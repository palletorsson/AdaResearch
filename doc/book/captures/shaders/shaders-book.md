# shaders: the chapters

## Shader 01 Shaping

*Shader_01_Shaping*

### Why does the wave jump?

Your question can wait at the door. Five dark squares hang in a row along the wall, pictures two metres on a side, each with a desk in front of it, and one of the five is already moving with nobody at its desk. Begin with one that holds still.


The first square is a graph: a faint grid every quarter, one white line. Its desk carries a single slider, THRESHOLD, and one line of text. Leave the text for now.

Drag the slider to the right. The white line runs along the bottom of the square, climbs in one vertical stroke, and runs along the top. The stroke follows your hand. Watch both halves of the line while it moves. Neither arrives first. The right-hand part of the square is a shade lighter than the left, and that band moves as one piece with the stroke.

Try to catch it in between. Drag fast, then slowly. There is no in-between. At each position of the slider the whole square is one picture; at the next position it is another whole picture. Nothing travelled from the old stroke to the new one, because there was no old stroke for anything to travel from.

That is the hall's first fact, and the sequence's. The square is not a thing that gets changed. It is a rule, and the rule is asked, for every pixel of the square, on every frame the museum draws: given this pixel's position and this number, what colour? The pixel just left of the stroke has never heard of the pixel just right of it. They were computed in the same instant, by the same rule, from different positions.

The desk's line names the rule:

```glsl
float y = step(threshold, x);
```

A step takes a threshold and a position and answers zero on one side, one on the other. Everything you saw, the lighter band and the white stroke, is that answer drawn twice.

Now read how the stroke itself is drawn. This is the panel's own code, for the part of the line to the right of the threshold:

```glsl
if (uv.x > threshold + 0.005) {
	float dist_to_line = abs(uv.y - 0.0);
	curve = max(curve, 1.0 - smoothstep(0.0, line_width, dist_to_line));
}
```

The picture of a discontinuity is made with a continuous function. Each pixel measures its distance to where the line should be and fades over a line's width; without that, a line one pixel wide would flicker as you moved your head. The step is the subject and smoothstep is the pen. You meet the pen on its own at the next desk.

The second square has two sliders, EDGE 0 and EDGE 1, and two orange marks on the graph where they stand. Between the marks the white line eases from the bottom to the top in an S; outside them it is flat. Push the marks apart and the S stretches. Push them together and it steepens toward the stroke you saw at the first desk.

Now push EDGE 0 past EDGE 1. The function is defined as a division by the distance between its two edges, and the language this panel is written in promises nothing about what happens when that distance turns negative.[^Shader_01_Shaping--smoothstep] Whatever the square shows you now is not something the rule promised. You have walked to the edge of what it defines, and it was two slider-widths away.

The third square is the one that moves. FREQUENCY, AMPLITUDE, PHASE SPEED. A wave runs across it, and it ran before you arrived. Move AMPLITUDE: the wave grows or shrinks in place. Move FREQUENCY: the wave jumps. Not faster, not slower; it is suddenly somewhere else, and then runs on as before.

Now the slider the chapter is named for. Move PHASE SPEED by one notch. The wave leaps sideways, by an amount you could not have predicted, and continues. Move it back a notch: another leap, and not the reverse of the first. Then take your hands off the desk and watch for half a minute. The wave leaps on its own.

Here is the line:

```glsl
float func_val = 0.5 + amplitude * sin(frequency * uv.x * 6.28318 + TIME * phase_speed);
```

The wave's position is TIME multiplied by the speed. TIME is the museum's clock. The panel keeps no position of its own from one frame to the next; it asks the clock and multiplies. When you change the speed, every frame after that multiplies the whole clock by the new number, so the phase moves by the change in speed times however long the clock has been running. One notch of the slider is a tenth, and fifteen seconds into the clock's run that is a quarter of a wavelength, at once.[^Shader_01_Shaping--leap] A wave that kept its own position could accelerate. This one cannot. It can only be asked again.

And the leap with nobody at the desk: this museum's clock wraps. It runs for thirty seconds and drops back to zero.[^Shader_01_Shaping--rollover] At the default speed that drop moves the phase by thirty radians, four and three-quarter cycles, so the wave you are watching skips about a quarter of a wavelength twice a minute. Some of the moving surfaces in the halls ahead do the same at that moment. Some were written, by accident or on purpose, so that they do not. Watch for it.

The fourth square, EXPONENT, draws one curve from the bottom left corner to the top right. At one it is a straight line. Below one it bulges upward; above one it sags. Nothing here moves and nothing jumps: the exponent bends the same line in place. A curve is a decision about where the value collects, near zero or near one, and this desk lets you make it with one number.

The fifth square draws all four on one graph, a red step, a cyan S, a green wave and an orange curve, and a white line that blends them. The green one keeps moving among the three that hold still. That is the whole hall in one square: four rules for turning a position into a value, and one clock.


The dark sphere pulses beside the desks. Its pulse is driven from the other side of the museum's machinery, by a script that runs once a frame on the processor and remembers where it was.[^Shader_01_Shaping--sphere] Stand between it and the wave. One of them has a past.

You came from halls where noise was made and then kept: a column of values, a voxel field, a wall. Nothing in this hall is kept. The graphs are asked, every frame, from nothing, and all they are asked with is a position, a few numbers from the desks, and the clock.

Everything in this hall is also flat, and hangs on a wall. The sequence begins with pictures. Two halls on it moves to bodies, and after that to rooms.


