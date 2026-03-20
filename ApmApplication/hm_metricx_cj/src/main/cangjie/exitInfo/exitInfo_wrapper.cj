
package ohos_app_cangjie_hm_metricx_cj.exitInfo

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

@Interop[ArkTS]
public func getExitInfoInterop(lastExitMessage: String, lastExitReason: Int32): ExitInfo {
    getExitInfo(lastExitMessage, lastExitReason)
}