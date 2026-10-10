# Starting the Android side

The Android pipeline is proven on one production app. This folder is that pipeline with the app
taken out. It works the same for any kind of app: the sample is a neutral list-and-totals app, and
you replace its surfaces and data with your own.

New to the skill? Read `docs/android-end-to-end.md` in the skill folder first. It covers
connecting every tool (Higgsfield, Paparazzi, Chrome, fastlane, the Play service account), each
gate with its prompt, the Play submission checklist (Wear OS, the AI declaration) and
troubleshooting. This file is the short version: what to copy, and the Gate 0 prompt.

```
storeart.config.json            YOUR markets: store locale, app locale, time zone, clock, direction,
                                currency, digits, script font, upload approval. Copy to
                                <repo>/store/. Two example entries (one LTR, one RTL) to replace.
                                "surfaces": what your app has. Screens always; widgets,
                                notification, wear, tablet only if you ship them. The sample
                                lists all of them; trim it to yours.
storeart/                       a test-only Gradle module (Paparazzi), copy to <repo>/storeart/
  build.gradle.kts              plugins and dependencies through the version catalog; passes the
                                config path and the market selection to the tests
  libs.versions.snippet.toml    the catalog entries it needs, with the versions proven together
  logos.json                    logical id -> image URL (committed); placeholder images to start
  scripts/fetch_logos.py        downloads every URL once into src/test/resources/logos (gitignored)
  scripts/export.sh             fetch, render the selected markets, copy the PNGs to page/ui/<market>/
  src/main/.../StoreArtConfig.kt  reads storeart.config.json, selects markets (default market only)
  src/main/.../RecordEngine.kt  seeded records -> computed aggregates, seed picked to fit the story
  src/main/.../SampleWorld.kt   ShowcaseWorld: one world per market (the two examples)
  src/main/.../SampleUi.kt      PLACEHOLDER card, list screen and Glance widget; replace with your own
  src/test/.../StoreArtSupport.kt  Paparazzi setup, 412 x 915 dp at 3x, transparent theme, image
                                files with loud failure, 12/24 h, RTL, Glance via RemoteViews,
                                Material You wallpaper, PNG writer
  src/test/.../SampleSurfacesTest.kt  screen_list always; card_live and widget_list_big only when
                                surfaces lists notification and widgets; once per market
  src/main/.../SampleWear.kt    PLACEHOLDER watch tile and list; replace with your Wear UI
  src/test/.../WearSurfacesTest.kt  only with "wear" in surfaces: wear_01_tile, wear_02_list,
                                square, opaque Wear OS listing screenshots (raw watch UI, no
                                mask or frame), once per market
  src/test/.../WorldsTest.kt    every market's world holds together (plain JUnit, fast)
page/                           the HTML page layer, copy to <repo>/store/page/
  slots.html  kit.css  kit.js   two sample slots; kit.js reads the config (market, clock, date, font)
  copy.js  COPY_NOTES.md        copy per store locale, and its back-translations
  header.html                   the Play feature graphic
  tools/render.sh  render-header.sh  render-all.sh  widthtest.sh  stage-play.sh  markets.sh
```

Read `references/android-compose.md` first. Its "What broke" table is why each helper exists, and
"Adding a market" is the checklist for every market after the first.

## The first 30 minutes

From your Android project's root, with the skill installed at `~/.claude/skills/store-art-studio`
and the Higgsfield MCP connected (`docs/android-end-to-end.md`, section 1).

```bash
SKILL=~/.claude/skills/store-art-studio
mkdir -p store/tools
cp $SKILL/templates/android/storeart.config.json store/
cp -R $SKILL/templates/android/page store/page
cp -R $SKILL/templates/android/storeart storeart
cp $SKILL/scripts/* store/tools/
```

1. Add `include(":storeart")` to `settings.gradle(.kts)` and merge
   `storeart/libs.versions.snippet.toml` into `gradle/libs.versions.toml` (or let Claude do it in
   Gate 0, after it read your versions). No catalog yet: copy the snippet to
   `gradle/libs.versions.toml`. Two checks before the first build:
   - If the root build already declares AGP, Kotlin or Paparazzi (`apply false` or a buildscript
     classpath), set `agp`, `kotlin` and `paparazzi` in the catalog to exactly those versions.
   - If `gradle.properties` has `android.builtInKotlin=false`, uncomment
     `alias(libs.plugins.kotlin.android)` in `storeart/build.gradle.kts`. The build file tells you
     if you forget.
2. Leave the two example markets in `store/storeart.config.json` for now. The sample world is
   written for them. Gate 0 replaces them with your default market.
3. Render the sample surfaces and the page:

```bash
python3 storeart/scripts/fetch_logos.py
./gradlew :storeart:testDebugUnitTest --tests '*WorldsTest'
storeart/scripts/export.sh
store/page/tools/render-all.sh
store/page/tools/widthtest.sh
store/tools/verify-export.sh store/page/out 1080x1920 1024x500
```

