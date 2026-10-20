# Shaders — complete reflective sequence

Read alongside the museum and the tutorial. This track includes the wider collection; it is not an additional list of programs to build.


---

# Why does the wave jump?

A pale circle holds its place on the dark wall. A smaller one sits on the cube in front of it. Move RADIUS and both expand. Press EDGE and both soften. They share a rule, but they do not occupy the same amount of the room.

<!-- @shader_shaping_wall -->

The soft edge offers an interval where the hard edge offered a cut. That difference matters to what you see. It grants no passage through either backing. A boundary can become gentle in its appearance while remaining just as firm to the body.

Across the room, five dark squares hang in a row, each with a desk in front of it. One is already moving with nobody at its desk. Begin with one that holds still.

<!-- @shader_01_shaping -->

The first square is a graph: a faint grid every quarter, one white line. Its desk carries a single slider, THRESHOLD, and one line of text. Leave the text for now.

Drag the slider to the right. The white line runs along the bottom of the square, climbs in one vertical stroke, and runs along the top. The stroke follows your hand. Watch both halves of the line while it moves. Neither arrives first. The right-hand part of the square is a shade lighter than the left, and that band moves as one piece with the stroke.

Try to catch it in between. Drag fast, then slowly. There is no in-between. At each position of the slider the whole square is one picture; at the next position it is another whole picture. Nothing travelled from the old stroke to the new one, because there was no old stroke for anything to travel from.

That is the hall's first fact, and the sequence's. The square is not a thing that gets changed. It is a rule, and the rule is asked, for every pixel of the square, on every frame the museum draws: given this pixel's position and this number, what colour? The pixel just left of the stroke has never heard of the pixel just right of it. They are evaluated by the same rule at different positions; neither waits for a message from its neighbour.

The desk names it STEP. Below the threshold its answer is zero; at or above the threshold it is one. The lighter band and the white stroke show that answer in different ways. Yet the stroke has a width, and its own edges fade.

The picture of a discontinuity is made with a continuous function. Each pixel measures its distance to where the line should be and fades over a line's width; without that, a line one pixel wide would flicker as you moved your head. The step is the subject and smoothstep is the pen. You meet the pen on its own at the next desk.

The second square has two sliders, EDGE 0 and EDGE 1, and two orange marks on the graph where they stand. Between the marks the white line eases from the bottom to the top in an S; outside them it is flat. Push the marks apart and the S stretches. Push them together and it steepens toward the stroke you saw at the first desk.

Now push EDGE 0 past EDGE 1. The function is defined as a division by the distance between its two edges, and the language this panel is written in promises nothing about what happens when that distance turns negative.[^f1-smoothstep] Whatever the square shows you now is not something the rule promised. You have walked to the edge of what it defines, and it was two slider-widths away.

The third square is the one that moves. FREQUENCY, AMPLITUDE, PHASE SPEED. A wave runs across it, and it ran before you arrived. Move AMPLITUDE: the wave grows or shrinks in place. Move FREQUENCY: the wave jumps. Not faster, not slower; it is suddenly somewhere else, and then runs on as before.

Now the slider the chapter is named for. Move PHASE SPEED by one notch. The wave leaps sideways and continues. The amount depends on when you moved the slider. Move it back a notch: another leap, and not the reverse of the first. Then take your hands off the desk and watch for half a minute. The wave leaps on its own.

The wave's position is TIME multiplied by the speed. TIME is the museum's clock. The panel keeps no position of its own from one frame to the next; it asks the clock and multiplies. When you change the speed, every frame after that multiplies the whole clock by the new number, so the phase moves by the change in speed times however long the clock has been running. One notch of the slider is a tenth, and fifteen seconds into the clock's run that is a quarter of a wavelength, at once.[^f1-leap] A wave that kept its own position could accelerate. This one cannot. It can only be asked again.

And the leap with nobody at the desk: this museum's clock wraps. It runs for thirty seconds and drops back to zero.[^f1-rollover] At the default speed that drop moves the phase by thirty radians, four and three-quarter cycles, so the wave you are watching skips about a quarter of a wavelength twice a minute. Some of the moving surfaces in the halls ahead do the same at that moment. Some were written, by accident or on purpose, so that they do not. Watch for it.

The fourth square, EXPONENT, draws one curve from the bottom left corner to the top right. At one it is a straight line. Below one it bulges upward; above one it sags. Nothing here moves and nothing jumps: the exponent bends the same line in place. A curve is a decision about where the value collects, near zero or near one, and this desk lets you make it with one number.

The fifth square draws all four on one graph, a red step, a cyan S, a green wave and an orange curve, and a white line that blends them. The green one keeps moving among the three that hold still. That is the whole hall in one square: four rules for turning a position into a value, and one clock.

<!-- @dark_sphere -->

The dark sphere pulses beside the desks. Its pulse is driven from the other side of the museum's machinery, by a script that runs once a frame on the processor and remembers where it was.[^f1-sphere] Stand between it and the wave. One of them has a past.

