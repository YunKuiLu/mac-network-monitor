#!/bin/bash
# English Language Pack

translate() {
    local key="$1"
    shift

    case "$key" in
        # Config errors
        "err.config.not_found")
            printf "Error: Configuration file not found: %s" "$1"
            ;;

        # General messages
        "msg.making_executable")
            echo "Making scripts executable..."
            ;;
        "msg.creating_log_dir")
            printf "Creating log directory at: %s" "$1"
            ;;
        "msg.setting_permissions")
            echo "Setting config file permissions..."
            ;;

        # WiFi operations
        "wifi.turning_off")
            echo "Turning WiFi off..."
            ;;
        "wifi.turning_on")
            echo "Turning WiFi on..."
            ;;
        "wifi.connecting")
            printf "Attempting to connect to WiFi: %s" "$1"
            ;;
        "wifi.connected")
            printf "Connected to %s" "$1"
            ;;
        "wifi.not_connected")
            echo "Not connected"
            ;;
        "wifi.ssid_hidden")
            echo "Connected (SSID hidden)"
            ;;

        # Network monitoring
        "network.checking")
            echo "Checking network connectivity..."
            ;;
        "network.normal")
            echo "Network connection is normal."
            ;;
        "network.down")
            printf "Network disconnected. Current WiFi: %s. Starting reconnection..." "${1:-none}"
            ;;
        "network.recovered")
            echo "Network has recovered on its own. Skipping reconnection."
            ;;
        "network.retry_waiting")
            printf "Retry #%d: Waiting %d seconds before attempting..." "$1" "$2"
            ;;
        "network.retry_immediate")
            printf "Retry #%d: Attempting immediately..." "$1"
            ;;
        "network.retry_success")
            printf "Successfully connected to WiFi (IP: %s), network is working!" "$1"
            ;;
        "network.retry_wifi_no_ip")
            echo "WiFi connection failed (no IP address). Will retry..."
            ;;
        "network.retry_ip_no_network")
            printf "WiFi connected (IP: %s) but no network access. Will retry..." "$1"
            ;;
        "network.retry_failed")
            printf "Reconnection failed after %d attempts. Will try again on next scheduled check." "$1"
            ;;

        # Status messages
        "status.monitor_start")
            echo "=== Network Monitor Check Started ==="
            ;;
        "status.monitor_end")
            echo "=== Network Monitor Check Completed ==="
            ;;
        "status.wifi_interface")
            printf "WiFi Interface: %s" "$1"
            ;;
        "status.current_wifi")
            printf "Current WiFi: %s" "$1"
            ;;
        "status.wifi_ip")
            printf "WiFi IP Address: %s" "$1"
            ;;
        "status.no_wifi_interface")
            echo "Unable to detect WiFi interface. Terminating."
            ;;

        # Install script
        "install.title")
            echo "Network Monitor Installation"
            ;;
        "install.not_root")
            echo "ERROR: This script should not be run as root. Run as your regular user."
            ;;
        "install.installing_plist")
            printf "Installing launchd agent to: %s" "$1"
            ;;
        "install.loading_launchd")
            echo "Loading launchd agent..."
            ;;
        "install.warning.load_failed")
            printf "WARNING: Failed to load launchd agent. You may need to run:\n  launchctl load '%s'" "$1"
            ;;
        "install.creating_symlink")
            printf "Creating CLI symlink: %s -> %s" "$1" "$2"
            ;;
        "install.removing_existing_symlink")
            printf "Removing existing symlink at %s" "$1"
            ;;
        "install.warning.symlink_failed")
            printf "WARNING: Could not create symlink at %s\nYou may need to run with sudo or create it manually:\n  sudo ln -s '%s' %s" "$1" "$2" "$3"
            ;;
        "install.complete")
            echo "Installation Complete!"
            ;;
        "install.info.running")
            echo "Network Monitor is now running and will check every 30 minutes."
            ;;
        "install.info.commands")
            echo "Available Commands:"
            ;;

        # Uninstall script
        "uninstall.title")
            echo "Network Monitor Uninstallation"
            ;;
        "uninstall.unloading")
            echo "Unloading launchd agent..."
            ;;
        "uninstall.warning.unload_failed")
            echo "WARNING: Failed to unload via launchctl. Trying bootout..."
            ;;
        "uninstall.not_loaded")
            echo "Launchd agent not currently loaded."
            ;;
        "uninstall.removing_plist")
            printf "Removing launchd plist file: %s" "$1"
            ;;
        "uninstall.plist_not_found")
            printf "Launchd plist file not found: %s" "$1"
            ;;
        "uninstall.removing_symlink")
            printf "Removing CLI symlink: %s" "$1"
            ;;
        "uninstall.warning.symlink_remove_failed")
            printf "WARNING: Could not remove symlink. You may need sudo:\n  sudo rm '%s'" "$1"
            ;;
        "uninstall.symlink_not_symlink")
            printf "WARNING: %s exists but is not a symlink. Not removing." "$1"
            ;;
        "uninstall.symlink_not_found")
            printf "CLI symlink not found: %s" "$1"
            ;;
        "uninstall.logs_preserved")
            printf "Log files are preserved at: %s\nIf you want to remove them, run:\n  rm -rf '%s'" "$1" "$2"
            ;;
        "uninstall.complete")
            echo "Uninstallation Complete!"
            ;;
        "uninstall.info")
            echo "The network monitor has been uninstalled.\nYour configuration and log files have been preserved."
            ;;

        # Status tool
        "status.tool.name")
            echo "Network Monitor Status Tool"
            ;;
        "status.tool.usage")
            echo "Usage: nm-status [command]"
            ;;
        "status.tool.commands")
            echo "Commands:"
            ;;
        "status.cmd.show")
            echo "(none) | show    - Show recent 10 log entries"
            ;;
        "status.cmd.status")
            echo "status          - Show launchd task status"
            ;;
        "status.cmd.tail")
            echo "tail            - Follow log in real-time"
            ;;
        "status.cmd.test")
            echo "test            - Run manual network check"
            ;;
        "status.cmd.wifi")
            echo "wifi            - Show current WiFi info"
            ;;
        "status.cmd.help")
            echo "help            - Show this help message"
            ;;
        "status.tool.examples")
            echo "Examples:"
            ;;
        "status.logs.not_found")
            printf "Log file not found: %s" "$1"
            ;;
        "status.logs.not_running")
            echo "Monitor may not be running yet."
            ;;
        "status.logs.header")
            printf "Recent Log Entries (Last %d)" "$1"
            ;;
        "status.logs.realtime")
            echo "Real-time Log Following (Ctrl+C to exit)"
            ;;
        "status.launchd.header")
            echo "Launchd Task Status"
            ;;
        "status.launchd.plist_installed")
            printf "Launchd plist installed: %s" "$1"
            ;;
        "status.launchd.plist_not_found")
            printf "Launchd plist not found: %s" "$1"
            ;;
        "status.launchd.loaded")
            echo "Task is loaded in launchctl"
            ;;
        "status.launchd.not_loaded")
            echo "Task is not loaded in launchctl"
            ;;
        "status.launchd.load_hint")
            echo "To load, run: ./install.sh"
            ;;
        "status.launchd.details")
            echo "Task Details:"
            ;;
        "status.launchd.last_check")
            echo "Last Check:"
            ;;
        "status.test.header")
            echo "Running Manual Network Check"
            ;;
        "status.test.script_not_found")
            printf "Error: Main script not found: %s" "$1"
            ;;
        "status.test.setting_permissions")
            echo "Setting script executable permissions..."
            ;;
        "status.wifi.header")
            echo "Current WiFi Information"
            ;;
        "status.wifi.no_interface")
            echo "Unable to detect WiFi interface"
            ;;
        "status.wifi.connected")
            printf "Connected to: %s" "$1"
            ;;
        "status.wifi.connected_hidden")
            echo "Connected (SSID hidden)"
            ;;
        "status.wifi.not_connected")
            echo "Not connected to any WiFi network"
            ;;
        "status.wifi.power_on")
            echo "WiFi Power: On"
            ;;
        "status.wifi.power_off")
            echo "WiFi Power: Off"
            ;;
        "status.wifi.testing")
            echo "Testing network connection..."
            ;;
        "status.wifi.reachable")
            echo "Network is reachable"
            ;;
        "status.wifi.unreachable")
            echo "Network is unreachable"
            ;;
        "status.unknown_command")
            printf "Unknown command: %s" "$1"
            ;;

        # Log levels
        "log.INFO")
            echo "INFO"
            ;;
        "log.WARN")
            echo "WARN"
            ;;
        "log.ERROR")
            echo "ERROR"
            ;;

        *)
            echo "[TRANSLATION MISSING: $key]"
            ;;
    esac
}
