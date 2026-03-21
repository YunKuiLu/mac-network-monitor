#!/bin/bash
# Chinese Language Pack (简体中文)

translate() {
    local key="$1"
    shift

    case "$key" in
        # 配置错误
        "err.config.not_found")
            printf "错误：配置文件未找到：%s" "$1"
            ;;

        # 通用消息
        "msg.making_executable")
            echo "正在设置脚本可执行权限..."
            ;;
        "msg.creating_log_dir")
            printf "创建日志目录：%s" "$1"
            ;;
        "msg.setting_permissions")
            echo "正在设置配置文件权限..."
            ;;

        # WiFi 操作
        "wifi.turning_off")
            echo "正在关闭 WiFi..."
            ;;
        "wifi.turning_on")
            echo "正在打开 WiFi..."
            ;;
        "wifi.connecting")
            printf "尝试连接 WiFi：%s" "$1"
            ;;
        "wifi.connected")
            printf "已连接到 %s" "$1"
            ;;
        "wifi.not_connected")
            echo "未连接"
            ;;
        "wifi.ssid_hidden")
            echo "已连接（SSID 已隐藏）"
            ;;

        # 网络监控
        "network.checking")
            echo "检查网络连接..."
            ;;
        "network.normal")
            echo "网络连接正常。"
            ;;
        "network.down")
            printf "网络已断开。当前 WiFi：%s。开始重新连接..." "${1:-无}"
            ;;
        "network.recovered")
            echo "网络已自行恢复，无需重连。"
            ;;
        "network.retry_waiting")
            printf "重试 #%d：等待 %d 秒后尝试..." "$1" "$2"
            ;;
        "network.retry_immediate")
            printf "重试 #%d：立即尝试..." "$1"
            ;;
        "network.retry_success")
            printf "成功连接到 WiFi（IP：%s），网络正常！" "$1"
            ;;
        "network.retry_wifi_no_ip")
            echo "WiFi 连接失败（未获取到 IP 地址）。将重试..."
            ;;
        "network.retry_ip_no_network")
            printf "WiFi 已连接（IP：%s）但无法访问网络。将重试..." "$1"
            ;;
        "network.retry_failed")
            printf "重连失败，已尝试 %d 次。将在下次定时检测时再试。" "$1"
            ;;

        # 状态消息
        "status.monitor_start")
            echo "=== 网络监控检测开始 ==="
            ;;
        "status.monitor_end")
            echo "=== 网络监控检测完成 ==="
            ;;
        "status.wifi_interface")
            printf "WiFi 接口：%s" "$1"
            ;;
        "status.current_wifi")
            printf "当前 WiFi：%s" "$1"
            ;;
        "status.wifi_ip")
            printf "WiFi IP 地址：%s" "$1"
            ;;
        "status.no_wifi_interface")
            echo "无法检测到 WiFi 接口。终止执行。"
            ;;

        # 安装脚本
        "install.title")
            echo "网络监控安装程序"
            ;;
        "install.not_root")
            echo "错误：此脚本不应以 root 身份运行。请以普通用户身份运行。"
            ;;
        "install.installing_plist")
            printf "安装 launchd 代理到：%s" "$1"
            ;;
        "install.loading_launchd")
            echo "加载 launchd 代理..."
            ;;
        "install.warning.load_failed")
            printf "警告：无法加载 launchd 代理。您可能需要运行：\n  launchctl load '%s'" "$1"
            ;;
        "install.creating_symlink")
            printf "创建 CLI 符号链接：%s -> %s" "$1" "$2"
            ;;
        "install.removing_existing_symlink")
            printf "移除现有符号链接：%s" "$1"
            ;;
        "install.warning.symlink_failed")
            printf "警告：无法创建符号链接 %s\n您可能需要使用 sudo 或手动创建：\n  sudo ln -s '%s' %s" "$1" "$2" "$3"
            ;;
        "install.complete")
            echo "安装完成！"
            ;;
        "install.info.running")
            echo "网络监控现已运行，将每 30 分钟检查一次。"
            ;;
        "install.info.commands")
            echo "可用命令："
            ;;

        # 卸载脚本
        "uninstall.title")
            echo "网络监控卸载程序"
            ;;
        "uninstall.unloading")
            echo "卸载 launchd 代理..."
            ;;
        "uninstall.warning.unload_failed")
            echo "警告：无法通过 launchctl 卸载。尝试使用 bootout..."
            ;;
        "uninstall.not_loaded")
            echo "Launchd 代理当前未加载。"
            ;;
        "uninstall.removing_plist")
            printf "移除 launchd plist 文件：%s" "$1"
            ;;
        "uninstall.plist_not_found")
            printf "Launchd plist 文件未找到：%s" "$1"
            ;;
        "uninstall.removing_symlink")
            printf "移除 CLI 符号链接：%s" "$1"
            ;;
        "uninstall.warning.symlink_remove_failed")
            printf "警告：无法移除符号链接。您可能需要 sudo：\n  sudo rm '%s'" "$1"
            ;;
        "uninstall.symlink_not_symlink")
            printf "警告：%s 存在但不是符号链接。不移除。" "$1"
            ;;
        "uninstall.symlink_not_found")
            printf "CLI 符号链接未找到：%s" "$1"
            ;;
        "uninstall.logs_preserved")
            printf "日志文件保存在：%s\n如需删除，请运行：\n  rm -rf '%s'" "$1" "$2"
            ;;
        "uninstall.complete")
            echo "卸载完成！"
            ;;
        "uninstall.info")
            echo "网络监控已卸载。\n您的配置和日志文件已保留。"
            ;;

        # 状态工具
        "status.tool.name")
            echo "网络监控状态查询工具"
            ;;
        "status.tool.usage")
            echo "用法：nm-status [命令]"
            ;;
        "status.tool.commands")
            echo "命令："
            ;;
        "status.cmd.show")
            echo "（无）| show    - 显示最近 10 条日志"
            ;;
        "status.cmd.status")
            echo "status          - 显示 launchd 任务状态"
            ;;
        "status.cmd.tail")
            echo "tail            - 实时跟踪日志"
            ;;
        "status.cmd.test")
            echo "test            - 手动运行网络检测"
            ;;
        "status.cmd.wifi")
            echo "wifi            - 显示当前 WiFi 信息"
            ;;
        "status.cmd.help")
            echo "help            - 显示此帮助信息"
            ;;
        "status.tool.examples")
            echo "示例："
            ;;
        "status.logs.not_found")
            printf "日志文件未找到：%s" "$1"
            ;;
        "status.logs.not_running")
            echo "监控可能尚未运行。"
            ;;
        "status.logs.header")
            printf "最近日志条目（最近 %d 条）" "$1"
            ;;
        "status.logs.realtime")
            echo "实时跟踪日志文件（Ctrl+C 退出）"
            ;;
        "status.launchd.header")
            echo "Launchd 任务状态"
            ;;
        "status.launchd.plist_installed")
            printf "Launchd plist 已安装：%s" "$1"
            ;;
        "status.launchd.plist_not_found")
            printf "Launchd plist 未找到：%s" "$1"
            ;;
        "status.launchd.loaded")
            echo "任务已加载到 launchctl"
            ;;
        "status.launchd.not_loaded")
            echo "任务未加载到 launchctl"
            ;;
        "status.launchd.load_hint")
            echo "如需加载，请运行：./install.sh"
            ;;
        "status.launchd.details")
            echo "任务详情："
            ;;
        "status.launchd.last_check")
            echo "上次检测："
            ;;
        "status.test.header")
            echo "运行手动网络检测"
            ;;
        "status.test.script_not_found")
            printf "错误：主脚本未找到：%s" "$1"
            ;;
        "status.test.setting_permissions")
            echo "正在设置脚本可执行权限..."
            ;;
        "status.wifi.header")
            echo "当前 WiFi 信息"
            ;;
        "status.wifi.no_interface")
            echo "无法检测到 WiFi 接口"
            ;;
        "status.wifi.connected")
            printf "已连接到：%s" "$1"
            ;;
        "status.wifi.connected_hidden")
            echo "已连接（SSID 已隐藏）"
            ;;
        "status.wifi.not_connected")
            echo "未连接到任何 WiFi 网络"
            ;;
        "status.wifi.power_on")
            echo "WiFi 电源：开启"
            ;;
        "status.wifi.power_off")
            echo "WiFi 电源：关闭"
            ;;
        "status.wifi.testing")
            echo "测试网络连接..."
            ;;
        "status.wifi.reachable")
            echo "网络可达"
            ;;
        "status.wifi.unreachable")
            echo "网络不可达"
            ;;
        "status.unknown_command")
            printf "未知命令：%s" "$1"
            ;;

        # 日志级别
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
