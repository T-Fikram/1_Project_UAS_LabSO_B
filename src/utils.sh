#!/bin/bash
# FILE: src/utils.sh

CONF_FILE="$(dirname "${BASH_SOURCE[0]}")/../project.conf"
SERVICE_NAME="autobackup"

# Generate ID Acak
generate_id() {
    echo "backup@$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 4)"
}

# Cek Service Installed
is_service_installed() {
    if [[ -f "$HOME/.config/systemd/user/$SERVICE_NAME.service" ]]; then
        return 0
    else
        return 1
    fi
}

# Cek Service Active
is_service_active() {
    if systemctl --user is-active --quiet "$SERVICE_NAME.timer"; then
        return 0
    else
        return 1
    fi
}

check_service_health() {
    if ! is_service_installed; then
        return 1
    elif ! is_service_active; then
        return 2
    fi
    return 0
}

# Validasi Cron Format Sederhana
validate_cron() {
    local cron_str="$1"
    
    read -r -a fields <<< "$cron_str"
    if [[ "${#fields[@]}" -ne 5 ]]; then
        return 1 # Format salah jumlah kolom
    fi

    check_range() {
        local val="$1"
        local min="$2"
        local max="$3"

        # Bypass simbol *, */n
        if [[ "$val" == "*" ]] || [[ "$val" =~ ^\*/[0-9]+$ ]]; then
            return 0
        fi

        # Cek apakah angka valid
        if [[ ! "$val" =~ ^[0-9]+$ ]]; then
            return 1
        fi

        # Cek range
        if (( val < min || val > max )); then
            return 1
        fi
        return 0
    }

    # Validasi per kolom
    # Menit (0-59), Jam (0-23), Tanggal (1-31), Bulan (1-12), Hari (0-6)
    check_range "${fields[0]}" 0 59 || return 2
    check_range "${fields[1]}" 0 23 || return 3
    check_range "${fields[2]}" 1 31 || return 4
    check_range "${fields[3]}" 1 12 || return 5
    check_range "${fields[4]}" 0 6  || return 6

    return 0
}