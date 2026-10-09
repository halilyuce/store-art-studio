#!/usr/bin/env bash
# usage: verify-export.sh <dir> <WIDTHxHEIGHT> [more WIDTHxHEIGHT ...]
#
# Fails when any PNG or JPEG under <dir> has a size not in the list or carries an alpha channel.
# The stores reject both at upload time, which is a slow place to find out. Folders named checks
# and work are skipped. Pass every size you ship (a header is 3840x1646, for example).
#
#   verify-export.sh StoreArt/Output 1320x2868
#   verify-export.sh fastlane/metadata/android 1080x1920 1440x2560
set -euo pipefail
dir="${1:?directory}"; shift
(( $# )) || { echo "give at least one WIDTHxHEIGHT"; exit 2; }
allowed=" $* "
bad=0; count=0
while IFS= read -r file; do
  count=$((count + 1))
  w=$(sips -g pixelWidth "$file" | awk '/pixelWidth/ {print $2}')
  h=$(sips -g pixelHeight "$file" | awk '/pixelHeight/ {print $2}')
  alpha=$(sips -g hasAlpha "$file" | awk '/hasAlpha/ {print $2}')
  [[ "$allowed" == *" ${w}x${h} "* ]] || { echo "SIZE   $file is ${w}x${h}"; bad=$((bad + 1)); }
  [[ "$alpha" == "no" ]] || { echo "ALPHA  $file has an alpha channel"; bad=$((bad + 1)); }
done < <(find "$dir" \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -not -path "*/checks/*" -not -path "*/work/*" | sort)
(( count )) || { echo "no images under $dir"; exit 1; }
if (( bad )); then echo "$bad problem(s) in $count image(s)"; exit 1; fi
echo "ok: $count image(s), sizes ${*}, no alpha"
