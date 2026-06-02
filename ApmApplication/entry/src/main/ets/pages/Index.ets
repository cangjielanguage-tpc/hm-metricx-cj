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
  @State pageStack: NavPathStack = new NavPathStack()

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
  private leakedArray: number[][] = []

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

  build(): void {
    Column() {
      Navigation(this.pageStack) {
        this.buildHomePage()
      }
      .id("root")
      .navDestination(this.pageMap)
    }
    .id('whiteScreenTestRoot')
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildHomePage(): void {
    Scroll() {
      Column({ space: 12 }) {
        Text(this.message)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)

        // 白屏测试按钮
        Button('WhiteScreen: Page Open Trigger Page')
          .onClick((): void => {
            this.pageStack.pushPath(new NavPathInfo('PageOpenTriggerPage', ''))
          })

        Button('WhiteScreen: Switch Result Trigger Page')
          .onClick((): void => {
            this.pageStack.pushPath(new NavPathInfo('SwitchResultTriggerPage', ''))
          })

        // 原有测试按钮
        Button('模拟 Freeze')
          .onClick((): void => {
            while (true) {
            }
          })
        Button('js leak')
          .type(ButtonType.Capsule)
          .margin({
            top: 20
          })
          .backgroundColor('#0D9FFB')
          .width('80%')
          .height('5%')
          .onClick(() => {
            for (let i = 0; i < 10000; i++) {
              this.leakedArray.push(new Array(500000).fill(1));
            }
          })
        Button('模拟 Crash')
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
          .onClick(() => {
            this.message = '准备触发 Crash';
            throw new Error("Simulated crash in ArkTS");
          })

        Button('刷新显示')
          .onClick((): void => {
            this.syncFromStore()
            this.refreshThermalLevel()
          })

        Button(this.isTrafficRunning ? '下载流量中…' : '开始下载流量')
          .onClick((): void => {
            this.startDownloadTraffic()
          })

        Button('停止下载流量')
          .onClick((): void => {
            this.stopTraffic()
          })

        Button('CPU 热压测试页面（验证路由路径）')
          .onClick((): void => {
            this.pageStack.pushPath(new NavPathInfo('CpuStressTestPage', ''))
          })

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
      .justifyContent(FlexAlign.Center)
      .padding(20)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private pageMap(name: string): void {
    if (name === 'BlankPage') {
      BlankPage()
    } else if (name === 'HalfBlankPage') {
      HalfBlankPage()
    } else if (name === 'SlowLoadPage') {
      SlowLoadPage()
    } else if (name === 'ImagePage') {
      ImagePage()
    } else if (name === 'SlowImagePage') {
      SlowImagePage()
    } else if (name === 'PageOpenTriggerPage') {
      PageOpenTriggerPage()
    } else if (name === 'SwitchResultTriggerPage') {
      SwitchResultTriggerPage()
    } else if (name === 'SwitchResultBlankPage') {
      SwitchResultBlankPage()
    } else if (name === 'CpuStressTestPage') {
      CpuStressTestPage()
    } else {
      this.buildHomePage()
    }
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

// ===================== BlankPage =====================
@Component
struct BlankPage {
  @State pageStack: NavPathStack = new NavPathStack()
  @State contentReady: boolean = false

  private revealTimer: number = -1
  private returnTimer: number = -1

  build(): void {
    NavDestination() {
      Stack() {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor('#FFFFFF')

        if (this.contentReady) {
          Column() {
            Text('Recovered From Page-Open White Screen')
              .fontSize(22)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 10 })
            Text('This demo blocks the UI thread before the first frame to trigger TTID timeout.')
              .fontSize(16)
              .fontColor('#3D4A5D')
              .margin({ bottom: 10 })
            Text('If MetricX is working, blankPage should report PAGE_OPEN + TIMEOUT.')
              .fontSize(15)
              .fontColor('#56657A')
          }
          .width('100%')
          .height('100%')
          .padding(24)
          .backgroundColor('#F3F8FF')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
      .id('whiteScreenTestRoot')
    }
    .hideTitleBar(true)
    .onReady((context): void => {
      this.pageStack = context.pathStack
      this.contentReady = false

      let whiteDurationMs: number = 6000
      const param: string = context.pathInfo.param as string
      if (param && param.length > 0) {
        const parsed: number = Number(param)
        if (!isNaN(parsed)) {
          whiteDurationMs = parsed
        }
      }

      const PAGE_OPEN_TTID_BLOCK_MS: number = 1500
      let blockDurationMs: number = PAGE_OPEN_TTID_BLOCK_MS
      if (whiteDurationMs < blockDurationMs) {
        blockDurationMs = whiteDurationMs
      }

      this.blockUiThread(blockDurationMs)

      const remainingWhiteMs: number = whiteDurationMs - blockDurationMs
      if (remainingWhiteMs <= 0) {
        this.revealContent()
      } else {
        this.revealTimer = setTimeout((): void => {
          this.revealContent()
        }, remainingWhiteMs)
      }
    })
    .onBackPressed((): boolean => {
      if (this.revealTimer !== -1) {
        clearTimeout(this.revealTimer)
        this.revealTimer = -1
      }
      if (this.returnTimer !== -1) {
        clearTimeout(this.returnTimer)
        this.returnTimer = -1
      }
      this.pageStack.pop()
      return true
    })
  }

  private revealContent(): void {
    if (this.contentReady) {
      return
    }
    this.contentReady = true
    if (this.revealTimer !== -1) {
      clearTimeout(this.revealTimer)
      this.revealTimer = -1
    }
    const WHITE_SCREEN_RECOVERY_STAY_MS: number = 1200
    this.returnTimer = setTimeout((): void => {
      this.pageStack.pop()
    }, WHITE_SCREEN_RECOVERY_STAY_MS)
  }

  private blockUiThread(durationMs: number): void {
    if (durationMs <= 0) {
      return
    }
    const start: number = Date.now()
    while (Date.now() - start < durationMs) {
    }
  }
}

// ===================== HalfBlankPage =====================
@Component
struct HalfBlankPage {
  @State pageStack: NavPathStack = new NavPathStack()
  private timerId: number = -1

  build(): void {
    NavDestination() {
      Column() {
        Row()
          .width('100%')
          .height('50%')
          .backgroundColor('#000000')
        Row()
          .width('100%')
          .height('50%')
          .backgroundColor('#FFFFFF')
      }
      .width('100%')
      .height('100%')
      .id('whiteScreenTestRoot')
    }
    .hideTitleBar(true)
    .onReady((context): void => {
      this.pageStack = context.pathStack

      let duration: number = 6000
      const param: string = context.pathInfo.param as string
      if (param && param.length > 0) {
        const parsed: number = Number(param)
        if (!isNaN(parsed)) {
          duration = parsed
        }
      }

      this.timerId = setTimeout((): void => {
        this.pageStack.pop()
      }, duration)
    })
    .onBackPressed((): boolean => {
      if (this.timerId !== -1) {
        clearTimeout(this.timerId)
      }
      this.pageStack.pop()
      return true
    })
  }
}

// ===================== ImagePage =====================
@Component
struct ImagePage {
  @State pageStack: NavPathStack = new NavPathStack()
  private timerId: number = -1

  build(): void {
    NavDestination() {
      Stack() {
        Image('https://pic.baike.soso.com/ugc/baikepic2/17155/20220223180002-2131977287_png_512_512_124034.jpg/0')
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      }
      .width('100%')
      .height('100%')
      .id('whiteScreenTestRoot')
    }
    .hideTitleBar(true)
    .onReady((context): void => {
      this.pageStack = context.pathStack

      let duration: number = 8000
      const param: string = context.pathInfo.param as string
      if (param && param.length > 0) {
        const parsed: number = Number(param)
        if (!isNaN(parsed)) {
          duration = parsed
        }
      }

      this.timerId = setTimeout((): void => {
        this.pageStack.pop()
      }, duration)
    })
    .onBackPressed((): boolean => {
      if (this.timerId !== -1) {
        clearTimeout(this.timerId)
      }
      this.pageStack.pop()
      return true
    })
  }
}

// ===================== SlowImagePage =====================
@Component
struct SlowImagePage {
  @State showImage: boolean = false
  @State pageStack: NavPathStack = new NavPathStack()
  private timerId: number = -1
  private returnTimerId: number = -1

  build(): void {
    NavDestination() {
      Stack() {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor('#FFFFFF')

        if (this.showImage) {
          Image('https://pic.baike.soso.com/ugc/baikepic2/17155/20220223180002-2131977287_png_512_512_124034.jpg/0')
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
      .id('whiteScreenTestRoot')
    }
    .hideTitleBar(true)
    .onReady((context): void => {
      this.pageStack = context.pathStack
      this.showImage = false

      let delayMs: number = 8000
      const param: string = context.pathInfo.param as string
      if (param && param.length > 0) {
        const parsed: number = Number(param)
        if (!isNaN(parsed)) {
          delayMs = parsed
        }
      }

      this.timerId = setTimeout((): void => {
        this.showImage = true
        if (this.returnTimerId !== -1) {
          clearTimeout(this.returnTimerId)
        }
        this.returnTimerId = setTimeout((): void => {
          this.pageStack.pop()
        }, 1000)
      }, delayMs)
    })
    .onBackPressed((): boolean => {
      if (this.timerId !== -1) {
        clearTimeout(this.timerId)
      }
      if (this.returnTimerId !== -1) {
        clearTimeout(this.returnTimerId)
      }
      this.pageStack.pop()
      return true
    })
  }
}

// ===================== SlowLoadPage =====================
@Component
struct SlowLoadPage {
  @State loadingStep: number = 0
  @State contentReady: boolean = false
  @State pageStack: NavPathStack = new NavPathStack()

  private animationTimerId: number = -1
  private contentTimerId: number = -1
  private returnTimerId: number = -1

  build(): void {
    NavDestination() {
      Stack() {
        Column() {
          if (!this.contentReady) {
            Text(this.loadingLabel())
              .fontSize(24)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 16 })

            Row() {
              Row().width(52).height(12).backgroundColor('#E8E8E8').borderRadius(6)
              Row().width(120).height(12).backgroundColor('#D8D8D8').borderRadius(6).margin({ top: 12 })
              Row().width(88).height(12).backgroundColor('#E8E8E8').borderRadius(6).margin({ top: 12 })
            }
            .width('100%')
            .margin({ bottom: 24 })

            Text('Content is still loading, but frames keep updating.')
              .fontSize(16)
              .fontColor('#666666')
          } else {
            Image('https://pic.baike.soso.com/ugc/baikepic2/17155/20220223180002-2131977287_png_512_512_124034.jpg/0')
              .width('100%')
              .height(220)
              .objectFit(ImageFit.Cover)
              .margin({ bottom: 18 })
            Text('Content loaded')
              .fontSize(22)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 8 })
            Text('This page simulates a slow-loading business page.')
              .fontSize(16)
              .fontColor('#666666')
          }
        }
        .width('100%')
        .height('100%')
        .padding(24)
        .backgroundColor('#FFFFFF')
      }
      .width('100%')
      .height('100%')
      .id('whiteScreenTestRoot')
    }
    .hideTitleBar(true)
    .onReady((context): void => {
      this.pageStack = context.pathStack

      let delay: number = 8000
      const param: string = context.pathInfo.param as string
      if (param && param.length > 0) {
        const parsed: number = Number(param)
        if (!isNaN(parsed)) {
          delay = parsed
        }
      }

      this.animationTimerId = setTimeout((): void => {
        this.advanceLoading()
      }, 180)
      this.contentTimerId = setTimeout((): void => {
        this.finishLoading()
      }, delay)
    })
    .onBackPressed((): boolean => {
      this.clearTimers()
      this.pageStack.pop()
      return true
    })
  }

  private loadingLabel(): string {
    const labels: Array<string> = ['Loading', 'Loading.', 'Loading..', 'Loading...']
    const idx: number = this.loadingStep % labels.length
    return labels[idx]
  }

  private advanceLoading(): void {
    if (this.contentReady) {
      return
    }
    this.loadingStep = (this.loadingStep + 1) % 4
    this.animationTimerId = setTimeout((): void => {
      this.advanceLoading()
    }, 180)
  }

  private finishLoading(): void {
    if (this.contentReady) {
      return
    }
    this.contentReady = true
    if (this.animationTimerId !== -1) {
      clearTimeout(this.animationTimerId)
      this.animationTimerId = -1
    }
    this.returnTimerId = setTimeout((): void => {
      this.pageStack.pop()
    }, 1500)
  }

  private clearTimers(): void {
    if (this.animationTimerId !== -1) {
      clearTimeout(this.animationTimerId)
      this.animationTimerId = -1
    }
    if (this.contentTimerId !== -1) {
      clearTimeout(this.contentTimerId)
      this.contentTimerId = -1
    }
    if (this.returnTimerId !== -1) {
      clearTimeout(this.returnTimerId)
      this.returnTimerId = -1
    }
  }
}

// ===================== PageOpenTriggerPage =====================
@Component
struct PageOpenTriggerPage {
  @State pageStack: NavPathStack = new NavPathStack()

  build(): void {
    NavDestination() {
      Column() {
        Text('Page-open white screen trigger page')
          .fontSize(20)
          .margin({ bottom: 12 })
        Text('Expected Positive means the detector should report white screen.')
          .fontSize(16)
          .margin({ bottom: 8 })
        Text('Control pages are for contrast and should not be treated as real white screens.')
          .fontSize(15)
          .fontColor('#666666')
          .margin({ bottom: 20 })
        Button('Go To TTID Timeout White Screen').onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('BlankPage', '8000'))
        })
        Button('Go To Half Blank Control Page').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('HalfBlankPage', '8000'))
        })
        Button('Go To Image Control Page').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('ImagePage', '8000'))
        })
        Button('Go To Delayed Image Page (Experimental)').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('SlowImagePage', '8000'))
        })
        Button('Go To Slow Load Control Page').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('SlowLoadPage', '8000'))
        })
        Button('Back To Home').margin({ top: 16 }).onClick((): void => {
          this.pageStack.pop()
        })
      }
      .width('100%')
      .height('100%')
      .padding(24)
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
    .onReady((context): void => {
      this.pageStack = context.pathStack
    })
    .onBackPressed((): boolean => {
      this.pageStack.pop()
      return true
    })
  }
}

