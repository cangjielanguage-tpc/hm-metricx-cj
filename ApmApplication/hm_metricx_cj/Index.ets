import { bundleManager, common } from '@kit.AbilityKit';
import { requireCJLib } from 'libark_interop_loader.so';
import { CustomLib, InteropSampleTrafficInfo as SampleTrafficInfo, TrafficPreference } from 'libark_interop_api.so';
import { preferences } from '@kit.ArkData';
import { uiObserver } from '@kit.ArkUI';
import { statistics } from '@kit.NetworkKit';

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
    let trafficCb = (info: uiObserver.NavDestinationSwitchInfo) => cb(getTargetPageName(info))
    uiObserver.on('navDestinationSwitch', context, trafficCb);
    offTraffic = () => uiObserver.off('navDestinationSwitch', context, trafficCb);
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