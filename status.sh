#!/bin/bash
# Network Monitor Status CLI Tool
# Usage: nm-status [command]

set -euo pipefail

# Get script directory (follow symlinks to find real location)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

# Load configuration
if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
    source "$SCRIPT_DIR/config.sh"
else
    echo "Error: Configuration file not found: $SCRIPT_DIR/config.sh" >&2
    exit 1
fi

# Initialize i18n
if [[ -f "$SCRIPT_DIR/i18n/i18n.sh" ]]; then
    source "$SCRIPT_DIR/i18n/i18n.sh"
    i18n_init "$SCRIPT_DIR" "${LANGUAGE:-}"
else
    echo "Warning: i18n loader not found, using default messages" >&2
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_color() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}"
}

# Show help
show_help() {
    cat << EOF
$(t "status.tool.name")

$(t "status.tool.usage")

$(t "status.tool.commands")
  $(t "status.cmd.show")
  $(t "status.cmd.status")
  $(t "status.cmd.tail")
  $(t "status.cmd.test")
  $(t "status.cmd.wifi")
  $(t "status.cmd.help")

$(t "status.tool.examples"):
  nm-status              # $(t "status.logs.header" 10)
  nm-status show         # $(t "status.logs.header" 10)
  nm-status status       # $(t "status.launchd.header")
  nm-status tail         # $(t "status.logs.realtime")
  nm-status test         # $(t "status.test.header")
  nm-status wifi         # $(t "status.wifi.header")

EOF
}

# Show recent logs
show_logs() {
    local lines="${1:-10}"

    if [[ ! -f "$LOG_FILE" ]]; then
        print_color "$YELLOW" "$(t "status.logs.not_found" "$LOG_FILE")"
        print_color "$YELLOW" "$(t "status.logs.not_running")"
        return 1
    fi

    echo "======================================"
    echo "$(t "status.logs.header" "$lines")"
    echo "======================================"
    echo ""
    tail -n "$lines" "$LOG_FILE" 2>/dev/null || print_color "$YELLOW" "$(t "status.logs.not_found" "$LOG_FILE")"
    echo ""
}

# Show launchd task status
show_status() {
    echo "======================================"
    echo "$(t "status.launchd.header")"
    echo "======================================"
    echo ""

    local plist_path="$HOME/Library/LaunchAgents/com.network.monitor.plist"

    # Check if plist file exists
    if [[ -f "$plist_path" ]]; then
        print_color "$GREEN" "✓ $(t "status.launchd.plist_installed" "$plist_path")"
    else
        print_color "$RED" "✗ $(t "status.launchd.plist_not_found" "$plist_path")"
        return 1
    fi

    echo ""

    # Check if task is loaded
    if launchctl list | grep -q "com.network.monitor"; then
        print_color "$GREEN" "✓ $(t "status.launchd.loaded")"
        echo ""
        echo "$(t "status.launchd.details"):"
        launchctl list | grep "com.network.monitor" || true
    else
        print_color "$YELLOW" "✗ $(t "status.launchd.not_loaded")"
        echo "$(t "status.launchd.load_hint")"
    fi

    echo ""

    # Show last run time from log
    if [[ -f "$LOG_FILE" ]]; then
        local last_check
        local monitor_start_marker
        if type t &>/dev/null; then
            monitor_start_marker="$(t "status.monitor_start")"
        else
            monitor_start_marker="=== 网络监控检测开始 ==="
        fi
        last_check=$(grep "$monitor_start_marker" "$LOG_FILE" 2>/dev/null | tail -1 || echo "")
        if [[ -n "$last_check" ]]; then
            print_color "$BLUE" "$(t "status.launchd.last_check")"
            echo "  $last_check"
        fi
    fi

    echo ""
}

# Tail logs in real-time
tail_logs() {
    if [[ ! -f "$LOG_FILE" ]]; then
        print_color "$YELLOW" "$(t "status.logs.not_found" "$LOG_FILE")"
        print_color "$YELLOW" "$(t "status.logs.not_running")"
        return 1
    fi

    echo "======================================"
    echo "$(t "status.logs.realtime")"
    echo "======================================"
    echo ""
    tail -f "$LOG_FILE"
}

# Run manual test
run_test() {
    echo "======================================"
    echo "$(t "status.test.header")"
    echo "======================================"
    echo ""

    local main_script="$SCRIPT_DIR/network-monitor.sh"

    if [[ ! -f "$main_script" ]]; then
        print_color "$RED" "$(t "status.test.script_not_found" "$main_script")"
        return 1
    fi

    if [[ ! -x "$main_script" ]]; then
        print_color "$YELLOW" "$(t "status.test.setting_permissions")"
        chmod +x "$main_script"
    fi

    "$main_script"
}

# Show WiFi information
show_wifi_info() {
    echo "======================================"
    echo "$(t "status.wifi.header")"
    echo "======================================"
    echo ""

    # Get WiFi interface
    local wifi_interface
    wifi_interface=$(networksetup -listallhardwareports | grep -A 1 "Wi-Fi" | grep "Device:" | awk '{print $2}')

    if [[ -z "$wifi_interface" ]]; then
        print_color "$RED" "$(t "status.wifi.no_interface")"
        return 1
    fi

    print_color "$BLUE" "$(t "status.wifi_interface" "$wifi_interface")"
    echo ""

    # Check if WiFi has IP (most reliable indicator)
    local wifi_ip
    wifi_ip=$(ifconfig "$wifi_interface" 2>/dev/null | grep "inet " | awk '{print $2}')

    if [[ -n "$wifi_ip" ]]; then
        # Try to get SSID
        local current_network
        current_network=$(ipconfig getsummary "$wifi_interface" 2>/dev/null | awk -F' : ' '/SSID/ {print $2; exit}')

        if [[ -z "$current_network" || "$current_network" == *"<redacted>"* || "$current_network" == *"You are not"* ]]; then
            current_network=$(networksetup -getairportnetwork "$wifi_interface" 2>/dev/null | sed 's/Current Wi-Fi Network: //')
        fi

        if [[ -z "$current_network" || "$current_network" == *"<redacted>"* || "$current_network" == *"You are not"* ]]; then
            print_color "$GREEN" "$(t "status.wifi.connected_hidden")"
        else
            print_color "$GREEN" "$(t "status.wifi.connected" "$current_network")"
        fi
        print_color "$BLUE" "$(t "status.wifi_ip" "$wifi_ip")"
    else
        print_color "$YELLOW" "$(t "status.wifi.not_connected")"
    fi

    echo ""

    # Check if WiFi is on
    local wifi_power
    wifi_power=$(networksetup -getairportpower "$wifi_interface" 2>/dev/null)

    if [[ "$wifi_power" == *"On"* ]]; then
        print_color "$GREEN" "$(t "status.wifi.power_on")"
    else
        print_color "$YELLOW" "$(t "status.wifi.power_off")"
    fi

    echo ""

    # Test network connectivity
    print_color "$BLUE" "$(t "status.wifi.testing")"
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
        print_color "$GREEN" "✓ $(t "status.wifi.reachable")"
    else
        print_color "$RED" "✗ $(t "status.wifi.unreachable")"
    fi

    echo ""
}

# Main entry point
main() {
    local command="${1:-show}"

    case "$command" in
        show|logs|"")
            show_logs
            ;;
        status)
            show_status
            ;;
        tail|follow)
            tail_logs
            ;;
        test|check)
            run_test
            ;;
        wifi|info)
            show_wifi_info
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_color "$RED" "$(t "status.unknown_command" "$command")"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
