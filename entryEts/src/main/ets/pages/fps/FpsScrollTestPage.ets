import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN: number = 0x0021
const TAG: string = 'fps_scroll_test'
const ITEM_COUNT: number = 60

/**
 * FPS / 滑动掉帧率测试页（manual 姿势）。
 *
 * manual 约定：
 * - FPS 在「页面退出时」上报（initPageEventHandler 的 reportFpsInfo 回调）；
 * - 滑动掉帧率在「滑动停止时」上报（initScrollEventHandler 的 reportPageScrollInfo 回调）。
 *
 * 本页提供可垂直滑动的 List：上下滑动→停止触发 ScrollHitchInfo 上报；
 * 按返回退出触发 FpsEventInfo 上报。上报结果经 AppStorage 回吐首页 FpsTestCard 展示。
 *
 * 本页不自行 setInterval 制造重绘——靠真实滑动产生帧数据，贴合线上场景。
 */
@Component
export struct FpsScrollTestPage {
  private pageStack: NavPathStack = new NavPathStack()
  @State private items: string[] = []

  aboutToAppear(): void {
    let arr: string[] = []
    for (let i = 0; i < ITEM_COUNT; i++) {
      arr.push(`列表项 ${i + 1} —— 上下滑动以产生帧数据`)
    }
    this.items = arr
  }

  build(): void {
    NavDestination() {
      Column({ space: 12 }) {
        Text('FPS / 滑动掉帧率测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Text('上下滑动下方列表，停止后触发掉帧率上报；按返回退出触发 FPS 上报')
          .fontSize(13)
          .fontColor('#56657A')

        List({ space: 8 }) {
          ForEach(this.items, (item: string, index: number) => {
            ListItem() {
              Text(item)
                .fontSize(16)
                .padding(12)
                .width('100%')
                .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F0F3F7')
                .borderRadius(8)
            }
          }, (item: string) => { return item })
        }
        .width('100%')
        .layoutWeight(1)
        .padding(12)
      }
      .width('100%')
      .height('100%')
      .padding(16)
    }
    .hideTitleBar(true)
    .onReady((context): void => {
      this.pageStack = context.pathStack
      hilog.info(DOMAIN, TAG, `FpsScrollTestPage onReady, name=${context.pathInfo.name ?? 'unknown'}`)
    })
    .onBackPressed((): boolean => {
      this.pageStack.pop()
      return true
    })
  }
}
