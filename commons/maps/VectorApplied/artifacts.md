# VectorApplied — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 9 artifacts*

> Vectors aim turrets. Subtract the target position from the turret position and you get the direction to fire. Normalize it and you get the unit vector — pure direction without magnitude. Check the dot product against the turret's forward vector and you know if the target is in range. Every operation from the previous maps finds a job.

The map, read through what it holds — its artifacts in the order you meet them:

## Force Field Visualizer
![Force Field Visualizer](/scene-catalog/force_field_visualizer.png)

Visualize gravitational, electric, and magnetic force fields in 3D using arrow glyphs and particle tracers. Place sources and sinks to sculpt the field landscape, then release test particles to see how forces guide motion through space.

`force_field_visualizer`

## VectorForces
![VectorForces](/scene-catalog/VectorForces.png)

VectorForces

`VectorForces`

## Half-Life Turret - Vector Compendium
![Half-Life Turret - Vector Compendium](/scene-catalog/hl_turret_vectors.png)

Half-Life inspired sentry turret demonstrating ALL vector operations in one coherent system: subtraction (direction to target), magnitude (distance/range check), normalization (unit direction), dot product (FOV check), cross product (rotation axis), projection (ground plane), scalar multiplication (bullet velocity), and velocity integration (bullet physics). Fires tracer rounds with visible velocity vectors!

`hl_turret_vectors`

## Proximity Spawner
![Proximity Spawner](/scene-catalog/proximity_spawner.png)

Spawns enemies when player enters radius. Respawns after enemy death. Configure with type, spawn_radius, despawn_radius, respawn_delay.

`proximity_spawner`

## VectorFieldFlow
![VectorFieldFlow](/scene-catalog/VectorFieldFlow.png)

F(p) = swirl(p) - radial(p). A vector field assigns a direction to every point. The particle reads the field and follows.

`VectorFieldFlow`

## Weather Vector Field — Storm Chamber
![Weather Vector Field — Storm Chamber](/scene-catalog/weather_vector_field.png)

A walkable storm chamber (~5x5 m) built on vector addition — two grabbable wind vectors combine in real-time. Drag arrow endpoints to feel how wind directions sum, then watch a real GPUParticles3D storm answer the resultant: rain streaks slant at the true gravity + wind angle, wind-blown debris streaks downwind (the vector in flight), drifting cloud slabs and swaying ground mist advect on the wind, and forked lightning strikes downwind in stormy weather. A MultiMesh field of arrows plus classic instruments — a yawing windsock, a spinning 3-cup anemometer, a ground compass rose, and fading streamlines — all read the same live summed vector. Four weather modes (calm / breezy / storm / blizzard) swap density, scale, colour, drift and lightning; calm adds a sun shaft with rising motes; blizzard turns the rain to slow white snow. Pressure zones distort the field; the ground tints warm/cool with the wind's vertical sign.

`weather_vector_field`

## Basis Vectors Rig
![Basis Vectors Rig](/scene-catalog/basis_vectors_rig.png)

Interactive basis vectors (î, ĵ, k̂) showing how any 3D point is a linear combination: P = xî + yĵ + zk̂.

`basis_vectors_rig`

## VectorBasics
![VectorBasics](/scene-catalog/VectorBasics.png)

UNDERSTAND that a vector is not a number and not a point — it is a displacement carrying both how far and which way

`VectorBasics`

## Catalyst Target
![Catalyst Target](/scene-catalog/catalyst_target.png)

TRACK a target through hit, destroy, and respawn states while keeping its identity legible.

`catalyst_target`
