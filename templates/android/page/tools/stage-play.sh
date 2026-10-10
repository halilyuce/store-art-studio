#!/usr/bin/env bash
# Builds the fastlane supply image tree from out/:
#   out/play/<locale>/images/phoneScreenshots/01.png .. NN.png
#   out/play/<locale>/images/featureGraphic.png
#   out/play/<locale>/images/wearScreenshots/01.png .. NN.png   when ui/<code>/wear_*.png exist
# then runs verify-export.sh on it. The upload_art lane uploads from this tree.
#
#   tools/stage-play.sh                      every config locale that has renders in out/
#   tools/stage-play.sh en-US                these locales
#   tools/stage-play.sh --variant straight   slot 1 from 01-straight.png (any alternate 01-<name>.png)
#
# Wear OS screenshots, only when the config's "surfaces" lists "wear": they come straight from the
# render module (WearSurfacesTest, copied to ui/<code>/ by storeart/scripts/export.sh): square,
# opaque, raw watch UI, no page around them. NO_WEAR=1 skips them; WEAR_SIZE (default 576x576) is
# the size verify-export.sh expects.
#
# Slots are taken in name order (01.png, 02.png ...); Play shows them in that order. Variant files
# (01-<name>.png) never ship unless chosen here.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/markets.sh
variant=""; [[ "${1:-}" == "--variant" ]] && { variant="${2:?--variant needs a name}"; shift 2; }
if (( $# )); then read -r -a locales <<< "$(dedupe "$@")"
else
  locales=(); for L in $(store_locales); do [[ -d "out/$L" ]] && locales+=("$L"); done
fi
(( ${#locales[@]} )) || { echo "nothing to stage: render first (tools/render-all.sh)"; exit 1; }
# The skill's verify-export.sh: copied to store/tools/ at Gate 0, or straight from the skill folder.
VERIFY="${VERIFY:-../tools/verify-export.sh}"
[[ -f "$VERIFY" ]] || VERIFY="../../../scripts/verify-export.sh"
[[ -f "$VERIFY" ]] || { echo "no verify-export.sh: set VERIFY=<path>"; exit 2; }
rm -rf out/play
for L in "${locales[@]}"; do
  [[ -d "out/$L" ]] || { echo "no renders for $L in out/$L"; exit 1; }
  d="out/play/$L/images"; mkdir -p "$d/phoneScreenshots"
  n=0
  for f in $(ls "out/$L" | grep -E '^[0-9]{2}\.png$' | sort); do
    src="out/$L/$f"
    [[ -n "$variant" && "$f" == 01.png ]] && { src="out/$L/01-$variant.png"; [[ -f "$src" ]] || { echo "no $src"; exit 1; }; }
    cp "$src" "$d/phoneScreenshots/$f"; n=$((n + 1))
  done
  (( n >= 2 && n <= 8 )) || { echo "$L: $n phone screenshots, Play takes 2 to 8"; exit 1; }
  [[ -f "out/$L/feature-graphic.png" ]] || { echo "$L: no feature-graphic.png (tools/render-header.sh $L)"; exit 1; }
  cp "out/$L/feature-graphic.png" "$d/featureGraphic.png"
  code="$(market_code "$L")"; w=0
  if [[ "${NO_WEAR:-0}" != 1 && -n "$code" ]] && has_surface wear && ls "ui/$code"/wear_*.png >/dev/null 2>&1; then
    mkdir -p "$d/wearScreenshots"
    for f in $(ls "ui/$code" | grep -E '^wear_.*\.png$' | grep -v -- '-dark\.png$' | sort); do
      w=$((w + 1)); cp "ui/$code/$f" "$d/wearScreenshots/$(printf %02d "$w").png"
    done
    (( w <= 8 )) || { echo "$L: $w Wear OS screenshots, Play takes at most 8"; exit 1; }
  fi
  echo "$L: $n phone, $w wear"
done
bash "$VERIFY" out/play 1080x1920 1024x500 "${WEAR_SIZE:-576x576}"
echo "staged: ${locales[*]} (slot 1: ${variant:-default})"
