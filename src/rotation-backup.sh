#!/bin/bash
# FILE: src/rotation-backup.sh

DEST_DIR="$1"
RETENTION_DAYS="$2"
BACKUP_ID="$3"

if [[ -z "$DEST_DIR" || -z "$RETENTION_DAYS" || -z "$BACKUP_ID" ]]; then
    exit 1
fi

if [[ ! -d "$DEST_DIR" ]]; then
    exit 1
fi

LOG_FILE="$DEST_DIR/backup.log"

find "$DEST_DIR" -name "${BACKUP_ID}-*.tar.gz" -type f -mtime +"$RETENTION_DAYS" -print0 | while IFS= read -r -d '' FILE; do
    if rm "$FILE"; then
        DATE_NOW=$(date +"%Y-%m-%d %H:%M:%S")
        echo "$DATE_NOW | [ID: $BACKUP_ID] Rotation: Deleted old backup $(basename "$FILE") (> $RETENTION_DAYS days)" >> "$LOG_FILE"
    fi
done