The way out is a long one. The museum builds a crossing after every hall, a door, a run of open floor, and a second door offset to one side, and this hall has asked for its crossing to be fourteen rows deep instead of the usual seven.[^Shader_01_Shaping--passage] Walk it slowly. The museum keeps only a hall or two built at any time; the rest is a plan on disk, and the crossing's corner is where the swap is hidden. A rule with no memory on the square, and a building that keeps two rooms around you. Take the wave's jump with you.

[^Shader_01_Shaping--smoothstep]: The desk's line is `float y = smoothstep(e0, e1, x);`. The GLSL specification defines it as a clamped division by `e1 - e0` followed by a cubic, and states that the result is undefined when the first edge is not less than the second. What a particular graphics driver draws in that case is its own business.

[^Shader_01_Shaping--leap]: The panel is `shaping_sin.gdshader`; the slider steps by 0.1. The phase is `TIME * phase_speed`, so a step of 0.1 taken t seconds into the clock's run moves the phase by 0.1 t radians: 0.08 of a wavelength at five seconds, 0.24 at fifteen, 0.46 at twenty-nine. Nothing about the leap is random. It is the clock's reading at the moment you moved.

[^Shader_01_Shaping--rollover]: `project.godot` sets `rendering/limits/time/time_rollover_secs` to 30, so the shader clock TIME runs from 0 to 30 and wraps; Godot's own default is 3600. At phase speed 1.0 the wrap moves the phase by 30 radians, 4.77 cycles, a leap of 0.23 of a wavelength; at 2.0 it is 0.45, at 0.5 it is 0.39. Only a speed whose product with 30 is a whole number of cycles would hide it, and the slider's steps do not land on one.

[^Shader_01_Shaping--sphere]: `dark_sphere.gd` drives its wobble and its emission pulse from `_process`, on the CPU, frame after frame, from values it keeps. The graphs keep nothing; they are functions of TIME.

[^Shader_01_Shaping--passage]: `map_info.museum.passage` on this map is `{"kind": "chicane", "depth": 14}`. The museum's crossing rule (`endless_museum.gd`, `_authored_passages`): a door in this hall's last row, `depth` rows of crossing, a door where the next hall's own door is, then the next hall's first row copied, so that walking the last metre of the crossing you are already looking into the room you are entering. The default depth with a known next hall is 7. A chicane's middle rows open the whole span between the two doors, so when the doors sit at opposite corners the crossing is a room rather than a corridor. Palle, on first seeing one: "like a service corridor that can lead to other places."

---

## Shader 05 Patterns

*Shader_05_Patterns*

### Where are the seams?

The long crossing ends at a floor, again. You have met tilings before, whole halls of them, and there a pattern was a thing with parts: pieces, and the joins between them. This hall hangs four dark squares along its wall, pictures again, with a desk under each and a tilted panel at the left end with two buttons, MODE and RESET. Leave the buttons. Go to the first square.


A grid of shapes, five across and five down, each a little brighter or darker than its neighbours. The desk: GRID SIZE, SHAPE SIZE, ANIMATE. Take GRID SIZE down to one. One shape, filling the square. Now up, one notch at a time. Two across, then three, then twenty. The shapes get smaller, and the seams between them, the lines where one ends and the next begins, arrive with them.

Where are they? Not drawn. There is no line in the code for a seam. Here is what each pixel does:

```glsl
vec2 uv = UV * grid_size;
vec2 tile_uv = fract(uv) - 0.5; // centered -0.5 to 0.5
```

The pixel multiplies its position by the grid size and throws the whole-number part away. A pixel at 3.7 becomes 0.7, and so does one at 12.7. After that line every pixel believes it is inside the one and only tile, and draws the shape accordingly. The seams are where the whole numbers were thrown away: fold lines in a coordinate, not the edges of a piece. Nothing was copied five times. Every pixel folded its own address.

The tiles are not quite identical, though. Each is tinted by a number made from the whole part before it was discarded, so the fold shows as a step in brightness.[^Shader_05_Patterns--tint] Press ANIMATE and every shape breathes on its own phase, again from its whole part and the clock. One rule, twenty-five tiles, no two in step.

The second square is a labyrinth of arcs, and here the chapter's question has no answer you can point to. Look for a seam. Every arc crosses from one tile to the next without a kink. GRID and THICKNESS are on the desk, and SEED; move SEED and the whole labyrinth is another labyrinth, all at once, with the same property.

```glsl
float choice = step(0.5, hash(tile_id));
if (choice > 0.5) {
	tile_uv.x = 1.0 - tile_uv.x;
}
```

Each tile flips a coin from its address and, on heads, mirrors its own coordinate. Then it draws two quarter-circles from two opposite corners, each of radius one half. A quarter-circle of radius one half from a corner meets the tile's edges exactly at their midpoints, and so does its neighbour's, whichever way the neighbour flipped. The seams are still there, at every whole number. They are invisible because the rule was chosen so that both sides always agree at the midpoint. The word is Truchet; what it names is that agreement.

The third and fourth squares, OFFSET ROWS and BRICK, put the seam back and make it the subject. A brick wall is nothing but its joins. `uv.x += mod(row, 2.0) * 0.5;`: every second row is slid half a tile before the fold, and the pattern you know from every wall outside this building appears.

Now press MODE. The four squares are replaced by three. The first is Wang tiles, and its desk claims something: an edge-matched tiling, with a slider called APERIODIC. Each tile's four edges are coloured, red, cyan, gold or green, from a number made of the tile's address and the edge. Take APERIODIC down to zero and look at any seam. The colour on this side and the colour on that side were chosen separately, and mostly differ. Now bring APERIODIC up to one. The seams agree.

```glsl
int matched_type = edge_type(neighbor, opposite);
vec3 own_col = EDGE_COLORS[etype];
vec3 matched_col = EDGE_COLORS[matched_type];
vec3 edge_col = mix(own_col, matched_col, aperiodic_mix * 0.5);
```

