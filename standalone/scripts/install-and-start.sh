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
IMAGE_TAG_ARG=""

# Optional version argument (first arg or --version/-v)
if [ $# -gt 0 ]; then
    case "$1" in
        --version=*)
            IMAGE_TAG_ARG="${1#*=}"
            shift
            ;;
        --version|-v)
            IMAGE_TAG_ARG="$2"
            shift 2
            ;;
        *)
            IMAGE_TAG_ARG="$1"
            shift
            ;;
    esac
fi

if [ -n "$IMAGE_TAG_ARG" ]; then
    if [[ "$IMAGE_TAG_ARG" =~ ^v ]]; then
        echo -e "${RED}❌ 版本号请使用 1.2.3 格式，不要带 v 前缀${NC}"
        exit 1
    fi
    if ! [[ "$IMAGE_TAG_ARG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}❌ 版本号格式无效，应为 1.2.3${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Magicain Standalone 安装启动脚本${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "本脚本支持:"
echo "  ✓ 全新安装部署"
echo "  ✓ 在线更新（保留数据）"
echo ""

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ 错误: 请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 步骤 1: 检查系统环境
echo -e "${YELLOW}[1/7] 检查系统环境...${NC}"
echo ""

# 检查操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "操作系统: $PRETTY_NAME"
else
    echo -e "${YELLOW}⚠️  无法检测操作系统版本${NC}"
fi

# 检查架构
ARCH=$(uname -m)
echo "系统架构: $ARCH"
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ] && [ "$ARCH" != "x86_64" ]; then
    echo -e "${YELLOW}⚠️  警告: 检测到非标准架构（$ARCH），支持的架构为 AMD64(x86_64) 或 ARM64(aarch64)${NC}"
fi

# 检查内存
TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
echo "总内存: ${TOTAL_MEM}GB"
if [ "$TOTAL_MEM" -lt 8 ]; then
    echo -e "${YELLOW}⚠️  警告: 内存少于 8GB，可能影响性能${NC}"
fi

# 检查磁盘空间
AVAILABLE_SPACE=$(df -BG "$STANDALONE_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
echo "可用磁盘空间: ${AVAILABLE_SPACE}GB"
if [ "$AVAILABLE_SPACE" -lt 50 ]; then
    echo -e "${YELLOW}⚠️  警告: 磁盘空间少于 50GB${NC}"
fi

echo ""

# 步骤 2: 检查并安装 Docker
echo -e "${YELLOW}[2/7] 检查 Docker 安装...${NC}"
echo ""

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "${GREEN}✅ Docker 已安装: $DOCKER_VERSION${NC}"
    
    if command -v docker compose &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version)
        echo -e "${GREEN}✅ Docker Compose 已安装: $COMPOSE_VERSION${NC}"
    else
        echo -e "${YELLOW}⚠️  Docker Compose 未安装，尝试安装...${NC}"
        if [ -d "$STANDALONE_DIR/docker/infra" ]; then
            cd "$STANDALONE_DIR/docker/infra"
            if rpm -ivh docker-compose-plugin-*.rpm 2>/dev/null; then
                echo -e "${GREEN}✅ Docker Compose 安装成功${NC}"
            else
                echo -e "${RED}❌ Docker Compose 安装失败${NC}"
                exit 1
            fi
        else
            echo -e "${RED}❌ 未找到 Docker Compose 安装包${NC}"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}Docker 未安装，开始安装...${NC}"
    if [ -f "$STANDALONE_DIR/scripts/install-infra.sh" ]; then
        bash "$STANDALONE_DIR/scripts/install-infra.sh"
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Docker 安装失败${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ 未找到 Docker 安装脚本${NC}"
        exit 1
    fi
fi

# 启动 Docker 服务
if ! systemctl is-active --quiet docker; then
    echo "启动 Docker 服务..."
    systemctl start docker
    systemctl enable docker
fi

echo ""

# 步骤 3: 检查并安装 iptables-nft（麒麟 V10）
echo -e "${YELLOW}[3/7] 检查 iptables-nft...${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "kylin" ]] || [[ "$NAME" == *"Kylin"* ]]; then
        if ! rpm -q iptables-nft &> /dev/null; then
            echo "检测到麒麟系统，安装 iptables-nft..."
            yum install -y iptables iptables-nft || {
                echo -e "${YELLOW}⚠️  iptables-nft 安装失败，如果后续 Docker 网络启动失败，请手动安装${NC}"
            }
        else
            echo -e "${GREEN}✅ iptables-nft 已安装${NC}"
        fi
    fi
fi
echo ""

# 步骤 4: 加载 Docker 镜像
echo -e "${YELLOW}[4/7] 检查 Docker 镜像...${NC}"
echo ""

IMAGE_DIR="$STANDALONE_DIR/docker/images"
if [ -d "$IMAGE_DIR" ] && [ -n "$(ls -A $IMAGE_DIR/*.tar 2>/dev/null)" ]; then
    TOTAL_IMAGES=$(ls -1 "$IMAGE_DIR"/*.tar 2>/dev/null | wc -l)
    echo "发现 $TOTAL_IMAGES 个离线镜像包，开始加载..."
    echo -e "${BLUE}ℹ️  如存在同名旧镜像，将被自动覆盖为新版本${NC}"
    echo -e "${BLUE}ℹ️  大文件加载可能需要几分钟，请耐心等待${NC}"
    echo ""
    LOADED_COUNT=0
    FAILED_COUNT=0
    CURRENT_INDEX=0
    
    for IMAGE_TAR in "$IMAGE_DIR"/*.tar; do
        if [ -f "$IMAGE_TAR" ]; then
            IMAGE_NAME=$(basename "$IMAGE_TAR")
            IMAGE_SIZE=$(du -h "$IMAGE_TAR" | cut -f1)
            CURRENT_INDEX=$((CURRENT_INDEX + 1))
            echo "[$CURRENT_INDEX/$TOTAL_IMAGES] 加载镜像: $IMAGE_NAME (大小: $IMAGE_SIZE)"
            echo -e "${BLUE}ℹ️  正在加载，请耐心等待...${NC}"
            
            # 使用临时文件捕获输出，避免 grep 退出码问题
            TEMP_OUTPUT=$(mktemp)
            
            # 执行 docker load 并捕获输出和退出码
            set +e  # 临时禁用错误退出
            docker load -i "$IMAGE_TAR" > "$TEMP_OUTPUT" 2>&1
            LOAD_EXIT_CODE=$?
            set -e  # 恢复错误退出
            
            # 显示非空输出行
            if [ -s "$TEMP_OUTPUT" ]; then
                grep -v "^$" "$TEMP_OUTPUT" || true
            fi
            rm -f "$TEMP_OUTPUT"
            
            # 根据退出码判断成功或失败
            if [ $LOAD_EXIT_CODE -eq 0 ]; then
                echo -e "${GREEN}✅ 加载成功: $IMAGE_NAME${NC}"
                ((LOADED_COUNT+=1))
            else
                echo -e "${RED}❌ 加载失败: $IMAGE_NAME (退出码: $LOAD_EXIT_CODE)${NC}"
                ((FAILED_COUNT+=1))
            fi
            echo ""
        fi
    done
    
    if [ $FAILED_COUNT -eq 0 ]; then
        echo -e "${GREEN}✅ 所有镜像加载成功 ($LOADED_COUNT 个镜像)${NC}"
    else
        echo -e "${YELLOW}⚠️  部分镜像加载失败 (成功: $LOADED_COUNT, 失败: $FAILED_COUNT)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  未找到离线镜像包目录 ($IMAGE_DIR) 或目录为空${NC}"
    echo "将在启动时从网络拉取镜像"
fi

echo ""

# 步骤 5: 创建必要的目录
echo -e "${YELLOW}[5/7] 创建必要的目录...${NC}"
echo ""

# 创建数据目录
mkdir -p /data/postgres
mkdir -p /data/redis
chmod 755 /data/postgres
chmod 755 /data/redis

# 创建日志目录
mkdir -p "$STANDALONE_DIR/logs/nginx"
chmod 755 "$STANDALONE_DIR/logs/nginx"

# 创建证书目录
mkdir -p "$STANDALONE_DIR/cert"
chmod 755 "$STANDALONE_DIR/cert"

echo -e "${GREEN}✅ 目录创建完成${NC}"
echo ""

# 步骤 6: 配置环境变量
echo -e "${YELLOW}[6/7] 配置环境变量...${NC}"
echo ""

ENV_FILE="$STANDALONE_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "创建 .env 文件..."
    # 生成随机密码
    RANDOM_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    cat > "$ENV_FILE" << EOF
# PostgreSQL 配置
POSTGRES_USER=magicain
POSTGRES_PASSWORD=$RANDOM_PASSWORD
IMAGE_TAG=${IMAGE_TAG_ARG:-latest}
EOF
    echo -e "${GREEN}✅ .env 文件已创建${NC}"
    echo -e "${YELLOW}⚠️  请记录 PostgreSQL 配置:${NC}"
    echo -e "${YELLOW}    用户名: magicain${NC}"
    echo -e "${YELLOW}    密码: $RANDOM_PASSWORD${NC}"
    echo -e "${YELLOW}⚠️  建议修改 .env 文件中的密码为更安全的密码${NC}"
else
    echo -e "${GREEN}✅ .env 文件已存在${NC}"
fi

# Ensure IMAGE_TAG is set (override when provided)
if [ -n "$IMAGE_TAG_ARG" ]; then
    if grep -q '^IMAGE_TAG=' "$ENV_FILE"; then
        sed -i.bak "s/^IMAGE_TAG=.*/IMAGE_TAG=${IMAGE_TAG_ARG}/" "$ENV_FILE"
    else
        echo "IMAGE_TAG=${IMAGE_TAG_ARG}" >> "$ENV_FILE"
    fi
elif ! grep -q '^IMAGE_TAG=' "$ENV_FILE"; then
    echo "IMAGE_TAG=latest" >> "$ENV_FILE"
fi

echo ""

# 步骤 7: 启动服务
echo -e "${YELLOW}[7/7] 启动服务...${NC}"
echo ""

cd "$STANDALONE_DIR"

# 检查 docker-compose.yml 是否存在
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ 未找到 docker-compose.yml 文件${NC}"
    exit 1
fi

echo "停止现有容器..."
# 停止并移除容器、网络，保留数据卷
# --remove-orphans 会清理掉不再 docker-compose.yml 中的旧服务容器
docker compose down --remove-orphans

echo ""
echo "清理旧版本悬空镜像..."
# 在步骤 4 加载新镜像后，旧的同名镜像会变为 <none> (dangling)，这里进行清理以释放空间
docker image prune -f

echo ""
echo "启动 Docker Compose 服务..."
echo -e "${BLUE}ℹ️  使用 --force-recreate 强制重建容器以应用新镜像${NC}"
if docker compose up -d --force-recreate; then
    echo -e "${GREEN}✅ 服务启动成功${NC}"
else
    echo -e "${RED}❌ 服务启动失败${NC}"
    echo "查看日志: docker compose logs"
    exit 1
fi

echo ""
echo -e "${BLUE}ℹ️  重要说明:${NC}"
echo "   - Docker 镜像: 如有新版本已通过离线包更新"
echo "   - PostgreSQL: 数据库数据已保留，初始化脚本不会重新执行"
if [ -d "/data/postgres" ] && [ "$(ls -A /data/postgres 2>/dev/null)" ]; then
    echo -e "${YELLOW}   ⚠️  检测到已有数据库数据，如需 schema 升级请手动执行 SQL${NC}"
fi

echo ""

# 等待服务启动
echo "等待服务启动..."
sleep 5

# 检查服务状态
echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}服务状态${NC}"
echo -e "${BLUE}================================${NC}"
docker compose ps

echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}✅ 安装和启动完成！${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "服务访问地址:"
echo "  - HTTP:  http://$(hostname -I | awk '{print $1}')"
echo "  - HTTPS: https://$(hostname -I | awk '{print $1}')"
echo "  - Admin UI: http://$(hostname -I | awk '{print $1}'):8080"
echo "  - Agent UI: http://$(hostname -I | awk '{print $1}'):8081"
echo "  - User UI: http://$(hostname -I | awk '{print $1}'):8082"
echo "  - Cloud API: http://$(hostname -I | awk '{print $1}'):48080"
echo ""
echo "常用命令:"
echo "  - 查看日志: cd $STANDALONE_DIR && docker compose logs -f"
echo "  - 停止服务: cd $STANDALONE_DIR && docker compose stop"
echo "  - 重启服务: cd $STANDALONE_DIR && docker compose restart"
echo "  - 查看状态: cd $STANDALONE_DIR && docker compose ps"
echo ""
if [ -f "$ENV_FILE" ] && [ ! -f "$ENV_FILE.old" ]; then
    echo -e "${YELLOW}⚠️  重要: PostgreSQL 密码保存在 $ENV_FILE${NC}"
    echo -e "${YELLOW}⚠️  请妥善保管此文件${NC}"
fi
echo ""

