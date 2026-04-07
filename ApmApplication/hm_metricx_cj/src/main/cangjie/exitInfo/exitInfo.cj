package ohos_app_cangjie_hm_metricx_cj.exitInfo

import ohos.base.AppLog
import std.time.*
import ohos.ark_interop.*
import ohos.ark_interop_macro.*

// ---------------- 全局状态 ----------------
var currentAppState: String = "foreground"
var lastStateChangeTime: Int64 = 0
private var inited: Bool = false

// ---------------- 数据类 ----------------
@Interop[ArkTS]
public class ExitInfo {
    public let exitMessage: String
    public let exitReason: String
    public let isBackground: Bool
    public let appState: String
    public let stateChangeTime: Int64
    public let timestamp: Int64

    public init(
        exitMessage: String,
        exitReason: String,
        isBackground: Bool,
        appState: String,
        stateChangeTime: Int64,
        timestamp: Int64
    ) {
        this.exitMessage = exitMessage
        this.exitReason = exitReason
        this.isBackground = isBackground
        this.appState = appState
        this.stateChangeTime = stateChangeTime
        this.timestamp = timestamp
    }
}

@Interop[ArkTS]
public class AppStateInfo {
    public let appState: String
    public let stateChangeTime: Int64
    public let timestamp: Int64

    public init(
        appState: String,
        stateChangeTime: Int64,
        timestamp: Int64
    ) {
        this.appState = appState
        this.stateChangeTime = stateChangeTime
        this.timestamp = timestamp
    }
}

// ---------------- 回调 ----------------
var reportExitInfoCallback: (data: ExitInfo) -> Unit = {data: ExitInfo =>}
var reportAppStateCallback: (data: AppStateInfo) -> Unit = {data: AppStateInfo =>}

// ---------------- 工具方法 ----------------
private func nowMs(): Int64 {
    DateTime.now().toUnixTimeStamp().toMilliseconds()
}

private func reportExitInfo(exitInfo: ExitInfo): Unit {
    AppLog.info("hm-metricx-cj exitInfo report: ${exitInfo.exitMessage}")
    reportExitInfoCallback(exitInfo)
}

private func reportAppState(appStateInfo: AppStateInfo): Unit {
    AppLog.info("hm-metricx-cj appState report: ${appStateInfo.appState}")
    reportAppStateCallback(appStateInfo)
}

private func updateAppState(state: String): Unit {
    currentAppState = state
    lastStateChangeTime = nowMs()
    reportAppState(AppStateInfo(currentAppState, lastStateChangeTime, nowMs()))
}

// ---------------- 状态操作 ----------------
private func setForeground(): Unit {
    updateAppState("foreground")
}

private func setBackground(): Unit {
    updateAppState("background")
}

// ---------------- 公共接口 ----------------
public func initExitInfoHandler(
    lastExitMessage: String,
    lastExitReason: Int32,
    reportExitInfoHandler: (ExitInfo) -> Unit,
    reportAppStateHandler: (AppStateInfo) -> Unit
): Unit {
    if (inited) {
        return
    }

    reportExitInfoCallback = reportExitInfoHandler
    reportAppStateCallback = reportAppStateHandler

    currentAppState = "foreground"
    lastStateChangeTime = nowMs()

    reportAppState(AppStateInfo(currentAppState, lastStateChangeTime, nowMs()))
    reportExitInfo(
        ExitInfo(
            lastExitMessage,
            lastExitReasonToString(lastExitReason),
            currentAppState == "background",
            currentAppState,
            lastStateChangeTime,
            nowMs()
        )
    )

    inited = true
}

public func destroyExitInfoHandler(): Unit {
    reportExitInfoCallback = {data: ExitInfo =>}
    reportAppStateCallback = {data: AppStateInfo =>}
    inited = false
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