You came from halls where noise was made and then kept: a column of values, a voxel field, a wall. These materials retain their parameters, but neither the new circle nor the graphs receives its previous image. Each is asked again from coordinates and current inputs. The moving graph also asks the clock.

The circle on the cube already crosses from picture to body. For now it occupies a flat receiver on one face; it does not reshape the cube. In the rooms ahead the surface will repeat, take light differently, and move. Each change asks us to locate what changed.

<!-- @ -->

The way out is a long one. The museum builds a crossing after every hall, a door, a run of open floor, and a second door offset to one side, and this hall has asked for its crossing to be fourteen rows deep instead of the usual seven.[^f1-passage] Walk it slowly. The museum keeps only a hall or two built at any time; the rest is a plan on disk, and the crossing's corner is where the swap is hidden. A rule with no memory on the square, and a building that keeps two rooms around you. Take the wave's jump with you.

[^f1-smoothstep]: The desk's line is `float y = smoothstep(e0, e1, x);`. The GLSL specification defines it as a clamped division by `e1 - e0` followed by a cubic, and states that the result is undefined when the first edge is not less than the second. What a particular graphics driver draws in that case is its own business.

[^f1-leap]: The panel is `shaping_sin.gdshader`; the slider steps by 0.1. The phase is `TIME * phase_speed`, so a step of 0.1 taken t seconds into the clock's run moves the phase by 0.1 t radians: 0.08 of a wavelength at five seconds, 0.24 at fifteen, 0.46 at twenty-nine. Nothing about the leap is random. It is the clock's reading at the moment you moved.

[^f1-rollover]: `project.godot` sets `rendering/limits/time/time_rollover_secs` to 30, so the shader clock TIME runs from 0 to 30 and wraps; Godot's own default is 3600. At phase speed 1.0 the wrap moves the phase by 30 radians, 4.77 cycles, a leap of 0.23 of a wavelength; at 2.0 it is 0.45, at 0.5 it is 0.39. Only a speed whose product with 30 is a whole number of cycles would hide it, and the slider's steps do not land on one.

[^f1-sphere]: `dark_sphere.gd` drives its wobble and its emission pulse from `_process`, on the CPU, frame after frame, from values it keeps. The graphs retain their control values but no previous image; the animated graph also reads TIME.

[^f1-passage]: `map_info.museum.passage` on this map is `{"kind": "chicane", "depth": 14}`. The museum's crossing rule (`endless_museum.gd`, `_authored_passages`): a door in this hall's last row, `depth` rows of crossing, a door where the next hall's own door is, then the next hall's first row copied, so that walking the last metre of the crossing you are already looking into the room you are entering. The default depth with a known next hall is 7. A chicane's middle rows open the whole span between the two doors, so when the doors sit at opposite corners the crossing is a room rather than a corridor. Palle, on first seeing one: "like a service corridor that can lead to other places."


---

# Where are the seams?

The circle has left its frame. It crosses the floor, a cube, a column and a chair. Slide the pattern and watch the chair's outline: something moves without carrying the chair with it. Move the chair instead. With the pattern held in the room, another part of it falls across the seat. Attach it to the chair and the marks travel with their support.

You have met tilings before, including the loom's crossing threads and the cloth that can be opened into layers. There, a pattern depended on how parts met. Here the repeated mark needs no new thread or tile. That difference becomes visible when the image can pass across a chair without moving it.

The smaller rack along the wall keeps four dark squares in its first mode, each with a desk, and MODE and RESET at the left. Go to the first square.

<!-- @shader_05_patterns -->

A grid of shapes, five across and five down, each a little brighter or darker than its neighbours. The desk: GRID SIZE, SHAPE SIZE, ANIMATE. Take GRID SIZE down to one. One shape, filling the square. Now up, one notch at a time. Two across, then three, then twenty. The shapes get smaller, and the seams between them, the lines where one ends and the next begins, arrive with them.

There is a faint border drawn around each cell.[^f2-border] But the border marks a division that already exists in the coordinates. Each sample multiplies its address by the grid size and keeps the fractional part. An address at 3.7 becomes 0.7, and so does one at 12.7. The same local position can now occur in many cells.

The seam is where that local coordinate begins again. It need not become a visible line. In the large circle installation, both sides of a cell boundary read the same background. In this smaller square, an extra border makes the division legible. We can draw attention to a boundary, or leave it unmarked, without changing where it falls.

The tiles are not quite identical, though. Each is tinted by a number made from the whole part before it was discarded, so the fold shows as a step in brightness.[^f2-tint] Press ANIMATE and every shape breathes on its own phase, again from its whole part and the clock. One rule, twenty-five tiles, no two in step.

The second square is a labyrinth of arcs, and here the chapter's question has no answer you can point to. Look for a seam. Every arc crosses from one tile to the next without a kink. GRID and THICKNESS are on the desk, and SEED; move SEED and the whole labyrinth is another labyrinth, all at once, with the same property.

