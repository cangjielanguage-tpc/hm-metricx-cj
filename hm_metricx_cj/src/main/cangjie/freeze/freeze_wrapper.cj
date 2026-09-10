
package hm_metricx_cj.freeze

import ohos.ark_interop_macro.*
import ohos.ark_interop.*
import std.fs.*
@Interop[ArkTS]
public func initFreezeHandlerInterop(sdkApiVersion: Int64,
    addFreezeWatcher: ((String, String, String, String, String) -> Unit) -> Unit, onFreeze: (() -> Unit) -> Unit,
    collectFreezeInfo: () -> String, reportFreezeInfo: (InteropFreezeInfo) -> Unit, persistentDir: String): Unit {
    initFreezeHandler(sdkApiVersion, addFreezeWatcher, onFreeze, collectFreezeInfo, reportFreezeInfo,
        Path(persistentDir))
}