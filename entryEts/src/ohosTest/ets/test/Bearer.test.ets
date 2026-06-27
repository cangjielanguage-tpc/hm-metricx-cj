import { describe, it, expect } from '@ohos/hypium';
import { connection } from '@kit.NetworkKit';
import { mapBearerTypes } from '@cangjie-tpc/hm_metricx_cj_hybrid';

/**
 * mapBearerTypes 纯逻辑单测。
 * 校验承载类型数组 → 承载网字符串的映射，不依赖真机网络，可重复。
 */
export default function bearerTest() {
  describe('mapBearerTypes', () => {
    it('空数组返回 none', 0, () => {
      let arr: Array<connection.NetBearType> = [];
      expect(mapBearerTypes(arr)).assertEqual('none');
    });

    it('仅 WIFI 返回 wifi', 0, () => {
      let arr: Array<connection.NetBearType> = [connection.NetBearType.BEARER_WIFI];
      expect(mapBearerTypes(arr)).assertEqual('wifi');
    });

    it('WIFI 与 CELLULAR 同时存在时优先返回 wifi', 0, () => {
      let arr: Array<connection.NetBearType> = [
        connection.NetBearType.BEARER_WIFI,
        connection.NetBearType.BEARER_CELLULAR
      ];
      expect(mapBearerTypes(arr)).assertEqual('wifi');
    });

    it('仅 CELLULAR 返回 mobile', 0, () => {
      let arr: Array<connection.NetBearType> = [connection.NetBearType.BEARER_CELLULAR];
      expect(mapBearerTypes(arr)).assertEqual('mobile');
    });

    it('非 WIFI/CELLULAR 的承载（如 ETHERNET）返回 other', 0, () => {
      let arr: Array<connection.NetBearType> = [connection.NetBearType.BEARER_ETHERNET];
      expect(mapBearerTypes(arr)).assertEqual('other');
    });
  });
}
