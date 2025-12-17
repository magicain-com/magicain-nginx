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
STANDALONE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$STANDALONE_DIR/.." && pwd)"
BUILD_DIR="$STANDALONE_DIR/build"

# 生成带日期的文件名
DATE_STAMP=$(date +%Y%m%d-%H%M%S)
PACKAGE_NAME="standalone-deployment-${DATE_STAMP}.zip"
PACKAGE_PATH="$BUILD_DIR/$PACKAGE_NAME"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Standalone Deployment Package Builder${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 步骤 1: 拉取最新镜像
echo -e "${YELLOW}[1/3] 拉取最新 Docker 镜像...${NC}"
echo ""

if [ -f "$SCRIPT_DIR/docker-save.sh" ]; then
    cd "$STANDALONE_DIR"
    bash "$SCRIPT_DIR/docker-save.sh"
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Docker 镜像拉取和保存完成${NC}"
    else
        echo -e "${RED}❌ Docker 镜像拉取失败${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ 未找到 docker-save.sh 脚本${NC}"
    exit 1
fi

echo ""

# 步骤 2: 创建构建目录
echo -e "${YELLOW}[2/3] 准备构建目录...${NC}"
echo ""

mkdir -p "$BUILD_DIR"
echo -e "${GREEN}✅ 构建目录已创建: $BUILD_DIR${NC}"

echo ""

# 步骤 3: 打包 standalone 目录
echo -e "${YELLOW}[3/3] 打包部署文件...${NC}"
echo ""

cd "$PROJECT_ROOT"

# 检查 zip 命令是否可用
if ! command -v zip &> /dev/null; then
    echo -e "${RED}❌ zip 命令未找到，请先安装 zip 工具${NC}"
    echo "   Ubuntu/Debian: sudo apt-get install zip"
    echo "   CentOS/RHEL: sudo yum install zip"
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

if [ $? -eq 0 ]; then
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
PACKAGE_SIZE=$(du -h "$PACKAGE_PATH" | cut -f1)
echo "📦 部署包信息:"
echo "   文件名: $PACKAGE_NAME"
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
echo "   scp $PACKAGE_PATH root@your-server-ip:/root/"
echo ""
echo "2. 在服务器上解压并安装:"
echo "   cd /root"
echo "   unzip $PACKAGE_NAME"
echo "   cd standalone"
echo "   sudo bash scripts/install-and-start.sh"
echo ""

# 可选：清理旧的部署包
echo -e "${YELLOW}💡 提示: 如需清理旧的部署包，可以运行:${NC}"
echo "   rm $BUILD_DIR/standalone-deployment-*.zip"
echo ""

