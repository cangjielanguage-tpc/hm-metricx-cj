# Changelog

## 1.0.24

- 高 CPU 异常回调监控新增返回异常期间完整调用栈，监控周期由 3 分钟改为 30 秒
- `HighCpuReportInfo`/`BackgroundCpuReportInfo` 新增 `stackTrace`（异常线程调用栈）、`moduleName`（责任模块名）字段
- 高 CPU 上报只抓取 CPU 最高的单线程（Top1）调用栈
- 修复停止热压后仍误报高 CPU 的问题

## 1.0.23

- 发热异常回调增加 `cpuNum`（CPU 核心数）字段
- 新增页面进入→离开完整流量增量获取接口 `getAndResetCurrentPageTraffic`
- 流量上报增加承载网标注 `bearerType`（wlan/mobile），标注本次上报走的是 wifi 还是移动网络
- 重构 entryEts 拆分为分层模块（common/components/pages/store），首页支持展示上次崩溃（重启回吐）

## 1.0.22

- 调整项目结构，将 ApmApplication 目录内容提升至项目根目录
- 修正流量回调参数顺序，修复上下行流量反转问题
- 修改路由切换更新当前页面信息
- 修改日志跨天上报的问题

## 1.0.8

- 删除 crashLogPath 字段

## 1.0.7

- 修复 crash 日志乱序问题

## 1.0.6

- 修复流量上报的问题

## 1.0.5

- 修复内存上报的问题

## 1.0.4

- 修复交互响应延迟的问题

## 1.0.3

- 修复 C 层内存监控 crash 的问题

## 1.0.2

- 添加代码示例

## 1.0.1

- 修复文档描述

## 1.0.0

- 支持 crash 事件监控
- 支持 freeze 事件监控
- 支持进程异常退出监控
- 支持 FPS 统计
- 支持滑动掉帧率统计
- 支持交互响应延迟统计
- 支持内存监控
- 支持 CPU 监控
- 支持掉电率统计
- 支持流量统计
- 支持存储使用统计