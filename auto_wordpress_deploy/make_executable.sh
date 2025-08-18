#!/bin/bash

# 通用WordPress脚本权限设置脚本
# 为所有脚本添加执行权限

echo "======================================"
echo "通用WordPress部署脚本权限设置"
echo "======================================"
echo

# 检查当前目录
echo "当前目录: $(pwd)"
echo

# 设置所有脚本的执行权限
SCRIPTS=(
    "auto_wordpress_universal.sh"
    "quick_deploy.sh"
    "check_installation.sh"
    "uninstall.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        chmod +x "$script"
        echo "✅ 已设置执行权限: $script"
    else
        echo "⚠️  文件不存在: $script"
    fi
done

echo
echo "======================================"
echo "设置完成！"
echo
echo "使用方法:"
echo "  一键部署: ./quick_deploy.sh"
echo "  手动部署: ./auto_wordpress_universal.sh"
echo "  检查安装: ./check_installation.sh"
echo "  卸载环境: ./uninstall.sh"
echo "  查看帮助: ./auto_wordpress_universal.sh --help"
echo "======================================"