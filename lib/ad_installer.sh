#!/bin/bash
# ==============================================================================
# Domain Logic: AD Engineer Tools (Docker, GPU Drivers, IDES, ML Infra)
# ==============================================================================

# [阶段1] 更新系统基础源
configure_apt_sources() {
    info "[1/9] 更新 APT 源 (兼容第三方库)..."
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak || true
    sudo sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
    sudo sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
    sudo apt-get update -y || warn "apt-get update 执行出错，继续执行"
    sudo apt-get upgrade -y || warn "apt-get upgrade 执行出错，继续执行"
}

# [阶段5.1] 安装各大必备第三方套件 VSCode
install_vscode() {
    if ! command -v code &> /dev/null; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm -f packages.microsoft.gpg
        sudo apt-get update || true
        install_apt_pkgs code
    else
        echo "  -> [跳过] VSCode 已安装"
    fi
}

# [阶段5.2] 安装 Edge
install_edge() {
    if ! command -v microsoft-edge &> /dev/null; then
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-edge.gpg || true
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list > /dev/null
        sudo apt-get update || true
        install_apt_pkgs microsoft-edge-stable
    else
        echo "  -> [跳过] Microsoft Edge 已安装"
    fi
}

# [阶段5.3] 安装 Warp 现代 GPU 加速终端
install_warp() {
    if ! command -v warp-terminal &> /dev/null; then
        sudo apt-get install -y wget gpg
        wget -qO- https://releases.warp.dev/linux/keys/warp.asc | gpg --dearmor > warpdotdev.gpg
        sudo install -D -o root -g root -m 644 warpdotdev.gpg /etc/apt/keyrings/warpdotdev.gpg
        sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/warpdotdev.gpg] https://releases.warp.dev/linux/apt stable main" > /etc/apt/sources.list.d/warpdotdev.list'
        rm -f warpdotdev.gpg
        sudo apt-get update || true
        install_apt_pkgs warp-terminal
    else
        echo "  -> [跳过] Warp Terminal 已安装"
    fi
}

# [阶段5.4] 安装 Zotero (带 GhProxy 加速)
install_zotero() {
    if ! command -v zotero &> /dev/null; then
        GH_RAW_MIRROR=$(get_gh_raw_mirror)
        wget -qO- --timeout=15 "${GH_RAW_MIRROR}/retorquere/zotero-deb/master/install.sh" | sudo bash || warn "Zotero 安装脚本异常"
        sudo apt-get update || true
        install_apt_pkgs zotero
    else
        echo "  -> [跳过] Zotero 已安装"
    fi
}

# [阶段6.2] 安装 Joplin (带 GhProxy 加速)
install_joplin() {
    install_apt_pkgs libfuse2
    if ! command -v joplin &> /dev/null; then
        GH_RAW_MIRROR=$(get_gh_raw_mirror)
        wget -O - --timeout=20 "${GH_RAW_MIRROR}/laurent22/joplin/dev/Joplin_install_and_update.sh" | bash || warn "Joplin 安装脚本退出异常"
    else
        echo "  -> [跳过] Joplin 已安装"
    fi
}

# [阶段6.3] 安装神级编程字体 (FiraCode, JetBrains Mono, Maple Mono)
install_developer_fonts() {
    info "正在安装神级编程终端字体 (FiraCode, JetBrains Mono, Maple Mono) ..."
    install_apt_pkgs fonts-firacode fonts-jetbrains-mono unzip fontconfig jq
    
    local MAPLE_FONT_DIR="$HOME/.local/share/fonts/MapleMono"
    if [ ! -d "$MAPLE_FONT_DIR" ]; then
        mkdir -p "$MAPLE_FONT_DIR"
        # 借助 Github API 动态解析最新版本的发行包
        local api_url="https://api.github.com/repos/subframe7536/maple-font/releases/latest"
        local download_url=$(curl -sL --max-time 10 "$api_url" | jq -r '.assets[] | select(.name | test("MapleMono-(NF|CC|SC|NF-CN|NF-SC)\\.zip$") or .name == "MapleMono.zip") | .browser_download_url' | head -n 1)
        
        if [ -n "$download_url" ]; then
            local GH_BASE=$(get_gh_raw_mirror | sed 's#https://raw.githubusercontent.com#https://github.com#')
            local proxy_url=$(echo "$download_url" | sed "s#https://github.com#$GH_BASE#")
            
            info "正在从最快镜像挂载拉取 Maple Mono 字体: $proxy_url"
            wget -qO /tmp/maple.zip "$proxy_url" || wget -qO /tmp/maple.zip "https://mirror.ghproxy.com/$download_url"
            
            if [ -f /tmp/maple.zip ] && [ -s /tmp/maple.zip ]; then
                unzip -q -o /tmp/maple.zip -d "$MAPLE_FONT_DIR"
                rm -f /tmp/maple.zip
                fc-cache -fv "$MAPLE_FONT_DIR" >/dev/null 2>&1
                info "  -> [成功] Maple Mono (NF) 字体已载入系统"
            else
                warn "Maple Mono 字体文件拉取失败或为空"
                rm -f /tmp/maple.zip
            fi
        else
            warn "未能从 Github Release 解析出合法的 Maple 字体包 URL，请手动前往 Github Release 下载挂载。"
        fi
    else
        echo "  -> [跳过] Maple Mono 字体库似乎已存在 ($MAPLE_FONT_DIR)"
    fi
}

