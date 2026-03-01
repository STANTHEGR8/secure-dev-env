#!/bin/bash
# System Configuration Validation Script

echo "Validating secure development environment configuration..."
echo ""

PASS=0
FAIL=0

check() {
    local name="$1"
    local command="$2"
    
    # Run command and capture status without exiting the script
    if eval "$command" >/dev/null 2>&1; then
        echo "✓ $name"
        ((PASS++))
    else
        echo "✗ $name (Failed or Not Installed)"
        ((FAIL++))
    fi
}

# Security checks
echo "=== Security Validation ==="
check "AppArmor enabled" "sudo aa-status --enabled"
check "Firewall active" "sudo systemctl is-active --quiet nftables"
check "Fail2ban running" "sudo systemctl is-active --quiet fail2ban"
check "AIDE installed" "command -v aide"
check "ASLR enabled" "[ \$(cat /proc/sys/kernel/randomize_va_space) -eq 2 ]"

# Privacy checks
echo ""
echo "=== Privacy Validation ==="
check "Cloudflared installed" "command -v cloudflared"
check "WireGuard installed" "command -v wg"
check "DNS encryption configured" "[ -f /etc/cloudflared/config.yml ]"

# Performance checks
echo ""
echo "=== Performance Validation ==="
check "ZRAM active" "swapon --show | grep -q zram"
check "BFQ scheduler" "ls /sys/block/sd*/queue/scheduler | xargs grep -q bfq 2>/dev/null"

# Developer tools checks
echo ""
echo "=== Developer Tools Validation ==="
check "Docker installed" "command -v docker"
check "Python3 installed" "command -v python3"
check "Node.js installed" "command -v node"
check "Java installed" "command -v java"
check "GCC installed" "command -v gcc"
check "VS Code installed" "command -v code"

# Summary
echo ""
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ $FAIL -eq 0 ]; then
    echo "✓ All checks passed!"
else
    echo "✗ Some checks failed. Review configuration."
fi
