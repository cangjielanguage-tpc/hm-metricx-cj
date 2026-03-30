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

export declare function initCpuHandlerInterop(getCpuUsage: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportCpu: (funcArg0: () => void, funcArg1: () => void) => void, reporPageCpuInfo: (funcArg0: InteropPageCpuInfo) => void, reporProcessCpuInfo: (funcArg0: InteropProcessCpuInfo) => void): void

/**
 * 初始化高 CPU 监控
 */
export declare function initHighCpuMonitorHandlerInterop(
    getCpuUsage: () => number,
    getAppThreadCpuUsageJson: () => string,
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
 * 检查高 CPU 监控是否正在运行
 */
export declare function isHighCpuMonitoringActiveInterop(): boolean
