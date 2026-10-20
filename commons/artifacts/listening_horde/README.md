# They heard you there

Optional full-size ABM encounter in the Endless Museum. The primary foraging lesson and its canonical `tutorial.md` and `final.md` remain unchanged.

Twenty stylized listeners carry a state and a remembered position. The player carries the existing PointBody sphere. Pressing its action sends a short audible pulse and snapshots the sphere's position. Move away: the listeners investigate the recorded place, then return to their original resting places.

## Controls

- VR: grip the black point; press trigger to pulse.
- Desktop: right-click to carry/drop; left-click while carrying to pulse.
- A dropped point returns to the stand after 1.5 seconds. This does not reset the listeners.
- A new pulse replaces the memory only of listeners inside the eight-metre hearing radius. A half-second debounce prevents repeated press events from flooding the simulation.
- Pulse within the court, above its floor and below four metres. Outside or inside the partition is rejected with a visible message.

## Model

`horde.gd` contains the production state and movement model. `listening_horde.gd` builds the bodies, low partition, sphere stand, sound and readouts in code.

RESTING → audible pulse → INVESTIGATING → within one metre for three seconds → RETURNING → within 0.12 m of home → RESTING. A wall-separated destination cannot satisfy arrival. Investigation projects the recorded 3D sound position onto the floor; hearing itself uses 3D distance to an ear at 1.4 m. Sound occlusion is not simulated: a pulse can be heard through the partition.

The supplied single-door waypoint and separation steering channel bodies through the 2.2 m opening. Movement uses snapshots of the other positions, a 1.6 m/s speed cap and 5 m/s² steering limit. This is a controlled kinematic crowd, not a rigid-body crowd simulation; listeners have no player collision or damage. The wall and sphere stand have physical collision. A partition constraint keeps the listeners on the intended route. The point reuses `commons/artifacts/particle_swarm_walk/point_body.gd` without modification.

The small spheres return as heads. Glyphs (`o`, `?`, `<`) and colour show state; floor circles show resting places; gold rings mark the latest pulse. All listeners hear the same event but carry their own record and elapsed investigation time.

## Teaching role

The point from earlier lessons becomes a source of an event. A state selects a behaviour; a position can survive the movement of its source. Keep these operations distinct from a claim that the model understands a person. The foraging tutorial already teaches state; this is a game-like transfer encounter, not another primary tutorial or a replacement for the existing colony.

## Verification

`tools/probes/listening_horde_checks.gd` executes the production model, real scene, transformed host, synthetic pickup and actual action signal. `tools/probes/listening_horde_museum.gd` checks the native ABM hall and captures it from eye level and above. Physical headset controls, portal travel and Quest performance require a separate test.
