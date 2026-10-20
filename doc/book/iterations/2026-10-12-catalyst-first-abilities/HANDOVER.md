# Catalyst first abilities — test-map handover

Request: start building the catalyst/counterpart trajectory in a test map. Start with a small playable route, not all 25 sequences. Existing museum, VR objects and code are the base.

Implemented: isolated 13 × 36 m map and F6 scene. Charge a wall rod in the sphere's field → draw/release → actual record becomes a sculpture in the next room → same burning head waits in the Dürer apparatus, then moves into the arena → actual sphere projectile interrupts it and opens the gate → crossing completes. Reset available at arrival and arena. Head contact counts a touch; no health damage or forced movement. The initial power and emitting sphere are supplied in this prototype.

Launch: `commons/testing/catalyst_first_abilities.tscn`, F6. Uses actual Endless Museum generator and existing XR rig when OpenXR is available. A private plan and private museum output files keep this experiment out of the live walk. No new curriculum sequence or textbook changes.

Implementation: `commons/hazards/catalyst_counterpart/proving_ground.gd`, `charged_rod.gd`, `trial_trace.gd`. Reuses `drawing_pen.gd`, DrawDot, `resolution_catalyst.gd`, `flying_skull.gd`, and the Dürer tableau. The new map's map_data describes the shell; the launcher mounts the encounter controller after museum generation. Do not expect loading map_data alone in GridSystem to mount the encounter.

Data: capped local array of world positions, independent retained copy, fitted visual copy of its intervals. No TraceData/TagSystem writes from this prototype. This is not a change to production Trace → Grid persistence.

Verification: `python -X utf8 tools/test_catalyst_first_abilities.py --render` passes 43/43 checks. Tests real XRTools pickup, field dwell, actual recorder, record ownership, actual projectile collision, door collision, head identity, cancelled arrival/reset, tool return and continuous floor. Six native museum photographs. The harness supplies hand poses; no headset or enjoyment claim. Receipt/source hashes: `checks.json` beside this file.

Reset issue found and fixed locally: a rigid body's release pose could overwrite its immediate home reset in the same frame. The test controller also schedules the existing tool return timer after the physics sync. Held tools are never pulled out of the hand.

Build report: `python -X utf8 doc/book/iterations/2026-10-12-catalyst-first-abilities/build.py`. Rebuild plan after map edits: `python -X utf8 tools/build_catalyst_test_plan.py`.

Next: human headset pass for the wall rod's reach, charging feedback, sight of the kept drawing, warning time, sphere aim and a satisfying reason to intervene. Later: acquired two-hand power continuity, a richer counterpart relationship, and other operations from the spine. Keep those proposals separate from what this first test actually implements.
