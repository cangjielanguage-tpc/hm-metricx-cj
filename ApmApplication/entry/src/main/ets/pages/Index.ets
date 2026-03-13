import http from '@ohos.net.http'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { thermal } from '@kit.BasicServicesKit'

const DOMAIN: number = 0x0021
const TAG: string = 'thermal_traffic_test'

class ThermalTestStore {
  reportCount: number = 0
  lastLevel: number = -1
  lastLevelName: string = ''
  lastPageName: string = ''
  lastDurationMs: number = 0
  lastTimestamp: number = 0
  lastIsForeground: boolean = true
}

export const thermalTestStore: ThermalTestStore = new ThermalTestStore()

function levelToName(level: number): string {
  switch (level) {
    case 0:
      return 'COOL'
    case 1:
      return 'NORMAL'
    case 2:
      return 'WARM'
    case 3:
      return 'HOT'
    case 4:
      return 'OVERHEATED'
    case 5:
      return 'WARNING'
    case 6:
      return 'EMERGENCY'
    case 7:
      return 'ESCAPE'
    default:
      return 'UNKNOWN'
  }
}

@Entry
@Component
struct Index {
  @State message: string = 'Thermal + Traffic Test'

  // traffic
  @State downloadBytes: number = 0
  @State requestCount: number = 0
  @State failedCount: number = 0
  @State isTrafficRunning: boolean = false
  private stopTrafficFlag: boolean = false

  // thermal display
  @State reportCount: number = 0
  @State lastLevel: number = -1
  @State lastLevelName: string = ''
  @State lastPageName: string = ''
  @State lastDurationMs: number = 0
  @State lastTimestamp: number = 0
  @State lastIsForeground: boolean = true

  // current thermal level
  @State currentThermalLevel: number = -1
  @State currentThermalLevelName: string = 'UNKNOWN'

  // stress
  @State isCpuStressRunning: boolean = false
  @State isUiStressRunning: boolean = false
  @State cpuStressRounds: number = 0
  @State uiTick: number = 0

  private syncTimerId: number = -1
  private thermalPollTimerId: number = -1
  private uiStressTimerId: number = -1
  private stopStressFlag: boolean = false

  aboutToAppear(): void {
    this.syncFromStore()
    this.refreshThermalLevel()

    this.syncTimerId = setInterval((): void => {
      this.syncFromStore()
    }, 500)

    this.thermalPollTimerId = setInterval((): void => {
      this.refreshThermalLevel()
    }, 1000)
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

    this.stopUiStress()
    this.stopCpuStress()
    this.stopTraffic()
  }

  build() {
    Column({ space: 12 }) {
      Text(this.message)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

      Button('刷新显示')
        .onClick((): void => {
          this.syncFromStore()
          this.refreshThermalLevel()
        })

      // traffic
      Button(this.isTrafficRunning ? '下载流量中…' : '开始下载流量')
        .onClick((): void => {
          this.startDownloadTraffic()
        })

      Button('停止下载流量')
        .onClick((): void => {
          this.stopTraffic()
        })

      // stress
      Button(this.isCpuStressRunning ? 'CPU 热压中…' : '开始 CPU 热压测试')
        .onClick((): void => {
          this.startCpuStress()
        })

      Button('停止 CPU 热压测试')
        .onClick((): void => {
          this.stopCpuStress()
        })

      Button(this.isUiStressRunning ? 'UI 高频刷新中…' : '开始 UI 高频刷新')
        .onClick((): void => {
          this.startUiStress()
        })

      Button('停止 UI 高频刷新')
        .onClick((): void => {
          this.stopUiStress()
        })

      Button('模拟点击切换文本')
        .onClick((): void => {
          this.message = this.message === 'Thermal + Traffic Test' ? 'Welcome' : 'Thermal + Traffic Test'
        })

      Text(`下载状态: ${this.isTrafficRunning ? '运行中' : '已停止'}`)
      Text(`下载字节: ${this.downloadBytes}`)
      Text(`请求次数: ${this.requestCount}`)
      Text(`失败次数: ${this.failedCount}`)

      Text(`CPU热压状态: ${this.isCpuStressRunning ? '运行中' : '已停止'}`)
      Text(`UI刷新状态: ${this.isUiStressRunning ? '运行中' : '已停止'}`)
      Text(`CPU热压轮次: ${this.cpuStressRounds}`)
      Text(`UI刷新计数: ${this.uiTick}`)

      Text(`当前热档位: ${this.currentThermalLevel}`)
      Text(`当前热档位名称: ${this.currentThermalLevelName}`)

      Text(`thermal上报次数: ${this.reportCount}`)
      Text(`最近 level: ${this.lastLevel}`)
      Text(`最近 levelName: ${this.lastLevelName}`)
      Text(`最近 pageName: ${this.lastPageName}`)
      Text(`最近 durationMs: ${this.lastDurationMs}`)
      Text(`最近 timestamp: ${this.lastTimestamp}`)
      Text(`最近前台状态: ${this.lastIsForeground}`)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20)
  }

