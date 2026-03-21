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
    echo "错误: 配置文件未找到: $SCRIPT_DIR/config.sh" >&2
    exit 1
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
网络监控状态查询工具

用法: nm-status [命令]

命令:
  (无) | show    - 显示最近 10 条日志
  status          - 显示 launchd 任务状态
  tail            - 实时跟踪日志
  test            - 手动运行网络检测
  wifi            - 显示当前 WiFi 信息
  help            - 显示此帮助信息

示例:
  nm-status              # 显示最近日志
  nm-status show         # 显示最近日志（同上）
  nm-status status       # 显示任务运行状态
  nm-status tail         # 实时查看日志
  nm-status test         # 立即测试网络连接
  nm-status wifi         # 显示 WiFi 信息

EOF
}

# Show recent logs
show_logs() {
    local lines="${1:-10}"

    if [[ ! -f "$LOG_FILE" ]]; then
        print_color "$YELLOW" "日志文件未找到: $LOG_FILE"
        print_color "$YELLOW" "监控可能尚未运行。"
        return 1
    fi

    echo "======================================"
    echo "最近日志条目（最近 $lines 条）"
    echo "======================================"
    echo ""
    tail -n "$lines" "$LOG_FILE" 2>/dev/null || print_color "$YELLOW" "无法读取日志文件。"
    echo ""
}

# Show launchd task status
show_status() {
    echo "======================================"
    echo "Launchd 任务状态"
    echo "======================================"
    echo ""

    local plist_path="$HOME/Library/LaunchAgents/com.network.monitor.plist"

    # Check if plist file exists
    if [[ -f "$plist_path" ]]; then
        print_color "$GREEN" "✓ Launchd plist 已安装: $plist_path"
    else
        print_color "$RED" "✗ Launchd plist 未找到: $plist_path"
        return 1
    fi

    echo ""

    # Check if task is loaded
    if launchctl list | grep -q "com.network.monitor"; then
        print_color "$GREEN" "✓ 任务已加载到 launchctl"
        echo ""
        echo "任务详情:"
        launchctl list | grep "com.network.monitor" || true
    else
        print_color "$YELLOW" "✗ 任务未加载到 launchctl"
        echo "如需加载，请运行: ./install.sh"
    fi

    echo ""

    # Show last run time from log
    if [[ -f "$LOG_FILE" ]]; then
        local last_check
        last_check=$(grep "网络监控检测开始" "$LOG_FILE" 2>/dev/null | tail -1 || echo "")
        if [[ -n "$last_check" ]]; then
            print_color "$BLUE" "上次检测:"
            echo "  $last_check"
        fi
    fi

    echo ""
}

# Tail logs in real-time
tail_logs() {
    if [[ ! -f "$LOG_FILE" ]]; then
        print_color "$YELLOW" "日志文件未找到: $LOG_FILE"
        print_color "$YELLOW" "监控可能尚未运行。"
        return 1
    fi

    echo "======================================"
    echo "实时跟踪日志文件 (Ctrl+C 退出)"
    echo "======================================"
    echo ""
    tail -f "$LOG_FILE"
}

# Run manual test
run_test() {
    echo "======================================"
    echo "运行手动网络检测"
    echo "======================================"
    echo ""

    local main_script="$SCRIPT_DIR/network-monitor.sh"

    if [[ ! -f "$main_script" ]]; then
        print_color "$RED" "错误: 主脚本未找到: $main_script"
        return 1
    fi

    if [[ ! -x "$main_script" ]]; then
        print_color "$YELLOW" "正在设置脚本可执行权限..."
        chmod +x "$main_script"
    fi

    "$main_script"
}

# Show WiFi information
show_wifi_info() {
    echo "======================================"
    echo "当前 WiFi 信息"
    echo "======================================"
    echo ""

    # Get WiFi interface
    local wifi_interface
    wifi_interface=$(networksetup -listallhardwareports | grep -A 1 "Wi-Fi" | grep "Device:" | awk '{print $2}')

    if [[ -z "$wifi_interface" ]]; then
        print_color "$RED" "无法检测到 WiFi 接口"
        return 1
    fi

    print_color "$BLUE" "WiFi 接口: $wifi_interface"
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
            print_color "$GREEN" "已连接 (SSID 已隐藏)"
        else
            print_color "$GREEN" "已连接到: $current_network"
        fi
        print_color "$BLUE" "IP 地址: $wifi_ip"
    else
        print_color "$YELLOW" "未连接到任何 WiFi 网络"
    fi

    echo ""

    # Check if WiFi is on
    local wifi_power
    wifi_power=$(networksetup -getairportpower "$wifi_interface" 2>/dev/null)

    if [[ "$wifi_power" == *"On"* ]]; then
        print_color "$GREEN" "WiFi 电源: 开启"
    else
        print_color "$YELLOW" "WiFi 电源: 关闭"
    fi

    echo ""

    # Test network connectivity
    print_color "$BLUE" "测试网络连接..."
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
        print_color "$GREEN" "✓ 网络可达"
    else
        print_color "$RED" "✗ 网络不可达"
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
            print_color "$RED" "未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
