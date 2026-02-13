#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/Protactin96/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/AKVorrat/netzbremse-measurement
#         https://github.com/lwndp/netzbremse-dashboard

APP="Netzbremse"
var_tags="${var_tags:-network}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /root/netzbremse-measurement || ! -d /root/netzbremse-dashboard ]]; then
    msg_error "No ${APP} installation found in this container!"
    exit
  fi

  msg_info "Updating OS"
  $STD apt update
  $STD apt -y upgrade
  msg_ok "OS updated"

  msg_info "Updating netzbremse-measurement dependencies"
  cd /root/netzbremse-measurement || exit 1
  $STD npm install
  msg_ok "Updated netzbremse-measurement"

  msg_info "Updating netzbremse-dashboard dependencies"
  cd /root/netzbremse-dashboard || exit 1
  if [[ -x /root/.local/bin/uv ]]; then
    $STD /root/.local/bin/uv sync || true
  fi
  msg_ok "Updated netzbremse-dashboard"

  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access the dashboard on the container's IP and configured Streamlit port.${CL}"
