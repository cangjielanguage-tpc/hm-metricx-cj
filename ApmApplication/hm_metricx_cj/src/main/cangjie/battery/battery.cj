/**
 * Created on 2025/9/20
 */
package ohos_app_cangjie_hm_metricx_cj.battery

import ohos_app_cangjie_hm_metricx_cj.util.*
import std.convert.*
import std.fs.*
import std.time.*
import std.collection.*
import std.posix.isDir
import ohos.ark_interop.*
import ohos.ark_interop_macro.*
import std.env.*

@Interop[ArkTS]
public class InteropBatteryUsageInfo {
    public let currentPageName: Option<String>
    public let level: Option<Int32>
    public let temperature: Option<Float64>
    public let capacity: Option<Float64>
    public let scale: Option<Int32>
    public let status: Option<Int32>
    public let health: Option<Int32>
    public let voltage: Option<Int32>
    public let technology: Option<String>
    public let plugged: Option<Int32>
    public let charging: Option<Bool>
    public let limit: Option<Int32>
    public let brightness: Option<Int32>
    public let useTime: Option<Int64>
    public let time: Option<Int64>
    public init(c: Option<String>, l: Option<Int32>, t: Option<Float64>, ca: Option<Float64>, sc: Option<Int32>,
        st: Option<Int32>, h: Option<Int32>, v: Option<Int32>, te: Option<String>, p: Option<Int32>, ch: Option<Bool>,
        li: Option<Int32>, b: Option<Int32>, u: Option<Int64>, ti: Option<Int64>) {
        this.currentPageName = c
        this.level = l
        this.temperature = t
        this.capacity = ca
        this.scale = sc
        this.status = st
        this.health = h
        this.voltage = v
        this.technology = te
        this.plugged = p
        this.charging = ch
        this.limit = li
        this.brightness = b
        this.useTime = u
        this.time = ti
    }
}

public class BatteryUsageInfo {
    private var currentPageNameValue: ?String = None
    private var levelValue: ?Int32 = None
    private var temperatureValue: ?Float64 = None
    private var capacityValue: ?Float64 = None
    private var scaleValue: ?Int32 = None
    private var statusValue: ?Int32 = None
    private var healthValue: ?Int32 = None
    private var voltageValue: ?Int32 = None
    private var technologyValue: ?String = None
    private var pluggedValue: ?Int32 = None
    private var chargingValue: ?Bool = None
    private var limitValue: ?Int32 = None
    private var brightnessValue: ?Int32 = None
    private var useTimeValue: ?Int64 = None
    private var timeValue: ?Int64 = None

    mut prop currentPageName: ?String {
        get() {
            currentPageNameValue
        }
        set(value) {
            currentPageNameValue = value
        }
    }
    mut prop level: ?Int32 {
        get() {
            levelValue
        }
        set(value) {
            levelValue = value
        }
    }
    mut prop temperature: ?Float64 {
        get() {
            temperatureValue
        }
        set(value) {
            temperatureValue = value
        }
    }
    mut prop capacity: ?Float64 {
        get() {
            capacityValue
        }
        set(value) {
            capacityValue = value
        }
    }
    mut prop scale: ?Int32 {
        get() {
            scaleValue
        }
        set(value) {
            scaleValue = value
        }
    }
    mut prop status: ?Int32 {
        get() {
            statusValue
        }
        set(value) {
            statusValue = value
        }
    }
    mut prop health: ?Int32 {
        get() {
            healthValue
        }
        set(value) {
            healthValue = value
        }
    }
    mut prop voltage: ?Int32 {
        get() {
            voltageValue
        }
        set(value) {
            voltageValue = value
        }
    }
    mut prop technology: ?String {
        get() {
            technologyValue
        }
        set(value) {
            technologyValue = value
        }
    }
    mut prop plugged: ?Int32 {
        get() {
            pluggedValue
        }
        set(value) {
            pluggedValue = value
        }
    }
    mut prop charging: ?Bool {
        get() {
            chargingValue
        }
        set(value) {
            chargingValue = value
        }
    }
    mut prop limit: ?Int32 {
        get() {
            limitValue
        }
        set(value) {
            limitValue = value
        }
    }
    mut prop brightness: ?Int32 {
        get() {
            brightnessValue
        }
        set(value) {
            brightnessValue = value
        }
    }
    mut prop useTime: ?Int64 {
        get() {
            useTimeValue
        }
        set(value) {
            useTimeValue = value
        }
    }
    mut prop time: ?Int64 {
        get() {
            timeValue
        }
        set(value) {
            timeValue = value
        }
    }

