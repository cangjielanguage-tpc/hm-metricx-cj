
package hm_metricx_cj.thermal

import ohos.ark_interop_macro.*
import ohos.ark_interop.*
import hm_metricx_cj.util.JSHelper


var thermalWrapperDestroyed: Bool = false

@Interop[ArkTS]
public func initThermalHandlerInterop(
    getUptimeMs: () -> Int64,
    thermalInterface: ThermalInfoInterface,
    hooks: AppHooks,
    repeatSampleThermal: (() -> Unit) -> Unit,
    stopSampleThermal: () -> Unit,
    reportThermalInfo: (InteropThermalEventInfo) -> Unit,
    sampleInterval: Int64,
    reportMinInterval: Int64,
    abnormalThreshold: Int32
): Unit {
    thermalWrapperDestroyed = false

    initThermalHandler(
        getUptimeMs,
        thermalInterface,
        hooks,
        repeatSampleThermal,
        stopSampleThermal,
        reportThermalInfo,
        sampleInterval: sampleInterval,
        reportMinInterval: reportMinInterval,
        abnormalThreshold: abnormalThreshold
    )
}

@Interop[ArkTS]
public func destroyThermalHandlerInterop(): Unit {
    thermalWrapperDestroyed = true
    destroyThermalHandler()
}