import { AbilityConstant, bundleManager, common, errorManager } from '@kit.AbilityKit';
import { ApplicationStateChangeCallback, appManager } from '@kit.AbilityKit';
import {thermal} from '@kit.BasicServicesKit';
import { requireCJLib } from 'libark_interop_loader.so';
import { process } from '@kit.ArkTS';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import inspector from '@ohos.arkui.inspector';

import {
  CustomLib,
  InteropCrashInfo as CrashInfo,
  InteropFreezeInfo as FreezeInfo,
  InteropSampleTrafficInfo as SampleTrafficInfo,
  InteropPageTrafficInfo as PageTrafficInfo,
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
  AppStateInfo,
  SwipeKillInfo,
  InteropDayTrafficInfo as DayTrafficInfo,
  InteropHighCpuMonitorConfig,
  InteropBackgroundCpuMonitorConfig,
  InteropWhiteScreenConfig,
  InteropWhiteScreenEventInfo,
  InteropFirstRenderTimeConfig
} from 'libark_interop_api.so';
import { preferences } from '@kit.ArkData';
import { uiObserver, window } from '@kit.ArkUI';
import { connection, statistics } from '@kit.NetworkKit';
import { storageStatistics } from '@kit.CoreFileKit';
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import {
  batteryInfo,
  BusinessError,
  commonEventManager,
  deviceInfo,
  settings,
  systemDateTime
} from '@kit.BasicServicesKit';
import { displaySync, effectKit } from '@kit.ArkGraphics2D';
import { image } from '@kit.ImageKit';


// ==================== 仓颉库动态加载 ====================
if (process.pid != process.tid) {
  throw new Error("Does not work on worker")
}

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

if (cjLib) {
  cjLib.initLogger(logger);
}

export class CMemMonitorConfig {
  shouldBeClusteredToThisSo: (so: string) => boolean

  constructor(shouldBeClusteredToThisSo: (so: string) => boolean) {
    this.shouldBeClusteredToThisSo = shouldBeClusteredToThisSo
  }
}
let uid = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).appInfo.uid;

// 承载类型数组 → 承载网字符串映射（纯函数，便于单测）。
// 约定：空数组 → 'none'；含 WIFI 优先 → 'wifi'；否则含 CELLULAR → 'mobile'；其余 → 'other'。
// 注：'unknown' 仅在 getCurrentBearer 运行时异常路径产生，本函数不涉及。
export function mapBearerTypes(bearerTypes: Array<connection.NetBearType>): string {
  if (bearerTypes.length === 0) {
    return 'none';
  }
  // 承载类型枚举:BEARER_CELLULAR=0, BEARER_WIFI=1, BEARER_ETHERNET=3, ...
  if (bearerTypes.includes(connection.NetBearType.BEARER_WIFI)) {
    return 'wifi';
  } else if (bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR)) {
    return 'mobile';
  } else {
    return 'other';
  }
}

// 查询当前默认网络的承载类型，返回 wifi/mobile/none/unknown。
// 用于流量上报标注本次数据走的是 wlan 还是移动网络。
// getDefaultNet()/getNetCapabilities() 均返回 Promise，结果经回调异步返回。
let getCurrentBearer = (onBearer: (bearer: string) => void): void => {
  try {
    // getDefaultNet() 返回 Promise<NetHandle>；getNetCapabilities 是 connection 顶层函数
    connection.getDefaultNet().then((netHandle: connection.NetHandle): void => {
      if (!netHandle || !netHandle.netId) {
        onBearer('none');
        return;
      }
      connection.getNetCapabilities(netHandle).then((netCapabilities: connection.NetCapabilities): void => {
        onBearer(mapBearerTypes(netCapabilities.bearerTypes ?? []));
      }).catch((e: BusinessError): void => {
        hilog.warn(DOMAIN, TAG, `getNetCapabilities failed: ${e.message}`);
        onBearer('unknown');
      });
    }).catch((e: BusinessError): void => {
      hilog.warn(DOMAIN, TAG, `getDefaultNet failed: ${e.message}`);
      onBearer('unknown');
    });
  } catch (e) {
    hilog.warn(DOMAIN, TAG, 'getCurrentBearer failed');
    onBearer('unknown');
  }
};

let getUidRxAndTxBytes = (
  cb: (rxBytes: number, txBytes: number, pageName: string, bearer: string) => void,
  pageName: string
) => {
  statistics.getUidRxBytes(uid).then(rxBytes => {
    statistics.getUidTxBytes(uid).then(txBytes => {
      getCurrentBearer((bearer: string): void => cb(rxBytes, txBytes, pageName, bearer));
    });
  });
};

let offTraffic = () => {
};

let clearSampleTraffic = () => {
};

let offHighCpu = () => {
};

// @Concurrent function worker(){
//   requireCJLib(`libohos_app_cangjie_hm_metricx_cj.traffic.so`) as CustomLib;
//   return
// }

// async function run_worker ():Promise <void>{
//   await taskpool.execute(worker)
//   return
// }
//export async function initTrafficHandler(

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
  //await run_worker()
  cjLibTraffic.initTrafficHandlerInterop(p, onNavDestinationSwitch, repeatSampleTraffic, getUidRxAndTxBytes, reportTraffic,
    reportYesterdayTraffic, sampleThreshold);
}

export function destroyTrafficHandler(): void {
  if (!cjLibTraffic) return;
  clearSampleTraffic();
  offTraffic();
  cjLibTraffic.destroyTrafficHandlerInterop((cb: (rxBytes: number, txBytes: number) => void) => {
    // destroy 路径只需字节累计，丢弃 pageName/bearer
    getUidRxAndTxBytes((rxBytes: number, txBytes: number, _pageName: string, _bearer: string): void => {
      cb(rxBytes, txBytes);
    }, '');
  });
}

/**
 * 获取当前页面从进入到调用时刻期间的完整流量增量，调用后自动清零，供下一页面计数。
 * 上层在页面切换（离开上一页）时调用，即可拿到上一个页面从进入到离开期间的完整流量增量，
 * 用于发热异常快照中关联当前页面的流量消耗。
 *
 * 注意：结果经回调异步返回（底层 statistics API 返回 Promise）。
 */
