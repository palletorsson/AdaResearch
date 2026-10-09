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

Each accepted position occupies a place in that ordered list. The recorder joins neighbouring positions with straight segments. Enough small segments can let us see a curve. Go closer to a turn: the smooth-looking gesture has acquired joints.

The dot waits for at least five millimetres of movement before considering another sample. Below that movement threshold, the update can return without adding a position. A stationary pause can leave the list unchanged while Point One's counter has plenty more calls to count.

There is already more code at work than we can read here: pickup, tracking, drawing, the letters on the screen. We choose the movement gate because it answers the question our hand just asked. The other processes continue to support the experiment while we leave them unread.

Read two neighbouring rows. The coordinates give places in world metres. If your loop has more than ten points, its first row may have left the table: the instrument shows the last ten, while the larger count names the whole retained list. The line can hold something its small window is no longer showing.

## Another resolution, another gesture

Try the other drawing dots. Red rounds positions to a 10 mm grid, green to 40 mm, blue to 80 mm. The first dot adds no such grid. Read the instrument to find which rule you are holding.

Repeat a small bend with the blue dot. Then enlarge the movement until another turn appears. Your wrist is negotiating with a spacing. A gesture that one recorder can distinguish may need to become larger for another.

The grid operation is small enough to read. With `rec` as a position and `s` as the spacing in metres:

```gdscript
rec = Vector3(snappedf(rec.x, s), snappedf(rec.y, s), snappedf(rec.z, s))
```

Each component moves to the nearest multiple of the spacing. If the result repeats the last stored position, the recorder does not add it again. The movement gate decides whether to consider a reading; the grid helps decide where that reading can stand. These are different choices.

The segments can cross the grid diagonally. Follow one of those shortcuts. The program connects what it kept; it did not measure every place along that connection. Even the finest dot reads positions during successive calls while the rest of the museum runs between them.

Now give the coarse recorder something it might do well. Make a corner you can return to. Let your hand wander while one address stays steady, then find the edge where it changes. The same interval that swallowed a small flourish can help you repeat a shape. What kind of drawing do you want to make with it?

<!-- @draw_stick -->

Take the stick. Keep your fist nearly still and turn your wrist. The tip travels an arc. This tool uses the same recorder, but puts the sampling point at the end of a rod. A small turn can become a large mark. The line has gained another way to extend your movement.

The record has a finite capacity: 4096 accepted points. Beyond that, a new position pushes the oldest out:

```gdscript
if _trail_points.size() > trail_max_points:
    _trail_points.pop_front()
```

The number could stay at 4096 while the beginning of the line changes. We can read that limit without filling it now. The current dots do not fade their live trails merely because time passes. Looking at the line need not spend another place in it.

## Touch the page

<!-- @whiteboard -->

Four pens hang in front of the whiteboard. These belong to the board. Take the red one and touch its nib to the face. Make a short stroke, lift the pen, cross a little space, and touch down again.

Your hand travelled across the gap. The picture leaves it white.

This pen writes near the board's surface, within its edges. Lifting beyond the contact allowance begins a new stroke when you return. The dot carried a line into the room; this pen lets contact interrupt it. An empty interval can become part of a drawing.

The board brings the nib's world position into its own frame:

```gdscript
var p := to_local(world_tip)
```

Across and up the board become two coordinates. The coloured pens apply the same 10, 40 and 80 mm spacings we met in the air. Try a bend that red can keep and blue cannot, then enlarge it for blue. The pen marked NO GRID omits that rounding, but its marks still enter a pixel canvas. There is always another construction to examine when we look closer.

Take the eraser across a mark. Leave another beside it. Something worth keeping may appear through removing. The board holds a painted image during this visit; the dot holds a list of positions. Those records give us different materials to work with next.

<!-- @hand_telemetry_diptych -->

At the paired monitors, check whether the footer says `TRACKING` or `DEMO FEED`. With a tracked controller, you can follow a hand through timed rows, including while it stays still. The demonstration feed supplies an example when tracking is absent. A full-looking record needs an account of where it came from.

<!-- @automatic_writing_desk -->

The desk offers wordless handwriting. When it finds a headset camera, movement of that camera changes the writing's amplitude; otherwise a demonstration can keep it moving. Try leaning, then resting. Something like a confession appears, although you have composed no words. What makes a mark feel as if it knows you?

<!-- @ -->

Return to a line you want to keep. Release the drawing dot or stick after making it: that release is how we send a copy onward. A whiteboard image is kept differently and will not take this route.

The trace is transmissible as data and irrecoverable as event. We can carry its positions into another room, even though we cannot carry the original movement there. We can also give them another task.

In the next room, look for your bend. It may have grown.
