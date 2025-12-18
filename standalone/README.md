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

2. 运行一键打包脚本（推荐）：

```bash
cd standalone
bash scripts/build-deployment-package.sh
```

该脚本会自动完成：
- 使用 `docker-save.sh` 拉取最新的 Docker 镜像
- 将镜像保存到 `docker/images/` 目录
- 打包整个 standalone 目录为 zip 文件
- 保存到 `standalone/build/` 目录，文件名包含时间戳

**脚本输出示例**：
```
standalone/build/
└── standalone-deployment-20231217-143022.zip  (~1.3GB)
```

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

**或者手动打包（如果只需更新镜像）**：

```bash
# 仅拉取和保存镜像
cd standalone
bash scripts/docker-save.sh

# 手动打包
cd ..
zip -r standalone-deployment.zip standalone/ \
  -x "standalone/.git/*" \
  -x "standalone/build/*" \
  -x "standalone/logs/*" \
  -x "standalone/.DS_Store"
```

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
3. 清理悬空镜像（释放空间）
4. 使用新镜像强制重建容器
5. **保留所有数据库和配置数据**

#### 更新机制说明

**1. Docker 镜像更新（main tag）**

由于镜像使用 `main` tag（无版本号），更新机制如下：

- **离线部署场景**：
  - ✅ 先用 `build-deployment-package.sh` 拉取最新镜像打包
  - ✅ 部署包中的镜像会覆盖服务器上的旧镜像
  - ✅ `--force-recreate` 强制用新镜像重建容器
  - ⚠️  旧镜像会变成 `<none>` 状态，自动被清理

- **在线部署场景**：
  - 如果没有新的离线包，只是重新运行脚本，不会自动拉取最新镜像
  - 需要手动 `docker compose pull` 拉取最新版本

**2. PostgreSQL 数据库更新**

PostgreSQL 初始化脚本的行为：

- **首次安装**：
  - 数据目录 `/data/postgres` 为空
  - 自动执行 `database/postgresql/*.sql` 初始化脚本
  - 创建数据库结构和初始数据

- **更新时**：
  - 数据目录已存在
  - **初始化脚本不会重新执行**（PostgreSQL 官方镜像行为）
  - 所有数据保持不变

- **Schema 升级**：
  - 如果需要升级数据库结构（新增表/字段等）
  - 需要**手动执行增量 SQL 脚本**
  - 示例：
    ```bash
    docker compose exec postgres psql -U magicain -d magicain -f /path/to/upgrade.sql
    ```

**3. 完整更新流程（带镜像更新）**

```bash
# 开发机：构建最新部署包
cd standalone
bash scripts/build-deployment-package.sh

# 传输到服务器
scp build/standalone-deployment-*.zip root@server:/root/

# 服务器：解压并覆盖
cd /root
unzip -o standalone-deployment-*.zip

# 运行更新（会用新镜像重建容器）
cd standalone
sudo bash scripts/install-and-start.sh
```

#### 方式二：手动更新

```bash
cd standalone

# 拉取最新镜像（在线方式）
docker compose pull

# 或者加载离线镜像包
docker load -i docker/images/cloud_main.tar
docker load -i docker/images/admin-ui_main.tar
# ... 其他镜像

# 停止并删除旧容器（保留数据）
docker compose down

# 清理悬空镜像
docker image prune -f

# 使用新镜像启动服务
docker compose up -d --force-recreate
```

#### 验证更新

```bash
# 查看镜像版本
docker images | grep -E "cloud|admin-ui|agent-ui|user-ui"

# 查看容器创建时间（确认已重建）
docker compose ps

# 查看容器日志（确认启动正常）
docker compose logs -f cloud
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
# 备份 PostgreSQL（完整备份）
docker compose exec postgres pg_dumpall -U postgres > backup_$(date +%Y%m%d).sql

# 备份特定数据库
docker compose exec postgres pg_dump -U magicain magicain > magicain_backup_$(date +%Y%m%d).sql

# 备份 Redis（如果使用持久化）
docker compose exec redis redis-cli SAVE
cp /data/redis/dump.rdb backup_redis_$(date +%Y%m%d).rdb
```

#### 恢复数据库

```bash
# 恢复 PostgreSQL（完整恢复）
docker compose exec -T postgres psql -U postgres < backup_20240101.sql

# 恢复特定数据库
docker compose exec -T postgres psql -U magicain -d magicain < magicain_backup_20240101.sql
```

### 数据库 Schema 升级

当应用版本更新需要升级数据库结构时：

#### 准备升级脚本

创建增量升级脚本（例如 `upgrade_v2.0.sql`）：

```sql
-- 示例：添加新表
CREATE TABLE IF NOT EXISTS new_feature (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 示例：添加新字段
ALTER TABLE existing_table 
ADD COLUMN IF NOT EXISTS new_field VARCHAR(100);

-- 示例：创建索引
CREATE INDEX IF NOT EXISTS idx_existing_table_new_field 
ON existing_table(new_field);
```

#### 执行升级

**方式一：从宿主机执行**

```bash
# 将升级脚本复制到服务器
scp upgrade_v2.0.sql root@server:/root/

# 在服务器上执行
cd /root/standalone
docker compose exec -T postgres psql -U magicain -d magicain < /root/upgrade_v2.0.sql
```

**方式二：在容器内执行**

```bash
# 进入 postgres 容器
docker compose exec postgres bash

# 在容器内执行
psql -U magicain -d magicain << 'EOF'
-- 升级 SQL 语句
ALTER TABLE existing_table ADD COLUMN IF NOT EXISTS new_field VARCHAR(100);
EOF
```

