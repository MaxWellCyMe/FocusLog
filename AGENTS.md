# FocusLog 项目约定

## 项目定位

FocusLog 是一个本地优先的 iOS 专注与任务管理应用，使用 SwiftUI、SwiftData、Charts 和 UserNotifications。默认用中文沟通；新增或修改的应用界面文案沿用当前英文风格。

## 目录地图

| 位置 | 职责 |
| --- | --- |
| `FocusLog/App/` | 应用入口、根 Tab 和路由状态 |
| `FocusLog/Core/Models/` | SwiftData 任务与专注记录模型 |
| `FocusLog/Core/Timer/` | 可持久化恢复的专注计时状态机 |
| `FocusLog/Core/Services/` | 任务提醒与计时完成通知 |
| `FocusLog/Core/Analytics/` | 纯数据统计与连续专注日计算 |
| `FocusLog/Features/Today/` | 今日、未来、逾期任务视图及组件 |
| `FocusLog/Features/Tasks/` | 任务详情与创建/编辑流程 |
| `FocusLog/Features/Focus/` | 专注计时器界面 |
| `FocusLog/Features/Insights/` | 趋势统计与专注历史 |
| `FocusLog/Features/Settings/` | 外观、通知和应用信息设置 |
| `FocusLogTests/` | 计时器和统计逻辑的单元测试 |
| `.agents/skills/focuslog-ios-development/` | FocusLog 项目技能及按需参考资料 |

## 修改约定

- 先读目标文件及其直接调用方，再沿用现有 SwiftUI、Observation、SwiftData 和 `AppRouter` 模式做局部修改。
- Tab 内 push 路由由 `AppRouter` 管理；新增路由时同步检查目标 NavigationStack 的 destination 和相关跳转入口。
- SwiftData 模型字段变化要考虑已有本地数据和迁移兼容性；不要只为界面临时状态扩充持久化模型。
- 计时器以持久化 deadline 推导剩余时间。阶段完成、重置、暂停和恢复时，保持通知与计时状态同步；休息阶段不计为专注记录。
- 日期筛选使用 `Calendar.current` 的日历边界；任务完成/撤销时同步维护 `completedAt` 和提醒。
- 新增统计逻辑优先放在 `Core/Analytics/` 并提供可注入时间/日历的确定性测试。
- 页面职责明显增长时，将可复用行、编辑表单或摘要区域拆入相邻 feature/component 目录。
- 默认不添加第三方依赖，不把用户数据发送到服务端，也不生成构建产物或提交 DerivedData。
- 不执行 GitHub 推送、发布或其他外部写操作，除非用户明确要求。

## 验证

针对改动风险选择验证：

```bash
xcodebuild -project FocusLog.xcodeproj \
  -scheme FocusLog \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

```bash
xcodebuild -project FocusLog.xcodeproj \
  -scheme FocusLog \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
```

报告实际执行的构建、测试或模拟器检查；未执行的验证不要描述为通过。具体架构地图和按任务选取的检查流程见 `.agents/skills/focuslog-ios-development/SKILL.md`。
