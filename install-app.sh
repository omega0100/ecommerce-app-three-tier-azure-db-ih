#!/bin/bash
set -e

# تحديث النظام
sudo apt-get update -y
sudo apt-get upgrade -y

# تثبيت Docker و Docker Compose
sudo apt-get install -y docker.io docker-compose-plugin git curl

# تفعيل docker
sudo systemctl enable docker
sudo systemctl start docker

# تنزيل المشروع (لو ما هو موجود)
if [ ! -d "/home/azureuser/ecommerce-app-three-tier-azure-db-ih" ]; then
  cd /home/azureuser
  git https://github.com/omega0100/ecommerce-app-three-tier-azure-db-ih.git
fi

cd /home/azureuser/ecommerce-app-three-tier-azure-db-ih

# تشغيل docker compose
sudo docker compose up -d --build
