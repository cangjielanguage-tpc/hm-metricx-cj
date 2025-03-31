/**
 * Created on 2025/3/28
 */
package ohos_app_cangjie_hm_metricx_cj.crash

import tpc.AbilityKit.kit_common.*
import tpc.AbilityKit.errorManager
import tpc.AbilityKit.errorManager.*
import tpc.PerformanceAnalysisKit.hiAppEvent.*
import tpc.AbilityKit.ApplicationContext
import tpc.AbilityKit.getRunningProcessInformation
import encoding.json.JsonValue
import std.fs.*
import std.collection.*
import ohos.hilog.Hilog
import tpc.CoreFileKit.fs.listFile
import tpc.CoreFileKit.fs.dup
import ohos.base.AppLog
import std.convert.*
import std.os.posix.getpid
import encoding.json.JsonObject
import encoding.json.JsonException

public class CrashInfo {
    private var timestampValue: ?String = None
    private var pidValue: ?String = None
    private var pnameValue: ?String = None
    private var stacktraceValue: ?String = None
    private var hilogValue: ?String = None
    private var tidValue: ?String = None
    private var tnameValue: ?String = None
    private var fdsValue: ?HashMap<String, String> = None
    private var limitsValue: ?String = None
    private var threadsValue: ?String = None
    private var extraInfoValue: ?JsonValue = None
    private var crashLogPathValue: ?String = None

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

    mut prop pname: ?String {
        get() {
            pnameValue
        }
        set(value) {
            pnameValue = value
        }
    }

