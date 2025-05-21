/**
 * Created on 2025/5/16
 */
package ohos_app_cangjie_hm_metricx_cj.battery

import tpc.AbilityKit.UIAbility
import tpc.BasicServicesKit.*
import tpc.BasicServicesKit.batteryInfo.*
import tpc.BasicServicesKit.commonEventManager.*
import tpc.BasicServicesKit.systemDateTime.*
import tpc.BasicServicesKit.settings.*
import tpc.BasicServicesKit.power.*
import tpc.AbilityKit.kit_common.*
import tpc.AbilityKit.ApplicationContextType
import tpc.UIKit.Observer.*
import encoding.json.JsonString
import encoding.json.JsonObject
import encoding.json.JsonException
import ohos.base.AppResource
import tpc.UIKit.component_interop.ResourceStr
import std.convert.*
import std.fs.*
import std.io.*
import std.time.*
import std.sync.*
import ohos.hilog.Hilog

public class BatteryUsageInfo {
    private var currentPageNameValue: ?String = None
    private var levelValue: ?Int32 = None
    private var temperatureValue: ?Float64 = None
    private var capacityValue: ?Float64 = None
    private var scaleValue: ?Int32 = None
    private var statusValue: ?Int32 = None
    private var healthValue: ?Int32 = None
    private var voltageValue: ?Int32 = None
    private var technologyValue: ?String = None
    private var pluggedValue: ?Int32 = None
    private var chargingValue: ?Bool = None
    private var limitValue: ?Int32 = None
    private var brightnessValue: ?Int32 = None
    private var useTimeValue: ?Int64 = None
    private var timeValue: ?Int64 = None

    mut prop currentPageName: ?String {
        get() {
            currentPageNameValue
        }
        set(value) {
            currentPageNameValue = value
        }
    }
    mut prop level: ?Int32 {
        get() {
            levelValue
        }
        set(value) {
            levelValue = value
        }
    }
    mut prop temperature: ?Float64 {
        get() {
            temperatureValue
        }
        set(value) {
            temperatureValue = value
        }
    }
    mut prop capacity: ?Float64 {
        get() {
            capacityValue
        }
        set(value) {
            capacityValue = value
        }
    }
    mut prop scale: ?Int32 {
        get() {
            scaleValue
        }
        set(value) {
            scaleValue = value
        }
    }
    mut prop status: ?Int32 {
        get() {
            statusValue
        }
        set(value) {
            statusValue = value
        }
    }
    mut prop health: ?Int32 {
        get() {
            healthValue
        }
        set(value) {
            healthValue = value
        }
    }
    mut prop voltage: ?Int32 {
        get() {
            voltageValue
        }
        set(value) {
            voltageValue = value
        }
    }
    mut prop technology: ?String {
        get() {
            technologyValue
        }
        set(value) {
            technologyValue = value
        }
    }
    mut prop plugged: ?Int32 {
        get() {
            pluggedValue
        }
        set(value) {
            pluggedValue = value
        }
    }
    mut prop charging: ?Bool {
        get() {
            chargingValue
        }
        set(value) {
            chargingValue = value
        }
    }
    mut prop limit: ?Int32 {
        get() {
            limitValue
        }
        set(value) {
            limitValue = value
        }
    }
    mut prop brightness: ?Int32 {
        get() {
            brightnessValue
        }
        set(value) {
            brightnessValue = value
        }
    }
    mut prop useTime: ?Int64 {
        get() {
            useTimeValue
        }
        set(value) {
            useTimeValue = value
        }
    }
    mut prop time: ?Int64 {
        get() {
            timeValue
        }
        set(value) {
            timeValue = value
        }
    }

    public init() {
        this.scale = 100
    }

    public init(limit: Int32) {
        this.scale = 100
        this.limit = limit
    }

