# CA_Introduction: decisions

## Verdict
**Development.** The encounter was repaired in the map before this text pass: `map_info.museum = {artifact_placement: "map", props_deny: ["bench"]}` (commons/maps/CA_Introduction/map_data.json:25-30), row 1 cols 5-6 opened (map_data.json:103-104), and the explorer turned to 270 (map_data.json:727). On the prose side this is a targeted revision. Six sentences were changed and nothing was cut. The added words are positional clauses in three of those sentences, plus two short sentences in the closing list.

## Preserved
- The title question, the opening frame, the noise recap paragraph ("Keep the pleasure of the blob. Bring an unfinished question with it."), which already echoes Lab_Path's closing, and every teaching passage the audit listed under Preserve.
- Both code excerpts, verbatim: `_apply_rule` (commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd:368-370) and the `_advance` loop (:377-383). Also the `_enforce_quadrant` excerpt (algorithms/cellularautomata/persian_rug/persian_rug.gd:361-365).
- All four `<!-- @token -->` anchors (4 before, 4 after) and all six code fences.
- The Rule 90 `100`/`010` comparison, STEP/RUN/SEED/CELL/RST, the wrap, "Twenty-four rows", the mirror remaining at work, the textile disclaimer, "The line does not prove which earlier cell caused the birth", the twenty growth updates, the three carried choices, and the hand-on to the structure-growth specimen (commons/maps/CA_ElementaryRules/map_data.json holds `structure_growth:0:0#study:states#plinth:0`).
- The bridge from Noise stays as stored state and local dependence. The old row is kept while the new one is written. The chapter never says noise has no rules.

## Changes
1. **L3, "Across the room, a small board..."**
   - Before: "Across the room, a small board holds one green cell and waits."
   - After: "On the other side of the dividing wall, a board holds one green cell and waits."
   - Why: the audit and the re-check agree it was false. The col-7 wall (height 4, rows 1-16, map_data.json structure rows 1-16, index 7) separates the rug's room from the board's corridor, and nothing can be seen across it. I used the re-checker's wording as given. The re-checker thought "small" could be defended, but its rewording dropped it. In study mode the board is 1.6 m (ca_rule_explorer.gd:106).
   - Still true: the board is held (`auto_run = false`, :109), seeded with one centre cell (:361), and drawn in green `alive_color` (ca_rule_explorer.tscn: `alive_color = Color(0.2, 0.9, 0.4, 1)`). The map lane passes every `#key` (commons/scenes/endless_museum.gd:11003, 11020, 11143-11146), so `study:neighbours` reaches the explorer.
2. **L9, "Find the board near the entrance side of the hall."**
   - After: "Find the board on your left as you come in, a few steps into the corridor on that side, set against its outer wall."
   - Why: the audit and the re-check agree it was false, and the layout has changed since. The explorer is at map (10,4), turned 270 (map_data.json:727). The visitor enters at row 0 facing +z, so +x (cols 8-11) is on their left. The corridor's outer wall is col 12. A BFS over the structure from the entrance cells (5-8, 0) reaches the explorer in 5 steps. "Far edge" still holds: the controls sit at local +z (neighbour_study.gd:34), the newest row and its markers at local -z (ca_rule_explorer.gd:385, neighbour_study.gd:64), and at rotation 270 the -z side faces the wall.
3. **L41, "part of its rule"**
   - After: "This installation builds that separation into its update step, the same under every rule number."
   - Why: the audit and the re-check agree it was overstated. The separate `new_row` belongs to `_advance` (:374-383), while `_apply_rule` (:368-370) knows nothing about order. I used the re-checker's wording.
4. **L49, "Now approach the rug."**
   - After: "Now return towards the entrance, go through the opening on the other side of the wall, and approach the rug."
   - Why: the audit and the re-check agree it was false under the old bench stamp (rug sealed off, under walls). The layout has changed. The rug is now map-placed at (4,4) (map_data.json:721), and the new two-cell opening at row 1, cols 5-6 lets the entrance reach its room (BFS: 4 steps). From the board, the rug's room can be reached only back through the entrance: a BFS from (4,4) with the entrance cells blocked reaches neither the explorer nor the exit. The rest of the sentence ("A detail in one quarter has partners across the cloth") is true in code (persian_rug.gd:88 default stencil `quadrant`, :348, :351-365, :483), so it stays.