# [阶段6.4] 高级终端模拟器注入 (Terminator 绝美透明主题)
configure_terminator() {
    if command -v terminator &> /dev/null; then
        info "正在为 Terminator 注入 AD 极简透明暗黑主题与 JetBrains 字体绑定 ..."
        
        # 使用 ad_installer.sh 所在目录的 ../conf/terminator.config
        local SCRIPT_REAL_DIR
        SCRIPT_REAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local TERMINATOR_CONF_SRC="${SCRIPT_REAL_DIR}/../conf/terminator.config"
        local TERMINATOR_CONF_DST="$HOME/.config/terminator/config"
        
        if [ -f "$TERMINATOR_CONF_SRC" ]; then
            # 如果旧配置已存在，先备份一份
            if [ -f "$TERMINATOR_CONF_DST" ]; then
                cp "$TERMINATOR_CONF_DST" "${TERMINATOR_CONF_DST}.bak_$(date +%Y%m%d%H%M)" && \
                echo "  -> [备份] 旧 terminator 配置已备份至 ${TERMINATOR_CONF_DST}.bak_*"
            fi
            mkdir -p "$HOME/.config/terminator"
            cp "$TERMINATOR_CONF_SRC" "$TERMINATOR_CONF_DST"
            echo "  -> [成功] Terminator 主题已写入 $TERMINATOR_CONF_DST"
        else
            warn "conf/terminator.config 源文件不存在，跳过主题注入： $TERMINATOR_CONF_SRC"
        fi
    else
        warn "Terminator 未安装，跳过主题注入。"
    fi
}

# [阶段7] Docker & NVIDIA Container Toolkit 配置
install_docker_and_ctk() {
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
        echo "  -> [跳过] NVIDIA Container Toolkit 已安装"
    fi
}

# [阶段8] 安装 Conda 与 Rust级纯享 uv 包管理器
install_python_ml_toolchain() {
    info "[8/9] 安装 Python 极速工具 (uv) 与 Miniconda3..."
    if ! command -v uv &> /dev/null; then
        curl -m 15 -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL="/usr/local/bin" sh || warn "uv 安装失败 (可能需要代理)"
    else
        echo "  -> [跳过] uv 已经存在"
    fi
    
    if [ ! -d "$HOME/miniconda3" ]; then
        local os_name arch miniconda_url
        os_name=$(uname -s)
        arch=$(uname -m)
        if [ "$os_name" = "Darwin" ]; then
            if [ "$arch" = "arm64" ]; then
                miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
            else
                miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
            fi
        else
            miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
        fi
        
        mkdir -p ~/miniconda3
        wget "$miniconda_url" -O ~/miniconda3/miniconda.sh || true
        bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 || warn "Miniconda 安装遇到错误"
        rm ~/miniconda3/miniconda.sh
        # 自动初始化 conda
        ~/miniconda3/bin/conda init bash || true
        ~/miniconda3/bin/conda init zsh || true
    else
        echo "  -> [跳过] miniconda3 目录已存在"
    fi
}

# [阶段9] 部署 GPU 驱动更新
install_nvidia_drivers() {
    info "[9/9] 自动更新 NVIDIA 显卡驱动并清理环境..."
    sudo add-apt-repository -y ppa:graphics-drivers/ppa || true
    sudo apt-get update || true
    install_apt_pkgs "${NVIDIA_DRIVER_TOOLS[@]}"
    sudo ubuntu-drivers autoinstall || warn "ubuntu-drivers 安装闭源驱动时发生异常"
    sudo apt-get autoremove -y
    sudo apt-get clean
}
