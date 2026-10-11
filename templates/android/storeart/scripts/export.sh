#!/usr/bin/env bash
# Renders every store-art surface host-less (Paparazzi), one world per market, and copies them to
# the page kit.
#
#   storeart/scripts/export.sh                 the config's default market only
#   storeart/scripts/export.sh us sa           these markets (codes from storeart.config.json)
#   storeart/scripts/export.sh all             every market in the config
#   STOREART_MARKETS=us,sa storeart/scripts/export.sh
#   PAGE_DIR=store/page storeart/scripts/export.sh
#
# Renders land in storeart/build/storeart/<market>/; the copies go to $PAGE_DIR/ui/<market>/, where
# slots.html and header.html look for them. Run from anywhere; paths are repo-relative. A full run
# over many markets takes minutes (about a minute per market in the project this comes from).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PAGE_DIR="${PAGE_DIR:-store/page}"
cd "$ROOT"
MARKETS="${*:-${STOREART_MARKETS:-}}"
MARKETS="$(echo "$MARKETS" | tr ' ' ',' | sed 's/,,*/,/g; s/^,//; s/,$//')"

python3 storeart/scripts/fetch_logos.py
rm -rf storeart/build/storeart
./gradlew :storeart:recordPaparazziDebug -Pstoreart.markets="$MARKETS"

for dir in storeart/build/storeart/*/; do
  market="$(basename "$dir")"
  # Replaced, not merged: a surface dropped from "surfaces" must not linger in the page kit.
  rm -rf "$PAGE_DIR/ui/$market"; mkdir -p "$PAGE_DIR/ui/$market"
  cp "$dir"*.png "$PAGE_DIR/ui/$market/"
  echo "$(ls "$dir"*.png | wc -l | tr -d ' ') surfaces -> $PAGE_DIR/ui/$market/"
done
