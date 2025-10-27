/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */
package ohos_app_cangjie_hm_metricx_cj.memory

import ohos_app_cangjie_hm_metricx_cj.util.*
import tpc.AbilityKit.UIAbilityContext
import tpc.BasicServicesKit.*
import tpc.UIKit.Observer.*
import tpc.PerformanceAnalysisKit.hidebug.*
import tpc.UIKit.global.*
import std.convert.*
import stdx.encoding.json.*
import std.posix.*
import tpc.ArkData.preferences
import std.unicode.UnicodeStringExtension

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
    mut prop sampleCount: Int64 {
        get() {
            sampleCountValue
        }
        set(value) {
            sampleCountValue = value
        }
    }

    public init() {
        avgMemoryValue = 0
        maxMemoryValue = 0
        sampleCountValue = 0
    }

    func computeAvg(currrentMemoryValue: Int64): Unit {
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

    protected open func reset(): Unit {
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

    protected override func reset(): Unit {
        super.reset()
        this.pageNameValue = ""
    }

    public func toString(): String {
        let jsonObj = JsonObject()
        jsonObj.put("avgMemory", JsonString(avgMemory.toString()))
        jsonObj.put("maxMemory", JsonString(maxMemory.toString()))
        jsonObj.put("sampleCount", JsonString(sampleCount.toString()))
        jsonObj.put("pageName", JsonString(pageNameValue.toString()))
        jsonObj.toString()
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

    protected override func reset(): Unit {
        super.reset()
        this.pidValue = 0
    }

    public func toString(): String {
        let jsonObj = JsonObject()
        jsonObj.put("avgMemory", JsonString(avgMemory.toString()))
        jsonObj.put("maxMemory", JsonString(maxMemory.toString()))
        jsonObj.put("sampleCount", JsonString(sampleCount.toString()))
        jsonObj.put("pid", JsonString(pidValue.toString()))
        jsonObj.toString()
    }

    static func fromJson(jsonObject: JsonObject): ProcessMemoryInfo {
        let processMemoryInfo = ProcessMemoryInfo()
        if (let Some(v) <-  jsonObject.get("avgMemory")) {
            processMemoryInfo.avgMemory = Int64.parse(JsonValueToString(v))
        }
        if (let Some(v) <-  jsonObject.get("maxMemory")) {
            processMemoryInfo.maxMemory = Int64.parse(JsonValueToString(v))
        }
        if (let Some(v) <-  jsonObject.get("sampleCount")) {
            processMemoryInfo.sampleCount = Int64.parse(JsonValueToString(v))
        }
        if (let Some(v) <-  jsonObject.get("pid")) {
            processMemoryInfo.pid = Int32.parse(JsonValueToString(v))
        }
        processMemoryInfo
    }
}

let preferenceOptionName: String = "hm-metric-cj-memory"
var MEMOMRY_THRESHOLD: Int64 = 1024 * 100
var thresholdReported: Bool = false
var pageMemoryInfo = PageMemoryInfo(defaultPageName)
var processMemoryInfo = ProcessMemoryInfo()
var uiContext: Option<UIAbilityContext> = None
var reportPageMemory: (memoryInfo: PageMemoryInfo) -> Unit = {info: PageMemoryInfo =>}
var reportProcessMemory: (memoryInfo: ProcessMemoryInfo) -> Unit = {info: ProcessMemoryInfo =>}
let doMemorySample: (param: Array<String>) -> Unit = {
    param: Array<String> =>
    let memoryUsage = getPss().toInt64()
    if (!thresholdReported) {
        if (memoryUsage >= MEMOMRY_THRESHOLD) {
            processMemoryInfo.maxMemory = memoryUsage
            reportProcessMemory(processMemoryInfo)
            thresholdReported = true
        }
    }
    pageMemoryInfo.computeAvg(memoryUsage)
    processMemoryInfo.computeAvg(memoryUsage)
}
let handleProcessMemoryReport: (param: Array<String>) -> Unit = {
    param: Array<String> => reportProcessMemory(processMemoryInfo)
}
var currentPageName: String = defaultPageName
let pageSwitchCallback: PageSwitchCallBack = PageSwitchCallBack(
    {
        info: NavDestinationSwitchInfo =>
        currentPageName = getTargetPageName(info, defaultName: currentPageName)
        doMemorySample()
        reportPageMemory(pageMemoryInfo)
        pageMemoryInfo.reset()
        pageMemoryInfo.pageName = currentPageName
    }
)

let saveProcessMemory: (param: Array<String>) -> Unit = {
    param: Array<String> =>
    try {
        let options = preferences.Options(preferenceOptionName)
        let dataPreferences = preferences.getPreferences(uiContext.getOrThrow(), options)
        dataPreferences.put("processMemory", preferences.ValueType.STRING(processMemoryInfo.toString()))
        dataPreferences.flush({err, data => })
    } catch (e:Exception) {
        AppLog.warn("hm-metricx-cj error: " + e.toString())
    }
}

private func handleMemory(array: Array<String>): Unit {
    setInterval(doMemorySample, 2000, Array<String>())
    setInterval(handleProcessMemoryReport, 30 * 60 * 1000, Array<String>())
    setInterval(saveProcessMemory, 60 * 1000, Array<String>())
}

public func getPageMemoryInfo(): PageMemoryInfo {
    pageMemoryInfo
}

public func getProcessMemoryInfo(): ProcessMemoryInfo {
    processMemoryInfo
}

private func getStoragedProcessMemory(): Option<ProcessMemoryInfo> {
    var processMemoryStr: String = ""
    try {
        let options = preferences.Options(preferenceOptionName)
        let dataPreferences = preferences.getPreferences(uiContext.getOrThrow(), options)
        let val = dataPreferences.get("processMemory", preferences.ValueType.STRING(""))
        match (val) {
            case STRING(v) => processMemoryStr = v
            case _ => ()
        }
        if (processMemoryStr.isBlank()) {
            return Option.None
        }
        let obj = JsonValue.fromStr(processMemoryStr).asObject()
        return ProcessMemoryInfo.fromJson(obj)
    } catch (e: Exception) {
        AppLog.warn("hm-metricx-cj error: " + e.toString())
    }
    Option.None
}

public func initMemoryHandler(
    context: UIAbilityContext,
    reportPageMemoryInfo: (info: PageMemoryInfo) -> Unit,
    reportProcessMemoryInfo: (info: ProcessMemoryInfo) -> Unit,
    memoryThreshold!: Int64 = 100 * 1024
): Unit {
    uiContext = context
    reportPageMemory = reportPageMemoryInfo
    reportProcessMemory = reportProcessMemoryInfo
    MEMOMRY_THRESHOLD = memoryThreshold
    let lastProcessMemory = getStoragedProcessMemory()
    if (let Some(v) <- lastProcessMemory) {
        reportProcessMemoryInfo(v)
    }
    setTimeout(handleMemory, 2 * 1000, Array<String>())
    on(navDestinationSwitch, uiContext.getOrThrow(), pageSwitchCallback)
}

public func destroyMemoryHandler(): Unit {
    off(navDestinationSwitch, uiContext.getOrThrow(), pageSwitchCallback)
    // todo clearInterval
}
