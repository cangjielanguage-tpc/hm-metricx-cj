
package ohos_app_cangjie_hm_metricx_cj.traffic

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

@Interop[ArkTS]
public func initTrafficHandlerInterop(
    preference: TrafficPreference,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatSampleTraffic: (() -> Unit) -> Unit,
    getUidRxAndTxBytes: ((Int64, Int64, String, String) -> Unit, String) -> Unit,
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

// 获取当前页面从进入到调用时刻期间的完整流量增量，调用后自动清零，供下一页面计数。
// 结果经 onResult 回调返回（getUidRxAndTxBytes 本质异步）。
@Interop[ArkTS]
public func getAndResetCurrentPageTrafficInterop(onResult: (InteropPageTrafficInfo) -> Unit): Unit {
    getAndResetCurrentPageTraffic(onResult)
}