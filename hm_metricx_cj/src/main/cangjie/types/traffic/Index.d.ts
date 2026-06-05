export declare interface TrafficPreference {
    put: (key: string, value: string) => void
    has: (key: string) => boolean
    get: (key: string, defaultValue: string) => string
}

export declare class InteropSampleTrafficInfo {
    systemInfo: InteropSystemTrafficInfo
    pageInfoMap: Map<string, InteropPageTrafficInfo>
    constructor (s: InteropSystemTrafficInfo, p: Map<string, InteropPageTrafficInfo>)
}

export declare class InteropDayTrafficInfo {
    total: number
    upTotal: number
    downTotal: number
    date: string
    constructor (u: number, d: number, date: string)
}

export declare class InteropPageTrafficInfo {
    total: number
    upTotal: number
    downTotal: number
    pageName: string
    constructor (u: number, d: number, p: string)
}

export declare class InteropSystemTrafficInfo {
    total: number
    upTotal: number
    downTotal: number
    timeStamp: string
    constructor (u: number, d: number, t: string)
}
export declare function initTrafficHandlerInterop(preference: TrafficPreference, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleTraffic: (funcArg0: () => void) => void, getUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number) => void) => void, reportTraffic: (funcArg0: InteropSampleTrafficInfo) => void, sampleThreshold: number): void

export declare function destroyTrafficHandlerInterop(getUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number) => void) => void): void

export declare function initTrafficHandlerInterop(preference: TrafficPreference, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleTraffic: (funcArg0: () => void) => void, getUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number, funcArgfuncArg2: string) => void, funcArg1: string) => void, reportTraffic: (funcArg0: InteropSampleTrafficInfo) => void, reportYesterdayTraffic: (funcArg0: InteropDayTrafficInfo) => void, sampleThreshold: number): void

