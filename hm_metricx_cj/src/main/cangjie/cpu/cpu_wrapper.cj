package hm_metricx_cj.cpu

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

/**
 * 设置进程名（包名），供 CPU/高CPU/后台CPU 上报 reportInfo.processName 使用。
 * 由 ArkTS 端在 init 时调用，替代 cpu.cj 内 getpid().toString()（与 pid 字段重复且语义错误）。
 */
@Interop[ArkTS]
public func setProcessNameInterop(name: String): Unit {
    processName = name
}

@Interop[ArkTS]
public func initCpuHandlerInterop(
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatSampleAndReportCpu: (() -> Unit, () -> Unit) -> Unit,
    reporPageCpuInfo: (InteropPageCpuInfo) -> Unit,
    reporProcessCpuInfo: (InteropProcessCpuInfo) -> Unit
): Unit {
    initCpuHandler(onNavDestinationSwitch, repeatSampleAndReportCpu, reporPageCpuInfo, reporProcessCpuInfo)
}

/**
 * 销毁普通 CPU 采样监控（复位 cpu_init_flag 以允许再次 init）。
 */
@Interop[ArkTS]
public func destroyCpuHandlerInterop(): Unit {
    destroyCpuHandler()
}

/**
 * 初始化高 CPU 监控
 *
 * @param onNavDestinationSwitch 页面切换回调（由 ArkTS 传入，用于更新当前页面名称）
 * @param repeatHighCpuSample 重复采样回调（由 ArkTS 传入，用于启动采样定时器）
 * @param repeatHighCpuReport 重复上报回调（由 ArkTS 传入，用于启动上报定时器）
 * @param reportHighCpuInfoJson 高 CPU 占用上报回调（JSON 字符串格式）
 */
@Interop[ArkTS]
public func initHighCpuMonitorHandlerInterop(
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    repeatHighCpuSample: (() -> Unit) -> Unit,
    repeatHighCpuReport: (() -> Unit) -> Unit,
    reportHighCpuInfoJson: (String) -> Unit
): Unit {
    // 包装上报回调，将 HighCpuReportInfo 转换为 JSON 字符串
    let wrappedReportCallback: (info: HighCpuReportInfo) -> Unit = { info =>
        reportHighCpuInfoJson(info.toJson())
    }

    initHighCpuMonitorHandlerInternal(
        onNavDestinationSwitch,
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
 * 抓栈自检：抓取当前线程调用栈并返回符号化文本（tid=0 同步直调，不发信号、无 cooldown）。
 * 供 demo 自检按钮验证 native 抓栈链路，不依赖高 CPU 上报窗口。
 */
@Interop[ArkTS]
public func captureCurrentThreadStackInterop(): String {
    captureCurrentThreadStack()
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
 * @param repeatSample 重复采样回调（由 ArkTS 传入，用于启动采样定时器）
 * @param clearSample 清除采样定时器回调（由 ArkTS 传入）
 * @param reportHighCpuInfoJson 后台 CPU 占用上报回调（JSON 字符串格式）
 */
@Interop[ArkTS]
public func initBackgroundCpuMonitorHandlerInterop(
    config: InteropBackgroundCpuMonitorConfig,
    repeatSample: (() -> Unit) -> Unit,
    clearSample: () -> Unit,
    reportHighCpuInfoJson: (String) -> Unit
): Unit {
    let wrappedReportCallback: (info: BackgroundCpuReportInfo) -> Unit = { info =>
        reportHighCpuInfoJson(info.toJson())
    }

    initBackgroundCpuMonitorHandlerInternal(
        config,
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
