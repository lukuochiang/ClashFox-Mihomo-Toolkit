#!/bin/bash

# -----------------------------------------------------------------------------
# ClashFox Mihomo Kernel Management CLI
# Copyright (c) 2026 Kuochiang Lu
# Licensed under the MIT License.
# -----------------------------------------------------------------------------

# Author: Kuochiang Lu
# Version: 1.2.1
# Last Updated: 2026-01-27
#
# 描述：
#   ClashFox mihomo Kernel Manager 是一个功能完整的 mihomo 内核管理工具，
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
SCRIPT_VERSION="v1.2.0"

# ClashFox 目录
CLASHFOX_DIR="/Applications/ClashFox"
# ClashFox 内核目录
CLASHFOX_CORE_DIR="$CLASHFOX_DIR/bin"
# ClashFox 默认配置文件路径
CLASHFOX_CONFIG_DIR="$CLASHFOX_DIR/config"
# ClashFox 数据目录
CLASHFOX_DATA_DIR="$CLASHFOX_DIR/data"
# ClashFox 日志目录
CLASHFOX_LOG_DIR="$CLASHFOX_DIR/logs"
# ClashFox PID 文件路径
CLASHFOX_PID_DIR="$CLASHFOX_DIR/runtime"
# 当前激活的内核名称
ACTIVE_CORE="mihomo"

# 可选 GitHub 用户
GITHUB_USERS=("vernesong" "MetaCubeX")
# 默认分支
DEFAULT_BRANCH="Prerelease-Alpha"

# 颜色
RED='\033[0;31m'          # 红色 - 错误信息
GREEN='\033[0;32m'        # 绿色 - 成功信息
YELLOW='\033[1;33m'       # 黄色 - 提示和警告
BLUE='\033[0;34m'         # 蓝色 - 主色调，用于标题和重要信息
PURPLE='\033[0;35m'       # 紫色 - 强调信息
CYAN='\033[0;36m'         # 青色 - 状态信息和功能说明
NC='\033[0m'              # 重置颜色

# 清屏命令
clear_screen() {
    clear
}

# 显示标题
show_title() {
    clear_screen
    echo -e "${CYAN}===============================================================${NC}"
    echo -e "${CYAN}                    $SCRIPT_NAME${NC}"
    echo -e "${CYAN}===============================================================${NC}"
    echo -e "${CYAN}版本: $SCRIPT_VERSION${NC}"
    echo ""
}

# 显示分隔线
show_separator() {
    echo -e "${BLUE}----------------------------------------${NC}"
}

# 等待用户按键
wait_for_key() {
    echo ""
    read -p "按 Enter 键继续..."
}

#========================
# 检查内核目录
#========================
require_core_dir() {
    echo -e "${BLUE}[步骤] 检查 ClashFox 内核目录...${NC}"

    if [ ! -d "$CLASHFOX_CORE_DIR" ]; then
        echo -e "${RED}[错误] 内核目录不存在: $CLASHFOX_CORE_DIR${NC}"
        wait_for_key
        return 1
    fi

    cd "$CLASHFOX_CORE_DIR" || {
        echo -e "${RED}[错误] 无法进入内核目录${NC}";
        wait_for_key;
        return 1;
    }

    echo -e "${GREEN}[成功] 当前目录: $CLASHFOX_CORE_DIR${NC}"
    return 0
}

#========================
# 显示当前状态
#========================
show_status() {
    clear_screen
    show_title
    echo ""
    echo -e "${CYAN}[功能] 显示内核状态${NC}"
    show_separator

    if ! require_core_dir; then
        return
    fi

    if [ -f "$ACTIVE_CORE" ]; then
        echo "[信息] 内核文件存在"
        if [ -x "$ACTIVE_CORE" ]; then
            CURRENT_RAW=$("./$ACTIVE_CORE" -v 2>/dev/null | head -n1)
            echo "[信息] 内核版本: $CURRENT_RAW"
            if [[ "$CURRENT_RAW" =~ ^Mihomo[[:space:]]+Meta[[:space:]]+([^[:space:]]+)[[:space:]]+darwin[[:space:]]+(amd64|arm64) ]]; then
                CURRENT_VER="${BASH_REMATCH[1]}"
                CURRENT_ARCH="${BASH_REMATCH[2]}"
                CURRENT_DISPLAY="mihomo-darwin-${CURRENT_ARCH}-${CURRENT_VER}"
            else
                CURRENT_DISPLAY="$ACTIVE_CORE (无法解析)"
            fi
        else
            CURRENT_DISPLAY="$ACTIVE_CORE (不可执行)"
        fi
        echo -e "当前内核: $ACTIVE_CORE -> ${RED}$CURRENT_DISPLAY${NC}"
    else
        echo -e "${RED}内核文件不存在${NC}"
    fi

    echo ""
    echo -e "${BLUE}[步骤] 检查备份信息${NC}"
    LATEST=$(ls -1t mihomo.backup.* 2>/dev/null | head -n1)
    if [ -n "$LATEST" ]; then
        echo "[信息] 最新备份: $LATEST"
        if [[ "$LATEST" =~ ^(mihomo\.backup\.(mihomo-darwin-(amd64|arm64)-.+))\.([0-9]{8}_[0-9]{6})$ ]]; then
            BACKUP_VER="${BASH_REMATCH[2]}"
            BACKUP_TIMESTAMP="${BASH_REMATCH[4]}"
        else
            BACKUP_VER="未知版本"
            BACKUP_TIMESTAMP=""
        fi
        echo -e "最新备份版本: ${RED}$BACKUP_VER${NC}, 时间戳: ${YELLOW}$BACKUP_TIMESTAMP${NC}"
    else
        echo -e "${YELLOW}未找到任何备份${NC}"
    fi

    wait_for_key
}

