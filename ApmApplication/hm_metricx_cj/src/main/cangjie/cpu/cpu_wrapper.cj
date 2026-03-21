
package ohos_app_cangjie_hm_metricx_cj.cpu

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

@Interop[ArkTS]
public func getPageCpuInfoInterop(): InteropPageCpuInfo {
    getPageCpuInfo()
}

@Interop[ArkTS]
public func getProcessCpuInfoInterop(): InteropProcessCpuInfo {
    getProcessCpuInfo()
}

@Interop[ArkTS]
public func initCpuHandlerInterop(
    getCpuUsage: () -> Float64,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatSampleAndReportCpu: (() -> Unit, () -> Unit) -> Unit,
    reporPageCpuInfo: (InteropPageCpuInfo) -> Unit,
    reporProcessCpuInfo: (InteropProcessCpuInfo) -> Unit
): Unit {
    initCpuHandler(getCpuUsage, onNavDestinationSwitch, repeatSampleAndReportCpu, reporPageCpuInfo, reporProcessCpuInfo)
}