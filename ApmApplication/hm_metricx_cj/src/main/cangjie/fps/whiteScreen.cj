package ohos_app_cangjie_hm_metricx_cj.fps

import ohos_app_cangjie_hm_metricx_cj.util.*
import ohos.ark_interop.*
import ohos.ark_interop_macro.*
import std.collection.*
import std.time.*
import std.convert.*
import ohos.base.AppLog

// ============================================================
// 白屏类型枚举
// ============================================================

public enum WhiteScreenType {
    | TIMEOUT
    | CONTENT_MISSING

    public func toString(): String {
        match (this) {
            case TIMEOUT => "TIMEOUT"
            case CONTENT_MISSING => "CONTENT_MISSING"
        }
    }
}

// ============================================================
// 白屏检测场景（区分页面进入 / 前台切后台）
// ============================================================

public enum WhiteScreenScene {
    | PAGE_OPEN
    | PAGE_BACKGROUND

    public func toString(): String {
        match (this) {
            case PAGE_OPEN => "PAGE_OPEN"
            case PAGE_BACKGROUND => "PAGE_BACKGROUND"
        }
    }
}

// ============================================================
// 应用前后台状态
// ============================================================

public enum WhiteScreenAppState {
    | FOREGROUND
    | BACKGROUND

    public func toString(): String {
        match (this) {
            case FOREGROUND => "FOREGROUND"
            case BACKGROUND => "BACKGROUND"
        }
    }

    public func isForeground(): Bool {
        match (this) {
            case FOREGROUND => true
            case BACKGROUND => false
        }
    }
}

// ============================================================
// 检测阶段枚举（内部状态机）
// ============================================================

enum DetectionPhase {
    | IDLE
    | WAITING_FIRST_FRAME
    | COUNTING_FRAMES
    | SNAPSHOT_ANALYSIS
}

// ============================================================
// 白屏事件数据模型（互操作版本）
// ============================================================

@Interop[ArkTS]
public class InteropWhiteScreenEventInfo {
    public let pageName: String
    public let whiteScreenType: String
    public let whiteScreenScene: String
    public let appState: String
    public let ttid: Float64
    public let backgroundElapsedMs: Float64
    public let foregroundDistinctColorCount: Int64
    public let foregroundMainColorWhite: Bool
    public let backgroundFirstDistinctColorCount: Int64
    public let backgroundSecondDistinctColorCount: Int64
    public let backgroundFirstMainColorWhite: Bool
    public let backgroundSecondMainColorWhite: Bool
    public let backgroundDetectionReason: String
    public let frameCountInNSeconds: Int64

    public init(
        pageName: String,
        whiteScreenType: String,
        whiteScreenScene: String,
        appState: String,
        ttid: Float64,
        backgroundElapsedMs: Float64,
        foregroundDistinctColorCount: Int64,
        foregroundMainColorWhite: Bool,
        backgroundFirstDistinctColorCount: Int64,
        backgroundSecondDistinctColorCount: Int64,
        backgroundFirstMainColorWhite: Bool,
        backgroundSecondMainColorWhite: Bool,
        backgroundDetectionReason: String,
        frameCountInNSeconds: Int64
    ) {
        this.pageName = pageName
        this.whiteScreenType = whiteScreenType
        this.whiteScreenScene = whiteScreenScene
        this.appState = appState
        this.ttid = ttid
        this.backgroundElapsedMs = backgroundElapsedMs
        this.foregroundDistinctColorCount = foregroundDistinctColorCount
        this.foregroundMainColorWhite = foregroundMainColorWhite
        this.backgroundFirstDistinctColorCount = backgroundFirstDistinctColorCount
        this.backgroundSecondDistinctColorCount = backgroundSecondDistinctColorCount
        this.backgroundFirstMainColorWhite = backgroundFirstMainColorWhite
        this.backgroundSecondMainColorWhite = backgroundSecondMainColorWhite
        this.backgroundDetectionReason = backgroundDetectionReason
        this.frameCountInNSeconds = frameCountInNSeconds
    }
}

// ============================================================
// 白屏检测配置类（内部使用）
// ============================================================