#========================
# 列出所有备份
#========================
show_list_backups() {
    show_title
    echo -e "${CYAN}[功能] 列出所有备份内核${NC}"
    show_separator

    if ! require_core_dir; then
        return
    fi

    BACKUP_FILES=$(ls -1 mihomo.backup.* 2>/dev/null)
    if [ -z "$BACKUP_FILES" ]; then
        echo -e "${YELLOW}无备份文件${NC}"
        wait_for_key
        return
    fi

    echo -e "${BLUE}可用备份内核列表（按时间倒序）:${NC}"
    echo "序号 | 版本信息 | 备份时间"
    show_separator

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
            printf "%2d   | ${RED}%s${NC} | ${YELLOW}%s${NC}\n" "$i" "$VERSION_CLEAN" "$TS"
            i=$((i+1))
        fi
    done

    echo ""
    echo -e "${GREEN}备份文件总数: $((i-1)) 个${NC}"
    wait_for_key
}

#========================
# 切换内核版本
#========================
switch_core() {
    show_title
    echo -e "${CYAN}[功能] 切换内核版本${NC}"
    show_separator

    if ! require_core_dir; then
        return
    fi

    # 先列出所有备份
    list_backups_content

    # 让用户选择
    read -p "请输入要切换的备份序号 (或按 Enter 返回主菜单): " CHOICE

    if [ -z "$CHOICE" ]; then
        return
    fi

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[错误] 请输入有效的数字${NC}"
        wait_for_key
        return
    fi

    # 获取所有备份文件并排序
    BACKUP_FILES_SORTED=$(ls -1t mihomo.backup.* 2>/dev/null | sort -r)

    # 根据选择获取目标备份
    TARGET_BACKUP=$(echo "$BACKUP_FILES_SORTED" | sed -n "${CHOICE}p")

    if [ -z "$TARGET_BACKUP" ]; then
        echo -e "${RED}[错误] 未找到匹配的备份序号${NC}"
        wait_for_key
        return
    fi

    echo ""
    echo -e "${BLUE}[步骤] 开始切换内核...${NC}"
    echo "[信息] 选择的备份文件: $TARGET_BACKUP"

    # 显示当前内核信息
    if [ -f "$ACTIVE_CORE" ]; then
        CURRENT_RAW=$("./$ACTIVE_CORE" -v 2>/dev/null | head -n1 2>/dev/null)
        echo "[信息] 当前内核版本: $CURRENT_RAW"
    else
        echo "[信息] 当前内核不存在"
    fi

    # 确认操作
    read -p "确定要切换到该版本吗? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[提示] 操作已取消${NC}"
        wait_for_key
        return
    fi

    # 备份当前内核
    if [ -f "$ACTIVE_CORE" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        ROLLBACK_FILE="${ACTIVE_CORE}.bak.$TIMESTAMP"
        cp "$ACTIVE_CORE" "$ROLLBACK_FILE"
        echo "[步骤] 已备份当前内核 -> $ROLLBACK_FILE"
    fi

    # 替换内核
    TMP_CORE="${ACTIVE_CORE}.tmp"
    cp "$TARGET_BACKUP" "$TMP_CORE"
    mv -f "$TMP_CORE" "$ACTIVE_CORE"
    chmod +x "$ACTIVE_CORE"
    echo "[步骤] 内核已替换为: $TARGET_BACKUP"

    # 删除临时备份
    rm -f "$ROLLBACK_FILE"
    echo "[步骤] 已删除临时备份文件: $ROLLBACK_FILE"

    echo -e "${GREEN}[完成] 内核切换完成${NC}"
    wait_for_key
}

# 列出备份内容（用于切换功能）
list_backups_content() {
    BACKUP_FILES=$(ls -1 mihomo.backup.* 2>/dev/null)
    if [ -z "$BACKUP_FILES" ]; then
        echo -e "${YELLOW}无备份文件${NC}"
        wait_for_key
        return 1
    fi

    echo -e "${BLUE}可用备份内核:${NC}"
    echo "序号 | 版本信息 | 备份时间"
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
    echo ""
    return 0
}

#========================
# 安装内核
#========================
install_core() {
    show_title
    echo -e "${CYAN}[功能] 安装/更新 Mihomo 内核${NC}"
    show_separator

    if ! require_core_dir; then
        #========================
        # 检查并创建必要的目录结构
        #========================
        check_and_create_directories
    fi

    VERSION_BRANCH="$DEFAULT_BRANCH"

    # 选择 GitHub 用户
    echo -e "${BLUE}选择 GitHub 用户下载内核:${NC}"
    for i in "${!GITHUB_USERS[@]}"; do
        echo "  $((i+1))) ${GITHUB_USERS[$i]}"
    done
    read -p "请选择用户（默认1）: " CHOICE

    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#GITHUB_USERS[@]}" ]; then
        GITHUB_USER="${GITHUB_USERS[$((CHOICE-1))]}"
    else
        GITHUB_USER="${GITHUB_USERS[0]}"
    fi

    echo -e "[信息] 选择的 GitHub 用户: ${GREEN}$GITHUB_USER${NC}"
    echo ""

    # 获取版本信息
    VERSION_URL="https://github.com/${GITHUB_USER}/mihomo/releases/download/$VERSION_BRANCH/version.txt"
    BASE_DOWNLOAD_URL="https://github.com/${GITHUB_USER}/mihomo/releases/download/$VERSION_BRANCH"

    echo -e "${BLUE}[步骤] 获取最新版本信息...${NC}"
    VERSION_INFO=$(curl -sL "$VERSION_URL")

    if [ -z "$VERSION_INFO" ] || echo "$VERSION_INFO" | grep -iq "Not Found"; then
        echo -e "${RED}[错误] 无法获取版本信息或版本不存在${NC}"
        wait_for_key
        return 1
    fi

    echo -e "[信息] 版本信息: ${GREEN}$VERSION_INFO${NC}"

    # 解析版本号
    if [ "$VERSION_BRANCH" = "Prerelease-Alpha" ]; then
        VERSION_HASH=$(echo "$VERSION_INFO" | grep -oE 'alpha(-smart)?-[0-9a-f]+' | head -1)
    else
        VERSION_HASH=$(echo "$VERSION_INFO" | head -1)
    fi

    echo -e "[信息] 解析版本号: ${RED}$VERSION_HASH${NC}"

    # 检测架构
    ARCH_RAW="$(uname -m)"
    if [ "$ARCH_RAW" = "arm64" ]; then
        MIHOMO_ARCH="arm64"
    elif [ "$ARCH_RAW" = "x86_64" ]; then
        MIHOMO_ARCH="amd64"
    else
        echo -e "${RED}[错误] 不支持的架构: $ARCH_RAW${NC}"
        wait_for_key
        return 1
    fi

    echo -e "[信息] 架构检测: ${YELLOW}$MIHOMO_ARCH${NC}"

    # 构建下载信息
    VERSION="mihomo-darwin-${MIHOMO_ARCH}-${VERSION_HASH}"
    DOWNLOAD_URL="${BASE_DOWNLOAD_URL}/${VERSION}.gz"

    echo -e "${BLUE}[步骤] 下载信息:${NC}"
    echo "  下载地址: $DOWNLOAD_URL"
    echo "  版本信息: $VERSION"
    echo ""

    # 确认安装
    read -p "确定要下载并安装此版本吗? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[提示] 操作已取消${NC}"
        wait_for_key
        return
    fi

    # 备份当前内核
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="mihomo.backup.${VERSION}.${TIMESTAMP}"

    if [ -f "$ACTIVE_CORE" ]; then
        cp "$ACTIVE_CORE" "$BACKUP_FILE"
        echo -e "[步骤] 已备份当前内核 -> ${YELLOW}$BACKUP_FILE${NC}"
    else
        echo -e "[步骤] 当前无内核文件，跳过备份"
    fi

    # 下载并安装
    TMP_FILE="$(mktemp)"
    echo -e "${BLUE}[步骤] 正在下载内核 (可能需要几分钟)...${NC}"

    if curl -fL "$DOWNLOAD_URL" -o "$TMP_FILE" -#; then
        echo -e "${GREEN}[成功] 下载完成${NC}"

        echo -e "${BLUE}[步骤] 正在解压内核...${NC}"
        if gunzip -c "$TMP_FILE" > "$ACTIVE_CORE"; then
            chmod +x "$ACTIVE_CORE"
            rm -f "$TMP_FILE"

            echo -e "${GREEN}[完成] 内核安装成功${NC}"
        else
            echo -e "${RED}[错误] 解压失败${NC}"
            rm -f "$TMP_FILE"
        fi
    else
        echo -e "${RED}[错误] 下载失败${NC}"
        rm -f "$TMP_FILE"
    fi

    wait_for_key
}

# 检查 Mihomo 进程状态
check_mihomo_status() {
    if sudo pgrep -x "$ACTIVE_CORE" > /dev/null 2>&1; then
        echo "已运行"
        return 0
    else
        echo "已停止"
        return 1
    fi
}

# 获取 Mihomo 版本
get_mihomo_version() {
    if [ -x "$CLASHFOX_CORE_DIR/$ACTIVE_CORE" ]; then
        CURRENT_RAW=$("$CLASHFOX_CORE_DIR/$ACTIVE_CORE" -v 2>/dev/null | head -n1)
        if [[ "$CURRENT_RAW" =~ ^Mihomo[[:space:]]+Meta[[:space:]]+([^[:space:]]+)[[:space:]]+darwin[[:space:]]+(amd64|arm64) ]]; then
            CURRENT_VER="${BASH_REMATCH[1]}"
            echo "$CURRENT_VER"
        else
            echo "无法解析"
        fi
    else
        echo "未安装"
    fi
}

# 请求 sudo 权限
request_sudo_permission() {
    echo -e "${YELLOW}[提示] 请输入密码以获取内核控制权限:${NC}"
    if sudo -v; then
        # 保持 sudo 权限有效期
        sudo -v -s <<EOF
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
EOF
        return 0
    else
        echo -e "${RED}[错误] 密码验证失败，请重新尝试${NC}"
        return 1
    fi
}

#========================
# 内核控制功能
#========================

#========================
# 启动 Mihomo 内核
#========================
start_mihomo_kernel() {
    show_title
    echo -e "${CYAN}[功能] 启动 Mihomo 内核${NC}"
    show_separator

    if ! require_core_dir; then
        return
    fi

    # 确保有sudo权限
    if ! request_sudo_permission; then
        return
    fi

    # 检查内核是否已在运行
    if check_mihomo_status | grep -q "已运行"; then
        echo -e "${YELLOW}[提示] Mihomo 内核已经在运行中${NC}"
        wait_for_key
        return
    fi

    echo -e "${BLUE}[步骤] 正在启动 Mihomo 内核...${NC}"

    # 检查内核文件是否存在且可执行
    if [ ! -f "$ACTIVE_CORE" ]; then
        echo -e "${RED}[错误] 未找到 Mihomo 内核文件${NC}"
        wait_for_key
        return
    fi

    if [ ! -x "$ACTIVE_CORE" ]; then
        echo -e "${RED}[错误] Mihomo 内核文件不可执行${NC}"
        echo -e "${BLUE}[步骤] 正在添加执行权限...${NC}"
        chmod +x "$ACTIVE_CORE"
        if [ $? -ne 0 ]; then
            echo -e "${RED}[错误] 添加执行权限失败${NC}"
            wait_for_key
            return
        fi
    fi

    # 配置文件设置
    CONFIG_PATH="$CLASHFOX_CONFIG_DIR/default.yaml"
    if [ -f "$CONFIG_PATH" ]; then
        CONFIG_OPTION="-f $CONFIG_PATH"
        echo -e "${GREEN}[信息] 将使用配置文件:${NC} $CONFIG_PATH"
    else
        echo -e "${RED}[错误] 配置文件不存在:${NC} $CONFIG_PATH"
        wait_for_key
        return
    fi

    # 数据目录设置
    CONFIG_PATH="$CLASHFOX_CONFIG_DIR/default.yaml"
    if [ -f "$CONFIG_PATH" ]; then
        CONFIG_OPTION="-f $CONFIG_PATH"
        echo -e "${GREEN}[信息] 将使用配置文件:${NC} $CONFIG_PATH"
    else
        echo -e "${RED}[错误] 配置文件不存在:${NC} $CONFIG_PATH"
        wait_for_key
        return
    fi

    # 数据目录设置
    if [ -d "$CLASHFOX_DATA_DIR" ]; then
        DATA_OPTION="-d $CLASHFOX_DATA_DIR"
        echo -e "${GREEN}[信息] 将使用数据目录:${NC} $CLASHFOX_DATA_DIR"
    else
        echo -e "${RED}[错误] 数据目录不存在:${NC} $CLASHFOX_DATA_DIR"
        wait_for_key
        return
    fi

    # 日志文件设置
    LOG_PATH="$CLASHFOX_LOG_DIR/clashfox.log"
    LOG_DIR=$(dirname "$LOG_PATH")
    if [ ! -d "$LOG_DIR" ]; then
        echo -e "${BLUE}[步骤] 创建日志目录...${NC}"
        mkdir -p "$LOG_DIR"
        if [ $? -ne 0 ]; then
            echo -e "${RED}[错误] 创建日志目录失败${NC}"
            wait_for_key
            return
        fi
        echo -e "${GREEN}[成功] 日志目录已创建:${NC} $LOG_DIR"
    fi

    echo -e "${GREEN}[信息] 将使用日志文件:${NC} $LOG_PATH"

    # 启动内核
    echo ""
    echo -e "${BLUE}[步骤] 正在启动内核进程...${NC}"
    sudo nohup ./$ACTIVE_CORE $CONFIG_OPTION $DATA_OPTION >> $LOG_PATH 2>&1 &
    echo -e "${GREEN}[信息] 启动命令:${NC} nohup ./$ACTIVE_CORE $CONFIG_OPTION $DATA_OPTION >> $LOG_PATH 2>&1 &"
    PID=$!

    sleep 5

    # 创建runtime目录（如果不存在）
    PID_DIR=$(dirname "$CLASHFOX_PID_DIR")
    if [ ! -d "$PID_DIR" ]; then
        echo -e "${BLUE}[步骤] 创建runtime目录...${NC}"
        mkdir -p "$PID_DIR"
    fi

    # 将PID写入文件
    echo $PID > "$CLASHFOX_PID_DIR/clashfox.pid"
    echo -e "${GREEN}[信息] PID已写入:${NC} $CLASHFOX_PID_DIR/clashfox.pid"

    # 等待内核启动
    sleep 2

    # 检查内核是否启动成功
    if ps -p $PID > /dev/null 2>&1; then
        echo -e "${GREEN}[成功] Mihomo 内核已启动${NC}"
        echo -e "${GREEN}[信息] 进程 ID:${NC} $PID"
        echo -e "${GREEN}[信息] 配置文件:${NC} $CONFIG_PATH"
        echo -e "${GREEN}[信息] 数据目录:${NC} $CLASHFOX_DATA_DIR"
        echo -e "${GREEN}[信息] 日志文件:${NC} $LOG_PATH"
    else
        echo -e "${RED}[错误] Mihomo 内核启动失败${NC}"
        echo -e "${YELLOW}[提示] 请检查配置文件是否正确${NC}"
        echo -e "${YELLOW}[提示] 可以使用 '显示当前状态' 功能检查配置文件${NC}"
    fi

    wait_for_key
}

# 关闭 Mihomo 内核
kill_mihomo_kernel() {
    show_title
    echo -e "${CYAN}[功能] 关闭 Mihomo 内核${NC}"
    show_separator

    if ! require_core_dir; then
        return
    fi

    # 确保有sudo权限
    if ! request_sudo_permission; then
        return
    fi

    # 检查内核是否在运行
    if ! check_mihomo_status | grep -q "已运行"; then
        echo -e "${YELLOW}[提示] Mihomo 内核当前未运行${NC}"
        wait_for_key
        return
    fi

    echo -e "${BLUE}[步骤] 正在关闭 Mihomo 内核...${NC}"

    # 获取 Mihomo 进程 ID（使用 sudo 确保能找到所有用户的进程）
    local pids=$(sudo pgrep -x "$ACTIVE_CORE")

    if [ -n "$pids" ]; then
        echo -e "${GREEN}[信息] 找到进程 ID:${NC} $pids"

        # 尝试正常关闭进程
        for pid in $pids; do
            echo -e "${BLUE}[步骤] 正在关闭进程 $pid...${NC}"
            sudo kill "$pid" 2>/dev/null
        done

        # 等待进程关闭
        sleep 2

        # 检查是否还有进程在运行
        local remaining_pids=$(sudo pgrep -x "$ACTIVE_CORE")
        if [ -n "$remaining_pids" ]; then
            echo -e "${YELLOW}[提示] 尝试强制关闭剩余进程...${NC}"
            for pid in $remaining_pids; do
                sudo kill -9 "$pid" 2>/dev/null
            done
        fi

        # 再次检查
        if sudo pgrep -x "$ACTIVE_CORE" > /dev/null 2>&1; then
            echo -e "${RED}[错误] 关闭 Mihomo 内核失败${NC}"
            echo -e "${YELLOW}[提示] 请尝试在 Activity Monitor 手动停止内核${NC}"
        else
            echo -e "${GREEN}[成功] Mihomo 内核已关闭${NC}"
        fi
    else
        echo -e "${YELLOW}[提示] Mihomo 内核进程当前未运行${NC}"
    fi

    # 清理PID文件（修复：检查正确的PID文件路径）
    PID_FILE="$CLASHFOX_PID_DIR/clashfox.pid"
    if [ -f "$PID_FILE" ]; then
        rm -f "$PID_FILE"
        echo -e "${GREEN}[成功] PID文件已清理:${NC} $PID_FILE"
    fi

    wait_for_key
}

# 重启 Mihomo 内核
restart_mihomo_kernel() {
    show_title
    echo -e "${CYAN}[功能] 重启 Mihomo 内核${NC}"
    show_separator

    if ! require_core_dir; then
        return
    fi

    # 确保有sudo权限
    if ! request_sudo_permission; then
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
        echo -e "${CYAN}[功能] 内核控制${NC}"
        show_separator

        # 验证用户权限
        if ! request_sudo_permission; then
            wait_for_key
            continue
        fi

        # 显示当前内核状态
        MIHOMO_STATUS=$(check_mihomo_status)
        if [ "$MIHOMO_STATUS" = "已运行" ]; then
            echo -e "当前内核状态: ${GREEN}$MIHOMO_STATUS${NC}"
        else
            echo -e "当前内核状态: ${RED}$MIHOMO_STATUS${NC}"
        fi

        echo ""
        echo -e "${BLUE}请选择内核操作:${NC}"
        echo "  1) 启动内核"
        echo "  2) 关闭内核"
        echo "  3) 重启内核"
        echo "  0) 返回主菜单"
        echo ""

        read -p "请输入选择 (0-3): " CHOICE

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
                echo -e "${RED}[错误] 无效的选择，请重新输入${NC}"
                wait_for_key
                ;;
        esac
    done
}

# 查看 Mihomo 内核日志
show_logs() {
    show_title
    echo -e "${CYAN}[功能] 查看 Mihomo 内核日志${NC}"
    show_separator

    LOG_FILE="$CLASHFOX_LOG_DIR/clashfox.log"

    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${YELLOW}[提示] 日志文件不存在:${NC} $LOG_FILE"
        echo -e "${YELLOW}[提示] 请先启动内核以生成日志文件${NC}"
        wait_for_key
        return
    fi

    echo -e "${BLUE}[信息] 日志文件路径:${NC} $LOG_FILE"
    echo -e "${BLUE}[信息] 日志大小:${NC} $(du -h "$LOG_FILE" | cut -f1)"
    echo -e "${BLUE}[信息] 日志行数:${NC} $(wc -l < "$LOG_FILE")"
    echo ""

    echo -e "${GREEN}[选项] 如何查看日志:${NC}"
    echo "  1) 查看日志的最后 50 行"
    echo "  2) 实时查看日志更新 (按 Ctrl+C 退出)"
    echo "  3) 使用 less 查看完整日志 (按 q 退出)"
    echo "  0) 返回主菜单"
    echo ""

    read -p "请输入选择 (0-3): " CHOICE

    case "$CHOICE" in
        1)
            echo ""
            echo -e "${BLUE}[日志] 最后 50 行内容:${NC}"
            echo "------------------------------------------------------------------------"
            tail -n 50 "$LOG_FILE"
            echo "------------------------------------------------------------------------"
            wait_for_key
            ;;
        2)
            echo ""
            echo -e "${BLUE}[日志] 实时查看更新 (按 Ctrl+C 退出):${NC}"
            echo "------------------------------------------------------------------------"
            tail -f "$LOG_FILE"
            echo ""
            ;;
        3)
            echo ""
            echo -e "${BLUE}[日志] 使用 less 查看完整日志 (按 q 退出):${NC}"
            echo "------------------------------------------------------------------------"
            less "$LOG_FILE"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}[错误] 无效的选择，请重新输入${NC}"
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
    echo -e "${CYAN}[功能] 帮助信息${NC}"
    show_separator

    echo -e "${BLUE}ClashFox Mihomo 内核管理器${NC}"
    echo -e "版本: ${YELLOW}$SCRIPT_VERSION${NC}"
    echo ""
    echo -e "${BLUE}功能说明:${NC}"
    echo "  1. 安装/更新 Mihomo 内核 - 从 GitHub 下载最新内核并安装"
    echo "  2. 切换内核版本 - 在已备份的内核版本之间切换"
    echo "  3. 查看当前状态 - 显示当前内核版本和最新备份信息"
    echo "  4. 列出所有备份 - 查看所有已备份的内核版本"
    echo "  5. 内核控制 (启动/关闭/重启) - 管理内核的运行状态"
    echo "  6. 查看内核日志"
    echo "  7. 清除日志"
    echo "  6. 显示帮助信息 - 显示此帮助内容"
    echo "  0. 退出程序 - 退出内核管理器"
    echo ""
    echo -e "${BLUE}新增功能:${NC}"
    echo "  - 完整的目录结构自动检查与创建"
    echo "  - 配置文件与日志目录的智能管理"
    echo "  - PID 文件管理确保进程安全控制"
    echo "  - 内核运行环境的完整性验证"
    echo ""
    echo -e "${BLUE}使用提示:${NC}"
    echo "  - 按数字键选择功能，然后按 Enter 键"
    echo "  - 在任何界面按 Enter 键返回上一级"
    echo ""
    echo -e "${YELLOW}[提示] 此工具不仅负责内核版本管理，还可以控制内核的运行状态（启动/关闭/重启）${NC}"

    wait_for_key
}

