# Random Game — Astra review, 12–13 September 2026

Palle's latest principle is persistent: **one primary is a starting point, not a maximum**. Include other convincing encounters during the first pass when each makes a distinct contribution. Keep book anchors, roles, order and actual placement aligned.

Delivered: [Random Game review](http://localhost:3003/research/possible-bodies/random-game.html) and [two primary book cards](http://localhost:3003/necklace/thread?map=Random_Game&role=primary). Next: **Random_Noise_Types**, first on the active noise route. Headset checks remain deferred while Palle is remote.

## The argument and changes

Two primaries, in order: `r_c` (a fixed state order with drawn waits) and `cube_projectile_spawner` (a regular attempt clock with drawn initial positions/velocities and separate later jitter). One hero remains r_c. The final has 967 whitespace words; primary passages show 610 and 263 words. Eleven GDScript excerpts across the book/tutorial/technical match actual production source. Critical/technical/intent previously described unsupported distribution switches, 64 sinking tiles, scores and creature/player capabilities; those claims are replaced with the implemented encounters and explicit limits. The field's contribution is STOP versus CLEAR: pausing a source does not recall earlier emissions.

Production files:

- `commons/primitives/cubes/random_cycle_cube.gd`: cancel prior tween and invalidate old timers when restarting, restore standing position and collider, retain beacons on all stones, add actual state to the readout, extinguish crowns synchronously on state change, exclude the current number from NEW SEED, extend lip ramps and add short landings before the capsule reaches a stone's vertical face. The landing visual is 4 mm below its collider to avoid coplanar overlap with a standing stone; the collision surface stays level.
- `commons/primitives/cubes/CubeSpawner.gd`: optional `stand:field` marks the initial spawn region and builds an east-edge plinth/panel for RUN / STOP and CLEAR. Guard interval configuration before the Timer is bound. Cancel preceding pulse tweens when toggling. Ignore empty base AudioStream placeholders. Correct documentation: field_seed repeats initial conditions, not full projectile trajectories.
- `commons/primitives/cubes/ProjectileCube.gd`: replace obsolete material.emission_energy with emission_enabled / emission_energy_multiplier; omit the empty sound placeholder.
- Eight room texts, field notes, registry descriptions, book hero/lines, roles/order, WCN research card, and both museum plan rows. Source map change adds only #stand:field to the existing field token plus descriptive metadata/formatting. Structure, utilities, dimensions, museum settings and all nine requested positions remain.

The optional field stand uses world axes because the actual field does. Its lines show where centres start; they do not contain drift or guarantee a safe observation zone. Control tests use the project desktop rig placed inside the actual museum; that rig is distinct from the museum's default walker, which has no such pointer. No tracked-hand test is claimed.

## Evidence

Final run: **PID 38856, 2026-09-13 00:13:45–00:15:18 +02:00, 88 checks, zero failures, exit 0**. Full process inventories preceded each run; no other Godot process was present or terminated. Hidden/offscreen owned runs used isolated copies of the saved hand. Sources were stable and the original hand unchanged. Runtime files are `ada_run/game-review-2026-09-12/Random_Game/`; receipt is `ada_run/game-review-2026-09-12/run.json`.

The inherited live test checks the actual hall, all three crossing controls through the pointer, bed/floor rays, gap cells, east bypass, traversal and a deliberate fall with recovery up the west ramp. Independent additions reset during a live sink, compare first waits for all stones, assert unchanged RNG states/deadlines under CUE, record frame-level state transitions and verify beacons/crowns. The final captured event record contains 23 transitions over 11.5 seconds. The field test calls its actual spawn path 24 times twice at seed 31415, verifies the cap, STOP/CLEAR and exact initial records, then separately operates real timer emission through local buttons. Projectile jitter RNG state differs between the two sets; it is not claimed replayed.

The first run (PID 14816, 00:03:23–00:04:55) had 88 checks/four failures: threshold walk, one-frame crown light, RUN pointer miss and the resulting no-emission failure; also an early Timer configuration script error. Preserved under `first-run-failures/`. The second run (PID 36684, 00:09:13–00:10:44) passed 88/0 but visual inspection found the landing overlap seam; preserved under `passed-before-landing-visual/`. The last run verifies the final visual correction. A research-page builder assertion about card lengths was corrected before publication; no runtime failure was hidden.

Final log: no GDScript or shader error. Existing missing-audio UID, root certificate, DebugLogger, empty registry and GL compatibility warnings remain; ObjectDB shutdown leaks remain and were not diagnosed as fixed. These are listed verbatim in verification.json. The actual motion/collision/pointer checks passed despite those diagnostics.

## Publication and open work

Builder `tools/build_game_review.py` writes the illustrated page and inspectors from captured engine records. Event selection presents recorded states; launch selection presents initial centres/velocities, not simulated trajectories. The initial-velocity lines are magnified fourfold and that scale is stated. Four displayed images and eight other captures are included. Book disclosure and both primary cards are verified in the local browser. Publication manifest has 63 files including the previous Mushrooms link, WCN index/cards and new final. HTTP hashes and browser observations are saved beside this handover.

Nine map requests, nine matched ledger cells, **eight placed / one refused / zero extra**. The refused body is `monte_carlo`: the live loader reports no living scene in this lane. Its source also has unfinished extra modes and an unsuitable independent camera/input arrangement. It stays a secondary candidate; no artifact was deleted to make the accounting look complete. The six folding creatures can interfere with the experiments. Controlled activation/separation and combat balance are still open; the text does not promise safety or absence of pursuit. The unrelated Noise_Voxel primary/book mismatch remains for its own pass.

Helpers: `prepare_game_review.py` (before snapshots and runner setup), `stage_game_review.py`, `write_game_text.py`, `finish_game_text.py`, `document_game_review.py` are one-off preparation scripts; do not rerun casually. `review_game.py` + `game_review_extra.gd` own runtime checks. `align_game_review.py`, `verify_game_review.py` and the page builders derive indexes/publication. No commit or goal was created.