export function getAndResetCurrentPageTraffic(onResult: (info: PageTrafficInfo) => void): void {
  if (!cjLibTraffic) {
    hilog.warn(DOMAIN, TAG, 'getAndResetCurrentPageTraffic called but traffic module is disabled');
    return;
  }
  cjLibTraffic.getAndResetCurrentPageTrafficInterop(onResult);
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
  cjLibCpu.initCpuHandlerInterop(onNavDestinationSwitch, repeatSampleAndReportCpu, reportPageCpuInfo,
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
  SYNC,
  ASYNC
}

export class CrashCallbacks {
  collectCrashInfo?: () => string
  reportCrashInfo: (info: CrashInfo) => void

  constructor(reportCrashInfo: (info: CrashInfo) => void, collectCrashInfo?: () => string) {
    this.collectCrashInfo = collectCrashInfo ?? undefined
    this.reportCrashInfo = reportCrashInfo
  }
}

export class CrashConfig {
  memMonitor?: CMemMonitorConfig
  lastNHilogNumber: number = 1000
  systemLogNumber: number = 1000

  constructor(memMonitor?: CMemMonitorConfig, lastNHilogNumber?: number, systemLogNumber?: number) {
    this.memMonitor = memMonitor ?? undefined
    this.lastNHilogNumber = lastNHilogNumber ?? 1000
    this.systemLogNumber = systemLogNumber ?? 1000
  }
}

export function initCrashHandler(
  applicationContext: common.ApplicationContext,
  persistentDir: string,
  callbacks: CrashCallbacks,
  config?: CrashConfig
): void {
  let finalConfig = config ?? new CrashConfig();
  hilog.warn(DOMAIN, TAG, 'crash 1');

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
          hilog.warn(DOMAIN, TAG, 'crash onReceive 2');
          hilog.warn(DOMAIN, 'hm_metricx_cj', 'crash addCrashWatcher');
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
  let addResourceLeakWatcher =
    (cb: (pid: string, timestamp: string, resourceType: string, memoryLimit: number, currentMemory: number, rawheapPath: string) => void) => {
      hilog.info(DOMAIN, 'hm_metricx_cj', 'registering resourceLeakWatcher...');
      hiAppEvent.addWatcher({
        name: 'resourceLeakWatcher',
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          hilog.warn(DOMAIN, TAG, 'crash resourceLeak onReceive 3');
          hilog.warn(DOMAIN, 'hm_metricx_cj', 'crash resourceLeak addResourceLeakWatcher triggered');
          if (domain !== 'OS') {
            hilog.warn(DOMAIN, 'hm_metricx_cj', `resourceLeakWatcher: domain mismatch, expected OS but got ${domain}`);
            return;
          }
          hilog.warn(DOMAIN, 'hm_metricx_cj', `resourceLeakWatcher: received ${appEventGroups.length} event groups`);
          for (const eventGroup of appEventGroups) {
            if (eventGroup.name !== 'RESOURCE_OVERLIMIT') {
              hilog.warn(DOMAIN, 'hm_metricx_cj', `resourceLeakWatcher: skipping event group ${eventGroup.name}`);
              continue;
            }
            hilog.warn(DOMAIN, 'hm_metricx_cj', `resourceLeakWatcher: processing RESOURCE_OVERLIMIT, ${eventGroup.appEventInfos.length} events`);
            for (const eventInfo of eventGroup.appEventInfos) {
              let pid: number = eventInfo.params['pid'];
              let timestamp: number = eventInfo.params['time'];
              let resourceType: string = eventInfo.params['resource_type'] ?? 'unknown';
              let memory: Record<string, number> = eventInfo.params['memory'];
              let memoryLimit: number = memory?.limit_size ?? 0;
              let currentMemory: number = memory?.live_object_size ?? 0;
              let external_logs: string[] = eventInfo.params['external_log'];

              hilog.warn(DOMAIN, 'hm_metricx_cj',
                `RESOURCE_OVERLIMIT: pid=${pid}, resourceType=${resourceType}, memory_limit=${memoryLimit}KB, memory_limit=${memoryLimit}KB, current=${currentMemory}KB, external_logs=${external_logs}`);
              let log = ''
              if (external_logs.length !== 0) {
                log = external_logs[0]
              }
              cb(pid.toString(), timestamp.toString(), resourceType, memoryLimit, currentMemory, log);
              break;
            }
            break;
          }
        }
      });
      hilog.info(DOMAIN, 'hm_metricx_cj', 'resourceLeakWatcher registered successfully');
    };
  let memMonitor =
    finalConfig.memMonitor !== undefined ? new cjLibCrash.CMemMonitorConfig(finalConfig.memMonitor!.shouldBeClusteredToThisSo) :
      undefined;
  if (finalConfig.lastNHilogNumber < 0 || finalConfig.systemLogNumber < 0) {
    throw new Error(`negative value ${finalConfig.lastNHilogNumber} or ${finalConfig.systemLogNumber}`);
  }
  cjLibCrash.initCrashHandlerInterop(addCrashWatcher, addResourceLeakWatcher, onCrash, exit,
    callbacks.collectCrashInfo,
    callbacks.reportCrashInfo,
    persistentDir,
    OOMHandlerMode.ASYNC,
    finalConfig.lastNHilogNumber,
    finalConfig.systemLogNumber, memMonitor);
}

export function getExitInfo(launchParam: AbilityConstant.LaunchParam): ExitInfo {
  if (!cjLibExitInfo) {
    hilog.warn(DOMAIN, TAG, 'getExitInfo called but exitInfo module is disabled');
    return {} as ExitInfo;
  }
  return cjLibExitInfo.getExitInfoInterop(launchParam.lastExitMessage, launchParam.lastExitReason);
}

/**
 * 初始化 exitInfo Handler
 */
let exitInfoWrapperDestroyed = false;

export function initExitInfoHandler(
  lastExitMessage: string,
  lastExitReason: number,
  reportExitInfoHandler: (data: ExitInfo) => void,
  reportAppStateHandler: (data: AppStateInfo) => void
): void {
  if (!cjLibExitInfo) {
    hilog.warn(DOMAIN, TAG, 'initExitInfoHandler called but exitinfo module is disabled');
    return;
  }
  exitInfoWrapperDestroyed = false;

  const jsReportExitInfo = (data: ExitInfo) => {
    if (exitInfoWrapperDestroyed) return;
    reportExitInfoHandler(data);
  };

  const jsReportAppState = (data: AppStateInfo) => {
    if (exitInfoWrapperDestroyed) return;
    reportAppStateHandler(data);
  };

  // 调用仓颉实现的 initExitInfoHandler
  cjLibExitInfo!.initExitInfoHandlerInterop(
    lastExitMessage,
    lastExitReason,
    jsReportExitInfo,
    jsReportAppState
  );
}

/**
 * 销毁 exitInfo Handler
 */
export function destroyExitInfoHandler(): void {
  exitInfoWrapperDestroyed = true;
  cjLibExitInfo!.destroyExitInfoHandlerInterop();
}

// ==================== SwipeKill 相关接口 ====================

let swipeKillWrapperDestroyed = false;

/**
 * 初始化 SwipeKill Handler
 * @param context UIAbilityContext，用于注册生命周期监听
 * @param lastExitReason 上次的退出原因（来自 launchParam.lastExitReason）
 * @param reportSwipeKillInfoHandler 上报回调
 * @param thresholdMs 划杀判断阈值（毫秒），默认 5000ms
 */
export function initSwipeKillHandler(
  context: common.UIAbilityContext,
  lastExitReason: number,
  reportSwipeKillInfoHandler: (data: SwipeKillInfo) => void,
  thresholdMs?: number
): void {
  if (!cjLibExitInfo) {
    hilog.warn(DOMAIN, TAG, 'initSwipeKillHandler called but exitInfo module is disabled');
    return;
  }
  swipeKillWrapperDestroyed = false;
  if (thresholdMs !== undefined && thresholdMs < 0) {
    throw new Error(`negative value ${thresholdMs}`);
  }
  const validthresholdMs = (thresholdMs === undefined) ? 5000 : thresholdMs;

  const jsReportSwipeKillInfo: (data: SwipeKillInfo) => void = (data: SwipeKillInfo) => {
    if (swipeKillWrapperDestroyed) return;
    reportSwipeKillInfoHandler(data);
  };

  // 定义 onAbilityBackground 回调，传给仓颉层注册生命周期监听
  const onAbilityBackgroundCallback = (cb: () => void) => {
    context.getApplicationContext().on('abilityLifecycle', {
      onAbilityCreate() {},
      onWindowStageCreate() {},
      onWindowStageActive() {},
      onWindowStageInactive() {},
      onWindowStageDestroy() {},
      onAbilityDestroy() {},
      onAbilityForeground() {},
      onAbilityBackground() {
        cb();
      },
      onAbilityContinue() {}
    })
  };

  cjLibExitInfo.initSwipeKillHandlerInterop(
    lastExitReason,
    jsReportSwipeKillInfo,
    onAbilityBackgroundCallback,
    validthresholdMs
  );
}

/**
 * 销毁 SwipeKill Handler
 */
