#!/bin/bash
set -euxo pipefail
APP_DIR="/home/azureuser/ecommerce-app-three-tier-azure-db-ih"
BRANCH="main"

sudo apt-get update -y
sudo systemctl unmask docker.service || true
sudo systemctl unmask docker.socket || true
command -v docker || { curl -fsSL https://get.docker.com | sh; }
sudo systemctl enable --now docker
sudo apt-get install -y docker-compose-plugin git curl

if [ ! -d "$APP_DIR/.git" ]; then
  sudo rm -rf "$APP_DIR"
  sudo -H -u azureuser git clone --branch "$BRANCH" https://github.com/omega0100/ecommerce-app-three-tier-azure-db-ih.git "$APP_DIR"
else
  sudo -H -u azureuser bash -lc "cd '$APP_DIR' && git fetch --all --prune && git reset --hard origin/$BRANCH"
fi
sudo chown -R azureuser:azureuser "$APP_DIR"

cd "$APP_DIR"
# ابنِ وشغّل خدمة الفرونت فقط بدون أي تبعيات
sudo docker compose build --no-cache frontend
sudo docker compose up -d --no-deps --force-recreate frontend

# افحص على البورت 3000 (زي ما HealthExtension عندك)
sleep 5
curl -sf http://localhost:3000/ || exit 53
