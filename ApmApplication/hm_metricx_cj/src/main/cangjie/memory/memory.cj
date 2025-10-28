/**
 * Created on 2025/9/20
 */
package ohos_app_cangjie_hm_metricx_cj.memory

import ohos_app_cangjie_hm_metricx_cj.util.*
import ohos.ark_interop.*
import ohos.ark_interop_macro.*

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

@Interop[ArkTS]
public class InteropPageMemoryInfo {
    public let avgMemory: Int64
    public let maxMemory: Int64
    public let sampleCount: Int64
    public let pageName: String
    public init(a: Int64, m: Int64, s: Int64, p: String) {
        this.avgMemory = a
        this.maxMemory = m
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
        InteropPageMemoryInfo(this.avgMemory, this.maxMemory, this.sampleCount, this.pageName)
    }
}

@Interop[ArkTS]
public class InteropProcessMemoryInfo {
    public let avgMemory: Int64
    public let maxMemory: Int64
    public let sampleCount: Int64
    public let pid: Int64
    public init(a: Int64, m: Int64, s: Int64, p: Int64) {
        this.avgMemory = a
        this.maxMemory = m
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
        InteropProcessMemoryInfo(this.avgMemory, this.maxMemory, this.sampleCount, this.pid)
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
var _memoryPreference: Option<MemoryPreference> = None
let doMemorySample: () -> Unit = {
    =>
        let memoryUsage = _getMemoryUsage()
        if (!thresholdReported) {
            if (memoryUsage >= MEMOMRY_THRESHOLD) {
                processMemoryInfo.maxMemory = memoryUsage
                _reportProcessMemoryInfo(processMemoryInfo.toInteropProcessMemotyInfo())
                thresholdReported = true
            }
        }
        pageMemoryInfo.computeAvg(memoryUsage)
        processMemoryInfo.computeAvg(memoryUsage)
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
    onNavDestinationSwitch: (cb: (targetPageName: String) -> Unit) -> Unit,
    repeatSampleAndReportMemory: (sample: () -> Unit, report: () -> Unit, save: () -> Unit) -> Unit,
    reporPageMemoryInfo: (info: InteropPageMemoryInfo) -> Unit,
    reporProcessMemoryInfo: (info: InteropProcessMemoryInfo) -> Unit,
    memoryThreshold!: Int64 = 100 * 1024
): Unit {
    _memoryPreference = memoryPreference
    _getMemoryUsage = getMemoryUsage
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
