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
    totalHeap: number
    sampleCount: number
    pid: number
    constructor (a: number, m: number, acj: number, mcj: number, aark: number, mark: number, th: number, s: number, p: number)
}

export declare class InteropPageMemoryInfo {
    avgMemory: number
    maxMemory: number
    avgCJMemory: number
    maxCJMemory: number
    avgArkTsMemory: number
    maxArkTsMemory: number
    totalHeap: number
    sampleCount: number
    pageName: string
    constructor (a: number, m: number, acj: number, mcj: number, aark: number, mark: number, th: number, s: number, p: string)
}
export declare function getPageMemoryInfoInterop(): InteropPageMemoryInfo

export declare function getProcessMemoryInfoInterop(): InteropProcessMemoryInfo

export declare function initMemoryHandlerInterop(memoryPreference: MemoryPreference, getMemoryUsage: () => number, getArkTsMemoryUsage: () => number, getArkTsTotalHeap: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportMemory: (funcArg0: () => void, funcArg1: () => void, funcArg2: () => void) => void, reporPageMemoryInfo: (funcArg0: InteropPageMemoryInfo) => void, reporProcessMemoryInfo: (funcArg0: InteropProcessMemoryInfo) => void, memoryThreshold: number): void

export declare function destroyMemoryHandlerInterop(): void
