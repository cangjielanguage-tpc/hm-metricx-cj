export declare class InteropStorageInfo {
    appSize: number
    cacheSize: number
    dataSize: number
    totalSize: number
    topStorageFileList: Array<InteropStorageFileInfo>
    exceptionDirList: Array<InteropStorageFileInfo>
    constructor (a: number, c: number, d: number, t: number, ts: Array<InteropStorageFileInfo>, es: Array<InteropStorageFileInfo>)
}

export declare class InteropStorageFileInfo {
    path: string
    size: number
    subfileList: Array<InteropStorageFileInfo>
    isDir: boolean
    constructor (p: string, s: number, ss: Array<InteropStorageFileInfo>, i: boolean)
}

