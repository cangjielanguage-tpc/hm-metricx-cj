/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */
package ohos_app_cangjie_hm_metricx_cj.thermal

import ohos_app_cangjie_hm_metricx_cj.util.*
import std.time.*
import std.runtime.getProcessorCount
import ohos.base.AppLog
import ohos.ark_interop_macro.*
import ohos.ark_interop.*

const DEFAULT_SAMPLE_INTERVAL_MS: Int64 = 5 * 1000
const DEFAULT_REPORT_MIN_INTERVAL_MS: Int64 = 30 * 1000
const DEFAULT_ABNORMAL_LEVEL: Int32 = 2

@Interop[ArkTS]
public class InteropThermalEventInfo {
    public var pageName: String = ""
    public var prevLevel: Int32 = -1
    public var level: Int32 = -1
    public var levelName: String = ""
    public var levelChange: String = "UNKNOWN"
    public var threshold: Int32 = -1
    public var isForeground: Bool = true
    public var durationMs: Int64 = 0
    public var timestamp: Int64 = 0
    public var cpuNum: Int32 = -1

    public init() {}
}

@Interop[ArkTS]
public interface ThermalInfoInterface {
    func getThermalLevel(): Int32
}

@Interop[ArkTS]
public interface AppHooks {
    func onAppStateChange(onFg: () -> Unit, onBg: () -> Unit): Unit
    func onNavDestinationSwitch(cb: (String) -> Unit): Unit
}

var _thermalInterface: Option<ThermalInfoInterface> = None
var _hooks: Option<AppHooks> = None
var _getUptimeMs: () -> Int64 = {=> DateTime.now().toUnixTimeStamp().toMilliseconds()}
var _reportThermalCallback: (info: InteropThermalEventInfo) -> Unit = {_ =>}
var _stopSampleThermal: () -> Unit = {=>}

var currentPageName: String = defaultPageName
var isForeground: Bool = true
var sampleIntervalMs: Int64 = DEFAULT_SAMPLE_INTERVAL_MS
var reportMinIntervalMs: Int64 = DEFAULT_REPORT_MIN_INTERVAL_MS
var abnormalThresholdLevel: Int32 = DEFAULT_ABNORMAL_LEVEL

var lastLevelInt: Int32 = -1
var levelStartTime: Int64 = 0
var lastReportTime: Int64 = 0
var lastAbnormalState: Bool = false

// CPU 核心数：静态系统属性，init 时读取一次缓存即可
var cpuNum: Int32 = -1

var started: Bool = false
var destroyed: Bool = false

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

private func getSensitiveLevelGroup(level: Int32): Int32 {
    match (level) {
        case 0 => 0
        case 1 => 0
        case 2 => 1
        case 3 => 1
        case 4 => 2
        case 5 => 2
        case 6 => 3
        case 7 => 3
        case _ => -1
    }
}

private func getLevelChange(prevLevel: Int32, levelInt: Int32): String {
    let prevGroup = getSensitiveLevelGroup(prevLevel)
    let currentGroup = getSensitiveLevelGroup(levelInt)
    if (prevGroup < 0 || currentGroup < 0) {
        return "UNKNOWN"
    }
    if (currentGroup > prevGroup) {
        return "LEVEL UP"
    }
    if (currentGroup < prevGroup) {
        return "LEVEL DOWN"
    }
    return "LEVEL UNCHANGE"
}

private func buildEvent(levelInt: Int32, prevLevel: Int32, now: Int64): InteropThermalEventInfo {
    let info = InteropThermalEventInfo()
    info.pageName = currentPageName
    info.prevLevel = prevLevel
    info.level = levelInt
    info.levelName = levelIntToName(levelInt)
    info.levelChange = getLevelChange(prevLevel, levelInt)
    info.threshold = abnormalThresholdLevel
    info.isForeground = isForeground
    info.durationMs = now - levelStartTime
    info.timestamp = now
    info.cpuNum = cpuNum
    info
}

