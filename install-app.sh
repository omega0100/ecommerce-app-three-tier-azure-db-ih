#!/bin/bash
set -e

# تحديث النظام
sudo apt-get update -y
sudo apt-get upgrade -y

# إزالة أي تعارض مع containerd
sudo apt-get remove -y containerd.io || true

# تثبيت Docker بالطريقة الرسمية
if ! command -v docker &> /dev/null
then
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
fi

# تثبيت docker-compose (plugin)
sudo apt-get install -y docker-compose-plugin git curl

# تفعيل docker
sudo systemctl enable docker
sudo systemctl start docker

# تنزيل المشروع (لو ما هو موجود)
APP_DIR="/home/azureuser/ecommerce-app-three-tier-azure-db-ih"
if [ ! -d "$APP_DIR" ]; then
  cd /home/azureuser
  git clone https://github.com/omega0100/ecommerce-app-three-tier-azure-db-ih.git
fi

cd $APP_DIR

# تشغيل docker compose
sudo docker compose up -d --build
