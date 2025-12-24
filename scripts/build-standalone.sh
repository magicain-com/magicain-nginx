#!/bin/bash

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STANDALONE_DIR="$PROJECT_ROOT/standalone"
BUILD_DIR="$PROJECT_ROOT/build"
OUTPUT_DIR="$STANDALONE_DIR/docker/images"

# 必须指定架构参数：--arch amd64 | --arch arm64
# 使用 skopeo 拉取镜像，支持跨架构打包（如在 Mac arm64 上打包 amd64 镜像）
TARGET_ARCH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch=*)
      TARGET_ARCH="${1#*=}"
      shift
      ;;
    --arch)
      TARGET_ARCH="$2"
      shift 2
      ;;
    *)
      echo -e "${YELLOW}⚠️  忽略未知参数: $1${NC}"
      shift
      ;;
  esac
done

if [ -z "$TARGET_ARCH" ]; then
  echo -e "${RED}❌ 必须指定架构参数: --arch amd64 | --arch arm64${NC}"
  echo ""
  echo "用法示例："
  echo "  bash scripts/build-standalone.sh --arch amd64   # 打包 x86_64 镜像"
  echo "  bash scripts/build-standalone.sh --arch arm64   # 打包 ARM64 镜像"
  exit 1
fi

case "$TARGET_ARCH" in
  amd64|arm64) ;;
  *)
    echo -e "${RED}❌ 无效架构: $TARGET_ARCH（仅支持 amd64 / arm64）${NC}"
    exit 1
    ;;
esac

PULL_LABEL="$TARGET_ARCH"
ZIP_ARCH_SUFFIX="$TARGET_ARCH"

# Docker 镜像列表
IMAGES=(
  "crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/cloud:main"
  "crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/admin-ui:main"
  "crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/agent-ui:main-noda"
  "crpi-yzbqob8e5cxd8omc.cn-hangzhou.personal.cr.aliyuncs.com/magictensor/user-ui:main"
  "docker.m.daocloud.io/nginx:1.25-alpine"
  "docker.m.daocloud.io/pgvector/pgvector:pg16"
  "docker.m.daocloud.io/redis:7-alpine"
)

# 生成带日期的文件名（包含架构后缀）
DATE_STAMP=$(date +%Y%m%d-%H%M%S)
PACKAGE_NAME="standalone-deployment-${ZIP_ARCH_SUFFIX}-${DATE_STAMP}.zip"
PACKAGE_PATH="$BUILD_DIR/$PACKAGE_NAME"

# Function to generate filename from image name
generate_filename() {
  local IMAGE=$1
  # Extract image name and tag, convert to valid filename
  local FILENAME=$(echo "$IMAGE" | sed 's|.*/||' | sed 's/:/_/g' | sed 's/\./-/g')
  echo "${FILENAME}.tar"
}

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Standalone Deployment Package Builder${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 步骤 1: 加载环境变量并检查工具
echo -e "${YELLOW}[1/4] 加载配置...${NC}"
echo ""

# 检查 skopeo 是否安装
if ! command -v skopeo &> /dev/null; then
    echo -e "${RED}❌ skopeo 未安装${NC}"
    echo ""
    echo "请先安装 skopeo："
    echo "  - macOS: brew install skopeo"
    echo "  - Ubuntu/Debian: sudo apt-get install skopeo"
    echo "  - CentOS/RHEL: sudo yum install skopeo"
    echo "  - Windows: 不支持，请使用 WSL 或 Mac/Linux 机器"
    echo ""
    echo "skopeo 用于跨架构拉取镜像，解决 Mac 上打包非本机架构镜像的问题。"
    exit 1
fi
echo -e "${GREEN}✅ skopeo 已安装: $(skopeo --version | head -1)${NC}"

ENV_FILE="$PROJECT_ROOT/.env.standalone"
SKOPEO_CREDS=""
if [ -f "$ENV_FILE" ]; then
    echo "📝 Loading environment variables from .env.standalone file..."
    export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)
    echo -e "${GREEN}✅ 配置加载成功${NC}"
    
    # 为 skopeo 准备凭据参数
    if [ -n "$DOCKER_REGISTRY_USERNAME" ] && [ -n "$DOCKER_REGISTRY_PASSWORD" ]; then
        SKOPEO_CREDS="--src-creds ${DOCKER_REGISTRY_USERNAME}:${DOCKER_REGISTRY_PASSWORD}"
        echo -e "${GREEN}✅ Docker 凭据已配置${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  未找到 .env.standalone 文件${NC}"
    echo "   如需拉取私有镜像，请创建 .env.standalone 并配置 Docker 凭据"
fi

echo ""