export function destroySwipeKillHandler(): void {
  swipeKillWrapperDestroyed = true;
  if (!cjLibExitInfo) return;
  cjLibExitInfo!.destroySwipeKillHandlerInterop();
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

// 时间间隔边界值常量（毫秒）
const MIN_INTERVAL = 0;           // 最小间隔：0ms
const MAX_INTERVAL = 60 * 60 * 1000; // 最大间隔：1 小时

// 默认时间间隔（毫秒）
const DEFAULT_SAMPLE_INTERVAL = 2 * 1000;    // 2 秒
const DEFAULT_REPORT_INTERVAL = 30 * 60 * 1000; // 30 分钟
const DEFAULT_SAVE_INTERVAL = 60 * 1000;     // 1 分钟

/**
 * 校验时间间隔是否在合法范围内
 * @param value 待校验的时间间隔值
 * @param defaultValue 默认值
 * @returns 合法的值或默认值
 */
function validateInterval(value: number | undefined, defaultValue: number): number {
  if (value === undefined || value < MIN_INTERVAL || value > MAX_INTERVAL) {
    return defaultValue;
  }
  return value;
}

export function initMemoryHandler(
  context: common.UIAbilityContext,
  reportPageMemoryInfo: (data: PageMemoryInfo) => void,
  reportProcessMemoryInfo: (data: ProcessMemoryInfo) => void,
  memoryThreshold: number,
  sampleInterval?: number,
  reportInterval?: number,
  saveInterval?: number,
  totalRatio?: number,
  cjRatio?: number,
  arkTsRatio?: number,
  startArkTsHeapSampler?: () => void,
  stopArkTsHeapSampler?: () => void
): void {
  if (!cjLibMemory) {
    hilog.warn(DOMAIN, TAG, 'initMemoryHandler called but memory module is disabled');
    return;
  }

  // 边界值校验，超出范围则使用默认值
  const validSampleInterval = validateInterval(sampleInterval, DEFAULT_SAMPLE_INTERVAL);
  const validReportInterval = validateInterval(reportInterval, DEFAULT_REPORT_INTERVAL);
  const validSaveInterval = validateInterval(saveInterval, DEFAULT_SAVE_INTERVAL);

  // ratio边界值校验，超出范围则使用默认值0.8
  const validTotalRatio = (totalRatio === undefined || totalRatio < 0 || totalRatio > 1) ? 0.8 : totalRatio;
  const validCjRatio = (cjRatio === undefined || cjRatio < 0 || cjRatio > 1) ? 0.8 : cjRatio;
  const validArkTsRatio = (arkTsRatio === undefined || arkTsRatio < 0 || arkTsRatio > 1) ? 0.8 : arkTsRatio;

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
      let sampleId = setInterval(sample, validSampleInterval);
      let reportId = setInterval(report, validReportInterval);
      let saveId = setInterval(save, validSaveInterval);
      // 启动 ArkTS VM 堆异步采样 Worker（主线程零 hidebug 调用，防 THREAD_BLOCK_6S ANR）。
      if (startArkTsHeapSampler) {
        startArkTsHeapSampler();
      }
      clearSampleMemory = () => {
        clearInterval(sampleId);
        clearInterval(reportId);
        clearInterval(saveId);
        if (stopArkTsHeapSampler) {
          stopArkTsHeapSampler();
        }
      }
    }, validSampleInterval);
  };
  cjLibMemory.initMemoryHandlerInterop(p, onNavDestinationSwitch, repeatSampleAndReportMemory,
    reportPageMemoryInfo, reportProcessMemoryInfo, memoryThreshold, validTotalRatio, validCjRatio,
    validArkTsRatio);
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

