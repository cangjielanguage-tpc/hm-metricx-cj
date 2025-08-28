/**
 * Created on 2025/3/28
 */
package ohos_app_cangjie_hm_metricx_cj.freeze

import ohos_app_cangjie_hm_metricx_cj.*
import tpc.AbilityKit.kit_common.*
import tpc.AbilityKit.errorManager.*
import tpc.PerformanceAnalysisKit.hiAppEvent.*
import tpc.PerformanceAnalysisKit.hidebug.*
import tpc.AbilityKit.ApplicationContext
import tpc.AbilityKit.getRunningProcessInformation
import stdx.encoding.json.*
import std.fs.*
import std.collection.*
import ohos.hilog.Hilog
import tpc.CoreFileKit.fs.listFile
import tpc.CoreFileKit.fs.dup
import ohos.base.AppLog
import std.convert.*
import std.posix.getpid
import ohos.base.nativeLog
import ohos.base.ArrayLike
import std.sort.stableSort

public class FreezeInfo {
    private var timestampValue: ?String = None
    private var pidValue: ?String = None
    private var exceptionValue: ?String = None
    private var hilogValue: ?String = None
    private var tidValue: ?String = None
    private var tnameValue: ?String = None
    private var extraInfoValue: ?JsonValue = None
    private var freezeLogPathValue: ?String = None
    private var cpuThreadValue: ?HashMap<String, String> = None
    private var cpuValue: ?HashMap<String, String> = None
    private var stacktraceValue: ?ArrayList<String> = None
    private var rawFileValue: ?String = None

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

