#!/usr/bin/env bash

# Local nginx-only runner for quick debugging.
# Builds the Dockerfile at repo root and starts a container that
# serves using conf/local.conf. Existing containers/images are removed first.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="magicain-nginx-local"
CONTAINER_NAME="magicain-nginx-local"
HOST_PORT="${HOST_PORT:-8080}"

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
  "${IMAGE_NAME}"

echo ""
echo "✅ Local nginx started."
echo "   - Container: ${CONTAINER_NAME}"
echo "   - Image:     ${IMAGE_NAME}"
echo "   - Access:    http://localhost:${HOST_PORT}/"
echo ""
echo "To stop: docker rm -f ${CONTAINER_NAME}"

