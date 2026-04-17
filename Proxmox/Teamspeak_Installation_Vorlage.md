# Vorlage für die Installation von TeamSpeak Server in einem LXC-Container

Diese Vorlage führt Sie Schritt für Schritt durch die Erstellung und Konfiguration eines LXC-Containers für TeamSpeak 3 Server in einer Proxmox-Umgebung. TeamSpeak ist eine VoIP-Software für Sprachkommunikation in Teams oder Communities.

## Voraussetzungen
- Proxmox VE installiert und konfiguriert.
- Zugriff auf die Proxmox-Weboberfläche.
- Ein Debian- oder Ubuntu-Template (z. B. Debian 12 Bookworm oder Ubuntu 22.04 LTS) heruntergeladen in Proxmox.

## Schritt 1: LXC-Container erstellen
1. Öffnen Sie die Proxmox-Weboberfläche.
2. Navigieren Sie zu **Datacenter > [Ihr Node] > LXC**.
3. Klicken Sie auf **Create CT** (Container erstellen).
4. Konfigurieren Sie den Container:
   - **Hostname**: z. B. `teamspeak-server`
   - **Template**: Wählen Sie ein Debian- oder Ubuntu-Template (z. B. `debian-12-standard_12.1-1_amd64.tar.zst` oder `ubuntu-22.04-standard_22.04-1_amd64.tar.zst`).
   - **Password**: Setzen Sie ein Root-Passwort.
   - **Storage**: Wählen Sie einen Speicherpool (z. B. `local-lvm`).
   - **Disk size**: Mindestens 10 GB.
   - **CPU**: 1-2 Kerne.
   - **Memory**: 512-1024 MB (erweiterbar).
   - **Network**: Bridge-Modus, statische IP oder DHCP.
5. Unter **Options**:
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
Kopieren Sie das folgende Bash-Skript in den Container (z. B. als `install_teamspeak.sh`) und führen Sie es aus. Das Skript lädt die neueste TeamSpeak-Server-Version herunter, installiert sie und richtet einen Systemd-Service ein.

```bash
#!/bin/bash

# TeamSpeak Server Installation Script
# Führen Sie dieses Skript als Root im LXC-Container aus.

# Aktuelle Version ermitteln
RELEASE=$(curl -fsSL https://teamspeak.com/en/downloads/#server | grep -oP 'teamspeak3-server_linux_amd64-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)

# TeamSpeak herunterladen und extrahieren
curl -fsSL "https://files.teamspeak-services.com/releases/server/${RELEASE}/teamspeak3-server_linux_amd64-${RELEASE}.tar.bz2" -o ts3server.tar.bz2
tar -xf ./ts3server.tar.bz2
mv teamspeak3-server_linux_amd64/ /opt/teamspeak-server/

# Lizenz akzeptieren und Version speichern
touch /opt/teamspeak-server/.ts3server_license_accepted
echo "${RELEASE}" >~/.teamspeak-server

# Aufräumen
rm -f ~/ts3server.tar.bz2

# Systemd-Service erstellen
cat <<EOF >/etc/systemd/system/teamspeak-server.service
[Unit]
Description=TeamSpeak3 Server
Wants=network-online.target
After=network.target

[Service]
WorkingDirectory=/opt/teamspeak-server
User=root
Type=forking
ExecStart=/opt/teamspeak-server/ts3server_startscript.sh start
ExecStop=/opt/teamspeak-server/ts3server_startscript.sh stop
ExecReload=/opt/teamspeak-server/ts3server_startscript.sh restart
Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target
EOF

# Service aktivieren und starten
systemctl daemon-reload
systemctl enable teamspeak-server
systemctl start teamspeak-server

echo "TeamSpeak Server installiert und gestartet."
echo "Logs: journalctl -u teamspeak-server"
echo "Server-Verzeichnis: /opt/teamspeak-server"
```

### Ausführung des Skripts:
1. Speichern Sie das Skript als `install_teamspeak.sh` im Container.
2. Machen Sie es ausführbar: `chmod +x install_teamspeak.sh`
3. Führen Sie es aus: `./install_teamspeak.sh`

## Schritt 4: Konfiguration und Zugriff
- **IP-Adresse prüfen**: Verwenden Sie `ip addr show` im Container, um die IP zu ermitteln.
- **Ports freigeben**: Stellen Sie sicher, dass die Standard-TeamSpeak-Ports (9987 UDP für Voice, 10011 TCP für Server Query, 30033 TCP für File Transfer) in der Proxmox-Firewall freigegeben sind.
- **Erster Zugriff**: Verbinden Sie sich mit einem TeamSpeak-Client (z. B. TeamSpeak 3 Client) zu `<Container-IP>:9987`.
- **Admin-Token**: Nach dem ersten Start finden Sie den Server-Admin-Token in den Logs: `journalctl -u teamspeak-server` oder in `/opt/teamspeak-server/logs/`. Suchen Sie nach "token=".
- **Konfiguration**: Bearbeiten Sie `/opt/teamspeak-server/ts3server.ini` für erweiterte Einstellungen (z. B. Server-Name, Passwort).

## Schritt 5: Wartung und Backups
- **Updates**: Überprüfen Sie regelmäßig auf neue TeamSpeak-Versionen und aktualisieren Sie manuell (Skript neu ausführen nach Backup).
- **Backups**: Sichern Sie das Verzeichnis `/opt/teamspeak-server` (enthält Konfiguration, Datenbanken und Logs).
- **Logs**: Überprüfen Sie Logs mit `journalctl -u teamspeak-server` oder in `/opt/teamspeak-server/logs/`.
- **Stoppen/Starten**: `systemctl stop teamspeak-server` / `systemctl start teamspeak-server`.
- **Neustart**: `systemctl restart teamspeak-server`.

## Fehlerbehebung
- **Service startet nicht**: Überprüfen Sie die Logs mit `journalctl -u teamspeak-server -f`.
- **Port-Konflikte**: Stellen Sie sicher, dass die Ports nicht von anderen Services verwendet werden.
- **Download-Fehler**: Überprüfen Sie die Internetverbindung und versuchen Sie das Skript erneut.
- **Lizenz**: Das Skript akzeptiert automatisch die Lizenz; für kommerzielle Nutzung benötigen Sie eine offizielle Lizenz von TeamSpeak.

Diese Vorlage ist vollständig und sollte ohne Anpassungen funktionieren. Bei Fragen oder Problemen passen Sie die Konfiguration an Ihre Umgebung an.