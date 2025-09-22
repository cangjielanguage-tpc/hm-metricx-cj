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
    constructor ()
}

