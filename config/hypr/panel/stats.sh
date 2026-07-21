#!/usr/bin/env sh

STATS_FILE="/tmp/hypr-panel-stats.txt"

while true; do
    CPU=$(ps -eo %cpu --no-headers 2>/dev/null | awk '{s+=$1} END {printf "%.0f", s}')
    [ -z "$CPU" ] && CPU=0
    MEM=$(free -h | awk '/^Mem:/ {print $3"/"$2}')
    NOW=$(playerctl metadata --format "{{ artist }} - {{ title }}" 2>/dev/null || echo "Nothing playing")
    DATE=$(date '+%A, %d %B %Y')
    WEEK=$(date '+%V')

    printf "CPU=%s\nRAM=%s\nNOW=%s\nDATE=%s\nWEEK=%s\n" \
        "$CPU" "${MEM:-0}" "$NOW" "$DATE" "$WEEK" > "$STATS_FILE"

    sleep 2
done
