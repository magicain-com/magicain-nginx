#!/bin/bash

# Define the images to pack
IMAGES=(
  "crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/cloud:main-arm64"
  "crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/admin-ui:main-arm64"
  "crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/agent-ui:main-arm64"
  "crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/user-ui:main-arm64"
  "docker.m.daocloud.io/nginx:1.25-alpine"
  "docker.m.daocloud.io/pgvector/pgvector:pg16"
  "docker.m.daocloud.io/redis:7-alpine"
)

# Get the script directory and set output path relative to standalone folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STANDALONE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$STANDALONE_DIR/docker"
OUTPUT_FILE="$OUTPUT_DIR/chatbi-node1-pack_arm64.tar"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "================================"
echo "Docker ARM64 Image Packer"
echo "================================"
echo ""
echo "📦 Target platform: linux/arm64"
echo "📝 Output file: $OUTPUT_FILE"
echo ""

# Pull ARM64 images
echo "🔄 Pulling ARM64 images..."
echo ""

for IMAGE in "${IMAGES[@]}"; do
  echo "⏳ Pulling: $IMAGE"
  if docker pull --platform linux/arm64 "$IMAGE"; then
    echo "✅ Successfully pulled: $IMAGE"
  else
    echo "❌ Failed to pull: $IMAGE"
    exit 1
  fi
  echo ""
done

echo "================================"
echo "💾 Saving images to $OUTPUT_FILE..."
echo "================================"
echo ""

# Save all images to a tar file
if docker save -o "$OUTPUT_FILE" "${IMAGES[@]}"; then
  echo "✅ Successfully saved all images to $OUTPUT_FILE"
  
  # Display file size
  FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
  echo "📊 File size: $FILE_SIZE"
else
  echo "❌ Failed to save images"
  exit 1
fi

echo ""
echo "================================"
echo "✅ ARM64 image pack completed!"
echo "================================"