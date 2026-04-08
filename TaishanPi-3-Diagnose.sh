#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${NC} $*"; }
warn() { echo -e "  ${YELLOW}[!!]${NC} $*"; }
err()  { echo -e "  ${RED}[ERR]${NC} $*"; }
info() { echo -e "  ${CYAN}[--]${NC} $*"; }

ISSUES=0
FIXES=""

echo -e "\n${BOLD}${CYAN}=== TaishanPi-3 Environment Diagnostic ===${NC}\n"

echo -e "${BOLD}1. APT Lock Status${NC}"
apt_procs=$(ps aux 2>/dev/null | grep -E '(apt-get|dpkg|packagekitd|unattended-upgr|aptd)' | grep -v grep)
if [[ -n "$apt_procs" ]]; then
    err "Processes holding or competing for APT lock:"
    echo "$apt_procs" | while read -r line; do
        info "  $line"
    done
    if echo "$apt_procs" | grep -q "packagekitd"; then
        warn "packagekitd is running (Ubuntu desktop auto-update daemon)"
        FIXES+="FIX_PACKAGEKIT "
    fi
    if echo "$apt_procs" | grep -q "unattended-upgr"; then
        warn "unattended-upgrades is running"
        FIXES+="FIX_UNATTENDED "
    fi
    ((ISSUES++))
else
    ok "No processes holding APT lock"
fi

if sudo fuser /var/lib/dpkg/lock-frontend 2>/dev/null; then
    err "dpkg lock-frontend is held"
    ((ISSUES++))
else
    ok "dpkg lock-frontend is free"
fi
echo ""

echo -e "${BOLD}2. DNS Resolution${NC}"
dns_ok=true
for domain in mirrors.cernet.edu.cn mirrors.tuna.tsinghua.edu.cn mirrors.aliyun.com security.ubuntu.com archive.ubuntu.com github.com; do
    ip=$(dig +short "$domain" 2>/dev/null | head -1)
    if [[ -z "$ip" ]]; then
        ip=$(getent hosts "$domain" 2>/dev/null | awk '{print $1}' | head -1)
    fi
    if [[ -z "$ip" ]]; then
        err "$domain -> FAILED (cannot resolve)"
        dns_ok=false
        ((ISSUES++))
    elif [[ "$ip" =~ ^198\.18\. || "$ip" =~ ^127\. || "$ip" =~ ^0\. ]]; then
        err "$domain -> $ip (SUSPICIOUS - likely DNS hijack or proxy)"
        dns_ok=false
        FIXES+="FIX_DNS "
        ((ISSUES++))
    else
        ok "$domain -> $ip"
    fi
done
$dns_ok || warn "DNS issues detected. Check /etc/resolv.conf and proxy settings"
echo ""

echo -e "${BOLD}3. Proxy / Network Environment${NC}"
proxy_found=false
for var in http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy; do
    val="${!var}"
    if [[ -n "$val" ]]; then
        info "$var=$val"
        proxy_found=true
    fi
done
if [[ -f /etc/apt/apt.conf.d/proxy.conf ]] || grep -rq "Acquire::http::Proxy" /etc/apt/apt.conf.d/ 2>/dev/null; then
    info "APT proxy configured in /etc/apt/apt.conf.d/"
    grep -rh "Acquire::http::Proxy" /etc/apt/apt.conf.d/ 2>/dev/null | while read -r line; do
        info "  $line"
    done
    proxy_found=true
fi
if $proxy_found; then
    warn "Proxy detected - this may cause apt download failures"
    FIXES+="FIX_PROXY "
    ((ISSUES++))
else
    ok "No proxy environment variables set"
fi
echo ""

echo -e "${BOLD}4. Mirror Connectivity${NC}"
for mirror in "http://mirrors.cernet.edu.cn/ubuntu/dists/jammy/Release" \
              "http://mirrors.tuna.tsinghua.edu.cn/ubuntu/dists/jammy/Release" \
              "http://mirrors.aliyun.com/ubuntu/dists/jammy/Release" \
              "http://security.ubuntu.com/ubuntu/dists/jammy-security/Release"; do
    domain=$(echo "$mirror" | awk -F/ '{print $3}')
    code=$(curl -o /dev/null -s -w '%{http_code}' --connect-timeout 10 --max-time 15 "$mirror" 2>/dev/null)
    if [[ "$code" == "200" || "$code" == "302" ]]; then
        ok "$domain -> HTTP $code"
    elif [[ "$code" == "000" ]]; then
        err "$domain -> Connection failed (timeout/refused)"
        ((ISSUES++))
    else
        warn "$domain -> HTTP $code"
        ((ISSUES++))
    fi
