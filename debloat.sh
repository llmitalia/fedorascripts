#!/bin/bash
# Debloat script for Fedora 42 KDE Plasma
# Version: 1.0 – Optimization and safe management of essential packages

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging functions
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Format sizes in a human-readable form
human_size() { numfmt --to=iec --suffix=B --padding=7 "$1"; }

# Check if a package is installed
is_installed() { rpm -q "$1" &>/dev/null; }

# Essential packages for Fedora and KDE Plasma
ESSENTIAL_PKGS=(
    plasma-desktop plasmashell plasma-workspace kwin sddm systemsettings
    dolphin konsole kgpg okular kamoso plasma-pa plasma-nm plasma-thunderbolt
    plasma-disks plasma-activities plasma-activities-stats plasma-user-manager
    kactivities-workspace kactivitymanagerd kde-cli-tools kio-extras kmenuedit
    kpipewire kwrited filelight khelpcenter keditbookmarks kf6-kcoreaddons
    kf6-kconfig kf6-kconfigwidgets kf6-kwidgetsaddons kf6-kio-core-libs
    kf6-kio-file-widgets kf6-kio-gui kf6-solid libplasma libkworkspace6
    libksysguard kcm_touchpad kcm_tablet kscreen polkit-kde
    xdg-desktop-portal-kde rpm dnf sudo bash coreutils filesystem glibc kernel
    systemd networkmanager dbus fontconfig freedesktop-menus gtk3 qt6-qtbase
    qt6-qtwidgets xorg-x11-server-Xorg kwalletmanager
)

# Candidate packages for removal, organized by category
DEBLOAT_PKGS=(
    akonadi akonadi-contacts akonadi-import-wizard akonadi-mime akonadi-notes
    akonadi-search akregator grantlee-editor kaddressbook kmail kmail-account-wizard
    kontact korganizer ktnef mbox-importer pim-data-exporter pim-sieve-editor
    kblog kmahjongg kmines kpat palapeli kajongg granatier kiriki knights kolf
    konquest ksudoku dragon elisa-player juk k3b kwave audiotube cantata haruna
    kaffeine kleopatra kmousetool kmouth kdf kipi-plugins kfloppy kget krdc krfb
    ktimer kmag ksnapshot kbackup kcolorchooser kcron kolourpaint kruler digikam
    kphotoalbum skanlite skanpage kfind konversation neochat qrca falkon ktorrent
    knotes kmail-mobile libreoffice-calc libreoffice-draw libreoffice-impress
    libreoffice-math libreoffice-writer libreoffice-base libreoffice-core
    libreoffice-data libreoffice-gtk3 libreoffice-kde5 libreoffice-langpack-it
    libreoffice-x11 kdevelop kdesdk kdevelop-pg-qt kapptemplate kcachegrind
    kdesdk-thumbnailers
)

# Remove duplicates and exclude essential packages
DEBLOAT_PKGS=($(echo "${DEBLOAT_PKGS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
SAFE_TO_REMOVE=()
for pkg in "${DEBLOAT_PKGS[@]}"; do
    if [[ ! " ${ESSENTIAL_PKGS[*]} " =~ " $pkg " ]]; then
        SAFE_TO_REMOVE+=("$pkg")
    else
        log_warn "Excluded essential package: $pkg"
    fi
done

# Preliminary checks
if ! command -v dnf &>/dev/null; then
    log_error "dnf not found."
    exit 1
fi
if [ "$EUID" -eq 0 ]; then
    log_error "Do not run as root."
    exit 1
fi
if ! is_installed plasma-desktop; then
    log_warn "Plasma Desktop not installed."
    read -rp "Continue anyway? (y/N): " cont
    [[ ! "$cont" =~ ^[Yy]$ ]] && exit 0
fi

echo -e "${BOLD}--- Debloat Fedora KDE Plasma 42 v1.0 ---${NC}"

# Identify installed packages and calculate total size
SAFE_TO_REMOVE_INSTALLED=()
TOTAL_SIZE=0
for pkg in "${SAFE_TO_REMOVE[@]}"; do
    if is_installed "$pkg"; then
        size=$(rpm -q --queryformat "%{SIZE}" "$pkg" 2>/dev/null || echo 0)
        [[ "$size" -eq 0 ]] && size=$(dnf repoquery --installed --queryformat "%{size}" "$pkg")
        TOTAL_SIZE=$((TOTAL_SIZE + size))
        SAFE_TO_REMOVE_INSTALLED+=("$pkg")
    fi
done

if [ ${#SAFE_TO_REMOVE_INSTALLED[@]} -eq 0 ]; then
    log_warn "No packages to remove found."
    exit 0
fi

# Display list and size of packages to remove
echo -e "${BOLD}Packages to remove (${#SAFE_TO_REMOVE_INSTALLED[@]}):${NC}"
for pkg in "${SAFE_TO_REMOVE_INSTALLED[@]}"; do
    size=$(rpm -q --queryformat "%{SIZE}" "$pkg" 2>/dev/null || echo 0)
    [[ "$size" -eq 0 ]] && size=$(dnf repoquery --installed --queryformat "%{size}" "$pkg")
    echo "  - $pkg ($(human_size "$size"))"
done

echo "Estimated total space to free: $(human_size "$TOTAL_SIZE")"

read -rp "Proceed with package removal? (y/N): " confirm
[[ ! "$confirm" =~ ^[Yy]$ ]] && exit 0

BEFORE=$(df --output=used -B1 / | tail -1)
sudo dnf -y remove "${SAFE_TO_REMOVE_INSTALLED[@]}"
sudo dnf clean all && sudo dnf makecache
AFTER=$(df --output=used -B1 / | tail -1)
log_success "Freed space: $(human_size $((BEFORE-AFTER)))"

read -rp "Also remove orphaned dependencies? (y/N): " orph
[[ "$orph" =~ ^[Yy]$ ]] && sudo dnf autoremove -y

read -rp "Clean user cache older than 7 days? (y/N): " uc
[[ "$uc" =~ ^[Yy]$ ]] && find ~/.cache -type f -atime +7 -delete

log_success "Cleanup complete!"

echo "Recommended next steps:"
echo -e "${YELLOW}Consider a full reboot to apply all changes.${NC}"

exit 0
