import { BlankPage } from './whitescreen/BlankPage'
import { HalfBlankPage } from './whitescreen/HalfBlankPage'
import { ImagePage } from './whitescreen/ImagePage'
import { SlowImagePage } from './whitescreen/SlowImagePage'
import { SlowLoadPage } from './whitescreen/SlowLoadPage'
import { SwitchResultBlankPage } from './whitescreen/SwitchResultBlankPage'
import { PageOpenTriggerPage } from './whitescreen/PageOpenTriggerPage'
import { SwitchResultTriggerPage } from './whitescreen/SwitchResultTriggerPage'
import { CpuStressTestPage } from './cpu/CpuStressTestPage'
import { FpsScrollTestPage } from './fps/FpsScrollTestPage'
import { MemoryStressTestPage } from './memory/MemoryStressTestPage'
import { ThermalInfoCard } from '../components/ThermalInfoCard'
import { TrafficTestCard } from '../components/TrafficTestCard'
import { CpuStressCard } from '../components/CpuStressCard'
import { FpsTestCard } from '../components/FpsTestCard'
import { CrashLeakCard } from '../components/CrashLeakCard'
import { MemoryStressCard } from '../components/MemoryStressCard'

/**
 * 应用首页:Navigation 容器 + pageMap 路由 + 各功能卡片。
 *
 * 路由说明:NavDestination 页面通过 pageMap 按结构名装载,无需在 main_pages.json 注册。
 * 子页面通过 context.pathStack 与首页共享同一个 NavPathStack。
 */
@Entry
@Component
struct Index {
  @State pageStack: NavPathStack = new NavPathStack()

  build(): void {
    Column() {
      Navigation(this.pageStack) {
        this.buildHomePage()
      }
      .id('root')
      .navDestination(this.pageMap)
    }
    .id('whiteScreenTestRoot')
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildHomePage(): void {
    Scroll() {
      Column({ space: 12 }) {
        Text('Thermal + Traffic Test')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)

        // 白屏测试入口
        Button('WhiteScreen: Page Open Trigger Page')
          .width('100%')
          .onClick((): void => {
            this.pageStack.pushPath(new NavPathInfo('PageOpenTriggerPage', ''))
          })

        Button('WhiteScreen: Switch Result Trigger Page')
          .width('100%')
          .onClick((): void => {
            this.pageStack.pushPath(new NavPathInfo('SwitchResultTriggerPage', ''))
          })

        Button('CPU 热压测试页面（验证路由路径）')
          .width('100%')
          .onClick((): void => {
            this.pageStack.pushPath(new NavPathInfo('CpuStressTestPage', ''))
          })

        Button('内存压力测试页面（验证 native PSS/rssLimit）')
          .width('100%')
          .onClick((): void => {
            this.pageStack.pushPath(new NavPathInfo('MemoryStressTestPage', ''))
          })

        Divider().margin({ top: 4, bottom: 4 })

        // 功能卡片(各自维护状态与定时器)
        ThermalInfoCard()
        TrafficTestCard({ pageStack: this.pageStack })
        CpuStressCard()
        FpsTestCard({ pageStack: this.pageStack })
        CrashLeakCard()
        MemoryStressCard({ pageStack: this.pageStack })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding(20)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private pageMap(name: string): void {
    if (name === 'BlankPage') {
      BlankPage()
    } else if (name === 'HalfBlankPage') {
      HalfBlankPage()
    } else if (name === 'SlowLoadPage') {
      SlowLoadPage()
    } else if (name === 'ImagePage') {
      ImagePage()
    } else if (name === 'SlowImagePage') {
      SlowImagePage()
    } else if (name === 'PageOpenTriggerPage') {
      PageOpenTriggerPage()
    } else if (name === 'SwitchResultTriggerPage') {
      SwitchResultTriggerPage()
    } else if (name === 'SwitchResultBlankPage') {
      SwitchResultBlankPage()
    } else if (name === 'CpuStressTestPage') {
      CpuStressTestPage()
    } else if (name === 'MemoryStressTestPage') {
      MemoryStressTestPage()
    } else if (name === 'FpsScrollTestPage') {
      FpsScrollTestPage()
    }
  }
}