done
echo ""

echo -e "${BOLD}5. APT Package Index${NC}"
info "Current sources.list:"
grep -v '^#' /etc/apt/sources.list 2>/dev/null | grep -v '^$' | while read -r line; do
    info "  $line"
done
echo ""
for pkg in cmake qemu-user-static bison gcc-aarch64-linux-gnu; do
    if apt-cache show "$pkg" > /dev/null 2>&1; then
        ok "Package index has: $pkg"
    else
        err "Package index MISSING: $pkg"
        FIXES+="FIX_APT_INDEX "
        ((ISSUES++))
    fi
done
echo ""

echo -e "${BOLD}6. System Resources${NC}"
mem_total=$(free -m | awk '/Mem:/{print $2}')
mem_avail=$(free -m | awk '/Mem:/{print $7}')
if [[ $mem_avail -lt 512 ]]; then
    warn "Low available memory: ${mem_avail}MB / ${mem_total}MB (apt may OOM)"
    ((ISSUES++))
else
    ok "Memory: ${mem_avail}MB available / ${mem_total}MB total"
fi

disk_avail=$(df -BG / | awk 'NR==2{print $4}' | tr -d 'G')
if [[ $disk_avail -lt 10 ]]; then
    err "Critically low disk: ${disk_avail}GB (apt needs space for downloads)"
    ((ISSUES++))
else
    ok "Disk: ${disk_avail}GB available"
fi
echo ""

echo -e "${BOLD}${CYAN}=== Diagnostic Summary ===${NC}\n"

if [[ $ISSUES -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}All checks passed. Environment looks healthy.${NC}\n"
    exit 0
fi

echo -e "  ${YELLOW}${BOLD}Found $ISSUES issue(s). Recommended fixes:${NC}\n"

if [[ "$FIXES" == *"FIX_PACKAGEKIT"* ]]; then
    echo -e "  ${BOLD}>> Stop PackageKit (holding apt lock):${NC}"
    echo -e "     ${CYAN}sudo systemctl stop packagekit${NC}"
    echo -e "     ${CYAN}sudo systemctl disable packagekit${NC}"
    echo ""
fi

if [[ "$FIXES" == *"FIX_UNATTENDED"* ]]; then
    echo -e "  ${BOLD}>> Stop unattended-upgrades:${NC}"
    echo -e "     ${CYAN}sudo systemctl stop unattended-upgrades${NC}"
    echo -e "     ${CYAN}sudo systemctl disable unattended-upgrades${NC}"
    echo ""
fi

if [[ "$FIXES" == *"FIX_DNS"* ]]; then
    echo -e "  ${BOLD}>> Fix DNS (suspicious resolution detected):${NC}"
    echo -e "     Check if a VPN/proxy is hijacking DNS."
    echo -e "     Try using public DNS temporarily:"
    echo -e "     ${CYAN}echo 'nameserver 223.5.5.5' | sudo tee /etc/resolv.conf${NC}"
    echo -e "     ${CYAN}echo 'nameserver 8.8.8.8' | sudo tee -a /etc/resolv.conf${NC}"
    echo ""
fi

if [[ "$FIXES" == *"FIX_PROXY"* ]]; then
    echo -e "  ${BOLD}>> Proxy may interfere with apt downloads:${NC}"
    echo -e "     If not needed, unset proxy for this session:"
    echo -e "     ${CYAN}unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY${NC}"
    echo ""
fi

if [[ "$FIXES" == *"FIX_APT_INDEX"* ]]; then
    echo -e "  ${BOLD}>> APT package index is incomplete:${NC}"
    echo -e "     ${CYAN}sudo apt-get update${NC}"
    echo -e "     If that fails, check sources.list and DNS first."
    echo ""
fi

echo -e "  ${BOLD}After fixing, re-run the install script.${NC}\n"
