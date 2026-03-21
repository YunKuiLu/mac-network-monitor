# Network Monitor for macOS

[中文文档](README.CN.md)
|

Automatic network monitoring and WiFi reconnection tool for macOS. Monitors network connectivity every 30 minutes and automatically reconnects to your specified WiFi network when connection is lost.

## Features

- **Automatic Network Monitoring**: Checks network connectivity every 30 minutes
- **Smart WiFi Reconnection**: Automatically reconnects to your specified WiFi when network goes down
- **Retry with Backoff**: Up to 5 retry attempts with increasing delays (0s, 30s, 60s, 120s, 300s)
- **Smart Recovery Detection**: Checks if network recovers during wait periods before reconnecting
- **Targeted WiFi**: Only reconnects to specified network
- **Native macOS Tools**: Uses built-in `networksetup` and `launchd` - no external dependencies
- **CLI Status Tool**: Easy-to-use command `nm-status` for checking logs and status
- **Comprehensive Logging**: All operations logged with timestamps

## Installation

1. Navigate to the project directory:
```bash
cd /Users/luyunkui/project/network-monitor
```

2. Run the install script:
```bash
./install.sh
```

The installer will:
- Make all scripts executable
- Create log directory at `~/.network-monitor/`
- Set appropriate file permissions
- Install the launchd agent for automatic execution
- Create the `nm-status` command symlink

## Configuration

Copy `config.example.sh` to `config.sh` and customize:

```bash
cp config.example.sh config.sh
vim config.sh  # or your preferred editor
```

Edit `config.sh` to customize settings:

```bash
# WiFi Network Configuration
WIFI_SSID="Your_WiFi_SSID"      # Target WiFi network
WIFI_PASSWORD=""                  # Leave empty if already saved

# Network Check Configuration
CHECK_INTERVAL=1800               # 30 minutes in seconds
PING_HOST="8.8.8.8"              # Host for connectivity check
PING_TIMEOUT=3                    # Ping timeout in seconds

# Retry Configuration
MAX_RETRY_COUNT=5                 # Maximum retry attempts
RETRY_DELAYS=(0 30 60 120 300)   # Delays between retries
```

## Usage

### CLI Commands

After installation, use the `nm-status` command from anywhere:

```bash
# Show recent log entries
nm-status

# Show launchd task status
nm-status status

# Follow logs in real-time
nm-status tail

# Run manual network check
nm-status test

# Show current WiFi information
nm-status wifi

# Show help
nm-status help
```

### Manual Execution

You can also run the monitor manually:
```bash
./network-monitor.sh
```

## How It Works

1. **Scheduled Execution**: launchd runs `network-monitor.sh` every 30 minutes
2. **Network Check**: Pings 8.8.8.8 to verify connectivity
3. **WiFi Status**: Records current WiFi connection
4. **Auto-Reconnect**: If network is down:
   - Checks if network recovers during wait periods (smart retry)
   - Turns WiFi off, waits 2 seconds
   - Turns WiFi on, waits 5 seconds
   - Connects to specified WiFi
   - Verifies connectivity
   - Retries up to 5 times with increasing delays if needed

## Smart Retry Strategy

```
Detection: Network Down
  ↓
Retry #1: Immediate (0s delay)
  ├─ Check network → Still down
  ├─ WiFi toggle + reconnect
  └─ Success? → Yes → Exit / No → Continue
Retry #2: After 30 seconds
  ├─ Wait 30s
  ├─ Check network → Recovered! → Exit (no WiFi toggle)
  └─ Still down → WiFi toggle + reconnect
...continues for 5 retries with increasing delays
```

**Key Feature**: Before executing WiFi operations, the script checks if the network has recovered during the wait period. If recovered, it skips the WiFi toggle to avoid disrupting the working connection.

## Log Files

Logs are stored in `~/.network-monitor/`:

- `network-monitor.log` - Main activity log
- `network-monitor.error.log` - Error messages

View logs with:
```bash
nm-status show      # Recent entries
nm-status tail      # Real-time monitoring
tail -f ~/.network-monitor/network-monitor.log
```

## Uninstallation

To completely remove Network Monitor:

```bash
./uninstall.sh
```

This will:
- Unload and remove the launchd agent
- Remove the `nm-status` command symlink
- Preserve log files (manually delete if desired)

## Troubleshooting

### Task not running
```bash
# Check if loaded
launchctl list | grep network.monitor

# Reload if needed
launchctl unload ~/Library/LaunchAgents/com.network.monitor.plist
launchctl load ~/Library/LaunchAgents/com.network.monitor.plist
```

### WiFi not reconnecting
```bash
# Check WiFi interface name
networksetup -listallhardwareports | grep -A 1 "Wi-Fi"

# Test manually
nm-status test

# Check logs for errors
nm-status tail
```

### Permission issues
```bash
# Ensure scripts are executable
chmod +x *.sh

# Fix config permissions (contains password if set)
chmod 600 config.sh
```

## Requirements

- macOS 10.10 or later
- Bash or Zsh shell
- No external dependencies (uses native macOS tools)

## Security Notes

- If `WIFI_PASSWORD` is set in `config.sh`, the file should have restrictive permissions (chmod 600)
- The launchd agent runs with your user permissions (not as root)
- WiFi passwords stored by macOS are used if `WIFI_PASSWORD` is left empty

## File Structure

```
network-monitor/
├── network-monitor.sh         # Main monitoring script
├── config.sh                  # Configuration file (gitignored)
├── config.example.sh          # Configuration template
├── com.network.monitor.plist  # launchd configuration
├── install.sh                 # Installation script
├── uninstall.sh               # Uninstallation script
├── status.sh                  # CLI status tool (nm-status)
├── CLAUDE.md                  # AI assistant guide
├── README.md                  # This file (English)
└── README.CN.md               # Chinese documentation
```

## License

Free to use and modify.
