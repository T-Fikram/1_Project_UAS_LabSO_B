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
    echo "  list                  List active backups"
    echo "  create                Create new backup config"
    echo "  edit <id>             Edit existing config"
    echo "  delete <id>           Delete config"
    echo "  backup <id>           Trigger manual backup"
    echo "  recovery <id>         Restore data"
    echo ""
    echo "Service Control:"
    echo "  --install-service     Install systemd service"
    echo "  --uninstall-service   Remove service"
    echo "  --start-service       Start timer"
    echo "  --stop-service        Stop timer"
    echo "  --status-service      Check status"
    exit "$exit_code"
}

# --- Global Flags ---
if [[ "$1" == "-h" || "$1" == "--help" ]]; then usage 0; fi
if [[ "$1" == "--install-service" ]]; then shift; bash "$ROOT_DIR/install-service.sh" "$@"; exit 0; fi
if [[ "$1" == "--uninstall-service" ]]; then shift; bash "$ROOT_DIR/install-service.sh" uninstall "$@"; exit 0; fi

if [[ "$1" == "--install-completion" ]]; then
    COMP_FILE="$ROOT_DIR/completion.sh"
    BASH_RC="$HOME/.bashrc"

    if [[ ! -f "$COMP_FILE" ]]; then
        echo "Error: completion.sh not found."
        exit 1
    fi

    if grep -qF "source $COMP_FILE" "$BASH_RC"; then
        echo "Completion already installed."
    else
        echo "" >> "$BASH_RC"
        echo "source $COMP_FILE" >> "$BASH_RC"
        echo "Completion installed. Run 'source ~/.bashrc' to apply."
    fi
    exit 0
fi

# --- Service Validation ---
check_service_health
HEALTH_STATUS=$?
if [[ "$HEALTH_STATUS" -eq 1 ]]; then
    echo "Error: Service not installed. Run --install-service first."; usage 1
elif [[ "$HEALTH_STATUS" -eq 2 ]]; then
    if [[ "$1" != "--start-service" && "$1" != "--stop-service" && "$1" != "--status-service" ]]; then
        echo "Note: Service is currently stopped."
    fi
fi

# --- Controllers ---
if [[ "$1" == "--start-service" ]]; then systemctl --user start "${SERVICE_NAME}.timer"; echo "Service started."; exit 0; fi
if [[ "$1" == "--stop-service" ]]; then systemctl --user stop "${SERVICE_NAME}.timer"; echo "Service stopped."; exit 0; fi
if [[ "$1" == "--status-service" ]]; then systemctl --user status "${SERVICE_NAME}.timer"; exit 0; fi

COMMAND="$1"
ID_ARG="$2"

error_arg() {
    echo "Error: Invalid argument '$1' for command '$COMMAND'."
    usage 1
}

