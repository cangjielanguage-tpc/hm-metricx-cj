/**
 * Created on 2025/3/28
 */
package ohos_app_cangjie_hm_metricx_cj.crash

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
import encoding.json.JsonObject
import encoding.json.JsonException
import std.os.process.Process
import std.os.setEnv
import ohos.ability.ErrorManager
import ohos.ability.ErrorObserver
import encoding.json.JsonString

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
    private var dumpOnOOMPathValue: ?String = None

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

    mut prop dumpOnOOMPath: ?String {
        get() {
            dumpOnOOMPathValue
        }
        set(value) {
            dumpOnOOMPathValue = value
        }
    }

    func toString(): String {
        let jsonObj = JsonObject()
        if (fdsValue.isSome()) {
            jsonObj.put("fds", map2json(fdsValue.getOrThrow()))
        }
        if (limitsValue.isSome()) {
            jsonObj.put("limits", JsonString(limitsValue.getOrThrow()))
        }
        if (threadsValue.isSome()) {
            jsonObj.put("threads", JsonString(threadsValue.getOrThrow()))
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
    input.iterator().forEach({entry => map.put(entry[0], JsonString(entry[1]))})
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
    collectCrashInfo: () -> JsonValue,
    collectNativeCrashInfo: CFunc<() -> CString>,
    reportCrashInfo: (crashInfo: CrashInfo) -> Unit,
    persistentDir: Path,
    enableDumpOnOOM: Bool
) {
    if (inited) {
        return
    }
    let crashInfo = CrashInfo()
    crashInfo.limits = collectLimits()
    let persistentFilePath = persistentDir.join("crash.json")
    initErrorObserver(crashInfo, collectCrashInfo, persistentFilePath)
    initNativeSignalHandler(persistentFilePath.toString(), crashInfo.limits.getOrThrow(), collectNativeCrashInfo)
    initCrashWatcher(crashInfo, applicationContext, reportCrashInfo, persistentFilePath)
    if (enableDumpOnOOM) {
        initOOMHandler(persistentDir.toString())
    }
    inited = true
}

private func initOOMHandler(persistentDir: String) {
    setEnv("cjHeapDumpOnOOM", "on")
    setEnv("cjHeapDumpLog", persistentDir)
    unsafe {
        let targetFile = LibC.mallocCString(persistentDir + "/cj_OOM_pid" + Process.current.pid.toString() + ".dat")
        if (InitOOMHandler(targetFile) != 0) {
            AppLog.warn("InitOOMHandler failed.")
        }
    }
}

private func initNativeSignalHandler(persistentFilePath: String, limits: String, collectCrashInfo: CFunc<() -> CString>) {
    unsafe {
        let cstr = LibC.mallocCString(persistentFilePath)
        let lmts = LibC.mallocCString(limits)
        if (InitNativeSignalHandler(
            cstr,
            lmts,
            collectCrashInfo,
            {
                persistentFilePath, limits, collectCrashInfo, fds =>
                let crashInfo = CrashInfo()
                crashInfo.limits = limits.toString()
                crashInfo.fds = parseFDs(fds.toString())
                crashInfo.threads = collectThreads()
                let extraInfo = collectCrashInfo()
                try {
                    crashInfo.extraInfo = JsonValue.fromStr(extraInfo.toString())
                } catch (e: JsonException) {
                    AppLog.warn(e.toString())
                } finally {
                    LibC.free(extraInfo)
                }
                writeFile(persistentFilePath.toString(), crashInfo.toString())
            }
        ) != 0) {
            AppLog.warn("InitNativeSignalHandler failed.")
        }
        LibC.free(cstr)
        LibC.free(lmts)
    }
}

private func parseFDs(fds: String) {
    let map: HashMap<String, String> = HashMap()
    let arr = fds.split(",")
    if (arr.size % 2 != 0) {
        return map
    }
    var i = 0
    while (i < arr.size) {
        map.put(arr[i], arr[i + 1])
        i += 2
    }
    map
}

private func initErrorObserver(crashInfo: CrashInfo, collectCrashInfo: () -> JsonValue, persistentFilePath: Path) {
    let errorObserver = ErrorObserver(
        {errMsg: String =>},
        onException: {
            errObject =>
            crashInfo.fds = collectFDInfo()
            crashInfo.threads = collectThreads()
            crashInfo.extraInfo = collectCrashInfo()
            writeFile(persistentFilePath.toString(), crashInfo.toString())
        }
    )
    ErrorManager.on("error", errorObserver)
}

private func writeFile(path: String, data: String) {
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
    try {
        // somtimes stackoverflow
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
    } catch (e: Exception) {
        AppLog.warn("collectFDInfo failed: " + e.toString())
    }
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
                        case Some(value) => value.toString().trimRight(".000000")
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
            if (crashInfo.pid.isSome()) {
                let dumpOnOOMPath = persistentFilePath.join("cj_OOM_pid" + crashInfo.pid.getOrThrow() + ".dat")
                if (File.exists(dumpOnOOMPath)) {
                    crashInfo.dumpOnOOMPath = dumpOnOOMPath.toString()
                }
            }
            reportCrashInfo(crashInfo)
            if (Process.current.pid.toString() == crashInfo.pid.getOrDefault({=> ""})) {
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

foreign func InitNativeSignalHandler(persistentFilePath: CString, limits: CString,
    collectCrashInfo: CFunc<() -> CString>, cb: CFunc<(CString, CString, CFunc<() -> CString>, CString) -> Unit>): Int8

foreign func InitOOMHandler(targetFile: CString): Int8
