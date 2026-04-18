#!/bin/bash

# RustDesk Server LXC Container Setup Script für Debian Trixie
# Dieses Skript installiert Docker und richtet RustDesk Server (hbbs und hbbr) in einem LXC-Container ein.

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

# Verzeichnis für RustDesk Server erstellen
mkdir -p /opt/rustdesk-server
cd /opt/rustdesk-server

# Docker Compose Datei erstellen
cat <<EOF > docker-compose.yml
services:
  hbbs:
    container_name: hbbs
    image: rustdesk/rustdesk-server:latest
    command: hbbs
    volumes:
      - ./data:/root
    network_mode: "host"
    depends_on:
      - hbbr
    restart: unless-stopped

  hbbr:
    container_name: hbbr
    image: rustdesk/rustdesk-server:latest
    command: hbbr
    volumes:
      - ./data:/root
    network_mode: "host"
    restart: unless-stopped
EOF

# Container starten
docker compose up -d

echo "RustDesk Server wurde erfolgreich installiert."
echo "Stellen Sie sicher, dass die folgenden Ports auf dem Host geöffnet sind:"
echo "  - 21114 (TCP): Web-Konsole (nur Pro-Version)"
echo "  - 21115 (TCP): NAT-Typ-Test"
echo "  - 21116 (TCP/UDP): ID-Registrierung, Heartbeat, TCP Hole Punching"
echo "  - 21117 (TCP): Relay-Service"
echo "  - 21118 (TCP): Web-Client-Support"
echo "  - 21119 (TCP): Web-Client-Support"
echo ""
echo "Konfigurieren Sie Ihre RustDesk-Clients, um diesen Server zu verwenden."

docker ps
docker logs hbbs
docker compose logs -f

