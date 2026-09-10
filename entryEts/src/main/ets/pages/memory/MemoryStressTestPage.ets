import { hilog } from '@kit.PerformanceAnalysisKit'
import { ErrorEvent, MessageEvents, worker } from '@kit.ArkTS'
import { SectionHeader } from '../../components/SectionHeader'
import { getPageMemoryInfo, getProcessMemoryInfo } from '@cangjie-tpc/hm_metricx_cj_hybrid'

const DOMAIN: number = 0x0021
const TAG: string = 'memory_stress_test'
const BLOCK_BYTES: number = 4 * 1024 * 1024 // 主线程每轮 4MB
const MAX_MAIN_BLOCKS: number = 32 // 主线程累计上限 128MB

/**
 * 内存压力测试页（独立 NavDestination 页）。
 *
 * 用于验证内存模块 native 化（commit 6aa2f77）改动：
 *  - native PSS（OH_HiDebug_GetAppNativeMemInfo）随压力上扬、量级合理；
 *  - native rssLimit（OH_HiDebug_GetAppMemoryLimit）>0、与设备配额一致；
 *  - ArkTs VM 堆 used/limit 恒 0（无 native 等价物，业务确认置 0）；
 *  - ProcessMemoryInfo.pageName 上报为路由名 MemoryStressTestPage 而非 mainPage；
 *  - 主线程 5s 采样 + 主线程同步分配 + 拉取快照，无 THREAD_BLOCK_6S（修复目标）。
 *
 * 复用 CpuStressTestPage 的 NavDestination 约定：pageStack、aboutToDisappear 清理、
 * onBackPressed 回收。Worker 约定同 CpuBurnWorker：terminate() 强制停止。
 */
@Component
export struct MemoryStressTestPage {
  @State pageStack: NavPathStack = new NavPathStack()
  @State currentPageName: string = ''
  @State isMainAllocating: boolean = false
  @State isWorkerAllocating: boolean = false
  @State mainAllocMB: number = 0
  @State workerAllocMB: number = 0
  @State snapshotText: string = '（点击「拉取内存快照」查看）'

  private mainBlocks: Uint8Array[] = []
  private allocWorker: worker.ThreadWorker | null = null

  aboutToDisappear(): void {
    this.stopMainAlloc()
    this.stopWorkerAlloc()
  }

