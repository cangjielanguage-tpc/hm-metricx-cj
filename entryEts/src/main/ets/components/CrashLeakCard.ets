import { SectionHeader } from './SectionHeader'

const LEAK_BATCH: number = 10000
const LEAK_ARRAY_SIZE: number = 500000

/**
 * 异常触发卡片:Freeze(死循环)、Crash(抛异常)、JS 内存泄漏(数组堆积)。
 * 用于验证 MetricX 的 freeze / crash / OOM 监控上报。
 */
@Component
export struct CrashLeakCard {
  @State message: string = ''
  private leakedArray: number[][] = []

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
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor('#F7F9FC')
  }
}
