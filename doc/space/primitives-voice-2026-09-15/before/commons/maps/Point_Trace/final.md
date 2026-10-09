Bring the detour.

In the last room, making a line could bring down a barrier. You could keep changing the line after the way opened. Keep two of its positions now: the place you started and the place you finished. Could that connection tell a direct walk from a wandering one?

There was time between the ends. We passed through it. Let the next line try to keep something of the passage.

## What the line forgot

<!-- @draw_dot -->

The drawing points wait on their plinths. Take the first dot and draw a short loop in the air, then pause with it still in your hand. Beside the line, a small instrument tilts its face towards reading: a count above a table of positions. Watch it during the pause. Does another point enter merely because time passes?

Move again: a small bend followed by a larger one. Look for the places where the line turns. Compare them with the turns you remember making. Keep drawing until the count passes twelve, then release the dot. The cased display stays beside the trace. Your hand can rest while you read.

Find the first row in the table. Where is row 1? Follow the line back towards its beginning before deciding what has disappeared.

The large count names the whole retained record. The table opens a window onto its last ten positions. A line of eighteen points shows rows 9 to 18; the earlier eight can still belong to the line. The instrument has made another selection, this time for the reader.

The count comes from the list itself:

```gdscript
var point_count = _trail_points.size()
```

A row names a place in that list. It does not name a frame of the game clock, a second, or a bend you remember making. Two gestures can leave equally long lists with very different coordinates.

A segment can be described by two endpoints and a rule for the between. There is nowhere in that description for a hesitation to be. This recorder adds an ordered list of positions. It can keep an overshoot or correction when those movements produce different accepted samples. A stationary pause, by itself, supplies no new position.

The readout gives a retained count and its capacity, the movement threshold and the recording grid. These placed drawing dots use a **5 mm movement threshold** and a capacity of **4096 accepted points**. The recorder first checks movement, then shapes the position, then rejects a shaped sample if it duplicates the last one.

That is three decisions before the line reaches your eyes: whether to look, where to put the reading, and whether another reading adds anything the list distinguishes.

The movement gate begins here:

```gdscript
var dist = current_global.distance_to(_last_global_position)

if dist < min_segment_distance:
    if fade_trail:
        _cleanup_old_points()
        _rebuild_trail()
    _refresh_data_table_if_due()
    return
```

Below the threshold, the callback can refresh the display and return without adding a position. The engine has done more work; the list has not grown. Point One's counter would have something to count during your pause. Here the hand waits, the list waits, and the museum keeps running.

There is already more code at work than we can read before leaving this hall: pickup, tracking, drawing, the letters on this small screen. We choose the movement gate because it answers the question our hand just asked. The other processes continue to support the experiment while we leave them unread.

Read two neighbouring rows. Their coordinates are in world metres, with at least three decimal places. The table once printed only two: a recorder could keep two positions that its own display made look identical. The record and the account of the record each have a resolution. We had to change the account to let this experiment be read.

<!-- @ -->

## The same gesture, on four different grids

Try the other three drawing dots. Their traces differ in colour and in where they can turn: red, green and blue round to **10 mm**, **40 mm** and **80 mm** spacing. The first dot has no added recording grid. Read each instrument to check its rule. Four instances of one recorder have been told differently where a reading is allowed to stand.

Repeat the small bend with the 80 mm dot. Then make a larger loop. Find a movement that changes the finer record while leaving the coarse recorder at the same stored lattice position. Use the readout to check which recorder you have, rather than relying on colour alone.

Away from a whiteboard, the spatial part of its rule is:

```gdscript
var s: float = resolution_mm / 1000.0
rec = Vector3(snappedf(rec.x, s), snappedf(rec.y, s), snappedf(rec.z, s))
```

This controls **where** a reading may land. The movement threshold is another rule, controlling when the tool considers a new reading. Coarse spacing can collapse different hand positions onto a position already occupied. The duplicate is never added to the list.

The accepted positions are connected by straight segments. Some segments may be diagonal; the tool does not promise an axis-by-axis staircase. The corners it keeps belong to the recording lattice, not necessarily to every bend of the hand.

None of these records is the movement. Even the finer recorder receives discrete measurements. Its line connects them, making the unobserved between look continuous.

The calls arrive while the rest of the museum is also running. The recorder reads one available position on a call; it cannot go back and measure every turn that happened between calls. Drawing faster can spread those readings farther apart. The spatial grid adds a separate decision afterward. A sparse record and a coarse grid may both change a curve, but they do not change it by the same operation.

Now give the coarse recorder a task it might suit. Try making a corner you can return to, or keeping one stored address steady while your hand wanders around it. Find the edge where it changes. Something that could not keep your small loop may help you hold a place. Which difference does this drawing need?

<!-- @draw_stick -->

