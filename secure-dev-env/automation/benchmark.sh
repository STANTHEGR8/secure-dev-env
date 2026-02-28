#!/bin/bash
# Performance Testing and Benchmarking Script

set -e

RESULTS_DIR="/var/log/benchmarks"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$RESULTS_DIR"

echo "Running performance benchmarks..."
echo "Results will be saved to: $RESULTS_DIR"
echo ""

# Boot time
echo "=== Boot Time ==="
systemd-analyze time | tee "$RESULTS_DIR/boot-time-$TIMESTAMP.txt"

# Memory usage
echo ""
echo "=== Memory Usage ==="
free -h | tee "$RESULTS_DIR/memory-$TIMESTAMP.txt"

# ZRAM status
echo ""
echo "=== ZRAM Status ==="
zramctl | tee "$RESULTS_DIR/zram-$TIMESTAMP.txt"

# CPU info
echo ""
echo "=== CPU Performance ==="
if command -v sysbench &> /dev/null; then
    sysbench cpu --cpu-max-prime=20000 --threads=1 run | tee "$RESULTS_DIR/cpu-single-$TIMESTAMP.txt"
    sysbench cpu --cpu-max-prime=20000 --threads=2 run | tee "$RESULTS_DIR/cpu-multi-$TIMESTAMP.txt"
else
    echo "sysbench not installed. Install with: sudo apt install sysbench"
fi

# Disk I/O
echo ""
echo "=== Disk I/O ==="
if command -v fio &> /dev/null; then
    fio --name=seqread --rw=read --bs=128k --size=1G --numjobs=1 --runtime=30 --time_based \
        --output="$RESULTS_DIR/disk-seqread-$TIMESTAMP.txt"
else
    echo "fio not installed. Install with: sudo apt install fio"
fi

# Security audit
echo ""
echo "=== Security Audit ==="
if command -v lynis &> /dev/null; then
    sudo lynis audit system --quick 2>&1 | tee "$RESULTS_DIR/lynis-$TIMESTAMP.txt"
else
    echo "lynis not installed. Install with: sudo apt install lynis"
fi

echo ""
echo "Benchmarks complete!"
echo "Results saved to: $RESULTS_DIR"