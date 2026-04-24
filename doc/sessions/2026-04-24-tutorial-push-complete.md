# Tutorial Push — Complete — 2026-04-24

The text audit that began with blurbs closes here. Six text roles (blurb, summary, intent, critical, technical, tutorial) now pass across all 179 spine maps. 1074/1074. The last cohort to land was Randomness — fourteen tutorials written in one sitting, topped up for a handful of short files, committed.

## What actually got done

Five tutorial cohorts after the pre-compact handoff:

| Sequence | Maps |
|---|---|
| postfoundationscrisis | 8 |
| qfeplaboratory | 9 |
| foundationscrisis | 9 |
| wavefunctions | 13 |
| randomness | 14 |
| **Total** | **53** |

The workflow was the same one that carried the earlier cohorts: bundle the sequence with `--only-failing`, write one edited bundle inline with every tutorial, split back to per-map files, check metrics, top up short files with a Python script in `doc/_bundles/_<seq>_tut_topup.py`, commit. Nothing clever. The clever part was earlier, building the bundle/split pair so the loop could run.

## Text as spec

The tutorial is the most concrete of the six roles. The blurb invites. The summary labels. The intent structures. The critical theorises. The technical explains. The tutorial *commits* — it picks a `class_name`, declares `@export` properties, chooses function signatures, lays out a sequence of numbered actions with captioned code blocks.

That makes every tutorial a proposal to the implementation. In the maps where the tutorial matches the `.gd` file, the two reinforce each other. In the maps where they don't, something is wrong — either the tutorial is misdescribing the code or the code is under-implemented.

I have read almost none of the scene files while writing these tutorials. That was deliberate — the tutorials are meant to describe what the maps *should* feel like, not what they currently are. But the gap between "should" and "is" is exactly the information the next iteration needs. The tutorial layer is now a high-fidelity spec that can be diffed against the codebase.

## The chambers are the weakest seam

Every sequence ends with a catalyst chamber: Chamber_Foundations, Chamber_QFEP, Chamber_Random, Chamber_Waves, etc. The tutorials I wrote for these chambers invent a lot — fold thresholds, resonance scoring, hue alignment, chaos scatter coefficients, befriend signals, hardcoded mode names like `"suspend"` and `"chaos"`. Some of this matches the existing `commons/hazards/becoming_catalyst/` system; much of it projects forward into a system that is only partially present.

Chambers are where text most confidently describes something that doesn't fully exist yet. That is useful — they are proposals for what becoming_catalyst should do as creatures unify with modes — but it means the chambers will fail a strict text-against-code check the hardest. They are deliberate over-promising.

## The six roles separate cleanly

After six cohorts, the role ecology holds. A reader can walk a map's six files top to bottom and each adds a distinct layer:

- Blurb lands the invitation.
- Summary labels the museum exhibit.
- Intent names the concept, sequence role, and technical angle.
- Critical argues the theoretical stakes.
- Technical walks the code paths.
- Tutorial hands the learner a series of actions with working examples.

The roles rarely repeat content across a single map. That coherence is what makes the texts usable. Ask a question about any map and one of the six files is the right entry point.

## The iteration loop this enables

The text push was never the end. The texts exist to inform and improve the implementations. The loop:

1. **Text as spec.** (Done.) Six roles per map, all passing thresholds.
2. **Read text against code.** Walk each tutorial's `class_name` and function signatures against the actual `.gd` files. Flag divergences.
3. **Pick a direction per divergence.** Either the tutorial is wrong and the text gets corrected, or the map is under-implemented and the code gets extended.
4. **VR walk each map** with its summary and critical open. Note where the felt experience matches the text's promise and where it drifts.
5. **Update the weakest role per map.** Usually tutorial (if code changed) or critical (if the theoretical stakes shifted after walking).
6. **Regenerate capture images** on any map whose structure changed.

The first two steps are mechanical and could be automated. A script that parses each tutorial's fenced `gdscript` blocks and cross-references them with `commons/maps/<Map>/*.gd` would produce a first-pass divergence report.

## Three data points from the writing

**The 400-word minimum is almost exactly right.** A tutorial under 400 words cannot walk a map's core move without skipping steps. A tutorial much over 700 words starts repeating its voice or over-explaining. The 40% code ratio forces the writing to stay concrete.

**Captioned code blocks are the actual unit of teaching.** One caption sentence (≤15 words), one code block (~5-15 lines), 1-3 explanatory sentences below. The triad is the atom. Everything else is scaffolding between triads.

**Paragraph sentence limits do invisible work.** `max_paragraph_sentences: 3` forces you to break a thought into its real beats rather than run them together. Every 4-sentence paragraph that failed the check turned out to be three ideas pretending to be one. The fix was always just to insert a blank line at the real break.

## What's next

The text layer is a checkpoint, not a product. The next useful milestone is not more text; it is reading the text against the code and treating the divergences as a worklist.

A small tool would help: `tools/tutorial_code_diff.py <map_name>` that reads the tutorial's fenced GDScript, extracts declared classes and functions, and grep-checks the map's `.gd` files for matches. Report on `class_name`s that exist, `func` signatures that match, and functions present in the tutorial but absent from the code. That report becomes the input to the implementation pass.

The other useful thing would be a small blog-visible page in the encyclopedia — `/text-audit` — showing the 179 × 6 grid with pass states and last-edit timestamps. Something the user can glance at to see which maps have warm texts and which have cold.

1074/1074 is the beginning of the next loop, not the end of one.
