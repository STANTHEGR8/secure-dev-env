#!/bin/bash
# Tor Browser Installation Script - FIXED VERSION
# Automatically detects latest stable version

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "  Tor Browser Installation"
echo "========================================"
echo ""

# Check for required tools
if ! command -v wget &> /dev/null; then
    echo -e "${RED}Error: wget is not installed${NC}"
    echo "Install it with: sudo apt install wget"
    exit 1
fi

if ! command -v tar &> /dev/null; then
    echo -e "${RED}Error: tar is not installed${NC}"
    exit 1
fi

# Variables
INSTALL_DIR="/opt"
DESKTOP_FILE="/usr/share/applications/tor-browser.desktop"
TMP_DIR="/tmp/tor-browser-install"

# Create temporary directory
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

# Method 1: Try to detect latest version from Tor Project website
echo "Detecting latest Tor Browser version..."

# Get the latest version number from the download page
LATEST_VERSION=$(wget -qO- https://www.torproject.org/download/ | \
    grep -oP 'tor-browser-linux-x86_64-[0-9]+\.[0-9]+(\.[0-9]+)?\.tar\.xz' | \
    head -1 | \
    grep -oP '[0-9]+\.[0-9]+(\.[0-9]+)?' || echo "")

if [ -z "$LATEST_VERSION" ]; then
    echo -e "${YELLOW}Could not auto-detect version. Trying known stable versions...${NC}"
    
    # Try known recent versions
    KNOWN_VERSIONS=("13.5.7" "13.5.6" "13.5.5" "13.5.4" "13.5.3" "13.5.2" "13.5.1" "13.0.9" "13.0.8")
    
    for version in "${KNOWN_VERSIONS[@]}"; do
        echo "Trying version $version..."
        TOR_URL="https://www.torproject.org/dist/torbrowser/${version}/tor-browser-linux-x86_64-${version}.tar.xz"
        
        if wget --spider "$TOR_URL" 2>/dev/null; then
            LATEST_VERSION="$version"
            echo -e "${GREEN}Found available version: $LATEST_VERSION${NC}"
            break
        fi
    done
    
    if [ -z "$LATEST_VERSION" ]; then
        echo -e "${RED}Could not find any working Tor Browser version.${NC}"
        echo "Please download manually from: https://www.torproject.org/download/"
        exit 1
    fi
else
    echo -e "${GREEN}Latest version detected: $LATEST_VERSION${NC}"
fi

# Construct download URL
TOR_URL="https://www.torproject.org/dist/torbrowser/${LATEST_VERSION}/tor-browser-linux-x86_64-${LATEST_VERSION}.tar.xz"
TOR_FILENAME="tor-browser-linux-x86_64-${LATEST_VERSION}.tar.xz"

echo ""
echo "Download URL: $TOR_URL"
echo ""

# Download Tor Browser
echo "Downloading Tor Browser $LATEST_VERSION..."
if ! wget -O "$TOR_FILENAME" "$TOR_URL"; then
    echo -e "${RED}Download failed!${NC}"
    echo ""
    echo "Alternative: Download manually from https://www.torproject.org/download/"
    echo "Then extract to /opt/tor-browser"
    exit 1
fi

echo -e "${GREEN}Download complete!${NC}"

# Verify download (check file size)
FILE_SIZE=$(stat -c%s "$TOR_FILENAME")
if [ "$FILE_SIZE" -lt 10000000 ]; then  # Less than 10MB means error
    echo -e "${RED}Downloaded file is too small. Download may have failed.${NC}"
    exit 1
fi

# Remove old installation if exists
if [ -d "${INSTALL_DIR}/tor-browser" ]; then
    echo "Removing old Tor Browser installation..."
    sudo rm -rf "${INSTALL_DIR}/tor-browser"
fi

# Extract to /opt
echo "Extracting Tor Browser..."
sudo tar -xf "$TOR_FILENAME" -C "${INSTALL_DIR}"

# Find the extracted directory name
EXTRACTED_DIR=$(sudo find "${INSTALL_DIR}" -maxdepth 1 -type d -name "tor-browser*" | head -1)

if [ -z "$EXTRACTED_DIR" ]; then
    echo -e "${RED}Extraction failed or directory not found${NC}"
    exit 1
fi

# Rename to standard name
if [ "$EXTRACTED_DIR" != "${INSTALL_DIR}/tor-browser" ]; then
    sudo mv "$EXTRACTED_DIR" "${INSTALL_DIR}/tor-browser"
fi

# Set permissions
sudo chown -R root:root "${INSTALL_DIR}/tor-browser"
sudo chmod 755 "${INSTALL_DIR}/tor-browser"

# Make launcher script executable
if [ -f "${INSTALL_DIR}/tor-browser/Browser/start-tor-browser" ]; then
    sudo chmod +x "${INSTALL_DIR}/tor-browser/Browser/start-tor-browser"
elif [ -f "${INSTALL_DIR}/tor-browser/start-tor-browser.desktop" ]; then
    sudo chmod +x "${INSTALL_DIR}/tor-browser/start-tor-browser.desktop"
fi

# Create desktop entry
echo "Creating desktop menu entry..."
sudo tee "${DESKTOP_FILE}" > /dev/null << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Tor Browser
GenericName=Web Browser
Comment=Anonymous web browsing with Tor
Exec=sh -c '"/opt/tor-browser/Browser/start-tor-browser" --detach || "/opt/tor-browser/start-tor-browser.desktop" --detach || zenity --error --text="Tor Browser failed to start"' %u
Icon=/opt/tor-browser/Browser/browser/chrome/icons/default/default128.png
Categories=Network;WebBrowser;Security;
Keywords=Internet;WWW;Browser;Web;Tor;Anonymous;Privacy;
StartupWMClass=Tor Browser
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
Terminal=false
EOF

# Update desktop database
sudo update-desktop-database 2>/dev/null || true

# Create user-friendly launcher script
sudo tee /usr/local/bin/tor-browser > /dev/null << 'LAUNCHEREOF'
#!/bin/bash
# Tor Browser launcher script

TOR_DIR="/opt/tor-browser"

if [ -f "$TOR_DIR/Browser/start-tor-browser" ]; then
    cd "$TOR_DIR/Browser"
    ./start-tor-browser --detach "$@"
elif [ -f "$TOR_DIR/start-tor-browser.desktop" ]; then
    cd "$TOR_DIR"
    ./start-tor-browser.desktop --detach "$@"
else
    echo "Error: Tor Browser launcher not found"
    echo "Try reinstalling Tor Browser"
    exit 1
fi
LAUNCHEREOF

sudo chmod +x /usr/local/bin/tor-browser

# Cleanup
echo "Cleaning up..."
cd ~
rm -rf "$TMP_DIR"

# Verify installation
if [ -d "${INSTALL_DIR}/tor-browser" ]; then
    echo ""
    echo "========================================"
    echo -e "${GREEN}✓ Tor Browser installed successfully!${NC}"
    echo "========================================"
    echo ""
    echo "Version: $LATEST_VERSION"
    echo "Location: ${INSTALL_DIR}/tor-browser"
    echo ""
    echo "How to launch:"
    echo "  1. From Applications menu: Search for 'Tor Browser'"
    echo "  2. From terminal: tor-browser"
    echo "  3. Direct command: /opt/tor-browser/Browser/start-tor-browser"
    echo ""
    echo "First launch will take a few moments to connect to Tor network."
    echo ""
else
    echo -e "${RED}Installation verification failed${NC}"
    exit 1
fi
