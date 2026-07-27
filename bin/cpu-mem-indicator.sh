#!/bin/bash
# CPU + memory sparkline for the tmux status bar (macOS / Linux).
# Renders a trend graph from recent samples instead of a bare number:
#   CPU ▂▃▅▇█ 39%   MEM ▃▃▄▄▄ 36%
# Each bar's height encodes that sample's %, and its color shifts
# green -> orange -> red with load. History is kept in a tmp file so the
# graph scrolls over time. Sampling uses `sysctl` load average for CPU and
# `memory_pressure` for MEM, avoiding `top -l 1` (~1.1s system time per
# status refresh).

HIST="${TMPDIR:-/tmp}/tmux-cpumem-history"
SAMPLES=8   # bars shown = window of SAMPLES * status-interval seconds

# Color for an integer percentage.
color_for() {
  if   [ "$1" -ge 85 ]; then echo 'colour196'   # red
  elif [ "$1" -ge 60 ]; then echo 'colour214'   # orange
  else                       echo 'colour41'    # green
  fi
}

# Sparkline: one colored block per value, height = value / 100.
spark() {
  local ticks=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █) out="" v idx
  for v in "$@"; do
    idx=$(( v * 7 / 100 ))
    (( idx < 0 )) && idx=0
    (( idx > 7 )) && idx=7
    out+="#[fg=$(color_for "$v")]${ticks[$idx]}"
  done
  printf '%s' "$out"
}

if [[ "$(uname)" == 'Darwin' ]]; then
  # CPU%: 1-min load average over cores (instant sysctl), clamped to 100. A
  # load-based pressure gauge -- more representative of "is the box busy" than a
  # ps snapshot, and ~1000x cheaper than the old `top -l 1` (~1.1s of sys/tick).
  ncpu=$(sysctl -n hw.ncpu)
  cpu=$(sysctl -n vm.loadavg | awk -v n="${ncpu:-1}" '{ c=($2/n)*100; if(c>100)c=100; printf "%d", c }')
  mem_free=$(memory_pressure | awk '/free percentage/ {gsub("%","",$NF); print $NF}')
  mem=$((100 - ${mem_free:-100}))
else
  read -r _ u1 n1 s1 i1 w1 _ < /proc/stat
  t1=$((u1 + n1 + s1 + i1 + w1)); idle1=$((i1 + w1))
  sleep 0.2
  read -r _ u2 n2 s2 i2 w2 _ < /proc/stat
  t2=$((u2 + n2 + s2 + i2 + w2)); idle2=$((i2 + w2))
  dt=$((t2 - t1)); didle=$((idle2 - idle1))
  cpu=$(( dt > 0 ? (100 * (dt - didle)) / dt : 0 ))
  mem=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END { printf "%d", (t - a) * 100 / t }' /proc/meminfo)
fi

# Append current sample, keep the last SAMPLES rows.
echo "$cpu $mem" >> "$HIST" 2>/dev/null
tail -n "$SAMPLES" "$HIST" 2>/dev/null > "$HIST.tmp" && mv "$HIST.tmp" "$HIST" 2>/dev/null

cpus=() mems=()
while read -r c m; do
  [[ "$c" =~ ^[0-9]+$ ]] && cpus+=("$c")
  [[ "$m" =~ ^[0-9]+$ ]] && mems+=("$m")
done < "$HIST"
# Fall back to the live sample if history is somehow empty.
[ ${#cpus[@]} -eq 0 ] && cpus=("$cpu")
[ ${#mems[@]} -eq 0 ] && mems=("$mem")

printf '#[fg=colour13,bold]CPU#[nobold] %s#[fg=%s,nobold] %d%%#[fg=colour13,bold]  MEM#[nobold] %s#[fg=%s,nobold] %d%%' \
  "$(spark "${cpus[@]}")" "$(color_for "$cpu")" "$cpu" \
  "$(spark "${mems[@]}")" "$(color_for "$mem")" "$mem"
