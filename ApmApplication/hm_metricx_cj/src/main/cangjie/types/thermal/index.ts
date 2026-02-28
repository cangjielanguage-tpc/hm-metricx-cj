export declare interface InteropThermalEventInfo {
    pageName: string | undefined
    level: number | undefined
    levelName: string | undefined
    threshold: number | undefined
    isForeground: boolean | undefined
    durationMs: number | undefined
    timestamp: number | undefined
    constructor (c: string | undefined, l: number | undefined, ln: string | undefined, th: number | undefined, fg: boolean | undefined, dMs: number | undefined, ts: number | undefined)
}

export declare interface ThermalInfoInterface {
    getThermalLevel: () => number
}

export declare interface Scheduler {
    setInterval: (cb: () => void, intervalMs: number) => number
    clearInterval: (id: number) => void
}

export declare interface AppHooks {
    onAppStateChange: (onFg: () => void, onBg: () => void) => void
    onNavDestinationSwitch: (cb: (targetPageName: string) => void) => void
}