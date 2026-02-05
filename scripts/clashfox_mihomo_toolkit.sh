#!/bin/bash

# -----------------------------------------------------------------------------
# ClashFox Mihomo Kernel Management CLI
# Copyright (c) 2026 Kuochiang Lu
# Licensed under the MIT License.
# -----------------------------------------------------------------------------

# Author: Kuochiang Lu
# Version: v1.2.3(36)
# Last Updated: 2026-02-03
#
# 描述：
#   ClashFox Mihomo Kernel Manager 是一个功能完整的 mihomo 内核管理工具，
#   提供下载、安装、切换、备份及运行状态控制等一站式服务，确保内核运行环境的完整性和稳定性。
#
# 功能：
#   - 安装/更新最新 mihomo 内核（支持多 GitHub 源选择）
#   - 自动检测系统架构 (arm64 / amd64)
#   - 智能内核备份机制（按时间戳管理，保留历史版本）
#   - 灵活的内核版本切换功能
#   - 实时显示内核运行状态及版本信息
#   - 完整的目录结构检查与自动创建
#   - 内核进程的启动/关闭/重启控制
#   - 配置文件与日志目录的智能管理
#   - PID 文件管理确保进程安全控制
#   - 友好的交互式菜单界面，操作直观简单
#

# 生成二进制文件
# shc -f clashfox_mihomo_toolkit.sh -o ../shc/clashfox-installer && rm -f clashfox_mihomo_toolkit.sh.x.c
SCRIPT_NAME="ClashFox Mihomo Toolkit"
# 脚本版本号
SCRIPT_VERSION="v1.2.3(36)"

# Language settings: set CLASHFOX_LANG=zh|en|auto (default: auto)
CLASHFOX_LANG="${CLASHFOX_LANG:-auto}"

detect_language() {
    case "$CLASHFOX_LANG" in
        zh|en)
            echo "$CLASHFOX_LANG"
            return
            ;;
    esac

    local apple_locale
    apple_locale=$(defaults read -g AppleLocale 2>/dev/null)
    if [[ "$apple_locale" == zh* || "$apple_locale" == *zh* ]]; then
        echo "zh"
        return
    fi

    local sys_lang="${LC_ALL:-${LANG:-}}"
    if [[ "$sys_lang" == zh* || "$sys_lang" == *zh* ]]; then
        echo "zh"
    else
        echo "en"
    fi
}