  build(): void {
    NavDestination() {
      Scroll() {
        Column({ space: 12 }) {
          Text('内存压力测试页面')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 16 })

          Text('此页面用于验证内存模块 native 化（commit 6aa2f77）')
            .fontSize(16)
            .fontColor('#3D4A5D')
          Text('预期：PSS/rssLimit 走 native C API，ArkTs VM 堆字段恒 0，主线程无 ANR')
            .fontSize(15)
            .fontColor('#56657A')
            .margin({ bottom: 20 })

          Divider().margin({ top: 8, bottom: 8 })
          Text(`当前页面名: ${this.currentPageName}`)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentPageName === 'MemoryStressTestPage' ? '#4CAF50' : '#F44336')

          Divider().margin({ top: 16, bottom: 16 })

          // 主线程压力（复现 ANR 场景：UI 线程同步分配 + 5s 采样 + 拉取快照）
          SectionHeader('主线程压力 / Main-Thread Alloc')
          Text(`主线程压力状态: ${this.isMainAllocating ? '运行中' : '已停止'}`)
          Text(`主线程累计分配: ${this.mainAllocMB} MB`)
          Button(this.isMainAllocating ? '主线程分配中…' : '开始主线程分配')
            .width('80%')
            .onClick((): void => {
              this.startMainAlloc()
            })
          Button('停止主线程分配')
            .width('80%')
            .onClick((): void => {
              this.stopMainAlloc()
            })

          Divider().margin({ top: 16, bottom: 16 })

          // Worker 压力（子线程分配，验证 pageName 上报 + 避免主线程自指）
          SectionHeader('Worker 压力 / Worker Alloc')
          Text(`Worker 压力状态: ${this.isWorkerAllocating ? '运行中' : '已停止'}`)
          Text(`Worker 累计分配: ${this.workerAllocMB} MB`)
          Button(this.isWorkerAllocating ? 'Worker 分配中…' : '开始 Worker 分配')
            .width('80%')
            .onClick((): void => {
              this.startWorkerAlloc()
            })
          Button('停止 Worker 分配')
            .width('80%')
            .onClick((): void => {
              this.stopWorkerAlloc()
            })

          Divider().margin({ top: 16, bottom: 16 })

          // 释放（清空主线程数组 + worker release）
          Button('释放全部内存（主线程数组 + Worker release）')
            .width('80%')
            .onClick((): void => {
              this.releaseAll()
            })

          Divider().margin({ top: 16, bottom: 16 })

          // 验证控件：拉取内存快照
          SectionHeader('内存快照验证 / Snapshot')
          Button('拉取内存快照（getPageMemoryInfo + getProcessMemoryInfo）')
            .width('80%')
            .onClick((): void => {
              this.takeSnapshot()
            })

          if (this.snapshotText.length > 0) {
            Text(this.snapshotText)
              .fontSize(12)
              .fontColor('#3D4A5D')
              .maxLines(40)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .backgroundColor('#FFFFFF')
              .borderRadius(6)
              .padding(6)
          }

          Button('返回主页')
            .width('80%')
            .margin({ top: 16 })
            .onClick((): void => {
              this.pageStack.pop()
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding(20)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onReady((context): void => {
      this.pageStack = context.pathStack
      this.currentPageName = context.pathInfo.name ?? 'unknown'
      hilog.info(DOMAIN, TAG, `MemoryStressTestPage onReady, name=${this.currentPageName}`)
    })
    .onBackPressed((): boolean => {
      this.stopMainAlloc()
      this.stopWorkerAlloc()
      this.pageStack.pop()
      return true
    })
  }

  /**
   * 主线程同步分配循环：每轮 4MB，累计到 MAX_MAIN_BLOCKS 后空转保持持有。
   * 同步阻塞 UI 线程，复现内存采样 ANR 场景。
   */
  private startMainAlloc(): void {
    if (this.isMainAllocating) {
      return
    }
    this.isMainAllocating = true
    hilog.info(DOMAIN, TAG, 'main-thread alloc started')

    // 同步分配循环（阻塞 UI 线程，与 CpuBurnWorker.burnCpuFor 同性质）
    while (this.isMainAllocating && this.mainBlocks.length < MAX_MAIN_BLOCKS) {
      const block: Uint8Array = new Uint8Array(BLOCK_BYTES)
      block[0] = 1 // 触发物理页提交，PSS 立即上涨
      this.mainBlocks.push(block)
    }
    this.mainAllocMB = this.mainBlocks.length * (BLOCK_BYTES / (1024 * 1024))
    hilog.info(DOMAIN, TAG, `main-thread alloc reached ${this.mainAllocMB} MB`)
  }

  private stopMainAlloc(): void {
    this.isMainAllocating = false
    hilog.info(DOMAIN, TAG, 'main-thread alloc stopped')
  }

  /**
   * 启动 Worker 子线程持续分配。
   */
  private startWorkerAlloc(): void {
    if (this.allocWorker !== null) {
      hilog.info(DOMAIN, TAG, 'worker already allocating')
      return
    }
    this.allocWorker = new worker.ThreadWorker('../../workers/MemAllocWorker')
    this.allocWorker.onmessage = (msg: MessageEvents): void => {
      hilog.info(DOMAIN, TAG, `MemAllocWorker: ${String(msg.data)}`)
      // 粗略估算 worker 分配量（release/start 消息含 blocks 计数）
      this.refreshWorkerAllocMB()
    }
    this.allocWorker.onerror = (e: ErrorEvent): void => {
      hilog.error(DOMAIN, TAG, `MemAllocWorker error: ${e.message}`)
    }
    this.isWorkerAllocating = true
    this.allocWorker.postMessage('start')
    hilog.info(DOMAIN, TAG, 'worker alloc started')
  }

  /**
   * 停止 Worker：while(allocating) 同步阻塞消息循环，postMessage('stop') 收不到，
   * 必须用 terminate() 强制终止（同 CpuStressTestPage.stopWorkerBurn 约定）。
   */
  private stopWorkerAlloc(): void {
    if (this.allocWorker === null) {
      this.isWorkerAllocating = false
      return
    }
    this.allocWorker.terminate()
    this.allocWorker = null
    this.isWorkerAllocating = false
    this.workerAllocMB = 0
    hilog.info(DOMAIN, TAG, 'worker alloc stopped')
  }

  private refreshWorkerAllocMB(): void {
    // Worker 端持有量无法直接读，仅用 256MB 上限做粗估显示
    this.workerAllocMB = this.isWorkerAllocating ? 256 : 0
  }

  /**
   * 释放主线程数组 + 通知 Worker release（触发 GC，PSS 不立即回落属正常）。
   */
  private releaseAll(): void {
    this.mainBlocks = []
    this.mainAllocMB = 0
    this.isMainAllocating = false
    if (this.allocWorker !== null) {
      this.allocWorker.postMessage('release')
    }
    hilog.info(DOMAIN, TAG, 'all memory released')
  }

  /**
   * 拉取内存快照并展示。命中主线程 native 调用路径（getPageMemoryInfo/
   * getProcessMemoryInfo → cjLibMemory.getProcessMemoryInfoInterop → native），
   * 与 5s 采样共用同一 native 路径，是 ANR 复现的可观测入口。
   */
  private takeSnapshot(): void {
    try {
      const page = getPageMemoryInfo()
      const proc = getProcessMemoryInfo()
      const KB_TO_MB: number = 1024

      const lines: string[] = [
        `=== 内存快照 ===`,
        `[Process] pid=${proc.pid} sampleCount=${proc.sampleCount}`,
        `[Process] avgMemory=${(proc.avgMemory / KB_TO_MB).toFixed(1)}MB maxMemory=${(proc.maxMemory / KB_TO_MB).toFixed(1)}MB`,
        `[Process] avgCJMemory=${(proc.avgCJMemory / KB_TO_MB).toFixed(1)}MB maxCJMemory=${(proc.maxCJMemory / KB_TO_MB).toFixed(1)}MB`,
        `[Process] avgArkTsMemory=${proc.avgArkTsMemory}(预期0) maxArkTsMemory=${proc.maxArkTsMemory}(预期0)`,
        `[Process] totalMemoryLimit=${(proc.totalMemoryLimit / KB_TO_MB).toFixed(1)}MB cjMemoryLimit=${(proc.cjMemoryLimit / KB_TO_MB).toFixed(1)}MB arkTsMemoryLimit=${proc.arkTsMemoryLimit}(预期0)`,
        `[Process] isTotalTop=${proc.isTotalTop} isCJTop=${proc.isCJTop} isArkTsTop=${proc.isArkTsTop}`,
        `[Process] memoryAvgUsageRate=${(proc.memoryAvgUsageRate * 100).toFixed(1)}% memoryMaxUsageRate=${(proc.memoryMaxUsageRate * 100).toFixed(1)}%`,
        `[Process] cjMemoryAvgUsageRate=${(proc.cjMemoryAvgUsageRate * 100).toFixed(1)}% arkTsMemoryAvgUsageRate=${(proc.arkTsMemoryAvgUsageRate * 100).toFixed(1)}%`,
        `[Page] pageName=${page.pageName} avgMemory=${(page.avgMemory / KB_TO_MB).toFixed(1)}MB`,
        `[Page] avgArkTsMemory=${page.avgArkTsMemory}(预期0) arkTsMemoryLimit=${page.arkTsMemoryLimit}(预期0)`,
        `[Page] memoryAvgUsageRate=${(page.memoryAvgUsageRate * 100).toFixed(1)}%`
      ]
      const text: string = lines.join('\n')
      this.snapshotText = text
      hilog.warn(DOMAIN, TAG, `===== 内存快照 =====\n${text}`)
    } catch (e) {
      const msg: string = `拉取快照失败: ${JSON.stringify(e)}`
      this.snapshotText = msg
      hilog.error(DOMAIN, TAG, msg)
    }
  }
}
