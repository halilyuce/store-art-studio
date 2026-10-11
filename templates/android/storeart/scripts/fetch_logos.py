#!/usr/bin/env python3
"""Downloads every image the store-art world uses, so the Paparazzi renders run offline.

Reads storeart/logos.json (logical id -> image URL, committed) and saves each URL to
storeart/src/test/resources/logos/<sha1 of the URL>.png (gitignored: provider images are
licensed inputs, re-fetched, never committed). The tests serve an image by hashing the same URL,
and fail when its file is missing.

    python3 storeart/scripts/fetch_logos.py           # fetch what is missing
    python3 storeart/scripts/fetch_logos.py --force   # download everything again
"""
import argparse
import hashlib
import json
import pathlib
import sys
import urllib.request

MODULE = pathlib.Path(__file__).resolve().parent.parent
LOGOS_JSON = MODULE / "logos.json"
OUT_DIR = MODULE / "src" / "test" / "resources" / "logos"

# PNG, JPEG, WebP, GIF: what BitmapFactory decodes in the tests. An HTML error page is not an image.
MAGIC = (b"\x89PNG", b"\xff\xd8\xff", b"RIFF", b"GIF8")


def file_for(url: str) -> pathlib.Path:
    return OUT_DIR / (hashlib.sha1(url.encode("utf-8")).hexdigest() + ".png")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--force", action="store_true", help="download files that already exist again")
    args = parser.parse_args()

    logos = json.loads(LOGOS_JSON.read_text(encoding="utf-8"))
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    failed = []
    fetched = 0
    for logo_id, url in sorted(logos.items()):
        target = file_for(url)
        if target.exists() and not args.force:
            continue
        try:
            request = urllib.request.Request(url, headers={"User-Agent": "storeart-fetch/1.0"})
            with urllib.request.urlopen(request, timeout=30) as response:
                data = response.read()
            if not data.startswith(MAGIC):
                raise ValueError("not a bitmap image (%d bytes)" % len(data))
            target.write_bytes(data)
            fetched += 1
            print("fetched %-24s %s" % (logo_id, url))
        except Exception as e:  # report every failure, then exit non-zero
            failed.append(logo_id)
            print("FAILED  %-24s %s: %s" % (logo_id, url, e), file=sys.stderr)
    print("%d fetched, %d already present, %d failed" % (fetched, len(logos) - fetched - len(failed), len(failed)))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
