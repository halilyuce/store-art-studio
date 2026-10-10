#!/usr/bin/env bash
# Fails when any headline line is too wide, in any locale. Never shrink the type: rewrite the line.
#
#   tools/widthtest.sh                 every locale in copy.js, slots in SLOTS (default: 1)
#   SLOTS="1 2 3" tools/widthtest.sh ar
#
# slots.html measures each headline line after the fonts load and writes "WIDTH OK" or
# "OVERFLOW line<n>=<px>px" into document.title; this reads it back with --dump-dom.
set -euo pipefail
cd "$(dirname "$0")/.."
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
locales=("$@")
(( ${#locales[@]} )) || read -r -a locales <<< "$(grep -oE '^  "[a-zA-Z-]+": \{' copy.js | tr -d ' ":{' | tr '\n' ' ')"
read -r -a slots <<< "${SLOTS:-1}"
fail=0
for L in "${locales[@]}"; do
  for s in "${slots[@]}"; do
    t=$("$CHROME" --headless=new --disable-gpu --allow-file-access-from-files --virtual-time-budget=6000 --window-size=1080,1920 \
      --dump-dom "file://$PWD/slots.html?l=$L&s=$s" 2>/dev/null | grep -o '<title>[^<]*</title>' | sed 's/<[^>]*>//g' || true)
    [[ "$t" == "WIDTH OK" ]] || { echo "$L slot $s: ${t:-no result}"; fail=1; }
  done
done
(( fail )) && exit 1
echo "width test: all headlines fit (${locales[*]})"
