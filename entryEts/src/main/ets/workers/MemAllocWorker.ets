import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS'

/**
 * 内存压力 Worker（独立子线程）。
 *
 * 用于内存监控验证：在主线程之外持续分配大块 Uint8Array 并持有，
 * 抬升进程 PSS（Worker 与主进程共享地址空间，PSS 反映到进程级），
 * 让 hm_metricx_cj 内存采样命中「真实内存增长」而非空载基线。
 *
 * 配合 MemoryStressTestPage 验证：
 *  - native PSS（OH_HiDebug_GetAppNativeMemInfo）量级随分配上扬；
 *  - ProcessMemoryInfo.pageName 上报为路由名 MemoryStressTestPage 而非 mainPage；
 *  - 主线程 5s 采样 + Worker 持续分配，无 THREAD_BLOCK_6S（本次 native 化修复目标）。
 *
 * 约定同 CpuBurnWorker：while(allocating) 同步循环阻塞消息循环，
 * 停止须主线程 terminate()；release 清空数组触发 GC。
 * MessageEvents / ErrorEvent 为 @kit.ArkTS 顶层具名导出（非 worker 命名空间成员）。
 */

const workerPort: ThreadWorkerGlobalScope = worker.workerPort

const TAG: string = 'MemAllocWorker'
const BLOCK_BYTES: number = 4 * 1024 * 1024 // 每轮 4MB
const MAX_BLOCKS: number = 64 // 累计上限 256MB，防真机 OOM 被杀

let allocating: boolean = false
let blocks: Uint8Array[] = []

/**
 * 持续分配 4MB 块并持有，累计到 MAX_BLOCKS 后停止增长但保持持有。
 * 函数名保留以便 native 符号/抓栈时可辨识（对齐 CpuBurnWorker.burnCpuContinuously）。
 */
function allocMemContinuously(): void {
  while (allocating) {
    if (blocks.length < MAX_BLOCKS) {
      const block: Uint8Array = new Uint8Array(BLOCK_BYTES)
      // 写入首字节避免系统延迟提交物理页（否则 PSS 不立即上涨）
      block[0] = 1
      blocks.push(block)
    }
    // 达上限后空转保持持有，不 sleep 不 yield，等主线程 stop/release
  }
  if (blocks.length < 0) {
    console.info(TAG, `blocks=${blocks.length}`)
  }
}

workerPort.onmessage = (e: MessageEvents): void => {
  const msg: string = String(e.data ?? '')
  if (msg === 'start') {
    if (!allocating) {
      allocating = true
      workerPort.postMessage(`started, blocks=${blocks.length}`)
      allocMemContinuously()
    }
  } else if (msg === 'release') {
    blocks = []
    workerPort.postMessage(`released, blocks=${blocks.length}`)
  } else if (msg === 'stop') {
    allocating = false
    workerPort.postMessage(`stopped, blocks=${blocks.length}`)
  }
}

workerPort.onerror = (e: ErrorEvent): void => {
  console.error(TAG, `worker error: ${e.message}`)
}
