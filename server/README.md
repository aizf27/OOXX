# OOXX 标准 WebSocket 服务端

Node.js 服务端：HTTP 提供题目、排行接口；标准 WebSocket（不是 Socket.IO）提供实时房间与落子同步。

## 启动

```bash
npm install
npm start
```

默认监听 `0.0.0.0:9527`：

- `GET /health`
- `GET /games/daily`
- `GET /rankings?limit=20`
- `POST /rankings`
- `ws://<host>:9527/ws`

局域网演示时，将 Android 的地址设为电脑局域网 IP，例如 `ws://192.168.1.23:9527/ws` 与 `http://192.168.1.23:9527/`。Android 模拟器访问宿主机用 `10.0.2.2`。

## WebSocket 协议

连接后先发送：

```json
{"type":"hello","playerId":"guest-001","name":"康思"}
```

创建或加入房间：

```json
{"type":"room.create","size":3}
{"type":"room.join","code":"123456"}
```

落子和认输：

```json
{"type":"move","row":1,"col":2}
{"type":"game.surrender"}
```

服务端广播 `room.state`，其中包含权威棋盘、当前回合、玩家、胜者与本端棋子。服务端会验证房间状态、回合、坐标、占用、胜负和平局；结算时排行榜自动更新。

排行榜保存到 `data/rankings.json`。此版本适合作业演示；生产环境需要数据库、身份签名、鉴权与 TLS（`wss://`）。
