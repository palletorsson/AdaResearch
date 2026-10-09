… You arrive late.[^1]

<!-- @frame_counter_display -->

The number is already changing. Its first number for you is not its first number. While you find somewhere to stand, the room continues with whatever it was doing before you arrived.

You can stand in a room you did not build. Someone has made that possible. Their work gives us somewhere to begin, and brings decisions with it. We inherit possibilities before we know their conditions. What are we forced to borrow for now, and what must we understand to make the work our own?

Follow the number for a moment. Where does the next one come from?

A small counter can begin here:

```gdscript
extends Node3D

var _count := 0

func _process(delta: float) -> void:
    _count += 1
```

Godot repeatedly calls the function named `_process`. Each call runs the indented line, `_count += 1`, adding one to the number stored in `_count`. One, then two, then three.

The declaration `var _count := 0` sits outside the function. It sets the starting value. Calling `_process` again does not run that declaration again, so the count keeps what the previous call left behind.

Godot also supplies `delta`: this update's time interval, in seconds. Our counter receives it but does not use it. A hundred calls add a hundred, however long they took. The number keeps how many, leaving how long unanswered.

That example has its own count. The room's counter reads a total that began earlier:

```gdscript
var frames: int = int(Engine.get_process_frames())
```

`Engine.get_process_frames()` counts process frames since the engine started. The panel reads and displays that total on each `_process` call. It includes frames before the panel existed, and before you found the number. Loading the room has already occupied some of those intervals.

We begin with a number that includes something we did not witness.

We have read the line that asks for that number. Much of the code making it readable remains unopened.

<!-- @folding_past -->

Through the entrance window, rectangular frames recede within frames. They keep folding while you look elsewhere. There is a temptation to follow them back to a first frame, a place from which everything here might be explained in order.

Ten frames, scaled and moved through a repeating cycle, make this depth. They hold no record of the route you took to arrive here. A few repeated shapes can invite a much longer journey than the one their program keeps.

In 1968, an experimental head-mounted display put its viewer inside a room drawn in wireframe. Turning the head changed the view; walls, ceiling and floor were already part of the experiment.[^point-one-room-history] Before we could take a room like this for granted, people had to make it possible to look around one. You are here now, with some time to play.

We could turn back into the counter: how a digit gets its shape, how its glass is drawn, how the engine returns to `_process`. Any of those questions could take the rest of our time here. We would also like time to pick something up and see what happens. To begin with the point, we have to leave some invitations unanswered.

The code we leave unread keeps working. It gives the number its appearance and the room its possibilities while our attention moves elsewhere. Choosing a first principle also means choosing what we will, for now, take on trust. Who gets to decide which questions can wait?

Alice's rabbit is already ahead. There are functions we would like to open, but we still have a point to find. We carry a question forward; others fold behind us.

<!-- @origin -->

We cannot follow everything back to its beginning. But we can choose somewhere to count from.

Find the black sphere with its pink glow and wireframe cube. Zero has been given a place in this room too. This zero is a reference in space, not the first moment of the running clock.

```gdscript
var origin := Vector3.ZERO
```

`Vector3.ZERO` is shorthand for three zeroes: `(0, 0, 0)`. Used as a position, it names the origin of a coordinate system. From there we can measure where something else is. Nothing in those three zeroes explains why this place was chosen.

Nearby, a sign says “~~you~~ are here.” The location remains legible after its visitor is crossed out. What part of you has arrived at this address?[^point-one-ahmed-reach]

<!-- @the_invisible_point -->

In the glass case, four brass arrows address an empty centre. Two thin red lines meet there. Follow either line towards the crossing. There is no dot to take over the work of locating it.

What have you found, if there is no body there?

The source names the meeting place:

```gdscript
const FOCUS := Vector3(0.0, 1.25, 0.0)
```

`Vector3` holds three numbers in the order X, Y, Z. Here they locate a position in the case's own coordinate system: 1.25 metres up from its origin, with no displacement along X or Z. The numbers specify where the lines will meet. They do not draw anything there.

