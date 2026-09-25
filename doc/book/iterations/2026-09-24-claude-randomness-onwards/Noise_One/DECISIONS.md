# Noise_One — decisions

Sequence `noise`, hall 3 of 9. 24 September 2026. Verdict: **Targeted revision**. Three sentences changed; nothing added.

`after.md` is the full revised chapter. `before.md` is byte-identical to `commons/maps/Noise_One/final.md` as found; that file was not edited.

## Preserved

All of it except three sentences: the title question, every section and its order, all visitor questions, the five code excerpts (unchanged, still matching `noisetorus.gd:339-341, 346-347, 350-351`, `noiselayers.gd:188-190, 193`, `dark_sphere.gd:599-600` per the audit), the three `<!-- @token -->` anchors (`@noisetorus`, `@noiselayers`, `@dark_sphere`), and the hand-off to Noise_Voxel. Anchor count 3 → 3, code fences 12 → 12.

## Changes

Each is one where the audit and its adversarial re-check agreed. The wording is the re-checker's, or a narrower form of it.

1. **"rest" → "hover" (paragraph 1).** Nothing holds the rings up. I checked this myself. The scene root has no transform (`noisetorus.tscn:30`). Each ring is a bare `TorusMesh` in a holder at `(x, PAIR_H, 0)` with no rotation (`noisetorus.gd:396-408`). `TorusMesh` lies flat in XZ around +Y (the repo says so at `chroma_stack.gd:276`, `codex_food.gd:659`, `autoclave.gd:225`, and `_sample_point` puts markers at y = 0, `noisetorus.gd:354-357`). With `PAIR_H` 1.22, inner 0.18 and outer 0.46 (`:156-158`), the tube spans y 1.08-1.36. The post (`:415-416`) is centred at (1.22 − 0.46 + 0.78)/2 = 0.77 and is 0.08 m tall, so it spans 0.73-0.81. It stands on the ring's axis, inside the 0.18 m hole, and touches nothing. The bench top ends at 0.78 (`:381`, `PAIR_BENCH_H` `:161`). The comment at `:414` ("so the ring stands rather than floats") shows the post was sized for an upright ring.

2. **"the result" → "the same product, computed there again" (the AMPLITUDE paragraph).** Right after the `relief_of` excerpt, "the result" says the function's return value reaches the vertex shader. It does not. `relief_of` has three callers: the marker offset (`noisetorus.gd:510`), the plate (`:535`) and `pair_state` (`:607`). The shader gets `height_multiplier = PAIR_AMPS[_amp_i]` (`:490`) and `show_relief` (`:497`), then does the multiplication itself: `displacement = NORMAL * noise_value * height_multiplier * show_relief; VERTEX = object_pos + displacement` (`noiseTorus.gdshader:76-78`). The sentence's meaning, displacement along the normal, is kept.

3. **"It matters here too." → "Here the order is present in the arithmetic but not to the eye: on this model the gap is a matter of millimetres, against about half a metre of relief."** The order effect is real. Each layer button re-runs `generate_terrain` (`noiselayers_stage.gd:67-77`), and that always lowers after combining (`noiselayers.gd:131-135`). But the effect is tiny. Per pass, the lowering is `(slope − 0.5) * erosion_strength * 0.1` (`noiselayers.gd:222-224`) with `erosion_strength` 0.3 (`:55`), i.e. (slope − 0.5) × 0.03 field units. Displayed height is field × `height_scale` 2 (`noiselayers.tscn:77`) at model scale 0.02 (`noiselayers_stage.gd:29`), so each pass lowers a sample by (slope − 0.5) × 1.2 mm. My own rough bound on the gradient, from the weights 12/6/1.5 and frequencies 0.0056/0.0057/0.0175 at grid step 2 (`noiselayers.tscn:27-39, 76`), puts the largest slope near 1. The re-checker's port measured 0.9-1.1, a largest gap of 0.83-1.14 mm and a relief of 0.52-0.73 m. I wrote "a matter of millimetres" and "about half a metre", not the port's exact figures, because the port only approximates FastNoiseLite. The preceding sentence ("need not equal") is true and was left alone.

## Left alone, and why

- **"The bench supports the instrument"** (AMPLITUDE paragraph). The re-checker cited it as support for "rest", but neither pass flagged it as a claim of its own. The audit's preserve list keeps the bench as the only solid part. It is true of the bench, the posts, the readout case and the button panel, and it now sits next to "hover" in paragraph 1, so it no longer suggests the rings are carried.
- **"southern edge"** (basin paragraph). The audit offered a visitor-relative direction as optional. Neither pass called the sentence false.
- **Naming MIDDLE as cellular noise** (`noiselayers.tscn:31`, `noise_type = 2`). This was optional. "They also differ in algorithm" already covers it, and it is not a placed work the chapter ignores, so adding it would break the add-only-to-repair rule.
- **Material listed under "Placed works the chapter ignores"** (the stray prism at y 7.29, the hidden 3.67 m torus, the leftover Camera3D, the basin's vertical grid plane, the dormant gestation egg on `dark_sphere`, dealt colonnade dressing). None of these does teaching work in the hall. They are staging and engine matters, not chapter matters.
- Every sentence on the audit's preserve list.

## Limits

- Godot was not run. Change 3's figures are arithmetic from the constants plus the re-checker's approximate port. They were not measured in the engine.
- The chapter describes **uncommitted** working-tree code. `git status` shows `noisetorus.gd`, `noiseTorus.gdshader`, `noiselayers.tscn` and `final.md` modified. A headset export from HEAD would contradict the text (audit handover 1). This revision does not change that.
- Stale companions are not touched here, because they are outside the write scope. These are the 12 Sep entry in `field_notes.md` (plate "last touched", old float-hash numbers), the comments at `noisetorus.gd:176-177` (they claim `PAIR_AMPS[2]` is 0.2 and `PAIR_FREQS[1]` is 3.575, but the constants at `:167-168` are 0.02 and 14.0), and `technical.md`'s "unchanged" claims.
- A code fix would also resolve change 1: a cradle that reaches the tube at y 1.08. If one lands, "hover" should go back to a word for being held up.

## Installed

`after.md` was installed to `commons/maps/Noise_One/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: LF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `6d9528ae1be3…`, after `b0f02dc3f2a7…`. No runtime or learner status changes, because the text changed and nothing new was walked.