tr_msg() {
    local key="$1"
    shift
    local lang
    lang="$(detect_language)"

    case "$lang" in
        zh)
            case "$key" in
                TAG_SUCCESS) printf "成功" ;;
                TAG_ERROR) printf "错误" ;;
                TAG_WARNING) printf "提示" ;;
                TAG_VERSION) printf "版本" ;;
                LABEL_FUNCTION) printf "功能" ;;
                LABEL_STATUS) printf "状态" ;;
                LABEL_HELP) printf "帮助" ;;
                LABEL_INIT) printf "初始化" ;;
                LABEL_STEP) printf "步骤" ;;
                LABEL_INFO) printf "信息" ;;
                LABEL_CLEANUP) printf "清理" ;;
                LABEL_OPTIONS) printf "选项" ;;
                LABEL_MENU) printf "主菜单" ;;

                MSG_MACOS_ONLY) printf "此脚本仅支持 macOS 系统" ;;
                MSG_WELCOME) printf "欢迎 %s 使用 %s" "$@" ;;
                MSG_PRESS_ENTER) printf "按 Enter 键继续..." ;;
                MSG_REQUIRE_SUDO_TITLE) printf "需要系统权限以执行内核管理操作" ;;
                MSG_REQUIRE_SUDO_DESC) printf "说明: 内核启动/关闭/重启/状态等操作需要 sudo 权限" ;;
                MSG_REQUIRE_SUDO_PROMPT) printf "授权: 请输入您的 macOS 用户密码以继续" ;;
                MSG_SUDO_OK) printf "权限验证通过" ;;
                MSG_SUDO_FAIL) printf "密码验证失败，请重新尝试" ;;

                MSG_INIT_CHECK_DIRS) printf "[初始化] 检查目录结构..." ;;
                MSG_INIT_SET_PERMS) printf "[初始化] 设置目录权限..." ;;
                MSG_NEED_ADMIN) printf "需要管理员权限创建目录结构" ;;
                MSG_NO_PERMISSION) printf "权限不足，无法创建目录结构" ;;
                MSG_CORE_DIR_CREATE) printf "创建内核目录: %s" "$@" ;;
                MSG_CORE_DIR_EXISTS) printf "内核目录存在: %s" "$@" ;;
                MSG_CONFIG_DIR_CREATE) printf "创建配置目录: %s" "$@" ;;
                MSG_CONFIG_DIR_EXISTS) printf "配置目录存在: %s" "$@" ;;
                MSG_DATA_DIR_CREATE) printf "创建数据目录: %s" "$@" ;;
                MSG_DATA_DIR_EXISTS) printf "数据目录存在: %s" "$@" ;;
                MSG_LOG_DIR_CREATE) printf "创建日志目录: %s" "$@" ;;
                MSG_LOG_DIR_EXISTS) printf "日志目录存在: %s" "$@" ;;
                MSG_RUNTIME_DIR_CREATE) printf "创建运行时目录: %s" "$@" ;;
                MSG_RUNTIME_DIR_EXISTS) printf "运行时目录存在: %s" "$@" ;;
                MSG_DIRS_PERMS_OK) printf "目录权限已设置" ;;

                MSG_CORE_DIR_MISSING_CREATE) printf "内核目录不存在，正在创建完整目录结构..." ;;
                MSG_DIR_CREATE_FAIL) printf "目录结构创建失败" ;;
                MSG_CORE_DIR_ENTER_FAIL) printf "无法进入内核目录" ;;

                MSG_STATUS_STOPPED) printf "已停止" ;;
                MSG_STATUS_RUNNING) printf "已运行" ;;
                MSG_STATUS_LABEL) printf "Mihomo 状态" ;;
                MSG_KERNEL_LABEL) printf "Mihomo 内核" ;;
                MSG_CONFIG_LABEL) printf "Mihomo 配置" ;;
                MSG_CONFIG_NOT_FOUND) printf "未找到 %s" "$@" ;;
                MSG_STATUS_SECTION) printf "• 运行状态:" ;;
                MSG_KERNEL_FILES_SECTION) printf "• 内核文件信息:" ;;
                MSG_BACKUP_SECTION) printf "• 备份信息:" ;;
                MSG_KERNEL_FILE_OK) printf "✓ 内核文件存在" ;;
                MSG_KERNEL_FILE_NOEXEC) printf "✗ 内核文件不可执行" ;;
                MSG_KERNEL_FILE_MISSING) printf "✗ 内核文件不存在" ;;
                MSG_KERNEL_VERSION_INFO) printf "版本信息: %s" "$@" ;;
                MSG_KERNEL_DISPLAY_NAME) printf "显示名称: %s" "$@" ;;
                MSG_KERNEL_DISPLAY_NAME_PARSE_FAIL) printf "显示名称: %s (无法解析)" "$@" ;;
                MSG_BACKUP_FOUND) printf "✓ 找到备份文件" ;;
                MSG_BACKUP_LATEST) printf "最新备份: %s" "$@" ;;
                MSG_BACKUP_VERSION) printf "备份版本: %s" "$@" ;;
                MSG_BACKUP_VERSION_UNKNOWN) printf "备份版本: 未知版本" ;;
                MSG_BACKUP_TIME) printf "备份时间: %s" "$@" ;;
                MSG_BACKUP_NONE) printf "⚠️  未找到任何备份" ;;

                MSG_LIST_BACKUPS_TITLE) printf "列出所有备份内核" ;;
                MSG_NO_BACKUPS) printf "无备份文件" ;;
                MSG_BACKUP_LIST_TITLE) printf "[信息] 可用备份内核列表（按时间倒序）:" ;;
                MSG_BACKUP_LIST_COLUMNS) printf "序号 | 版本信息 | 备份时间" ;;
                MSG_BACKUP_TOTAL) printf "备份文件总数: %s 个" "$@" ;;

                MSG_SWITCH_TITLE) printf "切换内核版本" ;;
                MSG_SWITCH_PROMPT) printf "请输入要切换的备份序号 (或按 Enter 返回主菜单): " ;;
                MSG_INVALID_NUMBER) printf "请输入有效的数字" ;;
                MSG_BACKUP_NO_MATCH) printf "未找到匹配的备份序号" ;;
                MSG_SWITCH_START) printf "[步骤] 开始切换内核..." ;;
                MSG_BACKUP_SELECTED) printf "[信息] 选择的备份文件: %s" "$@" ;;
                MSG_CURRENT_KERNEL_VERSION) printf "[信息] 当前内核版本: %s" "$@" ;;
                MSG_CURRENT_KERNEL_MISSING) printf "[信息] 当前内核不存在" ;;
                MSG_SWITCH_CONFIRM) printf "确定要切换到该版本吗? (y/n): " ;;
                MSG_OP_CANCELLED) printf "操作已取消" ;;
                MSG_BACKUP_CURRENT_KERNEL) printf "[步骤] 已备份当前内核 -> %s" "$@" ;;
                MSG_KERNEL_REPLACED) printf "[步骤] 内核已替换为: %s" "$@" ;;
                MSG_TEMP_BACKUP_REMOVED) printf "[步骤] 已删除临时备份文件: %s" "$@" ;;
                MSG_SWITCH_DONE) printf "[完成] 内核切换完成" ;;

                MSG_LIST_BACKUPS_SIMPLE_TITLE) printf "[信息] 可用备份内核:" ;;
                MSG_INSTALL_TITLE) printf "安装/更新 Mihomo 内核" ;;
                MSG_SELECT_GITHUB_USER) printf "选择 GitHub 用户下载内核:" ;;
                MSG_SELECT_USER_PROMPT) printf "请选择用户（默认1）: " ;;
                MSG_SELECTED_GITHUB_USER) printf "[信息] 选择的 GitHub 用户: %s" "$@" ;;
                MSG_GET_VERSION_INFO) printf "[步骤] 获取最新版本信息..." ;;
                MSG_VERSION_INFO_FAIL) printf "无法获取版本信息或版本不存在" ;;
                MSG_VERSION_INFO) printf "[信息] 版本信息: %s" "$@" ;;
                MSG_ARCH_UNSUPPORTED) printf "不支持的架构: %s" "$@" ;;
                MSG_ARCH_DETECTED) printf "[信息] 架构检测: %s" "$@" ;;
                MSG_DOWNLOAD_INFO) printf "[步骤] 下载信息:" ;;
                MSG_DOWNLOAD_URL) printf "  下载地址: %s" "$@" ;;
                MSG_VERSION_LABEL) printf "  版本信息: %s" "$@" ;;
                MSG_DOWNLOAD_CONFIRM) printf "确定要下载并安装此版本吗? (y/n): " ;;
                MSG_DOWNLOAD_START) printf "[步骤] 正在下载内核 (可能需要几分钟)..." ;;
                MSG_DOWNLOAD_RETRY) printf "下载失败，正在进行第 %s/%s 次重试..." "$@" ;;
                MSG_DOWNLOAD_OK) printf "下载完成" ;;
                MSG_EXTRACT_START) printf "[步骤] 正在解压内核..." ;;
                MSG_BACKUP_NEW_KERNEL) printf "[步骤] 已备份新安装的内核 -> %s" "$@" ;;
                MSG_INSTALL_DONE) printf "[完成] 内核安装成功" ;;
                MSG_EXTRACT_FAIL) printf "解压失败" ;;
                MSG_DOWNLOAD_FAIL) printf "下载失败，已尝试 %s 次" "$@" ;;

                MSG_VERSION_PARSE_FAIL) printf "无法解析" ;;
                MSG_NOT_INSTALLED) printf "未安装" ;;

                MSG_START_TITLE) printf "启动 Mihomo 内核" ;;
                MSG_KERNEL_RUNNING) printf "Mihomo 内核已经在运行中" ;;
                MSG_START_PRECHECK) printf "[步骤] 启动 Mihomo 内核前检查..." ;;
                MSG_KERNEL_NOT_FOUND) printf "未找到 Mihomo 内核文件" ;;
                MSG_KERNEL_NOT_EXEC) printf "Mihomo 内核文件不可执行" ;;
                MSG_ADD_EXEC) printf "[步骤] 正在添加执行权限..." ;;
                MSG_ADD_EXEC_FAIL) printf "添加执行权限失败" ;;
                MSG_CONFIG_DEFAULT_MISSING) printf "默认配置文件不存在: %s" "$@" ;;
                MSG_CONFIG_SCAN) printf "[步骤] 检查配置目录中的其他配置文件..." ;;
                MSG_CONFIG_NONE) printf "配置目录中没有找到任何配置文件" ;;
                MSG_CONFIG_PUT_HINT) printf "请将配置文件放置在 %s 目录下" "$@" ;;
                MSG_CONFIG_AVAILABLE) printf "[信息] 可用的配置文件:" ;;
                MSG_CONFIG_LIST_COLUMNS) printf "序号 | 配置文件路径" ;;
                MSG_CONFIG_SELECT_PROMPT) printf "请选择要使用的配置文件序号 (0 表示取消): " ;;
                MSG_CONFIG_SELECTED) printf "选择的配置文件: %s" "$@" ;;
                MSG_CONFIG_INVALID) printf "无效的选择" ;;
                MSG_CONFIG_READ_FAIL) printf "配置文件不可读: %s" "$@" ;;
                MSG_CONFIG_PERM_HINT) printf "请检查配置文件的权限设置" ;;
                MSG_CONFIG_EMPTY) printf "配置文件为空: %s" "$@" ;;
                MSG_CONFIG_EMPTY_HINT) printf "请确保配置文件包含有效的配置内容" ;;
                MSG_CONFIG_WILL_USE) printf "将使用配置文件: %s" "$@" ;;
                MSG_START_PROCESS) printf "[步骤] 正在启动内核进程..." ;;
                MSG_START_COMMAND) printf "启动命令: %s" "$@" ;;
                MSG_PID_WRITTEN) printf "PID已写入: %s" "$@" ;;
                MSG_KERNEL_STARTED) printf "Mihomo 内核已启动" ;;
                MSG_PROCESS_ID) printf "进程 ID: %s" "$@" ;;
                MSG_KERNEL_START_FAIL) printf "Mihomo 内核启动失败" ;;

                MSG_STOP_TITLE) printf "关闭 Mihomo 内核" ;;
                MSG_KERNEL_NOT_RUNNING) printf "Mihomo 内核当前未运行" ;;
                MSG_STOPPING_KERNEL) printf "[步骤] 正在关闭 Mihomo 内核..." ;;
                MSG_PIDS_FOUND) printf "找到进程 ID: %s" "$@" ;;
                MSG_STOPPING_PROCESS) printf "[步骤] 正在关闭进程 %s..." "$@" ;;
                MSG_FORCE_STOPPING) printf "尝试强制关闭剩余进程..." ;;
                MSG_KERNEL_STOP_FAIL) printf "关闭 Mihomo 内核失败" ;;
                MSG_KERNEL_STOP_HINT) printf "请尝试在 Activity Monitor 手动停止内核" ;;
                MSG_KERNEL_STOPPED) printf "Mihomo 内核已关闭" ;;
                MSG_PROCESS_NOT_RUNNING) printf "Mihomo 内核进程当前未运行" ;;
                MSG_PID_CLEANED) printf "PID文件已清理: %s" "$@" ;;

                MSG_RESTART_TITLE) printf "重启 Mihomo 内核" ;;
                MSG_KERNEL_MENU_TITLE) printf "内核控制" ;;
                MSG_KERNEL_MENU_PROMPT) printf "请选择内核操作:" ;;
                MSG_MENU_START) printf "1) 启动内核" ;;
                MSG_MENU_STOP) printf "2) 关闭内核" ;;
                MSG_MENU_RESTART) printf "3) 重启内核" ;;
                MSG_MENU_BACK) printf "0) 返回主菜单" ;;
                MSG_MENU_CHOICE_0_3) printf "请输入选择 (0-3): " ;;
                MSG_MENU_INVALID) printf "无效的选择，请重新输入" ;;

                MSG_LOGS_TITLE) printf "查看 Mihomo 内核日志" ;;
                MSG_LOG_FILE_MISSING) printf "日志文件不存在: %s" "$@" ;;
                MSG_LOG_FILE_HINT) printf "请先启动内核以生成日志文件" ;;
                MSG_LOG_FILE_PATH) printf "[信息] 日志文件路径: %s" "$@" ;;
                MSG_LOG_FILE_SIZE) printf "[信息] 日志大小: %s" "$@" ;;
                MSG_LOG_FILE_LINES) printf "[信息] 日志行数: %s" "$@" ;;
                MSG_LOG_VIEW_OPTIONS) printf "[选项] 如何查看日志:" ;;
                MSG_LOG_OPTION_TAIL) printf "1) 查看日志的最后 50 行" ;;
                MSG_LOG_OPTION_FOLLOW) printf "2) 实时查看日志更新 (按 Ctrl+C 退出)" ;;
                MSG_LOG_OPTION_LESS) printf "3) 使用 less 查看完整日志 (按 q 退出)" ;;
                MSG_LOG_OPTION_BACK) printf "0) 返回主菜单" ;;
                MSG_LOG_TAIL_HEADER) printf "[信息] 日志的最后 50 行内容:" ;;
                MSG_LOG_FOLLOW_HEADER) printf "[信息] 实时查看日志更新 (按 Ctrl+C 退出):" ;;
                MSG_LOG_LESS_HEADER) printf "[信息] 使用 less 查看完整日志 (按 q 退出):" ;;

                MSG_HELP_TITLE) printf "帮助信息" ;;
                MSG_HELP_ARGS) printf "命令行参数:" ;;
                MSG_HELP_DIR_ARG) printf "  -d|--directory <路径>  自定义 ClashFox 安装目录" ;;
                MSG_HELP_LANG_ARG) printf "  -l|--lang <zh|en|auto>  指定显示语言" ;;
                MSG_HELP_STATUS) printf "  status                 查看当前内核状态" ;;
                MSG_HELP_LIST) printf "  list                   列出所有内核备份" ;;
                MSG_HELP_SWITCH) printf "  switch                 切换内核版本" ;;
                MSG_HELP_LOGS) printf "  logs|log               查看内核日志" ;;
                MSG_HELP_CLEAN) printf "  clean|clear            清除日志" ;;
                MSG_HELP_HELP) printf "  help|-h                显示帮助信息" ;;
                MSG_HELP_VERSION) printf "  version|-v             显示版本信息" ;;
                MSG_HELP_MENU) printf "交互式菜单:" ;;
                MSG_MENU_INSTALL) printf "1) 安装/更新 Mihomo 内核" ;;
                MSG_MENU_CONTROL) printf "2) 内核控制(启动/关闭/重启)" ;;
                MSG_MENU_STATUS) printf "3) 查看当前状态" ;;
                MSG_MENU_SWITCH) printf "4) 切换内核版本" ;;
                MSG_MENU_LIST) printf "5) 列出所有备份" ;;
                MSG_MENU_LOGS) printf "6) 查看内核日志" ;;
                MSG_MENU_CLEAN) printf "7) 清除日志" ;;
                MSG_MENU_HELP) printf "8) 显示帮助信息" ;;
                MSG_MENU_EXIT) printf "0) 退出程序" ;;
                MSG_HELP_NOTE) printf "此工具不仅负责内核版本管理，还可以控制内核的运行状态（启动/关闭/重启）" ;;

                MSG_CLEAN_TITLE) printf "清理旧日志文件" ;;
                MSG_CLEAN_CURRENT_LOG) printf "[信息] 当前日志文件: %s" "$@" ;;
                MSG_CLEAN_LOG_SIZE) printf "[信息] 日志大小: %s" "$@" ;;
                MSG_CLEAN_OLD_COUNT) printf "[信息] 旧日志数量: %s" "$@" ;;
                MSG_CLEAN_OLD_SIZE) printf "[信息] 旧日志总大小: %s" "$@" ;;
                MSG_CLEAN_OPTIONS) printf "[清理选项]" ;;
                MSG_CLEAN_ALL) printf "1) 删除所有旧日志文件" ;;
                MSG_CLEAN_7D) printf "2) 保留最近7天的日志，删除更早的日志" ;;
                MSG_CLEAN_30D) printf "3) 保留最近30天的日志，删除更早的日志" ;;
                MSG_CLEAN_CANCEL) printf "0) 取消操作" ;;
                MSG_CLEAN_PROMPT) printf "请选择清理方式 (0-3): " ;;
                MSG_CLEAN_DONE_ALL) printf "已删除所有旧日志文件" ;;
                MSG_CLEAN_DONE_7D) printf "已删除7天前的日志文件" ;;
                MSG_CLEAN_DONE_30D) printf "已删除30天前的日志文件" ;;
                MSG_CLEAN_CANCELLED) printf "取消清理操作" ;;
                MSG_CLEAN_INVALID) printf "无效的选择" ;;

                MSG_LOG_ROTATE_DATE) printf "日志已按日期备份: %s" "$@" ;;
                MSG_LOG_ROTATE_SIZE) printf "日志已按大小滚动: %s" "$@" ;;

                MSG_MAIN_STATUS_TITLE) printf "当前内核信息" ;;
                MSG_MAIN_MENU_TITLE) printf "主菜单" ;;
                MSG_KERNEL_STATUS_CHECK) printf "内核状态检查" ;;
                MSG_MAIN_PROMPT) printf "请选择要执行的功能:" ;;
                MSG_MAIN_LINE_1) printf "  1) 安装/更新 Mihomo 内核         2) 内核控制(启动/关闭/重启)" ;;
                MSG_MAIN_LINE_2) printf "  3) 查看当前状态                  4) 切换内核版本" ;;
                MSG_MAIN_LINE_3) printf "  5) 列出所有备份                  6) 查看内核日志" ;;
                MSG_MAIN_LINE_4) printf "  7) 清除日志                      8) 显示帮助信息" ;;
                MSG_MAIN_LINE_5) printf "  0) 退出程序" ;;

                MSG_CLEANUP_STOPPING) printf "[清理] 正在终止日志检查进程 (PID: %s)..." "$@" ;;
                MSG_CLEANUP_FORCE) printf "[清理] 尝试强制终止日志检查进程..." ;;
                MSG_CLEANUP_FAIL) printf "[清理] 日志检查进程终止失败 (PID: %s)" "$@" ;;
                MSG_CLEANUP_OK) printf "日志检查进程已终止" ;;
                MSG_EXIT_ABNORMAL) printf "[退出] 程序已异常终止" ;;

                MSG_ARG_DIR_REQUIRED) printf "-d/--directory 参数需要指定目录路径" ;;
                MSG_ARG_LANG_REQUIRED) printf "-l/--lang 参数需要指定语言(zh|en|auto)" ;;
                MSG_ARG_LANG_INVALID) printf "无效语言: %s (支持: zh|en|auto)" "$@" ;;
                MSG_UNKNOWN_COMMAND) printf "未知命令: %s" "$@" ;;
                MSG_AVAILABLE_COMMANDS) printf "可用命令: status, list, switch, logs, clean, help, version" ;;
                MSG_AVAILABLE_ARGS) printf "可用参数: -d/--directory <路径> - 自定义 ClashFox 安装目录; -l/--lang <zh|en|auto> - 指定显示语言" ;;

                MSG_SAVED_DIR_LOADED) printf "已加载保存的目录: %s" "$@" ;;
                MSG_SAVED_DIR_NOT_FOUND) printf "未找到保存的目录，将使用默认目录: %s" "$@" ;;
                MSG_DIR_SAVED) printf "已保存目录到配置文件: %s" "$@" ;;

                MSG_DIR_SELECT_TITLE) printf "选择 ClashFox 安装目录" ;;
                MSG_DEFAULT_DIR_CURRENT) printf "当前默认安装目录: %s" "$@" ;;
                MSG_USE_DEFAULT_DIR) printf "是否使用默认目录? (y/n): " ;;
                MSG_CUSTOM_DIR_PROMPT) printf "请输入自定义安装目录: " ;;
                MSG_DIR_SET) printf "已设置 ClashFox 安装目录为: %s" "$@" ;;
                MSG_DIR_USE_DEFAULT) printf "将使用默认安装目录: %s" "$@" ;;
                MSG_DIR_INVALID_FALLBACK) printf "未输入有效目录，将使用默认目录: %s" "$@" ;;
                MSG_DIR_EXISTING) printf "使用现有安装目录: %s" "$@" ;;

                MSG_LOG_CHECKER_START) printf "[初始化] 启动日志定期检查进程..." ;;
                MSG_LOG_CHECKER_OK) printf "日志定期检查进程已启动，PID: %s" "$@" ;;
                MSG_APP_CHECK) printf "[初始化] 检查 ClashFox 应用是否安装..." ;;
                MSG_APP_DIR_MISSING) printf "ClashFox 应用目录不存在，正在创建..." ;;
                MSG_APP_DIR_TARGET) printf "  目标目录: %s" "$@" ;;
                MSG_APP_DIR_CREATED) printf "已创建 ClashFox 应用目录: %s" "$@" ;;
                MSG_APP_DIR_EXISTS) printf "ClashFox 应用已安装: %s" "$@" ;;

                MSG_MAIN_CHOICE) printf "请输入选择 (0-8): " ;;
                MSG_EXIT_THANKS) printf "[退出] 感谢使用 ClashFox Mihomo 内核管理器" ;;

                MSG_MIHOMO_CONFIG_NOT_FOUND) printf "Mihomo 配置: [未找到 %s]" "$@" ;;
                MSG_MIHOMO_CONFIG_FOUND) printf "Mihomo 配置: [%s]" "$@" ;;
                MSG_MIHOMO_STATUS_RUNNING) printf "%s: [%s]" "$@" ;;
                MSG_MIHOMO_STATUS_STOPPED) printf "%s: [%s]" "$@" ;;
                MSG_MIHOMO_KERNEL_LINE) printf "%s: [%s]" "$@" ;;

                *) printf "%s" "$key" ;;
            esac
            ;;
        en)
            case "$key" in
                TAG_SUCCESS) printf "Success" ;;
                TAG_ERROR) printf "Error" ;;
                TAG_WARNING) printf "Tip" ;;
                TAG_VERSION) printf "Version" ;;
                LABEL_FUNCTION) printf "Function" ;;
                LABEL_STATUS) printf "Status" ;;
                LABEL_HELP) printf "Help" ;;
                LABEL_INIT) printf "Init" ;;
                LABEL_STEP) printf "Step" ;;
                LABEL_INFO) printf "Info" ;;
                LABEL_CLEANUP) printf "Cleanup" ;;
                LABEL_OPTIONS) printf "Options" ;;
                LABEL_MENU) printf "Main Menu" ;;

                MSG_MACOS_ONLY) printf "This script only supports macOS." ;;
                MSG_WELCOME) printf "Welcome %s to %s" "$@" ;;
                MSG_PRESS_ENTER) printf "Press Enter to continue..." ;;
                MSG_REQUIRE_SUDO_TITLE) printf "System privileges are required to manage the kernel." ;;
                MSG_REQUIRE_SUDO_DESC) printf "Note: start/stop/restart/status operations require sudo privileges." ;;
                MSG_REQUIRE_SUDO_PROMPT) printf "Authorization: enter your macOS password to continue." ;;
                MSG_SUDO_OK) printf "Privilege check passed." ;;
                MSG_SUDO_FAIL) printf "Password verification failed. Please try again." ;;

                MSG_INIT_CHECK_DIRS) printf "[Init] Checking directory structure..." ;;
                MSG_INIT_SET_PERMS) printf "[Init] Setting directory permissions..." ;;
                MSG_NEED_ADMIN) printf "Administrator privileges are required to create directories." ;;
                MSG_NO_PERMISSION) printf "Insufficient permissions to create directories." ;;
                MSG_CORE_DIR_CREATE) printf "Creating core directory: %s" "$@" ;;
                MSG_CORE_DIR_EXISTS) printf "Core directory exists: %s" "$@" ;;
                MSG_CONFIG_DIR_CREATE) printf "Creating config directory: %s" "$@" ;;
                MSG_CONFIG_DIR_EXISTS) printf "Config directory exists: %s" "$@" ;;
                MSG_DATA_DIR_CREATE) printf "Creating data directory: %s" "$@" ;;
                MSG_DATA_DIR_EXISTS) printf "Data directory exists: %s" "$@" ;;
                MSG_LOG_DIR_CREATE) printf "Creating log directory: %s" "$@" ;;
                MSG_LOG_DIR_EXISTS) printf "Log directory exists: %s" "$@" ;;
                MSG_RUNTIME_DIR_CREATE) printf "Creating runtime directory: %s" "$@" ;;
                MSG_RUNTIME_DIR_EXISTS) printf "Runtime directory exists: %s" "$@" ;;
                MSG_DIRS_PERMS_OK) printf "Directory permissions set." ;;

                MSG_CORE_DIR_MISSING_CREATE) printf "Core directory missing. Creating full structure..." ;;
                MSG_DIR_CREATE_FAIL) printf "Failed to create directory structure." ;;
                MSG_CORE_DIR_ENTER_FAIL) printf "Unable to enter core directory." ;;

                MSG_STATUS_STOPPED) printf "Stopped" ;;
                MSG_STATUS_RUNNING) printf "Running" ;;
                MSG_STATUS_LABEL) printf "Mihomo Status" ;;
                MSG_KERNEL_LABEL) printf "Mihomo Kernel" ;;
                MSG_CONFIG_LABEL) printf "Mihomo Config" ;;
                MSG_CONFIG_NOT_FOUND) printf "Not found %s" "$@" ;;
                MSG_STATUS_SECTION) printf "• Status:" ;;
                MSG_KERNEL_FILES_SECTION) printf "• Kernel file info:" ;;
                MSG_BACKUP_SECTION) printf "• Backup info:" ;;
                MSG_KERNEL_FILE_OK) printf "✓ Kernel file exists" ;;
                MSG_KERNEL_FILE_NOEXEC) printf "✗ Kernel file is not executable" ;;
                MSG_KERNEL_FILE_MISSING) printf "✗ Kernel file not found" ;;
                MSG_KERNEL_VERSION_INFO) printf "Version: %s" "$@" ;;
                MSG_KERNEL_DISPLAY_NAME) printf "Display name: %s" "$@" ;;
                MSG_KERNEL_DISPLAY_NAME_PARSE_FAIL) printf "Display name: %s (parse failed)" "$@" ;;
                MSG_BACKUP_FOUND) printf "✓ Backup found" ;;
                MSG_BACKUP_LATEST) printf "Latest backup: %s" "$@" ;;
                MSG_BACKUP_VERSION) printf "Backup version: %s" "$@" ;;
                MSG_BACKUP_VERSION_UNKNOWN) printf "Backup version: Unknown" ;;
                MSG_BACKUP_TIME) printf "Backup time: %s" "$@" ;;
                MSG_BACKUP_NONE) printf "⚠️  No backups found" ;;

                MSG_LIST_BACKUPS_TITLE) printf "List all backup kernels" ;;
                MSG_NO_BACKUPS) printf "No backup files" ;;
                MSG_BACKUP_LIST_TITLE) printf "[Info] Available backups (newest first):" ;;
                MSG_BACKUP_LIST_COLUMNS) printf "No. | Version | Backup time" ;;
                MSG_BACKUP_TOTAL) printf "Total backups: %s" "$@" ;;

                MSG_SWITCH_TITLE) printf "Switch kernel version" ;;
                MSG_SWITCH_PROMPT) printf "Enter backup number to switch (or press Enter to return): " ;;
                MSG_INVALID_NUMBER) printf "Please enter a valid number." ;;
                MSG_BACKUP_NO_MATCH) printf "No matching backup number found." ;;
                MSG_SWITCH_START) printf "[Step] Starting kernel switch..." ;;
                MSG_BACKUP_SELECTED) printf "[Info] Selected backup: %s" "$@" ;;
                MSG_CURRENT_KERNEL_VERSION) printf "[Info] Current kernel version: %s" "$@" ;;
                MSG_CURRENT_KERNEL_MISSING) printf "[Info] Current kernel not found" ;;
                MSG_SWITCH_CONFIRM) printf "Confirm switch to this version? (y/n): " ;;
                MSG_OP_CANCELLED) printf "Operation cancelled." ;;
                MSG_BACKUP_CURRENT_KERNEL) printf "[Step] Backed up current kernel -> %s" "$@" ;;
                MSG_KERNEL_REPLACED) printf "[Step] Kernel replaced with: %s" "$@" ;;
                MSG_TEMP_BACKUP_REMOVED) printf "[Step] Removed temp backup file: %s" "$@" ;;
                MSG_SWITCH_DONE) printf "[Done] Kernel switch complete" ;;

                MSG_LIST_BACKUPS_SIMPLE_TITLE) printf "[Info] Available backups:" ;;
                MSG_INSTALL_TITLE) printf "Install/Update Mihomo kernel" ;;
                MSG_SELECT_GITHUB_USER) printf "Select GitHub user for download:" ;;
                MSG_SELECT_USER_PROMPT) printf "Choose user (default 1): " ;;
                MSG_SELECTED_GITHUB_USER) printf "[Info] Selected GitHub user: %s" "$@" ;;
                MSG_GET_VERSION_INFO) printf "[Step] Fetching latest version info..." ;;
                MSG_VERSION_INFO_FAIL) printf "Unable to fetch version info or version does not exist." ;;
                MSG_VERSION_INFO) printf "[Info] Version: %s" "$@" ;;
                MSG_ARCH_UNSUPPORTED) printf "Unsupported architecture: %s" "$@" ;;
                MSG_ARCH_DETECTED) printf "[Info] Architecture: %s" "$@" ;;
                MSG_DOWNLOAD_INFO) printf "[Step] Download info:" ;;
                MSG_DOWNLOAD_URL) printf "  Download URL: %s" "$@" ;;
                MSG_VERSION_LABEL) printf "  Version: %s" "$@" ;;
                MSG_DOWNLOAD_CONFIRM) printf "Download and install this version? (y/n): " ;;
                MSG_DOWNLOAD_START) printf "[Step] Downloading kernel (may take a few minutes)..." ;;
                MSG_DOWNLOAD_RETRY) printf "Download failed. Retrying %s/%s..." "$@" ;;
                MSG_DOWNLOAD_OK) printf "Download complete" ;;
                MSG_EXTRACT_START) printf "[Step] Extracting kernel..." ;;
                MSG_BACKUP_NEW_KERNEL) printf "[Step] Backed up new kernel -> %s" "$@" ;;
                MSG_INSTALL_DONE) printf "[Done] Kernel installation successful" ;;
                MSG_EXTRACT_FAIL) printf "Extraction failed." ;;
                MSG_DOWNLOAD_FAIL) printf "Download failed after %s attempts." "$@" ;;

                MSG_VERSION_PARSE_FAIL) printf "Parse failed" ;;
                MSG_NOT_INSTALLED) printf "Not installed" ;;

                MSG_START_TITLE) printf "Start Mihomo kernel" ;;
                MSG_KERNEL_RUNNING) printf "Mihomo kernel is already running" ;;
                MSG_START_PRECHECK) printf "[Step] Pre-check before starting kernel..." ;;
                MSG_KERNEL_NOT_FOUND) printf "Mihomo kernel file not found" ;;
                MSG_KERNEL_NOT_EXEC) printf "Mihomo kernel file is not executable" ;;
                MSG_ADD_EXEC) printf "[Step] Adding execute permission..." ;;
                MSG_ADD_EXEC_FAIL) printf "Failed to add execute permission" ;;
                MSG_CONFIG_DEFAULT_MISSING) printf "Default config file not found: %s" "$@" ;;
                MSG_CONFIG_SCAN) printf "[Step] Checking other config files..." ;;
                MSG_CONFIG_NONE) printf "No config files found in config directory." ;;
                MSG_CONFIG_PUT_HINT) printf "Place your config file in %s" "$@" ;;
                MSG_CONFIG_AVAILABLE) printf "[Info] Available config files:" ;;
                MSG_CONFIG_LIST_COLUMNS) printf "No. | Config file path" ;;
                MSG_CONFIG_SELECT_PROMPT) printf "Choose config file number (0 to cancel): " ;;
                MSG_CONFIG_SELECTED) printf "Selected config file: %s" "$@" ;;
                MSG_CONFIG_INVALID) printf "Invalid selection." ;;
                MSG_CONFIG_READ_FAIL) printf "Config file not readable: %s" "$@" ;;
                MSG_CONFIG_PERM_HINT) printf "Check the config file permissions." ;;
                MSG_CONFIG_EMPTY) printf "Config file is empty: %s" "$@" ;;
                MSG_CONFIG_EMPTY_HINT) printf "Ensure the config file has valid content." ;;
                MSG_CONFIG_WILL_USE) printf "Using config file: %s" "$@" ;;
                MSG_START_PROCESS) printf "[Step] Starting kernel process..." ;;
                MSG_START_COMMAND) printf "Start command: %s" "$@" ;;
                MSG_PID_WRITTEN) printf "PID written to: %s" "$@" ;;
                MSG_KERNEL_STARTED) printf "Mihomo kernel started" ;;
                MSG_PROCESS_ID) printf "Process ID: %s" "$@" ;;
                MSG_KERNEL_START_FAIL) printf "Mihomo kernel failed to start" ;;

                MSG_STOP_TITLE) printf "Stop Mihomo kernel" ;;
                MSG_KERNEL_NOT_RUNNING) printf "Mihomo kernel is not running" ;;
                MSG_STOPPING_KERNEL) printf "[Step] Stopping Mihomo kernel..." ;;
                MSG_PIDS_FOUND) printf "Found process IDs: %s" "$@" ;;
                MSG_STOPPING_PROCESS) printf "[Step] Stopping process %s..." "$@" ;;
                MSG_FORCE_STOPPING) printf "Forcing remaining processes to stop..." ;;
                MSG_KERNEL_STOP_FAIL) printf "Failed to stop Mihomo kernel" ;;
                MSG_KERNEL_STOP_HINT) printf "Try stopping the kernel in Activity Monitor." ;;
                MSG_KERNEL_STOPPED) printf "Mihomo kernel stopped" ;;
                MSG_PROCESS_NOT_RUNNING) printf "Mihomo kernel process is not running" ;;
                MSG_PID_CLEANED) printf "PID file removed: %s" "$@" ;;

                MSG_RESTART_TITLE) printf "Restart Mihomo kernel" ;;
                MSG_KERNEL_MENU_TITLE) printf "Kernel control" ;;
                MSG_KERNEL_MENU_PROMPT) printf "Choose kernel action:" ;;
                MSG_MENU_START) printf "1) Start kernel" ;;
                MSG_MENU_STOP) printf "2) Stop kernel" ;;
                MSG_MENU_RESTART) printf "3) Restart kernel" ;;
                MSG_MENU_BACK) printf "0) Back to main menu" ;;
                MSG_MENU_CHOICE_0_3) printf "Enter choice (0-3): " ;;
                MSG_MENU_INVALID) printf "Invalid choice. Please try again." ;;

                MSG_LOGS_TITLE) printf "View Mihomo kernel logs" ;;
                MSG_LOG_FILE_MISSING) printf "Log file not found: %s" "$@" ;;
                MSG_LOG_FILE_HINT) printf "Start the kernel to generate logs first." ;;
                MSG_LOG_FILE_PATH) printf "[Info] Log file path: %s" "$@" ;;
                MSG_LOG_FILE_SIZE) printf "[Info] Log size: %s" "$@" ;;
                MSG_LOG_FILE_LINES) printf "[Info] Log lines: %s" "$@" ;;
                MSG_LOG_VIEW_OPTIONS) printf "[Options] How to view logs:" ;;
                MSG_LOG_OPTION_TAIL) printf "1) Show last 50 lines" ;;
                MSG_LOG_OPTION_FOLLOW) printf "2) Follow log updates (Ctrl+C to exit)" ;;
                MSG_LOG_OPTION_LESS) printf "3) View full log with less (q to exit)" ;;
                MSG_LOG_OPTION_BACK) printf "0) Back to main menu" ;;
                MSG_LOG_TAIL_HEADER) printf "[Info] Last 50 log lines:" ;;
                MSG_LOG_FOLLOW_HEADER) printf "[Info] Following log updates (Ctrl+C to exit):" ;;
                MSG_LOG_LESS_HEADER) printf "[Info] Viewing log with less (q to exit):" ;;

                MSG_HELP_TITLE) printf "Help" ;;
                MSG_HELP_ARGS) printf "Command-line arguments:" ;;
                MSG_HELP_DIR_ARG) printf "  -d|--directory <path>  Custom ClashFox install directory" ;;
                MSG_HELP_LANG_ARG) printf "  -l|--lang <zh|en|auto>  Set UI language" ;;
                MSG_HELP_STATUS) printf "  status                 Show current kernel status" ;;
                MSG_HELP_LIST) printf "  list                   List all kernel backups" ;;
                MSG_HELP_SWITCH) printf "  switch                 Switch kernel version" ;;
                MSG_HELP_LOGS) printf "  logs|log               View kernel logs" ;;
                MSG_HELP_CLEAN) printf "  clean|clear            Clean logs" ;;
                MSG_HELP_HELP) printf "  help|-h                Show help" ;;
                MSG_HELP_VERSION) printf "  version|-v             Show version" ;;
                MSG_HELP_MENU) printf "Interactive menu:" ;;
                MSG_MENU_INSTALL) printf "1) Install/Update Mihomo kernel" ;;
                MSG_MENU_CONTROL) printf "2) Kernel control (start/stop/restart)" ;;
                MSG_MENU_STATUS) printf "3) Show current status" ;;
                MSG_MENU_SWITCH) printf "4) Switch kernel version" ;;
                MSG_MENU_LIST) printf "5) List all backups" ;;
                MSG_MENU_LOGS) printf "6) View kernel logs" ;;
                MSG_MENU_CLEAN) printf "7) Clean logs" ;;
                MSG_MENU_HELP) printf "8) Show help" ;;
                MSG_MENU_EXIT) printf "0) Exit" ;;
                MSG_HELP_NOTE) printf "This tool manages kernel versions and controls kernel status (start/stop/restart)." ;;

                MSG_CLEAN_TITLE) printf "Clean old log files" ;;
                MSG_CLEAN_CURRENT_LOG) printf "[Info] Current log file: %s" "$@" ;;
                MSG_CLEAN_LOG_SIZE) printf "[Info] Log size: %s" "$@" ;;
                MSG_CLEAN_OLD_COUNT) printf "[Info] Old log count: %s" "$@" ;;
                MSG_CLEAN_OLD_SIZE) printf "[Info] Total old log size: %s" "$@" ;;
                MSG_CLEAN_OPTIONS) printf "[Cleanup options]" ;;
                MSG_CLEAN_ALL) printf "1) Delete all old logs" ;;
                MSG_CLEAN_7D) printf "2) Keep last 7 days, delete older logs" ;;
                MSG_CLEAN_30D) printf "3) Keep last 30 days, delete older logs" ;;
                MSG_CLEAN_CANCEL) printf "0) Cancel" ;;
                MSG_CLEAN_PROMPT) printf "Choose cleanup option (0-3): " ;;
                MSG_CLEAN_DONE_ALL) printf "Deleted all old log files" ;;
                MSG_CLEAN_DONE_7D) printf "Deleted logs older than 7 days" ;;
                MSG_CLEAN_DONE_30D) printf "Deleted logs older than 30 days" ;;
                MSG_CLEAN_CANCELLED) printf "Cleanup cancelled" ;;
                MSG_CLEAN_INVALID) printf "Invalid selection" ;;

                MSG_LOG_ROTATE_DATE) printf "Log rotated by date: %s" "$@" ;;
                MSG_LOG_ROTATE_SIZE) printf "Log rotated by size: %s" "$@" ;;

                MSG_MAIN_STATUS_TITLE) printf "Current kernel info" ;;
                MSG_MAIN_MENU_TITLE) printf "Main menu" ;;
                MSG_KERNEL_STATUS_CHECK) printf "Kernel status check" ;;
                MSG_MAIN_PROMPT) printf "Choose an option:" ;;
                MSG_MAIN_LINE_1) printf "  1) Install/Update Mihomo kernel        2) Kernel control (start/stop/restart)" ;;
                MSG_MAIN_LINE_2) printf "  3) Show current status                 4) Switch kernel version" ;;
                MSG_MAIN_LINE_3) printf "  5) List all backups                    6) View kernel logs" ;;
                MSG_MAIN_LINE_4) printf "  7) Clean logs                          8) Show help" ;;
                MSG_MAIN_LINE_5) printf "  0) Exit" ;;

                MSG_CLEANUP_STOPPING) printf "[Cleanup] Stopping log checker (PID: %s)..." "$@" ;;
                MSG_CLEANUP_FORCE) printf "[Cleanup] Forcing log checker to stop..." ;;
                MSG_CLEANUP_FAIL) printf "[Cleanup] Failed to stop log checker (PID: %s)" "$@" ;;
                MSG_CLEANUP_OK) printf "Log checker stopped" ;;
                MSG_EXIT_ABNORMAL) printf "[Exit] Program terminated unexpectedly" ;;

                MSG_ARG_DIR_REQUIRED) printf "-d/--directory requires a directory path." ;;
                MSG_ARG_LANG_REQUIRED) printf "-l/--lang requires a language (zh|en|auto)." ;;
                MSG_ARG_LANG_INVALID) printf "Invalid language: %s (supported: zh|en|auto)" "$@" ;;
                MSG_UNKNOWN_COMMAND) printf "Unknown command: %s" "$@" ;;
                MSG_AVAILABLE_COMMANDS) printf "Available commands: status, list, switch, logs, clean, help, version" ;;
                MSG_AVAILABLE_ARGS) printf "Available args: -d/--directory <path> - custom ClashFox install dir; -l/--lang <zh|en|auto> - set UI language" ;;

                MSG_SAVED_DIR_LOADED) printf "Loaded saved directory: %s" "$@" ;;
                MSG_SAVED_DIR_NOT_FOUND) printf "No saved directory found. Using default: %s" "$@" ;;
                MSG_DIR_SAVED) printf "Saved directory to config: %s" "$@" ;;

                MSG_DIR_SELECT_TITLE) printf "Select ClashFox install directory" ;;
                MSG_DEFAULT_DIR_CURRENT) printf "Current default directory: %s" "$@" ;;
                MSG_USE_DEFAULT_DIR) printf "Use default directory? (y/n): " ;;
                MSG_CUSTOM_DIR_PROMPT) printf "Enter custom install directory: " ;;
                MSG_DIR_SET) printf "Set ClashFox install directory to: %s" "$@" ;;
                MSG_DIR_USE_DEFAULT) printf "Using default install directory: %s" "$@" ;;
                MSG_DIR_INVALID_FALLBACK) printf "Invalid input. Using default directory: %s" "$@" ;;
                MSG_DIR_EXISTING) printf "Using existing install directory: %s" "$@" ;;

                MSG_LOG_CHECKER_START) printf "[Init] Starting log checker..." ;;
                MSG_LOG_CHECKER_OK) printf "Log checker started. PID: %s" "$@" ;;
                MSG_APP_CHECK) printf "[Init] Checking ClashFox app installation..." ;;
                MSG_APP_DIR_MISSING) printf "ClashFox app directory not found. Creating..." ;;
                MSG_APP_DIR_TARGET) printf "  Target directory: %s" "$@" ;;
                MSG_APP_DIR_CREATED) printf "Created ClashFox app directory: %s" "$@" ;;
                MSG_APP_DIR_EXISTS) printf "ClashFox app installed: %s" "$@" ;;

                MSG_MAIN_CHOICE) printf "Enter choice (0-8): " ;;
                MSG_EXIT_THANKS) printf "[Exit] Thanks for using ClashFox Mihomo Kernel Manager" ;;

                MSG_MIHOMO_CONFIG_NOT_FOUND) printf "Mihomo Config: [Not found %s]" "$@" ;;
                MSG_MIHOMO_CONFIG_FOUND) printf "Mihomo Config: [%s]" "$@" ;;
                MSG_MIHOMO_STATUS_RUNNING) printf "%s: [%s]" "$@" ;;
                MSG_MIHOMO_STATUS_STOPPED) printf "%s: [%s]" "$@" ;;
                MSG_MIHOMO_KERNEL_LINE) printf "%s: [%s]" "$@" ;;

                *) printf "%s" "$key" ;;
            esac
            ;;
    esac
}