public class WhiteScreenConfig {
    public var rootComponentId: String = ""
    public var ttidTimeoutMs: Int64 = 1000
    public var frameCheckDurationMs: Int64 = 3000
    public var backgroundFirstSnapshotDelayMs: Int64 = 800
    public var backgroundSecondSnapshotDelayMs: Int64 = 1800
    public var backgroundRecentPageEnterThresholdMs: Int64 = 3000
    public var minFrameCountThreshold: Int64 = 30
    public var maxDistinctColorCount: Int64 = 2
    public var whiteRgbThreshold: Int64 = 245
    public var snapshotScale: Float64 = 0.1
    public var snapshotRegionTop: Float64 = 0.08
    public var snapshotRegionBottom: Float64 = 0.08
    public var autoWriteFaultLog: Bool = true

    public init() {}

    public init(rootComponentId: String) {
        this.rootComponentId = rootComponentId
    }

    public func validate(): Unit {
        validateNonNegativeInt64("ttidTimeoutMs", ttidTimeoutMs)
        validateNonNegativeInt64("frameCheckDurationMs", frameCheckDurationMs)
        validateNonNegativeInt64("backgroundFirstSnapshotDelayMs", backgroundFirstSnapshotDelayMs)
        validateNonNegativeInt64("backgroundSecondSnapshotDelayMs", backgroundSecondSnapshotDelayMs)
        validateNonNegativeInt64("backgroundRecentPageEnterThresholdMs", backgroundRecentPageEnterThresholdMs)
        validateNonNegativeInt64("minFrameCountThreshold", minFrameCountThreshold)
        validateNonNegativeInt64("maxDistinctColorCount", maxDistinctColorCount)
        validateNonNegativeInt64("whiteRgbThreshold", whiteRgbThreshold)
        validateFloat64InRange("snapshotScale", snapshotScale, 0.0, 1.0)
        validateFloat64InRange("snapshotRegionTop", snapshotRegionTop, 0.0, 1.0)
        validateFloat64InRange("snapshotRegionBottom", snapshotRegionBottom, 0.0, 1.0)
    }
}

private func validateNonNegativeInt64(fieldName: String, value: Int64): Unit {
    if (value < 0) {
        throw Exception("WhiteScreenConfig.${fieldName} must be >= 0, actual=${value}")
    }
}

private func validateFloat64InRange(fieldName: String, value: Float64, min: Float64, max: Float64): Unit {
    if (value < min || value > max) {
        throw Exception("WhiteScreenConfig.${fieldName} must be in [${min}, ${max}], actual=${value}")
    }
}

// ============================================================
// 白屏检测配置类（互操作版本）
// ============================================================

@Interop[ArkTS]
public class InteropWhiteScreenConfig {
    public let rootComponentId: String
    public let ttidTimeoutMs: Int64
    public let frameCheckDurationMs: Int64
    public let backgroundFirstSnapshotDelayMs: Int64
    public let backgroundSecondSnapshotDelayMs: Int64
    public let backgroundRecentPageEnterThresholdMs: Int64
    public let minFrameCountThreshold: Int64
    public let maxDistinctColorCount: Int64
    public let whiteRgbThreshold: Int64
    public let snapshotScale: Float64
    public let snapshotRegionTop: Float64
    public let snapshotRegionBottom: Float64
    public let autoWriteFaultLog: Bool

    public init(
        rootComponentId: String,
        ttidTimeoutMs: Int64,
        frameCheckDurationMs: Int64,
        backgroundFirstSnapshotDelayMs: Int64,
        backgroundSecondSnapshotDelayMs: Int64,
        backgroundRecentPageEnterThresholdMs: Int64,
        minFrameCountThreshold: Int64,
        maxDistinctColorCount: Int64,
        whiteRgbThreshold: Int64,
        snapshotScale: Float64,
        snapshotRegionTop: Float64,
        snapshotRegionBottom: Float64,
        autoWriteFaultLog: Bool
    ) {
        this.rootComponentId = rootComponentId
        this.ttidTimeoutMs = ttidTimeoutMs
        this.frameCheckDurationMs = frameCheckDurationMs
        this.backgroundFirstSnapshotDelayMs = backgroundFirstSnapshotDelayMs
        this.backgroundSecondSnapshotDelayMs = backgroundSecondSnapshotDelayMs
        this.backgroundRecentPageEnterThresholdMs = backgroundRecentPageEnterThresholdMs
        this.minFrameCountThreshold = minFrameCountThreshold
        this.maxDistinctColorCount = maxDistinctColorCount
        this.whiteRgbThreshold = whiteRgbThreshold
        this.snapshotScale = snapshotScale
        this.snapshotRegionTop = snapshotRegionTop
        this.snapshotRegionBottom = snapshotRegionBottom
        this.autoWriteFaultLog = autoWriteFaultLog
    }
}

