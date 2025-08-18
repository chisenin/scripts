#!/bin/bash

# =============================================================================
# 通用WordPress自动化部署脚本
# 自适应Debian/Ubuntu和Alpine Linux
# 适用于PVE LXC容器
# =============================================================================

set -e
set -u

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 脚本目录和配置文件
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/.wp_universal_config"
LOG_DIR="/var/log/wp_deploy"
LOG_FILE="$LOG_DIR/auto_deploy_universal.log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# =============================================================================
# 日志函数
# =============================================================================
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# 系统检测函数
# =============================================================================

detect_system() {
    if [[ -f /etc/alpine-release ]]; then
        OS_NAME="alpine"
        OS_VERSION=$(cat /etc/alpine-release)
        PACKAGE_MANAGER="apk"
        SERVICE_MANAGER="rc-service"
        PHP_VERSION_CMD="82"
        print_status "检测到Alpine Linux: $OS_VERSION"
    elif [[ -f /etc/debian_version ]]; then
        OS_NAME="debian"
        OS_VERSION=$(cat /etc/debian_version)
        PACKAGE_MANAGER="apt"
        SERVICE_MANAGER="systemctl"
        PHP_VERSION_CMD="8.2"
        print_status "检测到Debian/Ubuntu: $OS_VERSION"
    else
        print_error "不支持的操作系统！此脚本仅支持Debian/Ubuntu和Alpine Linux"
        exit 1
    fi
}

# =============================================================================
# 系统特定函数
# =============================================================================

# 包管理器包装函数
install_packages() {
    local packages="$*"
    case "$OS_NAME" in
        "alpine")
            apk add --no-cache $packages
            ;;
        "debian")
            apt-get update
            apt-get install -y $packages
            ;;
    esac
}

# 服务管理包装函数
start_service() {
    local service="$1"
    case "$OS_NAME" in
        "alpine")
            rc-service "$service" start
            rc-update add "$service" default
            ;;
        "debian")
            systemctl start "$service"
            systemctl enable "$service"
            ;;
    esac
}

restart_service() {
    local service="$1"
    case "$OS_NAME" in
        "alpine")
            rc-service "$service" restart
            ;;
        "debian")
            systemctl restart "$service"
            ;;
    esac
}

# 获取PHP版本字符串
get_php_version() {
    case "$OS_NAME" in
        "alpine")
            echo "php${PHP_VERSION_CMD}"
            ;;
        "debian")
            echo "php${PHP_VERSION_CMD}"
            ;;
    esac
}

# 获取PHP配置文件路径
get_php_ini_path() {
    case "$OS_NAME" in
        "alpine")
            echo "/etc/php${PHP_VERSION_CMD}/php.ini"
            ;;
        "debian")
            echo "/etc/php/${PHP_VERSION_CMD}/fpm/php.ini"
            ;;
    esac
}

get_php_fpm_path() {
    case "$OS_NAME" in
        "alpine")
            echo "/etc/php${PHP_VERSION_CMD}/php-fpm.d/www.conf"
            ;;
        "debian")
            echo "/etc/php/${PHP_VERSION_CMD}/fpm/pool.d/www.conf"
            ;;
    esac
}

# 获取PHP-FPM服务名
get_php_fpm_service() {
    case "$OS_NAME" in
        "alpine")
            echo "php${PHP_VERSION_CMD}-fpm"
            ;;
        "debian")
            echo "php${PHP_VERSION_CMD}-fpm"
            ;;
    esac
}

# =============================================================================
# 配置管理函数
# =============================================================================

generate_password() {
    local length=${1:-16}
    tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c "$length"
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
# 通用WordPress部署配置文件
OS_NAME="$OS_NAME"
DOMAIN="$DOMAIN"
PHP_VERSION_CMD="$PHP_VERSION_CMD"
NGINX_PORT="$NGINX_PORT"
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_PASSWORD="$DB_PASSWORD"
DB_ROOT_PASSWORD="$DB_ROOT_PASSWORD"
WP_PATH="$WP_PATH"
WP_ADMIN_USER="$WP_ADMIN_USER"
WP_ADMIN_PASSWORD="$WP_ADMIN_PASSWORD"
WP_ADMIN_EMAIL="$WP_ADMIN_EMAIL"
REDIS_PASSWORD="$REDIS_PASSWORD"
EOF
    chmod 600 "$CONFIG_FILE"
}

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        print_status "检测到现有配置文件，正在加载..."
        source "$CONFIG_FILE"
        
        # 验证OS一致性
        local current_os
        if [[ -f /etc/alpine-release ]]; then
            current_os="alpine"
        elif [[ -f /etc/debian_version ]]; then
            current_os="debian"
        fi
        
        if [[ "$OS_NAME" != "$current_os" ]]; then
            print_warning "配置文件中的系统($OS_NAME)与当前系统($current_os)不匹配"
            return 1
        fi
        
        return 0
    fi
    return 1
}

