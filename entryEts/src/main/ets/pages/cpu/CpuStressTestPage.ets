import { hilog } from '@kit.PerformanceAnalysisKit'
import { ErrorEvent, MessageEvents, worker } from '@kit.ArkTS'
import { getCurrentThermalLevel, ThermalLevel } from '../../common/ThermalHelper'
import { runCpuStressLoop } from '../../common/StressHelper'
import { captureCurrentThreadStack } from '@cangjie-tpc/hm_metricx_cj_hybrid'

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
  @State isWorkerBurning: boolean = false

  private stopStressFlag: boolean = false
  private thermalPollTimerId: number = -1
  private burnWorker: worker.ThreadWorker | null = null

  aboutToDisappear(): void {
    this.stopCpuStress()
    this.stopWorkerBurn()
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

          Button('抓栈自检（当前线程）')
            .width('80%')
            .onClick((): void => {
              const stack: string = captureCurrentThreadStack();
              hilog.warn(DOMAIN, TAG, `===== 抓栈自检（当前线程） =====\n${stack}`);
            })

          Divider().margin({ top: 16, bottom: 8 })
          Text('Worker 子线程烧 CPU（验证抓到真实高 CPU 栈）')
            .fontSize(15)
            .fontColor('#56657A')
          Text(`Worker 烧机状态: ${this.isWorkerBurning ? '运行中' : '已停止'}`)
          Button(this.isWorkerBurning ? 'Worker 烧机中…' : '开始 Worker 烧 CPU')
            .width('80%')
            .onClick((): void => {
              this.startWorkerBurn()
            })
          Button('停止 Worker 烧 CPU')
            .width('80%')
            .onClick((): void => {
              this.stopWorkerBurn()
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

  /**
   * 启动 Worker 子线程持续烧 CPU。
   * Worker 线程长期高 CPU（>30%），hm_metricx_cj 采样命中后上报抓栈，
   * 应抓到 burnCpuContinuously / JS 解释器计算帧，而非主线程的互操作/事件循环栈。
   */
  private startWorkerBurn(): void {
    if (this.burnWorker !== null) {
      hilog.info(DOMAIN, TAG, 'CpuStressTestPage: worker already burning')
      return
    }
    this.burnWorker = new worker.ThreadWorker('../../workers/CpuBurnWorker')
    this.burnWorker.onmessage = (msg: MessageEvents): void => {
      hilog.info(DOMAIN, TAG, `CpuBurnWorker: ${String(msg.data)}`)
    }
    this.burnWorker.onerror = (e: ErrorEvent): void => {
      hilog.error(DOMAIN, TAG, `CpuBurnWorker error: ${e.message}`)
    }
    this.isWorkerBurning = true
    this.burnWorker.postMessage('start')
    hilog.info(DOMAIN, TAG, 'CpuStressTestPage: worker burn started')
  }

  private stopWorkerBurn(): void {
    if (this.burnWorker === null) {
      this.isWorkerBurning = false
      return
    }
    // Worker 内 while(burning) 同步阻塞消息循环，postMessage('stop') 收不到，
    // 必须用 terminate() 强制终止。
    this.burnWorker.terminate()
    this.burnWorker = null
    this.isWorkerBurning = false
    hilog.info(DOMAIN, TAG, 'CpuStressTestPage: worker burn stopped')
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
