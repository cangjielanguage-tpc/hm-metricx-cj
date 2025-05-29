/**
 * Created on 2025/5/19
 */
package ohos_app_cangjie_hm_metricx_cj.memory

import ohos_app_cangjie_hm_metricx_cj.*
import tpc.AbilityKit.UIAbility
import tpc.BasicServicesKit.*
import tpc.UIKit.Observer.*
import tpc.PerformanceAnalysisKit.hidebug.*
import tpc.UIKit.global.*
import tpc.UIKit.component_interop.ResourceStr
import ohos.base.AppResource
import std.convert.*
import encoding.json.*
import std.os.posix.*
import std.fs.*
import std.collection.*
import ohos.hilog.Hilog

public open class MemoryInfo {
    private var avgMemoryValue: Int64 = 0
    private var maxMemoryValue: Int64 = 0
    private var sampleCountValue: Int64 = 0

    mut prop avgMemory: Int64 {
        get() {
            avgMemoryValue
        }
        set(value) {
            avgMemoryValue = value
        }
    }
    mut prop maxMemory: Int64 {
        get() {
            maxMemoryValue
        }
        set(value) {
            maxMemoryValue = value
        }
    }

    public init() {
        avgMemoryValue = 0
        maxMemoryValue = 0
        sampleCountValue = 0
    }

    public func computeAvg(currrentMemoryValue: Int64): Unit {
        this.avgMemoryValue = this.avgMemoryValue + (currrentMemoryValue - this.avgMemoryValue) / (sampleCountValue + 1)
        if (maxMemoryValue < currrentMemoryValue) {
            maxMemoryValue = currrentMemoryValue
        }
        sampleCountValue++
    }

    public func getAvgMemory(): Int64 {
        this.avgMemoryValue
    }
    public func getMaxMemory(): Int64 {
        this.maxMemoryValue
    }

    public open func toString(): String {
        let jsonObj = JsonObject()
        jsonObj.put("avgMemory", JsonString(avgMemoryValue.toString()))
        jsonObj.put("maxMemory", JsonString(maxMemoryValue.toString()))
        jsonObj.put("sampleCount", JsonString(sampleCountValue.toString()))

        jsonObj.toString()
    }

    public open func reset(): Unit {
        this.avgMemoryValue = 0
        this.maxMemoryValue = 0
        this.sampleCountValue = 0
    }
}

public class PageMemoryInfo <: MemoryInfo {
    private var pageNameValue: String = ""

    mut prop pageName: String {
        get() {
            pageNameValue
        }
        set(value) {
            pageNameValue = value
        }
    }

    public init() {
    }

    public init(pageName: String) {
        pageNameValue = pageName
    }

    public func getPageName(): String {
        pageNameValue
    }
    public override func reset(): Unit {
        super.reset()
        this.pageNameValue = ""
    }
}

public class ProcessMemoryInfo <: MemoryInfo {
    private var pidValue: Int32 = 0

    mut prop pid: Int32 {
        get() {
            this.pidValue
        }
        set(value) {
            this.pidValue = value
        }
    }

    public init() {
        this.pidValue = getpid()
    }

    public init(pidValue: Int32) {
        this.pidValue = pidValue
    }

    public func getProcessName(): Int32 {
        this.pidValue
    }
}

var MEMOMRY_THRESHOLD: Int64 = 1024 * 100
var thresholdReported: Bool = false
var pageMemoryInfo = PageMemoryInfo("mainPage")
var processMemoryInfo = ProcessMemoryInfo()
var uiAbility: UIAbility = UIAbility()
var reportMemory: (memoryInfo: MemoryInfo) -> Unit = {info: MemoryInfo =>}
let doMemorySample: (param: Array<String>) -> Unit = {
    param: Array<String> =>
    let memoryUsage = getPss().toInt64()
    if (!thresholdReported) {
        if (memoryUsage >= MEMOMRY_THRESHOLD) {
            processMemoryInfo.maxMemory = memoryUsage
            reportMemory(processMemoryInfo)
            thresholdReported = true
        }
    }
    pageMemoryInfo.computeAvg(memoryUsage)
    processMemoryInfo.computeAvg(memoryUsage)
}
let handleMemoryReport: (param: Array<String>) -> Unit = {
    param: Array<String> => reportMemory(processMemoryInfo)
}
var currentPageName: String = "mainPage"
let pageSwitchCallback: PageSwitchCallBack = PageSwitchCallBack(
    {
        info: NavDestinationSwitchInfo =>
        match (info.to) {
            case to: NavBar => currentPageName = "navRoot"
            case to: NavDestinationInfo => try {
                currentPageName = (((to as NavDestinationInfo).getOrThrow()).name as String).getOrThrow()
            } catch (e: Exception) {
                AppLog.warn(e.toString())
            }
        }
        doMemorySample()
        pageMemoryInfo.reset()
        pageMemoryInfo.pageName = currentPageName
    }
)

private func handleMemory(array: Array<String>): Unit {
    setInterval(doMemorySample, 2000, Array<String>())
    setInterval(handleMemoryReport, 30 * 60 * 1000, Array<String>())
}

public func getPageMemoryInfo(): PageMemoryInfo {
    pageMemoryInfo
}

public func getProcessMemoryInfo(): ProcessMemoryInfo {
    processMemoryInfo
}

private func getMaxMemory(): Int64 {
    let filePath: String = uiAbility.context.cacheDir + "/memory.txt"
    var maxMemory: Int64 = 0
    try {
        if (File.exists(filePath)) {
            let txtString = String.fromUtf8(File.readFrom(filePath))
            if (!txtString.isEmpty()) {
                maxMemory = Int64.parse(txtString)
            }
        }
    } catch (e: Exception) {
        AppLog.warn(e.toString())
    }
    maxMemory
}

private func setMaxMemory(memoryValue: Int64): Unit {
    let filePath: String = uiAbility.context.cacheDir + "/memory.txt"
    try {
        let memoryStr = memoryValue.toString()
        let fileOption: OpenOption = OpenOption.CreateOrTruncate(false)
        File.writeTo(filePath, memoryStr.toArray(), openOption: fileOption)
    } catch (e: Exception) {
        AppLog.warn(e.toString())
    }
}

public func initMemoryHandler(
    ability: UIAbility,
    reportMemoryInfo: (info: MemoryInfo) -> Unit,
    memoryThreshold!: Int64 = 100 * 1024
): Unit {
    uiAbility = ability
    reportMemory = reportMemoryInfo
    MEMOMRY_THRESHOLD = memoryThreshold
    let maxMemory: Int64 = getMaxMemory()
    processMemoryInfo.reset()
    processMemoryInfo.maxMemory = maxMemory
    reportMemory(processMemoryInfo)
    processMemoryInfo.reset()
    setTimeout(handleMemory, 2 * 1000, Array<String>())
    on(navDestinationSwitch, uiAbility.context, pageSwitchCallback)
}

public func destroyMemoryHandler(): Unit {
    setMaxMemory(processMemoryInfo.maxMemory)
    off(navDestinationSwitch, uiAbility.context, pageSwitchCallback)
    // todo clearInterval
}
