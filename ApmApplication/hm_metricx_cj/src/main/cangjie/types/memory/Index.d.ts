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

