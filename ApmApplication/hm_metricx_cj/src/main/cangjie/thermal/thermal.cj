/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */
package ohos_app_cangjie_hm_metricx_cj.thermal

import ohos_app_cangjie_hm_metricx_cj.util.*
import std.time.*
import ohos.base.AppLog
import ohos.ark_interop_macro.*
import ohos.ark_interop.*

const DEFAULT_SAMPLE_INTERVAL_MS: Int64 = 5 * 1000
const DEFAULT_REPORT_MIN_INTERVAL_MS: Int64 = 30 * 1000
const DEFAULT_ABNORMAL_LEVEL: Int32 = 2

@Interop[ArkTS]
public class InteropThermalEventInfo {
    public var pageName: String = ""
    public var level: Int32 = -1
    public var levelName: String = ""
    public var threshold: Int32 = -1
    public var isForeground: Bool = true
    public var durationMs: Int64 = 0
    public var timestamp: Int64 = 0

    public init() {}
}

public class ThermalEventInfo {
    private var pageNameValue: ?String = None
    private var levelValue: ?Int32 = None
    private var levelNameValue: ?String = None
    private var thresholdValue: ?Int32 = None
    private var isForegroundValue: ?Bool = None
    private var durationMsValue: ?Int64 = None
    private var timestampValue: ?Int64 = None

    mut prop pageName: ?String { 
        get() { 
            pageNameValue 
        } 
        set(value) { 
            pageNameValue = value 
        } 
    }
    mut prop level: ?Int32 { 
        get() { 
            levelValue 
        } 
        set(value) { 
            levelValue = value 
        } 
    }
    mut prop levelName: ?String { 
        get() { 
            levelNameValue 
        } 
        set(value) { 
            levelNameValue = value 
        } 
    }
    mut prop threshold: ?Int32 { 
        get() { 
            thresholdValue 
        } 
        set(value) { 
            thresholdValue = value 
        } 
    }
    mut prop isForeground: ?Bool { 
        get() { 
            isForegroundValue 
        } 
        set(value) { 
            isForegroundValue = value 
        } 
    }
    mut prop durationMs: ?Int64 { 
        get() { 
            durationMsValue 
        } 
        set(value) { 
            durationMsValue = value 
        } 
    }
    mut prop timestamp: ?Int64 { 
        get() { 
            timestampValue 
        } 
        set(value) { 
            timestampValue = value 
        } 
    }

    func toInteropThermalEventInfo(): InteropThermalEventInfo {
        let o = InteropThermalEventInfo()
        o.pageName = pageNameValue ?? ""
        o.level = levelValue ?? -1
        o.levelName = levelNameValue ?? ""
        o.threshold = thresholdValue ?? -1
        o.isForeground = isForegroundValue ?? false
        o.durationMs = durationMsValue ?? 0
        o.timestamp = timestampValue ?? 0
        o
    }
}

@Interop[ArkTS]
public interface ThermalInfoInterface {
    // 约定：0..7
    func getThermalLevel(): Int32
}

@Interop[ArkTS]
public interface Scheduler {
    func setInterval(cb: () -> Unit, intervalMs: Int64): Int64
    func clearInterval(id: Int64): Unit
}

@Interop[ArkTS]
public interface AppHooks {
    func onAppStateChange(onFg: () -> Unit, onBg: () -> Unit): Unit
    func onNavDestinationSwitch(cb: (String) -> Unit): Unit
}

var _thermalInterface: Option<ThermalInfoInterface> = None
var _scheduler: Option<Scheduler> = None
var _hooks: Option<AppHooks> = None
var _getUptimeMs: () -> Int64 = {=> DateTime.now().toUnixTimeStamp().toMilliseconds()}
var _reportThermalCallback: (info: InteropThermalEventInfo) -> Unit = {_ =>}
var currentPageName: String = defaultPageName
var isForeground: Bool = true
var sampleIntervalMs: Int64 = DEFAULT_SAMPLE_INTERVAL_MS
var reportMinIntervalMs: Int64 = DEFAULT_REPORT_MIN_INTERVAL_MS
var abnormalThresholdLevel: Int32 = DEFAULT_ABNORMAL_LEVEL

var monitorId: Int64 = -1
var lastLevelInt: Int32 = -1
var levelStartTime: Int64 = 0
var lastReportTime: Int64 = 0
var lastAbnormalState: Bool = false

