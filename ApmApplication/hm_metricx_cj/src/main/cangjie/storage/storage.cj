/**
 * Created on 2025/9/18
 */
package ohos_app_cangjie_hm_metricx_cj.storage

import std.fs.{Directory, Path, exists, FileInfo}
import std.collection.{TreeSet, ArrayList}
import ohos.ark_interop.*
import ohos.ark_interop_macro.*

@Interop[ArkTS]
public class InteropStorageFileInfo {
    public let path: String
    public let size: Int64
    public let subfileList: JSArrayEx<InteropStorageFileInfo>
    public let isDir: Bool
    public init(p: String, s: Int64, ss: JSArrayEx<InteropStorageFileInfo>, i: Bool) {
        this.path = p
        this.size = s
        this.subfileList = ss
        this.isDir = i
    }
}

@Interop[ArkTS]
public class InteropStorageInfo {
    public let appSize: Int64
    public let cacheSize: Int64
    public let dataSize: Int64
    public let totalSize: Int64
    public let topStorageFileList: JSArrayEx<InteropStorageFileInfo>
    public let exceptionDirList: JSArrayEx<InteropStorageFileInfo>
    public init(a: Int64, c: Int64, d: Int64, t: Int64, ts: JSArrayEx<InteropStorageFileInfo>,
        es: JSArrayEx<InteropStorageFileInfo>) {
        this.appSize = a
        this.cacheSize = c
        this.dataSize = d
        this.totalSize = t
        this.topStorageFileList = ts
        this.exceptionDirList = es
    }
}

public class StorageInfo {
    public let appSize: Int64
    public let cacheSize: Int64
    public let dataSize: Int64
    public let totalSize: Int64
    public let topStorageFileList = ArrayList<StorageFileInfo>()
    public let exceptionDirList = ArrayList<StorageFileInfo>()

    public init(a: Int64, c: Int64, d: Int64) {
        this.appSize = a
        this.cacheSize = c
        this.dataSize = d
        this.totalSize = a + d
    }

    func toInteropStorageInfo(): InteropStorageInfo {
        let ts = JSArrayEx<InteropStorageFileInfo>(
            this
                .topStorageFileList
                .toArray()
                .map<InteropStorageFileInfo>({x => x.toInteropStorageFileInfo()}))
        let es = JSArrayEx<InteropStorageFileInfo>(
            this
                .exceptionDirList
                .toArray()
                .map<InteropStorageFileInfo>({x => x.toInteropStorageFileInfo()}))

        InteropStorageInfo(this.appSize, this.cacheSize, this.dataSize, this.totalSize, ts, es)
    }
}

public class StorageFileInfo <: Comparable<StorageFileInfo> {
    public let path: String
    public let size: Int64
    public var subfileList = TreeSet<StorageFileInfo>()
    public let isDir: Bool

    public init(f: FileInfo, isDir: Bool) {
        this.path = f
            .path
            .toString()
        this.size = f.size
        this.isDir = isDir
    }

    public init(path: String, size: Int64, isDir: Bool) {
        this.path = path
        this.size = size
        this.isDir = isDir
    }

    public func compare(f: StorageFileInfo) {
        if (this.size > f.size) {
            return Ordering.LT
        } else if (this.size < f.size) {
            return Ordering.GT
        }
        if (this.path < f.path) {
            return Ordering.LT
        } else if (this.path > f.path) {
            return Ordering.GT
        }
        return Ordering.EQ
    }
    func toInteropStorageFileInfo(): InteropStorageFileInfo {
        let ss = JSArrayEx<InteropStorageFileInfo>(
            this
                .subfileList
                .toArray()
                .map<InteropStorageFileInfo>({x => x.toInteropStorageFileInfo()}))
        InteropStorageFileInfo(this.path, this.size, ss, this.isDir)
    }
}

var reportStorageInfoCallback: (storageInfo: InteropStorageInfo) -> Unit = {_ =>}
var sizeLimitValue: ?Int64 = None
var dirSizeLimitValue: ?Int64 = None
var reportTopNumValue: Int64 = 5

