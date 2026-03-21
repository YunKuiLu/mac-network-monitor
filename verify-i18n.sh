#!/bin/bash
# i18n Verification Script
# Tests all aspects of internationalization functionality

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Helper function to print test result
print_result() {
    local test_name="$1"
    local result="$2"
    local message="${3:-}"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}✓ PASS${NC} - $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC} - $test_name"
        if [[ -n "$message" ]]; then
            echo -e "  ${YELLOW}→${NC} $message"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Get project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo "i18n Verification Suite"
echo "======================================"
echo ""

# ============================================================================
# Test 1: Check i18n files exist
# ============================================================================
echo "Test Group 1: File Existence"
echo "----------------------------"

FILES_TO_CHECK=(
    "$SCRIPT_DIR/i18n/i18n.sh"
    "$SCRIPT_DIR/i18n/locales/zh.sh"
    "$SCRIPT_DIR/i18n/locales/en.sh"
)

for file in "${FILES_TO_CHECK[@]}"; do
    if [[ -f "$file" ]]; then
        print_result "File exists: $(basename "$file")" "PASS"
    else
        print_result "File exists: $(basename "$file")" "FAIL" "File not found"
    fi
done
echo ""

# ============================================================================
# Test 2: Test basic translation functionality
# ============================================================================
echo "Test Group 2: Basic Translation"
echo "----------------------------"

# Test Chinese
source "$SCRIPT_DIR/i18n/i18n.sh"
i18n_init "$SCRIPT_DIR" "zh"
zh_output=$(t "status.monitor_start")
if [[ "$zh_output" == *"网络监控检测开始"* ]]; then
    print_result "Chinese translation works" "PASS"
else
    print_result "Chinese translation works" "FAIL" "Got: $zh_output"
fi

# Test English
i18n_init "$SCRIPT_DIR" "en"
en_output=$(t "status.monitor_start")
if [[ "$en_output" == *"Network Monitor Check Started"* ]]; then
    print_result "English translation works" "PASS"
else
    print_result "English translation works" "FAIL" "Got: $en_output"
fi

# Test formatted translation
formatted_output=$(t "status.wifi_interface" "en0")
if [[ "$formatted_output" == *"en0"* ]]; then
    print_result "Formatted translation works" "PASS"
else
    print_result "Formatted translation works" "FAIL" "Got: $formatted_output"
fi

# Test missing key fallback
missing_output=$(t "nonexistent.key")
if [[ "$missing_output" == *"TRANSLATION MISSING"* ]]; then
    print_result "Missing key fallback works" "PASS"
else
    print_result "Missing key fallback works" "FAIL" "Got: $missing_output"
fi
echo ""

# ============================================================================
# Test 3: Language detection
# ============================================================================
echo "Test Group 3: Language Detection"
echo "----------------------------"

# Save current LANG
ORIGINAL_LANG="$LANG"

# Test with Chinese locale
LANG="zh_CN.UTF-8"
detected=$(i18n_detect_system_language)
if [[ "$detected" == "zh" ]]; then
    print_result "Detects Chinese locale" "PASS"
else
    print_result "Detects Chinese locale" "FAIL" "Got: $detected"
fi

# Test with English locale
LANG="en_US.UTF-8"
detected=$(i18n_detect_system_language)
if [[ "$detected" == "en" ]]; then
    print_result "Detects English locale" "PASS"
else
    print_result "Detects English locale" "FAIL" "Got: $detected"
fi

# Test with unknown locale (should default to zh)
LANG="fr_FR.UTF-8"
detected=$(i18n_detect_system_language)
if [[ "$detected" == "zh" ]]; then
    print_result "Defaults to Chinese for unknown locale" "PASS"
else
    print_result "Defaults to Chinese for unknown locale" "FAIL" "Got: $detected"
fi

# Restore original LANG
LANG="$ORIGINAL_LANG"
echo ""

# ============================================================================
# Test 4: Integration with main scripts
# ============================================================================
echo "Test Group 4: Script Integration"
echo "----------------------------"

# Test network-monitor.sh (dry run - just check it loads)
if grep -q "i18n/i18n.sh" "$SCRIPT_DIR/network-monitor.sh"; then
    print_result "network-monitor.sh loads i18n" "PASS"
else
    print_result "network-monitor.sh loads i18n" "FAIL" "i18n not found in script"
fi

if grep -q 'i18n_init' "$SCRIPT_DIR/network-monitor.sh"; then
    print_result "network-monitor.sh calls i18n_init" "PASS"
