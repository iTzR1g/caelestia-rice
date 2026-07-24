#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_SRC="$REPO_DIR/config"
BACKUP_DIR="$HOME/.config/caelestia-rice.backup.$(date +%Y%m%d%H%M%S)"
CAELESTIA_SRC="$HOME/.config/quickshell/caelestia"

# ── Packages ──────────────────────────────────────────────────────
BUILD_DEPS=(
    base-devel git cmake ninja
    qt6-base qt6-declarative qt6-svg qt6-wayland
    wayland-protocols pkgconf libglvnd
)
PACMAN_PKGS=(
    hyprland kitty fish fastfetch starship
    grim slurp eza zoxide lazygit
    curl unzip
)
AUR_PKGS=(quickshell)

# ── Colors ────────────────────────────────────────────────────────
color() { printf "\e[38;2;23;147;209m%s\e[0m" "$1"; }
info()  { echo -e "$(color '::') $1"; }
ok()    { echo -e "$(color '✓') $1"; }
warn()  { echo -e "$(color '!') $1"; }
err()   { echo -e "$(color '✗') $1" >&2; }

trap 'err "Installation aborted."' ERR

echo
info "Caelestia Rice — Arch Blue on Catppuccin Mocha"
echo

# ── Distro check ──────────────────────────────────────────────────
if ! command -v pacman &>/dev/null; then
    err "This installer requires pacman (Arch Linux or derivative)."
    exit 1
fi
if ! command -v sudo &>/dev/null; then
    err "sudo is required."
    exit 1
fi

# ── System update ─────────────────────────────────────────────────
info "Updating system..."
sudo pacman -Syu --noconfirm

# ── Install AUR helper (paru preferred, yay fallback) ────────────
install_aur_helper() {
    local name=$1
    local dir="/tmp/$name-build"
    info "Installing $name from AUR..."

    [ -d "$dir" ] && rm -rf "$dir"
    if ! git clone --depth=1 "https://aur.archlinux.org/$name.git" "$dir" 2>/dev/null; then
        return 1
    fi
    (cd "$dir" && makepkg -si --noconfirm --needed)
    rm -rf "$dir"
}

AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
else
    info "No AUR helper found. Installing paru..."
    if install_aur_helper "paru"; then
        AUR_HELPER="paru"
    else
        warn "paru failed, trying yay..."
        install_aur_helper "yay"
        AUR_HELPER="yay"
    fi
    ok "$AUR_HELPER installed."
fi

# ── Install build dependencies ────────────────────────────────────
MISSING_BUILD=()
for pkg in "${BUILD_DEPS[@]}"; do
    pacman -Qi "$pkg" &>/dev/null || MISSING_BUILD+=("$pkg")
