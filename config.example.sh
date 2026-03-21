#!/bin/bash
# Network Monitor Configuration File
# Edit these parameters according to your needs

# WiFi Network Configuration
WIFI_SSID="Your_WiFi_SSID"
WIFI_PASSWORD=""  # Leave empty if macOS already has the password saved

# Network Check Configuration
CHECK_INTERVAL=1800  # Check interval in seconds (default: 1800 = 30 minutes)
PING_HOST="8.8.8.8"  # Host to ping for network connectivity check
PING_TIMEOUT=3       # Ping timeout in seconds
PING_COUNT=1         # Number of ping packets to send

# Retry Configuration
MAX_RETRY_COUNT=5    # Maximum number of reconnection attempts
# Retry delays in seconds (immediate, 30s, 60s, 120s, 300s)
RETRY_DELAYS=(0 30 60 120 300)

# WiFi Operation Delays
WIFI_OFF_DELAY=2     # Seconds to wait after turning WiFi off
WIFI_ON_DELAY=5      # Seconds to wait after turning WiFi on before connecting

# Log Configuration
LOG_DIR="$HOME/.network-monitor"
LOG_FILE="$LOG_DIR/network-monitor.log"
ERROR_LOG_FILE="$LOG_DIR/network-monitor.error.log"

# Script Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/network-monitor.sh"
