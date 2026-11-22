#!/bin/sh
# Every required § anchor exists exactly once and is named in the feature map.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
file=$root/index.html
map=$root/docs/FEATURE-MAP.md
bad=0

for a in CONFIG STATE GRID PHYSICS RENDER INPUT PALETTE "PALETTE: DRAWER" \
         CONTROLS PRESENTATION AUTOPILOT PERSISTENCE SCENES WEATHER AUDIO \
         MUSIC HELP CHRONICLE GOALS LOOP SELFTEST API BOOT \
         "TEST: MATERIAL REGISTRY" "TEST: PHYSICS" "TEST: ECOLOGY" "TEST: WEATHER" "TEST: PEOPLE & HERDS" \
         "TEST: AUDIO" "TEST: PERSISTENCE & SECURITY" "TEST: SCENES" \
         "TEST: UI & INPUT" "TEST: STATE RESTORE" "TEST: RESET & VALIDATION"; do
  if ! grep -qF "// § $a" "$file"; then
    echo "missing anchor: // § $a" >&2
    bad=1
  fi
  if ! grep -qF "$a" "$map"; then
    echo "feature map does not mention: $a" >&2
    bad=1
  fi
done

dup=$(grep '^// §' "$file" | sed 's/ —.*//' | sort | uniq -d)
if [ -n "$dup" ]; then
  echo "duplicate anchors:" >&2
  printf '%s\n' "$dup" >&2
  bad=1
fi

[ "$bad" -eq 0 ] || exit 1
echo "map: $(grep -c '^// §' "$file") anchors, all unique and documented"
