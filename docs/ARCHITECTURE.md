# 鸿蒙端项目架构

## 分层

```text
ArkUI 页面/组件
      ↓
AppStore / GameStore
      ↓
Repository / MatchTransport
      ↓
HTTP、WebSocket、蓝牙、本地存储

GameEngine 为独立纯算法模块
```

## 目录

```text
entry/src/main/ets/
├── pages/          # 启动、引导、首页、模式、房间、对局、结算、战绩、我的
├── components/     # 棋盘、模式卡片、底栏、状态卡片
├── model/          # Board、Move、Puzzle、Record、协议 DTO
├── service/        # GameEngine、PuzzleValidator
├── repository/     # 题库、战绩、排行仓库
├── store/          # AppStore、GameStore
├── network/        # HTTP、WebSocket
├── match/          # MatchConnection、WebSocket/Bluetooth 适配器
└── theme/          # 颜色、间距、圆角
```

## Android 对齐点

参考 Android `main` 分支提交 `1406e32`：

- `GameEngine`：棋盘、胜负、AI、唯一解生成。
- `GameRepository`：网络题目、本地战绩、排行。
- `OoxxViewModel`：页面与对局状态。
- `MatchTransport`：WebSocket 与蓝牙统一连接接口。

鸿蒙不复制 Compose 代码，只保持规则、状态语义和协议一致。

## 状态

```text
Screen: SPLASH、ONBOARDING、HOME、MODE、ROOM、GAME、RESULT、HISTORY、PROFILE
GameKind: AI_3X3、AI_5X5、LOCAL、DAILY、NETWORK、BLUETOOTH
MatchResult: WIN、LOSS、DRAW
```

## 约束

- 页面不直接实现胜负算法。
- Repository 不依赖 ArkUI。
- WebSocket/蓝牙都实现统一 `MatchConnection`。
- 网络对战客户端只发操作，收到 `room.state` 后覆盖本地房间状态。
