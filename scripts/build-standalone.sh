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

# 解析目标架构参数：amd64 / arm64（默认取当前系统架构）
HOST_ARCH_RAW=$(uname -m)
case "$HOST_ARCH_RAW" in
  x86_64) HOST_ARCH="amd64" ;;
  aarch64|arm64) HOST_ARCH="arm64" ;;
  *)
    HOST_ARCH="amd64"
    echo -e "${YELLOW}⚠️  未知主机架构: $HOST_ARCH_RAW，默认使用 amd64${NC}"
    ;;
esac

TARGET_ARCH="$HOST_ARCH"
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

case "$TARGET_ARCH" in
  amd64|arm64) ;;
  *)
    echo -e "${RED}❌ 无效架构: $TARGET_ARCH（仅支持 amd64 / arm64）${NC}"
    exit 1
    ;;
esac

# 根据架构设置镜像拉取选项和输出标识
PULL_LABEL="$TARGET_ARCH"
ZIP_ARCH_SUFFIX="$TARGET_ARCH"

# Docker 镜像列表
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

# 生成带日期的文件名（包含架构标识）
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

# 步骤 1: 加载环境变量
echo -e "${YELLOW}[1/4] 加载配置...${NC}"
echo ""

ENV_FILE="$PROJECT_ROOT/.env.standalone"
if [ -f "$ENV_FILE" ]; then
    echo "📝 Loading environment variables from .env.standalone file..."
    export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)
    echo -e "${GREEN}✅ 配置加载成功${NC}"
else
    echo -e "${YELLOW}⚠️  未找到 .env.standalone 文件${NC}"
    echo "   如需拉取私有镜像，请创建 .env.standalone 并配置 Docker 凭据"
fi

echo ""

# Docker login if credentials are provided
if [ -n "$DOCKER_REGISTRY_USERNAME" ] && [ -n "$DOCKER_REGISTRY_PASSWORD" ] && [ -n "$DOCKER_REGISTRY_URL" ]; then
    echo "🔐 Logging into Docker registry: $DOCKER_REGISTRY_URL"
    if echo "$DOCKER_REGISTRY_PASSWORD" | docker login "$DOCKER_REGISTRY_URL" -u "$DOCKER_REGISTRY_USERNAME" --password-stdin > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Successfully logged into Docker registry${NC}"
    else
        echo -e "${YELLOW}⚠️  Warning: Failed to login to Docker registry${NC}"
        echo "    Continuing anyway, but private images may fail to pull..."
    fi
    echo ""
else
    echo "ℹ️  No Docker registry credentials found"
    echo "   Public images will be pulled without authentication"
    echo ""
fi

# 步骤 2: 拉取并保存 Docker 镜像
echo -e "${YELLOW}[2/4] 拉取并保存 Docker 镜像...${NC}"
echo ""

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "📦 Target platform: $PULL_LABEL"
echo "📁 Output directory: $OUTPUT_DIR"
echo ""

# Detect current system architecture
ARCH=$(uname -m)
echo "🖥️  System architecture: $ARCH"
echo ""

echo "🔄 Pulling and saving images..."
echo "ℹ️  Pulling architecture: $TARGET_ARCH"
echo ""

SAVED_COUNT=0
TOTAL_COUNT=${#IMAGES[@]}

for IMAGE in "${IMAGES[@]}"; do
  echo "⏳ [$((SAVED_COUNT+1))/$TOTAL_COUNT] Pulling: $IMAGE"
  
  # 单架构拉取
  if docker pull --platform "linux/$TARGET_ARCH" "$IMAGE"; then
    echo "✅ Successfully pulled ($TARGET_ARCH): $IMAGE"
  else
    echo -e "${RED}❌ Failed to pull ($TARGET_ARCH): $IMAGE${NC}"
    exit 1
  fi
  
  # Generate output filename
  OUTPUT_FILE="$OUTPUT_DIR/$(generate_filename "$IMAGE")"
  
  echo "💾 Saving to: $(basename "$OUTPUT_FILE")"
  if docker save -o "$OUTPUT_FILE" "$IMAGE"; then
    FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    echo -e "${GREEN}✅ Successfully saved: $(basename "$OUTPUT_FILE") ($FILE_SIZE)${NC}"
    ((SAVED_COUNT++))
  else
    echo -e "${RED}❌ Failed to save: $IMAGE${NC}"
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

OS_NAME="$(uname -s)"
IS_GIT_BASH_WIN=false
case "$OS_NAME" in
    MINGW*|MSYS*|CYGWIN*)
        IS_GIT_BASH_WIN=true
        ;;
esac

if [ "$IS_GIT_BASH_WIN" = true ]; then
    echo "检测到 Windows Git Bash，使用 PowerShell 压缩..."

    PROJECT_ROOT_WIN="$(cd "$PROJECT_ROOT" && { pwd -W 2>/dev/null || pwd; })"
    PACKAGE_PATH_WIN="$(cd "$(dirname "$PACKAGE_PATH")" && { pwd -W 2>/dev/null || pwd; })/$(basename "$PACKAGE_PATH")"
    if command -v cygpath &> /dev/null; then
        PROJECT_ROOT_WIN="$(cygpath -w "$PROJECT_ROOT")"
        PACKAGE_PATH_WIN="$(cygpath -w "$PACKAGE_PATH")"
    fi

    POWERSHELL_CMD=$(cat <<EOF
\$ErrorActionPreference = 'Stop'
\$projectRoot = '$PROJECT_ROOT_WIN'
\$packagePath = '$PACKAGE_PATH_WIN'
\$tempRoot = Join-Path \$env:TEMP ('standalone-package-' + [guid]::NewGuid())
\$source = Join-Path \$projectRoot 'standalone'
\$dest = Join-Path \$tempRoot 'standalone'
New-Item -ItemType Directory -Path \$dest -Force | Out-Null
robocopy \$source \$dest /E /XD (Join-Path \$source '.git') (Join-Path \$source 'build') (Join-Path \$source 'logs') /XF '.DS_Store' '.env' /NJH /NJS /NDL /NFL /NC /NS | Out-Null
if (\$LASTEXITCODE -ge 8) { throw 'robocopy failed' }
Compress-Archive -Path \$dest -DestinationPath \$packagePath -Force
Remove-Item -Path \$tempRoot -Recurse -Force -ErrorAction SilentlyContinue
EOF
)

    powershell -NoProfile -Command "$POWERSHELL_CMD"
    PACKAGE_STATUS=$?
else
    # 检查 zip 命令是否可用
    if ! command -v zip &> /dev/null; then
        echo -e "${RED}❌ zip 命令未找到${NC}"
        echo ""
        echo "请安装 zip 工具："
        echo "  - Windows: 安装 Git Bash (https://git-scm.com/download/win)"
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
      -x "standalone/.env" \
      -q

    PACKAGE_STATUS=$?
fi

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
echo ""

# 显示构建目录中的所有包
echo "📁 构建目录中的部署包:"
ls -lh "$BUILD_DIR"/*.zip 2>/dev/null | awk '{print "   " $9 " (" $5 ")"}' || echo "   (无其他文件)"
echo ""

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}部署说明${NC}"
echo -e "${BLUE}================================${NC}"
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

