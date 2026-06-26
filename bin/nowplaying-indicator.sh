#!/bin/bash
# Now-playing for the tmux status bar (macOS) -- a "reveal then settle" ticker.
#
# tmux can only re-run a #() status command once per status-interval (>= 1s),
# and forcing a faster redraw (refresh-client) makes the terminal cursor blink
# on every redraw. So a *continuous* smooth marquee = a continuously blinking
# cursor. The compromise: when a long title starts, scroll it ONCE so you can
# read all of it, then settle to a static head (first chars + "…") and stop
# redrawing -- the cursor goes steady until the song changes.
#
# It writes the styled segment into the @nowplaying user option; status-right
# just references #{@nowplaying}. The script is launched ONCE per server via
# run-shell -b and must NEVER be referenced via #() (it loops). An atomic mkdir
# lock makes duplicate/extra launches a no-op, so it can never storm.
# The slow AppleScript player query is cached + run in the background.

WIDTH=38          # visible window width, in display columns
STEP=1            # characters advanced per reveal tick
TICK=0.08         # seconds between ticks during the (brief) reveal scroll
PASSES=1          # how many full scroll passes to reveal a long title
IDLE=1.0          # seconds between polls once settled / idle (no redraw)
REFRESH=5         # seconds between background player re-queries
GAP='   •   '     # shown between the tail and the wrapped-around head

NPF="${TMPDIR:-/tmp}/tmux-nowplaying.track"   # cached "artist — track"
LOCKD="${TMPDIR:-/tmp}/tmux-nowplaying.lock"  # single-instance lock (atomic dir)

# --- single instance: an atomic mkdir lock. Only the first daemon wins; any
# extra invocation (a config reload, or a stray #() call) exits immediately, so
# it can never storm. A stale lock from a crashed daemon (dead pid) is taken
# over. NEVER reference this script via #() in the status line -- it loops. ---
if ! mkdir "$LOCKD" 2>/dev/null; then
  op=$(cat "$LOCKD/pid" 2>/dev/null)
  if [ -n "$op" ] && kill -0 "$op" 2>/dev/null; then exit 0; fi
  rm -rf "$LOCKD" 2>/dev/null
  mkdir "$LOCKD" 2>/dev/null || exit 0
fi
echo $$ >"$LOCKD/pid"
trap 'rm -rf "$LOCKD"' EXIT INT TERM

# Ask a Spotify-compatible app (Spotify / Music share the same dictionary).
query() { # $1 = app name
  osascript 2>/dev/null \
    -e "tell application \"$1\"" \
    -e 'if player state is playing then return (artist of current track) & " — " & (name of current track)' \
    -e 'end tell'
}

# Background refresher: query whichever player is running, write the (single-
# line) result to NPF atomically. Detached so the tick never waits on osascript.
refresh_track() {
  (
    t=""
    if pgrep -x Spotify >/dev/null 2>&1; then t=$(query Spotify); fi
    if [ -z "$t" ] && pgrep -x Music >/dev/null 2>&1; then t=$(query Music); fi
    t=$(printf '%s' "$t" | tr '\n\r\t' '   ')
    printf '%s' "$t" >"$NPF.$$" && mv -f "$NPF.$$" "$NPF"
  ) >/dev/null 2>&1 &
}

# Per-char display width (2 for CJK / fullwidth / emoji) shared by both helpers.
CW_PERL='
  use Encode qw(decode_utf8);
  sub cw {
    my $c = ord $_[0];
    return 2 if ($c>=0x1100&&$c<=0x115F)||($c>=0x2E80&&$c<=0x303E)
             ||($c>=0x3041&&$c<=0x33FF)||($c>=0x3400&&$c<=0x4DBF)
             ||($c>=0x4E00&&$c<=0x9FFF)||($c>=0xA000&&$c<=0xA4CF)
             ||($c>=0xAC00&&$c<=0xD7A3)||($c>=0xF900&&$c<=0xFAFF)
             ||($c>=0xFE30&&$c<=0xFE4F)||($c>=0xFF00&&$c<=0xFF60)
             ||($c>=0xFFE0&&$c<=0xFFE6)||($c>=0x1F300&&$c<=0x1FAFF)
             ||($c>=0x20000&&$c<=0x3FFFD);
    return 1;
  }
  my $s = do { local $/; <STDIN> }; $s = "" unless defined $s;
  $s =~ s/\s+/ /g; $s =~ s/^ //; $s =~ s/ $//;
'

