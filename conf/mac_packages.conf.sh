#!/bin/bash
# ==============================================================================
# macOS Environment Package Configurations (对标 Linux 的 ad_packages.conf.sh)
# ==============================================================================

# 核心 C++ 开发工具 (CLI via brew)
MAC_CPP_CORE_TOOLS=(
    cmake ninja ccache llvm
)

# 系统效率与开发辅助工具 (CLI via brew)
MAC_SYSTEM_TOOLS=(
    git-lfs rsync tmux htop btop tree jq unzip zip wget
)

# 多媒体工具 (CLI via brew)
MAC_MEDIA_CLI_TOOLS=(
    ffmpeg imagemagick
)

# 多媒体工具 (GUI via brew cask)
MAC_MEDIA_CASK_TOOLS=(
    mpv vlc
)

# 第三方 GUI 应用 (via brew cask)
MAC_GUI_APPS=(
    visual-studio-code
    microsoft-edge
    warp
    zotero
)

# 开发字体 (via brew cask — Nerd Font 变体包含终端图标支持)
MAC_DEVELOPER_FONTS=(
    font-fira-code-nerd-font
    font-jetbrains-mono
    font-maple-mono-nf
)

# Docker Desktop (via brew cask)
MAC_DOCKER_CASK=(docker)
