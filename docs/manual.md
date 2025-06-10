# hm-metricx-cj

## 功能简介

`hm-metricx-cj` 是一款为鸿蒙系统上的仓颉应用提供的线上性能监控框架。 `hm-metricx-cj` 系统性地采集和分析监控指标数据，帮助开发团队及时发现性能瓶颈和异常，持续优化应用质量，提升用户体验。

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
    reportNativeCrashInfo: CFunc<(CString) -> Unit>,
    persistentDir: Path,
    enableDumpOnOOM: Bool
): Unit
```
接口对ArkTS/仓颉/Native层引发的崩溃进行监控。

`initCrashHandler` 需要的入参说明如下：

- `applicationContext: ApplicationContext` 指定应用上下文。
- `collectCrashInfo: () -> JsonValue` 用于在发生ArkTS/仓颉层引发的crash时，收集若干自定义的业务/系统信息(比如页面浏览路径等)，以json形式返回。
- `collectNativeCrashInfo: CFunc<() -> CString` 用于在发生Native层引发的crash时，收集若干自定义的业务/系统信息(比如页面浏览路径等)，以json字符串形式返回。
- `reportCrashInfo: (crashInfo: CrashInfo) -> Unit` 用于在发生ArkTS/仓颉层引发的crash时，将收集完毕的崩溃信息进行上报，入参为 `CrashInfo` 类型对象。 
- `reportNativeCrashInfo: CFunc<(CString) -> Unit` 用于在发生Native层引发的crash时，将收集完毕的崩溃信息进行上报，入参为包含 `CrashInfo` 信息的json字符串。
- `persistentDir: Path` 指定中间日志文件和内存快照的持久化目录。
- `enableDumpOnOOM: Bool` 指定是否在发生OOM时导出仓颉内存快照。

`CrashInfo` 包含以下信息：

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

使用示例：

i.
在主模块的 `module.json5` 中添加权限配置：
```text
"requestPermissions":[
	{
		"name":"ohos.permission.ACCESS_ANALYTICS"
	}
]
```

ii.
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
            { => JsonValue.fromStr("{}") },
            { => unsafe { LibC.mallocCString("{}") } },
            { crashInfo => },
            { crashInfo => },
            Path(this.context.cacheDir),
            true)
    }
}
```

> ** 注意: **
> 
> 对ArkTS/仓颉层引发的崩溃的监控依赖系统提供的ErrorManager机制。
> 
> 当存在其他ErrorManager回调，并且在崩溃监控对应的回调之前执行时，可能会干扰崩溃监控的正常行为，导致收集的数据错漏等情况。


### 监控Freeze

`hm_metricx_cj` 提供

```text
public func initFreezeHandler(
    applicationContext: ApplicationContext,
    reportFreezeInfo: (freezeInfo: FreezeInfo) -> Unit,
    persistentDir: Path
): Unit
```

接口对freeze事件进行监控。

`initFreezeHandler` 需要的入参说明如下：

- `applicationContext: ApplicationContext` 指定应用上下文。
- `reportFreezeInfo: (freezeInfo: FreezeInfo) -> Unit` 用于在APP发生freeze事件时，将收集完成的freeze信息进行上报，入参为 `FreezeInfo` 类型对象。
- `persistentDir: Path` 指定中间日志文件的持久化目录。

`FreezeInfo` 包含以下信息：

- `timestamp` freeze发生的时间戳
- `pid` freeze进程名
- `exception` freeze发生原因
- `hilog` Hilog日志
- `tid` freeze线程ID
- `tname` freeze线程名
- `freezeLogPath` 系统生成的faultlog文件路径
- `cpuThread` 线程CPU使用率
- `cpu` 进程CPU使用率
- `stacktrace` freeze调用栈

使用示例：

i.
在主模块的 `module.json5` 中添加权限配置：

```text
"requestPermissions":[
    {
        "name":"ohos.permission.ACCESS_ANALYTICS"
    }
]
```

ii.

在主模块的 `main_ability.cj` 的 `onCreate` 回调中调用 `initFreezeHandler` ：

```text
class EntryAbility <: UIAbility {
    public override func onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Unit {
        AppLog.info("Ability OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case AbilityConstant.LaunchReason.START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
        initFreezeHandler(this.context.getApplicationContext(), {data =>}, Path(this.context.cacheDir))
    }
}
```

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

`initPageEventHandler` 需要的入参说明如下：

- `windowStage: WindowStage` 指定WindowStage
- `reportFpsInfo: (fpsInfo: FpsEventInfo) -> Unit` 用于每次进入后台时，将统计到的FPS信息进行上报，入参为 `FpsEventInfo` 类型对象

`initScrollEventHandler` 需要的入参说明如下：

- `reportScrollInfo: (scrollInfo: ScrollHitchInfo) -> Unit` 用于每次滑动事件停止时，将统计到的滑动掉帧率信息，以及FPS信息进行上报，入参为 `ScrollHitchInfo` 类型对象。 

`ScrollHitchInfo` 继承 `FpsEventInfo` 的所有信息，并包含以下信息：

- `frameDropRatio` 滑动掉帧率

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
        initPageEventHandle(this.context, {data =>})
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
    }
}
```

### 监控交互响应延迟

`hm_metricx_cj` 提供
```text
public func initLaggyHandle(applicationcontext: ApplicationContext, uiContext: UIContext,
                            maxTime: Float64, maxArraySize: Int64,
                            reportLaggyInfo: (data: JsonObject) -> Unit)
