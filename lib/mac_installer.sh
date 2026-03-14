#!/bin/bash
# ==============================================================================
# Domain Logic: macOS Developer Tools Installer (对标 Linux 的 ad_installer.sh)
# ==============================================================================

# [全局] 配置 Homebrew 清华镜像源 (加速 brew install / brew update)
configure_brew_mirrors() {
    export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
    export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
    export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
    info "已配置 Homebrew 清华镜像源 (API + Bottles + Git)"
}

# [阶段0] 确保 Homebrew 可用
ensure_homebrew() {
    # 🔑 无论是否已安装，都先激活清华镜像
    configure_brew_mirrors
    
    if command -v brew &> /dev/null; then
        echo "  -> [跳过] Homebrew 已安装"
        return 0
    fi
    
    info "未检测到 Homebrew，开始安装 (使用清华镜像加速)..."
    /bin/bash -c "$(curl -fsSL https://mirror.ghproxy.com/https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        warn "Homebrew 安装脚本遇到网络限制，尝试直接安装..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
            error "Homebrew 安装失败，请手动安装后重试。"
            exit 1
        }
    }
    
    # Apple Silicon: brew 安装在 /opt/homebrew，需要加入 PATH
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

# 批量安装 brew CLI 包 (已安装则跳过)
install_brew_pkgs() {
    if [ $# -eq 0 ]; then return 0; fi
    
    local to_install=()
    for pkg in "$@"; do
        if brew list --formula "$pkg" &> /dev/null; then
            echo "  -> [跳过] $pkg (brew) 已安装"
        else
            to_install+=("$pkg")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        info "正在通过 brew 安装: ${to_install[*]}"
        brew install "${to_install[@]}" || warn "部分 brew 包安装遇到错误: ${to_install[*]}"
    fi
}

# 批量安装 brew cask GUI 包 (已安装则跳过)
install_cask_pkgs() {
    if [ $# -eq 0 ]; then return 0; fi
    
    local to_install=()
    for pkg in "$@"; do
        if brew list --cask "$pkg" &> /dev/null; then
            echo "  -> [跳过] $pkg (cask) 已安装"
        else
            to_install+=("$pkg")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        info "正在通过 brew cask 安装: ${to_install[*]}"
        brew install --cask "${to_install[@]}" || warn "部分 cask 包安装遇到错误: ${to_install[*]}"
    fi
}

# 安装神级编程字体 (通过 Homebrew Cask Fonts)
install_mac_developer_fonts() {
    info "正在安装编程字体 (FiraCode, JetBrains Mono, Maple Mono NF)..."
    
    # 确保 fonts tap 已添加
    if ! brew tap | grep -q "homebrew/cask-fonts" 2>/dev/null; then
        brew tap homebrew/cask-fonts 2>/dev/null || true
    fi
    
    install_cask_pkgs "${MAC_DEVELOPER_FONTS[@]}"
}

# 安装 ML 工具链 (uv + Miniconda)
install_mac_ml_toolchain() {
    info "安装 Python 极速工具 (uv) 与 Miniconda..."
    
    # 安装 uv
    if ! command -v uv &> /dev/null; then
        curl -m 15 -LsSf https://astral.sh/uv/install.sh | sh || warn "uv 安装失败 (可能需要代理)"
    else
        echo "  -> [跳过] uv 已经存在"
    fi
    
    # 安装 Miniconda (macOS 版)
    if [ ! -d "$HOME/miniconda3" ]; then
        local arch
        arch=$(uname -m)
        local miniconda_url
        if [ "$arch" = "arm64" ]; then
            miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
        else
            miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
        fi
        
        mkdir -p ~/miniconda3
        info "正在下载 Miniconda ($arch 架构)..."
        wget "$miniconda_url" -O ~/miniconda3/miniconda.sh || curl -fsSL "$miniconda_url" -o ~/miniconda3/miniconda.sh || {
            warn "Miniconda 下载失败"
            return 1
        }
        bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 || warn "Miniconda 安装遇到错误"
        rm -f ~/miniconda3/miniconda.sh
        # 自动初始化 conda
        ~/miniconda3/bin/conda init zsh || true
        ~/miniconda3/bin/conda init bash || true
    else
        echo "  -> [跳过] miniconda3 目录已存在"
    fi
}
