import { AbilityConstant, bundleManager, common, errorManager } from '@kit.AbilityKit';
import { ApplicationStateChangeCallback, appManager } from '@kit.AbilityKit';
import { requireCJLib } from 'libark_interop_loader.so';
import {
  CustomLib,
  InteropCrashInfo as CrashInfo,
  InteropFreezeInfo as FreezeInfo,
  InteropSampleTrafficInfo as SampleTrafficInfo,
  InteropStorageInfo,
  TrafficPreference,
  InteropProcessCpuInfo as ProcessCpuInfo,
  InteropPageCpuInfo as PageCpuInfo,
  MemoryPreference,
  InteropPageMemoryInfo as PageMemoryInfo,
  InteropProcessMemoryInfo as ProcessMemoryInfo,
  InteropBatteryUsageInfo as BatteryUsageInfo,
  BatteryInfoInterface,
  InteropAllThreadCpuUsageInfo as AllThreadCpuUsageInfo,
  FpsEventInfo,
  ScrollHitchInfo,
  ClickInfo,
  ResponseEvent,
  InteropPageResponseLaggyModel as PageResponseLaggyModel,
  DisplaySyncInterface,
  Logger
} from 'libark_interop_api.so';
import { preferences } from '@kit.ArkData';
import { uiObserver, window } from '@kit.ArkUI';
import { statistics } from '@kit.NetworkKit';
import { storageStatistics } from '@kit.CoreFileKit';
import { hidebug, hilog } from '@kit.PerformanceAnalysisKit';
import { batteryInfo, BusinessError, settings } from '@kit.BasicServicesKit';
import { displaySync } from '@kit.ArkGraphics2D';

const cjLib = requireCJLib('libohos_app_cangjie_hm_metricx_cj.wrapper.so') as CustomLib;
const DOMAIN = 0x0021;
const TAG = 'hm_metricx_cj';
let logger: Logger = {
  warn: (content: string): void => hilog.warn(DOMAIN, TAG, content),
  info: (content: string): void => hilog.info(DOMAIN, TAG, content),
};
cjLib.initLogger(logger);

export class CMemMonitorConfig {
  shouldBeClusteredToThisSo: (so: string) => boolean

  constructor(shouldBeClusteredToThisSo: (so: string) => boolean) {
    this.shouldBeClusteredToThisSo = shouldBeClusteredToThisSo
  }
}

let uid = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).appInfo.uid;

let getUidRxAndTxBytes = (cb: (rxBytes: number, txBytes: number) => void) => {
  statistics.getUidRxBytes(uid).then(rxBytes => {
    statistics.getUidTxBytes(uid).then(txBytes => cb(rxBytes, txBytes));
  });
};

let offTraffic = () => {
};

let clearSampleTraffic = () => {
};

export function initTrafficHandler(
  context: common.UIAbilityContext,
  reportTraffic: (data: SampleTrafficInfo) => void,
  sampleTime: number = 10 * 60 * 1000,
  sampleThreshold: number = 50 * 1024 * 1024
): void {
  let preference = preferences.getPreferencesSync(context, { name: 'hm_metricx_cj:Traffic' });
  let p: TrafficPreference = {
    put: (key: string, value: string): void => {
      preference.putSync(key, value);
      preference.flushSync();
    },
    has: (key: string): boolean => preference.hasSync(key),
    get: (key: string, defaultValue: string): string => preference.getSync(key, defaultValue) as string
  };
  let onNavDestinationSwitch = (cb: (targetPageName: string) => void) => {
    let callback = (info: uiObserver.NavDestinationSwitchInfo) => cb(getTargetPageName(info));
    uiObserver.on('navDestinationSwitch', context, callback);
    offTraffic = () => uiObserver.off('navDestinationSwitch', context, callback);
  };
  let repeatSampleTraffic = (sample: () => void) => {
    let id = setInterval(sample, sampleTime);
    clearSampleTraffic = () => clearInterval(id);
  };
  cjLib.initTrafficHandler(p, onNavDestinationSwitch, repeatSampleTraffic, getUidRxAndTxBytes, reportTraffic,
    sampleThreshold);
}

export function destroyTrafficHandler(): void {
  clearSampleTraffic();
  offTraffic();
  cjLib.destroyTrafficHandler(getUidRxAndTxBytes);
}

