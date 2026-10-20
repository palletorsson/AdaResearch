# Two kinds of guidance

Optional full-size encounter in the Boids hall of Endless Museum. Two flights of twelve point-bodied drones begin with identical relative positions and velocities. Cyan bodies seek assigned formation slots. Pink bodies combine alignment, cohesion and separation with a shared destination. Both retain separation, bounded arrival, the same speed cap and soft volume boundaries.

The same `particle_swarm_walk/point_body.gd` supplies pickup and action. Carry it to translate both destination systems. Trigger (desktop left-click while carried) shows/hides guidance. Releasing removes the displacement gradually and returns the point to its stand after 1.5 seconds. Desktop right-click carries/drops it. Hand displacement is measured in the artifact's frame and clamped to ±1.6 m X, ±0.45 m Y, ±0.65 m Z.

The gold witness in each flight exposes actual total acceleration as a cylinder arrow at 0.25 m per m/s². Cyan slot rings and the shared target ring locate destinations. Fine links show the witness's destination and, for the pink flight, neighbours currently within its two-metre perception radius. Hiding guides changes no motion state. A stationary body's acceleration arrow can disappear.

`drone.gd` inherits the existing museum `Boid.gd` integration; it supplies one arrival request through the existing steering adapter. `flight.gd` limits neighbour lookup to its own group. The original sequential neighbour update is retained. These are stylized kinematic agents, not rotor physics, a real-drone controller or a biological validation. Soft steering/separation is not physical collision avoidance. Both systems contain authored choices and shared targets; neither demonstrates a simple opposition between control and freedom.

The east court is connected through three open floor cells. The two small stands alone seal navigation; the floor pads, agents and annotations have no collision. The original flock, aquarium and western fish balcony remain. This encounter does not replace the primary printed Boids lesson.

## Appearance comparison

The three-position physical slider beside the point selects **1 Drone / 2 Point / 3 Light**. Grab and slide its handle in VR, or drag its face with a desktop pointer. Release retains the choice. Point pickup and trigger keep their existing destination/guidance roles.

All three views are prebuilt child nodes under each of the same 24 agents. `set_appearance()` changes their visibility and the selector readout only. It does not replace bodies, draw random numbers, reset velocities, alter targets or change neighbours. The gold witness keeps its identity in every view. Light uses unshaded cores and additive translucent halos, without a dynamic light for every body. The room's lighting stays fixed. These view spheres are rendering geometry; the carried control still uses the original PointBody class.

This returns to the distinction between model and display: a change in perceived coordination need not be a change in steering. The paired trajectory test supplies the same moving target to two copies and changes appearance in only one.

Verification:

- `tools/probes/drone_comparison_checks.gd`: original integrator, destination semantics, transformed host, actual PointBody action, bounds, finite/capped motion and formation convergence.
- `tools/probes/drone_comparison_museum.gd`: native hall, floor/capsule approach, live controls, original exhibits and five images.
- `tools/probes/swarm_appearance_checks.gd`: real pointer and synthetic XRTools near-grab input, identity/state preservation and 720 paired integration steps.
- `tools/probes/swarm_appearance_museum.gd`: reruns the original hall checks, then exercises the selector, captures three identical-state appearances, resumes motion and tests the carried point in light mode.
- `python tools/run_encounter_probe.py SwarmIntelligence_Boids_Algorithm --sequence swarmintelligence --render --no-bridges --output-tag drone-comparison-final --probe tools/probes/drone_comparison_museum.gd`

Controls in the probes are synthetic. Physical headset use and Quest performance still need testing.
