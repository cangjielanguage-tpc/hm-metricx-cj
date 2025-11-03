/**
 * Created on 2025/3/28
 */
package ohos_app_cangjie_hm_metricx_cj.crash

import ohos_app_cangjie_hm_metricx_cj.util.*
import std.fs.*
import std.collection.*
import std.convert.*
import std.time.*
import std.sync.*
import std.convert.*
import std.sort.*
import ohos.ark_interop_macro.*
import ohos.ark_interop.*
import ohos_app_cangjie_hm_metricx_cj.util.zlib.*

public class CrashInfo {
    public var language: ?String = None
    public var meminfo: ?String = None
    public var timestamp: ?String = None
    public var pid: ?String = None
    public var pname: ?String = None
    public var stacktrace: ?String = None
    public var hilog: ?String = None
    public var tid: ?String = None
    public var tname: ?String = None
    public var fds: ?HashMap<String, String> = None
    public var limits: ?String = None
    public var threads: ?String = None
    public var extraInfo: ?String = None
    public var crashLogPath: ?String = None
    public var dumpOnOOMPath: ?String = None
    public var appVersion: ?String = None
    public var rawFile: ?String = None
    public var systemLog: ?String = None
    public var lastNHilog: ?String = None
    public var dumpTime: ?String = None
    public var historyRawFiles: ?String = None
    public var nativeMemDetail: ?String = None
    public var memPersistTime: ?String = None

    func toInteropCrashInfo(): InteropCrashInfo {
        let crashInfo = InteropCrashInfo()
        crashInfo.language = language
        crashInfo.meminfo = meminfo
        crashInfo.timestamp = timestamp
        crashInfo.pid = pid
        crashInfo.pname = pname
        crashInfo.stacktrace = stacktrace
        crashInfo.hilog = hilog
        crashInfo.tid = tid
        crashInfo.tname = tname
        if (let Some(v) <- fds) {
            // crashInfo.fds = JSHashMapEx<String, String>(v)
            crashInfo.fds = map2String(v)
        }
        crashInfo.limits = limits
        crashInfo.threads = threads
        crashInfo.extraInfo = extraInfo
        crashInfo.crashLogPath = crashLogPath
        crashInfo.dumpOnOOMPath = dumpOnOOMPath
        crashInfo.appVersion = appVersion
        crashInfo.rawFile = rawFile
        crashInfo.systemLog = systemLog
        crashInfo.lastNHilog = lastNHilog
        crashInfo.dumpTime = dumpTime
        crashInfo.historyRawFiles = historyRawFiles
        crashInfo.nativeMemDetail = nativeMemDetail
        crashInfo.memPersistTime = memPersistTime
        crashInfo
    }

    func toString(): String {
        var res = ""
        res += "language:\n"
        if (let Some(v) <- language) {
            res += "${v}\n"
        }
        res += "meminfo:\n"
        if (let Some(v) <- meminfo) {
            res += "${v}\n"
        }
        res += "timestamp:\n"
        if (let Some(v) <- timestamp) {
            res += "${v}\n"
        }
        res += "pid:\n"
        if (let Some(v) <- pid) {
            res += "${v}\n"
        }
        res += "pname:\n"
        if (let Some(v) <- pname) {
            res += "${v}\n"
        }
        res += "stacktrace:\n"
        if (let Some(v) <- stacktrace) {
            res += "${v}\n"
        }
        res += "hilog:\n"
        if (let Some(v) <- hilog) {
            res += "${v}\n"
        }
        res += "tid:\n"
        if (let Some(v) <- tid) {
            res += "${v}\n"
        }
        res += "tname:\n"
        if (let Some(v) <- tname) {
            res += "${v}\n"
        }
        res += "fds:\n"
        if (let Some(v) <- fds) {
            for (entry in v) {
                res += "${entry[0]}#${entry[1]}\n"
            }
        }
        res += "limits:\n"
        if (let Some(v) <- limits) {
            res += "${v}\n"
        }
        res += "threads:\n"
        if (let Some(v) <- threads) {
            res += "${v}\n"
        }
        res += "extraInfo:\n"
        if (let Some(v) <- extraInfo) {
            res += "${v}\n"
        }
        res += "crashLogPath:\n"
        if (let Some(v) <- crashLogPath) {
            res += "${v}\n"
        }
        res += "dumpOnOOMPath:\n"
        if (let Some(v) <- dumpOnOOMPath) {
            res += "${v}\n"
        }
        res += "appVersion:\n"
        if (let Some(v) <- appVersion) {
            res += "${v}\n"
        }
        res += "rawFile:\n"
        if (let Some(v) <- rawFile) {
            res += "${v}\n"
        }
        res += "systemLog:\n"
        if (let Some(v) <- systemLog) {
            res += "${v}\n"
        }
        res += "lastNHilog:\n"
        if (let Some(v) <- lastNHilog) {
            res += "${v}\n"
        }
        res += "dumpTime:\n"
        if (let Some(v) <- dumpTime) {
            res += "${v}\n"
        }
        res += "historyRawFiles:\n"
        if (let Some(v) <- historyRawFiles) {
            res += "${v}\n"
        }
        res += "nativeMemDetail:\n"
        if (let Some(v) <- nativeMemDetail) {
            res += "${v}\n"
        }
        res += "memPersistTime:\n"
        if (let Some(v) <- memPersistTime) {
            res += "${v}\n"
        }
        res
    }

