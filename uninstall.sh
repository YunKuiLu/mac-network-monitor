#!/bin/bash
# Network Monitor Uninstallation Script

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"

# Source config to get paths
source "$CONFIG_FILE"

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DEST="$LAUNCH_AGENTS_DIR/com.network.monitor.plist"
BIN_LINK="/usr/local/bin/nm-status"

echo "======================================"
echo "Network Monitor Uninstallation"
echo "======================================"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "ERROR: This script should not be run as root. Run as your regular user."
    exit 1
fi

# Unload the launchd agent
if launchctl list | grep -q "com.network.monitor"; then
    echo "Unloading launchd agent..."
    launchctl unload "$PLIST_DEST" 2>/dev/null || {
        echo "WARNING: Failed to unload via launchctl. Trying bootout..."
        launchctl bootout gui/"$(id -u)"/com.network.monitor 2>/dev/null || true
    }
else
    echo "Launchd agent not currently loaded."
fi

# Remove plist file
if [[ -f "$PLIST_DEST" ]]; then
    echo "Removing launchd plist file: $PLIST_DEST"
    rm "$PLIST_DEST"
else
    echo "Launchd plist file not found: $PLIST_DEST"
fi

# Remove CLI symlink
if [[ -L "$BIN_LINK" ]]; then
    echo "Removing CLI symlink: $BIN_LINK"
    if [[ -w /usr/local/bin ]] || rm "$BIN_LINK" 2>/dev/null; then
        rm "$BIN_LINK"
    else
        echo "WARNING: Could not remove symlink. You may need sudo:"
        echo "  sudo rm '$BIN_LINK'"
    fi
elif [[ -f "$BIN_LINK" ]]; then
    echo "WARNING: $BIN_LINK exists but is not a symlink. Not removing."
else
    echo "CLI symlink not found: $BIN_LINK"
fi

# Ask about log files
echo ""
echo "Log files are preserved at: $LOG_DIR"
echo "If you want to remove them, run:"
echo "  rm -rf '$LOG_DIR'"
echo ""

echo "======================================"
echo "Uninstallation Complete!"
echo "======================================"
echo ""
echo "The network monitor has been uninstalled."
echo "Your configuration and log files have been preserved."
echo ""
