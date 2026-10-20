# What carries you over the water?

The bridge takes you across an eleven-metre square of water. Glass under your feet; a moving surface below. On either side, the bathhouse opens between columns and chairs. A sphere and cube wait near the entrance. They stay rigid while the water changes.[^basin]

<!-- @basin_water -->

Hold the water with TIME. The button stops its changing phase. COLOUR leaves a field on a flat plane. NORMAL makes that plane answer light as though it had slopes. HEIGHT gives those slopes an outline. Look across the surface from the bank: now the edge itself rises and falls. Three readings of one field, and the glass carries you through all three.

In Materials, the circle seemed to stand out from a square that remained flat. Here the vertices really move in the rendered image. The distinction matters, but it does not settle what the water can do. A moved vertex is still no promise of resistance. Your feet encounter another construction.

The smaller study beside the basin puts that difference within reach. Carry the point upward; the apparent height increases. Move it sideways; another part of the field comes into view. Let go. The surface keeps this reading because the input stays where you left it. The cube beside it does not bob. Neither does the narrow glass support above it.

At the large console, take SCALES down to one. Broad changes cross the water. Add another scale: smaller changes enter at half the weight. Add two more. The rule keeps dividing its attention between larger and smaller differences, but divides the total by the weights it has used. Detail can increase without increasing the permitted height.[^bound] Four scales give a particular surface. They do not give four times as much sea.

Walk onto the bridge and look down. Light and viewing angle help this field read as water. A pale response gathers where the surface turns away from the eye; the height changes the directions that can meet you. Some of that pallor is emission, a brightness added by the material itself. There is no reflected room hidden beneath it, no current waiting to carry the sphere away. The word water gathers expectations that this construction answers only in part.

Start TIME. The sampling position travels around a circle; the field returns when that journey completes. Stop it partway. Nothing settles. There is no remaining momentum, no wave arriving from somewhere else. The processor retains a phase; the shader reads it and computes a surface. It has no record of the previous water.[^phase]

The controls let you intervene in that reading. They do not let you make a splash. This is a useful limit to meet with the body: movement can be present without consequence passing from one part of the water to another. The later state-based hall will ask for the previous field as part of the next calculation. Here, repeating the inputs is enough.

So, what carries you. The glass does. It is a narrow, fixed bridge with a collider, not a lid over the entire pool. The water has none. Its highest permitted crest remains below the bridge; beside the bridge, the basin floor lies lower still.[^support] What you look at and what holds you up are two constructions. The difference becomes practical as soon as you place a foot.

<!-- @shader_09_fbm -->

Beyond the pool stand four squares with their own controls. On the first desk: SCALE, OCTAVES, GAIN, LACUNARITY. One octave gives a field. Another adds finer variation. LACUNARITY changes the ratio between their spacings; GAIN changes how much the smaller scales contribute. Unlike the bounded pool, this graph keeps the raw weighted sum. Its brightness need not stay in the same range as you change the recipe.

The name on the desk is fractional Brownian motion. In this graphics example it names a finite sum of noise at different scales. That construction can resemble terrain without knowing a stone, a slope's weight or the time it took to wear down.

The second square folds the signed field toward ridges. The third removes its sign and drifts. The fourth uses sampled values to displace the coordinates of further samples. Look at it for a while. Marble, smoke, something geological. Each resemblance invites a history. The computation performs its nested readings inside the present frame; it does not inherit the last frame's result. Complexity within a calculation and consequence across calculations are different capacities.

<!-- @dark_sphere -->

The dark sphere pulses from a number it keeps. The pool also has a number kept for it now: a phase that you can hold and resume. The older graph rack still reads the engine's wrapping clock. There is no single clock for everything in this room, and no single meaning of remembering. A counter, a held input and an evolving field preserve different things.

<!-- @ -->

Next, a room that is all surface. Take the glass with you: the thing you walked on was not the thing you looked at.

[^basin]: The current hall is 26 × 29 cells. Its open basin occupies an 11 × 11 rectangle, 1.2 m deep. `BasinWater` opts into `water_study.gd`, which positions the mean surface at −0.40 m and installs the separate bridge, controls and colonnade. The earlier seven-by-three sine pool remains a different configuration; its figures and measurements do not describe this study.

[^bound]: The study uses one to four signed value-noise samples with successively halved positive weights, normalized by their sum. The result lies in [−1, 1]. Relief is limited to 0.25 m, placing the rendered water within −0.65…−0.15 m before numerical rounding. Normal directions are estimated at vertices and interpolated across triangles. This is a finite procedural surface, not a fluid simulation.

[^phase]: The pool's TIME control advances a CPU-owned phase at 0.24 radians per second and wraps it at one turn. The circular lookup repeats in about 26.18 seconds; floating-point computation gives an approximate numerical return. The shader does not read TIME. The learner study instead ties phase directly to the held point's local X. Both compute a field from current inputs without storing an evolving water state.

[^support]: The installed glass bridge is 1.8 m wide and 6 cm thick, with its top at deck height. Its underside is −0.06 m; the water's highest permitted crest, −0.15 m, leaves 9 cm clearance. The glass owns collision; the water does not. In the small learner tray, the corresponding clearance is 6 cm. Neither normal mapping nor vertex displacement updates those colliders.