# 清理旧日志
clean_logs() {
    show_title
    echo -e "${CYAN}[功能] 清理旧日志文件${NC}"
    show_separator

    LOG_FILE="$CLASHFOX_LOG_DIR/clashfox.log"
    LOG_BACKUPS="$CLASHFOX_LOG_DIR/clashfox.log.*.gz"

    echo -e "${BLUE}[信息] 当前日志文件:${NC} $LOG_FILE"
    echo -e "${BLUE}[信息] 日志大小:${NC} $(du -h "$LOG_FILE" 2>/dev/null | cut -f1)"
    echo -e "${BLUE}[信息] 旧日志数量:${NC} $(ls -l $LOG_BACKUPS 2>/dev/null | wc -l)"
    echo -e "${BLUE}[信息] 旧日志总大小:${NC} $(du -ch $LOG_BACKUPS 2>/dev/null | tail -n 1 | cut -f1)"
    echo ""

    echo -e "${GREEN}[清理选项]${NC}"
    echo "  1) 删除所有旧日志文件"
    echo "  2) 保留最近7天的日志，删除更早的日志"
    echo "  3) 保留最近30天的日志，删除更早的日志"
    echo "  0) 取消操作"
    echo ""

    read -p "请选择清理方式 (0-3): " CHOICE

    case "$CHOICE" in
        1)
            rm -f $LOG_BACKUPS
            echo -e "${GREEN}[成功] 已删除所有旧日志文件${NC}"
            ;;
        2)
            # 保留最近7天的日志
            find "$CLASHFOX_LOG_DIR" -name "clashfox.log.*.gz" -mtime +7 -delete
            echo -e "${GREEN}[成功] 已删除7天前的日志文件${NC}"
            ;;
        3)
            # 保留最近30天的日志
            find "$CLASHFOX_LOG_DIR" -name "clashfox.log.*.gz" -mtime +30 -delete
            echo -e "${GREEN}[成功] 已删除30天前的日志文件${NC}"
            ;;
        0)
            echo -e "${YELLOW}[提示] 取消清理操作${NC}"
            ;;
        *)
            echo -e "${RED}[错误] 无效的选择${NC}"
            ;;
    esac

    wait_for_key
}

