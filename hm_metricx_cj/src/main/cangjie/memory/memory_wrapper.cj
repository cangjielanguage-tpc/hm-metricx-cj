
package hm_metricx_cj.memory

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

@Interop[ArkTS]
public func getPageMemoryInfoInterop(): InteropPageMemoryInfo {
    getPageMemoryInfo()
}

@Interop[ArkTS]
public func getProcessMemoryInfoInterop(): InteropProcessMemoryInfo {
    getProcessMemoryInfo()
}

// ArkTS 端 Worker 异步采样到 heapUsed/vmHeapLimit 后经本 interop 灌 Cangjie 缓存。
// doMemorySample 读缓存不再置 0，6 个 ArkTS VM 堆字段恢复有效，主线程零 hidebug 调用。
@Interop[ArkTS]
public func setArkTsMemoryCacheInterop(usage: Int64, limit: Int64): Unit {
    setArkTsMemoryCache(usage, limit)
}

@Interop[ArkTS]
public func initMemoryHandlerInterop(
    memoryPreference: MemoryPreference,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatSampleAndReportMemory: (() -> Unit, () -> Unit, () -> Unit) -> Unit,
    reporPageMemoryInfo: (InteropPageMemoryInfo) -> Unit,
    reporProcessMemoryInfo: (InteropProcessMemoryInfo) -> Unit,
    memoryThreshold: Int64,
    totalRatio: Float64,
    cjRatio: Float64,
    arkTsRatio: Float64
): Unit {
    initMemoryHandler(memoryPreference, onNavDestinationSwitch, repeatSampleAndReportMemory,
        reporPageMemoryInfo, reporProcessMemoryInfo, memoryThreshold: memoryThreshold,
        totalRatio: totalRatio, cjRatio: cjRatio, arkTsRatio: arkTsRatio)
}

@Interop[ArkTS]
public func destroyMemoryHandlerInterop(): Unit {
    destroyMemoryHandler()
}