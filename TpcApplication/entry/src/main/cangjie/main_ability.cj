/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */
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
import ohos_app_cangjie_hm_metricx_cj.memLeak.*
import ohos_app_cangjie_hm_metricx_cj.thermal.*
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
            .getApplicationContext(), {=> JsonValue.fromStr("{}")}, {=> unsafe { LibC.mallocCString("{}") }}, {data => AppLog.error("xxx: " + data.rawFile.toString())},
            Path(this
                .context
                .cacheDir), OOMHandlerMode.Async, 1000, 1000, CMemMonitorConfig({soName:String =>false}))
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
        initThermalHandler(
            context,
            { info: ThermalEventInfo =>
                AppLog.error("[MetricX][Thermal] ${info.toString()}")
            },
            abnormalThreshold: 2
        )
        match (launchParam.launchReason) {
            case AbilityConstant
                .LaunchReason
                .START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }

        // 高 CPU 占用监控初始化
        initHighCpuMonitorHandler(
            this.context,
            HighCpuMonitorConfig(
                cpuThreshold: 0.05,
                foregroundIntervalMs: 1000,
                backgroundIntervalMs: 2000,
                monitorDurationMs: 33000,
                threadCooldownMs: 60000,
                globalCooldownMs: 3000,
                highSampleRatioThreshold: 0.85,
                topNThreads: 10
            ),
            { reportInfo =>
                AppLog.warn("===== 高 CPU 占用上报 =====")
                AppLog.warn("时间：${reportInfo.timestamp}")
                AppLog.warn("进程：${reportInfo.processName} (PID: ${reportInfo.pid})")
                AppLog.warn("页面：${reportInfo.pageName}")
                AppLog.warn("进程平均 CPU: ${reportInfo.avgProcessCpu}")
                AppLog.warn("进程最大 CPU: ${reportInfo.maxProcessCpu}")
                AppLog.warn("监控时长：${reportInfo.monitorDuration}毫秒")
                AppLog.warn("高占用线程数：${reportInfo.highCpuThreads.size}")

                for (threadInfo in reportInfo.highCpuThreads) {
                    AppLog.warn("--- 线程信息 ---")
                    AppLog.warn("  TID: ${threadInfo.tid}")
                    AppLog.warn("  线程名：${threadInfo.threadName}")
                    AppLog.warn("  平均 CPU: ${threadInfo.avgCpuUsage}")
                    AppLog.warn("  最大 CPU: ${threadInfo.maxCpuUsage}")
                    AppLog.warn("  采样次数：${threadInfo.sampleCount}")
                    AppLog.warn("  高采样比例：${threadInfo.getHighSampleRatio()}")
                }
            }
        )
        AppLog.info("高 CPU 监控已启动（生产模式：3 分钟上报，50% 阈值，85% 高采样比例）")

        initTrafficHandler(this.context, {data =>}, {data =>})
        initStorageHandler({data: StorageInfo =>}, sizeLimit: 100000000, dirSizeLimit: 1000, reportTopNum: 5)
        initBatteryHandler(this.context, {data =>}, {data =>})
        initCpuHandler(this.context, {data =>}, {data =>})

        // 测试自定义报告间隔和保存间隔
        initMemoryHandler(
            this.context, 
            {data => AppLog.info("initMemoryHandler : ${data.toString()}")},
            {data => AppLog.info("initMemoryHandler2 : ${data.toString()}")},
            sampleInterval : 5,
            reportInterval : 6,
            saveInterval : 30
        )
        initMemLeakHandler(this.context, Path(this
            .context
            .cacheDir), {pageInfo, typeInfos => true}, {typeInfos => false},
            {dumpFilePath => AppLog.info("dumpFilePath : ${dumpFilePath.toString()}")})
    }

    public override func onDestroy(): Unit {
        destroyHighCpuMonitorHandler()
        destroyBatteryHandler()
        destroyCpuHandler()
        destroyMemoryHandler()
        destroyTrafficHandler()
        AppLog.info("myAbility onDestroy.")
    }

    public override func onWindowStageCreate(windowStage: window.WindowStage): Unit {
        windowStage.loadContent("pages/index", {err, data => ()})
        windowStage.getMainWindow(
            {
                err: ?BusinessException, data: ?window.Window => match (data) {
                    case Some(x) =>
                        initLaggyHandler(this
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
