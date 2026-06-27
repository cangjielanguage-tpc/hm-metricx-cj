import { hilog } from '@kit.PerformanceAnalysisKit'
import { SectionHeader } from './SectionHeader'

const DOMAIN: number = 0x0021
const TAG: string = 'fps_scroll_test'
const SYNC_INTERVAL_MS: number = 500

/**
 * FPS / 滑动掉帧率测试卡片（入口 + 结果展示）。
 *
 * manual 姿势：FPS 在页面退出时上报、滑动掉帧率在滑动停止时上报。
 * 本卡片为入口——点击进入 FpsScrollTestPage 滑动列表，退出后回此页看上报结果。
 * 上报信息经 AppStorage 桥接（EntryAbility 回调 setOrCreate → 本卡片 get + 周期同步），
 * 复用 lastCrashText 的闭环模式。
 */
@Component
export struct FpsTestCard {
  pageStack: NavPathStack = new NavPathStack()

  @State lastFpsInfo: string = ''
  @State lastScrollHitchInfo: string = ''
  private syncTimerId: number = -1

  aboutToAppear(): void {
    this.syncFromStorage()
    this.syncTimerId = setInterval((): void => {
      this.syncFromStorage()
    }, SYNC_INTERVAL_MS)
  }

  aboutToDisappear(): void {
    if (this.syncTimerId !== -1) {
      clearInterval(this.syncTimerId)
      this.syncTimerId = -1
    }
  }

  build(): void {
    Column({ space: 6 }) {
      SectionHeader('帧率 / 滑动掉帧率 · FPS · ScrollHitch')

      Button('进入滑动测试页（退出时上报 FPS）')
        .width('100%')
        .onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('FpsScrollTestPage', ''))
        })

      Button('刷新显示')
        .width('100%')
        .onClick((): void => {
          this.syncFromStorage()
        })

      Divider().margin({ top: 4, bottom: 4 })

      Text('最近 FPS 上报（页面退出时）')
        .fontSize(13)
        .fontColor('#56657A')
      Text(this.lastFpsInfo.length > 0 ? this.lastFpsInfo : '（尚无，进入测试页滑动后退出）')
        .fontSize(13)
        .fontColor(this.lastFpsInfo.length > 0 ? '#3D4A5D' : '#9AA7B5')

      Divider().margin({ top: 4, bottom: 4 })

      Text('最近滑动掉帧率上报（滑动停止时）')
        .fontSize(13)
        .fontColor('#56657A')
      Text(this.lastScrollHitchInfo.length > 0 ? this.lastScrollHitchInfo : '（尚无，进入测试页滑动后停止）')
        .fontSize(13)
        .fontColor(this.lastScrollHitchInfo.length > 0 ? '#3D4A5D' : '#9AA7B5')
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor('#F7F9FC')
  }

  private syncFromStorage(): void {
    const fps: string | undefined = AppStorage.get<string>('lastFpsInfo')
    if (fps !== undefined && fps.length > 0) {
      this.lastFpsInfo = fps
    }
    const hitch: string | undefined = AppStorage.get<string>('lastScrollHitchInfo')
    if (hitch !== undefined && hitch.length > 0) {
      this.lastScrollHitchInfo = hitch
    }
  }
}