They agree because each side paints its edge as the average of its own colour and the neighbour's, and the average of two things is the same from either side. No tile was chosen to fit its neighbour. The seam was painted to look as if one had. The desk's word, Wang, names a tiling whose tiles are picked so that their edges match; what this square does is the reverse, and the slider is the distance between the claim and the paint.[^Shader_05_Patterns--wang]

The two Voronoi squares have no tiles to fold. Each pixel asks which of a scatter of points is nearest and colours itself by that, or by the difference between the nearest and the second nearest, which is zero exactly on the borders, so that the second of them is a picture of nothing but seams. The points still live in folded cells, one per cell, jittered. The seams you see are not those cells' edges but the borders the points make between themselves.

Press MODE again. Noise synthesis: noise layered at several scales, which the basin hall will take further, a Worley variant, a domain warp. No seams anywhere, and yet the noise is built on the same fold, a lattice of whole numbers with a random value at each corner. The seams are hidden by the interpolation between corners, whose slope was chosen to be zero at every corner, so that the surface passes over each fold without a crease.[^Shader_05_Patterns--smooth]

So the floor returned, and it has no parts. There are seams at every whole number of every square in this hall. Some are shown, as the tile's step in brightness and the brick's mortar. Some are agreed away, as Truchet's midpoints. Some are painted over, as Wang's averages. Some are smoothed, as the noise's zero slopes. None is a join between two things, because there are no two things: there is one rule, asked at every pixel, and a coordinate that was folded before the rule saw it.


The dark sphere stands in front of the squares. It has no seams because it is one mesh. Everything behind it has seams because it is one function.


<!-- study-spine:reference_pattern_garden -->


The pattern leaves the flat sample and crosses a flower. Turn its phase: a band moves over the petal while the petal stays still. Further back it crosses the room itself.

Claudia Hart's supplied image makes ornament difficult to dismiss as a finishing layer. In this response, the shared pattern can compete with the outline that would ordinarily tell us where one thing ends. Keep watching one edge through the change. Does the surface make the object more available, or make its boundary harder to trust?


Press RESET if you have lost the defaults. The next hall has no desks at all, and nothing on its walls: the pictures end here, and bodies begin. Take the painted seam with you, the one that agreed only because both sides averaged.

[^Shader_05_Patterns--tint]: `patterns_tile.gdshader`: `tile_color = shape_color * (0.7 + 0.3 * fract(sin(dot(tile_id, vec2(12.9898, 78.233))) * 43758.5453))`, where `tile_id = floor(uv)` is the whole part the fold discarded. The animation is `1.0 + animate * 0.3 * sin(TIME + tile_id.x * 1.3 + tile_id.y * 0.7)`, and it leaps at the clock's wrap like the first hall's wave.

[^Shader_05_Patterns--wang]: `patterns_wang.gdshader`. `edge_type(tile_id, edge)` hashes the tile's address with the edge's index, so a tile's north edge and its northern neighbour's south edge are independent draws. At `aperiodic_mix` = 1 the mix weight is 0.5 and both sides of every seam show the same average; at 0 each shows its own draw. The desk's default is 1.

[^Shader_05_Patterns--smooth]: `fbm_basic.gdshader`, `noise()`: `u = f * f * (3.0 - 2.0 * f)` is the interpolation weight, whose derivative is zero at f = 0 and at f = 1, so the value crosses each lattice line with a continuous slope. The lattice is `floor(p)`, the same fold as the tile square's.

---

## Shader 11 QueerRubber

*Shader_11_QueerRubber*

### What does a surface answer to?

The crossing leaves you in a hall with columns. Every other hall in this sequence has refused them; this one asked to keep them.[^Shader_11_QueerRubber--piers] Down the lane between two rows of columns stand five bodies, each on a low round stage and each about the size of a person, turning slowly under three coloured lamps, with a name in capitals at its foot, and a pink line of text hangs over them all.[^Shader_11_QueerRubber--stage] The pictures are behind you now. There are no desks. Nothing here is yours to adjust. What you have is your feet.


Go to the ring first, the black one with a rainbow at its edge. Walk a quarter of the way round it. The rainbow comes with you. It stays at the ring's rim, the part of the surface that turns away from you at a grazing angle, wherever you stand. The pink highlight from the lamp on the left does not come with you; it stays on the side that faces the lamp.

Two answers, then, on one surface. One is an answer to the lamp: where its light lands, and where the reflection would reach an eye. The other is an answer to you: how steeply the surface turns away from where you are. Here is the second, from the ring's own code:

```glsl
float NdotV = dot(normalize(NORMAL), normalize(VIEW));
float rim = 1.0 - clamp(NdotV, 0.0, 1.0);
vec3 rainbow = spectrum(perturbed_rim * 2.0 + TIME * 0.1);
vec3 oil_sheen = rainbow * pow(rim, 2.0) * interference_strength;
EMISSION = oil_sheen;
```

NORMAL is which way the surface faces; VIEW is which way you are. Their product is large where the surface faces you and small where it turns away, and the rainbow is put where it is small. The last line is the one to hold on to. The rainbow is written into EMISSION: light the surface claims to make, not light it receives. Turn every lamp in the hall off and the rim would still glow.[^Shader_11_QueerRubber--emission]

Now the two spheres. The dark one and the pink one both turn, one with the clock and one against it.[^Shader_11_QueerRubber--spin] Watch the dark one, LEATHER: a grain crawls across it, folds pass, and you can see it turning. Watch the pink one, POP PLASTIC, for as long as you like. Nothing on it moves. It is turning at very nearly the same rate.

