# Android: the Jetpack Compose render target

**Status: designed from the iOS pipeline, not yet run by the authors.** The iOS side is proven in
production. This page carries the same contract over to Compose and the Play Store. Treat Gate 0 on
Android as a real experiment: prove one slot end to end, then write what broke back into this file.
Where a fact below comes from outside the project it is marked, and must be verified against the
current docs before you rely on it.

To start: `templates/android/START-HERE.md` has a prompt that ports the iOS template into your project.

## The contract is identical

The four layers do not change: real composables fed with sample data (truth), Higgsfield art (atmosphere),
page type and layout in Compose (page), fastlane `supply` (delivery). So do the hard rules: never
drive the user's real app or a signed-in emulator; one market first; headlines never shrink; every
generated asset has a provenance file.

## Host-less rendering

The Android equivalent of the iOS host-less bundle is a JVM screenshot test that renders composables
without an emulator or device.

- **Paparazzi** (`app.cash.paparazzi`) renders through layoutlib on the JVM. Tests live in the
  module's unit test source set and call `paparazzi.snapshot { Slot() }`. A custom `DeviceConfig`
  sets pixel size and density. Verify the constructor against the version you use, since parameter
  names have changed between releases. Paparazzi releases pin a Gradle, compileSdk and JDK range, so
  check the release notes first.
- **Roborazzi** (Robolectric based) is the alternative when you already run Robolectric. Compose UI
  tests can capture with `captureToImage()`.
- Google's own Compose Preview Screenshot Testing plugin exists as an alternative. It was
  experimental when last checked.

Pick whichever the project already uses. Do not add two.

## Canvas

Google Play requires each side between 320 and 3840 px, the long side at most twice the short side,
JPEG or 24-bit PNG, no alpha, at most 8 MB each, and 2 to 8 phone screenshots (third-party summaries
of Google's rules, verify on the current Play Console help page). So a 20:9 phone screen is not a valid
screenshot as it is: author the slot at **9:16**, for example 1080 x 1920 (360 x 640 dp at 3.0x) or
1440 x 2560.

The app screen inside the slot is a different canvas. Render the app composable at a realistic phone
size, such as 412 x 915 dp, then scale it into the device frame, as `StraightPhone` does on iOS with
`scaleEffect`. In Compose use `Modifier.graphicsLayer { scaleX = s; scaleY = s; transformOrigin = TransformOrigin(0f, 0f) }` or lay the screen out inside a `Box` and scale it.

## Pixels, density, baselines

- Write specs in pixels and convert once: `fun Int.px(density: Density) = with(density) { toDp() }`.
  Keep `Density` fixed (fontScale 1.0) in the test so Dynamic type equivalents never move text.
- Place text by baseline with `Modifier.paddingFromBaseline(top = ...)` or an explicit `Layout` with
  `FirstBaseline`. The compare loop depends on baselines, so do not place by top edge.
- Tracking is `letterSpacing = (-0.02).em` on the headline.
- Fonts: bundle static TTFs in `res/font/` or load them from the test's resources, then define a
  `FontFamily` per face. A missing font silently falls back; assert it in a test.
- Measure headline widths with `TextMeasurer` in a unit test and fail above the limit, same as iOS.

## Differences that matter

| iOS | Android |
|---|---|
| Widgets (WidgetKit) | Glance widgets. Render the Glance composition's content as a composable stand-in, or screenshot the widget host if the project already tests it |
| Live Activity, Dynamic Island | Ongoing notification or a Live Update. Render the notification layout from the app's own RemoteViews or Compose content |
| Lock Screen accessories | Rarely worth showing. The Android story is usually the home screen and notification shade |
| Apple bezel PNG | No official frames. Prefer no frame, or a simple rounded rect, since Play expects real UI |
| Status bar chrome | Draw a minimal one from a real emulator screenshot, 9:41 and full battery, and freeze it |
| `AppLanguage.select` | Set the locale through the test's configuration or `LocalConfiguration`; verify strings and number formats change |

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

(Layout from fastlane supply's convention as summarised by third-party guides. Check the supply docs
for current names, file-name ordering and limits.)

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

The Play feature graphic is required to publish and is 1024 x 500, no alpha. It is a brand image like
the iOS header: no UI, no ratings, key content away from the edges.

Run `scripts/verify-export.sh fastlane/metadata/android 1080x1920` (add every size you ship) before
any upload, and pull the listing back to compare after.

## First-run checklist

1. A Paparazzi or Roborazzi test renders the sample slot at 1080 x 1920, opaque.
2. Fonts register and a missing font fails the test.
3. A real app composable fed with sample data renders without a network or an account.
4. The same slot renders in two locales with different strings and number formats.
5. `verify-export.sh` passes, `supply` uploads one locale to a track that is not production, and the
   console shows it.

Anything that fails goes into this file under a "What broke" heading with the fix.
