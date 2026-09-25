# Handback for Astra: Randomness, Noise, Cellular Automata

Claude (Opus), 24 September 2026. Brief: `doc/book/handoffs/2026-09-24-claude-randomness-onwards/START_HERE.md`. Stopped before Fractal_Recursion, as assigned.

**In one line:** 31 halls. 1 preserved, 24 given targeted revisions (three of them also received an encounter repair), and 6 developed through encounter work in the map or the artifact. Every revision is installed in the canonical `final.md`, so there is no `candidate.md`. Nothing is committed. Nothing was walked in a headset.

> **Read first: four of these chapters were rewritten by another session after this block installed them.** Between 14:16 and 14:20 on 24 September, with no forum post before the change, another session rewrote the canonical `final.md` of Randomness_10_PRINT_Algorithm, Random_Cubes, Noise_Perlin_Simplex and CA_Introduction. It also added `#study:arrival` to CA_Introduction's line-network token and an arrival history to `LineNetworkCA.gd` (forum 260924-zgl38).
>
> - The rewrites drop content this block had verified: for example, 10 PRINT's breathing-coin reading, and Cubes' dead-level/tilt instruction and pip rule.
> - Nothing was reverted; which text stands is Palle's and Astra's call.
> - This block's verified versions are the hall folders' `after.md`. Copying one to `final.md` with the baseline line endings restores it byte for byte.
> - `HASHES.txt`, `text.diff` and INTEGRATION section 8 describe this block's versions, and each affected `HASHES.txt` adds a `LIVE` line.

**Where things are:**

- Each changed hall has a folder, `<Map>/`, holding `before.md`, `after.md`, `text.diff`, `DECISIONS.md` and `HASHES.txt` (text before and after, plus the map where it changed).
  - Where an encounter changed, the folder also holds `map.diff`, source diffs against `<file>.gd.before.txt`, gate transcripts (`*.out.txt`) and PNGs.
  - The preserved hall keeps only its before copies.
- The table is `STATUS.md`. Shared patches are in `INTEGRATION.md`.
- `_dependencies.md` lists, per hall, the uncommitted code the chapter runs on.
- `_impact/` holds the `tools/artifact_impact.py` reports.
- `_frame_cost/` holds the frame-cost tools, specs and outputs.

## 1. What each hall got, and why

**Preserved (1).** Random_Noise_Types. All 34 factual sentences and six code excerpts hold against the code, and the museum builds the hall from its map with every config key. No edit was made.

**Developed (6).** In each of these the encounter was broken in the museum before any sentence was wrong. Text alone could not have fixed them.

