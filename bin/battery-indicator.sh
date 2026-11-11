#!/bin/bash
# Optional tmux segment: own the leading separator so desktops leave no gap.

percent=
state=
power=
case $(uname -s) in
  Darwin)
    pattern='([0-9]+)%;[[:space:]]*([^;]+)'
    while IFS= read -r line; do
      [[ $line == *"'AC Power'"* ]] && power=AC
      if [[ $line == *InternalBattery* && $line =~ $pattern ]]; then
        percent=${BASH_REMATCH[1]}
        state=${BASH_REMATCH[2]}
        break
      fi
    done < <(pmset -g batt 2>/dev/null)
    ;;
  Linux)
    for battery in /sys/class/power_supply/*; do
      [[ -r $battery/type && -r $battery/capacity && -r $battery/status ]] || continue
      IFS= read -r type < "$battery/type"
      [[ $type == Battery ]] || continue
      IFS= read -r percent < "$battery/capacity"
      IFS= read -r state < "$battery/status"
      break
    done
    ;;
esac

[[ $percent =~ ^[0-9]{1,3}$ ]] || exit 0
percent=$((10#$percent))
((percent <= 100)) || exit 0

printf '#[fg=colour241,nobold] │ #[fg=colour196]'
if ((percent == 100)) && [[ $state != discharging && $state != Discharging ]] &&
   [[ $power == AC || $state == Full || $state == Charging || $state == "Not charging" ]]; then
  printf '∞'
  exit 0
fi

# Keep the original three-heart gauge and its fill thresholds.
filled=$((percent / 30 + 1))
((filled > 3)) && filled=3
for ((i = 0; i < 3; i++)); do
  ((i == filled)) && printf '#[fg=colour254]'
  printf '♥ '
done
