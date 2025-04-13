#!/bin/bash
# 安装计时器服务

# 检查root权限
if [ "$EUID" -ne 0 ]; then
  echo "请使用root权限: sudo bash install_service.sh"
  exit 1
fi

echo "安装计时器服务..."

# 复制服务文件并设置权限
cp /home/timer_app/timer-app.service /etc/systemd/system/
chmod +x /home/timer_app/cleanup.sh
chmod +x /home/timer_app/jsq

# 创建jsq命令链接
ln -sf /home/timer_app/jsq /usr/local/bin/jsq

# 启用并启动服务
systemctl daemon-reload
systemctl enable timer-app.service
systemctl start timer-app.service

echo "安装完成！"
echo "现在可以使用 'jsq' 命令查看剩余时间，'jsq reset' 重置计时器"
