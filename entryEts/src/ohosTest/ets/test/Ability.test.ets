import { hilog } from '@kit.PerformanceAnalysisKit';
import { describe, it, expect } from '@ohos/hypium';
import { getAndResetCurrentPageTraffic } from '@cangjie-tpc/hm_metricx_cj_hybrid';

const DOMAIN: number = 0x0000;
const TAG: string = 'hm_metricx_cj_test';

/**
 * 流量 getAndResetCurrentPageTraffic 骨架用例（device-only）。
 *
 * 说明：getAndResetCurrentPageTraffic 内部依赖 initTrafficHandler 缓存的
 * _getUidRxAndTxBytes（未 init 时为空实现，回调不会触发）。完整增量数值
 * 断言需真机网络栈 + 先 init，易 flaky，故此处仅做"未 init 调用不抛异常"
 * 的最小骨架，真实增量断言留给真机手动联调。
 */
export default function abilityTest() {
  describe('getAndResetCurrentPageTraffic', () => {
    it('未 init 时调用不抛异常', 0, () => {
      let thrown: boolean = false;
      try {
        getAndResetCurrentPageTraffic((_info): void => {
          // 未 init 时回调不触发；此处仅占位，不做数值断言
          hilog.info(DOMAIN, TAG, 'getAndReset callback fired unexpectedly');
        });
      } catch (e) {
        thrown = true;
        hilog.error(DOMAIN, TAG, 'getAndReset threw: %{public}s', `${e}`);
      }
      expect(thrown).assertFalse();
    });
  });
}
