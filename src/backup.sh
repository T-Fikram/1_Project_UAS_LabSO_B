#!/bin/bash

# src/backup.sh
# Menerima 3 argumen: SOURCE, DESTINATION, RETENTION (Opsional)

SOURCE_DIR="$1"
DEST_DIR="$2"
RETENTION="$3"

# 1. Validasi Input
if [[ -z "$SOURCE_DIR" ]] || [[ -z "$DEST_DIR" ]]; then
    echo "Error: Parameter tidak lengkap."
    echo "Usage: $0 <source_dir> <dest_dir> <retention_days>"
    exit 1
fi

# 2. Validasi Folder
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Folder sumber '$SOURCE_DIR' tidak ditemukan."
    exit 1
fi

# Buat folder tujuan jika belum ada
mkdir -p "$DEST_DIR" || { echo "Error: Gagal membuat folder tujuan."; exit 1; }

# Tentukan Lokasi Log (SESUAI REQUEST: Di folder tujuan)
LOG_FILE="$DEST_DIR/backup.log"

# 3. Persiapan Variabel
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
FILENAME="backup-${TIMESTAMP}.tar.gz"
FILE_PATH="$DEST_DIR/$FILENAME"
DATE_NOW=$(date +"%Y-%m-%d %H:%M:%S")

# --- LOG START (SESUAI REQUEST: Catat waktu mulai) ---
echo "$DATE_NOW | Backup started: $SOURCE_DIR" >> "$LOG_FILE"
echo "Memproses backup: $SOURCE_DIR -> $FILE_PATH"

# 4. Eksekusi Backup
# Menggunakan parent directory agar struktur dalam tar rapi
PARENT_DIR=$(dirname "$SOURCE_DIR")
BASE_NAME=$(basename "$SOURCE_DIR")

if tar -czf "$FILE_PATH" -C "$PARENT_DIR" "$BASE_NAME" 2>/dev/null; then
    STATUS="SUCCESS"
    EXIT_CODE=0
else
    STATUS="FAILED"
    EXIT_CODE=1
fi

# 5. Hitung Ukuran & Waktu Selesai
DATE_FINISH=$(date +"%Y-%m-%d %H:%M:%S")
if [[ -f "$FILE_PATH" ]]; then
    SIZE=$(du -h "$FILE_PATH" | cut -f1)
else
    SIZE="0"
fi

# --- LOG FINISH (SESUAI REQUEST: Catat hasil akhir) ---
# Format: Waktu | Backup finished: nama_file
# Format: Waktu | Size: ... | Status: ...
{
    echo "$DATE_FINISH | Backup finished: $(basename "$FILE_PATH")"
    echo "$DATE_FINISH | Size: $SIZE | Status: $STATUS"
} >> "$LOG_FILE"

# Output ke layar (User Feedback)
if [[ "$STATUS" == "SUCCESS" ]]; then
    echo "Backup Berhasil!"
    echo "File: $FILE_PATH"
    echo "Log tersimpan di: $LOG_FILE"
else
    echo "Backup Gagal! Cek log."
fi

exit $EXIT_CODE