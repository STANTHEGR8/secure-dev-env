#!/bin/bash
# Master Installation Script - FULLY CORRECTED
# Handles errors gracefully and runs in correct order

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

LOG_FILE="/var/log/secure-dev-env-install.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    error "Do not run this script as root. Run as normal user with sudo privileges."
    exit 1
fi

# Verify sudo access
if ! sudo -v; then
    error "This script requires sudo privileges."
    exit 1
fi

echo "========================================"
echo "Secure Development Environment Installer"
echo "========================================"
echo ""
info "Project root: $PROJECT_ROOT"
info "Log file: $LOG_FILE"
echo ""

# ==========================================
# Phase 1: Base System Configuration
# ==========================================
log "Phase 1: Configuring base system..."

info "Backing up existing sources.list..."
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d) 2>/dev/null || true

info "Configuring APT sources for Debian Bookworm..."
sudo tee /etc/apt/sources.list > /dev/null << 'EOF'
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
EOF

info "Updating package lists..."
sudo apt update

info "Upgrading existing packages..."
sudo apt upgrade -y

info "Installing essential packages..."
ESSENTIAL_PACKAGES=(
    "sudo" "vim" "curl" "wget" "git" "build-essential"
    "apt-transport-https" "ca-certificates" "gnupg" "lsb-release"
    "net-tools" "dnsutils" "iputils-ping" "htop" "sysstat"
)

for package in "${ESSENTIAL_PACKAGES[@]}"; do
    sudo apt install -y "$package" 2>/dev/null || warn "Could not install $package"
done

# ==========================================
# Phase 2: Security Hardening
# ==========================================
log "Phase 2: Applying security hardening..."

# Kernel hardening
info "Applying kernel hardening parameters..."
if [ -f "$PROJECT_ROOT/security/sysctl.conf" ]; then
    sudo cp "$PROJECT_ROOT/security/sysctl.conf" /etc/sysctl.d/99-security-hardening.conf
    sudo sysctl -p /etc/sysctl.d/99-security-hardening.conf 2>/dev/null || warn "Some sysctl parameters failed (normal on first run)"
else
    warn "sysctl.conf not found, skipping kernel hardening"
fi

# AppArmor installation
info "Installing AppArmor..."
sudo apt install -y apparmor apparmor-utils apparmor-profiles apparmor-profiles-extra

# Enable AppArmor in GRUB (requires reboot)
if ! grep -q "apparmor=1" /etc/default/grub 2>/dev/null; then
    info "Enabling AppArmor in GRUB..."
    sudo sed -i.bak 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 apparmor=1 security=apparmor"/' /etc/default/grub
    sudo update-grub
    warn "AppArmor requires REBOOT to activate"
fi

