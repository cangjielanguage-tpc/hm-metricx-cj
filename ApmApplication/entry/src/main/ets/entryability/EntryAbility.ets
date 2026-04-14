import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

import {
  CMemMonitorConfig,
  OOMHandlerMode,
  initCpuHandler,
  initCrashHandler,
  initStorageHandler,
  initTrafficHandler,
  initExitInfoHandler,
  initFreezeHandler,
  initMemoryHandler,
  destroyMemoryHandler,
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
  initBackgroundCpuMonitorHandler,
  destroyBackgroundCpuMonitorHandler,
  BackgroundCpuMonitorConfig,
  BackgroundCpuReportInfo
} from '@cangjie-tpc/hm_metricx_cj_hybrid';

const DOMAIN = 0x0000;

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

    initCrashHandler(
      this.context.getApplicationContext(),
      () => "{}",
      data => hilog.error(DOMAIN, 'hm_metricx_cj', 'crash rawFile: ' + data.rawFile),
      this.context.cacheDir,
      OOMHandlerMode.ASYNC,
      1000,
      1000,
      new CMemMonitorConfig(data => false)
    );
    initFreezeHandler(
      () => "{}",
      data => hilog.error(DOMAIN, 'hm_metricx_cj', 'freeze info %{public}s', data.rawFile),
      this.context.cacheDir
    );
    initThermalHandler(
      this.context,
      (info) => {
        hilog.error(0x0000, 'thermal',
          `pageName=${info.pageName}, level=${info.level}, levelName=${info.levelName}, ` +
            `threshold=${info.threshold}, isForeground=${info.isForeground}, durationMs=${info.durationMs}`
        );
      },
      1000,  // 1s，先把周期调短验证链路
      1000, // 1s
      0
    );
    hilog.error(0x0000, 'thermal', 'initThermalHandler called in EntryAbility');
    initTrafficHandler(
      this.context,
      data => {
        hilog.error(
          0x0000,
          'cangjie',
          'traffic data: %{public}s',
          `current_total = ${data.systemInfo.total}, current_upTotal = ${data.systemInfo.upTotal}, current_downTotal = ${data.systemInfo.downTotal}`
        );
      },
      data => {
        hilog.error(
          0x0000,
          'cangjie',
          'traffic data: %{public}s',
          `data.systemInfo.total = ${data.total}
           data.systemInfo.upTotal = ${data.upTotal}
           data.systemInfo.downTotal = ${data.downTotal}
          `
        );
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
      0.6
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
        0.05,        // cpuThreshold: 5% CPU 阈值
        1000,        // foregroundIntervalMs: 前台 1 秒采样
        2000,        // backgroundIntervalMs: 后台 2 秒采样
        33000,       // monitorDurationMs: 33000 毫秒 (33 秒) 上报一次
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
        }
      }
    );
    hilog.info(DOMAIN, 'HighCpuMonitor', '高 CPU 监控已启动（生产模式：33 秒上报，5% 阈值，85% 高采样比例）');

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

    windowStage.getMainWindow().then(() => {
      initPageEventHandler(this.context, windowStage, data => {
      });
      initScrollEventHandler(this.context, data => {
      });
      initLaggyHandler(this.context, windowStage, 100, 100, data => {
      }, data => {
      });
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
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