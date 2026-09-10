/*
 * Copyright (c) 2026 hm-metricx-cj. All rights reserved.
 *
 * 高 CPU 线程调用栈采集实现。详见 cpu_stack_capture.h。
 */
#include "cpu_stack_capture.h"

#include <atomic>
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <pthread.h>
#include <signal.h>
#include <ucontext.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <cerrno>
#include <hilog/log.h>
#include "hidebug/hidebug.h"

namespace {
constexpr int32_t CPU_STACK_TAG = 0x00008;
constexpr const char *CPU_STACK_LOG_TAG = "hm_metricx_cj";

// 单次抓栈的栈帧上限。栈深通常 < 64，64 足够定位业务代码模块。
constexpr int32_t MAX_PC_FRAMES = 64;

// 采集线程等待目标线程写完 ready 的超时（毫秒）。超时返回空栈，不阻塞采集主流程。
constexpr int32_t CAPTURE_WAIT_TIMEOUT_MS = 100;

// pending 槽：信号处理与采集线程之间的单槽通信（配合 cpu.cj 的 isCapturingStack 串行锁）。
struct PendingSlot {
    std::atomic<bool> ready{false};
    std::atomic<int32_t> count{0};
    void *pcs[MAX_PC_FRAMES];
    // 诊断字段（handler 写、采集线程读，普通上下文打印；handler 内禁止调 hilog）。
    std::atomic<bool> handlerRan{false};
    std::atomic<uint64_t> startFpValue{0};   // handler 实际用作 startFp 的值
    std::atomic<int32_t> btReturn{0};        // OH_HiDebug_BacktraceFromFp 返回值
};

PendingSlot g_pending;
std::atomic<bool> g_inited{false};
std::atomic<bool> g_capturing{false}; // 采集线程持锁标志，防并发

// backtrace object 在普通上下文创建并长期持有，信号处理里直接读。
HiDebug_Backtrace_Object g_btObj = nullptr;

// SIGUSR2 的原处理动作，卸载时恢复（目前不卸载，保留以备扩展）。
struct sigaction g_oldSigusr2Act;

inline void LogWarn(const char *msg) {
    OH_LOG_Print(LOG_APP, LOG_WARN, CPU_STACK_TAG, CPU_STACK_LOG_TAG, "%s", msg);
}

inline void LogInfo(const char *msg) {
    OH_LOG_Print(LOG_APP, LOG_INFO, CPU_STACK_TAG, CPU_STACK_LOG_TAG, "%s", msg);
}

/*
 * SIGUSR2 信号处理：在目标线程上下文执行。
 * 只调 signal-safe 的 OH_HiDebug_BacktraceFromFp，写 pc 数组到 g_pending，置 ready。
 * 绝不调 SymbolicAddress/malloc 等。
 *
 * startFp 必须用被中断线程的帧指针（x29），而非 handler 自身的 __builtin_frame_address(0)。
 * 后者是信号栈上的 handler 帧，沿其 FP 链回溯跨不过内核信号帧，会得到空栈。
 * arm64 的 ucontext_t.uc_mcontext 即 struct sigcontext，regs[29]=x29(FP)、regs[30]=x30(LR)。
 */
static void CpuStackSignalHandler(int /*sig*/, siginfo_t * /*si*/, void *context) {
    // backtrace object 在 init 时创建；若未 init 直接返回（不应发生）。
    if (g_btObj == nullptr) {
        return;
    }

    void *startFp = nullptr;
    uint64_t fpValue = 0;
#if defined(__aarch64__)
    if (context != nullptr) {
        auto *uc = static_cast<ucontext_t *>(context);
        // arm64：uc_mcontext 为 struct sigcontext，regs[29] 即 x29 帧指针。
        unsigned long fp = uc->uc_mcontext.regs[29];
        fpValue = static_cast<uint64_t>(fp);
        if (fp != 0) {
            startFp = reinterpret_cast<void *>(fp);
        }
    }
#endif
    if (startFp == nullptr) {
        // 退化：无 ucontext 或非 arm64，用 handler 自身帧（跨帧可能不全，仅兜底）。
        startFp = __builtin_frame_address(0);
        fpValue = reinterpret_cast<uint64_t>(startFp);
    }

    int32_t n = OH_HiDebug_BacktraceFromFp(g_btObj, startFp, g_pending.pcs, MAX_PC_FRAMES);
    g_pending.handlerRan.store(true, std::memory_order_release);
    g_pending.startFpValue.store(fpValue, std::memory_order_release);
    g_pending.btReturn.store(n, std::memory_order_release);
    if (n < 0) {
        n = 0;
    }
    if (n > MAX_PC_FRAMES) {
        n = MAX_PC_FRAMES;
    }
    g_pending.count.store(n, std::memory_order_release);
    g_pending.ready.store(true, std::memory_order_release);
}

// 把单个 pc 符号化并追加到 stackBuf。返回追加的长度（不含 '\0'）。
// 此函数在采集线程普通上下文调用，可用 OH_HiDebug_SymbolicAddress（非 signal-safe）。
static int64_t AppendSymbolizedFrame(void *pc, char *stackBuf, int64_t stackSize, int64_t curLen) {
    if (pc == nullptr || stackBuf == nullptr || stackSize <= 0) {
        return 0;
    }
    struct FrameArg {
        char *buf;
        int64_t bufSize;
        int64_t written;
        bool valid; // callback 是否产出有效帧
    } arg{stackBuf, stackSize, curLen, false};

    auto callback = [](void * /*pc*/, void *cbArg, const HiDebug_StackFrame *frame) {
        auto *fa = static_cast<FrameArg *>(cbArg);
        if (fa == nullptr || frame == nullptr) {
            return;
        }
        // snprintf 返回“本应写入”的逻辑字节数（不含 '\0'），而非实际写入。
        // 直接把它累加进 written 会导致 written 越过 bufSize，后续帧 snprintf 的
        // size 参数 (bufSize-written) 回绕成巨大正数、buf+written 指针越过缓冲末尾，
        // 最终把超界 total 返回仓颉层引发 IndexOutOfBoundsException。
        // 故用“可用空间”钳制：只累加真正能写进缓冲的字节数（real），written 始终 ≤ bufSize-1。
        auto appendText = [fa](const char *fmt, ...) -> void {
            if (fa->written >= fa->bufSize - 1) {
                return; // 缓冲已满（留 1 字节给 '\0'），不再追加
            }
            va_list ap;
            va_start(ap, fmt);
            int n = std::vsnprintf(fa->buf + fa->written,
                                   static_cast<size_t>(fa->bufSize - fa->written), fmt, ap);
            va_end(ap);
            if (n <= 0) {
                return;
            }
            int64_t avail = fa->bufSize - 1 - fa->written; // 可写字节数（留 1 给 '\0'）
            int64_t real = (n < avail) ? static_cast<int64_t>(n) : avail;
            fa->written += real;
            fa->buf[fa->written] = '\0'; // 保持 '\0' 结尾，供下次 snprintf 正确续写
            fa->valid = true;
        };
        if (frame->type == HIDEBUG_STACK_FRAME_TYPE_NATIVE) {
            // native 帧：functionName(mapName+0xoffset)。
            const HiDebug_NativeStackFrame &nf = frame->frame.native;
            const char *fn = nf.functionName ? nf.functionName : "";
            const char *map = nf.mapName ? nf.mapName : "?";
            // 过滤栈扫描产生的噪音帧：无函数符号且 offset==0 的帧（典型表现如 "cpu.so+0x0"
            // 连续重复多帧），是 BacktraceFromFp 遇非标准 FP 帧后启发式扫描到的无效 PC，
            // 被勉强归类到某 .so 基址。有函数符号 + offset 0 是真实帧（函数入口），保留。
            if ((fn[0] == '\0') && nf.funcOffset == 0) {
                return;
            }
            if (fn[0] == '\0') {
                fn = "?";
            }
            appendText("  %s(%s+0x%llx)\n", fn, map,
                       static_cast<unsigned long long>(nf.funcOffset));
            return;
        }
        if (frame->type == HIDEBUG_STACK_FRAME_TYPE_JS) {
            // JS 帧：functionName(url:line:column)。这是业务热点函数所在的帧，
            // 例如 ArkTS Worker 的 burnCpuContinuously。若无 functionName 则用 url 短名兜底，
            // line/column 无效（<=0）时只保留 url，避免误导。
            const HiDebug_JsStackFrame &jf = frame->frame.js;
            const char *fn = jf.functionName ? jf.functionName : "";
            const char *url = jf.url ? jf.url : "";
            if (fn[0] == '\0' && url[0] == '\0') {
                return; // 既无函数名也无源码，跳过
            }
            const char *urlBase = url;
            if (url[0] != '\0') {
                for (const char *p = url; *p != '\0'; p++) {
                    if (*p == '/') {
                        urlBase = p + 1;
                    }
                }
            }
            const char *displayName = (fn[0] != '\0') ? fn : urlBase;
            if (jf.line > 0 && jf.column > 0) {
                appendText("  %s(%s:%d:%d)\n", displayName, urlBase, jf.line, jf.column);
            } else if (jf.line > 0) {
                appendText("  %s(%s:%d)\n", displayName, urlBase, jf.line);
            } else {
                appendText("  %s(%s)\n", displayName, urlBase);
            }
            return;
        }
        // 未知帧类型，跳过。
    };

    HiDebug_ErrorCode ec = OH_HiDebug_SymbolicAddress(g_btObj, pc, &arg, callback);
    if (ec != HIDEBUG_SUCCESS || !arg.valid) {
        // 符号化失败或被过滤的噪音帧：不输出，避免连续 "so+0x0" 噪音淹没真实栈。
        // 真正无符号的裸地址帧也省略（pc 数组已存，需要时可单独 dump）。
        return 0;
    }
    return arg.written - curLen;
}

// 取模块短名（去路径），与 /proc/.../comm 风格对齐，便于责任模块归类。
static void ExtractMapBase(const char *map, char *out, int64_t size) {
    if (map == nullptr || map[0] == '\0' || out == nullptr || size <= 0) {
        return;
    }
    const char *base = map;
    for (const char *p = map; *p != '\0'; p++) {
        if (*p == '/') {
            base = p + 1;
        }
    }
    std::strncpy(out, base, static_cast<size_t>(size - 1));
    out[size - 1] = '\0';
}

// 从栈顶帧符号化结果提取 module（so/包短名）。moduleBuf 写 '\0' 结尾的模块名。
static void ExtractTopModule(void **pcs, int32_t count, char *moduleBuf, int64_t moduleSize) {
    if (moduleBuf == nullptr || moduleSize <= 0) {
        return;
    }
    moduleBuf[0] = '\0';
    if (count <= 0 || pcs == nullptr) {
        return;
    }
    // 栈顶第一帧（pcs[0]）通常最接近热点函数，取它的 mapName 作为 moduleName。
    struct ModArg {
        char *buf;
        int64_t size;
        bool done;
    } arg{moduleBuf, moduleSize, false};

    auto cb = [](void * /*pc*/, void *cbArg, const HiDebug_StackFrame *frame) {
        auto *ma = static_cast<ModArg *>(cbArg);
        if (ma == nullptr || ma->done || frame == nullptr) {
            return;
        }
        if (frame->type == HIDEBUG_STACK_FRAME_TYPE_NATIVE) {
            ExtractMapBase(frame->frame.native.mapName, ma->buf, ma->size);
            if (ma->buf[0] != '\0') {
                ma->done = true;
            }
            return;
        }
        if (frame->type == HIDEBUG_STACK_FRAME_TYPE_JS) {
            // JS 帧的 module 取 packageName（业务包名最贴切），兜底 mapName（abc 文件）。
            const char *pkg = frame->frame.js.packageName;
            if (pkg != nullptr && pkg[0] != '\0') {
                ExtractMapBase(pkg, ma->buf, ma->size);
                ma->done = true;
                return;
            }
            ExtractMapBase(frame->frame.js.mapName, ma->buf, ma->size);
            if (ma->buf[0] != '\0') {
                ma->done = true;
            }
            return;
        }
    };
    // 栈顶帧（pcs[0]）通常最接近热点函数，取它的模块名。若栈顶帧符号化失败或无模块名，
    // 顺次向下取第一帧有效模块名，避免 Worker 高 CPU 时栈顶为 JS 帧被丢弃导致 unknown。
    for (int32_t i = 0; i < count && !arg.done; i++) {
        OH_HiDebug_SymbolicAddress(g_btObj, pcs[i], &arg, cb);
    }
    if (!arg.done) {
        std::snprintf(moduleBuf, static_cast<size_t>(moduleSize), "unknown");
    }
}

// 抓当前线程栈（tid==0 分支）：同步直调，不发信号。
static int64_t CaptureCurrentThread(char *stackBuf, int64_t stackSize, char *moduleBuf, int64_t moduleSize) {
    if (g_btObj == nullptr) {
        return -1;
    }
    void *pcs[MAX_PC_FRAMES];
    int32_t n = OH_HiDebug_BacktraceFromFp(g_btObj, __builtin_frame_address(0), pcs, MAX_PC_FRAMES);
    if (n <= 0) {
        return 0;
    }
    int64_t total = 0;
    stackBuf[0] = '\0';
    for (int32_t i = 0; i < n && total < stackSize - 1; i++) {
        total += AppendSymbolizedFrame(pcs[i], stackBuf, stackSize, total);
    }
    ExtractTopModule(pcs, n, moduleBuf, moduleSize);
    return total;
}

// 自旋等待 ready，带超时。返回 true 表示就绪。
static bool WaitReady(std::atomic<bool> &ready, int32_t timeoutMs) {
    for (int32_t i = 0; i < timeoutMs; i++) {
        if (ready.load(std::memory_order_acquire)) {
            return true;
        }
        usleep(1000); // 1ms
    }
    return ready.load(std::memory_order_acquire);
}

/* ============== native CPU usage via OH_HiDebug_* ==============
 * 替代 hidebug.getAppThreadCpuUsage()/getCpuUsage() 经 NAPI 回调的路径，消除 hidebug
 * 内部 ApiInvokeRecorder FFRT 退避导致的主线程 ANR。
 * /proc/self/stat 与 /proc/stat 在 HarmonyOS 沙箱下 native 无权读，改走
 * OH_HiDebug_GetAppCpuUsage / OH_HiDebug_GetAppThreadCpuUsage native C 直调：
 * 不经 ArkTS NAPI 包装层，不触发 ApiInvokeRecorder 析构退避，主线程安全。
 */

} // namespace

