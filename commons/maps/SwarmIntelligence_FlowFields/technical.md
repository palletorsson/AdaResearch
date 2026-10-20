# FlowFields — test and placement record

## What is now runnable

The canonical `tutorial.md` prints field.gd, study.gd and the byte-identical PointBody from Physarum. `tools/test_swarm_flow.py` extracts the printed code, verifies equality with the saved study, and starts a fresh Godot 4.6 process. 35 checks pass. They cover the exact first tick (velocity 0.3 cells/s; displacement 0.015 cells), steady motion, bounded reversal, a turn with retained momentum, zero-vector braking and rest, periodic bounds, unchanged field after 1,500 steps, update-order independence, deterministic reset, local edits and preservation of body identity.

A separately generated patch points south; its first velocity is checked against an independent expected value. Three executed faulty variants are rejected: missing current-velocity subtraction, missing acceleration cap, and writing into the supplied field during movement. Actual button signals and synthetic XRTools pickup/trigger/release run with a translated/rotated study. This is author-operated reconstruction evidence. It is not an independent learner review, physical Quest usability test or hardware-performance measurement.

## Museum placement

Baseline captures show the existing 50 m ground and its agents crossing the 13 × 10 hall boundaries. This hall now uses the new `flow_field_table` token at authored cell (4,2), yaw 90, with matching em_plan placement. The table has a 2.8 m live screen on a 2.95 m body. Its private SubViewport/World3D holds the original 40 × 40 field, 200 agents and original route/wind/noise tour. FlowFieldMain.gd, FlowGrid.gd, FlowAgent.gd and their scene/visualizer remain unchanged. The original `FlowFieldMain` registry entry and its other placements are preserved. The table forwards existing scenario/display configuration and names its current scenario.

The full printed learner study is temporarily instantiated beside it at map/world (8.5,0,2.5), yaw −90, for the native run. It is supplied as study.tscn, not permanently installed in the hall. Its six spheres are kinematic teaching objects. Neither simulation is represented as a calibrated fluid model, shortest-route proof or biological reconstruction.

21 native checks pass, including native images, original-agent movement, private-world separation, control effects, clear sightlines and a supported study-bay approach. Overhead, elevated detail and 1.7 m eye-height views are supplied. Turn and brake screenshots use the same reset start and tick 42. These are native Godot images, not generated illustrations.

## Limits found, not erased

The initial approach check continued through a pre-existing central wedge at map/world z 3.5. Its collider names and failed report are retained in approach-investigation.json. The final approach test explicitly covers the study bay from z 1 through 3 plus its controls; it does not certify walking through that wedge.

Both the baseline and final native logs report blocked authored entry/exit and a fallback arrival in this hall. Portal traversal needs a separate repair before this hall can be called ready for an uninterrupted VR walkthrough. The long-standing unresolved UID `uid://rwex60pqapc` also appears at startup. Neither is counted as a passing lesson assertion. The headless code log contains the existing Jolt custom-solver-bias warning. No GDScript/parse errors occur in the final code or native run.

The production zero-vector behaviour remains random wandering. The tutorial deliberately brakes. Model units are cells, cells/s and cells/s²; display size is 0.16 m/cell. Both model bounds and input-edit semantics are explicitly explained. The response time is 0.5 s, acceleration cap 6 cells/s², speed 3 cells/s and step 0.05 s. Patch changes retain body state; Reset clears all edits, restores bodies and pauses. Holding clears that point's velocity and pauses everyone until release.

## Reproduce

1. `python tools/write_swarm_flow.py`
2. `python tools/test_swarm_flow.py`
3. `python tools/seat_swarm_flow.py`
4. `python tools/run_encounter_probe.py SwarmIntelligence_FlowFields --sequence swarmintelligence --render --no-bridges --output-tag flow-lesson --probe tools/probes/swarm_flow_room.gd`
5. `python tools/publish_swarm_flow.py`

The code and probe files are included for inspection. The ZIP is a review bundle for the prepared Ada project, not a standalone game export.
