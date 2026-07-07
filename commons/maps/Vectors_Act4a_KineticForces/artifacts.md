# Vectors Act4a KineticForces — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 5 artifacts*

> The forces, at the size of your body. A park of moving machines where each one is a force bending a path. Push a mower by its angled handle and watch the work drain away as you raise it — only the part along the ground counts. Run through corridors of rising resistance and feel speed taxed back to nothing. Step on a pad that throws you into an arc. Ride a ring that hauls you toward a centre you never reach. Walk an orbit around a point that belongs to neither body. Work, drag, launch, turn, fall — every one a force editing motion, met on foot instead of read off a chart.

The map, read through what it holds — its artifacts in the order you meet them:

## Centrifuge Ring (walk-in centripetal)
![Centrifuge Ring (walk-in centripetal)](/scene-catalog/centrifuge_ring.png)

The body-scale, walk-in twin of circle_train: a pod laps a big neon ring while the velocity (tangent) and centripetal force (inward, ∝ v²/r) ride it at your own scale. Velocity is always tangent, the force always toward the centre you never reach; crank the speed and the inward arrow explodes as the square. a = v²/r made into a ridden loop you stand inside.

`centrifuge_ring`

## Orbit Walk (walk-in two-body)
![Orbit Walk (walk-in two-body)](/scene-catalog/orbit_walk.png)

The body-scale, walk-in twin of orbit_pair: stand at the barycenter while a heavy star and a lighter planet wheel around you on opposite sides, the equal-and-opposite gravity vectors (F = G m1 m2 / r squared) riding each body. Make one heavier and the barycenter slides toward it, the orbits resizing to keep the balance. An orbit is two things falling toward each other and missing, around a centre that belongs to neither.

`orbit_walk`

## Force Pad
![Force Pad](/scene-catalog/force_pad.png)

1x1 m glowing launch pad. An Area3D on the player_body layer fires on contact, setting the player CharacterBody3D's velocity to forward+up. Pulsing surface, forward chevrons, live launch-vector arrow. DNA: forward_force (6), up_force (7), cooldown_time.

`force_pad`

## Force Mower (W = F d cos θ)
![Force Mower (W = F d cos θ)](/scene-catalog/force_mower.png)

The lawn-mower work diagram turned into a thing you push - an embodied force-display prop for the vectors-forces arc. Push the mower by its angled handle; the push F splits into the part that does work (F cos θ, along the ground) and the part wasted into the dirt (F sin θ, downward). The force vectors live on the object: F down the handle, the horizontal F cos θ, the green dashed vertical decomposition, the long purple displacement d, and a W = F d cos θ readout. DNA: push_angle 0..1 raises the handle angle θ so cos θ - the share of work - shrinks (steeper push, less work done).

`force_mower`

## Drag Corridor (walk-in air/water/honey)
![Drag Corridor (walk-in air/water/honey)](/scene-catalog/drag_corridor.png)

The body-scale, walk-in twin of drag_lane: a corridor of three media (air, water, honey) you walk through, your own pace damped more in each denser section. A probe in each zone glides and dies under F = -b*v, its velocity arrow shrinking as it bunches up — the same launch goes far in air, less in water, barely a lunge in honey. Drag is the world charging you rent on speed.

`drag_corridor`
