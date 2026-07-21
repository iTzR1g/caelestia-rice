#!/bin/sh
for i in 1 2 3; do
    hyprctl keyword input:touchpad:tap-to-click false 2>/dev/null && exit 0
    sleep 1
done
exit 1
