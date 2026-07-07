# VFM 04 Fields — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 11 artifacts*

> Stand inside the field.

The map, read through what it holds — its artifacts in the order you meet them:

## Magnetic Field Simulation
![Magnetic Field Simulation](/scene-catalog/magnetic_simulation.png)

Magnetic field simulation with dipoles, field line visualization, and Lorentz force on charged particles. Watch iron filings align along field lines, see how bar magnets attract and repel, and observe charged particles spiraling in helical paths through uniform fields. Maxwell's equations made tangible through interactive electromagnetic landscapes.

`magnetic_simulation`

## Weather Vector Field — Storm Chamber
![Weather Vector Field — Storm Chamber](/scene-catalog/weather_vector_field.png)

A walkable storm chamber (~5x5 m) built on vector addition — two grabbable wind vectors combine in real-time. Drag arrow endpoints to feel how wind directions sum, then watch a real GPUParticles3D storm answer the resultant: rain streaks slant at the true gravity + wind angle, wind-blown debris streaks downwind (the vector in flight), drifting cloud slabs and swaying ground mist advect on the wind, and forked lightning strikes downwind in stormy weather. A MultiMesh field of arrows plus classic instruments — a yawing windsock, a spinning 3-cup anemometer, a ground compass rose, and fading streamlines — all read the same live summed vector. Four weather modes (calm / breezy / storm / blizzard) swap density, scale, colour, drift and lightning; calm adds a sun shaft with rising motes; blizzard turns the rain to slow white snow. Pressure zones distort the field; the ground tints warm/cool with the wind's vertical sign.

`weather_vector_field`

## Force Vortex
![Force Vortex](/scene-catalog/force_vortex.png)

Rotating whirlpool force field. An Area3D (cylinder, player_body layer) captures the player; each physics frame the field overwrites their velocity with inward pull + tangential spin + gentle lift, spiralling them toward the core; crossing eject_radius throws them outward + up, then a cooldown. Rotating spiral arms + glowing core + boundary ring. DNA: field_radius (3.5), pull/spin/lift, eject_force/up.

`force_vortex`

## vector_field
![vector_field](/scene-catalog/vector_field.png)

vector_field

`vector_field`

## Force Fields
![Force Fields](/scene-catalog/force_fields.png)

FEEL that a force field is a region with different rules — cross the boundary and the laws change

`force_fields`

## VectorFieldFlow
![VectorFieldFlow](/scene-catalog/VectorFieldFlow.png)

F(p) = swirl(p) - radial(p). A vector field assigns a direction to every point. The particle reads the field and follows.

`VectorFieldFlow`

## Force Field Visualizer
![Force Field Visualizer](/scene-catalog/force_field_visualizer.png)

Visualize gravitational, electric, and magnetic force fields in 3D using arrow glyphs and particle tracers. Place sources and sinks to sculpt the field landscape, then release test particles to see how forces guide motion through space.

`force_field_visualizer`

## Flow Field Painter
![Flow Field Painter](/scene-catalog/flow_field_painter.png)

Paint with vector fields — particles follow the flow you create, tracing streamlines that reveal the hidden topology of your brushstrokes. Combines art and physics as your gestures define the force landscape that particles navigate.

`flow_field_painter`

## 1.0.2 Interactive Point — Force Catalyst
![1.0.2 Interactive Point — Force Catalyst](/scene-catalog/interactive_point_origin_force.png)

Force-catalyst variant of interactive_point_origin. Starts as a plain point; on pickup a vertex shader morphs the surface into a pulsing 'force field' shell. While held with the morph engaged, nearby RigidBody3D objects feel an inverse-square pull toward the artifact. With both hands closed (the OrbGestureDetector two-hand gesture), the artifact spits a luminous projectile ball forward.

`interactive_point_origin_force`

## Vector Field Visualizer
![Vector Field Visualizer](/scene-catalog/vector_field_visualizer.png)

3D arrow field showing flow — vortex, source, sink, or dipole fields. An 8x8x4 grid of arrow glyphs colored by magnitude (blue=slow, red=fast). Each arrow drawn with ImmediateMesh lines for shaft and arrowhead.

`vector_field_visualizer`

## Flow Field Following
![Flow Field Following](/scene-catalog/noc_5_04_flow_field.png)

Agents navigate by following a vector flow field.

`noc_5_04_flow_field`