private func levelIntToName(level: Int32): String {
    match (level) {
        case 0 => "COOL"
        case 1 => "NORMAL"
        case 2 => "WARM"
        case 3 => "HOT"
        case 4 => "OVERHEATED"
        case 5 => "WARNING"
        case 6 => "EMERGENCY"
        case 7 => "ESCAPE"
        case _ => "UNKNOWN"
    }
}

private func buildEvent(levelInt: Int32, now: Int64): ThermalEventInfo {
    let info = ThermalEventInfo()
    info.pageName = currentPageName
    info.level = levelInt
    info.levelName = levelIntToName(levelInt)
    info.threshold = abnormalThresholdLevel
    info.isForeground = isForeground
    info.durationMs = now - levelStartTime
    info.timestamp = now
    info
}

private func sampleThermal(force!: Bool = false): Unit {
    if (!force && !isForeground) {
        return
    }

    let now = _getUptimeMs()

    try {
        var levelInt: Int32 = -1
        if (let Some(inter) <- _thermalInterface) {
            levelInt = inter.getThermalLevel()
        } else {
            return
        }

        let prevLevel = lastLevelInt

        if (prevLevel != levelInt) {
            levelStartTime = now
            lastLevelInt = levelInt
        }

        let abnormalNow = levelInt >= abnormalThresholdLevel
        let levelIncreased = prevLevel >= 0 && levelInt > prevLevel

        let shouldReport =
            abnormalNow &&
            (!lastAbnormalState ||
             levelIncreased ||
             (now - lastReportTime) >= reportMinIntervalMs)

        if (shouldReport) {
            let event = buildEvent(levelInt, now)
            _reportThermalCallback(event.toInteropThermalEventInfo())
            lastReportTime = now
        }

        lastAbnormalState = abnormalNow
    } catch (e: Exception) {
        AppLog.warn("hm-metricx-cj thermal sample failed: ${e.toString()}")
    }
}

private func startThermalMonitor(): Unit {
    // stop old
    if (monitorId != -1) {
        if (let Some(s) <- _scheduler) {
            s.clearInterval(monitorId)
        }
        monitorId = -1
    }

    lastLevelInt = -1
    levelStartTime = _getUptimeMs()
    lastReportTime = 0
    lastAbnormalState = false

    if (let Some(s) <- _scheduler) {
        monitorId = s.setInterval({=> sampleThermal()}, sampleIntervalMs)
    } 
    sampleThermal(force: true)
}

private func stopThermalMonitor(): Unit {
    if (monitorId != -1) {
        if (let Some(s) <- _scheduler) {
            s.clearInterval(monitorId)
        }
        monitorId = -1
    }
}

public func onAppForegroundCallBack(): Unit {
    isForeground = true
    startThermalMonitor()
}

public func onAppBackgroundCallBack(): Unit {
    sampleThermal(force: true)
    isForeground = false
    stopThermalMonitor()
}

public func onNavDestinationSwitchCallBack(targetPageName: String): Unit {
    if (!targetPageName.isEmpty()) {
        currentPageName = targetPageName
    }
}

// ========== init/destroy：注入所有依赖（改成 Scheduler + AppHooks） ==========
public func initThermalHandler(
    getUptimeMs: () -> Int64,
    thermalInterface: ThermalInfoInterface,
    scheduler: Scheduler,
    hooks: AppHooks,
    reportThermalInfo: (info: InteropThermalEventInfo) -> Unit,
    sampleInterval!: Int64 = DEFAULT_SAMPLE_INTERVAL_MS,
    reportMinInterval!: Int64 = DEFAULT_REPORT_MIN_INTERVAL_MS,
    abnormalThreshold!: Int32 = DEFAULT_ABNORMAL_LEVEL
): Unit {
    _getUptimeMs = getUptimeMs
    _thermalInterface = thermalInterface
    _scheduler = Some(scheduler)
    _hooks = Some(hooks)
    _reportThermalCallback = reportThermalInfo

    sampleIntervalMs = sampleInterval
    reportMinIntervalMs = reportMinInterval
    abnormalThresholdLevel = abnormalThreshold

    hooks.onAppStateChange(onAppForegroundCallBack, onAppBackgroundCallBack)
    hooks.onNavDestinationSwitch(onNavDestinationSwitchCallBack)

    isForeground = true
    startThermalMonitor()
}

public func destroyThermalHandler(): Unit {
    _reportThermalCallback = {_ =>}
    stopThermalMonitor()
}