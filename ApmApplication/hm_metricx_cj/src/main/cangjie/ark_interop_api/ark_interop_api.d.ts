export declare class SwipeKillInfo {
    timestamp: number
    isUserSwipeKill: boolean
    exitInfo: string
    toString(): string
}

export declare class InteropRawheapInfo {
    filePath: string | undefined
    fileSize: number | undefined
    timestamp: string | undefined
    pid: string | undefined
    rsEventTime: string | undefined
    crashTime: string | undefined
    resourceType: string | undefined
    memoryLimit: number | undefined
    currentMemory: number | undefined
    logMessage: string | undefined
}

export declare class RawheapInfo {
    filePath: string
    fileSize: number
    timestamp: string
    pid: string
    rsEventTime: string
    crashTime: string
    resourceType: string
    memoryLimit: number
    currentMemory: number
    logMessage: string
}



export declare class InteropBackgroundCpuMonitorConfig {
    cpuThreshold: number
    warnDurationMs: number
    errorDurationMs: number
    fatalDurationMs: number
    sampleIntervalMs: number
    windowSizeMs: number
}

export declare class InteropAppStateInfo {
    appState: string
    stateChangeTime: number
    timestamp: number
}

export declare class InteropExitInfo {
    exitMessage: string
    exitReason: string
    isBackground: boolean
    appState: string
    stateChangeTime: number
    timestamp: number
}

export declare class CMemMonitorConfig {
    shouldBeClusteredToThisSo: (varArg0: string) => boolean
}

export declare class InteropCrashInfo {
    language: string | undefined
    meminfo: string | undefined
    timestamp: string | undefined
    pid: string | undefined
    pname: string | undefined
    stacktrace: string | undefined
    hilog: string | undefined
    tid: string | undefined
    tname: string | undefined
    fds: string | undefined
    limits: string | undefined
    threads: string | undefined
    extraInfo: string | undefined
    dumpOnOOMPath: string | undefined
    appVersion: string | undefined
    rawFile: string | undefined
    systemLog: string | undefined
    lastNHilog: string | undefined
    dumpTime: string | undefined
    historyRawFiles: string | undefined
    nativeMemDetail: string | undefined
    memPersistTime: string | undefined
    rawheapFilePath: string | undefined
    rawheapTimestamp: string | undefined
    rawheapResourceType: string | undefined
    rawheapMemoryLimit: number | undefined
    rawheapCurrentMemory: number | undefined
    rawheapLogMessage: string | undefined
}

export declare class InteropAllThreadCpuUsageInfo {
    threadCpuUsageInfoList: Array<InteropThreadCpuUsageInfo>
}

export declare class InteropThreadCpuUsageInfo {
    threadId: number
    threadName: string
    threadState: string
    threadJiffiesPercent: number
    threadJiffies: number
    totalJiffies: number
    startBgTime: number
    exceptionTime: number
}

export declare interface BatteryInfoInterface {
    getBatterySOC: () => number
    getChargingStatus: () => number
    getHealthStatus: () => number
    getPluggedType: () => number
    getVoltage: () => number
    getTechnology: () => string
    getBatteryTemperature: () => number
}

export declare class InteropBatteryUsageInfo {
    currentPageName: string | undefined
    level: number | undefined
    temperature: number | undefined
    capacity: number | undefined
    scale: number | undefined
    status: number | undefined
    health: number | undefined
    voltage: number | undefined
    technology: string | undefined
    plugged: number | undefined
    charging: boolean | undefined
    limit: number | undefined
    brightness: number | undefined
    useTime: number | undefined
    time: number | undefined
}

export declare class ClickInfo {
    timestamp: number
    windowX: number
    windowY: number
    id: string
    nodeType: string
    hitX: number
    hitY: number
    hitHeight: number
    hitWidth: number
}

export declare interface AppHooks {
    onAppStateChange: (onFg: () => void, onBg: () => void) => void
    onNavDestinationSwitch: (cb: (funcArg0: string) => void) => void
}

