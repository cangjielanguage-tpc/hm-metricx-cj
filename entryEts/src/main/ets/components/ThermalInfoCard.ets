import { thermalTestStore } from '../store/ThermalTestStore'
import { getCurrentThermalLevel, ThermalLevel } from '../common/ThermalHelper'
import { SectionHeader } from './SectionHeader'

const SYNC_INTERVAL_MS: number = 500
const POLL_INTERVAL_MS: number = 1000

/**
 * 热档位信息卡片:周期刷新当前热档位 + 从 thermalTestStore 同步 thermal 上报字段。
 * 上报字段由 EntryAbility 的 initThermalHandler 回调写入 store;当前档位来自 thermal.getLevel()。
 */
@Component
export struct ThermalInfoCard {
  @State reportCount: number = 0
  @State lastLevel: number = -1
  @State lastLevelName: string = ''
  @State lastPageName: string = ''
  @State lastDurationMs: number = 0
  @State lastTimestamp: number = 0
  @State lastIsForeground: boolean = true

  @State currentThermalLevel: number = -1
  @State currentThermalLevelName: string = 'UNKNOWN'

  private syncTimerId: number = -1
  private thermalPollTimerId: number = -1

  aboutToAppear(): void {
    this.syncFromStore()
    this.refreshThermalLevel()

    this.syncTimerId = setInterval((): void => {
      this.syncFromStore()
    }, SYNC_INTERVAL_MS)

    this.thermalPollTimerId = setInterval((): void => {
      this.refreshThermalLevel()
    }, POLL_INTERVAL_MS)
  }

  aboutToDisappear(): void {
    if (this.syncTimerId !== -1) {
      clearInterval(this.syncTimerId)
      this.syncTimerId = -1
    }
    if (this.thermalPollTimerId !== -1) {
      clearInterval(this.thermalPollTimerId)
      this.thermalPollTimerId = -1
    }
  }

  build(): void {
    Column({ space: 6 }) {
      SectionHeader('热档位 / Thermal')

      Text(`当前热档位: ${this.currentThermalLevel}`)
      Text(`当前热档位名称: ${this.currentThermalLevelName}`)

      Divider().margin({ top: 6, bottom: 6 })

      Text(`thermal上报次数: ${this.reportCount}`)
      Text(`最近 level: ${this.lastLevel}`)
      Text(`最近 levelName: ${this.lastLevelName}`)
      Text(`最近 pageName: ${this.lastPageName}`)
      Text(`最近 durationMs: ${this.lastDurationMs}`)
      Text(`最近 timestamp: ${this.lastTimestamp}`)
      Text(`最近前台状态: ${this.lastIsForeground}`)

      Button('刷新显示')
        .width('100%')
        .margin({ top: 6 })
        .onClick((): void => {
          this.syncFromStore()
          this.refreshThermalLevel()
        })
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor('#F7F9FC')
  }

  private syncFromStore(): void {
    this.reportCount = thermalTestStore.reportCount
    this.lastLevel = thermalTestStore.lastLevel
    this.lastLevelName = thermalTestStore.lastLevelName
    this.lastPageName = thermalTestStore.lastPageName
    this.lastDurationMs = thermalTestStore.lastDurationMs
    this.lastTimestamp = thermalTestStore.lastTimestamp
    this.lastIsForeground = thermalTestStore.lastIsForeground
  }

  private refreshThermalLevel(): void {
    const t: ThermalLevel = getCurrentThermalLevel()
    this.currentThermalLevel = t.level
    this.currentThermalLevelName = t.name
  }
}
