# Android: the Jetpack Compose render target

**Status: proven on one production app.** A Paparazzi module rendered that app's real composables,
its real Glance widgets, its real notification layout and its Wear tile face from a frozen world,
one world per market, and an HTML page layer turned them into a full Play set (8 phone slots and a
feature graphic per locale, left to right and right to left). `templates/android` is that module
and that page kit with the app taken out: a neutral sample app, two example markets, no market
list of its own. The template itself was then built and run as it ships, copied into a separate
multi-module host app with the sample data only: Gradle 9.7.0 on JDK 21, AGP 9.3.0, Kotlin 2.4.10,
compileSdk 37, Paparazzi 2.0.0-alpha05, Compose BOM 2026.09.00, Glance 1.2.0, Coil 3.6.3. Both
example markets, screens only and every surface, the page, the feature graphic, the width tests and
the Play staging all ran on macOS. Every trap below was hit for real, and the fix is the one that
shipped.

The method does not depend on what the app does. A finance app, a fitness tracker, a notes app or
a game shows its own surfaces from its own data; the skill only fixes how they are rendered,
placed and shipped.

To start: `templates/android/START-HERE.md`. The full walkthrough, from connecting the tools to
the store declarations, is `docs/android-end-to-end.md`.

## The contract is identical

The four layers do not change. Neither do the hard rules: never drive the user's real app or a
signed-in emulator; one market first; headlines never shrink; every generated asset has a
provenance file.

| Layer | On Android |
|---|---|
| Truth | The app's own composables, Glance widgets and RemoteViews layouts, rendered by Paparazzi (layoutlib on the JVM) from a frozen world. No emulator, no device, no network, no account |
| Atmosphere | Higgsfield art, keyed and placed by the page layer (`references/higgsfield-art.md`) |
| Page | Compose in the same test module, or an HTML page rendered by headless Chrome. Both work. The production set used HTML because the project already had an HTML pipeline |
| Delivery | `tools/stage-play.sh` builds the supply tree; the `upload_art` fastlane lane uploads images only, after a `validate_only` dry run, and the developer runs it |

The split that worked: the render module writes one PNG per surface (a screen, a widget at one
size, a notification card, a status chip, a watch face), often on a transparent background, in
light and dark. The page layer only places those PNGs and the art. It never draws app UI.

## One config owns the markets

The skill ships no language or market list. The developer owns `storeart.config.json` (template:
`templates/android/storeart.config.json`, copied to `store/storeart.config.json`), and everything
reads it: the render module (which markets exist, which run), `slots.html` and `header.html`
(direction, clock, date line, script font), and the page tools (`render-all.sh`, `widthtest.sh`,
`stage-play.sh`) and the `upload_art` lane (the allow list).

```json
{
  "moment": "2026-10-11T21:41",
  "default": "us",
  "markets": [
    { "code": "us", "storeLocale": "en-US", "appLocale": "en-rUS", "languageTag": "en-US",
      "timeZone": "America/New_York", "clock24h": false, "rtl": false, "currency": "USD",
      "digits": "", "fontFamily": "", "fontWeights": "", "upload": true }
  ]
}
```

- `code` names the render folder (`ui/<code>/`). `storeLocale` is the Play listing's locale and the
  key into `copy.js`. `appLocale` is the resource qualifier Paparazzi takes. `languageTag` plus
  `digits` (`"latn"` appends `-u-nu-latn`) is what every formatter reads, in Kotlin and in the page.
- `fontFamily` and `fontWeights` load a face for a script the Latin faces lack. `upload: true` puts
  the market on the upload allow list; set it only after the owner approved that market's renders.
- Keep each market flat (no nesting): the Kotlin side parses it without a JSON library and the
  scripts read it with `python3`.
- Selection: `-Pstoreart.markets=us,sa`, `STOREART_MARKETS=us,sa`, or `all`. Unset means the
  default market only, so one market comes first by default, not by discipline.

The template's two entries are examples (one left to right, one right to left) so both paths stay
testable. They are not a recommendation.