Each tile flips a coin from its address and, on heads, mirrors its own coordinate. Then it draws two quarter-circles from two opposite corners, each of radius one half. A quarter-circle of radius one half from a corner meets the tile's edges exactly at their midpoints, and so does its neighbour's, whichever way the neighbour flipped. The seams are still there, at every whole number. They are invisible because the rule was chosen so that both sides always agree at the midpoint. The word is Truchet; what it names is that agreement.

The third and fourth squares, OFFSET ROWS and BRICK, put the seam back and make it the subject. A brick wall is nothing but its joins. Every second row is slid half a tile before the fold, and the pattern you know from every wall outside this building appears.

Now press MODE. The four squares are replaced by three. The first is Wang tiles, and its desk claims something: an edge-matched tiling, with a slider called APERIODIC. Each tile's four edges are coloured, red, cyan, gold or green, from a number made of the tile's address and the edge. Take APERIODIC down to zero and look at any seam. The colour on this side and the colour on that side were chosen separately, and mostly differ. Now bring APERIODIC up to one. The seams agree.

They agree because each side paints its edge as the average of its own colour and the neighbour's, and the average of two things is the same from either side. No tile was chosen to fit its neighbour. The seam was painted to look as if one had. The desk's word, Wang, names a tiling whose tiles are picked so that their edges match; what this square does is the reverse, and the slider is the distance between the claim and the paint.[^f2-wang]

The two Voronoi squares divide their images by proximity. Each pixel asks which of a scatter of points is nearest and colours itself by that, or by the difference between the nearest and the second nearest, which is zero exactly on the borders, so that the second of them is a picture of nothing but seams. The points still live in folded cells, one per cell, jittered. The seams you see are not those cells' edges but the borders the points make between themselves.

Press MODE again. Noise synthesis: a layered simplex field, a cellular distance field, a warped lookup. Their visible boundaries no longer follow the same repeated square. In the first, weighted contributions from a triangular lattice meet smoothly. In the second, the nearest point can change as you cross an edge. The third bends the coordinates before reading them. A surface can look continuous without those three operations being the same.[^f2-smooth]

So the pattern returned. Its repetitions did not require separate pieces of floor. In the tiled studies, whole-number boundaries divide the coordinates. Some are shown, as the tile's border and the brick's mortar. Some are agreed away, as Truchet's midpoints. Some are painted over, as Wang's averages. Some disappear into smooth contributions; others emerge when a different point becomes nearest. These seams are not joins between separately placed tiles. They belong to the way a rule reads a surface. The surface still has geometry; its repeated marks need not have separate bodies.

<!-- @dark_sphere -->

The dark sphere stands in front of the squares. No painted seam announces itself on its surface. Being one mesh would not guarantee that: its texture coordinates can still contain a join. A body's divisions and an image's divisions need not coincide.

<!-- @ -->

<!-- study-spine:reference_pattern_garden -->

<!-- @reference_pattern_garden -->

The pattern leaves the flat sample and crosses a flower. Turn its phase: a band moves over the petal while the petal stays still. Further back it crosses the room itself.

Claudia Hart's supplied image makes ornament difficult to dismiss as a finishing layer. In this response, the shared pattern can compete with the outline that would ordinarily tell us where one thing ends. Keep watching one edge through the change. Does the surface make the object more available, or make its boundary harder to trust?

<!-- @ -->

<!-- uncertainty:p4-record -->

At the camera instrument, keep one small image. Its colours rise into a field of columns. Turn to the signed reading and part of that field hangs below its own zero. The saved picture beside it has not changed. Two neighbouring values, 127 and 128, have crossed a boundary in the reading: what counted as a little more now becomes the most negative value it can hold.

There is a pleasure in watching the form open like this, and a temptation to call it a failure. But the instrument has followed the interpretation we gave it. Its discontinuity makes that choice visible. When the next setting asks the same record to fit a smaller layout, the receiver refuses; the picture remains. What has become impossible belongs to this agreement between a record and a reader. It has not made the record disappear.

<!-- uncertainty:p4-record:end -->

Press RESET if you have lost the defaults. The next hall furnishes another room with familiar bodies under different surface responses. The pictures have already reached the chair. Next, light will make another claim about what that chair might be made of. Take the painted seam with you, the one that agreed only because both sides averaged.

[^f2-tint]: `patterns_tile.gdshader`: `tile_color = shape_color * (0.7 + 0.3 * fract(sin(dot(tile_id, vec2(12.9898, 78.233))) * 43758.5453))`, where `tile_id = floor(uv)` is the whole part the fold discarded. The animation is `1.0 + animate * 0.3 * sin(TIME + tile_id.x * 1.3 + tile_id.y * 0.7)`, and it leaps at the clock's wrap like the first hall's wave.

