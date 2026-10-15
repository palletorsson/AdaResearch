# Duration and Residue

Bring the detour.

There was time between the ends. We passed through it. Let the next line try to keep something of the passage.[^point-trace-klee]

A segment keeps two ends and everything between them, and it keeps them as a *rule*: move either end and the between recomputes. That is its whole economy. It is why a line can be stored in six numbers and why it can be drawn a thousand times without getting tired.

The price is that a line has no history. It cannot tell you whether it was drawn quickly, whether the hand stopped halfway, whether it was drawn and undrawn and drawn again. Those are not lost in the drawing; there is nowhere in a line for them to be.

## Let the hand leave a line

<!-- @draw_dot -->

Three coloured pens wait on their plinths. Take the red pen and draw a short loop in the air. Pause with it still in your hand. Beside the line, a small instrument tilts its face towards reading: a count above a table of positions.

The nib is the point being followed. Turn your wrist while keeping your hand almost still: the tip can travel while your grip barely moves.

Watch during the pause. Does another point enter merely because time passes?

Move again. Give the loop a tail, then release the pen. Your hand can rest while the line stays. Something of the movement has become available to look at from another side.

The count comes from a list:

```gdscript
var point_count = _trail_points.size()
```

`_trail_points` holds positions in the order they were kept; `size()` counts them. The recorder joins each position to the next with a straight segment. Repeated in small enough steps, the two-point construction from the last room lets us see a curve. The gesture has acquired joints. Between those joints, the program draws a connection; your hand may have taken another way.[^point-trace-sampling]

The recorder waits for at least five millimetres of movement before considering another position. A still pause can leave the count unchanged while Point Zero's counter keeps running. You spend time holding the line still; the position list does not say how long you waited.

Pickup, tracking, drawing, the letters on the screen: more code is running than we can read here. We follow the movement gate because it answers the question our hand just asked.

Each row gives three coordinates for a retained position. As the drawing grows, earlier rows leave the small table. The drawing still has its beginning. What has left the screen has not yet left the line.

## Another resolution, another gesture

The other pens give the line a coarser grain. From red through green to blue, their grids grow wider.

Repeat a small bend with the blue pen. Then enlarge the movement until another turn appears. Your wrist is negotiating with a spacing. A gesture that one recorder can distinguish may need to become larger for another.

The program rounds each coordinate to the nearest grid position. Several movements of your hand can arrive at the same saved address. Until a different address is kept, the line has no new corner.[^point-trace-quantisation]

The saved positions lie on the grid, but the segments between them can cut across it diagonally. A grid of corners does not require a drawing made only of right angles.

Two separate operations, and it matters which is which. **The loss happened when the samples were taken** — at the grain, at the lattice, before you looked. The lines perform the other one: they *invent* what happened in between. Nothing was recorded there, and a straight segment is the machine's guess, drawn at full confidence.

So the thing you are looking at is part record and part fabrication, and it does not distinguish them anywhere.

Now give the coarse recorder something it might do well. Make a corner you can return to. Let your hand wander while one address stays steady, then find the edge where it changes. The same interval that swallowed a small flourish can help you repeat a shape. What kind of drawing do you want to make with it?

There is also a limit to how many positions a pen can keep. Near the exit, another dot has a shorter memory. We will reach its limit while drawing. Every archive is a decision about a boundary, taken before anything is in it.


## After the hand lets go

<!-- @trace_ball_ramp -->

A black ball rests on a pale plinth. A plank slopes from its edge to the floor. Pick up the ball, set it near the top of the plank and let go.

The ball continues. A thin black line stays behind it.

The point has acquired weight. Your hand chose where to release it; gravity, the slope and contact with the plank carry the movement further. Here the recorder follows the ball's centre. The mark hangs a radius above the surface it seems to draw on.

Wait until the ball settles in the shallow tray. The line stops growing. Walk alongside it: the slope has become part of the drawing. Carry the ball back and release it from another place. The next release begins a new trace.

You have set a line in motion and let something else continue it. How much of the drawing did you make when you placed the ball?


## Touch the page

<!-- @whiteboard -->

Four pens and an eraser wait on the shelf beneath the wall-mounted whiteboard. These belong to the board. Take the red one and touch its nib to the face. Make a short stroke, lift the pen, cross a little space, and touch down again.

Your hand travelled across the gap. The picture leaves it white.

The pen writes within the board's edges and close enough to its face. Lift beyond that contact allowance, and the next touch begins a new stroke. Your hand keeps moving across the gap; the rule stops admitting it to the picture. You can use that interruption to give two marks some space.

The board turns the accepted contacts into a painted image. The coloured pens have the familiar spacings. A lift of the hand gives the drawing a gap.

## A line with a short memory

<!-- @trace_short_memory -->

The amber point near the exit has room for thirty-two positions. Draw a loop, then lead it away. Small beads mark the positions the cord joins. Watch its far end.

