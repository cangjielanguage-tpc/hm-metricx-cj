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

// native 高 CPU 调用栈抓取（OH_HiDebug_BacktraceFromFp 实现，见 cpp/cpu/cpu_stack_capture.cpp）
// 返回：0 成功；-2 未初始化；-3 并发占用；-5 信号超时
foreign func InitCpuStackCapture(): Int8

// 抓取指定 OS tid 线程的调用栈。tid==0 表示当前线程（自检，不发信号）。
// stackTrace/moduleName 写入对应缓冲，返回栈文本字节数；负值表示错误码。
foreign func CaptureThreadStack(tid: Int64, stackBuf: CPointer<UInt8>, stackSize: Int64,
    moduleBuf: CPointer<UInt8>, moduleSize: Int64): Int64

// 只回溯拿原始 PC 数组，不符号化。采样阶段高频调用（~20µs/次）。
// tid==0 表示当前线程（自检，不发信号）。pcsBuf 写入原始 PC（UInt64=64bit），返回帧数；负值错误码：
// -1 参数非法；-2 未初始化；-3 并发占用；-4 tgkill 失败；-5 信号超时
foreign func CaptureThreadPcs(tid: Int64, pcsBuf: CPointer<UInt64>, pcsCapacity: Int64): Int64

// 批量符号化 PC 数组，写入栈文本 + 栈顶模块名。周期末对频次 TopK 栈调用。
// 纯读符号表，不拿 g_capturing 锁，可与回溯并发。返回栈文本字节数（<=0 失败：-2 未初始化）
foreign func SymbolizePcs(pcsBuf: CPointer<UInt64>, count: Int64,
    stackBuf: CPointer<UInt8>, stackSize: Int64,
    moduleBuf: CPointer<UInt8>, moduleSize: Int64): Int64

// ============== native /proc 直读 CPU 使用率（替代 hidebug 热路径，消除 FFRT ANR）=============
// 详见 cpp/cpu/cpu_stack_capture.cpp。互操作签名不变，Index.ets 的 hidebug 回调变死代码（向后兼容）。

// 进程级 CPU 使用率（千分比 0-1000+）。native 调 OH_HiDebug_GetAppCpuUsage 返回 0-1 浮点 ×1000。
// 与 hidebug.getCpuUsage 口径对齐。返回 <0 失败。
foreign func CaptureProcessCpuUsagePermille(): Int64

// 线程级 CPU 使用率 JSON：[{"threadId":T,"cpuUsage":C}, ...]，cpuUsage 0-1
// （与 hidebug.getAppThreadCpuUsage 对齐，所有线程相加≈1.0）。native 调
// OH_HiDebug_GetAppThreadCpuUsage 遍历链表拼装。outBuf 由调用方预分配；
// 返回写入字节数（不含 '\0'），<0 失败；超长时截到最后一个 '}' 补 ']' 保证合法 JSON。
foreign func CaptureThreadCpuUsageJson(outBuf: CPointer<UInt8>, outSize: Int64): Int64

