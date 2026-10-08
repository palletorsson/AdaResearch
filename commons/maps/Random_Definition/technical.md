# Random Definition — the instrument beside the lesson

The current 13 × 20 source grid places `seed_replay_demo:180#display:wall#comparison:replicas#stand:table#controls:compact#control_front:1.0` at column 6, row 6 (zero-based). Its controls face −Z. Seven placed artifacts remain: the replay instrument, textile comparison, crank, slot machine, TRNG/PRNG comparison, changing number page and catalyst. Map layers and the scene implementation are unchanged by this writing pass.

## Generator and assignment

Source: `algorithms/randomness/seed_replay/seed_replay_demo.gd`. `_regenerate()` resets the local `_rng.seed` before colouring each grid. Each cube takes three successive `randf()` results as RGB. The two 8 × 8 grids therefore assign 192 values each. With `_extra_on`, only the last grid discards `extra_draws` values after seeding and before colour assignment. This placement uses one: 193 requests, 192 assigned values. REPLAY keeps the selected procedure; +1 DRAW toggles it instead of accumulating offsets.

`raw_prefix()` uses a separate generator to inspect the first twenty-four draws without advancing the colour stream. These bars expose the offset, not a measured period. `_pick`, randomized on arrival, is separate again: RANDOM chooses `_pick.randi() % 1000`, so it may choose the current seed. Waiting alone never advances `_rng`.

The handle chooses `roundi(clampf(norm, 0, 1) * 999)`. Its continuous travel selects integers 0–999; adjacent seeds need not produce adjacent-looking palettes. This is a menu of seeds, not a guarantee of one thousand distinct images. `Panel/Param_0` is the current slider path. `_syncing_seed_slider` guards programmatic updates. The previous wrong path and compact-control repair are documented in the archived tutorial, preserved in this review's `before/tutorial.md`.

## A fresh instance and a restored visit

`_ready()` starts a fresh instance at configured `seed_value` (42 here) and its comparison mode. `capture_museum_state()` records the selected seed, extra-draw flag, picker state and last action. `restore_museum_state()` restores these, regenerates the colours and synchronizes the handle. `commons/scenes/em/em_portal_stream.gd` calls these methods when capturing and restoring compatible artifact nodes. A portal return with retained state is therefore different from a fresh load without retained state.

This is visit-state restoration, not an authored save-seed button or a promise of persistence across restarting the application. Current source inspection confirms the caller. The current native run verifies the artifact methods and the actual portal caller’s save/restore methods. During restoration the instrument rebuilds its bar strips; the caller now skips removed nodes before computing their state keys. This is not a physical portal or headset trial.

## Supporting encounters

The textile comparison at (6,11) gives three frozen vocabularies the same seed 41. NEXT SEED advances them together; RESET restores 41. The number page at (9,16) draws from shared game randomness and lets old numbers fall off its display. The crank at (3,4) makes each advance an individual action. These supports change the question about a sequence's use and retention; they are not alternative entrances to the first making exercise.

## The portable construction

`doc/book/studies/random-definition/` isolates the same generator and assignment principle. `study.gd` begins with one cube. Six complete scripts carry it through a seeded colour, a 4 × 4 grid, a matched pair, a one-draw offset and an RGB-role exchange. `display.gd` supplies geometry, individual materials and input; it consumes no random values. No XR setup, slider wiring or museum placement code is introduced in the lesson.

The final assignment exercise starts from the matched pair, with no discarded draw. It changes only the right grid's mapping from `(a,b,c)` to `(c,b,a)`. This comparison belongs to the editable study; the museum has not gained a channel-swap button.

Repeatability is scoped to the generator implementation, engine version and complete procedure. See [Godot's RandomNumberGenerator reference](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html).

## Evidence

The September 12 run's 65 checks describe an older layout and remain historical evidence. Current checks, source snapshots and their exact scope are in [the September 30 review](/book-review/doc/book/iterations/2026-09-30-random-definition-making/index.html). No learner, physical-headset or Quest performance claim is made.
