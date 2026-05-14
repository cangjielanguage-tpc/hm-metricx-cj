/**
 * Created on 2025/9/19
 */
package ohos_app_cangjie_hm_metricx_cj.cpu

import ohos_app_cangjie_hm_metricx_cj.util.*
import ohos.ark_interop.*
import ohos.ark_interop_macro.*
import std.convert.*
import std.posix.*
import std.collection.*
import std.time.*
import std.io.*
import std.fs.*
import std.process.*
import std.sort.*
import ohos.base.AppLog

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

    func getAvgCpu(): Float64 {
        this.avgCpuValue
    }

    func getMaxCpu(): Float64 {
        this.maxCpuValue
    }

    protected open func reset(): Unit {
        this.avgCpuValue = 0.0
        this.maxCpuValue = 0.0
        this.sampleCount = 0
    }
}

@Interop[ArkTS]
public class InteropPageCpuInfo {
    public let avgCpu: Float64
    public let maxCpu: Float64
    public let sampleCount: Int64
    public let pageName: String
    public init(a: Float64, m: Float64, s: Int64, p: String) {
        this.avgCpu = a
        this.maxCpu = m
        this.sampleCount = s
        this.pageName = p
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

    func getPageName(): String {
        pageNameValue
    }

    protected override func reset() {
        super.reset()
        this.pageNameValue = ""
    }

    func toInteropPageCpuInfo(): InteropPageCpuInfo {
        InteropPageCpuInfo(this.avgCpu, this.maxCpu, this.sampleCount, this.pageName)
    }
}

@Interop[ArkTS]
public class InteropProcessCpuInfo {
    public let avgCpu: Float64
    public let maxCpu: Float64
    public let sampleCount: Int64
    public let pid: Int64
    public init(a: Float64, m: Float64, s: Int64, p: Int64) {
        this.avgCpu = a
        this.maxCpu = m
        this.sampleCount = s
        this.pid = p
    }
}

public class ProcessCpuInfo <: CpuInfo {
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

    func toInteropProcessCpuInfo(): InteropProcessCpuInfo {
        InteropProcessCpuInfo(this.avgCpu, this.maxCpu, this.sampleCount, this.pid)
    }
}

var pageCpuInfo = PageCpuInfo(defaultPageName)
var processCpuInfo = ProcessCpuInfo()
var currentPageName: String = defaultPageName
var _getCpuUsage: () -> Float64 = {=> 0.0}
let doCpuSample: () -> Unit = {
    =>
        let cpuUsage = _getCpuUsage()
        pageCpuInfo.computeAvg(cpuUsage)
        processCpuInfo.computeAvg(cpuUsage)
}
var _reporProcessCpuInfo: (info: InteropProcessCpuInfo) -> Unit = {_ =>}
let handleCpuReport: () -> Unit = {
    => _reporProcessCpuInfo(processCpuInfo.toInteropProcessCpuInfo())
}

var cpu_init_flag = false
var high_cpu_init_flag = false

public func getPageCpuInfo(): InteropPageCpuInfo {
    pageCpuInfo.toInteropPageCpuInfo()
}

public func getProcessCpuInfo(): InteropProcessCpuInfo {
    processCpuInfo.toInteropProcessCpuInfo()
}

public func initCpuHandler(
    getCpuUsage: () -> Float64,
    onNavDestinationSwitch: (cb: (targetPageName: String) -> Unit) -> Unit,
    repeatSampleAndReportCpu: (sample: () -> Unit, report: () -> Unit) -> Unit,
    reporPageCpuInfo: (info: InteropPageCpuInfo) -> Unit,
    reporProcessCpuInfo: (info: InteropProcessCpuInfo) -> Unit
): Unit {
    if (cpu_init_flag) {
    	return
    }
    cpu_init_flag = true
    _getCpuUsage = getCpuUsage
    _reporProcessCpuInfo = reporProcessCpuInfo
    repeatSampleAndReportCpu(doCpuSample, handleCpuReport)
    onNavDestinationSwitch(
        {
            targetPageName =>
                if (!targetPageName.isEmpty()) {
                    currentPageName = targetPageName
                }
                doCpuSample()
                reporPageCpuInfo(pageCpuInfo.toInteropPageCpuInfo())
                pageCpuInfo.reset()
                pageCpuInfo.pageName = currentPageName
        }
    )
}

/**
 * 线程 CPU 使用情况（用于 ArkTS 传递给仓颉）
 */
public class ThreadCpuUsageInfo {
    public let threadId: Int32
    public let cpuUsage: Float64

    public init(threadId: Int32, cpuUsage: Float64) {
        this.threadId = threadId
        this.cpuUsage = cpuUsage
    }
}

// 线程栈信息（用于上报）
public class ThreadStackInfo {
    private var tidValue: Int64 = 0                   // 线程 ID（唯一标识）
    private var threadNameValue: String = ""          // 线程名称
    private var avgCpuUsageValue: Float64 = 0.0       // 平均 CPU 使用率（0-1 之间）
    private var maxCpuUsageValue: Float64 = 0.0       // 最大 CPU 使用率（0-1 之间）
    private var sampleCountValue: Int64 = 0           // 总采样次数
    private var stackTraceValue: String = ""          // 线程调用栈（用于定位代码位置）
    private var moduleNameValue: String = ""          // 所属模块名（如 xxx.so，用于定位责任模块）
    private var firstDetectedTimeValue: Int64 = 0     // 首次检测到高占用的时间戳（毫秒）
    private var highSampleCountValue: Int64 = 0       // CPU>50% 的采样次数（用于计算高采样比例）

    public mut prop tid: Int64 {
        get() { tidValue }
        set(value) { tidValue = value }
    }
    public mut prop threadName: String {
        get() { threadNameValue }
        set(value) { threadNameValue = value }
    }
    public mut prop avgCpuUsage: Float64 {
        get() { avgCpuUsageValue }
        set(value) { avgCpuUsageValue = value }
    }
    public mut prop maxCpuUsage: Float64 {
        get() { maxCpuUsageValue }
        set(value) { maxCpuUsageValue = value }
    }
    public mut prop sampleCount: Int64 {
        get() { sampleCountValue }
        set(value) { sampleCountValue = value }
    }
    public mut prop stackTrace: String {
        get() { stackTraceValue }
        set(value) { stackTraceValue = value }
    }
    public mut prop moduleName: String {
        get() { moduleNameValue }
        set(value) { moduleNameValue = value }
    }
    public mut prop firstDetectedTime: Int64 {
        get() { firstDetectedTimeValue }
        set(value) { firstDetectedTimeValue = value }
    }
    public mut prop highSampleCount: Int64 {
        get() { highSampleCountValue }
        set(value) { highSampleCountValue = value }
    }

    /**
     * 计算平均 CPU 使用率并更新统计信息
     *
     * 每次采样时调用此方法，会：
     * 1. 更新平均 CPU 使用率（增量计算）
     * 2. 更新最大 CPU 使用率
     * 3. 增加采样次数
     * 4. 如果 CPU > cpuThreshold，增加高采样次数
     *
     * @param cpuUsage 当前 CPU 使用率（0-1 之间）
     * @param threshold CPU 阈值（从 config 传入）
     */
    public func computeAvg(cpuUsage: Float64, threshold!: Float64 = 0.5): Unit {
        this.avgCpuUsageValue = this.avgCpuUsageValue + (cpuUsage - this.avgCpuUsageValue) / Float64(sampleCountValue + 1)
        if (maxCpuUsageValue < cpuUsage) {
            maxCpuUsageValue = cpuUsage
        }
        sampleCountValue++
        // 统计高 CPU 采样次数（使用动态阈值）
        if (cpuUsage > threshold) {
            highSampleCountValue++
        }
    }

    /**
     * 获取高采样比例
     *
     * 计算 CPU>50% 的采样次数占总采样次数的比例
     * 用于判定线程是否持续高占用（>=85% 视为持续高占用）
     *
     * @return 高采样比例（0-1 之间），采样次数为 0 时返回 0.0
     */
    public func getHighSampleRatio(): Float64 {
        if (sampleCountValue == 0) {
            return 0.0
        }
        return Float64(highSampleCountValue) / Float64(sampleCountValue)
    }

    /**
     * 转换为 JSON 字符串
     */
    public func toJson(): String {
        // 转义 stackTrace 中的特殊字符
        let escapedStackTrace = this.stackTrace.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")

        let sb = StringBuilder()
        sb.append("{\"tid\":")
        sb.append(this.tid.toString())
        sb.append(",\"threadName\":\"")
        sb.append(this.threadName)
        sb.append("\",\"avgCpuUsage\":")
        sb.append(this.avgCpuUsage.toString())
        sb.append(",\"maxCpuUsage\":")
        sb.append(this.maxCpuUsage.toString())
        sb.append(",\"sampleCount\":")
        sb.append(this.sampleCount.toString())
        sb.append(",\"stackTrace\":\"")
        sb.append(escapedStackTrace)
        sb.append("\",\"moduleName\":\"")
        sb.append(this.moduleName)
        sb.append("\",\"firstDetectedTime\":")
        sb.append(this.firstDetectedTime.toString())
        sb.append(",\"highSampleCount\":")
        sb.append(this.highSampleCount.toString())
        sb.append("}")
        sb.toString()
    }
}

// 高 CPU 占用上报信息
public class HighCpuReportInfo {
    private var timestampValue: Int64 = 0             // 上报时间戳（毫秒，Unix 纪元时间）
    private var pidValue: Int32 = 0                   // 进程 ID（唯一标识当前进程）
    private var processNameValue: String = ""         // 进程名称（包名）
    private var pageNameValue: String = ""            // 当前页面名称（发生高 CPU 占用时的页面）
    private var highCpuThreadsValue: ArrayList<ThreadStackInfo> = ArrayList()  // 高占用线程列表（所有符合条件的线程）
    private var avgProcessCpuValue: Float64 = 0.0     // 监控时长内进程平均 CPU 使用率（0-1 之间）
    private var maxProcessCpuValue: Float64 = 0.0     // 监控时长内进程最大 CPU 使用率（0-1 之间）
    private var monitorDurationValue: Int64 = 180000     // 监控时长（毫秒），用于上报显示

