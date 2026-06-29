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

# "agent needs you" indicators, raised by the omp tmux-attention extension
# (omp/extensions/tmux-attention.ts) on turn_end:
#   @omp_attn_win (window option) -> a dot here in the window-status list, the
#     cross-window "which window needs me" glance.
#   @omp_attn_pane (pane option) -> a dot on the pane border (see tmux.conf),
#     pinpointing which agent in a multi-pane window is waiting.
# Both clear via the select hooks below the moment you engage. Style attributes
# are SPACE-separated on purpose: a comma inside #[...] would be read as the
# #{?...} branch separator and split the conditional.
tm_attn="#{?@omp_attn_win,#[fg=$tm_active_border_color bold]●#[fg=$tm_color_inactive nobold] ,}"

# default window title colors
set-window-option -g window-status-style fg=$tm_color_inactive,bg=default
set -g window-status-format "$tm_attn#I #W"

# active window title colors
set-window-option -g window-status-current-style fg=$tm_color_active,bg=default
set-window-option -g window-status-current-format "$tm_attn#[fg=$tm_color_active bold]#I #W"

# Clear the flags the instant you engage, so a dot only ever marks an unseen,
# waiting agent: drop the window flag when you enter the window, the pane flag
# when you focus the pane. -g (not -ga) keeps this idempotent across reloads.
set-hook -g after-select-window "set-option -uw @omp_attn_win"
set-hook -g after-select-pane   "set-option -up @omp_attn_pane"

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

# now playing (spotify / music): a background ticker scrolls long titles and
# publishes the styled segment into @nowplaying (see bin/nowplaying-indicator.sh).
# Launched once per server; it self-guards against duplicates on config reload.
set -gq @nowplaying ''
run-shell -b '~/.dotfiles/bin/nowplaying-indicator.sh'
tm_nowplaying="#{@nowplaying}"

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
