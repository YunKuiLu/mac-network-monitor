#!/bin/bash
# Network Monitor Installation Script

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
PLIST_FILE="$SCRIPT_DIR/com.network.monitor.plist"
STATUS_SCRIPT="$SCRIPT_DIR/status.sh"

# Source config to get paths
source "$CONFIG_FILE"

# Initialize i18n
if [[ -f "$SCRIPT_DIR/i18n/i18n.sh" ]]; then
    source "$SCRIPT_DIR/i18n/i18n.sh"
    i18n_init "$SCRIPT_DIR" "${LANGUAGE:-}"
fi

echo "======================================"
if type t &>/dev/null; then
    echo "$(t "install.title")"
else
    echo "Network Monitor Installation"
fi
echo "======================================"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "$(t "install.not_root")"
    exit 1
fi

# Make scripts executable
echo "$(t "msg.making_executable")"
chmod +x "$SCRIPT_DIR/network-monitor.sh"
chmod +x "$SCRIPT_DIR/status.sh"
chmod +x "$SCRIPT_DIR/uninstall.sh"

# Create log directory
echo "$(t "msg.creating_log_dir" "$LOG_DIR")"
mkdir -p "$LOG_DIR"

# Set config file permissions (restrictive for password security)
echo "$(t "msg.setting_permissions")"
chmod 600 "$CONFIG_FILE"

# Create LaunchAgents directory if it doesn't exist
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCH_AGENTS_DIR"

# Copy plist file to LaunchAgents
PLIST_DEST="$LAUNCH_AGENTS_DIR/com.network.monitor.plist"
echo "$(t "install.installing_plist" "$PLIST_DEST")"

# Update plist with actual user path if needed
sed "s|/Users/luyunkui|$HOME|g" "$PLIST_FILE" > "$PLIST_DEST"

# Load the launchd agent
echo "$(t "install.loading_launchd")"
launchctl load "$PLIST_DEST" 2>/dev/null || {
    t "install.warning.load_failed" "$PLIST_DEST"
}

# Create symlink for CLI tool
BIN_LINK="/usr/local/bin/nm-status"
if [[ -w /usr/local/bin ]] || mkdir -p /usr/local/bin 2>/dev/null; then
    if [[ -L "$BIN_LINK" ]]; then
        echo "$(t "install.removing_existing_symlink" "$BIN_LINK")"
        rm "$BIN_LINK"
    fi
    echo "$(t "install.creating_symlink" "$BIN_LINK" "$STATUS_SCRIPT")"
    ln -s "$STATUS_SCRIPT" "$BIN_LINK"
    chmod +x "$BIN_LINK"
else
    t "install.warning.symlink_failed" "$BIN_LINK" "$STATUS_SCRIPT" "$BIN_LINK"
fi

echo ""
echo "======================================"
echo "$(t "install.complete")"
echo "======================================"
echo ""
echo "$(t "install.info.running")"
echo ""
echo "$(t "install.info.commands"):"
echo "  nm-status          - Show recent logs"
echo "  nm-status show     - Show recent logs"
echo "  nm-status status   - Show launchd task status"
echo "  nm-status tail     - Follow log in real-time"
echo "  nm-status test     - Run manual network check"
echo "  nm-status wifi     - Show current WiFi info"
echo ""
echo "Log files:"
echo "  Main log:    $LOG_FILE"
echo "  Error log:   $ERROR_LOG_FILE"
echo ""
echo "To uninstall, run:"
echo "  $SCRIPT_DIR/uninstall.sh"
echo ""
