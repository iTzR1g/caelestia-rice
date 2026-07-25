#!/bin/sh
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date '+%Y-%m-%d_%H-%M-%S').png"

case "${1:-full}" in
    area)
        grim -g "$(slurp)" "$file"
        ;;
    focused)
        grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$file"
        ;;
    *)
        grim "$file"
        ;;
esac

[ -f "$file" ] || exit 1

# Copy to clipboard if wl-copy is available
command -v wl-copy >/dev/null 2>&1 && wl-copy < "$file"

# Notify
command -v notify-send >/dev/null 2>&1 && notify-send -a "Screenshot" -i "$file" "Screenshot saved" "$(basename "$file")"
