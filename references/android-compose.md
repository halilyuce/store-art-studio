# Android: the Jetpack Compose render target

**Status: proven on one production app.** A Paparazzi module rendered that app's real composables,
its real Glance widgets, its real notification layout and its Wear tile face from a frozen world,
and an HTML page layer turned them into a full Play set (8 phone slots and a feature graphic, in 11
locales including Arabic). `templates/android` is that module and that page kit with the app taken
out. The generic copy has not been run as it is, so expect a version or an import to need a touch
on your first build. Every trap below was hit for real, and the fix is the one that shipped.

To start: `templates/android/START-HERE.md`.

## The contract is identical

The four layers do not change. Neither do the hard rules: never drive the user's real app or a
signed-in emulator; one market first; headlines never shrink; every generated asset has a
provenance file.

| Layer | On Android |
|---|---|
| Truth | The app's own composables, Glance widgets and RemoteViews layouts, rendered by Paparazzi (layoutlib on the JVM) from a frozen world. No emulator, no device, no network, no account |
| Atmosphere | Higgsfield art, keyed and placed by the page layer (`references/higgsfield-art.md`) |
| Page | Compose in the same test module, or an HTML page rendered by headless Chrome. Both work. The production set used HTML because the project already had an HTML pipeline |
| Delivery | fastlane `supply`, or the Play Console by hand, to a track that is not production |

The split that worked: the render module writes one PNG per surface (a screen, a widget at one
size, a notification card, a status chip, a watch face), often on a transparent background, in
light and dark. The page layer only places those PNGs and the art. It never draws app UI.

## The render module

`templates/android/storeart/` is a test-only Gradle library module. It depends on the app modules
that hold the composables you show, and nothing depends on it.

- **Paparazzi `2.0.0-alpha05`** ran on AGP 9 with compileSdk 36 and 37 (built-in Kotlin plus the
  Compose compiler plugin). Paparazzi pins a Gradle, compileSdk and JDK range per release, so read
  the release notes before you pick a version. Roborazzi is the alternative if the project already
  runs Robolectric. Do not add both.
- `./gradlew :storeart:recordPaparazziDebug` runs every test. The template's snapshot handler
  writes `build/storeart/<market>/<id>.png` directly, alpha kept. The renders are the output, not
  goldens, so record and verify runs write the same files.
- Tests run with the module folder as the working directory, so `logos.json` and
  `src/test/resources/logos/` are read by relative path.

### The render recipe

1. **Device.** `DeviceConfig.PIXEL_6.copy(...)` with `screenWidth = widthDp * 3`,
   `screenHeight = heightDp * 3`, `density = XXHIGH`, `xdpi = ydpi = 480`, `fontScale = 1f`, the
   market's `locale`, `nightMode`, `softButtons = false`. Full screens are 412 x 915 dp (a Pixel's
   content area), so a screen render is 1236 x 2745 px. Resize the device per surface with
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
   by the SHA-1 of the URL. A URL with no file fails the test. A blank logo must never ship.
6. **The world.** One data object per market (`SampleWorld.kt`), see below.
7. **Widgets and notifications** go through RemoteViews, see "Surfaces".

### The frozen world

Every surface reads one object per market: date, clock, time zone, locale, 12 or 24 hour clock,
and every row of data the screens show. Then the widget, the screen and the notification agree.

- `now` is a constant (`ZonedDateTime.of(2026, 10, 11, 9, 41, 0, 0, zone)`). Nothing in a
  rendered code path may call `System.currentTimeMillis()`. Where app code reads the clock, add a
  seam (a parameter or a CompositionLocal) that defaults to the system clock and that the test
  sets.
- **12 or 24 hours** comes from a CompositionLocal (`LocalUse24HourClock`, `null` means the device
  setting) that the app's time formatting reads. Without it the render follows the host, and a US
  slot can show "21:41".
- Set the JVM defaults too (`TimeZone.setDefault`, `Locale.setDefault`): formatting code that does
  not take a locale reads them.