At first you make more line. Then you begin to unmake it.

Hold your hand still. Does the remaining line wait with you?

This recorder uses the same movement gate as the red pen. We have given its list less room. When a new position takes it over that limit, the oldest goes:

```gdscript
if _trail_points.size() > trail_max_points:
    _trail_points.pop_front()
```

Waiting does not spend another place. Continuing the drawing can. Thirty-two positions are neither thirty-two seconds nor a fixed length of line.

Rafael Lozano-Hemmer's *Pulse Room* lets recorded heartbeats continue as light after a participant releases the sensor. New arrivals move older recordings along a finite queue.[^point-trace-pulse-room] Watch the amber tail disappear at its far end. What can remain when making room is part of the work?

Now try drawing with the loss. Give yourself a tail. Curl it around your other hand, then lead it elsewhere. The space you just marked can open again. What would you make with a line that follows you without keeping all of where you have been?

<!-- @ -->

Return to a line you want to keep. Release the drawing pen after making it: that release sends a copy onward. With the amber dot, only the surviving positions travel.[^point-trace-carry]

We bring that trace into the next hall. Your hand can rest now. The movement that made the line has already passed; its recorded positions can remain.[^point-trace-inscription] There we will place the drawing as a sculpture, something you can approach from another side.

The trace sends perfectly: this is what a GPS track is, and a mocap take, and every gesture your phone has ever kept. **The trace is transmissible as data and irrecoverable as event.** Copy it exactly and it still never happens again.

The recorder was made to keep a gesture. Its list can now become something to compose with. A bend of the wrist may return at the size of a room, inviting another movement. The first use is still there, but it no longer tells us everything the record can become.[^point-trace-hauntology]

In the next room, look for your bend. It may have grown.

[^point-trace-pulse-room]: Rafael Lozano-Hemmer, [*Pulse Room*](https://www.lozano-hemmer.com/pulse_room.php) (2006). The comparison concerns limited retention. His installation keeps pulse rhythms; this recorder keeps ordered positions without their timing.

[^point-trace-klee]: Paul Klee, [*Pedagogical Sketchbook*](https://openendedgroup.com/field2/assets/Klee_Paul_Pedagogical_Sketchbook_1960.pdf), translated by Sibyl Moholy-Nagy (1960 edition; German original 1925), opening section. Klee begins with an “active line on a walk” and a moving point. Ada makes the recording conditions part of that encounter: which point moves, when a position is accepted, and how retained positions become a line.

[^point-trace-sampling]: Claude E. Shannon, [“Communication in the Presence of Noise”](https://fab.cba.mit.edu/classes/S62.12/docs/Shannon_noise.pdf), *Proceedings of the IRE* 37, no. 1 (1949), 10–21, Theorem 1, gives a reconstruction result for band-limited signals sampled uniformly in time. It is a technical neighbour, not a guarantee for this trace: frame timing, a movement threshold and spatial rounding do not meet those assumptions. Joining retained positions with straight segments cannot by itself recover the intervening gesture.

[^point-trace-quantisation]: Godot’s [`snappedf`](https://docs.godotengine.org/en/4.6/classes/class_%40globalscope.html#class-globalscope-method-snappedf) returns the nearest multiple of a spacing. Here this quantises spatial components; it does not set a fixed temporal sampling rate. The separate movement gate determines whether to consider another reading. Changing either operation can alter the record, for different reasons. The [technical companion](/book?map=Point_Trace&section=technical) gives the spacings, recording gate and list capacities.

[^point-trace-carry]: A drawing pen must retain at least two positions to send a copy onward. The whiteboard's image and the ball's path stay in this hall. The [technical companion](/book?map=Point_Trace&section=technical) distinguishes these records and their transfer routes.

[^point-trace-inscription]: Sigmund Freud’s [“A Note upon the ‘Mystic Writing-Pad’”](https://web.english.upenn.edu/~cavitch/pdf-library/Freud_WritingPad.pdf) (1925) and Jacques Derrida’s “Freud and the Scene of Writing,” in [*Writing and Difference*](https://press.uchicago.edu/ucp/books/book/chicago/W/bo27619783.html), translated by Alan Bass (1978), open a neighbouring inquiry into inscription, retention and the relation between a mark and what is no longer present. Here they open a question to pursue: what can a retained mark tell us about a movement that has already passed?

[^point-trace-hauntology]: Jacques Derrida's [*Specters of Marx*](https://api.pageplace.de/preview/DT0400.9781040559963_A63760427/preview-9781040559963_A63760427.pdf) (1993; English translation by Peggy Kamuf, 1994), “Exordium,” connects inheritance with responsibilities towards those no longer or not yet present. Ada extends this question to technical use: a tool can carry an earlier purpose into an unanticipated connection. The [project afterword](/book-review/doc/book/iterations/2026-09-23-book-frame/index.html#afterword) develops this proposal alongside entropy as difference and Ashby's requisite variety.
