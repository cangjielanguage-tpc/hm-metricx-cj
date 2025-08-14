/**

 */
package ohos_app_cangjie_hm_metricx_cj.traffic

import tpc.AbilityKit.bundleManager
import tpc.AbilityKit.bundleManager.BundleFlag
import tpc.AbilityKit.UIAbilityContext
import tpc.NetworkKit.statistics
import ohos.base.BusinessException
import std.time.DateTime
import tpc.ArkData.preferences
import tpc.ArkData.preferences.*
import tpc.UIKit.global.setInterval
import stdx.encoding.json.*
import std.collection.ArrayList
import ohos.base.AppLog
import std.collection.HashMap
import tpc.UIKit.Observer.{NavDestinationSwitchInfo, on, ObserverListenerType}
import ohos_app_cangjie_hm_metricx_cj.getTargetPageName
import ohos_app_cangjie_hm_metricx_cj.PageSwitchCallBack

let pageTrafficMap: HashMap<String, PageTrafficData> = HashMap<String, PageTrafficData>()
let uid: UInt32 = GetAppUid()
var pageRxStart: Int64 = 0
var pageTxStart: Int64 = 0
var currentPageName = ""

// 获取应用UID
public func GetAppUid(): UInt32 {
    let flag = BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
    let bundleInfo = bundleManager.getBundleInfoForSelf(flag)
    let uid = bundleInfo.appInfo.getOrThrow().uid
    UInt32(uid)
}

public open class TrafficData {
    private var totalValue: Int64 = 0
    private var upTotalValue: Int64 = 0
    private var downTotalValue: Int64 =0