// ArkTS VM 堆异步采样回调灌缓存。由 ArkTsHeapWorker 的 onmessage（主线程）调用，
// 把 heapUsed/vmHeapLimit 写入 Cangjie 缓存，供 doMemorySample 读取。
// 主线程零 hidebug 调用，防 THREAD_BLOCK_6S ANR；全字段恢复有效。
export function setArkTsMemoryCacheInterop(usage: number, limit: number): void {
  if (!cjLibMemory) {
    return;
  }
  cjLibMemory.setArkTsMemoryCacheInterop(Math.max(0, Math.floor(usage)), Math.max(0, Math.floor(limit)));
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

// ==================== High CPU Monitor 互操作接口 ====================

let clearHighCpuSample = () => {
};
let clearHighCpuReport = () => {
};

/**
 * 高 CPU 监控配置（ArkTS 版本）
 */
export class HighCpuMonitorConfig {
  cpuThreshold: number = 0.5;
  foregroundIntervalMs: number = 1000;
  backgroundIntervalMs: number = 2000;
  monitorDurationMs: number = 180000;  // 3 分钟
  threadCooldownMs: number = 600000;   // 10 分钟
  globalCooldownMs: number = 180000;    // 3 分钟
  highSampleRatioThreshold: number = 0.85;
  topNThreads: number = 10;

  constructor(
    cpuThreshold?: number,
    foregroundIntervalMs?: number,
    backgroundIntervalMs?: number,
    monitorDurationMs?: number,
    threadCooldownMs?: number,
    globalCooldownMs?: number,
    highSampleRatioThreshold?: number,
    topNThreads?: number
  ) {
    if (cpuThreshold !== undefined) {
      this.cpuThreshold = cpuThreshold;
    }
    if (foregroundIntervalMs !== undefined) {
      this.foregroundIntervalMs = foregroundIntervalMs;
    }
    if (backgroundIntervalMs !== undefined) {
      this.backgroundIntervalMs = backgroundIntervalMs;
    }
    if (monitorDurationMs !== undefined) {
      this.monitorDurationMs = monitorDurationMs;
    }
    if (threadCooldownMs !== undefined) {
      this.threadCooldownMs = threadCooldownMs;
    }
    if (globalCooldownMs !== undefined) {
      this.globalCooldownMs = globalCooldownMs;
    }
    if (highSampleRatioThreshold !== undefined) {
      this.highSampleRatioThreshold = highSampleRatioThreshold;
    }
    if (topNThreads !== undefined) {
      this.topNThreads = topNThreads;
    }
  }

  toInteropConfig(): InteropHighCpuMonitorConfig {
    if (!cjLibCpu) {
      throw new Error('cjLibCpu is not available');
    }
    return new cjLibCpu.InteropHighCpuMonitorConfig(
      this.cpuThreshold,
      this.foregroundIntervalMs,
      this.backgroundIntervalMs,
      this.monitorDurationMs,
      this.threadCooldownMs,
      this.globalCooldownMs,
      this.highSampleRatioThreshold,
      this.topNThreads
    );
  }
}

/**
 * 线程栈信息（ArkTS 版本）
 */
export interface ThreadStackInfo {
  tid: number;
  threadName: string;
  avgCpuUsage: number;
  maxCpuUsage: number;
  sampleCount: number;
  stackTrace: string;
  moduleName: string;
  firstDetectedTime: number;
  highSampleCount: number;
}

/**
 * 高 CPU 占用上报信息（ArkTS 版本）
 */
export interface HighCpuReportInfo {
  timestamp: number;
  pid: number;
  processName: string;
  pageName: string;
  highCpuThreads: ThreadStackInfo[];
  avgProcessCpu: number;
  maxProcessCpu: number;
  monitorDuration: number;
}

/**
 * 初始化高 CPU 监控
 */
export function initHighCpuMonitorHandler(
  context: common.UIAbilityContext,
  config: HighCpuMonitorConfig,
  reportHighCpuInfo: (data: HighCpuReportInfo) => void
): void {
  if (!cjLibCpu) {
    hilog.warn(DOMAIN, TAG, 'initHighCpuMonitorHandler called but high_cpu module is disabled');
    return;
  }

  const applicationStateChangeCallback: ApplicationStateChangeCallback = {
    onApplicationForeground() {
      cjLibCpu.onAppForegroundInterop();
    },
    onApplicationBackground() {
      cjLibCpu.onAppBackgroundInterop();
    }
  };
  context.getApplicationContext().on('applicationStateChange', applicationStateChangeCallback);

  const repeatHighCpuSample = (sample: () => void) => {
    const sampleId = setInterval(sample, config.foregroundIntervalMs);
    clearHighCpuSample = () => clearInterval(sampleId);
  };

  const repeatHighCpuReport = (report: () => void) => {
    const reportIntervalMs = config.monitorDurationMs;
    const reportId = setInterval(report, reportIntervalMs);
    clearHighCpuReport = () => clearInterval(reportId);
  };

  const reportHighCpuInfoJson = (jsonStr: string) => {
    try {
      const jsonObj: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>;
      const highCpuThreadsRaw: Object[] = (jsonObj.highCpuThreads as Object[]) || [];
      const threads: ThreadStackInfo[] = highCpuThreadsRaw.map((threadRaw) => {
        const t = threadRaw as Record<string, number | string>;
        const threadInfo: ThreadStackInfo = {
          tid: t.tid as number,
          threadName: t.threadName as string,
          avgCpuUsage: t.avgCpuUsage as number,
          maxCpuUsage: t.maxCpuUsage as number,
          sampleCount: t.sampleCount as number,
          stackTrace: t.stackTrace as string,
          moduleName: t.moduleName as string,
          firstDetectedTime: t.firstDetectedTime as number,
          highSampleCount: t.highSampleCount as number
        };
        return threadInfo;
      });

      const info: HighCpuReportInfo = {
        timestamp: jsonObj.timestamp as number,
        pid: jsonObj.pid as number,
        processName: jsonObj.processName as string,
        pageName: jsonObj.pageName as string,
        highCpuThreads: threads,
        avgProcessCpu: jsonObj.avgProcessCpu as number,
        maxProcessCpu: jsonObj.maxProcessCpu as number,
        monitorDuration: jsonObj.monitorDuration as number
      };
      reportHighCpuInfo(info);
    } catch {
      hilog.error(DOMAIN, TAG, 'Failed to parse HighCpuReportInfo JSON');
    }
  };

  // 注册页面切换回调，用于更新当前页面名称
  let onNavDestinationSwitch = (cb: (targetPageName: string) => void) => {
    let callback = (info: uiObserver.NavDestinationSwitchInfo) => cb(getTargetPageName(info));
    uiObserver.on('navDestinationSwitch', context, callback);
    offHighCpu = () => uiObserver.off('navDestinationSwitch', context, callback);
  };

  cjLibCpu.initHighCpuMonitorHandlerInterop(
    onNavDestinationSwitch,
    repeatHighCpuSample,
    repeatHighCpuReport,
    reportHighCpuInfoJson
  );

  let interopConfig: InteropHighCpuMonitorConfig = config.toInteropConfig();
  cjLibCpu.startHighCpuMonitorInterop(interopConfig);

  hilog.info(DOMAIN, TAG, 'High CPU monitor initialized');
}

/**
 * 销毁高 CPU 监控
 */
export function destroyHighCpuMonitorHandler(): void {
  if (!cjLibCpu) return;
  clearHighCpuSample();
  clearHighCpuReport();
  offHighCpu();
  cjLibCpu.stopHighCpuMonitorInterop();
  hilog.info(DOMAIN, TAG, 'High CPU monitor destroyed');
}

/**
 * 手动触发高 CPU 上报
 */
export function triggerHighCpuReport(): void {
  if (!cjLibCpu) return;
  cjLibCpu.triggerHighCpuReportInterop();
}

/**
 * 仅用于抓栈自检调用的本地接口：captureCurrentThreadStackInterop 由 cpu_wrapper.cj 的
 * @Interop[ArkTS] 导出，但聚合类型 CustomLib（ark_interop_api.d.ts，构建期由 cangjie 插件
 * 重新生成、可能滞后）未稳定包含该方法，故在此以本地 interface 显式声明调用签名，
 * 运行时仍走 cjLibCpu 实际加载的 wrapper.so 符号。
 */
interface CpuStackCaptureLib {
  captureCurrentThreadStackInterop(): string;
}

/**
 * 抓栈自检：抓取当前线程调用栈并返回符号化文本（同步直调，不发信号、无 cooldown）。
 * 供 demo 自检按钮验证 native 抓栈链路，不依赖高 CPU 上报窗口。
 */
export function captureCurrentThreadStack(): string {
  if (!cjLibCpu) return 'cjLibCpu disabled';
  return cjLibCpu.captureCurrentThreadStackInterop();
}

// ==================== 后台活动超长率监控 ====================

/**
 * 后台 CPU 异常级别
 */
export enum BackgroundCpuLevel {
  WARN = 'WARN',
  ERROR = 'ERROR',
  FATAL = 'FATAL'
}

/**
 * 滑动窗口采样数据
 */
export interface WindowSample {
  timestamp: number;
  cpuUsage: number;
  duration: number;
}

/**
 * 后台 CPU 异常上报信息
 */
export interface BackgroundCpuReportInfo {
  timestamp: number;
  pid: number;
  processName: string;
  level: BackgroundCpuLevel;
  backgroundDuration: number;
  avgCpuUsage: number;
  maxCpuUsage: number;
  windowSamples: WindowSample[];
  highCpuThreads: ThreadStackInfo[];
}

/**
 * 后台活动超长率监控配置（ArkTS 版本）
 */
export class BackgroundCpuMonitorConfig {
  cpuThreshold: number = 0.5;
  warnDurationMs: number = 10000;
  errorDurationMs: number = 30000;
  fatalDurationMs: number = 60000;
  sampleIntervalMs: number = 1000;
  windowSizeMs: number = 5000;
  topNThreads: number = 10;
  threadCooldownMs: number = 600000;
  globalCooldownMs: number = 180000;

  constructor(
    cpuThreshold?: number,
    warnDurationMs?: number,
    errorDurationMs?: number,
    fatalDurationMs?: number,
    sampleIntervalMs?: number,
    windowSizeMs?: number,
    topNThreads?: number,
    threadCooldownMs?: number,
    globalCooldownMs?: number
  ) {
    if (cpuThreshold !== undefined) this.cpuThreshold = cpuThreshold;
    if (warnDurationMs !== undefined) this.warnDurationMs = warnDurationMs;
    if (errorDurationMs !== undefined) this.errorDurationMs = errorDurationMs;
    if (fatalDurationMs !== undefined) this.fatalDurationMs = fatalDurationMs;
    if (sampleIntervalMs !== undefined) this.sampleIntervalMs = sampleIntervalMs;
    if (windowSizeMs !== undefined) this.windowSizeMs = windowSizeMs;
    if (topNThreads !== undefined) this.topNThreads = topNThreads;
    if (threadCooldownMs !== undefined) this.threadCooldownMs = threadCooldownMs;
    if (globalCooldownMs !== undefined) this.globalCooldownMs = globalCooldownMs;
  }

  toInteropConfig(): InteropBackgroundCpuMonitorConfig {
    if (!cjLibCpu) {
      throw new Error('cjLibCpu is not available');
    }
    return new cjLibCpu.InteropBackgroundCpuMonitorConfig(
      this.cpuThreshold,
      this.warnDurationMs,
      this.errorDurationMs,
      this.fatalDurationMs,
      this.sampleIntervalMs,
      this.windowSizeMs,
      this.topNThreads,
      this.threadCooldownMs,
      this.globalCooldownMs
    );
  }
}

let clearBackgroundSampleTimer: () => void = () => {};
let backgroundDelayTaskId: number = -1; // 后台延时任务ID

/**
 * 申请后台延时任务
 *
 * 应用进入后台时调用,申请3分钟的延时任务,保持定时器和采样继续运行
 * 3分钟后系统会自动恢复正常的后台挂起行为
 */
function requestBackgroundDelayTask(): void {
  // 如果已经有延时任务在运行,先取消
  if (backgroundDelayTaskId > 0) {
    hilog.info(DOMAIN, TAG, 'Background delay task already running, cancelling first');
    cancelBackgroundDelayTask();
  }

  try {
    // 申请延时任务 - 系统会返回实际批准的延时时长
    const delayInfo = backgroundTaskManager.requestSuspendDelay('后台性能监控', () => {
      // 回调函数:应用申请的延时任务即将超时
      hilog.info(DOMAIN, TAG, 'Background delay task will time out, stopping all monitoring');
      backgroundDelayTaskId = -1;
      // 取消后台任务
      cancelBackgroundDelayTask();
    });

    backgroundDelayTaskId = delayInfo.requestId;
    const actualTime = delayInfo.actualDelayTime;

    hilog.warn(DOMAIN, TAG, `===== Background delay task requested =====`);
    hilog.warn(DOMAIN, TAG, `Request ID: ${backgroundDelayTaskId}`);
    hilog.warn(DOMAIN, TAG, `System approved actualDelayTime: ${actualTime}ms (${actualTime / 1000}s)`);
    hilog.warn(DOMAIN, TAG, `Timer will continue for approximately ${actualTime / 1000} seconds`);

  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `requestSuspendDelay failed: code is ${err.code}, message is ${err.message}`);
  }
}

