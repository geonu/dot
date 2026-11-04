#!/bin/bash
# Disk usage gauge for the tmux status bar (macOS / Linux):
#   DISK ▰▰▰▰▰▰▱▱▱▱ 61% 351G
# Ten cells fill with the used percentage of the volume holding user data; the
# trailing figure is the space still free. Filled cells and the percentage
# shift green -> orange -> red as the disk fills; below the 30 GiB floor that
# `git worktree-new` enforces they are always red.

# On macOS / is the sealed system snapshot; user data lives on the Data volume.
volume=/
[[ -d /System/Volumes/Data ]] && volume=/System/Volumes/Data

read -r used free_kib < <(df -kP "$volume" | awk 'NR == 2 { gsub("%", "", $5); print $5, $4 }')
[[ $used =~ ^[0-9]+$ && $free_kib =~ ^[0-9]+$ ]] || exit 0
free_gib=$((free_kib / 1048576))

if ((used >= 90 || free_gib < 30)); then
  color=colour196 # red
elif ((used >= 80)); then
  color=colour214 # orange
else
  color=colour41 # green
fi

filled=$(((used + 5) / 10))
((filled > 10)) && filled=10
gauge="#[fg=$color]"
for ((i = 0; i < 10; i++)); do
  ((i == filled)) && gauge+='#[fg=colour238]'
  if ((i < filled)); then gauge+='▰'; else gauge+='▱'; fi
done

printf '#[fg=colour13,bold]DISK#[nobold] %s#[fg=%s] %d%%#[fg=colour245] %dG' "$gauge" "$color" "$used" "$free_gib"