    public init() {
        this.scale = 100
    }

    public init(limit: Int32) {
        this.scale = 100
        this.limit = limit
    }

    func toInteropBatteryUsageInfo(): InteropBatteryUsageInfo {
        InteropBatteryUsageInfo(currentPageName, level, temperature, capacity, scale, status, health, voltage,
            technology, plugged, charging, limit, brightness, useTime, time)
    }
}

@Interop[ArkTS]
public interface BatteryInfoInterface {
    func getBatterySOC(): Int32
    func getChargingStatus(): Int32
    func getHealthStatus(): Int32
    func getPluggedType(): Int32
    func getVoltage(): Int32
    func getTechnology(): String
    func getBatteryTemperature(): Int32
}

var _batterInterface: Option<BatteryInfoInterface> = None
var _getBrightness: () -> Int32 = {=> 0}
var _getRunningProcessInfo: ((status: Bool) -> Unit) -> Unit = {_ =>}
var _getUptime: () -> Int64 = {=> 0}

private func isPluggedStatus(): Bool {
    if (let Some(inter) <- _batterInterface) {
        return inter.getPluggedType() != 0
    }
    false
}

var _reportBatteryCallback: (info: InteropBatteryUsageInfo) -> Unit = {_ =>}
var batteryLimit: Int32 = 1
var lastLevel: Int32 = -1
var lastTime: Int64 = -1 // TODO 初始化定义改变是否有影响
var lastScreenOnTimeStamp: Int64 = -1 // TODO 初始化定义改变是否有影响
var screenOnTotalSecond: Int64 = 0
var frontStatus: Bool = true
var currentPageName: String = defaultPageName

private func reset() {
    lastLevel = -1
    screenOnTotalSecond = 0
    lastScreenOnTimeStamp = _getUptime()
}

let onBatteryChanged = {
    =>
        let isCharging: Bool = isPluggedStatus()
        if (isCharging) {
            reset()
        } else {
            var nowLevel: Int32 = 0
            if (let Some(inter) <- _batterInterface) {
                nowLevel = inter.getBatterySOC()
            }
            if (lastLevel < 0) {
                lastLevel = nowLevel
                lastTime = _getUptime()
                lastScreenOnTimeStamp = lastTime
                screenOnTotalSecond = 0
            } else if (nowLevel == lastLevel) {
            } else if ((nowLevel + batteryLimit) <= lastLevel) {
                let nowTime = _getUptime()
                let elapsedSecond = (nowTime - lastTime) / 1000

                lastTime = nowTime
                lastLevel = nowLevel

                if (frontStatus) {
                    screenOnTotalSecond += (nowTime - lastScreenOnTimeStamp) / 1000
                }

                let screenOnSecond: Int64 = screenOnTotalSecond
                screenOnTotalSecond = 0
                lastScreenOnTimeStamp = nowTime

                let info: BatteryUsageInfo = BatteryUsageInfo(batteryLimit)
                info.currentPageName = currentPageName
                info.level = nowLevel
                info.scale = 100
                var temperature: Int32 = 0
                var chargingStatus: Int32 = 0
                var health: Int32 = 0
                var voltage: Int32 = 0
                var technology: String = ""
                var plugged: Int32 = 0
                var brightness: Int32 = 0
                if (let Some(inter) <- _batterInterface) {
                    temperature = inter.getBatteryTemperature()
                    chargingStatus = inter.getChargingStatus()
                    health = inter.getHealthStatus()
                    voltage = inter.getVoltage()
                    technology = inter.getTechnology()
                    plugged = inter.getPluggedType()
                }
                brightness = _getBrightness()
                info.temperature = Float64(temperature) / Float64(10.0)
                info.health = health
                info.voltage = voltage / 1000
                info.technology = technology
                info.plugged = plugged
                info.charging = isPluggedStatus()
                info.brightness = brightness
                info.useTime = screenOnSecond
                info.time = elapsedSecond
                _reportBatteryCallback(info.toInteropBatteryUsageInfo())
            }
        }
}
let onConnected = reset
let onDisconnected = reset
var isOnBackground = false
var needUpdateStartBgTime = true
var startBgTime = DateTime
    .now()
    .toUnixTimeStamp()
    .toMilliseconds()
var lastJiffiesSnapshot: ?JiffiesSnapshot = None
var _reportThreadCpuUsageCallback: (info: InteropAllThreadCpuUsageInfo) -> Unit = {_ =>}

