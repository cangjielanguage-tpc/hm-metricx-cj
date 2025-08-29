/**
 * Created on 2025/5/15
 */
package ohos_app_cangjie_hm_metricx_cj.storage

import tpc.AbilityKit.UIAbility
import tpc.AbilityKit.ApplicationContext
import tpc.CoreFileKit.storageStatistics.*
import tpc.CoreFileKit.fs.*
import stdx.encoding.json.*
import std.core.*
import std.sync.*
import std.fs
import ohos.hilog.Hilog
import tpc.CoreFileKit.statvfs.getTotalSize
import std.collection.TreeSet
import std.fs.FileInfo
import std.collection.ArrayList
import tpc.UIKit.arkui_node.Content
import tpc.AbilityKit.kit_common.*
import tpc.AbilityKit.UIAbilityContext
import tpc.AbilityKit.bundleManager.*
import ohos.ability.Context
import tpc.MapKit.navi.snapToRoads
import std.fs.Directory
import std.fs.Path
import std.fs.exists
import std.posix.isDir
import tpc.FormKit.formInfo.FormState
import ohos_app_cangjie_hm_metricx_cj.JsonValueToString
import std.fs.SymbolicLink
import std.fs.File

public class StorageInfo {
    public var appSize: ?Int64 = None
    public var cacheSize: ?Int64 = None
    public var dataSize: ?Int64 = None
    public var totalSize: ?Int64 = None
    public var topStorageFileList = ArrayList<StorageFileInfo>()
    public var exceptionDirList = ArrayList<StorageFileInfo>()

    public init() {}

    public func toString(): String {
        let jsonObj = JsonObject()
        if (appSize.isSome()) {
            jsonObj.put("appSize", JsonString(appSize.getOrThrow().toString()))
        }
        if (dataSize.isSome()) {
            jsonObj.put("dataSize", JsonString(dataSize.getOrThrow().toString()))
        }
        if (cacheSize.isSome()) {
            jsonObj.put("cacheSize", JsonString(cacheSize.getOrThrow().toString()))
        }
        if (totalSize.isSome()) {
        	jsonObj.put("totalSize", JsonString(totalSize.getOrThrow().toString()))
        }
        if (!topStorageFileList.isEmpty()) {
        	jsonObj.put("topStorageFileList", JsonString(topStorageFileList.toString()))
        }
        if (!exceptionDirList.isEmpty()) {
            jsonObj.put("exceptionDirList", JsonString(exceptionDirList.toString()))
        }
        jsonObj.toString()
    }
}

public class StorageFileInfo <: Comparable<StorageFileInfo> & ToString {
    public var path: String
    public var size: Int64
    public var subfileList = TreeSet<StorageFileInfo>()
    public var isDir: Bool

    public init(f: FileInfo, isDir: Bool) {
    	this.path = f.path.toString()
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

    public func toString(): String {
        let jsonObj = JsonObject()
        jsonObj.put("path", JsonString(path))
        jsonObj.put("size", JsonString(size.toString()))
        if (isDir) {
        	jsonObj.put("subfileList", JsonString(subfileList.toString()))
        }
        jsonObj.toString().replace("\\\"", "\"").replace("\"[", "[").replace("]\"", "]")
    }
}

var reportStorageInfoCallback: (storageInfo: StorageInfo) -> Unit = {info: StorageInfo =>}
var sizeLimitValue: ?Int64 = None
var dirSizeLimitValue: ?Int64 = None
var reportTopNumValue: Int64 = 5
public func reportAppStorageInfo(): Unit {
    getCurrentBundleStats(
        {
            err, data => if (err.isNone()) {
                if (data.isSome()) {
                    let storageInfo = StorageInfo()
                    storageInfo.appSize = data.getOrThrow().appSize
                    storageInfo.dataSize = data.getOrThrow().dataSize
                    storageInfo.cacheSize = data.getOrThrow().cacheSize
                    //总计 = appSize + dataSize
                    if (storageInfo.appSize.isSome() && storageInfo.dataSize.isSome()) {
                    	storageInfo.totalSize = storageInfo.appSize.getOrThrow() + storageInfo.dataSize.getOrThrow()
                    }

                    let allAppStorageFiles = TreeSet<StorageFileInfo>()
                    let allAppStorageDirs = TreeSet<StorageFileInfo>()

                    if (sizeLimitValue.isSome()) {
                        if (storageInfo.totalSize.getOrThrow() > sizeLimitValue.getOrThrow()) {
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
                            var fileCount: Int64 = 0
                            for (storageFileInfo in allAppStorageFiles) {
                                storageInfo.topStorageFileList.add(storageFileInfo)
                                fileCount++
                                if (fileCount == reportTopNumValue) {
                                    break
                                }
                            }
                            var dirCount: Int64 = 0
                            for (storageDirsInfo in allAppStorageDirs) {
                                storageInfo.exceptionDirList.add(storageDirsInfo)
                                dirCount++
                                if (dirCount == reportTopNumValue) {
                                    break
                                }
                            }
                        }
                    }
                    reportStorageInfoCallback(storageInfo)
                }
            }
        })
}

public func getDirsOverLimit(f: StorageFileInfo, dirLimitSize: Int64, dirSet: TreeSet<StorageFileInfo>): Unit {
    //找到超过阈值要求的最小一层文件夹
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

public func getAllStoragePath(): ArrayList<String> {
    let storagePathList = ArrayList<String>()
    storagePathList.add("/data/storage/el1/bundle")
    for (i in 1..6) {
    	storagePathList.add("/data/storage/el${i}/base")
    	storagePathList.add("/data/storage/el${i}/database")
    }
    storagePathList.add("/data/storage/el2/sharefiles")
    storagePathList.add("/data/storage/el2/distributedfiles")
    storagePathList
}

public func getAllStorage(f: FileInfo, fileSet: TreeSet<StorageFileInfo>): StorageFileInfo {
    if (f.size <= 0) {
    	return StorageFileInfo(f.path.toString(), 0, true)
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
    let parentStorageFileInfo = StorageFileInfo(f.path.toString(), size, true)
    parentStorageFileInfo.subfileList = storageFilesList
    parentStorageFileInfo
}

public func initStorageHandler(
    reportStorageInfo: (storageInfo: StorageInfo) -> Unit,
    sizeLimit!: Int64,
    dirSizeLimit!: Int64,
    reportTopNum!: Int64 = 5): Unit {
    sizeLimitValue = sizeLimit
    dirSizeLimitValue = dirSizeLimit
    reportTopNumValue = reportTopNum
    reportStorageInfoCallback = reportStorageInfo
}
