#!/bin/sh
state=$(cat /tmp/hypr-gamemode 2>/dev/null || echo "off")
if [ "$state" = "on" ]; then
    echo "off" > /tmp/hypr-gamemode
    hyprctl reload
    notify-send -t 1500 "Game Mode" "OFF"
else
    echo "on" > /tmp/hypr-gamemode
    hyprctl keyword animations:enabled 0
    hyprctl keyword decoration:shadow:enabled 0
    hyprctl keyword decoration:blur:enabled 0
    hyprctl keyword decoration:active_opacity 1
    hyprctl keyword decoration:inactive_opacity 1
    hyprctl keyword general:gaps_in 0
    hyprctl keyword general:gaps_out 0
    hyprctl keyword general:border_size 1
    hyprctl keyword decoration:rounding 0
    hyprctl keyword general:allow_tearing 1
    notify-send -t 1500 "Game Mode" "ON"
fi
