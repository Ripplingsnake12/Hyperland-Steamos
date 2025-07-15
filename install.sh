#!/bin/bash
#
# Seamless Hyprland <-> Gamescope Session Switcher for Arch Linux (UWSM-enabled)
#

set -e

# --- Pre-flight Checks and Setup ---
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_BLUE='\033[0;34m'
C_NC='\033[0m' # No Color

if [ "$EUID" -eq 0 ]; then
  echo -e "${C_RED}Error: Do not run this script as root! It will use 'sudo' as needed.${C_NC}"
  exit 1
fi

USER_NAME=$(whoami)
USER_HOME=$(eval echo "~$USER_NAME")

# --- Banner ---
echo -e "${C_BLUE}===================================================================${C_NC}"
echo -e "${C_BLUE} Hyprland <-> Gamescope Session Switcher Setup for: ${C_YELLOW}$USER_NAME${C_NC}"
echo -e "${C_BLUE}===================================================================${C_NC}\n"

# --- USER CHOICE FOR AUTOLOGIN ---
echo -e "${C_YELLOW}Configuration Choice:${C_NC}"
echo "Do you want to enable automatic login? [y/N]: "
read AUTOLOGIN_CHOICE

# --- Script Variables ---
HYPR_CONF="$USER_HOME/.config/hypr/hyprland.conf"
SWITCH_SCRIPT_PATH="$USER_HOME/.local/bin/switch-session.sh"
XSESSION_PATH="$USER_HOME/.xsession"
SERVICE_OVERRIDE_DIR="/etc/systemd/user/gamescope-session-plus@.service.d"
SERVICE_OVERRIDE_FILE="$SERVICE_OVERRIDE_DIR/override.conf"

OFFICIAL_PACKAGES=( "hyprland" "wofi" "sddm" "uwsm" )
AUR_PACKAGES=( "gamescope-git" "gamescope-session-git" "steam" "gamescope-session-steam-git" "mangohud" )

#=======================================================
# STEP 1: DEPENDENCY INSTALLATION
#=======================================================
echo -e "${C_BLUE}==> Installing Dependencies...${C_NC}"
if command -v yay &> /dev/null; then AUR_HELPER="yay"; elif command -v paru &> /dev/null; then AUR_HELPER="paru"; else
    echo -e "${C_RED}Error: No AUR helper found (yay or paru). Please install one.${C_NC}"; exit 1; fi
echo -e "${C_GREEN}Found AUR helper: ${AUR_HELPER}${C_NC}"
sudo pacman -Syudd --needed "${OFFICIAL_PACKAGES[@]}" --noconfirm
$AUR_HELPER -Sdd --needed "${AUR_PACKAGES[@]}" --noconfirm

#=======================================================
# STEP 2: CLEAN UP OLD CONFIGURATIONS
#=======================================================
echo -e "${C_BLUE}==> Cleaning Up Old Configurations...${C_NC}"
sudo rm -rf "$SERVICE_OVERRIDE_DIR"
rm -f "$XSESSION_PATH"
rm -f "$SWITCH_SCRIPT_PATH"

#=======================================================
# STEP 3: APPLY SYSTEMD FIXES
#=======================================================
echo -e "${C_BLUE}==> Applying Core Fix for Wayland Socket Errors...${C_NC}"
sudo mkdir -p "$SERVICE_OVERRIDE_DIR"
sudo tee "$SERVICE_OVERRIDE_FILE" > /dev/null <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/env -u WAYLAND_DISPLAY /usr/share/gamescope-session-plus/gamescope-session-plus %i
EOF
systemctl --user daemon-reload

#=======================================================
# STEP 4: INSTALL SESSION SWITCHING LOGIC
#=======================================================
echo -e "${C_BLUE}==> Installing Session Switching Workflow...${C_NC}"

# --- SDDM AUTOLOGIN (CONDITIONAL) ---
if [[ "$AUTOLOGIN_CHOICE" =~ ^[Yy]$ ]]; then
    echo "--> Configuring SDDM for autologin..."
    sudo tee /etc/sddm.conf > /dev/null <<EOF
