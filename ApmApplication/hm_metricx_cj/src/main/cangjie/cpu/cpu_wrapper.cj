package ohos_app_cangjie_hm_metricx_cj.cpu

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

@Interop[ArkTS]
public func getPageCpuInfoInterop(): InteropPageCpuInfo {
    getPageCpuInfo()
}

@Interop[ArkTS]
public func getProcessCpuInfoInterop(): InteropProcessCpuInfo {
    getProcessCpuInfo()
}

@Interop[ArkTS]
public func initCpuHandlerInterop(
    getCpuUsage: () -> Float64,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatSampleAndReportCpu: (() -> Unit, () -> Unit) -> Unit,
    reporPageCpuInfo: (InteropPageCpuInfo) -> Unit,
    reporProcessCpuInfo: (InteropProcessCpuInfo) -> Unit
): Unit {
    initCpuHandler(getCpuUsage, onNavDestinationSwitch, repeatSampleAndReportCpu, reporPageCpuInfo, reporProcessCpuInfo)
}

/**
 * 初始化高 CPU 监控
 *
 * @param getCpuUsage 获取 CPU 使用率的回调（由 ArkTS 传入）
 * @param getAppThreadCpuUsageJson 获取线程 CPU 使用率 JSON 的回调（由 ArkTS 传入）
 * @param repeatHighCpuSample 重复采样回调（由 ArkTS 传入，用于启动采样定时器）
 * @param repeatHighCpuReport 重复上报回调（由 ArkTS 传入，用于启动上报定时器）
 * @param reportHighCpuInfoJson 高 CPU 占用上报回调（JSON 字符串格式）
 */
@Interop[ArkTS]
public func initHighCpuMonitorHandlerInterop(
    getCpuUsage: () -> Float64,
    getAppThreadCpuUsageJson: () -> String,
    repeatHighCpuSample: (() -> Unit) -> Unit,
    repeatHighCpuReport: (() -> Unit) -> Unit,
    reportHighCpuInfoJson: (String) -> Unit
): Unit {
    // 包装上报回调，将 HighCpuReportInfo 转换为 JSON 字符串
    let wrappedReportCallback: (info: HighCpuReportInfo) -> Unit = { info =>
        reportHighCpuInfoJson(info.toJson())
    }

    initHighCpuMonitorHandlerInternal(
        getCpuUsage,
        getAppThreadCpuUsageJson,
        repeatHighCpuSample,
        repeatHighCpuReport,
        wrappedReportCallback
    )
}

/**
 * 应用进入前台时调用
 */
@Interop[ArkTS]
public func onAppForegroundInterop(): Unit {
    onAppForegroundInternal()
}

/**
 * 应用进入后台时调用
 */
@Interop[ArkTS]
public func onAppBackgroundInterop(): Unit {
    onAppBackgroundInternal()
}

/**
 * 开始高 CPU 监控
 *
 * @param config 高 CPU 监控配置
 */
@Interop[ArkTS]
public func startHighCpuMonitorInterop(config: InteropHighCpuMonitorConfig): Unit {
    startHighCpuMonitorInternal(config)
}

/**
 * 停止高 CPU 监控
 */
@Interop[ArkTS]
public func stopHighCpuMonitorInterop(): Unit {
    stopHighCpuMonitorInternal()
}

/**
 * 手动触发高 CPU 占用上报
 */
@Interop[ArkTS]
public func triggerHighCpuReportInterop(): Unit {
    triggerHighCpuReportInternal()
}

/**
 * 检查高 CPU 监控是否正在运行
 *
 * @return true=监控正在运行，false=监控未启动或已停止
 */
@Interop[ArkTS]
public func isHighCpuMonitoringActiveInterop(): Bool {
    isHighCpuMonitoringActiveInternal()
}

/**
 * 初始化后台活动超长率监控
 *
 * @param config 后台 CPU 监控配置
 * @param getAppThreadCpuUsageJson 获取线程 CPU 使用率 JSON 的回调（由 ArkTS 传入）
 * @param repeatSample 重复采样回调（由 ArkTS 传入，用于启动采样定时器）
 * @param clearSample 清除采样定时器回调（由 ArkTS 传入）
 * @param reportHighCpuInfoJson 后台 CPU 占用上报回调（JSON 字符串格式）
 */
@Interop[ArkTS]
public func initBackgroundCpuMonitorHandlerInterop(
    config: InteropBackgroundCpuMonitorConfig,
    getAppThreadCpuUsageJson: () -> String,
    repeatSample: (() -> Unit) -> Unit,
    clearSample: () -> Unit,
    reportHighCpuInfoJson: (String) -> Unit
): Unit {
    let wrappedReportCallback: (info: BackgroundCpuReportInfo) -> Unit = { info =>
        reportHighCpuInfoJson(info.toJson())
    }

    initBackgroundCpuMonitorHandlerInternal(
        config,
        getAppThreadCpuUsageJson,
        repeatSample,
        clearSample,
        wrappedReportCallback
    )
}

/**
 * 销毁后台活动超长率监控
 */
@Interop[ArkTS]
public func destroyBackgroundCpuMonitorHandlerInterop(): Unit {
    destroyBackgroundCpuMonitorHandlerInternal()
}
