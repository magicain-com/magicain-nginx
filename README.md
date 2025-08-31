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
   docker-compose up -d
   ```

3. **Wait for services to initialize (check logs):**
   ```bash
   docker-compose logs -f postgres
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
docker-compose -f docker-compose.yml -f docker-compose.test.yml up -d

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
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
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

## Database Schema

The PostgreSQL database includes:
- **AI Agents**: Configuration and management
- **Chat System**: Sessions and message history
- **Vector Embeddings**: For RAG (Retrieval Augmented Generation)
- **User Management**: Authentication and authorization
- **Monitoring**: Custom metrics and API usage tracking

Pre-configured with sample data including demo users and AI agents.

## Environment Configuration

- **Local Development** (`conf/local.conf`): Routes to external dev servers
- **Test Environment** (`conf/test.conf`): Routes to test infrastructure  
- **Production** (`conf/prod.conf`): SSL, load balancing, security headers

## Common Development Commands

### Service Management
```bash
# Development (automatic with override)
docker-compose up -d
docker-compose logs -f
docker-compose down

# Test Environment  
docker-compose -f docker-compose.yml -f docker-compose.test.yml up -d
docker-compose -f docker-compose.yml -f docker-compose.test.yml logs -f
docker-compose -f docker-compose.yml -f docker-compose.test.yml down

# Production Environment
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down

# Start specific services (any environment)
docker-compose up -d postgres redis nginx-proxy

# Stop and remove all data (WARNING: destructive)
docker-compose down -v
```

### Database Operations
```bash
# Connect to database
docker-compose exec postgres psql -U magicain -d magicain

# Run database migrations
docker-compose exec postgres psql -U magicain -d magicain -f /docker-entrypoint-initdb.d/migration.sql

# Backup database
docker-compose exec postgres pg_dump -U magicain magicain > backup.sql
```

### Monitoring
```bash
# Check service health
docker-compose ps

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
docker-compose exec backend curl http://localhost:8080/actuator/health
```

**Memory issues:**
- Elasticsearch requires significant RAM; consider adjusting `ES_JAVA_OPTS`
- Monitor with: `docker stats`

**Frontend assets not loading:**
- Verify dev servers are running on correct ports
- Check nginx configuration for proper upstream definitions

For detailed troubleshooting, monitoring, and configuration guidance, see [CLAUDE.md](./CLAUDE.md).