# ClashFox 默认目录 - 默认值，可通过命令行参数或交互方式修改
CLASHFOX_DEFAULT_DIR="/Applications/ClashFox.app"
CLASHFOX_DIR="$CLASHFOX_DEFAULT_DIR"

# ClashFox 子目录定义
set_clashfox_subdirectories() {
    # ClashFox 内核目录
    CLASHFOX_CORE_DIR="$CLASHFOX_DIR/core"
    # ClashFox 默认配置文件路径
    CLASHFOX_CONFIG_DIR="$CLASHFOX_DIR/config"
    # ClashFox 数据目录
    CLASHFOX_DATA_DIR="$CLASHFOX_DIR/data"
    # ClashFox 日志目录
    CLASHFOX_LOG_DIR="$CLASHFOX_DIR/logs"
    # ClashFox PID 文件路径
    CLASHFOX_PID_DIR="$CLASHFOX_DIR/runtime"
}

# 初始化子目录
set_clashfox_subdirectories
# 当前激活的内核名称
ACTIVE_CORE="mihomo"

# 可选 GitHub 用户
GITHUB_USERS=("vernesong" "MetaCubeX")
# 默认分支
DEFAULT_BRANCH="Prerelease-Alpha"

# 终端颜色定义 - 和谐专业版
RED='\033[0;31m'          # 红色 - 错误信息（保持标准红色，确保警示性）
GREEN='\033[0;32m'        # 绿色 - 成功信息（保持标准绿色，确保清晰识别）
YELLOW='\033[0;33m'       # 黄色 - 提示和警告（使用标准黄色，避免过于刺眼）
BLUE='\033[1;34m'         # 亮蓝色 - 主色调，用于标题和重要信息（突出但不刺眼）
CYAN='\033[0;36m'         # 青色 - 状态信息和功能说明（保持专业感）
PURPLE='\033[0;35m'       # 紫色 - 强调信息（降低亮度，避免与其他颜色冲突）
GRAY='\033[0;37m'         # 灰色 - 辅助信息（新增，用于次要文本）
WHITE='\033[1;37m'        # 白色 - 强调文本（新增，用于需要突出的普通文本）
NC='\033[0m'              # 重置颜色（保持不变）

