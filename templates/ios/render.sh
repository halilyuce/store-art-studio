#!/usr/bin/env bash
# Renders store creative from your real SwiftUI views (the StoreArt test target).
#
#   scripts/screenshots/render.sh                 every slot
#   scripts/screenshots/render.sh Sample          one test: runs testSample (the name after "test", exactly)
#   TEST_RUNNER_STOREART_MARKET=de-DE,ja scripts/screenshots/render.sh Slot03Markets
#
# PNGs land in StoreArt/Output. The tests run on a dedicated simulator that never has the app
# installed, so no real favorites, account or settings can be touched. Edit the four variables.
set -euo pipefail
cd "$(dirname "$0")/../.."

PROJECT="MyApp.xcodeproj"            # or WORKSPACE="MyApp.xcworkspace" and swap -project below
SCHEME="StoreArt"
TEST_TARGET="StoreArt"
TEST_CLASS="StoreArtRenderTests"
SIM_NAME="StoreArt iPhone 17 Pro Max"
DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max"

udid=$(xcrun simctl list devices -j | python3 -c "
import json, sys
for runtime, devices in json.load(sys.stdin)['devices'].items():
    for d in devices:
        if d['name'] == '$SIM_NAME' and d.get('isAvailable', True):
            print(d['udid']); sys.exit()
")
if [[ -z "$udid" ]]; then
  runtime=$(xcrun simctl list runtimes -j | python3 -c "
import json, sys
ios = [r for r in json.load(sys.stdin)['runtimes'] if r['platform'] == 'iOS' and r['isAvailable']]
print(sorted(ios, key=lambda r: [int(x) for x in r['version'].split('.')])[-1]['identifier'])
")
  udid=$(xcrun simctl create "$SIM_NAME" "$DEVICE_TYPE" "$runtime")
  echo "Created simulator $SIM_NAME ($udid)"
fi

only=()
[[ -n "${1:-}" ]] && only=(-only-testing:"$TEST_TARGET/$TEST_CLASS/test$1")

# Its own DerivedData: sharing Xcode's breaks the next IDE build with stale module caches.
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "id=$udid" \
  -derivedDataPath build/StoreArtDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  ${only[@]+"${only[@]}"} 2>&1 | grep -E "error: |\[storeart\]|\[widths\]|Test (Suite|Case).*(passed|failed)|TEST (SUCCEEDED|FAILED)|\*\* TEST" || true

find StoreArt/Output -name "*.png" 2>/dev/null | sort
