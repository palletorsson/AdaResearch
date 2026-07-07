# ForcesArena — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 20 artifacts*

> Three arenas connected by long-range jump pads — one for drone combat, one for physics destruction, and one exhibition gallery holding every vector and force artifact built so far. The player puts accumulated knowledge to use: pilot a drone with force vectors, shatter objects with momentum, then walk through a curated lineup of the concepts that made it all possible.

The map, read through what it holds — its artifacts in the order you meet them:

## hits_reset_display
![hits_reset_display](/scene-catalog/hits_reset_display.png)

Counter panel showing hits taken toward map reset — displays N / max, incrementing as the player accumulates damage from hazards.

`hits_reset_display`

## health_display
![health_display](/scene-catalog/health_display.png)

Live health readout panel wired to GameManager.health_updated — shows current hit points on a Label3D and updates every frame the value changes.

`health_display`

## Catalyst Target
![Catalyst Target](/scene-catalog/catalyst_target.png)

TRACK a target through hit, destroy, and respawn states while keeping its identity legible.

`catalyst_target`

## gravity_gun_test_scene
![gravity_gun_test_scene](/scene-catalog/gravity_gun_test_scene.png)

gravity_gun_test_scene

`gravity_gun_test_scene`

## queer_cylinder_target
![queer_cylinder_target](/scene-catalog/queer_cylinder_target.png)

queer_cylinder_target

`queer_cylinder_target`

## Catapult
![Catapult](/scene-catalog/catapult.png)

Procedural wooden catapult: A-frame base, torsion pivot, a long throwing arm with a basket at the tip and a counterweight at the short end. A console with ANGLE + FORCE sliders and a FIRE push-button sits in front. Changing a control retilts the arm and redraws a live predicted-trajectory parabola; FIRE swings the arm and launches a ball that follows the arc. Always-on velocity (green) and gravity (red) vector arrows with labels make the parabola = initial velocity + constant gravity legible.

`catapult`

## Proximity Spawner
![Proximity Spawner](/scene-catalog/proximity_spawner.png)

Spawns enemies when player enters radius. Respawns after enemy death. Configure with type, spawn_radius, despawn_radius, respawn_delay.

`proximity_spawner`

## vector_drone
![vector_drone](/scene-catalog/vector_drone.png)

desired = (target - position).normalized() * speed. Chase, prepare, shoot, cooldown. A state machine driven by vector subtraction.

`vector_drone`

## Human Catapult
![Human Catapult](/scene-catalog/human_catapult.png)

Heavy timber frame + throwing arm + a player-sized basket (StaticBody floor you stand on, low walls, harness). An Area3D (player_body layer) arms the seat when you step in; ANGLE/FORCE sliders + a FIRE button launch you. Live velocity arrow + parabola preview. DNA: launch_force, launch_angle, gravity_magnitude.

`human_catapult`

## destructibles_test_scene
![destructibles_test_scene](/scene-catalog/destructibles_test_scene.png)

impact → destroy(method). Eight destruction methods: instant, health-based, face-peel, Cantor recursion, Voronoi fracture, planar crack, prism shatter. Topology of breaking.

`destructibles_test_scene`

## VectorThrowing
![VectorThrowing](/scene-catalog/VectorThrowing.png)

p(t) = p0 + v0*t + 0.5*g*t^2. Projectile motion. Horizontal = constant velocity; vertical = constant acceleration. Your hand writes the initial conditions.

`VectorThrowing`

## throw_ball
![throw_ball](/scene-catalog/throw_ball.png)

throw_ball.

`throw_ball`

## grab_sphere_point
![grab_sphere_point](/scene-catalog/grab_sphere_point.png)

XR Tools pickable sphere with highlight ring for repositioning a reference point.

`grab_sphere_point`

## sphere_splitting_showcase
![sphere_splitting_showcase](/scene-catalog/sphere_splitting_showcase.png)

sphere → fragments(method). Five fracture algorithms: planar cut, octree division, orange-peel sectors, CSG boolean, pre-segmented mesh. One sphere, five deaths.

`sphere_splitting_showcase`

## VectorBasics
![VectorBasics](/scene-catalog/VectorBasics.png)

UNDERSTAND that a vector is not a number and not a point — it is a displacement carrying both how far and which way

`VectorBasics`

## VectorAddition
![VectorAddition](/scene-catalog/VectorAddition.png)

SEE that the ball knows only the sum of all forces, not the individual forces themselves

`VectorAddition`

## VectorSubtraction
![VectorSubtraction](/scene-catalog/VectorSubtraction.png)

VectorSubtraction

`VectorSubtraction`

## Vector Magnitude
![Vector Magnitude](/scene-catalog/vector_magnitude_demo.png)

Visualizes vector magnitude (length) using Pythagorean theorem. Shows |V| = √(x² + y² + z²).

`vector_magnitude_demo`

## Vector Normalization
![Vector Normalization](/scene-catalog/vector_normalize_demo.png)

Shows normalization: V̂ = V/|V|. Converts any vector to unit length while preserving direction.

`vector_normalize_demo`

## VectorCrossProduct
![VectorCrossProduct](/scene-catalog/VectorCrossProduct.png)

FEEL that torque is not a force but the force's opinion about rotation, measured by how far off-center and how perpendicular it acts

`VectorCrossProduct`
