#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_SRC="$REPO_DIR/config"
BACKUP_DIR="$HOME/.config/caelestia-rice.backup.$(date +%Y%m%d%H%M%S)"
PACMAN_PKGS=(hyprland kitty fish fastfetch starship grim slurp eza zoxide lazygit)
AUR_PKGS=(quickshell)

color() { printf "\e[38;2;23;147;209m%s\e[0m" "$1"; }
info()  { echo -e "$(color '::') $1"; }
ok()    { echo -e "$(color '✓') $1"; }
warn()  { echo -e "$(color '!') $1"; }
err()   { echo -e "$(color '✗') $1" >&2; }

trap 'err "Installation aborted."' ERR

echo
info "Caelestia Rice — Arch Blue on Catppuccin Mocha"
echo

# ── Package installation ──────────────────────────────────────────
info "Installing packages..."
if ! command -v pacman &>/dev/null; then
    err "This installer requires pacman (Arch Linux)."
    exit 1
fi

sudo pacman -Syu --noconfirm "${PACMAN_PKGS[@]}" 2>/dev/null || {
    warn "Some packages may have failed. Check pacman output above."
}

for pkg in "${AUR_PKGS[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        if command -v paru &>/dev/null; then
            paru -S --noconfirm "$pkg"
        elif command -v yay &>/dev/null; then
            yay -S --noconfirm "$pkg"
        else
            warn "Install $pkg manually (paru/yay): $pkg"
        fi
    fi
done

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
if ! grep -q "$(which fish 2>/dev/null)" /etc/shells 2>/dev/null; then
    echo "$(which fish)" | sudo tee -a /etc/shells >/dev/null
fi
if [ "$SHELL" != "$(which fish)" ]; then
    info "Setting fish as default shell..."
    chsh -s "$(which fish)"
    ok "Default shell set to fish (log out & back in)."
fi

# ── Done ──────────────────────────────────────────────────────────
echo
ok "Installation complete!"
echo
echo "$(color '→')  Restart Hyprland:  $(color 'SUPER + SHIFT + R')"
echo "$(color '→')  Apply font cache:  $(color 'fc-cache -fv')  (already done)"
echo "$(color '→')  Restart shell:     $(color 'exec fish')"
echo "$(color '→')  If gaps look off:  $(color 'SUPER + SHIFT + R')  (Hyprland restart)"
echo "$(color '→')  Caelestia scheme:  auto-generated from wallpaper on next login"
echo "$(color '→')                         or keep the included scheme.json"
echo
