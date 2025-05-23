/**
 * Created on 2025/5/23
 */
package ohos_app_cangjie_hm_metricx_cj.exitInfo

import tpc.AbilityKit.AbilityConstant.LaunchParam
import tpc.AbilityKit.AbilityConstant.LastExitReason

public class ExitInfo {
    public ExitInfo(let exitMessage: String, let exitReason: String) {}
}

public func getExitInfo(launchParam: LaunchParam) {
    ExitInfo(launchParam.lastExitMessage, lastExitReasonToString(launchParam.lastExitReason))
}

private func lastExitReasonToString(lastExitReason: LastExitReason) {
    match (lastExitReason) {
        case LastExitReason.ABILITY_NOT_RESPONDING => "ability_not_responding"
        case LastExitReason.APP_FREEZE => "app_freeze"
        case LastExitReason.CPP_CRASH => "cpp_crash"
        case LastExitReason.JS_ERROR => "js_error"
        case LastExitReason.UNKNOWN => "unknown"
        case LastExitReason.NORMAL => "normal"
        case LastExitReason.PERFORMANCE_CONTROL => "performance_control"
        case LastExitReason.RESOURCE_CONTROL => "resource_control"
        case LastExitReason.UPGRADE => "upgrade"
    }
}
