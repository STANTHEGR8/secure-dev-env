#!/bin/bash
# ZRAM Configuration Script

set -e

echo "Configuring ZRAM compressed swap..."

# Install zram-tools
sudo apt install -y zram-tools

# Configure ZRAM
sudo tee /etc/default/zramswap > /dev/null << 'EOF'
# ZRAM Configuration
# Allocation: 75% of physical RAM (3GB on 4GB system)
ALLOCATION=75

# Compression algorithm: zstd (best ratio)
ALGO=zstd

# Number of ZRAM devices (usually 1)
ZRAM_DEVICES=1
EOF

# Enable and start ZRAM
sudo systemctl enable zramswap
sudo systemctl restart zramswap

# Set ZRAM swap priority higher than disk swap
sleep 2
ZRAM_DEV=$(swapon --show=NAME --noheadings | grep zram)
if [ -n "$ZRAM_DEV" ]; then
    sudo swapoff "$ZRAM_DEV"
    sudo swapon -p 100 "$ZRAM_DEV"
    echo "ZRAM swap priority set to 100"
fi

# Set disk swap to lower priority if exists
DISK_SWAP=$(swapon --show=NAME --noheadings | grep -v zram | head -1)
if [ -n "$DISK_SWAP" ]; then
    sudo swapoff "$DISK_SWAP"
    sudo swapon -p 10 "$DISK_SWAP"
    echo "Disk swap priority set to 10"
fi

# Verify ZRAM status
echo ""
echo "ZRAM Status:"
zramctl
echo ""
echo "Swap devices:"
swapon --show

echo "ZRAM configuration complete!"