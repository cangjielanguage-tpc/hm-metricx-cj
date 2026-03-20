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
    constructor ()
}
export declare function initCrashHandlerInterop(exit: () => void, collectCrashInfo: () => string, reportCrashInfo: (funcArg0: InteropCrashInfo) => void, persistentDir: string, enableDumpOnOOM: number, lastNHilogNumber: number, systemLogNumber: number, enableMemMonitor: CMemMonitorConfig | undefined): void
export declare function initCrashHandlerInterop(onCrash: (funcArg0: () => void) => void, exit: () => void, collectCrashInfo: () => string, reportCrashInfo: (funcArg0: InteropCrashInfo) => void, persistentDir: string, enableDumpOnOOM: number, lastNHilogNumber: number, systemLogNumber: number, enableMemMonitor: CMemMonitorConfig | undefined): void

export declare function initCrashHandlerInterop(addCrashWatcher: (funcArg0: (funcArgfuncArg0: string, funcArgfuncArg1: string, funcArgfuncArg2: string, funcArgfuncArg3: string, funcArgfuncArg4: string, funcArgfuncArg5: string, funcArgfuncArg6: string) => void) => void, onCrash: (funcArg0: () => void) => void, exit: () => void, collectCrashInfo: () => string, reportCrashInfo: (funcArg0: InteropCrashInfo) => void, persistentDir: string, enableDumpOnOOM: number, lastNHilogNumber: number, systemLogNumber: number, enableMemMonitor: CMemMonitorConfig | undefined): void

