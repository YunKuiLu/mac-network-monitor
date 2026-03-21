#!/bin/bash
# Network Monitor Installation Script

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
PLIST_FILE="$SCRIPT_DIR/com.network.monitor.plist"
STATUS_SCRIPT="$SCRIPT_DIR/status.sh"

# Source config to get paths
source "$CONFIG_FILE"

echo "======================================"
echo "Network Monitor Installation"
echo "======================================"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "ERROR: This script should not be run as root. Run as your regular user."
    exit 1
fi

# Make scripts executable
echo "Making scripts executable..."
chmod +x "$SCRIPT_DIR/network-monitor.sh"
chmod +x "$SCRIPT_DIR/status.sh"
chmod +x "$SCRIPT_DIR/uninstall.sh"

# Create log directory
echo "Creating log directory at: $LOG_DIR"
mkdir -p "$LOG_DIR"

# Set config file permissions (restrictive for password security)
echo "Setting config file permissions..."
chmod 600 "$CONFIG_FILE"

# Create LaunchAgents directory if it doesn't exist
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCH_AGENTS_DIR"

# Copy plist file to LaunchAgents
PLIST_DEST="$LAUNCH_AGENTS_DIR/com.network.monitor.plist"
echo "Installing launchd agent to: $PLIST_DEST"

# Update plist with actual user path if needed
sed "s|/Users/luyunkui|$HOME|g" "$PLIST_FILE" > "$PLIST_DEST"

# Load the launchd agent
echo "Loading launchd agent..."
launchctl load "$PLIST_DEST" 2>/dev/null || {
    echo "WARNING: Failed to load launchd agent. You may need to run:"
    echo "  launchctl load '$PLIST_DEST'"
}

# Create symlink for CLI tool
BIN_LINK="/usr/local/bin/nm-status"
if [[ -w /usr/local/bin ]] || mkdir -p /usr/local/bin 2>/dev/null; then
    if [[ -L "$BIN_LINK" ]]; then
        echo "Removing existing symlink at $BIN_LINK"
        rm "$BIN_LINK"
    fi
    echo "Creating CLI symlink: $BIN_LINK -> $STATUS_SCRIPT"
    ln -s "$STATUS_SCRIPT" "$BIN_LINK"
    chmod +x "$BIN_LINK"
else
    echo "WARNING: Could not create symlink at /usr/local/bin/nm-status"
    echo "You may need to run with sudo or create it manually:"
    echo "  sudo ln -s '$STATUS_SCRIPT' /usr/local/bin/nm-status"
fi

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""
echo "Network Monitor is now running and will check every 30 minutes."
echo ""
echo "Available Commands:"
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
