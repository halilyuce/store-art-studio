#!/usr/bin/env bash
# Renders every store-art surface host-less (Paparazzi) and copies them to the page kit.
#
#   storeart/scripts/export.sh                     fetch missing images, render, copy
#   PAGE_DIR=store/page storeart/scripts/export.sh copy somewhere else
#
# Renders land in storeart/build/storeart/<market>/; the copies go to $PAGE_DIR/ui/<market>/,
# where slots.html and header.html look for them. Run from anywhere; paths are repo-relative.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PAGE_DIR="${PAGE_DIR:-store/page}"
cd "$ROOT"

python3 storeart/scripts/fetch_logos.py
rm -rf storeart/build/storeart
./gradlew :storeart:recordPaparazziDebug

for dir in storeart/build/storeart/*/; do
  market="$(basename "$dir")"
  mkdir -p "$PAGE_DIR/ui/$market"
  cp "$dir"*.png "$PAGE_DIR/ui/$market/"
  echo "$(ls "$dir"*.png | wc -l | tr -d ' ') surfaces -> $PAGE_DIR/ui/$market/"
done
