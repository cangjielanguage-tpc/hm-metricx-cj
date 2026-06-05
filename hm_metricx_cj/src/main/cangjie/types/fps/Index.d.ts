export declare class ScrollHitchInfo {
    minFps: number
    avgFps: number
    frameDropRatio: number
    jankRate: number
    bigJankRate: number
    htLessThan0: number
    ht0To00001: number
    ht00001To0001: number
    ht0001To001: number
    ht001To005: number
    ht005To01: number
    ht01To1: number
    htBiggerThan1: number
    targetFPS: number
    longestLostFrame: number
    totalFrameCount: number
    pageName: string
    constructor (minFps: number, avgFps: number, frameDropRatio: number, jankRate: number, bigJankRate: number, htLessThan0: number, ht0To00001: number, ht00001To0001: number, ht0001To001: number, ht001To005: number, ht005To01: number, ht01To1: number, htBiggerThan1: number, targetFPS: number, longestLostFrame: number, totalFrameCount: number, pageName: string)
}

export declare class FpsEventInfo {
    minFps: number
    avgFps: number
    pageName: string
    constructor (minFps: number, avgFps: number, pageName: string)
}

export declare function initPageEventHandlerInterop(onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, onWindowEvent: (funcArg0: () => void, funcArg1: () => void) => void, reportFpsInfo: (funcArg0: FpsEventInfo) => void): void
export declare function initPageEventHandlerInterop(onDisplay: DisplaySync, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, onWindowEvent: (funcArg0: () => void, funcArg1: () => void) => void, reportFpsInfo: (funcArg0: FpsEventInfo) => void): void


export declare function initScrollEventHandlerInterop(onDisplay: DisplaySync, onScrollEvect: (funcArg0: () => void, funcArg1: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, reportPageScrollInfo: (funcArg0: ScrollHitchInfo) => void): void
export declare function initScrollEventHandlerInterop(onDisplay: DisplaySyncInterface, onScrollEvect: (funcArg0: () => void, funcArg1: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, reportPageScrollInfo: (funcArg0: ScrollHitchInfo) => void): void

// ==================== 白屏检测 ====================

export declare class InteropWhiteScreenConfig {
    rootComponentId: string
    ttidTimeoutMs: number
    frameCheckDurationMs: number
    backgroundFirstSnapshotDelayMs: number
    backgroundSecondSnapshotDelayMs: number
    backgroundRecentPageEnterThresholdMs: number
    minFrameCountThreshold: number
    maxDistinctColorCount: number
    whiteRgbThreshold: number
    snapshotScale: number
    snapshotRegionTop: number
    snapshotRegionBottom: number
    autoWriteFaultLog: boolean
    constructor (rootComponentId: string, ttidTimeoutMs: number, frameCheckDurationMs: number, backgroundFirstSnapshotDelayMs: number, backgroundSecondSnapshotDelayMs: number, backgroundRecentPageEnterThresholdMs: number, minFrameCountThreshold: number, maxDistinctColorCount: number, whiteRgbThreshold: number, snapshotScale: number, snapshotRegionTop: number, snapshotRegionBottom: number, autoWriteFaultLog: boolean)
}

export declare class InteropWhiteScreenEventInfo {
    pageName: string
    whiteScreenType: string
    whiteScreenScene: string
    appState: string
    ttid: number
    backgroundElapsedMs: number
    foregroundDistinctColorCount: number
    foregroundMainColorWhite: boolean
    backgroundFirstDistinctColorCount: number
    backgroundSecondDistinctColorCount: number
    backgroundFirstMainColorWhite: boolean
    backgroundSecondMainColorWhite: boolean
    backgroundDetectionReason: string
    frameCountInNSeconds: number
    constructor (pageName: string, whiteScreenType: string, whiteScreenScene: string, appState: string, ttid: number, backgroundElapsedMs: number, foregroundDistinctColorCount: number, foregroundMainColorWhite: boolean, backgroundFirstDistinctColorCount: number, backgroundSecondDistinctColorCount: number, backgroundFirstMainColorWhite: boolean, backgroundSecondMainColorWhite: boolean, backgroundDetectionReason: string, frameCountInNSeconds: number)
}

export declare function initWhiteScreenHandlerInterop(config: InteropWhiteScreenConfig, reportCallback: (funcArg0: InteropWhiteScreenEventInfo) => void, setTimeoutFunc: (funcArg0: string, funcArg1: number) => number, clearTimeoutFunc: (funcArg0: number) => void, performSnapshotFunc: () => void, performBackgroundSnapshotFunc: (funcArg0: number) => void): void

export declare function destroyWhiteScreenHandlerInterop(): void

export declare function onNavDestinationSwitchInterop(toPageName: string, toShown: boolean): void

export declare function onFirstFrameReceivedInterop(): void

export declare function onFrameReceivedInterop(): void

export declare function handleWhiteScreenTimerCallbackInterop(timerType: string): void

export declare function performSnapshotAndAnalyzeInterop(): void

export declare function onSnapshotAnalysisResultInterop(colorData: string): void

export declare function onBackgroundSnapshotAnalysisResultInterop(sampleIndex: number, colorData: string): void

export declare function onWhiteScreenForegroundInterop(): void

export declare function onWhiteScreenBackgroundInterop(): void

export declare class InteropFirstRenderTimeInfo {
    startTime: number;
    endTime: number;
    duration: number;
    targetPage: string;
    constructor (startTime: number, endTime: number, duration: number, targetPage: string)
}

export declare class InteropFirstRenderTimeConfig {
    enableLogging: boolean;
    reportThreshold: number;
    constructor (enableLogging: boolean, reportThreshold: number)
}

export declare function initFirstRenderTimeMonitorInterop(config: InteropFirstRenderTimeConfig, reportCallback: (funcArg0: InteropFirstRenderTimeInfo) => void): void

export declare function recordClickStartInterop(): void

export declare function recordNavigationTargetInterop(targetPage: string): void

export declare function calculateFirstRenderTimeInterop(targetPage: string): void;

export declare function calculateFirstRenderTimeManuallyInterop(startTime: number, targetPage: string): void;

export declare function resetFirstRenderTimeMonitorInterop(): void;