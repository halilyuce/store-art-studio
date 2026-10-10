# Style and copy

The numbers here are the house style that survived review against a reference board. Use them as
defaults when the user has no style of their own. When they have a reference, measure it and replace
the numbers (`reference-matching.md`). Specs are pixels on a 1320 x 2868 slot.

## The discipline (keep even if you change the numbers)

- One headline, one body, one object per slot.
- Headline at one pixel size in every slot and language. Never shrink; rewrite.
- Text placed by baseline, flush left at a constant margin.
- One accent per slot, the hue of its pill tile.
- Ink is a tuned dark grey, never `#000`. Device screens carry the app's own colour, flat.
- The device bleeds off the bottom and its screen is full: nothing empty over 25% of its height.
- Depth is deliberate: a pill has a rim and no shadow, a card has one shadow, nothing has a default.

## Default palette

| Role | Value |
|---|---|
| Page | 3 x 3 `MeshGradient`: TL `#DAE3FF`, TR `#E7E3F0`, centre `#E5E2F3`, BL `#F1E2E6`, BR `#FDE1D6`, midpoints averaged |
| Ink | `#37373F` |
| Accents | yellow `#FDCB2C` to `#F6BA32`, cyan `#1BDAEB`, blue `#3C6FF9`, one orange word `#FC4C02` |
| Device screen backdrop | flat `#3121FD` to `#3E3FF9`, white system text, never pastel or dark |
| Hero page | `#3021FD` top, `#1E71F7` middle, `#332BFC` bottom; light burst `#D8F4FF` fading to `#1F70F5` by r 620 |

Pick the accent for the pill from the object in the headline: a stopwatch is yellow, a watch is
cyan, a speech bubble is blue.

## Type

| Element | Spec |
|---|---|
| Headline | Inter Tight 700 (800 closes the counters at this size), 195 px, lowercase, tracking -2%, line pitch 205 (223 when a pill is on the line) |
| Body | Inter 500, 56 px, pitch 80, at most 1090 px wide, two lines |
| Hero line (optional) | Bebas Neue, cap height 64 px, white, shadow y +2 blur 6 at 15% |
| Footer (optional) | Archivo Expanded 600, 30 px, +0.16em tracking, white 45% |
| Headline baselines | about 312 and 535 (pill line), body first baseline 660; measure the reference |

A headline line's ink right edge stays at most 1240 px. Compute widths in a test, not by eye.

## The pill

A rounded rect 234 px tall, radius 60, around one word plus its icon tile. Padding 55 px left and 40
px right. White at 40% with a radial wash of the tile's hue (r 200, 25%) behind the tile, a 2 px white
rim strongest at the top and bottom, no shadow. The tile is a 153 px squircle (radius 38) in a hue
gradient with a top highlight, 35 px after the glyph, centred on the x-height, holding a generated
white 3D glyph. `templates/ios/StoreArtPage.swift` implements exactly this.

## Layout archetypes

| Archetype | Use for | Notes |
|---|---|---|
| **Hero** | Slot 1 | Saturated brand field, generated figure or plate, icon and wordmark at top, the single strongest promise, a device or card |
| **Pastel plus straight phone** | Most slots | Headline top left, device from y 832 bleeding off the bottom, scale about 0.76, no shadow |
| **Bento** | A feature that is a set (widgets, collections) | Cards in one rounded slab, objects overlapping its edges |
| **Flat tiles, no phone** | A screen that is already a list (saved items) | Three stacked tiles of the real screen, nothing else |
| **Object on a slab** | Watch, a physical thing | The device sits on a soft gradient slab, the band cut flush at the slab's edge |
| **Scene** | Siri or other "magic" moments | Generated atmosphere behind a real card, the command pill hand-built on top |

Between slots the device keeps its scale and x position unless the story demands otherwise.

## Storyboard

Seven slots covered an app with several surfaces well. Keep the ones your app has, reorder for the
product:

1. Promise: what the app is, in one line. The only all-caps slot if the reference does that.
2. The Home Screen: real widgets, at the sizes users pick.
3. Real time: the Live Activity on the Lock Screen.
4. The wrist: Watch.
5. Voice: Siri or another assistant.
6. Depth: the detail screen that proves it is serious.
7. Yours: the personal, saved or favorites screen.

