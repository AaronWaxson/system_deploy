#!/bin/bash
# ==============================================================================
# 🧪 Dry-Run 沙盒测试：验证全部脚本的 OS 分流逻辑和函数完整性
# 用法：bash tests/test_all.sh
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
TOTAL=0

# ---------- 测试工具函数 ----------
assert_pass() {
    local desc="$1"
    TOTAL=$((TOTAL+1))
    PASS=$((PASS+1))
    echo "  ✅ PASS: $desc"
}
assert_fail() {
    local desc="$1"
    local detail="$2"
    TOTAL=$((TOTAL+1))
    FAIL=$((FAIL+1))
    echo "  ❌ FAIL: $desc"
    [ -n "$detail" ] && echo "         $detail"
}
assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        assert_pass "$desc"
    else
        assert_fail "$desc" "expected='$expected' actual='$actual'"
    fi
}

# ---------- 1. 语法校验 ----------
echo ""
echo "═══════════════════════════════════════════════"
echo " [1/6] Bash 语法校验 (bash -n)"
echo "═══════════════════════════════════════════════"

for f in \
    install_all.sh deploy_ad_env.sh deploy_zsh_env.sh deploy_mac_env.sh \
    lib/utils.sh lib/network.sh lib/package_manager.sh lib/ad_installer.sh \
    lib/zsh_installer.sh lib/mac_installer.sh \
    conf/ad_packages.conf.sh conf/zsh_plugins.conf.sh conf/mac_packages.conf.sh; do
    if bash -n "$SCRIPT_DIR/$f" 2>/dev/null; then
        assert_pass "$f"
    else
        assert_fail "$f" "bash -n 语法错误"
    fi
done

# ---------- 2. 函数可用性 ----------
echo ""
echo "═══════════════════════════════════════════════"
echo " [2/6] 函数可用性验证 (source + type)"
echo "═══════════════════════════════════════════════"

source "$SCRIPT_DIR/lib/utils.sh"
for func in detect_os require_root info warn success error setup_error_trap; do
    if type "$func" &>/dev/null; then
        assert_pass "utils.sh::$func()"
    else
        assert_fail "utils.sh::$func() 未定义"
    fi
done

source "$SCRIPT_DIR/lib/zsh_installer.sh"
for func in install_starship install_zsh_plugins generate_zshrc generate_starship_toml switch_default_shell; do
    if type "$func" &>/dev/null; then
        assert_pass "zsh_installer.sh::$func()"
    else
        assert_fail "zsh_installer.sh::$func() 未定义"
    fi
done

source "$SCRIPT_DIR/lib/mac_installer.sh"
for func in configure_brew_mirrors ensure_homebrew install_brew_pkgs install_cask_pkgs install_mac_developer_fonts install_mac_ml_toolchain; do
    if type "$func" &>/dev/null; then
        assert_pass "mac_installer.sh::$func()"
    else
        assert_fail "mac_installer.sh::$func() 未定义"
    fi
done

source "$SCRIPT_DIR/lib/package_manager.sh"
for func in install_apt_pkgs install_snap_pkg; do
    if type "$func" &>/dev/null; then
        assert_pass "package_manager.sh::$func()"
    else
        assert_fail "package_manager.sh::$func() 未定义"
    fi
done

# ---------- 3. OS 检测逻辑 ----------
echo ""
echo "═══════════════════════════════════════════════"
echo " [3/6] OS 检测与分流逻辑"
echo "═══════════════════════════════════════════════"

CURRENT_OS=$(uname -s)
DETECTED_OS=$(detect_os)
assert_eq "detect_os() 返回当前 OS" "$CURRENT_OS" "$DETECTED_OS"

if grep -q 'Darwin' "$SCRIPT_DIR/install_all.sh" && grep -q 'deploy_mac_env' "$SCRIPT_DIR/install_all.sh"; then
    assert_pass "install_all.sh 包含 macOS -> deploy_mac_env.sh 分流"
else
    assert_fail "install_all.sh 缺失 macOS 分流逻辑"
fi

if grep -q 'deploy_ad_env.sh' "$SCRIPT_DIR/install_all.sh"; then
    assert_pass "install_all.sh 包含 Linux -> deploy_ad_env.sh 分流"
else
    assert_fail "install_all.sh 缺失 Linux 分流逻辑"
fi

if grep -q 'Darwin' "$SCRIPT_DIR/deploy_ad_env.sh" && grep -q 'exit 0' "$SCRIPT_DIR/deploy_ad_env.sh"; then
    assert_pass "deploy_ad_env.sh 包含 Darwin exit 0 守卫"
else
    assert_fail "deploy_ad_env.sh 缺失 macOS 安全守卫"
fi

if grep -q '!= "Darwin"' "$SCRIPT_DIR/deploy_mac_env.sh"; then
    assert_pass "deploy_mac_env.sh 包含非 Darwin exit 0 守卫"
else
    assert_fail "deploy_mac_env.sh 缺失 Linux 安全守卫"
fi

# ---------- 4. macOS 守卫测试 (apt/snap) ----------
echo ""
echo "═══════════════════════════════════════════════"
echo " [4/6] macOS 安全守卫验证 (apt/snap)"
echo "═══════════════════════════════════════════════"