# 检查是否在 macOS 上运行
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_fmt "$(tr_msg MSG_MACOS_ONLY)"
    exit 1
fi

#========================
# 清屏函数
#========================
clear_screen() {
    clear
}

#========================
# 显示标题
#========================
show_title() {
    clear_screen

    log_fmt "${PURPLE}=============================================================================${NC}"
    log_fmt "${PURPLE}                         🦊  $SCRIPT_NAME 🦊${NC}"
    log_fmt "${PURPLE}=============================================================================${NC}"
    log_fmt "${CYAN}[$(tr_msg TAG_VERSION)]: ${WHITE} $SCRIPT_VERSION${NC}"
    log_blank

    # 显示欢迎提示
    log_fmt "${YELLOW}[$(tr_msg TAG_WARNING)]${NC} $(tr_msg MSG_WELCOME "${GRAY}$USER" "$SCRIPT_NAME") !${NC}"
    log_blank
}

#========================
# 显示分隔线
#========================
show_separator() {
    log_fmt "${BLUE}------------------------------------------------------------${NC}"
}

# Menu column width can be overridden via CLASHFOX_MENU_WIDTH
MENU_COL_WIDTH="${CLASHFOX_MENU_WIDTH:-}"

menu_col_width() {
    if [[ "$MENU_COL_WIDTH" =~ ^[0-9]+$ ]]; then
        echo "$MENU_COL_WIDTH"
        return
    fi
    local cols
    cols=$(tput cols 2>/dev/null)
    if [ -z "$cols" ] || [ "$cols" -le 0 ]; then
        cols=80
    fi
    local width=$(( (cols - 3) / 2 ))
    if [ "$width" -lt 28 ]; then
        width=28
    fi
    echo "$width"
}

display_width() {
    local s="$1"
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$s" <<'PY'
import sys
import unicodedata
s = sys.argv[1]
width = 0
for ch in s:
    if unicodedata.east_asian_width(ch) in ("W", "F"):
        width += 2
    else:
        width += 1
print(width)
PY
        return
    fi
    echo "${#s}"
}

pad_right() {
    local s="$1"
    local width="$2"
    local w
    w=$(display_width "$s")
    if [ "$w" -ge "$width" ]; then
        printf "%s" "$s"
        return
    fi
    printf "%s%*s" "$s" "$((width - w))" ""
}

# Two-column menu output helper for alignment
print_menu_two_cols() {
    local left="$1"
    local right="$2"
    local color_prefix="$3"
    local color_suffix="$4"
    local width
    local line
    width="$(menu_col_width)"
    line="$(pad_right "$left" "$width") $right"
    if [ -n "$color_prefix" ]; then
        log_fmt "  ${color_prefix}${line}${color_suffix}"
    else
        log_fmt "  ${line}"
    fi
}

#========================
# 公共日志输出方法
#========================

log_fmt() {
    # 获取参数个数
    local arg_count=$#

    case $arg_count in
        0)
            # 无参数时输出空行
            printf "\n"
            ;;
        1)
            # 一个参数时只输出该参数
            printf "%b\n" "$1${NC}"
            ;;
        2)
            # 两个参数时保持现有行为：参数1 + 空格 + 参数2
            printf "%b %b\n" "$1" "$2${NC}"
            ;;
        *)
            # 三个或更多参数时，用空格连接所有参数
            local output=""
            for arg in "$@"; do
                output="$output$arg "
            done
            printf "%b\n" "${output% }${NC}"  # 移除末尾的空格
            ;;
    esac
}

# 输出成功消息（绿色）
log_success() {
    printf "%b\n" "${GREEN}[$(tr_msg TAG_SUCCESS)] $1${NC}"
}

# 输出错误消息（红色）
log_error() {
    printf "%b\n" "${RED}[$(tr_msg TAG_ERROR)] $1${NC}"
}

# 输出警告/提示消息（黄色）
log_warning() {
    printf "%b\n" "${YELLOW}[$(tr_msg TAG_WARNING)] $1${NC}"
}

# 输出功能/状态消息（青色）
log_highlight() {
    printf "%b\n" "${CYAN}[$1] $2${NC}"
}

# 输出空行
log_blank() {
    printf "\n"
}

#========================
# 等待用户按键
#========================
wait_for_key() {
    log_blank
    read -p "$(tr_msg MSG_PRESS_ENTER)"
}

