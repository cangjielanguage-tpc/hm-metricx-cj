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


### 监控Freeze

### 监控异常退出原因

### 监控FPS

### 监控滑动掉帧率

### 监控交互响应延迟

### 监控内存

### 监控CPU

### 监控电量

### 监控流量

### 监控存储