#!/usr/bin/env bash
# OOXX 对战服务器一键部署脚本（阿里云 ECS / Ubuntu 22.04）
#
# 用法:
#   ./deploy.sh [host] [user]
#   ./deploy.sh                      # 默认 root@47.243.15.216
#   ./deploy.sh 47.243.15.216 root
#
# 建议先执行一次 `ssh-copy-id root@<host>` 配置免密，
# 否则下面 scp / ssh 各会提示输入一次密码。
set -euo pipefail

HOST="${1:-47.243.15.216}"
USER="${2:-root}"
SSH_TARGET="${USER}@${HOST}"
REMOTE_DIR="/opt/ooxx-server"
NODE_MAJOR=20

cd "$(dirname "$0")"

echo "==> [1/4] 打包服务端源码（排除 node_modules/data/test）"
TARBALL="$(mktemp -d)/ooxx-server.tar.gz"
tar --exclude='node_modules' --exclude='data' --exclude='test' \
    -czf "$TARBALL" src package.json package-lock.json

echo "==> [2/4] 上传到 ${SSH_TARGET}:${REMOTE_DIR}"
ssh "$SSH_TARGET" "mkdir -p ${REMOTE_DIR}"
scp -q "$TARBALL" "$SSH_TARGET:/tmp/ooxx-server.tar.gz"

echo "==> [3/4] 远程安装 Node ${NODE_MAJOR} 并以 systemd 启动服务"
ssh "$SSH_TARGET" bash -s <<REMOTE
set -euo pipefail

# 安装 Node.js（apt 自带的 12 缺 crypto.randomUUID，必须用 NodeSource）
if ! command -v node >/dev/null 2>&1 || [ "\$(node -v | sed 's/v\([0-9]*\).*/\1/')" -lt ${NODE_MAJOR} ]; then
  echo "---- 安装 Node.js ${NODE_MAJOR}.x ----"
  curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash -
  apt-get install -y nodejs
fi
node -v

echo "---- 解压并安装依赖 ----"
cd ${REMOTE_DIR}
tar -xzf /tmp/ooxx-server.tar.gz
rm -f /tmp/ooxx-server.tar.gz
npm install --omit=dev

echo "---- 写入 systemd 服务 ----"
cat > /etc/systemd/system/ooxx-server.service <<UNIT
[Unit]
Description=OOXX WebSocket game server
After=network.target

[Service]
Type=simple
WorkingDirectory=${REMOTE_DIR}
ExecStart=/usr/bin/node src/index.js
Restart=always
RestartSec=3
Environment=PORT=9527
Environment=HOST=0.0.0.0
# 2G 内存小实例，限制堆防 OOM
Environment=NODE_OPTIONS=--max-old-space-size=512

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable ooxx-server
systemctl restart ooxx-server
sleep 1

echo "---- 服务状态 ----"
systemctl --no-pager -l status ooxx-server | head -8

echo "---- 本机健康检查 ----"
curl -sf http://127.0.0.1:9527/health && echo " <- health OK"
REMOTE

echo "==> [4/4] 完成"
echo "    WS 地址:   ws://${HOST}:9527/ws"
echo "    HTTP 地址: http://${HOST}:9527/"
echo "    查看日志:  ssh ${SSH_TARGET} journalctl -u ooxx-server -f"
echo ""
echo "注意：若公网访问不通，请到阿里云控制台检查安全组是否放行 TCP 9527。"
