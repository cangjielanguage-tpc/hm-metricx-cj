export declare class InteropCrashInfo {
    language: string
    meminfo: string
    timestamp: string
    pid: string
    pname: string
    stacktrace: string
    hilog: string
    tid: string
    tname: string
    fds: Map<string, string>
    limits: string
    threads: string
    extraInfo: string
    crashLogPath: string
    dumpOnOOMPath: string
    appVersion: string
    rawFile: string
    systemLog: string
    lastNHilog: string
    dumpTime: string
    historyRawFiles: string
    nativeMemDetail: string
    memPersistTime: string
    constructor ()
}

export declare class CMemMonitorConfig {
    shouldBeClusteredToThisSo: (varArg0: string) => boolean
    constructor (shouldBeClusteredToThisSo: (funcArg0: string) => boolean)
}

export declare class InteropCrashInfo {
    constructor ()
}

