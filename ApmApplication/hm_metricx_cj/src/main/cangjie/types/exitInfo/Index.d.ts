export declare class ExitInfo {
    exitMessage: string;
    exitReason: string;
    isBackground: boolean;
    appState: string;
    stateChangeTime: number;
    timestamp: number;

    constructor(
        exitMessage: string,
        exitReason: string,
        isBackground: boolean,
        appState: string,
        stateChangeTime: number,
        timestamp: number
    );
}

export declare class AppStateInfo {
    appState: string;
    stateChangeTime: number;
    timestamp: number;

    constructor(appState: string, stateChangeTime: number, timestamp: number);
}

export declare function initExitInfoHandlerInterop(
    lastExitMessage: string,
    lastExitReasonValue: number,
    reportExitInfoHandler: (data: ExitInfo) => void,
    reportAppStateHandler: (data: AppStateInfo) => void
): void;

/** 销毁 exitInfo 互操作 handler */
export declare function destroyExitInfoHandlerInterop(): void;