# =============================================================================
# 系统检查
# =============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此脚本需要以root权限运行！"
        echo "请使用: sudo $0"
        exit 1
    fi
}

test_network() {
    print_status "测试网络连接..."
    
    if ping -c 1 8.8.8.8 &>/dev/null; then
        print_status "网络连接正常"
        return 0
    else
        print_error "网络连接失败，请检查网络配置"
        exit 1
    fi
}

# =============================================================================
# 依赖安装
# =============================================================================

install_dependencies() {
    print_status "安装系统依赖..."
    
    case "$OS_NAME" in
        "alpine")
            install_packages curl wget bash openssl ca-certificates
            ;;
        "debian")
            apt-get update
            apt-get install -y curl wget gnupg2 software-properties-common
            ;;
    esac
    
    print_success "基础依赖安装完成"
}

install_services() {
    print_status "安装核心服务..."
    
    case "$OS_NAME" in
        "alpine")
            install_packages nginx mariadb mariadb-client redis unzip tar
            install_packages php${PHP_VERSION_CMD} php${PHP_VERSION_CMD}-fpm php${PHP_VERSION_CMD}-mysqli
            install_packages php${PHP_VERSION_CMD}-curl php${PHP_VERSION_CMD}-gd php${PHP_VERSION_CMD}-mbstring
            install_packages php${PHP_VERSION_CMD}-xml php${PHP_VERSION_CMD}-zip php${PHP_VERSION_CMD}-opcache
            install_packages php${PHP_VERSION_CMD}-redis
            ;;
        "debian")
            # 添加PHP源（Ubuntu/Debian）
            if ! command -v php &>/dev/null; then
                add-apt-repository ppa:ondrej/php -y || true
                apt-get update
            fi
            
            install_packages nginx mariadb-server mariadb-client redis-server
            install_packages php${PHP_VERSION_CMD} php${PHP_VERSION_CMD}-fpm php${PHP_VERSION_CMD}-mysql
            install_packages php${PHP_VERSION_CMD}-curl php${PHP_VERSION_CMD}-gd php${PHP_VERSION_CMD}-mbstring
            install_packages php${PHP_VERSION_CMD}-xml php${PHP_VERSION_CMD}-zip php${PHP_VERSION_CMD}-opcache
            install_packages php${PHP_VERSION_CMD}-redis unzip tar
            ;;
    esac
    
    print_success "核心服务安装完成"
}

# =============================================================================
# 服务配置
# =============================================================================

configure_mariadb() {
    print_status "配置MariaDB..."
    
    case "$OS_NAME" in
        "alpine")
            # 初始化MariaDB
            if [[ ! -d "/var/lib/mysql/mysql" ]]; then
                mysql_install_db --user=mysql --datadir=/var/lib/mysql
            fi
            start_service "mariadb"
            ;;
        "debian")
            # 安全配置
            mysql_secure_installation << EOF

y
$DB_ROOT_PASSWORD
$DB_ROOT_PASSWORD
y
y
y
y
EOF
            start_service "mysql"
            ;;
    esac
    
    # 创建WordPress数据库和用户
    mysql -u root -p"$DB_ROOT_PASSWORD" << EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # 优化配置
    local mysql_conf_path
    case "$OS_NAME" in
        "alpine")
            mysql_conf_path="/etc/my.cnf.d/wordpress.cnf"
            ;;
        "debian")
            mysql_conf_path="/etc/mysql/conf.d/wordpress.cnf"
            ;;
    esac
    
    cat > "$mysql_conf_path" << EOF
[mysqld]
innodb_buffer_pool_size = 128M
innodb_log_file_size = 32M
max_connections = 50
character-set-server = utf8mb4
EOF
    
    restart_service "mariadb" || restart_service "mysql"
}

