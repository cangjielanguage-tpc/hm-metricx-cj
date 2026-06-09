package ohos_app_cangjie_hm_metricx_cj.exitInfo

import ohos.base.AppLog
import std.time.*
import ohos.ark_interop.*
import ohos.ark_interop_macro.*
import std.fs.*
import std.convert.*
import ohos_app_cangjie_hm_metricx_cj.util.readFile

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

// ==================== SwipeKill 相关代码 ====================

let DEFAULT_SWIPE_KILL_THRESHOLD_MS: Int64 = 5000

private var lastBackgroundTime: Int64 = 0
var swipeKillThresholdMs: Int64 = 0
private var swipeKillInited = false
private var exitInfoStr: String = "unknown"

var reportSwipeKillInfoCallback: (data: SwipeKillInfo) -> Unit = {data: SwipeKillInfo =>}

@Interop[ArkTS]
public class SwipeKillInfo {
    public let timestamp: Int64
    public let isUserSwipeKill: Bool
    public let exitInfo: String

    public init(timestamp: Int64, isUserSwipeKill: Bool, exitInfo: String) {
        this.timestamp = timestamp
        this.isUserSwipeKill = isUserSwipeKill
        this.exitInfo = exitInfo
    }

    public func toString(): String {
        return "{\"timestamp\": \"${timestamp}\", \"isUserSwipeKill\": \"${isUserSwipeKill}\", \"exitInfo\": \"${exitInfo}}\""
    }
}

private func saveBackgroundTime() {
    try {
        writeFile(getPersistencePath(), lastBackgroundTime.toString())
    } catch (e: Exception) {
        AppLog.error("[SwipeKill] Save failed: ${e.message}")
    }
}

private func writeFile(path: Path, data: String) {
    try {
        File.writeTo(path, data.toArray())
    } catch (e: FSException) {
        AppLog.error("hm-metricx-cj error: " + e.toString())
    } catch (e: IllegalArgumentException) {
        AppLog.error("hm-metricx-cj error: " + e.toString())
    }
}

private func loadBackgroundTime() {
    try {
        if (exists(getPersistencePath())) {
            lastBackgroundTime = Int64.parse(readFile(getPersistencePath()).trimAscii())
        }
    } catch (e: Exception) {
        AppLog.error("[SwipeKill] Load failed: ${e.message}")
    }
}

private func getPersistencePath(): Path {
    return Path("/data/storage/el2/log/hiappevent/swipe_kill_data.txt")
}

private func clearBackgroundTime() {
    try {
        let path = getPersistencePath()
        if (exists(path)) {
            removeIfExists(path)
        }
    } catch (e: Exception) {}
}

private func lastExitReasonToStr(lastExitReason: Int32): String {
   return match (lastExitReason) {
        case 1 => "ability_not_responding"
        case 2 => "normal"
        case 3 => "cpp_crash"
        case 4 => "js_error"
        case 5 => "app_freeze"
        case 6 => "performance_control"
        case 7 => "resource_control"
        case 8 => "upgrade"
        case _ => "unknown"
    }
}

public func onBackgroundSwipeKill() {
    lastBackgroundTime = getCurrentTimeMillis()
    AppLog.info("[SwipeKill] Background time: ${lastBackgroundTime}")
    saveBackgroundTime()
}

private func reportSwipeKill(launchParamLastExitReason: Int32): Unit {
    let now = getCurrentTimeMillis()
    let timeSinceBg = now - lastBackgroundTime
    let isQuickRestart = timeSinceBg < swipeKillThresholdMs && lastBackgroundTime > 0

    exitInfoStr = lastExitReasonToStr(launchParamLastExitReason)
    AppLog.info("[SwipeKill] getLastExitInfo: ${exitInfoStr}")

    let isUserSwipeKill = isQuickRestart && (exitInfoStr == "unknown" || exitInfoStr == "normal")
    if (isUserSwipeKill) {
        AppLog.warn("[SwipeKill] User swipe kill detected! timeSinceBg: ${timeSinceBg}ms")
    }

    clearBackgroundTime()
    let info = SwipeKillInfo(now, isUserSwipeKill, exitInfoStr)
    reportSwipeKillInfoCallback(info)
}

public func initSwipeKillHandler(
    launchParamLastExitReason: Int32,
    reportSwipeKillHandler: (SwipeKillInfo) -> Unit,
    onAbilityBackground: (cb: () -> Unit) -> Unit,
    thresholdMs: Int64
): Unit {
    if (swipeKillInited) {
        return
    }
    swipeKillInited = true
    swipeKillThresholdMs = thresholdMs
    reportSwipeKillInfoCallback = reportSwipeKillHandler
    loadBackgroundTime()

    onAbilityBackground({=> onBackgroundSwipeKill()})

    AppLog.info("[SwipeKill] Initialized")
    reportSwipeKill(launchParamLastExitReason)
}

public func destroySwipeKillHandler(): Unit {
    reportSwipeKillInfoCallback = {data: SwipeKillInfo =>}
    swipeKillInited = false
}

private func getCurrentTimeMillis(): Int64 {
    DateTime.now().toUnixTimeStamp().toMilliseconds()
}