---
name: store-art-studio
description: Build App Store and Google Play screenshots, product page headers and localized sets to a studio standard, from code, for any app. It reads the project, asks the developer structured questions, writes a brief, then renders the app's real SwiftUI or Jetpack Compose views from sample data in a host-less test target, adds generated 3D art from the Higgsfield MCP, sets the page type in code, iterates with the developer, localizes per market and ships with fastlane. Use for store screenshots, store creative, product page art, localizing a screenshot set into more languages, or matching a reference set the user shares. Not for quick device captures.
---

# Store Art Studio

Store screenshots that look designed, not generated, and that stay correct in every language because
they are code.

Proof of the method: one iOS codebase produced 7 slots in 22 App Store locales (154 screenshots) and
22 product page headers. Every figure on every device agrees, every row of data on every screen is real
payload data, and nothing was ever drawn by hand in a design tool.

## The four layers

| Layer | Made by | Rule |
|---|---|---|
| Truth | The app's own views, rendered host-less from your data | Never redraw, never generate, never mock up app UI |
| Atmosphere | Higgsfield MCP | Objects, stickers, hands, light, scenes. Never readable UI, never text |
| Page | SwiftUI or Compose in a render target | Type, layout, pills, backgrounds, placed by baseline in pixels |
| Delivery | fastlane plus the store APIs | Exact sizes, no alpha, allow-listed locales, never submits for review |

If a task seems to need a different split, say so and ask. Do not blur the layers: the day a model
draws a table row is the day a wrong number ships.

## Hard rules

1. **Never launch the user's real app to get a picture.** Render views in a host-less test bundle on
   a dedicated simulator that never has the app installed. Apps that sync state can overwrite real
   keychains and saved user data; this happened twice in the project this skill comes from.
2. **UI is real code.** If a view cannot render host-less (remote images, `onAppear`), redraw it in
   the render target at the app's own point sizes, from the same payloads and the same localized
   string keys, and tell the user which screens are redraws.
3. **Never shrink a headline to fit.** The headline is one size in every slot and language. When a
   wording is too wide, shorten the wording. A width test enforces it.
4. **One market first.** Render the first market, get approval, then roll out. Never render all
   locales unprompted. Rendering 22 at once drew an objection once already.
5. **Approved chrome is frozen.** The status bar, bezel metrics and Lock Screen are shared by every
   slot. Changing one silently restyles slots the user already approved. Fix spacing around them.
6. **Exact exports.** Right pixel size, opaque PNG, no alpha. Run `scripts/verify-export.sh`.
7. **Provenance.** Every generated asset gets a `.txt` beside it: model id, prompt, seed or "n/a",
   generation id, credits. A picked image you cannot reproduce is a liability.
8. **Spend deliberately.** Check `balance`, preflight with `get_cost`, ask before a single gate costs
   more than the budget the user named (default: ask above 40 credits).
9. **Copy is transcreated, not translated.** Write each locale as if authored there, under the
   skill's rules and then the developer's rules from the brief, mark it "not native-reviewed", and
   ask which languages the developer reads natively. See `references/style-and-copy.md`.
10. **No borrowed identity.** No real people or brands you do not own (athletes, celebrities, team
    kits, broadcasters, competitors), no third-party icons, no AI-generated Apple hardware. Claims (user counts, awards, ratings) only when the user supplies
    them and can back them. Apple forbids awards, prices and URLs in headers.
11. **Licensed inputs stay out of git.** Apple bezel PNGs and provider images are gitignored and
    re-fetched by script.
12. **Match craft, never content.** When matching a reference set, copy composition, rhythm and
    finish. Never copy its brand, copy, icons or photography.
13. **No em dashes** in any copy, comment or message. They read as machine writing, and in store copy
    that costs conversions.

## The seven phases

Every job runs the same seven phases, on iOS, Android or both, for any kind of app. The job stops
for the developer's approval at the brief and at the end of every gate. Do not start the next one
on your own.