# 日志滚动功能（支持按大小和按日期备份）
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
            echo -e "${YELLOW}[提示] 日志已按日期备份:${NC} $DATE_BACKUP_FILE"
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
        echo -e "${YELLOW}[提示] 日志已按大小滚动:${NC} $SIZE_BACKUP_FILE"
    fi
}

#========================
# 检查并创建必要的目录结构
#========================
check_and_create_directories() {
    echo -e "${BLUE}[初始化] 检查目录结构...${NC}"

    # 检查是否有足够权限创建目录
    if [ ! -w "$(dirname "$CLASHFOX_DIR")" ]; then
        echo -e "${YELLOW}[提示] 需要管理员权限创建目录结构${NC}"
        if ! request_sudo_permission; then
            echo -e "${RED}[错误] 权限不足，无法创建目录结构${NC}"
            return 1
        fi
    fi

    # 检查并创建内核目录
    if [ ! -d "$CLASHFOX_CORE_DIR" ]; then
        echo -e "${YELLOW}[提示] 创建内核目录: $CLASHFOX_CORE_DIR${NC}"
        sudo mkdir -p "$CLASHFOX_CORE_DIR"
    fi
    echo -e "${GREEN}[成功] 内核目录存在: $CLASHFOX_CORE_DIR${NC}"

    # 检查并创建配置目录
    if [ ! -d "$CLASHFOX_CONFIG_DIR" ]; then
        echo -e "${YELLOW}[提示] 创建配置目录: $CLASHFOX_CONFIG_DIR${NC}"
        sudo mkdir -p "$CLASHFOX_CONFIG_DIR"
    fi
    echo -e "${GREEN}[成功] 配置目录存在: $CLASHFOX_CONFIG_DIR${NC}"

    # 检查并创建数据目录
    if [ ! -d "$CLASHFOX_DATA_DIR" ]; then
        echo -e "${YELLOW}[提示] 创建数据目录: $CLASHFOX_DATA_DIR${NC}"
        sudo mkdir -p "$CLASHFOX_DATA_DIR"
    fi
    echo -e "${GREEN}[成功] 数据目录存在: $CLASHFOX_DATA_DIR${NC}"

    # 检查并创建日志目录
    if [ ! -d "$CLASHFOX_LOG_DIR" ]; then
        echo -e "${YELLOW}[提示] 创建日志目录: $CLASHFOX_LOG_DIR${NC}"
        sudo mkdir -p "$CLASHFOX_LOG_DIR"
    fi
    echo -e "${GREEN}[成功] 日志目录存在: $CLASHFOX_LOG_DIR${NC}"

    # 检查并创建运行时目录
    if [ ! -d "$CLASHFOX_PID_DIR" ]; then
        echo -e "${YELLOW}[提示] 创建运行时目录: $CLASHFOX_PID_DIR${NC}"
        sudo mkdir -p "$CLASHFOX_PID_DIR"
    fi
    echo -e "${GREEN}[成功] 运行时目录存在: $CLASHFOX_PID_DIR${NC}"

    # 设置目录权限，确保当前用户可以访问
    echo -e "${BLUE}[初始化] 设置目录权限...${NC}"
    sudo chown -R "$USER:admin" "$CLASHFOX_DIR"
    sudo chmod -R 755 "$CLASHFOX_DIR"
    echo -e "${GREEN}[成功] 目录权限已设置${NC}"
}

