#!/bin/bash
# ==============================================================================
# Domain Logic: Advanced Zsh Productivity Environment Installer
# ==============================================================================

# OS 检测
detect_os() {
    OS="$(uname -s)"
    if [ "$OS" != "Linux" ] && [ "$OS" != "Darwin" ]; then
        error "暂不支持的操作系统架构: $OS"
        exit 1
    fi
    echo "$OS"
}

# 安装 Starship 系统级工具
install_starship() {
    info "安装 Starship 跨平台提示符..."
    if ! command -v starship &> /dev/null; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    else
        echo "  -> [跳过] Starship 已经安装"
    fi
}

# 拉取 Zsh 插件
install_zsh_plugins() {
    info "拉取 Zsh 生产力加速插件..."
    ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
    mkdir -p "$ZSH_PLUGIN_DIR"
    
    for plugin_url in "${ZSH_PLUGINS[@]}"; do
        # Combine GH_MIRROR with the plugin repo portion
        local full_url="${GH_MIRROR}/${plugin_url}"
        local plugin_name
        plugin_name=$(basename "$plugin_url" .git)
        
        if [ ! -d "$ZSH_PLUGIN_DIR/$plugin_name" ]; then
            git clone --depth 1 "$full_url" "$ZSH_PLUGIN_DIR/$plugin_name"
        else
            echo "  -> [跳过] 插件 $plugin_name ($full_url) 已存在"
        fi
    done
}

# 生成强力 ~/.zshrc 环境配置项
generate_zshrc() {
    info "正在配置您的终端环境变量 ~/.zshrc ..."
    ZSHRC_FILE="$HOME/.zshrc"
    
    # 备份旧文件
    if [ -f "$ZSHRC_FILE" ]; then
        cp "$ZSHRC_FILE" "${ZSHRC_FILE}.bak_$(date +%Y%m%d%H%M)"
    fi
    
cat << 'EOF' > "$ZSHRC_FILE"
# =====================================
# 🚀 自动驾驶/算法工程师 纯净极速配置档
# =====================================

export HISTFILE=~/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000
setopt appendhistory share_history hist_ignore_all_dups inc_append_history

# BATcat / EZA aliases
if command -v batcat &> /dev/null; then
    alias cat="batcat"
elif command -v bat &> /dev/null; then
    alias cat="bat"
fi

if command -v eza &> /dev/null; then
    alias ls="eza --icons -F"
    alias ll="eza --icons -F -l -h --git"
    alias tree="eza --tree --icons"
elif command -v exa &> /dev/null; then
    alias ls="exa --icons -F"
    alias ll="exa --icons -F -l -h --git"
fi

alias rm='rm -i' cp='cp -i' mv='mv -i' n='nvidia-smi' nn='watch -n 1 nvidia-smi'

# 核心插件加载
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8c8c8c"
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
source ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh 2>/dev/null
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Rust 工具链补全加载
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
    alias cd="z"
fi
if command -v fzf &> /dev/null; then
    source <(fzf --zsh 2>/dev/null || fzf --bash 2>/dev/null || echo "")
fi
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi
EOF
}

# 部署精简高频 Starship.toml 主题配置
generate_starship_toml() {
    mkdir -p "$HOME/.config"
    if [ ! -f "$HOME/.config/starship.toml" ]; then
        info "生成定制版的 Starship 简明主题..."
cat << 'EOF' > "$HOME/.config/starship.toml"
add_newline = false
[username]
show_always = false
[directory]
truncation_length = 4
format = "[$path]($style)[$read_only]($read_only_style) "
style = "bold cyan"
[git_branch]
format = "[$symbol$branch]($style) "
symbol = "🌱 "
style = "bold purple"
[git_status]
format = "([$all_status$ahead_behind]($style) )"
style = "bold red"
[python]
format = "[${symbol}${py_version}( \\($virtualenv\\))]($style) "
symbol = "🐍 "
style = "bold yellow"
[cmd_duration]
min_time = 2_000
format = "⏱ [$duration]($style)"
style = "bold yellow"
[character]
success_symbol = "[❯](bold green)"
error_symbol = "[✗](bold red)"
EOF
    fi
}

# 绑定切换默认 Shell
switch_default_shell() {
    info "检查默认 Shell 是否为 zsh..."
    local zsh_path
    zsh_path=$(command -v zsh)
    
    # 1. 尝试使用原生命令彻底修改 /etc/passwd
    if [ "$SHELL" != "$zsh_path" ] && [ "$SHELL" != "/bin/zsh" ]; then
        info "正在尝试通过 chsh 将默认 Shell 切为 zsh"
        sudo chsh -s "$zsh_path" "$USER" 2>/dev/null || chsh -s "$zsh_path" 2>/dev/null || warn "原生 chsh 切换遇到阻力 (多见于无密码环境或容器/WSL内)"
    else
        echo "  -> [跳过] 原生 /etc/passwd 默认 Shell 已经是 zsh"
    fi
    
    # 2. [防弹级别] 为防止 chsh 因权限或 PAM 认证失效导致重启后依旧是 bash，注入一个兼容跳板到 .bashrc
    local bashrc_file="$HOME/.bashrc"
    if [ -f "$bashrc_file" ] && ! grep -q "exec \"$zsh_path\"" "$bashrc_file"; then
        info "正在为 ~/.bashrc 注入防弹级别的 Zsh 自动跳转保护逻辑..."
        cat << EOF >> "$bashrc_file"

# ==========================================
# 🚀 自动驾驶/算法工程师: Zsh 终端强绑定防弹方案
# ==========================================
if [[ \$- == *i* ]] && [ -x "$zsh_path" ] && [ "\$SHELL" != "$zsh_path" ] && [ "\$SHELL" != "/bin/zsh" ]; then
    export SHELL="$zsh_path"
    exec "$zsh_path" -l
fi
EOF
    fi
}
