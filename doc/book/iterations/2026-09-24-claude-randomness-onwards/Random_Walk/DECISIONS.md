# Random_Walk: decisions

Sequence `randomness`, hall 7 of 14. 24 September 2026. Verdict: **Targeted revision.** Text only. No code, map or repo file was touched.

## Preserved

The title, the opening question, every code excerpt, every `<!-- @token -->` anchor and every region's wording apart from the two sentences below. That includes all thirteen sentences the audit listed under Preserve and the handover in from Random_Rotate_Random_XYZ ("The last room let perturbations accumulate in a stack"). The random_draw_dot section keeps its heading and its text word for word. It has only moved.

Region check (`tools/final_tags.py` parse): before = untagged / terrarium / 128 / hall / dot. After = untagged / terrarium / dot / 128 / hall. The dot, 128 and hall regions are byte-identical. Only the terrarium region changed, from 876 words to 954.

## Changes

**1. The tank's back is closed.** Audit and re-check agree the sentence is overstated. I used the re-checker's wording for the first clause only.
- Before: "Walk around the tank: the thin arrangement holds."
- After: "Move from the front to either side of the tank (a dark board closes the back): the thin arrangement holds."
- Evidence: the map places the terrarium with `stand:logbook` (`commons/maps/Random_Walk/map_data.json:1315`). Under that stand `_apply_stand` calls `_build_backboard` (`commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd:712-725`). The board is `terrarium_size + 0.30`, so 0.8 x 0.7 m. It is opaque matte albedo (0.10, 0.11, 0.13) at roughness 0.92, and stands 0.04 m behind the rear pane (`:742-755`, with `terrarium_size` at `:60`).
- The next sentence ("A route that looked crowded from one side may open when you look through another") is still true with three usable panes, so I left it alone.

**2. Repaired handover: the dot section moved into walk order.** The audit and the sequence reader both say the Random Gaussian handover sat mid-chapter, with the dot section added after it, so the chapter ended on "Let go and the wandering stops."
- The `random_draw_dot` region, heading included, now comes between the terrarium's MSD paragraph and the `random_walk_128` region. The hall region with the handover is last again.
- This also matches the floor. The dot stands at (6,8) (`map_data.json:1375`). The basin is structure row 10: cols 2-7 and 11-16 are 0, and the bridge is cols 8-10. The field stands at (9,17) (`:1567`).
- The dot's text now leads straight into "Cross the bridge over the narrow basin".

**3. Added: pixel_cloud, the relation the chapter says "would have to be built".** Three sentences follow "To make a walker avoid its own trail, that relation would have to be built."
- Added: "Between this cabinet and the basin, a small sculpture of cubes shows one way to build it. Before each step, that walk sets aside every neighbouring cell it already occupies and chooses among the rest; if none is left, it stops. The walk runs once, when the hall is built, and what stands is the path alone: the free cells it passed over are not drawn."
- Placement: `pixel_cloud:180:0.1:0.18#walk_seed:101` at (3,9) (`map_data.json:1393`). That is rows 6-9, between the terrarium (row 5) and the basin (row 10).
- Small: the fourth token field is the uniform scale 0.18 (`commons/scenes/endless_museum.gd:11159`). The museum passes every `#k:v` segment (`:11261-11269`), and `walk_seed` is accepted (`algorithms/randomness/pixelcloud/pixel_cloud.gd:344-348`).
- The rule: six neighbour directions (`pixel_cloud.gd:101-108`). A move is valid only if it is in bounds and not in `occupied_cells` (`:152-158`). The walk stops when no move is valid (`:160-162`), and the choice is weighted among the valid moves (`:165`).
- Runs once: `_ready` builds (`:110-112`). A regenerate on `ui_accept` (`:317-321`) replays the same seeded walk.
- Not drawn: `evidence` defaults to `result` (`:77`), and the map does not set it. Unchosen neighbours are recorded in `forgone_cells` (`:166-168`) but drawn only under `longhand` (`:235-236, 241-255`). Under `result` every cube is identical, with a tint only under `trace` (`:232-233`).

## Left alone, and why

- **"accumulate in a stack".** The re-check found it true. The singular is generic, holds for each of the two stacks, and matches the last room's own title.
- **The 128 field's "keeps another account".** The re-check found it true. The walk finishes about 8 s after the hall is built and differs every boot, but "keeps" describes a finished record, and the next paragraph reads it that way.
- **"the openings let you pass through or watch from outside".** The re-check found it true. There is a clear ring about 0.98 m wide between the cubes and the glass, and it joins both doorways.
- **"the grip from Trace with one addition".** The re-check found it true: same scene instance, same recorder, same plinth height.
- **"At that boundary, the program shortens an outward proposal".** The audit flagged it, but no re-check was recorded, so the rule does not allow a change. On my own reading it is defensible. `limit_length(RADIUS)` (`commons/artifacts/randomness_space/random_draw_dot.gd:49`) shortens the proposed new offset along its own direction when it passes 25 cm.
- **Omissions about works already described.** A mode press restarts the walk: the `walk_mode` setter calls `_reset_walkers` (`random_walk_terrarium.gd:73-76`). The trail also fades (alpha ramps from nothing to 0.6 along it, `random_walk_terrarium.gd:84`). Neither makes a sentence false, and the brief allows additions only for ignored works or handovers. A later pass could qualify "Try it, then return to 3D. Look for what the longer movements do to the tangle." Returning to 3D clears the LONG STEP tangle.
- **random_walk_leash.** It is ignored by the chapter, but I did not add it. It applies a random impulse every 0.3 s (`algorithms/randomness/random_walk_leash/random_walk_leash.gd:247-250, 407-414`) and a leash force only while held (`:254-255, 438-445`). It makes no haptic call, and whether a held XRToolsPickable passes the tug to the hand is unverified. The bodily claim would be the whole point, so I left it out.
- **random_walk_collection.** The laws on its six sheets are unverified, so I made no claim about them.

## Limits

- **The heading now sits mid-chapter.** "## A hand with company" still opens the dot region. In rendered reading order it now comes before the 128 field and the closing, so a renderer that scopes by heading will group them under it. Dropping the heading would be a structural edit outside this brief. It is for the editor to decide.
- **Nothing was walked or booted.** pixel_cloud's seeded shape, its visibility at 0.18 scale, and the stray Camera3D and DirectionalLight3D in its scene are all unmeasured. `ada_run/em_bake.json` for this hall is stale: it lists the old lab_room, dark_sphere and catalyst placements. It cannot confirm the current layout, so the map is the authority here.
- **Companions left as they are.** The stale companions the audit lists (technical.md, intent.md, walked.md, tutorial.md, artifacts.md) are outside this brief.
- **Line endings.** after.md is LF. before.md is CRLF.

## Installed

`after.md` was installed to `commons/maps/Random_Walk/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: CRLF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `a72a6459a2fd…`, after `a9aceb725976…`. No runtime or learner status changes, because the text changed and nothing new was walked.
