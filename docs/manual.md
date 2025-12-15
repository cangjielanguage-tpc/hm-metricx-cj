# hm-metricx-cj

## 功能简介

`hm-metricx-cj` 是一款适用于鸿蒙应用的线上性能监控框架。 `hm-metricx-cj` 系统性地采集和分析监控指标数据，帮助开发团队及时发现性能瓶颈和异常，持续优化应用质量，提升用户体验。

`hm-metricx-cj` 目前支持的监控范围包括：Crash、Freeze、异常退出原因、FPS、滑动掉帧率、交互响应延迟、内存、CPU、电量、流量、存储。

## 使用说明

### 集成方式

i.
获取 `hm-metricx-cj` 源码。

ii.
在 `DevEco Studio` 中点击 `Build -> Make module 'hm-metricx-cj'` 编译生成har包 `hm_metricx_cj.har` 。har包产物路径在 `hm_metricx_cj/build/default/outputs/default` 目录下。

iii.
将 `hm_metricx_cj.har` 放到工程模块的har目录下。在工程模块的 `oh-package.json5` 中配置依赖 `"hm_metricx_cj": "file:./har/hm_mtricx_cj.har"` 。
并且在工程模块的 `src/main/cangjie/cjpm.toml` 中配置依赖：
```text
[dependencies]
  [dependencies.ohos_app_cangjie_hm_metricx_cj]
    path = "../../../oh_modules/hm_metricx_cj/src/main/cangjie"
```

### 监控Crash

`hm_metricx_cj` 提供
```text
public func initCrashHandler(
    applicationContext: ApplicationContext,
    collectCrashInfo: () -> JsonValue,
    collectNativeCrashInfo: CFunc<() -> CString>,
    reportCrashInfo: (crashInfo: CrashInfo) -> Unit,
    persistentDir: Path,
    enableDumpOnOOM: Option<OOMHandlerMode>,
    lastNHilogNumber: Int64,
    systemLogNumber: Int64,
    enableMemMonitor: Option<CMemMonitorConfig>
): Unit

public enum OOMHandlerMode {
    | Async | Sync
}

public class CMemMonitorConfig {
    let shouldBeClusteredToThisSo: (soName: String) -> Bool
    public init(shouldBeClusteredToThisSo: (soName: String) -> Bool){
        this.shouldBeClusteredToThisSo = shouldBeClusteredToThisSo
    }
}
```
接口对ArkTS/仓颉/Native层引发的崩溃进行监控。

`initCrashHandler` 需要的入参说明如下：

- `applicationContext: ApplicationContext` 指定应用上下文。
- `collectCrashInfo: () -> JsonValue` 用于在发生ArkTS/仓颉层引发的crash时，收集若干自定义的业务/系统信息(比如页面浏览路径等)，以json形式返回。
- `collectNativeCrashInfo: CFunc<() -> CString` 用于在发生Native层引发的crash时，收集若干自定义的业务/系统信息(比如页面浏览路径等)，以json字符串形式返回。
- `reportCrashInfo: (crashInfo: CrashInfo) -> Unit` 用于在发生ArkTS/仓颉层引发的crash时，将收集完毕的崩溃信息进行上报，入参为 `CrashInfo` 类型对象。 
- `persistentDir: Path` 指定中间日志文件和内存快照的持久化目录。
- `enableDumpOnOOM: Option<OOMHandlerMode>` 指定是否在发生OOM时导出仓颉内存快照, Option.None表示不导出仓颉内存快照，`OOMHandlerMode`枚举类型可选`Async`异步导出或`Sync`同步导出。
- `lastNHilogNumber: Int64` 指定lastNHilog的条数。
- `systemLogNumber: Int64` 指定系统级日志systemLog的条数。
- `enableMemMonitor: Option<CMemMonitorConfig>` 指定是否开启C内存详情监控，Option.None表示不开启，传入`CMemMonitorConfig`对象表示开启，`CMemMonitorConfig`类表示C内存详情监控的配置项。

