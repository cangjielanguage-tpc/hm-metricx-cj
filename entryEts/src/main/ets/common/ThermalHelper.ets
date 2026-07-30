import { thermal } from '@kit.BasicServicesKit'

/**
 * 热档位工具:档位号↔名称映射、安全读取当前档位。
 * 提取自原 Index.ets / CpuStressTestPage 内重复实现。
 */

export function levelToName(level: number): string {
  switch (level) {
    case 0:
      return 'COOL'
    case 1:
      return 'NORMAL'
    case 2:
      return 'WARM'
    case 3:
      return 'HOT'
    case 4:
      return 'OVERHEATED'
    case 5:
      return 'WARNING'
    case 6:
      return 'EMERGENCY'
    case 7:
      return 'ESCAPE'
    default:
      return 'UNKNOWN'
  }
}

export interface ThermalLevel {
  level: number
  name: string
}

/** 安全读取当前热档位,异常时返回 -1 / UNKNOWN。 */
export function getCurrentThermalLevel(): ThermalLevel {
  try {
    let level: number = thermal.getLevel()
    return { level: level, name: levelToName(level) }
  } catch (_) {
    return { level: -1, name: 'UNKNOWN' }
  }
}
