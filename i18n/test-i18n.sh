#!/bin/bash
# Test script for i18n functionality

set -euo pipefail

# Get script directory (follow symlinks to find real location)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "======================================"
echo "i18n Test Suite"
echo "======================================"
echo ""

# Test 1: Chinese
echo "Test 1: Chinese (zh)"
export LANGUAGE="zh"
source "$PROJECT_ROOT/i18n/i18n.sh"
i18n_init "$PROJECT_ROOT" "zh"
echo "Current language: $(i18n_get_current_lang 2>/dev/null || echo "N/A")"
echo "Test message: $(t "status.monitor_start")"
echo "Formatted: $(t "status.wifi_interface" "en0")"
echo ""

# Test 2: English
echo "Test 2: English (en)"
source "$PROJECT_ROOT/i18n/i18n.sh"
i18n_init "$PROJECT_ROOT" "en"
echo "Current language: $(i18n_get_current_lang 2>/dev/null || echo "N/A")"
echo "Test message: $(t "status.monitor_start")"
echo "Formatted: $(t "status.wifi_interface" "en0")"
echo ""

# Test 3: Auto detection
echo "Test 3: Auto-detection"
source "$PROJECT_ROOT/i18n/i18n.sh"
i18n_init "$PROJECT_ROOT" ""
echo "Detected language: $(i18n_get_current_lang 2>/dev/null || echo "N/A")"
echo "Test message: $(t "status.monitor_start")"
echo ""

# Test 4: Missing key
echo "Test 4: Missing key (fallback)"
source "$PROJECT_ROOT/i18n/i18n.sh"
i18n_init "$PROJECT_ROOT" "en"
echo "Missing key test: $(t "nonexistent.key")"
echo ""

echo "======================================"
echo "All tests completed!"
echo "======================================"
