import http from '@ohos.net.http'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { getAndResetCurrentPageTraffic } from '@cangjie-tpc/hm_metricx_cj_hybrid'
import { SectionHeader } from './SectionHeader'

const DOMAIN: number = 0x0021
const TAG: string = 'thermal_traffic_test'

const DOWNLOAD_URL: string = 'https://www.baidu.com'
const DOWNLOAD_DURATION_MS: number = 10000
const DOWNLOAD_INTERVAL_MS: number = 500
const HTTP_TIMEOUT_MS: number = 10000
const PAGE_TRAFFIC_SAFETY_TIMEOUT_MS: number = 20000
const PAGE_TRAFFIC_PUSH_DELAY_MS: number = 500
const PAGE_TRAFFIC_UI_REFRESH_DELAY_MS: number = 100

/**
 * 流量测试卡片。
 *
 * 包含三部分:
 * 1. 下载流量:循环 GET 请求 10s,统计字节/次数/失败。
 * 2. 方案A:首页直接调 getAndResetCurrentPageTraffic,获取当前页自上次以来的增量。
 * 3. 方案B:切到 BlankPage 下载后,在离开前调 getAndReset,验证子页面流量归属。
 *
 * pageStack 由首页传入,用于方案B 的 push/pop BlankPage。
 */
@Component
export struct TrafficTestCard {
  pageStack: NavPathStack = new NavPathStack()

  @State message: string = ''

  // download traffic
  @State downloadBytes: number = 0
  @State requestCount: number = 0
  @State failedCount: number = 0
  @State isTrafficRunning: boolean = false
  private stopTrafficFlag: boolean = false

  // page traffic (getAndResetCurrentPageTraffic)
  @State pageTrafficUpTotal: number = 0
  @State pageTrafficDownTotal: number = 0
  @State pageTrafficPageName: string = ''
  @State pageTrafficCallCount: number = 0
  @State pageTrafficLastUp: number = 0
  @State pageTrafficLastDown: number = 0
  @State isPageTrafficWaiting: boolean = false

