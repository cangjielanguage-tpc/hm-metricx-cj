/**
 * Created on 2025/4/28
 */
package ohos_app_cangjie_hm_metricx_cj.fps

import ohos.base.{Callback1Argument}
import tpc.UIKit.Observer.{ScrollEventInfo, NavDestinationSwitchInfo, on, ObserverListenerType}
import tpc.ArkGraphics2D.displaySync.{IntervalInfo, DisplaySync, create, OnOffType}
import ohos.hilog.Hilog
import tpc.UIKit.arkui_node.*
import tpc.AbilityKit.common.UIAbilityContext
import stdx.encoding.json.{JsonObject, JsonString}
import ohos.component.Scroll
import tpc.UIKit.component_interop.Scroll
import tpc.UIKit.window.{WindowStage, WindowCallbackType, WindowEventType}
import tpc.WeatherServiceKit.weatherService.Wind
import std.collection.ArrayDeque
import ohos.base.AppLog
import ohos_app_cangjie_hm_metricx_cj.getTargetPageName
import ohos_app_cangjie_hm_metricx_cj.defaultPageName

const NANOS_IN_SECOND = 1000000000
const SCROLL_HITCH_COEFF = 1000

// 滚动时间回调类
public class ScrollEventCallback <: Callback1Argument<ScrollEventInfo> {
    let elementInfoCallback: (ScrollEventInfo) -> Unit
    public init(elementInfoCallback: (ScrollEventInfo) -> Unit) {
        this.elementInfoCallback = elementInfoCallback
    }
    public func invoke(res: ScrollEventInfo): Unit {
        this.elementInfoCallback(res)
    }
}

// 页面跳转回调类
public class NavDestinationSwitchCallBack <: Callback1Argument<NavDestinationSwitchInfo> {
    let elementInfoCallback: (NavDestinationSwitchInfo) -> Unit
    public init(elementInfoCallback: (NavDestinationSwitchInfo) -> Unit) {
        this.elementInfoCallback = elementInfoCallback
    }
    public func invoke(res: NavDestinationSwitchInfo): Unit {
        this.elementInfoCallback(res)
    }
}

// window监控回调类
public class WindowEventTypeCallBack <: Callback1Argument<WindowEventType> {
    let elementInfoCallback: (WindowEventType) -> Unit
    public init(elementInfoCallback: (WindowEventType) -> Unit) {
        this.elementInfoCallback = elementInfoCallback
    }
    public func invoke(res: WindowEventType): Unit {
        this.elementInfoCallback(res)
    }
}

// 帧事件回调类
public class IntervalInfoCallback <: Callback1Argument<IntervalInfo> {
    let elementInfoCallback: (IntervalInfo) -> Unit
    public init(elementInfoCallback: (IntervalInfo) -> Unit) {
        this.elementInfoCallback = elementInfoCallback
    }
    public func invoke(res: IntervalInfo): Unit {
        this.elementInfoCallback(res)
    }
}

// 页面Fps信息类
public open class FpsEventInfo {
    private var minFpsValue: ?Int64 = None
    private var avgFpsValue: ?Int64 = None
    private var pageNameValue: ?String = None

    mut prop minFps: ?Int64 {
        get() {
            minFpsValue
        }
        set(value) {
            minFpsValue = value
        }
    }

    mut prop avgFps: ?Int64 {
        get() {
            avgFpsValue
        }
        set(value) {
            avgFpsValue = value
        }
    }

    mut prop pageName: ?String {
        get() {
            pageNameValue
        }
        set(value) {
            pageNameValue = value
        }
    }

    public init() {}

    public init(minFps: Int64, avgFps: Int64, pageName: String) {
        this.minFpsValue = minFps
        this.avgFpsValue = avgFps
        this.pageNameValue = pageName
    }

