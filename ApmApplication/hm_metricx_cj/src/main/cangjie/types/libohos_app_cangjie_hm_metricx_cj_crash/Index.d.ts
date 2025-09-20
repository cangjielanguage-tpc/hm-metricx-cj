export declare class CMemMonitorConfig {
    shouldBeClusteredToThisSo: (varArg0: string) => boolean
    constructor (shouldBeClusteredToThisSo: (funcArg0: string) => boolean)
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
    constructor ()
}

