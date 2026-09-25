# Noise_Voxel — targeted revision, 24 September 2026

## Verdict

Targeted revision. The audit and its adversarial re-check agreed on five claims: one false and four overstated. I made the five fixes, plus one consequential word change so a later sentence still has its referent. I added no new material. `after.md` is the full revised chapter. `before.md` is byte-identical to `commons/maps/Noise_Voxel/final.md`, which I did not edit.

## Preserved

- The title, all four `<!-- @token -->` anchors and the closing `<!-- @ -->`, and the order of the sections.
- All three code blocks and the code quoted in the footnote, verbatim. The audit found them source-exact.
- Both footnotes (`voxel-pieces`, `voxel-screen`).
- The opening THRESHOLD question, the strict predicate ("Equality goes with empty"), the bias arithmetic, the no-gravity sentence, and the pieces passage.
- The CUT passage, the screen passage, the paragraph on two readings, and SEED.
- The shared-sampler paragraph, "connected is not walkable", the cavity paragraph, the orb's continuity with earlier halls, and the handover to Noise 6 Wall.
- Everything the audit's Preserve list names, left untouched.

## Changes

1. **Opening: the cell marker.**
   - Before: "The yellow cage names a cell, including when that cell contains nothing you can see."
   - After: "A translucent yellow box marks one cell, whether or not that cell holds a block. Deep inside the body, the blocks around it can hide the box until CUT opens the near half."
   - Reason: it is not a cage, and it is not always visible. The marker is a filled `BoxMesh`, 1.9 voxels wide, alpha 0.55 and unshaded (`perlin_terrain_sculptor.gd:602-605`). The code comment at `:598` says "wire cage", but nothing in the code builds one. The marker is placed at the cell centre without reading `_voxels` (`:635-642`), so it does mark empty cells. The voxel blocks are opaque (`:210-221`).
   - The start cell is (12,12,12) (`:99`). CUT hides instances with z > 12 (`:381`), so it opens the start cell's layer to view. The cut half is local +z, the side the readout case faces (`:581`), so it is the near half for someone at the panel. I used the re-checker's wording verbatim.

2. **Opening: the two bodies.**
   - Before: "...has the same irregular outline."
   - After: "...has the same irregular outline, turned half round."
   - Reason: the bench token carries yaw 180 and the volume token has none (`map_data.json:109, 111`). The as-built plan agrees: row 81 of `ada_run/em_plan.json` gives rotation 180 and 0. The museum applies the yaw only when it is non-zero (`endless_museum.gd:13267-13268`).
   - Both scripts map an index to a local position the same way (`perlin_terrain_sculptor.gd:384-388`; `voxelnoise.gd:316`). Seen from where the room places the visitor, the bodies therefore show opposite faces. This is the re-checker's wording.

3. **Screen section: follow-on to change 1.**
   - Before: "The cage visits another address..."
   - After: "The box visits another address..."
   - Reason: this keeps the referent after change 1. The same marker is moved by `next_cell()` (`perlin_terrain_sculptor.gd:669-679`).

4. **Screen section: what the left panel gives.**
   - Before: "The binary mask cannot tell you how far a rejected value missed the line; the other display can."
   - After: "The binary mask cannot show how far a rejected value missed the line; the other display keeps that difference as a shade, darker the further below, though it prints no scale."
   - Reason: the left panel is a purple-to-teal lerp over clamp(score·0.5+0.5) (`science_screen.gd:2569`). It has no legend and no contour at the threshold. Its only labels are the panel title (`:2563`) and the footer text "score > t" (`:2574`).
   - The ramp brightens monotonically with the score, so a lower score (further below the line) is darker. This is the re-checker's wording.

5. **Volume section: viewing height at the bench.**
   - Before: "The bench lets you look down into the arrangement; here parts of it rise above your head."
   - After: "At the bench you look down on most of the arrangement, though its top layers reach just above eye level; here parts of it rise above your head."
   - Reason: the token's y-offset of 1.35 becomes `hover_m` (`endless_museum.gd:11312`). The node origin is set to top + lift + hover (`:13228`). The model is centred on that origin, with cells at (i − 12 + 0.5)·0.04 (`perlin_terrain_sculptor.gd:384-388`). That puts the model at roughly 0.87 to 1.83 m.
   - The desktop eye is 1.65 m (`endless_museum.gd:190`). The first-person constant is 1.62 (`:20930`). Either way, the top layers sit above the eye. This is the re-checker's wording.

6. **Orb section: the pool.**
   - Before: "The dark orb is still here, turning above its pool of light."
   - After: "The dark orb is still here, turning above its faint violet shadow."
   - Reason: the token is a bare `dark_sphere` (`map_data.json:114`), so it gets the default presence, witness (`dark_sphere.gd:467`). The witness lamp is "none" (`:489`), so `_add_presence_lamp` returns before it adds any light (`:906-907`).
   - The disc is described in the code as a "shadow/halo disc" (`:983`). It is unshaded, coloured (0.1, 0.04, 0.16) (`:999, :1020`), and its alpha pulses between 0.08 and 0.20 (`:639-640`). The file header also calls it a soft shadow (`:11`). The Y rotation is real (`:594`). This is the re-checker's wording.

## Left alone, and why

- The THRESHOLD start value. The audit suggested stating 0.00 → +0.10 → +0.20 → wrap to −0.20, but it did not flag the current sentences as false. "Visits five values and then returns to the first" and "Something has disappeared" after two presses from the start are both accurate.
- The frame label on the volume ("SAME 24 x 24 x 24 CELLS | FIVE TIMES THE MODEL") and the screen footer ("Darkness is a decision, not missing data."). The chapter already covers both works, and adding either line would not repair any claim.
- The map's utilities (turn cubes, spawn, teleporter). The audit did not check whether the museum builds them, and the chapter makes no claim about them.
- The orb pulse excerpt, even though it is the third hall in a row to quote it (audit handover h). That is an editorial choice across three chapters, not an error in this one.
- The layout fix of placing the volume at yaw 180 and moving its label. It is a map and code change outside this brief. If it lands, change 2's "turned half round" must be removed.

## Limits

- I read the code and did not run it. Godot was not started. The visibility of the marker at the other four CELL addresses is not claimed, and CUT may not reveal (17,6,9) or (9,17,6) (`perlin_terrain_sculptor.gd:672`). The revised sentence speaks only about the start state.
- The audit's handover still stands. The map, `perlin_terrain_sculptor.gd`, `voxelnoise.gd`, `science_screen.gd` and `final.md` that make this chapter true are uncommitted working-tree state. HEAD's `science_screen.gd` has no `voxel_slice` mode. A stash or checkout would make both `before.md` and `after.md` false.
- Other risks are recorded in the audit and not addressed here. The bake row is stale against the map's modification time. `perlin_terrain_sculptor._input` is live across the museum: R/N reseed and arrow keys move the threshold off its ladder. In VR, a demoted hall resets SEED and THRESHOLD.
- Headset reach, traversal and Quest cost remain unverified.

## Installed

`after.md` was installed to `commons/maps/Noise_Voxel/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: CRLF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `0339bbfd0b39…`, after `1714ff63c8bb…`. No runtime or learner status changes, because the text changed and nothing new was walked.
