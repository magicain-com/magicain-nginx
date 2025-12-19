# Magicain 私有化部署指南

> 适用于内网环境、无法访问公网 Docker 仓库的离线部署场景

## 🚀 快速开始

### 一、打包部署包（开发机）

> 💡 **环境要求**：需要 bash 和 zip 命令（Windows 用户请安装 Git Bash）

#### 1. 配置 Docker 凭据（首次需要）

```bash
cd standalone
cat > .env << EOF
# Docker Registry 配置（用于拉取私有镜像）
DOCKER_REGISTRY_URL=crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com
DOCKER_REGISTRY_USERNAME=your_username
DOCKER_REGISTRY_PASSWORD=your_password

# PostgreSQL 数据库配置
POSTGRES_USER=magicain
POSTGRES_PASSWORD=magicain123
EOF
```

#### 2. 一键打包

```bash
cd standalone
bash scripts/build-deployment-package.sh
```

**输出**：`standalone/build/standalone-deployment-20231217-143022.zip` (~1.3GB)

> 📦 **多架构镜像**：自动拉取 AMD64 和 ARM64 双架构，一个包适配所有服务器

---

### 二、部署到服务器

#### 1. 传输部署包

```bash
scp standalone/build/standalone-deployment-*.zip root@your-server-ip:/root/
```

#### 2. 解压

```bash
ssh root@your-server-ip
cd /root
unzip standalone-deployment-*.zip
cd standalone
```

#### 3. 一键安装

```bash
sudo bash scripts/install-and-start.sh
```

脚本自动完成：
- ✅ 检测系统环境（AMD64/ARM64）
- ✅ 安装 Docker（如未安装）
- ✅ 加载所有镜像
- ✅ 创建数据目录
- ✅ 启动所有服务

#### 4. 访问服务

```
HTTP:      http://server-ip
HTTPS:     https://server-ip
Admin UI:  http://server-ip:8080
Agent UI:  http://server-ip:8081
User UI:   http://server-ip:8082
Cloud API: http://server-ip:48080
```

---

### 三、更新应用

#### 1. 构建新版本部署包（开发机）

```bash
cd standalone
bash scripts/build-deployment-package.sh
```

#### 2. 传输并解压（服务器）

```bash
scp standalone/build/standalone-deployment-*.zip root@server:/root/
ssh root@server
cd /root
unzip -o standalone-deployment-*.zip  # -o 覆盖
```

#### 3. 运行更新

```bash
cd standalone
sudo bash scripts/install-and-start.sh
```

**重要**：
- ✅ 数据会保留（PostgreSQL、Redis）
- ✅ 容器会重建（使用新镜像）
- ✅ 旧镜像会自动清理

---

## 📖 常用命令

### 查看服务状态

```bash
cd standalone
docker compose ps
```

### 查看日志

```bash
# 所有服务
docker compose logs -f

# 特定服务
docker compose logs -f cloud
docker compose logs -f postgres
```

### 重启服务

```bash
# 重启所有服务
docker compose restart

# 重启特定服务
docker compose restart cloud
```

### 停止服务

```bash
docker compose stop
```

### 启动服务

```bash
docker compose up -d
```

---

## ⚙️ 系统要求

### 部署服务器

| 项目 | 要求 |
|------|------|
| **CPU** | AMD64 或 ARM64，推荐 4 核+ |
| **内存** | 最低 8GB，推荐 16GB+ |
| **磁盘** | 最低 50GB，推荐 100GB+ SSD |
| **系统** | CentOS 7+、Ubuntu 18.04+、麒麟 V10 |

> 💡 **多架构支持**：镜像支持 AMD64 和 ARM64，自动适配，无需手动选择

### 开发机（打包环境）

| 项目 | 要求 |
|------|------|
| **操作系统** | Windows (Git Bash)、macOS、Linux |
| **必需工具** | Docker、bash、zip |
| **Docker 版本** | 推荐 20.10+ (支持多架构拉取) |

#### Windows 用户

安装 **Git Bash** 即可（自带 bash 和 zip）：
- 下载：https://git-scm.com/download/win
- 安装后打开 Git Bash 运行脚本

---

