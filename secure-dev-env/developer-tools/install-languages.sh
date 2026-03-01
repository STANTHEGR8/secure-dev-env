#!/bin/bash
# Programming Language Toolchains Installation

set -e

echo "Installing programming language toolchains..."

# Update package list
sudo apt update

# ===== NODE.JS =====
echo "Installing Node.js..."
sudo apt install nodejs npm

# ===== JAVA =====
echo "Installing Java (OpenJDK)..."
sudo apt install -y openjdk-21-jdk openjdk-21-jre

# ===== C/C++ =====
echo "Verifying C/C++ compiler..."
sudo apt install -y \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    gdb

# ===== RUST (optional) =====
echo "Installing Rust (optional)..."
read -p "Install Rust? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

echo ""
echo "Language toolchains installed!"
echo ""
echo "Versions:"
python3 --version
node --version
npm --version
java --version
gcc --version

g++ --version
