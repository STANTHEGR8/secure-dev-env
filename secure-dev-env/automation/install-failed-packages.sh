#!/bin/bash
# Script to Install Failed Packages with Retry Logic
# Handles network errors and skips unavailable packages

set +e  # Don't exit on errors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "  Failed Package Installation"
echo "========================================"
echo ""

# Function to install a package with retry
install_package() {
    local package=$1
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo -e "${BLUE}[Attempt $attempt/$max_attempts]${NC} Installing $package..."
        
        if sudo apt install -y "$package" 2>&1 | tee /tmp/apt-install.log; then
            echo -e "${GREEN}✓${NC} $package installed successfully"
            return 0
        else
            if grep -q "Unable to locate package" /tmp/apt-install.log; then
                echo -e "${YELLOW}⚠${NC} $package not found in repositories (skipping)"
                return 1
            elif grep -q "Temporary failure" /tmp/apt-install.log; then
                echo -e "${YELLOW}⚠${NC} Network error, retrying in 10 seconds..."
                sleep 10
                ((attempt++))
            else
                echo -e "${RED}✗${NC} $package failed to install"
                return 1
            fi
        fi
    done
    
    echo -e "${RED}✗${NC} $package failed after $max_attempts attempts (skipping)"
    return 1
}

# Fix DNS first
echo "Fixing DNS configuration..."
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf > /dev/null
echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf > /dev/null

# Test connectivity
echo ""
echo "Testing internet connectivity..."
if ping -c 2 8.8.8.8 > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Internet connection OK"
else
    echo -e "${RED}✗${NC} No internet connection detected!"
    echo "Please fix network connection and try again."
    exit 1
fi

# Update package lists with retry
echo ""
echo "Updating package lists..."
for i in {1..3}; do
    if sudo apt update; then
        echo -e "${GREEN}✓${NC} Package lists updated"
        break
    else
        echo -e "${YELLOW}⚠${NC} Update failed, retrying in 5 seconds..."
        sleep 5
    fi
done

echo ""
echo "========================================"
echo "Installing System Packages"
echo "========================================"
echo ""

# Track statistics
INSTALLED=0
FAILED=0
SKIPPED=0

# ==========================================
# Essential System Packages
# ==========================================
echo "=== Essential System Packages ==="

ESSENTIAL_PACKAGES=(
    "sudo"
    "vim"
    "curl"
    "wget"
    "git"
    "build-essential"
    "apt-transport-https"
    "ca-certificates"
    "gnupg"
    "lsb-release"
    "software-properties-common"
)

for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg"; then
        echo -e "${GREEN}✓${NC} $pkg already installed"
        ((INSTALLED++))
    else
        if install_package "$pkg"; then
            ((INSTALLED++))
        else
            ((FAILED++))
        fi
    fi
done

# ==========================================
# Network Utilities
# ==========================================
echo ""
echo "=== Network Utilities ==="

NETWORK_PACKAGES=(
    "net-tools"
    "dnsutils"
    "iputils-ping"
    "traceroute"
    "iproute2"
    "netcat-openbsd"
)

for pkg in "${NETWORK_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg"; then
        if install_package "$pkg"; then
            ((INSTALLED++))
        else
            ((FAILED++))
        fi
    fi
done

# ==========================================
# System Monitoring
# ==========================================
echo ""
echo "=== System Monitoring Tools ==="

MONITORING_PACKAGES=(
    "htop"
    "iotop"
    "sysstat"
    "lsof"
)

for pkg in "${MONITORING_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg"; then
        if install_package "$pkg"; then
            ((INSTALLED++))
        else
            ((FAILED++))
        fi
    fi
done

# ==========================================
# Kernel and Firmware
# ==========================================
echo ""
echo "=== Kernel Headers and Firmware ==="

KERNEL_VERSION=$(uname -r)
KERNEL_PACKAGES=(
    "linux-headers-$KERNEL_VERSION"
    "linux-headers-amd64"
    "firmware-linux-free"
    "firmware-linux-nonfree"
    "firmware-misc-nonfree"
)

for pkg in "${KERNEL_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg"; then
        if install_package "$pkg"; then
            ((INSTALLED++))
        else
            ((SKIPPED++))
        fi
    fi
done

# ==========================================
# Security Packages
# ==========================================
echo ""
echo "=== Security Packages ==="

SECURITY_PACKAGES=(
    "apparmor"
    "apparmor-utils"
    "apparmor-profiles"
    "apparmor-profiles-extra"
    "nftables"
    "fail2ban"
    "aide"
    "aide-common"
    "libpam-tmpdir"
    "libpam-pwquality"
)

