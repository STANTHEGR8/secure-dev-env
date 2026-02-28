#!/bin/bash
# Master Installation Script - CORRECTED VERSION
# Orchestrates complete system deployment

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
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
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
fi

# Verify sudo access
if ! sudo -v; then
    error "This script requires sudo privileges."
fi

echo "========================================"
echo "Secure Development Environment Installer"
echo "========================================"
echo ""
info "Project root: $PROJECT_ROOT"
info "Log file: $LOG_FILE"
echo ""

# Verify directory structure
if [ ! -d "$PROJECT_ROOT/base-system" ]; then
    error "Invalid directory structure. Expected 'base-system' directory at $PROJECT_ROOT"
fi

log "Starting installation..."

# ==========================================
# Phase 1: Base System Configuration
# ==========================================
log "Phase 1: Configuring base system..."

if [ -f "$PROJECT_ROOT/base-system/sources.list" ]; then
    info "Backing up existing sources.list..."
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d)
    
    info "Installing new APT sources..."
    sudo cp "$PROJECT_ROOT/base-system/sources.list" /etc/apt/sources.list
    
    info "Updating package lists..."
    if ! sudo apt update; then
        error "Failed to update package lists. Check /etc/apt/sources.list"
    fi
    
    info "Upgrading existing packages..."
    sudo apt upgrade -y
    
    info "Installing minimal required packages..."
    if [ -f "$PROJECT_ROOT/base-system/minimal-packages.txt" ]; then
        # Read packages line by line and install individually to avoid single failure
        while IFS= read -r package || [ -n "$package" ]; do
            # Skip comments and empty lines
            [[ "$package" =~ ^#.*$ ]] && continue
            [[ -z "$package" ]] && continue
            
            # Trim whitespace
            package=$(echo "$package" | xargs)
            
            if sudo apt install -y "$package"; then
                info "✓ Installed: $package"
            else
                warn "✗ Failed to install: $package (skipping)"
            fi
        done < "$PROJECT_ROOT/base-system/minimal-packages.txt"
    fi
else
    warn "sources.list not found. Skipping base system configuration."
fi

# Fix broken dependencies if any
info "Fixing any broken dependencies..."
sudo apt --fix-broken install -y
sudo apt autoremove -y

# ==========================================
# Phase 2: Security Hardening
# ==========================================
log "Phase 2: Applying security hardening..."

# Install sysctl parameters
if [ -f "$PROJECT_ROOT/security/sysctl.conf" ]; then
    info "Applying kernel hardening parameters..."
    sudo cp "$PROJECT_ROOT/security/sysctl.conf" /etc/sysctl.d/99-security-hardening.conf
    sudo sysctl -p /etc/sysctl.d/99-security-hardening.conf
fi

# Install AppArmor
info "Installing and configuring AppArmor..."
sudo apt install -y apparmor apparmor-utils apparmor-profiles apparmor-profiles-extra

if [ -d "$PROJECT_ROOT/security/apparmor-profiles" ]; then
    info "Installing custom AppArmor profiles..."
    sudo cp "$PROJECT_ROOT/security/apparmor-profiles"/* /etc/apparmor.d/ 2>/dev/null || true
fi

# Enable AppArmor in GRUB
if ! grep -q "apparmor=1" /etc/default/grub; then
    info "Enabling AppArmor in GRUB..."
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="apparmor=1 security=apparmor /' /etc/default/grub
    sudo update-grub
fi

sudo systemctl enable apparmor
sudo systemctl start apparmor

# Install nftables firewall
# Install nftables firewall
info "Installing and configuring nftables firewall..."
sudo apt install -y nftables

if [ -f "$PROJECT_ROOT/security/nftables.conf" ]; then
    # Backup existing config
    if [ -f /etc/nftables.conf ]; then
        sudo cp /etc/nftables.conf /etc/nftables.conf.backup
    fi
    
    # Copy new config
    sudo cp "$PROJECT_ROOT/security/nftables.conf" /etc/nftables.conf
    sudo chmod +x /etc/nftables.conf
    
    # Test configuration before enabling service
    info "Testing nftables configuration..."
    if sudo nft -c -f /etc/nftables.conf; then
        info "✓ nftables configuration is valid"
        
        # Load rules
        if sudo nft -f /etc/nftables.conf; then
            info "✓ nftables rules loaded successfully"
            
            # Enable service
            sudo systemctl enable nftables
            sudo systemctl start nftables
            
            if sudo systemctl is-active nftables &>/dev/null; then
                info "✓ nftables service is running"
            else
                warn "nftables service failed to start"
                warn "Check logs: sudo journalctl -xeu nftables.service"
            fi
        else
            error "Failed to load nftables rules"
        fi
    else
        error "nftables configuration has syntax errors"
    fi
else
    warn "nftables.conf not found. Skipping firewall configuration."
fi

# Install AIDE
info "Installing AIDE file integrity monitoring..."
sudo apt install -y aide aide-common

if [ -f "$PROJECT_ROOT/security/aide.conf" ]; then
    sudo cp "$PROJECT_ROOT/security/aide.conf" /etc/aide/aide.conf
fi

info "Initializing AIDE database (this may take 5-10 minutes)..."
sudo aideinit
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Install Fail2ban
info "Installing and configuring Fail2ban..."
sudo apt install -y fail2ban

if [ -f "$PROJECT_ROOT/security/fail2ban/jail.local" ]; then
    sudo mkdir -p /etc/fail2ban
    sudo cp "$PROJECT_ROOT/security/fail2ban/jail.local" /etc/fail2ban/
    sudo systemctl enable fail2ban
    sudo systemctl restart fail2ban
fi

# ==========================================
# Phase 3: Privacy Layer
# ==========================================
log "Phase 3: Installing privacy tools..."

# Install cloudflared (DNS-over-HTTPS)
info "Installing cloudflared for DNS-over-HTTPS..."
CLOUDFLARED_VERSION="2024.12.2"
wget -q "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-amd64.deb" -O /tmp/cloudflared.deb
sudo dpkg -i /tmp/cloudflared.deb || sudo apt install -f -y
rm /tmp/cloudflared.deb

if [ -f "$PROJECT_ROOT/privacy/cloudflared-config.yml" ]; then
    sudo mkdir -p /etc/cloudflared
    sudo cp "$PROJECT_ROOT/privacy/cloudflared-config.yml" /etc/cloudflared/config.yml
    
    # Create systemd service
    sudo tee /etc/systemd/system/cloudflared.service > /dev/null << 'EOF'
[Unit]
Description=cloudflared DNS over HTTPS proxy
After=network.target

[Service]
Type=simple
User=cloudflared
ExecStart=/usr/local/bin/cloudflared proxy-dns --config /etc/cloudflared/config.yml
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Create cloudflared user
    sudo useradd -r -s /usr/sbin/nologin cloudflared 2>/dev/null || true
    
    sudo systemctl daemon-reload
    sudo systemctl enable cloudflared
    sudo systemctl start cloudflared
    
    # Configure system DNS
    info "Configuring system DNS to use cloudflared..."
    echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf > /dev/null
    echo "options edns0" | sudo tee -a /etc/resolv.conf > /dev/null
    sudo chattr +i /etc/resolv.conf
fi

# Install WireGuard
info "Installing WireGuard VPN..."
sudo apt install -y wireguard wireguard-tools resolvconf

if [ -f "$PROJECT_ROOT/privacy/wireguard/wg0.conf.template" ]; then
    sudo cp "$PROJECT_ROOT/privacy/wireguard/wg0.conf.template" /etc/wireguard/wg0.conf.template
    warn "WireGuard template installed. Edit /etc/wireguard/wg0.conf.template with your VPN details."
fi

# Install Tor Browser (optional)
read -p "Install Tor Browser? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$PROJECT_ROOT/privacy/tor-browser-setup.sh" ]; then
        bash "$PROJECT_ROOT/privacy/tor-browser-setup.sh"
    fi
fi

# ==========================================
# Phase 4: Performance Optimization
# ==========================================
log "Phase 4: Applying performance optimizations..."

# Configure ZRAM
if [ -f "$PROJECT_ROOT/performance/zram-config.sh" ]; then
    bash "$PROJECT_ROOT/performance/zram-config.sh"
fi

# Configure I/O scheduler
if [ -f "$PROJECT_ROOT/performance/io-scheduler.sh" ]; then
    bash "$PROJECT_ROOT/performance/io-scheduler.sh"
fi

# Disable unnecessary services
if [ -f "$PROJECT_ROOT/performance/systemd-services-disable.txt" ]; then
    info "Disabling unnecessary services..."
    while IFS= read -r service; do
        # Skip comments and empty lines
        [[ "$service" =~ ^#.*$ ]] && continue
        [[ -z "$service" ]] && continue
        
        if systemctl is-active "$service" &>/dev/null; then
            sudo systemctl disable --now "$service" 2>/dev/null && \
                info "Disabled: $service" || \
                warn "Could not disable: $service"
        fi
    done < "$PROJECT_ROOT/performance/systemd-services-disable.txt"
fi

# ==========================================
# Phase 5: Developer Tools
# ==========================================
log "Phase 5: Installing developer tools..."

# Install Docker
if [ -f "$PROJECT_ROOT/developer-tools/install-docker.sh" ]; then
    bash "$PROJECT_ROOT/developer-tools/install-docker.sh"
fi

# Install programming languages
if [ -f "$PROJECT_ROOT/developer-tools/install-languages.sh" ]; then
    bash "$PROJECT_ROOT/developer-tools/install-languages.sh"
fi

# Install IDEs
if [ -f "$PROJECT_ROOT/developer-tools/install-ide.sh" ]; then
    bash "$PROJECT_ROOT/developer-tools/install-ide.sh"
fi

# ==========================================
# Phase 6: Utility Scripts Installation
# ==========================================
log "Phase 6: Installing utility scripts..."

if [ -f "$PROJECT_ROOT/customization/security-status" ]; then
    sudo cp "$PROJECT_ROOT/customization/security-status" /usr/local/bin/
    sudo chmod +x /usr/local/bin/security-status
fi

# ==========================================
# Completion
# ==========================================
log "Installation complete!"

echo ""
echo "========================================"
echo "Installation Summary"
echo "========================================"
echo "✓ Base system configured"
echo "✓ Security hardening applied (AppArmor, nftables, AIDE, Fail2ban)"
echo "✓ Privacy tools installed (DNS-over-HTTPS, WireGuard)"
echo "✓ Performance optimized (ZRAM, I/O scheduler, service minimization)"
echo "✓ Developer tools installed (Docker, languages, IDEs)"
echo ""
echo "⚠  IMPORTANT NEXT STEPS:"
echo "1. REBOOT the system to activate all changes"
echo "2. Log out and back in for group changes to take effect"
echo "3. Configure VPN: Edit /etc/wireguard/wg0.conf.template with your VPN credentials"
echo "4. Verify installation: Run 'security-status' command"
echo ""
echo "Documentation:"
echo "  - Full log: $LOG_FILE"
echo "  - Security status: security-status"
echo "  - Validate installation: $PROJECT_ROOT/automation/validate.sh"
echo ""
echo "========================================"

read -p "Reboot now? (recommended) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo reboot

fi

