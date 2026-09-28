# 鸿蒙端项目架构

## 分层

```text
ArkUI 页面 / 组件
        ↓
Index / GameStore
        ↓
GameEngine / Repository / MatchConnection
        ↓
本地存储 / HTTP / WebSocket / 蓝牙
```

## 目录职责

- `pages/`：页面展示和事件转发。
- `components/`：按钮、导航、模式卡、角色和棋盘组件。
- `store/`：对局流程与页面状态。
- `service/`：胜负、AI、唯一解算法。
- `repository/`：题目、战绩和排行数据接口。
- `match/`：跨端消息与连接抽象。
- `theme/`：颜色、间距、圆角等 Token。

## ArkUI 约束

- `Index.build()` 使用固定 `Column` 根容器，条件页面放在容器内部。
- 自定义属性不使用 `size` 等系统链式属性名。
- 条件棋盘共用外层容器，样式不挂在 `if/else` 上。
- 页面不计算胜负，不直接修改业务棋盘。

## 跨端边界

- 坐标使用从 0 开始的 `row`、`col`。
- 网络棋盘使用长度为 `size × size` 的扁平字符串。
- 客户端只提交操作，服务器快照覆盖客户端状态。
- WebSocket 与蓝牙统一实现 `MatchConnection`。

## 验证状态

- 2026-09-28：DevEco Studio 编译及鸿蒙模拟器运行通过。