    public mut prop extraInfo: ?JsonValue {
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

    public func toString(): String {
        let jsonObj = JsonObject()
        if (timestampValue.isSome()) {
            jsonObj.put("timestamp", JsonString(timestampValue.getOrThrow()))
        }
        if (pidValue.isSome()) {
            jsonObj.put("pid", JsonString(pidValue.getOrThrow()))
        }
        if (exceptionValue.isSome()) {
            jsonObj.put("exception", JsonString(exceptionValue.getOrThrow()))
        }
        if (hilogValue.isSome()) {
            jsonObj.put("hilog", JsonString(hilogValue.getOrThrow()))
        }
        if (tidValue.isSome()) {
            jsonObj.put("tid", JsonString(tidValue.getOrThrow()))
        }
        if (tnameValue.isSome()) {
            jsonObj.put("tname", JsonString(tnameValue.getOrThrow()))
        }
        if (extraInfoValue.isSome()) {
            jsonObj.put("extraInfo", extraInfoValue.getOrThrow())
        }
        if (freezeLogPathValue.isSome()) {
            jsonObj.put("freezeLogPath", JsonString(freezeLogPathValue.getOrThrow()))
        }
        if (cpuThreadValue.isSome()) {
            jsonObj.put("cpuThread", map2json(cpuThreadValue.getOrThrow()))
        }
        if (cpuValue.isSome()) {
            jsonObj.put("cpu", map2json(cpuValue.getOrThrow()))
        }
        if (rawFileValue.isSome()) {
            jsonObj.put("rawFile", JsonString(rawFileValue.getOrThrow()))
        }
        if (stacktraceValue.isSome()) {
            let arrJson = ArrayList<JsonValue>()
            stacktraceValue
                .getOrThrow()
                .iterator()
                .forEach({
                    entry =>
                    arrJson.add(JsonValue.fromStr(JsonString(entry).toJsonString()))
                })
            jsonObj.put("stacktrace", JsonArray(arrJson))
        }
        jsonObj.toString()
    }
}

private var freezeInited = false
private var iCollectFreezeInfo: () -> JsonValue = { => JsonValue.fromStr("{}") }

public func initFreezeHandler(
    applicationContext: ApplicationContext,
    collectFreezeInfo: () -> JsonValue,
    reportFreezeInfo: (freezeInfo: FreezeInfo) -> Unit,
    persistentDir: Path
): Unit {
    if (freezeInited) {
        return
    }
    iCollectFreezeInfo = collectFreezeInfo
    let cpuUsageFilePath = persistentDir.join("cpuUsageFreeze.txt")
    let cpuUsageBakFilePath = persistentDir.join("cpuUsageFreeze-bak.txt")
    renameFile(cpuUsageFilePath, cpuUsageBakFilePath)
    let extraInfoFilePath = persistentDir.join("extraInfoFreeze.json")
    let extraInfoBakFilePath = persistentDir.join("extraInfoFreeze-bak.json")
    renameFile(extraInfoFilePath, extraInfoBakFilePath)
    initFreezeWatcher(applicationContext, reportFreezeInfo, cpuUsageBakFilePath, extraInfoBakFilePath)
    initHilogWatcher(cpuUsageFilePath, extraInfoFilePath)
    freezeInited = true
}

private func initFreezeWatcher(
    applicationContext: ApplicationContext,
    reportFreezeInfo: (freeezeInfo: FreezeInfo) -> Unit,
    cpuUsageFilePath: Path,
    extraInfoFilePath: Path
) {
    let watcher = Watcher(
        "freezeWatcher",
        appEventFilters: [AppEventFilter(OS, eventTypes: [FAULT], names: [APP_FREEZE])],
        onReceive: {
            domain: String, appEventGroups: Array<AppEventGroup> =>
            if (domain != OS) {
                return
            }
            let freezeInfo = FreezeInfo()
            if (exists(cpuUsageFilePath)) {
                try {
                    if (freezeInfo.cpuThread.isNone()) {
                        let fileContent = String.fromUtf8(File.readFrom(cpuUsageFilePath))
                        freezeInfo.cpuThread = extractDataFromLog(fileContent)
                    }
                } catch (e: Exception) {
                    AppLog.warn(e.toString())
                }
                deleteFile(cpuUsageFilePath)
            }
            else {
                AppLog.warn("No persistent cpuUsage file.")
            }
            if (exists(extraInfoFilePath)) {
                try {
                    if (freezeInfo.extraInfo.isNone()) {
                        let jsonObj = JsonValue.fromStr(String.fromUtf8(File.readFrom(extraInfoFilePath))).asObject()
                        freezeInfo.extraInfo = jsonObj.get("extraInfo")
                    }
                } catch (e: Exception) {
                    AppLog.warn(e.toString())
                }
                deleteFile(extraInfoFilePath)
            }
            else {
                AppLog.warn("No persistent extraInfo file.")
            }
            for (eventGroup in appEventGroups) {
                if (eventGroup.name != APP_FREEZE) {
                    continue
                }
                for (eventInfo in eventGroup.appEventInfos) {
                    freezeInfo.timestamp = match (eventInfo.params.get("time")) {
                        case Some(value) => value.toString()
                        case _ => None
                    }
                    freezeInfo.pid = match (eventInfo.params.get("pid")) {
                        case Some(value) => value.toString()
                        case _ => None
                    }
                    freezeInfo.exception = match (eventInfo.params.get("exception")) {
                        case Some(value) => value.toString()
                        case _ => None
                    }
                    freezeInfo.hilog = match (eventInfo.params.get("hilog")) {
                        case Some(value) => hilogWordWrap(value.toString())
                        case _ => None
                    }

                    if (eventInfo.params.get("external_log").isNone()) {
                        freezeInfo.rawFile = "hm-metricx-cj freeze error: external_log is none"
                        continue
                    }

                    var freezeLogPath: String = eventInfo.params.get("external_log")
                        .getOrThrow().toString().removePrefix("[").removeSuffix("]")
                    if (freezeLogPath.isEmpty() ) {
                        freezeInfo.rawFile = "hm-metricx-cj freeze error: freezeLogPath is empty"
                        continue
                    }
                    if (!exists(freezeLogPath)) {
                        freezeInfo.rawFile = "hm-metricx-cj freeze error: freezeLogPath path ${freezeLogPath} does not exist"
                        continue
                    }
                    freezeInfo.freezeLogPath = freezeLogPath
                    try {
                        freezeInfo.rawFile = readFile(Path(freezeLogPath), isReturnException: true)
                        let res = extractFromFreezeLog(freezeInfo.rawFile.getOrThrow())
                        freezeInfo.tid = res[0]
                        freezeInfo.tname = res[1]
                        freezeInfo.stacktrace = res[2]
                        freezeInfo.cpu = res[3]
                    } catch (e: Exception) {
                        AppLog.warn(e.toString())
                    }
                }
            }
            reportFreezeInfo(freezeInfo)
            if (let Some(v) <- freezeInfo.freezeLogPath) {
                    deleteFile(v)
            }
        }
    )
    addWatcher(watcher)
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

@C
func collectExtraFreezeInfo(): CString {
    let jsonObj = JsonObject()
    try {
        jsonObj.put("extraInfo", iCollectFreezeInfo())
    } catch (e: Exception) {
        AppLog.error(e.toString())
    }
    unsafe {
        let crashInfoCStr = LibC.mallocCString(jsonObj.toString())
        crashInfoCStr
    }
}

public func initHilogWatcher(cpuUsageFilePath: Path, extraInfoFilePath: Path): Unit {
    unsafe {
        let cpuUsageFilePath = LibC.mallocCString(cpuUsageFilePath.toString())
        let extraInfoFilePath = LibC.mallocCString(extraInfoFilePath.toString())
        if (registerFreezeHilogCallback(cpuUsageFilePath, extraInfoFilePath, collectExtraFreezeInfo) != 0) {
            AppLog.warn("registerFreezeHilogCallback failed.")
        }
        LibC.free(cpuUsageFilePath)
        LibC.free(extraInfoFilePath)
    }
}
