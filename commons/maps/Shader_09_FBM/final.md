# What carries you over the water?

Water lies across the hall, and you are meant to walk on it. Not through it: on it. A pane of glass, flush with the floor and six centimetres thick, covers a pool seven metres long and three wide, and the water moves thirty-five centimetres beneath the pane.[^basin] Beyond the pool stand four dark squares with desks, and a rack by the door. Cross the pool first.

<!-- @basin_water -->

Stop in the middle of the glass and look down. The surface under your feet is the darkest part of the pool; further off it pales toward a milky blue-green. Now walk to the far end and look back. The dark part has come with you. It is always under your feet, and the pale part is always at a distance.

Nothing in the pool changed when you moved. What changed is the angle at which each point of the surface meets your eye. The water's colour is decided, at every pixel, from that angle: steep, and it answers with the deep colour; shallow, and it answers with the pale one, and with less of it, since the pale water is also the more transparent.[^fresnel] You met this in the pillar hall as a rainbow on the rim of a ring. Here it is the whole surface, and the rim is wherever you are not.

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

Now stand still for a minute and watch the water and the first square beyond it together. Twice in that minute the square's noise leaps. The water does not. Both are asked from the same clock, and the clock wraps every thirty seconds, as you saw in the first hall. The square was not written for that. The water was: each of its three wave rates is rounded to a whole number of cycles per thirty seconds, fourteen, twenty-one and thirty-two, and its noise drifts round a circle once per wrap, so that at the moment the clock drops to zero the surface is exactly where it was when the clock started.[^wrap] The difference between a surface that leaps and one that does not is not a memory. It is arithmetic done in advance.

There is no desk for the water. Its numbers are written into the map, in the token that places it:

```
basin_water:0:0#width:7#depth:3
```

Width and depth are the pool's; amplitude, wavelength, speed and the noise's share keep their defaults, and `calm:on` would still it into a mirror. Whoever edits the map edits the water. Nobody in the hall can.

So, what carries you. The glass does. It is a slab the museum lays over every cell of the pool, with a collider of its own, and the museum counts it as floor you can walk.[^lid] The water has no collider at all. It is a picture that happens to lie under a floor. Had the map asked for the pool without its lid, the museum would have left it open, to be stepped into by a wedge, and you would stand in the water and it would lift through your shins without touching you. What you are looking at and what holds you up are two different constructions, and only one of them knows you are there.

<!-- @shader_09_fbm -->

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

<!-- @library_rack -->

The rack by the door: the same forty entries.

<!-- @dark_sphere -->

The dark sphere stands between the pool and the squares. It pulses from a number it keeps. Behind you the water moves from a number it reads; in front of you the noise drifts from the same number and leaps twice a minute.

<!-- @ -->

Next, a floor. Take the glass with you: the thing you walked on was not the thing you looked at.

[^basin]: `map_info.museum.basin` on this map is `{"depth": 1.2, "glass": true, "rects": [[3, 1, 7, 3]]}`: cells x 3..9, z 1..3. The museum (`endless_museum.gd`) sinks each cell in the rect: a pool floor slab a basin-depth down, side walls where the pool meets ground, and a glass lid 6 cm thick with its top flush with the deck. The water is `basin_water:0:0#width:7#depth:3` at cell (6, 2), the rect's centre; the artifact's origin is the lid and the plane sits at `lift` = -0.35 m.

[^fresnel]: `basin_water.gdshader`, fragment: `facing = dot(NORMAL, VIEW)`, `fres = pow(1.0 - facing, 3.0)`, colour `mix(deep_color, shallow_color, fres)`. Deep is (0.06, 0.20, 0.30) at alpha 0.86; shallow is (0.38, 0.64, 0.72) at alpha 0.55. The alpha travels with the colour.

[^wrap]: Measured on a port of the shader over the 7 x 3 m pool at the map's values: crests 10.9 cm, RMS height 4.24 cm, RMS vertical speed 15.2 cm/s, periods 2.14, 1.43 and 0.94 s; 49 x 49 = 2401 vertices, 14.6 cm apart along the pool and 6.25 cm across it. The three rates are `wrap_rate(w)`, that is `floor(w * 30 / TAU + 0.5) * TAU / 30`: 14, 21 and 32 whole cycles per rollover. The largest difference between the surface at t = 30 s and at t = 0 s is zero to four decimal places of a millimetre. The rollover is read from `project.godot` by `basin_water.gd` and handed to the shader.

[^lid]: In `endless_museum.gd` a glass basin cell gets a box at y = -0.03 of size 1 x 0.06 x 1, its collider, and `_walk_cells[...] = true`; an open one (`glass: false`) gets no walk cell and no deck floor and is entered by wedge. `basin_water.gd` builds one `MeshInstance3D` and nothing else.
