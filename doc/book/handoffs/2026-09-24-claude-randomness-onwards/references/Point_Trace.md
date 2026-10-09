Bring the detour.

There was time between the ends. We passed through it. Let the next line try to keep something of the passage.[^point-trace-klee]

## Let the hand leave a line

<!-- @draw_dot -->

The drawing points wait on their plinths. Take the first dot and draw a short loop in the air. Pause with it still in your hand. Beside the line, a small instrument tilts its face towards reading: a count above a table of positions.

Watch during the pause. Does another point enter merely because time passes?

Move again. Give the loop a tail, then release the dot. Your hand can rest while the line stays. Something of the movement has become available to look at from another side.

The count comes from a list:

```gdscript
var point_count = _trail_points.size()
```

`_trail_points` holds positions in the order they were kept; `size()` counts them. The recorder joins each position to the next with a straight segment. Repeated in small enough steps, the two-point construction from the last room lets us see a curve. The gesture has acquired joints. Between those joints, the program draws a connection; your hand may have taken another way.[^point-trace-sampling]

The recorder waits for at least five millimetres of movement before considering another position. A still pause can leave the count unchanged while Point One's counter keeps running. You spend time holding the line still; the position list does not say how long you waited.

Pickup, tracking, drawing, the letters on the screen: more code is running than we can read here. We follow the movement gate because it answers the question our hand just asked.

Read two neighbouring rows. Each gives three coordinates, in world metres, for a retained position. When the count reaches eleven, the table starts at row 2: it has room to show only the last ten. The drawing still has its beginning. What has left the screen has not yet left the line.

## Another resolution, another gesture

Try the other drawing dots. Red rounds positions to a 10 mm grid, green to 40 mm, blue to 80 mm. The first dot adds no such grid. Read the instrument to find which rule you are holding.

Repeat a small bend with the blue dot. Then enlarge the movement until another turn appears. Your wrist is negotiating with a spacing. A gesture that one recorder can distinguish may need to become larger for another.

The grid operation is small enough to read. With `rec` as a position and `s` as the spacing in metres:

```gdscript
rec = Vector3(snappedf(rec.x, s), snappedf(rec.y, s), snappedf(rec.z, s))
```

With the blue dot, `s` is `0.08`: an X reading of `0.05` metres is stored as `0.08`. The program rounds Y and Z in the same way. If the resulting position matches the last one kept, it adds nothing to the list. Passing the five-millimetre movement test does not guarantee a new corner; the grid can send different readings to the same address.[^point-trace-quantisation]

The saved positions lie on the grid, but the segments between them can cut across it diagonally. Look for a diagonal in your drawing. A grid of corners does not require a drawing made only of right angles.

Now give the coarse recorder something it might do well. Make a corner you can return to. Let your hand wander while one address stays steady, then find the edge where it changes. The same interval that swallowed a small flourish can help you repeat a shape. What kind of drawing do you want to make with it?

The list can hold 4096 positions. Keep drawing beyond that and each new position replaces the oldest: the line can begin to lose its beginning. You do not have to fill it now. Looking at the line need not spend another place in it.

## Move the place that draws

<!-- @draw_stick -->

Take the stick. Keep your fist nearly still and turn your wrist. The tip travels an arc. This tool uses the same recorder, but puts the sampling point at the end of a rod. A small turn can become a large mark.

The movement threshold is still five millimetres. We moved the place the recorder observes. Which part of your movement has the line begun to describe?

## Touch the page

<!-- @whiteboard -->

Four pens wait on the shelf beneath the whiteboard. These belong to the board. Take the red one and touch its nib to the face. Make a short stroke, lift the pen, cross a little space, and touch down again.

Your hand travelled across the gap. The picture leaves it white.

The pen writes within the board's edges and close enough to its face. Lift beyond that contact allowance, and the next touch begins a new stroke. Your hand keeps moving across the gap; the rule stops admitting it to the picture. You can use that interruption to give two marks some space.

The board brings the nib's world position into its own frame with `to_local(world_tip)`, then turns the accepted contacts into a painted image. The coloured pens have the familiar spacings. For now, try making something with the lift between strokes.

<!-- @ -->

Return to a line you want to keep. Release the drawing dot or stick after making it: that release is how we send a copy onward. A whiteboard image is kept differently and will not take this route.

We can carry the record forward. The movement that made it has already passed.[^point-trace-inscription] The copied positions can enter another program and be given another task.

In the next room, look for your bend. It may have grown.

[^point-trace-klee]: Paul Klee, [*Pedagogical Sketchbook*](https://openendedgroup.com/field2/assets/Klee_Paul_Pedagogical_Sketchbook_1960.pdf), translated by Sibyl Moholy-Nagy (1960 edition; German original 1925), opening section. Klee begins with an “active line on a walk” and a moving point. Ada makes the recording conditions part of that encounter: which point moves, when a position is accepted, and how retained positions become a line.

[^point-trace-sampling]: Claude E. Shannon, [“Communication in the Presence of Noise”](https://fab.cba.mit.edu/classes/S62.12/docs/Shannon_noise.pdf), *Proceedings of the IRE* 37, no. 1 (1949), 10–21, Theorem 1, gives a reconstruction result for band-limited signals sampled uniformly in time. It is a technical neighbour, not a guarantee for this trace: frame timing, a movement threshold and spatial rounding do not meet those assumptions. Joining retained positions with straight segments cannot by itself recover the intervening gesture.

[^point-trace-quantisation]: Godot’s [`snappedf`](https://docs.godotengine.org/en/4.6/classes/class_%40globalscope.html#class-globalscope-method-snappedf) returns the nearest multiple of a spacing. Here this quantises spatial components; it does not set a fixed temporal sampling rate. The separate movement gate determines whether to consider another reading. Changing either operation can alter the record, for different reasons.

[^point-trace-inscription]: Sigmund Freud’s [“A Note upon the ‘Mystic Writing-Pad’”](https://web.english.upenn.edu/~cavitch/pdf-library/Freud_WritingPad.pdf) (1925) and Jacques Derrida’s “Freud and the Scene of Writing,” in [*Writing and Difference*](https://press.uchicago.edu/ucp/books/book/chicago/W/bo27619783.html), translated by Alan Bass (1978), open a neighbouring inquiry into inscription, retention and the relation between a mark and what is no longer present. A list of coordinates is not Derrida’s philosophical trace or a model of psychic memory. The connection here is a question to pursue, not an identity between these concepts.