## 🔧 服务架构

| 服务 | 端口 | 说明 |
|------|------|------|
| **Nginx** | 80, 443 | 反向代理 |
| **Admin UI** | 8080 | 管理后台 |
| **Agent UI** | 8081 | Agent 界面 |
| **User UI** | 8082 | 用户界面 |
| **Cloud API** | 48080 | 后端服务 |
| **PostgreSQL** | 5432 | 数据库 |
| **Redis** | 6379 | 缓存 |

---

## 📦 镜像列表

| 镜像 | 大小 | 说明 |
|------|------|------|
| `cloud_main.tar` | ~440MB | 后端服务（多架构）|
| `admin-ui_main.tar` | ~28MB | 管理后台 |
| `agent-ui_main.tar` | ~20MB | Agent 界面 |
| `agent-ui_main-noda.tar` | ~21MB | Agent 界面（无达梦）|
| `user-ui_main.tar` | ~20MB | 用户界面 |
| `nginx_1-25-alpine.tar` | ~19MB | Nginx |
| `pgvector_pg16.tar` | ~174MB | PostgreSQL |
| `redis_7-alpine.tar` | ~17MB | Redis |

**总大小**: 约 1.3GB

---

## ⚠️ 重要注意事项

### 1. 数据库密码配置

`.env` 文件中的 `POSTGRES_PASSWORD` 必须与 Java 应用配置一致（默认 `magicain123`）

### 2. 麒麟 V10 系统

需要额外安装 `iptables-nft`：

```bash
sudo yum install iptables iptables-nft -y
```

### 3. 数据库更新机制

- **首次部署**：自动执行初始化脚本，创建数据库
- **更新时**：初始化脚本**不会重新执行**，数据保留
- **Schema 升级**：需要手动执行增量 SQL（见下方详细说明）

### 4. 镜像更新机制

- 使用 `main` tag（无版本号）
- 必须使用 `--force-recreate` 强制重建容器
- 脚本已自动处理，无需手动操作

---

## 🔥 常见问题快速解决

### 问题 1：端口被占用

```bash
# 检查端口
sudo netstat -tlnp | grep :80

# 停止占用端口的服务或修改 docker-compose.yml
```

### 问题 2：数据库连接失败

```bash
# 检查密码是否一致
cat .env

# 测试数据库连接
docker exec postgres psql -U magicain -d magicain -c "SELECT 1"

# 测试容器网络
docker exec cloud sh -c '(echo > /dev/tcp/postgres/5432) 2>/dev/null && echo "OK" || echo "FAIL"'
```

### 问题 3：防火墙问题（麒麟系统）

```bash
# 添加 Docker 网络到信任区域
sudo firewall-cmd --permanent --zone=trusted --add-interface=docker0
sudo firewall-cmd --reload

# 或临时关闭测试
sudo systemctl stop firewalld
```

---

## 📚 详细文档

### 数据备份与恢复

#### 备份数据库

```bash
# 完整备份
docker compose exec postgres pg_dumpall -U postgres > backup_$(date +%Y%m%d).sql

# 特定数据库
docker compose exec postgres pg_dump -U magicain magicain > magicain_backup.sql
```

#### 恢复数据库

```bash
# 完整恢复
docker compose exec -T postgres psql -U postgres < backup_20240101.sql

# 特定数据库
docker compose exec -T postgres psql -U magicain -d magicain < magicain_backup.sql
```

---

### 数据库 Schema 升级

当应用更新需要升级数据库结构时：

#### 1. 准备升级脚本（upgrade.sql）

```sql
-- 添加新表
CREATE TABLE IF NOT EXISTS new_feature (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 添加新字段
ALTER TABLE existing_table 
ADD COLUMN IF NOT EXISTS new_field VARCHAR(100);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_field ON existing_table(new_field);
```

#### 2. 执行升级

```bash
# 备份（必需）
docker compose exec postgres pg_dump -U magicain magicain > backup_before_upgrade.sql

# 停止应用
docker compose stop cloud

# 执行升级
docker compose exec -T postgres psql -U magicain -d magicain < upgrade.sql

# 验证升级
docker compose exec postgres psql -U magicain -d magicain -c "\dt"

# 更新应用
sudo bash scripts/install-and-start.sh
```

