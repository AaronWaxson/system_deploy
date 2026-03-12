#!/bin/bash
# ==============================================================================
# 自动驾驶算法工程师 (AD Algorithm Engineer) 极速终端一键部署脚本
# 架构方案：Zsh + Starship + zoxide + fzf + bat + eza + 常用插件
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 导入环境配置项
source "$SCRIPT_DIR/conf/zsh_plugins.conf.sh"

# 导入底层框架库
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/network.sh"

# 导入终端领域逻辑库
source "$SCRIPT_DIR/lib/zsh_installer.sh"

# 绑定错误捕捉框架
setup_error_trap

echo "=============================================="
echo " 🚀 开始部署跨平台极致终端生态..."
echo "=============================================="

# 1. 检查操作系统与基础包管理器支持情况
OS=$(detect_os)
info "[1/4] 检测到操作系统: $OS，开始安装基础运行库..."

if [ "$OS" = "Linux" ]; then
    sudo apt-get update -y || warn "apt-get update 失败，但我们将继续尝试安装。"
    sudo apt-get install -y zsh curl git unzip fzf zoxide bat || warn "包安装失败..."
    sudo apt-get install -y eza || true
elif [ "$OS" = "Darwin" ]; then
    if ! command -v brew &> /dev/null; then
        info "未检测到 Homebrew，开始安装 Homebrew (macOS 包管理器)..."
        export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
        export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
        export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
        /bin/bash -c "$(curl -fsSL https://mirror.ghproxy.com/https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || warn "Homebrew 安装脚本当中遇到网络限制。"
    fi
    info "正在使用 brew 安装核心依赖..."
    brew install zsh curl git unzip fzf zoxide bat eza
fi

# 2. 安装核心视觉提示符
info "[2/4] 安装 Starship (使用 Rust 编写的极速跨平台 Prompt)..."
install_starship

# 3. 安装配置插件群
info "[3/4] 克隆并更新 Zsh 高效流插件..."
install_zsh_plugins

# 4. 生成终端配置
info "[4/4] 注入环境变量和 Zsh 主命令集 ..."
generate_zshrc
generate_starship_toml

# 5. 接管默认 Shell
switch_default_shell

echo "==========================================================================="
echo -e "\e[32m ✅ 极速终端 (Zsh + Starship) 部署完成！\e[0m"
echo ""
echo "   🎉 您的配置已更新。"
echo "   ⚠️ 请完全注销重新登录，或者关掉所有终端并新开一个标签页来享受新环境！"
echo "==========================================================================="
