#!/bin/bash
# 安装计时器服务

# 检查root权限
if [ "$EUID" -ne 0 ]; then
  echo "请使用root权限: sudo bash install_service.sh"
  exit 1
fi

echo "安装计时器服务..."

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "检测到安装目录: $SCRIPT_DIR"

# 直接修改服务文件内容
cat > /etc/systemd/system/timer-app.service << EOF
[Unit]
Description=计时器应用服务
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$SCRIPT_DIR
ExecStart=/bin/bash -c "while true; do $SCRIPT_DIR/jsq > /dev/null; sleep 60; done"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 设置权限
chmod +x "$SCRIPT_DIR/cleanup.sh"
chmod +x "$SCRIPT_DIR/jsq"

# 确保数据文件存在并设置正确的权限
touch "$SCRIPT_DIR/timer_data.json"
chmod 666 "$SCRIPT_DIR/timer_data.json"

# 创建jsq命令链接
ln -sf "$SCRIPT_DIR/jsq" /usr/local/bin/jsq

# 启用并启动服务
systemctl daemon-reload
systemctl enable timer-app.service
systemctl start timer-app.service

echo "安装完成！"
echo "现在可以使用 'jsq' 命令查看剩余时间，'jsq reset' 重置计时器"
