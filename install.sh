#!/bin/bash
# Post-install configuration script for Fedora KDE

set -e

LOG_FILE="install.log"
ERR_TMP="install_error.tmp"
> "$LOG_FILE"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# External URLs
NORDVPN_INSTALL_URL="https://downloads.nordcdn.com/apps/linux/install.sh"
DENO_INSTALL_URL="https://deno.land/install.sh"
BUN_INSTALL_URL="https://bun.sh/install"

# Package lists
BASE_PKGS=("tealdeer" "htop" "fastfetch" "vlc" "keepassxc" "chromium")
DEV_PKGS=("python3" "git")
FLATPAK_APPS=("com.spotify.Client" "dev.vencord.Vesktop" "org.telegram.desktop" "eu.betterbird.Betterbird" "com.vscodium.codium")

# Function to run commands and handle logging
run_cmd() {
    local cmd="$1"
    local msg="$2"
    echo -e "${YELLOW}[EXE]${NC} $cmd"
    if eval "$cmd" 2> "$ERR_TMP"; then
        echo -e "${GREEN}[OK]${NC} $msg"
        echo "[OK] $msg" >> "$LOG_FILE"
    else
        echo -e "${RED}[ERR]${NC} $msg"
        echo "[ERR] $msg" >> "$LOG_FILE"
        if [ -s "$ERR_TMP" ]; then
            echo "   ↳ Detail: $(<"$ERR_TMP" tr '\n' ' ')" >> "$LOG_FILE"
        fi
    fi
    rm -f "$ERR_TMP"
}

# Check if a package is already installed
pkg_installed() {
    rpm -q "$1" &>/dev/null
}

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}=== FINAL CLEANUP ===${NC}"
    run_cmd "sudo dnf upgrade -y" "System upgraded"
    run_cmd "sudo dnf autoremove -y" "Obsolete packages removed"
    run_cmd "sudo dnf clean all" "Cache cleaned"
}
trap cleanup EXIT

# User interface
echo -e "${YELLOW}\n=============================================="
echo " POST-INSTALL FEDORA KDE CONFIGURATOR"
echo "=============================================="

# User options
read -p $'\nInstall NVIDIA drivers? (y/n): ' -n 1 INSTALL_NVIDIA
echo
INSTALL_NVIDIA=${INSTALL_NVIDIA,,}
INSTALL_NVIDIA=$([[ $INSTALL_NVIDIA =~ ^(y)$ ]] && echo true || echo false)

read -p $'Install Flatpak apps? (y/n): ' -n 1 INSTALL_FLATPAK_APPS
echo
INSTALL_FLATPAK_APPS=${INSTALL_FLATPAK_APPS,,}
INSTALL_FLATPAK_APPS=$([[ $INSTALL_FLATPAK_APPS =~ ^(y)$ ]] && echo true || echo false)

read -p $'Install NordVPN? (y/n): ' -n 1 INSTALL_NORDVPN
echo
INSTALL_NORDVPN=${INSTALL_NORDVPN,,}
INSTALL_NORDVPN=$([[ $INSTALL_NORDVPN =~ ^(y)$ ]] && echo true || echo false)

read -p $'Install JetBrains font? (y/n): ' -n 1 INSTALL_JETBRAINS_FONT
echo
INSTALL_JETBRAINS_FONT=${INSTALL_JETBRAINS_FONT,,}
INSTALL_JETBRAINS_FONT=$([[ $INSTALL_JETBRAINS_FONT =~ ^(y)$ ]] && echo true || echo false)

read -p $'Install development tools? (y/n): ' -n 1 INSTALL_DEV
echo
INSTALL_DEV=${INSTALL_DEV,,}
INSTALL_DEV=$([[ $INSTALL_DEV =~ ^(y)$ ]] && echo true || echo false)

# JavaScript runtime flags
HAS_NODE=false
HAS_DENO=false
HAS_BUN=false

if [ "$INSTALL_DEV" = true ]; then
    echo -e "\n${YELLOW}=== SELECT JAVASCRIPT RUNTIME ===${NC}"
    echo "1) NodeJS"
    echo "2) Deno"
    echo "3) Bun"
    read -p $'Choose an option (1/2/3): ' RUNTIME_CHOICE
    case "$RUNTIME_CHOICE" in
        1) HAS_NODE=true ;;
        2) HAS_DENO=true ;;
        3) HAS_BUN=true ;;
        *) echo -e "${RED}Invalid choice, skipping JS runtime.${NC}" ;;
    esac