`CMemMonitorConfig` 参数说明：
- `shouldBeClusteredToThisSo` 用于在按照so聚合类别中，指定内存分配数据是否被聚合到该so。

`CrashInfo` 包含以下信息：

- `language` 崩溃发生所处的语言层
- `meminfo` 崩溃发生时的应用内存信息
- `timestamp` 崩溃发生的时间戳
- `pid` 崩溃进程ID
- `pname` 崩溃进程名
- `stacktrace` 崩溃调用栈
- `hilog` Hilog日志
- `tid` 崩溃线程ID
- `tname` 崩溃线程名
- `fds` FD及其对应路径
- `limits` 进程资源限制
- `threads` OS线程ID与线程名
- `extraInfo` `collectCrashInfo/reportNativeCrashInfo` 收集的自定义的业务/系统信息
- `crashLogPath` 系统生成的faultlog文件路径
- `dumpOnOOMPath` 导出的仓颉内存快照地址
- `appVersion` 应用版本
- `rawFile` 系统生成的faultlog文件的原始内容
- `systemLog` 系统级日志
- `lastNHilog` 最新的N条hilog日志
- `dumpTime` 导出仓颉内存快照的时间
- `historyRawFiles` 所有历史系统生成的crash日志文件的内容
- `nativeMemDetail` C层内存详情
- `memPersistTime` C层内存详情持久化时间

使用示例：

i.
在主模块的 `main_ability.cj` 的 `onCreate` 回调中调用 `initCrashHandler` ：
```text
class EntryAbility <: UIAbility {
    public override func onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Unit {
        AppLog.info("Ability OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case AbilityConstant.LaunchReason.START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
        initCrashHandler(
            this.context.getApplicationContext(), 
            {=> JsonValue.fromStr("{}")}, 
            {=> unsafe { LibC.mallocCString("{}") }}, 
            {data => AppLog.error("testTag: " + data.rawFile.toString())},
            Path(this.context.cacheDir), 
            OOMHandlerMode.Async, 
            1000, 
            1000, 
            CMemMonitorConfig({soName:String =>false}))
    }
}
```

> ** 注意: **
> 
> 对ArkTS/仓颉层引发的崩溃的监控依赖系统提供的ErrorManager机制。
> 
> 当存在其他ErrorManager回调，并且在崩溃监控对应的回调之前执行时，可能会干扰崩溃监控的正常行为，导致收集的数据错漏等情况。

> ** 注意: **
> 
> 如果应用编译开启了 `O2` 级别优化，在部分场景，崩溃调用栈会出现漏栈、行号不准的问题。示例如下：
>
> ```cangjie
> func pri(n: Int64): Unit {
>     if (n < 0) {
>         return;
>     }
> 
>     if (n == 90) {
>         throw Exception("e");
>     }
> 
>     pri(n - 1);
> }
> 
> main(): Unit {
>     pri(1000);
> }
> ```
> 
> 由于内联优化和基础块合并优化的影响，抛出异常点的行号信息为0，并且调用栈长度会少于程序实际递归次数。


### 监控Freeze

`hm_metricx_cj` 提供

```text
public func initFreezeHandler(
    applicationContext: ApplicationContext,
    collectFreezeInfo: () -> JsonValue,
    reportFreezeInfo: (freezeInfo: FreezeInfo) -> Unit,
    persistentDir: Path
): Unit
```

接口对freeze事件进行监控。

`initFreezeHandler` 需要的入参说明如下：

- `applicationContext: ApplicationContext` 指定应用上下文。
- `collectFreezeInfo: () -> JsonValue` 用于在APP发生freeze事件时，收集若干自定义的业务/系统信息(比如页面操作栈等)，以 `JsonValue` 形式返回。
- `reportFreezeInfo: (freezeInfo: FreezeInfo) -> Unit` 用于在APP发生freeze事件时，将收集完成的freeze信息进行上报，入参为 `FreezeInfo` 类型对象。
- `persistentDir: Path` 指定中间日志文件的持久化目录。

