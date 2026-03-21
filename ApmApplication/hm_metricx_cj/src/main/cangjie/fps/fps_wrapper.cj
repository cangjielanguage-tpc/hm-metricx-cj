
package ohos_app_cangjie_hm_metricx_cj.fps

import ohos.ark_interop_macro.*
import ohos.ark_interop.*
import ohos_app_cangjie_hm_metricx_cj.util.*

@Interop[ArkTS]
public func initPageEventHandlerInterop(
    onDisplay: DisplaySync,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    onWindowEvent: (() -> Unit, () -> Unit) -> Unit,
    reportFpsInfo: (FpsEventInfo) -> Unit
): Unit {
    initPageEventHandler(onDisplay, onNavDestinationSwitch, reportFpsInfo)
    initPageEventHandler(onDisplay, onWindowEvent, reportFpsInfo)
}

@Interop[ArkTS]
public func initScrollEventHandlerInterop(
    onDisplay: DisplaySync,
    onScrollEvect: (() -> Unit, () -> Unit) -> Unit,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    reportPageScrollInfo: (ScrollHitchInfo) -> Unit
): Unit {
    initScrollEventHandler(onDisplay, onScrollEvect, onNavDestinationSwitch, reportPageScrollInfo)
}
