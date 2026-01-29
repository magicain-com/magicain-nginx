#!/bin/bash
set -e

# Docker Registry Login Script
# Logs into both public and private registries using env files

# Optional env file override
ENV_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file=*)
      ENV_FILE="${1#*=}"
      shift
      ;;
    --env-file)
      ENV_FILE="$2"
      shift 2
      ;;
    *)
      echo "⚠️  忽略未知参数: $1"
      shift
      ;;
  esac
done

# If required vars are already set, skip loading from file
if [ -n "$PUBLIC_DOCKER_REGISTRY_URL" ] && [ -n "$PUBLIC_DOCKER_REGISTRY_USERNAME" ] && [ -n "$PUBLIC_DOCKER_REGISTRY_PASSWORD" ] \
  && [ -n "$PRIVATE_DOCKER_REGISTRY_URL" ] && [ -n "$PRIVATE_DOCKER_REGISTRY_USERNAME" ] && [ -n "$PRIVATE_DOCKER_REGISTRY_PASSWORD" ]; then
  echo "Using registry credentials from environment variables"
else
  if [ -z "$ENV_FILE" ]; then
    if [ -f ".env" ]; then
      ENV_FILE=".env"
    elif [ -f ".env.prod" ]; then
      ENV_FILE=".env.prod"
    elif [ -f ".env.standalone" ]; then
      ENV_FILE=".env.standalone"
    fi
  fi

  if [ -z "$ENV_FILE" ] || [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env file not found and registry credentials not provided"
    exit 1
  fi

  # shellcheck disable=SC2046
  export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)
  echo "Loaded env file: $ENV_FILE"
fi

login_registry() {
  local name="$1"
  local url="$2"
  local user="$3"
  local pass="$4"

  if [ -z "$url" ] || [ -z "$user" ] || [ -z "$pass" ]; then
    echo "❌ Missing credentials for ${name} registry (URL/User/Password required)"
    exit 1
  fi

  echo "Logging into ${name} registry: ${url}"
  if echo "$pass" | docker login "$url" -u "$user" --password-stdin; then
    echo "✅ ${name} registry login succeeded"
  else
    echo "❌ ${name} registry login failed"
    exit 1
  fi
}

# Public registry
login_registry "Public" \
  "$PUBLIC_DOCKER_REGISTRY_URL" \
  "$PUBLIC_DOCKER_REGISTRY_USERNAME" \
  "$PUBLIC_DOCKER_REGISTRY_PASSWORD"

# Private registry
login_registry "Private" \
  "$PRIVATE_DOCKER_REGISTRY_URL" \
  "$PRIVATE_DOCKER_REGISTRY_USERNAME" \
  "$PRIVATE_DOCKER_REGISTRY_PASSWORD"