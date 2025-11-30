#!/bin/bash
# FILE: completion.sh
# Fungsi: Memberikan fitur autocomplete (TAB) untuk main.sh yang KONTEKSTUAL

_autobackup_completion() {
    local cur prev opts commands service_opts conf_file
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # 1. Level Utama: Hanya Command dan Service Controller Utama
    commands="list show create edit delete backup recovery"
    # HAPUS --update dan -y dari sini agar tidak muncul di awal
    service_opts="--install-service --uninstall-service --install-completion --start-service --stop-service --status-service --help -h"

    # Cari file config
    if [[ -f "./project.conf" ]]; then conf_file="./project.conf"
    elif [[ -f "../project.conf" ]]; then conf_file="../project.conf"
    fi

    _get_ids() {
        if [[ -n "$conf_file" ]]; then
            grep -v '^#' "$conf_file" | grep -v '^$' | cut -d'|' -f1
        fi
    }

    # === LOGIKA BERTINGKAT ===

    # Level 1: Saat kursor ada di argumen pertama (setelah nama script)
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "${service_opts}" -- ${cur}) )
        else
            COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        fi
        return 0
    fi

    # Level 2+: Argumen Lanjutan (Context Aware)
    case "${prev}" in
        # KASUS: Service Options
        --install-service)
            # Hanya suggest --update setelah install
            COMPREPLY=( $(compgen -W "--update" -- ${cur}) )
            return 0
            ;;
        --uninstall-service)
            # Hanya suggest -y setelah uninstall
            COMPREPLY=( $(compgen -W "-y" -- ${cur}) )
            return 0
            ;;
        
        # KASUS: Command Utama
        show|backup)
            local ids=$(_get_ids)
            COMPREPLY=( $(compgen -W "${ids}" -- ${cur}) )
            return 0
            ;;
        delete)
            # Jika baru ngetik delete, suggest ID
            local ids=$(_get_ids)
            COMPREPLY=( $(compgen -W "${ids}" -- ${cur}) )
            return 0
            ;;
        create)
            # Create butuh path, jangan suggest ID
            COMPREPLY=() 
            return 0
            ;;
        edit|recovery)
            # Edit/Recovery butuh ID dulu
            local ids=$(_get_ids)
            COMPREPLY=( $(compgen -W "${ids}" -- ${cur}) )
            return 0
            ;;
    esac

    # Level 3: Opsi Lanjutan (Misal setelah ID diketik untuk delete)
    local prev2="${COMP_WORDS[COMP_CWORD-2]}"
    
    if [[ "${prev2}" == "delete" ]]; then
         COMPREPLY=( $(compgen -W "--purge -y" -- ${cur}) )
         return 0
    elif [[ "${prev2}" == "create" ]]; then
         # Argumen ke-6 create adalah -y
         if [[ ${COMP_CWORD} -eq 6 ]]; then
            COMPREPLY=( $(compgen -W "-y" -- ${cur}) )
         fi
         return 0
    elif [[ "${prev2}" == "recovery" ]]; then
         COMPREPLY=( $(compgen -W "latest -y" -- ${cur}) )
         return 0
    fi
}

complete -F _autobackup_completion ./main.sh
complete -F _autobackup_completion ./src/main.sh
complete -F _autobackup_completion src/main.sh