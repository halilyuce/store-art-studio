# Android, end to end

From an Android project to a finished Google Play set: phone screenshots, a feature graphic, and
Wear OS screenshots if the app has a Wear OS app or tile, in every market you choose. Any kind of
app works. You bring the app and your decisions; the skill reads the project, asks, renders and
ships.

Only phone screens are required. Widgets, live notifications, Wear OS and tablet layouts appear
only if your app ships them and you choose to show them.

| You get | Where |
|---|---|
| A brief you can edit | `docs/screenshots/brief.md` |
| Your market list (the only one) | `store/storeart.config.json` |
| Real UI renders, light and dark, per market | `storeart/build/storeart/<code>/` |
| Phone slots (1080 x 1920) and a feature graphic (1024 x 500) | `store/page/out/<locale>/` |
| The staged Play tree | `store/page/out/play/<locale>/images/` |

<p>
  <img src="../assets/examples/android/standings/en-US/01.jpg" width="160" alt="Standings for Android, English, slot 1">
  <img src="../assets/examples/android/standings/en-US/02.jpg" width="160" alt="Standings for Android, English, slot 2">
  <img src="../assets/examples/android/standings/tr-TR/04.jpg" width="160" alt="Standings for Android, Turkish, Wear OS slot">
  <img src="../assets/examples/android/standings/ar/01.jpg" width="160" alt="Standings for Android, Arabic, right to left, slot 1">
</p>

<sub>A finished run on a real app (Standings for Android): Compose, Glance and RemoteViews renders
from Paparazzi, placed by the HTML page kit, with generated backgrounds, avatars and 3D objects.
Your own app's set comes out of the same steps with your screens, design and markets.</sub>

Deep detail lives elsewhere, so this guide stays short:

| Need | Read |
|---|---|
| The workflow and its rules | `SKILL.md` |
| What to copy, the first 30 minutes | `templates/android/START-HERE.md` |
| The renderer, the config fields, every trap with its fix | `references/android-compose.md` |
| Reading a project, the question bank, the brief | `references/discovery.md` |
| Rounds and the decision log | `references/iteration.md` |
| Copy and localization rules | `references/style-and-copy.md` |
| Art: generating, keying, committing | `references/higgsfield-art.md` |
| Upload lane and safety checklist | `references/fastlane-and-delivery.md` |

## Before you start

Tick the checklist in [INSTALL.md](../INSTALL.md): the skill, the Higgsfield MCP, a JDK and a
build that works, Google Chrome, fastlane, a Play service account. Then copy the template and
render its sample once (`templates/android/START-HERE.md`, "The first 30 minutes"). If the sample
renders, the pipeline works in your build.

Every phase below ends with Claude stopping for your approval.

## 1. Discover

Claude reads your project, read only: modules and the version catalog, the navigation graph and
screens, view models, the manifest, Glance widgets, notification layouts, a Wear OS module, string
files per locale, brand colours and fonts, any fastlane metadata. It never builds and launches
your app or touches a signed-in device. It reports what it found in one block: the app, its main
features, which surfaces exist, which locales ship and how complete they are, and which screens
render from plain state.

```text
Use the store-art-studio skill for Google Play. Discover this project and summarise what you
found. Do not build or run anything yet.
```

## 2. Ask

Claude asks only what the repo cannot answer, in batches with a recommended option first:
features and their order, surfaces to show, design direction (an archetype or your reference
set), first market, your copy rules (glossary, banned words, register, claims you can back), the
art budget and kind, and who uploads. A skipped question takes the stated default.

## 3. Brief

Claude writes `docs/screenshots/brief.md` from your answers, and `store/storeart.config.json`
with your first market only (`"upload": false`) and the surfaces you chose. Read both, edit
anything, then approve. Every later phase reads them.

```text
The brief is approved. Start Gate 0.
```

## 4. First draft

**Gate 0, setup.** Claude reports your AGP, Kotlin, compileSdk, Compose BOM, Glance, Coil and JDK
and any screenshot library, proposes the exact catalog and settings changes, and waits. Then it
adds the `storeart` module and page kit, replaces the sample composables with your real ones
(adding a seam where a screen needs a ViewModel or the clock, and telling you which), builds the
frozen world for your first market, and checks Higgsfield. You get a contact sheet of every
surface, the plan with a credit estimate, which screens are redraws, and what broke.

The world is one fixed moment with full, plausible lists whose totals are computed from records,
no real people, and nothing that reads the system clock. Surfaces are named by role
(`screen_list`, `widget_list_big`, `card_live`), so one page layout serves every market.

**Gate 1, style tile and calibration slot.** Palette, type, pill and phone frame from the brief,
and the simplest slot. From a status bar capture on an emulator with no account
(`references/android-compose.md`, "Status bar chrome"), Claude measures and freezes the chrome.

