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
    constructor ()
}
export declare function initFreezeHandlerInterop(sdkApiVersion: number, addFreezeWatcher: (funcArg0: (funcArgfuncArg0: string, funcArgfuncArg1: string, funcArgfuncArg2: string, funcArgfuncArg3: string, funcArgfuncArg4: string) => void) => void, onFreeze: (funcArg0: () => void) => void, collectFreezeInfo: () => string, reportFreezeInfo: (funcArg0: InteropFreezeInfo) => void, persistentDir: string): void

export declare function initFreezeHandlerInterop(sdkApiVersion: number, addFreezeWatcher: (funcArg0: (funcArgfuncArg0: string, funcArgfuncArg1: string, funcArgfuncArg2: string, funcArgfuncArg3: string, funcArgfuncArg4: string) => InteropFreezeInfo) => void, onFreeze: (funcArg0: () => void) => void, collectFreezeInfo: () => string, persistentDir: string): void
