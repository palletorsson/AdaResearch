# Where are the seams?

A floor, again. You have met tilings before, whole halls of them, and there a pattern was a thing with parts: pieces, and the joins between them. This hall has four dark squares, a desk under each, and a tilted panel at the left end with two buttons, MODE and RESET. Leave the buttons. Go to the first square.

<!-- @shader_05_patterns -->

A grid of shapes, five across and five down, each a little brighter or darker than its neighbours. The desk: GRID SIZE, SHAPE SIZE, ANIMATE. Take GRID SIZE down to one. One shape, filling the square. Now up, one notch at a time. Two across, then three, then twenty. The shapes get smaller, and the seams between them, the lines where one ends and the next begins, arrive with them.

Where are they? Not drawn. There is no line in the code for a seam. Here is what each pixel does:

```glsl
vec2 uv = UV * grid_size;
vec2 tile_uv = fract(uv) - 0.5; // centered -0.5 to 0.5
```

The pixel multiplies its position by the grid size and throws the whole-number part away. A pixel at 3.7 becomes 0.7, and so does one at 12.7. After that line every pixel believes it is inside the one and only tile, and draws the shape accordingly. The seams are where the whole numbers were thrown away: fold lines in a coordinate, not the edges of a piece. Nothing was copied five times. Every pixel folded its own address.

The tiles are not quite identical, though. Each is tinted by a number made from the whole part before it was discarded, so the fold shows as a step in brightness.[^tint] Press ANIMATE and every shape breathes on its own phase, again from its whole part and the clock. One rule, twenty-five tiles, no two in step.

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

They agree because each side paints its edge as the average of its own colour and the neighbour's, and the average of two things is the same from either side. No tile was chosen to fit its neighbour. The seam was painted to look as if one had. The desk's word, Wang, names a tiling whose tiles are picked so that their edges match; what this square does is the reverse, and the slider is the distance between the claim and the paint.[^wang]

The two Voronoi squares have no tiles to fold. Each pixel asks which of a scatter of points is nearest and colours itself by that, or by the difference between the nearest and the second nearest, which is zero exactly on the borders, so that the second of them is a picture of nothing but seams. The points still live in folded cells, one per cell, jittered. The seams you see are not those cells' edges but the borders the points make between themselves.

Press MODE again. Noise synthesis: the layered noise of the basin hall, a Worley variant, a domain warp. No seams anywhere, and yet the noise is built on the same fold, a lattice of whole numbers with a random value at each corner. The seams are hidden by the interpolation between corners, whose slope was chosen to be zero at every corner, so that the surface passes over each fold without a crease.[^smooth]

So the floor returned, and it has no parts. There are seams at every whole number of every square in this hall. Some are shown, as the tile's step in brightness and the brick's mortar. Some are agreed away, as Truchet's midpoints. Some are painted over, as Wang's averages. Some are smoothed, as the noise's zero slopes. None is a join between two things, because there are no two things: there is one rule, asked at every pixel, and a coordinate that was folded before the rule saw it.

<!-- @library_rack -->

The rack by the door, the same index.

<!-- @dark_sphere -->

The dark sphere stands in front of the squares. It has no seams because it is one mesh. Everything behind it has seams because it is one function.

<!-- @ -->

Press RESET if you have lost the defaults. The next hall has no desks at all. Take the painted seam with you, the one that agreed only because both sides averaged.

[^tint]: `patterns_tile.gdshader`: `tile_color = shape_color * (0.7 + 0.3 * fract(sin(dot(tile_id, vec2(12.9898, 78.233))) * 43758.5453))`, where `tile_id = floor(uv)` is the whole part the fold discarded. The animation is `1.0 + animate * 0.3 * sin(TIME + tile_id.x * 1.3 + tile_id.y * 0.7)`, and it leaps at the clock's wrap like the first hall's wave.

[^wang]: `patterns_wang.gdshader`. `edge_type(tile_id, edge)` hashes the tile's address with the edge's index, so a tile's north edge and its northern neighbour's south edge are independent draws. At `aperiodic_mix` = 1 the mix weight is 0.5 and both sides of every seam show the same average; at 0 each shows its own draw. The desk's default is 1.

[^smooth]: `fbm_basic.gdshader`, `noise()`: `u = f * f * (3.0 - 2.0 * f)` is the interpolation weight, whose derivative is zero at f = 0 and at f = 1, so the value crosses each lattice line with a continuous slope. The lattice is `floor(p)`, the same fold as the tile square's.
