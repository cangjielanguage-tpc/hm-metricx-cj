export declare interface InteropThermalEventInfo {
    pageName: string
    prevLevel: number
    level: number
    levelName: string
    levelChange: string
    threshold: number
    isForeground: boolean
    durationMs: number
    timestamp: number
    cpuNum: number
    constructor ()
}

export declare interface ThermalInfoInterface {
    getThermalLevel: () => number
}

export declare interface AppHooks {
    onAppStateChange: (onFg: () => void, onBg: () => void) => void
    onNavDestinationSwitch: (cb: (targetPageName: string) => void) => void
}
export declare function initThermalHandlerInterop(scheduler: Scheduler, hooks: AppHooks, thermalInterface: ThermalInfoInterface, reportThermalInfo: (funcArg0: ThermalEventInfo) => void, sampleInterval: number, reportMinInterval: number, abnormalThreshold: number): void
export declare function initThermalHandlerInterop(getUptimeMs: () => number, thermalInterface: ThermalInfoInterface, hooks: AppHooks, repeatSampleThermal: (funcArg0: () => void) => void, stopSampleThermal: () => void, reportThermalInfo: (funcArg0: InteropThermalEventInfo) => void, sampleInterval: number, reportMinInterval: number, abnormalThreshold: number): void
export declare function destroyThermalHandlerInterop(): void
