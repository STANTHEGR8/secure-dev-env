#!/bin/bash
# XFCE Desktop Environment Aesthetic Customization Script
# Creates a professional, modern look for the secure development environment

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "  XFCE Aesthetic Customization"
echo "========================================"
echo ""

# Check if XFCE is installed
if ! command -v xfce4-session &> /dev/null; then
    echo -e "${YELLOW}XFCE not detected. Installing XFCE desktop environment...${NC}"
    sudo apt update
    sudo apt install -y xfce4 xfce4-goodies
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
# Install Required Packages
# ==========================================
info "Installing theme and customization packages..."

sudo apt install -y \
    arc-theme \
    papirus-icon-theme \
    fonts-ubuntu \
    fonts-ubuntu-console \
    fonts-font-awesome \
    numix-gtk-theme \
    breeze-cursor-theme \
    lightdm-gtk-greeter-settings \
    xfce4-screenshooter \
    xfce4-clipman-plugin \
    xfce4-whiskermenu-plugin \
    xfce4-weather-plugin \
    xfce4-pulseaudio-plugin \
    xfce4-power-manager \
    2>/dev/null || warn "Some packages may not be available"

log "Packages installed"

# ==========================================
# Apply GTK Theme
# ==========================================
info "Applying Arc-Dark GTK theme..."

xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus-Dark"
xfconf-query -c xfwm4 -p /general/theme -s "Arc-Dark"

log "GTK theme applied"

# ==========================================
# Configure Fonts
# ==========================================
info "Configuring fonts..."

xfconf-query -c xsettings -p /Gtk/FontName -s "Ubuntu 10"
xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "Ubuntu Mono 11"
xfconf-query -c xfwm4 -p /general/title_font -s "Ubuntu Bold 10"

# Font rendering
xfconf-query -c xsettings -p /Xft/Antialias -s 1
xfconf-query -c xsettings -p /Xft/HintStyle -s "hintfull"
xfconf-query -c xsettings -p /Xft/Rgba -s "rgb"
xfconf-query -c xsettings -p /Xft/DPI -s 96

log "Fonts configured"

# ==========================================
# Configure Window Manager
# ==========================================
info "Configuring window manager..."

# Disable compositor for better performance
xfconf-query -c xfwm4 -p /general/use_compositing -s false

# Window decorations
xfconf-query -c xfwm4 -p /general/button_layout -s "CHM|"
xfconf-query -c xfwm4 -p /general/titleless_maximize -s false
xfconf-query -c xfwm4 -p /general/title_alignment -s "center"

# Window behavior
xfconf-query -c xfwm4 -p /general/click_to_focus -s true
xfconf-query -c xfwm4 -p /general/focus_delay -s 0
xfconf-query -c xfwm4 -p /general/raise_on_focus -s false
xfconf-query -c xfwm4 -p /general/snap_to_border -s true
xfconf-query -c xfwm4 -p /general/snap_to_windows -s true

# Workspace settings
xfconf-query -c xfwm4 -p /general/workspace_count -s 4

log "Window manager configured"

# ==========================================
# Configure Desktop
# ==========================================
info "Configuring desktop..."

# Desktop background
WALLPAPER_PATH="$HOME/.local/share/wallpapers/secure-dev-env.png"
mkdir -p "$HOME/.local/share/wallpapers"

# Create a simple gradient wallpaper if none exists
if [ ! -f "$WALLPAPER_PATH" ]; then
    # Create a dark blue gradient using ImageMagick if available
    if command -v convert &> /dev/null; then
        convert -size 1920x1080 gradient:'#1a1a2e'-'#16213e' "$WALLPAPER_PATH"
    else
        # Download a placeholder if ImageMagick not available
        wget -q "https://raw.githubusercontent.com/NvChad/NvChad/main/lua/core/default_config.lua" \
            -O "$WALLPAPER_PATH" 2>/dev/null || touch "$WALLPAPER_PATH"
    fi
fi

# Apply wallpaper to all monitors
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$WALLPAPER_PATH"
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/image-style -s 5  # Scaled

# Desktop icons
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-home -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-trash -s false
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-removable -s false

log "Desktop configured"

# ==========================================
# Configure Panel
# ==========================================
info "Configuring XFCE panel..."

