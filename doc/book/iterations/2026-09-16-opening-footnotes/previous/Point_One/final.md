… You arrive late.[^1]

<!-- @frame_counter_display -->

The number is already changing. Its first number for you is not its first number. While you find somewhere to stand, the room continues with whatever it was doing before you arrived.

You can already stand in a room you could not yet build. Someone has made that possible. Their work gives us somewhere to begin, and brings decisions with it. We inherit possibilities before we know their conditions.

We can make more than we can explain. What can we borrow for now, and what must we understand to make the work our own?

Follow the number for a moment. Where does the next one come from?

A small counter can begin here:

```gdscript
extends Node3D

var _count := 0

func _process(delta: float) -> void:
    _count += 1
```

Godot calls `_process` once per process frame while this node is processing. The engine supplies the repetition. Each call reaches the indented line: add one to `_count`. One, then two, then three. Declared outside the function, `_count` keeps its value between calls. Its zero belongs to the beginning of this instance.

`delta` carries this update's time interval in seconds. We receive it here but do not use it yet. Adding one counts calls. The same count could have accumulated through different durations; the number keeps how many, leaving how long unanswered.

The room's counter reads a total that began earlier:

```gdscript
var frames: int = int(Engine.get_process_frames())
```

`Engine.get_process_frames()` counts process frames since the engine started. The panel reads and displays that total on each `_process` call. It includes frames before the panel existed, and before you found the number. Loading the room has already occupied some of those intervals.

We begin with a number that includes something we did not witness.

We have read the line that asks for that number. Much of the code making it readable remains unopened.

<!-- @folding_past -->

Through the entrance window, frames recede within frames. They keep folding while you look elsewhere. There is a temptation to follow them back to a first frame, a place from which everything here might be explained in order.

The source gives this particular depth a small inventory: ten frames, scaled and moved through a repeating cycle. It makes a figure of a past. It has no record of the route you took to arrive here. A few repeated shapes can invite a much longer journey than the one their program keeps.

We could turn back into the counter: how a digit gets its shape, how its glass is drawn, how the engine returns to `_process`. Any of those questions could take the rest of our time here. To begin with the point, we have to leave some invitations unanswered. The lesson borrows operations we have not learned to examine yet.

The code we leave unread keeps working. It gives the number its appearance and the room its possibilities while our attention moves elsewhere. Choosing a first principle also means choosing what we will, for now, take on trust. Who gets to decide which questions can wait?

Alice's rabbit is already ahead. There are functions we would like to open, but we still have a point to find. We carry a question forward; others fold behind us.

<!-- @origin -->

We cannot follow everything back to its beginning. But we can choose somewhere to count from.

Find the origin marker. Zero has been given a place in this room too. This zero is a reference in space, not the first moment of the running clock.

```gdscript
var origin := Vector3.ZERO
```

The origin is a point chosen as the reference from which other positions are measured. Calling it zero establishes a relation with other positions. It does not put zero outside the world it helps describe.

Nearby, a sign says “~~you~~ are here.” The location remains legible after its visitor is crossed out. What part of you has arrived at this address?

<!-- @the_invisible_point -->

In the glass case, four brass arrows address an empty centre. Two thin red lines meet there. Follow either line towards the crossing. There is no dot to take over the work of locating it.

What have you found, if there is no body there?

The source names the meeting place:

```gdscript
const FOCUS := Vector3(0.0, 1.25, 0.0)
```

`Vector3` holds three components. Here we use them as a position: zero along the case's local X direction, 1.25 metres along its Y direction, zero along Z. These are coordinates relative to the case. They specify a location without making anything visible.

The arrows and lines are built in relation to `FOCUS`. They make its location available through things beside it and passing through it. The point itself is never drawn. It has no hidden mesh and no later appearance to wait for.

That is a strange thing to exhibit: a position you can locate, with no body of its own. The source offers another access to it. You can read the address and follow how the surrounding construction was arranged. The position has become available through those relations, without acquiring a surface.

<!-- @code_evolution_screen -->

The nearby code screen builds a visible marker in a separate example. Its excerpts give a sphere a position, then colour and a label. The screen does not execute these scripts. Their sphere belongs to that example; the point in the case remains undrawn. The complete illustrative scripts accompany the excerpts in the room's source.

In a later stage, `_process(delta)` adds `delta` to `elapsed`. The example accumulates time rather than adding one per call; that elapsed time selects when its marker would be drawn. Its position stays the same. This is a construction we could make from a position. The invisible point keeps its empty centre.