`FreezeInfo` 包含以下信息：

- `timestamp` freeze发生的时间戳
- `pid` freeze进程名
- `exception` freeze发生原因
- `hilog` Hilog日志
- `tid` freeze线程ID
- `tname` freeze线程名
- `exrtaInfo` 收集的自定义的业务/系统信息
- `freezeLogPath` 系统生成的faultlog文件路径
- `cpuThread` 线程CPU使用率
- `cpu` 进程CPU使用率
- `stacktrace` freeze调用栈
- `rawFile` 系统生成的faultlog文件的原始内容
- `historyRawFiles` 所有历史系统生成的freeze日志文件的内容

使用示例：

i.

在主模块的 `main_ability.cj` 的 `onCreate` 回调中调用 `initFreezeHandler` ：

```text
class EntryAbility <: UIAbility {
    public override func onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Unit {
        AppLog.info("Ability OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case AbilityConstant.LaunchReason.START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
        initFreezeHandler(this.context.getApplicationContext(), {=> JsonValue.fromStr("{}")}, {data =>}, Path(this.context.cacheDir))
    }
}
```

> ** 注意: **
> 
> 和监控Crash类似，如果应用编译开启了 `O2` 级别优化，在部分场景，freeze调用栈会出现漏栈、行号不准的问题。

### 监控异常退出原因

`hm_metricx_cj` 提供
```text
getExitInfo(launchParam: LaunchParam): ExitInfo
```
接口获取应用异常退出原因。

`getExitInfo` 需要的入参说明如下：

- `launchParam: LaunchParam` 应用启动参数。

`ExitInfo` 包含以下信息：

- `exitReason` 上次应用退出的原因，分类如下：
    - `ability_not_responding` Ability未响应
    - `app_freeze` 应用无响应
    - `cpp_crash` Native层发出异常信号导致应用退出
    - `js_error` JS层Error导致应用退出
    - `unknown` 上次应用退出原因未被应用框架记录
    - `normal` 正常退出，如用户主动关闭应用
    - `performance_control` 系统能耗管控导致应用退出，如设备低内存
    - `resource_control` 资源管控导致应用退出，如过量使用CPU/IO/内存资源
    - `upgrade` 应用升级导致应用退出
- `exitMessage` 上次应用退出的详细信息

使用示例：

i.
在主模块的 `main_ability.cj` 的 `onCreate` 回调中调用 `getExitInfo` ：
```text
class EntryAbility <: UIAbility {
    public override func onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Unit {
        AppLog.info("Ability OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case AbilityConstant.LaunchReason.START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
        let lastExitInfo = getExitInfo(launchParam)
        // report lastExitInfo
    }
}
```

### 监控FPS/滑动掉帧率

`hm_metricx_cj` 提供
```text
public func initPageEventHandler(
    uiContext: UIAbilityContext,
    reportFpsInfo: (fpsInfo: FpsEventInfo) -> Unit
): Unit

public func initPageEventHandler(
    windowStage: WindowStage,
    reportFpsInfo: (fpsInfo: FpsEventInfo) -> Unit
): Unit

public func initScrollEventHandler(
    uiContext: UIAbilityContext,
    reportScrollInfo: (scrollInfo: ScrollHitchInfo) -> Unit
): Unit
```
接口对FPS/滑动掉帧率进行监控。

`initPageEventHandler` 需要的入参说明如下：

- `uiContext: UIAbilityContext` 指定UIAbility上下文
- `reportFpsInfo: (fpsInfo: FpsEventInfo) -> Unit` 用于每次页面退出时，将统计到的FPS信息进行上报，入参为 `FpsEventInfo` 类型对象

`FpsEventInfo` 包含以下信息：

- `minFps` 一段时间内，每隔一秒采样，测量到的最低帧率值
- `avgFps` 一段时间内，测量到的平均帧率值
- `pageName` 所在页面名称

`initPageEventHandler` 需要的入参说明如下：

