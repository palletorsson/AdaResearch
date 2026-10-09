Your hand may have been here before you.

If you released a drawing dot or stick in Trace, a copy of its retained positions can arrive ahead of you. Look for the line over the ruled field. A small movement may now occupy enough space to suggest a route. Keep it in view while we learn what a grid can help us do with it.

## Hold a place

<!-- @grab_sphere_point_snap -->

Pick up the snapping sphere. Move it a little, then a little more. Follow its drawing marker and read the ground table. Can your hand move while the retained line admits no new place?

This tool uses a five-centimetre grid. Along one axis, a sequence of stored positions might read `0.10`, `0.15`, `0.20` metres. Their grid indices would be `2`, `3`, `4`: count the spacings from zero, or measure them in metres. Two readings of the same position.

Release the sphere and compare the marker with the last retained row. The marker aligns to the lattice on release. The grid gives a place you can return to, with an interval around it in which small differences can share an address.

## Let a walk draw

<!-- @player_trace -->

Walk a small loop beside the recorder, then a wider diagonal. Look behind you. One path keeps a finer sampled reference; the other rounds positions onto a one-metre lattice. Both are drawings made from readings of movement.

In the headset, try leaning with your feet planted, then standing upright and taking a step. The paths can respond to both. The recorder uses the headset's horizontal position and the rig origin's height. It needs some point to follow before it can call the result a path.

The recorder brings that position into its own frame. Then it rounds the horizontal components:

```gdscript
local_point.x = roundf(local_point.x / seam_grid) * seam_grid
local_point.z = roundf(local_point.z / seam_grid) * seam_grid
```

Divide by the spacing, round to an integer, multiply back. At one-metre spacing, several nearby positions become the same address. Near the boundary between two rounding regions, a small movement can change that address by a metre.

Find an edge by moving slowly. Cross it and return. Give the change a rhythm. Then find room to move while keeping one address steady. There is a dance available on either side of the rule: using the jump, inhabiting the interval.

The line connects successive retained positions, sometimes diagonally across places you did not traverse. You can return to a place and add another part of the journey; this is an ordered path, rather than a single mark for each visited cell. The record gives us a construction we can compare with our walk.

## A gesture becomes a score

<!-- @grid_lines -->

Return to the ruled field and look for the bend you made in Trace. If the instrument reports no released trace, make a line there with at least two retained points, let go of the dot or stick, and return. The release supplies the copy. The whiteboard's ink and the path now growing behind you are separate records.

Pink carries the received shape after recentering and enlargement. Green rounds that displayed shape again. Find one small turn in pink and follow what green does with it.

The display starts with the midpoint of the source's bounding box, `center`. It subtracts that centre from each position `p` and multiplies the result by `final_scale`:

```gdscript
mesh.surface_add_vertex((p - center) * final_scale)
```

A small trace is enlarged five times. A larger one is scaled less if necessary to fit within five metres along its longest dimension. The stored positions remain available; the display makes another set of positions from them. Green applies its grid afterward, with six intervals per metre along each displayed axis.

Look back at your hand. A little bend of the wrist has acquired another extent. Imagine another body following it. What was easy to draw might ask for a detour; a turn made without thought might become the part someone else wants to repeat.

This is one reason to keep a record: it can become useful for something we did not do the first time. We could treat the enlarged line as a score. We would still have to decide how to read it together—where to begin, what counts as following, how much room to leave for another person's movement.

The instrument's coordinate rows describe the source positions, even while the line stands somewhere else at a different scale. Follow a row, then look up. A number needs its frame; an instruction needs someone to interpret it. The shared record does not settle either relation by itself.

Below the glass, five-by-five cells continue across the lowered basin. The museum's glass supports you above the ruled field. The lines have no collision surface of their own. A grid can supply addresses for building; something else must make a floor that carries a body.

<!-- @floating_sphere_field -->

Small spheres drift while your path is being recorded. Their movement accompanies yours without entering that recorder. The room has more going on than one instrument follows.

<!-- @room_grammar -->

A plan generated by rules brings the question to walls and doors. An address lets us place something. We still have to make an approach to it, leave room beside it, decide what kinds of bodies should be able to pass. A plan can hold an arrangement before anyone has found a way to inhabit it.

<!-- @plan_vitrine -->

Step into the glass enclosure around the small five-by-five plan beside the main gallery. Count a row, then a column. Twenty-five cells, each one metre across. Their numbers run from zero to four along each direction.

Walk across a row and cut diagonally. These edges can help us place objects without becoming walls for our bodies. Here a cube could stand; beside it, a wedge could become a ramp. A few relations could begin to make a level. The line that asked you to follow now gives you places to compose.

<!-- @ -->

Keep a purpose for your path: accompanying someone, returning to a view, making a loop for its own pleasure. The coarse record may be enough to share part of that purpose. You may want to add something—a time, a word, another position—or leave the record open to another interpretation.

We began with a location. A line offered a relation; a trace kept positions from a movement; a grid made places comparable and available for another construction. Each gives us more to work with, and another choice about what matters.

The next room adds a third point. We can return a path to its beginning. What else must we make before that closed boundary becomes a face?