The arrows aim towards `FOCUS`; the red lines pass through it. What they locate is never drawn. There is no hidden mesh waiting to appear.

That is a strange thing to exhibit: a position you can locate, with no body of its own. The source lets us approach it from the other direction. In the case, we follow the arrows towards a meeting place. In the code, that place is given first, and the arrows are arranged around it.

<!-- @code_evolution_screen -->

On the nearby screen, a separate example begins with three numbers. The displayed code adds a sphere at that position, then colour and a label. The screen advances through excerpts; it does not run the program. We can follow the decisions that would give this position a visible body.

Here `delta`, which the counter received without using, has something to do. Each call to `_process(delta)` adds its time interval to `elapsed`. In this example, the accumulated time would hide and show the sphere every two seconds. Its centre would stay at the same address. A body can disappear from view without going anywhere.

The additions matter separately, even though they arrive together when we look at the finished object. A position does not contain a colour. A mesh does not tell us whether a hand can hold it. To make the next point approachable, we have to give it more.

<!-- @interactive_point_origin_force -->

The dark point offers itself to your hands. Pick it up. Follow it a little to one side, then back. Its appearance can change as you handle it; successive pickups also cycle its coordinate display through several formats, including one that hides the label.

The first point has already broken the promise of taking things one step at a time. There is shine here, a surface, a changing body. We are already Alice. We can follow that interest into the construction, where the things meeting us at once were made separately.

A mathematical point specifies a location without extension.[^point-one-euclid] This artifact gives it a sphere, a collision shape and ways to respond. Those additions let us meet it through movement. They also give it possibilities that a position alone does not have.

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

Now compare it with the card marked `LOCAL`. Move the same point between two places. Both cards answer, but with different numbers. What would you need to know to read either address?

<!-- @CoordinateSystem3M -->

Follow the coloured frame's guides as you move the point in your hand. Red follows X, green follows Y, blue follows Z. Move along one direction, then across it. The guides separate a movement into components, letting you follow several directions within one gesture.

The frame has its own origin, orientation and scale. Its script uses `to_local()` to express a world position relative to that frame. The `LOCAL` card prints that address beside `WORLD`: the same place measured from different references. Remember the case's `FOCUS`: its 1.25 was measured from the case, too.

A coordinate needs its reference. Reading more digits cannot supply one that has been left unnamed.[^point-one-haraway]

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

[^point-one-ahmed-reach]: Sara Ahmed, [*Queer Phenomenology: Orientations, Objects, Others*](https://www.dukeupress.edu/queer-phenomenology) (Duke University Press, 2006), introduction. Ada’s questions about orientation and reach draw on her account of bodies finding their bearings through relations with objects, spaces and others. Lines will make this conversation more explicit.

[^point-one-euclid]: Euclid, [*Elements*, Book I, Definition 1](https://mathcs.clarku.edu/~djoyce/elements/bookI/defI1.html), defines a point as that which has no part. This is a historical starting point for the abstraction, not a specification of a Godot object. A stored position, a visible marker and a collision body require different constructions; the invisible point lets us keep them apart.

[^point-one-haraway]: Donna Haraway, [“Situated Knowledges: The Science Question in Feminism and the Privilege of Partial Perspective”](https://doi.org/10.2307/3178066), *Feminist Studies* 14, no. 3 (1988), 575–599, especially 581–585. Haraway argues for embodied, situated and accountable knowledge, challenging both a view from nowhere and an easy relativism. Naming a coordinate frame is not equivalent to that epistemology. It gives this room a technical way to ask a related question: what must accompany a reading for someone else to understand its reference and limits?

[^point-one-room-history]: Ivan E. Sutherland, [“A Head-Mounted Three Dimensional Display”](https://doi.org/10.1145/1476589.1476686) (1968), especially “Results”; [accessible paper](https://archive.aec.at/media/assets/636b23b07bfd1b4f1d1154827ac9d9ab.pdf). The wireframe room and response to head movement are described there. The acknowledgments name a collective effort, and the funding note names ARPA, the Office of Naval Research and Bell Telephone Laboratories. This is one historical encounter with these problems, not a claim that the museum follows a single line of descent.
