#!/bin/bash
# FILE: src/utils.sh

CONF_FILE="$(dirname "${BASH_SOURCE[0]}")/../project.conf"
SERVICE_NAME="uaspraktikum-backup"

# Generate ID Acak
generate_id() {
    echo "backup@$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 4)"
}

# Cek apakah Service Terinstall (Ada file unit-nya)
is_service_installed() {
    # Cek keberadaan file service di folder systemd user
    if [[ -f "$HOME/.config/systemd/user/$SERVICE_NAME.service" ]]; then
        return 0 # Terinstall
    else
        return 1 # Belum
    fi
}

# Cek apakah Service Berjalan (Timer aktif)
is_service_active() {
    if systemctl --user is-active --quiet "$SERVICE_NAME.timer"; then
        return 0 # Aktif
    else
        return 1 # Mati/Stopped
    fi
}

# Fungsi Validasi Kesehatan Service
# Return 0: Sehat
# Return 1: Belum Install (FATAL)
# Return 2: Stopped (WARNING)
check_service_health() {
    if ! is_service_installed; then
        return 1
    elif ! is_service_active; then
        return 2
    fi
    return 0
}