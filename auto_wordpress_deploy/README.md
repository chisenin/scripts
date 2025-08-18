# 通用WordPress自动化部署脚本

## 🚀 功能特点

- ✅ **自动检测系统**：智能识别Debian/Ubuntu和Alpine Linux
- ✅ **完全自动化**：所有配置自动生成，无需手动输入
- ✅ **智能记忆**：自动保存配置，支持重新部署
- ✅ **完整环境**：WordPress + Nginx + MariaDB + PHP + Redis
- ✅ **性能优化**：针对容器环境优化配置
- ✅ **中文支持**：完整中文界面和文档
- ✅ **一键部署**：小白也能轻松使用

## 📋 系统支持

| 系统类型 | 版本支持 | 包管理器 | 服务管理 | 状态 |
|----------|----------|----------|----------|------|
| **Debian** | 10/11/12 | apt | systemctl | ✅ |
| **Ubuntu** | 18.04/20.04/22.04 | apt | systemctl | ✅ |
| **Alpine** | 3.15+ | apk | rc-service | ✅ |

## 🚀 快速开始

### 一键部署（推荐）

```bash
# 下载脚本（任意系统通用）
wget https://your-domain.com/auto_wordpress_universal.sh
wget https://your-domain.com/quick_deploy.sh

# 一键部署
chmod +x quick_deploy.sh
./quick_deploy.sh
```

### 手动部署

```bash
chmod +x auto_wordpress_universal.sh
./auto_wordpress_universal.sh
```

## 🔧 使用方法

### 首次运行

脚本会自动检测系统类型并执行相应操作：

```bash
./auto_wordpress_universal.sh
```

### 重新部署

```bash
./auto_wordpress_universal.sh --reinstall
```

### 检查系统兼容性

```bash
./auto_wordpress_universal.sh --check
```

## 📊 默认配置

| 项目 | 默认值 | 说明 |
|------|--------|------|
| **域名** | localhost | 可自定义 |
| **端口** | 80 | HTTP端口 |
| **PHP版本** | 8.2 | 自动适配系统 |
| **数据库** | wordpress | WordPress专用数据库 |
| **安装路径** | /var/www/wordpress | 网站根目录 |
| **日志路径** | /var/log/wp_deploy | 部署日志 |

## 🔍 密码管理

所有密码自动生成并保存到：`~/.wp_universal_config`

```bash
# 查看配置
cat ~/.wp_universal_config
```

## 🎯 服务管理

### Debian/Ubuntu系统

```bash
# 启动服务
systemctl start nginx mysql php8.2-fpm redis

# 开机启动
systemctl enable nginx mysql php8.2-fpm redis

# 查看状态
systemctl status nginx mysql php8.2-fpm redis
```

### Alpine系统

```bash
# 启动服务
rc-service nginx start
rc-service mariadb start
rc-service php82-fpm start
rc-service redis start

# 开机启动
rc-update add nginx default
rc-update add mariadb default
rc-update add php82-fpm default
rc-update add redis default

# 查看状态
rc-service nginx status
```

## 📁 文件结构

```
auto_wordpress_deploy/
├── auto_wordpress_universal.sh    # 通用主部署脚本
├── quick_deploy.sh                 # 一键部署脚本
├── check_installation.sh           # 安装检查脚本
├── uninstall.sh                    # 卸载脚本
├── make_executable.sh              # 权限设置脚本
├── README.md                       # 使用说明
└── DEPLOYMENT_GUIDE.md             # 详细部署指南
```

## 🛠️ 系统要求

### 最小配置
- **内存**: 512MB
- **磁盘**: 2GB
- **CPU**: 1核

### 推荐配置
- **内存**: 1GB+
- **磁盘**: 10GB+
- **CPU**: 2核+

## 🔍 故障排查

### 查看日志
```bash
# 部署日志
tail -f /var/log/wp_deploy/auto_deploy_universal.log

# 服务日志
tail -f /var/log/nginx/error.log
```

### 常见问题

1. **权限问题**
   ```bash
   chown -R www-data:www-data /var/www/wordpress
   ```

2. **端口占用**
   ```bash
   netstat -tulnp | grep :80
   ```

3. **数据库连接失败**
   ```bash
   mysql -u root -p
   ```

## 🔄 更新维护

### 更新WordPress
```bash
cd /var/www/wordpress
wp core update
wp plugin update --all
```

### 备份网站
```bash
# 备份数据库
mysqldump -u root -p wordpress > backup_$(date +%Y%m%d).sql

# 备份文件
tar -czf wordpress_backup_$(date +%Y%m%d).tar.gz /var/www/wordpress
```

## 📞 技术支持

- **文档**: 查看`DEPLOYMENT_GUIDE.md`详细指南
- **问题**: 提交GitHub Issue
- **社区**: 加入技术交流群

## ⚖️ 许可证

MIT License - 可自由使用和修改
