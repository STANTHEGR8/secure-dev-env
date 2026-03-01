#!/bin/bash
# Master Installation Script
# Orchestrates complete system deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/secure-dev-env-install.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

log "Starting installation..."

# Phase 1: Base System
log "Phase 1: Configuring base system..."
sudo cp "$SCRIPT_DIR/../base-system/sources.list" /etc/apt/sources.list
sudo apt update && sudo apt upgrade -y

# Phase 2: Security Hardening
log "Phase 2: Applying security hardening..."
bash "$SCRIPT_DIR/../security/security-setup.sh"

# Phase 3: Privacy Layer
log "Phase 3: Installing privacy tools..."
bash "$SCRIPT_DIR/../privacy/doh-setup.sh"
bash "$SCRIPT_DIR/../privacy/vpn-setup.sh"

# Phase 4: Performance Optimization
log "Phase 4: Applying performance optimizations..."
bash "$SCRIPT_DIR/../performance/zram-config.sh"
bash "$SCRIPT_DIR/../performance/io-scheduler.sh"

# Phase 5: Developer Tools
log "Phase 5: Installing developer tools..."
bash "$SCRIPT_DIR/../developer-tools/install-docker.sh"
bash "$SCRIPT_DIR/../developer-tools/install-languages.sh"
bash "$SCRIPT_DIR/../developer-tools/install-ide.sh"

# Phase 6: Customization
log "Phase 6: Applying system customization..."
# Add customization steps here
#!/bin/bash
./custom-one.sh
echo "Customization done. Reboot to apply it automatically."


log "Installation complete!"
echo ""
echo "========================================"
echo "Installation Summary"
echo "========================================"
echo "✓ Base system configured"
echo "✓ Security hardening applied"
echo "✓ Privacy tools installed"
echo "✓ Performance optimized"
echo "✓ Developer tools ready"
echo ""
echo "Next steps:"
echo "1. Log out and back in for group changes"
echo "2. Configure VPN credentials in /etc/wireguard/wg0.conf"
echo "3. Run 'security-status' to verify configuration"
echo ""

echo "Full log: $LOG_FILE"
