import { AbilityConstant, bundleManager, common, errorManager } from '@kit.AbilityKit';
import { ApplicationStateChangeCallback, appManager } from '@kit.AbilityKit';
import {thermal} from '@kit.BasicServicesKit';
import { requireCJLib } from 'libark_interop_loader.so';

import {
  CustomLib,
  InteropCrashInfo as CrashInfo,
  InteropFreezeInfo as FreezeInfo,
  InteropSampleTrafficInfo as SampleTrafficInfo,
  InteropStorageInfo as StorageInfo,
  TrafficPreference,
  InteropProcessCpuInfo as ProcessCpuInfo,
  InteropPageCpuInfo as PageCpuInfo,
  MemoryPreference,
  InteropPageMemoryInfo as PageMemoryInfo,
  InteropProcessMemoryInfo as ProcessMemoryInfo,
  InteropBatteryUsageInfo as BatteryUsageInfo,
  BatteryInfoInterface,
  InteropAllThreadCpuUsageInfo as AllThreadCpuUsageInfo,
  InteropThermalEventInfo ,
  ThermalInfoInterface,
  AppHooks,
  FpsEventInfo,
  ScrollHitchInfo,
  ClickInfo,
  ResponseEvent,
  InteropPageResponseLaggyModel as PageResponseLaggyModel,
  DisplaySync,
  Logger,
  ExitInfo,
  InteropDayTrafficInfo as DayTrafficInfo
} from 'libark_interop_api.so';
import { preferences } from '@kit.ArkData';
import { uiObserver, window } from '@kit.ArkUI';
import { statistics } from '@kit.NetworkKit';
import { storageStatistics } from '@kit.CoreFileKit';
import { hiAppEvent, hidebug, hilog } from '@kit.PerformanceAnalysisKit';
import {
  batteryInfo,
  BusinessError,
  commonEventManager,
  deviceInfo,
  settings,
  systemDateTime
} from '@kit.BasicServicesKit';
import { displaySync } from '@kit.ArkGraphics2D';

// ==================== 仓颉库动态加载 ====================

const cjLib = requireCJLib('libohos_app_cangjie_hm_metricx_cj.wrapper.so') as CustomLib;

// 动态加载功能库：如果库不存在则返回 null
function loadCJLibSafe(feature: string): CustomLib | null {
  try {
    return requireCJLib(`libohos_app_cangjie_hm_metricx_cj.${feature}.so`) as CustomLib;
  } catch (e) {
    return null;
  }
}

// 按需加载各功能库（自动判空）
const cjLibBattery = loadCJLibSafe('battery');
const cjLibCpu = loadCJLibSafe('cpu');
const cjLibCrash = loadCJLibSafe('crash');
const cjLibExitInfo = loadCJLibSafe('exitInfo');
const cjLibFps = loadCJLibSafe('fps');
const cjLibFreeze = loadCJLibSafe('freeze');
const cjLibLaggy = loadCJLibSafe('laggy');
const cjLibMemory = loadCJLibSafe('memory');
const cjLibStorage = loadCJLibSafe('storage');
const cjLibThermal = loadCJLibSafe('thermal');
const cjLibTraffic = loadCJLibSafe('traffic');

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

let getUidRxAndTxBytes = (cb: (rxBytes: number, txBytes: number, pageName: string) => void, pageName: string) => {
  statistics.getUidRxBytes(uid).then(rxBytes => {
    statistics.getUidTxBytes(uid).then(txBytes => cb(rxBytes, txBytes, pageName));
  });
};

let offTraffic = () => {
};

let clearSampleTraffic = () => {
};

export function initTrafficHandler(
  context: common.UIAbilityContext,
  reportTraffic: (data: SampleTrafficInfo) => void,
  reportYesterdayTraffic: (data: DayTrafficInfo) => void,
  sampleTime: number = 10 * 60 * 1000,
  sampleThreshold: number = 50 * 1024 * 1024
): void {
  if (!cjLibTraffic) {
    hilog.warn(DOMAIN, TAG, 'initTrafficHandler called but traffic module is disabled');
    return;
  }
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
  cjLibTraffic.initTrafficHandlerInterop(p, onNavDestinationSwitch, repeatSampleTraffic, getUidRxAndTxBytes, reportTraffic,
    reportYesterdayTraffic, sampleThreshold);
}