#========================
# 请求 sudo 权限
#========================
request_sudo_permission() {
    # 先静默检查是否已经有 sudo 权限
    if sudo -n true 2>/dev/null; then
        # 保持 sudo 权限有效期（后台进程，每60秒刷新一次）
        sudo -v -s >/dev/null 2>&1 <<-EOF
            while true; do
                sudo -n true >/dev/null 2>&1  # 静默刷新 sudo 权限
                sleep 60                      # 等待60秒
                kill -0 "$$" 2>/dev/null || exit  # 检查主进程是否存活，否则退出
            done &
EOF
        return 0  # 已有权限，直接返回成功，不输出任何提示
    fi


    # 只有在需要授权时才显示提示信息
    log_fmt "${RED}========================================================================${NC}"
    log_fmt "${RED}⚠️  $(tr_msg MSG_REQUIRE_SUDO_TITLE)${NC}"
    log_fmt "${RED}========================================================================${NC}"
    log_fmt "${RED}$(tr_msg MSG_REQUIRE_SUDO_DESC)${NC}"
    log_fmt "${RED}$(tr_msg MSG_REQUIRE_SUDO_PROMPT)${NC}"
    log_blank

    if sudo -v 2>/dev/null; then
        # 保持 sudo 权限有效期（后台进程，每60秒刷新一次）
        sudo -v -s >/dev/null 2>&1 <<-EOF
            while true; do
                sudo -n true >/dev/null 2>&1  # 静默刷新 sudo 权限
                sleep 60                      # 等待60秒
                kill -0 "$$" 2>/dev/null || exit  # 检查主进程是否存活，否则退出
            done &
EOF
        log_success "$(tr_msg MSG_SUDO_OK)"
        # 清屏并重新显示标题
        clear_screen
        show_title
    else
        log_error "$(tr_msg MSG_SUDO_FAIL)"
        return 1
    fi
}

#========================
# 检查并创建必要的目录结构
#========================
check_and_create_directories() {
    log_fmt "${BLUE}$(tr_msg MSG_INIT_CHECK_DIRS)"

    # 检查是否有足够权限创建目录
    if [ ! -w "$(dirname "$CLASHFOX_DIR")" ]; then
        log_warning "$(tr_msg MSG_NEED_ADMIN)"
        if ! request_sudo_permission; then
            log_error "$(tr_msg MSG_NO_PERMISSION)"
            return 1
        fi
    fi

    # 检查并创建内核目录
    if [ ! -d "$CLASHFOX_CORE_DIR" ]; then
        log_warning "$(tr_msg MSG_CORE_DIR_CREATE "$CLASHFOX_CORE_DIR")"
        sudo mkdir -p "$CLASHFOX_CORE_DIR"
    fi
    log_success "$(tr_msg MSG_CORE_DIR_EXISTS "$CLASHFOX_CORE_DIR")"

    # 检查并创建配置目录
    if [ ! -d "$CLASHFOX_CONFIG_DIR" ]; then
        log_warning "$(tr_msg MSG_CONFIG_DIR_CREATE "$CLASHFOX_CONFIG_DIR")"
        sudo mkdir -p "$CLASHFOX_CONFIG_DIR"
    fi
    log_success "$(tr_msg MSG_CONFIG_DIR_EXISTS "$CLASHFOX_CONFIG_DIR")"

    # 检查并创建数据目录
    if [ ! -d "$CLASHFOX_DATA_DIR" ]; then
        log_warning "$(tr_msg MSG_DATA_DIR_CREATE "$CLASHFOX_DATA_DIR")"
        sudo mkdir -p "$CLASHFOX_DATA_DIR"
    fi
    log_success "$(tr_msg MSG_DATA_DIR_EXISTS "$CLASHFOX_DATA_DIR")"

    # 检查并创建日志目录
    if [ ! -d "$CLASHFOX_LOG_DIR" ]; then
        log_warning "$(tr_msg MSG_LOG_DIR_CREATE "$CLASHFOX_LOG_DIR")"
        sudo mkdir -p "$CLASHFOX_LOG_DIR"
    fi
    log_success "$(tr_msg MSG_LOG_DIR_EXISTS "$CLASHFOX_LOG_DIR")"

    # 检查并创建运行时目录
    if [ ! -d "$CLASHFOX_PID_DIR" ]; then
        log_warning "$(tr_msg MSG_RUNTIME_DIR_CREATE "$CLASHFOX_PID_DIR")"
        sudo mkdir -p "$CLASHFOX_PID_DIR"
    fi
    log_success "$(tr_msg MSG_RUNTIME_DIR_EXISTS "$CLASHFOX_PID_DIR")"

    # 设置目录权限，确保当前用户可以访问
    log_fmt "${BLUE}$(tr_msg MSG_INIT_SET_PERMS)"
    sudo chown -R "$USER:admin" "$CLASHFOX_DIR"
    sudo chmod -R 755 "$CLASHFOX_DIR"
    log_success "$(tr_msg MSG_DIRS_PERMS_OK)"
}


#========================
# 检查内核目录
#========================
require_core_dir() {
    if [ ! -d "$CLASHFOX_CORE_DIR" ]; then
        log_warning "$(tr_msg MSG_CORE_DIR_MISSING_CREATE)"
        if ! check_and_create_directories; then
            log_error "$(tr_msg MSG_DIR_CREATE_FAIL)"
            wait_for_key
            return 1
        fi
    fi

    cd "$CLASHFOX_CORE_DIR" || {
        log_error "$(tr_msg MSG_CORE_DIR_ENTER_FAIL)"
        wait_for_key
        return 1
    }
    return 0
}

#============================
# 检查 Mihomo 状态并显示完整信息
#============================
check_mihomo_status() {
    local status
    status="$(tr_msg MSG_STATUS_STOPPED)"
    local exit_code=1

    # 快速检查：首先尝试不使用 sudo 检查进程状态（最快）
    if pgrep -x "$ACTIVE_CORE" > /dev/null 2>&1; then
        status="$(tr_msg MSG_STATUS_RUNNING)"
        exit_code=0
    # 如果快速检查失败，静默尝试使用 sudo 检查（不触发完整的权限请求流程）
    elif sudo -n pgrep -x "$ACTIVE_CORE" > /dev/null 2>&1; then
        status="$(tr_msg MSG_STATUS_RUNNING)"
        exit_code=0
    # 如果需要交互式sudo权限，才调用完整的权限请求函数
    elif ! sudo -n true > /dev/null 2>&1; then
        # 确保有sudo权限
        if request_sudo_permission; then
            if sudo pgrep -x "$ACTIVE_CORE" > /dev/null 2>&1; then
                status="$(tr_msg MSG_STATUS_RUNNING)"
                exit_code=0
            fi
        fi
    fi

    # 显示Mihomo状态
    if [ "$status" = "$(tr_msg MSG_STATUS_RUNNING)" ]; then
        log_fmt "$(tr_msg MSG_MIHOMO_STATUS_RUNNING "$(tr_msg MSG_STATUS_LABEL)" "${GREEN}$status${NC}")"
    else
        log_fmt "$(tr_msg MSG_MIHOMO_STATUS_STOPPED "$(tr_msg MSG_STATUS_LABEL)" "${RED}$status${NC}")"
    fi

    # 显示Mihomo版本
    MIHOMO_VERSION=$(get_mihomo_version)
    log_fmt "$(tr_msg MSG_MIHOMO_KERNEL_LINE "$(tr_msg MSG_KERNEL_LABEL)" "${GREEN}$MIHOMO_VERSION${NC}")"

    # 显示配置文件状态
    if [ -f "$CLASHFOX_CONFIG_DIR/default.yaml" ]; then
        log_fmt "$(tr_msg MSG_MIHOMO_CONFIG_FOUND "${GREEN}$CLASHFOX_CONFIG_DIR/default.yaml${NC}")"
    else
        log_fmt "$(tr_msg MSG_MIHOMO_CONFIG_NOT_FOUND "${YELLOW}$CLASHFOX_CONFIG_DIR/default.yaml${NC}")"
    fi

    # 返回原始的状态值和退出码
    return $exit_code
}

#========================
# 显示当前状态
#========================
show_status() {
    clear_screen
    show_title

    # 确保有sudo权限
    if ! request_sudo_permission; then
        return
    fi

    show_separator
    log_highlight "$(tr_msg LABEL_FUNCTION)" "$(tr_msg MSG_KERNEL_STATUS_CHECK)"
    show_separator

    # 内核运行状态
    log_fmt "\n${BLUE}$(tr_msg MSG_STATUS_SECTION)${NC}"
    check_mihomo_status

    # 目录和内核文件检查
    if require_core_dir; then
        log_fmt "\n${BLUE}$(tr_msg MSG_KERNEL_FILES_SECTION)${NC}"

        if [ -f "$ACTIVE_CORE" ]; then
            log_fmt "  ${GREEN}$(tr_msg MSG_KERNEL_FILE_OK)${NC}"

            if [ -x "$ACTIVE_CORE" ]; then
                CURRENT_RAW=$("./$ACTIVE_CORE" -v 2>/dev/null | head -n1)
                log_fmt "  ${BLUE}$(tr_msg MSG_KERNEL_VERSION_INFO "$CURRENT_RAW")${NC}"

                if [[ "$CURRENT_RAW" =~ ^Mihomo[[:space:]]+Meta[[:space:]]+([^[:space:]]+)[[:space:]]+darwin[[:space:]]+(amd64|arm64) ]]; then
                    CURRENT_VER="${BASH_REMATCH[1]}"
                    CURRENT_ARCH="${BASH_REMATCH[2]}"
                    CURRENT_DISPLAY="mihomo-darwin-${CURRENT_ARCH}-${CURRENT_VER}"
                    log_fmt "  ${BLUE}$(tr_msg MSG_KERNEL_DISPLAY_NAME "${RED}$CURRENT_DISPLAY${NC}")"
                else
                    log_fmt "  ${BLUE}$(tr_msg MSG_KERNEL_DISPLAY_NAME_PARSE_FAIL "${RED}$ACTIVE_CORE${NC}")"
                fi
            else
                log_fmt "  ${RED}$(tr_msg MSG_KERNEL_FILE_NOEXEC)${NC}"
            fi
        else
            log_fmt "  ${RED}$(tr_msg MSG_KERNEL_FILE_MISSING)${NC}"
        fi

        # 备份信息检查
        log_fmt "\n${BLUE}$(tr_msg MSG_BACKUP_SECTION)${NC}"
        LATEST=$(ls -1t mihomo.backup.* 2>/dev/null | head -n1)

        if [ -n "$LATEST" ]; then
            log_fmt "  ${GREEN}$(tr_msg MSG_BACKUP_FOUND)${NC}"
            log_fmt "  ${BLUE}$(tr_msg MSG_BACKUP_LATEST "$LATEST")"

            if [[ "$LATEST" =~ ^mihomo\.backup\.mihomo-darwin-(amd64|arm64)-(.+)\.([0-9]{8}_[0-9]{6})$ ]]; then
                BACKUP_VER="${BASH_REMATCH[2]}"
                BACKUP_TIMESTAMP="${BASH_REMATCH[3]}"
                log_fmt "  ${BLUE}$(tr_msg MSG_BACKUP_VERSION "${RED}$BACKUP_VER${NC}")"
                log_fmt "  ${BLUE}$(tr_msg MSG_BACKUP_TIME "${YELLOW}$BACKUP_TIMESTAMP${NC}")"
            else
                log_fmt "  ${BLUE}$(tr_msg MSG_BACKUP_VERSION_UNKNOWN)"
            fi
        else
            log_fmt "  ${YELLOW}$(tr_msg MSG_BACKUP_NONE)${NC}"
        fi
    fi

    wait_for_key
}

#========================
# 列出所有备份
#========================
show_list_backups() {
    show_title
    show_separator
    log_highlight "$(tr_msg LABEL_FUNCTION)" "$(tr_msg MSG_LIST_BACKUPS_TITLE)"
    show_separator

    if ! require_core_dir; then
        return
    fi

    BACKUP_FILES=$(ls -1 mihomo.backup.* 2>/dev/null)
    if [ -z "$BACKUP_FILES" ]; then
        log_fmt "${YELLOW}$(tr_msg MSG_NO_BACKUPS)${NC}"
        wait_for_key
        return
    fi

    log_fmt "${BLUE}$(tr_msg MSG_BACKUP_LIST_TITLE)${NC}"
    log_fmt "$(tr_msg MSG_BACKUP_LIST_COLUMNS)"
    # 创建临时数组存储备份信息
    declare -a backup_list=()

    # 收集所有备份文件的时间戳和文件名
    while read -r f; do
        if [[ "$f" =~ ^mihomo\.backup\.mihomo-darwin-(amd64|arm64)-.+\.([0-9]{8}_[0-9]{6})$ ]]; then
            TS="${BASH_REMATCH[2]}"
            # 格式：时间戳 文件名（时间戳在前以便排序）
            backup_list+=("$TS $f")
        fi
    done <<< "$BACKUP_FILES"

    # 按时间戳倒序排序
    IFS=$'\n' sorted_backups=($(sort -r <<< "${backup_list[*]}"))
    unset IFS

    # 显示排序后的备份列表
    i=1
    for backup in "${sorted_backups[@]}"; do
        # 分离时间戳和文件名
        TS=$(echo "$backup" | cut -d' ' -f1)
        f=$(echo "$backup" | cut -d' ' -f2-)

        # 提取版本信息
        if [[ "$f" =~ ^mihomo\.backup\.(mihomo-darwin-(amd64|arm64)-.+)\.[0-9]{8}_[0-9]{6}$ ]]; then
            VERSION_CLEAN="${BASH_REMATCH[1]}"
            printf "   %2d   | ${RED}%s${NC} | ${YELLOW}%s${NC}\n" "$i" "$VERSION_CLEAN" "$TS"
            i=$((i+1))
        fi
    done

    log_blank
    log_fmt "${GREEN}$(tr_msg MSG_BACKUP_TOTAL "$((i-1))")${NC}"
    wait_for_key
}

