import { hilog } from '@kit.PerformanceAnalysisKit'
import { SectionHeader } from './SectionHeader'

const DOMAIN: number = 0x0021
const TAG: string = 'thermal_traffic_test'
const UI_REFRESH_INTERVAL_MS: number = 16

/**
 * UI 高频刷新卡片。
 *
 * 用 16ms setInterval 持续累加 uiTick 并刷新文本,制造高频重绘压力。
 * 逻辑提取自原 Index.startUiStress / stopUiStress。
 */
@Component
export struct UiStressCard {
  @State isRunning: boolean = false
  @State tick: number = 0
  @State message: string = ''
  private timerId: number = -1

  build(): void {
    Column({ space: 6 }) {
      SectionHeader('UI 高频刷新 / UI Stress')

      Button(this.isRunning ? 'UI 高频刷新中…' : '开始 UI 高频刷新')
        .width('100%')
        .onClick((): void => {
          this.startUiStress()
        })

      Button('停止 UI 高频刷新')
        .width('100%')
        .onClick((): void => {
          this.stopUiStress()
        })

      Button('模拟点击切换文本')
        .width('100%')
        .onClick((): void => {
          this.message = this.message === 'Thermal + Traffic Test' ? 'Welcome' : 'Thermal + Traffic Test'
        })

      Text(`UI刷新状态: ${this.isRunning ? '运行中' : '已停止'}`)
      Text(`UI刷新计数: ${this.tick}`)
      Text(this.message)
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor('#F7F9FC')
  }

  private startUiStress(): void {
    if (this.isRunning) {
      this.message = 'UI 高频刷新已启动'
      return
    }

    this.isRunning = true
    this.message = 'UI 高频刷新已启动'

    this.timerId = setInterval((): void => {
      this.tick += 1
      this.message = `Thermal + Traffic Test ${this.tick}`
    }, UI_REFRESH_INTERVAL_MS)

    hilog.info(DOMAIN, TAG, 'ui stress started')
  }

  private stopUiStress(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
    }

    this.isRunning = false
    hilog.info(DOMAIN, TAG, 'ui stress stopped')
  }

  aboutToDisappear(): void {
    this.stopUiStress()
  }
}
