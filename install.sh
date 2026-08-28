#!/usr/bin/env bash
set -euo pipefail

# ── Paths ──────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_SRC="$REPO_DIR/config"
BACKUP_DIR="$HOME/.config/caelestia-rice.backup.$(date +%Y%m%d%H%M%S)"
CAELESTIA_SRC="$HOME/.config/quickshell/caelestia"
STATE_DIR="$HOME/.local/state/caelestia"

# ── Packages ──────────────────────────────────────────────────────
# Bootstrap: needed on a truly fresh Arch before we can clone/build anything.
BOOTSTRAP=(
    base-devel git curl unzip wget rust
)

# Hyprland compositor + XDG portals + launcher
HYPR_PKGS=(
    hyprland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    rofi
    qt6-wayland
)

# Caelestia shell runtime deps (matches caelestia-dots/shell PKGBUILD)
SHELL_PKGS=(
    ddcutil
    brightnessctl
    lm_sensors
    aubio
    libqalculate
    networkmanager
    power-profiles-daemon
    ttf-material-symbols-variable
    ttf-cascadia-code-nerd
    qt6-imageformats
    swappy
)

# PipeWire audio stack
AUDIO_PKGS=(
    pipewire
    pipewire-pulse
    pipewire-audio
    pipewire-alsa
    pipewire-jack
    wireplumber
)

# Qt / GTK theming
THEME_PKGS=(
    adw-gtk-theme
    papirus-icon-theme
    frameworkintegration
    gnome-themes-extra
)

# Core apps & tools used by the configs
APP_PKGS=(
    kitty bash fastfetch starship
    thunar pavucontrol
    grim slurp wl-clipboard jq
    eza zoxide lazygit bat ripgrep direnv neovim code
    flatpak xdg-user-dirs
    libnotify playerctl gammastep
    gnome-keyring polkit-gnome geoclue
    bluez bluez-utils hyprpicker
    noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd
)

# C++ build deps for the Caelestia shell
BUILD_DEPS=(
    cmake ninja
    qt6-base qt6-declarative qt6-svg qt6-shadertools
    wayland-protocols pkgconf libglvnd
)

# AUR packages
AUR_PKGS=(quickshell-git caelestia-cli cliphist qtengine libcava ttf-rubik-vf papirus-folders)
# Optional AUR packages: installed best-effort (won't abort the install)
AUR_OPTIONAL_PKGS=(darkly-bin)

# ── Colors ────────────────────────────────────────────────────────
color() { printf "\e[38;2;23;147;209m%s\e[0m" "$1"; }
info()  { echo -e "$(color '::') $1"; }
ok()    { echo -e "$(color '✓') $1"; }
warn()  { echo -e "$(color '!') $1"; }
err()   { echo -e "$(color '✗') $1" >&2; }

trap 'err "Installation aborted. See the error above."' ERR

echo
info "Caelestia Rice — Arch Blue on Catppuccin Mocha"
echo

# ── Preflight ─────────────────────────────────────────────────────
if ! command -v pacman &>/dev/null; then
    err "This installer requires pacman (Arch Linux or derivative)."
    exit 1
fi
if [ "$(id -u)" -eq 0 ]; then
    err "Do NOT run as root — makepkg cannot run as root."
    err "Run as a normal user; sudo is invoked automatically."
    exit 1
fi
if ! command -v sudo &>/dev/null; then
    err "sudo is required."
    exit 1
fi
sudo -v || { err "sudo access is required."; exit 1; }

# ── System update ─────────────────────────────────────────────────
info "Updating system..."
sudo pacman -Syu --noconfirm

# ── Bootstrap (make the box able to clone/build anything) ─────────
MISSING_BOOTSTRAP=()
for pkg in "${BOOTSTRAP[@]}"; do
    pacman -Qi "$pkg" &>/dev/null || MISSING_BOOTSTRAP+=("$pkg")
