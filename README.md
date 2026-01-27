# ClashFox-Mihomo-Toolkit

一个功能强大的 ClashFox Mihomo 内核管理工具集，提供完整的内核安装、配置、运行和监控功能。

## ⚡️一键安装

```bash
bash -c 't=$(mktemp /tmp/clashfox_mihomo_toolkit.sh)&&curl -fL https://raw.githubusercontent.com/lukuochiang/clashmac-mihomo-kernel-helper/refs/heads/main/scripts/clashfox_mihomo_toolkit.sh -o "$t"&&chmod +x "$t"&&"$t" install&&rm -f "$t"'
```

## 💡功能特性

### 🔧 内核管理
- **安装/更新内核**：支持从多个 GitHub 源（vernesong/MetaCubeX）下载最新版本
- **自动架构检测**：智能识别系统架构（arm64/amd64）
- **版本切换**：灵活切换不同版本的内核
- **智能备份**：自动按时间戳备份历史版本
- **备份管理**：查看和管理所有备份版本

### 📊 状态监控
- **实时状态显示**：显示内核运行状态、版本信息
- **日志管理**：查看内核日志、定期清理日志
- **配置检查**：检测配置文件状态

### 🎛️ 进程控制
- **启动/关闭**：控制内核进程的运行状态
- **重启内核**：快速重启内核以应用配置
- **PID管理**：通过PID文件确保进程安全控制

### 📁 目录管理
- **自动创建目录**：确保完整的目录结构存在
- **权限设置**：自动设置正确的目录权限
- **文件组织**：合理管理配置、日志、数据等文件

## 系统要求

- macOS 操作系统
- bash shell 环境
- curl 命令（用于下载内核）
- sudo 权限（用于目录创建和权限设置）

## 安装说明

1. 克隆仓库到本地：

```bash
git clone https://github.com/yourusername/ClashFox-Mihomo-Toolkit.git
cd ClashFox-Mihomo-Toolkit
```

2. 赋予脚本执行权限：

```bash
chmod +x scripts/clashfox_mihomo_toolkit.sh
```

3. 运行脚本：

```bash
./scripts/clashfox_mihomo_toolkit.sh
```

## 使用指南

### 主菜单

运行脚本后，将看到主菜单界面：