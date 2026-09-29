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

## 局域网跨端联调

用于 Android 真机与鸿蒙模拟器通过电脑上的本地服务端进行网络对战。

### 1. 准备网络

安卓真机必须能够访问电脑。可以选择以下任一种方式：

- 电脑和安卓真机连接同一个 Wi-Fi。
- 安卓真机开启个人热点，电脑连接该热点。

鸿蒙模拟器运行在电脑上，不需要单独连接 Wi-Fi。测试期间不要让电脑或安卓真机切换到其他网络、VPN 或代理。

### 2. 启动本地服务端

在电脑 PowerShell 中执行：

```powershell
cd "D:\Android\MyProject\OOXX\OOXX\server"
npm install
npm start
```

看到服务端开始监听 `9527` 端口后，保持窗口不要关闭。停止服务使用 `Ctrl+C`。

### 3. 获取电脑局域网 IP

在另一个 PowerShell 窗口执行：

```powershell
ipconfig
```

找到电脑当前 Wi-Fi 适配器的 `IPv4 Address`，例如 `192.168.43.123`。下面将这个地址记为 `<电脑IP>`。

### 4. 修改客户端服务器地址

将 Android 和鸿蒙代码中的服务器地址替换为电脑当前 IP：

```text
http://<电脑IP>:9527/
ws://<电脑IP>:9527/ws
```

Android 主要检查：

- `android/app/build.gradle.kts`
- `android/app/src/main/res/xml/network_security_config.xml`

鸿蒙主要检查：

- `ohos/entry/src/main/ets/match/MatchStore.ets`
- `ohos/entry/src/main/ets/match/WebSocketMatchClient.ets`
- `ohos/entry/src/main/ets/network/DailyClient.ets`

如果电脑更换网络，局域网 IP 可能变化，需要重新修改这些地址。

### 5. 验证手机能访问电脑

用安卓手机浏览器打开：

```text
http://<电脑IP>:9527/health
```

看到类似下面的内容，说明手机已经能够访问电脑服务端：

```json
{"ok":true,"rooms":0}
```

如果打不开，检查服务端是否运行、电脑和手机是否在同一网络，以及 Windows 防火墙是否允许 Node.js 使用专用网络。部分公共 Wi-Fi 会禁止设备之间互访，此时改用手机热点测试。

### 6. 运行两端并测试

1. Android Studio 打开 `android/`，重新构建并安装到安卓真机。
2. DevEco Studio 打开 `ohos/`，重新构建并运行到鸿蒙模拟器。
3. 安卓进入“好友房间 → 网络对战 → 创建房间”。
4. 鸿蒙进入“好友房间 → 网络对战”，输入安卓显示的 6 位房间码并加入。
5. 测试双方轮流落子，确认棋盘、回合、胜负结果在两端保持一致。
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
