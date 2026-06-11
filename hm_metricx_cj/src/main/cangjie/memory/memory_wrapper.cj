
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

@Interop[ArkTS]
public func initMemoryHandlerInterop(
    memoryPreference: MemoryPreference,
    getMemoryUsage: () -> Int64,
    getArkTsMemoryUsage: () -> Int64,
    getArkTsTotalHeap: () -> Int64,
    getTotalMemoryLimit: () -> Int64,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatSampleAndReportMemory: (() -> Unit, () -> Unit, () -> Unit) -> Unit,
    reporPageMemoryInfo: (InteropPageMemoryInfo) -> Unit,
    reporProcessMemoryInfo: (InteropProcessMemoryInfo) -> Unit,
    memoryThreshold: Int64,
    totalRatio: Float64,
    cjRatio: Float64,
    arkTsRatio: Float64
): Unit {
    initMemoryHandler(memoryPreference, getMemoryUsage, getArkTsMemoryUsage, getArkTsTotalHeap,
        getTotalMemoryLimit, onNavDestinationSwitch, repeatSampleAndReportMemory,
        reporPageMemoryInfo, reporProcessMemoryInfo, memoryThreshold: memoryThreshold,
        totalRatio: totalRatio, cjRatio: cjRatio, arkTsRatio: arkTsRatio)
}

@Interop[ArkTS]
public func destroyMemoryHandlerInterop(): Unit {
    destroyMemoryHandler()
}