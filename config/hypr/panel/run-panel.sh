#!/usr/bin/env sh

env QML_XHR_ALLOW_FILE_READ=1 \
    QT_QPA_PLATFORM=wayland \
    /home/rigby/.local/bin/quickshell.AppImage \
    --path /home/rigby/.config/hypr/panel/hover-panel.qml
