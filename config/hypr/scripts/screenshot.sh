#!/bin/sh
mkdir -p /home/rigby/Pictures/Screenshots
file="/home/rigby/Pictures/Screenshots/$(date '+%Y-%m-%d_%H-%M-%S').png"
case "${1:-full}" in
    area) grim -l 1 -g "$(slurp)" "$file" ;;
    *)    grim -l 1 "$file" ;;
esac
