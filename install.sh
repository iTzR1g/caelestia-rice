#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_SRC="$REPO_DIR/config"
BACKUP_DIR="$HOME/.config/caelestia-rice.backup.$(date +%Y%m%d%H%M%S)"

# ── Packages ──────────────────────────────────────────────────────
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

    sudo pacman -S --needed --noconfirm git base-devel >/dev/null 2>&1

    [ -d "$dir" ] && rm -rf "$dir"
    if ! git clone --depth=1 "https://aur.archlinux.org/$name.git" "$dir" 2>/dev/null; then
        return 1
    fi

    (cd "$dir" && makepkg -si --noconfirm --needed)
    rm -rf "$dir"
    return 0
}

AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    ok "paru already installed."
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    ok "yay already installed."
else
    info "No AUR helper found. Installing paru..."
    if install_aur_helper "paru"; then
        AUR_HELPER="paru"
        ok "paru installed."
    else
        warn "paru install failed, trying yay..."
        if install_aur_helper "yay"; then
            AUR_HELPER="yay"
            ok "yay installed."
        else
            warn "Could not install paru or yay. AUR packages will be skipped."
        fi
    fi
fi

# ── Install pacman packages ──────────────────────────────────────
MISSING=()
for pkg in "${PACMAN_PKGS[@]}"; do
    pacman -Qi "$pkg" &>/dev/null || MISSING+=("$pkg")
done

if [ ${#MISSING[@]} -gt 0 ]; then
    info "Installing: ${MISSING[*]}"
    sudo pacman -S --needed --noconfirm "${MISSING[@]}"
    ok "Packages installed."
else
    ok "All pacman packages already present."
fi

# ── Install AUR packages ─────────────────────────────────────────
if [ -n "$AUR_HELPER" ]; then
    for pkg in "${AUR_PKGS[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            ok "$pkg already installed."
        else
            info "Installing $pkg from AUR..."
            "$AUR_HELPER" -S --noconfirm --needed "$pkg"
            ok "$pkg installed."
        fi
    done
else
    for pkg in "${AUR_PKGS[@]}"; do
        warn "Skipping $pkg — no AUR helper available. Install manually."
    done
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
    ok "Fonts installed."
else
    ok "JetBrainsMono Nerd Font already present."
fi

# ── Backup existing configs ───────────────────────────────────────
BACKUP_DIRS=(hypr fish kitty fastfetch caelestia quickshell caelestia-dots)
info "Backing up existing configs to $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR"
for d in "${BACKUP_DIRS[@]}"; do
    [ -d "$HOME/.config/$d" ] && cp -r "$HOME/.config/$d" "$BACKUP_DIR/" 2>/dev/null || true
done
[ -f "$HOME/.config/starship.toml" ] && cp "$HOME/.config/starship.toml" "$BACKUP_DIR/"
[ -f "$HOME/.local/state/caelestia/scheme.json" ] && {
    mkdir -p "$BACKUP_DIR/state"
    cp "$HOME/.local/state/caelestia/scheme.json" "$BACKUP_DIR/state/"
}
ok "Backup complete."

# ── Deploy configs ────────────────────────────────────────────────
info "Deploying configs..."
deploy() {
    local src="$CONFIG_SRC/$1"
    local dest="$HOME/$2"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        rm -rf "$dest"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sfT "$src" "$dest"
    ok "$dest → $src"
}

deploy hypr                .config/hypr
deploy fish                .config/fish
deploy kitty               .config/kitty
deploy fastfetch           .config/fastfetch
deploy caelestia           .config/caelestia
deploy quickshell/caelestia .config/quickshell/caelestia
deploy starship.toml       .config/starship.toml

# ── Color scheme ──────────────────────────────────────────────────
if [ -f "$CONFIG_SRC/caelestia/scheme.json" ]; then
    mkdir -p "$HOME/.local/state/caelestia"
    cp "$CONFIG_SRC/caelestia/scheme.json" "$HOME/.local/state/caelestia/scheme.json"
    ok "Caelestia color scheme applied."
fi

# ── Fish as default shell ─────────────────────────────────────────
FISH="$(which fish 2>/dev/null || true)"
if [ -n "$FISH" ]; then
    if ! grep -qx "$FISH" /etc/shells 2>/dev/null; then
        echo "$FISH" | sudo tee -a /etc/shells >/dev/null
    fi
    if [ "$SHELL" != "$FISH" ]; then
        info "Setting fish as default shell..."
        chsh -s "$FISH"
        ok "Default shell set to fish (log out & back in to apply)."
    else
        ok "Fish is already the default shell."
    fi
else
    warn "fish not found — skipping shell change."
fi

# ── Done ──────────────────────────────────────────────────────────
echo
ok "Installation complete!"
echo
echo "$(color '→')  Restart Hyprland:  $(color 'SUPER + SHIFT + R')"
echo "$(color '→')  Restart shell:     $(color 'exec fish')"
echo "$(color '→')  Caelestia scheme:  auto-generated from wallpaper on next login"
echo "$(color '→')                         or keep the included scheme.json"
echo
