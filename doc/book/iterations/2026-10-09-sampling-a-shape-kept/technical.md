# When does a body become a form? — implementation

Primary source scenes:

- `res://algorithms/softbodies/rounded_softbody_test.tscn`
- `res://commons/artifacts/frozen_glass_vessel/frozen_glass_vessel.tscn`

The hall desk is implemented in `commons/artifacts/timing_machines/soft_workshop.gd`. It binds models inside this map, offers MEASURE, FEEDBACK, SQUEEZE, STIFFNESS, DURATION, GRAVITY, RULE, and blocks repeated activation during rebuilds. The seven controls fit a 4×2 desk with a small inclined transparent readout.

The rounded body continues to respond while an instrument colours its surface. MEASURE changes what is made legible: strain, collision or volume. The body has not acquired a new material because we changed its reading.

Keep the reading on volume and press FEEDBACK. Now the instrument acts back: it adjusts pressure to bring its reading toward the recorded value. Switching FEEDBACK off restores the selected pressure. It does not retrieve the body you had before.

What has been asked to stay the same? This instrument measures the box around the vertices, aligned with the room's axes. It does not measure the space enclosed by the skin. A fold can change the body without changing that box. A number that helped us look has become a number the body is asked to follow.

SQUEEZE changes the strength used by the artifact's existing squeeze interaction. STIFFNESS changes resistance in the solver. Watch the instrument as well as the silhouette. A colour scale can bring a small difference forward, or persuade us that its chosen quantity is the whole event.

The strain display compares the current vertex positions with recorded positions. That reference belongs to the model. Returning toward it is not a universal tendency toward an original or natural body; it is a particular constraint implemented here.

The branching study and field sculpture remain nearby, so the new capability can be compared with earlier ways of constructing an organic-looking form. A branch recipe, a deformed surface and a sampled field may resemble one another without explaining one another.

The glass vessel has already stopped. Its program begins with a sphere, pins an upper region and runs a custom soft-body simulation for a chosen number of steps. It then builds a surface from the resulting positions.

```gdscript
sim.gravity = Vector3(gravity_x, gravity_y, gravity_z)
sim.constraint_passes = 5
```

DURATION reconstructs the vessel using 40, 200 or 400 solver steps. GRAVITY changes the lateral component of the force. Compare duration first while the force remains fixed. These are numerical steps in a reconstruction, not seconds borrowed from the museum clock.

The object is evidence of a process, with most of that process absent. A different stop could have become the sculpture. Walk up to the frozen skin. Its surface can meet your body; transparency has not made it passable. Look for a mouth. This specimen began as a closed sphere, and deforming it has not cut an opening. To make a vessel we could enter, we would have to change more than its silhouette.

A frozen result lets us look longer. It also makes the timing of a decision disappear into the apparent permanence of a thing. Next, we will ask what else an image of a body invites us to infer.

Floor provenance: earlier structure cells remain behind the front court. Raw zeros receive explicit covers after relocation; this does not redefine zero globally. See `doc/space/soft-sequence-2026-09-15/floor-audit.json`. Headset reach and comfort require a human pass; runtime receipts separately record tested desktop operations.

Implementation notes: `volume_feedback` is independent of `measure` and defaults to false. Pressure feedback uses elapsed delta with the existing gain, a 2% deadband and a pressure range of -1..2. The local MODE/FEEDBACK buttons and hall desk control the same state. The hall's `lesson:true` seats the specimen bench before its physics reference capture; other test-harness placements retain their elevation. Frozen glass geometry is translated above its floor datum after simulation, with a two-sided trimesh collision child that is replaced on each reconstruction. This supplies surface contact, not a solid interior or a cut mouth.

The rounded body's mesh is created before `SoftBody3D` enters the scene tree. Godot 4.6 connects its simulation/render path when entering the world; adding an empty body and assigning its mesh afterwards had left the point readings at zero. The six mesh faces now have consistent outward winding. Deck collision includes the visible apron depth, avoiding the initial expansion passing through the former 6 cm shell. World-space overlays and the desktop squeeze centre follow simulated points, while the history chart stays in the bench's local frame.
## Executable snapshot lesson — 9 October 2026


Canonical learner source: `doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Playground_of_Joy/`.

The new host copies the custom vessel solver's local positions and face indices into a separate ArrayMesh. The old Jolt panel is not treated as exposing the same state interface. PointBody is byte-identical to hall5; the supplied solver is byte-identical to `commons/soft_body/soft_body_sim.gd`. The adapter follows the installed vessel's construction and iteration order. Native comparison at 200 steps measured maximum vertex difference 0.0000000 m.

Host timing: one explicit 0.0166667 solver step per physics callback, automatic capture40, trigger/key1 recapture, key2 reconstructs solver and clears snapshot. The stored copy has positions, indices and step number. Previous positions, constraints, force history, collision and disk persistence are not included. Two MeshInstance3D translations stage the same local coordinate system. The independently run edit captures at step200. Normals are rebuilt for each mesh.

27 executable checks extract the four exact tutorial blocks, run their complete program, exercise actual keyboard dispatch and synthetic XRTools, compare installed geometry, and reject following-copy, clock-only-reset and truncated-face faults. 29 museum checks cover all seven real pointer controls, floor/capsule clearance, the temporary learner host and its step200 edit. This is native desktop/synthetic-input evidence, not a physical headset or independent human learner test.

The selected hall desk moves from (15,3) to (11,5) in map_data and the corresponding museum plan row. No artifact algorithm, solver, registry or sequence order changes. The runtime learner host is mounted temporarily at map-local (15,0,14), yaw180, unit scale; it is not a permanently registered duplicate. The checked route ends inside the exit at z47.5 for this 49-row hall. Its capsule query excludes the visitor's own Walker body.

SQUEEZE maps the desk's normalized .2 setting to strength1.0; .6 maps to3.0 and0 disables it. Existing pressure feedback requests a -1..2 range; Jolt clamps negative SoftBody3D pressure to0. Numerical values in a control and physical effects should be distinguished.

Report, screenshots, printed files, independent edit and receipts: `doc/book/iterations/2026-10-09-sampling-a-shape-kept/`. Reproduce with `python tools/test_sampling_lesson.py` and `python tools/run_encounter_probe.py SoftBodies_Playground_of_Joy --sequence softbodies --render --no-bridges --output-tag sampling-verified --probe tools/probes/sampling_room.gd`.
