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

