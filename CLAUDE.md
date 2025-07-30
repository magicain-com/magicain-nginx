# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Docker nginx reverse proxy project designed to enable multiple web applications to share localStorage by serving them through the same domain with different path prefixes. The proxy allows two separate development servers running on different ports to be accessed via `/admin` and `/agent` paths on localhost.

## Architecture

The nginx proxy runs in a Docker container and routes requests to development servers running on the host machine:

- **Admin app**: `/admin/*` → `host.docker.internal:8080`
- **Agent app**: `/agent/*` → `host.docker.internal:8081`

Key architectural decisions:
- Uses `host.docker.internal` to access development servers running outside Docker
- Configured with upstream definitions for clean proxy management
- WebSocket support enabled for development server features (hot reload, etc.)
- No trailing slash in `proxy_pass` to preserve full request paths

## Environment Configuration

The project is structured to support multiple environments:

- **Local development**: `conf/local.conf` (currently implemented)
- **Test environment**: `conf/test.conf` (planned)
- **Production environment**: `conf/prod.conf` (planned)

The Dockerfile copies the appropriate config file based on the environment.

## Development Commands

### Basic Operations
```bash
# Start the proxy (detached mode)
docker-compose up -d

# Restart the proxy (after config changes)
docker-compose restart

# Stop the proxy
docker-compose down

# View logs
docker logs magicain-nginx-nginx-proxy-1

# View recent logs
docker logs magicain-nginx-nginx-proxy-1 --tail 20
```

### Development Workflow
1. Start your development servers on ports 8080 and 8081 with base paths `/admin` and `/agent` respectively
2. Run `docker-compose up -d` to start the nginx proxy
3. Access applications via:
   - Admin app: `http://localhost/admin/`
   - Agent app: `http://localhost/agent/`

### Configuration Changes
After modifying nginx configuration files:
1. Run `docker-compose restart` to apply changes
2. Check logs if requests return 404 or other errors
3. Test upstream connectivity with: `docker exec magicain-nginx-nginx-proxy-1 curl -I http://host.docker.internal:PORT`

## Troubleshooting

### Asset Loading Issues
If Vite or other development assets fail to load, ensure:
- Development servers are configured with correct base paths
- Both servers are accessible on their respective ports
- WebSocket connections are working for hot reload features

### Docker Registry Issues
If image pulling fails, the issue may be with Docker registry mirrors. Try restarting Docker Desktop or switching to default registry settings.

### Path Configuration
The current setup expects development servers to handle their own base path routing. If servers expect different path structures, modify the `proxy_pass` directives in the nginx configuration accordingly.