/**
 * Created on 2025/4/7
 */
package ohos_app_cangjie_hm_metricx_cj

import std.collection.*
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
    input.iterator().forEach({entry => map.add(entry[0], entry[1].toString())})
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
        case NavigationInfo =>
            try {
                name = (((info.to as NavDestinationInfo).getOrThrow()).name as String).getOrThrow()
            } catch (e: Exception) {
                AppLog.warn(e.toString())
            }
        case  NavBar => name = "navRoot"
    }
    name
}

public const defaultPageName = "mainPage"