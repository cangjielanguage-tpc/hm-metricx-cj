/**
 * Created on 2025/9/18
 */
package ohos_app_cangjie_hm_metricx_cj.wrapper

import ohos_app_cangjie_hm_metricx_cj.traffic.TrafficPreference
import ohos_app_cangjie_hm_metricx_cj.traffic.initTrafficHandler as _initTrafficHandler
import ohos_app_cangjie_hm_metricx_cj.traffic.destroyTrafficHandler as _destroyTrafficHandler
import ohos_app_cangjie_hm_metricx_cj.traffic.InteropSampleTrafficInfo
import ohos_app_cangjie_hm_metricx_cj.storage.initStorageHandler as _initStorageHandler
import ohos_app_cangjie_hm_metricx_cj.traffic.InteropDayTrafficInfo
import ohos_app_cangjie_hm_metricx_cj.traffic.getYesterdayTraffic as _getYesterdayTraffic
import ohos_app_cangjie_hm_metricx_cj.storage.reportAppStorageInfo as _reportAppStorageInfo
import ohos_app_cangjie_hm_metricx_cj.storage.InteropStorageInfo
import ohos_app_cangjie_hm_metricx_cj.cpu.initCpuHandler as _initCpuHandler
import ohos_app_cangjie_hm_metricx_cj.cpu.getPageCpuInfo as _getPageCpuInfo
import ohos_app_cangjie_hm_metricx_cj.cpu.getProcessCpuInfo as _getProcessCpuInfo
import ohos.ark_interop_macro.*
import ohos.ark_interop.*
import ohos_app_cangjie_hm_metricx_cj.cpu.InteropProcessCpuInfo
import ohos_app_cangjie_hm_metricx_cj.cpu.InteropPageCpuInfo
import ohos_app_cangjie_hm_metricx_cj.crash.OOMHandlerMode
import ohos_app_cangjie_hm_metricx_cj.crash.CMemMonitorConfig
import ohos_app_cangjie_hm_metricx_cj.crash.InteropCrashInfo
import ohos_app_cangjie_hm_metricx_cj.crash.initCrashHandler as _initCrashHandler
import ohos_app_cangjie_hm_metricx_cj.exitInfo.getExitInfo as _getExitInfo
import ohos_app_cangjie_hm_metricx_cj.exitInfo.ExitInfo
import ohos_app_cangjie_hm_metricx_cj.freeze.InteropFreezeInfo
import ohos_app_cangjie_hm_metricx_cj.freeze.initFreezeHandler as _initFreezeHandler
import ohos_app_cangjie_hm_metricx_cj.memory.MemoryPreference
import ohos_app_cangjie_hm_metricx_cj.memory.InteropPageMemoryInfo
import ohos_app_cangjie_hm_metricx_cj.memory.InteropProcessMemoryInfo
import ohos_app_cangjie_hm_metricx_cj.memory.getPageMemoryInfo as _getPageMemoryInfo
import ohos_app_cangjie_hm_metricx_cj.memory.getProcessMemoryInfo as _getProcessMemoryInfo
import ohos_app_cangjie_hm_metricx_cj.memory.initMemoryHandler as _initMemoryHandler
import ohos_app_cangjie_hm_metricx_cj.memory.destroyMemoryHandler as _destroyMemoryHandler
import ohos_app_cangjie_hm_metricx_cj.battery.InteropBatteryUsageInfo
import ohos_app_cangjie_hm_metricx_cj.battery.InteropAllThreadCpuUsageInfo
import ohos_app_cangjie_hm_metricx_cj.battery.BatteryInfoInterface
import ohos_app_cangjie_hm_metricx_cj.battery.initBatteryHandler as _initBatteryHandler
import ohos_app_cangjie_hm_metricx_cj.fps.ScrollHitchInfo
import ohos_app_cangjie_hm_metricx_cj.fps.FpsEventInfo
import ohos_app_cangjie_hm_metricx_cj.fps.initPageEventHandler as _initPageEventHandler
import ohos_app_cangjie_hm_metricx_cj.fps.initScrollEventHandler as _initScrollEventHandler
import ohos_app_cangjie_hm_metricx_cj.laggy.ClickInfo
import ohos_app_cangjie_hm_metricx_cj.laggy.ResponseEvent
import ohos_app_cangjie_hm_metricx_cj.laggy.InteropPageResponseLaggyModel
import ohos_app_cangjie_hm_metricx_cj.laggy.initLaggyHandler as _initLaggyHandler
import ohos_app_cangjie_hm_metricx_cj.util.DisplaySyncInterface
import ohos_app_cangjie_hm_metricx_cj.util.Logger
import ohos_app_cangjie_hm_metricx_cj.util.initLogger as _initLogger
import ohos_app_cangjie_hm_metricx_cj.util.JSHelper
import std.fs.*

