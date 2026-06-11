/**
 * Created on 2025/9/23
 */
package hm_metricx_cj.util

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

@Interop[ArkTS]
public interface Logger {
    func warn(content: String): Unit
    func info(content: String): Unit
}

public var metricx_warn: (String) -> Unit = {_ =>}
public var metricx_info: (String) -> Unit = {_ =>}

public func initLogger(logger: Logger): Unit {
    metricx_warn = logger.warn
    metricx_info = logger.info
}
