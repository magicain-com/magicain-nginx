#!/bin/bash
set -e

# Docker Registry Login Script
# Logs into both public and private registries using env files

# Load variables from .env.prod only
if [ -f ".env.prod" ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' ".env.prod" | grep -v '^$' | xargs)
  echo "Loaded env file: .env.prod"
else
  echo "❌ .env.prod not found"
  exit 1
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