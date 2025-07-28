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

    public func toString(): String {
        let jsonObj = JsonObject()
        if (languageValue.isSome()) {
            jsonObj.put("language", JsonString(languageValue.getOrThrow()))
        }
        if (meminfoValue.isSome()) {
            jsonObj.put("meminfo", JsonString(meminfoValue.getOrThrow()))
        }
        if (timestampValue.isSome()) {
            jsonObj.put("timestamp", JsonString(timestampValue.getOrThrow()))
        }
        if (pidValue.isSome()) {
            jsonObj.put("pid", JsonString(pidValue.getOrThrow()))
        }
        if (pnameValue.isSome()) {
            jsonObj.put("pname", JsonString(pnameValue.getOrThrow()))
        }
        if (stacktraceValue.isSome()) {
            jsonObj.put("stacktrace", JsonString(stacktraceValue.getOrThrow()))
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
        if (crashLogPathValue.isSome()) {
            jsonObj.put("crashLogPath", JsonString(crashLogPathValue.getOrThrow()))
        }
        if (dumpOnOOMPathValue.isSome()) {
            jsonObj.put("dumpOnOOMPath", JsonString(dumpOnOOMPathValue.getOrThrow()))
        }
        if (appVersionValue.isSome()) {
            jsonObj.put("appVersion", JsonString(appVersionValue.getOrThrow()))
        }
        if (rawFileValue.isSome()) {
            jsonObj.put("rawFile", JsonString(rawFileValue.getOrThrow()))
        }
        if (systemLogValue.isSome()) {
            jsonObj.put("systemLog", JsonString(systemLogValue.getOrThrow()))
        }
        jsonObj.toString()
    }

    public static func fromJson(jsonObject: JsonObject): CrashInfo {
        let crashInfo = CrashInfo()
        if (jsonObject.get("language").isSome()) {
            crashInfo.language = jsonObject.get("language").getOrThrow().toString()
        }
        if (jsonObject.get("meminfo").isSome()) {
            crashInfo.meminfo = jsonObject.get("meminfo").getOrThrow().toString()
        }
        if (jsonObject.get("timestamp").isSome()) {
            crashInfo.timestamp = jsonObject.get("timestamp").getOrThrow().toString()
        }
        if (jsonObject.get("pid").isSome()) {
            crashInfo.pid = jsonObject.get("pid").getOrThrow().toString()
        }
        if (jsonObject.get("pname").isSome()) {
            crashInfo.pname = jsonObject.get("pname").getOrThrow().toString()
        }
        if (jsonObject.get("stacktrace").isSome()) {
            crashInfo.stacktrace = jsonObject.get("stacktrace").getOrThrow().toString()
        }
        if (jsonObject.get("hilog").isSome()) {
            crashInfo.hilog = jsonObject.get("hilog").getOrThrow().toString()
        }
        if (jsonObject.get("tid").isSome()) {
            crashInfo.tid = jsonObject.get("tid").getOrThrow().toString()
        }
        if (jsonObject.get("tname").isSome()) {
            crashInfo.tname = jsonObject.get("tname").getOrThrow().toString()
        }
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
        if (jsonObject.get("extraInfo").isSome()) {
            crashInfo.extraInfo = jsonObject.get("extraInfo")
        }
        if (jsonObject.get("crashLogPath").isSome()) {
            crashInfo.crashLogPath = jsonObject.get("crashLogPath").getOrThrow().toString()
        }
        if (jsonObject.get("dumpOnOOMPath").isSome()) {
            crashInfo.dumpOnOOMPath = jsonObject.get("dumpOnOOMPath").getOrThrow().toString()
        }
        if (jsonObject.get("appVersion").isSome()) {
            crashInfo.appVersion = jsonObject.get("appVersion").getOrThrow().toString()
        }
        if (jsonObject.get("rawFile").isSome()) {
            crashInfo.rawFile = jsonObject.get("rawFile").getOrThrow().toString()
        }
        if (jsonObject.get("systemLog").isSome()) {
            crashInfo.systemLog = jsonObject.get("systemLog").getOrThrow().toString()
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
    let persistentSystemLogPath = persistentDir.join("crashSystemLog.json")
    initErrorObserver(crashInfo, applicationContext, collectCrashInfo, persistentFilePath, persistentSystemLogPath)
    initNativeSignalHandler(persistentFilePath.toString(), applicationContext, crashInfo.limits.getOrThrow(),
        collectNativeCrashInfo, persistentSystemLogPath.toString())
    initCrashWatcher(applicationContext, reportCrashInfo, persistentFilePath, persistentSystemLogPath, persistentDir)
    initHilogWatcher()
    if (enableDumpOnOOM) {
        initOOMHandler(persistentDir.toString())
    }
    inited = true
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
    collectCrashInfo: CFunc<() -> CString>, persistentSystemLogPath: String) {
    unsafe {
        let cstr = LibC.mallocCString(persistentFilePath)
        let lmts = LibC.mallocCString(limits)
        let cSystemLogPath = LibC.mallocCString(persistentSystemLogPath)
        if (InitNativeSignalHandler(
            cstr,
            lmts,
            collectCrashInfo,
            cSystemLogPath,
            {
                persistentFilePath, limits, collectCrashInfo, fds, threads, meminfo, bundleName =>
                let crashInfo = CrashInfo()
                crashInfo.language = "CPP"
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
    collectCrashInfo: () -> JsonValue, persistentFilePath: Path, persistentSystemLogPath: Path) {
    let errorObserver = ErrorObserver(
        {errMsg: String =>},
        onException: {
            errObject =>
            crashInfo.language = "JS"
            crashInfo.meminfo = collectMemInfo()
            crashInfo.fds = collectFDInfo()
            crashInfo.threads = collectThreads()
            crashInfo.extraInfo = collectCrashInfo()
            writeFile(persistentFilePath.toString(), crashInfo.toString())
            writeSystemLog2File(persistentSystemLogPath.toString())
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

private func readFile(path: Path) {
    if (!exists(path)) {
        return ""
    }
    try {
        return String.fromUtf8(File.readFrom(path))
    } catch (e: Exception) {
        AppLog.warn("reading ${path} failed: " + e.toString())
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

private func initCrashWatcher(applicationContext: ApplicationContext,
    reportCrashInfo: (crashInfo: CrashInfo) -> Unit, persistentFilePath: Path, persistentSystemLogPath: Path, persistentDir: Path) {
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
            }
            else {
                AppLog.warn("No persistent crash file.")
            }
            if (exists(persistentSystemLogPath)) {
                try {
                    crashInfo.systemLog = String.fromUtf8(File.readFrom(persistentSystemLogPath))
                } catch (e: JsonException) {
                    AppLog.warn(e.toString())
                }
                deleteFile(persistentSystemLogPath)
            }
            else {
                AppLog.warn("No persistent crash system log file.")
            }
            for (eventGroup in appEventGroups) {
                if (eventGroup.name != APP_CRASH) {
                    continue
                }
                for (eventInfo in eventGroup.appEventInfos) {
                    if (eventInfo.params.get("external_log").isNone()) {
                        continue
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
                        case Some(value) => value.toString()
                        case _ => None
                    }
                    crashInfo.hilog = match (eventInfo.params.get("hilog")) {
                        case Some(value) => hilogWordWrap(value.toString())
                        case _ => None
                    }
                    crashInfo.appVersion = match (eventInfo.params.get("bundle_version")) {
                        case Some(value) => value.toString()
                        case _ => None
                    }
                    let crashLogPath: String = eventInfo.params.get("external_log")
                        .getOrThrow().toString().removePrefix("[").removeSuffix("]")
                    if (crashLogPath.isEmpty() || !exists(crashLogPath)) {
                        continue
                    }
                    crashInfo.crashLogPath = crashLogPath
                    let content = readFile(Path(crashLogPath))
                    crashInfo.rawFile = content
                    let res = extractFromCrashLog(content.split("\n", removeEmpty: true), crashInfo.pid,
                        crashInfo.threads)
                    crashInfo.pname = res[0]
                    crashInfo.tid = res[1]
                    crashInfo.tname = res[2]
                }
            }
            if (crashInfo.pid.isSome()) {
                let dumpOnOOMPath = persistentDir.join("cj_OOM_pid" + crashInfo.pid.getOrThrow() + ".zlib")
                if (exists(dumpOnOOMPath)) {
                    crashInfo.dumpOnOOMPath = dumpOnOOMPath.toString()
                }
            }
            reportCrashInfo(crashInfo)
        }
    )
    addWatcher(watcher)
}

private func exit(applicationContext: ApplicationContext) {
    applicationContext.killAllProcesses({err, data =>})
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
        if (threads.isSome()) {
            let arr = threads.getOrThrow().split("\n")
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

private func initHilogWatcher() {

    unsafe {
        if (registerCrashHilogCallback() != 0){
            AppLog.warn("registerCrashHilogCallback failed.")
        }
    }
}

foreign func InitNativeSignalHandler(persistentFilePath: CString, limits: CString,
    collectCrashInfo: CFunc<() -> CString>, persistentSystemLogPath: CString,
    cb: CFunc<(CString, CString, CFunc<() -> CString>, CString, CString, CString, CString) -> Unit>): Int8

foreign func InitOOMHandler(targetFile: CString, zlibFile: CString, compressFile: CFunc<(CString, CString) -> Unit>): Int8

foreign func writeSystemLog(persistentFilePath: CString): Int8

foreign func registerCrashHilogCallback(): Int8