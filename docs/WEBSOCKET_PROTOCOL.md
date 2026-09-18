# WebSocket 通信协议草案

> 状态：跨端阶段使用。第一版单机不连接服务器，但代码结构需预留仓库接口。

## 1. 基本约定

- 传输：原生 WebSocket。
- 数据：JSON，字段使用 `camelCase`。
- 服务端按接收顺序处理操作。
- 服务端维护房间最终状态，并广播已接受的结果。
- 客户端发送操作意图，不直接决定最终棋盘。
- 每次服务端接受状态变化后递增 `version`。

## 2. 通用消息字段

```text
 type       消息类型
 requestId  请求标识，可选
 roomId     房间号，可选
 playerId   玩家标识，可选
 version    客户端已知版本，可选
 payload    消息内容
```

## 3. 房间模式

- `COLLABORATIVE`：两端共同编辑一张棋盘。
- `COMPETITIVE`：两端各自解题，只同步成绩和完成状态。

第一种用于跨端协作演示，第二种后续实现。

## 4. 第一批消息

| 消息 | 方向 | 作用 |
| --- | --- | --- |
| `createRoom` | 客户端 → 服务端 | 创建房间 |
| `joinRoom` | 客户端 → 服务端 | 加入房间 |
| `roomState` | 服务端 → 客户端 | 返回完整房间状态 |
| `cellUpdate` | 双向 | 请求或广播一次落子 |
| `checkResult` | 双向 | 请求检查并返回错误格 |
| `restartPuzzle` | 双向 | 请求重启当前题目 |
| `puzzleCompleted` | 服务端 → 客户端 | 广播完成结果 |
| `playerJoined` | 服务端 → 客户端 | 通知玩家加入 |
| `playerLeft` | 服务端 → 客户端 | 通知玩家离开 |
| `error` | 服务端 → 客户端 | 返回失败原因 |
| `ping` / `pong` | 双向 | 保持连接和检测断线 |

## 5. 核心状态

房间状态至少包含：

- `roomId`
- `roomMode`
- `puzzleId`
- `size`
- 固定格布局
- 当前玩家棋盘
- `version`
- `status`：`WAITING`、`PLAYING`、`COMPLETED`
- 玩家列表

## 6. 落子规则

客户端发送：

```text
row、col、value、version
```

服务端处理：

1. 检查房间和玩家身份；
2. 检查坐标和固定格；
3. 按顺序写入状态；
4. 更新 `version`；
5. 广播服务端确认后的最新操作或完整状态。

如果版本过旧，返回 `VERSION_CONFLICT` 和最新 `roomState`。

## 7. 错误码建议

```text
ROOM_NOT_FOUND
ROOM_FULL
INVALID_CELL
CELL_LOCKED
INVALID_VALUE
VERSION_CONFLICT
PUZZLE_ALREADY_COMPLETED
INTERNAL_ERROR
```

## 8. 后续扩展

- 登录后携带认证 token；
- 断线重连后通过 `roomState` 恢复；
- 服务端保存房间和历史成绩；
- 增加独立竞速模式的计时和成绩消息。