[Autologin]
User=${USER_NAME}
Session=switcher.desktop
Relogin=true
EOF
    AUTOLOGIN_ENABLED=true
else
    AUTOLOGIN_ENABLED=false
fi

# --- WAYLAND SESSION DESKTOP ENTRY ---
sudo tee /usr/share/wayland-sessions/switcher.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Auto Session Switcher
Exec=${XSESSION_PATH}
Type=Application
EOF

#=======================================================
# STEP 5: CREATE XSESSION LAUNCH SCRIPT WITH UWSM
#=======================================================
echo -e "${C_BLUE}==> Creating Session Launch Script (with UWSM)...${C_NC}"

cat > "$XSESSION_PATH" <<'EOS'
#!/bin/bash
SESSION=$(cat "$HOME/.next-session" 2>/dev/null)
rm -f "$HOME/.next-session"

# Ensure environment is updated
dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY

# Enhanced Wayland socket waiting with better error handling
wait_for_wayland() {
    local socket_path="$XDG_RUNTIME_DIR/wayland-1"
    local max_attempts=60
    local attempt=1
    
    echo "Waiting for Wayland socket at $socket_path"
    
    while [ $attempt -le $max_attempts ]; do
        if [ -e "$socket_path" ] && [ -S "$socket_path" ]; then
            echo "Wayland socket ready after $attempt attempts"
            return 0
        fi
        
        # Log progress every 10 attempts
        if [ $((attempt % 10)) -eq 0 ]; then
            echo "Still waiting for Wayland socket... ($attempt/$max_attempts)"
        fi
        
        sleep 0.5
        ((attempt++))
    done
    
    echo "Warning: Wayland socket not found after $max_attempts attempts"
    return 1
}

if [[ "$SESSION" == *"gamescope-session-steam"* ]]; then
    echo "Starting Gamescope session..."
    # Ensure gamescope dependencies are available
    if ! command -v gamescope-session-plus &> /dev/null; then
        echo "Error: gamescope-session-plus not found"
        exit 1
    fi
    exec gamescope-session-plus steam
else
    echo "Starting Hyprland session with UWSM..."
    # Ensure uwsm is available
    if ! command -v uwsm &> /dev/null; then
        echo "Error: uwsm not found"
        exit 1
    fi
    
    # Wait for Wayland socket if needed
    wait_for_wayland
    
    exec uwsm start hyprland-uwsm.desktop
fi
EOS
chmod +x "$XSESSION_PATH"

#=======================================================
# STEP 6: CREATE SWITCHING SCRIPT
#=======================================================
echo -e "${C_BLUE}==> Creating Session Switching Helper...${C_NC}"

mkdir -p "$(dirname "$SWITCH_SCRIPT_PATH")"
cat > "$SWITCH_SCRIPT_PATH" <<'EOSWITCH'
#!/bin/bash

# Set environment variables for Wofi to work properly
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# Create Wofi config directory if it doesn't exist
mkdir -p "$HOME/.config/wofi"

# Create custom Wofi stylesheet for SteamOS appearance with glass effect
cat > "$HOME/.config/wofi/style.css" <<'EOSTYLE'
window {
    background-color: rgba(30, 30, 46, 0.85);
    border: 1px solid rgba(60, 125, 210, 0.5);
    border-radius: 16px;
    font-family: "Noto Sans", sans-serif;
    font-size: 18px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4),
                inset 0 1px 0 rgba(255, 255, 255, 0.1);
    min-height: 250px;
}

#input {
    background-color: rgba(42, 42, 62, 0.6);
    border: 1px solid rgba(60, 125, 210, 0.3);
    border-radius: 8px;
    color: #cdd6f4;
    font-size: 16px;
    margin: 12px;
    padding: 12px 16px;
    box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.2);
}

#inner-box {
    background-color: transparent;
    margin: 8px;
    min-height: 150px;
}

#outer-box {
    background-color: rgba(255, 255, 255, 0.02);
    border-radius: 12px;
    margin: 4px;
    padding: 8px;
}

