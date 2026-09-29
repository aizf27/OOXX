# Monorepo 协作约定

## 分支

- 稳定代码进入 `main`。
- 功能开发从最新 `main` 创建分支。
- 禁止强推 `main`，通过 PR 合并。

## 提交

- 每个小功能单独提交，提交说明使用中文。
- 不提交 IDE 配置、依赖目录和构建产物。
- 跨端字段变化先更新公共文档，再同步两端与服务端。

## 联调顺序

1. 服务端确定请求、响应和错误码。
2. Android 与鸿蒙分别实现相同协议。
3. 先验证本地规则，再验证 WebSocket 房间流程。
4. 服务端快照覆盖客户端临时状态。

## 目录责任

| 范围 | 主要负责人 |
| --- | --- |
| `android/**` | Android 开发 |
| `ohos/**` | 鸿蒙开发 |
| `server/**` | 服务端开发 |
| `docs/**` | 双方共同确认 |

## 契约修改流程

1. 修改根目录 `contracts/*.json`；棋盘、题目和 WebSocket 消息分别维护在对应版本契约中。
2. 执行 `node tools/sync-contract-fixtures.mjs` 校验契约并同步鸿蒙夹具。
3. 分别运行 Android、鸿蒙和服务端契约测试。
4. 执行 `node tools/sync-contract-fixtures.mjs --check` 确认生成文件没有漂移。

`ohos/entry/src/test/fixtures/ContractFixtures.ets` 是生成文件，禁止手工修改。Android 与服务端直接读取根目录 JSON，鸿蒙测试只读取生成后的 ArkTS 常量。