done
if [ ${#MISSING_BOOTSTRAP[@]} -gt 0 ]; then
    info "Bootstrapping build tools: ${MISSING_BOOTSTRAP[*]}"
    sudo pacman -S --needed --noconfirm "${MISSING_BOOTSTRAP[@]}"
fi

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

# ── Install all repo packages ─────────────────────────────────────
ALL_PACMAN=("${HYPR_PKGS[@]}" "${SHELL_PKGS[@]}" "${AUDIO_PKGS[@]}" "${THEME_PKGS[@]}" "${APP_PKGS[@]}" "${BUILD_DEPS[@]}")
MISSING_PKGS=()
for pkg in "${ALL_PACMAN[@]}"; do
    pacman -Qi "$pkg" &>/dev/null || MISSING_PKGS+=("$pkg")
done
if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    info "Installing ${#MISSING_PKGS[@]} packages: ${MISSING_PKGS[*]}"
    sudo pacman -S --needed --noconfirm "${MISSING_PKGS[@]}"
fi
ok "All repo packages installed."

# ── Install AUR packages ─────────────────────────────────────────
for pkg in "${AUR_PKGS[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
        ok "$pkg already installed."
    else
        info "Installing $pkg from AUR (this may build from source)..."
        "$AUR_HELPER" -S --noconfirm --needed "$pkg"
    fi
done

for pkg in "${AUR_OPTIONAL_PKGS[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
        ok "$pkg already installed."
    elif "$AUR_HELPER" -S --noconfirm --needed "$pkg"; then
        ok "$pkg installed."
    else
        warn "Optional package '$pkg' failed to install; continuing."
    fi
done

# ── Build Caelestia shell ─────────────────────────────────────────
if [ -d "$CAELESTIA_SRC/.git" ]; then
    info "Caelestia shell source exists. Updating..."
    git -C "$CAELESTIA_SRC" fetch --depth=1 origin main
    git -C "$CAELESTIA_SRC" reset --hard origin/main
else
    info "Cloning Caelestia shell..."
    git clone --depth=1 "https://github.com/caelestia-dots/shell.git" "$CAELESTIA_SRC"
fi

# ── Apply QML overrides (before build so they're in the tree) ─────
if [ -d "$CONFIG_SRC/quickshell/caelestia" ] && \
   [ "$(readlink -f "$CAELESTIA_SRC" 2>/dev/null)" != "$(readlink -f "$CONFIG_SRC/quickshell/caelestia")" ]; then
    info "Applying QML overrides..."
    cp -r "$CONFIG_SRC/quickshell/caelestia/." "$CAELESTIA_SRC/"
    ok "QML overrides applied (clock, osicon, toggles, gamemode)."
fi

if [ ! -f "$CAELESTIA_SRC/build/build.ninja" ]; then
    info "Configuring build with CMake..."
    cmake -S "$CAELESTIA_SRC" -B "$CAELESTIA_SRC/build" -G Ninja -DCMAKE_BUILD_TYPE=Release
fi

info "Building Caelestia shell (this may take a while)..."
cmake --build "$CAELESTIA_SRC/build" --parallel
ok "Caelestia shell built."

# ── Backup existing configs ───────────────────────────────────────
info "Backing up existing configs to $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR"
for d in hypr bash kitty fastfetch caelestia caelestia-dots quickshell; do
    [ -d "$HOME/.config/$d" ] && cp -r "$HOME/.config/$d" "$BACKUP_DIR/" 2>/dev/null || true
done
[ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$BACKUP_DIR/" 2>/dev/null || true
[ -f "$HOME/.config/starship.toml" ] && cp "$HOME/.config/starship.toml" "$BACKUP_DIR/" 2>/dev/null || true
[ -f "$STATE_DIR/scheme.json" ] && {
    mkdir -p "$BACKUP_DIR/state"
    cp "$STATE_DIR/scheme.json" "$BACKUP_DIR/state/" 2>/dev/null || true
}

# ── Deploy configs ────────────────────────────────────────────────
info "Deploying configs..."
deploy() {
    local src="$CONFIG_SRC/$1"
    local dest="$HOME/$2"

    # Avoid clobbering / self-copying: if the target already resolves to the
    # repo path (e.g. from a previous run / manual symlink), leave it alone.
    if [ -e "$dest" ] && [ "$(readlink -f "$dest" 2>/dev/null)" = "$(readlink -f "$src")" ]; then
        ok "  $dest already points to $src"
        return
    fi

    [ -e "$dest" ] && [ ! -L "$dest" ] && rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    ln -sfT "$src" "$dest"
    ok "  $dest → $src"
}

deploy hypr                .config/hypr
deploy bash/.bashrc        .bashrc
deploy kitty               .config/kitty
deploy fastfetch           .config/fastfetch
deploy caelestia           .config/caelestia
deploy starship.toml       .config/starship.toml

# Copy a file only if it isn't already the same file as the destination
# (works through symlinks, so repo symlinks can't cause self-copies).
safe_copy() {
    local src="$1" dest="$2"
    if [ -e "$src" ] && [ "$(readlink -f "$dest" 2>/dev/null)" = "$(readlink -f "$src")" ]; then
        ok "  $dest already matches $src"
        return 0
    fi
    cp -f "$src" "$dest"
}

# ── Caelestia state files (scheme is generated into state, not config)
mkdir -p "$STATE_DIR"
safe_copy "$CONFIG_SRC/caelestia/scheme.json" "$STATE_DIR/scheme.json"
ok "Caelestia config and color scheme deployed."

# ── Hyprpaper (generated per-user: no env expansion in its config) ─
cat > "$HOME/.config/hypr/hyprpaper.conf" <<EOF
preload = $HOME/.config/hypr/wallpapers/dark.png
wallpaper = ,$HOME/.config/hypr/wallpapers/dark.png
EOF
ok "hyprpaper.conf generated for $USER."

# ── Media dirs & a stock wallpaper ────────────────────────────────
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/Pictures/Wallpapers"
safe_copy "$HOME/.config/hypr/wallpapers/dark.png" "$HOME/Pictures/Wallpapers/dark.png"
ok "Media directories ready."

# ── Enable system services ────────────────────────────────────────
info "Enabling services..."
sudo systemctl enable --now NetworkManager    2>/dev/null || warn "NetworkManager failed to start."
sudo systemctl enable --now bluetooth          2>/dev/null || warn "bluetooth failed to start."
sudo systemctl enable --now systemd-resolved   2>/dev/null || warn "systemd-resolved failed to start."
sudo systemctl enable --now power-profiles-daemon 2>/dev/null || warn "power-profiles-daemon failed to start."

systemctl --user enable --now pipewire.socket        >/dev/null 2>&1 || warn "pipewire.socket could not be enabled."
systemctl --user enable --now pipewire-pulse.socket  >/dev/null 2>&1 || warn "pipewire-pulse.socket could not be enabled."
systemctl --user enable --now wireplumber            >/dev/null 2>&1 || warn "wireplumber could not be enabled."
ok "Services enabled."

# ── Browser (best-effort: config uses flatpak run com.brave.Browser)
if ! flatpak info com.brave.Browser &>/dev/null; then
    info "Setting up Flatpak + Brave browser (best effort)..."
    flatpak remote-add --if-not-exists flathub "https://dl.flathub.org/repo/flathub.flatpakrepo" 2>/dev/null || true
    if flatpak install --noninteractive --assumeyes flathub com.brave.Browser; then
        ok "Brave installed via Flatpak."
    else
        warn "Brave could not be installed; install it later with 'flatpak install flathub com.brave.Browser'."
    fi
fi

# ── Bash as default shell ─────────────────────────────────────────
BASH="$(which bash 2>/dev/null || true)"
if [ -n "$BASH" ] && [ "$SHELL" != "$BASH" ]; then
    grep -qx "$BASH" /etc/shells 2>/dev/null || echo "$BASH" | sudo tee -a /etc/shells >/dev/null
    sudo chsh -s "$BASH" "$USER" 2>/dev/null || warn "Could not set bash as your default shell; run 'chsh -s $BASH' manually."
    info "Default shell set to bash. Log out & back in to apply."
fi

# ── Post-install notes ────────────────────────────────────────────
echo
ok "Everything installed."
echo
echo "$(color '→')  Restart Hyprland:   $(color 'SUPER + SHIFT + R')  or  $(color 'hyprctl reload')"
echo "$(color '→')  Caelestia shell:    autostarts on next login (or run $(color '~/.config/hypr/panel/caelestia-launch.sh'))"
echo "$(color '→')  Restart shell:      $(color 'CTRL + SUPER + ALT + R')  or reboot"
echo "$(color '→')  Caelestia scheme:   auto-generated from wallpaper on next login"
echo "$(color '→')  Wallpapers:         drop images in $(color '~/Pictures/Wallpapers')"
echo "$(color '→')  Build logs:         $(color "$CAELESTIA_SRC/build")"
echo
echo "$(color '!')  Reboot (or log out/in) to start Hyprland + pipewire + services."
echo "$(color '!')  No login manager was installed — start Hyprland from a TTY with: $(color 'Hyprland')"
echo "$(color '!')  (or install a login manager like $(color 'sddm') / $(color 'greetd'))"
echo