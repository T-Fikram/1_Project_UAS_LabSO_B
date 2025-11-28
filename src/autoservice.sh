#!/bin/bash
# FILE: src/autoservice.sh
# Fungsi: Membaca project.conf dan menjalankan backup.sh serta rotation-backup.sh sesuai jadwal.

# Tentukan lokasi file konfigurasi (Asumsi script ini ada di folder src/, jadi config ada di satu level di atasnya)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONF_FILE="$ROOT_DIR/project.conf"

# Cek apakah file config ada
if [[ ! -f "$CONF_FILE" ]]; then
    echo "Config file not found: $CONF_FILE"
    exit 1
fi

# Baca file config baris per baris (Lewati baris yang diawali #)
grep -v '^#' "$CONF_FILE" | while IFS='|' read -r SOURCE DEST RETENTION INTERVAL; do
    # Bersihkan spasi jika ada
    SOURCE=$(echo "$SOURCE" | xargs)
    DEST=$(echo "$DEST" | xargs)
    RETENTION=$(echo "$RETENTION" | xargs)
    INTERVAL=$(echo "$INTERVAL" | xargs)

    # Validasi baris config kosong
    if [[ -z "$SOURCE" ]]; then continue; fi

    # --- LOGIKA PENGECEKAN JADWAL (Simpel) ---
    # Karena systemd timer nanti akan menjalankan script ini secara berkala (misal tiap jam),
    # Kita perlu mengecek kapan terakhir kali folder ini dibackup.
    # Kita akan cek waktu modifikasi file backup terakhir di folder tujuan.
    
    LAST_BACKUP=$(ls -t "$DEST"/backup-*.tar.gz 2>/dev/null | head -n 1)
    
    RUN_BACKUP=false
    
    if [[ -z "$LAST_BACKUP" ]]; then
        # Belum pernah backup sama sekali -> Jalankan!
        echo "[AUTO] First time backup for $SOURCE"
        RUN_BACKUP=true
    else
        # Hitung selisih waktu
        NOW_EPOCH=$(date +%s)
        LAST_EPOCH=$(date -r "$LAST_BACKUP" +%s)
        DIFF_HOURS=$(( (NOW_EPOCH - LAST_EPOCH) / 3600 ))
        
        if [[ "$DIFF_HOURS" -ge "$INTERVAL" ]]; then
            echo "[AUTO] Interval reached ($DIFF_HOURS >= $INTERVAL hours). Backing up $SOURCE"
            RUN_BACKUP=true
        else
            echo "[SKIP] $SOURCE already backed up $DIFF_HOURS hours ago (Interval: $INTERVAL)"
        fi
    fi

    # Eksekusi jika waktunya tiba
    if [[ "$RUN_BACKUP" == "true" ]]; then
        # 1. Jalankan Backup
        bash "$SCRIPT_DIR/backup.sh" "$SOURCE" "$DEST" "$RETENTION"
        
        # 2. Jalankan Rotasi (Hanya jika backup sukses/selesai)
        bash "$SCRIPT_DIR/rotation-backup.sh" "$DEST" "$RETENTION"
    fi

done