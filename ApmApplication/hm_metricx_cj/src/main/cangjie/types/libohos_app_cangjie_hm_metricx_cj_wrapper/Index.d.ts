
export declare function initCrashHandler(exit: () => void, collectCrashInfo: () => string, reportCrashInfo: (funcArg0: InteropCrashInfo) => void, persistentDir: string, enableDumpOnOOM: number, lastNHilogNumber: number, systemLogNumber: number, enableMemMonitor: CMemMonitorConfig | undefined): void

export declare function getExitInfo(lastExitMessage: string, lastExitReason: number): void

export declare function initFreezeHandler(onFreeze: (funcArg0: () => void) => void, collectFreezeInfo: () => string, reportFreezeInfo: (funcArg0: InteropFreezeInfo) => void, persistentDir: string): void

export declare function initTrafficHandler(preference: TrafficPreference, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleTraffic: (funcArg0: () => void) => void, getUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number) => void) => void, reportTraffic: (funcArg0: InteropSampleTrafficInfo) => void, sampleThreshold: number): void

export declare function destroyTrafficHandler(getUidRxAndTxBytes: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number) => void) => void): void

export declare function initStorageHandler(reportStorageInfo: (funcArg0: InteropStorageInfo) => void, sizeLimit: number, dirSizeLimit: number, reportTopNum: number): void

export declare function reportAppStorageInfo(getCurrentBundleStats: (funcArg0: (funcArgfuncArg0: number, funcArgfuncArg1: number, funcArgfuncArg2: number) => void) => void): void

export declare function getPageCpuInfo(): InteropPageCpuInfo

export declare function getProcessCpuInfo(): InteropProcessCpuInfo

export declare function initCpuHandler(getCpuUsage: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportCpu: (funcArg0: () => void, funcArg1: () => void) => void, reporPageCpuInfo: (funcArg0: InteropPageCpuInfo) => void, reporProcessCpuInfo: (funcArg0: InteropProcessCpuInfo) => void): void

export declare function getPageMemoryInfo(): InteropPageMemoryInfo

export declare function getProcessMemoryInfo(): InteropProcessMemoryInfo

export declare function initMemoryHandler(memoryPreference: MemoryPreference, getMemoryUsage: () => number, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, repeatSampleAndReportMemory: (funcArg0: () => void, funcArg1: () => void) => void, reporPageMemoryInfo: (funcArg0: InteropPageMemoryInfo) => void, reporProcessMemoryInfo: (funcArg0: InteropProcessMemoryInfo) => void, memoryThreshold: number): void

export declare function destroyMemoryHandler(): void

export declare function initBatteryHandler(batteryInterface: BatteryInfoInterface, getBrightness: () => number, onApplicationStateChange: (funcArg0: () => void, funcArg1: () => void) => void, onAbilityForeground: (funcArg0: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, getRunningProcessInfo: (funcArg0: (funcArgfuncArg0: boolean) => void) => void, repeatHandleCpuUsage: (funcArg0: () => void) => void, reportBatteryInfo: (funcArg0: InteropBatteryUsageInfo) => void, reportThreadCpuUsageInfo: (funcArg0: InteropAllThreadCpuUsageInfo) => void, limit: number): void

export declare function destroyBatteryHandler(): void

export declare function initScrollEventHandler(onDisplay: DisplaySyncInterface, onScrollEvect: (funcArg0: () => void, funcArg1: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, reportPageScrollInfo: (funcArg0: ScrollHitchInfo) => void): void

export declare function initPageEventHandler(onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, onWindowEvent: (funcArg0: () => void, funcArg1: () => void) => void, reportFpsInfo: (funcArg0: FpsEventInfo) => void): void

export declare function initLaggyHandler(onDisplay: DisplaySyncInterface, onAbilityBackground: (funcArg0: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, onDidClick: (funcArg0: (funcArgfuncArg0: ClickInfo) => void) => void, maxTime: number, maxArraySize: number, reportResponseEvent: (funcArg0: ResponseEvent) => void, reportPageResponseLaggyModel: (funcArg0: InteropPageResponseLaggyModel) => void): void

export declare function initLogger(logger: Logger): void