# Panel 1 - Top panel
xfconf-query -c xfce4-panel -p /panels/panel-1/position -s "p=6;x=0;y=0"
xfconf-query -c xfce4-panel -p /panels/panel-1/size -s 32
xfconf-query -c xfce4-panel -p /panels/panel-1/length -s 100
xfconf-query -c xfce4-panel -p /panels/panel-1/mode -s 0  # Horizontal
xfconf-query -c xfce4-panel -p /panels/panel-1/autohide -s false
xfconf-query -c xfce4-panel -p /panels/panel-1/background-alpha -s 90

# Panel appearance
xfconf-query -c xfce4-panel -p /panels/panel-1/background-style -s 1  # Solid color
xfconf-query -c xfce4-panel -p /panels/panel-1/background-color -t uint -t uint -t uint -t uint \
    -s 10794 -s 10794 -s 10794 -s 52428  # Dark gray

log "Panel configured"

# ==========================================
# Configure Terminal (XFCE Terminal)
# ==========================================
info "Configuring XFCE Terminal..."

mkdir -p "$HOME/.config/xfce4/terminal"

cat > "$HOME/.config/xfce4/terminal/terminalrc" << 'EOF'
[Configuration]
FontName=Ubuntu Mono 12
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscBellUrgent=FALSE
MiscBordersDefault=TRUE
MiscCursorBlinks=FALSE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscDefaultGeometry=100x30
MiscInheritGeometry=FALSE
MiscMenubarDefault=FALSE
MiscMouseAutohide=FALSE
MiscMouseWheelZoom=TRUE
MiscToolbarDefault=FALSE
MiscConfirmClose=TRUE
MiscCycleTabs=TRUE
MiscTabCloseButtons=TRUE
MiscTabCloseMiddleClick=TRUE
MiscTabPosition=GTK_POS_TOP
MiscHighlightUrls=TRUE
MiscMiddleClickOpensUri=FALSE
MiscCopyOnSelect=FALSE
MiscShowRelaunchDialog=TRUE
MiscRewrapOnResize=TRUE
MiscUseShiftArrowsToScroll=FALSE
MiscSlimTabs=FALSE
MiscNewTabAdjacent=FALSE
MiscSearchDialogOpacity=100
MiscShowUnsafePasteDialog=TRUE
ScrollingLines=10000
BackgroundDarkness=0.900000
ColorForeground=#ffffff
ColorBackground=#1a1a2e
ColorCursor=#ffffff
ColorPalette=#1a1a2e;#e74c3c;#2ecc71;#f39c12;#3498db;#9b59b6;#1abc9c;#ecf0f1;#95a5a6;#e74c3c;#2ecc71;#f39c12;#3498db;#9b59b6;#1abc9c;#ffffff
TabActivityColor=#3498db
EOF

log "Terminal configured"

# ==========================================
# Configure File Manager (Thunar)
# ==========================================
info "Configuring Thunar file manager..."

mkdir -p "$HOME/.config/Thunar"

cat > "$HOME/.config/Thunar/thunarrc" << 'EOF'
[Configuration]
LastView=ThunarIconView
LastIconView=ThunarIconView
LastDetailsViewColumnOrder=THUNAR_COLUMN_NAME,THUNAR_COLUMN_SIZE,THUNAR_COLUMN_TYPE,THUNAR_COLUMN_DATE_MODIFIED
LastDetailsViewColumnWidths=50,50,50,50
LastDetailsViewFixedColumns=FALSE
LastDetailsViewVisibleColumns=THUNAR_COLUMN_DATE_MODIFIED,THUNAR_COLUMN_NAME,THUNAR_COLUMN_SIZE,THUNAR_COLUMN_TYPE
LastLocationBar=ThunarLocationEntry
LastSeparatorPosition=170
LastShowHidden=FALSE
LastSidePane=ThunarShortcutsPane
LastSortColumn=THUNAR_COLUMN_NAME
LastSortOrder=GTK_SORT_ASCENDING
LastStatusbarVisible=TRUE
LastMenubarVisible=TRUE
LastWindowHeight=480
LastWindowWidth=640
LastWindowMaximized=FALSE
MiscVolumeManagement=TRUE
MiscCaseSensitive=FALSE
MiscDateStyle=THUNAR_DATE_STYLE_SIMPLE
MiscFoldersFirst=TRUE
MiscHorizontalWheelNavigates=FALSE
MiscRecursivePermissions=THUNAR_RECURSIVE_PERMISSIONS_ASK
MiscRememberGeometry=TRUE
MiscShowAboutTemplates=TRUE
MiscShowThumbnails=FALSE
MiscSingleClick=FALSE
MiscSingleClickTimeout=500
MiscTextBesideIcons=FALSE
ShortcutsIconEmblems=TRUE
ShortcutsIconSize=THUNAR_ICON_SIZE_SMALLER
TreeIconEmblems=TRUE
TreeIconSize=THUNAR_ICON_SIZE_SMALLER
EOF

