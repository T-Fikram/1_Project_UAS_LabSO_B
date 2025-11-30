#!/bin/bash
# FILE: src/recovery.sh
# Usage CLI: ./recovery.sh <ID> [FILE_NAME|"latest"] [DEST_OPT] [CUSTOM_PATH] [-y]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/../project.conf"

# --- Parsing Argumen CLI ---
INPUT_ID="$1"
INPUT_FILE="$2"       # Bisa nama file spesifik atau "latest"
INPUT_DEST_OPT="$3"   # 1 (Original) atau 2 (Custom)
INPUT_CUSTOM_PATH="$4"
AUTO_YES=false

# Cek flag -y di argumen mana saja
for arg in "$@"; do
    if [[ "$arg" == "-y" ]]; then AUTO_YES=true; fi
done

echo "=== RECOVERY / RESTORE DATA ==="

# 1. Validasi ID
if [[ -z "$INPUT_ID" ]]; then
    echo "Error: ID tidak diberikan."
    exit 1
fi

LINE=$(grep "^$INPUT_ID|" "$CONF_FILE")
if [[ -z "$LINE" ]]; then
    echo "Error: ID '$INPUT_ID' tidak ditemukan."
    exit 1
fi

IFS='|' read -r id src_dir dest_dir ret int <<< "$LINE"

if [[ ! -d "$dest_dir" ]]; then
    echo "Error: Folder backup fisik tidak ditemukan di $dest_dir"
    exit 1
fi

# 2. Pilih File Backup (CLI vs Interactive)
SELECTED_FILE=""
if [[ -n "$INPUT_FILE" ]]; then
    if [[ "$INPUT_FILE" == "latest" ]]; then
        # Ambil file terbaru milik ID ini
        SELECTED_FILE=$(ls -t "$dest_dir"/"$id"-*.tar.gz 2>/dev/null | head -n 1)
    else
        SELECTED_FILE="$dest_dir/$INPUT_FILE"
    fi
    
    if [[ ! -f "$SELECTED_FILE" ]]; then
        echo "Error: File backup '$INPUT_FILE' tidak ditemukan."
        exit 1
    fi
else
    # --- Mode Interaktif ---
    echo "Mencari backup untuk $id di: $dest_dir"
    backups=($(ls "$dest_dir"/"$id"-*.tar.gz 2>/dev/null))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo "Tidak ada file backup tersedia."
        exit 1
    fi

    echo "File backup tersedia:"
    j=1
    for file in "${backups[@]}"; do
        echo "[$j] $(basename "$file") ($(du -h "$file" | cut -f1))"
        ((j++))
    done

    read -p "Pilih file nomor: " file_choice
    file_idx=$((file_choice-1))
    SELECTED_FILE="${backups[$file_idx]}"
fi

if [[ ! -f "$SELECTED_FILE" ]]; then
    echo "File tidak valid."
    exit 1
fi

# 3. Tentukan Lokasi Restore & Cek Overwrite
TARGET_DIR=""
MODE_OVERWRITE=false

# Tentukan Target
if [[ -n "$INPUT_DEST_OPT" ]]; then
    # Mode CLI
    if [[ "$INPUT_DEST_OPT" == "1" ]]; then
        TARGET_DIR="$(dirname "$src_dir")"
        MODE_OVERWRITE=true
    elif [[ "$INPUT_DEST_OPT" == "2" ]]; then
        if [[ -z "$INPUT_CUSTOM_PATH" ]]; then
            echo "Error: Custom path harus diisi untuk opsi 2."
            exit 1
        fi
        TARGET_DIR="$INPUT_CUSTOM_PATH"
        mkdir -p "$TARGET_DIR"
    fi
else
    # Mode Interaktif
    echo -e "\nFile terpilih: $SELECTED_FILE"
    echo "Mau direstore kemana?"
    echo "1. Ke lokasi aslinya ($src_dir) [OVERWRITE WARNING]"
    echo "2. Ke folder lain (Custom)"
    read -p "Pilihan: " dest_opt

    if [[ "$dest_opt" == "1" ]]; then
        TARGET_DIR="$(dirname "$src_dir")"
        MODE_OVERWRITE=true
    elif [[ "$dest_opt" == "2" ]]; then
        read -e -p "Masukkan path tujuan: " custom_path
        custom_path="${custom_path/#~/$HOME}"
        mkdir -p "$custom_path"
        TARGET_DIR="$custom_path"
    else
        echo "Batal."
        exit 1
    fi
fi

# 4. Logic Overwrite Protection
if [[ "$MODE_OVERWRITE" == "true" ]]; then
    if [[ "$AUTO_YES" == "false" ]]; then
        echo -e "\n\e[1;33m[PERINGATAN] Anda akan menimpa data di lokasi asli: $src_dir\e[0m"
        read -p "Apakah Anda yakin? (y/n): " confirm
        if [[ "$confirm" != "y" ]]; then
            echo "Restore dibatalkan."
            exit 1
        fi
    else
        echo "[INFO] Overwrite mode aktif (Bypass konfirmasi)."
    fi
fi

# 5. Eksekusi
echo "Sedang mengekstrak $(basename "$SELECTED_FILE")..."
if tar -xzf "$SELECTED_FILE" -C "$TARGET_DIR"; then
    echo "SUCCESS: Data dipulihkan ke $TARGET_DIR"
else
    echo "FAILED: Gagal mengekstrak."
fi