Take the stick and try the loop again. Keep your fist nearly still and turn your wrist. Compare the movement of the fist with the movement at the tip.

The stick uses the same recorder as the dot, but the recording point sits at the end of a rod. A small turn of the hand can move that tip through a much larger arc. Changing what is sampled changes what the gesture becomes, even before changing the sampling rule.

<!-- @ -->

## It forgets too

Go back to the beginning of a line you have made. Can you still locate it after a pause? What would have to happen for that earliest retained point to leave?

The current drawing dots do not fade the live trail with age. Reading a line takes time without necessarily spending any more of its memory. Their capacity rule is:

```gdscript
if _trail_points.size() > trail_max_points:
    _trail_points.pop_front()
```

After 4096 accepted points, another accepted point pushes the oldest out. The display could keep saying 4096 while the line changes. Its count would still be correct. To discover that exchange, we would have to inspect which positions remain.

The row numbers address the current retained list. They are not permanent names attached to samples: removing its first member shifts the others towards the beginning. This is a point-count horizon, not a fixed number of frames or seconds. A pause does not spend another place. A gesture that repeatedly reaches new stored positions spends them differently from one that keeps returning to the same coarse position.

A smaller capacity would make that eviction easier to watch; changing it is a possible later experiment. The current encounter asks you to distinguish the rule from the number of seconds you have been drawing. We can read the removal here without pretending we have already watched all 4096 places fill.

Some of the plinths already carry example traces. They were generated for the display; they are not recovered gestures from an earlier visitor. An archive needs both something retained and an account of where it came from.

<!-- @whiteboard -->

Four pens hang in front of the whiteboard. These belong to the board. Take the red one and touch its nib to the face. Make a short stroke, lift the pen, cross a little space, and touch down again. Does the board join the two marks?

Your hand travelled across the gap. The picture leaves it white. A pen that writes only in contact has made a different selection from the dot that follows you through the room.

Contact here has a small allowance: the nib must be within 35 millimetres of the writing plane and inside the board's edges. Lift beyond that allowance and the next contact begins a new stroke. The program has to decide what touching means before it can leave a mark.

The board takes the nib's world position into its own frame:

```gdscript
var p := to_local(world_tip)
```

Across and up the board become two coordinates. The pen marked NO GRID adds no rounding to them; red, green and blue round to 10, 40 and 80 millimetres. Try a bend with blue that red can keep. Enlarge it until blue changes too. Can you use that interval to repeat a shape?

The positions are then mapped onto a 1024 by 768 pixel canvas. NO GRID still meets a grid here. Its name describes one operation we have omitted; the image still needs somewhere to put the ink. Between accepted contacts, the brush fills a connecting line. It has not measured every place it colours.

The drawing dot's instrument lets us read a list of retained world positions. This board keeps a painted image. Neither gives us the hand back. They offer different things to carry forward: addresses we can inspect, or a surface we can write over.

Take the eraser across one mark. Leave another beside it. What remains may make a new shape worth keeping. The board holds the image during this loaded encounter; saving it for another visit would need another act of storage.

<!-- @ -->

## A record of whom?

<!-- @hand_telemetry_diptych -->

At the paired monitors, read the footer first: `TRACKING` or `DEMO FEED`. With a tracked controller, move one hand and follow its own panel. Keep it still for a moment and look at the timed rows. Compare that recording with the drawing dot that waits for qualifying movement.

In desktop use, a demonstration feed can supply the moving numbers. It illustrates a log; it does not establish that your hand was measured. A full-looking record still needs a source.

The two panels divide a body into independently tracked parts. That can be useful. It also leaves the reader to decide what those parts mean together, and neither a coordinate nor a blinking recording light can supply that meaning by itself.

<!-- @automatic_writing_desk -->

The desk writes a different-looking record. When it finds a headset camera, movement of the camera's position changes the amplitude of its wordless script. Try leaning while watching the page, then holding still. Without that input, its demonstration motion can keep the page writing.

Head movement is not attention, and the marks are not words you composed. The warmth of handwriting can make a mechanical reading feel like a confession. Keep the movement, the encoding and the interpretation apart long enough to ask who is claiming to have read whom.

<!-- @ -->

Before leaving, invent two gestures the coarse recorder struggles to distinguish. One could include a deliberate pause; another could vary within one lattice position. Say what extra information would preserve the difference you care about: a timestamp, another sample, a pressure reading, a note in your own words. Those are proposals for another recorder, not information this line secretly contains.

**The trace is transmissible as data and irrecoverable as event.** Copy every retained position and the original gesture still does not happen again. Yet the copy can be useful, and choosing what it needs to preserve is work you can participate in.

The next room takes this hand-scale question under your feet: how far can you move while a grid continues to report the same place?
