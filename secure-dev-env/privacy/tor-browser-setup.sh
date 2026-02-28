#!/bin/bash
# Tor Browser Installation Script

set -e

echo "Installing Tor Browser..."

# Variables
TOR_VERSION="13.5"
TOR_URL="https://www.torproject.org/dist/torbrowser/${TOR_VERSION}/tor-browser-linux-x86_64-${TOR_VERSION}.tar.xz"
INSTALL_DIR="/opt"
DESKTOP_FILE="/usr/share/applications/tor-browser.desktop"

# Download Tor Browser
cd /tmp
wget -O tor-browser.tar.xz "${TOR_URL}"

# Extract to /opt
sudo tar -xf tor-browser.tar.xz -C ${INSTALL_DIR}
sudo mv ${INSTALL_DIR}/tor-browser* ${INSTALL_DIR}/tor-browser

# Create desktop entry
sudo tee ${DESKTOP_FILE} > /dev/null << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Tor Browser
Comment=Anonymous web browsing
Exec=/opt/tor-browser/Browser/start-tor-browser
Icon=/opt/tor-browser/Browser/browser/chrome/icons/default/default128.png
Categories=Network;WebBrowser;Security;
Terminal=false
EOF

# Update desktop database
sudo update-desktop-database

# Cleanup
rm -f /tmp/tor-browser.tar.xz

echo "Tor Browser installed successfully!"
echo "Launch from Applications menu or run: /opt/tor-browser/Browser/start-tor-browser"