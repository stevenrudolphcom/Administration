# Vorlage für die Installation von Rustdesk Server in einem LXC-Container

Diese Vorlage führt Sie Schritt für Schritt durch die Erstellung und Konfiguration eines LXC-Containers für Rustdesk Server in einer Proxmox-Umgebung. Rustdesk Server besteht aus zwei Komponenten: `hbbs` (ID/Rendezvous-Server) und `hbbr` (Relay-Server), die über Docker bereitgestellt werden. Rustdesk ist eine Open-Source-Alternative zu TeamViewer für Fernzugriff.

## Voraussetzungen
- Proxmox VE installiert und konfiguriert.
- Zugriff auf die Proxmox-Weboberfläche.
- Ein Debian-Template (z. B. Debian 12 Bookworm oder Trixie unstable) heruntergeladen in Proxmox.
- Öffnen Sie die folgenden Ports auf dem Proxmox-Host (Firewall/Firewall-Regeln):
  - 21114 (TCP): Web-Konsole (nur Pro-Version)
  - 21115 (TCP): NAT-Typ-Test
  - 21116 (TCP/UDP): ID-Registrierung, Heartbeat, TCP Hole Punching
  - 21117 (TCP): Relay-Service
  - 21118 (TCP): Web-Client-Support
  - 21119 (TCP): Web-Client-Support
- Hinweis: Wenn der Container hinter NAT steht, leiten Sie diese Ports an den Container weiter.

## Schritt 1: LXC-Container erstellen
1. Öffnen Sie die Proxmox-Weboberfläche.
2. Navigieren Sie zu **Datacenter > [Ihr Node] > LXC**.
3. Klicken Sie auf **Create CT** (Container erstellen).
4. Konfigurieren Sie den Container:
   - **Hostname**: z. B. `rustdesk-server`
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
   - Setzen Sie **Start at boot** auf **Yes** (damit der Container beim Host-Start automatisch startet).
6. Klicken Sie auf **Create** und warten Sie, bis der Container erstellt ist.

## Schritt 2: Container starten und vorbereiten
1. Starten Sie den Container über die Proxmox-Oberfläche.
2. Öffnen Sie eine Konsole zum Container (Shell-Zugang).
3. Aktualisieren Sie das System:
   ```
   apt update && apt upgrade -y
   ```

## Schritt 3: Installationsskript ausführen
Kopieren Sie das folgende Bash-Skript in den Container (z. B. als `install_rustdesk.sh`) und führen Sie es aus. Das Skript installiert Docker, richtet Rustdesk Server ein und startet die Services.

```bash
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
```

## Schritt 4: Nach der Installation
1. **Server-Informationen abrufen**:
   - Führen Sie `docker logs hbbs` aus, um den generierten Sicherheitsschlüssel (Key) zu erhalten. Notieren Sie ihn – Sie benötigen ihn für die Client-Konfiguration.
   - Prüfen Sie den Status: `docker ps` (sollte `hbbs` und `hbbr` zeigen).

2. **Clients konfigurieren**:
   - Öffnen Sie Rustdesk auf Ihren Geräten.
   - Gehen Sie zu **Einstellungen > Netzwerk**.
   - Setzen Sie **ID-Server** und **Relay-Server** auf die IP-Adresse Ihres Containers (z. B. `192.168.1.100`).
   - Geben Sie den Key ein, falls Sie einen festen gesetzt haben oder verwenden Sie den generierten.

3. **Automatischer Start**:
   - Der Container startet automatisch beim Host-Start (wegen "Start at boot").
   - Die Docker-Container starten automatisch neu, wenn Docker läuft.

## Troubleshooting
- **Container startet nicht**: Prüfen Sie die Proxmox-Logs und stellen Sie sicher, dass "Nesting" aktiviert ist.
- **Ports nicht erreichbar**: Überprüfen Sie die Firewall auf dem Proxmox-Host und die Port-Weiterleitung.
- **Docker-Fehler**: Führen Sie `docker compose logs` aus, um Fehler zu sehen.
- **Key nicht gefunden**: Starten Sie die Container neu mit `docker compose restart` und prüfen Sie die Logs erneut.

Bei weiteren Fragen konsultieren Sie die [offizielle Rustdesk-Dokumentation](https://rustdesk.com/docs/en/self-host/rustdesk-server-oss/docker/).