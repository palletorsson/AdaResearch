# Catalyst counterpart trial

## Acquiring the opening abilities

For the connected progression from the first point, open `res://commons/testing/catalyst_opening_progression.tscn` and press F6. Place the point in the hollow field, join empty hands, charge the rod, keep a drawing, simplify the same point and send its form to a quiet target. Then meet the same head through translation, rotation and scale; three successive interrupted rounds open the passage. This is a compressed four-room rehearsal, with local unlocks and reset. See `commons/maps/Catalyst_Opening_Progression/README.md`.

Test with `python -X utf8 tools/test_catalyst_first_abilities.py --progression --render`. The supplied-power route and direct-entry arena below remain separately runnable.

## Direct-entry arena

Choose **Head Arena** from the game's main menu. It opens `biome_arena.tscn`: the encounter inside one complete `biome_object.tscn`, among its plants and terrain. The original biome collider is the floor. There is no separate stage, clearing slab or large backdrop. The shared base scene supplies the XR rig. The small console on the bank has the **MAIN MENU** control, returning to the same menu session. Existing installed Quest builds need a new export to include these changes. The earlier museum court remains available as `head_arena.tscn`.

The landscape uses the last kept RSI iteration, **generation 17**, with the reviewed seed-7 DNA, full stage and catalogue residents enabled. Original moisture, relief, wildness and community seed are retained. The menu probe compares actual runtime ecology counts and resident identities/positions against `ada_run/biome_rsi/gen_17/state_s7_m50_r50_w60.json`. `terrain_arena.gd` inherits the existing round logic and samples the original ground triangles for placement. The head's home and flight bounds fit this terrain. Only state-file recording is disabled in this practice scene. Review: `doc/book/iterations/2026-10-12-biome-is-the-arena/index.html`.

For immediate combat trials, open `res://commons/testing/catalyst_test_arena.tscn` and press F6. Take the point; choose MOVE / TURN / SCALE; press START. Three projectile interruptions complete a round. REST and RESET are separate reachable controls. No drawing prerequisite. This is a dedicated museum court, separate from the connected route below. See `commons/maps/Catalyst_Test_Arena/README.md`.

Menu integration check: `python -X utf8 tools/test_catalyst_first_abilities.py --menu --render`. The biome route is tested through actual pointer dwell and staging, with ground colliders, pickup providers, three real projectile interruptions and return. Godot currently crashes during final process cleanup; a menu-only control run reproduces it without entering the arena. This is not a clean process-exit result. Headset testing and Android deployment were not performed.

## Dedicated test route

The connected first-abilities prototype is now `res://commons/testing/catalyst_first_abilities.tscn` (F6). It creates the real museum from an isolated 13 × 36 m test map: charge a wall rod in the sphere's field, draw and release, see the recorded line as a sculpture beside the waiting head, then carry the existing catalyst into a short passage encounter. BEGIN moves that same head into the arena; a projectile interruption opens the exit. RESET is available at the entrance and arena.

`proving_ground.gd` owns local progression and the gate. `charged_rod.gd` extends the existing pen. `trial_trace.gd` preserves DrawDot sampling but keeps this experiment out of TraceData and TagSystem. No teaching map, textbook text or curriculum order was changed. The original trials below remain available.

Run `python -X utf8 tools/test_catalyst_first_abilities.py --render` for the dedicated route's assertions and native screenshots. Rebuild its plan from its map with `python -X utf8 tools/build_catalyst_test_plan.py`. Headset testing remains necessary.

First playable experiment, 2026-10-12. An original procedural burning skull in the real Endless Museum. Following the user's revised placement: it waits in Melencolia, then moves in Transformation. These are optional test scenes; no enemy has been added to the main spine.

First sighting: open `res://commons/testing/melencolia_counterpart_preview.tscn` and press F6. In this preview the burning skull replaces the seated figure in the Dürer tableau. Its body stays still and has no active collision; only the pale fire moves. This is Ada's proposed substitution, not a claim about the engraving. The original map and tableau source are preserved.

Open `res://commons/testing/catalyst_counterpart_trial.tscn` in Godot and run the current scene (F6). The scene uses the museum generator and existing XR rig. In VR, take the black point and use its trigger. Choose MOVE, TURN or SCALE, then START / REST. The point is the existing Ignorance resolution catalyst: holding reduces its rings/segments and its trigger sends a copy of the form. This is a supplied ability in this trial, not a new unlock in Coordinates.

The counterpart waits on arrival. When started, it shows a line for 1.2 seconds, then follows that locked line. Sidestep or interrupt it with the point's projectile. A contact counts one training tag; there is no damage, forced locomotion, death or relationship conversion. The counterpart is bounded to the test area. REST cancels its attack immediately. TURN adds an orbit during recovery; SCALE changes both its visual body and collision radius. MOVE returns to the simplest behaviour. Abilities are selected explicitly, not learned autonomously.

## Implementation boundaries

- `flying_skull.gd`: bounded flying CharacterBody3D, visual construction and state machine; implements the existing catalyst receiver methods.
- `counterpart_trial.gd`: museum placement, four existing CubeButtons and the existing `resolution_catalyst.gd` PointBody.
- `commons/testing/catalyst_counterpart_trial.gd`: prepares a private museum snapshot under `user://catalyst-counterpart-trial/`; starts Trans_Pre and mounts the trial. Resume and museum evidence files are redirected. The main map and progression save are not edited by the trial's code.
- Trace charging is implemented in the dedicated test route above; permanent spine placement remains a proposal. Existing draw_dot sampling, trace persistence, Grid and the opening two-hand ability are unchanged by this experiment.

## Verification

Run from the repository:

```powershell
python -X utf8 tools/run_encounter_probe.py Trans_Pre --sequence transformation --no-bridges --render --probe tools/probes/catalyst_counterpart.gd --output-tag counterpart
```

The probe mounts in the real hall and tests an XRTools pickup, the actual trigger signal, a flying projectile collision, interruption, locked aim, movement, orbit, scaling, bounds, rest and contact cooldown. Inputs are supplied; this is not a headset playtest. `tools/probes/catalyst_trial_boot.gd` separately smoke-tests the F6 entry point.

Headset checks still needed: reaching the controls, seeing the warning line, aiming the inherited sphere, avoiding the dash, and whether repeated encounters remain enjoyable. The trial shares space with the existing examples; a permanent encounter should get a clear optional bay after the three operations have been encountered.

## Proposed lineage

Coordinates: acquire → Lines: relate → Trace: leave a mark → Grid: retrieve your mark → Triangle/Polyhedra: build a boundary/body → Ignorance: emit a form → Melencolia: meet the burning counterpart at rest → Transformation: it moves; read and interrupt motion → Arrays: distribute effects → Colour: change a receiver → Forces: redirect a motion.

The ability belongs to the visitor; the sphere is its first available form. The counterpart gains operations from the same curriculum. Its behaviour determines whether an encounter is threatening. A skull appearance alone does not settle whether it is an enemy, companion or instrument.