    public mut prop timestamp: Int64 {
        get() { timestampValue }
        set(value) { timestampValue = value }
    }
    public mut prop pid: Int32 {
        get() { pidValue }
        set(value) { pidValue = value }
    }
    public mut prop processName: String {
        get() { processNameValue }
        set(value) { processNameValue = value }
    }
    public mut prop pageName: String {
        get() { pageNameValue }
        set(value) { pageNameValue = value }
    }
    public mut prop highCpuThreads: ArrayList<ThreadStackInfo> {
        get() { highCpuThreadsValue }
        set(value) { highCpuThreadsValue = value }
    }
    public mut prop avgProcessCpu: Float64 {
        get() { avgProcessCpuValue }
        set(value) { avgProcessCpuValue = value }
    }
    public mut prop maxProcessCpu: Float64 {
        get() { maxProcessCpuValue }
        set(value) { maxProcessCpuValue = value }
    }
    public mut prop monitorDuration: Int64 {
        get() { monitorDurationValue }
        set(value) { monitorDurationValue = value }
    }

    /**
     * 转换为 JSON 字符串
     */
    public func toJson(): String {
        // 构建 highCpuThreads JSON 数组
        let threadsSb = StringBuilder()
        threadsSb.append("[")
        var first = true
        for (thread in this.highCpuThreads) {
            if (!first) {
                threadsSb.append(",")
            }
            threadsSb.append(thread.toJson())
            first = false
        }
        threadsSb.append("]")

        // 构建完整 JSON
        let sb = StringBuilder()
        sb.append("{\"timestamp\":")
        sb.append(this.timestamp.toString())
        sb.append(",\"pid\":")
        sb.append(this.pid.toString())
        sb.append(",\"processName\":\"")
        sb.append(this.processName)
        sb.append("\",\"pageName\":\"")
        sb.append(this.pageName)
        sb.append("\",\"highCpuThreads\":")
        sb.append(threadsSb.toString())
        sb.append(",\"avgProcessCpu\":")
        sb.append(this.avgProcessCpu.toString())
        sb.append(",\"maxProcessCpu\":")
        sb.append(this.maxProcessCpu.toString())
        sb.append(",\"monitorDuration\":")
        sb.append(this.monitorDuration.toString())
        sb.append("}")
        sb.toString()
    }
}

// 高 CPU 监控配置
public class HighCpuMonitorConfig {
    // CPU 占用阈值（0-1 之间），默认 0.5 表示 50% 超过此值的线程被视为高占用线程
    public let cpuThreshold: Float64
    // 前台采样间隔（毫秒），默认 1000ms (1 秒)
    public let foregroundIntervalMs: Int64
    // 后台采样间隔（毫秒），默认 2000ms (2 秒)
    public let backgroundIntervalMs: Int64
    // 监控时长（毫秒），默认 180000 毫秒（3 分钟）达到此时长后触发上报
    public let monitorDurationMs: Int64
    // 单线程 cooldown 时间（毫秒），默认 10 分钟（600000ms）同一线程在此时间内最多被抓取一次栈
    public let threadCooldownMs: Int64
    // 全局 cooldown 时间（毫秒），默认 3 分钟（180000ms）避免各模块重复抓取，全局在此时间内最多触发一次
    public let globalCooldownMs: Int64
    // 高采样比例阈值（0-1 之间），默认 0.85 表示 85% 当某线程 85% 的采样都>50% CPU 时，判定为持续高占用
    public let highSampleRatioThreshold: Float64
    // 每次采样保留的 TopN 线程数，默认 10 只保留 CPU 使用率最高的 N 个线程参与判定
    public let topNThreads: Int64

    // 默认值常量
    private static let DEFAULT_CPU_THRESHOLD: Float64 = 0.5
    private static let DEFAULT_FOREGROUND_INTERVAL_MS: Int64 = 1000
    private static let DEFAULT_BACKGROUND_INTERVAL_MS: Int64 = 2000
    private static let DEFAULT_MONITOR_DURATION_MS: Int64 = 180000  // 3 分钟
    private static let DEFAULT_THREAD_COOLDOWN_MS: Int64 = 600000   // 10 分钟
    private static let DEFAULT_GLOBAL_COOLDOWN_MS: Int64 = 180000   // 3 分钟
    private static let DEFAULT_HIGH_SAMPLE_RATIO_THRESHOLD: Float64 = 0.85
    private static let DEFAULT_TOP_N_THREADS: Int64 = 10

    public init(
        cpuThreshold!: Float64 = DEFAULT_CPU_THRESHOLD,
        foregroundIntervalMs!: Int64 = DEFAULT_FOREGROUND_INTERVAL_MS,
        backgroundIntervalMs!: Int64 = DEFAULT_BACKGROUND_INTERVAL_MS,
        monitorDurationMs!: Int64 = DEFAULT_MONITOR_DURATION_MS,
        threadCooldownMs!: Int64 = DEFAULT_THREAD_COOLDOWN_MS,
        globalCooldownMs!: Int64 = DEFAULT_GLOBAL_COOLDOWN_MS,
        highSampleRatioThreshold!: Float64 = DEFAULT_HIGH_SAMPLE_RATIO_THRESHOLD,
        topNThreads!: Int64 = DEFAULT_TOP_N_THREADS
    ) {
        // 校验 cpuThreshold: 必须在 [0.0, 1.0] 范围内
        this.cpuThreshold = if (cpuThreshold < 0.0 || cpuThreshold > 1.0) {
            throw Exception("Invalid cpuThreshold: ${cpuThreshold}, expected [0.0, 1.0]")
        } else {
            cpuThreshold
        }

        // 校验 foregroundIntervalMs: 必须在 [0, Int64.Max] 范围内
        this.foregroundIntervalMs = if (foregroundIntervalMs < 0 || foregroundIntervalMs > Int64.Max) {
            throw Exception("Invalid foregroundIntervalMs: ${foregroundIntervalMs}, expected [0, Int64.Max]")
        } else {
            foregroundIntervalMs
        }

        // 校验 backgroundIntervalMs: 必须在 [0, Int64.Max] 范围内
        this.backgroundIntervalMs = if (backgroundIntervalMs < 0 || backgroundIntervalMs > Int64.Max) {
            throw Exception("Invalid backgroundIntervalMs: ${backgroundIntervalMs}, expected [0, Int64.Max]")
        } else {
            backgroundIntervalMs
        }

        // 校验 monitorDurationMs: 必须在 (0, Int64.Max] 范围内
        this.monitorDurationMs = if (monitorDurationMs <= 0 || monitorDurationMs > Int64.Max) {
            throw Exception("Invalid monitorDurationMs: ${monitorDurationMs}, expected (0, Int64.Max]")
        } else {
            monitorDurationMs
        }

        // 校验 threadCooldownMs: 必须在 [0, Int64.Max] 范围内
        this.threadCooldownMs = if (threadCooldownMs < 0 || threadCooldownMs > Int64.Max) {
            throw Exception("Invalid threadCooldownMs: ${threadCooldownMs}, expected [0, Int64.Max]")
        } else {
            threadCooldownMs
        }

        // 校验 globalCooldownMs: 必须在 [0, Int64.Max] 范围内
        this.globalCooldownMs = if (globalCooldownMs < 0 || globalCooldownMs > Int64.Max) {
            throw Exception("Invalid globalCooldownMs: ${globalCooldownMs}, expected [0, Int64.Max]")
        } else {
            globalCooldownMs
        }

        // 校验 highSampleRatioThreshold: 必须在 [0.0, 1.0] 范围内
        this.highSampleRatioThreshold = if (highSampleRatioThreshold < 0.0 || highSampleRatioThreshold > 1.0) {
            throw Exception("Invalid highSampleRatioThreshold: ${highSampleRatioThreshold}, expected [0.0, 1.0]")
        } else {
            highSampleRatioThreshold
        }

        // 校验 topNThreads: 必须在 (0, Int64.Max] 范围内
        this.topNThreads = if (topNThreads <= 0 || topNThreads > Int64.Max) {
            throw Exception("Invalid topNThreads: ${topNThreads}, expected (0, Int64.Max]")
        } else {
            topNThreads
        }
    }

