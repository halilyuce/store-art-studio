#!/usr/bin/env bash
# Renders phone slots with headless Chrome: out/<locale>/<NN>.png, 1080 x 1920, opaque.
#
#   tools/render.sh en-US            every slot in SLOTS (default: 1)
#   tools/render.sh ar 1 3           slots 1 and 3
#   CHROME=/path/to/chrome tools/render.sh en-US
#
# Needs Google Chrome. Chrome's screenshots came out opaque on macOS; if one ever carries an alpha
# channel, it is flattened with ImageMagick when present, and scripts/verify-export.sh catches it
# before upload either way.
set -euo pipefail
cd "$(dirname "$0")/.."
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
L="${1:-en-US}"; shift || true
slots=("$@"); (( ${#slots[@]} )) || read -r -a slots <<< "${SLOTS:-1}"
mkdir -p "out/$L"
flatten() {
  if sips -g hasAlpha "$1" 2>/dev/null | grep -q 'hasAlpha: yes'; then
    if command -v magick >/dev/null; then magick "$1" -background white -alpha remove -alpha off "$1"
    else echo "ALPHA  $1 has an alpha channel and magick is not installed"; fi
  fi
}
for s in "${slots[@]}"; do
  n=$(printf %02d "$s")
  # --virtual-time-budget lets web fonts and images load before the shot; scale factor 1 keeps 1080 x 1920.
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --allow-file-access-from-files \
    --virtual-time-budget=6000 --window-size=1080,1920 --screenshot="$PWD/out/$L/$n.png" \
    "file://$PWD/slots.html?l=$L&s=$s" 2>/dev/null
  flatten "out/$L/$n.png"
  echo "out/$L/$n.png"
done