The dark sphere's skin is drawn from a coordinate painted onto it, so when the sphere turns the skin turns with it. The pink sphere's skin is drawn from NdotV alone, the angle between its surface and your eye, and from nothing painted on. A sphere turned by any amount presents the same angles to the same eye. It answers to you and to the lamps, and not at all to where it has got to in its own rotation. Its cyan edge is the rim you saw on the ring, cubed:

```glsl
float rim = 1.0 - clamp(NdotV, 0.0, 1.0);
rim = pow(rim, 3.0); // Sharp falloff
EMISSION = rim_color * rim * rim_width;
```

The capsule is fur, or says it is. Its code explains its sheen as light grazing the fibres. Read what it computes: the same NdotV, the same rim, roughened with a noise from its painted coordinate, and again written to EMISSION and added to the colour. The eye grazes the fibres, not the light. It is a velvet that glows at its own edges for whoever is looking, and because its grain is painted on, this one you can see turn.

The last body is a cube of a metal the header calls sad, with streaks that were meant to run down it like tears. The streaks are read from a texture that this hall never hands it.[^Shader_11_QueerRubber--white] What you see is the alloy without its tears. And a cube cannot hide its turning the way the pink sphere does. It has corners, and they sweep past you; a cube turned by a few degrees presents new angles to the same eye, and its faces take the lamps one at a time. The rule is the same on both bodies. The shape decides what the rule can show.

Now the lamps. Pink on the left, blue on the right, purple above and behind, each with a reach of ten metres and none of them casting a shadow.[^Shader_11_QueerRubber--lamps] Put your hand between the pink lamp and the leather. Nothing on the leather changes. Stand between the lamp and the ring: still nothing. The lamps here light everything they reach and are blocked by nothing, which is not how a lamp behaves and is exactly how a rule behaves. The surface asks each lamp where it is, what colour it is and how far away. It does not ask whether anything stands in between.

So, what a surface answers to. To the lamps: their direction, colour and distance, and no more. To you: the angle at which it turns from your eye, which is why the rims and the rainbow follow you round the room. To the clock: everything turns, and the ring's rainbow drifts, a tenth of a cycle a second.[^Shader_11_QueerRubber--drift] To its own painted coordinate, if it has one. Not to the other four objects, which it cannot see. Not to its own past, of which it keeps none.

None of the five materials carries a body of its own. The spheres, the ring, the capsule and the cube are shapes this hall lent them, on the map's instruction, and the map could lend them others.


The dark sphere near the centre pulses on its own clock, kept on the processor. Stand where you can see it and the pink sphere together. One is turning and shows it; one is turning and cannot show it; one is pulsing from a number it remembers.

The columns stand through all this, the museum's own furniture on a four-metre beat, and the coloured light lands on them too. They are the one thing in the hall that answers to nothing. A column is placed, and stays.


The next hall has water in it. Take the ring's rainbow with you, and the question of what it would take for a surface to notice that you are standing in front of a lamp.

[^Shader_11_QueerRubber--piers]: `map_info.museum.piers` is `true` on this map and `false` on the sequence's other five. The plan tool (`tools/em_map_halls.py`, `normalize_row`) stamps the template colonnade into every bare hall of eight rows or more: a pier every fourth row from the third and every fourth column from the second, never on or beside a body. On this 14 x 14 floor that rule gives eight piers, the ninth falling on the artifact's own cell. The count is the dealt plan's to confirm.

[^Shader_11_QueerRubber--stage]: The map token is `shader_11_queerrubber:0:0#layout:line#gap:2.2#bodies:1.35#shapes:sphere,torus,sphere,capsule,cube#stage:0.4` at cell (8, 7): the five bodies in a line 2.2 m apart down the lane at x 8.5, between the colonnade's pier columns at x 6 and x 10, each scaled 1.35 times the script's default and standing on a 0.4 m stage. The leather sphere is 1.94 m across, the pink one 1.78, the cube 1.35 on a side. Without these keys the script builds its original arc of smaller bodies floating at 1.5 m, which would have stood one of them on a pier. Palle, 25 September: "stages large spheres and cubes".

[^Shader_11_QueerRubber--emission]: Godot's spatial shaders separate what a surface reflects (ALBEDO, ROUGHNESS, METALLIC, lit by the lamps) from what it emits (EMISSION, added whether or not any lamp reaches it). Every rim in this hall is written to EMISSION.

