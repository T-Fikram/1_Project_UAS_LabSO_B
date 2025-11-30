#!/bin/bash
# FILE: src/main.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/utils.sh"

if [[ ! -f "$CONF_FILE" ]]; then
    echo "# FORMAT: ID|SOURCE|DEST|RETENTION|CRON_SCHEDULE" > "$CONF_FILE"
fi

usage() {
    local exit_code=${1:-0}
    echo "Usage: $0 [OPTION] [COMMAND]"
    echo "Commands:"
    echo "  list                  Lihat daftar"
    echo "  create [src] [dest] [ret] [cron] [-y]"
    echo "                        Buat backup baru (Argumen opsional untuk otomatisasi)"
    echo "  edit <id> [src] [dest] [ret] [cron]"
    echo "                        Edit konfigurasi (Argumen opsional)"
    echo "  delete <id> [--purge] Hapus konfigurasi"
    echo "  backup <id>           Jalankan backup manual"
    echo "  recovery <id>         Recovery data"
    echo ""
    echo "Service Control:"
    echo "  --install-service, --uninstall-service, --start-service, etc."
    exit "$exit_code"
}

# --- GLOBAL HELP & INSTALLER HANDLER (Sama seperti sebelumnya) ---
if [[ "$1" == "-h" || "$1" == "--help" ]]; then usage 0; fi
if [[ "$1" == "--install-service" ]]; then shift; bash "$ROOT_DIR/install-service.sh" "$@"; exit 0; fi
if [[ "$1" == "--uninstall-service" ]]; then shift; bash "$ROOT_DIR/install-service.sh" uninstall "$@"; exit 0; fi
if [[ "$1" == "--install-completion" ]]; then
    COMP_FILE="$ROOT_DIR/completion.sh"
    BASH_RC="$HOME/.bashrc"

    if [[ ! -f "$COMP_FILE" ]]; then
        echo "Error: File completion.sh tidak ditemukan di $ROOT_DIR"
        exit 1
    fi

    # Cek apakah sudah terinstall
    if grep -qF "source $COMP_FILE" "$BASH_RC"; then
        echo "Autocomplete sudah terinstall sebelumnya."
    else
        echo "" >> "$BASH_RC"
        echo "# UAS Backup Completion" >> "$BASH_RC"
        echo "source $COMP_FILE" >> "$BASH_RC"
        echo "✅ Autocomplete berhasil ditambahkan ke $BASH_RC"
        echo "Agar efeknya terasa sekarang, jalankan perintah:"
        echo -e "\e[1;32m   source ~/.bashrc\e[0m"
    fi
    exit 0
fi

# --- VALIDASI SERVICE ---
check_service_health
HEALTH_STATUS=$?
if [[ "$HEALTH_STATUS" -eq 1 ]]; then
    echo "Service belum terinstall. Gunakan --install-service"; usage 1
elif [[ "$HEALTH_STATUS" -eq 2 ]]; then
    if [[ "$1" != "--start-service" && "$1" != "--stop-service" && "$1" != "--status-service" ]]; then
        echo "[INFO] Service Stopped. Manual commands allowed."
    fi
fi

# --- SERVICE CONTROLLERS (Start/Stop/Status) ---
if [[ "$1" == "--start-service" ]]; then systemctl --user start "${SERVICE_NAME}.timer"; echo "Started."; exit 0; fi
if [[ "$1" == "--stop-service" ]]; then systemctl --user stop "${SERVICE_NAME}.timer"; echo "Stopped."; exit 0; fi
if [[ "$1" == "--status-service" ]]; then systemctl --user status "${SERVICE_NAME}.timer"; exit 0; fi

# --- CORE LOGIC ---
COMMAND="$1"
ID_ARG="$2"

# Fungsi helper untuk error
error_arg() {
    echo "Error: Argumen '$1' tidak dikenal atau jumlah argumen salah untuk perintah '$COMMAND'."
    usage 1
}

