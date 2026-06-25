import { parseDuration } from '../../common/PageParamParser'

const DEFAULT_DELAY_MS: number = 8000
const REVEAL_STAY_MS: number = 1000

const IMAGE_URL: string =
  'https://pic.baike.soso.com/ugc/baikepic2/17155/20220223180002-2131977287_png_512_512_124034.jpg/0'

/**
 * 延迟图片页:先白屏 delayMs,再加载图片,停留 1s 后自动 pop。
 * 用于白屏检测对照(延迟显现内容)。
 */
@Component
export struct SlowImagePage {
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
          Image(IMAGE_URL)
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

      const delayMs: number = parseDuration(context.pathInfo.param as string, DEFAULT_DELAY_MS)
      this.timerId = setTimeout((): void => {
        this.showImage = true
        if (this.returnTimerId !== -1) {
          clearTimeout(this.returnTimerId)
        }
        this.returnTimerId = setTimeout((): void => {
          this.pageStack.pop()
        }, REVEAL_STAY_MS)
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
