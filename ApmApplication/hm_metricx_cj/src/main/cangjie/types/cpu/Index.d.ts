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

export declare function getPageCpuInfoInterop(): InteropPageCpuInfo

export declare function getProcessCpuInfoInterop(): InteropProcessCpuInfo

export declare function initCpuHandlerInterop(getCpuUsage: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportCpu: (funcArg0: () => void, funcArg1: () => void) => void, reporPageCpuInfo: (funcArg0: InteropPageCpuInfo) => void, reporProcessCpuInfo: (funcArg0: InteropProcessCpuInfo) => void): void
