package ohos_app_cangjie_entry

import ohos.base.AppLog
import tpc.AbilityKit
import tpc.AbilityKit.UIAbility
import tpc.AbilityKit.Want
import tpc.AbilityKit.AbilityConstant
import tpc.UIKit.window
import ohos.hybrid_base.CJPageEntry
import ohos_app_cangjie_hm_metricx_cj.crash.*
import ohos_app_cangjie_hm_metricx_cj.freeze.*
import ohos_app_cangjie_hm_metricx_cj.fps.*
import ohos_app_cangjie_hm_metricx_cj.storage.*
import ohos_app_cangjie_hm_metricx_cj.battery.*
import ohos_app_cangjie_hm_metricx_cj.cpu.*
import ohos_app_cangjie_hm_metricx_cj.memory.*
import ohos_app_cangjie_hm_metricx_cj.laggy.*
import ohos_app_cangjie_hm_metricx_cj.traffic.*
import stdx.encoding.json.*
import std.fs.*
import ohos.hilog.*
import ohos.base.BusinessException
import tpc.UIKit.UIContext.fromUIContextBase
import tpc.UIKit.UIContext.*

let ENTRYABILITY_REGISTER_RESULT = UIAbility.registerCreator("EntryAbility", {=> EntryAbility()})

class EntryAbility <: UIAbility {
    public override func onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Unit {
        AppLog.info("Ability OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case AbilityConstant
                    .LaunchReason
                    .START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
        initCrashHandler(this
            .context
            .getApplicationContext(), {=> JsonValue.fromStr("{}")}, {=> unsafe { LibC.mallocCString("{}") }}, {data =>},
            Path(this
                .context
                .cacheDir), true)
        initFreezeHandler(
            this
                .context
                .getApplicationContext(),
            {=>
                JsonValue.fromStr("{\"xxx\":\"yyy\"}")},
            {
                data => AppLog.error("freeze "+data.extraInfo.toString())
            },
            Path(this
                .context
                .cacheDir)
        )
        initTrafficHandler(this.context, {data =>}, 1000 * 1024 * 1024)
        initStorageHandler({data: StorageInfo =>})
        initBatteryHandler(this, {data =>})
        initCpuHandler(this, {data =>})
        initMemoryHandler(this, {data =>})
    }

    public override func onDestroy(): Unit {
        destroyBatteryHandler()
        destroyCpuHandler()
        destroyMemoryHandler()
        AppLog.info("myAbility onDestroy.")
    }

    public override func onWindowStageCreate(windowStage: window.WindowStage): Unit {
        windowStage.loadContent("pages/index", {err, data => ()})
        windowStage.getMainWindow(
            {
                err: ?BusinessException, data: ?window.Window => match (data) {
                    case Some(x) =>
                        initLaggyHandle(this
                            .context
                            .getApplicationContext(), fromUIContextBase(x.getUIContext()), 10, 10, {data =>})
                        AppLog.info("initLaggyHandle")
                        initPageEventHandler(
                            this.context,
                            {
                                data => AppLog.error("page fps: " + data.toString())
                            }
                        )
                        initPageEventHandler(windowStage, {data => AppLog.error("window fps: " + data.toString())})
                        AppLog.info("initScrollEventHandler")
                        initScrollEventHandler(this.context, {data => AppLog.error("scroll fps: " + data.toString())})
                    case None =>
                        AppLog.info("initLaggyHandle error")
                        AppLog.info("initScrollEventHandler error")
                }
            })
    }

    public override func onWindowStageDestroy(): Unit {
        AppLog.info("myAbility onWindowStageDestroy.")
    }

    public override func onForeground(): Unit {
        AppLog.info("myAbility onForeground.")
    }

    public override func onBackground(): Unit {
        AppLog.info("myAbility onBackground.")
    }

    public override func onConfigurationUpdate(config: AbilityKit.Configuration): Unit {
        AppLog.info("myAbility onConfigurationUpdate: ${config.mcc}")
        CJPageEntry
            .getInstance()
            .forceRerenderAllEntry()
    }
}
