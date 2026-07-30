/**
 * NavDestination onReady 参数解析工具。
 * 提取自原 6 个白屏测试页内重复的 param→数字解析逻辑。
 *
 * 约定:pushPath 传入的 param 为字符串。
 * - 数字串(如 "8000"):覆盖默认时长(ms)。
 * - 'keep':白屏自恢复测试跳过自动 pop 的标记(由调用方主动 pop)。
 * - 空串/undefined:使用默认时长。
 */

/** 解析 param 为时长(ms);非数字或空则返回 defaultMs。 */
export function parseDuration(param: string | undefined | null, defaultMs: number): number {
  if (param && param.length > 0) {
    const parsed: number = Number(param)
    if (!isNaN(parsed)) {
      return parsed
    }
  }
  return defaultMs
}

/** 是否为 'keep' 标记(跳过自动 pop)。 */
export function isKeepParam(param: string | undefined | null): boolean {
  return param === 'keep'
}
