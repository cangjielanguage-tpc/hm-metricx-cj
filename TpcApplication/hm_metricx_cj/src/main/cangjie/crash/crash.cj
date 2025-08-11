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
import std.io.*
import std.convert.*
import std.sort.*
import std.unicode.UnicodeStringExtension

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
    private var nativeMemDetailValue: ?String = None

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

    public mut prop nativeMemDetail: ?String {
        get() {
            nativeMemDetailValue
        }
        set(value) {
            nativeMemDetailValue = value
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
        if (let Some(v) <- nativeMemDetailValue) {
            jsonObj.put("nativeMemDetail", JsonString(v))
        }
        jsonObj.toString()
    }

    public static func fromJson(jsonObject: JsonObject): CrashInfo {
        let crashInfo = CrashInfo()
        if (let Some(v) <- jsonObject.get("language")) {
            crashInfo.language = v.toString()
        }
        if (let Some(v) <- jsonObject.get("meminfo")) {
            crashInfo.meminfo = v.toString()
        }
        if (let Some(v) <- jsonObject.get("timestamp")) {
            crashInfo.timestamp = v.toString()
        }
        if (let Some(v) <- jsonObject.get("pid")) {
            crashInfo.pid = v.toString()
        }
        if (let Some(v) <- jsonObject.get("pname")) {
            crashInfo.pname = v.toString()
        }
        if (let Some(v) <- jsonObject.get("stacktrace")) {
            crashInfo.stacktrace = v.toString()
        }
        if (let Some(v) <- jsonObject.get("hilog")) {
            crashInfo.hilog = v.toString()
        }
        if (let Some(v) <- jsonObject.get("tid")) {
            crashInfo.tid = v.toString()
        }
        if (let Some(v) <- jsonObject.get("tname")) {
            crashInfo.tname = v.toString()
        }
        if (let Some(v) <- jsonObject.get("fds")) {
            let fields: HashMap<String, JsonValue> = v.asObject().getFields()
            crashInfo.fds = json2map(fields)
        }
        if (let Some(v) <- jsonObject.get("limits")) {
            crashInfo.limits = v.toString()
        }
        if (let Some(v) <- jsonObject.get("threads")) {
            crashInfo.threads = v.toString()
        }
        if (let Some(v) <- jsonObject.get("extraInfo")) {
            crashInfo.extraInfo = v
        }
        if (let Some(v) <- jsonObject.get("crashLogPath")) {
            crashInfo.crashLogPath = v.toString()
        }
        if (let Some(v) <- jsonObject.get("dumpOnOOMPath")) {
            crashInfo.dumpOnOOMPath = v.toString()
        }
        if (let Some(v) <- jsonObject.get("appVersion")) {
            crashInfo.appVersion = v.toString()
        }
        if (let Some(v) <- jsonObject.get("rawFile")) {
            crashInfo.rawFile = v.toString()
        }
        if (let Some(v) <- jsonObject.get("systemLog")) {
            crashInfo.systemLog = v.toString()
        }
        if (let Some(v) <- jsonObject.get("nativeMemDetail")) {
            crashInfo.nativeMemDetail = v.toString()
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
        this.systemLog = None
        this.nativeMemDetail = None
    }
}

struct PersistentPaths {
    let dir: Path
    let lastCrashFilePath: Path
    let filePath: Path
    let systemLogPath: Path
    let memMapPath: Path

    public init(persistentDir: Path) {
        this.dir = persistentDir
        this.lastCrashFilePath = persistentDir.join("lastCrash.json")
        this.filePath = persistentDir.join("crash.json")
        this.systemLogPath = persistentDir.join("crashSystemLog.txt")
        this.memMapPath = persistentDir.join("crashMemMap.txt")
    }
}

public enum OOMHandlerMode {
    | Async | Sync
}

private var inited = false
private let TIMEOUT = Duration.second

public func initCrashHandler(
    applicationContext: ApplicationContext,
    collectCrashInfo: () -> JsonValue,
    collectNativeCrashInfo: CFunc<() -> CString>,
    reportCrashInfo: (crashInfo: CrashInfo) -> Unit,
    persistentDir: Path,
    enableDumpOnOOM: Option<OOMHandlerMode>
) {
    if (inited) {
        return
    }
    let persistentPaths = PersistentPaths(persistentDir)
    reportLastCrash(persistentPaths.lastCrashFilePath, reportCrashInfo)
    let crashInfo = CrashInfo()
    crashInfo.limits = collectLimits()
    let persistentFilePath = persistentDir.join("crash.json")
    let persistentSystemLogPath = persistentDir.join("crashSystemLog.txt")
    initErrorObserver(crashInfo, applicationContext, collectCrashInfo, enableDumpOnOOM, persistentPaths)
    initNativeSignalHandler(applicationContext, crashInfo.limits.getOrThrow(), collectNativeCrashInfo, persistentPaths)
    initCrashWatcher(applicationContext, reportCrashInfo, persistentPaths)
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
            reportCrashInfo(CrashInfo.fromJson(jsonObj))
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

private func initNativeSignalHandler(applicationContext: ApplicationContext, limits: String,
    collectCrashInfo: CFunc<() -> CString>, persistentPaths: PersistentPaths) {
    unsafe {
        let cstr = LibC.mallocCString(persistentPaths.filePath.toString())
        let lmts = LibC.mallocCString(limits)
        let cSystemLogPath = LibC.mallocCString(persistentPaths.systemLogPath.toString())
        let cMemMapPath = LibC.mallocCString(persistentPaths.memMapPath.toString())
        if (InitNativeSignalHandler(
            cstr,
            lmts,
            collectCrashInfo,
            cSystemLogPath,
            cMemMapPath,
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
        LibC.free(cMemMapPath)
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
    collectCrashInfo: () -> JsonValue, enableDumpOnOOM: Option<OOMHandlerMode>, persistentPaths: PersistentPaths) {
    let errorObserver = ErrorObserver(
        {errMsg: String =>},
        onException: {
            errObject =>
            crashInfo.language = "JS"
            crashInfo.meminfo = collectMemInfo()
            crashInfo.fds = collectFDInfo()
            crashInfo.threads = collectThreads()
            crashInfo.extraInfo = collectCrashInfo()
            writeFile(persistentPaths.filePath, crashInfo.toString())
            writeSystemLog2File(persistentPaths.systemLogPath.toString())
            persistentMemMap2File(persistentPaths.memMapPath.toString())
            if (enableDumpOnOOM.isSome()) {
                let rawOomFile = persistentPaths.dir.join("cj_OOM_pid" + Process.current.pid.toString() + ".dat")
                let oomFile = persistentPaths.dir.join("cj_OOM_pid" + Process.current.pid.toString() + ".zlib")
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

private func initCrashWatcher(applicationContext: ApplicationContext, reportCrashInfo: (crashInfo: CrashInfo) -> Unit,
    persistentPaths: PersistentPaths) {
    let watcher = Watcher(
        "crashWatcher",
        appEventFilters: [AppEventFilter(OS, names: [APP_CRASH], eventTypes: [FAULT])],
        onReceive: {
            domain: String, appEventGroups: Array<AppEventGroup> =>
            if (domain != OS) {
                return
            }
            var crashInfo = CrashInfo()
            if (exists(persistentPaths.filePath)) {
                try {
                    let jsonObj = JsonValue.fromStr(String.fromUtf8(File.readFrom(persistentPaths.filePath))).asObject()
                    crashInfo = CrashInfo.fromJson(jsonObj)
                } catch (e: JsonException) {
                    AppLog.warn(e.toString())
                }
                deleteFile(persistentPaths.filePath)
            }
            else {
                AppLog.warn("No persistent crash file.")
            }
            if (exists(persistentPaths.systemLogPath)) {
                try {
                    crashInfo.systemLog = String.fromUtf8(File.readFrom(persistentPaths.systemLogPath))
                } catch (e: Exception) {
                    AppLog.warn(e.toString())
                }
                deleteFile(persistentPaths.systemLogPath)
            }
            else {
                AppLog.warn("No persistent crash system log file.")
            }

            if (exists(persistentPaths.memMapPath)) {
                crashInfo.nativeMemDetail = parseMaps(persistentPaths.memMapPath, Int32.Max)
                deleteFile(persistentPaths.memMapPath)
            } else {
                AppLog.warn("No persistent crash memMap log file.")
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
            if (let Some(pid) <- crashInfo.pid) {
                let rawDumpOnOOMPath = persistentPaths.dir.join("cj_OOM_pid" + pid + ".dat")
                let dumpOnOOMPath = persistentPaths.dir.join("cj_OOM_pid" + pid + ".zlib")
                if (exists(dumpOnOOMPath)) {
                    crashInfo.dumpOnOOMPath = dumpOnOOMPath.toString()
                }
                else {
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
                writeFile(persistentPaths.lastCrashFilePath, crashInfo.toString())
            } else {
                reportCrashInfo(crashInfo)
            }
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
            AppLog.warn("write crash system log file failed.")
        }
        LibC.free(filePath)
    }
}

private func persistentMemMap2File(persistentMemMapFileName: String) {
    unsafe {
        let filePath = LibC.mallocCString(persistentMemMapFileName)
        if (persistentMemMapFile(filePath) != 0) {
            AppLog.warn("write crash memMap file failed.")
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

private func parseMaps(filePath: Path, headCount: Int32): String {
    let specs = HashMap<String, Array<String>>(
        [("code", [".hap", ".hsp", ".har", ".so"]), ("malloc", ["libc_malloc"]), ("font", [".ttc", ".ttf", ".otf"]),
            ("stack", ["stack"]), ("thread", ["thread"])])
    let pathLength = HashMap<String, Int64>()
    let specPathLength = HashMap<String, Int64>()
    try {
        let reader = StringReader(File(filePath, OpenMode.Read))
        while (let Some(line) <- reader.readln()) {
            let segments = line.trim().split(" ", removeEmpty: true)
            if (segments.size < 5) {
                AppLog.info("parse memMap skiped line: " + line)
                continue
            }
            if (segments.size > 6) {
                for (str in segments[6..]) {
                    segments[5] += " " + str
                }
            }
            var zonePath = "unknown"
            if (segments.size >= 6) {
                zonePath = segments[5]
            }
            let zoneItem = segments[0].split("-")
            if (zoneItem.size != 2) {
                continue
            }
            try {
                let curSize = Int64.parse("0x" + zoneItem[1]) - Int64.parse("0x" + zoneItem[0])
                let originPathSize = pathLength.get(zonePath) ?? 0
                pathLength.add(zonePath, originPathSize + curSize)

                for ((spec, keywords) in specs) {
                    for (keyword in keywords) {
                        if (zonePath.contains(keyword)) {
                            let specSize: Int64 = specPathLength.get(spec) ?? 0
                            specPathLength.add(spec, specSize + curSize)
                            break
                        }
                    }
                }
            } catch (e: Exception) {
                AppLog.info("parse memMap skiped line: ${line}, exception: ${e.toString()}")
            }
        }
        reader.close()
    } catch (e: Exception) {
        AppLog.warn("parse memMap failed: " + e.toString())
    }

    // 格式化
    let by: ((String, Int64), (String, Int64)) -> Ordering = {
        a, b =>
        if (a[1] < b[1]) {
            return Ordering.GT
        } else if (a[1] > b[1]) {
            return Ordering.LT
        }
        return Ordering.EQ
    }
    let specLengthArr = specPathLength.toArray()
    sort(specLengthArr, by: by, stable: true)
    let pathLengthArr = pathLength.toArray()
    sort(pathLengthArr, by: by, stable: true)

    let stringBuilder = StringBuilder()
    stringBuilder.append("============Summarry============\n")
    for ((spec, size) in specLengthArr) {
        stringBuilder.append("${formatWithCommasAndPadding(size / 1024, 10)} kB    ${spec}\n")
    }

    stringBuilder.append("============Details============\n")
    var totalSize: Int64 = 0
    var count: Int32 = 0
    for ((path, size) in pathLengthArr) {
        stringBuilder.append("${formatWithCommasAndPadding(size / 1024, 10)} kB    ${path}\n")
        totalSize += size
        count++
        if (count >= headCount) {
            stringBuilder.append("${(-1).format("10")} kB   others\n")
            break
        }
    }
    stringBuilder.append("${formatWithCommasAndPadding(totalSize / 1024, 10)} kB    Total\n")
    stringBuilder.toString()
}

foreign func InitNativeSignalHandler(persistentFilePath: CString, limits: CString,
    collectCrashInfo: CFunc<() -> CString>, persistentSystemLogPath: CString, pMemMapFilePath: CString,
    cb: CFunc<(CString, CString, CFunc<() -> CString>, CString, CString, CString, CString) -> Unit>): Int8

foreign func InitOOMHandler(targetFile: CString, zlibFile: CString, compressFile: CFunc<(CString, CString) -> Unit>): Int8

foreign func writeSystemLog(persistentFilePath: CString): Int8

foreign func persistentMemMapFile(persistentFilePath: CString): Int8

foreign func registerCrashHilogCallback(): Int8
