# 开发与验证流程

## 页面和路由

先读目标 View、`AppRouter` 和相邻子页面。新增 push route 时同步维护 enum、path、destination 与发起跳转的入口；Modal 编辑流程继续使用 sheet。避免重复引入另一套导航状态。

提取 UI 时按功能归属放到对应目录。共享模型行或摘要可进入 Today 的 `Components/`；跨 Feature 的任务编辑保持在 Tasks Feature。拆分应降低页面状态和布局的耦合，而不是仅按行数切文件。

## SwiftData 任务行为

- 任务的完成时刻保存于 `completedAt`；完成时写入当前时间，撤销时清空。
- 旧记录可能没有 `completedAt`，对既有数据要保留合理回退行为。
- Today 的未完成任务：截止日期是今天，或没有截止日期且今天创建。
- Upcoming：未完成且截止日期从明天开始。
- Overdue：未完成且截止日期早于今天。
- 完成任务按完成当天进入 Today，不参与 Upcoming/Overdue。
- 创建、编辑、完成、撤销和删除时检查提醒是否需要排程或取消。

需要验证日期边界时将 `Calendar` 和 `now` 作为纯逻辑参数，测试午夜、跨日和无截止日期情形，避免依赖测试运行当天。

## 计时器和通知

`FocusTimerController` 用持久化 deadline 计算剩余时间，因此不要改成依赖后台逐秒递减的唯一计时来源。状态变更要验证 start、pause、resume、reset、完成及应用恢复路径。

focus 完成后保存 `FocusSession` 并进入休息阶段；每第四轮进入长休息。休息完成只返回 focus，不创建专注历史。计时器通知应根据 running 状态和 deadline 同步，暂停/重置/阶段完成时撤销旧通知。

通知权限可能被拒绝或处于 provisional 等状态。权限拒绝时计时功能仍应正常工作，不要把请求授权当作计时器的前置条件。

## 测试和构建

当前 XCTest target 为 `FocusLogTests`，scheme 为 `FocusLog`。推荐命令：

```bash
xcodebuild -project FocusLog.xcodeproj \
  -scheme FocusLog \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
```

只改界面布局或文案时至少构建对应 App scheme；修改状态机、日期统计、模型或跨层交互时运行测试。项目已有五个测试，覆盖 focus/休息转换、暂停恢复、七日总量和连续天数。

构建失败要区分源码错误与当前机器缺失的 Xcode/模拟器条件。不要把构建缓存、DerivedData 或临时模拟器数据加入仓库。模拟器验收要实际查看目标页面，而不只报告安装或启动命令成功。

## 改动收尾

- `git diff --check` 检查空白和补丁格式。
- 检查改动涉及的导航目标、SwiftData 调用方、提醒副作用和 accessibility 文案。
- 保持 README 中项目树、功能说明和测试命令与实现同步。
- 最终说明修改点及实际验证结果；未验证的行为明确说明。
