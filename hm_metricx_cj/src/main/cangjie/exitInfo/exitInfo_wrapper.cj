package hm_metricx_cj.exitInfo

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

var exitInfoWrapperDestroyed: Bool = false

// 将仓颉 ExitInfo 转换给 ArkTS 层使用
private func toInteropExitInfo(data: ExitInfo): ExitInfo {
    data
}

private func toInteropAppStateInfo(data: AppStateInfo): AppStateInfo {
    data
}

@Interop[ArkTS]
public func initExitInfoHandlerInterop(
    lastExitMessage: String,
    lastExitReasonValue: Int32,   // 系统传入的 LastExitReason 枚举值
    reportExitInfoHandler: (ExitInfo) -> Unit,
    reportAppStateHandler: (AppStateInfo) -> Unit
): Unit {
    exitInfoWrapperDestroyed = false

    let jsReportExitInfo: (ExitInfo) -> Unit = { data: ExitInfo =>
        if (exitInfoWrapperDestroyed) {
            return
        }
        reportExitInfoHandler(toInteropExitInfo(data))
    }

    let jsReportAppState: (AppStateInfo) -> Unit = { data: AppStateInfo =>
        if (exitInfoWrapperDestroyed) {
            return
        }
        reportAppStateHandler(toInteropAppStateInfo(data))
    }

    // 调用仓颉 initExitInfoHandler，将 reasonStr 传进去
    initExitInfoHandler(
        lastExitMessage,
        lastExitReasonValue,
        jsReportExitInfo,
        jsReportAppState
    )
}

@Interop[ArkTS]
public func destroyExitInfoHandlerInterop(): Unit {
    exitInfoWrapperDestroyed = true
    destroyExitInfoHandler()
}

// ==================== SwipeKill 互操作接口 ====================

@Interop[ArkTS]
public func initSwipeKillHandlerInterop(
    lastExitReason: Int32,
    reportSwipeKillInfoHandler: (SwipeKillInfo) -> Unit,
    onAbilityBackground: (() -> Unit) -> Unit,
    thresholdMs: Int64
): Unit {
    let jsReportSwipeKillInfo: (SwipeKillInfo) -> Unit = { data: SwipeKillInfo =>
        if (exitInfoWrapperDestroyed) {
            return
        }
        reportSwipeKillInfoHandler(data)
    }

    initSwipeKillHandler(lastExitReason, jsReportSwipeKillInfo, onAbilityBackground, thresholdMs)
}

@Interop[ArkTS]
public func destroySwipeKillHandlerInterop(): Unit {
    destroySwipeKillHandler()
}