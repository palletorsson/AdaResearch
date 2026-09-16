Bring the detour.

There was time between the ends. We passed through it. Let the next line try to keep something of the passage.

## Let the hand leave a line

<!-- @draw_dot -->

The drawing points wait on their plinths. Take the first dot and draw a short loop in the air. Pause with it still in your hand. Beside the line, a small instrument tilts its face towards reading: a count above a table of positions.

Watch during the pause. Does another point enter merely because time passes?

Move again. Give the loop a tail, then release the dot. Your hand can rest while the line stays. Something of the movement has become available to look at from another side.

The count comes from a list:

```gdscript
var point_count = _trail_points.size()
```

Each accepted position occupies a place in that ordered list. The recorder joins neighbouring positions with straight segments. Enough small segments can let us see a curve. Go closer to a turn: the smooth-looking gesture has acquired joints. The connection between two samples has been drawn; it is not a measurement of everything your hand did between them.

The dot waits for at least five millimetres of movement before considering another sample. Below that movement threshold, the update can return without adding a position. A stationary pause can leave the list unchanged while Point One's counter has plenty more calls to count.

Pickup, tracking, drawing, the letters on the screen: more code is running than we can read here. We follow the movement gate because it answers the question our hand just asked.

Read two neighbouring rows. The coordinates give places in world metres. If your loop has more than ten points, its first row may have left the table: the instrument shows the last ten, while the larger count names the whole retained list. The line can hold something its small window is no longer showing.

## Another resolution, another gesture

Try the other drawing dots. Red rounds positions to a 10 mm grid, green to 40 mm, blue to 80 mm. The first dot adds no such grid. Read the instrument to find which rule you are holding.

Repeat a small bend with the blue dot. Then enlarge the movement until another turn appears. Your wrist is negotiating with a spacing. A gesture that one recorder can distinguish may need to become larger for another.

The grid operation is small enough to read. With `rec` as a position and `s` as the spacing in metres:

```gdscript
rec = Vector3(snappedf(rec.x, s), snappedf(rec.y, s), snappedf(rec.z, s))
```

Each component moves to the nearest multiple of the spacing. If the result repeats the last stored position, the recorder does not add it again. The movement gate decides whether to consider a reading; the grid helps decide where that reading can stand. These are different choices.

The segments can cross the grid diagonally. Follow one of those shortcuts. Even the finest dot reads positions during successive calls while the rest of the museum runs between them.

Now give the coarse recorder something it might do well. Make a corner you can return to. Let your hand wander while one address stays steady, then find the edge where it changes. The same interval that swallowed a small flourish can help you repeat a shape. What kind of drawing do you want to make with it?

The list is finite too: beyond 4096 accepted positions, keeping a new one means dropping the oldest. We can read that limit on the instrument and leave its questions for a return. These dots do not fade their live trails merely because time passes.

## Move the place that draws

<!-- @draw_stick -->

Take the stick. Keep your fist nearly still and turn your wrist. The tip travels an arc. This tool uses the same recorder, but puts the sampling point at the end of a rod. A small turn can become a large mark.

The movement threshold is still five millimetres. We moved the place the recorder observes. Which part of your movement has the line begun to describe?

## Touch the page

<!-- @whiteboard -->

Four pens hang in front of the whiteboard. These belong to the board. Take the red one and touch its nib to the face. Make a short stroke, lift the pen, cross a little space, and touch down again.

Your hand travelled across the gap. The picture leaves it white.

The pen writes within the board's edges and close enough to its face. Lift beyond that contact allowance, and the next touch begins a new stroke. Your hand keeps moving across the gap; the rule stops admitting it to the picture. You can use that interruption to give two marks some space.

The board brings the nib's world position into its own frame with `to_local(world_tip)`, then turns the accepted contacts into a painted image. The coloured pens have the familiar spacings. For now, try making something with the lift between strokes.

Other machines nearby keep timed rows or make wordless handwriting. They offer further ways to read movement. Let them remain available while we follow the record we have just made.

<!-- @ -->

Return to a line you want to keep. Release the drawing dot or stick after making it: that release is how we send a copy onward. A whiteboard image is kept differently and will not take this route.

We can carry the record forward. The movement that made it has already passed. The copied positions can enter another program and be given another task.

In the next room, look for your bend. It may have grown.
