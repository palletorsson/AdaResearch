# Where are the seams?

The circle has left its frame. It crosses the floor, a cube, a column and a chair. Slide the pattern and watch the chair's outline: something moves without carrying the chair with it. Move the chair instead. With the pattern held in the room, another part of it falls across the seat. Attach it to the chair and the marks travel with their support.

You have met tilings before, including the loom's crossing threads and the cloth that can be opened into layers. There, a pattern depended on how parts met. Here the repeated mark needs no new thread or tile. That difference becomes visible when the image can pass across a chair without moving it.

The smaller rack along the wall keeps four dark squares in its first mode, each with a desk, and MODE and RESET at the left. Go to the first square.

<!-- @shader_05_patterns -->

A grid of shapes, five across and five down, each a little brighter or darker than its neighbours. The desk: GRID SIZE, SHAPE SIZE, ANIMATE. Take GRID SIZE down to one. One shape, filling the square. Now up, one notch at a time. Two across, then three, then twenty. The shapes get smaller, and the seams between them, the lines where one ends and the next begins, arrive with them.

There is a faint border drawn around each cell.[^border] But the border marks a division that already exists in the coordinates. Each sample multiplies its address by the grid size and keeps the fractional part. An address at 3.7 becomes 0.7, and so does one at 12.7. The same local position can now occur in many cells.

The seam is where that local coordinate begins again. It need not become a visible line. In the large circle installation, both sides of a cell boundary read the same background. In this smaller square, an extra border makes the division legible. We can draw attention to a boundary, or leave it unmarked, without changing where it falls.

The tiles are not quite identical, though. Each is tinted by a number made from the whole part before it was discarded, so the fold shows as a step in brightness.[^tint] Press ANIMATE and every shape breathes on its own phase, again from its whole part and the clock. One rule, twenty-five tiles, no two in step.

The second square is a labyrinth of arcs, and here the chapter's question has no answer you can point to. Look for a seam. Every arc crosses from one tile to the next without a kink. GRID and THICKNESS are on the desk, and SEED; move SEED and the whole labyrinth is another labyrinth, all at once, with the same property.

Each tile flips a coin from its address and, on heads, mirrors its own coordinate. Then it draws two quarter-circles from two opposite corners, each of radius one half. A quarter-circle of radius one half from a corner meets the tile's edges exactly at their midpoints, and so does its neighbour's, whichever way the neighbour flipped. The seams are still there, at every whole number. They are invisible because the rule was chosen so that both sides always agree at the midpoint. The word is Truchet; what it names is that agreement.

The third and fourth squares, OFFSET ROWS and BRICK, put the seam back and make it the subject. A brick wall is nothing but its joins. Every second row is slid half a tile before the fold, and the pattern you know from every wall outside this building appears.

Now press MODE. The four squares are replaced by three. The first is Wang tiles, and its desk claims something: an edge-matched tiling, with a slider called APERIODIC. Each tile's four edges are coloured, red, cyan, gold or green, from a number made of the tile's address and the edge. Take APERIODIC down to zero and look at any seam. The colour on this side and the colour on that side were chosen separately, and mostly differ. Now bring APERIODIC up to one. The seams agree.

They agree because each side paints its edge as the average of its own colour and the neighbour's, and the average of two things is the same from either side. No tile was chosen to fit its neighbour. The seam was painted to look as if one had. The desk's word, Wang, names a tiling whose tiles are picked so that their edges match; what this square does is the reverse, and the slider is the distance between the claim and the paint.[^wang]

The two Voronoi squares divide their images by proximity. Each pixel asks which of a scatter of points is nearest and colours itself by that, or by the difference between the nearest and the second nearest, which is zero exactly on the borders, so that the second of them is a picture of nothing but seams. The points still live in folded cells, one per cell, jittered. The seams you see are not those cells' edges but the borders the points make between themselves.

Press MODE again. Noise synthesis: a layered simplex field, a cellular distance field, a warped lookup. Their visible boundaries no longer follow the same repeated square. In the first, weighted contributions from a triangular lattice meet smoothly. In the second, the nearest point can change as you cross an edge. The third bends the coordinates before reading them. A surface can look continuous without those three operations being the same.[^smooth]

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

[^tint]: `patterns_tile.gdshader`: `tile_color = shape_color * (0.7 + 0.3 * fract(sin(dot(tile_id, vec2(12.9898, 78.233))) * 43758.5453))`, where `tile_id = floor(uv)` is the whole part the fold discarded. The animation is `1.0 + animate * 0.3 * sin(TIME + tile_id.x * 1.3 + tile_id.y * 0.7)`, and it leaps at the clock's wrap like the first hall's wave.

[^wang]: `patterns_wang.gdshader`. `edge_type(tile_id, edge)` hashes the tile's address with the edge's index, so a tile's north edge and its northern neighbour's south edge are independent draws. At `aperiodic_mix` = 1 the mix weight is 0.5 and both sides of every seam show the same average; at 0 each shows its own draw. The desk's default is 1.

[^smooth]: This rack uses `patterns_noise.gdshader`, not the basin's `fbm_basic.gdshader`. Its three modes use `simplex2d`, `worley`, and a domain-warped simplex lookup respectively. A square-lattice value-noise helper is also present but unused by these modes; its interpolation must not stand in for their different calculations. The separate Voronoi study searches nearby cell points for its two distances.
[^border]: `patterns_tile.gdshader` adds a narrow, low-intensity band near each cell edge. Its tile tint and optional animation are separate operations. The larger passage's `repeated_mask.gdshader` has no added cell border.
