import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS'
import { hidebug } from '@kit.PerformanceAnalysisKit'

/**
 * ArkTS VM 堆异步采样 Worker（独立子线程）。
 *
 * 背景：6aa2f77 为消除主线程 hidebug NAPI 退避 ANR，把 arkTsMemoryUsage/arkTsMemoryLimit
 * 置 0，致 6 个 ArkTS VM 堆字段失效。native OH_HiDebug 无 ArkTS VM 堆等价字段
 * （HiDebug_NativeMemInfo 是 smaps、HiDebug_MemoryLimit 仅 rss/vss），唯一数据源是
 * hidebug.getAppVMMemoryInfo().heapUsed / getAppMemoryLimit().vmHeapLimit ArkTS NAPI。
 * 主线程 2s 热循环直调会触发 ApiInvokeRecorder 析构 FFRT 退避致 THREAD_BLOCK_6S ANR。
 *
 * 解法：两 hidebug 调用挪进本 Worker 线程，按采样周期采一次，postMessage 回主线程。
 * 主线程 onmessage 调 setArkTsMemoryCacheInterop 灌 Cangjie 缓存——写与 doMemorySample 读
 * 同线程，无并发；Worker 线程零 Cangjie 互操作调用。主线程 2s 热循环零 hidebug 调用，
 * ANR 根除，全字段恢复有效。
 *
 * 约定同 MemAllocWorker：interval 在 Worker 线程，停止须主线程 terminate()。
 * MessageEvents / ErrorEvent 为 @kit.ArkTS 顶层具名导出。
 */

const workerPort: ThreadWorkerGlobalScope = worker.workerPort

const TAG: string = 'ArkTsHeapWorker'
const SAMPLE_INTERVAL: number = 2 * 1000 // 2s，与主采样周期对齐

let sampling: boolean = false
let timerId: number = -1

interface ArkTsHeapSample {
  heapUsed: number
  vmHeapLimit: number
}

/**
 * 采一次 ArkTS VM 堆。各 hidebug 调用独立 try/catch，失败只清 0 不抛。
 */
function sampleOnce(): ArkTsHeapSample {
  let heapUsed: number = 0
  let vmHeapLimit: number = 0
  try {
    heapUsed = Number(hidebug.getAppVMMemoryInfo().heapUsed)
  } catch (e) {
    console.warn(TAG, 'getAppVMMemoryInfo failed: ' + JSON.stringify(e))
  }
  try {
    vmHeapLimit = Number(hidebug.getAppMemoryLimit().vmHeapLimit)
  } catch (e) {
    console.warn(TAG, 'getAppMemoryLimit failed: ' + JSON.stringify(e))
  }
  return { heapUsed, vmHeapLimit }
}

workerPort.onmessage = (e: MessageEvents): void => {
  const msg: string = String(e.data ?? '')
  if (msg === 'start' && !sampling) {
    sampling = true
    // 立即采一次再按周期采，避免首周期主线程读到的缓存仍为 0。
    workerPort.postMessage(sampleOnce())
    timerId = setInterval(() => {
      workerPort.postMessage(sampleOnce())
    }, SAMPLE_INTERVAL)
  } else if (msg === 'stop' && sampling) {
    sampling = false
    if (timerId >= 0) {
      clearInterval(timerId)
      timerId = -1
    }
    workerPort.postMessage('stopped')
  }
}

workerPort.onerror = (e: ErrorEvent): void => {
  console.error(TAG, `worker error: ${e.message}`)
}
