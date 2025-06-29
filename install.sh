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
        echo "hyprland-uwsm.desktop" > "$HOME/.next-session"
        notify-send "Session Switcher" "Switching to Desktop..." -t 2000
        ;;
    "🎮 SteamOS")
        echo "gamescope-session-steam.desktop" > "$HOME/.next-session"
        notify-send "Session Switcher" "Switching to SteamOS..." -t 2000
        ;;
    *)
        exit 1
        ;;
esac

# Clean shutdown of current session
if pgrep -x "gamescope" > /dev/null; then
    # We're in Gamescope, need to exit it properly
    pkill -TERM gamescope
    systemctl --user stop gamescope-session-plus@steam 2>/dev/null || true
elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    # We're in Hyprland, exit gracefully
    hyprctl dispatch exit
    sleep 2 # Give Hyprland time to exit
else
    # Fallback - try to determine session and exit
    pkill -u $USER Hyprland 2>/dev/null || true
    pkill -u $USER gamescope 2>/dev/null || true
    systemctl --user stop gamescope-session-plus@steam 2>/dev/null || true
fi