[^f2-wang]: `patterns_wang.gdshader`. `edge_type(tile_id, edge)` hashes the tile's address with the edge's index, so a tile's north edge and its northern neighbour's south edge are independent draws. At `aperiodic_mix` = 1 the mix weight is 0.5 and both sides of every seam show the same average; at 0 each shows its own draw. The desk's default is 1.

[^f2-smooth]: This rack uses `patterns_noise.gdshader`, not the basin's `fbm_basic.gdshader`. Its three modes use `simplex2d`, `worley`, and a domain-warped simplex lookup respectively. A square-lattice value-noise helper is also present but unused by these modes; its interpolation must not stand in for their different calculations. The separate Voronoi study searches nearby cell points for its two distances.
[^f2-border]: `patterns_tile.gdshader` adds a narrow, low-intensity band near each cell edge. Its tile tint and optional animation are separate operations. The larger passage's `repeated_mask.gdshader` has no added cell border.


---

# What does a surface answer to?

The room offers a sofa, a chair, a vase, a sphere and a cube. One recipe covers them all. Choose STUDY; turn ROUGH; walk around the bodies. The highlight spreads or tightens, but the sofa does not soften beneath that name. The same material has different things to say on a curved surface and a flat face.

In the tutorial study, the circle acquires apparent relief. Change from the flat reading to the height map, then to the normal map. The lamp finds slopes where the mesh has none. Look along the square's edge: it has not lifted. The hand and the eye receive different accounts of the same body. Neither account needs to be mistaken; they are being answered by different parts of the construction.

Beside this furnished room, eight piers retain a lane for the earlier collection.[^f3-piers] Five bodies stand on low round stages, turning under three coloured lamps, with a name at each foot and pink text above.[^f3-stage] Leave the controls and walk around them.

<!-- @shader_11_queerrubber -->

Go to the ring first, the black one with a rainbow at its edge. Walk a quarter of the way round it. The rainbow comes with you. It stays at the ring's rim, the part of the surface that turns away from you at a grazing angle, wherever you stand. The pink reflection also changes as you move, but it depends on the lamp as well as the eye. It cannot follow the whole rim in the same way.

Two answers, then, on one surface. One is an answer to the lamp: where its light lands, and where the reflection would reach an eye. The other is an answer to you: how steeply the surface turns away from where you are. The ring compares its surface direction with the direction toward the eye.

NORMAL is which way the surface faces; VIEW is which way you are. Their dot product is large where the surface faces you and small where it turns away, and the rainbow is put where it is small. The rainbow is written into emission: light the surface claims to make, not light it receives. Turn every lamp in the hall off and the rim would still glow.[^f3-emission]

Now the two spheres. The dark one and the pink one both turn, one with the clock and one against it.[^f3-spin] Watch the dark one, LEATHER: a grain crawls across it, folds pass, and you can see it turning. Watch the pink one, POP PLASTIC, for as long as you like. Nothing on it moves. It is turning at very nearly the same rate.

The dark sphere's skin is drawn from a coordinate painted onto it, so when the sphere turns the skin turns with it. The pink sphere's skin is drawn from NdotV alone, the angle between its surface and your eye, and from nothing painted on. A sphere turned by any amount presents the same angles to the same eye. It answers to you and to the lamps, and not at all to where it has got to in its own rotation. Its cyan edge concentrates the same response near the rim.

The capsule is fur, or says it is. Its code explains its sheen as light grazing the fibres. Read what it computes: the same NdotV, the same rim, roughened with a noise from its painted coordinate, and again written to EMISSION and added to the colour. The eye grazes the fibres, not the light. It is a velvet that glows at its own edges for whoever is looking, and because its grain is painted on, this one you can see turn.

The last body is a cube of a metal the header calls sad, with streaks that were meant to run down it like tears. The streaks are read from a texture that this hall never hands it.[^f3-white] What you see is the alloy without its tears. And a cube cannot hide its turning the way the pink sphere does. It has corners, and they sweep past you; a cube turned by a few degrees presents new angles to the same eye, and its faces take the lamps one at a time. The rule is the same on both bodies. The shape decides what the rule can show.

Now the old collection's three lamps. Pink on the left, blue on the right, purple above and behind, each with a reach of ten metres and none of them casting a shadow.[^f3-lamps] Put your hand between the pink lamp and the leather. Nothing on the leather changes. Stand between the lamp and the ring: still nothing. Those three lamps light the surfaces they reach without consulting shadow occlusion, which is not how a lamp behaves and is exactly how a rule behaves. The surface asks each lamp where it is, what colour it is and how far away. It does not ask whether anything stands in between.

So, what a surface answers to. To those three lamps: their direction, colour and distance, without their shadows. To you: the angle at which it turns from your eye, which is why the rims and the rainbow follow you round the room. To the clock: these five specimens turn, and the ring's rainbow drifts, a tenth of a cycle a second.[^f3-drift] To its own painted coordinate, if it has one. Not to the other four objects, which it cannot see. Not to its own past, of which it keeps none.

