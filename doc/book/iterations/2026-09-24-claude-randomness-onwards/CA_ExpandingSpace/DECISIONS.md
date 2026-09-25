# CA_ExpandingSpace: decisions

**Verdict:** targeted revision. I changed three sentences because the audit and its re-check agree they are false or overstated. I changed one word in a fourth sentence so that it still points at something after the first change. I added nothing. The rest of the chapter is unchanged.

## Preserved

- The title, both `<!-- @decaying_bridge -->` / `<!-- @ -->` anchors, all three code excerpts and every question put to the visitor.
- The desk sequence (SOURCE to PROBE / NEAR, RUN, the gold square W, colour and then a faint sheet), withdrawal with NEAR/FAR, the edge recovering before the centre, and the VISITOR input. The audit checked these against `proximity_study.gd:45-64,119-123` and `decaying_bridge.gd:113-117,128-131`.
- Health in [0,1], the fixed decrement, distance measured in 3D to the body origin, no weight, the probe having the same influence, four-neighbour recovery above 0.5, 0.3 supporting you without counting as healthy, the collider switching off below 0.2. I re-read `decaying_bridge.gd:96-135` myself.
- The CHAIN / SYNC / SCAN / REVERSE passage. I recomputed it from `proximity_study.gd:28-30` and `decaying_bridge.gd:106-118`: SYNC gives W 0.505 and the next cell 0; forward SCAN gives the next cell 0.010; reverse gives 0.000. It matches the chapter.
- "At thirty simulated seconds" (`LIMIT := 300`, 0.1 s per tick, `proximity_study.gd:4,78`), the close, and the handover to CA_SoftRules. That room comes next in `commons/data/map_authored.json:112-113`, and its chapter opens "What can a cell receive?".

## Changes

1. **L5, the frieze's position.** The sentence was overstated: the auditor and the re-checker agree.
   - Before: "Its colours repeat in a panel along the wall."
   - After: "Its colours repeat in panels on a free-standing frieze beside the basin."
   - Evidence: `FriezeBack` is a free-standing board at bridge-local x 3.1, between two `FriezePost`s (`proximity_study.gd:110,116`). It carries 16 x 5 = 80 `HealthPanel`s, each with `material_override = work.materials[cell]` (`:111-115`), which are the bridge's own materials (`decaying_bridge.gd:90`). The bridge stands at map cell (7,4), yaw 0 (`map_data.json` interactables row 4). That puts the board on column 10, and the hall wall is on column 14. I used the re-checker's phrase with one change: I wrote "panels" instead of "a row of panels", because the 80 panels form five rows of sixteen (`:114` sets the height by `x`).
2. **L11, which side the ramps are on.** The sentence was false: the auditor and the re-checker agree.
   - Before: "The ordinary museum floor continues alongside the basin; recovery ramps rise from its left side."
   - After: "The ordinary museum floor continues alongside the basin; recovery ramps rise at either end of its right-hand edge, on the desk's side."
   - Evidence: both ramps span local x -2.5 to -1.55. `EntryRecovery` climbs to floor level at the near end (z -0.5) and `ExitRecovery` at the far end (z 9.5) (`proximity_study.gd:103-104,162-164`). The desk (`:134-136`) and the `SupportPost` (`:124`) are also at -x. The visitor enters at low z: the spawn is at row 1 and the teleporter at row 26 (`map_data.json` utilities). The `WitnessReadout` is turned 180 degrees so that it faces a reader at low z (`:146`). The museum places the node at cell + 0.5 and does not rotate it when the yaw is 0 (`commons/scenes/endless_museum.gd:13227-13229,13267-13268`). For someone facing +z, -x is on the right. I used the re-checker's wording. "On the desk's side" holds whichever way a reader happens to be facing.
3. **L28, one word: "The wall" becomes "The frieze".** This is a handover repair, not a correction. The sentence is true, but its referent, "the wall", came from L5, and L5 no longer uses that word. Without the change, a book reader would look for a hall wall. The facts are the same as in change 1. The frieze panels and the backboard have no collider, because `box()` defaults to `solid=false` (`proximity_study.gd:155`).
   - Before: "The wall uses the same health materials, but its coloured panels supply no bridge collision."
   - After: "The frieze uses the same health materials, but its coloured panels supply no bridge collision."
4. **L40, "arrays".** The sentence was overstated: the auditor and the re-checker agree.
   - Before: "We have returned to the two arrays from the Life dish."
   - After: "We have returned to the Life dish's two buffers."
   - Evidence: `previous` and `next` are Dictionaries keyed by `Vector2i` (`decaying_bridge.gd:106-108`), and the excerpt two lines above prints `Dictionary`. The Life dish does keep two arrays, `_grid` and `_next_grid`, and swaps them (`commons/artifacts/game_of_life_petri/game_of_life_petri.gd:112-113,419-421`). CA_BeyondBinary's chapter calls them "the two buffers" (its final.md:24). I used the re-checker's wording.

## Left alone, and why

- **"To your left" for the frieze.** The auditor offered it and the geometry supports it (+x is on the left of someone facing +z). The re-checker's wording did not include it, and L5 does not need a direction. "Beside the basin" is enough.
- **The six rear-gallery works** (ca_chair_test, catalyst_vent, catalyst_prompter_box, dark_sphere, cellular_automata_3d_tree, crossway_ca). The museum builds them (`ada_run/em_plan.json` plans[90]). The chapter makes no claim about any of them. The hall's intent says "six are retained for later encounters" (intent.md). Writing about them would mean checking two further CA rules and two catalyst game systems, and none of that serves this chapter's question. "The museum continues" stays as the only gesture towards them.
- **Every other sentence.** The audit marks it true, and nobody disputed it.

## Limits

- **The floor label contradicts the corrected prose.** `BasinNote` reads "FIXED BASIN 0.60 m BELOW / RECOVERY RAMPS ON LEFT". It is rotated (-90,0,0), so it reads upright only to someone facing -z, back toward the entry (`proximity_study.gd:130-131`). The `WitnessTag` (`:123`) is also upside down to a visitor coming in. I could not edit code. The chapter's "on the desk's side" gives a reader standing in the hall an unambiguous landmark. A code session should rotate the label to (-90,180,0) and make it read "ON RIGHT". That is audit fix 4.
- **The frieze board is not solid.** Only the posts have colliders, so a body can pass through the board. The chapter's claim, "no bridge collision", is still true. Whether the board should block movement is a space decision (audit fix 5).
- **Other lanes and fallbacks.** If `artifact_placement: "map"` were removed, the stale bench stamp in `ada_run/necklace_hand.json` would build the old 5x30 bridge with no study. In the grid lane, the bridge would sit 0.5 m below the floor (`GridCommon.gd:110-113`). The chapter describes only the museum encounter.
- **Companions.** critical.md overstates the source label. walked.md and eye_shot.md describe the layout before the rewrite. All three are outside my write scope.
- Godot was not started. The left/right result comes from the code and the map, not from a capture or a walk.

## Installed

`after.md` was installed to `commons/maps/CA_ExpandingSpace/final.md` on 24 September 2026. First an independent second agent checked every changed or added sentence against the code. Its verdict was install or install-with-fixes, and one fix applied: the frieze stands 'beside the path', not 'beside the basin', so the next sentence's 'Beneath it' points at the path. Line endings: LF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `e862892a45ed…`, after `a4d172fc5f2e…`. No runtime or learner status changes.
