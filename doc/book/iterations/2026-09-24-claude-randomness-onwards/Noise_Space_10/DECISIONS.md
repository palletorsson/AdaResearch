# Noise_Space_10: decisions

## Verdict

Targeted revision. The chapter's main claim holds: the collider follows the surface you can see. Four overstated sentences were reworded, and one sentence was added to fix how the steepest-stretch claim leads into "why this walk stopped". Nothing else changed.

## Preserved

- Every question, the voice, the paragraph order, the three code excerpts (NoiseSpace.gd:152-154, :148-150, :134-136, re-read and matching), both footnotes, and the `<!-- @noise_space -->`, `<!-- @dark_sphere -->` and `<!-- @ -->` anchors.
- The mesh/collision passage, the edge-envelope passage, the heightfield and cave limit, the shelter paragraph, and the orb clock versus RESET. The audit's Preserve list covers all of these.
- The hedges ("one body, one approach and two settings", "It does not tell us that no body could pass", "It has not promised an easier passage"). They meet the brief's rule against calling random land impossible to optimise.

## Changes

1. **Posts.** "pale posts" became "glowing turquoise posts". The auditor and the re-checker agree. I used the re-checker's colour name. Evidence: noise_walk_study.gd:32-35 builds the posts with `Kit.emissive(Color(0.25,0.9,0.8),0.6)`, and hangar_kit.gd:213-220 sets both albedo and emission to that colour.
2. **HEIGHT waits.** "HEIGHT waits if a player body is still on the patch." became "HEIGHT and RESET refuse while a player body is still on the patch: the press is dropped, not saved, and the readout asks you to return to the margin." The auditor and the re-checker agree. Evidence, all in noise_walk_study.gd: at :53-60, can_rebuild returns false when a player_body or em_walker body is inside the patch. At :62-65, set_height returns before it changes anything. At :72, next_height ignores that return, and the file has no retry. At :77-79, RESET goes through set_height(1). The message is at :130.
3. **Each proposed route.** "of each proposed route" became "of whichever proposed route is selected". The auditor and the re-checker agree. Evidence: noise_walk_study.gd:95-111 computes one surface_length/maximum_grade pair for the current route_index, and :126-127 prints only that pair. *This change is outside the hall note's five-item list.* That list repeats the audit's summary line, which leaves this claim out. I made the change because the audit and the re-check both confirm it. Revert it if the orchestrator meant "only" literally.
4. **Orb.** "The dark orb rests on the raised margin." became "The dark orb hovers beside the raised margin." No re-check covered this claim, so I checked it myself before changing it, as the hall note asked.
   - map_data.json:611 puts dark_sphere at cell (11,3), on structure 2. :651 puts the NoiseSpace stand at (6,6).
   - GridInteractablesComponent.gd:1125 places each work at `x * total_size`, the centre of its cell. The orb is therefore at x 11.0.
   - noise_walk_study.gd:27-29 builds the stone margin with boxes centred at ±4.4 and 0.8 wide. Its outer edge is at 6 + 4.8 = 10.8. The orb stands just past the margin, not on it.
   - dark_sphere.gd:454 sets float_height 0.25, and :779-785 describes "one sphere floating over the halo". "Rests" was wrong.

## Added (one sentence)

After the footnote reference in the paragraph on the forty-five-degree limit:

> That stretch is a descent, and the body got past it; the walk ended at the foot of the climb out of the hollow it leads into, where several sampled stretches also exceed the limit.

The re-checker said the surrounding sentences are true and suggested this clarification as optional. The hall note asked for "the link between the steepest stretch and where the body stopped" to be fixed. I checked every figure again in doc/research/possible-bodies/noise-space-ten-evidence.json:

- measurements.cases[3].routes[0].profile: segment 36, z -1.20 to -1.12, is -58.3° and the maximum. Segments 37-39 descend at about -50°. The hollow's bottom is y 0.468 at z -0.72. Segments 45-52, z -0.48 to +0.16, climb at +42.9° to +51.0°, and six of those eight are above 45°.
- measurements.walks[1].end = (-0.232, 0.748, -0.376): about 0.1 m into that climb.
- measurements.walker.floor_max_angle_degrees = 45.0.
- noise_walk_study.gd:104 uses abs(dy), so the readout does not show that the stretch is a descent.

## Left alone

- **"At 0.90, the same forward input stopped partway across."** and the footnote's "stopped partway at 0.90". The hall note named "stopped partway", but the re-checker showed the auditor wrong, and the rule is to leave a sentence in that case. At 0.25 the same 120-frame input carried the body 9.86 m. At 0.90 it carried the body 3.97 m, and the walk ended 0.1 m into a sustained climb steeper than the controller's 45° limit. The footnote claim was not re-checked on its own. It is the same claim, so I left it too.
- **"Increasing HEIGHT took the steepest sampled stretch ... above it."** and **"That helps us ask why this walk stopped."** The re-checker found both true as written: it is the same segment at both scales, and "ask" is not "explain". They are kept, with the addition above.
- Every sentence on the audit's Preserve list.

## Limits

- I did not run Godot. The orb's position is worked out from placement code and the map, not from a render. For the museum lane I relied on the audit's reading that the pack report shows no slide.
- The claim that the walk "stopped" is inferred: the probe keeps only the start and end points (the audit's evidence on "stopped partway", and the re-checker's remaining gap). The chapter's wording stays within that.
- Repo state, not touched: `git status` shows that NoiseSpace.gd and commons/maps/Noise_Space_10/map_data.json are modified and uncommitted. At HEAD, the chapter's ground_at and edge_weight excerpts exist in no committed file (audit handover item 1). technical.md's teleporter line (handover item 5) is outside the files I may write.
- The audit cites the evidence at ada_encyclopedia/public/...; I used the copy in this repo at doc/research/possible-bodies/noise-space-ten-evidence.json.

## Installed

`after.md` was installed to `commons/maps/Noise_Space_10/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: CRLF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `0336acd8fbdc…`, after `66acc8cc33ef…`. No runtime or learner status changes, because the text changed and nothing new was walked.