5. **L65, the line network**
   - After: "Further along, down the passage beyond the rug's room, the line network gives the cell another body. Occupied positions are joined by thin coloured lines, and some of them run below the floor."
   - Why: the audit and the re-check agree it was overstated. With the new layout, "Further along" is true again on this side of the wall: col 6 runs south from the rug's room to (3,12) (map_data.json:840), 14 steps from the entrance against the rug's 4. I kept the re-checker's hedge, because the half-under-floor problem is not fixed:
     - the walk starts at the grid centre (LineNetworkCA.gd:47-51), which `_grid_to_world` maps to the node origin (:159-164), and each step moves y by -1, 0 or +1 (:56);
     - the map lane gives a plinth only for a `2` or `p` structure cell (endless_museum.gd:11122-11130), and (3,12) is `1`;
     - token y-offset 0 (:11152);
     - un-lifted bodies are not re-seated (:13378-13381);
     - the lines do not exist before the first `_process` in any case (base_ca.gd:81-85; LineNetworkCA.gd:92-104, 166-168).

     "Thin lines" rather than "segments": they are `PRIMITIVE_LINES` (:171), and `line_width` (:23) is never read.
6. **L75, the closing list**
   - Before: "The other works remain in the room: agents painting a shared surface, a Rule 110 display, the showcase and the orb."
   - After: "Other works remain in the hall. The orb stays by the rug, and the showcase stands further along past the network. On the board's side of the wall, the corridor continues past agents painting a shared surface to a Rule 110 display near its far end."
   - Why: the audit flagged it as false (under the stamp, none of them were placed or reachable), and the hall notes ask for the list to follow the new layout.
     - The dark sphere is at (5,3) (map_data.json:707), one cell from the rug.
     - ca_showcase is at (1,17) (:913), 21 BFS steps from the entrance, beyond the network.
     - langton_swarm is at (10,9) (:802), with 8-16 ants on one grid (langton_swarm.gd:85-92).
     - rule110_computer is at (10,16) (:907). The exit (row 18) is reachable only by that corridor.
   - "Display", not "computer", is kept on purpose. The brief says never to claim that an apparent circuit computes.

## Added
No new sentences outside the rewritten list. The positional clauses in changes 2, 4 and 5 and the two extra sentences in change 6 are the only new words. Every place and step count in them comes from map_data.json and a BFS over its structure layer. The BFS treats only `1` as walkable.

## Left alone, and why
- **"The drawing then chooses a recorded neighbour to connect to each newly encountered position."** The auditor called it overstated, and my own reading agrees: a line is drawn only `if candidates.size() > 0` (LineNetworkCA.gd:144), and walk cells scanned before any recorded neighbour get a birth time but no segment (:123-126). The re-check did not test this sentence, though, and its note on the network restated the chapter's version. The rule is audit and re-check together, so it stays. **Flag for the next pass:** "...to a newly encountered position whenever one of its neighbours has already been recorded."
- **grid_substrate_runner** (map (11,8)) is not named. It stands between the board and the swarm, and a wall label beside it says it edits the floor that is already there (hall_ci_eye.png). According to the audit, it looks for a `GridMultiMesh` that a museum-built hall does not have, and nobody has run it. I could not verify what it does here, so the chapter says nothing about it. The rewritten list no longer claims to be complete.
- **synthesis_stand** (2,3) now gets its full config (subject dark_sphere, mode hero). It is a DNA-measurement stand (synthesis_stand.gd:1-13), so it does no work for the CA inquiry, and the chapter leaves it out.
- The noise recap paragraph and the handover. Lab_Path closes on "That previous step has to be kept while the next one is written... Bring one of your unfinished questions with you". This chapter answers with "Bring an unfinished question with it" and, later, with "All the questions go to the old row". The handover is intact, so nothing was added.

## Limits
- *(Superseded; see "Encounter, part two" below.)* ~~I did not start Godot. The museum placement, full-size explorer and unsevered walk come from the task's museum-boot readback and the two images (hall_ci_plan.png, hall_ci_eye.png). I did not re-run them.~~
- "On your left" assumes the visitor arrives facing +z through row 0, as the hall notes state.
- *(Superseded; see "Encounter, part two" below.)* ~~The line network still sits with its origin at the deck. Roughly half the tangle is below the floor, and some of it runs through the narrow room's walls. The prose now says the first part. The work itself still needs a lift or a smaller step (audit, encounter fix item 4).~~
- The orb's centre falls inside the rug's 2.56 x 3.84 m footprint near its corner (persian_rug.tscn QuadMesh size, flat, 3.84 along z). It may hide a little of one quarter. Not tested.
- No headset walk.

| file | sha256 |
|---|---|
| before.md (= current final.md) | `6f1d7de34b510fa4f6071ed4ec96432632e8fc8750bcbbecd260ef2574516b82` |
| map_data.json (as read) | `4e869d45f889535842b1b383141a9d27db6ff0617a2a2650cf55cd4147bc6051` |

## Encounter, part two: the line network (added by the main agent after the text pass)

The editor's checker replayed the network over 300 seeds. At its old cell (3,12), on the deck in a corridor one cell deep, about 49% of the tangle lay below the floor, 22% inside walls, and only about 22% in open floor. The chapter gives it three paragraphs and asks the visitor to "move around it". Reading its script turned up a second fault: after its 20 growth steps it kept scanning 64³ cells and redrawing every frame, at 15-24 ms of script a frame on a desktop, for as long as the hall is loaded.

