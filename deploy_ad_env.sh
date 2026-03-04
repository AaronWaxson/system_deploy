#!/bin/bash
# ==============================================================================
# 自动驾驶算法工程师 (AD Algorithm Engineer) 全能工作站一键部署脚本
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 导入配置
source "$SCRIPT_DIR/conf/ad_packages.conf.sh"

# 导入底层框架库
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/network.sh"
source "$SCRIPT_DIR/lib/package_manager.sh"

# 导入领域逻辑功能库
source "$SCRIPT_DIR/lib/ad_installer.sh"

# 绑定错误捕捉框架
setup_error_trap

echo "=============================================="
echo " 🚀 开始部署全能工作站核心环境..."
echo "=============================================="

# 1. 基础系统源更新
configure_apt_sources

# 2. 基础组件与网络包
install_apt_pkgs "${BASE_TOOLS[@]}"

# 3. 核心 C++ 开发
info "[2/9] 安装核心 C++ 开发、编译及系统监控工具..."
install_apt_pkgs "${CPP_CORE_TOOLS[@]}"

# 4. 效率文件工具
info "[3/9] 安装工作流效率工具 (CopyQ 剪贴板, FileZilla)..."
install_apt_pkgs "${WORKFLOW_TOOLS[@]}"

# 5. 多媒体查看视频工具
info "[4/9] 安装多媒体查看、截图录制工具..."
install_apt_pkgs "${MEDIA_TOOLS[@]}"

# 6. 本机独立第三方软件
info "[5/9] 自动配置安装第三方源软件 (VSCode, Edge, Warp, Zotero等)..."
install_vscode
install_edge
install_warp
install_zotero
install_apt_pkgs antigravity

# 7. 辅助笔记软件集成
info "[6/9] 正在通过 Snap / 脚本安装附加软件..."
install_snap_pkg drawio
install_joplin
install_developer_fonts
configure_terminator

# 8. ML Infra: Docker / NVIDIA-CTK
install_docker_and_ctk

# 9. ML Infra: Python / Conda / UV
install_python_ml_toolchain

# 10. GPU Driver Layer
install_nvidia_drivers

echo "==========================================================================="
echo " ✅ 自动部署已完成！"
echo ""
echo " ⚠️  注意：以下高频软件我们建议您前往官网【手动下载或配置】： "
echo "   1. 百度拼音输入法 (BaiduPinyin): 下载 Linux(Ubuntu) .deb 配合 fcitx"
echo "   2. 飞书 (Feishu) / 坚果云 (Nutstore) / Snipaste / Clash Verge"
echo ""
echo "   🔥 【最后】强烈建议您执行 \`sudo reboot\` 重启系统环境以使显卡驱动生效。"
echo "==========================================================================="