    static func fromString(str: String): CrashInfo {
        let crashInfo = CrashInfo()
        let lines = str.split("\n", removeEmpty: true)
        let info = ArrayList<String>()
        let collect = {
            =>
                let res = reduce({acc, cur => "${cur}\n${acc}"})(info)
                info.clear()
                res
        }
        for (line in lines) {
            if (line == "language:") {
            } else if (line == "meminfo:") {
                crashInfo.language = collect()
            } else if (line == "timestamp:") {
                crashInfo.meminfo = collect()
            } else if (line == "pid:") {
                crashInfo.timestamp = collect()
            } else if (line == "pname:") {
                crashInfo.pid = collect()
            } else if (line == "stacktrace:") {
                crashInfo.pname = collect()
            } else if (line == "hilog:") {
                crashInfo.stacktrace = collect()
            } else if (line == "tid:") {
                crashInfo.hilog = collect()
            } else if (line == "tname:") {
                crashInfo.tid = collect()
            } else if (line == "fds:") {
                crashInfo.tname = collect()
            } else if (line == "limits:") {
                if (info.size != 0) {
                    let fds = HashMap<String, String>()
                    for (entry in info) {
                        let arr = entry.split("#")
                        if (arr.size == 2) {
                            fds.add(arr[0], arr[1])
                        } else {
                            metricx_warn("invalid fd: ${arr.toString()}")
                        }
                    }
                    crashInfo.fds = fds
                    info.clear()
                }
            } else if (line == "threads:") {
                crashInfo.limits = collect()
            } else if (line == "extraInfo:") {
                crashInfo.threads = collect()
            } else if (line == "crashLogPath:") {
                crashInfo.extraInfo = collect()
            } else if (line == "dumpOnOOMPath:") {
                crashInfo.crashLogPath = collect()
            } else if (line == "appVersion:") {
                crashInfo.dumpOnOOMPath = collect()
            } else if (line == "rawFile:") {
                crashInfo.appVersion = collect()
            } else if (line == "systemLog:") {
                crashInfo.rawFile = collect()
            } else if (line == "lastNHilog:") {
                crashInfo.systemLog = collect()
            } else if (line == "dumpTime:") {
                crashInfo.lastNHilog = collect()
            } else if (line == "historyRawFiles:") {
                crashInfo.dumpTime = collect()
            } else if (line == "nativeMemDetail:") {
                crashInfo.historyRawFiles = collect()
            } else if (line == "memPersistTime:") {
                crashInfo.nativeMemDetail = collect()
            } else {
                info.add(line)
            }
        }
        crashInfo.memPersistTime = collect()
        crashInfo
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
    //    public var fds: Option<JSHashMapEx<String, String>> = None TODO cannot use JSHashMapEx due to known bug in ark_interop lib
    public var fds: Option<String> = None
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
    let crashFilePath: Path
    let systemLogPath: Path
    let memMapPath: Path
    let memMallocPath: Path
    let parsedAddrPath: Path
    let lastNHilogPath: Path
    let dumpTimePath: Path
    let memPersistTimePath: Path

    public init(persistentDir: Path) {
        this.dir = persistentDir
        this.lastCrashFilePath = persistentDir.join("lastCrash.txt")
        this.crashFilePath = persistentDir.join("crash.txt")
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
    spawn {
        => reportLastCrash(persistentPaths, reportCrashInfo)
    }
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
            let crashInfo = CrashInfo.fromString(readFile(persistentPaths.lastCrashFilePath))
            deleteFile(persistentPaths.lastCrashFilePath)
            crashInfo.dumpTime = readFile(persistentPaths.dumpTimePath)
            deleteFile(persistentPaths.dumpTimePath)
            if (let Some(pid) <- crashInfo.pid) {
                crashInfo.dumpOnOOMPath = compressOOMFile(pid, persistentPaths.dir)
            }
            reportCrashInfo(crashInfo.toInteropCrashInfo())
            reported = true
        } catch (e: Exception) {
            metricx_warn("hm-metricx-cj error: " + e.toString())
        }
    }
}

