/**
 * Created on 2025/9/20
 */
package ohos_app_cangjie_hm_metricx_cj.memory

import ohos_app_cangjie_hm_metricx_cj.util.*
import ohos.ark_interop.*
import ohos.ark_interop_macro.*
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

@Interop[ArkTS]
public class InteropPageMemoryInfo {
    public let avgMemory: Int64
    public let maxMemory: Int64
    public let avgCJMemory: Int64
    public let maxCJMemory: Int64
    public let avgArkTsMemory: Int64
    public let maxArkTsMemory: Int64
    public let totalHeap: Int64
    public let sampleCount: Int64
    public let pageName: String
    public init(a: Int64, m: Int64, acj: Int64, mcj: Int64, aark: Int64, mark: Int64, th: Int64, s: Int64, p: String) {
        this.avgMemory = a
        this.maxMemory = m
        this.avgCJMemory = acj
        this.maxCJMemory = mcj
        this.avgArkTsMemory = aark
        this.maxArkTsMemory = mark
        this.totalHeap = th
        this.sampleCount = s
        this.pageName = p
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

    func toInteropPageMemoryInfo(): InteropPageMemoryInfo {
        InteropPageMemoryInfo(this.avgMemory, this.maxMemory, this.avgCJMemory, this.maxCJMemory, this.avgArkTsMemory, this.maxArkTsMemory, this.totalHeap, this.sampleCount, this.pageName)
    }
}

@Interop[ArkTS]
public class InteropProcessMemoryInfo {
    public let avgMemory: Int64
    public let maxMemory: Int64
    public let avgCJMemory: Int64
    public let maxCJMemory: Int64
    public let avgArkTsMemory: Int64
    public let maxArkTsMemory: Int64
    public let totalHeap: Int64
    public let sampleCount: Int64
    public let pid: Int64
    public init(a: Int64, m: Int64, acj: Int64, mcj: Int64, aark: Int64, mark: Int64, th: Int64, s: Int64, p: Int64) {
        this.avgMemory = a
        this.maxMemory = m
        this.avgCJMemory = acj
        this.maxCJMemory = mcj
        this.avgArkTsMemory = aark
        this.maxArkTsMemory = mark
        this.totalHeap = th
        this.sampleCount = s
        this.pid = p
    }
}

public class ProcessMemoryInfo <: MemoryInfo {
    private var pidValue: Int64 = 0

    mut prop pid: Int64 {
        get() {
            this.pidValue
        }
        set(value) {
            this.pidValue = value
        }
    }

    public init() {
        this.pidValue = PID
    }

    public init(pidValue: Int64) {
        this.pidValue = pidValue
    }

