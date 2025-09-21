#!/usr/bin/env bash
set -euxo pipefail

# --- Vars ---
APP_DIR=/home/azureuser/ecommerce-app-three-tier-azure-db-ih
REPO_URL=https://github.com/omega0100/ecommerce-app-three-tier-azure-db-ih.git
BRANCH=main
ACR_NAME=group4acr
ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER:-group4acr.azurecr.io}
IMAGE_TAG=${IMAGE_TAG:-latest}

apt_wait() {
  for f in /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock /var/cache/apt/archives/lock; do
    while fuser "$f" >/dev/null 2>&1; do sleep 1; done
  done
}

# --- Docker & tools ---
command -v docker || curl -fsSL https://get.docker.com | sh
systemctl enable --now docker
apt_wait
apt-get update -y
apt-get install -y docker-compose-plugin git curl

# --- Azure CLI (for MI ACR login) ---
if ! command -v az >/dev/null 2>&1; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | bash
fi

# --- Get/refresh code ---
if [ ! -d "$APP_DIR/.git" ]; then
  rm -rf "$APP_DIR"
  sudo -u azureuser git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
else
  sudo -u azureuser bash -lc "cd '$APP_DIR' && git fetch --all --prune && git reset --hard origin/$BRANCH"
fi
chown -R azureuser:azureuser "$APP_DIR"

# --- Compose .env (what docker-compose expects) ---
cat > "$APP_DIR/.env" <<ENVEOF
ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
IMAGE_TAG=$IMAGE_TAG

DB_HOST=sqlserver-group4.database.windows.net
DB_NAME=group4db
DB_USER=user-admine-group4
DB_PASSWORD=Gr@123456
DB_ENCRYPT=true
DB_TRUST_SERVER_CERTIFICATE=false

JWT_SECRET=Group4
JWT_EXPIRES_IN=7d
CORS_ORIGIN=http://4.245.59.253:3000
ENVEOF
chown azureuser:azureuser "$APP_DIR/.env"

# --- Login to ACR using Managed Identity ---
az login --identity >/dev/null 2>&1 || true
TOKEN=$(az acr login -n "$ACR_NAME" --expose-token --query accessToken -o tsv || echo "")
if [ -n "$TOKEN" ]; then
  echo "$TOKEN" | docker login "$ACR_LOGIN_SERVER" -u 00000000-0000-0000-0000-000000000000 --password-stdin
fi

# --- Run backend (as root to avoid docker socket perms) ---
cd "$APP_DIR"
docker compose --env-file .env pull backend || true
docker compose --env-file .env up -d --no-deps --force-recreate backend

# --- Health check with logs on failure ---
for i in $(seq 1 30); do
  if curl -sfS http://127.0.0.1:3001/health >/dev/null; then
    echo "Backend healthy"
    exit 0
  fi
  sleep 2
done

echo "Backend failed healthcheck"
docker ps || true
docker logs --tail 200 ecommerce-backend || true
exit 1