// ===================== SwitchResultTriggerPage =====================
@Component
struct SwitchResultTriggerPage {
  @State pageStack: NavPathStack = new NavPathStack()

  build(): void {
    NavDestination() {
      Column() {
        Text('Switch-result white screen trigger page')
          .fontSize(20)
          .margin({ bottom: 12 })
        Text('The first button keeps the next page white for a while before real content appears.')
          .fontSize(16)
          .margin({ bottom: 8 })
        Text('Other buttons are contrast pages for manual comparison.')
          .fontSize(15)
          .fontColor('#666666')
          .margin({ bottom: 20 })
        Button('Go To Switch-Result White Screen').onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('SwitchResultBlankPage', '8000'))
        })
        Button('Go To Switch-Result Half Blank Control').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('HalfBlankPage', '8000'))
        })
        Button('Go To Switch-Result Image Control').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('ImagePage', '8000'))
        })
        Button('Go To Switch-Result Delayed Image').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('SlowImagePage', '8000'))
        })
        Button('Go To Switch-Result Slow Load Control').margin({ top: 12 }).onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('SlowLoadPage', '8000'))
        })
        Button('Back To Home').margin({ top: 16 }).onClick((): void => {
          this.pageStack.pop()
        })
      }
      .width('100%')
      .height('100%')
      .padding(24)
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
    .onReady((context): void => {
      this.pageStack = context.pathStack
    })
    .onBackPressed((): boolean => {
      this.pageStack.pop()
      return true
    })
  }
}

