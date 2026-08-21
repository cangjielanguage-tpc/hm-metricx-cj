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
    sampleCount: number
    pid: number
    totalMemoryLimit: number
    cjMemoryLimit: number
    arkTsMemoryLimit: number
    isTotalTop: boolean
    isCJTop: boolean
    isArkTsTop: boolean
    memoryAvgUsageRate: number
    memoryMaxUsageRate: number
    cjMemoryAvgUsageRate: number
    cjMemoryMaxUsageRate: number
    arkTsMemoryAvgUsageRate: number
    arkTsMemoryMaxUsageRate: number
    constructor (a: number, m: number, acj: number, mcj: number, aark: number, mark: number, s: number, p: number, tml: number, cjl: number, atl: number, itt: boolean, ict: boolean, iat: boolean, maur: number, mmur: number, cmaur: number, cmmur: number, atmaur: number, atmmur: number)
}

export declare class InteropPageMemoryInfo {
    avgMemory: number
    maxMemory: number
    avgCJMemory: number
    maxCJMemory: number
    avgArkTsMemory: number
    maxArkTsMemory: number
    sampleCount: number
    pageName: string
    totalMemoryLimit: number
    cjMemoryLimit: number
    arkTsMemoryLimit: number
    isTotalTop: boolean
    isCJTop: boolean
    isArkTsTop: boolean
    memoryAvgUsageRate: number
    memoryMaxUsageRate: number
    cjMemoryAvgUsageRate: number
    cjMemoryMaxUsageRate: number
    arkTsMemoryAvgUsageRate: number
    arkTsMemoryMaxUsageRate: number
    constructor (a: number, m: number, acj: number, mcj: number, aark: number, mark: number, s: number, p: string, tml: number, cjl: number, atl: number, itt: boolean, ict: boolean, iat: boolean, maur: number, mmur: number, cmaur: number, cmmur: number, atmaur: number, atmmur: number)
}
export declare function getPageMemoryInfoInterop(): InteropPageMemoryInfo

export declare function getProcessMemoryInfoInterop(): InteropProcessMemoryInfo

export declare function initMemoryHandlerInterop(memoryPreference: MemoryPreference, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportMemory: (funcArg0: () => void, funcArg1: () => void, funcArg2: () => void) => void, reporPageMemoryInfo: (funcArg0: InteropPageMemoryInfo) => void, reporProcessMemoryInfo: (funcArg0: InteropProcessMemoryInfo) => void, memoryThreshold: number, totalRatio: number, cjRatio: number, arkTsRatio: number): void

export declare function destroyMemoryHandlerInterop(): void
