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
    # TODO: Anggota 2 mengerjakan bagian ini
    # - Generate timestamp
    # - Buat nama file backup-YYYYMMDD-HHMMSS.tar.gz
    # - Jalankan tar untuk membuat backup
    # - Simpan path file backup ke variabel global FILE_PATH
    :
}

write_log() {
    # TODO: Anggota 2 mengerjakan bagian ini
    # - Mencatat start time, finish time, ukuran file, status SUCCESS/FAILED
    # - Log disimpan ke "$dest/backup.log"
    :
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
