# Ant Colony — reconstruction and room evidence

## One carried operation

The previous tutorial used an unrelated travelling-tour graph and an undefined tour_length. It did not reconstruct the two-channel foraging exhibit. The new tutorial prints a complete model and host, carrying PointBody byte-for-byte from ABM and Boids. The carrying flag now selects one field to read and the other to write. Returning no longer steers directly toward a known home coordinate.

This lesson is a simplified foraging reconstruction. It is not the full AntColonyV2 simulation: it uses24 spheres, a16×16 field, deterministic starting headings and strict strongest-sample steering. It omits production diffusion, random wandering and collision-based destination Areas. Contact is a numerical distance check. We do not infer optimality from a bright path.

## The room is permanent

ant_colony_walk is registered at commons/artifacts/registry/ant_colony_walk.json and placed at cell8,8, yaw180°, scale1 in this hall's map_data.json and em_plan row. It replaces AntColonyV2:0:0:0.22 here; the original scene, algorithm and other placements are retained. All other runtime hall rows compare equal to the saved before state.

The field is12×12m, with controls on opposite ends, offset to keep the central doorway view open. Each model cell is0.75m.24 sphere bodies are0.51m across and move at0.8m height. Their mesh and collision radius are enlarged together; the RigidBody3D root remains unscaled. They are model-driven frozen pickables with mask0 and do not obstruct the walking route. Home and food rings have0.75m contact radius. A green cube indicates carrying and a gold ring identifies the selected witness.

Blue and rose strips are paired within each cell, not separate navigational lanes.512 strips are drawn by two MultiMeshInstance3Ds. Their surfaces sit above the supplied museum floor, removing the old coplanar/displaced display interference. The display is visual; the museum provides walking support. Controls are0.95m high. Holding any point pauses the whole model so the selected body can be moved without a chase; the held trigger selects the witness.

The initial control banks crossed the doorway view. Visual inspection led to moving each bank3.5m sideways and reducing nearby labels. Earlier captures remain in ada_run under aco-lesson and aco-final; the published images use the final exportable artifact run. No artificial diagram is presented as an engine image.

## Printed code and export copies

Study: doc/book/studies/swarm-through-the-hands/SwarmIntelligence_Ant_Colony_Optimization/study.tscn. The tutorial prints colony.gd, point_body.gd and study.gd in full, with carried/host files folded for reading. Students work in a copy of the prepared museum hall, replacing the existing artifact rather than superimposing a second one. There are no hidden dollar mesh references. The supplied button and XRTools dependencies are named explicitly.

Both existing export presets exclude doc/**. The permanent scene therefore inherits commons/artifacts/ant_colony_walk/study.gd with local colony.gd and point_body.gd dependencies. The test runner and publisher require these copies to be byte-identical to the study and exact extracted tutorial blocks. No doc path remains in the runtime dependency chain. An exported APK or desktop package was not built in this pass.

## Exact boundaries

16×16 periodic position/sample field;24 agents;0.05s tick;3cells/s speed cap;0.5s response;6cells/s² acceleration cap. Home(3,8), food(12,8), contact strictly less than1cell, tested before motion. Destination distance is direct, not a wrapped shortest distance. The maximum0.15cell movement per tick is less than the contact radius.

Contact reverses model velocity once, flips state and restores energy1. This is an explicit model event, not a physical collision. The ordinary bounded steering resumes between contacts. Equal samples keep heading; stationary points choose east while searching and west while returning. No random generator or global pathfinder is concealed here.

Every point reads old fields. All positions and velocities commit before either field is faded or written. Both retain99.5% per tick. Energy falls0.0025 each tick and stops at zero. Deposit is0.5×energy, capped at8. Searching deposits home; returning deposits food. Finally the home cell's home value and the food cell's food value are set to8; no other source cells are renewed. Food is inexhaustible.

Replace restores the24 agent records and energies, retaining both fields, tally and clock. Clear resets those records too while preserving retention and deposit settings. The visible empty fields are replenished at the two source cells on the next tick. Hold zeros velocity, preserves cargo/energy and pauses all ticks; both resets ignore a held point. Release returns it to the model's plane. The same scene instances survive these operations.

## Executed checks

42 checks pass in a fresh Godot4.6 process using code extracted from tutorial.md. They cover isolated channel reads/writes, unchanged opposite-channel deposits, saturation, evaporation, source renewal, energy decay, contact timing, one delivery, one reversal, wrapping, reset scopes, reversed traversal,2000 finite bounded ticks and an unassisted delivery cycle. The independent half-deposit edit produces0.25 directly and0.249375 after tick energy decay. Three faulty variants execute and fail the relevant expectations: wrong read channel, wrong write channel, and destructive population replacement.

The host checks instantiate actual XRTools pickup machinery under a translated/rotated host, move and release the same sphere, trigger selection, test held reset guards and verify visible cargo and channel captions. These are author-operated reconstruction tests, not an independent ghost-student or physical headset assessment.

22 native checks pass in the actual saved ACO museum hall. These include both control banks,24 bodies, two256-instance field batches,15 centre-route floor/clearance samples, eight control approaches, visible field elevation, replacement/reset scope and rendered rigid-body position across physics frames. The unassisted model has delivered9 items by tick260 in this capture. The receipt includes screenshot-camera checks. Actual player portal crossing, headset comfort and headset frame rate remain untested.

The final logs have no GDScript errors. They retain the project's pre-existing unrecognized resource UID and Jolt solver-bias warning. Neither is presented as repaired here. The sequence's referenced ant_colony_axioms.md and stigmergy_axioms.md are absent; no content was inferred from those missing files.

## Replay

1. python tools/write_swarm_aco.py
2. python tools/place_swarm_aco.py
3. python tools/test_swarm_aco.py
4. python tools/run_encounter_probe.py SwarmIntelligence_Ant_Colony_Optimization --sequence swarmintelligence --render --no-bridges --output-tag aco-exportable --probe tools/probes/swarm_aco_room.gd
5. python tools/publish_swarm_aco.py

The initial state is preserved under before/. The report includes complete texts, code, receipts, source hashes and real museum images. Next: Particle Swarm Optimization, hall6/7; retain this room-scale approach and the same sphere.