#========================
# 切换内核版本
#========================
switch_core() {
    show_title
    show_separator
    log_highlight "$(tr_msg LABEL_FUNCTION)" "$(tr_msg MSG_SWITCH_TITLE)"
    show_separator

    if ! require_core_dir; then
        return
    fi

    # 先列出所有备份
    list_backups_content

    # 让用户选择
    read -p "$(tr_msg MSG_SWITCH_PROMPT)" CHOICE

    if [ -z "$CHOICE" ]; then
        return
    fi

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
        log_error "$(tr_msg MSG_INVALID_NUMBER)"
        wait_for_key
        return
    fi

    # 获取所有备份文件并排序
    BACKUP_FILES_SORTED=$(ls -1t mihomo.backup.* 2>/dev/null | sort -r)

    # 根据选择获取目标备份
    TARGET_BACKUP=$(echo "$BACKUP_FILES_SORTED" | sed -n "${CHOICE}p")

    if [ -z "$TARGET_BACKUP" ]; then
        log_error "$(tr_msg MSG_BACKUP_NO_MATCH)"
        wait_for_key
        return
    fi

    log_blank
    log_fmt "${BLUE}$(tr_msg MSG_SWITCH_START)"
    log_fmt "${BLUE}$(tr_msg MSG_BACKUP_SELECTED "$TARGET_BACKUP")"

    # 显示当前内核信息
    if [ -f "$ACTIVE_CORE" ]; then
        CURRENT_RAW=$("./$ACTIVE_CORE" -v 2>/dev/null | head -n1 2>/dev/null)
        log_fmt "${BLUE}$(tr_msg MSG_CURRENT_KERNEL_VERSION "$CURRENT_RAW")"
    else
        log_fmt "${BLUE}$(tr_msg MSG_CURRENT_KERNEL_MISSING)"
    fi

    # 确认操作
    read -p "$(tr_msg MSG_SWITCH_CONFIRM)" CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_warning "$(tr_msg MSG_OP_CANCELLED)"
        wait_for_key
        return
    fi

    # 备份当前内核
    if [ -f "$ACTIVE_CORE" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        ROLLBACK_FILE="${ACTIVE_CORE}.bak.$TIMESTAMP"
        cp "$ACTIVE_CORE" "$ROLLBACK_FILE"
        log_fmt "${BLUE}$(tr_msg MSG_BACKUP_CURRENT_KERNEL "$ROLLBACK_FILE")"
    fi

    # 替换内核
    TMP_CORE="${ACTIVE_CORE}.tmp"
    cp "$TARGET_BACKUP" "$TMP_CORE"
    mv -f "$TMP_CORE" "$ACTIVE_CORE"
    chmod +x "$ACTIVE_CORE"
    log_fmt "${BLUE}$(tr_msg MSG_KERNEL_REPLACED "$TARGET_BACKUP")"

    # 删除临时备份
    rm -f "$ROLLBACK_FILE"
    log_fmt "${BLUE}$(tr_msg MSG_TEMP_BACKUP_REMOVED "$ROLLBACK_FILE")"

    log_fmt "${GREEN}$(tr_msg MSG_SWITCH_DONE)"
    wait_for_key
}

#========================
# 列出备份内容（用于切换功能）
#========================
list_backups_content() {
    BACKUP_FILES=$(ls -1 mihomo.backup.* 2>/dev/null)
    if [ -z "$BACKUP_FILES" ]; then
        log_fmt "${YELLOW}$(tr_msg MSG_NO_BACKUPS)${NC}"
        wait_for_key
        return 1
    fi

    log_fmt "${BLUE}$(tr_msg MSG_LIST_BACKUPS_SIMPLE_TITLE)"
    log_fmt "$(tr_msg MSG_BACKUP_LIST_COLUMNS)"
    show_separator

    i=1
    echo "$BACKUP_FILES" | while read -r f; do
        TS=$(echo "$f" | sed -E 's/^mihomo\.backup\.mihomo-darwin-(amd64|arm64)-.+\.([0-9]{8}_[0-9]{6})$/\2/')
        echo "$TS $f"
    done | sort -r | while read -r TS f; do
        VERSION_CLEAN=$(echo "$f" | sed -E 's/^mihomo\.backup\.(mihomo-darwin-(amd64|arm64)-.+)\.[0-9]{8}_[0-9]{6}$/\1/')
        printf "%2d   | ${RED}%s${NC} | ${YELLOW}%s${NC}\n" "$i" "$VERSION_CLEAN" "$TS"
        i=$((i+1))
    done
    log_blank
    return 0
}

#========================
# 安装内核
#========================
install_core() {
    show_title
    log_highlight "$(tr_msg LABEL_FUNCTION)" "$(tr_msg MSG_INSTALL_TITLE)"
    show_separator

    if ! require_core_dir; then
        return
    fi

    VERSION_BRANCH="$DEFAULT_BRANCH"

    # 选择 GitHub 用户
    log_fmt "${BLUE}$(tr_msg MSG_SELECT_GITHUB_USER)${NC}"
    for i in "${!GITHUB_USERS[@]}"; do
        echo "  $((i+1))) ${GITHUB_USERS[$i]}"
    done
    read -p "$(tr_msg MSG_SELECT_USER_PROMPT)" CHOICE

    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#GITHUB_USERS[@]}" ]; then
        GITHUB_USER="${GITHUB_USERS[$((CHOICE-1))]}"
    else
        GITHUB_USER="${GITHUB_USERS[0]}"
    fi

    log_fmt "${BLUE}$(tr_msg MSG_SELECTED_GITHUB_USER "${GREEN}$GITHUB_USER${NC}")"
    log_blank

    # 获取版本信息
    VERSION_URL="https://github.com/${GITHUB_USER}/mihomo/releases/download/$VERSION_BRANCH/version.txt"
    BASE_DOWNLOAD_URL="https://github.com/${GITHUB_USER}/mihomo/releases/download/$VERSION_BRANCH"

    log_fmt "${BLUE}$(tr_msg MSG_GET_VERSION_INFO)"
    VERSION_INFO=$(curl -sL "$VERSION_URL")

    if [ -z "$VERSION_INFO" ] || echo "$VERSION_INFO" | grep -iq "Not Found"; then
        log_error "$(tr_msg MSG_VERSION_INFO_FAIL)"
        wait_for_key
        return 1
    fi

    # 解析版本号
    if [ "$VERSION_BRANCH" = "Prerelease-Alpha" ]; then
        VERSION_HASH=$(echo "$VERSION_INFO" | grep -oE 'alpha(-smart)?-[0-9a-f]+' | head -1)
    else
        VERSION_HASH=$(echo "$VERSION_INFO" | head -1)
    fi

    log_fmt "${BLUE}$(tr_msg MSG_VERSION_INFO "${GREEN}$VERSION_HASH${NC}")"

    # 检测架构
    ARCH_RAW="$(uname -m)"
    if [ "$ARCH_RAW" = "arm64" ]; then
        MIHOMO_ARCH="arm64"
    elif [ "$ARCH_RAW" = "x86_64" ]; then
        MIHOMO_ARCH="amd64"
    else
        log_error "$(tr_msg MSG_ARCH_UNSUPPORTED "$ARCH_RAW")"
        wait_for_key
        return 1
    fi

    log_fmt "${BLUE}$(tr_msg MSG_ARCH_DETECTED "${YELLOW}$MIHOMO_ARCH${NC}")"

    # 构建下载信息
    VERSION="mihomo-darwin-${MIHOMO_ARCH}-${VERSION_HASH}"
    DOWNLOAD_URL="${BASE_DOWNLOAD_URL}/${VERSION}.gz"

    log_fmt "${BLUE}$(tr_msg MSG_DOWNLOAD_INFO)"
    log_fmt "$(tr_msg MSG_DOWNLOAD_URL "$DOWNLOAD_URL")"
    log_fmt "$(tr_msg MSG_VERSION_LABEL "$VERSION")"
    log_blank

    # 确认安装
    read -p "$(tr_msg MSG_DOWNLOAD_CONFIRM)" CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_warning "$(tr_msg MSG_OP_CANCELLED)"
        wait_for_key
        return
    fi

    # 下载并安装
    TMP_FILE="$(mktemp)"
    log_fmt "${BLUE}$(tr_msg MSG_DOWNLOAD_START)"

    # 增加下载重试机制（最多3次）
    DOWNLOAD_SUCCESS=0
    MAX_RETRIES=3
    RETRY_COUNT=0

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -fL "$DOWNLOAD_URL" -o "$TMP_FILE" -#; then
            DOWNLOAD_SUCCESS=1
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                log_warning "$(tr_msg MSG_DOWNLOAD_RETRY "$RETRY_COUNT" "$MAX_RETRIES")"
                sleep 5  # 等待5秒后重试
            fi
        fi
    done

    if [ $DOWNLOAD_SUCCESS -eq 1 ]; then
        log_success "$(tr_msg MSG_DOWNLOAD_OK)"

        log_fmt "${BLUE}$(tr_msg MSG_EXTRACT_START)"
        if gunzip -c "$TMP_FILE" > "$ACTIVE_CORE"; then
            chmod +x "$ACTIVE_CORE"
            rm -f "$TMP_FILE"

            # 备份新安装的内核（无论是否是首次安装）
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            BACKUP_FILE="mihomo.backup.${VERSION}.${TIMESTAMP}"
            cp "$ACTIVE_CORE" "$BACKUP_FILE"
            log_fmt "${BLUE}$(tr_msg MSG_BACKUP_NEW_KERNEL "${YELLOW}$BACKUP_FILE${NC}")"

            log_fmt "${GREEN}$(tr_msg MSG_INSTALL_DONE)"
        else
            log_error "$(tr_msg MSG_EXTRACT_FAIL)"
            rm -f "$TMP_FILE"
        fi
    else
        log_error "$(tr_msg MSG_DOWNLOAD_FAIL "$MAX_RETRIES")"
        rm -f "$TMP_FILE"
    fi

    wait_for_key
}

# 获取 Mihomo 版本
get_mihomo_version() {
    if [ -x "$CLASHFOX_CORE_DIR/$ACTIVE_CORE" ]; then
        CURRENT_RAW=$("$CLASHFOX_CORE_DIR/$ACTIVE_CORE" -v 2>/dev/null | head -n1)
        if [[ "$CURRENT_RAW" =~ ^Mihomo[[:space:]]+Meta[[:space:]]+([^[:space:]]+)[[:space:]]+darwin[[:space:]]+(amd64|arm64) ]]; then
            CURRENT_VER="${BASH_REMATCH[1]}"
            echo "$CURRENT_VER"
        else
            tr_msg MSG_VERSION_PARSE_FAIL
        fi
    else
        tr_msg MSG_NOT_INSTALLED
    fi
}
start_mihomo_kernel() {
    show_title

    # 验证用户权限
    if ! request_sudo_permission; then
        wait_for_key
        return
    fi

    show_separator
    log_highlight "$(tr_msg LABEL_FUNCTION)" "$(tr_msg MSG_START_TITLE)"
    show_separator

    if ! require_core_dir; then
        return
    fi

    # 检查内核是否已在运行
    if check_mihomo_status | grep -q "$(tr_msg MSG_STATUS_RUNNING)"; then
        log_warning "$(tr_msg MSG_KERNEL_RUNNING)"
        wait_for_key
        return
    fi

    log_fmt "${BLUE}$(tr_msg MSG_START_PRECHECK)"

    # 检查内核文件是否存在且可执行
    if [ ! -f "$ACTIVE_CORE" ]; then
        log_error "$(tr_msg MSG_KERNEL_NOT_FOUND)"
        wait_for_key
        return
    fi

    if [ ! -x "$ACTIVE_CORE" ]; then
        log_error "$(tr_msg MSG_KERNEL_NOT_EXEC)"
        log_fmt "${BLUE}$(tr_msg MSG_ADD_EXEC)"
        chmod +x "$ACTIVE_CORE"
        if [ $? -ne 0 ]; then
            log_error "$(tr_msg MSG_ADD_EXEC_FAIL)"
            wait_for_key
            return
        fi
    fi

    # 配置文件检查 - 增加更详细的检查逻辑
    CONFIG_PATH="$CLASHFOX_CONFIG_DIR/default.yaml"

    # 检查默认配置文件是否存在
    if [ ! -f "$CONFIG_PATH" ]; then
        log_error "$(tr_msg MSG_CONFIG_DEFAULT_MISSING "$CONFIG_PATH")"
        log_fmt "${BLUE}$(tr_msg MSG_CONFIG_SCAN)"

        # 列出配置目录中的所有yaml文件
        CONFIG_FILES=$(find "$CLASHFOX_CONFIG_DIR" -name "*.yaml" -o -name "*.yml" -o -name "*.json" 2>/dev/null)

        if [ -z "$CONFIG_FILES" ]; then
            log_error "$(tr_msg MSG_CONFIG_NONE)"
            log_warning "$(tr_msg MSG_CONFIG_PUT_HINT "$CLASHFOX_CONFIG_DIR")"
            wait_for_key
            return
        fi

        log_fmt "${BLUE}$(tr_msg MSG_CONFIG_AVAILABLE)"
        log_fmt "$(tr_msg MSG_CONFIG_LIST_COLUMNS)"
        show_separator

        # 将配置文件列表转换为数组并显示
        IFS=$'\n' read -r -d '' -a CONFIG_FILE_ARRAY <<< "$CONFIG_FILES"
        for i in "${!CONFIG_FILE_ARRAY[@]}"; do
            log_fmt "  ${BLUE}$((i+1)))${NC} ${CONFIG_FILE_ARRAY[$i]}"
        done

        # 让用户选择配置文件
        log_blank
        read -p "$(tr_msg MSG_CONFIG_SELECT_PROMPT)" CONFIG_CHOICE

        if [ "$CONFIG_CHOICE" -eq 0 ] 2>/dev/null; then
            log_warning "$(tr_msg MSG_OP_CANCELLED)"
            wait_for_key
            return
        elif [ "$CONFIG_CHOICE" -ge 1 ] && [ "$CONFIG_CHOICE" -le "${#CONFIG_FILE_ARRAY[@]}" ] 2>/dev/null; then
            CONFIG_PATH="${CONFIG_FILE_ARRAY[$((CONFIG_CHOICE-1))]}"
            log_success "$(tr_msg MSG_CONFIG_SELECTED "$CONFIG_PATH")"
        else
            log_error "$(tr_msg MSG_CONFIG_INVALID)"
            wait_for_key
            return
        fi
    fi

    # 设置配置文件选项
    CONFIG_OPTION="-f $CONFIG_PATH"

    # 检查配置文件是否可读
    if [ ! -r "$CONFIG_PATH" ]; then
        log_error "$(tr_msg MSG_CONFIG_READ_FAIL "$CONFIG_PATH")"
        log_warning "$(tr_msg MSG_CONFIG_PERM_HINT)"
        wait_for_key
        return
    fi

    # 检查配置文件是否非空
    if [ ! -s "$CONFIG_PATH" ]; then
        log_error "$(tr_msg MSG_CONFIG_EMPTY "$CONFIG_PATH")"
        log_warning "$(tr_msg MSG_CONFIG_EMPTY_HINT)"
        wait_for_key
        return
    fi

    log_success "$(tr_msg MSG_CONFIG_WILL_USE "$CONFIG_PATH")"

    # 启动内核
    log_fmt "${BLUE}$(tr_msg MSG_START_PROCESS)"
    sudo nohup ./$ACTIVE_CORE $CONFIG_OPTION -d $CLASHFOX_DATA_DIR >> "$CLASHFOX_LOG_DIR/clashfox.log" 2>&1 &
    log_success "$(tr_msg MSG_START_COMMAND "nohup ./$ACTIVE_CORE $CONFIG_OPTION -d $CLASHFOX_DATA_DIR >> $CLASHFOX_LOG_DIR/clashfox.log 2>&1 &")"
    PID=$!

    sleep 5

    # 将PID写入文件
    echo $PID > "$CLASHFOX_PID_DIR/clashfox.pid"
    log_success "$(tr_msg MSG_PID_WRITTEN "$CLASHFOX_PID_DIR/clashfox.pid")"

    # 等待内核启动
    sleep 2

    # 检查内核是否启动成功
    if ps -p $PID > /dev/null 2>&1; then
        log_success "$(tr_msg MSG_KERNEL_STARTED)"
        log_success "$(tr_msg MSG_PROCESS_ID "$PID")"
    else
        log_error "$(tr_msg MSG_KERNEL_START_FAIL)"
    fi

    wait_for_key
}

#========================
# 关闭 Mihomo 内核
#========================
kill_mihomo_kernel() {
    show_title

    # 验证用户权限
    if ! request_sudo_permission; then
        wait_for_key
        continue
    fi

    show_separator
    log_highlight "$(tr_msg LABEL_FUNCTION)" "$(tr_msg MSG_STOP_TITLE)"
    show_separator

    if ! require_core_dir; then
        return
    fi

    # 检查内核是否在运行
    if ! check_mihomo_status | grep -q "$(tr_msg MSG_STATUS_RUNNING)"; then
        log_warning "$(tr_msg MSG_KERNEL_NOT_RUNNING)"
        wait_for_key
        return
    fi

    log_fmt "${BLUE}$(tr_msg MSG_STOPPING_KERNEL)"

    # 获取 Mihomo 进程 ID（使用 sudo 确保能找到所有用户的进程）
    local pids=$(sudo pgrep -x "$ACTIVE_CORE")

    if [ -n "$pids" ]; then
        log_success "$(tr_msg MSG_PIDS_FOUND "$pids")"

        # 尝试正常关闭进程
        for pid in $pids; do
            log_fmt "${BLUE}$(tr_msg MSG_STOPPING_PROCESS "$pid")"
            sudo kill "$pid" 2>/dev/null
        done

        # 等待进程关闭
        sleep 2

        # 检查是否还有进程在运行
        local remaining_pids=$(sudo pgrep -x "$ACTIVE_CORE")
        if [ -n "$remaining_pids" ]; then
            log_warning "$(tr_msg MSG_FORCE_STOPPING)"
            for pid in $remaining_pids; do
                sudo kill -9 "$pid" 2>/dev/null
            done
        fi

        # 再次检查
        if sudo pgrep -x "$ACTIVE_CORE" > /dev/null 2>&1; then
            log_error "$(tr_msg MSG_KERNEL_STOP_FAIL)"
            log_warning "$(tr_msg MSG_KERNEL_STOP_HINT)"
        else
            log_success "$(tr_msg MSG_KERNEL_STOPPED)"
        fi
    else
        log_warning "$(tr_msg MSG_PROCESS_NOT_RUNNING)"
    fi

    # 清理PID文件（修复：检查正确的PID文件路径）
    PID_FILE="$CLASHFOX_PID_DIR/clashfox.pid"
    if [ -f "$PID_FILE" ]; then
        rm -f "$PID_FILE"
        log_success "$(tr_msg MSG_PID_CLEANED "$PID_FILE")"
    fi

    wait_for_key
}

#========================
# 重启 Mihomo 内核
#========================
restart_mihomo_kernel() {
    show_title

    # 验证用户权限
    if ! request_sudo_permission; then
        wait_for_key
        continue
    fi

    show_separator
    log_highlight "$(tr_msg LABEL_FUNCTION)" "$(tr_msg MSG_RESTART_TITLE)"
    show_separator

    if ! require_core_dir; then
        return
    fi

    # 先关闭内核
    kill_mihomo_kernel

    # 清除标题和分隔线
    clear_screen

    # 再启动内核
    start_mihomo_kernel
}

#========================
# 内核控制菜单
#========================
manage_kernel_menu() {
    while true; do
        show_title

        # 验证用户权限
        if ! request_sudo_permission; then
            wait_for_key
            continue
        fi

        show_separator
        log_highlight "$(tr_msg LABEL_FUNCTION)" "$(tr_msg MSG_KERNEL_MENU_TITLE)"
        show_separator

        # 显示当前内核状态
        check_mihomo_status

        log_blank
        log_fmt "${BLUE}$(tr_msg MSG_KERNEL_MENU_PROMPT)${NC}"
        log_fmt "  $(tr_msg MSG_MENU_START)"
        log_fmt "  $(tr_msg MSG_MENU_STOP)"
        log_fmt "  $(tr_msg MSG_MENU_RESTART)"
        log_fmt "  $(tr_msg MSG_MENU_BACK)"
        log_blank

        read -p "$(tr_msg MSG_MENU_CHOICE_0_3)" CHOICE

        case "$CHOICE" in
            1)
                start_mihomo_kernel
                ;;
            2)
                kill_mihomo_kernel
                ;;
            3)
                restart_mihomo_kernel
                ;;
            0)
                return
                ;;
            *)
                log_error "$(tr_msg MSG_MENU_INVALID)"
                wait_for_key
                ;;
        esac
    done
}