private func resetThermalState(): Unit {
    lastLevelInt = -1
    levelStartTime = _getUptimeMs()
    lastReportTime = 0
    lastAbnormalState = false

}

public func sampleThermal(force!: Bool = false): Unit {
    if (destroyed || !started) {
        return
    }
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
        let prevLevelGroup = getSensitiveLevelGroup(prevLevel)
        let currentLevelGroup = getSensitiveLevelGroup(levelInt)
        let levelChanged = prevLevelGroup >= 0 && currentLevelGroup >= 0 && prevLevelGroup != currentLevelGroup
        if (currentLevelGroup >= 0 && (prevLevelGroup < 0 || levelChanged)) {
            levelStartTime = now
        }
        if (currentLevelGroup >= 0 && prevLevel != levelInt) {
            lastLevelInt = levelInt
        }

        let abnormalNow = levelInt >= abnormalThresholdLevel

        let shouldReport =
            isForeground &&
            (
                levelChanged ||
                (
                    abnormalNow &&
                    (
                        !lastAbnormalState ||
                        (now - lastReportTime) >= reportMinIntervalMs
                    )
                )
            )

        if (shouldReport) {
            let event = buildEvent(levelInt, prevLevel, now)
            _reportThermalCallback(event)
            lastReportTime = now
        }

        lastAbnormalState = abnormalNow
    } catch (e: Exception) {
        AppLog.warn("hm-metricx-cj thermal sample failed: ${e.toString()}")
    }
}

private func startThermalMonitor(repeatSampleThermal: (() -> Unit) -> Unit): Unit {
    started = true
    destroyed = false
    resetThermalState()

    repeatSampleThermal({=> sampleThermal()})
    sampleThermal(force: true)
}

private func stopThermalMonitor(): Unit {
    started = false
    try {
        _stopSampleThermal()
    } catch (e: Exception) {
        AppLog.warn("hm-metricx-cj thermal stop sample failed: ${e.toString()}")
    }
}

public func onAppForegroundCallBack(): Unit {
    if (destroyed) {
        return
    }
    isForeground = true
    resetThermalState()
    sampleThermal(force: true)
}

public func onAppBackgroundCallBack(): Unit {
    if (destroyed) {
        return
    }
    isForeground = false
}

public func onNavDestinationSwitchCallBack(targetPageName: String): Unit {
    if (!targetPageName.isEmpty()) {
        currentPageName = targetPageName
    }
}

public func initThermalHandler(
    getUptimeMs: () -> Int64,
    thermalInterface: ThermalInfoInterface,
    hooks: AppHooks,
    repeatSampleThermal: (() -> Unit) -> Unit,
    stopSampleThermal: () -> Unit,
    reportThermalInfo: (info: InteropThermalEventInfo) -> Unit,
    sampleInterval!: Int64 = DEFAULT_SAMPLE_INTERVAL_MS,
    reportMinInterval!: Int64 = DEFAULT_REPORT_MIN_INTERVAL_MS,
    abnormalThreshold!: Int32 = DEFAULT_ABNORMAL_LEVEL
): Unit {
    destroyed = false
    started = false

    _getUptimeMs = getUptimeMs
    _thermalInterface = Some(thermalInterface)
    _hooks = Some(hooks)
    _reportThermalCallback = reportThermalInfo
    _stopSampleThermal = stopSampleThermal

    sampleIntervalMs = sampleInterval
    reportMinIntervalMs = reportMinInterval
    abnormalThresholdLevel = abnormalThreshold

    // 读取并缓存 CPU 核心数（静态属性，整个生命周期内不变）
    cpuNum = Int32(getProcessorCount())

    hooks.onAppStateChange(onAppForegroundCallBack, onAppBackgroundCallBack)
    hooks.onNavDestinationSwitch(onNavDestinationSwitchCallBack)

    isForeground = true
    startThermalMonitor(repeatSampleThermal)
}

public func destroyThermalHandler(): Unit {
    destroyed = true
    started = false
    _reportThermalCallback = {_ =>}
    stopThermalMonitor()
}
