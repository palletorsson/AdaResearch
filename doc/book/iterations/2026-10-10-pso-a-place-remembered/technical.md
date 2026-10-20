# Particle Swarm — reconstruction and evidence

The primary operation is remembering a position because it earned a score. The same PointBody class travels from ACO unchanged. Its previous carry flag and shared trail are not retained in this optimizer: continuity belongs to the object and learned tools, not to accumulating every earlier behavior.

## What changed

The previous tutorial offered disconnected Rastrigin/particle snippets, began moving toward an unevaluated global record, left global reset incomplete and promised the global minimum. The replacement prints complete executable code and teaches one fixed objective before introducing objective changes. The model uses the same three fixed objective ideas as the existing display, with squared-distance scores and simultaneous shared-record updates. It is an explicit teaching variant, not a claim that the original algorithm is reproduced byte-for-byte.

The map expands from13×11 to17×23. Interior partitions are removed. particle_swarm_walk stands at cell8,9, yaw180, scale1. Existing fitness_landscape_politics and self_organizing_patterns move to4,19 and12,19; tick_flock becomes a wall-margin plate at1,13. The duplicate ant_colony_v2 placement is removed from this hall; its source is preserved, and the previous hall remains the full-size colony encounter. The original before run instantiated only3 of its4 authored placements. Final native run finds the new primary artifact and both rear comparisons.

Only this map and its em_plan row are changed. The publisher asserts equality for every other hall row. It also updates only this execution-plan lesson and preserves its decision and baseline hashes.

## Model boundary

24 candidates; model coordinates[-6,6]²; starting scatter[-5.5,5.5]²; seed101006. CENTER=-squared radius; EDGE=+squared radius; RIDGE=-(x-y)²/2. Larger scores win. The coordinates map to local(x,0.8,-y), one unit per metre. The coloured floor is flat and shows a sampled score, not a physical height field or pheromone.

Initial candidates are scored before movement. Each personal best is a position/score pair. Strict greater-than retains the earlier position on ties. Before an iteration, hand-placed candidates are evaluated. Then every point sees one snapshot of shared best. Inertia0.6 plus personal/social coefficients1.5, each pull with its own uniform random scalar, produces a displacement capped at0.35 per iteration. Positions commit together; memories are evaluated afterward. Boundary crossing clamps position and zeros the outward velocity component. No wrapping, collision avoidance, physical mass or force integration is implied.

Playback is ten iterations per second, starts paused, and caps a single frame's accumulated time at0.5s. Under long rendering stalls this is a slowed demonstration, not real-time physical integration. Restart resets the seed, population, records and iteration count but retains objective and coefficients. Objective change preserves position, velocity, clock and random stream; it resets records to the current candidates and pauses. Neither action runs while a point is held.

Holding pauses every candidate, zeros the held point's velocity, records its position in the host's local plane, and retains its previous best. Release alone is not a scored iteration; the next step evaluates the current candidate before calculating its motion. If Run was active before pickup, release resumes playback. A held trigger selects the witness. White ring=current selected body, blue=personal best, gold=shared best. The two thin cylinders show unweighted position differences, not random weighted forces or future trajectories.

Original fitness_landscape_politics is retained unchanged as a smaller contextual exhibit: its scores use ordinary distance, motion updates sequentially and NOVELTY compares an evolving bounded archive. The new lesson's full source covers fixed objectives and explicit objective reset. Its reflection discusses the archive as a comparison, not a hidden dependency.

## Runtime and printed source

Study: doc/book/studies/swarm-through-the-hands/SwarmIntelligence_Particle_Swarm_Optimization/study.tscn. Runtime: commons/artifacts/particle_swarm_walk/particle_swarm_walk.tscn. Both export presets exclude doc/**, so the permanent scene inherits local runtime copies. All three scripts are byte-identical to the study and to the fenced blocks extracted from canonical tutorial.md. The copied PointBody itself is unchanged from ACO. Its visual child and spherical grab collision are enlarged together to0.51m diameter; its rigid-body root stays unscaled. Rendering uses one256-cell MultiMesh,24 spheres, three rings and two cylinders.

The museum and XRTools are explicit prerequisites. The example does not supply a player or lighting in an empty standalone Godot project. The review ZIP contains the study files; reconstruct inside a working copy of the prepared hall and replace the installed example. No APK or packaged desktop export was built here.

## Evidence and repairs

**39 fresh printed-code checks pass.** They include exact numerical scores and velocity contributions, an independent zero-social edit, deterministic replay,1800 bounded iterations across the three objectives, boundary behavior, tie retention and objective-scoped records. Three faulty programs are executed: unevaluated initial scores, stale records on objective change, and sharing a new discovery halfway through an iteration. A designed two-point fixture catches the last fault; the same fixture passes against the printed model. Synthetic XRTools pickup/release runs under a translated and rotated host. It verifies retained memory, local coordinates, trigger selection, reset guards and evaluation after release.

The first code pass exposed weaknesses in two test expectations: headless rendering does not provide usable GPU colour readback, and negative zero formats as -0.00. Field colours are therefore asserted in the rendered native run; memory markers are checked against their actual coordinates. A cylinder transform error found during visual inspection was corrected and now has an endpoint assertion.

**23 native saved-room and capture checks pass.** Twenty-one centre-route samples and twelve control approaches have physical floor support and capsule clearance. These are samples, not an exhaustive navigation proof. Actual button signals change the model and the displayed objective. The first arrangement put front controls too near the wall; moving the main field inward then revealed an overlap with the rear comparison controls. The latter moved back one metre. Earlier failed spatial reports remain under pso-lesson and pso-final; the published run is pso-ready.

Eye-level, overhead, displaced-memory, EDGE, RIDGE, control and comparison images are actual Godot captures. The displaced-memory image uses a scripted placement equivalent to the separately tested hand action; it is not a photograph of a headset session. The native probe also verifies rendered frozen bodies remain aligned to their model after physics frames.

No GDScript errors in final code or native logs. Existing project UID and Jolt solver-bias warnings remain. No physical-headset comfort, Quest performance, real controller tracking, independent ghost student, global optimum or actual portal-crossing certification is claimed.

Replay: python tools/write_swarm_pso.py; python tools/place_swarm_pso.py; python tools/test_swarm_pso.py. Then run tools/run_encounter_probe.py SwarmIntelligence_Particle_Swarm_Optimization --sequence swarmintelligence --render --no-bridges --output-tag pso-ready --probe tools/probes/swarm_pso_room.gd, and python tools/publish_swarm_pso.py.