/**
 * 取消后台延时任务
 *
 * 应用回到前台或3分钟到期时调用,停止延时任务
 */
function cancelBackgroundDelayTask(): void {
  // 取消延时任务
  if (backgroundDelayTaskId > 0) {
    try {
      backgroundTaskManager.cancelSuspendDelay(backgroundDelayTaskId);
      hilog.warn(DOMAIN, TAG, `Background delay task cancelled, requestId: ${backgroundDelayTaskId}`);
      backgroundDelayTaskId = -1;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `cancelSuspendDelay failed: code is ${err.code}, message is ${err.message}`);
    }
  }
}

/**
 * 初始化后台活动超长率监控
 */
export function initBackgroundCpuMonitorHandler(
  context: common.UIAbilityContext,
  config: BackgroundCpuMonitorConfig,
  reportBackgroundCpuInfo: (data: BackgroundCpuReportInfo) => void
): void {
  if (!cjLibCpu) {
    hilog.warn(DOMAIN, TAG, 'initBackgroundCpuMonitorHandler called but cpu module is disabled');
    return;
  }

  // 监听应用生命周期
  const applicationStateChangeCallback: ApplicationStateChangeCallback = {
    onApplicationForeground() {
      cjLibCpu.onAppForegroundInterop();
      // 应用回到前台,取消后台延时任务
      cancelBackgroundDelayTask();
    },
    onApplicationBackground() {
      cjLibCpu.onAppBackgroundInterop();
      // 应用进入后台,申请延时任务,保持3分钟的定时器运行
      requestBackgroundDelayTask();
    }
  };
  context.getApplicationContext().on('applicationStateChange', applicationStateChangeCallback);

  // 定义定时器控制逻辑
  const repeatSample = (sample: () => void) => {
    const id = setInterval(sample, config.sampleIntervalMs);
    clearBackgroundSampleTimer = () => clearInterval(id);
  };

  const clearSample = () => {
    clearBackgroundSampleTimer();
  };

  // 解析上报数据
  const reportCallbackJson = (jsonStr: string) => {
    try {
      const jsonObj: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>;
      const windowSamplesRaw: Object[] = (jsonObj.windowSamples as Object[]) || [];
      const windowSamples: WindowSample[] = windowSamplesRaw.map((s: Object) => {
        const sample = s as Record<string, number>;
        return { timestamp: sample.timestamp, cpuUsage: sample.cpuUsage, duration: sample.duration } as WindowSample;
      });

      const highCpuThreadsRaw: Object[] = (jsonObj.highCpuThreads as Object[]) || [];
      const highCpuThreads: ThreadStackInfo[] = highCpuThreadsRaw.map((t: Object) => {
        const thread = t as Record<string, number | string>;
        return {
          tid: thread.tid as number, threadName: thread.threadName as string,
          avgCpuUsage: thread.avgCpuUsage as number, maxCpuUsage: thread.maxCpuUsage as number,
          sampleCount: thread.sampleCount as number, stackTrace: thread.stackTrace as string,
          moduleName: thread.moduleName as string, firstDetectedTime: thread.firstDetectedTime as number,
          highSampleCount: thread.highSampleCount as number
        } as ThreadStackInfo;
      });

      const info: BackgroundCpuReportInfo = {
        timestamp: jsonObj.timestamp as number, pid: jsonObj.pid as number,
        processName: jsonObj.processName as string, level: jsonObj.level as BackgroundCpuLevel,
        backgroundDuration: jsonObj.backgroundDuration as number,
        avgCpuUsage: jsonObj.avgCpuUsage as number, maxCpuUsage: jsonObj.maxCpuUsage as number,
        windowSamples: windowSamples, highCpuThreads: highCpuThreads
      };
      reportBackgroundCpuInfo(info);
    } catch {
      hilog.error(DOMAIN, TAG, 'Failed to parse BackgroundCpuReportInfo JSON');
    }
  };

  // 调用仓颉侧初始化
  cjLibCpu.initBackgroundCpuMonitorHandlerInterop(
    config.toInteropConfig(),
    repeatSample,
    clearSample,
    reportCallbackJson
  );

  hilog.info(DOMAIN, TAG, 'Background CPU monitor initialized');
}

/**
 * 销毁后台活动超长率监控
 */
export function destroyBackgroundCpuMonitorHandler(): void {
  if (!cjLibCpu) return;
  clearBackgroundSampleTimer();
  // 销毁时也取消后台延时任务
  cancelBackgroundDelayTask();
  cjLibCpu.destroyBackgroundCpuMonitorHandlerInterop();
}

/**
 * 检查高 CPU 监控是否正在运行
 */
export function isHighCpuMonitoringActive(): boolean {
  if (!cjLibCpu) return false;
  return cjLibCpu.isHighCpuMonitoringActiveInterop();
}

// ==================== 白屏检测 ====================

let whiteScreenTimerMap: Map<number, number> = new Map();
let whiteScreenTimerCounter: number = 0;
let whiteScreenInited: boolean = false;
let whiteScreenOffNavSwitch: () => void = () => {};
let whiteScreenOffLifecycle: () => void = () => {};
let whiteScreenDisplaySync: displaySync.DisplaySync | null = null;
let whiteScreenFrameCallback: ((timestamp: number, targetTimestamp: number) => void) | null = null;

/**
 * 初始化白屏检测
 */
