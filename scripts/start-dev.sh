#!/bin/bash

# Development Environment Startup Script
# Handles Docker login and starts all services

echo "🚀 Starting Magicain AI System - Development Environment"

# Change to project directory
cd "$(dirname "$0")/.."

# Run Docker login script
./scripts/docker-login.sh

if [ $? -ne 0 ]; then
    echo "⚠️  Docker login failed, but continuing with startup..."
fi

# Start services
echo "🔧 Starting all development services..."
docker compose up -d

# Check service status
echo "📊 Service Status:"
docker compose ps

echo ""
echo "✅ Development environment started!"
echo ""
echo "🌐 Access Points:"
echo "   - Admin: http://localhost/admin/"
echo "   - Agent: http://localhost/agent/"
echo "   - Chat: http://localhost/chat/"
echo "   - Agent UI: http://localhost:8001/"
echo "   - Grafana: http://localhost:3001/ (admin/admin123)"
echo "   - Langfuse: http://localhost:3000/"
echo "   - Prometheus: http://localhost:9090/"
echo ""
echo "📋 Useful commands:"
echo "   - View logs: docker compose logs -f"
echo "   - Stop services: docker compose down"
echo "   - Restart: docker compose restart [service-name]"