export declare class InteropProcessCpuInfo {
    avgCpu: number
    maxCpu: number
    sampleCount: number
    pid: number
    constructor (a: number, m: number, s: number, p: number)
}

export declare class InteropPageCpuInfo {
    avgCpu: number
    maxCpu: number
    sampleCount: number
    pageName: string
    constructor (a: number, m: number, s: number, p: string)
}

/**
 * 高 CPU 监控配置
 */
export declare class InteropHighCpuMonitorConfig {
    cpuThreshold: number
    foregroundIntervalMs: number
    backgroundIntervalMs: number
    monitorDurationMs: number
    threadCooldownMs: number
    globalCooldownMs: number
    highSampleRatioThreshold: number
    topNThreads: number
    constructor (
        cpuThreshold: number,
        foregroundIntervalMs: number,
        backgroundIntervalMs: number,
        monitorDurationMs: number,
        threadCooldownMs: number,
        globalCooldownMs: number,
        highSampleRatioThreshold: number,
        topNThreads: number
    )
}

export declare function getPageCpuInfoInterop(): InteropPageCpuInfo

export declare function getProcessCpuInfoInterop(): InteropProcessCpuInfo

/**
 * 设置进程名（包名），供 CPU/高CPU/后台CPU 上报 reportInfo.processName 使用。
 */
export declare function setProcessNameInterop(name: string): void

/**
 * 销毁普通 CPU 采样监控（复位 cpu_init_flag 以允许再次 init）。
 */
export declare function destroyCpuHandlerInterop(): void

export declare function initCpuHandlerInterop(onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportCpu: (funcArg0: () => void, funcArg1: () => void) => void, reporPageCpuInfo: (funcArg0: InteropPageCpuInfo) => void, reporProcessCpuInfo: (funcArg0: InteropProcessCpuInfo) => void): void

/**
 * 初始化高 CPU 监控
 */
export declare function initHighCpuMonitorHandlerInterop(
    onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void,
    repeatHighCpuSample: (funcArg0: () => void) => void,
    repeatHighCpuReport: (funcArg0: () => void) => void,
    reportHighCpuInfoJson: (funcArg0: string) => void
): void

/**
 * 应用进入前台时调用
 */
export declare function onAppForegroundInterop(): void

/**
 * 应用进入后台时调用
 */
export declare function onAppBackgroundInterop(): void

/**
 * 开始高 CPU 监控
 */
export declare function startHighCpuMonitorInterop(config: InteropHighCpuMonitorConfig): void

/**
 * 停止高 CPU 监控
 */
export declare function stopHighCpuMonitorInterop(): void

/**
 * 手动触发高 CPU 占用上报
 */
export declare function triggerHighCpuReportInterop(): void

/**
 * 抓栈自检：抓取当前线程调用栈并返回符号化文本（tid=0 同步直调，不发信号、无 cooldown）。
 * 供 demo 自检按钮验证 native 抓栈链路，不依赖高 CPU 上报窗口。
 */
export declare function captureCurrentThreadStackInterop(): string

/**
 * 检查高 CPU 监控是否正在运行
 */
export declare function isHighCpuMonitoringActiveInterop(): boolean

/**
 * 后台监控配置互操作类
 */
export declare class InteropBackgroundCpuMonitorConfig {
    cpuThreshold: number
    warnDurationMs: number
    errorDurationMs: number
    fatalDurationMs: number
    sampleIntervalMs: number
    windowSizeMs: number
    topNThreads: number
    threadCooldownMs: number
    globalCooldownMs: number
    constructor (
        cpuThreshold: number,
        warnDurationMs: number,
        errorDurationMs: number,
        fatalDurationMs: number,
        sampleIntervalMs: number,
        windowSizeMs: number,
        topNThreads: number,
        threadCooldownMs: number,
        globalCooldownMs: number
    )
}

/**
 * 初始化后台活动超长率监控
 */
export declare function initBackgroundCpuMonitorHandlerInterop(
    config: InteropBackgroundCpuMonitorConfig,
    repeatSample: (funcArg0: () => void) => void,
    clearSample: () => void,
    reportHighCpuInfoJson: (funcArg0: string) => void
): void

/**
 * 销毁后台活动超长率监控
 */
export declare function destroyBackgroundCpuMonitorHandlerInterop(): void