// ===================== SwitchResultBlankPage =====================
@Component
struct SwitchResultBlankPage {
  @State pageStack: NavPathStack = new NavPathStack()
  @State contentReady: boolean = false

  private revealTimer: number = -1
  private returnTimer: number = -1

  build(): void {
    NavDestination() {
      Stack() {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor('#FFFFFF')

        if (this.contentReady) {
          Column() {
            Text('Recovered From Switch-Result White Screen')
              .fontSize(22)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 10 })
            Text('The destination page stayed fully white before business content appeared.')
              .fontSize(16)
              .fontColor('#3D4A5D')
              .margin({ bottom: 10 })
            Text('If MetricX is working, switchResultBlankPage should report PAGE_SWITCH_RESULT + CONTENT_MISSING.')
              .fontSize(15)
              .fontColor('#56657A')
          }
          .width('100%')
          .height('100%')
          .padding(24)
          .backgroundColor('#F6FBFF')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
      .id('whiteScreenTestRoot')
    }
    .hideTitleBar(true)
    .onReady((context): void => {
      this.pageStack = context.pathStack
      this.contentReady = false

      let durationMs: number = 8000
      const param: string = context.pathInfo.param as string
      if (param && param.length > 0) {
        const parsed: number = Number(param)
        if (!isNaN(parsed)) {
          durationMs = parsed
        }
      }

      this.revealTimer = setTimeout((): void => {
        this.revealContent()
      }, durationMs)
    })
    .onBackPressed((): boolean => {
      if (this.revealTimer !== -1) {
        clearTimeout(this.revealTimer)
        this.revealTimer = -1
      }
      if (this.returnTimer !== -1) {
        clearTimeout(this.returnTimer)
        this.returnTimer = -1
      }
      this.pageStack.pop()
      return true
    })
  }

