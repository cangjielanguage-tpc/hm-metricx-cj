/**
 * Created on 2025/3/28
 */
package ohos_app_cangjie_hm_metricx_cj.freeze

import ohos_app_cangjie_hm_metricx_cj.util.*
import std.fs.*
import std.collection.*
import ohos.ark_interop_macro.*
import ohos.ark_interop.*

public class FreezeInfo {
    private var timestampValue: ?String = None
    private var pidValue: ?String = None
    private var exceptionValue: ?String = None
    private var hilogValue: ?String = None
    private var tidValue: ?String = None
    private var tnameValue: ?String = None
    private var extraInfoValue: ?String = None
    private var freezeLogPathValue: ?String = None
    private var cpuThreadValue: ?HashMap<String, String> = None
    private var cpuValue: ?HashMap<String, String> = None
    private var stacktraceValue: ?ArrayList<String> = None
    private var rawFileValue: ?String = None
    private var historyRawFilesValue: ?String = None

    public mut prop timestamp: ?String {
        get() {
            timestampValue
        }
        set(value) {
            timestampValue = value
        }
    }

    public mut prop pid: ?String {
        get() {
            pidValue
        }
        set(value) {
            pidValue = value
        }
    }

    public mut prop exception: ?String {
        get() {
            exceptionValue
        }
        set(value) {
            exceptionValue = value
        }
    }

    public mut prop hilog: ?String {
        get() {
            hilogValue
        }
        set(value) {
            hilogValue = value
        }
    }

    public mut prop tid: ?String {
        get() {
            tidValue
        }
        set(value) {
            tidValue = value
        }
    }

    public mut prop tname: ?String {
        get() {
            tnameValue
        }
        set(value) {
            tnameValue = value
        }
    }

    public mut prop extraInfo: ?String {
        get() {
            extraInfoValue
        }
        set(value) {
            extraInfoValue = value
        }
    }

    public mut prop freezeLogPath: ?String {
        get() {
            freezeLogPathValue
        }
        set(value) {
            freezeLogPathValue = value
        }
    }

    public mut prop cpuThread: ?HashMap<String, String> {
        get() {
            cpuThreadValue
        }
        set(value) {
            cpuThreadValue = value
        }
    }

    public mut prop cpu: ?HashMap<String, String> {
        get() {
            cpuValue
        }
        set(value) {
            cpuValue = value
        }
    }

    public mut prop stacktrace: ?ArrayList<String> {
        get() {
            stacktraceValue
        }
        set(value) {
            stacktraceValue = value
        }
    }

    public mut prop rawFile: ?String {
        get() {
            rawFileValue
        }
        set(value) {
            rawFileValue = value
        }
    }

    public mut prop historyRawFiles: ?String {
        get() {
            historyRawFilesValue
        }
        set(value) {
            historyRawFilesValue = value
        }
    }

    func toInteropFreezeInfo(): InteropFreezeInfo {
        let freezeInfo = InteropFreezeInfo()
        freezeInfo.timestamp = timestampValue
        freezeInfo.pid = pidValue
        freezeInfo.exception = exceptionValue
        freezeInfo.hilog = hilogValue
        freezeInfo.tid = tidValue
        freezeInfo.tname = tnameValue
        if (let Some(v) <- extraInfoValue) {
            freezeInfo.extraInfo = v.toString()
        }
        freezeInfo.freezeLogPath = freezeLogPathValue
        freezeInfo.rawFile = rawFileValue
        freezeInfo.historyRawFiles = historyRawFilesValue
        if (let Some(v) <- cpuThreadValue) {
            // freezeInfo.cpuThread = JSHashMapEx<String, String>(v)
        }
        if (let Some(v) <- cpuValue) {
            // freezeInfo.cpu = JSHashMapEx<String, String>(v) TODO 互操作已知问题
        }
        if (let Some(v) <- stacktraceValue) {
            freezeInfo.stacktrace = JSArrayEx<String>(v.toString())
        }
        freezeInfo
    }
}

