#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt_wait() {
  # انتظر أي قفل لـ apt/dpkg
  while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 \
     || sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 \
     || sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
    sleep 3
  done
}

# Docker
if ! command -v docker >/dev/null 2>&1; then
  apt_wait; sudo apt-get update -y
  curl -fsSL https://get.docker.com | sh
fi
sudo systemctl enable --now docker

# أدوات لازمة (مع انتظار القفل وإعادة المحاولة)
apt_wait; sudo apt-get install -y docker-compose-plugin git curl || {
  apt_wait; sudo apt-get -f install -y
  apt_wait; sudo apt-get install -y docker-compose-plugin git curl
}

# تهيئة لوجات Docker (اختياري)
sudo mkdir -p /etc/docker
cat >/tmp/daemon.json <<'JSON'
{ "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "3" } }
JSON
sudo mv /tmp/daemon.json /etc/docker/daemon.json
sudo systemctl restart docker

exit 0