public func toInternalConfig(config: InteropWhiteScreenConfig): WhiteScreenConfig {
    let internalConfig = WhiteScreenConfig()
    internalConfig.rootComponentId = config.rootComponentId
    internalConfig.ttidTimeoutMs = config.ttidTimeoutMs
    internalConfig.frameCheckDurationMs = config.frameCheckDurationMs
    internalConfig.backgroundFirstSnapshotDelayMs = config.backgroundFirstSnapshotDelayMs
    internalConfig.backgroundSecondSnapshotDelayMs = config.backgroundSecondSnapshotDelayMs
    internalConfig.backgroundRecentPageEnterThresholdMs = config.backgroundRecentPageEnterThresholdMs
    internalConfig.minFrameCountThreshold = config.minFrameCountThreshold
    internalConfig.maxDistinctColorCount = config.maxDistinctColorCount
    internalConfig.whiteRgbThreshold = config.whiteRgbThreshold
    internalConfig.snapshotScale = config.snapshotScale
    internalConfig.snapshotRegionTop = config.snapshotRegionTop
    internalConfig.snapshotRegionBottom = config.snapshotRegionBottom
    internalConfig.autoWriteFaultLog = config.autoWriteFaultLog
    internalConfig
}

// ============================================================
// 白屏检测器（单例）- 互操作版本
// ============================================================

public class WhiteScreenDetector {
    private static var instance = WhiteScreenDetector()
    public static func GetInstance() { instance }

    // Session 管理
    private var nextDetectionSessionId: Int64 = 0
    private var activeDetectionSessionId: Int64 = 0

    // 内部状态
    private var phase: DetectionPhase = DetectionPhase.IDLE
    private var enterTime: Int64 = 0
    private var firstFrameTime: Int64 = 0
    private var frameCount: Int64 = 0
    private var currentPageName: String = ""

    // 定时器 ID（由 ArkTS 侧管理）
    private var ttidTimerId: Int64 = -1
    private var frameCheckTimerId: Int64 = -1

    // 配置
    private var config: WhiteScreenConfig = WhiteScreenConfig()

    // 应用前后台状态
    private var appState: WhiteScreenAppState = WhiteScreenAppState.FOREGROUND

    // 回调函数（由 ArkTS 侧注入）
    private var reportCallback: Option<(info: InteropWhiteScreenEventInfo) -> Unit> = None
    private var setTimeoutFunc: Option<(String, Int64) -> Int64> = None
    private var clearTimeoutFunc: Option<(Int64) -> Unit> = None
    // 异步快照触发函数（由 ArkTS 侧注入）
    private var performSnapshotFunc: Option<() -> Unit> = None
    private var performBackgroundSnapshotFunc: Option<(Int64) -> Unit> = None

    // 后台检测状态
    private var nextBackgroundSessionId: Int64 = 0
    private var activeBackgroundSessionId: Int64 = 0
    private var backgroundFirstSnapshotTimerId: Int64 = -1
    private var backgroundSecondSnapshotTimerId: Int64 = -1
    private var backgroundPageName: String = ""
    private var backgroundStartTime: Int64 = 0
    private var backgroundDetectionActive: Bool = false
    private var backgroundFirstDistinctColorCount: ?Int64 = None
    private var backgroundSecondDistinctColorCount: ?Int64 = None
    private var backgroundFirstMainColorWhite: ?Bool = None
    private var backgroundSecondMainColorWhite: ?Bool = None
    private var backgroundDetectionReason: ?String = None

    private var backgroundFirstDone: Bool = false
    private var backgroundSecondDone: Bool = false

    // --------------------------------------------------------
    // Session 管理方法
    // --------------------------------------------------------

    private func createDetectionSessionId(): Int64 {
        nextDetectionSessionId += 1
        activeDetectionSessionId = nextDetectionSessionId
        activeDetectionSessionId
    }

    private func createBackgroundSessionId(): Int64 {
        nextBackgroundSessionId += 1
        activeBackgroundSessionId = nextBackgroundSessionId
        activeBackgroundSessionId
    }

    private func isDetectionSessionActive(sessionId: Int64): Bool {
        activeDetectionSessionId == sessionId && sessionId > 0
    }

