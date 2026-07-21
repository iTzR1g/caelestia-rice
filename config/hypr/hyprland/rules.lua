local vars = require("variables")

-- Workspace assignments (matching i3 config)

-- Browsers → ws2
hl.window_rule({ match = { class = "firefox" }, workspace = "2" })
hl.window_rule({ match = { class = "Chromium" }, workspace = "2" })
hl.window_rule({ match = { class = "brave" }, workspace = "2" })
hl.window_rule({ match = { class = "com.brave.Browser" }, workspace = "2" })

-- Code editors → ws3
hl.window_rule({ match = { class = "Code" }, workspace = "3" })
hl.window_rule({ match = { class = "code-oss" }, workspace = "3" })
hl.window_rule({ match = { class = "jetbrains-idea" }, workspace = "3" })
hl.window_rule({ match = { class = "jetbrains-toolbox" }, workspace = "3" })

-- Media → ws4
hl.window_rule({ match = { class = "Spotify" }, workspace = "4" })
hl.window_rule({ match = { class = "vlc" }, workspace = "4" })

-- File managers → ws5
hl.window_rule({ match = { class = "org.gnome.Nautilus" }, workspace = "5" })
hl.window_rule({ match = { class = "Thunar" }, workspace = "5" })
hl.window_rule({ match = { class = "dolphin" }, workspace = "5" })

-- Floating applications
hl.window_rule({ match = { class = "guifetch|yad|zenity|wev|org.gnome.FileRoller|file-roller|blueman-manager|feh|imv|system-config-printer|org.quickshell" }, tag = "+float" })
hl.window_rule({ match = { title = "(Select|Open)( a)? (File|Folder)(s)?|File (Operation|Upload)( Progress)?|.* Properties|Export Image as PNG|GIMP Crash Debug|Save As|Library" }, tag = "+float" })
hl.window_rule({ match = { class = "steam", title = "Friends List" }, tag = "+float" })
hl.window_rule({ match = { tag = "float" }, float = true })

-- Opaque apps
hl.window_rule({ match = { class = "kitty|imv|swappy|krita|gimp|steam|gamescope" }, tag = "+opaque" })
hl.window_rule({ match = { tag = "opaque" }, opaque = true })

-- Games
hl.window_rule({ match = { class = "(steam_app_[0-9]+)|gamescope" }, immediate = true, idle_inhibit = "always" })

-- Steam
hl.window_rule({ match = { class = "steam" }, rounding = 10 })

-- Picture-in-picture
hl.window_rule({ match = { title = "Picture(-| )in(-| )[Pp]icture" }, move = "(monitor_w*0.98-window_w) (monitor_h*0.97-window_h)", pin = true, float = true })

-- XWayland popups
hl.window_rule({ match = { xwayland = true, title = "win[0-9]+" }, tag = "+xwl_popup" })
hl.window_rule({ match = { xwayland = true, title = "", class = "", initial_title = "", initial_class = "" }, tag = "+xwl_popup" })
hl.window_rule({ match = { tag = "xwl_popup" }, no_dim = true, no_shadow = true, no_blur = true, opaque = true, rounding = 10 })

-- Workspace rules
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = vars.singleWindowGapsOut })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = vars.singleWindowGapsOut })

-- Layer rules
hl.layer_rule({ match = { namespace = "hyprpicker" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "selection" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "wayfreeze" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "launcher" }, animation = "popin 80%", blur = true })