- `windowStage: WindowStage` 指定WindowStage
- `reportFpsInfo: (fpsInfo: FpsEventInfo) -> Unit` 用于每次进入后台时，将统计到的FPS信息进行上报，入参为 `FpsEventInfo` 类型对象

`initScrollEventHandler` 需要的入参说明如下：

- `uiContext: UIAbilityContext` 指定UIAbility上下文
- `reportScrollInfo: (scrollInfo: ScrollHitchInfo) -> Unit` 用于每次滑动事件停止时，将统计到的滑动掉帧率信息，以及FPS信息进行上报，入参为 `ScrollHitchInfo` 类型对象。 

`ScrollHitchInfo` 继承 `FpsEventInfo` 的所有信息，并包含以下信息：

- `frameDropRatio` 滑动掉帧率
- `jankRate` 卡顿率
- `bigJankRate` 严重卡顿率
- `htLessThan0` 延迟小于0的帧数比例
- `ht0To00001` 延迟在0到0.0001秒之间的帧数比例
- `ht00001To0001` 延迟在0.0001到0.001秒之间的帧数比例
- `ht0001To001` 延迟在0.001到0.01秒之间的帧数比例
- `ht001To005` 延迟在0.01到0.05秒之间的帧数比例
- `ht005To01` 延迟在0.05到0.1秒之间的帧数比例
- `ht01To1` 延迟在0.1到1秒之间的帧数比例
- `htBiggerThan1` 延迟大于1秒的帧数比例
- `targetFPS` 目标帧率
- `longestLostFrame` 最长丢失的帧时间
- `totalFrameCount` 总帧数



使用示例：

i.
在主模块的 `main_ability.cj` 的 `onCreate` 回调中调用 `initPageEventHandler` 和 `initScrollEventHandler` ：
```text
class EntryAbility <: UIAbility {
    public override func onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Unit {
        AppLog.info("Ability OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case AbilityConstant.LaunchReason.START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
        initScrollEventHandler({data =>})
    }
}
```

ii.
在主模块的 `main_ability.cj` 的 `onWindowStageCreate` 回调中调用 `initPageEventHandler` ：
```text
class EntryAbility <: UIAbility {
    public override func onWindowStageCreate(windowStage: window.WindowStage): Unit {
        windowStage.loadContent("pages/index", {err, data => ()})
        initPageEventHandler(windowStage, {data =>})
        windowStage.getMainWindow(
            {
                err, data => match(data) {
                    case Some(x) => initPageEventHandler(this.context, {data =>})
                    case None => AppLog.info("initPageEventHandler error)
                }
            }
        )
    }
}
```

### 监控交互响应延迟

`hm_metricx_cj` 提供
```text
public func initLaggyHandle(applicationcontext: ApplicationContext, uiContext: UIContext,
                            maxTime: Int64, maxArraySize: Int64,
                            reportLaggyInfo: (data: JsonObject) -> Unit)
```
接口对交互式响应延迟提供监控能力。

`initLaggyHandle` 需要的入参说明如下：

- `applicationcontext` 指定应用上下文。

- `uiContext` 指定 `uiContext`。

- `maxTime` 指定最大的响应时间，超过该时间视为一次卡顿事件。

- `maxArraySize` 指定存储最大的卡顿时间集合，当卡顿次数超过该值时，会删除最早的一次卡顿数据。

- `reportLaggyInfo` 上报数据的回调函数，入参为 `JsonObject` 类型对象，该对象包含以下字段：
  - `pageName` 当前页面名称
  - `technologyStack` 技术栈
  - `responseTime` 响应时间，单位：ms
  - `descriptionID` 响应组件的结构信息
  - `nodeType` 响应组件类型
  - `viewTouchID` 响应组件ID
  - `touchX` 点击位置相对于应用窗口左上角的X坐标，单位：px
  - `touchY` 点击位置相对于应用窗口左上角的Y坐标，单位：px
  - `hitX` 响应组件相对于应用窗口的X轴偏移，单位: px
  - `hitY` 响应组件相对于应用窗口的Y轴偏移，单位: px
  - `hitWidth` 响应组件大小的宽度，单位: vp
  - `hitHeight` 响应组件大小的高度，单位: vp

