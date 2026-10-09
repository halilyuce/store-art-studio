# Higgsfield art: what to generate and how to land it

Generation supplies atmosphere. Precise UI stays code. Every rule below was paid for in rejected
renders.

## What to generate, what not to

| Generate | Never generate |
|---|---|
| 3D clay glyphs for pill tiles, objects that fit your app, stickers | Readable UI, tables, scores, buttons |
| A figure or object cut out for a hero | Any text or numbers |
| Hands holding a plain slab, for a screen to be warped onto | Apple hardware (use the real bezel PNG) |
| A scene or light burst behind a device | Logos, real brands, real people |
| Glow and glass atmosphere around a real card | Proportion-critical chrome (a search bar, a status bar) |

Generated glass could not hold UI proportions: buttons came out mismatched and misaligned. The split
that works is hand-built precise UI plus generated atmosphere around it.

## Tools (Higgsfield MCP)

If the tool schemas are not loaded yet, load them first. Model ids in the MCP differ from the CLI docs, so never
trust a remembered id.

1. `models_explore` with `action: "recommend"` or `"get"`: aspect ratios, parameters, accepted
   `medias[].roles`. Default general image model is `gpt_image_2_5` (best for typography-free
   objects, photoreal plates, reference edits). The Nano Banana family (`nano_banana_2`,
   `nano_banana_2_1`, `nano_banana_pro`) is a separate set of models, not aliases of each other.
2. `balance`, then `generate_image` with `get_cost: true` to preflight. Cost varies by model and
   resolution.
3. `generate_image` for one request (use `count` 2 to 4 for variants of the same prompt) or
   `generate_image_batch` for independent prompts. Reuse the project `folder_id` if one exists.
4. `jobs_wait` for batch jobs, then show results. Do not resubmit after a transport timeout until the
   original outcome is known.
5. Download with `curl` into `StoreArt/Art/<slot>/` and write the provenance `.txt` immediately.

### Giving the model a reference image

`media_upload` returns a presigned URL. Then:

```bash
curl -X PUT "$UPLOAD_URL" -H "Content-Type: image/png" -H "If-None-Match: *" --data-binary @plate.png
```

then `media_confirm`, then pass `medias: [{ "value": "<media_id>", "role": "image_references" }]`. The
`If-None-Match: *` header is required or the PUT is rejected. Never retype a presigned URL: one typo
produced `SignatureDoesNotMatch`. Script it or paste it whole. If a model needs two images, say which
is which in the prompt ("Image 1 is my plate, image 2 is the style reference").

## Recipes

### Sticker or glyph on a key colour

Generate on flat magenta, key it to alpha, trim.

```
Glossy soft-3D clay render of <single object>, <colour and one distinguishing detail>, slightly
tilted, soft studio lighting from top left, gentle ambient occlusion, playful premium app-icon
style, matching a set of 3D clay <family>. No logos, no text, no brand marks. Centered, filling
70% of the frame. Solid flat #FF00FF background, no shadow on the background.
```

`gpt_image_2_5`, aspect 1:1, `count: 2`. Keep the family consistent by naming it ("matching a set of
3D clay objects") and generating new members with the same sentence. Then:

```bash
swift scripts/chromakey.swift in.png out.png --key "#FF00FF" --crop
```

`chromakey.swift` keys in the YCbCr chroma plane with a soft ramp and despill, so edges lose the
magenta cast. A red or pink subject on a magenta key turns brown under the default despill, because it removes
the key's own colour direction. Key it with `--spill 0` (and accept a faint rim), or generate it on
solid green instead. Tune `--inner` and `--outer` (defaults 0.35 and 0.65) if a rim survives or the object
gets eaten. A glyph that reads as a different object on the page (one object looked like another and
vanished on a blue background) is a rejection, record it in the `.txt`.

White glyphs for a pill tile: "Glossy soft-3D clay icon of a white <object>, rotated -30 degrees,
solid #FF00FF background, no text." Pass `--key` and keep the white.

### A figure for a hero

Flat vector or stylised, two-tone cel shading, a thick white sticker outline, from behind or in
profile, generic clothing with no stripe, number, decal or logo, unlike any real brand or team. Solid magenta
background. Then key it.

### A plate with a slab for a screen

Hands holding a featureless phone-shaped slab, face flat pure `#00FF00`, on your brand background.
Then `swift scripts/screenswap.swift plate.png ui.png out.png`: it keys the green, finds the screen
quad (Vision, with an extreme-points fallback), perspective-warps the rendered UI onto it, and
composites through the mask so fingers stay on top. Reject slabs that are not about 19.5:9, and
always ask for the subject in the centre 70% so you can extend vertically and never crop the sides.

### A scene around a real phone (the one that took iterations)

1. Render a BARE plate from code: the phone and the page, nothing else.
2. Upload it with a style reference as two `image_references`.
3. Prompt: "Image 1 is my plate, image 2 is the style reference. Recreate image 2's composition
   applied to image 1." State what must not change.
4. Output arrives around 1536 x 2752. Resize and extend to the slot, then `-alpha off`.

Do not ask the model to reshape the phone. "Wider and shorter" squashed it into a toy-like block and
posterised the sky. Reshape the original with ImageMagick instead: the screen is flat black, so cut a
band out of the middle (below the side buttons, above where the screen glow begins, so the join is
black into black) and `-append` the halves. Check a join by sampling brightness per row with
`probe.swift`, not by eye.

### Atmosphere on black, keyed to alpha

For a swirl, glow or light trail: generate on pure black, then turn the black into real alpha once.

```bash
magick src.png \( +clone -colorspace Gray -auto-level -sigmoidal-contrast 4,35% \) \
  -alpha off -compose CopyOpacity -composite out-alpha.png
```

Do **not** use `.plusLighter` over a light page: it adds the art's black and washes the page out.
Draw the art whole. Splitting it into front and back halves with a hard mask cuts the swirl in two.
Verify a mask with `-format "%[pixel:p{x,y}]"`, not the exit code: the three-image form
`magick a b mask -composite` silently ignored the mask here.

### Letting a model change an existing render (rare)

When you must, the prompt lists verbatim everything to keep (headline, answer text, table, bar,
status bar, background), or the model rewrites the text. The model will still degrade UI: it clipped
buttons, added a rainbow fringe to a bezel, ghosted a second copy of table rows. The hybrid fix is to
keep the pixel-exact render for all UI and take only the glow band from the output, masked and
feathered, hard-cut outside the band so the blur cannot leak.

## Landing rules

- Highest resolution, 9:16 for full slots, subject in the middle 70%.
- Pick, do not average. Generate 2 variants, choose, keep the rejected ids in the `.txt`.
- Name files by role (`object-sticker.png`), not by job id. Keep the unreproducible originals
  (`scene-source.png`) next to the processed one; delete candidates once a pick is final.
- Reject anything with text, a logo, a recognisable kit, a wrong-looking hand, or a face you did not
  ask for.
- Content policy rejections (`nsfw`, `ip_detected`) mean rephrase: remove the real brand or
  team cue, never argue with it.

## The provenance file

```
file: object-sticker.png (keyed with scripts/chromakey.swift --key #FF00FF --crop)
model: gpt_image_2_5 (aspect 1:1, count 2)
prompt: <the full prompt, verbatim>
generation id: <picked> (picked). Other: <id>
rejected: <id> reads as X, vanishes on Y
credits: <n>
```