    func toInteropProcessMemotyInfo(): InteropProcessMemoryInfo {
        InteropProcessMemoryInfo(this.avgMemory, this.maxMemory, this.avgCJMemory, this.maxCJMemory, this.avgArkTsMemory, this.maxArkTsMemory, this.totalHeap, this.sampleCount, this.pid)
    }
}

@Interop[ArkTS]
public interface MemoryPreference {
    func put(key: String, value: Int64): Unit
    func has(key: String): Bool
    func get(key: String, defaultValue: Int64): Int64
}

var MEMOMRY_THRESHOLD: Int64 = 1024 * 100
var thresholdReported: Bool = false
var pageMemoryInfo = PageMemoryInfo(defaultPageName)
var processMemoryInfo = ProcessMemoryInfo()
var currentPageName: String = defaultPageName
var _reportPageMemoryInfo: (info: InteropPageMemoryInfo) -> Unit = {_ =>}
var _reportProcessMemoryInfo: (info: InteropProcessMemoryInfo) -> Unit = {_ =>}
var _getMemoryUsage: () -> Int64 = {=> 0}
var _getArkTsMemoryUsage: () -> Int64 = {=> 0}
var _getArkTsTotalHeap: () -> Int64 = {=> 0}
var _memoryPreference: Option<MemoryPreference> = None

/**
 * 仓颉侧直接获取 CJ 堆内存大小
 * 使用仓颉运行时 API getAllocatedHeapSize()
 */
func getCJMemoryUsageFromCJ(): Int64 {
    unsafe {
        getAllocatedHeapSize() / 1024
    }
}

let doMemorySample: () -> Unit = {
    =>
        let memoryUsage = _getMemoryUsage()
        let cjMemoryUsage = getCJMemoryUsageFromCJ()
        let arkTsMemoryUsage = _getArkTsMemoryUsage()
        let arkTsTotalHeap = _getArkTsTotalHeap()
        if (!thresholdReported) {
            if (memoryUsage >= MEMOMRY_THRESHOLD) {
                processMemoryInfo.maxMemory = memoryUsage
                _reportProcessMemoryInfo(processMemoryInfo.toInteropProcessMemotyInfo())
                thresholdReported = true
            }
        }
        pageMemoryInfo.computeAvg(memoryUsage, cjMemoryUsage, arkTsMemoryUsage, arkTsTotalHeap)
        processMemoryInfo.computeAvg(memoryUsage, cjMemoryUsage, arkTsMemoryUsage, arkTsTotalHeap)
}
let handleMemoryReport: () -> Unit = {
    => _reportProcessMemoryInfo(processMemoryInfo.toInteropProcessMemotyInfo())
}

let saveProcessMemory: () -> Unit = {
    =>
    try {
        if (let Some(preference) <- _memoryPreference) {
            preference.put("processMemory_maxMemory", processMemoryInfo.maxMemory)
            preference.put("processMemory_avgMemory", processMemoryInfo.avgMemory)
            preference.put("processMemory_maxCJMemory", processMemoryInfo.maxCJMemory)
            preference.put("processMemory_avgCJMemory", processMemoryInfo.avgCJMemory)
            preference.put("processMemory_maxArkTsMemory", processMemoryInfo.maxArkTsMemory)
            preference.put("processMemory_avgArkTsMemory", processMemoryInfo.avgArkTsMemory)
            preference.put("processMemory_totalHeap", processMemoryInfo.totalHeap)
            preference.put("processMemory_pid", processMemoryInfo.pid)
            preference.put("processMemory_sampleCount", processMemoryInfo.sampleCount)
        }
    } catch (e:Exception) {
        metricx_warn("hm-metricx-cj error: " + e.toString())
    }
}

public func getPageMemoryInfo(): InteropPageMemoryInfo {
    pageMemoryInfo.toInteropPageMemoryInfo()
}

public func getProcessMemoryInfo(): InteropProcessMemoryInfo {
    processMemoryInfo.toInteropProcessMemotyInfo()
}

private func getStoragedProcessMemory(): ProcessMemoryInfo {
    let processMemoryInfo = ProcessMemoryInfo()
    try {
        if (let Some(preference) <- _memoryPreference) {
            processMemoryInfo.maxMemory = preference.get("processMemory_maxMemory", 0)
            processMemoryInfo.avgMemory = preference.get("processMemory_avgMemory", 0)
            processMemoryInfo.maxCJMemory = preference.get("processMemory_maxCJMemory", 0)
            processMemoryInfo.avgCJMemory = preference.get("processMemory_avgCJMemory", 0)
            processMemoryInfo.maxArkTsMemory = preference.get("processMemory_maxArkTsMemory", 0)
            processMemoryInfo.avgArkTsMemory = preference.get("processMemory_avgArkTsMemory", 0)
            processMemoryInfo.totalHeap = preference.get("processMemory_totalHeap", 0)
            processMemoryInfo.pid = preference.get("processMemory_pid", 0)
            processMemoryInfo.sampleCount = preference.get("processMemory_sampleCount", 0)
        }
    } catch (e: Exception) {
        metricx_warn(e.toString())
    }
    processMemoryInfo
}

public func initMemoryHandler(
    memoryPreference: MemoryPreference,
    getMemoryUsage: () -> Int64,
    getArkTsMemoryUsage: () -> Int64,
    getArkTsTotalHeap: () -> Int64,
    onNavDestinationSwitch: (cb: (targetPageName: String) -> Unit) -> Unit,
    repeatSampleAndReportMemory: (sample: () -> Unit, report: () -> Unit, save: () -> Unit) -> Unit,
    reporPageMemoryInfo: (info: InteropPageMemoryInfo) -> Unit,
    reporProcessMemoryInfo: (info: InteropProcessMemoryInfo) -> Unit,
    memoryThreshold!: Int64 = 100 * 1024
): Unit {
    _memoryPreference = memoryPreference
    _getMemoryUsage = getMemoryUsage
    _getArkTsMemoryUsage = getArkTsMemoryUsage
    _getArkTsTotalHeap = getArkTsTotalHeap
    _reportPageMemoryInfo = reporPageMemoryInfo
    _reportProcessMemoryInfo = reporProcessMemoryInfo
    MEMOMRY_THRESHOLD = memoryThreshold

    let lastProcessMemory = getStoragedProcessMemory()
    _reportProcessMemoryInfo(lastProcessMemory.toInteropProcessMemotyInfo())
    repeatSampleAndReportMemory(doMemorySample, handleMemoryReport, saveProcessMemory)
    onNavDestinationSwitch(
        {
            targetPageName: String =>
                if (!targetPageName.isEmpty()) {
                    currentPageName = targetPageName
                }
                doMemorySample()
                _reportPageMemoryInfo(pageMemoryInfo.toInteropPageMemoryInfo())
                pageMemoryInfo.reset()
                pageMemoryInfo.pageName = currentPageName
        }
    )
}

public func destroyMemoryHandler(): Unit {
    saveProcessMemory()
}