configure_php() {
    print_status "配置PHP..."
    
    local php_ini=$(get_php_ini_path)
    local php_fpm=$(get_php_fpm_path)
    
    # 优化PHP配置
    sed -i "s/memory_limit = .*/memory_limit = 256M/" "$php_ini"
    sed -i "s/upload_max_filesize = .*/upload_max_filesize = 64M/" "$php_ini"
    sed -i "s/post_max_size = .*/post_max_size = 64M/" "$php_ini"
    sed -i "s/max_execution_time = .*/max_execution_time = 300/" "$php_ini"
    
    # 配置PHP-FPM
    sed -i "s/pm.max_children = .*/pm.max_children = 30/" "$php_fpm"
    sed -i "s/pm.start_servers = .*/pm.start_servers = 5/" "$php_fpm"
    sed -i "s/pm.min_spare_servers = .*/pm.min_spare_servers = 5/" "$php_fpm"
    sed -i "s/pm.max_spare_servers = .*/pm.max_spare_servers = 20/" "$php_fpm"
    
    start_service "$(get_php_fpm_service)"
}

configure_redis() {
    print_status "配置Redis..."
    
    local redis_conf_path
    case "$OS_NAME" in
        "alpine")
            redis_conf_path="/etc/redis.conf"
            ;;
        "debian")
            redis_conf_path="/etc/redis/redis.conf"
            ;;
    esac
    
    # 配置Redis
    cat > "$redis_conf_path" << EOF
bind 127.0.0.1
port 6379
requirepass $REDIS_PASSWORD
maxmemory 128mb
maxmemory-policy allkeys-lru
EOF
    
    start_service "redis"
}

configure_nginx() {
    print_status "配置Nginx..."
    
    local nginx_conf_path
    case "$OS_NAME" in
        "alpine")
            nginx_conf_path="/etc/nginx/http.d/wordpress.conf"
            ;;
        "debian")
            nginx_conf_path="/etc/nginx/sites-available/wordpress"
            ;;
    esac
    
    # 创建Nginx配置
    cat > "$nginx_conf_path" << EOF
server {
    listen ${NGINX_PORT};
    server_name ${DOMAIN};
    root ${WP_PATH};
    index index.php index.html index.htm;

    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\. {
        deny all;
    }
}
EOF

    # Debian系统需要启用站点
    if [[ "$OS_NAME" == "debian" ]]; then
        ln -sf "$nginx_conf_path" /etc/nginx/sites-enabled/
    fi
    
    start_service "nginx"
}

# =============================================================================
# WordPress安装
# =============================================================================