# 步骤 2: 拉取并保存 Docker 镜像（使用 skopeo）
echo -e "${YELLOW}[2/4] 拉取并保存 Docker 镜像（使用 skopeo）...${NC}"
echo ""

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# 清理旧的 tar 文件（skopeo 不支持覆盖现有文件）
if ls "$OUTPUT_DIR"/*.tar 1> /dev/null 2>&1; then
    echo "🧹 清理旧的镜像包..."
    rm -f "$OUTPUT_DIR"/*.tar
    echo -e "${GREEN}✅ 旧镜像包已清理${NC}"
    echo ""
fi

echo "📦 Target platform: linux/$PULL_LABEL"
echo "📁 Output directory: $OUTPUT_DIR"
echo ""

# Detect current system architecture
ARCH=$(uname -m)
echo "🖥️  System architecture: $ARCH"
if [ "$ARCH" = "arm64" ] && [ "$TARGET_ARCH" = "amd64" ]; then
    echo -e "${BLUE}ℹ️  跨架构打包: 在 ARM64 主机上打包 AMD64 镜像${NC}"
elif [ "$ARCH" = "x86_64" ] && [ "$TARGET_ARCH" = "arm64" ]; then
    echo -e "${BLUE}ℹ️  跨架构打包: 在 AMD64 主机上打包 ARM64 镜像${NC}"
fi
echo ""

echo "🔄 使用 skopeo 拉取并保存镜像..."
echo "ℹ️  目标架构: $TARGET_ARCH"
echo ""

SAVED_COUNT=0
TOTAL_COUNT=${#IMAGES[@]}

for IMAGE in "${IMAGES[@]}"; do
  echo "⏳ [$((SAVED_COUNT+1))/$TOTAL_COUNT] 处理镜像: $IMAGE"
  
  # Generate output filename
  OUTPUT_FILE="$OUTPUT_DIR/$(generate_filename "$IMAGE")"
  
  # 使用 skopeo copy 直接从 registry 下载指定架构的镜像到本地 tar 文件
  # --override-arch 指定架构
  # docker:// 是源（远程 registry）
  # docker-archive: 是目标（本地 tar 文件）
  echo "💾 Downloading and saving to: $(basename "$OUTPUT_FILE")"
  
  # 构建 skopeo 命令
  SKOPEO_CMD="skopeo copy --override-arch $TARGET_ARCH --override-os linux"
  
  # 添加凭据（如果有）
  if [ -n "$SKOPEO_CREDS" ]; then
    SKOPEO_CMD="$SKOPEO_CMD $SKOPEO_CREDS"
  fi
  
  # 添加源和目标
  # docker-archive 格式: docker-archive:/path/to/file.tar:image:tag
  SKOPEO_CMD="$SKOPEO_CMD docker://$IMAGE docker-archive:$OUTPUT_FILE:$IMAGE"
  
  if eval $SKOPEO_CMD; then
    FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    echo -e "${GREEN}✅ Successfully saved ($TARGET_ARCH): $(basename "$OUTPUT_FILE") ($FILE_SIZE)${NC}"
    ((++SAVED_COUNT))
  else
    echo -e "${RED}❌ Failed to download/save: $IMAGE${NC}"
    exit 1
  fi
  echo ""
done

echo -e "${GREEN}✅ 所有镜像已拉取和保存 ($SAVED_COUNT/$TOTAL_COUNT)${NC}"
echo ""

# 显示保存的镜像
echo "📊 已保存的镜像文件:"
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
echo "📦 镜像总大小: $TOTAL_SIZE"
echo ""

# 步骤 3: 创建构建目录
echo -e "${YELLOW}[3/4] 准备构建目录...${NC}"
echo ""

mkdir -p "$BUILD_DIR"
echo -e "${GREEN}✅ 构建目录已创建: $BUILD_DIR${NC}"

echo ""

# 步骤 4: 打包 standalone 目录
echo -e "${YELLOW}[4/4] 打包部署文件...${NC}"
echo ""

cd "$PROJECT_ROOT"

# 检查 zip 命令是否可用
if ! command -v zip &> /dev/null; then
    echo -e "${RED}❌ zip 命令未找到${NC}"
    echo ""
    echo "请安装 zip 工具："
    echo "  - Ubuntu/Debian: sudo apt-get install zip"
    echo "  - CentOS/RHEL: sudo yum install zip"
    echo "  - macOS: 系统自带"
    exit 1
fi

# 打包文件，排除不必要的内容
echo "正在打包，请稍候..."
zip -r "$PACKAGE_PATH" standalone/ \
  -x "standalone/.git/*" \
  -x "standalone/build/*" \
  -x "standalone/logs/*" \
  -x "standalone/.DS_Store" \
  -x "standalone/**/.DS_Store" \
  -q

PACKAGE_STATUS=$?

if [ $PACKAGE_STATUS -eq 0 ]; then
    echo -e "${GREEN}✅ 打包完成${NC}"
else
    echo -e "${RED}❌ 打包失败${NC}"
    exit 1
fi

echo ""

# 显示打包结果
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}✅ 部署包构建成功！${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 显示文件信息
PACKAGE_SIZE=$(du -h "$PACKAGE_PATH" 2>/dev/null | cut -f1)
echo "📦 部署包信息:"
echo "   文件名: $(basename $PACKAGE_PATH)"
echo "   路径: $PACKAGE_PATH"
echo "   大小: $PACKAGE_SIZE"
echo "   架构: $TARGET_ARCH"
echo ""

# 显示构建目录中的所有包
echo "📁 构建目录中的部署包:"
ls -lh "$BUILD_DIR"/*.zip 2>/dev/null | awk '{print "   " $9 " (" $5 ")"}' || echo "   (无其他文件)"
echo ""

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}部署说明${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo -e "${YELLOW}⚠️  注意: 此部署包仅适用于 $TARGET_ARCH 架构的服务器${NC}"
echo ""
echo "1. 传输到目标服务器:"
echo "   scp $(basename $PACKAGE_PATH) root@your-server-ip:/root/"
echo ""
echo "2. 在服务器上解压并安装:"
echo "   cd /root"
echo "   unzip $(basename $PACKAGE_PATH)"
echo "   cd standalone"
echo "   sudo bash scripts/install-and-start.sh"
echo ""

# 可选：清理旧的部署包
echo -e "${YELLOW}💡 提示: 如需清理旧的部署包，可以运行:${NC}"
echo "   rm $BUILD_DIR/standalone-deployment-*.zip"
echo ""
