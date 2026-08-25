import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { ErrorEvent, MessageEvents, worker } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

import {
  CMemMonitorConfig,
  OOMHandlerMode,
  initCpuHandler,
  initCrashHandler,
  CrashCallbacks,
  CrashConfig,
  initStorageHandler,
  initTrafficHandler,
  initExitInfoHandler,
  initFreezeHandler,
  initMemoryHandler,
  destroyMemoryHandler,
  setArkTsMemoryCacheInterop,
  initBatteryHandler,
  destroyBatteryHandler,
  initScrollEventHandler,
  initPageEventHandler,
  initLaggyHandler,
  destroyCpuHandler,
  destroyTrafficHandler,
  initThermalHandler,
  initHighCpuMonitorHandler,
  destroyHighCpuMonitorHandler,
  HighCpuMonitorConfig,
  HighCpuReportInfo,
  captureCurrentThreadStack,
  initBackgroundCpuMonitorHandler,
  destroyBackgroundCpuMonitorHandler,
  BackgroundCpuMonitorConfig,
  BackgroundCpuReportInfo,
  WhiteScreenConfig,
  WhiteScreenEventInfo,
  initWhiteScreenHandler,
  destroyWhiteScreenHandler,
  FirstRenderTimeConfig,
  initFirstRenderTimeHandler,
  destroyFirstRenderTimeHandler,
  initSwipeKillHandler,
  destroySwipeKillHandler
} from '@cangjie-tpc/hm_metricx_cj_hybrid';
import { thermalTestStore } from '../store/ThermalTestStore';

const DOMAIN = 0x0000;

// ArkTS VM 堆异步采样 Worker（独立子线程）。
// hidebug.getAppVMMemoryInfo()/getAppMemoryLimit() 无 native 等价 API（见 hidebug_type.h，
// HiDebug_NativeMemInfo/HiDebug_MemoryLimit 无 JS 堆字段），唯一数据源是 ArkTS NAPI；
// 主线程 2s 热循环直调会经 FFRT 退避触发 THREAD_BLOCK_6S ANR。故挪进 Worker 线程采样，
// onmessage 回主线程调 setArkTsMemoryCacheInterop 灌 Cangjie 缓存，主线程零 hidebug 调用。
let arkTsHeapWorker: worker.ThreadWorker | null = null;

function startArkTsHeapSampler(): void {
  if (arkTsHeapWorker) {
    return;
  }
  arkTsHeapWorker = new worker.ThreadWorker('../workers/ArkTsHeapWorker');
  arkTsHeapWorker.onmessage = (e: MessageEvents): void => {
    // Worker 采到 {heapUsed, vmHeapLimit}（KB），在主线程 onmessage 灌缓存，
    // 与 doMemorySample 读同线程，无并发写。
    const data = e.data as ArkTsHeapSample;
    setArkTsMemoryCacheInterop(
      Math.max(0, Math.floor(data.heapUsed)),
      Math.max(0, Math.floor(data.vmHeapLimit))
    );
  };
  arkTsHeapWorker.onerror = (e: ErrorEvent): void => {
    hilog.warn(DOMAIN, 'memory', 'ArkTsHeapWorker error: %{public}s', e.message);
  };
  arkTsHeapWorker.postMessage('start');
  hilog.info(DOMAIN, 'memory', 'ArkTsHeapWorker started');
}

function stopArkTsHeapSampler(): void {
  if (!arkTsHeapWorker) {
    return;
  }
  arkTsHeapWorker.postMessage('stop');
  arkTsHeapWorker.terminate();
  arkTsHeapWorker = null;
  hilog.info(DOMAIN, 'memory', 'ArkTsHeapWorker stopped');
}

