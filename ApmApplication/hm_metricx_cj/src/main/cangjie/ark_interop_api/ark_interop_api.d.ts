export declare interface TrafficPreference {
    put: (key: string, value: string) => void
    has: (key: string) => boolean
    get: (key: string, defaultValue: string) => string
}

export declare class InteropSampleTrafficInfo {
    systemInfo: InteropSystemTrafficInfo
    pageInfoMap: Map<string, InteropPageTrafficInfo>
}

export declare class InteropPageTrafficInfo {
    total: number
    upTotal: number
    downTotal: number
    pageName: string
}

export declare class CMemMonitorConfig {
    shouldBeClusteredToThisSo: (varArg0: string) => boolean
}

export declare class InteropFreezeInfo {
    timestamp: string | undefined
    pid: string | undefined
    exception: string | undefined
    hilog: string | undefined
    tid: string | undefined
    tname: string | undefined
    extraInfo: string | undefined
    freezeLogPath: string | undefined
    cpuThread: Map<string, string> | undefined
    cpu: Map<string, string> | undefined
    stacktrace: Array<string> | undefined
    rawFile: string | undefined
    historyRawFiles: string | undefined
}

export declare class InteropSystemTrafficInfo {
    total: number
    upTotal: number
    downTotal: number
    timeStamp: string
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
    fds: Map<string, string> | undefined
    limits: string | undefined
    threads: string | undefined
    extraInfo: string | undefined
    crashLogPath: string | undefined
    dumpOnOOMPath: string | undefined
    appVersion: string | undefined
    rawFile: string | undefined
    systemLog: string | undefined
    lastNHilog: string | undefined
    dumpTime: string | undefined
    historyRawFiles: string | undefined
    nativeMemDetail: string | undefined
    memPersistTime: string | undefined
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

export declare class InteropPageResponseLaggyModel {
    pageName: string
    touchTimes: number
    laggyTimes: number
    laggyTimeList: Array<number>
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

export declare class InteropProcessCpuInfo {
    avgCpu: number
    maxCpu: number
    sampleCount: number
    pid: number
}

export declare class InteropPageCpuInfo {
    avgCpu: number
    maxCpu: number
    sampleCount: number
    pageName: string
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

export declare interface MemoryPreference {
    put: (key: string, value: number) => void
    has: (key: string) => boolean
    get: (key: string, defaultValue: number) => number
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

export declare class FpsEventInfo {
    minFps: number
    avgFps: number
    pageName: string
}

export declare class InteropProcessMemoryInfo {
    avgMemory: number
    maxMemory: number
    sampleCount: number
    pid: number
}

export declare class InteropPageMemoryInfo {
    avgMemory: number
    maxMemory: number
    sampleCount: number
    pageName: string
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
    lastExitMessage: string
    lastExitReason: string
}

export declare interface DisplaySyncInterface {
    start: () => void
    stop: () => void
    on: (cb: (funcArg0: number, funcArg1: number) => void) => void
    off: () => void
}

export declare class InteropDayTrafficInfo {
    total: number
    upTotal: number
    downTotal: number
    date: string
}

export declare interface CustomLib {
    ExitInfo: {new (exitMessage: string, exitReason: string): ExitInfo}
    InteropStorageFileInfo: {new (p: string, s: number, ss: Array<InteropStorageFileInfo>, i: boolean): InteropStorageFileInfo}
    InteropStorageInfo: {new (a: number, c: number, d: number, t: number, ts: Array<InteropStorageFileInfo>, es: Array<InteropStorageFileInfo>): InteropStorageInfo}
    InteropFreezeInfo: {new (): InteropFreezeInfo}
    InteropPageMemoryInfo: {new (a: number, m: number, s: number, p: string): InteropPageMemoryInfo}
    InteropProcessMemoryInfo: {new (a: number, m: number, s: number, p: number): InteropProcessMemoryInfo}
    ResponseEvent: {new (): ResponseEvent}
    InteropPageResponseLaggyModel: {new (): InteropPageResponseLaggyModel}
    ClickInfo: {new (time: number, wx: number, wy: number, id: string, nodeType: string, hX: number, hY: number, hH: number, hW: number): ClickInfo}
    InteropSystemTrafficInfo: {new (u: number, d: number, t: string): InteropSystemTrafficInfo}
    InteropPageTrafficInfo: {new (u: number, d: number, p: string): InteropPageTrafficInfo}
    InteropDayTrafficInfo: {new (u: number, d: number, date: string): InteropDayTrafficInfo}
    InteropPageCpuInfo: {new (a: number, m: number, s: number, p: string): InteropPageCpuInfo}
    InteropSampleTrafficInfo: {new (s: InteropSystemTrafficInfo, p: Map<string, InteropPageTrafficInfo>): InteropSampleTrafficInfo}
    InteropProcessCpuInfo: {new (a: number, m: number, s: number, p: number): InteropProcessCpuInfo}
    FpsEventInfo: {new (minFps: number, avgFps: number, pageName: string): FpsEventInfo}
    InteropBatteryUsageInfo: {new (c: string | undefined, l: number | undefined, t: number | undefined, ca: number | undefined, sc: number | undefined, st: number | undefined, h: number | undefined, v: number | undefined, te: string | undefined, p: number | undefined, ch: boolean | undefined, li: number | undefined, b: number | undefined, u: number | undefined, ti: number | undefined): InteropBatteryUsageInfo}
    InteropCrashInfo: {new (): InteropCrashInfo}
    ScrollHitchInfo: {new (minFps: number, avgFps: number, frameDropRatio: number, jankRate: number, bigJankRate: number, htLessThan0: number, ht0To00001: number, ht00001To0001: number, ht0001To001: number, ht001To005: number, ht005To01: number, ht01To1: number, htBiggerThan1: number, targetFPS: number, longestLostFrame: number, totalFrameCount: number, pageName: string): ScrollHitchInfo}
    InteropThreadCpuUsageInfo: {new (threadId: number, threadName: string, threadState: string, threadJiffiesPercent: number, threadJiffies: number, totalJiffies: number, st: number, et: number): InteropThreadCpuUsageInfo}
    CMemMonitorConfig: {new (shouldBeClusteredToThisSo: (funcArg0: string) => boolean): CMemMonitorConfig}
    InteropAllThreadCpuUsageInfo: {new (t: Array<InteropThreadCpuUsageInfo>): InteropAllThreadCpuUsageInfo}
    initCrashHandler(exit: () => void, collectCrashInfo: () => string, reportCrashInfo: (funcArg0: InteropCrashInfo) => void, persistentDir: string, enableDumpOnOOM: number, lastNHilogNumber: number, systemLogNumber: number, enableMemMonitor: CMemMonitorConfig | undefined): void
    getExitInfo(lastExitMessage: string, lastExitReason: number): ExitInfo
    initFreezeHandler(onFreeze: (funcArg0: () => void) => void, collectFreezeInfo: () => string, reportFreezeInfo: (funcArg0: InteropFreezeInfo) => void, persistentDir: string): void
    initTrafficHandler(preference: TrafficPreference, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleTraffic: (funcArg0: () => void) => void, getUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number) => void) => void, getPageUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number, funcArgfuncArg2: string) => void, funcArg1: string) => void, reportTraffic: (funcArg0: InteropSampleTrafficInfo) => void, sampleThreshold: number): void
    destroyTrafficHandler(getUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number) => void) => void): void
    getYesterdayTraffic(): InteropDayTrafficInfo | undefined
    initStorageHandler(reportStorageInfo: (funcArg0: InteropStorageInfo) => void, sizeLimit: number, dirSizeLimit: number, reportTopNum: number): void
    reportAppStorageInfo(getCurrentBundleStats: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number, funcArgfuncArg2: number) => void) => void): void
    getPageCpuInfo(): InteropPageCpuInfo
    getProcessCpuInfo(): InteropProcessCpuInfo
    initCpuHandler(getCpuUsage: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportCpu: (funcArg0: () => void, funcArg1: () => void) => void, reporPageCpuInfo: (funcArg0: InteropPageCpuInfo) => void, reporProcessCpuInfo: (funcArg0: InteropProcessCpuInfo) => void): void
    getPageMemoryInfo(): InteropPageMemoryInfo
    getProcessMemoryInfo(): InteropProcessMemoryInfo
    initMemoryHandler(memoryPreference: MemoryPreference, getMemoryUsage: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportMemory: (funcArg0: () => void, funcArg1: () => void) => void, reporPageMemoryInfo: (funcArg0: InteropPageMemoryInfo) => void, reporProcessMemoryInfo: (funcArg0: InteropProcessMemoryInfo) => void, memoryThreshold: number): void
    destroyMemoryHandler(): void
    initBatteryHandler(batteryInterface: BatteryInfoInterface, getBrightness: () => number, onApplicationStateChange: (funcArg0: () => void, funcArg1: () => void) => void, onAbilityForeground: (funcArg0: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, getRunningProcessInfo: (funcArg0: (funcArgfuncArg0: boolean) => void) => void, repeatHandleCpuUsage: (funcArg0: () => void) => void, reportBatteryInfo: (funcArg0: InteropBatteryUsageInfo) => void, reportThreadCpuUsageInfo: (funcArg0: InteropAllThreadCpuUsageInfo) => void, limit: number): void
    destroyBatteryHandler(): void
    initScrollEventHandler(onDisplay: DisplaySyncInterface, onScrollEvect: (funcArg0: () => void, funcArg1: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, reportPageScrollInfo: (funcArg0: ScrollHitchInfo) => void): void
    initPageEventHandler(onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, onWindowEvent: (funcArg0: () => void, funcArg1: () => void) => void, reportFpsInfo: (funcArg0: FpsEventInfo) => void): void
    initLaggyHandler(onDisplay: DisplaySyncInterface, onAbilityBackground: (funcArg0: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, onDidClick: (funcArg0: (funcArgfuncArg0: ClickInfo) => void) => void, maxTime: number, maxArraySize: number, reportResponseEvent: (funcArg0: ResponseEvent) => void, reportPageResponseLaggyModel: (funcArg0: InteropPageResponseLaggyModel) => void): void
}