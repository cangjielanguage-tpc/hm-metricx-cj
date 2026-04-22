
package ohos_app_cangjie_hm_metricx_cj.crash

import ohos.ark_interop_macro.*
import ohos.ark_interop.*
import ohos_app_cangjie_hm_metricx_cj.util.JSHelper
import std.fs.*

@Interop[ArkTS]
public func initCrashHandlerInterop(
    addCrashWatcher: ((String, String, String, String, String, String, String) -> Unit) -> Unit,
    addResourceLeakWatcher: ((String, String, String, Int64, Int64, String) -> Unit) -> Unit,
    onCrash: (() -> Unit) -> Unit,
    exit: () -> Unit,
    collectCrashInfo: () -> String,
    reportCrashInfo: (InteropCrashInfo) -> Unit,
    persistentDir: String,
    enableDumpOnOOM: Int8,
    lastNHilogNumber: Int64,
    systemLogNumber: Int64,
    enableMemMonitor: Option<CMemMonitorConfig>,
    reportRawheap: (InteropRawheapInfo) -> Unit
): Unit {
    let jsReportCrashInfo = {crashInfo => JSHelper.postJSTask {reportCrashInfo(crashInfo)}}
    let jsExit = {=> JSHelper.postJSTask {exit()}}
    let jsReportRawheap = {info => JSHelper.postJSTask {reportRawheap(info)}}
    initCrashHandler(addCrashWatcher, addResourceLeakWatcher, onCrash, jsExit, collectCrashInfo, jsReportCrashInfo, Path(persistentDir),
        transEnableDumpOnOOM(enableDumpOnOOM), enableMemMonitor, jsReportRawheap, lastNHilogNumber: lastNHilogNumber, systemLogNumber: systemLogNumber)
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