@Interop[ArkTS]
public class InteropThreadCpuUsageInfo {
    public let threadId: UInt32
    public let threadName: String
    public let threadState: String
    public let threadJiffiesPercent: Float64
    public let threadJiffies: Int64
    public let totalJiffies: Int64
    public let startBgTime: Int64
    public let exceptionTime: Float64

    public init(threadId: UInt32, threadName: String, threadState: String, threadJiffiesPercent: Float64,
        threadJiffies: Int64, totalJiffies: Int64, st: Int64, et: Float64) {
        this.threadId = threadId
        this.threadName = threadName
        this.threadState = threadState
        this.threadJiffiesPercent = threadJiffiesPercent
        this.threadJiffies = threadJiffies
        this.totalJiffies = totalJiffies
        this.startBgTime = st
        this.exceptionTime = et
    }
}

public class ThreadCpuUsageInfo {
    public var threadId: UInt32
    public var threadName: String
    public var threadState: String
    public var threadJiffiesPercent: Float64
    public var threadJiffies: Int64
    public var totalJiffies: Int64
    public var startBgTime: ?Int64 = None
    public var exceptionTime: ?Float64 = None

    public init(threadId: UInt32, threadName: String, threadState: String, threadJiffiesPercent: Float64,
        threadJiffies: Int64, totalJiffies: Int64) {
        this.threadId = threadId
        this.threadName = threadName
        this.threadState = threadState
        this.threadJiffiesPercent = threadJiffiesPercent
        this.threadJiffies = threadJiffies
        this.totalJiffies = totalJiffies
    }

    func toInteropThreadCpuUsageInfo(): InteropThreadCpuUsageInfo {
        InteropThreadCpuUsageInfo(this.threadId, this.threadName, this.threadState, this.threadJiffiesPercent,
            this.threadJiffies, this.totalJiffies, this.startBgTime ?? -1, this.exceptionTime ?? -1.0)
    }
}

@Interop[ArkTS]
public class InteropAllThreadCpuUsageInfo {
    public let threadCpuUsageInfoList: JSArrayEx<InteropThreadCpuUsageInfo>
    public init(t: JSArrayEx<InteropThreadCpuUsageInfo>) {
        threadCpuUsageInfoList = t
    }
}

public class AllThreadCpuUsageInfo {
    public var threadCpuUsageInfoList = ArrayList<ThreadCpuUsageInfo>()
    func toInteropAllThreadCpuUsageInfo(): InteropAllThreadCpuUsageInfo {
        let t = JSArrayEx<InteropThreadCpuUsageInfo>()
        var i = 0
        for (info in threadCpuUsageInfoList) {
            t.set(i, info.toInteropThreadCpuUsageInfo())
            i++
        }
        InteropAllThreadCpuUsageInfo(t)
    }
}

public class JiffiesSnapshot {
    public var pid: ?Int64 = -1
    public var name: ?String = None
    public var totalJiffies: Int64 = 0
    public var threadEntries = ArrayList<ThreadJiffiesSnapshot>()

    public init() {
    }

    public init(pid: Int64, name: String) {
        this.pid = pid
        this.name = name
    }
}

public class ThreadJiffiesSnapshot {
    public var tid: UInt32
    public var name: ?String = None
    public var state: ?String = None
    public var jiffies: Int64 = 0

    public init(tid: UInt32) {
        this.tid = tid
    }

    public init(tid: UInt32, name: String, state: String, jiffies: Int64) {
        this.tid = tid
        this.name = name
        this.state = state
        this.jiffies = jiffies
    }
}

private func parseThreadInfo(pid: Int64, tid: UInt32, threadJiffiesSnapshot: ThreadJiffiesSnapshot, path: String): Unit {
    if (!exists(path)) {
        return
    }
    let originText = readFile(Path(path))
    let splitText = originText.split(" ")
    threadJiffiesSnapshot.name = splitText[1]
        .replace("(", "")
        .replace(")", "")
    threadJiffiesSnapshot.state = splitText[2]
    let utime = Int64.parse(splitText[13])
    let stime = Int64.parse(splitText[14])
    let cutime = Int64.parse(splitText[15])
    let cstime = Int64.parse(splitText[16])
    threadJiffiesSnapshot.jiffies = utime + stime + cutime + cstime
}