```
接口对交互式响应延迟提供监控能力。

`initLaggyHandle` 需要的入参说明如下：

- `applicationcontext` 指定应用上下文。

- `uiContext` 指定 `uiContext`。

- `maxTime` 指定最大的响应时间，超过该时间视为一次卡顿事件。

- `maxArraySize` 指定存储最大的卡顿时间集合，当卡顿次数超过该值时，会删除最早的一次卡顿数据。

- `reportLaggyInfo` 上报数据的回调函数，接受一个输入型参数 `data`。

### 监控内存

`hm_metricx_cj` 提供

```text
// 注册内存监控
public func initMemoryHandler(
    ability: UIAbility,
    reportMemoryInfo: (info: MemoryInfo) -> Unit,
    memoryThreshold!: Int64
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

- `ability: UIAbility` 指定应用组件。
- `reportMemoryInfo: (info: MemoryInfo) -> Unit` 将内存的使用情况进行上报，入参为 `MemoryInfo` 类型对象。
- `memoryThreshold!: Int64` 内存使用阈值，默认为100 * 1024 KB。当使用内存超过该阈值时，将内存使用情况上报。

`MemoryInfo` 包含以下信息：

- `avgMemory` 内存使用平均值，单位为KB
- `maxMemory` 内存使用最大值，单位为KB
- `sampleCount` 内存采样次数

`PageMemoryInfo` 继承 `MemoryInfo` ，在 `MemoryInfo` 基础上，添加：

- `pageName` 当前页面名称

`ProcessMemoryInfo` 继承 `MemoryInfo` ，在 `MemoryInfo` 基础上，添加：

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
        initMemoryHandler(this, {data =>})
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
    reportCpuInfo: (info: CpuInfo) -> Unit
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

- `ability: UIAbility` 指定应用组件。
- `reportCpuInfo: (info: CpuInfo) -> Unit` 将CPU的使用情况进行上报，入参为 `CpuInfo` 类型对象。

`CpuInfo` 包含以下信息：

- `avgCpu` CPU使用平均值，单位为KB
- `maxCpu` CPU使用最大值，单位为KB
- `sampleCount` CPU采样次数

`PageCpuInfo` 继承 `CpuInfo` ，在 `CpuInfo` 基础上，添加如下信息：

- `pageName` 当前页面名称

`ProcessCpuInfo` 继承 `CpuInfo` ，在 `CpuInfo` 基础上，添加如下信息：

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
        initCpuHandler(this, {data =>})
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
    limit!: Int32
): Unit
// 取消电量监控
public func destroyBatteryHandler(): Unit
```

接口对手机的掉电情况进行监控。

`initBatteryHandler` 需要的入参说明如下：

- `ability: UIAbility` 指定应用组件。
- `reportBatteryInfo: (batteryInfo: BatteryUsageInfo) -> Unit` 用于在发生掉电时，将相应的信息进行上报，入参为 `BatteryUsageInfo` 类型对象。
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
        initBatteryHandler(this, {data =>})
    }
    
    public override func onDestroy(): Unit {
        destroyBatteryHandler()
        AppLog.info("myAbility onDestroy.")
    }
}
```

### 监控流量

`hm_metricx_cj` 提供

```text
// 注册占用存储空间上报函数
public func initTrafficHandler(
    ability: UIAbility,
    reportTrafficInfo: (trafficInfo: TrafficInfo) -> Unit,
    limits: ?Int32
): Unit
// 上报占用存储空间
public func reportTrafficInfo(): Unit
```

接口对app占用存储空间获取并进行上报。

`initTrafficHandler` 需要的入参说明如下：
- `ability`: `UIAbility`指定应用组件。

- `reportTrafficInfo: (trafficInfo: TrafficInfo) -> Unit` 用于获取app流量时，将app流量信息进行上报，入参为 `TrafficInfo` 类型对象。

`TrafficInfo` 包含以下信息

- `totalDailyTraffic` 应用日流量信息
- `totalTraffic` 单次进程总流量
- `limit` 触发告警的流量阈值

使用示例：

i.

在主模块的 `main_ability.cj` 的 `onCreate` 回调中调用 `initTrafficHandler` ：

```text
class EntryAbility <: UIAbility {
    public override func onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Unit {
        AppLog.info("Ability OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case AbilityConstant.LaunchReason.START_ABILITY => AppLog.info("START_ABILITY")
            case _ => ()
        }
        initBatteryHandler(this, {data =>}， 500 * 1024 * 1024)
    }
}
```

ii.

需要上报app占用存储空间时，调用 `reportTrafficInfo` 函数 ：

```text
reportTrafficInfo()
```

### 监控存储

`hm_metricx_cj` 提供

```text
// 注册占用存储空间上报函数
public func initStorageHandler(
    reportStorageInfo: (storageInfo: StorageInfo) -> Unit
): Unit
// 上报占用存储空间
public func reportAppStorageInfo(): Unit
```

接口对app占用存储空间获取并进行上报。

`initStorageHandler` 需要的入参说明如下：

- `reportStorageInfo: (storageInfo: StorageInfo) -> Unit` 用于获取app占用存储空间时，将app占用存储空间进行上报，入参为 `StorageInfo` 类型对象。

`StorageInfo` 包含以下信息

- `appSize` 应用安装文件大小，单位为Byte
- `cacheSize` 应用缓存文件大小，单位为Byte
- `dataSize` 应用文件存储大小（除应用安装文件和缓存文件），单位为Byte

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
        initBatteryHandler(this, {data =>})
    }
}
```

ii.

需要上报app占用存储空间时，调用 `reportAppStorageInfo` 函数 ：

```text
reportAppStorageInfo()
```

