/**
 * Created on 2025/3/28
 */
package ohos_app_cangjie_hm_metricx_cj.crash

import ohos_app_cangjie_hm_metricx_cj.*
import tpc.PerformanceAnalysisKit.hiAppEvent.*
import tpc.AbilityKit.ApplicationContext
import std.fs.*
import std.collection.*
import ohos.hilog.Hilog
import ohos.base.AppLog
import std.convert.*
import std.process.*
import std.env.*
import ohos.ability.ErrorManager
import ohos.ability.ErrorObserver
import stdx.compress.zlib.*
import stdx.encoding.json.*
import std.time.*
import std.sync.*
import ohos_app_cangjie_hm_metricx_cj.deleteFile

public class CrashInfo {
    private var languageValue: ?String = None
    private var meminfoValue: ?String = None
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
    private var appVersionValue: ?String = None
    private var rawFileValue: ?String = None
    private var systemLogValue: ?String = None
    private var lastNHilogValue: ?String = None

    public mut prop language: ?String {
        get() {
            languageValue
        }
        set(value) {
            languageValue = value
        }
    }

    public mut prop meminfo: ?String {
        get() {
            meminfoValue
        }
        set(value) {
            meminfoValue = value
        }
    }

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

    public mut prop pname: ?String {
        get() {
            pnameValue
        }
        set(value) {
            pnameValue = value
        }
    }