export function initStorageHandler(reportStorageInfo: (data: InteropStorageInfo) => void, sizeLimit: number,
  dirSizeLimit: number,
  reportTopNum: number = 5): void {
  cjLib.initStorageHandler(reportStorageInfo, sizeLimit, dirSizeLimit, reportTopNum);
}

export function reportAppStorageInfo(): void {
  let getCurrentBundleStats = (onData: (appSize: number, dataSize: number, cacheSize: number) => void) => {
    storageStatistics.getCurrentBundleStats((err: BusinessError, bundleStats: storageStatistics.BundleStats) => {
      if (err) {
        console.error(`Invoke getCurrentBundleStats failed, code is ${err.code}, message is ${err.message}`);
      } else {
        onData(bundleStats.appSize, bundleStats.dataSize, bundleStats.cacheSize);
      }
    });
  }
  cjLib.reportAppStorageInfo(getCurrentBundleStats);
}

export function getPageCpuInfo(): PageCpuInfo {
  return cjLib.getPageCpuInfo();
}

export function getProcessCpuInfo(): ProcessCpuInfo {
  return cjLib.getProcessCpuInfo();
}

let offCpu = () => {
};
let clearSampleCpu = () => {
};

export function initCpuHandler(
  context: common.UIAbilityContext,
  reportPageCpuInfo: (data: PageCpuInfo) => void,
  reportProcessCpuInfo: (data: ProcessCpuInfo) => void
): void {
  let onNavDestinationSwitch = (cb: (targetPageName: string) => void) => {
    let callback = (info: uiObserver.NavDestinationSwitchInfo) => cb(getTargetPageName(info));
    uiObserver.on('navDestinationSwitch', context, callback);
    offCpu = () => uiObserver.off('navDestinationSwitch', context, callback);
  };
  let repeatSampleAndReportCpu = (sample: () => void, report: () => void) => {
    setTimeout(() => {
      let sampleId = setInterval(sample, 2 * 1000);
      let reportId = setInterval(report, 30 * 60 * 1000);
      clearSampleCpu = () => {
        clearInterval(sampleId);
        clearInterval(reportId);
      }
    }, 2 * 1000);
  };
  cjLib.initCpuHandler(hidebug.getCpuUsage, onNavDestinationSwitch, repeatSampleAndReportCpu, reportPageCpuInfo,
    reportProcessCpuInfo);
}

export function destroyCpuHandler(): void {
  offCpu();
  clearSampleCpu();
}

function getTargetPageName(info: uiObserver.NavDestinationSwitchInfo): string {
  let name = '';
  let to: NavDestinationInfo | NavBar = info.to;
  if (typeof to === 'string') {
    name = 'navRoot';
  } else {
    if (typeof to.name === 'string') {
      name = to.name;
    }
  }
  return name;
}

export enum OOMHandlerMode {
  NONE,
  SYMC,
  ASYNC
}

export function initCrashHandler(applicationContext: common.ApplicationContext,
  collectCrashInfo: () => string,
  reportCrashInfo: (CrashInfo: CrashInfo) => void,
  persistentDir: string,
  enableDumpOnOOM: OOMHandlerMode,
  lastNHilogNumber: number,
  systemLogNumber: number,
  enableMemMonitor?: CMemMonitorConfig
): void {
  let exit = () => {
    applicationContext.killAllProcesses().catch(() => {
      hilog.warn(DOMAIN, 'hm_metricx_cj', 'killAllProcesses failed');
    });
  };
  if (enableMemMonitor != undefined) {
    let memMonitor = new cjLib.CMemMonitorConfig(enableMemMonitor!.shouldBeClusteredToThisSo);
    cjLib.initCrashHandler(exit, collectCrashInfo, reportCrashInfo, persistentDir, enableDumpOnOOM, lastNHilogNumber,
      systemLogNumber, memMonitor);
  } else {
    cjLib.initCrashHandler(exit, collectCrashInfo, reportCrashInfo, persistentDir, enableDumpOnOOM, lastNHilogNumber,
      systemLogNumber, undefined);
  }
}

export function getExitInfo(launchParam: AbilityConstant.LaunchParam): void {
  cjLib.getExitInfo(launchParam.lastExitMessage, launchParam.lastExitReason);
}