    mut prop stacktrace: ?String {
        get() {
            stacktraceValue
        }
        set(value) {
            stacktraceValue = value
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

    mut prop limits: ?String {
        get() {
            limitsValue
        }
        set(value) {
            limitsValue = value
        }
    }

    mut prop fds: ?HashMap<String, String> {
        get() {
            fdsValue
        }
        set(value) {
            fdsValue = value
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

    mut prop threads: ?String {
        get() {
            threadsValue
        }
        set(value) {
            threadsValue = value
        }
    }

    mut prop crashLogPath: ?String {
        get() {
            crashLogPathValue
        }
        set(value) {
            crashLogPathValue = value
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

    func toString(): String {
        let jsonObj = JsonObject()
        if (fdsValue.isSome()) {
            jsonObj.put("fds", map2json(fdsValue.getOrThrow()))
        }
        if (limitsValue.isSome()) {
            jsonObj.put("limits", JsonValue.fromStr(limitsValue.getOrThrow()))
        }
        if (threadsValue.isSome()) {
            jsonObj.put("threads", JsonValue.fromStr(threadsValue.getOrThrow()))
        }
        if (extraInfoValue.isSome()) {
            jsonObj.put("extraInfo", extraInfoValue.getOrThrow())
        }
        jsonObj.toString()
    }

    static func fromJson(jsonObject: JsonObject): CrashInfo {
        let crashInfo = CrashInfo()
        if (jsonObject.get("fds").isSome()) {
            let fields: HashMap<String, JsonValue> = jsonObject.get("fds").getOrThrow().asObject().getFields()
            crashInfo.fds = json2map(fields)
        }
        if (jsonObject.get("limits").isSome()) {
            crashInfo.limits = jsonObject.get("limits").getOrThrow().toString()
        }
        if (jsonObject.get("threads").isSome()) {
            crashInfo.threads = jsonObject.get("threads").getOrThrow().toString()
        }
        crashInfo.extraInfo = jsonObject.get("extraInfo")
        crashInfo
    }
}

private func map2json(input: HashMap<String, String>) {
    let map = HashMap<String, JsonValue>()
    input.iterator().forEach({entry => map.put(entry[0], JsonValue.fromStr(entry[1]))})
    JsonObject(map)
}

private func json2map(input: HashMap<String, JsonValue>) {
    let map = HashMap<String, String>()
    input.iterator().forEach({entry => map.put(entry[0], entry[1].toString())})
    map
}

private var inited = false

public func initCrashHandler(
    applicationContext: ApplicationContext,
    collectCrashInfo: (errObject: ?ErrorObject) -> JsonValue,
    reportCrashInfo: (crashInfo: CrashInfo) -> Unit,
    persistentDir: Path
) {
    if (inited) {
        return
    }
    let crashInfo = CrashInfo()
    crashInfo.limits = collectLimits()
    let persistentFilePath = persistentDir.join("crash.json")
    initErrorObserver(crashInfo, collectCrashInfo, persistentFilePath)
    initCrashWatcher(crashInfo, applicationContext, reportCrashInfo, persistentFilePath)
    inited = true
}

private func initErrorObserver(crashInfo: CrashInfo, collectCrashInfo: (errObject: ?ErrorObject) -> JsonValue,
    persistentFilePath: Path) {
    let errorObserver = ErrorObserver(
        {errMsg: String =>},
        {
            errObject: ErrorObject =>
            crashInfo.fds = collectFDInfo()
            crashInfo.threads = collectThreads()
            crashInfo.extraInfo = collectCrashInfo(errObject)
            writeFile(persistentFilePath, crashInfo.toString())
        }
    )
    errorManager.on(ErrorManagerType.ERROR, errorObserver)
}

private func writeFile(path: Path, data: String) {
    try {
        File.writeTo(path, data.toArray())
    } catch (e: FSException) {
        AppLog.warn(e.toString())
    } catch (e: IllegalArgumentException) {
        AppLog.warn(e.toString())
    }
}

private func collectThreads() {
    let path = Path("/proc/self/tids")
    String.fromUtf8(File.readFrom(path))
}

private func collectLimits() {
    let path = Path("/proc/self/limits")
    String.fromUtf8(File.readFrom(path))
}

private func collectFDInfo() {
    let fds: HashMap<String, String> = HashMap()
    let path = Path("/proc/self/fd")
    if (!Directory.exists(path)) {
        return fds
    }
    let files = listFile("/proc/self/fd")
    files
        .iterator()
        .forEach(
            {
                file =>
                let fdPath = path.join(file)
                if (File.exists(fdPath)) {
                    let realPath = dup(Int32.parse(file)).path
                    fds.put(fdPath.toString(), realPath)
                } else {
                    fds.put(fdPath.toString(), "unknown")
                }
            }
        )
    fds
}

private func initCrashWatcher(crashinfo: CrashInfo, applicationContext: ApplicationContext,
    reportCrashInfo: (crashInfo: CrashInfo) -> Unit, persistentFilePath: Path) {
    let watcher = Watcher(
        "crashWatcher",
        appEventFilters: [AppEventFilter(OS, names: [APP_CRASH], eventTypes: [FAULT])],
        onReceive: {
            domain: String, appEventGroups: Array<AppEventGroup> =>
            if (domain != OS) {
                return
            }
            var crashInfo = crashinfo
            if (File.exists(persistentFilePath)) {
                if (crashInfo.fds.isNone()) {
                    try {
                        let jsonObj = JsonValue.fromStr(String.fromUtf8(File.readFrom(persistentFilePath))).asObject()
                        crashInfo = CrashInfo.fromJson(jsonObj)
                    } catch (e: JsonException) {
                        AppLog.warn(e.toString())
                    }
                }
                File.delete(persistentFilePath)
            }
            for (eventGroup in appEventGroups) {
                if (eventGroup.name != APP_CRASH) {
                    continue
                }
                for (eventInfo in eventGroup.appEventInfos) {
                    crashInfo.timestamp = match (eventInfo.params.get("time")) {
                        case Some(value) => value.toString()
                        case _ => None
                    }
                    crashInfo.pid = match (eventInfo.params.get("pid")) {
                        case Some(value) => value.toString()
                        case _ => None
                    }
                    crashInfo.stacktrace = match (eventInfo.params.get("exception")) {
                        case Some(value) => value.toString()
                        case _ => None
                    }
                    crashInfo.hilog = match (eventInfo.params.get("hilog")) {
                        case Some(value) => value.toString()
                        case _ => None
                    }

                    if (eventInfo.params.get("external_logs").isNone()) {
                        continue
                    }

                    let crashLogPath: String = eventInfo.params.get("external_logs").getOrThrow().toString()
                    if (!File.exists(crashLogPath)) {
                        continue
                    }

                    crashInfo.crashLogPath = crashLogPath
                    let content = String.fromUtf8(File.readFrom(crashLogPath))
                    let res = extractFromCrashLog(content, crashInfo.pid, crashInfo.threads)
                    crashInfo.pname = res[0]
                    crashInfo.tid = res[1]
                    crashInfo.tname = res[2]
                }
            }
            reportCrashInfo(crashInfo)
            if (getpid().toString() == crashInfo.pid.getOrDefault({=> ""})) {
                applicationContext.killAllProcesses({err, data =>})
            }
        }
    )
    addWatcher(watcher)
}

private func extractFromCrashLog(content: String, pid: ?String, threads: ?String) {
    let lines = content.split("\n", removeEmpty: true)
    var moduleName = ""
    var tid = ""
    var tname = ""
    var pname = ""
    var cnt = 0
    for (line in lines) {
        cnt++
        if (cnt > 40) {
            break
        }
        if (line.startsWith("Module name:")) {
            moduleName = line.trimLeft("Module name:")
        } else if (line.startsWith("Process name:")) {
            pname = line.trimLeft("Process name:")
        } else if (line.startsWith("Tid:") && line.contains(", Name:")) {
            let arr = line.split(", ")
            if (arr.size != 2) {
                continue
            }
            tid = arr[0].trimLeft("Tid:")
            tname = arr[1].trimLeft("Name:")
            break
        }
    }
    if (pname.isEmpty()) {
        pname = moduleName
    }
    if (tid.isEmpty() && pid.isSome()) {
        tid = pid.getOrThrow()
        if (threads.isSome()) {
            let arr = threads.getOrThrow().split("\n")
            for (thread in arr) {
                let prefix = tid + ":"
                if (thread.startsWith(prefix)) {
                    tname = thread.trimLeft(prefix)
                    break
                }
            }
        }
    }
    return (pname, tid, tname)
}
