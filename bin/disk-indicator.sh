#!/bin/bash
# Disk usage for the tmux status bar (macOS / Linux):
#   DISK 63% 352G
# Used percentage of the volume holding user data, then the space still free.
# Color shifts green -> orange -> red as the disk fills; below the 30 GiB
# floor that `git worktree-new` enforces it is always red.

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

printf '#[fg=colour13,bold]DISK#[fg=%s,nobold] %d%% %dG' "$color" "$used" "$free_gib"
