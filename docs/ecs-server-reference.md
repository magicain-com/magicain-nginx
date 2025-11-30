## 阿里云 ECS 拆分部署参考

下表记录当前 4 台运行中的 ECS 实例及其职责，方便在多机部署时查阅。若后续变更实例规格或 IP，请同步更新本文件。

| 名称 | 实例 ID | 用途 | 规格 | 公网 IP | 私网 IP | Compose 文件 |
| --- | --- | --- | --- | --- | --- | --- |
| infra-1 | i-bp1dgel8mk3laj6lqfqb | PostgreSQL（PgVector） | ecs.g9i.large · 2 vCPU · 8 GiB · 1 Mbps | 47.111.190.157 | 172.27.181.227 | `docker-compose.infra-1.yml` |
| infra-2 | i-bp1dgel8mk3laj6lqfqc | Elasticsearch 单独节点 | ecs.g9i.large · 2 vCPU · 8 GiB · 1 Mbps | 47.110.91.72 | 172.27.181.228 | `docker-compose.infra-2.yml` |
| app-backend | i-bp1dgel8mk3laj6lqfqa | Redis + Cloud 后端 | ecs.g9i.large · 2 vCPU · 8 GiB · 1 Mbps | 118.31.122.158 | 172.27.181.229 | `docker-compose.app-backend.yml` |
| app-frontend | i-bp13bkw0jug3irsl1ku4 | Nginx + 3 个前端 UI | ecs.u1-c1m2.large · 2 vCPU · 4 GiB · 5 Mbps | 47.111.178.112 | 172.27.181.226 | `docker-compose.app-frontend.yml` |

### 使用建议

- 每台服务器拉取同一仓库代码后，仅运行对应列中的 compose 文件，例如 `docker compose -f docker-compose.infra-1.yml up -d`。
- 建议在各节点上设置相同的 `.env`（或最少包含端口/密码），并按需要覆盖公网暴露端口。
- 可以把私网 IP 写入 `config/nginx/prod.conf` 或上游服务的环境变量中，避免跨机通信走公网。
- 若新增实例（例如 ClickHouse / 监控），沿用本表格式记录，以便团队成员查看。