export function destroyTrafficHandler(): void {
  if (!cjLibTraffic) return;
  clearSampleTraffic();
  offTraffic();
  cjLibTraffic.destroyTrafficHandlerInterop((cb: (rxBytes: number, txBytes: number) => void) => {
    getUidRxAndTxBytes(cb, '');
  });
}

export function initStorageHandler(
  reportStorageInfo: (data: StorageInfo) => void,
  sizeLimit: number,
  dirSizeLimit: number,
  reportTopNum: number = 5): void {
  if (!cjLibStorage) {
    hilog.warn(DOMAIN, TAG, 'initStorageHandler called but storage module is disabled');
    return;
  }
  cjLibStorage.initStorageHandlerInterop(reportStorageInfo, sizeLimit, dirSizeLimit, reportTopNum);
}

export function reportAppStorageInfo(): void {
  if (!cjLibStorage) {
    hilog.warn(DOMAIN, TAG, 'reportAppStorageInfo called but storage module is disabled');
    return;
  }
  let getCurrentBundleStats = (onData: (appSize: number, dataSize: number, cacheSize: number) => void) => {
    storageStatistics.getCurrentBundleStats((err: BusinessError, bundleStats: storageStatistics.BundleStats) => {
      if (err) {
        console.error(`Invoke getCurrentBundleStats failed, code is ${err.code}, message is ${err.message}`);
      } else {
        onData(bundleStats.appSize, bundleStats.dataSize, bundleStats.cacheSize);
      }
    });
  }
  cjLibStorage.reportAppStorageInfoInterop(getCurrentBundleStats);
}

export function getPageCpuInfo(): PageCpuInfo {
  if (!cjLibCpu) {
    hilog.warn(DOMAIN, TAG, 'getPageCpuInfo called but cpu module is disabled');
    return {} as PageCpuInfo;
  }
  return cjLibCpu.getPageCpuInfoInterop();
}

export function getProcessCpuInfo(): ProcessCpuInfo {
  if (!cjLibCpu) {
    hilog.warn(DOMAIN, TAG, 'getProcessCpuInfo called but cpu module is disabled');
    return {} as ProcessCpuInfo;
  }
  return cjLibCpu.getProcessCpuInfoInterop();
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
  if (!cjLibCpu) {
    hilog.warn(DOMAIN, TAG, 'initCpuHandler called but cpu module is disabled');
    return;
  }
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
  cjLibCpu.initCpuHandlerInterop(hidebug.getCpuUsage, onNavDestinationSwitch, repeatSampleAndReportCpu, reportPageCpuInfo,
    reportProcessCpuInfo);
}

export function destroyCpuHandler(): void {
  if (!cjLibCpu) return;
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

export function initCrashHandler(
  applicationContext: common.ApplicationContext,
  collectCrashInfo: () => string,
  reportCrashInfo: (CrashInfo: CrashInfo) => void,
  persistentDir: string,
  enableDumpOnOOM: OOMHandlerMode,
  lastNHilogNumber: number,
  systemLogNumber: number,
  enableMemMonitor?: CMemMonitorConfig
): void {
  if (!cjLibCrash) {
    hilog.warn(DOMAIN, TAG, 'initCrashHandler called but crash module is disabled');
    return;
  }
  let exit = () => {
    applicationContext.killAllProcesses().catch(() => {
      hilog.warn(DOMAIN, 'hm_metricx_cj', 'killAllProcesses failed');
    });
  };
  let onCrash = (cb: () => void) => {
    let index = errorManager.on('error', {
      onUnhandledException(errorMsg) {
      },
      onException(errorObj) {
        cb();
      }
    });
    if (index !== 0) {
      hilog.warn(DOMAIN, 'hm_metricx_cj',
        'There are other error observers registered before crash obsverver, which may interfere with its behavior.');
    }
  };
  let addCrashWatcher =
    (cb: (time: string, pid: string, exception: string, hilog: string, external_log: string, crash_type: string,
      bundle_version: string) => void) => {
      hiAppEvent.addWatcher({
        name: 'crashWatcher',
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.APP_CRASH]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          if (domain !== 'OS') {
            return;
          }
          for (const eventGroup of appEventGroups) {
            if (eventGroup.name !== 'APP_CRASH') {
              continue;
            }
            for (const eventInfo of eventGroup.appEventInfos) {
              let time: number = eventInfo.params['time'];
              let pid: number = eventInfo.params['pid'];
              let exception: string = JSON.stringify(eventInfo.params['exception']);
              let hilogs: string[] = eventInfo.params['hilog'];
              let external_logs: string[] = eventInfo.params['external_log'];
              let crash_type: string = eventInfo.params['crash_type'];
              let bundle_version: string = eventInfo.params['bundle_version'];
              cb(time.toString(), pid.toString(), exception, hilogs.reduce((acc, cur) => acc + '\n' + cur, ''),
                external_logs.length === 0 ? '' : external_logs[0], crash_type, bundle_version);
              break;
            }
            break;
          }
        }
      });
    };
  let memMonitor =
    enableMemMonitor !== undefined ? new cjLibCrash.CMemMonitorConfig(enableMemMonitor!.shouldBeClusteredToThisSo) :
      undefined;
  cjLibCrash.initCrashHandlerInterop(addCrashWatcher, onCrash, exit, collectCrashInfo, reportCrashInfo, persistentDir,
    enableDumpOnOOM,
    lastNHilogNumber,
    systemLogNumber, memMonitor);
}

