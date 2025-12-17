# Standalone 部署指南

本文档介绍如何在独立服务器上部署 Magicain 系统。

## 📋 目录

- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [详细部署步骤](#详细部署步骤)
- [服务管理](#服务管理)
- [故障排查](#故障排查)

## 系统要求

### 硬件要求
- CPU: AMD64 (x86_64) 或 ARM64 (aarch64) 架构（推荐 4 核以上）
- 内存: 至少 8GB（推荐 16GB）
- 磁盘: 至少 50GB 可用空间

### 软件要求
- 操作系统: Linux（支持麒麟 V10、CentOS 7+、Ubuntu 20.04+）
- 内核版本: 3.10 或更高
- 网络: 可访问互联网（用于拉取镜像）或已准备好离线镜像包

> **多架构支持**：Docker 镜像构建为多架构镜像，自动适配 AMD64 和 ARM64 平台，无需手动选择。

## 快速开始

### 一键安装启动

```bash
# 进入 standalone 目录
cd standalone

# 运行一键安装启动脚本
sudo bash scripts/install-and-start.sh
```

该脚本会自动完成：
1. 检查系统环境
2. 安装 Docker 和 Docker Compose
3. 加载 Docker 镜像（如果存在离线包）
4. 创建必要的目录和配置
5. 启动所有服务

## 详细部署步骤

### 步骤 1: 安装 Docker 基础设施

如果系统未安装 Docker，使用提供的脚本安装：

```bash
cd standalone
sudo bash scripts/install-infra.sh
```

该脚本会：
- 从 `docker/infra/` 目录安装 Docker RPM 包
- 启动并启用 Docker 服务
- 验证安装是否成功

**注意**: 
- 在麒麟 V10 系统上，可能需要额外安装 iptables-nft：
  ```bash
  sudo yum install iptables iptables-nft -y
  ```
- 安装脚本会自动检测系统架构（AMD64 或 ARM64），无需手动配置

### 步骤 2: 准备 Docker 镜像

#### 方式 A: 使用离线镜像包（推荐）

如果已有离线镜像包（位于 `docker/images/` 目录）：

```bash
cd standalone
# 加载所有镜像
for img in docker/images/*.tar; do
  docker load -i "$img"
done
```

或者使用安装脚本会自动加载所有镜像。

#### 方式 B: 从网络拉取镜像

如果没有离线包，Docker Compose 会自动从网络拉取镜像。确保服务器可以访问：
- `crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com`
- `docker.m.daocloud.io`

#### 方式 C: 打包镜像（开发环境）

如果需要打包镜像供离线使用：

1. 配置 Docker 镜像仓库凭证（如果需要拉取私有镜像），在 `standalone/.env` 文件中添加：

```bash
DOCKER_REGISTRY_URL=crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com
DOCKER_REGISTRY_USERNAME=your_username
DOCKER_REGISTRY_PASSWORD=your_password
```

2. 运行打包脚本：

```bash
cd standalone
bash scripts/docker-save.sh
```

该脚本会：
- 自动登录 Docker 镜像仓库（如果提供了凭证）
- 拉取所有多架构镜像（支持 AMD64 和 ARM64）
- 将每个镜像单独保存为 tar 文件到 `docker/images/` 目录
- 显示详细的打包进度和文件大小

**打包的镜像列表**：
- `cloud_main.tar` (~440MB) - 后端服务（多架构）
- `admin-ui_main.tar` (~28MB) - 管理后台（多架构）
- `agent-ui_main.tar` (~20MB) - Agent 界面（多架构）
- `agent-ui_main-noda.tar` (~21MB) - Agent 界面（无达梦数据库）
- `user-ui_main.tar` (~20MB) - 用户界面（多架构）
- `nginx_1-25-alpine.tar` (~19MB) - Nginx 反向代理（多架构）
- `pgvector_pg16.tar` (~174MB) - PostgreSQL + PgVector（多架构）
- `redis_7-alpine.tar` (~17MB) - Redis 缓存（多架构）

**总大小**: 约 1.3GB

> **注意**：镜像构建为多架构（multi-arch），Docker 会根据当前系统架构自动选择对应版本，部署时无需关心架构差异。

3. 打包完整部署包：

```bash
# 返回项目根目录
cd ..

# 打包整个 standalone 目录
zip -r standalone-deployment.zip standalone/ \
  -x "standalone/.git/*" \
  -x "standalone/logs/*" \
  -x "standalone/.DS_Store"

# 查看打包结果
ls -lh standalone-deployment.zip
```

现在可以将 `standalone-deployment.zip` 传输到目标服务器进行部署。

### 步骤 3: 配置环境变量

创建 `.env` 文件（如果不存在）：

```bash
cd standalone
cat > .env << EOF
# PostgreSQL 数据库配置
POSTGRES_USER=magicain
POSTGRES_PASSWORD=magicain123
EOF
```

**重要**: 
- `POSTGRES_PASSWORD` 必须与 Java 应用配置中的密码一致（默认为 `magicain123`）
- 生产环境建议修改为强密码，并同步更新 Java 应用配置

### 步骤 4: 创建必要的目录

```bash
cd standalone

# 创建数据目录
sudo mkdir -p /data/postgres
sudo mkdir -p /data/redis

# 创建日志目录
mkdir -p logs/nginx

# 创建证书目录（如果需要 SSL）
mkdir -p cert
```

### 步骤 5: 配置 SSL 证书（可选）

如果需要 HTTPS，将证书文件放入 `cert/` 目录：

```bash
cd standalone
# 将证书文件复制到 cert 目录
# cert/server.crt
# cert/server.key
```

### 步骤 6: 启动服务

```bash
cd standalone
docker compose up -d
```

### 步骤 7: 验证部署

检查服务状态：

```bash
# 查看所有服务状态
docker compose ps

# 查看服务日志
docker compose logs -f

# 检查特定服务
docker compose logs nginx-proxy
docker compose logs cloud
```

访问服务：
- HTTP: http://your-server-ip
- HTTPS: https://your-server-ip（如果配置了证书）
- Admin UI: http://your-server-ip:8080
- Agent UI: http://your-server-ip:8081
- User UI: http://your-server-ip:8082
- Cloud API: http://your-server-ip:48080

## 服务管理

### 启动服务

```bash
cd standalone
docker compose up -d
```

### 停止服务

```bash
cd standalone
docker compose stop
```

### 重启服务

```bash
cd standalone
docker compose restart
```

### 停止并删除容器

```bash
cd standalone
docker compose down
```

### 查看日志

```bash
# 查看所有服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f cloud
docker compose logs -f nginx-proxy
```

### 更新服务

#### 方式一：一键更新（推荐）

使用安装脚本自动更新，会自动检测已运行的容器并进行更新：

```bash
cd standalone

# 如果有新的离线镜像包，替换 docker/images 目录中的 tar 文件

# 运行更新脚本
sudo bash scripts/install-and-start.sh
```

脚本会自动：
1. 加载新镜像（覆盖旧镜像）
2. 停止旧版本容器
3. 使用新镜像重新创建并启动容器
4. **保留所有数据库和配置数据**

#### 方式二：手动更新

```bash
cd standalone

# 拉取最新镜像（在线方式）
docker compose pull

# 或者加载离线镜像包
docker load -i docker/images/xxx.tar

# 停止并删除旧容器
docker compose down

# 使用新镜像启动服务
docker compose up -d
```

## 故障排查

### 常见问题

#### 1. Docker 网络启动失败（麒麟 V10）

**错误信息**:
```
modprobe: nf_tables module not found
```

**解决方法**:
```bash
sudo yum install iptables iptables-nft -y
# 或手动加载内核模块
sudo modprobe nf_tables
```

#### 2. 端口被占用

**错误信息**:
```
Error: bind: address already in use
```

**解决方法**:
```bash
# 检查端口占用
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# 停止占用端口的服务或修改 docker-compose.yml 中的端口映射
```

#### 3. 数据目录权限问题

**错误信息**:
```
Permission denied: /data/postgres
```

**解决方法**:
```bash
sudo chown -R 999:999 /data/postgres
sudo chown -R 999:999 /data/redis
```

#### 4. 镜像拉取失败

**解决方法**:
- 检查网络连接
- 使用离线镜像包：将 tar 文件放入 `docker/images/` 目录，安装脚本会自动加载
- 检查镜像仓库访问权限

#### 5. 数据库连接失败（Cloud 服务无法连接 PostgreSQL）

**错误信息**:
```
Caused by: org.postgresql.util.PSQLException: The connection attempt failed
com.baomidou.dynamic.datasource.exception.ErrorCreateDataSourceException: druid create error
```

**常见原因及解决方法**:

**原因 1: 密码不匹配**
```bash
# 检查 .env 文件中的密码
cat .env
# 确认 POSTGRES_PASSWORD 是否为 magicain123

# 如果密码不一致，修改 .env 文件
vi .env
# 然后重新启动服务
docker compose down
docker compose up -d
```

**原因 2: Docker 网络 DNS 解析失败**
```bash
# 测试 cloud 容器能否解析 postgres 主机名
docker exec cloud sh -c '(echo > /dev/tcp/postgres/5432) 2>/dev/null && echo "可连接" || echo "不可连接"'

# 如果显示"不可连接"，检查 docker-compose.yml 中是否配置了 links 和 hostname
# 已在最新版本中通过以下配置解决：
# - postgres 服务添加了 hostname: postgres
# - cloud 服务添加了 links: - postgres
```

**原因 3: PostgreSQL 未完全启动**
```bash
# 检查 postgres 健康状态
docker compose ps postgres

# 查看 postgres 日志
docker compose logs postgres

# 等待 postgres 完全启动后再启动 cloud
docker compose up -d postgres
sleep 10
docker compose up -d cloud
```

**原因 4: 防火墙阻止容器间通信（麒麟系统常见）**
```bash
# 检查 firewalld 状态
sudo systemctl status firewalld

# 添加 Docker 网络到信任区域
sudo firewall-cmd --permanent --zone=trusted --add-interface=docker0
sudo firewall-cmd --permanent --zone=trusted --add-interface=br-$(docker network inspect standalone_magicain-app -f '{{.Id}}' | cut -c1-12)
sudo firewall-cmd --reload

# 或临时关闭防火墙测试
sudo systemctl stop firewalld

# 重启 Docker 和服务
sudo systemctl restart docker
docker compose down
docker compose up -d
```

#### 6. 服务无法启动

**排查步骤**:
```bash
# 查看详细错误日志
docker compose logs [service-name]

# 检查容器状态
docker compose ps

# 检查系统资源
free -h
df -h
```

### 日志位置

- Nginx 日志: `standalone/logs/nginx/`
- Docker 容器日志: `docker compose logs`
- 系统日志: `/var/log/messages` 或 `/var/log/syslog`

### 数据备份

#### 备份数据库

```bash
# 备份 PostgreSQL
docker compose exec postgres pg_dumpall -U postgres > backup_$(date +%Y%m%d).sql

# 备份 Redis（如果使用持久化）
docker compose exec redis redis-cli SAVE
cp /data/redis/dump.rdb backup_redis_$(date +%Y%m%d).rdb
```

#### 恢复数据库

```bash
# 恢复 PostgreSQL
docker compose exec -T postgres psql -U postgres < backup_20240101.sql
```

## 目录结构

```
standalone/
├── conf/              # Nginx 配置文件
│   └── standalone.conf
├── cert/              # SSL 证书目录
├── logs/              # 日志目录
│   └── nginx/
├── docker/            # Docker 相关文件
│   ├── images/        # Docker 镜像包目录（多架构镜像）
│   │   ├── cloud_main.tar
│   │   ├── admin-ui_main.tar
│   │   ├── agent-ui_main.tar
│   │   ├── agent-ui_main-noda.tar
│   │   ├── user-ui_main.tar
│   │   ├── nginx_1-25-alpine.tar
│   │   ├── pgvector_pg16.tar
│   │   └── redis_7-alpine.tar
│   └── infra/         # Docker 安装包（支持 AMD64/ARM64）
│       ├── libcgroup-*.rpm
│       ├── container-selinux-*.rpm
│       ├── containerd.io-*.rpm
│       ├── docker-ce-*.rpm
│       ├── docker-ce-cli-*.rpm
│       └── docker-compose-plugin-*.rpm
├── scripts/           # 部署脚本
│   ├── install-infra.sh          # 安装 Docker
│   ├── docker-save.sh            # 打包镜像（多架构）
│   └── install-and-start.sh      # 一键安装启动
├── docker-compose.yml # Docker Compose 配置
├── .env               # 环境变量配置
└── README.md          # 本文档
```

## 技术支持

如遇到问题，请检查：
1. 系统日志
2. Docker 容器日志
3. 网络连接
4. 磁盘空间和内存使用情况

---

⚠️ **麒麟 V10 常见坑**: 需要额外安装 iptables-nft，否则 Docker 网络启动报错：
```
modprobe: nf_tables module not found
```
解决：`yum install iptables iptables-nft -y` 或手动加载内核模块。