    private func isBackgroundSessionActive(sessionId: Int64): Bool {
        activeBackgroundSessionId == sessionId && sessionId > 0 && backgroundDetectionActive
    }

    private func finishDetectionSession() {
        activeDetectionSessionId = 0
        phase = DetectionPhase.IDLE
    }

    private func isPageOpenDetectionRunning(): Bool {
        if (activeDetectionSessionId > 0) {
            match (phase) {
                case DetectionPhase.IDLE => false
                case _ => true
            }
        } else {
            false
        }
    }

    private func isPageRecentlyEntered(nowNanos: Int64): Bool {
        let elapsedMs = getPageEnterElapsedMs(nowNanos)
        elapsedMs >= 0.0 && elapsedMs <= Float64(config.backgroundRecentPageEnterThresholdMs)
    }

    private func getPageEnterElapsedMs(nowNanos: Int64): Float64 {
        if (enterTime <= 0) {
            return -1.0
        }
        Float64(nowNanos - enterTime) / 1_000_000.0
    }

    private func getBackgroundGateReason(nowNanos: Int64, pageOpenDetectionRunning: Bool): ?String {
        let recentlyEntered = isPageRecentlyEntered(nowNanos)
        if (recentlyEntered && pageOpenDetectionRunning) {
            return Some("RECENT_PAGE_ENTER_AND_PAGE_OPEN_DETECTION_ACTIVE")
        }
        if (recentlyEntered) {
            return Some("RECENT_PAGE_ENTER")
        }
        if (pageOpenDetectionRunning) {
            return Some("PAGE_OPEN_DETECTION_ACTIVE")
        }
        None
    }

    // --------------------------------------------------------
    // 初始化配置
    // --------------------------------------------------------

    public func configure(
        config: WhiteScreenConfig,
        reportCallback: (info: InteropWhiteScreenEventInfo) -> Unit,
        setTimeoutFunc: (String, Int64) -> Int64,
        clearTimeoutFunc: (Int64) -> Unit,
        performSnapshotFunc: () -> Unit,
        performBackgroundSnapshotFunc: (Int64) -> Unit
    ) {
        this.config = config
        this.reportCallback = reportCallback
        this.setTimeoutFunc = setTimeoutFunc
        this.clearTimeoutFunc = clearTimeoutFunc
        this.performSnapshotFunc = performSnapshotFunc
        this.performBackgroundSnapshotFunc = performBackgroundSnapshotFunc
    }

    public func destroy(): Unit {
        reset()
        resetBackgroundDetection()
        reportCallback = None
        setTimeoutFunc = None
        clearTimeoutFunc = None
        performSnapshotFunc = None
        performBackgroundSnapshotFunc = None
    }

    // --------------------------------------------------------
    // 状态重置
    // --------------------------------------------------------

    public func reset() {
        if (let Some(clear) <- clearTimeoutFunc) {
            if (ttidTimerId >= 0) {
                clear(ttidTimerId)
                ttidTimerId = -1
            }
            if (frameCheckTimerId >= 0) {
                clear(frameCheckTimerId)
                frameCheckTimerId = -1
            }
        }
        activeDetectionSessionId = 0
        phase = DetectionPhase.IDLE
        enterTime = 0
        firstFrameTime = 0
        frameCount = 0
    }

    private func resetBackgroundDetection() {
        if (let Some(clear) <- clearTimeoutFunc) {
            if (backgroundFirstSnapshotTimerId >= 0) {
                clear(backgroundFirstSnapshotTimerId)
            }
            if (backgroundSecondSnapshotTimerId >= 0) {
                clear(backgroundSecondSnapshotTimerId)
            }
        }
        backgroundFirstSnapshotTimerId = -1
        backgroundSecondSnapshotTimerId = -1
        backgroundDetectionActive = false
        backgroundPageName = ""
        backgroundStartTime = 0
        backgroundFirstDone = false
        backgroundSecondDone = false
        backgroundFirstDistinctColorCount = None
        backgroundSecondDistinctColorCount = None
        backgroundFirstMainColorWhite = None
        backgroundSecondMainColorWhite = None
        backgroundDetectionReason = None
    }

