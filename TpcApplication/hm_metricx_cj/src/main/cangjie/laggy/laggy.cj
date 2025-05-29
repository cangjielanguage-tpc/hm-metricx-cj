/**
 * Created on 2025/5/24
 */
package ohos_app_cangjie_hm_metricx_cj.laggy

import tpc.UIKit.UIContext.*
import tpc.AbilityKit.ApplicationContext
import tpc.AbilityKit.ApplicationContextType
import tpc.AbilityKit.AbilityLifecycleCallback
import tpc.UIKit.arkui_node.{FrameNode, ComponentContent}
import tpc.UIKit.Observer.*
import tpc.UIKit.component_interop.*
import tpc.ArkGraphics2D.displaySync.*
import tpc.UIKit.window
import tpc.AbilityKit.UIAbility
import std.collection.*
import encoding.json.*
import ohos.ark_interop.JSObject
import ohos.ark_interop.JSString
import ohos_app_cangjie_hm_metricx_cj.*
import ohos.window.WindowStage
import ohos.ability.Ability
import ohos.base.Callback1Argument

var laggyMap = HashMap<String, PageResponseLaggyModel>()
var eventMap = HashMap<Float64, ResponseEvent>()
var uploadLaggyinfo: (JsonObject) -> Unit = { info: JsonObject => () }
var timeBegain: Float64 = 0.0
var currentPageName = "mainPage"
var isFirstCallBack = true
var isComplite = false
var maxResponsesTime = 0.0
var maxSize = 0

public class ResponseEvent{
    var pageName = ""
    var technologyStack = "Native"
    var responseTime = 0.0
    var descriptionID = ""
    var nodeType = ""
    var viewTouchID = ""
    var touchX = 0.0
    var touchY = 0.0
    var hitX = 0.0
    var hitY = 0.0
    var hitWidth = 0.0
    var hitHeight = 0.0

    public func ToJsonValue() {
        var info = HashMap<String, String>()
        info.put("pageName", pageName)
        info.put("technologyStack", technologyStack)
        info.put("responseTime", responseTime.toString())
        info.put("descriptionID", descriptionID)
        info.put("nodeType", nodeType)
        info.put("viewTouchID", viewTouchID)
        info.put("touchX", touchX.toString())
        info.put("touchY", touchY.toString())
        info.put("hitX", hitX.toString())
        info.put("hitY", hitY.toString())
        info.put("hitWidth", hitWidth.toString())
        info.put("hitHeight", hitHeight.toString())
        var jsObj = JsonObject()
        jsObj.put("ResponseEvent", map2json(info))
        jsObj
    }
}

public class PageResponseLaggyModel {
    var pageName = ""
    // 触摸次数
    var touchTimes = 0
    // 卡顿次数
    var laggyTimes = 0
    // 卡顿时间集合
    var laggyTimeList = ArrayList<Float64>()

    public func ToJsonValue() {
        var info = HashMap<String, String>()
        info.put("pageName", pageName)
        info.put("touchTimes", touchTimes.toString())
        info.put("laggyTimes", laggyTimes.toString())
        info.put("laggyTimeList", laggyTimeList.toString())
        var jsObj = JsonObject()
        jsObj.put("PageResponseLaggyModel", map2json(info))
        jsObj
    }
}

public func syncCallBack(info: IntervalInfo)
{
    if (isFirstCallBack) {
        isFirstCallBack = false
        return
    }
    var timeEnd = Float64(info.timestamp)
    var sync = create()
    sync.off(OnOffType.DS_FRAME)
    var event = eventMap[timeBegain]
    if (timeEnd - timeBegain > maxResponsesTime) {
        var jsObj = event.ToJsonValue()
        uploadLaggyinfo(jsObj)
        if (laggyMap.contains(currentPageName)) {
            var model = laggyMap[currentPageName]
            model.laggyTimes += 1
            model.laggyTimeList.append(timeEnd - timeBegain)
            if (model.laggyTimeList.size > maxSize) {
                model.laggyTimeList.remove(0)
            }
            isComplite = true
        }
    }
    isFirstCallBack = true
}

public func didClickCallBack(event: ClickEventEnhanced, node: ?FrameNode)
{
    if (isComplite) {
        isComplite = false
    }
    var response = ResponseEvent()
    var t_begain = event.timestamp
    timeBegain = t_begain
    response.pageName = currentPageName
    response.touchX = event.windowX ?? 0.0
    response.touchY = event.windowY ?? 0.0
    try {
        let frameNode = node.getOrThrow()
        response.viewTouchID = frameNode.getId()
        response.nodeType = frameNode.getNodeType()
        var pos = frameNode.getPositionToWindow()
        var measureSize = frameNode.getMeasuredSize()
        // waiting bugfix
        //response.descriptionID = frameNode.getInspectorInfo()
        response.hitX = pos.x
        response.hitY = pos.y
        response.hitHeight = measureSize.height
        response.hitWidth = measureSize.width
    } catch (e: NoneValueException) {
        println(e.toString())
    }
}