    /**
     * 转换为互操作版本
     */
    public func toInterop(): InteropHighCpuMonitorConfig {
        InteropHighCpuMonitorConfig(
            this.cpuThreshold,
            this.foregroundIntervalMs,
            this.backgroundIntervalMs,
            this.monitorDurationMs,
            this.threadCooldownMs,
            this.globalCooldownMs,
            this.highSampleRatioThreshold,
            this.topNThreads
        )
    }
}

// --- 初始化状态 ---
// 监控是否已初始化（防止重复初始化）
var highCpuMonitorInited: Bool = false
// 当前使用的配置（初始化后保存）
var highCpuConfig: Option<HighCpuMonitorConfig> = None
// 用户上报回调
var reportHighCpuCallback: Option<(info: HighCpuReportInfo) -> Unit> = None
// CPU 使用率获取回调（由 ArkTS 传入，使用 cpu.cj 中定义的 _getCpuUsage）

// --- 应用状态 ---
// 应用是否在前台（true=前台，false=后台）由 ArkTS 侧通知
var isAppForeground: Bool = true

// CPU 使用率获取回调（由 ArkTS 传入，复用 cpu.cj 中的 _getCpuUsage）
// 获取线程 CPU 使用情况回调（JSON 字符串格式，由 ArkTS 传入）
var _getAppThreadCpuUsageJson: () -> String = { => "[]" }

// --- 采样数据 ---
// 线程采样数据：tid -> ThreadStackInfo 记录每个高占用线程的统计信息
var threadSamples: HashMap<Int64, ThreadStackInfo> = HashMap()
// 进程 CPU 采样列表
var processCpuSamples: ArrayList<Float64> = ArrayList()

// --- Cooldown 记录（限流机制） ---
// 线程 cooldown 记录：tid -> 上次抓取时间戳（毫秒）
var threadCooldownMap: HashMap<Int64, Int64> = HashMap()
// 全局 cooldown 记录：上次全局抓取时间戳（毫秒）
var globalLastCaptureTime: Int64 = 0

// --- 监控时间窗口 ---
// 监控开始时间（毫秒）
var monitorStartTime: Int64 = 0
// 监控结束时间（毫秒）
var monitorEndTime: Int64 = 0

// --- 定时器 ---
// 采样定时器控制回调（由 ArkTS 侧传入）
var repeatHighCpuSampleCallback: Option<(() -> Unit) -> Unit> = None
// 上报定时器控制回调（由 ArkTS 侧传入）
var repeatHighCpuReportCallback: Option<(() -> Unit) -> Unit> = None
// 停止采样定时器回调（由 ArkTS 侧传入）
var clearHighCpuSampleCallback: Option<() -> Unit> = None
// 停止上报定时器回调（由 ArkTS 侧传入）
var clearHighCpuReportCallback: Option<() -> Unit> = None

// --- 抓栈锁 ---
// 抓栈锁（true=正在抓栈，false=空闲） 防止重复触发抓栈，避免性能问题
var isCapturingStack: Bool = false

// --- 采样统计 ---
// 总采样次数 从监控开始至今的采样总次数
var totalSampleCount: Int64 = 0
// 高 CPU 采样次数（CPU>50% 的次数） 用于计算高采样比例，判定是否触发抓栈
var highCpuSampleCount: Int64 = 0

// --- 后台监控状态 ---
// 监控是否已初始化（防止重复初始化）
var backgroundCpuConfig: Option<BackgroundCpuMonitorConfig> = None
var backgroundCpuCallback: Option<(info: BackgroundCpuReportInfo) -> Unit> = None
var backgroundCpuMonitorInited: Bool = false

var backgroundStartTime: Int64 = 0
var isInBackground: Bool = false

// 定时器控制回调 (由 ArkTS 传入)
var repeatBackgroundSampleCallback: Option<(() -> Unit) -> Unit> = None
var clearBackgroundSampleCallback: Option<() -> Unit> = None

// --- 采样数据 ---
// 滑动窗口采样数据
var windowSamplesList: ArrayList<WindowSample> = ArrayList()
// 进程 CPU 采样列表
var backgroundCpuSamples: ArrayList<Float64> = ArrayList()
// 线程采样数据：tid -> ThreadStackInfo
var backgroundThreadSamples: HashMap<Int64, ThreadStackInfo> = HashMap()

// --- 上报状态 ---
// 各级别是否已上报
var warnReported: Bool = false
var errorReported: Bool = false
var fatalReported: Bool = false
// 抓栈锁（防止重复抓栈）
var isBackgroundCapturingStack: Bool = false

/**
 * 获取当前时间戳（毫秒）
 *
 * @return 当前时间的毫秒时间戳
 */
private func getCurrentTimeMillis(): Int64 {
    DateTime.now().toUnixTimeStamp().toMilliseconds()
}

/**
 * 获取线程名称
 *
 * 通过读取 /proc/self/task/{tid}/comm 文件获取线程名
 *
 * @param tid 线程 ID
 * @return 线程名称，获取失败时返回 "Thread-{tid}"
 */
private func getThreadName(tid: Int64): String {
    try {
        let commPath = Path("/proc/self/task/${tid}/comm")
        if (exists(commPath)) {
            let content = File.readFrom(commPath)
            unsafe {
                let name = String.fromUtf8Unchecked(content).trimAscii()
                if (name.isEmpty()) {
                    return "Thread-${tid}"
                }
                return name
            }
        }
    } catch (e: Exception) {
        AppLog.warn("hm-metricx-cj: getThreadName failed for tid ${tid}: " + e.toString())
    }
    "Thread-${tid}"
}

/**
 * 检查是否可以对指定线程进行采样（检查线程 cooldown）
 *
 * 实现需求：同一 tid 10 分钟最多抓一次
 *
 * @param tid 线程 ID
 * @param currentTime 当前时间戳（毫秒）
 * @return true=可以采样，false=cooldown 中
 */
private func canSampleThread(tid: Int64, currentTime: Int64): Bool {
    if (threadCooldownMap.contains(tid)) {
        let lastCaptureTime = threadCooldownMap[tid]
        if (let Some(config) <- highCpuConfig) {
            if (currentTime - lastCaptureTime < config.threadCooldownMs) {
                return false
            }
        }
    }
    true
}

/**
 * 检查是否可以进行全局采样（检查全局 cooldown）
 *
 * 实现需求：全局 3 分钟最多抓一次，避免各模块重复抓取
 *
 * @param currentTime 当前时间戳（毫秒）
 * @return true=可以采样，false=cooldown 中
 */
private func canSampleGlobal(currentTime: Int64): Bool {
    if (globalLastCaptureTime == 0) {
        return true
    }
    if (let Some(config) <- highCpuConfig) {
        return currentTime - globalLastCaptureTime >= config.globalCooldownMs
    }
    true
}

/**
 * 更新线程 cooldown 时间
 *
 * 记录线程上次被抓取的时间，用于后续 cooldown 检查
 *
 * @param tid 线程 ID
 * @param currentTime 当前时间戳（毫秒）
 */
private func updateThreadCooldown(tid: Int64, currentTime: Int64): Unit {
    threadCooldownMap.add(tid, currentTime)
}

/**
 * 获取当前采样间隔（根据前后台状态）
 *
 * 实现需求：前台默认 1s，后台默认 2s
 *
 * @return 采样间隔（毫秒）
 */
private func getCurrentSampleInterval(): Int64 {
    if (let Some(config) <- highCpuConfig) {
        if (isAppForeground) {
            return config.foregroundIntervalMs
        } else {
            return config.backgroundIntervalMs
        }
    }
    1000  // 默认 1 秒
}

/**
 * 执行 CPU 采样
 *
 * 核心采样逻辑，实现以下功能：
 * 1. 固定时间间隔获取当前进程 CPU 使用率
 * 2. 获取所有线程的 CPU 使用情况（使用 getAppThreadCpuUsage）
 * 3. 按 CPU 使用率降序排序，保留 TopN 线程
 * 4. 对超过阈值的线程进行采样（检查 cooldown）
 * 5. 记录线程栈和模块名
 *
 * 限流规则：
 * - 全局 cooldown 检查（3 分钟最多一次）
 * - 抓栈锁检查（避免重复触发）
 * - 线程 cooldown 检查（10 分钟最多一次）
 */
private func doHighCpuSample(): Unit {
    let currentTime = getCurrentTimeMillis()

    // 【调试】检查全局 cooldown
    if (!canSampleGlobal(currentTime)) {
        AppLog.info("hm-metricx-cj: [DEBUG] Sampling skipped due to global cooldown")
        return
    }

    // 检查是否正在抓栈
    if (isCapturingStack) {
        AppLog.info("hm-metricx-cj: Sampling skipped, stack capture in progress")
        return
    }

    // 获取当前进程 CPU 使用率（使用 ArkTS 传入的回调）
    let processCpuUsage = _getCpuUsage()
    processCpuSamples.add(processCpuUsage)
    totalSampleCount++

    // 统计高 CPU 采样次数（使用动态阈值）
    if (let Some(config) <- highCpuConfig) {
        if (processCpuUsage >= config.cpuThreshold) {
            highCpuSampleCount++
        }
    } else {
        if (processCpuUsage > 0.5) {
            highCpuSampleCount++
        }
    }

    // 获取所有线程的 CPU 使用情况（使用 ArkTS 传入的 JSON 回调）
    let threadCpuUsageJson = _getAppThreadCpuUsageJson()
    let threadCpuUsageArray = parseThreadCpuUsage(threadCpuUsageJson)
    if (threadCpuUsageArray.isEmpty()) {
        AppLog.warn("hm-metricx-cj: parseThreadCpuUsage returned empty array")
        return
    }

    // 收集所有线程的 CPU 使用情况
    var threadCpuList = ArrayList<(Int64, String, Float64)>()
    for (threadUsage in threadCpuUsageArray) {
        let tid = Int64(threadUsage.threadId)
        let cpuUsage = Float64(threadUsage.cpuUsage)
        let threadName = getThreadName(tid)
        threadCpuList.add((tid, threadName, cpuUsage))
    }

    // 按 CPU 使用率降序排序，保留 TopN
    // 使用 std.sort 的 sort 函数，传入 lessThan 比较函数
    sort<(Int64, String, Float64)>(
        threadCpuList,
        lessThan: { a, b => a[2] > b[2] },
        stable: false,
        descending: false
    )

    // 【调试】打印排序后的 TopN 线程
    if (let Some(config) <- highCpuConfig) {
        let topN = min(threadCpuList.size, config.topNThreads)
        AppLog.info("hm-metricx-cj: [DEBUG] Processing top ${topN} threads (threshold=${config.cpuThreshold}):")
        for (i in 0..topN) {
            let item = threadCpuList[i]
            let tid = item[0]
            let threadName = item[1]
            let cpuUsage = item[2]
            AppLog.info("hm-metricx-cj: [DEBUG]   #${i} TID=${tid}, name=${threadName}, cpu=${cpuUsage * 100.0}%")

            // 检查是否超过阈值
            if (cpuUsage >= config.cpuThreshold) {
                // 创建或更新线程采样信息（总是更新，不受 cooldown 限制）
                if (!threadSamples.contains(tid)) {
                    let threadInfo = ThreadStackInfo()
                    threadInfo.tid = tid
                    threadInfo.threadName = threadName
                    threadInfo.firstDetectedTime = currentTime
                    if (let Some(config) <- highCpuConfig) {
                        threadInfo.computeAvg(cpuUsage, threshold: config.cpuThreshold)
                    } else {
                        threadInfo.computeAvg(cpuUsage)
                    }
                    threadSamples.add(tid, threadInfo)

                    AppLog.info("hm-metricx-cj: Detected high CPU thread: tid=${tid}, name=${threadName}, cpu=${cpuUsage}")
                } else {
                    let threadInfo = threadSamples[tid]
                    if (let Some(config) <- highCpuConfig) {
                        threadInfo.computeAvg(cpuUsage, threshold: config.cpuThreshold)
                    } else {
                        threadInfo.computeAvg(cpuUsage)
                    }
                }

                // 检查线程 cooldown（只用于是否抓栈，不影响采样统计）
                if (canSampleThread(tid, currentTime)) {
                    // 更新线程 cooldown
                    updateThreadCooldown(tid, currentTime)

                    AppLog.info("hm-metricx-cj: Thread cooldown updated: tid=${tid}")
                }
            }
        }
    }

    // 更新全局 cooldown 时间
    globalLastCaptureTime = currentTime
}

/**
 * 判断是否满足抓栈条件
 *
 * 实现需求：当 CPU 利用率>0.5 且至少有一定百分比 (0.85/0.9) 的采样次数都>0.5 时，触发抓栈
 *
 * 判定条件：
 * - 总采样次数 > 0
 * - 高 CPU 采样比例 >= highSampleRatioThreshold（默认 0.85）
 *
 * @return true=满足抓栈条件，false=不满足
 */
private func shouldCaptureStack(): Bool {
    if (totalSampleCount == 0) {
        return false
    }

    // 检查高 CPU 采样比例
    let highRatio = Float64(highCpuSampleCount) / Float64(totalSampleCount)

    if (let Some(config) <- highCpuConfig) {
        // 条件 1: 当前 CPU 利用率 > 0.5
        // 条件 2: 高采样比例 >= 阈值（0.85 或 0.9）
        if (highRatio >= config.highSampleRatioThreshold) {
            AppLog.info("hm-metricx-cj: Should capture stack: highRatio=${highRatio}, threshold=${config.highSampleRatioThreshold}")
            return true
        }
    }
    return false
}

/**
 * 执行抓栈操作
 *
 * 实现需求：对高 CPU 占用的线程抓取调用栈，用于定位哪个模块持续占用 CPU
 *
 * 核心逻辑：
 * 1. 检查抓栈锁（如果抓栈正在进行，忽略新的触发）
 * 2. 检查全局 cooldown（3 分钟最多一次）
 * 3. 获取所有线程的 CPU 使用情况
 * 4. 对超过阈值的线程抓取栈信息
 * 5. 提取模块名并记录
 * 6. 更新线程 cooldown（10 分钟最多抓一次）
 *
 * 安全保护：
 * - 使用 try-finally 确保抓栈锁正确释放
 * - 异常捕获避免影响主流程
 */
private func captureStackForHighCpuThreads(): Unit {
    if (isCapturingStack) {
        AppLog.info("hm-metricx-cj: Stack capture already in progress, ignoring new trigger")
        return
    }

    let currentTime = getCurrentTimeMillis()

    // 检查全局 cooldown
    if (!canSampleGlobal(currentTime)) {
        AppLog.info("hm-metricx-cj: Stack capture skipped due to global cooldown")
        return
    }

    isCapturingStack = true

    try {
        // 获取所有线程的 CPU 使用情况（使用 ArkTS 传入的 JSON 回调）
        let threadCpuUsageJson = _getAppThreadCpuUsageJson()
        let threadCpuUsageArray = parseThreadCpuUsage(threadCpuUsageJson)
        if (threadCpuUsageArray.isEmpty()) {
            AppLog.warn("hm-metricx-cj: parseThreadCpuUsage returned empty array during stack capture")
            return
        }

        for (threadUsage in threadCpuUsageArray) {
            let tid = Int64(threadUsage.threadId)
            let cpuUsage = Float64(threadUsage.cpuUsage)

            // 检查是否超过阈值
            if (let Some(config) <- highCpuConfig) {
                if (cpuUsage >= config.cpuThreshold) {
                    // 检查线程 cooldown
                    if (canSampleThread(tid, currentTime)) {
                        // 获取线程详细信息
                        let threadName = getThreadName(tid)

                        // 创建或更新线程采样信息
                        if (!threadSamples.contains(tid)) {
                            let threadInfo = ThreadStackInfo()
                            threadInfo.tid = tid
                            threadInfo.threadName = threadName
                            threadInfo.firstDetectedTime = currentTime
                            if (let Some(config) <- highCpuConfig) {
                                threadInfo.computeAvg(cpuUsage, threshold: config.cpuThreshold)
                            } else {
                                threadInfo.computeAvg(cpuUsage)
                            }
                            threadSamples.add(tid, threadInfo)
                        } else {
                            let threadInfo = threadSamples[tid]
                            if (let Some(config) <- highCpuConfig) {
                                threadInfo.computeAvg(cpuUsage, threshold: config.cpuThreshold)
                            } else {
                                threadInfo.computeAvg(cpuUsage)
                            }
                        }

                        // 更新线程 cooldown
                        updateThreadCooldown(tid, currentTime)

                        AppLog.info("hm-metricx-cj: Stack captured for tid=${tid}, name=${threadName}")
                    }
                }
            }
        }
    } catch (e: Exception) {
        AppLog.warn("hm-metricx-cj: Exception during stack capture: " + e.toString())
    } finally {
        isCapturingStack = false
    }
}

/**
 * 执行高 CPU 占用上报
 *
 * 实现需求：3 分钟上报一次，包含以下信息：
 * - 3 分钟内进程平均 CPU 使用率
 * - 持续高占用线程的栈信息和模块名
 *
 * 上报条件：
 * - 监控时长达到 3 分钟（monitorDurationMs）
 * - 线程平均 CPU >= cpuThreshold（默认 0.5）
 * - 线程高采样比例 >= highSampleRatioThreshold（默认 0.85）
 *
 * 上报前触发抓栈：
 * - 如果满足 shouldCaptureStack 条件，先执行抓栈
 */
private func doHighCpuReport(): Unit {
    let currentTime = getCurrentTimeMillis()

    // 计算从监控开始的总时长（毫秒）
    let totalElapsedMs = currentTime - monitorStartTime

    // 计算当前周期的时长（用于上报显示，单位：毫秒）
    // 使用 config.monitorDurationMs 作为固定值
    let currentCycleMs: Int64

    if (let Some(config) <- highCpuConfig) {
        // 当前周期时长 = 总时长 % 监控周期
        let remainder = totalElapsedMs % config.monitorDurationMs
        // 如果余数接近 0，说明是完整周期，显示完整周期时长
        if (remainder < config.monitorDurationMs / 2) {
            currentCycleMs = config.monitorDurationMs
        } else {
            currentCycleMs = remainder
        }

        // 检查是否达到监控时长
        if (totalElapsedMs < config.monitorDurationMs) {
            AppLog.info("hm-metricx-cj: Report skipped, duration=${totalElapsedMs}ms / ${config.monitorDurationMs}ms")
            return
        }
    } else {
        currentCycleMs = totalElapsedMs
    }

    // 判断是否满足抓栈条件
    if (shouldCaptureStack()) {
        captureStackForHighCpuThreads()
    }

    // 计算进程平均 CPU 使用率和最大 CPU 使用率
    var avgProcessCpu: Float64 = 0.0
    var maxProcessCpu: Float64 = 0.0
    if (!processCpuSamples.isEmpty()) {
        var sum: Float64 = 0.0
        for (sample in processCpuSamples) {
            sum += sample
            if (sample > maxProcessCpu) {
                maxProcessCpu = sample
            }
        }
        avgProcessCpu = sum / Float64(processCpuSamples.size)
    }

    // 筛选出平均 CPU 使用率超过阈值且高采样比例达标的线程
    let highCpuThreads = ArrayList<ThreadStackInfo>()
    if (let Some(config) <- highCpuConfig) {
        for (entry in threadSamples) {
            let threadInfo = entry[1]
            // 条件：平均 CPU > 阈值 且 高采样比例 >= 阈值
            if (threadInfo.avgCpuUsage >= config.cpuThreshold &&
                threadInfo.getHighSampleRatio() >= config.highSampleRatioThreshold) {
                highCpuThreads.add(threadInfo)
                AppLog.info("hm-metricx-cj: Thread qualified for report: tid=${threadInfo.tid}, avgCpu=${threadInfo.avgCpuUsage}, ratio=${threadInfo.getHighSampleRatio()}")
            }
        }
    }

    // 只有存在高占用线程时才上报
    if (!highCpuThreads.isEmpty()) {
        let reportInfo = HighCpuReportInfo()
        reportInfo.timestamp = currentTime
        reportInfo.pid = getpid()
        reportInfo.processName = getpid().toString()
        reportInfo.pageName = currentPageName
        reportInfo.avgProcessCpu = avgProcessCpu
        reportInfo.maxProcessCpu = maxProcessCpu
        reportInfo.monitorDuration = currentCycleMs
        reportInfo.highCpuThreads = highCpuThreads

        if (let Some(callback) <- reportHighCpuCallback) {
            callback(reportInfo)
            AppLog.info("hm-metricx-cj: High CPU report triggered with ${highCpuThreads.size} threads")
        }
    } else {
        AppLog.info("hm-metricx-cj: No high CPU threads qualified for report")
    }

    // 重置采样数据（但保持 cooldown 记录）
    resetSamplingData()
}

/**
 * 重置采样数据
 *
 * 在每次上报完成后调用，清空采样数据以便下一轮监控
 * 注意：不清空 cooldown 记录，保持限流效果
 * 注意：不重置 monitorStartTime，保持与上报定时器同步
 */
private func resetSamplingData(): Unit {
    AppLog.info("hm-metricx-cj: [DEBUG] Resetting sampling data. Before reset: totalSampleCount=${totalSampleCount}, threadSamples.size=${threadSamples.size}, monitorStartTime=${monitorStartTime}")
    threadSamples.clear()
    processCpuSamples.clear()
    totalSampleCount = 0
    highCpuSampleCount = 0
    AppLog.info("hm-metricx-cj: [DEBUG] Sampling data reset. After reset: totalSampleCount=${totalSampleCount}, threadSamples.size=${threadSamples.size}")
}

/**
 * 开始高 CPU 占用监控
 *
 * 通过 ArkTS 传入的回调函数启动两个定时器：
 * 1. 采样定时器：按 foregroundIntervalMs 间隔执行 CPU 采样
 * 2. 上报定时器：按 monitorDurationMs 间隔执行上报
 *
 * 采样间隔会根据前后台状态动态调整（通过 updateSampleInterval）
 */
private func startHighCpuMonitor(): Unit {
    if (let Some(config) <- highCpuConfig) {
        monitorStartTime = getCurrentTimeMillis()
        monitorEndTime = monitorStartTime + config.monitorDurationMs

        // 通过 ArkTS 传入的回调启动采样定时器（使用前台间隔）
        if (let Some(callback) <- repeatHighCpuSampleCallback) {
            callback({ => doHighCpuSample() })
        }

        // 通过 ArkTS 传入的回调启动上报定时器
        if (let Some(callback) <- repeatHighCpuReportCallback) {
            callback({ => doHighCpuReport() })
        }

        AppLog.info("hm-metricx-cj: High CPU monitoring started, foregroundInterval=${config.foregroundIntervalMs}ms, backgroundInterval=${config.backgroundIntervalMs}ms, duration=${config.monitorDurationMs}ms")
    }
}

/**
 * 停止高 CPU 占用监控
 *
 * 通过 ArkTS 传入的回调清除采样定时器和上报定时器
 */
private func stopHighCpuMonitor(): Unit {
    // 通过 ArkTS 传入的回调清除定时器
    if (let Some(callback) <- clearHighCpuSampleCallback) {
        callback()
    }
    if (let Some(callback) <- clearHighCpuReportCallback) {
        callback()
    }

    AppLog.info("hm-metricx-cj: High CPU monitoring stopped")
}

/**
 * 更新采样间隔（根据前后台状态）
 *
 * 实现需求：前台默认 1s，后台默认 2s
 *
 * 当应用从前台切换到后台或从后台切换到前台时调用，
 * 动态调整采样间隔以平衡监控精度和性能开销
 *
 * 注意：在互操作版本中，定时器由 ArkTS 侧控制，
 * 此函数仅记录日志，实际的间隔更新由 ArkTS 侧在调用 repeatHighCpuSample 时传入新间隔
 */
private func updateSampleInterval(): Unit {
    if (!highCpuMonitorInited) {
        return
    }

    let newInterval = getCurrentSampleInterval()
    let state = if (isAppForeground) { "foreground" } else { "background" }
    AppLog.info("hm-metricx-cj: App entered ${state}, sample interval should be ${newInterval}ms")

    // 注意：在互操作版本中，定时器的重启由 ArkTS 侧控制
    // 这里不再直接调用 setInterval/clearInterval
}

/**
 * 初始化高 CPU 占用监控（内部版本）
 *
 * 启动高 CPU 占用监控功能，可配置采样间隔（毫秒）、上报周期（默认 180000 毫秒/3 分钟）
 * 自动抓取高占用线程的调用栈和模块名，帮助定位性能问题
 *
 * 功能特性：
 * - 固定时间间隔（前台默认 1s，后台默认 2s，可配置）获取 CPU 使用率
 * - 每次采样保留 Top10 高 CPU 线程参与判定
 * - 当 CPU 利用率>0.5 且至少 85%（可配置）的采样次数都>0.5 时，触发抓栈
 * - 同一 tid 10 分钟（可配置）最多抓一次
 * - 全局 3 分钟（可配置）最多抓一次
 * - 抓栈进行中忽略新触发
 *
 * @param getCpuUsage 获取 CPU 使用率的回调（由 ArkTS 传入）
 * @param getAppThreadCpuUsageJson 获取线程 CPU 使用率 JSON 的回调（由 ArkTS 传入）
 * @param repeatHighCpuSample 重复采样回调（由 ArkTS 传入，用于启动采样定时器）
 * @param repeatHighCpuReport 重复上报回调（由 ArkTS 传入，用于启动上报定时器）
 * @param reportHighCpuInfo 高 CPU 占用上报回调（3 分钟一次或手动触发）
 *
 */
public func initHighCpuMonitorHandlerInternal(
    getCpuUsage: () -> Float64,
    getAppThreadCpuUsageJson: () -> String,
    repeatHighCpuSample: (() -> Unit) -> Unit,
    repeatHighCpuReport: (() -> Unit) -> Unit,
    reportHighCpuInfo: (info: HighCpuReportInfo) -> Unit
): Unit {
    if (high_cpu_init_flag) {
    	return
    }
    high_cpu_init_flag = true
    if (highCpuMonitorInited) {
        AppLog.warn("hm-metricx-cj: High CPU monitor already initialized")
        return
    }

    // 保存 CPU 获取回调
    _getCpuUsage = getCpuUsage
    
    // 保存线程 CPU 获取回调
    _getAppThreadCpuUsageJson = getAppThreadCpuUsageJson

    // 保存定时器控制回调
    repeatHighCpuSampleCallback = Some(repeatHighCpuSample)
    repeatHighCpuReportCallback = Some(repeatHighCpuReport)
    clearHighCpuSampleCallback = Some({ => }) // 默认空实现，由 ArkTS 侧控制
    clearHighCpuReportCallback = Some({ => }) // 默认空实现，由 ArkTS 侧控制

    // 保存上报回调
    reportHighCpuCallback = Some(reportHighCpuInfo)
    highCpuMonitorInited = true

    AppLog.info("hm-metricx-cj: High CPU monitor handler initialized")
}

/**
 * 应用进入前台时调用（由 ArkTS 侧调用）
 *
 * 同时处理高 CPU 监控和后台监控的前台切换逻辑
 */
public func onAppForegroundInternal(): Unit {
    // 高 CPU 监控逻辑
    isAppForeground = true
    updateSampleInterval()
    
    // 后台监控逻辑
    if (isInBackground) {
        isInBackground = false
        stopBackgroundMonitorInternal()
        warnReported = false
        errorReported = false
        fatalReported = false
        AppLog.info("hm-metricx-cj: App entered foreground, background monitoring stopped")
    }
}

/**
 * 应用进入后台时调用（由 ArkTS 侧调用）
 *
 * 同时处理高 CPU 监控和后台监控的后台切换逻辑
 */
public func onAppBackgroundInternal(): Unit {
    // 高 CPU 监控逻辑
    isAppForeground = false
    updateSampleInterval()
    
    // 后台监控逻辑
    if (!isInBackground) {
        isInBackground = true
        backgroundStartTime = getCurrentTimeMillis()
        resetBackgroundMonitorData()
        startBackgroundMonitorInternal()
        AppLog.info("hm-metricx-cj: App entered background, background monitoring started")
    }
}

/**
 * 开始高 CPU 监控（内部版本）
 *
 * 由 ArkTS 侧在调用 initHighCpuMonitorHandler 后调用此方法启动监控
 *
 * @param config 高 CPU 监控配置
 */
public func startHighCpuMonitorInternal(config: InteropHighCpuMonitorConfig): Unit {
    if (!highCpuMonitorInited) {
        AppLog.warn("hm-metricx-cj: High CPU monitor not initialized, call initHighCpuMonitorHandlerInternal first")
        return
    }

    // 转换配置并保存
    let cjConfig = HighCpuMonitorConfig(
        cpuThreshold: config.cpuThreshold,
        foregroundIntervalMs: config.foregroundIntervalMs,
        backgroundIntervalMs: config.backgroundIntervalMs,
        monitorDurationMs: config.monitorDurationMs,
        threadCooldownMs: config.threadCooldownMs,
        globalCooldownMs: config.globalCooldownMs,
        highSampleRatioThreshold: config.highSampleRatioThreshold,
        topNThreads: config.topNThreads
    )
    highCpuConfig = Some(cjConfig)

    // 启动监控
    startHighCpuMonitor()

    AppLog.info("hm-metricx-cj: High CPU monitoring started with config: cpuThreshold=${config.cpuThreshold}, " +
                "foregroundInterval=${config.foregroundIntervalMs}ms, backgroundInterval=${config.backgroundIntervalMs}ms, " +
                "monitorDuration=${config.monitorDurationMs}ms, highSampleRatioThreshold=${config.highSampleRatioThreshold}, " +
                "topNThreads=${config.topNThreads}")
}

/**
 * 停止高 CPU 监控（内部版本）
 *
 * 由 ArkTS 侧在销毁时调用此方法停止监控
 */
public func stopHighCpuMonitorInternal(): Unit {
    if (!highCpuMonitorInited) {
        return
    }

    stopHighCpuMonitor()

    highCpuMonitorInited = false
    highCpuConfig = None
    reportHighCpuCallback = None
    resetSamplingData()
    threadCooldownMap.clear()
    globalLastCaptureTime = 0
    isCapturingStack = false
    cpu_init_flag = false
    high_cpu_init_flag = false
    sleep(Duration.millisecond * 0.1)
    AppLog.info("hm-metricx-cj: High CPU monitor destroyed")
}

/**
 * 手动触发高 CPU 占用上报（内部版本）
 *
 * 立即触发一次高 CPU 占用上报，不等待 3 分钟周期结束
 *
 * 使用场景：
 * - 用户反馈卡顿时
 * - 检测到 ANR 时
 * - 调试阶段需要立即查看当前 CPU 状态
 * - 其他需要紧急获取 CPU 信息的场景
 *
 * 注意：
 * - 如果监控未启动，调用此方法无效
 * - 频繁调用可能影响性能，建议仅在必要时使用
 */
public func triggerHighCpuReportInternal(): Unit {
    if (highCpuMonitorInited) {
        doHighCpuReport()
    }
}

/**
 * 检查高 CPU 监控是否正在运行（内部版本）
 *
 * 用于查询当前监控状态
 *
 * @return true=监控正在运行，false=监控未启动或已停止
 *
 */
public func isHighCpuMonitoringActiveInternal(): Bool {
    highCpuMonitorInited
}

/// 获取当前配置
public func getHighCpuConfig(): Option<HighCpuMonitorConfig> {
    highCpuConfig
}

/// 获取当前应用状态（前台/后台）
public func isAppInForeground(): Bool {
    isAppForeground
}

/// 获取当前采样统计信息
public func getSamplingStats(): (totalSamples: Int64, highCpuSamples: Int64, highRatio: Float64) {
    let ratio = if (totalSampleCount > 0) {
        Float64(highCpuSampleCount) / Float64(totalSampleCount)
    } else {
        0.0
    }
    (totalSampleCount, highCpuSampleCount, ratio)
}

// ==================== @Interop 互操作类定义 ====================

/**
 * 高 CPU 监控配置
 * 用于 ArkTS 与仓颉之间的数据传递
 */
@Interop[ArkTS]
public class InteropHighCpuMonitorConfig {
    public let cpuThreshold: Float64
    public let foregroundIntervalMs: Int64
    public let backgroundIntervalMs: Int64
    public let monitorDurationMs: Int64
    public let threadCooldownMs: Int64
    public let globalCooldownMs: Int64
    public let highSampleRatioThreshold: Float64
    public let topNThreads: Int64

