#!/bin/bash
# ==============================================================================
# AD Environment Package Configurations
# ==============================================================================

# 基础系统工具 (Base System & Network Tools)
BASE_TOOLS=(
    snapd wget curl git gnupg software-properties-common
    apt-transport-https ca-certificates lsb-release
)

# 核心 C++ 开发、编译及系统监控工具 (Core C++ & Monitoring)
CPP_CORE_TOOLS=(
    build-essential cmake ninja-build ccache
    gcc g++ clang clang-format clang-tidy gdb valgrind
    git-lfs rsync tmux screen htop btop tree jq unzip zip
)

# 工作流效率与终端工具 (Workflow Productivity & Terminals)
WORKFLOW_TOOLS=(copyq filezilla terminator)

# 多媒体查看、截图录制工具 (Multimedia & Visualization)
MEDIA_TOOLS=(
    ffmpeg libopencv-dev imagemagick
    eog feh mpv vlc gwenview okular
    shutter peek simplescreenrecorder
    libgl1 libglx-mesa0 libcanberra-gtk-module
    sqlitebrowser
)

# AppImage 基础支持库 (Joplin / Clash)
APPIMAGE_LIBS=(libfuse2)

# NVIDIA 常用驱动工具
NVIDIA_DRIVER_TOOLS=(ubuntu-drivers-common)
