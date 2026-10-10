# Android, end to end

This guide takes you from nothing to a finished Google Play listing set: phone screenshots, a
feature graphic, and Wear OS screenshots if your app has a Wear OS app or tile, in every market you
choose. It works for any kind of app. You bring your app, your design and your markets. The skill
brings the method.

Only phone screens are required. Widgets, live notifications (or Live Updates and live cards), a
Wear OS app or tile, and tablet layouts are optional: you list the ones your app has in the config,
and only those render.

Read it once before you start. Then work through it gate by gate. Each gate ends with you
approving the result. Claude does not start the next gate on its own.

Related files, all paths relative to the skill folder:

| File | What it is |
|---|---|
| `SKILL.md` | The contract: layers, hard rules, gates, review loop |
| `templates/android/START-HERE.md` | The files to copy and the Gate 0 prompt |
| `templates/android/storeart.config.json` | The config you own: your markets |
| `references/android-compose.md` | The renderer, every trap with its fix, Play specs |
| `references/higgsfield-art.md` | What to generate and how to key and place it |
| `references/style-and-copy.md` | Palette, type, layout, transcreation |
| `references/reference-matching.md` | Matching a set you like |
| `references/fastlane-and-delivery.md` | Staging, the upload lane, the safety checklist |

## Contents