**方式三：使用临时挂载**

```bash
# 将升级脚本放到 database/postgresql 目录
cp upgrade_v2.0.sql database/postgresql/

# 在容器内执行
docker compose exec postgres psql -U magicain -d magicain \
  -f /docker-entrypoint-initdb.d/upgrade_v2.0.sql
```

#### 升级后验证

```bash
# 查看表结构
docker compose exec postgres psql -U magicain -d magicain -c "\d table_name"

# 查看所有表
docker compose exec postgres psql -U magicain -d magicain -c "\dt"

# 验证数据
docker compose exec postgres psql -U magicain -d magicain -c "SELECT COUNT(*) FROM new_feature;"
```

#### 升级回滚

如果升级出现问题：

```bash
# 1. 停止服务
docker compose stop cloud

# 2. 恢复数据库到升级前的备份
docker compose exec -T postgres psql -U magicain -d magicain < backup_before_upgrade.sql

# 3. 回滚到旧版本镜像（如果需要）
docker load -i old_version/cloud_main.tar
docker compose up -d --force-recreate cloud

# 4. 验证回滚成功
docker compose logs cloud
```

## 目录结构

```
standalone/
├── conf/              # Nginx 配置文件
│   └── standalone.conf
├── cert/              # SSL 证书目录
├── logs/              # 日志目录（自动创建）
│   └── nginx/
├── build/             # 构建输出目录（自动创建，已 gitignore）
│   └── standalone-deployment-YYYYMMDD-HHMMSS.zip
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
├── database/          # 数据库初始化脚本
│   ├── postgresql/    # PostgreSQL 初始化脚本
│   │   ├── 01-ruoyi-vue-pro.sql
│   │   ├── 02-quartz.sql
│   │   └── 03-pg-chatbi.sql
│   └── mysql/         # MySQL 脚本（备用）
├── scripts/           # 部署脚本
│   ├── install-infra.sh              # 安装 Docker
│   ├── docker-save.sh                # 拉取并保存镜像（多架构）
│   ├── build-deployment-package.sh   # 一键构建部署包
│   └── install-and-start.sh          # 一键安装启动
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

---

## 更新最佳实践

### 版本更新策略

由于使用 `main` tag（无具体版本号），建议采用以下更新策略：

#### 1. 小版本更新（无 Schema 变更）

**场景**：应用 Bug 修复、性能优化等，数据库结构不变

```bash
# 步骤 1: 备份数据（可选但推荐）
docker compose exec postgres pg_dump -U magicain magicain > backup_before_update.sql

# 步骤 2: 获取最新部署包（开发机构建）
# 步骤 3: 传输到服务器并解压覆盖
unzip -o standalone-deployment-*.zip

# 步骤 4: 运行更新脚本
cd standalone
sudo bash scripts/install-and-start.sh

# 步骤 5: 验证服务
docker compose ps
docker compose logs -f cloud
```

#### 2. 大版本更新（有 Schema 变更）

**场景**：数据库结构变更、新增表/字段等

```bash
# 步骤 1: 完整备份（必需）
docker compose exec postgres pg_dump -U magicain magicain > backup_v1.0_$(date +%Y%m%d).sql

# 步骤 2: 停止服务
docker compose stop cloud

# 步骤 3: 执行数据库升级脚本
docker compose exec postgres psql -U magicain -d magicain -f /path/to/upgrade.sql

# 步骤 4: 验证数据库升级
docker compose exec postgres psql -U magicain -d magicain -c "\dt"

# 步骤 5: 更新应用（新镜像）
sudo bash scripts/install-and-start.sh

# 步骤 6: 验证服务
docker compose logs -f cloud
```

### 更新前检查清单

- [ ] 查看版本更新说明（是否有 Schema 变更）
- [ ] 备份 PostgreSQL 数据库
- [ ] 备份 Redis 数据（如果重要）
- [ ] 记录当前运行的镜像版本
- [ ] 准备回滚方案（保留旧版本镜像）
- [ ] 通知用户系统维护时间窗口

### 更新后验证清单

- [ ] 检查所有容器运行状态：`docker compose ps`
- [ ] 检查应用日志无异常：`docker compose logs cloud`
- [ ] 测试 API 接口可用性
- [ ] 验证前端页面加载正常
- [ ] 检查数据库连接正常
- [ ] 验证关键业务功能

### 回滚方案

如果更新后出现问题，快速回滚步骤：

```bash
# 1. 停止新版本服务
docker compose stop

# 2. 恢复数据库（如果执行了 Schema 升级）
docker compose exec -T postgres psql -U magicain -d magicain < backup_before_update.sql

# 3. 加载旧版本镜像
docker load -i old_version/cloud_main.tar
docker load -i old_version/admin-ui_main.tar
# ... 其他镜像

# 4. 启动旧版本
docker compose up -d --force-recreate

# 5. 验证回滚成功
docker compose ps
docker compose logs -f cloud
```

### 镜像版本管理建议

为了更好地管理版本，建议：

1. **保留旧版本镜像**
   ```bash
   # 在更新前，导出当前镜像作为备份
   docker save cloud:main > backup/cloud_main_v1.0.tar
   ```

2. **使用具体版本 tag**（如果可能）
   ```yaml
   # 推荐：使用具体版本
   image: magictensor/cloud:v1.2.3
   
   # 不推荐：使用 main tag（难以回滚）
   image: magictensor/cloud:main
   ```

3. **记录部署历史**
   ```bash
   # 创建部署日志
   echo "$(date): Deployed version $(docker images | grep cloud:main)" >> deployment.log
   ```
