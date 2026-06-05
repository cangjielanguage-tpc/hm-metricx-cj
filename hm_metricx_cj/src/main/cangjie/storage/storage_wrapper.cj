
package ohos_app_cangjie_hm_metricx_cj.storage

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

@Interop[ArkTS]
public func initStorageHandlerInterop(reportStorageInfo: (InteropStorageInfo) -> Unit, sizeLimit: Int64, dirSizeLimit: Int64,
    reportTopNum: Int64): Unit {
    initStorageHandler(reportStorageInfo, sizeLimit: sizeLimit, dirSizeLimit: dirSizeLimit, reportTopNum: reportTopNum)
}

@Interop[ArkTS]
public func reportAppStorageInfoInterop(getCurrentBundleStats: ((Int64, Int64, Int64) -> Unit) -> Unit): Unit {
    reportAppStorageInfo(getCurrentBundleStats)
}