4. Open `storeart/build/storeart/<code>/` and `store/page/out/<locale>/01.png`.
5. Paste the prompt below. Claude takes it from there, one gate at a time.

If you already replaced the examples, the sample render fails with "no world for market". That
is expected: Gate 0 writes the world for your market.

## Set it up

1. Copy `storeart.config.json` to `store/`, `storeart/` to your repo root, and `page/` to
   `store/page/`. Add `include(":storeart")` to `settings.gradle(.kts)`. Merge
   `libs.versions.snippet.toml` into `gradle/libs.versions.toml` (plugin versions equal to the
   root build's, `kotlin.android` only without built-in Kotlin: see step 1 above). If the build
   has convention plugins, use them in `storeart/build.gradle.kts` instead of the plain plugins.
2. Replace the two example markets in the config with yours. Keep one as `default`: it renders first
   and alone until it is approved.
3. Add `/storeart/src/test/resources/logos/` to `.gitignore` (the module's own `.gitignore` has
   it), and the page kit's `.gitignore` rules (`page/.gitignore`).
4. `python3 storeart/scripts/fetch_logos.py`, then `./gradlew :storeart:testDebugUnitTest --tests '*WorldsTest'`
   and `./gradlew :storeart:recordPaparazziDebug`. Open `storeart/build/storeart/<default market>/`:
   `card_live`, `widget_list_big` (plain and `-dyn`), `screen_list`, each light and `-dark`.
5. `storeart/scripts/export.sh`, then `store/page/tools/render-all.sh`,
   `store/page/tools/widthtest.sh` and `store/page/tools/widthtest.sh --negative`. The slots show
   your renders, or labelled boxes where a render is missing.
6. Copy `scripts/` of this skill to `store/tools/` for `verify-export.sh`, `probe.swift`,
   `chromakey.swift`, `edgekey.swift` and `greenbox.swift`. `store/page/tools/stage-play.sh` finds
   `verify-export.sh` there.
7. For delivery, paste `templates/fastlane/Fastfile.android.snippet.rb` into the Android platform
   block of `fastlane/Fastfile`.

## The prompt

Paste this into Claude Code from your Android project's root, with the skill installed. It starts
Gate 0. Fill the brackets.

```text
Use the store-art-studio skill. Start Gate 0 for Google Play. Follow docs/android-end-to-end.md
and templates/android/START-HERE.md in the skill folder, and references/android-compose.md for
the renderer.

My default market: <store locale>, time zone <IANA zone>, <12 or 24> hour clock, currency <ISO
code>, <left to right or right to left>. Screens worth showing: <screens>. My app also has
(delete what it does not): widgets, a live notification or Live Update, a Wear OS app or tile, a
tablet layout. Credit budget: <n> credits; ask before any gate costs more than <m>. Reference
set: <path, or "none">.

Before you edit any Gradle file, tell me what this project already uses (AGP, Kotlin, compileSdk,
Compose BOM, Glance, Coil, JDK, any screenshot library) and the exact catalog and settings changes
you will make. Wait for my answer.

Then:
1. Add the storeart module, the page kit and store/storeart.config.json with only my default
   market in it, "upload": false. The config is the only list of markets. Set "surfaces" to what
   my app has (ask me if the list above is unclear): "screens" always, the rest only if I ship
   them. Render and place nothing for a surface that is not listed.
2. Render the sample surfaces and open every PNG.
3. Replace the placeholders in SampleUi.kt (and SampleWear.kt if I have a Wear OS app or tile)
   with my real composables: one screen, and for the surfaces I have, one widget (through
   GlanceRemoteViews and an AppWidgetHostView) and one live card. If a composable needs a ViewModel, a repository or the clock, add a seam that takes plain
   state, and tell me which.
4. Replace the sample world with a frozen world for my default market: one fixed moment, full and
   plausible lists whose aggregates are computed from records, no real people, no
   System.currentTimeMillis() in any rendered path. Use role ids for every surface.
5. Check Higgsfield: balance, one cheap test image, and a plan for Gates 1 to 5 with a credit
   estimate.

Never run my real app, an emulator signed in to a real account, or anything that syncs.

Stop at Gate 0 and show me the renders, the sample slot, verify-export.sh passing, the plan, which
screens you redrew instead of rendered, and a short list of what broke. Add anything new to the
"What broke" table in references/android-compose.md.
```

## After Gate 0

Continue gate by gate with `docs/android-end-to-end.md`, which has the prompt for each one, or
the workflow in `SKILL.md`: style tile and a calibration slot, hero and hard
slots, the rest, localization (one config entry, one world, one copy entry per market), delivery
with `stage-play.sh` and the `upload_art` lane's dry run. If you have a reference set, say so in
the first message: `references/reference-matching.md` is for that.

## What to send back

Anything that broke in the generic template and not in the reference doc is worth a pull request:
the fix in `templates/android` and a row in "What broke".
