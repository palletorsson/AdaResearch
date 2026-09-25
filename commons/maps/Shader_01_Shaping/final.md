# Why does the wave jump?

Your question can wait at the door. Five dark squares hang in a row along the wall, pictures two metres on a side, each with a desk in front of it, and one of the five is already moving with nobody at its desk. Begin with one that holds still.

<!-- @shader_01_shaping -->

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

Now push EDGE 0 past EDGE 1. The function is defined as a division by the distance between its two edges, and the language this panel is written in promises nothing about what happens when that distance turns negative.[^smoothstep] Whatever the square shows you now is not something the rule promised. You have walked to the edge of what it defines, and it was two slider-widths away.

The third square is the one that moves. FREQUENCY, AMPLITUDE, PHASE SPEED. A wave runs across it, and it ran before you arrived. Move AMPLITUDE: the wave grows or shrinks in place. Move FREQUENCY: the wave jumps. Not faster, not slower; it is suddenly somewhere else, and then runs on as before.

Now the slider the chapter is named for. Move PHASE SPEED by one notch. The wave leaps sideways, by an amount you could not have predicted, and continues. Move it back a notch: another leap, and not the reverse of the first. Then take your hands off the desk and watch for half a minute. The wave leaps on its own.

Here is the line:

```glsl
float func_val = 0.5 + amplitude * sin(frequency * uv.x * 6.28318 + TIME * phase_speed);
```

The wave's position is TIME multiplied by the speed. TIME is the museum's clock. The panel keeps no position of its own from one frame to the next; it asks the clock and multiplies. When you change the speed, every frame after that multiplies the whole clock by the new number, so the phase moves by the change in speed times however long the clock has been running. One notch of the slider is a tenth, and fifteen seconds into the clock's run that is a quarter of a wavelength, at once.[^leap] A wave that kept its own position could accelerate. This one cannot. It can only be asked again.

And the leap with nobody at the desk: this museum's clock wraps. It runs for thirty seconds and drops back to zero.[^rollover] At the default speed that drop moves the phase by thirty radians, four and three-quarter cycles, so the wave you are watching skips about a quarter of a wavelength twice a minute. Some of the moving surfaces in the halls ahead do the same at that moment. Some were written, by accident or on purpose, so that they do not. Watch for it.

The fourth square, EXPONENT, draws one curve from the bottom left corner to the top right. At one it is a straight line. Below one it bulges upward; above one it sags. Nothing here moves and nothing jumps: the exponent bends the same line in place. A curve is a decision about where the value collects, near zero or near one, and this desk lets you make it with one number.

The fifth square draws all four on one graph, a red step, a cyan S, a green wave and an orange curve, and a white line that blends them. The green one keeps moving among the three that hold still. That is the whole hall in one square: four rules for turning a position into a value, and one clock.

<!-- @dark_sphere -->

The dark sphere pulses beside the desks. Its pulse is driven from the other side of the museum's machinery, by a script that runs once a frame on the processor and remembers where it was.[^sphere] Stand between it and the wave. One of them has a past.

You came from halls where noise was made and then kept: a column of values, a voxel field, a wall. Nothing in this hall is kept. The graphs are asked, every frame, from nothing, and all they are asked with is a position, a few numbers from the desks, and the clock.

Everything in this hall is also flat, and hangs on a wall. The sequence begins with pictures. Two halls on it moves to bodies, and after that to rooms.

<!-- @ -->

The way out is a long one. The museum builds a crossing after every hall, a door, a run of open floor, and a second door offset to one side, and this hall has asked for its crossing to be fourteen rows deep instead of the usual seven.[^passage] Walk it slowly. The museum keeps only a hall or two built at any time; the rest is a plan on disk, and the crossing's corner is where the swap is hidden. A rule with no memory on the square, and a building that keeps two rooms around you. Take the wave's jump with you.

[^smoothstep]: The desk's line is `float y = smoothstep(e0, e1, x);`. The GLSL specification defines it as a clamped division by `e1 - e0` followed by a cubic, and states that the result is undefined when the first edge is not less than the second. What a particular graphics driver draws in that case is its own business.

[^leap]: The panel is `shaping_sin.gdshader`; the slider steps by 0.1. The phase is `TIME * phase_speed`, so a step of 0.1 taken t seconds into the clock's run moves the phase by 0.1 t radians: 0.08 of a wavelength at five seconds, 0.24 at fifteen, 0.46 at twenty-nine. Nothing about the leap is random. It is the clock's reading at the moment you moved.

[^rollover]: `project.godot` sets `rendering/limits/time/time_rollover_secs` to 30, so the shader clock TIME runs from 0 to 30 and wraps; Godot's own default is 3600. At phase speed 1.0 the wrap moves the phase by 30 radians, 4.77 cycles, a leap of 0.23 of a wavelength; at 2.0 it is 0.45, at 0.5 it is 0.39. Only a speed whose product with 30 is a whole number of cycles would hide it, and the slider's steps do not land on one.

[^sphere]: `dark_sphere.gd` drives its wobble and its emission pulse from `_process`, on the CPU, frame after frame, from values it keeps. The graphs keep nothing; they are functions of TIME.

[^passage]: `map_info.museum.passage` on this map is `{"kind": "chicane", "depth": 14}`. The museum's crossing rule (`endless_museum.gd`, `_authored_passages`): a door in this hall's last row, `depth` rows of crossing, a door where the next hall's own door is, then the next hall's first row copied, so that walking the last metre of the crossing you are already looking into the room you are entering. The default depth with a known next hall is 7. A chicane's middle rows open the whole span between the two doors, so when the doors sit at opposite corners the crossing is a room rather than a corridor. Palle, on first seeing one: "like a service corridor that can lead to other places."
