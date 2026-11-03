# The pit, the annex, floors that bounce, and a comfort vignette — report for Astra

2 November 2026, from the playground session (on the forum as `claude-pit` in the morning, `playground-session`
after), for the Codex / Astra session that built the receiving places. Previous:
[slots, rims and the pocket test](../2026-10-31-slots-and-pocket-test/README.md). The evening of 31 October (the
board, the display plate) is on the blog as `/blog/2026-10-31-a-structure-of-displays`. Blog with pictures for
today: `/blog/2026-11-02-floors-that-throw-you-back` on the encyclopedia.

**None of your untracked place files was edited today.** Your untracked `place_spec.gd`, `place_builder.gd`, `principal_builder.gd`,
`parameterized_place.gd`, `principal_places/places.gd` and the approved `principal_places/recipe.json` were last
written on 30 and 31 October. Check C of `probe_board_vocabulary` still finds no `activities` or `boards` in `recipe.json`.
New halls reach your builder by **extending** `places.gd` (`spec_hall.gd`), not by editing it. In the dirty `playable.json`
I added four entries and committed only those (below). Forum threads as it
happened: 261102-mjk7e (the pit, then the annex), 261102-il49m (the Patterns pool), 261102-s4vjx (the shared rig).

## What Palle asked, in order

1. A good next step: the ball pit. *"100 might be a bit too much for the VR set, or?"*
2. *"Are they physical? Can we ensure they do not have so much bounciness and that they do not repel too much."*
   Then: test it on the desktop.
3. *"A new map with the artifacts that do not fit on the floor. I cannot walk to these and inspect them."*
4. The facade mini town, held *"one metre up in the air"* by the playground structure, and mosaics inside the
   scaffolding. Test each in its own non-spine map first, then later move it into the skyscraper.
5. *"Can I walk all floors"*, then *"I mean the mosaic floors"*: all 46, not the five Pompeii decks.
6. *"These should be added to the pattern sequence, but we can also use the vertical plane when we curate the space."*
7. A 4 m super jump on those surfaces, corrected to *"the material should be bouncy"*, then *"do the bouncy version
   with the 4 m ceiling"*.
8. A VR comfort vignette, instant on a jump, possibly general: *"after moving more than 2 sec ... What is a good call
   here?"*

## The sidecar on floor 210

`commons/void/trials/principal_places/activities.json` is tracked and mine, beside your recipe.

- **Morning (8c44e4761).** `board_builder.merge_sidecar()` now reads a `places` array, validates the whole array as one
  place spec (one refusal refuses all), and builds each entry with your `place_builder.build_place`. The pit went in as a place.
- **An hour later (56696e96d).** `tools/playground_trial.py check` measured the sidecar against the tower's
  42 × 18 m slab, room at (0, -1). Seven of eight pieces stood off it, so every board and the pit moved to the
  annex, and the sidecar kept the samples and ball tests.
- **Since then.** The court session (`claude-museum-returns`, forum 261102-mjk7e) replaced the court's gaussian
  sample and ball test with a flight bay, the biome ladder stratum and six workers. That work is committed (2ec904893,
  its report amended in 0170c24f1); see `../2026-11-02-court-flight-bay-and-ladder/README.md`.
- **Probes that remembered the room.** `probe_board_vocabulary` B hard-coded four samples and three ball tests, and
  went red when the court changed. It now reads the expected kinds from the sidecar itself (3/3 again,
  99658ea67). The court session also took the court entry out of
  `probe_hall_activities`'s want list (3/3).

## Shared tracked files (my hunks only, via HEAD-blob staging where the file was dirty)

| file | change |
|---|---|
| `commons/void/trials/playable.json` | four trial entries: `playground_annex`, `facade_town`, `mosaic_decks`, `playground_floors`. Your uncommitted trials untouched. |
| `commons/void/walker.gd` | `_support_jump()`: a floor's `GroundPhysics` jump velocity (flag 16) replaces the jump. `_bounce(pre_slide)`: XR Tools' rule `v + 2 n m b` from the floor's bounciness and threshold (flags 32/64), capped by the floor's `bounce_ceiling` meta, carried by `bounce_pending` past the line that zeroes `velocity.y` on the floor. |
| `commons/artifacts/facade_builder/facade_builder.gd` | `explicit_config`: a config with `preset` or `plan_path` skips the `user://facade_plan.json` sync file. It only matters for a builder whose `plan_path` is empty: `build_facade` reads `plan_path` first, and `facade_builder.tscn` sets it to the Galleria. The town works because each board names its own `plan_path`; a `preset` alone still loses to the scene's Galleria. |
| `commons/maps/sequences/tiling.json` | the Patterns sequence (id `tiling`) gains one artifact group, `Pattern_Mosaic_Floors` (`position: exploration`, status *proposed - a pool for curation*, 46 tokens). Not in `maps`; `verify_sequence tiling` prints the same before and after. |
| `commons/player/museum_rig.tscn` | one node, `XRCamera3D/ComfortVignette`. The museum and the Void both carry it; on the desktop this XR rig is disabled, so the desktop view is unchanged. |

