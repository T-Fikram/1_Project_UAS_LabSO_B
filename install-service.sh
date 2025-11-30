#!/bin/bash
# FILE: install-service.sh
# Fungsi: Install/Uninstall systemd service & timer + Autocomplete

# Setup Path Absolut
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$ROOT_DIR/src/autoservice.sh"
SERVICE_NAME="autobackup"
SYSTEMD_DIR="$HOME/.config/systemd/user"
COMPLETION_FILE="$ROOT_DIR/completion.sh"

# --- 0. PARSING ARGUMEN ---
MODE="install"
AUTO_YES=false
FORCE_UPDATE=false

for arg in "$@"; do
    case $arg in
        uninstall|--uninstall)
            MODE="uninstall"
            ;;
        -y|--yes)
            AUTO_YES=true
            ;;
        --update)
            FORCE_UPDATE=true
            ;;
    esac
done

# --- 1. LOGIKA UNINSTALL ---
if [[ "$MODE" == "uninstall" ]]; then
    echo "=== UNINSTALL SERVICE ==="

    # Validasi Konfirmasi (Kecuali ada flag -y)
    if [[ "$AUTO_YES" == "false" ]]; then
        echo -e "\e[1;31m[PERINGATAN] Tindakan ini akan:\e[0m"
        echo "1. Menghentikan service backup otomatis."
        echo "2. Menghapus file konfigurasi systemd."
        echo "3. Menghapus fitur autocomplete dari terminal."
        echo -n "Apakah Anda yakin ingin melanjutkan? (y/n): "
        read confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Uninstall dibatalkan."
            exit 0
        fi
    fi
    
    # Proses Uninstall
    if systemctl --user list-unit-files | grep -q "$SERVICE_NAME.timer"; then
        echo "Menghentikan service..."
        systemctl --user stop "$SERVICE_NAME.timer"
        systemctl --user disable "$SERVICE_NAME.timer"
        systemctl --user stop "$SERVICE_NAME.service" 2>/dev/null
    else
        echo "Service tidak aktif, melanjutkan pembersihan file..."
    fi

    rm -f "$SYSTEMD_DIR/$SERVICE_NAME.service"
    rm -f "$SYSTEMD_DIR/$SERVICE_NAME.timer"
    echo "File service dihapus."

    systemctl --user daemon-reload

    if [[ -f "$HOME/.bashrc" ]]; then
        sed -i "\|source $COMPLETION_FILE|d" "$HOME/.bashrc"
        echo "Konfigurasi .bashrc dibersihkan."
    fi

    echo "✅ Uninstall Selesai!"
    exit 0
fi

# --- 2. LOGIKA INSTALL ---
echo "=== INSTALLER SERVICE AUTOBACKUP ==="

# Cek apakah sudah terinstall
if [[ -f "$SYSTEMD_DIR/$SERVICE_NAME.service" ]]; then
    if [[ "$FORCE_UPDATE" == "true" ]]; then
        echo -e "\e[1;34m[UPDATE]\e[0m Service ditemukan. Mode update aktif. Menimpa konfigurasi..."
    else
        echo -e "\e[1;33m[SKIP]\e[0m Service sudah terinstall."
        echo "Gunakan opsi '--update' untuk memaksa install ulang/update konfigurasi."
        exit 0
    fi
fi

# ... (SISA KODE SAMA SEPERTI SEBELUMNYA) ...

echo "Path Script: $SCRIPT_PATH"

if [[ ! -x "$SCRIPT_PATH" ]]; then
    echo "Memberikan izin eksekusi ke script..."
    chmod +x "$SCRIPT_PATH"
fi

mkdir -p "$SYSTEMD_DIR"

cat > "$SYSTEMD_DIR/$SERVICE_NAME.service" <<EOF
[Unit]
Description=Layanan Backup Otomatis UAS Lab SO
Wants=$SERVICE_NAME.timer

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
EOF

cat > "$SYSTEMD_DIR/$SERVICE_NAME.timer" <<EOF
[Unit]
Description=Timer Menit untuk Backup UAS
Requires=$SERVICE_NAME.service

[Timer]
Unit=$SERVICE_NAME.service
OnCalendar=*-*-* *:*:00
Persistent=false

[Install]
WantedBy=timers.target
EOF

echo "File service diperbarui di: $SYSTEMD_DIR"

echo "Mengaktifkan service..."
systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE_NAME.timer"

echo "------------------------------------------------"
echo "Status Timer:"

# MENGGUNAKAN AWK UNTUK FORMATTING RAPI
# Penjelasan: Mengambil output, membuang header, lalu mencetak kolom tertentu dengan spasi yang diatur
systemctl --user list-timers --no-pager | grep "$SERVICE_NAME" | \
awk '{printf "NEXT: %-20s %-5s | LAST: %-20s | UNIT: %s\n", $1" "$2, $3, $6" "$7, $10}'

echo "------------------------------------------------"
echo "Memasang fitur Autocomplete..."
bash "$ROOT_DIR/src/main.sh" --install-completion

echo "------------------------------------------------"
echo "✅ Instalasi Selesai!"