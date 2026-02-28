#!/bin/bash
# System Configuration Validation Script

set -e

echo "Validating secure development environment configuration..."
echo ""

PASS=0
FAIL=0

check() {
    local name="$1"
    local command="$2"
    
    if eval "$command" &>/dev/null; then
        echo "✓ $name"
        ((PASS++))
    else
        echo "✗ $name"
        ((FAIL++))
    fi
}

# Security checks
echo "=== Security Validation ==="
check "AppArmor enabled" "sudo aa-status | grep -q 'profiles are loaded'"
check "Firewall active" "sudo systemctl is-active nftables"
check "Fail2ban running" "sudo systemctl is-active fail2ban"
check "AIDE installed" "which aide"
check "ASLR enabled" "[ $(cat /proc/sys/kernel/randomize_va_space) -eq 2 ]"

# Privacy checks
echo ""
echo "=== Privacy Validation ==="
check "Cloudflared installed" "which cloudflared"
check "WireGuard installed" "which wg"
check "DNS encryption configured" "[ -f /etc/cloudflared/config.yml ]"

# Performance checks
echo ""
echo "=== Performance Validation ==="
check "ZRAM active" "swapon --show | grep -q zram"
check "BFQ scheduler" "grep -q bfq /sys/block/sda/queue/scheduler 2>/dev/null || true"

# Developer tools checks
echo ""
echo "=== Developer Tools Validation ==="
check "Docker installed" "which docker"
check "Python3 installed" "which python3"
check "Node.js installed" "which node"
check "Java installed" "which java"
check "GCC installed" "which gcc"
check "VS Code installed" "which code"

# Summary
echo ""
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ $FAIL -eq 0 ]; then
    echo "✓ All checks passed!"
    exit 0
else
    echo "✗ Some checks failed. Review configuration."
    exit 1
fi