/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */
package ohos_app_cangjie_hm_metricx_cj.cpu

import ohos_app_cangjie_hm_metricx_cj.util.*
import tpc.AbilityKit.UIAbility
import tpc.AbilityKit.UIAbilityContext
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

    func computeAvg(currrentCpuValue: Float64): Unit {
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

    protected open func reset(): Unit {
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

    protected override func reset() {
        super.reset()
        this.pageNameValue = ""
    }

    public func toString(): String {
        let jsonObj = JsonObject()
        jsonObj.put("avgCpu", JsonString(avgCpu.toString()))
        jsonObj.put("maxCpu", JsonString(maxCpu.toString()))
        jsonObj.put("sampleCount", JsonString(sampleCount.toString()))
        jsonObj.put("pageName", JsonString(pageNameValue.toString()))
        jsonObj.toString()
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

    public func toString(): String {
        let jsonObj = JsonObject()
        jsonObj.put("avgCpu", JsonString(avgCpu.toString()))
        jsonObj.put("maxCpu", JsonString(maxCpu.toString()))
        jsonObj.put("sampleCount", JsonString(sampleCount.toString()))
        jsonObj.put("pid", JsonString(pidValue.toString()))
        jsonObj.toString()
    }
}

var pageCpuInfo = PageCpuInfo(defaultPageName)
var processCpuInfo = ProcessCpuInfo()
var uiContext: Option<UIAbilityContext> = None
var currentPageName: String = defaultPageName
let doCpuSample: (param: Array<String>) -> Unit = {
    param: Array<String> =>
    let cpuUsage = getCpuUsage()
    pageCpuInfo.computeAvg(cpuUsage)
    processCpuInfo.computeAvg(cpuUsage)
}
var reportPageCpu: (infp: PageCpuInfo) -> Unit = {event: PageCpuInfo =>}
var reportProcessCpu: (info: ProcessCpuInfo) -> Unit = {event: ProcessCpuInfo =>}
let pageSwitchCallback: PageSwitchCallBack = PageSwitchCallBack(
    {
        info: NavDestinationSwitchInfo =>
        currentPageName = getTargetPageName(info, defaultName: currentPageName)
        doCpuSample()
        reportPageCpu(pageCpuInfo)
        pageCpuInfo.reset()
        pageCpuInfo.pageName = currentPageName
    }
)
let handleCpuReport: (param: Array<String>) -> Unit = {
    param: Array<String> => reportProcessCpu(processCpuInfo)
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
    context: UIAbilityContext,
    reportPageCpuInfo: (info: PageCpuInfo) -> Unit,
    reportProcessCpuInfo: (info: ProcessCpuInfo) -> Unit
): Unit {
    uiContext = context
    reportPageCpu = reportPageCpuInfo
    reportProcessCpu = reportProcessCpuInfo
    setTimeout(handleCpu, 2 * 1000, Array<String>())
    on(navDestinationSwitch, uiContext.getOrThrow(), pageSwitchCallback)
}

public func destroyCpuHandler(): Unit {
    off(navDestinationSwitch, uiContext.getOrThrow(), pageSwitchCallback)
    // todo clearInterval
}
