#!/bin/bash
#
# Uninstaller for Hyprland <-> Gamescope Session Switcher
#

set -e

# --- Colors ---
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_BLUE='\033[0;34m'
C_NC='\033[0m'

if [ "$EUID" -eq 0 ]; then
  echo -e "${C_RED}Error: Do not run this script as root! It will use 'sudo' as needed.${C_NC}"
  exit 1
fi

USER_NAME=$(whoami)
USER_HOME=$(eval echo "~$USER_NAME")

# --- Banner ---
echo -e "${C_BLUE}===================================================================${C_NC}"
echo -e "${C_BLUE} Hyprland <-> Gamescope Session Switcher Uninstaller${C_NC}"
echo -e "${C_BLUE}===================================================================${C_NC}\n"

# --- Confirmation ---
echo -e "${C_YELLOW}This will remove:${C_NC}"
echo "  - Session switching scripts only"
echo "  - SDDM autologin configuration"
echo "  - Systemd service overrides for gamescope"
echo "  - Wofi custom styling for the switcher"
echo "  - ONLY the SUPER+F12 switcher keybinding from Hyprland"
echo ""
echo -e "${C_YELLOW}This will NOT remove:${C_NC}"
echo "  - Hyprland (kept completely intact)"
echo "  - UWSM (kept completely intact)"
echo "  - Your Hyprland configuration files"
echo "  - Any installed packages"
echo "  - Steam, MangoHud, or other apps"
echo ""
echo -e "${C_RED}Continue with uninstallation? [y/N]:${C_NC} "
read -r CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${C_YELLOW}Uninstallation cancelled.${C_NC}"
    exit 0
fi

# --- Start Uninstallation ---
echo -e "\n${C_BLUE}==> Starting uninstallation...${C_NC}"

# 1. Remove session switching scripts
echo -e "${C_BLUE}==> Removing session switching scripts...${C_NC}"
rm -f "$USER_HOME/.local/bin/switch-session.sh"
rm -f "$USER_HOME/.xsession"
rm -f "$USER_HOME/.next-session"

# 2. Remove SDDM configuration
echo -e "${C_BLUE}==> Removing SDDM autologin configuration...${C_NC}"
if [ -f /etc/sddm.conf ]; then
    sudo rm -f /etc/sddm.conf
    echo "  - Removed SDDM configuration"
fi

# 3. Remove wayland session entry
echo -e "${C_BLUE}==> Removing session switcher entry...${C_NC}"
sudo rm -f /usr/share/wayland-sessions/switcher.desktop

# 4. Remove systemd service override
echo -e "${C_BLUE}==> Removing systemd service overrides...${C_NC}"
sudo rm -rf /etc/systemd/user/gamescope-session-plus@.service.d
sudo systemctl --user daemon-reload

# 5. Remove Wofi custom styling
echo -e "${C_BLUE}==> Removing Wofi custom styling...${C_NC}"
rm -f "$USER_HOME/.config/wofi/style.css"
# Remove wofi config directory if empty
rmdir "$USER_HOME/.config/wofi" 2>/dev/null || true

# 6. Remove Hyprland keybinding
echo -e "${C_BLUE}==> Removing Hyprland session switcher keybinding...${C_NC}"
HYPR_CONF="$USER_HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    # Remove session switcher keybinding and its comment
    sed -i '/# Session Switcher Keybinding/d' "$HYPR_CONF"
    sed -i '/bind = SUPER, F12, exec,.*switch-session.sh/d' "$HYPR_CONF"
    echo "  - Removed SUPER+F12 keybinding from Hyprland config"
fi

# --- Completion ---
echo -e "\n${C_GREEN}✅ Uninstallation Complete! ✅${C_NC}\n"

echo -e "${C_YELLOW}What was removed:${C_NC}"
echo "  ✓ Session switching scripts and binaries"
echo "  ✓ SDDM autologin configuration"
echo "  ✓ Custom wayland session entry"
echo "  ✓ Systemd service overrides"
echo "  ✓ Wofi custom styling"
echo "  ✓ Hyprland SUPER+F12 keybinding"

echo -e "\n${C_YELLOW}What remains:${C_NC}"
echo "  • Hyprland (completely untouched)"
echo "  • UWSM (completely untouched)"
echo "  • All your Hyprland configurations"
echo "  • All installed packages (gamescope, steam, wofi, etc.)"
echo "  • Any other customizations you've made"

echo -e "\n${C_BLUE}Note:${C_NC} You may need to restart your session or reboot for all changes to take effect."
echo ""
echo -e "${C_RED}IMPORTANT:${C_NC} This uninstaller does NOT remove:"
echo "  • Hyprland or UWSM (these are kept intact)"
echo "  • Your Hyprland configurations (only the switcher keybinding was removed)"
echo "  • Any core system components"
echo ""
echo -e "${C_BLUE}If you want to remove only the gamescope/gaming components, you can run:${C_NC}"
echo "  yay -R gamescope gamescope-session-git"
echo ""
