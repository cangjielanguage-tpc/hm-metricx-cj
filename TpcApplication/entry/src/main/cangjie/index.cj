/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */
package ohos_app_cangjie_entry

import ohos.hybrid_base.CJPageEntry
import tpc.UIKit.Text
import tpc.UIKit.Button
import tpc.UIKit.Column
import tpc.UIKit.CustomView
import tpc.UIKit.*
import ohos.state_macro_manage.State
import ohos.state_macro_manage.Component
import ohos.state_manage.LocalStorage
import ohos.state_manage.ObservedProperty
import ohos.state_manage.SubscriberManager
import ohos.state_manage.ViewStackProcessor
import ohos.state_macro_manage.{HybridComponentEntry, Component}
import ohos.hybrid_base.CJPageEntry
import ohos.hybrid_base.HybridComponentBase
import ohos_app_cangjie_hm_metricx_cj.util.*
import ohos_app_cangjie_hm_metricx_cj.freeze.*
import ohos_app_cangjie_hm_metricx_cj.storage.*
import ohos_app_cangjie_hm_metricx_cj.memLeak.*
import ohos.base.nativeLog
import ohos.hilog.*
import tpc.AbilityKit.*
import tpc.UIKit.component_interop.getContext
import std.collection.ArrayList
import ohos.base.AppLog
import tpc.UIKit.component_interop.NavDestination
import ohos.state_macro_manage.Provide
import ohos.state_macro_manage.Builder
import tpc.ArkWeb.webview.WebviewController

//对于thermal测试的新增
import tpc.UIKit.global.*   // setTimeout
import std.time.*           // DateTime
import std.sync.*

@Component
class pageOneTmp {
    public func build() {
        NavDestination() {
            TextInput(placeholder: 'search...').height(40).width(90).backgroundColor(0XFFFFFF).margin(top: 8)
        }
    }
}

@HybridComponentEntry
@Component
class Index {
    @State
    var webviewController: WebviewController = WebviewController()
    var msg: String = "Hello"
    let arr = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100]
    @Provide
    var pageInfos: NavPathStack = NavPathStack()

    @Builder
    public func PageMap(name: String): Unit {
        if (name == "pageOne"){
            PageOne()
        }else {
            PageTwo()
        }
    }

    public func build() {
        Column {
            Button("click to change Text").onClick {
                =>
                msg = "world"
                oom()
                //sayHello()
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
            Button("storage").onClick {
                =>
                Hilog.info(0, "testTag", "storage click")
                reportAppStorageInfo()
            }

            Button("Start Heating (CPU Burn)").onClick {
                =>
                msg = "Heating..."
                startCpuBurnMulti()
            }

            Button("Stop Heating").onClick {
                =>
                msg = "Stop heating"
                stopCpuBurnMulti()
            }
            
            Navigation(this.pageInfos) {
                Text(msg)

                TextInput(placeholder: 'search...').height(40).width(90).backgroundColor(0XFFFFFF).margin(top: 8)

                List(space: 20, initialIndex: 0) {
                    ForEach(
                        this.arr,
                        itemGeneratorFunc: {
                            item: Int64, _: Int64 => ListItem() {
                                Text("${item}")
                                    .width(100)
                                    .height(100)
                                    .fontSize(16)
                                    .textAlign(TextAlign.Center)
                                    .borderRadius(10)
                                    .backgroundColor(0xFFFFFF)
                                    .onClick(
                                        {event => this.pageInfos.pushPath(NavPathInfo(name: "pageOne", param: ""))}
                                    )
                            }
                        }
                    )
                }.scrollBar(BarState.Off).width(90)
            }.width(100).height(300.vp).padding(top: 5.px)
            .navDestination(bind<String>(PageMap, this))
        }
    }

    private var memLeakMark: Option<MemLeakMark> = None
    protected override func aboutToDisappear() {
        this.memLeakMark = MemLeakMark()
        collectDestroyedComponent(this.memLeakMark.getOrThrow(), this)
    }
}

@Component
class PageOne{
    @State
    var webviewController: WebviewController = WebviewController()
    var pageInfos:NavPathStack = NavPathStack()
    public func build() {
        NavDestination() {
            Text("cur page is PageOne")
            Text("enter page two").onClick {
                evt => pageInfos.pushPath(NavPathInfo(name:"pageTwo",param:""))
            }
        }
        .onReady {
            context => pageInfos=context.pathStack
        }
        .onBackPressed {
            pageInfos.pop()
            true
        }
    }

    private var memLeakMark: Option<MemLeakMark> = None
    protected override func aboutToDisappear() {
        this.memLeakMark = MemLeakMark()
        collectDestroyedComponent(this.memLeakMark.getOrThrow(), this)
    }
}

@Component
class PageTwo{
    var pageInfos:NavPathStack = NavPathStack()
    public func build() {
        NavDestination() {
            Text("cur page is PageTwo")
            Text("enter page one").onClick {
                evt => pageInfos.pushPath(NavPathInfo(name:"pageOne",param:""))
            }
        }
        .onReady {
            context => pageInfos=context.pathStack
        }
        .onBackPressed {
            pageInfos.pop()
            true
        }
    }

    private var memLeakMark: Option<MemLeakMark> = None
    protected override func aboutToDisappear() {
        this.memLeakMark = MemLeakMark()
        collectDestroyedComponent(this.memLeakMark.getOrThrow(), this)
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

func oom() {
    let arr = ArrayList<Int64>(4200000000000)
}


// ===================== Multi-Thread CPU Heating =====================

var burnRunning: Bool = false
var burnFutures: ArrayList<Future<Unit>> = ArrayList<Future<Unit>>()

const THREAD_COUNT: Int64 = 6i64   // 直接写死
const BURN_LOOP_COUNT: Int64 = 80_000_000i64

public func startCpuBurnMulti(): Unit {
    if (burnRunning) {
        AppLog.info("CPU burn already running")
        return
    }

    burnRunning = true
    burnFutures.clear()

    AppLog.info("Starting CPU burn with ${THREAD_COUNT} threads")

    for (n in 1i64..THREAD_COUNT) {
        let future = spawn {
            =>
            var x: Int64 = 1

            while (burnRunning) {
                for (i in 1i64..BURN_LOOP_COUNT) {
                    x = (x * 1664525 + 1013904223 + i) & 0xffffffff
                }
            }

            ()
        }

        burnFutures.add(future)
    }
}

public func stopCpuBurnMulti(): Unit {
    if (!burnRunning) {
        AppLog.info("CPU burn not running")
        return
    }

    burnRunning = false

    for (f in burnFutures) {
        try { f.cancel() } catch (_: Exception) {}
    }

    burnFutures.clear()

    AppLog.info("CPU burn stopped")
}