for pkg in "${SECURITY_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg"; then
        if install_package "$pkg"; then
            ((INSTALLED++))
        else
            ((FAILED++))
        fi
    fi
done

# ==========================================
# Performance Packages
# ==========================================
echo ""
echo "=== Performance Optimization ==="

PERFORMANCE_PACKAGES=(
    "zram-tools"
    "preload"
    "irqbalance"
)

for pkg in "${PERFORMANCE_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg"; then
        if install_package "$pkg"; then
            ((INSTALLED++))
        else
            ((SKIPPED++))
        fi
    fi
done

# ==========================================
# Development Tools
# ==========================================
echo ""
echo "=== Development Tools ==="

DEV_PACKAGES=(
    "python3"
    "python3-pip"
    "python3-venv"
    "python3-dev"
    "python3-setuptools"
    "openjdk-17-jdk"
    "openjdk-17-jre"
    "gcc"
    "g++"
    "make"
    "cmake"
    "gdb"
    "valgrind"
    "strace"
)

for pkg in "${DEV_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg"; then
        if install_package "$pkg"; then
            ((INSTALLED++))
        else
            ((FAILED++))
        fi
    fi
done

# ==========================================
# Docker (separate handling due to repository)
# ==========================================
echo ""
echo "=== Docker Installation ==="

if ! command -v docker &> /dev/null; then
    echo "Installing Docker from official repository..."
    
    # Add Docker GPG key
    sudo mkdir -p /etc/apt/keyrings
    if curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Docker GPG key added"
    else
        echo -e "${RED}✗${NC} Failed to add Docker GPG key"
    fi
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update and install Docker
    sudo apt update
    
    DOCKER_PACKAGES=(
        "docker-ce"
        "docker-ce-cli"
        "containerd.io"
        "docker-buildx-plugin"
        "docker-compose-plugin"
    )
    
    for pkg in "${DOCKER_PACKAGES[@]}"; do
        if install_package "$pkg"; then
            ((INSTALLED++))
        else
            ((FAILED++))
        fi
    done
    
    # Add user to docker group
    if command -v docker &> /dev/null; then
        sudo usermod -aG docker $USER
        echo -e "${GREEN}✓${NC} User added to docker group (logout required)"
    fi
else
    echo -e "${GREEN}✓${NC} Docker already installed"
fi

# ==========================================
# Node.js (from NodeSource)
# ==========================================
echo ""
echo "=== Node.js Installation ==="

if ! command -v node &> /dev/null; then
    echo "Installing Node.js from NodeSource..."
    
    if curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 2>/dev/null; then
        if install_package "nodejs"; then
            ((INSTALLED++))
        else
            ((FAILED++))
        fi
    else
        echo -e "${RED}✗${NC} Failed to add NodeSource repository"
        ((FAILED++))
    fi
else
    echo -e "${GREEN}✓${NC} Node.js already installed"
fi

# ==========================================
# VS Code (from Microsoft)
# ==========================================
echo ""
echo "=== Visual Studio Code Installation ==="

if ! command -v code &> /dev/null; then
    echo "Installing VS Code from Microsoft repository..."
    
    # Add Microsoft GPG key
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    rm /tmp/packages.microsoft.gpg
    
    # Add VS Code repository
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    
    # Update and install
    sudo apt update
    
    if install_package "code"; then
        ((INSTALLED++))
    else
        ((FAILED++))
    fi
else
    echo -e "${GREEN}✓${NC} VS Code already installed"
fi

# ==========================================
# Fix broken dependencies
# ==========================================
echo ""
echo "Fixing any broken dependencies..."
sudo apt --fix-broken install -y
sudo apt autoremove -y

# ==========================================
# Summary
# ==========================================
echo ""
echo "========================================"
echo "           INSTALLATION SUMMARY"
echo "========================================"
echo -e "${GREEN}Installed:${NC} $INSTALLED packages"
echo -e "${YELLOW}Skipped:${NC}   $SKIPPED packages (not available)"
echo -e "${RED}Failed:${NC}    $FAILED packages"
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${YELLOW}Some packages failed to install.${NC}"
    echo "This is usually due to:"
    echo "  - Network issues (retry later)"
    echo "  - Package not available in Debian Bookworm"
    echo "  - Repository not configured"
    echo ""
fi

# ==========================================
# Verification
# ==========================================
echo "========================================"
echo "           VERIFICATION"
echo "========================================"
echo ""

verify() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed: $($1 --version 2>&1 | head -1)"
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
    fi
}

verify "docker"
verify "python3"
verify "node"
verify "npm"
verify "java"
verify "gcc"
verify "code"
