#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/AKVorrat/netzbremse-measurement
#         https://github.com/lwndp/netzbremse-dashboard

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies (git, curl, nodejs, npm, chromium, python3, pip)"
$STD apt-get install -y git curl nodejs npm chromium python3 python3-pip
msg_ok "Dependencies installed"

msg_info "Installing uv"
curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1
msg_ok "uv installed"

msg_info "Creating /data directory"
mkdir -p /data
chown root:root /data
msg_ok "/data created"

msg_info "Cloning netzbremse-measurement"
cd /root || exit 1
if [[ ! -d netzbremse-measurement ]]; then
  git clone https://github.com/AKVorrat/netzbremse-measurement.git
fi
msg_ok "Cloned netzbremse-measurement"

msg_info "Installing netzbremse-measurement dependencies"
cd /root/netzbremse-measurement || exit 1
$STD npm install
msg_ok "Installed netzbremse-measurement dependencies"

msg_info "Cloning netzbremse-dashboard"
cd /root || exit 1
if [[ ! -d netzbremse-dashboard ]]; then
  git clone https://github.com/lwndp/netzbremse-dashboard.git
fi
msg_ok "Cloned netzbremse-dashboard"

msg_info "Installing netzbremse-dashboard dependencies"
cd /root/netzbremse-dashboard || exit 1
if [[ -x /root/.local/bin/uv ]]; then
  $STD /root/.local/bin/uv sync || true
else
  # Fallback: try requirements.txt if uv unavailable
  if [[ -f requirements.txt ]]; then
    $STD pip3 install -r requirements.txt
  fi
fi
msg_ok "Installed netzbremse-dashboard dependencies"

msg_info "Creating environment file for measurement service"
/usr/bin/env bash -c 'cat <<EOF >/etc/netzbremse-measurement.env
NB_SPEEDTEST_ACCEPT_POLICY=true
PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
NB_SPEEDTEST_JSON_OUT_DIR=/data
EOF'
msg_ok "Environment file created"

msg_info "Creating systemd service for netzbremse-measurement"
/usr/bin/env bash -c 'cat <<EOF >/etc/systemd/system/netzbremse-measurement.service
[Unit]
Description=Netzbremse Measurement Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/netzbremse-measurement
EnvironmentFile=/etc/netzbremse-measurement.env
ExecStart=/usr/bin/npm start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF'
msg_ok "Measurement service created"

msg_info "Creating systemd service for netzbremse-dashboard"
/usr/bin/env bash -c 'cat <<EOF >/etc/systemd/system/netzbremse-dashboard.service
[Unit]
Description=Netzbremse Dashboard (Streamlit)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/netzbremse-dashboard
ExecStart=/root/.local/bin/uv run streamlit run app/app.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF'
msg_ok "Dashboard service created"

msg_info "Enabling and starting services"
systemctl daemon-reload
systemctl enable netzbremse-measurement.service netzbremse-dashboard.service
systemctl start netzbremse-measurement.service netzbremse-dashboard.service
msg_ok "Services enabled and started"

motd_ssh
customize
cleanup_lxc