| Phase | What happens | Gate | Detail |
|---|---|---|---|
| 1. Discover | Read the project: platforms, app type, features, surfaces, locales, brand, listing | | `references/discovery.md` |
| 2. Ask | Structured questions for what the repo cannot answer, recommended option first | | `references/discovery.md`, "Question bank" |
| 3. Brief | Write `docs/screenshots/brief.md` (and the market config); the developer edits and approves | Brief | `templates/brief-template.md` |
| 4. First draft | Renderer setup, style tile and calibration slot, hero and hard slots, the full set, in the first market | 0 to 3 | below |
| 5. Iterate | Rounds of render, review, feedback and fix until the developer approves the set | within 1 to 3 | `references/iteration.md` |
| 6. Localize | Per market from the config: world, transcreated copy, width tests, native-review list | 4 | `references/style-and-copy.md` |
| 7. Ship | Verify, stage, dry run, the developer uploads, pull back and compare, store checklist | 5 | `references/fastlane-and-delivery.md` |

### Phases 1 to 3: discover, ask, brief

Read before asking. Explore the repo yourself (navigation graphs, screens and routes, view models,
the manifest or `Info.plist`, widget and watch targets, notifications and Live Activities, string
files, brand assets, any existing listing) and present a short summary of what you found. Then ask
only what the repo cannot answer, in batches that fit Claude Code's `AskUserQuestion` tool:
features and their order, surfaces, design direction, first market and language, the developer's
own rules (glossary, banned words, register, brand voice, claims they can back), art budget and
kind, stores and who uploads. State your defaults. Write the answers into the brief and the market
config, and stop until the developer approves the brief. The brief is the source of truth from here
on: re-read it at every gate, and follow the developer's edits.

A reference set changes the order: read `references/reference-matching.md` before the style tile.

### Phase 4: first draft (Gates 0 to 3)

**Gate 0, setup.** Create the host-less `StoreArt` test target from `templates/ios`
(`references/ios-swiftui-renderer.md`), or the Android `storeart` module and page kit from
`templates/android` (`references/android-compose.md`). Prove the pipeline with one contact sheet
that renders every real view the brief needs, in light and dark. Build the frozen world for the
first market. Check the Higgsfield MCP is authenticated (`balance`), run one cheap test generation
if the brief has an art budget, and write a plan with a credit estimate. Output: the plan and the
contact sheet.

**Gate 1, style tile and one calibration slot.** Pick the simplest slot, one object on the page.
Build the style tile (palette, type, pill, device) from the brief's design direction, and that
slot. Verify system chrome against a real device or simulator screenshot, not memory.

**Gate 2, hero and the hard slots.** The hero, and any slot with hands, warps or scenes. Name the
slots that risk a store guideline (tilted or obstructed bezels, graphics leaving the screen) in one
line and ask whether the developer wants straight variants.

**Gate 3, the rest, then the set.** Build the remaining slots in the brief's order, then lay all of
them side by side at store-thumbnail size. A reader sees roughly the first three in search, so those
must tell the story.

### Phase 5: iterate

Every gate from 1 to 3 is a loop of rounds: render, run the review loop below, show the developer
the renders and a thumbnail strip, take feedback, fix, repeat. Log every decision and rejection in
`docs/screenshots/` so a direction that failed is never repeated. The set is approved when the
developer says so, not when the loop runs out of ideas. `references/iteration.md` has the round
format and the stopping rules.

### Phase 6: localize (Gate 4)

Only after the first market is approved. The markets and their order come from the developer's
config, never from the skill. Per market: its world (time zone, data, clock, currency), copy
transcreated by the skill's rules and then the developer's rules from the brief (the developer
wins on a conflict; flag it), width tests, and a list of what needs native review. Roll out one
market or a small batch at a time.

### Phase 7: ship (Gate 5)

`verify-export.sh`, then upload through fastlane (`deliver` for the App Store, `supply` for Google
Play) to a target that cannot go live: a preview or a Product Page Optimization treatment on the
App Store. Google Play has no draft for listing art: stage with `tools/stage-play.sh`, run the
`upload_art` lane with `validate_only:true`, and hand the real upload command to the developer.
Pull the result back from the store and compare; a success line is not proof. Never submit for
review unless asked. Before an upload, walk the store checklist (`references/fastlane-and-delivery.md`;
on Play also `docs/android-end-to-end.md`): watch screenshots, the AI asset declaration (label
every asset with generated art; raw UI renders need none), and claims the developer can back.

