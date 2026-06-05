/**
 * Created on 2025/9/18
 */
package ohos_app_cangjie_hm_metricx_cj.wrapper

import ohos.ark_interop_macro.*
import ohos.ark_interop.*

import ohos_app_cangjie_hm_metricx_cj.util.Logger
import ohos_app_cangjie_hm_metricx_cj.util.initLogger as _initLogger

@Interop[ArkTS]
public func initLogger(logger: Logger): Unit {
    _initLogger(logger)
}