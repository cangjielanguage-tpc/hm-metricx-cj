
package ohos_app_cangjie_hm_metricx_cj.traffic

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

@Interop[ArkTS]
public func initTrafficHandlerInterop(
    preference: TrafficPreference,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatSampleTraffic: (() -> Unit) -> Unit,
    getUidRxAndTxBytes: ((Int64, Int64, String) -> Unit, String) -> Unit,
    reportTraffic: (InteropSampleTrafficInfo) -> Unit,
    reportYesterdayTraffic: (InteropDayTrafficInfo) -> Unit,
    sampleThreshold: Int64
): Unit {
    initTrafficHandler(preference, onNavDestinationSwitch, repeatSampleTraffic, getUidRxAndTxBytes, reportTraffic,
        reportYesterdayTraffic, sampleThreshold: sampleThreshold)
}

@Interop[ArkTS]
public func destroyTrafficHandlerInterop(getUidRxAndTxBytes: ((Int64, Int64) -> Unit) -> Unit): Unit {
    destroyTrafficHandler(getUidRxAndTxBytes)
}