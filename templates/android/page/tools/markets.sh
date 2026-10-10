# Sourced by the page tools. Reads the developer's storeart.config.json (default: one level up
# from the page kit; override with STOREART_CONFIG=<path>). Nothing in the tools names a locale.
#
#   store_locales          every market's storeLocale, once each, in config order
#   default_locale         the default market's storeLocale
#   has_surface <name>     true when the config's "surfaces" lists it (screens always)
#   market_code <locale>   the code (render folder ui/<code>/) of the first market with that storeLocale
#   dedupe a b a           a b  (keeps the first of each, so a repeated argument runs once)
STOREART_CONFIG="${STOREART_CONFIG:-$PWD/../storeart.config.json}"
[[ -f "$STOREART_CONFIG" ]] || { echo "no config at $STOREART_CONFIG (set STOREART_CONFIG)" >&2; exit 2; }
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
# --allow-file-access-from-files lets the page fetch the config from a file:// URL.
CHROME_FLAGS=(--headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --allow-file-access-from-files --virtual-time-budget=8000)
store_locales() {
  python3 -I -c 'import json,sys; seen=[]; [seen.append(m["storeLocale"]) for m in json.load(open(sys.argv[1]))["markets"] if m["storeLocale"] not in seen]; print(" ".join(seen))' "$STOREART_CONFIG"
}
default_locale() {
  python3 -I -c 'import json,sys; c=json.load(open(sys.argv[1])); m=[m for m in c["markets"] if m["code"]==c.get("default")] or c["markets"]; print(m[0]["storeLocale"])' "$STOREART_CONFIG"
}
has_surface() {
  [[ "$1" == screens ]] || python3 -I -c 'import json,sys; sys.exit(0 if sys.argv[2] in json.load(open(sys.argv[1])).get("surfaces", []) else 1)' "$STOREART_CONFIG" "$1"
}
market_code() {
  python3 -I -c 'import json,sys; m=[m for m in json.load(open(sys.argv[1]))["markets"] if m["storeLocale"]==sys.argv[2]]; print(m[0]["code"] if m else "")' "$STOREART_CONFIG" "$1"
}
dedupe() { printf '%s\n' "$@" | awk 'NF && !seen[$0]++' | tr '\n' ' '; }
flatten() {
  if sips -g hasAlpha "$1" 2>/dev/null | grep -q 'hasAlpha: yes'; then
    if command -v magick >/dev/null; then magick "$1" -background white -alpha remove -alpha off "$1"
    else echo "ALPHA  $1 has an alpha channel and magick is not installed"; fi
  fi
}