private func transEnableDumpOnOOM(enableDumpOnOOM: Int8): Option<OOMHandlerMode> {
    if (enableDumpOnOOM == 1) {
        OOMHandlerMode.Sync
    } else if (enableDumpOnOOM == 2) {
        OOMHandlerMode.Async
    } else {
        None
    }
}

@Interop[ArkTS]
public func initCrashHandler(
    addCrashWatcher: ((String, String, String, String, String, String, String) -> Unit) -> Unit,
    onCrash: (() -> Unit) -> Unit,
    exit: () -> Unit,
    collectCrashInfo: () -> String,
    reportCrashInfo: (InteropCrashInfo) -> Unit,
    persistentDir: String,
    enableDumpOnOOM: Int8,
    lastNHilogNumber: Int64,
    systemLogNumber: Int64,
    enableMemMonitor: Option<CMemMonitorConfig>
): Unit {
    let jsReportCrashInfo = {crashInfo => JSHelper.postJSTask {reportCrashInfo(crashInfo)}}
    let jsExit = {=> JSHelper.postJSTask {exit()}}
    _initCrashHandler(addCrashWatcher, onCrash, jsExit, collectCrashInfo, jsReportCrashInfo, Path(persistentDir),
        transEnableDumpOnOOM(enableDumpOnOOM), lastNHilogNumber, systemLogNumber, enableMemMonitor)
}

@Interop[ArkTS]
public func getExitInfo(lastExitMessage: String, lastExitReason: Int32): ExitInfo {
    _getExitInfo(lastExitMessage, lastExitReason)
}

@Interop[ArkTS]
public func initFreezeHandler(sdkApiVersion: Int64,
    addFreezeWatcher: ((String, String, String, String, String) -> Unit) -> Unit, onFreeze: (() -> Unit) -> Unit,
    collectFreezeInfo: () -> String, reportFreezeInfo: (InteropFreezeInfo) -> Unit, persistentDir: String): Unit {
    _initFreezeHandler(sdkApiVersion, addFreezeWatcher, onFreeze, collectFreezeInfo, reportFreezeInfo,
        Path(persistentDir))
}

@Interop[ArkTS]
public func initTrafficHandler(
    preference: TrafficPreference,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatSampleTraffic: (() -> Unit) -> Unit,
    getUidRxAndTxBytes: ((Int64, Int64, String) -> Unit, String) -> Unit,
    reportTraffic: (InteropSampleTrafficInfo) -> Unit,
    sampleThreshold: Int64
): Unit {
    _initTrafficHandler(preference, onNavDestinationSwitch, repeatSampleTraffic, getUidRxAndTxBytes, reportTraffic,
        sampleThreshold: sampleThreshold)
}

@Interop[ArkTS]
public func getYesterdayTraffic(): Option<InteropDayTrafficInfo> {
    _getYesterdayTraffic()
}

@Interop[ArkTS]
public func destroyTrafficHandler(getUidRxAndTxBytes: ((Int64, Int64) -> Unit) -> Unit): Unit {
    _destroyTrafficHandler(getUidRxAndTxBytes)
}

@Interop[ArkTS]
public func initStorageHandler(reportStorageInfo: (InteropStorageInfo) -> Unit, sizeLimit: Int64, dirSizeLimit: Int64,
    reportTopNum: Int64): Unit {
    _initStorageHandler(reportStorageInfo, sizeLimit: sizeLimit, dirSizeLimit: dirSizeLimit, reportTopNum: reportTopNum)
}

@Interop[ArkTS]
public func reportAppStorageInfo(getCurrentBundleStats: ((Int64, Int64, Int64) -> Unit) -> Unit): Unit {
    _reportAppStorageInfo(getCurrentBundleStats)
}

@Interop[ArkTS]
public func getPageCpuInfo(): InteropPageCpuInfo {
    _getPageCpuInfo()
}

@Interop[ArkTS]
public func getProcessCpuInfo(): InteropProcessCpuInfo {
    _getProcessCpuInfo()
}

