#!/usr/bin/env bash
# hyprquickpaper-lite: cycle to the next wallpaper in ~/Pictures (Super+Alt+W)
set -euo pipefail
PICS_DIR="$HOME/Pictures"
STATE_DIR="$HOME/Library/Application Support/aerospace"
STATE_FILE="$STATE_DIR/wallpaper-index"

WALLS=()
while IFS= read -r f; do
  WALLS+=("$f")
done < <(find "$PICS_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.heic' \) | sort)

N=${#WALLS[@]}
if [[ $N -eq 0 ]]; then
  echo "no wallpapers in $PICS_DIR" >&2
  exit 1
fi

IDX=0
[[ -f "$STATE_FILE" ]] && IDX=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
[[ "$IDX" =~ ^[0-9]+$ ]] || IDX=0
IDX=$(( (IDX + 1) % N ))
mkdir -p "$STATE_DIR"
printf '%s' "$IDX" > "$STATE_FILE"

osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"${WALLS[$IDX]}\"" >/dev/null 2>&1 || true
