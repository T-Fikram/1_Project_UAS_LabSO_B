#!/bin/bash
# FILE: src/utils.sh

CONF_FILE="$(dirname "${BASH_SOURCE[0]}")/../project.conf"
SERVICE_NAME="uaspraktikum-backup"

# Generate ID Acak (backup + 4 karakter)
generate_id() {
    echo "backup$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 4)"
}

# Cek apakah Service Terinstall
is_service_installed() {
    if systemctl --user list-unit-files | grep -q "^$SERVICE_NAME.service"; then
        return 0 # True
    else
        return 1 # False
    fi
}

# Cek apakah Service Berjalan (Active)
is_service_active() {
    if systemctl --user is-active --quiet "$SERVICE_NAME.timer"; then
        return 0
    else
        return 1
    fi
}

# Fungsi Validasi Service (Peringatan)
check_service_health() {
    if ! is_service_installed; then
        echo -e "\e[31m[WARNING] Service belum terinstall!\e[0m Otomatisasi tidak akan berjalan."
        echo "Gunakan: ./src/main.sh --install-service"
        return 1
    elif ! is_service_active; then
        echo -e "\e[33m[WARNING] Service terinstall tapi STOPPED.\e[0m"
        echo "Gunakan: ./src/main.sh --start-service"
        return 2
    fi
    return 0
}