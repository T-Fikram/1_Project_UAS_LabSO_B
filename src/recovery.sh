#!/bin/bash
# FILE: src/recovery.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/../project.conf"

INPUT_ID="$1"
INPUT_FILE="$2"
INPUT_DEST_OPT="$3"
INPUT_CUSTOM_PATH="$4"
AUTO_YES=false

for arg in "$@"; do
    if [[ "$arg" == "-y" ]]; then AUTO_YES=true; fi
done

if [[ -z "$INPUT_ID" ]]; then
    echo "Error: Missing ID."
    exit 1
fi

LINE=$(grep "^$INPUT_ID|" "$CONF_FILE")
if [[ -z "$LINE" ]]; then
    echo "Error: ID not found."
    exit 1
fi

IFS='|' read -r id src_dir dest_dir ret int <<< "$LINE"

if [[ ! -d "$dest_dir" ]]; then
    echo "Error: Backup dir not found."
    exit 1
fi

SELECTED_FILE=""
if [[ -n "$INPUT_FILE" ]]; then
    if [[ "$INPUT_FILE" == "latest" ]]; then
        SELECTED_FILE=$(ls -t "$dest_dir"/"$id"-*.tar.gz 2>/dev/null | head -n 1)
    else
        SELECTED_FILE="$dest_dir/$INPUT_FILE"
    fi
    
    if [[ ! -f "$SELECTED_FILE" ]]; then
        echo "Error: Backup file not found."
        exit 1
    fi
else
    echo "Available backups for $id:"
    backups=($(ls "$dest_dir"/"$id"-*.tar.gz 2>/dev/null))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo "No backups found."
        exit 1
    fi

    j=1
    for file in "${backups[@]}"; do
        echo "[$j] $(basename "$file") ($(du -h "$file" | cut -f1))"
        ((j++))
    done

    read -p "Select file number: " file_choice
    file_idx=$((file_choice-1))
    SELECTED_FILE="${backups[$file_idx]}"
fi

if [[ ! -f "$SELECTED_FILE" ]]; then
    echo "Invalid selection."
    exit 1
fi

TARGET_DIR=""
MODE_OVERWRITE=false

if [[ -n "$INPUT_DEST_OPT" ]]; then
    if [[ "$INPUT_DEST_OPT" == "1" ]]; then
        TARGET_DIR="$(dirname "$src_dir")"
        MODE_OVERWRITE=true
    elif [[ "$INPUT_DEST_OPT" == "2" ]]; then
        if [[ -z "$INPUT_CUSTOM_PATH" ]]; then
            echo "Error: Missing custom path."
            exit 1
        fi
        TARGET_DIR="$INPUT_CUSTOM_PATH"
        mkdir -p "$TARGET_DIR"
    fi
else
    echo "Target Location:"
    echo "1. Original Location ($src_dir) [OVERWRITE]"
    echo "2. Custom Folder"
    read -p "Choice: " dest_opt

    if [[ "$dest_opt" == "1" ]]; then
        TARGET_DIR="$(dirname "$src_dir")"
        MODE_OVERWRITE=true
    elif [[ "$dest_opt" == "2" ]]; then
        read -e -p "Enter path: " custom_path
        custom_path="${custom_path/#~/$HOME}"
        mkdir -p "$custom_path"
        TARGET_DIR="$custom_path"
    else
        echo "Aborted."
        exit 1
    fi
fi

if [[ "$MODE_OVERWRITE" == "true" ]]; then
    if [[ "$AUTO_YES" == "false" ]]; then
        echo "WARNING: Overwriting data in: $src_dir"
        read -p "Confirm? (y/n): " confirm
        if [[ "$confirm" != "y" ]]; then
            echo "Aborted."
            exit 1
        fi
    fi
fi

echo "Extracting $(basename "$SELECTED_FILE")..."
if tar -xzf "$SELECTED_FILE" -C "$TARGET_DIR"; then
    echo "Restore complete: $TARGET_DIR"
else
    echo "Extract failed."
fi