使用示例：

i.

在主模块的 `main_ability.cj` 的 `onWindowStageCreate` 回调中调用 `initLaggyHandler` :

```text
public func onWindowStageCreate(windowStage: window.WindowStage): Unit {
    windowStage.loadContent("pages/index", {err, data => ()})
    windowStage.getMainWindow(
        {
            err: ?BusinessException, data: ?window.Window => match (data) {
                case Some(x) => initLaggyHandler(this.context.getApplicationContext(),
                    fromUIContextBase(x.getUIContext()), 10, 10, {data =>})
                case None => AppLog.info("initLaggyHandler error")
            }
        })
}
```

### 监控内存

`hm_metricx_cj` 提供

```text
// 注册内存监控
public func initMemoryHandler(
    context: UIAbilityContext,
    reportPageMemoryInfo: (info: PageMemoryInfo) -> Unit,
    reportProcessMemoryInfo: (info: ProcessMemoryInfo) -> Unit,    
    memoryThreshold!: Int64 = 100*1024
): Unit
// 取消内存监控
public func destroyMemoryHandler(): Unit
// 获取页面内存信息
public func getPageMemoryInfo(): PageMemoryInfo
// 获取进程内存信息
public func getProcessMemoryInfo(): ProcessMemoryInfo
```

接口对应用的内存使用情况进行监控。

`initMemoryHandler` 需要的入参说明如下：

- `context: UIAbilityContext` 指定UIAbility上下文。
- `reportPageMemoryInfo: (info: PageMemoryInfo) -> Unit` 将当前页面内存的使用情况进行上报，入参为 `PageMemoryInfo` 类型对象。
- `reportProcessMemoryInfo: (info: ProcessMemoryInfo) -> Unit` 将进程内存的使用情况进行上报，入参为 `ProcessMemoryInfo` 类型对象。
- `memoryThreshold!: Int64` 内存使用阈值，默认为100 * 1024 KB。当使用内存超过该阈值时，将内存使用情况上报。

`PageMemoryInfo` 包含以下信息：
- `avgMemory` 内存使用平均值，单位为KB
- `maxMemory` 内存使用最大值，单位为KB
- `sampleCount` 内存采样次数
- `pageName` 当前页面名称

`ProcessMemoryInfo` 包含以下信息：
- `avgMemory` 内存使用平均值，单位为KB
- `maxMemory` 内存使用最大值，单位为KB
- `sampleCount` 内存采样次数
- `pid` 进程ID

使用示例：

i.

在主模块的 `main_ability.cj` 的 `onCreate` 回调中调用 `initMemoryHandler` 

ii.

在主模块的 `main_ability.cj` 的 `onDestroy` 回调中调用 `destroyMemoryHandler` ：

```text
class EntryAbility <: UIAbility {
    public override func onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Unit {
        AppLog.info("Ability OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case AbilityConstant.LaunchReason.START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
        initMemoryHandler(this.context, {data =>}, {data =>})
    }
    public override func onDestroy(): Unit {
        destroyMemoryHandler()
        AppLog.info("myAbility onDestroy.")
    }
}
```

### 监控CPU

`hm_metricx_cj` 提供

```text
// 注册CPU监控
public func initCpuHandler(
    ability: UIAbility,
    reportPageCpuInfo: (info: PageCpuInfo) -> Unit,
    reportProcessCpuInfo: (info: ProcessCpuInfo) -> Unit
): Unit
// 取消CPU监控
public func destroyCpuHandler(): Unit
// 获取页面CPU信息
public func getPageCpuInfo(): PageCpuInfo
// 获取进程CPU信息
public func getProcessCpuInfo(): ProcessCpuInfo
```

接口对应用的CPU使用情况进行监控。

`initCpuHandler` 需要的入参说明如下：

