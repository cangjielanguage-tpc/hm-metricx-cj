export declare class ClickInfo {
    timestamp: number
    windowX: number
    windowY: number
    id: string
    nodeType: string
    hitX: number
    hitY: number
    hitHeight: number
    hitWidth: number
    constructor (time: number, wx: number, wy: number, id: string, nodeType: string, hX: number, hY: number, hH: number, hW: number)
}

export declare class InteropPageResponseLaggyModel {
    pageName: string
    touchTimes: number
    laggyTimes: number
    laggyTimeList: Array<number>
    constructor ()
}

export declare class ResponseEvent {
    pageName: string
    technologyStack: string
    responseTime: number
    descriptionID: string
    nodeType: string
    viewTouchID: string
    touchX: number
    touchY: number
    hitX: number
    hitY: number
    hitWidth: number
    hitHeight: number
    constructor ()
}


export declare function initLaggyHandlerInterop(onDisplay: DisplaySyncInterface, onAbilityBackground: (funcArg0: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, onDidClick: (funcArg0: (funcArgfuncArg0: ClickInfo) => void) => void, maxTime: number, maxArraySize: number, reportResponseEvent: (funcArg0: ResponseEvent) => void, reportPageResponseLaggyModel: (funcArg0: InteropPageResponseLaggyModel) => void): void
export declare function initLaggyHandlerInterop(onDisplay: DisplaySync, onAbilityBackground: (funcArg0: () => void) => void, onNavDestinationSwitch: (funcArg0: (funcArgfuncArg0: string) => void) => void, onDidClick: (funcArg0: (funcArgfuncArg0: ClickInfo) => void) => void, maxTime: number, maxArraySize: number, reportResponseEvent: (funcArg0: ResponseEvent) => void, reportPageResponseLaggyModel: (funcArg0: InteropPageResponseLaggyModel) => void): void
