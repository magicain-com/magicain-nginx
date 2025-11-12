#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Navigate to the project root
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
# Path to the Docker RPM packages
DOCKER_RPM_DIR="$PROJECT_ROOT/docker/infra"

echo "================================"
echo "Docker Installation Script"
echo "================================"
echo ""

# Check if RPM directory exists
if [ ! -d "$DOCKER_RPM_DIR" ]; then
    echo "❌ Error: RPM directory not found at $DOCKER_RPM_DIR"
    exit 1
fi

echo "📦 Installing Docker packages from: $DOCKER_RPM_DIR"
echo ""

# Install Docker RPM packages
echo "⏳ Installing Docker RPM packages..."
cd "$DOCKER_RPM_DIR"
if sudo rpm -ivh containerd.io-*.rpm docker-ce-*.rpm docker-ce-cli-*.rpm docker-compose-plugin-*.rpm; then
    echo "✅ Docker packages installed successfully"
else
    echo "❌ Failed to install Docker packages"
    exit 1
fi

echo ""
echo "🔧 Enabling and starting Docker service..."
if sudo systemctl enable --now docker; then
    echo "✅ Docker service enabled and started"
else
    echo "❌ Failed to enable/start Docker service"
    exit 1
fi

echo ""
echo "🔍 Verifying Docker installation..."
echo ""
echo "Docker version:"
docker version

echo ""
echo "Docker Compose version:"
docker compose version

echo ""
echo "================================"
echo "✅ Docker installation completed!"
echo "================================"