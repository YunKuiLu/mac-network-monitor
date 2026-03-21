#!/bin/bash
# i18n Core Engine for Network Monitor (Bash 3.2 compatible)
# Provides translation functionality with language auto-detection

set -euo pipefail

# Global variables
I18N_CURRENT_LANG=""

# Detect system language
i18n_detect_system_language() {
    local sys_lang="${LANG:-}"
    local sys_locale="${LC_ALL:-}"

    # Check both LANG and LC_ALL
    for lang_var in "$sys_locale" "$sys_lang"; do
        if [[ "$lang_var" =~ ^zh_CN ]] || [[ "$lang_var" =~ ^zh- ]] || [[ "$lang_var" =~ ^zh\. ]]; then
            echo "zh"
            return 0
        elif [[ "$lang_var" =~ ^zh ]] && [[ ! "$lang_var" =~ ^zh_TW ]] && [[ ! "$lang_var" =~ ^zh_HK ]]; then
            echo "zh"
            return 0
        elif [[ "$lang_var" =~ ^en ]] || [[ "$lang_var" =~ ^en- ]]; then
            echo "en"
            return 0
        fi
    done

    # Default to Chinese for this project
    echo "zh"
    return 0
}

# Initialize i18n system
i18n_init() {
    local script_dir="$1"
    local config_lang="${2:-}"

    # Determine language: config > system detection > default
    local target_lang
    if [[ -n "$config_lang" ]]; then
        target_lang="$config_lang"
    else
        target_lang=$(i18n_detect_system_language)
    fi

    # Validate and set language
    if [[ "$target_lang" != "zh" && "$target_lang" != "en" ]]; then
        echo "Warning: Unsupported language '$target_lang', falling back to 'zh'" >&2
        target_lang="zh"
    fi

    I18N_CURRENT_LANG="$target_lang"

    # Load the appropriate language file
    local lang_file="$script_dir/i18n/locales/$target_lang.sh"
    if [[ -f "$lang_file" ]]; then
        source "$lang_file"
    else
        echo "Warning: Language file not found: $lang_file" >&2
    fi
}

# Translation function (main API)
t() {
    local key="$1"
    shift

    # Call the language-specific translate function
    if type translate &>/dev/null; then
        translate "$key" "$@"
    else
        # Fallback: return the key itself
        echo "[TRANSLATION MISSING: $key]"
    fi
}

# Get current language
i18n_get_current_lang() {
    echo "$I18N_CURRENT_LANG"
}
