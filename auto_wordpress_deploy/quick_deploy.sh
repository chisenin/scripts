#!/bin/bash

# 通用WordPress一键部署脚本
# 自适应Debian/Ubuntu和Alpine Linux

set -e

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}通用WordPress一键部署${NC}"
echo -e "${BLUE}======================================${NC}"
echo

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "此脚本需要以root权限运行！"
    echo "请使用: sudo ./quick_deploy.sh"
    exit 1
fi

# 检测系统类型
if [[ -f /etc/alpine-release ]]; then
    echo "检测到Alpine Linux系统"
elif [[ -f /etc/debian_version ]]; then
    echo "检测到Debian/Ubuntu系统"
else
    echo "错误：不支持的操作系统"
    echo "此脚本仅支持Debian/Ubuntu和Alpine Linux"
    exit 1
fi

# 检查主脚本是否存在
if [[ ! -f "./auto_wordpress_universal.sh" ]]; then
    echo "错误: auto_wordpress_universal.sh 未找到！"
    echo "请确保两个脚本在同一目录下。"
    exit 1
fi

# 添加执行权限并执行部署
echo "开始部署..."
chmod +x ./auto_wordpress_universal.sh
./auto_wordpress_universal.sh

echo
echo -e "${GREEN}部署完成！${NC}"
echo -e "${BLUE}======================================${NC}"