## New, tracked, mine

| file | what |
|---|---|
| `commons/artifacts/pocket_test/ball_pit.{gd,tscn}` | `pocket_test` in pit mode: 320 balls of 0.4 m rained in 40 per tick, density 25, bounce .15, damping 2, 2 m/s cap, layer 20 masked so the player's body wades. Registry `walkable_surfaces.json`; parameters `artifact-parameters/ball_pit.json` (presets `pit`, `quest_light`, `lively`). |
| `commons/modular/places/board_builder.gd`, `place_activity.gd` (mine since 31 October; today's additions) | board words `artifact` per content, `artifact_turn`, `artifact_tilt` (-90 stands a floor artifact on the wall), `fit` (uniform scale into the board, measured in the board frame, skipping nodes queued for deletion; `draws_nothing` when there is no mesh), `walk` (a thin body at the surface), `label`, `jump`, `bounce {bounciness, threshold, ceiling}`. Ground-level walk surfaces and display plates get a 50 cm skirt. |
| `commons/modular/places/bounce_ceiling.gd` | one per hall with bouncy floors. It caps the XR body's rise at the floor's ceiling on `player_bounced`. It also **completes the XR bounce**: the XR Tools body lands without bouncing when the stick is idle (below). |
| `commons/void/trials/playground_recipes/spec_hall.{gd,tscn}` | extends your `places.gd`: compiles the place spec named by meta `config_spec` and builds it; refuses with a label on errors. Token `playground_spec_hall` in `registry/display_plates.json` (map_ready false). |
| `tools/playground_trial.py` | `make` writes a trial for one spec; `stack` writes one trial with a spec per floor, 12 m storeys, 6 m shafts A and B centred at x = ±(reach + 6) m, where reach is the furthest \|x\| any piece extends, and a soft corner pad in shaft B on each floor below; `check` exits with the count of pieces off a slab. |
| `commons/data/playgrounds/halls/playground_annex.json` | the annex: pit and screen wall, Shader_05 path, posters, tiling corridor, pattern rack. 58 plates. |
| `commons/data/playgrounds/maps/Facade_Assembly_Principle.json`, `Mosaic_Pompeii_Floors.json` | the town (11 boards, `facade_builder`, `artifact_turn` 180, `fit`, a preset plan each, 1 m up on posts) and the decks plus the field (46 boards, 4 × 4 m, `fit`, `walk`, `label`, `bounce {1.2, 2.0, 4}`). |
| `commons/data/playgrounds/examples/{pit,mosaic_wall}.json` | example structures 8 and 9. |
| `commons/void/trials/{playground_annex,facade_town,mosaic_decks,playground_floors}/` | the trials: `trial.tscn`, `rooms.json`, `layout.json`. |
| `commons/player/comfort_vignette.gd` | the vignette (below). |

## The two findings worth your attention

**XR Tools' player body does not bounce with the stick idle.** It tests its bounce after the move, against a
`local_velocity` that its ground-drag step has just rebuilt from the post-slide velocity, whose vertical part is
zero. On a bounciness-1.2 floor the body jumped once to 1.04 m and stayed down. `BounceCeiling.complete()`
(physics process priority 100; the body runs at -100) reads the velocity the body carried into the step. When an XR body lands on
a floor with bounciness and XR Tools did not throw it back, it sets the normal part of the body's
velocity to what XR Tools' own rule, `v + 2 n m b`, gives for the velocity it carried in: `m (2b - 1)`, 1.4 × `m` for
b = 1.2. The tangential part stays as the body's own step left it, and the rise is then capped at the floor's ceiling. Only halls with bouncy floors carry the node, and the addon is untouched. If your
places ever use XR Tools bounciness, this is why it seems not to work.

**The comfort vignette reads the body, never the head.** A clip-space ring drawn with XR Tools' vignette shader on
layer 2 has three channels:
- **Air** closes within two or three frames once airborne past 1.5 m/s (2 on the plain-ground jump, 3 on the
  mosaic floor; it updates in `_process`), stays closed to the landing, holds 0.2 s, then opens at a rate of full
  closure per 0.5 s, about 0.3 s from a jump's closure (0.53 s from landing to open, measured).
- **Walk** eases in with a 0.4 s time constant, to closure 0.3 at 3 m/s.
- **Turn** closes to 0.7 at 2 rad/s.

Snap turns, teleports and head motion do nothing. `walk_delay` (default 0) is the setting for Palle's two-second
delay, and `strength` 0 turns the vignette off.

## Evidence

| probe | result |
|---|---|
| `probe_ball_pit` | 6/6. 320 balls in the pool after 14 s; wading displaces them, a body off their layer does not; after the stop no ball coasts a metre or passes 2.0 m/s (coasting peak 1.53); 58 annex plates |
| `probe_example_structures` | 15/15. Nine examples and five map recipes compile; the annex stands 58 plates |
| `probe_board_vocabulary` | 3/3. The sidecar expectation is read from the file (rerun this evening) |
| `probe_display_path` | 5/5. The walker walks onto the first screen; mid-screen it stands on the glass at 0.121 m |
| `probe_hall_activities` | 3/3 since the court change (4/4 before) |
| `probe_playground_maps` | 5/5. 11 fronts at 1.00 m, fitted and turned; 5 decks walkable; 46 different floors fitted or labelled, each met by a downward ray at 8.5 cm (the walk across the edge is `probe_bouncy_floors` E); 8 stand on the wall, and the same 8 lie flat without `artifact_tilt` |
| `tools/probes/probe_void_stack.gd` | 4/4. Three drops through shaft B land at -24, -36 and -48 m: the facade town (11 activities) and the mosaic floors (51) are built, and the last drop lands on the empty catch floor |
| `probe_bouncy_floors` | 5/5. 46/46 bouncy; the XR cap at 8.85 m/s, the launch speed for a 4 m rise; desktop climb 1.04, 2.01, 3.79, 3.93; no bounce on plain ground, and none when walking across the field's edge onto a floor |
| `probe_comfort_vignette` | 8/8 on the real `museum_rig.tscn` body. Jump closes in 2 frames; the XR body bounces 1.04, 2.02, 3.79, 3.93 standing still; walk 0.07 at 0.1 s, 0.29 at 1.5 s; snap, teleport, head 0.000; strength 0 off |
| `museum_rig_contract_probe` / `probe_inventory_prism` | 105 nodes, no failures / 26/26 |

Run with `godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_<name>.tscn` under
`tools/godot_watchdog.py --expect=ada_run/workstation/<name>.json`; the vignette probe wants `--grace=60
--stall=30`. The stack probe is a `--script` run with `-- --void-trial=playground_floors`. On the desktop:
`python tools/launch_void_desktop.py --trial mosaic_decks` (or `playground_annex`, `facade_town`,
`playground_floors`). Two rows differ: the rig contract probe is `--script res://tools/probes/museum_rig_contract_probe.gd
-- --out=<dir>` (writes `base-contract.json`; this run went to a scratch folder, so only its printed line records the
105), and `probe_inventory_prism` writes `ada_run/inventory/prism.json`.

## Lessons that cost a pass

- **A ray is not a walk.** All 46 floors passed a downward ray at 8.5 cm, but the desktop walker stopped dead at
  the field's 7.5 cm bar. A capsule with a 45° floor angle meets it as a wall. The fix is the skirt, and the test
  drives the walker across the edge.
- **A rebuild leaves the first build in the tree this frame.** `queue_free` is deferred, so `fit` measured the old
  facade. It now skips any node that is queued for deletion or sits under one that is.
- **The scene's own plan sat above the config.** `facade_builder.tscn` ships `plan_path` = the Galleria (12 × 14 m),
  which `build_facade` reads before any `preset`, so the first preset boards all built the Galleria. Naming a
  `plan_path` per board fixed that; then `fit` still measured the queued-for-deletion Galleria (next lesson). The
  editor's sync file is read only when `plan_path` is empty, so it never touched these boards.
- **Testing a function is not testing the motion.** I reported that the headset body bounced after testing
  `BounceCeiling.cap()` on a stand-in body. Driving the real rig body showed it did not.
- **A probe that remembers someone else's room goes red when they change it** (`probe_board_vocabulary` B, above).
- **Physics.** Spawning 250 balls in one tick peaked at a 117 ms physics tick. Raining 320 in at 40 per tick halves
  that, but the latest run still peaks at 58 ms while they fall; the headset question is open.
- **Spec rules.** Board positions must be whole metres, and place ids use underscores.

## Open

- **Floor 210 on the headset (found by the court session, both mine to fix).**
  - The Quest export drops `activities.json`: it is not in `addons/quest_game_export/runtime-trial-files.json`, so
    none of the sidecar has reached the headset since 31 October.
  - The synthetic XR body spawns 0.30 m under the disco plate's noise surface and is held there.
- **The playground maps are trials, and trials do not ship to the Quest.** Moving the annex, the town and the mosaics
  into the skyscraper as tower floors is the step that puts them on the headset. It touches the tower's own files, so
  it waits for Palle and the tower's session.
- **Curation.** Where the `Pattern_Mosaic_Floors` pool goes, on the floor or on the wall.
- **`pompeii_meander_floor` draws nothing.** Its script builds nothing; the field labels it.
- **The vignette** has not been worn and has no in-headset strength control.
- **Found in passing, not mine.** `tools/test_void_game.py --stage-only` dies with `shutil.SameFileError` on
  `D:/AdaGenerated/AdaResearch_46/state/chains-futures.json`. The half-staged copy cannot compile `game.gd`, so
  `test_void_museum_rig.py` cannot run (forum 261102-s4vjx).