install_wordpress() {
    print_status "安装WordPress..."
    
    # 下载WordPress
    if [[ ! -d "$WP_PATH" ]]; then
        mkdir -p "$WP_PATH"
        cd /tmp
        wget https://wordpress.org/latest.tar.gz
        tar -xzf latest.tar.gz
        mv wordpress/* "$WP_PATH/"
        rm -rf wordpress latest.tar.gz
    fi
    
    # 设置权限
    case "$OS_NAME" in
        "alpine")
            adduser -D -s /bin/sh -h /var/www www-data || true
            ;;
        "debian")
            useradd -r -s /bin/false www-data || true
            ;;
    esac
    
    chown -R www-data:www-data "$WP_PATH"
    
    # 创建wp-config.php
    if [[ ! -f "$WP_PATH/wp-config.php" ]]; then
        cp "$WP_PATH/wp-config-sample.php" "$WP_PATH/wp-config.php"
        
        # 替换数据库配置
        sed -i "s/database_name_here/$DB_NAME/" "$WP_PATH/wp-config.php"
        sed -i "s/username_here/$DB_USER/" "$WP_PATH/wp-config.php"
        sed -i "s/password_here/$DB_PASSWORD/" "$WP_PATH/wp-config.php"
        
        # 添加Redis配置
        cat >> "$WP_PATH/wp-config.php" << EOF

// Redis配置
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_PASSWORD', '$REDIS_PASSWORD');
define('WP_CACHE', true);
define('WP_MEMORY_LIMIT', '256M');
EOF

        # 生成认证密钥
        local salts=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
        if [[ -n "$salts" ]]; then
            sed -i "/AUTH_KEY/d;/SECURE_AUTH_KEY/d;/LOGGED_IN_KEY/d;/NONCE_KEY/d;/AUTH_SALT/d;/SECURE_AUTH_SALT/d;/LOGGED_IN_SALT/d;/NONCE_SALT/d" "$WP_PATH/wp-config.php"
            echo "$salts" >> "$WP_PATH/wp-config.php"
        fi
    fi
    
    chown www-data:www-data "$WP_PATH/wp-config.php"
}

# =============================================================================
# 交互式配置
# =============================================================================

generate_config() {
    print_status "生成配置..."
    
    # 域名配置
    if [[ -z "${DOMAIN:-}" ]]; then
        read -p "请输入域名 (默认: localhost): " DOMAIN_INPUT
        DOMAIN=${DOMAIN_INPUT:-localhost}
    fi
    
    # 端口配置
    if [[ -z "${NGINX_PORT:-}" ]]; then
        read -p "请输入Nginx端口 (默认: 80): " PORT_INPUT
        NGINX_PORT=${PORT_INPUT:-80}
    fi
    
    # 数据库配置
    if [[ -z "${DB_NAME:-}" ]]; then
        DB_NAME="wordpress"
    fi
    
    if [[ -z "${DB_USER:-}" ]]; then
        DB_USER="wp_user"
    fi
    
    if [[ -z "${DB_PASSWORD:-}" ]]; then
        DB_PASSWORD=$(generate_password 16)
        print_status "已生成数据库密码: $DB_PASSWORD"
    fi
    
    if [[ -z "${DB_ROOT_PASSWORD:-}" ]]; then
        DB_ROOT_PASSWORD=$(generate_password 20)
        print_status "已生成root数据库密码: $DB_ROOT_PASSWORD"
    fi
    
    # WordPress配置
    if [[ -z "${WP_PATH:-}" ]]; then
        WP_PATH="/var/www/wordpress"
    fi
    
    if [[ -z "${WP_ADMIN_USER:-}" ]]; then
        WP_ADMIN_USER="admin"
    fi
    
    if [[ -z "${WP_ADMIN_PASSWORD:-}" ]]; then
        WP_ADMIN_PASSWORD=$(generate_password 12)
        print_status "已生成WordPress管理员密码: $WP_ADMIN_PASSWORD"
    fi
    
    if [[ -z "${WP_ADMIN_EMAIL:-}" ]]; then
        WP_ADMIN_EMAIL="admin@$DOMAIN"
    fi
    
    # Redis配置
    if [[ -z "${REDIS_PASSWORD:-}" ]]; then
        REDIS_PASSWORD=$(generate_password 16)
        print_status "已生成Redis密码: $REDIS_PASSWORD"
    fi
    
    save_config
    print_success "配置已保存到: $CONFIG_FILE"
}

# =============================================================================
# 主流程
# =============================================================================

main() {
    print_status "开始通用WordPress自动化部署..."
    print_status "系统检测中..."
    
    # 检测系统
    detect_system
    
    # 检查root权限
    check_root
    
    # 测试网络
    test_network
    
    # 尝试加载现有配置
    if load_config; then
        print_status "已加载现有配置"
        read -p "是否重新配置? (y/N): " reconfigure
        if [[ "$reconfigure" =~ ^[Yy]$ ]]; then
            generate_config
        fi
    else
        # 生成新配置
        generate_config
    fi
    
    # 安装依赖
    install_dependencies
    
    # 安装服务
    install_services
    
    # 配置服务
    configure_mariadb
    configure_php
    configure_redis
    configure_nginx
    
    # 安装WordPress
    install_wordpress
    
    print_success "通用WordPress部署完成！"
    echo
    echo "======================================"
    echo "系统类型: $OS_NAME"
    echo "访问地址: http://localhost:${NGINX_PORT}"
    echo "WordPress管理员: $WP_ADMIN_USER"
    echo "WordPress密码: $WP_ADMIN_PASSWORD"
    echo "配置文件: $CONFIG_FILE"
    echo "======================================"
}

# =============================================================================
# 命令行参数处理
# =============================================================================

case "${1:-}" in
    "--help"|"-h")
        echo "使用方法: $0 [选项]"
        echo
        echo "通用WordPress自动化部署脚本"
        echo "自动检测并适配Debian/Ubuntu和Alpine Linux系统"
        echo
        echo "选项:"
        echo "  --help, -h     显示此帮助信息"
        echo "  --reinstall    重新安装"
        echo "  --check        检查系统兼容性"
        exit 0
        ;;
    "--check")
        print_status "检查系统兼容性..."
        detect_system
        echo
        echo "系统信息:"
        echo "  操作系统: $OS_NAME"
        echo "  包管理器: $PACKAGE_MANAGER"
        echo "  服务管理: $SERVICE_MANAGER"
        echo "  PHP版本: $(get_php_version)"
        echo "  支持状态: ✓ 兼容"
        exit 0
        ;;
    "--reinstall")
        print_status "重新安装模式..."
        main
        ;;
    *)
        main
        ;;
esac