/**
 * Created on 2025/9/18
 */
package ohos_app_cangjie_hm_metricx_cj.wrapper

import ohos_app_cangjie_hm_metricx_cj.traffic.TrafficPreference
import ohos_app_cangjie_hm_metricx_cj.traffic.initTrafficHandler as _initTrafficHandler
import ohos_app_cangjie_hm_metricx_cj.traffic.destroyTrafficHandler as _destroyTrafficHandler
import ohos_app_cangjie_hm_metricx_cj.traffic.InteropSampleTrafficInfo
import ohos_app_cangjie_hm_metricx_cj.storage.initStorageHandler as _initStorageHandler
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
import ohos_app_cangjie_hm_metricx_cj.freeze.InteropFreezeInfo
import ohos_app_cangjie_hm_metricx_cj.freeze.initFreezeHandler as _initFreezeHandler
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
    exit: () -> Unit,
    collectCrashInfo: () -> String,
    reportCrashInfo: (InteropCrashInfo) -> Unit,
    persistentDir: String,
    enableDumpOnOOM: Int8,
    lastNHilogNumber: Int64,
    systemLogNumber: Int64,
    enableMemMonitor: Option<CMemMonitorConfig>
): Unit {
    _initCrashHandler(exit, collectCrashInfo, reportCrashInfo, Path(persistentDir),
        transEnableDumpOnOOM(enableDumpOnOOM), lastNHilogNumber, systemLogNumber, enableMemMonitor)
}

@Interop[ArkTS]
public func getExitInfo(lastExitMessage: String, lastExitReason: Int32): Unit {
    _getExitInfo(lastExitMessage, lastExitReason)
}

@Interop[ArkTS]
public func initFreezeHandler(
    onFreeze: (() -> Unit) -> Unit,
    collectFreezeInfo: () -> String,
    reportFreezeInfo: (InteropFreezeInfo) -> Unit,
    persistentDir: String): Unit {
    _initFreezeHandler(onFreeze, collectFreezeInfo, reportFreezeInfo, Path(persistentDir))
}

@Interop[ArkTS]
public func initTrafficHandler(
    preference: TrafficPreference,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatSampleTraffic: (() -> Unit) -> Unit,
    getUidRxAndTxBytes: ((Int64, Int64) -> Unit) -> Unit,
    reportTraffic: (InteropSampleTrafficInfo) -> Unit,
    sampleThreshold: Int64
): Unit {
    _initTrafficHandler(preference, onNavDestinationSwitch, repeatSampleTraffic, getUidRxAndTxBytes, reportTraffic,
        sampleThreshold: sampleThreshold)
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
