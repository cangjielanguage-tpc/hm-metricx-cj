export declare class InteropAllThreadCpuUsageInfo {
    threadCpuUsageInfoList: Array<InteropThreadCpuUsageInfo>
    constructor (t: Array<InteropThreadCpuUsageInfo>)
}

export declare class InteropThreadCpuUsageInfo {
    threadId: number
    threadName: string
    threadState: string
    threadJiffiesPercent: number
    threadJiffies: number
    totalJiffies: number
    startBgTime: number
    exceptionTime: number
    constructor (threadId: number, threadName: string, threadState: string, threadJiffiesPercent: number, threadJiffies: number, totalJiffies: number, st: number, et: number)
}

export declare interface BatteryInfoInterface {
    getBatterySOC: () => number
    getChargingStatus: () => number
    getHealthStatus: () => number
    getPluggedType: () => number
    getVoltage: () => number
    getTechnology: () => string
    getBatteryTemperature: () => number
}

export declare class InteropBatteryUsageInfo {
    currentPageName: string | undefined
    level: number | undefined
    temperature: number | undefined
    capacity: number | undefined
    scale: number | undefined
    status: number | undefined
    health: number | undefined
    voltage: number | undefined
    technology: string | undefined
    plugged: number | undefined
    charging: boolean | undefined
    limit: number | undefined
    brightness: number | undefined
    useTime: number | undefined
    time: number | undefined
    constructor (c: string | undefined, l: number | undefined, t: number | undefined, ca: number | undefined, sc: number | undefined, st: number | undefined, h: number | undefined, v: number | undefined, te: string | undefined, p: number | undefined, ch: boolean | undefined, li: number | undefined, b: number | undefined, u: number | undefined, ti: number | undefined)
}

