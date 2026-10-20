# ABM — reconstruction and evidence

## What is now taught

The previous tutorial introduced unrelated FORAGING/FOLLOWING/RESTING states with undeclared dominant_state and initialise_swarm helpers. The replacement teaches a state change visible in the existing foraging exhibit: collect, return, deliver. Boids was already an agent-based model; adding a Boolean is a new behaviour, not the definition of ABM.

All three student scripts are printed in tutorial.md. PointBody is byte-identical to Boids. The host constructs the display and uses the explicitly supplied museum/XRTools/button environment. No hidden sphere scene or dollar reference. The study is saved at doc/book/studies/swarm-through-the-hands/SwarmIntelligence_Agent_Based_Modeling_ABM/study.tscn. Add it to a working Node3D in the prepared Ada museum. The report's native placement is map position(8.8,0,6.5), yaw−90°; it is temporary, not registered as another production artifact.

## Actual code execution

42 checks pass in a fresh Godot4.6 process. The runner extracts the three marked blocks from canonical tutorial.md, compares them with source files, writes printed copies, then runs those copies. It checks contact timing, pickup without instantaneous reversal, single delivery, search-only sensing, return-only deposition, saturation, wrapping, finite bounded movement, reversed traversal, full reset replay, and both reset scopes. A self-running arrangement completes a delivery cycle.

The independent return-speed edit produces the stated first velocity and position. Three faulty variants are executed: never acquiring food, erasing the field during replacement, and counting delivery repeatedly. Each violates its relevant condition. Actual button signals and synthetic XRTools pickup/trigger/release are exercised under a translated, rotated host. The sphere instance is retained through resets and interactions. This is author-operated reconstruction evidence, not an independent student or a physical headset assessment.

The first harness run called max() directly on a PackedFloat32Array, which Godot does not provide. The harness now converts that value to Array for the maximum check. The student model needed no correction for this error. Final logs retain the project's existing unresolved resource UID and Jolt solver-bias warning; no GDScript errors remain.

## Exact model boundaries

Six points;16×16 periodic plane;0.16m/cell;0.05s tick;3cells/s maximum speed;0.5s response;6cells/s² acceleration cap. Home(3,8), food(12,8), strictly less than1cell for contact, checked before movement. Sampling positions and movement wrap; destination distance is direct, not shortest distance across the seam. The default contact radius exceeds the maximum0.15cell step; independently changing those parameters could allow a point to skip the ring.

Searching reuses the three samples. Returners ignore them and know the home coordinate. Returning points deposit after all movement commits and after92% retention. A new pickup deposits this tick; a delivery does not. Delivery requests east for one tick, then search sampling resumes. A stationary searcher also uses east as its fallback. Food is inexhaustible and therefore needs no shared stock allocation. The points can overlap; frozen XR bodies represent a planar model, not a collision-based ant simulation. There is no shortest-path guarantee.

Replace restores the six position/velocity/carry records but retains field, deliveries and tick count. Clear All clears those shared records as well. Both preserve retention and return_speed. While held, all ticks pause and the held velocity is zeroed; cargo persists. Reset and replacement ignore input while any point is held. The held trigger chooses the witness, not a new state. Model food is acquired by contact on a tick.

## Native museum checks

23 checks pass. The actual colony still has40 agents and its original simulation. Population replacement retains a seeded mark and full reset clears it. The learner controls trigger pickup, draw cargo, preserve the exact field on replacement and clear it on full reset. The rendered rigid sphere is checked across physics frames; the normal host update stays active during capture. An earlier paused-host capture showed stale rigid-body rendering despite a correct model position; that investigation is preserved, not presented as final evidence.

The initial room had five isolated authored wall cells that generated obstructing cross-room runs. Removing those five seeds opens the floor between displays. The existing colony faces180° so its projection is no longer backed by the optional navigator. The next marker moves from7,7 to the existing south perimeter opening6,9. Map data and this hall's em_plan row agree; every other runtime hall row is unchanged. The final log does not report a blocked exit. Capsule probes test floor and body clearance along ten centre-route samples, plus the working approach; two rays test the label and far grid. This does not test a physical player crossing the portal.

An initial study position put its Run button in the centre route. Moving the temporary study0.8m east cleared it. Native images were visually inspected after these repairs. The pre-existing lower-case physarum_colony token has no living scene in this hall; the log records5 of6 requested placements. This is not a regression from the spatial edits and is not counted as a working exhibit here. The original colony and navigator remain present; the optional navigator text is preserved and its prior companion is linked, not re-certified by these tests.

## Replay

- python tools/write_swarm_abm.py
- python tools/test_swarm_abm.py
- python tools/run_encounter_probe.py SwarmIntelligence_Agent_Based_Modeling_ABM --sequence swarmintelligence --render --no-bridges --output-tag abm-lesson --probe tools/probes/swarm_abm_room.gd
- python tools/publish_swarm_abm.py

Hashes and engine logs accompany this report. Changes to the code or tutorial require fresh tests before republishing. Next: Ant Colony Optimization, two channels carried by the same point.
