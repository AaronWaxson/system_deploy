#!/bin/bash
# ==============================================================================
# 自动驾驶算法工程师 (AD Algorithm Engineer) 极速终端一键部署脚本
# 架构方案：Zsh + Starship + zoxide + fzf + bat + eza + 常用插件
# 支持系统：Ubuntu / Debian / macOS
# ==============================================================================

# 设置严格错误捕获
set -e
handle_error() {
    echo -e "\e[31m[ERROR] 脚本执行出错，退出码 $?，位置在第 $1 行。\e[0m" >&2
}
trap 'handle_error $LINENO' ERR

info() { echo -e "\e[34m[INFO] $1\e[0m"; }
warn() { echo -e "\e[33m[WARN] $1\e[0m"; }

# 1. 甄别操作系统并安装基础包管理器
OS="$(uname -s)"
info "[1/4] 检测到操作系统: $OS，开始安装基础运行库..."

if [ "$OS" = "Linux" ]; then
    # 假设使用基于 Debian/Ubuntu 的发型版
    sudo apt-get update -y || warn "apt-get update 失败，但我们将继续尝试安装。"
    # ubuntu 24.04 等高版本已经自带很全的包，且 bat 在 ubuntu 中默认叫 batcat
    sudo apt-get install -y zsh curl git unzip fzf zoxide bat || warn "包安装失败..."
    
    # Ubuntu apt 源中的 eza/exa 更新可能较慢，若需要使用 eza，建议去通过 cargo 或 apt-source 安装，此处尽量保证通用不报错
    # 为了更好看，我们可以顺便尝试装个 exa 替代 ls
    sudo apt-get install -y eza || true
    
    elif [ "$OS" = "Darwin" ]; then
    # macOS - 检查和安装 Homebrew
    if ! command -v brew &> /dev/null; then
        info "未检测到 Homebrew，开始安装 Homebrew (macOS 包管理器)..."
        # 使用国内镜像加速拉取官方安装脚本并注入清华源的环境变量，防止脚本内克隆卡死
        export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
        export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
        export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
        /bin/bash -c "$(curl -fsSL https://mirror.ghproxy.com/https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || warn "Homebrew 安装脚本当中可能遇到网络阻断，请尝试挂载全局代理解决。"
    fi
    info "正在使用 brew 安装核心依赖..."
    brew install zsh curl git fzf zoxide bat eza
else
    echo -e "\e[31m[ERROR] 暂不支持的操作系统架构: $OS，仅支持 Linux / Darwin\e[0m"
    exit 1
fi

# 2. 从官方源静默安装 Starship (跨平台终端提示符)
info "[2/4] 安装 Starship (使用 Rust 编写的极速跨平台 Prompt)..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo "  -> [跳过] Starship 已经安装"
fi

# 3. 本地化克隆 Zsh 必备插件 (无需庞大的 Oh-My-Zsh 框架级臃肿)
info "[3/4] 拉取 Zsh 生产力加速插件..."
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$ZSH_PLUGIN_DIR"

install_plugin() {
    local repo_url
    repo_url=$1
    local plugin_name
    plugin_name=$(basename "$repo_url" .git)
    if [ ! -d "$ZSH_PLUGIN_DIR/$plugin_name" ]; then
        git clone --depth 1 "$repo_url" "$ZSH_PLUGIN_DIR/$plugin_name"
    else
        echo "  -> [跳过] 插件 $plugin_name 已存在"
    fi
}

GH_MIRROR=https://kkgithub.com

# 自动推断 (Fish-like)
install_plugin "${GH_MIRROR}/zsh-users/zsh-autosuggestions.git"
# 语法高亮
install_plugin "${GH_MIRROR}/zsh-users/zsh-syntax-highlighting.git"
# 历史记录模糊搜索加强辅助
install_plugin "${GH_MIRROR}/zsh-users/zsh-history-substring-search.git"