    private func tryReportBackgroundIfReady(): Unit {
        if (!backgroundDetectionActive) {
            return
        }
        if (!backgroundFirstDone || !backgroundSecondDone) {
            return
        }
        let first = backgroundFirstDistinctColorCount ?? -1
        let second = backgroundSecondDistinctColorCount ?? -1
        let firstWhite = backgroundFirstMainColorWhite ?? false
        let secondWhite = backgroundSecondMainColorWhite ?? false
        if (first <= config.maxDistinctColorCount &&
            second <= config.maxDistinctColorCount &&
            firstWhite && secondWhite) {
            let elapsedMs = Float64(DateTime.now().toUnixTimeStamp().toNanoseconds() - backgroundStartTime) / 1_000_000.0
            let eventInfo = InteropWhiteScreenEventInfo(
                backgroundPageName,
                WhiteScreenType.CONTENT_MISSING.toString(),
                WhiteScreenScene.PAGE_BACKGROUND.toString(),
                appState.toString(),
                0.0,
                elapsedMs,
                -1,
                false,
                first,
                second,
                firstWhite,
                secondWhite,
                backgroundDetectionReason.getOrThrow(),
                0
            )
            reportWhiteScreen(eventInfo)
        }
        resetBackgroundDetection()
    }

    // --------------------------------------------------------
    // 阶段一：TTID 首帧超时检测
    // --------------------------------------------------------

    public func startDetection(pageName: String) {
        reset()
        currentPageName = pageName
        let sessionId = createDetectionSessionId()
        enterTime = DateTime.now().toUnixTimeStamp().toNanoseconds()
        phase = DetectionPhase.WAITING_FIRST_FRAME

        printLog("WhiteScreen: start detection for page '" + pageName + "', sessionId=" + sessionId.toString() + ", appState=" + appState.toString())

        // 启动 TTID 超时定时器
        if (let Some(setTimeout) <- setTimeoutFunc) {
            ttidTimerId = setTimeout("ttidTimeout_" + sessionId.toString(), config.ttidTimeoutMs)
        }

        printLog("WhiteScreen: waiting for first frame")
    }

    // ArkTS 侧收到首帧后调用此方法
    public func onFirstFrameReceived(): Unit {
        match (phase) {
            case DetectionPhase.WAITING_FIRST_FRAME => ()
            case _ => return
        }

        firstFrameTime = DateTime.now().toUnixTimeStamp().toNanoseconds()
        let ttidNanos = firstFrameTime - enterTime
        let ttidMs = Float64(ttidNanos) / 1_000_000.0

        printLog("WhiteScreen: first frame received, TTID = " + ttidMs.toString() + "ms")

        // 清除 TTID 超时定时器
        if (let Some(clear) <- clearTimeoutFunc) {
            if (ttidTimerId >= 0) {
                clear(ttidTimerId)
                ttidTimerId = -1
            }
        }

        phase = DetectionPhase.COUNTING_FRAMES
        frameCount = 1

        // 启动帧检查定时器
        if (let Some(setTimeout) <- setTimeoutFunc) {
            frameCheckTimerId = setTimeout("frameCheckTimeout_" + activeDetectionSessionId.toString(), config.frameCheckDurationMs)
        }
    }

    // ArkTS 侧每次帧回调调用此方法
    public func onFrameReceived(): Unit {
        match (phase) {
            case DetectionPhase.COUNTING_FRAMES => frameCount += 1
            case _ => ()
        }
    }

    public func onTtidTimeout() {
        match (phase) {
            case DetectionPhase.WAITING_FIRST_FRAME => ()
            case _ => return
        }
        printLog("WhiteScreen: TTID timeout for page: " + currentPageName)

        phase = DetectionPhase.IDLE

        let eventInfo = InteropWhiteScreenEventInfo(
            currentPageName,
            WhiteScreenType.TIMEOUT.toString(),
            WhiteScreenScene.PAGE_OPEN.toString(),
            appState.toString(),
            Float64(config.ttidTimeoutMs),
            0.0,
            -1,
            false,
            -1,
            -1,
            false,
            false,
            "",
            0
        )
        reportWhiteScreen(eventInfo)
    }

    // --------------------------------------------------------
    // 应用前后台状态处理
    // --------------------------------------------------------

    public func onForeground(): Unit {
        appState = WhiteScreenAppState.FOREGROUND
        printLog("WhiteScreen: app state changed to FOREGROUND")
        if (backgroundDetectionActive) {
            printLog("WhiteScreen: finishing background detection safely")
        }
        resetBackgroundDetection()
    }

