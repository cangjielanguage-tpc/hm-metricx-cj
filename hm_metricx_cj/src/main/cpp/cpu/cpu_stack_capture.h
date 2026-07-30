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
 * 回溯/符号化解耦：采样阶段调 CaptureThreadPcs 只做信号内 FP 回溯（~20µs），周期末对
 *   频次 TopK 栈调 SymbolizePcs 批量符号化。CaptureThreadStack（一体化）保留给自检/即时场景。
 *
 * 触发稀疏：线程级 3 分钟 cooldown（见 cpu.cj），配合 isCapturingStack 串行锁，g_pending
 *   单槽即可。
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

/*
 * 只回溯拿原始 PC 数组，不符号化。供采样阶段高频调用（~20µs/次）。
 *   tid == 0 表示当前线程（同步直调 BacktraceFromFp，不发信号）。
 *   pcs: 调用方分配的 PC 缓冲；pcsCapacity: 容量帧数（建议 MAX_PC_FRAMES=64）。
 *   返回写入 pcs 的帧数；负值为错误码：-1 参数非法，-2 未初始化，-3 并发占用，
 *   -4 tgkill 失败，-5 信号超时。
 */
int64_t CaptureThreadPcs(int64_t tid, uint64_t *pcs, int64_t pcsCapacity);

/*
 * 批量符号化 PC 数组，写入栈文本 + 栈顶模块名。周期末对频次 TopK 栈调用。
 *   纯读符号表，不碰 g_pending，不拿 g_capturing 锁，可与回溯并发。
 * @return 写入 stackBuf 的字节数（不含 '\0'）；<0 失败（-2 未初始化）。
 */
int64_t SymbolizePcs(const uint64_t *pcs, int64_t count,
                      uint8_t *stackBuf, int64_t stackSize,
                      uint8_t *moduleBuf, int64_t moduleSize);

#ifdef __cplusplus
}
#endif

#endif /* CPU_STACK_CAPTURE_H */
