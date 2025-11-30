#!/bin/bash
# FILE: src/edit-conf.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/../project.conf"

if [[ ! -f "$CONF_FILE" ]]; then
    echo "# FORMAT: ID|SOURCE|DESTINATION|RETENTION_DAYS|INTERVAL_HOURS" > "$CONF_FILE"
fi

list_configs() {
    echo -e "\n=== DAFTAR KONFIGURASI BACKUP ==="
    i=1
    # Baca file, abaikan komentar (#) dan baris kosong
    grep -v '^#' "$CONF_FILE" | grep -v '^$' | while IFS='|' read -r src dest ret int; do
        echo "[$i] SUMBER : $src"
        echo "    TUJUAN : $dest"
        echo "    ATURAN : Retensi $ret hari | Interval $int jam"
        echo "-------------------------------------"
        ((i++))
    done
}

add_config() {
    echo -e "\n--- Tambah Jadwal Backup Baru ---"
    
    read -e -p "Folder yang mau dibackup: " src_in
    src_in="${src_in/#~/$HOME}"
    if [[ ! -d "$src_in" ]]; then
        echo "Error: Folder sumber tidak ditemukan!"
        return
    fi
    src_path=$(realpath "$src_in")

    read -e -p "Folder tujuan backup: " dest_in
    dest_in="${dest_in/#~/$HOME}"
    mkdir -p "$dest_in"
    dest_path=$(realpath "$dest_in")

    read -p "Hapus backup setelah berapa hari? (Contoh: 7): " ret_in
    read -p "Jalankan backup setiap berapa jam? (Contoh: 12): " int_in

    if [[ ! "$ret_in" =~ ^[0-9]+$ ]] || [[ ! "$int_in" =~ ^[0-9]+$ ]]; then
        echo "Error: Input hari/jam harus angka."
        return
    fi

    echo "$src_path|$dest_path|$ret_in|$int_in" >> "$CONF_FILE"
    echo "Sukses! Konfigurasi tersimpan."
}

delete_config() {
    list_configs
    echo "Hapus konfigurasi nomor berapa?"
    read -p "Pilihan (0 untuk batal): " choice

    if [[ "$choice" == "0" || -z "$choice" ]]; then return; fi

    grep -v '^#' "$CONF_FILE" | grep -v '^$' > /tmp/clean_conf.tmp
    total_lines=$(wc -l < /tmp/clean_conf.tmp)
    
    if [[ "$choice" -gt "$total_lines" ]]; then
        echo "Nomor tidak valid."
        return
    fi

    line_content=$(sed "${choice}q;d" /tmp/clean_conf.tmp)
    
    echo "Menghapus: $line_content"
    grep -v -F "$line_content" "$CONF_FILE" > "$CONF_FILE.tmp" && mv "$CONF_FILE.tmp" "$CONF_FILE"
    
    echo "Data berhasil dihapus."
    rm /tmp/clean_conf.tmp
}

while true; do
    echo -e "\n=== MENU KONFIGURASI ==="
    echo "1. Lihat Daftar Backup"
    echo "2. Tambah Backup Baru"
    echo "3. Hapus Backup"
    echo "4. Kembali ke Menu Utama"
    read -p "Pilih: " menu

    case $menu in
        1) list_configs ;;
        2) add_config ;;
        3) delete_config ;;
        4) break ;;
        *) echo "Pilihan salah." ;;
    esac
done