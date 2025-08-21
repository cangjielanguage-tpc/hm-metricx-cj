/**

 */
package ohos_app_cangjie_hm_metricx_cj.traffic

import tpc.AbilityKit.bundleManager
import tpc.AbilityKit.bundleManager.BundleFlag
import tpc.AbilityKit.UIAbilityContext
import tpc.AbilityKit.UIAbility
import tpc.NetworkKit.statistics
import ohos.base.BusinessException
import std.time.DateTime
import tpc.ArkData.preferences
import tpc.ArkData.preferences.*
import tpc.UIKit.global.*
import stdx.encoding.json.*
import std.collection.ArrayList
import std.convert.*
import ohos.base.AppLog
import std.collection.HashMap
import tpc.UIKit.Observer.{NavDestinationSwitchInfo, on, ObserverListenerType}
import ohos_app_cangjie_hm_metricx_cj.*

let pageTrafficMap: HashMap<String, PageTrafficInfo> = HashMap<String, PageTrafficInfo>()
let uid: UInt32 = GetAppUid()
var pageRxStart: Int64 = 0
var pageTxStart: Int64 = 0
var prevUpload: Int64 = 0
var prevDownload: Int64 = 0
var inited: Bool = false
var uiContext: Option<UIAbilityContext> = None
var currentPageName = defaultPageName
var SAMPLE_TIME: Int64 = 0
var SAMPLE_THRESHOLD: Int64 = 0
var sampleId : Int64 = -1
var reportTrafficCallback: (sampleTraffixInfo: SampleTrafficInfo) -> Unit = {
    sampleTraffixInfo: SampleTrafficInfo =>
}

// current
private let KEY_CURRENT_UPLOAD: String = "current_upload"
private let KEY_CURRENT_DOWNLOAD: String = "current_download"
// today
private let KEY_TODAY_DATE: String = "today_date"
private let KEY_TODAY_UPLOAD: String = "today_upload"
private let KEY_TODAY_DOWNLOAD: String = "today_download"
// yesterday
private let KEY_YESTERDAY_DATE: String = "yesterday_date"
private let KEY_YESTERDAY_UPLOAD: String = "yesterday_upload"
private let KEY_YESTERDAY_DOWNLOAD: String = "yesterday_download"
private let KEY_YESTERDAY_REPORTED: String = "yesterday_reported"

// 获取应用UID
public func GetAppUid(): UInt32 {
    let flag = BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
    let bundleInfo = bundleManager.getBundleInfoForSelf(flag)
    let uid = bundleInfo.appInfo.getOrThrow().uid
    UInt32(uid)
}

public open class TrafficInfo {
    private var totalValue: Int64 = 0
    private var upTotalValue: Int64 = 0
    private var downTotalValue: Int64 =0
    public init() {}
    public init(upTotalValue: Int64, downTotalValue: Int64) {
        this.upTotalValue = upTotalValue
        this.downTotalValue = downTotalValue
        this.totalValue = upTotalValue + downTotalValue
    }
    public prop total: Int64 {
        get() {
            totalValue
        }
    }
    public mut prop upTotal: Int64 {
        get() {
            upTotalValue
        }
        set(value) {
            upTotalValue = value
            totalValue = upTotalValue + downTotalValue
        }
    }
    public mut prop downTotal: Int64 {
        get() {
            downTotalValue
        }
        set(value) {
            downTotalValue = value
            totalValue = upTotalValue + downTotalValue
        }
    }
}

public class SystemTrafficInfo <: TrafficInfo {
    private var timeStampValue: String = ""

    public init() {}
    public init(timeStamp: String, upload: Int64, download: Int64) {
        super(upload, download)
        this.timeStampValue = timeStamp
    }

    public mut prop timeStamp: String {
        get() {
            timeStampValue
        }
        set(value) {
            timeStampValue = value
        }
    }
    public func toString() {
        let jsonObj = JsonObject()
        jsonObj.put("timeStamp", JsonString(timeStampValue))
        jsonObj.put("total", JsonString(total.toString()))
        jsonObj.put("upTotal", JsonString(upTotal.toString()))
        jsonObj.put("downTotal", JsonString(downTotal.toString()))
        jsonObj.toString()
    }
}

public class PageTrafficInfo <: TrafficInfo {
    private var pageNameValue: String = ""

    public init() {}
    public init(pageName: String, upload: Int64, download: Int64) {
        super(upload, download)
        this.pageNameValue = pageName
    }

    public mut prop pageName: String {
        get() {
            pageNameValue
        }
        set(value) {
            pageNameValue = value
        }
    }
    public func toString() {
        let jsonObj = JsonObject()
        jsonObj.put("pageName", JsonString(pageNameValue))
        jsonObj.put("total", JsonString(total.toString()))
        jsonObj.put("upTotal", JsonString(upTotal.toString()))
        jsonObj.put("downTotal", JsonString(downTotal.toString()))
        jsonObj.toString()
    }
}