#scroll {
    background-color: transparent;
    min-height: 120px;
}

#text {
    color: rgba(205, 214, 244, 0.95);
    padding: 12px 16px;
    font-weight: 500;
    font-size: 18px;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
}

#entry {
    background-color: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 10px;
    margin: 8px 12px;
    padding: 12px;
    min-height: 48px;
    transition: all 0.2s ease;
    backdrop-filter: blur(10px);
}

#entry:hover {
    background-color: rgba(255, 255, 255, 0.08);
    border-color: rgba(60, 125, 210, 0.4);
    transform: translateX(4px);
}

#entry:selected {
    background: linear-gradient(135deg, rgba(60, 125, 210, 0.8) 0%, rgba(37, 99, 235, 0.8) 100%);
    border: 1px solid rgba(60, 125, 210, 0.6);
    box-shadow: 0 4px 16px rgba(60, 125, 210, 0.4),
                inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

#entry:selected #text {
    color: #ffffff;
    font-weight: 600;
    text-shadow: 0 1px 3px rgba(0, 0, 0, 0.4);
}
EOSTYLE

# Show session switcher with Wofi
choice=$(printf "🎮 SteamOS\n🖥️ Desktop" | wofi --dmenu \
    --prompt "Switch Mode:" \
    --width 400 \
    --height 250 \
    --cache-file /dev/null \
    --style "$HOME/.config/wofi/style.css" \
    --hide-scroll \
    --no-actions \
    --lines 2)

case "$choice" in
    "🖥️ Desktop")
        # Validate we can write the session file
        if echo "hyprland-uwsm.desktop" > "$HOME/.next-session" 2>/dev/null; then
            notify-send "Session Switcher" "Switching to Desktop..." -t 2000
            echo "Session file written successfully"
        else
            notify-send "Session Switcher" "Error: Failed to write session file" -t 3000
            echo "Error: Cannot write to $HOME/.next-session"
            exit 1
        fi
        ;;
    "🎮 SteamOS")
        # Validate we can write the session file
        if echo "gamescope-session-steam.desktop" > "$HOME/.next-session" 2>/dev/null; then
            notify-send "Session Switcher" "Switching to SteamOS..." -t 2000
            echo "Session file written successfully"
        else
            notify-send "Session Switcher" "Error: Failed to write session file" -t 3000
            echo "Error: Cannot write to $HOME/.next-session"
            exit 1
        fi
        ;;
    *)
        echo "No valid choice made"
        exit 1
        ;;
esac


# Improved session cleanup with better reliability
cleanup_session() {
    local max_wait=10
    local wait_count=0
    
    # Detect current session more reliably
    if pgrep -x "gamescope" > /dev/null || pgrep -f "gamescope-session" > /dev/null; then
        echo "Detected Gamescope session, shutting down..."
        
        # Try graceful shutdown first
        systemctl --user stop gamescope-session-plus@steam 2>/dev/null || true
        sleep 2
        
        # Force kill if still running
        if pgrep -x "gamescope" > /dev/null; then
            pkill -TERM gamescope
            sleep 1
            pkill -KILL gamescope 2>/dev/null || true
        fi
        
        # Wait for processes to fully exit
        while pgrep -x "gamescope" > /dev/null && [ $wait_count -lt $max_wait ]; do
            sleep 1
            ((wait_count++))
        done
        
    elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || pgrep -x "Hyprland" > /dev/null; then
        echo "Detected Hyprland session, shutting down..."
        
        # Try hyprctl first if available
        if command -v hyprctl &> /dev/null && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
            hyprctl dispatch exit 2>/dev/null || true
        else
            # Fallback to pkill
            pkill -TERM Hyprland 2>/dev/null || true
        fi
        
        sleep 2
        
        # Force kill if still running
        if pgrep -x "Hyprland" > /dev/null; then
            pkill -KILL Hyprland 2>/dev/null || true
        fi
        
        # Wait for processes to fully exit
        while pgrep -x "Hyprland" > /dev/null && [ $wait_count -lt $max_wait ]; do
            sleep 1
            ((wait_count++))
        done
        
    else
        echo "No specific session detected, attempting general cleanup..."
        # Fallback cleanup
        pkill -u $USER Hyprland 2>/dev/null || true
        pkill -u $USER gamescope 2>/dev/null || true
        systemctl --user stop gamescope-session-plus@steam 2>/dev/null || true
        sleep 2
    fi
    
    # Clean up any remaining compositor processes
    pkill -u $USER -f "gamescope-session" 2>/dev/null || true
    pkill -u $USER -f "steam" 2>/dev/null || true
    
    # Give time for cleanup
    sleep 1
}

