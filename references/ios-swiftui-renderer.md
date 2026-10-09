# iOS: the SwiftUI render target

The files in `templates/ios` compile and render as shipped: 1320 x 2868, opaque, headline and pill
in place, verified on an iOS 26 simulator. Start there, then replace the sample screen with real views.

## Create the target

1. A **Unit Testing Bundle** target named `StoreArt`, with **Host Application: None**. No app is
   installed or launched, which is what makes it safe.
2. Add the template files to it. Add the app's or widget extension's source files to the target's
   membership so the real views are available. Do not add the app's entry point.
3. A shared scheme `StoreArt`, with environment variable `TZ` set to the zone in
   `StoreArt.timeZone`. `setUp` fails when they disagree.
4. Resources the views need (Localizable.strings, asset catalogs) join the target's resources. Call
   `StoreArt.forwardMainBundle()` in `setUp`; see the traps.
5. `scripts/screenshots/render.sh` creates a simulator named "StoreArt iPhone 17 Pro Max" the first time and
   reuses it. Never point it at a simulator that has the app installed.
6. Adding Swift files means editing `project.pbxproj`. **Hand-edit it**: a PBXFileReference, an entry
   in the group, a PBXBuildFile, an entry in the target's Sources phase, fresh 24-hex ids, building
   after each edit. The `xcodeproj` gem re-sorts the file and can drop entries.
7. Build with the project or workspace and **its own DerivedData** (`-derivedDataPath build/...`).
   Sharing Xcode's DerivedData breaks Xcode's next build with a stale module cache error.

Pixels in, points out: the canvas is 440 x 956 pt at 3x. Write specs in pixels and divide by
`StoreArt.scale`. Tracking -2.5% is `.tracking(-0.025 * pt)`.

## Host-less traps (all fail silently)

| Symptom | Cause | Fix |
|---|---|---|
| Strings print as raw keys, images missing | `Bundle.main` is the xctest runner | `StoreArt.forwardMainBundle()` swaps `+[NSBundle mainBundle]`. Overriding `localizedString` alone fixes `.localized` but not `Text("key")` |
| Crash decoding a preview sample | Helpers like `Bundle.main.decode` find nothing | Copy sample data into `StoreArt/SampleData` and decode with `JSONDecoder` |
| Widget has no background | `containerBackground` draws nothing | Paint the 22 pt continuous tile yourself (`WidgetTile`), with the artwork and the dark wash the widget declares |
| Frosted look is flat | Materials do not blur | `.blur` does. Build glass from a blurred copy of the backdrop plus a gradient fill |
| Remote images empty, async content missing | `onAppear`, `.task` and `AsyncImage` never run | Pass images in the model. For widgets, fill the entry's image map the way the provider would |
| Progress bar is a yellow box with a prohibited sign | A UIKit-backed `ProgressView` | A custom `ProgressViewStyle`: capsule track, fill at `fractionCompleted`, inherited tint |
| Progress bar renders zero width | Start time is not in the past | Give the activity a start date earlier in the day in the right zone |
| Text vanishes inside a mask | `luminanceToAlpha` drops dark text | Draw the text white explicitly inside the mask, stack the alpha three times for dim colours |
| Dates show the wrong hour | Formatting follows the process zone (TZ), not `NSTimeZone.default` | `StoreArt.useTimeZone` sets TZ, `tzset`, resets the system zone and the default |
| A second language prints English | The app has its own language switch | Call the app's own switch (for example `AppLanguage.select("tr")`) and set the render's `locale` environment |
| A Watch gauge shows a logo where the watch shows text | The target compiles the iOS branch | Accept it, or compile the watchOS source with a stub. Record which |
| `widgetFamily` cannot be set | It is get-only | Views that read it need a different seam; `activityFamily` is settable |
| Whole slot shifts when one layer is added | `placed(x:)` at a negative or oversize position widens the ZStack | `.placed(x: 0, y: 0).offsetPx(...)` for anything that starts off the canvas |
| A blurred ellipse stack clips too small | A clip shrinks to the widest child | Frame the stack to the shape's size before `clipShape` |
| `.background` with a canvas-size child stretches the view | The child proposes its own size | Put it in `Color.clear.overlay(alignment: .topLeading)` |
| Black seam beside a masked shape | A half-masked fill | Fill the whole shape and mask only the rim glow |
| Device flush against the bottom is off by half the overhang | A centred frame | Render with `.frame(alignment: .topLeading)` (the kit does) |
| Layout moves between locales | Dynamic Type or system fonts | Fixed-size fonts only (`.custom(name, fixedSize:)`) |