None of the five materials carries a body of its own. The spheres, the ring, the capsule and the cube are shapes this hall lent them, on the map's instruction, and the map could lend them others.

<!-- @dark_sphere -->

The dark sphere near the centre pulses on its own clock, kept on the processor. Stand where you can see it and the pink sphere together. One is turning and shows it; one is turning and cannot show it; one is pulsing from a number it remembers.

The columns stand through all this, and the coloured light lands on them too. Their placement stays fixed; their appearance still answers to the light. Staying in place is not the same as remaining unaffected.

<!-- @ -->

The next hall has water in it. Take the apparent relief with you. There, the surface will also move its vertices. What the eye calls a rise will need another account, and what supports your feet will remain another question.

[^f3-piers]: The current map is 34 × 18 cells, with the eight piers retained from the earlier colonnade and a furnished side bay. The old 14 × 14 description belongs to the previous layout.

[^f3-stage]: The map token is `shader_11_queerrubber:0:0#layout:line#gap:2.2#bodies:1.35#shapes:sphere,torus,sphere,capsule,cube#stage:0.4` at cell (8, 7): the five bodies in a line 2.2 m apart down the lane at x 8.5, between the colonnade's pier columns at x 6 and x 10, each scaled 1.35 times the script's default and standing on a 0.4 m stage. The leather sphere is 1.94 m across, the pink one 1.78, the cube 1.35 on a side. Without these keys the script builds its original arc of smaller bodies floating at 1.5 m, which would have stood one of them on a pier. Palle, 25 September: "stages large spheres and cubes".

[^f3-emission]: Godot's spatial shaders separate what a surface reflects (ALBEDO, ROUGHNESS, METALLIC, lit by the lamps) from what it emits (EMISSION, added whether or not any lamp reaches it). The rims discussed in the five-body collection and the furnished STUDY use EMISSION. The learner relief shader adds no emission.

