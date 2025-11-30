## GitHub Actions CD

本仓库提供 4 份 GitHub Actions Workflow，对应四台 ECS 主机的分布式部署：

| Workflow | Compose 文件 | 服务器 | 默认触发 |
| --- | --- | --- | --- |
| `.github/workflows/deploy-infra-1.yml` | `docker-compose.infra-1.yml` | `infra-1`（PostgreSQL） | 推送 `latest` 或 `x.x.x` tag、手动 `workflow_dispatch` |
| `.github/workflows/deploy-infra-2.yml` | `docker-compose.infra-2.yml` | `infra-2`（Elasticsearch） | 同上 |
| `.github/workflows/deploy-app-backend.yml` | `docker-compose.app-backend.yml` | `app-backend`（Redis + Cloud） | 同上 |
| `.github/workflows/deploy-app-frontend.yml` | `docker-compose.app-frontend.yml` | `app-frontend`（Nginx + 3x UI） | 同上 |

### 部署逻辑

每个 Workflow 执行以下步骤：

1. `actions/checkout` 拉取当前仓库。
2. 在构建机上将 `.env`（来自 `ENV_FILE` secret）与 `config/` 目录打包成 `config-bundle.tar.gz`。
3. 通过 `appleboy/scp-action` 上传该 tar 包至目标 ECS。
4. 通过 `appleboy/ssh-action` 登录目标 ECS，解压覆盖 `.env`/`config`，随后执行 `docker compose -f <compose> pull && docker compose -f <compose> up -d --remove-orphans`。

这样可以保证每台机器的 `.env` 与配置文件保持最新，同时镜像依旧从 registry 拉取，本地仍可保留证书等敏感信息。

### 必需 Secrets

请在 GitHub 仓库的 **Settings → Secrets and variables → Actions** 中配置以下条目：

| Secret | 用途 |
| --- | --- |
| `INFRA1_HOST` | infra-1 公网或私网可达 IP（建议放在仓库 Variables） |
| `INFRA1_REMOTE_PATH` | 服务器上的项目路径（如 `/opt/magicain`） |
| `INFRA2_HOST` | infra-2 IP |
| `INFRA2_REMOTE_PATH` | infra-2 项目路径 |
| `APP_BACKEND_HOST` | app-backend IP |
| `APP_BACKEND_REMOTE_PATH` | app-backend 项目路径 |
| `APP_FRONTEND_HOST` | app-frontend IP |
| `APP_FRONTEND_REMOTE_PATH` | app-frontend 项目路径 |
| `SSH_USER` | 四台服务器共用的 SSH 用户名 |
| `SSH_KEY` | 四台服务器共用的私钥（PEM 文本） |
| `ENV_FILE` | `.env` 文件的完整内容（多行字符串） |

> 建议将 `*_HOST`/`*_REMOTE_PATH` 放在 **Actions Variables**，方便团队查看 IP；而 `SSH_USER`、`SSH_KEY`、`ENV_FILE` 等敏感信息继续使用 Secrets。

### 触发方式

- **自动触发**：创建/更新 `latest` 或形如 `1.2.3` 的 tag 时自动部署（四个 workflow 都监听）。
- **手动触发**：在 **Actions** 页面选择 Workflow，点击 *Run workflow*。

> 版本 tag 使用 `x.x.x`（例如 `1.0.0`）的形式即可被匹配；如需其它命名规则，可在 workflow 中调整 `tags` 模式。

### 首次准备步骤

1. 在每台服务器上安装 Docker / Docker Compose。
2. 预先创建 `docker compose` 使用的 `.env`、证书、持久化目录等本地文件。
3. 使用与 Secrets 相同的凭证手动运行一次：
   ```bash
   git clone https://github.com/jackjack-7/magicain-nginx.git /opt/magicain
   cd /opt/magicain
   docker compose -f docker-compose.infra-1.yml up -d
   ```
   后续 GitHub Actions 会自动更新同一路径。
4. **重要**：当前 workflow 只覆盖 `.env` 与 `config/`，不会再次 `git pull`，因此首次部署时需手动将仓库拷贝到 `*_REMOTE_PATH`。

如需扩展到更多服务器，只需拷贝现有 workflow，替换 compose 文件与 secrets 名称即可。