# Copy AppArmor profiles
if [ -d "$PROJECT_ROOT/security/apparmor-profiles" ]; then
    info "Installing custom AppArmor profiles..."
    sudo cp "$PROJECT_ROOT/security/apparmor-profiles"/* /etc/apparmor.d/ 2>/dev/null || true
fi

# Firewall - nftables
info "Installing nftables firewall..."
sudo apt install -y nftables

# Create minimal working firewall config
sudo tee /etc/nftables.conf > /dev/null << 'NFTEOF'
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        iif lo accept
        ct state established,related accept
        ct state invalid drop
        ip protocol icmp accept
        ip6 nexthdr ipv6-icmp accept
        tcp dport 22 ct state new limit rate 3/minute accept
        udp sport 68 udp dport 67 accept
        reject
    }
    
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
NFTEOF

sudo chmod +x /etc/nftables.conf

# Test and enable firewall
if sudo nft -c -f /etc/nftables.conf; then
    sudo nft -f /etc/nftables.conf
    sudo systemctl enable nftables
    sudo systemctl start nftables || warn "Firewall service failed (may work after reboot)"
else
    warn "Firewall configuration has errors, skipping"
fi

# AIDE installation
info "Installing AIDE file integrity monitoring..."
sudo apt install -y aide aide-common

if [ -f "$PROJECT_ROOT/security/aide.conf" ]; then
    sudo cp "$PROJECT_ROOT/security/aide.conf" /etc/aide/aide.conf
fi

warn "AIDE database initialization will take 5-10 minutes..."
info "You can initialize AIDE later with: sudo aideinit"

# Fail2ban installation
info "Installing Fail2ban..."
sudo apt install -y fail2ban

if [ -f "$PROJECT_ROOT/security/fail2ban/jail.local" ]; then
    sudo mkdir -p /etc/fail2ban
    sudo cp "$PROJECT_ROOT/security/fail2ban/jail.local" /etc/fail2ban/
fi

sudo systemctl enable fail2ban
sudo systemctl start fail2ban || warn "Fail2ban failed to start (check logs)"

# ==========================================
# Phase 3: Privacy Layer
# ==========================================
log "Phase 3: Installing privacy tools..."

# Cloudflared
info "Installing cloudflared..."
CLOUDFLARED_VERSION="2024.12.2"
if wget -q "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-amd64.deb" -O /tmp/cloudflared.deb; then
    sudo dpkg -i /tmp/cloudflared.deb || sudo apt install -f -y
    rm /tmp/cloudflared.deb
    
    if [ -f "$PROJECT_ROOT/privacy/cloudflared-config.yml" ]; then
        sudo mkdir -p /etc/cloudflared
        sudo cp "$PROJECT_ROOT/privacy/cloudflared-config.yml" /etc/cloudflared/config.yml
        
        # Create cloudflared service
        sudo tee /etc/systemd/system/cloudflared.service > /dev/null << 'CFEOF'
[Unit]
Description=cloudflared DNS over HTTPS proxy
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/bin/cloudflared proxy-dns --config /etc/cloudflared/config.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target
CFEOF
        
        sudo systemctl daemon-reload
        sudo systemctl enable cloudflared
        sudo systemctl start cloudflared || warn "Cloudflared failed to start"
    fi
else
    warn "Could not download cloudflared, skipping"
fi

# WireGuard
info "Installing WireGuard..."
sudo apt install -y wireguard wireguard-tools resolvconf

if [ -f "$PROJECT_ROOT/privacy/wireguard/wg0.conf.template" ]; then
    sudo cp "$PROJECT_ROOT/privacy/wireguard/wg0.conf.template" /etc/wireguard/wg0.conf.template
    info "WireGuard template installed at /etc/wireguard/wg0.conf.template"
fi

# ==========================================
# Phase 4: Performance Optimization
# ==========================================
log "Phase 4: Applying performance optimizations..."

# ZRAM (optional, skip if fails)
info "Installing ZRAM..."
if sudo apt install -y zram-tools 2>/dev/null; then
    info "✓ ZRAM installed"
    
    sudo tee /etc/default/zramswap > /dev/null << 'ZRAMEOF'
ALLOCATION=75
ALGO=zstd
ZRAM_DEVICES=1
ZRAMEOF

    sudo systemctl enable zramswap 2>/dev/null || true
    sudo systemctl restart zramswap 2>/dev/null || warn "ZRAM service failed"
else
    warn "ZRAM installation failed (network issue), skipping"
    warn "You can install it later with: sudo apt install zram-tools"
fi

# Continue with I/O scheduler regardless of ZRAM status
info "Configuring I/O scheduler..."
# I/O Scheduler
info "Configuring I/O scheduler..."
sudo tee /etc/udev/rules.d/60-ioschedulers.rules > /dev/null << 'UDEVEOF'
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
UDEVEOF

sudo udevadm control --reload-rules
sudo udevadm trigger

# Disable unnecessary services
info "Disabling unnecessary services..."
SERVICES_TO_DISABLE=("bluetooth" "cups" "cups-browsed" "avahi-daemon" "ModemManager")

for service in "${SERVICES_TO_DISABLE[@]}"; do
    if systemctl is-active "$service" &>/dev/null; then
        sudo systemctl disable --now "$service" 2>/dev/null && info "Disabled: $service" || true
    fi
done

# ==========================================
# Phase 5: Developer Tools
# ==========================================
log "Phase 5: Installing developer tools..."

# Docker
info "Installing Docker..."
sudo apt install -y ca-certificates curl gnupg

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

# Programming languages
info "Installing programming languages..."
sudo apt install -y python3 python3-pip python3-venv python3-dev
sudo apt install -y openjdk-17-jdk || warn "Java installation failed"

# Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 2>/dev/null || warn "Node.js repo setup failed"
sudo apt install -y nodejs || warn "Node.js installation failed"

# VS Code
info "Installing VS Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
rm packages.microsoft.gpg

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
    sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

sudo apt update
sudo apt install -y code || warn "VS Code installation failed"

echo "Installing Failed Packages and Checking"
./install-failed-packages.sh  # Calls the second script

# ==========================================
# Completion
# ==========================================
log "Installation complete!"

echo ""
echo "========================================"
echo "         INSTALLATION COMPLETE"
echo "========================================"
echo ""
echo "✓ Base system configured"
echo "✓ Security hardening applied"
echo "✓ Privacy tools installed"
echo "✓ Performance optimized"
echo "✓ Developer tools installed"
echo ""
echo "⚠️  CRITICAL: REBOOT REQUIRED"
echo ""
echo "Many changes (especially AppArmor) require a reboot to activate."
echo ""
echo "After reboot:"
echo "  1. Verify installation: sudo systemctl status apparmor nftables fail2ban"
echo "  2. Check security: security-status (if installed)"
echo "  3. Configure VPN: sudo nano /etc/wireguard/wg0.conf.template"
echo ""
echo "Full log: $LOG_FILE"
echo ""

read -p "Reboot now? (RECOMMENDED) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo reboot
fi



