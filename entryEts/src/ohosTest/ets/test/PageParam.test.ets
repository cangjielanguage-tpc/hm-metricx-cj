import { describe, it, expect } from '@ohos/hypium';
import { parseDuration, isKeepParam } from '../../main/ets/common/PageParamParser';

/**
 * PageParamParser 纯逻辑单测。
 * 校验 NavDestination param → 时长/keep 标记的解析，零依赖、可重复。
 */
export default function pageParamTest() {
  describe('parseDuration', () => {
    it('数字串解析为对应时长', 0, () => {
      expect(parseDuration('8000', 5000)).assertEqual(8000);
    });

    it('undefined 返回默认时长', 0, () => {
      expect(parseDuration(undefined, 5000)).assertEqual(5000);
    });

    it('null 返回默认时长', 0, () => {
      expect(parseDuration(null, 5000)).assertEqual(5000);
    });

    it('空串返回默认时长', 0, () => {
      expect(parseDuration('', 5000)).assertEqual(5000);
    });

    it('非数字串（含 keep）返回默认时长', 0, () => {
      expect(parseDuration('keep', 5000)).assertEqual(5000);
      expect(parseDuration('abc', 5000)).assertEqual(5000);
    });
  });

  describe('isKeepParam', () => {
    it('keep 返回 true', 0, () => {
      expect(isKeepParam('keep')).assertTrue();
    });

    it('数字串返回 false', 0, () => {
      expect(isKeepParam('8000')).assertFalse();
    });

    it('undefined/null/空串返回 false', 0, () => {
      expect(isKeepParam(undefined)).assertFalse();
      expect(isKeepParam(null)).assertFalse();
      expect(isKeepParam('')).assertFalse();
    });
  });
}