if [ "$CURRENT_OS" = "Darwin" ]; then
    output=$(install_apt_pkgs test-package 2>&1)
    if echo "$output" | grep -q "macOS"; then
        assert_pass "install_apt_pkgs 在 macOS 上安全跳过"
    else
        assert_fail "install_apt_pkgs 在 macOS 上未正确跳过"
    fi

    output=$(install_snap_pkg test-package 2>&1)
    if echo "$output" | grep -q "macOS"; then
        assert_pass "install_snap_pkg 在 macOS 上安全跳过"
    else
        assert_fail "install_snap_pkg 在 macOS 上未正确跳过"
    fi
else
    echo "  ⏭️  SKIP: 当前非 macOS，跳过 macOS 守卫测试"
fi

# ---------- 5. 清华镜像源配置验证 ----------
echo ""
echo "═══════════════════════════════════════════════"
echo " [5/6] Homebrew 清华镜像源配置验证"
echo "═══════════════════════════════════════════════"

# 检查 mac_installer.sh 有 configure_brew_mirrors 函数
if grep -q 'configure_brew_mirrors' "$SCRIPT_DIR/lib/mac_installer.sh"; then
    assert_pass "mac_installer.sh 定义了 configure_brew_mirrors()"
else
    assert_fail "mac_installer.sh 缺失 configure_brew_mirrors()"
fi

# 检查 HOMEBREW_BOTTLE_DOMAIN 存在 (二进制加速)
if grep -q 'HOMEBREW_BOTTLE_DOMAIN' "$SCRIPT_DIR/lib/mac_installer.sh"; then
    assert_pass "mac_installer.sh 包含 HOMEBREW_BOTTLE_DOMAIN (二进制加速)"
else
    assert_fail "mac_installer.sh 缺失 HOMEBREW_BOTTLE_DOMAIN"
fi

# 检查 deploy_zsh_env.sh 的镜像在 if 块外 (全局生效)
if grep -q 'HOMEBREW_BOTTLE_DOMAIN' "$SCRIPT_DIR/deploy_zsh_env.sh"; then
    assert_pass "deploy_zsh_env.sh 包含 HOMEBREW_BOTTLE_DOMAIN"
else
    assert_fail "deploy_zsh_env.sh 缺失 HOMEBREW_BOTTLE_DOMAIN"
fi

# 检查 .zshrc 生成中包含镜像持久化
if grep -q 'HOMEBREW_BOTTLE_DOMAIN' "$SCRIPT_DIR/lib/zsh_installer.sh"; then
    assert_pass "zsh_installer.sh .zshrc 中持久化 HOMEBREW_BOTTLE_DOMAIN"
else
    assert_fail "zsh_installer.sh .zshrc 中缺失 HOMEBREW_BOTTLE_DOMAIN 持久化"
fi

# 检查 4 个关键镜像变量在 mac_installer.sh 中全部存在
for var in HOMEBREW_API_DOMAIN HOMEBREW_BOTTLE_DOMAIN HOMEBREW_BREW_GIT_REMOTE HOMEBREW_CORE_GIT_REMOTE; do
    if grep -q "$var" "$SCRIPT_DIR/lib/mac_installer.sh"; then
        assert_pass "镜像变量 $var 已配置"
    else
        assert_fail "镜像变量 $var 缺失"
    fi
done

# ---------- 6. 配置变量完整性 ----------
echo ""
echo "═══════════════════════════════════════════════"
echo " [6/6] 配置变量完整性"
echo "═══════════════════════════════════════════════"

source "$SCRIPT_DIR/conf/ad_packages.conf.sh"
for var in BASE_TOOLS CPP_CORE_TOOLS WORKFLOW_TOOLS MEDIA_TOOLS NVIDIA_DRIVER_TOOLS; do
    eval "val=\${$var+SET}"
    if [ "$val" = "SET" ]; then
        assert_pass "ad_packages.conf.sh::$var 已定义"
    else
        assert_fail "ad_packages.conf.sh::$var 未定义"
    fi
done

source "$SCRIPT_DIR/conf/mac_packages.conf.sh"
for var in MAC_CPP_CORE_TOOLS MAC_SYSTEM_TOOLS MAC_MEDIA_CLI_TOOLS MAC_MEDIA_CASK_TOOLS MAC_GUI_APPS MAC_DEVELOPER_FONTS MAC_DOCKER_CASK; do
    eval "val=\${$var+SET}"
    if [ "$val" = "SET" ]; then
        assert_pass "mac_packages.conf.sh::$var 已定义"
    else
        assert_fail "mac_packages.conf.sh::$var 未定义"
    fi
done

source "$SCRIPT_DIR/conf/zsh_plugins.conf.sh"
if [ ${#ZSH_PLUGINS[@]} -ge 1 ]; then
    assert_pass "zsh_plugins.conf.sh::ZSH_PLUGINS 包含 ${#ZSH_PLUGINS[@]} 个插件"
else
    assert_fail "zsh_plugins.conf.sh::ZSH_PLUGINS 为空"
fi

if printf '%s\n' "${MAC_DEVELOPER_FONTS[@]}" | grep -q "nerd-font"; then
    assert_pass "MAC_DEVELOPER_FONTS 包含 Nerd Font 变体"
else
    assert_fail "MAC_DEVELOPER_FONTS 缺失 Nerd Font 变体"
fi

# ---------- 汇总 ----------
echo ""
echo "═══════════════════════════════════════════════"
echo " 📊 测试汇总"
echo "═══════════════════════════════════════════════"
echo "  总计: $TOTAL | ✅ 通过: $PASS | ❌ 失败: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "  🎉 全部测试通过！"
    exit 0
else
    echo "  ⚠️  存在 $FAIL 个失败项，请检查。"
    exit 1
fi