    public open func toString(): String {
        let jsonObj = JsonObject()
        if (minFpsValue.isSome()) {
            let str: String = "${minFpsValue.getOrThrow()}"
            jsonObj.put("minFps", JsonString(str))
        }
        if (avgFpsValue.isSome()) {
            let str: String = "${avgFpsValue.getOrThrow()}"
            jsonObj.put("avgFps", JsonString(str))
        }
        if (pageNameValue.isSome()) {
            jsonObj.put("pageName", JsonString(pageNameValue.getOrThrow()))
        }
        jsonObj.toString()
    }

    static func fromJson(jsonObject: JsonObject): FpsEventInfo {
        let fpsEventInfo = FpsEventInfo()
        if (jsonObject.get("minFps").isSome()) {
            fpsEventInfo.minFps = jsonObject.get("minFps").getOrThrow().toString() as Int64
        }
        if (jsonObject.get("avgFps").isSome()) {
            fpsEventInfo.avgFps = jsonObject.get("avgFps").getOrThrow().toString() as Int64
        }
        if (jsonObject.get("pageName").isSome()) {
            fpsEventInfo.pageName = jsonObject.get("pageName").getOrThrow().toString()
        }
        fpsEventInfo
    }
}

// 滑动事件Fps&滑动掉帧率信息类
public class ScrollHitchInfo <: FpsEventInfo {
    private var frameDropRatioValue: ?Float64 = None

    mut prop frameDropRatio: ?Float64 {
        get() {
            frameDropRatioValue
        }
        set(value) {
            frameDropRatioValue = value
        }
    }

    public init() {}

    public init(minFpsValue: Int64, avgFpsValue: Int64, frameDropRatioValue: Float64, currentPageName: String) {
        super(minFpsValue, avgFpsValue, currentPageName)
        this.frameDropRatioValue = frameDropRatioValue
    }

    public override func toString(): String {
        let jsonObj = JsonObject()
        if (minFps.isSome()) {
            let str: String = "${minFps.getOrThrow()}"
            jsonObj.put("minFps", JsonString(str))
        }
        if (avgFps.isSome()) {
            let str: String = "${avgFps.getOrThrow()}"
            jsonObj.put("avgFps", JsonString(str))
        }
        if (frameDropRatioValue.isSome()) {
            let str: String = "${frameDropRatioValue.getOrThrow()}"
            jsonObj.put("frameDropRatio", JsonString(str))
        }
        jsonObj.toString()
    }

    static func fromJson(jsonObject: JsonObject): ScrollHitchInfo {
        let scrollHitchInfo = ScrollHitchInfo()
        if (jsonObject.get("minFps").isSome()) {
            scrollHitchInfo.minFps = jsonObject.get("minFps").getOrThrow().toString() as Int64
        }
        if (jsonObject.get("avgFps").isSome()) {
            scrollHitchInfo.avgFps = jsonObject.get("avgFps").getOrThrow().toString() as Int64
        }
        if (jsonObject.get("pageName").isSome()) {
            scrollHitchInfo.pageName = jsonObject.get("pageName").getOrThrow().toString()
        }
        if (jsonObject.get("frameDropRatio").isSome()) {
            scrollHitchInfo.frameDropRatio = jsonObject.get("frameDropRatio").getOrThrow().toString() as Float64
        }
        scrollHitchInfo
    }
}

public open class FpsEvent {
    // 创建DisplaySync对象
    protected var backDisplaySync: DisplaySync = create()
    // 当前帧信息
    protected var timestamp: Int64 = 0
    protected var targetTimestamp: Int64 = 0
    // 统计信息
    protected var totalStatisticsTime: Int64 = 0
    protected var totalFrameCount: Int64 = 0
    protected var totalStatisticsTimePerSec: Int64 = 0
    // 是否是第一帧
    protected var isFirstFrame: Bool = true
    // 当前页面名
    protected var currentPageName: String = ""
    // 重置当前Frame
    public func resetFrameInfo(timestamp: Int64, targetTimestamp: Int64): Unit {
        this.timestamp = timestamp
        this.targetTimestamp = targetTimestamp
    }
    // 开始检测frame事件
    public func startDisplaySync() {
        this.backDisplaySync.start()
    }
    // 停止检测frame事件
    public func stopDisplaySync() {
        this.backDisplaySync.stop()
    }
    // 重置监听事件
    public open func reset() {
        this.isFirstFrame = true
        this.timestamp = 0
        this.targetTimestamp = 0
        this.totalStatisticsTime = 0
        this.totalFrameCount = 0
        this.totalStatisticsTimePerSec = 0
    }
}

