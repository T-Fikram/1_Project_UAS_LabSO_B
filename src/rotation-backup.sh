#!/bin/bash
# FILE: src/rotation-backup.sh
# Fungsi: Menghapus file backup yang lebih tua dari X hari
# Argumen: $1 = Folder Tujuan, $2 = Jumlah Hari Retensi

DEST_DIR="$1"
RETENTION_DAYS="$2"

# 1. Validasi Input
if [[ -z "$DEST_DIR" ]] || [[ -z "$RETENTION_DAYS" ]]; then
    echo "Error: Parameter kurang. Usage: $0 <dest_dir> <retention_days>"
    exit 1
fi

if [[ ! -d "$DEST_DIR" ]]; then
    echo "Error: Folder tujuan tidak ditemukan ($DEST_DIR)"
    exit 1
fi

LOG_FILE="$DEST_DIR/backup.log"

# 2. Proses Rotasi
# Penjelasan: find mencari file dengan pola 'backup-*.tar.gz' yang dimodifikasi lebih dari +Hari
# Kita lakukan loop agar bisa mencatat log satu per satu sebelum dihapus.

find "$DEST_DIR" -name "backup-*.tar.gz" -type f -mtime +"$RETENTION_DAYS" -print0 | while IFS= read -r -d '' FILE; do
    # Hapus file
    if rm "$FILE"; then
        DATE_NOW=$(date +"%Y-%m-%d %H:%M:%S")
        # Catat ke Log
        echo "$DATE_NOW | Rotation: Deleted old backup $(basename "$FILE") (> $RETENTION_DAYS days)" >> "$LOG_FILE"
        echo "Deleted: $(basename "$FILE")"
    else
        echo "Gagal menghapus: $FILE"
    fi
done