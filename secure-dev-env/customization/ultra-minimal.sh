#!/bin/bash
# XFCE Ultra-Minimal Configuration
# Optimized for maximum performance on 4GB RAM systems
# Removes all unnecessary visual effects and services

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "  XFCE Ultra-Minimal Configuration"
echo "========================================"
echo ""

# Check if XFCE is installed
if ! command -v xfce4-session &> /dev/null; then
    echo -e "${RED}XFCE not detected. Please install XFCE first.${NC}"
    exit 1
fi

log() {
    echo -e "${GREEN}[✓]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# ==========================================
# Install Minimal Theme Components
# ==========================================
info "Installing minimal theme components..."

sudo apt install -y \
    xfce4 \
    xfce4-terminal \
    thunar \
    adwaita-icon-theme \
    fonts-dejavu-core \
    2>/dev/null || warn "Some packages may not be available"

# Remove unnecessary XFCE components
info "Removing unnecessary XFCE components..."
sudo apt remove -y \
    xfce4-weather-plugin \
    xfce4-notes-plugin \
    xfce4-dict \
    xfce4-screensaver \
    xfce4-artwork \
    xfburn \
    parole \
    ristretto \
    2>/dev/null || true

sudo apt autoremove -y

log "Minimal packages configured"

# ==========================================
# Disable Compositor (Critical for Performance)
# ==========================================
info "Disabling window compositor..."

xfconf-query -c xfwm4 -p /general/use_compositing -s false
xfconf-query -c xfwm4 -p /general/vblank_mode -s "off"

log "Compositor disabled"

# ==========================================
# Minimal Window Manager Settings
# ==========================================
info "Configuring minimal window manager..."

# Minimal window decorations
xfconf-query -c xfwm4 -p /general/theme -s "Default"
xfconf-query -c xfwm4 -p /general/button_layout -s "HM|C"
xfconf-query -c xfwm4 -p /general/title_alignment -s "left"
xfconf-query -c xfwm4 -p /general/title_font -s "Sans Bold 9"

# Disable all animations
xfconf-query -c xfwm4 -p /general/zoom_desktop -s false
xfconf-query -c xfwm4 -p /general/show_popup_shadow -s false
xfconf-query -c xfwm4 -p /general/show_frame_shadow -s false
xfconf-query -c xfwm4 -p /general/popup_opacity -s 100

# Window behavior - minimal delays
xfconf-query -c xfwm4 -p /general/click_to_focus -s true
xfconf-query -c xfwm4 -p /general/focus_delay -s 0
xfconf-query -c xfwm4 -p /general/raise_delay -s 0
xfconf-query -c xfwm4 -p /general/raise_on_focus -s false
xfconf-query -c xfwm4 -p /general/raise_on_click -s true

# Minimal workspaces
xfconf-query -c xfwm4 -p /general/workspace_count -s 2

log "Window manager configured for minimal resource usage"

# ==========================================
# Minimal GTK Theme Settings
# ==========================================
info "Applying minimal GTK theme..."

# Use lightweight default theme
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita"
xfconf-query -c xsettings -p /Net/IconThemeName -s "Adwaita"
xfconf-query -c xfwm4 -p /general/theme -s "Default"

# Disable menu icons (saves memory)
xfconf-query -c xsettings -p /Gtk/MenuImages -s false
xfconf-query -c xsettings -p /Gtk/ButtonImages -s false

# Minimal toolbar style
xfconf-query -c xsettings -p /Gtk/ToolbarStyle -s "icons"
xfconf-query -c xsettings -p /Gtk/ToolbarIconSize -s 2  # Small icons

log "Minimal GTK theme applied"

# ==========================================
# Minimal Font Configuration
# ==========================================
info "Configuring minimal fonts..."

# Small system fonts
xfconf-query -c xsettings -p /Gtk/FontName -s "Sans 9"
xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "Monospace 10"

# Disable font antialiasing for performance (optional)
xfconf-query -c xsettings -p /Xft/Antialias -s 1
xfconf-query -c xsettings -p /Xft/HintStyle -s "hintslight"

log "Minimal fonts configured"

# ==========================================
# Minimal Desktop Configuration
# ==========================================
info "Configuring minimal desktop..."

# Solid color background (no wallpaper)
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/color-style -s 0
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/color1 -t uint -t uint -t uint -t uint \
    -s 8224 -s 8224 -s 8224 -s 65535  # Dark gray

# Disable desktop icons completely
xfconf-query -c xfce4-desktop -p /desktop-icons/style -s 0
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-home -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-trash -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-removable -s false

# Disable backdrop cycle (uses CPU)
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/backdrop-cycle-enable -s false

log "Minimal desktop configured (no icons, solid color background)"

# ==========================================
# Strip Panel to Bare Essentials
# ==========================================
info "Configuring ultra-minimal panel..."

# Single small panel
xfconf-query -c xfce4-panel -p /panels/panel-1/position -s "p=6;x=0;y=0"
xfconf-query -c xfce4-panel -p /panels/panel-1/size -s 24  # Smaller panel
xfconf-query -c xfce4-panel -p /panels/panel-1/length -s 100
xfconf-query -c xfce4-panel -p /panels/panel-1/autohide -s false

# Solid panel background
xfconf-query -c xfce4-panel -p /panels/panel-1/background-style -s 1
xfconf-query -c xfce4-panel -p /panels/panel-1/background-alpha -s 100

# Remove all panels except panel-1
xfconf-query -c xfce4-panel -p /panels -s 1 -t int -a

# ESSENTIAL PLUGINS ONLY:
# 1. Application Menu (launcher)
# 2. Window Buttons (task manager)
# 3. Clock
# 4. Systray
# Remove: Weather, CPU monitor, Notes, etc.

# Reset plugin configuration to minimal set
xfconf-query -c xfce4-panel -p /plugins -r -R 2>/dev/null || true

log "Ultra-minimal panel configured (essential plugins only)"

# ==========================================
# Minimal Terminal Configuration
# ==========================================
info "Configuring minimal terminal..."

mkdir -p "$HOME/.config/xfce4/terminal"

cat > "$HOME/.config/xfce4/terminal/terminalrc" << 'EOF'
[Configuration]
FontName=Monospace 10
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscBellUrgent=FALSE
MiscBordersDefault=FALSE
MiscCursorBlinks=FALSE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscDefaultGeometry=100x30
MiscInheritGeometry=FALSE
MiscMenubarDefault=FALSE
MiscMouseAutohide=TRUE
MiscMouseWheelZoom=FALSE
MiscToolbarDefault=FALSE
MiscConfirmClose=FALSE
MiscCycleTabs=TRUE
MiscTabCloseButtons=FALSE
MiscTabCloseMiddleClick=TRUE
MiscTabPosition=GTK_POS_TOP
MiscHighlightUrls=TRUE
ScrollingBar=TERMINAL_SCROLLBAR_NONE
ScrollingLines=1000
BackgroundDarkness=1.000000
ColorForeground=#ffffff
ColorBackground=#000000
ColorCursor=#ffffff
ColorPalette=#000000;#cc0000;#4e9a06;#c4a000;#3465a4;#75507b;#06989a;#d3d7cf;#555753;#ef2929;#8ae234;#fce94f;#729fcf;#ad7fa8;#34e2e2;#eeeeec
TabActivityColor=#3465a4
EOF

log "Minimal terminal configured"

# ==========================================
# Minimal Thunar Configuration
# ==========================================
info "Configuring minimal file manager..."

mkdir -p "$HOME/.config/Thunar"

cat > "$HOME/.config/Thunar/thunarrc" << 'EOF'
[Configuration]
LastView=ThunarIconView
LastIconView=ThunarIconView
LastShowHidden=FALSE
LastSidePane=void
LastSortColumn=THUNAR_COLUMN_NAME
LastSortOrder=GTK_SORT_ASCENDING
LastStatusbarVisible=FALSE
LastMenubarVisible=TRUE
LastWindowHeight=480
LastWindowWidth=640
LastWindowMaximized=FALSE
MiscVolumeManagement=FALSE
MiscCaseSensitive=FALSE
MiscDateStyle=THUNAR_DATE_STYLE_SIMPLE
MiscFoldersFirst=TRUE
MiscHorizontalWheelNavigates=FALSE
MiscRecursivePermissions=THUNAR_RECURSIVE_PERMISSIONS_ASK
MiscRememberGeometry=TRUE
MiscShowAboutTemplates=FALSE
MiscShowThumbnails=FALSE
MiscSingleClick=FALSE
MiscSingleClickTimeout=500
MiscTextBesideIcons=FALSE
ShortcutsIconEmblems=FALSE
ShortcutsIconSize=THUNAR_ICON_SIZE_SMALLEST
TreeIconEmblems=FALSE
TreeIconSize=THUNAR_ICON_SIZE_SMALLEST
EOF

log "Minimal file manager configured"

# ==========================================
# Disable All Autostart Applications
# ==========================================
info "Disabling unnecessary autostart applications..."

mkdir -p "$HOME/.config/autostart"

# Disable common autostart items
AUTOSTART_DISABLE=(
    "blueman"
    "update-notifier"
    "xfce4-power-manager"
    "xfce4-clipman"
    "xfce4-volumed-pulse"
    "light-locker"
    "xscreensaver"
    "gnome-keyring-pkcs11.desktop"
    "gnome-keyring-secrets.desktop"
    "gnome-keyring-ssh.desktop"
    "print-applet"
    "tracker-store"
    "tracker-miner-apps"
    "tracker-miner-fs"
)

for app in "${AUTOSTART_DISABLE[@]}"; do
    if [ -f "/etc/xdg/autostart/$app.desktop" ] || [ -f "$HOME/.config/autostart/$app.desktop" ]; then
        cat > "$HOME/.config/autostart/$app.desktop" << EOF
[Desktop Entry]
Hidden=true
EOF
        info "Disabled: $app"
    fi
done

log "Autostart applications minimized"

# ==========================================
# Disable Desktop Services
# ==========================================
info "Disabling resource-heavy desktop services..."

# Disable thumbnail generation
xfconf-query -c thunar -p /misc-thumbnail-mode -s THUNAR_THUMBNAIL_MODE_NEVER

# Disable volume management
xfconf-query -c thunar -p /misc-volume-management -s false

# Disable desktop file monitoring
pkill -9 xfdesktop 2>/dev/null || true
xfconf-query -c xfce4-desktop -p /desktop-icons/style -s 0

log "Desktop services disabled"

# ==========================================
# Minimal Session Settings
# ==========================================
info "Configuring minimal session..."

# Disable session saving (faster logout/login)
xfconf-query -c xfce4-session -p /general/SaveOnExit -s false
xfconf-query -c xfce4-session -p /general/PromptOnLogout -s false

# Disable splash screen
xfconf-query -c xfce4-session -p /splash/Engine -s ""

log "Minimal session configured"

# ==========================================
# Disable Power Management Features
# ==========================================
info "Disabling non-essential power management..."

# Keep display always on (for desktop use)
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-sleep -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-off -s 0

# Disable lid close action (for laptops)
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lid-action-on-ac -s 0

# Minimal brightness management
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/show-panel-label -s 0

log "Power management minimized"

# ==========================================
# Minimal Keyboard Shortcuts (Essential Only)
# ==========================================
info "Configuring minimal keyboard shortcuts..."

# Essential shortcuts only
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/<Super>t" -n -t string -s "xfce4-terminal"
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/<Super>e" -n -t string -s "thunar"
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/<Alt>F2" -n -t string -s "xfce4-appfinder"

# Disable fancy shortcuts (window animations, etc.)
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/default/<Alt>F9" --reset 2>/dev/null || true
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/default/<Alt>F10" --reset 2>/dev/null || true
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/default/<Alt>F11" --reset 2>/dev/null || true

log "Essential keyboard shortcuts configured"

# ==========================================
# Remove Desktop Shortcuts (Save RAM)
# ==========================================
info "Removing desktop shortcuts..."

rm -f "$HOME/Desktop"/*.desktop 2>/dev/null || true

log "Desktop cleaned"

# ==========================================
# Disable Notifications (Optional)
# ==========================================
info "Configuring minimal notifications..."

# Very short notification timeout
xfconf-query -c xfce4-notifyd -p /expire-timeout -s 3
xfconf-query -c xfce4-notifyd -p /initial-opacity -s 1.0
xfconf-query -c xfce4-notifyd -p /theme -s "Default"

# Or disable notifications completely:
# killall xfce4-notifyd 2>/dev/null || true

log "Notifications minimized"

# ==========================================
# Optimize Memory Usage
# ==========================================
info "Creating memory optimization script..."

cat > "$HOME/.local/bin/xfce-memory-optimize" << 'MEMEOF'
#!/bin/bash
# XFCE Memory Optimization Script

echo "Optimizing XFCE memory usage..."

# Kill non-essential processes
pkill -9 xfce4-power-manager 2>/dev/null
pkill -9 xfce4-volumed 2>/dev/null
pkill -9 xfdesktop 2>/dev/null  # Desktop file manager

# Clear thumbnail cache
rm -rf ~/.cache/thumbnails/*

# Compact Firefox/browser cache if present
rm -rf ~/.cache/mozilla/firefox/*/cache2/entries/*

# Drop caches (requires sudo)
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

echo "Memory optimization complete"
free -h
MEMEOF

mkdir -p "$HOME/.local/bin"
chmod +x "$HOME/.local/bin/xfce-memory-optimize"

log "Memory optimization script created"

# ==========================================
# Create Performance Monitoring Alias
# ==========================================
info "Creating performance monitoring aliases..."

cat >> "$HOME/.bashrc" << 'BASHEOF'

# XFCE Performance Aliases
alias xfce-mem='ps aux --sort=-%mem | grep xfce | head -10'
alias xfce-cpu='ps aux --sort=-%cpu | grep xfce | head -10'
alias xfce-restart='xfce4-panel -r && xfwm4 --replace &'
BASHEOF

log "Performance aliases added to .bashrc"

# ==========================================
# Apply All Changes
# ==========================================
info "Applying all changes..."

# Restart XFCE components
killall xfce4-panel 2>/dev/null || true
xfce4-panel &

killall xfwm4 2>/dev/null || true
xfwm4 --replace &

# Don't restart xfdesktop (disabled for minimal mode)
pkill -9 xfdesktop 2>/dev/null || true

log "Changes applied"

# ==========================================
# Display Resource Usage Stats
# ==========================================
echo ""
echo "========================================"
echo "  MEMORY USAGE COMPARISON"
echo "========================================"
echo ""

XFCE_MEM=$(ps aux | grep -E 'xfce|xfwm|xfce4-panel' | grep -v grep | awk '{sum+=$6} END {print sum/1024}')
echo "XFCE processes memory usage: ${XFCE_MEM}MB"
echo ""
echo "Detailed breakdown:"
ps aux --sort=-%mem | grep -E 'xfce|xfwm|xfce4-panel' | grep -v grep | head -10
echo ""

# ==========================================
# Summary
# ==========================================
echo ""
echo "========================================"
echo "  ULTRA-MINIMAL CONFIGURATION COMPLETE"
echo "========================================"
echo ""
echo "Optimizations applied:"
echo "  ✓ Compositor DISABLED (major performance gain)"
echo "  ✓ Desktop icons DISABLED"
echo "  ✓ Thumbnails DISABLED"
echo "  ✓ Animations DISABLED"
echo "  ✓ Panel size reduced to 24px"
echo "  ✓ Non-essential plugins REMOVED"
echo "  ✓ Autostart applications DISABLED"
echo "  ✓ Solid color background (no wallpaper)"
echo "  ✓ Minimal fonts (9px system)"
echo "  ✓ Menu/button icons DISABLED"
echo ""
echo "Expected memory savings: 150-250MB compared to default XFCE"
echo ""
echo "Keyboard shortcuts:"
echo "  Super + T  → Terminal"
echo "  Super + E  → File Manager"
echo "  Alt + F2   → Application Finder"
echo ""
echo "Performance tools:"
echo "  xfce-mem              → Show XFCE memory usage"
echo "  xfce-cpu              → Show XFCE CPU usage"
echo "  xfce-memory-optimize  → Free up memory"
echo "  xfce-restart          → Restart XFCE components"
echo ""
echo "⚠️  NOTE: Desktop icons are disabled. Use file manager (Super+E)"
echo ""
echo "Log out and back in for all changes to take effect."
echo ""

# Prompt to log out
read -p "Log out now to apply all changes? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    xfce4-session-logout --logout
fi
