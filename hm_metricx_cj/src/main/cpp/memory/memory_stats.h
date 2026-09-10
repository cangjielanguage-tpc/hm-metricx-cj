/*
 * Copyright (c) 2026 hm-metricx-cj. All rights reserved.
 *
 * 内存模块原生采集（基于 Performance Analysis Kit 的 OH_HiDebug_GetAppNativeMemInfo /
 * OH_HiDebug_GetAppMemoryLimit）。
 *
 * 机制：仓颉 2s setInterval 采样 → doMemorySample 闭包 → 本文件 native 直调，
 *   绕开 hidebug ArkTS NAPI 包装层 ApiInvokeRecorder 析构退避链，主线程安全。
 *   与 CPU 模块 native-化（commit ee0dc58）同口径同模式。
 *
 * OH_HiDebug_GetAppNativeMemInfo / OH_HiDebug_GetAppMemoryLimit 签名为 void，
 *   按指针写出参；调用方据字段值是否为 0 判别失败（运行进程 PSS/rssLimit 不可能为 0）。
 */
#ifndef MEMORY_STATS_H
#define MEMORY_STATS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * 读取本进程 PSS（KB）。
 *   调 OH_HiDebug_GetAppNativeMemInfo(&info) 填充结构体，返回 info.pss。
 *   与 hidebug.getPss 口径对齐。
 *   pss 字段 uint32_t KB，最大约 4GB-1 KB，足够覆盖 PSS。
 * @return Pss KB（>=0）；<0 失败。
 */
int64_t CaptureProcessPss(void);

/*
 * 读取本进程 rss 内存上限（KB）。
 *   调 OH_HiDebug_GetAppMemoryLimit(&limit) 填充结构体，返回 limit.rssLimit。
 *   与 hidebug.getAppMemoryLimit().rssLimit 口径对齐。
 *   注：native 仅暴露 rssLimit/vssLimit 两字段，无 vmHeapLimit 等价物——
 *   ArkTS 总堆上限无 native 替代，由仓颉侧返回 0（业务已确认）。
 * @return rssLimit KB（>=0）；<0 失败。
 */
int64_t CaptureProcessRssLimit(void);

#ifdef __cplusplus
}
#endif

#endif /* MEMORY_STATS_H */