#========================
# 查看 Mihomo 内核日志
#========================
show_logs() {
    show_title
    show_separator
    log_highlight "$(tr_msg LABEL_FUNCTION)" "$(tr_msg MSG_LOGS_TITLE)"
    show_separator

    LOG_FILE="$CLASHFOX_LOG_DIR/clashfox.log"

    if [ ! -f "$LOG_FILE" ]; then
        log_warning "$(tr_msg MSG_LOG_FILE_MISSING "$LOG_FILE")"
        log_warning "$(tr_msg MSG_LOG_FILE_HINT)"
        wait_for_key
        return
    fi

    log_fmt "${BLUE}$(tr_msg MSG_LOG_FILE_PATH "$LOG_FILE")"
    log_fmt "${BLUE}$(tr_msg MSG_LOG_FILE_SIZE "$(du -h "$LOG_FILE" | cut -f1)")"
    log_fmt "${BLUE}$(tr_msg MSG_LOG_FILE_LINES "$(wc -l < "$LOG_FILE")")"
    log_blank

    log_fmt "${GREEN}$(tr_msg MSG_LOG_VIEW_OPTIONS)${NC}"
    log_fmt "  $(tr_msg MSG_LOG_OPTION_TAIL)"
    log_fmt "  $(tr_msg MSG_LOG_OPTION_FOLLOW)"
    log_fmt "  $(tr_msg MSG_LOG_OPTION_LESS)"
    log_fmt "  $(tr_msg MSG_LOG_OPTION_BACK)"
    log_blank

    read -p "$(tr_msg MSG_MENU_CHOICE_0_3)" CHOICE

    case "$CHOICE" in
        1)
            log_blank
            log_fmt "${BLUE}$(tr_msg MSG_LOG_TAIL_HEADER)"
            log_fmt "------------------------------------------------------------------------"
            tail -n 50 "$LOG_FILE"
            log_fmt "------------------------------------------------------------------------"
            wait_for_key
            ;;
        2)
            log_blank
            log_fmt "${BLUE}$(tr_msg MSG_LOG_FOLLOW_HEADER)"
            log_fmt "------------------------------------------------------------------------"
            tail -f "$LOG_FILE"
            log_blank
            ;;
        3)
            log_blank
            log_fmt "${BLUE}$(tr_msg MSG_LOG_LESS_HEADER)"
            log_fmt "------------------------------------------------------------------------"
            less "$LOG_FILE"
            ;;
        0)
            return
            ;;
        *)
            log_error "$(tr_msg MSG_MENU_INVALID)"
            wait_for_key
            ;;
    esac

    # 再次显示日志菜单，方便连续查看
    show_logs
}

#========================
# 显示帮助信息
#========================
show_help() {
    show_title
    show_separator
    log_highlight "$(tr_msg LABEL_HELP)" "$(tr_msg MSG_HELP_TITLE)"
    show_separator
    log_fmt "${BLUE}$(tr_msg MSG_HELP_ARGS)${NC}"
    log_fmt "${BLUE}$(tr_msg MSG_HELP_DIR_ARG)${NC}"
    log_fmt "${BLUE}$(tr_msg MSG_HELP_LANG_ARG)${NC}"
    log_fmt "${BLUE}$(tr_msg MSG_HELP_STATUS)${NC}"
    log_fmt "${BLUE}$(tr_msg MSG_HELP_LIST)${NC}"
    log_fmt "${BLUE}$(tr_msg MSG_HELP_SWITCH)${NC}"
    log_fmt "${BLUE}$(tr_msg MSG_HELP_LOGS)${NC}"
    log_fmt "${BLUE}$(tr_msg MSG_HELP_CLEAN)${NC}"
    log_fmt "${BLUE}$(tr_msg MSG_HELP_HELP)${NC}"
    log_fmt "${BLUE}$(tr_msg MSG_HELP_VERSION)${NC}"
    log_blank
    log_fmt "${BLUE}$(tr_msg MSG_HELP_MENU)${NC}"
    print_menu_two_cols "$(tr_msg MSG_MENU_INSTALL)" "$(tr_msg MSG_MENU_CONTROL)" "$GRAY" "$NC"
    print_menu_two_cols "$(tr_msg MSG_MENU_STATUS)" "$(tr_msg MSG_MENU_SWITCH)" "$GRAY" "$NC"
    print_menu_two_cols "$(tr_msg MSG_MENU_LIST)" "$(tr_msg MSG_MENU_LOGS)" "$GRAY" "$NC"
    print_menu_two_cols "$(tr_msg MSG_MENU_CLEAN)" "$(tr_msg MSG_MENU_HELP)" "$GRAY" "$NC"
    log_fmt "  ${GRAY}$(tr_msg MSG_MENU_EXIT)${NC}"
    log_blank
    log_warning "$(tr_msg MSG_HELP_NOTE)"

    wait_for_key
}

#========================
# 清理旧日志文件
#========================
clean_logs() {
    show_title
    show_separator
    log_highlight "$(tr_msg LABEL_FUNCTION)" "$(tr_msg MSG_CLEAN_TITLE)"
    show_separator

    LOG_FILE="$CLASHFOX_LOG_DIR/clashfox.log"
    LOG_BACKUPS="$CLASHFOX_LOG_DIR/clashfox.log.*.gz"

    log_fmt "${BLUE}$(tr_msg MSG_CLEAN_CURRENT_LOG "$LOG_FILE")"
    log_fmt "${BLUE}$(tr_msg MSG_CLEAN_LOG_SIZE "$(du -h "$LOG_FILE" 2>/dev/null | cut -f1)")"
    log_fmt "${BLUE}$(tr_msg MSG_CLEAN_OLD_COUNT "$(ls -l $LOG_BACKUPS 2>/dev/null | wc -l)")"
    log_fmt "${BLUE}$(tr_msg MSG_CLEAN_OLD_SIZE "$(du -ch $LOG_BACKUPS 2>/dev/null | tail -n 1 | cut -f1)")"
    log_blank

    log_fmt "${GREEN}$(tr_msg MSG_CLEAN_OPTIONS)${NC}"
    log_fmt "  $(tr_msg MSG_CLEAN_ALL)"
    log_fmt "  $(tr_msg MSG_CLEAN_7D)"
    log_fmt "  $(tr_msg MSG_CLEAN_30D)"
    log_fmt "  $(tr_msg MSG_CLEAN_CANCEL)"
    log_blank

    read -p "$(tr_msg MSG_CLEAN_PROMPT)" CHOICE

    case "$CHOICE" in
        1)
            rm -f $LOG_BACKUPS
            log_success "$(tr_msg MSG_CLEAN_DONE_ALL)"
            ;;
        2)
            # 保留最近7天的日志
            find "$CLASHFOX_LOG_DIR" -name "clashfox.log.*.gz" -mtime +7 -delete
            log_success "$(tr_msg MSG_CLEAN_DONE_7D)"
            ;;
        3)
            # 保留最近30天的日志
            find "$CLASHFOX_LOG_DIR" -name "clashfox.log.*.gz" -mtime +30 -delete
            log_success "$(tr_msg MSG_CLEAN_DONE_30D)"
            ;;
        0)
            log_warning "$(tr_msg MSG_CLEAN_CANCELLED)"
            ;;
        *)
            log_error "$(tr_msg MSG_CLEAN_INVALID)"
            ;;
    esac

    wait_for_key
}

