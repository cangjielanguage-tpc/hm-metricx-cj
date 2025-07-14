/**
 * Created on 2025/4/28
 */
package ohos_app_cangjie_hm_metricx_cj.fps

import ohos.base.{Callback1Argument}
import tpc.UIKit.Observer.{ScrollEventInfo, NavDestinationSwitchInfo, on, ObserverListenerType}
import tpc.ArkGraphics2D.displaySync.{IntervalInfo, DisplaySync, create, OnOffType}
import ohos.hilog.Hilog
//import tpc.UIKit.arkui_node.*
import tpc.AbilityKit.common.UIAbilityContext
import stdx.encoding.json.{JsonObject, JsonString}
//import ohos.component.Scroll
//import tpc.UIKit.component_interop.Scroll
import tpc.UIKit.window.{WindowStage, WindowCallbackType, WindowEventType}
//import tpc.WeatherServiceKit.weatherService.Wind

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

    public init() {}

    public init(minFpsValue: Int64, avgFpsValue: Int64) {
        this.minFpsValue = minFpsValue
        this.avgFpsValue = avgFpsValue
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
        fpsEventInfo
    }

    public open func reset(): Unit {
        this.minFpsValue = None
        this.avgFpsValue = None
    }
}

// 滑动事件Fps&滑动掉帧率信息类
public class ScrollHitchInfo <: FpsEventInfo {
    private var frameDropRatioValue: ?Int64 = None

    mut prop frameDropRatio: ?Int64 {
        get() {
            frameDropRatioValue
        }
        set(value) {
            frameDropRatioValue = value
        }
    }

    public init() {}

    public init(minFpsValue: Int64, avgFpsValue: Int64, frameDropRatioValue: Int64) {
        super(minFpsValue, avgFpsValue)
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
        if (jsonObject.get("frameDropRatio").isSome()) {
            scrollHitchInfo.frameDropRatio = jsonObject.get("frameDropRatio").getOrThrow().toString() as Int64
        }
        scrollHitchInfo
    }

    public override func reset(): Unit {
        super.reset()
        this.frameDropRatioValue = None
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
    protected var totalFrameCountPerSec: Int64 = 0
    // 是否是第一帧
    protected var isFirstFrame: Bool = true
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
        this.totalFrameCountPerSec = 0
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
    private var fpsEventInfo: ?FpsEventInfo = None
    public func reset() {
        super.reset()
        this.minFps = 0
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
                if (totalStatisticsTimePerSec < NANOS_IN_SECOND) {
                    totalFrameCountPerSec += 1
                    totalStatisticsTimePerSec += realTimeInterval
                } else {
                    if (minFps > totalFrameCountPerSec) {
                        minFps = totalFrameCountPerSec
                    }
                    totalFrameCountPerSec = 0
                    totalStatisticsTimePerSec = 0
                }
                resetFrameInfo(frameInfo.timestamp, frameInfo.targetTimestamp)
            }
        }
        backDisplaySync.on(OnOffType.DS_FRAME, IntervalInfoCallback(callback))
    }
    // 统计minFps和avgFps
    public func report(): FpsEventInfo {
        if (totalStatisticsTime <= 0) {
            return FpsEventInfo()
        }
        let avgFps = NANOS_IN_SECOND * totalFrameCount / totalStatisticsTime
        if (totalStatisticsTime < NANOS_IN_SECOND) {
            minFps = avgFps
        }
        FpsEventInfo(minFps, avgFps)
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
    private var scrollHitchInfo: ?ScrollHitchInfo = None
    public func reset() {
        super.reset()
        this.minFps = 0
        this.totalFrameDropTime = 0
        this.scrollHitchInfo = None
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
                if (totalStatisticsTimePerSec < NANOS_IN_SECOND) {
                    totalFrameCountPerSec += 1
                    totalStatisticsTimePerSec += realTimeInterval
                } else {
                    if (minFps > totalFrameCountPerSec) {
                        minFps = totalFrameCountPerSec
                    }
                    totalFrameCountPerSec = 0
                    totalStatisticsTimePerSec = 0
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
    public func report(): ScrollHitchInfo {
        if (totalStatisticsTime <= 0) {
            return ScrollHitchInfo()
        }
        let avgFps = NANOS_IN_SECOND * totalFrameCount / totalStatisticsTime
        if (totalStatisticsTime < NANOS_IN_SECOND) {
            minFps = avgFps
        }
        let frameDropRatio: Int64 = SCROLL_HITCH_COEFF * totalFrameDropTime / totalStatisticsTime
        ScrollHitchInfo(minFps, avgFps, frameDropRatio)
    }
}

// 滑动时间监听
public func initScrollEventHandle(reportScrollInfo: (scrollInfo: ScrollHitchInfo) -> Unit) {
    let instance = ScrollFpsEvent.GetInstance()
    let scrollCallback1 = {
        =>
        instance.startDisplaySync()
        instance.frameEventListener()
    }
    let scrollCallback2 = {
        =>
        instance.stopDisplaySync()
        let scrollInfo = instance.report()
        reportScrollInfo(scrollInfo)
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
}

// 页面停留监听
public func initPageEventHandle(uiContext: UIAbilityContext, reportFpsInfo: (fpsInfo: FpsEventInfo) -> Unit) {
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
        reportFpsInfo(fpsInfo)
        instance.reset()
    }
    on(
        navDestinationSwitch,
        uiContext,
        NavDestinationSwitchCallBack {
            info: NavDestinationSwitchInfo =>
            pageCallback2()
            pageCallback1()
        }
    )
}

// 应用状态监控
public func initPageEventHandle(windowStage: WindowStage, reportFpsInfo: (fpsInfo: FpsEventInfo) -> Unit) {
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
        reportFpsInfo(fpsInfo)
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