public func reportAppStorageInfo(
    getCurrentBundleStats: (onData: (appSize: Int64, dataSize: Int64, cacheSize: Int64) -> Unit) -> Unit): Unit {
    getCurrentBundleStats(
        {
            appSize, dataSize, cacheSize =>
                let storageInfo = StorageInfo(appSize, cacheSize, dataSize)

                let allAppStorageFiles = TreeSet<StorageFileInfo>()
                let allAppStorageDirs = TreeSet<StorageFileInfo>()

                if (sizeLimitValue.isSome()) {
                    if (storageInfo.totalSize > sizeLimitValue.getOrThrow()) {
                        let storagePathList = getAllStoragePath()
                        let allStorageInfoList = ArrayList<StorageFileInfo>()
                        for (storagePath in storagePathList) {
                            if (!exists(storagePath)) {
                                continue
                            }
                            let fileInfo = FileInfo(storagePath)
                            let storageDirInfo = getAllStorage(fileInfo, allAppStorageFiles)
                            allStorageInfoList.add(storageDirInfo)
                            if (dirSizeLimitValue.isSome()) {
                                getDirsOverLimit(storageDirInfo, dirSizeLimitValue.getOrThrow(), allAppStorageDirs)
                            }
                        }
                        reportTopNFile(allAppStorageFiles, storageInfo.topStorageFileList, reportTopNumValue)
                        reportTopNFile(allAppStorageDirs, storageInfo.exceptionDirList, reportTopNumValue)
                    }
                }
                reportStorageInfoCallback(storageInfo.toInteropStorageInfo())
        }
    )
}

func reportTopNFile(fileList: TreeSet<StorageFileInfo>, resultList: ArrayList<StorageFileInfo>, reportTopNum: Int64): Unit {
    var count: Int64 = 0
    for (storageFileInfo in fileList) {
        resultList.add(storageFileInfo)
        count++
        if (count == reportTopNum) {
            break
        }
    }
}

func getDirsOverLimit(f: StorageFileInfo, dirLimitSize: Int64, dirSet: TreeSet<StorageFileInfo>): Unit {
    //Find the smallest folder level that exceeds the size limit
    let subfilePathList = f.subfileList
    var reportFlag = true
    if (f.size <= dirLimitSize) {
        return
    }
    for (subfile in subfilePathList) {
        if (!subfile.isDir) {
            continue
        }
        if (subfile.size > dirLimitSize) {
            getDirsOverLimit(subfile, dirLimitSize, dirSet)
            reportFlag = false
        }
    }
    if (reportFlag) {
        dirSet.add(f)
    }
}

func getAllStoragePath(): ArrayList<String> {
    //Get storage path according to official documentation: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-fs-space-statistics
    let storagePathList = ArrayList<String>(
        ["/data/storage/el1/bundle", "/data/storage/el2/sharefiles", "/data/storage/el2/distributedfiles"])
    for (i in 1..6) {
        storagePathList.add("/data/storage/el${i}/base")
        storagePathList.add("/data/storage/el${i}/database")
    }
    storagePathList
}

func getAllStorage(f: FileInfo, fileSet: TreeSet<StorageFileInfo>): StorageFileInfo {
    if (f.size <= 0) {
        return StorageFileInfo(f
            .path
            .toString(), 0, true)
    }
    let storageFilesList = TreeSet<StorageFileInfo>()
    var size = 0
    let fileList = Directory.readFrom(f.path)
    for (file in fileList) {
        if (file.isDirectory()) {
            let childStorageFileInfo = getAllStorage(file, fileSet)
            size += childStorageFileInfo.size
            storageFilesList.add(childStorageFileInfo)
        } else {
            let fileInfo = StorageFileInfo(file, false)
            fileSet.add(fileInfo)
            storageFilesList.add(fileInfo)
            size += fileInfo.size
        }
    }
    let parentStorageFileInfo = StorageFileInfo(f
        .path
        .toString(), size, true)
    parentStorageFileInfo.subfileList = storageFilesList
    parentStorageFileInfo
}

public func initStorageHandler(reportStorageInfo: (storageInfo: InteropStorageInfo) -> Unit, sizeLimit!: Int64,
    dirSizeLimit!: Int64, reportTopNum!: Int64 = 5): Unit {
    sizeLimitValue = sizeLimit
    dirSizeLimitValue = dirSizeLimit
    reportTopNumValue = reportTopNum
    reportStorageInfoCallback = reportStorageInfo
}