### Surfaces are optional

Phone screens are the only required surface. Everything else depends on what the app ships, and
the config says so in one top-level list:

```json
"surfaces": ["screens", "widgets", "notification", "wear"]
```

| Entry | Means the app has | What renders |
|---|---|---|
| `screens` | Always on | `screen_*` renders, every phone slot |
| `widgets` | Home screen widgets | `widget_*` renders, widgets on the lock screen slot and the feature graphic |
| `notification` | A live notification, a Live Update chip or a live card | `card_live*` renders, the floating card in slot 1 |
| `wear` | A Wear OS app or tile | `wear_*` renders, `wearScreenshots/` in the staged tree, any watch-on-wrist slot |
| `tablet` | A tablet layout | Tablet slots, if you add them (the template has none) |

A missing `surfaces` key means screens only, so the default works for any app. A test for a
surface that is not listed is skipped, not failed, and the page leaves the surface out (slot 2
shows a second screen instead of the lock screen). Gate 0 asks which surfaces exist. The template
lists all of them so every path stays testable: trim it to what you ship.

### Adding a market

1. **Config:** an entry in `storeart.config.json`. Set `rtl`, `clock24h`, `currency`, `digits` and,
   for a script the page faces lack, `fontFamily` with explicit `fontWeights`.
2. **World:** a branch in `showcaseWorld()` (`SampleWorld.kt`): that market's own names, amounts
   and primary item. The surfaces stay the same.
3. **Strings:** the app's own translations already cover the app UI. Add `values-<qualifier>` only
   for strings the sample surfaces use.
4. **Copy:** an entry in `copy.js` (`COPY` and `HEADER`) under the market's `storeLocale`,
   transcreated, with its back-translation in `COPY_NOTES.md` (`references/style-and-copy.md`).
5. **Art:** optionally `art/hero/<code>.jpg` and `art/avatars/<code>/a1..a4.png`; the page falls
   back to `default`.
6. **Checks:** `WorldsTest`, `storeart/scripts/export.sh <code>`, `tools/widthtest.sh <locale>`,
   `tools/widthtest.sh --negative <locale>`, `tools/render-all.sh <locale>`, open every PNG,
   `verify-export.sh`. Then list the new locale as "not native-reviewed".

## The render module

`templates/android/storeart/` is a test-only Gradle library module. It depends on the app modules
that hold the composables you show, and nothing depends on it.

- **Paparazzi `2.0.0-alpha05`** ran on AGP 9 with compileSdk 36 and 37 (built-in Kotlin plus the
  Compose compiler plugin). Paparazzi pins a Gradle, compileSdk and JDK range per release, so read
  the release notes before you pick a version. Roborazzi is the alternative if the project already
  runs Robolectric. Do not add both.
- `./gradlew :storeart:recordPaparazziDebug` runs every test. The template's snapshot handler
  writes `build/storeart/<market>/<id>.png` directly, alpha kept. The renders are the output, not
  goldens, so record and verify runs write the same files, and the test task is never up to date.
- Surface tests are JUnit `Parameterized` over `CONFIG.selected()`: one run per market, no copy of a
  test per market. Gradle passes the config path and the selection as system properties.
- Tests run with the module folder as the working directory, so `logos.json` and
  `src/test/resources/logos/` are read by relative path.
- A full run is minutes, not seconds: in the production app a full multi-market run (every surface,
  light and dark) took about 12 minutes. Render one market while you iterate.

### The render recipe

1. **Device.** `DeviceConfig.PIXEL_6.copy(...)` with `screenWidth = widthDp * 3`,
   `screenHeight = heightDp * 3`, `density = XXHIGH`, `xdpi = ydpi = 480`, `fontScale = 1f`, the
   market's `appLocale`, `nightMode`, `softButtons = false`. Full screens are 412 x 915 dp (a
   Pixel's content area), so a screen render is 1236 x 2745 px. Resize the device per surface with
   `paparazzi.unsafeUpdateConfig(deviceConfig = ...)`.
