#!/bin/bash
# ==============================================================================
# 🧪 跨平台沙盒测试执行器
# 自动在 macOS (本机) + Linux (Docker Ubuntu) 两个沙盒中运行完整测试套件
# 用法：bash tests/run_sandbox_tests.sh
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_SCRIPT="$SCRIPT_DIR/tests/test_all.sh"

# Docker 二进制路径探测
find_docker() {
    if command -v docker &> /dev/null; then
        echo "docker"
    elif [ -x "/Applications/Docker.app/Contents/Resources/bin/docker" ]; then
        echo "/Applications/Docker.app/Contents/Resources/bin/docker"
    elif [ -x "/usr/local/bin/docker" ]; then
        echo "/usr/local/bin/docker"
    else
        echo ""
    fi
}

MAC_PASS=0
MAC_FAIL=0
LINUX_PASS=0
LINUX_FAIL=0

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     🧪 system_deploy 跨平台沙盒测试 (macOS + Linux)         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"

# ============================================================
# 沙盒 1: macOS (本机原生环境)
# ============================================================
echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│  🍎 沙盒 1/2: macOS 本机测试                │"
echo "└─────────────────────────────────────────────┘"
echo ""

mac_output=$(bash "$TEST_SCRIPT" 2>&1)
mac_exit=$?
echo "$mac_output"

# 解析 macOS 结果
MAC_PASS=$(echo "$mac_output" | sed -n 's/.*通过: \([0-9]*\).*/\1/p' | tail -1)
MAC_FAIL=$(echo "$mac_output" | sed -n 's/.*失败: \([0-9]*\).*/\1/p' | tail -1)
[ -z "$MAC_PASS" ] && MAC_PASS=0
[ -z "$MAC_FAIL" ] && MAC_FAIL=0

# ============================================================
# 沙盒 2: Linux (Docker Ubuntu 22.04)
# ============================================================
echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│  🐧 沙盒 2/2: Linux Docker 测试             │"
echo "└─────────────────────────────────────────────┘"
echo ""

DOCKER_BIN=$(find_docker)

if [ -z "$DOCKER_BIN" ]; then
    echo "  ⚠️  Docker 未安装，跳过 Linux 沙盒测试。"
    echo "  💡 安装方式: brew install --cask docker"
    LINUX_PASS="SKIP"
    LINUX_FAIL="SKIP"
else
    # 检查 Docker daemon 是否在运行
    if ! "$DOCKER_BIN" info &> /dev/null; then
        echo "  ⚠️  Docker daemon 未运行，尝试启动 Docker Desktop..."
        open -a Docker 2>/dev/null || true
        
        # 等待 Docker 就绪 (最多 60 秒)
        for i in $(seq 1 30); do
            "$DOCKER_BIN" info &> /dev/null && break
            echo "  ⏳ 等待 Docker 启动... ($i/30)"
            sleep 2
        done
        
        if ! "$DOCKER_BIN" info &> /dev/null; then
            echo "  ❌ Docker daemon 启动超时，跳过 Linux 沙盒测试。"
            LINUX_PASS="SKIP"
            LINUX_FAIL="SKIP"
        fi
    fi
    
    if [ "$LINUX_PASS" != "SKIP" ]; then
        echo "  📦 正在拉取 Ubuntu 22.04 镜像 (首次可能需要下载)..."
        "$DOCKER_BIN" pull ubuntu:22.04 -q 2>/dev/null || true
        
        echo ""
        linux_output=$("$DOCKER_BIN" run --rm -v "$SCRIPT_DIR:/deploy:ro" ubuntu:22.04 bash /deploy/tests/test_all.sh 2>&1)
        linux_exit=$?
        echo "$linux_output"
        
        # 解析 Linux 结果
        LINUX_PASS=$(echo "$linux_output" | sed -n 's/.*通过: \([0-9]*\).*/\1/p' | tail -1)
        LINUX_FAIL=$(echo "$linux_output" | sed -n 's/.*失败: \([0-9]*\).*/\1/p' | tail -1)
        [ -z "$LINUX_PASS" ] && LINUX_PASS=0
        [ -z "$LINUX_FAIL" ] && LINUX_FAIL=0
    fi
fi

# ============================================================
# 汇总报告
# ============================================================
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    📊 沙盒测试汇总报告                        ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
printf "║  🍎 macOS   │ ✅ 通过: %-4s │ ❌ 失败: %-4s              ║\n" "$MAC_PASS" "$MAC_FAIL"
printf "║  🐧 Linux   │ ✅ 通过: %-4s │ ❌ 失败: %-4s              ║\n" "$LINUX_PASS" "$LINUX_FAIL"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# 计算总退出码
TOTAL_FAIL=0
[ "$MAC_FAIL" != "SKIP" ] && [ "$MAC_FAIL" != "0" ] && TOTAL_FAIL=$((TOTAL_FAIL + MAC_FAIL))
[ "$LINUX_FAIL" != "SKIP" ] && [ "$LINUX_FAIL" != "0" ] && TOTAL_FAIL=$((TOTAL_FAIL + LINUX_FAIL))

if [ "$TOTAL_FAIL" -eq 0 ]; then
    echo "  🎉 所有沙盒测试全部通过！"
    exit 0
else
    echo "  ⚠️  存在 $TOTAL_FAIL 个失败项，请检查。"
    exit 1
fi