- `context: UIAbilityContext` 指定UIAbility上下文。
- `reportPageCpuInfo: (info: PageCpuInfo) -> Unit` 将当前页面的CPU的使用情况进行上报，入参为 `PageCpuInfo` 类型对象。
- `reportProcessCpuInfo: (info: ProcessCpuInfo) -> Unit` 将进程的CPU的使用情况进行上报，入参为 `ProcessCpuInfo` 类型对象。

`PageCpuInfo` 包含以下信息：
- `avgCpu` CPU使用率平均值，以比例值表示（如使用率50%，则返回0.5）
- `maxCpu` CPU使用率最大值，以比例值表示
- `sampleCount` CPU采样次数
- `pageName` 当前页面名称

`ProcessCpuInfo` 包含以下信息：
- `avgCpu` CPU使用率平均值，以比例值表示（如使用率50%，则返回0.5）
- `maxCpu` CPU使用率最大值，以比例值表示
- `sampleCount` CPU采样次数
- `pid` 进程ID

使用示例：

i.

在主模块的 `main_ability.cj` 的 `onCreate` 回调中调用 `initCpuHandler`

ii.

在主模块的 `main_ability.cj` 的 `onDestroy` 回调中调用 `destroyCpuHandler` ：

```text
class EntryAbility <: UIAbility {
    public override func onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Unit {
        AppLog.info("Ability OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case AbilityConstant.LaunchReason.START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
        initCpuHandler(this.context, {data =>}, {data =>})
    }
    public override func onDestroy(): Unit {
        destroyCpuHandler()
        AppLog.info("myAbility onDestroy.")
    }
}
```

### 监控电量

`hm_metricx_cj`提供

```text
// 注册电量监控
public func initBatteryHandler(
    ability: UIAbility,
    reportBatteryInfo: (batteryInfo: BatteryUsageInfo) -> Unit,
    reportThreadCpuUsageInfo: (allThreadCpuUsageInfo: AllThreadCpuUsageInfo) -> Unit,
    limit!: Int32 = 1
): Unit
// 取消电量监控
public func destroyBatteryHandler(): Unit
```

接口对手机的掉电情况进行监控。

`initBatteryHandler` 需要的入参说明如下：

- `ability: UIAbility` 指定应用组件。
- `reportBatteryInfo: (batteryInfo: BatteryUsageInfo) -> Unit` 用于在发生掉电时，将相应的信息进行上报，入参为 `BatteryUsageInfo` 类型对象。
- `reportThreadCpuUsageInfo: (allThreadCpuUsageInfo: AllThreadCpuUsageInfo) -> Unit` 用于上报所有线程的CPU使用情况，当检测到CPU使用异常时，该回调函数会被触发，函数入参为`AllThreadCpuUsageInfo` 类型对象。
- `limit!: Int32` 掉电x格上报，默认为1。

`BatteryUsageInfo` 包含以下信息：

- `currentPageName` 当前浏览页面
- `level` 当前电量
- `temperature` 当前电池温度，单位为摄氏度（°C）
- `capacity` 电池容量（当前暂不支持获取）
- `scale` 电池的最大电量，默认为100
- `status` 电池的当前状态
- `health` 电池的健康状况
- `voltage` 电池的当前电压，单位为毫伏特
- `technology` 电池的技术类型
- `plugged`  设备的连接方式
- `charging` 设备是否在充电
- `limit` 掉电x格上报，默认为1格
- `brightness` 屏幕亮度
- `useTime` APP前台使用时间，单位为s
- `time` 距离上次掉电的时间间隔，单位为s

`AllThreadCpuUsageInfo` 包含以下信息：

- `threadCpuUsageInfoList` 所有线程的CPU使用信息，类型为`ArrayList<ThreadCpuUsageInfo>`

`ThreadCpuUsageInfo` 包含以下信息：
- `threadId` 线程id
- `threadName` 线程名
- `threadState` 线程状态
- `threadJiffiesPercent` 线程的CPU使用率百分比
- `threadJiffies` 线程的CPU使用时间
- `totalJiffies` 总的CPU时间
- `startBgTime` 线程进入后台的时间
- `exceptionTime` 线程出现异常的时间

