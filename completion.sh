#!/bin/bash
# FILE: completion.sh

_autobackup_completion() {
    local cur prev opts commands service_opts conf_file
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    commands="list show create edit delete backup recovery"
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


    if [[ ${COMP_CWORD} -eq 1 ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "${service_opts}" -- ${cur}) )
        else
            COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        fi
        return 0
    fi

    case "${prev}" in
        --install-service)
            COMPREPLY=( $(compgen -W "--update" -- ${cur}) )
            return 0
            ;;
        
        show|backup)
            local ids=$(_get_ids)
            COMPREPLY=( $(compgen -W "${ids}" -- ${cur}) )
            return 0
            ;;
        delete)
            local ids=$(_get_ids)
            COMPREPLY=( $(compgen -W "${ids}" -- ${cur}) )
            return 0
            ;;
        create)
            COMPREPLY=() 
            return 0
            ;;
        edit|recovery)
            local ids=$(_get_ids)
            COMPREPLY=( $(compgen -W "${ids}" -- ${cur}) )
            return 0
            ;;
    esac

    local prev2="${COMP_WORDS[COMP_CWORD-2]}"
    
    if [[ "${prev2}" == "delete" ]]; then
         COMPREPLY=( $(compgen -W "--purge" -- ${cur}) )
         return 0
    elif [[ "${prev2}" == "recovery" ]]; then
         COMPREPLY=( $(compgen -W "latest" -- ${cur}) )
         return 0
    fi
}

complete -F _autobackup_completion ./main.sh
complete -F _autobackup_completion ./src/main.sh
complete -F _autobackup_completion src/main.sh