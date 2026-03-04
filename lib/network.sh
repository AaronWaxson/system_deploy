#!/bin/bash
# ==============================================================================
# Network Utilities: Mirrors, Proxies, and HTTP Wrappers
# ==============================================================================

# 获取最优的 Github 节点
# 自动轮询测速可用的加速镜像 (国内免翻墙拉取 Github)
get_fastest_github_mirror() {
    local mirrors=(
        "https://kkgithub.com"
        "https://mirror.ghproxy.com/https://github.com"
        "https://github.moeyy.xyz/https://github.com"
        "https://gitclone.com/github.com"
        "https://github.com"
    )
    local best_mirror="https://github.com"
    local min_time=999999
    
    info "正在测速轮询可用的 GitHub 镜像节点 (超时设置 2s)..." >&2
    for mirror in "${mirrors[@]}"; do
        # 测速访问一个已知存在的库头
        local result
        result=$(curl -sI -m 2 -o /dev/null -w "%{http_code} %{time_total}" "${mirror}/retorquere/zotero-deb" 2>/dev/null) || true
        local http_code
        http_code=$(echo "$result" | awk '{print $1}')
        local time_total
        time_total=$(echo "$result" | awk '{print $2}')
        
        if [[ "$http_code" == "200" || "$http_code" == "301" || "$http_code" == "302" ]]; then
            local is_faster=$(awk -v t1="${time_total:-999}" -v t2="$min_time" 'BEGIN{print (t1 < t2) ? 1 : 0}')
            if [ "$is_faster" -eq 1 ]; then
                min_time=$time_total
                best_mirror=$mirror
            fi
        fi
    done
    
    if [ "$min_time" = "999999" ]; then
        warn "所有镜像节点测试均超时或失败，无奈回退至原生 GitHub。" >&2
    else
        info ">>> 🎯 锁定最快 GitHub 节点: $best_mirror (延迟: ${min_time}s)" >&2
    fi
    echo "$best_mirror"
}

# 导出全局的 GH_MIRROR，以便各个需要 git clone 的地方直接使用
declare -g GH_MIRROR
GH_MIRROR=$(get_fastest_github_mirror)

get_gh_raw_mirror() {
    echo "$GH_MIRROR" | sed 's#https://github.com#https://raw.githubusercontent.com#'
}
