/**
 * Created on 2025/9/20
 */
package ohos_app_cangjie_hm_metricx_cj.fps

import ohos_app_cangjie_hm_metricx_cj.util.*
import std.collection.*
import ohos.ark_interop_macro.*
import ohos.ark_interop.*

const NANOS_IN_SECOND = 1000000000
const SCROLL_HITCH_COEFF = 1000

// 页面Fps信息类
@Interop[ArkTS]
public class FpsEventInfo {
    public let minFps: Int64
    public let avgFps: Int64
    public let pageName: String
    public FpsEventInfo(minFps: Int64, avgFps: Int64, pageName: String) {
        this.minFps = minFps
        this.avgFps = avgFps
        this.pageName = pageName
    }
}

// 滑动事件Fps&滑动掉帧率信息类
@Interop[ArkTS]
public class ScrollHitchInfo {
    public let minFps: Int64
    public let avgFps: Int64
    public let frameDropRatio: Float64
    public let jankRate: Float64
    public let bigJankRate: Float64
    public let htLessThan0: Float64
    public let ht0To00001: Float64
    public let ht00001To0001: Float64
    public let ht0001To001: Float64
    public let ht001To005: Float64
    public let ht005To01: Float64
    public let ht01To1: Float64
    public let htBiggerThan1: Float64
    public let targetFPS: Float64
    public let longestLostFrame: Float64
    public let totalFrameCount: Int64
    public let pageName: String

    public ScrollHitchInfo(minFps: Int64, avgFps: Int64, frameDropRatio: Float64, jankRate: Float64,
        bigJankRate: Float64, htLessThan0: Float64, ht0To00001: Float64, ht00001To0001: Float64, ht0001To001: Float64,
        ht001To005: Float64, ht005To01: Float64, ht01To1: Float64, htBiggerThan1: Float64, targetFPS: Float64,
        longestLostFrame: Float64, totalFrameCount: Int64, pageName: String) {
        this.minFps = minFps
        this.avgFps = avgFps
        this.frameDropRatio = frameDropRatio
        this.jankRate = jankRate
        this.bigJankRate = bigJankRate
        this.htLessThan0 = htLessThan0
        this.ht0To00001 = ht0To00001
        this.ht00001To0001 = ht00001To0001
        this.ht0001To001 = ht0001To001
        this.ht001To005 = ht001To005
        this.ht005To01 = ht005To01
        this.ht01To1 = ht01To1
        this.htBiggerThan1 = htBiggerThan1
        this.targetFPS = targetFPS
        this.longestLostFrame = longestLostFrame
        this.totalFrameCount = totalFrameCount
        this.pageName = pageName
    }
}

var _displySyncInterface: Option<DisplaySyncInterface> = None

public open class FpsEvent {
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
    public func updateFrameInfo(timestamp: Int64, targetTimestamp: Int64): Unit {
        this.timestamp = timestamp
        this.targetTimestamp = targetTimestamp
    }
    // 开始检测frame事件
    public func startDisplaySync() {
        if (let Some(inter) <- _displySyncInterface) {
        	inter.start()
        }
    }
    // 停止检测frame事件
    public func stopDisplaySync() {
        if (let Some(inter) <- _displySyncInterface) {
        	inter.stop()
        }
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
    private var minFps: Int64 = Int64.Max
    private var framesInOnePer = ArrayDeque<Int64>()
    private var fpsEventInfo: ?FpsEventInfo = None
    public func reset() {
        super.reset()
        this.minFps = Int64.Max
        this.framesInOnePer = ArrayDeque<Int64>()
        this.fpsEventInfo = None
    }
    // 监控每一帧，计算Fps
    public func frameEventListener() {
        let callback = {
            frameTime: Int64, frameTargetTime: Int64 =>
            if (isFirstFrame) {
                isFirstFrame = false
            } else {
                totalFrameCount += 1
                let realTimeInterval = frameTime - timestamp
                // avgFps
                totalStatisticsTime += realTimeInterval
                // minFps
                while (!framesInOnePer.isEmpty() && framesInOnePer.first.getOrThrow() < frameTime - NANOS_IN_SECOND) {
                    framesInOnePer.removeFirst()
                }
                framesInOnePer.addLast(frameTime)
                if (totalStatisticsTime >= NANOS_IN_SECOND) {
                    minFps = min(minFps, framesInOnePer.size)
                }
            }
            updateFrameInfo(frameTime, frameTargetTime)
        }
        if (let Some(inter) <- _displySyncInterface) {
        	inter.on(callback)
        }
    }
    // 统计minFps和avgFps
    public func report(): Option<FpsEventInfo> {
        if (totalStatisticsTime <= 0) {
            return None
        }
        let avgFps = NANOS_IN_SECOND * totalFrameCount / totalStatisticsTime
        minFps = min(minFps, avgFps)
        FpsEventInfo(minFps, avgFps, currentPageName)
    }
}

class PageScrollFps {
    private let minFpsList = ArrayList<Int64>()
    private var frameCount = 0
    private var totalTime = 0
    private var dropTime = 0
    private var htLessThan0 = 0
    private var ht0To00001 = 0
    private var ht00001To0001 = 0
    private var ht0001To001 = 0
    private var ht001To005 = 0
    private var ht005To01 = 0
    private var ht01To1 = 0
    private var htBiggerThan1 = 0
    private var htBiggerThan0001 = 0
    private var htBiggerThan07 = 0
    private var targetDuration = 0
    private var longestLostFrame = 0.0