#========================
# 显示主菜单
#========================
show_main_menu() {
    show_title

    # Mihomo 状态
    MIHOMO_STATUS=$(check_mihomo_status)
    if [ "$MIHOMO_STATUS" = "已运行" ]; then
        echo -e "Mihomo Status：${GREEN}$MIHOMO_STATUS${NC}"
    else
        echo -e "Mihomo Status：${RED}$MIHOMO_STATUS${NC}"
    fi

    # Mihomo 版本
    MIHOMO_VERSION=$(get_mihomo_version)
    echo -e "Mihomo Kernel：${CYAN}$MIHOMO_VERSION${NC}"

    if [ -f "$CLASHFOX_CONFIG_DIR/default.yaml" ]; then
        echo -e "Mihomo Config: ${GREEN}$CLASHFOX_CONFIG_DIR/default.yaml${NC}"
    else
        echo -e "Mihomo Config: ${YELLOW}未找到${NC}"
    fi

    echo ""

    echo -e "${BLUE}请选择要执行的功能:${NC}"
    echo "  1) 安装/更新 Mihomo 内核"
    echo "  2) 切换内核版本"
    echo "  3) 查看当前状态"
    echo "  4) 列出所有备份"
    echo "  5) 内核控制 (启动/关闭/重启)"
    echo "  6) 查看内核日志"
    echo "  7) 清除日志"
    echo "  8) 显示帮助信息"
    echo "  0) 退出程序"
    echo ""
}

