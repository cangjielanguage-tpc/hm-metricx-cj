
package hm_metricx_cj.battery

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

@Interop[ArkTS]
public func initBatteryHandlerInterop(
    subscribe: (() -> Unit, () -> Unit, () -> Unit) -> Unit,
    getUptime: () -> Int64,
    batteryInterface: BatteryInfoInterface,
    getBrightness: () -> Int32,
    onApplicationStateChange: (() -> Unit, () -> Unit) -> Unit,
    onAbilityForeground: (() -> Unit) -> Unit,
    onNavDestinationSwitch: ((String) -> Unit) -> Unit,
    getRunningProcessInfo: ((Bool) -> Unit) -> Unit,
    repeatHandleCpuUsage: (() -> Unit) -> Unit,
    reportBatteryInfo: (InteropBatteryUsageInfo) -> Unit,
    reportThreadCpuUsageInfo: (InteropAllThreadCpuUsageInfo) -> Unit,
    limit: Int32
): Unit {
    initBatteryHandler(subscribe, getUptime, batteryInterface, getBrightness, onApplicationStateChange,
        onAbilityForeground, onNavDestinationSwitch, getRunningProcessInfo, repeatHandleCpuUsage, reportBatteryInfo,
        reportThreadCpuUsageInfo, limit: limit)
}