- **Full, plausible data.** A table with three rows or a list with one item reads as broken in
  store art. Invent complete tables and schedules that add up (totals match the rows, the same
  figure everywhere). Invented, not real: no real people. If the app shows third-party names or
  marks, check the right to show them in marketing, which is separate from the right to show them
  in the app.

## Surfaces

| iOS | Android, as proven |
|---|---|
| Widgets (WidgetKit) | The real Glance widget: compose with `GlanceRemoteViews`, apply the RemoteViews inside an `AppWidgetHostView`, snapshot the view. No redraw |
| Live Activity, Dynamic Island | The app's own notification RemoteViews layout, applied the same way, inside a redrawn system frame. The Android 16 Live Update status-bar chip is redrawn too |
| Material You | Layoutlib's built-in wallpaper support, seeded with a solid colour, runs the real dynamic colour pipeline, so `GlanceTheme` and `system_accent*` colours come out as on a phone |
| Watch face, complication | The Wear tile face rendered as a round cut-out on the transparent theme, then composited onto a generated wrist (see "Green screen faces") |
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
paparazzi.snapshot(host, name = "widget_big")
```

- Render the widget at the size a launcher actually gives it (a Pixel 6: 2x2 is 179 x 203 dp, 2x3
  179 x 310, 4x2 374 x 203, 4x3 374 x 310, 4x4 374 x 417), not its minimum size, where real
  layouts clip.
- Factor the widget so its content composable takes plain state and a clock. `provideGlance`
  reads storage and the network, which a test must not.
- `GlanceRemoteViews.compose` runs one composition and translates it. Effects that finish later (a
  logo load) never reach the result. Pass decoded bitmaps in, or compose twice: the first pass
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

## What broke

Every row cost at least one wasted render. The fix column is what shipped.

| Symptom | Cause | Fix |
|---|---|---|
| Widget table (Glance `LazyColumn`) renders empty | RemoteViews collections only fill inside an `AppWidgetHostView` | Apply the RemoteViews with an `AppWidgetHostView` as the parent |
| Applied widget crashes or its images are missing | AppCompat's inflater swaps in `AppCompatImageView`, which RemoteViews cannot drive | `Paparazzi(appCompatEnabled = false)` |
| `BitmapFactory.decodeFile` returns null or throws | It calls `fstat` through libcore, which layoutlib does not back | Read the bytes, then `BitmapFactory.decodeByteArray` |
| The JVM aborts mid-run, no stack trace | Images decoded on Coil's background threads inside layoutlib | Decode every image on the test thread first and serve them from a map |
| Images blank, test passes | A URL the test has no file for | The preview handler throws for a missing file, and `@After` asserts there were no misses |
| Entrance animation frozen at frame zero | A single snapshot at an offset does not advance `LaunchedEffect` animations | `paparazzi.gif(start = 0, end = settle)`, keep the last frame |
| Screen crashes on `rememberLauncherForActivityResult` | No activity, so no `ActivityResultRegistryOwner` | Provide a no-op `LocalActivityResultRegistryOwner` |
| A 12 hour market shows "21:41" | Time formatting follows the host setting | A `LocalUse24HourClock` CompositionLocal the app's formatting reads, set from the market |
| Dates in the wrong zone or language | Formatting reads the JVM defaults | `TimeZone.setDefault` and `Locale.setDefault` from the market in `@Before` |
| A wide surface (4x2 widget) is laid out wrong | Layoutlib lays a portrait screen out tall side down | `orientation = LANDSCAPE` when the width exceeds the height |
| Arabic strings in a left-to-right layout | Library modules have no `android:supportsRtl` | `LocalLayoutDirection provides LayoutDirection.Rtl` around the Compose content |
| Notification frame does not inflate | Framework notification templates fail in layoutlib | Redraw the frame; the content stays the app's RemoteViews |
| Widget colours are the default palette, not Material You | No wallpaper in the session | The wallpaper flag above, with a solid seed PNG on the test classpath |
| A widget font change does nothing | RemoteViews cannot load bundled fonts, and Glance's text appearance span beats a TextView typeface | System families only, through Glance `TextStyle(fontFamily = FontFamily("sans-serif-medium"))` |
| A near-black logo vanishes on a dark widget | Contrast close to 1:1 | Detect logos that are dark all over and bake a thin light halo into the bitmap (RemoteViews cannot tint per theme). The same check can drive an outline in the Compose image |
| A screen with time-based state differs between runs | `System.currentTimeMillis()` in a render path | A clock seam, set from the world |

## The page layer

Pick one and keep it.

- **Compose**, in the same module: port `templates/ios/StoreArtPage.swift`. A 1080 x 1920 device
  config, text placed by baseline with `Modifier.paddingFromBaseline`, headline widths measured
  with `TextMeasurer` in a test that fails above the limit.
- **HTML and headless Chrome**, when the project already has an HTML pipeline or a designer works
  in CSS. `templates/android/page/` is the proven kit: `slots.html` places the render PNGs and the
  art by pixel, `copy.js` holds the copy per locale, `header.html` is the feature graphic.
  - `--headless=new --force-device-scale-factor=1 --window-size=1080,1920
    --virtual-time-budget=6000 --screenshot=...`. The virtual time budget lets web fonts load; the
    page measures only after `document.fonts.ready`.
  - **Width test**: the page measures every headline line's bounding box (the right edge, or the
    left edge in RTL) and writes `WIDTH OK` or `OVERFLOW ...` into `document.title`.
    `tools/widthtest.sh` reads it with `--dump-dom` for every locale and exits 1 on any overflow.
  - **Feature graphic**: author at 2048 x 1000 and downsample to 1024 x 500. A 1x render gives
    soft type.
  - Chrome screenshots can carry an alpha channel. Flatten before export
    (`magick in.png -background white -alpha remove -alpha off out.png`); the render scripts do it.
  - A missing render shows as a labelled placeholder box, so a page can be laid out before every
    surface exists.

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
- **User-count badges** ("50K+ fans") are a Play metadata policy risk even when true. Keep a
  variant of the slot without the badge and let the user choose.
- **People**: illustrated avatars only (clay, cartoon), never photoreal "fans" who look like real
  customers. Record them as illustrations in the provenance file.

## Delivery

fastlane `supply` reads `fastlane/metadata/android/<locale>/`:

```
fastlane/metadata/android/en-US/
  title.txt  short_description.txt  full_description.txt
  changelogs/default.txt
  images/
    icon.png                   512 x 512, 32-bit PNG with alpha
    featureGraphic.png         1024 x 500, no alpha
    phoneScreenshots/          01_*.png, 02_*.png ... ordered by name
    sevenInchScreenshots/
    tenInchScreenshots/