case "$COMMAND" in
    list)
        # Validasi: Command list TIDAK BOLEH ada argumen tambahan
        if [[ -n "$2" ]]; then error_arg "$2"; fi

        echo "ID           | SOURCE PATH"
        echo "------------------------------------------------"
        grep -v '^#' "$CONF_FILE" | grep -v '^$' | while IFS='|' read -r id src dest ret cron; do
            printf "%-12s | %s\n" "$id" "$src"
        done
        ;;

    show)
        # Validasi: Show HARUS punya ID, dan TIDAK BOLEH ada argumen ke-3
        if [[ -z "$ID_ARG" ]]; then echo "Error: ID wajib diisi."; usage 1; fi
        if [[ -n "$3" ]]; then error_arg "$3"; fi

        line=$(grep "^$ID_ARG|" "$CONF_FILE")
        if [[ -z "$line" ]]; then echo "Error: ID tidak ditemukan."; exit 1; fi
        IFS='|' read -r id src dest ret cron <<< "$line"
        echo "ID        : $id"
        echo "Source    : $src"
        echo "Dest      : $dest"
        echo "Retention : $ret hari"
        echo "Schedule  : $cron"
        ;;

    create)
        # Argumen CLI: create <src> <dest> <ret> <cron> [-y]
        if [[ -n "$6" && "$6" != "-y" ]]; then error_arg "$6"; fi
        # Argumen ke-7 tidak boleh ada
        if [[ -n "$7" ]]; then error_arg "$7"; fi
        
        SRC_IN="$2"
        DEST_IN="$3"
        RET_IN="$4"
        CRON_IN="$5"
        AUTO_YES=false
        if [[ "$6" == "-y" ]]; then AUTO_YES=true; fi

        # Jika argumen CLI lengkap, pakai itu. Jika tidak, Interactive.
        if [[ -n "$SRC_IN" && -n "$DEST_IN" && -n "$RET_IN" && -n "$CRON_IN" ]]; then
            src=$(realpath "${SRC_IN/#~/$HOME}")
            dest=$(realpath "${DEST_IN/#~/$HOME}")
            ret="$RET_IN"
            cron="$CRON_IN"
        else
            # Interactive Mode
            new_id=$(generate_id)
            echo "Membuat konfigurasi baru ID: $new_id"
            read -e -p "Folder Source: " src_raw
            src=$(realpath "${src_raw/#~/$HOME}")
            read -e -p "Folder Destination: " dest_raw
            dest=$(realpath "${dest_raw/#~/$HOME}")
            mkdir -p "$dest"
            read -p "Retensi (hari): " ret
            echo "Format Cron: m h dom mon dow (Contoh: '*/30 * * * *')"
            read -p "Jadwal Cron: " cron
        fi

        # 1. Validasi Destination In Use
        if grep -q "|$dest|" "$CONF_FILE"; then
            if [[ "$AUTO_YES" == "false" ]]; then
                echo -e "\e[1;33m[PERINGATAN] Folder tujuan '$dest' sudah digunakan oleh backup lain!\e[0m"
                read -p "Tetap lanjutkan? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then echo "Batal."; exit 1; fi
            fi
        fi

        # 2. Validasi Cron Range
        validate_cron "$cron"
        cron_status=$?
        if [[ "$cron_status" -ne 0 ]]; then
            echo "Error: Format Cron tidak valid (Cek jumlah kolom atau range angka)."
            exit 1
        fi

        new_id=$(generate_id)
        echo "$new_id|$src|$dest|$ret|$cron" >> "$CONF_FILE"
        echo "Sukses membuat konfigurasi $new_id"
        ;;

    edit)
        if [[ -z "$ID_ARG" ]]; then echo "Error: Masukkan ID."; usage 1; fi
        line=$(grep "^$ID_ARG|" "$CONF_FILE")
        if [[ -z "$line" ]]; then echo "Error: ID tidak ditemukan."; exit 1; fi
        # Argumen ke-7 tidak boleh ada
        if [[ -n "$7" ]]; then error_arg "$7"; fi
        
        # Argumen CLI: edit <id> <src> <dest> <ret> <cron>
        # Jika argumen CLI ada, overwrite semua. Jika kosong, interactive.
        IFS='|' read -r oid osrc odest oret ocron <<< "$line"
        
        if [[ -n "$3" && -n "$4" && -n "$5" && -n "$6" ]]; then
            nsrc=$(realpath "${3/#~/$HOME}")
            ndest=$(realpath "${4/#~/$HOME}")
            nret="$5"
            ncron="$6"
        else
            echo "Mengedit $ID_ARG (Enter untuk nilai lama)"
            read -e -p "Source [$osrc]: " nsrc
            nsrc=${nsrc:-$osrc}
            read -e -p "Dest [$odest]: " ndest
            ndest=${ndest:-$odest}
            read -p "Retention [$oret]: " nret
            nret=${nret:-$oret}
            read -p "Cron [$ocron]: " ncron
            ncron=${ncron:-$ocron}
        fi

        # Validasi Cron Baru
        validate_cron "$ncron"
        if [[ $? -ne 0 ]]; then echo "Error: Format cron salah."; exit 1; fi

        # Update File
        grep -v "^$ID_ARG|" "$CONF_FILE" > "$CONF_FILE.tmp" && mv "$CONF_FILE.tmp" "$CONF_FILE"
        echo "$ID_ARG|$nsrc|$ndest|$nret|$ncron" >> "$CONF_FILE"
        echo "Update sukses."
        ;;

    delete)
        if [[ -z "$ID_ARG" ]]; then echo "Error: Masukkan ID."; usage 1; fi
        line=$(grep "^$ID_ARG|" "$CONF_FILE")
        if [[ -z "$line" ]]; then echo "Error: ID tidak ditemukan."; exit 1; fi

        # Validasi Opsi delete (Hanya boleh --purge atau -y)
        for arg in "$3" "$4"; do
            if [[ -n "$arg" && "$arg" != "--purge" && "$arg" != "-y" ]]; then
                error_arg "$arg"
            fi
        done
        if [[ -n "$5" ]]; then error_arg "$5"; fi

        IFS='|' read -r id src dest ret cron <<< "$line"
        IS_PURGE=false
        AUTO_YES=false
        for arg in "$3" "$4"; do
            if [[ "$arg" == "--purge" ]]; then IS_PURGE=true; fi
            if [[ "$arg" == "-y" ]]; then AUTO_YES=true; fi
        done

        if [[ "$IS_PURGE" == "true" ]]; then
            if [[ "$AUTO_YES" == "false" ]]; then
                echo -e "\e[1;31m[BAHAYA] Akan menghapus file backup milik ID: $id\e[0m"
                read -p "Yakin? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then exit 1; fi
            fi
            # --- LOGIKA BARU: Hapus spesifik ID ---
            echo "Menghapus file backup $id-*.tar.gz di $dest..."
            find "$dest" -name "${id}-*.tar.gz" -delete
        fi

        grep -v "^$ID_ARG|" "$CONF_FILE" > "$CONF_FILE.tmp" && mv "$CONF_FILE.tmp" "$CONF_FILE"
        echo "Konfigurasi $ID_ARG dihapus."
        ;;

    backup)
        if [[ -z "$ID_ARG" ]]; then echo "Error: Masukkan ID."; usage 1; fi
        if [[ -n "$3" ]]; then error_arg "$3"; fi
        line=$(grep "^$ID_ARG|" "$CONF_FILE")
        IFS='|' read -r id src dest ret cron <<< "$line"
        # Kirim ID ke script backup
        bash "$SCRIPT_DIR/backup.sh" "$src" "$dest" "$ret" "$id"
        bash "$SCRIPT_DIR/rotation-backup.sh" "$dest" "$ret" "$id"
        ;;
    
    recovery)
        # Recovery ditangani script terpisah, tapi kita bisa validasi argumen awal di sini
        if [[ -z "$ID_ARG" ]]; then echo "Error: Masukkan ID."; usage 1; fi
        
        # Shift dan pass ke script recovery
        shift 
        bash "$SCRIPT_DIR/recovery.sh" "$@"
        ;;

    *) # Menangkap command ngawur (misal: ./main.sh makan)
        echo "Error: Perintah '$COMMAND' tidak dikenali."
        usage 1 
        ;;
esac