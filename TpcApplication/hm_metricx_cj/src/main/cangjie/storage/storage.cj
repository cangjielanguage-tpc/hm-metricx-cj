/**
 * Created on 2025/5/15
 */
package ohos_app_cangjie_hm_metricx_cj.storage

import tpc.AbilityKit.UIAbility
import tpc.AbilityKit.ApplicationContext
import tpc.CoreFileKit.storageStatistics.*
import tpc.CoreFileKit.fs.*
import encoding.json.JsonString
import encoding.json.JsonObject
import encoding.json.JsonException
import std.core.*
import std.sync.*
import std.fs

public class StorageInfo {
    private var appSizeValue: ?Int64 = None
    private var cacheSizeValue: ?Int64 = None
    private var dataSizeValue: ?Int64 = None

    mut prop appSize: ?Int64 {
        get() {
            appSizeValue
        }
        set(value) {
            appSizeValue = value
        }
    }
    mut prop cacheSize: ?Int64 {
        get() {
            cacheSizeValue
        }
        set(value) {
            cacheSizeValue = value
        }
    }
    mut prop dataSize: ?Int64 {
        get() {
            dataSizeValue
        }
        set(value) {
            dataSizeValue = value
        }
    }

    public init() {}

    public func toString(): String {
        let jsonObj = JsonObject()
        if (appSizeValue.isSome()) {
            jsonObj.put("appSize", JsonString(appSizeValue.getOrThrow().toString()))
        }
        if (cacheSizeValue.isSome()) {
            jsonObj.put("cacheSize", JsonString(cacheSizeValue.getOrThrow().toString()))
        }
        if (dataSizeValue.isSome()) {
            jsonObj.put("dataSize", JsonString(dataSizeValue.getOrThrow().toString()))
        }
        jsonObj.toString()
    }
}

var reportStorageInfoCallback: (storageInfo: StorageInfo) -> Unit = {info: StorageInfo =>}

public func reportStorageInfo(): Unit {
    getCurrentBundleStats(
        {
            err, data => if (err.isNone()) {
                if (data.isSome()) {
                    let storageInfo = StorageInfo()
                    storageInfo.appSize = data.getOrThrow().appSize
                    storageInfo.cacheSize = data.getOrThrow().cacheSize
                    storageInfo.dataSize = data.getOrThrow().dataSize
                    reportStorageInfoCallback(storageInfo)
                }
            }
        })
}

public func initStorageHandler(reportStorageInfo: (storageInfo: StorageInfo) -> Unit): Unit {
    reportStorageInfoCallback = reportStorageInfo
}
