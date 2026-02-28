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
}

export declare interface AppHooks {
    onAppStateChange: (onFg: () => void, onBg: () => void) => void
    onNavDestinationSwitch: (cb: (funcArg0: string) => void) => void
}

export declare class InteropAllThreadCpuUsageInfo {
    threadCpuUsageInfoList: Array<InteropThreadCpuUsageInfo>
}

export declare interface Scheduler {
    setInterval: (cb: () => void, intervalMs: number) => number
    clearInterval: (id: number) => void
}

export declare interface ThermalInfoInterface {
    getThermalLevel: () => number
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

export declare class InteropProcessCpuInfo {
    avgCpu: number
    maxCpu: number
    sampleCount: number
    pid: number
}

export declare class InteropThermalEventInfo {
    pageName: string
    level: number
    levelName: string
    threshold: number
    isForeground: boolean
    durationMs: number
    timestamp: number
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

export declare class InteropPageCpuInfo {
    avgCpu: number
    maxCpu: number
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

export declare interface MemoryPreference {
    put: (key: string, value: number) => void
    has: (key: string) => boolean
    get: (key: string, defaultValue: number) => number
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

export declare class InteropProcessMemoryInfo {
    avgMemory: number
    maxMemory: number
    sampleCount: number
    pid: number
}

export declare class InteropPageResponseLaggyModel {
    pageName: string
    touchTimes: number
    laggyTimes: number
    laggyTimeList: Array<number>
}

export declare class InteropPageMemoryInfo {
    avgMemory: number
    maxMemory: number
    sampleCount: number
    pageName: string
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
    lastExitMessage: string
    lastExitReason: string
}