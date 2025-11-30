#!/bin/bash
# FILE: src/rotation-backup.sh
# Usage: ./rotation-backup.sh <DEST> <RETENTION> <ID>

DEST_DIR="$1"
RETENTION_DAYS="$2"
BACKUP_ID="$3" # --- BARU: Terima ID ---

if [[ -z "$DEST_DIR" ]] || [[ -z "$RETENTION_DAYS" ]] || [[ -z "$BACKUP_ID" ]]; then
    echo "Error: Parameter kurang. Usage: $0 <dest> <days> <id>"
    exit 1
fi

if [[ ! -d "$DEST_DIR" ]]; then
    exit 1
fi

LOG_FILE="$DEST_DIR/backup.log"

# --- BARU: Cari pola nama file berdasarkan ID ---
# Pola: ID-*.tar.gz
find "$DEST_DIR" -name "${BACKUP_ID}-*.tar.gz" -type f -mtime +"$RETENTION_DAYS" -print0 | while IFS= read -r -d '' FILE; do
    if rm "$FILE"; then
        DATE_NOW=$(date +"%Y-%m-%d %H:%M:%S")
        echo "$DATE_NOW | Rotation: Deleted old backup $(basename "$FILE") (> $RETENTION_DAYS days)" >> "$LOG_FILE"
        echo "Rotasi: Menghapus $(basename "$FILE")"
    fi
done