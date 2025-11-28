# Bagian input dari user
get_user_input() {
    while true; do
        read -e -p "Folder yang mau dibackup: " source
        source="${source/#~/$HOME}"

        # buang spasi berlebih
        source=$(echo "$source" | sed 's/^ *//;s/ *$//')

        if [[ -z "$source" ]]; then
            echo "Gak boleh kosong."
            continue
        fi

        # kalau ada realpath ya bagus, kalau nggak ya gpp
        if command -v realpath >/dev/null; then
            source=$(realpath "$source")
        fi
        break
    done

    while true; do
        read -e -p "Simpan backup di mana (folder tujuan): " dest
        dest="${dest/#~/$HOME}"
        dest=$(echo "$dest" | sed 's/^ *//;s/ *$//')

        if [[ -z "$dest" ]]; then
            echo "Ini juga gak boleh kosong."
            continue
        fi

        if command -v realpath >/dev/null; then
            dest=$(realpath "$dest")
        fi
        break
    done

    # retention days
    while true; do
        read -p "Backup disimpan berapa hari: " retention

        if [[ "$retention" =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Masukkan angka aja ya."
        fi
    done

    logFile="$dest/backup.log"
}

# Cek folder sumber dan tujuan
validate_folders() {
    if [[ ! -d "$source" ]]; then
        echo "Folder sumber gak ditemukan: $source"
        exit 1
    fi

    if [[ ! -d "$dest" ]]; then
        echo "Folder tujuan belum ada. Bikin dululah."
        mkdir -p "$dest" || { echo "Gagal bikin folder."; exit 1; }
    fi

    if [[ ! -w "$dest" ]]; then
        echo "Folder tujuan gak bisa ditulis."
        exit 1
    fi
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
