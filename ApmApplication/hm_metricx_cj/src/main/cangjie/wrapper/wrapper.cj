/**
 * Created on 2025/9/18
 */
package ohos_app_cangjie_hm_metricx_cj.wrapper

import ohos_app_cangjie_hm_metricx_cj.traffic.TrafficPreference
import ohos_app_cangjie_hm_metricx_cj.traffic.initTrafficHandler as _initTrafficHandler
import ohos_app_cangjie_hm_metricx_cj.traffic.destroyTrafficHandler as _destroyTrafficHandler
import ohos_app_cangjie_hm_metricx_cj.traffic.InteropSampleTrafficInfo
import ohos_app_cangjie_hm_metricx_cj.storage.initStorageHandler as _initStorageHandler
import ohos_app_cangjie_hm_metricx_cj.storage.reportAppStorageInfo as _reportAppStorageInfo
import ohos.ark_interop_macro.*
import ohos.ark_interop.*
import ohos_app_cangjie_hm_metricx_cj.storage.InteropStorageInfo

@Interop[ArkTS]
public func initTrafficHandler(
    preference: TrafficPreference,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatSampleTraffic: (() -> Unit) -> Unit,
    getUidRxAndTxBytes: ((Int64, Int64) -> Unit) -> Unit,
    reportTraffic: (InteropSampleTrafficInfo) -> Unit,
    sampleThreshold: Int64
): Unit {
    _initTrafficHandler(preference, onNavDestinationSwitch, repeatSampleTraffic, getUidRxAndTxBytes, reportTraffic,
        sampleThreshold: sampleThreshold)
}

@Interop[ArkTS]
public func destroyTrafficHandler(getUidRxAndTxBytes: ((Int64, Int64) -> Unit) -> Unit): Unit {
    _destroyTrafficHandler(getUidRxAndTxBytes)
}

@Interop[ArkTS]
public func initStorageHandler(reportStorageInfo: (InteropStorageInfo) -> Unit, sizeLimit: Int64, dirSizeLimit: Int64,
    reportTopNum: Int64): Unit {
    _initStorageHandler(reportStorageInfo, sizeLimit: sizeLimit, dirSizeLimit: dirSizeLimit, reportTopNum: reportTopNum)
}

@Interop[ArkTS]
public func reportAppStorageInfo(getCurrentBundleStats: ((Int64, Int64, Int64) -> Unit) -> Unit): Unit {
    _reportAppStorageInfo(getCurrentBundleStats)
}
