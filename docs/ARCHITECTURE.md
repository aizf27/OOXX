# 鸿蒙端项目架构

## 1. 分层

```text
页面 / 组件
    ↓
GameStore 或 ViewModel
    ↓
GameRepository
    ↓
本地数据源 / WebSocket 数据源
```

- 页面：只负责展示和派发用户操作。
- 状态层：维护当前页面状态、加载状态、错误提示和导航状态。
- 仓库：统一提供开始、落子、检查、重启、保存等操作。
- 规则服务：纯逻辑校验，不依赖 ArkUI、网络或持久化。

## 2. 目录建议

```text
entry/src/main/ets/
├── pages/          # HomePage、GamePage、RulesPage
├── components/     # 棋盘、格子、顶部栏、工具栏
├── model/          # Puzzle、BoardState、GameState、枚举
├── service/        # GameRuleService、PuzzleService
├── repository/     # GameRepository、LocalGameRepository
├── store/          # 单机状态管理
└── utils/          # 时间、格式化等通用工具
```

后续联网增加：

```text
├── network/        # WebSocketClient、消息编解码
└── repository/     # RemoteGameRepository
```

## 3. 第一版页面

- `HomePage`：标题、开始游戏、游戏规则。
- `GamePage`：计时、棋盘、检查、重启、返回。
- `RulesPage`：三条规则和点击说明。

## 4. 棋盘组件原则

- 棋盘尺寸根据可用宽度计算，单元格保持正方形。
- 固定格与玩家格使用不同视觉样式。
- X 和 O 不使用图片依赖，优先使用文字或自绘样式。
- 棋盘组件只接收状态和回调，不直接调用仓库。

## 5. 单机与联网的衔接

第一版使用 `LocalGameRepository`，后续实现 `RemoteGameRepository`。

两者对外保持相同操作语义：

- 加载谜题；
- 修改格子；
- 检查棋盘；
- 重启谜题；
- 获取当前状态。

单机模式由本地状态作为权威；联网模式由服务器返回状态作为权威。

## 6. 安卓端协作约定

安卓端使用 Kotlin + XML 实现自己的页面和仓库，但必须统一：

- 模型名称和字段含义；
- `CellValue`、`GameStatus`、`RoomMode` 等枚举；
- 校验规则；
- WebSocket JSON 字段名；
- 错误码和完成状态。
