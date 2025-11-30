#!/bin/bash
# FILE: src/autoservice.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/../project.conf"

check_cron_match() {
    local cron_str="$1"
    local min=$(date +%-M)
    local hour=$(date +%-H)
    local dom=$(date +%-d)
    local mon=$(date +%-m)
    local dow=$(date +%-w)
    read -r c_min c_hour c_dom c_mon c_dow <<< "$cron_str"

    match_field() {
        local current=$1
        local pattern=$2
        if [[ "$pattern" == "*" ]]; then return 0;
        elif [[ "$pattern" =~ ^\*/([0-9]+)$ ]]; then
            local step=${BASH_REMATCH[1]}
            if (( current % step == 0 )); then return 0; else return 1; fi
        elif [[ "$pattern" == "$current" ]]; then return 0;
        else return 1; fi
    }
    match_field "$min" "$c_min" && match_field "$hour" "$c_hour" && match_field "$dom" "$c_dom" && match_field "$mon" "$c_mon" && match_field "$dow" "$c_dow"
}

grep -v '^#' "$CONF_FILE" | grep -v '^$' | while IFS='|' read -r id src dest ret cron; do
    LOCK_FILE="/tmp/autobackup-${id}.lock"

    if [[ -f "$LOCK_FILE" ]]; then
        LOCK_PID=$(cat "$LOCK_FILE")
        if kill -0 "$LOCK_PID" 2>/dev/null; then
            continue
        else
            rm -f "$LOCK_FILE"
        fi
    fi
    
    if check_cron_match "$cron"; then
        echo $$ > "$LOCK_FILE"
        bash "$SCRIPT_DIR/backup.sh" "$src" "$dest" "$ret" "$id"
        bash "$SCRIPT_DIR/rotation-backup.sh" "$dest" "$ret" "$id"
        rm -f "$LOCK_FILE"
    fi
done