使用示例：

i.

在主模块的 `main_ability.cj` 的 `onCreate` 回调中调用 `initBatteryHandler`

ii.

在主模块的 `main_ability.cj` 的 `onDestroy` 回调中调用 `destroyBatteryHandler` ：

```text
class EntryAbility <: UIAbility {
    public override func onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Unit {
        AppLog.info("Ability OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case AbilityConstant.LaunchReason.START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
        initBatteryHandler(this, {data =>}, {data =>})
    }
    
    public override func onDestroy(): Unit {
        destroyBatteryHandler()
        AppLog.info("myAbility onDestroy.")
    }
}
```

### 监控流量

流量监控依赖正确配置对网络统计信息的访问权限，即需要在应用的 `module.json5` 中添加以下内容

```text
"requestPermissions": [
    {
        "name": "ohos.permission.GET_NETWORK_INFO"
    }
]
```

`hm_metricx_cj` 提供

```text
// 注册占用存储空间上报函数
public func initTrafficHandler(
    context: UIAbilityContext,
    reportTraffic: (sampleTraffixInfo: SampleTrafficInfo) -> Unit,
    reportYesterdayTraffic: (yesterdayTraffic: DayTrafficInfo) -> Unit,
    sampleTime!: Int64 = 10 * 60 * 1000,
    sampleThreshold!: Int64 = 50 * 1024 * 1024
): Unit


// 取消流量监控
public func destroyTrafficHandler()

```

接口对app占用存储空间获取并进行上报。

`initTrafficHandler` 需要的入参说明如下：
- `context`: `UIAbilityContext` 指定UIAbility上下文。
- `reportTraffic: (sampleTraffixInfo: SampleTrafficInfo) -> Unit` 回调函数，用于上报流量使用情况。当流量数据达到上报阈值`sampleThreshold`时，回调被触发。
- `reportYesterdayTraffic: (yesterdayTraffic: DayTrafficInfo) -> Unit` 回调函数，用于在应用启动时上报前一天的流量使用情况, 仅上报一次。
- `sampleTime` 用于设置流量数据的采样时间间隔，单位为毫秒。
- `sampleThreshold` 用于设置流量数据的上报阈值，单位为字节。

`SampleTrafficInfo` 包含以下信息：

- `systemInfo: SystemTrafficInfo` 系统级别流量信息
- `pageInfoMap: HashMap<String, PageTrafficInfo>` 页面级别的流量信息，键为页面名称，值为对应的流量信息
- `urlInfoArray: ArrayList<UrlTrafficInfo>` URL级别的流量信息

`TrafficInfo` 包含以下信息

- `totalDailyTraffic` 应用日流量信息
- `totalTraffic` 单次进程总流量
- `limit` 触发告警的流量阈值

`SystemTrafficInfo` 在 `TrafficInfo` 基础上，添加如下信息：

- `timeStamp: String` 时间戳，表示流量数据的采集时间

`PageTrafficInfo` 在 `TrafficInfo` 基础上，添加如下信息：

- `pageName: String` 页面名称

`UrlTrafficInfo` 在 `TrafficInfo` 基础上，添加如下信息：

- `url: String` url地址

`DayTrafficInfo` 在 `TrafficInfo` 基础上，添加如下信息：

- `date: String` 日期

使用示例：

i.

在主模块的 `main_ability.cj` 的 `onCreate` 回调中调用 `initTrafficHandler` ：

ii.

在主模块的 `main_ability.cj` 的 `onDestroy` 回调中调用 `destroyTrafficHandler` ：

```text
class EntryAbility <: UIAbility {
    public override func onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Unit {
        AppLog.info("Ability OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case AbilityConstant.LaunchReason.START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
        initTrafficHandler(this, {data =>})
    }
    public override func onDestroy(): Unit {
        destroyTrafficHandler()
        AppLog.info("myAbility onDestroy.")
    }
}
```



