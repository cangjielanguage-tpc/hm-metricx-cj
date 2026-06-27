import { SectionHeader } from './SectionHeader'

const SYNC_INTERVAL_MS: number = 500
const LEAK_BATCH: number = 10000
const LEAK_ARRAY_SIZE: number = 500000

/**
 * 异常触发卡片:Freeze(死循环)、Crash(抛异常)、JS 内存泄漏(数组堆积)。
 *
 * 上方为触发按钮,下方用 Text 展示最近一次 crash/freeze 上报信息。
 * 注意:crash/freeze 触发后应用会被系统杀并重启,上报信息经 AppStorage
 * 在重启后回吐(由 EntryAbility 的 initCrashHandler/initFreezeHandler 回调写入)。
 * leak(OOM)走 crash 回调,归入 lastCrashText。
 */
@Component
export struct CrashLeakCard {
  @State message: string = ''
  @State lastCrashText: string = ''
  @State lastFreezeText: string = ''
  @State crashExpanded: boolean = false
  @State freezeExpanded: boolean = false
  private leakedArray: number[][] = []
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
    Column({ space: 8 }) {
      SectionHeader('异常触发 / Crash · Freeze · Leak')

      Button('模拟 Freeze')
        .width('100%')
        .onClick((): void => {
          while (true) {
          }
        })

      Button('模拟 Crash')
        .width('100%')
        .onClick((): void => {
          this.message = '准备触发 Crash'
          throw new Error('Simulated crash in ArkTS')
        })

      Button('js leak')
        .width('100%')
        .onClick((): void => {
          for (let i: number = 0; i < LEAK_BATCH; i++) {
            this.leakedArray.push(new Array(LEAK_ARRAY_SIZE).fill(1))
          }
        })

      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(13)
          .fontColor('#9AA7B5')
      }

      Divider().margin({ top: 4, bottom: 4 })

      // 上次 crash 上报（重启回吐，含 OOM/leak 走此回调）
      if (this.lastCrashText.length > 0) {
        Button(this.crashExpanded ? '收起上次 Crash ▲' : '上次 Crash（重启回吐） ▼')
          .fontColor('#F44336')
          .width('100%')
          .onClick((): void => {
            this.crashExpanded = !this.crashExpanded
          })

        if (this.crashExpanded) {
          Text(this.lastCrashText)
            .fontSize(11)
            .fontColor('#3D4A5D')
            .maxLines(40)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .backgroundColor('#FFFFFF')
            .borderRadius(6)
            .padding(6)
        }
      } else {
        Text('上次 Crash:（尚无，触发 Crash/leak 后重启可见）')
          .fontSize(12)
          .fontColor('#9AA7B5')
      }

      // 上次 freeze 上报（重启回吐）
      if (this.lastFreezeText.length > 0) {
        Button(this.freezeExpanded ? '收起上次 Freeze ▲' : '上次 Freeze（重启回吐） ▼')
          .fontColor('#F44336')
          .width('100%')
          .onClick((): void => {
            this.freezeExpanded = !this.freezeExpanded
          })

        if (this.freezeExpanded) {
          Text(this.lastFreezeText)
            .fontSize(11)
            .fontColor('#3D4A5D')
            .maxLines(40)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .backgroundColor('#FFFFFF')
            .borderRadius(6)
            .padding(6)
        }
      } else {
        Text('上次 Freeze:（尚无，触发 Freeze 后重启可见）')
          .fontSize(12)
          .fontColor('#9AA7B5')
      }
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor('#F7F9FC')
  }

  private syncFromStorage(): void {
    const crash: string | undefined = AppStorage.get<string>('lastCrashText')
    if (crash !== undefined && crash.length > 0) {
      this.lastCrashText = crash
    }
    const freeze: string | undefined = AppStorage.get<string>('lastFreezeText')
    if (freeze !== undefined && freeze.length > 0) {
      this.lastFreezeText = freeze
    }
  }
}