2. **Transparent background.** Theme `android:Theme.Translucent.NoTitleBar.Fullscreen`. Anything
   that does not paint its own background (a card, a chip, a round watch face, the corners of a
   widget) keeps real alpha, so the page can drop a shadow under it. Screens paint
   `MaterialTheme.colorScheme.background` themselves.
3. **Cut-outs.** `RenderingMode.SHRINK` crops the image to the content's own size. Use it for a
   notification card or a status chip, where you only know the width.
4. **Animations settled.** Wrap content in `LocalInspectionMode provides true` (what Studio
   previews do), then render with `paparazzi.gif(view, name, start = 0, end = 2000, fps = 6)`.
   The handler keeps the last frame.
5. **Images.** Composables take image URL strings, as in the app. Coil 3's
   `LocalAsyncImagePreviewHandler` (active under `LocalInspectionMode`) maps each URL to a file
   that `scripts/fetch_logos.py` downloaded once from `logos.json` into a gitignored folder, named
   by the SHA-1 of the URL. A URL with no file fails the test. A blank image must never ship.
6. **The world.** One `ShowcaseWorld` per market, see below.
7. **Widgets and notifications** go through RemoteViews, see "Surfaces".

### The frozen world, one per market

Every surface reads one object per market: the moment, time zone, locale, 12 or 24 hour clock,
currency, and every record the screens show. Then the widget, the screen and the notification
agree.

- **One interface, one implementation per market.** `ShowcaseWorld` is what surfaces read: a title,
  the records, the aggregates, the user's primary item and its live state. Each market gets its own
  world (its own names, amounts, primary item), so a market tells its own story while the surfaces
  and the page do not change.
- **A seeded engine, not typed numbers.** `RecordEngine` draws records from a seed and computes
  every aggregate from them. Typed-in totals drift; computed ones agree on every surface. (In the
  production app the records were results and the aggregates were tables; the template's sample is
  spending per place.) The engine tries a range of seeds and keeps the first whose outcome fits the
  story: the primary item in the top two and its latest record trending up, because the surfaces
  open on it. No seed fits: reorder the inputs or move the seed, never edit an output.
- `WorldsTest` (plain JUnit, about a second) asserts each market's world holds together before
  anything renders, and prints it for a read-through.
- `now` is the config's `moment` in the market's zone. Nothing in a rendered code path may call
  `System.currentTimeMillis()`. Where app code reads the clock, add a seam (a parameter or a
  CompositionLocal) that defaults to the system clock and that the test sets.
- **12 or 24 hours** comes from a CompositionLocal (`LocalUse24HourClock`, `null` means the device
  setting) that the app's time formatting reads. Without it the render follows the host, and a
  12 hour market can show "21:41". Most markets are 24 hour; set it per market in the config.
- Set the JVM defaults too (`TimeZone.setDefault`, `Locale.setDefault`): formatting code that does
  not take a locale reads them.
- **Full, plausible data.** A list with three rows reads as broken in store art. Invent complete
  data that adds up. Invented, not real: no real people. If the app shows third-party names or
  marks, check the right to show them in marketing, which is separate from the right to show them
  in the app.

### Role ids

Surfaces are written under **role** ids, not under what they show in one market:
`widget_primary_big`, `widget_list_wide`, `widget_list_big`, `card_live`, `card_live_2`,
`screen_detail`, `screen_list`, `screen_secondary`. A role says what the surface does on the page.
Then one page layout works for every market, even when the primary item or the content type differs
by market. Each surface comes in light and `-dark`; widgets also in `-dyn` and `-dyn-dark` (Material
You). The page asks for `id-dyn-dark|id-dark|id` and takes the first that exists.

## Surfaces

Each row below is optional except the screens. Render a surface only if the app has it and the
config's `surfaces` lists it (see "Surfaces are optional").

