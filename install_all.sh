#!/bin/bash
# ==============================================================================
# 自动驾驶与大模型开发：工作站全局一键部署脚本 (Master Orchestrator)
# 跨平台支持：Linux (Ubuntu) / macOS
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 导入底层 logging
source "$SCRIPT_DIR/lib/utils.sh"

# 绑定错误捕捉框架
setup_error_trap
require_root

# 检测操作系统
CURRENT_OS=$(uname -s)

echo "==========================================================================="
echo " 🌟 欢迎使用 自动驾驶算法工程师 全垒打统一部署程序"
echo " 🌟 检测到操作系统: $CURRENT_OS"
echo " 🌟 此程序将依次执行："
if [ "$CURRENT_OS" = "Darwin" ]; then
echo "    [1] MAC_ENV: macOS 核心开发工具部署 (Homebrew + C++/Python/Docker)"
else
echo "    [1] AD_ENV: 核心多媒体、C++/Python环境、推理、Docker 以及 Nvidia 驱动部署"
fi
echo "    [2] ZSH_ENV: 跨平台极速终端与高级高亮提示符系统部署"
echo "==========================================================================="
echo ""
read -p "按 [Enter] 键确认开始全局环境搭建..."

# 阶段一：核心开发环境 (根据 OS 分流)
if [ "$CURRENT_OS" = "Darwin" ]; then
    info ">>> 阶段一：调用 deploy_mac_env.sh 开始装备 macOS 核心开发基础设施"
    bash "$SCRIPT_DIR/deploy_mac_env.sh"
    success ">>> 阶段一 完成。"
else
    info ">>> 阶段一：调用 deploy_ad_env.sh 开始装备核心开发基础设施"
    bash "$SCRIPT_DIR/deploy_ad_env.sh"
    success ">>> 阶段一 完成。"
fi

# 阶段二：终端配置栈 (跨平台共享)
info ">>> 阶段二：调用 deploy_zsh_env.sh 开始装备现代化 Zsh 终端生态"
bash "$SCRIPT_DIR/deploy_zsh_env.sh"
success ">>> 阶段二 完成。"

echo "==========================================================================="
success " ✅ 所有环境已全部部署完毕！"
if [ "$CURRENT_OS" = "Darwin" ]; then
echo " ⚠️ 重要提示："
echo "   1. 请关闭所有终端窗口并重新打开，以激活 Zsh + Starship 全新环境。"
echo "   2. Docker Desktop 需要手动启动一次以完成初始化。"
else
echo " ⚠️ 重要提示："
echo "   1. 强烈建议您马上执行 \`sudo reboot\` 彻底重新启动计算机，以激活 nvidia 闭源驱动、更新的内核层以及 Docker 用户组权限。"
echo "   2. 重启登录后，双击打开新的终端即可拥抱带有 Starship 极速主题的 Zsh 全新环境。"
fi
echo "==========================================================================="
