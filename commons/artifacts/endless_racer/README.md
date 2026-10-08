# Endless Drive

A small arcade driving game entered from **Forces → Carry the point through**
(`Vectors_Act5_ForceAsPlace`). The rose car is before the capability court.
Press **DRIVE** beside its seat. A three-second countdown starts the run.

- VR: grip either rose wheel handle and turn it. Right trigger accelerates;
  left trigger brakes. Release the wheel to centre it.
- Desktop: W accelerates, S brakes, A/D steer; mouse looks around.
- Both: collect gold cubes, avoid rose barriers and guard rails. A hit reduces
  speed. The dashboard counts distance, cubes and hits.
- **RESTART** and **MUSEUM** sit next to the wheel. Desktop also has R to restart
  and Backspace to return. Best distance lasts for this artifact's lifetime.

The cockpit adapts to the visitor's eye height at boarding. Tracked head motion
continues; the game applies no camera roll or camera-follow turn. Step away from
the cockpit centre to return. Physical headset feel and Quest frame rate still
need in-device testing.

## What the model does

`race_model.gd` integrates forward speed, steering response and lateral offset
against a continuous sine-based road centre. Throttle is acceleration; braking
and quadratic resistance reduce speed. Swept longitudinal crossings detect
collectibles and barriers. These are explicit arcade collision rules, not Jolt
tyre, suspension or rigid-car physics. Jolt still handles the surrounding museum.

`road.gd` recycles 28 sections of 16 metres. The car stays in a small pocket of
the same World3D, 2048 metres to the side of its bay, at the same museum z.
The track scrolls past it; neither the player nor a growing set of road nodes
travels indefinitely. Consumed-item bookkeeping discards passed sections.

`endless_racer.gd` owns boarding and the return transform. Desktop movement uses
the museum's existing carry interface; `seat_provider.gd` temporarily owns XR
locomotion. The tracked head remains live. Leaving removes the provider and the
pocket and restores the visitor's pose. Wheel handles use the existing XRTools
grab driver, with controller trigger actions read separately.

The bay is an optional game beside the force studies. The thrust sphere remains
the hall's tutorial carrier. No tutorial or reflective chapter was rewritten.

## Verification

- `tools/probes/endless_racer.gd`: arcade outcomes, 100 km pool recycling,
  desktop handoff, XRTools body, controller inputs, grab steering and return.
- `tools/probes/endless_racer_museum.gd`: real museum placement, wall clearance,
  walking route, driver view, keyboard driving, restart, return and captures.
- Review: `doc/book/iterations/2026-10-07-endless-drive/index.html`.
