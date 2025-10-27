/**
 * Created on 2025/9/19
 */
package ohos_app_cangjie_hm_metricx_cj.cpu

import ohos_app_cangjie_hm_metricx_cj.util.*
import ohos.ark_interop.*
import ohos.ark_interop_macro.*

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
