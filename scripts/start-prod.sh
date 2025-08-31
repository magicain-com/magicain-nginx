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
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Check service status
echo "📊 Service Status:"
docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps

echo ""
echo "✅ Production environment started!"
echo ""
echo "🌐 Access Points:"
echo "   - Main application: https://magicain.ai/"
echo "   - (SSL certificates must be configured)"
echo ""
echo "📋 Useful commands:"
echo "   - View logs: docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f"
echo "   - Stop services: docker-compose -f docker-compose.yml -f docker-compose.prod.yml down"
echo ""
echo "⚠️  Production Security Reminders:"
echo "   - Change all default passwords in .env"
echo "   - Configure SSL certificates"
echo "   - Set up regular database backups"
echo "   - Monitor resource usage"