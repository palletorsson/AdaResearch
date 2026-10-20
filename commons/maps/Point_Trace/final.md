# Duration and Residue

Bring the detour.

There was time between the ends. We passed through it. Let the next line try to keep something of the passage.

A segment keeps two ends and a rule for joining them. Move either end and the between recomputes. It cannot tell us whether a hand stopped halfway, circled back, or hurried through. Those differences need somewhere to be recorded.

## A surface gives the pen somewhere to meet

<!-- @glass_paint_wall -->

A clear pane stands in a dark frame. Four pens and an eraser lie along its shelf. Through the empty surface, the rest of the room remains visible.

The pen meets the glass and a mark appears. Lift it, cross a little space, then touch down again. The hand travelled across the gap. The picture leaves it clear.

The drawing admits contacts close to the pane and inside its edges. Moving away ends the stroke; the next contact begins another. The glass gives this interruption a place we can understand with our hands. A pen has something to press towards, and a surface from which to lift.

Walking around the frame, we can see the mark from the other side. The line has changed its relation to the room behind it. Its place on the glass has stayed the same. The eraser clears the ink back to transparency.

Here the record is an image on a surface. A curved stroke can suggest depth while remaining on the pane. Further into the room, the coloured points ask what happens when the movement itself occupies depth.

## Hold the point

<!-- @draw_dot -->

Three small beads wait above their readouts. There is no barrel to orient and no nib searching for contact. Holding a bead and moving it leaves a line through open space. The recorder follows the bead's centre.

A loop can turn towards us, pass above the hand, and return on another level. Released, it stays available to walk around. The tool rests while the drawing occupies the room.

Beside each bead, a count sits above rows of coordinates. The list is the record:

```gdscript
var point_count = _trail_points.size()
```

Each retained position has three coordinates. The program connects it to the next with a straight segment. A curve is assembled from these small connections; between two retained positions, the hand may have taken another way.[^point-trace-sampling]

Holding still need not add a row. The recorder waits for at least five millimetres of movement before considering another position. A long pause can leave the same list as a brief one. Time passed through the gesture without acquiring a place in this record.

## Give the same bend another grain

The pink, green and violet beads use ten-, forty- and eighty-millimetre grids. Each accepted position is rounded to the nearest address on its grid. Several small movements can arrive at the same saved address. The recorder omits immediately repeated addresses; returning after another position can still make a new entry.[^point-trace-quantisation]

A small bend may survive in the pink trace and flatten in the violet one. Repeating the gesture with another hand movement changes two things at once: the recorder and the gesture. The sampling monitor follows one held movement before the bead's rounding, then compares several spacings applied to its own record. The hand does not have to repeat itself exactly.

The grain can also help a drawing. There is room to wander while an address holds, then a threshold across which the line gains a corner. A spacing that hides a flourish can make a return easier to recognise. The instrument offers both losses and possibilities; we need a particular drawing to judge them.

The lines joining the positions may cross the lattice diagonally. Rounding the corners does not require the path between them to follow the grid's edges. Sampling decides what enters the list. Joining decides what appears between its entries.

## After the hand lets go

<!-- @trace_ball_ramp -->

Beyond the bead stations, a black ball rests above a sloping plank. Released near the top, it continues down. A thin black line stays behind it.

The point has acquired weight. The hand chose a release; gravity, slope and contact carry the movement further. The recorder follows the ball's centre, so its path hangs a radius above the surface on which it rolls.

We can walk alongside the line while the ball settles in the tray. The slope has entered the drawing. Moving the ball back and releasing it elsewhere begins another trace. How much of the drawing was made in the choice of where to let go?

The three encounters have given movement different terms of admission. Contact leaves ink on glass. Holding a bead keeps positions through space. Releasing a ball lets a physical calculation continue the path. A line alone would not tell us which of these happened.

## Carry a bend

<!-- @ -->

Returning to a bead, we can leave a drawing for the next hall. Releasing it sends a copy of its retained positions to the running game's archive. At least two positions are needed. The image on the glass and the ball's path remain here.[^point-trace-carry]

This copy preserves the positions exactly. It does not preserve how long the hand paused or how the movement felt. The session archive survives the change of hall; it is not a disk save for a later launch.

The next room can give those positions another centre and size. A bend made at arm's length may become something we approach with the whole body. The movement has passed, but its record has acquired a use that was not settled when it was made.

In the next room, look for the bend. It may have grown.

[^point-trace-sampling]: Claude E. Shannon, [“Communication in the Presence of Noise”](https://fab.cba.mit.edu/classes/S62.12/docs/Shannon_noise.pdf), *Proceedings of the IRE* 37, no. 1 (1949), 10–21, Theorem 1, gives a reconstruction result for band-limited signals sampled uniformly in time. It is a technical neighbour, not a guarantee for this trace: frame timing, a movement threshold and spatial rounding do not meet those assumptions. Joining retained positions with straight segments cannot by itself recover the intervening gesture.

[^point-trace-quantisation]: Godot’s [`snappedf`](https://docs.godotengine.org/en/4.6/classes/class_%40globalscope.html#class-globalscope-method-snappedf) returns the nearest multiple of a spacing. Here this quantises spatial components; it does not set a fixed temporal sampling rate. The separate movement gate determines whether to consider another reading. Changing either operation can alter the record, for different reasons. The [technical companion](/book?map=Point_Trace&section=technical) gives the spacings, recording gate and list capacities.

[^point-trace-carry]: A spatial bead must retain at least two positions to send a copy onward. The glass wall's image and the ball's path stay in this hall. The [technical companion](/book?map=Point_Trace&section=technical) distinguishes these records and their transfer routes.
