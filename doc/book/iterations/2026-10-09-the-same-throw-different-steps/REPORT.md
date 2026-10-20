# P1 — The same throw, different steps

Installed in **VFM_05_Launch**, cell (29,6), rotated 180° toward entry. The existing registered `euler_drift` gains an opt-in `lesson:step_study` mode; no duplicate registry entry. All 9 previous placement tokens, wall cells and utilities remain. Only this map's generated plan row was rederived. The original launch chamber remains the primary encounter.

## What changes

Both calculated spheres use the earlier PointBody class. One uses the analytic constant-acceleration formula; the other uses explicit Euler, position first and velocity second. The hand slider selects 10, 20 or 40 updates over exactly one simulated second. Five nearby buttons fire/pause, advance one step, replay, choose another throw and reset. Both paths occupy one display plane; their visible displacement preserves the calculated difference vector. The spheres coincide at the start and partly overlap when the error is small. The reference is drawn with 80 line segments independently of the solver count.

Start (-2, 0.75, 0) m; initial velocity (4, 4.9, 0) m/s; gravity (0, -9.8, 0) m/s². The analytic endpoint is (2, 0.75, 0) m. The older launch lesson uses a different gravity and stopping rule; the optional tutorial explicitly introduces this fixture's changed conditions.

| Euler steps | Interval (s) | Signed y difference after 1 s (m) |
|---|---|---|
| 10 | 0.100 | +0.4900 |
| 20 | 0.050 | +0.2450 |
| 40 | 0.025 | +0.1225 |

Difference means Euler minus reference. Reversing the update order reverses the error vector in this fixture: magnitude alone cannot detect that change. This is a discrete calculation on a constant-acceleration model, not a Jolt collision or tunnelling experiment. Global physics settings, player movement and the existing catapults remain unchanged.

## Evidence

- **53 native core/scene checks pass**, including the three exact fixtures, signed difference, shared elapsed time, alternate acceleration/launch, changed render cadence, bounded history, preserved snapshots, controls, rendered-frame position retention and legacy-mode selection.
- **51 checks pass on five files freshly extracted from the printed tutorial.** Only internal resource paths are relocated. The two additional original-source checks test legacy/opt-in selection and do not apply to the isolated learner scene. This is executable reconstruction, not a blind learner review.
- **Two deliberately faulty programs are detected:** velocity-first integration and returning the original history array instead of a copy. Their code and failed assertions remain in the package.
- **22 native museum checks pass**, including five actual desktop pointer buttons, a pickup/movement/release through the supplied XRTools slider, endpoint retention after rendering, and 54 supported capsule-route samples from entry to controls. This count includes capture-camera assertions.
- At most 40 solver updates and 41 saved states per run. The trail only rebuilds on a changed tick. This is a bound, not a Quest performance benchmark.

The first parse found a method name colliding with RefCounted.reference; it is now reference_at. One early test process then passed its assertions but crashed during shutdown. The scene harness now waits after constructing the opt-in scene and completes cleanup inside its own function; subsequent accepted processes exit cleanly. The engine-level crash cause is not established; both failed logs are retained.

The first image exposed frozen points reverting after the test advanced time. A small extension of PointBody now projects the saved state every physics frame, even while paused; the assertions wait for later frames before checking. The first thicker trace had back-face culling and was not visible from the visitor's side. It is now explicitly two-sided, with a corresponding check. An angled view also showed that separating the paths in depth distorted the comparison through parallax. Both now occupy the same plane, and an assertion checks their full difference vector. Failed captures are retained, not offered as successful evidence.

The existing room's width is 44 m; the plan normalizer still reports its pre-existing 13–19 m preferred-width warning. This work did not widen the room. Existing UID/texture diagnostics occur in baseline museum logs too; accepted new-code runs contain no SCRIPT ERROR or Parse Error. A neighbouring Bubble Blaster label draws through the board from the straight-on sightline; the angled capture shows it beside the panel. Its source has not been changed by this work.

Physical headset reach/readability, Quest performance, independent learner comprehension and a full portal journey remain untested. Browser rendering was not tested; local links and ZIP integrity are checked separately. Actual Godot captures were visually inspected, with current walls retained.

## Two texts, one local addition

[The tutorial](tutorial.html) contains the complete model, carried point, display extension, stage and scene. It separates the small calculation from supplied museum display code, explains update order and ends with an independent two-axis acceleration exercise. The complete optional text is appended to the hall's tutorial.md.

[The reflection](reflection.html) follows a difference produced by intervals, without treating accuracy as aesthetic judgment. Three paragraphs are appended to the existing final.md. The original small Euler board keeps its geometry; its misleading tunnelling caption is corrected to identify a visual marker with no collision test.

P1 is built alongside G0, G1 and G2. The next original package is P3: sample budget on the existing Monte Carlo dartboard. P2, P3, P4, P5 and P6 remain proposals, not implementations.