    public init(
        cpuThreshold: Float64,
        foregroundIntervalMs: Int64,
        backgroundIntervalMs: Int64,
        monitorDurationMs: Int64,
        threadCooldownMs: Int64,
        globalCooldownMs: Int64,
        highSampleRatioThreshold: Float64,
        topNThreads: Int64
    ) {
        this.cpuThreshold = cpuThreshold
        this.foregroundIntervalMs = foregroundIntervalMs
        this.backgroundIntervalMs = backgroundIntervalMs
        this.monitorDurationMs = monitorDurationMs
        this.threadCooldownMs = threadCooldownMs
        this.globalCooldownMs = globalCooldownMs
        this.highSampleRatioThreshold = highSampleRatioThreshold
        this.topNThreads = topNThreads
    }
}

/**
 * 解析线程 CPU 使用情况 JSON 字符串
 * JSON 格式：[{"threadId":123,"cpuUsage":0.5}, ...]
 */
private func parseThreadCpuUsage(jsonStr: String): ArrayList<ThreadCpuUsageInfo> {
    let result = ArrayList<ThreadCpuUsageInfo>()
    var pos: Int64 = 0
    
    AppLog.info("hm-metricx-cj: parseThreadCpuUsage received: " + jsonStr)
    
    while (pos < jsonStr.size) {
        let tidKey = "\"threadId\":"
        let tidKeyIdx = jsonStr[pos..].indexOf(tidKey)
        
        // 找不到 "threadId" 就退出循环
        match (tidKeyIdx) {
            case Some(offset) =>
                if (offset == -1) {
                    break
                }
            case None => break
        }
        
        let tidStart = pos + tidKeyIdx.getOrThrow() + tidKey.size
        let tidRest = jsonStr[tidStart..]
        var tidEnd: Int64 = 0
        while (tidEnd < tidRest.size && tidRest[tidEnd] != b',' && tidRest[tidEnd] != b'}') { 
            tidEnd++ 
        }
        let threadId = jsonStr[tidStart..tidStart+tidEnd].trimAscii()
        
        let cpuKey = "\"cpuUsage\":"
        let cpuKeyIdx = jsonStr[tidStart..].indexOf(cpuKey)
        
        // 找不到 "cpuUsage" 就退出循环
        match (cpuKeyIdx) {
            case Some(offset) =>
                if (offset == -1) {
                    break
                }
            case None => break
        }
        
        let cpuStart = tidStart + cpuKeyIdx.getOrThrow() + cpuKey.size
        let cpuRest = jsonStr[cpuStart..]
        var cpuEnd: Int64 = 0
        while (cpuEnd < cpuRest.size && cpuRest[cpuEnd] != b',' && cpuRest[cpuEnd] != b'}') { 
            cpuEnd++ 
        }
        let cpuUsage = jsonStr[cpuStart..cpuStart+cpuEnd].trimAscii()
        
        // 安全解析，避免解析失败崩溃
        try {
            let tidValue = Int32.parse(threadId)
            let cpuValue = Float64.parse(cpuUsage)
            result.add(ThreadCpuUsageInfo(tidValue, cpuValue))
        } catch (e: Exception) {
            AppLog.warn("hm-metricx-cj: parseThreadCpuUsage failed to parse: threadId=" + threadId + ", cpuUsage=" + cpuUsage + ", error=" + e.toString())
        }
        
        pos = cpuStart + cpuEnd + 1
    }
    
    AppLog.info("hm-metricx-cj: parseThreadCpuUsage parsed " + result.size.toString() + " threads")
    result
}

// ==================== 后台活动超长率监控 ====================

// 后台 CPU 异常级别
public enum BackgroundCpuLevel {
    WARN |    // 警告级别（超过最小异常时长）
    ERROR |   // 错误级别（超过 error_time）
    FATAL    // 致命级别（超过 fatal_time）

