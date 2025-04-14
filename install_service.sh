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

# 复制服务文件并设置权限
cp "$SCRIPT_DIR/timer-app.service" /etc/systemd/system/
chmod +x "$SCRIPT_DIR/cleanup.sh"
chmod +x "$SCRIPT_DIR/jsq"

# 更新服务文件中的路径
sed -i "s|/home/timer_app|$SCRIPT_DIR|g" /etc/systemd/system/timer-app.service

# 创建jsq命令链接
ln -sf "$SCRIPT_DIR/jsq" /usr/local/bin/jsq

# 启用并启动服务
systemctl daemon-reload
systemctl enable timer-app.service
systemctl start timer-app.service

echo "安装完成！"
echo "现在可以使用 'jsq' 命令查看剩余时间，'jsq reset' 重置计时器"