@Interop[ArkTS]
public class InteropFreezeInfo {
    public var timestamp: Option<String> = None
    public var pid: Option<String> = None
    public var exception: Option<String> = None
    public var hilog: Option<String> = None
    public var tid: Option<String> = None
    public var tname: Option<String> = None
    public var extraInfo: Option<String> = None
    public var freezeLogPath: Option<String> = None
    public var cpuThread: Option<JSHashMapEx<String, String>> = None
    public var cpu: Option<JSHashMapEx<String, String>> = None
    public var stacktrace: Option<JSArrayEx<String>> = None
    public var rawFile: Option<String> = None
    public var historyRawFiles: Option<String> = None

    public init() {}
}

private var freezeInited = false
private var extraInfo = ""

public func initFreezeHandler(
    sdkApiVersion: Int64,
    addFreezeWatcher: (callback: (time: String, pid: String, exception: String, hilog: String, external_log: String) -> InteropFreezeInfo) -> Unit,
    onFreeze: (callback: () -> Unit) -> Unit,
    collectFreezeInfo: () -> String,
    persistentDir: Path
): Unit {
    if (freezeInited) {
        return
    }
    cleanHistoryLogFiles()
    extraInfo = collectFreezeInfo()
    let cpuUsageFilePath = persistentDir.join("cpuUsageFreeze.txt")
    let cpuUsageBakFilePath = persistentDir.join("cpuUsageFreeze-bak.txt")
    renameFile(cpuUsageFilePath, cpuUsageBakFilePath)
    let extraInfoFilePath = persistentDir.join("extraInfoFreeze.txt")
    let extraInfoBakFilePath = persistentDir.join("extraInfoFreeze-bak.txt")
    renameFile(extraInfoFilePath, extraInfoBakFilePath)
    initFreezeWatcher(addFreezeWatcher, cpuUsageBakFilePath, extraInfoBakFilePath)
    if (sdkApiVersion >= 18) {
        onFreeze({=> freezeCallback(cpuUsageFilePath, extraInfoFilePath)})
    } else {
        initHilogWatcher(cpuUsageFilePath, extraInfoFilePath)
    }
    freezeInited = true
}

var reportFlag = false

private func freezeCallback(cpuUsageFilePath: Path, extraInfoFilePath: Path): Unit {
    if (!reportFlag) {
        collectFreezeInfo(cpuUsageFilePath, extraInfoFilePath)
        reportFlag = true
    }
}

private func collectFreezeInfo(cpuUsageFilePath: Path, extraInfoFilePath: Path): Unit {
    unsafe {
        let cpuUsageFilePathForC = LibC.mallocCString(cpuUsageFilePath.toString())
        let extraInfoFilePathForC = LibC.mallocCString(extraInfoFilePath.toString())
        if (registerFreezeCallback(cpuUsageFilePathForC, extraInfoFilePathForC, collectExtraFreezeInfo) != 0) {
            metricx_warn("registerFreezeCallback failed.")
        }
        LibC.free(cpuUsageFilePathForC)
        LibC.free(extraInfoFilePathForC)
    }
}

private func initFreezeWatcher(
    addFreezeWatcher: (callback: (time: String, pid: String, exception: String, hilog: String, external_log: String) -> InteropFreezeInfo) -> Unit,
    cpuUsageFilePath: Path,
    extraInfoFilePath: Path
) {
    let cb: (time: String, pid: String, exception: String, hilog: String, external_log: String) -> InteropFreezeInfo = {
        time: String, pid: String, exception: String, hilog: String, external_log: String =>
            let freezeInfo = FreezeInfo()
            try {
                if (exists(cpuUsageFilePath)) {
                    try {
                        if (freezeInfo
                            .cpuThread
                            .isNone()) {
                            let fileContent = String.fromUtf8(File.readFrom(cpuUsageFilePath))
                            freezeInfo.cpuThread = extractDataFromLog(fileContent)
                        }
                    } catch (e: Exception) {
                        metricx_warn(e.toString())
                    }
                    deleteFile(cpuUsageFilePath)
                } else {
                    metricx_warn("No persistent cpuUsage file.")
                }
                if (exists(extraInfoFilePath)) {
                    if (freezeInfo
                        .extraInfo
                        .isNone()) {
                        freezeInfo.extraInfo = readFile(extraInfoFilePath)
                    }
                    deleteFile(extraInfoFilePath)
                } else {
                    metricx_warn("No persistent extraInfo file.")
                }
                freezeInfo.timestamp = time
                freezeInfo.pid = pid
                freezeInfo.exception = exception
                freezeInfo.hilog = hilog
                if (external_log.isEmpty()) {
                    freezeInfo.rawFile = "hm-metricx-cj freeze error: freezeLogPath is empty"
                    freezeInfo.historyRawFiles = collectAndCleanHistoryLogFiles()
                } else if (!exists(external_log)) {
                    freezeInfo.rawFile = "hm-metricx-cj freeze error: freezeLogPath path ${external_log} does not exist"
                }
                freezeInfo.freezeLogPath = external_log
                freezeInfo.rawFile = readFile(Path(external_log), isReturnException: true)
                let res = extractFromFreezeLog(freezeInfo
                    .rawFile
                    .getOrThrow())
                deleteFile(external_log)
                freezeInfo.tid = res[0]
                freezeInfo.tname = res[1]
                freezeInfo.stacktrace = res[2]
                freezeInfo.cpu = res[3]
            } catch (e: Exception) {
                metricx_warn(e.toString())
            }
            freezeInfo.toInteropFreezeInfo()
    }
    addFreezeWatcher(cb)
}

