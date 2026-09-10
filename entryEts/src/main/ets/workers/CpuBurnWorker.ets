import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS'

/**
 * CPU 烧机 Worker（独立子线程）。
 *
 * 两种工作模式：
 *
 * 1) 持续烧机（原模式，startWorkerBurn 用）：收到 'start' 后 while(burning) 死循环烧 CPU，
 *    不 sleep 不 yield，保证上报抓栈那一刻大概率命中计算帧而非等待帧。
 *    停止须主线程 terminate()（while 同步阻塞消息循环，postMessage('stop') 收不到）。
 *
 * 2) 定时烧机（runCpuStressLoop 用，替代原主线程 burnCpuFor）：收到 'burn:<ms>' 后
 *    烧指定毫秒再 postMessage('burnDone') 回报，然后回到消息循环等下一条指令。
 *    把主线程 950ms 忙等挪到子线程，消除页面卡顿（原 burnCpuFor 在主线程同步阻塞 UI）。
 *
 * 抓栈验证：hm_metricx_cj 采样命中本 Worker 线程的 burnCpuContinuously / burnCpuFor 帧，
 * 而非主线程的互操作/事件循环栈，避免「采集自身被判成元凶」的自指。
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

/**
 * 烧 CPU 指定毫秒。函数名保留以便抓栈时在 native 符号里可辨识。
 * 在 Worker 线程内同步执行，不阻塞主线程 UI；用 Date.now() 计时退出。
 */
function burnCpuFor(durationMs: number): void {
  const end: number = Date.now() + durationMs
  let acc: number = 0
  let i: number = 0
  while (Date.now() < end) {
    for (let k: number = 0; k < 100000; k++) {
      acc += Math.sqrt((i + k) % 997) * Math.sin(i + k) * Math.cos((i + k) % 359)
      i++
    }
  }
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
  } else if (msg.startsWith('burn:')) {
    // 定时烧机：烧完回报 burnDone，回到消息循环等下一条指令（不持续阻塞）。
    const durationMs: number = Number.parseInt(msg.substring('burn:'.length))
    if (durationMs > 0) {
      burnCpuFor(durationMs)
      workerPort.postMessage('burnDone')
    }
  }
}

workerPort.onerror = (e: ErrorEvent): void => {
  console.error(BURN_TAG, `worker error: ${e.message}`)
}
