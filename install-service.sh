#!/bin/bash
# FILE: install-service.sh
# Fungsi: Menginstall systemd service dan timer untuk user saat ini.

# Setup Path Absolut (Penting untuk Systemd)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$ROOT_DIR/src/autoservice.sh"
SERVICE_NAME="uaspraktikum-backup"

# Lokasi User Systemd
SYSTEMD_DIR="$HOME/.config/systemd/user"

echo "=== INSTALLER SERVICE AUTOBACKUP ==="
echo "Path Script: $SCRIPT_PATH"

# 1. Cek Permission Script
if [[ ! -x "$SCRIPT_PATH" ]]; then
    echo "Error: $SCRIPT_PATH belum executable."
    echo "Menjalankan chmod +x..."
    chmod +x "$SCRIPT_PATH"
fi

# 2. Buat Folder Systemd User jika belum ada
mkdir -p "$SYSTEMD_DIR"

# 3. Buat File .service
cat > "$SYSTEMD_DIR/$SERVICE_NAME.service" <<EOF
[Unit]
Description=Layanan Backup Otomatis UAS Lab SO
Wants=$SERVICE_NAME.timer

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
EOF

# 4. Buat File .timer (Jalan setiap 1 jam)
# Catatan: Timer ini hanya memicu pengecekan. 
# Logika "interval 2 jam" atau "12 jam" tetap diatur di dalam autoservice.sh
cat > "$SYSTEMD_DIR/$SERVICE_NAME.timer" <<EOF
[Unit]
Description=Timer untuk Backup Otomatis UAS
Requires=$SERVICE_NAME.service

[Timer]
Unit=$SERVICE_NAME.service
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

echo "File service dibuat di: $SYSTEMD_DIR"

# 5. Reload dan Enable
echo "Mengaktifkan service..."
systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE_NAME.timer"

echo "------------------------------------------------"
echo "Status Timer:"
systemctl --user list-timers --no-pager | grep "$SERVICE_NAME"
echo "------------------------------------------------"
echo "✅ Instalasi Selesai!"
echo "Service akan berjalan di background setiap jam untuk mengecek jadwal backup."
echo "Untuk melihat log systemd: journalctl --user -u $SERVICE_NAME.service"
echo "Untuk uninstall: systemctl --user disable --now $SERVICE_NAME.timer"