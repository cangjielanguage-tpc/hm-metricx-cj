package ohos_app_cangjie_entry

import tpc.UIKit.Text
import tpc.UIKit.Button
import tpc.UIKit.Column
import tpc.UIKit.CustomView
import ohos.state_macro_manage.State
import ohos.state_macro_manage.Component
import ohos.state_manage.LocalStorage
import ohos.state_manage.ObservedProperty
import ohos.state_manage.SubscriberManager
import ohos.state_manage.ViewStackProcessor
import ohos.state_macro_manage.HybridComponentEntry
import ohos.hybrid_base.CJPageEntry
import ohos.hybrid_base.HybridComponentBase
import cj_res_entry.app
import ohos_app_cangjie_hm_metricx_cj.*
import ohos_app_cangjie_hm_metricx_cj.freeze.*
import ohos.base.nativeLog
import ohos.hilog.*
import tpc.AbilityKit.*
import tpc.UIKit.component_interop.getContext
import std.collection.ArrayList
import ohos.base.AppLog

@HybridComponentEntry
@Component
class Index {
    @State
    var msg: String = "Hello"

    public func build() {
        Column {
            Text(msg)
            Button("click to change Text").onClick {
                =>
                msg = "world"
                sayHello()
                //let xxx = ArrayList<Int64>(222222222222222222)
                //crash()
//                unsafe {
//                    Crash()
//                }
            }
            Button("Hilog-Freeze").onClick {
                =>
                msg = "Hilog"
                Hilog.info(218108688, "AppDfr", "appfreeze_inner cj log : hilog")
            }
            Button("freeze").onClick {
                =>
                msg = "freeze"
                Hilog.info(0, "testTag", "cj log : freeze clicked")
                while (true) {
                }
            }
        }
    }
}

func crash() {
    let xxx = 1
    var flag = 10
    for (i in 0..10) {
        flag--
    }
    let qqq = xxx / flag
}

foreign func Crash(): Unit
