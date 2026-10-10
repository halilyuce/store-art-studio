#!/usr/bin/env bash
# Renders phone slots with headless Chrome: out/<locale>/<NN>.png, 1080 x 1920, opaque.
#
#   tools/render.sh                  the default market's locale, every slot in SLOTS (default: 1 2)
#   tools/render.sh ar 1             one locale, slot 1
#   VARIANT=straight tools/render.sh en-US 1
#                                    an alternate version of a slot: out/<locale>/01-straight.png
#                                    (slots.html reads &variant=<name>; any name a layout handles)
#
# Locales are storeLocale values from storeart.config.json. Chrome's screenshots came out opaque on
# macOS; if one ever carries an alpha channel it is flattened with ImageMagick when present, and
# scripts/verify-export.sh catches it before upload either way.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/markets.sh
L="${1:-$(default_locale)}"; shift || true
slots=("$@"); (( ${#slots[@]} )) || read -r -a slots <<< "${SLOTS:-1 2}"
mkdir -p "out/$L"
for s in "${slots[@]}"; do
  n=$(printf %02d "$s"); extra=""; suffix=""
  [[ -n "${VARIANT:-}" ]] && { extra="&variant=$VARIANT"; suffix="-$VARIANT"; }
  # --virtual-time-budget lets the config, web fonts and images load before the shot.
  "$CHROME" "${CHROME_FLAGS[@]}" --window-size=1080,1920 --screenshot="$PWD/out/$L/$n$suffix.png" \
    "file://$PWD/slots.html?l=$L&s=$s$extra" 2>/dev/null
  flatten "out/$L/$n$suffix.png"
  echo "out/$L/$n$suffix.png"
done