### 监控存储

`hm_metricx_cj` 提供

```text
// 注册占用存储空间上报函数
public func initStorageHandler(
    reportStorageInfo: (storageInfo: StorageInfo) -> Unit,
    sizeLimit!: Int64,
    dirSizeLimit!: Int64,
    reportTopNum!: Int64 = 5
): Unit
// 上报占用存储空间
public func reportAppStorageInfo(): Unit
```

接口对app占用存储空间获取并进行上报。

`initStorageHandler` 需要的入参说明如下：

- `reportStorageInfo: (storageInfo: StorageInfo) -> Unit` 用于获取app占用存储空间时，将app占用存储空间进行上报，入参为 `StorageInfo` 类型对象。
- `sizeLimit`   存储大小阈值。超过该阈值会上报top N个异常文件和异常文件夹。
- `dirSizeLimit`  文件夹大小阈值。超过该阈值的文件夹被标记为异常文件夹。
- `reportTopNum` 用于设置上报的前N个文件/夹数量。

`StorageInfo` 包含以下信息

- `appSize` 应用安装文件大小，单位为Byte
- `cacheSize` 应用缓存文件大小，单位为Byte
- `dataSize` 应用文件存储大小（除应用安装文件和缓存文件），单位为Byte
- `totalSize` 数据的大小，单位为Byte
- `topStorageFileList` 文件列表，包含size最大的N个文件
- `exceptionDirList` 异常文件夹列表，包含超过dirSizeLimit大小限制的文件夹

使用示例：

i.

在主模块的 `main_ability.cj` 的 `onCreate` 回调中调用 `initBatteryHandler` ：

```text
class EntryAbility <: UIAbility {
    public override func onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Unit {
        AppLog.info("Ability OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case AbilityConstant.LaunchReason.START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
        initStorageHandler({data: StorageInfo =>}, sizeLimit: 100000000, dirSizeLimit: 1000, reportTopNum: 5)
    }
}
```

ii.

需要上报app占用存储空间时，调用 `reportAppStorageInfo` 函数 ：

```text
reportAppStorageInfo()
```

### 监控内存泄漏

`hm_metricx_cj` 提供

```text
public func initMemLeakHandler(
    context: UIAbilityContext,
    persistentDir: Path,
    needDumpSnapshot: (pageInfo: PageInfo, typeInfos: List<String>) -> Bool,
    clearHistoryComponentInfo: (typeInfos: List<String>) -> Bool,
    reportMemLeak: (path: Path) -> Unit
)
```

接口对内存泄漏进行监控。

`initMemLeakHandler` 需要的入参说明如下：

- `context: UIAbilityContext` 指定UIAbility上下文。
- `persistentDir: Path` 指定内存快照导出目录。
- `needDumpSnapshot: (pageInfo: PageInfo, typeInfos: List<String>) -> Bool` 是否需要导出内存快照， `pageInfo` 为 `PageInfo` 类型对象，记录页面切换的名称信息，`typeInfos` 记录存活组件的类型信息。
- `clearHistoryComponentInfo: (typeInfos: List<String>) -> Bool` 每次内存检测结束，是否清除存活的组件，`typeInfos` 记录存活组件的类型信息。
- `reportMemLeak: (path: Path) -> Unit` 内存泄漏上报函数，入参为 `Path` 类型对象，表示内存快照文件路径。

`PageInfo` 包含以下信息：

- `fromPage` 页面切换的源页面名称。
- `toPage` 页面切换的目的页面名称。

使用示例：

i.

```text
class EntryAbility <: UIAbility {
    public override func onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Unit {
        AppLog.info("Ability OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case AbilityConstant.LaunchReason.START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
        initMemLeakHandler(
            this.context,
            Path(this.context.cacheDir),
            {pageInfo, typeInfos => true},
            {typeInfos => false},
            {dumpFilePath => AppLog.info("dumpFilePath : ${dumpFilePath.toString()}")})
    }
}
```