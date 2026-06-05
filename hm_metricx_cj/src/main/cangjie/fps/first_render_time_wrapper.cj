package ohos_app_cangjie_hm_metricx_cj.fps

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

@Interop[ArkTS]
public func initFirstRenderTimeMonitorInterop(
    config: InteropFirstRenderTimeConfig,
    reportCallback: (InteropFirstRenderTimeInfo) -> Unit
): Unit {
    if (frt_init_flag) {
    	return
    }
    frt_init_flag = true
    let monitor = FirstRenderTimeMonitor.GetInstance()
    monitor.setConfig(config)
    monitor.setReportCallback(reportCallback)
}

@Interop[ArkTS]
public func recordClickStartInterop(): Unit {
    FirstRenderTimeMonitor.GetInstance().recordClickStart()
}

@Interop[ArkTS]
public func recordNavigationTargetInterop(targetPage: String): Unit {
    FirstRenderTimeMonitor.GetInstance().recordNavigationTarget(targetPage)
}

@Interop[ArkTS]
public func resetFirstRenderTimeMonitorInterop(): Unit {
    FirstRenderTimeMonitor.GetInstance().reset()
}

@Interop[ArkTS]
public func calculateFirstRenderTimeManuallyInterop(startTime: Int64, targetPage: String): Unit {
    FirstRenderTimeMonitor.GetInstance().calculateFirstRenderTimeManually(startTime, targetPage)
}

@Interop[ArkTS]
public func recordDrawEndInterop(): Unit {
    FirstRenderTimeMonitor.GetInstance().recordDrawEnd()
}

@Interop[ArkTS]
public func calculateFirstRenderTimeInterop(targetPage: String): Unit {
    FirstRenderTimeMonitor.GetInstance().calculateFirstRenderTime(targetPage)
}