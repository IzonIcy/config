#!/bin/sh
# Launch the Playwright MCP against whatever Chromium build is installed.
#
# Why this exists: pointing the server at a fixed path such as
# chromium-1254/... breaks on the next Playwright upgrade, which writes a new
# chromium-<build> directory and leaves the old one missing or stale. Resolving
# the newest build at launch keeps one config working across upgrades.
set -eu

base="$HOME/Library/Caches/ms-playwright"

newest_build() {
  prefix="$1"
  best=0
  bestdir=""
  for d in "$base/$prefix"-[0-9]*; do
    [ -d "$d" ] || continue
    n=${d##*-}
    case "$n" in ''|*[!0-9]*) continue ;; esac
    if [ "$n" -gt "$best" ]; then
      best="$n"
      bestdir="$d"
    fi
  done
  printf '%s' "$bestdir"
}

find_bin() {
  dir=$(newest_build "$1")
  [ -n "$dir" ] || return 1
  for p in \
    "$dir/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" \
    "$dir/chrome-mac-x64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" \
    "$dir/chrome-mac/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" \
    "$dir/chrome-linux64/chrome" \
    "$dir/chrome-mac-arm64/headless_shell" \
    "$dir/chrome-mac/headless_shell"; do
    if [ -x "$p" ]; then
      printf '%s' "$p"
      return 0
    fi
  done
  return 1
}

bin=$(find_bin chromium || find_bin chromium_headless_shell || true)

if [ "${1:-}" = "--print-browser" ]; then
  [ -n "$bin" ] || { printf 'none\n'; exit 1; }
  printf '%s\n' "$bin"
  exit 0
fi

if [ -z "$bin" ]; then
  printf 'playwright-mcp.sh: no Playwright chromium under %s; run: bunx playwright install chromium\n' "$base" >&2
  exit 1
fi

exec bunx @playwright/mcp --executable-path "$bin" "$@"
