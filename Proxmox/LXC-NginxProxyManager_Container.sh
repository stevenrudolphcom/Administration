#!/bin/bash

# Nginx Proxy Manager LXC Container Setup Script für Debian Trixie
# Dieses Skript installiert Docker und richtet Nginx Proxy Manager in einem LXC-Container ein.

# Docker installieren
apt update
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Für Debian Trixie (unstable) verwenden wir das bullseye-Repository, da Docker unstable nicht offiziell unterstützt
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Docker Service starten
systemctl start docker
systemctl enable docker

# Verzeichnis für Nginx Proxy Manager erstellen
mkdir -p /opt/nginx-proxy-manager
cd /opt/nginx-proxy-manager

# Docker Compose Datei erstellen
cat <<EOF > docker-compose.yml
version: '3.8'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    depends_on:
      - db
  db:
    image: 'jc21/mariadb-aria:latest'
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: 'npm'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'npm'
    volumes:
      - ./data/mysql:/var/lib/mysql
EOF

# Container starten
docker compose up -d

echo "Nginx Proxy Manager wurde erfolgreich installiert."
echo "Web-Interface ist verfügbar unter: http://<Container-IP>:81"
echo "Standard-Login: admin@example.com / changeme"
EOF

# Container starten
docker compose up -d

echo "Nginx Proxy Manager wurde erfolgreich installiert."
echo "Web-Interface ist verfügbar unter: http://<Container-IP>:81"
echo "Standard-Login: admin@example.com / changeme"