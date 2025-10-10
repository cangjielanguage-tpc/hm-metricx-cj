/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */
package ohos_app_cangjie_hm_metricx_cj.memory

import ohos_app_cangjie_hm_metricx_cj.util.*
import tpc.AbilityKit.UIAbility
import tpc.AbilityKit.UIAbilityContext
import tpc.BasicServicesKit.*
import tpc.UIKit.Observer.*
import tpc.PerformanceAnalysisKit.hidebug.*
import tpc.UIKit.global.*
import tpc.UIKit.component_interop.ResourceStr
import std.convert.*
import stdx.encoding.json.*
import std.posix.*
import std.fs.*
import std.collection.*
import ohos.hilog.Hilog
import tpc.ArkData.preferences

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
var pageMemoryInfo = PageMemoryInfo(defaultPageName)
var processMemoryInfo = ProcessMemoryInfo()
var uiContext: Option<UIAbilityContext> = None
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
var currentPageName: String = defaultPageName
let pageSwitchCallback: PageSwitchCallBack = PageSwitchCallBack(
    {
        info: NavDestinationSwitchInfo =>
        currentPageName = getTargetPageName(info, defaultName: currentPageName)
        doMemorySample()
        reportMemory(pageMemoryInfo)
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

private func setMaxMemory(memoryValue: Int64): Unit {
    try {
        let options = preferences.Options("Memory")
        let dataPreferences = preferences.getPreferences(uiContext.getOrThrow(), options)
        dataPreferences.put("max", preferences.ValueType.NUMBER(Int32(memoryValue)))
        dataPreferences.flush({err, data =>})
    } catch (e: Exception) {
        AppLog.warn(e.toString())
    }
}

private func getMaxMemory(): Int64 {
    var maxMemory: Int64 = -1
    try {
        let options = preferences.Options("Memory")
        let dataPreferences = preferences.getPreferences(uiContext.getOrThrow(), options)
        let status: Bool = dataPreferences.has("max")
        if (status) {
            let val = dataPreferences.get("max", preferences.ValueType.NUMBER(0))
            match (val) {
                case NUMBER(v) => maxMemory = Int64(v)
                case _ => ()
            }
        }
    } catch (e: Exception) {
        AppLog.warn(e.toString())
    }
    maxMemory
}

public func initMemoryHandler(
    context: UIAbilityContext,
    reportMemoryInfo: (info: MemoryInfo) -> Unit,
    memoryThreshold!: Int64 = 100 * 1024
): Unit {
    uiContext = context
    reportMemory = reportMemoryInfo
    MEMOMRY_THRESHOLD = memoryThreshold
    let maxMemory: Int64 = getMaxMemory()
    if (maxMemory != -1) {
        processMemoryInfo.reset()
        processMemoryInfo.maxMemory = maxMemory
        reportMemory(processMemoryInfo)
        processMemoryInfo.reset()
    }
    setTimeout(handleMemory, 2 * 1000, Array<String>())
    on(navDestinationSwitch, uiContext.getOrThrow(), pageSwitchCallback)
}

public func destroyMemoryHandler(): Unit {
    setMaxMemory(processMemoryInfo.maxMemory)
    off(navDestinationSwitch, uiContext.getOrThrow(), pageSwitchCallback)
    // todo clearInterval
}
