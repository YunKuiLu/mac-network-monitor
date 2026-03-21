# Internationalization (i18n) Guide

This directory contains the internationalization system for the network monitor tool.

## Architecture

```
i18n/
├── i18n.sh              # Core i18n engine
├── locales/
│   ├── en.sh           # English translations
│   └── zh.sh           # Chinese (Simplified) translations
└── test-i18n.sh        # Unit tests
```

## How It Works

### 1. Language Detection

The system detects language in this order:
1. `LANGUAGE` variable in `config.sh` (highest priority)
2. `LC_ALL` environment variable
3. `LANG` environment variable
4. Default: Chinese (zh)

### 2. Translation Function

All scripts use the `t()` function to translate messages:

```bash
# Simple translation
t "status.monitor_start"
# Output: === Network Monitor Check Started ===

# Translation with parameters
t "status.wifi_interface" "en0"
# Output: WiFi Interface: en0
```

### 3. Language Files

Each language file defines a `translate()` function:

```bash
translate() {
    local key="$1"
    shift

    case "$key" in
        "status.monitor_start")
            echo "=== Network Monitor Check Started ==="
            ;;
        "status.wifi_interface")
            printf "WiFi Interface: %s" "$1"
            ;;
        # ... more translations
    esac
}
```

## Adding a New Language

### Step 1: Create Language File

Create `i18n/locales/xx.sh` (replace `xx` with your language code):

```bash
#!/bin/bash
# Language Pack (Language Name)

translate() {
    local key="$1"
    shift

    case "$key" in
        # Copy all keys from en.sh or zh.sh
        # Translate the values
        "status.monitor_start")
            echo "=== Translation Here ==="
            ;;
        # ... all other keys
    esac
}
```

### Step 2: Copy All Keys

**Important**: Your language file must have the exact same keys as `en.sh` and `zh.sh`.

Use this command to check for missing keys:

```bash
# Extract keys from English
grep -E '^\s+"[^"]+"\)' i18n/locales/en.sh | sed 's/^[[:space:]]*//;s/")[[:space:]]*$//' > /tmp/en_keys.txt

# Extract keys from your language
grep -E '^\s+"[^"]+"\)' i18n/locales/xx.sh | sed 's/^[[:space:]]*//;s/")[[:space:]]*$//' > /tmp/xx_keys.txt

# Find missing keys
diff /tmp/en_keys.txt /tmp/xx_keys.txt
```

### Step 3: Test Your Translation

```bash
# Test your language
LANGUAGE="xx" ./status.sh help

# Run verification
./verify-i18n.sh
```

## Translation Key Naming

Use this pattern for new keys:

```
<category>.<subcategory>.<action>

Examples:
- status.monitor_start      - Status messages
- wifi.turning_on          - WiFi operations
- network.normal           - Network status
- install.complete         - Installation messages
- log.INFO                 - Log levels
```

## Translation Best Practices

### DO ✅

1. **Keep parameter placeholders** consistent:
   ```bash
   # English
   printf "Connecting to: %s" "$1"

   # Chinese
   printf "正在连接：%s" "$1"
   ```

2. **Use echo for simple strings**:
   ```bash
   echo "Network is down"
   ```

3. **Use printf for formatted strings**:
   ```bash
   printf "Retry #%d: Waiting %ds" "$1" "$2"
   ```

4. **Maintain same keys across all languages**

### DON'T ❌

1. **Don't change key names** between languages
2. **Don't add/remove parameters** without updating all languages
3. **Don't use language-specific formatting** that can't be translated
4. **Don't forget to test** with `./verify-i18n.sh`

## Testing

### Unit Tests

```bash
cd i18n
./test-i18n.sh
```

### Integration Tests

```bash
# Test all supported languages
for lang in zh en; do
    echo "Testing $lang:"
    LANGUAGE="$lang" ./status.sh help
    echo ""
done
```

### Comprehensive Verification

```bash
./verify-i18n.sh
```

## Troubleshooting

### Translation Not Working

1. Check if `LANGUAGE` is set in `config.sh`
2. Verify language file exists: `ls i18n/locales/`
3. Check for syntax errors: `bash -n i18n/locales/xx.sh`
4. Test manually: `source i18n/i18n.sh && i18n_init . "xx"`

### Missing Translation Keys

If you see `[TRANSLATION MISSING: key]`:

1. Check if the key exists in your language file
2. Verify exact spelling (case-sensitive)
3. Run `./verify-i18n.sh` to check coverage

### Character Encoding Issues

All files must use UTF-8 encoding:

```bash
# Check file encoding
file -I i18n/locales/xx.sh

# Convert to UTF-8 if needed
iconv -f ISO-8859-1 -t UTF-8 input.sh > i18n/locales/xx.sh
```

## Contributing

When contributing translations:

1. Fork the repository
2. Create a new branch: `git checkout -b i18n-xx`
3. Add your language file
4. Update `README.md` and `README.CN.md`
5. Test thoroughly with `./verify-i18n.sh`
6. Submit a pull request

## Statistics

Current translation coverage:
- **Keys**: 89 translation keys
- **Languages**: 2 (zh, en)
- **Coverage**: 100% for all supported languages

## Contact

For questions or issues with translations, please open an issue on GitHub.
