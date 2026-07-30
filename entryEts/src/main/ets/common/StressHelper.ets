import { hilog } from '@kit.PerformanceAnalysisKit'
import { getCurrentThermalLevel } from './ThermalHelper'

const DOMAIN: number = 0x0021
const TAG: string = 'thermal_traffic_test'

/**
 * 压测工具:sleep、CPU 烧轮、带热档位自动停止的压测循环。
 * 提取自原 Index.ets / CpuStressTestPage 内重复实现。
 */

export function sleep(ms: number): Promise<void> {
  return new Promise<void>((resolve: () => void): void => {
    setTimeout((): void => {
      resolve()
    }, ms)
  })
}

/**
 * 在主线程忙等 durationMs,做无意义浮点运算消耗 CPU。
 * stopFlag 返回 true 时提前退出。
 */
export function burnCpuFor(durationMs: number, stopFlag: () => boolean): void {
  let end: number = Date.now() + durationMs
  let acc: number = 0

  while (Date.now() < end && !stopFlag()) {
    for (let i: number = 1; i < 300000; i++) {
      acc += Math.sqrt(i % 997) * Math.sin(i) * Math.cos(i % 359)
    }
  }

  if (acc < 0) {
    hilog.debug(DOMAIN, TAG, `acc=${acc}`)
  }
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

/**
 * 标准压测循环:每轮烧 950ms CPU → 刷新热档位 → 达到 autoStopLevel 自动停止。
 * 复用 Index 首页版与 CpuStressTestPage 版的相同逻辑。
 */
export async function runCpuStressLoop(opts: CpuStressLoopOptions): Promise<void> {
  while (!opts.shouldStop()) {
    opts.onRound()

    burnCpuFor(950, opts.shouldStop)
    const level: number = opts.onRefreshThermal()

    if (level >= opts.autoStopLevel) {
      opts.onAutoStop(getCurrentThermalLevel().name)
      break
    }

    await sleep(50)
  }
}
