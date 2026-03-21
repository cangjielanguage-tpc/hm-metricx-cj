
package ohos_app_cangjie_hm_metricx_cj.crash

import ohos.ark_interop_macro.*
import ohos.ark_interop.*
import ohos_app_cangjie_hm_metricx_cj.util.JSHelper
import std.fs.*

@Interop[ArkTS]
public func initCrashHandlerInterop(
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
    initCrashHandler(addCrashWatcher, onCrash, jsExit, collectCrashInfo, jsReportCrashInfo, Path(persistentDir),
        transEnableDumpOnOOM(enableDumpOnOOM), lastNHilogNumber, systemLogNumber, enableMemMonitor)
}

private func transEnableDumpOnOOM(enableDumpOnOOM: Int8): Option<OOMHandlerMode> {
    if (enableDumpOnOOM == 1) {
        OOMHandlerMode.Sync
    } else if (enableDumpOnOOM == 2) {
        OOMHandlerMode.Async
    } else {
        None
    }
}