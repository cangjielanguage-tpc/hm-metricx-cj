import { hilog } from '@kit.PerformanceAnalysisKit'
import { SectionHeader } from './SectionHeader'

const DOMAIN: number = 0x0021
const TAG: string = 'memory_stress_test'
const BLOCK_BYTES: number = 4 * 1024 * 1024 // 每轮 4MB
const MAX_MAIN_BLOCKS: number = 32 // 主线程累计上限 128MB

/**
 * 首页内存压力卡片。
 *
 * 轻量入口：主线程同步分配启停 + 状态展示 + 跳转独立测试页。
 * 不在此调 getPageMemoryInfo（避免首页高频 native 调用），
 * 完整验证控件在 MemoryStressTestPage。
 * 逻辑约定同 CpuStressCard。
 */
@Component
export struct MemoryStressCard {
  @State isRunning: boolean = false
  @State allocMB: number = 0
  @State message: string = ''
  private mainBlocks: Uint8Array[] = []
  pageStack: NavPathStack = new NavPathStack()

  build(): void {
    Column({ space: 6 }) {
      SectionHeader('内存压力 / Memory Stress')

      Button(this.isRunning ? '主线程分配中…' : '开始主线程分配')
        .width('100%')
        .onClick((): void => {
          this.startAlloc()
        })

      Button('停止主线程分配')
        .width('100%')
        .onClick((): void => {
          this.stopAlloc()
        })

      Button('进入内存测试页（完整验证）')
        .width('100%')
        .onClick((): void => {
          this.pageStack.pushPath(new NavPathInfo('MemoryStressTestPage', ''))
        })

      Text(`压力状态: ${this.isRunning ? '运行中' : '已停止'}`)
      Text(`累计分配: ${this.allocMB} MB`)
      Text(this.message)
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor('#F7F9FC')
  }

  private startAlloc(): void {
    if (this.isRunning) {
      this.message = '主线程分配已启动'
      return
    }
    this.isRunning = true
    this.message = '主线程分配已启动'
    hilog.info(DOMAIN, TAG, 'memory stress started')

    while (this.isRunning && this.mainBlocks.length < MAX_MAIN_BLOCKS) {
      const block: Uint8Array = new Uint8Array(BLOCK_BYTES)
      block[0] = 1
      this.mainBlocks.push(block)
    }
    this.allocMB = this.mainBlocks.length * (BLOCK_BYTES / (1024 * 1024))
    hilog.info(DOMAIN, TAG, `memory stress reached ${this.allocMB} MB`)
  }

  private stopAlloc(): void {
    this.isRunning = false
    hilog.info(DOMAIN, TAG, 'memory stress stopped')
  }
}