    public func toString(): String {
        match (this) {
            case WARN => "WARN"
            case ERROR => "ERROR"
            case FATAL => "FATAL"
        }
    }
}

// 滑动窗口采样数据
public class WindowSample {
    private var timestampValue: Int64 = 0
    private var cpuUsageValue: Float64 = 0.0
    private var durationValue: Int64 = 0

    public mut prop timestamp: Int64 {
        get() { timestampValue }
        set(value) { timestampValue = value }
    }
    public mut prop cpuUsage: Float64 {
        get() { cpuUsageValue }
        set(value) { cpuUsageValue = value }
    }
    public mut prop duration: Int64 {
        get() { durationValue }
        set(value) { durationValue = value }
    }

    public func toJson(): String {
        let sb = StringBuilder()
        sb.append("{\"timestamp\":")
        sb.append(this.timestampValue.toString())
        sb.append(",\"cpuUsage\":")
        sb.append(this.cpuUsageValue.toString())
        sb.append(",\"duration\":")
        sb.append(this.durationValue.toString())
        sb.append("}")
        sb.toString()
    }
}

// 后台 CPU 异常上报信息
public class BackgroundCpuReportInfo {
    private var timestampValue: Int64 = 0
    private var pidValue: Int32 = 0
    private var processNameValue: String = ""
    private var levelValue: BackgroundCpuLevel = BackgroundCpuLevel.WARN
    private var backgroundDurationValue: Int64 = 0
    private var avgCpuUsageValue: Float64 = 0.0
    private var maxCpuUsageValue: Float64 = 0.0
    private var windowSamplesValue: ArrayList<WindowSample> = ArrayList()
    private var highCpuThreadsValue: ArrayList<ThreadStackInfo> = ArrayList()