# Execute cleanup
cleanup_session
EOSWITCH
chmod +x "$SWITCH_SCRIPT_PATH"

#=======================================================
# STEP 7: CONFIGURE HYPRLAND KEYBINDING
#=======================================================
echo -e "${C_BLUE}==> Configuring Hyprland Keybinding...${C_NC}"

# Create hyprland config directory if it doesn't exist
mkdir -p "$(dirname "$HYPR_CONF")"

# Check if hyprland.conf exists, create basic one if not
if [ ! -f "$HYPR_CONF" ]; then
    echo "# Hyprland Configuration" > "$HYPR_CONF"
    echo "" >> "$HYPR_CONF"
fi

# Remove any existing session switcher keybinding
sed -i '/# Session Switcher Keybinding/d' "$HYPR_CONF"
sed -i '/bind = SUPER, F12, exec,.*switch-session.sh/d' "$HYPR_CONF"

# Add the keybinding to hyprland.conf
cat >> "$HYPR_CONF" <<EOF

# Session Switcher Keybinding
bind = SUPER, F12, exec, $SWITCH_SCRIPT_PATH
EOF

echo -e "${C_GREEN}Added SUPER+F12 keybinding to $HYPR_CONF${C_NC}"

#=======================================================
# STEP 8: ENSURE NOTIFICATION DAEMON
#=======================================================
echo -e "${C_BLUE}==> Ensuring notification support...${C_NC}"

# Check if mako or dunst is installed, install mako if neither exists
if ! command -v mako &> /dev/null && ! command -v dunst &> /dev/null; then
    echo "Installing mako for notifications..."
    sudo pacman -S mako --needed --noconfirm
fi

# Add notification daemon to Hyprland autostart if not present
if ! grep -q "exec-once.*mako\|exec-once.*dunst" "$HYPR_CONF"; then
    if command -v mako &> /dev/null; then
        echo "exec-once = mako" >> "$HYPR_CONF"
    elif command -v dunst &> /dev/null; then
        echo "exec-once = dunst" >> "$HYPR_CONF"
    fi
fi

#=======================================================
# FINALIZATION
#=======================================================
echo -e "${C_GREEN}✅ Setup Complete! ✅${C_NC}\n"

echo -e "${C_YELLOW}What was fixed:${C_NC}"
echo "1. Updated session launch to use 'uwsm start hyprland-uwsm.desktop'"
echo "2. Added proper SUPER+F12 keybinding to hyprland.conf"
echo "3. Fixed Wofi environment variables and sizing"
echo "4. Added visual notifications for session switching"
echo "5. Improved session detection and cleanup"
echo "6. Added notification daemon support (mako/dunst)"

echo -e "\n${C_YELLOW}Reboot is required for changes to take effect.${C_NC}\n"

if [ "$AUTOLOGIN_ENABLED" = true ]; then
    echo -e "-> Autologin is enabled. System will boot directly into Hyprland."
    echo "   Use SUPER+F12 to switch sessions."
else
    echo -e "-> Autologin is disabled. Choose 'Auto Session Switcher' at login."
fi

echo -e "\n${C_BLUE}Post-reboot testing:${C_NC}"
echo "1. Press SUPER+F12 in Hyprland to test the session switcher"
echo "2. You can also run the switcher manually: $SWITCH_SCRIPT_PATH"
echo "3. Check Hyprland config: $HYPR_CONF"