## The review loop (every render, before the user sees it)

1. Render. Open the PNG yourself with Read. A render you have not looked at is not done.
2. Look at it again at about 300 px wide. If the headline or the point of the slot is gone, it fails.
3. With a reference: `scripts/compare.swift` puts the reference left and the render right with the
   same guides. `scripts/probe.swift` measures instead of guessing (ink bounds, line rows, colours).
4. Write down every difference by category: palette, type size, tracking, margins and baselines,
   pill and tile, device scale and position, depth and shadow, light, empty areas.
5. Fix, rerender, repeat until the remaining differences are minor. Then show the comparison and the
   differences that remain, not just the render.

## What makes a slot good

- One headline, one body, one object. If a slot makes two promises, split it.
- Headline: two lines, lowercase unless the brief says otherwise, tight tracking, same pixel size
  everywhere. Body: two short lines, broken by you.
- The device fills its screen. No empty band over 25% of the visible screen height.
- Text sits on baselines, margins are constants, and the same objects keep the same scale across slots.
- One accent colour per slot, taken from its pill tile. Ink is never pure black.
- Numbers agree: the same figures and clock on every device in every slot.
- The first three slots carry the whole story. Slot one says what it is, two and three say why.

## Slop checklist (fail the slot on any hit)

- Floating UI cards that do not exist in the app, or UI that was generated instead of rendered.
- Text baked into generated art, or hands, fingers or hardware that are subtly wrong.
- Background glows and blobs with no system behind them; shadows nobody measured.
- Headlines at different sizes across slots; a headline that was shrunk; a third line.
- Copy that reads translated: noun fragments in a language that uses verbs, one metaphor in all
  locales, "unlock", "seamless", "elevate", "supercharge", em dashes.
- Decorative third-party logos, laurels, "#1", invented ratings or user counts.
- Pure black text on a pastel page, pure white on a device screen, un-tuned default shadows.
- Anything you did not look at.

## Reference map

| Need | Read |
|---|---|
| Phases 1 to 3: reading a project, the question bank, writing the brief | `references/discovery.md` |
| Phase 5: rounds, the decision log, when to stop | `references/iteration.md` |
| Architecture, repo layout, slot registry pattern | `references/architecture.md` |
| Build the iOS render target, every host-less trap | `references/ios-swiftui-renderer.md` |
| Android: Paparazzi renderer, Glance widgets, what broke, Play specs, supply | `references/android-compose.md` |
| Android end to end by phase, with short prompts and the Play checklist | `docs/android-end-to-end.md` |
| Android: the module and HTML page kit to copy | `templates/android/START-HERE.md` |
| Generate art with Higgsfield, key it, composite it | `references/higgsfield-art.md` |
| Palette, type, layout archetypes, copy and localization | `references/style-and-copy.md` |
| The user shared a set to match | `references/reference-matching.md` |
| fastlane, deliver, Product Page Optimization, headers | `references/fastlane-and-delivery.md` |
| The brief the skill writes in phase 3 | `templates/brief-template.md` |

Paths in these files are relative to this skill folder. At Gate 0 copy `scripts/` into the project (for
example `scripts/screenshots/tools/`) and `templates/ios` into `StoreArt/` (Android: `templates/android`, see
its `START-HERE.md`), then use the project copies.

Scripts in `scripts/` run with plain `swift` (no packages): `chromakey.swift`, `cutout.swift`,
`screenswap.swift`, `compare.swift`, `probe.swift`, `edgekey.swift` (keys a white background the model
returned instead of the key colour), `greenbox.swift` (measures a green screen face to place a real render on); `verify-export.sh` uses `sips`; `ppo.rb` needs
`spaceship` and `dotenv` (fastlane's bundle has both). Pillow is not required and was broken on the
machine this came from, so measure with `probe.swift`.

## Reporting back

At each gate: what rendered and where the files are, what differs from the reference and why, credits
spent and left, what you redrew instead of rendered, and the decisions you need. Short, specific,
no celebration.
