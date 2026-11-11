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

case $state in
  charged|Full) label=FULL ;;
  charging|Charging|"finishing charge") label=CHG ;;
  discharging|Discharging) label=BAT ;;
  "not charging"|"Not charging") label=AC ;;
  *) label=${power:-BAT} ;;
esac

color=colour41
if [[ $label == BAT ]]; then
  if ((percent <= 20)); then
    color=colour196
  elif ((percent <= 40)); then
    color=colour214
  fi
fi
printf '#[fg=colour241,nobold] │ #[fg=colour13,bold]%s#[fg=%s,nobold] %d%%' "$label" "$color" "$percent"