    public func toString(): String {
        let jsonObj = JsonObject()
        if (currentPageNameValue.isSome()) {
            jsonObj.put("currentPageName", JsonString(currentPageNameValue.getOrThrow()))
        }
        if (levelValue.isSome()) {
            jsonObj.put("level", JsonString(levelValue.getOrThrow().toString()))
        }
        if (temperatureValue.isSome()) {
            jsonObj.put("temperature", JsonString(temperatureValue.getOrThrow().toString()))
        }
        if (capacityValue.isSome()) {
            jsonObj.put("capacity", JsonString(capacityValue.getOrThrow().toString()))
        }
        if (scaleValue.isSome()) {
            jsonObj.put("scale", JsonString(scaleValue.getOrThrow().toString()))
        }
        if (statusValue.isSome()) {
            jsonObj.put("status", JsonString(statusValue.getOrThrow().toString()))
        }
        if (healthValue.isSome()) {
            jsonObj.put("health", JsonString(healthValue.getOrThrow().toString()))
        }
        if (voltageValue.isSome()) {
            jsonObj.put("voltage", JsonString(voltageValue.getOrThrow().toString()))
        }
        if (technologyValue.isSome()) {
            jsonObj.put("technology", JsonString(technologyValue.getOrThrow()))
        }
        if (pluggedValue.isSome()) {
            jsonObj.put("pluegged", JsonString(pluggedValue.getOrThrow().toString()))
        }
        if (chargingValue.isSome()) {
            jsonObj.put("charging", JsonString(chargingValue.getOrThrow().toString()))
        }
        if (limitValue.isSome()) {
            jsonObj.put("limit", JsonString(limitValue.getOrThrow().toString()))
        }
        if (brightnessValue.isSome()) {
            jsonObj.put("brightness", JsonString(brightnessValue.getOrThrow().toString()))
        }
        if (useTimeValue.isSome()) {
            jsonObj.put("useTime", JsonString(useTimeValue.getOrThrow().toString()))
        }
        if (time.isSome()) {
            jsonObj.put("time", JsonString(time.getOrThrow().toString()))
        }
        jsonObj.toString()
    }
}

public class PageSwitchCallBack <: Callback1Argument<NavDestinationSwitchInfo> {
    let elementInfoCallback: (NavDestinationSwitchInfo) -> Unit
    public init(elementInfoCallback: (NavDestinationSwitchInfo) -> Unit) {
        this.elementInfoCallback = elementInfoCallback
    }
    public func invoke(res: NavDestinationSwitchInfo): Unit {
        this.elementInfoCallback(res)
    }
}

private func getChargingStatus(): Int32 {
    let chargingStatus: BatteryChargeState = BatteryInfo.chargingStatus
    let status: Int32 = match (chargingStatus) {
        case BatteryChargeState.NONE => 1
        case BatteryChargeState.ENABLE => 2
        case BatteryChargeState.DISABLE => 4
        case BatteryChargeState.FULL => 5
    }
    return status
}

private func getHealthStatus(): Int32 {
    let healthStatus: BatteryHealthState = BatteryInfo.healthStatus
    let status: Int32 = match (healthStatus) {
        case BatteryHealthState.UNKNOWN => 1
        case BatteryHealthState.GOOD => 2
        case BatteryHealthState.OVERHEAT => 3
        case BatteryHealthState.OVERVOLTAGE => 5
        case BatteryHealthState.COLD => 7
        case BatteryHealthState.DEAD => 4
    }
    return status
}

private func getPulggedType(): Int32 {
    let pluggedType: BatteryPluggedType = BatteryInfo.pluggedType
    let status: Int32 = match (pluggedType) {
        case BatteryPluggedType.NONE => 0
        case BatteryPluggedType.AC => 1
        case BatteryPluggedType.USB => 2
        case BatteryPluggedType.WIRELESS => 4
    }
    return status
}

private func isPulggedStatus(): Bool {
    let pluggedType: BatteryPluggedType = BatteryInfo.pluggedType
    let status: Bool = match (pluggedType) {
        case BatteryPluggedType.NONE => false
        case BatteryPluggedType.AC => true
        case BatteryPluggedType.USB => true
        case BatteryPluggedType.WIRELESS => true
    }
    return status
}

//
var uiAbility: UIAbility = UIAbility()
var events: Array<String> = [
    Support.COMMON_EVENT_POWER_CONNECTED,
    Support.COMMON_EVENT_POWER_DISCONNECTED,
    Support.COMMON_EVENT_BATTERY_CHANGED
]
var subscribeInfo: CommonEventSubscribeInfo = CommonEventSubscribeInfo(events)
var eventSubscriber: CommonEventSubscriber = createSubscriber(subscribeInfo)
var reportBatteryCallback: (batteryInfo: BatteryUsageInfo) -> Unit = {info: BatteryUsageInfo =>}
var batteryLimit: Int32 = 1
var lastLevel: AtomicInt32 = AtomicInt32(-1)
var lastTime: AtomicInt64 = AtomicInt64(getUptime(TimeType.STARTUP))
var lastScreenOnTimeStamp: AtomicInt64 = AtomicInt64(getUptime(TimeType.STARTUP))
var screenOnTotalSecond: AtomicInt64 = AtomicInt64(0)
var currentPageName: String = ""

private func reset() {
    lastLevel.store(-1)
    screenOnTotalSecond.store(0)
}