public class PageFpsEvent <: FpsEvent {
    // 单例模式
    private static var instance = PageFpsEvent()
    public static func GetInstance() {
        instance
    }
    // 监控指标
    private var minFps: Int64 = 0
    private var framesInOnePer = ArrayDeque<Int64>()
    private var fpsEventInfo: ?FpsEventInfo = None
    public func reset() {
        super.reset()
        this.minFps = 0
        this.framesInOnePer = ArrayDeque<Int64>()
        this.fpsEventInfo = None
    }
    // 监控每一帧，计算Fps
    public func frameEventListener() {
        let callback = {
            frameInfo: IntervalInfo =>
            totalFrameCount += 1
            if (isFirstFrame) {
                resetFrameInfo(frameInfo.timestamp, frameInfo.targetTimestamp)
                isFirstFrame = false
            } else {
                let realTimeInterval = frameInfo.timestamp - timestamp
                // avgFps
                totalStatisticsTime += realTimeInterval
                // minFps
                while (!framesInOnePer.isEmpty() && framesInOnePer.first.getOrThrow() < frameInfo.timestamp - NANOS_IN_SECOND) {
                    framesInOnePer.removeFirst()
                }
                framesInOnePer.addLast(frameInfo.timestamp)
                if (totalStatisticsTime >= NANOS_IN_SECOND) {
                    var fpsCount = framesInOnePer.size
                    if (fpsCount < minFps || minFps == 0) {
                        minFps = fpsCount
                    }
                }
                resetFrameInfo(frameInfo.timestamp, frameInfo.targetTimestamp)
            }
        }
        backDisplaySync.on(OnOffType.DS_FRAME, IntervalInfoCallback(callback))
    }
    // 统计minFps和avgFps
    public func report(): Option<FpsEventInfo> {
        if (totalStatisticsTime <= 0) {
            return None
        }
        let avgFps = NANOS_IN_SECOND * totalFrameCount / totalStatisticsTime
        if (totalStatisticsTime < NANOS_IN_SECOND || minFps > avgFps) {
            minFps = avgFps
        }
        FpsEventInfo(minFps, avgFps, currentPageName)
    }
}

public class ScrollFpsEvent <: FpsEvent {
    // 单例模式
    private static var instance = ScrollFpsEvent()
    public static func GetInstance() {
        instance
    }
    // 监控指标
    private var minFps: Int64 = 0
    private var totalFrameDropTime: Int64 = 0
    private var framesInOnePer = ArrayDeque<Int64>()
    private var scrollHitchInfo: ?ScrollHitchInfo = None
    public func reset() {
        super.reset()
        this.minFps = 0
        this.totalFrameDropTime = 0
        this.scrollHitchInfo = None
        this.framesInOnePer = ArrayDeque<Int64>()
    }
    // 监控每一帧，计算Fps和滑动掉帧时间
    public func frameEventListener() {
        let callback = {
            frameInfo: IntervalInfo =>
            totalFrameCount += 1
            if (isFirstFrame) {
                resetFrameInfo(frameInfo.timestamp, frameInfo.targetTimestamp)
                isFirstFrame = false
            } else {
                let realTimeInterval = frameInfo.timestamp - timestamp
                // avgFps
                totalStatisticsTime += realTimeInterval
                // minFps
                while (!framesInOnePer.isEmpty() && framesInOnePer.first.getOrThrow() < frameInfo.timestamp - NANOS_IN_SECOND) {
                    framesInOnePer.removeFirst()
                }
                framesInOnePer.addLast(frameInfo.timestamp)
                if (totalStatisticsTime >= NANOS_IN_SECOND) {
                    var fpsCount = framesInOnePer.size
                    if (fpsCount < minFps || minFps == 0) {
                        minFps = fpsCount
                    }
                }
                // 滑动掉帧率, 值为负时不纳入统计
                if (targetTimestamp < frameInfo.timestamp) {
                    totalFrameDropTime += (frameInfo.timestamp - targetTimestamp)
                }
                resetFrameInfo(frameInfo.timestamp, frameInfo.targetTimestamp)
            }
        }
        backDisplaySync.on(OnOffType.DS_FRAME, IntervalInfoCallback(callback))
    }
    // 统计minFps和avgFps
    public func report(): Option<ScrollHitchInfo> {
        if (totalStatisticsTime <= 0) {
            return None
        }
        let avgFps = NANOS_IN_SECOND * totalFrameCount / totalStatisticsTime
        if (totalStatisticsTime < NANOS_IN_SECOND) {
            minFps = avgFps
        }
        let frameDropRatio: Float64 = Float64(SCROLL_HITCH_COEFF * totalFrameDropTime) / Float64(totalStatisticsTime)
        ScrollHitchInfo(minFps, avgFps, frameDropRatio, currentPageName)
    }
}

