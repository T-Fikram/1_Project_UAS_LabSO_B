#!/bin/bash
# FILE: src/main.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/utils.sh"

# Pastikan config ada
if [[ ! -f "$CONF_FILE" ]]; then
    echo "# FORMAT: ID|SOURCE|DEST|RETENTION|CRON_SCHEDULE" > "$CONF_FILE"
fi

usage() {
    echo "Usage: $0 [OPTION] [COMMAND]"
    echo "Commands:"
    echo "  list                  Lihat daftar backup aktif"
    echo "  show <id>             Lihat detail konfigurasi backup"
    echo "  create                Buat konfigurasi backup baru"
    echo "  edit <id>             Edit konfigurasi backup"
    echo "  delete <id> [--purge] Hapus konfigurasi (opsional: hapus file backup)"
    echo "  backup <id>           Jalankan backup manual sekarang"
    echo "  recovery <id>         Recovery data dari backup"
    echo ""
    echo "Service Control:"
    echo "  --install-service     Install systemd service"
    echo "  --uninstall-service   Hapus service dan bersihkan sistem"
    echo "  --install-completion  Pasang fitur Autocomplete (TAB) ke Terminal"
    echo "  --start-service       Jalankan service"
    echo "  --stop-service        Hentikan service"
    echo "  --status-service      Cek status service"
    exit 1
}

# --- 1. PENGECUALIAN UNTUK INSTALLER ---
if [[ "$1" == "--install-service" ]]; then
    shift
    bash "$ROOT_DIR/install-service.sh" "$@"
    exit 0
fi

if [[ "$1" == "--uninstall-service" ]]; then
    shift
    bash "$ROOT_DIR/install-service.sh" uninstall "$@"
    exit 0
fi

if [[ "$1" == "--install-completion" ]]; then
    COMP_FILE="$ROOT_DIR/completion.sh"
    BASH_RC="$HOME/.bashrc"

    if [[ ! -f "$COMP_FILE" ]]; then
        echo "Error: File completion.sh tidak ditemukan di $ROOT_DIR"
        exit 1
    fi

    # Cek apakah sudah pernah diinstall (Grep path file di .bashrc)
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

# --- 2. VALIDASI SERVICE (BLOCKING LOGIC) ---
check_service_health
HEALTH_STATUS=$?

if [[ "$HEALTH_STATUS" -eq 1 ]]; then
    # KASUS: BELUM TERINSTALL -> BLOKIR TOTAL
    echo -e "\n\e[1;31m[AKSES DITOLAK] Service Systemd Belum Terinstall!\e[0m"
    echo "Anda wajib menginstall service terlebih dahulu agar sistem dapat berjalan."
    echo "Silakan jalankan perintah berikut:"
    echo -e "\e[1;32m   $0 --install-service\e[0m"
    echo ""
    exit 1
elif [[ "$HEALTH_STATUS" -eq 2 ]]; then
    # KASUS: STOPPED -> WARNING SAJA (TIDAK DIBLOKIR)
    echo -e "\e[1;33m[PERINGATAN] Service otomatisasi sedang BERHENTI (Stopped).\e[0m"
    echo "Backup otomatis tidak akan berjalan, namun Anda tetap bisa menggunakan fitur manual."
    echo "Gunakan '$0 --start-service' untuk mengaktifkan kembali."
    echo "---------------------------------------------------------------"
fi

# --- 3. SERVICE CONTROLLER LAINNYA ---
# Perintah ini ditaruh di sini agar ikut terblokir jika belum install
if [[ "$1" == "--start-service" ]]; then
    systemctl --user start "uaspraktikum-backup.timer"
    echo "Service berhasil dijalankan."
    exit 0
elif [[ "$1" == "--stop-service" ]]; then
    systemctl --user stop "uaspraktikum-backup.timer"
    echo "Service berhasil dihentikan."
    exit 0
elif [[ "$1" == "--status-service" ]]; then
    systemctl --user status "uaspraktikum-backup.timer"
    exit 0
fi

# --- 4. CORE LOGIC (BACKUP/CREATE/DLL) ---
COMMAND="$1"
ID_ARG="$2"

