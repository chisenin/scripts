#!/bin/bash

# WordPress完整卸载脚本（通用版本）
# 支持Debian/Ubuntu和Alpine系统

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检测系统类型
detect_system() {
    if [ -f /etc/alpine-release ]; then
        SYSTEM_TYPE="alpine"
        PACKAGE_MANAGER="apk"
        SERVICE_CMD="rc-service"
        SERVICE_ENABLE_CMD="rc-update"
        WEB_USER="nginx"
        WEB_GROUP="nginx"
        PHP_SERVICE_PREFIX="php"
        PHP_SERVICE_SUFFIX="-fpm"
        MYSQL_SERVICE="mariadb"
        MYSQL_PACKAGE="mariadb"
        MYSQL_CLIENT_PACKAGE="mariadb-client"
        REDIS_PACKAGE="redis"
    elif [ -f /etc/debian_version ]; then
        SYSTEM_TYPE="debian"
        PACKAGE_MANAGER="apt"
        SERVICE_CMD="systemctl"
        SERVICE_ENABLE_CMD="systemctl"
        WEB_USER="www-data"
        WEB_GROUP="www-data"
        PHP_SERVICE_PREFIX="php"
        PHP_SERVICE_SUFFIX="-fpm"
        MYSQL_SERVICE="mysql"
        MYSQL_PACKAGE="mariadb-server"
        MYSQL_CLIENT_PACKAGE="mariadb-client"
        REDIS_PACKAGE="redis-server"
    else
        echo -e "${RED}错误：不支持的操作系统${NC}"
        exit 1
    fi
}

# 显示欢迎信息
show_welcome() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  WordPress完全卸载工具（通用版本）${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo -e "${RED}⚠️  警告：此操作将完全删除WordPress及相关服务${NC}"
    echo -e "${YELLOW}系统将：${NC}"
    echo "  • 停止所有相关服务"
    echo "  • 删除WordPress文件和数据库"
    echo "  • 卸载Nginx、PHP、MariaDB、Redis"
    echo "  • 清理配置文件"
    echo ""
}

# 确认卸载
confirm_uninstall() {
    echo -e "${YELLOW}请输入以下文字确认卸载：${NC}"
    echo -e "${GREEN}YES-I-WANT-TO-UNINSTALL${NC}"
    echo ""
    read -p "确认: " confirmation
    
    if [ "$confirmation" != "YES-I-WANT-TO-UNINSTALL" ]; then
        echo -e "${YELLOW}卸载已取消${NC}"
        exit 0
    fi
}

# 停止服务
stop_services() {
    echo -e "${YELLOW}正在停止服务...${NC}"
    
    if [ "$SYSTEM_TYPE" = "alpine" ]; then
        # Alpine系统
        rc-service nginx stop 2>/dev/null || true
        rc-service mariadb stop 2>/dev/null || true
        rc-service redis stop 2>/dev/null || true
        
        # 停止所有PHP-FPM服务
        for php_service in php82-fpm php81-fpm php80-fpm php74-fpm; do
            rc-service "$php_service" stop 2>/dev/null || true
        done
        
        # 禁用开机启动
        rc-update del nginx default 2>/dev/null || true
        rc-update del mariadb default 2>/dev/null || true
        rc-update del redis default 2>/dev/null || true
        
        for php_service in php82-fpm php81-fpm php80-fpm php74-fpm; do
            rc-update del "$php_service" default 2>/dev/null || true
        done
    else
        # Debian/Ubuntu系统
        systemctl stop nginx 2>/dev/null || true
        systemctl stop mysql 2>/dev/null || true
        systemctl stop redis-server 2>/dev/null || true
        
        # 停止所有PHP-FPM服务
        for php_service in php8.2-fpm php8.1-fpm php8.0-fpm php7.4-fpm; do
            systemctl stop "$php_service" 2>/dev/null || true
        done
        
        # 禁用开机启动
        systemctl disable nginx 2>/dev/null || true
        systemctl disable mysql 2>/dev/null || true
        systemctl disable redis-server 2>/dev/null || true
        
        for php_service in php8.2-fpm php8.1-fpm php8.0-fpm php7.4-fpm; do
            systemctl disable "$php_service" 2>/dev/null || true
        done
    fi
    
    echo -e "${GREEN}✅ 所有服务已停止${NC}"
}

