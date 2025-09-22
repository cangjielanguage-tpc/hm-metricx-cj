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

export declare class InteropSystemTrafficInfo {
    total: number
    upTotal: number
    downTotal: number
    timeStamp: string
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

export declare interface CustomLib {
    ExitInfo: {new (exitMessage: string, exitReason: string): ExitInfo}
    InteropStorageFileInfo: {new (p: string, s: number, ss: Array<InteropStorageFileInfo>, i: boolean): InteropStorageFileInfo}
    InteropStorageInfo: {new (a: number, c: number, d: number, t: number, ts: Array<InteropStorageFileInfo>, es: Array<InteropStorageFileInfo>): InteropStorageInfo}
    InteropFreezeInfo: {new (): InteropFreezeInfo}
    InteropPageCpuInfo: {new (a: number, m: number, s: number, p: string): InteropPageCpuInfo}
    InteropProcessCpuInfo: {new (a: number, m: number, s: number, p: number): InteropProcessCpuInfo}
    InteropSystemTrafficInfo: {new (u: number, d: number, t: string): InteropSystemTrafficInfo}
    InteropPageTrafficInfo: {new (u: number, d: number, p: string): InteropPageTrafficInfo}
    InteropSampleTrafficInfo: {new (s: InteropSystemTrafficInfo, p: Map<string, InteropPageTrafficInfo>): InteropSampleTrafficInfo}
    InteropCrashInfo: {new (): InteropCrashInfo}
    CMemMonitorConfig: {new (shouldBeClusteredToThisSo: (funcArg0: string) => boolean): CMemMonitorConfig}
    initCrashHandler(exit: () => void, collectCrashInfo: () => string, reportCrashInfo: (funcArg0: InteropCrashInfo) => void, persistentDir: string, enableDumpOnOOM: number, lastNHilogNumber: number, systemLogNumber: number, enableMemMonitor: CMemMonitorConfig | undefined): void
    getExitInfo(lastExitMessage: string, lastExitReason: number): void
    initFreezeHandler(onFreeze: (funcArg0: () => void) => void, collectFreezeInfo: () => string, reportFreezeInfo: (funcArg0: InteropFreezeInfo) => void, persistentDir: string): void
    initTrafficHandler(preference: TrafficPreference, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleTraffic: (funcArg0: () => void) => void, getUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number) => void) => void, reportTraffic: (funcArg0: InteropSampleTrafficInfo) => void, sampleThreshold: number): void
    destroyTrafficHandler(getUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number) => void) => void): void
    initStorageHandler(reportStorageInfo: (funcArg0: InteropStorageInfo) => void, sizeLimit: number, dirSizeLimit: number, reportTopNum: number): void
    reportAppStorageInfo(getCurrentBundleStats: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number, funcArgfuncArg2: number) => void) => void): void
    getPageCpuInfo(): InteropPageCpuInfo
    getProcessCpuInfo(): InteropProcessCpuInfo
    initCpuHandler(getCpuUsage: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportCpu: (funcArg0: () => void, funcArg1: () => void) => void, reporPageCpuInfo: (funcArg0: InteropPageCpuInfo) => void, reporProcessCpuInfo: (funcArg0: InteropProcessCpuInfo) => void): void
}