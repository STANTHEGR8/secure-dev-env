#!/bin/bash
# ----------------------------------------------------------------
# Secure Dev Env - Lynis Score Booster
# Targeted at Debian/Ubuntu systems based on Figure 3.3
# ----------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then 
   echo "This script must be run as root" 
   exit 1
fi

echo "--- Starting System Hardening ---"

# 1. Kernel Hardening (sysctl.conf)
# Addresses network stack security and memory protection
cat <<EOF > /etc/sysctl.d/99-hardened.conf
# Network Security
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1323 = 1

# Memory/Process Protection
kernel.randomize_va_space = 2
kernel.dmesg_restrict = 1
fs.suid_dumpable = 0
EOF
sysctl -p /etc/sysctl.d/99-hardened.conf

# 2. Legal Banners
# Lynis awards points for explicit unauthorized access warnings
echo "Authorized uses only. All activity may be monitored and reported." > /etc/issue
echo "Authorized uses only. All activity may be monitored and reported." > /etc/issue.net

# 3. File Permissions & Accounting
# Install auditd for system auditing (High point gain)
apt-get update && apt-get install -y auditd acct
systemctl enable --now auditd

# Restrict compilers (Common Lynis suggestion)
chmod 700 /usr/bin/as /usr/bin/gcc* /usr/bin/g++* 2>/dev/null || true

# 4. SSH Hardening
# Updates configuration to modern security standards
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config
systemctl restart ssh

# 5. Systemd Sandboxing (Fixing the "UNSAFE" status)
# Creating a drop-in for cloudflared as an example
mkdir -p /etc/systemd/system/cloudflared.service.d/
cat <<EOF > /etc/systemd/system/cloudflared.service.d/override.conf
[Service]
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
NoNewPrivileges=true
EOF
systemctl daemon-reload

echo "--- Hardening Complete. Re-run Lynis to see improved score. ---"
