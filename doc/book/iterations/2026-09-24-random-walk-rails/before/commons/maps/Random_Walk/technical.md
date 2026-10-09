# Random Walk — implementation record

Primary: `res://commons/artifacts/random_walk_terrarium/random_walk_terrarium.tscn`, script in the same folder. Map token: `random_walk_terrarium:90#stand:logbook`, cell (4,1). Museum geometry remains a 13×14 map with 41 raised cells and the existing clear rectangle [[3,1,7,5]]. All twelve placements remain declared; the terrarium is the single book primary.

| Property | Current encounter |
|---|---|
| Tank full extents | 0.5 × 0.4 × 0.5 m |
| Release | (0, 0.2, 0), five walkers |
| Ordinary proposed step | 0.015 m |
| Cadence | 30 batches/s; five walkers per batch |
| Catch-up cap | Five batches/frame; excess time discarded |
| Tail | 200 previous positions per walker |
| Arrival view | ONE: red enlarged, four dimmed |
| Keypad | 2D, 3D, LEVY, RESET |
| Wing | ONE, ALL, NEW SEED; six logbook lines |
| Seed | Private named five-digit seed in the logbook configuration |

No pause or seed-entry control is provided on these panels. DNA memory variants exist in source but are not offered by these seven buttons. A bare instance uses the global stream and has no logbook wing.

`_generate_step` produces one attempted vector; `_reflect_boundaries` folds its tentative endpoint; `_step_all_walkers` appends the old position before writing the new one. `_update_trails` connects the stored samples as a line strip. At step 300 the retained positions are 100..299 and the bead is 300. Wall contacts are not inserted into the trail.

2D fixes y=0.2 and draws one heading. 3D draws two values for a uniform direction on the sphere. LEVY uses three values including the bounded power-law length: 0.015 / sqrt(u+0.01), capped at 0.15 m. The minimum is approximately 0.01493 m. Expected length under an ideal continuous uniform draw is approximately 0.02715 m; P(length>0.10 m)=0.0125. These derivations describe the implemented law, not a claim about a particular short run's frequencies.

The same seed across modes does not imply an identical projected path: the coordinates and number of consumed draws change. NEW SEED loops until its value differs from the current seed; earlier seeds remain possible. RESET re-seeds the private generator, clears history and counters and restores the release positions, but retains fractional step time and the logbook refresh accumulator. Compare positions at equal step counts. ONE/ALL does not remove walkers or change draw consumption.

The frame clock sums `_process(delta)` since reset. Simulation time is accepted batches / 30. A two-second injected frame accepts five batches, advances the frame clock by two seconds and leaves no deferred backlog. This is an internal probe condition, not a claimed measured headset stall.

MSD is sum of squared displacement from release divided by five, displayed to four decimals. Geometric upper bounds: 0.125 m² (2D), 0.165 m² (3D/LEVY). It can fluctuate; it is neither path length nor entropy.

The secondary sampling pavilion mounts `monte_carlo_apparatus`. Its `#show_observation_window:true` token is a string. The metadata reader now uses the existing `_parse_bool` helper, matching adjacent boolean flags, so it can read both true/false and continue to the east-wall setting. This is the only production-script change in this continuation; the terrarium source and scene remain preserved.

Validation: `commons/testing/probe_wcn_walk.gd`, its generated live port, and isolated runner `ada_run/review_walk.py`. The extension captures three complete 300-step, five-walker histories at seed 31415, records actual proposals for walker zero without consuming extra draws, and verifies every frame against a replay that erases trail history at step 60 and selects ALL. Separate assertions cover frame-time loss and the pavilion's boolean metadata. Existing tests cover seven controls, desktop pointer input, bounds, seed replay, physical routes, reach and unload/rebuild.

Runtime evidence, final assertion count, images and diagnostic limits belong to `doc/space/walk-review-2026-09-12/README.md` and the illustrated `random-walk.html` review. Headset use remains pending.
