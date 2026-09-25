# Lab_Path: decisions

## Verdict
Targeted revision. One sentence reworded and one sentence added. Everything else is unchanged.

## Preserved
- The opening question, the three recalled encounters (REMAP, the threshold, the ridge), the two tellings, "Hold a seed. Change a threshold...", the sphere's missing verdict and its pulse, and the closing "Bring one of your unfinished questions with you."
- The `<!-- @dark_sphere -->` / `<!-- @ -->` anchors, and the sphere's place as a companion to a pause, not a teacher. No primary lesson was invented for it.
- Catalyst gestation stays out, because it yields nothing for "lab path".
- The brief's constraints still hold. The chapter makes no claim that random land cannot be optimised, and none that a noise basis guarantees walkability.

## Changes
1. **"swelling surface" now has a referent.** The audit and the re-check agree this was overstated. The sentence sits right after the sphere's pulse, but the sphere never swells. `_radius` is set once, in `_resolve_presence` (commons/artifacts/dark_sphere/dark_sphere.gd:635). `_process` changes only rotation, emission, albedo and halo alpha (dark_sphere.gd:589-625). The only scaling ring is gated to `presence == "becoming"` (dark_sphere.gd:956). The sheet that does swell is perlin_noise_terrain in Noise_Perlin_Simplex, the map just before Lab_Path (commons/maps/sequences/noise.json:48-49). There, `animate` defaults to true (algorithms/randomness/noise/perlinnoise/scripts/terrain_generator.gd:83), a 0.5 s timer (:129) advances `time_offset` (:144), and the mesh is rebuilt (:166). That chapter already calls it "the small sheet". I used the re-checker's wording.
   - Before: "Perhaps what stays with you is the swelling surface itself."
   - After: "Perhaps what stays with you is the small sheet's swelling surface."
2. **Added one handover sentence naming stored state.** The hall brief asks for a handover through stored state and local dependence. The existing sentence already carries the local dependence and "the previous step". The new sentence makes the storage that dependence needs explicit. Both primary CA_Introduction works do this. ca_rule_explorer reads `_current_row` while it writes a separate `new_row`, then swaps them (commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd:374-383). persian_rug writes into `next_grid` and swaps (algorithms/cellularautomata/persian_rug/persian_rug.gd:450-481).
   - Added: "That previous step has to be kept while the next one is written."

## Left alone, and why
- **"In the cellular-automata rooms, a cell's next state will depend on what its neighbours were doing in the previous step."** The auditor wanted to add the cell's own state. The re-checker showed the auditor was wrong. The sentence says "depend on", not "only on". The room places the explorer at Rule 90, which is left XOR right, so the centre bit is ignored there. "It and its neighbours" would be false for that board. The sentence also never contrasts "noise has no rules" with "CA has rules", so it meets the brief. I did not add a noise-versus-CA contrast about re-asking a field, because Random_Noise_Types (white/blue noise) may not be a field sampled at an address, and I did not verify it.
- All other sentences are true according to the audit, and none was contested.

## Limits (structural, outside the prose, not edited)
- The museum does not build this hall. The book pearl is `drop: true` (commons/data/book/noise.json:193-197). Noise_Perlin_Simplex/final.md already hands over to Cellular Automata, so a reader of the book gets two handovers. Palle should decide whether this pause is grid-lane only or gets a hall.
- In the grid lane, the sphere and the exit teleporter share a cell (commons/maps/Lab_Path/map_data.json:61,68), so walking up to the sphere can end the pause. The chapter does not promise that anyone can stand beside it, so no prose change was made.
- `map_info.description` ("Shared endpoint for all sequences", map_data.json:6) is false, and the info board displays it. According to the audit, technical.md and tutorial.md contain invented code. None of these were edited (outside the write scope).
- Godot was not started. There was no runtime or learner verification.

## Installed

`after.md` was installed to `commons/maps/Lab_Path/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: CRLF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `3fa6bd94aa92…`, after `f566363c70e8…`. No runtime or learner status changes, because the text changed and nothing new was walked.