    public mut prop timestamp: Int64 { get() { timestampValue } set(value) { timestampValue = value } }
    public mut prop pid: Int32 { get() { pidValue } set(value) { pidValue = value } }
    public mut prop processName: String { get() { processNameValue } set(value) { processNameValue = value } }
    public mut prop level: BackgroundCpuLevel { get() { levelValue } set(value) { levelValue = value } }
    public mut prop backgroundDuration: Int64 { get() { backgroundDurationValue } set(value) { backgroundDurationValue = value } }
    public mut prop avgCpuUsage: Float64 { get() { avgCpuUsageValue } set(value) { avgCpuUsageValue = value } }
    public mut prop maxCpuUsage: Float64 { get() { maxCpuUsageValue } set(value) { maxCpuUsageValue = value } }
    public mut prop windowSamples: ArrayList<WindowSample> { get() { windowSamplesValue } set(value) { windowSamplesValue = value } }
    public mut prop highCpuThreads: ArrayList<ThreadStackInfo> { get() { highCpuThreadsValue } set(value) { highCpuThreadsValue = value } }

    public func toJson(): String {
        let sb = StringBuilder()
        sb.append("{\"timestamp\":")
        sb.append(this.timestampValue.toString())
        sb.append(",\"pid\":")
        sb.append(this.pidValue.toString())
        sb.append(",\"processName\":\"")
        sb.append(this.processNameValue)
        sb.append("\",\"level\":\"")
        sb.append(this.levelValue.toString())
        sb.append("\",\"backgroundDuration\":")
        sb.append(this.backgroundDurationValue.toString())
        sb.append(",\"avgCpuUsage\":")
        sb.append(this.avgCpuUsageValue.toString())
        sb.append(",\"maxCpuUsage\":")
        sb.append(this.maxCpuUsageValue.toString())
        sb.append(",\"windowSamples\":[")
        var first = true
        for (sample in this.windowSamplesValue) {
            if (!first) { sb.append(",") }
            sb.append(sample.toJson())
            first = false
        }
        sb.append("],\"highCpuThreads\":[")
        first = true
        for (thread in this.highCpuThreadsValue) {
            if (!first) { sb.append(",") }
            sb.append(thread.toJson())
            first = false
        }
        sb.append("]}")
        sb.toString()
    }
}

/**
 * 后台活动超长率监控配置
 */
public class BackgroundCpuMonitorConfig {
    // CPU 利用率阈值（0-1 之间），超过此值视为异常
    public let cpuThreshold: Float64
    // 最小异常时长（毫秒），超过此时长才触发 warn 级别上报
    public let warnDurationMs: Int64
    // error 级别时长（毫秒），超过此时长触发 error 级别上报
    public let errorDurationMs: Int64
    // fatal 级别时长（毫秒），超过此时长触发 fatal 级别上报
    public let fatalDurationMs: Int64
    // 采样间隔（毫秒）
    public let sampleIntervalMs: Int64
    // 滑动窗口大小（毫秒）
    public let windowSizeMs: Int64

