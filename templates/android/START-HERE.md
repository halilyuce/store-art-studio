# Starting the Android side

The iOS template in `../ios` is proven. The Android one does not exist yet: building it in your own
project is the first job. Paste the prompt below into Claude Code, from your Android project's root,
with the `store-art-studio` skill installed (see `INSTALL.md`).

## The prompt

```text
Use the store-art-studio skill. I want to build the Android half of it in this repository: a host-less
Jetpack Compose render target that produces Google Play screenshots from my app's real composables.

Read these first, in order:
1. SKILL.md, for the layers and the hard rules
2. references/android-compose.md, for the Android plan and its open questions
3. templates/ios/*.swift, which is the proven reference implementation. Port its structure, not its syntax.
4. references/style-and-copy.md and references/reference-matching.md, because the finished slots must
   look like the iOS ones (or like the reference set I give you)

Port the iOS kit to Compose one file at a time, keeping the same responsibilities:
- StoreArtKit.swift      -> StoreArtKit.kt: the canvas in px and dp, a px-to-dp helper with a fixed
                            Density and fontScale 1.0, font registration with a test that fails on a
                            missing font, a render function that writes an opaque PNG, a timezone and
                            locale switch, and baseline placement helpers
- StoreArtChrome.swift   -> a minimal Android status bar (9:41, full battery) drawn from a real emulator
                            screenshot, plus an optional device frame (Google Play expects real UI,
                            so default to no frame or a plain rounded rect)
- StoreArtPage.swift     -> palette, background, headline with tracking and a width measurement, the
                            pill and glyph tile, body lines placed by baseline
- SampleSlot.swift       -> one complete sample slot
- StoreArtRenderTests    -> a Paparazzi (or Roborazzi, whichever this project already uses) test that
                            renders the sample slot, plus a headline width test that fails instead of
                            shrinking type
- render.sh              -> a Gradle task or script that runs one test and lists the PNGs

Rules for this job:
- Canvas is 9:16, 1080 x 1920 px at density 3.0 (360 x 640 dp), opaque PNG, no alpha. Render my app
  screens at a realistic phone size (about 412 x 915 dp) and scale them into the slot.
- Never run my real app, an emulator signed in to a real account, or anything that syncs. Render
  composables from sample data only. If a screen needs a ViewModel, give it a fake and tell me.
- Look at what the project already uses (AGP, Kotlin, Compose BOM, JDK, any screenshot library) and
  tell me your choice and the dependency changes before you edit any Gradle file.
- Put the new code in the place that fits this repo (a test source set, or a dedicated test-only
  module). Propose it and wait for my answer.

Stop at Gate 0 and show me:
1. The sample slot rendered, opened and checked by you.
2. One of my real screens rendered from sample data with no network and no account.
3. The same slot in two locales, with different strings and number formats.
4. scripts/verify-export.sh passing on the output.
5. A short list of what broke or surprised you, and add the same list to references/android-compose.md
   under "What broke", so the next developer does not hit it.

Then wait. Do not start any real slot until I approve Gate 0.
```

## After Gate 0

Continue with the normal workflow in `SKILL.md`: style tile and a calibration slot, hero and hard
slots, the rest, localization, delivery with `supply` to a track that is not production. If you have a
reference set, say so at the first message and point the agent at it: matching it is what
`references/reference-matching.md` is for.

## What to send back

If something in the iOS-to-Android port was wrong in this skill, the most useful thing you can do is
send the corrected `references/android-compose.md` and your `StoreArtKit.kt` to whoever maintains it.
That turns the Android page from "designed" into "proven".
