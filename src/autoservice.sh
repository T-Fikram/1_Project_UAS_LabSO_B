#!/bin/bash
# FILE: src/autoservice.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/../project.conf"

# Fungsi cek cron sederhana (Pure Bash)
# Mengembalikan 0 jika match, 1 jika tidak
check_cron_match() {
    local cron_str="$1"
    
    # Ambil waktu sekarang
    local min=$(date +%-M)  # 0-59
    local hour=$(date +%-H) # 0-23
    local dom=$(date +%-d)  # 1-31
    local mon=$(date +%-m)  # 1-12
    local dow=$(date +%-w)  # 0-6 (0=Sunday)

    read -r c_min c_hour c_dom c_mon c_dow <<< "$cron_str"

    # Fungsi pembantu untuk cek satu field (support * dan */n dan angka tepat)
    match_field() {
        local current=$1
        local pattern=$2
        
        if [[ "$pattern" == "*" ]]; then
            return 0
        elif [[ "$pattern" =~ ^\*/([0-9]+)$ ]]; then
            # Step (e.g., */5)
            local step=${BASH_REMATCH[1]}
            if (( current % step == 0 )); then return 0; else return 1; fi
        elif [[ "$pattern" == "$current" ]]; then
            return 0
        else
            # Komplesitas lain (range 1-5, list 1,2) dilewati untuk simplifikasi UAS
            return 1
        fi
    }

    match_field "$min" "$c_min" && \
    match_field "$hour" "$c_hour" && \
    match_field "$dom" "$c_dom" && \
    match_field "$mon" "$c_mon" && \
    match_field "$dow" "$c_dow"
}

# Loop config
grep -v '^#' "$CONF_FILE" | grep -v '^$' | while IFS='|' read -r id src dest ret cron; do
    if pgrep -f "tar.*$src" > /dev/null; then
        echo "Skip $id: Backup still running."
        continue
    fi
    
    if check_cron_match "$cron"; then
        echo "[AUTO] Schedule match for $id ($cron). Running backup..."
        bash "$SCRIPT_DIR/backup.sh" "$src" "$dest" "$ret"
        bash "$SCRIPT_DIR/rotation-backup.sh" "$dest" "$ret"
    fi
done