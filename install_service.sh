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

# 初始化计时器数据（设置为当前时间后12小时）
# 计算12小时后的时间
END_TIME=$(date -d "+12 hours" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null)
if [ $? -ne 0 ]; then
    # 如果上面的命令失败，尝试不同的日期格式
    END_TIME=$(date -v+12H "+%Y-%m-%dT%H:%M:%S" 2>/dev/null)
    if [ $? -ne 0 ]; then
        # 如果仍然失败，使用简单的方法计算
        CURRENT_TIMESTAMP=$(date +%s)
        FUTURE_TIMESTAMP=$((CURRENT_TIMESTAMP + 43200)) # 12小时 = 43200秒
        END_TIME=$(date -d "@$FUTURE_TIMESTAMP" "+%Y-%m-%dT%H:%M:%S" 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S")
    fi
fi
echo "{\"end_time\":\"$END_TIME\"}" > "$SCRIPT_DIR/timer_data.json"
echo "计时器已初始化，到期时间: $END_TIME"

# 创建jsq命令链接
ln -sf "$SCRIPT_DIR/jsq" /usr/local/bin/jsq

# 启用并启动服务
systemctl daemon-reload
systemctl enable timer-app.service
systemctl start timer-app.service

echo "安装完成！"
echo "现在可以使用 'jsq' 命令查看剩余时间，'jsq reset' 重置计时器"
