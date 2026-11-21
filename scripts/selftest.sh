#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
url="file://$(printf '%s' "$root/index.html" | sed 's/ /%20/g')?selftest"
browser=${BROWSER:-}
if [ -z "$browser" ]; then
  browser=$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || true)
fi
[ -n "$browser" ] || { echo "selftest: no Chrome/Chromium found" >&2; exit 2; }
out=$("$browser" --headless=new --disable-gpu --no-sandbox --virtual-time-budget=15000 --dump-dom "$url" 2>/dev/null || true)
line=$(printf '%s' "$out" | grep -oE 'selftest: (all [0-9]+ passed|[0-9]+ FAILED[^<]*)' | tail -1)
[ -n "$line" ] || { echo "selftest: no result (page did not run)" >&2; exit 2; }
echo "$line"
case "$line" in *passed) exit 0;; *) exit 1;; esac