  build(): void {
    Column({ space: 8 }) {
      SectionHeader('流量 / Traffic')

      Button(this.isTrafficRunning ? '下载流量中…' : '开始下载流量')
        .width('100%')
        .onClick((): void => {
          this.startDownloadTraffic()
        })

      Button('停止下载流量')
        .width('100%')
        .onClick((): void => {
          this.stopTraffic()
        })

      Text(`下载状态: ${this.isTrafficRunning ? '运行中' : '已停止'}`)
      Text(`下载字节: ${this.downloadBytes}`)
      Text(`请求次数: ${this.requestCount}`)
      Text(`失败次数: ${this.failedCount}`)

      Divider().margin({ top: 6, bottom: 6 })

      Button('获取页面流量增量(getAndReset)')
        .width('100%')
        .onClick((): void => {
          this.testGetAndResetCurrentPageTraffic()
        })

      Button('切页面+验证增量(自动)')
        .width('100%')
        .onClick((): void => {
          this.testPageTrafficWithSwitch()
        })

      Text(`页面流量调用次数: ${this.pageTrafficCallCount}`)
      Text(`页面流量上次 pageName: ${this.pageTrafficPageName}`)
      Text(`页面流量上次 上传(deltaTx): ${this.pageTrafficLastUp}`)
      Text(`页面流量上次 下载(deltaRx): ${this.pageTrafficLastDown}`)
      Text(`页面流量累计 上传: ${this.pageTrafficUpTotal}`)
      Text(`页面流量累计 下载: ${this.pageTrafficDownTotal}`)
      Text(`页面流量等待中: ${this.isPageTrafficWaiting ? '是' : '否'}`)
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor('#F7F9FC')
  }

  // =========================
  // download traffic
  // =========================
  private async startDownloadTraffic(): Promise<void> {
    if (this.isTrafficRunning) {
      this.message = '下载任务已在运行中'
      return
    }

    this.resetTrafficStats()
    this.isTrafficRunning = true
    this.stopTrafficFlag = false
    this.message = '开始下载流量测试'

    let stopAt: number = Date.now() + DOWNLOAD_DURATION_MS

    while (!this.stopTrafficFlag && Date.now() < stopAt) {
      let ok: boolean = await this.doGetOnce(DOWNLOAD_URL)
      if (!ok) {
        this.failedCount += 1
      }
      await this.sleep(DOWNLOAD_INTERVAL_MS)
    }

    this.isTrafficRunning = false
    this.message = '下载流量测试结束'
  }

  private async doGetOnce(url: string): Promise<boolean> {
    let httpRequest: http.HttpRequest = http.createHttp()

    try {
      let data: http.HttpResponse = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        readTimeout: HTTP_TIMEOUT_MS,
        connectTimeout: HTTP_TIMEOUT_MS
      })

      let result: string = ''
      if (typeof data.result === 'string') {
        result = data.result
      } else {
        result = JSON.stringify(data.result)
      }

      this.downloadBytes += result.length
      this.requestCount += 1
      this.message = '下载流量生成中'
      return true
    } catch (_) {
      this.message = '下载请求失败'
      return false
    } finally {
      httpRequest.destroy()
    }
  }

  private stopTraffic(): void {
    this.stopTrafficFlag = true
    this.isTrafficRunning = false
    hilog.info(DOMAIN, TAG, 'traffic stopped')
  }

  private resetTrafficStats(): void {
    this.downloadBytes = 0
    this.requestCount = 0
    this.failedCount = 0
  }

  // =========================
  // page traffic (getAndResetCurrentPageTraffic)
  // =========================

  /**
   * 方案A:手动触发一次 getAndResetCurrentPageTraffic。
   * 在当前页面(首页)下直接调用,回调返回首页自上次 init/上次 getAndReset 以来的上传/下载增量,并自动重置基线。
   */
  private testGetAndResetCurrentPageTraffic(): void {
    this.pageTrafficCallCount += 1
    this.message = 'getAndResetCurrentPageTraffic 调用中…'
    getAndResetCurrentPageTraffic((info): void => {
      this.pageTrafficLastUp = info.upTotal
      this.pageTrafficLastDown = info.downTotal
      this.pageTrafficPageName = info.pageName
      this.pageTrafficUpTotal += info.upTotal
      this.pageTrafficDownTotal += info.downTotal
      this.message = `getAndReset 完成: pageName=${info.pageName}, up=${info.upTotal}, down=${info.downTotal}, total=${info.total}`
      hilog.info(DOMAIN, TAG,
        `getAndResetCurrentPageTraffic result: pageName=${info.pageName} upTotal=${info.upTotal} downTotal=${info.downTotal} total=${info.total}`)
    })
  }

  /**
   * 方案B:自动验证"进入子页面→离开前"期间的流量增量。
   *
   * 设计依据:getAndResetCurrentPageTraffic 内部取调用瞬间的 currentPageName 作为归属页名,
   * 该变量仅在 onNavDestinationSwitch(系统 navDestinationSwitch 事件)切页时更新为 targetPageName。
   * 因此要正确归属到子页面,必须在子页面仍处于显示状态、currentPageName 尚为子页面名时调用。
   *
   * 流程:
   *   1. 首页 getAndReset:清零首页基线(避免首页遗留流量混入子页面增量)。
   *   2. push BlankPage('keep'):navDestinationSwitch 触发,currentPageName 切到 'BlankPage';
   *      'keep' 让 BlankPage 跳过自动 pop,避免下载中途被自动弹出导致归属失真。
   *   3. 在 BlankPage 内持续下载 10s。
   *   4. 下载结束、pop 返回首页之前调用 getAndReset:
   *      此时 currentPageName 仍为 'BlankPage',回调 pageName 应为 'BlankPage',
   *      增量反映 BlankPage 期间的真实流量(pageEnter 基线独立,不被周期采样截断)。
   *   5. pop 返回首页。
   *
   * 注意:不要在 pop 之后调用,否则 currentPageName 已切回 'navRoot',归属页会变成 navRoot
   *      (增量数值仍正确,但 pageName 失真)。
   */
  private testPageTrafficWithSwitch(): void {
    hilog.info(DOMAIN, TAG, '[方案B] 按钮点击，进入 testPageTrafficWithSwitch')
    if (this.isPageTrafficWaiting) {
      hilog.warn(DOMAIN, TAG, '[方案B] isPageTrafficWaiting=true，强制复位后继续（上次可能中断未复位）')
    }
    this.isPageTrafficWaiting = true
    this.message = '页面流量验证：先清零首页基线'

    // 安全保险:无论如何 20s 后复位锁,避免回调丢失导致永久卡死
    setTimeout((): void => {
      if (this.isPageTrafficWaiting) {
        hilog.warn(DOMAIN, TAG, '[方案B] 20s 超时保险触发，强制复位 isPageTrafficWaiting')
        this.isPageTrafficWaiting = false
      }
    }, PAGE_TRAFFIC_SAFETY_TIMEOUT_MS)

    // 1. 清零首页基线
    getAndResetCurrentPageTraffic((_info): void => {
      hilog.info(DOMAIN, TAG, '[方案B] 第1次 getAndReset 回调触发，准备 push BlankPage')
      this.pageTrafficCallCount += 1
      // 2. 跳转 BlankPage,navDestinationSwitch 会把 currentPageName 切到 'BlankPage'
      this.message = '页面流量验证：跳转 BlankPage 开始下载'
      this.pageStack.pushPath(new NavPathInfo('BlankPage', 'keep'))

      // 3. 等待页面切换事件落定后开始下载
      setTimeout((): void => {
        hilog.info(DOMAIN, TAG, '[方案B] 500ms 后开始 startDownloadTraffic')
        this.startDownloadTraffic().then((): void => {
          hilog.info(DOMAIN, TAG, '[方案B] startDownloadTraffic 完成，准备第2次 getAndReset')
          // 4. 下载 10s 结束、仍在 BlankPage 显示时抓取增量
          this.message = '页面流量验证：BlankPage 下载结束，抓取增量'
          this.pageTrafficCallCount += 1
          getAndResetCurrentPageTraffic((info): void => {
            hilog.info(DOMAIN, TAG,
              `[方案B] 第2次 getAndReset 回调触发: pageName=${info.pageName} upTotal=${info.upTotal} downTotal=${info.downTotal} total=${info.total}`)
            const pageName: string = info.pageName
            const upTotal: number = info.upTotal
            const downTotal: number = info.downTotal
            const total: number = info.total
            hilog.info(DOMAIN, TAG,
              `page traffic verify result(BlankPage上抓取): pageName=${pageName} upTotal=${upTotal} downTotal=${downTotal} total=${total}`)
            // 5. 抓取完成后返回首页
            this.pageStack.pop()
            // 6. 返回首页后再刷新 @State,确保组件已重新可见、能正确重绘
            setTimeout((): void => {
              this.pageTrafficLastUp = upTotal
              this.pageTrafficLastDown = downTotal
              this.pageTrafficPageName = pageName
              this.pageTrafficUpTotal += upTotal
              this.pageTrafficDownTotal += downTotal
              this.isPageTrafficWaiting = false
              this.message =
                `页面流量验证完成: pageName=${pageName}, up=${upTotal}, down=${downTotal}, total=${total}`
            }, PAGE_TRAFFIC_UI_REFRESH_DELAY_MS)
          })
        }).catch((e: Error): void => {
          hilog.error(DOMAIN, TAG, `[方案B] startDownloadTraffic 异常: ${e?.message ?? e}`)
          this.isPageTrafficWaiting = false
        })
      }, PAGE_TRAFFIC_PUSH_DELAY_MS)
    })
  }

  // =========================
  // utils
  // =========================
  private sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void): void => {
      setTimeout((): void => {
        resolve()
      }, ms)
    })
  }
}
