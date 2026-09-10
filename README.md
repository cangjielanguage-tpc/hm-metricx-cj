<div align="center">
<h1>hm-metricx-cj</h1>
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v1.0.1-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/build-pass-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v1.1.0-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjcov-NA-red" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/project-open-brightgreen" style="display: inline-block;" />
</p>

## 介绍

`hm-metricx-cj` 是一款适用于鸿蒙应用的线上性能监控框架。

`hm-metricx-cj` 系统性地采集和分析监控指标数据，帮助开发团队及时发现性能瓶颈和异常，持续优化应用质量，提升用户体验。

## 优势

- 覆盖范围广，支持收集多种量化指标
- 简单便捷，使用无需繁琐的配置
- 轻量高效，可在线上使用

## 使用流程，基于 DevEco Studio 6.1.1.280 和 DevEco Studio-Cangjie Plugin 6.1.1 Beta1

 - 在file -> project structure -> signing Configs: ☑️勾选Automatically generate signature，然后apply再点ok。 
 - 点中hm_metricx_cj文件夹，然后再Build -> make moudle "hm_metricx_cj", 之后会产生一个hm_metricx_cj.har文件。 
 - 在entry里创建一个libs文件夹（跟src同级），然后把hm_metricx_cj.har放入libs，同时在entry中的oh-package.json5中uncomment(去掉//) "@cangjie-tpc/hm_metricx_cj_hybrid": "file:./libs/hm_metricx_cj.har"。 
 - 然后点运行即可。

### 特性

1. 支持 crash 事件监控
2. 支持 freeze 事件监控
3. 支持进程异常退出监控
4. 支持 FPS 统计
5. 支持滑动掉帧率统计
6. 支持交互响应延迟统计
7. 支持内存监控
8. 支持 CPU 监控
9. 支持掉电率统计
10. 支持流量统计
11. 支持存储使用统计


## 软件架构

![](./docs/assets/img.png)

### 源码目录

```shell
─hm_metricx_cj
  └─src
      └─main
          ├─cangjie
          │  ├─battery
          │  ├─cpu
          │  ├─crash
          │  ├─exitInfo
          │  ├─fps
          │  ├─freeze
          │  ├─laggy
          │  ├─memory
          │  ├─storage
          │  ├─traffic
          │  ├─types
          │  ├─util
          │  └─wrapper
          ├─cpp
          └─resources

```

- `hm_metricx_cj` 工程模块 - 编译生成一个har包
- `hm_metricx_cj src` 模块代码目录
- `hm_metricx_cj src main` 模块项目目录
- `hm_metricx_cj src main cangjie` 仓颉代码目录
- `hm_metricx_cj src main cpp` cpp代码目录
- `hm_metricx_cj src main resources` 资源文件目录
- `hm_metricx_cj src main cangjie src battery` hm_metricx_cj 掉电率统计目录
- `hm_metricx_cj src main cangjie src cpu` hm_metricx_cj CPU 监控目录
- `hm_metricx_cj src main cangjie src crash` hm_metricx_cj crash 事件监控目录
- `hm_metricx_cj src main cangjie src exitInfo` hm_metricx_cj 进程异常退出监控目录
- `hm_metricx_cj src main cangjie src fps` hm_metricx_cj FPS/滑动掉帧率统计目录
- `hm_metricx_cj src main cangjie src freeze` hm_metricx_cj freeze 事件监控目录
- `hm_metricx_cj src main cangjie src laggy` hm_metricx_cj 交互响应延迟统计目录
- `hm_metricx_cj src main cangjie src memory` hm_metricx_cj 内存监控目录
- `hm_metricx_cj src main cangjie src storage` hm_metricx_cj 存储使用统计目录
- `hm_metricx_cj src main cangjie src traffic` hm_metricx_cj 流量统计目录
- `hm_metricx_cj src main cangjie src types` hm_metricx_cj 暴露给 ArkTS 层的类型声明目录
- `hm_metricx_cj src main cangjie src util` hm_metricx_cj 工具目录
- `hm_metricx_cj src main cangjie src wrapper` hm_metricx_cj 与 ArkTS 互操作接口目录

### 接口说明

主要类和函数接口说明详见 [manual](https://gitcode.com/Cangjie-TPC/hm-metricx-cj/blob/noohos_publish/docs/manual.md)

## 使用说明

### 集成方式

 在项目中使用 `hm_metricx_cj` 项目
   ```arkts
   import { initCrashHandler } from '@cangjie-tpc/hm_metricx_cj_hybrid'
   ```

### 功能示例

以 crash 监控为例：

i.
在主模块的 `EntryAbility.ets` 的 `onCreate` 回调中调用 `initCrashHandler` ：
```arkts
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    initCrashHandler(
      this.context.getApplicationContext(),
      () => "{}",
      data => hilog.error(DOMAIN, 'hm_metricx_cj', 'crash rawFile: ' + data.rawFile),
      this.context.cacheDir,
      OOMHandlerMode.ASYNC,
      1000,
      1000,
      new CMemMonitorConfig(data => false)
    );
  }
}
```

完整的示例详见 详见 [manual](https://gitcode.com/Cangjie-TPC/hm-metricx-cj/blob/noohos_publish/docs/manual.md)

## 约束与限制

当前分支基于 DevEco Studio 6.1.1.280 和 DevEco Studio-Cangjie Plugin 6.1.1 Beta1 版本实现。

1. crash 事件监控限制：
   1. 暂不支持收集存活仓颉线程数/仓颉线程名
2. freeze 事件监控限制：
   1. 暂不支持收集全量仓颉线程调用栈及状态
3. 内存监控限制：
   1. 暂不支持组件级内存泄漏监控
4. 掉电率统计限制：
   1. 暂不支持收集每秒 APP 耗电毫安时
   2. 暂不支持定时统计线程耗电毫安时

## 包体积

har 包体积：3.3 MB

纯 ArkTS 工程集成后，包体积额外增加 3.3 MB

ArkTS/Native 混合工程集成后，包体积额外增加 2.8 MB

## 和 ArkTS 版本的区别

- Cangjie 执行性能更高
- 覆盖的指标更全面
- 支持自定义收集信息

## 开源协议

本项目基于 [Apache License 2.0](https://gitcode.com/Cangjie-TPC/hm-metricx-cj/blob/noohos_publish/LICENSE) ，请自由的享受和参与开源。

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。
