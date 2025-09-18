#!/bin/bash
set -euxo pipefail

sudo apt-get update -y
sudo systemctl unmask docker.service || true
sudo systemctl unmask docker.socket || true
sudo apt-get remove -y docker docker-engine docker.io containerd runc containerd.io || true
curl -fsSL https://get.docker.com | sh
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker azureuser || true

sudo apt-get install -y docker-compose-plugin git curl

APP_DIR="/home/azureuser/ecommerce-app-three-tier-azure-db-ih"
if [ ! -d "$APP_DIR" ]; then
  sudo -u azureuser git clone https://github.com/omega0100/ecommerce-app-three-tier-azure-db-ih.git "$APP_DIR"
else
  cd "$APP_DIR"
  sudo -u azureuser git pull --rebase
fi

# REACT_APP_API_URL لو عندكم يعتمد على IP الـ AppGW، تأكدوا إنه مضبوط داخل الـ Dockerfile/NGINX أو .env الخاصة بالفرونت
cd "$APP_DIR"
sudo docker compose pull || true
sudo docker compose up -d --build frontend

sleep 5
curl -sf http://localhost/ || exit 1
