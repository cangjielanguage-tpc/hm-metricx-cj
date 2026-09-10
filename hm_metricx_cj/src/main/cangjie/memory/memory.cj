/**
 * Created on 2025/9/20
 */
package hm_metricx_cj.memory

import hm_metricx_cj.util.*
import ohos.ark_interop.*
import ohos.ark_interop_macro.*
import std.runtime.*

// ============== native PSS/rssLimit 直读包装（OH_HiDebug C API，替代 hidebug ArkTS 热路径）=============
// 详见 cpp/memory/memory_stats.cpp。互操作签名不变，Index.ets 的 hidebug 回调变死代码（向后兼容）。

// 进程级 PSS（KB）。native 调 OH_HiDebug_GetAppNativeMemInfo(&info) 读 info.pss。
// 与 hidebug.getPss 口径对齐。返回 <0 失败。
foreign func CaptureProcessPss(): Int64

// 进程级 rss 内存上限（KB）。native 调 OH_HiDebug_GetAppMemoryLimit(&limit) 读 limit.rssLimit。
// 与 hidebug.getAppMemoryLimit().rssLimit 口径对齐。返回 <0 失败。
foreign func CaptureProcessRssLimit(): Int64

public open class MemoryInfo {
    private var avgMemoryValue: Int64 = 0
    private var maxMemoryValue: Int64 = 0
    private var avgCJMemoryValue: Int64 = 0
    private var maxCJMemoryValue: Int64 = 0
    private var avgArkTsMemoryValue: Int64 = 0
    private var maxArkTsMemoryValue: Int64 = 0
    private var sampleCountValue: Int64 = 0
    private var totalMemoryLimitValue: Int64 = 0
    private var cjMemoryLimitValue: Int64 = 0
    private var arkTsMemoryLimitValue: Int64 = 0
    private var isTotalTopValue: Bool = false
    private var isCJTopValue: Bool = false
    private var isArkTsTopValue: Bool = false
    private var totalRatioThresholdValue: Float64 = 0.8
    private var cjRatioThresholdValue: Float64 = 0.8
    private var arkTsRatioThresholdValue: Float64 = 0.8

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
        sampleCountValue = 0
        totalMemoryLimitValue = 0
        cjMemoryLimitValue = 0
        arkTsMemoryLimitValue = 0
        isTotalTopValue = false
        isCJTopValue = false
        isArkTsTopValue = false
        totalRatioThresholdValue = 0.8
        cjRatioThresholdValue = 0.8
        arkTsRatioThresholdValue = 0.8
    }

    func computeAvg(currrentMemoryValue: Int64, currrentCJMemoryValue: Int64, currrentArkTsMemoryValue: Int64, 
                    currentArkTsMemoryLimit: Int64, currentTotalMemoryLimit: Int64): Unit {
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

        // 系统总内存限制 (只设置一次)
        if (totalMemoryLimitValue <= 0) {
            this.totalMemoryLimitValue = currentTotalMemoryLimit
        }

        // CJ 最大堆内存 (只设置一次，getMaxHeapSize 返回 byte，转 KB)
        if (cjMemoryLimitValue <= 0) {
            this.cjMemoryLimitValue = getMaxHeapSize() / 1024
        }

        // ArkTS 最大堆内存 (只设置一次)
        if (arkTsMemoryLimitValue <= 0) {
            this.arkTsMemoryLimitValue = currentArkTsMemoryLimit
        }

        // 判断是否触顶
        if (totalMemoryLimitValue > 0) {
            let totalUsageRate = Float64(currrentMemoryValue) / Float64(totalMemoryLimitValue)
            this.isTotalTopValue = totalUsageRate >= totalRatioThresholdValue
        }

        if (cjMemoryLimitValue > 0) {
            let cjUsageRate = Float64(currrentCJMemoryValue) / Float64(cjMemoryLimitValue)
            this.isCJTopValue = cjUsageRate >= cjRatioThresholdValue
        }

        if (arkTsMemoryLimitValue > 0) {
            let arkTsUsageRate = Float64(currrentArkTsMemoryValue) / Float64(arkTsMemoryLimitValue)
            this.isArkTsTopValue = arkTsUsageRate >= arkTsRatioThresholdValue
        }

        sampleCountValue++
    }

    /**
     * 获取系统总内存限制
     * @return 系统总内存限制 (KB)
     */
    public func getTotalMemoryLimit(): Int64 {
        this.totalMemoryLimitValue
    }

    /**
     * 获取 CJ 最大堆内存
     * @return CJ 最大堆内存 (KB)
     */
    public func getCJMemoryLimit(): Int64 {
        this.cjMemoryLimitValue
    }

    /**
     * 获取 ArkTS 最大堆内存
     * @return ArkTS 最大堆内存 (KB)
     */
    public func getArkTsMemoryLimit(): Int64 {
        this.arkTsMemoryLimitValue
    }

    /**
     * 获取系统总内存是否触顶
     * @return true 表示系统总内存使用率已达到阈值
     */
    public func isTotalTop(): Bool {
        this.isTotalTopValue
    }

    /**
     * 获取 CJ 是否触顶
     * @return true 表示 CJ 内存使用率已达到阈值
     */
    public func isCJTop(): Bool {
        this.isCJTopValue
    }

    /**
     * 获取 ArkTS 是否触顶
     * @return true 表示 ArkTS 内存使用率已达到阈值
     */
    public func isArkTsTop(): Bool {
        this.isArkTsTopValue
    }

    /**
     * 设置系统总内存触顶阈值
     * @param ratio 阈值 (0.0-1.0)，默认 0.8
     */
    public func setTotalRatioThreshold(ratio: Float64): Unit {
        if (ratio >= 0.0 && ratio <= 1.0) {
            this.totalRatioThresholdValue = ratio
        } else {
            this.totalRatioThresholdValue = 0.8
        }
    }

    /**
     * 设置 CJ 内存触顶阈值
     * @param ratio 阈值 (0.0-1.0)，默认 0.8
     */
    public func setCJRatioThreshold(ratio: Float64): Unit {
        if (ratio >= 0.0 && ratio <= 1.0) {
            this.cjRatioThresholdValue = ratio
        } else {
            this.cjRatioThresholdValue = 0.8
        }
    }

    /**
     * 设置 ArkTS 内存触顶阈值
     * @param ratio 阈值 (0.0-1.0)，默认 0.8
     */
    public func setArkTsRatioThreshold(ratio: Float64): Unit {
        if (ratio >= 0.0 && ratio <= 1.0) {
            this.arkTsRatioThresholdValue = ratio
        } else {
            this.arkTsRatioThresholdValue = 0.8
        }
    }

    /**
     * 计算系统内存平均使用率 (avgMemory / totalMemoryLimit)
     * @return 使用率 0.0-1.0+，超过 0.8 表示高风险
     */
    public func getMemoryAvgUsageRate(): Float64 {
        if (totalMemoryLimitValue <= 0) {
            return 0.0
        }
        Float64(avgMemoryValue) / Float64(totalMemoryLimitValue)
    }

    /**
     * 计算系统内存峰值使用率 (maxMemory / totalMemoryLimit)
     * @return 使用率 0.0-1.0+，超过 0.8 表示高风险
     */
    public func getMemoryMaxUsageRate(): Float64 {
        if (totalMemoryLimitValue <= 0) {
            return 0.0
        }
        Float64(maxMemoryValue) / Float64(totalMemoryLimitValue)
    }

    /**
     * 计算 CJ 内存平均使用率 (avgCJMemory / cjMemoryLimit)
     * @return 使用率 0.0-1.0+
     */
    public func getCJMemoryAvgUsageRate(): Float64 {
        if (cjMemoryLimitValue <= 0) {
            return 0.0
        }
        Float64(avgCJMemoryValue) / Float64(cjMemoryLimitValue)
    }

    /**
     * 计算 CJ 内存峰值使用率 (maxCJMemory / cjMemoryLimit)
     * @return 使用率 0.0-1.0+
     */
    public func getCJMemoryMaxUsageRate(): Float64 {
        if (cjMemoryLimitValue <= 0) {
            return 0.0
        }
        Float64(maxCJMemoryValue) / Float64(cjMemoryLimitValue)
    }

    /**
     * 计算 ArkTS 内存平均使用率 (avgArkTsMemory / arkTsMemoryLimit)
     * @return 使用率 0.0-1.0+，超过 0.8 表示高风险
     */
    public func getArkTsMemoryAvgUsageRate(): Float64 {
        if (arkTsMemoryLimitValue <= 0) {
            return 0.0
        }
        Float64(avgArkTsMemoryValue) / Float64(arkTsMemoryLimitValue)
    }

    /**
     * 计算 ArkTS 内存峰值使用率 (maxArkTsMemory / arkTsMemoryLimit)
     * @return 使用率 0.0-1.0+，超过 0.8 表示高风险
     */
    public func getArkTsMemoryMaxUsageRate(): Float64 {
        if (arkTsMemoryLimitValue <= 0) {
            return 0.0
        }
        Float64(maxArkTsMemoryValue) / Float64(arkTsMemoryLimitValue)
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
        this.sampleCountValue = 0
        this.totalMemoryLimitValue = 0
        this.cjMemoryLimitValue = 0
        this.arkTsMemoryLimitValue = 0
        this.isTotalTopValue = false
        this.isCJTopValue = false
        this.isArkTsTopValue = false
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
    public let sampleCount: Int64
    public let pageName: String
    public let totalMemoryLimit: Int64
    public let cjMemoryLimit: Int64
    public let arkTsMemoryLimit: Int64
    public let isTotalTop: Bool
    public let isCJTop: Bool
    public let isArkTsTop: Bool
    public let memoryAvgUsageRate: Float64
    public let memoryMaxUsageRate: Float64
    public let cjMemoryAvgUsageRate: Float64
    public let cjMemoryMaxUsageRate: Float64
    public let arkTsMemoryAvgUsageRate: Float64
    public let arkTsMemoryMaxUsageRate: Float64
    public init(a: Int64, m: Int64, acj: Int64, mcj: Int64, aark: Int64, mark: Int64, s: Int64, p: String,
                tml: Int64, cjl: Int64, atl: Int64, itt: Bool, ict: Bool, iat: Bool,
                maur: Float64, mmur: Float64, cmaur: Float64, cmmur: Float64, atmaur: Float64, atmmur: Float64) {
        this.avgMemory = a
        this.maxMemory = m
        this.avgCJMemory = acj
        this.maxCJMemory = mcj
        this.avgArkTsMemory = aark
        this.maxArkTsMemory = mark
        this.sampleCount = s
        this.pageName = p
        this.totalMemoryLimit = tml
        this.cjMemoryLimit = cjl
        this.arkTsMemoryLimit = atl
        this.isTotalTop = itt
        this.isCJTop = ict
        this.isArkTsTop = iat
        this.memoryAvgUsageRate = maur
        this.memoryMaxUsageRate = mmur
        this.cjMemoryAvgUsageRate = cmaur
        this.cjMemoryMaxUsageRate = cmmur
        this.arkTsMemoryAvgUsageRate = atmaur
        this.arkTsMemoryMaxUsageRate = atmmur
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
        InteropPageMemoryInfo(
            this.avgMemory, this.maxMemory, this.avgCJMemory, this.maxCJMemory,
            this.avgArkTsMemory, this.maxArkTsMemory, this.sampleCount, this.pageName,
            this.getTotalMemoryLimit(), this.getCJMemoryLimit(), this.getArkTsMemoryLimit(),
            this.isTotalTop(), this.isCJTop(), this.isArkTsTop(),
            this.getMemoryAvgUsageRate(), this.getMemoryMaxUsageRate(),
            this.getCJMemoryAvgUsageRate(), this.getCJMemoryMaxUsageRate(),
            this.getArkTsMemoryAvgUsageRate(), this.getArkTsMemoryMaxUsageRate()
        )
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
    public let sampleCount: Int64
    public let pid: Int64
    public let totalMemoryLimit: Int64
    public let cjMemoryLimit: Int64
    public let arkTsMemoryLimit: Int64
    public let isTotalTop: Bool
    public let isCJTop: Bool
    public let isArkTsTop: Bool
    public let memoryAvgUsageRate: Float64
    public let memoryMaxUsageRate: Float64
    public let cjMemoryAvgUsageRate: Float64
    public let cjMemoryMaxUsageRate: Float64
    public let arkTsMemoryAvgUsageRate: Float64
    public let arkTsMemoryMaxUsageRate: Float64
    public init(a: Int64, m: Int64, acj: Int64, mcj: Int64, aark: Int64, mark: Int64, s: Int64, p: Int64,
                tml: Int64, cjl: Int64, atl: Int64, itt: Bool, ict: Bool, iat: Bool,
                maur: Float64, mmur: Float64, cmaur: Float64, cmmur: Float64, atmaur: Float64, atmmur: Float64) {
        this.avgMemory = a
        this.maxMemory = m
        this.avgCJMemory = acj
        this.maxCJMemory = mcj
        this.avgArkTsMemory = aark
        this.maxArkTsMemory = mark
        this.sampleCount = s
        this.pid = p
        this.totalMemoryLimit = tml
        this.cjMemoryLimit = cjl
        this.arkTsMemoryLimit = atl
        this.isTotalTop = itt
        this.isCJTop = ict
        this.isArkTsTop = iat
        this.memoryAvgUsageRate = maur
        this.memoryMaxUsageRate = mmur
        this.cjMemoryAvgUsageRate = cmaur
        this.cjMemoryMaxUsageRate = cmmur
        this.arkTsMemoryAvgUsageRate = atmaur
        this.arkTsMemoryMaxUsageRate = atmmur
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
        InteropProcessMemoryInfo(
            this.avgMemory, this.maxMemory, this.avgCJMemory, this.maxCJMemory,
            this.avgArkTsMemory, this.maxArkTsMemory, this.sampleCount, this.pid,
            this.getTotalMemoryLimit(), this.getCJMemoryLimit(), this.getArkTsMemoryLimit(),
            this.isTotalTop(), this.isCJTop(), this.isArkTsTop(),
            this.getMemoryAvgUsageRate(), this.getMemoryMaxUsageRate(),
            this.getCJMemoryAvgUsageRate(), this.getCJMemoryMaxUsageRate(),
            this.getArkTsMemoryAvgUsageRate(), this.getArkTsMemoryMaxUsageRate()
        )
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
var _memoryPreference: Option<MemoryPreference> = None
var memory_init_flag = false

// ArkTS VM 堆缓存（heapUsed / vmHeapLimit，KB）。
// native OH_HiDebug 无 ArkTS VM 堆等价字段（HiDebug_NativeMemInfo 是 smaps，HiDebug_MemoryLimit
// 仅 rss/vss），唯一数据源是 hidebug.getAppVMMemoryInfo()/getAppMemoryLimit() ArkTS NAPI——
// 主线程 2s 热循环直调会触发 ApiInvokeRecorder 析构 FFRT 退避致 THREAD_BLOCK_6S ANR。
// 故由 ArkTS 侧 Worker 线程异步采样、经 onmessage 回主线程调本 setter 灌缓存。
// doMemorySample 读缓存（滞后 ≤1 周期可接受），主线程零 hidebug 调用，ANR 根除，字段全有效。
var _arkTsMemoryUsage: Int64 = 0
var _arkTsMemoryLimit: Int64 = 0

/**
 * ArkTS 端 Worker 异步采样到 heapUsed/vmHeapLimit 后经 interop 调本 setter 灌入缓存。
 * 必须在主线程调（onmessage 回调上下文），保证与 doMemorySample 读同线程、无并发写。
 * limit 只在首次非 0 时写一次（对齐 computeAvg 行 153 的「只设一次」语义）。
 */
public func setArkTsMemoryCache(usage: Int64, limit: Int64): Unit {
    _arkTsMemoryUsage = usage
    if (limit > 0) {
        _arkTsMemoryLimit = limit
    }
}

/**
 * 仓颉侧直接获取 CJ 堆内存大小
 * 使用仓颉运行时 API getAllocatedHeapSize()
 */
func getCJMemoryUsageFromCJ(): Int64 {
    unsafe {
        getAllocatedHeapSize() / 1024
    }
}

// 进程级 PSS（KB）。失败返回 0（与原 ArkTS hidebug.getPss 回调失败口径一致）。
// try-catch 保护避免 native 异常杀死 2s setInterval 采样循环。
func getPssNative(): Int64 {
    try {
        let pss = unsafe { CaptureProcessPss() }
        if (pss < 0) {
            return 0
        }
        return pss
    } catch (e: Exception) {
        metricx_warn("hm-metricx-cj: getPssNative exception: " + e.toString())
        return 0
    }
}

// 进程级 rss 内存上限（KB）。失败返回 0。
func getRssLimitNative(): Int64 {
    try {
        let limit = unsafe { CaptureProcessRssLimit() }
        if (limit < 0) {
            return 0
        }
        return limit
    } catch (e: Exception) {
        metricx_warn("hm-metricx-cj: getRssLimitNative exception: " + e.toString())
        return 0
    }
}

let doMemorySample: () -> Unit = {
    =>
        // PSS 与 rssLimit 改 native OH_HiDebug 直读，绕开 hidebug NAPI 退避路径。
        // ArkTS VM 堆 used/limit native 无等价字段，改由 ArkTS Worker 异步采样灌缓存
        // （见 setArkTsMemoryCache）。本处读缓存，滞后 ≤1 周期可接受，主线程零 hidebug 调用。
        let memoryUsage = getPssNative()
        let cjMemoryUsage = getCJMemoryUsageFromCJ()
        let arkTsMemoryUsage = _arkTsMemoryUsage
        let arkTsMemoryLimit = _arkTsMemoryLimit
        let totalMemoryLimit = getRssLimitNative()
        if (!thresholdReported) {
            if (memoryUsage >= MEMOMRY_THRESHOLD) {
                processMemoryInfo.maxMemory = memoryUsage
                _reportProcessMemoryInfo(processMemoryInfo.toInteropProcessMemotyInfo())
                thresholdReported = true
            }
        }
        pageMemoryInfo.computeAvg(memoryUsage, cjMemoryUsage, arkTsMemoryUsage, arkTsMemoryLimit, totalMemoryLimit)
        processMemoryInfo.computeAvg(memoryUsage, cjMemoryUsage, arkTsMemoryUsage, arkTsMemoryLimit, totalMemoryLimit)
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
            preference.put("processMemory_totalMemoryLimit", processMemoryInfo.getTotalMemoryLimit())
            preference.put("processMemory_cjMemoryLimit", processMemoryInfo.getCJMemoryLimit())
            preference.put("processMemory_arkTsMemoryLimit", processMemoryInfo.getArkTsMemoryLimit())
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
    onNavDestinationSwitch: (cb: (targetPageName: String) -> Unit) -> Unit,
    repeatSampleAndReportMemory: (sample: () -> Unit, report: () -> Unit, save: () -> Unit) -> Unit,
    reporPageMemoryInfo: (info: InteropPageMemoryInfo) -> Unit,
    reporProcessMemoryInfo: (info: InteropProcessMemoryInfo) -> Unit,
    memoryThreshold!: Int64 = 100 * 1024,
    totalRatio!: Float64 = 0.8,
    cjRatio!: Float64 = 0.8,
    arkTsRatio!: Float64 = 0.8
): Unit {
    if (memory_init_flag) {
    	return
    }
    memory_init_flag = true
    _memoryPreference = memoryPreference
    _reportPageMemoryInfo = reporPageMemoryInfo
    _reportProcessMemoryInfo = reporProcessMemoryInfo
    MEMOMRY_THRESHOLD = memoryThreshold

    // 设置触顶阈值
    pageMemoryInfo.setTotalRatioThreshold(totalRatio)
    pageMemoryInfo.setCJRatioThreshold(cjRatio)
    pageMemoryInfo.setArkTsRatioThreshold(arkTsRatio)
    processMemoryInfo.setTotalRatioThreshold(totalRatio)
    processMemoryInfo.setCJRatioThreshold(cjRatio)
    processMemoryInfo.setArkTsRatioThreshold(arkTsRatio)

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
    memory_init_flag = false
}
