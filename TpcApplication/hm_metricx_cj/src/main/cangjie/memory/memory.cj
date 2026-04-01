/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 * 支持仓颉 (CJ) 和 ArkTS (JS) 堆内存监控
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
import std.runtime.*

public open class MemoryInfo {
    private var avgMemoryValue: Int64 = 0
    private var maxMemoryValue: Int64 = 0
    private var avgCJMemoryValue: Int64 = 0
    private var maxCJMemoryValue: Int64 = 0
    private var avgArkTsMemoryValue: Int64 = 0
    private var maxArkTsMemoryValue: Int64 = 0
    private var totalHeapValue: Int64 = 0
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

    mut prop avgCJMemory: Int64 {
        get() {
            avgCJMemoryValue
        }
        set(value) {
            avgCJMemoryValue = value
        }
    }

    mut prop maxCJMemory: Int64 {
        get() {
            maxCJMemoryValue
        }
        set(value) {
            maxCJMemoryValue = value
        }
    }

    mut prop avgArkTsMemory: Int64 {
        get() {
            avgArkTsMemoryValue
        }
        set(value) {
            avgArkTsMemoryValue = value
        }
    }

    mut prop maxArkTsMemory: Int64 {
        get() {
            maxArkTsMemoryValue
        }
        set(value) {
            maxArkTsMemoryValue = value
        }
    }