export declare class InteropPageResponseLaggyModel {
    pageName: string
    touchTimes: number
    laggyTimes: number
    laggyTimeList: Array<number>
}

export declare interface Scheduler {
    setInterval: (cb: () => void, intervalMs: number) => number
    clearInterval: (id: number) => void
}

export declare interface ThermalInfoInterface {
    getThermalLevel: () => number
}

export declare class ResponseEvent {
    pageName: string
    technologyStack: string
    responseTime: number
    descriptionID: string
    nodeType: string
    viewTouchID: string
    touchX: number
    touchY: number
    hitX: number
    hitY: number
    hitWidth: number
    hitHeight: number
}

export declare class InteropThermalEventInfo {
    pageName: string
    prevLevel: number
    level: number
    levelName: string
    levelChange: string
    threshold: number
    isForeground: boolean
    durationMs: number
    timestamp: number
}

export declare class InteropProcessCpuInfo {
    avgCpu: number
    maxCpu: number
    sampleCount: number
    pid: number
}

export declare interface MemoryPreference {
    put: (key: string, value: number) => void
    has: (key: string) => boolean
    get: (key: string, defaultValue: number) => number
}

export declare class InteropProcessMemoryInfo {
    avgMemory: number
    maxMemory: number
    avgCJMemory: number
    maxCJMemory: number
    avgArkTsMemory: number
    maxArkTsMemory: number
    sampleCount: number
    pid: number
    totalMemoryLimit: number
    cjMemoryLimit: number
    arkTsMemoryLimit: number
    isTotalTop: boolean
    isCJTop: boolean
    isArkTsTop: boolean
    memoryAvgUsageRate: number
    memoryMaxUsageRate: number
    cjMemoryAvgUsageRate: number
    cjMemoryMaxUsageRate: number
    arkTsMemoryAvgUsageRate: number
    arkTsMemoryMaxUsageRate: number
}

export declare class InteropPageCpuInfo {
    avgCpu: number
    maxCpu: number
    sampleCount: number
    pageName: string
}

export declare class InteropFreezeInfo {
    timestamp: string | undefined
    pid: string | undefined
    exception: string | undefined
    hilog: string | undefined
    tid: string | undefined
    tname: string | undefined
    extraInfo: string | undefined
    cpuThread: string | undefined
    cpu: string | undefined
    stacktrace: Array<string> | undefined
    rawFile: string | undefined
    historyRawFiles: string | undefined
}

export declare class ScrollHitchInfo {
    minFps: number
    avgFps: number
    frameDropRatio: number
    jankRate: number
    bigJankRate: number
    htLessThan0: number
    ht0To00001: number
    ht00001To0001: number
    ht0001To001: number
    ht001To005: number
    ht005To01: number
    ht01To1: number
    htBiggerThan1: number
    targetFPS: number
    longestLostFrame: number
    totalFrameCount: number
    pageName: string
}

export declare class InteropPageMemoryInfo {
    avgMemory: number
    maxMemory: number
    avgCJMemory: number
    maxCJMemory: number
    avgArkTsMemory: number
    maxArkTsMemory: number
    sampleCount: number
    pageName: string
    totalMemoryLimit: number
    cjMemoryLimit: number
    arkTsMemoryLimit: number
    isTotalTop: boolean
    isCJTop: boolean
    isArkTsTop: boolean
    memoryAvgUsageRate: number
    memoryMaxUsageRate: number
    cjMemoryAvgUsageRate: number
    cjMemoryMaxUsageRate: number
    arkTsMemoryAvgUsageRate: number
    arkTsMemoryMaxUsageRate: number
}

export declare class FpsEventInfo {
    minFps: number
    avgFps: number
    pageName: string
}

export declare interface TrafficPreference {
    put: (key: string, value: string) => void
    has: (key: string) => boolean
    get: (key: string, defaultValue: string) => string
}

export declare class InteropSampleTrafficInfo {
    systemInfo: InteropSystemTrafficInfo
    pageInfoMap: Map<string, InteropPageTrafficInfo>
}

export declare class InteropDayTrafficInfo {
    total: number
    upTotal: number
    downTotal: number
    date: string
}