**What changed**

- `algorithms/cellularautomata/ca_showcase/LineNetworkCA.gd` (`LineNetworkCA.diff`; the shipped script is `LineNetworkCA.gd.before.txt`). Two changes:
  - It stops once its own growth is over. A flag is set only by its own `update_simulation`, so `dendrite_growth_ca`, which has its own unlimited growth rule, keeps running.
  - An additive key `#size:<m>` scales the drawn lines uniformly until the tangle's largest side equals it, centred over the node, with the lowest line 0.3 m above the origin. `size` is a listed grid config name, so the grid lane does not read the number as a rotation. With no `size` the drawing is exactly as before, and a live config without it puts the drawing back.
- The map token moved from (3,12) `line_network_ca` to (10,12) `line_network_ca:0:0#size:2.0` (`map.diff`).

**Where it went, and why**

- First try, (9,13) at 2.4 m. The space verifier found that the museum's dealt statue (`art:dream_bodies`, at (10,14)) stood inside the tangle's corner, with lines crossing the statue's box in 78% of replayed seeds. The tangle's west edge also came within 0.3 m of the dividing wall, across the lane every visitor walks down.
- Second try, (10,12) at 2.0 m. The worst-case box is x 9.5-11.5, z 11.5-13.5, which keeps:
  - the col-8 lane fully clear (1.5 m);
  - at least 0.5 m to the east wall;
  - about 0.6 m to the statue's plinth, which did not move;
  - at least 1 m to the swarm's easel.
- The visitor now meets it in the corridor after the board and the swarm, on the way to the Rule 110 display and the exit. The west passage now leads only to the showcase.

**Evidence**

- `probe_ca_stop_and_fit.out.txt`, all PASS, each against the shipped script from the same seed (L1-L5):
  - the default draws the same lines;
  - a network one generation short is detected;
  - it stops after growth: 20,886 µs a frame shipped against 3 µs;
  - `#size` puts every line end in the box when configured before `_ready` (museum lane) and after growth (grid lane);
  - the grid tokenizer reads `#size:2.4` as a value;
  - dendrite keeps growing (30 to 705 lines).
- `museum_network_readback.txt`, a museum boot:
  - node at (10.5, 0, 12.5), fit 2.0, stopped at iteration 21;
  - 672 line ends: 0 under the deck, 0 over a wall, void or outside the hall, 0 over the statue's cell;
  - 174 over open walk cells, 498 over the network's own one-cell footprint;
  - `9 verbatim + 0 slid of 9`, no `[em-walk]` line.
- `museum_seal_map.txt`: the full walk map. The network is `I`, the statue is `J`.
- `hall_ci_net_eye.png`, `hall_ci_net_plan.png`.

**What the walk map still says.** The rug and the synthesis stand log `[em-seal] … the route is severed`. They cut off two small pockets of their room, and the stand, which the chapter does not name, has no reachable walk cell beside it. Every work the chapter names has a reachable walk cell beside it: board 5 steps from the entrance, rug 2, orb 3, swarm 11, showcase 18, Rule 110 19 (the verifier's BFS over the seal map). The walk from entrance to exit is not severed.

**Text changed after the editor.** The editor's version is kept as `after.editor.md`. Three independent verifiers (text, code, space) checked the result; their fixes are applied:

- The network paragraph now takes the visitor back out through the opening, across the entrance and down the board's corridor past the painting agents. The lines are "drawn as a tangle in the air above the floor". This replaces the checker's "many of them run below the floor or into the walls", which is no longer true.
- The closing list: "The orb rests on the rug's edge" (its centre is 0.28 m inside the rug's edge). A showcase waits at the end of the passage beyond the rug's room. The Rule 110 display stands near the corridor's far end.
- "set against its outer wall" became "near its outer wall" (the desk's far edge is about 0.6 m short).
- "the wall" became "the dividing wall".
- "may already have finished" became "has already finished", since growth ends within 21 frames of the hall waking.
- The parent sentence the editor flagged is narrowed: a line is drawn only if a neighbour has already been recorded (`LineNetworkCA.gd`, `if candidates.size() > 0`).

`blurb.md` and `intent.md` were rewritten to match; the before-copies are in this folder.

## Installed

`after.md` was installed to `commons/maps/CA_Introduction/final.md` on 24 September 2026, with its line endings kept (LF). The baseline hash was checked first, and the anchors and code fences are unchanged. The hashes are in `HASHES.txt` and the diff is in `text.diff`. The current `map_data.json` is `map.diff` applied to `map_data.before.json`; the "as read" map hash in the table above predates the network move and the removal of two stray `" "` cells left by earlier placement attempts. No headset walk.
