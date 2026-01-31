# Magicain 私有化部署指南

> 适用于内网环境、无法访问公网 Docker 仓库的离线部署场景
>
> ⚠️ **本文档仅说明如何部署。如需构建部署包，请参考项目根目录的 [README.md](../README.md)**

## 📋 前提条件

在开始部署之前，请确保：
1. ✅ 已获取完整的 `standalone-deployment-*.zip` 部署包
2. ✅ 部署包已传输到目标服务器

> 💡 如需构建部署包，请参考项目根目录 [README.md](../README.md) 的 "Standalone Deployment" 章节

---

## 🚀 快速部署

### 1. 传输部署包

将部署包传输到目标服务器：

```bash
scp build/standalone-deployment-*.zip root@your-server-ip:/root/
```

### 2. 解压

在服务器上解压部署包：

```bash
ssh root@your-server-ip
cd /root
unzip standalone-deployment-*.zip
cd standalone
```

### 3. 一键安装

运行安装脚本，自动完成所有部署步骤：

```bash
sudo bash scripts/install-and-start.sh
```

脚本自动完成：
- ✅ 检测系统环境（AMD64/ARM64）
- ✅ 安装 Docker（如未安装）
- ✅ 加载所有镜像
- ✅ 创建数据目录
- ✅ 启动所有服务

### 4. 访问服务

```
HTTP:      http://server-ip
HTTPS:     https://server-ip
Admin UI:  http://server-ip:8080
Agent UI:  http://server-ip:8081
User UI:   http://server-ip:8082
Cloud API: http://server-ip:48080
```

---

## 🔄 更新应用

更新流程与首次部署类似：

### 1. 获取新版本部署包

从开发团队获取最新的 `standalone-deployment-*.zip` 文件。

> 💡 如需自行构建，请参考项目根目录 [README.md](../README.md)

### 2. 传输并解压

```bash
scp build/standalone-deployment-*.zip root@server-ip:/root/
ssh root@server-ip
cd /root
unzip -o standalone-deployment-*.zip  # -o 覆盖现有文件
```

### 3. 运行更新脚本

```bash
cd standalone
sudo bash scripts/install-and-start.sh
```

> 💡 **数据保留**：更新脚本会自动保留 PostgreSQL 和 Redis 的数据，无需担心数据丢失。

> 💡 **镜像更新**：脚本会强制重建容器以使用最新的 Docker 镜像。

**重要说明**：
- ✅ 数据库数据保持不变
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
|---|---|
| **CPU** | AMD64 (x86_64) 或 ARM64 (aarch64)，推荐 4 核+ |
| **内存** | 至少 8GB，推荐 16GB+ |
| **磁盘** | 至少 50GB 可用空间 |
| **操作系统** | Linux (麒麟 V10、CentOS 7+、Ubuntu 20.04+) |
| **网络** | 可访问互联网（用于拉取镜像）或已准备好离线镜像包 |

> 💡 **多架构支持**：镜像支持 AMD64 和 ARM64，自动适配，无需手动选择

---

## ⚠️ 重要注意事项

### 1. PostgreSQL 数据库密码

- `.env` 文件中的 `POSTGRES_PASSWORD` 必须与 Java 应用配置中的密码一致（默认为 `magicain123`）。
- 生产环境强烈建议修改为更安全的强密码，并同步更新 Java 应用配置。

### 2. 麒麟 V10 系统网络问题

- 在麒麟 V10 系统上，可能需要额外安装 `iptables-nft`，否则 Docker 网络启动可能报错 `modprobe: nf_tables module not found`。
- 解决方法：`sudo yum install iptables iptables-nft -y`

### 3. PostgreSQL 数据库更新机制

- **首次安装**：数据目录为空时，会自动执行 `database/postgresql/*.sql` 初始化脚本。
- **后续更新**：数据目录已存在时，**初始化脚本不会重新执行**，所有数据保持不变。
- **Schema 升级**：如果需要升级数据库结构，必须**手动执行增量 SQL 脚本**。

### 4. Docker 镜像更新机制（`IMAGE_TAG`）

- 镜像使用 `IMAGE_TAG` 控制版本（默认 `latest`）。
- `install-and-start.sh` 支持版本参数：`--version 1.2.3`（或直接传 `1.2.3`）。
- `docker compose` 会读取 `.env` 中的 `IMAGE_TAG` 来拉取对应版本镜像。
- `install-and-start.sh` 会使用 `docker compose down --remove-orphans` 和 `docker compose up -d --force-recreate` 确保容器使用新镜像。

---

## 🔥 常见问题快速解决

| 问题 | 解决方法 |
|---|---|
| **端口被占用** | `sudo netstat -tlnp` 检查，停止占用进程或修改 `docker-compose.yml` 端口 |
| **数据目录权限** | `sudo chown -R 999:999 /data/postgres` 和 `/data/redis` |
| **镜像拉取失败** | 检查网络、使用离线包、检查仓库权限 |
| **数据库连接失败** | 检查 `.env` 密码、Docker 网络 DNS、PostgreSQL 启动状态、防火墙 |
| **服务无法启动** | `docker compose logs [service-name]` 查看日志，检查系统资源 |