// PC 栈聚合常量（与 native MAX_PC_FRAMES 对齐）
let MAX_PC_FRAMES: Int64 = 64
// 每线程暂存的不同 PC 栈上限：超出后只计数不存栈，防内存膨胀（10线程×32×512B≈160KB）
let MAX_DISTINCT_PC_STACKS: Int64 = 32
// 周期末符号化频次 TopK（每线程）：只符号化出现次数最高的 K 个栈，其余只计数
let TOP_K_SYMBOLIZE: Int64 = 5
// 后台 ratio 门控阈值：BackgroundCpuMonitorConfig 未含此字段，复用前台默认值 0.85。
// 后台级别上报前同样按 ratio 门控符号化，偶发峰值线程不符号化不上报。
let BACKGROUND_HIGH_SAMPLE_RATIO_THRESHOLD: Float64 = 0.85

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
let doCpuSample: () -> Unit = {
    =>
        let cpuUsage = getCpuUsageNative()
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
    onNavDestinationSwitch: (cb: (targetPageName: String) -> Unit) -> Unit,
    repeatSampleAndReportCpu: (sample: () -> Unit, report: () -> Unit) -> Unit,
    reporPageCpuInfo: (info: InteropPageCpuInfo) -> Unit,
    reporProcessCpuInfo: (info: InteropProcessCpuInfo) -> Unit
): Unit {
    if (cpu_init_flag) {
    	return
    }
    cpu_init_flag = true
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

// 周期内同一 PC 栈的去重条目：保留原始 PC 数组 + 出现次数。
// 采样阶段只做信号内 FP 回溯（~20µs），把 PC 数组 hash 后聚合——相同栈只计数不重复存，
// 周期末再对频次 TopK 条目批量符号化（~10ms/栈），从而把高频采样抓栈的总开销降 1~2 个数量级。
public class PcStackEntry {
    public let pcs: Array<UInt64>        // 原始 PC 数组（定长 64，前 frames 个有效）
    public var frames: Int64 = 0           // 有效帧数
    public var count: Int64 = 0            // 该 PC 栈在周期内被采样到的次数

    public init() {
        pcs = Array<UInt64>(MAX_PC_FRAMES, repeat: UInt64(0))
    }

    // 用 srcBuf 前 n 帧覆盖本 entry 的 pcs，重置 count=1（新建条目时用）。
    public func setPcs(srcBuf: Array<UInt64>, n: Int64): Unit {
        let copyN = if (n > MAX_PC_FRAMES) { MAX_PC_FRAMES } else { n }
        for (i in 0..copyN) {
            pcs[i] = srcBuf[i]
        }
        frames = copyN
        count = 1
    }
}

// 周期内线程级 PC 栈聚合器：HashMap<栈指纹, PcStackEntry>。
// key 为 PC 数组转 hex 串（pcs 内容指纹），相同栈只计数；上限 MAX_DISTINCT_PC_STACKS=32 个不同栈，
// 超出后只对现有最接近的条目计数（不新增，防内存膨胀）。周期末按 count 降序取 TopK 符号化。
public class ThreadPcAggregator {
    private var entries: HashMap<String, PcStackEntry> = HashMap<String, PcStackEntry>()
    private var overflowCount: Int64 = 0     // 超出上限后只计数不存栈的采样数（用于诊断）

    public init() {}

    // 把 pcsBuf 前 n 帧喂给聚合器：栈指纹命中则 +1，未命中且未满则新增，已满则 overflow++。
    public func addOrUpdate(pcsBuf: Array<UInt64>, n: Int64): Unit {
        if (n <= 0) {
            return
        }
        let key = pcStackKey(pcsBuf, n)
        if (entries.contains(key)) {
            entries[key].count++
            return
        }
        if (entries.size >= MAX_DISTINCT_PC_STACKS) {
            overflowCount++
            return
        }
        let entry = PcStackEntry()
        entry.setPcs(pcsBuf, n)
        entries.add(key, entry)
    }

    // 返回频次降序 TopK（K 由调用方传）。周期末符号化用。
    public func topK(k: Int64): ArrayList<PcStackEntry> {
        var list = ArrayList<PcStackEntry>()
        for (e in entries) {
            list.add(e[1])
        }
        sort<PcStackEntry>(
            list,
            lessThan: { a, b => a.count > b.count },
            stable: false,
            descending: false
        )
        let takeN = min(list.size, k)
        var result = ArrayList<PcStackEntry>()
        for (i in 0..takeN) {
            result.add(list[i])
        }
        result
    }

    // 周期末丢弃暂存 PC（ratio 不达标时不符号化、零成本清理）。
    public func clear(): Unit {
        entries.clear()
        overflowCount = 0
    }

    public func size(): Int64 {
        entries.size
    }

    // PC 数组 → 内容指纹串（用 StringBuilder 拼 PC 的十进制表示，加逗号分隔）。
    // 仅用作 HashMap 查重 key，无需可读性；十进制 + 分隔符保证相同栈命中相同 key。
    private func pcStackKey(pcsBuf: Array<UInt64>, n: Int64): String {
        let sb = StringBuilder()
        let copyN = if (n > MAX_PC_FRAMES) { MAX_PC_FRAMES } else { n }
        for (i in 0..copyN) {
            if (i > 0) {
                sb.append(",")
            }
            sb.append(pcsBuf[i].toString())
        }
        sb.toString()
    }
}

// 线程栈信息（用于上报）
public class ThreadStackInfo {
    private var tidValue: Int64 = 0                   // 线程 ID（唯一标识）
    private var threadNameValue: String = ""          // 线程名称
    private var avgCpuUsageValue: Float64 = 0.0       // 平均 CPU 使用率（0-1 之间）
    private var maxCpuUsageValue: Float64 = 0.0       // 最大 CPU 使用率（0-1 之间）
    private var sampleCountValue: Int64 = 0           // 该线程在 TopN 中被采样到的总次数（ratio 分母）
    private var stackTraceValue: String = ""          // 线程调用栈（周期末由频次 TopK 符号化拼接填入）
    private var moduleNameValue: String = ""          // 所属模块名（如 xxx.so，用于定位责任模块）
    private var firstDetectedTimeValue: Int64 = 0     // 首次检测到高占用的时间戳（毫秒）
    private var highSampleCountValue: Int64 = 0       // CPU≥阈值 的采样次数（ratio 分子）
    private var pcAggregatorValue: ThreadPcAggregator = ThreadPcAggregator()  // 周期内 PC 栈聚合
    // 周期总采样次数（前台 totalSampleCount / 后台 bgTotalSampleCount）。由 symbolizeTopPcStacksForReport
    // 在门控通过时回填，供 toJson 输出与门控同口径的 highSampleRatio。设计：ratio 分母用进程级周期
    // 总采样次数而非 per-thread 出现次数，避免"只进 1 次 TopN 且恰好超标"的线程 ratio=1/1=1.0 误通过门控。
    private var lastPeriodTotalSamplesValue: Int64 = 0

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
    public prop pcAggregator: ThreadPcAggregator {
        get() { pcAggregatorValue }
    }
    // 周期总采样次数（门控同口径），由 symbolizeTopPcStacksForReport 门控通过时回填
    public mut prop lastPeriodTotalSamples: Int64 {
        get() { lastPeriodTotalSamplesValue }
        set(value) { lastPeriodTotalSamplesValue = value }
    }

    /**
     * 记录一次该线程被采样到的结果（无论是否超标）。
     *
     * sampleCount 无条件 +1（该线程出现在 TopN 的次数，用于诊断/聚合），
     * 仅当 cpuUsage >= threshold 才 highSampleCount++（ratio 分子）。
     * ratio 分母用周期总采样次数（getHighSampleRatio(periodTotalSamples)），非 sampleCount。
     * ratio 门控修复：sampleCount 无条件 +1、highSampleCount 仅 cpuUsage≥threshold +1，
     * 分母用周期总采样次数（非 sampleCount），避免巧合线程 ratio=1.0 误通过门控。
     *
     * @param cpuUsage 当前线程 CPU 使用率（0-1 之间）
     * @param threshold CPU 阈值（从 config 传入）
     */
    public func recordSample(cpuUsage: Float64, threshold!: Float64 = 0.5): Unit {
        this.avgCpuUsageValue = this.avgCpuUsageValue + (cpuUsage - this.avgCpuUsageValue) / Float64(sampleCountValue + 1)
        if (maxCpuUsageValue < cpuUsage) {
            maxCpuUsageValue = cpuUsage
        }
        sampleCountValue++
        if (cpuUsage >= threshold) {
            highSampleCountValue++
        }
    }

    /**
     * 获取高采样比例（口径：周期总采样次数为分母）
     *
     * ratio = highSampleCount / totalSamples
     * - highSampleCount：该线程在 TopN 中 CPU≥阈值 的采样次数（分子）
     * - totalSamples：进程级周期总采样次数（前台 totalSampleCount / 后台 bgTotalSampleCount）
     *
     * 【为何分母用周期总采样次数】旧口径 ratio = highSampleCount / 该线程出现在 TopN 的次数，
     * 当某线程只进入 TopN 1 次且恰好超标，ratio = 1/1 = 1.0 ≥ 门控阈值（默认 0.85）会误通过，
     * 把单次巧合当持续热点上报，误差高。改用周期总采样次数（3min×1s≈180）作分母：
     * 单次巧合线程 ratio ≈ 1/180 ≈ 0.006 自动被挡；持续热点（整周期都在 TopN 且超标）≈ 180/180 = 1.0 不受影响。
     *
     * @param totalSamples 周期内进程级采样总次数（ratio 分母），<=0 时返回 0.0
     * @return 高采样比例（0-1 之间）
     */
    public func getHighSampleRatio(totalSamples: Int64): Float64 {
        if (totalSamples <= 0) {
            return 0.0
        }
        return Float64(highSampleCountValue) / Float64(totalSamples)
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
        // 频次 TopK 符号化栈列表：每个栈带出现次数与占比，呈现周期内热点分布而非单次快照。
        // pcAggregator 在周期末 ratio 门控通过后由 doHighCpuReport 填入 stackTrace，
        // 此处序列化 stackTrace 解析出的多条栈 + 计数（若 stackTrace 已含 \n[count=N]\n 标记则原样上报）。
        // highSampleRatio 与门控同口径：highSampleCount / lastPeriodTotalSamples（周期总采样次数为分母），
        // lastPeriodTotalSamples 由 symbolizeTopPcStacksForReport 门控通过时回填。
        sb.append(",\"highSampleRatio\":")
        sb.append(this.getHighSampleRatio(this.lastPeriodTotalSamples).toString())
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
    // 单线程 cooldown 时间（毫秒），默认 3 分钟（180000ms）同一线程在此时间内最多被抓取一次栈。
    // 采样阶段已改为每次采样达标即抓栈，cooldown 默认值与监控周期（monitorDurationMs 3min）对齐，
    // 保证同一线程在一个周期内最多被抓一次；下个周期可再次抓栈，避免跨周期漏报。
    public let threadCooldownMs: Int64
    // 全局 cooldown 时间（毫秒），默认 3 分钟（180000ms）。
    // 字段保留兼容 ArkTS 互操作配置——采样阶段每采样达标即抓栈，全局 cooldown 不再产生限流效果。
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
    private static let DEFAULT_THREAD_COOLDOWN_MS: Int64 = 180000   // 3 分钟（与监控周期对齐，每周期每线程最多抓一次）
    private static let DEFAULT_GLOBAL_COOLDOWN_MS: Int64 = 180000   // 3 分钟（已废弃，字段保留兼容互操作，不再实际限流）
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

// --- 应用状态 ---
// 应用是否在前台（true=前台，false=后台）由 ArkTS 侧通知
var isAppForeground: Bool = true

// --- 采样数据 ---
// 线程采样数据：tid -> ThreadStackInfo 记录每个高占用线程的统计信息
var threadSamples: HashMap<Int64, ThreadStackInfo> = HashMap()
// 进程 CPU 采样列表
var processCpuSamples: ArrayList<Float64> = ArrayList()

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
// 后台周期总采样次数（后台 ratio 分母）：doBackgroundCpuSample 每次自增，resetBackgroundMonitorData 清零。
// 后台为级别模型（WARN/ERROR/FATAL），上报不立即清零，整个后台生命周期内累加——分母只增不减，
// 巧合线程 ratio 趋近 0 自动被挡，语义自洽。与前台 totalSampleCount 对应，前后台分母互不串台。
var bgTotalSampleCount: Int64 = 0

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
 * - 抓栈锁检查（isCapturingStack，避免 native 回溯与采样回调并发）
 * - 采样达标即抓栈：检测到 cpuUsage≥cpuThreshold 的线程时，本函数末尾调
 *   captureStackForHighCpuThreads（线程级 cooldown 默认 3min，与周期对齐）
 * - 全局 cooldown 已废弃（与“每采样抓栈”逻辑冲突，不再限流）
 */
private func doHighCpuSample(): Unit {
    let currentTime = getCurrentTimeMillis()

    // 检查是否正在抓栈（抓栈期间暂停采样，避免 native 回溯与采样 JSON 回调并发）
    if (isCapturingStack) {
        return
    }
    // 注意：采样本身不受 thread cooldown 限制——cooldown 仅用于限流抓栈，
    // 若采样也被 cooldown 拦截，totalSampleCount/highCpuSampleCount 会严重偏低，
    // 导致周期末上报时调用栈为空。全局 cooldown 已废弃，不再限制采样与抓栈。

    // 获取当前进程 CPU 使用率（native OH_HiDebug C API 直调，不经 ArkTS hidebug NAPI 包装层）
    let processCpuUsage = getCpuUsageNative()
    processCpuSamples.add(processCpuUsage)
    totalSampleCount++

    // 统计高 CPU 采样次数（进程级口径，仅用于 processCpuSamples/avgProcessCpu 统计展示；
    // 抓栈触发改用线程级 cpuUsage≥cpuThreshold——doHighCpuSample 末尾检测到即调
    // captureStackForHighCpuThreads，不依赖此进程级计数）
    if (let Some(config) <- highCpuConfig) {
        if (processCpuUsage >= config.cpuThreshold) {
            highCpuSampleCount++
        }
    } else {
        if (processCpuUsage > 0.5) {
            highCpuSampleCount++
        }
    }

    // 获取所有线程的 CPU 使用情况（native OH_HiDebug C API 直调，不经 ArkTS hidebug NAPI 包装层）
    let threadCpuUsageJson = getThreadCpuUsageJsonNative()
    let threadCpuUsageArray = parseThreadCpuUsage(threadCpuUsageJson)
    if (threadCpuUsageArray.isEmpty()) {
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
    sort<(Int64, String, Float64)>(
        threadCpuList,
        lessThan: { a, b => a[2] > b[2] },
        stable: false,
        descending: false
    )

    // 记录本次采样是否出现过达标高 CPU 线程。
    // 关键：TopN 中每个线程都调 recordSample（sampleCount++ 无条件、highSampleCount++ 仅超标）。
    // ratio 口径为 highSampleCount / 周期总采样次数（getHighSampleRatio(periodTotalSamples)），
    // sampleCount 记录该线程出现在 TopN 的次数（用于诊断/聚合，非 ratio 分母）。
    var hasHighCpuThread = false
    if (let Some(config) <- highCpuConfig) {
        let topN = min(threadCpuList.size, config.topNThreads)
        for (i in 0..topN) {
            let item = threadCpuList[i]
            let tid = item[0]
            let threadName = item[1]
            let cpuUsage = item[2]

            // TopN 中每个线程都记录采样（无论是否超标），保证 ratio 分母准确
            let threadInfo = if (!threadSamples.contains(tid)) {
                let ni = ThreadStackInfo()
                ni.tid = tid
                ni.threadName = threadName
                ni.firstDetectedTime = currentTime
                threadSamples.add(tid, ni)
                ni
            } else {
                threadSamples[tid]
            }
            threadInfo.recordSample(cpuUsage, threshold: config.cpuThreshold)

            // 超标才触发抓栈（未超标的线程只计数，不抓 PC）
            if (cpuUsage >= config.cpuThreshold) {
                hasHighCpuThread = true
            }
        }
    }

    // 采样阶段即抓栈（只回溯存 PC，不符号化）：本次采样出现过 cpuUsage≥cpuThreshold
    // 的线程时立即触发。captureStackForHighCpuThreads 内部有 isCapturingStack 锁防并发，
    // 有线程级 cooldown 防同线程重复抓；全局 cooldown 已废弃。抓到的 PC 数组经 hash 聚合
    // 存入对应 ThreadStackInfo.pcAggregator，周期末 doHighCpuReport 经 ratio 门控后批量符号化。
    if (hasHighCpuThread) {
        captureStackForHighCpuThreads()
    }
}

/**
 * 调用 native 层抓取指定线程的完整调用栈，并填充到 ThreadStackInfo。
 *
 * 实现：通过 OH_HiDebug_BacktraceFromFp（信号安全）在目标线程的 SIGUSR2
 * handler 中回溯 PC 数组，再在正常上下文用 OH_HiDebug_SymbolicAddress 符号化。
 * 失败不阻断主流程，stackTrace/moduleName 保持原值（默认空/unknown）。
 *
 * tid 为 hidebug 返回的 OS tid（gettid），native 层用 syscall(SYS_tgkill) 投递信号。
 *
 * @return true=成功抓到栈（n>0，已填充 stackTrace）；false=失败（n<=0 或异常），调用方不应据此更新 cooldown。
 */
private func fillThreadStackInfo(threadInfo: ThreadStackInfo, tid: Int64): Bool {
    try {
        let stackBuf = Array<UInt8>(8192, repeat: UInt8(0))
        let moduleBuf = Array<UInt8>(256, repeat: UInt8(0))
        let n = captureStackNative(tid, stackBuf, moduleBuf)
        if (n > 0) {
            threadInfo.stackTrace = bytesToString(stackBuf, n)
            // moduleName：以 \0 为终止符截断
            var modLen = 0
            while (modLen < 256 && moduleBuf[modLen] != UInt8(0)) {
                modLen = modLen + 1
            }
            if (modLen > 0) {
                threadInfo.moduleName = bytesToString(moduleBuf, modLen)
            }
            return true
        } else {
            AppLog.warn("hm-metricx-cj: CaptureThreadStack tid=${tid} returned ${n}, no stack captured (see native '0 frames'/'tgkill failed'/'timeout' log)")
        }
    } catch (e: Exception) {
        AppLog.warn("hm-metricx-cj: fillThreadStackInfo tid=${tid} exception: ${e.message}")
    }
    false
}

/**
 * 自检探针：抓取【当前线程】调用栈并返回符号化文本。
 * tid=0 走 native 同步直调（不发信号、无 cooldown），用于在不触发高 CPU 上报的前提下
 * 验证 native 抓栈链路（符号链接、BacktraceObject、BacktraceFromFp+SymbolicAddress）是否打通。
 * 失败返回带错误码说明的字符串，便于在 hilog 里直接判断。
 */
public func captureCurrentThreadStack(): String {
    try {
        let stackBuf = Array<UInt8>(8192, repeat: UInt8(0))
        let moduleBuf = Array<UInt8>(256, repeat: UInt8(0))
        let n = captureStackNative(0, stackBuf, moduleBuf)
        if (n > 0) {
            let stack = bytesToString(stackBuf, n)
            var modLen = 0
            while (modLen < 256 && moduleBuf[modLen] != UInt8(0)) {
                modLen = modLen + 1
            }
            let mod = if (modLen > 0) { bytesToString(moduleBuf, modLen) } else { "unknown" }
            return "module=${mod}\n--- stack ---\n${stack}"
        }
        return "captureCurrentThreadStack: native returned ${n} (no stack; -2=not inited, -3=concurrent, -4=tgkill fail, -5=timeout)"
    } catch (e: Exception) {
        return "captureCurrentThreadStack exception: ${e.message}"
    }
}

// 调 native 抓栈，把符号化栈写入 stackBuf、栈顶 so 名写入 moduleBuf。返回栈字节数（<=0 为错误码）。
private func captureStackNative(tid: Int64, stackBuf: Array<UInt8>, moduleBuf: Array<UInt8>): Int64 {
    unsafe {
        let stackHandle = acquireArrayRawData(stackBuf)
        let moduleHandle = acquireArrayRawData(moduleBuf)
        let n = CaptureThreadStack(tid, stackHandle.pointer, 8192, moduleHandle.pointer, 256)
        releaseArrayRawData(stackHandle)
        releaseArrayRawData(moduleHandle)
        n
    }
}

// 把 buf 前 len 字节（native 已写入）转成 String。
// native 的 SymbolizePcs 用 snprintf 累积栈文本长度，而 snprintf 的返回值是“本应写入”的字节数
// （非实际写入，实际写入被 bufSize 截断），fa->written 累加的是这个逻辑长度，故返回的 total 会
// 超过实际写入量、可远超 stackSize（8192）。调用方直接拿 total 当 len 传入，for (i in 0..len)
// 会读到 buf[8192] → IndexOutOfBoundsException: array length 8192, index 8192。
// 故在此单点做边界保护：len 截断到 buf.size，负值视为 0。
private func bytesToString(buf: Array<UInt8>, len: Int64): String {
    var safeLen = len
    if (safeLen < 0) {
        safeLen = 0
    } else if (safeLen > buf.size) {
        safeLen = buf.size
    }
    var bytes = Array<UInt8>(safeLen, repeat: UInt8(0))
    for (i in 0..safeLen) {
        bytes[i] = buf[i]
    }
    String.fromUtf8(bytes)
}

// 只回溯拿原始 PC 数组，不符号化。采样阶段高频调用（~20µs/次）。
// pcsBuf 由调用方预分配 Array<UInt64>(64)；返回抓到的帧数（<=0 错误码）。
private func capturePcsNative(tid: Int64, pcsBuf: Array<UInt64>): Int64 {
    unsafe {
        let h = acquireArrayRawData(pcsBuf)
        let n = CaptureThreadPcs(tid, h.pointer, MAX_PC_FRAMES)
        releaseArrayRawData(h)
        n
    }
}

// 批量符号化 PC 数组 → 栈文本 + 模块名。周期末对频次 TopK 栈调用。
// 返回栈文本字节数（<=0 失败）。符号化结果写入 stackBuf/moduleBuf，再由调用方 bytesToString 取出。
private func symbolizePcsNative(pcsBuf: Array<UInt64>, count: Int64,
        stackBuf: Array<UInt8>, moduleBuf: Array<UInt8>): Int64 {
    unsafe {
        let ph = acquireArrayRawData(pcsBuf)
        let sh = acquireArrayRawData(stackBuf)
        let mh = acquireArrayRawData(moduleBuf)
        let n = SymbolizePcs(ph.pointer, count, sh.pointer, 8192, mh.pointer, 256)
        releaseArrayRawData(ph)
        releaseArrayRawData(sh)
        releaseArrayRawData(mh)
        n
    }
}

// ============== native /proc 直读包装（替代原 hidebug getCpuUsage/getAppThreadCpuUsageJson 回调）=============
// native 在仓颉 spawn/主线程均可安全调用（不经 hidebug，无 FFRT 退避），消除主线程 ANR 风险。

// 进程级 CPU 使用率（0-1 浮点，多核可>1）。native OH_HiDebug_GetAppCpuUsage 返回 0-1，
// native 侧 ×1000 转千分比，此处 /1000 还原。失败返回 0。
func getCpuUsageNative(): Float64 {
    try {
        let permille = unsafe { CaptureProcessCpuUsagePermille() }
        if (permille < 0) {
            return 0.0
        }
        return Float64(permille) / 1000.0
    } catch (e: Exception) {
        AppLog.warn("hm-metricx-cj: getCpuUsageNative exception: ${e.message}")
        return 0.0
    }
}

// 线程级 CPU 使用率 JSON（供 parseThreadCpuUsage 解析）。失败返回 "[]"。
// outBuf=16384 足够几百线程；超长时 native 截到最后一个 '}' 补 ']' 保证合法 JSON。
func getThreadCpuUsageJsonNative(): String {
    let outBuf = Array<UInt8>(16384, repeat: UInt8(0))
    try {
        unsafe {
            let h = acquireArrayRawData(outBuf)
            let n = CaptureThreadCpuUsageJson(h.pointer, 16384)
            releaseArrayRawData(h)
            if (n <= 0) {
                return "[]"
            }
            // 取出 n 字节转字符串（native 已写 '\0' 结尾，bytesToString 按 n 截断）
            return bytesToString(outBuf, n)
        }
    } catch (e: Exception) {
        AppLog.warn("hm-metricx-cj: getThreadCpuUsageJsonNative exception: ${e.message}")
        return "[]"
    }
}

/**
 * 执行抓栈操作（采样阶段即触发，非周期末触发）
 *
 * 实现需求：doHighCpuSample 在每次采样时检测到 cpuUsage≥cpuThreshold 的线程即调用本函数。
 * 抓取 TopN 中过阈值的线程的调用栈，用于定位哪个模块/线程持续占用 CPU。
 *
 * 核心逻辑：
 * 1. 检查抓栈锁（如果抓栈正在进行，忽略新的触发——避免 native 回溯与采样回调并发）
 * 2. 获取所有线程的 CPU 使用情况，按 cpuUsage 降序排序
 * 3. 遍历 TopN，逐线程：① 线程 cooldown 中则跳过；② 过阈值才抓；③ 抓栈成功才更新该线程 cooldown
 * 4. 抓到的栈填充到对应 ThreadStackInfo.stackTrace，供周期末 doHighCpuReport 按 tid 去重拼接上报
 *
 * 限流：仅保留线程级 cooldown（默认 3 分钟，与监控周期对齐）。
 * 全局 cooldown 已废弃——采样阶段每采样达标即抓栈，全局 cooldown 会直接拦截周期内的合法抓栈。
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

    isCapturingStack = true

    try {
        if (let Some(config) <- highCpuConfig) {
            // 只回溯存原始 PC 数组（不符号化）。取当前帧所有线程按 cpuUsage 降序排序，
            // 遍历前 topN 个，逐线程判断：① cooldown 中则跳过；② 过阈值才抓 PC
            // （进入 TopN 但未过阈值的线程不抓，避免抓无关线程的栈）；
            // ③ 抓到 PC（n>0）才更新该线程 cooldown，避免抓栈失败也占满 cooldown 额度。
            // 抓到的 PC 数组经 hash 聚合存入 threadInfo.pcAggregator：相同栈只计数不重复存。
            // 符号化推迟到周期末 doHighCpuReport，经 ratio 门控后只对频次 TopK 批量符号化。
            let threadCpuUsageJson = getThreadCpuUsageJsonNative()
            let threadCpuUsageArray = parseThreadCpuUsage(threadCpuUsageJson)
            if (threadCpuUsageArray.isEmpty()) {
                AppLog.warn("hm-metricx-cj: parseThreadCpuUsage returned empty array during stack capture")
            } else if (threadCpuUsageArray.size > 0) {
                var threadCpuList = ArrayList<(Int64, String, Float64)>()
                for (threadUsage in threadCpuUsageArray) {
                    let tid = Int64(threadUsage.threadId)
                    let cpuUsage = Float64(threadUsage.cpuUsage)
                    let threadName = getThreadName(tid)
                    threadCpuList.add((tid, threadName, cpuUsage))
                }
                sort<(Int64, String, Float64)>(
                    threadCpuList,
                    lessThan: { a, b => a[2] > b[2] },
                    stable: false,
                    descending: false
                )
                // TopN：CPU 最高的 N 个线程（与采样阶段 doHighCpuSample 的 topN 一致）
                let topN = min(threadCpuList.size, config.topNThreads)
                let pcsBuf = Array<UInt64>(MAX_PC_FRAMES, repeat: UInt64(0))
                for (i in 0..topN) {
                    let item = threadCpuList[i]
                    let tid = item[0]
                    let threadName = item[1]
                    let cpuUsage = item[2]
                    // 阈值过滤：只抓 cpuUsage≥cpuThreshold 的线程，避免抓 TopN 中无关的低 CPU 线程
                    if (cpuUsage < config.cpuThreshold) {
                        continue
                    }
                    // 【解耦后不再限流】旧 threadCooldownMs（默认 3min）是为"每采样完整符号化 ~10ms"
                    // 设计的限流；解耦后抓 PC 只剩信号内 FP 回溯（~20µs/次），与"每次采样达标即抓"
                    // 的设计直接冲突——3min cooldown 会让 30s 测试窗口里 29 次采样只抓到 1 个 PC，
                    // 频率分布形同虚设。故 PC 抓取路径去掉 cooldown，每次采样都抓，相同栈靠 hash 聚合计数。
                    // 并发安全仍由 isCapturingStack 串行锁 + native g_capturing CAS 保证（g_pending 单槽）。

                    // threadSamples 中该 tid 的 ThreadStackInfo 已在 doHighCpuSample 中创建并 recordSample
                    let threadInfo = if (threadSamples.contains(tid)) {
                        threadSamples[tid]
                    } else {
                        // 极端情况：doHighCpuSample 未创建（如本次是新超标线程，但 doHighCpuSample
                        // 已先于本函数跑过，理论上 threadSamples 已含）。兜底创建并记录一次采样。
                        let ni = ThreadStackInfo()
                        ni.tid = tid
                        ni.threadName = threadName
                        ni.firstDetectedTime = currentTime
                        ni.recordSample(cpuUsage, threshold: config.cpuThreshold)
                        threadSamples.add(tid, ni)
                        ni
                    }

                    // 只回溯拿 PC，不符号化（~20µs/次）
                    let n = capturePcsNative(tid, pcsBuf)
                    if (n > 0) {
                        // hash 聚合：相同栈只计数不重复存；超 32 种截断
                        threadInfo.pcAggregator.addOrUpdate(pcsBuf, n)
                    } else {
                        AppLog.warn("hm-metricx-cj: capturePcsNative tid=${tid} returned ${n}, no PC captured")
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
 * 周期末/级别上报前的统一符号化逻辑（前台 doHighCpuReport 与后台 triggerBackgroundCpuReport 共用）。
 *
 * 对单个线程的暂存 PC 数组做 ratio 门控 + 频次 TopK 批量符号化：
 * - pcAggregator 为空（该线程被采样到但从未抓到 PC）→ 不符号化，返回 false
 * - ratio < ratioThreshold → 丢弃暂存 PC，零符号化成本，返回 false
 * - ratio ≥ 阈值 → 取频次 TopK 栈逐个符号化，拼入 threadInfo.stackTrace（带次数/占比标记），
 *   moduleName 取频次最高栈的栈顶 so；符号化后清理 PC 数组。stackTrace 非空返回 true。
 *
 * ratio 口径：getHighSampleRatio(periodTotalSamples) = highSampleCount / periodTotalSamples。
 * 分母用周期总采样次数（非 per-thread 出现次数），挡掉"只进 1 次 TopN 且恰好超标"的巧合线程。
 *
 * @param threadInfo 待符号化线程
 * @param stackBuf 符号化栈缓冲（复用，8192B）
 * @param moduleBuf 模块名缓冲（复用，256B）
 * @param ratioThreshold ratio 门控阈值（前台 config.highSampleRatioThreshold，后台 BACKGROUND_HIGH_SAMPLE_RATIO_THRESHOLD）
 * @param periodTotalSamples 周期内进程级采样总次数（ratio 分母；前台 totalSampleCount / 后台 bgTotalSampleCount）
 * @return true=该线程符号化出栈、应纳入上报；false=跳过（无 PC / ratio 不达标 / 符号化全失败）
 */
private func symbolizeTopPcStacksForReport(threadInfo: ThreadStackInfo,
        stackBuf: Array<UInt8>, moduleBuf: Array<UInt8>,
        ratioThreshold: Float64, periodTotalSamples: Int64): Bool {
    // 该线程在周期内被采样到但从未抓到 PC（cooldown 中 / 抓栈失败）→ 跳过
    if (threadInfo.pcAggregator.size() == 0) {
        return false
    }
    let ratio = threadInfo.getHighSampleRatio(periodTotalSamples)
    // ratio 门控：不足阈值则丢弃 PC，不符号化（偶发峰值线程）
    if (ratio < ratioThreshold) {
        AppLog.info("hm-metricx-cj: Discard PC (ratio below threshold): tid=${threadInfo.tid}, name=${threadInfo.threadName}, ratio=${ratio} < ${ratioThreshold}, highSamples=${threadInfo.highSampleCount}, periodTotalSamples=${periodTotalSamples}")
        threadInfo.pcAggregator.clear()
        return false
    }
    // 达标：回填周期总采样次数（toJson 输出与门控同口径的 highSampleRatio）
    threadInfo.lastPeriodTotalSamples = periodTotalSamples
    // 取频次 TopK 栈批量符号化，拼入 stackTrace（带次数/占比标记）
    let topEntries = threadInfo.pcAggregator.topK(TOP_K_SYMBOLIZE)
    var totalSamples: Int64 = 0
    for (e in topEntries) {
        totalSamples += e.count
    }
    let sb = StringBuilder()
    for (idx in 0..topEntries.size) {
        let e = topEntries[idx]
        let n = symbolizePcsNative(e.pcs, e.frames, stackBuf, moduleBuf)
        if (n > 0) {
            let stackStr = bytesToString(stackBuf, n)
            // 模块名：以 \0 截断
            var modLen = 0
            while (modLen < 256 && moduleBuf[modLen] != UInt8(0)) {
                modLen = modLen + 1
            }
            let mod = if (modLen > 0) { bytesToString(moduleBuf, modLen) } else { "unknown" }
            let pct = if (totalSamples > 0) { Float64(e.count) / Float64(totalSamples) * 100.0 } else { 0.0 }
            if (idx > 0) {
                sb.append("\n---\n")
            }
            sb.append("[module=${mod}] [count=${e.count}/${totalSamples}, ${pct}%]\n${stackStr}")
            // 取第一个（频次最高）栈的模块名作为线程级 moduleName
            if (idx == 0) {
                threadInfo.moduleName = mod
            }
        } else {
            AppLog.warn("hm-metricx-cj: SymbolizePcs returned ${n} for tid=${threadInfo.tid}, frames=${e.frames}")
        }
    }
    let stackText = sb.toString()
    // 符号化后清理 PC（已转成文本，PC 数组不再需要）
    threadInfo.pcAggregator.clear()
    if (stackText == "") {
        return false
    }
    threadInfo.stackTrace = stackText
    AppLog.info("hm-metricx-cj: Thread symbolized for report: tid=${threadInfo.tid}, name=${threadInfo.threadName}, ratio=${ratio}, highSamples=${threadInfo.highSampleCount}, periodTotalSamples=${periodTotalSamples}, threadSamples=${threadInfo.sampleCount}, distinctStacks=${topEntries.size}")
    true
}

/**
 * 执行高 CPU 占用上报
 *
 * 实现需求：3 分钟周期末上报一次，包含以下信息：
 * - 本周期内进程平均 CPU 使用率
 * - 本周期内出现过的不同高 CPU 线程的栈信息和模块名
 *
 * 上报条件：
 * - 监控时长达到 monitorDurationMs（默认 3 分钟）
 * - 本周期内至少有一次采样达标并抓到栈（threadSamples 中存在 stackTrace 非空的线程）
 *
 * 上报方式（周期末拼接）：
 * - 抓栈已在采样阶段（doHighCpuSample 检测到 cpuUsage≥cpuThreshold 即调
 *   captureStackForHighCpuThreads）完成，本函数不再触发抓栈
 * - 周期内出现过的不同高 CPU 线程按 tid 去重（threadSamples 以 tid 为键），
 *   每个 tid 只保留最近一次抓到的栈，拼接到 highCpuThreads 一起上报
 * - 未抓到栈（cooldown 中 / 抓栈失败）的线程 stackTrace 为空，被过滤掉
 *
 * 【解耦符号化】周期末对每个线程先算 highSampleRatio：
 * - ratio < highSampleRatioThreshold（默认 0.85）：丢弃暂存 PC 数据，零符号化成本
 *   （该线程在 TopN 中真正烧 CPU 的比例不足，不值得符号化上报）
 * - ratio ≥ 阈值：取 pcAggregator 频次 TopK（默认 5）的栈批量符号化，拼入 stackTrace
 *   （带出现次数/占比标记），moduleName 取栈顶 so
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

    // 周期末不再触发抓栈——抓栈已在采样阶段完成。此处仅对暂存 PC 经 ratio 门控后批量符号化。

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

    // 周期末符号化缓冲区（复用，避免每栈 alloc）
    let stackBuf = Array<UInt8>(8192, repeat: UInt8(0))
    let moduleBuf = Array<UInt8>(256, repeat: UInt8(0))

    // 拼接上报线程：周期内采样达标（ratio≥阈值）且符号化出栈的线程。
    // ratio 门控 + 频次 TopK 批量符号化逻辑封装在 symbolizeTopPcStacksForReport 中，前后台共用。
    let highCpuThreads = ArrayList<ThreadStackInfo>()
    if (let Some(config) <- highCpuConfig) {
        for (entry in threadSamples) {
            if (symbolizeTopPcStacksForReport(entry[1], stackBuf, moduleBuf, config.highSampleRatioThreshold, totalSampleCount)) {
                highCpuThreads.add(entry[1])
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
    threadSamples.clear()
    processCpuSamples.clear()
    totalSampleCount = 0
    highCpuSampleCount = 0
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
 * @param onNavDestinationSwitch 页面切换回调（由 ArkTS 传入，用于更新当前页面名称）
 * @param repeatHighCpuSample 重复采样回调（由 ArkTS 传入，用于启动采样定时器）
 * @param repeatHighCpuReport 重复上报回调（由 ArkTS 传入，用于启动上报定时器）
 * @param reportHighCpuInfo 高 CPU 占用上报回调（3 分钟一次或手动触发）
 *
 */
public func initHighCpuMonitorHandlerInternal(
    onNavDestinationSwitch: (cb: (targetPageName: String) -> Unit) -> Unit,
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

    // 保存定时器控制回调
    repeatHighCpuSampleCallback = Some(repeatHighCpuSample)
    repeatHighCpuReportCallback = Some(repeatHighCpuReport)
    clearHighCpuSampleCallback = Some({ => }) // 默认空实现，由 ArkTS 侧控制
    clearHighCpuReportCallback = Some({ => }) // 默认空实现，由 ArkTS 侧控制

    // 保存上报回调
    reportHighCpuCallback = Some(reportHighCpuInfo)
    highCpuMonitorInited = true

    // 初始化 native 高 CPU 调用栈抓取（一次性，创建 BacktraceObject + 注册 SIGUSR2 handler）
    try {
        let initRet = unsafe { InitCpuStackCapture() }
        if (initRet != 0) {
            AppLog.warn("hm-metricx-cj: InitCpuStackCapture failed, ret=${initRet}, stack capture disabled")
        }
    } catch (e: Exception) {
        AppLog.warn("hm-metricx-cj: InitCpuStackCapture exception, stack capture disabled: ${e.message}")
    }

    // 注册页面切换回调，更新 currentPageName
    onNavDestinationSwitch(
        {
            targetPageName =>
                if (!targetPageName.isEmpty()) {
                    currentPageName = targetPageName
                    AppLog.info("hm-metricx-cj: High CPU monitor page switched to: ${targetPageName}")
                }
        }
    )

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
    // 每次抓栈保留的 TopN 线程数（默认 10），只抓 TopN 中过阈值的线程
    public let topNThreads: Int64
    // 单线程 cooldown（毫秒），同一线程在此时间内最多被抓取一次栈（默认 3 分钟）。
    // 采样阶段已改为每次采样达标即抓栈，cooldown 与后台级别周期对齐，避免跨周期漏报。
    public let threadCooldownMs: Int64
    // 全局 cooldown（毫秒），后台抓栈整体限流（默认 3 分钟）。
    // 字段保留兼容 ArkTS 互操作配置——采样阶段每采样达标即抓栈，全局 cooldown 不再产生限流效果。
    public let globalCooldownMs: Int64

    // 默认值常量
    private static let DEFAULT_CPU_THRESHOLD: Float64 = 0.5
    private static let DEFAULT_WARN_DURATION_MS: Int64 = 10000      // 10 秒
    private static let DEFAULT_ERROR_DURATION_MS: Int64 = 30000     // 30 秒
    private static let DEFAULT_FATAL_DURATION_MS: Int64 = 60000     // 60 秒
    private static let DEFAULT_SAMPLE_INTERVAL_MS: Int64 = 1000     // 1 秒
    private static let DEFAULT_WINDOW_SIZE_MS: Int64 = 5000         // 5 秒窗口
    private static let DEFAULT_TOP_N_THREADS: Int64 = 10
    private static let DEFAULT_THREAD_COOLDOWN_MS: Int64 = 180000   // 3 分钟（与级别周期对齐，每周期每线程最多抓一次）
    private static let DEFAULT_GLOBAL_COOLDOWN_MS: Int64 = 180000   // 3 分钟（已废弃，字段保留兼容互操作，不再实际限流）

    public init(
        cpuThreshold!: Float64 = DEFAULT_CPU_THRESHOLD,
        warnDurationMs!: Int64 = DEFAULT_WARN_DURATION_MS,
        errorDurationMs!: Int64 = DEFAULT_ERROR_DURATION_MS,
        fatalDurationMs!: Int64 = DEFAULT_FATAL_DURATION_MS,
        sampleIntervalMs!: Int64 = DEFAULT_SAMPLE_INTERVAL_MS,
        windowSizeMs!: Int64 = DEFAULT_WINDOW_SIZE_MS,
        topNThreads!: Int64 = DEFAULT_TOP_N_THREADS,
        threadCooldownMs!: Int64 = DEFAULT_THREAD_COOLDOWN_MS,
        globalCooldownMs!: Int64 = DEFAULT_GLOBAL_COOLDOWN_MS
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

        // 校验 topNThreads: 必须在 (0, Int64.Max] 范围内
        this.topNThreads = if (topNThreads <= 0 || topNThreads > Int64.Max) {
            throw Exception("Invalid topNThreads: ${topNThreads}, expected (0, Int64.Max]")
        } else {
            topNThreads
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
    }

    public func toInterop(): InteropBackgroundCpuMonitorConfig {
        InteropBackgroundCpuMonitorConfig(
            this.cpuThreshold, this.warnDurationMs, this.errorDurationMs,
            this.fatalDurationMs, this.sampleIntervalMs, this.windowSizeMs,
            this.topNThreads, this.threadCooldownMs, this.globalCooldownMs
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
    if (!isInBackground) {
        return
    }

    let currentTime = getCurrentTimeMillis()
    let cpuUsage = getCpuUsageNative() // native /proc 直读，不经 hidebug，主线程安全
    let backgroundDuration = currentTime - backgroundStartTime

    backgroundCpuSamples.add(cpuUsage)
    // 后台周期总采样次数自增（后台 ratio 分母）。与前台 totalSampleCount 语义对齐：
    // 每次进程级采样 +1，作为 symbolizeTopPcStacksForReport 的 periodTotalSamples 传入，
    // 使 ratio = highSampleCount / bgTotalSampleCount，挡掉"只进 1 次 TopN 且达标"的巧合线程。
    bgTotalSampleCount++

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

            if (windowAvgCpu >= config.cpuThreshold) {
                // 采样阶段即抓栈：窗口均值达标立即触发后台抓 PC（与前台一致）。
                // captureStackForBackgroundCpu 内有 isBackgroundCapturingStack 串行锁防并发；
                // 抓到的 PC 经 hash 聚合存入 backgroundThreadSamples，级别上报时经 ratio 门控
                // 后批量符号化。
                if (!isBackgroundCapturingStack) { captureStackForBackgroundCpu() }
                // 分级上报：从高级别到低级别判断，每次只触发一个级别
                if (backgroundDuration >= config.fatalDurationMs && !fatalReported) {
                    triggerBackgroundCpuReport(BackgroundCpuLevel.FATAL, windowAvgCpu, cpuUsage)
                } else if (backgroundDuration >= config.errorDurationMs && !errorReported) {
                    triggerBackgroundCpuReport(BackgroundCpuLevel.ERROR, windowAvgCpu, cpuUsage)
                } else if (backgroundDuration >= config.warnDurationMs && !warnReported) {
                    triggerBackgroundCpuReport(BackgroundCpuLevel.WARN, windowAvgCpu, cpuUsage)
                }
            }
        }
    }
}

/**
 * 触发后台 CPU 占用上报
 *
 * 根据异常级别（WARN/ERROR/FATAL）上报后台活动超长率信息。
 *
 * 抓栈已在采样阶段（doBackgroundCpuSample 窗口均值达标即调 captureStackForBackgroundCpu）完成，
 * 本函数不再触发抓栈，仅对暂存 PC 经 ratio 门控后批量符号化：backgroundThreadSamples 以 tid 为键，
 * 天然按 tid 去重；ratio 不达标线程丢弃 PC 零符号化成本，达标线程取频次 TopK 符号化拼入 stackTrace。
 */
private func triggerBackgroundCpuReport(level: BackgroundCpuLevel, avgCpu: Float64, maxCpu: Float64): Unit {
    let currentTime = getCurrentTimeMillis()
    let backgroundDuration = currentTime - backgroundStartTime

    let reportInfo = BackgroundCpuReportInfo()
    reportInfo.timestamp = currentTime
    reportInfo.pid = getpid()
    reportInfo.processName = getpid().toString()
    reportInfo.level = level
    reportInfo.backgroundDuration = backgroundDuration
    reportInfo.avgCpuUsage = avgCpu
    reportInfo.maxCpuUsage = maxCpu
    reportInfo.windowSamples = windowSamplesList

    // 周期末符号化缓冲区（复用，避免每栈 alloc）
    let stackBuf = Array<UInt8>(8192, repeat: UInt8(0))
    let moduleBuf = Array<UInt8>(256, repeat: UInt8(0))

    reportInfo.highCpuThreads = ArrayList()
    for (entry in backgroundThreadSamples) {
        // ratio 门控 + 频次 TopK 批量符号化（与前台 doHighCpuReport 共用 symbolizeTopPcStacksForReport）。
        // 后台 config 无 highSampleRatioThreshold 字段，复用模块级 BACKGROUND_HIGH_SAMPLE_RATIO_THRESHOLD。
        // 分母用 bgTotalSampleCount（后台生命周期内累加，进前台/销毁时 reset）。
        if (symbolizeTopPcStacksForReport(entry[1], stackBuf, moduleBuf, BACKGROUND_HIGH_SAMPLE_RATIO_THRESHOLD, bgTotalSampleCount)) {
            reportInfo.highCpuThreads.add(entry[1])
        }
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
 * 执行后台抓栈操作（采样阶段即触发，只回溯存 PC，不符号化）
 *
 * 与前台 captureStackForHighCpuThreads 一致：取当前帧所有线程按 cpuUsage 降序排序，遍历前 topN 个，
 * 逐线程判断：① 过阈值才抓 PC（未过阈值的 TopN 线程不抓）；② 线程级 cooldown 中则跳过该线程；
 * ③ 抓到 PC（n>0）才更新该线程 cooldown。抓到的 PC 数组 hash 聚合存入 threadInfo.pcAggregator，
 * 级别上报时（triggerBackgroundCpuReport）经 ratio 门控后批量符号化。
 *
 * 限流：仅保留线程级 cooldown（默认 3min，与级别周期对齐）。后台全局 cooldown 已废弃。
 */
private func captureStackForBackgroundCpu(): Unit {
    if (isBackgroundCapturingStack) { return }
    isBackgroundCapturingStack = true

    let currentTime = getCurrentTimeMillis()
    try {
        let threadCpuUsageJson = getThreadCpuUsageJsonNative()
        let threadCpuUsageArray = parseThreadCpuUsage(threadCpuUsageJson)

        if (let Some(config) <- backgroundCpuConfig) {
            if (threadCpuUsageArray.size > 0) {
                var threadCpuList = ArrayList<(Int64, String, Float64)>()
                for (threadUsage in threadCpuUsageArray) {
                    let tid = Int64(threadUsage.threadId)
                    let cpuUsage = Float64(threadUsage.cpuUsage)
                    let threadName = getThreadName(tid)
                    threadCpuList.add((tid, threadName, cpuUsage))
                }
                sort<(Int64, String, Float64)>(
                    threadCpuList,
                    lessThan: { a, b => a[2] > b[2] },
                    stable: false,
                    descending: false
                )
                // TopN：CPU 最高的 N 个线程
                let topN = min(threadCpuList.size, config.topNThreads)
                let pcsBuf = Array<UInt64>(MAX_PC_FRAMES, repeat: UInt64(0))
                for (i in 0..topN) {
                    let item = threadCpuList[i]
                    let tid = item[0]
                    let threadName = item[1]
                    let cpuUsage = item[2]
                    // 阈值过滤：只抓 cpuUsage≥cpuThreshold 的线程
                    if (cpuUsage < config.cpuThreshold) {
                        continue
                    }
                    // 【解耦后不再限流】与前台同理：threadCooldownMs 是旧"完整符号化"限流，
                    // 与"每次采样达标即抓 PC（~20µs）"冲突，会让短窗口只抓到 1 个 PC。去掉 cooldown，
                    // 每次采样都抓，相同栈靠 hash 聚合计数。并发安全由 isBackgroundCapturingStack
                    // 串行锁 + native g_capturing CAS 保证。

                    // 后台级别模型下，doBackgroundCpuSample 不会为每个 TopN 线程 recordSample
                    // （它只看窗口均值），故此处兜底：抓 PC 前先记录一次该线程采样。
                    let threadInfo = if (backgroundThreadSamples.contains(tid)) {
                        backgroundThreadSamples[tid]
                    } else {
                        let ni = ThreadStackInfo()
                        ni.tid = tid
                        ni.threadName = threadName
                        ni.firstDetectedTime = currentTime
                        ni.recordSample(cpuUsage, threshold: config.cpuThreshold)
                        backgroundThreadSamples.add(tid, ni)
                        ni
                    }

                    // 只回溯拿 PC，不符号化（~20µs/次）
                    let n = capturePcsNative(tid, pcsBuf)
                    if (n > 0) {
                        threadInfo.pcAggregator.addOrUpdate(pcsBuf, n)
                    } else {
                        AppLog.warn("hm-metricx-cj: [BG] capturePcsNative tid=${tid} returned ${n}, no PC captured")
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
    bgTotalSampleCount = 0
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
    repeatSample: (() -> Unit) -> Unit,
    clearSample: () -> Unit,
    reportCallback: (info: BackgroundCpuReportInfo) -> Unit
): Unit {
    if (backgroundCpuMonitorInited) { return }

    backgroundCpuConfig = Some(BackgroundCpuMonitorConfig(
        cpuThreshold: config.cpuThreshold, warnDurationMs: config.warnDurationMs,
        errorDurationMs: config.errorDurationMs, fatalDurationMs: config.fatalDurationMs,
        sampleIntervalMs: config.sampleIntervalMs, windowSizeMs: config.windowSizeMs,
        topNThreads: config.topNThreads, threadCooldownMs: config.threadCooldownMs,
        globalCooldownMs: config.globalCooldownMs
    ))

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
    sleep(Duration.millisecond * 0.1)
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
    // 每次抓栈保留的 TopN 线程数（默认 10）
    public let topNThreads: Int64
    // 单线程 cooldown（ms），同一线程在此时间内最多被抓取一次栈
    public let threadCooldownMs: Int64
    // 全局 cooldown（ms），后台抓栈整体限流
    public let globalCooldownMs: Int64

    public init(
        cpuThreshold: Float64, warnDurationMs: Int64, errorDurationMs: Int64,
        fatalDurationMs: Int64, sampleIntervalMs: Int64, windowSizeMs: Int64,
        topNThreads: Int64, threadCooldownMs: Int64, globalCooldownMs: Int64
    ) {
        this.cpuThreshold = cpuThreshold
        this.warnDurationMs = warnDurationMs
        this.errorDurationMs = errorDurationMs
        this.fatalDurationMs = fatalDurationMs
        this.sampleIntervalMs = sampleIntervalMs
        this.windowSizeMs = windowSizeMs
        this.topNThreads = topNThreads
        this.threadCooldownMs = threadCooldownMs
        this.globalCooldownMs = globalCooldownMs
    }
}