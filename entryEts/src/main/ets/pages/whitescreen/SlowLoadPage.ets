import { parseDuration } from '../../common/PageParamParser'

const DEFAULT_DELAY_MS: number = 8000
const LOADING_ANIM_INTERVAL_MS: number = 180
const RECOVERY_STAY_MS: number = 1500

const IMAGE_URL: string =
  'https://pic.baike.soso.com/ugc/baikepic2/17155/20220223180002-2131977287_png_512_512_124034.jpg/0'

const LOADING_LABELS: string[] = ['Loading', 'Loading.', 'Loading..', 'Loading...']

/**
 * 慢加载页:骨架屏动画期间帧持续刷新,延迟 delayMs 后加载真实内容,停留 1.5s 自动 pop。
 * 用于白屏检测对照(有帧活动不应判为白屏)。
 */
@Component
export struct SlowLoadPage {
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
            Image(IMAGE_URL)
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

      const delay: number = parseDuration(context.pathInfo.param as string, DEFAULT_DELAY_MS)
      this.animationTimerId = setTimeout((): void => {
        this.advanceLoading()
      }, LOADING_ANIM_INTERVAL_MS)
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
    const idx: number = this.loadingStep % LOADING_LABELS.length
    return LOADING_LABELS[idx]
  }

  private advanceLoading(): void {
    if (this.contentReady) {
      return
    }
    this.loadingStep = (this.loadingStep + 1) % LOADING_LABELS.length
    this.animationTimerId = setTimeout((): void => {
      this.advanceLoading()
    }, LOADING_ANIM_INTERVAL_MS)
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
    }, RECOVERY_STAY_MS)
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