[^Shader_11_QueerRubber--spin]: `shader_11_queerrubber.gd`: leather at 0.15 radians a second, pop plastic at -0.18, the ring at 0.2, the capsule at 0.12, the cube at -0.1 (a cylinder in the script's own defaults; the map asks for a cube), each turned in `_process`. Rotation is the one thing here that does keep a state: a node's transform, on the processor. `pop_plastic.gdshader` reads no UV and no texture; `leather.gdshader` reads `noise(UV * grain_scale)`; `fur_velvet.gdshader` reads `random(UV * noise_scale)`.

[^Shader_11_QueerRubber--white]: `sad_metal.gdshader` declares `uniform sampler2D tear_noise : hint_default_white;` and the hall's script contains no `set_shader_parameter` call, so the sampler reads white everywhere and the tear term is a constant. The ring's `noise_tex` is declared the same way, so its "oil on water" perturbation is a constant too: the rainbow you see is the clean rim.

[^Shader_11_QueerRubber--lamps]: Three `OmniLight3D` nodes: pink (1.0, 0.1, 0.5) at energy 8, blue (0.1, 0.3, 1.0) at 8, purple (0.8, 0.0, 1.0) at 6; `omni_range` 10; `shadow_enabled = false` on all three.

[^Shader_11_QueerRubber--drift]: `spectrum(t)` is `0.5 + 0.5 * cos(6.28318 * (t + offsets))`, periodic in 1, and the drift is `TIME * 0.1`. Over the clock's thirty seconds that is exactly three cycles, so when the clock wraps the rainbow lands where it started. The first hall's wave leaps at the wrap; this rainbow does not, by an accident of arithmetic.

---

## Shader 09 FBM

*Shader_09_FBM*

### What carries you over the water?

Water lies across the hall, and you are meant to walk on it. Not through it: on it. A pane of glass, flush with the floor and six centimetres thick, covers a pool seven metres long and three wide, and the water moves thirty-five centimetres beneath the pane.[^Shader_09_FBM--basin] Beyond the pool stand four dark squares with desks, and a rack by the door. Cross the pool first.


Stop in the middle of the glass and look down. The surface under your feet is the darkest part of the pool; further off it pales toward a milky blue-green. Now walk to the far end and look back. The dark part has come with you. It is always under your feet, and the pale part is always at a distance.

Nothing in the pool changed when you moved. What changed is the angle at which each point of the surface meets your eye. The water's colour is decided, at every pixel, from that angle: steep, and it answers with the deep colour; shallow, and it answers with the pale one, and with less of it, since the pale water is also the more transparent.[^Shader_09_FBM--fresnel] You met this in the pillar hall as a rainbow on the rim of a ring. Here it is the whole surface, and the rim is wherever you are not.

Watch the waves. Three trains cross one another at different angles and speeds, the longest 1.6 metres from crest to crest, and a finer roughness rides on top of them. Crests reach eleven centimetres above the mean, never more, so they stay twenty-four centimetres short of the glass. The surface is a mesh of some two and a half thousand points, and every one of them is lifted, on every frame, by a rule that reads its position and the clock and nothing else:

```glsl
float height_at(vec2 p, float t) {
	float k = TAU / max(wavelength, 0.05);
	float w = speed * k;
	float w1 = wrap_rate(w * 0.9);
	float w2 = wrap_rate(w * 1.4);
	float w3 = wrap_rate(w * 2.1);
	float h = sin(k * dot(p, vec2(0.90, 0.44)) - t * w1)
	        + 0.55 * sin(k * 1.7 * dot(p, vec2(-0.30, 0.95)) - t * w2)
	        + 0.30 * sin(k * 2.9 * dot(p, vec2(0.62, -0.78)) + t * w3);
	float a = TAU * t / max(rollover, 1.0);
	h += (vnoise(p * 2.3 + 0.9 * vec2(cos(a), sin(a))) - 0.5) * 2.0 * noise_amount;
	return h * amplitude;
}
```

Three sines, from the halls of wave functions; one value noise, from the halls you have just left; and a sum. The water keeps no state. There is no wave that was here a moment ago and has moved on. There is this frame's answer at this point, and the next frame's. If the clock stopped, the water would freeze, and when it started again the water would not resume: it would be wherever the clock said.

![The 7 by 3 m surface at t = 0 seen from above, and a section along the pool showing the glass lid, the mean surface and the pool floor](/book-review/doc/book/figures/shaders/basin-section-under-the-glass.png)

*Left: the surface at t = 0 from above, height in centimetres under the glass, computed from a port of the shader. Right: a section along the pool at three moments; the crests stay twenty-four centimetres below the lid. Amplitude 0.05, wavelength 1.6 m, speed 0.8 m/s, noise share 0.35: the map's values.*

Now stand still for a minute and watch the water and the first square beyond it together. Twice in that minute the square's noise leaps. The water does not. Both are asked from the same clock, and the clock wraps every thirty seconds, as you saw in the first hall. The square was not written for that. The water was: each of its three wave rates is rounded to a whole number of cycles per thirty seconds, fourteen, twenty-one and thirty-two, and its noise drifts round a circle once per wrap, so that at the moment the clock drops to zero the surface is exactly where it was when the clock started.[^Shader_09_FBM--wrap] The difference between a surface that leaps and one that does not is not a memory. It is arithmetic done in advance.

There is no desk for the water. Its numbers are written into the map, in the token that places it:

```
basin_water:0:0#width:7#depth:3
```

Width and depth are the pool's; amplitude, wavelength, speed and the noise's share keep their defaults, and `calm:on` would still it into a mirror. Whoever edits the map edits the water. Nobody in the hall can.

So, what carries you. The glass does. It is a slab the museum lays over every cell of the pool, with a collider of its own, and the museum counts it as floor you can walk.[^Shader_09_FBM--lid] The water has no collider at all. It is a picture that happens to lie under a floor. Had the map asked for the pool without its lid, the museum would have left it open, to be stepped into by a wedge, and you would stand in the water and it would lift through your shins without touching you. What you are looking at and what holds you up are two different constructions, and only one of them knows you are there.


The four squares beyond the pool are the noise you came from, layered. On the first desk: SCALE, OCTAVES, GAIN, LACUNARITY. Take OCTAVES down to one. The square shows rolling hills of value noise, the lattice of the previous sequence, soft, with nothing smaller than a hill. Add one octave. The same hills, with smaller hills laid over them at half the height. Add another. By five the square looks like a mountain range seen from very high up, and by eight nothing more changes that you can see.

```glsl
for (int i = 0; i < octaves; i++) {
	value += amplitude * noise(p * frequency);
	frequency *= lacunarity;
	amplitude *= gain;
}
```

Each turn of the loop doubles the frequency, if LACUNARITY is two, and halves the amplitude, if GAIN is a half. Move LACUNARITY and the small hills sit at another spacing relative to the large ones. Move GAIN toward 0.9 and the small ones grow until the large are buried. The words on the desk are fractional Brownian motion; what they name is this loop.

The second square folds the noise with an absolute value so that its zero crossings become sharp ridges. The third removes direction the same way and drifts. The fourth feeds the field its own output as an input:

```glsl
fbm(p + warp * fbm(p + ...))
```

Look at the fourth for a while. Marble, smoke, something geological. This is the nearest the sequence comes to a memory, and it is not one: the field reads itself inside a single frame, and the next frame reads itself again, from nothing. A rule fed its own output within the frame can make forms that look grown. A rule fed its own output from the previous frame is another thing entirely, and the last hall of the sequence stands in front of it.


The dark sphere stands between the pool and the squares. It pulses from a number it keeps. Behind you the water moves from a number it reads; in front of you the noise drifts from the same number and leaps twice a minute.


Next, a room that is all surface. Take the glass with you: the thing you walked on was not the thing you looked at.

[^Shader_09_FBM--basin]: `map_info.museum.basin` on this map is `{"depth": 1.2, "glass": true, "rects": [[3, 1, 7, 3]]}`: cells x 3..9, z 1..3. The museum (`endless_museum.gd`) sinks each cell in the rect: a pool floor slab a basin-depth down, side walls where the pool meets ground, and a glass lid 6 cm thick with its top flush with the deck. The water is `basin_water:0:0#width:7#depth:3` at cell (6, 2), the rect's centre; the artifact's origin is the lid and the plane sits at `lift` = -0.35 m.

[^Shader_09_FBM--fresnel]: `basin_water.gdshader`, fragment: `facing = dot(NORMAL, VIEW)`, `fres = pow(1.0 - facing, 3.0)`, colour `mix(deep_color, shallow_color, fres)`. Deep is (0.06, 0.20, 0.30) at alpha 0.86; shallow is (0.38, 0.64, 0.72) at alpha 0.55. The alpha travels with the colour.

[^Shader_09_FBM--wrap]: Measured on a port of the shader over the 7 x 3 m pool at the map's values: crests 10.9 cm, RMS height 4.24 cm, RMS vertical speed 15.2 cm/s, periods 2.14, 1.43 and 0.94 s; 49 x 49 = 2401 vertices, 14.6 cm apart along the pool and 6.25 cm across it. The three rates are `wrap_rate(w)`, that is `floor(w * 30 / TAU + 0.5) * TAU / 30`: 14, 21 and 32 whole cycles per rollover. The largest difference between the surface at t = 30 s and at t = 0 s is zero to four decimal places of a millimetre. The rollover is read from `project.godot` by `basin_water.gd` and handed to the shader.

[^Shader_09_FBM--lid]: In `endless_museum.gd` a glass basin cell gets a box at y = -0.03 of size 1 x 0.06 x 1, its collider, and `_walk_cells[...] = true`; an open one (`glass: false`) gets no walk cell and no deck floor and is entered by wedge. `basin_water.gd` builds one `MeshInstance3D` and nothing else.

---

## Shader 12 PinkExtravaganza

*Shader_12_PinkExtravaganza*

### Which of these is the lamp?

No desks. A title in pink capitals floating above everything. Three lamps, pink, purple and pink again, and five things under them: a sagging sphere, a ring and a black cube, each on a low stage, an enormous sphere floating above the rest, and on the floor a sheet of water twelve metres square that you are already standing in.[^Shader_12_PinkExtravaganza--scene] The hall's own notes say that every number here has been pushed past its intended range. Hold that. First find the light.


Start with the water, since you are in it. It comes to your ankles and it does not touch you; walk through it and it lifts through your shins as if you were not there. It is pink over purple, with pale glints that move. The notes say it refracts wrong on purpose. Look for the refraction: look at the floor through the water, at the edge where the sheet ends. Nothing is bent. The code has no refraction in it, wrong or right; it has three sines for the height, a noise for the glints, and a colour it partly emits itself.[^Shader_12_PinkExtravaganza--water] Stand still in it for half a minute. It jerks. All three of its waves are written straight on the clock, and the clock wraps.

Now the big sphere. It is the loudest thing in the room: hot pink swirling into magenta, a rainbow drifting over it, a glitter, and it breathes, five per cent larger and smaller, every second and a half. Walk round it. The rainbow comes with you; it is the rim again, the angle to your eye. Now try to find the lamps on it. There is a pink lamp to the left and a purple one to the right, so the sphere should be pinker on one side and bluer on the other. It is barely so. Most of what you see it makes itself:

```glsl
EMISSION = color * 0.4 * pulse;
EMISSION += hot_pink * rim * 0.8;
```

Four tenths of its own colour, pulsing, plus a hot pink at the rim, added to whatever the lamps manage. The lamps are there. They are outvoted.

The sagging sphere: bands of sag run across it, up to ten centimetres deep, and move. That is not a body deforming. It is every vertex asked, each frame, how far down to be:

```glsl
float melt_wave = sin(VERTEX.x * 5.0 + TIME * melt_speed) * 0.5 + 0.5;
VERTEX.y -= melt_wave * melt_amount;
```

It, too, emits a fifth of its own colour, and it tints its edges red and its centre blue by the angle to your eye, and calls that chromatic aberration in a comment that admits it cannot do the real thing without reading the screen.[^Shader_12_PinkExtravaganza--candy] The ring, crushed pearl, is a diffraction grating done with noise: a hue that runs round the ring by angle and drifts with the clock, and glints that are emission. The black cube is the oil slick of the pillar hall, rim and rainbow, emission, and on a cube the rim is not a band but a face: whichever face turns nearly edge-on to you takes the rainbow whole, and the face that squares up to you goes black.

So: which of these is the lamp? Every one of them. The five surfaces make most of their own light, and the three lamps hung above them add to it and are outvoted. A lamp is a thing that puts light on a surface. In a rule that writes EMISSION, the surface puts light on itself, and it does so at every pixel, from the angle to your eye and the clock, exactly as the rims did two halls ago, only louder.

Now the notes' claim. Every number pushed past its intended range. Read the script that builds this hall: it loads five shaders, hangs three lamps, sets a title, and sets no number at all. Not one slider value, not one uniform.[^Shader_12_PinkExtravaganza--defaults] Everything you see is what these rules do when nobody touches them. The excess is the default. Taste would be the thing you would have to add.

There is one motion in this hall with a past. The objects bob. Not from the clock: each frame adds a small amount to each object's height, and the amounts add up, so an object's height is the sum of everything that has been added since the hall was built.[^Shader_12_PinkExtravaganza--bob] Add faster and it bobs further: at ninety frames a second the bob is nine centimetres, at seventy-two it is seven. A surface asked from the clock is the same in any headset. A bob added up frame by frame is the headset's. The only thing here that remembers is also the only thing here that depends on who is looking.


The dark sphere, pulsing purple, in a room where everything pulses pink. It is the one thing in the hall you could mistake for a lamp that is not trying to be one.


<!-- study-spine:reference_plural_body -->


Six limbs unfold around three heads. The pose opens without becoming another inventory. A pink edge catches the light; a silver loop holds a space beside the body.

The Peaches and Pussykrew reference brings bodily excess into this return to familiar primitives and shaders. Our assembly makes an attachment changeable. That is a technical permission, with limits: a larger menu of parts cannot by itself promise a freer life. Let the pose remain unresolved. The body does not owe the room a single final outline.


One hall left, and it is quiet. Take the emission with you: a surface that lights itself is answering to nothing but its own rule and your eye.

[^Shader_12_PinkExtravaganza--scene]: `shader_12_pinkextravaganza.gd` with the map's token `#bodies:1.5#shapes:sphere,torus,cube,plane,sphere_big#stage:0.35#water:12`: melted candy, a sphere of radius 1.17 m on a 0.35 m stage at x -4.5, turning at 0.25 rad/s; crushed pearl, a torus 2.3 m across at x -1.5; oil slick latex, a cube 1.8 m on a side at x 1.5; queer water, a plane 12 m square on the floor, centred on the hall's anchor, not turning; drag extravaganza, a sphere of radius 1.6 m at (0, 4, -2), neither scaled nor staged, turning at 0.3 rad/s. The script's own defaults, without the token, are smaller bodies at fixed heights, a capsule instead of the cube, and an 8 m water. Lamps: (1.0, 0.0, 0.5) at (-5, 5, 3), energy 8; (0.5, 0.0, 1.0) at (5, 5, 3), energy 8; (1.0, 0.1, 0.8) at (0, 6, -2), energy 6; range 10; no shadows. The title reads P I N K   E X T R A V A G A N Z A between two stars.

[^Shader_12_PinkExtravaganza--water]: `queer_water.gdshader`: `wave1 = sin(VERTEX.x * wave_scale + TIME * wave_speed) * 0.05`, `wave2 = cos(... TIME * wave_speed * 1.3) * 0.04`, `wave3 = sin(... TIME * wave_speed * 0.8) * 0.03`, so the crests reach 12 cm above the plane and the troughs 2 cm below the floor it lies on. `EMISSION = color * 0.15 * dream_intensity`, `ALPHA = 0.85`. No `SCREEN_TEXTURE`, no `refract`. At the wrap the three phases drop by 30, 39 and 24 radians, none a whole number of cycles.

[^Shader_12_PinkExtravaganza--candy]: `melted_candy.gdshader`: `melt_amount` = 0.1, `EMISSION = candy_color * 0.2`, `BACKLIGHT = candy_color`, and the comment "Hard to do real chromatic aberration in standard shader without screen reading. We can fake it by tinting based on normal angle." The big sphere's breathing is `VERTEX *= 1.0 + 0.05 * sin(TIME * pulse_speed * 2.0)` at `pulse_speed` 2: a period of 1.57 s.

[^Shader_12_PinkExtravaganza--defaults]: `shader_12_pinkextravaganza.gd` contains no `set_shader_parameter` call. Each material is `ShaderMaterial.new()` with its shader loaded and nothing else set; the shaders that declare a noise texture read a default white. `crushed_pearl`'s hue drifts by `TIME * 0.1` inside a `fract`, three whole cycles per wrap, so of the five it is the one that happens not to leap when the clock does.

[^Shader_12_PinkExtravaganza--bob]: `_process`: `objects[i].position.y += sin(Time.get_ticks_msec() * 0.001 + float(i) * 1.5) * 0.001`, for every turning object, every frame. Summed over frames at rate r this is a bob of about r x 0.001 m in amplitude: 0.09 m at 90 Hz, 0.072 m at 72 Hz, 0.06 m at 60 Hz. `Time.get_ticks_msec()` does not wrap with the shader clock.

---

## Shader 10 ReactionDiffusion

*Shader_10_ReactionDiffusion*

### Where is the last frame?

Two squares, larger than the others in the sequence, and one desk. The left square is green. Not a pattern in green: green, edge to edge, one colour, and it does not change while you watch it. Its label says Reaction-Diffusion. The right square is a cyan frost branching from its centre, and its desk has three sliders, SCALE, GROWTH, DENSITY. Everything in this hall points at the green one. Start there.


The green square is running a rule. Here it is, from the shader the square is drawn with:

```glsl
vec4 prev = texture(prev_texture, uv);
float A = prev.r;
float B = prev.g;
float lap_A = laplacian(prev_texture, uv, 0);
float lap_B = laplacian(prev_texture, uv, 1);
float reaction = A * B * B;
A += (diffusion_a * lap_A - reaction + feed * (1.0 - A)) * dt;
B += (diffusion_b * lap_B + reaction - (kill + feed) * B) * dt;
ALBEDO = vec3(A, B, 0.0);
```

Read the first line. `prev_texture`. The rule begins by asking for a picture: the previous one, its own last frame. It reads two quantities out of that picture at this pixel and at the eight pixels around it, lets them diffuse and react and feed and decay by one small step, and writes the result as a colour, red for the first quantity and green for the second. Next frame it would read that colour back as its picture and take another step. This is the first rule in the sequence written for a past. Every square before it was asked from a position and the clock; this one is asked from what it drew.

And it is green edge to edge because it is never given what it drew. The hall's script builds the square, loads the shader, and hands it nothing for `prev_texture`.[^Shader_10_ReactionDiffusion--unbound] A texture nobody assigns reads as white: both quantities are one, everywhere. Run the rule once on that. The reaction term is one, the first quantity drops to zero, the second stays at one, and the colour is (0, 1, 0). Green. Next frame the rule asks for its last frame again, is given the same white again, and computes the same green again. It has a past written into it and no past handed to it, so it repeats its first step forever.

Suppose the hall did hand it its own picture. From the white start the two quantities would decay evenly, everywhere at once, and within about a hundred frames the square would be red and stay red.[^Shader_10_ReactionDiffusion--uniform] A rule fed its past can still do nothing if the past has no difference in it anywhere. Give it a difference, a few cells of the second quantity in the middle of a field of the first, and feed it back, and it does what the figure shows.

![The hall's rule handed its own last frame: a ten-cell seed on a 256 by 256 field at feed 0.055 and kill 0.062, at the shader's diffusion rates and at the standard ones](/book-review/doc/book/figures/shaders/what-the-rule-would-do.png)

*The rule in the shader, ported and fed its own output. Top row: with the diffusion rates written in the shader, 0.16 and 0.08, the seed sits and never spreads, two tenths of a per cent of the field at two hundred frames and still at twelve thousand. Bottom row: at the rates this rule is usually run at, 1.0 and 0.5, the same feed and kill grow a coral that covers three tenths of the field after six thousand frames.*

So even with its picture handed back, the square's own numbers would not give you the coral its notes promise; the seed would sit. The spreading needs diffusion about six times faster than what is written, which is a fact for whoever builds the missing piece, not a fault in the rule. What the hall shows you is the exact shape of the missing piece: a rule that asks, every frame, where the last frame is, and a hall that does not answer.

The right square looks grown. Frost, or a crystal, branching from the centre and bright at its tips. Move GROWTH and the branches reach further; move DENSITY and they thicken. Its label says DLA, which elsewhere in this museum names particles wandering at random until they touch something and stick, one at a time, an aggregate that is nothing but its history.[^Shader_10_ReactionDiffusion--dla] This square keeps no history. Its code says so in its second line: it "simulates the visual appearance" of that growth using noise. Each pixel measures its distance and angle from the centre, adds noise to both, and lights up if it falls inside a radius that GROWTH sets. Turn GROWTH down and up: the branches do not retreat and regrow, they are drawn shorter and longer. It is a picture of an aggregate, asked from a position and the clock, like everything else in this sequence. Between the two squares you have the sequence's whole edge in one glance: on the right, a memory imitated with no memory; on the left, a memory asked for and not supplied.


The dark sphere stands between the two squares. It pulses from a number it keeps, on the processor, as it has in every hall. It has been the one thing with a past all along, and it was placed here as furniture.

What a shader answers to, then, across six halls: a position, a few numbers from a desk or a map, the clock, the angle to your eye, the lamps' directions, and a coordinate painted on. Not its neighbours. Not its own last frame, unless somebody builds the thing that hands it over, two pictures taking turns to be each other's past. Nothing in this sequence has done that. The next sequence begins with a board that does exactly it, one row at a time, and keeps every row.


Take the green with you. The next hall has one green cell on a board, and a rule for what happens to it.

[^Shader_10_ReactionDiffusion--unbound]: `shader_10_reactiondiffusion.gd` creates `ShaderMaterial.new()`, loads `commons/resourses/shaders/reaction_diffusion.gdshader`, and sets no parameter on it; the only `set_shader_parameter` calls in the script drive the DLA square's sliders. `uniform sampler2D prev_texture;` carries no default hint, and an unassigned sampler reads white. The square was captured on 25 September 2026 and is a flat (0, 1, 0).

[^Shader_10_ReactionDiffusion--uniform]: The rule ported to Python with the shader's numbers: diffusion 0.16 and 0.08, feed 0.055, kill 0.062, dt 1, and the same nine-cell Laplacian, centre -1, sides 0.2, corners 0.05. From a uniform white field the second quantity falls below 0.01 after 99 steps and the first rises above 0.99 after 137: red, with no structure anywhere, because the Laplacian of a uniform field is zero everywhere and the reaction has nothing to work on.

[^Shader_10_ReactionDiffusion--dla]: `dla_visual.gdshader`, lines 4 and 5: "DLA (Diffusion Limited Aggregation) visualization shader. Simulates the visual appearance of DLA growth using noise." The radius is `growth_radius = growth * (0.5 + 0.5 * angular_noise)` and a pixel is inside it or not by `smoothstep`. The particle-by-particle version stands in the pattern-generation halls, outside this sequence.

---
