#!/bin/bash
# Post-reboot validation

echo "Checking installation status..."

check() {
    if $2 &>/dev/null; then
        echo "✓ $1"
    else
        echo "✗ $1"
    fi
}

check "AppArmor" "sudo aa-status | grep -q 'profiles are loaded'"
check "Firewall (nftables)" "sudo systemctl is-active nftables"
check "Fail2ban" "sudo systemctl is-active fail2ban"
check "ZRAM" "swapon --show | grep -q zram"
check "Docker" "docker --version"
check "Python3" "python3 --version"
check "Node.js" "node --version"
check "VS Code" "code --version"

echo ""
echo "Run 'sudo journalctl -xeu <service>' to debug any failures"
