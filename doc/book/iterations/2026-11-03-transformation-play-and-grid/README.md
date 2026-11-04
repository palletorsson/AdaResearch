# 3 November 2026: Transformation floors, physics play, associations and the grid audit

Task: Palle's requests through the day on the Transformation floors of the Void (13–21), the
inventory and the editor. Status: technically verified in the actual tower on desktop. Nothing has
been walked in the headset or committed.

Previous report: [the court's flight bay and ladder](../2026-11-02-court-flight-bay-and-ladder/).
Blog: `/blog/2026-11-03-what-survives-the-move`, with nine pictures in the encyclopedia's
`public/what-survives/`. Source revision: HEAD `30f48b283` with these files (`git hash-object`):

| File | Hash | State |
|---|---|---|
| `commons/void/rooms.json` | `2e620ebd9c` | tracked, dirty (shared) |
| `commons/void/floor_content.gd` | `acd9f5930e` | tracked, dirty (shared) |
| `commons/void/step_box.gd` | `d8b47da5f7` | tracked, dirty |
| `commons/modular/terms.json` | `e843246a34` | tracked, dirty (shared) |
| `commons/data/inventory/items.json` | `f1594df091` | tracked, dirty (shared) |
| `commons/void/primitive-prefabs.json` | `dd8116f6b1` | tracked, dirty (shared) |
| `commons/artifacts/physics_play/physics_play.gd` | `ac2d189e7a` | untracked |
| `commons/artifacts/invariant_tape/invariant_tape.gd` | `3beb6e39fc` | untracked |
| `commons/artifacts/association_tape/association_tape.gd` | `0e47f4999a` | untracked |
| `commons/artifacts/parallel_beams/parallel_beams.gd` | `5e3d95e2a2` | untracked |
| `tools/probes/void_candidates.gd` | `aad0c36fbd` | untracked |
| `tools/probes/physics_play_floor.gd` | `ffc9bf5620` | untracked |

The forum threads are 261103-1xab1 (beams and candidates), 261103-fgj5x (floor 13) and 261103-sbcaf
(floor 14, physics play, associations, the move to floor 21, the grid candidates).

## What changed

1. **Spine placement worklist.** `doc/plans/spine-placement/README.md` and `worklist.json` list
   210 items by sequence and hall: ideas, and recent artifacts that stand nowhere.
2. **Parallel beams on Point Lines (floor 3).**
   - `parallel_beams` is three black beams, parallel, leaning 15°, colliding.
   - Worklist candidates stand on floors 3–12 and 15–17 as `candidate-<token>` for Palle's keep/remove.
   - `tools/place_void_candidates.py` and `tools/probes/void_candidates.gd` find off-route clear spots.
3. **Trans_Pre (floor 13).**
   - Single-cell islands with two wedges for still, translate, rotate and scale.
   - Then configurations of 2, 3 and 2×4 cubes; `tools/trans_pre_layout.py`.
   - Step boxes: `step_box.gd` gains `drop_m` (a falling familiar solid).
   - `floor_content.gd` gains `config.support: false`, an additive opt-out from the steel support of a raised work.
4. **Levels brush (encyclopedia).**
   - Files: `src/components/voxel-editor/void-levels.ts`, with 11 tests in `void-levels.test.ts`.
   - What it does: per-cell levels 0–5, automatic wedges, stamps, and route-blocking refusal.
   - The cell grid is centred on n + 0.5, and floor 13 was re-laid on it.
5. **Physics play.**
   - `commons/artifacts/physics_play/` holds twelve Jolt set-ups, built from inventory prefabs.
   - No buttons: gates (a plank in forks, a door stop in the chute) and a floor reset plate.
   - Registry: `physics_play.json`.
6. **Associations.**
   - `fire_extinguisher = association(config(cylinder))` was the pilot. `tools/associations_rollout.py` writes the terms, registry `associations.json`, inventory items, the prefab timeline and floor entries.
   - `association_tape` writes the expression on the floor or a wall.
   - Classics added: cinder block, wooden board (quad), oil drum, tin can, bowling pin, marble and chute, domino tile, hinge.
7. **The move (Palle's choice).**
   - The 12 plays and the thresholds again/almost/just/barely/still went from floor 14 to floor 21 Logic_Event, with an 8-leg route.
   - `threshold_descent` went to floor 62 FormFinding_Annealing.
   - Floor 14 is the Introduction again; its threshold loop is cut from its route.
   - Floor 20 could not take them: the two scaffold circuits fill it over electrified ground.
8. **Invariant tapes on floor 13.**
   - `invariant_tape` pins a strip across each demo cube in the cube's own frame.
   - It reads ×1.00 under the bob and the spin, and changes under the pulse.
9. **Grid audit and candidates.**
   - Every Transformation grid map was diffed against floors 13–21.
   - 14 grid-only works stand as candidates labelled `candidate / grid <Map>`:
     - floor 14: the Composition hall and the numbers cluster;
     - floor 15: `pickup_gate`;
     - floor 16: `spin`;
     - floor 19: `sweeper_block`.
   - Held back: `boolean_tunnel` (10 × 10.8 × 43 m), `rotatescalecubes` (about 20 m) and `rotate_grid_cubes`.
   - `void_candidates.gd` now accepts a measured `size` per row; measure with `tools/probes/measure_true_aabb.gd`.

## Verification

| Check | Command | Result |
|---|---|---|
| Physics play bench | `python tools/test_physics_play.py` | 17/17 |
| Floor 21 in the tower | `python tools/test_physics_play_floor.py` | 13/13 |
| Associations in the tower | `python tools/test_associations_tower.py` | 20/20 |
| The first association | `python tools/test_association_floor.py` | 5/5 |
| Invariant tapes, floor 13 | `python tools/test_invariant_tape.py` | 8/8 |
| Levels brush | `npx tsx src/components/voxel-editor/void-levels.test.ts` (encyclopedia) | 11/11 |

The floor 21 check covers the following:
- all 12 plays and the 5 thresholds are built;
- nothing moves before release, and everything moves after it;
- nothing is lost off the floor or into a shaft;
- the reset plate works under the player's body, and every body goes home on reset;
- every route leg passes a capsule sweep plus floor rays every 0.5 m.

The negative test for the rays is the centre of shaft A, which must read as no floor. It does.

The invariant tape check's negative test is the scaled cube: its tape must not hold its length. It
spreads 59%.

Earlier today, Trans_Pre passed 9/9. Palle has since painted further cubes on floor 13 (bars joining
the islands, cubes at x 18.5 and 19.5), so `tools/test_trans_pre.py`'s island checks now fail by
design until the probe learns the new layout.

## Traps met

- **A shaft is a hole.** A capsule sweep cannot see it, so a route label had stood inside shaft A. The fix is floor rays.
- **The candidate probe reads CSG, Label3D and slow builds as a 1 m box.** Measure the true bounds first.
- **The printed strip winds face-down**, so it is invisible from above with back-face culling.
- **The SubViewport print photographed as nothing on a black cube.** The reading is now a Label3D.
- **A raised entry without `support: false` grows a steel rod.**
- **A sleeping, frozen body ignores a new transform.** Wake it, place it, then freeze it.
- **A lifted gate held frozen in mid-air was put back home** by something else, so it is now set down free.
- **The Void body's collision layer is the grid's player layer (20).**
- **`export_void_floors.py` takes the floors as one comma list**; a second argument is its output folder.

## Open

- **Floor 20.** The museum's embedded `GridSystem` could stand the AxisDecomposition grid where the motion scaffold circuit is. That needs Palle's decision and Codex's agreement.
- **Floors 13 to 21 are unwalked in XR.**
- **The Quest export** still omits sidecar files. That is from the 2 Nov report and not touched here.
- **An inventory carrier fits a BOX collider**, so a round item placed by hand will not roll.
- **The tin can's tape** lands 3.5 m from the can.
- **The candidates** wait for Palle's keep/remove in the editor.
- **Trans_Playground has no `final.md`**, and the book's Transformation chapter has no text.
