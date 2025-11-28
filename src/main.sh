#!/bin/bash
# FILE: src/main.sh
# Fungsi: Main Menu Dashboard

# Setup Path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/../project.conf"

# Pastikan script lain bisa dieksekusi
chmod +x "$SCRIPT_DIR/"*.sh 2>/dev/null

show_header() {
    clear
    echo "=========================================="
    echo "   SYSTEM BACKUP & ROTASI OTOMATIS (UAS)"
    echo "=========================================="
}

run_manual_backup() {
    echo -e "\n--- Jalankan Backup Manual ---"
    # Cek config
    if [[ ! -s "$CONF_FILE" ]]; then
        echo "Belum ada konfigurasi. Silakan setup dulu."
        return
    fi

    # Baca config ke dalam array untuk dipilih
    mapfile -t lines < <(grep -v '^#' "$CONF_FILE" | grep -v '^$')
    
    if [[ ${#lines[@]} -eq 0 ]]; then
        echo "Konfigurasi kosong."
        return
    fi

    echo "Pilih tugas backup untuk dijalankan:"
    i=1
    for line in "${lines[@]}"; do
        IFS='|' read -r src dest ret int <<< "$line"
        echo "[$i] $src -> $dest"
        ((i++))
    done

    read -p "Nomor (0 untuk semua): " choice

    if [[ "$choice" == "0" ]]; then
        # Jalankan Semua dengan autoservice logic (tanpa cek waktu)
        echo "Menjalankan semua backup..."
        # Kita panggil backup.sh langsung loop manual agar paksa jalan
        for line in "${lines[@]}"; do
            IFS='|' read -r src dest ret int <<< "$line"
            bash "$SCRIPT_DIR/backup.sh" "$src" "$dest" "$ret"
            bash "$SCRIPT_DIR/rotation-backup.sh" "$dest" "$ret"
        done
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#lines[@]}" ]; then
        # Jalankan Satu
        idx=$((choice-1))
        IFS='|' read -r src dest ret int <<< "${lines[$idx]}"
        bash "$SCRIPT_DIR/backup.sh" "$src" "$dest" "$ret"
        bash "$SCRIPT_DIR/rotation-backup.sh" "$dest" "$ret"
    else
        echo "Pilihan tidak valid."
    fi
    
    read -p "Tekan Enter untuk lanjut..."
}

while true; do
    show_header
    echo "1. Manajemen Konfigurasi (Tambah/Hapus Folder)"
    echo "2. Jalankan Backup Manual (Sekarang)"
    echo "3. Recovery / Restore Data"
    echo "4. Install Otomatisasi (Systemd Service)"
    echo "5. Keluar"
    echo "------------------------------------------"
    read -p "Pilihan Anda: " main_menu

    case $main_menu in
        1) 
            bash "$SCRIPT_DIR/edit-conf.sh" 
            ;;
        2) 
            run_manual_backup 
            ;;
        3) 
            if [[ -f "$SCRIPT_DIR/recovery.sh" ]]; then
                bash "$SCRIPT_DIR/recovery.sh"
            else
                echo "Modul recovery belum dibuat."
                read -p "Enter..."
            fi
            ;;
        4) 
            if [[ -f "$SCRIPT_DIR/../install-service.sh" ]]; then
                bash "$SCRIPT_DIR/../install-service.sh"
            else
                echo "Script installer belum ada di root folder."
                read -p "Enter..."
            fi
            ;;
        5) 
            echo "Terima kasih."
            exit 0 
            ;;
        *) 
            echo "Input salah." 
            sleep 1
            ;;
    esac
done