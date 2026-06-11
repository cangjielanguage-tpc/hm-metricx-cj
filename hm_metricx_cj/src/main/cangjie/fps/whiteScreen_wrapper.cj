package hm_metricx_cj.fps

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

@Interop[ArkTS]
public func initWhiteScreenHandlerInterop(
    config: InteropWhiteScreenConfig,
    reportCallback: (InteropWhiteScreenEventInfo) -> Unit,
    setTimeoutFunc: (String, Int64) -> Int64,
    clearTimeoutFunc: (Int64) -> Unit,
    performSnapshotFunc: () -> Unit,
    performBackgroundSnapshotFunc: (Int64) -> Unit
): Unit {
    let internalConfig = toInternalConfig(config)
    initWhiteScreenHandlerInternal(internalConfig, reportCallback, setTimeoutFunc, clearTimeoutFunc, performSnapshotFunc, performBackgroundSnapshotFunc)
}

@Interop[ArkTS]
public func destroyWhiteScreenHandlerInterop(): Unit {
    destroyWhiteScreenHandlerInternal()
}

@Interop[ArkTS]
public func onNavDestinationSwitchInterop(fromPageName: String, toPageName: String, fromHidden: Bool, toShown: Bool): Unit {
    onNavDestinationSwitchInternal(fromPageName, toPageName, fromHidden, toShown)
}

@Interop[ArkTS]
public func onFirstFrameReceivedInterop(): Unit {
    WhiteScreenDetector.GetInstance().onFirstFrameReceived()
}

@Interop[ArkTS]
public func onFrameReceivedInterop(): Unit {
    WhiteScreenDetector.GetInstance().onFrameReceived()
}

@Interop[ArkTS]
public func handleWhiteScreenTimerCallbackInterop(timerType: String): Unit {
    handleWhiteScreenTimerCallback(timerType)
}

@Interop[ArkTS]
public func performSnapshotAndAnalyzeInterop(): Unit {
    WhiteScreenDetector.GetInstance().performSnapshotAndAnalyze()
}

@Interop[ArkTS]
public func onSnapshotAnalysisResultInterop(colorData: String): Unit {
    WhiteScreenDetector.GetInstance().onSnapshotAnalysisResult(colorData)
}

@Interop[ArkTS]
public func onBackgroundSnapshotAnalysisResultInterop(sampleIndex: Int64, colorData: String): Unit {
    WhiteScreenDetector.GetInstance().onBackgroundSnapshotAnalysisResult(sampleIndex, colorData)
}

@Interop[ArkTS]
public func onWhiteScreenForegroundInterop(): Unit {
    WhiteScreenDetector.GetInstance().onForeground()
}

@Interop[ArkTS]
public func onWhiteScreenBackgroundInterop(): Unit {
    WhiteScreenDetector.GetInstance().onBackground()
}