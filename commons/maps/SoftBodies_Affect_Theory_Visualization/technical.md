# What makes this look alive? — implementation

## Installed encounter

`algorithms/computationalbiology/radiolaria2/radiolaria.tscn` constructs nine forms by drawing from six families. Repeated families are possible. Its source geometry recipes are unchanged. The forms are CSG assemblies, not simulated growing organisms or deformable SoftBody3D objects. Visible CSG skins have `use_collision=false`.

The hall-specific adapter in `commons/artifacts/timing_machines/soft_workshop.gd` now raises the generator by2.2m, selects seed1337 and spacing4m, and adds nine solid low plinths plus a flat display runner. ROTATION originally turned the demo camera, whose view is inactive in the museum. The adapter now also turns each specimen about its own Y axis while that control is enabled. Other chapters do not enter this branch. The original demo camera behaviour and geometric construction algorithms remain unchanged.

The six existing pointer controls remain: ROTATION, COLOUR, EFFECTS, SEED, SPIKES, RULE. COLOUR rebuilds the forms with another palette. At the fixed seed, the tested hierarchy, transforms below each specimen root and CSG construction properties remain equal across this palette change. SEED selects1338/1339/1337. SPIKES changes the polyhedral branch probability and can alter subsequent random choices; it is not a uniform switch for every spine on every family. EFFECTS toggles the existing particles, which may take their lifetime to clear.

Map placements: desk(15,3)→(15,11), radiolaria(9,11)→(15,21). Existing hall dimensions and floor architecture remain. The desk approach and outer route have support and capsule clearance; the route turns toward the centre at z41 before entering the exit frame at z43.5. It does not cross the portal's solid side post. These are checked paths, not exhaustive navigation or inter-hall transition tests.

## Executable learner

Canonical source: `doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Affect_Theory_Visualization/`.

Four complete files are printed in tutorial.md. study.gd is new. vessel_surface.gd, solver.gd and point_body.gd are byte-identical to the preceding Sampling lesson. The host reconstructs the same step40 surface using the same recipe and creates a shared ArrayMesh:330 stored positions and616 triangles. This is repeatable reconstruction, not a disk transfer or continuation of a previous running session. The solver runs only during initialization.

Two MeshInstance3D nodes share this mesh but receive separate materials. Left remains neutral/still. Right has three conditions: neutral/still; turn about local Z at0.7rad/s; accent colour with orientation reset. PointBody trigger or key1 cycles. Key2 restores baseline. The independent edit uses0.35rad/s. Both conditions retain all saved positions and face indices. Shared geometry is safe here because it remains unmodified; it is not a general permission to edit a resource used by multiple bodies.

The test mounts this exact learner temporarily at map-local(18,0,33), yaw180, unit scale. It is a student construction beside the existing encounter, not another permanently registered artifact. Its surface adds neither collision nor biological behaviour.

## Evidence

25 executable code checks pass: exact visible blocks, carried-file parity, previous snapshot equivalence, isolated materials, fixed geometry, condition reset, actual keyboard dispatch, synthetic XRTools pickup/action/release and the independent speed edit. Three executing fault programs are caught: shared materials, an accumulated orientation cue, and a solver that keeps advancing.

36 native museum checks pass, including six pointer controls, specimen rotation, fixed-seed construction comparison, temporary printed host and variation, floor/capsule queries, and retained capture camera. Native eye-level and overhead images are included. Existing UID, compatibility renderer and legacy material warnings remain; final runs contain no script/parse errors. Neither automated assertions nor screenshots establish a visitor's felt response. Physical headset comfort, Quest performance and independent student understanding remain untested.

Reproduce: `python tools/test_affect_lesson.py`, then `python tools/run_encounter_probe.py SoftBodies_Affect_Theory_Visualization --sequence softbodies --render --no-bridges --output-tag affect-final --probe tools/probes/affect_room.gd`.

Report, before/after texts, exact code, independent edit, deliberate faults and receipts: `doc/book/iterations/2026-10-09-affect-one-cue/`.
