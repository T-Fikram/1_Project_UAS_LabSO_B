#!/bin/bash
# FILE: completion.sh
# Fungsi: Memberikan fitur autocomplete (TAB) untuk main.sh

_autobackup_completion() {
    local cur prev opts commands service_opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Daftar perintah utama
    commands="list show create edit delete backup recovery"
    
    # Daftar opsi service (diawali --)
    service_opts="--install-service --install-completion --start-service --stop-service --status-service --uninstall-service --update -y --help -h"

    # Lokasi config: Coba cari di folder saat ini atau parent folder
    local conf_file=""
    if [[ -f "./project.conf" ]]; then
        conf_file="./project.conf"
    elif [[ -f "../project.conf" ]]; then
        conf_file="../project.conf"
    fi

    # Fungsi helper untuk mengambil ID backup dari file config
    _get_ids() {
        if [[ -n "$conf_file" ]]; then
            # Ambil kolom pertama (ID), abaikan komentar
            grep -v '^#' "$conf_file" | grep -v '^$' | cut -d'|' -f1
        fi
    }

    # === LOGIKA AUTOCOMPLETE ===

    # Level 1: Saat kursor ada di argumen pertama (setelah nama script)
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        if [[ "$cur" == -* ]]; then
            # Jika user mengetik tanda minus (-), sarankan opsi service
            COMPREPLY=( $(compgen -W "${service_opts}" -- ${cur}) )
        else
            # Jika tidak, sarankan perintah utama
            COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        fi
        return 0
    fi

    # Level 2: Saat kursor ada di argumen kedua (setelah perintah utama)
    case "${prev}" in
        show|edit|backup|recovery)
            # Sarankan daftar ID yang ada di project.conf
            local ids=$(_get_ids)
            COMPREPLY=( $(compgen -W "${ids}" -- ${cur}) )
            return 0
            ;;
        delete)
            # Sarankan ID untuk dihapus
            local ids=$(_get_ids)
            COMPREPLY=( $(compgen -W "${ids}" -- ${cur}) )
            return 0
            ;;
        *)
            ;;
    esac

    # Level 3: Khusus perintah delete (setelah ID diketik)
    # Contoh: ./src/main.sh delete id_backup [TAB] -> muncul --purge atau -y
    local prev2="${COMP_WORDS[COMP_CWORD-2]}"
    if [[ "${prev2}" == "delete" ]]; then
         COMPREPLY=( $(compgen -W "--purge -y" -- ${cur}) )
         return 0
    fi
}

# Daftarkan fungsi completion ini ke script main.sh
# Kita daftarkan untuk berbagai cara pemanggilan script
complete -F _autobackup_completion ./main.sh
complete -F _autobackup_completion ./src/main.sh
complete -F _autobackup_completion src/main.sh