//计算两个JiffiesSnapshot的差值
private func diffThreadJiffiesSnapshot(current: JiffiesSnapshot, last: JiffiesSnapshot): (Int64, ArrayList<ThreadJiffiesSnapshot>) {
    var totalJiffies: Int64 = 0
    let deltaThreadJiffiesList = ArrayList<ThreadJiffiesSnapshot>()
    let currentThreadEntries = current.threadEntries
    let lastThreadEntries = last.threadEntries
    for (currentThread in currentThreadEntries) {
        if (currentThread
            .name
            .isNone()) {
            continue
        }
        var jiffiesConsumed = currentThread.jiffies
        for (lastThread in lastThreadEntries) {
            if (lastThread
                .name
                .isNone()) {
                continue
            }
            if (currentThread.tid == lastThread.tid && currentThread
                .name
                .getOrThrow() == lastThread
                .name
                .getOrThrow()) {
                jiffiesConsumed = currentThread.jiffies - lastThread.jiffies
                break
            }
        }
        if (jiffiesConsumed > 0) {
            let deltaThreadJiffies = ThreadJiffiesSnapshot(currentThread.tid, currentThread
                .name
                .getOrThrow(), currentThread
                .state
                .getOrThrow(), jiffiesConsumed)
            deltaThreadJiffiesList.add(deltaThreadJiffies)
            totalJiffies += jiffiesConsumed
        }
    }
    deltaThreadJiffiesList.sortBy() {
        t1: ThreadJiffiesSnapshot, t2: ThreadJiffiesSnapshot => if (t1.jiffies > t2.jiffies) {
            return Ordering.LT
        } else if (t1.jiffies < t2.jiffies) {
            return Ordering.GT
        } else {
            return Ordering.EQ
        }
    }
    return (totalJiffies, deltaThreadJiffiesList)
}

private func currentJiffiesSnapshot(): JiffiesSnapshot {
    let currentPid = getProcessId()
    let jiffiesSnapshot: JiffiesSnapshot = JiffiesSnapshot(currentPid, getCommand())
    let threads: ArrayList<UInt32> = getAllThreadId()

    for (threadId in threads) {
        let tid = threadId
        let path = "/proc/self/task/" + tid.toString() + "/stat"
        if (!exists(path)) {
            continue
        }
        var threadJiffiesSnapshot: ThreadJiffiesSnapshot = ThreadJiffiesSnapshot(tid)
        parseThreadInfo(currentPid, tid, threadJiffiesSnapshot, path)
        jiffiesSnapshot
            .threadEntries
            .add(threadJiffiesSnapshot)
    }
    return jiffiesSnapshot
}

private func getAllThreadId(): ArrayList<UInt32> {
    let threadIdArray = ArrayList<UInt32>()
    let path = "/proc/self/task/"
    let threadArray = ArrayList<String>()
    if (exists(path) && isDir(path)) {
        Directory.walk(
            path,
            {
                file =>
                    threadArray.add(file.name)
                    true
            }
        )
    }
    for (thread in threadArray) {
        threadIdArray.add(UInt32.parse(thread))
    }
    threadIdArray
}

/**
 * 如果这3min内jiff值大于3*60*100*0.5（在3min持续时间中，当前进程有一半的时间在使用CPU）.则作为一个有效的异常抓取
 */
let SINGLE_INTERVAL_TOTAL_JIFFIES_LIMIT = 9000

private func isHitRule(deltaThreadJiffiesList: ArrayList<ThreadJiffiesSnapshot>, singleIntervalTotalJiffies: Int64): Bool {
    if (singleIntervalTotalJiffies < SINGLE_INTERVAL_TOTAL_JIFFIES_LIMIT) {
        return false
    }
    var maxThreadJiff = 0
    let threadNameJifffMap = HashMap<String, Int64>()
    //同名thread累加 不同名则比较
    for (deltaThreadJiffies in deltaThreadJiffiesList) {
        let threadName = deltaThreadJiffies
            .name
            .getOrThrow()
        let threadJiff = deltaThreadJiffies.jiffies
        if (threadNameJifffMap.contains(threadName)) {
            var threadTotalJiffies = threadNameJifffMap
                .get(threadName)
                .getOrThrow()
            threadTotalJiffies += threadJiff
            threadNameJifffMap.add(threadName, threadTotalJiffies)
        } else {
            threadNameJifffMap.add(threadName, threadJiff)
        }
        let threadNewJiff = threadNameJifffMap
            .get(threadName)
            .getOrThrow()
        if (threadNewJiff > maxThreadJiff) {
            maxThreadJiff = threadNewJiff
        }
    }
    return Float64(maxThreadJiff) > Float64(singleIntervalTotalJiffies) * 0.5
}

