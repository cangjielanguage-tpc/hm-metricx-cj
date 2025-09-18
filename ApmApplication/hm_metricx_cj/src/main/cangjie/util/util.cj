/**
 * Created on 2025/9/18
 */
package ohos_app_cangjie_hm_metricx_cj.util
import std.time.DateTime

public const defaultPageName = "mainPage"

public func getCurTimeStamp(): String {
    DateTime.now().format("yyyy-MM-dd HH:mm:ss")
}

public func getTodayDate(): String {
    DateTime.now().format("yyyy-MM-dd")
}