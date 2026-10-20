# A direction in common

Optional walk-in encounter in the existing Flow Fields hall. Twenty-four point-headed figures follow a supplied direction field around a low island. The original table and other exhibits remain.

Carry the existing `particle_swarm_walk/point_body.gd` control. Move it more than 20 cm toward the cyan A side (local −Z) or pink B side (+Z). The middle band retains the selected destination. Trigger, or desktop left-click while carrying, toggles floor arrows. Desktop right-click carries/drops. Drop selects RETURN; all the same figures walk back, and the point returns to its stand after 1.5 seconds. No agents spawn or disappear during a trip.

## What is reused and what is new

`model.gd` instantiates the existing `algorithms/pathfinding/flow_field/FlowGrid.gd`. It retains that class’s cost propagation. All route costs are uniform in this exhibit. A new adapter chooses cardinal lower-cost neighbours, with an inflated obstacle margin, instead of the table’s eight-neighbour gradient. Agents steer toward successive cell centres with bounded acceleration and speed, then take individual assigned parking positions on arrival. Parking is supplied staging, not emergent coordination.

The new movers read the shared field; they never read one another. Their coloured spheres, bodies and swinging legs are visual children, not rigid-body people. They can overlap; this is not a pedestrian safety or crowd-pressure simulation. The island and hand-control stand have real collision for the visitor. The grid also excludes the island for the movers. Directions are drawn from the same field used to choose their next cell, using thin cylinders and cone tips.

The figure positions and velocities persist across target changes. Hiding arrows affects rendering only. A prepared route can produce a collective turn without local flocking rules. This distinguishes the encounter from Boids and keeps route construction separate from Graph Theory’s later search lesson.

## Verification

- `tools/probes/flow_crowd_checks.gd`: all three destinations, mid-route reversal, island clearance, speed bounds, unchanged witness when other agents change, transformed host, actual PointBody desktop pickup/action/drop, displayed arrow direction.
- `tools/probes/flow_crowd_museum.gd`: live museum, original table retained, floor and standing-capsule routes, live arrival/return, controls and six native images.
- `python tools/run_encounter_probe.py SwarmIntelligence_FlowFields --sequence swarmintelligence --render --no-bridges --output-tag flow-crowd --probe tools/probes/flow_crowd_museum.gd`

The automated controls are synthetic. Physical headset use and Quest performance remain untested. The canonical tutorial and reflective text are preserved; the encounter report is a separate review surface.