The additions matter separately, even though they arrive together when we look at the finished object. A position does not contain a colour. A mesh does not tell us whether a hand can hold it. To make the next point approachable, we have to give it more.

<!-- @interactive_point_origin_force -->

The dark point offers itself to your hands. Pick it up. Follow it a little to one side, then back. Its appearance can change as you handle it; successive pickups also cycle its coordinate display through several formats, including one that hides the label.

The first point has already broken the promise of taking things one step at a time. There is shine here, a surface, a changing body. We are already Alice. We can follow that interest into the construction, where the things meeting us at once were made separately.

A mathematical point specifies a location without extension. This artifact gives it a sphere, a collision shape and ways to respond. Those additions let us meet it through movement. They also give it possibilities that a position alone does not have.

```gdscript
var p := Vector3(1.0, 0.5, 0.0)
```

Three components again, now another position. There is nowhere in this value to put the sphere's radius, your hesitation, or the reason you chose this place. The position can be used by a program that records those things separately. On its own, it does not tell that story.

What drew your hand towards the point may be among the things its coordinates cannot report. Knowing how the sphere was made need not finish that interest. It gives you places to intervene: another surface, another response, another way to make a location felt.

<!-- @coordinate_readout -->

Keep the point in your hand. Move it while watching the white card. The changing body now has an address. What does the address follow, and what does it leave out?

The opening between the two areas lets you carry the same point towards the coloured frame. Its guides and the card follow the point you are already holding.

The card marked `WORLD` puts its position into another visible form. Move the point slightly while watching the card. A printed component may stay unchanged through a movement you can see.

The reporting operation can be written like this:

```gdscript
func report_position(point: Node3D) -> String:
    var p := point.global_position
    return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
```

`%.2f` rounds each component to two decimal places in the text. The stored position is left alone. The card has made the location easier to read by allowing several nearby positions to share a printed address. The apparent stillness belongs to that report.

<!-- @CoordinateSystem3M -->

Follow the coloured frame's guides as you move the point in your hand. Red follows X, green follows Y, blue follows Z. Move along one direction, then across it. The guides separate a movement into components, letting you follow several directions within one gesture.

The frame has its own origin, orientation and scale. Its script uses `to_local()` to express a world position relative to that frame. The white card and the coloured frame can therefore give different addresses for the same place. Remember the case's `FOCUS`: its 1.25 was measured from the case, too.

A coordinate needs its reference. Reading more digits cannot supply one that has been left unnamed.

Carry the point beyond an arrow's end. The drawn axis has a length; the coordinate system can describe positions beyond it. An earlier version confined the point to the arrows' span. A drawing made to explain movement had also been deciding where movement could end. The frame now keeps describing the point outside that span.

<!-- @drag_point_target -->

The red arrow says “drag point here”. Carry the point towards it. Watch for the falling balls. Leave and return by another route.

“Here” has become a request, and the request has a tolerance. This is the distance test, reduced to one position:

```gdscript
@export var catch_radius: float = 0.45
@export var catch_height: float = 1.20

func accepts_position(p: Vector3) -> bool:
    var centre := global_position + Vector3(0.0, catch_height, 0.0)
    return p.distance_to(centre) <= catch_radius
```

The comparison accepts a position within 0.45 metres of a centre 1.20 metres above the target's origin. A hand has room to arrive. The accepted position can be close enough without being identical to the centre.

The target checks points registered in its coordinate-point group. It requires no release and rearms when the point leaves. A careful delivery and an accidental pass can bring the same rain. Your intention never enters this comparison.

Return again, and a destination can become an instrument. The rhythm of your arrivals changes what the room's instruction is useful for. A detour may matter to that rhythm while remaining absent from the success test. We could give the target a memory of the journey; we would then have to decide what it remembers, and what someone else could read from it.

<!-- @ -->

The counter has continued through all of this. A position has acquired a body, different addresses, a tolerance for arrival. It still leaves questions unanswered.

One of them travels with us: how did it get there?

The next room brings two points into relation. A line begins.

[^1]: Heidegger’s *thrownness* names finding ourselves already delivered into an existence we did not choose—not simply arriving after the clock started. Here, the room offers a small encounter with that condition. Genesis, first light: we look for a beginning. But is this the world beginning, or our first glimpse of something already underway? See [*Being and Time*, §29](https://www.beyng.com/pages/en/BeingandTimeMR/BeingandTimeMR.174.html).
