# Vectors Act3 FieldsAndMotion — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 5 artifacts*

> Two rooms, two ways a vector stops holding still. First the field: a flow console, then a storm chamber you walk into where an arrow waits at every point and the wind decides where you drift. Then motion: a projectile's arc rising and falling, a bubble gun whose launch velocity you can watch, and a velocity pulled apart into the part that carries you forward and the part that fights gravity. A field is force that has decided to be everywhere at once; motion is a vector the world keeps editing. Both refuse to sit still on a page.

The map, read through what it holds — its artifacts in the order you meet them:

## VectorFieldFlow
![VectorFieldFlow](/scene-catalog/VectorFieldFlow.png)

F(p) = swirl(p) - radial(p). A vector field assigns a direction to every point. The particle reads the field and follows.

`VectorFieldFlow`

## Weather Vector Field — Storm Chamber
![Weather Vector Field — Storm Chamber](/scene-catalog/weather_vector_field.png)

A walkable storm chamber (~5x5 m) built on vector addition — two grabbable wind vectors combine in real-time. Drag arrow endpoints to feel how wind directions sum, then watch a real GPUParticles3D storm answer the resultant: rain streaks slant at the true gravity + wind angle, wind-blown debris streaks downwind (the vector in flight), drifting cloud slabs and swaying ground mist advect on the wind, and forked lightning strikes downwind in stormy weather. A MultiMesh field of arrows plus classic instruments — a yawing windsock, a spinning 3-cup anemometer, a ground compass rose, and fading streamlines — all read the same live summed vector. Four weather modes (calm / breezy / storm / blizzard) swap density, scale, colour, drift and lightning; calm adds a sun shaft with rising motes; blizzard turns the rain to slow white snow. Pressure zones distort the field; the ground tints warm/cool with the wind's vertical sign.

`weather_vector_field`

## Launch Arc (projectile motion)
![Launch Arc (projectile motion)](/scene-catalog/launch_arc.png)

Projectile motion made playable - the launch / F=ma toy for the embodied vectors-forces arc (the pad that throws you). A launch pad fires at angle theta with speed v; gravity bends the straight launch vector into a parabola. The launch velocity decomposes into a horizontal vx (carries you) and a vertical vy (fights gravity); the trade between them sets the range = v^2 sin(2theta)/g - which peaks at 45 degrees. Shows the tilted glowing pad, the stroboscopic projectile arc, the launch vector + its vx/vy components, and apex / range markers. DNA: angle 0..1 sets the launch angle (flat to steep), power 0..1 the launch speed; color_a pad + components, color_b the arc + launch vector, accent pad glow + apex/range.

`launch_arc`

## Bubble Blaster (output velocity vector)
![Bubble Blaster (output velocity vector)](/scene-catalog/bubble_blaster.png)

A soap-bubble gun that fires a spreading cone of bubbles and wears its launch vector on the muzzle - an embodied force-display prop. Pull the trigger and bubbles pour out; the muzzle shows an arrow for the output velocity and a faint cone for the spread. Crank the output and the arrow stretches, the cone widens, the bubbles fly faster and further. Every emitter is a little vector field - each particle leaves with a velocity, and the spray's force is just that launch vector made of many departures. DNA: output 0..1 dials the launch (vector length, spread angle, bubble speed/count); seed jitters the bubbles.

`bubble_blaster`

## VectorMotion
![VectorMotion](/scene-catalog/VectorMotion.png)

VectorMotion

`VectorMotion`