**Gate 2, the hero and the hard slots.** The slots with generated art. Claude preflights the cost,
shows two variants per asset, writes a provenance file per pick, and names any slot that risks a
store guideline.

**Gate 3, the rest.** The remaining slots in the brief's order, the feature graphic, the Wear OS
set if you chose it, and a thumbnail strip of the whole set. The width test proves every headline
fits at one size in every slot; the negative test proves the width test can fail.

```bash
store/page/tools/render-all.sh
store/page/tools/widthtest.sh && store/page/tools/widthtest.sh --negative
```

## 5. Iterate

Each of Gates 1 to 3 runs in rounds: Claude renders, reviews its own output first, shows you the
slots and a thumbnail strip with what changed, takes your feedback in one batch, and fixes. Every
decision and rejected direction is logged in the brief and in `docs/screenshots/rejected/`. A gate
is done when you approve it.

```text
Round feedback: the slot 2 headline is too generic, lead with the verb. Keep slot 1.
Show me the strip again.
```

## 6. Localize

Only after the first market is approved, and only the markets you name. Per market Claude adds a
config entry (`"upload": false`), a world, copy transcreated under the skill's rules and then yours
from the brief (yours win; conflicts are flagged), a literal back-translation in `COPY_NOTES.md`,
the width tests for that locale, and a list of what needs a native reader.

```text
The first market is approved. Add <store locale> (<time zone>, <12 or 24> hour clock, <currency>,
<left to right or right to left>). One market at a time, with the width tests and the
native-review list.
```

Read the back-translations, and have a native speaker read the slots, not only the text. When a
market is approved, set its `"upload": true`.

## 7. Ship

Google Play has **no draft for listing art**: images go live when the edit commits. So Claude
stages, verifies and dry runs; you run the real upload.

```bash
store/page/tools/render-all.sh en-US
store/page/tools/stage-play.sh en-US                    # supply tree, 2 to 8 phone shots, verified
fastlane upload_art locales:en-US validate_only:true    # dry run, changes nothing
fastlane upload_art locales:en-US                       # you run this one
```

Prefix `bundle exec` if the repo has a `Gemfile`. Paste
`templates/fastlane/Fastfile.android.snippet.rb` into `fastlane/Fastfile` once. The lane uploads
images only, and only for staged locales with `"upload": true`.

Then pull the listing back (Play Console, or `fastlane supply init --metadata_path /tmp/play-pull`)
and compare count, order and images with `out/play`. The job is done when they match.

## Store submission checklist (Google Play)

Play's rules change; follow the current Play Console help over this list.

- [ ] **Phone screenshots:** 2 to 8 per language, JPEG or 24-bit PNG, no alpha, each side 320 to
      3840 px, the long side at most twice the short side. The template authors 1080 x 1920.
- [ ] **Feature graphic:** 1024 x 500, no alpha, key content away from the edges. Required.
- [ ] **Wear OS** (only if you ship it): square, at least 384 x 384 px, raw watch UI only (no
      frame, mask, wrist, background or added text), a few distinct states. They go in the Wear OS
      form factor, not with the phone screenshots.
- [ ] **Tablet** (only if you ship a tablet layout): 7 and 10 inch screenshots. Ask Claude to add a
      tablet page size and stage `sevenInchScreenshots/` and `tenInchScreenshots/`.
- [ ] **Listing:** each language exists on the listing before you upload to it. The icon is
      512 x 512 with alpha, checked on its own.
- [ ] **AI asset declaration:** label every asset that contains generated art (photos,
      characters, 3D objects, backgrounds). Raw UI renders need no label; the provenance `.txt`
      files say which assets are generated. Suggested wording, adjusted to what your set holds:
      "Background art and 3D decorative objects were generated with AI. All app screens are
      rendered from the app's real interface."
- [ ] **Claims and identity:** no ratings, user counts, awards or rankings unless the brief lists
      them with a source; no real people; no marks you do not own.
- [ ] **Upload:** the dry run passed, and you run the real upload.

## Troubleshooting

A failing first build is almost always a version mismatch: paste the error to Claude in Gate 0.
Renderer traps are in `references/android-compose.md`, "What broke"; tooling and delivery traps
under "Tooling and delivery" in the same file; art traps in `references/higgsfield-art.md`,
"In practice".

## Costs and time

Measured on one production set. Preflight with `get_cost`: prices change.

| Work | Credits | Time |
|---|---|---|
| Gate 0, first build and wiring | under 2 (one test image) | an hour or two, mostly seams |
| One market, the whole set with a hero and variants | about 30 to 60 | a working day, mostly review |
| Each extra market | close to 0 (art reused) | under an hour plus native review |
| Paparazzi, one market, every surface light and dark | | about a minute once Gradle is warm |
| Page kit, one locale, slots and feature graphic | | seconds |

Render one market while you iterate; render all only before staging.
