# Duration and Residue

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

These dots can hold 4096 positions each. Beyond that, a new position replaces the oldest. Near the exit, another dot will let us meet that limit sooner.

## Move the place that draws

<!-- @draw_stick -->

Take the stick. Keep your fist nearly still and turn your wrist. The tip travels an arc. This tool uses the same recorder, but puts the sampling point at the end of a rod. A small turn can become a large mark.

The movement threshold is still five millimetres. We moved the place the recorder observes. Which part of your movement has the line begun to describe?

## A line you did not hold

<!-- @head_trace_projection -->

Put the tool down. Enter the outlined square beside the plinths. Lean a little, lower your head, then rise. Step outside the square and look back.

A pink line hangs where your head has been. A cyan line lies beneath it. Find the place where you lowered yourself. Can you find that movement in both?

The hand needed a tool. Here the point being followed is in the headset. You were making a line while looking for one.

Both views use the same retained positions. For the floor version, each position gives up its height:

```gdscript
return Vector3(p.x, FLOOR_Y, p.z)
```

`p` is a position measured relative to the square. X and Z remain; the floor height takes Y's place. Positions above one another meet on the same spot below. The line can keep where you went across the room while losing how low you bent.

Walk around what remains. Neither line has shoulders, a face, or a reason for leaning. Yet you may recognise something you just did. Which difference would another observer need in order to read it?

Return to the square to begin again. Try giving the floor line a bend. Then try moving without extending it. The same body can make more than one account of its passage.

## The pause leaves a line

<!-- @automatic_writing_desk -->

Come close to the small writing desk. Let the nib cross a little paper while you hold still. Lower your head, wait there, then rise. Your hands can remain empty.

Look for the waits in the writing. A level stretch can keep something the drawing dot left out.

At this desk, time moves the pen across the page. The height of your headset moves the mark above or below the row. The height at which you arrived becomes its starting level. Small movements still belong to the recording; stillness need not be perfectly straight.

```gdscript
_elapsed += delta
```

Each update adds the elapsed time. The nib keeps travelling while a measured height stays the same. Lower yourself and the line bends; stay lower and another level stretch can appear. We have given waiting a length.

The page can also have blanks. When measured input disappears, the clock can carry on without a mark. A horizontal line and an empty interval make different claims about what the instrument received.

A completed page waits. Step away and return to begin another. Give one pause more room than the last. Your reason for waiting stays with you.

## Touch the page

<!-- @whiteboard -->

Four pens and an eraser wait on the shelf beneath the whiteboard. These belong to the board. Take the red one and touch its nib to the face. Make a short stroke, lift the pen, cross a little space, and touch down again.

Your hand travelled across the gap. The picture leaves it white.

The pen writes within the board's edges and close enough to its face. Lift beyond that contact allowance, and the next touch begins a new stroke. Your hand keeps moving across the gap; the rule stops admitting it to the picture. You can use that interruption to give two marks some space.

The board brings the nib's world position into its own frame with `to_local(world_tip)`, then turns the accepted contacts into a painted image. The coloured pens have the familiar spacings. For now, try making something with the lift between strokes.

## A line with a short memory

<!-- @trace_short_memory -->

The amber point near the exit has room for thirty-two positions. Draw a loop, then lead it away. Small beads mark the positions the cord joins. Watch its far end.

At first you make more line. Then you begin to unmake it.

Hold your hand still. Does the remaining line wait with you?

This recorder uses the same movement gate as the first dot. We have given its list less room. When a new position takes it over that limit, the oldest goes:

```gdscript
if _trail_points.size() > trail_max_points:
    _trail_points.pop_front()
```

Here, `trail_max_points` is `32`. Waiting does not spend another place. Continuing the drawing can. Thirty-two positions are neither thirty-two seconds nor a fixed length of line.

Now try drawing with the loss. Give yourself a tail. Curl it around your other hand, then lead it elsewhere. The space you just marked can open again. What would you make with a line that follows you without keeping all of where you have been?

<!-- @ -->

Return to a line you want to keep. Release the drawing dot or stick after making it: that release is how we send a copy onward. With the amber dot, only the surviving positions travel. A whiteboard image is kept differently and will not take this route. The head trace and the desk's page stay in this hall.

We can carry the record forward. The movement that made it has already passed.[^point-trace-inscription] The copied positions can enter another program and be given another task.

In the next room, look for your bend. It may have grown.

[^point-trace-klee]: Paul Klee, [*Pedagogical Sketchbook*](https://openendedgroup.com/field2/assets/Klee_Paul_Pedagogical_Sketchbook_1960.pdf), translated by Sibyl Moholy-Nagy (1960 edition; German original 1925), opening section. Klee begins with an “active line on a walk” and a moving point. Ada makes the recording conditions part of that encounter: which point moves, when a position is accepted, and how retained positions become a line.

[^point-trace-sampling]: Claude E. Shannon, [“Communication in the Presence of Noise”](https://fab.cba.mit.edu/classes/S62.12/docs/Shannon_noise.pdf), *Proceedings of the IRE* 37, no. 1 (1949), 10–21, Theorem 1, gives a reconstruction result for band-limited signals sampled uniformly in time. It is a technical neighbour, not a guarantee for this trace: frame timing, a movement threshold and spatial rounding do not meet those assumptions. Joining retained positions with straight segments cannot by itself recover the intervening gesture.

[^point-trace-quantisation]: Godot’s [`snappedf`](https://docs.godotengine.org/en/4.6/classes/class_%40globalscope.html#class-globalscope-method-snappedf) returns the nearest multiple of a spacing. Here this quantises spatial components; it does not set a fixed temporal sampling rate. The separate movement gate determines whether to consider another reading. Changing either operation can alter the record, for different reasons.

[^point-trace-inscription]: Sigmund Freud’s [“A Note upon the ‘Mystic Writing-Pad’”](https://web.english.upenn.edu/~cavitch/pdf-library/Freud_WritingPad.pdf) (1925) and Jacques Derrida’s “Freud and the Scene of Writing,” in [*Writing and Difference*](https://press.uchicago.edu/ucp/books/book/chicago/W/bo27619783.html), translated by Alan Bass (1978), open a neighbouring inquiry into inscription, retention and the relation between a mark and what is no longer present. Here they open a question to pursue: what can a retained mark tell us about a movement that has already passed?
