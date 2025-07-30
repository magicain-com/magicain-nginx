# Magicain Nginx Reverse Proxy

A Docker nginx reverse proxy that enables multiple web applications to share localStorage through path-based routing.

## Deployment

### Prerequisites
- Docker and Docker Compose
- Two web applications running on ports 8080 and 8081

### Quick Start

1. Start your web applications:
   ```bash
   # Admin app on port 8080 with base path /admin
   # Agent app on port 8081 with base path /agent
   ```

2. Deploy the proxy:
   ```bash
   docker-compose up -d
   ```

3. Access your applications:
   - Admin: http://localhost/admin/
   - Agent: http://localhost/agent/

## Usage

The proxy routes requests as follows:
- `/admin/*` → `localhost:8080`
- `/agent/*` → `localhost:8081`

Both applications will share localStorage since they're served from the same domain.

## Configuration

To change upstream ports, edit `conf/local.conf`:

```nginx
upstream admin_app {
    server host.docker.internal:8080;  # Change port here
}

upstream agent_app {
    server host.docker.internal:8081;  # Change port here
}
```

Then restart: `docker-compose restart`

## Commands

```bash
# Deploy
docker-compose up -d

# View logs
docker logs magicain-nginx-nginx-proxy-1

# Restart
docker-compose restart

# Stop
docker-compose down
```