    public init(upTotalValue!: Int64, downTotalValue!: Int64) {
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

public class PageTrafficData <: TrafficData {
    public var pageName = ""

    public init(upTotalValue!: Int64, downTotalValue!: Int64, pageName!: String) {
        super(upTotalValue: upTotalValue, downTotalValue: downTotalValue)
        this.pageName = pageName
    }

    public func toString() {
        let jsonObj = JsonObject()
        jsonObj.put("pageName", JsonString(pageName))
        jsonObj.put("total", JsonString(total.toString()))
        jsonObj.put("upTotal", JsonString(upTotal.toString()))
        jsonObj.put("downTotal", JsonString(downTotal.toString()))
        jsonObj.toString()
    }
}

// 流量信息上报类
public class TrafficInfo {
    // 日总流量
    private var totalDailyTrafficValue: ?Int64 = None
    // 单次进程总流量
    private var totalTrafficValue: ?Int64 = None
    // 阈值
    private var limitsValue: ?Int64 = None

    mut prop totalDailyTraffic: ?Int64 {
        get() {
            totalDailyTrafficValue
        }
        set(value) {
            totalDailyTrafficValue = value
        }
    }

    mut prop totalTraffic: ?Int64 {
        get() {
            totalTrafficValue
        }
        set(value) {
            totalTrafficValue = value
        }
    }

    mut prop limits: ?Int64 {
        get() {
            limitsValue
        }
        set(value) {
            limitsValue = value
        }
    }

    public init() {}

    public init(totalDailyTrafficValue: Int64, totalTrafficValue: Int64, limitsValue: Int64) {
        this.totalDailyTrafficValue = totalDailyTrafficValue
        this.totalTrafficValue = totalTrafficValue
        this.limitsValue = limitsValue
    }

    public func toString(): String {
        let jsonObj = JsonObject()
        if (totalDailyTrafficValue.isSome()) {
            let str = totalDailyTrafficValue as String
            jsonObj.put("TotalDailyTraffic", JsonString(str.getOrThrow()))
        }
        if (totalTrafficValue.isSome()) {
            let str = totalTrafficValue as String
            jsonObj.put("TotalTraffic", JsonString(str.getOrThrow()))
        }
        if (limitsValue.isSome()) {
            let str = limitsValue as String
            jsonObj.put("limits", JsonString(str.getOrThrow()))
        }
        jsonObj.toString()
    }

    public func fromJson(jsonObj: JsonObject): TrafficInfo {
        let trafficInfo = TrafficInfo()
        if (jsonObj.get("TotalDailyTraffic").isSome()) {
            trafficInfo.totalDailyTraffic = jsonObj.get("TotalDailyTraffic").getOrThrow().toString() as Int64
        }
        if (jsonObj.get("TotalTraffic").isSome()) {
            trafficInfo.totalTraffic = jsonObj.get("TotalTraffic").getOrThrow().toString() as Int64
        }
        if (jsonObj.get("limits").isSome()) {
            trafficInfo.limits = jsonObj.get("limits").getOrThrow().toString() as Int64
        }
        trafficInfo
    }
}

// 流量监听类
private class TrafficInfoListener {
    // 是否为应用启动后第一次采用
    public var isFirstSample: Bool = true
    // 日上行/下行流量起点
    public var year: ?Int64 = None
    public var month: ?Int64 = None
    public var dayOfMonth: ?Int64 = None
    public var rxBytesAtZeroOclock: ?Int64 = None
    public var txBytesAtZeroOclock: ?Int64 = None
    // 单次进程上行/下行流量起点
    public var rxBytesAtStart: ?Int64 = None
    public var txBytesAtStart: ?Int64 = None
    // 当前采样上行/下行流量
    public var rxBytes: ?Int64 = None
    public var txBytes: ?Int64 = None
    // 单例模式
    private static var instance = TrafficInfoListener()
    public static func GetInstance() {
        instance
    }
}

private var needPersistenceStorage: Bool = false

public func initTrafficHandler(context: UIAbilityContext, report: (TrafficInfo) -> Unit, limits: ?Int64) {
    let instance = TrafficInfoListener.GetInstance()
    let trafficInfo = TrafficInfo()
    let options = preferences.Options("Traffic")
    let dataPreferences = preferences.getPreferences(context, options)
    // 从持久化存储接口取值
    if (dataPreferences.has("year")) {
        let val = dataPreferences.get("year", ValueType.NUMBER(0))
        match (val) {
            case NUMBER(v) => instance.year = Int64(v)
            case _ => ()
        }
    }
    if (dataPreferences.has("month")) {
        let val = dataPreferences.get("month", ValueType.NUMBER(0))
        match (val) {
            case NUMBER(v) => instance.month = Int64(v)
            case _ => ()
        }
    }
    if (dataPreferences.has("dayOfMonth")) {
        let val = dataPreferences.get("dayOfMonth", ValueType.NUMBER(0))
        match (val) {
            case NUMBER(v) => instance.dayOfMonth = Int64(v)
            case _ => ()
        }
    }
    if (dataPreferences.has("rxBytesAtZeroOclock")) {
        let val = dataPreferences.get("rxBytesAtZeroOclock", ValueType.NUMBER(0))
        match (val) {
            case NUMBER(v) => instance.rxBytesAtZeroOclock = Int64(v)
            case _ => ()
        }
    }
    if (dataPreferences.has("txBytesAtZeroOclock")) {
        let val = dataPreferences.get("txBytesAtZeroOclock", ValueType.NUMBER(0))
        match (val) {
            case NUMBER(v) => instance.txBytesAtZeroOclock = Int64(v)
            case _ => ()
        }
    }
    let doTrafficSample: (Array<String>) -> Unit = {
        param: Array<String> =>
        let currentTime = DateTime.now() // 当前时刻时间
        let uid = GetAppUid()
        // 异步回调函数，当前只能采用回调地狱的方式
        statistics.getUidRxBytes(
            uid,
            {
                err: ?BusinessException, data: ?Int64 =>
                if (err.isSome()) {
                    return
                }
                instance.rxBytes = data.getOrThrow()
                statistics.getUidTxBytes(
                    uid,
                    {
                        err: ?BusinessException, data: ?Int64 =>
                        if (err.isSome()) {
                            return
                        }
                        instance.txBytes = data.getOrThrow()
                        // 判断是否是程序启动后的第一次采样
                        if (instance.isFirstSample && instance.rxBytes.isSome() && instance.txBytes.isSome()) {
                            instance.isFirstSample = false
                            instance.rxBytesAtStart = instance.rxBytes
                            instance.txBytesAtStart = instance.txBytes
                        }
                        // 判断时间
                        if (currentTime.hour == 0 && currentTime.minute == 0) {
                            instance.year = currentTime.year
                            instance.month = currentTime.month.value()
                            instance.dayOfMonth = currentTime.dayOfMonth
                            instance.rxBytesAtZeroOclock = instance.rxBytes
                            instance.txBytesAtZeroOclock = instance.txBytes
                            needPersistenceStorage = true
                        }
                        let isTheSameDay: Bool = instance.year != currentTime.year || instance.month !=
                            currentTime.month.value() || instance.dayOfMonth != currentTime.dayOfMonth
                        if (instance.rxBytesAtZeroOclock.isNone() || instance.txBytesAtZeroOclock.isNone() || isTheSameDay) {
                            instance.year = currentTime.year
                            instance.month = currentTime.month.value()
                            instance.dayOfMonth = currentTime.dayOfMonth
                            instance.rxBytesAtZeroOclock = instance.rxBytes
                            instance.txBytesAtZeroOclock = instance.txBytes
                            needPersistenceStorage = true
                        }
                        // 持久化存储
                        if (needPersistenceStorage) {
                            try {
                                dataPreferences.put("year", NUMBER(Int32(instance.year.getOrThrow())))
                                dataPreferences.put("month", NUMBER(Int32(instance.month.getOrThrow())))
                                dataPreferences.put("dayOfMonth", NUMBER(Int32(instance.dayOfMonth.getOrThrow())))
                                dataPreferences.put("rxBytesAtZeroOclock", NUMBER(Int32(instance.rxBytesAtZeroOclock.getOrThrow())))
                                dataPreferences.put("txBytesAtZeroOclock", NUMBER(Int32(instance.txBytesAtZeroOclock.getOrThrow())))
                                dataPreferences.flush({err, data => ()})
                            } catch (e: Exception) {
                                AppLog.warn("Permanent storage of traffic-related data failed")
                            }
                        }
                        // 获取日总流量
                        try {
                            trafficInfo.totalDailyTraffic = (instance.rxBytes.getOrThrow() - instance.rxBytesAtZeroOclock.getOrThrow()) +
                                (instance.txBytes.getOrThrow() - instance.txBytesAtZeroOclock.getOrThrow())
                            trafficInfo.totalTraffic = (instance.rxBytes.getOrThrow() - instance.rxBytesAtStart.getOrThrow()) +
                                (instance.txBytes.getOrThrow() - instance.txBytesAtStart.getOrThrow())
                            trafficInfo.limits = limits
                            if (trafficInfo.totalDailyTraffic.getOrThrow() > limits.getOrThrow()) {
                                report(trafficInfo)
                            }
                        } catch (e: Exception) {
                            AppLog.warn("Failed to obtain traffic data.")
                        }
                    }
                )
            }
        )
    }
    setInterval(doTrafficSample, 1000, Array<String>())

    initPageTraffic(context)
}

private func initPageTraffic(context: UIAbilityContext) {
    statistics.getUidRxBytes(
        uid,
        {
            err: ?BusinessException, data: ?Int64 =>
            if (let Some(v) <- err) {
                AppLog.warn("init Rx error: ${v.toString()}")
                return
            }
            if (data.isNone()) {
                AppLog.warn("init Rx data is none")
            }
            pageRxStart = data ?? 0
            statistics.getUidTxBytes(
                uid,
                {
                    err: ?BusinessException, data: ?Int64 =>
                    if (let Some(v) <- err) {
                        AppLog.warn("Tx error: ${v.toString()}")
                        return
                    }
                    if (data.isNone()) {
                        AppLog.warn("init Tx data is none")
                    }
                    pageTxStart = data ?? 0
                    on(navDestinationSwitch, context, PageSwitchCallBack(navDestinationSwitchCallBack))
                }
            )
        }
    )


}

private func navDestinationSwitchCallBack(info: NavDestinationSwitchInfo) {
    updatePageTraffic(currentPageName)
    currentPageName = getTargetPageName(info)
}

private func updatePageTraffic(pageName: String) {
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
                return
            }
            let rxBytes = data.getOrThrow()
            let curRx = rxBytes - pageRxStart
            pageRxStart = rxBytes
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
                        return
                    }
                    let txBytes = data.getOrThrow()
                    let curTx = txBytes - pageTxStart
                    pageTxStart = txBytes
                    updatePageMap(pageName, curRx, curTx)
                }
            )
        }
    )
}

private func updatePageMap(pageName: String, curRx: Int64, curTx: Int64) {

    if(!pageTrafficMap.contains(pageName)) {
        let pageTrafficData = PageTrafficData(upTotalValue: curTx, downTotalValue: curRx, pageName: pageName)
        pageTrafficMap.add(pageName, pageTrafficData)
        return
    }
    let pageTrafficData = pageTrafficMap.get(pageName).getOrThrow()
    pageTrafficData.upTotal += curTx
    pageTrafficData.downTotal += curRx
}