case "$COMMAND" in
    list)
        echo "ID           | SOURCE PATH"
        echo "------------------------------------------------"
        grep -v '^#' "$CONF_FILE" | grep -v '^$' | while IFS='|' read -r id src dest ret cron; do
            printf "%-12s | %s\n" "$id" "$src"
        done
        ;;

    show)
        if [[ -z "$ID_ARG" ]]; then echo "Error: Masukkan ID."; exit 1; fi
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
        new_id=$(generate_id)
        echo "Membuat konfigurasi baru dengan ID: $new_id"
        read -e -p "Folder Source: " src
        # Gunakan path absolut
        src=$(realpath "${src/#~/$HOME}")
        
        read -e -p "Folder Destination: " dest
        dest=$(realpath "${dest/#~/$HOME}")
        mkdir -p "$dest"

        read -p "Retensi (hari): " ret
        echo "Format Cron: m h dom mon dow (Contoh: '*/30 * * * *' = tiap 30 menit)"
        read -p "Jadwal Cron: " cron
        
        echo "$new_id|$src|$dest|$ret|$cron" >> "$CONF_FILE"
        echo "Sukses membuat konfigurasi $new_id"
        ;;

    edit)
        if [[ -z "$ID_ARG" ]]; then echo "Error: Masukkan ID."; exit 1; fi
        line=$(grep "^$ID_ARG|" "$CONF_FILE")
        if [[ -z "$line" ]]; then echo "Error: ID tidak ditemukan."; exit 1; fi
        
        grep -v "^$ID_ARG|" "$CONF_FILE" > "$CONF_FILE.tmp" && mv "$CONF_FILE.tmp" "$CONF_FILE"
        
        echo "Mengedit $ID_ARG (Input kosong untuk menggunakan nilai lama)"
        IFS='|' read -r oid osrc odest oret ocron <<< "$line"

        read -e -p "Source [$osrc]: " nsrc
        nsrc=${nsrc:-$osrc}
        read -e -p "Dest [$odest]: " ndest
        ndest=${ndest:-$odest}
        read -p "Retention [$oret]: " nret
        nret=${nret:-$oret}
        read -p "Cron [$ocron]: " ncron
        ncron=${ncron:-$ocron}

        echo "$ID_ARG|$nsrc|$ndest|$nret|$ncron" >> "$CONF_FILE"
        echo "Update sukses."
        ;;

    delete)
        if [[ -z "$ID_ARG" ]]; then echo "Error: Masukkan ID."; exit 1; fi
        line=$(grep "^$ID_ARG|" "$CONF_FILE")
        if [[ -z "$line" ]]; then echo "Error: ID tidak ditemukan."; exit 1; fi

        IFS='|' read -r id src dest ret cron <<< "$line"

        IS_PURGE=false
        AUTO_YES=false

        for arg in "$3" "$4"; do
            if [[ "$arg" == "--purge" ]]; then IS_PURGE=true; fi
            if [[ "$arg" == "-y" ]]; then AUTO_YES=true; fi
        done

        if [[ "$IS_PURGE" == "true" ]]; then
            if [[ "$AUTO_YES" == "false" ]]; then
                echo -e "\n\e[1;31m[BAHAYA!] ANDA AKAN MENGHAPUS PERMANEN:\e[0m"
                echo "1. Konfigurasi Backup ID: $id"
                echo "2. Folder Backup Beserta Isinya: $dest"
                echo "------------------------------------------------"
                read -p "Apakah anda yakin ingin melanjutkan? (y/n): " confirm
                if [[ "$confirm" != "y" || "$confirm" != "Y" ]]; then
                    echo "Operasi dibatalkan."
                    exit 1
                fi
            fi
            echo "Menghapus folder backup: $dest"
            rm -rf "$dest"
        fi

        grep -v "^$ID_ARG|" "$CONF_FILE" > "$CONF_FILE.tmp" && mv "$CONF_FILE.tmp" "$CONF_FILE"
        echo "✅ Konfigurasi $ID_ARG berhasil dihapus."
        ;;

    backup)
        if [[ -z "$ID_ARG" ]]; then echo "Error: Masukkan ID."; exit 1; fi
        line=$(grep "^$ID_ARG|" "$CONF_FILE")
        if [[ -z "$line" ]]; then echo "Error: ID tidak ditemukan."; exit 1; fi
        
        IFS='|' read -r id src dest ret cron <<< "$line"
        echo "Menjalankan backup manual untuk $id..."
        bash "$SCRIPT_DIR/backup.sh" "$src" "$dest" "$ret"
        bash "$SCRIPT_DIR/rotation-backup.sh" "$dest" "$ret"
        ;;
    
    recovery)
        if [[ -z "$ID_ARG" ]]; then echo "Error: Masukkan ID."; exit 1; fi
        bash "$SCRIPT_DIR/recovery.sh" "$ID_ARG"
        ;;

    *)
        usage
        ;;
esac