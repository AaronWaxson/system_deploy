#!/bin/bash
# ==============================================================================
# Package Management Wrappers (APT, Snap, etc.)
# ==============================================================================

# 冗余查验逻辑：封装通用安全安装函数 (Linux/APT only)
install_apt_pkgs() {
    if [ "$(uname -s)" = "Darwin" ]; then
        warn "[install_apt_pkgs] 当前为 macOS，跳过 APT 安装: $*"
        return 0
    fi
    if [ $# -eq 0 ]; then return 0; fi
    
    local to_install=()
    for pkg in "$@"; do
        # 查验当前包是否已被安装
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
            echo "  -> [跳过] $pkg 已经存在，无需再次安装。"
        else
            to_install+=("$pkg")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        info "正在安装以下未安装组件: ${to_install[*]}"
        sudo apt-get install -y "${to_install[@]}" || warn "组件安装遇到部分错误或缺少依赖: ${to_install[*]}"
    fi
}

# 辅助 Snap 安装函数 (Linux only)
install_snap_pkg() {
    if [ "$(uname -s)" = "Darwin" ]; then
        warn "[install_snap_pkg] 当前为 macOS，跳过 Snap 安装: $1"
        return 0
    fi
    local pkg=$1
    if snap list | grep -q "^$pkg "; then
        echo "  -> [跳过] $pkg (Snap) 已安装"
    else
        sudo snap install "$pkg" || warn "$pkg (Snap) 安装失败"
    fi
}