# 程序退出时的清理函数
cleanup() {
    echo ""
    echo -e "${BLUE}[退出] 正在清理日志后台进程...${NC}"

    # 终止日志检查后台进程（如果存在）
    if [ -n "$LOG_CHECKER_PID" ]; then
        kill "$LOG_CHECKER_PID" 2>/dev/null
        wait "$LOG_CHECKER_PID" 2>/dev/null
        echo -e "${GREEN}[成功] 日志检查进程已终止${NC}"
    fi

    echo -e "${GREEN}[成功] 日志后台进程已清理${NC}"

}

# 注册退出处理函数 - 优化版本
trap 'cleanup; exit 1' SIGINT SIGTERM SIGTSTP
trap cleanup EXIT

#========================
# 命令行参数解析
#========================
parse_arguments() {
    case "$1" in
        status)
            echo -e "${BLUE}[命令行] 查看当前状态...${NC}"
            show_status
            exit 0
            ;;
        list)
            echo -e "${BLUE}[命令行] 列出所有备份...${NC}"
            show_list_backups
            exit 0
            ;;
        switch)
            echo -e "${BLUE}[命令行] 切换内核版本...${NC}"
            switch_core
            exit 0
            ;;
        logs|log)
            echo -e "${BLUE}[命令行] 查看内核日志...${NC}"
            show_logs
            exit 0
            ;;
        clean|clear)
            echo -e "${BLUE}[命令行] 清除日志...${NC}"
            clean_logs
            exit 0
            ;;
        help|-h|--help)
            show_help
            exit 0
            ;;
        version|-v|--version)
            show_title
            exit 0
            ;;
        *)
            if [ -n "$1" ]; then
                echo -e "${RED}[错误] 未知命令: $1${NC}"
                echo -e "${YELLOW}可用命令: status, list, switch, logs, clean, help, version${NC}"
                exit 1
            fi
            ;;
    esac
}

