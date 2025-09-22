/**
 * Created on 2025/5/23
 */
package ohos_app_cangjie_hm_metricx_cj.exitInfo

import ohos.ark_interop.*
import ohos.ark_interop_macro.*

@Interop[ArkTS]
public class ExitInfo {
    public let lastExitMessage: String
    public let lastExitReason: String

    public init(exitMessage: String, exitReason: String) {
        this.lastExitMessage = exitMessage
        this.lastExitReason = exitReason
    }
}

public func getExitInfo(lastExitMessage: String, lastExitReason: Int32) {
    ExitInfo(lastExitMessage, lastExitReasonToString(lastExitReason))
}

private func lastExitReasonToString(value: Int32) {
    match (LastExitReason.parse(value)) {
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

public enum LastExitReason {
    | UNKNOWN
    | ABILITY_NOT_RESPONDING
    | NORMAL
    | CPP_CRASH
    | JS_ERROR
    | APP_FREEZE
    | PERFORMANCE_CONTROL
    | RESOURCE_CONTROL
    | UPGRADE

    protected func get(): Int32 {
        match (this) {
            case UNKNOWN => 0
            case ABILITY_NOT_RESPONDING => 1
            case NORMAL => 2
            case CPP_CRASH => 3
            case JS_ERROR => 4
            case APP_FREEZE => 5
            case PERFORMANCE_CONTROL => 6
            case RESOURCE_CONTROL => 7
            case UPGRADE => 8
        }
    }

    protected static func parse(val: Int32): LastExitReason {
        match (val) {
            case 0 => UNKNOWN
            case 1 => ABILITY_NOT_RESPONDING
            case 2 => NORMAL
            case 3 => CPP_CRASH
            case 4 => JS_ERROR
            case 5 => APP_FREEZE
            case 6 => PERFORMANCE_CONTROL
            case 7 => RESOURCE_CONTROL
            case 8 => UPGRADE
            case _ => throw IllegalArgumentException("unknown value ${val}")
        }
    }
}