private func getBrightness(): Int32 {
    let brightness = getValue<Display>(uiAbility.context, Display.SCREEN_BRIGHTNESS_STATUS,
        DomainName.DEVICE_SHARED.toString())
    let convertValue: Option<Int32> = Int32.tryParse(brightness)
    var status: Int32 = 0
    if (convertValue.isSome()) {
        status = convertValue.getOrThrow()
    }
    return status
}

let applicationCallback: ApplicationStateChangeCallback = ApplicationStateChangeCallback(
    {
        =>
        let currentTime = getUptime(TimeType.STARTUP)
        lastScreenOnTimeStamp.store(currentTime)
    },
    {
        => if (lastLevel.load() > 0 && lastTime.load() < lastScreenOnTimeStamp.load()) {
            let currentTime = getUptime(TimeType.STARTUP)
            let deltaTime = (currentTime - lastScreenOnTimeStamp.load()) / 1000
            screenOnTotalSecond.fetchAdd(deltaTime)
        }
    }
)
let pageSwitchCallback: PageSwitchCallBack = PageSwitchCallBack(
    {
        info: NavDestinationSwitchInfo => match (info.to) {
            case to: NavBar => currentPageName = "navRoot"
            case to: NavDestinationInfo =>
                let resource: ResourceStr = to.name
                match (resource) {
                    case name: String => currentPageName = name
                    case name: AppResource => currentPageName = name.moduleName
                }
        }
    })
let commonEventCallback: AsyncCallback<CommonEventData> = {
    err, data =>
    var eventData = CommonEventData("empty")
    if (err.isNone()) {
        if (data.isSome()) {
            eventData = data.getOrThrow()
        }
    }
    if (eventData.event == Support.COMMON_EVENT_BATTERY_CHANGED) {
        let isCharging: Bool = isPulggedStatus()
        if (isCharging) {
            reset()
        } else {
            let nowLevel: Int32 = BatteryInfo.batterySOC
            batteryLimit = 1
            if (lastLevel.load() < 0) {
                lastLevel.store(nowLevel)
                lastTime.store(getUptime(TimeType.STARTUP))
                if (isActive()) {
                    lastScreenOnTimeStamp.store(getUptime(TimeType.STARTUP))
                } else {
                    lastScreenOnTimeStamp.store(0)
                }
            } else if (nowLevel == lastLevel.load()) {
            } else if ((nowLevel + batteryLimit) <= lastLevel.load()) {
                let nowTime = getUptime(TimeType.STARTUP)
                let elapsedSecond = (nowTime - lastTime.load()) / 1000

                if (isActive() && lastTime.load() < lastScreenOnTimeStamp.load()) {
                    screenOnTotalSecond.fetchAdd((nowTime - lastScreenOnTimeStamp.load()) / 1000)
                    lastScreenOnTimeStamp.store(nowTime)
                }

                lastTime.store(nowTime)
                lastLevel.store(nowLevel)

                let screenOnSecond: Int64 = screenOnTotalSecond.load()
                screenOnTotalSecond.store(0)

                let info: BatteryUsageInfo = BatteryUsageInfo(batteryLimit)
                info.currentPageName = currentPageName
                info.level = nowLevel
                info.temperature = Float64(BatteryInfo.batteryTemperature) / Float64(10.0)
                info.scale = 100
                info.status = getChargingStatus()
                info.health = getHealthStatus()
                info.voltage = BatteryInfo.voltage / 1000
                info.technology = BatteryInfo.technology
                info.plugged = getPulggedType()
                info.charging = isPulggedStatus()
                info.brightness = getBrightness()
                info.useTime = screenOnSecond
                info.time = elapsedSecond
                reportBatteryCallback(info)
            }
        }
    } else if (eventData.event == Support.COMMON_EVENT_POWER_DISCONNECTED || eventData.event == Support
        .COMMON_EVENT_POWER_CONNECTED) {
        reset()
    }
}

public func initBatteryHandler(
    ability: UIAbility,
    reportBatteryInfo: (batteryInfo: BatteryUsageInfo) -> Unit
) {
    reportBatteryCallback = reportBatteryInfo
    uiAbility = ability
    let context = uiAbility.context
    let applicationContext = context.getApplicationContext()
    applicationContext.on(ApplicationContextType.APPLICATION_STATE_CHANGE, applicationCallback)
    on(navDestinationSwitch, context, pageSwitchCallback)
    subscribe(eventSubscriber, commonEventCallback)
}

public func destroyBatteryHandler() {
    reportBatteryCallback = {data: BatteryUsageInfo =>}
    let context = uiAbility.context
    let applicationContext = context.getApplicationContext()
    applicationContext.off(ApplicationContextType.APPLICATION_STATE_CHANGE, callback: applicationCallback)
    off(navDestinationSwitch, context, pageSwitchCallback)
    unsubscribe(eventSubscriber)
}
