#!/bin/bash
# ==============================================================================
# 自动驾驶算法工程师 (AD Algorithm Engineer) 全能工作站一键部署脚本
# 包含：核心开发环境、可视化多媒体工具、高频工作软件、深度学习基础设施
# ==============================================================================

# 1. 取消全局严格退出，防止因为某个软件源失效阻断全流程
# set -e

# 2. 增加全局错误捕捉
handle_error() {
    local exit_code=$?
    local line_no=$1
    echo -e "\e[31m[ERROR] 脚本执行在第 $line_no 行发出错误信号，退出码: $exit_code，但这将不会阻断后续代码的执行。\e[0m" >&2
}
trap 'handle_error $LINENO' ERR

# 日志输出函数
info() { echo -e "\e[34m[INFO] $1\e[0m"; }
warn() { echo -e "\e[33m[WARN] $1\e[0m"; }

echo "=============================================="
echo " 🚀 开始部署全能工作站核心环境..."
echo "=============================================="

# 4. 冗余查验逻辑：封装通用安全安装函数
install_apt_pkgs() {
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

GH_MIRROR=https://kkgithub.com

# --- 1. 自动替换 APT 源为主流镜像 ---
info "[1/9] 更新 APT 源 (兼容第三方库)..."
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak || true
sudo sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
sudo sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
sudo apt-get update -y || warn "apt-get update 执行出错（可能是第三方源过期），继续执行"
sudo apt-get upgrade -y || warn "apt-get upgrade 执行出错，继续执行"

# 确保安装 snapd 和必备网络下载工具
install_apt_pkgs snapd wget curl git gnupg software-properties-common apt-transport-https ca-certificates lsb-release

# --- 2. 核心 C++ 开发与编译构建工具 ---
info "[2/9] 安装核心 C++ 开发、编译及系统监控工具..."
install_apt_pkgs \
build-essential cmake ninja-build ccache \
gcc g++ clang clang-format clang-tidy gdb valgrind \
git-lfs rsync tmux screen htop btop tree jq unzip zip

# --- 3. 效率工具与文件传输 ---
info "[3/9] 安装工作流效率工具 (CopyQ 剪贴板, FileZilla)..."
install_apt_pkgs copyq filezilla

# --- 4. 图像/视频多媒体查看与调试工具 ---
info "[4/9] 安装多媒体查看、截图录制工具..."
install_apt_pkgs \
ffmpeg libopencv-dev imagemagick \
eog feh mpv vlc gwenview okular \
shutter peek simplescreenrecorder \
libgl1 libglx-mesa0 libcanberra-gtk-module \
sqlitebrowser

# --- 5. 常见第三方开发配置 (VSCode, Edge, Zotero, Antigravity) ---
info "[5/9] 自动配置安装第三方源软件 (VSCode, Edge, Zotero等)..."

# VSCode (微软源)
if ! command -v code &> /dev/null; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    sudo apt-get update || true
    install_apt_pkgs code
else
    echo "  -> [跳过] VSCode (code) 已安装"
fi

# Microsoft Edge
if ! command -v microsoft-edge &> /dev/null; then
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-edge.gpg || true
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list > /dev/null
    sudo apt-get update || true
    install_apt_pkgs microsoft-edge-stable
else
    echo "  -> [跳过] Microsoft Edge 已安装"
fi

# Zotero (retorquere deb)
if ! command -v zotero &> /dev/null; then
    # 动态将最优 GitHub 域名替换至 raw 域名前缀（部分加速站通过 url 参数解析，此处统一处理）
    GH_RAW_MIRROR=$(echo "$GH_MIRROR" | sed 's#https://github.com#https://raw.githubusercontent.com#')
    wget -qO- --timeout=15 "${GH_RAW_MIRROR}/retorquere/zotero-deb/master/install.sh" | sudo bash || warn "Zotero 安装源配置失败"
    sudo apt-get update || true
    install_apt_pkgs zotero
else
    echo "  -> [跳过] Zotero 已安装"
fi

# Antigravity (检测由于您当前APT源里已配有antigravity-debian)
install_apt_pkgs antigravity

# --- 6. 辅助工具与笔记配置 (Drawio, Joplin) ---
info "[6/9] 正在通过 Snap / 脚本安装附加软件..."

# Drawio (官方推荐 snap)
if snap list | grep -q drawio; then
    echo "  -> [跳过] drawio (Snap) 已安装"
else
    sudo snap install drawio || warn "Drawio 安装失败"
fi

# Joplin 需要 libfuse2 来运行其背后包含的 AppImage
install_apt_pkgs libfuse2

if ! command -v joplin &> /dev/null; then
    GH_RAW_MIRROR=$(echo "$GH_MIRROR" | sed 's#https://github.com#https://raw.githubusercontent.com#')
    wget -O - --timeout=20 "${GH_RAW_MIRROR}/laurent22/joplin/dev/Joplin_install_and_update.sh" | bash || warn "Joplin 安装脚本退出异常"
else
    echo "  -> [跳过] Joplin 已安装"
fi

# --- 7. 安装 Docker 引擎及 NVIDIA Container Toolkit ---
info "[7/9] 配置 Docker 及 GPU 容器支持 (NVIDIA Container Toolkit)..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER || true
    rm get-docker.sh
else
    echo "  -> [跳过] Docker (docker) 已安装"
fi

if ! command -v nvidia-ctk &> /dev/null; then
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg || true
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
    sudo apt-get update || true
    install_apt_pkgs nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker || true
    sudo systemctl restart docker || true
else
    echo "  -> [跳过] NVIDIA Container Toolkit (nvidia-ctk) 已安装"
fi

# --- 8. Python 底层环境管理 (Conda, uv) ---
info "[8/9] 安装 Python 极速工具 (uv) 与 Miniconda3..."
# 安装 uv (Rust 编写的极速 Python 包管理器)
if ! command -v uv &> /dev/null; then
    curl -m 15 -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL="/usr/local/bin" sh || warn "uv 安装失败 (可能需要代理)"
else
    echo "  -> [跳过] uv 已经存在"
fi

# 安装 Miniconda3
if [ ! -d "$HOME/miniconda3" ]; then
    mkdir -p ~/miniconda3
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh || true
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 || warn "Miniconda 安装遇到错误"
    rm ~/miniconda3/miniconda.sh
    
    # 自动初始化 conda (bash & zsh)
    ~/miniconda3/bin/conda init bash || true
    ~/miniconda3/bin/conda init zsh || true
else
    echo "  -> [跳过] miniconda3 目录已存在"
fi

# --- 9. 闭源驱动更新及缓存清理 ---
info "[9/9] 自动更新 NVIDIA 显卡驱动并清理环境..."
sudo add-apt-repository -y ppa:graphics-drivers/ppa || true
sudo apt-get update || true

# Check if ubuntu-drivers is installed before executing
if ! command -v ubuntu-drivers &> /dev/null; then
    install_apt_pkgs ubuntu-drivers-common
fi
sudo ubuntu-drivers autoinstall || warn "ubuntu-drivers 安装闭源驱动时发生异常"

sudo apt-get autoremove -y
sudo apt-get clean

echo "==========================================================================="
echo " ✅ 自动部署已完成！"
echo ""
echo " ⚠️  注意：以下高频软件我们建议您前往官网【手动下载或配置】： "
echo "   1. 百度拼音输入法 (BaiduPinyin): 下载 Linux(Ubuntu) .deb 配合 fcitx"
echo "   2. 飞书 (Feishu) / 坚果云 (Nutstore) / Snipaste / Clash Verge"
echo ""
echo "   🔥 【最后】强烈建议您执行 \`sudo reboot\` 重启系统环境以使显卡驱动生效。"
echo "==========================================================================="