export function initWhiteScreenHandler(
  context: common.UIAbilityContext,
  windowStage: window.WindowStage,
  win: window.Window,
  config: WhiteScreenConfig,
  reportWhiteScreenInfo: (data: InteropWhiteScreenEventInfo) => void
): void {
  const cjLibFps = loadCJLibSafe('fps');
  if (!cjLibFps) {
    hilog.warn(DOMAIN, TAG, 'initWhiteScreenHandler called but fps module is disabled');
    return;
  }

  if (whiteScreenInited) {
    hilog.warn(DOMAIN, TAG, 'WhiteScreen handler already initialized');
    return;
  }

  // setTimeout 包装函数
  const setTimeoutFunc = (timerType: string, delayMs: number): number => {
    const timerId: number = ++whiteScreenTimerCounter;
    const nativeTimerId: number = setTimeout(() => {
      cjLibFps!.handleWhiteScreenTimerCallbackInterop(timerType);
      whiteScreenTimerMap.delete(timerId);
    }, delayMs);
    whiteScreenTimerMap.set(timerId, nativeTimerId);
    return timerId;
  };

  // clearTimeout 包装函数
  const clearTimeoutFunc = (timerId: number): void => {
    const nativeTimerId: number | undefined = whiteScreenTimerMap.get(timerId);
    if (nativeTimerId !== undefined) {
      clearTimeout(nativeTimerId);
      whiteScreenTimerMap.delete(timerId);
    }
  };

  // 首帧标记（用于区分首帧和后续帧）
  let isFirstFrame: boolean = true;

  // 帧事件回调
  const onFrameCallback = (timestamp: number, targetTimestamp: number): void => {
    if (isFirstFrame) {
      isFirstFrame = false;
      cjLibFps!.onFirstFrameReceivedInterop();
    } else {
      cjLibFps!.onFrameReceivedInterop();
    }
  };

  // 创建 DisplaySync 用于帧监听
  whiteScreenDisplaySync = displaySync.create();
  whiteScreenFrameCallback = onFrameCallback;
  whiteScreenDisplaySync.on('frame', (info: displaySync.IntervalInfo) => {
    if (whiteScreenFrameCallback) {
      whiteScreenFrameCallback(info.timestamp, info.targetTimestamp);
    }
  });
  whiteScreenDisplaySync.start();

  // 应用生命周期监听
  let whiteScreenIsBackground = false;
  let lifecycleCallback: ApplicationStateChangeCallback = {
    onApplicationForeground() {
      if (whiteScreenIsBackground && whiteScreenDisplaySync) {
        whiteScreenDisplaySync.start();
        isFirstFrame = true;
      }
      whiteScreenIsBackground = false;
      cjLibFps!.onWhiteScreenForegroundInterop();
    },
    onApplicationBackground() {
      whiteScreenIsBackground = true;
      if (whiteScreenDisplaySync) {
        whiteScreenDisplaySync.stop();
      }
      cjLibFps!.onWhiteScreenBackgroundInterop();
    }
  };
  whiteScreenOffLifecycle = () => {
    context.getApplicationContext().off('applicationStateChange', lifecycleCallback);
  };
  context.getApplicationContext().on('applicationStateChange', lifecycleCallback);

  // 异步快照触发函数
  const performSnapshotFunc = (): void => {
    hilog.info(DOMAIN, TAG, 'performSnapshotFunc triggered');
    performWindowSnapshotAsync(win, (colorData: string) => {
      cjLibFps!.onSnapshotAnalysisResultInterop(colorData);
    });
  };

  // 后台检测快照触发函数（带 sampleIndex 参数）
  const performBackgroundSnapshotFunc = (sampleIndex: number): void => {
    hilog.info(DOMAIN, TAG, 'performBackgroundSnapshotFunc triggered, sampleIndex=' + sampleIndex);
    performWindowSnapshotAsync(win, (colorData: string) => {
      cjLibFps!.onBackgroundSnapshotAnalysisResultInterop(sampleIndex, colorData);
    });
  };

  // 注册路由切换监听
  const onNavDestinationSwitch = (cb: (targetPageName: string) => void) => {
    const navSwitchCallback = (info: uiObserver.NavDestinationSwitchInfo) => {
      const fromPageName: string = getSourcePageName(info);
      const toPageName: string = getTargetPageName(info);
      const fromHidden: boolean = info.from !== null && typeof info.from !== 'string' &&
        (info.from as NavDestinationInfo).state === uiObserver.NavDestinationState.ON_HIDDEN;
      const toShown: boolean = info.to !== null && typeof info.to !== 'string' &&
        (info.to as NavDestinationInfo).state === uiObserver.NavDestinationState.ON_SHOWN;

      cjLibFps!.onNavDestinationSwitchInterop(fromPageName, toPageName, fromHidden, toShown);
      cb(toPageName);
    };
    uiObserver.on('navDestinationSwitch', context, navSwitchCallback);
    whiteScreenOffNavSwitch = () => uiObserver.off('navDestinationSwitch', context, navSwitchCallback);
  };

  // 调用仓颉侧初始化
  const interopConfig = config.toInteropConfig();
  cjLibFps.initWhiteScreenHandlerInterop(
    interopConfig,
    reportWhiteScreenInfo,
    setTimeoutFunc,
    clearTimeoutFunc,
    performSnapshotFunc,
    performBackgroundSnapshotFunc
  );

  onNavDestinationSwitch((targetPageName: string) => {
    isFirstFrame = true;
    hilog.info(DOMAIN, TAG, 'Nav destination switched to: ' + targetPageName);
  });

  whiteScreenInited = true;
  hilog.info(DOMAIN, TAG, 'WhiteScreen handler initialized');
}

/**
 * 销毁白屏检测
 */
export function destroyWhiteScreenHandler(): void {
  const cjLibFps = loadCJLibSafe('fps');
  if (!cjLibFps) return;

  // 停止 DisplaySync 帧监听
  if (whiteScreenDisplaySync) {
    whiteScreenDisplaySync.stop();
    whiteScreenDisplaySync.off('frame');
    whiteScreenDisplaySync = null;
    whiteScreenFrameCallback = null;
  }

  // 清除所有定时器
  const timerEntries: Array<[number, number]> = Array.from(whiteScreenTimerMap.entries());
  for (const entry of timerEntries) {
    const timerId: number = entry[0];
    const nativeTimerId: number = entry[1];
    clearTimeout(nativeTimerId);
  }
  whiteScreenTimerMap.clear();
  whiteScreenTimerCounter = 0;

  // 取消路由监听
  whiteScreenOffNavSwitch();

  // 取消生命周期监听
  whiteScreenOffLifecycle();

  cjLibFps.destroyWhiteScreenHandlerInterop();
  whiteScreenInited = false;
  hilog.info(DOMAIN, TAG, 'WhiteScreen handler destroyed');
}

/**
 * 通知首帧到达
 */
export function notifyFirstFrameReceived(): void {
  const cjLibFps = loadCJLibSafe('fps');
  if (!cjLibFps) return;
  cjLibFps.onFirstFrameReceivedInterop();
}

/**
 * 通知帧到达
 */
export function notifyFrameReceived(): void {
  const cjLibFps = loadCJLibSafe('fps');
  if (!cjLibFps) return;
  cjLibFps.onFrameReceivedInterop();
}

/**
 * 触发快照分析
 */
export function notifyPerformSnapshotAnalyze(): void {
  const cjLibFps = loadCJLibSafe('fps');
  if (!cjLibFps) return;
  cjLibFps.performSnapshotAndAnalyzeInterop();
}

/**
 * 触发快照分析
 */
export function notifyPerformSwitchResultSnapshotAnalyze(): void {
  const cjLibFps = loadCJLibSafe('fps');
  if (!cjLibFps) return;
  cjLibFps.performSnapshotAndAnalyzeInterop();
}

/**
 * 白屏检测配置（用户侧类）
 */
export class WhiteScreenConfig {
  rootComponentId: string = 'root';
  ttidTimeoutMs: number = 1000;
  frameCheckDurationMs: number = 3000;
  backgroundFirstSnapshotDelayMs: number = 800;
  backgroundSecondSnapshotDelayMs: number = 1800;
  backgroundRecentPageEnterThresholdMs: number = 3000;
  minFrameCountThreshold: number = 30;
  maxDistinctColorCount: number = 2;
  whiteRgbThreshold: number = 245;
  snapshotScale: number = 0.1;
  snapshotRegionTop: number = 0.08;
  snapshotRegionBottom: number = 0.08;
  autoWriteFaultLog: boolean = true;

