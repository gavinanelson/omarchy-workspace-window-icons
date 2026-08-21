#!/usr/bin/env bash
set -euo pipefail

app_id="${1:-}"
[[ $app_id =~ ^[0-9]+$ ]] || exit 0

roots=(
  "${XDG_DATA_HOME:-$HOME/.local/share}/Steam"
  "$HOME/.steam/steam"
  "$HOME/.var/app/com.valvesoftware.Steam/data/Steam"
)

for root in "${roots[@]}"; do
  cache="$root/appcache/librarycache/$app_id"
  [[ -d $cache ]] || continue

  while IFS= read -r icon; do
    name="${icon##*/}"
    if [[ $name =~ ^[[:xdigit:]]{40}\.(jpg|png)$ ]]; then
      printf '%s\n' "$icon"
      exit 0
    fi
  done < <(find "$cache" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' \) -print 2>/dev/null | sort)
done