extern "C" {

int8_t InitCpuStackCapture(void) {
    bool expected = false;
    if (!g_inited.compare_exchange_strong(expected, true)) {
        return 0; // 已初始化，幂等返回
    }

    g_btObj = OH_HiDebug_CreateBacktraceObject();
    if (g_btObj == nullptr) {
        LogWarn("InitCpuStackCapture: CreateBacktraceObject failed, arch unsupported");
        g_inited.store(false);
        return -1;
    }

    struct sigaction act;
    std::memset(&act, 0, sizeof(act));
    sigfillset(&act.sa_mask);
    act.sa_sigaction = CpuStackSignalHandler;
    act.sa_flags = SA_RESTART | SA_SIGINFO;
    if (sigaction(SIGUSR2, &act, &g_oldSigusr2Act) != 0) {
        LogWarn("InitCpuStackCapture: sigaction SIGUSR2 failed");
        OH_HiDebug_DestroyBacktraceObject(g_btObj);
        g_btObj = nullptr;
        g_inited.store(false);
        return -2;
    }

    LogInfo("InitCpuStackCapture: SIGUSR2 handler registered");
    return 0;
}

int64_t CaptureThreadStack(int64_t tid, uint8_t *stackBuf, int64_t stackSize,
                           uint8_t *moduleBuf, int64_t moduleSize) {
    // Cangjie 侧传入 CPointer<UInt8>（uint8_t*）；内部 snprintf/strncpy 需要 char*，在此统一转换。
    char *stack = reinterpret_cast<char *>(stackBuf);
    char *module = (moduleBuf != nullptr) ? reinterpret_cast<char *>(moduleBuf) : nullptr;
    if (stack == nullptr || stackSize <= 0) {
        return -1;
    }
    stack[0] = '\0';
    if (module != nullptr && moduleSize > 0) {
        module[0] = '\0';
    }
    if (!g_inited.load() || g_btObj == nullptr) {
        return -2;
    }

    // tid == 0：当前线程，同步直调。
    if (tid == 0) {
        return CaptureCurrentThread(stack, stackSize, module, moduleSize);
    }

    // 串行：同时只允许一个采集在飞（cpu.cj 的 isCapturingStack 已做上层串行，这里再兜一层）。
    bool expected = false;
    if (!g_capturing.compare_exchange_strong(expected, true)) {
        return -3; // 并发抓栈，跳过本次
    }

    int64_t ret = 0;
    do {
        // 准备 pending 槽
        g_pending.ready.store(false, std::memory_order_release);
        g_pending.count.store(0, std::memory_order_release);

        // hidebug 给的是 OS tid（uint32_t），不是 pthread_t，必须用 tgkill 而非 pthread_kill。
        // tgkill(tgid, tid, sig)：tgid=getpid()，tid=目标 OS 线程号，sig=SIGUSR2。
        if (syscall(SYS_tgkill, getpid(), static_cast<pid_t>(tid), SIGUSR2) != 0) {
            // 目标线程已退出(ESRCH) 或无此 tid，跳过。带 errno 便于区分 ESRCH/EPERM/EINVAL。
            int err = errno;
            char buf[128];
            std::snprintf(buf, sizeof(buf),
                "CaptureThreadStack: tgkill failed tid=%lld errno=%d",
                static_cast<long long>(tid), err);
            LogWarn(buf);
            ret = -4;
            break;
        }

        if (!WaitReady(g_pending.ready, CAPTURE_WAIT_TIMEOUT_MS)) {
            char buf[128];
            std::snprintf(buf, sizeof(buf),
                "CaptureThreadStack: wait ready timeout tid=%lld (handlerRan=%d)",
                static_cast<long long>(tid),
                g_pending.handlerRan.load(std::memory_order_acquire) ? 1 : 0);
            LogWarn(buf);
            ret = -5;
            break;
        }

        int32_t n = g_pending.count.load(std::memory_order_acquire);
        if (n <= 0) {
            // handler 跑了但 0 帧：打印诊断区分根因（startFp 取值 / BacktraceFromFp 返回）。
            bool ran = g_pending.handlerRan.load(std::memory_order_acquire);
            uint64_t fp = g_pending.startFpValue.load(std::memory_order_acquire);
            int32_t btRet = g_pending.btReturn.load(std::memory_order_acquire);
            char dbg[160];
            std::snprintf(dbg, sizeof(dbg),
                "CaptureThreadStack: 0 frames, tid=%lld, handlerRan=%d, startFp=0x%llx, btReturn=%d",
                static_cast<long long>(tid), ran ? 1 : 0,
                static_cast<unsigned long long>(fp), btRet);
            LogWarn(dbg);
            ret = 0;
            break;
        }
        if (n > MAX_PC_FRAMES) {
            n = MAX_PC_FRAMES;
        }

        // 符号化（普通上下文，非信号）。
        int64_t total = 0;
        for (int32_t i = 0; i < n && total < stackSize - 1; i++) {
            total += AppendSymbolizedFrame(g_pending.pcs[i], stack, stackSize, total);
        }
        ExtractTopModule(g_pending.pcs, n, module, moduleSize);
        ret = total;
    } while (false);

    g_capturing.store(false, std::memory_order_release);
    return ret;
}

// 只回溯拿原始 PC 数组，不符号化。供采样阶段高频调用（~20µs/次）。
// 信号内 FP 回溯结果经 g_pending.pcs 拷贝到调用方 pcs 缓冲，不付符号化成本。
// 返回：>0=帧数（写入 pcs 前 N 个）；0=handler 跑了但 0 帧；负值=错误码
//       -2 未初始化；-3 并发占用；-4 tgkill 失败；-5 信号超时
int64_t CaptureThreadPcs(int64_t tid, uint64_t *pcs, int64_t pcsCapacity) {
    if (pcs == nullptr || pcsCapacity <= 0) {
        return -1;
    }
    if (!g_inited.load() || g_btObj == nullptr) {
        return -2;
    }

    // tid == 0：当前线程，同步直调 BacktraceFromFp（不发信号）。
    if (tid == 0) {
        int32_t n = OH_HiDebug_BacktraceFromFp(g_btObj, __builtin_frame_address(0),
                                                reinterpret_cast<void **>(pcs),
                                                static_cast<int32_t>(pcsCapacity));
        if (n <= 0) {
            return 0;
        }
        if (n > pcsCapacity) {
            n = static_cast<int32_t>(pcsCapacity);
        }
        return static_cast<int64_t>(n);
    }

    // 串行：同时只允许一个回溯在飞（与 CaptureThreadStack 同锁）。
    bool expected = false;
    if (!g_capturing.compare_exchange_strong(expected, true)) {
        return -3;
    }

    int64_t ret = 0;
    do {
        g_pending.ready.store(false, std::memory_order_release);
        g_pending.count.store(0, std::memory_order_release);

        if (syscall(SYS_tgkill, getpid(), static_cast<pid_t>(tid), SIGUSR2) != 0) {
            int err = errno;
            char buf[128];
            std::snprintf(buf, sizeof(buf),
                "CaptureThreadPcs: tgkill failed tid=%lld errno=%d",
                static_cast<long long>(tid), err);
            LogWarn(buf);
            ret = -4;
            break;
        }

        if (!WaitReady(g_pending.ready, CAPTURE_WAIT_TIMEOUT_MS)) {
            char buf[128];
            std::snprintf(buf, sizeof(buf),
                "CaptureThreadPcs: wait ready timeout tid=%lld (handlerRan=%d)",
                static_cast<long long>(tid),
                g_pending.handlerRan.load(std::memory_order_acquire) ? 1 : 0);
            LogWarn(buf);
            ret = -5;
            break;
        }

        int32_t n = g_pending.count.load(std::memory_order_acquire);
        if (n <= 0) {
            ret = 0;  // handler 跑了但 0 帧
            break;
        }
        if (n > MAX_PC_FRAMES) {
            n = MAX_PC_FRAMES;
        }
        int64_t copyN = (n < pcsCapacity) ? n : static_cast<int32_t>(pcsCapacity);
        std::memcpy(pcs, g_pending.pcs, static_cast<size_t>(copyN * sizeof(uint64_t)));
        ret = copyN;
    } while (false);

    g_capturing.store(false, std::memory_order_release);
    return ret;
}

// 批量符号化 PC 数组。周期末对频次 TopK 栈调用，输入 PC 数组、输出栈文本+模块名。
// 纯读符号表，不碰 g_pending，不拿 g_capturing 锁，可与回溯并发（但 Cangjie 侧串行调用）。
// 返回写入 stackBuf 的字节数（<=0=失败）。
int64_t SymbolizePcs(const uint64_t *pcs, int64_t count,
                      uint8_t *stackBuf, int64_t stackSize,
                      uint8_t *moduleBuf, int64_t moduleSize) {
    char *stack = reinterpret_cast<char *>(stackBuf);
    char *module = (moduleBuf != nullptr) ? reinterpret_cast<char *>(moduleBuf) : nullptr;
    if (pcs == nullptr || stack == nullptr || stackSize <= 0 || count <= 0) {
        if (stack != nullptr && stackSize > 0) {
            stack[0] = '\0';
        }
        return 0;
    }
    if (g_btObj == nullptr) {
        return -2;
    }

    void **pcPtrs = const_cast<void **>(reinterpret_cast<const void *const *>(pcs));
    int32_t n = (count > MAX_PC_FRAMES) ? MAX_PC_FRAMES : static_cast<int32_t>(count);

    stack[0] = '\0';
    if (module != nullptr && moduleSize > 0) {
        module[0] = '\0';
    }
    int64_t total = 0;
    for (int32_t i = 0; i < n && total < stackSize - 1; i++) {
        total += AppendSymbolizedFrame(pcPtrs[i], stack, stackSize, total);
    }
    ExtractTopModule(pcPtrs, n, module, moduleSize);
    return total;
}

/* ============== native CPU 使用率（OH_HiDebug C API，extern C 导出） ============== */

int64_t CaptureProcessCpuUsagePermille(void) {
    // OH_HiDebug_GetAppCpuUsage 返回 0-1 浮点（多核可>1），与 hidebug.getCpuUsage 口径对齐。
    // ×1000 转千分比，沿用 wrapper getCpuUsageNative 的 /1000 还原逻辑。
    double cpu = OH_HiDebug_GetAppCpuUsage();
    if (cpu < 0) {
        return -1;
    }
    int64_t permille = static_cast<int64_t>(cpu * 1000.0);
    if (permille < 0) permille = 0;
    return permille;
}

int64_t CaptureThreadCpuUsageJson(uint8_t *outBuf, int64_t outSize) {
    char *out = reinterpret_cast<char *>(outBuf);
    if (out == nullptr || outSize <= 2) {
        return -1;
    }
    HiDebug_ThreadCpuUsagePtr head = OH_HiDebug_GetAppThreadCpuUsage();
    if (head == nullptr) {
        out[0] = '['; out[1] = ']'; out[2] = '\0';
        return 2;
    }

    // 拼接 JSON：[{"threadId":T,"cpuUsage":C}, ...]
    // 元素间逗号在元素前（首个元素不带逗号），超长截到最后一个 '}' 后补 ']'（合法 JSON）。
    int64_t written = 0;
    out[written++] = '[';
    bool first = true;
    HiDebug_ThreadCpuUsagePtr p = head;
    while (p != nullptr) {
        // cpuUsage 0-1（线程级口径，所有线程相加≈1.0），5 位小数足够
        char element[64];
        int n = std::snprintf(element, sizeof(element), "%s{\"threadId\":%u,\"cpuUsage\":%.5f}",
                              first ? "" : ",", p->threadId, p->cpuUsage);
        if (n < 0) {
            p = p->next;
            continue;
        }
        // 截断保护：若本元素写不下，截到最后一个 '}' 后补 ']'
        if (written + n + 1 > outSize - 1) {
            if (written > 1 && out[written - 1] == '}') {
                out[written] = ']';
                out[written + 1] = '\0';
                OH_HiDebug_FreeThreadCpuUsage(&head);
                return written + 1;
            }
            // 连第一个元素都写不下
            out[0] = '['; out[1] = ']'; out[2] = '\0';
            OH_HiDebug_FreeThreadCpuUsage(&head);
            return 2;
        }
        std::memcpy(out + written, element, n);
        written += n;
        first = false;
        p = p->next;
    }
    out[written++] = ']';
    out[written] = '\0';

    OH_HiDebug_FreeThreadCpuUsage(&head);
    return written;
}

} // extern "C"
