/**
 * Created on 2025/3/28
 */
package ohos_app_cangjie_hm_metricx_cj.crash

import ohos_app_cangjie_hm_metricx_cj.*
import tpc.PerformanceAnalysisKit.hiAppEvent.*
import tpc.AbilityKit.ApplicationContext
import tpc.AbilityKit.getRunningProcessInformation
import std.fs.*
import std.collection.*
import ohos.hilog.Hilog
import tpc.CoreFileKit.fs.listFile
import tpc.CoreFileKit.fs.dup
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
    private var appVersionValue: ?String = None

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

    func reset() {
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
    }
}

private var inited = false
private let TIMEOUT = Duration.second

public func initCrashHandler(
    applicationContext: ApplicationContext,
    collectCrashInfo: () -> JsonValue,
    collectNativeCrashInfo: CFunc<() -> CString>,
    reportCrashInfo: (crashInfo: CrashInfo) -> Unit,
    reportNativeCrashInfo: CFunc<(CString) -> Unit>,
    persistentDir: Path,
    enableDumpOnOOM: Bool
) {
    if (inited) {
        return
    }
    let crashInfo = CrashInfo()
    crashInfo.limits = collectLimits()
    let persistentFilePath = persistentDir.join("crash.json")
    initErrorObserver(crashInfo, applicationContext, collectCrashInfo, persistentFilePath)
    initNativeSignalHandler(persistentFilePath.toString(), applicationContext, crashInfo.limits.getOrThrow(),
        collectNativeCrashInfo, reportNativeCrashInfo)
    initCrashWatcher(crashInfo, applicationContext, reportCrashInfo, persistentFilePath)
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
    collectCrashInfo: CFunc<() -> CString>, reportCrashInfo: CFunc<(CString) -> Unit>) {
    unsafe {
        let cstr = LibC.mallocCString(persistentFilePath)
        let lmts = LibC.mallocCString(limits)
        if (InitNativeSignalHandler(
            cstr,
            lmts,
            collectCrashInfo,
            reportCrashInfo,
            {
                persistentFilePath, limits, collectCrashInfo, reportCrashInfo, fds, bundleName =>
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
                let faultlogDir = Path("/data/log/faultlog/faultlogger")
                if (!exists(faultlogDir)) {
                    AppLog.warn("No permission to access faultlog.")
                    // report at next launch in HiAppEvent callback
                    return
                }
                var crashLogFound = false
                let fut: Future<Unit> = spawn {
                    => sleep(TIMEOUT)
                }
                fut.get()
                let files = listFile("/proc/self/fd")
                let prefix = "cppcrash-" + bundleName.toString() + "-"
                files
                    .iterator()
                    .forEach(
                        {
                            file => if (file.startsWith(prefix)) {
                                crashInfo.crashLogPath = faultlogDir.join(file).toString()
                            }
                        })
                if (crashInfo.crashLogPath.isSome()) {
                    let file = crashInfo.crashLogPath.getOrThrow()
                    let content = String.fromUtf8(File.readFrom(file))
                    let lines = content.split("\n", removeEmpty: true)
                    let nativeInfo = extractFromNativeCrashLog(lines)
                    if (nativeInfo[1] != Process.current.pid.toString()) {
                        AppLog.warn("No native crash log generated.")
                        // report at next launch in HiAppEvent callback
                        return
                    }
                    crashInfo.timestamp = nativeInfo[0]
                    crashInfo.pid = nativeInfo[1]
                    crashInfo.stacktrace = nativeInfo[2]
                    crashInfo.hilog = nativeInfo[3]
                    let res = extractFromCrashLog(lines, None, None)
                    crashInfo.pname = res[0]
                    crashInfo.tid = res[1]
                    crashInfo.tname = res[2]
                    crashLogFound = true
                }
                if (!crashLogFound) {
                    AppLog.warn("No native crash log generated.")
                    // report at next launch in HiAppEvent callback
                    return
                }
                let crashInfoStr = LibC.mallocCString(crashInfo.toString())
                reportCrashInfo(crashInfoStr)
                LibC.free(crashInfoStr)
                deleteFile(persistentFilePath.toString())
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
    collectCrashInfo: () -> JsonValue, persistentFilePath: Path) {
    let errorObserver = ErrorObserver(
        {errMsg: String =>},
        onException: {
            errObject =>
            crashInfo.fds = collectFDInfo()
            crashInfo.threads = collectThreads()
            crashInfo.extraInfo = collectCrashInfo()
            writeFile(persistentFilePath.toString(), crashInfo.toString())
            Timer.once(TIMEOUT) {
                exit(applicationContext)
            }
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

private func deleteFile(path: String) {
    try {
        remove(path)
    } catch (e: FSException) {
        AppLog.warn(e.toString())
    }
}

private func deleteFile(path: Path) {
    try {
        remove(path)
    } catch (e: FSException) {
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
    if (!exists(path)) {
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
                    if (exists(fdPath)) {
                        let realPath = dup(Int32.parse(file)).path
                        fds.add(fdPath.toString(), realPath)
                    } else {
                        fds.add(fdPath.toString(), "unknown")
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
            var nativeCrashReported = true
            if (exists(persistentFilePath)) {
                nativeCrashReported = false
                if (crashInfo.fds.isNone()) {
                    try {
                        let jsonObj = JsonValue.fromStr(String.fromUtf8(File.readFrom(persistentFilePath))).asObject()
                        crashInfo = CrashInfo.fromJson(jsonObj)
                    } catch (e: JsonException) {
                        AppLog.warn(e.toString())
                    }
                }
                deleteFile(persistentFilePath)
            }
            for (eventGroup in appEventGroups) {
                if (eventGroup.name != APP_CRASH) {
                    continue
                }
                for (eventInfo in eventGroup.appEventInfos) {
                    if (eventInfo.params.get("external_log").isNone()) {
                        continue
                    }
                    let crashLogPath: String = eventInfo.params.get("external_log").getOrThrow().toString()
                    if (crashLogPath.startsWith("cppcrash-") && nativeCrashReported) {
                        crashInfo.reset()
                        return
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
                        case Some(value) => value.toString()
                        case _ => None
                    }
                    crashInfo.appVersion = match (eventInfo.params.get("bundle_version")) {
                        case Some(value) => value.toString()
                        case _ => None
                    }

                    if (!exists(crashLogPath)) {
                        continue
                    }

                    crashInfo.crashLogPath = crashLogPath
                    let content = String.fromUtf8(File.readFrom(crashLogPath))
                    let res = extractFromCrashLog(content.split("\n", removeEmpty: true), crashInfo.pid,
                        crashInfo.threads)
                    crashInfo.pname = res[0]
                    crashInfo.tid = res[1]
                    crashInfo.tname = res[2]
                }
            }
            if (crashInfo.pid.isSome()) {
                let dumpOnOOMPath = persistentFilePath.join("cj_OOM_pid" + crashInfo.pid.getOrThrow() + ".dat")
                if (exists(dumpOnOOMPath)) {
                    crashInfo.dumpOnOOMPath = dumpOnOOMPath.toString()
                }
            }
            reportCrashInfo(crashInfo)
            if (Process.current.pid.toString() == crashInfo.pid.getOrDefault({=> ""})) {
                exit(applicationContext)
            } else {
                crashInfo.reset()
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

foreign func InitNativeSignalHandler(persistentFilePath: CString, limits: CString,
    collectCrashInfo: CFunc<() -> CString>, reportCrashInfo: CFunc<(CString) -> Unit>,
    cb: CFunc<(CString, CString, CFunc<() -> CString>, CFunc<(CString) -> Unit>, CString, CString) -> Unit>): Int8

foreign func InitOOMHandler(targetFile: CString, zlibFile: CString, compressFile: CFunc<(CString, CString) -> Unit>): Int8