else
    print_result "network-monitor.sh calls i18n_init" "FAIL" "i18n_init not found"
fi

# Test status.sh
if grep -q "i18n/i18n.sh" "$SCRIPT_DIR/status.sh"; then
    print_result "status.sh loads i18n" "PASS"
else
    print_result "status.sh loads i18n" "FAIL" "i18n not found in script"
fi

# Test install.sh
if grep -q "i18n/i18n.sh" "$SCRIPT_DIR/install.sh"; then
    print_result "install.sh loads i18n" "PASS"
else
    print_result "install.sh loads i18n" "FAIL" "i18n not found in script"
fi

# Test uninstall.sh
if grep -q "i18n/i18n.sh" "$SCRIPT_DIR/uninstall.sh"; then
    print_result "uninstall.sh loads i18n" "PASS"
else
    print_result "uninstall.sh loads i18n" "FAIL" "i18n not found"
fi
echo ""

# ============================================================================
# Test 5: Config file integration
# ============================================================================
echo "Test Group 5: Configuration"
echo "----------------------------"

if grep -q 'LANGUAGE=' "$SCRIPT_DIR/config.example.sh"; then
    print_result "config.example.sh has LANGUAGE variable" "PASS"
else
    print_result "config.example.sh has LANGUAGE variable" "FAIL" "LANGUAGE not found"
fi

# Check LANGUAGE documentation
if grep -q '# Language Configuration' "$SCRIPT_DIR/config.example.sh"; then
    print_result "LANGUAGE is documented in config.example.sh" "PASS"
else
    print_result "LANGUAGE is documented in config.example.sh" "FAIL" "Documentation not found"
fi
echo ""

# ============================================================================
# Test 6: Translation coverage check
# ============================================================================
echo "Test Group 6: Translation Coverage"
echo "----------------------------"

# Extract keys from both language files
zh_keys=$(grep -E '^\s+"[^"]+"\)' "$SCRIPT_DIR/i18n/locales/zh.sh" | wc -l | tr -d ' ')
en_keys=$(grep -E '^\s+"[^"]+"\)' "$SCRIPT_DIR/i18n/locales/en.sh" | wc -l | tr -d ' ')

echo "  Chinese keys: $zh_keys"
echo "  English keys: $en_keys"

if [[ "$zh_keys" -eq "$en_keys" ]]; then
    print_result "Both language files have same number of keys" "PASS" "Each has $zh_keys keys"
else
    print_result "Both language files have same number of keys" "FAIL" "zh: $zh_keys, en: $en_keys"
fi

# Check for minimum required keys
REQUIRED_KEYS=(
    "status.monitor_start"
    "status.monitor_end"
    "wifi.turning_on"
    "wifi.turning_off"
    "network.normal"
    "log.INFO"
    "log.WARN"
    "log.ERROR"
)

all_keys_found=true
for key in "${REQUIRED_KEYS[@]}"; do
    if ! grep -q "\"$key\"" "$SCRIPT_DIR/i18n/locales/en.sh"; then
        print_result "Required key exists: $key" "FAIL" "Not found in en.sh"
        all_keys_found=false
    fi
done

if $all_keys_found; then
    print_result "All required translation keys exist" "PASS"
fi
echo ""

# ============================================================================
# Test 7: Practical usage test
# ============================================================================
echo "Test Group 7: Practical Usage"
echo "----------------------------"

echo -e "${BLUE}Testing Chinese output:${NC}"
LANGUAGE="zh" bash -c "
    source '$SCRIPT_DIR/i18n/i18n.sh'
    i18n_init '$SCRIPT_DIR' 'zh'
    echo '  Monitor start: '\$(t 'status.monitor_start')
    echo '  WiFi interface: '\$(t 'status.wifi_interface' 'en0')
"
echo ""

echo -e "${BLUE}Testing English output:${NC}"
LANGUAGE="en" bash -c "
    source '$SCRIPT_DIR/i18n/i18n.sh'
    i18n_init '$SCRIPT_DIR' 'en'
    echo '  Monitor start: '\$(t 'status.monitor_start')
    echo '  WiFi interface: '\$(t 'status.wifi_interface' 'en0')
"
echo ""

# ============================================================================
# Summary
# ============================================================================
echo "======================================"
echo "Test Summary"
echo "======================================"
echo -e "Total Tests: $TESTS_TOTAL"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo -e "${GREEN}✓ i18n is working correctly!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo -e "${YELLOW}Please review the failures above${NC}"
    exit 1
fi