#### 3. 回滚（如果出问题）

```bash
# 停止服务
docker compose stop

# 恢复数据库
docker compose exec -T postgres psql -U magicain -d magicain < backup_before_upgrade.sql

# 加载旧版本镜像
docker load -i old_version/cloud_main.tar

# 启动旧版本
docker compose up -d --force-recreate
```

---

### 更新策略详解

#### 小版本更新（无数据库变更）

适用：Bug 修复、性能优化等

```bash
# 1. 备份（推荐）
docker compose exec postgres pg_dump -U magicain magicain > backup.sql

# 2. 构建新部署包（开发机）
cd standalone && bash scripts/build-deployment-package.sh

# 3. 传输并解压（服务器）
scp build/standalone-deployment-*.zip root@server:/root/
ssh root@server "cd /root && unzip -o standalone-deployment-*.zip"

# 4. 更新
ssh root@server "cd /root/standalone && sudo bash scripts/install-and-start.sh"

# 5. 验证
ssh root@server "cd /root/standalone && docker compose ps && docker compose logs -f cloud"
```

#### 大版本更新（有数据库变更）

适用：新增表/字段、结构变更等

```bash
# 1. 完整备份（必需）
docker compose exec postgres pg_dump -U magicain magicain > backup_v1.0.sql

# 2. 停止应用
docker compose stop cloud

# 3. 执行 Schema 升级
docker compose exec -T postgres psql -U magicain -d magicain < upgrade.sql

# 4. 验证升级
docker compose exec postgres psql -U magicain -d magicain -c "\dt"

# 5. 更新应用
sudo bash scripts/install-and-start.sh

# 6. 验证服务
docker compose logs -f cloud
```

---

### 手动部署（详细步骤）

如果不使用一键脚本，可以手动部署：

#### 1. 安装 Docker

```bash
cd standalone
sudo bash scripts/install-infra.sh
```

#### 2. 加载镜像

```bash
cd standalone
for img in docker/images/*.tar; do
  docker load -i "$img"
done
```

#### 3. 创建目录

```bash
sudo mkdir -p /data/postgres
sudo mkdir -p /data/redis
mkdir -p logs/nginx
mkdir -p cert
```

#### 4. 配置环境变量

```bash
cat > .env << EOF
POSTGRES_USER=magicain
POSTGRES_PASSWORD=magicain123
EOF
```

#### 5. 启动服务

```bash
docker compose up -d
```

#### 6. 验证

```bash
docker compose ps
docker compose logs -f
```

---

### 故障排查详解

#### 1. Docker 网络失败（麒麟 V10）

**错误**：`modprobe: nf_tables module not found`

**解决**：
```bash
sudo yum install iptables iptables-nft -y
sudo modprobe nf_tables
```

#### 2. 端口冲突

**错误**：`Error: bind: address already in use`

**解决**：
```bash
# 查找占用端口的进程
sudo netstat -tlnp | grep :80

# 停止进程或修改端口
vi docker-compose.yml  # 修改 ports 映射
```

#### 3. 权限问题

**错误**：`Permission denied: /data/postgres`

**解决**：
```bash
sudo chown -R 999:999 /data/postgres
sudo chown -R 999:999 /data/redis
```

#### 4. 镜像加载失败

**排查**：
```bash
# 检查文件完整性
cd docker/images
ls -lh *.tar

# 手动加载测试
docker load -i cloud_main.tar

# 查看 Docker 日志
journalctl -u docker -f
```

#### 5. 数据库连接失败

**排查步骤**：
```bash
# 1. 检查 postgres 容器状态
docker ps | grep postgres

# 2. 测试数据库连接
docker exec postgres psql -U magicain -d magicain -c "SELECT 1"

# 3. 检查密码配置
cat .env
# 确认 POSTGRES_PASSWORD=magicain123

# 4. 测试容器网络
docker exec cloud sh -c '(echo > /dev/tcp/postgres/5432) && echo "OK" || echo "FAIL"'

# 5. 查看 cloud 日志
docker compose logs cloud | grep -i error
```