log "Thunar configured"

# ==========================================
# Create Custom Wallpaper with Branding
# ==========================================
info "Creating custom branded wallpaper..."

if command -v convert &> /dev/null; then
    WALLPAPER="$HOME/.local/share/wallpapers/secure-dev-env-branded.png"
    
    # Create gradient background
    convert -size 1920x1080 gradient:'#0f2027'-'#203a43'-'#2c5364' "$WALLPAPER"
    
    # Add text overlay
    convert "$WALLPAPER" \
        -gravity center \
        -pointsize 72 \
        -fill white \
        -font Ubuntu-Bold \
        -annotate +0-100 "Secure Development Environment" \
        -pointsize 36 \
        -fill '#3498db' \
        -annotate +0-20 "Debian 12 | Hardened | Privacy-Enabled" \
        -pointsize 24 \
        -fill '#95a5a6' \
        -annotate +0+40 "AppArmor • nftables • WireGuard • Docker" \
        "$WALLPAPER"
    
    # Apply the branded wallpaper
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$WALLPAPER"
    
    log "Custom wallpaper created"
else
    warn "ImageMagick not installed. Install with: sudo apt install imagemagick"
fi

# ==========================================
# Configure Mouse and Touchpad
# ==========================================
info "Configuring mouse and touchpad..."

xfconf-query -c pointers -p /SynPS2_Synaptics_TouchPad/Properties/Synaptics_Tap_Action -t int -t int -t int -t int -t int -t int -t int -t int \
    -s 0 -s 0 -s 0 -s 0 -s 1 -s 3 -s 2 -s 0 2>/dev/null || true

# Mouse cursor theme
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "Breeze_Snow"

log "Mouse and touchpad configured"

# ==========================================
# Configure Keyboard Shortcuts
# ==========================================
info "Configuring keyboard shortcuts..."

# Terminal shortcut
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/<Super>t" -n -t string -s "xfce4-terminal"

# File manager shortcut
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/<Super>e" -n -t string -s "thunar"

# Application finder
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/<Super>space" -n -t string -s "xfce4-appfinder"

# Screenshot shortcuts
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/Print" -n -t string -s "xfce4-screenshooter -f"
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/<Shift>Print" -n -t string -s "xfce4-screenshooter -r"

log "Keyboard shortcuts configured"

# ==========================================
# Configure Power Management
# ==========================================
info "Configuring power management..."

# Display power management
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 10
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-sleep -s 15
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-off -s 20

# Show battery percentage
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/show-panel-label -s 1

log "Power management configured"

# ==========================================
# Configure Session and Startup
# ==========================================
info "Configuring session and startup..."

# Disable some autostart applications
mkdir -p "$HOME/.config/autostart"

# Disable update notifier (we use manual updates)
cat > "$HOME/.config/autostart/update-notifier.desktop" << 'EOF'
[Desktop Entry]
Hidden=true
EOF

# Disable Bluetooth manager (if not needed)
cat > "$HOME/.config/autostart/blueman.desktop" << 'EOF'
[Desktop Entry]
Hidden=true
EOF

log "Session and startup configured"

# ==========================================
# Install Additional Icon Themes
# ==========================================
info "Installing additional icon themes..."

# Numix icon theme
sudo apt install -y numix-icon-theme numix-icon-theme-circle 2>/dev/null || warn "Numix icons not available"

# Flat Remix icon theme (if available)
sudo apt install -y flat-remix-gtk flat-remix-gnome 2>/dev/null || true

log "Additional themes installed"

# ==========================================
# Create Desktop Shortcuts
# ==========================================
info "Creating desktop shortcuts..."

mkdir -p "$HOME/Desktop"

# Terminal shortcut
cat > "$HOME/Desktop/Terminal.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Comment=Terminal Emulator
Exec=xfce4-terminal
Icon=utilities-terminal
Path=
Terminal=false
StartupNotify=false
EOF

# Security Status shortcut (if script exists)
if [ -f "/usr/local/bin/security-status" ]; then
    cat > "$HOME/Desktop/Security-Status.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Security Status
Comment=Check system security configuration
Exec=xfce4-terminal -e "bash -c 'security-status; read -p \"Press Enter to close...\"'"
Icon=security-high
Path=
Terminal=false
StartupNotify=false
EOF
fi

