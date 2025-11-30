# Magicain AI Agent System

A comprehensive Docker Compose orchestration for a complete AI agent platform including frontend applications, backend services, databases, and monitoring infrastructure.

## Overview

This project provides a complete development and production environment including:

- Nginx reverse proxy for unified access
- 3 frontend applications (admin, agent, chat)
- Java Spring Boot backend with dual API endpoints
- PostgreSQL database with PgVector for vector search
- Redis for caching and sessions
- Elasticsearch for full-text search
- Langfuse for AI agent monitoring and tracing
- Prometheus and Grafana for system monitoring

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- At least 8GB RAM available for all services
- Ports 80, 3000, 3001, 5432, 6379, 8080, 9090, 9200 available

### Development Setup

1. **Clone and navigate to the project:**
   ```bash
   cd magicain-nginx
   ```

2. **Set up environment variables (optional for development):**
   ```bash
   cp .env.example .env
   # Edit .env with your Docker registry credentials if using private images
   ```

3. **Start all services (recommended method):**
   ```bash
   ./scripts/start-dev.sh
   ```
   
   **Or manually:**
   ```bash
   # Login to Docker registry (if needed)
   ./scripts/docker-login.sh
   
   # Start services
   docker compose up -d
   ```

3. **Wait for services to initialize (check logs):**
   ```bash
   docker compose logs -f postgres
   # Wait for "database system is ready to accept connections"
   ```

4. **Start your development servers (optional - for external development):**
   - Admin frontend on port 8080 with base path `/admin`
   - Agent frontend on port 8081 with base path `/agent`  
   - Chat frontend on port 8082 with base path `/chat`
   - Java backend on port 8080 (or use the containerized version)

5. **Access your applications:**
   - **Admin:** http://localhost/admin/
   - **Agent:** http://localhost/agent/
   - **Chat:** http://localhost/chat/
   - **Agent UI:** http://localhost:8001/ (containerized frontend)
   - **Admin API:** http://localhost/admin-api/
   - **General API:** http://localhost/api/
   - **Grafana:** http://localhost:3001/ (admin/admin123)
   - **Langfuse:** http://localhost:3000/
   - **Prometheus:** http://localhost:9090/

### Test Environment Setup

```bash
# Recommended method
./scripts/start-test.sh

# Or manually
docker compose -f docker-compose.yml -f docker-compose.test.yml up -d

# Access via test domain (configure your hosts file)
echo "127.0.0.1 test.magicain.local" | sudo tee -a /etc/hosts
```

### Production Deployment

```bash
# Recommended method
./scripts/start-prod.sh

# Or manually:
# 1. Set up environment variables
cp .env.example .env
# Edit .env with your production values including Docker registry credentials

# 2. Deploy to production
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Service Architecture

### Frontend Layer
- **Nginx Reverse Proxy**: Single entry point routing all requests
- **Admin Frontend**: Management interface for AI agents and users
- **Agent Frontend**: AI agent interaction interface  
- **Chat Frontend**: Real-time chat interface with AI agents

### Backend Layer
- **Spring Boot API**: Dual endpoint structure (`/admin-api/`, `/api/`)
- **PostgreSQL + PgVector**: Primary database with vector search
- **Redis**: Session storage and caching
- **Elasticsearch**: Document indexing and search

### Monitoring & Operations
- **Langfuse**: AI agent execution monitoring and tracing
- **Prometheus**: Metrics collection from all services
- **Grafana**: Dashboards and alerting
- **Node Exporter**: System metrics

## Split Server Deployment

To match production resource planning, the stack is now broken into smaller Compose bundles that can run on dedicated hosts or clusters:

- `docker-compose.infra-1.yml`: PostgreSQL (PgVector) only.
- `docker-compose.infra-2.yml`: Elasticsearch only.
- `docker-compose.app-backend.yml`: Redis + `cloud` 后端服务，Redis 已从基础设施包中移出。
- `docker-compose.app-frontend.yml`: Nginx 反向代理与 3 个前端 UI（admin / agent / user）。
- ClickHouse 在拆分方案中暂不部署，如需开启可在单独服务器沿用旧配置。
- 阿里云 ECS 机器与 compose 的映射记录在 `docs/ecs-server-reference.md`，可用于多人协同参考。
- GitHub Actions 的四套对应 CD 脚本详见 `docs/github-actions-cd.md`。
- `config/spring/application-prod.yml` 会被挂载到 cloud 容器的 `/config/application-prod.yml`，通过 `.env` 中的 `POSTGRES_HOST`、`ELASTICSEARCH_HOST` 等变量来注入跨机器的 IP/端口。

示例启动方式：

```bash
# Infra-1 server (PostgreSQL)
docker compose -f docker-compose.infra-1.yml up -d