export function initFreezeHandler(
  collectFreezeInfo: () => string,
  reportFreezeInfo: (freezeInfo: FreezeInfo) => void,
  persistentDir: string
): void {

  let onFreeze = (cb: () => void) => {
    errorManager.on('freeze', cb);
  };
  cjLib.initFreezeHandler(onFreeze, collectFreezeInfo, reportFreezeInfo, persistentDir);
}

let offMemory = () => {
};
let clearSampleMemory = () => {
};

function getMemoryUsage(): number {
  return Number(hidebug.getPss());
}

export function initMemoryHandler(
  context: common.UIAbilityContext,
  reportPageMemoryInfo: (data: PageMemoryInfo) => void,
  reportProcessMemoryInfo: (data: ProcessMemoryInfo) => void,
  memoryThreshold: number
): void {
  let preference = preferences.getPreferencesSync(context, { name: 'hm_metricx_cj:Memory' });
  let p: MemoryPreference = {
    put: (key: string, value: number): void => {
      preference.putSync(key, value);
      preference.flushSync();
    },
    has: (key: string): boolean => preference.hasSync(key),
    get: (key: string, defaultValue: number): number => preference.getSync(key, defaultValue) as number
  };

  let onNavDestinationSwitch = (cb: (targetPageName: string) => void) => {
    let callback = (info: uiObserver.NavDestinationSwitchInfo) => cb(getTargetPageName(info));
    uiObserver.on('navDestinationSwitch', context, callback);
    offMemory = () => uiObserver.off('navDestinationSwitch', context, callback);
  };
  let repeatSampleAndReportMemory = (sample: () => void, report: () => void) => {
    setTimeout(() => {
      let sampleId = setInterval(sample, 2 * 1000);
      let reportId = setInterval(report, 30 * 60 * 1000);
      clearSampleMemory = () => {
        clearInterval(sampleId);
        clearInterval(reportId);
      }
    }, 2 * 1000);
  };
  cjLib.initMemoryHandler(p, getMemoryUsage, onNavDestinationSwitch, repeatSampleAndReportMemory, reportPageMemoryInfo,
    reportProcessMemoryInfo, memoryThreshold);
}

export function destroyMemoryHandler(): void {
  offMemory();
  clearSampleMemory();
  cjLib.destroyMemoryHandler();
}

let offBatteryHandlerCallback = () => {
};
let clearCpuUsageHandler = () => {
};