#========================
# 日志滚动功能（支持按大小和按日期备份）
#========================
rotate_logs() {
    LOG_FILE="$CLASHFOX_LOG_DIR/clashfox.log"
    MAX_SIZE=10  # MB
    BACKUP_DIR="$CLASHFOX_LOG_DIR"
    CURRENT_DATE=$(date +%Y%m%d)

    if [ ! -f "$LOG_FILE" ]; then
        return
    fi

    # 检查日志的最后修改日期
    if [ -f "$LOG_FILE" ]; then
        LOG_MODIFY_DATE=$(stat -f "%Sm" -t "%Y%m%d" "$LOG_FILE")

        # 如果日志是昨天或更早的，进行日期备份
        if [ "$LOG_MODIFY_DATE" != "$CURRENT_DATE" ]; then
            # 创建按日期命名的备份文件
            DATE_BACKUP_FILE="$BACKUP_DIR/clashfox.log.$LOG_MODIFY_DATE.gz"

            # 如果备份文件已存在，添加时间戳避免覆盖
            if [ -f "$DATE_BACKUP_FILE" ]; then
                DATE_BACKUP_FILE="$BACKUP_DIR/clashfox.log.$LOG_MODIFY_DATE.$(date +%H%M%S).gz"
            fi

            # 压缩并备份旧日志
            gzip -c "$LOG_FILE" > "$DATE_BACKUP_FILE"
            # 清空当前日志
            > "$LOG_FILE"
            log_warning "$(tr_msg MSG_LOG_ROTATE_DATE "$DATE_BACKUP_FILE")"
        fi
    fi

    # 保留按大小滚动的功能
    LOG_SIZE=$(du -m "$LOG_FILE" | cut -f1)
    if [ "$LOG_SIZE" -ge "$MAX_SIZE" ]; then
        # 创建带时间戳的备份文件
        SIZE_BACKUP_FILE="$BACKUP_DIR/clashfox.log.$(date +%Y%m%d_%H%M%S).gz"
        gzip -c "$LOG_FILE" > "$SIZE_BACKUP_FILE"
        # 清空当前日志
        > "$LOG_FILE"
        log_warning "$(tr_msg MSG_LOG_ROTATE_SIZE "$SIZE_BACKUP_FILE")"
    fi
}

#========================
# 显示主菜单
#========================
show_main_menu() {
    show_title
    show_separator
    log_highlight "$(tr_msg LABEL_STATUS)" "$(tr_msg MSG_MAIN_STATUS_TITLE)"
    show_separator
    check_mihomo_status
    log_blank
    show_separator
    log_highlight "$(tr_msg LABEL_FUNCTION)" "$(tr_msg MSG_MAIN_MENU_TITLE)"
    show_separator
    log_fmt "${BLUE}$(tr_msg MSG_MAIN_PROMPT)${NC}"
    print_menu_two_cols "$(tr_msg MSG_MENU_INSTALL)" "$(tr_msg MSG_MENU_CONTROL)"
    print_menu_two_cols "$(tr_msg MSG_MENU_STATUS)" "$(tr_msg MSG_MENU_SWITCH)"
    print_menu_two_cols "$(tr_msg MSG_MENU_LIST)" "$(tr_msg MSG_MENU_LOGS)"
    print_menu_two_cols "$(tr_msg MSG_MENU_CLEAN)" "$(tr_msg MSG_MENU_HELP)"
    log_fmt "  $(tr_msg MSG_MENU_EXIT)"
    log_blank
}

#========================
# 程序退出时的清理函数
#========================
cleanup() {
    # 只在有实际清理操作时才输出日志
    if [ -n "$LOG_CHECKER_PID" ]; then
        # 终止日志检查后台进程
        log_fmt "${BLUE}$(tr_msg MSG_CLEANUP_STOPPING "$LOG_CHECKER_PID")"

        # 先尝试正常终止
        kill "$LOG_CHECKER_PID" 2>/dev/null

        # 等待进程终止
        local timeout=5
        while ps -p "$LOG_CHECKER_PID" > /dev/null 2>&1 && [ $timeout -gt 0 ]; do
            sleep 1
            ((timeout--))
        done

        # 如果进程仍然存在，尝试强制终止
        if ps -p "$LOG_CHECKER_PID" > /dev/null 2>&1; then
            log_fmt "${BLUE}$(tr_msg MSG_CLEANUP_FORCE)"
            kill -9 "$LOG_CHECKER_PID" 2>/dev/null
        fi

        # 等待进程终止
        wait "$LOG_CHECKER_PID" 2>/dev/null

        # 输出终止结果
        if ps -p "$LOG_CHECKER_PID" > /dev/null 2>&1; then
            log_fmt "${BLUE}$(tr_msg MSG_CLEANUP_FAIL "$LOG_CHECKER_PID")"
        else
            log_success "$(tr_msg MSG_CLEANUP_OK)"
        fi
    fi
}

# 注册退出处理函数 - 只处理异常退出
trap 'cleanup; log_fmt "${RED}$(tr_msg MSG_EXIT_ABNORMAL)${NC}"; exit 1' SIGINT SIGTERM SIGTSTP

#========================
# 命令行参数解析
#========================
parse_arguments() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -d|--directory)
                shift
                if [ -n "$1" ]; then
                    # 确保目录以ClashFox结尾
                    if [[ "$1" != *"/ClashFox"* ]]; then
                        if [[ "$1" == */ ]]; then
                            CLASHFOX_DIR="${1}ClashFox"
                        else
                            CLASHFOX_DIR="${1}/ClashFox"
                        fi
                    else
                        CLASHFOX_DIR="$1"
                    fi
                    set_clashfox_subdirectories

                    # 保存选择的目录
                    save_directory

                    shift
                else
                    log_error "$(tr_msg MSG_ARG_DIR_REQUIRED)"
                    exit 1
                fi
                ;;
            -l|--lang)
                shift
                if [ -n "$1" ]; then
                    case "$1" in
                        zh|en|auto)
                            CLASHFOX_LANG="$1"
                            ;;
                        *)
                            log_error "$(tr_msg MSG_ARG_LANG_INVALID "$1")"
                            exit 1
                            ;;
                    esac
                    shift
                else
                    log_error "$(tr_msg MSG_ARG_LANG_REQUIRED)"
                    exit 1
                fi
                ;;
            --lang=*|-l=*)
                LANG_VALUE="${1#*=}"
                if [ -n "$LANG_VALUE" ]; then
                    case "$LANG_VALUE" in
                        zh|en|auto)
                            CLASHFOX_LANG="$LANG_VALUE"
                            ;;
                        *)
                            log_error "$(tr_msg MSG_ARG_LANG_INVALID "$LANG_VALUE")"
                            exit 1
                            ;;
                    esac
                else
                    log_error "$(tr_msg MSG_ARG_LANG_REQUIRED)"
                    exit 1
                fi
                shift
                ;;
            status)
                show_status
                exit 0
                ;;
            list)
                show_list_backups
                exit 0
                ;;
            switch)
                switch_core
                exit 0
                ;;
            logs|log)
                show_logs
                exit 0
                ;;
            clean|clear)
                clean_logs
                exit 0
                ;;
            help|-h)
                show_help
                exit 0
                ;;
            version|-v)
                show_title
                exit 0
                ;;
            *)
                if [ -n "$1" ]; then
                    log_error "$(tr_msg MSG_UNKNOWN_COMMAND "$1")"
                    log_warning "$(tr_msg MSG_AVAILABLE_COMMANDS)"
                    log_warning "$(tr_msg MSG_AVAILABLE_ARGS)"
                    exit 1
                fi
                ;;
        esac
    done
}

#========================
# 读取保存的自定义目录
#========================
read_saved_directory() {
    # 配置文件路径
    CONFIG_FILE="$HOME/.clashfox/config"

    # 如果配置文件存在且可读
    if [ -f "$CONFIG_FILE" ] && [ -r "$CONFIG_FILE" ]; then
        # 读取保存的目录
        SAVED_DIR=$(cat "$CONFIG_FILE")

        # 验证保存的目录是否有效
        if [ -n "$SAVED_DIR" ]; then
            CLASHFOX_DIR="$SAVED_DIR"
            set_clashfox_subdirectories
            log_success "$(tr_msg MSG_SAVED_DIR_LOADED "$CLASHFOX_DIR")"
            return 0
        fi
    fi

    # 没有找到有效配置，使用默认目录
    log_warning "$(tr_msg MSG_SAVED_DIR_NOT_FOUND "$CLASHFOX_DIR")"
    return 1
}

# 读取保存的自定义目录
read_saved_directory

#========================
# 保存自定义目录到配置文件
#========================
save_directory() {
    # 配置文件路径
    CONFIG_FILE="$HOME/.clashfox/config"

    # 创建配置文件目录
    mkdir -p "$(dirname "$CONFIG_FILE")"

    # 保存当前目录到配置文件
    echo "$CLASHFOX_DIR" > "$CONFIG_FILE"

    # 设置权限
    chmod 600 "$CONFIG_FILE"

    log_success "$(tr_msg MSG_DIR_SAVED "$CONFIG_FILE")"
    return 0
}

#========================
# 主程序
#========================
main() {
    # 检查是否有命令行参数
    if [ $# -gt 0 ]; then
        parse_arguments "$@"
    fi
    show_title

    # 程序启动时请求一次sudo权限
    if ! request_sudo_permission; then
        wait_for_key
        exit 1  # 改为exit，因为这里不是循环结构
    fi

    # 交互式询问用户是否修改默认目录 - 仅首次使用时提示
    if [ ! -d "$CLASHFOX_DIR" ]; then
        show_separator
        log_highlight "$(tr_msg LABEL_INIT)" "$(tr_msg MSG_DIR_SELECT_TITLE)"
        show_separator
        log_fmt "$(tr_msg MSG_DEFAULT_DIR_CURRENT "${GREEN}$CLASHFOX_DIR${NC}")"
        log_blank
        read -p "$(tr_msg MSG_USE_DEFAULT_DIR)" USE_DEFAULT_DIR

        if [[ ! "$USE_DEFAULT_DIR" =~ ^[Yy]$ ]]; then
            read -p "$(tr_msg MSG_CUSTOM_DIR_PROMPT)" CUSTOM_DIR

            # 验证目录路径
            if [ -n "$CUSTOM_DIR" ]; then
                # 确保目录以ClashFox结尾
                if [[ "$CUSTOM_DIR" != *"/ClashFox"* ]]; then
                    if [[ "$CUSTOM_DIR" == */ ]]; then
                        CLASHFOX_DIR="${CUSTOM_DIR}ClashFox"
                    else
                        CLASHFOX_DIR="${CUSTOM_DIR}/ClashFox"
                    fi
                else
                    CLASHFOX_DIR="$CUSTOM_DIR"
                fi
                set_clashfox_subdirectories
                log_success "$(tr_msg MSG_DIR_SET "$CLASHFOX_DIR")"

                # 保存选择的目录
                save_directory
            else
                log_warning "$(tr_msg MSG_DIR_INVALID_FALLBACK "$CLASHFOX_DIR")"
            fi
        else
            log_success "$(tr_msg MSG_DIR_USE_DEFAULT "$CLASHFOX_DIR")"

            # 保存选择的目录
            save_directory
        fi
        log_blank
        sleep 3
    else
        # 非首次使用，直接使用现有目录
        set_clashfox_subdirectories
        log_success "$(tr_msg MSG_DIR_EXISTING "$CLASHFOX_DIR")"
    fi

    # 调用日志回滚
    rotate_logs

    # 确保所有必要目录都已创建
    if ! require_core_dir; then
        return
    fi

    # 启动定期检查日志的后台进程（每30分钟检查一次）
    log_fmt "${BLUE}$(tr_msg MSG_LOG_CHECKER_START)"
    while true; do
        # 定期调用日志滚动函数
        rotate_logs
        # 等待30分钟
        sleep 1800
        # 检查主进程是否还在运行，不在则退出
        kill -0 "$$" || exit 0
    done 2>/dev/null &

    # 保存后台进程的PID
    LOG_CHECKER_PID=$!
    log_success "$(tr_msg MSG_LOG_CHECKER_OK "$LOG_CHECKER_PID")"
    log_blank

    # 检查 ClashFox 应用是否安装
    log_fmt "${BLUE}$(tr_msg MSG_APP_CHECK)"

    if [ ! -d "$CLASHFOX_DIR" ]; then
        log_warning "$(tr_msg MSG_APP_DIR_MISSING)"
        log_fmt "$(tr_msg MSG_APP_DIR_TARGET "$CLASHFOX_DIR")"
        # 如果主目录不存在，先创建主目录
        mkdir -p "$CLASHFOX_DIR"
        log_success "$(tr_msg MSG_APP_DIR_CREATED "$CLASHFOX_DIR")"
        log_blank
    else
        log_success "$(tr_msg MSG_APP_DIR_EXISTS "$CLASHFOX_DIR")"
        log_blank
    fi

    # 主循环
    while true; do
        show_main_menu

        read -p "$(tr_msg MSG_MAIN_CHOICE)" CHOICE

        case "$CHOICE" in
            1)
                install_core
                ;;
            2)
                manage_kernel_menu
                ;;
            3)
                show_status
                ;;
            4)
                switch_core
                ;;
            5)
                show_list_backups
                ;;
            6)
                show_logs
                ;;
            7)
                clean_logs
                ;;
            8)
                show_help
                ;;
            0)
                # 先执行清理操作
                log_blank
                cleanup
                log_blank
                # 然后输出感谢信息，确保它是最后一行
                log_fmt "${GREEN}$(tr_msg MSG_EXIT_THANKS)${NC}"
                exit 0
                ;;
            *)
                log_error "$(tr_msg MSG_MENU_INVALID)"
                wait_for_key
                ;;
        esac
    done
}

# 执行主程序
main "$@"
