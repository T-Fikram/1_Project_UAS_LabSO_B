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


