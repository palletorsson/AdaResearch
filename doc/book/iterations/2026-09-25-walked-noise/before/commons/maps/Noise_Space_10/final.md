# Which way will carry you?

<!-- @noise_space -->

Two pairs of glowing turquoise posts face each other across the ground. A gold line joins them. The far opening looks close enough. Before entering, follow the line with your eyes. Where would you expect your pace to change?

The previous sphere surrounded us with a changing field while its floor stayed still. Here the answer reaches the ground itself. Take the ramp onto the dark margin. The instrument stands along its side, leaving the route open.

At HEIGHT 0.25, try walking between the posts. A small dip can disappear from the far view and return under your feet. The colour gathers into contours, but your body meets a surface. Keep those two ways of reading it in play.

Return to the margin. Press HEIGHT until it reads 0.90 and look for the feature you just crossed. The posts have not moved. The field has not been drawn again from another seed. Try the same approach.

In the recorded desktop walk, the first crossing reached the far margin. At 0.90, the same forward input, held for the same time, left the body partway across. That is an observation about one body, one approach and two settings. It leaves other ways through the terrain to be found. A line drawn across the ground has made a proposal; it has not given the body permission to follow it.

Press RESET from the margin. The lower terrain returns, with route A and the first sample selected. HEIGHT and RESET refuse while a player body is still on the patch: the press is dropped, not saved, and the readout asks you to return to the margin. We make the alteration from a place that remains steady enough to compare what changed.

The current height rule is short:

```gdscript
func ground_at(p: Vector2) -> float:
	var value: float = noise.get_noise_2d(p.x * noise_scale, p.y * noise_scale)
	return 1.0 + height_scale * edge_weight(p) * value
```

The value is signed. It can lower a point below the one-metre reference as well as raise it above. HEIGHT selects zero, 0.25, 0.65 or 0.90 as the multiplier. At zero, the ground becomes level. The noise calculation still has an answer; its contribution to height has become zero.

The seed and the field's other settings stay fixed while HEIGHT changes how much of the same variation reaches the ground. We have held the source still enough to feel what one multiplication changes.[^walk-recipe]

There is a second multiplier in the code. Look at the place where green ground meets the dark margin. Even at the largest height setting, the two join at the same level.

```gdscript
func edge_weight(p: Vector2) -> float:
	var distance_to_edge: float = minf(4.0 - absf(p.x), 4.0 - absf(p.y))
	return smoothstep(0.0, 0.75, distance_to_edge)
```

The last three-quarters of a metre gradually withhold the noise's contribution. At the edge, that contribution is zero. The margin did not emerge from the field. We made it, so a body could enter and so the place from which we compare would remain available. The transition is part of the landscape's construction.

Now choose ROUTE B. A gold line takes a longer way through the same patch. Nothing in the ground moves when the line changes. Follow it to the instrument, where the proposed route has become a section: distance across the plan runs horizontally, ground height vertically. SAMPLE moves a yellow witness along both the section and the terrain.

The display gives the length and steepest sampled stretch of whichever proposed route is selected. At the lower setting, B is longer and includes a slightly steeper stretch. The detour has changed what the body would meet. It has not promised an easier passage.

The section follows a line; your body has width. It can meet a slope beside the line, and its controller brings rules of its own. The recorded desktop body accepted floor angles up to forty-five degrees. Increasing HEIGHT took the steepest sampled stretch of route A from below that limit to above it.[^walk-measurements] That stretch is a descent, and the body got past it; the walk ended at the foot of the climb out of the hollow it leads into, where several sampled stretches also exceed the limit. That helps us ask why this walk fell short. It does not tell us that no body could pass.

Look down at the yellow witness. Its printed height belongs to the triangle under that point. The terrain is made from 81 by 81 sampled positions, spaced ten centimetres apart. Between those positions, triangles supply a surface. Sampling the noise again between the vertices can give a slightly different answer: the collider is the constructed mesh, not an infinitely detailed function.

```gdscript
var mesh = create_mesh_from_heights(heights)
mesh_instance.mesh = mesh
create_collision_from_mesh(mesh)
```

The same mesh is sent to sight and collision. This is the extra connection the small relief spheres did not have. A displayed height can now catch a foot.

Find a place where the ground seems to fold over itself. Move sideways and look again. Every horizontal position in this heightfield receives one ground height. A cave would need a floor and a roof at some of the same positions. We would have to give the representation something else to hold. Carry the occupied volume from Noise Voxel back into this question.

The crease that catches one body might shelter another. This instrument tests walking; shelter would ask us to place another body and a line of sight. The same terrain can support questions that a successful crossing does not settle. We can learn its construction and still discover another use for what resisted us.

<!-- @dark_sphere -->

The dark orb hovers beside the raised margin. Its pulse continues while you compare routes or return the terrain to its starting height. RESET has a local reach. It does not recover the time spent choosing a way across.

The margin, the terrain and the orb hold different relations to change. One offers a steady place to return to; one changes when its height multiplier changes; one keeps time. A shared computational world can let those differences coexist, provided we say where each operation acts.

<!-- @ -->

In Noise Perlin Simplex, the next comparison changes the generator. Bring the habit of holding a question steady: if two surfaces differ, which operation changed, and which body makes that difference matter?

[^walk-recipe]: The fixed recipe uses OpenSimplex2S, seed zero, four fBM octaves, gain 0.5 and lacunarity 2. Generator frequency is 0.1 and input coordinates are multiplied by five. HEIGHT changes the later multiplier.

[^walk-measurements]: The desktop record of 13 September 2026 measured routes A/B at approximately 8.13/10.40 metres for HEIGHT 0.25; their steepest sampled segments were about 24.18°/25.22°. Route A reached about 58.26° at HEIGHT 0.90. The tested controller used a 45° floor-angle limit. The same forward input, held for the same time, crossed at 0.25 and ended partway across at 0.90; the record keeps only each walk's start and end. A sampled line and one desktop trajectory do not establish every route or body's possibilities.