fi

# Begin execution

# Base packages
echo -e "\n${YELLOW}=== INSTALLING BASE PACKAGES ===${NC}"
run_cmd "sudo dnf install -y ${BASE_PKGS[*]}" "Base packages installed"

# Flatpak apps
echo -e "\n${YELLOW}=== INSTALLING FLATPAK APPS ===${NC}"
if [ "$INSTALL_FLATPAK_APPS" = true ]; then
    for app in "${FLATPAK_APPS[@]}"; do
        if flatpak list --app | grep -q "$app"; then
            echo -e "${GREEN}[OK]${NC} $app is already installed"
        else
            run_cmd "flatpak install -y flathub $app" "Flatpak $app installed"
        fi
    done
else
    echo -e "${GREEN}[OK]${NC} Flatpak skipped"
fi

# JetBrains font
echo -e "\n${YELLOW}=== INSTALLING JETBRAINS FONT ===${NC}"
if [ "$INSTALL_JETBRAINS_FONT" = true ]; then
    run_cmd "sudo dnf install -y jetbrains-mono-fonts-all" "JetBrains font installed"
    run_cmd "sudo fc-cache -f -v" "Font cache updated"
else
    echo -e "${GREEN}[OK]${NC} JetBrains font skipped"
fi

# Development tools
echo -e "\n${YELLOW}=== INSTALLING DEVELOPMENT TOOLS ===${NC}"
if [ "$INSTALL_DEV" = true ]; then
    for pkg in "${DEV_PKGS[@]}"; do
        if ! pkg_installed "$pkg"; then
            run_cmd "sudo dnf install -y $pkg" "Dev tool $pkg installed"
        else
            echo -e "${GREEN}[OK]${NC} $pkg already installed"
        fi
    done
    if [ "$HAS_NODE" = true ]; then
        run_cmd "sudo dnf install -y nodejs" "NodeJS installed"
    elif [ "$HAS_DENO" = true ]; then
        run_cmd "curl -fsSL $DENO_INSTALL_URL | sh" "Deno installed"
    elif [ "$HAS_BUN" = true ]; then
        run_cmd "curl -fsSL $BUN_INSTALL_URL | bash" "Bun installed"
    fi
else
    echo -e "${GREEN}[OK]${NC} Dev tools skipped"
fi

# NVIDIA drivers
echo -e "\n${YELLOW}=== INSTALLING NVIDIA DRIVERS ===${NC}"
if [ "$INSTALL_NVIDIA" = true ]; then
    run_cmd "sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda" "NVIDIA drivers installed"
else
    echo -e "${GREEN}[OK]${NC} NVIDIA drivers skipped"
fi

# NordVPN
echo -e "\n${YELLOW}=== INSTALLING NORDVPN ===${NC}"
if [ "$INSTALL_NORDVPN" = true ]; then
    run_cmd "yes | sh <(curl -sSf $NORDVPN_INSTALL_URL)" "NordVPN script run"
    if rpm -q nordvpn &>/dev/null; then
        run_cmd "sudo usermod -aG nordvpn $USER" "User added to nordvpn group"
        run_cmd "sudo nordvpn set technology nordlynx" "NordLynx enabled"
        run_cmd "sudo nordvpn set autoconnect on" "Autoconnect enabled"
    else
        echo -e "${RED}[ERR]${NC} NordVPN not installed"
    fi
else
    echo -e "${GREEN}[OK]${NC} NordVPN skipped"
fi

echo -e "
${GREEN}Configuration complete!${NC}"

# Show summary of installations
echo -e "
${YELLOW}=== INSTALLATION SUMMARY ===${NC}"
if [ -f "$LOG_FILE" ]; then
    grep "^\[OK\]" "$LOG_FILE" || echo "No successful operations recorded."
else
    echo "Log file not found: $LOG_FILE"
fi

echo -e "
${YELLOW}If you haven't logged in to NordVPN, run:${NC}"
echo "  nordvpn login"
echo "  nordvpn connect"

# End script
exit 0
