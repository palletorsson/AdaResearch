# Boids — reconstruction and museum evidence

## Printed code

40 assertions pass in a fresh Godot 4.6 process. The test runner extracts the three marked code blocks from canonical tutorial.md and compares them with the saved study before execution. PointBody is byte-identical to FlowFields. The model and host are complete for the explicitly supplied Ada environment; this is not an empty-project export.

Checks include exact neighbour indices; three independently calculated requests; first separation velocity (0.7,0), alignment (0.9,0.2) and cohesion; the combined cap; strict radius; coincident points; no-neighbour coasting; stationary-neighbour braking; balanced requests; the periodic motion/direct-distance seam; reversed traversal over 20 steps; 1,500 finite bounded steps; deterministic reset; and the independent half-alignment edit (0.95,0.1).

Three faulty models are actually executed and rejected by the checks: self included, combined cap omitted, and in-place state updates. The last produces a different result when order is reversed. The host tests actual button signals, unchanged object identities, radius geometry and synthetic XRTools pickup/trigger/release under a translated and rotated host. Initial test harness compilation tried to resolve XRTools before its autoload; moving that type inspection to runtime fixed the harness. The final log has no GDScript errors.

## What the model promises

Six points on the familiar 16×16 XZ plane, 0.16 m per cell. Speed cap 3 cells/s; response 0.5 s; acceleration cap 6 cells/s²; step 0.05 s. Neighbour radius 3.5 or 2 cells; separation distance strictly below 2 cells, also restricted by the chosen neighbour radius. All rules read old arrays. Alignment uses the actual mean velocity, including its speed; separation/cohesion use normalised direction at maximum speed. Absent or balanced directional requests contribute nothing. An alignment average of zero brakes. Distinct coincident points remain neighbours but have no invented separation direction.

This is an explicitly different small model from the existing aquarium: planar, synchronous and bounded. The production aquarium uses 3D, a spatial grid, sequential updates and boundary bounces. Both remain identified in the tutorial. The learner arrows are weighted accelerations, not distances or instantaneous velocities. The white arrow is their capped combination. Reset restores body state while retaining the selected rule, radius and weights. Holding pauses all and clears only the held body's velocity; release resumes if Run was active. Trigger selects the observed point.

## Inside the existing museum

26 native checks pass. The original 100-agent open flock, 30-agent aquarium and 30-agent controls display are retained. The tank and panel were partly below the floor. This hall now requests plinth heights 0.5 m and 0.85 m; automatic mesh seating places their centres at approximately 1.20 m and 1.32 m. The actual separation slider is checked between 0.8 m and 1.25 m. Canonical map_data and em_plan agree; all other runtime hall rows are unchanged.

The old next-room marker at (10,10) shared the controls' approach. Raising the panel exposed that conflict and generated an obstructing fallback portal. The marker now uses the existing three-cell perimeter opening at (6,12). The report includes the investigation image; it is not used as a successful exhibit photograph. The final run's portal result is recorded separately below. No physical player crossing or Quest test is claimed.

The printed learner scene is temporarily placed at map/world (6,0,9), yaw 0, for this native run. It is supplied as study.tscn, not permanently added to the artifact registry. Its supported approach and two sightlines pass. The first candidate at (9,0,5) intersected a visible wall even though two collision rays passed; its image and receipt are retained under placement-investigation. Native image inspection remains necessary in addition to assertions.

The original controls display repeatedly called ImmediateMesh.surface_end() with no vertices when all three forces were too small to draw. A guard now uses the same 0.001 threshold as its existing arrow helper. A zero-force fixture produces no surface, and a nonzero fixture still produces an arrow. The production movement/update function is unchanged.

## Evidence limits

The test operator is the authoring assistant. These are reconstruction tests, not an independent ghost student's reading or proof of pedagogical success. Synthetic XR exercises the real pickup code but cannot establish hand comfort, hardware performance or headset legibility. Captures use the compatibility renderer; existing Forward+ lighting warnings and the unresolved startup UID remain in the engine log. The old tank-divergence figure is preserved as a dated 25 September measurement, not rerun or generalised here. The final text now says so and distinguishes step count from equal elapsed time.

## Reproduce

1. `python tools/write_swarm_boids.py`
2. `python tools/test_swarm_boids.py`
3. `python tools/seat_swarm_boids.py`
4. `python tools/run_encounter_probe.py SwarmIntelligence_Boids_Algorithm --sequence swarmintelligence --render --no-bridges --output-tag boids-lesson --probe tools/probes/swarm_boids_room.gd`
5. `python tools/publish_swarm_boids.py`
6. `python tools/verify_swarm_boids_review.py`

## Portal log

The final native startup contains no blocked-portal placement warning. This is a placement result, not a physical traversal test.