public func navDestinationSwitchCallBack(info:NavDestinationSwitchInfo)
{
    var name = ""
    match (info.to) {
        case NavigationInfo =>
            try {
                name = (((info.to as NavDestinationInfo).getOrThrow()).name as String).getOrThrow()
            } catch (e: NoneValueException) {
                println(e.toString())
            }
        case  NavBar => name = "navRoot"
    }
    if (laggyMap.contains(currentPageName)) {
        var res = laggyMap[currentPageName]
        uploadLaggyinfo(res.ToJsonValue())
        laggyMap.remove(currentPageName)
        return
    }
    if (!name.isEmpty()) {
        var res = PageResponseLaggyModel()
        res.pageName = name
        currentPageName = name
        laggyMap.put(name, res)
    }
}

public func onAbilityBackgroundCallBack(ability: UIAbility)
{
    if (laggyMap.contains(currentPageName)) {
        var res = laggyMap[currentPageName]
        uploadLaggyinfo(res.ToJsonValue())
        laggyMap.remove(currentPageName)
    }
}

let abilityLifecycleCallback: AbilityLifecycleCallback = AbilityLifecycleCallback(
    onAbilityCreate: { ability: UIAbility => () },
    onWindowStageCreate: { abilty: UIAbility, windowStage: window.WindowStage => () },
    onWindowStageActive: { abilty: UIAbility, windowStage: window.WindowStage => () },
    onWindowStageInactive: { abilty: UIAbility, windowStage: window.WindowStage => () },
    onWindowStageDestroy: { abilty: UIAbility, windowStage: window.WindowStage => () },
    onAbilityDestroy: { abilityUIability => () },
    onAbilityForeground: { ability: UIAbility => () },
    onAbilityBackground: onAbilityBackgroundCallBack,
    onAbilityContinue: { abilityUIability => () },
    onWindowStageRestore: { abilty: UIAbility, windowStage: window.WindowStage => () }
)

public func initLaggyHandle(applicationcontext: ApplicationContext, uiContext: UIContext,
                            maxTime: Float64, maxArraySize: Int64, reportLaggyInfo: (data: JsonObject) -> Unit)
{
    uploadLaggyinfo = reportLaggyInfo
    maxSize = maxArraySize
    maxResponsesTime = maxTime
    uiContext.getUIObserver().on(ObserverListenerType.navDestinationSwitch,
                                NavDestinationSwitchCallBack(navDestinationSwitchCallBack))
    uiContext.getUIObserver().on(ObserverListenerType.didClick, DidClickCallBack(didClickCallBack))
    applicationcontext.on(ApplicationContextType.ABILITY_LIFECYCLE, abilityLifecycleCallback)
    0
}

// 回调函数warper
public class DidClickCallBack <: ClickEventListenerCallback<ClickEventEnhanced, ?FrameNode> {
    let elementInfoCallBack: (event: ClickEventEnhanced, node: ?FrameNode) -> Unit
    public init(elementInfoCallBack: (event: ClickEventEnhanced, node: ?FrameNode) -> Unit) {
        this.elementInfoCallBack = elementInfoCallBack
    }
    public func invoke(event: ClickEventEnhanced, node: ?FrameNode): Unit {
        this.elementInfoCallBack(event, node)
    }
}

public class NavDestinationSwitchCallBack <: Callback1Argument<NavDestinationSwitchInfo> {
    let elementInfoCallBack: (NavDestinationSwitchInfo) -> Unit
    public init(elementInfoCallBack: (NavDestinationSwitchInfo) -> Unit) {
        this.elementInfoCallBack = elementInfoCallBack
    }
    public func invoke(info: NavDestinationSwitchInfo): Unit {
        this.elementInfoCallBack(info)
    }
}

public class DisplaySyncCallBack <: Callback1Argument<IntervalInfo> {
    let elementInfoCallBack: (IntervalInfo) -> Unit
    public init(elementInfoCallBack: (IntervalInfo) -> Unit) {
        this.elementInfoCallBack = elementInfoCallBack
    }
    public func invoke(info: IntervalInfo): Unit {
        this.elementInfoCallBack(info)
    }
}