---

## 📚 详细文档

### 1. 数据备份与恢复

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

### 2. 数据库 Schema 升级

当应用版本更新需要升级数据库结构时，需要**手动执行增量 SQL 脚本**。

#### 准备升级脚本

创建增量升级脚本（例如 `upgrade_v2.0.sql`），包含 `ALTER TABLE`、`CREATE TABLE` 等语句。

#### 执行升级

```bash
# 方式一：从宿主机执行
cd /root/standalone
docker compose exec -T postgres psql -U magicain -d magicain < /path/to/upgrade_v2.0.sql

# 方式二：在容器内执行
docker compose exec postgres bash
psql -U magicain -d magicain << 'EOF'
-- 升级 SQL 语句
ALTER TABLE existing_table ADD COLUMN IF NOT EXISTS new_field VARCHAR(100);
EOF

# 方式三：使用临时挂载
cp upgrade_v2.0.sql database/postgresql/
docker compose exec postgres psql -U magicain -d magicain \
  -f /docker-entrypoint-initdb.d/upgrade_v2.0.sql
```

#### 升级后验证

```bash
docker compose exec postgres psql -U magicain -d magicain -c "\d table_name"
docker compose exec postgres psql -U magicain -d magicain -c "\dt"
```

#### 升级回滚

如果升级出现问题，可以停止服务，恢复数据库到升级前的备份，并回滚到旧版本镜像。

### 3. 更新策略详解

#### 小版本更新（无 Schema 变更）

- **场景**：应用 Bug 修复、性能优化等，数据库结构不变。
- **流程**：获取新部署包，传输到服务器，运行 `install-and-start.sh`。

#### 大版本更新（有 Schema 变更）

- **场景**：数据库结构变更、新增表/字段等。
- **流程**：
  1. 完整备份数据库。
  2. 停止 `cloud` 服务。
  3. 手动执行数据库升级脚本。
  4. 验证数据库升级。
  5. 运行 `install-and-start.sh` 更新应用。

#### 更新前检查清单

- [ ] 查看版本更新说明（是否有 Schema 变更）
- [ ] 备份 PostgreSQL 数据库
- [ ] 备份 Redis 数据（如果重要）
- [ ] 记录当前运行的镜像版本
- [ ] 准备回滚方案（保留旧版本镜像）
- [ ] 通知用户系统维护时间窗口

#### 更新后验证清单

- [ ] 检查所有容器运行状态：`docker compose ps`
- [ ] 检查应用日志无异常：`docker compose logs cloud`
- [ ] 测试 API 接口可用性
- [ ] 验证前端页面加载正常
- [ ] 检查数据库连接正常
- [ ] 验证关键业务功能

#### 回滚方案

如果更新后出现问题，快速回滚步骤：

```bash
# 1. 停止新版本服务
docker compose stop

# 2. 恢复数据库（如果执行了 Schema 升级）
docker compose exec -T postgres psql -U magicain -d magicain < backup_before_update.sql

# 3. 加载旧版本镜像
# docker load -i old_version/cloud_main.tar
# ... 其他镜像

# 4. 启动旧版本
docker compose up -d --force-recreate

# 5. 验证回滚成功
docker compose ps
docker compose logs -f cloud
```

### 4. 目录结构

```
standalone/
├── conf/              # Nginx 配置文件
│   └── standalone.conf
├── cert/              # SSL 证书目录
├── logs/              # 日志目录（自动创建）
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
├── database/          # 数据库初始化脚本
│   ├── postgresql/    # PostgreSQL 初始化脚本
│   │   ├── 01-ruoyi-vue-pro.sql
│   │   ├── 02-quartz.sql
│   │   └── 03-pg-chatbi.sql
│   └── mysql/         # MySQL 脚本（备用）
├── scripts/           # 部署脚本
│   ├── install-infra.sh              # 安装 Docker
│   └── install-and-start.sh          # 一键安装启动
├── docker-compose.yml # Docker Compose 配置
├── .env               # 环境变量配置
└── README.md          # 本文档
```

### 5. 镜像版本管理建议

为了更好地管理版本，建议：

1. **保留旧版本镜像**
   ```bash
   # 在更新前，导出当前镜像作为备份
   docker save crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/cloud:latest > backup/cloud_latest.tar
   ```

2. **使用具体版本 tag**
   ```yaml
   # 推荐：通过 IMAGE_TAG 统一控制版本
   IMAGE_TAG=1.2.3
   image: crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/cloud:${IMAGE_TAG}
   ```

3. **记录部署历史**
   ```bash
   # 创建部署日志
   echo "$(date): Deployed version ${IMAGE_TAG:-latest}" >> deployment.log
   ```

---

## 📞 技术支持

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
