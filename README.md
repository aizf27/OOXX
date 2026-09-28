# OOXX 跨端项目

鸿蒙、Android 与 Node.js 服务端统一仓库。客户端规则保持一致，网络对局以服务端状态为最终结果。

## 目录

| 目录 | 内容 |
| --- | --- |
| `android/` | Kotlin + Jetpack Compose 客户端 |
| `ohos/` | ArkTS + ArkUI 客户端 |
| `server/` | Node.js HTTP/WebSocket 服务端 |
| `design/` | UI 原型与视觉资料 |
| docs/ | 跨端规则、协议与协作约定 |
| contracts/ | Android、鸿蒙与服务端共用的机器可读契约 |

## 打开与运行

- Android：使用 Android Studio 打开 `android/`。
- 鸿蒙：使用 DevEco Studio 打开 `ohos/`。
- 服务端：进入 `server/`，执行 `npm install` 后运行 `npm start`。

## 公共约定

- 棋盘坐标从 `0` 开始，字段使用 `row`、`col`。
- Android 与鸿蒙不得各自修改公共规则和网络字段。
- 客户端只提交操作，服务器校验并广播权威状态。
- 公共规则见 `docs/GAME_RULES.md`，网络消息见 `docs/WEBSOCKET_PROTOCOL.md`。

## 代码边界

- Android 主要修改 `android/**`。
- 鸿蒙主要修改 `ohos/**`。
- 服务端主要修改 `server/**`。
- `docs/**` 和根目录文件由双方确认后修改。