    public func onBackground(): Unit {
        appState = WhiteScreenAppState.BACKGROUND
        printLog("WhiteScreen: app state changed to BACKGROUND")
        let pageName = currentPageName
        let nowNanos = DateTime.now().toUnixTimeStamp().toNanoseconds()
        let pageOpenDetectionRunning = isPageOpenDetectionRunning()
        let gateReason = getBackgroundGateReason(nowNanos, pageOpenDetectionRunning)
        if (gateReason.isNone()) {
            printLog("WhiteScreen: skip background detection")
            reset()
            resetBackgroundDetection()
            return
        }
        if (let Some(reason) <- gateReason) {
            reset()
            resetBackgroundDetection()
            let sessionId = createBackgroundSessionId()
            backgroundPageName = pageName
            backgroundStartTime = nowNanos
            backgroundDetectionActive = true
            backgroundDetectionReason = Some(reason)
            printLog("WhiteScreen: start background detection session=" + sessionId.toString())
            if (let Some(setTimeout) <- setTimeoutFunc) {
                backgroundFirstSnapshotTimerId = setTimeout(
                    "bgFirst_" + sessionId.toString(),
                    config.backgroundFirstSnapshotDelayMs
                )
                backgroundSecondSnapshotTimerId = setTimeout(
                    "bgSecond_" + sessionId.toString(),
                    config.backgroundSecondSnapshotDelayMs
                )
            }
        }
    }

    // --------------------------------------------------------
    // 阶段二：N 秒渲染活跃度检测
    // --------------------------------------------------------

    public func onFrameCheckTimeout() {
        match (phase) {
            case DetectionPhase.COUNTING_FRAMES => ()
            case _ => return
        }

        printLog("WhiteScreen: frame check done, frameCount = " + frameCount.toString() +
                 " (threshold = " + config.minFrameCountThreshold.toString() + ")")

        if (frameCount >= config.minFrameCountThreshold) {
            printLog("WhiteScreen: frame activity is high, skip snapshot, frameCount=" + frameCount.toString())
            finishDetectionSession()
            return
        }

        phase = DetectionPhase.SNAPSHOT_ANALYSIS
        performSnapshotAnalysis()
    }

    // --------------------------------------------------------
    // 阶段三：截图分析（由 ArkTS 侧执行快照获取和颜色分析）
    // --------------------------------------------------------

    private func performSnapshotAnalysis() {
        if (let Some(performSnapshot) <- performSnapshotFunc) {
            printLog("WhiteScreen: triggering async snapshot analysis")
            performSnapshot()
        } else {
            printLog("WhiteScreen: performSnapshotFunc is None, skip snapshot analysis")
            phase = DetectionPhase.IDLE
        }
    }

    // ArkTS 侧完成快照分析后调用此方法
    public func performSnapshotAndAnalyze(): Unit {
        match (phase) {
            case DetectionPhase.SNAPSHOT_ANALYSIS => ()
            case _ => return
        }

        printLog("WhiteScreen: performSnapshotAndAnalyze called, waiting for ArkTS callback")
    }

    // ArkTS 侧完成快照分析后调用
    public func onSnapshotAnalysisResult(colorData: String): Unit {
        match (phase) {
            case DetectionPhase.SNAPSHOT_ANALYSIS => ()
            case _ => return
        }

        let distinctCount = parseDistinctColorCount(colorData)
        let mainColorWhite = parseMainColorWhite(colorData)
        printLog("WhiteScreen: distinctColors=" + distinctCount.toString() + ", mainColorWhite=" + mainColorWhite.toString() + ", frameCount=" + frameCount.toString())

        if (distinctCount <= config.maxDistinctColorCount && mainColorWhite) {
            let ttidNanos = firstFrameTime - enterTime
            let ttidMs = Float64(ttidNanos) / 1_000_000.0

            let eventInfo = InteropWhiteScreenEventInfo(
                currentPageName,
                WhiteScreenType.CONTENT_MISSING.toString(),
                WhiteScreenScene.PAGE_OPEN.toString(),
                appState.toString(),
                ttidMs,
                0.0,
                distinctCount,
                mainColorWhite,
                -1,
                -1,
                false,
                false,
                "",
                frameCount
            )
            reportWhiteScreen(eventInfo)
        } else {
            printLog("WhiteScreen: snapshot analysis passed, no white screen")
        }

        phase = DetectionPhase.IDLE
    }

