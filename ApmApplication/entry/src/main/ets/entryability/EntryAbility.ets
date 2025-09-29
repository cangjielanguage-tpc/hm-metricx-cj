import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import {
  CMemMonitorConfig,
  OOMHandlerMode,
  initCpuHandler,
  initCrashHandler,
  initStorageHandler,
  initTrafficHandler,
  getExitInfo,
  initFreezeHandler,
  initMemoryHandler,
  destroyMemoryHandler,
  initBatteryHandler,
  destroyBatteryHandler,
  initScrollEventHandler,
  initPageEventHandler,
  initLaggyHanddler,
  getYesterdayTraffic
} from 'hm_metricx_cj';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    let exitInfo = getExitInfo(launchParam);
    hilog.info(DOMAIN, 'testTag', 'last exitMessage is %{public}s, exitReason is %{public}s', exitInfo.lastExitMessage,
      exitInfo.lastExitReason);
    initCrashHandler(this.context.getApplicationContext(), () => "{}", data => {

      hilog.info(DOMAIN, 'testTag', 'crash timestamp %{public}s', data.timestamp);
      hilog.info(DOMAIN, 'testTag', 'crash stacktrace %{public}s', data.stacktrace);
      hilog.info(DOMAIN, 'testTag', 'crash nativeMemDetail %{public}s', data.nativeMemDetail);
    }, this.context.cacheDir, OOMHandlerMode.ASYNC, 1000, 1000, new CMemMonitorConfig(data => false));
    initFreezeHandler(() => "{}", data => {
    }, this.context.cacheDir);
    initTrafficHandler(this.context, data => {
    });
    initStorageHandler(data => {
    }, 1, 1);
    initCpuHandler(this.context, data => {
    }, data => {
    });
    initMemoryHandler(this.context, data => {
    }, data => {
    }, 100 * 1024);
    initBatteryHandler(this.context, data => {
    }, data => {
    });
    let dayTraffic = getYesterdayTraffic()
    if (dayTraffic != undefined) {
      hilog.info(DOMAIN, 'testTag', 'traffic dayTraffic.total is %{public}s', dayTraffic.total)
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    destroyMemoryHandler();
    destroyBatteryHandler();
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
      initLaggyHanddler(this.context, windowStage, 100, 100, data => {
      }, data => {
      })
    })
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