  constructor(
    rootComponentId?: string,
    ttidTimeoutMs?: number,
    frameCheckDurationMs?: number,
    backgroundFirstSnapshotDelayMs?: number,
    backgroundSecondSnapshotDelayMs?: number,
    backgroundRecentPageEnterThresholdMs?: number,
    minFrameCountThreshold?: number,
    maxDistinctColorCount?: number,
    whiteRgbThreshold?: number,
    snapshotScale?: number,
    snapshotRegionTop?: number,
    snapshotRegionBottom?: number,
    autoWriteFaultLog?: boolean
  ) {
    if (rootComponentId !== undefined) {
      this.rootComponentId = rootComponentId;
    }
    if (ttidTimeoutMs !== undefined) {
      this.ttidTimeoutMs = ttidTimeoutMs;
    }
    if (frameCheckDurationMs !== undefined) {
      this.frameCheckDurationMs = frameCheckDurationMs;
    }
    if (backgroundFirstSnapshotDelayMs !== undefined) {
      this.backgroundFirstSnapshotDelayMs = backgroundFirstSnapshotDelayMs;
    }
    if (backgroundSecondSnapshotDelayMs !== undefined) {
      this.backgroundSecondSnapshotDelayMs = backgroundSecondSnapshotDelayMs;
    }
    if (backgroundRecentPageEnterThresholdMs !== undefined) {
      this.backgroundRecentPageEnterThresholdMs = backgroundRecentPageEnterThresholdMs;
    }
    if (minFrameCountThreshold !== undefined) {
      this.minFrameCountThreshold = minFrameCountThreshold;
    }
    if (maxDistinctColorCount !== undefined) {
      this.maxDistinctColorCount = maxDistinctColorCount;
    }
    if (whiteRgbThreshold !== undefined) {
      this.whiteRgbThreshold = whiteRgbThreshold;
    }
    if (snapshotScale !== undefined) {
      this.snapshotScale = snapshotScale;
    }
    if (snapshotRegionTop !== undefined) {
      this.snapshotRegionTop = snapshotRegionTop;
    }
    if (snapshotRegionBottom !== undefined) {
      this.snapshotRegionBottom = snapshotRegionBottom;
    }
    if (autoWriteFaultLog !== undefined) {
      this.autoWriteFaultLog = autoWriteFaultLog;
    }
  }

  toInteropConfig(): InteropWhiteScreenConfig {
    if (!cjLibFps) {
      throw new Error('cjLibFps is not available');
    }
    return new cjLibFps.InteropWhiteScreenConfig(
      this.rootComponentId,
      this.ttidTimeoutMs,
      this.frameCheckDurationMs,
      this.backgroundFirstSnapshotDelayMs,
      this.backgroundSecondSnapshotDelayMs,
      this.backgroundRecentPageEnterThresholdMs,
      this.minFrameCountThreshold,
      this.maxDistinctColorCount,
      this.whiteRgbThreshold,
      this.snapshotScale,
      this.snapshotRegionTop,
      this.snapshotRegionBottom,
      this.autoWriteFaultLog
    );
  }
}

/**
 * 白屏检测事件信息（用户侧类）
 */
export class WhiteScreenEventInfo {
  pageName: string = '';
  whiteScreenType: string = '';
  whiteScreenScene: string = '';
  appState: string = '';
  ttid: number = 0;
  backgroundElapsedMs: number = 0;
  foregroundDistinctColorCount: number = -1;
  foregroundMainColorWhite: boolean = false;
  backgroundFirstDistinctColorCount: number = -1;
  backgroundSecondDistinctColorCount: number = -1;
  backgroundFirstMainColorWhite: boolean = false;
  backgroundSecondMainColorWhite: boolean = false;
  backgroundDetectionReason: string = '';
  frameCountInNSeconds: number = 0;

  constructor(
    pageName?: string,
    whiteScreenType?: string,
    whiteScreenScene?: string,
    appState?: string,
    ttid?: number,
    backgroundElapsedMs?: number,
    foregroundDistinctColorCount?: number,
    foregroundMainColorWhite?: boolean,
    backgroundFirstDistinctColorCount?: number,
    backgroundSecondDistinctColorCount?: number,
    backgroundFirstMainColorWhite?: boolean,
    backgroundSecondMainColorWhite?: boolean,
    backgroundDetectionReason?: string,
    frameCountInNSeconds?: number
  ) {
    if (pageName !== undefined) {
      this.pageName = pageName;
    }
    if (whiteScreenType !== undefined) {
      this.whiteScreenType = whiteScreenType;
    }
    if (whiteScreenScene !== undefined) {
      this.whiteScreenScene = whiteScreenScene;
    }
    if (appState !== undefined) {
      this.appState = appState;
    }
    if (ttid !== undefined) {
      this.ttid = ttid;
    }
    if (backgroundElapsedMs !== undefined) {
      this.backgroundElapsedMs = backgroundElapsedMs;
    }
    if (foregroundDistinctColorCount !== undefined) {
      this.foregroundDistinctColorCount = foregroundDistinctColorCount;
    }
    if (foregroundMainColorWhite !== undefined) {
      this.foregroundMainColorWhite = foregroundMainColorWhite;
    }
    if (backgroundFirstDistinctColorCount !== undefined) {
      this.backgroundFirstDistinctColorCount = backgroundFirstDistinctColorCount;
    }
    if (backgroundSecondDistinctColorCount !== undefined) {
      this.backgroundSecondDistinctColorCount = backgroundSecondDistinctColorCount;
    }
    if (backgroundFirstMainColorWhite !== undefined) {
      this.backgroundFirstMainColorWhite = backgroundFirstMainColorWhite;
    }
    if (backgroundSecondMainColorWhite !== undefined) {
      this.backgroundSecondMainColorWhite = backgroundSecondMainColorWhite;
    }
    if (backgroundDetectionReason !== undefined) {
      this.backgroundDetectionReason = backgroundDetectionReason;
    }
    if (frameCountInNSeconds !== undefined) {
      this.frameCountInNSeconds = frameCountInNSeconds;
    }
  }
}

/**
 * 同步获取窗口快照
 */
function getWindowSnapshotSync(
  windowStage: window.WindowStage,
  rootComponentId: string
): string {
  hilog.info(DOMAIN, TAG, 'getWindowSnapshotSync called');
  return '{"distinctCount": 1}';
}

function performWindowSnapshotAsync(
  win: window.Window,
  callback: (colorData: string) => void
): void {
  const MAX_RETRY = 1;
  const trySnapshot = (retry: number): void => {
    try {
      win.snapshot((err: BusinessError, pixelMap: image.PixelMap) => {
        if (!pixelMap) {
          hilog.warn(DOMAIN, TAG,
            `Window snapshot failed, retry=${retry}, err=` + JSON.stringify(err));
          if (retry > 0) {
            setTimeout(() => {
              trySnapshot(retry - 1);
            }, 120);
            return;
          }
          callback('{"distinctCount": 999, "mainColorWhite": false}');
          return;
        }
        hilog.info(DOMAIN, TAG, 'Window snapshot succeed, analyzing color...');
        try {
          effectKit.createColorPicker(pixelMap, [0, 0, 1, 1])
            .then((colorPicker: effectKit.ColorPicker) => {
              const topColors = colorPicker.getTopProportionColors(10);
              const distinctCount =
                topColors && topColors.length > 0
                  ? countDistinctColors(topColors as Array<effectKit.Color>)
                  : 999;
              const mainColorWhite =
                topColors && topColors.length > 0
                  ? isMainColorWhite(topColors as Array<effectKit.Color>)
                  : false;
              hilog.info(
                DOMAIN,
                TAG,
                'Color analysis complete, distinctCount=' + distinctCount + ', mainColorWhite=' + mainColorWhite
              );

              callback('{"distinctCount": ' + distinctCount + ', "mainColorWhite": ' + mainColorWhite + '}');

            })
            .catch((colorErr: Error) => {
              hilog.warn(DOMAIN, TAG,
                'Color analysis failed: ' + JSON.stringify(colorErr));
              callback('{"distinctCount": 999, "mainColorWhite": false}');
            });
        } catch (colorErr) {
          hilog.warn(DOMAIN, TAG,
            'Color analysis exception: ' + JSON.stringify(colorErr));
          callback('{"distinctCount": 999, "mainColorWhite": false}');
        }
      });
    } catch (e) {
      hilog.warn(DOMAIN, TAG,
        'performWindowSnapshotAsync exception: ' + JSON.stringify(e));
      callback('{"distinctCount": 999, "mainColorWhite": false}');
    }
  };
  trySnapshot(MAX_RETRY);
}

/**
 * 计算不同颜色的数量（RGB量化去重）
 */
function countDistinctColors(colors: Array<effectKit.Color>): number {
  if (!colors || colors.length === 0) {
    return 999;
  }
  const keys = new Set<number>();
  for (let i = 0; i < colors.length; i++) {
    const c = colors[i];
    if (c) {
      const key = Math.floor(c.red / 32) * 64 + Math.floor(c.green / 32) * 8 + Math.floor(c.blue / 32);
      keys.add(key);
    }
  }
  return keys.size;
}

