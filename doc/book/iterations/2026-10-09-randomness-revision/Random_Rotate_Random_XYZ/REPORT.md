# Keep the turn

**Sixth of fourteen Randomness halls revised.** The cube and PointBody return. One list of turns drives two identical cubes: one takes the latest angle, the other retains the sum.

## The lesson in the sequence

The continuing die introduced a record and a running total. Here increments can be positive or negative, and their sum becomes an orientation. This prepares Random Walk: replace the sum of turns with a sum of displacements, then use Trace's list to retain the path. The new subject is accumulation, supported by rotation already learned in Transformation.

The learner creates a small comparison inside their copy of Endless Museum. All lesson geometry and the unchanged PointBody dependency are printed. The museum supplies the player, camera, lighting and XR Tools. Two marked cubes receive the same saved input. Reading begins at the short `step()` function; the supporting construction remains available in full.

REPLAY rewinds the list cursor without redrawing. STEP reads once. PLAY reads at a fixed interval; PAUSE retains the partly completed interval. The record is finite. The student's edits change amplitude, axis, or a deliberately supplied list while keeping the comparison interpretable.

## What inspection changed

The legacy tutorial mixed isolated sketches, missing variables and helpers, an unimplemented history, and a false claim that hashing clock readings supplied hardware entropy. The replacement distinguishes input source, retained state, timing and display. It makes no claim that random Euler components uniformly sample spatial orientations.

The artifact named `Random_Rotate_Random_XYZ` currently searches for `GridMultiMesh`. That floor-grid target is absent in this museum layout, so the artifact does not rotate anything here. The lesson's installed reference is instead the working `random_decay_multimesh#study:rotation` display already central to the reflection. This finding changes the teaching plan, not the production artifact.

The installed display has twenty cubes and 120 prisms. In this study its rates match; drift, sinking and colour changes are disabled. Its internal angular velocity and wear state make it more elaborate than the two-cube reconstruction. It also updates on rendered frames. The tutorial explicitly separates this implementation from its fixed-interval comparison, rather than promising equivalent trajectories.

## The two texts

The reflection keeps the weathering rig, changing stacks, pause/reset distinction and static half-sine field. Its opening now connects with the previous room's sum. A short passage locates the difference between receiving the same input and retaining the same history.

Two unsupported numerical comparisons were corrected: an approximate turning timetable was replaced by its actual frame dependence, and the claimed threefold default rate difference was removed. The current defaults are 0.32 and 0.14; this hall matches both to 0.32. RESET aligns the installed pieces and clears their accumulated state but does not rewind the random generator.

## Predicted changes

| Input or edit | Latest-angle cube | Accumulating cube |
|---|---|---|
| +10°, +10°, −5° | Ends at −5° | Ends at +15° |
| Equal and opposite turns | Takes the second turn | Returns to zero |
| Two half-turns | Takes the last half-turn | Stores a full turn although its pose returns |
| Amplitude 20° → 40°, same seed | Each sampled angle doubles | Each prefix sum doubles |
| Axis Z → X, same record | Same values, different axis | Same sums, different axis |

The real capture uses the default seed 42 after thirteen entries: the latest angle is about −19.4° and the sum about −86.0°. No specially searched seed was used. The marker makes a near-quarter-turn distinguishable from the cube's original pose.

## Evidence

The exact printed files and three source edits—double amplitude, local X axis, and the supplied +10,+10,−5 record—each pass **29 Godot checks**. Four faulty variants are rejected: replacing the sum, drawing during replay, losing steps during a slow frame, and moving the centre when rotating.

Checks cover initialization, inherited point actions, seeded samples, shared input, cancellation, full-turn state, unchanged geometry, finite and empty records, replay without draws, independently owned state, paused time, manual stepping, different frame partitions and catch-up after a slow frame.

The first test found a real integration mistake: the action callback omitted the object argument emitted by XRToolsPickable. That version is preserved in `failed-first-run/`. The final listing accepts the argument and passes the actual signal route.

The native museum run passes **26 checks**, including five capture-camera checks. It confirms the active stack, inactive grid rotator, controls, matched rates, fixed positions and sizes, and the 25-cube static half-wave. The turned-stack image follows 3,600 supplied 1/60-second updates after the initial delay check. This is controlled simulation time, not a claim about sixty seconds on another machine.

The learner comparison was reconstructed from the extracted printed code in a temporary bay. The first placement failed its floor check: a raised floor cut through the plinths and control shelf. Its images and receipt remain in `failed-first-placement/`. A second passed the geometric checks but its photograph was obstructed by a foreground tool; those images remain in `occluded-second-placement/`. The final placement checks the floor under both plinth footprints and a body-sized visitor approach, then exercises STEP, PLAY/PAUSE and REPLAY through the inherited point action.

## Scope and remaining questions

The map, installed artifact sources and PointBody class match their saved pre-edit hashes. The temporary reconstruction is not a permanent new exhibit. Native images were inspected directly. This is an author-informed reconstruction, not a blind ghost-student reading or a physical-headset test.

The log still reports the absent GridMultiMesh target and safe-fallback routing for blocked authored entry/exit positions. Full walking and teleport acceptance need a separate visit. The existing unknown UID and renderer-compatibility warnings also remain. No accepted run contains a script, parse or signal-callback error.

HTML links, printed-code parity and ZIP contents are checked. Browser layout was not inspected because the browser blocks local file URLs. The reflection's earlier static-field figure is retained and copied into the packet; it is not represented as a new capture.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Before/after](changes.html)

[Predictions](predictions.md) · [Code results](tests.json) · [Museum receipt](museum/report.json) · [Editable sequence plan](../../../course/randomness-revision/PLAN.md) · [Review ZIP](random-rotate-review.zip)
