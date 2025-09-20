#!/usr/bin/env bash
set -euo pipefail

# === Parse args ===
APP_DIR=""
ACR_NAME=""
ACR_LOGIN_SERVER=""
RAW_COMPOSE_URL=""
IMAGE_TAG="latest"
HEALTH_URL=""
SERVICE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-dir) APP_DIR="$2"; shift 2 ;;
    --acr-name) ACR_NAME="$2"; shift 2 ;;
    --acr-login) ACR_LOGIN_SERVER="$2"; shift 2 ;;
    --raw-compose-url) RAW_COMPOSE_URL="$2"; shift 2 ;;
    --image-tag) IMAGE_TAG="$2"; shift 2 ;;
    --health-url) HEALTH_URL="$2"; shift 2 ;;
    --service) SERVICE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ -z "$APP_DIR" || -z "$ACR_NAME" || -z "$ACR_LOGIN_SERVER" || -z "$RAW_COMPOSE_URL" || -z "$SERVICE" ]]; then
  echo "Missing required args"; exit 2
fi

# === Ensure docker compose (v2 plugin or classic) ===
if ! docker compose version >/dev/null 2>&1; then
  if ! command -v docker-compose >/dev/null 2>&1; then
    sudo curl -fsSL "https://github.com/docker/compose/releases/download/2.29.7/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose || true
  fi
fi

# === Ensure az cli (احتياط) ===
if ! command -v az >/dev/null 2>&1; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# === Prepare app dir + compose ===
mkdir -p "$APP_DIR"
cd "$APP_DIR"
curl -fsSL "$RAW_COMPOSE_URL" -o docker-compose.yml

# نمرر قيم الريجستري/التاج عبر .env
printf '%s\n' "ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER" "IMAGE_TAG=$IMAGE_TAG" > .env

# === ACR login عبر الهوية المُدارة ===
az login --identity >/dev/null
TOKEN=$(az acr login -n "$ACR_NAME" --expose-token --query accessToken -o tsv)
echo "$TOKEN" | docker login "$ACR_LOGIN_SERVER" -u 00000000-0000-0000-0000-000000000000 --password-stdin

# === Pull + recreate المطلوب فقط ===
if docker compose version >/dev/null 2>&1; then
  docker compose --env-file .env pull "$SERVICE"
  docker compose --env-file .env up -d --no-deps --force-recreate "$SERVICE"
else
  docker-compose --env-file .env pull "$SERVICE"
  docker-compose --env-file .env up -d --no-deps --force-recreate "$SERVICE"
fi

# === Health wait (لو متوفر) ===
if [[ -n "${HEALTH_URL:-}" ]]; then
  for i in $(seq 1 36); do
    if curl -fsS "$HEALTH_URL" >/dev/null; then
      if [[ "$SERVICE" = "frontend" ]]; then
        echo -n "version: "; cat /usr/share/nginx/html/version.txt 2>/dev/null || echo no-version
        echo "--- css files ---"; ls -l /usr/share/nginx/html/static/css 2>/dev/null || true
        echo "--- index refs ---"; grep -o '/static/[^" ]*\.\(css\|js\)' -n /usr/share/nginx/html/index.html 2>/dev/null || true
      fi
      echo "$SERVICE healthy ✓"
      exit 0
    fi
    sleep 5
  done
  echo "$SERVICE failed healthcheck"
  docker ps --filter "name=ecommerce-$SERVICE" || true
  docker logs "$(docker ps --filter "name=ecommerce-$SERVICE" -q)" --tail 200 || true
  exit 1
fi