    // 默认值常量
    private static let DEFAULT_CPU_THRESHOLD: Float64 = 0.5
    private static let DEFAULT_WARN_DURATION_MS: Int64 = 10000      // 10 秒
    private static let DEFAULT_ERROR_DURATION_MS: Int64 = 30000     // 30 秒
    private static let DEFAULT_FATAL_DURATION_MS: Int64 = 60000     // 60 秒
    private static let DEFAULT_SAMPLE_INTERVAL_MS: Int64 = 1000     // 1 秒
    private static let DEFAULT_WINDOW_SIZE_MS: Int64 = 5000         // 5 秒窗口

    public init(
        cpuThreshold!: Float64 = DEFAULT_CPU_THRESHOLD,
        warnDurationMs!: Int64 = DEFAULT_WARN_DURATION_MS,
        errorDurationMs!: Int64 = DEFAULT_ERROR_DURATION_MS,
        fatalDurationMs!: Int64 = DEFAULT_FATAL_DURATION_MS,
        sampleIntervalMs!: Int64 = DEFAULT_SAMPLE_INTERVAL_MS,
        windowSizeMs!: Int64 = DEFAULT_WINDOW_SIZE_MS
    ) {
        // 校验 cpuThreshold: 必须在 [0.0, 1.0] 范围内
        this.cpuThreshold = if (cpuThreshold < 0.0 || cpuThreshold > 1.0) {
            throw Exception("Invalid cpuThreshold: ${cpuThreshold}, expected [0.0, 1.0]")
        } else {
            cpuThreshold
        }

        // 校验 warnDurationMs: 必须在 (0, Int64.Max] 范围内
        this.warnDurationMs = if (warnDurationMs <= 0 || warnDurationMs > Int64.Max) {
            throw Exception("Invalid warnDurationMs: ${warnDurationMs}, expected (0, Int64.Max]")
        } else {
            warnDurationMs
        }

        // 校验 errorDurationMs: 必须在 (0, Int64.Max] 范围内
        this.errorDurationMs = if (errorDurationMs <= 0 || errorDurationMs > Int64.Max) {
            throw Exception("Invalid errorDurationMs: ${errorDurationMs}, expected (0, Int64.Max]")
        } else {
            errorDurationMs
        }

        // 校验 fatalDurationMs: 必须在 (0, Int64.Max] 范围内
        this.fatalDurationMs = if (fatalDurationMs <= 0 || fatalDurationMs > Int64.Max) {
            throw Exception("Invalid fatalDurationMs: ${fatalDurationMs}, expected (0, Int64.Max]")
        } else {
            fatalDurationMs
        }

        // 校验 sampleIntervalMs: 必须在 (0, Int64.Max] 范围内
        this.sampleIntervalMs = if (sampleIntervalMs <= 0 || sampleIntervalMs > Int64.Max) {
            throw Exception("Invalid sampleIntervalMs: ${sampleIntervalMs}, expected (0, Int64.Max]")
        } else {
            sampleIntervalMs
        }

        // 校验 windowSizeMs: 必须在 (0, Int64.Max] 范围内
        this.windowSizeMs = if (windowSizeMs <= 0 || windowSizeMs > Int64.Max) {
            throw Exception("Invalid windowSizeMs: ${windowSizeMs}, expected (0, Int64.Max]")
        } else {
            windowSizeMs
        }
    }

