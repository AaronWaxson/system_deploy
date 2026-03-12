#!/bin/bash
# ==============================================================================
# 自动驾驶算法工程师 (AD Algorithm Engineer) macOS 一键部署脚本
# 对标 Linux 的 deploy_ad_env.sh，通过 Homebrew 安装 Mac 必备开发工具
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 导入配置
source "$SCRIPT_DIR/conf/mac_packages.conf.sh"

# 导入底层框架库
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/network.sh"

# 导入 macOS 安装逻辑库
source "$SCRIPT_DIR/lib/mac_installer.sh"

# 绑定错误捕捉框架
setup_error_trap

# Linux 安全守卫
if [ "$(uname -s)" != "Darwin" ]; then
    warn "deploy_mac_env.sh 仅适用于 macOS 系统。Linux 请使用 deploy_ad_env.sh。"
    exit 0
fi

echo "=============================================="
echo " 🍎 开始部署 macOS 核心开发环境..."
echo "=============================================="

# 1. 确保 Homebrew 可用
info "[1/8] 初始化 Homebrew 包管理器..."
ensure_homebrew

# 2. C++ 核心开发工具
info "[2/8] 安装核心 C++ 开发与编译工具..."
install_brew_pkgs "${MAC_CPP_CORE_TOOLS[@]}"

# 3. 系统效率工具
info "[3/8] 安装系统效率与开发辅助工具..."
install_brew_pkgs "${MAC_SYSTEM_TOOLS[@]}"

# 4. 多媒体工具
info "[4/8] 安装多媒体查看与处理工具..."
install_brew_pkgs "${MAC_MEDIA_CLI_TOOLS[@]}"
install_cask_pkgs "${MAC_MEDIA_CASK_TOOLS[@]}"

# 5. 第三方 GUI 应用 (VSCode, Edge, Warp, Zotero)
info "[5/8] 安装第三方开发与生产力 GUI 应用..."
install_cask_pkgs "${MAC_GUI_APPS[@]}"

# 6. 开发字体
info "[6/8] 安装编程字体 (FiraCode, JetBrains Mono, Maple Mono)..."
install_mac_developer_fonts

# 7. Docker Desktop
info "[7/8] 安装 Docker Desktop..."
install_cask_pkgs "${MAC_DOCKER_CASK[@]}"

# 8. ML Toolchain (uv + Miniconda)
info "[8/8] 安装 ML 工具链 (uv + Miniconda)..."
install_mac_ml_toolchain

echo "==========================================================================="
echo " ✅ macOS 开发环境部署已完成！"
echo ""
echo " ⚠️  注意：以下软件建议您前往官网 【手动下载或配置】："
echo "   1. 飞书 (Feishu) / 坚果云 (Nutstore) / Snipaste / Clash Verge"
echo "   2. 输入法：macOS 原生输入法体验优异，如需百度拼音请自行下载"
echo ""
echo "   🎉 所有核心开发工具已就绪！"
echo "==========================================================================="
