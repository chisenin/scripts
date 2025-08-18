# 通用WordPress完整部署方案

## 📦 部署包内容

本部署包包含以下文件：

### 核心脚本
- `auto_wordpress_universal.sh` - 通用主部署脚本（支持Debian/Ubuntu/Alpine）
- `quick_deploy.sh` - 一键部署脚本
- `check_installation.sh` - 安装状态检查
- `uninstall.sh` - 卸载清理脚本

### 辅助文件
- `README.md` - 详细使用说明
- `make_executable.sh` - 权限设置脚本

## 🚀 快速开始

### 方法1：一键部署（推荐小白用户）
```bash
# 下载脚本（所有系统通用）
curl -O [脚本地址]/quick_deploy.sh
curl -O [脚本地址]/auto_wordpress_universal.sh

chmod +x quick_deploy.sh
./quick_deploy.sh
```

### 方法2：完整部署（推荐高级用户）
```bash
# 下载完整脚本包
chmod +x *.sh
./auto_wordpress_universal.sh
```

## 📋 系统支持

| 系统类型 | 检测方式 | 包管理器 | 服务管理 | 状态 |
|----------|----------|----------|----------|------|
| **Debian** | `/etc/debian_version` | `apt` | `systemctl` | ✅ |
| **Ubuntu** | `/etc/debian_version` | `apt` | `systemctl` | ✅ |
| **Alpine** | `/etc/alpine-release` | `apk` | `rc-service` | ✅ |

## 🔧 部署前准备

### 系统要求
- **操作系统**：Debian 10+ / Ubuntu 18.04+ / Alpine 3.15+
- **内存**：最低512MB，推荐1GB+
- **存储**：最低2GB可用空间
- **网络**：需要互联网连接

### PVE LXC容器配置建议

#### Debian/Ubuntu容器
```bash
pct create 100 local:vztmpl/debian-12-standard_20231015_amd64.tar.xz \
  --hostname wordpress-debian \
  --cores 2 \
  --memory 1024 \
  --rootfs 10G \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 1 \
  --onboot 1
```

#### Alpine容器
```bash
pct create 100 local:vztmpl/alpine-3.18-default_20230607_amd64.tar.xz \
  --hostname wordpress-alpine \
  --cores 2 \
  --memory 1024 \
  --rootfs 8G \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 1 \
  --onboot 1
```

## 🔧 部署流程

### 1. 进入容器
```bash
# 在PVE主机上执行
pct enter [容器ID]
```

### 2. 更新系统（根据系统类型）

#### Debian/Ubuntu
```bash
apt update && apt upgrade -y
```

#### Alpine
```bash
apk update && apk upgrade
```

### 3. 下载部署脚本
```bash
# 通用下载命令
curl -O https://raw.githubusercontent.com/your-repo/auto_wordpress_universal.sh
curl -O https://raw.githubusercontent.com/your-repo/quick_deploy.sh
```

### 4. 执行部署
```bash
chmod +x auto_wordpress_universal.sh
./auto_wordpress_universal.sh
```

## 📊 部署结果

部署完成后，你将获得：

### 服务组件（自动适配系统）
- **Nginx** - Web服务器
- **MariaDB** - 数据库
- **PHP** - 自动检测系统版本
- **Redis** - 缓存服务
- **WordPress** - 最新版本

### 自动配置
- ✅ 系统类型自动检测
- ✅ 所有密码自动生成并保存
- ✅ 数据库自动创建和优化
- ✅ Nginx配置优化
- ✅ PHP性能调优
- ✅ Redis缓存配置
- ✅ 中文语言包
- ✅ 安全设置
- ✅ 定时备份

### 访问信息
```
网站地址: http://[容器IP]:80
WordPress管理员: admin
管理员密码: [自动生成，请查看输出]
系统类型: [自动检测显示]
```

## 🔄 重新部署

### 场景1：保留配置重新安装
```bash
./auto_wordpress_universal.sh --reinstall
```

### 场景2：完全重新配置
```bash
# 先卸载
./uninstall.sh

# 再重新部署
./auto_wordpress_universal.sh
```

### 场景3：检查系统兼容性
```bash
./auto_wordpress_universal.sh --check
```

## 🛠️ 管理命令（按系统类型）

### Debian/Ubuntu系统
```bash
# 查看服务状态
systemctl status nginx mysql php8.2-fpm redis-server

# 重启服务
systemctl restart nginx mysql php8.2-fpm redis-server

# 开机启动
systemctl enable nginx mysql php8.2-fpm redis-server
```

