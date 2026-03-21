# macOS 网络监控工具

[English](README.md)
|

macOS 自动网络监控和 WiFi 重连工具。每 30 分钟检查一次网络连接，网络断开时自动重连到指定的 WiFi 网络。

## 功能特性

- **自动网络监控**: 每 30 分钟检查一次网络连接
- **智能 WiFi 重连**: 网络断开时自动重连到指定 WiFi
- **退避重试**: 最多 5 次重试，延迟递增 (0s, 30s, 60s, 120s, 300s)
- **智能恢复检测**: 在等待期间检测网络是否已恢复，避免不必要的重连
- **指定 WiFi**: 只重连到指定网络
- **原生 macOS 工具**: 使用内置 `networksetup` 和 `launchd` - 无需额外依赖
- **命令行状态工具**: 使用 `nm-status` 命令查看日志和状态
- **完整日志**: 所有操作都有时间戳记录

## 安装

1. 进入项目目录:
```bash
cd /Users/luyunkui/project/network-monitor
```

2. 运行安装脚本:
```bash
./install.sh
```

安装程序将:
- 设置脚本可执行权限
- 创建日志目录 `~/.network-monitor/`
- 设置适当的文件权限
- 安装 launchd 代理以自动执行
- 创建 `nm-status` 命令链接

## 配置

复制 `config.example.sh` 为 `config.sh` 并自定义:

```bash
cp config.example.sh config.sh
vim config.sh  # 或使用其他编辑器
```

编辑 `config.sh` 自定义设置:

```bash
# WiFi 网络配置
WIFI_SSID="Your_WiFi_SSID"      # 目标 WiFi 网络
WIFI_PASSWORD=""                  # 如已保存则留空

# 网络检查配置
CHECK_INTERVAL=1800               # 30分钟（秒）
PING_HOST="8.8.8.8"              # 连接检查主机
PING_TIMEOUT=3                    # Ping 超时（秒）

# 重试配置
MAX_RETRY_COUNT=5                 # 最大重试次数
RETRY_DELAYS=(0 30 60 120 300)   # 重试间隔（秒）
```

## 使用方法

### 命令行命令

安装后可在任意位置使用 `nm-status` 命令:

```bash
# 显示最近日志
nm-status

# 显示 launchd 任务状态
nm-status status

# 实时跟踪日志
nm-status tail

# 手动运行网络检查
nm-status test

# 显示当前 WiFi 信息
nm-status wifi

# 显示帮助
nm-status help
```

### 手动执行

也可以手动运行监控:
```bash
./network-monitor.sh
```

## 工作原理

1. **定时执行**: launchd 每 30 分钟运行一次脚本
2. **网络检查**: Ping 8.8.8.8 验证连接
3. **WiFi 状态**: 记录当前 WiFi 连接
4. **自动重连**: 如果网络断开:
   - 检查等待期间网络是否已恢复（智能重试）
   - 关闭 WiFi，等待 2 秒
   - 打开 WiFi，等待 5 秒
   - 连接到指定 WiFi
   - 验证连接
   - 最多重试 5 次，延迟递增

## 智能重试策略

```
检测到网络断开
  ↓
重试 #1: 立即 (0s 延迟)
  ├─ 检测网络 → 仍断开
  ├─ 重连 WiFi
  └─ 成功？→ 是→退出 / 否→继续
重试 #2: 等待 30 秒后
  ├─ 等待 30s
  ├─ 检测网络 → 已恢复！退出（不执行 WiFi 操作）
  └─ 仍断开 → 重连 WiFi
...继续最多 5 次重试，延迟递增
```

**核心特性**: 在执行 WiFi 操作之前，脚本会检查网络是否在等待期间已恢复。如果已恢复，则跳过 WiFi 操作以避免干扰正常连接。

## 日志文件

日志存储在 `~/.network-monitor/`:

- `network-monitor.log` - 主要活动日志
- `network-monitor.error.log` - 错误信息

查看日志:
```bash
nm-status show      # 最近条目
nm-status tail      # 实时监控
tail -f ~/.network-monitor/network-monitor.log
```

## 卸载

完全移除网络监控工具:

```bash
./uninstall.sh
```

这将:
- 卸载并移除 launchd 代理
- 移除 `nm-status` 命令链接
- 保留日志文件（如需可手动删除）

## 故障排除

### 任务未运行
```bash
# 检查是否已加载
launchctl list | grep network.monitor

# 如需重新加载
launchctl unload ~/Library/LaunchAgents/com.network.monitor.plist
launchctl load ~/Library/LaunchAgents/com.network.monitor.plist
```

### WiFi 未重连
```bash
# 检查 WiFi 接口名称
networksetup -listallhardwareports | grep -A 1 "Wi-Fi"

# 手动测试
nm-status test

# 检查日志错误
nm-status tail
```

### 权限问题
```bash
# 确保脚本可执行
chmod +x *.sh

# 修复配置权限
chmod 600 config.sh
```

## 系统要求

- macOS 10.10 或更高版本
- Bash 或 Zsh shell
- 无需额外依赖（使用 macOS 原生工具）

## 安全说明

- 如在 `config.sh` 中设置 `WIFI_PASSWORD`，文件应设置严格权限 (chmod 600)
- launchd 代理以用户权限运行（非 root）
- 如留空 `WIFI_PASSWORD` 则使用 macOS 保存的密码

## 文件结构

```
network-monitor/
├── network-monitor.sh         # 主监控脚本
├── config.sh                  # 配置文件（已排除）
├── config.example.sh          # 配置模板
├── com.network.monitor.plist  # launchd 配置
├── install.sh                 # 安装脚本
├── uninstall.sh               # 卸载脚本
├── status.sh                  # 状态工具 (nm-status)
├── CLAUDE.md                  # AI 助手指南
├── README.md                  # 英文文档
└── README.zh-CN.md            # 中文文档（本文件）
```

## 许可证

可自由使用和修改。
