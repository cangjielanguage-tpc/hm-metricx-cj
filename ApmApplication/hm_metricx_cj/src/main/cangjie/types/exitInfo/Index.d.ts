export declare class ExitInfo {
    lastExitMessage: string
    lastExitReason: string
    constructor (exitMessage: string, exitReason: string)
}


export declare function getExitInfoInterop(lastExitMessage: string, lastExitReason: number): void

export declare function getExitInfoInterop(lastExitMessage: string, lastExitReason: number): ExitInfo