# 4. 生成统一的配置文件 ~/.zshrc 和 ~/.config/starship.toml
info "[4/4] 正在配置您的终端环境变量 ~/.zshrc ..."
ZSHRC_FILE="$HOME/.zshrc"

# 先备份旧文件
if [ -f "$ZSHRC_FILE" ]; then
    cp "$ZSHRC_FILE" "${ZSHRC_FILE}.bak_$(date +%Y%m%d%H%M)"
fi

# 写入纯净而极速的配置文件
cat << 'EOF' > "$ZSHRC_FILE"
# =====================================
# 🚀 自动驾驶/算法工程师 纯净极速配置档
# =====================================

# 1. SSH / History 历史回放加强
export HISTFILE=~/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000
setopt appendhistory
setopt share_history
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt inc_append_history

# 2. alias 效率别名区 (无缝替换老旧古董命令)
# [BATcat] 更高亮查阅文件内容
if command -v batcat &> /dev/null; then
    alias cat="batcat"
elif command -v bat &> /dev/null; then
    alias cat="bat"
fi

# [EZA / EXA] 更好的带图标版 ls
if command -v eza &> /dev/null; then
    alias ls="eza --icons -F"
    alias ll="eza --icons -F -l -h --git"
    alias la="eza --icons -F -l -a -h --git"
    alias tree="eza --tree --icons"
elif command -v exa &> /dev/null; then
    alias ls="exa --icons -F"
    alias ll="exa --icons -F -l -h --git"
fi

# 其他防错以及生产力别名
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias df='df -h'
alias du='du -h'
alias n='nvidia-smi'
alias nn='watch -n 1 nvidia-smi'

# 3. Zsh 高亮与预测核心插件初始化
# -- Autosuggestions (Fish 风格的命令推断) --
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8c8c8c"  # 调整推断字体变暗以保护视力

# -- Syntax Highlighting (语法错误标红) --
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# -- History Substring Search (历史按键补全) --
source ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
# 为 ↑/↓ 绑定子串搜索历史
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# 4. Rust 次世代组件启动 (Zoxide 目录折叠 + FZF 全局搜素 + Starship 状态显示)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
    alias cd="z"     # 现在可以用如: z dat 代替 cd /data/datasets
fi

if command -v fzf &> /dev/null; then
    # 加载基于 fzf 的 Ctrl+R (历史检索) 和 Ctrl+T (文件搜索)
    source <(fzf --zsh 2>/dev/null || fzf --bash 2>/dev/null || echo "")
fi

# [注意] Starship 放最后
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi
EOF

# 如果本地不存在 starship.toml 则生成一份默认定制化的主题文件
mkdir -p "$HOME/.config"
if [ ! -f "$HOME/.config/starship.toml" ]; then
    info "生成定制版的 Starship 简明主题..."
    cat << 'EOF' > "$HOME/.config/starship.toml"
# 简明轻快的算法工程师专用主题
add_newline = false

[username]
show_always = false

[directory]
truncation_length = 4
truncate_to_repo = false
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

# 5. 切换默认 Shell
info "检查默认 Shell 是否为 zsh..."
if [ "$SHELL" != "$(which zsh)" ] && [ "$SHELL" != "/bin/zsh" ]; then
    info "正在将默认 Shell 切为 zsh (可能需要输入您的登录密码)"
    chsh -s "$(command -v zsh)" || warn "切换 shell 失败，您可以稍后再执行: chsh -s \$(which zsh)"
else
    echo "  -> [跳过] 默认 Shell 已经是 zsh"
fi

echo "==========================================================================="
echo -e "\e[32m ✅ 极速终端 (Zsh + Starship) 部署完成！\e[0m"
echo ""
echo "   🎉 您的配置已更新。"
echo "   ⚠️ 请完全注销重新登录，或者关掉所有终端并新开一个标签页来享受新环境！"
echo "==========================================================================="