export function getExitInfo(launchParam: AbilityConstant.LaunchParam): ExitInfo {
  if (!cjLibExitInfo) {
    hilog.warn(DOMAIN, TAG, 'getExitInfo called but exitInfo module is disabled');
    return {} as ExitInfo;
  }
  return cjLibExitInfo.getExitInfoInterop(launchParam.lastExitMessage, launchParam.lastExitReason);
}

export function initFreezeHandler(
  collectFreezeInfo: () => string,
  reportFreezeInfo: (freezeInfo: FreezeInfo) => void,
  persistentDir: string
): void {
  if (!cjLibFreeze) {
    hilog.warn(DOMAIN, TAG, 'initFreezeHandler called but freeze module is disabled');
    return;
  }
  let onFreeze = (cb: () => void) => {
    errorManager.on('freeze', cb);
  };
  let addFreezeWatcher =
    (cb: (time: string, pid: string, exception: string, hilog: string, external_log: string) => void) => {
      hiAppEvent.addWatcher({
        name: 'freezeWatcher',
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.APP_FREEZE]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          if (domain !== 'OS') {
            return;
          }
          for (const eventGroup of appEventGroups) {
            if (eventGroup.name !== 'APP_FREEZE') {
              continue;
            }
            for (const eventInfo of eventGroup.appEventInfos) {
              let time: number = eventInfo.params['time'];
              let pid: number = eventInfo.params['pid'];
              let exception: string = JSON.stringify(eventInfo.params['exception']);
              let hilogs: string[] = eventInfo.params['hilog'];
              let external_logs: string[] = eventInfo.params['external_log'];
              cb(time.toString(), pid.toString(), exception, hilogs.reduce((acc, cur) => acc + '\n' + cur, ''),
                external_logs.length === 0 ? '' : external_logs[0]);
              break;
            }
            break;
          }
        }
      });
    };
  cjLibFreeze.initFreezeHandlerInterop(deviceInfo.sdkApiVersion, addFreezeWatcher, onFreeze, collectFreezeInfo, reportFreezeInfo,
    persistentDir);
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
  if (!cjLibMemory) {
    hilog.warn(DOMAIN, TAG, 'initMemoryHandler called but memory module is disabled');
    return;
  }
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
  let repeatSampleAndReportMemory = (sample: () => void, report: () => void, save: () => void) => {
    setTimeout(() => {
      let sampleId = setInterval(sample, 2 * 1000);
      let reportId = setInterval(report, 30 * 60 * 1000);
      let saveId = setInterval(save, 60 * 1000);
      clearSampleMemory = () => {
        clearInterval(sampleId);
        clearInterval(reportId);
        clearInterval(saveId);
      }
    }, 2 * 1000);
  };
  cjLibMemory.initMemoryHandlerInterop(p, getMemoryUsage, onNavDestinationSwitch, repeatSampleAndReportMemory, reportPageMemoryInfo,
    reportProcessMemoryInfo, memoryThreshold);
}

export function destroyMemoryHandler(): void {
  if (!cjLibMemory) return;
  offMemory();
  clearSampleMemory();
  cjLibMemory.destroyMemoryHandlerInterop();
}

export function getPageMemoryInfo(): PageMemoryInfo {
  if (!cjLibMemory) {
    hilog.warn(DOMAIN, TAG, 'getPageMemoryInfo called but memory module is disabled');
    return {} as PageMemoryInfo;
  }
  return cjLibMemory.getPageMemoryInfoInterop();
}

