#!/bin/bash

# WordPress安装状态检查脚本（通用版本）
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
        SERVICE_CMD="rc-service"
        PHP_SERVICE_PREFIX="php"
        PHP_SERVICE_SUFFIX="-fpm"
        MYSQL_SERVICE="mariadb"
        WEB_USER="nginx"
        WEB_GROUP="nginx"
    elif [ -f /etc/debian_version ]; then
        SYSTEM_TYPE="debian"
        SERVICE_CMD="systemctl"
        PHP_SERVICE_PREFIX="php"
        PHP_SERVICE_SUFFIX="-fpm"
        MYSQL_SERVICE="mysql"
        WEB_USER="www-data"
        WEB_GROUP="www-data"
    else
        echo -e "${RED}错误：不支持的操作系统${NC}"
        exit 1
    fi
}

# 检查服务状态
check_service() {
    local service_name=$1
    local service_display=$2
    
    if [ "$SYSTEM_TYPE" = "alpine" ]; then
        if rc-service "$service_name" status >/dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_display 运行正常${NC}"
            return 0
        else
            echo -e "${RED}❌ $service_display 未运行${NC}"
            return 1
        fi
    else
        if systemctl is-active --quiet "$service_name"; then
            echo -e "${GREEN}✅ $service_display 运行正常${NC}"
            return 0
        else
            echo -e "${RED}❌ $service_display 未运行${NC}"
            return 1
        fi
    fi
}

# 检查端口
check_port() {
    local port=$1
    local service=$2
    
    if netstat -tulnp | grep -q ":$port " || ss -tulnp | grep -q ":$port " ; then
        echo -e "${GREEN}✅ 端口 $port ($service) 已监听${NC}"
        return 0
    else
        echo -e "${RED}❌ 端口 $port ($service) 未监听${NC}"
        return 1
    fi
}

# 检查文件权限
check_permissions() {
    local file=$1
    local expected_user=$2
    local expected_group=$3
    
    if [ -e "$file" ]; then
        local actual_user=$(stat -c "%U" "$file")
        local actual_group=$(stat -c "%G" "$file")
        
        if [ "$actual_user" = "$expected_user" ] && [ "$actual_group" = "$expected_group" ]; then
            echo -e "${GREEN}✅ $file 权限正确 ($expected_user:$expected_group)${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  $file 权限异常 ($actual_user:$actual_group)${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ $file 不存在${NC}"
        return 1
    fi
}

# 检查数据库连接
check_database() {
    local db_name="wordpress"
    local db_user="wordpress"
    
    # 尝试从配置文件获取密码
    if [ -f /root/.wp_universal_config ]; then
        source /root/.wp_universal_config
        DB_PASSWORD="$WORDPRESS_DB_PASSWORD"
    else
        echo -e "${YELLOW}⚠️  配置文件未找到，使用默认密码${NC}"
        DB_PASSWORD="wordpress"
    fi
    
    if mysql -u"$db_user" -p"$DB_PASSWORD" -e "USE $db_name; SELECT 1;" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 数据库连接正常${NC}"
        return 0
    else
        echo -e "${RED}❌ 数据库连接失败${NC}"
        return 1
    fi
}

# 检查WordPress站点
check_wordpress() {
    local url="http://localhost"
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
        echo -e "${GREEN}✅ WordPress站点可访问${NC}"
        
        # 检查WordPress版本
        local wp_version=$(curl -s "$url/wp-includes/version.php" | grep "\$wp_version" | cut -d"'" -f2)
        if [ -n "$wp_version" ]; then
            echo -e "${GREEN}✅ WordPress版本: $wp_version${NC}"
        fi
        
        return 0
    else
        echo -e "${RED}❌ WordPress站点无法访问${NC}"
        return 1
    fi
}

# 检查磁盘空间
check_disk_space() {
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$usage" -lt 80 ]; then
        echo -e "${GREEN}✅ 磁盘空间充足 ($usage% 已使用)${NC}"
    elif [ "$usage" -lt 90 ]; then
        echo -e "${YELLOW}⚠️  磁盘空间紧张 ($usage% 已使用)${NC}"
    else
        echo -e "${RED}❌ 磁盘空间不足 ($usage% 已使用)${NC}"
    fi
}

# 检查内存使用
check_memory() {
    local usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    
    if [ "$usage" -lt 80 ]; then
        echo -e "${GREEN}✅ 内存使用正常 ($usage% 已使用)${NC}"
    elif [ "$usage" -lt 90 ]; then
        echo -e "${YELLOW}⚠️  内存使用较高 ($usage% 已使用)${NC}"
    else
        echo -e "${RED}❌ 内存使用过高 ($usage% 已使用)${NC}"
    fi
}