// 滑动时间监听
public func initScrollEventHandler(uiContext: UIAbilityContext, reportScrollInfo: (scrollInfo: ScrollHitchInfo) -> Unit) {
    let instance = ScrollFpsEvent.GetInstance()
    instance.currentPageName = defaultPageName
    let scrollCallback1 = {
        =>
        instance.startDisplaySync()
        instance.frameEventListener()
    }
    let scrollCallback2 = {
        =>
        instance.stopDisplaySync()
        let scrollInfo = instance.report()
        if (scrollInfo.isSome()) {
            reportScrollInfo(scrollInfo.getOrThrow())
        }
        instance.reset()
    }
    on(
        scrollEvent,
        ScrollEventCallback {
            info: ScrollEventInfo => match (info.scrollEvent) {
                case SCROLL_START => scrollCallback1()
                case SCROLL_STOP => scrollCallback2()
            }
        }
    )
    on(
        navDestinationSwitch,
        uiContext,
        NavDestinationSwitchCallBack {
            info: NavDestinationSwitchInfo => instance.currentPageName = getTargetPageName(info)
        }
    )
}

// 页面停留监听
public func initPageEventHandler(uiContext: UIAbilityContext, reportFpsInfo: (fpsInfo: FpsEventInfo) -> Unit) {
    let instance = PageFpsEvent.GetInstance()
    let pageCallback1 = {
        currentPageName: String =>
        instance.currentPageName = currentPageName
        instance.startDisplaySync()
        instance.frameEventListener()
    }
    let pageCallback2 = {
        =>
        instance.stopDisplaySync()
        let fpsInfo = instance.report()
        if (fpsInfo.isSome()) {
            reportFpsInfo(fpsInfo.getOrThrow())
        }
        instance.reset()
    }
    pageCallback1(defaultPageName)
    on(
        navDestinationSwitch,
        uiContext,
        NavDestinationSwitchCallBack {
            info: NavDestinationSwitchInfo =>
            pageCallback2()
            pageCallback1(getTargetPageName(info))
        }
    )
}

// 应用状态监控
public func initPageEventHandler(windowStage: WindowStage, reportFpsInfo: (fpsInfo: FpsEventInfo) -> Unit) {
    let instance = PageFpsEvent.GetInstance()
    let pageCallback1 = {
        =>
        instance.startDisplaySync()
        instance.frameEventListener()
    }
    let pageCallback2 = {
        =>
        instance.stopDisplaySync()
        let fpsInfo = instance.report()
        if (fpsInfo.isSome()) {
            reportFpsInfo(fpsInfo.getOrThrow())
        }
        instance.reset()
    }
    let window = windowStage.getMainWindowSync()
    window.on(
        WindowCallbackType.WindowEvent,
        WindowEventTypeCallBack {
            info => match (info) {
                case WINDOW_ACTIVE => pageCallback1()
                case WINDOW_INACTIVE => pageCallback2()
                case _ => ()
            }
        }
    )
}