export function getProcessMemoryInfo(): ProcessMemoryInfo {
  if (!cjLibMemory) {
    hilog.warn(DOMAIN, TAG, 'getProcessMemoryInfo called but memory module is disabled');
    return {} as ProcessMemoryInfo;
  }
  return cjLibMemory.getProcessMemoryInfoInterop();
}

let offBatteryHandlerCallback = () => {
};
let clearCpuUsageHandler = () => {
};
let unsubscribe = () => {
};

export function initBatteryHandler(
  context: common.UIAbilityContext,
  reportBatterInfo: (data: BatteryUsageInfo) => void,
  reportThreadCpuUsageInfo: (data: AllThreadCpuUsageInfo) => void,
  limit: number = 1
): void {
  if (!cjLibBattery) {
    hilog.warn(DOMAIN, TAG, 'initBatteryHandler called but battery module is disabled');
    return;
  }
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
  let getUptime = () => {
    return systemDateTime.getUptime(systemDateTime.TimeType.STARTUP);
  };
  let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
    events: [commonEventManager.Support.COMMON_EVENT_BATTERY_CHANGED,
      commonEventManager.Support.COMMON_EVENT_POWER_CONNECTED,
      commonEventManager.Support.COMMON_EVENT_POWER_DISCONNECTED]
  };
  let subscriber = commonEventManager.createSubscriberSync(subscribeInfo);
  let subscribe = (onBatteryChanged: () => void, onConnected: () => void, onDisconnected: () => void) => {
    commonEventManager.subscribe(subscriber, (err, data) => {
      if (!data || err) {
        hilog.warn(DOMAIN, TAG, err.name + ", " + err.message + ", " + err.code);
        return;
      }
      switch (data.event) {
        case commonEventManager.Support.COMMON_EVENT_BATTERY_CHANGED:
          onBatteryChanged();
          break;
        case commonEventManager.Support.COMMON_EVENT_POWER_CONNECTED:
          onConnected();
          break;
        case commonEventManager.Support.COMMON_EVENT_POWER_DISCONNECTED:
          onDisconnected();
          break;
      }
    });
  };
  unsubscribe = () => {
    commonEventManager.unsubscribe(subscriber);
  };
  cjLibBattery.initBatteryHandlerInterop(subscribe, getUptime, batteryInterface, getBrightness, onApplicationStateChange,
    onAbilityForeGround,
    onNavDestinationSwitch,
    getRunningProcessInfo, repeatHandlerCpuUsage, reportBatterInfo, reportThreadCpuUsageInfo, limit);
}

export function destroyBatteryHandler(): void {
  if (!cjLibBattery) return;
  offBatteryHandlerCallback();
  clearCpuUsageHandler();
  unsubscribe();
}