export function initBatteryHandler(
  context: common.UIAbilityContext,
  reportBatterInfo: (data: BatteryUsageInfo) => void,
  reportThreadCpuUsageInfo: (data: AllThreadCpuUsageInfo) => void,
  limit: number = 1
): void {
  let onApplicationStateChange = (onForeground: () => void, onBackground: () => void) => {
    let applicationStateChageCallback: ApplicationStateChangeCallback = {
      onApplicationForeground() {
        onForeground();
      },
      onApplicationBackground() {
        onBackground();
      }
    };
    context.getApplicationContext().on('applicationStateChange', applicationStateChageCallback);
  };
  let onAbilityForeGround = (cb: () => void) => {
    context.getApplicationContext().on('abilityLifecycle', {
      onAbilityCreate() {
      },
      onWindowStageCreate() {
      },
      onWindowStageActive() {
      },
      onWindowStageInactive() {
      },
      onWindowStageDestroy() {
      },
      onAbilityDestroy() {
      },
      onAbilityForeground() {
        cb();
      },
      onAbilityBackground() {
      },
      onAbilityContinue() {
      }
    });
  };

  let getRunningProcessInfo = (cb: (status: boolean) => void) => {
    context.getApplicationContext().getRunningProcessInformation().then(data => {
      let processStatus = false;
      for (let item of data) {
        if (item.state == appManager.ProcessState.STATE_BACKGROUND) {
          processStatus = true;
        } else if (item.state == appManager.ProcessState.STATE_FOREGROUND) {
          processStatus = false;
          break;
        }
      }
      cb(processStatus);
    })
  };
  let onNavDestinationSwitch = (cb: (targetPageName: string) => void) => {
    let callback = (info: uiObserver.NavDestinationSwitchInfo) => cb(getTargetPageName(info));
    uiObserver.on('navDestinationSwitch', context, callback);
    offBatteryHandlerCallback = () => uiObserver.off('navDestinationSwitch', context, callback);
  };

  let batteryInterface: BatteryInfoInterface = {
    getBatterySOC: (): number => {
      return batteryInfo.batterySOC;
    },
    getChargingStatus: (): number => {
      let status = batteryInfo.chargingStatus;
      if (batteryInfo.BatteryChargeState.NONE == status) {
        return 1;
      } else if (batteryInfo.BatteryChargeState.ENABLE == status) {
        return 2;
      } else if (batteryInfo.BatteryChargeState.DISABLE == status) {
        return 4;
      } else if (batteryInfo.BatteryChargeState.FULL == status) {
        return 5;
      }
      return 0;
    },
    getHealthStatus: (): number => {
      let status = batteryInfo.healthStatus
      if (batteryInfo.BatteryHealthState.UNKNOWN == status) {
        return 1;
      } else if (batteryInfo.BatteryHealthState.GOOD == status) {
        return 2;
      } else if (batteryInfo.BatteryHealthState.OVERHEAT == status) {
        return 3;
      } else if (batteryInfo.BatteryHealthState.OVERVOLTAGE == status) {
        return 5;
      } else if (batteryInfo.BatteryHealthState.COLD == status) {
        return 7;
      } else if (batteryInfo.BatteryHealthState.DEAD == status) {
        return 4;
      }
      return 0;
    },
    getPluggedType: (): number => {
      let type = batteryInfo.pluggedType
      if (batteryInfo.BatteryPluggedType.NONE === type) {
        return 0;
      } else if (batteryInfo.BatteryPluggedType.AC === type) {
        return 1;
      } else if (batteryInfo.BatteryPluggedType.USB === type) {
        return 2;
      } else if (batteryInfo.BatteryPluggedType.WIRELESS === type) {
        return 4;
      }
      return 0;
    },
    getVoltage: (): number => {
      return batteryInfo.voltage;
    },
    getTechnology: (): string => {
      return batteryInfo.technology;
    },
    getBatteryTemperature: (): number => {
      return batteryInfo.batteryTemperature;
    }
  };

  let getBrightness = (): number => {
    return Number.parseInt(settings.getValueSync(context, settings.display.SCREEN_BRIGHTNESS_STATUS, '0'));
  };

  let repeatHandlerCpuUsage = (handler: () => void) => {
    let id = setInterval(handler, 3 * 60 * 1000);
    clearCpuUsageHandler = () => clearInterval(id);
  };
  cjLib.initBatteryHandler(batteryInterface, getBrightness, onApplicationStateChange, onAbilityForeGround,
    onNavDestinationSwitch,
    getRunningProcessInfo, repeatHandlerCpuUsage, reportBatterInfo, reportThreadCpuUsageInfo, limit);
}

export function destroyBatteryHandler(): void {
  offBatteryHandlerCallback();
  clearCpuUsageHandler();
  cjLib.destroyBatteryHandler();
}

export function initScrollEventHandler(
  context: common.UIAbilityContext,
  reportPageScrollInfo: (info: ScrollHitchInfo) => void
): void {

  let scrokkDisplay = displaySync.create();
  let scrollDisplaySyncInterface: DisplaySyncInterface = {
    start: (): void => {
      scrokkDisplay.start();
    },
    stop: (): void => {
      scrokkDisplay.stop();
    },
    on: (cb: (time: number, targetTime: number) => void): void => {
      scrokkDisplay.on('frame', (info: displaySync.IntervalInfo) => {
        cb(info.timestamp, info.targetTimestamp);
      });
    },
    off: (): void => {
      scrokkDisplay.off('frame');
    }
  }

  let onScrollEvent = (onScrollStart: () => void, onScrollStop: () => void) => {
    uiObserver.on('scrollEvent', (info) => {
      if (info.scrollEvent === uiObserver.ScrollEventType.SCROLL_START) {
        onScrollStart();
      } else if (info.scrollEvent === uiObserver.ScrollEventType.SCROLL_STOP) {
        onScrollStop();
      }
    });
  };
  let onNavDestinationSwitch = (cb: (targetPageName: string) => void) => {
    let callback = (info: uiObserver.NavDestinationSwitchInfo) => cb(getTargetPageName(info));
    uiObserver.on('navDestinationSwitch', context, callback);
    offBatteryHandlerCallback = () => uiObserver.off('navDestinationSwitch', context, callback);
  };
  cjLib.initScrollEventHandler(scrollDisplaySyncInterface, onScrollEvent, onNavDestinationSwitch, reportPageScrollInfo);
}

