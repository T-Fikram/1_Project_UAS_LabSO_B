#!/bin/bash
# FILE: src/backup.sh

SOURCE_DIR="$1"
DEST_DIR="$2"
RETENTION="$3"
BACKUP_ID="$4"

if [[ -z "$SOURCE_DIR" ]] || [[ -z "$DEST_DIR" ]] || [[ -z "$BACKUP_ID" ]]; then
    echo "Error: Missing parameters."
    exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source not found: $SOURCE_DIR"
    exit 1
fi

mkdir -p "$DEST_DIR"
LOG_FILE="$DEST_DIR/backup.log"

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
FILENAME="${BACKUP_ID}-${TIMESTAMP}.tar.gz"
FILE_PATH="$DEST_DIR/$FILENAME"
DATE_NOW=$(date +"%Y-%m-%d %H:%M:%S")

echo "$DATE_NOW | [ID: $BACKUP_ID] Backup started: $SOURCE_DIR" >> "$LOG_FILE"

PARENT_DIR=$(dirname "$SOURCE_DIR")
BASE_NAME=$(basename "$SOURCE_DIR")

if tar -czf "$FILE_PATH" -C "$PARENT_DIR" "$BASE_NAME" 2>/dev/null; then
    STATUS="SUCCESS"
    EXIT_CODE=0
    echo "Backup created: $FILENAME"
else
    STATUS="FAILED"
    EXIT_CODE=1
    echo "Backup failed."
fi

DATE_FINISH=$(date +"%Y-%m-%d %H:%M:%S")
if [[ -f "$FILE_PATH" ]]; then
    SIZE=$(du -h "$FILE_PATH" | cut -f1)
else
    SIZE="0"
fi

{
    echo "$DATE_FINISH | [ID: $BACKUP_ID] Backup finished: $(basename "$FILE_PATH")"
    echo "$DATE_FINISH | [ID: $BACKUP_ID] Size: $SIZE | Status: $STATUS"
} >> "$LOG_FILE"

exit $EXIT_CODE