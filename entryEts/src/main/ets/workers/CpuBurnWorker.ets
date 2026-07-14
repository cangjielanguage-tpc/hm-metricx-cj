import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS'

/**
 * CPU 烧机 Worker（独立子线程）。
 *
 * 用于高 CPU 抓栈验证：在主线程之外持续跑浮点死循环，使该 Worker 线程长期高 CPU，
 * 让 hm_metricx_cj 采样命中并抓到「真正造成高 CPU 的栈」，避免主线程自指
 * （hm_metricx_cj 自身的采样/抓栈/hilog 也在主线程跑，阈值低时会被误判为高 CPU）。
 *
 * 烧循环不sleep、不yield，保证上报抓栈那一刻大概率命中计算帧而非等待帧。
 *
 * Worker 上下文：workerPort 不是裸全局，需从 worker 命名空间取值并声明类型；
 * MessageEvents / ErrorEvent 为 @kit.ArkTS 顶层具名导出（非 worker 命名空间成员）。
 */

const workerPort: ThreadWorkerGlobalScope = worker.workerPort

const BURN_TAG: string = 'CpuBurnWorker'

let burning: boolean = false

/**
 * 持续浮点运算烧 CPU。函数名保留以便抓栈时在 native 符号里可辨识。
 */
function burnCpuContinuously(): void {
  let acc: number = 0
  let i: number = 0
  while (burning) {
    // 内层循环加大单次调度时间片内的计算量，减少被 Worker 消息循环打断的频率。
    for (let k: number = 0; k < 100000; k++) {
      acc += Math.sqrt((i + k) % 997) * Math.sin(i + k) * Math.cos((i + k) % 359)
      i++
    }
  }
  // 防止 acc 被优化掉
  if (acc < 0) {
    console.info(BURN_TAG, `acc=${acc}`)
  }
}

workerPort.onmessage = (e: MessageEvents): void => {
  const msg: string = String(e.data ?? '')
  if (msg === 'start') {
    if (!burning) {
      burning = true
      workerPort.postMessage('started')
      burnCpuContinuously()
    }
  } else if (msg === 'stop') {
    burning = false
    workerPort.postMessage('stopped')
  }
}

workerPort.onerror = (e: ErrorEvent): void => {
  console.error(BURN_TAG, `worker error: ${e.message}`)
}


