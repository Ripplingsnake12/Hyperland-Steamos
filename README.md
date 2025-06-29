# 🎮 Hyprland ↔ SteamOS Session Switcher

<div align="center">

![Hyprland Logo](https://raw.githubusercontent.com/hyprwm/Hyprland/main/assets/header.png)

**Seamlessly switch between Desktop and Gaming modes on Arch Linux**

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-00D9FF?style=for-the-badge&logo=wayland&logoColor=white)](https://hyprland.org/)
[![Steam](https://img.shields.io/badge/Steam-000000?style=for-the-badge&logo=steam&logoColor=white)](https://store.steampowered.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

</div>

## ✨ Features

🚀 **One-Click Session Switching** - Toggle between Desktop (Hyprland) and Gaming (SteamOS-like) modes  
🎯 **Gaming Optimized** - Seamless integration with Steam Big Picture and Gamescope  
🎨 **Beautiful UI** - Custom Wofi interface with glassmorphism effects  
⚡ **Lightning Fast** - Instant session switching with proper cleanup  
🔧 **Arch Native** - Built specifically for Arch Linux gaming setups  
🎮 **Controller Friendly** - Works perfectly with gaming controllers  

## 🖼️ Preview

```
┌─────────────────────────────┐
│        Switch Mode:         │
├─────────────────────────────┤
│  🎮 SteamOS                 │
│  🖥️ Desktop                 │
└─────────────────────────────┘
```

*Elegant Wofi interface with SteamOS-inspired glassmorphism design*

## 🎯 What This Does

Transform your Arch Linux gaming rig into the ultimate dual-purpose machine:

- **🖥️ Desktop Mode**: Full Hyprland experience with UWSM session management
- **🎮 Gaming Mode**: SteamOS-like experience with Gamescope for optimal gaming performance
- **⌨️ Quick Switch**: `SUPER + F12` to instantly toggle between modes
- **🔄 Smart Cleanup**: Properly terminates sessions and handles process management

## 📋 Requirements

### Core Dependencies
```bash
# Essential packages
sudo pacman -S hyprland sddm wofi gamescope steam

# AUR packages (install with yay)
yay -S gamescope-session-git uwsm-git gamescope-session-steam-git
```

### System Setup
- **OS**: Arch Linux (or Arch-based distro)
- **Display Manager**: SDDM
- **Session Manager**: UWSM
- **Window Manager**: Hyprland
- **Gaming Layer**: Gamescope + Steam

## 🚀 Installation

### Quick Install
```bash
# Clone the repository
git clone https://github.com/yourusername/hyprland-steamos-switcher.git
cd hyprland-steamos-switcher

# Make installer executable
chmod +x install.sh

# Run installation
./install.sh
```

### Manual Installation
<details>
<summary>Click to expand manual installation steps</summary>

1. **Copy the session switcher script**:
```bash
mkdir -p ~/.local/bin
cp install.sh ~/.local/bin/switch-session.sh
chmod +x ~/.local/bin/switch-session.sh
```

2. **Add Hyprland keybinding**:
```bash
echo "bind = SUPER, F12, exec, ~/.local/bin/switch-session.sh" >> ~/.config/hypr/hyprland.conf
```

3. **Configure SDDM for autologin** (optional):
```bash
sudo tee /etc/sddm.conf > /dev/null <<EOF
[Autologin]
User=yourusername
Session=switcher
EOF
```

</details>

## 🎮 Usage

### Switching Sessions

**Method 1: Keyboard Shortcut**
- Press `SUPER + F12` while in Hyprland
- Select your desired mode from the Wofi menu

**Method 2: Terminal**
```bash
~/.local/bin/switch-session.sh
```

**Method 3: From Gaming Mode**
- Use Steam's built-in session switching
- Or run the script from a terminal in desktop mode

### Session Types

| Mode | Description | Best For |
|------|-------------|----------|
| 🎮 **SteamOS Mode** | Gamescope + Steam Big Picture | Gaming, controller use, living room setup |
| 🖥️ **Desktop Mode** | Hyprland + UWSM | Development, productivity, general computing |

## ⚙️ Configuration

### Customizing the Wofi Interface
Edit `~/.config/wofi/style.css` to modify the appearance:

```css
/* Example: Change the accent color */
#entry:selected {
    background: linear-gradient(135deg, rgba(255, 107, 107, 0.8) 0%, rgba(255, 142, 83, 0.8) 100%);
}
```

### Adding Custom Session Options
Modify the script to add more session types:

```bash
choice=$(printf "🎮 SteamOS\n🖥️ Desktop\n🎲 RetroArch\n🎵 Music Mode" | wofi --dmenu ...)
```

## 🛠️ Troubleshooting

### Common Issues

**Session won't switch**
```bash
# Check if services are running
systemctl --user status gamescope-session-plus@steam
systemctl --user status uwsm@hyprland-uwsm.service
```

**Wofi not appearing**
```bash
# Verify Wayland display
echo $WAYLAND_DISPLAY
echo $XDG_RUNTIME_DIR
```

**Steam not launching in gaming mode**
```bash
# Restart Steam service
systemctl --user restart gamescope-session-plus@steam
```

### Getting Help
- 📖 Check the [Wiki](../../wiki) for detailed guides
- 🐛 Report issues on [GitHub Issues](../../issues)
- 💬 Join the discussion in [Discussions](../../discussions)

## 🗑️ Uninstallation

To completely remove the session switcher:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

This will remove:
- ✅ Session switching scripts
- ✅ SDDM autologin configuration  
- ✅ Systemd service overrides
- ✅ Wofi custom styling
- ✅ Hyprland keybinding

**Preserved**:
- ✅ Hyprland configuration (except switcher keybinding)
- ✅ UWSM setup
- ✅ All installed packages
- ✅ Steam and gaming setup

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Desktop Mode  │    │   Gaming Mode   │
│                 │    │                 │
│   Hyprland      │◄──►│   Gamescope     │
│   + UWSM        │    │   + Steam       │
│   + Full DE     │    │   + Big Picture │
└─────────────────┘    └─────────────────┘
         ▲                       ▲
         │                       │
         └───────── Wofi ────────┘
              Session Switcher
```

## 🤝 Contributing

We love contributions! Here's how you can help:

1. 🍴 Fork the repository
2. 🌿 Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. 💍 Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. 📤 Push to the branch (`git push origin feature/AmazingFeature`)
5. 🎯 Open a Pull Request

### Development Setup
```bash
# Clone your fork
git clone https://github.com/yourusername/hyprland-steamos-switcher.git

# Create a development branch
git checkout -b my-awesome-feature

# Test your changes
./install.sh  # Test installation
./uninstall.sh  # Test cleanup
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **[Hyprland](https://hyprland.org/)** - Amazing Wayland compositor
- **[Gamescope](https://github.com/ValveSoftware/gamescope)** - Valve's gaming compositor  
- **[UWSM](https://github.com/Vladimir-csp/uwsm)** - Universal Wayland Session Manager
- **[Wofi](https://hg.sr.ht/~scoopta/wofi)** - Beautiful application launcher
- **Arch Linux Community** - For the amazing ecosystem

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yourusername/hyprland-steamos-switcher&type=Date)](https://star-history.com/#yourusername/hyprland-steamos-switcher&Date)

---

<div align="center">

**Made with ❤️ for the Arch Linux Gaming Community**

[🏠 Homepage](../../) • [📖 Documentation](../../wiki) • [🐛 Report Bug](../../issues) • [💡 Request Feature](../../issues)

</div>
