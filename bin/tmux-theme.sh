#### COLOUR

tm_color_active=colour41
tm_color_inactive=colour241
tm_color_feature=colour13
tm_active_border_color=colour198

# separators
tm_separator_left_bold="◀"
tm_separator_left_thin="❮"
tm_separator_right_bold="▶"
tm_separator_right_thin="❯"

set -g status-left-length 32
set -g status-right-length 200
set -g status-interval 5


# default statusbar colors
set-option -g status-style fg=$tm_color_active,bg=default

# default window title colors
set-window-option -g window-status-style fg=$tm_color_inactive,bg=default
set -g window-status-format "#I #W"

# active window title colors
set-window-option -g window-status-current-style fg=$tm_color_active,bg=default
set-window-option -g window-status-current-format "#[bold]#I #W"

# pane border
set-option -g pane-border-style fg=$tm_color_inactive
set-option -g pane-active-border-style fg=$tm_active_border_color

# message text
set-option -g message-style bg=default,fg=$tm_color_active

 # pane number display
set-option -g display-panes-active-colour $tm_color_active
set-option -g display-panes-colour $tm_color_inactive

 # clock
set-window-option -g clock-mode-colour $tm_color_active

# battery
tm_battery="#(~/.dotfiles/bin/battery-indicator.sh)"

# cpu + memory
tm_cpumem="#(~/.dotfiles/bin/cpu-mem-indicator.sh)"

# now playing (spotify / music)
tm_nowplaying="#(~/.dotfiles/bin/nowplaying-indicator.sh)"

# group separator: dim vertical bar with 1-space padding on each side
tm_sep="#[fg=$tm_color_inactive,nobold] │ "
tm_date="#[fg=$tm_color_inactive,nobold]%R %b %d"
tm_host="#[fg=$tm_color_feature,bold]#h"
tm_session_name="#[fg=$tm_color_feature,bold]#S"

set -g status-left ' '$tm_session_name' '
# order: ♫ music │ cpu/mem │ battery │ host │ clock  (clock anchored at the
# right edge; music emits its own trailing separator, so it cleanly vanishes
# when nothing is playing).
set -g status-right "$tm_nowplaying$tm_cpumem$tm_sep$tm_battery$tm_sep$tm_host$tm_sep$tm_date "
