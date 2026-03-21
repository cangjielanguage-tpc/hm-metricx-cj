export declare interface MemoryPreference {
    put: (key: string, value: number) => void
    has: (key: string) => boolean
    get: (key: string, defaultValue: number) => number
}

export declare class InteropProcessMemoryInfo {
    avgMemory: number
    maxMemory: number
    sampleCount: number
    pid: number
    constructor (a: number, m: number, s: number, p: number)
}

export declare class InteropPageMemoryInfo {
    avgMemory: number
    maxMemory: number
    sampleCount: number
    pageName: string
    constructor (a: number, m: number, s: number, p: string)
}
export declare function getPageMemoryInfoInterop(): InteropPageMemoryInfo

export declare function getProcessMemoryInfoInterop(): InteropProcessMemoryInfo

export declare function initMemoryHandlerInterop(memoryPreference: MemoryPreference, getMemoryUsage: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportMemory: (funcArg0: () => void, funcArg1: () => void) => void, reporPageMemoryInfo: (funcArg0: InteropPageMemoryInfo) => void, reporProcessMemoryInfo: (funcArg0: InteropProcessMemoryInfo) => void, memoryThreshold: number): void

export declare function destroyMemoryHandlerInterop(): void
