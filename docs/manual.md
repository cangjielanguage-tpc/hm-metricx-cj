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

### 监控Crash

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