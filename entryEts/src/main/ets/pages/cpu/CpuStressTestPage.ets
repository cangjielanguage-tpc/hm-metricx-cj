import { hilog } from '@kit.PerformanceAnalysisKit'
import { getCurrentThermalLevel, ThermalLevel } from '../../common/ThermalHelper'
import { runCpuStressLoop } from '../../common/StressHelper'

const DOMAIN: number = 0x0021
const TAG: string = 'thermal_traffic_test'
const THERMAL_POLL_INTERVAL_MS: number = 1000
const AUTO_STOP_LEVEL: number = 3

/**
 * CPU 热压测试页(独立页)。
 * 用于验证 HighCpuReportInfo.pageName 是否正确上报为路由路径(CpuStressTestPage)而非 mainPage。
 * 压测逻辑复用 StressHelper,与首页 CpuStressCard 行为一致。
 */
@Component
export struct CpuStressTestPage {
  @State pageStack: NavPathStack = new NavPathStack()
  @State isCpuStressRunning: boolean = false
  @State cpuStressRounds: number = 0
  @State currentThermalLevel: number = -1
  @State currentThermalLevelName: string = 'UNKNOWN'
  @State currentPageName: string = ''

  private stopStressFlag: boolean = false
  private thermalPollTimerId: number = -1

  aboutToDisappear(): void {
    this.stopCpuStress()
    if (this.thermalPollTimerId !== -1) {
      clearInterval(this.thermalPollTimerId)
      this.thermalPollTimerId = -1
    }
  }

  build(): void {
    NavDestination() {
      Scroll() {
        Column({ space: 12 }) {
          Text('CPU 热压测试页面')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 16 })

          Text('此页面用于验证 HighCpuReportInfo.pageName')
            .fontSize(16)
            .fontColor('#3D4A5D')
          Text('预期：pageName 应为 "CpuStressTestPage" 而非 "mainPage"')
            .fontSize(15)
            .fontColor('#56657A')
            .margin({ bottom: 20 })

          Divider().margin({ top: 8, bottom: 8 })
          Text(`CPU 热压状态: ${this.isCpuStressRunning ? '运行中' : '已停止'}`)
          Text(`热压轮次: ${this.cpuStressRounds}`)
          Text(`当前热档位: ${this.currentThermalLevel}`)
          Text(`热档位名称: ${this.currentThermalLevelName}`)
          Text(`当前页面名: ${this.currentPageName}`)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentPageName === 'CpuStressTestPage' ? '#4CAF50' : '#F44336')

          Divider().margin({ top: 16, bottom: 16 })

          Button(this.isCpuStressRunning ? 'CPU 热压中…' : '开始 CPU 热压测试')
            .width('80%')
            .onClick((): void => {
              this.startCpuStress()
            })

          Button('停止 CPU 热压测试')
            .width('80%')
            .onClick((): void => {
              this.stopCpuStress()
            })

          Button('刷新热档位')
            .width('80%')
            .onClick((): void => {
              this.refreshThermalLevel()
            })

          Button('返回主页')
            .width('80%')
            .margin({ top: 16 })
            .onClick((): void => {
              this.pageStack.pop()
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding(20)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onReady((context): void => {
      this.pageStack = context.pathStack
      this.currentPageName = context.pathInfo.name ?? 'unknown'
      hilog.info(DOMAIN, TAG, `CpuStressTestPage onReady, name=${this.currentPageName}`)

      this.refreshThermalLevel()
      this.thermalPollTimerId = setInterval((): void => {
        this.refreshThermalLevel()
      }, THERMAL_POLL_INTERVAL_MS)
    })
    .onBackPressed((): boolean => {
      this.stopCpuStress()
      this.pageStack.pop()
      return true
    })
  }

  private startCpuStress(): void {
    if (this.isCpuStressRunning) {
      return
    }

    this.isCpuStressRunning = true
    this.stopStressFlag = false
    this.cpuStressRounds = 0
    hilog.info(DOMAIN, TAG, 'CpuStressTestPage: cpu stress started')

    this.runCpuStressLoop()
  }

  private stopCpuStress(): void {
    this.stopStressFlag = true
    this.isCpuStressRunning = false
    hilog.info(DOMAIN, TAG, 'CpuStressTestPage: cpu stress stopped')
  }

  private async runCpuStressLoop(): Promise<void> {
    await runCpuStressLoop({
      onRound: (): void => {
        this.cpuStressRounds += 1
      },
      onRefreshThermal: (): number => {
        this.refreshThermalLevel()
        return this.currentThermalLevel
      },
      shouldStop: (): boolean => this.stopStressFlag,
      autoStopLevel: AUTO_STOP_LEVEL,
      onAutoStop: (levelName: string): void => {
        hilog.info(DOMAIN, TAG, `CpuStressTestPage: thermal level ${levelName}, auto stop`)
        this.stopCpuStress()
      }
    })
  }

  private refreshThermalLevel(): void {
    const t: ThermalLevel = getCurrentThermalLevel()
    this.currentThermalLevel = t.level
    this.currentThermalLevelName = t.name
  }
}
