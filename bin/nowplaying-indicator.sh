#!/bin/bash
# Now-playing indicator for the tmux status bar (macOS).
# Shows "♫ artist — track" only while a player is actively playing; prints
# nothing otherwise so the status bar segment collapses. Queries Spotify /
# Music via AppleScript, guarded by pgrep so a stopped app is never launched.
# macOS >= 15.4 locks the system-wide MediaRemote API, so we go per-app.
# tmux runs #() async, so AppleScript's slow first call never blocks redraw.

MAXLEN=38   # max characters before truncation (keeps status-right bounded)

# Ask a Spotify-compatible app (Spotify / Music share the same dictionary).
query() { # $1 = app name
  osascript 2>/dev/null \
    -e "tell application \"$1\"" \
    -e 'if player state is playing then return (artist of current track) & " — " & (name of current track)' \
    -e 'end tell'
}

np=""
if pgrep -x Spotify >/dev/null 2>&1; then
  np=$(query Spotify)
fi
if [ -z "$np" ] && pgrep -x Music >/dev/null 2>&1; then
  np=$(query Music)
fi

[ -z "$np" ] && exit 0   # nothing playing -> empty segment

# UTF-8-safe truncation with an ellipsis (perl is always present on macOS).
np=$(printf '%s' "$np" | MAXLEN=$MAXLEN perl -CS -ne '
  chomp; s/\s+/ /g; my $m = $ENV{MAXLEN};
  print length() > $m ? substr($_, 0, $m - 1) . "…" : $_')

# Emit the music segment plus its own trailing separator, so an idle player
# leaves no orphaned "│" at the head of status-right.
printf '#[fg=colour13,bold]♫#[fg=colour250,nobold] %s#[fg=colour241,nobold] │ ' "$np"
