# Starting the Android side

The Android pipeline is proven on one production app. This folder is that pipeline with the app
taken out:

```
storeart/                       a test-only Gradle module (Paparazzi), copy to <repo>/storeart/
  build.gradle.kts              plugins and dependencies through the version catalog
  libs.versions.snippet.toml    the catalog entries it needs, with the versions proven together
  logos.json                    logical id -> image URL (committed); placeholder images to start
  scripts/fetch_logos.py        downloads every URL once into src/test/resources/logos (gitignored)
  scripts/export.sh             fetch, render, copy the PNGs to the page kit's ui/<market>/
  src/main/.../SampleWorld.kt   the frozen world: markets, one fixed moment, full sample data
  src/main/.../SampleUi.kt      PLACEHOLDER card, screen and Glance widget; replace with your own
  src/test/.../StoreArtSupport.kt  Paparazzi setup, 412 x 915 dp at 3x, transparent theme, image
                                files with loud failure, 12/24 h, RTL, Glance via RemoteViews,
                                Material You wallpaper, PNG writer
  src/test/.../SampleSurfacesTest.kt  one Compose card, one Glance widget, one full screen, plus RTL
page/                           the HTML page layer, copy to <repo>/store/page/
  slots.html  kit.css  copy.js  one sample slot, en-US and Arabic (RTL)
  header.html                   the Play feature graphic
  tools/render.sh  render-header.sh  widthtest.sh
```

Read `references/android-compose.md` first. Its "What broke" table is why each helper exists.

## Set it up

1. Copy `storeart/` to your repo root and add `include(":storeart")` to `settings.gradle(.kts)`.
   Merge `libs.versions.snippet.toml` into `gradle/libs.versions.toml`. If the build has convention
   plugins, use them in `storeart/build.gradle.kts` instead of the plain plugins.
2. Add `/storeart/src/test/resources/logos/` to `.gitignore` (the module's own `.gitignore` has it).
3. `python3 storeart/scripts/fetch_logos.py`, then `./gradlew :storeart:recordPaparazziDebug`.
   Open `storeart/build/storeart/us/` and `sa/`: `card_score`, `widget_table_big` (plain and
   `-dyn`), `screen_table`, each light and `-dark`.
4. Copy `page/` to `store/page/` (or set `PAGE_DIR` for `export.sh`), run
   `storeart/scripts/export.sh`, then `store/page/tools/render.sh en-US` and
   `store/page/tools/widthtest.sh`. The slot shows your renders, or labelled boxes where a render
   is missing.
5. Copy `scripts/` of this skill to `store/tools/` for `verify-export.sh`, `probe.swift`,
   `chromakey.swift`, `edgekey.swift` and `greenbox.swift`.

## The prompt

Paste this into Claude Code from your Android project's root, with the skill installed.

```text
Use the store-art-studio skill. Set up the Android render target in this repository from
templates/android, following references/android-compose.md.

Before you edit any Gradle file, tell me what this project already uses (AGP, Kotlin, compileSdk,
Compose BOM, Glance, Coil, JDK, any screenshot library) and the exact catalog and settings changes
you will make. Wait for my answer.

Then:
1. Add the storeart module and the page kit. Render the sample surfaces and open every PNG.
2. Replace the placeholders in SampleUi.kt with my real composables: one screen, one widget (through
   GlanceRemoteViews and an AppWidgetHostView), one card. If a composable needs a ViewModel, a
   repository or the clock, add a seam that takes plain state, and tell me which.
3. Fill SampleWorld.kt with a frozen world for my default market: one fixed moment, full tables and
   lists that add up, no real people, no System.currentTimeMillis() in any rendered path.
4. Render the same screen in a second market, with different strings and formats.

Never run my real app, an emulator signed in to a real account, or anything that syncs.

Stop at Gate 0 and show me the renders, the sample slot, verify-export.sh passing, and a short list
of what broke. Add anything new to the "What broke" table in references/android-compose.md.
```

## After Gate 0

Continue with the normal workflow in `SKILL.md`: style tile and a calibration slot, hero and hard
slots, the rest, localization, delivery with `supply` to a track that is not production. If you
have a reference set, say so in the first message: `references/reference-matching.md` is for that.

## What to send back

Anything that broke in the generic template and not in the reference doc is worth a pull request:
the fix in `templates/android` and a row in "What broke".