export declare class InteropPageTrafficInfo {
    total: number
    upTotal: number
    downTotal: number
    pageName: string
}

export declare class InteropSystemTrafficInfo {
    total: number
    upTotal: number
    downTotal: number
    timeStamp: string
}

// ==================== High CPU Monitor 互操作类型定义 ====================

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
}

export declare interface DisplaySync {
    start: () => void
    stop: () => void
    on: (cb: (funcArg0: number, funcArg1: number) => void) => void
    off: () => void
}

export declare interface Logger {
    warn: (content: string) => void
    info: (content: string) => void
}

export declare class InteropStorageInfo {
    appSize: number
    cacheSize: number
    dataSize: number
    totalSize: number
    topStorageFileList: Array<InteropStorageFileInfo>
    exceptionDirList: Array<InteropStorageFileInfo>
}

export declare class InteropStorageFileInfo {
    path: string
    size: number
    subfileList: Array<InteropStorageFileInfo>
    isDir: boolean
}

export declare class ExitInfo {
    exitMessage: string
    exitReason: string
    isBackground: boolean
    appState: string
    stateChangeTime: number
    timestamp: number
}

export declare class AppStateInfo {
    appState: string
    stateChangeTime: number
    timestamp: number
}

export declare interface CustomLib {
    ExitInfo: {new (exitMessage: string, exitReason: string, isBackground: boolean, appState: string, stateChangeTime: number, timestamp: number): ExitInfo}
    AppStateInfo: {new (appState: string, stateChangeTime: number, timestamp: number): AppStateInfo}
    SwipeKillInfo: {new (timestamp: number, isUserSwipeKill: boolean, exitInfo: string): SwipeKillInfo}
    InteropStorageFileInfo: {new (p: string, s: number, ss: Array<InteropStorageFileInfo>, i: boolean): InteropStorageFileInfo}
    InteropStorageInfo: {new (a: number, c: number, d: number, t: number, ts: Array<InteropStorageFileInfo>, es: Array<InteropStorageFileInfo>): InteropStorageInfo}
    InteropSystemTrafficInfo: {new (u: number, d: number, t: string): InteropSystemTrafficInfo}
    InteropPageTrafficInfo: {new (u: number, d: number, p: string): InteropPageTrafficInfo}
    InteropDayTrafficInfo: {new (u: number, d: number, date: string): InteropDayTrafficInfo}
    InteropSampleTrafficInfo: {new (s: InteropSystemTrafficInfo, p: Map<string, InteropPageTrafficInfo>): InteropSampleTrafficInfo}
    FpsEventInfo: {new (minFps: number, avgFps: number, pageName: string): FpsEventInfo}
    InteropPageMemoryInfo: {new (a: number, m: number, acj: number, mcj: number, aark: number, mark: number, s: number, p: string, tml: number, cjl: number, atl: number, itt: boolean, ict: boolean, iat: boolean, maur: number, mmur: number, cmaur: number, cmmur: number, atmaur: number, atmmur: number): InteropPageMemoryInfo}
    ScrollHitchInfo: {new (minFps: number, avgFps: number, frameDropRatio: number, jankRate: number, bigJankRate: number, htLessThan0: number, ht0To00001: number, ht00001To0001: number, ht0001To001: number, ht001To005: number, ht005To01: number, ht01To1: number, htBiggerThan1: number, targetFPS: number, longestLostFrame: number, totalFrameCount: number, pageName: string): ScrollHitchInfo}
    InteropFreezeInfo: {new (): InteropFreezeInfo}
    InteropPageCpuInfo: {new (a: number, m: number, s: number, p: string): InteropPageCpuInfo}
    InteropProcessMemoryInfo: {new (a: number, m: number, acj: number, mcj: number, aark: number, mark: number, s: number, p: number, tml: number, cjl: number, atl: number, itt: boolean, ict: boolean, iat: boolean, maur: number, mmur: number, cmaur: number, cmmur: number, atmaur: number, atmmur: number): InteropProcessMemoryInfo}
    InteropProcessCpuInfo: {new (a: number, m: number, s: number, p: number): InteropProcessCpuInfo}
    InteropThermalEventInfo: {new (): InteropThermalEventInfo}
    ResponseEvent: {new (): ResponseEvent}
    InteropPageResponseLaggyModel: {new (): InteropPageResponseLaggyModel}
    ClickInfo: {new (time: number, wx: number, wy: number, id: string, nodeType: string, hX: number, hY: number, hH: number, hW: number): ClickInfo}
    InteropBatteryUsageInfo: {new (c: string | undefined, l: number | undefined, t: number | undefined, ca: number | undefined, sc: number | undefined, st: number | undefined, h: number | undefined, v: number | undefined, te: string | undefined, p: number | undefined, ch: boolean | undefined, li: number | undefined, b: number | undefined, u: number | undefined, ti: number | undefined): InteropBatteryUsageInfo}
    InteropThreadCpuUsageInfo: {new (threadId: number, threadName: string, threadState: string, threadJiffiesPercent: number, threadJiffies: number, totalJiffies: number, st: number, et: number): InteropThreadCpuUsageInfo}
    InteropAllThreadCpuUsageInfo: {new (t: Array<InteropThreadCpuUsageInfo>): InteropAllThreadCpuUsageInfo}
    InteropCrashInfo: {new (): InteropCrashInfo}
    CMemMonitorConfig: {new (shouldBeClusteredToThisSo: (funcArg0: string) => boolean): CMemMonitorConfig}
    initCrashHandler(addCrashWatcher: (funcArg0: (funcArgfuncArg0: string, funcArgfuncArg1: string, funcArgfuncArg2: string, funcArgfuncArg3: string, funcArgfuncArg4: string, funcArgfuncArg5: string, funcArgfuncArg6: string) => void) => void, onCrash: (funcArg0: () => void) => void, exit: () => void, collectCrashInfo: () => string, reportCrashInfo: (funcArg0: InteropCrashInfo) => void, persistentDir: string, enableDumpOnOOM: number, lastNHilogNumber: number, systemLogNumber: number, enableMemMonitor: CMemMonitorConfig | undefined): void
    getExitInfo(lastExitMessage: string, lastExitReason: number): ExitInfo
    initFreezeHandler(sdkApiVersion: number, addFreezeWatcher: (funcArg0: (funcArgfuncArg0: string, funcArgfuncArg1: string, funcArgfuncArg2: string, funcArgfuncArg3: string, funcArgfuncArg4: string) => void) => void, onFreeze: (funcArg0: () => void) => void, collectFreezeInfo: () => string, reportFreezeInfo: (funcArg0: InteropFreezeInfo) => void, persistentDir: string): void
    initTrafficHandler(preference: TrafficPreference, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleTraffic: (funcArg0: () => void) => void, getUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number, funcArgfuncArg2: string) => void, funcArg1: string) => void, reportTraffic: (funcArg0: InteropSampleTrafficInfo) => void, reportYesterdayTraffic: (funcArg0: InteropDayTrafficInfo) => void, sampleThreshold: number): void
    destroyTrafficHandler(getUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number) => void) => void): void
    initStorageHandler(reportStorageInfo: (funcArg0: InteropStorageInfo) => void, sizeLimit: number, dirSizeLimit: number, reportTopNum: number): void
    reportAppStorageInfo(getCurrentBundleStats: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number, funcArgfuncArg2: number) => void) => void): void
    getPageCpuInfo(): InteropPageCpuInfo
    getProcessCpuInfo(): InteropProcessCpuInfo
    initCpuHandler(getCpuUsage: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportCpu: (funcArg0: () => void, funcArg1: () => void) => void, reporPageCpuInfo: (funcArg0: InteropPageCpuInfo) => void, reporProcessCpuInfo: (funcArg0: InteropProcessCpuInfo) => void): void
    getPageMemoryInfo(): InteropPageMemoryInfo
    getProcessMemoryInfo(): InteropProcessMemoryInfo
    initMemoryHandler(memoryPreference: MemoryPreference, getMemoryUsage: () => number, getArkTsMemoryUsage: () => number, getArkTsTotalHeap: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportMemory: (funcArg0: () => void, funcArg1: () => void, funcArg2: () => void) => void, reporPageMemoryInfo: (funcArg0: InteropPageMemoryInfo) => void, reporProcessMemoryInfo: (funcArg0: InteropProcessMemoryInfo) => void, memoryThreshold: number): void
    destroyMemoryHandler(): void
    initBatteryHandler(subscribe: (funcArg0: () => void, funcArg1: () => void, funcArg2: () => void) => void, getUptime: () => number, batteryInterface: BatteryInfoInterface, getBrightness: () => number, onApplicationStateChange: (funcArg0: () => void, funcArg1: () => void) => void, onAbilityForeground: (funcArg0: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, getRunningProcessInfo: (funcArg0: (funcArgfuncArg0: boolean) => void) => void, repeatHandleCpuUsage: (funcArg0: () => void) => void, reportBatteryInfo: (funcArg0: InteropBatteryUsageInfo) => void, reportThreadCpuUsageInfo: (funcArg0: InteropAllThreadCpuUsageInfo) => void, limit: number): void
    initScrollEventHandler(onDisplay: DisplaySync, onScrollEvect: (funcArg0: () => void, funcArg1: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, reportPageScrollInfo: (funcArg0: ScrollHitchInfo) => void): void
    initPageEventHandler(onDisplay: DisplaySync, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, onWindowEvent: (funcArg0: () => void, funcArg1: () => void) => void, reportFpsInfo: (funcArg0: FpsEventInfo) => void): void
    initLaggyHandler(onDisplay: DisplaySync, onAbilityBackground: (funcArg0: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, onDidClick: (funcArg0: (funcArgfuncArg0: ClickInfo) => void) => void, maxTime: number, maxArraySize: number, reportResponseEvent: (funcArg0: ResponseEvent) => void, reportPageResponseLaggyModel: (funcArg0: InteropPageResponseLaggyModel) => void): void
    initLogger(logger: Logger): void
    initThermalHandler(getUptimeMs: () => number, thermalInterface: ThermalInfoInterface, hooks: AppHooks, repeatSampleThermal: (funcArg0: () => void) => void, stopSampleThermal: () => void, reportThermalInfo: (funcArg0: InteropThermalEventInfo) => void, sampleInterval: number, reportMinInterval: number, abnormalThreshold: number): void
    destroyThermalHandler(): void
    getExitInfoInterop(lastExitMessage: string, lastExitReason: number): ExitInfo
    initStorageHandlerInterop(reportStorageInfo: (funcArg0: InteropStorageInfo) => void, sizeLimit: number, dirSizeLimit: number, reportTopNum: number): void
    reportAppStorageInfoInterop(getCurrentBundleStats: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number, funcArgfuncArg2: number) => void) => void): void
    initPageEventHandlerInterop(onDisplay: DisplaySync, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, onWindowEvent: (funcArg0: () => void, funcArg1: () => void) => void, reportFpsInfo: (funcArg0: FpsEventInfo) => void): void
    initScrollEventHandlerInterop(onDisplay: DisplaySync, onScrollEvect: (funcArg0: () => void, funcArg1: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, reportPageScrollInfo: (funcArg0: ScrollHitchInfo) => void): void
    initBatteryHandlerInterop(subscribe: (funcArg0: () => void, funcArg1: () => void, funcArg2: () => void) => void, getUptime: () => number, batteryInterface: BatteryInfoInterface, getBrightness: () => number, onApplicationStateChange: (funcArg0: () => void, funcArg1: () => void) => void, onAbilityForeground: (funcArg0: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, getRunningProcessInfo: (funcArg0: (funcArgfuncArg0: boolean) => void) => void, repeatHandleCpuUsage: (funcArg0: () => void) => void, reportBatteryInfo: (funcArg0: InteropBatteryUsageInfo) => void, reportThreadCpuUsageInfo: (funcArg0: InteropAllThreadCpuUsageInfo) => void, limit: number): void
    initFreezeHandlerInterop(sdkApiVersion: number, addFreezeWatcher: (funcArg0: (funcArgfuncArg0: string, funcArgfuncArg1: string, funcArgfuncArg2: string, funcArgfuncArg3: string, funcArgfuncArg4: string) => void) => void, onFreeze: (funcArg0: () => void) => void, collectFreezeInfo: () => string, reportFreezeInfo: (funcArg0: InteropFreezeInfo) => void, persistentDir: string): void
    initThermalHandlerInterop(getUptimeMs: () => number, thermalInterface: ThermalInfoInterface, hooks: AppHooks, repeatSampleThermal: (funcArg0: () => void) => void, stopSampleThermal: () => void, reportThermalInfo: (funcArg0: InteropThermalEventInfo) => void, sampleInterval: number, reportMinInterval: number, abnormalThreshold: number): void
    destroyThermalHandlerInterop(): void
    initLaggyHandlerInterop(onDisplay: DisplaySync, onAbilityBackground: (funcArg0: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, onDidClick: (funcArg0: (funcArgfuncArg0: ClickInfo) => void) => void, maxTime: number, maxArraySize: number, reportResponseEvent: (funcArg0: ResponseEvent) => void, reportPageResponseLaggyModel: (funcArg0: InteropPageResponseLaggyModel) => void): void
    getPageCpuInfoInterop(): InteropPageCpuInfo
    getProcessCpuInfoInterop(): InteropProcessCpuInfo
    initCpuHandlerInterop(getCpuUsage: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportCpu: (funcArg0: () => void, funcArg1: () => void) => void, reporPageCpuInfo: (funcArg0: InteropPageCpuInfo) => void, reporProcessCpuInfo: (funcArg0: InteropProcessCpuInfo) => void): void
    getPageMemoryInfoInterop(): InteropPageMemoryInfo
    getProcessMemoryInfoInterop(): InteropProcessMemoryInfo
    initMemoryHandlerInterop(memoryPreference: MemoryPreference, getMemoryUsage: () => number, getArkTsMemoryUsage: () => number, getArkTsMemoryLimit: () => number, getTotalMemoryLimit: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportMemory: (funcArg0: () => void, funcArg1: () => void, funcArg2: () => void) => void, reporPageMemoryInfo: (funcArg0: InteropPageMemoryInfo) => void, reporProcessMemoryInfo: (funcArg0: InteropProcessMemoryInfo) => void, memoryThreshold: number, totalRatio: number, cjRatio: number, arkTsRatio: number): void

    destroyMemoryHandlerInterop(): void
    initTrafficHandlerInterop(preference: TrafficPreference, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleTraffic: (funcArg0: () => void) => void, getUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number, funcArgfuncArg2: string) => void, funcArg1: string) => void, reportTraffic: (funcArg0: InteropSampleTrafficInfo) => void, reportYesterdayTraffic: (funcArg0: InteropDayTrafficInfo) => void, sampleThreshold: number): void
    destroyTrafficHandlerInterop(getUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number) => void) => void): void
    InteropExitInfo: {new (exitMessage: string, exitReason: string, isBackground: boolean, appState: string, stateChangeTime: number, timestamp: number): InteropExitInfo}
    InteropAppStateInfo: {new (appState: string, stateChangeTime: number, timestamp: number): InteropAppStateInfo}
    initExitInfoHandler(lastExitMessage: string, lastExitReason: string, reportExitInfoHandler: (funcArg0: InteropExitInfo) => void, reportAppStateHandler: (funcArg0: InteropAppStateInfo) => void): void
    destroyExitInfoHandler(): void
    destroyExitInfoHandlerWrapper(): void
    // ==================== High CPU Monitor 互操作方法 ====================
    initHighCpuMonitorHandlerInterop(getCpuUsage: () => number, getAppThreadCpuUsageJson: () => string, repeatHighCpuSample: (funcArg0: () => void) => void, repeatHighCpuReport: (funcArg0: () => void) => void, reportHighCpuInfoJson: (funcArg0: string) => void): void
    onAppForegroundInterop(): void
    onAppBackgroundInterop(): void
    startHighCpuMonitorInterop(config: InteropHighCpuMonitorConfig): void
    stopHighCpuMonitorInterop(): void
    triggerHighCpuReportInterop(): void
    isHighCpuMonitoringActiveInterop(): boolean
    InteropHighCpuMonitorConfig: {new (cpuThreshold: number, foregroundIntervalMs: number, backgroundIntervalMs: number, monitorDurationMs: number, threadCooldownMs: number, globalCooldownMs: number, highSampleRatioThreshold: number, topNThreads: number): InteropHighCpuMonitorConfig}

    initExitInfoHandlerInterop(lastExitMessage: string, lastExitReasonValue: number, reportExitInfoHandler: (funcArg0: ExitInfo) => void, reportAppStateHandler: (funcArg0: AppStateInfo) => void): void
    destroyExitInfoHandlerInterop(): void
    initSwipeKillHandlerInterop(lastExitReason: number, reportSwipeKillInfoHandler: (funcArg0: SwipeKillInfo) => void, onAbilityBackground: (cb: () => void) => void, thresholdMs: number): void
    destroySwipeKillHandlerInterop(): void
    initMemoryHandlerInterop(memoryPreference: MemoryPreference, getMemoryUsage: () => number, getArkTsMemoryUsage: () => number, getArkTsTotalHeap: () => number, getTotalMemoryLimit: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportMemory: (funcArg0: () => void, funcArg1: () => void, funcArg2: () => void) => void, reporPageMemoryInfo: (funcArg0: InteropPageMemoryInfo) => void, reporProcessMemoryInfo: (funcArg0: InteropProcessMemoryInfo) => void, memoryThreshold: number, totalRatio: number, cjRatio: number, arkTsRatio: number): void
    InteropBackgroundCpuMonitorConfig: {new (cpuThreshold: number, warnDurationMs: number, errorDurationMs: number, fatalDurationMs: number, sampleIntervalMs: number, windowSizeMs: number): InteropBackgroundCpuMonitorConfig}
    nitBackgroundCpuMonitorHandlerInterop(config: InteropBackgroundCpuMonitorConfig, getAppThreadCpuUsageJson: () => string, repeatSample: (funcArg0: () => void) => void, clearSample: () => void, reportHighCpuInfoJson: (funcArg0: string) => void): void
    destroyBackgroundCpuMonitorHandlerInterop(): void
    initBackgroundCpuMonitorHandlerInterop(config: InteropBackgroundCpuMonitorConfig, getAppThreadCpuUsageJson: () => string, repeatSample: (funcArg0: () => void) => void, clearSample: () => void, reportHighCpuInfoJson: (funcArg0: string) => void): void
    initCrashHandlerInterop(addCrashWatcher: (funcArg0: (funcArgfuncArg0: string, funcArgfuncArg1: string, funcArgfuncArg2: string, funcArgfuncArg3: string, funcArgfuncArg4: string, funcArgfuncArg5: string, funcArgfuncArg6: string) => void) => void, addResourceLeakWatcher: (funcArg0: (funcArgfuncArg0: string, funcArgfuncArg1: string, funcArgfuncArg2: string, funcArgfuncArg3: number, funcArgfuncArg4: number, funcArgfuncArg5: string) => void) => void, onCrash: (funcArg0: () => void) => void, exit: () => void, collectCrashInfo: () => string, reportCrashInfo: (funcArg0: InteropCrashInfo) => void, persistentDir: string, enableDumpOnOOM: number, lastNHilogNumber: number, systemLogNumber: number, enableMemMonitor: CMemMonitorConfig | undefined): void
    RawheapInfo: {new (): RawheapInfo}
    InteropRawheapInfo: {new (): InteropRawheapInfo}
    initSwipeKillHandlerInterop(lastExitReason: number, reportSwipeKillInfoHandler: (funcArg0: SwipeKillInfo) => void, onAbilityBackground: (funcArg0: () => void) => void, thresholdMs: number): void
}