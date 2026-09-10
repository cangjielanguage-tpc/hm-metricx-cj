import { hilog } from '@kit.PerformanceAnalysisKit'
import { MessageEvents, worker } from '@kit.ArkTS'
import { getCurrentThermalLevel } from './ThermalHelper'

const DOMAIN: number = 0x0021
const TAG: string = 'thermal_traffic_test'

/**
 * 压测工具:sleep、CPU 烧轮、带热档位自动停止的压测循环。
 * 提取自原 Index.ets / CpuStressTestPage 内重复实现。
 *
 * 重要：烧 CPU 阶段在 CpuBurnWorker 子线程执行（原 burnCpuFor 在主线程同步忙等 950ms，
 * 直接卡死 UI）。hm_metricx_cj 采样命中本 Worker 的 burnCpuFor 帧，避免主线程自指。
 */

export function sleep(ms: number): Promise<void> {
  return new Promise<void>((resolve: () => void): void => {
    setTimeout((): void => {
      resolve()
    }, ms)
  })
}

export interface CpuStressLoopOptions {
  /** 每轮开始时回调(通常用来累加计数、刷新显示)。 */
  onRound: () => void
  /** 每轮结束后刷新热档位(返回档位号)。 */
  onRefreshThermal: () => number
  /** 是否请求停止。 */
  shouldStop: () => boolean
  /** 到达该档位自动停止。 */
  autoStopLevel: number
  /** 自动停止时的回调。 */
  onAutoStop: (levelName: string) => void
}

/** 每轮烧 CPU 毫秒数（与原 burnCpuFor(950) 口径一致）。 */
const BURN_DURATION_MS: number = 950

/**
 * 等待 CpuBurnWorker 完成一轮定时烧 CPU。
 * 向 Worker 发 'burn:<ms>'，监听一次 'burnDone' 后 resolve（每轮重置 onmessage）。
 */
function awaitWorkerBurn(burnWorker: worker.ThreadWorker, durationMs: number): Promise<void> {
  return new Promise<void>((resolve: () => void): void => {
    burnWorker.onmessage = (msg: MessageEvents): void => {
      if (String(msg.data) === 'burnDone') {
        resolve()
      }
    }
    burnWorker.postMessage(`burn:${durationMs}`)
  })
}

/**
 * 标准压测循环:每轮在 Worker 子线程烧 950ms CPU → 刷新热档位 → 达到 autoStopLevel 自动停止。
 * 复用 Index 首页版与 CpuStressTestPage 版的相同逻辑。
 *
 * 烧 CPU 阶段在独立 Worker 线程执行，主线程仅 await 回报，UI 不卡顿。
 */
export async function runCpuStressLoop(opts: CpuStressLoopOptions): Promise<void> {
  // 单独的烧机 Worker，全程复用；退出（停止/自动停止）时 terminate。
  // 注意不能复用页面级 startWorkerBurn 的 Worker：那个跑 while(burning) 持续死循环，
  // 消息循环被阻塞收不到 'burn:<ms>'，故压测循环独占一个 Worker。
  let burnWorker: worker.ThreadWorker | null = null
  try {
    burnWorker = new worker.ThreadWorker('../workers/CpuBurnWorker')
    while (!opts.shouldStop()) {
      opts.onRound()

      await awaitWorkerBurn(burnWorker, BURN_DURATION_MS)
      const level: number = opts.onRefreshThermal()

      if (level >= opts.autoStopLevel) {
        opts.onAutoStop(getCurrentThermalLevel().name)
        break
      }

      await sleep(50)
    }
  } catch (e) {
    hilog.error(DOMAIN, TAG, `runCpuStressLoop worker failed: ${(e as Error).message}`)
  } finally {
    if (burnWorker !== null) {
      burnWorker.terminate()
      burnWorker = null
    }
  }
}
