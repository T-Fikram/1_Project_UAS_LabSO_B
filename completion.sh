#!/bin/bash
# FILE: completion.sh
# Fungsi: Memberikan fitur autocomplete (TAB) untuk main.sh

_autobackup_completion() {
    local cur prev opts commands service_opts conf_file
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    commands="list show create edit delete backup recovery"
    service_opts="--install-service --uninstall-service --install-completion --start-service --stop-service --status-service --update -y --help -h"

    # Cari file config
    if [[ -f "./project.conf" ]]; then conf_file="./project.conf"
    elif [[ -f "../project.conf" ]]; then conf_file="../project.conf"
    fi

    _get_ids() {
        if [[ -n "$conf_file" ]]; then
            grep -v '^#' "$conf_file" | grep -v '^$' | cut -d'|' -f1
        fi
    }

    # Level 1: Command Utama (create, list, dll)
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "${service_opts}" -- ${cur}) )
        else
            COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        fi
        return 0
    fi

    # Level 2+: Argumen Perintah
    case "${COMP_WORDS[1]}" in
        create)
            # Create menerima path folder, JANGAN sarankan ID
            # Biarkan default bash completion (file/folder) bekerja
            COMPREPLY=() 
            ;;
        
        edit)
            # Argumen ke-2 harus ID
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                local ids=$(_get_ids)
                COMPREPLY=( $(compgen -W "${ids}" -- ${cur}) )
            else
                # Argumen ke-3 dst adalah Path Folder, jangan sarankan ID
                COMPREPLY=()
            fi
            ;;

        show|backup|delete|recovery)
            # Argumen ke-2 harus ID
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                local ids=$(_get_ids)
                COMPREPLY=( $(compgen -W "${ids}" -- ${cur}) )
            elif [[ "${COMP_WORDS[1]}" == "delete" && ${COMP_CWORD} -ge 3 ]]; then
                # Khusus delete argumen ke-3 bisa opsi
                COMPREPLY=( $(compgen -W "--purge -y" -- ${cur}) )
            elif [[ "${COMP_WORDS[1]}" == "recovery" && ${COMP_CWORD} -ge 3 ]]; then
                 # Khusus recovery argumen ke-3 dst
                 COMPREPLY=( $(compgen -W "latest -y" -- ${cur}) )
            fi
            ;;
    esac
}

complete -F _autobackup_completion ./main.sh
complete -F _autobackup_completion ./src/main.sh
complete -F _autobackup_completion src/main.sh