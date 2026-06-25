import { parseDuration } from '../../common/PageParamParser'

const DEFAULT_DURATION_MS: number = 8000
const RECOVERY_STAY_MS: number = 1200

/**
 * Switch-Result 白屏测试页:切到本页后白屏 durationMs,再显现内容,停留 1.2s 自动 pop。
 * 预期 MetricX 应上报 PAGE_SWITCH_RESULT + CONTENT_MISSING。
 */
@Component
export struct SwitchResultBlankPage {
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

      const durationMs: number = parseDuration(context.pathInfo.param as string, DEFAULT_DURATION_MS)
      this.revealTimer = setTimeout((): void => {
        this.revealContent()
      }, durationMs)
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
