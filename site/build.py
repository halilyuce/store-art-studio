#!/usr/bin/env python3
"""Builds ../index.html (the web guide, also the Vercel site) from index.template.html.

    python3 site/build.py

It inlines the small images in site/art and site/logo as data URIs and pastes the Android
starter prompt from templates/android/START-HERE.md, so the prompt on the page and in the
skill never drift apart. The example screenshots stay as files under assets/examples.
Run it after every edit to the template, and commit index.html with it: Vercel serves the
repo as plain static files and has no build step.
"""
import base64
import html
import re
from pathlib import Path

SITE = Path(__file__).resolve().parent
ROOT = SITE.parent


def b64(path):
    return base64.b64encode((SITE / path).read_bytes()).decode()


template = (SITE / "index.template.html").read_text()
start_here = (ROOT / "templates/android/START-HERE.md").read_text()
prompt = html.escape(re.search(r"```text\n(.*?)\n```", start_here, re.S).group(1), quote=False)

page = (template
        .replace("{{ANDROID_PROMPT}}", prompt)
        .replace("{{SAMPLE}}", b64("art/sample.jpg"))
        .replace("{{STAR}}", b64("art/star.webp"))
        .replace("{{HEART}}", b64("art/heart.webp"))
        .replace("{{GIFT}}", b64("art/gift.webp"))
        .replace("{{ICON}}", b64("art/icon.webp"))
        .replace("{{BOW}}", b64("art/bow.webp"))
        .replace("{{AVATAR}}", b64("art/avatar.webp"))
        .replace("{{ICON96}}", b64("logo/icon96.webp"))
        .replace("{{ICON360}}", b64("logo/icon360.webp"))
        .replace("{{FAV}}", b64("logo/fav64.png")))
left = re.findall(r"\{\{[A-Z0-9_]+\}\}", page)
if left:
    raise SystemExit(f"unfilled placeholders: {sorted(set(left))}")
(ROOT / "index.html").write_text(page)
print(f"wrote index.html ({len(page) // 1024} KB)")