| hall | what the visitor met before | what they meet now | evidence |
|---|---|---|---|
| Randomness_10_PRINT_Algorithm | a printer, a floor, and upright fields that can be seen but not entered | the same stream of 12 characters stood up as 2.40 m solid walls, walkable, with one way through (8 regions: 7 open, each with exactly two mouths) | `probe_ten_print_hall.gd` (cases A-J, 13 checks), `probe_ten_print_walkable.gd` (A-I, E2), transcripts in the hall folder; `hall_tp_eye.png`, `hall_tp_vest.png`, `hall_plan.png` |
| Random_Cubes | on a desktop a thrown die was read 2 times in 16 (60 Hz); the reward rain fell 126 m away, and later onto the die; a held coin was counted in the hand; the force-placed bench put two spawners in one cell | the die is read 16/16 as the face on top, at 60 Hz and at 90 Hz; the rain falls over the table on its own collision layer; the coin is read once on landing; the existing `#disclosure:origin` gauges are switched on; the hall is map-placed | `probe_random_cubes.gd` (transcript in the hall folder), with shipped-script negative controls for A, B, C, F and G; H is also compared with the shipped script. Only G, the thrown die, ran at 90 Hz. SPIN and DROP gauges are checked; TILT is not. `hall_rc_plan_map.png` shows the hall as built; the other `hall_rc_*.png` show the old bench layout |
| Random_Rotate_Random_XYZ | two decay stacks at different rates, drifting, sinking and darkening, so the comparison the chapter proposed could not be made; the rotator also tumbled the lobby's picture frames; the exit step severed the walk | `#study:rotation`: one size, one rate, no drift, sink or colour, 12 even columns, a 10 m display; the rotator turns only a grid floor; the rig stands along the wall and the exit step is lowered | `probe_rotation_study.gd` A-E (a cube turns exactly as a matched run does, to 0.000000000 rad); `hall_rr_*.png` |
| Random_Pheromone | the bench passed only the first config key, so the comparison console, ATTRACT/AVOID and the seeded replay were never built | the hall is map-placed; a scratch museum boot (output not saved) read back comparison=true, walk_seed=190919 and a StepComparison child | `hall_plan_map.png`; the hash table in `DECISIONS.md` |
| Random_Space | the noise mixer and entropy meter were laid inside the 1 m raised ring | the hall is map-placed; the mixer stands on a 0.9 m plinth; `noise_mixer.gd` no longer dereferences a missing material when configured early | `hall_plan_map.png` |
| CA_Introduction | the bench omitted the rule explorer, the chapter's first work; the west room (rug, orb, synthesis stand) could not be reached from the entrance; the line network, which carries three paragraphs, spread about half its tangle below the deck and about a fifth into walls, and after its growth it kept scanning 64³ cells, 15-24 ms a frame | the hall is map-placed with `props_deny: ["bench"]`; a two-cell opening leads into the west room; the explorer stands full size near the east corridor's outer wall; the network has moved to the open east corridor as `#size:2.0`, a 2.0 m tangle above the floor (every line end above the deck, none in a wall, clear of the museum's dealt statue), and it stops computing when its growth ends; all 9 works are placed verbatim; the walk from entrance to exit is not severed | `probe_ca_stop_and_fit.gd` (L1-L5 against the shipped script; L4 on the shipped `#size:2.0`), `museum_network_readback.txt`, `museum_seal_map.txt`, `hall_ci_net_eye.png`, `hall_ci_net_plan.png`, `map.diff` |

**Encounter repairs in three targeted halls.**

- **CA_EdgeOfChaos.** The crack plate filled in about 75 frames, then rebuilt an identical mesh every frame: 61-76 ms of script a frame on a desktop, across four runs. It now stops after two settled frames. Against the shipped script from the same seed, the gate shows the same cracked set, stress and mesh vertices 120 frames later, so the picture and the chapter's sentence are unchanged.
- **Random_Remove and Random_Game.** The removal arena recognised no body in the headset, because the museum never sets `_player` there, so the floor removed nothing in VR. It now recognises the XR Tools PlayerBody. Its readout plate had also hidden the text. Both are gated (`probe_removal_arena_vr.gd`: V, D, S, R). Random_Game's headset caveat was withdrawn, restoring its original sentence.
- **Piers.** CA_EdgeOfChaos and Random_Remove now carry `map_info.museum.piers: false`. That takes effect only when Astra re-runs the plan (see section 4).

**Targeted (24).** Mature chapters, corrected sentence by sentence. Each went through the same chain:

1. an audit against the code of every placed work;
2. an adversarial re-check of every doubtful claim;
3. a revision that changed a sentence where the audit and the re-check agreed;
4. a second agent checking every changed sentence against the code.

Some claims had no re-check (in Random_Mushrooms, Random_Game, Random_Gaussian, Noise_Space_10 and CA_EdgeOfChaos). The reviser changed those only after confirming them in the code, and each DECISIONS file marks them. Some halls also gained sentences about placed works the chapter had ignored. CA_SoftRules gained one from the reviser's own calculation. Voice, questions, code excerpts, footnotes and anchors are kept. The re-check often overruled the audit, and in those cases the sentence stayed.

## 2. What reads and works better (samples; each `text.diff` has the rest)

- **Instructions that broke when followed literally now hold.**
  - Random_Gaussian: PAUSE is a toggle. "Return to GAUSS" after "Press PAUSE" restarted the draws, so "the landed count stays at three hundred" failed.
  - CA_BeyondBinary: the reader turned LINK off and was never told to turn it on again, so every lamp in "Predict which lamps will light" stayed dark. Added: "Press LINK again to reconnect the lamps."
  - CA_EdgeOfChaos: "Look down at the gain" became "Look up at the gain printed on the readout above the console". The readout is 1.1 m above the console.
- **Descriptions match what stands there.**
  - Random_Definition: "The patch is back." became "The patch is still there. REPLAY recoloured every cube from the seed and got the same colours, so nothing on the grid moved."
  - Noise_One: the rings "hover", since nothing holds them up.
  - CA_GameOfLife: the desk marks are bars (0.092 x 0.04 m), not squares.
  - CA_ExpandingSpace: the "panel along the wall" is a free-standing frieze beside the path.
- **Claims the code cannot back were narrowed, not deleted.**
  - Random_Remove: the guard in the removal loop never fires on this bench.
  - Random_Space_Geometry: no "future shared scale" exists.
  - CA_AgentsCircuits: the pyramid's copies overlap, because the cubes do not shrink with the spacing.
- **New passages for rebuilt encounters.** 10 PRINT, Cubes and Rotate carry passages written for their rebuilt encounters. Each was reviewed by a panel, and the ship-with-fixes changes were applied. CA_Introduction's route and network passages were checked by three verifiers (text, code, space), and their fixes applied.
- **Companions.** `blurb.md` and `intent.md` were rewritten for the six developed halls. The other companions (technical, tutorial, walked, artifacts, summary) are stale in several halls and were not touched, which is outside this brief.

## 3. Canonical, candidates, and choices left open

All 31 halls are canonical, and there is no candidate prose. These artistic and editorial choices are still open:

- **10 PRINT.**
  - The walkable block wraps 4 characters to a row. Probe case I measured the same 12 characters at other widths:
    - 3 to a row gives no way through and no sealed room;
    - 6 gives a way through and no sealed room;
    - a single line gives no sealed room.

    Only 4 gives both. The chapter treats the crop as a decision.
  - The slab height is 2.40 m.
  - The upright fields stay last, seen and not entered.
  - `@ten_print_structure` now tags two placements of one token (INTEGRATION section 1a).
- **Random_Cubes.** On a desktop (60 Hz) the landed die still hops and turns on its felt; at the headset's 90 Hz it mostly comes to rest. The chapter says it "may go on rocking slowly on its face". The reading is repaired; the physics is not. A single-setting sweep is in `Random_Cubes/die_settle_sweep.out.txt`: of sixteen throws, 2 were asleep after 6 s as shipped, 7 at bounce 0.2, 9 at bounce 0, 11 at gravity scale 1.0 and 0 at angular damp 1.5. None of the settings fixes it without changing the throw on the 22 maps that place the die.
- **Random_Walk.** The heading "## A hand with company" now falls mid-chapter in reading order. Dropping it would be a structural edit.
- **Noise_Inside_Noise.** In the one museum build on record (13 September, before a 14 September map edit) the museum shrank the enclosure to 80%. Whether it still does is unverified. The chapter now gives sizes relative to the radius, which hold at any scale.
- **CA_Introduction.**
  - The line network moved from the west passage to the east corridor. The visitor now meets it on the way to the Rule 110 display and the exit, and the west passage leads only to the showcase.
  - It is drawn at 2.0 m. At 2.4 m, one cell south-west of its final cell, it ran into a statue the museum deals into the hall, and it crossed the lane every visitor walks down. Both the position and the size are curatorial choices.
  - The grid substrate runner and the synthesis stand are not named in the chapter.
  - The orb rests on the rug's edge.
  - The rug and the synthesis stand seal two small pockets of the museum's walk map, and the stand has no reachable walk cell beside it. The walk through the hall is not severed, and every work the chapter names can be reached.
- **Code identifiers in reader prose.** Random_Remove carries `_removed`, `active_instances.remove_at` and `get_state` in sentences, beside its code excerpts. Random_Game and Random_Mushrooms carry desktop-carry qualifications. The writing brief prefers companions for such things. Whether they stay is the editor's call.
- **10 PRINT's clipboard and screen.** `ten_print_axioms` misdescribes the hall and is shared with two halls outside this block (INTEGRATION section 2). The science screen shows invented data (section 3). Leftover placements are listed in section 4. None was edited.

## 4. Waiting for integration, and checks still missing

**Shared patches** are in `INTEGRATION.md`:

- sections 1, 5 and 6: full room records for 10 PRINT, Cubes and Rotate. Cubes keeps `source_checked_draft`, since the evidence is headless gates.
- section 8: text and map hashes for every other hall, as one JSON object to merge (status fields untouched);
- section 9: the eight changed scripts (five for Randomness, `removal_arena.gd`, `LineNetworkCA.gd` and `crackpropagation_ca.gd`), with hashes, placement counts and diffs;
- sections 2-4: 10 PRINT's clipboard, science screen and leftovers;
- section 7: engine notes and open encounter items.

The section 7 items that need Astra or Palle:

- **Re-run `tools/em_map_halls.py --apply`.** This rewrites `ada_run/em_plan.json`, which is yours. Then the `piers: false` set here reaches CA_EdgeOfChaos, where a pier encloses the changed address inside volume B and damages the core encounter, and Random_Remove, where piers stand on the arena's apron. Random_Entropy (piers in the glass field) needs a decision.
- **Frame cost.** `BaseCA._process` never stops. The two worst cases are repaired here. Still to be profiled in the headset:
  - `disease_spread_ca` in CA_EdgeOfChaos: 7.9 ms of script a frame;
  - `persian_rug`: 5-11 ms;
  - CA_SoftRules' crack plate: 4.8 ms.

  A plain `self_organization_ca` costs about 4.9 s a frame, and it is placed plain eleven times on nine maps outside this block.
- **Input leaks.** In Noise_Voxel, `perlin_terrain_sculptor` reads R/N and the arrow keys across the museum. In Randomness_Examples, the dartboard's SPACE toggles AUTO from the walking keys on desktop.
- **Small encounter fixes proposed, not made:**
  - CA_ExpandingSpace's floor label contradicts the prose and faces the wrong way.
  - Random_Gaussian's compact console may hide its readout.
  - Random_Entropy's ruin has no `autostart:false`.
  - A stray prism stands in Random_Mushrooms' bed.
- **Lab_Path** is not built by the museum, and the book gives readers two handovers. Palle to decide.
- **Unchanged from earlier notes:**
  - the bench stamp passes only the first `#key`;
  - `_suppress_chrome` is never called;
  - `#stack_fit` is misread in the grid lane;
  - Random_Space's random ground severs the museum walker;
  - the die's physics.

**Commit hygiene.** Read this before committing anything from this block.

- **Chapters describe uncommitted code.** 30 of the 31 halls place at least one work whose script carries other sessions' uncommitted edits (`_dependencies.md`, a lower bound). Several revised chapters describe study mounts that exist only in those scripts: CA_GameOfLife, CA_ElementaryRules, CA_BeyondBinary, CA_SoftRules, CA_EdgeOfChaos, Noise_Perlin_Simplex and Noise_Columns, among others. Land the code with the chapters, or the chapters describe encounters HEAD does not build.
- **The packet's baseline was itself uncommitted.** With line endings ignored, 12 of the 31 `final.md` and 26 of the 31 `map_data.json` already differed from HEAD before this block touched them. Committing those files commits that earlier work too. The packet's `snapshot/` holds the baseline, so HEAD → snapshot is the earlier work and snapshot → now is this block.
- **Three scripts carry another session's uncommitted edits beside this block's:** `dice_throw.gd`, `random_decay_multimesh.gd` and `noise_mixer.gd`. The delivered diffs run from the `*.before.txt` snapshots, so they show only this block's hunks. `git diff` against HEAD shows both.
- **`LineNetworkCA.gd` is being edited live by another session.** Since 14:16 it has been adding an opt-in `#study:arrival` history on top of this block's change (forum 260924-zgl38). For about a minute (14:16:30 to 14:17:40) the file preloaded a `line_network_history.gd` that did not yet exist, so it did not compile. The file has since landed.
  - This block's own version is `CA_Introduction/LineNetworkCA.gd.block.txt`, and its diff is `LineNetworkCA.diff`. Their delta is `LineNetworkCA.other_session.diff`.
  - Do not commit the live file until they are done, and re-run `probe_ca_stop_and_fit.gd` after.
- **Six gates and `probe_hall_shot.gd` are new and untracked:** `probe_ten_print_hall`, `probe_ten_print_walkable`, `probe_random_cubes`, `probe_rotation_study`, `probe_ca_stop_and_fit` and `probe_removal_arena_vr`. No gate runner calls them yet.
  - All six pass on the tree at the end of this block. The CA gate was re-run after the concurrent `LineNetworkCA.gd` edit and still passes (`CA_Introduction/probe_ca_stop_and_fit.live.out.txt`).
  - `probe_removal_arena_vr` segfaults in teardown after printing RESULT (exit 139), so read the RESULT line.
  - Three of the gates run the shipped scripts as negative controls from the `*.before.txt` copies in `Random_Cubes/`, `Random_Remove/`, `CA_Introduction/` and `CA_EdgeOfChaos/`. Those copies must travel with the gates.
- **Line endings.** Seven CA baselines are LF. The first install wrote them as CRLF; they have been restored to LF, and their HASHES and diffs were regenerated.

**Not checked:**

- No hall was walked in a headset (pipeline stage 6 is unchanged), and no learner was observed.
- In Random_Cubes only the die's reading was gated at 90 Hz. The coin, rain and drop repairs were gated at 60 Hz only, and nothing was thrown by a hand.
- `tools/artifact_impact.py` was run after the changes, not before as OWNERSHIP.md asks. Every changed artifact belongs to one sequence of this block, but its other placements were not checked with the new behaviour: 21 other maps for the die, 57 for the coin, 12 for the rotator, and a few showcase maps for the rest.
- **The bake.** `ada_run/em_bake.json` has no row for 10 PRINT or Random_Cubes. Every one of the block's baked rows predates its map's current modification time, so the museum measures all of them live. A re-bake is Astra's.
- **CA boots.** The CA text passes read the code; they did not boot the works. The CA boots were:
  - CA_Introduction's placement and network, in the museum;
  - the line network and crack plate, in `probe_ca_stop_and_fit.gd`;
  - a headless script-cost pass over the 36 CA works.
- The pier opt-outs have not been seen in a museum boot, because the plan has not been re-run.

## 5. The question Fractal_Recursion inherits

CA_EdgeOfChaos hands over with a distinction, and its closing is unchanged: *a form can resemble its neighbour, inherit an earlier state, or be told to repeat. The resemblance does not yet explain the making.* Fractal_Recursion opens with "How many times can *again* happen?" and a square that asks for a smaller copy of itself.

The question this block leaves the next hall:

> **When a form repeats, was it told to repeat, did it inherit an earlier state, or does it only resemble its neighbour, and what would you have to see happen to tell which?**

The three sequences have prepared each part of it:

- **Randomness** separated the rule from the draw. "What chance may touch was settled before it ran."
- **Noise** separated a stored field from its reading.
- **Cellular Automata** separated local exchange from a stored history.

Fractal_Recursion is the first hall where the instruction to repeat is written into the procedure itself, so the reader can check which of the three they are looking at.