@Interop[ArkTS]
public func initCpuHandler(
    getCpuUsage: () -> Float64,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatSampleAndReportCpu: (() -> Unit, () -> Unit) -> Unit,
    reporPageCpuInfo: (InteropPageCpuInfo) -> Unit,
    reporProcessCpuInfo: (InteropProcessCpuInfo) -> Unit
): Unit {
    _initCpuHandler(getCpuUsage, onNavDestinationSwitch, repeatSampleAndReportCpu, reporPageCpuInfo, reporProcessCpuInfo)
}

@Interop[ArkTS]
public func getPageMemoryInfo(): InteropPageMemoryInfo {
    _getPageMemoryInfo()
}

@Interop[ArkTS]
public func getProcessMemoryInfo(): InteropProcessMemoryInfo {
    _getProcessMemoryInfo()
}

@Interop[ArkTS]
public func initMemoryHandler(
    memoryPreference: MemoryPreference,
    getMemoryUsage: () -> Int64,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatSampleAndReportMemory: (() -> Unit, () -> Unit) -> Unit,
    reporPageMemoryInfo: (InteropPageMemoryInfo) -> Unit,
    reporProcessMemoryInfo: (InteropProcessMemoryInfo) -> Unit,
    memoryThreshold: Int64
): Unit {
    _initMemoryHandler(memoryPreference, getMemoryUsage, onNavDestinationSwitch, repeatSampleAndReportMemory,
        reporPageMemoryInfo, reporProcessMemoryInfo, memoryThreshold: memoryThreshold)
}

@Interop[ArkTS]
public func destroyMemoryHandler(): Unit {
    _destroyMemoryHandler()
}

@Interop[ArkTS]
public func initBatteryHandler(
    subscribe: (() -> Unit, () -> Unit, () -> Unit) -> Unit,
    getUptime: () -> Int64,
    batteryInterface: BatteryInfoInterface,
    getBrightness: () -> Int32,
    onApplicationStateChange: (() -> Unit, () -> Unit) -> Unit,
    onAbilityForeground: (() -> Unit) -> Unit,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    getRunningProcessInfo: ((Bool) -> Unit) -> Unit,
    repeatHandleCpuUsage: (() -> Unit) -> Unit,
    reportBatteryInfo: (InteropBatteryUsageInfo) -> Unit,
    reportThreadCpuUsageInfo: (InteropAllThreadCpuUsageInfo) -> Unit,
    limit: Int32
): Unit {
    _initBatteryHandler(subscribe, getUptime, batteryInterface, getBrightness, onApplicationStateChange,
        onAbilityForeground, onNavDestinationSwitch, getRunningProcessInfo, repeatHandleCpuUsage, reportBatteryInfo,
        reportThreadCpuUsageInfo, limit: limit)
}

@Interop[ArkTS]
public func initScrollEventHandler(
    onDisplay: DisplaySyncInterface,
    onScrollEvect: (() -> Unit, () -> Unit) -> Unit,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    reportPageScrollInfo: (ScrollHitchInfo) -> Unit
): Unit {
    _initScrollEventHandler(onDisplay, onScrollEvect, onNavDestinationSwitch, reportPageScrollInfo)
}

@Interop[ArkTS]
public func initPageEventHandler(
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    onWindowEvent: (() -> Unit, () -> Unit) -> Unit,
    reportFpsInfo: (FpsEventInfo) -> Unit
): Unit {
    _initPageEventHandler(onNavDestinationSwitch, reportFpsInfo)
    _initPageEventHandler(onWindowEvent, reportFpsInfo)
}

@Interop[ArkTS]
public func initLaggyHandler(
    onDisplay: DisplaySyncInterface,
    onAbilityBackground: (() -> Unit) -> Unit,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    onDidClick: ((ClickInfo) -> Unit) -> Unit,
    maxTime: Int64,
    maxArraySize: Int64,
    reportResponseEvent: (ResponseEvent) -> Unit,
    reportPageResponseLaggyModel: (InteropPageResponseLaggyModel) -> Unit
): Unit {
    _initLaggyHandler(onDisplay, onAbilityBackground, onNavDestinationSwitch, onDidClick, maxTime, maxArraySize,
        reportResponseEvent, reportPageResponseLaggyModel)
}

@Interop[ArkTS]
public func initLogger(logger: Logger): Unit {
    _initLogger(logger)
}
