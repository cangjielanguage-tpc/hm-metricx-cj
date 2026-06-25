import { hilog } from '@kit.PerformanceAnalysisKit'
import { runCpuStressLoop } from '../common/StressHelper'
import { getCurrentThermalLevel as readThermal, ThermalLevel } from '../common/ThermalHelper'
import { SectionHeader } from './SectionHeader'

const DOMAIN: number = 0x0021
const TAG: string = 'thermal_traffic_test'
const AUTO_STOP_LEVEL: number = 3

/**
 * 首页 CPU 热压卡片。
 *
 * 忙等烧 CPU,每轮刷新热档位,到达档位 3(HOT)自动停止。
 * 逻辑提取自原 Index.runCpuStressLoop / burnCpuFor。
 */
@Component
export struct CpuStressCard {
  @State isRunning: boolean = false
  @State rounds: number = 0
  @State currentLevel: number = -1
  @State currentLevelName: string = 'UNKNOWN'
  @State message: string = ''
  private stopFlag: boolean = false

  build(): void {
    Column({ space: 6 }) {
      SectionHeader('CPU 热压 / CPU Stress')

      Button(this.isRunning ? 'CPU 热压中…' : '开始 CPU 热压测试')
        .width('100%')
        .onClick((): void => {
          this.startCpuStress()
        })

      Button('停止 CPU 热压测试')
        .width('100%')
        .onClick((): void => {
          this.stopCpuStress()
        })

      Text(`CPU热压状态: ${this.isRunning ? '运行中' : '已停止'}`)
      Text(`CPU热压轮次: ${this.rounds}`)
      Text(`当前热档位: ${this.currentLevel}`)
      Text(`当前热档位名称: ${this.currentLevelName}`)
      Text(this.message)
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor('#F7F9FC')
  }

  private refreshThermalLevel(): number {
    const level: ThermalLevel = readThermal()
    this.currentLevel = level.level
    this.currentLevelName = level.name
    return level.level
  }

  private startCpuStress(): void {
    if (this.isRunning) {
      this.message = 'CPU 热压已启动'
      return
    }

    this.isRunning = true
    this.stopFlag = false
    this.rounds = 0
    this.message = 'CPU 热压测试已启动'
    hilog.info(DOMAIN, TAG, 'cpu stress started')

    this.runLoop()
  }

  private stopCpuStress(): void {
    this.stopFlag = true
    this.isRunning = false
    hilog.info(DOMAIN, TAG, 'cpu stress stopped')
  }

  private async runLoop(): Promise<void> {
    await runCpuStressLoop({
      onRound: (): void => {
        this.rounds += 1
      },
      onRefreshThermal: (): number => {
        return this.refreshThermalLevel()
      },
      shouldStop: (): boolean => {
        return this.stopFlag
      },
      autoStopLevel: AUTO_STOP_LEVEL,
      onAutoStop: (levelName: string): void => {
        this.message = `到达热档位 ${levelName}，自动停止CPU热压`
        this.stopCpuStress()
      }
    })
  }
}