# Infra-2 server (Elasticsearch)
docker compose -f docker-compose.infra-2.yml up -d

# Backend server (Redis + Cloud)
docker compose -f docker-compose.app-backend.yml up -d

# Frontend server (Nginx + 3 UIs)
docker compose -f docker-compose.app-frontend.yml up -d
```

所有 compose 文件仍沿用 `.env` 中的变量定义，按需覆盖端口或凭据即可。

示例 `.env`（新增变量）：

```
POSTGRES_HOST=172.27.181.227
ELASTICSEARCH_HOST=172.27.181.228
```

Cloud 服务会将这些变量注入 `config/spring/application-prod.yml`，因此无需在文件中硬编码 IP。

## Database Schema

The PostgreSQL database includes:
- **AI Agents**: Configuration and management
- **Chat System**: Sessions and message history
- **Vector Embeddings**: For RAG (Retrieval Augmented Generation)
- **User Management**: Authentication and authorization
- **Monitoring**: Custom metrics and API usage tracking

Pre-configured with sample data including demo users and AI agents.

## Environment Configuration

- **Local Development** (`config/nginx/local.conf`): Routes to external dev servers
- **Test Environment** (`config/nginx/test.conf`): Routes to test infrastructure  
- **Production** (`config/nginx/prod.conf`): SSL, load balancing, security headers

## Common Development Commands

### Service Management
```bash
# Development (automatic with override)
docker compose up -d
docker compose logs -f
docker compose down

# Test Environment  
docker compose -f docker-compose.yml -f docker-compose.test.yml up -d
docker compose -f docker-compose.yml -f docker-compose.test.yml logs -f
docker compose -f docker-compose.yml -f docker-compose.test.yml down

# Production Environment
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
docker compose -f docker-compose.yml -f docker-compose.prod.yml logs -f
docker compose -f docker-compose.yml -f docker-compose.prod.yml down

# Start specific services (any environment)
docker compose up -d postgres redis nginx-proxy

# Stop and remove all data (WARNING: destructive)
docker compose down -v
```

### Database Operations
```bash
# Connect to database
docker compose exec postgres psql -U magicain -d magicain

# Run database migrations
docker compose exec postgres psql -U magicain -d magicain -f /docker-entrypoint-initdb.d/migration.sql

# Backup database
docker compose exec postgres pg_dump -U magicain magicain > backup.sql
```

### Monitoring
```bash
# Check service health
docker compose ps

# View Prometheus targets
curl http://localhost:9090/api/v1/targets

# Access Grafana dashboards
open http://localhost/grafana/
```

## Development Workflow

1. **Infrastructure First**: Start databases and monitoring
2. **Backend Services**: Start or develop your Java backend
3. **Frontend Development**: Run your frontend dev servers
4. **Proxy Last**: Start nginx to tie everything together

This allows you to develop individual components while having full system integration.

## Production Deployment

For production, modify the docker-compose.yml to:
- Use specific image tags instead of `latest`
- Configure proper secrets and environment variables
- Enable SSL certificates
- Set up proper backup strategies
- Configure external monitoring and alerting

## Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check Docker resources
docker system df
docker system prune

# Check port conflicts
netstat -tlnp | grep :80
```

**Database connection issues:**
```bash
# Test database connectivity
docker compose exec backend curl http://localhost:8080/actuator/health
```

**Memory issues:**
- Elasticsearch requires significant RAM; consider adjusting `ES_JAVA_OPTS`
- Monitor with: `docker stats`

**Frontend assets not loading:**
- Verify dev servers are running on correct ports
- Check nginx configuration for proper upstream definitions

For detailed troubleshooting, monitoring, and configuration guidance, see [CLAUDE.md](./CLAUDE.md).