private func calculateAndReportCpuUsage(deltaThreadJiffiesList: ArrayList<ThreadJiffiesSnapshot>,
    singleIntervalTotalJiffies: Int64): Unit {
    let allThreadCpuUsageInfo = AllThreadCpuUsageInfo()
    let reportThreadList = allThreadCpuUsageInfo.threadCpuUsageInfoList
    for (deltaThreadJiffies in deltaThreadJiffiesList) {
        //todo trace
        let threadJiffiesPercent = Float64(deltaThreadJiffies.jiffies) / Float64(singleIntervalTotalJiffies)
        let threadCpuUsageInfo = ThreadCpuUsageInfo(deltaThreadJiffies.tid, deltaThreadJiffies
            .name
            .getOrThrow(), deltaThreadJiffies
            .state
            .getOrThrow(), threadJiffiesPercent, deltaThreadJiffies.jiffies, singleIntervalTotalJiffies)
        if (isOnBackground) {
            threadCpuUsageInfo.startBgTime = startBgTime
            threadCpuUsageInfo.exceptionTime = Float64(DateTime
                .now()
                .toUnixTimeStamp()
                .toMilliseconds() - startBgTime) / 1000.0
        }
        reportThreadList.add(threadCpuUsageInfo)
    }
    _reportThreadCpuUsageCallback(allThreadCpuUsageInfo.toInteropAllThreadCpuUsageInfo())
}

private func checkRunningProcessInfo(status: Bool) {
    isOnBackground = status
    if (isOnBackground && needUpdateStartBgTime) {
        startBgTime = DateTime
            .now()
            .toUnixTimeStamp()
            .toMilliseconds()
        needUpdateStartBgTime = false
    }
}

private func cpuErrorPercentReport(): Unit {
    _getRunningProcessInfo(checkRunningProcessInfo)

    let currentJiffiesSnapshot = currentJiffiesSnapshot()
    if (lastJiffiesSnapshot.isSome()) {
        let deltaThreadJiffiesSnapshot = diffThreadJiffiesSnapshot(currentJiffiesSnapshot,
            lastJiffiesSnapshot.getOrThrow())
        let singleIntervalTotalJiffies: Int64 = deltaThreadJiffiesSnapshot[0]
        let deltaThreadJiffiesList = deltaThreadJiffiesSnapshot[1]
        if (isHitRule(deltaThreadJiffiesList, singleIntervalTotalJiffies)) {
            calculateAndReportCpuUsage(deltaThreadJiffiesList, singleIntervalTotalJiffies)
        }
    }
    lastJiffiesSnapshot = currentJiffiesSnapshot
}

let handleCpuReport: () -> Unit = {
    => cpuErrorPercentReport()
}

public func initBatteryHandler(
    subscribe: (onBatteryChanged: () -> Unit, onConnected: () -> Unit, onDisconnected: () -> Unit) -> Unit,
    getUptime: () -> Int64,
    batteryInterface: BatteryInfoInterface,
    getBrightness: () -> Int32,
    onApplicationStateChange: (onApplicationForefround: () -> Unit, onApplicationBackground: () -> Unit) -> Unit,
    onAbilityForeground: (cb: () -> Unit) -> Unit,
    onNavDestinationSwitch: (cb: (targetPageName: String) -> Unit) -> Unit,
    getRunningProcessInfo: ((Bool) -> Unit) -> Unit,
    repeatHandleCpuUsage: (handleCpuUsage: () -> Unit) -> Unit,
    reportBatteryInfo: (info: InteropBatteryUsageInfo) -> Unit,
    reportThreadCpuUsageInfo: (info: InteropAllThreadCpuUsageInfo) -> Unit,
    limit!: Int32 = 1
): Unit {
    _getUptime = getUptime
    _batterInterface = batteryInterface
    _getBrightness = getBrightness
    _getRunningProcessInfo = getRunningProcessInfo
    _reportBatteryCallback = reportBatteryInfo
    _reportThreadCpuUsageCallback = reportThreadCpuUsageInfo

    batteryLimit = limit
    lastTime = _getUptime()
    lastScreenOnTimeStamp = _getUptime()

    lastJiffiesSnapshot = currentJiffiesSnapshot()
    repeatHandleCpuUsage(handleCpuReport)
    onApplicationStateChange(
        {
            =>
                let currentTime = _getUptime()
                lastScreenOnTimeStamp = currentTime
                frontStatus = true
        },
        {
            =>
                let currentTime = _getUptime()
                let deltaTime = (currentTime - lastScreenOnTimeStamp) / 1000
                screenOnTotalSecond += deltaTime
                frontStatus = false
        }
    )
    onNavDestinationSwitch({
        targetPagaName: String => if (!targetPagaName.isEmpty()) {
            currentPageName = targetPagaName
        }
    })
    subscribe(onBatteryChanged, onConnected, onDisconnected)
}
