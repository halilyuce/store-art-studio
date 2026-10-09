# Matching a set the user shares

The user may share a set they love: a board image, a folder of screenshots, a competitor's listing.
The job is to reach that finish with their own app and their own content. Maximum effort means a
measured match, not a resemblance.

## What you may take and what you may not

Take: composition, margins, baselines, type scale and weight, tracking, palette relationships,
device scale and position, the depth treatment, how objects overlap, the rhythm across the set.

Do not take: the reference's brand, name, copy, icons, photography, illustrations or app UI. If the
reference shows its own app, the same slot shows the user's app in its place. When a reference element
cannot be reproduced without copying (a licensed character, a trademarked mark), say so and propose
a substitute.

## Step 1: take the set apart

1. Keep the original untouched in `docs/screenshots/references/`.
2. Cut it into slots at the store's native size. A board image is usually several slots side by side:
   measure the board, divide, crop with `sips` or ImageMagick, and name them `s1.png` to `sN.png`.
3. For each slot also save a top half, a bottom half and zooms of the hard parts (headline, pill,
   slab edge, a corner of the device). You compare at the detail where a match fails.
4. If the user supplies a rejected attempt, keep it as `zz-rejected-<what>.png` and treat it as a
   negative reference. Name in the brief what is wrong with it.

## Step 2: measure

Measure, do not eyeball. `scripts/probe.swift` reads pixels.

```bash
swift scripts/probe.swift s3.png --at 40,60 --at 660,1400          # sample flat colours
swift scripts/probe.swift s3.png --rows 104,1240 --bg "#E5E2F3"     # y range of every text line
swift scripts/probe.swift s3.png --ink 0,150,1320,420 --bg "#E5E2F3"   # ink bounds, so left, right, cap height
```

Fill this table per slot, and per set where it is constant:

| Item | Measure |
|---|---|
| Canvas | size, any rounded corner or inset |
| Background | colours at the corners and centre, whether it is a flat, linear, radial or mesh gradient |
| Text margin | left edge of ink, right limit |
| Headline | line count, cap height and x-height (so size), baselines, line pitch, case, weight, tracking, colour |
| Body | size, pitch, width, baseline offset from the headline |
| Accent | one hue per slot or one for the set |
| Pill or tag | height, radius, padding, fill, rim, shadow, tile size and position |
| Device | scale (bezel width over slot width), origin, tilt, which colour, how far it bleeds |
| Depth | shadows (offset, blur, opacity) or none, glows, the light direction |
| Objects | size, count, overlap with the device and the type |
| Bottom | footer line, tab bar cut, how the slot ends |

Write the result into the brief as a numbered spec. A style you did not write down is a style you
will drift from.

## Step 3: build the style tile first

One tile with the palette, the headline in two sizes, the pill, and the device, before any slot. The
user approves the tile, then the first slot. The tile catches wrong type weight and wrong palette at
the cheapest point.

Test two weights of the headline face against the zoom crop (700 against 800). Strokes are usually
between, and one is clearly closer.

## Step 4: the compare loop

```bash
swift scripts/compare.swift s3.png render.png cmp.png --gx 104 --gy 312,535,868
```

The reference is on the left, your render on the right, each at 50%, with the same guides drawn across
both: the text margin and the baselines you are matching. Read `cmp.png` yourself. Then list every
difference, grouped:

```
palette   | page top is cooler (#D9E3FF vs mine #DDE3F5)
type      | headline reads 4% heavier, tracking tighter by about 0.5%
margins   | second baseline 6 px low
pill      | rim too bright at the bottom edge
device    | scale 0.78 vs 0.763, origin 8 px right
depth     | reference has no shadow under the phone, mine does
light     | burst sits 40 px higher
empty     | none
```

Fix every line, rerender, compare again. Stop when what remains is minor, then show the user the
comparison and the remaining list, not only the render. Never show a render you have not compared.

## Step 5: when the reference and the product disagree

Content differs, so spacing will. Do not stretch the product to fit the reference. Hold the
discipline (margins, baselines, scale, depth) and let the content be the user's. Where the reference
has a sticker, a figure or a scene, generate the equivalent with Higgsfield from the recipes, matching
style and weight, with the user's subject. Record the prompt and the choice.

## Step 6: keep the standard across the set

A matched set is consistent, not seven separate matches. After slot one is approved, freeze its
numbers (margin, baselines, pill, device scale). Later slots inherit them, and a deviation needs a
reason in the brief.

## If the user gives several sets

Ask which properties come from which ("type from the first, palette from the second"), and write that
mapping in the brief. If two sets conflict, pick one as the master and say which.

## If there is no reference

Use the defaults in `style-and-copy.md`, build the style tile, and ask the user to react to it. A
tile costs a render; a wrong set costs a week.