export function initPageEventHandler(
  context: common.UIAbilityContext,
  windowStage: window.WindowStage,
  reportFpsInfo: (info: FpsEventInfo) => void
): void {
  let onNavDestinationSwitch = (cb: (targetPageName: string) => void) => {
    let callback = (info: uiObserver.NavDestinationSwitchInfo) => cb(getTargetPageName(info));
    uiObserver.on('navDestinationSwitch', context, callback);
    offBatteryHandlerCallback = () => uiObserver.off('navDestinationSwitch', context, callback);
  };
  let onWindowEvent = (windowActive: () => void, windowInActive: () => void) => {
    windowStage.getMainWindowSync().on('windowEvent', (data: window.WindowEventType) => {
      if (data === window.WindowEventType.WINDOW_ACTIVE) {
        windowActive();
      } else if (data === window.WindowEventType.WINDOW_INACTIVE) {
        windowInActive();
      }
    });
  };
  cjLib.initPageEventHandler(onNavDestinationSwitch, onWindowEvent, reportFpsInfo);
}

export function initLaggyHanddler(
  context: common.UIAbilityContext,
  windowStage: window.WindowStage,
  maxTime: number,
  maxArraySize: number,
  reportResponseEvent: (info: ResponseEvent) => void,
  reportPageResponseLaggyModel: (info: PageResponseLaggyModel) => void
): void {
  let laggyDisplay = displaySync.create();
  let laggyDisplaySyncInterface: DisplaySyncInterface = {
    start: (): void => {
      laggyDisplay.start();
    },
    stop: (): void => {
      laggyDisplay.stop();
    },
    on: (cb: (time: number, targetTime: number) => void): void => {
      laggyDisplay.on('frame', (info: displaySync.IntervalInfo) => {
        cb(info.timestamp, info.targetTimestamp);
      });
    },
    off: (): void => {
      laggyDisplay.off('frame');
    }
  }
  let onAbilityBackGround = (cb: () => void) => {
    context.getApplicationContext().on('abilityLifecycle', {
      onAbilityCreate() {
      },
      onWindowStageCreate() {
      },
      onWindowStageActive() {
      },
      onWindowStageInactive() {
      },
      onWindowStageDestroy() {
      },
      onAbilityDestroy() {
      },
      onAbilityForeground() {
      },
      onAbilityBackground() {
        cb();
      },
      onAbilityContinue() {
      }
    });
  };

  let onNavDestinationSwitch = (cb: (targetPageName: string) => void) => {
    let callback = (info: uiObserver.NavDestinationSwitchInfo) => cb(getTargetPageName(info));
    uiObserver.on('navDestinationSwitch', context, callback);
    offBatteryHandlerCallback = () => uiObserver.off('navDestinationSwitch', context, callback);
  };

  let onDidClick = (cb: (info: ClickInfo) => void) => {
    windowStage.getMainWindow().then(win => {
      win.getUIContext().getUIObserver().on('didClick', (event: ClickEvent, frameNode?: FrameNode) => {
        let info = new ClickInfo();
        info.timestamp = event.timestamp;
        info.windowX = event.windowX;
        info.windowY = event.windowY;
        info.id = frameNode?.getId() ?? '';
        info.nodeType = frameNode?.getNodeType() ?? '';
        info.hitX = frameNode?.getPositionToWindow().x ?? 0;
        info.hitY = frameNode?.getPositionToWindow().y ?? 0;
        info.hitHeight = frameNode?.getMeasuredSize().height ?? 0;
        info.hitWidth = frameNode?.getMeasuredSize().width ?? 0;
      });
    });
  };
  cjLib.initLaggyHandler(laggyDisplaySyncInterface, onAbilityBackGround, onNavDestinationSwitch,
    onDidClick, maxTime, maxArraySize, reportResponseEvent, reportPageResponseLaggyModel);
}