**常见原因**：
- 密码不匹配（`.env` 与 Java 配置不一致）
- Docker 网络 DNS 解析失败
- PostgreSQL 未完全启动
- 防火墙阻止容器间通信

#### 6. 服务无法启动

```bash
# 查看详细日志
docker compose logs [service-name]

# 检查容器状态
docker compose ps

# 检查系统资源
free -h
df -h
docker system df

# 清理 Docker 资源
docker system prune -a
```

---

### 目录结构

```
standalone/
├── conf/                      # Nginx 配置
│   └── standalone.conf
├── cert/                      # SSL 证书（可选）
├── logs/nginx/                # Nginx 日志
├── build/                     # 构建输出（gitignore）
│   └── standalone-deployment-YYYYMMDD-HHMMSS.zip
├── docker/
│   ├── images/                # Docker 镜像离线包
│   │   ├── cloud_main.tar
│   │   ├── admin-ui_main.tar
│   │   └── ...
│   └── infra/                 # Docker 安装包（RPM）
│       ├── docker-ce-*.rpm
│       └── ...
├── database/
│   ├── postgresql/            # PG 初始化脚本
│   │   ├── 01-ruoyi-vue-pro.sql
│   │   ├── 02-quartz.sql
│   │   └── 03-pg-chatbi.sql
│   └── mysql/                 # MySQL 脚本（备用）
├── scripts/
│   ├── build-deployment-package.sh   # 一键打包
│   ├── install-and-start.sh          # 一键安装
│   ├── install-infra.sh              # 安装 Docker
│   └── docker-save.sh                # 保存镜像
├── docker-compose.yml         # Compose 配置
├── .env                       # 环境变量
└── README.md                  # 本文档
```

---

### 更新最佳实践

#### 更新前检查清单

- [ ] 查看版本更新说明（是否有 Schema 变更）
- [ ] 备份 PostgreSQL 数据库
- [ ] 备份 Redis 数据（如果重要）
- [ ] 记录当前镜像版本
- [ ] 保留旧版本镜像（用于回滚）
- [ ] 通知用户维护时间窗口

#### 更新后验证清单

- [ ] 检查容器状态：`docker compose ps`
- [ ] 检查日志无异常：`docker compose logs cloud`
- [ ] 测试 API 接口
- [ ] 验证前端页面
- [ ] 检查数据库连接
- [ ] 验证关键功能

#### 回滚方案

```bash
# 1. 停止服务
docker compose stop

# 2. 恢复数据库（如有 Schema 变更）
docker compose exec -T postgres psql -U magicain -d magicain < backup.sql

# 3. 加载旧版本镜像
docker load -i old_version/cloud_main.tar
docker load -i old_version/admin-ui_main.tar
# ... 其他镜像

# 4. 强制重建容器
docker compose up -d --force-recreate

# 5. 验证
docker compose ps
docker compose logs -f cloud
```

---

### 镜像版本管理

#### 保留旧版本（推荐）

```bash
# 更新前，导出当前版本
docker save cloud:main > backup/cloud_main_v1.0_$(date +%Y%m%d).tar
```

#### 记录部署历史

```bash
# 创建部署日志
echo "$(date): Deployed $(docker images | grep cloud:main | awk '{print $3}')" >> deployment.log
```

#### 建议使用具体版本 tag

```yaml
# 推荐（便于回滚）
image: magictensor/cloud:v1.2.3

# 不推荐（难以追溯）
image: magictensor/cloud:main
```

---

### 日志位置

- **Nginx**: `standalone/logs/nginx/`
- **容器**: `docker compose logs`
- **系统**: `/var/log/messages` 或 `/var/log/syslog`

---

## 📞 技术支持

遇到问题时，收集以下信息：

1. 系统信息：`uname -a`
2. Docker 版本：`docker --version`
3. 容器状态：`docker compose ps`
4. 错误日志：`docker compose logs`
5. 系统资源：`free -h` 和 `df -h`

---

## 📝 更新日志

| 日期 | 版本 | 说明 |
|------|------|------|
| 2024-12-17 | v1.0 | 初始版本 |

---

> 💡 **提示**：首次部署建议先在测试环境验证，确认无误后再部署生产环境