export function initScrollEventHandler(
  context: common.UIAbilityContext,
  reportPageScrollInfo: (info: ScrollHitchInfo) => void
): void {
  if (!cjLibFps) {
    hilog.warn(DOMAIN, TAG, 'initScrollEventHandler called but fps module is disabled');
    return;
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
  cjLibFps.initScrollEventHandlerInterop(getDisplaySync(), onScrollEvent, onNavDestinationSwitch, reportPageScrollInfo);
}

export function initPageEventHandler(
  context: common.UIAbilityContext,
  windowStage: window.WindowStage,
  reportFpsInfo: (info: FpsEventInfo) => void
): void {
  if (!cjLibFps) {
    hilog.warn(DOMAIN, TAG, 'initPageEventHandler called but fps module is disabled');
    return;
  }
  let onNavDestinationSwitch = (cb: (targetPageName: string) => void) => {
    let callback = (info: uiObserver.NavDestinationSwitchInfo) => cb(getTargetPageName(info));
    uiObserver.on('navDestinationSwitch', context, callback);
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
  cjLibFps.initPageEventHandlerInterop(getDisplaySync(), onNavDestinationSwitch, onWindowEvent, reportFpsInfo);
}

let offThermalHandlerCallback = () => {
};

let offThermalAppStateCallback = () => {
};

let clearSampleThermal = () => {
};

let thermalInited = false;

export function initThermalHandler(
  context: common.UIAbilityContext,
  reportThermalInfo: (info: InteropThermalEventInfo) => void,
  sampleInterval: number = 5 * 1000,
  reportMinInterval: number = 30 * 1000,
  abnormalThreshold: number = 2
): void {
  if (!cjLibThermal) {
    hilog.warn(DOMAIN, TAG, 'initThermalHandler called but thermal module is disabled');
    return;
  }
  if (thermalInited) {
    return;
  }
  thermalInited = true;

  const normalizedSampleInterval = Math.max(sampleInterval, 1000);
  const normalizedReportMinInterval = Math.max(reportMinInterval, 5000);
  const normalizedAbnormalThreshold = Math.min(Math.max(abnormalThreshold, 0), 7);

  const getUptimeMs = (): number =>
  systemDateTime.getUptime(systemDateTime.TimeType.STARTUP);

  const thermalInterface: ThermalInfoInterface = {
    getThermalLevel: (): number => {
      try {
        return thermal.getLevel();
      } catch (e) {
        return -1;
      }
    }
  };

  const hooks: AppHooks = {
    onAppStateChange: (onFg: () => void, onBg: () => void): void => {
      const applicationStateChangeCallback: ApplicationStateChangeCallback = {
        onApplicationForeground() {
          onFg();
        },
        onApplicationBackground() {
          onBg();
        },
      };

      context.getApplicationContext().on('applicationStateChange', applicationStateChangeCallback);

      offThermalAppStateCallback = () => {
        try {
          context.getApplicationContext().off('applicationStateChange', applicationStateChangeCallback);
        } catch (e) {
        }
      };
    },

    onNavDestinationSwitch: (cb: (targetPageName: string) => void): void => {
      const callback = (info: uiObserver.NavDestinationSwitchInfo) => cb(getTargetPageName(info));
      uiObserver.on('navDestinationSwitch', context, callback);
      offThermalHandlerCallback = () => uiObserver.off('navDestinationSwitch', context, callback);
    },
  };

  const repeatSampleThermal = (sample: () => void): void => {
    clearSampleThermal();

    const sampleId = setInterval(() => {
      sample();
    }, normalizedSampleInterval);

    clearSampleThermal = () => {
      clearInterval(sampleId);
    };
  };

  const stopSampleThermal = (): void => {
    clearSampleThermal();
  };

  cjLibThermal.initThermalHandlerInterop(
    getUptimeMs,
    thermalInterface,
    hooks,
    repeatSampleThermal,
    stopSampleThermal,
    reportThermalInfo,
    normalizedSampleInterval,
    normalizedReportMinInterval,
    normalizedAbnormalThreshold
  );
}

export function destroyThermalHandler(): void {
  if (!cjLibThermal) return;
  thermalInited = false;
  clearSampleThermal();
  offThermalHandlerCallback();
  offThermalAppStateCallback();
  cjLibThermal.destroyThermalHandlerInterop();
}

export function initLaggyHandler(
  context: common.UIAbilityContext,
  windowStage: window.WindowStage,
  maxTime: number,
  maxArraySize: number,
  reportResponseEvent: (info: ResponseEvent) => void,
  reportPageResponseLaggyModel: (info: PageResponseLaggyModel) => void
): void {
  if (!cjLibLaggy) {
    hilog.warn(DOMAIN, TAG, 'initLaggyHandler called but laggy module is disabled');
    return;
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
        let info =
          new cjLibLaggy.ClickInfo(event.timestamp, win.getUIContext().vp2px(event.windowX),
            win.getUIContext().vp2px(event.windowY), frameNode?.getId() ?? '',
            frameNode?.getNodeType() ?? '', win.getUIContext().vp2px(frameNode?.getPositionToWindow().x ?? 0),
            win.getUIContext().vp2px(frameNode?.getPositionToWindow().y ?? 0), frameNode?.getMeasuredSize().height ?? 0,
            frameNode?.getMeasuredSize().width ?? 0);
        cb(info);
      });
    });
  };
  cjLibLaggy.initLaggyHandlerInterop(getDisplaySync(), onAbilityBackGround, onNavDestinationSwitch,
    onDidClick, maxTime, maxArraySize, reportResponseEvent, reportPageResponseLaggyModel);
}

function getDisplaySync() {
  let d = displaySync.create();
  let dSync: DisplaySync = {
    start: (): void => {
      d.start();
    },
    stop: (): void => {
      d.stop();
    },
    on: (cb: (time: number, targetTime: number) => void): void => {
      d.on('frame', (info: displaySync.IntervalInfo) => {
        cb(info.timestamp, info.targetTimestamp);
      });
    },
    off: (): void => {
      d.off('frame');
    }
  }
  return dSync;
}