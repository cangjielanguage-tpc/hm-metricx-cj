/**
 * Created on 2025/9/18
 */
package ohos_app_cangjie_hm_metricx_cj.traffic

import std.convert.*
import ohos.base.AppLog
import std.collection.HashMap
import ohos_app_cangjie_hm_metricx_cj.util.*
import ohos.ark_interop_macro.*
import ohos.ark_interop.*

let pageTrafficMap: HashMap<String, PageTrafficInfo> = HashMap<String, PageTrafficInfo>()
var pageRxStart: Int64 = 0
var pageTxStart: Int64 = 0
var prevUpload: Int64 = 0
var prevDownload: Int64 = 0
var inited: Bool = false
var currentPageName = defaultPageName
var SAMPLE_TIME: Int64 = 0
var SAMPLE_THRESHOLD: Int64 = 0
var sampleId: Int64 = -1
var reportTrafficCallback: (sampleTraffixInfo: InteropSampleTrafficInfo) -> Unit = {_ =>}

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

public open class TrafficInfo {
    private var totalValue: Int64 = 0
    private var upTotalValue: Int64 = 0
    private var downTotalValue: Int64 = 0
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

@Interop[ArkTS]
public class InteropSystemTrafficInfo {
    public let total: Int64
    public let upTotal: Int64
    public let downTotal: Int64
    public let timeStamp: String
    public init(u: Int64, d: Int64, t: String) {
        this.upTotal = u
        this.downTotal = d
        this.total = u + d
        this.timeStamp = t
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

    func toInteropSystemTrafficInfo(): InteropSystemTrafficInfo {
        InteropSystemTrafficInfo(this.upTotal, this.downTotal, this.timeStamp)
    }
}

@Interop[ArkTS]
public class InteropPageTrafficInfo {
    public let total: Int64
    public let upTotal: Int64
    public let downTotal: Int64
    public let pageName: String
    public init(u: Int64, d: Int64, p: String) {
        this.upTotal = u
        this.downTotal = d
        this.total = u + d
        this.pageName = p
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

    func toInteropPageTrafficInfo(): InteropPageTrafficInfo {
        InteropPageTrafficInfo(this.upTotal, downTotal, this.pageName)
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
}

@Interop[ArkTS]
public class InteropSampleTrafficInfo {
    public let systemInfo: InteropSystemTrafficInfo
    public let pageInfoMap: JSHashMapEx<String, InteropPageTrafficInfo>
    public init(s: InteropSystemTrafficInfo, p: JSHashMapEx<String, InteropPageTrafficInfo>) {
        this.systemInfo = s
        this.pageInfoMap = p
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
    func toInteropSampleTrafficInfo(): InteropSampleTrafficInfo {
        let pageInfos = JSHashMapEx<String, InteropPageTrafficInfo>()
        for (entry in this.pageInfoMap) {
            pageInfos.set(entry[0], entry[1].toInteropPageTrafficInfo())
        }
        InteropSampleTrafficInfo(this
            .systemInfo
            .toInteropSystemTrafficInfo(), pageInfos)
    }
}

var tPreference: Option<TrafficPreference> = None

private func setStoredData(key: String, value: String): Bool {
    var status: Bool = false
    try {
        if (let Some(p) <- tPreference) {
            p.put(key, value)
            status = true
        }
    } catch (e: Exception) {
        AppLog.warn(e.toString())
    }
    status
}

private func getStoredData(key: String): String {
    var value: String = ""
    try {
        if (let Some(p) <- tPreference) {
            if (p.has(key)) {
                value = p.get(key, "")
            }
        }
    } catch (e: Exception) {
        AppLog.warn(e.toString())
    }
    value
}

@Interop[ArkTS]
public interface TrafficPreference {
    func put(key: String, value: String): Unit
    func has(key: String): Bool
    func get(key: String, defaultValue: String): String
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
            let todayUpload: Int64 = Int64
                .tryParse(getStoredData(KEY_TODAY_UPLOAD))
                .getOrDefault({=> 0})
            let prevUpload: Int64 = Int64
                .tryParse(getStoredData(KEY_CURRENT_UPLOAD))
                .getOrDefault({=> 0})
            let newUpload: Int64 = todayUpload + upload - prevUpload
            setStoredData(KEY_TODAY_UPLOAD, newUpload.toString())
            // download
            let todayDownload: Int64 = Int64
                .tryParse(getStoredData(KEY_TODAY_DOWNLOAD))
                .getOrDefault({=> 0})
            let prevDownload: Int64 = Int64
                .tryParse(getStoredData(KEY_CURRENT_DOWNLOAD))
                .getOrDefault({=> 0})
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
                reportTrafficCallback(SampleTrafficInfo(systemTrafficInfo, pageTrafficMap).toInteropSampleTrafficInfo())
            }
        }
        prevUpload = upload
        prevDownload = download
        pageTxStart = upload
        pageRxStart = download
        pageTrafficMap.clear()
        updateDayTrafficCallback(upload, download)
}

public func initTrafficHandler(
    preference: TrafficPreference,
    onNavDestinationSwitch: (cb: (targetPageName: String) -> Unit) -> Unit,
    repeatSampleTraffic: (sample: () -> Unit) -> Unit,
    getUidRxAndTxBytes: (cb: (rxBytes: Int64, txBytes: Int64) -> Unit) -> Unit,
    reportTraffic: (sampleTraffixInfo: InteropSampleTrafficInfo) -> Unit,
    sampleThreshold!: Int64 = 50 * 1024 * 1024
) {
    tPreference = preference
    reportTrafficCallback = reportTraffic
    SAMPLE_THRESHOLD = sampleThreshold
    onNavDestinationSwitch(
        {
            targetPageName: String =>
                getUidRxAndTxBytes(updataPageMapCallback)
                currentPageName = targetPageName
        }
    )

    let doTrafficSample = {
        => getUidRxAndTxBytes({rxBytes, txBytes => sampleCallback(rxBytes, txBytes)})
    }

    doTrafficSample()
    repeatSampleTraffic(doTrafficSample)
}

private func updatePageMap(pageName: String, curTx: Int64, curRx: Int64) {
    if (!pageTrafficMap.contains(pageName)) {
        let pageTrafficInfo = PageTrafficInfo(pageName, curTx, curRx)
        pageTrafficMap.add(pageName, pageTrafficInfo)
        return
    }
    let pageTrafficInfo = pageTrafficMap
        .get(pageName)
        .getOrThrow()
    pageTrafficInfo.upTotal += curTx
    pageTrafficInfo.downTotal += curRx
}

func getYesterdayTraffic(): Option<DayTrafficInfo> {
    var res: Option<DayTrafficInfo> = None
    let reported: String = getStoredData(KEY_YESTERDAY_REPORTED)
    let yesterdayStored: String = getStoredData(KEY_YESTERDAY_DATE)
    if (!yesterdayStored.isEmpty() && reported == "false") {
        let date: String = getStoredData(KEY_YESTERDAY_DATE)
        let upload: Int64 = Int64
            .tryParse(getStoredData(KEY_YESTERDAY_UPLOAD))
            .getOrDefault({=> 0})
        let download: Int64 = Int64
            .tryParse(getStoredData(KEY_YESTERDAY_DOWNLOAD))
            .getOrDefault({=> 0})
        res = DayTrafficInfo(date, upload, download)
        setStoredData(KEY_YESTERDAY_REPORTED, "true")
    }
    res
}

public func destroyTrafficHandler(getUidRxAndTxBytes: (cb: (rxBytes: Int64, txBytes: Int64) -> Unit) -> Unit) {
    getUidRxAndTxBytes(updateDayTrafficCallback)
}