| iOS | Android, as proven |
|---|---|
| Widgets (WidgetKit) | The real Glance widget: compose with `GlanceRemoteViews`, apply the RemoteViews inside an `AppWidgetHostView`, snapshot the view. No redraw |
| Live Activity, Dynamic Island | The app's own notification RemoteViews layout (a delivery, a timer, a workout, a ride), applied the same way, inside a redrawn system frame. The Android 16 Live Update status-bar chip is redrawn too |
| Material You | Layoutlib's built-in wallpaper support, seeded with a solid colour, runs the real dynamic colour pipeline, so `GlanceTheme` and `system_accent*` colours come out as on a phone |
| Watch face, complication | The Wear tile face rendered as a round cut-out on the transparent theme, then composited onto a generated wrist (see "Green screen faces") |
| Watch screenshots for the listing | Square, opaque `wear_NN_*` renders of the watch UI alone, no mask or frame (see "Wear OS") |
| Lock Screen accessories | Rarely worth showing. The Android story is the home screen, the shade and the status bar |
| Apple bezel PNG | No official frames. A plain rounded rect phone in the page layer, frozen once approved |
| Status bar chrome | Measured from a real emulator capture in SystemUI demo mode, then frozen in the page layer |
| `AppLanguage.select` | `DeviceConfig.locale` per market, `LocalLayoutDirection` for RTL, the JVM default locale |

### Glance widgets in Paparazzi

```kotlin
val views = runBlocking { GlanceRemoteViews().compose(context, size) { MyWidgetContent(state) }.remoteViews }
val host = AppWidgetHostView(context).apply {
    addView(views.apply(context, this), FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT))
}
paparazzi.snapshot(host, name = "widget_list_big")
```

- Render the widget at the size a launcher actually gives it (a Pixel 6: 2x2 is 179 x 203 dp, 2x3
  179 x 310, 4x2 374 x 203, 4x3 374 x 310, 4x4 374 x 417), not its minimum size, where real
  layouts clip.
- Factor the widget so its content composable takes plain state and a clock. `provideGlance`
  reads storage and the network, which a test must not.
- `GlanceRemoteViews.compose` runs one composition and translates it. Effects that finish later (an
  image load) never reach the result. Pass decoded bitmaps in, or compose twice: the first pass
  starts the loads and fills a cache, the second draws from it.
- Fonts: RemoteViews can only name a font family the device has (`sans-serif`,
  `sans-serif-medium`, `sans-serif-condensed`). A bundled font cannot reach a widget, so the render
  must not show one either. To choose between families, render a side sheet with each, do not
  guess.

### Notifications and the status chip

The custom content of a notification is the app's own RemoteViews layout. Fill it with the same
setters the app's notification code uses (share that function), apply it in a `FrameLayout`, and
host that in a Compose `AndroidView`. The frame around it (small icon, app name, time, chevron,
actions) is system chrome. Layoutlib cannot inflate the framework's notification templates, so
redraw that frame at the system's own metrics, and say in your report that it is a redraw. The
Android 16 Live Update chip is drawn by SystemUI, not the app, so it is a redraw too: a 24 dp tall
pill, at most 96 dp wide, in `system_accent1_100` with `system_accent1_900` content.

### Material You from a wallpaper

Layoutlib carries the wallpaper support behind Android Studio's preview "Wallpaper" option. When a
session has `RenderParamsFlags.FLAG_KEY_WALLPAPER_PATH` set to a classpath image, it extracts the
seed and runs the real tonal-spot scheme into `android.R.color.system_*`. Draw a solid PNG of your
page's seed colour, point the flag at it, and the widget's `GlanceTheme` colours match a phone with
that wallpaper. Paparazzi `2.0.0-alpha05` has no API for render flags, so `StoreArtSupport.kt` sets
the flag by reflection on Paparazzi's shared session builder before `unsafeUpdateConfig`. **This is
fragile**: it reaches into Paparazzi internals and can break on any release. Render each widget
with and without it (the `-dyn` ids), so a broken flag shows up as two identical images.

### Wear OS

Only if the app ships a Wear OS app or tile, and the config's `surfaces` lists `wear`. Otherwise
skip this section: the Wear tests are skipped and nothing Wear is staged.

A watch shows up in two places, and they need different renders.