    // --------------------------------------------------------
    // 后台检测快照回调
    // --------------------------------------------------------

    public func onBackgroundFirstSnapshotTimeout(): Unit {
        if (!backgroundDetectionActive) {
            printLog("WhiteScreen: ignore stale background first snapshot timeout")
            return
        }

        backgroundFirstSnapshotTimerId = -1
        printLog("WhiteScreen: background first snapshot for page: " + backgroundPageName)

        if (let Some(performSnapshot) <- performBackgroundSnapshotFunc) {
            performSnapshot(1)
        }
    }

    public func onBackgroundSecondSnapshotTimeout(): Unit {
        if (!backgroundDetectionActive) {
            printLog("WhiteScreen: ignore stale background second snapshot timeout")
            return
        }

        backgroundSecondSnapshotTimerId = -1
        printLog("WhiteScreen: background second snapshot for page: " + backgroundPageName)

        if (let Some(performSnapshot) <- performBackgroundSnapshotFunc) {
            performSnapshot(2)
        }
    }

    // ArkTS 侧完成后台快照分析后调用
    public func onBackgroundSnapshotAnalysisResult(sampleIndex: Int64, colorData: String): Unit {
        if (!backgroundDetectionActive) {
            return
        }
        let distinctCount = parseDistinctColorCount(colorData)
        let mainColorWhite = parseMainColorWhite(colorData)
        printLog("WhiteScreen: background sampleIndex=" + sampleIndex.toString() +
                 ", distinctColors=" + distinctCount.toString() + ", mainColorWhite=" + mainColorWhite.toString())

        if (sampleIndex == 1) {
            backgroundFirstDistinctColorCount = Some(distinctCount)
            backgroundFirstMainColorWhite = Some(mainColorWhite)
            backgroundFirstDone = true
            printLog("WhiteScreen: background first done, count=" + distinctCount.toString())
        }

        if (sampleIndex == 2) {
            backgroundSecondDistinctColorCount = Some(distinctCount)
            backgroundSecondMainColorWhite = Some(mainColorWhite)
            backgroundSecondDone = true
            printLog("WhiteScreen: background second done, count=" + distinctCount.toString())
        }

        if (!backgroundFirstDone || !backgroundSecondDone) {
            return
        }

        let first = backgroundFirstDistinctColorCount.getOrThrow()
        let second = backgroundSecondDistinctColorCount.getOrThrow()
        let firstWhite = backgroundFirstMainColorWhite.getOrThrow()
        let secondWhite = backgroundSecondMainColorWhite.getOrThrow()

        let elapsedMs =
            Float64(DateTime.now().toUnixTimeStamp().toNanoseconds() - backgroundStartTime) / 1_000_000.0

        let isWhiteScreen =
            first <= config.maxDistinctColorCount &&
            second <= config.maxDistinctColorCount &&
            firstWhite && secondWhite

        if (isWhiteScreen) {
            let eventInfo = InteropWhiteScreenEventInfo(
                backgroundPageName,
                WhiteScreenType.CONTENT_MISSING.toString(),
                WhiteScreenScene.PAGE_BACKGROUND.toString(),
                appState.toString(),
                0.0,
                elapsedMs,
                -1,
                false,
                first,
                second,
                firstWhite,
                secondWhite,
                backgroundDetectionReason.getOrThrow(),
                0
            )
            reportWhiteScreen(eventInfo)
        } else {
            printLog("WhiteScreen: background snapshot passed, no white screen")
        }

        // =========================
        // 统一收尾（只执行一次）
        // =========================
        resetBackgroundDetection()
    }

    private func isBackgroundDoubleSnapshotWhiteScreen(): Bool {
        if (let Some(firstCount) <- backgroundFirstDistinctColorCount) {
            if (let Some(secondCount) <- backgroundSecondDistinctColorCount) {
                if (let Some(firstWhite) <- backgroundFirstMainColorWhite) {
                    if (let Some(secondWhite) <- backgroundSecondMainColorWhite) {
                        return firstCount <= config.maxDistinctColorCount &&
                            secondCount <= config.maxDistinctColorCount &&
                            firstWhite && secondWhite
                    }
                }
            }
        }
        false
    }

    // --------------------------------------------------------
    // 颜色数据分析
    // --------------------------------------------------------