# 显示系统信息
show_system_info() {
    echo -e "${YELLOW}=== 系统信息 ===${NC}"
    echo "操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "内核版本: $(uname -r)"
    echo "架构: $(uname -m)"
    echo "内存: $(free -h | awk 'NR==2{print $2}')"
    echo "磁盘: $(df -h / | awk 'NR==2{print $2}')"
    echo ""
}

# 显示配置信息
show_config_info() {
    echo -e "${YELLOW}=== 配置信息 ===${NC}"
    
    if [ -f /root/.wp_universal_config ]; then
        source /root/.wp_universal_config
        echo "系统类型: $SYSTEM_TYPE"
        echo "WordPress管理员: $WORDPRESS_ADMIN"
        echo "WordPress管理员密码: $WORDPRESS_ADMIN_PASSWORD"
        echo "数据库用户: $WORDPRESS_DB_USER"
        echo "数据库密码: $WORDPRESS_DB_PASSWORD"
    else
        echo -e "${YELLOW}配置文件未找到，使用默认配置${NC}"
    fi
    
    echo ""
}

# 主检查函数
main() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  WordPress安装状态检查（通用版本）${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    
    # 检测系统
    detect_system
    echo -e "${GREEN}检测到系统: $SYSTEM_TYPE${NC}"
    echo ""
    
    # 显示系统信息
    show_system_info
    
    # 显示配置信息
    show_config_info
    
    # 检查服务
    echo -e "${YELLOW}=== 服务状态检查 ===${NC}"
    
    # 根据系统类型检查对应的服务
    if [ "$SYSTEM_TYPE" = "alpine" ]; then
        check_service "nginx" "Nginx"
        check_service "mariadb" "MariaDB"
        check_service "redis" "Redis"
        
        # 检测PHP版本
        for php_version in 82 81 80 7.4; do
            if [ -f "/etc/init.d/php${php_version}-fpm" ]; then
                check_service "php${php_version}-fpm" "PHP-FPM ${php_version}"
                break
            fi
        done
    else
        check_service "nginx" "Nginx"
        check_service "mysql" "MySQL/MariaDB"
        check_service "redis-server" "Redis"
        
        # 检测PHP版本
        for php_version in 8.2 8.1 8.0 7.4; do
            if systemctl list-unit-files | grep -q "php${php_version}-fpm.service"; then
                check_service "php${php_version}-fpm" "PHP-FPM ${php_version}"
                break
            fi
        done
    fi
    
    echo ""
    
    # 检查端口
    echo -e "${YELLOW}=== 端口检查 ===${NC}"
    check_port 80 "HTTP"
    check_port 3306 "MySQL"
    check_port 6379 "Redis"
    check_port 9000 "PHP-FPM"
    echo ""
    
    # 检查文件权限
    echo -e "${YELLOW}=== 文件权限检查 ===${NC}"
    check_permissions "/var/www/wordpress" "$WEB_USER" "$WEB_GROUP"
    check_permissions "/var/www/wordpress/wp-content" "$WEB_USER" "$WEB_GROUP"
    check_permissions "/var/www/wordpress/wp-config.php" "$WEB_USER" "$WEB_GROUP"
    echo ""
    
    # 检查数据库连接
    echo -e "${YELLOW}=== 数据库检查 ===${NC}"
    check_database
    echo ""
    
    # 检查WordPress站点
    echo -e "${YELLOW}=== WordPress站点检查 ===${NC}"
    check_wordpress
    echo ""
    
    # 检查系统资源
    echo -e "${YELLOW}=== 系统资源检查 ===${NC}"
    check_disk_space
    check_memory
    echo ""
    
    # 总结
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  检查完成！${NC}"
    echo -e "${YELLOW}========================================${NC}"
    
    echo -e "${YELLOW}如需重新检查，请运行：${NC}"
    echo "  ./check_installation.sh"
    echo ""
    
    echo -e "${YELLOW}如需重新部署，请运行：${NC}"
    echo "  ./auto_wordpress_universal.sh --reinstall"
}

# 检查依赖
if ! command -v netstat &> /dev/null && ! command -v ss &> /dev/null; then
    echo -e "${YELLOW}安装网络工具...${NC}"
    if [ "$SYSTEM_TYPE" = "alpine" ]; then
        apk add net-tools
    else
        apt install -y net-tools
    fi
fi

# 运行主程序
main