1. **On a phone slot** (a watch on a wrist, as atmosphere): the round tile face as a cut-out on the
   transparent theme, composited onto generated art. See "Green screen faces".
2. **In the Wear OS listing** (Play Console, the Wear OS form factor): raw screenshots of the watch
   UI. Play's rules: 1:1, at least 384 x 384 px, no alpha, and only the app's interface. No watch
   frame, no round mask, no wrist, no background, no added text. The watch draws its UI round, but
   the screenshot is the square around it, filled with the UI's own black.

`templates/android/storeart/src/test/.../WearSurfacesTest.kt` renders the listing set:
`wear_01_tile` and `wear_02_list`, 192 dp square at 3x (576 x 576 px). The snapshot handler writes
every `wear_` id on black without alpha, and `tools/stage-play.sh` copies them in name order to
`images/wearScreenshots/` (`NO_WEAR=1` skips them, `WEAR_SIZE` sets the size it verifies).

- **Compose for Wear OS** screens render in Paparazzi like any composable. Keep the content inside
  the round safe area; the corners stay black.
- **Tiles built with ProtoLayout** are not Compose. Render a Compose mirror from the same state and
  say in the report that it is a redraw, or capture the tile on a Wear OS emulator that has no
  account and no data of the user's (`adb exec-out screencap -p`). A capture is the real thing, so
  prefer it when the tile's look is hard to mirror.
- Show a few distinct states (a tile, a list, a detail), not the same screen twice. Use the same
  world as the phone set, so the numbers agree.
- Wear screenshots carry no generated art, so they need no AI label in the Play declaration.

## What broke

Every row cost at least one wasted render. The fix column is what shipped.

