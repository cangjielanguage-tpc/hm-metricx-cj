import { bundleManager, common } from '@kit.AbilityKit';
import { requireCJLib } from 'libark_interop_loader.so';
import {
  CustomLib,
  InteropSampleTrafficInfo as SampleTrafficInfo,
  InteropStorageInfo,
  TrafficPreference,
  InteropProcessCpuInfo as ProcessCpuInfo,
  InteropPageCpuInfo as PageCpuInfo
} from 'libark_interop_api.so';
import { preferences } from '@kit.ArkData';
import { uiObserver } from '@kit.ArkUI';
import { statistics } from '@kit.NetworkKit';
import { storageStatistics } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hidebug } from '@kit.PerformanceAnalysisKit';

const cjLib = requireCJLib('libohos_app_cangjie_hm_metricx_cj.wrapper.so') as CustomLib;

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
    let callback = (info: uiObserver.NavDestinationSwitchInfo) => cb(getTargetPageName(info))
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
    let callback = (info: uiObserver.NavDestinationSwitchInfo) => cb(getTargetPageName(info))
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