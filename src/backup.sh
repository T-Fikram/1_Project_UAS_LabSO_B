#!/bin/bash
# FILE: src/backup.sh
# Usage: ./backup.sh <SOURCE> <DEST> <RETENTION> <ID>

SOURCE_DIR="$1"
DEST_DIR="$2"
RETENTION="$3"
BACKUP_ID="$4"

# 1. Validasi Input
if [[ -z "$SOURCE_DIR" ]] || [[ -z "$DEST_DIR" ]] || [[ -z "$BACKUP_ID" ]]; then
    echo "Error: Parameter tidak lengkap."
    echo "Usage: $0 <source> <dest> <retention> <id>"
    exit 1
fi

# 2. Validasi Folder
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Folder sumber '$SOURCE_DIR' tidak ditemukan."
    exit 1
fi

mkdir -p "$DEST_DIR" || { echo "Error: Gagal membuat folder tujuan."; exit 1; }
LOG_FILE="$DEST_DIR/backup.log"

# 3. Persiapan Variabel
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
FILENAME="${BACKUP_ID}-${TIMESTAMP}.tar.gz"
FILE_PATH="$DEST_DIR/$FILENAME"
DATE_NOW=$(date +"%Y-%m-%d %H:%M:%S")

# --- UPDATE: Tambahkan ID di Log ---
echo "$DATE_NOW | [ID: $BACKUP_ID] Backup started: $SOURCE_DIR" >> "$LOG_FILE"
echo "Memproses backup: $SOURCE_DIR -> $FILE_PATH"

# 4. Eksekusi Backup
PARENT_DIR=$(dirname "$SOURCE_DIR")
BASE_NAME=$(basename "$SOURCE_DIR")

if tar -czf "$FILE_PATH" -C "$PARENT_DIR" "$BASE_NAME" 2>/dev/null; then
    STATUS="SUCCESS"
    EXIT_CODE=0
else
    STATUS="FAILED"
    EXIT_CODE=1
fi

# 5. Log Finish
DATE_FINISH=$(date +"%Y-%m-%d %H:%M:%S")
if [[ -f "$FILE_PATH" ]]; then
    SIZE=$(du -h "$FILE_PATH" | cut -f1)
else
    SIZE="0"
fi

# --- UPDATE: Tambahkan ID di Log Finish ---
{
    echo "$DATE_FINISH | [ID: $BACKUP_ID] Backup finished: $(basename "$FILE_PATH")"
    echo "$DATE_FINISH | [ID: $BACKUP_ID] Size: $SIZE | Status: $STATUS"
} >> "$LOG_FILE"

if [[ "$STATUS" == "SUCCESS" ]]; then
    echo "Backup Berhasil: $FILENAME"
else
    echo "Backup Gagal!"
fi

exit $EXIT_CODE