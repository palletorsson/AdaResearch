You arrive late.

<!-- @frame_counter_display -->

The number is already changing. Its first number for you is not its first number. While you find somewhere to stand, the room continues with whatever it was doing before you arrived.

Follow the number for a moment. Where does the next one come from?

A small counter can begin here:

```gdscript
extends Node3D

var _count := 0

func _process(delta: float) -> void:
    _count += 1
```

Godot calls `_process` once per process frame while this node is processing. Each call reaches the indented line: add one to `_count`. One, then two, then three. Declared outside the function, `_count` keeps its value between calls. Its zero belongs to the beginning of this node.

`delta` brings the update's time interval in seconds. We receive it without using it yet. Adding one counts calls; adding the intervals would accumulate time. The same count could have taken different durations.

The room's panel reads a total that began earlier:

```gdscript
var frames: int = int(Engine.get_process_frames())
```

This counts process frames since the engine started, including frames before the panel existed. We begin with a number that includes something we did not witness.

<!-- @folding_past -->

Through the entrance window, frames recede within frames. They keep folding while you look elsewhere. There is a temptation to follow them back to a first frame, a place from which everything might be explained in order.

This particular depth has a small inventory: ten frames, scaled and moved through a repeating cycle. It makes a figure of a past. It keeps no record of your arrival. A few repeated shapes can invite a much longer journey than the one their program holds.

We could turn back into the counter: how a digit gets its shape, how the glass is drawn, how the engine returns to `_process`. Any of those questions could take the rest of our time here. To begin with the point, we have to leave some invitations unanswered. The lesson borrows operations we have not learned to examine yet.

The code we leave unread keeps working. Choosing a first principle also means choosing what we will, for now, take on trust. Who gets to decide which questions can wait?

Alice's rabbit is already ahead. We still have a point to find.

## Somewhere, without a body

<!-- @the_invisible_point -->

In the glass case, four brass arrows address an empty centre. Two thin red lines meet there. Follow either line towards the crossing. There is no dot to take over the work of locating it.

What have you found, if there is no body there?

The source names the meeting place:

```gdscript
const FOCUS := Vector3(0.0, 1.25, 0.0)
```

`Vector3` holds three components. Here they specify a position: zero along the case's local X direction, 1.25 metres along its Y direction, zero along Z. The case supplies the reference. These numbers give a location without making anything visible.

The arrows and lines are arranged around `FOCUS`. The point itself is never drawn. There is no hidden mesh, no later appearance to wait for. We have found it through its relations to other things.

The source gives us another way to approach the same empty centre. An address can be read. A position can organise a room without wearing a surface.

<!-- @code_evolution_screen -->

On the nearby code screen, a separate example begins to dress a position: a sphere, colour, a label. Later, an accumulated time decides when that marker would appear. These are illustrative scripts to read; the screen does not execute them. The point in the case stays invisible.

A position does not contain a colour. A mesh does not tell us whether a hand can hold it. To make the next point approachable, we have to give it more.

## Dress the point

<!-- @interactive_point_origin_force -->

The dark point offers itself to your hands. Pick it up. Follow it a little to one side, then back. Its appearance can change as you handle it; successive pickups also change how its coordinates are displayed, sometimes hiding the label.

Already, the point has broken the promise of taking things one step at a time. There is shine here, a surface, a changing body. We are already Alice. We can follow that interest into the construction, where the things meeting us at once were made separately.

A mathematical point has no extension. This artifact gives it a sphere, a collision shape and ways to respond. Those additions let us meet a position through movement.

```gdscript
var p := Vector3(1.0, 0.5, 0.0)
```

Three components again. There is nowhere in this value to put the sphere's radius, your hesitation, or the reason you chose this place. A program could record some of those things separately. Here, the position gives us a place to begin making.

What drew your hand towards it? Knowing how the sphere was made need not finish that interest. Another surface, another response: there are already several ways to make a location felt.

<!-- @origin -->

Find the origin marker. Zero has been given a place too. `Vector3.ZERO` names the reference from which other positions can be measured. It belongs to a coordinate frame. It is a beginning we can use.

<!-- @coordinate_readout -->

Put down the dark point. The coloured frame has a movable point of its own. Take that one and watch the card marked `WORLD`. Move it slightly. A printed number may stay unchanged through movement you can see.

The card rounds its account to two decimal places. Nearby positions can share a printed address while the stored position continues to change. That little stillness has been made for reading.

<!-- @CoordinateSystem3M -->

Red follows X, green follows Y, blue follows Z. Move the point along one guide, then across it. The frame uses `to_local()` to express the point's world position relative to its own origin, orientation and scale. The same place can have different addresses. Remember the case: its 1.25 was measured from there.

Carry the point beyond an arrow's end. The drawn guide stops; the coordinate system can keep describing the movement. An earlier version confined the point to the arrows' span. A drawing intended to explain space had become a rule for where movement must end. Now you can take the point farther.

<!-- @drag_point_target -->

The red arrow says “drag point here”. Carry the point towards it. Watch for falling balls. Leave and return by another route.

The target accepts the point within 0.45 metres of its chosen centre. A hand has room to arrive. Passing through can count as arriving too; the test asks for proximity, without asking why you came. Leave, return, and a destination can become an instrument. Give the falling balls a rhythm.

<!-- @wireframe_threshold -->

Step inside the floor ring. Surfaces become edges in the wireframe view. The glass case has geometry; the invisible point has no triangles to reveal. Nor will this view show the comparison that accepted your arrival at the arrow. That opening waits in the source.

<!-- @fontana_puncture -->

The punctured surface offers another instance of the changing point. Look through a different opening. A cut can give you another approach to the body inside. We have an address, a sphere, an opening: each lets us come near differently.

<!-- @floating_sphere_field -->

Small spheres drift nearby. Positions have acquired another pace and appearance. There is more here to follow than we have time to follow now.

<!-- @ -->

The counter has continued through all of this. We have located a point, dressed it, carried it, given ourselves somewhere to return.

Keep a place you would like to reach. In the next room, we will hold two positions together. A line begins.