| Symptom | Cause | Fix |
|---|---|---|
| Widget list (Glance `LazyColumn`) renders empty | RemoteViews collections only fill inside an `AppWidgetHostView` | Apply the RemoteViews with an `AppWidgetHostView` as the parent |
| Applied widget crashes or its images are missing | AppCompat's inflater swaps in `AppCompatImageView`, which RemoteViews cannot drive | `Paparazzi(appCompatEnabled = false)` |
| `BitmapFactory.decodeFile` returns null or throws | It calls `fstat` through libcore, which layoutlib does not back | Read the bytes, then `BitmapFactory.decodeByteArray` |
| The JVM aborts mid-run, no stack trace | Images decoded on Coil's background threads inside layoutlib | Decode every image on the test thread first and serve them from a map |
| Images blank, test passes | A URL the test has no file for | The preview handler throws for a missing file, and `@After` asserts there were no misses |
| Entrance animation frozen at frame zero | A single snapshot at an offset does not advance `LaunchedEffect` animations | `paparazzi.gif(start = 0, end = settle)`, keep the last frame |
| Screen crashes on `rememberLauncherForActivityResult` | No activity, so no `ActivityResultRegistryOwner` | Provide a no-op `LocalActivityResultRegistryOwner` |
| A 12 hour market shows "21:41" | Time formatting follows the host setting | A `LocalUse24HourClock` CompositionLocal the app's formatting reads, set from the market |
| Dates in the wrong zone or language | Formatting reads the JVM defaults | `TimeZone.setDefault` and `Locale.setDefault` from the market in `@Before` |
| A wide surface (4x2 widget) is laid out wrong | Layoutlib lays a portrait screen out tall side down | `orientation = LANDSCAPE` when the width exceeds the height |
| Right-to-left strings in a left-to-right layout | Library modules have no `android:supportsRtl` | `LocalLayoutDirection provides LayoutDirection.Rtl` around the Compose content, and `Paparazzi(supportsRtl = true)` for Views |
| Notification frame does not inflate | Framework notification templates fail in layoutlib | Redraw the frame; the content stays the app's RemoteViews |
| Widget colours are the default palette, not Material You | No wallpaper in the session | The wallpaper flag above, with a solid seed PNG on the test classpath |
| A widget font change does nothing | RemoteViews cannot load bundled fonts, and Glance's text appearance span beats a TextView typeface | System families only, through Glance `TextStyle(fontFamily = FontFamily("sans-serif-medium"))` |
| A near-black image vanishes on a dark widget | Contrast close to 1:1 | Detect images that are dark all over and bake a thin light halo into the bitmap (RemoteViews cannot tint per theme). The same check can drive an outline in the Compose image |
| A screen with time-based state differs between runs | `System.currentTimeMillis()` in a render path | A clock seam, set from the world |
| Totals disagree between the widget and the list screen | Aggregates typed in by hand per surface | Compute every aggregate from records in one seeded engine |
| A page written per market breaks for the next market | Surface ids named after one market's content | Role ids (`widget_primary_big`, `card_live`), one page for every market |
| `Plugin request ... already on the classpath with a different version` on the first build | The root build already loads AGP, Kotlin or Paparazzi (`plugins { ... apply false }` or a buildscript classpath) at another version than the catalog snippet | Set the catalog's `agp`, `kotlin` and `paparazzi` to exactly the root build's versions |
| `Unknown command-line option '--tests'` on `:storeart:test` | In an Android module `test` is an aggregate of the variant test tasks and takes no filter | `./gradlew :storeart:testDebugUnitTest --tests '*WorldsTest'` |
| Every test "passes" in seconds, `testDebugUnitTest NO-SOURCE`, no PNGs | The build opted out of AGP 9 built-in Kotlin (`android.builtInKotlin=false`), so a module with no Kotlin plugin compiles no Kotlin | Apply `kotlin.android` in the module; the build file now fails loudly when it is missing |
| `Unresolved reference 'BufferedImage'` / `'imageio'` in the test sources | Without built-in Kotlin, unit tests compile against `android.jar` only (`-no-jdk`) | Set `compilerOptions.noJdk = false` on the unit test Kotlin compilations (the build file does it when built-in Kotlin is off) |
| Text on a dark screen render is black, only explicitly coloured text shows | A composable drawn without its Scaffold or Surface gets the default `LocalContentColor`, black | The snapshot provides `LocalContentColor` from the theme's `onBackground` |
| Right to left widget (applied RemoteViews) keeps its left to right column order; amounts run into names | Layoutlib resolves Views left to right unless the app supports RTL, and a library module has no `android:supportsRtl`; setting `layoutDirection` alone does nothing | `Paparazzi(supportsRtl = true)`; left to right markets are unaffected |
| A watch line (the clock under the amount, a fourth list row) is missing, no error | Content taller than the round safe area of a 192 dp square is clipped, not flagged; scripts with tall glyphs need more room | Budget the column against about 136 dp, show fewer rows, ellipsize names, keep long amounts off the list rows |
| On the lock screen slot the live card covers the bottom of the widget | Fixed tops for stacked renders; a render's height depends on the app and the script | Stack the renders in a flex column with a gap, never at fixed tops |
| On the feature graphic a widget sits under the headline | Widgets placed toward the middle; the headline's width differs per language | Keep the widgets in the corners, clear of the headline's band |
| A surface removed from `surfaces` still shows up in the page kit | The export merged new renders into `ui/<market>/` | The export replaces `ui/<market>/` on every run |

## The page layer

Pick one and keep it.

- **Compose**, in the same module: port `templates/ios/StoreArtPage.swift`. A 1080 x 1920 device
  config, text placed by baseline with `Modifier.paddingFromBaseline`, headline widths measured
  with `TextMeasurer` in a test that fails above the limit.