    mut prop totalHeap: Int64 {
        get() {
            totalHeapValue
        }
        set(value) {
            totalHeapValue = value
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
        avgCJMemoryValue = 0
        maxCJMemoryValue = 0
        avgArkTsMemoryValue = 0
        maxArkTsMemoryValue = 0
        totalHeapValue = 0
        sampleCountValue = 0
    }

    func computeAvg(currrentMemoryValue: Int64, currrentCJMemoryValue: Int64, currrentArkTsMemoryValue: Int64, currentTotalHeap: Int64): Unit {
        // 系统内存 (PSS)
        this.avgMemoryValue = this.avgMemoryValue + (currrentMemoryValue - this.avgMemoryValue) / (sampleCountValue + 1)
        if (maxMemoryValue < currrentMemoryValue) {
            maxMemoryValue = currrentMemoryValue
        }

        // 仓颉堆内存
        this.avgCJMemoryValue = this.avgCJMemoryValue + (currrentCJMemoryValue - this.avgCJMemoryValue) / (sampleCountValue + 1)
        if (maxCJMemoryValue < currrentCJMemoryValue) {
            maxCJMemoryValue = currrentCJMemoryValue
        }

        // ArkTS 堆内存
        this.avgArkTsMemoryValue = this.avgArkTsMemoryValue + (currrentArkTsMemoryValue - this.avgArkTsMemoryValue) / (sampleCountValue + 1)
        if (maxArkTsMemoryValue < currrentArkTsMemoryValue) {
            maxArkTsMemoryValue = currrentArkTsMemoryValue
        }

        // 总堆内存 (取最新值)
        this.totalHeapValue = currentTotalHeap

        sampleCountValue++
    }

    /**
     * 计算 ArkTS 内存使用率 (heapUsed / totalHeap)
     * @return 使用率 0.0-1.0+，超过 0.8 表示高风险，超过 1.0 会触发 OOM
     */
    public func getArkTsMemoryUsageRate(): Float64 {
        if (totalHeapValue <= 0) {
            return 0.0
        }
        Float64(avgArkTsMemoryValue) / Float64(totalHeapValue)
    }

    public func getAvgMemory(): Int64 {
        this.avgMemoryValue
    }

    public func getMaxMemory(): Int64 {
        this.maxMemoryValue
    }

    public func getAvgCJMemory(): Int64 {
        this.avgCJMemoryValue
    }

    public func getMaxCJMemory(): Int64 {
        this.maxCJMemoryValue
    }

    public func getAvgArkTsMemory(): Int64 {
        this.avgArkTsMemoryValue
    }

    public func getMaxArkTsMemory(): Int64 {
        this.maxArkTsMemoryValue
    }

    public func getTotalHeap(): Int64 {
        this.totalHeapValue
    }

    public func getSampleCount(): Int64 {
        this.sampleCountValue
    }

    protected open func reset(): Unit {
        this.avgMemoryValue = 0
        this.maxMemoryValue = 0
        this.avgCJMemoryValue = 0
        this.maxCJMemoryValue = 0
        this.avgArkTsMemoryValue = 0
        this.maxArkTsMemoryValue = 0
        this.totalHeapValue = 0
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
        jsonObj.put("avgCJMemory", JsonString(avgCJMemory.toString()))
        jsonObj.put("maxCJMemory", JsonString(maxCJMemory.toString()))
        jsonObj.put("avgArkTsMemory", JsonString(avgArkTsMemory.toString()))
        jsonObj.put("maxArkTsMemory", JsonString(maxArkTsMemory.toString()))
        jsonObj.put("totalHeap", JsonString(totalHeap.toString()))
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
        jsonObj.put("avgCJMemory", JsonString(avgCJMemory.toString()))
        jsonObj.put("maxCJMemory", JsonString(maxCJMemory.toString()))
        jsonObj.put("avgArkTsMemory", JsonString(avgArkTsMemory.toString()))
        jsonObj.put("maxArkTsMemory", JsonString(maxArkTsMemory.toString()))
        jsonObj.put("totalHeap", JsonString(totalHeap.toString()))
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
        if (let Some(v) <-  jsonObject.get("avgCJMemory")) {
            processMemoryInfo.avgCJMemory = Int64.parse(JsonValueToString(v))
        }
        if (let Some(v) <-  jsonObject.get("maxCJMemory")) {
            processMemoryInfo.maxCJMemory = Int64.parse(JsonValueToString(v))
        }
        if (let Some(v) <-  jsonObject.get("avgArkTsMemory")) {
            processMemoryInfo.avgArkTsMemory = Int64.parse(JsonValueToString(v))
        }
        if (let Some(v) <-  jsonObject.get("maxArkTsMemory")) {
            processMemoryInfo.maxArkTsMemory = Int64.parse(JsonValueToString(v))
        }
        if (let Some(v) <-  jsonObject.get("totalHeap")) {
            processMemoryInfo.totalHeap = Int64.parse(JsonValueToString(v))
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
var SAMPLE_INTERVAL: Int64 = 30
var thresholdReported: Bool = false
var pageMemoryInfo = PageMemoryInfo(defaultPageName)
var processMemoryInfo = ProcessMemoryInfo()
var uiContext: Option<UIAbilityContext> = None
var reportPageMemory: (memoryInfo: PageMemoryInfo) -> Unit = {info: PageMemoryInfo =>}
var reportProcessMemory: (memoryInfo: ProcessMemoryInfo) -> Unit = {info: ProcessMemoryInfo =>}

var memory_init_flag = false

/**
 * 获取 ArkTS (JS) 堆内存信息
 * 使用 hidebug.getAppVMMemoryInfo() 获取虚拟机内存信息
 * @return VMMemoryInfo 包含 heapUsed, totalHeap, allArraySize
 */
public func getArkTsHeapSize(): Int64 {
    try {
        let vmMemoryInfo: VMMemoryInfo = getAppVMMemoryInfo()
        return vmMemoryInfo.heapUsed.toInt64()
    } catch (e: Exception) {
        AppLog.warn("hm-metricx-cj error: getArkTsHeapSize failed - " + e.toString())
    }
    return 0
}

/**
 * 获取 ArkTS 堆总大小
 * @return totalHeap 虚拟机堆总大小 (KB)
 */
public func getArkTsTotalHeap(): Int64 {
    try {
        let vmMemoryInfo: VMMemoryInfo = getAppVMMemoryInfo()
        return vmMemoryInfo.totalHeap.toInt64()
    } catch (e: Exception) {
        AppLog.warn("hm-metricx-cj error: getArkTsTotalHeap failed - " + e.toString())
    }
    return 0
}

let doMemorySample: (param: Array<String>) -> Unit = {
    param: Array<String> =>
    spawn {
        =>
            let memoryUsage = getPss().toInt64()
            let cjMemoryUsage = getAllocatedHeapSize() / 1024
            let arkTsMemoryUsage = getArkTsHeapSize()
            let arkTsTotalHeap = getArkTsTotalHeap()
            if (!thresholdReported) {
                if (memoryUsage >= MEMOMRY_THRESHOLD) {
                    processMemoryInfo.maxMemory = memoryUsage
                    reportProcessMemory(processMemoryInfo)
                    thresholdReported = true
                }
            }
            pageMemoryInfo.computeAvg(memoryUsage, cjMemoryUsage, arkTsMemoryUsage, arkTsTotalHeap)
            processMemoryInfo.computeAvg(memoryUsage, cjMemoryUsage, arkTsMemoryUsage, arkTsTotalHeap)
    }
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
    setInterval(doMemorySample, SAMPLE_INTERVAL * 1000, Array<String>())
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
    memoryThreshold!: Int64 = 100 * 1024,
    sampleInterval!: Int64 = 30
): Unit {
    if (memory_init_flag) {
    	return
    }
    memory_init_flag = true
    uiContext = context
    reportPageMemory = reportPageMemoryInfo
    reportProcessMemory = reportProcessMemoryInfo
    MEMOMRY_THRESHOLD = memoryThreshold
    SAMPLE_INTERVAL = sampleInterval
    let lastProcessMemory = getStoragedProcessMemory()
    if (let Some(v) <- lastProcessMemory) {
        reportProcessMemoryInfo(v)
    }
    setTimeout(handleMemory, SAMPLE_INTERVAL * 1000, Array<String>())
    on(navDestinationSwitch, uiContext.getOrThrow(), pageSwitchCallback)
}

public func destroyMemoryHandler(): Unit {
    off(navDestinationSwitch, uiContext.getOrThrow(), pageSwitchCallback)
    memory_init_flag = false
    // todo clearInterval
}
