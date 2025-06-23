/**
 * Created on 2025/5/17
 */
package ohos_app_cangjie_hm_metricx_cj.cpu

import ohos_app_cangjie_hm_metricx_cj.*
import tpc.AbilityKit.UIAbility
import tpc.BasicServicesKit.*
import tpc.UIKit.Observer.*
import tpc.PerformanceAnalysisKit.hidebug.*
import tpc.UIKit.component_interop.ResourceStr
import tpc.UIKit.global.*
import std.convert.*
import stdx.encoding.json.*
import std.posix.*
import std.collection.*

public open class CpuInfo {
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
        this.avgCpuValue = this.avgCpuValue + (currrentCpuValue - this.avgCpuValue) / Float64(sampleCountValue + 1)
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

    public func toString(): String {
        let jsonObj = JsonObject()
        jsonObj.put("avgCpu", JsonString(avgCpuValue.toString()))
        jsonObj.put("maxCpu", JsonString(maxCpuValue.toString()))
        jsonObj.put("sampleCount", JsonString(sampleCountValue.toString()))

        jsonObj.toString()
    }

    public open func reset(): Unit {
        this.avgCpuValue = 0.0
        this.maxCpuValue = 0.0
        this.sampleCount = 0
    }
}

public class PageCpuInfo <: CpuInfo {
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

public class ProcessCpuInfo <: CpuInfo {
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

var pageCpuInfo = PageCpuInfo("mainPage")
var processCpuInfo = ProcessCpuInfo()
var uiAbility: UIAbility = UIAbility()
var currentPageName: String = "mainPage"
let doCpuSample: (param: Array<String>) -> Unit = {
    param: Array<String> =>
    let cpuUsage = getCpuUsage()
    pageCpuInfo.computeAvg(cpuUsage)
    processCpuInfo.computeAvg(cpuUsage)
}
var reportCpu: (infp: CpuInfo) -> Unit = {event: CpuInfo =>}
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
            case _ => ()

        }
        doCpuSample()
        reportCpu(pageCpuInfo)
        pageCpuInfo.reset()
        pageCpuInfo.pageName = currentPageName
    }
)
let handleCpuReport: (param: Array<String>) -> Unit = {
    param: Array<String> => reportCpu(processCpuInfo)
}

private func handleCpu(param: Array<String>): Unit {
    setInterval(doCpuSample, 2000, Array<String>())
    setInterval(handleCpuReport, 30 * 60 * 1000, Array<String>())
}

public func getPageCpuInfo(): PageCpuInfo {
    pageCpuInfo
}

public func getProcessCpuInfo(): ProcessCpuInfo {
    processCpuInfo
}

public func initCpuHandler(
    ability: UIAbility,
    reporCpuInfo: (info: CpuInfo) -> Unit
): Unit {
    uiAbility = ability
    reportCpu = reporCpuInfo
    setTimeout(handleCpu, 2 * 1000, Array<String>())
    on(navDestinationSwitch, uiAbility.context, pageSwitchCallback)
}

public func destroyCpuHandler(): Unit {
    off(navDestinationSwitch, uiAbility.context, pageSwitchCallback)
    // todo clearInterval
}