- **HTML and headless Chrome**, when the project already has an HTML pipeline or a designer works
  in CSS. `templates/android/page/` is the proven kit: `slots.html` places the render PNGs and the
  art by pixel, `kit.js` reads the config, `copy.js` holds the copy per store locale, `header.html`
  is the feature graphic.
  - `--headless=new --force-device-scale-factor=1 --window-size=1080,1920
    --virtual-time-budget=8000 --allow-file-access-from-files --screenshot=...`. The virtual time
    budget lets the config, web fonts and images load; the file access flag lets a `file://` page
    fetch the config. The page measures only after its fonts have loaded.
  - **Width test**: the page measures every headline line's bounding box and writes `WIDTH OK` or
    `OVERFLOW ...` into `document.title`. `tools/widthtest.sh` reads it with `--dump-dom` for
    every locale in the config and exits 1 on any overflow. It de-duplicates locales (a repeated
    argument or a shared store locale tests once). `tools/widthtest.sh --negative` forces an
    overflow in every locale (`&overflow=1`) and fails if any passes: run it once per new locale,
    or a test that can never fail looks the same as one that passes.
  - **Feature graphic**: author at 2048 x 1000 and downsample to 1024 x 500. A 1x render gives
    soft type.
  - Chrome screenshots can carry an alpha channel. Flatten before export
    (`magick in.png -background white -alpha remove -alpha off out.png`); the render scripts do it.
  - A missing render shows as a labelled placeholder box, so a page can be laid out before every
    surface exists.
  - `tools/render-all.sh all` writes every slot and the feature graphic, for every locale.
    `VARIANTS="straight"` adds alternate versions of slot 1 (`01-straight.png`), and
    `stage-play.sh --variant <name>` ships one in place of `01.png`.

### Localising the page

- **Market from the config.** The page looks up the market by `storeLocale`: render folder, clock,
  direction, date line, font. Nothing in the page names a language.
- **Fonts for the script.** When the display faces lack a script, load a face that covers it, with
  explicit weights (the config's `fontFamily` and `fontWeights`), and wait for each weight
  (`document.fonts.load`). A weight that is not loaded is synthesised: a smeared fake bold that also
  measures differently in the width test.
- **Right to left.** `dir="rtl"` on the slot mirrors margins, the pill padding and the tile order
  (kit.css). Renders are never mirrored: the app laid them out for the market already. The status
  bar stays as on a phone. The width test must measure an RTL line from its **left** edge
  (`1080 - left`), because it grows leftwards; measuring the right edge passes every overflow.
- **Figures in RTL.** A figure like "-12%" in a right-to-left line can render as "%12-" unless it is
  isolated: `direction: ltr; unicode-bidi: isolate` (the `.num` class). Check it in the render.
- **Date and clock.** The date line comes from `Intl.DateTimeFormat(languageTag)`, with
  `-u-nu-latn` when the market wants Western digits. The clock comes from the config's moment and
  `clock24h`. Android's status bar shows no AM/PM.
- **Room-aware decoration.** An object that sits next to the headline is placed only when the
  headline leaves room for it. Measure the line after the fonts load; never hard-code it per
  locale, because translations are usually longer than the source and the next one will collide.
- **Per-market art by file name.** `art/hero/<code>.jpg` and `art/avatars/<code>/` with a
  `default` fallback: a market gets art that fits it without a code change.

### Status bar chrome

Measure it, do not draw it from memory. On an emulator with no account and no app of yours:

```bash
adb shell settings put global sysui_demo_allowed 1
adb shell cmd uimode night yes
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4
adb shell am broadcast -a com.android.systemui.demo -e command network -e mobile show -e datatype none -e level 4
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false
adb exec-out screencap -p > chrome/ref-dark.png
```

Read the clock's left edge, cap height and centre line, and the icon row's right edge with
`scripts/probe.swift`, write them as constants scaled to the phone width, and freeze them. Use
`cmd uimode night no` for the light capture. A 24 hour market reads "21:41" (`-e hhmm 2141`).

### Green screen faces

For a watch on a wrist (or a phone in a hand), generate the photo with the face as flat `#00FF00`,
measure the green with `swift scripts/greenbox.swift photo.png` (box, centre, size), then place the
real round tile render over it with a circular mask at about 1.035 times the measured diameter, so
no green fringe survives. Record the measured box in the provenance file.

## Canvas and Play specs

Google Play requires each side between 320 and 3840 px, the long side at most twice the short side,
JPEG or 24-bit PNG, no alpha, at most 8 MB each, and 2 to 8 phone screenshots (verify on the current
Play Console help page). A 20:9 phone screen is not a valid screenshot as it is: author the slot at
**9:16**, 1080 x 1920. The production set used 1080 x 1920 slots and a 1024 x 500 feature graphic.

- The **feature graphic** is required to publish: 1024 x 500, no alpha, key content away from the
  edges.
- **Claims** (user counts, ratings, awards) are not in the template. Add one only when the
  developer asks and can back it; Play may treat it as a policy risk even when true
  (`references/style-and-copy.md`, "Claims and store rules").
- **Wear OS** screenshots: 1:1, at least 384 x 384 px, raw watch UI only (see "Wear OS"). They
  go in the Wear OS listing, not among the phone screenshots.
- **People**: illustrated avatars only (clay, cartoon), never photoreal people who look like real
  customers. Record them as illustrations in the provenance file.

## Delivery

1. `tools/render-all.sh <locales>` then `tools/stage-play.sh [--variant <name>] [locales]`. It
   builds `out/play/<locale>/images/phoneScreenshots/01..NN.png` and `featureGraphic.png` from
   `out/`, in name order, adds `wearScreenshots/` from `ui/<code>/wear_*.png` when they exist,
   refuses fewer than 2 or more than 8 phone screenshots, and runs `verify-export.sh` on the tree.
2. Paste `templates/fastlane/Fastfile.android.snippet.rb` into the Android platform block. Its
   `upload_art` lane uploads images only (no APK or AAB, no metadata, no changelogs,
   `sync_image_upload`), reads the allow list from the config (`"upload": true`), refuses a locale
   that is unknown, not approved or not staged, and uploads from a temporary tree that holds only
   the requested locales, so no other locale is touched.
3. Dry run first: `fastlane upload_art locales:en-US validate_only:true`. Play validates the edit
   and changes nothing.
4. **The developer runs the real upload, not the agent.** Hand over the exact command.
5. Pull the listing back (Play Console, or `fastlane supply init` into a scratch folder) and compare
   it with `out/play`. A success line is not proof.

What to know before step 4:

- Play has **no draft for listing art**. Images go live once the edit commits.
- The language must already exist on the store listing (add it in Play Console), or the edit fails.
- `supply` replaces that locale's images of each uploaded type: every phone screenshot, the feature
  graphic. It does not merge with what is there.
- fastlane may be a Homebrew install with no Gemfile. Then run `fastlane`, not `bundle exec`.
- Play's locale codes differ from App Store codes (check Play Console's list); the config's
  `storeLocale` is the Play one.

