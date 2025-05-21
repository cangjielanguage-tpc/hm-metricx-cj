/**
 * Created on 2025/5/19
 */
package ohos_app_cangjie_hm_metricx_cj.memory

import tpc.AbilityKit.UIAbility
import tpc.BasicServicesKit.*
import tpc.UIKit.Observer.*
import tpc.PerformanceAnalysisKit.hidebug.*
import tpc.UIKit.global.*
import std.convert.*
import encoding.json.*
import std.os.posix.*
import std.collection.*

public open class MemoryEventInfo {
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
        this.avgMemoryValue = (this.avgMemoryValue * sampleCountValue + currrentMemoryValue) / (sampleCountValue + 1)
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

    static func fromJson(jsonObject: JsonObject): MemoryEventInfo {
        let memoryEventInfo = MemoryEventInfo()
        if (jsonObject.get("avgMemory").isSome()) {
            memoryEventInfo.avgMemoryValue = Int64.parse(
                jsonObject.get("avgCpu").getOrDefault({=> JsonString("0")}).toString())
        }
        if (jsonObject.get("maxMemory").isSome()) {
            memoryEventInfo.maxMemoryValue = Int64.parse(
                jsonObject.get("maxCpu").getOrDefault({=> JsonString("0")}).toString())
        }
        if (jsonObject.get("sampleCount").isSome()) {
            memoryEventInfo.sampleCountValue = Int64.parse(
                jsonObject.get("sampleCount").getOrDefault({=> JsonString("0")}).toString())
        }
        memoryEventInfo
    }

    public open func reset(): Unit {
        this.avgMemoryValue = 0
        this.maxMemoryValue = 0
        this.sampleCountValue = 0
    }
}

public class PageMemoryEventInfo <: MemoryEventInfo {
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

public class ProcessMemoryEventInfo <: MemoryEventInfo {
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

var pageMemoryInfo = PageMemoryEventInfo()
var processMemoryInfo = ProcessMemoryEventInfo()
var uiAbility: UIAbility = UIAbility()
let doMemorySample: (param: Array<String>) -> Unit = {
    param: Array<String> =>
    let memoryUsage = getPss().toInt64()
    pageMemoryInfo.computeAvg(memoryUsage)
    processMemoryInfo.computeAvg(memoryUsage)
}
var reportPageCallback: (pageMemoryInfo: PageMemoryEventInfo) -> Unit = {info: PageMemoryEventInfo =>}
var reportProcessCallback: (processMemoryInfo: ProcessMemoryEventInfo) -> Unit = {info: ProcessMemoryEventInfo =>}
let reportMemoryCallback: (param: Array<String>) -> Unit = {
    param: Array<String> => reportProcessCallback(processMemoryInfo)
}
var currentPageName: String = ""

public class PageSwitchCallBack <: Callback1Argument<NavDestinationSwitchInfo> {
    let elementInfoCallback: (NavDestinationSwitchInfo) -> Unit
    public init(elementInfoCallback: (NavDestinationSwitchInfo) -> Unit) {
        this.elementInfoCallback = elementInfoCallback
    }
    public func invoke(res: NavDestinationSwitchInfo): Unit {
        this.elementInfoCallback(res)
    }
}

let pageSwitchCallback: PageSwitchCallBack = PageSwitchCallBack(
    {
        info: NavDestinationSwitchInfo =>
        match (info.to) {
            case to: NavBar => currentPageName = "navRoot"
            case to: NavDestinationInfo => currentPageName = "test"
        }
        doMemorySample()
        reportPageCallback(pageMemoryInfo)
        pageMemoryInfo.reset()
        pageMemoryInfo.pageName = currentPageName
    }
)

public func handleMemory(array: Array<String>): Unit {
    setInterval(doMemorySample, 2000, Array<String>())
    setInterval(reportMemoryCallback, 30 * 60 * 1000, Array<String>())
}

public func initMemoryHandler(ability: UIAbility, delayTime: Int64, sampleTime: Int64, reportTime: Int64): Unit {
    uiAbility = ability
    setTimeout(handleMemory, delayTime, Array<String>())
    on(navDestinationSwitch, uiAbility.context, pageSwitchCallback)
}

public func destroyMemoryHandler(): Unit {
    off(navDestinationSwitch, uiAbility.context, pageSwitchCallback)
}