done
if [ ${#MISSING_BUILD[@]} -gt 0 ]; then
    info "Installing build deps: ${MISSING_BUILD[*]}"
    sudo pacman -S --needed --noconfirm "${MISSING_BUILD[@]}"
fi

# ── Install app packages ──────────────────────────────────────────
MISSING_PKGS=()
for pkg in "${PACMAN_PKGS[@]}"; do
    pacman -Qi "$pkg" &>/dev/null || MISSING_PKGS+=("$pkg")
done
if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    info "Installing: ${MISSING_PKGS[*]}"
    sudo pacman -S --needed --noconfirm "${MISSING_PKGS[@]}"
fi

# ── Install AUR packages ─────────────────────────────────────────
for pkg in "${AUR_PKGS[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
        ok "$pkg already installed."
    else
        info "Installing $pkg from AUR..."
        "$AUR_HELPER" -S --noconfirm --needed "$pkg"
    fi
done

# ── Build Caelestia shell ─────────────────────────────────────────
if [ -d "$CAELESTIA_SRC/.git" ]; then
    info "Caelestia shell source exists. Updating..."
    git -C "$CAELESTIA_SRC" pull --ff-only
else
    info "Cloning Caelestia shell..."
    git clone --depth=1 "https://github.com/caelestia-dots/shell.git" "$CAELESTIA_SRC"
fi

if [ ! -f "$CAELESTIA_SRC/build/build.ninja" ]; then
    info "Configuring build with CMake..."
    cmake -S "$CAELESTIA_SRC" -B "$CAELESTIA_SRC/build" -G Ninja -DCMAKE_BUILD_TYPE=Release
fi

info "Building Caelestia shell (this may take a while)..."
cmake --build "$CAELESTIA_SRC/build" --parallel
ok "Caelestia shell built."

# ── Apply QML overrides ──────────────────────────────────────────
if [ -d "$CONFIG_SRC/quickshell/caelestia" ]; then
    info "Applying QML overrides..."
    cp -r "$CONFIG_SRC/quickshell/caelestia/." "$CAELESTIA_SRC/"
    ok "QML overrides applied (clock, osicon, toggles, gamemode)."
fi

# ── JetBrainsMono Nerd Font ───────────────────────────────────────
if ! fc-list | grep -qi "JetBrainsMono.*Nerd" &>/dev/null; then
    info "Installing JetBrainsMono Nerd Font..."
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    curl -LfSo "$FONT_DIR/JetBrainsMono.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -qo "$FONT_DIR/JetBrainsMono.zip" -d "$FONT_DIR" && rm "$FONT_DIR/JetBrainsMono.zip"
    fc-cache -f
fi

# ── Backup existing configs ───────────────────────────────────────
info "Backing up configs to $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR"
for d in hypr fish kitty fastfetch caelestia caelestia-dots; do
    [ -d "$HOME/.config/$d" ] && cp -r "$HOME/.config/$d" "$BACKUP_DIR/" 2>/dev/null || true
done
[ -f "$HOME/.config/starship.toml" ] && cp "$HOME/.config/starship.toml" "$BACKUP_DIR/"
[ -f "$HOME/.local/state/caelestia/scheme.json" ] && {
    mkdir -p "$BACKUP_DIR/state"
    cp "$HOME/.local/state/caelestia/scheme.json" "$BACKUP_DIR/state/"
}

# ── Deploy configs ────────────────────────────────────────────────
info "Deploying configs..."
deploy() {
    local src="$CONFIG_SRC/$1"
    local dest="$HOME/$2"
    [ -e "$dest" ] && [ ! -L "$dest" ] && rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    ln -sfT "$src" "$dest"
    ok "  $dest → $src"
}

deploy hypr                .config/hypr
deploy fish                .config/fish
deploy kitty               .config/kitty
deploy fastfetch           .config/fastfetch
deploy caelestia           .config/caelestia
deploy starship.toml       .config/starship.toml

# ── Caelestia config files (shell.json, tokens, scheme) ───────────
cp "$CONFIG_SRC/caelestia/shell.json"        "$HOME/.config/caelestia/shell.json"
cp "$CONFIG_SRC/caelestia/shell-tokens.json" "$HOME/.config/caelestia/shell-tokens.json"
mkdir -p "$HOME/.local/state/caelestia"
cp "$CONFIG_SRC/caelestia/scheme.json"       "$HOME/.local/state/caelestia/scheme.json"
ok "Caelestia config and color scheme deployed."

# ── Fish as default shell ─────────────────────────────────────────
FISH="$(which fish 2>/dev/null || true)"
if [ -n "$FISH" ]; then
    grep -qx "$FISH" /etc/shells 2>/dev/null || echo "$FISH" | sudo tee -a /etc/shells >/dev/null
    if [ "$SHELL" != "$FISH" ]; then
        chsh -s "$FISH"
        info "Default shell set to fish. Log out & back in to apply."
    fi
fi

# ── Post-install notes ────────────────────────────────────────────
echo
ok "Everything installed."
echo
echo "$(color '→')  Restart Hyprland:   $(color 'SUPER + SHIFT + R')  or  $(color 'hyprctl reload')"
echo "$(color '→')  Restart Caelestia:  $(color 'CTRL + SUPER + ALT + R')  or reboot"
echo "$(color '→')  Restart shell:      $(color 'exec fish')"
echo "$(color '→')  Caelestia scheme:   auto-generated from wallpaper on next login"
echo "$(color '→')  Build logs:         $(color "$CAELESTIA_SRC/build")"
echo