    public func clear(): Unit {
        minFpsList.clear()
        frameCount = 0
        totalTime = 0
        dropTime = 0
        htLessThan0 = 0
        ht0To00001 = 0
        ht00001To0001 = 0
        ht0001To001 = 0
        ht001To005 = 0
        ht005To01 = 0
        ht01To1 = 0
        htBiggerThan1 = 0
        htBiggerThan0001 = 0
        htBiggerThan07 = 0
        targetDuration = 0
        longestLostFrame = 0.0
    }

    public func addInfo(minFps: Int64, totalFrameCount: Int64, totalStatisticsTime: Int64, totalFrameDropTime: Int64,
        htLessThan0Cnt: Int64, ht0To00001Cnt: Int64, ht00001To0001Cnt: Int64, ht0001To001Cnt: Int64,
        ht001To005Cnt: Int64, ht005To01Cnt: Int64, ht01To1Cnt: Int64, htBiggerThan1Cnt: Int64,
        htBiggerThan0001Cnt: Int64, htBiggerThan07Cnt: Int64, targetDurationValue: Int64, longestLostFrameValue: Float64): Unit {
        minFpsList.add(minFps)
        frameCount += totalFrameCount
        totalTime += totalStatisticsTime
        dropTime += totalFrameDropTime
        htLessThan0 += htLessThan0Cnt
        ht0To00001 += ht0To00001Cnt
        ht00001To0001 += ht00001To0001Cnt
        ht0001To001 += ht0001To001Cnt
        ht001To005 += ht001To005Cnt
        ht005To01 += ht005To01Cnt
        ht01To1 += ht01To1Cnt
        htBiggerThan1 += htBiggerThan1Cnt
        htBiggerThan0001 += htBiggerThan0001Cnt
        htBiggerThan07 += htBiggerThan07Cnt
        targetDuration = targetDurationValue
        longestLostFrame = max(longestLostFrame, longestLostFrameValue)
    }

    public func isEmpty(): Bool {
        minFpsList.isEmpty()
    }

    public func report(): Option<ScrollHitchInfo> {
        if (isEmpty()) {
            return None
        }
        let minFps = min<Int64>(minFpsList.iterator()).getOrThrow()
        let avgFps = NANOS_IN_SECOND * frameCount / totalTime
        let frameDropRatio: Float64 = Float64(SCROLL_HITCH_COEFF * dropTime) / Float64(totalTime)
        let jankRate = Float64(htBiggerThan0001) / Float64(frameCount)
        let bigJankRate = Float64(htBiggerThan07) / Float64(frameCount)
        let htLessThan0 = Float64(htLessThan0) / Float64(frameCount)
        let ht0To00001 = Float64(ht0To00001) / Float64(frameCount)
        let ht00001To0001 = Float64(ht00001To0001) / Float64(frameCount)
        let ht0001To001 = Float64(ht0001To001) / Float64(frameCount)
        let ht001To005 = Float64(ht001To005) / Float64(frameCount)
        let ht005To01 = Float64(ht005To01) / Float64(frameCount)
        let ht01To1 = Float64(ht01To1) / Float64(frameCount)
        let htBiggerThan1 = Float64(htBiggerThan1) / Float64(frameCount)
        let targetFPS = Float64(NANOS_IN_SECOND) / Float64(targetDuration)
        ScrollHitchInfo(minFps, avgFps, frameDropRatio, jankRate, bigJankRate, htLessThan0, ht0To00001, ht00001To0001,
            ht0001To001, ht001To005, ht005To01, ht01To1, htBiggerThan1, targetFPS, longestLostFrame, frameCount,
            ScrollFpsEvent.GetInstance().currentPageName)
    }
}

public class ScrollFpsEvent <: FpsEvent {
    // 单例模式
    private static var instance = ScrollFpsEvent()
    public static func GetInstance() {
        instance
    }
    // 监控指标
    private var minFps: Int64 = Int64.Max
    private var totalFrameDropTime: Int64 = 0
    private var framesInOnePer = ArrayDeque<Int64>()
    private var scrollHitchInfo: ?ScrollHitchInfo = None
    private var htLessThan0 = 0
    private var ht0To00001 = 0
    private var ht00001To0001 = 0
    private var ht0001To001 = 0
    private var ht001To005 = 0
    private var ht005To01 = 0
    private var ht01To1 = 0
    private var htBiggerThan1 = 0
    private var htBiggerThan0001 = 0
    private var htBiggerThan07 = 0
    private var firstTargetDuration = 0
    private var longestLostFrame = 0.0
    private var targetDuration = 0

