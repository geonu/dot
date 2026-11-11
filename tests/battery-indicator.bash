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
check 'original heart gauge remains' ' │ ♥ ♥ ♥ '
record 'AC Power' '100%' charged
check 'full battery on AC shows infinity' ' │ ∞'
record 'AC Power' '100%' charging
check '100 percent while charging shows infinity' ' │ ∞'
record 'AC Power' '99%' charging
check 'not yet full keeps hearts' ' │ ♥ ♥ ♥ '
record 'Battery Power' '100%' discharging
check 'unplugged full battery keeps hearts' ' │ ♥ ♥ ♥ '
record 'AC Power' '100%' discharging
check 'discharging on AC does not imply unlimited power' ' │ ♥ ♥ ♥ '
record 'Battery Power' '0%' discharging
check 'original empty-battery gauge remains visible' ' │ ♥ ♥ ♥ '
record 'AC Power' '(no estimate)' charging
check 'missing capacity does not invent a percentage' ''
record 'AC Power' '101%' charging
check 'invalid capacity does not render' ''
: > "$BATTERY_FIXTURE"
export PMSET_EXIT=1
check 'failed power query hides segment' ''