private func initOOMHandler(persistentDir: String) {
    unsafe {
        let targetFile = LibC.mallocCString(persistentDir + "/cj_OOM_pid" + PID.toString() + ".dat")
        let dumpDir = LibC.mallocCString(persistentDir)
        if (InitOOMHandler(targetFile) != 0) {
            metricx_warn("hm-metricx-cj error: InitOOMHandler failed.")
        } else {
            OOMHandlerInited = true
        }
        LibC.free(targetFile)
        LibC.free(dumpDir)
    }
}

private func initNativeSignalHandler(limits: String, collectCrashInfo: CFunc<() -> CString>,
    persistentPaths: PersistentPaths, lastNHilogNumber: Int64, systemLogNumber: Int64) {
    unsafe {
        let cstr = LibC.mallocCString(persistentPaths
            .crashFilePath
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
            writeFile(persistentPaths.crashFilePath, crashInfo.toString())
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
                        fds.add(file.name, realPath.toString())
                    } else {
                        fds.add(file.name, "unknown")
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
        time: String, crashPid: String, exception: String, hilog: String, external_log: String, crash_type: String, 
            bundle_version: String => try {
            var crashInfo = CrashInfo()
            if (exists(persistentPaths.crashFilePath)) {
                crashInfo = CrashInfo.fromString(readFile(persistentPaths.crashFilePath))
                deleteFile(persistentPaths.crashFilePath)
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
            crashInfo.pid = crashPid
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
            if (PID.toString() == crashPid) {
                let shouldIgnore = crashInfo.language == "cpp_crash" && unsafe { IsSigCaught() }
                if (shouldIgnore) {
                    unsafe {
                        ResetSigCaught()
                    }
                    return
                }
                writeFile(persistentPaths.lastCrashFilePath, crashInfo.toString())
            } else {
                if (!reported) {
                    let info: CrashInfo = crashInfo
                    spawn {
                        =>
                            if (let Some(pid) <- info.pid) {
                                info.dumpOnOOMPath = compressOOMFile(pid, persistentPaths.dir)
                            }
                            // onReceive callback sometimes will be invoked both before app crash and next launch on high-verion (API 18?) devcies
                            reportCrashInfo(info.toInteropCrashInfo())
                    }
                }
            }
        } catch (e: Exception) {
            metricx_warn("hm-metricx-cj error: initCrashWatcher error: " + e.toString())
        } catch (e: OutOfMemoryError) {
            AppLog.warn("hm-metricx-cj error: initCrashWatcher error, " + e.toString())
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
        var compressOutputStream: CompressOutputStream = CompressOutputStream(destFile)
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
    count > 0
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
    let lines = readFile(filePath).split("\n", removeEmpty: true)
    for (line in lines) {
        let strings = line.split(" ", removeEmpty: true)
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
    let lines = readFile(parsedPath).split("\n", removeEmpty: true)
    for (line in lines) {
        try {
            let arr = line.split(" ", removeEmpty: true)
            let pc = arr[0]
            let pcInt = Int64.parse("0x" + pc)
            let parsedAddr = line.removePrefix(pc)
            let soName = arr[2]
            map.add(pcInt, ParsedAddr(pcInt, parsedAddr, soName))
        } catch (e: Exception) {
            metricx_warn("getParsedStacks skip line: " + line)
        }
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

    let lines = readFile(filePath).split("\n", removeEmpty: true)
    for (line in lines) {
        let segments = line.split(" ", removeEmpty: true)
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

foreign func IsSigCaught(): Bool

foreign func ResetSigCaught(): Unit
