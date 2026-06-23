/**
 * Created on 2025/9/18
 */
package ohos_app_cangjie_hm_metricx_cj.traffic

import std.convert.*
import std.collection.HashMap
import ohos_app_cangjie_hm_metricx_cj.util.*
import ohos.ark_interop_macro.*
import ohos.ark_interop.*
import ohos.hilog.Hilog

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

// 页面进入→离开完整流量增量的独立基线。
// 注意：pageTxStart/pageRxStart 会在每次周期采样(sampleCallback)中被重置，
// 它们是"自上次采样以来"的基线，不能直接用于计算页面生命周期内的完整增量。
// 此处 pageEnter* 仅在页面切换与 getAndResetCurrentPageTraffic 调用时重置，
// 因此从页面进入到调用获取期间累计的增量不会被周期采样截断。
var pageEnterTxStart: Int64 = 0
var pageEnterRxStart: Int64 = 0
// init 时缓存 getUidRxAndTxBytes，供 getAndResetCurrentPageTraffic 直接复用。
var _getUidRxAndTxBytes: (cb: (download: Int64, upload: Int64, pageName: String) -> Unit, pageName: String) -> Unit = {_, _ =>}

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
        InteropPageTrafficInfo(this.upTotal, this.downTotal, this.pageName)
    }
}

@Interop[ArkTS]
public class InteropDayTrafficInfo {
    public let total: Int64
    public let upTotal: Int64
    public let downTotal: Int64
    public let date: String
    public init(u: Int64, d: Int64, date: String) {
        this.upTotal = u
        this.downTotal = d
        this.total = u + d
        this.date = date
    }
}

public class DayTrafficInfo <: TrafficInfo {
    private var date: String = ""

    public init(date: String, upload: Int64, download: Int64) {
        super(upload, download)
        this.date = date
    }

