#!/bin/bash

# Docker Registry Login Script
# This script handles authentication to private Docker registries

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Check if registry credentials are provided
if [ -z "$DOCKER_REGISTRY_USERNAME" ] || [ -z "$DOCKER_REGISTRY_PASSWORD" ] || [ -z "$DOCKER_REGISTRY_URL" ]; then
    echo "Warning: Docker registry credentials not found in .env file"
    echo "Please set DOCKER_REGISTRY_USERNAME, DOCKER_REGISTRY_PASSWORD, and DOCKER_REGISTRY_URL"
    echo "Attempting to start services without private registry authentication..."
    exit 0
fi

# Login to Docker registry
echo "Logging into Docker registry: $DOCKER_REGISTRY_URL"
echo "$DOCKER_REGISTRY_PASSWORD" | docker login "$DOCKER_REGISTRY_URL" -u "$DOCKER_REGISTRY_USERNAME" --password-stdin

if [ $? -eq 0 ]; then
    echo "✅ Successfully logged into Docker registry"
else
    echo "❌ Failed to login to Docker registry"
    exit 1
fi