/**
 * 判断主色是否为白色
 */
function isMainColorWhite(colors: Array<effectKit.Color>): boolean {
  for (let i = 0; i < colors.length; i++) {
    const c = colors[i];
    if (c) {
      return isWhiteColor(c);
    }
  }
  return false;
}

function isWhiteColor(c: effectKit.Color): boolean {
  return c.red >= 245 && c.green >= 245 && c.blue >= 245;
}

/**
 * 获取源页面名称
 */
function getSourcePageName(info: uiObserver.NavDestinationSwitchInfo): string {
  let name: string = '';
  const fromValue: Object | string = info.from;
  if (typeof fromValue === 'string') {
    name = 'navRoot';
  } else if (typeof fromValue === 'object' && fromValue !== null) {
    const navDest: NavDestinationInfo = fromValue as NavDestinationInfo;
    if (typeof navDest.name === 'string') {
      name = navDest.name;
    }
  }
  return name;
}

// ==================== 首帧渲染时间监控 ====================

// 首帧渲染时间监控相关变量
// 是否已初始化
let firstRenderTimeInited: boolean = false;
// 路由监听取消函数
let firstRenderTimeOffNavSwitch: (() => void) | null = null;
// 点击监听取消函数
let offClick: (() => void) | null = null;
// draw observer（ArkUI 返回对象，类型未知，用 unknown）
let drawObserver: (() => void) | null = null;
// ComponentObserver（ArkUI 未导出类型，用接口约束）
interface DrawOption {
  onDraw: () => void;
}
let componentObserverRef: inspector.ComponentObserver | null = null;
// 是否已经收到首帧
let hasDraw: boolean = false;
// timeout（兼容 ArkTS）
let timeoutId: number = -1;

// 页面版本（防止页面切换串数据）
let currentPageId: number = 0;

// 首帧渲染时间事件信息接口
export interface FirstRenderTimeEventInfo {
  startTime: number;
  endTime: number;
  duration: number;
  targetPage: string;
}

// 首帧渲染时间配置类（用户侧类）
export class FirstRenderTimeConfig {
  enableLogging: boolean = true;
  reportThreshold: number = 1000; // 超过或者等于此阈值才上报，默认1000ms

  constructor(
    enableLogging?: boolean,
    reportThreshold?: number
  ) {
    if (enableLogging !== undefined) {
      this.enableLogging = enableLogging;
    }
    if (reportThreshold !== undefined) {
      this.reportThreshold = reportThreshold;
    }
  }

  toInteropConfig(): InteropFirstRenderTimeConfig {
    if (!cjLibFps) {
      throw new Error('cjLibFps is not available');
    }
    return new cjLibFps.InteropFirstRenderTimeConfig(
      this.enableLogging,
      this.reportThreshold
    );
  }
}

/**
 * 初始化首帧渲染时间监控
 */
export function initFirstRenderTimeHandler(
  context: common.UIAbilityContext,
  win: window.Window,
  config: FirstRenderTimeConfig,
  reportFirstRenderTimeInfo: (data: FirstRenderTimeEventInfo) => void
): void {
  const cjLibFps = loadCJLibSafe('fps');
  if (!cjLibFps) {
    hilog.warn(DOMAIN, 'firstRenderTime', 'initFirstRenderTimeHandler called but fps module is disabled');
    return;
  }
  if (firstRenderTimeInited) {
    hilog.warn(DOMAIN, 'firstRenderTime', 'FirstRenderTime handler already initialized');
    return;
  }
  // ==================== 初始化 ComponentObserver ====================
  const uiContext = win.getUIContext();
  const inspector = uiContext.getUIInspector?.();
  componentObserverRef = inspector?.createComponentObserver?.("root") ?? null;
  // ==================== 路由监听 ====================
  const onNavDestinationSwitch = (cb: (targetPageName: string) => void) => {
    const navSwitchCallback = (info: uiObserver.NavDestinationSwitchInfo) => {
      const targetPageName: string = getTargetPageName(info);

      cjLibFps.recordNavigationTargetInterop(targetPageName);
      cb(targetPageName);
    };
    uiObserver.on('navDestinationSwitch', context, navSwitchCallback);
    firstRenderTimeOffNavSwitch = () => {
      uiObserver.off('navDestinationSwitch', context, navSwitchCallback);
    };
  };
  // ==================== 点击监听 ====================
  const clickCallback = (_event: object) => {
    cjLibFps.recordClickStartInterop();
  };
  const uiObserverInstance = uiContext.getUIObserver();
  uiObserverInstance.on('willClick', clickCallback);
  offClick = () => {
    uiObserverInstance.off('willClick', clickCallback);
  };
  // ==================== 初始化 CJ ====================
  const interopConfig = config.toInteropConfig();
  cjLibFps.initFirstRenderTimeMonitorInterop(
    interopConfig,
    reportFirstRenderTimeInfo
  );
  // ==================== 核心逻辑（nav + draw） ====================
  onNavDestinationSwitch((targetPageName: string) => {
    hilog.info(DOMAIN, 'firstRenderTime', 'Nav destination switched to: ' + targetPageName);
    // 防串数据（关键）
    currentPageId++;
    const pageId = currentPageId;
    hasDraw = false;
    const observer = componentObserverRef;
    // 清理旧 drawObserver
    if (drawObserver !== null && observer !== null) {
      observer.off('draw', drawObserver);
      drawObserver = null;
    }
    // 清理旧 timeout
    if (timeoutId !== -1) {
      clearTimeout(timeoutId);
      timeoutId = -1;
    }
    if (!observer) {
      hilog.warn(DOMAIN, 'firstRenderTime', 'componentObserver not available');
      return;
    }

    const drawCallback = () => {
      if (hasDraw || pageId !== currentPageId) return;
      hasDraw = true;
      hilog.info(DOMAIN, 'firstRenderTime', 'First draw detected: ' + targetPageName);
      cjLibFps.recordDrawEndInterop();
      observer.off('draw', drawCallback);
      drawObserver = null;
      // 清理 timeout
      if (timeoutId !== -1) {
        clearTimeout(timeoutId);
        timeoutId = -1;
      }
    };
    observer.on('draw', drawCallback);
    drawObserver = drawCallback;
    // 超时兜底
    timeoutId = setTimeout(() => {
      if (!hasDraw && pageId === currentPageId) {
        hasDraw = true;
        hilog.warn(DOMAIN, 'firstRenderTime', 'Draw timeout fallback: ' + targetPageName);
        cjLibFps.calculateFirstRenderTimeInterop(targetPageName + "_timeout");
      }
    }, 3000);
  });
  firstRenderTimeInited = true;
  hilog.info(DOMAIN, 'firstRenderTime', 'FirstRenderTime handler initialized');
}

/**
 * 销毁首帧渲染时间监控
 */
export function destroyFirstRenderTimeHandler(): void {
  const cjLibFps = loadCJLibSafe('fps');
  if (!cjLibFps) return;
  if (offClick) {
    offClick();
    offClick = null;
  }
  if (firstRenderTimeOffNavSwitch) {
    firstRenderTimeOffNavSwitch();
    firstRenderTimeOffNavSwitch = null;
  }
  if (drawObserver !== null && componentObserverRef !== null) {
    componentObserverRef.off('draw', drawObserver);
    drawObserver = null;
  }
  if (timeoutId !== -1) {
    clearTimeout(timeoutId);
    timeoutId = -1;
  }
  hasDraw = false;
  currentPageId = 0;
  componentObserverRef = null;
  cjLibFps.resetFirstRenderTimeMonitorInterop();
  firstRenderTimeInited = false;
  hilog.info(DOMAIN, 'firstRenderTime', 'FirstRenderTime handler destroyed');
}