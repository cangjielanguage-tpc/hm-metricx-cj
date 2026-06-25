/**
 * 全局 thermal 上报状态存储。
 *
 * 注意:当前为只读占位 store —— EntryAbility 的 thermal handler 直接 hilog 打印,
 * 并未写入本 store,故显示字段恒为初始值。保留结构以备后续接入实时上报回填。
 * 提取自原 Index.ets。
 */
export class ThermalTestStore {
  reportCount: number = 0
  lastLevel: number = -1
  lastLevelName: string = ''
  lastPageName: string = ''
  lastDurationMs: number = 0
  lastTimestamp: number = 0
  lastIsForeground: boolean = true
}

export const thermalTestStore: ThermalTestStore = new ThermalTestStore()
