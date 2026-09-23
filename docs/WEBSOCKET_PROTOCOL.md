# 网络协议

> 与 Android 仓库 `server/` 当前实现对齐；默认端口 `9527`。

## HTTP

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| GET | `/health` | 健康检查 |
| GET | `/games/daily` | 每日挑战 |
| GET | `/rankings?limit=20` | 排行榜 |
| POST | `/rankings` | 提交结算 |

每日挑战字段：

```text
id、size、winLength、board、next、answer、title
```

提交排行字段：

```text
playerId、name、result(WIN/LOSS/DRAW)
```

## WebSocket

地址：`ws://<host>:9527/ws`

客户端消息：

```text
hello           playerId、name
room.create     size、winLength
room.join       code
room.state      code（可选）
move            row、col
game.surrender
```

服务端消息：

```text
connected、hello.ok、room.created、room.state、error
```

`room.state.room` 至少包含：

```text
code、size、winLength、board、turn、status、winner、yourMark、players、spectators
```

状态：`WAITING`、`PLAYING`、`FINISHED`。

## 权威规则

- 服务器校验房间、身份、回合、坐标、占用、胜负和平局。
- 客户端不得自行宣布网络对局结果。
- 每次收到 `room.state`，以服务端棋盘覆盖本地房间棋盘。

## 蓝牙

蓝牙复用同一业务消息模型，通过换行分隔 JSON；首版两机 RFCOMM。多机需求优先由 WebSocket 房间满足。

## 联调前补强

Android 当前协议没有 `requestId` 和 `version`。正式跨端联调前升级协议版本，加入房间版本号、幂等请求和断线恢复，避免重复落子与乱序覆盖。
