# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a comprehensive Docker Compose orchestration project for the Magicain AI Agent system. It includes an nginx reverse proxy, multiple frontend applications, a Java backend, databases, monitoring, and AI agent tracking services.

## Architecture

The system consists of the following components:

### Frontend Applications (External Development Servers)
- **Admin app**: `/admin/*` → `host.docker.internal:8080`
- **Agent app**: `/agent/*` → `host.docker.internal:8081`  
- **Chat app**: `/chat/*` → `host.docker.internal:8082`

### Backend Services (Docker Containers)
- **Java Backend**: Spring Boot application with two main API endpoints
  - `/admin-api/*` → Backend admin operations
  - `/api/*` → General API endpoints
- **PostgreSQL with PgVector**: Main database with vector search capabilities
- **Redis**: Caching and session storage
- **Elasticsearch**: Full-text search and analytics
- **Langfuse**: AI agent monitoring and tracing
- **Prometheus**: Metrics collection
- **Grafana**: Metrics visualization and dashboards
- **Node Exporter**: System metrics

### Network Architecture
- All services run on a custom bridge network `magicain-network`
- Nginx serves as the single entry point routing to appropriate services
- Frontend apps run externally for development, containers in production
- Backend services communicate internally via Docker networking

## Environment Configuration

The project supports multiple environments with different nginx configurations:

- **Local development**: `config/nginx/local.conf` - Routes to external dev servers
- **Test environment**: `config/nginx/test.conf` - Routes to test servers
- **Production environment**: `config/nginx/prod.conf` - SSL, load balancing, security headers

## Service Endpoints

When running locally, access services via:

- **Frontend Applications:**
  - Admin: `http://localhost/admin/`
  - Agent: `http://localhost/agent/`
  - Chat: `http://localhost/chat/`

- **API Endpoints:**
  - Admin API: `http://localhost/admin-api/`
  - General API: `http://localhost/api/`

- **Monitoring Services:**
  - Langfuse: `http://localhost/langfuse/`
  - Grafana: `http://localhost/grafana/` (admin/admin123)
  - Prometheus: `http://localhost/prometheus/`

- **Direct Service Access:**
  - Backend: `http://localhost:8080`
  - PostgreSQL: `localhost:5432`
  - Redis: `localhost:6379`
  - Elasticsearch: `http://localhost:9200`
  - Langfuse: `http://localhost:3000`
  - Grafana: `http://localhost:3001`
  - Prometheus: `http://localhost:9090`

## Database Schema

The PostgreSQL database includes:

- **Schemas**: `ai_agents`, `chat`, `admin`, `monitoring`
- **PgVector Extension**: Enabled for vector similarity search
- **Sample Data**: Pre-loaded with demo users, agents, and conversations
- **Optimized Indexes**: Including HNSW vector indexes for fast similarity search

Key tables:
- `admin.users` - User management
- `ai_agents.agents` - AI agent configurations
- `chat.sessions` & `chat.messages` - Chat conversations
- `ai_agents.embeddings` - Vector embeddings for RAG
- `ai_agents.execution_logs` - AI agent execution tracking
- `monitoring.metrics` - Custom application metrics

## Development Commands

### Basic Operations
```bash
# Start all services
docker compose up -d

# Start specific services
docker compose up -d nginx-proxy backend postgres redis

# View logs for all services
docker compose logs -f

# View logs for specific service
docker compose logs -f backend

# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes data)
docker compose down -v

# Rebuild services after code changes
docker compose up -d --build
```

### Database Operations
```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U magicain -d magicain

# View database logs
docker compose logs -f postgres

# Backup database
docker compose exec postgres pg_dump -U magicain magicain > backup.sql

# Restore database
docker compose exec -T postgres psql -U magicain magicain < backup.sql
```

### Monitoring Operations
```bash
# View Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check Grafana health
curl http://localhost:3001/api/health

# View Langfuse metrics
curl http://localhost:3000/api/public/metrics
```

### Development Workflow

1. **Start Infrastructure Services:**
   ```bash
   docker compose up -d postgres redis elasticsearch langfuse prometheus grafana
   ```

2. **Start Your Development Servers:**
   - Admin frontend on port 8080 with base path `/admin`
   - Agent frontend on port 8081 with base path `/agent`  
   - Chat frontend on port 8082 with base path `/chat`
   - Java backend on port 8080 (or use containerized version)

3. **Start Nginx Proxy:**
   ```bash
   docker compose up -d nginx-proxy
   ```

4. **Access Applications:**
   - All frontends via `http://localhost/{app}/`
   - Monitoring via `http://localhost/{service}/`

### Configuration Changes

**Nginx Configuration:**
1. Modify files in `config/nginx/` directory
2. Run `docker compose restart nginx-proxy`
3. Check logs: `docker compose logs nginx-proxy`

**Monitoring Configuration:**
1. Update `monitoring/prometheus/prometheus.yml` for new metrics targets
2. Add dashboards to `monitoring/grafana/dashboards/`
3. Restart services: `docker compose restart prometheus grafana`

**Database Changes:**
1. Add migration scripts to `database/init/`
2. For existing databases, connect and run migrations manually
3. Restart: `docker compose restart postgres`

## Troubleshooting

### Service Health Checks
```bash
# Check if all services are running
docker compose ps

# Check service health
docker compose exec backend curl http://localhost:8080/actuator/health
docker compose exec postgres pg_isready -U magicain
```

### Common Issues

**Frontend Assets Not Loading:**
- Ensure development servers are running on correct ports
- Check nginx configuration for proper upstream definitions
- Verify WebSocket connections for hot reload

**Database Connection Issues:**
- Check if PostgreSQL is fully started: `docker compose logs postgres`
- Verify connection from backend: `docker compose logs backend`
- Test connection: `docker compose exec postgres psql -U magicain -d magicain -c "SELECT 1;"`

**Memory Issues:**
- Elasticsearch requires significant memory; adjust `ES_JAVA_OPTS` if needed
- Monitor Docker resource usage
- Consider reducing service replicas for development

**Port Conflicts:**
- Check for services already running on required ports
- Modify port mappings in docker-compose.yml if needed
- Use `docker compose port SERVICE` to check assigned ports

### Performance Optimization

**Vector Search Performance:**
- Ensure HNSW indexes are created on embedding columns
- Tune vector search parameters in database queries
- Monitor query performance via Grafana dashboards

**Monitoring Overhead:**
- Adjust Prometheus scrape intervals for production
- Limit Grafana dashboard refresh rates
- Archive old metrics data regularly

## Security Considerations

**Development Environment:**
- Default passwords are used for convenience
- All services are accessible without authentication
- Monitoring services expose metrics publicly

**Production Environment:**
- Change all default passwords
- Enable SSL/TLS with proper certificates
- Restrict monitoring service access to internal networks
- Enable authentication for all services
- Use secrets management for sensitive configuration