    func toInteropDayTrafficInfo(): InteropDayTrafficInfo {
        InteropDayTrafficInfo(this.upTotal, this.downTotal, this.date)
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

foreign func gettid(): Int32
foreign func getpid(): Int32

var globalContext: ?JSContext = None
let _ = JSModule.registerModule { c, _ =>
    if (unsafe{ getpid() != gettid()}) {
        let error_report = Exception()
        for (element in error_report.getStackTrace()) {
            Hilog.error(0, "test", "    at ${element.declaringClass}.${element.methodName}(${element.fileName}:${element.lineNumber})")
        }
        let errCls = c.global["Error"].asClass()
        let errObJ = errCls.new().asObject()
        let stack = errObJ["stack"].toString()
        Hilog.error(0, "test", "should never import that at worker\n${stack}")
    }
    if (globalContext.isNone()){
        globalContext = c
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
        JSCurrentJSContext.set(globalContext.getOrThrow())
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
        metricx_warn(e.toString())
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
        metricx_warn(e.toString())
    }
    value
}

@Interop[ArkTS]
public interface TrafficPreference {
    func put(key: String, value: String): Unit
    func has(key: String): Bool
    func get(key: String, defaultValue: String): String
}

let updataPageMapCallback: (download: Int64, upload: Int64, pageName: String) -> Unit = {
    download: Int64, upload: Int64, pageName: String =>
        let curTx = upload - pageTxStart
        let curRx = download - pageRxStart
        updatePageMap(pageName, curTx, curRx)
        pageTxStart = upload
        pageRxStart = download
}
// 检测日期切换，将昨天的流量数据迁移到 YESTERDAY 字段
// 需要在检查昨日流量上报之前调用，确保数据已正确迁移
private func checkDateSwitch(): Unit {
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
    }
}

let updateDayTrafficCallback: (download: Int64, upload: Int64) -> Unit = {
    download: Int64, upload: Int64 =>
        // 先检测日期切换
        checkDateSwitch()

        // 更新今日流量累计
        setStoredData(KEY_TODAY_DATE, getTodayDate())
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

        setStoredData(KEY_CURRENT_UPLOAD, upload.toString())
        setStoredData(KEY_CURRENT_DOWNLOAD, download.toString())
}
let sampleCallback: (download: Int64, upload: Int64, pageName: String) -> Unit = {
    download: Int64, upload: Int64, pageName: String =>
        if (!inited) {
            inited = true
        } else {
            let deltaUpload: Int64 = upload - prevUpload
            let deltaDownload: Int64 = download - prevDownload
            let delta: Int64 = deltaUpload + deltaDownload
            if (delta >= SAMPLE_THRESHOLD) {
                // update page traffic
                let curTx = upload - pageTxStart
                let curRx = download - pageRxStart
                updatePageMap(pageName, curTx, curRx)

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
        updateDayTrafficCallback(download, upload)
}

public func initTrafficHandler(
    preference: TrafficPreference,
    onNavDestinationSwitch: (cb: (targetPageName: String) -> Unit) -> Unit,
    repeatSampleTraffic: (sample: () -> Unit) -> Unit,
    getUidRxAndTxBytes: (cb: (download: Int64, upload: Int64, pageName: String) -> Unit, pageName: String) -> Unit,
    reportTraffic: (sampleTraffixInfo: InteropSampleTrafficInfo) -> Unit,
    reportYesterdayTraffic: (yesterdayTraffic: InteropDayTrafficInfo) -> Unit,
    sampleThreshold!: Int64 = 50 * 1024 * 1024
) {
    tPreference = preference
    reportTrafficCallback = reportTraffic
    SAMPLE_THRESHOLD = sampleThreshold
    _getUidRxAndTxBytes = getUidRxAndTxBytes

    // 初始化时先检测日期切换，确保昨日流量数据已正确迁移
    checkDateSwitch()

    let reportPendingYesterdayTraffic = {
        =>
            let yesterdayTraffic = getYesterdayTraffic()
            if (let Some(v) <- yesterdayTraffic) {
                reportYesterdayTraffic(v)
            }
    }

    reportPendingYesterdayTraffic()

    let doTrafficSample = {
        => getUidRxAndTxBytes({rxBytes, txBytes, pageName =>
            sampleCallback(rxBytes, txBytes, pageName)
            reportPendingYesterdayTraffic()
        }, currentPageName)
    }
    // 注意：ArkTS 回调参数顺序为 (rxBytes, txBytes, pageName)
    // 仓颉侧回调参数顺序为 (download, upload, pageName)
    // rxBytes = 下行(download), txBytes = 上行(upload)
    // 首次采样：初始化页面进入基线为首个真实字节，避免首页面增量包含历史值
    getUidRxAndTxBytes({download, upload, pageName =>
        sampleCallback(download, upload, pageName)
        pageEnterTxStart = upload
        pageEnterRxStart = download
        reportPendingYesterdayTraffic()
    }, currentPageName)
    onNavDestinationSwitch(
        {
            targetPageName: String =>
                getUidRxAndTxBytes(updataPageMapCallback, currentPageName)
                currentPageName = targetPageName
        }
    )
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

private func getYesterdayTraffic(): Option<InteropDayTrafficInfo> {
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
    if (let Some(v) <- res) {
        v.toInteropDayTrafficInfo()
    } else {
        Option.None
    }
}

/**
 * 获取当前页面从进入到调用时刻期间的完整流量增量，调用后自动清零，
 * 供下一个页面重新计数。
 *
 * 用于发热异常快照中关联当前页面的流量消耗：上层在页面切换（离开上一页）时调用，
 * 即可拿到上一个页面从进入到离开期间的完整流量增量。
 *
 * 实现要点：
 * - 使用独立的 pageEnter* 基线（仅在页面切换与本函数调用时重置），
 *   而非 pageTxStart/pageRxStart（后者每次周期采样都会被重置），
 *   从而保证页面生命周期内的完整增量不被周期采样截断。
 * - 返回的 pageName 取调用时刻的 currentPageName（即尚未切走的离开页），
 *   与现有 updataPageMapCallback 的归属策略保持一致。
 * - getUidRxAndTxBytes 本质异步（statistics API 返回 Promise），
 *   结果经 onResult 回调返回，符合现有 traffic 模块的回调风格。
 *
 * @param onResult 结果回调，传入页面增量（upTotal=上行, downTotal=下行, pageName=离开页）
 */
public func getAndResetCurrentPageTraffic(onResult: (info: InteropPageTrafficInfo) -> Unit): Unit {
    let pageName = currentPageName
    _getUidRxAndTxBytes({download, upload, _ =>
        let deltaTx = upload - pageEnterTxStart
        let deltaRx = download - pageEnterRxStart
        // 清零基线，供下一个页面重新计数
        pageEnterTxStart = upload
        pageEnterRxStart = download
        onResult(InteropPageTrafficInfo(deltaTx, deltaRx, pageName))
    }, pageName)
}

public func destroyTrafficHandler(getUidRxAndTxBytes: (cb: (download: Int64, upload: Int64) -> Unit) -> Unit) {
    getUidRxAndTxBytes(updateDayTrafficCallback)
}
