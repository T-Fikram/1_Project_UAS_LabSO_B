#!/bin/bash

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

    dest="backup/"
    
    # retention days
    while true; do
        read -p "Backup disimpan berapa hari: " retention

        if [[ "$retention" =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Masukkan angka aja ya"
        fi
    done

    logFile="./backup.log"
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

perform_backup() {
    timestamp=$(date +"%Y%m%d-%H%M%S")
    filename="backup-$timestamp.tar.gz"
    FILE_PATH="$dest/$filename"

    echo "Membuat backup..."

    if [[ -d "$source" ]]; then
        parent=$(dirname "$source")
        base=$(basename "$source")
        tar -czf "$FILE_PATH" -C "$parent" "$base"
    else
        tar -czf "$FILE_PATH" -C "$(dirname "$source")" "$(basename "$source")"
    fi

    BACKUP_STATUS=$?
}

write_log() {
    readable_finish=$(date +"%Y-%m-%d %H:%M:%S")

    if [[ $BACKUP_STATUS -eq 0 ]]; then
        status="SUCCESS"
    else
        status="FAILED"
    fi

    if [[ -f "$FILE_PATH" ]]; then
        size=$(du -h "$FILE_PATH" | cut -f1)
    else
        size="0"
    fi

    {
        echo "$(date +"%Y-%m-%d %H:%M:%S") | Backup finished: $(basename "$FILE_PATH")"
        echo "$(date +"%Y-%m-%d %H:%M:%S") | Size: $size | Status: $status"
    } >> "$logFile"    # pastikan nama variabel ini sama dengan yang di get_user_input

    if [[ $status == "SUCCESS" ]]; then
        echo "Backup selesai: $(basename "$FILE_PATH")"
        echo "Ukuran backup: $size"
        echo "Backup tersimpan di: $dest"
    else
        echo "Backup gagal! Cek log di: $logFile"
    fi
}

diff_days() {
    local date1="$1"
    local date2="$2"

    sec1=$(date -d "$date1" +%s 2>/dev/null)
    sec2=$(date -d "$date2" +%s 2>/dev/null)
    
    if [ -z "$sec1" ] || [ -z "$sec2" ]; then
        echo "Error: Format tanggal tidak valid"
        return 1
    fi
    
    diff_sec=$((sec2 - sec1))
    diff_days=$((diff_sec / 86400))

    return $diff_days
}

rotate_backups() {
    for file in $dest/*; do
	local backup_date=$(stat -c %y $file)
	local date_now=$(date +%s)
	
	if [[$(diff_days $date_now $backup_date) gt $retention]]; then
	    rm $file
	fi
    done
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



