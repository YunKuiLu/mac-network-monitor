#!/bin/bash
# Network Monitor Uninstallation Script

set -euo pipefail

# Get script directory (follow symlinks to find real location)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"

# Source config to get paths
source "$CONFIG_FILE"

# Initialize i18n
if [[ -f "$SCRIPT_DIR/i18n/i18n.sh" ]]; then
    source "$SCRIPT_DIR/i18n/i18n.sh"
    i18n_init "$SCRIPT_DIR" "${LANGUAGE:-}"
fi

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DEST="$LAUNCH_AGENTS_DIR/com.network.monitor.plist"
BIN_LINK="/usr/local/bin/nm-status"

echo "======================================"
if type t &>/dev/null; then
    echo "$(t "uninstall.title")"
else
    echo "Network Monitor Uninstallation"
fi
echo "======================================"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "$(t "install.not_root")"
    exit 1
fi

# Unload the launchd agent
if launchctl list | grep -q "com.network.monitor"; then
    echo "$(t "uninstall.unloading")"
    launchctl unload "$PLIST_DEST" 2>/dev/null || {
        echo "$(t "uninstall.warning.unload_failed")"
        launchctl bootout gui/"$(id -u)"/com.network.monitor 2>/dev/null || true
    }
else
    echo "$(t "uninstall.not_loaded")"
fi

# Remove plist file
if [[ -f "$PLIST_DEST" ]]; then
    echo "$(t "uninstall.removing_plist" "$PLIST_DEST")"
    rm "$PLIST_DEST"
else
    echo "$(t "uninstall.plist_not_found" "$PLIST_DEST")"
fi

# Remove CLI symlink
if [[ -L "$BIN_LINK" ]]; then
    echo "$(t "uninstall.removing_symlink" "$BIN_LINK")"
    if [[ -w /usr/local/bin ]] || rm "$BIN_LINK" 2>/dev/null; then
        rm "$BIN_LINK"
    else
        t "uninstall.warning.symlink_remove_failed" "$BIN_LINK"
    fi
elif [[ -f "$BIN_LINK" ]]; then
    echo "$(t "uninstall.symlink_not_symlink" "$BIN_LINK")"
else
    echo "$(t "uninstall.symlink_not_found" "$BIN_LINK")"
fi

# Ask about log files
echo ""
t "uninstall.logs_preserved" "$LOG_DIR" "$LOG_DIR"
echo ""

echo "======================================"
echo "$(t "uninstall.complete")"
echo "======================================"
echo ""
printf "$(t "uninstall.info")\n"
echo ""
