import { parseDuration, isKeepParam } from '../../common/PageParamParser'

const PAGE_OPEN_TTID_BLOCK_MS: number = 1500
const DEFAULT_WHITE_MS: number = 6000
const RECOVERY_STAY_MS: number = 1200

/**
 * 白屏测试页(Page-Open 场景)。
 *
 * 行为:
 * - param='keep':跳过白屏自恢复与自动 pop,由调用方主动 pop(用于页面流量增量测试)。
 * - param 为数字串:覆盖白屏总时长(ms)。
 * - 默认 6000ms:阻塞 UI 1500ms(触发 TTID 超时) + 剩余时间白屏 → 内容显现 → 1200ms 后自动 pop。
 *
 * 保留 .id('whiteScreenTestRoot') 作为白屏快照锚点。
 */
@Component
export struct BlankPage {
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

      const param: string = context.pathInfo.param as string
      // 'keep':跳过自动 pop 定时器,由调用方主动 pop(页面流量增量测试用)。
      if (isKeepParam(param)) {
        this.contentReady = true
        return
      }

      const whiteDurationMs: number = parseDuration(param, DEFAULT_WHITE_MS)
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
      this.clearTimers()
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
    this.returnTimer = setTimeout((): void => {
      this.pageStack.pop()
    }, RECOVERY_STAY_MS)
  }

  private blockUiThread(durationMs: number): void {
    if (durationMs <= 0) {
      return
    }
    const start: number = Date.now()
    while (Date.now() - start < durationMs) {
    }
  }

  private clearTimers(): void {
    if (this.revealTimer !== -1) {
      clearTimeout(this.revealTimer)
      this.revealTimer = -1
    }
    if (this.returnTimer !== -1) {
      clearTimeout(this.returnTimer)
      this.returnTimer = -1
    }
  }
}
