
package ohos_app_cangjie_hm_metricx_cj.memory

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
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatSampleAndReportMemory: (() -> Unit, () -> Unit, () -> Unit) -> Unit,
    reporPageMemoryInfo: (InteropPageMemoryInfo) -> Unit,
    reporProcessMemoryInfo: (InteropProcessMemoryInfo) -> Unit,
    memoryThreshold: Int64
): Unit {
    initMemoryHandler(memoryPreference, getMemoryUsage, getArkTsMemoryUsage, getArkTsTotalHeap,
        onNavDestinationSwitch, repeatSampleAndReportMemory,
        reporPageMemoryInfo, reporProcessMemoryInfo, memoryThreshold: memoryThreshold)
}

@Interop[ArkTS]
public func destroyMemoryHandlerInterop(): Unit {
    destroyMemoryHandler()
}