#========================
# 主程序
#========================
main() {
    # 检查是否有命令行参数
    if [ $# -gt 0 ]; then
        parse_arguments "$@"
    fi

    # 调用日志回滚
    rotate_logs

    # 程序启动时请求一次sudo权限
#    echo -e "${BLUE}[初始化] 请求程序执行权限...${NC}"
#    if ! request_sudo_permission; then
#        echo -e "${RED}[错误] 授权失败，程序无法正常运行${NC}"
#        exit 1
#    fi

    # 确保所有必要目录都已创建
    if ! require_core_dir; then
        return
    fi;

    # 启动定期检查日志的后台进程（每30分钟检查一次）
    echo -e "${BLUE}[初始化] 启动日志定期检查进程...${NC}"
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
    echo -e "${GREEN}[成功] 日志定期检查进程已启动，PID: ${LOG_CHECKER_PID}${NC}"
    echo ""

    # 检查 ClashFox 应用是否安装
    echo -e "${BLUE}[初始化] 检查 ClashFox 应用是否安装...${NC}"

    if [ ! -d "$CLASHFOX_DIR" ]; then
        echo -e "${YELLOW}[提示] ClashFox 应用目录不存在，正在创建...${NC}"
        echo "  目标目录: $CLASHFOX_DIR"
        # 如果主目录不存在，先创建主目录
        mkdir -p "$CLASHFOX_DIR"
        echo -e "${GREEN}[成功] 已创建 ClashFox 应用目录: $CLASHFOX_DIR${NC}"
        echo ""
    else
        echo -e "${GREEN}[成功] ClashFox 应用已安装: $CLASHFOX_DIR${NC}"
        echo ""
    fi

    echo -e "${GREEN}[成功] ClashFox 应用已安装: $CLASHFOX_DIR${NC}"
    echo ""

    # 主循环
    while true; do
        show_main_menu

        read -p "请输入选择 (0-8): " CHOICE

        case "$CHOICE" in
            1)
                install_core
                ;;
            2)
                switch_core
                ;;
            3)
                show_status
                ;;
            4)
                show_list_backups
                ;;
            5)
                manage_kernel_menu
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
                echo -e "${GREEN}[退出] 感谢使用 ClashFox Mihomo 内核管理器${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}[错误] 无效的选择，请重新输入${NC}"
                wait_for_key
                ;;
        esac
    done
}

# 执行主程序
main "$@"