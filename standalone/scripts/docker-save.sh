#!/bin/bash

# Define the images to pack
IMAGES=(
  "crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/cloud:main"
  "crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/admin-ui:main"
  "crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/agent-ui:main"
  "crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/agent-ui:main-noda"
  "crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/user-ui:main"
  "docker.m.daocloud.io/nginx:1.25-alpine"
  "docker.m.daocloud.io/pgvector/pgvector:pg16"
  "docker.m.daocloud.io/redis:7-alpine"
)

# Get the script directory and set output path relative to standalone folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STANDALONE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$STANDALONE_DIR/docker/images"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Load environment variables from .env file if it exists
ENV_FILE="$STANDALONE_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    echo "📝 Loading environment variables from .env file..."
    export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)
fi

# Docker login if credentials are provided
if [ -n "$DOCKER_REGISTRY_USERNAME" ] && [ -n "$DOCKER_REGISTRY_PASSWORD" ] && [ -n "$DOCKER_REGISTRY_URL" ]; then
    echo "🔐 Logging into Docker registry: $DOCKER_REGISTRY_URL"
    if echo "$DOCKER_REGISTRY_PASSWORD" | docker login "$DOCKER_REGISTRY_URL" -u "$DOCKER_REGISTRY_USERNAME" --password-stdin > /dev/null 2>&1; then
        echo "✅ Successfully logged into Docker registry"
    else
        echo "⚠️  Warning: Failed to login to Docker registry"
        echo "    Continuing anyway, but private images may fail to pull..."
    fi
    echo ""
else
    echo "ℹ️  No Docker registry credentials found in .env file"
    echo "   If pulling private images fails, please set:"
    echo "   - DOCKER_REGISTRY_URL"
    echo "   - DOCKER_REGISTRY_USERNAME"
    echo "   - DOCKER_REGISTRY_PASSWORD"
    echo ""
fi

# Function to generate filename from image name
generate_filename() {
  local IMAGE=$1
  # Extract image name and tag, convert to valid filename
  local FILENAME=$(echo "$IMAGE" | sed 's|.*/||' | sed 's/:/_/g' | sed 's/\./-/g')
  echo "${FILENAME}.tar"
}

echo "================================"
echo "Docker Multi-Arch Image Packer"
echo "================================"
echo ""
echo "📦 Target platform: Multi-arch (AMD64/ARM64)"
echo "📁 Output directory: $OUTPUT_DIR"
echo ""

# Detect current system architecture
ARCH=$(uname -m)
echo "🖥️  System architecture: $ARCH"
echo ""

# Pull and save multi-arch images
echo "🔄 Pulling and saving multi-arch images..."
echo "ℹ️  Docker will automatically pull all architectures (AMD64 + ARM64)"
echo ""

SAVED_COUNT=0
TOTAL_COUNT=${#IMAGES[@]}

for IMAGE in "${IMAGES[@]}"; do
  echo "⏳ Pulling: $IMAGE"
  
  # 使用 --all-platforms 拉取所有架构（Docker 20.10+）
  # 如果不支持该参数，会fallback到默认行为
  if docker pull --all-platforms "$IMAGE" 2>/dev/null; then
    echo "✅ Successfully pulled (all platforms): $IMAGE"
  elif docker pull "$IMAGE"; then
    echo "✅ Successfully pulled (default platform): $IMAGE"
    echo "⚠️  Note: --all-platforms not supported, using default platform"
  else
    echo "❌ Failed to pull: $IMAGE"
    exit 1
  fi
  
  # Generate output filename
  OUTPUT_FILE="$OUTPUT_DIR/$(generate_filename "$IMAGE")"
  
  echo "💾 Saving to: $(basename "$OUTPUT_FILE")"
  if docker save -o "$OUTPUT_FILE" "$IMAGE"; then
    FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    echo "✅ Successfully saved: $(basename "$OUTPUT_FILE") ($FILE_SIZE)"
    ((SAVED_COUNT++))
  else
    echo "❌ Failed to save: $IMAGE"
    exit 1
  fi
  echo ""
done

echo "================================"
echo "📊 Summary"
echo "================================"
echo "✅ Successfully saved $SAVED_COUNT/$TOTAL_COUNT images"
echo ""
echo "Saved files:"
for IMAGE in "${IMAGES[@]}"; do
  FILENAME=$(generate_filename "$IMAGE")
  if [ -f "$OUTPUT_DIR/$FILENAME" ]; then
    FILE_SIZE=$(ls -lh "$OUTPUT_DIR/$FILENAME" | awk '{print $5}')
    echo "  - $FILENAME ($FILE_SIZE)"
  fi
done

# Calculate total size
TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" | awk '{print $1}')
echo ""
echo "📦 Total size: $TOTAL_SIZE"
echo ""
echo "================================"
echo "✅ Multi-arch image pack completed!"
echo "================================"
echo ""
echo "ℹ️  Images are multi-architecture and will work on both AMD64 and ARM64 systems"