### Alpine系统
```bash
# 查看服务状态
rc-service nginx status
rc-service mariadb status
rc-service php82-fpm status
rc-service redis status

# 重启服务
rc-service nginx restart
rc-service mariadb restart
rc-service php82-fpm restart
rc-service redis restart

# 开机启动
rc-update add nginx default
rc-update add mariadb default
rc-update add php82-fpm default
rc-update add redis default
```

### 通用命令
```bash
# 进入WordPress目录
cd /var/www/wordpress

# 查看配置信息
cat ~/.wp_universal_config
```

## 🔍 故障排查

### 系统检测问题
```bash
# 检查系统类型
cat /etc/os-release
ls -la /etc/*release*

# 检查脚本兼容性
./auto_wordpress_universal.sh --check
```

### 服务问题（按系统类型）

#### Debian/Ubuntu
```bash
# 查看服务日志
journalctl -u nginx --no-pager -n 50
journalctl -u mysql --no-pager -n 50
journalctl -u php8.2-fpm --no-pager -n 50
```

#### Alpine
```bash
# 查看服务日志
tail -n 50 /var/log/nginx/error.log
tail -n 50 /var/log/mysqld.log
tail -n 50 /var/log/php82/error.log
```

### 网络问题
```bash
# 检查网络连接
ping 8.8.8.8
nslookup google.com

# 检查端口占用
netstat -tulnp | grep :80
ss -tulnp | grep :80
```

### 权限问题
```bash
# 修复文件权限（通用）
chown -R www-data:www-data /var/www/wordpress

# Alpine系统可能需要
chown -R nginx:nginx /var/www/wordpress
```

### 内存问题
```bash
# 检查内存使用
free -h

# 检查磁盘空间
df -h

# 增加交换空间（通用）
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

## 📊 性能监控

### 系统监控（按系统类型）

#### Debian/Ubuntu
```bash
# 安装监控工具
apt install htop iotop

# 使用htop查看资源使用
htop
```

#### Alpine
```bash
# 安装监控工具
apk add htop iotop

# 使用htop查看资源使用
htop
```

### 服务监控
```bash
# 查看Nginx状态
curl -I http://localhost

# 查看PHP-FPM状态
php-fpm -t

# 查看MySQL状态
mysqladmin -u root -p status
```

## 🔄 备份与恢复

### 通用备份命令
```bash
# 创建备份目录
mkdir -p /var/backups/wordpress

# 备份数据库
mysqldump -u root -p wordpress > /var/backups/wordpress/db_$(date +%Y%m%d).sql

# 备份网站文件
tar -czf /var/backups/wordpress/files_$(date +%Y%m%d).tar.gz -C /var/www wordpress
```

### 恢复备份
```bash
# 恢复数据库
mysql -u root -p wordpress < /var/backups/wordpress/db_backup.sql

# 恢复文件
tar -xzf /var/backups/wordpress/files_backup.tar.gz -C /var/www/
```

## 📱 容器管理

### 导出容器（按系统类型）

#### Debian/Ubuntu容器
```bash
pct stop 100
vzdump 100 --remove 0 --mode snapshot
```

#### Alpine容器
```bash
pct stop 100
vzdump 100 --remove 0 --mode snapshot --compress zstd
```

### 导入容器
```bash
# 通用导入命令
pct restore 100 /var/lib/vz/dump/vzdump-lxc-100-*.tar.zst
```

## 🆘 高级故障排查

### 日志位置（按系统类型）

#### Debian/Ubuntu
- Nginx日志: `/var/log/nginx/`
- PHP日志: `/var/log/php*-fpm.log`
- MySQL日志: `/var/log/mysql/`
- 系统日志: `journalctl`

#### Alpine
- Nginx日志: `/var/log/nginx/`
- PHP日志: `/var/log/php*/`
- MySQL日志: `/var/log/mysqld.log`
- 系统日志: `/var/log/messages`

### 调试模式
```bash
# 以调试模式运行脚本
bash -x ./auto_wordpress_universal.sh
```

## 📞 技术支持

### 获取帮助
1. **查看文档**: `README.md` 和本指南
2. **检查日志**: 按系统类型查看相应日志
3. **系统信息**: 提供系统类型和版本信息
4. **错误信息**: 提供完整的错误输出

### 社区支持
- **GitHub Issues**: 提交详细问题报告
- **技术论坛**: 搜索相关解决方案
- **文档更新**: 关注脚本更新和优化