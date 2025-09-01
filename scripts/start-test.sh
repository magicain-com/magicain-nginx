#!/bin/bash

# Test Environment Startup Script
# Handles Docker login and starts test services

echo "🧪 Starting Magicain AI System - Test Environment"

# Change to project directory
cd "$(dirname "$0")/.."

# Run Docker login script
./scripts/docker-login.sh

if [ $? -ne 0 ]; then
    echo "⚠️  Docker login failed, but continuing with startup..."
fi

# Start test services
echo "🔧 Starting test environment services..."
docker compose -f docker-compose.yml -f docker-compose.test.yml up -d

# Check service status
echo "📊 Service Status:"
docker compose -f docker-compose.yml -f docker-compose.test.yml ps

echo ""
echo "✅ Test environment started!"
echo ""
echo "🌐 Access Points:"
echo "   - Main application: http://test.magicain.local/"
echo "   - (Configure /etc/hosts: 127.0.0.1 test.magicain.local)"
echo ""
echo "📋 Useful commands:"
echo "   - View logs: docker compose -f docker-compose.yml -f docker-compose.test.yml logs -f"
echo "   - Stop services: docker compose -f docker-compose.yml -f docker-compose.test.yml down"