public class DayTrafficInfo <: TrafficInfo {
    private var dateValue: String = ""

    public init(date: String, upload: Int64, download: Int64) {
        super(upload, download)
        this.date = date
    }

    public mut prop date: String {
        get() {
            dateValue
        }
        set(value) {
            dateValue = value
        }
    }
    public func toString() {
        let jsonObj = JsonObject()
        jsonObj.put("date", JsonString(dateValue))
        jsonObj.put("total", JsonString(total.toString()))
        jsonObj.put("upTotal", JsonString(upTotal.toString()))
        jsonObj.put("downTotal", JsonString(downTotal.toString()))
        jsonObj.toString()
    }
}

public class SampleTrafficInfo {
    private var systemInfoValue: SystemTrafficInfo = SystemTrafficInfo()
    private var pageInfoMapValue: HashMap<String, PageTrafficInfo> = HashMap<String, PageTrafficInfo>()
    public init() {}
    public init(systemInfo: SystemTrafficInfo, pageInfoMap: HashMap<String, PageTrafficInfo>) {
        systemInfoValue = systemInfo
        pageInfoMapValue = pageInfoMap
    }
    public mut prop systemInfo: SystemTrafficInfo {
        get() {
            systemInfoValue
        }
        set(value) {
            systemInfoValue = value
        }
    }
    public mut prop pageInfoMap: HashMap<String, PageTrafficInfo> {
        get() {
            pageInfoMapValue
        }
        set(value) {
            pageInfoMapValue = value
        }
    }
}

private func setStoredData(key: String, value: String): Bool {
    var status: Bool = false
    try {
    	let options = preferences.Options("Traffic")
        let dataPreferences = preferences.getPreferences(uiContext.getOrThrow(), options)
        dataPreferences.put(key, preferences.ValueType.STRING(value))
        dataPreferences.flush({err,data =>})
        status = true
    } catch (e: Exception) {
    	AppLog.warn(e.toString())
    }
    status
}

private func getStoredData(key: String): String {
    var value: String = ""
    try {
    	let options = preferences.Options("Traffic")
        let dataPreferences = preferences.getPreferences(uiContext.getOrThrow(), options)
        let status: Bool = dataPreferences.has(key)
        if(status) {
            let val = dataPreferences.get(key, preferences.ValueType.STRING(""))
            match (val) {
            	case preferences.ValueType.STRING(v) => value = v
                case _ => ()
            }
        }
    } catch (e: Exception) {
    	AppLog.warn(e.toString())
    }
    value
}

public func initTrafficHandler(
    context: UIAbilityContext,
    reportTraffic: (sampleTraffixInfo: SampleTrafficInfo) -> Unit,
    sampleTime!: Int64 = 10 * 60 * 1000,
    sampleThreshold!: Int64 = 50 * 1024 * 1024
) {
    uiContext = context
    reportTrafficCallback = reportTraffic
    on(navDestinationSwitch, uiContext.getOrThrow(), PageSwitchCallBack(navDestinationSwitchCallBack))
    SAMPLE_TIME = sampleTime
    SAMPLE_THRESHOLD = sampleThreshold
    doTrafficSample()
    sampleId = setInterval(doTrafficSample, SAMPLE_TIME, Array<String>())
}

private func processUidTrafficBytes(callback: (upload: Int64, download: Int64) -> Unit) {
    statistics.getUidRxBytes(
        uid,
        {
            err: ?BusinessException, data: ?Int64 =>
            if (let Some(v) <- err) {
                AppLog.warn("Rx error: ${v.toString()}")
                return
            }
            if (data.isNone()) {
                AppLog.warn("Rx data is none")
            }
            let curDownload = data ?? 0
            statistics.getUidTxBytes(
                uid,
                {
                    err: ?BusinessException, data: ?Int64 =>
                    if (let Some(v) <- err) {
                        AppLog.warn("Tx error: ${v.toString()}")
                        return
                    }
                    if (data.isNone()) {
                        AppLog.warn("Tx data is none")
                    }
                    let curUpload = data ?? 0
                    callback(curUpload, curDownload)
                }
            )
        }
    )
}

let updataPageMapCallback: (upload: Int64, download: Int64) -> Unit = {
    upload: Int64, download: Int64 =>
    let curTx = upload - pageTxStart
    let curRx = download - pageRxStart
    updatePageMap(currentPageName, curTx, curRx)
    pageTxStart = upload
    pageRxStart = download
}

