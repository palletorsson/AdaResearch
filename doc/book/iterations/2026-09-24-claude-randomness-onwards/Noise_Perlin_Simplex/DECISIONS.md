# Noise_Perlin_Simplex — decisions

Noise hall 8 of 9. 24 September 2026. Verdict: **Targeted revision.** One paragraph touched (the VIEW paragraph), two sentences changed, nothing added, nothing cut.

## Preserved

Everything else, word for word: the opening frame (hollow/ridge, "Walk a little further before deciding", seed and sampling scale as rival explanations); the shared-address encounter and "it does not award a point to either landscape"; the `TYPE_SIMPLEX` / OpenSimplex2 naming and "here we also have a way to check what they claim"; FREQ on one side, MATCH (both) and REPLAY (one); "the display has stopped spending its answer on height" and the display-grid / internal-lattice warning; "Matching conditions costs us possibilities"; the small sheet as a work that fails the pair's contract; "A return always has a scope"; the blob-culture argument (lines 84-88) verbatim; the bridge to Cellular Automata. All four code excerpts, every `<!-- @token -->` anchor, the engine-docs link. The matched comparison is not touched.

## Changes

**1. "settles" → "drops at once".** Audit and re-check agree (overstated). VIEW is one immediate rewrite with no transition.
- `algorithms/randomness/simplexnoise/pair_study.gd:58-61` — `toggle_view` calls `apply_grid_config({"readout": ...})` on both works in one call; `:79` sets the marker's y in the same `refresh()`.
- `algorithms/randomness/simplexnoise/SimplexVisualizer.gd:115-117` and `algorithms/randomness/perlinnoise/NoiseVisualizer.gd:124-126` — plate sets `cube.position.y = 0.0` directly.
- No `Tween`, `create_tween` or position lerp anywhere in either folder (grep, 0 hits).
- Used the re-checker's wording ("as the relief drops at once into two flat arrangements").

**2. "The colour retains the sampled values." → qualified.** Audit and re-check agree (overstated as a general claim; true in the order the chapter narrates). On the Simplex side, VIEW after REGEN reseeds the field to the declared seed, so the colours no longer show the values sampled before VIEW. The Perlin side does not do this.
- `algorithms/randomness/simplexnoise/SimplexNoise.gd:341-345` — a readout change sets `changed = true`; `:372-374` then runs `_apply_contract()`; `:153-154` reseeds whenever `current_seed != seed_value`.
- `algorithms/randomness/simplexnoise/SimplexVisualizer.gd:137-140` — REGEN sets `current_seed = randi()`.
- `commons/maps/Noise_Perlin_Simplex/map_data.json:655` — both tokens declare `#seed:20260910`.
- `algorithms/randomness/perlinnoise/PerlinNoise.gd:316-320, 321-351, 358-364` — Perlin keeps readout in `changed` and seed/size/ramp in `contract_changed`; a readout-only config goes to `set_dna` (`NoiseVisualizer.gd:157-168`), which never reseeds.
- Colour is still computed from `world_y` in every readout (`SimplexVisualizer.gd:126-130`), so the rest of the sentence holds.
- Used the re-checker's wording. "Since MATCH or REPLAY" fits the chapter's order, which begins with REPLAY.

## Left alone

- The technical.md sentence about the twin lookup. It is not in final.md, and the re-check found it accurate. The timing gap belongs to the code and to technical.md.
- "Return to relief. The same answers regain height." True even after REGEN: the reseed happens when VIEW goes to plate, so the answers that return are the plate's answers.
- The portal, the demo scenes' extra lights and cameras, and the hidden overclaiming label and `@identity` block. The audit shows none of them doing work a visitor meets, so the chapter's silence is correct.
- The optional pacing move (the gradient-noise paragraph and the `_noise_type_for` excerpt to technical.md). This is style, not a false claim.
- The brief's limits are respected: the chapter never says random land cannot be optimised, and never says a noise basis guarantees walkability.

## Limits

- **The code fix makes change 2 unnecessary.** If `SimplexNoise.apply_grid_config` is changed to treat a readout-only change like Perlin does (`_update_noise_parameters()` without `_apply_contract()`), the "unless ..." clause becomes false and should be removed. The plain "The colour retains the sampled values." can then return.
- Everything here comes from reading the code. I did not run Godot, and there has been no headset walk (`accepted-run.json`: `headset_verified` false).
- The audit's landing warning still applies. The Sep 13 afternoon pass, including the `#study:compare` hook that the SAMPLE/VIEW/MATCH instrument depends on, is only in the working tree. The study is built once and depends on the order in which works arrive, so it may be missing under patient or VR stamping. If it is missing, this whole encounter is missing too.

## Installed

`after.md` was installed to `commons/maps/Noise_Perlin_Simplex/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: LF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `0748a01ffa37…`, after `afb16c279fd6…`. No runtime or learner status changes, because the text changed and nothing new was walked.