    public func reset() {
        super.reset()
        this.minFps = Int64.Max
        this.totalFrameDropTime = 0
        this.scrollHitchInfo = None
        this.framesInOnePer.clear()
        htLessThan0 = 0
        ht0To00001 = 0
        ht00001To0001 = 0
        ht0001To001 = 0
        ht001To005 = 0
        ht005To01 = 0
        ht01To1 = 0
        htBiggerThan1 = 0
        htBiggerThan0001 = 0
        htBiggerThan07 = 0
        firstTargetDuration = 0
        longestLostFrame = 0.0
    }
    // 监控每一帧，计算Fps和滑动掉帧时间
    public func frameEventListener() {
        let callback = {
            frameTime: Int64, frameTargetTime: Int64 =>
            if (isFirstFrame) {
                isFirstFrame = false
                firstTargetDuration = frameTargetTime - frameTime
            } else {
                totalFrameCount += 1
                let realTimeInterval = frameTime - timestamp
                // avgFps
                totalStatisticsTime += realTimeInterval
                // minFps
                while (!framesInOnePer.isEmpty() && framesInOnePer.first.getOrThrow() < frameTime - NANOS_IN_SECOND) {
                    framesInOnePer.removeFirst()
                }
                framesInOnePer.addLast(frameTime)
                if (totalStatisticsTime >= NANOS_IN_SECOND) {
                    minFps = min(minFps, framesInOnePer.size)
                }
                // 滑动掉帧率, 值为负时不纳入统计
                let delta = frameTime - targetTimestamp
                totalFrameDropTime += max(0, delta)
                longestLostFrame = max(longestLostFrame, Float64(delta) / Float64(targetDuration) - 1.0)
                updateHt(delta)
            }
            targetDuration = frameTargetTime - frameTime
            updateFrameInfo(frameTime, frameTargetTime)
        }
        if (let Some(inter) <- _displySyncInterface) {
        	inter.on(callback)
        }
    }

    func report(pageScrollFps: PageScrollFps): Unit {
        if (totalStatisticsTime <= 0) {
            return
        }
        let avgFps = NANOS_IN_SECOND * totalFrameCount / totalStatisticsTime
        minFps = min(minFps, avgFps)
        pageScrollFps.addInfo(minFps, totalFrameCount, totalStatisticsTime, totalFrameDropTime, htLessThan0, ht0To00001,
            ht00001To0001, ht0001To001, ht001To005, ht005To01, ht01To1, htBiggerThan1, htBiggerThan0001, htBiggerThan07,
            firstTargetDuration, longestLostFrame)
    }

    func updateHt(delta: Int64) {
        if (delta < 0) {
            htLessThan0 += 1
        } else if (delta < 100_000) { // 0.1ms
            ht0To00001 += 1
        } else if (delta < 1000_000) {
            ht00001To0001 += 1
        } else if (delta < 10_000_000) {
            ht0001To001 += 1
        } else if (delta < 50_000_000) {
            ht001To005 += 1
        } else if (delta < 100_000_000) {
            ht005To01 += 1
        } else if (delta < 1000_000_000) {
            ht01To1 += 1
        } else {
            htBiggerThan1 += 1
        }

        if (delta > 1000_000) {
            htBiggerThan0001 += 1
        }

        if (delta > 700_000_000) {
            htBiggerThan07 += 1
        }
    }
}

// 滑动时间监听
public func initScrollEventHandler(
    onDisplay: DisplaySyncInterface,
    onScrollEvent: (scrolllStart: () -> Unit, onScrllStop: () -> Unit) -> Unit,
    onNavDestinationSwitch: (cb: (targetPageName: String) -> Unit) -> Unit,
    reportPageScrollInfo: (scrollInfo: ScrollHitchInfo) -> Unit
) {
    _displySyncInterface = onDisplay
    let instance = ScrollFpsEvent.GetInstance()
    let pageScrollFps = PageScrollFps()
    instance.currentPageName = defaultPageName
    let scrollStartCallback = {
        =>
        instance.startDisplaySync()
        instance.frameEventListener()
    }
    let scrollStopCallback = {
        =>
        instance.stopDisplaySync()
        instance.report(pageScrollFps)
        instance.reset()
    }
    onScrollEvent(scrollStartCallback, scrollStopCallback)
    onNavDestinationSwitch(
        {
            targetPageName: String =>
            let pageScrollInfo = pageScrollFps.report()
            if (let Some(info) <- pageScrollInfo) {
                reportPageScrollInfo(info)
            }
            pageScrollFps.clear()
            instance.currentPageName = targetPageName
        }
    )
}

// 页面停留监听
public func initPageEventHandler(
    onNavDestinationSwitch: (cb: (targetPageName: String) -> Unit) -> Unit,
    reportFpsInfo: (fpsInfo: FpsEventInfo) -> Unit
) {
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
    onNavDestinationSwitch(
        {
            targetPageName: String =>
            pageCallback2()
            pageCallback1(targetPageName)
        }
    )
}

// 应用状态监控
public func initPageEventHandler(
    onWindowEvent: (windwoActive: () -> Unit, windowInactive: () -> Unit) -> Unit,
    reportFpsInfo: (fpsInfo: FpsEventInfo) -> Unit
): Unit {
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
    onWindowEvent(pageCallback1, pageCallback2)
}
