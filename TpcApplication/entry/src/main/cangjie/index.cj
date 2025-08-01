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
import ohos_app_cangjie_hm_metricx_cj.*
import ohos_app_cangjie_hm_metricx_cj.freeze.*
import ohos_app_cangjie_hm_metricx_cj.storage.*
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
//            Web(src: "https://www.baidu.com/", controller: webviewController)
        }
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
//            Web(src: "https://baidu.com", controller: webviewController)
        }
        .onReady {
            context => pageInfos=context.pathStack
        }
        .onBackPressed {
            pageInfos.pop()
            true
        }
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