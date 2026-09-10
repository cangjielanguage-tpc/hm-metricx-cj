/*
 * Copyright (c) 2026 hm-metricx-cj. All rights reserved.
 *
 * 内存模块原生采集实现。详见 memory_stats.h。
 */
#include "memory_stats.h"

#include "hidebug/hidebug.h"

extern "C" {

int64_t CaptureProcessPss(void) {
    HiDebug_NativeMemInfo info;
    info.pss = 0;
    info.vss = 0;
    info.rss = 0;
    info.sharedDirty = 0;
    info.privateDirty = 0;
    info.sharedClean = 0;
    info.privateClean = 0;
    OH_HiDebug_GetAppNativeMemInfo(&info);
    if (info.pss == 0) {
        return -1;
    }
    return static_cast<int64_t>(info.pss);
}

int64_t CaptureProcessRssLimit(void) {
    HiDebug_MemoryLimit limit;
    limit.rssLimit = 0;
    limit.vssLimit = 0;
    OH_HiDebug_GetAppMemoryLimit(&limit);
    if (limit.rssLimit == 0) {
        return -1;
    }
    return static_cast<int64_t>(limit.rssLimit);
}

} // extern "C"
