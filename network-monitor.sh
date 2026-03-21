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
    echo "错误: 配置文件未找到: $SCRIPT_DIR/config.sh" >&2
    exit 1
fi

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
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
            echo "已连接 (SSID 已隐藏)"
        else
            echo "$wifi_name"
        fi
    else
        # No IP = not connected
        echo "未连接"
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
    log "INFO" "正在关闭 WiFi..."
    networksetup -setairportpower "$wifi_interface" off
    sleep "$WIFI_OFF_DELAY"
}

# Turn WiFi on
wifi_on() {
    local wifi_interface="$1"
    log "INFO" "正在打开 WiFi..."
    networksetup -setairportpower "$wifi_interface" on
    sleep "$WIFI_ON_DELAY"
}

# Connect to specified WiFi
connect_wifi() {
    local wifi_interface="$1"
    local ssid="$2"
    local password="${3:-}"

    log "INFO" "尝试连接 WiFi: $ssid"

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

    log "WARN" "网络已断开。当前 WiFi: ${current_wifi:-无}。开始重新连接..."

    local retry_count=0
    local success=false

    while [[ $retry_count -lt $MAX_RETRY_COUNT ]]; do
        ((retry_count++)) || true

        # Get delay for this retry
        local retry_delay="${RETRY_DELAYS[$((retry_count - 1))]:-0}"

        if [[ $retry_delay -gt 0 ]]; then
            log "INFO" "重试 #$retry_count: 等待 ${retry_delay}秒 后尝试..."
            sleep "$retry_delay"
        else
            log "INFO" "重试 #$retry_count: 立即尝试..."
        fi

        # 先检测网络是否已恢复（避免在等待期间网络已恢复时执行不必要的重连操作）
        if check_network; then
            log "INFO" "网络已自行恢复，无需重连。退出重试流程。"
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
                log "INFO" "成功连接到 WiFi (IP: $wifi_ip)，网络正常！"
                success=true
                break
            else
                log "WARN" "WiFi 已连接 (IP: $wifi_ip) 但无法访问网络。将重试..."
            fi
        else
            log "WARN" "WiFi 连接失败（未获取到 IP 地址）。将重试..."
        fi
    done

    if [[ "$success" == false ]]; then
        log "ERROR" "重连失败，已尝试 $MAX_RETRY_COUNT 次。将在下次定时检测时再试。"
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
        log "ERROR" "无法检测到 WiFi 接口。终止执行。"
        exit 1
    fi

    log "INFO" "=== 网络监控检测开始 ==="
    log "INFO" "WiFi 接口: $wifi_interface"

    # Get current WiFi network
    local current_wifi
    current_wifi=$(get_current_wifi "$wifi_interface")
    log "INFO" "当前 WiFi: ${current_wifi}"

    # Show WiFi IP if available
    local wifi_ip
    if wifi_ip=$(check_wifi_connected "$wifi_interface"); then
        log "INFO" "WiFi IP 地址: $wifi_ip"
    fi

    # Check network connectivity
    if check_network; then
        log "INFO" "网络连接正常。"
    else
        # Double-check network connectivity to avoid false positives
        sleep 2
        if check_network; then
            log "INFO" "网络连接正常（二次确认）。"
        else
            # Network is down, attempt to reconnect
            reconnect_wifi "$wifi_interface" "$current_wifi"
        fi
    fi

    log "INFO" "=== 网络监控检测完成 ==="
    echo "" >> "$LOG_FILE"
}

# Run main function
main "$@"