interface ArkTsHeapSample {
  heapUsed: number
  vmHeapLimit: number
}

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.error(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    const lastExitMessage = launchParam?.lastExitMessage ?? 'unknown';
    const lastExitReasonValue = launchParam?.lastExitReason ?? 0; // 0 = UNKNOWN

    initExitInfoHandler(
      lastExitMessage,
      lastExitReasonValue,
      (exitInfo) => {
        hilog.error(0x0000, 'exitInfo', `ExitInfo: message=${exitInfo.exitMessage}, reason=${exitInfo.exitReason}, appState=${exitInfo.appState}, isBackground=${exitInfo.isBackground}`);
      },
      (appStateInfo) => {
        hilog.error(0x0000, 'exitInfo', `AppStateInfo: state=${appStateInfo.appState}, timestamp=${appStateInfo.timestamp}`);
      }
    );

    initSwipeKillHandler(
      this.context,
      lastExitReasonValue,
      (swipeKillInfo) => {
        hilog.error(0x0000, 'swipeKill', `SwipeKillInfo: timestamp=${swipeKillInfo.timestamp}, isUserSwipeKill=${swipeKillInfo.isUserSwipeKill}, exitInfo=${swipeKillInfo.exitInfo}`);
      },
      5000
    );

initCrashHandler(
      this.context.getApplicationContext(),
      this.context.cacheDir,
      new CrashCallbacks(
        data => {
          hilog.error(DOMAIN, 'hm_metricx_cj', 'crash fix === Crash Info ===');
          hilog.error(DOMAIN, 'hm_metricx_cj', 'crash fix rawFile: %{public}s', data.rawFile);

          // 供首页展示上次崩溃（重启后 reportLastCrash 回吐的那一次）
          try {
            AppStorage.setOrCreate<string>('lastCrashText', data.rawFile ?? '');
          } catch (e) {
            hilog.error(DOMAIN, 'hm_metricx_cj', 'set lastCrashText failed: %{public}s', `${e}`);
          }

          if (data.rawheapFilePath) {
            hilog.error(DOMAIN, 'hm_metricx_cj', 'crash fix === OOM Info ===');
            hilog.error(DOMAIN, 'hm_metricx_cj', 'crash fix rawheapFilePath: %{public}s', data.rawheapFilePath);
            hilog.error(DOMAIN, 'hm_metricx_cj', 'crash fix rawheapTimestamp: %{public}s', data.rawheapTimestamp);
            hilog.error(DOMAIN, 'hm_metricx_cj', 'crash fix rawheapResourceType: %{public}s', data.rawheapResourceType);
            hilog.error(DOMAIN, 'hm_metricx_cj', 'crash fix rawheapMemoryLimit: ' + data.rawheapMemoryLimit);
            hilog.error(DOMAIN, 'hm_metricx_cj', 'crash fix rawheapCurrentMemory: ' + data.rawheapCurrentMemory);
            hilog.error(DOMAIN, 'hm_metricx_cj', 'crash fix rawheapLogMessage: %{public}s', data.rawheapLogMessage);
          }
        },
        () => "{}"
      ),
      new CrashConfig(new CMemMonitorConfig(data => false), 1000, 1000)
    );
    initFreezeHandler(
      () => "{}",
      data => {
        hilog.error(DOMAIN, 'hm_metricx_cj', 'freeze info %{public}s', data.rawFile);
        // 供首页展示上次 freeze（重启后回吐）
        try {
          AppStorage.setOrCreate<string>('lastFreezeText', data.rawFile ?? '');
        } catch (e) {
          hilog.error(DOMAIN, 'hm_metricx_cj', 'set lastFreezeText failed: %{public}s', `${e}`);
        }
      },
      this.context.cacheDir
    );
    initThermalHandler(
      this.context,
      (info) => {
        hilog.error(0x0000, 'thermal',
          `pageName=${info.pageName}, level=${info.level}, ` +
            `levelName=${info.levelName}, levelChange=${info.levelChange}, ` +
            `threshold=${info.threshold}, isForeground=${info.isForeground}, ` +
            `durationMs=${info.durationMs}, cpuNum=${info.cpuNum}`
        );
        // 回吐 store，供首页 ThermalInfoCard 展示（不再恒为初始值）
        thermalTestStore.reportCount += 1;
        thermalTestStore.lastLevel = info.level;
        thermalTestStore.lastLevelName = info.levelName;
        thermalTestStore.lastPageName = info.pageName;
        thermalTestStore.lastDurationMs = info.durationMs;
        thermalTestStore.lastTimestamp = info.timestamp;
        thermalTestStore.lastIsForeground = info.isForeground;
        // demo 断言：cpuNum 取值逻辑在 Cangjie 侧(getProcessorCount)，ohosTest 无法直接测，
        // 在发热回调里校验产出：cpuNum 应为正数。
        if (info.cpuNum !== undefined && info.cpuNum > 0) {
          hilog.info(0x0000, 'thermal', 'cpuNum check pass: %{public}d', info.cpuNum);
        } else {
          hilog.error(0x0000, 'thermal', 'cpuNum check FAIL: %{public}d', info.cpuNum);
        }
      },
      1000,  // 1s，先把周期调短验证链路
      1000, // 1s
      0
    );
    hilog.error(0x0000, 'thermal', 'initThermalHandler called in EntryAbility');
    initTrafficHandler(
      this.context,
      data => {
        hilog.error(0x0000, 'traffic', '=== 实时流量上报 ===');
        hilog.error(0x0000, 'traffic', `total: ${data.systemInfo.total}`);
      },
      data => {
        hilog.error(0x0000, 'traffic', '=== 昨日流量上报 ===');
        hilog.error(0x0000, 'traffic', `date: ${data.date}`);
        hilog.error(0x0000, 'traffic', `total: ${data.total}, up: ${data.upTotal}, down: ${data.downTotal}`);
      },
      5000,
      5
    );
    initStorageHandler(
      data => {},
      1,
      1);
    initCpuHandler(
      this.context, data => {
    },
      data => {
      });
    // 测试：自定义更短的间隔用于验证（5 秒采样，15 秒上报，10 秒保存）
    // 注意：生产环境请注释掉以下测试代码，使用上述默认值

    initMemoryHandler(
      this.context,
      data => {
        hilog.error(
          0x0000,
          'memory',
          'memory page data: %{public}s',
          `pageName = ${data.pageName}, avgMemory = ${data.avgMemory}, maxMemory = ${data.maxMemory}, ` +
            `avgCJMemory = ${data.avgCJMemory}, maxCJMemory = ${data.maxCJMemory}, ` +
            `avgArkTsMemory = ${data.avgArkTsMemory}, maxArkTsMemory = ${data.maxArkTsMemory}, ` +
            `sampleCount = ${data.sampleCount}, ` +
            `totalMemoryLimit = ${data.totalMemoryLimit}, cjMemoryLimit = ${data.cjMemoryLimit}, arkTsMemoryLimit = ${data.arkTsMemoryLimit}, ` +
            `isTotalTop = ${data.isTotalTop}, isCJTop = ${data.isCJTop}, isArkTsTop = ${data.isArkTsTop}, ` +
            `memoryAvgUsageRate = ${data.memoryAvgUsageRate}, memoryMaxUsageRate = ${data.memoryMaxUsageRate}, ` +
            `cjMemoryAvgUsageRate = ${data.cjMemoryAvgUsageRate}, cjMemoryMaxUsageRate = ${data.cjMemoryMaxUsageRate}, ` +
            `arkTsMemoryAvgUsageRate = ${data.arkTsMemoryAvgUsageRate}, arkTsMemoryMaxUsageRate = ${data.arkTsMemoryMaxUsageRate}`
        );
      },
      data => {
        hilog.error(
          0x0000,
          'memory',
          'memory process data: %{public}s',
          `pid = ${data.pid}, avgMemory = ${data.avgMemory}, maxMemory = ${data.maxMemory}, ` +
            `avgCJMemory = ${data.avgCJMemory}, maxCJMemory = ${data.maxCJMemory}, ` +
            `avgArkTsMemory = ${data.avgArkTsMemory}, maxArkTsMemory = ${data.maxArkTsMemory}, ` +
            `sampleCount = ${data.sampleCount}, ` +
            `totalMemoryLimit = ${data.totalMemoryLimit}, cjMemoryLimit = ${data.cjMemoryLimit}, arkTsMemoryLimit = ${data.arkTsMemoryLimit}, ` +
            `isTotalTop = ${data.isTotalTop}, isCJTop = ${data.isCJTop}, isArkTsTop = ${data.isArkTsTop}, ` +
            `memoryAvgUsageRate = ${data.memoryAvgUsageRate}, memoryMaxUsageRate = ${data.memoryMaxUsageRate}, ` +
            `cjMemoryAvgUsageRate = ${data.cjMemoryAvgUsageRate}, cjMemoryMaxUsageRate = ${data.cjMemoryMaxUsageRate}, ` +
            `arkTsMemoryAvgUsageRate = ${data.arkTsMemoryAvgUsageRate}, arkTsMemoryMaxUsageRate = ${data.arkTsMemoryMaxUsageRate}`
        );
      },
      100 * 1024,
      5 * 1000,       // sampleInterval: 5 秒（测试用）
      6 * 1000,      // reportInterval: 15 秒（测试用）
      10 * 1000,       // saveInterval: 10 秒（测试用）
      0.6,
      0.6,
      0.6,
      startArkTsHeapSampler,   // ArkTS VM 堆异步采样（Worker 线程，防主线程 ANR）
      stopArkTsHeapSampler
    );
    hilog.info(0x0000, 'memory', '测试：initMemoryHandler 使用自定义间隔 (5s/15s/10s)');

    initBatteryHandler(
      this.context,
      data => {
      },
      data => {
      });

    // 高 CPU 占用监控初始化
    initHighCpuMonitorHandler(
      this.context,
      new HighCpuMonitorConfig(
        0.05,        // cpuThreshold: 线程级阈值 0.05（线程占进程 CPU 比例≥5% 才抓栈，挡住主线程/hilog/采样自身的偶发抖动；单 Worker 烧单核时占进程 CPU≈8%+，稳定命中）
        1000,        // foregroundIntervalMs: 前台 1 秒采样
        2000,        // backgroundIntervalMs: 后台 2 秒采样
        30000,       // monitorDurationMs: 30000 毫秒 (30 秒) 上报一次
        60000,       // threadCooldownMs: 线程 60 秒 cooldown
        3000,        // globalCooldownMs: 全局 3 秒 cooldown
        0.85,        // highSampleRatioThreshold: 85% 高采样比例阈值
        10           // topNThreads: 保留 Top10 线程
      ),
      (reportInfo: HighCpuReportInfo) => {
        hilog.warn(DOMAIN, 'HighCpuMonitor', '===== 高 CPU 占用上报 =====');
        hilog.warn(DOMAIN, 'HighCpuMonitor', `时间：${reportInfo.timestamp}`);
        hilog.warn(DOMAIN, 'HighCpuMonitor', `进程：${reportInfo.processName} (PID: ${reportInfo.pid})`);
        hilog.warn(DOMAIN, 'HighCpuMonitor', `页面：${reportInfo.pageName}`);
        hilog.warn(DOMAIN, 'HighCpuMonitor', `进程平均 CPU: ${reportInfo.avgProcessCpu}`);
        hilog.warn(DOMAIN, 'HighCpuMonitor', `进程最大 CPU: ${reportInfo.maxProcessCpu}`);
        hilog.warn(DOMAIN, 'HighCpuMonitor', `监控时长：${reportInfo.monitorDuration}毫秒`);
        hilog.warn(DOMAIN, 'HighCpuMonitor', `高占用线程数：${reportInfo.highCpuThreads.length}`);

        for (const threadInfo of reportInfo.highCpuThreads) {
          hilog.warn(DOMAIN, 'HighCpuMonitor', '--- 线程信息 ---');
          hilog.warn(DOMAIN, 'HighCpuMonitor', `  TID: ${threadInfo.tid}`);
          hilog.warn(DOMAIN, 'HighCpuMonitor', `  线程名：${threadInfo.threadName}`);
          hilog.warn(DOMAIN, 'HighCpuMonitor', `  平均 CPU: ${threadInfo.avgCpuUsage}`);
          hilog.warn(DOMAIN, 'HighCpuMonitor', `  最大 CPU: ${threadInfo.maxCpuUsage}`);
          hilog.warn(DOMAIN, 'HighCpuMonitor', `  采样次数：${threadInfo.sampleCount}`);
          hilog.warn(DOMAIN, 'HighCpuMonitor', `  高采样比例：${threadInfo.highSampleCount / threadInfo.sampleCount}`);
          hilog.warn(DOMAIN, 'HighCpuMonitor', `  首次检测时间：${threadInfo.firstDetectedTime}`);
          hilog.warn(DOMAIN, 'HighCpuMonitor', `  模块名：${threadInfo.moduleName}`);
          hilog.warn(DOMAIN, 'HighCpuMonitor', `  调用栈：\n${threadInfo.stackTrace}`);
        }
      }
    );
    hilog.info(DOMAIN, 'HighCpuMonitor', '高 CPU 监控已启动（生产模式：33 秒上报，30% 阈值，85% 高采样比例）');

    // 后台活动超长率监控初始化
    initBackgroundCpuMonitorHandler(
      this.context,
      new BackgroundCpuMonitorConfig(
        0.05,           // CPU 利用率阈值 5%
        10000,           // 10 秒触发 WARN
        30000,           // 30 秒触发 ERROR
        60000,          // 60 秒触发 FATAL
        1000,            // 1 秒采样一次
        5000            // 5 秒滑动窗口
      ),
      (reportInfo: BackgroundCpuReportInfo) => {
        hilog.warn(DOMAIN, 'BackgroundCpuMonitor', '===== 后台 CPU 活动超长率上报 =====');
        hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `时间：${reportInfo.timestamp}`);
        hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `进程：${reportInfo.processName} (PID: ${reportInfo.pid})`);
        hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `异常级别：${reportInfo.level}`);
        hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `后台时长：${reportInfo.backgroundDuration}ms`);
        hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `平均 CPU: ${reportInfo.avgCpuUsage}`);
        hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `最大 CPU: ${reportInfo.maxCpuUsage}`);
        hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `滑动窗口采样数：${reportInfo.windowSamples.length}`);

        // 打印滑动窗口数据
        for (const sample of reportInfo.windowSamples) {
          hilog.warn(DOMAIN, 'BackgroundCpuMonitor', '--- 窗口采样 ---');
          hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `  时间戳：${sample.timestamp}`);
          hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `  CPU 使用率：${sample.cpuUsage}`);
          hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `  后台时长：${sample.duration}ms`);
        }

        // 打印高占用线程调用栈
        for (const threadInfo of reportInfo.highCpuThreads) {
          hilog.warn(DOMAIN, 'BackgroundCpuMonitor', '--- 高占用线程 ---');
          hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `  TID: ${threadInfo.tid}`);
          hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `  线程名：${threadInfo.threadName}`);
          hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `  模块名：${threadInfo.moduleName}`);
          hilog.warn(DOMAIN, 'BackgroundCpuMonitor', `  调用栈：\n${threadInfo.stackTrace}`);
        }
      }
    );
    hilog.info(DOMAIN, 'BackgroundCpuMonitor', '后台 CPU 监控已启动');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    destroyMemoryHandler();
    destroyCpuHandler();
    destroyBatteryHandler();
    destroyTrafficHandler();
    destroyHighCpuMonitorHandler();
    destroyBackgroundCpuMonitorHandler();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

    windowStage.getMainWindow().then((win) => {
      initPageEventHandler(this.context, windowStage, data => {
        // 页面退出时上报 FPS（manual 姿势），回吐 AppStorage 供首页展示
        AppStorage.setOrCreate<string>('lastFpsInfo',
          `pageName=${data.pageName}, minFps=${data.minFps}, avgFps=${data.avgFps}`);
      });
    initScrollEventHandler(this.context, data => {
      // 滑动停止时上报掉帧率（manual 姿势），回吐 AppStorage 供首页展示
      AppStorage.setOrCreate<string>('lastScrollHitchInfo',
        `pageName=${data.pageName}, minFps=${data.minFps}, avgFps=${data.avgFps}, ` +
          `frameDropRatio=${data.frameDropRatio}, jankRate=${data.jankRate}, ` +
          `bigJankRate=${data.bigJankRate}, totalFrameCount=${data.totalFrameCount}, ` +
          `targetFPS=${data.targetFPS}`);
    });
    initLaggyHandler(this.context, windowStage, 100, 100, data => {
    }, data => {
    });

    // 初始化白屏检测
    initWhiteScreenHandler(
      this.context,
      windowStage,
      win,
      new WhiteScreenConfig(
        'whiteScreenTestRoot',  // rootComponentId
        1000,                   // ttidTimeoutMs
        3000,                   // frameCheckDurationMs
        800,                    // backgroundFirstSnapshotDelayMs
        1800,                   // backgroundSecondSnapshotDelayMs
        3000,                   // backgroundRecentPageEnterThresholdMs
        30,                     // minFrameCountThreshold
        2,                      // maxDistinctColorCount
        245,                    // whiteRgbThreshold
        0.1,                    // snapshotScale
        0.08,                   // snapshotRegionTop
        0.08,                   // snapshotRegionBottom
        true                    // autoWriteFaultLog
      ),
      (info: WhiteScreenEventInfo) => {
        hilog.warn(DOMAIN, 'WhiteScreen', `===== 白屏检测上报 =====`);
        hilog.warn(DOMAIN, 'WhiteScreen', `页面：${info.pageName}`);
        hilog.warn(DOMAIN, 'WhiteScreen', `类型：${info.whiteScreenType}`);
        hilog.warn(DOMAIN, 'WhiteScreen', `场景：${info.whiteScreenScene}`);
        hilog.warn(DOMAIN, 'WhiteScreen', `应用状态：${info.appState}`);
        hilog.warn(DOMAIN, 'WhiteScreen', `TTID：${info.ttid}ms`);
        hilog.warn(DOMAIN, 'WhiteScreen', `后台耗时：${info.backgroundElapsedMs}ms`);
        hilog.warn(DOMAIN, 'WhiteScreen', `前台去重颜色数：${info.foregroundDistinctColorCount}`);
        hilog.warn(DOMAIN, 'WhiteScreen', `前台主色白色：${info.foregroundMainColorWhite}`);
        hilog.warn(DOMAIN, 'WhiteScreen', `后台第1次去重颜色数：${info.backgroundFirstDistinctColorCount}`);
        hilog.warn(DOMAIN, 'WhiteScreen', `后台第2次去重颜色数：${info.backgroundSecondDistinctColorCount}`);
        hilog.warn(DOMAIN, 'WhiteScreen', `后台第1次主色白色：${info.backgroundFirstMainColorWhite}`);
        hilog.warn(DOMAIN, 'WhiteScreen', `后台第2次主色白色：${info.backgroundSecondMainColorWhite}`);
        hilog.warn(DOMAIN, 'WhiteScreen', `后台检测原因：${info.backgroundDetectionReason}`);
        hilog.warn(DOMAIN, 'WhiteScreen', `N秒内帧数：${info.frameCountInNSeconds}`);
      }
    );

    // 初始化首帧渲染时间监控
    initFirstRenderTimeHandler(
      this.context,
      win,
      new FirstRenderTimeConfig(),
      (info) => {
        hilog.warn(DOMAIN, 'firstRenderTime', `===== 首帧渲染上报 =====`);
        hilog.warn(DOMAIN, 'firstRenderTime', `First Render Time: startTime=${info.startTime}, endTime=${info.endTime}, duration=${info.duration}ms, page=${info.targetPage}`);
      }
    );
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');

    // 销毁首帧渲染时间监控
    destroyFirstRenderTimeHandler();
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}