#!/usr/bin/env bash
# The whole set per locale: every slot and the feature graphic -> out/<locale>/01.png ...,
# feature-graphic.png. VARIANTS="straight" also renders those alternate versions of slot 1
# (out/<locale>/01-straight.png); stage-play.sh --variant <name> picks one.
#
#   tools/render-all.sh              the default market only (one market first)
#   tools/render-all.sh en-US ar     these store locales
#   tools/render-all.sh all          every market in storeart.config.json
#   SLOTS="1 2 3" tools/render-all.sh all
#
# Then: scripts/verify-export.sh out 1080x1920 1024x500. Renders are rebuilt, never committed.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/markets.sh
if [[ "${1:-}" == "all" ]]; then read -r -a locales <<< "$(store_locales)"
elif (( $# )); then read -r -a locales <<< "$(dedupe "$@")"
else locales=("$(default_locale)"); fi
start=$SECONDS
for L in "${locales[@]}"; do
  tools/render.sh "$L" ${SLOTS:-1 2} >/dev/null
  for v in ${VARIANTS:-}; do VARIANT="$v" tools/render.sh "$L" 1 >/dev/null; done
  tools/render-header.sh "$L" >/dev/null
  echo "$L: $(ls "out/$L" | tr '\n' ' ')"
done
echo "${#locales[@]} locale(s) in $((SECONDS - start)) s"