private func extractFromFreezeLog(content: String) {
    let lines = content.split("\n", removeEmpty: true)
    var tid: String = ""
    var tname: String = ""
    var cpuMap = HashMap<String, String>()
    var stacktrace = ArrayList<String>()

    var curLine: Int64 = -1
    for (i in 0..lines.size) {
        if (lines[i].startsWith("TID = ")) {
            tid = lines[i].removePrefix("TID = ")
            curLine = i
            break
        }
    }
    if (curLine == -1) {
        return (tid, tname, stacktrace, cpuMap)
    }

    let tidTag: String = "Tid:" + tid + ", Name:"
    for (i in curLine..lines.size) {
        if (lines[i].startsWith(tidTag)) {
            tname = lines[i].removePrefix(tidTag)
            curLine = i
            break
        }
    }
    curLine = curLine + 1
    for (i in curLine..lines.size) {
        if (!lines[i].startsWith("#")) {
            curLine = i
            break
        }
        stacktrace.add(lines[i])
    }
    let cpuTag = "Details of Processes:"
    for (i in curLine..lines.size) {
        if (lines[i].startsWith(cpuTag)) {
            curLine = i
            break
        }
    }
    curLine = curLine + 2
    for (i in curLine..lines.size) {
        let line = lines[i]
        if (!line.startsWith("  ")) {
            curLine = i
            break
        }
        let dataArray = line.split(" ", removeEmpty: true)
        cpuMap.add(dataArray[0], dataArray[1])
    }
    return (tid, tname, stacktrace, cpuMap)
}

private func extractDataFromLog(content: String): HashMap<String, String> {
    let cpuUsageMap = HashMap<String, String>()
    let cpuUsageStrs = content.split(",", removeEmpty: true)
    let cpuSize = cpuUsageStrs.size / 2
    for (i in 0..cpuSize) {
        cpuUsageMap.add(cpuUsageStrs[2 * i], cpuUsageStrs[2 * i + 1])
    }
    cpuUsageMap
}

foreign func registerFreezeHilogCallback(cpuUsageFilePath: CString, extraInfoFile: CString, cb: CFunc<() -> CString>): Int8

foreign func registerFreezeCallback(cpuUsageFilePath: CString, extraInfoFile: CString, cb: CFunc<() -> CString>): Int8

@C
func collectExtraFreezeInfo(): CString {
    unsafe {
        let crashInfoCStr = LibC.mallocCString(extraInfo)
        crashInfoCStr
    }
}

func initHilogWatcher(cpuUsageFilePath: Path, extraInfoFilePath: Path): Unit {
    unsafe {
        let cpuUsageFilePath = LibC.mallocCString(cpuUsageFilePath.toString())
        let extraInfoFilePath = LibC.mallocCString(extraInfoFilePath.toString())
        if (registerFreezeHilogCallback(cpuUsageFilePath, extraInfoFilePath, collectExtraFreezeInfo) != 0) {
            metricx_warn("registerFreezeHilogCallback failed.")
        }
        LibC.free(cpuUsageFilePath)
        LibC.free(extraInfoFilePath)
    }
}
