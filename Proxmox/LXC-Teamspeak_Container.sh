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

journalctl -u teamspeak-server
cd /opt/teamspeak-server/logs/