package ohos_app_cangjie_hm_metricx_cj.fps

import ohos.ark_interop.*
import ohos.ark_interop_macro.*
import std.convert.*
import ohos.base.AppLog
import std.time.DateTime

var frt_init_flag: Bool = false

// 首帧渲染时间信息类（互操作版本）
@Interop[ArkTS]
public class InteropFirstRenderTimeInfo {
    public let startTime: Int64
    public let endTime: Int64
    public let duration: Int64
    public let targetPage: String

    public init(startTime: Int64, endTime: Int64, duration: Int64, targetPage: String) {
        this.startTime = startTime
        this.endTime = endTime
        this.duration = duration
        this.targetPage = targetPage
    }
}

// 首帧渲染时间配置类（互操作版本）
@Interop[ArkTS]
public class InteropFirstRenderTimeConfig {
    public let enableLogging: Bool
    public let reportThreshold: Int64

    public init(enableLogging: Bool, reportThreshold: Int64) {
        this.enableLogging = enableLogging
        this.reportThreshold = reportThreshold
    }
}

// 首帧渲染时间监控器
public class FirstRenderTimeMonitor {
    private static var instance = FirstRenderTimeMonitor()
    public static func GetInstance() { instance }

    // 内部状态
    private var clickStartTime: Int64 = 0
    private var navigationTargetPage: ?String = None
    private var config: InteropFirstRenderTimeConfig = InteropFirstRenderTimeConfig(false, 1000)

    private var drawEndTime: Int64 = 0
    private var isWaitingDraw: Bool = false

    // 回调函数
    private var reportCallback: Option<(info: InteropFirstRenderTimeInfo) -> Unit> = None

    // 设置配置
    public func setConfig(config: InteropFirstRenderTimeConfig): Unit {
        this.config = config
    }

    // 设置上报回调
    public func setReportCallback(callback: (info: InteropFirstRenderTimeInfo) -> Unit): Unit {
        this.reportCallback = Some(callback)
    }

    // 记录点击开始时间
    public func recordClickStart() {
        if (isWaitingDraw) {
            if (config.enableLogging) {
                AppLog.warn("FRT click ignored, previous flow not finished")
            }
            return
        }
        clickStartTime = DateTime.now().toUnixTimeStamp().toMilliseconds()
        if (config.enableLogging) {
            AppLog.info("FRT click at: ${clickStartTime} ms")
        }
    }

    // 记录导航目标页面
    public func recordNavigationTarget(targetPage: String): Unit {
        navigationTargetPage = Some(targetPage)
        isWaitingDraw = true

        if (config.enableLogging) {
            AppLog.info("FRT nav: " + targetPage)
        }
    }

    // 手动计算首帧渲染时间
    public func calculateFirstRenderTimeManually(startTime: Int64, targetPage: String): Unit {
        let endTime = DateTime.now().toUnixTimeStamp().toMilliseconds()
        let duration = endTime - startTime
        if (duration >= config.reportThreshold) {
            let frtInfo = InteropFirstRenderTimeInfo(startTime, endTime, duration, targetPage)
            if (config.enableLogging) {
                AppLog.info("FirstRenderTimeMonitor Manual calculation - First render time for " + targetPage + ": " + duration.toString() + "ms")
            }
            if (let Some(cb) <- reportCallback) {
                cb(frtInfo)
            }
        }
    }

    // 超时兜底：使用内部已记录的 clickStartTime 计算首帧渲染时间
    public func calculateFirstRenderTime(targetPage: String): Unit {
        let endTime = DateTime.now().toUnixTimeStamp().toMilliseconds()
        let duration = endTime - clickStartTime
        if (duration >= config.reportThreshold) {
            let info = InteropFirstRenderTimeInfo(clickStartTime, endTime, duration, targetPage)
            if (config.enableLogging) {
                AppLog.info("FirstRenderTimeMonitor Timeout fallback - First render time for " + targetPage + ": " + duration.toString() + "ms")
            }
            if (let Some(cb) <- reportCallback) {
                cb(info)
            }
        }
        reset()
    }

    public func recordDrawEnd() {
        if (!isWaitingDraw) {
            return
        }

        drawEndTime = DateTime.now().toUnixTimeStamp().toMilliseconds()
        calculateIfReady()
    }

    private func calculateIfReady(): Unit {
        if (navigationTargetPage.isSome()) {
            let startTime = clickStartTime
            let endTime = drawEndTime
            let duration = endTime - startTime
            let page = navigationTargetPage.getOrThrow()
            if (duration >= config.reportThreshold) {
                let info = InteropFirstRenderTimeInfo(startTime, endTime, duration, page)

                if (let Some(cb) <- reportCallback) {
                    cb(info)
                }
            }
            reset()
        }
    }

    // 重置状态
    public func reset(): Unit {
        clickStartTime = 0
        navigationTargetPage = None
        drawEndTime = 0
        isWaitingDraw = false
        frt_init_flag = false
    }
}