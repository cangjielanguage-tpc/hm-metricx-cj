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

    mut prop timestamp: ?String {
        get() {
            timestampValue
        }
        set(value) {
            timestampValue = value
        }
    }

    mut prop pid: ?String {
        get() {
            pidValue
        }
        set(value) {
            pidValue = value
        }
    }

    mut prop exception: ?String {
        get() {
            exceptionValue
        }
        set(value) {
            exceptionValue = value
        }
    }

    mut prop hilog: ?String {
        get() {
            hilogValue
        }
        set(value) {
            hilogValue = value
        }
    }

    mut prop tid: ?String {
        get() {
            tidValue
        }
        set(value) {
            tidValue = value
        }
    }

    mut prop tname: ?String {
        get() {
            tnameValue
        }
        set(value) {
            tnameValue = value
        }
    }
        mut prop extraInfo: ?JsonValue {
        get() {
            extraInfoValue
        }
        set(value) {
            extraInfoValue = value
        }
    }

    mut prop freezeLogPath: ?String {
        get() {
            freezeLogPathValue
        }
        set(value) {
            freezeLogPathValue = value
        }
    }

    mut prop cpuThread: ?HashMap<String, String> {
        get() {
            cpuThreadValue
        }
        set(value) {
            cpuThreadValue = value
        }
    }

    mut prop cpu: ?HashMap<String, String> {
        get() {
            cpuValue
        }
        set(value) {
            cpuValue = value
        }
    }

    mut prop stacktrace: ?ArrayList<String> {
        get() {
            stacktraceValue
        }
        set(value) {
            stacktraceValue = value
        }
    }

    func toString(): String {
        let jsonObj = JsonObject()
        if (cpuThreadValue.isSome()) {
            jsonObj.put("cpuThread", map2json(cpuThreadValue.getOrThrow()))
        }
        jsonObj.toString()
    }

    static func fromJson(jsonObject: JsonObject): FreezeInfo {
        let freezeInfo = FreezeInfo()

        if (jsonObject.get("cpuThread").isSome()) {
            let fields: HashMap<String, JsonValue> = jsonObject.get("cpuThread").getOrThrow().asObject().getFields()
            freezeInfo.cpuThread = json2map(fields)
        }

        freezeInfo
    }
}

private var freezeInited = false
private var jsonPath: Path = Path("")

public func initFreezeHandler(
    applicationContext: ApplicationContext,
    collectFreezeInfo: () -> JsonValue,
    reportFreezeInfo: (freezeInfo: FreezeInfo) -> Unit,
    persistentDir: Path
): Unit {
    if (freezeInited) {
        return
    }
    let freezeInfo = FreezeInfo()
    let persistentFilePath = persistentDir.join("freeze.json")
    jsonPath = persistentFilePath
    let persistentBackFilePath = persistentDir.join("freeze-back.json")
    try {
        if (exists(persistentFilePath)) {
            copy(persistentFilePath, to: persistentBackFilePath,overwrite: true)
        }
    } catch (e: Exception) {
        AppLog.warn(e.toString())
    }
    initFreezeWatcher(freezeInfo, applicationContext, collectFreezeInfo, reportFreezeInfo, persistentBackFilePath)
    initHilogWatcher(persistentFilePath)
    freezeInited = true
}

private func initFreezeWatcher(
    freezeinfo: FreezeInfo,
    applicationContext: ApplicationContext,
    collectFreezeInfo: () -> JsonValue,
    reportFreezeInfo: (freeezeInfo: FreezeInfo) -> Unit,
    persistentFilePath: Path
) {
    let watcher = Watcher(
        "freezeWatcher",
        appEventFilters: [AppEventFilter(OS, eventTypes: [FAULT], names: [APP_FREEZE])],
        onReceive: {
            domain: String, appEventGroups: Array<AppEventGroup> =>
            if (domain != OS) {
                return
            }
            let freezeInfo = freezeinfo
            freezeInfo.extraInfo = collectFreezeInfo()
            try {
                if (exists(persistentFilePath)) {
                    if (freezeInfo.cpuThread.isNone()) {
                        let fileContent = String.fromUtf8(File.readFrom(persistentFilePath))
                        let cpuUsageMap = extractDataFromLog(fileContent)
                        freezeInfo.cpuThread = cpuUsageMap
                    }
                    remove(persistentFilePath)
                }
            } catch (e: Exception) {
                AppLog.warn(e.toString())
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
                        case Some(value) => value.toString()
                        case _ => None
                    }

                    if (eventInfo.params.get("external_log").isNone()) {
                        continue
                    }

                    var freezeLogPath: String = eventInfo.params.get("external_log").getOrThrow().toString()
                    freezeLogPath = freezeLogPath.removePrefix("[")
                    freezeLogPath = freezeLogPath.removeSuffix("]")
                    if (!exists(freezeLogPath)) {
                        continue
                    }
                    freezeInfo.freezeLogPath = freezeLogPath

                    try {
                        let content = String.fromUtf8(File.readFrom(freezeLogPath))
                        let res = extractFromFreezeLog(content)
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
        (tid, tname, stacktrace, cpuMap)
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
    let lines = content.split("\n", removeEmpty: true)
    var cpuUsageMap = HashMap<String, String>()
    var curLine: Int64 = -1
    for (i in 0..lines.size) {
        if (lines[i].startsWith("ThreadCpuUsage")) {
            curLine = i
            break
        }
    }
    if (curLine == -1) {
        cpuUsageMap
    }

    curLine = curLine + 1
    let cpuUsageStr = lines[curLine]
    let cpuUsageStrs = cpuUsageStr.split(",", removeEmpty: true)
    let cpuSize = cpuUsageStrs.size / 2
    for (i in 0..cpuSize) {
        cpuUsageMap.add(cpuUsageStrs[2 * i], cpuUsageStrs[2 * i + 1])
    }
    cpuUsageMap
}

foreign func registerHilogCallback(logPath: CString, cb: CFunc<() -> Unit>): Unit

@C
func CallbackHilogHandler(): Unit {
    let cpuThreadUsage = getAppThreadCpuUsage()

    let cpuThreadJson = HashMap<String, JsonValue>()
    cpuThreadUsage
        .iterator()
        .forEach({entry => cpuThreadJson.add(entry.threadId.toString(), JsonValue.fromStr(entry.cpuUsage.toString()))})
    let cpuThreadObject = JsonObject(cpuThreadJson)

    let obJect = JsonObject()
    obJect.put("cpuThread", cpuThreadObject)

    let file = File(jsonPath, OpenMode.Write)
    file.write(obJect.toJsonString().toArray())
    file.close()
}

public func initHilogWatcher(persistentFilePath: Path): Unit {
    let logStr = persistentFilePath.toString()
    unsafe {
        let cPath = LibC.mallocCString(logStr)
        registerHilogCallback(cPath, CallbackHilogHandler)
        LibC.free(cPath)
    }
}
