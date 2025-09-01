#!/bin/bash

# Production Environment Startup Script
# Handles Docker login and starts production services

echo "🚀 Starting Magicain AI System - Production Environment"

# Change to project directory
cd "$(dirname "$0")/.."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "Please copy .env.example to .env and configure your production settings"
    exit 1
fi

# Run Docker login script
./scripts/docker-login.sh

if [ $? -ne 0 ]; then
    echo "❌ Docker login failed! Cannot start production without registry access."
    exit 1
fi

# Verify production directories exist
echo "🔧 Checking production data directories..."
sudo mkdir -p /data/{postgres,postgres-langfuse,redis,elasticsearch,clickhouse,prometheus,grafana}
sudo chown -R 1000:1000 /data/

# Start production services
echo "🔧 Starting production environment services..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Check service status
echo "📊 Service Status:"
docker compose -f docker-compose.yml -f docker-compose.prod.yml ps

echo ""
echo "✅ Production environment started!"
echo ""
echo "🌐 Production Access Points:"
echo ""
echo "📱 Frontend Applications (via HTTPS):"
echo "   - Admin Interface:    https://magictensor.ai/admin/"
echo "   - Agent Interface:    https://magictensor.ai/agent/"  
echo "   - Chat Interface:     https://magictensor.ai/chat/"
echo "   - Agent UI:           https://magictensor.ai/agent-ui/"
echo ""
echo "🔌 API Endpoints:"
echo "   - Admin API:          https://magictensor.ai/admin-api/"
echo "   - General API:        https://magictensor.ai/api/"
echo ""
echo "📊 Monitoring & Analytics (Internal Access Only):"
echo "   - Langfuse (AI Monitor): https://magictensor.ai/langfuse/"
echo "   - Grafana (Dashboards):  https://magictensor.ai/grafana/"
echo "   - Prometheus (Metrics):  https://magictensor.ai/prometheus/"
echo ""
echo "🔧 System Health:"
echo "   - Health Check:       https://magictensor.ai/health"
echo "   - System Status:      https://magictensor.ai/status"
echo ""
echo "⚠️  SSL Configuration Required:"
echo "   - SSL certificates must be configured in ./ssl/ directory"
echo "   - HTTP requests automatically redirect to HTTPS"
echo "   - All services accessible only via nginx proxy for security"
echo ""
echo "📋 Useful commands:"
echo "   - View logs: docker compose -f docker-compose.yml -f docker-compose.prod.yml logs -f"
echo "   - Stop services: docker compose -f docker-compose.yml -f docker-compose.prod.yml down"
echo ""
echo "⚠️  Production Security Reminders:"
echo "   - Change all default passwords in .env"
echo "   - Configure SSL certificates"
echo "   - Set up regular database backups"
echo "   - Monitor resource usage"