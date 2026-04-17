# Vorlage für die Installation von Nginx Proxy Manager in einem LXC-Container

Diese Vorlage führt Sie Schritt für Schritt durch die Erstellung und Konfiguration eines LXC-Containers für Nginx Proxy Manager (NPM) in einer Proxmox-Umgebung. Nginx Proxy Manager ist ein Web-basiertes Tool zur Verwaltung von Nginx-Proxy-Konfigurationen, Reverse-Proxys und SSL-Zertifikaten.

## Voraussetzungen
- Proxmox VE installiert und konfiguriert.
- Zugriff auf die Proxmox-Weboberfläche.
- Ein Debian-Template (z. B. Debian 12 Bookworm oder Trixie unstable) heruntergeladen in Proxmox.

## Schritt 1: LXC-Container erstellen
1. Öffnen Sie die Proxmox-Weboberfläche.
2. Navigieren Sie zu **Datacenter > [Ihr Node] > LXC**.
3. Klicken Sie auf **Create CT** (Container erstellen).
4. Konfigurieren Sie den Container:
   - **Hostname**: z. B. `nginx-proxy-manager`
   - **Template**: Wählen Sie ein Debian-Template (z. B. `debian-12-standard_12.1-1_amd64.tar.zst` für Bookworm oder ein Trixie-Template, falls verfügbar).
   - **Password**: Setzen Sie ein Root-Passwort.
   - **Storage**: Wählen Sie einen Speicherpool (z. B. `local-lvm`).
   - **Disk size**: Mindestens 20 GB.
   - **CPU**: 1-2 Kerne.
   - **Memory**: 1024-2048 MB (erweiterbar).
   - **Network**: Bridge-Modus, statische IP oder DHCP.
5. Unter **Options**:
   - Aktivieren Sie **Nesting** (für Docker-Unterstützung).
   - Aktivieren Sie **FUSE** (falls benötigt).
   - Setzen Sie **Unprivileged container** auf **No** (für privilegierte Operationen).
6. Klicken Sie auf **Create** und warten Sie, bis der Container erstellt ist.

## Schritt 2: Container starten und vorbereiten
1. Starten Sie den Container über die Proxmox-Oberfläche.
2. Öffnen Sie eine Konsole zum Container (Shell-Zugang).
3. Aktualisieren Sie das System:
   ```
   apt update && apt upgrade -y
   ```

## Schritt 3: Installationsskript ausführen
Kopieren Sie das folgende Bash-Skript in den Container (z. B. als `install_npm.sh`) und führen Sie es aus. Das Skript installiert Docker, richtet Nginx Proxy Manager ein und startet die Services.

```bash
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
```

### Ausführung des Skripts:
1. Speichern Sie das Skript als `install_npm.sh` im Container.
2. Machen Sie es ausführbar: `chmod +x install_npm.sh`
3. Führen Sie es aus: `./install_npm.sh`

## Schritt 4: Konfiguration und Zugriff
- **IP-Adresse prüfen**: Verwenden Sie `ip addr show` im Container, um die IP zu ermitteln.
- **Ports freigeben**: Stellen Sie sicher, dass die Ports 80, 81 und 443 in der Proxmox-Firewall und dem Container freigegeben sind.
- **Erster Zugriff**: Öffnen Sie einen Browser und gehen Sie zu `http://<IP>:81`.
- **SSL-Zertifikate**: Verwenden Sie die integrierte Let's Encrypt-Unterstützung für HTTPS.

## Schritt 5: Wartung und Backups
- **Updates**: Aktualisieren Sie Docker-Images mit `cd /opt/nginx-proxy-manager && docker compose pull && docker compose up -d`.
- **Backups**: Sichern Sie das Verzeichnis `/opt/nginx-proxy-manager/data`.
- **Logs**: Überprüfen Sie Logs mit `docker compose logs`.
- **Stoppen/Starten**: `docker compose stop` / `docker compose start`.

## Fehlerbehebung
- **Docker startet nicht**: Überprüfen Sie, ob "Nesting" im Container aktiviert ist.
- **Port-Konflikte**: Stellen Sie sicher, dass die Ports nicht von anderen Services verwendet werden.
- **Datenbank-Fehler**: Löschen Sie `./data/mysql` und starten Sie neu, wenn Probleme auftreten.

Diese Vorlage ist vollständig und sollte ohne Anpassungen funktionieren. Bei Fragen oder Problemen passen Sie die Konfiguration an Ihre Umgebung an.