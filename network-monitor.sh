#!/bin/bash
# Network Monitor Script
# Automatically detects network status and reconnects to specified WiFi if needed

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

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level="$1"
    local key="$2"
    shift 2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Translate the message
    local message
    if [[ $# -eq 0 ]]; then
        if type t &>/dev/null; then
            message="$(t "$key")"
        else
            message="$key"
        fi
    else
        if type t &>/dev/null; then
            message="$(t "$key" "$@")"
        else
            message="$key"
        fi
    fi

    # Translate log level
    local level_text
    if type t &>/dev/null; then
        level_text="$(t "log.$level")"
    else
        level_text="$level"
    fi

    echo "[$timestamp] [$level_text] $message" | tee -a "$LOG_FILE"
}

# Get WiFi interface name
get_wifi_interface() {
    networksetup -listallhardwareports | grep -A 1 "Wi-Fi" | grep "Device:" | awk '{print $2}'
}

# Check if WiFi interface has IP address (connected)
check_wifi_connected() {
    local wifi_interface="$1"
    local ip_addr
    ip_addr=$(ifconfig "$wifi_interface" 2>/dev/null | grep "inet " | awk '{print $2}')

    if [[ -n "$ip_addr" ]]; then
        echo "$ip_addr"
        return 0
    else
        return 1
    fi
}

# Get current WiFi network name (may be hidden by macOS)
get_current_wifi() {
    local wifi_interface="$1"
    local wifi_name

    # First check if WiFi has IP (most reliable connection indicator)
    if check_wifi_connected "$wifi_interface" >/dev/null 2>&1; then
        # Try to get actual SSID
        wifi_name=$(ipconfig getsummary "$wifi_interface" 2>/dev/null | awk -F' : ' '/SSID/ {print $2; exit}')

        if [[ -z "$wifi_name" || "$wifi_name" == *"<redacted>"* ]]; then
            # Try networksetup as fallback
            wifi_name=$(networksetup -getairportnetwork "$wifi_interface" 2>/dev/null | sed 's/Current Wi-Fi Network: //')
        fi

        # If SSID is hidden or unavailable
        if [[ -z "$wifi_name" || "$wifi_name" == *"<redacted>"* || "$wifi_name" == *"You are not"* ]]; then
            if type t &>/dev/null; then
                echo "$(t "wifi.ssid_hidden")"
            else
                echo "已连接 (SSID 已隐藏)"
            fi
        else
            echo "$wifi_name"
        fi
    else
        # No IP = not connected
        if type t &>/dev/null; then
            echo "$(t "wifi.not_connected")"
        else
            echo "未连接"
        fi
    fi
}

# Check network connectivity
check_network() {
    local ping_output
    if ping_output=$(ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$PING_HOST" 2>&1); then
        return 0
    else
        return 1
    fi
}

# Turn WiFi off
wifi_off() {
    local wifi_interface="$1"
    log "INFO" "wifi.turning_off"
    networksetup -setairportpower "$wifi_interface" off
    sleep "$WIFI_OFF_DELAY"
}

# Turn WiFi on
wifi_on() {
    local wifi_interface="$1"
    log "INFO" "wifi.turning_on"
    networksetup -setairportpower "$wifi_interface" on
    sleep "$WIFI_ON_DELAY"
}

# Connect to specified WiFi
connect_wifi() {
    local wifi_interface="$1"
    local ssid="$2"
    local password="${3:-}"

    log "INFO" "wifi.connecting" "$ssid"

    # Suppress error output - macOS may report errors even when connection succeeds
    # We'll verify connection status afterwards instead
    if [[ -n "$password" ]]; then
        networksetup -setairportnetwork "$wifi_interface" "$ssid" "$password" >/dev/null 2>&1
    else
        networksetup -setairportnetwork "$wifi_interface" "$ssid" >/dev/null 2>&1
    fi
}

# Reconnect to WiFi with retry logic
reconnect_wifi() {
    local wifi_interface="$1"
    local current_wifi="$2"

    log "WARN" "network.down" "${current_wifi:-$(t "wifi.not_connected")}"

    local retry_count=0
    local success=false

    while [[ $retry_count -lt $MAX_RETRY_COUNT ]]; do
        ((retry_count++)) || true

        # Get delay for this retry
        local retry_delay="${RETRY_DELAYS[$((retry_count - 1))]:-0}"

        if [[ $retry_delay -gt 0 ]]; then
            log "INFO" "network.retry_waiting" "$retry_count" "$retry_delay"
            sleep "$retry_delay"
        else
            log "INFO" "network.retry_immediate" "$retry_count"
        fi

        # 先检测网络是否已恢复（避免在等待期间网络已恢复时执行不必要的重连操作）
        if check_network; then
            log "INFO" "network.recovered"
            success=true
            break
        fi

        # 网络仍未恢复，执行重连操作
        # Turn WiFi off and on
        wifi_off "$wifi_interface"
        wifi_on "$wifi_interface"

        # Attempt to connect to specified WiFi only
        connect_wifi "$wifi_interface" "$WIFI_SSID" "$WIFI_PASSWORD"

        # Wait for connection to establish
        sleep 5

        # Check if WiFi has IP address (more reliable than checking SSID)
        local wifi_ip
        if wifi_ip=$(check_wifi_connected "$wifi_interface"); then
            # Verify network connectivity
            if check_network; then
                log "INFO" "network.retry_success" "$wifi_ip"
                success=true
                break
            else
                log "WARN" "network.retry_ip_no_network" "$wifi_ip"
            fi
        else
            log "WARN" "network.retry_wifi_no_ip"
        fi
    done

    if [[ "$success" == false ]]; then
        log "ERROR" "network.retry_failed" "$MAX_RETRY_COUNT"
        return 1
    fi

    return 0
}

# Main function
main() {
    # Get WiFi interface
    local wifi_interface
    wifi_interface=$(get_wifi_interface)

    if [[ -z "$wifi_interface" ]]; then
        log "ERROR" "status.no_wifi_interface"
        exit 1
    fi

    log "INFO" "status.monitor_start"
    log "INFO" "status.wifi_interface" "$wifi_interface"

    # Get current WiFi network
    local current_wifi
    current_wifi=$(get_current_wifi "$wifi_interface")
    log "INFO" "status.current_wifi" "${current_wifi}"

    # Show WiFi IP if available
    local wifi_ip
    if wifi_ip=$(check_wifi_connected "$wifi_interface"); then
        log "INFO" "status.wifi_ip" "$wifi_ip"
    fi

    # Check network connectivity
    if check_network; then
        log "INFO" "network.normal"
    else
        # Double-check network connectivity to avoid false positives
        sleep 2
        if check_network; then
            log "INFO" "network.normal"
        else
            # Network is down, attempt to reconnect
            reconnect_wifi "$wifi_interface" "$current_wifi"
        fi
    fi

    log "INFO" "status.monitor_end"
    echo "" >> "$LOG_FILE"
}

# Run main function
main "$@"
