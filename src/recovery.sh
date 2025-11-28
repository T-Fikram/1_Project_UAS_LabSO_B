#!/bin/bash
# FILE: src/recovery.sh
# Fungsi: Interface untuk restore/extract file backup

# Setup Path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/../project.conf"

echo "=== RECOVERY / RESTORE DATA ==="

# 1. Cek Config
if [[ ! -s "$CONF_FILE" ]]; then
    echo "Error: Belum ada konfigurasi backup."
    exit 1
fi

# 2. Pilih Folder Backup (Project)
echo "Pilih folder project yang ingin dipulihkan:"
i=1
mapfile -t lines < <(grep -v '^#' "$CONF_FILE" | grep -v '^$')

if [[ ${#lines[@]} -eq 0 ]]; then
    echo "Tidak ada konfigurasi aktif."
    exit 1
fi

for line in "${lines[@]}"; do
    IFS='|' read -r src dest ret int <<< "$line"
    echo "[$i] $src (Backup di: $dest)"
    ((i++))
done

read -p "Pilihan: " choice
idx=$((choice-1))

if [[ -z "${lines[$idx]}" ]]; then
    echo "Pilihan tidak valid."
    exit 1
fi

IFS='|' read -r src_dir dest_dir ret int <<< "${lines[$idx]}"

# 3. List File Backup Tersedia
echo -e "\nMencari backup di: $dest_dir"
if [[ ! -d "$dest_dir" ]]; then
    echo "Error: Folder backup tidak ditemukan."
    exit 1
fi

backups=($(ls "$dest_dir"/backup-*.tar.gz 2>/dev/null))

if [[ ${#backups[@]} -eq 0 ]]; then
    echo "Tidak ada file backup ditemukan di folder tersebut."
    exit 1
fi

echo "File backup tersedia:"
j=1
for file in "${backups[@]}"; do
    filename=$(basename "$file")
    size=$(du -h "$file" | cut -f1)
    echo "[$j] $filename ($size)"
    ((j++))
done

read -p "Pilih file nomor: " file_choice
file_idx=$((file_choice-1))
selected_file="${backups[$file_idx]}"

if [[ ! -f "$selected_file" ]]; then
    echo "File tidak valid."
    exit 1
fi

# 4. Tentukan Lokasi Restore
echo -e "\nFile terpilih: $selected_file"
echo "Mau direstore kemana?"
echo "1. Ke lokasi aslinya ($src_dir)"
echo "2. Ke folder lain (Custom)"
read -p "Pilihan: " dest_opt

if [[ "$dest_opt" == "1" ]]; then
    target_dir="$(dirname "$src_dir")" # Restore ke parent agar folder aslinya tertimpa/terisi
elif [[ "$dest_opt" == "2" ]]; then
    read -e -p "Masukkan path tujuan: " custom_path
    custom_path="${custom_path/#~/$HOME}"
    mkdir -p "$custom_path"
    target_dir="$custom_path"
else
    echo "Batal."
    exit 1
fi

# 5. Eksekusi Restore
echo "Sedang mengekstrak..."
# tar -xzvf [file] -C [tujuan]
if tar -xzf "$selected_file" -C "$target_dir"; then
    echo "SUCCESS: Data berhasil dipulihkan ke $target_dir"
else
    echo "FAILED: Gagal mengekstrak file."
fi