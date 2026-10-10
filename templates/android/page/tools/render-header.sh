#!/usr/bin/env bash
# Renders the Play feature graphic: out/<locale>/feature-graphic.png, 1024 x 500, opaque.
#
#   tools/render-header.sh en-US
#
# Authored at 2048 x 1000 and downsampled, because a 1x render gives soft type. Needs Google
# Chrome; downsamples with ImageMagick when present, otherwise with macOS sips.
set -euo pipefail
cd "$(dirname "$0")/.."
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
L="${1:-en-US}"
mkdir -p "out/$L"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --allow-file-access-from-files \
  --virtual-time-budget=6000 --window-size=2048,1000 --screenshot="$PWD/out/$L/feature-graphic@2x.png" \
  "file://$PWD/header.html?l=$L" 2>/dev/null
if command -v magick >/dev/null; then
  magick "out/$L/feature-graphic@2x.png" -resize 1024x500! -background white -alpha remove -alpha off "out/$L/feature-graphic.png"
else
  sips -z 500 1024 "out/$L/feature-graphic@2x.png" --out "out/$L/feature-graphic.png" >/dev/null
fi
rm "out/$L/feature-graphic@2x.png"
echo "out/$L/feature-graphic.png"
