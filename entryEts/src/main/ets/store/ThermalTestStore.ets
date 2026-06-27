/**
 * 全局 thermal 上报状态存储。
 * 由 EntryAbility 的 initThermalHandler 回调写入,首页 ThermalInfoCard 周期读取展示。
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
