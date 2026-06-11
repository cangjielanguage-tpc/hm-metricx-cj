/**
 * Created on 2025/9/18
 */
package hm_metricx_cj.wrapper

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

import hm_metricx_cj.util.Logger
import hm_metricx_cj.util.initLogger as _initLogger

@Interop[ArkTS]
public func initLogger(logger: Logger): Unit {
    _initLogger(logger)
}