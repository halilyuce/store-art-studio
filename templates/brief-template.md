# Store screenshots for <App>: <style name>, <market> set

Make the <market> App Store screenshots for **<App>**, my <platform> app. Repo: this one, branch
`<branch>`. The Higgsfield MCP is connected. Use the `store-art-studio` skill.

<!-- If you have a reference set, fill the next paragraph. If not, delete it and the skill will build
     a style tile for you to react to. -->
**Match this set as closely as possible:** `docs/screenshots/references/<board>.jpg`; each slot at
native size is in `references/crops/` (`s1` to `sN`, `*top`, `*bot`, zooms). **Never repeat**
`references/zz-rejected-<what>.png` (<what is wrong with it>).

## Hard rules

- **Never launch <App>** anywhere; <why, e.g. it wiped my real data>. Render only via
  `scripts/screenshots/render.sh` (host-less `StoreArt` tests, "StoreArt iPhone 17 Pro Max" simulator).
- **No em dashes.** <Spelling and the words your users use for your product's things, ...>
- **Banned:** <awards, laurels, ratings, "#1", user counts, real people, real kits, third-party icons,
  broadcaster names, AI-generated hardware, ...>
- **App UI is always the real views.** System chrome (status bar, clock, Home Screen) is drawn in code.
- **Export:** 1320 x 2868, opaque PNG, content <60> px from the edges. `sips -g hasAlpha` says no.
- **Generated art:** `StoreArt/Art/<slot>/` plus a `.txt` with model id, prompt, seed, generation id.
- **Ask first** before a new Xcode target or over <40> credits per gate.

## The world

<Date and time, time zone, and the live data the app shows (a score, a balance, an ETA), the user's
sample account. One moment, every device agrees.>

## Style spec

<Measured from the reference, or the defaults from `references/style-and-copy.md`.>

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
| Device | scale, origin, bezel colour |
| Depth | |

## Storyboard

For each slot: headline, body, the one object, what is on the screen, what is generated.

1. **Hero.** 
2. **<Surface>.** 
3. **<Surface>.** 

## Higgsfield

Highest resolution, 9:16 for full slots, subject in the centre 70%. Prompts per asset (see
`references/higgsfield-art.md`): <figure>, <plate>, <glyphs>.

## Gates (stop and wait for approval)

Before showing a render: view the compare with Read, list every difference, fix, repeat until minor.

- **Gate 0:** setup done; plan with credit estimate.
- **Gate 1:** style tile plus the calibration slot.
- **Gate 2:** hero and the hard slots. Name the slots at risk with store guidelines.
- **Gate 3:** the rest, then all slots together at thumbnail size.
- **Gate 4:** localize, one market at a time, list what needs native review.
- **Gate 5:** verify, upload to a preview or PPO treatment, pull back and compare.
