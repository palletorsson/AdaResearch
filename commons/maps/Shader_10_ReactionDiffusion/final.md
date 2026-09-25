# Where is the last frame?

Two squares, larger than the others in the sequence, and one desk. The left square is green. Not a pattern in green: green, edge to edge, one colour, and it does not change while you watch it. Its label says Reaction-Diffusion. The right square is a cyan frost branching from its centre, and its desk has three sliders, SCALE, GROWTH, DENSITY. Everything in this hall points at the green one. Start there.

<!-- @shader_10_reactiondiffusion -->

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

And it is green edge to edge because it is never given what it drew. The hall's script builds the square, loads the shader, and hands it nothing for `prev_texture`.[^unbound] A texture nobody assigns reads as white: both quantities are one, everywhere. Run the rule once on that. The reaction term is one, the first quantity drops to zero, the second stays at one, and the colour is (0, 1, 0). Green. Next frame the rule asks for its last frame again, is given the same white again, and computes the same green again. It has a past written into it and no past handed to it, so it repeats its first step forever.

Suppose the hall did hand it its own picture. From the white start the two quantities would decay evenly, everywhere at once, and within about a hundred frames the square would be red and stay red.[^uniform] A rule fed its past can still do nothing if the past has no difference in it anywhere. Give it a difference, a few cells of the second quantity in the middle of a field of the first, and feed it back, and it does what the figure shows.

![The hall's rule handed its own last frame: a ten-cell seed on a 256 by 256 field at feed 0.055 and kill 0.062, at the shader's diffusion rates and at the standard ones](/book-review/doc/book/figures/shaders/what-the-rule-would-do.png)

*The rule in the shader, ported and fed its own output. Top row: with the diffusion rates written in the shader, 0.16 and 0.08, the seed sits and never spreads, two tenths of a per cent of the field at two hundred frames and still at twelve thousand. Bottom row: at the rates this rule is usually run at, 1.0 and 0.5, the same feed and kill grow a coral that covers three tenths of the field after six thousand frames.*

So even with its picture handed back, the square's own numbers would not give you the coral its notes promise; the seed would sit. The spreading needs diffusion about six times faster than what is written, which is a fact for whoever builds the missing piece, not a fault in the rule. What the hall shows you is the exact shape of the missing piece: a rule that asks, every frame, where the last frame is, and a hall that does not answer.

The right square looks grown. Frost, or a crystal, branching from the centre and bright at its tips. Move GROWTH and the branches reach further; move DENSITY and they thicken. Its label says DLA, which elsewhere in this museum names particles wandering at random until they touch something and stick, one at a time, an aggregate that is nothing but its history.[^dla] This square keeps no history. Its code says so in its second line: it "simulates the visual appearance" of that growth using noise. Each pixel measures its distance and angle from the centre, adds noise to both, and lights up if it falls inside a radius that GROWTH sets. Turn GROWTH down and up: the branches do not retreat and regrow, they are drawn shorter and longer. It is a picture of an aggregate, asked from a position and the clock, like everything else in this sequence. Between the two squares you have the sequence's whole edge in one glance: on the right, a memory imitated with no memory; on the left, a memory asked for and not supplied.

<!-- @library_rack -->

The rack by the door, the same forty entries, for the last time.

<!-- @dark_sphere -->

The dark sphere stands between the two squares. It pulses from a number it keeps, on the processor, as it has in every hall. It has been the one thing with a past all along, and it was placed here as furniture.

What a shader answers to, then, across six halls: a position, a few numbers from a desk or a map, the clock, the angle to your eye, the lamps' directions, and a coordinate painted on. Not its neighbours. Not its own last frame, unless somebody builds the thing that hands it over, two pictures taking turns to be each other's past. Nothing in this sequence has done that. The next sequence begins with a board that does exactly it, one row at a time, and keeps every row.

<!-- @ -->

Take the green with you. The next hall has one green cell on a board, and a rule for what happens to it.

[^unbound]: `shader_10_reactiondiffusion.gd` creates `ShaderMaterial.new()`, loads `commons/resourses/shaders/reaction_diffusion.gdshader`, and sets no parameter on it; the only `set_shader_parameter` calls in the script drive the DLA square's sliders. `uniform sampler2D prev_texture;` carries no default hint, and an unassigned sampler reads white. The square was captured on 25 September 2026 and is a flat (0, 1, 0).

[^uniform]: The rule ported to Python with the shader's numbers: diffusion 0.16 and 0.08, feed 0.055, kill 0.062, dt 1, and the same nine-cell Laplacian, centre -1, sides 0.2, corners 0.05. From a uniform white field the second quantity falls below 0.01 after 99 steps and the first rises above 0.99 after 137: red, with no structure anywhere, because the Laplacian of a uniform field is zero everywhere and the reaction has nothing to work on.

[^dla]: `dla_visual.gdshader`, lines 4 and 5: "DLA (Diffusion Limited Aggregation) visualization shader. Simulates the visual appearance of DLA growth using noise." The radius is `growth_radius = growth * (0.5 + 0.5 * angular_noise)` and a pixel is inside it or not by `smoothstep`. The particle-by-particle version stands in the pattern-generation halls, outside this sequence.
