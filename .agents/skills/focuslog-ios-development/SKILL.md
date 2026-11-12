---
name: focuslog-ios-development
description: 为 FocusLog iOS 应用实现或维护 SwiftUI 页面、SwiftData 模型、路由、计时器、通知和统计；不用于其他平台或通用 Swift 问题。
---

# FocusLog iOS 开发

## 项目上下文

先遵循仓库根目录的 `AGENTS.md`。FocusLog 是本地优先的 SwiftUI 应用；任务和专注记录使用 SwiftData，不依赖账号或后端。已有页面导航、计时持久化和通知同步都具有跨文件约定，修改时沿调用关系核对。

## 按需读取

| 任务 | 先读取 |
| --- | --- |
| 页面、数据流、路由或目录定位 | [架构地图](references/architecture.md) |
| 模型、计时器、通知、统计逻辑或测试变更 | [开发与验证流程](references/development.md) |

不要为纯文案或局部样式修改加载无关参考资料。

## 工作方式

1. 从根级 `AGENTS.md` 和目标 feature 进入；使用 `rg` 找路由、模型和服务调用方。
2. 明确状态归属：界面临时状态留在 View，跨页面导航放在 `AppRouter`，设备本地业务状态放在 Core。
3. 小范围实现，遵循已有 UI 与命名；跨文件契约变动时一并更新调用者、空状态和测试。
4. 对时间、阶段转换、提醒排程和 SwiftData 字段变化优先补确定性测试或迁移检查。
5. 运行与改动相称的构建/测试；有条件时用模拟器检查目标交互。准确记录验证边界。

## 关键行为

- 专注计时以 deadline 恢复运行状态；完成专注后切换到短休息，每四轮切换长休息。
- 只有完成的 focus 阶段创建 `FocusSession`；休息阶段不计入分析。
- 任务范围以本地日历日划分为 Today、Upcoming、Overdue；任务完成和撤销需更新 `completedAt` 并同步提醒。
- 统计计算集中于 `FocusInsightsCalculator`；聚合逻辑应保持可独立测试。
- 本地通知可能受系统授权状态影响；不要把已排程当作一定展示，也不要绕过用户授权。
