---
name: store-art-studio
description: Build App Store and Google Play screenshots, product page headers and localized sets to a studio standard, from code. The app's real SwiftUI (or Jetpack Compose) views are rendered from sample data in a host-less test target, generated 3D art comes from the Higgsfield MCP, the page type is set in code, and fastlane ships it. Use for store screenshots, store creative, product page art, localizing a screenshot set into more languages, or matching a reference set the user shares. Not for quick device captures.
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
4. **One market first.** Render the default market, get approval, then roll out. Never render all
   locales unprompted. Rendering 22 at once drew an objection once already.
5. **Approved chrome is frozen.** The status bar, bezel metrics and Lock Screen are shared by every
   slot. Changing one silently restyles slots the user already approved. Fix spacing around them.
6. **Exact exports.** Right pixel size, opaque PNG, no alpha. Run `scripts/verify-export.sh`.
7. **Provenance.** Every generated asset gets a `.txt` beside it: model id, prompt, seed or "n/a",
   generation id, credits. A picked image you cannot reproduce is a liability.
8. **Spend deliberately.** Check `balance`, preflight with `get_cost`, ask before a single gate costs
   more than the budget the user named (default: ask above 40 credits).
9. **Copy is transcreated, not translated.** Write each locale as if authored there, mark it "not
   native-reviewed", and ask the user for the languages they speak natively. See
   `references/style-and-copy.md`.
10. **No borrowed identity.** No real people or brands you do not own (athletes, celebrities, team
    kits, broadcasters, competitors), no third-party icons, no AI-generated Apple hardware. Claims (user counts, awards, ratings) only when the user supplies
    them and can back them. Apple forbids awards, prices and URLs in headers.
11. **Licensed inputs stay out of git.** Apple bezel PNGs and provider images are gitignored and
    re-fetched by script.
12. **Match craft, never content.** When matching a reference set, copy composition, rhythm and
    finish. Never copy its brand, copy, icons or photography.
13. **No em dashes** in any copy, comment or message. They read as machine writing, and in store copy
    that costs conversions.

## Before you start: intake

Ask only what you cannot read from the repo. Then state your defaults in one block and proceed.

- Platforms and stores: iOS, Android, or both. Which device classes (iPhone 6.9", iPad, Watch).
- Surfaces worth showing: app screens, plus only what the app really has: widgets, Live Activities or
  live notifications, Watch or Wear OS, Siri, Lock Screen, tablet. Every surface beyond the screens is
  optional. On Android, write the answer into `surfaces` in `storeart.config.json`; nothing else renders.
- A reference set? If yes, read `references/reference-matching.md` before anything else.
- Markets and the order to roll them out. The default market comes first.
- Brand inputs: icon, colours, tone, a banned-words list. Fonts (default: Inter Tight and Inter, OFL).
- Credit budget for Higgsfield and who approves each gate.
- The world: one fixed moment (date, time zone, and the live data your app shows) that every device
  agrees on.

## Workflow

Each gate ends by stopping for approval. Do not start the next one on your own.

**Gate 0, setup.** Read the repo and any brief. Create the host-less `StoreArt` test target from
`templates/ios` (`references/ios-swiftui-renderer.md`), or the Android `storeart` module and page kit
from `templates/android` (`references/android-compose.md`). Prove the pipeline with one contact sheet that renders every real
view you will need, in light and dark. Check the Higgsfield MCP is authenticated (`balance`), run one
cheap test generation, and write a plan with a credit estimate. Output: the plan and the contact
sheet.

**Gate 1, style tile and one calibration slot.** Pick the simplest slot, one object on the page. Build
the style tile (palette, type, pill, device) and that slot. Verify system chrome against a real
device or simulator screenshot, not memory.

**Gate 2, hero and the hard slots.** The hero, and any slot with hands, warps or scenes. Name the
slots that risk a store guideline (tilted or obstructed bezels, graphics leaving the screen) in one
line and ask whether the user wants straight variants.

**Gate 3, the rest, then the set.** Build the remaining slots, then lay all of them side by side at
store-thumbnail size. A reader sees roughly the first three in search, so those must tell the story.

**Gate 4, localize.** Only after the default market is approved. Per locale: market data, time zone,
language, transcreated copy, width tests. The markets come from the user, never from the skill: on
Android they live in one `storeart.config.json` the developer owns. List what needs native review.
Roll out in batches.

**Gate 5, deliver.** `verify-export.sh`, then upload through fastlane or the store API to a target
that cannot go live (a preview, or a Product Page Optimization treatment). Pull the result back from
the store and compare. A success line is not proof. Never submit for review unless asked. Google
Play has no draft for listing art: stage with `tools/stage-play.sh`, run the `upload_art` lane with
`validate_only:true`, and hand the real upload command to the developer
(`references/fastlane-and-delivery.md`, "Google Play"). Before that upload, walk the developer
through the Play submission checklist in `docs/android-end-to-end.md`: Wear OS screenshots and the
AI asset declaration (label every asset with generated art; raw UI captures need none).

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
| Architecture, repo layout, slot registry pattern | `references/architecture.md` |
| Build the iOS render target, every host-less trap | `references/ios-swiftui-renderer.md` |
| Android: Paparazzi renderer, Glance widgets, what broke, Play specs, supply | `references/android-compose.md` |
| Android end to end: connect the tools, each gate's prompt, Play checklist (Wear OS, AI declaration) | `docs/android-end-to-end.md` |
| Android: the module and HTML page kit to copy | `templates/android/START-HERE.md` |
| Generate art with Higgsfield, key it, composite it | `references/higgsfield-art.md` |
| Palette, type, layout archetypes, copy and localization | `references/style-and-copy.md` |
| The user shared a set to match | `references/reference-matching.md` |
| fastlane, deliver, Product Page Optimization, headers | `references/fastlane-and-delivery.md` |
| A brief to hand the agent for a new app | `templates/brief-template.md` |

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