# meta: decide scroll vs fit. Emits "scroll<TAB>L<TAB>headline".
#   scroll   = 1 if the title is wider than WIDTH.
#   L        = base length in codepoints (title + gap) = one full scroll pass.
#   headline = the static settled view: whole title if it fits, else the first
#              WIDTH-1 columns + "…". (# escaped so tmux keeps it literal.)
meta() {
  printf '%s' "$1" | WIDTH=$WIDTH GAP="$GAP" perl -CS -e "$CW_PERL"'
    my $W = ($ENV{WIDTH} // 38) + 0;
    my @ch = split //, $s;
    my $tot = 0; $tot += cw($_) for @ch;
    if ($tot <= $W) { (my $h = $s) =~ s/#/##/g; print "0\t0\t$h"; exit; }
    my $L = scalar(@ch) + scalar(split //, decode_utf8($ENV{GAP} // "   "));
    my ($cols, $out) = (0, "");
    for my $c (@ch) { my $w = cw($c); last if $cols + $w > $W - 1; $out .= $c; $cols += $w; }
    $out .= "…"; $out =~ s/#/##/g;
    print "1\t$L\t$out";
  '
}

# frame: one marquee frame while revealing. Emits "nextoffset<TAB>window".
frame() { # $1 = text, $2 = offset
  printf '%s' "$1" | WIDTH=$WIDTH STEP=$STEP OFFSET=$2 GAP="$GAP" perl -CS -e "$CW_PERL"'
    my $W = ($ENV{WIDTH} // 38) + 0;
    my @base = (split(//, $s), split(//, decode_utf8($ENV{GAP} // "   ")));
    my $L = scalar @base; $L = 1 if $L < 1;
    my $o = ($ENV{OFFSET} // 0) % $L;
    my ($cols, $i, $out) = (0, 0, "");
    while ($i <= 4 * $L) {
      my $cch = $base[($o + $i) % $L];
      my $w = cw($cch);
      last if $cols + $w > $W;
      $out .= $cch; $cols += $w; $i++;
    }
    $out .= " " x ($W - $cols);
    my $next = ($o + ($ENV{STEP} // 1)) % $L;
    $out =~ s/#/##/g;
    print "$next\t$out";
  '
}

chrome() { # wrap the inner text in ♫ ... + trailing separator
  printf '#[fg=colour13,bold]♫#[fg=colour250,nobold] %s#[fg=colour241,nobold] │ ' "$1"
}

# Publish a segment and force ONE status redraw on every client. Returns
# non-zero when the server is gone (-> the loop exits).
emit() { # $1 = segment
  local clients c
  clients=$(tmux list-clients -F '#{client_name}' 2>/dev/null) || return 1
  tmux set -g @nowplaying "$1" 2>/dev/null || return 1
  while IFS= read -r c; do
    [ -n "$c" ] && tmux refresh-client -S -t "$c" 2>/dev/null
  done <<<"$clients"
  return 0
}

prevnp="__omp_init__"; mode="settled"; offset=0; steps=0; last_query=0

while :; do
  now=$(date +%s)
  if [ $(( now - last_query )) -ge "$REFRESH" ]; then last_query=$now; refresh_track; fi

  np=""
  [ -r "$NPF" ] && np=$(cat "$NPF")

  if [ "$np" != "$prevnp" ]; then
    # --- song changed: nothing -> empty; short -> settle; long -> reveal ---
    prevnp=$np; offset=0
    if [ -z "$np" ]; then
      mode="settled"
      emit "" || break
    else
      m=$(meta "$np"); m_scroll=${m%%$'\t'*}; m_rest=${m#*$'\t'}
      m_L=${m_rest%%$'\t'*}; m_head=${m_rest#*$'\t'}
      if [ "$m_scroll" = 1 ]; then
        mode="reveal"; steps=$(( m_L * PASSES ))
        f=$(frame "$np" "$offset"); offset=${f%%$'\t'*}; window=${f#*$'\t'}
        steps=$(( steps - STEP ))
        emit "$(chrome "$window")" || break
      else
        mode="settled"
        emit "$(chrome "$m_head")" || break
      fi
    fi
  elif [ "$mode" = reveal ]; then
    # --- mid-reveal: advance one frame; settle after a full pass ---
    f=$(frame "$np" "$offset"); offset=${f%%$'\t'*}; window=${f#*$'\t'}
    emit "$(chrome "$window")" || break
    steps=$(( steps - STEP ))
    if [ "$steps" -le 0 ]; then
      mode="settled"
      m=$(meta "$np"); m_head=${m##*$'\t'}
      emit "$(chrome "$m_head")" || break   # one final redraw, then steady
    fi
  fi
  # settled: no emit, no refresh -> cursor stays steady.

  if [ "$mode" = reveal ]; then sleep "$TICK"; else sleep "$IDLE"; fi
done
