/**
 * Created on 2025/4/7
 */
package ohos_app_cangjie_hm_metricx_cj

import std.unicode.UnicodeStringExtension
import std.collection.*
import std.fs.*
import std.regex.Regex
import std.time.*
import stdx.encoding.json.*

import tpc.UIKit.Observer.*
import tpc.BasicServicesKit.*

public func map2json(input: HashMap<String, String>) {
    let map = HashMap<String, JsonValue>()
    input.iterator().forEach({entry => map.add(entry[0], JsonString(entry[1]))})
    JsonObject(map)
}

public func json2map(input: HashMap<String, JsonValue>) {
    let map = HashMap<String, String>()
    input.iterator().forEach({entry => map.add(entry[0], JsonValueToString(entry[1]))})
    map
}

public class PageSwitchCallBack <: Callback1Argument<NavDestinationSwitchInfo> {
    let elementInfoCallback: (NavDestinationSwitchInfo) -> Unit
    public init(elementInfoCallback: (NavDestinationSwitchInfo) -> Unit) {
        this.elementInfoCallback = elementInfoCallback
    }
    public func invoke(res: NavDestinationSwitchInfo): Unit {
        this.elementInfoCallback(res)
    }
}

public func getTargetPageName(info: NavDestinationSwitchInfo, defaultName!: String = "") {
    var name = defaultName
    match (info.to) {
        case to: NavDestinationInfo =>
            try {
                name = (to.name as String).getOrThrow()
            } catch (e: Exception) {
                AppLog.warn(e.toString())
            }
        case to: NavBar => name = "navRoot"
        case _ => throw Exception("")
    }
    name
}

public func deleteFile(path: String) {
    if (!exists(path)) {
        return
    }
    try {
        remove(path)
    } catch (e: FSException) {
        AppLog.warn(e.toString())
    }
}

public func deleteFile(path: Path) {
    if (!exists(path)) {
        return
    }
    try {
        remove(path)
    } catch (e: FSException) {
        AppLog.warn(e.toString())
    }
}

public func renameFile(sourceFile: Path, targetFile: Path) {
    try {
        if (exists(sourceFile)) {
            rename(sourceFile, to: targetFile, overwrite: true)
        }
    } catch (e: Exception) {
        AppLog.warn(e.toString())
    }
}

public const defaultPageName = "mainPage"

public func hilogWordWrap(str: String) {
    let rule = ##"(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3} )(.*?)(?=\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3} |$)"##
    let arr = Regex(rule).findAll(str)
    if (arr.size == 0) {
        return str
    }
    var res: String = ""
    for (md in arr) {
        let cur = md.matchString().trim().removeSuffix(",")
        res = res + cur + "\n"
    }
    return res
}

public func JsonValueToString(value: JsonValue): String {
    return value.asString().getValue()
}

let ESCAPE_MAP: HashMap<String, String> = HashMap<String, String>([("\\n", "\n"), ("\\t", "\t")])
public func unescapeString(str: String): String {
    var res: String = str
    for (escape in ESCAPE_MAP) {
        res = res.replace(escape[0], escape[1])
    }
    res
}

public func getCurTimeStamp(): String {
    DateTime.now().format("yyyy-MM-dd HH:mm:ss")
}

public func getTodayDate(): String {
    DateTime.now().format("yyyy-MM-dd")
}