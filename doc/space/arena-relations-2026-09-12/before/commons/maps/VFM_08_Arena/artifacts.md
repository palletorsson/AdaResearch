# VFM 08 Arena — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 7 artifacts*

> Vectors you play against.

The map, read through what it holds — its artifacts in the order you meet them:

## Turret Targeting (Combined)
![Turret Targeting (Combined)](/scene-catalog/turret_targeting.png)

Combined turret + ball dropper setup. Laser turret tracks and destroys falling balls. Use laser_turret and ball_dropper separately for custom arrangements.

`turret_targeting`

## Reflection Hall
![Reflection Hall](/scene-catalog/reflection_hall.png)

Six StaticBody3D walls (floor, ceiling, +X, -X, +Z) enclose a 5x5x3 m room; the -Z wall is two side panels + a lintel leaving a 1.2x2.2 m entrance you walk through. An invisible doorway curtain on the ball-only collision layer keeps thrown balls inside while letting the player pass. Balls are RigidBody3D with a bouncy physics material (engine bounces; we visualise). Each ball caches its pre-contact velocity every physics frame; on wall contact it recovers the incident d, looks up the wall's inward normal n̂, computes r = d - 2(d.n̂)n̂, and spawns a ~1.5 s fading d/n̂/r arrow cluster + live formula at the hit point, verifying r against the post-bounce velocity. Fading per-ball trails via ImmediateMesh line strips. A grab-throw ball rack (primary VR) plus an optional ANGLE/FORCE/FIRE console; on desktop/headless the console auto-fires every ~3 s so captures show live bounces. DNA: ball_bounce, gravity_scale, launch_speed, room dimensions.

`reflection_hall`

## queer_cylinder_target
![queer_cylinder_target](/scene-catalog/queer_cylinder_target.png)

queer_cylinder_target

`queer_cylinder_target`

## Vector Arena
![Vector Arena](/scene-catalog/vector_arena.png)

Two-handed vector playground: LEFT trigger places point A at the left hand, RIGHT trigger places point B at the right hand, and a live green arrow A->B carries its own billboarded readout (AB = B - A, |AB|, dir). RIGHT grip charges the arrow; RIGHT trigger while charged fires a RigidBody3D ball from A with velocity = AB * force_gain, leaving a faded ghost of the intended vector for intent-vs-result comparison. A labeled wall shows its unit normal n-hat as an arrow; fired balls reflect off it by the formula r = d - 2(d.n)n (not engine bounce), flashing a panel with the full arithmetic and the |r| = |d| check. Degrades gracefully on desktop/headless to two orbiting demo points with periodic auto-fire.

`vector_arena`

## Collision Carts (momentum exchange)
![Collision Carts (momentum exchange)](/scene-catalog/collision_carts.png)

Rigid-body collision made playable - a heavy cart meets a light one and momentum before equals momentum after, but the velocities split by mass. Shows the before and after lanes with carts sized by mass and their velocity vectors. The console rebuild of the rigid-body sim. mass_ratio 0..1 from a light striker to a heavy one.

`collision_carts`

## Momentum Cradle (p = mv conserved)
![Momentum Cradle (p = mv conserved)](/scene-catalog/momentum_cradle.png)

Momentum conservation made playable - Newton's cradle, rebuilt as a console. Lift an end ball and the blow travels through the still middle balls untouched and kicks the far ball out to the same height: one in, one out, p = mv conserved. lift 0..1 sets the swing amplitude.

`momentum_cradle`

## Sentry Turret
![Sentry Turret](/scene-catalog/sentry_turret.png)

Half-Life style sentry turret. Targets balls and/or player. Simple reliable targeting with bullet physics. Emits signals for hits.

`sentry_turret`