`supply` reads `<locale>/images/` with `phoneScreenshots/`, `sevenInchScreenshots/`,
`tenInchScreenshots/`, `wearScreenshots/`, `featureGraphic.png` and `icon.png` (512 x 512, 32-bit with alpha, so check
it on its own). Check the supply docs for current names, ordering and limits.

## First-run checklist

1. Copy `storeart.config.json` to `store/`, `page/` to `store/page/`, `storeart/` to the repo root.
2. `python3 storeart/scripts/fetch_logos.py` fetches every URL in `logos.json`.
3. `./gradlew :storeart:testDebugUnitTest --tests '*WorldsTest'` passes and prints each market's world.
4. `./gradlew :storeart:recordPaparazziDebug -Pstoreart.markets=all` writes the sample card, widget
   and screen to `storeart/build/storeart/<market>/`, light and dark, for both example markets.
5. Open each PNG. The card and the widget corners are transparent; the screen is opaque; the RTL
   market is laid out right to left.
6. Swap the sample screen for one real composable fed from the world. No network, no account.
7. `storeart/scripts/export.sh all`, `store/page/tools/widthtest.sh`, `widthtest.sh --negative`,
   `render-all.sh all`, `stage-play.sh`. Open the slots; `verify-export.sh` passes.
8. If the app has a Wear OS app: open `wear_01_tile.png` and `wear_02_list.png`; both are square,
   opaque and show only the watch UI.

Anything new that breaks goes into "What broke" above, with the fix.