# 删除WordPress文件
delete_wordpress() {
    echo -e "${YELLOW}正在删除WordPress文件...${NC}"
    
    # 删除WordPress目录
    rm -rf /var/www/wordpress
    rm -rf /var/www/html
    
    # 删除Nginx配置
    rm -f /etc/nginx/sites-available/wordpress
    rm -f /etc/nginx/sites-enabled/wordpress
    rm -f /etc/nginx/conf.d/wordpress.conf
    
    # 删除PHP配置
    rm -f /etc/php/*/fpm/pool.d/wordpress.conf
    
    # 删除MariaDB配置
    rm -f /etc/mysql/mariadb.conf.d/99-wordpress.cnf
    rm -f /etc/my.cnf.d/99-wordpress.cnf
    
    # 删除Redis配置
    rm -f /etc/redis/conf.d/wordpress.conf
    
    echo -e "${GREEN}✅ WordPress文件已删除${NC}"
}

# 删除数据库
delete_database() {
    echo -e "${YELLOW}正在删除数据库...${NC}"
    
    # 尝试从配置文件获取密码
    local db_root_password=""
    if [ -f /root/.wp_universal_config ]; then
        source /root/.wp_universal_config
        db_root_password="$DB_ROOT_PASSWORD"
    else
        # 尝试默认密码
        db_root_password="$(cat /root/.mysql_root_password 2>/dev/null || echo "")"
    fi
    
    if [ -n "$db_root_password" ]; then
        # 删除数据库和用户
        mysql -u root -p"$db_root_password" -e "DROP DATABASE IF EXISTS wordpress; DROP USER IF EXISTS 'wordpress'@'localhost'; FLUSH PRIVILEGES;" 2>/dev/null || true
    else
        echo -e "${YELLOW}⚠️  无法获取数据库密码，请手动删除数据库${NC}"
    fi
    
    echo -e "${GREEN}✅ 数据库已删除${NC}"
}

# 卸载软件包
uninstall_packages() {
    echo -e "${YELLOW}正在卸载软件包...${NC}"
    
    if [ "$SYSTEM_TYPE" = "alpine" ]; then
        # Alpine系统卸载
        apk del nginx mariadb mariadb-client redis php82-fpm php82-mysqlnd php82-gd php82-curl php82-mbstring php82-xml php82-zip php82-redis 2>/dev/null || true
        apk del php81-fpm php81-mysqlnd php81-gd php81-curl php81-mbstring php81-xml php81-zip php81-redis 2>/dev/null || true
        apk del php80-fpm php80-mysqlnd php80-gd php80-curl php80-mbstring php80-xml php80-zip php80-redis 2>/dev/null || true
    else
        # Debian/Ubuntu系统卸载
        apt-get remove --purge -y nginx* mariadb-* redis* php* 2>/dev/null || true
        apt-get autoremove -y 2>/dev/null || true
        apt-get autoclean 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ 软件包已卸载${NC}"
}

# 清理配置文件
cleanup_config() {
    echo -e "${YELLOW}正在清理配置文件...${NC}"
    
    # 删除配置文件
    rm -f /root/.wp_universal_config
    rm -f /root/.mysql_root_password
    rm -f /root/.wp_admin_password
    rm -f /root/.redis_password
    
    # 删除日志文件
    rm -rf /var/log/wp_deploy
    
    # 删除备份
    rm -rf /var/backups/wordpress
    
    # 删除定时任务
    crontab -l 2>/dev/null | grep -v "wp_backup" | crontab -
    
    echo -e "${GREEN}✅ 配置文件已清理${NC}"
}

# 显示卸载完成信息
show_completion() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  卸载完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}已删除的内容：${NC}"
    echo "  • WordPress文件和数据库"
    echo "  • Nginx、PHP、MariaDB、Redis"
    echo "  • 所有配置文件"
    echo "  • 备份和日志文件"
    echo ""
    echo -e "${YELLOW}如需重新安装，请运行：${NC}"
    echo "  ./auto_wordpress_universal.sh"
    echo ""
}

# 主卸载流程
main() {
    # 检测系统
    detect_system
    
    # 显示欢迎信息
    show_welcome
    
    # 确认卸载
    confirm_uninstall
    
    # 执行卸载步骤
    stop_services
    delete_wordpress
    delete_database
    uninstall_packages
    cleanup_config
    
    # 显示完成信息
    show_completion
}

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误：请使用root权限运行此脚本${NC}"
    echo "请使用: sudo $0"
    exit 1
fi

# 运行主程序
main "$@"