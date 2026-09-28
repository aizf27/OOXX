# 鸿蒙与 Android 对齐

## 基线

- Android 参考：`aizf27/OOXX`，`main@1406e32`，检查日期 2026-09-23。
- Android 当前技术：Kotlin + Jetpack Compose；不是 XML。
- 鸿蒙：ArkTS + ArkUI。
- 两端统一业务和交互结果，不要求控件实现一致。

## UI

页面顺序：

```text
启动 → 引导 → 首页 → 模式/好友房 → 对局 → 结算
                    ↓
                战绩 / 我的
```

统一视觉 Token：

```text
Paper #FFFCF3   Ink #292827   Coral #FF765E
Teal  #45BFC2   Sunny #FFD657 Sky   #66BDF1
SoftGray #F0EEE8
```

- 手绘、轻松、卡片化；竖屏优先。
- 首页四入口：快速对战、双人同屏、好友房间、每日挑战。
- 底栏：首页、战绩、我的。
- 对局页统一显示双方、比分/回合、棋盘、悔棋/认输等操作。

## 业务枚举

```text
Mark: EMPTY、X、O
GameKind: AI_3X3、AI_5X5、LOCAL、DAILY、NETWORK、BLUETOOTH
MatchResult: WIN、LOSS、DRAW
RoomStatus: WAITING、PLAYING、FINISHED
```

棋盘索引统一从 `0` 开始，网络坐标使用 `row`、`col`。

## 算法

- 3×3：Alpha-Beta Minimax。
- 5×5：连续 4 个获胜，使用一致的棋形评分方向。
- 唯一解：最高分候选必须只有一个。
- 网络题：两端本地复算；答案不一致则拒绝题目。

## 数据与积分

- 网络接口和消息见 `WEBSOCKET_PROTOCOL.md`。
- 游客身份格式建议 `guest-<uuid>`，不要求用户名密码。
- 战绩字段：`result、mode、opponent、playedAt、steps`。
- 积分：胜 30、平 10、负 2。

## 当前差异与处理

1. 旧鸿蒙文档的 6×6 逻辑填格已废弃，改为与作业/Android 一致的井字棋。
2. Android 已有 Compose、HTTP、WebSocket、蓝牙骨架；鸿蒙按相同边界实现。
3. Android 服务端当前仅两名玩家对战，多人先解释为“玩家 + 观战者”；真正多人玩法需另开规则。
4. 当前 WS 无版本号；联调前两端和服务端一起升级，不单端私改。

## Android 基线已发现的问题

- `/games/daily`：Android 客户端和 README 要求 `board` 为扁平字符串；服务端当前返回二维数组。统一改为字符串，例如 `"XO..X.O.."`。
- 好友房页面目前只更新提示文字，尚未把 `WebSocketMatchClient`/蓝牙连接接入 ViewModel 和真实对局。
- 页面文案写“TCP 房间”，实际实现是标准 WebSocket，应统一写 WebSocket。
- 因此鸿蒙只对齐 UI、规则和协议，不把 Android 的占位交互当作已完成能力。