case "$COMMAND" in
    list)
        if [[ -n "$2" ]]; then error_arg "$2"; fi
        echo "ID           | SOURCE PATH"
        echo "------------------------------------------------"
        grep -v '^#' "$CONF_FILE" | grep -v '^$' | while IFS='|' read -r id src dest ret cron; do
            printf "%-12s | %s\n" "$id" "$src"
        done
        ;;

    show)
        if [[ -z "$ID_ARG" ]]; then echo "Error: Missing ID."; usage 1; fi
        if [[ -n "$3" ]]; then error_arg "$3"; fi

        line=$(grep "^$ID_ARG|" "$CONF_FILE")
        if [[ -z "$line" ]]; then echo "Error: ID not found."; exit 1; fi
        IFS='|' read -r id src dest ret cron <<< "$line"
        echo "ID        : $id"
        echo "Source    : $src"
        echo "Dest      : $dest"
        echo "Retention : $ret days"
        echo "Schedule  : $cron"
        ;;

    create)
        if [[ -n "$6" && "$6" != "-y" ]]; then error_arg "$6"; fi
        if [[ -n "$7" ]]; then error_arg "$7"; fi
        
        SRC_IN="$2"
        DEST_IN="$3"
        RET_IN="$4"
        CRON_IN="$5"
        AUTO_YES=false
        if [[ "$6" == "-y" ]]; then AUTO_YES=true; fi

        if [[ -n "$SRC_IN" && -n "$DEST_IN" && -n "$RET_IN" && -n "$CRON_IN" ]]; then
            src=$(realpath "${SRC_IN/#~/$HOME}")
            dest=$(realpath "${DEST_IN/#~/$HOME}")
            ret="$RET_IN"
            cron="$CRON_IN"
        else
            new_id=$(generate_id)
            echo "Creating config ID: $new_id"
            read -e -p "Source Folder: " src_raw
            src=$(realpath "${src_raw/#~/$HOME}")
            read -e -p "Destination Folder: " dest_raw
            dest=$(realpath "${dest_raw/#~/$HOME}")
            mkdir -p "$dest"
            read -p "Retention (days): " ret
            echo "Cron Format: m h dom mon dow (e.g., '*/30 * * * *')"
            read -p "Schedule: " cron
        fi

        if grep -q "|$dest|" "$CONF_FILE"; then
            if [[ "$AUTO_YES" == "false" ]]; then
                echo "WARNING: Destination '$dest' is used by another config."
                read -p "Continue? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then echo "Aborted."; exit 1; fi
            fi
        fi

        validate_cron "$cron"
        if [[ $? -ne 0 ]]; then
            echo "Error: Invalid cron format."
            exit 1
        fi

        new_id=$(generate_id)
        echo "$new_id|$src|$dest|$ret|$cron" >> "$CONF_FILE"
        echo "Config created: $new_id"
        ;;

    edit)
        if [[ -z "$ID_ARG" ]]; then echo "Error: Missing ID."; usage 1; fi
        line=$(grep "^$ID_ARG|" "$CONF_FILE")
        if [[ -z "$line" ]]; then echo "Error: ID not found."; exit 1; fi
        if [[ -n "$7" ]]; then error_arg "$7"; fi
        
        IFS='|' read -r oid osrc odest oret ocron <<< "$line"
        
        if [[ -n "$3" && -n "$4" && -n "$5" && -n "$6" ]]; then
            nsrc=$(realpath "${3/#~/$HOME}")
            ndest=$(realpath "${4/#~/$HOME}")
            nret="$5"
            ncron="$6"
        else
            echo "Editing $ID_ARG (Press Enter to keep current)"
            read -e -p "Source [$osrc]: " nsrc
            nsrc=${nsrc:-$osrc}
            read -e -p "Dest [$odest]: " ndest
            ndest=${ndest:-$odest}
            read -p "Retention [$oret]: " nret
            nret=${nret:-$oret}
            read -p "Schedule [$ocron]: " ncron
            ncron=${ncron:-$ocron}
        fi

        validate_cron "$ncron"
        if [[ $? -ne 0 ]]; then echo "Error: Invalid cron format."; exit 1; fi

        grep -v "^$ID_ARG|" "$CONF_FILE" > "$CONF_FILE.tmp" && mv "$CONF_FILE.tmp" "$CONF_FILE"
        echo "$ID_ARG|$nsrc|$ndest|$nret|$ncron" >> "$CONF_FILE"
        echo "Config updated."
        ;;

    delete)
        if [[ -z "$ID_ARG" ]]; then echo "Error: Missing ID."; usage 1; fi
        line=$(grep "^$ID_ARG|" "$CONF_FILE")
        if [[ -z "$line" ]]; then echo "Error: ID not found."; exit 1; fi

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
                echo "WARNING: This will permanently delete backup files for ID: $id"
                read -p "Confirm? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then exit 1; fi
            fi
            echo "Deleting files $id-*.tar.gz in $dest..."
            find "$dest" -name "${id}-*.tar.gz" -delete
        fi

        grep -v "^$ID_ARG|" "$CONF_FILE" > "$CONF_FILE.tmp" && mv "$CONF_FILE.tmp" "$CONF_FILE"
        echo "Config $ID_ARG deleted."
        ;;

    backup)
        if [[ -z "$ID_ARG" ]]; then echo "Error: Missing ID."; usage 1; fi
        if [[ -n "$3" ]]; then error_arg "$3"; fi
        line=$(grep "^$ID_ARG|" "$CONF_FILE")
        IFS='|' read -r id src dest ret cron <<< "$line"
        bash "$SCRIPT_DIR/backup.sh" "$src" "$dest" "$ret" "$id"
        bash "$SCRIPT_DIR/rotation-backup.sh" "$dest" "$ret" "$id"
        ;;
    
    recovery)
        if [[ -z "$ID_ARG" ]]; then echo "Error: Missing ID."; usage 1; fi
        shift 
        bash "$SCRIPT_DIR/recovery.sh" "$@"
        ;;

    *)
        echo "Error: Unknown command '$COMMAND'."
        usage 1 
        ;;
esac