#!/usr/bin/env bash
# Fails when any headline line is too wide, in any locale. Never shrink the type: rewrite the line.
#
#   tools/widthtest.sh                 every market's locale in storeart.config.json, slots in SLOTS (default: 1 2)
#   SLOTS="1 3" tools/widthtest.sh ar  some locales and slots
#   tools/widthtest.sh --negative      proves the test can fail: forces an overflow in every
#                                      locale (LTR and RTL) and exits 1 if any of them passes
#
# slots.html measures each headline line after the fonts load and writes "WIDTH OK",
# "OVERFLOW line<n>=<px>px", "NO COPY ..." or "ERROR ..." into document.title; this reads it back
# with --dump-dom. Locales are de-duplicated: a list that repeats one (two config entries that
# share a store locale, or a repeated argument) tests it once.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/markets.sh
negative=0; [[ "${1:-}" == "--negative" ]] && { negative=1; shift; }
if (( $# )); then read -r -a locales <<< "$(dedupe "$@")"; else read -r -a locales <<< "$(store_locales)"; fi
read -r -a slots <<< "${SLOTS:-1 2}"
title() {
  "$CHROME" "${CHROME_FLAGS[@]}" --window-size=1080,1920 --dump-dom "file://$PWD/slots.html?l=$1&s=$2$3" 2>/dev/null \
    | grep -o '<title>[^<]*</title>' | sed 's/<[^>]*>//g' || true
}
fail=0
for L in "${locales[@]}"; do
  for s in "${slots[@]}"; do
    if (( negative )); then
      t=$(title "$L" "$s" "&overflow=1")
      [[ "$t" == OVERFLOW* ]] && echo "$L slot $s: forced overflow caught ($t)" || { echo "$L slot $s: forced overflow NOT caught: ${t:-no result}"; fail=1; }
    else
      t=$(title "$L" "$s" "")
      [[ "$t" == "WIDTH OK" ]] || { echo "$L slot $s: ${t:-no result}"; fail=1; }
    fi
  done
done
(( fail )) && exit 1
(( negative )) && echo "negative test: every forced overflow was caught (${locales[*]})" || echo "width test: all headlines fit (${locales[*]})"