# VS Code shortcut
if command -v code &> /dev/null; then
    cat > "$HOME/Desktop/VSCode.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Visual Studio Code
Comment=Code Editor
Exec=code
Icon=com.visualstudio.code
Path=
Terminal=false
StartupNotify=false
EOF
fi

# Make desktop files executable
chmod +x "$HOME/Desktop"/*.desktop

log "Desktop shortcuts created"

# ==========================================
# Configure Notification Daemon
# ==========================================
info "Configuring notifications..."

xfconf-query -c xfce4-notifyd -p /theme -s "Default"
xfconf-query -c xfce4-notifyd -p /initial-opacity -s 0.9
xfconf-query -c xfce4-notifyd -p /notify-location -s 2  # Top-right

log "Notifications configured"

# ==========================================
# Optimize Panel Plugins
# ==========================================
info "Configuring panel plugins..."

# Remove weather plugin if present (uses CPU)
xfconf-query -c xfce4-panel -p /plugins/plugin-8 --reset 2>/dev/null || true

# Ensure essential plugins are present
# Whiskermenu, window buttons, system tray, clock, power manager

log "Panel plugins optimized"

# ==========================================
# Create Custom Color Scheme
# ==========================================
info "Creating custom terminal color scheme..."

mkdir -p "$HOME/.local/share/xfce4/terminal/colorschemes"

cat > "$HOME/.local/share/xfce4/terminal/colorschemes/SecureDev.theme" << 'EOF'
[Scheme]
Name=Secure Dev
ColorForeground=#ffffff
ColorBackground=#1a1a2e
ColorCursor=#ffffff
ColorPalette=#1a1a2e;#e74c3c;#2ecc71;#f39c12;#3498db;#9b59b6;#1abc9c;#ecf0f1;#95a5a6;#e74c3c;#2ecc71;#f39c12;#3498db;#9b59b6;#1abc9c;#ffffff
EOF

log "Custom color scheme created"

# ==========================================
# Apply all changes
# ==========================================
info "Restarting XFCE components to apply changes..."

# Restart panel
xfce4-panel -r 2>/dev/null || true

# Restart window manager
xfwm4 --replace &

# Restart desktop
xfdesktop --reload 2>/dev/null || true

log "Changes applied"

# ==========================================
# Create Restoration Script
# ==========================================
info "Creating restoration script..."

cat > "$HOME/.local/bin/restore-xfce-defaults" << 'RESTOREOF'
#!/bin/bash
# Restore XFCE to default Debian settings

echo "Restoring XFCE defaults..."

# Remove custom configurations
rm -rf ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-*
rm -rf ~/.config/xfce4/terminal/terminalrc
rm -rf ~/.config/Thunar/thunarrc

# Restart XFCE components
xfce4-panel -r
xfwm4 --replace &
xfdesktop --reload

echo "XFCE restored to defaults. Log out and back in for full effect."
RESTOREOF

chmod +x "$HOME/.local/bin/restore-xfce-defaults"

log "Restoration script created at ~/.local/bin/restore-xfce-defaults"

# ==========================================
# Summary
# ==========================================
echo ""
echo "========================================"
echo "  CUSTOMIZATION COMPLETE"
echo "========================================"
echo ""
echo "Applied customizations:"
echo "  ✓ Arc-Dark GTK theme"
echo "  ✓ Papirus-Dark icon theme"
echo "  ✓ Ubuntu fonts"
echo "  ✓ Optimized window manager (compositor disabled)"
echo "  ✓ Custom terminal color scheme"
echo "  ✓ Thunar file manager optimization"
echo "  ✓ Custom keyboard shortcuts"
echo "  ✓ Desktop shortcuts"
echo "  ✓ Power management settings"
echo "  ✓ Branded wallpaper (if ImageMagick installed)"
echo ""
echo "Keyboard Shortcuts:"
echo "  Super + T       → Open Terminal"
echo "  Super + E       → Open File Manager"
echo "  Super + Space   → Application Finder"
echo "  Print           → Screenshot (full screen)"
echo "  Shift + Print   → Screenshot (region)"
echo ""
echo "To restore defaults: ~/.local/bin/restore-xfce-defaults"
echo ""
echo "IMPORTANT: Log out and back in for all changes to take effect!"
echo ""

# Prompt to log out
read -p "Log out now to apply all changes? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    xfce4-session-logout --logout
fi
