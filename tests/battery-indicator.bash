#!/bin/bash
# Exercise macOS power records without depending on this machine's battery.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin"
printf '#!/bin/bash\nprintf "Darwin\\n"\n' > "$tmp/bin/uname"
printf '#!/bin/bash\ncat "$BATTERY_FIXTURE"\nexit "${PMSET_EXIT:-0}"\n' > "$tmp/bin/pmset"
chmod +x "$tmp/bin/uname" "$tmp/bin/pmset"
export PATH="$tmp/bin:$PATH" BATTERY_FIXTURE="$tmp/power"

check() {
  local name=$1 expected=$2 actual style='\#\[[^]]*\]'
  actual=$(bash "$root/bin/battery-indicator.sh")
  while [[ $actual =~ $style ]]; do
    actual=${actual/"${BASH_REMATCH[0]}"/}
  done
  if [[ $actual != "$expected" ]]; then
    printf 'FAIL %s: expected <%s>, got <%s>\n' "$name" "$expected" "$actual" >&2
    exit 1
  fi
  printf 'ok: %s\n' "$name"
}

record() {
  printf "Now drawing from '%s'\n -InternalBattery-0 (id=123)\t%s; %s; %s\n" "$1" "$2" "$3" "${4:-present: true}" > "$BATTERY_FIXTURE"
}

printf "Now drawing from 'AC Power'\n" > "$BATTERY_FIXTURE"
check 'desktop without battery hides entire segment' ''
record 'Battery Power' '62%' discharging
check 'battery power shows remaining charge' ' │ BAT 62%'
record 'AC Power' '62%' charging
check 'charging differs from battery power' ' │ CHG 62%'
record 'AC Power' '100%' charged
check 'full charge differs from charging' ' │ FULL 100%'
record 'AC Power' '80%' 'not charging'
check 'charge limit or paused charging stays explicit' ' │ AC 80%'
record 'AC Power' '99%' 'finishing charge'
check 'finishing charge is still charging' ' │ CHG 99%'
record 'AC Power' '42%' discharging
check 'discharging on an underpowered adapter is not called charging' ' │ BAT 42%'
record 'Battery Power' '100%' discharging
check 'full capacity on battery power is not called plugged in' ' │ BAT 100%'
record 'Battery Power' '0%' discharging
check 'empty battery remains visible' ' │ BAT 0%'
record 'AC Power' '(no estimate)' charging
check 'missing capacity does not invent a percentage' ''
record 'AC Power' '101%' charging
check 'invalid capacity does not render' ''
: > "$BATTERY_FIXTURE"
export PMSET_EXIT=1
check 'failed power query hides segment' ''