let updateDayTrafficCallback: (upload: Int64, download: Int64) -> Unit = {
    upload: Int64, download: Int64 =>
    let todayDate: String = getTodayDate()
    let todayDateStored: String = getStoredData(KEY_TODAY_DATE)
    if (!todayDateStored.isEmpty() && todayDate != todayDateStored) {
        // update yesterday data
        setStoredData(KEY_YESTERDAY_DATE, getStoredData(KEY_TODAY_DATE))
        setStoredData(KEY_YESTERDAY_UPLOAD, getStoredData(KEY_TODAY_UPLOAD))
        setStoredData(KEY_YESTERDAY_DOWNLOAD, getStoredData(KEY_TODAY_DOWNLOAD))
        setStoredData(KEY_YESTERDAY_REPORTED, "false")

        // reset today data
        setStoredData(KEY_TODAY_DATE, todayDate)
        setStoredData(KEY_TODAY_UPLOAD, "0")
        setStoredData(KEY_TODAY_DOWNLOAD, "0")
    } else {
        setStoredData(KEY_TODAY_DATE, todayDate)
        // upload
        let todayUpload: Int64 = Int64.tryParse(getStoredData(KEY_TODAY_UPLOAD)).getOrDefault({=> 0})
        let prevUpload: Int64 = Int64.tryParse(getStoredData(KEY_CURRENT_UPLOAD)).getOrDefault({=> 0})
        let newUpload: Int64 = todayUpload + upload - prevUpload
        setStoredData(KEY_TODAY_UPLOAD, newUpload.toString())
        // download
        let todayDownload: Int64 = Int64.tryParse(getStoredData(KEY_TODAY_DOWNLOAD)).getOrDefault({=> 0})
        let prevDownload: Int64 = Int64.tryParse(getStoredData(KEY_CURRENT_DOWNLOAD)).getOrDefault({=> 0})
        let newDownload: Int64 = todayDownload + download - prevDownload
        setStoredData(KEY_TODAY_DOWNLOAD, newDownload.toString())
    }
    setStoredData(KEY_CURRENT_DOWNLOAD, upload.toString())
    setStoredData(KEY_CURRENT_DOWNLOAD, download.toString())
}

let sampleCallback: (upload: Int64, download: Int64) -> Unit = {
    upload: Int64, download: Int64 =>
    if (!inited) {
        inited = true
    } else {
        let deltaUpload: Int64 = upload - prevUpload
        let deltaDownload: Int64 = download - prevDownload
        let delta: Int64 = deltaUpload + deltaDownload
        if (delta >= SAMPLE_THRESHOLD) {
            let curTimeStamp = getCurTimeStamp()
            let systemTrafficInfo = SystemTrafficInfo(curTimeStamp, deltaUpload, deltaDownload)
            let sampleTrafficInfo = SampleTrafficInfo(systemTrafficInfo, pageTrafficMap)
            reportTrafficCallback(sampleTrafficInfo)
        }
    }
    prevUpload = upload
    prevDownload = download
    pageTxStart = upload
    pageRxStart = download
    pageTrafficMap.clear()
    updateDayTrafficCallback(upload, download)
}

private func doTrafficSample(array: Array<String>) {
    processUidTrafficBytes(sampleCallback)
}

private func navDestinationSwitchCallBack(info: NavDestinationSwitchInfo) {
    processUidTrafficBytes(updataPageMapCallback)
    currentPageName = getTargetPageName(info)
}

private func updatePageMap(pageName: String, curTx: Int64, curRx: Int64) {
    if(!pageTrafficMap.contains(pageName)) {
        let pageTrafficInfo = PageTrafficInfo(pageName, curTx, curRx)
        pageTrafficMap.add(pageName, pageTrafficInfo)
        return
    }
    let pageTrafficInfo = pageTrafficMap.get(pageName).getOrThrow()
    pageTrafficInfo.upTotal += curTx
    pageTrafficInfo.downTotal += curRx
}

public func getYesterdayTraffic(): Option<DayTrafficInfo> {
    var res: Option<DayTrafficInfo> = None
    let reported: String = getStoredData(KEY_YESTERDAY_REPORTED)
    let yesterdayStored: String = getStoredData(KEY_YESTERDAY_DATE)
    if( !yesterdayStored.isEmpty() && reported == "false") {
        let date: String = getStoredData(KEY_YESTERDAY_DATE)
        let upload: Int64 = Int64.tryParse(getStoredData(KEY_YESTERDAY_UPLOAD)).getOrDefault({=> 0})
        let download: Int64 = Int64.tryParse(getStoredData(KEY_YESTERDAY_DOWNLOAD)).getOrDefault({=> 0})
        res = DayTrafficInfo(date, upload, download)
        setStoredData(KEY_YESTERDAY_REPORTED, "true")
    }
    res
}
public func destroyTrafficHandler() {
    if (sampleId != -1) {
        clearInterval(sampleId)
    }
    processUidTrafficBytes(updateDayTrafficCallback)
}

