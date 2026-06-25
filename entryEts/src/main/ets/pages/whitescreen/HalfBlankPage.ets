import { parseDuration } from '../../common/PageParamParser'

const DEFAULT_DURATION_MS: number = 6000

/**
 * 半白屏控制页:上半黑、下半白,用于白屏检测对照(部分白色不应判为白屏)。
 * param 为数字串时覆盖停留时长;到达时长后自动 pop。
 */
@Component
export struct HalfBlankPage {
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

      const duration: number = parseDuration(context.pathInfo.param as string, DEFAULT_DURATION_MS)
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
