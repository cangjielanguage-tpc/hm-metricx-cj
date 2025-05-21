/**
 * Created on 2025/5/17
 */
package ohos_app_cangjie_hm_metricx_cj.cpu

import tpc.AbilityKit.UIAbility
import tpc.BasicServicesKit.*
import tpc.UIKit.Observer.*
import tpc.PerformanceAnalysisKit.hidebug.*
import tpc.UIKit.global.*
import ohos.base.AppResource
import tpc.UIKit.component_interop.ResourceStr
import std.convert.*
import encoding.json.*
import std.os.posix.*
import std.collection.*

public open class CpuEventInfo {
    private var avgCpuValue: Float64 = 0.0
    private var maxCpuValue: Float64 = 0.0
    private var sampleCountValue: Int64 = 0

    mut prop avgCpu: Float64 {
        get() {
            avgCpuValue
        }
        set(value) {
            avgCpuValue = value
        }
    }
    mut prop maxCpu: Float64 {
        get() {
            maxCpuValue
        }
        set(value) {
            maxCpuValue = value
        }
    }
    mut prop sampleCount: Int64 {
        get() {
            sampleCountValue
        }
        set(value) {
            sampleCountValue = value
        }
    }

    public init() {
        avgCpuValue = 0.0
        maxCpuValue = 0.0
        sampleCountValue = 0
    }

    public func computeAvg(currrentCpuValue: Float64): Unit {
        this.avgCpuValue = (this.avgCpuValue * Float64(sampleCountValue) + currrentCpuValue) / Float64(sampleCountValue +
            1)
        if (maxCpuValue < currrentCpuValue) {
            maxCpuValue = currrentCpuValue
        }
        sampleCountValue++
    }

    public func getAvgCpu(): Float64 {
        this.avgCpuValue
    }
    public func getMaxCpu(): Float64 {
        this.maxCpuValue
    }

    public open func toString(): String {
        let jsonObj = JsonObject()
        jsonObj.put("avgCpu", JsonString(avgCpuValue.toString()))
        jsonObj.put("maxCpu", JsonString(maxCpuValue.toString()))
        jsonObj.put("sampleCount", JsonString(sampleCountValue.toString()))

        jsonObj.toString()
    }

    static func fromJson(jsonObject: JsonObject): CpuEventInfo {
        let cpuEventInfo = CpuEventInfo()
        if (jsonObject.get("avgCpu").isSome()) {
            cpuEventInfo.avgCpuValue = Float64.parse(
                jsonObject.get("avgCpu").getOrDefault({=> JsonString("0.0")}).toString())
        }
        if (jsonObject.get("maxCpu").isSome()) {
            cpuEventInfo.maxCpuValue = Float64.parse(
                jsonObject.get("maxCpu").getOrDefault({=> JsonString("0.0")}).toString())
        }
        if (jsonObject.get("sampleCount").isSome()) {
            cpuEventInfo.sampleCountValue = Int64.parse(
                jsonObject.get("sampleCount").getOrDefault({=> JsonString("0")}).toString())
        }
        cpuEventInfo
    }

    public open func reset(): Unit {
        this.avgCpuValue = 0.0
        this.maxCpuValue = 0.0
        this.sampleCount = 0
    }
}

public class PageCpuEventInfo <: CpuEventInfo {
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

    public override func reset() {
        super.reset()
        this.pageNameValue = ""
    }
}

public class ProcessCpuEventInfo <: CpuEventInfo {
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

public class PageSwitchCallBack <: Callback1Argument<NavDestinationSwitchInfo> {
    let elementInfoCallback: (NavDestinationSwitchInfo) -> Unit
    public init(elementInfoCallback: (NavDestinationSwitchInfo) -> Unit) {
        this.elementInfoCallback = elementInfoCallback
    }
    public func invoke(res: NavDestinationSwitchInfo): Unit {
        this.elementInfoCallback(res)
    }
}

var pageCpuInfo = PageCpuEventInfo()
var processCpuInfo = ProcessCpuEventInfo()
var uiAbility: UIAbility = UIAbility()
let doCpuSample: (param: Array<String>) -> Unit = {
    param: Array<String> =>
    let cpuUsage = getCpuUsage()
    pageCpuInfo.computeAvg(cpuUsage)
    processCpuInfo.computeAvg(cpuUsage)
}
var reportPageCallback: (pageCpuInfo: PageCpuEventInfo) -> Unit = {info: PageCpuEventInfo =>}
var reportProcessCallback: (processCpuInfo: ProcessCpuEventInfo) -> Unit = {info: ProcessCpuEventInfo =>}
let reportCpuCallback: (param: Array<String>) -> Unit = {
    param: Array<String> => reportProcessCallback(processCpuInfo)
}
var currentPageName: String = ""
let pageSwitchCallback: PageSwitchCallBack = PageSwitchCallBack(
    {
        info: NavDestinationSwitchInfo =>
        match (info.to) {
            case to: NavBar => currentPageName = "navRoot"
            case to: NavDestinationInfo =>
                let resource: ResourceStr = to.name
                match (resource) {
                    case name: String => currentPageName = name
                    case name: AppResource => currentPageName = name.moduleName
                }
        }
        doCpuSample()
        reportPageCallback(pageCpuInfo)
        pageCpuInfo.reset()
        pageCpuInfo.pageName = currentPageName
    }
)

public func handleCpu(array: Array<String>): Unit {
    setInterval(doCpuSample, 2000, Array<String>())
    setInterval(reportCpuCallback, 30 * 60 * 1000, Array<String>())
}

public func initCpuHandler(ability: UIAbility, reportPage: (info: PageCpuEventInfo) -> Unit,
    reportProcess: (info: ProcessCpuEventInfo) -> Unit): Unit {
    uiAbility = ability
    reportPageCallback = reportPage
    reportProcessCallback = reportProcess
    setTimeout(handleCpu, 2000, Array<String>())
    on(navDestinationSwitch, uiAbility.context, pageSwitchCallback)
}

public func destroyCpuHandler(): Unit {
    off(navDestinationSwitch, uiAbility.context, pageSwitchCallback)
    // todo clearInterval

}
