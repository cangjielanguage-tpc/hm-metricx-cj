
package hm_metricx_cj.laggy

import ohos.ark_interop_macro.*
import ohos.ark_interop.*
import hm_metricx_cj.util.*

@Interop[ArkTS]
public func initLaggyHandlerInterop(
    onDisplay: DisplaySync,
    onAbilityBackground: (() -> Unit) -> Unit,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    onDidClick: ((ClickInfo) -> Unit) -> Unit,
    maxTime: Int64,
    maxArraySize: Int64,
    reportResponseEvent: (ResponseEvent) -> Unit,
    reportPageResponseLaggyModel: (InteropPageResponseLaggyModel) -> Unit
): Unit {
    initLaggyHandler(onDisplay, onAbilityBackground, onNavDestinationSwitch, onDidClick, maxTime, maxArraySize,
        reportResponseEvent, reportPageResponseLaggyModel)
}