```

Check the supply docs for current names, ordering and limits. Play locale folders use Play's codes
(`en-US`, `ar`, `de-DE`, `ja-JP`, `pt-BR`), which differ from App Store codes.

```ruby
lane :upload_play_art do
  upload_to_play_store(
    track: "internal",                    # never production from this lane
    skip_upload_apk: true, skip_upload_aab: true,
    skip_upload_metadata: true, skip_upload_changelogs: true,
    skip_upload_images: false, skip_upload_screenshots: false
  )
end
```

Run `scripts/verify-export.sh` on the screenshot and feature graphic folders before any upload
(`1080x1920 1024x500`; the 512 x 512 icon keeps its alpha, so check it on its own), and pull the
listing back to compare after.

## First-run checklist

1. `python3 storeart/scripts/fetch_logos.py` fetches every URL in `logos.json`.
2. `./gradlew :storeart:recordPaparazziDebug` writes the sample card, widget and screen to
   `storeart/build/storeart/us/`, light and dark, plus the RTL market's screen.
3. Open each PNG. The card and the widget corners are transparent; the screen is opaque.
4. Swap the sample screen for one real composable fed from the world. No network, no account.
5. The same screen in two markets shows different strings, number formats and clocks.
6. `page/tools/render.sh en-US` and `page/tools/widthtest.sh` pass, and `verify-export.sh` passes
   on the output.

Anything new that breaks goes into "What broke" above, with the fix.
