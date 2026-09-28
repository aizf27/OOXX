# OOXX 康思小游戏（Android）

基于作业原型实现的 Android 原生 Jetpack Compose 应用。项目提供完整的 OOXX（井字棋）体验，并将算法求解、唯一解校验、网络题库、排行榜、网络房间及蓝牙对战入口纳入同一应用。

## 已实现功能

- 原型对应页面：启动、引导、首页、模式选择、好友房、对局、结算、战绩、我的。
- 经典 `3×3`：Alpha-Beta Minimax 精确求解；AI 不会漏掉最优着。
- 进阶 `5×5`：四子连线规则，使用棋形评分 AI。
- 每日挑战：优先请求网络题库，本地重新计算最佳着；仅在**唯一最高分着**成立且服务端答案一致时接受题目。网络不可用时使用本地生成且已校验的唯一解题目。
- 本地对局战绩、胜率和积分排行榜，使用 SharedPreferences 持久化。
- 网络对战：提供 TCP 房间协议客户端；蓝牙对战：提供 RFCOMM 主机/连接通道及 Android 12+ 运行时权限请求。
- 小程序游客式身份：不要求用户名或密码。

## 运行

使用 Android Studio 打开本目录，等待 Gradle 同步后运行 `app` 模块；最低 Android 8.0（API 26）。

也可使用命令行：

```bash
./gradlew testDebugUnitTest
./gradlew assembleDebug
```

## 网络接口约定

在 `app/build.gradle.kts` 中替换以下 BuildConfig 参数：

```kotlin
GAME_API_BASE_URL = "http://192.168.1.23:9527/"
MATCH_WS_URL = "ws://192.168.1.23:9527/ws"
```

每日题库接口为 `GET /games/daily`，返回示例：

```json
{
  "size": 3,
  "winLength": 3,
  "board": "XO..X.O..",
  "next": "X",
  "answer": { "row": 2, "col": 2 }
}
```

客户端会拒绝无唯一解、答案与本地解不一致、或棋盘格式非法的题目。房间对战使用标准 WebSocket JSON 协议，服务端实现位于 `server/`；启动和消息格式见 `server/README.md`。

## 关键源码

- `app/src/main/java/com/kangsi/ooxx/game/GameEngine.kt`：规则、胜负判定、Minimax、唯一解生成。
- `app/src/main/java/com/kangsi/ooxx/data/GameRepository.kt`：网络题库校验、本地战绩和排行榜。
- `app/src/main/java/com/kangsi/ooxx/match/MatchTransport.kt`：标准 WebSocket 与 Bluetooth RFCOMM 传输通道。
- `app/src/main/java/com/kangsi/ooxx/ui/OoxxApp.kt`：Compose 原型页面和交互。

## 验证

`GameEngineTest` 覆盖行/列/对角线胜负、AI 必胜着、无唯一解拒绝，以及多组随机唯一解题目校验。