    private func parseDistinctColorCount(colorData: String): Int64 {
        try {
            let key = "\"distinctCount\":"
            match (colorData.indexOf(key)) {
                case Some(idx) =>
                    let startIdx = idx + key.size
                    var i = startIdx
                    while (i < colorData.size && (colorData[i] == b' ' || colorData[i] == b'\t')) {
                        i++
                    }
                    let sb = StringBuilder()
                    while (i < colorData.size) {
                        let ch = colorData[i]
                        if (ch >= b'0' && ch <= b'9') {
                            sb.append(Rune(Int32(ch)))
                            i++
                        } else {
                            break
                        }
                    }
                    let numStr = sb.toString()
                    if (!numStr.isEmpty()) {
                        return Int64.parse(numStr)
                    }
                case None => ()
            }
        } catch (e: Exception) {
            AppLog.warn("hm-metricx-cj: parseDistinctColorCount failed: " + e.toString())
        }
        999
    }

    private func parseMainColorWhite(colorData: String): Bool {
        try {
            let key = "\"mainColorWhite\":"
            match (colorData.indexOf(key)) {
                case Some(idx) =>
                    let startIdx = idx + key.size
                    var i = startIdx
                    while (i < colorData.size && (colorData[i] == b' ' || colorData[i] == b'\t')) {
                        i++
                    }
                    if (i < colorData.size && (colorData[i] == b't' || colorData[i] == b'T')) {
                        return true
                    }
                case None => ()
            }
        } catch (e: Exception) {
            AppLog.warn("hm-metricx-cj: parseMainColorWhite failed: " + e.toString())
        }
        false
    }

    // --------------------------------------------------------
    // 阶段四：上报
    // --------------------------------------------------------

    private func reportWhiteScreen(eventInfo: InteropWhiteScreenEventInfo) {
        printLog("WhiteScreen: detected! scene=" + eventInfo.whiteScreenScene)
        if (activeDetectionSessionId == 0 && eventInfo.whiteScreenScene == WhiteScreenScene.PAGE_OPEN.toString()) {
            printLog("WhiteScreen: drop report due to invalid session")
            return
        }
        if (let Some(cb) <- reportCallback) {
            cb(eventInfo)
        }
    }

    // --------------------------------------------------------
    // 条件编译日志
    // --------------------------------------------------------

    @When[debug]
    private func printLog(msg: String) {
        AppLog.warn("hm-metricx-cj: " + msg)
    }

    @When[!debug]
    private func printLog(msg: String) {}
}

// ============================================================
// 定时器回调处理（由 ArkTS 侧调用）
// ============================================================

public func handleWhiteScreenTimerCallback(timerType: String): Unit {
    if (timerType.contains("ttidTimeout")) {
        WhiteScreenDetector.GetInstance().onTtidTimeout()
    } else if (timerType.contains("frameCheckTimeout")) {
        WhiteScreenDetector.GetInstance().onFrameCheckTimeout()
    } else if (timerType.contains("bgFirst")) {
        WhiteScreenDetector.GetInstance().onBackgroundFirstSnapshotTimeout()
    } else if (timerType.contains("bgSecond")) {
        WhiteScreenDetector.GetInstance().onBackgroundSecondSnapshotTimeout()
    }
}

// ============================================================
// 路由切换回调处理（由 ArkTS 侧调用）
// ============================================================

public func onNavDestinationSwitchInternal(fromPageName: String, toPageName: String, fromHidden: Bool, toShown: Bool): Unit {
    if (toShown && !toPageName.isEmpty()) {
        WhiteScreenDetector.GetInstance().startDetection(toPageName)
    }
}

// ============================================================
// 初始化入口（内部版本）
// ============================================================

public func initWhiteScreenHandlerInternal(
    config: WhiteScreenConfig,
    reportCallback: (info: InteropWhiteScreenEventInfo) -> Unit,
    setTimeoutFunc: (String, Int64) -> Int64,
    clearTimeoutFunc: (Int64) -> Unit,
    performSnapshotFunc: () -> Unit,
    performBackgroundSnapshotFunc: (Int64) -> Unit
): Unit {
    let detector = WhiteScreenDetector.GetInstance()
    detector.destroy()
    detector.configure(config, reportCallback, setTimeoutFunc, clearTimeoutFunc, performSnapshotFunc, performBackgroundSnapshotFunc)
}

public func destroyWhiteScreenHandlerInternal(): Unit {
    let detector = WhiteScreenDetector.GetInstance()
    detector.destroy()
}