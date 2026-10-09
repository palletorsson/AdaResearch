# Motion: a command meets a stored velocity

The two primary encounters are `VectorMotion` (this map's `motion_chamber` variant), then `friction_ramp`. Begin with the observable comparisons in final.md; use this page to inspect the mechanisms afterward.

## The chamber

Stand between the control banks. PUSH X and PUSH F each request a 2 N force for one second, in local +X or local -Z. A new push replaces the previous command and restarts its duration. COAST cancels commanded force and braking while preserving velocity. BRAKE applies force opposite the current velocity, capped at 2 N; a smaller final step avoids deliberately accelerating past rest. RESET clears position, velocity, local clock and history. MASS cycles 1/2/4 kg and resets the run. Neither reset changes the selected damping or reveal switches.

A `RigidBody3D` integrates motion. There is no manual position update during ordinary motion. Force is converted from the chamber frame to the world frame:

```gdscript
body.apply_central_force(global_basis * local_force)
```

For a constant force away from contacts, the useful prediction is delta_v = force / mass * duration. At 1 kg the full 2 N pulse gives about 2 m/s; at 2 kg about 1 m/s. PUSH F after PUSH X adds a perpendicular velocity component. It does not erase the earlier one.

The body has zero gravity, explicit replacement damping, locked height and rotation, no sleeping and continuous collision detection. DRAG toggles linear damping between 0 and 0.8. COAST does not disable damping. The cube and four static boundaries share only collision bit 19; the visitor and furniture are excluded. Boundary materials produce an elastic reflection under the tested desktop solver. This is a selected horizontal collision world, not the museum's complete contact world.

PARTS reveals three reused arrow rigs: velocity (0.35 m per m/s), measured acceleration (0.2 m per m/s squared), commanded force (0.3 m per N). All cap at 2.5 m. Measured acceleration is the change in solver velocity divided by the physics interval. It can include contacts and damping absent from commanded force. The readout updates at 10 Hz, so brief contact peaks are not a complete force record.

TRAIL displays at most 120 position samples at nominally 10 Hz. It records even while hidden and discards the oldest sample when full. The geometry rebuilds only on sampling; arrow nodes are reused. The running time belongs to this resettable experiment, not the engine's total lifetime.

## The smaller friction ramp

At 30 degrees, vary the coefficient mu; then hold mu fixed and vary angle. Reset between comparisons of descent. The custom scalar model tests:

```gdscript
_is_sliding = sin(angle_rad) > friction_mu * cos(angle_rad)
```

When sliding, acceleration is `G * (sin(angle_rad) - friction_mu * cos(angle_rad))`. Velocity accumulates acceleration times delta. Displayed travel accumulates velocity times delta times 0.01, and reaching the end resets the block. The STATIC branch immediately sets velocity to zero. One coefficient serves the model's starting and sliding conditions. Do not treat that discontinuous reset as the large chamber's braking response or the display distance as an unscaled physical measurement.

The map opts into a physical stand via `#table:1`. Its placement offset is 0.1 m above the museum's 1 m support; the panel is at world height 1.06 m. Other ramp placements are unchanged.

## Red thread and evidence

Launch calculated a complete flight from its initial conditions. Motion keeps a current state for the next intervention. `Vectors_Act3_FieldsAndMotion` follows: inspect whether its spatial instructions prescribe velocity or change it through acceleration before calling them forces.

34 desktop checks pass in `commons/testing/probe_motion_chamber.gd`: real pointer presses, pulse/mass/coast/brake/drag/contact response, bounded history, stable arrow allocation, sampled approaches, control heights, ramp threshold and legacy compact scene. Headset reach, comfort and performance remain untested. All 17 source artifact identities remain; two are primary.
