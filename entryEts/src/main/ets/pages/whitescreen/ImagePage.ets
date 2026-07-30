import { parseDuration } from '../../common/PageParamParser'

const DEFAULT_DURATION_MS: number = 8000

const IMAGE_URL: string =
  'https://pic.baike.soso.com/ugc/baikepic2/17155/20220223180002-2131977287_png_512_512_124034.jpg/0'

/**
 * 图片控制页:首帧即加载图片,用于白屏检测对照(有内容不应判为白屏)。
 */
@Component
export struct ImagePage {
  @State pageStack: NavPathStack = new NavPathStack()
  private timerId: number = -1

  build(): void {
    NavDestination() {
      Stack() {
        Image(IMAGE_URL)
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
