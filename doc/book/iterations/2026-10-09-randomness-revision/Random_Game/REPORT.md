# A wait kept

**Randomness, hall 14 of 14.** The tutorial closes with one stone and one clock. Its state order is known; its waits are sampled. A cue reads the current decision without replacing it.

## The teaching choice

The former tutorial offered a source walkthrough and fragments, then widened to several artifacts. The new tutorial prints the complete schedule, the body that displays it, and the unchanged PointBody. The larger crossing remains the encounter; the reconstruction is a smaller stone beside it, inspected from the existing museum floor.

The lesson returns to translation, clocks, states, collision and local random generators. Its new responsibility is specific: **draw at a defined moment, retain the result, and let several views read it**. The schedule uses four states with explicit deadlines. Only standing and hidden waits consume variable-duration draws. Movement and collider delays stay separate.

The complete student edit shortens notice from 1.2 to 0.3 seconds. At 0.9 seconds before the same deadline, the original ring is on and the edited ring is off. Both stones still leave at the same time. A second edit makes standing waits exactly three seconds; because that fixed duration consumes no RNG value, subsequent hidden waits read earlier values from the stream. Seed 43 supplies another complete tested variation.

## How the two texts work together

The reflection keeps its crossing, removal floor, doors, disclosure trials, falling field and waiting profiles. Its six GDScript excerpts become prose, and one short addition brings the learner's notice experiment into the encounter. The question remains embodied: before calling a missed step poor timing, where was its warning readable?

The tutorial reconstructs one primary mechanism. It does not claim to implement the other encounters, and the new model has not been registered as a permanent museum artifact.

## Validation

- **33 assertions passed in each of four complete printed programs:** baseline, short notice, seed 43 and fixed standing waits.
- Each version matches 200 alternating waits against the production stone's draw method, including RNG state. Deadline boundaries, sine easing, collider delay, replay, pause, local actions and coarse/fine elapsed-time partitions are checked.
- **Four faulty versions rejected:** reading a cue changes its deadline; replay omits the seed reset; a late update discards phase transitions; a local action uses world coordinates.
- **30 native museum checks passed.** Actual CUE and REPLAY button signals, a full source cycle, reset during motion, learner interactions, support/approach clearance and eight captures are included.

The first native probe looked for the source buttons under their old parent. The museum's compact-console staging had moved them while preserving callbacks. That probe failed four checks and produced null-reference errors; it is retained under `first-room-check`. The corrected probe finds the original buttons under their actual artifact root. No production repair was needed. The first before-closeup looked at the entrance door because the museum's hall placement includes a depth offset; the overhead and corrected close view show the crossing.

## What the evidence does not establish

The learner uses a pausable integer-millisecond clock. The installed crossing uses timers and tweens, with original fractional durations and a cancellation ticket. The tests establish the draw rule and phase logic, not frame-identical live synchronization. A large clock jump can preserve a schedule while skipping poses and physical contacts. This is stated in the tutorial.

The station's local floor and standing approach pass; the whole hall's traversal is not certified. The loader reports an existing blocked authored entrance at (9.5, 0.05, 0.5) and uses a fallback. This pass does not repair that entrance. Test events are supplied by the probe. Physical headset use, Quest performance and an unfamiliar student's understanding remain open. Native images were visually inspected; browser layout has not been checked. Existing engine warnings are retained in the log, with no script or parse errors in the accepted run.

Source algorithms, scenes, map, sequence and inherited PointBody are unchanged from the baseline. Only the tutorial, targeted reflection, learner study, tests and planning records change.

Next: read all fourteen revised pairs as one sequence, check the handoff to Noise, and export the complete tutorial and reflective tracks for review.

[Facing pages](parallel.html) · [Before / after](changes.html) · [Review ZIP](random-game-review.zip)
