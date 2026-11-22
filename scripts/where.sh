#!/bin/sh
# Find a feature by name: the map, section anchors, symbols, DOM ids and tests.
# usage: sh scripts/where.sh <word>
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
term=${1:?usage: sh scripts/where.sh <word>}
up=$(printf '%s' "$term" | tr '[:lower:]' '[:upper:]')

echo "== feature map =="
grep -in -- "$term" "$root/docs/FEATURE-MAP.md" || true

echo "== sections =="
grep -n '^// §' "$root/index.html" | grep -i -- "$term" || true

echo "== symbols =="
grep -nE "(function|const|let) [A-Za-z0-9_]*${term}|id=\"[^\"]*${term}|\[${up}\]" "$root/index.html" | head -30 || true

echo "== tests =="
grep -n -i "ok('[^']*${term}" "$root/index.html" | head -20 || true
