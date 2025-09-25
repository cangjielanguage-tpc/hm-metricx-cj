/**
 * Created on 2025/3/28
 */
package ohos_app_cangjie_hm_metricx_cj.crash

import ohos_app_cangjie_hm_metricx_cj.util.*
import std.fs.*
import std.collection.*
import std.convert.*
import std.env.*
import stdx.compress.zlib.*
import stdx.encoding.json.*
import std.time.*
import std.sync.*
import std.io.*
import std.convert.*
import std.sort.*
import ohos.ark_interop_macro.*
import ohos.ark_interop.*

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
    private var extraInfoValue: ?String = None
    private var crashLogPathValue: ?String = None
    private var dumpOnOOMPathValue: ?String = None
    private var appVersionValue: ?String = None
    private var rawFileValue: ?String = None
    private var systemLogValue: ?String = None
    private var lastNHilogValue: ?String = None
    private var dumpTimeValue: ?String = None
    private var historyRawFilesValue: ?String = None
    private var nativeMemDetailValue: ?String = None
    private var memPersistTimeValue: ?String = None

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

    public mut prop extraInfo: ?String {
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

    public mut prop dumpTime: ?String {
        get() {
            dumpTimeValue
        }
        set(value) {
            dumpTimeValue = value
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

    public mut prop nativeMemDetail: ?String {
        get() {
            nativeMemDetailValue
        }
        set(value) {
            nativeMemDetailValue = value
        }
    }

    public mut prop memPersistTime: ?String {
        get() {
            memPersistTimeValue
        }
        set(value) {
            memPersistTimeValue = value
        }
    }

    public func toInteropCrashInfo(): InteropCrashInfo {
        let crashInfo = InteropCrashInfo()
        crashInfo.language = languageValue
        crashInfo.meminfo = meminfoValue
        crashInfo.timestamp = timestampValue
        crashInfo.pid = pidValue
        crashInfo.pname = pnameValue
        crashInfo.stacktrace = stacktraceValue
        crashInfo.hilog = hilogValue
        crashInfo.tid = tidValue
        crashInfo.tname = tnameValue
        if (let Some(v) <- fdsValue) {
            crashInfo.fds = JSHashMapEx<String, String>(v)
        }
        crashInfo.limits = limitsValue
        crashInfo.threads = threadsValue
        crashInfo.extraInfo = extraInfoValue
        crashInfo.crashLogPath = crashLogPathValue
        crashInfo.dumpOnOOMPath = dumpOnOOMPathValue
        crashInfo.appVersion = appVersionValue
        crashInfo.rawFile = rawFileValue
        crashInfo.systemLog = systemLogValue
        crashInfo.lastNHilog = lastNHilogValue
        crashInfo.dumpTime = dumpTimeValue
        crashInfo.historyRawFiles = historyRawFiles
        crashInfo.nativeMemDetail = nativeMemDetailValue
        crashInfo.memPersistTime = memPersistTimeValue
        crashInfo
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
            jsonObj.put("extraInfo", JsonString(v))
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
        if (let Some(v) <- dumpTimeValue) {
            jsonObj.put("dumpTime", JsonString(v))
        }
        if (let Some(v) <- historyRawFiles) {
            jsonObj.put("historyRawFiles", JsonString(v))
        }
        if (let Some(v) <- nativeMemDetailValue) {
            jsonObj.put("nativeMemDetail", JsonString(v))
        }
        if (let Some(v) <- memPersistTimeValue) {
            jsonObj.put("memPersistTime", JsonString(v))
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
            let fields: HashMap<String, JsonValue> = v
                .asObject()
                .getFields()
            crashInfo.fds = json2map(fields)
        }
        if (let Some(v) <- jsonObject.get("limits")) {
            crashInfo.limits = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("threads")) {
            crashInfo.threads = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("extraInfo")) {
            crashInfo.extraInfo = JsonValueToString(v)
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
        if (let Some(v) <- jsonObject.get("dumpTime")) {
            crashInfo.dumpTime = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("historyRawFiles")) {
            crashInfo.historyRawFiles = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("nativeMemDetail")) {
            crashInfo.nativeMemDetail = JsonValueToString(v)
        }
        if (let Some(v) <- jsonObject.get("memPersistTime")) {
            crashInfo.memPersistTime = JsonValueToString(v)
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
        this.systemLogValue = None
        this.dumpTimeValue = None
        this.historyRawFilesValue = None
        this.nativeMemDetailValue = None
        this.memPersistTimeValue = None
    }
}

@Interop[ArkTS]
public class InteropCrashInfo {
    public var language: Option<String> = None
    public var meminfo: Option<String> = None
    public var timestamp: Option<String> = None
    public var pid: Option<String> = None
    public var pname: Option<String> = None
    public var stacktrace: Option<String> = None
    public var hilog: Option<String> = None
    public var tid: Option<String> = None
    public var tname: Option<String> = None
    public var fds: Option<JSHashMapEx<String, String>> = None
    public var limits: Option<String> = None
    public var threads: Option<String> = None
    public var extraInfo: Option<String> = None
    public var crashLogPath: Option<String> = None
    public var dumpOnOOMPath: Option<String> = None
    public var appVersion: Option<String> = None
    public var rawFile: Option<String> = None
    public var systemLog: Option<String> = None
    public var lastNHilog: Option<String> = None
    public var dumpTime: Option<String> = None
    public var historyRawFiles: Option<String> = None
    public var nativeMemDetail: Option<String> = None
    public var memPersistTime: Option<String> = None

    public init() {}
}

class PersistentPaths {
    let dir: Path
    let lastCrashFilePath: Path
    let filePath: Path
    let systemLogPath: Path
    let memMapPath: Path
    let memMallocPath: Path
    let parsedAddrPath: Path
    let lastNHilogPath: Path
    let dumpTimePath: Path
    let memPersistTimePath: Path

    public init(persistentDir: Path) {
        this.dir = persistentDir
        this.lastCrashFilePath = persistentDir.join("lastCrash.json")
        this.filePath = persistentDir.join("crash.json")
        this.systemLogPath = persistentDir.join("crashSystemLog.txt")
        this.memMapPath = persistentDir.join("crashMemMap.txt")
        this.memMallocPath = persistentDir.join("crashMemMalloc.txt")
        this.parsedAddrPath = persistentDir.join("crashParsedAddrPath.txt")
        this.lastNHilogPath = persistentDir.join("crashLastNHilog.txt")
        this.dumpTimePath = persistentDir.join("dumpTime.txt")
        this.memPersistTimePath = persistentDir.join("crashMemPersistTime.txt")
    }
}

class MallocModel {
    let size: Int64
    let ptr: Int64
    let stack: Array<Int64>

    public init(size: Int64, ptr: Int64, stack: Array<Int64>) {
        this.size = size
        this.ptr = ptr
        this.stack = stack
    }
}

class MallocStack {
    let stack: String
    let size: Int64
    public init(stack: String, size: Int64) {
        this.stack = stack
        this.size = size
    }
}

class ParsedAddr {
    let pc: Int64
    let parsedAddr: String
    let soName: String
    public init(pc: Int64, parsedAddr: String, soName: String) {
        this.pc = pc
        this.parsedAddr = parsedAddr
        this.soName = soName
    }
}

@Interop[ArkTS]
public class CMemMonitorConfig {
    public let shouldBeClusteredToThisSo: (String) -> Bool
    public init(shouldBeClusteredToThisSo: (String) -> Bool) {
        this.shouldBeClusteredToThisSo = shouldBeClusteredToThisSo
    }
}

public enum OOMHandlerMode {
    | Async | Sync
}

@C
struct DumpTime {
    var total: Int64 = 0
    var stw: Int64 = 0
    var fork: Int64 = 0
    var dump: Int64 = 0
}

private var inited = false
private let TIMEOUT = Duration.second
private var reported = false
private var OOMHandlerInited = false;
private let PRIORITY_HIGH: Array<String> = []
private let PRIORITY_LOW: Array<String> = []
private var iCollectCrashInfo: () -> String = {=> ""}

@C
func collectExtraCrashInfo(): CString {
    unsafe {
        let crashInfoStr = LibC.mallocCString(iCollectCrashInfo())
        crashInfoStr
    }
}

public func initCrashHandler(
    addCrashWatcher: (callback: (time: String, pid: String, exception: String, hilog: String, external_log: String,
            crash_type: String, bundle_version: String) -> Unit) -> Unit,
    onCrash: (() -> Unit) -> Unit,
    exit: () -> Unit,
    collectCrashInfo: () -> String,
    reportCrashInfo: (crashInfo: InteropCrashInfo) -> Unit,
    persistentDir: Path,
    enableDumpOnOOM: Option<OOMHandlerMode>,
    lastNHilogNumber: Int64,
    systemLogNumber: Int64,
    enableMemMonitor: Option<CMemMonitorConfig>
) {
    if (inited) {
        return
    }
    cleanHistoryLogFiles()
    let persistentPaths = PersistentPaths(persistentDir)
    let hilogNumber = max(lastNHilogNumber, 0)
    let systemLogNum = max(systemLogNumber, 0)
    //    spawn {
    //        => reportLastCrash(persistentPaths, reportCrashInfo)
    //    }
    reportLastCrash(persistentPaths, reportCrashInfo) // TODO
    let crashInfo = CrashInfo()
    crashInfo.limits = collectLimits()
    initErrorObserver(onCrash, crashInfo, exit, collectCrashInfo, enableDumpOnOOM, persistentPaths)
    initNativeSignalHandler(crashInfo
        .limits
        .getOrThrow(), collectExtraCrashInfo, persistentPaths, hilogNumber, systemLogNum)
    initCrashWatcher(addCrashWatcher, reportCrashInfo, persistentPaths, enableMemMonitor)
    initHilogWatcher()
    if (enableMemMonitor.isSome()) {
        spawn {
            => initNativeMemoryWatcher()
        }
    }
    if (let Some(handlerMode) <- enableDumpOnOOM) {
        match (handlerMode) {
            case OOMHandlerMode.Sync => initOOMHandler(persistentDir.toString())
            case OOMHandlerMode.Async => spawn {
                => initOOMHandler(persistentDir.toString())
            }
        }
    }
    inited = true
}

private func reportLastCrash(persistentPaths: PersistentPaths, reportCrashInfo: (crashInfo: InteropCrashInfo) -> Unit) {
    if (exists(persistentPaths.lastCrashFilePath)) {
        try {
            let jsonObj = JsonValue
                .fromStr(readFile(persistentPaths.lastCrashFilePath))
                .asObject()
            let crashInfo = CrashInfo.fromJson(jsonObj)
            deleteFile(persistentPaths.lastCrashFilePath)
            crashInfo.dumpTime = readFile(persistentPaths.dumpTimePath)
            deleteFile(persistentPaths.dumpTimePath)
            if (let Some(pid) <- crashInfo.pid) {
                crashInfo.dumpOnOOMPath = compressOOMFile(pid, persistentPaths.dir)
            }
            reportCrashInfo(crashInfo.toInteropCrashInfo())
            reported = true
        } catch (e: JsonException) {
            metricx_warn("hm-metricx-cj error: " + e.toString())
        }
    }
}

private func initOOMHandler(persistentDir: String) {
    setVariable("cjHeapDumpOnOOM", "on")
    setVariable("cjHeapDumpLog", persistentDir)
    unsafe {
        let targetFile = LibC.mallocCString(persistentDir + "/cj_OOM_pid" + getProcessId().toString() + ".dat")
        let zlibFile = LibC.mallocCString(persistentDir + "/cj_OOM_pid" + getProcessId().toString() + ".zlib")
        if (InitOOMHandler(targetFile) != 0) {
            metricx_warn("hm-metricx-cj error: InitOOMHandler failed.")
        } else {
            OOMHandlerInited = true
        }
        LibC.free(targetFile)
        LibC.free(zlibFile)
    }
}

private func initNativeSignalHandler(limits: String, collectCrashInfo: CFunc<() -> CString>,
    persistentPaths: PersistentPaths, lastNHilogNumber: Int64, systemLogNumber: Int64) {
    unsafe {
        let cstr = LibC.mallocCString(persistentPaths
            .filePath
            .toString())
        let lmts = LibC.mallocCString(limits)
        let cSystemLogPath = LibC.mallocCString(persistentPaths
            .systemLogPath
            .toString())
        let cLastNHilogPath = LibC.mallocCString(persistentPaths
            .lastNHilogPath
            .toString())
        let cMemMapPath = LibC.mallocCString(persistentPaths
            .memMapPath
            .toString())
        let cMemMallocPath = LibC.mallocCString(persistentPaths
            .memMallocPath
            .toString())
        let cParsedAddrPath = LibC.mallocCString(persistentPaths
            .parsedAddrPath
            .toString())
        let cMemPersistTimePath = LibC.mallocCString(persistentPaths
            .memPersistTimePath
            .toString())
        if (InitNativeSignalHandler(
            cstr,
            lmts,
            collectCrashInfo,
            cSystemLogPath,
            cMemMapPath,
            cMemMallocPath,
            cParsedAddrPath,
            cMemPersistTimePath,
            cLastNHilogPath,
            lastNHilogNumber,
            systemLogNumber,
            {
                persistentFilePath, limits, collectCrashInfo, fds, threads, meminfo, bundleName =>
                    let crashInfo = CrashInfo()
                    crashInfo.limits = limits.toString()
                    crashInfo.fds = parseFDs(fds.toString())
                    // sometimes invoking collectThreads will crash, so read tids at native side
                    crashInfo.threads = threads.toString()
                    // sometimes invoking collectMemInfo will crash, so read meminfo at native side
                    crashInfo.meminfo = meminfo.toString()
                    try {
                        crashInfo.extraInfo = collectCrashInfo().toString()
                    } catch (e: Exception) {
                        metricx_warn("hm-metricx-cj error: " + e.toString())
                    }
                    writeFile(persistentFilePath.toString(), crashInfo.toString())
            }
        ) != 0) {
            metricx_warn("hm-metricx-cj error: InitNativeSignalHandler failed.")
        }
        LibC.free(cstr)
        LibC.free(lmts)
        LibC.free(cSystemLogPath)
        LibC.free(cLastNHilogPath)
        LibC.free(cMemMapPath)
        LibC.free(cMemMallocPath)
        LibC.free(cParsedAddrPath)
        LibC.free(cMemPersistTimePath)
    }
}

private func parseFDs(fds: String) {
    let map: HashMap<String, String> = HashMap()
    let arr = fds.split(",", removeEmpty: true)
    if (arr.size % 2 != 0) {
        metricx_warn("hm-metricx-cj error: parseFDs failed.")
        return map
    }
    var i = 0
    while (i < arr.size) {
        map.add(arr[i], arr[i + 1])
        i += 2
    }
    map
}

private func waitOOMDumping(exit: () -> Unit, dumpTimePath: Path): Unit {
    Timer.once(TIMEOUT) {
        let isOOMDumping = unsafe {
            IsOOMDumping()
        }
        metricx_warn("hm_metricx_cj: isOOMDumping: ${isOOMDumping}")
        if (isOOMDumping) {
            waitOOMDumping(exit, dumpTimePath)
        } else {
            let dumpTime = unsafe {
                GetDumpTime()
            }
            writeFile(dumpTimePath,
                "dump time: total: ${dumpTime.total} ms, stw: ${dumpTime.stw} ms, fork: ${dumpTime.fork} ms, dump: ${dumpTime.dump} ms")
            exit()
        }
    }
}

private func initErrorObserver(onCrash: (() -> Unit) -> Unit, crashInfo: CrashInfo, exit: () -> Unit,
    collectCrashInfo: () -> String, enableDumpOnOOM: Option<OOMHandlerMode>, persistentPaths: PersistentPaths) {
    onCrash({
        => try {
            crashInfo.meminfo = collectMemInfo()
            crashInfo.fds = collectFDInfo()
            crashInfo.threads = collectThreads()
            crashInfo.extraInfo = collectCrashInfo()
            writeFile(persistentPaths.filePath, crashInfo.toString())
            writeSystemLog2File(persistentPaths
                .systemLogPath
                .toString())
            writeLastNHilog2File(persistentPaths
                .lastNHilogPath
                .toString())
            persistMemoryData2File(persistentPaths
                .memMapPath
                .toString(), persistentPaths
                .memMallocPath
                .toString(), persistentPaths
                .parsedAddrPath
                .toString(), persistentPaths
                .memPersistTimePath
                .toString())
            if (OOMHandlerInited) {
                waitOOMDumping(exit, persistentPaths.dumpTimePath)
            } else {
                exit()
            }
        } catch (e: Exception) {
            metricx_warn("hm-metricx-cj error: initErrorObserver error, " + e.toString())
            exit()
        }
    })
}

private func writeFile(path: String, data: String) {
    try {
        File.writeTo(path, data.toArray())
    } catch (e: FSException) {
        metricx_warn("hm-metricx-cj error: " + e.toString())
    } catch (e: IllegalArgumentException) {
        metricx_warn("hm-metricx-cj error: " + e.toString())
    }
}

private func writeFile(path: Path, data: String) {
    try {
        File.writeTo(path, data.toArray())
    } catch (e: FSException) {
        metricx_warn("hm-metricx-cj error: " + e.toString())
    } catch (e: IllegalArgumentException) {
        metricx_warn("hm-metricx-cj error: " + e.toString())
    }
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
        metricx_warn("hm-metricx-cj error: collectFDInfo failed: " + e.toString())
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
        vss = "Vss:\t\t\t\t" + (Int32
            .tryParse(statm.split(" ", removeEmpty: true)[0])
            .getOrThrow() * 4).toString() + " KB"
    } catch (e: Exception) {
        metricx_warn("hm-metricx-cj error: statm failed: " + e.toString())
    }
    smaps_rollup + "\n" + vss
}

private func initCrashWatcher(
    addCrashWatcher: (callback: (time: String, pid: String, exception: String, hilog: String, external_log: String,
            crash_type: String, bundle_version: String) -> Unit) -> Unit,
    reportCrashInfo: (crashInfo: InteropCrashInfo) -> Unit, persistentPaths: PersistentPaths,
    enableMemMonitor: Option<CMemMonitorConfig>) {
    let cb = {
        time: String, pid: String, exception: String, hilog: String, external_log: String, crash_type: String, 
            bundle_version: String => try {
            var crashInfo = CrashInfo()
            if (exists(persistentPaths.filePath)) {
                try {
                    let jsonObj = JsonValue
                        .fromStr(String.fromUtf8(File.readFrom(persistentPaths.filePath)))
                        .asObject()
                    crashInfo = CrashInfo.fromJson(jsonObj)
                } catch (e: JsonException) {
                    metricx_warn("hm-metricx-cj error: " + e.toString())
                }
                deleteFile(persistentPaths.filePath)
            } else {
                metricx_warn("hm-metricx-cj error: No persistent crash file.")
            }
            crashInfo.dumpTime = readFile(persistentPaths.dumpTimePath)
            deleteFile(persistentPaths.dumpTimePath)
            crashInfo.systemLog = readFile(persistentPaths.systemLogPath).replace("\n\n", "\n")
            deleteFile(persistentPaths.systemLogPath)
            crashInfo.lastNHilog = readFile(persistentPaths.lastNHilogPath).replace("\n\n", "\n")
            deleteFile(persistentPaths.lastNHilogPath)
            crashInfo.memPersistTime = readFile(persistentPaths.memPersistTimePath)
            deleteFile(persistentPaths.memPersistTimePath)
            if (exists(persistentPaths.memMapPath) && exists(persistentPaths.memMallocPath)) {
                var shouldBeClusteredToThisSo = {soName: String => false}
                if (let Some(v) <- enableMemMonitor) {
                    shouldBeClusteredToThisSo = v.shouldBeClusteredToThisSo
                }
                crashInfo.nativeMemDetail = parseStackFrame(persistentPaths, shouldBeClusteredToThisSo)
                deleteFile(persistentPaths.memMapPath)
                deleteFile(persistentPaths.memMallocPath)
                deleteFile(persistentPaths.parsedAddrPath)
            } else {
                metricx_warn("hm-metricx-cj error: No persistent crash memory file.")
            }
            var crashLogPath = external_log
            if (crash_type == "JsError") {
                crashInfo.language = "js_crash"
            } else if (crash_type == "NativeCrash") {
                crashInfo.language = "cpp_crash"
            }
            crashInfo.timestamp = time
            crashInfo.pid = pid
            crashInfo.stacktrace = exception
            crashInfo.hilog = hilog
            crashInfo.appVersion = bundle_version
            if (crashLogPath.isEmpty()) {
                crashInfo.rawFile = "hm-metricx-cj error: crash log path is empty \n" + getLogFileInfo()
                crashInfo.historyRawFiles = collectAndCleanHistoryLogFiles()
            } else if (!exists(crashLogPath)) {
                crashInfo.rawFile = "hm-metricx-cj error: crash log path ${crashLogPath} does not exist \n" +
                    getLogFileInfo()
            }
            crashInfo.crashLogPath = crashLogPath
            let content = readFile(Path(crashLogPath), isReturnException: true)
            crashInfo.rawFile = content
            deleteFile(crashLogPath)
            let res = extractFromCrashLog(content.split("\n", removeEmpty: true), crashInfo.pid, crashInfo.threads)
            crashInfo.pname = res[0]
            crashInfo.tid = res[1]
            crashInfo.tname = res[2]
            if (getProcessId().toString() == crashInfo
                .pid
                .getOrDefault({=> ""})) {
                writeFile(persistentPaths.lastCrashFilePath, crashInfo.toString())
            } else {
                if (!reported) {
                    let crashInfoTemp: CrashInfo = crashInfo
                    if (let Some(pid) <- crashInfoTemp.pid) {
                        crashInfoTemp.dumpOnOOMPath = compressOOMFile(pid, persistentPaths.dir)
                    }
                    // onReceive callback sometimes will be invoked both before app crash and next launch on high-verion (API 18?) devcies
                    reportCrashInfo(crashInfoTemp.toInteropCrashInfo()) // TODO
                    //                    spawn {
                    //                        =>
                    //                            if (let Some(pid) <- crashInfoTemp.pid) {
                    //                                crashInfoTemp.dumpOnOOMPath = compressOOMFile(pid, persistentPaths.dir)
                    //                            }
                    //                            // onReceive callback sometimes will be invoked both before app crash and next launch on high-verion (API 18?) devcies
                    //                            reportCrashInfo(crashInfoTemp.toInteropCrashInfo())
                    //                    }
                }
            }
        } catch (e: Exception) {
            metricx_warn("hm-metricx-cj error: initCrashWatcher error, " + e.toString())
        }
    }
    addCrashWatcher(cb)
}

private func compressOOMFile(pid: String, dir: Path): Option<String> {
    let rawDumpOnOOMPath = dir.join("cj_OOM_pid" + pid + ".dat")
    let dumpOnOOMPath = dir.join("cj_OOM_pid" + pid + ".zlib")

    if (exists(dumpOnOOMPath)) {
        return dumpOnOOMPath.toString()
    }

    if (!exists(rawDumpOnOOMPath)) {
        return Option.None
    }

    let ret = compressFile(rawDumpOnOOMPath.toString(), dumpOnOOMPath.toString())
    deleteFile(rawDumpOnOOMPath)
    if (!ret) {
        metricx_warn("hm-metricx-cj error: compressFile failed in crash watcher.")
        return Option.None
    }
    return dumpOnOOMPath.toString()
}

private func getLogFileInfo(): String {
    let info = ArrayList<String>()
    let path = "/data/storage/el2/log/hiappevent/"
    if (exists(path)) {
        Directory.walk(
            path,
            {
                file =>
                    info.add(
                        "fileName: ${file.name}, createTime: ${file.creationTime.inLocal()}, size: ${(Float64(file.size) / 1024.0).format(".3")}KB")
                    true
            }
        )
    }
    info.toString()
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
    if (!exists(src)) {
        metricx_warn("hm-metricx-cj error: compressFile failed due to ${src} does not exist")
        return false
    }
    var count: Int64 = 0
    try {
        let srcFile: File = File(src, OpenMode.Read)
        let destFile: File = File(dest, OpenMode.Append)

        var tempBuf: Array<UInt8> = Array<UInt8>(1024, repeat: 0)
        var compressOutputStream: CompressOutputStream = CompressOutputStream(destFile, wrap: GzipFormat)
        while (true) {
            var readNum = srcFile.read(tempBuf)
            if (readNum > 0) {
                compressOutputStream.write(tempBuf
                    .slice(0, readNum)
                    .toArray())
                count += readNum
            } else {
                break
            }
        }
        compressOutputStream.flush()
        compressOutputStream.close()

        srcFile.close()
        destFile.close()
    } catch (e: Exception) {
        metricx_warn("hm-metricx-cj error: compressFile failed due to ${e.toString()}")
    }
    return count > 0
}

private func writeSystemLog2File(persistentSystemLogPath: String) {
    unsafe {
        let filePath = LibC.mallocCString(persistentSystemLogPath)
        if (writeSystemLog(filePath) != 0) {
            metricx_warn("hm-metricx-cj error: write system log file failed.")
        }
        LibC.free(filePath)
    }
}

private func persistMemoryData2File(persistentMemMapFileName: String, persistentMemMallocPath: String,
    parsedAddrPath: String, memPersistTimePath: String) {
    unsafe {
        let mapFilePath = LibC.mallocCString(persistentMemMapFileName)
        let memMallocPath = LibC.mallocCString(persistentMemMallocPath)
        let cParsedAddrPath = LibC.mallocCString(parsedAddrPath)
        let cMemPersistTimePath = LibC.mallocCString(memPersistTimePath)
        if (persistMemoryData(mapFilePath, memMallocPath, cParsedAddrPath, cMemPersistTimePath) != 0) {
            metricx_warn("write crash memMap file failed.")
        }
        LibC.free(mapFilePath)
        LibC.free(memMallocPath)
        LibC.free(cParsedAddrPath)
        LibC.free(cMemPersistTimePath)
    }
}

private func writeLastNHilog2File(persistentLastNHilogPath: String) {
    unsafe {
        let filePath = LibC.mallocCString(persistentLastNHilogPath)
        if (writeLastNHiLog(filePath) != 0) {
            metricx_warn("hm-metricx-cj error: write lastNHilog log file failed.")
        }
        LibC.free(filePath)
    }
}

private func initHilogWatcher() {
    unsafe {
        if (registerCrashSystemlogCallback() != 0) {
            metricx_warn("hm-metricx-cj error: registerCrashSystemlogCallback failed.")
        }
        if (registerCrashLastNHilogCallback() != 0) {
            metricx_warn("hm-metricx-cj error: registerCrashLastNHilogCallback failed.")
        }
    }
}

private func initNativeMemoryWatcher() {
    unsafe {
        if (installNativeMemoryMonitor() != 0) {
            metricx_warn("hm-metricx-cj error: registerNativeMemoryCallback failed.")
        }
    }
}

private func parseMallocLog(filePath: Path): List<MallocModel> {
    let mallocModels = ArrayList<MallocModel>()
    try {
        let reader = StringReader(File(filePath, OpenMode.Read))

        while (let Some(line) <- reader.readln()) {
            let strings = line
                //.trim() TODO
                .split(" ", removeEmpty: true)
            if (strings.size < 3) {
                metricx_info("parseMallocLog skiped line: " + line)
                continue
            }
            try {
                let size = Int64.parse(strings[0])
                let ptr = Int64.parse("0x" + strings[1])
                let stacks = strings[2].split(',', removeEmpty: true)
                let longStacks = Array<Int64>(stacks.size, {i => Int64.parse("0x" + stacks[i])})

                mallocModels.add(MallocModel(size, ptr, longStacks))
            } catch (e: Exception) {
                metricx_warn("hm-metricx-cj error: parseMallocLog skiped line: ${line},exception: ${e.toString()}")
            }
        }
        reader.close()
    } catch (e: Exception) {
        metricx_warn("hm-metricx-cj error: parse malloc log failed: " + e.toString())
    }
    mallocModels
}

private func parseStackFrame(persistentPaths: PersistentPaths, shouldBeClusteredToThisSo: (soName: String) -> Bool): String {
    let parsedMap: String = parseMaps(persistentPaths.memMapPath, Int32.Max)
    let mallocModels = parseMallocLog(persistentPaths.memMallocPath)
    if (mallocModels.isEmpty()) {
        return ""
    }
    let stacks = getParsedStacks(persistentPaths.parsedAddrPath)
    let soMemory = getSoMemory(mallocModels, stacks, shouldBeClusteredToThisSo)
    let mallocStacks = parseMallocWithStack(mallocModels, stacks)
    soMemory + mallocStacks + parsedMap
}

private func getParsedStacks(parsedPath: Path): HashMap<Int64, ParsedAddr> {
    let map = HashMap<Int64, ParsedAddr>()
    try {
        let reader = StringReader(File(parsedPath, OpenMode.Read))
        while (let Some(line) <- reader.readln()) {
            try {
                let arr = line.split(" ", removeEmpty: true)
                let pc = arr[0]
                let pcInt = Int64.parse("0x" + pc)
                let parsedAddr = line.removePrefix(pc)
                //.trim() TODO
                let soName = arr[2]
                map.add(pcInt, ParsedAddr(pcInt, parsedAddr, soName))
            } catch (e: Exception) {
                metricx_warn("getParsedStacks skip line: " + line)
            }
        }
        reader.close()
    } catch (e: Exception) {
        metricx_warn("getParsedStacks failed: " + e.toString())
    }
    map
}

private func getSoMemory(mallocModels: List<MallocModel>, stackMap: HashMap<Int64, ParsedAddr>,
    shouldBeClusteredToThisSo: (soName: String) -> Bool): String {
    let soMemoryMap = HashMap<String, Int64>()
    for (mallocModel in mallocModels) {
        let so = findSo(mallocModel, stackMap, shouldBeClusteredToThisSo)
        let sum = (soMemoryMap.get(so) ?? 0) + mallocModel.size
        soMemoryMap.add(so, sum)
    }
    let by: ((String, Int64), (String, Int64)) -> Ordering = {
        a, b =>
            if (a[1] < b[1]) {
                return Ordering.GT
            } else if (a[1] > b[1]) {
                return Ordering.LT
            }
            return Ordering.EQ
    }
    let soMemoryArr = soMemoryMap.toArray()
    sort(soMemoryArr, by: by, stable: true)

    let stringBuilder = StringBuilder()
    var total: Int64 = 0
    stringBuilder.append("Malloc Group By So(kB):\n")
    for ((so, size) in soMemoryArr) {
        stringBuilder.append("${so}: ${size / 1024}\n")
        total += size / 1024
    }
    stringBuilder.append("Total: ${total} kB \n")
    stringBuilder.toString()
}

private func findSo(mallocModel: MallocModel, stackMap: HashMap<Int64, ParsedAddr>,
    shouldBeClusteredToThisSo: (soName: String) -> Bool): String {
    let soList = ArrayList<String>()
    let stacks = mallocModel
        .stack
        .clone()
    sort(stacks)
    for (pc in stacks) {
        if (let Some(parsedAddr) <- stackMap.get(pc)) {
            if (let Some(last) <- soList.last && last == parsedAddr.soName) {
                continue
            }
            soList.add(parsedAddr.soName)
        }
    }

    var so: String = "<unknown>"
    for (soName in soList) {
        if (shouldBeClusteredToThisSo(soName)) {
            return soName
        }
        if (so == "<unknown>") {
            so = soName
        }
        if (let Some(v) <- PRIORITY_HIGH.indexOf(so) && let Some(p) <- PRIORITY_HIGH.indexOf(soName)) {
            if (v > p) {
                so = soName
            }
        } else if (PRIORITY_HIGH.contains(soName)) {
            so = soName
        } else if (!PRIORITY_HIGH.contains(so)) {
            so = soName
        }
    }
    so
}

private func parseMallocWithStack(mallocModels: List<MallocModel>, stacks: HashMap<Int64, ParsedAddr>): String {
    let mallocStacks = ArrayList<MallocStack>()
    for (mallocModel in mallocModels) {
        let stack = findStack(mallocModel.stack, stacks)
        mallocStacks.add(MallocStack(stack, mallocModel.size / 1024))
    }
    let by: (MallocStack, MallocStack) -> Ordering = {
        a, b =>
            if (a.size < b.size) {
                return Ordering.GT
            } else if (a.size > b.size) {
                return Ordering.LT
            }
            return Ordering.EQ
    }
    sort(mallocStacks, by: by)
    let stringBuilder = StringBuilder("\nMalloc Stack:\n")
    var index = 0

    for (mallocStack in mallocStacks) {
        stringBuilder.append("malloc ${index + 1}: ${mallocStack.size}kB\n")
        stringBuilder.append(mallocStack.stack)
        stringBuilder.append("\n")
        index++
    }
    stringBuilder.toString()
}

private func findStack(stack: Array<Int64>, stackMap: HashMap<Int64, ParsedAddr>): String {
    let stringBuilder = StringBuilder()
    for (pc in stack) {
        if (pc <= 0) {
            continue
        }
        var find: Bool = false
        if (let Some(parsedPc) <- stackMap.get(pc)) {
            stringBuilder.append(parsedPc.parsedAddr + "\n")
            find = true
        }
        if (!find) {
            stringBuilder.append("unknown \n")
        }
    }
    stringBuilder.toString()
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
            let segments = line
                //.trim() TODO
                .split(" ", removeEmpty: true)
            if (segments.size < 5) {
                metricx_info("parse memMap skiped line: " + line)
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
                let start = Int64.parse("0x" + zoneItem[0])
                let end = Int64.parse("0x" + zoneItem[1])
                let curSize = end - start

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
                metricx_info("parse memMap skiped line: ${line}, exception: ${e.toString()}")
            }
        }
        reader.close()
    } catch (e: Exception) {
        metricx_warn("parse memMap failed: " + e.toString())
    }

    // 统计Summarry和Details数据
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
    stringBuilder.append("Memory Map:\n")
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
    pMemMallocPath: CString, parsedAddrPath: CString, memPersistTimePath: CString, persistentLastNHilogPath: CString,
    lastNHilogNumber: Int64, systemLogNumber: Int64,
    cb: CFunc<(CString, CString, CFunc<() -> CString>, CString, CString, CString, CString) -> Unit>): Int8

foreign func InitOOMHandler(targetFile: CString): Int8

foreign func writeSystemLog(persistentFilePath: CString): Int8

foreign func writeLastNHiLog(persistentFilePath: CString): Int8

foreign func registerCrashSystemlogCallback(): Int8

foreign func registerCrashLastNHilogCallback(): Int8

foreign func registerCrashHilogCallback(): Int8

foreign func IsOOMDumping(): Bool

foreign func GetDumpTime(): DumpTime

foreign func persistMemoryData(mapPath: CString, memMallocPath: CString, parsedAddrPath: CString,
    memPersistTimePath: CString): Int8

foreign func installNativeMemoryMonitor(): Int8
