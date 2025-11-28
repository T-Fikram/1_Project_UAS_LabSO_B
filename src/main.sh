#!/bin/bash

########################################
# PROJECT UAS SISTEM OPERASI
# Sistem Backup Otomatis dengan Log & Rotasi
# Kerangka Script (untuk 3 orang)
########################################


########################################
# === BAGIAN ANGGOTA 1 ===
# INPUT USER + VALIDASI FOLDER
########################################

get_user_input() {
    # TODO: Anggota 1 mengerjakan bagian ini
    # Minta input:
    # - source folder
    # - destination folder
    # - retention days

    # Contoh kerangka:
    # read -p "Masukkan folder sumber: " source
    # read -p "Masukkan folder tujuan: " dest
    # read -p "Masukkan lama penyimpanan backup (hari): " retention
    :
}

validate_folders() {
    # TODO: Anggota 1 mengerjakan bagian ini
    # - Cek folder sumber ada atau tidak
    # - Cek folder tujuan, kalau tidak ada buat otomatis
    :
}


########################################
# === BAGIAN ANGGOTA 2 ===
# PROSES BACKUP + LOGGING
########################################

perform_backup() {
    # Generate timestamp untuk nama file
    timestamp=$(date +"%Y%m%d-%H%M%S")
    filename="backup-$timestamp.tar.gz"
    FILE_PATH="$dest/$filename"

    # Mulai proses backup
    echo "Membuat backup..."
    
    if [[ -d "$src" ]]; then
        # Jika sumber adalah folder
        parent=$(dirname "$src")
        base=$(basename "$src")
        tar -czf "$FILE_PATH" -C "$parent" "$base"
    else
        # Jika sumber adalah file
        tar -czf "$FILE_PATH" -C "$(dirname "$src")" "$(basename "$src")"
    fi

    # Simpan exit code (untuk log)
    BACKUP_STATUS=$?
}


write_log() {
    finish_time=$(date +%s)
    readable_finish=$(date +"%Y-%m-%d %H:%M:%S")

    if [[ $BACKUP_STATUS -eq 0 ]]; then
        status="SUCCESS"
    else
        status="FAILED"
    fi

    # Hitung ukuran file (hanya jika sukses)
    if [[ -f "$FILE_PATH" ]]; then
        size=$(du -h "$FILE_PATH" | cut -f1)
    else
        size="0"
    fi

    # Tulis ke log file
    {
        echo "$(date +"%Y-%m-%d %H:%M:%S") | Backup finished: $(basename "$FILE_PATH")"
        echo "$(date +"%Y-%m-%d %H:%M:%S") | Size: $size | Status: $status"
    } >> "$log_file"

    # Pesan ke terminal
    if [[ $status == "SUCCESS" ]]; then
        echo "Backup selesai: $(basename "$FILE_PATH")"
        echo "Ukuran backup: $size"
        echo "Backup tersimpan di: $dest"
    else
        echo "Backup gagal! Cek log di: $log_file"
    fi
}



########################################
# === BAGIAN ANGGOTA 3 ===
# ROTASI BACKUP + OUTPUT + README
########################################

rotate_backups() {
    # TODO: Anggota 3 mengerjakan bagian ini
    # - Menghapus backup yang lebih tua dari $retention hari
    :
}

final_message() {
    # TODO: Anggota 3 mengerjakan bagian ini
    # - Tampilkan pesan ke terminal apakah backup sukses
    # - Informasikan lokasi file backup
    :
}


########################################
# === FLOW UTAMA PROGRAM (Gabungan) ===
########################################

main() {
    get_user_input
    validate_folders
    perform_backup
    write_log
    rotate_backups
    final_message
}

main