    public func toInterop(): InteropBackgroundCpuMonitorConfig {
        InteropBackgroundCpuMonitorConfig(
            this.cpuThreshold, this.warnDurationMs, this.errorDurationMs,
            this.fatalDurationMs, this.sampleIntervalMs, this.windowSizeMs
        )
    }
}

/**
 * 执行后台 CPU 采样
 *
 * 核心采样逻辑：
 * 1. 检查是否在后台
 * 2. 获取当前进程 CPU 使用率
 * 3. 记录采样数据到滑动窗口
 * 4. 维护滑动窗口大小
 * 5. 检查是否满足上报条件
 */
private func doBackgroundCpuSample(): Unit {
    AppLog.info("hm-metricx-cj: [DEBUG] doBackgroundCpuSample called, isInBackground=${isInBackground}")
    
    if (!isInBackground) {
        AppLog.info("hm-metricx-cj: [DEBUG] Sampling skipped, not in background")
        return
    }

    let currentTime = getCurrentTimeMillis()
    let cpuUsage = _getCpuUsage() // 复用高 CPU 监控的获取函数
    let backgroundDuration = currentTime - backgroundStartTime
    
    AppLog.info("hm-metricx-cj: [DEBUG] Sample #${backgroundCpuSamples.size + 1}, cpuUsage=${cpuUsage}, backgroundDuration=${backgroundDuration}ms")

    backgroundCpuSamples.add(cpuUsage)

    let sample = WindowSample()
    sample.timestamp = currentTime
    sample.cpuUsage = cpuUsage
    sample.duration = backgroundDuration
    windowSamplesList.add(sample)

    // 维护滑动窗口
    if (let Some(config) <- backgroundCpuConfig) {
        while (!windowSamplesList.isEmpty()) {
            let firstSample = windowSamplesList[0]
            if (currentTime - firstSample.timestamp > config.windowSizeMs) {
                windowSamplesList.remove(at: 0)
            } else { break }
        }
    }

    // 检查上报条件
    if (let Some(config) <- backgroundCpuConfig) {
        if (backgroundDuration >= config.warnDurationMs) {
            var windowAvgCpu: Float64 = 0.0
            if (!windowSamplesList.isEmpty()) {
                var sum: Float64 = 0.0
                for (s in windowSamplesList) { sum += s.cpuUsage }
                windowAvgCpu = sum / Float64(windowSamplesList.size)
            }

            AppLog.info("hm-metricx-cj: [DEBUG] backgroundDuration=${backgroundDuration}ms, windowAvgCpu=${windowAvgCpu}, threshold=${config.cpuThreshold}")
            AppLog.info("hm-metricx-cj: [DEBUG] warnReported=${warnReported}, errorReported=${errorReported}, fatalReported=${fatalReported}")

            if (windowAvgCpu >= config.cpuThreshold) {
                // 分级上报：从高级别到低级别判断，每次只触发一个级别
                if (backgroundDuration >= config.fatalDurationMs && !fatalReported) {
                    AppLog.info("hm-metricx-cj: [DEBUG] Triggering FATAL report")
                    triggerBackgroundCpuReport(BackgroundCpuLevel.FATAL, windowAvgCpu, cpuUsage)
                } else if (backgroundDuration >= config.errorDurationMs && !errorReported) {
                    AppLog.info("hm-metricx-cj: [DEBUG] Triggering ERROR report")
                    triggerBackgroundCpuReport(BackgroundCpuLevel.ERROR, windowAvgCpu, cpuUsage)
                } else if (backgroundDuration >= config.warnDurationMs && !warnReported) {
                    AppLog.info("hm-metricx-cj: [DEBUG] Triggering WARN report")
                    triggerBackgroundCpuReport(BackgroundCpuLevel.WARN, windowAvgCpu, cpuUsage)
                }
            }
        } else {
            AppLog.info("hm-metricx-cj: [DEBUG] backgroundDuration=${backgroundDuration}ms < warnDurationMs=${config.warnDurationMs}ms, skipping report check")
        }
    }
}

/**
 * 触发后台 CPU 占用上报
 *
 * 根据异常级别（WARN/ERROR/FATAL）上报后台活动超长率信息
 */
private func triggerBackgroundCpuReport(level: BackgroundCpuLevel, avgCpu: Float64, maxCpu: Float64): Unit {
    let currentTime = getCurrentTimeMillis()
    let backgroundDuration = currentTime - backgroundStartTime

    if (!isBackgroundCapturingStack) { captureStackForBackgroundCpu() }

    let reportInfo = BackgroundCpuReportInfo()
    reportInfo.timestamp = currentTime
    reportInfo.pid = getpid()
    reportInfo.processName = getpid().toString()
    reportInfo.level = level
    reportInfo.backgroundDuration = backgroundDuration
    reportInfo.avgCpuUsage = avgCpu
    reportInfo.maxCpuUsage = maxCpu
    reportInfo.windowSamples = windowSamplesList
    
    reportInfo.highCpuThreads = ArrayList()
    for (entry in backgroundThreadSamples) {
        reportInfo.highCpuThreads.add(entry[1])
    }

    if (let Some(callback) <- backgroundCpuCallback) {
        callback(reportInfo)
    }

    match (level) {
        case BackgroundCpuLevel.WARN => warnReported = true
        case BackgroundCpuLevel.ERROR => errorReported = true
        case BackgroundCpuLevel.FATAL => fatalReported = true
    }
}

/**
 * 执行后台抓栈操作
 *
 * 抓取高 CPU 占用线程的调用栈信息
 */
private func captureStackForBackgroundCpu(): Unit {
    if (isBackgroundCapturingStack) { return }
    isBackgroundCapturingStack = true

    try {
        let threadCpuUsageJson = _getAppThreadCpuUsageJson()
        let threadCpuUsageArray = parseThreadCpuUsage(threadCpuUsageJson)
        
        let currentTime = getCurrentTimeMillis()
        if (let Some(config) <- backgroundCpuConfig) {
            for (threadUsage in threadCpuUsageArray) {
                let tid = Int64(threadUsage.threadId)
                let cpuUsage = Float64(threadUsage.cpuUsage)
                if (cpuUsage >= config.cpuThreshold) {
                    let threadName = getThreadName(tid)
                    if (!backgroundThreadSamples.contains(tid)) {
                        let threadInfo = ThreadStackInfo()
                        threadInfo.tid = tid
                        threadInfo.threadName = threadName
                        threadInfo.firstDetectedTime = currentTime
                        threadInfo.computeAvg(cpuUsage, threshold: config.cpuThreshold)
                        backgroundThreadSamples.add(tid, threadInfo)
                    } else {
                        let threadInfo = backgroundThreadSamples[tid]
                        threadInfo.computeAvg(cpuUsage, threshold: config.cpuThreshold)
                    }
                }
            }
        }
    } catch (e: Exception) {
        AppLog.warn("hm-metricx-cj: Exception during background stack capture: " + e.toString())
    } finally {
        isBackgroundCapturingStack = false
    }
}

/**
 * 启动后台监控（内部版本）
 *
 * 通过 ArkTS 传入的回调函数启动采样定时器
 */
private func startBackgroundMonitorInternal(): Unit {
    if (let Some(callback) <- repeatBackgroundSampleCallback) {
        callback({ => doBackgroundCpuSample() })
    }
}

/**
 * 停止后台监控（内部版本）
 *
 * 通过 ArkTS 传入的回调清除采样定时器
 */
private func stopBackgroundMonitorInternal(): Unit {
    if (let Some(callback) <- clearBackgroundSampleCallback) {
        callback()
    }
}

/**
 * 重置后台监控采样数据
 *
 * 在每次进入前台或销毁时调用，清空采样数据
 */
private func resetBackgroundMonitorData(): Unit {
    windowSamplesList.clear()
    backgroundCpuSamples.clear()
    backgroundThreadSamples.clear()
    isBackgroundCapturingStack = false
}

/**
 * 初始化后台活动超长率监控（内部版本）
 *
 * 启动后台活动超长率监控功能，可配置采样间隔、异常级别阈值等
 *
 * @param config 后台 CPU 监控配置
 * @param getAppThreadCpuUsageJson 获取线程 CPU 使用率 JSON 的回调（由 ArkTS 传入）
 * @param repeatSample 重复采样回调（由 ArkTS 传入，用于启动采样定时器）
 * @param clearSample 清除采样定时器回调（由 ArkTS 传入）
 * @param reportCallback 后台 CPU 占用上报回调
 */
public func initBackgroundCpuMonitorHandlerInternal(
    config: InteropBackgroundCpuMonitorConfig,
    getAppThreadCpuUsageJson: () -> String,
    repeatSample: (() -> Unit) -> Unit,
    clearSample: () -> Unit,
    reportCallback: (info: BackgroundCpuReportInfo) -> Unit
): Unit {
    if (backgroundCpuMonitorInited) { return }

    backgroundCpuConfig = Some(BackgroundCpuMonitorConfig(
        cpuThreshold: config.cpuThreshold, warnDurationMs: config.warnDurationMs,
        errorDurationMs: config.errorDurationMs, fatalDurationMs: config.fatalDurationMs,
        sampleIntervalMs: config.sampleIntervalMs, windowSizeMs: config.windowSizeMs
    ))
    
    // 保存线程 CPU 获取回调
    _getAppThreadCpuUsageJson = getAppThreadCpuUsageJson
    
    repeatBackgroundSampleCallback = Some(repeatSample)
    clearBackgroundSampleCallback = Some(clearSample)
    backgroundCpuCallback = Some(reportCallback)
    backgroundCpuMonitorInited = true

    AppLog.info("hm-metricx-cj: Background CPU monitor handler initialized")
}

/**
 * 销毁后台活动超长率监控（内部版本）
 *
 * 停止监控并清空所有采样数据
 */
public func destroyBackgroundCpuMonitorHandlerInternal(): Unit {
    if (!backgroundCpuMonitorInited) { return }
    stopBackgroundMonitorInternal()
    resetBackgroundMonitorData()
    warnReported = false; errorReported = false; fatalReported = false
    backgroundCpuMonitorInited = false
    backgroundCpuConfig = None
    backgroundCpuCallback = None
    AppLog.info("hm-metricx-cj: Background CPU monitor destroyed")
}

// ==================== @Interop 互操作类定义 ====================

/**
 * 后台监控配置互操作类
 * 用于 ArkTS 与仓颉之间的数据传递
 */
@Interop[ArkTS]
public class InteropBackgroundCpuMonitorConfig {
    public let cpuThreshold: Float64
    public let warnDurationMs: Int64
    public let errorDurationMs: Int64
    public let fatalDurationMs: Int64
    public let sampleIntervalMs: Int64
    public let windowSizeMs: Int64

    public init(
        cpuThreshold: Float64, warnDurationMs: Int64, errorDurationMs: Int64,
        fatalDurationMs: Int64, sampleIntervalMs: Int64, windowSizeMs: Int64
    ) {
        this.cpuThreshold = cpuThreshold
        this.warnDurationMs = warnDurationMs
        this.errorDurationMs = errorDurationMs
        this.fatalDurationMs = fatalDurationMs
        this.sampleIntervalMs = sampleIntervalMs
        this.windowSizeMs = windowSizeMs
    }
}