Show the strongest differentiator in slots 1 to 3. Search shows about three.

## Copy

- Headlines are lowercase fragments of two or three words per line. Body is a calm sentence in two
  lines. Periods only where the reference has them. No exclamation marks.
- The market's own spelling and the words its users use for your product's things. Write them in the
  brief once (for example, a banking app says "balance", never "amount"; "soccer" or "football" by market) and hold to them.
- Say what the thing does in the user's words. Banned: unlock, seamless, elevate, supercharge, next
  level, revolutionary, "your ultimate".

### Localization is transcreation

Write each locale as if it began there. Do not translate English fragments.

- English ad copy is clipped noun fragments. Turkish and many languages promise a benefit with a
  complete verb-led sentence in warm second person. Copying English architecture is the giveaway. The
  user's own Turkish corrections: "Saatinde de var" became "Artık saatinde de görebilirsin".
- Do not let one metaphor appear in every locale. That is translation wearing a costume.
- Keep a proper name from your data in a slot that needs no inflection. Vowel harmony and articles change
  the word otherwise.
- Mark every locale you wrote "not native-reviewed" in the summary, and ask the user to review the
  ones they read. Never ask a non-native to sign off.

### Back-translation notes

Keep one `COPY_NOTES.md` next to the copy (template: `templates/android/page/COPY_NOTES.md`). Per
locale: the register and glossary terms used, then a table of every slot with the headline, its
literal back-translation, the body and its back-translation. The owner can then check meaning in a
language they do not read, and the next agent sees why a line reads the way it does.

- Mark every locale "not native-reviewed" until a native speaker signs it off, with the date and
  the reviewer.
- **Surface conflicts as questions.** A project's translation rules can disagree with copy the owner
  already approved elsewhere (another platform's set used an informal register the ruleset forbids,
  or a word the ruleset bans). Do not silently pick one: follow the ruleset, note the conflict in a
  "Decisions" table, and ask the owner.
- **Language rules beat house style.** A lowercase headline style applies to the words a language
  lets you lowercase. In German, nouns keep their capital (lowercasing one is a spelling error), so a
  lowercase German headline still capitalises its nouns. Write such a rule into the notes once.
- A figure keeps one written form per locale, chosen with the owner (decimal mark, grouping,
  percent position).

### Fitting a wording

When a line is too wide, in this order: shorter synonym, shorter structure, drop the lead word. Never
type size. Examples: "favorites" became "faves" in en-GB, and a two-word imperative became the shorter verb of
the same meaning in fr, es, pt-BR, nl and ja. Rough widths at 195 px: Latin about 105 px per
character, Hangul about 165, kana and kanji about 180; a pill adds about 283.

### Typographic traps

- Glue with a no-break space (`\u{00A0}`) anything that must not wrap: a figure and its unit, a proper
  name. Use `\u{2060}` (word joiner) in ja and zh where no space exists.
- Right-to-left scripts: mirror the page (margins, pill, tile order) and the app layout, never the
  status bar, and verify bidi order by rendering. Isolate figures (`direction: ltr;
  unicode-bidi: isolate`), or "-12%" can render as "%12-". The width test measures an RTL line from its
  left edge.
- When the display face lacks a script, the headline falls back to another face. Load one that
  covers the script, with every weight you use set explicitly, or the browser or the OS synthesises
  a fake bold that also measures differently.
- Translations run longer than the source. Anything placed beside a headline (an object, a sticker)
  is placed by measuring the rendered line, not by a fixed position per locale.
- Body sentences are always two lines and tables always the same row count, so every card is the same
  height in every language. When a long language runs to three lines, use a shorter sentence form.

## Claims and store rules

- No awards, laurels, ratings, "#1" or user counts by default. The templates carry none. Add a
  claim only when the developer asks for one and can back it; the developer can prompt Claude to add
  one. Google Play may treat user counts and rankings in listing art as a policy risk even when true,
  so keep a version of the slot without it.
- Apple's header rules forbid awards, prices, URLs and other platforms, and require 4+ suitability.
- Never show real athletes, real kits or colour pairs, broadcaster names or third-party icons.
- Apple's guidelines discourage tilted or obstructed bezels and graphics leaving a screen. When the
  design uses them, flag it and offer straight-bezel variants.
- Google Play expects screenshots that show real app UI. Check the current policy before using device
  frames.