[^f3-spin]: `shader_11_queerrubber.gd`: leather at 0.15 radians a second, pop plastic at -0.18, the ring at 0.2, the capsule at 0.12, the cube at -0.1 (a cylinder in the script's own defaults; the map asks for a cube), each turned in `_process`. Rotation is the one thing here that does keep a state: a node's transform, on the processor. `pop_plastic.gdshader` reads no UV and no texture; `leather.gdshader` reads `noise(UV * grain_scale)`; `fur_velvet.gdshader` reads `random(UV * noise_scale)`.

[^f3-white]: `sad_metal.gdshader` declares `uniform sampler2D tear_noise : hint_default_white;` and the five-body collection script contains no `set_shader_parameter` call, so the sampler reads white everywhere and the tear term is a constant. The ring's `noise_tex` is declared the same way, so its "oil on water" perturbation is a constant too: the rainbow you see is the clean rim.

[^f3-lamps]: Three `OmniLight3D` nodes: pink (1.0, 0.1, 0.5) at energy 8, blue (0.1, 0.3, 1.0) at 8, purple (0.8, 0.0, 1.0) at 6; `omni_range` 10; `shadow_enabled = false` on all three.

[^f3-drift]: `spectrum(t)` is `0.5 + 0.5 * cos(6.28318 * (t + offsets))`, periodic in 1, and the drift is `TIME * 0.1`. Over the clock's thirty seconds that is exactly three cycles, so when the clock wraps the rainbow lands where it started. The first hall's wave leaps at the wrap; this rainbow does not, by an accident of arithmetic.


---

# What carries you over the water?

The bridge takes you across an eleven-metre square of water. Glass under your feet; a moving surface below. On either side, the bathhouse opens between columns and chairs. A sphere and cube wait near the entrance. They stay rigid while the water changes.[^f4-basin]

<!-- @basin_water -->

Hold the water with TIME. The button stops its changing phase. COLOUR leaves a field on a flat plane. NORMAL makes that plane answer light as though it had slopes. HEIGHT gives those slopes an outline. Look across the surface from the bank: now the edge itself rises and falls. Three readings of one field, and the glass carries you through all three.

In Materials, the circle seemed to stand out from a square that remained flat. Here the vertices really move in the rendered image. The distinction matters, but it does not settle what the water can do. A moved vertex is still no promise of resistance. Your feet encounter another construction.

The smaller study beside the basin puts that difference within reach. Carry the point upward; the apparent height increases. Move it sideways; another part of the field comes into view. Let go. The surface keeps this reading because the input stays where you left it. The cube beside it does not bob. Neither does the narrow glass support above it.

At the large console, take SCALES down to one. Broad changes cross the water. Add another scale: smaller changes enter at half the weight. Add two more. The rule keeps dividing its attention between larger and smaller differences, but divides the total by the weights it has used. Detail can increase without increasing the permitted height.[^f4-bound] Four scales give a particular surface. They do not give four times as much sea.

Walk onto the bridge and look down. Light and viewing angle help this field read as water. A pale response gathers where the surface turns away from the eye; the height changes the directions that can meet you. Some of that pallor is emission, a brightness added by the material itself. There is no reflected room hidden beneath it, no current waiting to carry the sphere away. The word water gathers expectations that this construction answers only in part.

Six coloured balls and a pink bathing ring float beside the bridge. Pick one up, push it down and release it. It rises, overshoots and settles. The ring can tilt; its hole stays open. These bodies keep their velocity even when you hold the water's phase. Their support comes from another rule: sample a depth, apply an upward force, resist motion. The water has acquired something that floats without acquiring a fluid simulation.[^f4-toys]

Start TIME. The sampling position travels around a circle; the field returns when that journey completes. Stop it partway. The water stops immediately, while a disturbed ball can keep moving. In the water itself there is no remaining momentum, no wave arriving from somewhere else. The processor retains a phase; the shader reads it and computes a surface. It has no record of the previous water.[^f4-phase]

The controls let you intervene in that reading. They do not let you make a splash. This is a useful limit to meet with the body: movement can be present without consequence passing from one part of the water to another. The later state-based hall will ask for the previous field as part of the next calculation. Here, repeating the inputs is enough.

So, what carries you. The glass does. It is a narrow, fixed bridge with a collider, not a lid over the entire pool. The water has none. Its highest permitted crest remains below the bridge; beside the bridge, the basin floor lies lower still.[^f4-support] What you look at and what holds you up are two constructions. The difference becomes practical as soon as you place a foot.

<!-- @shader_09_fbm -->

Beyond the pool stand four squares with their own controls. On the first desk: SCALE, OCTAVES, GAIN, LACUNARITY. One octave gives a field. Another adds finer variation. LACUNARITY changes the ratio between their spacings; GAIN changes how much the smaller scales contribute. Unlike the bounded pool, this graph keeps the raw weighted sum. Its brightness need not stay in the same range as you change the recipe.

The name on the desk is fractional Brownian motion. In this graphics example it names a finite sum of noise at different scales. That construction can resemble terrain without knowing a stone, a slope's weight or the time it took to wear down.

The second square folds the signed field toward ridges. The third removes its sign and drifts. The fourth uses sampled values to displace the coordinates of further samples. Look at it for a while. Marble, smoke, something geological. Each resemblance invites a history. The computation performs its nested readings inside the present frame; it does not inherit the last frame's result. Complexity within a calculation and consequence across calculations are different capacities.

<!-- @dark_sphere -->

The dark sphere pulses from a number it keeps. The pool also has a number kept for it now: a phase that you can hold and resume. The older graph rack still reads the engine's wrapping clock. There is no single clock for everything in this room, and no single meaning of remembering. A counter, a held input and an evolving field preserve different things.

<!-- @ -->

Next, a room that is all surface. Take the glass with you: the thing you walked on was not the thing you looked at.

[^f4-basin]: The current hall is 26 × 29 cells. Its open basin occupies an 11 × 11 rectangle, 1.2 m deep. `BasinWater` opts into `water_study.gd`, which positions the mean surface at −0.40 m and installs the separate bridge, controls and colonnade. The earlier seven-by-three sine pool remains a different configuration; its figures and measurements do not describe this study.

[^f4-bound]: The study uses one to four signed value-noise samples with successively halved positive weights, normalized by their sum. The result lies in [−1, 1]. Relief is limited to 0.25 m, placing the rendered water within −0.65…−0.15 m before numerical rounding. Normal directions are estimated at vertices and interpolated across triangles. This is a finite procedural surface, not a fluid simulation.

[^f4-phase]: The pool's TIME control advances a CPU-owned phase at 0.24 radians per second and wraps it at one turn. The circular lookup repeats in about 26.18 seconds; floating-point computation gives an approximate numerical return. The shader does not read TIME. The learner study instead ties phase directly to the held point's local X. Both compute a field from current inputs without storing an evolving water state.

[^f4-support]: The installed glass bridge is 1.8 m wide and 6 cm thick, with its top at deck height. Its underside is −0.06 m; the water's highest permitted crest, −0.15 m, leaves 9 cm clearance. The glass owns collision; the water does not. In the small learner tray, the corresponding clearance is 6 cm. Neither normal mapping nor vertex displacement updates those colliders.

[^f4-toys]: The seven toys are pickable rigid bodies with separate buoyancy and drag forces. The ring uses eight buoyancy samples and sixteen overlapping sphere colliders around an open centre. CPU samples use the pool's normalized field recipe and current phase, relief and scale count; sine-hash rounding can differ from the GPU, so contact with the rendered surface is approximate. COLOUR and NORMAL use the flat plane's level. Toys do not feed ripples back into the shader. RESET returns released toys and leaves held toys in the hand.


---

# Which of these is the lamp?

A sphere, a cube and a sofa wear the same pink circles. Mint light gathers toward their edges. Above them, chairs hang in pearl rings and a sheet of water forms a ceiling. You have met most of these operations before. Here they are being made to agree on a room.

<!-- @shader_composition_stage -->

Start at the bench. Take DOTS down to zero. The marks leave; the bodies remain. Remove RIM, then GLOW. Put one back. You can find the contribution again without having to undo the whole appearance. There is a difference between knowing a recipe's ingredients and being able to decide how much of each belongs here.

Walk around the sphere and cube. The sphere offers a curved band to your eye. On the cube, a face can become the band. A single material does not give every body the same appearance: it encounters different normals, addresses and proportions. The sofa receives the circles through a room-based projection because its source mesh has no UV coordinates. Even sharing a rule requires a decision about how that rule reaches a body.[^f5-recipe]

Press SETTING. The suspended chairs and water ceiling disappear; the backdrop becomes grey. The three main bodies keep their material, positions and lamps. Then bring the surroundings back. The circles may feel quieter or louder, cheaper or more ceremonial. Which change belongs to the object, and which to the place you have given it?

PALE makes another kind of comparison. It changes the ground colour and roughness as well as removing the three additions. You cannot attribute its whole effect to the absence of glow. Return to one slider when you want to isolate a contribution. Return to the whole room when you want to compose.

The small study nearby puts those decisions into the point you have carried through the book. Its position chooses three amounts. Trigger removes the additions without erasing that choice; trigger again and they return. Nothing has become more solid or less solid. The recipe displaces no vertices. This time the material change belongs entirely to the surface's response.

So, which of these is the lamp? The material can add visible brightness without a lamp shining on it. That does not make it a light source for the sofa beside it. In this comparison, emission brightens the surface that owns it; the separate lamps supply incident light. The mint edge is not proof of a hidden lamp behind the body. It is a relation between a normal and your eye.[^f5-light]

Pink does not settle what the room means. Neither does excess. A body can be brightly dressed and tightly prescribed; a changeable appearance can still be offered through a very small menu. Here you can inspect some of that menu, refuse a preset, keep an awkward combination. Those permissions are concrete. What you make of them remains open.

<!-- @shader_12_pinkextravaganza -->

The older collection has no control bench. A title in pink capitals floats above a sagging sphere, a ring, a black cube, an enormous sphere and a sheet of water on the floor. Its notes promise numbers pushed past their intended ranges. Hold that claim. First look at what the surfaces actually do.

The floor water comes to your ankles and passes through your shins. Its notes say it refracts wrong on purpose. Look at the floor through the water, at the edge where the sheet ends. Nothing is bent by a refraction calculation. Three sines move its height; noise and a view-dependent colour help it read as liquid. The separate water overhead uses the same shader. Neither sheet has the bathhouse toys' buoyancy, and neither remembers a splash. At the project's clock wrap, their phases jump.[^f5-water]

The large sphere swirls, glitters and breathes. Some of its colour responds to the lamps; some is added as emission. The sagging sphere asks each vertex how far down it should be at this moment. Its surface looks yielding, but no weight pulls the sag. The pearl ring adds shifting colour. The black cube gives its nearly edge-on faces a rainbow. Their titles invite bodily and material associations; their operations answer only part of each invitation.

Now the claim about excess. The collection's builder loads those five shaders without setting their material uniforms. The mesh sizes and placements have been arranged, but the materials begin at their declared defaults.[^f5-defaults] The excess was already chosen by whoever wrote those defaults. Taste did not arrive afterward to judge an innocent calculation. It was there in the first numbers.

There is also a small motion with accumulated state. The turning objects bob because their script adds a displacement every frame. An earlier addition remains in the next position, and the size of that bob depends on the frame rate. This differs from asking a shader for a position directly from the clock. It is a reminder that not every persistence is a carefully designed memory. Some are consequences of how a line was written.

<!-- @dark_sphere -->

The dark sphere pulses in a room where so much else already pulses. A retained counter, a held recipe, an accumulated position: each keeps something different. None of these keeps an evolving field to supply to its own next update.

<!-- @reference_plural_body -->

Six limbs unfold around three heads. The pose opens without becoming another inventory. A pink edge catches the light; a silver loop holds a space beside the body.

The Peaches and Pussykrew reference brings bodily excess into this return to familiar primitives and shaders. Our assembly makes an attachment changeable. That is a technical permission, with limits: a larger menu of parts cannot by itself promise a freer life. Let the pose remain unresolved. The body does not owe the room a single final outline.

<!-- @ -->

Take a chosen combination into the next room. There the question changes: what if the surface must keep what happened to it, rather than simply recompute the appearance you asked for?

[^f5-recipe]: The composition stage shares one material across its sphere, cube and existing sofa prefab. Three-plane projection uses positions in the stage's frame and weights from the surface normal. DOTS mixes pigment; RIM adds a view-angle contribution; GLOW adds the mixed pigment as emission. Its primary recipe has no clock. The smaller learner version uses mesh UVs on the carried point and cube; it does not reconstruct the sofa projection.

[^f5-light]: SETTING changes the backdrop and the visibility of suspended scenery. It preserves the primary recipe, meshes, transforms and lamps. That scenery has shadow casting and GI contribution disabled. Emission can contribute to indirect illumination in other renderer configurations; visible brightness alone does not establish that behaviour here.

[^f5-water]: The existing `queer_water.gdshader` uses three clock-driven displacements with amplitudes 0.05, 0.04 and 0.03 m. It adds emission and partial transparency, but no screen refraction, updated water normals, collider or fluid state. The floor plane starts 0.1 m above its anchor; its theoretical displacement bound reaches 0.12 m either way. Its phase rates do not complete whole turns at the configured 30-second shader-clock wrap. These facts describe the older dream-water shader, not the preceding hall's held-phase, normalized field.

[^f5-defaults]: `shader_12_pinkextravaganza.gd` loads the collection materials without setting shader parameters. Its map token changes geometry and placement, not those material defaults. The newer composition stage does set uniforms and exposes them through controls. The older collection's bob adds a clock-sampled displacement each frame without multiplying that addition by frame duration; its rotations, separately, do use frame duration.


---

# Where is the last frame?

<!-- @shader_state_chamber -->

Touch the wall. Take your hand away. Something remains where you were, although it has kept neither your hand nor the reason you put it there. A small disc of two quantities is enough for this field to continue from your intervention.

Press STEP. Press it again. RUN lets the change gather; HOLD gives you time to look. The point and cube wear the same record. They do not exchange anything through the space between them. One flat field has been fitted to three bodies, and the fit makes different parts of it visible.

Pink asked how much to add and what the surrounding room made of that addition. Here an addition acquires consequences. The next state depends on the previous one. Your mark may become difficult to recognise while the process still depends on its presence. This is a limited kind of memory: a present state shaped by earlier operations, without a story about who made them.

Change INK. The field looks different and its stored quantities have not changed. Clear it. Now something has been removed from the record. These actions can resemble each other on a screen, but they do different work. What would you need to inspect to tell concealment from erasure?

<!-- @shader_10_reactiondiffusion -->

The older two-square display remains nearby. The left square is green, edge to edge. Its label says Reaction-Diffusion. It runs a rule that asks for two quantities from a previous texture, lets them diffuse and react, and draws a new colour. The missing part is the return. Its script never binds that previous texture to its own completed output.[^f6-unbound]

In the captured version, the unassigned input reads white. Both quantities begin at one, the first update produces green, and the next frame repeats that first update. The panel has a place for a past and no past handed to it. The new wall makes that absent connection visible: completed data must be kept somewhere and supplied again.

A return alone does not promise an intricate pattern. A uniform field can remain uniform. The wall begins with three differences; CLEAR removes them. STEP after CLEAR changes nothing. You have not broken the mechanism. You have given its rule a condition that it preserves.

![Earlier numerical comparison of the old rule with feedback and two diffusion settings](images/what-the-rule-would-do.png)

*An earlier reconstruction used a ten-cell seed in a 256 × 256 field. At diffusion coefficients 0.16 and 0.08 the disturbance remained small; at 1.0 and 0.5, with the same feed and loss, it spread. This is an earlier comparison, not a capture of today's 96 × 96 wall. The starting difference, boundary and coefficients belong to the result.*

The right square looks grown: cyan frost branching from its centre. GROWTH lengthens its reach; DENSITY thickens it. Its label says DLA, a name used elsewhere in the museum for particles wandering until they stick to an aggregate. Here the shader constructs the appearance with noise and a radial mask.[^f6-dla] Turn the control down and up: a branch can return without having regrown. The nearby Memory Skin moves too, but does not store the contacts its name may lead you to imagine.

These are useful likenesses. A convincing image of a process can invite us to ask how that process works. It can also let the question disappear. The difference becomes available when the controls expose what changes and what survives.

<!-- @dark_sphere -->

The dark sphere pulses from a number kept on the CPU. Memory was already present in the room's machinery, in earlier recorded traces and in settings left where a hand released them. The new distinction is narrower: this shader's evolving field receives its own previous state and the neighbouring values within it.

Nothing here remembers everything. The wall keeps concentrations, not identities or intentions. It wraps one edge onto another. It stops when its clock stops, and its record disappears when the study unloads. Calling it a living skin may begin an association; it does not establish a living being.

What becomes possible when a surface can continue after we leave it alone? And what do we mistake for care when a system merely retains a trace? The next hall will change the rule while keeping the obligation to say which past each update receives.

<!-- @ -->

[^f6-unbound]: The retained `shader_10_reactiondiffusion.gd` rack loads `commons/resourses/shaders/reaction_diffusion.gdshader` without assigning `prev_texture`. The flat green capture and white-input explanation refer to that implementation and renderer, not a promise about every unassigned sampler.
[^f6-dla]: `dla_visual.gdshader` describes its output as a visual approximation using noise. The particle-by-particle aggregate elsewhere in the project is a different implementation. Similar appearance does not establish the same process.
