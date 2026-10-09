# Architecture

## Why code, not a design tool

A design file is a snapshot. A render target is a function: `(story, locale, market) -> PNG`.

- Localizing is a loop over a table, not 22 hand edits that drift.
- App screens are the app's own views, so they cannot be out of date or subtly wrong.
- A change to the pill, the margin or the status bar is one edit and a rerender of every slot.
- Everything diffs in git except the pixels, and the pixels regenerate.

Figma is still right when a human designer owns the creative. Then this skill supplies the real
screens and the export checks, and the layout lives in Figma. Ask before choosing.

## Render, or capture?

| Use | When |
|---|---|
| **Render** (host-less test target) | Default. Widgets, Live Activities, Dynamic Island, Watch complications, Siri snippets, Lock Screen, and any screen whose views build from a model |
| **Capture** (fastlane `snapshot`, UI tests) | A full-app flow you cannot rebuild from a model, and only if the app has a screenshot mode: bundled sample data, frozen clock, no network, no sign-in, no sync, no alerts |

The project this comes from planned both and ended up rendering everything. A capture that signs in
or syncs is how a real account gets damaged, so a capture path needs a screenshot mode first.

## The pieces

```
StoreArt/                       the host-less test target (iOS) or a Gradle test source set (Android)
  StoreArtKit.swift             canvas, render(), fonts, placement helpers, bundle forwarding
  StoreArtChrome.swift          status bar, device bezel (system chrome, not app UI)
  StoreArtPage.swift            palette, background, headline, pill, body lines
  <Slot>.swift                  one file per slot: Copy.all (per locale), Story (data), View
  StoreArtRenderTests.swift     one testXxx per slot, plus width tests and a pipeline check
  SampleData/                   real payloads as JSON, per market; images are re-fetched, not committed
  Fonts/<Family>/               static instances beside their licence
  Art/<slot>/                   generated art, each with a .txt of how it was made
  Art/bezels/                   Apple bezels, gitignored (licence)
  Output/                       renders, gitignored
scripts/screenshots/
  render.sh                     runs one test on the dedicated simulator
  tools/                        chromakey, compare, probe, fetch_*.py, ppo.rb
screenshots.yml                 single source of truth: markets, slots, upload allow list
docs/screenshots/               brief, references, rejected attempts
fastlane/                       lanes and metadata
```

## The slot pattern

Every slot has the same three parts, so adding a market or a slot is mechanical.

1. **Copy table**: `Slot03Copy.all`, one entry per locale: headline lines, the pill word, body
   lines. Hand-written per locale. Never machine-translated.
2. **Story**: the data one market shows: its own sample content, time zone, language. Built from
   sample data fetched once from the real API, so the picture is true.
3. **View**: the layout. Identical across locales; only the copy and the story change.

A test per slot loops the table and renders `default_<locale>_iphone_<NN>.png`. A
`STOREART_MARKET` environment variable (`TEST_RUNNER_STOREART_MARKET` when you launch it through
`xcodebuild`) limits the loop to a comma list of locales, or `all`. The default is the first market only.

Width tests sit beside the render tests. They measure every headline line at the full size and fail
over the limit, which is what stops a late translation from quietly shrinking type.

## File naming

`<page>_<locale>_<placement>[_<nn>].png`

- `default_en-US_iphone_03.png` goes to the default product page, slot 3.
- `cpp-<theme>_en-US_iphone_02.png` goes to a custom product page.
- `default_ja_header.png` is the 3840 x 1646 product page header.

Locales are the store's own codes, the same folders fastlane metadata uses. Keep one manifest
(`templates/fastlane/screenshots.yml`) listing markets, slots, and which locales are approved for
upload. The upload lane refuses any locale not on that list.

## The world

Pick one moment and make every device live in it: date, clock time, time zone, and the data your app shows
(a score, a balance, a delivery ETA). The Lock Screen says 9:41, the Live Activity says the same figure
as the widget, the Watch shows the same state. Mismatched numbers are the fastest way a set reads as fake. Use real payloads,
then overlay the storyboard where reality is boring, and write down exactly what you overlaid.

## Decision log

Keep `docs/screenshots/` as the memory of the project: the brief, the reference crops, a
`rejected/` image per direction that failed (so it is never repeated), and a dated line for each
decision with the reason. The agent that picks this up next month has only this.
