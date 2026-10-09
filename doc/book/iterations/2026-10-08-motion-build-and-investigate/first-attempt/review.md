# Ghost student reconstruction review

## What I used and produced

I read the packet README, lesson.md, shared-code.md and the declared Lines, Coordinates, Trace, Transformation and Launch tutorials. I did not inspect existing force implementations, the source lesson directory, teacher probes or other review reports. I have not run Godot or engine tests.

The four reference scripts are extracted from the visible complete code blocks without substantive edits. comparison.gd is my independent construction using the reference loop, a two-entry mass array, a two-entry duration array and a separate remaining-time entry for each point. Predictions were saved before the scripts were written or any engine execution.

## Instructions I could follow

The local file arrangement is explicit: keep the three helpers together and save a lesson script beside them. The supplied museum and button scene contract make rebuilding the hall unnecessary. The reference provides the force call, physics callback, pickup check, final partial-step scaling and caption formatting. Trace supplies indexing and iteration. Launch supplies the displacement calculation needed to compare distance, although the exercise does not explicitly point back to that formula.

## Exact points that needed interpretation

1. **lesson.md, “Build another comparison”: “Keep an independent remaining-time value for each point. A two-entry array and the loop pattern above are enough.”** The example only assigns a scalar clock. The earlier Trace lesson explains reading and appending entries, but does not demonstrate assigning an existing numeric entry with `remaining[i] = ...`. I inferred indexed assignment and used it both to start and to decrease each clock. This is a small new syntax step that could use one explanatory sentence without giving away the comparison.

2. **lesson.md, “Read the change”: “A greater mass receives a smaller acceleration from the same force.”** The text gives three specific speed changes but does not explicitly state acceleration = force / mass or change in velocity = force × duration / mass. I inferred those relationships to predict a new mass and duration. The mass comparison supports the inverse relationship, but the request to calculate a new duration would be clearer with the proportional rule stated explicitly.

3. **lesson.md, “Build another comparison”: “Also predict whether equal final speed puts them at the same distance from their starting places.”** The caption requirement later says only “Show both speeds in the caption.” There is no distance readout or sampling instruction, so a student can predict unequal distance but has no specified numerical verification route. I used Launch's position formula, separately for the accelerated and coasting intervals, to predict 1.5 m and 1 m at 2 seconds. My comparison follows the requested two-speed caption and does not add a distance display.

4. **lesson.md, “Build another comparison”: “Use a clear bay, no gravity or damping, and separate the points so they cannot collide during this comparison.”** I interpret separation as two parallel free trajectories at X = -1 and X = 1 with force along +Z, rather than adding lane constraints. With 0.14 m radii, they have 2 m of lateral centre separation. This is enough under the stated hands-off conditions. It does not prevent a later grab or external collision from steering one into the other. The lesson's “Model notes” explicitly says the tutorial leaves all three directions available, which supports this choice.

5. **shared-code.md, “Set up once”: “Use your existing PointStudy Node3D in a clear working bay inside each hall”.** The supplied museum is sufficient as a dependency, but the packet does not identify a concrete bay placement or unobstructed run length. I assume the parent will install the study where both +Z paths have enough room for at least the two-second comparison and an additional coasting interval. At 3 seconds the faster-starting point has travelled 2.5 m. I did not inspect the hall to choose that placement.

6. **lesson.md, “Read the change”: “Wait for one pulse to end before comparing a second” and “pressing during a pulse restarts its remaining time.”** The separate exercise does not restate the two-clock version. I kept that behavior: pressing the shared button assigns both durations again, and does not reset positions or velocities. Fresh numerical trials therefore require restarting the study. Pressing again after the first run adds another 1 m/s to both bodies, given the same hands-off conditions.

7. **lesson.md, “Model notes”: “Godot accounts for the physics time step when applying force.”** The packet explains the final partial force step, but does not state when a readout within `_physics_process` observes the resulting velocity, or what numerical tolerance to use for distance. I treat the caption as an ongoing observation and predict the ideal continuous values. I would not infer a failed force rule from a single displayed frame at the boundary without knowing its sampling time.

8. **lesson.md links such as “Setup and complete shared code” and the links in “What you bring”.** Their relative paths refer to the course layout rather than this flat packet. The README and clear filenames allowed me to find the supplied texts. If this packet is intended as a standalone student handout, those links should point at its local files.

## Assumptions carried into the comparison

- The existing museum provides Godot XR Tools and the exact push_button scene path shown in study.gd.
- The study and its ancestors have unit scale, and the study frame remains stationary during the trial.
- New points start at rest; neither is held while measuring; no extra forces or contacts intervene.
- The supplied free_point.gd contract governs gravity, damping and physical release. I did not reproduce those settings in comparison.gd.
- The same force means the same 1 N world-space vector for both points, obtained from the shared local vector by the study's global_basis.
- A “lane” in this small reconstruction is the point's separate straight path; no extra physical rails, locks or collision-layer edits were specified.

These findings describe what I could reconstruct from the lesson. They do not establish compilation, measured engine behavior, visual usability or a human learning outcome; execution remains for the independent checker.
