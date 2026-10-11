# Store screenshots for <App>: brief

<!-- The skill writes this file in phase 3 (references/discovery.md) at docs/screenshots/brief.md,
     from what it read in the repo and what you answered. You own it: edit anything, and every later
     phase follows your edit. Lines marked "assumed" are defaults nobody confirmed; check them.
     You can also fill it by hand and start a session with "Read docs/screenshots/brief.md and start
     at Gate 0". Delete any section that does not apply. -->

Make the store screenshots for **<App>**, <one line: what it is, for whom>. Repo: this one, branch
`<branch>`. Use the `store-art-studio` skill. Status: <draft | approved on <date>>.

## What discovery found

<The summary from phase 1: platforms, app type, features, surfaces, locales the app ships and how
complete, brand assets, the existing listing, which screens render from plain state. Facts with
their source.>

## Platforms and stores

| Store | Devices | Ship? |
|---|---|---|
| App Store | iPhone 6.9" <, iPad, Apple Watch> | <yes / no> |
| Google Play | phone <, tablet, Wear OS>, feature graphic | <yes / no> |

## Features to show, in order (the storyboard)

Slots 1 to 3 carry the story: a store visitor sees about three in search. One headline, one body,
one object per slot.

| Slot | Feature | Surface | The one promise | What renders | Generated art |
|---|---|---|---|---|---|
| 1 | <core promise> | screen | <headline idea> | <screen or view> | <none / hero / object> |
| 2 | | | | | |
| 3 | | | | | |

Not shown, on purpose: <features left out and why>.

## Surfaces

Phone screens always. Everything else only if the app ships it and this set should show it.

| Surface | App has it | Show it | Notes |
|---|---|---|---|
| Home screen widgets | | | <sizes> |
| Live notification, Live Update or Live Activity | | | |
| Watch app, tile or complication | | | |
| Lock Screen | | | |
| Siri, Shortcuts, assistant | | | |
| Tablet layout | | | |

On Android these go into `surfaces` in `store/storeart.config.json`; nothing else renders.

## Design direction

| Item | Choice |
|---|---|
| Archetype | <hero then pastel / pastel with a straight phone / bento / scene-led>; `references/style-and-copy.md` |
| Reference set | <none, build a style tile / `docs/screenshots/references/<board>.jpg`> |
| Colours | <page, ink, accents, from the app's brand> |
| Type | <Inter Tight and Inter (default) / the app's faces> |
| Tone | <three words> |
| Light or dark | <the app's default / light / dark / by slot> |
| Device frames | <plain drawn frame / none / official bezel (iOS, gitignored)> |

<!-- With a reference set, keep the next paragraph. -->
**Match this set as closely as possible:** `docs/screenshots/references/<board>.jpg`; each slot at
native size is in `references/crops/` (`s1` to `sN`, `*top`, `*bot`, zooms). **Never repeat**
anything in `docs/screenshots/rejected/`.

## The world

<One frozen moment: date, local time and time zone, and the data every surface shows (an account,
a list, a progress figure, a balance). Every device agrees. Invented, plausible, complete, no real
people.>

## Markets

The market list itself lives in one machine-read file: `store/storeart.config.json` (Android) or
`screenshots.yml` (iOS). This section only records the order and who reads what.

| Order | Store locale | Native reader | Status |
|---|---|---|---|
| 1 (first) | <locale> | <name or "none"> | <draft / approved on date> |
| 2 | | | not started |

## Your rules

Applied after the skill's own rules. Yours win on a conflict, and each conflict is flagged
(`references/style-and-copy.md`, "Two rulesets").

- **Source:** <path to your translation or style guide, or "pasted on <date>", or "none">
- **Brand voice:** <how the app speaks>
- **Glossary**, the words your users use for your product's things, per locale:

| Concept | <locale 1> | <locale 2> |
|---|---|---|
| | | |

- **Register per locale:** <locale: informal or formal "you">
- **Banned words:** <your list>, plus the skill's (unlock, seamless, elevate, supercharge, ...)
- **Claims allowed:** <none (default) / each claim with its source>

## Art

- **Kind:** <none / 3D objects and glyphs / a hero scene or figure / illustrated characters>
- **Budget:** <n> credits for the job; ask before any gate costs more than <40>.
- Highest resolution, 9:16 for full slots, subject in the centre 70%. Prompts per asset follow
  `references/higgsfield-art.md`: <figure>, <plate>, <glyphs>.
- Picked art goes to `StoreArt/Art/<slot>/` (iOS) or `store/page/art/` (Android), each file with a
  provenance `.txt`: model id, prompt, seed, generation id, credits.

## Store targets and upload

- **Upload:** <the developer runs it, the skill stages and dry runs / the skill uploads to a
  preview or PPO treatment (App Store only) / files only>
- **Google Play:** no draft for listing art: the `validate_only` dry run first, then the developer
  runs the real upload.
- **Declarations:** assets with generated art labelled in Play Console; watch screenshots are raw UI.

## Hard rules

- **Never launch <App>** anywhere, never sign in, never sync; <why, if it has bitten you>. Render
  only host-less: `scripts/screenshots/render.sh` on iOS (the `StoreArt` tests on their own
  simulator), the `storeart` Paparazzi module on Android.
- **App UI is always the real views.** System chrome (status bar, clock, Home Screen) is drawn in
  code and measured from a real capture.
- **No em dashes.** No awards, laurels, ratings, "#1" or user counts unless listed under "Claims
  allowed". No real people, brands you do not own or third-party icons.
- **Export:** exact store sizes (1320 x 2868 on iPhone 6.9", 1080 x 1920 on Play), opaque PNG,
  `verify-export.sh` passes.
- **Ask first** before a new Xcode target or Gradle module, and over the credit limit above.

## Style spec

<Measured from the reference, or the defaults from `references/style-and-copy.md`. Filled at Gate 1.>

| Item | Value |
|---|---|
| Page | |
| Ink | |
| Accents | |
| Screens | |
| Headline | face, size, case, tracking, pitch |
| Body | face, size, pitch, max width |
| Margin and baselines | |
| Pill and tile | |
| Device | scale, origin, frame |
| Depth | |

## Gates (stop and wait for approval)

Before showing a render: open it, look at it small, compare, list every difference, fix, repeat
until minor.

- **Brief:** this file, approved.
- **Gate 0:** renderer set up, a contact sheet of every real view, the world, a plan with a credit
  estimate.
- **Gate 1:** style tile plus the calibration slot.
- **Gate 2:** hero and the hard slots. Name the slots at risk with store guidelines.
- **Gate 3:** the rest, then all slots together at thumbnail size.
- **Gate 4:** localize, one market at a time, list what needs native review.
- **Gate 5:** verify, stage, dry run, upload (a preview or PPO treatment, or the developer on
  Play), pull back and compare.

## Approvals and decisions

One dated row per decision (`references/iteration.md`). A rejected direction also gets an image in
`docs/screenshots/rejected/`.

| Date | Decision | Why | By |
|---|---|---|---|
| | Brief approved | | |
