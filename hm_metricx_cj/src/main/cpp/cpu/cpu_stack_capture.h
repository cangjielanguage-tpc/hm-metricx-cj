/*
 * Copyright (c) 2026 hm-metricx-cj. All rights reserved.
 *
 * 高 CPU 线程调用栈采集（基于 Performance Analysis Kit 的 OH_HiDebug_BacktraceFromFp）。
 *
 * 机制：syscall(SYS_tgkill, getpid(), tid, SIGUSR2) 中断目标线程 → 信号处理里调
 *   OH_HiDebug_BacktraceFromFp（signal-safe）拿 pc 数组 → 采集线程普通上下文调
 *   OH_HiDebug_SymbolicAddress（非 signal-safe）符号化 → 回填栈串与栈顶 so 名。
 *   注：hidebug 给的是 OS tid（gettid），非 pthread_t，故用 tgkill 而非 pthread_kill。
 *
 * 信号安全分层（必须遵守）：
 *   - 信号处理里只调 OH_HiDebug_BacktraceFromFp + 原子标志，绝不调 SymbolicAddress/malloc 等。
 *   - backtrace object 在 InitCpuStackCapture（普通上下文）创建并长期持有。
 *
 * 触发稀疏：同 tid 10 分钟、全局 3 分钟 cooldown（见 cpu.cj），配合 isCapturingStack
 *   串行锁，g_pending 单槽即可。
 */
#ifndef CPU_STACK_CAPTURE_H
#define CPU_STACK_CAPTURE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * 初始化：创建 backtrace object + 注册 SIGUSR2 信号处理。
 * 幂等，重复调用安全。
 * @return 0 成功，<0 失败。
 */
int8_t InitCpuStackCapture(void);

/*
 * 抓取指定 tid 的调用栈并符号化。
 *   tid == 0 表示当前线程（自测/探针用，不发信号，直接 BacktraceFromFp）。
 *   stackBuf/moduleBuf 由调用方分配，分别写入"多行符号化栈串"与"栈顶 so 名"。
 *   两个 buf 均以 '\0' 结尾。
 * @return 写入 stackBuf 的字节数（不含 '\0'）；<0 失败（含超时、ESRCH、未 init）。
 */
int64_t CaptureThreadStack(int64_t tid, uint8_t *stackBuf, int64_t stackSize,
                           uint8_t *moduleBuf, int64_t moduleSize);

#ifdef __cplusplus
}
#endif

#endif /* CPU_STACK_CAPTURE_H */
