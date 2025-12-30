#!/usr/bin/env bash

# Local nginx-only runner for quick debugging.
# Builds the Dockerfile at repo root and starts a container that
# serves using the nginx config specified in .env.local.
# Existing containers/images are removed first.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="magicain-nginx-local"
CONTAINER_NAME="magicain-nginx-local"

# Load configuration from .env.local
ENV_FILE="${PROJECT_ROOT}/.env.local"
if [ ! -f "${ENV_FILE}" ]; then
  echo "❌ Error: .env.local not found at ${ENV_FILE}"
  echo "   Please create .env.local with the following variables:"
  echo "   NGINX_CONFIG_FILE=config/nginx/local.conf"
  echo "   HOST_PORT=7070"
  exit 1
fi

# Source the .env.local file
set -a
source "${ENV_FILE}"
set +a

# Validate required variables
if [ -z "${NGINX_CONFIG_FILE:-}" ]; then
  echo "❌ Error: NGINX_CONFIG_FILE not set in .env.local"
  exit 1
fi

# Set defaults
HOST_PORT="${HOST_PORT:-7070}"

# Resolve absolute path to nginx config
NGINX_CONF_PATH="${PROJECT_ROOT}/${NGINX_CONFIG_FILE}"
if [ ! -f "${NGINX_CONFIG_FILE}" ]; then
  echo "❌ Error: Nginx config file not found at ${NGINX_CONF_PATH}"
  exit 1
fi

echo "📋 Configuration:"
echo "   - Nginx config: ${NGINX_CONFIG_FILE}"
echo "   - Host port:    ${HOST_PORT}"
echo ""

echo "🧹 Cleaning previous containers/images (if any)..."
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
  docker rm -f "${CONTAINER_NAME}" >/dev/null
  echo "   Removed container ${CONTAINER_NAME}"
fi

if docker images -q "${IMAGE_NAME}" >/dev/null 2>&1 && [ -n "$(docker images -q "${IMAGE_NAME}")" ]; then
  docker rmi -f "${IMAGE_NAME}" >/dev/null
  echo "   Removed image ${IMAGE_NAME}"
fi

echo "🛠  Building local nginx image (${IMAGE_NAME})..."
cd "${PROJECT_ROOT}"
docker build -t "${IMAGE_NAME}" .

echo "🚀 Starting container ${CONTAINER_NAME} on port ${HOST_PORT}..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p "${HOST_PORT}:80" \
  -v "${NGINX_CONF_PATH}:/etc/nginx/nginx.conf:ro" \
  "${IMAGE_NAME}"

echo ""
echo "✅ Local nginx started."
echo "   - Container:    ${CONTAINER_NAME}"
echo "   - Image:        ${IMAGE_NAME}"
echo "   - Config:       ${NGINX_CONFIG_FILE}"
echo "   - Access:       http://localhost:${HOST_PORT}/"
echo ""
echo "To stop:  docker rm -f ${CONTAINER_NAME}"
echo "To logs:  docker logs -f ${CONTAINER_NAME}"

