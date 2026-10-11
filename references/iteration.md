# Iteration: rounds with the developer

Phase 5. Gates 1 to 3 are not one render each: they are rounds. A round is one pass of render,
self-review, show, feedback and fix. The developer decides when a gate is done.

## One round

1. **Render** only what changed, in the first market only.
2. **Review it yourself first**: the review loop and the slop checklist in `SKILL.md`. Never show a
   render you have not opened.
3. **Show**, in this order:
   - the slots of this round at full size (or the comparison with the reference, side by side);
   - a **thumbnail strip** of the whole set so far, every slot at about 300 px wide in store order,
     so the developer judges the set the way a store visitor sees it;
   - what changed since the last round, in one line per slot;
   - what you noticed and did not fix, and why;
   - credits spent this round and left of the budget.
4. **Ask** for feedback in one batch. Offer choices where you can ("headline A or B", "straight or
   tilted hero"), with your recommendation first.
5. **Log** the outcome (below), then fix and start the next round.

A thumbnail strip is one image. On Android, render the slots with the page kit and put them side by
side with headless Chrome or ImageMagick (`magick out/en-US/0?.png -resize x640 +append
checks/strip.png`); on iOS, `scripts/compare.swift` or the same `magick` call. Keep strips and
comparison sheets in a `checks/` folder: `verify-export.sh` skips it and it is gitignored.

## The decision log

`docs/screenshots/` is the memory of the job (`references/architecture.md`, "Decision log"). The
agent that picks the work up next month has only this folder and the brief.

- **`docs/screenshots/brief.md`, "Approvals and decisions"**: one dated row per decision: what was
  decided, why, and who decided. Approvals of a gate are rows too.
- **`docs/screenshots/rejected/`**: one image per direction that failed, named for what was wrong
  (`2026-10-11-hero-too-dark.jpg`), so it is never proposed again. Rejected headlines go in the
  log as text.
- **Brief edits**: when feedback changes the brief (a feature drops out, a banned word appears, the
  order of slots changes), edit the brief in the same round and log the edit. The brief must always
  describe the set as it is.

```markdown
| Date | Decision | Why | By |
|---|---|---|---|
| 2026-10-11 | Brief approved | | developer |
| 2026-10-11 | Hero: straight phone, not tilted | Avoids a store guideline risk | developer |
| 2026-10-12 | Slot 3 headline "plan the whole trip" replaces "every stop, one view" | Clearer verb | developer |
| 2026-10-12 | Rejected: dark hero page | Reads heavy at thumbnail size (rejected/2026-10-12-hero-dark.jpg) | developer |
```

## When to stop a gate

- The developer approves it. Silence, "looks good so far" or approval of one slot is not approval
  of the gate; ask.
- **Diminishing rounds**: when two rounds in a row only move pixels the developer did not ask about,
  stop polishing and ask for approval or for the one thing still wrong.
- **Taste loops**: when feedback alternates between two options for the same element, show both
  side by side once, ask for a final pick, log it, and do not reopen it unless the developer does.
- **Budget**: before a round would push the gate past its credit share, stop and ask.
- **Scope drift**: a request that changes the brief's direction (a new style, new features, another
  market first) is a brief edit. Say so, update the brief, and restart the affected gate rather than
  patching slot by slot.

## After approval

- Freeze what was approved: chrome, style tile, slot order. Later changes to frozen parts restyle
  approved slots, so they need the developer's explicit go.
- Record the approval with the date, and on Android leave `"upload": false` until the slots of that
  market are approved; then the developer (or you, when asked) sets it to `true`.
- Localization (phase 6) starts only from an approved first-market set.
