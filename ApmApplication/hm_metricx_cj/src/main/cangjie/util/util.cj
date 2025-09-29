/**
 * Created on 2025/9/18
 */
package ohos_app_cangjie_hm_metricx_cj.util

import std.fs.*
import std.time.*
import ohos.ark_interop_macro.*
import ohos.ark_interop.*

public const defaultPageName = "mainPage"
public let PID = unsafe { GetPid() }

public func getCurTimeStamp(): String {
    DateTime
        .now()
        .format("yyyy-MM-dd HH:mm:ss")
}

public func getTodayDate(): String {
    DateTime
        .now()
        .format("yyyy-MM-dd")
}

public func formatWithCommasAndPadding(num: Int64, width: Int64): String {
    let numStr = num
        .toString()
        .toRuneArray()
    let len = numStr.size
    let withCommas = StringBuilder()
    for (i in 0..len) {
        if ((len - i) % 3 == 0 && i != 0) {
            withCommas.append(",")
        }
        withCommas.append(numStr[i])
    }
    var result = withCommas.toString()
    if (result.size < width) {
        let paddingWidth = width - result.size
        let padded = StringBuilder()
        for (i in 0..paddingWidth) {
            padded.append(' ')
        }
        result = padded.toString() + result
    }
    return result
}

public func deleteFile(path: String) {
    if (!exists(path)) {
        return
    }
    try {
        remove(path)
    } catch (e: FSException) {
        metricx_warn(e.toString())
    }
}

public func readFile(path: Path, isReturnException!: Bool = false) {
    if (!exists(path)) {
        if (isReturnException) {
            return "hm-metricx-cj error: read file path ${path} does not exist"
        } else {
            return ""
        }
    }
    let content = File.readFrom(path)
    try {
        unsafe { return String.fromUtf8Unchecked(File.readFrom(path)) }
    } catch (e: Exception) {
        metricx_warn(
            "hm-metricx-cj error: reading ${path} failed due to error occured in fromUtf8Unchecked: ${e.toString()}")
        if (isReturnException) {
            return "hm-metricx-cj error: reading ${path} failed: ${e.toString()} content：" + content.toString()
        }
    }
    ""
}

public func deleteFile(path: Path) {
    if (!exists(path)) {
        return
    }
    try {
        remove(path)
    } catch (e: FSException) {
        metricx_warn(e.toString())
    }
}

public func renameFile(sourceFile: Path, targetFile: Path) {
    try {
        if (exists(sourceFile)) {
            rename(sourceFile, to: targetFile, overwrite: true)
        }
    } catch (e: Exception) {
        metricx_warn(e.toString())
    }
}

public func collectAndCleanHistoryLogFiles(): String {
    var historyFiles = ""
    let logPath = Path("/data/storage/el2/log/hiappevent/")
    if (!exists(logPath)) {
        return historyFiles
    }
    let fileList = Directory.readFrom(logPath)
    for (file in fileList) {
        if (exists(file.path)) {
            historyFiles += "fileName: ${file.name}\n" + readFile(file.path) + "\n"
            deleteFile(file.path)
        }
    }
    historyFiles
}

public func cleanHistoryLogFiles(keepLatest!: Bool = true): Unit {
    let logPath = Path("/data/storage/el2/log/hiappevent/")
    if (!exists(logPath)) {
        return
    }
    let fileList = Directory.readFrom(logPath)
    let size = fileList.size
    var cnt = 0
    for (file in fileList) {
        cnt++
        if (cnt == size && keepLatest) {
            break
        }
        if (exists(file.path)) {
            deleteFile(file.path)
        }
    }
}

@Interop[ArkTS]
public interface DisplaySyncInterface {
    func start(): Unit
    func stop(): Unit
    func on(cb: (Int64, Int64) -> Unit): Unit
    func off(): Unit
}

public class JSHelper {
    static let ctx: JSContext
    static init() {
        JSModule.registerModule({
            context, export => ctx = context
        })
    }
    public static func postJSTask(callback: () -> Unit): Unit {
        ctx.postJSTask(callback)
    }
}

foreign func GetPid(): Int64
