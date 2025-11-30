#!/bin/bash
# FILE: install-service.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$ROOT_DIR/src/autoservice.sh"
SERVICE_NAME="autobackup"
SYSTEMD_DIR="$HOME/.config/systemd/user"
COMPLETION_FILE="$ROOT_DIR/completion.sh"

MODE="install"
AUTO_YES=false
FORCE_UPDATE=false

for arg in "$@"; do
    case $arg in
        uninstall|--uninstall) MODE="uninstall" ;;
        -y|--yes) AUTO_YES=true ;;
        --update) FORCE_UPDATE=true ;;
    esac
done

if [[ "$MODE" == "uninstall" ]]; then
    echo "Uninstaller initiated."

    if [[ "$AUTO_YES" == "false" ]]; then
        echo "WARNING: This will stop the service and remove configurations."
        echo -n "Continue? (y/n): "
        read confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Aborted."
            exit 0
        fi
    fi
    
    if systemctl --user list-unit-files | grep -q "$SERVICE_NAME.timer"; then
        systemctl --user stop "$SERVICE_NAME.timer"
        systemctl --user disable "$SERVICE_NAME.timer"
        systemctl --user stop "$SERVICE_NAME.service" 2>/dev/null
    fi

    rm -f "$SYSTEMD_DIR/$SERVICE_NAME.service"
    rm -f "$SYSTEMD_DIR/$SERVICE_NAME.timer"
    systemctl --user daemon-reload

    if [[ -f "$HOME/.bashrc" ]]; then
        sed -i "\|source $COMPLETION_FILE|d" "$HOME/.bashrc"
    fi

    echo "Uninstall complete."
    exit 0
fi

echo "Installing AutoBackup Service..."

if [[ -f "$SYSTEMD_DIR/$SERVICE_NAME.service" ]]; then
    if [[ "$FORCE_UPDATE" == "true" ]]; then
        echo "Update mode: Overwriting config."
    else
        echo "Service already installed. Use --update to force reinstall."
        exit 0
    fi
fi

if [[ ! -x "$SCRIPT_PATH" ]]; then
    chmod +x "$SCRIPT_PATH"
fi

mkdir -p "$SYSTEMD_DIR"

cat > "$SYSTEMD_DIR/$SERVICE_NAME.service" <<EOF
[Unit]
Description=AutoBackup User Service
Wants=$SERVICE_NAME.timer

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
EOF

cat > "$SYSTEMD_DIR/$SERVICE_NAME.timer" <<EOF
[Unit]
Description=AutoBackup Timer
Requires=$SERVICE_NAME.service

[Timer]
Unit=$SERVICE_NAME.service
OnCalendar=*-*-* *:*:00
Persistent=false

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE_NAME.timer"

echo "------------------------------------------------"
systemctl --user list-timers --no-pager | grep "$SERVICE_NAME" | \
awk '{printf "NEXT: %-20s %-5s | LAST: %-20s | UNIT: %s\n", $1" "$2, $3, $6" "$7, $10}'
echo "------------------------------------------------"

bash "$ROOT_DIR/src/main.sh" --install-completion

echo "Installation complete."