    public mut prop stacktrace: ?String {
        get() {
            stacktraceValue
        }
        set(value) {
            stacktraceValue = value
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

    public mut prop limits: ?String {
        get() {
            limitsValue
        }
        set(value) {
            limitsValue = value
        }
    }

    public mut prop fds: ?HashMap<String, String> {
        get() {
            fdsValue
        }
        set(value) {
            fdsValue = value
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

    public mut prop threads: ?String {
        get() {
            threadsValue
        }
        set(value) {
            threadsValue = value
        }
    }

    public mut prop crashLogPath: ?String {
        get() {
            crashLogPathValue
        }
        set(value) {
            crashLogPathValue = value
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

    public mut prop dumpOnOOMPath: ?String {
        get() {
            dumpOnOOMPathValue
        }
        set(value) {
            dumpOnOOMPathValue = value
        }
    }

    public mut prop appVersion: ?String {
        get() {
            appVersionValue
        }
        set(value) {
            appVersionValue = value
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

    public mut prop systemLog: ?String {
        get() {
            systemLogValue
        }
        set(value) {
            systemLogValue = value
        }
    }

    public mut prop lastNHilog: ?String {
        get() {
            lastNHilogValue
        }
        set(value) {
            lastNHilogValue = value
        }
    }

    public func toString(): String {
        let jsonObj = JsonObject()
        if (let Some(v) <- languageValue) {
            jsonObj.put("language", JsonString(v))
        }
        if (let Some(v) <- meminfoValue) {
            jsonObj.put("meminfo", JsonString(v))
        }
        if (let Some(v) <- timestampValue) {
            jsonObj.put("timestamp", JsonString(v))
        }
        if (let Some(v) <- pidValue) {
            jsonObj.put("pid", JsonString(v))
        }
        if (let Some(v) <- pnameValue) {
            jsonObj.put("pname", JsonString(v))
        }
        if (let Some(v) <- stacktraceValue) {
            jsonObj.put("stacktrace", JsonString(v))
        }
        if (let Some(v) <- hilogValue) {
            jsonObj.put("hilog", JsonString(v))
        }
        if (let Some(v) <- tidValue) {
            jsonObj.put("tid", JsonString(v))
        }
        if (let Some(v) <- tnameValue) {
            jsonObj.put("tname", JsonString(v))
        }
        if (let Some(v) <- fdsValue) {
            jsonObj.put("fds", map2json(v))
        }
        if (let Some(v) <- limitsValue) {
            jsonObj.put("limits", JsonString(v))
        }
        if (let Some(v) <- threadsValue) {
            jsonObj.put("threads", JsonString(v))
        }
        if (let Some(v) <- extraInfoValue) {
            jsonObj.put("extraInfo", v)
        }
        if (let Some(v) <- crashLogPathValue) {
            jsonObj.put("crashLogPath", JsonString(v))
        }
        if (let Some(v) <- dumpOnOOMPathValue) {
            jsonObj.put("dumpOnOOMPath", JsonString(v))
        }
        if (let Some(v) <- appVersionValue) {
            jsonObj.put("appVersion", JsonString(v))
        }
        if (let Some(v) <- rawFileValue) {
            jsonObj.put("rawFile", JsonString(v))
        }
        if (let Some(v) <- systemLogValue) {
            jsonObj.put("systemLog", JsonString(v))
        }
        if (let Some(v) <- lastNHilogValue) {
            jsonObj.put("lastNHilog", JsonString(v))
        }
        jsonObj.toString()
    }

    public static func fromJson(jsonObject: JsonObject): CrashInfo {
        let crashInfo = CrashInfo()
        if (let Some(v) <- jsonObject.get("language")) {
            crashInfo.language = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("meminfo")) {
            crashInfo.meminfo = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("timestamp")) {
            crashInfo.timestamp = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("pid")) {
            crashInfo.pid = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("pname")) {
            crashInfo.pname = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("stacktrace")) {
            crashInfo.stacktrace = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("hilog")) {
            crashInfo.hilog = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("tid")) {
            crashInfo.tid = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("tname")) {
            crashInfo.tname = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("fds")) {
            let fields: HashMap<String, JsonValue> = v.asObject().getFields()
            crashInfo.fds = json2map(fields)
        }
        if (let Some(v) <- jsonObject.get("limits")) {
            crashInfo.limits = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("threads")) {
            crashInfo.threads = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("extraInfo")) {
            crashInfo.extraInfo = v
        }
        if (let Some(v) <- jsonObject.get("crashLogPath")) {
            crashInfo.crashLogPath = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("dumpOnOOMPath")) {
            crashInfo.dumpOnOOMPath = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("appVersion")) {
            crashInfo.appVersion = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("rawFile")) {
            crashInfo.rawFile = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("systemLog")) {
            crashInfo.systemLog = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("lastNHilog")) {
            crashInfo.lastNHilog = JsonValueToString(v)
        }
        crashInfo
    }

    func reset() {
        this.meminfoValue = None
        this.languageValue = None
        this.timestampValue = None
        this.pidValue = None
        this.pnameValue = None
        this.stacktraceValue = None
        this.hilogValue = None
        this.tidValue = None
        this.tnameValue = None
        this.fdsValue = None
        this.limitsValue = None
        this.threadsValue = None
        this.extraInfoValue = None
        this.crashLogPathValue = None
        this.dumpOnOOMPathValue = None
        this.appVersionValue = None
        this.rawFileValue = None
    }
}

public enum OOMHandlerMode {
    | Async | Sync
}

private var inited = false
private let TIMEOUT = Duration.second
private var reported = false

public func initCrashHandler(
    applicationContext: ApplicationContext,
    collectCrashInfo: () -> JsonValue,
    collectNativeCrashInfo: CFunc<() -> CString>,
    reportCrashInfo: (crashInfo: CrashInfo) -> Unit,
    persistentDir: Path,
    enableDumpOnOOM: Option<OOMHandlerMode>,
    lastNHilogNumber:Int64 ) {
    if (inited) {
        return
    }
    var hilogNumber = max(lastNHilogNumber, 0)
    let lastCrashFilePath = persistentDir.join("lastCrash.json")
    reportLastCrash(lastCrashFilePath, reportCrashInfo)
    let crashInfo = CrashInfo()
    crashInfo.limits = collectLimits()
    let persistentFilePath = persistentDir.join("crash.json")
    let persistentSystemLogPath = persistentDir.join("crashSystemLog.txt")
    let persistentLastNHilogPath = persistentDir.join("crashLastNHilog.txt")
    initErrorObserver(
        crashInfo, applicationContext, collectCrashInfo, persistentFilePath, persistentSystemLogPath,
        persistentLastNHilogPath, enableDumpOnOOM, persistentDir)
    initNativeSignalHandler(persistentFilePath.toString(), applicationContext, crashInfo.limits.getOrThrow(),
        collectNativeCrashInfo, persistentSystemLogPath.toString(),
        persistentLastNHilogPath.toString(), hilogNumber)
    initCrashWatcher(applicationContext, reportCrashInfo,
        persistentFilePath, persistentSystemLogPath, persistentLastNHilogPath,
        persistentDir, lastCrashFilePath)
    initHilogWatcher()
    if (let Some(handlerMode) <- enableDumpOnOOM) {
        match (handlerMode) {
            case OOMHandlerMode.Sync =>
                initOOMHandler(persistentDir.toString())
            case OOMHandlerMode.Async =>
                spawn { =>
                    initOOMHandler(persistentDir.toString())
                }
        }
    }
    inited = true
}

private func reportLastCrash(lastCrashFilePath: Path, reportCrashInfo: (crashInfo: CrashInfo) -> Unit) {
    if (exists(lastCrashFilePath)) {
        try {
            let jsonObj = JsonValue.fromStr(readFile(lastCrashFilePath)).asObject()
            let crashInfo = CrashInfo.fromJson(jsonObj)
            reportCrashInfo(crashInfo)
            reported = true
            if (let Some(v) <- crashInfo.crashLogPath) {
                deleteFile(v)
            }
        } catch (e: JsonException) {
            AppLog.warn(e.toString())
        }
        deleteFile(lastCrashFilePath)
    }
}

private func initOOMHandler(persistentDir: String) {
    setVariable("cjHeapDumpOnOOM", "on")
    setVariable("cjHeapDumpLog", persistentDir)
    unsafe {
        let targetFile = LibC.mallocCString(persistentDir + "/cj_OOM_pid" + Process.current.pid.toString() + ".dat")
        let zlibFile = LibC.mallocCString(persistentDir + "/cj_OOM_pid" + Process.current.pid.toString() + ".zlib")
        if (InitOOMHandler(targetFile, zlibFile,
            {
                src, dest => if (compressFile(src.toString(), dest.toString())) {
                    deleteFile(src.toString())
                } else {
                    AppLog.warn("compressFile failed.")
                }
            }) != 0) {
            AppLog.warn("InitOOMHandler failed.")
        }
        LibC.free(targetFile)
        LibC.free(zlibFile)
    }
}

private func initNativeSignalHandler(persistentFilePath: String, applicationContext: ApplicationContext, limits: String,
    collectCrashInfo: CFunc<() -> CString>, persistentSystemLogPath: String,
    persistentLastNHilogPath: String, lastNHilogNumber: Int64) {
    unsafe {
        let cstr = LibC.mallocCString(persistentFilePath)
        let lmts = LibC.mallocCString(limits)
        let cSystemLogPath = LibC.mallocCString(persistentSystemLogPath)
        let cLastNHilogPath = LibC.mallocCString(persistentLastNHilogPath)
        if (InitNativeSignalHandler(
            cstr,
            lmts,
            collectCrashInfo,
            cSystemLogPath,
            cLastNHilogPath,
            lastNHilogNumber,
            {
                persistentFilePath, limits, collectCrashInfo, fds, threads, meminfo, bundleName =>
                let crashInfo = CrashInfo()
                crashInfo.limits = limits.toString()
                crashInfo.fds = parseFDs(fds.toString())
                // sometimes invoking collectThreads will crash, so read tids at native side
                crashInfo.threads = threads.toString()
                // sometimes invoking collectMemInfo will crash, so read meminfo at native side
                crashInfo.meminfo = meminfo.toString()
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
        LibC.free(cSystemLogPath)
        LibC.free(cLastNHilogPath)
    }
}

private func parseFDs(fds: String) {
    let map: HashMap<String, String> = HashMap()
    let arr = fds.split(",", removeEmpty: true)
    if (arr.size % 2 != 0) {
        AppLog.warn("parseFDs failed.")
        return map
    }
    var i = 0
    while (i < arr.size) {
        map.add(arr[i], arr[i + 1])
        i += 2
    }
    map
}

private func initErrorObserver(crashInfo: CrashInfo, applicationContext: ApplicationContext,
    collectCrashInfo: () -> JsonValue, persistentFilePath: Path, persistentSystemLogPath: Path,
    persistentLastNHilogPath: Path, enableDumpOnOOM: Option<OOMHandlerMode>, persistentDir: Path) {
    let errorObserver = ErrorObserver(
        {errMsg: String =>},
        onException: {
            errObject =>
            crashInfo.meminfo = collectMemInfo()
            crashInfo.fds = collectFDInfo()
            crashInfo.threads = collectThreads()
            crashInfo.extraInfo = collectCrashInfo()
            writeFile(persistentFilePath, crashInfo.toString())
            writeSystemLog2File(persistentSystemLogPath.toString())
            writeLastNHilog2File(persistentLastNHilogPath.toString())
            if (enableDumpOnOOM.isSome()) {
                let rawOomFile = persistentDir.join("cj_OOM_pid" + Process.current.pid.toString() + ".dat")
                let oomFile = persistentDir.join("cj_OOM_pid" + Process.current.pid.toString() + ".zlib")
                let startTime = DateTime.now()
                while(!exists(oomFile) && DateTime.now() - startTime < Duration.second) {}
                while(exists(rawOomFile) && DateTime.now() - startTime < Duration.second) {}
            }
            exit(applicationContext)
        }
    )
    let index = ErrorManager.on("error", errorObserver)
    if (index != 0) {
        // TODO Once ErrorManager supports "freeze" handler, this condition may need to be tweaked.
        AppLog.warn(
            "There are other error observers registered before crash obsverver, which may interfere with its behavior.")
    }
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

private func writeFile(path: Path, data: String) {
    try {
        File.writeTo(path, data.toArray())
    } catch (e: FSException) {
        AppLog.warn(e.toString())
    } catch (e: IllegalArgumentException) {
        AppLog.warn(e.toString())
    }
}

private func readFile(path: Path, isReturnException!: Bool = false) {
    if (!exists(path)) {
        if (isReturnException) {
        	return "hm-metricx-cj error: read file path does not exist"
        } else {
            return ""
        }
    }
    try {
        return String.fromUtf8(File.readFrom(path))
    } catch (e: Exception) {
        AppLog.warn("reading ${path} failed: " + e.toString())
        if (isReturnException) {
        	return "hm-metricx-cj error: reading ${path} failed: + ${e.toString()}"
        }
    }
    ""
}

private func collectThreads() {
    readFile(Path("/proc/self/tids"))
}

private func collectLimits() {
    readFile(Path("/proc/self/limits"))
}

private func collectFDInfo() {
    let fds: HashMap<String, String> = HashMap()
    let path = Path("/proc/self/fd")
    if (!exists(path)) {
        return fds
    }
    try {
        Directory.walk(
            path,
            {
                file =>
                let fdPath = file.path
                if (exists(fdPath)) {
                    let realPath = SymbolicLink.readFrom(fdPath)
                    fds.add(fdPath.toString(), realPath.toString())
                } else {
                    fds.add(fdPath.toString(), "unknown")
                }
                true
            }
        )
    } catch (e: Exception) {
        AppLog.warn("collectFDInfo failed: " + e.toString())
    }
    fds
}

private func collectMemInfo() {
    let rollupPath = Path("/proc/self/smaps_rollup")
    let smaps_rollup = readFile(rollupPath)
    var vss = ""
    let statmPath = Path("/proc/self/statm")
    try {
        let statm = readFile(statmPath)
        vss = "Vss:\t\t\t\t" + (Int32.tryParse(statm.split(" ", removeEmpty: true)[0]).getOrThrow() * 4).toString() + " KB"
    } catch (e:Exception) {
        AppLog.warn("statm failed: " + e.toString())
    }
    smaps_rollup + "\n" + vss
}

private func initCrashWatcher(applicationContext: ApplicationContext, reportCrashInfo: (crashInfo: CrashInfo) -> Unit,
    persistentFilePath: Path, persistentSystemLogPath: Path, persistentLastNHilogPath: Path,
    persistentDir: Path, lastCrashFilePath: Path) {
    let watcher = Watcher(
        "crashWatcher",
        appEventFilters: [AppEventFilter(OS, names: [APP_CRASH], eventTypes: [FAULT])],
        onReceive: {
            domain: String, appEventGroups: Array<AppEventGroup> =>
            if (domain != OS) {
                return
            }
            var crashInfo = CrashInfo()
            if (exists(persistentFilePath)) {
                try {
                    let jsonObj = JsonValue.fromStr(String.fromUtf8(File.readFrom(persistentFilePath))).asObject()
                    crashInfo = CrashInfo.fromJson(jsonObj)
                } catch (e: JsonException) {
                    AppLog.warn(e.toString())
                }
                deleteFile(persistentFilePath)
            } else {
                AppLog.warn("No persistent crash file.")
            }
            if (exists(persistentSystemLogPath)) {
                try {
                    crashInfo.systemLog = String
                        .fromUtf8(File.readFrom(persistentSystemLogPath))
                        .replace("\n\n", "\n")
                } catch (e: Exception) {
                    AppLog.warn(e.toString())
                }
                deleteFile(persistentSystemLogPath)
            } else {
                AppLog.warn("No persistent crash system log file.")
            }
            if (exists(persistentLastNHilogPath)) {
                try {
                    crashInfo.lastNHilog = String
                        .fromUtf8(File.readFrom(persistentLastNHilogPath))
                        .replace("\n\n", "\n")
                } catch (e: Exception) {
                    AppLog.warn(e.toString())
                }
                deleteFile(persistentLastNHilogPath)
            } else {
                AppLog.warn("No persistent crash lastNHilog log file.")
            }
            for (eventGroup in appEventGroups) {
                if (eventGroup.name != APP_CRASH) {
                    continue
                }
                for (eventInfo in eventGroup.appEventInfos) {
                    if (eventInfo.params.get("external_log").isNone()) {
                        crashInfo.rawFile = "hm-metricx-cj error: external_log is none"
                        continue
                    }
                    if (let Some(v) <- eventInfo.params.get("crash_type")) {
                        if (v.toString() == "JsError") {
                            crashInfo.language = "js_crash"
                        } else if (v.toString() == "NativeCrash") {
                            crashInfo.language = "cpp_crash"
                        }
                    }
                    crashInfo.timestamp = match (eventInfo.params.get("time")) {
                        case Some(value) => value.toString()
                        case _ => None
                    }
                    crashInfo.pid = match (eventInfo.params.get("pid")) {
                        case Some(value) => value.toString().removeSuffix(".000000")
                        case _ => None
                    }
                    crashInfo.stacktrace = match (eventInfo.params.get("exception")) {
                        case Some(value) => match (value) {
                            case OBJECT(v) => extractStackTrace(v)
                            case _ => unescapeString(value.toString())
                        }
                        case _ => "hm-metricx-cj error: exception is none"
                    }
                    crashInfo.hilog = match (eventInfo.params.get("hilog")) {
                        case Some(value) => hilogWordWrap(unescapeString(value.toString()))
                        case _ => None
                    }
                    crashInfo.appVersion = match (eventInfo.params.get("bundle_version")) {
                        case Some(value) => value.toString()
                        case _ => None
                    }
                    let crashLogPath: String = eventInfo.params.get("external_log")
                        .getOrThrow().toString().removePrefix("[").removeSuffix("]")
                    if (crashLogPath.isEmpty() ) {
                        crashInfo.rawFile = "hm-metricx-cj error: crash log path is empty"
                        continue
                    }
                    if (!exists(crashLogPath)) {
                        crashInfo.rawFile = "hm-metricx-cj error: crash log path does not exist"
                        continue
                    }
                    crashInfo.crashLogPath = crashLogPath
                    let content = readFile(Path(crashLogPath), isReturnException: true)
                    crashInfo.rawFile = content
                    let res = extractFromCrashLog(content.split("\n", removeEmpty: true), crashInfo.pid,
                        crashInfo.threads)
                    crashInfo.pname = res[0]
                    crashInfo.tid = res[1]
                    crashInfo.tname = res[2]
                }
            }
            if (let Some(pid) <- crashInfo.pid) {
                let rawDumpOnOOMPath = persistentDir.join("cj_OOM_pid" + pid + ".dat")
                let dumpOnOOMPath = persistentDir.join("cj_OOM_pid" + pid + ".zlib")
                if (exists(dumpOnOOMPath)) {
                    crashInfo.dumpOnOOMPath = dumpOnOOMPath.toString()
                } else {
                    if (exists(rawDumpOnOOMPath)) {
                        if (compressFile(rawDumpOnOOMPath.toString(), dumpOnOOMPath.toString())) {
                            crashInfo.dumpOnOOMPath = dumpOnOOMPath.toString()
                        } else {
                            AppLog.warn("compressFile failed.")
                        }
                    }
                }
                if (exists(rawDumpOnOOMPath)) {
                    deleteFile(rawDumpOnOOMPath.toString())
                }
            }
            if (Process.current.pid.toString() == crashInfo.pid.getOrDefault({=> ""})) {
                writeFile(lastCrashFilePath, crashInfo.toString())
            } else {
                if (!reported) {
                    // onReceive callback sometimes will be invoked both before app crash and next launch on high-verion (API 18?) devcies
                    reportCrashInfo(crashInfo)
                }
                if (let Some(v) <- crashInfo.crashLogPath) {
                    deleteFile(v)
                }
            }
        }
    )
    addWatcher(watcher)
}

private func exit(applicationContext: ApplicationContext) {
    applicationContext.killAllProcesses({err, data =>})
}

private func extractStackTrace(obj: JsonObject): String {
    var res: String = ""
    if (obj.containsKey("stack")) {
        let name: String = obj.get("name").getOrDefault({=> JsonValue.fromStr("")}).asString().getValue()
        let message: String = obj.get("message").getOrDefault({=> JsonValue.fromStr("")}).asString().getValue()
        let stack: String = obj.get("stack").getOrDefault({=> JsonValue.fromStr("")}).asString().getValue()
        res = "Error name:" + name + "\n" + "Error message:" + message + "\n" + "Stacktrace:\n" + stack + "\n"
    } else  if (obj.containsKey("frames")) {
        res += "message: " + obj.get("message").getOrDefault({=> JsonValue.fromStr("")}).asString().getValue() + "\n"
        if (obj.containsKey("signal")) {
            let sigObj: JsonObject = obj.get("signal").getOrThrow().asObject()
            let address: String = sigObj.get("address").getOrDefault({=> JsonValue.fromStr("")}).asString().getValue()
            let code: String = sigObj.get("code").getOrDefault({=> JsonValue.fromStr("0")}).asInt().toString()
            let signo: String = sigObj.get("signo").getOrDefault({=> JsonValue.fromStr("0")}).asInt().toString()
            res += "Signal:\n\tcode:" + code + " signo: " + signo + " address: " + address + "\n"
        }
        res += "Tid: " + obj.get("tid").getOrDefault({=> JsonValue.fromStr("0")}).asInt().toString()
        res += ", Name: " + obj.get("thread_name").getOrDefault({=> JsonValue.fromStr("")}).asString().getValue() + "\n"
        if (obj.containsKey("frames")) {
            let framesArray: JsonArray = obj.get("frames").getOrThrow().asArray()
            for (i in 0..framesArray.size()) {
                let frameObj: JsonObject = framesArray[i].asObject()
                let file: String = frameObj.get("file").getOrDefault({=> JsonValue.fromStr("")}).asString().getValue()
                let symbol: String = frameObj.get("symbol").getOrDefault({=> JsonValue.fromStr("")}).asString().getValue()
                let buildId: String = frameObj.get("buildId").getOrDefault({=> JsonValue.fromStr("")}).asString().getValue()
                let pc: String = frameObj.get("pc").getOrDefault({=> JsonValue.fromStr("")}).asString().getValue()
                let offset: String = frameObj.get("offset").getOrDefault({=> JsonValue.fromStr("0")}).asInt().toString()
                var line: String = "#" + i.format("02") + " pc " + pc + " " + file
                if (!symbol.isEmpty()) {
                    line +=  "(" + symbol
                    if (!offset.isEmpty()) {
                        line += "+" + offset + ")"
                    }
                }
                if (!buildId.isEmpty()) {
                    line += "(" + buildId + ")"
                }
                res += line + "\n"
            }
        }
    } else {
        res = obj.toString()
    }
    res
}

private func extractFromCrashLog(lines: Array<String>, pid: ?String, threads: ?String) {
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
            moduleName = line.removePrefix("Module name:")
        } else if (line.startsWith("Process name:")) {
            pname = line.removePrefix("Process name:")
        } else if (line.startsWith("Tid:") && line.contains(", Name:")) {
            let arr = line.split(", ")
            if (arr.size != 2) {
                continue
            }
            tid = arr[0].removePrefix("Tid:")
            tname = arr[1].removePrefix("Name:")
            break
        }
    }
    if (pname.isEmpty()) {
        pname = moduleName
    }
    if (tid.isEmpty() && pid.isSome()) {
        tid = pid.getOrThrow()
        if (let Some(ts) <- threads) {
            let arr = ts.split("\n")
            for (thread in arr) {
                let prefix = tid + ":"
                if (thread.startsWith(prefix)) {
                    tname = thread.removePrefix(prefix)
                    break
                }
            }
        }
    }
    return (pname, tid, tname)
}

private func extractFromNativeCrashLog(lines: Array<String>) {
    var timestamp = ""
    var pid = ""
    var stacktrace = ""
    var hilog = ""
    var inHiLog = false
    var inStacktrace = false
    for (line in lines) {
        if (timestamp.isEmpty() && line.startsWith("Timestamp:")) {
            timestamp = line.removePrefix("Timestamp:")
        } else if (pid.isEmpty() && line.startsWith("Pid:")) {
            pid = line.removePrefix("Pid:")
        } else if (inHiLog) {
            hilog += line + "\n"
        } else if (line == "Reason:") {
            inStacktrace = true
            stacktrace += line.removePrefix("Reason:")
        } else if (line == "Other thread info:") {
            inStacktrace = false
        } else if (line == "HiLog:") {
            inHiLog = true
        } else if (inStacktrace) {
            stacktrace += line + "\n"
        }
    }
    return (timestamp, pid, stacktrace, hilog)
}

private func compressFile(src: String, dest: String): Bool {
    var count: Int64 = 0
    let srcFile: File = File(src, OpenMode.Read)
    let destFile: File = File(dest, OpenMode.Append)

    var tempBuf: Array<UInt8> = Array<UInt8>(1024, repeat: 0)
    var compressOutputStream: CompressOutputStream = CompressOutputStream(destFile, wrap: GzipFormat)
    while (true) {
        var readNum = srcFile.read(tempBuf)
        if (readNum > 0) {
            compressOutputStream.write(tempBuf.slice(0, readNum).toArray())
            count += readNum
        } else {
            break
        }
    }
    compressOutputStream.flush()
    compressOutputStream.close()

    srcFile.close()
    destFile.close()
    return count > 0
}

private func writeSystemLog2File(persistentSystemLogPath: String) {
    unsafe {
        let filePath = LibC.mallocCString(persistentSystemLogPath)
        if (writeSystemLog(filePath) != 0) {
            AppLog.warn("write system log file failed.")
        }
        LibC.free(filePath)
    }
}

private func writeLastNHilog2File(persistentLastNHilogPath: String) {
    unsafe {
        let filePath = LibC.mallocCString(persistentLastNHilogPath)
        if (writeLastNHiLog(filePath) != 0) {
            AppLog.warn("write lastNHilog log file failed.")
        }
        LibC.free(filePath)
    }
}

private func initHilogWatcher() {
    unsafe {
        if (registerCrashSystemlogCallback() != 0) {
            AppLog.warn("registerCrashSystemlogCallback failed.")
        }
        if (registerCrashLastNHilogCallback() != 0) {
            AppLog.warn("registerCrashLastNHilogCallback failed.")
        }
    }
}

foreign func InitNativeSignalHandler(persistentFilePath: CString, limits: CString,
    collectCrashInfo: CFunc<() -> CString>, persistentSystemLogPath: CString,
    persistentLastNHilogPath: CString, lastNHilogNumber: Int64,
    cb: CFunc<(CString, CString, CFunc<() -> CString>, CString, CString, CString, CString) -> Unit>): Int8

foreign func InitOOMHandler(targetFile: CString, zlibFile: CString, compressFile: CFunc<(CString, CString) -> Unit>): Int8

foreign func writeSystemLog(persistentFilePath: CString): Int8
foreign func writeLastNHiLog(persistentFilePath: CString): Int8

foreign func registerCrashSystemlogCallback(): Int8
foreign func registerCrashLastNHilogCallback(): Int8
