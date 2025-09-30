/**
 * Created on 2025/9/20
 */
package ohos_app_cangjie_hm_metricx_cj.laggy

import ohos_app_cangjie_hm_metricx_cj.util.*
import std.collection.*
import ohos.ark_interop_macro.*
import ohos.ark_interop.*

var laggyMap = HashMap<String, PageResponseLaggyModel>()
var eventMap = HashMap<Float64, ResponseEvent>()
var _reportResponseEvent: (ResponseEvent) -> Unit = {info =>}
var _reportPageResponseLaggyModel: (InteropPageResponseLaggyModel) -> Unit = {info =>}
var timeBegain: Float64 = 0.0
var currentPageName = defaultPageName
var isFirstCallBack = true
var isComplite = false
var maxResponsesTime = 0
var maxSize = 0
var _displySyncInterface: Option<DisplaySyncInterface> = None

@Interop[ArkTS]
public class ResponseEvent {
    public var pageName: String = ""
    public var technologyStack: String = "Native"
    public var responseTime: Int64 = 0
    public var descriptionID: String = ""
    public var nodeType: String = ""
    public var viewTouchID: String = ""
    public var touchX: Float64 = 0.0
    public var touchY: Float64 = 0.0
    public var hitX: Float64 = 0.0
    public var hitY: Float64 = 0.0
    public var hitWidth: Float64 = 0.0
    public var hitHeight: Float64 = 0.0

    public init() {}
}

@Interop[ArkTS]
public class InteropPageResponseLaggyModel {
    public var pageName: String = ""
    // 触摸次数
    public var touchTimes: Int64 = 0
    // 卡顿次数
    public var laggyTimes: Int64 = 0
    // 卡顿时间集合
    public var laggyTimeList: JSArrayEx<Float64> = JSArrayEx<Float64>()
    public init() {}
}

public class PageResponseLaggyModel {
    var pageName = ""
    // 触摸次数
    var touchTimes = 0
    // 卡顿次数
    var laggyTimes = 0
    // 卡顿时间集合
    var laggyTimeList = ArrayList<Float64>()
    public init() {}

    func toInteropPageResponseLaggyModel(): InteropPageResponseLaggyModel {
        let res = InteropPageResponseLaggyModel()
        res.pageName = this.pageName
        res.touchTimes = this.touchTimes
        res.laggyTimes = this.laggyTimes
        res.laggyTimeList = JSArrayEx<Float64>(this.laggyTimeList.toArray())
        res
    }
}

public func syncCallBack(frameTime: Int64, frameTargetTime: Int64) {
    if (isFirstCallBack) {
        isFirstCallBack = false
        return
    }
    var timeEnd = Float64(frameTime)
    var event = eventMap[timeBegain]
    var cost = ((timeEnd - timeBegain) * Duration.microsecond).toMicroseconds()
    if (cost > maxResponsesTime) {
        _reportResponseEvent(event)
        if (laggyMap.contains(currentPageName)) {
            var model = laggyMap[currentPageName]
            model.laggyTimes += 1
            model.laggyTimeList.add(timeEnd - timeBegain)
            if (model.laggyTimeList.size > maxSize) {
                model.laggyTimeList.remove(at: 0)
            }
            isComplite = true
        }
    }
    if (let Some(inter) <- _displySyncInterface) {
    	inter.stop()
        inter.off()
    }
    isFirstCallBack = true
}

@Interop[ArkTS]
public class ClickInfo {
    public let timestamp: Float64
    public let windowX: Float64
    public let windowY: Float64
    public let id: String
    public let nodeType: String
    public let hitX: Float64
    public let hitY: Float64
    public let hitHeight: Float64
    public let hitWidth: Float64
    public init(time: Float64, wx: Float64, wy: Float64, id: String, nodeType: String, hX: Float64, hY: Float64,
        hH: Float64, hW: Float64) {
        this.timestamp = time
        this.windowX = wx
        this.windowY = wy
        this.id = id
        this.nodeType = nodeType
        this.hitX = hX
        this.hitY = hY
        this.hitHeight = hH
        this.hitWidth = hW
    }
}

public func didClickCallBack(info: ClickInfo) {
    if (isComplite) {
        isComplite = false
    }
    var response = ResponseEvent()
    var t_begain = info.timestamp
    timeBegain = t_begain
    response.pageName = currentPageName
    response.touchX = info.hitX
    response.touchY = info.hitY
    try {
        response.viewTouchID = info.id
        response.nodeType = info.nodeType
        // waiting bugfix
        response.hitX = info.hitX
        response.hitY = info.hitY
        response.hitHeight = info.hitHeight
        response.hitWidth = info.hitWidth
    } catch (e: NoneValueException) {
        println(e.toString())
    }
    eventMap.add(timeBegain, response)
    if (laggyMap.contains(currentPageName)) {
        laggyMap[currentPageName].touchTimes += 1
    }

    if (let Some(inter) <- _displySyncInterface) {
    	inter.on(syncCallBack)
        inter.start()
    }
}

public func navDestinationSwitchCallBack(name: String) {
    if (laggyMap.contains(currentPageName)) {
        var res = laggyMap[currentPageName]
        _reportPageResponseLaggyModel(laggyMap[currentPageName].toInteropPageResponseLaggyModel())
        laggyMap.remove(currentPageName)
    }
    if (!name.isEmpty()) {
        var res = PageResponseLaggyModel()
        res.pageName = name
        currentPageName = name
        laggyMap.add(name, res)
    }
}

public func onAbilityBackgroundCallBack() {
    if (laggyMap.contains(currentPageName)) {
        var res = laggyMap[currentPageName]
        _reportPageResponseLaggyModel(laggyMap[currentPageName].toInteropPageResponseLaggyModel())
        laggyMap.remove(currentPageName)
    }
}

public func initLaggyHandler(
    onDisplay: DisplaySyncInterface,
    onAbilityBackground: (cb: () -> Unit) -> Unit,
    onNavDestinationSwitch: (cb: (targetPageName: String) -> Unit) -> Unit,
    onDidClick: (cb: (info: ClickInfo) -> Unit) -> Unit,
    maxTime: Int64,
    maxArraySize: Int64,
    reportResponseEvent: (info: ResponseEvent) -> Unit,
    reportPageResponseLaggyModel: (info: InteropPageResponseLaggyModel) -> Unit
): Unit {
    _displySyncInterface = onDisplay
    _reportResponseEvent = reportResponseEvent
    _reportPageResponseLaggyModel = reportPageResponseLaggyModel
    maxSize = maxArraySize
    maxResponsesTime = maxTime
    onNavDestinationSwitch(navDestinationSwitchCallBack)
    onDidClick(didClickCallBack)
    onAbilityBackground(onAbilityBackgroundCallBack)
}
