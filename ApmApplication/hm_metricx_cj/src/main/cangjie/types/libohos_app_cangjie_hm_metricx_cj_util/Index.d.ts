export declare interface DisplaySync {
    start: () => void
    stop: () => void
    on: (cb: (funcArg0: number, funcArg1: number) => void) => void
    off: () => void
}

export declare interface Logger {
    warn: (content: string) => void
    info: (content: string) => void
}

export declare interface DisplaySyncInterface {
    start: () => void
    stop: () => void
    on: (cb: (funcArg0: number, funcArg1: number) => void) => void
    off: () => void
}