1. [What you need and how to connect it](#1-what-you-need-and-how-to-connect-it)
2. [The first 30 minutes](#2-the-first-30-minutes)
3. [Gate 0: setup](#gate-0-setup)
4. [Gate 1: style tile and one calibration slot](#gate-1-style-tile-and-one-calibration-slot)
5. [Gate 2: the hero and the hard slots](#gate-2-the-hero-and-the-hard-slots)
6. [Gate 3: the rest of the set](#gate-3-the-rest-of-the-set)
7. [Gate 4: localize](#gate-4-localize)
8. [Gate 5: deliver](#gate-5-deliver)
9. [Store submission checklist (Google Play)](#store-submission-checklist-google-play)
10. [Troubleshooting](#troubleshooting)
11. [Costs and time](#costs-and-time)

## 1. What you need and how to connect it

Tick these off before Gate 0. Each row says how to check it.

| Need | Why | Check |
|---|---|---|
| Claude Code with the skill | The skill runs inside it | See "The skill" below |
| Higgsfield MCP with credits | Generates the art (objects, scenes, avatars) | `balance` answers in a session |
| A credit budget | The skill asks before it spends more | You name a number |
| An Android project that builds | The renderer is a test module in it | `./gradlew :app:assembleDebug` |
| AGP, Gradle and JDK that Paparazzi supports | Paparazzi pins a range per release | See "Paparazzi" below |
| Google Chrome | Renders the HTML page layer headless | See "Chrome" below |
| macOS with `swift` and `sips` | The image scripts and `verify-export.sh` | `swift --version`, `which sips` |
| ImageMagick (optional, recommended) | Flattening, resizing, compositing | `magick -version` |
| An Android emulator (optional) | Only to capture reference system chrome | `emulator -list-avds` |
| fastlane | Uploads the images | `fastlane --version` |
| A Google Play service account JSON | fastlane signs in to Play with it | `fastlane run validate_play_store_json_key` |
| `gh` (optional) | Only to send fixes back to the skill | `gh auth status` |

### The skill

```bash
# For every project on this machine
git clone https://github.com/halilyuce/store-art-studio.git ~/.claude/skills/store-art-studio
# Check the file sits at the top level, not one folder deeper
ls ~/.claude/skills/store-art-studio/SKILL.md
```

Start a new Claude Code session and ask:

```text
Is the store-art-studio skill available? Show me its description.
```

It should name the skill and quote its description. If not, the folder is nested one level too
deep, or the session started before you cloned it. Restart Claude Code.

### Higgsfield MCP

```bash
claude mcp add --transport http --scope user higgsfield https://mcp.higgsfield.ai/mcp
claude mcp list
```

Then start a **fresh foreground session**, run `/mcp`, pick `higgsfield` and sign in. Ask:

```text
Check my Higgsfield balance.
```

A session that was already open, and background or child sessions, may not load a server you added
later. Start a new session in your terminal after adding it.

If the tools still do not load in the session you work in, a headless session works as a bridge. It
loads the MCP servers fresh. Allow only the tools the task needs.

```bash
#!/usr/bin/env bash
# store/tools/hf.sh "<task>": one Higgsfield task in a headless session.
# Same spending rules: the task text must name the budget.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
exec claude -p "$1" --allowedTools "mcp__higgsfield__balance,mcp__higgsfield__models_explore,mcp__higgsfield__generate_image,mcp__higgsfield__generate_image_batch,mcp__higgsfield__jobs_wait,mcp__higgsfield__show_generation_by_ids"
```

```bash
store/tools/hf.sh "Check my Higgsfield balance and print it."
```

### A credit budget

Decide a number before Gate 0 and say it in the first prompt. The skill checks `balance`, preflights
each job with `get_cost`, and asks before a single gate costs more than your budget. The default is
to ask above 40 credits. See [Costs and time](#costs-and-time).

### Paparazzi

The renderer is [Paparazzi](https://github.com/cashapp/paparazzi). Each release supports a range of
AGP, Gradle, compileSdk and JDK versions.

1. Read your versions: AGP and Kotlin in `gradle/libs.versions.toml`, Gradle and the JVM with
   `./gradlew --version`, compileSdk in your module build files.
2. Open the Paparazzi releases page (github.com/cashapp/paparazzi/releases) and its
   `CHANGELOG.md`. Find the newest release whose notes cover your AGP and Gradle.
3. The template pins `2.0.0-alpha05`, proven with AGP 9.3, Kotlin 2.4 and compileSdk 36 and 37
   (`templates/android/storeart/libs.versions.snippet.toml`). The template as it ships was built
   and run on Gradle 9.7.0, JDK 21, AGP 9.3.0 and Kotlin 2.4.10.
4. If your root build already declares AGP, Kotlin or Paparazzi, the catalog must use exactly
   those versions. If `gradle.properties` has `android.builtInKotlin=false`, the module needs the
   Kotlin Android plugin (`templates/android/START-HERE.md`, step 1).

If the project already runs Roborazzi on Robolectric, the skill can use that instead. It never adds
both. Claude reports your versions and its plan before it edits any Gradle file.

### Chrome

The page tools call Chrome headless. On macOS they find it at the default path. Elsewhere, point
`CHROME` at the binary:

```bash
export CHROME="$(command -v google-chrome || command -v chromium)"
```

### macOS, and what to do on Linux

| Part | macOS | Linux |
|---|---|---|
| Gradle and Paparazzi renders | Yes | Yes |
| Headless Chrome page renders | Yes | Yes, with `CHROME` set |
| `chromakey`, `edgekey`, `cutout`, `screenswap`, `greenbox`, `probe`, `compare` (`.swift`) | Yes | No. They use CoreGraphics, ImageIO, Vision and CoreImage |
| `verify-export.sh`, the alpha flatten in the page tools | Yes | No. They call `sips` |
| fastlane upload | Yes | Yes |

On macOS, install the command line tools with `xcode-select --install`. That gives you `swift`.
On Linux, render and upload there, and run the image scripts and `verify-export.sh` on a Mac, or
replace them with ImageMagick (`magick identify -format "%w %h %A\n" file.png` prints size and
alpha).

### An emulator, only for chrome

You never run your app for store art. An emulator is useful for one thing: capturing a real status
bar to measure, once. Use an emulator with no Google account and no app of yours installed.

```bash
mkdir -p store/page/chrome
adb shell settings put global sysui_demo_allowed 1
adb shell cmd uimode night yes
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4
adb shell am broadcast -a com.android.systemui.demo -e command network -e mobile show -e datatype none -e level 4
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false
adb exec-out screencap -p > store/page/chrome/ref-dark.png
```

Repeat with `cmd uimode night no` for `ref-light.png`. Use the clock your default market shows
(`-e hhmm 2141` for a 24 hour market). A Wear OS emulator, set up the same way, can capture tile
screenshots if your tile is not Compose.

### fastlane

```bash
ls Gemfile 2>/dev/null && echo "use: bundle exec fastlane" || echo "use: fastlane"
```

A `Gemfile` at the repo root means fastlane comes from bundler: run `bundle exec fastlane ...`.
No `Gemfile` means a Homebrew or system install: run `fastlane ...`. To install with Homebrew:
`brew install fastlane`.

### A Google Play service account

fastlane needs a JSON key to sign in to the Google Play Developer API.

1. In Google Cloud Console, pick or create a project and enable the **Google Play Android
   Developer API**.
2. Create a service account in that project, then create a JSON key for it. The key downloads once.
3. In Play Console, open **Users and permissions**, invite the service account's email, and give it
   access to your app with permission to manage the store listing (store presence). Do not give it
   release or financial permissions it does not need.
4. Keep the key out of git. Put it outside the repo (for example `~/.config/play/<your-app>.json`)
   or in a gitignored path, and point fastlane at it in `fastlane/Appfile`
   (`json_key_file("...")`) or with `SUPPLY_JSON_KEY=<path>`.
5. Check it:

```bash
fastlane run validate_play_store_json_key json_key:"$HOME/.config/play/<your-app>.json"
```

Play Console's menus change. If a name above has moved, follow Play's own help page for service
accounts.

## 2. The first 30 minutes

The shortest path to a first real render. It assumes section 1 is done.

The commands are in `templates/android/START-HERE.md`, "The first 30 minutes".

1. **5 min.** Copy the template into your repo: the config to `store/`, the page kit to
   `store/page/`, the module to `storeart/`, the skill's scripts to `store/tools/`.
2. **5 min.** Add `:storeart` to the settings and merge the catalog snippet. Leave the two example
   markets in the config: the sample world is written for them.
3. **10 min.** Render the sample: `python3 storeart/scripts/fetch_logos.py`, then
   `./gradlew :storeart:testDebugUnitTest --tests '*WorldsTest'` and `storeart/scripts/export.sh`. Open the
   PNGs in `storeart/build/storeart/us/`.
4. **5 min.** Render the page: `store/page/tools/render-all.sh` and `store/page/tools/widthtest.sh`.
   Open `store/page/out/en-US/01.png`. The pipeline works.
5. **5 min.** Write your default market (see
   [Writing storeart.config.json](#writing-storeartconfigjson)) into the Gate 0 prompt below and
   paste it. Claude swaps the examples for your market and wires your first real composable.

If step 3 fails, it is almost always a version mismatch. Paste the error to Claude with the Gate 0
prompt; it fixes the build first.

## Gate 0: setup

**What Claude does.** Reads your build and reports AGP, Kotlin, compileSdk, the Compose BOM,
Glance, Coil, the JDK and any screenshot library. Proposes the catalog and settings changes and
waits. Adds the `storeart` module, the page kit and the config. Renders the sample surfaces and
opens every PNG. Asks which optional surfaces your app has and writes them into the config's
`surfaces`. Replaces the placeholders with your real composables. Builds a frozen world for
your default market. Checks Higgsfield (`balance`, one cheap test image) and writes a plan with a
credit estimate.

**What you provide.** Your default market (store locale, time zone, 12 or 24 hour clock, currency,
direction). Which surfaces your app has: screens always; widgets, a live notification, a Wear OS
app or tile, a tablet layout only if you ship them. Which screens are worth showing.
A credit budget. A reference set, if you have one.

**The prompt.** Paste from your Android project's root:

```text
Use the store-art-studio skill. Start Gate 0 for Google Play, following
docs/android-end-to-end.md and templates/android/START-HERE.md in the skill folder.

My default market: <store locale, e.g. en-US>, time zone <e.g. America/Chicago>,
<12 or 24> hour clock, currency <e.g. USD>, <left to right or right to left>.
Screens worth showing: <screens>. My app also has (delete what it does not): widgets,
a live notification or Live Update, a Wear OS app or tile, a tablet layout.
Credit budget: <n> credits for the whole job; ask before any gate costs more than <m>.
Reference set: <path, or "none, build a style tile">.

Before you edit any Gradle file, tell me what this project uses and the exact changes you will
make. Wait for my answer. Never run my real app or a signed-in emulator.
```

`templates/android/START-HERE.md` has the longer prompt with every step spelled out. Use either.

### Writing storeart.config.json

The skill ships no language list. This file is the only list of markets, and you own it. The
render module, the page, the page tools and the upload lane all read it.

```json
{
  "moment": "2026-10-11T21:41",
  "default": "us",
  "surfaces": ["screens"],
  "markets": [
    { "code": "us", "storeLocale": "en-US", "appLocale": "en-rUS", "languageTag": "en-US",
      "timeZone": "America/Chicago", "clock24h": false, "rtl": false, "currency": "USD",
      "digits": "", "fontFamily": "", "fontWeights": "", "upload": false }
  ]
}
```

| Field | What to put |
|---|---|
| `moment` | One local date and time every surface shows. Pick a moment when your app looks its best |
| `surfaces` | What your app has: `"screens"` always, plus `"widgets"`, `"notification"`, `"wear"`, `"tablet"` only if you ship them. Leave it out for screens only |
| `default` | The `code` of the market that renders first and alone |
| `code` | A short name for the render folder (`ui/<code>/`) |
| `storeLocale` | The Play listing locale, from Play Console's language list |
| `appLocale` | The Android resource qualifier (`en-rUS`, `de`, `pt-rBR`) |
| `languageTag` | The BCP 47 tag the formatters read (`en-US`, `de-DE`) |
| `timeZone` | An IANA zone (`Europe/Berlin`) |
| `clock24h` | `true` or `false`, as people in that market set their phones |
| `rtl` | `true` for a right to left script |
| `currency` | An ISO 4217 code, if your app shows money. Any code works |
| `digits` | `"latn"` to force Western digits, else `""` |
| `fontFamily`, `fontWeights` | A face for a script your display fonts lack, with explicit weights (`"500;700"`) |
| `upload` | `false` until you approved that market's renders. Gate 5 reads it |

Keep each market flat, one level, no nesting. The Kotlin side parses it without a JSON library.

With `"surfaces": ["screens"]` the whole pipeline works: the widget, card and Wear tests are
skipped, and the page shows screens only. Add `"widgets"` if you have home screen widgets,
`"notification"` if you have a live notification, Live Update or live card, `"wear"` if you have a
Wear OS app or tile. The template's sample lists all of them so you can see each part render.

### The frozen world

Every surface reads one world per market: the moment, the zone, the locale, and every record the
screens show. That is why the widget, the list and the card agree.

- **Full, plausible data.** Fill every list a screen shows. An empty list or three rows look broken
  in a store screenshot. Invent the data. No real people.
- **Computed, not typed.** Totals, ranks and counts come from records through `RecordEngine`. Typed
  totals drift between surfaces.
- **No clock in a render path.** Nothing rendered calls `System.currentTimeMillis()`. Where app code
  reads the clock, Claude adds a seam (a parameter or a CompositionLocal) and tells you.
- **Your story.** The engine tries seeds until the outcome fits (your primary item near the top,
  trending up). If no seed fits, change the inputs, never an output.

`./gradlew :storeart:testDebugUnitTest --tests '*WorldsTest'` checks each world in about a second and prints it.
Read it once like a stranger would.

### Choosing role ids

Surfaces are named by what they do on the page, not by what they show in one market:
`screen_list`, `screen_detail`, `screen_secondary`, `widget_primary_big`, `widget_list_wide`,
`widget_list_big`, `card_live`, `card_live_2`, and `wear_01_*` for the watch. Only screens are
required; the other roles exist only for surfaces your config lists. Each comes light and
`-dark`, widgets also `-dyn` (Material You). One page layout then works for every market, even when
the content differs. Pick the roles your story needs and tell Claude.

**Files produced.**

```
store/storeart.config.json
storeart/                        the render module (test only, nothing depends on it)
storeart/build/storeart/<code>/  the surface renders (rebuilt, never committed)
store/page/                      slots.html, kit.css, kit.js, copy.js, header.html, tools/
store/page/ui/<code>/            copies of the renders the page reads
store/tools/                     the skill's scripts (verify-export.sh, probe.swift, ...)
```

**How to check.** Open every surface PNG. Cards and widget corners (if you have them) are transparent, screens are
opaque, the right to left market (if any) is mirrored. `WorldsTest` passes. The sample slot renders
at 1080 x 1920. `store/tools/verify-export.sh store/page/out 1080x1920 1024x500` passes.

**Stop and approve.** Claude shows the renders, the sample slot, the plan with a credit estimate,
which screens it had to redraw instead of render (and why), and what broke. Approve, or ask for
changes.

## Gate 1: style tile and one calibration slot

**What Claude does.** Builds a style tile: palette, headline and body type, the pill, the phone
frame. Picks the simplest slot (one object on the page) and builds it. Measures the status bar from
your emulator capture and freezes it. With a reference set, measures it first.

**What you provide.** Brand colours, fonts (default Inter Tight and Inter), tone, banned words.
A reference set, if any. The emulator chrome captures from section 1.

**The prompt.**

```text
Gate 0 is approved. Start Gate 1: a style tile and the simplest slot.
Measure the status bar from store/page/chrome/ref-dark.png and ref-light.png and freeze it.
Brand: <colours>, <fonts or "default">, tone <three words>. Banned words: <list>.
```

With a reference set:

```text
Match this set: docs/screenshots/references/<board>.jpg. Take its layout and type, keep our own
colours and content. Measure it with probe.swift before you build anything, then show me the
style tile and slot 1 side by side with the reference (compare.swift).
```

**Measuring a reference set.** Claude cuts the board into slots, then measures margins, baselines,
line height, type size and palette with `swift store/tools/probe.swift`, instead of guessing. It
copies craft, never content: the other brand's name, copy, icons and photography stay theirs. See
`references/reference-matching.md`.

**The review loop.** Before you see any render, Claude has opened it, looked at it at about 300 px
wide, compared it with the reference (`compare.swift` puts both side by side with shared guides),
written down each difference (palette, type size, tracking, margins, device scale, shadow, empty
areas), fixed it and rendered again. You get the comparison and the differences left, not only
the render.

**Files produced.** `store/page/slots.html` and `kit.css` changes, `store/page/out/<locale>/01.png`,
`store/page/checks/` comparison sheets.

**How to check.** Open the slot at full size and at thumbnail size. The headline reads at 300 px.
The status bar matches your capture.

**Stop and approve.** The style tile is now frozen. Changing it later restyles every slot.

## Gate 2: the hero and the hard slots

**What Claude does.** Builds slot 1 (the hero) and any slot with hands, scenes, a watch on a wrist
(only if your app has Wear OS) or other generated art. Generates the art with Higgsfield, keys it, places it, and writes a
provenance `.txt` beside each picked file (model, prompt, seed, generation id, credits). Names any
slot that risks a store guideline (a tilted or covered phone, art leaving the screen) and offers a
straight variant.

**What you provide.** Approval of the credit estimate. Picks between variants.

**The prompt.**

```text
Gate 1 is approved. Start Gate 2: the hero and the slots with generated art.
Budget for this gate: <n> credits. Preflight with get_cost and show me the estimate first.
Generate 2 variants per asset, show them side by side, and wait for my pick.
```

**Files produced.** `store/page/art/<slot>/*.png` or `.jpg` with a `.txt` each,
`store/page/out/<locale>/01.png` and the hard slots.

**How to check.** No text, logos, real people or brands in the art. Hands look right. The key has
no fringe. Each picked file has its provenance file.

**Stop and approve.** The hero carries the listing in search. Take your time.

## Gate 3: the rest of the set

**What Claude does.** Builds the remaining phone slots (2 to 8 in total), the feature graphic
(`header.html`, authored at 2048 x 1000, shipped at 1024 x 500), any alternate slot you asked for
(for example a straight version of a tilted hero), and the Wear OS set if your app has a Wear OS
app or tile. Lays all slots side by side at store thumbnail size. Runs the width test.

**The width test.** A headline is one size in every slot and language. It never shrinks. The test
measures each headline line after the fonts load and fails on any overflow. The negative test
forces an overflow and fails if the test misses it, so you know it can fail.

```bash
store/page/tools/widthtest.sh
store/page/tools/widthtest.sh --negative
```

**The prompt.**

```text
Gate 2 is approved. Start Gate 3: the remaining slots and the feature graphic, plus the Wear OS
screenshots if "wear" is in surfaces. Show me all slots side by side at thumbnail size, the width
test and the negative test output.
```

**Files produced.** `store/page/out/<locale>/01.png .. NN.png`, `feature-graphic.png`, any
alternate `01-<name>.png`, and with Wear OS `storeart/build/storeart/<code>/wear_*.png`.

**How to check.** The first three slots tell the whole story on their own. Every number agrees
across slots. Both width tests pass.

**Stop and approve.** The default market is done. Nothing is uploaded yet.

## Gate 4: localize

Only after the default market is approved. You choose the markets; the skill never adds one you
did not name.

**What Claude does, per market.**

1. Adds the market to `store/storeart.config.json` with `"upload": false`.
2. Adds its world in `SampleWorld.kt` (its own names, amounts and primary item).
3. Transcreates the copy into `store/page/copy.js`: written as if authored there, not translated.
   Each line gets a literal back-translation in `COPY_NOTES.md`, so you can check the meaning
   without reading the language.
4. Optionally adds per-market art: `art/hero/<code>.jpg`, `art/avatars/<code>/`. The page falls
   back to `default`.
5. Runs `WorldsTest`, `storeart/scripts/export.sh <code>`, the width test and the negative test
   for that locale, renders the set, opens every PNG.
6. Marks the copy **not native-reviewed** and lists what needs a native speaker.

**What you provide.** The market list, in the order to roll out. The languages you or your team
read natively. Native reviewers for the rest, if you have them.

**The prompt.**

```text
The default market is approved. Add these markets to store/storeart.config.json, one at a time:
<store locale, time zone, 12 or 24 hour clock, currency, direction> for each.
Transcreate the copy, write back-translations in COPY_NOTES.md, run the width tests and the
negative test per locale, and list what needs native review. Do not render markets I did not name.
```

**Files produced.** Config entries, world branches, `copy.js` and `COPY_NOTES.md` entries,
`store/page/out/<locale>/`, optional per-market art.

**How to check.** Read the back-translations. Ask a native speaker to read the slots, not only the
text: line breaks and tone matter. Right to left markets: figures like "-12%" keep their order.

**Stop and approve, per market.** When a market is approved, set its `"upload": true`.

## Gate 5: deliver

Google Play has **no draft for listing art**. Images go live when the edit commits. So delivery is
staged, verified, dry run, and the real upload is yours.

**What Claude does.**

1. Renders the approved markets: `store/page/tools/render-all.sh <locales>`.
2. Stages the supply tree: `store/page/tools/stage-play.sh [--variant <name>] <locales>`. It
   builds `store/page/out/play/<locale>/images/` with `phoneScreenshots/`, `featureGraphic.png`
   and `wearScreenshots/` (only when `surfaces` lists `wear`), refuses fewer than 2 or more than 8 phone
   screenshots, and runs `verify-export.sh`.
3. Pastes `templates/fastlane/Fastfile.android.snippet.rb` into the Android platform block of
   `fastlane/Fastfile` (once).
4. Runs the dry run, if you allow it:

```bash
fastlane upload_art locales:en-US validate_only:true
```

Prefix with `bundle exec` if your repo has a `Gemfile`. Play validates the edit and changes
nothing.

5. Hands you the exact real upload command. **You run it, not Claude.**

```bash
fastlane upload_art locales:en-US
```

**Before you run it.**

- The language exists on your store listing in Play Console. Add it there first, or the edit fails.
- The locale has `"upload": true` in the config. The lane refuses any other.
- `supply` replaces all images of each uploaded type for that locale. It does not merge.
- The AI declaration and the rest of the [store checklist](#store-submission-checklist-google-play)
  are done.

**Pull back and compare.** A success line is not proof. Open the listing in Play Console, or pull it
into a scratch folder and compare it with `store/page/out/play`:

```bash
fastlane supply init --metadata_path /tmp/play-pull --json_key "$HOME/.config/play/<your-app>.json" --package_name <your.package>
```

Check the count, the order and that each image is the one you approved.

**Stop.** The job is done when the pulled-back listing matches what you approved.

## Store submission checklist (Google Play)

Play's requirements change. Check the current Play Console help pages and follow them over this
list.

**Phone screenshots**

- [ ] 2 to 8 per language. The template authors them at 1080 x 1920 (9:16).
- [ ] Each side between 320 and 3840 px, the long side at most twice the short side.
- [ ] JPEG or 24-bit PNG, no alpha, at most 8 MB each. `verify-export.sh` passes.
- [ ] The first three tell the story. Play shows them first.

**Feature graphic**

- [ ] 1024 x 500, JPEG or 24-bit PNG, no alpha. Required to publish.
- [ ] Key content away from the edges. Play may crop or overlay it.

**Wear OS screenshots** (only if you ship a Wear OS app or tile)

- [ ] Square, 1:1, at least 384 x 384 px. The template renders 576 x 576.
- [ ] Raw captures of the app or tile UI only. No watch frame, no round mask, no wrist, no
      background, no added text.
- [ ] Rendered from the same module (`WearSurfacesTest`), or captured on a Wear OS emulator with no
      account.
- [ ] A few distinct states (a tile, a list, a detail), not one screen twice.
- [ ] They go in the Wear OS form factor of the listing, not with the phone screenshots.

**Tablet screenshots** (only if you ship a tablet layout)

- [ ] Play asks for 7 inch and 10 inch screenshots when the app targets tablets. The template has
      no tablet slots: ask Claude to add a tablet page size and stage it as
      `sevenInchScreenshots/` and `tenInchScreenshots/`. Check Play's current size table first.

**Listing**

- [ ] Each language exists on the store listing before you upload to it.
- [ ] App icon 512 x 512, 32-bit PNG with alpha, checked on its own.

**AI asset declaration**

Play Console asks whether listing assets were created or edited with AI. Label every asset that
contains generated art: generated photos, avatars, 3D objects, backgrounds. Raw UI captures, like
the Wear OS screenshots, contain no generated art and need no label.

Suggested wording:

> Background photography, illustrated characters and 3D decorative objects were generated with
> AI. All app screens are rendered from the app's real interface.

Adjust it to what your set really contains. Follow Play's own definitions over this guide. The
provenance `.txt` beside each picked file tells you which assets are generated.

**Claims and identity**

- [ ] No user counts, ratings, awards or rankings unless you asked for one and can back it. The
      template has none. Play may treat them as a policy risk even when true.
- [ ] No real people. Avatars are illustrations and look like illustrations.
- [ ] No brands, logos, kits or marks you do not own or have the right to use in marketing.

**Before upload**

- [ ] Play has no draft for listing art. The dry run passed, and you run the real upload.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Higgsfield tools missing in the session | The session started before the server was added, or it is a background or child session | Start a fresh foreground session, run `/mcp`, sign in. Or use the headless `hf.sh` bridge |
| Higgsfield answers 429 | Rate limit on that model | Wait and retry the same model. Never switch models silently: the set would mix two looks |
| The key colour is off (`#15E02C` for `#00FF00`) | Models do not hit the exact colour | Sample the real key inside the frame and key that |
| A white frame around the key colour | The model drew a border | Sample inside the frame, then `edgekey.swift` for what is left |
| The model ignored the key and returned white | Same | `swift store/tools/edgekey.swift in.png out.png --crop`, note it in the `.txt` |
| The job reports a different model id | Some ids route to another model | Record both in the `.txt` and tell the user |
| Paparazzi does not build | Version range | Check the release notes against your AGP, Gradle and JDK |
| `already on the classpath with a different version` | The root build loads that plugin at another version | Use the root build's exact version in the catalog |
| Tests pass in seconds with `NO-SOURCE`, no PNGs | `android.builtInKotlin=false` and no Kotlin plugin in the module | Uncomment `alias(libs.plugins.kotlin.android)` in `storeart/build.gradle.kts` |
| Right to left widget keeps left to right columns | Views ignore RTL without app RTL support | `Paparazzi(supportsRtl = true)` (the template sets it) |
| Applied widget crashes or images missing | AppCompat swaps in views RemoteViews cannot drive | `Paparazzi(appCompatEnabled = false)` (the template sets it) |
| `BitmapFactory.decodeFile` returns null or throws | Layoutlib does not back `fstat` | Read the bytes and use `decodeByteArray` (the template does) |
| The JVM aborts mid-run, no stack trace | Images decoded on background threads in layoutlib | Decode on the test thread first (`LogoFiles.decodeAll()`) |
| A test fails with "No image file for ..." | A URL with no fetched file. By design: a blank image must never ship | Add it to `logos.json` and run `fetch_logos.py` |
| `widthtest.sh` reports `OVERFLOW` | The headline is too wide in that language | Shorten the wording. Never shrink the type |
| A figure like "-12%" is reordered in right to left | Bidi reorders the figure | Wrap it in the `.num` class (`unicode-bidi: isolate`) |
| `Could not locate Gemfile` | fastlane is a Homebrew install | Run `fastlane`, not `bundle exec fastlane` |
| The agent hits a session limit mid-run | Long renders or many steps | Resume that agent and tell it where it stopped. Do not restart: a new agent repeats work and spends credits again |
| Upload refused: "Not approved for upload" | The locale has `"upload": false` | Approve its renders, then set `"upload": true` |
| Upload refused: "Not staged" | No staged tree for that locale | `store/page/tools/stage-play.sh <locale>` |
| The edit fails on Play's side | The language does not exist on the listing | Add the language in Play Console first |

More traps with their causes: `references/android-compose.md`, "What broke".

## Costs and time

**Credits.** Prices change; preflight with `get_cost`. As measured on one production set:

| Work | Typical cost |
|---|---|
| One market, the whole set (objects, a hero, a scene or two, variants) | about 30 to 60 credits |
| Each extra market | mostly reuses the art, close to 0 |
| A per-market hero or avatar (`nano_banana_pro` at 2k) | about 2 credits per image |
| A photoreal hero (`gpt_image_2_5` at 2k) | about 1.4 credits per image |
| Gate 0 test image | under 2 credits |

**Time.**

| Step | Time |
|---|---|
| Gate 0, first build and wiring | an hour or two, mostly reading your build and adding seams |
| Paparazzi, one market, every surface light and dark | about a minute after Gradle warms up |
| Paparazzi, a full multi-market run | about 12 minutes in the production app |
| Page render, one locale (2 slots, variant, feature graphic) | about 6 seconds |
| Width test, one locale | a few seconds |
| Gates 1 to 3 for one market | a working day, mostly review |
| Each extra market | under an hour plus native review |

Render one market while you iterate. Render all only before staging.
