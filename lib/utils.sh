#!/bin/bash
# ==============================================================================
# Core Utilities: Logging and Error Handling
# ==============================================================================

# Global Variables for Colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

# Check if script is running as root
require_root() {
    if [ "$EUID" -ne 0 ]; then
        info "请注意：安装过程需要 root 权限，由于脚本中含有大量 sudo 命令，您可能需要暂时提权以顺利通过执行："
        sudo -v || exit 1
        # 保持 sudo 提权活跃
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    fi
}

# Logging Functions
info() { echo -e "${BLUE}[INFO] $1${RESET}"; }
warn() { echo -e "${YELLOW}[WARN] $1${RESET}"; }
success() { echo -e "${GREEN}[SUCCESS] $1${RESET}"; }
error() { echo -e "${RED}[ERROR] $1${RESET}" >&2; }

# Error Trapping
handle_error() {
    local exit_code=$?
    local line_no=$1
    error "脚本执行在第 $line_no 行发出错误信号，退出码: $exit_code，但这将不会阻断后续代码的执行。"
}

setup_error_trap() {
    trap 'handle_error $LINENO' ERR
}