## Fonts

Ship static instances, not variable fonts. Variable files from google/fonts become statics with
fonttools: `fonttools varLib.instancer Font[wght].ttf wght=700 -o Font-Bold.ttf`, then check the
PostScript name with `fc-scan` or `UIFont(name:)`. `StoreArtFace.verifyRegistered()` runs in `setUp`
so a missing face fails the run instead of falling back to SF Pro.

CJK and Arabic: the Latin display face has no glyphs, and falling back through the cascade picks the
regular weight. `Font.storeArt(_:px:for:)` switches to the system face at heavy weight for any text
beyond U+058F. Check these headlines by eye; they usually come out narrower or wider than Latin.

## Real data

Fetch once, store as JSON, decode in the test. Per market:

- The payloads your app's own endpoints return, saved under `SampleData/market/<locale>/`.
- Images (logos, avatars, photos) downloaded by a script that scans the sample data for URLs. They are provider
  images, so they are gitignored and rebuilt. Keep the hand-overlaid storyboard JSON tracked, because
  refetching would lose the overlay.
- When the data source returns empty or dull data (an off-season, a new account), lay a storyboard over
  it and write down exactly what you overlaid. Never invent a result; real data decides the outcome.

## System surfaces

**Status bar.** Metrics in `StoreArtChrome.swift` were measured from an iOS 26.5 simulator
screenshot with the status bar overridden to 9:41. Re-measure with `scripts/probe.swift` if the OS
redraws it. After the first approved slot, do not touch it.

**Lock Screen.** Calibrate against a real Lock Screen screenshot of the same OS version: date
baseline, clock top, the gap to the accessory row, button centres. The big clock is SF Pro heavy at a
slightly narrowed width. Accessory widgets are drawn in their vibrant look by turning their own
content white at its luminance.

**Dynamic Island.** The bezel PNG has an idle island baked in opaque. Draw the compact and expanded
activity from the app's own views at the system's sizes, and keep the compact ears clear of the
status icons. If a Siri or activity glow crowds the status bar, fix the glow's spacing, not the icons.

**Home Screen widgets.** `WidgetTile` reproduces the container background. Small, medium and large
sizes on the iPhone 17 Pro Max are 170 x 170, 364 x 170 and 364 x 382 pt.

**Watch.** The Ultra bezel export is small (600 px wide); scaling it past about 1.25x softens it.
Ask for a larger export from Apple's resources, or accept and say so.

**Siri.** On iOS 26 the answer is a snippet view the app already has. Compile that one view against a
stand-in snapshot type with exactly the members it reads, and wrap it in `if #available(iOS 26, *)`.
The glass around it is atmosphere: generate it, do not hand-build it (`higgsfield-art.md`).

## Glass, the rule that took four attempts

Apple's glass is a light layer over a blur, not a dark one. A panel that fades from black to dark
transparent always reads as a grey card. What works: blur the backdrop, then fill with a gradient that
is near-black at the top (where text must stay legible) and crosses to white at 8 to 16% at the
bottom; add a white sheen on the lower half; give it a rim faint at the top and bright round the
bottom, plus a second blurred white stroke masked to the bottom for the lit edge. The colour the glass
shows must exist behind it, so put a bloom of that colour in the scene under the panel.

## RTL and bidi

Mirror the app layout (`rightToLeft` on the screen and tile views), never the status bar. Use
`chevron.backward`. Wrap Arabic headlines left-aligned like the other locales if the reference does.
Glue proper names with no-break spaces so a wrap cannot split them. Check output by eye: bidi
output looks scrambled in a terminal and correct on the canvas.

## Contact sheet

`testPipelineCheck` in the project this comes from renders every widget family, Live Activity and
Siri card on one sheet, light and dark. Make one for your app at Gate 0. It is the cheapest way to
catch every trap above before a real slot depends on them.
