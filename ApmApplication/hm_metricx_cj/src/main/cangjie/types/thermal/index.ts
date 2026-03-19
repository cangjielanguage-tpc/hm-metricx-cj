export declare interface InteropThermalEventInfo {
    pageName: string
    level: number
    levelName: string
    threshold: number
    isForeground: boolean
    durationMs: number
    timestamp: number
    constructor ()
}

export declare interface ThermalInfoInterface {
    getThermalLevel: () => number
}

export declare interface AppHooks {
    onAppStateChange: (onFg: () => void, onBg: () => void) => void
    onNavDestinationSwitch: (cb: (targetPageName: string) => void) => void
}