  private revealContent(): void {
    if (this.contentReady) {
      return
    }
    this.contentReady = true
    if (this.revealTimer !== -1) {
      clearTimeout(this.revealTimer)
      this.revealTimer = -1
    }
    const WHITE_SCREEN_RECOVERY_STAY_MS: number = 1200
    this.returnTimer = setTimeout((): void => {
      this.pageStack.pop()
    }, WHITE_SCREEN_RECOVERY_STAY_MS)
  }
}

function oom(): void {
  let hugeArray: number[] = new Array(Number.MAX_SAFE_INTEGER)
}

// ===================== CpuStressTestPage =====================
// 用于验证 HighCpuReportInfo.pageName 是否正确上报路由路径
@Component
struct CpuStressTestPage {
  @State pageStack: NavPathStack = new NavPathStack()
  @State isCpuStressRunning: boolean = false
  @State cpuStressRounds: number = 0
  @State currentThermalLevel: number = -1
  @State currentThermalLevelName: string = 'UNKNOWN'
  @State currentPageName: string = ''  // 显示当前上报的页面名称

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

          // 路由路径验证提示
          Text('此页面用于验证 HighCpuReportInfo.pageName')
            .fontSize(16)
            .fontColor('#3D4A5D')
          Text('预期：pageName 应为 "CpuStressTestPage" 而非 "mainPage"')
            .fontSize(15)
            .fontColor('#56657A')
            .margin({ bottom: 20 })

          // 当前状态显示
          Divider().margin({ top: 8, bottom: 8 })
          Text(`CPU 热压状态: ${this.isCpuStressRunning ? '运行中' : '已停止'}`)
          Text(`热压轮次: ${this.cpuStressRounds}`)
          Text(`当前热档位: ${this.currentThermalLevel}`)
          Text(`热档位名称: ${this.currentThermalLevelName}`)
          Text(`当前页面名: ${this.currentPageName}`)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentPageName === 'CpuStressTestPage' ? '#4CAF50' : '#F44336')

          Divider().margin({ top: 16, bottom: 16 })

          // 控制按钮
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
      }, 1000)
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
    while (!this.stopStressFlag) {
      this.cpuStressRounds += 1

      this.burnCpuFor(950)
      this.refreshThermalLevel()

      if (this.currentThermalLevel >= 3) {
        hilog.info(DOMAIN, TAG, `CpuStressTestPage: thermal level ${this.currentThermalLevelName}, auto stop`)
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

  private sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void): void => {
      setTimeout((): void => {
        resolve()
      }, ms)
    })
  }
}