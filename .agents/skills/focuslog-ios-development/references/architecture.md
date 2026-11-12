# 架构地图

## 应用和导航

`FocusLog/App/FocusLogApp.swift` 创建 SwiftData 容器并显示 `RootTabView`。`RootTabView` 管理 Today、Focus、Insights、Settings 四个 Tab，并根据 `AppAppearance` 应用外观。

`FocusLog/App/Navigation/AppRouter.swift` 定义 `AppTab`、`AppRoute` 和 `AppRouter`。每个具备 push 页面流的 Tab 持有独立 path。新增页面时同时检查：

- `AppRoute` 是否需要新 route case。
- 对应 `NavigationStack` 是否注册 destination。
- 调用方是否选择了正确 Tab 并传入稳定标识。

任务详情通过 `PersistentIdentifier` 从当前 SwiftData 查询结果重新定位模型，不要把完整模型塞进路由值。

## 核心数据和服务

| 类型 | 位置 | 角色 |
| --- | --- | --- |
| `FocusTask` | `Core/Models/FocusTask.swift` | 标题、分类、估时、截止日期、完成状态与完成时间 |
| `FocusSession` | `Core/Models/FocusSession.swift` | 已完成专注时段的本地历史 |
| `FocusTimerController` | `Core/Timer/FocusTimerController.swift` | deadline 驱动并写入 UserDefaults 的 Pomodoro 状态机 |
| `TaskReminderService` | `Core/Services/TaskReminderService.swift` | 未完成且未来到期任务的本地提醒 |
| `FocusTimerNotificationService` | `Core/Services/FocusTimerNotificationService.swift` | 运行中的计时阶段完成通知 |
| `FocusInsightsCalculator` | `Core/Analytics/FocusInsightsCalculator.swift` | 日统计和当前连续专注天数 |

SwiftData 模型由应用容器集中注册。修改 schema 时检查旧数据兼容，不要假设用户设备总是空库。

## Feature 页面

| Feature | 入口与子页面 | 主要关联 |
| --- | --- | --- |
| Today | `TodayView`、`Components/` | `TaskScope`、`TaskRow`、`TaskEditorView`、`TaskDetailView`、任务提醒 |
| Focus | `FocusTimerView` | `FocusTimerController`、完成通知、`FocusSession` |
| Insights | `InsightsView`、`SessionHistoryView` | `FocusInsightsCalculator`、`FocusSession` |
| Settings | `SettingsView` | 外观偏好、系统通知权限、About 页面 |

任务创建/编辑共享 `Features/Tasks/TaskEditorView.swift`。Today 列表组件放在 `Features/Today/Components/`，不要让一个页面文件承担全部行布局和编辑流程。

## 状态流向

```text
SwiftData queries -> Feature views -> user actions -> modelContext/services
Tab selection and push paths -> AppRouter
FocusTimerView -> FocusTimerController -> UserDefaults snapshot
FocusTimerController running deadline -> FocusTimerNotificationService
completed focus phase -> FocusSession -> FocusInsightsCalculator -> InsightsView
```

视图负责呈现和事件转发。可独立计算的统计逻辑放 Core，通知 side effect 放 Services，路由状态不放进具体页面内部。