  // =========================
  // thermal display
  // =========================
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
    try {
      let level: number = thermal.getLevel()
      this.currentThermalLevel = level
      this.currentThermalLevelName = levelToName(level)
    } catch (_) {
      this.currentThermalLevel = -1
      this.currentThermalLevelName = 'UNKNOWN'
    }
  }

  // =========================
  // traffic
  // =========================
  private async startDownloadTraffic(): Promise<void> {
    if (this.isTrafficRunning) {
      this.message = '下载任务已在运行中'
      return
    }

    this.resetTrafficStats()
    this.isTrafficRunning = true
    this.stopTrafficFlag = false
    this.message = '开始下载流量测试'

    let durationMs: number = 10000
    let intervalMs: number = 500
    let stopAt: number = Date.now() + durationMs
    let url: string = 'https://www.baidu.com'

    while (!this.stopTrafficFlag && Date.now() < stopAt) {
      let ok: boolean = await this.doGetOnce(url)
      if (!ok) {
        this.failedCount += 1
      }
      await this.sleep(500)
      if (intervalMs !== 500) {
        // 占位，避免未使用变量风格问题
      }
    }

    this.isTrafficRunning = false
    this.message = '下载流量测试结束'
  }

  private async doGetOnce(url: string): Promise<boolean> {
    let httpRequest: http.HttpRequest = http.createHttp()

    try {
      let data: http.HttpResponse = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        readTimeout: 10000,
        connectTimeout: 10000
      })

      let result: string = ''
      if (typeof data.result === 'string') {
        result = data.result
      } else {
        result = JSON.stringify(data.result)
      }

      this.downloadBytes += result.length
      this.requestCount += 1
      this.message = '下载流量生成中'
      return true
    } catch (_) {
      this.message = '下载请求失败'
      return false
    } finally {
      httpRequest.destroy()
    }
  }

  private stopTraffic(): void {
    this.stopTrafficFlag = true
    this.isTrafficRunning = false
    hilog.info(DOMAIN, TAG, 'traffic stopped')
  }

  private resetTrafficStats(): void {
    this.downloadBytes = 0
    this.requestCount = 0
    this.failedCount = 0
  }

  // =========================
  // cpu stress
  // =========================
  private startCpuStress(): void {
    if (this.isCpuStressRunning) {
      this.message = 'CPU 热压已启动'
      return
    }

    this.isCpuStressRunning = true
    this.stopStressFlag = false
    this.cpuStressRounds = 0
    this.message = 'CPU 热压测试已启动'
    hilog.info(DOMAIN, TAG, 'cpu stress started')

    this.runCpuStressLoop()
  }

  private stopCpuStress(): void {
    this.stopStressFlag = true
    this.isCpuStressRunning = false
    hilog.info(DOMAIN, TAG, 'cpu stress stopped')
  }

  private async runCpuStressLoop(): Promise<void> {
    while (!this.stopStressFlag) {
      this.cpuStressRounds += 1

      this.burnCpuFor(950)
      this.refreshThermalLevel()

      if (this.currentThermalLevel >= 3) {
        this.message = `到达热档位 ${this.currentThermalLevelName}，自动停止CPU热压`
        this.stopCpuStress()
        break
      }

      await this.sleep(50)
    }
  }

  private burnCpuFor(durationMs: number): void {
    let end: number = Date.now() + durationMs
    let acc: number = 0

    while (Date.now() < end && !this.stopStressFlag) {
      for (let i: number = 1; i < 300000; i++) {
        acc += Math.sqrt(i % 997) * Math.sin(i) * Math.cos(i % 359)
      }
    }

    if (acc < 0) {
      hilog.debug(DOMAIN, TAG, `acc=${acc}`)
    }
  }

  // =========================
  // ui stress
  // =========================
  private startUiStress(): void {
    if (this.isUiStressRunning) {
      this.message = 'UI 高频刷新已启动'
      return
    }

    this.isUiStressRunning = true
    this.message = 'UI 高频刷新已启动'

    this.uiStressTimerId = setInterval((): void => {
      this.uiTick += 1
      this.message = `Thermal + Traffic Test ${this.uiTick}`
    }, 16)

    hilog.info(DOMAIN, TAG, 'ui stress started')
  }

  private stopUiStress(): void {
    if (this.uiStressTimerId !== -1) {
      clearInterval(this.uiStressTimerId)
      this.uiStressTimerId = -1
    }

    this.isUiStressRunning = false
    hilog.info(DOMAIN, TAG, 'ui stress stopped')
  }

  // =========================
  // utils
  // =========================
  private sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void): void => {
      setTimeout((): void => {
        resolve()
      }, ms)
    })
  }
}

function oom(): void {
  let hugeArray: number[] = new Array(Number.MAX_SAFE_INTEGER)
}