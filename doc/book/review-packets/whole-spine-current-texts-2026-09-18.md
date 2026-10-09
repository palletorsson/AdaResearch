# Ada Research — current local text snapshot

Captured 2026-09-18. Working copy based on 42496604b02d17856c5dbb69223fbf67747183ef. Uncommitted text is included. This is not a claim that GitHub has the same versions.

Read alongside whole-spine-handover-2026-09-18.md. Order below follows curriculum_spine and each sequence maps list. Differences from the museum declaration are reported explicitly.


# primitives

Declared order: Point_One → Point_Lines → Point_Trace → Point_Line_Grid → Point_Triangle_Context → Primitives_Polythedra → Point_Animatedcube → Primitives_Ignorance → Primitives_Portals → Primitives_Melencolia

Museum map-authored order differs: Point_One → Point_Lines → Point_Trace → Point_Line_Grid → Point_Triangle_Context → Primitives_Polythedra → Point_Animatedcube → Primitives_Ignorance → Primitives_Portals → Primitives_Melencolia → Biome_Ladder_Primitives. Treat this as route drift to inspect, not an editorial recommendation.


## Point_One

Source: commons/maps/Point_One/final.md

SHA256: 4eef4c45260896c989b50a008259d4593ef3ee07589eee84f65eec084585c679

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

Nearby, a sign says “~~you~~ are here.” The location remains legible after its visitor is crossed out. What part of you has arrived at this address?[^point-one-ahmed-reach]

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

<!-- @CoordinateSystem3M -->

Follow the coloured frame's guides as you move the point in your hand. Red follows X, green follows Y, blue follows Z. Move along one direction, then across it. The guides separate a movement into components, letting you follow several directions within one gesture.

The frame has its own origin, orientation and scale. Its script uses `to_local()` to express a world position relative to that frame. The white card and the coloured frame can therefore give different addresses for the same place. Remember the case's `FOCUS`: its 1.25 was measured from the case, too.

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



## Point_Lines

Source: commons/maps/Point_Lines/final.md

SHA256: eb2c11e847cb5267001023c721b7f5bc2f0c3184cc5c7c26391ff4804d15ef09

The point gave us somewhere to begin. Now put two positions into relation.

<!-- @line_demo -->

Two black points wait beside a barrier: **DO NOT CROSS.** Bring them near one another and release to request a connection. Watch for the segment between them. What else moved?

The barrier flies apart.

Keep hold of this small beginning: **two distinct points determine a straight line.**[^point-lines-euclid] Here we draw only the part between them: a segment. Move an endpoint. The segment changes length and direction while the connection remains.

Already something else has attached itself to the lesson. Joining two points has opened a passage.

<!-- @do_not_cross_barrier -->

Try crossing where the barrier stood. While intact, its collider reached from the floor to the bar; the visible gap beneath the plank did not let you through. Disconnecting the points does not rebuild it.

On the first connection, the demonstration calls the nearby barrier's `trigger_explosion()`. Someone joined those events in code. Geometry supplies a relation; another instruction gives that relation a consequence for your body. We could have made the connection ring a bell, or left the barrier standing.

The words, the plank and the collision boundary all helped to say **DO NOT CROSS**. Opening the way required changing what enforced that instruction. For a moment, a line has given us passage through another line's prohibition.

There is a whole inquiry waiting there. Keep the question with you as you move to the next pair of endpoints.

<!-- @line -->

This line has two ends you can hold. Pull them apart, then bring them closer. Watch the length display. Can you find a span of one metre?

Hold one end still and move the other around it. Try keeping the same distance. The segment can turn while its length stays steady. Once we choose to go from A to B, we can calculate a displacement with a distance and a direction.

Here is an example using the positions we began learning to write in the first room:

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(1, 0, 0)
var displacement := b - a
var distance := displacement.length()
```

`b - a` gives the displacement from the first position to the second: here, one unit along X. In this room we use that unit as a metre. `length()` gives the magnitude of that displacement, the straight distance between the endpoints.

Change either position and calculate again. The coordinates can change; we still have two endpoints and the segment between them. We have a small way to describe something that our hands can alter.

Even here, another question appears. Your hand may keep moving while the rounded number stays the same. How much difference can a display show? Remember it when we reach Trace and Grid.

Two points were enough to begin. They have not made the world small.

Nearby, a ruler offers a measure. Two crosses invite comparison. Lines on monitors seem to meet; a laser waits for something to stand in its way. Each could occupy the rest of our visit. There is pleasure in following these associations, in finding how quickly a familiar mark acquires another use.[^point-lines-ingold]

For now, hold on to the connection you made and the distance you changed. The other experiments remain available for a return.

The clock in the first room was already running when we arrived. Beginning required leaving some code unread. Continuing asks us to choose a thread and let other questions remain open.

Ahead, a line has acquired words.

<!-- @walk_this_line_marking -->

Across the glass cover of a shallow basin, a black stripe: **WALK THIS LINE.** The glass supports your crossing.

Try following it. Then walk alongside it. Cross it at an angle. The stripe gives you something steady to vary your relation with.

Did a sideways step feel like a mistake? The marking makes no such judgement: its script draws the stripe and lettering without scoring your walk. The instruction may still have changed how you moved.[^point-lines-ahmed-paths] Another visitor might find an invitation to dance around it.

Choose which end to start from, and the line gives you a direction to follow. It cannot settle what following will mean to a body.

<!-- @player_trace -->

Turn and look at the route your movement has left behind. Compare it with the stripe. That small sideways step is visible now.[^point-lines-ahmed-deviation]

The recorder saves sampled positions and joins them. In VR it follows the headset's horizontal position at the rig's floor height; on desktop it follows the walker. The resulting line records one part of your movement.

Choose a start and an end. Walk between them with a detour. Imagine walking directly between those same positions instead. The endpoint calculation, `b - a`, gives the same answer for both journeys. It contains no record of the turn you took.

The trace has kept more positions. How many did it need? What happened between the ones it kept?

<!-- @ -->

We can leave the other experiments here. The question taking us towards the exit has become precise: **what must we save if we want to keep something of the journey?**

Two endpoints were enough for the segment. To remember the detour, we will need to add something.

Bring the detour.

[^point-lines-euclid]: See Euclid, [*Elements*, Book I, Postulate 1](https://mathcs.clarku.edu/~djoyce/elements/bookI/post1.html), on drawing a straight line between two points. The construction concerns the finite segment; extending it and treating it as an unbounded line are further steps. The postulate is a historical reference, not an account of the renderer or the barrier’s programmed response.

[^point-lines-ingold]: Tim Ingold, [*Lines: A Brief History*](https://www.routledge.com/Lines-A-Brief-History/Ingold/p/book/9781138640399) (Routledge Classics edition, 2016), especially “Traces, Threads and Surfaces” and “Up, Across and Along.” Walking, drawing, weaving and connecting enter his inquiry as different practices of making lines. This helps us take the room’s proliferation seriously: a connector, a trace and a boundary need not perform the same work merely because we call each a line.

[^point-lines-ahmed-paths]: Sara Ahmed, [*Queer Phenomenology*](https://www.dukeupress.edu/queer-phenomenology) (2006), 15–20, especially 16: repeated journeys make paths, while established paths help direct later journeys. Ada takes up this relation as an experiment. Its stripe is authored rather than worn into the ground, and its instruction does not score compliance. Being oriented by a line, evaluated against one and physically blocked by one remain different operations to investigate.

[^point-lines-ahmed-deviation]: Ahmed, [*Queer Phenomenology*](https://www.dukeupress.edu/queer-phenomenology), 20, considers how deviations can leave marks and generate other lines. This sampled drawing offers one specific record, not the whole history of the body’s deviation.



## Point_Trace

Source: commons/maps/Point_Trace/final.md

SHA256: e8e49ba56b57cc1fd1cf6c965260ffa50e3efe72434ea95403f60b316b5f6354

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

Each accepted position occupies a place in that ordered list. The recorder joins neighbouring positions with straight segments. Enough small segments can let us see a curve. Go closer to a turn: the smooth-looking gesture has acquired joints. The connection between two samples has been drawn; it is not a measurement of everything your hand did between them.[^point-trace-sampling]

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

Each component moves to the nearest multiple of the spacing. If the result repeats the last stored position, the recorder does not add it again. The movement gate decides whether to consider a reading; the grid helps decide where that reading can stand. These are different choices.[^point-trace-quantisation]

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

We can carry the record forward. The movement that made it has already passed.[^point-trace-inscription] The copied positions can enter another program and be given another task.

In the next room, look for your bend. It may have grown.

[^point-trace-klee]: Paul Klee, [*Pedagogical Sketchbook*](https://openendedgroup.com/field2/assets/Klee_Paul_Pedagogical_Sketchbook_1960.pdf), translated by Sibyl Moholy-Nagy (1960 edition; German original 1925), opening section. Klee begins with an “active line on a walk” and a moving point. Ada makes the recording conditions part of that encounter: which point moves, when a position is accepted, and how retained positions become a line.

[^point-trace-sampling]: Claude E. Shannon, [“Communication in the Presence of Noise”](https://fab.cba.mit.edu/classes/S62.12/docs/Shannon_noise.pdf), *Proceedings of the IRE* 37, no. 1 (1949), 10–21, Theorem 1, gives a reconstruction result for band-limited signals sampled uniformly in time. It is a technical neighbour, not a guarantee for this trace: frame timing, a movement threshold and spatial rounding do not meet those assumptions. Joining retained positions with straight segments cannot by itself recover the intervening gesture.

[^point-trace-quantisation]: Godot’s [`snappedf`](https://docs.godotengine.org/en/4.6/classes/class_%40globalscope.html#class-globalscope-method-snappedf) returns the nearest multiple of a spacing. Here this quantises spatial components; it does not set a fixed temporal sampling rate. The separate movement gate determines whether to consider another reading. Changing either operation can alter the record, for different reasons.

[^point-trace-inscription]: Sigmund Freud’s [“A Note upon the ‘Mystic Writing-Pad’”](https://web.english.upenn.edu/~cavitch/pdf-library/Freud_WritingPad.pdf) (1925) and Jacques Derrida’s “Freud and the Scene of Writing,” in [*Writing and Difference*](https://press.uchicago.edu/ucp/books/book/chicago/W/bo27619783.html), translated by Alan Bass (1978), open a neighbouring inquiry into inscription, retention and the relation between a mark and what is no longer present. A list of coordinates is not Derrida’s philosophical trace or a model of psychic memory. The connection here is a question to pursue, not an identity between these concepts.



## Point_Line_Grid

Source: commons/maps/Point_Line_Grid/final.md

SHA256: 5968397789b7d1363d513c427fb91a6aff73ce10e04c07cc5e63afedc46e852a

Look for your bend. It may have grown.

A drawing released in Trace can arrive here as a list of positions. Over the ruled field, a small movement has acquired another size. Keep it in view. We are going to give positions addresses, then ask what those addresses help us make.

## Find somewhere to return

<!-- @grab_sphere_point_snap -->

Pick up the snapping sphere. Move it slowly, watching its marker and the retained line. Try to move without adding a new place to the record. Then go far enough for another place to appear.

Trace already made choices about which positions to keep. Here, look at the table's other way of naming them. Beside the coordinates in metres are integer indices. With this tool's five-centimetre spacing, `0.15` metres along X has index `3`: three spacings from world zero. The same place has two names.

The calculation, reduced to one axis, is:

```gdscript
var index = roundi(pos.x / grid_size)
var placed_x = index * grid_size
```

Divide by the spacing. Round to the nearest integer. Multiply back to get metres. At this spacing, `0.12` becomes `0.10`; `0.13` becomes `0.15`. One centimetre of movement can carry the record across a five-centimetre interval. Elsewhere, a larger movement can leave its address unchanged.

Let go. The tool brings its marker onto the lattice. Pick it up and try to return to that address. You have some room to be imprecise and still arrive at the same result. That can be useful: we may want two pieces to meet without having to place them by eye.[^point-grid-bowker-star]

The table gives another name to the retained position. It does not show the unrounded position beside it. We still need your movement to notice what this record leaves out.

## Give the interval a rhythm

<!-- @player_trace -->

Now walk a small loop, then a wider diagonal. Look behind you. The walking recorder keeps a finer sampled reference and a path rounded to one-metre spacing in its own frame.

Find a place where you can move while the coarse address holds. Slowly cross into another. Cross back. There is a rhythm in the jump, and room to move within the interval. A rule for making positions agree has also given us something to dance with.[^point-grid-ahmed-return]

In VR, lean with your feet planted. The recorder can respond: it follows the headset horizontally, using the rig's origin for height. On desktop it follows the walking body. It must choose a point before it can draw a path called yours.

The lines connect the positions it keeps. A diagonal can cut across ground you went around. Returning to an earlier address can add another turn to the record; the program keeps an order of visits, not just a collection of places visited once. An address lets us recognise a return. It does not tell us why we came back.

## Let the drawing find another use

<!-- @grid_lines -->

Return to the ruled field. Find your bend in pink, then compare green. Is it still your bend at this size? If the field is empty, return to Trace, draw with a dot or stick until it retains at least two points, and let go. The whiteboard and walking recorder keep separate records.

This display subtracts the centre of the received drawing's bounds and applies a scale:

```gdscript
mesh.surface_add_vertex((p - center) * final_scale)
```

Pink shows the drawing centred and scaled. Small drawings grow fivefold; larger ones receive a smaller multiplier to fit within five metres. Green rounds the displayed positions again, with six intervals per metre along each axis. The source positions listed in the panel stay unchanged.

A turn made by your wrist might now suggest a route for your whole body. Is there a part you would want to follow? A record can become a score, but it needs another decision about what following means.

## Give the address a floor

<!-- @plan_vitrine -->

Step onto the small plan in its glass enclosure. Count one row, then a column. Five by five: twenty-five one-metre cells. The printed indices run from zero to four.

Find a cell using both numbers. Leave it and find it again. You can now describe where a cube might stand without pointing. Two indices can become an instruction for placing it.[^point-grid-scott]

Cross a row, then cut diagonally. The drawn divisions do not stop you. A continuous collision surface supports the plan. Over the other basin, the museum supplies walkable glass; the replayed lines provide no floor of their own.

An address can tell a program where to put something. What lets a body reach it needs further work.[^point-grid-lefebvre]

<!-- @ -->

There are other movements and other plans here. We could keep following them. For now, carry this much: a shared address can help us repeat a placement, coordinate a meeting, begin a level. It cannot decide which of those things we should want.

The grid gives us a way to name a place and return to it together.

Next, three points can close a boundary. What must we add before there is a face inside it?

[^point-grid-bowker-star]: Geoffrey C. Bowker and Susan Leigh Star, [*Sorting Things Out: Classification and Its Consequences*](https://mitpress.mit.edu/9780262024617/sorting-things-out/) (MIT Press, 1999), study classifications and standards as information infrastructure, including whose differences become visible or disappear within them. Rounding coordinates is not identical to classifying people. It supplies a small operational comparison: treating different inputs as equivalent can support coordination while leaving distinctions out. Its consequences depend on what we build with that equivalence.

[^point-grid-ahmed-return]: Return to Ahmed, [*Queer Phenomenology*](https://www.dukeupress.edu/queer-phenomenology), introduction: bodily orientation involves relations of alignment and reach. Dancing with the interval is Ada’s proposed use of this rule, not a result already established by her argument.

[^point-grid-scott]: James C. Scott, [*Seeing Like a State: How Certain Schemes to Improve the Human Condition Have Failed*](https://yalebooks.yale.edu/book/9780300252989/seeing-like-a-state/) (Yale University Press, 1998), chapter 1, examines practices of administrative legibility, including cadastral mapping. The connection here is narrow: a plan can make a placement describable to someone not standing beside it. This does not make every grid coercive or establish that a legible plan is sufficient for inhabiting the place.

[^point-grid-lefebvre]: Henri Lefebvre, [*The Production of Space*](https://www.wiley-vch.de/de?isbn=9780631181774&option=com_eshop&title=The+Production+of+Space&view=product), translated by Donald Nicholson-Smith (Blackwell, 1991; French original 1974), chapter 1, distinguishes spatial practice, representations of space and representational spaces. His account keeps planning, practical activity and lived meanings in relation. The vitrine enters that problem without reproducing the whole theory: addresses and a plan do not by themselves establish access, habits, belonging or a place’s meaning to its inhabitants.



## Point_Triangle_Context

Source: commons/maps/Point_Triangle_Context/final.md

SHA256: 13ab860a3d58a06ee4d7f5153196d770163b6c66d8e489981dd54e3ed281dc5a

Three points can close a boundary. What must the machine add before there is a face to look at?

You have connected endpoints, recorded a path and given positions addresses you can return to. Now bring three edges together. Something can close without becoming a surface.

<!-- @triangle_line_puzzle -->

Bring two edges into place. Look through the remaining opening before adding the third. What do you expect to arrive with the last connection?

The boundary closes. Its centre stays unfilled. The small instrument beside it reports the closed boundary and the hidden fill. Press **SHOW / HIDE FILL**, then look from another side. Press again. The edges remain while the patch of colour comes and goes.

We have made two things happen separately. Connecting the endpoints closes a loop. Adding a triangle mesh gives that loop a visible face. The first operation does not secretly contain the second.

The button waits for the completed boundary. Once it is closed, its mesh receives the three target positions:

```gdscript
mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
for p: Vector3 in target_positions: mesh.surface_add_vertex(p)
mesh.surface_end()
```

The word `TRIANGLES` asks the renderer to treat each three vertices as a face. The positions alone did not ask for this. Their order, the primitive type and the material participate in what you see.

This fill is visible from both sides. Walk around it. Its appearance can narrow almost to a line without its three corners moving. The material permits a view from either side; the edge-on projection leaves little of the surface to show.[^point-triangle-winding]

Three distinct, non-collinear points determine a triangle and a unique plane. “Non-collinear” means that the third point is not on the line through the other two. Without that condition, the boundary can collapse into a line with no area.

## Close a loop, then inspect the fill

<!-- @draw_triangle_faces -->

Pick up the drawing point and make a small triangle in the air. The tool records a corner while held once its one-second interval has elapsed and the tip has moved far enough from the previous point. Move to each intended corner, watch for the numbered point, then return near the first to close the loop. Positions round to a ten-centimetre grid. The addressing we met in Grid helps corners meet here.

Look for the filled face. The side instrument distinguishes **filled loops** from **triangles**: one three-corner loop makes one triangle. Press **SHOW / HIDE FILL** and compare the surface with its retained boundary. Hiding the fill preserves the points and edges.

Each corner has a number. **START** marks the first point of the current path. That number is about order, not importance. We will give it a different job in a moment.

Release the tool at the corner where you closed the loop. Release can record a final position; after that the resting tool adds no timed samples. Your earlier corners remain grabbable. Move one and release it; the faces that use it rebuild.

For another independent outline, release the pen and press **NEW OUTLINE**, then pick it up again. The button keeps completed faces and lets you choose a new first corner. Use it before each comparison below.

Beside your first triangle, in a clear patch of space, make a six-corner L in one horizontal plane. Think of a 1.2-metre square with a 0.8-metre square missing from one corner. Each arm of the L is 0.4 metres wide. Keep the line from crossing itself.

For a precise version, the coordinates below name the two horizontal directions in metres, relative to the lower-left outer corner; keep every point at the same height:

```text
A (0.0, 0.0)     B (1.2, 0.0)     C (1.2, 0.4)
D (0.4, 0.4)     E (0.4, 1.2)     F (0.0, 1.2)
```

First follow **A → B → C → D → E → F → A**. Inspect the fill. Begin a new outline and follow the same boundary from its next corner: **B → C → D → E → F → A → B**. Reuse the six existing corner points. These letters name our route; the tool shows numbers. Check START before closing. Should beginning elsewhere change which region lies inside the L?

The boundary has not moved, but from B the added fill reaches into the missing notch. Something is covering a place you left open.

The tool uses the first point as the centre of a triangle fan, connecting it to successive pairs around the loop. For the second L it submits these four triangles:

```text
B C D
B D E
B E F
B F A
```

Follow their edges across the notch. The code kept its rule; the rule failed to keep your boundary. Choosing another start changed the input order, not the polygon's interior.

Each six-corner loop adds four triangles to the readout. Keeping both Ls adds two filled loops and eight triangles to whatever you already made. The counter includes the triangles that overspill. It can count a construction without deciding whether it fills the intended region.

The method works for a triangle and for a convex planar polygon. Some concave polygons also work from suitable starting vertices. Concavity by itself does not guarantee failure, which is why this comparison keeps the boundary fixed and changes the start deliberately.

You could choose a better starting vertex where one exists, redraw a shape the fan handles, or keep this outline and ask for another filling algorithm.[^point-triangle-triangulation] You might also want that unwanted patch for another work: a wing, a pleat, something extending beyond its frame. Changing its use would give the result another purpose. It would not repair the original fill.

We need not settle every use of a triangle before leaving. The folds, symbols and other surfaces remain here to return to. Carry this distinction onward: closing a boundary, making a face and choosing how to show it are operations we can separate. A convenient method need not require everyone to want a convenient shape.

Next, faces meet at a corner. What must we add to enclose a volume?

[^point-triangle-winding]: For the rendering convention, see [Godot 4.6’s SurfaceTool documentation](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html): triangle front faces use clockwise winding. Vertex order, shading normals and the material’s culling setting have different jobs. The puzzle deliberately displays both sides. That choice changes visibility; it does not give the face thickness or a collider.

[^point-triangle-triangulation]: One available development route is Godot’s [`Geometry2D.triangulate_polygon`](https://docs.godotengine.org/en/4.6/classes/class_geometry2d.html#class-geometry2d-method-triangulate-polygon), which returns triangle indices for a 2D polygon and an empty result if triangulation fails. A planar 3D drawing would first need coordinates in its plane, followed by mapping the returned indices back to its vertices and handling winding. This room still uses its first-vertex fan; no alternate triangulator is installed by this note.



## Primitives_Polythedra

Source: commons/maps/Primitives_Polythedra/final.md

SHA256: 4b812ea9471caf4aec36e1edd2a8a3e2453a4943f6b2a2151f8a9b66857de86a

The face you made in the last room could be seen from either side. Now let faces meet. When do they begin to enclose something?

<!-- @grab_trihedron -->

Pick up the open corner and turn it. Follow the three triangles toward the point they share. Then look through the opening opposite that point. Something suggests an inside, although one side is missing.

Count the faces before looking at the code. Three. The artifact is a finite model of a trihedral corner: three faces meeting at one vertex. Its four stored positions are connected like this:

```gdscript
[0, 1, 2]
[0, 2, 3]
[0, 3, 1]
```

Position `0` belongs to all three triangles. The other positions make a rim around the opening. No row joins those three rim points into a base.

We have turned the face into a corner. We have not yet closed a surface around a volume.

<!-- @grab_tetrahedron -->

Turn the tetrahedron beside it. Find a face where the first object has an opening. Follow its edges toward the opposite vertex. Four faces now complete the enclosure.[^polyhedra-separation]

Adding a base to the open corner would close a tetrahedron. This neighbouring example is regular, with four congruent equilateral faces. Its proportions differ, so compare how the faces connect before comparing their shapes.

Look at the tetrahedron as a little room with no door. Imagine it large enough to stand inside: where would you enter? The renderer draws the boundary without filling the interior with material. Enclosing a region has not supplied a way into it.

Now look back through the open corner. Would a small object fit through its missing side?

The same four positions used for drawing enter another construction:

```gdscript
var convex_shape = ConvexPolygonShape3D.new()
convex_shape.points = geometry["vertices"]
collision_shape.shape = convex_shape
```

The convex collision hull spans the four positions, including the base absent from the drawing.[^polyhedra-hull] Rendering leaves an opening; physics receives a closed shape. The points have entered two rules and acquired different boundaries.

That does not mean your tracked hand must stop there. Which body collides, with which layers, matters too. The geometric surface remains open; passage for a particular simulated body is another question.

## A face meets the floor

<!-- @prism_block -->

Find the bare prism examples toward the entrance side of the room. Follow a triangular end, then an edge joining it to the other end. The triangle has acquired a length. Two triangular ends and three connecting faces bound a triangular prism.

Compare the whole block with the quartered version and the open frame. Their visible construction changes; all three retain the original prism's collision surface. The gaps offered to your eye have no corresponding cutouts in that surface.

Approach a utility wedge from its low end and try walking toward the raised floor. Compare that approach with an upright face. Where can forward movement become upward movement?

The museum builds these wedges from a walkable prism scene, scaling the rise and the run:

```gdscript
w.scale = Vector3(1.0, maxf(0.05, rise), maxf(0.2, run_cells))
```

The low edge must meet the floor; the upper edge needs somewhere to arrive. The moving body's collision and slope settings also participate.[^polyhedra-gibson] If a join catches you, notice where. A continuous-looking route still has to work as a route.

You can hold a small solid and inspect it. A larger arrangement of faces begins to carry the inspector. The lesson has moved from the object in your hand to the conditions of your own movement.

<!-- @concrete_barrier -->

Approach the striped concrete enclosure and follow its outside edge. Its stepped profile is carried along a length too, with a collision body added. Related constructions can offer ascent or interrupt a route. Geometry does not decide the use.

A barrier might protect a place to stand; a slope might lead somewhere difficult to leave. Follow what this arrangement permits before deciding what you would change.

<!-- @street_sign -->

STOP stands beside the concrete. Did you pause at the word or at the physical boundary? Recall WALK THIS LINE: an instruction can orient you without enforcing collision. This sign has no collision body of its own.[^polyhedra-ahmed]

Read one blue arrow, then look where it points. An arrow can propose a direction without knowing whether the route is traversable.

We could follow these forms into many other arrangements. For now, ask which one you would change, and whose movement it would change. The fixtures are fixed here; this is a proposal to carry onward.

The pyramid, cube, stacks and rocks remain for a [return visit](/book?map=Primitives_Polythedra&section=tutorial). Keep the distinction: enclosing a region, admitting a body and suggesting a direction require different decisions. Next, a cube is taken apart so we can follow how its faces are made.

[^polyhedra-separation]: For the Jordan–Brouwer separation theorem, see Zuoqin Wang's [Topology lecture 23](https://staff.ustc.edu.cn/~wangzuoq/Courses/20S-Topology/Notes/Lec23.pdf), Theorem 2.7 (2020). In three dimensions, a surface embedded in Euclidean space and homeomorphic to a sphere separates its complement into two components, one bounded and one unbounded. The tetrahedron's boundary fits these conditions. This establishes separation, not a collider, an entrance or habitability.

[^polyhedra-hull]: Godot's [ConvexPolygonShape3D](https://docs.godotengine.org/en/4.6/classes/class_convexpolygonshape3d.html) is a solid collision shape. The opening here belongs to the rendered mesh, not to that hull. A collision model assembled from surface triangles is a different construction; Godot's [ConcavePolygonShape3D](https://docs.godotengine.org/en/4.6/classes/class_concavepolygonshape3d.html) is intended chiefly for static geometry. This is not an instruction to replace a held object's hull with a concave shape without considering its physics behavior.

[^polyhedra-gibson]: James J. Gibson, [The Ecological Approach to Visual Perception](https://memoof.me/download/1058/pdf/1058.pdf) (1979; linked Classic Edition), chapter 8, relates a surface's affordance of support to the animal's size, weight and behavior. The wedge invites a computational comparison: passage depends on the surface and the moving body's implementation. The engine's settings do not exhaust Gibson's account of perception or the visitor's bodily experience.

[^polyhedra-ahmed]: See Sara Ahmed, [Queer Phenomenology](https://www.dukeupress.edu/queer-phenomenology) (2006), Introduction; the fuller discussion accompanies WALK THIS LINE. Here orientation returns through a sign beside a physical boundary. Reading an instruction and meeting collision remain different operations.



## Point_Animatedcube

Source: commons/maps/Point_Animatedcube/final.md

SHA256: 8766f7315281827273337b3eba633e4ed6c3a5aca9528cf2184619f828dcc50c

You have been inside boxes since the first room. Now one of them lets you take hold of a corner. What must stay in place for it to remain a cube?

<!-- @cube_lines -->

Begin with the outline. Follow the three edges leaving one corner. Look through to the far side. You can recognise a cube before any faces have appeared, although nothing has yet closed the gaps between these lines.

The previous room gave us forms that could support a foot or interrupt a route. Here we return to their construction. What happens when the parts remain connected but their positions change?

<!-- @animatedcubebuilder -->

The builder may have finished before you arrive. Press **REPLAY** on its side instrument. Corners appear, then edges, then triangular patches. Press **PAUSE** at the moment you recognise the shape. How much did you need to see?

Only this assembly pauses. The folding net and the rest of the room continue. We have borrowed a little attention from a world already running.

The source has prepared the geometry before this presentation begins. The animation reveals pieces that were hidden. What looks like construction is also an arrangement of when we are allowed to see.

Resume. Once the assembly finishes, the numbered corner handles become available. Keep the second builder unchanged as a reference. On the one you will alter, find `v6`. Follow the square face containing `v4`, `v5`, `v6` and `v7`. Predict what will happen if you pull `v6` out of that face's plane, leaving its other corners where they are.

Move it a little. Look along the face. Where did the crease appear?

Try to locate the seam before pressing **DIAGONALS**. The yellow lines show the six diagonals that divide the cube's square faces into triangle pairs. Your hand has made one of those divisions matter.[^animatedcube-triangulation]

That face is stored as two triples:

```gdscript
[4, 5, 7]
[5, 6, 7]
```

Each number names a vertex. Both triples contain `5` and `7`: their shared edge. Only the second contains `6`. When you move that corner, the second triangle tilts while the first stays in place. A face that appeared to be one flat square can now bend along a choice made in its construction.

The builder reads a moved handle back into its position list:

```gdscript
vertices[i] = handle_nodes[i].position / cube_size
```

The edge and triangle lists still refer to the same vertex numbers. The neighbours remain; equal lengths, right angles and flat square faces need not.[^animatedcube-boundary] The display measures the largest corner shift in local metres. It cannot tell us what the changed form is worth.

Release the handle and press **REPLAY**. The layers return around your altered shape. Then try **RESTORE CUBE**. This time the initial corner positions return too. Repeating a presentation and undoing a change are different ways of beginning again.

Compare the two builders. Name one property your alteration preserved and one it lost. You can keep a crease you like without claiming the result is still a cube.

<!-- @polyhedron_nets_cube -->

Further on, watch the net fold. Choose one square and follow it from the flat arrangement into the closed form. Before it folds again, predict which faces will meet.

Here each square stays rigid. The hinges turn. In the builder, you moved a corner and bent a square into two differently tilted triangles. Similar-looking movement can come from different operations. Knowing which data changes helps you predict what a form can do.

<!-- @ -->

Now look down at the floor, then along a wall. Find the box form again in the crates. The museum builds its floor slabs and wall blocks from scaled box meshes. The primitive on display has also been carrying us from room to room.

The initial cube pairs twelve triangle patches into six square faces.[^animatedcube-counts] The crates add geometry for planks and reinforcing strips. We can recognise the box across these different meshes.

You can move a corner on the instrument while the museum's boxes support and redirect your body. What we are learning to inspect is also the place from which we inspect it.

Read the cartons: **A WORLD / WITHOUT / COMPOSITION**. The supply pile and the stamped crate add **YET**.

*A world without composition yet.* There is already an arrangement around us; the words cannot make it disappear. We can recognise what the museum is made from before we know how to compose another one.

The crates, glove box, shadow and glowing point offer more ways into that question. They can wait for a [return visit](/book?map=Point_Animatedcube&section=tutorial). For now, take the crease with you: a small movement exposed a decision inside a familiar shape.

The next room asks what an engine gives us when it supplies another familiar name: a sphere.

[^animatedcube-triangulation]: Godot Engine 4.6, [Using the ArrayMesh](https://docs.godotengine.org/en/4.6/tutorials/3d/procedural_geometry/arraymesh.html), rectangle example: four positions are connected by two triangle triples. This builder submits its patches through `SurfaceTool` in triangle mode. A flat convex quadrilateral admits either diagonal; moving a corner out of its plane can make that choice visible as a different crease.

[^animatedcube-boundary]: *Connectivity* names which vertices, edges and faces are incident; their positions place that structure in space. Compare the separate point and connectivity properties in Botsch, Sieger, Moeller and Fabri's [Surface Mesh manual](https://doc.cgal.org/latest/Surface_mesh/index.html), CGAL 6.2.1, “Connectivity” and “Properties.” Here the index lists preserve the combinatorial structure, but moving vertices may produce crossings or collapsed faces, so a valid geometric embedding is not guaranteed. The builder's patches also lack enclosing collision geometry; its handles have pickup colliders. See the [technical chapter](/book?map=Point_Animatedcube&section=technical).

[^animatedcube-counts]: Euler's [Elementa doctrinae solidorum](https://scholarlycommons.pacific.edu/euler-works/230/) (1758) investigates polyhedral counts. For the initial cube, `V - E + F = 8 - 12 + 6 = 2`. Splitting its squares adds six diagonals and six faces: `8 - 18 + 12 = 2` again. A proof for the sphere's triangulation appears in Heinz Hopf's [Selected Chapters of Geometry](https://pi.math.cornell.edu/~hatcher/Other/hopf-samelson.pdf), §I.3, from his 1940 lectures reconstructed and translated by Hans Samelson. The equality does not certify cube shape or a valid embedding. The instrument counts twelve patches, excluding reverse rendering copies.



## Primitives_Ignorance

Source: commons/maps/Primitives_Ignorance/final.md

SHA256: ea8323dc84accf77afe5a9f90731089016a8c95190fb271be5df7c6ec8c6cc9b

You left a cube whose connections could outlast its name. Now try the name sphere. What are you accepting when you recognise something as round?

<!-- @sphere -->

Begin with the ordinary sphere near the entrance. Look at it from a distance, then approach. Follow its silhouette against the room beyond it. Where does the outline give you something to inspect that the name had allowed you to pass over?

The room carries an instruction: **Let no one ignorant of geometry enter here.** It recalls the motto traditionally associated with Plato's Academy.[^ignorance-inscription] Here we have entered with a little geometry. We will use it to inspect the limits of the forms that seemed to admit us.

<!-- @sphere_high -->

Start with the first pair in the resolution display. One sphere wears lines along its triangle edges; the other has plain shading. Predict whether removing the lines also changes the sphere's outline. Walk around the pair and compare.

The two meshes have the same vertex positions and triangle connections. The lines are an added overlay. They make a construction easier to follow without rebuilding its surface.

Choose one place where the silhouette changes direction. Step back until that distinction becomes difficult to see, then approach again. Your distance changed. The mesh did not.

<!-- @sphere_mid -->

Continue to the middle pair. Inspect it from a comparable distance. Which distinctions are easier to find now? Compare the marked example with its plain neighbour before comparing it with the finer pair behind you.

The finer pair uses sixteen rings and sixteen radial segments; this pair uses seven of each. Those two settings divide different directions of the surface. Changing them changes the positions and connections available for making it.

<!-- @sphere_low -->

At the coarsest pair, follow one flat patch toward its edge. Is this merely a sphere missing something, or is there a feature here you would choose to keep?

Its construction uses one ring and ten radial segments. One direction is divided more often than in the middle example, the other much less. Resolution has a distribution. It does not arrive as a single quantity called detail.

The script gives the two choices separate names:

```gdscript
sphere_mesh.radial_segments = segment_count
sphere_mesh.rings = ring_count
```

A mathematical sphere consists of points at a fixed distance from a centre. The mesh joins sampled positions with flat triangles. Adding triangles can improve that approximation; no finite collection of flat patches acquires the sphere's continuous curvature. Shading can soften their appearance while the polygonal outline remains.

This is where ignorance turns around. Plato distinguishes the drawn figure from the geometric object considered in thought. Here we turn our attention toward the constructed figure: what its polygons leave out, and what their particular arrangement makes available.[^ignorance-plato]

The formula specifies a sphere. The mesh gives us one finite construction through which to encounter it. The ridge is available too. We can learn from its shape without requiring it to disappear into a smoother answer.

<!-- @budget_of_smoothness -->

Return to the counter by the inscription. Four numbered spheres turn at the same rate. Keep the counts hidden at first. Choose one for a distant background and one for someone to inspect close to their face. The spheres stay on their stands; you are choosing possible uses.

Press **SHOW / HIDE COUNTS**. Did the numbers change your choice? Then press **SHOW / HIDE EDGES** and follow the lines toward a pole.

Each tag gives two triangle counts. Even counting depends on what the instrument agrees to include.[^ignorance-counts]

Hide the counts while keeping the edges visible, then try the reverse. What becomes easier to judge? Both controls alter what is shown while keeping the sphere meshes in place.

A triangle count does not measure frame time or tell us which object deserves to exist. For your proposed use, name the distinction worth spending geometry on. You might spend more on a close silhouette, or keep a facet because it makes this body recognisable.

<!-- @capsule -->

Before leaving, find the five-sided capsule. Let it turn. When a ridge faces you, picture the other side. Would the same ridge be waiting there? Follow the silhouette as another side comes into view.

Five segments divide the body around its long axis. Opposite a ridge is the middle of a facet. Half a turn does not bring this cross-section back onto itself. The divisions are evenly spaced, but their odd number interrupts that particular symmetry.[^ignorance-capsule]

You cannot fold your understanding around this corner by simply repeating the front at the back. The shortcut fails. You have to follow another side, or learn the rule well enough to work it out. The object remains knowable; recognising a capsule was not yet knowing this one.

Stay with what the five divisions produced. Between the familiar pill and its polygonal construction, a body appears that the name did not prepare you for. Its surprise is made within the restriction. What would you miss if you corrected it into the capsule you expected?

This gives ignorance another direction: a limit in our expectation becomes somewhere to look. The same small set of instructions that confines the form can make more available than we first knew to ask of it.

<!-- @ -->

The five regular solids and the irregular rock remain around this experiment. Their symmetry and construction offer [return visits](/book?map=Primitives_Ignorance&section=tutorial). We do not need to settle every shape before leaving.

Carry a more specific question than whether the sphere is good enough: **enough to hold which distinction, for whom, at what distance?**

The polygonal model has a limit; our first understanding of its possibilities has one too. The next room follows a finite sequence of round-looking objects toward a boundary none of its examples reaches.

[^ignorance-inscription]: The Academy motto is a later tradition, not a securely documented inscription from Plato's lifetime. See [The Academy of Plato](https://mathshistory.st-andrews.ac.uk/Societies/Plato/), MacTutor History of Mathematics. The museum stages the familiar wording as an instruction whose authority we can question.

[^ignorance-plato]: Plato, [Republic, Book VI](https://classics.mit.edu/Plato/republic.7.vi.html), Benjamin Jowett translation, the divided-line discussion: drawn figures serve reasoning about geometric objects rather than being its ultimate objects. Ada's reversal is methodological: stay with the implemented figure and investigate its limits and possibilities. This does not establish that Plato was unaware of imperfect drawings, or that geometry cannot describe curves.

[^ignorance-counts]: Some generated triangle triples collapse at the poles. The counter distinguishes all submitted triples from those with measurable area in [Godot 4.6 SphereMesh](https://docs.godotengine.org/en/4.6/classes/class_spheremesh.html) arrays. “With area” excludes triangles below a local squared-cross-product tolerance of `1e-16`; it is a practical threshold. The [technical chapter](/book?map=Primitives_Ignorance&section=technical) records all four measured pairs of counts. Overlays and counter furniture are excluded. Analytic sphere descriptions and this finite polygonal rendering are different representations.

[^ignorance-capsule]: The installed `capsule.tscn` uses a [CapsuleMesh](https://docs.godotengine.org/en/4.6/classes/class_capsulemesh.html) with five radial segments and five rings. Its regular pentagonal cross-section repeats after 72 degrees, but not after 180 degrees about the long axis. The absent half-turn symmetry does not make all symmetry disappear. The scene turns at 45 degrees per second. These are the authored mesh and spin settings, not controls available on the plinth.



## Primitives_Portals

Source: commons/maps/Primitives_Portals/final.md

SHA256: 60febd9d3fccad0ebac7f78faff06616cae2ef769a3be3f882e174c0d0c592b1

The previous room asked when a finite model was enough to hold a distinction. Here we make that question move. Add a division, then another. **What would count as arriving?**

<!-- @combine_portals -->

Begin beside an early faceted ring. Follow a straight edge around its opening, then look along the progression. Choose a later ring that seems round enough from where you stand. Keep that choice in mind as you approach it. Does the edge you had stopped seeing return?

There are twenty members in this family. The first uses three divisions in each of the torus's two surface directions. Each following member adds one in one direction and two in the other. Both are changing; the last has twenty-two and forty-one.[^portals-mesh]

At the side instrument, use **NEXT RING** and **PREVIOUS** to select a member. It turns gold. Find the selected ring in the space. The button directs your attention while leaving your body where it is.

The display names the two subdivisions and counts the mesh's triangles. It also names a **separate unit polygon**. This is a simpler question placed beside the torus: how closely does a regular polygon's perimeter approach the circumference of a circle of radius one?

Predict which way its gap will move when you select a finer ring. Compare the numbers, then look at the object again. The display borrows the torus's ring count as the polygon's number of sides. Its code calculates:

```gdscript
var perimeter: float = 2.0*mesh.rings*sin(PI/mesh.rings)
```

Each straight side is a chord between two points on the circle. Adding sides brings their total length closer to the circumference, which the panel labels **Circle**. The positive gap belongs to this planar comparison; a measure of the whole torus's accuracy would need its own definition.[^portals-circle]

This is **convergence**: as the rule continues, the perimeters approach a limit. They can get arbitrarily close to the circumference, though no finite polygon in this sequence has that exact perimeter. Twenty examples show part of an approach that can continue beyond the display.

For this comparison, choose a small positive gap you would accept for a use you can describe. Check whether any displayed member meets it. That bound is a **tolerance**: a criterion for stopping. It may select a different member from your earlier judgment of “round enough”. What matters for this use?

Now predict what **REVERSE** will do. Press it and inspect the beginning again. The positions stay; the same family of resolutions appears in the opposite order. What the earlier arrangement kept for later has become the entrance.

The sequence had quietly given refinement a direction. Does walking toward more sides still describe what you want from these forms? Keep one corner in mind that you would lose by smoothing it away. Reverse again if you want to restore the earlier order.

Through this change, the openings remain. More divisions need not give the body another kind of passage.[^portals-hole]

<!-- @achilles_tortoise -->

Two figures wait along the next instrument's track. Before pressing **NEXT STEP**, point to where you think Achilles will go. Press once, compare, and predict again.

Achilles is placed where the tortoise was. The tortoise moves ahead again. In this construction the gaps halve at each stage. The marked end of the track stays where it is.[^portals-zeno]

The script chooses Achilles' next position with:

```gdscript
var a_z := -track_length * (1.0 - 1.0 / pow(2.0, float(n)))
```

Here `n` is the stage number. The minus sign sends him along this track's negative Z direction. The first stage covers half the track, the second three quarters. Each leaves a smaller distance to the same limit.

Continue to stage ten. The instrument now holds. Read **A to limit now**. Achilles' anchor still has about 5.86 millimetres to the limit, although the bodies may look as though they have arrived together. His visible body is larger than the gap. The display has a last stage. Does the sequence it represents have one?

Press **RESTART**, then **PLAY**, and pause during a movement. Compare **A to limit now** with **A to limit at stage target**. One describes where the marker is; the other describes where this movement was taking it.

The program gives these stages a regular schedule and adds movement between them. That schedule does not reproduce the shrinking durations of a continuous runner's journey. An infinite subdivision can have a finite total; it does not make ordinary motion impossible.

This instrument can pause while the museum continues. We have held one process still long enough to ask about it.

<!-- @ -->

Twenty rings. Ten stages. Each display has a last member because someone chose where to stop building it. Neither mathematical approach acquires a last step merely because its display has ended.

**The limit gives the sequence a direction. It does not tell us where to stop.**

Name something your stopping criterion leaves open for another visit. A finite encounter can teach us something without exhausting what its rules make possible.

Melencolia gathers the tools we have learned to use. They can give exact answers. What would make the work complete?

[^portals-mesh]: The installed `combine_portals` uses [Godot 4.6 TorusMesh](https://docs.godotengine.org/en/4.6/classes/class_torusmesh.html). `rings` divides the torus around its opening; `ring_segments` divides the tube's cross-section. The authored linear rule uses `(3 + i, 3 + 2i)` for indices 0–19. The panel calls the latter **Tube sides**. Its selection highlights a mesh; these rings do not implement teleportation.

[^portals-circle]: For a regular `n`-gon inscribed in a unit circle, each chord has length `2 * sin(PI/n)`, giving perimeter `2 * n * sin(PI/n)`. `TAU = 2 * PI` is the circle's circumference. In exact mathematics the perimeter is smaller for every finite `n ≥ 3` and converges to `TAU`. A useful tolerance can be met before equality. A floating-point calculation may eventually round a gap away; that is a separate computational event. The [technical chapter](/book?map=Primitives_Portals&section=technical) explains what the instrument measures.

[^portals-hole]: These subdivisions preserve the torus surface's central opening. Resolution and topology are different questions: more triangles do not give this surface another hole. Whether an opening is a usable passage also depends on scale, placement and collision. Keep that distinction for the later investigations of possible spaces.

[^portals-zeno]: Aristotle discusses the Achilles argument and the bisection argument in [Physics, Book VI, parts 2 and 9](https://classics.mit.edu/Aristotle/physics.6.vi.html), translated by R. P. Hardie and R. K. Gaye. This exhibit stages a particular halving construction: `A_n = L(1 − 2⁻ⁿ)` and `T_n = L(1 − 2⁻⁽ⁿ⁺¹⁾)`. Its six-metre track ends the display at stage ten, leaving `6/1024` metres between Achilles' anchor and the limit. Autoplay schedules stages two seconds apart and eases movement for one second. That theatrical timing is part of the implementation, not a proof about the duration of a physical race.



## Primitives_Melencolia

Source: commons/maps/Primitives_Melencolia/final.md

SHA256: 8be602c7212ff964fadc2bb0cf9d49f424f58a8d57fa146e97de0f8fdb188f66

What keeps you looking after you know the form?

<!-- @pyramid -->

Four pale blue pyramids mark the corners of a raised square. Before going closer, try to hold the arrangement in mind. Where would you put a fifth?

Walk around the court. One pyramid passes in front of another. A gap opens where two outlines seemed to meet. The objects have stayed still; your movement changes the picture. You have met this distinction before, but now the picture has become a place with room around it.

Take the side ramp onto the platform. The four corners repeat a form you can describe: a square base, four triangular sides, one apex. Five vertices, eight edges, five faces. Knowing those counts helps you recognise the family. It leaves you free to notice something else.

<!-- @pyramidlong -->

The fifth pyramid is pink, taller, and stands in the centre on a matching block. Look back at a corner. Does the centre seem to organise the others, or have you made it important because it rises above them?

Its base is still square. Its apex is still a single point above it. The tall pyramid's source collects the base vertices and then adds that point:

```gdscript
vertices.append_array(ring)
vertices.append(_apex_position(ring))
```

The same connections can carry a different height. In this version the pyramid's base is 0.8 metres wide and its apex rises 2.8 metres above that base. The pink block lifts the whole pyramid another 0.8 metres above the court. The script triangulates the square base into two faces for rendering; together with the four sides, that makes six triangles. We can explain how it is built without settling what its height does to the arrangement.

<!-- @cube_scene -->

Four ochre cubes sit around the spire in a cross. Follow that cross with your eyes, then look toward the corner pyramids. A few familiar solids are becoming a court, a monument, perhaps a model of somewhere you would like to go. Which reading arrived first?

The arrangement returns to the room's earlier floor plan. Its reference belongs to an anonymous sixteenth-century manuscript of geometric and perspective studies: solids drawn, combined and staged until a study begins to suggest an unfamiliar architecture.[^solids] Here the forms stand on a platform made from the same cube vocabulary as the museum floor. The support is already part of the picture.

Imagine one cube placed outside the cross. Its construction would be unchanged; its relation to the court would be different. You do not need to build every possibility before leaving this one.

<!-- @snap_pyramid_puzzle -->

Beside the front of the court, five snap points offer a small construction. Connect four into a base cycle and join each to the fifth. Watch what the puzzle accepts.

Its detector recognises those connections. It does not measure whether the base is square. Keep that distinction close: the program can complete its test while your question about the form remains open. The court was here before the test succeeded. Its place in the room has another history.

<!-- @ -->

## The tools are still here

<!-- @durer_scene -->

Follow the raised connection and the next ramp to the separate platform. The tableau gathers objects after Dürer's *Melencolia I*: a polyhedron, a sphere, a compass, a ladder, a numbered square. Find something you now know how to begin making. Then find something in the arrangement that this knowledge has not explained.

You have spent a chapter assembling a vocabulary. Here it returns as a scene. The compass belongs among the tools of geometry, but lying beside the other objects it also asks about work: begun, interrupted, waiting. These are possibilities for reading the tableau, not a solution hidden inside it.[^durer]

Go close to the numbered square. Choose a row and add it before reading further.

```text
16   3   2  13
 5  10  11   8
 9   6   7  12
 4  15  14   1
```

Try a column. Each row and column, and the two main diagonals, sums to 34. The 15 and 14 in the bottom row recall 1514, the year of the engraving. The numbers work.

Stay a little longer. Has that correct answer finished what you came to look at?

Perhaps the pleasure of the arrangement is enough for now. Perhaps its precision makes the interruption more palpable: these instruments can still measure, while the next action remains uncertain. We can read melancholy here without making geometry useless. We can also want the scene for the questions it keeps available.

## Enough to continue

The previous room left us approaching a curve with finite pieces. An exact mathematical description and a rendered body make different promises. More triangles can improve an approximation; they cannot decide what we should want to make with it.

Dürer's engraving is itself a made thing. An accomplished image gives us an encounter with unfinished work. That matters here. Looking, arranging, imagining and taking pleasure in a form can keep an investigation moving while its purpose is unsettled. The aesthetic attention is already doing work.

A few tools, and more possible constructions than we have time to pursue.[^sublime]

Look back toward the five pyramids. They have become another picture from here. The objects stayed still while your viewpoint changed. In transformation, you can watch from one place as objects move, turn and scale. Choose one relation from this court—the repeated corners, the tall centre, the distance between the platforms—and ask what would survive such a change.

We leave with enough to continue. There is still something here we have not finished looking at.

<!-- @ -->

[^solids]: Anonymous, sixteenth-century geometric and perspective manuscript, Herzog August Bibliothek, Cod. Guelf. 74.1 Aug. 2°. See [*Solid Objects*](https://publicdomainreview.org/collection/solid-objects/) and the [image selected for this room](https://pdimagearchive.org/images/4577a16c-d0e9-43d6-96fc-f125c47c6afe/). The court follows the drawing's blue corner spires, pink centre and ochre blocks within the earlier AdaResearch floor arrangement. Its dimensions are adapted for the museum. The manuscript is not attributed here to Dürer; its additional compound solids remain references for later studies.

[^durer]: Albrecht Dürer, *Melencolia I* (1514), [Metropolitan Museum of Art](https://www.metmuseum.org/art/collection/search/360018). The museum describes several interpretations rather than a settled key. AdaResearch stages selected objects, not a complete or geometrically exact reconstruction of the engraving. Reading aesthetic attention as a way to continue is this book's proposal.

[^sublime]: Kant's [*Critique of Judgement*](https://www.gutenberg.org/files/48433/48433-h/48433-h.htm), §§25–27, discusses the mathematical sublime through the distinction between apprehending parts and comprehending a whole; §49 describes aesthetic ideas as occasioning thought beyond what a determinate concept can exhaust. These offer a later vocabulary for this room's investigation: how a finite arrangement can keep attention moving among possibilities we have not yet specified.



# transformation

Declared order: Trans_Pre → Trans_Introduction → Trans_Translation → Trans_Rotation → Trans_Scale → Trans_Body → Trans_Pit

Museum map-authored order differs: Trans_Pre → Trans_Introduction → Trans_Translation → Trans_Rotation → Trans_Scale → Trans_Body → Trans_Pit → Biome_Ladder_Transformation. Treat this as route drift to inspect, not an editorial recommendation.


## Trans_Pre

Source: commons/maps/Trans_Pre/final.md

SHA256: 250748b3aa518b718da48b755f19c8811ce8f8a76bc6cbf757d7188e09582bab

We leave Primitives with a cube, a wedge and a grid. Now we can make a familiar game object: a Mario-style pickup cube.

Watch how its movement is built up, one addition at a time.

<!-- @pick_up_cube -->

The first cube holds still. Pause before approaching and watch a corner: nothing shifts. Then walk into it: even without an animation, it can be collected. Keep its shape in mind as you go to the next one.

This cube moves up and down. Follow it through a complete rise and fall. Its position changes while its size and facing stay the same. Moving an object from one position to another is **translation**. Here that movement follows the vertical Y direction.

The script chooses a height between two endpoints:

```gdscript
global_position.y = lerp(original_y - bob_height, original_y + bob_height, t)
```

`lerp` means **linear interpolation**: find a value between two values. Here the endpoints sit below and above the starting height. At `t = 0` the cube is at the lower end; at `t = 0.5` it is halfway; at `t = 1` it reaches the upper end. The animation runs `t` back and forth between zero and one, carrying the cube up and down at a steady speed on each leg.

The third cube keeps moving up and down. What has been added?

Follow a corner. The cube turns as well. Changing its orientation — which way it faces — is **rotation**. This line adds a small turn around the upright Y axis on each update:

```gdscript
rotate_y(rotation_speed * delta)
```

The cube can rise and turn at the same time. Both movements belong to the animation you are watching.

At the fourth cube, watch the edges move apart and come together. It grows and shrinks while it rises and turns. Changing size is **scale**.

```gdscript
var size_factor: float = lerp(1.0 - pulse_scale, 1.0 + pulse_scale, t)
_apply_pulse(size_factor)
```

The same `lerp` now chooses a size factor between 0.7 and 1.3. `_apply_pulse` multiplies the saved size by that factor. Below one, the cube becomes smaller; above one, larger. All three dimensions change together, so it keeps its cube shape.

The small markers beside the examples help you recognise each operation. Look back along the four stations. The still cube has gone if you collected it; the three moving examples remain. Recall the sequence: still; up and down; add turning; add growing and shrinking. Can you spot all three movements in the last one?

Ahead, wedges lead onto a platform with four collectible cubes. Here the finished animation belongs to a small level made from forms we already know.

Walk up and approach one. You can collect these by walking into them. The three moving demonstrations behind you stay in place for another look.

A few lines of code have given a plain cube the movement of a game pickup: **translation changes position, rotation changes orientation, scale changes size.** We will use these three operations throughout the next halls.

<!-- @ -->



## Trans_Introduction

Source: commons/maps/Trans_Introduction/final.md

SHA256: 6f3cf31ef89108c88fcbf109366be262710968857c630da5c53c22e7799acc5e

In the previous hall, a cube learned to rise, turn and swell. You could watch those movements, walk around them, leave them running.

Here the floor is missing.

Stand at the first gap. Look across, then down. The far side is already there. What would have to change for it to become somewhere you can go?

<!-- @tc -->

A cube travels between the banks. Let it make a journey without you. Its top meets the floor at each end; between them, it is a small piece of floor with nothing beside it.

Step onto it when it returns. Watch the bank you left. Now look down at the cube.

Relative to the room, you are moving. Relative to the cube, you may be standing still.

The transport script advances towards its destination:

```gdscript
global_position = global_position.move_toward(target_position, move_speed * delta)
```

The target lies two metres along the room's z direction. Each update allows another small distance, measured by speed times elapsed seconds. The cube keeps its size and facing.

That line moves the cube. Carrying you requires another relation in the implementation:

```gdscript
var movement_delta = global_position - previous_position
_translate_rider(carried_player, movement_delta)
```

The displacement just made is also applied to the supported rider. In VR, `_translate_rider` moves the collision body and the tracked viewpoint together. Contact, detection and this shared movement have to agree for the moving object to become transport. A beautiful motion can still leave someone behind.

Step off at the far bank. The cube waits, then goes back. The gap has not closed. You crossed with a temporary surface under your feet.

<!-- @sc -->

At the next gap, the green cube stays in one place. Watch its upper face. It rises as the cube grows; its edges approach the banks.

Wait until the surface is level with the floor, then walk across during its pause. Look back as it shrinks. What made a floor a moment ago is withdrawing below it.

This cube changes from half a metre to three metres on each side, about a fixed centre. The visible mesh begins as a one-metre cube. The script gives all three dimensions the same factor:

```gdscript
var scale_vec: Vector3 = Vector3(safe_scale, safe_scale, safe_scale)
mesh_instance.scale = scale_vec
box_shape.size = scale_vec
```

The last line matters to your feet. A larger image alone would not support them: the collision box must grow too. In this artifact, the two are updated together.

The centre sits below the floor so that the upper face reaches it at full size. Growth spreads downwards as well as upwards. From the bank, you might notice only the part that arrives to meet you.

The cube remains a cube. That is useful to recognise. But its relation to your body changes: something too small and too low to cross becomes a surface that carries your walk. Which description tells you what happened?

<!-- @rc -->

The third gap has a thin orange plank. Wait through a turn before stepping onto it. Across the lane, it reaches towards the sides. After a quarter-turn, its long dimension reaches along your route.

Cross while it holds that alignment. Its dimensions have not changed. Its centre has not moved. Yet a way through has appeared.

The step-and-pause rotation code assigns an angle around the upright axis:

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
```

The collision body follows the mesh's transform. Here the angle travels between zero and ninety degrees, holding for four seconds at either end. The plank is 3.6 metres long, one metre wide and 20 centimetres thick. Its upper face stays level with the floor; its ends overlap the banks when aligned.

Try following one end with your eyes. Rotation keeps the centre in place while that end travels. To say that nothing changed position would lose the very movement that makes this crossing work.

<!-- @ -->

Three gaps; three ways of making a passage. A surface carries you, a volume grows to meet the floor, a length turns towards the other bank. Each operation needs something against which its change can be read. Here there are banks, a centre, directions, dimensions—and your arriving body.

<!-- @adjustable_landing -->

Before leaving, take the side aisle to the small control marked MOVE THE BANK. The far landing rests on rails. Slide BANK a little, then watch the orange plank make its usual turn.

What did you change? The plank has the same length, the same centre, the same quarter-turn. Its destination has moved.

At the starting setting, the aligned plank overlaps the landing by thirty centimetres. Move the bank beyond that overlap and a seam opens between their surfaces. The readout measures the seam. It cannot settle what your body can do with it.

Let the plank turn again. An operation that worked a moment ago keeps running exactly as before. The crossing has lost one of its agreements.

The landing uses a translation too:

```gdscript
displacement = move_toward(displacement, target_displacement, SPEED * delta)
landing.position = HOME + Vector3.BACK * displacement
```

Here `Vector3.BACK` is the local positive z direction. The slider sets a destination up to one metre farther along it; the bank travels at a quarter of a metre per second. Its mesh and collision surface belong to the same moving body. RESET brings it back. The side aisles remain available while you compare.

<!-- @ -->

What relation makes a change possible, and what relation lets us recognise it? The banks were doing quiet work before we gave one a handle. We had treated them as the background to the experiment. Now part of that background can answer back.

The timers keep going while you think. The simulation supplies an opening and a duration. It does not know how long you need to understand what just carried you.

There is more to examine beside the route: measurements, matrices, the order of operations. For now, take the experience of crossing into the next hall. Trans_Translation will give displacement more work to do.



## Trans_Translation

Source: commons/maps/Trans_Translation/final.md

SHA256: c775cec8b9d3e70b96f2d4eea07f611cd5d5c72256a2d4116a3a82a61b23e7b0

The far bank is familiar now. In the last hall, a moving surface carried you across. Here that small surface becomes the thread through a longer space.

Before boarding, follow the line of waiting cubes with your eyes. Some hang over the pit. Others are high above the floor. Which ones could you reach from where you stand?

<!-- @tc -->

The first carrier travels into depth. Step aboard and let the room pass. Look at the cube under your feet: it keeps its facing and size. Along this journey, only its z coordinate changes.

At the next island, the route turns sideways. The carrier moves along x. You can keep looking towards the far end of the hall while travelling across it. Direction of travel and direction of attention have separated.

Then the way goes up.

Stand on the lift and watch the lower landing descend from view. It is still where it was. The carrier changes y; the room gives that change a consequence. You arrive beside an upper platform, three metres above the ground route.

The three small axis markers near the entrance have made these directions visible one at a time. Now the same distinctions have carried your body.

The transport script calculates a destination from a starting position, a direction and a distance:

```gdscript
target_position = initial_position + (move_direction * move_distance)
```

The direction is normalised before this calculation. It says which way; the distance says how far. A displacement of three metres upwards is written with a different direction from three metres forwards. The addition is the same kind of operation.

On the upper route, another carrier travels along z. You have done this before, but there is more space below your feet. What changed in the operation? What changed in the encounter?

A sideways return carries you back across x in the opposite direction. Then the next carrier moves down and forward together, like an escalator. Its surface stays level while its path slopes: three metres down, two metres further along z. Watch the pickup approach as the lower landing comes towards you.

Each carrier's top is placed at its departure deck, with its centre half a metre below. The upper lift socket needs its own starting height: the empty cell alone cannot tell us whether a journey begins above or below. The destination must meet a landing as well. Coordinates describe the ride; their agreement with the surrounding floor makes it usable.

<!-- @pick_up_cube -->

The small pickups have been waiting along these journeys. They rise and fall without turning. Their small vertical loop continues as the carrier brings you into contact with them, and each collected cube disappears with a sound.

You can return along the same displacement. The pickups already taken do not return with you.

The transport does not collect them at a distance. It adds its own movement to the detected rider:

```gdscript
var movement_delta = global_position - previous_position
_translate_rider(carried_player, movement_delta)
```

The helper moves the desktop body or the VR tracking origin with its collision body by that small displacement. It does not place the visitor at the destination. A pickup's detection area then recognises the passing body and calls `collect()`. Two small systems meet: one carries, the other notices contact. The empty place left behind belongs to their encounter.

<!-- @ -->

At the last crossing, the waiting cubes run diagonally over the pit. Watch an edge of the carrier as you travel. It does not turn.

This direction changes x and z together. The destination lies eight metres across and eight metres further into the hall. Both coordinates change during the same journey. We have combined directions without adding rotation.

Thirteen pickups mark one possible passage through seven rides. Their positions make some encounters easy and leave other parts of the arena untouched. Another arrangement could ask for another journey using exactly the same operations.

<!-- @translation_cube_demo -->

Step onto the final terrace. Two small door mechanisms wait at hand height. Their handles have the same distance to travel upwards and sideways. Try taking the diagonal.

One refuses. Its handle travels up a rail before sideways movement becomes possible. The other lets you combine those directions; a translucent door shows where you can arrive. Release a handle and take it again. The rule remains in the mechanism.

For the guided door, the code projects your displacement onto the currently permitted direction:

```gdscript
var t = (knob_pos - start).dot(phase1_dir)
knob_pos = start + phase1_dir * t
```

The full implementation also clamps the distance. Your hand can propose another path, but the handle retains only the part its current axis admits.

Up followed by sideways reaches the same position as sideways followed by up. Translation itself does not impose this order. The first mechanism does. The second gives both freedoms together. A destination can be shared by journeys with very different permissions.

<!-- @ -->

The torus beside the course already turns while its cylinder rises and falls. It offers a glimpse of the next question. Our carriers have kept their facing throughout; this neighbouring object combines the operations. Keep the difference between travelling and facing in mind. In Trans_Rotation, the turn itself will become the question.



## Trans_Rotation

Source: commons/maps/Trans_Rotation/final.md

SHA256: adb08af6b015727346427ec482fd391b0901a5e11e8c68cdddaae42547c3727a

The transport cube carried you without needing to turn. Here, a surface stays attached to its middle. Follow one end. Where does the other end go?

<!-- @rotation_wall_crossings -->

The green blade turns around y. Its centre stays over the gap while its ends sweep towards the grid. At ninety degrees it pauses. Walk across the length that has arrived in your direction of travel.

The orange blade turns around x. Look at its middle. It has no hinge at the bank. One end descends as the other rises, like a large paddle wheel.

The far landing is three grid cubes higher. During the pause, the blade makes a slope you can climb. But a slope that keeps turning does not keep offering itself as a floor. Through vertical, your feet lose their agreement with it.

Step onto the small level platform beside the orange blade's lower end. Stay there as the turn begins.

You rise, move forward, and arrive beside the higher grid. The blade's centre has stayed where it was. Your head has stayed upright. Which part turned, and which part was kept from turning?

The platform follows an arc while its surface stays level. Its sideways mounting lets the blade pass through vertical without sweeping through your body. Keeping a standing surface under you is another rule in this mechanism. Rotation does not supply it for free.

For the orange ride, the position calculation can be written:

```gdscript
var radial := Vector3(0, -1.5, -3.5)
var orbit := Basis(Vector3.RIGHT, PI * progress) * radial
var endpoint := Vector3(0, 1.5, 0) + orbit
```

`progress` runs from zero to one: half a revolution. The point goes from the lower near bank to the higher far bank; its x coordinate stays fixed. The platform adds its sideways mounting offset and shares each small displacement with a supported rider. Stepping off or jumping releases that support.

At the blue blade, z is the axis. Board from the left. This platform carries you sideways along x and up. Look down the hall while it moves. Rotation around z has no displacement along z to give you. The passage asks you to face another bank.

Both rides pause for twelve seconds, then take twelve for the half-turn. After the high pause they retrace the upper arc. Staying aboard brings you back above the basin. The grid wedges and still aisles offer other returns.

The blades remain 8.4 metres long and 2.4 wide. A centre, an axis and a length describe their turn. A standing surface, a body and a receiving bank make it a passage.

<!-- @ -->

Beyond the blades, the orientations stay still. Your movement will bring you into their differences.

<!-- @rotation_array_compare -->

Four bands each contain two columns and six rows of cubes. Begin at zero. Choose a column and walk forward along z.

Eighteen degrees. Thirty-six. Fifty-four.

The centres keep the same spacing; the angle increases with each row. Follow an outlined edge when surfaces seem continuous. It still belongs to one cube.

Try another band. Where do you climb, descend, stop? Find the row beside you, then inspect it from the still aisle.

X makes rises and falls across your route. Z makes ridges along it. Y turns square footprints while keeping their tops horizontal. The fourth band combines x, then y, then z. At intermediate rows, its edges leave the planes of the grid.

```gdscript
var degrees := float(cube.get_meta("row")) * row_angle_step
cube.basis = rotation_for_band(band, degrees)
```

The row supplies the angle; the band supplies the axis or combination. For XYZ:

```gdscript
return Basis(Vector3.BACK, radians) * Basis(Vector3.UP, radians) * Basis(Vector3.RIGHT, -radians)
```

The rightmost matrix acts first: x, then y, then z. In the previous hall, the same upward and sideways displacements could exchange order and still reach the same destination. Turns about different axes need not finish in the same orientation when their order is reversed. This band fixes its order in the code.

These angles are assigned by position, not accumulated while you wait.

The cubes have not been cut or joined. Their internal distances survive the turn; the connections available to your walk need not.

Watch the cyan bodies begin: each is 0.44 metres wide. Pink bodies follow from the same places, now 1.20 metres wide. Their height, speed, gravity and forward instruction stay the same. Rings keep the first endpoints. Readouts record distance, stopping and sideways displacement. REPLAY begins both passes again.

You might expect wider to mean worse. Watch z before deciding. Here the narrow body catches on a ridge; the wider one can slide sideways and continue. Its changed route matters as much as its arrival.

The capsules neither jump nor choose a detour. The collision solver supplies their slides. You can walk through them without pushing them, and try your own movement. A stopped trial belongs to this body and these rules. It has not exhausted the space.

<!-- @ -->

The final row reaches ninety degrees. A cube can recover an axis-aligned outline there. The way to that flat-looking end still passes through everything before it. More rotation does not promise more obstruction.

Compare the first and last orientations. A plain cube turned ninety degrees about an axis through the centres of two opposite faces occupies the same shape. Yet a corner has changed places. A mark on one face would make the return a difference you could follow.

The array holds these orientations still. The blades let you encounter the journey between them. A shape can return without giving back the time it took, or undoing where it carried you. What would you need to keep in order to notice that something happened?[^turning-studies]

Walk on into the last court. Let the repeated turns surround you.

<!-- @boolean_tunnel -->

Look through the first hollow cube. Four more stand beyond it. Walk inside and follow a corner with your eye.

Each segment adds eighteen degrees.

```gdscript
angle_deg = i * rotation_per_segment
```

Five segments occupy fifteen metres. They stand still; your walk unfolds their differences. Turn back and the sequence unwinds.

Subtracting an inner box made each cube hollow. The turns arrange those openings around a continuous floor.

Which edge did you take for a horizon?

<!-- @carousel_cake -->

Step out beside the turning stacks. Follow a stripe on a low layer, then near the top. Stand still. Their relations keep changing.

```gdscript
var layer_speed: float = base_rotation_speed * pow(rotation_speed_multiplier, float(i))
var angle: float = _rotation_angle * layer_speed
```

The lowest layer turns at half a radian per second; each successive layer turns 1.2 times as fast. In the tunnel, eighteen degrees separated neighbours. Here a rate changes the angle through time.

Eight layers make each of the five profiles: a brim, a column, a taper, a pinched spindle, a flare. They share heights and speeds. Walk between them and compare the room each leaves around itself.

Your body has supplied a measure throughout this hall: what could carry it, obstruct it, surround it. The next hall changes the size of the surroundings while your body stays the same. What will fit then?

[^turning-studies]: The [rotating-drum and axial-sweep studies](http://localhost:3003/research/possible-bodies/transformation-zoetrope.html) extend this question. Twelve fixed poses travel on a turning carrier; beside them, one body turns about its own axis. A centred cube sweeps a cylindrical volume, while the specified triangular profile sweeps a cone. The optional contours record the outer boundary of that full turn; they do not make it solid. These experiments are available in the research preview and test scene, awaiting placement in the museum. Their felt continuity still needs a headset encounter.



## Trans_Scale

Source: commons/maps/Trans_Scale/final.md

SHA256: ee9cbc1847e08e342a55cb7f63d07623da6665af664f0666de6ed2fa578cd18f

# A door, at last

<!-- @scale_me -->

In the rotation hall, you tried the openings against the size of your body. Here, something waits to be taken.

A figure stands behind a tower of food. Crystal grows through her suit; broad panels lean around her body. The food has begun to flower. Porcelain plates climb above it, and smaller serving plates wind down the side. These are familiar enough to approach, strange enough to keep looking at. In the far wall, beside the figure, a little gold frame surrounds a door.

Try to put yourself through it.

You can see the opening. You can point to the space beyond. Your body will not follow. For the moment, calling it an exit describes somebody else's possibility.

There is a bottle on the highest plate. DRINK ME. Take it.

A cut. Now the plate is under your feet. The figure rises beyond you, her leaning panels large enough to seem architectural. The table has become a place to stand. Look down along the serving plates. What could be read at a glance now asks for a journey.

The bottle is gone. You have not watched the room swell through the sizes between. Everything around it is suddenly four times as large: the food, the figure, the room, the spaces between them. Your body has kept its size. The effect may feel like shrinking. The program has made that feeling by changing the other side of the comparison.

```gdscript
room.scale = Vector3.ONE * FACTOR
```

`FACTOR` is four. The food and the figure belong to `room`, so the same multiplication reaches their positions as well as their dimensions. The figure is farther from the table now. Enlarging a mesh by itself would have left her standing in the wrong relationship to it.

The arrival on the plate is another operation. Scaling the room would not put you there. The program takes the top plate's local position and asks where it has arrived in the enlarged world:

```gdscript
var feet := table.to_global(landings[0]) + Vector3.UP*0.08
```

Then it moves your body to that position. The multiplication and the relocation arrive together as an encounter, but they do different work. One changes the room; the other chooses where you meet it again. A small clearance keeps your feet out of the porcelain.

Follow the plates down. Their winding descent was already present when they were small. Nothing in their arrangement needed to be invented after you took the bottle. Yet the distance from one to the next now belongs to balance, gravity and the time spent falling. The program did not multiply your walking speed or the gravity with the room. Uniform scaling has left a very uneven experience.

Find the little door again. It was forty-five centimetres wide and sixty high. Now it is 1.8 metres wide and 2.4 high. Walk through.

Just beyond it stands a second gold frame, also 1.8 metres wide and 2.4 high. Pass through that one too. It stood at this size before you took the bottle.

The little doorway has kept its proportions. There is a difference between preserving a shape and preserving what someone can do there.

The figure has not become hostile by becoming enormous. Her unfamiliar body remains with you through the change. The same is true of the food: its strangeness preceded its usefulness as a landscape. You can learn a route through something without exhausting what it is.

Beyond the two frames, turn toward the museum's own exit. The little door has brought you out of the furnished room; there is still a short walk to the next hall. The museum continues at its ordinary scale. The second frame belongs to it. That boundary belongs to the code too: this room was chosen as the thing that could grow. The next hall returns the question to the body that made the comparison possible.

<!-- @ -->



## Trans_Body

Source: commons/maps/Trans_Body/final.md

SHA256: a61584f0b9ee47b1faec56c21ce4c7e53a84f08a51ffd5e5ed6c92be91f261da

The corridor narrows, and then it stops.

<!-- @approach_wall -->

A wall of upright slats stands across the way. There is no handle, no plate, no light that turns green. Walk at it.

The slats near you turn out of the plane, and the ones further off do not. The opening centres on where you stand rather than on the wall. Step sideways along the face and the opening comes with you; step back and it closes.

The distance part of the rule can be written simply, for a visitor within reach:

```gdscript
var t: float = absf(slat_x - visitor_x) / aperture_m
var d: float = absf(visitor_z) / reach_m
var openness: float = (1.0 - t) * (1.0 - d)
```

Two distances, multiplied. The implementation smooths this value and opens a neighbouring run of slats far enough for a body to pass. The first is how far this slat is from you along the wall; the second is how far you are from the wall. The slat does not know whether you meant to come. Its mechanism holds which side you approached from while it swings, then settles back. Even this small response needs a little state.

A door gives you a place to approach. This wall lets the place of approach move with you. Someone has still chosen how close counts as close, how wide the opening should become, and which collision bodies it will notice. The invitation has dimensions. The slats remain attached to their hinges, the material is the same, nothing has been consumed. Your position changes what that arrangement allows.

Look back while you are still close: a slat may stay open for you. Continue into the space beyond its reach and wait for it to close. Crossing the plane and leaving the wall's attention are different distances.

<!-- @carve_grid -->

The next throat holds a low block of small cubes, about 1.3 metres high. You can look over it. The lattice reaches across the way, but it does not enclose your head.

Press into it. The cubes your body touches stop existing.

They are removed. You advance a shell at a time, leaving an open-topped cut through the block. For a standing visitor this is closer to a trench than a tunnel. Your view was above it before your legs had a way through.

The test is one line, and the interesting part is a number:

```gdscript
@export var bite_m: float = 0.16
```

The lattice is solid and so are you, so the physics engine stops you at the surface and your collider never actually overlaps a cube. A lattice that deleted only what it strictly intersected would delete nothing, for ever, and would look exactly like this one. `bite_m` is the margin by which you are allowed to reach past the place you were stopped. At zero the room is a wall. At 0.16 against a 0.34 cell it clears about one shell per press.

Your movement supplies the input, but the operation on the lattice is deletion. Translation alone would leave every cube somewhere. Here the count changes. The whole behaviour also hangs on a tolerance: the difference between a body being stopped and a position allowed to reach beyond it.

The cut stays while this room remains loaded. Look at its stepped sides. It records where the lattice met the collision shape used for your body, expanded by that small margin. The cubes can only retain the contact at their own resolution. Some of you passed above the entire record.

Somebody following behind you will find the cut already made. Will their body fit the passage yours left?

<!-- @approach_scale -->

Nine blocks, set closer together than a pair of shoulders. At rest the gap between neighbours is thirty-five centimetres, which is not "tight". It is shut.

Walk in anyway.

```gdscript
var t: float = clampf(sqrt(_dist2[i]) / reach_m, 0.0, 1.0)
t = t * t * (3.0 - 2.0 * t)
return lerpf(min_scale, 1.0, t)
```

Each block reads its own distance to the nearest body and takes a size from it. Close, it goes to about a third; far, it is whole. Each block keeps its place in the horizontal grid. Its visible mesh and collision box shrink together; their centres lower to keep the bottom face on the floor. Nothing is deleted. The gap changes because your distance has become a size.

So the gap you walk through was not made by clearing anything. It was made by measuring.

Look behind you near the last row. Some blocks may still be small: you have passed them, but they still measure you. Walk on towards the far end of the room. Once you are outside their reach, the field fills out again. The caption asks you to step clear; it cannot declare that you already have.

In the next room, another block will grow across your route. There, a clock supplies the factor. It will grow if you approach, if you wait, if you turn away. Here you can ask for room by moving closer. There you must learn a rhythm that does not read you.

<!-- @ -->

Three thresholds, and no button asked for your request. The input was already arriving with your body. The wall is still a wall, the blocks still have their places, and the lattice alone retains a visible cut while the room stays loaded.

In every other room in this chapter you have watched a cube be moved, turned or grown. Here your approach has turned slats, removed cells and reduced blocks. Two boundaries return; one keeps the cut. Walking felt like walking, while the room was doing different kinds of work.

What the room offers depends on the body its code can recognise. The next room continues changing even when you stand still.



## Trans_Pit

Source: commons/maps/Trans_Pit/final.md

SHA256: dc436620b38a7d1a621506e94791b3dfcfaebda3342575d9a2178fae326672fd

A wall can arrive on level ground. You can wait beside its path, or step into the space it is about to occupy.

Three rooms in a row: translating blocks, turning slabs, growing cubes. The ground stays level through the studies. There is a way around the first lanes and room to watch the others from beside them. Entering an obstacle's space is a choice you can make after seeing what it does.

Wait on the landing. Which opening is arriving, and which is about to go?

## Translation, from inside

<!-- @pusher_block -->

Three red blocks, each with an arrow on its face. Follow one through a complete journey before entering its path. It travels, stops, returns and stops again. The pause is part of the movement you need to learn.

The pusher's script advances a fraction along a line:

```gdscript
var speed_normalized: float = push_speed / push_distance
_t += _direction * speed_normalized * delta
_t = clampf(_t, 0.0, 1.0)
var target_pos: Vector3 = _start_pos.lerp(_end_pos, _t)
_body.global_position = target_pos
```

`_t` is not a distance. Zero gives the starting point; one gives the endpoint. Dividing speed by distance converts metres per second into a fraction of the journey per second. At either end the script waits, then changes the sign of `_direction`.

Each block travels two metres, but the journeys take different times: about one and a third seconds, one second, just over one second. Their pauses differ too. Two advance along Z; the third goes the other way. An opening that works for the first does not give you the timing of the next.

From outside, a pusher changes position and keeps its dimensions. From inside, standing where it wants to be, it is a wall that arrives. Look at the space beside its path as carefully as the path itself. Here the eastern passage lets you walk around. Try a lane because you want to compare its timing, then return to the place where you can watch. The room does not need to trap you for the moving boundary to become legible.

<!-- @ -->

## Rotation, from inside

<!-- @rc -->

The middle room has two orange turning slabs. Watch one end while the centre stays put. It takes two seconds to make a quarter-turn, waits, then reverses. One slab pauses for four seconds; the other for three.

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
static_body.transform = mesh_instance.transform
```

The collision follows the visible angle. These are the chapter's rotation cubes with their upright wall profile, not the narrow bridge from the Introduction. Across its strip of floor, the broad face occupies more width. Turned edge-on, it leaves more room beside it. The open middle route also lets you keep your distance; these are studies you can enter, not locks on the exit.

Its dimensions have not changed. The space it occupies has. A pivot is a fixed point, but it does not make the rest of the object stay still.

Look at the floor just beyond the slab's present edge. It is empty now. Follow the edge into it. The space this slab sweeps through is larger than the space one pose shows. Your place can become part of its turn without you taking a step.

Balls arrive from the side platforms as well. Let one cross the scene while you watch the slab. There is more than one clock here, and their movements do not wait for you to finish comparing them.

## Scale, from inside

<!-- @grower_block -->

The last room has three cubes sharing a tempo. Wait before approaching. They grow anyway. Watch them together first; the repetition makes the size change easier to read.

The previous hall's blocks made room when you came close. These read elapsed time. Walking towards them, standing still and turning away all leave the same clock running.

For this floor-anchored configuration, the size factor comes from:

```gdscript
var t: float = (1.0 - cos(_time)) * 0.5
var current_scale: float = lerpf(min_scale, max_scale, t)
```

The clock advances by `delta * grow_speed * TAU`. With `grow_speed = 0.15`, a complete small–large–small cycle takes about six and two-thirds seconds. All three use that rate. The factor runs between 0.3 and 3.5; with a one-metre base size, those are also the cube's side lengths in metres.

Watch a bottom edge. It stays on the floor. The mesh and collision box grow together, with their centres kept half a side-length above that edge. Growth takes space upwards and sideways rather than passing through the ground.

As a cube expands, its colour warms. Choose a gap and watch it narrow and widen. You can compare a passable interval with an interval that would make you wait, without calling every hesitation a failure. This instance scales all three axes equally, so the cube keeps its proportions. The gap beside it has no such guarantee. Your available space is the remainder after its growth.

<!-- @ -->

## The constant

The floor supports the operations. Which body can use the openings? A translation preserves the block's dimensions. A rotation preserves distances within the slab. Here, uniform scaling preserves the cube's proportions. Those statements describe the object. Clearance also depends on your width, your pace, your viewpoint and the collision shape the program gives you. A gap that comfortably fits one body can demand another's detour.

The block can come back to its starting place. The slab can recover its earlier angle. The growing cube can return to its small size. Each return can look like the beginning again. For the body waiting beside it, a passage has opened and closed in between. Sameness depends on which part of the encounter you keep.

This is the chapter turned round: operations that carried you or made a passage can also occupy it. In this room, the way around is part of the arrangement. Choosing it is another way to read what the space permits.

The matrices did not become false when you entered the room. They became insufficient as descriptions of what the room allows.

## Make room

<!-- @transformation_airlock -->

After the growing cubes, two armoured leaves meet inside a heavy frame. Approach, then stop. Follow the bright strip along one leaf.

It moves sideways and up. It turns through a quarter-turn. Then it becomes smaller, drawing its armour into a recess beside the opening. The frame has stayed still. The passage has changed.

These are the same three operations we added to the pickup cube at the beginning of the chapter. There they made a small object conspicuous. Here they make room for you.

The door keeps a fraction of its opening, from zero to one. Three overlapping intervals of that fraction drive position, angle and size:

```gdscript
var factor: float = lerpf(1.0, 0.34, operations.z)
var at := Vector3(side * lerpf(0.75, 2.15, operations.x), lerpf(1.4, 2.0, operations.x), -0.26)
var turn := Basis(Vector3.BACK, side * operations.y * PI * 0.5)
```

`side` gives the leaves opposite directions. The local Z axis points through the doorway, so these turns happen across its face. Each leaf ends at thirty-four percent of its original size. Its collision shape changes with it: the visible opening is also an opening your body can use.

Walk through. The door stays open while someone is near it. Once everyone leaves its clearance area, it waits three seconds and reverses. You can return from the other side and open it again. No pickup count decides whether you may enter.

A moving boundary has become a welcome. That welcome, too, has been written: how near you must come, how much room the frame leaves, how long the door waits. What else could these three operations make possible?

<!-- @ -->



# array_tutorial

Declared order: Array → Tutorial_3D → Tutorial_Tiling_Floor → Tutorial_Tiling_Walls → Tutorial_Disco


## Array

Source: commons/maps/Array/final.md

SHA256: 284c994eb651878a5566e2b118143ea6b835c641e63ea09e5ead46674601bada

What remains at an address after its occupant has gone?

This is the cube we met at the beginning of Transformation. There, one body acquired movement, orientation and scale. Here it has company. We have made copies, placed them apart, and given each a number. What can we do with many that we could not do with one?

Keep a position in mind while the thing occupying it disappears. Begin with the row before extending the same question across a grid.

<!-- @row_3_x -->

Find the four numbered positions. Choose one cube and read its address before approaching it. Predict which entry in the accompanying table will change when your body collects the cube. Then make contact and compare the table with the space you remember.

The cube disappears. Its entry changes from one to zero, while the other entries keep their values. Point to the former position without relying on the cube to mark it. An empty slot can still have an address.

An array keeps values in an indexed sequence. In this row, the index identifies a slot and the value records whether its cube remains present. The number naming the slot and the number stored there do different jobs. Changing the stored value does not require renumbering every position after it.

The removal event supplies the update. This is a collection by contact; the exercise does not require carrying the cube somewhere else. The table knows that its occupant has left, without keeping a destination for it.

<!-- @grid_2d_4x4 -->

Now choose a cube in the grid. Its address stands on a small plate at its feet. Give its two indices to a companion, or say them to yourself before moving. Predict both the table entry that will change and what will remain readable after collection. Collect the cube, then locate the empty place again.

Two indices distinguish positions along two directions. This grid writes them as [x, z]. In its table, the first index selects a row and the second a column. Exchanging them can name a different slot even though the same two numbers were used. Try choosing an off-diagonal position where that exchange would be visible.

The grid adds a way of locating values, rather than a new kind of cube. A zero here means absence under this particular rule. In another array it could mean a measured quantity, a silent beat or a legitimate category. The data structure does not supply that meaning on its own.

<!-- @ -->

Compare the two empty places. In the row, the cube took its label with it. In the grid, the plate still names the slot. Both tables record absence; the spaces give you different help in locating it. Ask a companion to name an empty slot without pointing, or turn away and find it again yourself. Which arrangement lets the address survive without depending on your memory?

Give an empty slot another meaning: a reserved place, a rest, something waiting to arrive. Does the zero distinguish any of those? The plate preserves where, while the stored value leaves why unresolved. Decide what additional record your chosen meaning would need.

The regular spacing helps you find a slot, but the address and the spacing are different decisions. We could place the same indexed cubes at unequal distances. An array needs a way to distinguish its entries; it does not require them to look alike, stand straight or remain occupied.

Carry forward two separate questions: where is the slot, and what happened to its occupant? In the next hall the copies rise above your head. A third index names a layer. To visit those layers, your body will need a permission that the array itself cannot give.



## Tutorial_3D

Source: commons/maps/Tutorial_3D/final.md

SHA256: 631a0b9e559b4b203c42862654f3a8c34f8de7725097caa4eb5f71889e57af8d

How do you reach an address above your head?

The familiar cubes have risen into a volume. Four across, four upwards, four deep: sixty-four possible encounters. Before entering, follow one vertical line with your eyes. Which part of the address changes as it climbs?

<!-- @array_flight_lab -->

At the console beside the glass enclosure, press Y +. A transparent marker moves up one layer. Press X +, then Z +. Each button changes one index; after three it returns to zero. Read the selected address before looking for its cube. The marker helps you locate the slot, including a slot whose occupant has gone.

Walk through the ground-level opening. Inside this frame you can fly. On desktop, look and use WASD, with Space to rise and Ctrl to descend. In VR, the left stick follows the tilted left controller. Release the controls to hover. The permission belongs to this enclosure; descend to either ground-level doorway to leave it.

Rise beside a column, then move between layers. The cubes are spaced 2.4 metres apart. There is room for a body between neighbouring samples. An indexed volume need not be a solid block.

The placement extends the earlier row's operation along three directions:

```gdscript
cube_instance.position = Vector3(x * spacing, y * spacing, z * spacing)
```

An index becomes a position through this multiplication. Changing the spacing would change the distances you travel without adding an entry. Changing the number of entries would be another operation. The glass frame is another decision again: it supplies the boundary within which this particular body can move vertically.

Choose an address, approach its cube and collect it by contact. Return to the console and select that address. Its value is now zero. The other cubes have not slid into the vacancy. This small record writes collection as an absence:

```gdscript
values[y][z][x] = 0
```

The display names coordinates in x, y, z order; the nested storage selects a y layer, then a z row, then an x entry. Those conventions must be connected explicitly. Neither a list nor a number arrives with a direction built into it.

<!-- @ -->

Hover where a cube used to be. For a moment, your body occupies the neighbourhood of a recorded absence. The table still says zero: it records cubes, not everything that could exist there. What would have to change for it to notice you?

The third index has extended what we can address. Flight has extended what we can reach. Keep those changes separate as you descend. Next, we return to the ground and ask how one small shape can organise a whole surface.



## Tutorial_Tiling_Floor

Source: commons/maps/Tutorial_Tiling_Floor/final.md

SHA256: ed5b723510dc25c3146752eed153663501d670e0a969a5a4bfe5375b05f3a113

How much floor can one small decision make?

The cubes gave us addresses. Now the addresses receive a motif: a square divided diagonally into black and white. Six fields lie underfoot. Before reading their names, find two that seem related. What has stayed the same between them?

<!-- @tiling_principles -->

Begin at TRANSLATE. Follow the diagonal through a row. The same square returns at the next address with the same orientation. A single tile has become a field through placement.

At ALTERNATE, neighbouring tiles exchange black and white. At QUARTER TURN, the tile's orientation advances with its address. REFLECT reverses it in alternate columns. SHIFT ROWS displaces every other row by half a tile. Walk between these fields before trying to name the larger shapes you see. A chevron or a band may belong to several tiles together. The unit that you notice need not be the unit stored by the program.

At the entrance console, press TURN MOTIF. The source triangle turns ninety degrees in all six fields. Their arrangement rules remain in place. Compare TRANSLATE with REFLECT again. One changed source can have different consequences under different rules.

This is one of the instructions making those differences:

```gdscript
if rule == 2: rotation += (cx+cy)%4
```

The cell address contributes an orientation. The remainder after division by four gives four returning positions. No tile has to remember the whole field. Its local address and the rule are enough to decide its turn.

Now look at ONE EXCEPTION. Initially it repeats the unexceptional translation field. Press EXCEPTION. One cell turns an extra quarter turn; the other five fields stay as they were. Find the difference from a distance, then approach it. Does it read as a direction, an error, an opening? The code supplies a difference without deciding what it should mean to you.

These are flat images on the floor. Their dark triangles are not holes, and the apparent ridges do not lift your feet. Walk across a boundary while watching it. The picture can divide a space that the collision surface keeps continuous.

<!-- @ -->

Black and white already make figure and ground. We have limited the palette to make the arrangement easier to compare; we have not removed perception from the experiment.

Turn the exception off, then on once more. A common source makes repetition economical. A local exception needs somewhere else to be recorded. This distinction will matter when the pattern reaches a wall, a room and a body. First, let the same six rules stand up.



## Tutorial_Tiling_Walls

Source: commons/maps/Tutorial_Tiling_Walls/final.md

SHA256: 62c95f4cb872cee8bf0b0ff402610e368d21ca95dc1140e5c02b7e533f2fbc8f

What changes when a floor stands up?

The same six black and white studies have become walls. Walk along the central aisle. A field that was beneath your feet now faces you; its far edge no longer disappears in quite the same way.

<!-- @tiling_principles -->

Find TRANSLATE and QUARTER TURN. Approach until one square becomes easy to distinguish, then step back until several squares begin to make another figure. The source has not acquired more detail. Your distance changes which relations are easiest to see.

The six panels use the same image generator as the previous floor. Each is five metres across and five metres high, with a solid backing. TURN MOTIF rotates the source in all six. EXCEPTION changes one cell in the field that carries that name. Repeat one comparison from the previous hall. Which arrangement becomes more insistent when it occupies your forward view?

Behind both versions, the program assigns each pixel one of two values:

```gdscript
image_.set_pixel(x,y,Color.BLACK if black else Color.WHITE)
```

The wall does not introduce another tiling rule. It gives the image another orientation, scale of encounter and physical support. A black triangle on this surface is still a colour value. The backing, with its separate collision, is what stops your body.

Walk beside the reflected field. The diagonals change their apparent angles as you pass. The stored image stays fixed. Perspective is doing some of the work that we might otherwise attribute to the pattern.

At SHIFT ROWS, follow a horizontal joint. The offset asks the next row to begin halfway through the interval you expected. At ONE EXCEPTION, find the isolated turn again. On a whole wall, a single difference can become a landmark. Could you use it to tell someone where to meet you?

<!-- @ -->

We have carried one small motif through several relations, then changed the surface that receives it. The image gives the wall a rhythm; the wall gives that rhythm a place in your walk. Neither account is complete on its own.

The next floor will add a clock. Keep watching the distinction between a value, an address and the act of reading it. Repetition is about to arrive in time as well as space.



## Tutorial_Disco

Source: commons/maps/Tutorial_Disco/final.md

SHA256: c4ee9f710640b8543cff6a0370def14ba21b85200b84b256a1d27e0803f14729

How can an arrangement that sits still make a rhythm?

You have seen slots hold values and a motif repeat across floors and walls. Here the floor is black and white again, but its arrangement moves. Begin by stopping one of its clocks.

<!-- @disco_controls -->

Press PLAY / HOLD at the floor console. Watch the pattern settle. Press ONE STEP: the next arrangement arrives without waiting for the automatic clock. Change PATTERN while holding. CHECKER alternates the tiles, ROWS visits one row at a time, DIAGONALS sends bands across the addresses, and SNAKE follows a route that reverses direction in every other row.

Start playback, then change SPEED. The same rule can hurry or wait. This small expression supplies the checker:

```gdscript
return (x+z+phase)%2
```

Two spatial indices and a changing phase enter the same remainder operation. The tiles have not moved; the values displayed at their addresses have changed. Stand on one tile and watch what arrives there. Then cross the floor and let your movement meet its movement.

The console controls this visual clock. Beside it, the sequencer has another. Begin with one cell and listen for the time it becomes audible.

<!-- @step_sequencer -->

Find the sequencer's grid. Select the empty pattern and turn on one cell. Activating it previews its sound immediately. Let that preview finish, then start playback and predict when the moving playhead will reach the chosen column. Compare the returning note with the highlighted column. Let the loop come round before changing anything else.

Turn that cell off and watch the same column on the next pass. Its address remains visible, but it requests no new note. This is the array room's question in another material: the slot remains available when its value changes. Here you can turn the value back on and repeat the comparison without rebuilding the room.

Turn the first cell back on, then add another active cell in the same track. Listen to the distance between the two events. Move the second event by turning its old cell off and another cell on. The instrument can remain the same while the rhythm changes, because a position in the pattern determines when that instrument is asked to sound.

Each row is a track, each column a step. An active cell requests an event when the playhead reaches it. The visible grid is stored state; playback repeatedly reads that state in a particular order. The pattern can wait without making a sound, and the playhead can move past inactive cells without adding a note.

Change the tempo and listen again. The active cells retain their addresses while the time taken to visit them changes. A pattern's arrangement and its rate of playback are separate choices. Return to the earlier tempo before making your next comparison, so you can hear which change belongs to the pattern itself.

<!-- @standalone_disco -->

Stop the sequencer and predict whether the floor will stop too. Watch before restarting. Its patterns continue while the floor console is set to PLAY; the floor's movement is not all a record of musical events. Conversely, holding the floor's pattern does not stop the sequencer or disable its brief flashes. To inspect a still image, stop both.

Restart with one active cell. The bridge briefly brightens a floor column when that step sounds, adding a response to the continuing animation. The next floor update can obscure the flash, so keep the sequencer's highlighted column as your reference when comparing sound and light.

There are sixteen steps but twelve floor columns. The mapping wraps: the first and thirteenth steps brighten the same column. Try them separately in the second track. A single floor flash cannot distinguish those two addresses, although the sequencer still can. A representation can preserve an event while folding together some of the information about where it came from.

Walk with a pulse, then keep your own rhythm across it. Distinguish the score, the floor's independent animation and your movement. The bridge sends sequencer events to the floor; it does not record your footsteps into the pattern. Sharing a space with a rhythm is different from being measured by it.

<!-- @ -->

Put a beat somewhere that interrupts the repetition you expected. Does it become a mistake, an accent, or the part you wait for? The grid supplies available positions and sounds. It does not decide which of their arrangements you should want.

A gesture falling between steps would need another representation if its timing were to be retained. Imagine what you would add to preserve that chosen difference, then listen to what can already be made within the current grid. Precision and pleasure need not ask the same question.

The colour rooms continue with another arrangement whose parts change how their neighbours are experienced. Carry the distinction between a stored value and the relation through which you encounter it.



# color

Declared order: Color_Context_Placed → Color_Flashlight → Color_Nails → Color_Rainbow → Color_Pillar → Color_Grid_Pallet → Color_Paint → Color_Walls → Chamber_Color

Museum map-authored order differs: Color_Context_Placed → Color_Flashlight → Color_Nails → Color_Rainbow → Color_Pillar → Color_Grid_Pallet → Color_Paint → Color_Walls → Chamber_Color → Biome_Ladder_Color. Treat this as route drift to inspect, not an editorial recommendation.


## Color_Context_Placed

Source: commons/maps/Color_Context_Placed/final.md

SHA256: a9a7843f170cc575b9b0957f803d2a8cbd0ee97e8e9384384864564542ac762f

# Before we ask what colour is

<!-- @chroma_stack -->

Colour has been here all along. It was in the rooms before we gave it a chapter. Now walk into this long hall and look at what we have brought with us.

A block, a sphere, a wedge: the primitives. Their positions, turns and proportions: transformation. One piece followed by another, each with an address in a list: arrays. The columns gather these earlier lessons into bodies we can walk around. The turns are already over. The movement is yours.

This is our way into colour. We have learned enough to build something, repeat a choice, change it and look again.

Begin with the four columns near the entrance. Each has the same five pieces in the same positions. One ochre covers the first from foot to crown. Beside it, the blocks are red and the round forms blue. Follow a block from one column to the other. Does it still belong to the whole in the same way?

The geometry has stayed still. Colour gives you another way to gather it, or take it apart.

The third column assigns colour by height. Two blocks can now disagree. In the fourth, each colour is calculated from the one below: the hue moves halfway around the hue circle, then halfway again. Two colours alternate up the stack. A neighbour has become an input.

The pieces are stored in an array. The builder begins each turn through it like this:

```gdscript
for i in range(elements.size()):
    var e: Dictionary = elements[i]
```

`i` is the address; `e` is the piece found there. The rest of the loop builds its shape, assigns its colour and places it above the previous piece. An array has an order. The builder makes that order climb. We could read the same list into another arrangement; here, *next* becomes *above*.

Further down, the colour assignment stays while the alphabet changes. Blocks and round forms give way to cylinders, a ring and a cone, then to blocks and wedges. The cone and wedge share yellow. Their grouping is a choice in the code. Nothing in a triangle requires yellow; here, yellow helps us recognise a relation someone has chosen to make.

Now find the four columns made from blocks and wedges. One keeps its levels aligned. In the next, each level has been turned another twenty-two and a half degrees. The third narrows successive levels across X and Z. The fourth combines the turns and narrowing. Follow the yellow through the changing silhouette. What remains easy to recognise?

These are the conditions we can hold and vary. We can keep the geometry and change its material, or keep the colour assignment and change the geometry. The material receives a value through one small line:

```gdscript
m.albedo_color = c
```

That gives the surface a base colour for the renderer to work with. Illumination, the surrounding scene and the display still participate in its appearance. The assignment is precise; it gives us something we can return to when the appearance raises a question.

Colour is deeply scientific and deeply associative. We can ask how light, surfaces and vision make a colour available to us, and how to measure it under specified conditions. We can also find ourselves remembering a room, wanting a garment, recognising a warning. Both kinds of attention can begin at the same patch of colour. A value in the material gives us a handle on the construction. What the colour calls up may lead elsewhere.

The next four stacks loosen the proportions. A large red sphere meets a small red sphere, with a dark cap between them. The red lets you follow a relation across a difference in size. Beside it, thin discs interrupt heavier forms. A narrow stem carries a broad crown. Your eye may supply a weight that the code has not calculated: these objects are fixed in place, with no simulation of balance.

Further across, slabs turn and pieces leave the centre. It is still a stack, but being above no longer means sharing an axis. In the fourth construction, pink, teal, yellow and blue accompany wedges, discs, a block and round beads. Colour is now chosen piece by piece. What might the same forms become in another palette?

The vocabulary is familiar. The combinations are beginning to exceed what we first asked it to do.

<!-- @color_dna_stack -->

The columns grow taller. White, red, blue and yellow blocks separated by thin dark levels carry the gallery's reference to Mondrian. Four diminishing blocks in warm colours come from its Albers study. Pink and teal enter the Memphis stack; eight different primitives gather into the taller Bauhaus study. These are composed adaptations of references. You can inspect their proportions and colour choices even if the names are new to you.

Recognition adds another kind of company. A palette can arrive with memories of paintings, furniture, toys or interiors. Those associations may draw your attention to a colour before you begin to measure it. They may also make a combination feel familiar so quickly that you stop looking. Stay with one of the columns a little longer. Find a detail its name did not tell you to expect.

The next pair rises above you: angular and round forms in two blues, then a tall striped shaft under a broad dark cap. Walk around the striped column. New colours come into view. The object has not turned.

This is the gallery's `ps07_kras_rainbow`, with its shaft raised to 6.2 metres. Thirty stripes take their colours from an array of six entries:

```gdscript
var col_idx: int = i % stripe_colors.size()
var col_val = stripe_colors[col_idx]
```

The remainder sends the index back to the start of the palette after every six stripes. The six-colour order repeats five times around the shaft. Arrays and transformations have brought us here again: a list of colours, repeated pieces, positions and turns around a circle.

If a Pride flag, a sweet wrapper or a fairground comes to mind, the array has not stored that memory. The arrangement meets something you bring. Someone else may arrive at another association, or stay with the stripes. Learning the rule gives us more to notice in that meeting.

The broad cap once belonged to a table-sized construction. Now it is overhead. A change in height has changed its relation to your reach. At the end of the hall, that cap carries another stack. The rainbow shaft and eight-piece Bauhaus crown become a 7.2-metre column. Beside it, Memphis blocks, a striped shaft and red beads rise to 7.4 metres. Whole configurations become parts of another body.

<!-- @ -->

We have brought primitives, transformations and arrays into composition. They let us specify what is built, keep a choice, vary it and share the construction with someone else. Colour enters that structure and opens further relations: between parts, between a surface and its surroundings, between something seen and something remembered.

We can begin with those relations before we know how to account for them. In the next hall, keep the surface and move the light. What happens to the colour then?



## Color_Flashlight

Source: commons/maps/Color_Flashlight/final.md

SHA256: 4f848a7a7d892bb9616d310b114570014e6832b1b2fba51ddb3bac83b1f53673

# What reaches the surface

<!-- @flashlight_demo -->

The colour is already there when you arrive. Several pools meet on a pale surface. Their edges are easier to follow than their crowded middle. Pick one edge. Which lamp is responsible for it?

Take the red lamp and turn it aside. Follow what leaves the surface. Bring it back slowly, across the other pools. There is a place where its red becomes difficult to name on its own. Move through that place again. Nothing has been painted over, yet something has appeared that neither lamp makes alone.

Leave the red lamp aimed at the surface. It stays where you release it. Take the green one and move its pool across the red. Separate them, then let their edges meet. Try the blue. The white lamp begins aimed aside; bring it into the comparison when you want to see what another contribution does. If the middle grows too pale to distinguish, separate the pools again. Their edges give you somewhere to begin.

In the previous room, colour was assigned to forms and positions. Here you can move one of the conditions of its appearance with your hand. What, exactly, have you changed?

The receiving surface keeps the same material throughout. Its stored base colour, its *albedo*, is a near-white value. Each lamp carries a `SpotLight3D`: a light with a position, a direction and a cone. Turning the handle turns the cone. The surface receives a different contribution because you have changed where that cone falls.

Inside each lamp, `flashlight_color.gd` finds the light and gives it its colour:

```gdscript
var spot = _find_spot_light(target_root)
if spot:
    spot.light_color = light_color
```

Four copies of the same scene receive four values. The red instance is given `Color(1, 0, 0, 1)`; the green instance `Color(0, 1, 0, 1)`. The first three numbers address red, green and blue channels. The last is alpha. The assignment happens when the scene starts. Your hand supplies the subsequent movement; the lamp does not need to change its colour value to make the surface look different.

Aim a beam off the board and onto the floor or the cube standing to its side. The cone can cross the boundary of its intended exhibit. Does the colour still read the same way? Follow a shadow or an edge before giving the result a name. The lamp carries a value, but it cannot carry a complete account of what you will see wherever you point it.

There is a useful limit here. These lamps offer RGB values to a renderer. They do not calculate a spectrum of wavelengths. The room also has other illumination: turning the lamps away does not promise darkness. Even the pale surface we have kept fixed is a chosen condition of this experiment. We have made a comparison manageable by leaving much of the world in place.

Perhaps the surprising body here is the patch of colour. You cannot pick it up separately from the meeting that produces it. Move one participant and its boundary moves; withdraw another and it changes again. The code gives us a way to repeat that meeting. There is still more to ask of it.

<!-- @ -->

Carry the distinction with you: changing the light that reaches a surface and changing the surface's own material can both change its appearance. In the next room, the receiving surface begins to resemble part of the body you act through. What happens when the colour is something you choose to wear?



## Color_Nails

Source: commons/maps/Color_Nails/final.md

SHA256: 214546e32247a68a09e1c3530e493e7fe9d1513ff163ca5a9899b225f4b36f64

What changes when a colour becomes part of the body you act through?

The lamps changed what reached a surface. Here a hand has outgrown the furniture. A small manicure table stands before it, complete with bottles, stools and another hand small enough to rest between the tools. Which of these bodies are you about to dress?

<!-- @nail_color_controller -->

Find the movable point in the RGB box on its own plinth beside the manicure table. The space above and in front of the plinth is open for your hand. Take hold of the point and move mainly along one axis. Watch the preview swatch before moving along another. Predict which part of the colour will change on the next movement, then test that prediction with a short return journey.

Look up at the giant nails, then down at the petite hand on the table. Both answer the same choice. A movement small enough for your hand to make crosses two very different scales. Does the colour feel equally delicate on both? Return to a colour you have already tried and compare again.

The point's three coordinates are constrained to the box and converted into red, green and blue channel values. Moving along one axis changes one channel. Moving diagonally can change several at once. The box turns a colour choice into a position that your hand can revisit.

This is a three-channel description of colour. It does not divide every difference you can perceive into three equally noticeable kinds. Equal distances in the box need not feel like equal changes in the preview.

When tracked hands are available and connected, compare the nail surface with the swatch. The nail material adds its own response to light. A colour selected in the box can look different on a small glossy surface from the way it appears on the flat preview.

<!-- @hand_color_controller -->

Repeat the comparison at the controller for the hand surface. Keep the coordinate gesture simple enough to recognise. Which difference seems to belong to your chosen channels, and which to the surface receiving them?

The two stations use the same position-to-colour mechanism but target different surfaces. The salon hands are two copies of the same source mesh. Their nail materials receive the nail-colour signal; their skin materials receive the hand-colour signal. Each receiving material is assigned the selected value:

```gdscript
material.albedo_color = colour
```

The scale difference lives in the geometry's transform. It does not require a second colour recipe. A nail can become monumental while its material still receives the same three channels as the small one on the cushion.

These two display hands remain available without tracked hands. They let you see a material change beyond the swatch; they do not establish that the player's own hand has been connected. Compare the surfaces that are actually present in your encounter.

<!-- @ -->

Choose a colour because you want it, without requiring a naturalistic match. Try a nail or hand that interrupts the palette you expected from this body. What does that choice make possible for your sense of the figure you act through?

The editable channels are a material choice, not a complete description of identity. A system can make a surface adjustable while leaving many other bodily possibilities fixed. Name one choice the box gives you and another it does not.

Carry one of those chosen colours toward the rainbow. Where would you put it among the bands? The next room gives colour a familiar order; look for the decisions that hold that order in place.



## Color_Rainbow

Source: commons/maps/Color_Rainbow/final.md

SHA256: 89624ea7e30ebd62d994ffe573fc1440a1bf7110b75449a5c0e6069facbe1646

# More colour, another rainbow

<!-- @rainbow -->

The mushrooms are dressed for it. Pearl collars beneath candy-coloured caps; stars beyond the arch; a small staircase that seems to have wandered in from a platform game. There is also a level path. You can join the celebration without taking the steps.

Enter along the coloured centre path. Confetti opens above it. You have not solved a puzzle yet. Stay a moment with the possibility that the room is pleased you arrived.

Find a boundary between two colours in the rainbow. Follow it far enough to see its curve. At the control plinth, press RE-DIVIDE. Find that boundary again. Has it moved, disappeared, acquired a neighbour? Has the opening beneath the arch become any smaller?

Try the button again before deciding what kind of rainbow this is. The steps keep their height. The path remains where it was. Yet the colours have another arrangement, and the familiar outline is being asked to hold it. CELEBRATE gives you another burst whenever you want one. There is no correct partition to earn first.

In the salon, one selected colour reached the same hand at two scales. Here a list of colours reaches a series of curved strips. Each strip is made from vertices: points placed along an inner and an outer half-circle, joined into triangles. Its position in the list gives it a colour.

The button moves through four authored choices: six bands, seven, forty-eight, then two. The generator keeps their combined width fixed:

```gdscript
return (RAINBOW_THICKNESS * 7.0) / float(maxi(1, rainbow_colors.size()))
```

The old width was seven strips of thickness `0.8`. That width remains the budget. More strips each receive less of it; fewer strips receive more. The familiar arch can survive a change in how we divide its colour.

The option called `continuous` still makes forty-eight strips. For each one, the code computes a hue:

```gdscript
var t: float = float(i) / float(count - 1)
out.append(Color.from_hsv(t * 0.78, 1.0, 1.0, 1.0))
```

Look for its seams. A name can promise continuity while an implementation offers enough small divisions for some seams to become difficult to see. These are HSV values converted into RGB colours on a mesh. No droplets, sunlight or wavelength calculation produce this particular rainbow. Even its opaque appearance does not make the bands a climbing surface. The low steps have collision; the arch is a display.

Look away from it, toward the striped banners and the mushrooms. There are pinks, pale blues, whites and dark colours that this sweep through saturated hues does not offer. They are already welcome in the room. What would you have to change in the list, or in the rule that builds it, to give another colour a place in the arch?

The answer is not that every difference is already included. This control gives four choices, made in advance. It lets you discover that the arrangement can be otherwise, and also where its available otherwise stops. You might want a fifth choice. You might want a colour to take more space, or a border to refuse its neat curve.

Before leaving, choose the version you want to stand beneath. Let the confetti return. The same programmed event can be a reward for obedience or an invitation that asks nothing of you; here you can repeat it without passing a test.

<!-- @ -->

Carry the distinction between a colour rule and the places where it is sampled. In the next room, pillars stand at particular addresses in a colour field. What is between them, where the field has a value but no pillar has been given a body?



## Color_Pillar

Source: commons/maps/Color_Pillar/final.md

SHA256: 51cf3d6bea1a33c12f3b7c156a928db69606dd8ff39e8b674263b41e2cc06180

# The colour between the pillars

<!-- @pillarcolorcollection -->

Stand where the colours are pale. Follow one line of pillars farther into the field. The hue stays recognisable while its saturation increases. Now walk across that line. The hue changes too. Two directions, two different ways to change a colour.

There are thirty-five pillars, but the floor does not stop at thirty-five colours. Look between the columns. The smooth field continues where no pillar stands. Each pillar is a sample of that field at a particular position.

```gdscript
var u := clampf(p.x / 12.8, 0.0, 1.0)
var v := clampf(p.z / 19.2, 0.0, 1.0)
return Color.from_hsv(u * 0.85, lerpf(0.25,1.0,v),0.95)
```

The address is doing work. One coordinate chooses a place along the hue range; another chooses saturation. Value stays at 0.95. The gaps between columns contain possibilities that the collection has not put into a body.

The field is larger than its former arrangement: five columns by seven rows, with 3.2 metres between samples. Each pillar rises 4.6 metres. Walk close enough to read a sample's address and colour code, then step back until several pillars overlap. The computed values remain fixed. What their company makes visible keeps changing.

<!-- @color_sets_overview -->

Beyond the field, twelve collections hang on a framed wall. Their colours have names, and their groups have names too. These sets were assembled. The field was evaluated. Both are ways of deciding which colours belong together.

Take a swatch if you want to carry that decision into another view. Its label makes it identifiable. It cannot carry every relationship the colour will enter. Compare it with a pillar, with another swatch, with the space around your hand.

The wall does not finish the gradient. It gives you another method of collecting it, with another set of omissions.

<!-- @ -->

On the next floor, follow what happens when a rule assigns colours to grid cells. Keep the spaces between these samples in mind.



## Color_Grid_Pallet

Source: commons/maps/Color_Grid_Pallet/final.md

SHA256: 8ba544dda4c4625245ad7661d98f5ee83a31885e54b750984138b6e0e1c3070d

# Find the colour again

<!-- @gridcolorizer -->

Choose a square before you choose a colour. The white outline marks one piece of the floor. On the console, two numbers give its address. Press X +. The outline moves across. Press Z +. It moves along the other direction. The floor stays where it was.

At the pillars, a position supplied a sample. Here you can write something back.

Press COLOUR. One cell receives pink. Press again and it receives another of the four available inks. Find a colour you want to leave there. Move the outline away. Keep going until the address returns: each direction cycles through five positions. The colour is still waiting at the address you left.

The white outline has travelled. Your exception has not followed it.

```gdscript
colorizer.multimesh.set_instance_color(cells[selected], INKS[ink_index])
```

One line writes to one instance. `selected` holds the two coordinates you chose; `cells` connects that address to a cube in the room's drawing buffer. Moving the selection changes what the console reads. It does not carry the stored colour from cube to cube.

Look from the small swatch beside the controls to the floor. Both receive the stored value. Their size, angle, light and neighbours differ. A matching number does not settle how the colour will meet you. The room where colour needed company has followed us here.

Now press RULE.

Your exception gives way to the floor's repeating assignment. The address remains. Walk toward the place you changed: the cube still supports your body. There has been no new geometry, no hole, no repair of the route. What changed was which colour that position received.

```gdscript
var colour_index: int = (address.x + address.y) % palette.size()
colorizer.multimesh.set_instance_color(cells[address], palette[colour_index])
```

In this two-coordinate address, `address.y` names the room's z direction. Add the coordinates. `%` keeps the remainder after division by the number of colours in the palette. Another cell can have the same remainder and receive the same colour. The diagonal relationships were already inside that addition.

Try PALETTE. The collection changes; the assignment keeps its form. The floor finds another appearance without learning another way to stand.

We could mistake this regularity for a requirement of the grid. Yet you have just made an exception. The cube held it perfectly well. The rule did not return because the exception was impossible. It returned because you pressed a button that wrote across the floor again.

The apparatus has its own narrow permissions. Five positions in each direction can be selected here. Four inks can be assigned. The rule reaches farther, across the interior floor. Why should its reach exceed yours? These limits are choices in this lesson's code; the experiment makes them available to question. A later version could let an exception travel, protect it from a rewrite, or change the rule itself. None of those possibilities happens merely because we can name it.

There is no history stack behind this console. An edit remains while you look elsewhere, but RULE replaces it and reloading the room starts again. To remember more would require another place to keep what has been overwritten.

<!-- @ -->

Ahead, a coloured ball is already moving across a canvas. We leave the address with its current value and approach a surface on which marks accumulate. What will that surface keep of a movement after the body has passed?



## Color_Paint

Source: commons/maps/Color_Paint/final.md

SHA256: a941b43cad8ee1ef202142d4e4c9ab79104e5883dcd1013b4f10e0f77241cf3e

# Before the hand

<!-- @ball_painting_demo -->

A coloured ball is already moving across the canvas. Wait before taking anything. The line changes direction, and the pigment changes colour as it travels. A painting is underway without your hand.

At the grid, a colour waited at an address until another write replaced it. Here, look back at a place the ball has left. Something of its passage remains. Something is already changing.

Thirty pigment balls wait on the low tray. Pick one up and aim it at the canvas. Move across the automatic line. Your gesture reaches a surface that has other business; it does not wait for you to finish. Release the ball. It returns to its place, and your marks stop arriving. The other painter continues.

Which part of the image can you still call yours?

```gdscript
var uv := Vector2(0.5+0.43*sin(elapsed*0.71),0.5+0.4*sin(elapsed*1.13+0.6))
```

Two oscillations give the automatic brush its position. Their rates differ. Follow one turn of the line and then another: neither coordinate alone describes the gesture you see. Its hue changes with elapsed time too. The moving ball is the visible companion of this calculation; no collision is needed for its paint to arrive.

Your ball takes another route. A ray finds the canvas you are aiming at. The hit becomes a position on that surface, then a pair of coordinates between zero and one. The canvas is four metres wide and two and a half high. Those proportions matter: assuming a square would quietly move your mark away from where you aimed.

Both routes reach the same drawing operation.

```gdscript
surface.draw_line(previous,uv,color,12,256)
```

That is the automatic caller: brush radius twelve pixels, positions snapped to 256 divisions along each axis. The manual balls carry their own brush sizes and snap resolutions. Try another ball. Colour changes, but it is not the only difference in your hand. As in Trace, the apparently continuous movement passes through a finite choice of positions.

The wet canvas keeps working between these calls. Its shader samples the preceding image and neighbouring pixels, shifts the sampling position, and fades the result toward white. The surface remembers by becoming another image. It does not preserve a list of gestures that can be retrieved intact.

```glsl
vec4 color = mix(vec4(1.0), prev_color, dissipation);
```

White enters the work again. It is the direction of forgetting in this particular simulation. We could ask for another ground, another rate of fading, another way for two colours to meet. None is the natural behaviour of code. Here we can point to the line that makes the decision.

The automatic brush advances by elapsed time. The wet surface updates with rendered frames. Even their clocks differ. A slower rendering pace can change how much the image has faded during the same time on your watch. The computer's ability to keep up participates in what the painting becomes.

<!-- @albers_wall_gallery -->

Turn from that accumulating surface to the Albers studies. Let one coloured area hold your attention, then include its surround. At the painting, a neighbour may arrive while you look. Here an arrangement holds the comparison available for longer.

Return to the canvas. Some of what happened while you looked away is still visible. Some has flowed into something else. The shared surface has made room for two ways of moving without keeping them separate for you.

<!-- @ -->

Ahead, colour becomes a partition you can walk beside and look through. What happens to this question of neighbours when the coloured surface helps organise the room itself?



## Color_Walls

Source: commons/maps/Color_Walls/final.md

SHA256: 148ef449203e399e03dd705ebd67082c862b5d3ad6178d3383716a2e049d54c2

# The view has partitions

<!-- @color_constellation_office -->

Someone has prepared a place for you. A desk, a monitor, a chair. Seven more places repeat along the aisle. The glass has colour; the office has an order.

Choose a cubicle. Before entering, look toward its desk through a pane. There is almost nothing between you and the chair. Almost. Walk toward the opening instead. Your view took a route your body could not.

At the entrance console, press **GLASS / OPAQUE**. Return to the same cubicle. The chair has disappeared behind a coloured wall. Find the opening again. Has the route become longer, or has finding it become a different task?

Press once more. The furniture returns to view. No doorway has opened.

The switch changes two material properties on each of forty panes:

```gdscript
mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if glass_visible else BaseMaterial3D.TRANSPARENCY_DISABLED
mat.albedo_color.a = 0.26 if glass_visible else 1.0
```

The collision bodies remain where they were. Each cubicle still has its 1.2-metre entrance; the walls still meet at right angles. A change to visibility can alter how you approach a place without changing the geometry that admits you.

In Paint, two gestures entered one image. Here the image and the body encounter different accounts of the same wall. Let that disagreement stay visible. An invitation to look is not yet an invitation to enter. Perhaps the useful discovery is the doorway; perhaps it is the distinction that lets you ask for another kind of doorway.

Move until several panes overlap. Their colours enter the renderer's transparency calculation. This glass does not calculate the wavelengths a real pane would absorb. Its clearness is a setting. Even the apparently empty space between you and the desk has been made by a procedure.

<!-- @color_space_navigator -->

Leave the cubicle through its opening. At the smaller models, look for red, first in the cube and then in the cylinder. Where could you go from it?

You have been walking through an arrangement of coloured space. These models arrange colour values in space. In the cube, increasing the red channel moves a sample along one axis. Green and blue have their own directions. A colour has become an address again, but the address now comes from the colour itself.

The RGB model assigns a sample's position and colour together. In this shortened version of the construction:

```gdscript
position = (Vector3(r, g, b) - Vector3.ONE * 0.5) * cube_size
colour = Color(r, g, b)
```

Look across to the HSV cylinder. Hue turns around its axis, saturation moves outward, and value changes height. Going around has replaced one of the cube's straight directions. The two models offer different ways to organise colour values.

Neither contains every colour as a visible point: each holds five hundred samples. The gaps belong to the display we have built. Even the black corner has been brightened slightly so that you can find it. To show a value, the exhibit has already made an accommodation. What would disappear if it refused?

<!-- @gradient_interpolator -->

The next bench starts with red at one end and blue at the other. Sixteen small cubes hold the intervening values. Follow them with your eyes, then press **RGB / HSV**. Leave the endpoints alone.

The middle changes. The agreement about where to begin and end did not decide how to travel.

In RGB mode, the calculation is:

```gdscript
col = ca.lerp(cb, t)
```

Here `t` runs from zero to one across the sixteen samples. Red decreases as blue increases. In HSV mode, the program instead chooses the shorter arc around hue, while interpolating saturation and value. For these endpoints that keeps a bright passage through magenta, where the RGB passage was darker. Try **COLOUR A** and **COLOUR B** to choose another pair from eight presets. Does the distinction remain as conspicuous?

The path was chosen in code. The number of places along it was chosen too. Sixteen cubes let us inspect a transition without pretending we have occupied every value between its ends.

<!-- @ -->

A view through glass, a position in a colour model, a calculated passage: similar appearances can conceal different operations. Carry that habit of asking how into the chamber ahead. When colour and shape both change, which operation did your gesture actually set in motion?



## Chamber_Color

Source: commons/maps/Chamber_Color/final.md

SHA256: dc574466fbd2f09d8a192e3f0260c6571a63b84926a256675dbc306f5f2c8948

# The colour lands

<!-- @becoming_catalyst -->

A small instrument faces a crate in a frame. The aim is already chosen. What remains for you to choose is when.

Press **FIRE COLOUR** once. Follow the bright sphere, then look at the crate. Stay with the place where it landed a little longer. Has only the crate changed?

Around its feet, some grid cubes have taken colour too. Their edges no longer quite agree with the grid. Small cubes spring away and disappear. Wait until the flash has passed before deciding what the shot left behind.

The instrument uses the catalyst's chromatic mode. Each launch chooses a hue:

```gdscript
var hue := randf()
proj.color_primary = Color.from_hsv(hue, 0.85, 1.0)
```

You did not select a pigment from the tray this time. The machine chose from an interval. During flight, its glow cycles through further hues, while the stored colour travels unchanged. The appearance that caught your eye on the way need not be the value delivered at the end.

The target receives that stored value and uses it to tint its materials. Nearby grid cubes receive another calculation. Their distance from the impact shifts the hue:

```gdscript
var hue_shift := dist * 0.15
var paint_color := Color.from_hsv(
    fmod(color_primary.h + hue_shift, 1.0), 0.8, 0.95
)
mm.set_instance_color(i, paint_color)
```

Only cube centres within 1.5 metres participate. This is a neighbourhood chosen by a distance test, not wet paint spreading over a surface. A cube just outside the radius stays as it was. Look for that boundary. The splash can look generous while its admission rule is exact.

Press again. The chosen hue changes; the aim stays fixed. The code also shrinks, turns and slightly displaces the affected grid visuals. Colour did not cause those changes by itself. The programmer put several operations behind one contact. We can separate them in the source even when the eye receives them together.

Approach the changed floor. Those smaller, tilted cubes still have their original collision bodies. The visual gaps have not all become gaps your feet can enter. Walls let a view pass through a body-blocking pane. Here the disagreement has moved underfoot: the image changes shape, while another account of the floor continues to hold you.

This is a remainder we can work with. We might choose to rebuild the collision and discover a new walk. We might preserve the disagreement and ask how you learn to trust a floor. The present implementation has made the second condition available; it has not completed the first.

On the third hit, the crate disappears. The frame stays. Wait. After four seconds the target begins to return, and you can start another three-hit cycle. Its counter starts again; the nearby grid has not been restored with it. A return can reset one part of an encounter while leaving another part altered.

The bench gives the visitor a mounted operation. It does not put a bracelet on your wrist or promise that these edits will survive reloading the hall. That larger question of what can travel with a body remains open.

<!-- @ -->

Across Colour, a value has needed a lamp, a nail, a neighbour, an address, a surface, a view. Now it arrives as a message, and the receiver decides what to do with it. What bodies are possible depends on those receiving rules as much as on the value we send.

Carry the coloured cube forward in thought. The next hall returns to the disco floor we met before Colour. Its old arrangements now receive a palette you can change independently. Does the same pattern still invite the same movement? After that return, the pattern machines will let a small source decision reach the walls and floor around you.



# tiling

Declared order: Pattern_Disco → Pattern_Foundry → Tutorial_Pattern → Array_Patterns → Symmetry_Seventeen → Ribbon_Patterns_01 → Ribbon_Patterns_02 → Ribbon_Patterns_03


## Pattern_Disco

Source: commons/maps/Pattern_Disco/final.md

SHA256: 508d7cbc06927da571a4e6a679baf03726f5c347df4955b351397b011bf14b83

Do you recognise the floor in its new colours?

The layout is familiar: the same twelve-by-twelve floor, the same console near the entrance, the same sequencer beside it. Before Colour, black and white made a checker, a travelling row, diagonal bands and a snaking passage through the cells. Those rules have returned. Their values can now wear another palette.

<!-- @disco_controls -->

Hold the floor and stop the sequencer. Choose a pattern, then press COLOUR without changing anything else. Follow one tile through the palette choices. Does it still seem to belong to the same band? The binary value at its address is unchanged, but its relation to its neighbours may feel different.

The separation is small enough to find in the code:

```gdscript
PALETTES[palette][value_at(x,z,floor_node.grid_width,floor_node.grid_depth)]
```

The pattern function returns zero or one. The selected palette supplies the colour at that index. This floor offers four pairs, including the old black and white. It is a deliberately limited instrument: two values, four arrangements, four palettes. The choices make a comparison possible before we ask the next machines to author more.

Now leave the palette alone and change PATTERN. Then change SPEED. Changing the palette preserves the current phase. Changing the pattern starts that pattern at phase zero. The controls have different consequences; watch the step number as well as the image.

<!-- @standalone_disco -->

Start the floor and walk towards an approaching band. Let it pass underneath you. Its passage does not push your body. The tiles receive changing colours while the supporting surface remains in place. Can an invitation to move be felt without a force being applied?

Return to black and white while it runs. You have taken away a palette, not undone the rules you learned in Colour. Brightness, contrast, neighbourhood and attention are still at work.

<!-- @step_sequencer -->

Bring in one repeating note, then another. The sequencer owns its musical clock and briefly brightens floor columns when events arrive. It does not read your footsteps. The visual pattern has its own tempo; matching the two tempos is not a guarantee that their phases coincide. Listen while watching one chosen column, then look away and keep moving.

Holding the floor leaves the musical events active. Stop both instruments if you want a motionless comparison. Otherwise let them disagree. Is the disagreement distracting, useful, pleasurable? A regular score can support a movement that does not repeat it.

<!-- @ -->

The return has given us a way to distinguish an arrangement from its colours and from the time taken to read it. None of those choices has rebuilt the floor. In the Foundry ahead, we will make a source pattern ourselves and let the surrounding architecture receive it. The field will no longer end at our feet.



## Pattern_Foundry

Source: commons/maps/Pattern_Foundry/final.md

SHA256: 415c1b854c1129b217c7a55a1b164b0c67a24e700e5cd2cf37c7326981d83f4a

How many places can one small decision change?

The returning disco let us separate a pattern, its palette and its clock. Here a small arrangement supplies a much larger field. Make one decision where you can see exactly where it began, then let it reach the architecture around you.

<!-- @pattern_architecture -->

At DRESS THE ARCHITECTURE, choose a SOURCE. The loom, kaleidoscope, stamp press and pattern mill can each supply their actual output to the hall. Walk away from the controller and look for the repeated image along the walls and underfoot. Then return and choose another machine. One room has acquired another account of itself.

TARGET selects ROOM, WALLS or FLOOR. REPEAT SIZE changes how much surface one complete output image occupies: two, four or eight metres. TINT multiplies the colours of that output by a pale colour or white. It does not rewrite the machine's own palette. To change the source design, use that machine's controls, then look back at the architectural surfaces receiving it.

The loom's carpet includes a short history of bands. When that carpet becomes the source, its history is what repeats across the room. The source named on the controller matters: a live connection can carry the current state of a record as well as a single current motif.

Press LIVE / HOLD. Both architectural receivers keep an independent image of what they were carrying. The machines continue their work. RESET reconnects the whole room to the loom, with white tint and a four-metre repeat. The smaller specimen controls beside the machines remain available for more precise comparisons; this console addresses the architectural skin.

These images add no collision. A patterned wall stays solid, and a dark floor tile stays supported. Before calling a visual difference a new passage, try to account for what your body can actually do there. Then go to the small tile where a source decision can be made one cell at a time.

<!-- @pattern_tile_4x4 -->

Take a coloured cube from the palette and release it over an off-centre cell in the small tile. Watch the repeated preview. Find several places where your mark appears, then locate the one source cell you changed.

Add a second mark beside the first. Predict the repeated pair before looking across the whole field. The size of the result can make the action seem more complicated than it was. Many visible changes have followed one local edit.

The tile stores a finite array of colour choices. To draw the larger field, the repetition rule maps each preview position back to a position in that array. Copies share a source. They do not each contain a separately authored decision.

<!-- @pattern_tile_mirror -->

Make a recognisably asymmetric mark at the mirror station. A mark away from the centre, with a differently coloured neighbour on one side, makes reversal easier to notice than a centred dot would. Follow the pair through the preview and compare the directions in which it faces.

The simple repetition keeps the tile's orientation. The mirror rule reverses selected copies along its directions. The source motif and the transformation applied to its copies do different work: changing either can change the field.

Now try to make the mark appear only once while the rest of the field stays unchanged. Editing the shared source makes it recur. The difficulty is evidence about the way this instrument stores authorship, rather than a failure to choose the right colour.

<!-- @pattern_machine_a -->

At the loom, two upright samples wait beside the carpet. One is flat. The other bends towards you. Press MARK on their console, then look for the changed cell on both surfaces. Walk a little to one side. The mark narrows around the curve; has the machine given it less room?

The samples have the same surface height and width: 1.2 metres high, 1.2 metres across the sheet. Across the curved one means following its arc. Its width seen head-on is smaller. Both receive the same colour image, with the same addresses in the same order. Bending the sheet changes where those addresses meet your view.

The loom begins here with translation: a five-by-five card repeated four times in each direction on each sample. MARK changes one card cell. Touching the loom's pegs lets you choose other cells; its GROUP control changes the repetition rule. Try a mark away from the centre before changing that rule. A centred mark can hide what the operation has done.

The current specimen is assembled one pixel at a time. This is the address at which the repetition rule enters:

```gdscript
var index:int=WallpaperGroups.get_symmetric_color(source_x,source_y,n,live.card,group_id)
var c:Array=live.palette[index]
img.set_pixel(x,y,Color(c[0],c[1],c[2],c[3]))
```

The rule returns a colour index. The palette supplies its colour. The receiving sheet supplies its shape. They meet in the visible pattern, but you can change them separately.

With CURVE selected on the display, press LINK / HOLD. Now press MARK again. The flat sample follows; the curve keeps what it had. There is a difference between them, and the loom has continued running. Holding this sample means declining the next image. It does not stop time or let you edit just one of its repeated marks.

Link them again. Press SAVE, change a peg or the group, then RESTORE. The saved card and palette return, along with the carpet's short history of bands and its saved animation phase. The carpet moves on from there. The two upright samples show only the current rule; the carpet carries earlier decisions as well. Saving the source does not save the curve's temporary held image.

Turn towards the low wall behind you. The pattern has arrived there too. Follow a pair of marks along it: the wall has more repetitions, rather than a larger version of the image. Under the starting translation rule, one card occupies thirty centimetres on every surface. The wall remains solid. Its new appearance has supplied no new passage.

Press TARGET until the display names WALL. Its mounted label picks up the selection. Hold it, then change the source again. The two samples move on; this piece of the room keeps what it had. It was easy to treat the wall as background while looking at the machine. Now the background participates in the same decision.

Keep the wall held and press REPEAT SIZE. The source advances from thirty to sixty centimetres. Look for the same pair of marks on a sample: each now occupies more room, and fewer copies fit. The wall keeps its earlier spacing. Both labels say what each surface is carrying.

Press again for fifteen centimetres, then once more to return to thirty. Nothing has been added to the card. The sheet has not grown. The address calculation now reaches the next source cell sooner or later as it moves across the same physical surface. In the starting translation rule, the 1.2 metre sheet holds eight, four or two card periods. Its edge may cut through a repeat; the surface does not stretch to finish the motif.

SAVE remembers the source spacing too. Set the source to sixty centimetres and save it. Change spacing, then restore while the wall is held at thirty: the linked samples recover the saved scale, and the wall continues to keep its difference. The carpet remains a separate view of the loom's band history at its original spacing.

Link the wall again, then press UNDO LINK. Its earlier held image returns. The carpet and the other machines continue their own work. Selecting a receiver changes who can follow; MARK, SAVE and RESTORE still act on the shared source.

Leave one surface held. With the repeat size at thirty centimetres and the offset at U00, press OFFSET +5CM. Follow a pair of marks on a live sample. They have changed position without growing. The image on the held surface stays where it was.

The offset advances the address sampled at each point on the sheet. U names that sheet's horizontal texture coordinate; it is not a shared compass direction through the museum. The curve carries the displacement around its bend. Neither surface moves, and the motif still has the same cells.

Press five more times to reach U30. Under the starting translation rule, the image returns to its U00 appearance. The stored offset differs by one full repeat. Returning to an appearance need not undo the process that brought you there. One more press returns the control to zero. SAVE and RESTORE remember the source offset; a held surface keeps its own accepted offset until you link it again.

Walk towards the wall beyond the loom, then around the grid block to its shorter east face. NORTH and EAST have received the pattern too. Their widths differ, but a card occupies the same number of centimetres. At sixty centimetres, the height of these low faces ends halfway through a repeat. The rule has continued further than the surface can show.

Select ARCHITECTURE. This names three wall faces, leaving the two specimens outside the selection. If their states are mixed, press LINK / HOLD to bring the walls live; press again to hold them together. Change the repeat size. The samples change while their surroundings keep an earlier scale. Try the reverse: hold a specimen and let the walls follow.

EAST can also be selected alone. Hold it, then return to ARCHITECTURE: the display now reports MIXED. One part of the background has separated from the others. ALL FIVE includes the three wall faces and both specimens. Neither name includes the whole museum. These names describe memberships we have made, and can revise.


Take the passage into the runway annex, then follow its side aisle into the curved room. The studio stands inside it. A small source has become something you can stand within. On its smaller surface console, choose WALL and press APPLY LIVE. Edit a cell in the studio. The wall follows it now; the loom's other surfaces continue their own account. Nothing in the wall's geometry had to move for this allegiance to change.

Press HOLD, then edit again. The wall keeps its image. UNDO LINK restores the preceding connection, including whose pattern it followed. LOOM explicitly returns the selected surface to the loom. A surface can share a source, keep a memory of it, or begin following another one. Watch the owner named on the display: the same instruction to change a cell now has different consequences depending on who is listening.

Choose ROOM and press APPLY LIVE. The same decision reaches the curved wall and the floor beneath you. Turn your head, walk towards a mark, then step back. The pattern changes its appearance across your view while the stored cells stay put.

Choose ROOM FLOOR and press HOLD. Change a source cell. The wall follows; the ground keeps its earlier image. The room has separated into two different moments. Its curvature has not changed, and the opening still admits your body. What changed in your sense of the space, even though its supports stayed where they were?

<!-- @ -->

A repeated field can be economical, recognisable and pleasurable. It can also make a wanted exception difficult to express. Choose a reason for keeping one copy different: a direction marker, a mistake you want to retain, or a place that should resist the general pattern.

The held curve has made one kind of separation possible: a whole surface keeps an earlier image. Keeping just one mark different would require a finer distinction, an exception within the repeat. Name what should stay shared and what you would let separate. The instrument's smallest editable unit decides how precisely you can answer.

The next station keeps the motif while changing the larger symmetry rule. Carry an asymmetric mark with you in memory; it will help you see which operation has been applied.



## Tutorial_Pattern

Source: commons/maps/Tutorial_Pattern/final.md

SHA256: 897d88c50dff322e9a9d6dedf0a88e65985c8bfef7b196119a42917cbc5a2373

What can change when you keep the painted cells exactly as they are?

In the foundry, a small source reached the walls around you. Here, take the opening into the side bay. Two framed fields flank an editor. Both contain the same red bend, the blue corner and the small ochre interruption. Follow the red bend across each field. Does it always face the same way?

<!-- @pattern_maker_station -->

The sixteen buttons on the console show the source. Read them from the top row down. Find the red bend there, then find it again on the left panel. Move one tile to the right. Something has travelled without turning.

On the other panel, the next bend faces back. The painted source still has only sixteen cells. Nothing in that little grid has turned over. Where did the other facing come from?

Press PM. Look at the floor, then back at the source buttons. Press P1 and return. The floor changes its arrangement; the two wall panels keep their respective rules. They let you compare what the floor has just left with what it has become.

The names can wait until you have found the difference. P1 repeats by translation. In this station's PM rule, alternate columns sample the source in reverse across x. The shader begins by separating a position into the tile it belongs to and its position within that tile:

```glsl
vec2 st = uv * tile_scale;
int tile_x = int(floor(st.x));
vec2 local = fract(st);
```

The whole part counts tiles. The fractional part returns to a place inside one tile. For translation, that local address is enough. For the reflected field, one additional condition changes where the lookup goes:

```glsl
if (imod(tile_x, 2) == 1) {
    local.x = 1.0 - local.x;
}
```

These lines run in the wallpaper shader used by the station. They change an address before it reads the source texture. They do not repaint the stored cells. The alternating facing belongs to the relation between copies.

Now press FLIP X. Watch the source this time. Its blue corner crosses to the other side. Both wall fields respond, although their rules remain P1 and PM. Here the operation really does rewrite the array:

```gdscript
row.append(_grid_data[y][tile_size - 1 - x])
```

The line takes a cell from the opposite end of its row. Press FLIP X again. The second reversal brings every cell back. Try ROTATE, then follow the corner through four presses. UNDO takes you back one editing operation; RESET restores the starting mark and the translating floor. Reset can itself be undone.

Choose a paint colour and press a source cell. Put a solitary mark where the motif was quiet. Both fields receive it. Step back. Your interruption has become regular too.

A repeating system can make room for an unexpected mark while giving that mark a schedule. What would it take to let one copy depart without sending the departure everywhere? In the foundry you could hold a receiving surface apart from its source. Here the source is shared deliberately, so an edit travels through every copy. Neither arrangement answers every desire.

The panels and floor give each tile forty centimetres. The floor has more copies because it extends further. On the reflected panel, facing alternates across tile columns: the two-column cycle is wider than the individual tile. A boundary around one copy does not necessarily enclose the whole repeating relation.

<!-- @ -->

The mark is made of cells, but the apparent continuity between copies is another decision. This lesson uses nearest-cell sampling, so a colour holds its square until another cell begins. A softer-looking edge would need a different account of how those stored values become visible. Sixteen cells have never been the whole surface, however completely they seem to occupy it.

For a moment, a field may look unchanged even after an operation. A very symmetrical source can conceal a reversal. Add a difference and try again. The useful mark may be the one that refuses to look the same from every direction.

In Array_Patterns, the repeated field extends along an environment. Keep these two questions available as you enter: what rule relates the copies, and what surface gives those relations a place to appear?



## Array_Patterns

Source: commons/maps/Array_Patterns/final.md

SHA256: 67cfa28ed8b81221a14c2ce061ace7930b806d57eef920a076f70e818ec2f032

When does repetition become an environment rather than a picture?

The red bend returns, with its blue corner and ochre interruption. It is the same starting arrangement you met in Tutorial_Pattern, entered here as a fixed source. Your edits from the previous room have not secretly travelled with you. This time the question is what gives the mark a place to appear.

<!-- @pattern_tunnel_machine -->

Take the opening into the side bay. A six-metre passage stands on a raised platform; its console is beside the ramp on the lower floor. Three wedges make a broad ascent. Side walls close the routes around the tunnel, so crossing this bay takes you through it and down the ramp at the far end. The source has sixteen cells. There are considerably more squares inside the tunnel. Find the pale yellow indicator on the floor and compare its position with the console's two addresses.

Press COL +. The surface address advances. Press it again, watching the smaller source address. After four steps, one number has returned while the other has moved on.

```gdscript
column % 4
row % 4
```

These are the wrapping expressions used by the inspector. It displays addresses as `[row, column]`, then the palette index stored there. Surface `[10,1]` returns to source `[2,1]`. Another place can consult the same memory.

The tunnel's renderer first computes a small swatch from the source and its translation rule. The shader samples that swatch across each face. The inspector follows the same cell coordinates back to the four-by-four source. You can move the indicator without changing a single stored colour.

Now press FACE. The indicator moves to the right wall. The panel still speaks in rows and columns, but those directions occupy another plane. On the floor, one direction runs across the passage and the other along it. On the right wall, columns run along the passage and rows descend from the ceiling. The address needs a surface to acquire a direction in the room.

Walk inside. Follow a line to the corner between floor and wall. Each face begins its own grid. A shared motif does not promise that its edges will join there. The corner exposes a decision that was harder to notice on a single flat panel: where should counting begin, and which way should it proceed?

Return to CELL SIZE. A cell now occupies sixty centimetres instead of forty. The source still has four cells across. Its whole motif therefore spans 2.4 metres instead of 1.6. In the previous room, forty centimetres described an entire motif; here the mark has been enlarged so you can inspect its individual addresses. The same number needs its unit and its referent.

The passage has not grown. Its width remains 3.6 metres and its height 3.2. Some divisions fit exactly; others leave a cut cell at an edge. A room does not owe the pattern an integer number of repeats. The inspector selects complete cells; the remaining strip is still there to look at.

Press GRID. The dark joints disappear. Keep walking. No wall has opened and no floor tile has fallen away. Those divisions were drawn in a shader on four large surfaces. The supports that stop your body are separate. UNDO restores the last inspector setting, including cell size and grid visibility.

<!-- @pattern_tile_brick -->

Back among the earlier stations, look at the brick preview. Follow a seam through two neighbouring rows. The boundary steps sideways. Compare that stagger with the tunnel's straight cell divisions and the corner where two faces restart their counting.

A stagger changes how rows relate within a field. A corner changes how a field is carried into space. They can resemble one another as disruptions, but they ask for different changes to the implementation. Keep the motif, the lookup and the carrier available as separate things to question.

<!-- @ -->

An orderly image can conceal a complicated support. A conspicuous seam can reveal the rule more clearly than a perfect join. Neither smoothness nor interruption is automatically the more interesting result. What becomes available to a body that can read the difference?

This passage holds its pattern fully visible. The earlier automatic reveal remains another performance to revisit when we study change over time. Here there is time to compare addresses, then move on. Symmetry_Seventeen will ask what can be classified about an ideal repeating field. Bring the finite edge of this room with you.



## Symmetry_Seventeen

Source: commons/maps/Symmetry_Seventeen/final.md

SHA256: ed35f6d3e880e8a5e6af2353cf71860e49e66a7c0a396574800ad25e52d1c798

What would have to stay the same for this to be the same pattern?

You have followed an address around a corridor. The floor and the wall gave it different directions. Here the surface stays flat, and a small mark returns in ways that do not quite agree.

<!-- @vr_tile_editor -->

Begin at the tilted console in the side bay. Its sixteen buttons hold an asymmetric mark: a bent line, a second colour near a corner, a third near the bend. The left panel holds a sample. The right panel and the carpet follow the current source and rule.

Choose **PM**. Keep your eyes on the corner colour. Find it in the next block. Has the mark travelled, or has it also reversed? Compare it with the held **P1** sample. You have changed no source address.

Now choose **PG**. The reversal remains, but the colour no longer arrives opposite its neighbour. Follow it along the other direction. The rule has slipped the reflected copy by half the source height. With four source rows, that is two rows.

Try to describe the difference before pressing **HOLD**. This saves the current image on the left. It gives your next change somewhere to return to.

The three buttons select translation, reflection and glide reflection. In the editor's integer lookup, the last two differ by one line. This is the PG branch of `WallpaperGroups.get_symmetric_color`, with its local source coordinates:

```gdscript
var tile_x = px / tile_size
tx = px % tile_size
ty = py % tile_size
if tile_x % 2 == 1:
    tx = tile_size - 1 - tx
    ty = (ty + tile_size / 2) % tile_size
```

An odd block reverses the source column. Then the row shifts halfway round the source and wraps. The array stays where it was; the lookup changes which of its addresses is read. The panel shows eight source blocks across and eight down. A source block is not necessarily a full translation period: reversal makes you wait for another block before its orientation returns.

Select a colour, then press one of the sixteen source cells. The live panel and floor change together; the held image keeps its pixels. **UNDO** can recover a paint edit, a rule choice or the previous held sample. **RESET** restores the initial mark and P1 while leaving the held comparison available.

Now make the source less distinctive. Remove the corner colour, or make both sides alike. Does the difference between rules remain easy to see? A rule can still execute while your chosen mark conceals what it does. The selected button names a construction; it does not prove that the finished image has exactly that symmetry group. An unusually symmetric source can introduce more symmetry.

<!-- @wallpaper_cage -->

Return to the cage. It marks rotational orders one, two, three, four and six, and crosses five and seven. Its subject is rotation compatible with a periodic planar lattice. It is a diagram of that restriction, not an experiment that tries every arrangement until one fails.

The larger classification concerns ideal patterns repeating in two independent directions on the Euclidean plane. Under those conditions there are seventeen plane-group types; the [IUCr tables](https://it.iucr.org/Ab/) list their operations and generators. The three comparisons at the console are an entrance into that subject, not a demonstration of the completeness of the list.

A fivefold-looking flower can sit inside a repeating cell. That does not give the entire field fivefold rotational symmetry. The flower and the field ask the question at different scales. Look for the boundary of what is being counted.

<!-- @ -->

The catalogue closes under its assumptions. This finite carpet still ends. Its colours have been sampled into pixels, its material meets the light, and your body stands at an angle to it. Those differences have not disappeared because the symmetry has a name.

What could this classification tell you about a garment? What would it leave unasked about its cut, its wearer, or the way a seam interrupts the repeat? Carry the small mark forward. In **Ribbon_Patterns_01**, the next question is what happens when the source gains another index and supplies a volume.



## Ribbon_Patterns_01

Source: commons/maps/Ribbon_Patterns_01/final.md

SHA256: 494882d0579203c1678cbfea061bd57a40cb4b90430061c1cf92dd64640e1cc2

The mark has acquired an inside. Can you find it?

In the previous room, one source could repeat, reverse and slip across a plane. The corridor wrapped a pattern around several faces. Here, look between the faces. There are addresses behind the ones you can see.

<!-- @grid_2d_4x4 -->

Begin with the low array. Sixteen cubes hold the same arrangement of four colours you have met in the pattern lessons. Find the blue corner, then the bend in red. The pale cells belong to the array too. Pale does not mean absent.

These cubes have bodies, but their addresses use only two indices: a row and a column. Giving a cell a visible thickness has not added a third index to its data. The room has made a two-dimensional arrangement out of three-dimensional objects.

At the console, press **X +** and **Z +**. Follow the turquoise frames. One frame selects a cell in the volume. The other shows the source cell from which it takes its colour. The displayed order is `SOURCE [z][x]` and `VOLUME [y][z][x]`; the same coordinates are placed in the room as `Vector3(x, y, z)`. We have to choose an order for storage as well as directions for space.

<!-- @grid_3d_4x4x4 -->

Press **LAYER +**. Keep x and z where they are. The selected address rises, while the source frame remains on the same cell. Do it again. For now, the four layers repeat the same source. Sixteen values have supplied sixty-four positions, but the added room is not yet being used to vary the pattern with height.

Turn on **SLICE** with **SLICE / ALL**. Three layers disappear from view. Read the counter: sixteen visible, sixty-four stored. Press **LAYER +** to inspect another layer. You are choosing what the display reveals, not cutting data out of the array. The hidden cells have not become empty.

Now press **REPEAT / SHIFT**. Stay with the selected volume address and watch the source frame. At layer one it reads one column further along the source. At layer two it reads two further along. Crossing the fourth column wraps the lookup back to zero.

Move through the slices before turning **ALL** back on. Can you anticipate where the blue will appear above its current position? In the full volume, the layers make a stepped relation that no single slice contains.

The changed rule is small. This is the lookup used to fill the volume:

```gdscript
func sample(x: int, y: int, z: int) -> int:
    var source_x: int = (x + y) % 4 if shifted else x
    return SOURCE[z][source_x]
```

Each result is stored at `values[y][z][x]` and selects a colour for the cube at `Vector3(x, y, z)`. The cubes keep their positions. Height has entered the colour lookup. Changing appearance across layers and moving the layers are different operations, even when both can suggest a slant.

Use **UNDO** to recover a previous rule, slice view or selected address. Find a change you can explain by following the source frame, then one that is difficult to see from where you stand. A stored value may be accessible to the program while another cube hides its visible body from you.

<!-- @ -->

What bodies are possible here? The extra index gives us another direction in which to arrange relationships. This particular rule makes repeated or shifted colour layers. It has not made a solid you can carve, a fabric that bends, or an organism that grows. Those would require further rules about what a value does.

There is already a decision worth returning to: every palette index receives a cube. Zero is a pale body. If zero meant no body, the same arrangement of numbers could admit gaps. If a value controlled density, resistance or affinity, other relations would become possible. We have not implemented those meanings at this station. We have found where they could enter.

For now, a slice lets you see by withholding most of the display. That is a useful reduction, provided we remember the forty-eight cells it leaves out. Turn the full volume back on before leaving. In **Ribbon_Patterns_02**, carry this distinction between stored value and visible appearance into the material and conditions that let a pattern be seen.



## Ribbon_Patterns_02

Source: commons/maps/Ribbon_Patterns_02/final.md

SHA256: 738c850adf0b894d24386b5030ebde05df99e79b8d64f51d875042c115cb5040

The value has stayed. Has the colour?

The previous room let you hide forty-eight cells without erasing them. Here the question turns towards the visible ones. A value has reached a surface. What else has arrived with it?

<!-- @SimultaneousContrast -->

Begin with the two grey squares. One has dark neighbours, the other light. Look before touching the controls. Do they appear alike to you? There is no required answer to report; make a comparison you can return to.

Press **SWAP**. The backgrounds exchange places. The targets keep their numerical values. Does your judgement follow the square, its surroundings, or neither?

Press **SURROUNDS** to give both targets the same grey background. Then return to the unequal backgrounds and press **CONNECT**. A narrow bar joins the targets using their colour. Notice what becomes easier to compare, and what remains uncertain. **UNDO** returns to your previous arrangement; **RESET** restores the start.

The two targets and the connector are assigned `Color(0.5, 0.5, 0.5)`. This comparison draws them without lighting-dependent shading. The controls change the backgrounds and whether the connector is shown. Numerical equality is something we can inspect in the program. It does not oblige every viewer, display or viewing situation to produce the same experience.

<!-- @MetamerismLab -->

At the other station, the familiar bent mark covers a plane and a curved wall. Find its blue corner on both. The plane is four metres wide; the half-cylinder is four metres along its arc. Each begins with four horizontal repeats and two vertical repeats. Walk a little sideways. Equal distances along the surfaces need not occupy equal widths in your view.

Press **GRID** to mark the repeat boundaries. Follow one around the curve. Its width along the surface stays fixed while its visible width changes with your position. The two ends of this half-cylinder are edges, not a welded seam; this station has not tested a pattern closing around an entire body.

Turn the grid off and press **FLAT / SHADED**. Keep watching one pale part of the mark. Now press **LIGHT SIDE**. Where does it darken? Compare the plane with the curve before reading the explanation.

Both surfaces read one texture. Their difference enters through their normals: directions describing which way the surface faces. The plane keeps one direction across its face; the curve turns. This small shader multiplies the sampled colour by a directional factor:

```glsl
float gain = shaded
    ? 0.18 + 0.82 * max(dot(normalize(specimen_normal),
                            normalize(light_direction)), 0.0)
    : 1.0;
ALBEDO = ink * gain;
```

The dot product compares the two directions. The added 0.18 keeps the model's darker side from becoming completely black. These are choices in the experiment. **LIGHT SIDE** changes a direction inside this shader; it does not move the museum's sun. The calculation does not model cloth fibres, gloss or wavelengths. Keeping the model small lets us follow exactly where the difference enters.

Try **REPEAT SIZE**. It changes the horizontal repeat from one metre to fifty centimetres on both carriers. The vertical repeat remains one metre. Neither the source pixels nor the meshes change. **UNDO** recovers the earlier setting; **RESET** returns to flat colour and the initial spacing.

The archived name of this artifact is MetamerismLab. Its earlier wave display assigned the same RGB yellow to both results without computing spectra. This encounter instead gives us a difference we can inspect: shared source values, different surface directions, and a stated rule for producing appearance. The older name cannot do the work of an experiment.

<!-- @ -->

Imagine carrying this mark onto a sleeve. Which part would you call the pattern: the source array, its spacing along the cloth, or the appearance that reaches someone across the room? Keeping one of those fixed does not keep all of them fixed.

This is where dressing becomes a question for the program. A carrier contributes shape; a material contributes rules for appearance. Neither is a neutral delivery system for an untouched original. Yet their contributions can be separated enough to investigate: keep the recipe, change one condition, return, compare.

In **Ribbon_Patterns_03**, we follow these operations into the shader and fabric studio: what gets sampled, where an edge is drawn, how a surface responds, and what can be carried onto a body. The mark will travel again. We now have more than one place to look when it changes.



## Ribbon_Patterns_03

Source: commons/maps/Ribbon_Patterns_03/final.md

SHA256: d37e668f05961bc71d47bdef8b6cb3c6a97195cbb5ec4be69407c950e077d0d8

What can you take with you?

The mark has crossed a floor, reflected, slipped along a row and acquired depth. In the previous room its values stayed fixed while the surface changed how they appeared. Here the surface is waiting beside a body. Find the bent red mark on both. What would have to stay the same for you to call this the same fabric?

<!-- @fabric_shader_studio -->

Choose one of the four paint colours, then touch a square in the small source array. Watch the wall and the skirt together. One address changes; many places answer. **UNDO** brings the earlier source back. We still have the array we learned to read. We have given it somewhere else to arrive.

Press **UV / FABRIC**. The familiar mark disappears into a coloured field. Walk around the preview skirt. Where does the colour return to its beginning? This view draws the surface's own two coordinates as red and green. A curved body can carry a flat address system. It also has to decide where that system joins, ends or starts again.

Return to the fabric and press **OFFSET**, then **REPEAT**. Which operation moves the mark? Which makes more copies fit? The wall and skirt both begin with four horizontal repeats and two vertical repeats in their own UV coordinates. Their physical widths differ. Four copies around this skirt do not promise the metre spacing of four copies across that wall.

```glsl
vec2 address = UV * vec2(repeats, 2.0) + vec2(phase, 0.0);
ALBEDO = texture(motif, address).rgb;
```

The source texture is four by four pixels, read with nearest filtering. `UV` supplies an address from the mesh; multiplication repeats it, addition shifts it, and the texture wraps. A small statement keeps finding new places to speak. The skirt's side and caps bring their own UV layout. We have not made a tailor's continuous cutting pattern, or promised that every seam will match.

Try **CUT OUT**. Narrow strips disappear from the wall and skirt. Look through a strip, then try to move through the sample wall. The view opens. The collision still refuses you.

```glsl
if (cut_out && fract(address.x) > 0.8) discard;
```

Here `discard` stops drawing a fragment. It does not cut a passage into the collision shape. There are already two accounts of the wall: one receives your gaze, another receives your attempt to cross. Finding their disagreement gives us somewhere precise to work. A visible opening has made a promise that the movement system does not keep.

Turn the cut-outs off. Press **FINISH** and compare a pale patch on the plane with one turning around the skirt. This control changes roughness and metallic response in the engine's material model. It leaves the source alone. Now try **VERTICES** and look along an edge.

```glsl
VERTEX += NORMAL * amplitude *
    sin(UV.y * 18.849556 + UV.x * 6.283185);
```

The shader moves rendered vertices along their normals, by at most 0.04 local units. The wall's subdivisions provide vertices to move. The garment has its own mesh and scale, so its result differs. Collision stays at the old shape; this deformation does not simulate cloth, gravity or a moving hem. Even the shading normals retain the original mesh directions. An edge has changed, but several systems still remember the earlier body.

<!-- @super_drag_mirror -->

Use **LOOK** to choose a silhouette for the preview. When you want to carry the current recipe, press **SAVE**, then **WEAR SAVED**. The saved fabric goes onto your skirt. Your bodice, crown and sleeves keep their own materials. Walk to the mirror.

This looking glass sees the body you are wearing in the shared scene. Turn slightly. Find the altered source cell again. It belongs to the recipe, but the shape and viewpoint have given it another appearance. What seemed like a surface sample is now part of how you meet yourself.

Change your look at the mirror. The skirt keeps the recipe. The permission to travel was quite specific: the program looks for a mesh named `Skirt`. Other parts of the outfit have not been invited into this exchange. There is room for another garment adapter here, and for a question about who gets to define the parts of a body.

Return to the studio and edit a cell. Your worn skirt keeps the saved version. **SAVE** replaces the stored recipe; **WEAR SAVED** chooses to wear it again. **UNDO** can restore the outfit and fabric from before a wear action. It follows the studio's recent actions, up to thirty-two, and does not erase or rewind the saved recipe file. The mirror offers a head-centred reflection; how it feels through the headset still needs our return.

<!-- @drag_catwalk -->

Press **RUNWAY SAVED**, then join the four performers. Find the same mark moving towards you and away. Their skirts receive the stored recipe; their other materials and their walking route remain their own. **SWAP LOOKS** changes their silhouettes while keeping the fabric. The studio's **UNDO** can restore each performer's previous fabric.

These walkers follow a programmed route. Their steps and poses do not prove that the garment can balance, bend or bear weight. Yet they make another comparison available: a recipe shared across bodies, encountered at different moments. Repetition can make a group legible without making its members look identical.

<!-- @ -->

Colour supplied values. Arrays gave them addresses. Patterns gave us rules for returning to those addresses, and shaders let the receiving surface take part. We can now carry a small source into a room, a garment and a procession. Each carries something of it; each leaves something unresolved.

The performers have been moving while we worked. In **Change_Intro**, we will ask a question that a saved appearance cannot answer: how much is changing, and how quickly, here? The fabric can come with us. Its next possibility may need a clock.



# change

Declared order: Change_Intro → Flow_Field


## Change_Intro

Source: commons/maps/Change_Intro/final.md

SHA256: 3f0dda74ccd813d4b648a6928b125becabfd5f8945e46110d210cd9c3239d327

# Change and accumulation

## Measure a change

Where can a high curve be changing very little?

The fabric can come with you. In the previous room, changing an address changed what reached a wall or a skirt. Here the curve stays fixed while you choose where to inspect it. We are still changing position, not advancing a clock. Before asking how fast a body moves, we can ask how a value changes from one place to another.

<!-- @tangent_slope_workbench -->

Begin with the red point and its green neighbour. A green line joins them. At the starting position, which point is higher? Follow the curve between them. Does that straight connection tell you everything the curve has done?

The console names three quantities: `x`, the selected position; `f`, the value there; and `h`, the interval to the other sample. Below them are the rise and the rise divided by that interval. A negative rise says the second value is lower when the interval points to the right. It does not tell us that every part of the journey went down.

Leave the red point where it is and press **STEP**. Watch the green neighbour approach. Press again, and again. Does the line still lean the same way? Now press **DERIVATIVE**. A gold tangent appears at the red point, and a second plot shows the local slopes along the whole curve. Compare their directions before reading the numbers.

At this starting position, the wide interval crosses a crest. Its two endpoints report an overall fall. Close enough to the red point, the curve is still rising. Both reports describe this same curve. They answer questions at different scales.

```gdscript
var rise = f(x + h) - f(x)
var rate = rise / h
```

Two values and an interval are enough to construct the green line. This rate is a finite difference: change across the interval, per unit of position. **STEP** cycles through 0.5, 0.25, 0.125 and 0.0625 position units. At the right edge, the bench samples backwards and displays a negative `h`; the division uses that signed interval. Zero is never offered. Dividing by zero would not uncover the tangent.

The derivative asks what these ratios approach as the interval tends to zero, where that limit exists. This bench does not reach the limit by pressing the button enough times. Its gold tangent comes from a separate analytic calculation for the smooth curve:

```gdscript
func f(x: float) -> float:
    return 0.5 + 0.4 * sin(2.0 * x) + 0.15 * cos(5.0 * x)

func df(x: float) -> float:
    return 0.8 * cos(2.0 * x) - 0.75 * sin(5.0 * x)
```

The two functions can be read alongside one another. The heights do not become slopes by changing their label: the calculation changes. `df` gives the local rate against which we can compare the finite samples. A smaller interval helps here, but the four choices are an experiment, not a proof that every smaller computational step must improve every estimate. Precision, noise and the shape of the function can matter.

Use the existing slider, or **x −** and **x +**, to move the red sample. Find a high point with a nearly flat tangent. Then find a lower point with a steep tangent. Compare `f` with the analytic `f′` readout. Height and rate cannot replace each other.

Try two places of similar height with opposite slopes. Imagine receiving only their height values. The report could be accurate and still conceal the distinction you need for your next movement. This is another kind of remainder: the data retained something true while leaving out a relation.

The sign card says **near zero** when the magnitude is below 0.05. That threshold is a display choice. It does not certify an exact zero or prove that you have found a maximum or minimum. Look at the neighbours. Extend the gold line in your imagination: it can describe the curve nearby without becoming a map of the whole journey.

Press **DERIVATIVE** again to hide the analytic comparison and make another prediction. **RESET** returns to the initial position and wide interval, with the tangent hidden. A sharp corner would ask whether the rates from its two sides can agree. This bench contains one smooth function; that corner remains an experiment we could build.

<!-- @ -->

What does this make possible for a body? Knowing a height tells it where a surface is. Knowing how height changes with position can help it anticipate an incline. This plot supplies the distinction; it does not make the museum's walking controller use it. That connection would be another piece of code.

Replace position with time and a rate acquires different units: change per second. The choice of independent variable belongs to the question. Moving the slider quickly does not make this curve's derivative a velocity.

Walk to the accumulation workbench in this hall. Carry the difference between a value, a local rate and the interval through which you look. We will keep the same curve and ask a different question.

## Add contributions

The curve has followed us. At the first workbench, two samples could report a fall while the curve was rising at the first point. Here we keep the same function and ask it for something else. Across this whole interval, how much area lies between the curve and the baseline?

<!-- @riemann_sum_workbench -->

Four blue rectangles wait under the line. Their tops cut through it. Somewhere a rectangle includes space above the curve; elsewhere it leaves space beneath it uncounted. Before touching the slider, choose one rectangle. Where would you put its top?

The console begins at **MID / N 4**. Press **CELL +** to move the red sample through the four intervals. The selected height and width appear together, followed by their product. Each interval is 1.25 units wide. One height has been asked to represent everything that happens across that width.

Press **HOLD**. A second panel keeps these four rectangles and their total. Now press **RULE** once. The live rectangles take their heights from the right edges of their intervals. The curve has not moved. The widths have not changed. Watch how much of the picture changes anyway.

Which total would you trust? Keep the question open while pressing **RULE** again for the left edges, then again for the midpoints. The held panel remembers the version you chose to keep. Its stillness gives the moving comparison somewhere to land.

The calculation is short enough to read aloud:

```gdscript
var width = (b - a) / n
var total = 0.0
for i in range(n):
    var x = a + (i + fraction) * width
    total += f(x) * width
```

`fraction` is 0 for the left edge, 0.5 for the midpoint, and 1 for the right edge. An address, a height, a width, an addition. The loop keeps doing the same small thing. What looks like a filled area is made from these contributions.

This is a Riemann sum. Here `a` is 0 and `b` is 5. The function stays positive, so the contributions are positive areas. In another model, a rate multiplied by a time interval could give an amount gained during that interval. We would need to name that rate and those units. Moving this slider does not turn its position axis into a clock.

Return to the midpoint rule and leave the held four-rectangle panel beside it. Move the count slider one stop. Eight narrower rectangles now look at the same curve. Follow their tops. A ridge that passed between two samples may now receive a sample of its own. Continue through 16, 32, 64 and 128. What becomes easier to estimate, and what becomes harder to distinguish by eye?

The held total stays at about 2.23665. At eight midpoint samples the live total is about 2.88669. More samples have changed the account substantially. The smooth-looking line did not warn us how much the first four would miss.

Only now press **REFERENCE**. The console shows a separate estimate made from 4,096 midpoint rectangles, about 2.86384, and the signed difference between the live sum and that reference. Toggle it off to return to the selected contribution. The small difference bar has a cap of 0.05; two full bars can conceal very different discrepancies. Read the numbers as well as the shape.

Try **RESET**, hold the four midpoint rectangles again, and select the right-edge rule. Against this reference, those four right-edge samples are closer than the four midpoints. A familiar method has no entitlement to win every coarse comparison. For this smooth function, sufficiently fine partitions bring the estimates together; that does not make every finite sampling choice equivalent.

There are several resolutions in front of you. The curve is drawn with 200 line intervals. Your sum uses one of six counts. The reference uses 4,096 rectangles. The integral is the limit these sums approach as the partition width tends to zero; none of the buttons reaches that limit. The apparently continuous image and the reassuring reference number each have a finite construction we can inspect.

<!-- @ -->

What did we reject to make a total possible? Variation inside each interval has been replaced by one selected height. Then the individual contributions have been gathered into a number that cannot tell us where they came from. The held picture keeps some of that history available. It still cannot keep everything.

Ada needs such reductions to run. The question is where to reopen them. An estimate can be useful enough to act on while leaving a difference worth returning to. Who chooses the tolerance, and for which body or task?

Before leaving this hall, visit the bridge. The sum we have just inspected used positive heights. What if the contributions themselves could be positive and negative?

## Recover a difference

Can a journey return to its starting height after changing all the way?

<!-- @ftc_bridge -->

Watch the pulse move along the arch. Predict the height difference left between its beginning and end. Then follow the coloured contributions beneath the bridge. Which side contributes positively, and which side negatively?

The arch rises and falls to a level endpoint. Zero net change does not mean that nothing happened. The curve here is a different function from the workbenches: a symmetric arch. Its horizontal coordinate is still position. The moving pulse lets you follow that function; its animation clock is not the input used by the rate plot.

The bridge now shows its working. A plot below the deck gives the local height rate with respect to horizontal position. Signed strips extend above or below the plot's baseline. Endpoint labels and a difference marker appear beside it. Underneath, a numerical sum of the rate is compared with the endpoint height difference.

```gdscript
var dx = span / samples
for i in range(samples):
    total += (slope_at(i) + slope_at(i + 1)) * 0.5 * dx
```

This is the structure of the bridge's trapezoid calculation, using 512 intervals. Its slope function and endpoint heights come from the same selected curve. It is a finite numerical comparison, not a proof printed by the machine.

For a continuously differentiable height function, integrating its signed derivative across an interval recovers the final height minus the initial height. This is the net-change relationship in the fundamental theorem of calculus. Recovering a function from its derivative still requires a starting value: a slope alone cannot tell us how high the whole bridge was placed.

Compare the earlier positive-area sum with this signed-rate sum. They use different inputs and answer different questions. Adding the magnitudes of the rate contributions would measure something else again. A journey's net height change can vanish while its rises and falls remain substantial.

<!-- @ -->

What would a report of zero leave out of your journey? The total can be correct and insufficient for the question you now want to ask. We have preserved three encounters here so that you can return to the choice: sample a change, gather contributions, recover a difference.

In **Flow_Field**, an update will help determine the address of the next sample. Carry the loop forward. We are about to make the path through the data part of the computation.



## Flow_Field

Source: commons/maps/Flow_Field/final.md

SHA256: 3ea544c0c2772fd26164796aa38cc652ab9b8b84d28dff2b7953dc9f03f88223

# A path made by its next step

Where will this particle look next?

In the previous hall, we chose addresses along a fixed interval, measured changes, and added contributions. Here an update changes a particle's position. That position becomes the address used by its next update. The loop starts making its own route through the field.

<!-- @flow_field_painter -->

Begin with the little canvas. Eighty particles leave coloured trails. Follow one through a bend before trying to read the whole picture. Do its neighbours continue beside it? Predict the next turn.

The display says **FIELD HELD**. The particles are moving, but the field's time coordinate is held still. Press **ARROWS**. Twenty-four arrows appear over the canvas. Find one near a particle and compare their directions. An arrow gives the instruction at its own address; a particle a little farther away samples a different address. They need not point exactly alike.

The arrows and particles call the same function. The neighbouring vector-field exhibit has its own definitions; it is not secretly steering this canvas. Here we can inspect the data connection itself.

```gdscript
var direction = field_direction(position)
position += direction * speed * delta
```

One local direction, one speed, one elapsed interval. The program repeats that operation at the new position. The trail remembers a limited sequence of those positions. It does not remember an infinitely detailed movement between them.

Keep SCALE fixed and move SPEED. What changes about the spacing of the samples? Now keep SPEED fixed and change SCALE. Look at the arrows as well as the trails. You have changed how the directional rule varies across space. Existing trails still contain earlier instructions, so give the particles time to replace that history, or use RESET.

The field starts from a scalar noise value. The program turns that value into an angle, then takes its cosine and sine to obtain a unit direction:

```gdscript
var angle = noise_value * TAU * 2.0
var direction = Vector2(cos(angle), sin(angle))
```

That construction makes a vector from a value. It does not calculate the noise function's gradient. A gradient would require measuring spatial changes in that scalar value, returning us to the first hall's question about rates. Similar-looking swirls can conceal different operations.

Press **FIELD TIME**. The field's time coordinate now advances too. The arrows refresh ten times per second while particles update every rendered frame. Can an arrow appear to lag a nearby turn? The shared rule is real, and the display still has a sampling schedule. Press again to hold field evolution at its current time; particles continue moving.

RESET scatters new starting positions and clears their trails without choosing a new noise seed. SEED chooses a different noise field and resets the particles. Neither button rewinds every clock. Distinguish a new starting distribution from a new rule before comparing their pictures.

Watch an edge. A particle leaving one side wraps to the opposite side. A long stroke across the canvas can be the trail renderer joining its last position before that wrap to its first position after it. The line suggests a crossing the update did not make. We have encountered another gap between an operation and its picture.

<!-- @ -->

What kind of body can exist here? This particle has a position and receives a prescribed direction and speed. It has no mass in this calculation, no accumulated velocity and no collision negotiation with the other particles. Its neighbours can influence what we see without influencing how it moves.

The opposite edges are joined by the wrapping rule. Directions on those edges are not guaranteed to match: the noise is not made periodic merely because the particle's coordinates wrap. A world can provide a return route and still contain a seam. Follow one return and look for it.

The pattern may recall a fluid. Its beauty invites that association; the code lets us ask how far the association holds. Changing a boundary rule or adding interactions would permit other kinds of movement, and ask for other quantities to be stored.

In **Forces**, we will distinguish a prescribed direction from an acceleration that changes velocity. A body will carry more of its previous motion into the next update. What possibilities appear when it cannot simply take the new direction immediately?



# forces

Declared order: Vectors_Act1_WhatAVectorIs → VFM_02_Operations → Vectors_Act2_VectorArithmetic → VFM_05_Launch → VFM_03_Motion → Vectors_Act3_FieldsAndMotion → Vectors_Act4a_KineticForces → Vectors_Act4b_Oscillation → Change_Choreography → VFM_07_Gravity → VFM_09_Legs → VFM_08_Arena → Vectors_Act5_ForceAsPlace


## Vectors_Act1_WhatAVectorIs

Source: commons/maps/Vectors_Act1_WhatAVectorIs/final.md

SHA256: e270dec4f34a0a1894a148093a442442e33c12b2fbaa47b5b13392c3261c6606

# The same difference, somewhere else

Can something move without its vector changing?

We have given points addresses, transformed shapes, made patterns and followed changes through time. Now keep two addresses together. One names a beginning; the other names an end. What can we carry forward from their relation?

<!-- @VectorBasics -->

At the first bench, move either pin of the small arrow. Watch the large wall. Two yellow arrows respond: an elevation view, XY, and a floor-plan view, XZ. They are two projections of the same displacement. Predict which view will change most before moving the tip again.

Press **SHORT**, then **LONG**. The displacement changes from a quarter metre to one metre without changing its direction. Look between the hand-sized arrow and the wall. The pictures have different display scales; their shared input is the difference between the pins in world coordinates.

Press **SHIFT**. Both pins move together by twenty centimetres along the bench. Their addresses change. Does the wall have anything new to report? Press again to return them. An unchanged picture can be evidence that the machine is doing exactly what we asked.

Only now press **PARTS**. The components and magnitude appear on the console; coloured legs make the components visible in each projection.

```gdscript
var displacement = end.global_position - start.global_position
```

Subtraction keeps the difference and discards the two original addresses. This is a free displacement vector: it can be represented at another origin without changing its direction or length. Later, where a force is applied will matter. We should not carry this freedom into every physical question without testing it.

The wall keeps the world axes fixed. Turning the bench changes how its local directions relate to that frame. A screen on a wall is another arrangement inside the room, not a transparent window onto mathematics. One projection leaves out Z; the other leaves out Y. Neither alone tells the whole displacement.

Now press **ZERO**. The pins coincide, and the displacement has length zero. There is no direction for the yellow arrow to show. If you press SHORT or LONG from this state, the interface chooses the direction (1,1,1), normalised. That direction is a convention supplied by the control, not information rescued from zero.

The wall samples the pins twenty times a second. An update can reach the small arrow before it reaches the large picture. If a projection exceeds the drawing window, the wall limits its drawn length and labels the clipping; the component numbers retain the measured displacement. The representation has a capacity, and it says where that capacity ends.

<!-- @ -->

The coordinate frame, route courier and length lantern remain nearby as supporting encounters. A path has an origin and a history even when a displacement summary does not keep them. What was useful to discard for this question may be necessary for the next one.

<!-- @vector_normalize_demo -->

At the second primary, compare the input vector with its normalised companion. Change the input direction and length. Which changes reach the companion? Which do not?

The operation divides a nonzero vector by its own magnitude:

```gdscript
var magnitude = v.length()
var unit = v / magnitude if magnitude > 0.001 else Vector3.ZERO
```

Length is removed while direction is retained. The sphere and rings provide the diagram's reference for unit length; they are part of the display's scale. A long input can become shorter and a short input longer. Normalisation is not simply shrinking.

This implementation also chooses a threshold: magnitudes at or below 0.001 return zero. It does not normalise every tiny nonzero input. The boundary keeps the calculation usable while treating a neighbourhood around zero as having no available direction. The numeric output now reports the computed length, including zero, rather than always printing one.

<!-- @ -->

We have made something reusable by leaving information behind. First the two addresses, then the magnitude. Reuse is powerful because of these reductions; the reductions also need to remain open to inspection.

Next, in **VFM_02_Operations**, vectors meet. We will compare a composed displacement with its separate contributions before asking a force to change a body's movement. The arrow on the wall can eventually become an instruction to the room. Today it describes; it does not push.



## VFM_02_Operations

Source: commons/maps/VFM_02_Operations/final.md

SHA256: 51edcafb21e713d250e36300b70e28d0f5ba8ee832c7804c723a6d4d7016cd9f

# The journey that adds up to nothing

<!-- @adder_board -->

A pale cube waits inside a glass-edged grid. Amber makes one leg of a route; pink continues from its end. A cyan mark waits elsewhere on the floor. Above them, the wall draws the same arrangement from overhead.

Press **GO**. The cube starts at home, follows amber, turns, follows pink. It stops at cyan.

Now **SWAP**, then **GO** again. The turn happens somewhere else. The destination has not moved.

There is already something here that the destination cannot tell us.

In the previous room we moved two points together and kept their difference. Here we keep two differences and exchange their order. Each contribution belongs to the same floor frame: X across the stage, F forward into it. Both are measured in metres. The wall turns that floor into a small upright plan; its upward direction means forward, not climbing.

The first pair is one metre across and one metre forward. **A/B** selects a contribution. **X−**, **X+**, **F−**, **F+** change one of its components in half-metre steps. Change the pink contribution and watch both cyan marks. The wall and the stage receive one result.

Try **PATH**. The console now says *direct*. **GO** sends the cube straight to cyan. The corner has gone, but the destination remains. On these opening inputs the two-legged trip covers two metres. The direct trip covers about 1.41.

Press **RULE** when you want to see the arithmetic that has been holding this together:

```gdscript
result = a + b
```

Small enough to pass over. Yet this is where two contributions become something a receiver can use. Component by component, one metre across plus no metres across; no metres forward plus one metre forward. The result is `(1, 1)`.

The carriage receives the result as a destination. The wall receives it as a point in a diagram. Neither has to invent another answer.

Addition needs compatible quantities and a shared frame. A metre of displacement can meet another metre of displacement here. Later, two velocities or two forces can be added by the same component rule, but the resulting numbers will have different jobs. The shape of a vector alone cannot tell us which job it has been given.

**CANCEL** sets B opposite to A. Keep A nonzero. Cyan returns home.

Choose the route *via A* and press **GO**. The cube leaves, reaches the corner, and comes back. The travelled counter grows. The sum stays zero.

Zero has not meant that nothing happened.

Switch to *direct* and run the same pair. This time the cube stays home. Two journeys now share both their start and their destination. One has movement, a turn, elapsed time. The other has no distance to cover. If we kept only the sum, we could not recover which one we had watched.

The out-and-back is useful precisely because it does not vanish from every account. Displacement cancels; distance accumulates. We have already met accumulation. Here it keeps a fact that the endpoint leaves behind. Which account would a delivery machine need? Which would a tired body insist on keeping?

There is a small choreography in the implementation too. The stage turns its two floor coordinates into three scene coordinates:

```gdscript
return Vector3(v.x, height, -v.y)
```

The second number goes forward along local negative Z. Height is supplied separately. Turning a plan upright on the wall has not given the carriage permission to rise. Its body is possible within this particular translation between representations.

The controls stop each input component at plus or minus one metre. A larger request meets a limit chosen for this stage. That boundary is not a property of vector addition. You can see the refusal by pressing again at the edge: the button still exists, but the value stays where it is.

And **GO** has its own convenience. It puts the cube back at home instantly before each trip. Editing the route resets it too. That return is outside the travelled counter. The experiment makes repetition easy by deciding where a journey begins. The running museum has no obligation to begin there with it.

For now, a prescribed speed carries the cube along a chosen path. Nothing here measures a push or asks the cube's mass. Beyond this arena the other instruments are still waiting: subtraction, projection, alignment, rotation. We can carry one question into them. When a relationship becomes a usable result, what becomes possible—and what would we need to keep if we wanted to remember more?



## Vectors_Act2_VectorArithmetic

Source: commons/maps/Vectors_Act2_VectorArithmetic/final.md

SHA256: 9a141e8b922c81f6487ef8ff0aad06e36266e07b5b2465ce0e16247b101cc1fe

# What the line can keep

<!-- @vector_add -->

The carriage is behind us. We have watched two routes reach one destination, and a journey return with zero displacement. A smaller addition console offers the relationship again, through two pads that place the arrow tips on its upright diagram.

Move one pad. The sum moves with it. At this scale there is no carriage to wait for. That absence matters: the result appears immediately, although a body given that destination would still need a way to get there.

Keep the distinction as we walk. These operations give us relationships. A simulation has to decide what to do with them.

<!-- @vector_sub -->

Two small blocks stand on the next gridded stage. Amber is A, pink is B. The cyan arrow runs from B to A. Its copy on the wall makes the same connection.

Press **SWAP**. The arrow reverses.

In the previous hall, exchanging the contributions kept the sum. Here exchanging their roles changes the answer. The distance between the blocks has not changed. Which one we are trying to reach has.

**A/B** chooses an address; **X−**, **X+**, **F−**, **F+** move it in half-metre coordinate steps. Try **SHIFT** instead. Both addresses move sideways together, while the gap between them stays the same. That is the first vector room returning inside a new operation.

Then **SAME** brings B to A. The two addresses coincide. The cyan arrow has no length to draw.

Press **RULE**:

```gdscript
gap = a - b
```

From a shared origin, A and B each had an address. Subtraction gives the displacement needed to get from B to A. We could also add the reverse of B. We have not introduced another kind of number; we have asked a different question of the same coordinates.

The diagram has a scale of its own. Each coordinate metre is drawn as half a metre, on the floor and on the wall. X goes across; F goes forward on the floor and upward on the wall. An upward arrow in the drawing still does not authorize a climb. The little blocks are representations of addresses, not a measurement of the visitor's position.

The controls stop at ±1.5 metres per component. SHIFT refuses the whole move if either address would cross that boundary. It does not quietly move one and spoil the comparison. A limit chosen for the exhibit is already shaping which questions can be asked without rebuilding it.

<!-- @dot_aligner -->

Between the gap and its next use, a small aiming console makes a decision from an angle. Move its **ALIGNMENT** slider. The drawn aim changes relative to a target; the readout moves toward *FRIEND* as their directions approach one another.

The source compares normalized directions. Their dot product is one at complete alignment, zero at a right angle, negative when they point sufficiently against each other. This placement's ordinary slider covers only a limited angular range; it does not offer the whole operation. The larger dot-product exhibit beside it is a separate comparison, not another control for this console.

A threshold of `0.985` divides the illustrated target's status. The directions vary continuously, but the name changes at a boundary someone selected. The target is not learning to trust the turret. A drawing is being classified by a rule.

That is a useful place to pause before calling a number agreement. What relation have we measured, and what extra story did the label attach to it?

<!-- @projection_shadow -->

At the next wall, the cyan gap has arrived before us. This station reads the actual A and B values from the subtraction station in this hall. It has not invented a similar-looking example.

A rail lies across the diagram. Gold runs along it; pink reaches from gold's endpoint to cyan's. Press **RESET** to return both stations to their opening coordinates and the rail to X. Then **SLIDE**.

A moves in the source. The cyan gap changes. Gold stays where it was. Pink grows.

SLIDE moves A half a coordinate metre perpendicular to the rail, reversing that step on the next press. The rail cannot register this part of the movement in its along-rail reading. Here the remainder remains visible beside the answer.

Now **TURN**. The rail turns thirty degrees while the incoming gap stays fixed. What was beside the rail becomes partly available along it. The vector did not become more complete. The direction of the question changed.

When you press **RULE**, three short lines hold the experiment together:

```gdscript
kept = axis * gap.dot(axis)
remainder = gap - kept
```

The axis is maintained at unit length. `gap.dot(axis)` gives a signed distance along it. Multiplying by the axis turns that number back into a vector. Subtracting the kept part leaves the perpendicular remainder.

And the addition we already know can check the result:

```gdscript
kept + remainder
```

It gives the gap back. To ordinary floating-point precision, the remainder's dot with the rail is zero. Nothing needs to disappear if we keep both parts. If a later machine stores only the projection, many different gaps will fit the answer it retained.

Try **FLIP**. The signed distance changes sign, but the gold vector stays in place: both the axis and its scalar coordinate reverse. Even a negative number cannot tell its whole story without the frame it belongs to.

There is pleasure in finding that the pink part has somewhere to go. It was excluded from this rail's account, not from existence. Turn the rail and the distinction moves. We can build a machine that needs only the gold part. We can also ask what another body could do with the pink.

<!-- @torque_crank -->

The crank farther along takes the question toward turning. Its **LEVERAGE** slider changes the angle between an illustrated arm and push. Along the arm, the normalized cross-product magnitude is zero. Across it, the value grows toward one.

The source contains a compact expression of the geometric relation:

```gdscript
var torque_vec: Vector3 = r_dir.cross(f_dir)
```

These are unit directions. Their cross product supplies an axis and an angular factor. Physical torque would also need the actual arm length and force magnitude. The exhibit draws its wheel at an angle derived from that factor; it does not accumulate a wheel's angular velocity through time.

Look at the label that says *rpm*. In this implementation it is the factor multiplied by 320 and rounded. It is not a rotation counter. A plausible instrument has arrived before the dynamics that would make its reading a measurement.

We can use that discrepancy. The diagram shows a relation worth learning, and also where a future simulation must do more work. What the rail keeps of a push along an arm contributes no torque about that arm's origin; the perpendicular part can. Yet neither a projection nor a cross product, by itself, makes a body move.

The larger comparisons and the distant laser-operated diagrams remain around this route. We need not finish every version before continuing. The next hall in the current sequence is Launch. Carry the gap, its components and this unfinished wheel with you: a destination, a direction, an initial velocity and a force may all be written with vectors, but they ask different things of time.



## VFM_05_Launch

Source: commons/maps/VFM_05_Launch/final.md

SHA256: 14c695ecdbbf59a1c3f0041b1346b1c11f40ddb8efd54a35f1a38e7a60b76458

# Stand inside the curve

<!-- @launch_arc -->

The controls are in the middle. A launch lane runs in front of you; another waits behind. The grid under your feet continues beneath both. For once, the diagram is large enough to ask you to turn around.

Press **FIRE**. An amber marker leaves its pad, rises, falls, and stops at the landing height. There was a straight arrow at the start. The marker took a curve.

Change the angle and try again. **ANGLE−** and **ANGLE+** move it in five-degree steps. Keep the speed fixed. Does aiming higher always carry the marker farther across the floor?

At first it may seem so. Keep going. The higher flight begins to give back horizontal distance. There is more room above the lane, and less progress along it.

Now **PAIR** adds the complementary angle in the lane behind you. At the opening setting, one launch is thirty degrees and the other sixty. Both begin at ten metres per second. Press FIRE and follow them in turn.

One is already down while the other is still in the air.

They have travelled the same horizontal distance: about 8.66 metres under this chamber's chosen gravity. One flight takes a second; the other about 1.73. A shared range has left two very different uses of space and time.

The two lanes are separated so that you can stand between them. Their markers do not land at one world address. They land at the same X coordinate, each in its own lane. Even a comparison that says *the same place* needs us to say which difference we are overlooking.

The control bank behind you offers **SLOW**. It advances the local flight clock at a quarter of ordinary playback speed. The museum keeps running. This small clock gives us longer to look at the ascent, the turn and the descent; it does not change the calculated path.

Press **PATH** when you want both predictions to remain in the room. Walk beside a low curve. Look across at the taller one. An archway and a low wall would ask different things of these routes. Neither obstruction is part of the calculation yet. Here you can stand where a physical projectile could not be allowed to pass through you.

**PARTS** opens another way of reading the flight. The velocity has a horizontal component and a vertical component. On the way up, the vertical one points upward. Near the highest point it shrinks to zero, then points down. The horizontal one keeps its length.

A downward acceleration arrow is still present at the top. Zero vertical velocity has not meant that the influence producing its change went away.

These arrows have units. Velocity is metres per second, drawn here with one metre per second occupying 0.2 metres. Acceleration is metres per second squared, drawn with one unit occupying 0.1 metres. Their lengths are representations with stated scales. The floor grid itself is one metre to a square.

Press **RULE**. The chamber computes each position from the launch condition and elapsed model time. Its vertical contribution contains this term:

```gdscript
Vector3.DOWN * 0.5 * gravity * t * t
```

The initial velocity contributes another:

```gdscript
launch_velocity(index) * t
```

Added to the starting position, they locate the marker. One term grows with time; the other with time squared. The curve is already in their different rates of growth.

We have met addition, subtraction and components. Here a component has acquired a role in a temporal model. The launch velocity is the initial condition. Gravity continues to change the velocity after departure. A destination would tell us where to go; it would not supply this history of getting there.

**SPEED** cycles through six, eight and ten metres per second. **GRAVITY** switches this chamber's downward acceleration between ten and fifteen metres per second squared. Change one, keep the others fixed, and fire again. A stronger downward acceleration shortens the time aloft and the range for the same launch velocity. These values belong to this model; the control does not change gravity for your body or for the museum's other objects.

Parameter changes reset the local flight. PATH, PARTS, RULE and SLOW let you inspect it without resetting it. FIRE always begins another run. This is how the apparatus makes comparisons repeatable: it can return an experiment to its beginning, while the person comparing it carries the previous run forward.

The bright path has sixty-four straight segments. The moving marker is evaluated from the equation at each rendered frame, rather than stepping from segment to segment. Look closely enough and two representations of the same flight disclose their different resolutions. Slow playback gives more rendered observations of the movement; it does not add pieces to the stored path.

At landing, the marker freezes at the launch height. With PARTS visible, its last velocity arrow is the incoming impact velocity, not a claim that a resting body continues moving. No collision response has been computed. The room has answered where this model reaches that height, and stopped before the next question.

Beyond the chamber, the other launch instruments remain. Some address actual objects or the player. Their names do not guarantee the same physical operation: setting a launch velocity and applying a continuing force are different interventions.

Next is Motion. We have a curve calculated from a known rule. What changes when the body carries velocity forward from one update to the next, and the next influence has not already been folded into a complete answer?



## VFM_03_Motion

Source: commons/maps/VFM_03_Motion/final.md

SHA256: 4674c8b37c0f9b89097f43fea600ca1ae44adda04311fbcf8cd07bb584b01278

# When the push ends

<!-- @VectorMotion -->

Step between the two control banks. The cube waits beyond them, held a metre above the grid. Press **PUSH X** once, then leave the controls alone.

The command lasts one second. The cube keeps going.

There is time to look back at the button. It has finished its small contribution. Something of that contribution is still crossing the room.

Press **COAST**. Does the cube stop? Try **BRAKE** instead. This time it slows. Two controls that might sound like ways of ending movement have asked different things of the body.

RESET returns the cube to its starting place and clears this run's velocity, trace and clock. Begin again. Press PUSH X, then COAST before the second is over. The cube leaves with less speed. Cutting the command short changes how much motion it acquires; it does not take back what has already accumulated.

In Launch we watched a position calculated from an initial velocity and elapsed time. Here a rigid body keeps its current velocity in the physics engine. Each new influence meets that state. The apparatus does not supply a complete curve in advance.

Turn toward the other control bank and reveal **PARTS** and **RULE**. Cyan gives velocity. Amber gives the force requested by the controls. When the pulse ends, amber disappears. Cyan remains.

The opening body has a mass of one kilogram. PUSH X requests two newtons for one second. Before a boundary intervenes, its velocity changes by about two metres per second. The relationship is acceleration = force / mass. An acceleration changes velocity for as long as it acts; velocity continues carrying position between those interventions.

**MASS** resets the run and cycles through one, two and four kilograms. Try the same pulse at two kilograms. The velocity change is halved. The cube looks the same size. A property that matters to its response was not something its silhouette could tell you.

Return to one kilogram. PUSH X, let the pulse finish, then **PUSH F**. The second command points forward along this chamber's local negative Z axis. Watch the cube leave sideways as well as forward. The new component has joined a velocity that was already there. An arrow showing only the latest request would miss part of where this body is going.

The source hands its requested force to the engine during each physics update:

```gdscript
body.apply_central_force(global_basis * local_force)
```

The multiplication turns the room's local direction into a world direction. The engine integrates the body's response. This call does not set its destination, nor replace its velocity with the arrow we just chose.

BRAKE makes another request. It points against the current velocity, with a cap of two newtons. Near rest, a smaller force avoids carrying the body into reverse during the next step. Stopping takes an intervention and time. RESET can erase the velocity immediately because resetting an experiment has been granted a different power.

Try **DRAG**, then COAST. Now the cube slows even though the command has ended. DRAG enables the engine's linear damping. COAST leaves that setting active. With DRAG off, this model explicitly removes both gravity and inherited linear damping; persistence was made possible by those choices too.

At the amber perimeter the cube rebounds. You can walk across that same line. The solver boundary recognises one collision layer, and the cube belongs to it. Your body and the control furniture do not. We appear to share a room, while its rules have divided us into different possible encounters.

The cube also keeps its height and cannot turn. These are locks, not achievements of balance. A three-dimensional body has been admitted to a horizontal experiment. Releasing a lock would open another question, but these controls do not yet release it.

Pink shows acceleration measured from successive velocities. At a rebound it may jump while the command reads zero. That is not an absent cause: the boundary has acted through collision response. The readout separates the force we requested from the body's measured change. Damping can separate them too.

The arrows use different stated scales, and each stops growing at 2.5 metres. Read the numbers when a long arrow reaches that limit. **TRAIL** keeps the latest 120 samples, taken at nominally ten per second. Follow the body long enough and the beginning leaves the drawing. Its velocity can still carry a contribution whose trace has already been discarded.

The run has room for a recent history. It has not kept everything that made the present.

<!-- @friction_ramp -->

Farther into the hall, a much smaller block waits on a ramp. Leave its angle at thirty degrees. Move **μ** until STATIC becomes SLIDING. Reset the block and approach that boundary again, more slowly.

Now hold μ fixed and change **ANGLE**. Can another adjustment reach the same beginning of movement?

Just before it starts, look at the arrows. Stillness has not emptied the block of influences. Gravity pulls partly down the incline and partly into its surface. Support answers the inward component; friction can answer the downhill component, up to the bound selected here.

The demonstration tests that boundary with this expression:

```gdscript
sin(angle_rad) > friction_mu * cos(angle_rad)
```

On one side the model holds the block still. On the other it accumulates downhill velocity. A continuous adjustment has crossed a condition that changes which behaviour the program permits.

Choose a setting that clearly slides. RESET and watch successive parts of the descent. The block gains speed. Increase resistance a little, reset, and compare. Keep the beginning, the acceleration and the automatic return at the bottom separate: that return prepares another run; friction has not thrown the block uphill.

This ramp has a different implementation from the large chamber. It computes one scalar velocity, uses one friction coefficient, and slows the displayed travel with a factor of 0.01. If you raise resistance into its STATIC condition while the block is moving, it immediately sets that velocity to zero. It does not apply the chamber's gradual braking force. Try that transition and look for the cut.

We need the comparison, and we need to know what made it manageable. The model exposes a threshold while abbreviating part of the contact history. What would become visible if starting friction and sliding friction could differ? What would it take to keep the existing motion when the rule changes?

<!-- @ -->

Next, fields and motion. A single command has met a body carrying a past. What happens when the next influence depends on where that body arrives?



## Vectors_Act3_FieldsAndMotion

Source: commons/maps/Vectors_Act3_FieldsAndMotion/final.md

SHA256: 3050d9438bf37064deb243305c9823223f87428dd6e2c73c2aab650efce8cea3

# The arrow does not decide

<!-- @VectorFieldFlow -->

Two small bodies wait beyond the controls. They share an address on the floor, one held a little higher so you can distinguish them. One is cyan, the other pink.

Stand between the control banks and press **RUN**. Both head inward. Watch the centre.

Cyan approaches and slows. Pink crosses it, keeps going, then begins to turn back. They started together. What did the second body bring through a place where the first was coming to rest?

Use RUN again to pause. **TRAILS** leaves their recent paths in the space and draws the same histories on the wall. In this first example the lines lie along the same diagonal. A line alone does not tell you which body crossed the centre, how quickly, or whether it came back. Run them again. Movement gives the shared line different histories.

Now reveal **ARROWS**. Sixty-three samples point inward across the floor. Their lengths diminish toward the centre, where the rule returns zero. Each moving body asks this same rule for a value at its own current position. The arrows are places where we have sampled the rule for you; a body can also ask between them.

In Motion, a pulse ended while its acquired velocity remained. Pink carries that possibility into a field. The next contribution depends on where it arrives. Near the centre the contribution shrinks, but the velocity it has already acquired is still present. Past the centre the field points back. It takes time to turn that velocity around.

Cyan receives the sample differently. It uses the current field value as its velocity. As the arrows shorten, its speed decreases directly. It has a position and a history of positions, but the next velocity replaces the previous one.

Press **RULE**. The first receiver performs this assignment:

```gdscript
velocities[i] = sample
```

The other adds a contribution over one model step:

```gdscript
velocities[i] += sample * STEP
```

Both then move:

```gdscript
positions[i] += velocities[i] * STEP
```

An equals sign and a plus-equals sign give the same spatial rule different consequences. The second line meets a velocity already there. The first supplies a new velocity each time.

This apparatus starts with dimensionless field values. Cyan interprets one field unit as one metre per second. Pink interprets one field unit as one metre per second squared. Those choices belong to the receivers. We cannot read a bare arrow and know whether it names a direction, a velocity, an acceleration or a force.

**FIELD** changes the inward rule to **SWIRL**. RESET, then RUN. The samples now point across the radius rather than along it. Cyan follows the turning directions. Pink adds those directions to its existing velocity. Look for the growing difference between their paths. A field drawn with circular symmetry does not, by itself, promise every body a circular orbit.

The next FIELD setting is **UNIFORM**. Every address returns the same value. Reset and compare the first second: at gain one, cyan travels about 0.8 metres. Pink, starting with zero velocity, travels about 0.4 metres and reaches about 0.8 metres per second. One travelled at the speed the other was still acquiring.

Try **REVERSE** during a run. The arrows reverse immediately. Does each body reverse with them? Cyan accepts the new velocity on its next update. Pink first receives an acceleration opposing the velocity it already has. Changing the rule does not erase that velocity.

GAIN cycles through 0.5, 1 and 1.5; field, gain and reverse edits keep the current state. For a comparison from the same beginning, RESET pauses both bodies at their starting address while keeping your chosen settings. RUN resumes the local experiment. The museum's clock is elsewhere, continuing.

At the gold perimeter a marker may stop. This apparatus has reached the edge of the comparison and freezes that receiver, retaining its outgoing velocity as a readout. No wall bounced it and no friction slowed it. Reset to begin another run. In the previous chamber a boundary computed a collision; here a boundary ends an observation. The line on the floor cannot tell us that difference without the implementation.

The markers pass through furniture and through your position. Their different heights are display offsets: both calculations take place in X and Z. We are standing inside a representation, with access to controls that change it. These controls do not push the player's body. That would require another receiver, with its own movement rules and limits.

The model advances in steps of one hundred and twentieth of a second. Its traces keep 240 samples at ten samples per model second. The fixed steps make comparisons repeatable across ordinary display rates; they do not make a numerical curve exact. Even cyan's circular path can drift slightly as straight steps approximate a turn. Long stalls advance at most a quarter of a model second per update, so the experiment can fall behind wall time.

We have chosen what to keep: a position, a velocity for each body, and a short history for drawing. We have also chosen how to receive the next sample. The difference between these two bodies is something we can locate in code, change, and watch unfold.

Beyond this opening, the earlier field, weather and motion exhibits remain. Read their mechanisms against this comparison. A wind arrow may drive a visual instrument, a particle update or a physical response. Similar arrows do not guarantee the same operation.

<!-- @ -->

Next are kinetic forces. Carry two questions into the room: what does this vector measure, and what does the receiving body do with it?



## Vectors_Act4a_KineticForces

Source: commons/maps/Vectors_Act4a_KineticForces/final.md

SHA256: 1f75c3d61f6b2dcc31fafd50e30f7bc88d080b25fc6b2da93c52afba70f0fc76

# The return is not an undo

<!-- @drag_corridor -->

Three strips cross the floor. AIR, WATER, HONEY. Each holds a cube, waiting at the same starting X coordinate. The controls stand before the passage between them.

Press **FIRE**. All three leave at four metres per second. Watch which one gives up distance first.

Honey barely carries its cube. Water lets another travel farther. Air is still letting go of its launch. These names suggest substances, but no liquid is being simulated here. Each strip supplies a different coefficient to the same rule.

Press **PARTS**. Pink arrows point against the movement. Their lengths shrink as the cubes slow. The influence changes with the state of the body it acts on: less velocity, less opposing force.

In the previous hall, one receiver replaced velocity and another accumulated acceleration. Here the receiver is a rigid body. **RULE** reveals the request sent to the physics engine on each update:

```gdscript
body.apply_central_force(-COEFFICIENTS[i] * body.linear_velocity)
```

A minus sign makes the force oppose velocity. The coefficient has units of kilograms per second; multiplied by metres per second, it gives newtons. The three values are 0.4, 1.3 and 3.2. They are chosen for this comparison, not measured properties of air, water or honey.

The opening mass is one kilogram. Increase **MASS** to two, then FIRE again. The same resistance now changes velocity more slowly. The force at a given speed has not doubled to match the body. Dividing by the greater mass produces a smaller acceleration.

MASS cycles through one, two and four kilograms, returning the probes to their starting positions and holding them there. FIRE begins another equal-speed comparison. A strip keeps its own coefficient throughout the flight, even when its cube passes through the glass boundary of the walking passage. The glass divides another kind of encounter.

Turn on **WALK**, then go through the centre: air, water, honey. The same desktop movement command carries you progressively less quickly. XR stick movement uses the same adaptation. Step outside the narrow passage and ordinary movement returns. The effect is optional; WALK begins off.

Your controller is a different receiver. Its requested walking speed is multiplied by approximately 0.71, 0.43 or 0.24. That mapping is chosen to make resistance apparent; it does not integrate the cube's drag force through your body. In a headset, the program can slow a stick request. It cannot make your physical legs walk more slowly through the room you are standing in.

One visible medium contains two implementations. The fact that both seem slower is a beginning for comparison, not proof that they share a mechanism.

The cubes ignore furniture and the visitor. Gravity and inherited damping are removed. If a cube reaches the end of its eight-metre observation window, the apparatus freezes it and labels FRAME EXIT. It has reached the limit of what we are watching, not a wall that did work to stop it. The displayed velocity remains its outgoing value.

<!-- @force_mower -->

Farther into the hall, grass stands around a mower. Take hold of it and push it forward. A strip is cut, the wheels turn, and the path counter increases.

Now bring it back without turning it around.

The signed work reading comes back toward its earlier value. The grass does not grow back. The path counter has kept both parts of the journey.

Look at the distinction before asking which number tells the truth. Each is keeping a different account. Path adds the lengths of the movements. Signed work uses a chosen force and the direction of each displacement. The lawn changes when the cutting deck passes close enough to a blade. None of those records contains the others in full.

The mower's drawn force is nominal: a selected value pointing forward and down its handle. The controller is carrying the mower; we are not measuring how hard your hand pushes. The readout now says so. It accumulates:

```gdscript
_work += nominal_force.dot(disp)
```

Forward movement contributes positively. Backward movement with the same orientation contributes negatively. Sideways movement contributes zero to this nominal horizontal force component, even though it adds to the path length and may take the deck across more grass.

Keep the mower facing the same way for that return comparison. Turn it around before returning and you have turned the nominal force too: another experiment, with a different account of work.

The downward component contributes no work along a level displacement. That does not make downward force universally useless. In a fuller contact model it could change the normal force and friction. This mower's annotation has left those interactions out. Its handle angle is configured in the artifact; raising your hand does not adjust that parameter, because the grab is constrained to keep the mower upright and on its ground plane.

The cut lawn is a small remainder that the return journey cannot cancel. Zero net nominal work has not meant that nothing happened. Nor is the work reading a complete energy budget for cutting grass. A body can return to an address while leaving changes there that another register has forgotten.

<!-- @centrifuge_ring -->

At the ring, a pod follows a circle. Stand beside the controls outside the circle and watch it pass. Press **SPEED** to go from two to four metres per second.

The velocity arrow doubles. The inward acceleration arrow grows fourfold.

At six metres per second the contrast grows again. The radius stays at 3.4 metres. More speed demands more change of direction during each second if the pod is to remain on that circle.

The ring now uses the same speed for its movement and its readout:

```gdscript
_omega = lerpf(2.0, 9.0, speed) / radius
```

Angular speed is linear speed divided by radius. The inward acceleration required for the circle is speed squared divided by radius. At two metres per second it is about 1.18 metres per second squared; at four, about 4.71.

The arrows remain perpendicular: one tangent to the circle, one inward. An acceleration can change direction while leaving speed constant. That is a different possibility from the drag arrow opposing the direction of travel.

But look at what this particular machine does. The pod is placed along a prescribed circular path. The inward arrow reports the acceleration that path requires; it is not a simulated force holding a free rigid body in orbit. The ring does not pull the visitor inward. SPEED keeps the pod's current phase when changing its pace, so the experiment continues from where you intervened.

We have met a force applied to a body, a force chosen for a work annotation, and an acceleration calculated from a prescribed path. The visual argument becomes useful when those differences can be examined. An arrow needs units, a receiver, and an account of how it entered the movement.

<!-- @ -->

Next, oscillation and balance. What happens when the restoring influence changes sign as a body crosses its resting place, and the accumulated motion carries it across once more?



## Vectors_Act4b_Oscillation

Source: commons/maps/Vectors_Act4b_Oscillation/final.md

SHA256: dcb13eabab91ba35a0de3d52cd293dd61d276ac6070130d77da7cf7a0bb93cd0

# Coming back takes you through

<!-- @spring_tower -->

A cube waits to one side of a line. A coil connects it to the frame. The line continues across the floor, where your feet can find it too.

Press **RELEASE**. The cube moves towards the line. Watch what happens when it arrives.

It goes through.

The spring has brought it back to a place where the spring's own force is zero. It has not brought it to rest. The movement gathered on the way still belongs to the body. Beyond the line the coil begins to oppose that movement, slows it, and brings it back from the other side.

Press **RESET**. The cube waits at its opening position again. **PULL** offers other starting displacements, or you can take the cube and move it yourself. Your hand can move in three dimensions; the handle keeps only the horizontal part, limited to one and a half metres on either side. Letting go starts from rest. This experiment deliberately leaves out the speed of your throw.

That is already a choice about the body we are making. A release could carry your hand's velocity into the next movement. Here it carries a position, while velocity begins at zero. Compare two releases before choosing which would be useful for another machine.

Try **DAMP** once, from FREE to LIGHT. RESET and RELEASE give it the same beginning. The cube still crosses the line, but its excursions shrink.

Now reveal **PARTS**. The cyan spring arrow points towards the resting place. The orange damping arrow points against the current velocity. On the way in, the arrows oppose one another. After the cube crosses the line, both can point back against its continuing journey. The gold arrow is their sum. The wall shows the same three signed forces, at the same scale, without following the cube.

The drag rule from the previous room has joined another rule:

```gdscript
var force: float = -stiffness * displacement - damping_coefficient() * velocity
velocity += (force / mass_value) * STEP
displacement += velocity * STEP
```

**RULE** brings those updates onto the wall. One term asks where the body is relative to rest. The other asks how it is moving. Divide their sum by mass and acceleration appears; add its contribution to velocity, then use the new velocity to change position.

The cube does not consult a cosine to find its next address. This one-dimensional model computes the next state from the current one, at 120 steps per model second. Its pickable cube displays that state. It is not a second, freely colliding physics body, and its coil does not push the visitor. The rail assumes vertical support; gravity and contact friction have been left out.

The opening mass is two kilograms and the spring stiffness is eight newtons per metre. With damping off, RESET and RELEASE, then compare a heavier **MASS** from the same start. It takes longer to cross the line. Return to two kilograms and increase **SPRING**: a stiffer spring brings it through sooner. The buttons cycle through one, two and four kilograms, and four, eight and sixteen newtons per metre.

Changing those values during motion keeps position and velocity. It does not promise to keep energy. Stiffening a stretched spring changes the energy attributed to that state; replacing mass while keeping velocity does too. The edit is an intervention in the apparatus, not a free transformation of an isolated system.

Continue through the DAMP settings. At CRITICAL, release from rest on one side and watch it approach without crossing. At HEAVY, it also approaches without crossing, but more slowly. Extra resistance has delayed the return. Try the comparison from the same displacement: the setting that removes movement most strongly need not bring the body to its resting place soonest.

Those names are tied to the chosen mass and stiffness. The damping coefficient is computed from a ratio:

```gdscript
return 2.0 * RATIOS[damping_index] * sqrt(stiffness * mass_value)
```

FREE, LIGHT, CRITICAL and HEAVY use ratios of zero, a quarter, one and two and a half. Changing mass or stiffness changes the coefficient required to keep that ratio. The names describe this linear, undriven model; the return we compared begins from rest. They do not prescribe a good rhythm for every body.

The word *restoring* gives a direction a purpose. Back to what? Here there is a visible line and an explicit displacement measured from it. We can inspect the chosen centre. A system that calls its preferred state normal may make its reference harder to see. The useful question is not whether returning is always desirable. It is which differences the apparatus returns, which it damps, and which it never allowed to enter.

The hand's sideways travel was discarded. Its throwing speed was discarded. The cube's horizontal velocity, once released, is precisely what lets it pass through the place it was being brought back to. What was excluded and what was retained both helped make this body possible.

There are further limits. A long computer stall advances at most a quarter of a model second on the next update. If an intervention sends the cube outside the observation frame, beyond 2.25 metres of displacement, FRAME EXIT holds its outgoing state. No imaginary collision is supplied to make the frame seem like a wall. And the finite update can introduce numerical error even when damping is off. The recurring movement is something to examine, not a promise of perfect repetition.

Other balances, springs and pendulums remain farther into this hall. A similar swing may be prescribed directly from time; the older tall pendulum does exactly that. Looking alike does not establish the same mechanism. The question follows you from one apparatus to the next.

<!-- @ -->

We will return to oscillation in Wavefunctions. There a pendulum leaves a history we can walk beside, and returning motion becomes material for sampling, phase, spatial patterns and sound. Here we have established a smaller thing to carry: a force can bring a body back without telling it to stop there.

Next, the timing machines. What happens when several returning movements share a clock, or begin to fall out of step?



## Change_Choreography

Source: commons/maps/Change_Choreography/final.md

SHA256: 3880bc0f41e1893357a482995b5477eddf08e3f74d7fc8bdf1d6560684cf9fd6

# Together, out of time

Can twenty repetitions make something that none of them does alone?

We have met oscillation: a movement returns. In Change we measured a rate and gathered contributions. Bring those ideas into a room where several processes continue at once. Before asking whether the room is working, choose what you expect it to do.

<!-- @phase_rod_array -->

Twenty light rods turn above their small square bases. Each has a white tip, so you can follow a full turn without confusing one end with the other. Begin by watching one. Then let your attention spread across a row.

Press **ONE +**. Rod ten moves a little ahead. The other nineteen continue their agreement. Press it again. Is this rod late, early, or simply somewhere else in its own cycle? You need another clock before those words can mean anything.

Each press adds forty-five degrees to that rod's phase. It keeps the same six-second period. The difference is an offset, not a growing delay.

Now press **WAVE**. Follow the five columns. A pattern travels across the array while every rod remains attached to its own base. Adjacent columns differ by one fifth of a turn; the four rows repeat that relation. None of these little machines travels across the stage. What you see travelling is a relationship between them.

Only now press **RULE**.

```gdscript
angle = TAU * frequency * time + phase
```

Frequency counts turns per second. `TAU` converts a turn into radians. Time advances the angle; phase places a rotor within its cycle. The array is indexed as four rows of five, carrying forward the addresses we learned to give a grid.

Press **DRIFT**. The back two rows now run four percent faster than the front two. A difference in frequency keeps changing the difference in phase. Watch agreement loosen. The rows need 150 seconds to gain one complete turn on each other and realign. Their clock was already running before you pressed the button, so this is an interval between alignments, not a countdown promised from your press.

These buttons select configurations immediately; a rod may jump to its new angle. After that change, watch the continuing motion. **RESET** restores common phase and frequency while the elapsed clock keeps advancing.

<!-- @ -->

The wave needed difference. Making every rod agree would destroy that particular pattern. Being out of phase becomes a fault only in relation to something we demand: meet here, leave an opening, arrive together. What other movement could your body make alongside this one?

These rods are driven by an angle formula. They do not keep time because a restoring force pulls them back. A spring and a scripted rotor may repeat, but the repetition has different causes. The resemblance is a place to begin investigating.

<!-- @conveyor_backlog -->

Walk to the conveyor. A parcel drops onto the belt, travels toward its end and reaches the collection tray. The receiver flashes when it collects a box. Follow a single parcel before reading the numbers.

The inlet attempts a delivery every 1.2 seconds. The matched receiver can collect one arrived parcel every 1.2 seconds. There will still be boxes on the belt: transport takes time. An occupied machine is not necessarily a congested one.

Press **BACK UP**. The inlet keeps its interval; the receiver now collects at most one box every three seconds. Wait. Which change becomes visible first: a longer stay in the tray, a neighbouring box touching it, or a parcel losing its straight route?

The parcels have rigid bodies. Friction carries them across a moving collision surface. Gravity and contacts determine how they fall, tilt and press against each other. The sculpture at the end is not a mesh that grows because we asked for a larger sculpture. Its shape is made by the deliveries that have not yet left.

Press **RULE** and compare the account with the pile.

```gdscript
here = admitted - collected
```

The receiver only collects a parcel that has physically reached its end of the machine. Its schedule cannot collect a promise. If the inlet is occupied, admission waits. At forty-eight live parcels the feed also waits, and the console says so. That finite capacity belongs to this implementation; the model does not hide extra boxes by deleting them.

Now press **RECOVER**. The receiver can collect one arrived box every 0.6 seconds. Existing boxes must still reach it. Watch the heap change before calling the repair complete. Increasing the collection rate and erasing the history are different operations.

**RESET** clears this local parcel experiment and restores matched intervals. It does not rewind the museum's elapsed time.

<!-- @ -->

Every box followed the same admission rule. Every collection followed the same receiver rule. A difference between their intervals nevertheless changed the space. What counted as a successful delivery upstream became somebody else's obstruction downstream.

There is comedy in anticipating a clean handover and watching a parcel arrive at the wrong moment. There is also another form appearing in the interruption. For whom is the heap only waste? What would have to change for it to become a shelter, a route, a body worth keeping?

We have made those questions available; this first machine does not yet let you carry away its boxes or climb its heap as a designed route. Carry the distinction forward: a parameter can change a pattern, but the permissions of the body still need to be built.



## VFM_07_Gravity

Source: commons/maps/VFM_07_Gravity/final.md

SHA256: f6366b3978bf7db77d121824816887d9454bf419642b57376c8ba1b4879b1b7e

# Who gets to stay still?

<!-- @orbital_mechanics_demo -->

The spring had an address to return to. You could move its body through that address without moving the address itself. Here the reference has acquired a body: a pink sphere, apparently untroubled by the small gold one waiting beside it.

Press RUN. Let the gold body go round. Then change SPEED and start again. The attraction has not changed; something about the beginning has. A circle narrows into a closer passage, or opens toward the golden frame. Which part of the path did the starting speed decide? Which part is being decided now?

Walk into the drawing. The spheres pass through you. You are inside its spatial explanation, but you have not become one of its masses. Already the room contains two kinds of body.

Reveal PARTS. The arrow on the satellite points toward the source even when the satellite travels across that direction. Motion keeps what the previous moments gave it; acceleration changes what comes next. The turn is made again at every step.

```gdscript
var arm: Vector3 = state.p[j] - state.p[i]
var pair_force: Vector3 = G * masses[i] * masses[j] * arm / pow(arm.length_squared() + EPS * EPS, 1.5)
```

The subtraction we learned as a gap now gives an interaction its direction. Distance also enters its strength. This room chooses G = 1, a source of 12 kg and a satellite of 1 kg. At three metres, the opening sideways speed is calculated for a circular orbit under this particular softened law. SPEED offers four multiples of that beginning. It does not push the current body; it prepares another run.

Try REVERSE while the satellite is moving. Its velocity changes sign, its position stays, and the clock continues forward. In this isolated model it can retrace the path it has just made. The earlier spring with damping could not offer the same experiment merely by reversing velocity: resistance would keep dissipating motion. A return depends on what the update preserves.

Look again at the pink body. Why has it not moved?

```gdscript
if mutual or i!=0:a[i] += pair_force / masses[i]
if mutual or j!=0:a[j] -= pair_force / masses[j]
```

Here `mutual` is false and body zero receives no acceleration. The source is held in place by the implementation. Its stillness is useful: it lets us learn one moving body's relation to a fixed reference. It also withholds a response. What happens if the thing we called the centre is allowed to answer?

<!-- @three_body_problem -->

The next floor begins with two equal masses. Press RUN before adding anything. Both move. Neither has the privilege the pink source had. A small white cross marks their centre of mass; it can remain still while the two bodies travel around it. A reference need not be occupied.

Now press BODIES. Time returns to zero and a third body waits above the pair in the floor plan. The original two keep their starting positions and velocities; the newcomer starts at rest. Run again. Follow one of the original paths. Where does it first cease to be the path you expected?

No new instruction says “be complicated.” Each pair contributes the same softened attraction, with an equal and opposite force on its partner. All three masses are 4 kg. The arrangement has changed, so the forces summed at each body change. The original pair's circular beginning is no longer a promise about its future.

```gdscript
var a=accelerations(state)
for i in state.p.size():
    state.v[i] += a[i] * (STEP * 0.5)
    state.p[i] += state.v[i] * STEP
a=accelerations(state)
for i in state.p.size():state.v[i] += a[i] * (STEP * 0.5)
```

A little change of velocity. A step in position. Read every relation again. Another little change of velocity. The code advances all bodies through these shared stages, 240 times per model second.

NUDGE prepares a second beginning. Only the last body's X coordinate changes, by three centimetres on the first press. Velocities remain identical. The translucent bodies belong to that second calculation; they are drawn higher so we can distinguish the copies, although both calculations stay in the X–Z plane. They do not attract the solid bodies below them.

Watch a corresponding pair, then read the displayed difference. It combines the distances between corresponding bodies as a root mean square. In the checked three-body run, three centimetres added to one initial coordinate gave about 7.6 centimetres of this paired difference after four seconds. Reset and compare again. This is a measured departure under specified conditions. A tangled trail alone would not establish chaos, and this short comparison does not establish an exponential rate of separation.

There are two white crosses now. Moving that one initial coordinate also moved its copy's centre of mass. We did not secretly recentre it. Even an experiment about difference has to decide which differences it will retain.

Return to `EPS * EPS`. The quarter-metre softening keeps close encounters finite by changing the attraction near coincidence. The visible spheres have no hard surfaces in this calculation: they neither collide nor merge. Their glow suggests bodies with skins; the rule offers positions and masses. What kind of encounter could we make by adding a skin?

The floor keeps at most 240 samples for each trail, taken twenty times a second: roughly twelve seconds of visible past. Hiding PATH does not stop this recording. Large acceleration arrows stop growing at two metres, while the numerical acceleration continues beyond that drawing limit. At the golden frame the whole experiment pauses with its outgoing state intact. The edge says our observation has ended; it does not prove that a body has escaped its partners.

We have allowed the centre to move and the third body to alter a relation already underway. Your feet, meanwhile, have remained on the museum floor. Gravity in the next encounter will need an answer from the ground. What lets a body stand?



## VFM_09_Legs

Source: commons/maps/VFM_09_Legs/final.md

SHA256: cf1c2f5112ca51a2d82126f5e83c24c508a39e760ce0db60bbd0dcdc02674018

# What lets a body stand?

<!-- @support_polygon_lab -->

In Gravity, the bodies passed through one another. A surface appeared in the light, but the calculation gave it no skin. This pink plate meets something different: four narrow posts, offering places where falling can be interrupted.

It is waiting. Press RELEASE. Almost nothing happens. That almost is worth watching: the plate drops the small distance to the supports, and they answer. Staying still is now an outcome of contact.

Press FEET once. One post disappears and the plate returns to its held beginning. Before releasing it, choose where you think it will go. SHIFT moves the load toward one corner; another press moves it toward the opposite corner. Compare those two releases with the same three supports. The missing post has not returned. Why can one beginning stay level?

Reveal PARTS. A gold marker shows the mass centre through the plate, and a line projects it onto the floor. The outline joins the outer edges of the available support pads. The wall carries that same initial footprint and the live projection of the mass centre. You can walk around the plate and still keep the relation in view.

```gdscript
hull=Geometry2D.convex_hull(corners)
```

The corners belong to the little squares at the tops of the posts. Their convex hull is the smallest convex outline enclosing them. With the load initially level, gravity vertical and the supports horizontal, the position of the projected mass centre tells us whether these upward contact forces can balance its weight without a tipping moment. Inside gives room to distribute the support. Outside asks the posts to provide something they cannot: a downward pull from a place where there is no fastening.

SHIFT changes the rigid body's custom centre of mass. Its silhouette remains the same. The gold mark moves because the simulation has changed where its ten kilograms are represented as acting. A body can become different without acquiring a different outline.

This is a deliberately sparse body: one rigid plate, a chosen inertia tensor, one mass centre. The fixed inertia stays the same across SHIFT. We are isolating a change of load position, not rebuilding a detailed internal distribution of matter. Its empty-looking interior is full of decisions.

Try FEET again. Two neighbouring posts remain. Try the next arrangement: two opposite posts. Same count, different relation. The diagonal pair leaves a very narrow region around the centre. Move the load out of it.

A foot is not necessarily a point. Each pad here is sixteen centimetres wide. Replace the pads by ideal points and the diagonal region contracts to a line: no room for a sideways displacement. On its boundary, balance would be marginal, not automatically a fall. Our earlier habit of counting points has left something out. Width can change what that count permits.

The right-hand display names its number **initial support margin**. Positive means the opening mass projection lies inside the footprint; negative means outside. After release, the plate can tilt, lose contacts and find new ones. The outline does not pretend to follow those changing contacts. It preserves the prediction beside what actually happens.

```gdscript
body.freeze=false
body.sleeping=false
```

Those are the small instructions that release the plate. The engine then integrates gravity and resolves collisions. We have not written its falling path. The museum floor and your body occupy a separate collision arrangement: you can inspect this experiment, but walking into the plate does not push it. Yet another permission deciding which bodies can meet.

<!-- @four_leg_critter -->

Beyond the table, seven creatures are already walking. Find the one with four legs. Follow a foot while the body travels past it. For a while the foot stays where it was planted. Then it swings through the air and lands ahead.

It looks like an answer to the table's problem. What happens to its support when that foot lifts?

This walker selects the planted foot furthest beyond its distance threshold, provided no other foot is already stepping. It moves one foot at a time. Four legs have not forced it into a trot; a branch in the program has chosen this sequence.

```gdscript
var smooth_t: float = t * t * (3.0 - 2.0 * t)
pos = _leg_step_from[leg_index].lerp(_leg_step_to[leg_index], smooth_t)
var arc: float = 4.0 * t * (1.0 - t)
pos.y += step_height * arc
```

The curve we met as a pattern over time now lifts a foot target. The joint chain reaches toward that target. This is useful work: it makes the planted interval and the swing legible. But reaching the ground and receiving support from it are different operations.

The body itself is a mesh whose position is advanced by the patrol code. Its gait does not ask the support hull for permission, and gravity does not tip this body when the answer would be no. The creature keeps going. The plate had to negotiate its stillness with contact; this walker has been granted movement directly.

Look along the row. One leg, two, three, four, five, six, eight. These are related constructions with different rigs and stepping rules, not a proof that a count dictates a way of living. The row is now a set of questions we can bring back to the table. Which feet are planted? How broad is a foot? Where is the load? Is the body trying to remain still, or carrying momentum into another step?

The gap between a persuasive walk and a supported body is material for another experiment. We could give a creature wider feet, a shifting load, a tail that can touch the ground, or a controller that catches a fall. Each addition would change what bodies this little world can sustain. It would also ask for new code and a new test.

The Arena is ahead. There, a moving body will share space with yours. We carry a more exact question into that encounter: which of its actions come from forces, which from a controller, and which relations to you has the world actually implemented?



## VFM_08_Arena

Source: commons/maps/VFM_08_Arena/final.md

SHA256: 0b474626dc1121778ac9837c9b76ee44d1ea52501bb19ce34de3be59e8753cea

# What makes an encounter?

<!-- @arena_relation_lab -->

The four-legged walker has acquired a small dark body. A familiar shape, perhaps already carrying the expectation that it will jump at you. Before it moves, notice what you have brought into the room with it.

Press RUN. The creature heads toward the blue beacon. Move BEACON to one side. Offer FOOD. Something about the same animal's direction changes. Nothing in its legs has been replaced.

Follow it to the mushroom. It pauses over the food and lowers its body. Wait. The pause belongs to the action: arriving is not yet having eaten. After two seconds, the meal is completed and the animal can move again. What does it go toward now?

This encounter considers two candidates: its own offered mushroom and one nominated visitor. At the beginning, that visitor is the beacon. Press VISITOR to take its place yourself. The board says YOU. Walk closer, or let the food be closer. You and the mushroom now enter the same comparison.

There is no bite in this version. That changes what you can risk while looking, without changing the question of how a target becomes a target. The other crabs retained deeper in the Arena have their own configurations; the panel controls this one experiment.

Now bring up SCREEN. A wall appears between the opening positions of the creature and the central beacon. The beacon has not ceased to exist. Move it to the side, or move yourself until the line clears the wall. Which part of the world is available to this creature now?

Reveal PARTS. The candidate label and line expose a current selection, while the completed-meal count records something that has happened. The two numbers are doing different kinds of work.

```gdscript
if d<distance and _sees(candidate.global_position):
    best=candidate
    distance=d
    bait=candidate==station.food
```

The closest visible candidate within six metres wins. Food is not given a higher rank simply for being food. A nearer beacon can win instead. This is a scoped version of the existing crab's selection: one nominated visitor and this station's mushroom, rather than every eligible object in the museum. It has no sight memory. A blocked candidate cannot continue drawing it through a remembered target, although the inherited controller can briefly exclude a candidate it has failed to reach.

Look at the sight line again. The query runs horizontally, twenty centimetres above the floor. Candidate distance, however, uses the three-dimensional positions of the nodes. Seeing and measuring do not even use quite the same world. The golden line on our floor is a display of selection, not a camera image from the creature's eyes.

A meal holds its attention for two seconds once feeding begins. Moving another candidate during that interval does not interrupt the meal. Offer another mushroom after the first is gone. The counter rises. At five completed meals, the creature stops moving.

```gdscript
_rooted = true
can_bite = false
_target = null
_lunge_t = 0.0
patrol_speed = 0.0
chase_speed = 0.0
```

There is a name in the source for this state: rooted. It does not currently grow branches. The same body remains, with a different set of actions available to it. Five is a threshold somebody chose; feeding has changed state, not trained a new policy. How quickly might we have called this trust, taming, exhaustion, or friendship if the counter and the code had stayed hidden?

That gap can hold an artistic question without being passed off as evidence. What relation do you feel when the creature approaches? What changes when it leaves you for something else? We can alter the conditions of that encounter and watch our own interpretation arrive beside its implementation.

RESET replaces this animal with an unfed one and keeps the panel choices. It is a new experimental beginning, not the creature forgetting its meals. RUN can pause this creature's controller, including a meal. The food's brief appearance and disappearance animations use their own clock; the rest of the museum continues. The golden perimeter pauses observation if the animal leaves the central area; it does not imprison it with a physical collision.

As in Legs, its movement is a commanded position change. The feet plant and swing, and the controller uses obstacle queries to limit steps. There is no integrated body momentum to conserve. The next exhibit asks what an encounter would have to share if that conservation were part of its rule.

## What the collision shares

If momentum is conserved, why can two collisions look so different?

<!-- @collision_carts -->

The carts are shown twice: before the encounter on the upper track and after it on the lower one. Find the striker’s incoming arrow in the first view and look for its outgoing arrow in the second. Move MASS RATIO and follow what happens to that arrow before worrying about the formula.

For a light striker, it points back. Near equal masses, the striker's outgoing arrow disappears while the other cart takes the motion forward. With a heavier striker, both outgoing arrows can point in the original direction. The control changes the comparison; these are diagrams of possible outcomes rather than carts repeatedly colliding in front of you.

Keep one mass setting while comparing the upper and lower tracks. Identify the striker by its colour and width, not merely by which cart has the longer arrow. Check that you are comparing the same body before and after. Then follow the other cart across the two views. Its initial lack of an arrow and its later forward arrow belong to one change, while the striker's change belongs to another. Describe both before saying that motion was lost. As you adjust the mass ratio, watch the striker's width too: the control changes the body's represented mass as well as the resulting velocity arrows.

Momentum combines mass with velocity, including its direction. A small body moving quickly and a large body moving slowly can contribute comparable amounts. Conservation constrains the total across the two bodies. It does not require each body to keep its own speed, or even its original direction.

The diagram assumes an isolated, elastic collision along one line. Its target starts at rest, and the striker's initial speed stays fixed. Those conditions matter. Two carts that stick together would answer a different collision rule, even though total momentum could still be conserved. The control here changes mass ratio; it does not offer a choice between bouncing and sticking.

Predict which way the striker will leave before crossing the equal-mass setting. Then ask a different question: which cart would be easier to catch afterwards? The quantity the model preserves and the consequence a visitor cares about need not be the same thing. Even the arrows require care: they are drawn for legibility, so their physical lengths are not a precision measuring instrument.

<!-- @ -->

The next room considers force as a place. Bring the habit of looking at the whole relationship before judging an outcome from one body's motion.



## Vectors_Act5_ForceAsPlace

Source: commons/maps/Vectors_Act5_ForceAsPlace/final.md

SHA256: ff6d2e1ec8c762288533299a11d60412c4a3b1a2cafb7ca71341efe3e52c8142

A hole in the floor, and two ways over it. One of them somebody built. The other one you have to set.

The crab in the previous room needed a rule for finding its next encounter. The collision carts needed an account of what the encounter preserved. Bring both questions here. What will this place recognise when you enter it, and what motion will you bring?

## A direction waiting

<!-- @vector_machine -->

The machine stands before the gap. Three sliders: PITCH, YAW, ACCEL. Before trying to cross, move YAW while the field points straight down. Watch the large arrow and the faint horizontal one. Which has heard you?

It opens at an acceleration of 9.8 metres per second squared, downward. That resembles ordinary falling, but the field supplies that value locally. Down is a setting you can change here.

Now watch what the steepness slider costs. At the bottom of its travel the field points straight down, `cos(pitch)` is zero, and the slider beside it does nothing at all. Run it through its whole range and the world will not move. Lift the field off the floor by even a little and the same slider becomes the most powerful control on the console.

That is not a fault, it is what a direction *is* when you name it with two angles. At the poles the second angle has nothing left to mean. So the console tells you: while the field is vertical the readout says the yaw is idle and at what bearing it is waiting, and a faint arrow on the stage holds that bearing where you can see it. The fader is not dead. It is aimed, and the field cannot hear it yet.

It is the oldest problem in spherical coordinates, and here it is at hand height, in metal, where you can feel it happen.


The two angles become a direction. Magnitude gives it a size:

```gdscript
# vector_machine.gd — world coordinates; yaw zero points along +Z
return Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * mag
```

The last slider stops at fifteen. Aim partly upward and along the hall. Read the components before leaving the bench: positive Z leads toward the far side. The machine speaks only to this hall's field. A dial elsewhere in the museum cannot quietly rewrite your crossing.

## Something in the way

<!-- @force_cube -->

Three glass cubes wait near the machine. Take one and move it slowly. Stop your hand. Its motion arrow should disappear; a body at rest need not invent a direction merely to remain a useful exhibit.

Release it into the volume and watch before following. Aim down, then repeat with the field tilted up and forward. Your release matters too. The field changes a velocity that has already begun.

The cube differences its current position against the previous frame:

```gdscript
# force_cube.gd — the visible arrow follows sampled movement
var vel: Vector3 = (global_position - _last_pos) / maxf(delta, 0.0001)
_last_pos = global_position
var f_world: Vector3 = (vel * 0.5).limit_length(2.6)
```

The name `f_world` has survived from an earlier account of this object. The quantity is a motion arrow. It shows half a metre for each metre per second, with its length capped at 2.6 metres. A fast throw can outrun what that length can tell you. The coloured legs decompose the drawing in the cube's own axes; turn the cube and those axes turn with it.

The arrow arrives after the movement. It cannot tell you, on its own, how much came from your hand, the field, damping or a collision. Even this small instrument has a past it cannot separate for you.

The probe has ordinary gravity outside the field and damping that slows its motion. If it falls four metres below its starting height, it returns there and waits frozen for another pickup. Returning is a recovery rule, not the field bringing it home. A cube resting in the basin may still need to be fetched.

## Enter the sentence

<!-- @force_field_zone -->

Five metres of air, marked by a cage. The thin edges are visible; they are not walls. A solid plank remains through the gap. Look along it, then into the air beside it. What would have to change for both to carry you?

With the field tilted up and forward, enter its near face from the plank. The field takes over locomotion inside. Your incoming velocity is retained, acceleration is added each physics step, and collision can still stop or deflect that movement. Ordinary keyboard or stick steering resumes when your feet leave the volume. Physical tracked movement remains possible in VR; this is a controller handoff, not a force applied to your muscles.

For a released cube, the central operation is short:

```gdscript
# force_field_zone.gd — remembered gravity is restored on exit
rb.gravity_scale = 0.0
rb.linear_velocity += f * delta
```

The missing division matters. This field gives an acceleration directly. It never divides a force by the receiver's mass. A one-kilogram body and a four-kilogram body receive the same velocity increment. They can still meet different contacts or have different damping. Equal instruction does not promise equal journeys.

The visitor's controller carries its velocity through a separate receiver:

```gdscript
# carry_velocity — incoming on entry, post-collision velocity thereafter
return Vector3(_carry.get(body.get_instance_id(), incoming)) + field_vector * delta
```

Set ACCEL to zero before another crossing. Enter with some motion. Zero has removed the new contribution; it has not removed what you brought. The loose cube slows through its damping. This visitor receiver does not add that damping. The same empty-looking volume holds two different accounts of persistence.

The boundary is another decision. The cube is detected by overlapping its physical body with an area; the visitor is admitted by a test of the body's position near its feet. Their entries need not happen at the same instant. At the far face, the desktop walker returns horizontal movement to its ordinary input controller and keeps its vertical velocity under ordinary gravity. That seam can be felt as a change in how you travel.

<!-- @ -->

## What the plank keeps

The plank originally repaired a promise the museum could not keep: a field drew its arrows, but the walker did not accept its acceleration. Writing the same vector into two objects had not made them the same kind of body. One controller erased what another had just written.

The repair belongs in the argument. Keep the plank. It gives you a way through while you investigate the other crossing, and it makes a comparison available: contact underneath, or a rule changing motion around you. Both depend on what the receiver can do.

The small free-vector display and the green invisible-hill diorama remain as side encounters. A vector can be drawn at another address without changing its components. A region can assign vectors to addresses and make paths bend. Between those two statements lies the work of this hall: admitting a body into a rule, retaining its history, and deciding where the rule stops.

What bodies are possible here? A carried visitor and a damped cube have become possible through related operations, implemented differently. The crab from the previous room would need its own receiver before this field could carry its commanded mesh. Shared code as a medium does not make that translation automatic. It gives us somewhere to work on it.

We leave with more than a new route across a hole. We have learned to look for the place where an instruction becomes a consequence. In the next sequence, Form Finding, that question reaches the shape of the world itself.



# formfinding

Declared order: FormFinding_Descent → FormFinding_Catenary → FormFinding_Relaxation → FormFinding_Equilibrium → FormFinding_Annealing → FormFinding_Forge


## FormFinding_Descent

Source: commons/maps/FormFinding_Descent/final.md

SHA256: c58b046d7db922054cee08dc7aaf4c429c9d188ab77cd4fd2900f5849d4b6c5b

# Where does downhill take you?

<!-- @descent_landscape_lab -->

The last room let a field carry you across a gap. You brought motion into it; the field changed that motion; something of the journey remained when you left. Here a gold point waits above a blue surface. There is no gap to jump. There is a button marked STEP.

Before pressing it, choose where you think the point will go.

One press leaves a short line behind. Another extends it. The number called cost changes. Try a few more presses before RUN. What repeats? What gets smaller? Does the point travel the same distance each time?

RUN lends the operation a rhythm. It repeats the same step, with a pause between updates so you can follow it. The pause helps us watch; it is not time inside the equation. Stop the run and take over with STEP again. The line remembers where the point has been, but that memory does not propel it.

This is already a departure from Forces. There is no stored velocity here.

## A direction without a destination

Press PARTS. The pink arrow offers a local direction. It lies horizontally, above the drawing; its length is capped at one metre. It does not point at a destination that the program has found elsewhere. The program has looked a little to either side of the current address.

In the x direction it asks how much cost changes between x minus 0.03 and x plus 0.03. It divides that difference by the distance between the samples. It does the same along z. Two comparisons make a vector: the sampled gradient. Its negative gives the direction the point will try.

Now reveal RULE. The moving point becomes a short instruction:

```gdscript
proposed = point - rate * gradient(point)
```

The subtraction is familiar. We have carried vectors, combined them and used them to cross space. Here subtraction changes an address in a search. RATE decides how far to trust the local direction. It does not name speed in metres per second. No mass is divided out; no acceleration is accumulated.

On the opening bowl, the cost is one quarter of x squared plus z squared. At the usual rate, the steps shrink as the point approaches the centre. The program does not need to know the centre's address to make those steps. We can see the whole bowl; the update uses nearby samples.

Eventually the display says SMALL SLOPE. Look at that wording before calling the run solved.

## Two beginnings

Switch SURFACE. The blue drawing now has two unequal valleys. Changing a setting starts a fresh run, so the next trail belongs to that setting alone. Keep RATE at 0.7 and STOP at 0.01. Run from the first START, note the final cost, then select the second START and repeat.

Both runs can stop at a small slope. They do not arrive at the same cost.

In the recorded desktop comparison, the first run finishes near -0.304 and the second near 0.295. The rule, tolerance and surface are shared. The beginning differs. One valley is lower, but the point in the other valley has no instruction to cross the intervening rise in search of it.

The surface makes this difference visible all at once. The moving point encounters it locally, one update at a time. You can walk around the plot and see the other valley. That knowledge has not entered the algorithm merely because it has entered your view.

What would have to change for the point to search there? Keep the question. Annealing will give us one way of approaching it later.

## How much is enough?

Try a looser STOP setting. A larger tolerance accepts a larger remaining slope. The run can finish earlier, at a different address and cost. Nothing in the surface has announced that this much unfinished movement is acceptable. We supplied that threshold.

Then return to the bowl and increase RATE. A downhill direction is a local statement; a long step can pass the useful part of it. Cost can rise. At the largest setting, a proposed step can leave the six-metre frame. The display says LEFT FRAME and keeps the last valid point. It does not silently push the point back against an edge and congratulate itself.

A third ending, STEP LIMIT, means the budget of 160 moves was spent. These endings answer different questions. Small slope describes a local measurement. Leaving the frame describes a boundary. Spending the budget describes how long we agreed to search.

Even a zero gradient would not by itself prove a global minimum. A maximum or a saddle can have one too. Here we can inspect the authored surface and compare runs. Elsewhere that overview may be unavailable.

## The surface we agreed to search

The plot is drawn with 48 by 48 cells, each split into two triangles. The gradient samples the cost function directly, at offsets of 0.03. It does not read the rendered triangles. What you see and what the point measures are related representations with different resolutions.

Its displayed height is another choice:

```gdscript
height = 0.40 + 0.22 * cost(point)
```

The height makes cost legible across a table. It is not gravitational potential energy, and the blue mesh is not a floor for your body to climb. The point's apparent descent comes from changing an address and drawing the result. Behind this experiment, the retained marble toy carries velocity and receives periodic programmed kicks. Its motion may resemble searching, but it uses another update. The resemblance gives us a comparison to investigate.

There is room for a different body in these small changes. One beginning inhabits a valley another beginning misses. A threshold admits one endpoint and rejects the next. Yet lowering cost only means improving according to the cost we wrote. Nothing in the arithmetic establishes that this measure contains everything worth keeping.

For now the landscape is authored and the point searches it. We have not yet let a connected shape emerge under load. In the next hall, hold two ends of a cable and let the space between them become the question. What can change when some things must remain fixed?

<!-- @ -->



## FormFinding_Catenary

Source: commons/maps/FormFinding_Catenary/final.md

SHA256: 49df26a33ccdf2fb45c3ecd4867312d51175748ca4bda4ac31e67a1c19e63f54

The least-cost curve is computed by its boundary, not drawn by a hand.

Two of the oldest solved minimisations in the world stand in this room. A hanging chain finds the catenary, the exact curve of least potential energy for a rope between two points. A soap film finds the minimal surface, the least area that can span a wire frame. Nobody drew either. They are computed, continuously, by matter obeying one instruction: spend the least. The last hall had a solver stepping toward an answer and trembling short of it. Here there is no solver at all, and the answer is exact.

```gdscript
@export var c: float = 0.5      # waist radius

var r: float = c * cosh(u / c)
var x: float = r * cos(v)
var y: float = r * sin(v)
var z: float = u
```

One function does both. `cosh` is the hanging chain, and a hanging chain spun about its axis is the soap film. The waist of the surface is where the chain is slackest, and the number that sets it, `c`, is the only parameter either shape has.

## The chain

<!-- @cable_builder -->

Four cyan beads at ankle height, and a four-metre cable glowing magenta into blue slung through them with its belly grazing the floor. The beads are the only thing in this room you can actually take hold of. Move one and the whole curve recomputes and re-skins in your hands, every frame.

Read it carefully, because it is the room's honest object. The cable is not a chain solving its own equation. It is a spline whose sag is two Bezier handles per span, each pulled down by a fixed fraction of that span's length, so the depth is drafted rather than found. It is a very good drawing of a catenary made by somebody who knew what one looks like, and the difference matters enormously here, because everything else in this room got its shape without anybody knowing in advance what the shape would be.

<!-- @laundry_line_cathedral -->

Three washing lines pegged with towels and shirts, and these are true `cosh` curves rather than good drawings. Only one of the three has a pole under either end; the other two simply begin and end in the air, which nothing in the room admits. Then look up. Above each line hangs its ghost: the same curve mirrored upward as a pale arch. That is Gaudí's trick, and it is the reason this is the hero of the room. He hung chains from a ceiling, photographed them, and turned the photograph upside down, because a chain in pure tension inverted is an arch in pure compression, and the curve that costs least to hang is the curve that costs least to stand. He let gravity do the drawing and then read the drawing the other way up.

<!-- @ -->

## The film

<!-- @catenoid -->

The chain, spun. A soap film between two rings makes this surface and no other, because surface tension is a cost per unit area and this is the least area that will reach both rings. It lies low and wide on the floor, a cyan wireframe hourglass about a metre and a fifth across and only a third of a metre tall, and it is the same `cosh` as the laundry line, revolved.

It looks as though you could pick it up, and you cannot. It is built as a physics body on the layer the world's static geometry uses, which is the one layer a hand is told to ignore, so it carries a collider that no grab will ever find. Three separate documents in this project say you can lift it.

<!-- @helicoid -->

In a slot between two pillars, the other one, and you will step over it before you notice it: a green wireframe corkscrew twenty centimetres across and a third of a metre high, six thousand triangles in a thing the size of a mug. A plane rotating as it rises, two full turns, three tenths of a turn's height gained per turn.

Apart from a flat plane, the helicoid and the catenoid are the only ruled minimal surfaces there are, and one bends continuously into the other without a single point of either ever stretching. They are the same film in two poses. Nothing in this room performs that bend. Both surfaces are computed once when the hall loads and then never touched again, so the deformation is a fact you are told and not a thing you can watch.

<!-- @science_screen -->

One thing in this room would draw a curve rather than be one, and it misses by sixty-six centimetres. The screen looks eight metres for a name it knows; the washing lines are the only match and they stand eight and two thirds metres off. A record-keeper just out of range of the thing worth recording.

<!-- @ -->

## Matter as the solver

The chain does not iterate. It does not sample its neighbourhood, take a step, and check whether things improved. It is already in the shape that costs least, at every instant, and if you move an end it is in the new one immediately. That is what makes these two problems the oldest solved ones: they were solved before anybody could state them, by rope and by water, and the mathematics arrived centuries later to describe what the rope had been doing all along.

The calculus of variations is that description. The room is the thing it describes.

Next: what happens when the solving has to be done in steps after all, by a machine with a frame budget.



## FormFinding_Relaxation

Source: commons/maps/FormFinding_Relaxation/final.md

SHA256: 98b18b3ba7c0edc659ab7ece1d338e589fa05d7d81dbfb701739953afb5f3b05

A released mesh settles into a shape nobody specified, and what stands afterwards is a fossil of the forces that made it.

The chain in the last hall was already right. A machine cannot do that. It has a frame to get through and a mesh of hundreds of points, so it does the only thing available: nudge everything a little toward where it should be, and do it again next frame. Nothing here is ever solved. It is relaxed, pass after pass, and it stops when it is close enough.

```gdscript
var pos: Vector3 = positions[i]
var prev: Vector3 = prev_positions[i]
var vel: Vector3 = (pos - prev) * damping
var new_pos: Vector3 = pos + vel + gravity * dt * dt
prev_positions[i] = pos
positions[i] = new_pos
```

There is no velocity in that code. Loup Verlet's idea, from 1967, is that you do not need one: where a point is going is implied by where it just was, so keep two positions and the difference between them is the motion. A point at rest, released, falls exactly gravity times a frame squared on its first step, which at sixty frames a second is under three millimetres.

## Nudged, not solved

<!-- @verlet_workbench -->

A magenta cloth of ten by eight points hanging from its two top corners, and this is the only thing in the chapter that is still solving while you watch it: sixty steps before you arrive, and then one more integration every frame you are in the room.

On the panel below it there is a dial reading nudged, worked, pressed or held. Those are one, four, eight and twelve constraint passes per frame, and the bench runs on four. You cannot turn it. It is a cylinder with a lit notch that rotates itself on a slow sine, and there is no collider, no grab and no input handler anywhere in the file. The setting is real and the control is furniture.

Two things about the number are worth more than the dial. The first is that a pass never finishes the job; it takes half the error off each spring and moves on to the next. The second is stranger, and it is measurable: going from one pass to four makes the whole cloth tauter and makes the single worst spring in it *worse*, because a sweep fixes each spring in turn and every fixed spring pulls its neighbour out of true. Relaxation improves the total and is under no obligation to improve any particular part of it.

<!-- @mass_spring_bench -->

The lattice version, and it is over your head: it shares a cell with the spawn point, so the grid bumped it up a level and its slab hangs a metre above where you land. Forty-eight pink masses, a hundred and seventy-nine cyan wires, rocking eight degrees either side on an eighteen-second cycle.

It is not settling. All eighty of its solver steps ran before the room finished loading, and what sways above you is the frozen result, tilted by a random hundredth of a metre per particle and then baked. No shape was authored: there is a grid, a rest length per spring and gravity, and the slumped block is what those three agreed on, once, in a moment nobody saw.

<!-- @frozen_glass_vessel -->

And here is where it stops being a demonstration. A sphere of glass, fifteen rings by twenty-two segments, three hundred and thirty particles, of which the eighty-eight above the top eighth are pinned as if gripped by a blowpipe. Every free vertex is pushed out by a fifth, a pressure pulse, and then the whole thing is dropped into gravity for two hundred steps of the same solver the cloth is running.

It runs once, when the room loads, and stops. The pose it happens to be in at that moment is the vessel. You cannot go inside it, whatever the label says: it has no collider at all, and you will walk through the glass.

Change the stiffness and you get a different vessel. Tilt the gravity and you get a lopsided one. Stop the clock earlier and you get a bottle instead of a bowl. The clock is part of the genome here, which is a real claim about glass and about D'Arcy Thompson's whole argument: the form is not a design, it is a record of the forces that acted and how long they were allowed to act.

<!-- @science_screen -->

A screen, and the thing this room is about is the one thing no screen can hold. Every shape here is a duration: eighty steps, two hundred steps, one integration per frame. A picture of a vessel contains none of the falling that made it, which is exactly what a fossil is and exactly what the vessel is.

<!-- @ -->

## A fossil of forces

The vessel in this room was never designed and it is not a simulation you are watching. It is the frozen output of one, kept because it was interesting, in the same way a fossil is a shape that some process left behind and then stopped.

That is the chapter's argument at its most literal. Nobody drew the amphora. Somebody chose a stiffness, a pin ring, a pulse and a number of steps, and the amphora is what those choose.

Next: forms that are not settling at all, but held, by forces that exactly cancel.



## FormFinding_Equilibrium

Source: commons/maps/FormFinding_Equilibrium/final.md

SHA256: 40e01a633d3f6f5107cc5e9dfba642813a70431720088c744978974a31d888ec

Where forces cancel, a form holds still. That stillness is not rest; it is opposition, exactly matched.

Everything in the halls before this one was falling. The marble was falling, the chain hangs because it is falling and cannot, the mesh was still settling when somebody stopped the clock. This room is what happens when the falling has nowhere left to go: structure as a field of forces in balance, and the shapes that only exist because the balance holds.

```gdscript
var wl: float = left["mass"]
var wr: float = right["mass"]
var total: float = wl + wr
var arm: float = span * (0.7 + 0.35 * float(d))
var dl: float = arm * wr / total
var dr: float = arm * wl / total
```

Read the crossover. The left-hand distance is computed from the right-hand weight, and the right-hand distance from the left. That is the lever law rearranged so it cannot fail: multiply out and the two moments are identical, to the last decimal the machine keeps. The heavier child rides the shorter arm, always, because the arithmetic gives it no choice.

## Balanced by arithmetic

<!-- @calder_mobile -->

A curtain of painted aluminium discs on hair-thin wires, nearly six metres wide and three and a half tall, filling the north half of the room. Each disc carries a small dark nameplate reading its own weight in grams, which is the room telling you what to check.

It is genuinely balanced, not balanced-looking. Each leaf's mass is computed from the real thing, its area times three millimetres of sheet times the density of aluminium, and then every rod is built from the bottom up: weigh the two children, place the pivot where the moments cancel, report the total upward. The heavier disc always rides the shorter arm because the arithmetic gives it no choice.

And it does not move. There is no process loop anywhere in it: for all the wire and the counterweighting, this is frozen sculpture, and the room's own older notes claiming it turns on a breath are describing something else. What hangs here is the solution to a system of equations, held still because it was never going to do anything else.

<!-- @tensegrity_triangle -->

Three struts and three orange joints, with a rhythmic squeeze arriving every few seconds that the frame takes and springs back from. Fuller's lesson: the triangle is the only rigid polygon. Four bars of the same stock, hinged, fold flat under a load like this. Three do not, and nothing was added to make that true; it is a fact about three.

One correction the object will not make for you. Its name promises a tensegrity, and this is not one. A tensegrity is compression members that never touch, held apart by tension; here the three struts meet at the joints and there is not a cable in it. What you are looking at is the rigid triangle that a tensegrity is built out of, and the thing itself is in the last hall of this chapter, holding a teacup.

<!-- @fractal_truss_tower -->

A steel tower three and a half metres tall standing on a seven-metre plate, four fat corner legs and four stacked panels of cross-bracing, an orange beacon at the top and the words MAX STRENGTH, MIN MATERIAL on a board. Eiffel's trick: span the most with the least, by never asking one long member to do a job a triangulated cluster of short ones can do lighter.

The recursion is not the one the label implies. It halves the tower vertically and braces each half again, so what recurses is the storey and not the strut, and the finer legs it adds lie along the same corner lines as the coarse ones, hidden inside them. A beam made of beams is the idea. Stacked bracing, three deep, is the building.

<!-- @science_screen -->

The screen ends up drawing a radar scope and counting the tower's children, having matched the triangle by name and then declined it. Fair enough: a diagram of a mobile is a picture of a tree, and the property that matters here is two products being equal at every node, which no picture holds. You have to be told, or you have to read the nameplates.

<!-- @ -->

## Gravity as co-designer

Gaudí hung chains from a ceiling and turned the photograph upside down. The chain finds the curve of least cost in tension; inverted, it is the arch of least cost in compression; and the shape nobody could calculate in 1890 was already hanging in the room, waiting to be photographed.

That is the same move all three objects here make. The mobile does not represent a balance, it is one. The triangle does not depict rigidity, it refuses a load in front of you. The truss does not illustrate efficiency, it is what is left after everything unnecessary was removed. In each case the designer's job was to set up a situation in which the answer would appear, and then to stop.

One thing to carry out. Everything in this room is holding still at the bottom of something. The last hall asks whether the bottom is where you want to be.

Next: how to leave a hole you have already fallen into, and why you might not want the deepest one.



## FormFinding_Annealing

Source: commons/maps/FormFinding_Annealing/final.md

SHA256: d1aa490701065b2e49a4b6f49a791c0947c6d7a6db6ed3d43dd0af4250409b7c

You have to be willing to get worse to get better. And then the room asks a harder question: how far down do you actually want to go?

The first stable shape you fall into is rarely the best one. The marble in the first hall found the nearest bottom, not the lowest, and every settling thing since has done the same. This is the room that knows the trick for getting out, and the room that argues the trick can be taken too far.

```gdscript
var delta_energy: float = neighbor_energy - current_energy
var accept: bool = false
if delta_energy < 0:
    accept = true
else:
    var probability: float = exp(-delta_energy / maxf(current_temperature, 0.0001))
    accept = randf() < probability
```

A better move is always taken. A worse move is taken with a probability that depends on how much worse it is and how hot things are. That second branch is the entire idea, and it is a strange thing to write down: a rule that deliberately accepts a bad outcome, because a run of bad outcomes is the only way out of a hole.

## Getting out

<!-- @energy_landscape_bench -->

A bench with a wrinkled tabletop: four hundred and eighty-four little boxes standing at the height of an energy field, three sine waves crossed, coloured from blue in the troughs to violet on the ridges. A soft yellow blob sits in one of the hollows. It descends into whichever basin it was dropped above and stays there, which is the first hall's marble again on a surface with more than one bottom, and it is here as the thing that needs fixing.

<!-- @simulated_annealing -->

The cabinet that fixes it: a dark survey table, waist high, with a milled basin holding a metre and a half of glowing relief. The surface is the Rastrigin function, which is the standard cruelty of this field, a smooth bowl with a cosine corrugation laid over it so that it has one true bottom and a regular grid of decoys all the way out. A temperature starts at a hundred and cools toward a tenth. A gauge along the rail shows how often a worse move is being accepted.

Run it hot and the search wanders almost anywhere, uphill as readily as down. Run it cold and it is gradient descent again, refusing every backward step. Cool it in between and it explores first and commits later.

The numbers behind the gauge are worth a moment. A move costing five hundredths of an energy unit is accepted about four times in five at a temperature of a fifth, and never at all at two thousandths. And when the search stops improving for long enough, the cabinet does not wait: it hops the whole solution to a new basin and starts again from there. This is a machine built around the admission that its own best rule gets stuck.

<!-- @max_q_basin_room -->

And then the turn, and you will have to look up to find it. Two wells cut into one seven-metre plate, and the plate is hanging three and a third metres over your head: it shares its cell with the spawn and got bumped, then the grounding pass lifted it clear of the walls, so the room's argument is on the ceiling and the frozen cube in its dead well dangles at about your eye level.

On one side a narrow pit two and a fifth metres deep with steep walls, holding a single rigid half-metre cube. It is at the lowest energy here, it is perfectly settled, and it will never be anything else. On the other a broad shallow basin with something soft in it that keeps moving, finding a shape and losing it and finding it again. That one is higher up. By the arithmetic of the previous four halls it is worse.

The claim on the floor is that it is the better minimum, and the room calls the difference Q. The deepest well is a dead-perfect crystal, finished. A form that can still be moved has to be resting somewhere shallow enough to be moved out of, which means the liveliest place in an energy landscape is never the bottom of it.

<!-- @impossible_end_table -->

The proof that this is not a metaphor, standing in the room as furniture, and the tensegrity the last hall promised and did not deliver. An end table whose top never touches its base: two steel Y-brackets whose arms overlap in plan with sixteen centimetres of daylight between them, one central cable holding the top down against three perimeter cables that stop it swaying. A teacup on top, unbothered.

Islands of compression in a sea of tension. Nothing here is resting on anything. Every part is being pulled, hard, in a direction that exactly cancels, and the stillness of the teacup is the sum of forces that never stop.

<!-- @science_screen -->

A screen, washing the wall green. Had it looked up it would have drawn two basins and drawn the deeper one deeper, because depth is the only quantity a diagram of this kind carries. Q is the difference between those two wells, and depth is precisely the axis on which the shallow one loses.

<!-- @ -->

## Low enough to hold, high enough to be moved

That is the chapter, and it ends by turning against its own first sentence. A form is the answer to a minimisation problem, and matter finds those answers by falling. Four halls of that: the marble, the chain, the settling mesh, the balanced mobile, none of them drawn, each one the shape that costs the least.

Then this one. Reaching the lowest value in a model is not the same as finding the form you want. A shallow basin can preserve a useful response to disturbance even when a deeper basin gives a lower score. That comparison is a choice about this model's purpose, not a test that separates living matter from dead matter.

Next: build a form and inspect the rule that decides whether it has settled well enough.



## FormFinding_Forge

Source: commons/maps/FormFinding_Forge/final.md

SHA256: 9b37c121ad49f071c1eeb43bdfa952dfda11f95edfb1fc692f71f4c1ac791b3d

# A shape that counts

Who decides when a shape has settled well enough?

<!-- @balance_puzzle -->

Arrange the loose pieces into a stack, then let go. Watch the height and stability display. If the pieces fall into a quiet heap, compare that stillness with a taller arrangement that holds. Both can stop moving, but the puzzle does not treat them as the same result.

Its recognition asks for height as well as a period of sufficiently small movement. A low heap can therefore be stable and still fail its test. When a raised arrangement meets both conditions, the transformation animation begins. The animation acknowledges the detector's decision; it does not establish that the arrangement has become biologically alive.

Try another construction before accepting the first as the answer. The pieces and their contacts constrain what can stand, while the height condition selects which standing forms will count. That second choice belongs to the task's author as much as to gravity.

<!-- @gradient_descent_optimizer -->

At the neighbouring optimiser, follow the point and its trail across the coloured surface. The energy readout and step count give you something to compare with its motion. Look for the slowing approach to a resting region and the later start from a different position.

Choose a short section of the optimiser's trail and compare its beginning with its end. Follow the energy readout while new steps appear, then notice whether the path changes direction or simply continues straight. A curved path can arise because the direction of descent changes from place to place. When the demonstration begins from another position, choose a second section rather than assuming it must retrace the first. Compare the approaches to a low region, leaving the question of the final destination open. This gives you two histories to explain, instead of treating the resting point as the only part of the calculation that matters.

Here a numerical rule estimates the local slope in two directions and takes a small step downhill. It repeats that operation, retaining a short record of previous positions. The surface supplies the quantity being reduced; the stopping condition decides when further change is small enough to begin another demonstration. A small local slope is not proof that the point has found the best possible place on every landscape.

<!-- @ -->

Build a low arrangement that you find useful and the puzzle refuses. Describe its usefulness without pretending it passed. This is a precise way to question a success criterion: retain the physical result and change what you ask it to mean.

The next sequence begins with oscillation. A form can persist through returning motion as well as through rest; settling is only one way for a system to continue.



# wavefunctions

Declared order: WaveFunctions_Intro → WaveFunctions_Pendulum → WaveFunctions_Sine_Space → WaveFunctions_Unit_Circle → WaveFunctions_3D_Wave_Propagation → WaveFunctions_Effect_Sound → Wavefunctions_Bernini → WaveFunctions_John_Cage → WaveFunctions_AirMusic → Wavefunctions_Sky_Stairs → WaveFunctions_TrigWalkingPath → WaveFunctions_Synthesis_Lab

Museum map-authored order differs: WaveFunctions_Intro → WaveFunctions_Pendulum → WaveFunctions_Sine_Space → WaveFunctions_Effect_Sound → WaveFunctions_AirMusic → WaveFunctions_Synthesis_Lab. Treat this as route drift to inspect, not an editorial recommendation.


## WaveFunctions_Intro

Source: commons/maps/WaveFunctions_Intro/final.md

SHA256: a4cfd70349d87286032d53620ddae87752d902acc02531881262e47960546f9e

# Returning differently

The ring marks a place the bob keeps leaving.

<!-- @control_pendulum -->

A thin line hangs from the pivot towards it. Take the bob to one side and release it. Watch the first crossing of the ring, then the next. Something has returned. Before looking at the numbers, try to say what has not.

The counter may already be above zero. Taking hold of the bob gives us a beginning inside a swing that began earlier. Those crossings remain in the count.

At the ring the angle is close to zero on both passes. The velocity reading carries a different sign. One zero is on the way out; the other is on the way back. A position that looked sufficient a moment ago needs another number before we can say what happens next.

Follow the bob towards an end of its swing. It slows, seems to wait, and turns. The speed has reached zero there too, but the angle has not. The body can be still for an instant without having finished moving.

We have met position, velocity and force in earlier rooms. Here they take turns making the return. These are the state updates in the pendulum's physics step, with the optional driving force omitted:

```gdscript
var angular_acceleration: float = -(gravity / pendulum_length) * sin(_angle)
_angular_velocity += angular_acceleration * delta
_angular_velocity *= _damping_multiplier(delta)
_angle += _angular_velocity * delta
```

The angle supplies a restoring acceleration. Acceleration changes velocity; damping reduces it; velocity changes the angle. At the next step, the new angle enters the first line. Read down, then return to the top. The repetition in the code makes a return in the room without listing the positions the bob must visit.

Now release it from the other side. Try giving it a small movement as you let go, then releasing it as nearly still as you can. The hand can supply speed as well as a starting position. But how much of the hand gets through?

The release code takes a velocity averaged from recent positions and projects it onto the direction of the swing:

```gdscript
var tangent_velocity = avg_velocity.dot(tangent_direction)
_angular_velocity = tangent_velocity / pendulum_length
```

The dot product keeps the part along that tangent. A sideways flourish can occupy your hand and contribute little to this number. The constraint makes the pendulum manageable: one angle, one angular velocity. It also gives you something to play against. Try two different gestures that leave a similar swing. Their resemblance belongs to what this body accepts from them.

Behind the bob, a curve predicts six seconds from a standard starting angle. Make a larger release and compare it with that curve. The prediction did not watch your hand. It began with another condition. A wide swing also presses against the small-angle approximation in which length, with gravity fixed, sets the period. The actual restoring rule still contains `sin(_angle)`. Give several complete swings time to pass before deciding how their rhythm differs.

There are several beginnings here: the engine's, the counter's, the prediction's, the moment you let go. They do not have to coincide for the experiment to work.

<!-- @ -->

The nearby cubes return by other means. A clock prescribes one cube's bobbing; a steady rotation brings another back to its orientation; a third listens to this pendulum's signal. Similar repetitions can be made by different arrangements of state and time.

Our counter can tell us that the bob crossed the middle. It cannot show the gesture that started this particular swing. We leave with a number that has kept something, and a reason to want more than a number. In the next room the past takes up space.



## WaveFunctions_Pendulum

Source: commons/maps/WaveFunctions_Pendulum/final.md

SHA256: ca12bf9d17f6c803f5990f5c6a77772195862c20b787ee2887753089c8c44aa5

# Where a swing leaves its past

Behind the bob, something is leaving the room very slowly.

<!-- @PendulumWave -->

Stand beside the frame and follow the swing. Then choose one teal mark just behind it. The bob turns. Keep looking at your mark: does it turn too?

It continues away along the hall. Walk beside it. From here the whole record resembles a wave, although the bob has only swung in one plane. The long direction belongs to something the bob did not do.

Each mark keeps a position and a time. When the record is drawn, this line gives it depth:

```gdscript
var depth: float = (time - p.z) * time_speed
```

`p.z` holds the time of the sample. Subtract it from the present and an age appears; multiply by 0.6 metres per second and that age becomes a distance. An old moment is further away. We can walk beside a duration because a direction has been given another job.

Find two crossings of the record's centre line that go the same way, one full swing apart. Count the marks between them. The plate gives a measured period and a target sampling interval; dividing the first by the second should come close to your count.

Close is enough to notice another line on the plate. FINE requests 25 milliseconds. The actual gaps are about 16.7 to 33.3 milliseconds. Which rhythm is in the drawing?

The recorder works on a physics clock ticking sixty times per second. Its request falls between ticks, so the gaps alternate between one tick and two. The small mismatch has a place in every swing's record. The cyan joins can make it easy to overlook.

Press COARSE and watch the empty record fill again. The bob continues its swing. Compare how far the oldest mark gets before disappearing. The rougher line can reach further into the past.

Two endings are written into this list:

```gdscript
while trail_points.size() > max_trail_length:
	trail_points.pop_back()
while not trail_points.is_empty() and time - trail_points.back().z > max_history_seconds:
	trail_points.pop_back()
```

The newest samples enter at the front. These lines remove from the back: first anything beyond three hundred entries, then anything older than ten seconds. FINE fills the available entries in roughly 7.5 seconds. COARSE keeps around fifty under the age limit. We changed which detail was affordable, and gained duration. A person looking for a small tremor and a person looking for a long return would have different reasons to choose.

Walk to the far end and wait with one mark. It is there, then absent. No fading gives it a farewell. The pendulum carries on from its current angle and speed; this little piece of its accessible past has gone.

Now press STROBE. The sampler uses the period measured from the pendulum's own crossings. After a few swings, compare the moving bob with the sparse record behind it. The marks nearly line up. Tick-sized differences remain, but much of the movement has vanished from what was kept.

This can become an instrument for finding repetition. It can also make repetition look like stillness. Try reading the marks before glancing back at the bob. The same setting helps with one question and makes another difficult to answer.

RESET begins this experiment again: starting angle, local time, empty list. The museum continues. We have already seen how useful it is to make a beginning without beginning everything.

<!-- @ -->

On the west walkway a drum turns beneath a pen. There, time takes an angle instead of a depth. In the point rooms, the drawing dot asked whether a hand had moved far enough to keep another position. These recorders ask different questions of what passes them.

We could stay and change what a record values. Ahead, rising and falling are being given yet another direction: two walls carry waves along a passage. A line that helped us read time will become something we read with a moving body.



## WaveFunctions_Sine_Space

Source: commons/maps/WaveFunctions_Sine_Space/final.md

SHA256: 1d97723e8dcc802d1c2b5598fe062023570be93cbdedc6dd77f98faf2080c615

# What a wave can hold

<!-- @sine_flow_tray -->

The blue surface is tilted towards an open edge. Choose a hollow. Will a body that reaches it leave again?

Press RELEASE on the side desk. Thirty-two spheres arrive together. Follow one while the others keep moving. When it meets a fold, its next position depends on contact with that surface and sometimes with another sphere. The landscape has become part of the movement.

After twelve seconds the bodies stop. The small display separates those that crossed the outlet from those still inside and those that left elsewhere. The spheres in the neat rows below are a record: the program moves each departed body there and removes it from further collisions.

Leave RELIEF alone and press SIZE. The surface waits for a larger body. Release again. Which hollow from your first prediction still matters? Cycle SIZE once more to try the smallest spheres. A place in the landscape has dimensions; so does what arrives there. The name of the wave has not told us their relationship.

RESET returns the middle size and the original relief. Now change RELIEF and repeat. This control raises the difference between the lowest and highest samples while keeping their positions across the tray. The same arrangement becomes steeper. You have changed the surface's height range, then watched what that means to a body with its own size, mass and contacts.

Open RULE. Before the heights are rescaled, the surface begins with this product:

```gdscript
samples.append(sin(TAU*0.9*x) * sin(TAU*0.9*z))
```

One sine repeats across the tray and another along it. Their product supplies a height at each sampled address. Triangles join those addresses. Then a further line gives the visible mesh a collision shape:

```gdscript
collision.shape = mesh.create_trimesh_shape()
```

The surface now participates in the physics simulation. It stays still throughout the trial. Time belongs to the moving bodies and to our observation window.

Look again at STILL IN. Twelve seconds gave us time to compare. It did not give us forever. A body present at this deadline has not been proven permanently trapped. And if the purpose were to hold something here, our judgement of the same count might change. What else would we need to learn before calling this hollow a shelter?

<!-- @ -->

Beyond the tray, at the mouth of the passage, a fold comes towards you.

<!-- @sine_wall_corridor -->

There is a corresponding fold on the other wall, a little out of step. Enter through the west mouth and stop. Choose a narrow place ahead. Watch what becomes of it while you stay where you are.

The walls keep changing the invitation. Walk back to the panel and press FREEZE. Now the folds wait for you. Pass one, turn, and approach it from the other direction. A shape can come to meet a body through its own motion or through the body's movement. For a moment these felt alike.

Run the walls again and follow a small ripple across a broader fold. The layers slip past each other. Walking the frozen surface carries one arrangement past the eye; advancing the phase changes how its layers agree. We have found a difference inside the resemblance.

Leave AMP where it is and slide PHASE through half a turn. Look at a place where the left wall approaches the middle. What is the right doing now?

Both sides bend the same way. The passage swerves while the readout settles at 2.00 to 2.00 metres. Slide back towards zero and openings and pinches return. One relative setting has changed the kind of passage the pair makes.

Here is how a displacement is placed on either side:

```gdscript
var x_pos: float = base_x - side * displacement
```

`side` is -1 on the left and 1 on the right. The same positive value moves both walls inward. Give one wall the negative of the other's value and their movement across the passage agrees instead. A half-turn phase offset does that to a sine. It does it to every sine in this sum:

```gdscript
offset += base_amplitude * amp_multiplier * amp_mul * sin((base_frequency * freq_multiplier * freq_mul) * z_norm * PI + phase_shift + phase_layer)
```

Read the terms through what you just changed. Amplitude multiplies the depth of a fold. Frequency sets how many returns fit along the passage. Phase changes where in the return a wall stands. The fundamental makes 4.5 cycles over seven metres; two higher spatial frequencies add the smaller ripples. All receive the running phase, but their different wavelengths make the layers drift at different speeds.

Return PHASE to half a turn and inspect a bend. The number still says two metres. Notice its name: `x-gap`. It compares the two walls at matching positions along the passage, across local X. The shortest way between curved surfaces need not follow that direction. We have made a constant width by deciding how to measure it. Which width would matter to a body trying to get through?

Bring PHASE back towards zero, then raise AMP. Approach a pinch slowly. Try crossing a visible crest instead of following the opening.

You can pass through. The walls have no collision shapes; a thin floor slab above the museum deck supplies support. Yet the surfaces have already offered a direction, a narrowing, a reason to hesitate. Their influence did not wait for collision to be enabled.

Try following the apparent passage for a few steps, then cutting across a fold. The same construction permits both. Giving these surfaces the power to stop you would change what can happen here, and it would require another part of the program.

RESET restores the declared settings. The walls begin to disagree by the familiar amount. You can recognise the passage and still choose a different route through it.

<!-- @ -->

The small case in the west nook offers another view of the wall rule. Below the bridge, the older floor of spheres rises and falls through a product of two sines. A repeating value has acquired several bodies already.

In the next room a sine enters another sine's phase. There will be no gap to walk through. We will listen for what their relation has made possible.



## WaveFunctions_Unit_Circle

Source: commons/maps/WaveFunctions_Unit_Circle/final.md

SHA256: e391c3623417c91e8a90b519aec3c7fffca392f79673fbcd4e72ad979f6f6f55

# A circle becoming a graph

How can going round a circle make a line that rises and falls?

<!-- @unit_circle_advanced -->

Follow the point on the circle and look at the projection rods beside it. When the point reaches the top, compare its height with the corresponding part of the wave. Repeat at a side and at the bottom. If the drawing has already finished, use its completed sequence of steps to follow those correspondences back to the circle.

The point's vertical position rises and falls while its journey continues around the circumference. Its horizontal position follows another cycle. The two projections do not reach their extremes together: when one is at an extreme, the other passes through its middle.

Pick four reference positions around the circle: right, top, left and bottom. At each, compare the point's horizontal and vertical offsets from the centre. At the top and bottom, the horizontal offset returns to its middle while the vertical offset reaches opposite extremes. At the sides, those roles exchange. Use that sequence to predict a quarter of the adjacent graph before following it. Then start your reading from a different reference position. You have changed where you begin describing the cycle without changing its order. A beginning is needed to label the progression, even though the circle itself has no privileged first point.

For a circle of unit radius, those coordinate values are sine and cosine. The adjacent graph gives angle progression a new axis and uses one changing coordinate as height. It unfolds a relationship already present in the circular motion. The graph is not the path the point takes across the floor; its horizontal direction has a different meaning from the circle's horizontal coordinate.

Find a height that appears twice in a cycle. One occurrence belongs to a rising part and the other to a falling part. Knowing the height therefore does not recover the whole angular position. The missing distinction matters whenever a cyclic process is described by one measured value.

The displayed construction is finite. It adds sampled steps until its allotted cycles are complete. Those steps let you count and compare positions, but they do not make a continuous mathematical curve exact, or establish a verified walking route simply by resembling a bridge.

<!-- @ -->

Next, a lattice of oscillators asks what happens when neighbouring cycles influence one another. You have followed one point and its projections; now look for relationships between many moving points.



## WaveFunctions_3D_Wave_Propagation

Source: commons/maps/WaveFunctions_3D_Wave_Propagation/final.md

SHA256: fb05267354126199f3f83591a0472069ff57b0b6b9b7a71e8398865b438ec095

# The motion that travels

How can a disturbance travel while its parts stay near their places?

<!-- @coupled_oscillator_lattice -->

Choose one sphere near the centre of the lattice. Follow that sphere alone for several movements. Then widen your attention to its neighbours. Compare when they rise together and when their displacements differ, without abandoning your first sphere as a reference.

The spheres remain at their horizontal grid positions. Their movement is vertical. The pattern spreading across them can therefore travel without any one sphere crossing the whole display. This is the distinction to establish before naming the result a wave.

Select two neighbouring spheres and look for a moment when their heights differ. Follow the pair through several movements, describing their separation rather than only the larger pattern. Now choose two spheres farther apart and make the same comparison. Similar heights at one instant do not establish that the two places are always moving together; watch which way each moves next. If you find a repeating relationship, check whether it persists through another cycle. This is a way to investigate coordination without assuming every visible crest is a travelling object. The pattern needs more than one instant to reveal what is changing and what remains related.

Each oscillator has its own restoring influence towards an equilibrium and a damping term that resists its velocity. Coupling adds another influence: a neighbour displaced differently contributes a force. The program gathers those forces and then updates the oscillators' velocities and displacements. The centre receives a continuing excitation in this version, so the surrounding motion has a source.

Look at an edge and then at the interior. An edge cell has fewer neighbours. A boundary is therefore part of the mechanism, not merely where the picture happens to stop. The finite arrangement cannot behave exactly like an unlimited medium, and these simplified links do not claim to reproduce every material that carries waves.

Try describing the display twice: first as a collection of individual moving spheres, then as a pattern moving through their relationships. Each account makes something visible and leaves something out. Neither requires the spheres to agree consciously or to know the pattern they collectively form.

<!-- @ -->

Changing the coupling or disconnecting selected neighbours would extend this investigation; those are proposed variations rather than controls available here. The next room turns to sound, where one oscillation can modify another and a relationship between simple sources can change what you hear.



## WaveFunctions_Effect_Sound

Source: commons/maps/WaveFunctions_Effect_Sound/final.md

SHA256: 34f3f99f684203ab9ad3e644f3567a30d1879b21a20fa58ed972eb297e6d4f94

# One wave inside another

In Sine Space, a sampled wave carried spheres and two moving walls suggested a passage. Here the wave enters another rule. Two balls sit in separate cages above desks. Begin with one note.

<!-- @DualBallFMController -->

The blue ball belongs to the carrier, the orange to the modulator. Their desks leave room to approach each separately. Press BASELINE, let the short note end, then press HOLD to keep it as the comparison's A.

Leave the blue ball where it is. Lift the orange one a little and listen again; PLAY sounds the current setting without another movement. While the ball is moving far enough to retrigger, the rig starts fresh notes at most once every 0.3 seconds. A drag can become a run of beginnings. Let the ball rest and give the note time to finish. Before giving the change a name, decide where you heard it: at the beginning, through the middle, or near the end.

COMPARE returns A, leaves a quarter-second gap, then plays the current note B. You do not have to keep the first sound intact in memory. Look at the `differs:` line. If the lift changed only I, the modulation index, we have one change to listen through. If other values moved too, return to BASELINE and try a more deliberate lift.

At index zero, the modulator contributes nothing to the carrier's phase. Raising it gives that contribution more depth. A sound may become brassy, brittle, bell-like, or acquire a quality for which you have no ready name. Keep listening before choosing a familiar object to stand in for it.

The two oscillations meet in this line:

```gdscript
var output = sin(2.0 * PI * carrier_freq * t + modulator) * carrier_env
```

The modulator is inside the sine's argument. Adding it there advances or delays the carrier's phase; the envelope outside controls the note's rise and fading. The room calls this FM synthesis. This expression implements phase modulation, which also changes instantaneous frequency. The orange contribution is not mixed in as a second audible output. It changes how the other oscillation proceeds.

Now keep the height of the orange ball as steady as you can and change its depth along the desk. That direction changes the modulator's decay. Listen through the tail before moving again. Can the altered character persist while the note grows quiet?

The modulator has a fading of its own:

```gdscript
var mod_env = exp(-t / mod_decay)
var modulator_freq = carrier_freq * mod_ratio
var modulator = sin(2.0 * PI * modulator_freq * t) * mod_index * mod_env
```

A longer `mod_decay` keeps the phase disturbance present for more of the note. The carrier's envelope can remain the same. Something we first heard as one fading has separated into two processes we can vary.

Try the orange ball's left-to-right direction last. It changes the ratio between the oscillators' frequencies. Keep a reference and compare. Listen for a relation you want to return to, even if it refuses the name of an instrument you know. A setting that would spoil one imitation may be the beginning of another sound.

BASELINE is a chosen reference too: a 440-hertz carrier, an attack and a decay, index zero. The generator still applies its `tanh` shaping and gain to the output. Calling this the beginning makes a comparison possible; it does not uncover a sound before all decisions.

HOLD can keep a note without knowing what you liked about it. COMPARE gives that decision back to your ear. The rig reports changed parameters, but there is no field in its list for the difference that made you want to listen again.

<!-- @ -->

Look back at the scope. Once the orange contribution is above zero, raising its index need not make the orange trace taller: the display divides that lane by the index to fit it. The output changes while the apparent height of its cause can stay much the same. Even this small window has an arrangement to uncover. It shows two carrier periods near the attack, not the whole fading note. The coloured cube gives some of the settings another appearance. Neither can take over the listening.

In AirMusic, a strike starts a response that continues after contact. Carry this habit to the bar: give a sound time to change before deciding what sort of body has answered.



## Wavefunctions_Bernini

Source: commons/maps/Wavefunctions_Bernini/final.md

SHA256: 78701900090a59b419c1862e9358f171fa8aee75001a5b04b2d8dfd76c71cbd4

# A movement kept in a column

Can a shape keep the rhythm of a movement without travelling along it?

<!-- @bernini_columns -->

Choose one ridge on a twisting shaft and follow it upward. Notice how it moves around the vertical axis as height increases. Change your viewpoint and find the ridge again. Then compare it with a neighbouring column.

There are two different changes to disentangle. The shaft is already twisted as a shape: its profile varies from one height to another. It also rotates slowly as a whole. Watching that rotation does not explain how the twist was made, and following the twist does not require the column to rotate.

Look at the shaft at a low level, then at a higher level, keeping its central axis in mind. Where has the ridge moved around that axis? Continue upward until you recognise a comparable orientation again. You are reading a repeated turn through height. Next keep your attention at one level and let the column's slow rotation bring the surface past you. This second observation follows change through time. The two readings can resemble one another while using different coordinates. Say which reading you are making before comparing two columns; otherwise a turning shaft can disguise a difference already built into their profiles.

Circular coordinates provide sine and cosine values around an axis. Combining those changing coordinates with height produces a helix. Further variations in the radius and surface give the shaft its richer profile. A periodic function that previously described movement through time now helps specify where parts of a solid belong.

Look at the columns together. Their repetition creates intervals and sight lines that a single shaft cannot. The form and its arrangement contribute different things: one supplies the twist, the other decides whether you meet a field of objects, a threshold or an aisle. This version presents a repeated set rather than a control for rearranging the plan.

The scene is inspired by spiral architectural columns. Its mathematical construction does not account for the whole history of a building, the labour of making it, or what it means to those who use it. Nor does the accompanying generated sound make the column an instrument you play by touching its surface.

<!-- @ -->

Try reading the shaft once as a solid and once as a sequence of changing cross-sections. The next room leaves more of its temporal composition to chance. A rule can preserve a recognisable form while allowing individual events to arrive differently.



## WaveFunctions_John_Cage

Source: commons/maps/WaveFunctions_John_Cage/final.md

SHA256: 16a16df2bd92561ab237bd1e14d59e2c5ddfa36c6d28d325389686271ee323f4

# The limits of the unexpected

What remains composed when the next event is left to chance?

<!-- @john_cage_tech_noir -->

Let the soundscape load, then listen long enough to separate a continuous layer from intermittent events. Count a few entrances without trying to force them into a regular beat. On a second listening, attend to the intervals rather than to the events themselves.

The background can remain recognisable while particular sounds arrive differently. There is a difference between not knowing which event comes next and hearing something the system has no means to produce. Listen for the vocabulary that persists through the variation: the kinds of sound available, their textures and their recurring relationships to the drone.

For one listening interval, attend only to whether the background continues beneath an event. For the next, attend to how the event begins and fades. A sound can arrive unexpectedly while retaining a recognisable envelope or texture. If a related sound returns, compare what seems shared and what differs without assuming it is exactly the same prepared variation. Then leave an event uncounted and listen to what remains around it. This gives you several ways to hear organisation even when the entrances resist a regular pulse. Your attention supplies a repeatable listening task, although the generator does not promise to repeat the same sequence for you.

The composition prepares a collection of generated sounds, including variations of several effect types, then makes choices about their playback. Randomness operates within that prepared collection. The program has already decided what can be selected and has supplied the rules that govern selection. Chance changes the sequence without escaping its frame.

The luminous forms respond to sound activity, but looking at them does not reveal every scheduling choice. The listening experiment also does not depend on treating them as physically located sources whose volume you can mix by walking around. Give the sound itself time to disclose its layers.

Try deciding that an interval is the part you are waiting for. This changes your listening without changing the generator. A version that admitted sounds recorded from visitors or the surrounding room would change the available vocabulary; that remains a proposed extension.

<!-- @ -->

The room's title offers a reference, not a claim to perform a particular John Cage score. Its concrete question is about authorship inside a chance procedure. In Air Music, a strike will supply a more direct beginning: you will choose when an oscillation starts and hear what continues after your contact ends.



## WaveFunctions_AirMusic

Source: commons/maps/WaveFunctions_AirMusic/final.md

SHA256: ea6e71249d23663f3b3613bb90908828f6f865635efcfd88526c0aa8c6657a01

# After the strike

In Effect Sound we kept a note and changed the rule that made it. Here the hand can leave while its consequence continues.

A stick lies in a cradle at the left end of a table, front to back. Eight metal bars lie along the table beside it, the longest nearest the stick, and a pale rail runs along the table's front edge.

<!-- @resonating_metallophone -->

Take the stick and bring it down on the left-hand bar. Lift it away at once and keep listening. The contact is over; the bar glows and rings, and the plate above the row names one voice, its hertz and its age. The glow fades as the seconds count up. Decide, before the note is gone, whether what you hear is the strike or what the strike began.

Strike the same bar again while it still rings. There is another attack, but no additional voice: this bar starts its existing player again, and its age on the plate returns towards zero. Now strike a shorter bar instead, while the first is still fading. The plate says two voices, each with its own age. The first was not stopped by the second. Try to hear where one ends and the other goes on.

The bar keeps its note as a number and its ring as a curve. Each bar plays a sound it made once at startup:

```gdscript
		var envelope = exp(-t / decay_time)
		var wave = sin(2.0 * PI * frequency * t)
```

a sine at the bar's frequency under an exponential decay. After three seconds its envelope is about 37 percent of its initial value. The glow uses that decay too:

```gdscript
			current_amplitude = (hit_velocity * max_amplitude) * exp(-resonance_time / decay_factor)
```

So this is a synthesised resonance, not the vibration of a metal bar solved from its material. The length is chosen from the note, not the note from the length:

```gdscript
	return BAR_LENGTH * sqrt(root / maxf(1.0, freq))
```

The chosen relation makes length fall with the square root of frequency. This gives the row a visible order before you have struck anything. The program does not compute this note from the metal, the stick's material or the table underneath. Those bodies could change without changing the stored frequency. The resemblance is an arrangement we can inspect.

The stick's speed does reach the bar. A slow touch lands at a fraction of the level a fast one does:

```gdscript
		hit_velocity = clamp(velocity_magnitude * 2.0, 0.1, 1.0)
```

Try the same bar slowly and then quickly, and listen for what the level changes and what it leaves alone. The glow uses the strike value directly; the player maps it into decibels. A much dimmer glow need not mean a proportionally quieter note. The hand has reached two different mappings.

Now the pair. Choose two bars and strike them with a clear gap, letting the first almost finish. Reverse the order. Then shorten the gap until the second enters while the first is still loud. The plate lists both voices with their own playback ages. The ribbon adds a short piece of the two generated notes, and the sum is not a third bar. When one masks the other, let them separate again and try the gap once more.

The eight notes take C, D, E, G and A and continue into the next octave, ending at E5. That is a decision about which pairs are available to you, not a law about which pairs are good. Another cut would offer other pairs; this room offers this one.

Set the stick down more than half a metre from its cradle and leave it alone. After three seconds the return begins. Leave it at rest and listen to the last voice go.

An exponential never quite arrives at zero, but this note does end. The stored sound lasts seven and a half seconds, with a short fade in its final tenth. The model lets go before the mathematical tail does.

Look at the plate's other number: 12 ms. The ribbon has only that much time across its width. It reads samples near each bar's playback position, after that player's gain, before distance and the rest of the audio system. A smooth curve here still joins chosen data points. Moving your head changes what reaches you without rewriting these stored notes.

<!-- @ -->

Every note here is one sinusoid under one decay. The Synthesis Lab adds such sinusoids together on purpose; what the ribbon drew for you as a sum is where that begins.



## Wavefunctions_Sky_Stairs

Source: commons/maps/Wavefunctions_Sky_Stairs/final.md

SHA256: 2b8e3f5a889a7dca10cd7422b0eb551915702ebfc21e136d42e41bc144fb9556

# What a curve needs from a stair

When does a sampled curve become a route a body can use?

<!-- @sine_cylinder_staircase -->

Begin by following the treads with your eyes from the lower end. Compare one step with the next: the change of height, the turn, and the distance from the centre. Notice the surfaces joining neighbouring edges as well as the steps themselves.

The route combines an angular progression with a steady rise. Its radius also varies with a sine function. A regular rule therefore produces a stair that does more than circle a fixed cylinder. The outline breathes inward and outward as it climbs.

Choose three consecutive treads that you can see clearly from the surrounding floor. Compare their centres first, then compare the edges a foot would meet. A regular change between centres can still leave different apparent gaps at the inner and outer edges of a turn. Move your viewpoint to check whether a gap is real or hidden by an overlapping surface. You do not need to step onto it to make that distinction. Repeat the comparison where the staircase's radius appears wider. Describe which relation changed: height, turn, width or edge connection. These observations turn a general impression of smoothness into several concrete questions about support.

Those sampled positions are only the beginning of a staircase. Each needs a tread with width and depth, an orientation, and a relationship to the next tread. The default construction adds connecting membranes between facing edges. They make the gaps part of the visible argument: a formula gives positions, while a route needs provision for the body moving between them.

Do not judge the whole climb from the smoothness of its outline. An entrance, a comfortable rise, headroom and continuous support have to work at the scale of the visitor. This room still needs that full walking check. You can inspect the sequence and compare accessible parts without treating the entire visible spiral as an established route.

Identify one turn or gap that would matter to a different stride. A route that feels continuous to one walker can remain discontinuous to another. The question is not answered by adding more samples alone: their arrangement and support also matter.

<!-- @ -->

A handrail, supporting posts or a different connection between treads could each change this encounter; they are choices to test, not qualities the equation supplies automatically. The following room returns to interacting cycles. Keep the distinction between a mathematical relation and the particular object that makes it available to perception.



## WaveFunctions_TrigWalkingPath

Source: commons/maps/WaveFunctions_TrigWalkingPath/final.md

SHA256: 9feafb76e00cdf28318f5b9e55dc6679ccd534badb9bbaf3da4d27d10deae583

# A slow pulse from fast motions

How can two quick repetitions produce one slow pulse?

<!-- @beat_frequency_demo -->

Look at the rows labelled A, B and A+B. Use the two frequency controls to bring A and B close together. Follow one part of the lower row long enough to see its movement grow and shrink, then compare that slower change with the quicker movement above.

Make the frequency difference smaller while keeping both sources moving. The envelope changes more slowly. At equal frequencies, this version's initially aligned waves reinforce one another without the same slow pattern of beating.

Keep A fixed and move B towards it from one side. Watch a single location on the lower row through a broadening and a narrowing of its motion. Now move B away again and compare how quickly that alternation returns. Avoid counting every small rise as a separate beat; you are following the larger change in how much motion is available. At a moment when the lower row is quiet, inspect A and B above it. Their contributions can remain substantial while opposing one another. A small sum therefore does not establish that both inputs have become small or that either source has stopped oscillating.

The lower row combines the two values at each sampled position and moment. When the sources are near alignment, their contributions reinforce. As their phases drift apart, they increasingly cancel; later they approach alignment again. The slow pulse belongs to this changing relationship. It is not a third independent source secretly supplying a new rhythm.

The beat readout gives the absolute difference between the two frequencies. This makes a small difference conspicuous in another form: two individually quick oscillations reveal their separation through a slow envelope. The lower row is drawn at half the raw sum's height so it fits the display, so compare the pattern rather than measuring the amplitudes with a ruler.

Try predicting how the envelope will change before moving one control. Then reverse which source has the higher frequency. The absolute difference can remain the same even though you have exchanged the roles of A and B.

<!-- @ -->

This is a visual experiment; it does not generate an audible beat. Adding sound or an independent phase control would extend the comparison. At the synthesis lab, you will change the contributions of several harmonics and ask how their sum can acquire a shape that no single component has.



## WaveFunctions_Synthesis_Lab

Source: commons/maps/WaveFunctions_Synthesis_Lab/final.md

SHA256: 00551106af3e40352ac5c9e88aa8d6fb0bcb8526c1c6ea381740dcd05fca8e6d

# The sum on the bench

In AirMusic one note could begin while another was already fading. Here a wave is waiting to be taken apart.

A bench stands against the north wall of the laboratory. Above it a dark board carries a pale wave with five coloured rows beneath it, and the wave already has a shape when you arrive: a long slope down and a steep rise, four times across the board, drifting to the left. On the bench, at its right end, five sliders stand in a column, one for each row.

<!-- @additive_wave_demo -->

Read the rows before you touch anything. The top row is one smooth rise and fall per cycle; each row below has more, two, three, four, five, and each is drawn smaller than the one above. None of them looks like the pale wave. Press HOLD on the panel at the left of the bench and the drift stops, so a place on the board stays where it is.

Now take the four lower sliders down, one at a time, and keep your eye on the pale wave while each row leaves the ladder. What remains is the top row, drawn larger: a sine. Press BASELINE and the four return together; press H1 ALONE and they leave together. The shape you arrived at is not one thing with a slope in it. It is five smooth returns added, and the slope belongs to none of them.

Bring the second row back on its own slider and choose a place on the board. The amber line marked *mark* is one such place. Before you raise the third slider, decide what the sum will do there: the third row is at a crest, or crossing its middle, or in a trough, and its slider decides how much of that is admitted. Raise it and read the plate on the bench. Its third line lists each row's value at the mark; the fourth adds them and prints the total drawn beside them. With these five visible rows, their sum agrees with the total. The pale wave is built by this loop:

```gdscript
	var value = 0.0
	for h in range(harmonic_amplitudes.size()):
		value += harmonic_amplitudes[h] * sin(phase * (h + 1))
	return value
```

Row h is a sine at h + 1 times the phase, scaled by its coefficient, and the sum is the running total. There is no separate drawing of "the wave". The pale line is this loop evaluated 256 times across two metres,

```gdscript
const WAVE_POINTS: int = 256
const WAVE_LENGTH: float = 2.0  # Visual length in meters
const NUM_HARMONICS: int = 5
```

with the phase running four cycles across the board and the clock adding the drift you stopped with HOLD:

```gdscript
		var phase = t * TAU * 4.0 + _time * TAU
```

A slider changes exactly one number. When a handle moves, the instrument reads the handle's position back as that row's coefficient:

```gdscript
		harmonic_amplitudes[harmonic_index] = harmonic_sliders[harmonic_index].get_normalized_value()
```

Even the first slider only changes how much of the first return is present. This is a visual instrument; it does not play the curve as sound. No slider changes the fundamental's frequency. The rows use integer multiples of one phase, so the vocabulary here is five amounts. Unlike the separately struck bars, these rows cannot choose separate beginnings. A shifted row or a negative amount would need a control this bench does not offer. BASELINE returns them to the table the room was placed with:

```gdscript
		"sawtooth":
			# Sawtooth: all harmonics, amplitude 1/n
			_set_amplitudes([1.0, 0.5, 0.333, 0.25, 0.2])
```

one over n, all five present, the recipe the label calls a sawtooth. The plate's last line names every coefficient that differs from this table, so you can wander and still know how far you have gone.

With the baseline held, look at the rise. An ideal sawtooth jumps; this one climbs from trough to crest over about nine centimetres of a fifty-centimetre cycle. Its descent ripples where the ideal would be straight. Raise the fifth slider and those ripples change. The baseline peaks near 1.58; other amounts can rise further. Five smooth returns can suggest a corner and cannot make an exact one. From across the room the pale line suggests a sawtooth. At the bench its rounded rise remains available to inspect.

Take the second and fourth rows out and leave the odd three; the label offers a name. Move the fifth a little. At first the name stays. Move further and it gives way to Custom Waveform. The curve has changed continuously; the naming rule crossed a threshold. It checks all five amounts relative to the first, allowing a small difference from a recipe. Custom is a place to continue from.

Then remove the row you think matters least and find where its absence shows. It is not in one place, because each row runs the whole cycle. Near zero, a row disappears before its coefficient reaches zero: the display hides values below 0.01 while the sum still includes them. At some marks the plate can report a difference between the visible rows and the total. Something has left the picture without leaving the calculation.

<!-- @ -->

BASELINE restores the five amounts. While HOLD keeps the phase still, the same curve returns to the same place. Let the clock run and those amounts return as a moving shape. Repeating a recipe and repeating an exact instant ask for different things to be kept. Random_Definition takes that question further: what must we retain to bring an unfamiliar result back?



# randomness

Declared order: Random_Definition → Random_Entropy → Random_Remove → Randomness_10_PRINT_Algorithm → Random_Cubes → Random_Rotate_Random_XYZ → Random_Walk → Random_Gaussian → Random_Mushrooms → Random_Space_Geometry → Randomness_Examples_of_Randomness → Random_Pheromone → Random_Space → Random_Game

Museum map-authored order differs: Random_Definition → Random_Entropy → Random_Remove → Randomness_10_PRINT_Algorithm → Random_Walk → Random_Gaussian → Random_Mushrooms → Biome_Cage → Randomness_Examples_of_Randomness → Random_Game → Biome_Ladder_Randomness. Treat this as route drift to inspect, not an editorial recommendation.


## Random_Definition

Source: commons/maps/Random_Definition/final.md

SHA256: 449ee9880e7685f86ea4c66aad7df90a44d4cd065c7d94daf910589ed1600104

# A pattern that returns

In Synthesis Lab, five amounts could bring a familiar curve back. Here, choose a patch of colour you would not have thought to put together.

<!-- @seed_replay_demo -->

Two large grids stand side by side above the controls. Find your patch in one of them, then look in the same place in the other. Press REPLAY and return to those cells before surveying the whole picture.

The patch is back. Press RANDOM, choose something in the arrangement it gives you, and replay that one. RANDOM is allowed to choose a seed again, including the one already here. A result can surprise us and still know the way back to itself.

The seed readout offers a tempting name for the picture. Remember it. Then press +1 DRAW.

The right-hand grid changes while the left keeps its arrangement. The seed has not changed. Look at the cube positions too: nothing has moved sideways to make this difference. One value was requested before the colouring began and was given no colour at all.

Above the grids, two strips show the first twenty-four draws as bar heights. Before the extra draw, their contours match. Switch it on: the right strip begins at draw two. Find its first bar in the second position on the left. The colours changed because the same stream was grouped differently, three numbers per cell. The strips expose a repeatable sequence, not a claim that these few numbers reveal a period or hidden geometric order.

This is the extra operation, applied to the last grid:

```gdscript
if _extra_on and i == _columns.size() - 1:
	for k in range(extra_draws):
		_rng.randf()
```

The underlying sequence has not been rearranged. The generator has moved one position farther into it before the first cube asks for red.

A call to `_rng.randf()` requests one number between zero and one. Colour takes three calls:

```gdscript
mat.albedo_color = Color(
	_rng.randf(),
	_rng.randf(),
	_rng.randf()
)
```

Red, green, blue. Then red, green, blue again. Sixty-four cubes use 192 draws. With one value discarded at the start, what would have supplied green now supplies red, blue becomes green, and the next cube's red enters this cube's blue. Nothing in a draw says that it is red. Red is the use made of its place in these three calls. The old boundaries between colours were made by counting in threes. Shift where that counting begins and the same stream dresses the grid differently.

Press +1 DRAW again to switch the extra draw off. The match returns. This button toggles one discarded draw; repeated presses do not keep adding more. REPLAY reconstructs each grid by restoring the generator to its seed and repeating the chosen procedure. We needed more than the seed's number: which generator, which calls, and which use of their results. The picture's name had left out part of its making.

Use RANDOM again and wait before replaying. The room continues around you; waiting does not advance the generator that colours these grids. Try to predict one cell from its neighbour. Then use REPLAY to recover it. Difficulty guessing from the picture and the ability to repeat its construction are different things you can encounter here. Neither observation makes the other disappear.

There is no need to prefer the matched pair. Keep the extra draw on and compare the two colourings as possible companions. Perhaps the misplaced beginning gives you a relation you want. The line that interrupts a demonstration of sameness can also be used to make another palette.

Move the seed slider slowly. Your hand travels between positions while the readout counts whole numbers, from 0 to 999. The handle can move a little without choosing another seed. The controls offer many seeds, yet every result still arrives as sixty-four cubes with three varying colour channels. Another seed cannot add a cube or let one leave its cell. Those would be other changes to the program. Here, randomness varies what the program has made variable.

The three textile panels offer another comparison. Each begins with seed 41. Diagonals, upright and horizontal marks, then blocks: three pairs of signs receive the same draws. Choose a cell and follow its colour across the panels. NEXT SEED changes the draws in all three; RESET returns to 41. These bolts are held still so their marks can be compared. Chance has not chosen what a mark means. The program supplied that vocabulary before drawing.

<!-- @ -->

The crank across the room makes a generator advance by hand, one state at a time. It gives each request a gesture. We could follow every request here too, but the picture has already asked for 192 of them. What can we leave unexamined and still recognise how it was made?

The next room gathers a sequence into a histogram and an entropy reading. Carry one small patch with you. We are about to ask what a number can retain of an arrangement that was worth looking at.



## Random_Entropy

Source: commons/maps/Random_Entropy/final.md

SHA256: c9616c6da7d990c61ad9837ec7a12bf53c7c5a01e238318a4391115de530c32d

# What the gauge forgets

In the last room, one discarded draw changed which values became neighbours. Here, choose a pair of neighbouring colours before touching a button.

A gauge hangs on a post in the middle of the hall, its number glowing over a desk. On the desk, two hundred small coloured tiles stand in a row, and a pale bar lies before the first forty of them.

<!-- @shannon_entropy_meter -->

Look at the tiles and the ten bars before the large number. Each tile is one draw, in the order it was drawn, coloured by its symbol; the strip along the panel's foot spells out the first forty, the ones behind the bar. Find a colour that comes often in the row and one that comes seldom, and compare their bars. The bars collect every occurrence wherever it fell; the row keeps where each one fell. Choose two neighbouring tiles and ask whether their closeness tells you anything about the height of their bars. Then find another tile of the same colour further along.

The first forty also appear enlarged across the desk's front, labelled “as drawn.” Keep one pair in that row in view.

Now press SORT, on the desk's front. Watch the row and the bars together. The tiles glide into ten blocks, one per symbol; the bars hold their places. Look up at the number. It has stayed too. The pale bar before the first forty disappears: those particular draws no longer occupy the beginning of the sorted row. The plate on the desk's front prints the sorted copy's H beside the reading, the word *equal*, and how many of the two hundred tiles changed place. The enlarged excerpt stays as drawn while the two hundred tiles regroup above it. One part of the desk keeps the old neighbours available beside the new ones. Press SORT again and the upper row comes back as it was drawn.

What the gauge counts is this:

```gdscript
	for s in sequence:
		counts[s] += 1
```

one tally per symbol, and nothing about where in the sequence the symbol stood. The number is made from the tallies alone:

```gdscript
	for c in counts:
		if c > 0:
			var p: float = float(c) / float(sequence_length)
			entropy -= p * (log(p) / log(2.0))
```

Each symbol's share of the two hundred, times the logarithm of that share, summed and negated. A symbol that never occurred is skipped rather than given a zero times an infinity, and the largest the sum can be is log₂ of the alphabet:

```gdscript
	var max_h: float = log(num_symbols) / log(2.0)
```

About 3.32 bits per symbol for ten equally frequent symbols, the ceiling marked at the end of the bar. The reading sits just under it, because this sample from an even source did not divide evenly; the bars record this particular sample rather than the ideal distribution as if it had already happened.

Sorting changed the row without changing any tally. The same counts entered the same loop. Yet the row looks like another object. Keep it sorted for a moment: finding every occurrence of a colour has become easier. Return to the order drawn and a colour has its former neighbours again. Which arrangement would you want to work with? The gauge cannot choose between these uses for you.

Press CONTRAST. A second sample takes the wall: the same ten symbols, the same two hundred draws, from a source that makes the first symbol about twice as likely as the second, the second twice as likely as the third, and so on. The probabilities are normalised across ten symbols; they do not promise fixed counts. In this sample the first symbol occurs 109 times. Its bar towers, and the number falls to about 1.82 bits. Nothing in the alphabet or the count changed; the shares did. The plate names the source and its seed, so you can tell the two samples apart by their provenance and not only by their look. Look closely at the smallest bars and compare them with the counts on the desk. Four symbols did not occur in this sample. They still have tiny marks. The display gives every bar at least two millimetres:

```gdscript
height = max(0.002, height)
```

A visible mark can stand for zero. The tallest bar also reaches the same height in both samples: the display divides by that sample's largest count. Read the counts to compare how many occurrences there were. The ruler has changed with the thing it measures.

Press CONTRAST again and the first sample returns, draw for draw.

The first sample comes from a seeded local generator, giving each symbol the same chance on each call:

```gdscript
		sequence.append(_rng.randi_range(0, num_symbols - 1))
```

The seed lets the gauge recover this sample when it rebuilds. The contrast uses a second seed and a weighted draw; it too can be recovered.

Press DISCLOSE and the formula appears under the title; press it again and the source is named on the panel with a pale bar behind each live one showing the count that source expects on average: one flat line for the even source, a descending staircase for the concentrated one, and the plate prints those expected counts beside its name. Keep pressing and the upper panel withholds its bars and strip, then brings them back. The reading stays. Look down: the desk still carries the tiles and its own account of the counts. Information absent from one display can remain within reach on another. How much would you know if you approached only the glowing number?

Now ask what the unchanged number failed to notice. It did not notice the order, which the sorted view rearranged. It cannot notice a pattern between neighbours, a repeated pair, a rhythm, a message, because it never looked at two tiles at once. It does not know whether the row was worth reading. A high reading is not a certificate of meaninglessness and a low one is not a certificate of value; here it averages surprise using the shares counted in this sample, without consulting the neighbours of a draw.

<!-- @entropy_axiom -->

Beyond the ledger, enter the square glass enclosure. Start at the blue end. The points sit in rows; toward the other end their positions stray further from those rows. Walk sideways as well as forward. The same field can look lined up from one direction and tangled from another.

Here the random offset grows with a point's position along z. The plan stays square; the rule still has a direction. This is a field of displaced points, not a spatial picture of the ledger's number. The meter counted symbol shares. This work moves bodies away from lattice addresses. Putting them in one hall gives us something to compare, and a reason to resist calling every visible irregularity the same entropy.

<!-- @entropy_ruin -->

Beyond the glass, four pale columns carry a lintel. A brick wall fills the space behind them. Choose a joint and wait. A piece drops out of the construction and comes to rest below. A capital loses its place; a shaft becomes a stump. The fallen stone is still here.

Press RUN / PAUSE to hold the scene, or ONE STONE to place the next selected piece among the rubble. The counter keeps two accounts: 116 stones, and how many have moved. The first number stays. Does the building stay with it? Look through the gaps and move around the surviving columns. What was a boundary now lets you see across it.

The program chooses among the exposed tops of the wall and columns. The bottom two courses remain. RESTORE puts the pieces back, resets the seed and waits for you to start it again. The same dismantling order can return; it was never centuries of weather compressed into a minute. The fall and the landing places were arranged too.

Turn toward the museum wall beside the columns. This time the pale courses belong to the hall itself. Its small console offers the same three actions. Let the top stones come down. Through the thinning edge, the view continues beyond the room. The floor stays beneath your feet; a low course keeps the edge. The structure that contained the demonstration has become another arrangement under the rule.

RESTORE closes those openings with the same stones and their collision. A wall is more than an image here: its written arrangement decides where a body can go. What else did we accept as background because it had not yet moved?

The ledger at the entrance counted symbols without keeping their neighbours. These stones make that omission bodily: the same inventory can hold different views, gaps and forms. Nothing has calculated the thermodynamic entropy of this ruin. Before calling its broken outline a higher number, we would have to say what we are measuring. What does a count of stones tell us about what they can still hold?

<!-- @ -->

The last room asked how an arrangement could return. This room asks what survives when we describe one. The histogram retains the counts; the entropy reading condenses those counts further. From that number alone you cannot recover even the bars, let alone the neighbours you chose. In the next room the eligible set becomes spatial: before anything is removed at random, a rule has already decided what can be chosen.



## Random_Remove

Source: commons/maps/Random_Remove/final.md

SHA256: b83c93ec71f22d0b47c49955deddaad0f0c93bf951f376378da5f025124cbd09

# The set before the choice

In the last room, sorting changed the neighbours while the count stayed. Here, find a cube the process cannot choose.

A board of sixty-four small cubes stands on a pedestal in the middle of the hall, numbered along two edges. Its controls sit together on the console in front; a cased account of the set stands to the left. Sixteen of the cubes are amber; the other forty-eight are grey.

<!-- @remove_random -->

Before pressing anything, count the amber ones. Four rows by four columns, from column 2 to column 5 and row 2 to row 5: sixteen possible first choices. The grey cubes are present, numbered, and out of the question. The plate beside the board says so in its own words: RANGE, columns 2–5, rows 2–5, a seed, and `Eligible: 16   Remaining: 16   Removed: 0`.

Press REMOVE ONE. One amber cube turns red for a moment and is gone; its slot plate stays, so the address survives the cube. The line names it: last removed, column such, row such. Remaining: fifteen. Press again. Does the new gap touch the first? Either answer is possible. Watch the amber set rather than expecting the gaps to spread like a stain.

Now point to a cube you know cannot disappear, and press until the amber is gone. Sixteen presses. The final shape was never in doubt: the square you counted at the start, emptied. What the initial picture did not tell you was the order, and the plate under each gap keeps only the fact of absence, not the turn it was taken on.

The rule that decided the sixteen is one question asked of every cube's own position on the board:

```gdscript
	match selection_mode:
		"All": return true
		"Column": return is_equal_approx(pos.x, float(target_column))
		"Row": return is_equal_approx(pos.z, float(target_row))
		"Range":
			return pos.x >= x_min and pos.x <= x_max and pos.y >= y_min and pos.y <= y_max and pos.z >= z_min and pos.z <= z_max
```

The coordinates are the board's, not the hall's: column 3 is the cube at x = 3 on this eight-by-eight, wherever the pedestal stands. The rule runs over every cube once and keeps the ones it admits; a cube already removed is skipped before the question is even put:

```gdscript
		if _removed.has(i):
			continue
		var included := _should_include_instance(_original[i].origin)
```

Only then does chance enter, and it enters only the remaining candidates:

```gdscript
	var offset := _rng.randi_range(0, active_instances.size() - 1)
	var index := active_instances[offset]
```

A whole number between zero and one less than the count of what remains, and the cube at that place in the list. The draw never sees a grey cube; there is no probability, however small, of its being chosen in this run. Removal is a third step again:

```gdscript
	transform.basis = Basis().scaled(Vector3.ZERO)
	multimesh.set_instance_transform(index, transform)
```

the cube's own transform scaled to nothing, the board underneath untouched. Look into the gap. Its small slot plate is still there. The cube also keeps an address inside the MultiMesh, and the remover has kept its original transform in `_original`. The model can stop drawing this body without forgetting how to put it back. At this board, the surface your feet stand on belongs to the museum; these small disappearances make no holes in it. Filter, draw, delete: three decisions that are easy to fold into one word, *random*, and only the middle one is.

Press RESET. All sixty-four cubes return, sixteen amber again, and the line shows the same seed. Empty the square a second time and watch the order: it is the first order, cube for cube, because RESET on this bench puts the generator back to the seed it names:

```gdscript
	if replay_on_reset:
		_rng.seed = run_seed
```

Watch the first few removals twice. After RESET, waiting before your next press does not advance the removal generator. The room goes on around the board; the next choice waits for the button. The same run can be taken slowly or quickly, although a press made during the red highlight is ignored while that removal is busy.

Press NEW SEED and try again. The button selects a five-digit seed and restores the set. It may select one you have already used, and a different seed does not guarantee a different removal order. Compare the histories you get rather than requiring difference as proof of randomness.

Then keep a seed and change the rule. Press ROW: all sixty-four return and only row 3 is amber, eight candidates. Press COLUMN for eight the other way. Keep the same seed for ROW and COLUMN and watch the first few removals in each. Both lists start with eight candidates and shrink by one on each removal. The generator therefore receives the same changing bounds, and selects the same positions within the two lists. The addresses at those positions differ: one list follows row 3; the other follows column 3. Press ALL and every cube is admitted, sixty-four candidates. That change also changes the draw's bounds; retaining a seed alone no longer means retaining the same list positions. Equal counts can leave a spatial difference undescribed: a rule can offer the same number of choices while making different places available, and the seed cannot tell.

Stop before the set is empty. Keep this interrupted pattern for a moment. Perhaps the openings make an arrangement you want. Nothing requires another press. The final empty range would erase the distinction between the orders you have been comparing; halfway through, their different choices can still be seen. A slot remembers where a cube is absent. The visible last-removal line remembers one event. The full history remains in `removal_log`, available in the source and the review, beyond what this plate shows.

<!-- @random_removal_arena -->

Behind the board, the set becomes a floor. Ninety-nine cubes span a basin inside a glass frame. Pause on the dark edge before entering. That edge is permanent. The amber cells are not.

Entry asks for one removal. As you walk, each further sixty centimetres of accumulated horizontal movement can ask for another; a pending draw must finish first. One cell turns red for eight-tenths of a second. Then its mesh disappears and its collider is disabled. The gap is now something your body can fall through. Fire burns at the base of the basin.

The board hid a drawing while leaving its little slot plate. This version connects the same selection to support:

```gdscript
func _removed(index: int) -> void:
    colliders[index].set_deferred("disabled", true)
```

The draw chooses from the floor's remaining cells, not from the cube nearest your foot. Walking makes a choice happen; it does not tell the choice where to land. Try the permanent apron and look back. A disappearance becomes a fall only because the code also withdraws support.

REPLAY restores the cells and their colliders, and starts the same seeded order again. NEW SEED restores them with another order. Both controls stand together outside the entrance. Keep the distinction between the small board and the floor: here removal has acquired a consequence because another piece of code joined it to collision.

<!-- @ -->

Ask now whether a random choice can be fair to a cube that was grey. Within the amber set the draw is even; the grey were decided before it ran, by a rule you can read and change, and the seed that makes a run repeatable has no say in it. Carry the changing set into the next room, where a walker takes its steps from draws like these and the set of places it can reach is decided one step at a time.



## Randomness_10_PRINT_Algorithm

Source: commons/maps/Randomness_10_PRINT_Algorithm/final.md

SHA256: 259612018d5721a305e97399d9c5652c5db6917fe019651bca5774c8f4fd8535

# A maze made of marks

When do independent marks begin to look like a maze?

<!-- @ten_print_maze_3d -->

Choose a small group of cells and identify the two diagonal orientations. Follow one contour across several corners. Before calling it a route, ask what you have actually followed: a continuous-looking mark, the edge of a barrier, or an open passage between barriers?

Watch a diagonal change and compare the connections around it. One local replacement can alter a much longer-looking contour. The field can reorganise without a designer redrawing every enclosure by hand.

Stay with one corner shared by neighbouring cells. Notice which diagonal endpoints reach it and which turn your attention elsewhere. When a nearby mark changes, first describe the immediate difference at that corner, then follow its consequences farther along the contour. You may discover that a path you were reading has become two separate pieces, or that separate pieces now appear joined. Compare that reading with the open space around the marks. A connection between drawn segments and a connection between passages are different observations. Keeping one corner as your reference makes the larger rearrangement traceable instead of treating the whole field as a new unexplained maze.

The generating rule makes one of two choices for each cell. Neighbouring marks meet because the grid places their endpoints in shared positions. A larger visual structure appears through those local adjacencies, even though the individual choices did not include an instruction to make that particular structure.

This version adds an ant and navigation calculations to the marks. Those are separate procedures. A pattern that looks like a maze does not by itself guarantee an open route from its entrance to its exit, and a changing field can invalidate a route that previously seemed available.

Read the same arrangement once as a textile and once as a passage system. The first reading may care about rhythm, density and contour. The second makes additional demands about clearance, connection and destination. Neither reading changes the original two-choice rule, but they ask different things of its result.

There is no need to treat the larger structure as either secretly planned or entirely meaningless. A simple local procedure and a particular representation can produce relationships worth investigating. The useful question is which relationships are supplied by the rule and which promises your interpretation adds.

<!-- @ -->

Next, the die offers six visible outcomes instead of two marks. You will compare individual results with a growing record, and ask what repeated observations can establish that one throw cannot.



## Random_Cubes

Source: commons/maps/Random_Cubes/final.md

SHA256: a7b9c7d24246a4be627e2e3dc74492aac82ea2b9d4a69ac2f38144775a48536f

# One throw and many throws

How much can one throw tell you about a die?

<!-- @dice_throw -->

Take the die and throw it onto the table. Wait for it to settle, then compare the upward face with the result shown. Watch what the reward does, but do not let the most spectacular result stand in for the whole experiment.

Throw again. Look at the face counts and the running mean as well as the latest answer. A short sequence can contain repetitions or missing faces without settling the question of whether the die is fair. The record becomes useful because it keeps outcomes that your attention might otherwise replace with the newest one.

Before your next throw, choose one reported face to follow through several results. After each settlement, check whether its count changed, even when another outcome attracted your attention. Also compare the mean before and after a high or low result. An outcome above the current mean pulls it upwards; an outcome below pulls it downwards. Neither direction alone tells you whether the die became fairer. This small record separates a face's frequency from the numerical average of all faces. If you change your throwing method, mark that change in your own account so that a later pattern is not silently attributed to the die alone.

There are six possible reported faces. If each were equally likely, their mean value would be 3.5. That is a statement about a distribution, not a face you can roll and not a promise that every small batch averages exactly 3.5. The observed mean belongs to the throws made so far.

Here the result is read from the settled orientation of a simulated physical die. Its shape, contact with the table and the way you throw all contribute to what happens. A cube's symmetry is a reason to investigate fairness, not a proof that every practical way of throwing it produces equal probabilities.

Compare a gentle throw with a more vigorous one. Keep track of which method produced which outcomes; combining the records immediately would erase the intervention you are testing. A larger reward also tells you about the rule converting pips into falling balls. It does not make one outcome more earned than another.

<!-- @ -->

The next room shifts attention from a single outcome to changes accumulating in an arrangement. Carry forward the habit of naming what is allowed to vary before calling the whole result random.



## Random_Rotate_Random_XYZ

Source: commons/maps/Random_Rotate_Random_XYZ/final.md

SHA256: 4ab6e6a1681f6ad918c3f9d09914c2f4836c995f0d7e0e8edf1279a62dd34c6e

# What remains in a changing stack

Which part of an arrangement can change while its pieces remain?

<!-- @random_decay_multimesh -->

Watch the two stacks long enough for their changes to begin. Choose one piece and compare its orientation with the line of its neighbours. Then look at its position and colour separately. Use TOGGLE to pause the process and inspect the difference; RESET restores the starting arrangement.

The changes do not happen uniformly across the whole display. Pieces acquire different amounts of drift, rotation and darkening. Yet their size stays fixed in this version. An arrangement can become less regular without every object shrinking, disappearing or becoming a different kind of object.

Pause while a chosen piece remains easy to recognise. Compare its edges with the original stack direction, then compare its centre with neighbouring centres. A piece can turn substantially while moving only a little, so one broad description of disorder can conceal different changes. Resume briefly and pause again, keeping the same piece in mind. Check its colour separately from those spatial comparisons. If it becomes difficult to identify, RESET gives you the ordered arrangement again. The renewed view restores a reference for comparison; it need not promise an identical sequence of later perturbations. Try explaining one changed relation before judging the whole stack's appearance.

The demonstration keeps a changing state for each instance. Random perturbations contribute to its movement, while bounds, damping and a gradually increasing decay value constrain what those perturbations can do. The result accumulates over time. A small angular change repeated many times can produce a visibly altered orientation even though no single step seems dramatic.

Pause and describe the result without using the word decay. Say which pieces moved, which turned and which changed appearance. This forces the general impression back into observable distinctions. The label names the model's presentation; it is not a measurement of thermodynamic entropy or a complete physical explanation of how a material deteriorates.

The two stacks also have different configured rates. Their difference therefore cannot be attributed only to their shapes or to the number of pieces. A controlled comparison would need to match those other conditions before isolating one cause.

<!-- @ -->

A rotation-only version at matched rates would be a useful next experiment. The random-walk room takes one accumulated quantity, position, and gives it a clearer history. There you can separate the next-step rule from the trail the display keeps of earlier steps.



## Random_Walk

Source: commons/maps/Random_Walk/final.md

SHA256: 23e616ef209e5ebdd78bbd6361314dd817d561f68421d6737d6d00fe2c7b73bc

# The trail is already elsewhere

What does a trail remember that its next step does not use?

<!-- @random_walk_terrarium -->

Five beads move inside a glass tank on a dark cabinet. One is bright red. The other four are dimmed, still moving. Follow the red one for a moment. A turn begins to look like hesitation; a curve seems to be taking it somewhere. Choose a place you think it will reach. Keep that expectation beside what happens.

The keypad offers 2D, 3D, LEVY and RESET. Begin with 2D. The trail can turn in any heading, yet it never leaves its level. Walk around the tank: the thin arrangement holds. Press 3D. Now the bead can rise and fall. A route that looked crowded from one side may open when you look through another. Find an apparent crossing and change your viewpoint. Do the two stretches meet, or did you put them together by looking?

The previous room let a draw choose a cube from a set. Here the draw proposes a movement from the position already reached. The earlier rooms have supplied the parts: a point, coordinates, a line made from samples, an array to keep them, an increment to add. In 2D, one number becomes a heading:

```gdscript
		WalkMode.WALK_2D:
			var angle = _rand() * TAU
			return Vector3(cos(angle), 0, sin(angle)) * step_size
```

The proposed step is 0.015 metres long. Its y component is zero. The code has room for three coordinates and has declined to change one. That flatness is a decision made each time the function returns.

In 3D two draws choose a direction on a sphere; the proposed length stays the same. LEVY draws a length too. Try it, then return to 3D. Look for what the longer movements do to the tangle. The cabinet is using this particular rule:

```gdscript
			var u = _rand()
			var levy_step = step_size * pow(u + LEVY_OFFSET, LEVY_EXPONENT)
			levy_step = minf(levy_step, step_size * LEVY_STEP_CAP)
			return direction * levy_step
```

The offset is 0.01, the exponent −0.5, the cap ten. Every length is drawn along this curve; there is no separate switch for a spectacular leap. The largest permitted proposal is 0.15 metres. Even this mode's long reach has an edge.

Look near the glass. A bead approaches, turns, stays inside. There is no test for whether it wants to return. First the code proposes a position; then the enclosure changes it:

```gdscript
		var step = _generate_step()
		var new_pos = _walker_positions[i] + step

		# Boundary reflection
		new_pos = _reflect_boundaries(new_pos)
```

For a wall at x = 0.25, an attempted endpoint at 0.27 returns as 0.23. The overshoot folds back. The displayed segment joins the retained positions on either side of this operation. It does not draw the contact with the wall. A short stroke can therefore stand for a longer proposed movement. The line we learned to trust as a record has left something out again.

The next few lines keep another difference:

```gdscript
		# Record trail
		_walker_trails[i].append(_walker_positions[i])
		if _walker_trails[i].size() > trail_length:
			_walker_trails[i] = _walker_trails[i].slice(1)

		_walker_positions[i] = new_pos
```

Read the order aloud. Keep where we were. Shorten the record. Put the bead where we are now. At step 300 the trail holds positions 100 through 299; the bead has reached position 300. The drawing is already behind the body, and the beginning has gone. Its absence from the glass does not mean those steps were never taken.

Nothing in the step generator reads this trail. Erasing its stored points in a controlled source test leaves the subsequent positions unchanged. The program still has memory: a current position, a generator state, a counter, a rule. What it lacks here is a way to consult the drawn history when choosing a heading. To make a walker avoid its own trail, that relation would have to be built.

The wing beside the tank carries the logbook; its buttons now share the front console with the mode controls. ONE and ALL change which beads and trails are bright. All five continue stepping under either view. Following one has changed your access to the population, without sending the other four away.

Read the seed, then press RESET. The named walk returns from the centre. Compare it at the same step count, with the same mode. NEW SEED chooses a five-digit number different from the current one; an older number can return later. Changing modes retains the seed but spends its draws differently. A number alone is not the whole recipe for a path.

Two times sit together on the plate. Simulation time counts the accepted steps at thirty per second. The frame clock adds the time supplied to the running process since reset. A stalled frame can separate them: this implementation accepts at most five steps in one frame and discards the excess. In a controlled two-second frame, the clock gains two seconds while the walk gains only a sixth of a simulated second. There is no pause control on this cabinet. RESET starts its account over while the museum continues.

Below, MSD measures the five beads' average squared distance from their release point. Watch it increase or decrease. The glass bounds it; the number does not report how much trail has accumulated or how far the beads have travelled. A return toward the centre can lower it while adding more line.

<!-- @random_walk_128 -->

Cross the bridge over the narrow basin and enter the larger glass frame. The gallery and the experiment remain at the same level; the gap distinguishes their floors. Its ten-metre field keeps another account of a walk: a visited cell rises. Four possible directions are enough to change the ground. The working lattice has thirty-two cells on each side, despite the older name `random_walk_128`.

Look at a high place. It records repeated visits; it was not selected as a destination. A small rule has become a spatial obstacle through what the surface retained. Compare this ground with the trails in the instrument. Both keep something of movement, and neither keeps everything. The surrounding glass names a boundary of the experiment; the openings let you pass through or watch from outside.

<!-- @ -->

Stay with a shape you had begun to read as a creature. What would its next step need to know for that reading to become a capability? The missing relation is an invitation to make another rule. For now, we leave with a path whose history exceeds both its current position and the drawing we can still see. In Random Gaussian, we gather draws in another way and ask what shape appears when we count where they land.


<!-- @random_draw_dot -->

## A hand with company

Pick up the drawing dot. Move your hand slowly across the space, then hold it still. The small green tip keeps wandering. What part of this line belongs to your movement?

This is the grip from Trace with one addition. Thirty times per second, while you hold it, a random direction adds a small step to an offset. The next step starts from the offset already reached:

```gdscript
walk_offset = (walk_offset + direction * STEP_SIZE).limit_length(RADIUS)
tip.global_position = _grab_point.global_position + walk_offset
```

Your hand carries the origin; the tip walks around it. Each proposed step is 1.2 centimetres, and the offset cannot exceed 25 centimetres. At that boundary, the program shortens an outward proposal. Its freedom has a radius.

Press HAND / RANDOM to clear the line and draw with the hand alone. Switch back and try the same gesture. The point-count display still counts retained samples, as it did in Trace. The random clock proposes thirty steps a second, but the visible trail is sampled by the drawing process; a stalled frame can miss intermediate positions.

CLEAR / REPLAY restores the random seed and clears the trail. The random steps can repeat. Your hand need not. Let go and the wandering stops: this encounter gives chance movement only while someone holds it.



## Random_Gaussian

Source: commons/maps/Random_Gaussian/final.md

SHA256: 847f74319596b18679df31dd2d53f945cb6daeee08ebe6976ca72d8fb485529b

# The shape we counted

What changes when the values stay where they are, but we count them differently?

<!-- @distribution_sampler -->

Yellow beads fall toward a row of blue bars. Some bars grow; others wait. An orange line already knows the shape we have come to expect. Look at the beads and the bars before letting that line finish the picture for you.

The cabinet stands in the middle of the hall, its controls facing you as you approach. The other distribution studies stand around it. Its left panel offers UNIFORM, GAUSS, POISSON, EXPON and CLEAR. On the right are BATCH, PAUSE, NEW SEED and BINS. GAUSS is running when you arrive.

Press PAUSE. Watch what keeps moving. The beads already released continue to fall. The plate counts them as “in flight” until they land; only the issuing of new draws has stopped. Wait for that count to reach zero. The histogram is now still enough to describe. Where is its highest bar? Where are its gaps? Which of those observations had the word “Gaussian” encouraged you to expect?

CLEAR empties the display and restarts its named seed. While paused, it stays empty. Press BATCH. One hundred values are counted immediately, without the falling animation. Describe this particular arrangement. Press twice more, reading the total each time. A gap may close; another bar may stand further from the pale bar behind it. More evidence does not promise that every part of the picture will improve at the next press.

Those pale bars carry the model's expected counts at the current number of landed values. Blue and pale share a count scale. Their disagreement is available to examine; the pale shape does not instruct a blue bar to grow toward it.

Now press UNIFORM. The bins clear, the seed stays, and three batches again give three hundred values. Keep the same thirty bins. Each pale bar now expects ten. Compare the two arrangements at equal count before deciding which looks more irregular. UNIFORM has used each number directly:

```gdscript
		DistType.UNIFORM:
			return _rand()
```

GAUSS has given two numbers another job:

```gdscript
		DistType.GAUSSIAN:
			var u1 := maxf(_rand(), 0.0001)
			var u2 := _rand()
			var z := sqrt(-2.0 * log(u1)) * cos(TAU * u2)
			return _fit(gaussian_mean + z * gaussian_std)
```

There is the logarithm, the square root, the turning cosine again. The mean is 0.5; the standard deviation is 0.15. The code directly transforms draws into an approximation to a normal distribution. It does not wait for an arbitrary collection of values to become Gaussian. UNIFORM will keep its own law as more draws arrive.

Read the small guard on `u1`. Zero cannot enter the logarithm. Values below 0.0001 share that lower bound, limiting the computed reach to about 4.29 standard deviations. Even before a value reaches the screen, the numerical procedure has made a boundary. The ideal orange model and this finite computation are close enough to compare, and still worth distinguishing.

There is another boundary at the screen itself:

```gdscript
func _fit(raw: float) -> float:
	if raw < 0.0 or raw > 1.0:
		_clipped += 1
	return clampf(raw, 0.0, 1.0)
```

The previous room's glass reflected an overshoot. Here a value past one is kept at one; a value below zero is kept at zero. Its distance beyond the edge is lost from the retained value. Look at the plate's clipped count and its two edge-bin counts. They need not agree: an edge bin also contains values that were inside the display all along.

Try EXPON. More values gather near the left. Occasionally a draw from its long right tail is clamped at one. A finite run need not contain such a draw; the model's tail is a probability, not an appointment. NEW SEED lets another run take place. Its number differs from the current one, though an older number can return later.

Return to GAUSS or UNIFORM, pause, clear, and collect three batches. Now press BINS. Thirty become sixty, then ten, then thirty again. The landed count stays at three hundred. Nothing has been sampled again. The stored values are assigned to new intervals:

```gdscript
	for v in _values:
		_bins[clampi(int(v * num_bins), 0, num_bins - 1)] += 1
```

Watch the mean and the σ marked “binned.” They can change too. The plate estimates each value by the centre of its bin, so changing the intervals changes that estimate. The values have stayed; the account of them has moved. Return to thirty bins and the earlier account returns.

Look back at the height of the picture. Blue bars are scaled against the tallest blue bar, with a small visible baseline even for an empty bin. A handful of values can already occupy almost the whole height. The orange model shape has its own scale. Its curve cannot tell you how much evidence has arrived; the count can.

CLEAR and repeat the batches if you want to point at the same sample twice. That return depends on the seed and the procedure, including which law spends the random draws. It gives a discussion somewhere to stand while the surrounding museum continues.

<!-- @ -->

We have met a centre, but have not discovered a command to belong to it. Frequent under a chosen model does not mean preferable, healthy or correct. Before carrying this shape onto a body, ask what was measured, what the bins kept, and what the edges absorbed. In Random Mushrooms, values like these become differences among forms. Which features of those bodies will be allowed to vary?



## Random_Mushrooms

Source: commons/maps/Random_Mushrooms/final.md

SHA256: 46ad26cd55dac8ef7ed5ace022d7c54fc0080ee64d200e45ea596974d257c128

# Which differences were invited?

In the previous room the numbers gathered into bars. Here they have caps and stems. Which differences can this recipe make?

<!-- @mushrooms -->

The glass enclosure around the bed makes a population into a place you can enter. Its front opening leaves room beside the specimen table; another opening is opposite. Begin at the compact console, then move among the mushrooms. The cage holds an experiment, not a claim that these bodies exhaust what a mushroom could be.

A bed fills the middle of the hall. Before it, six mushrooms stand on numbered discs. Look past the table and choose two in the bed that seem related. A cap bends out over a stem; another, smaller, repeats its proportions. Before pressing anything, decide what you are using to recognise their relation.

Press SHOW. A magenta ring moves to the next disc, and rings with tall pins mark its copies in the bed. Keep pressing until the plate names the template you were following. There may be many copies, or none in this particular population. The table still gives the absent form a place.

The discs run from 0 to 5: tan cap, red cap, flat brown cap, tall white mushroom, puffball, glowing cap. These are construction recipes rather than six biological species. Within this build, each recipe has become a template. A copy carries its template's details with it:

```gdscript
		var mushroom = mushroom_types[type_index].duplicate()
		mushroom.name = "Mushroom_" + str(i)
```

Look at two marked copies again. Their positions, turning and scale can differ. Their material situation can differ too: a cap lit by a neighbour need not look like the same cap in shadow. SHOW names a construction relationship; it cannot make every appearance identical.

Now press SIZE. The bed is rebuilt. Find your pair. Their places and orientations remain, but the extra scaling has gone. They have not all become the same physical size: a tall template remains tall beside a low one. The plate says “scale 1 · template sizes kept.” What did you think the button would remove?

For a scattered mushroom, the scale had been chosen here:

```gdscript
		var scale_factor = _size(0.7 + _rf() * 0.6)  # 0.7 to 1.3
		mushroom.scale = Vector3(scale_factor, scale_factor, scale_factor)
```

And the switch decides what to do with that value:

```gdscript
func _size(v: float) -> float:
	return v if size_variation else 1.0
```

The draw still happens when the scale rule is off. Only its use changes. If the program skipped the draw, the following decisions would receive different numbers and our comparison would slip away. Press SIZE again. The earlier scales return.

The seed on the plate makes this return possible under the same recipe. REGROW rebuilds the population and its ground. NEW SEED chooses a number different from the current one; it does not promise a number never used before. A new build can also change details inside a template, such as the puffball's bumps. Six available recipes do not mean six eternally identical objects.

Press KIND until the plate says “scattered.” Count what it calls accepted and rejected. Together they account for eighty candidate positions. The total mushroom count can be larger: two other routines add bodies later. First look at the spaces between the scattered ones. Which gaps seem intentional?

Continue to “rejected.” Grey markers appear at candidate positions that the placement rule refused. They were never mushrooms that died. At each proposed position, a noise field was consulted:

```gdscript
		var noise_val = noise.get_noise_2d(pos_x * 2, pos_z * 2)

		# Skip if noise value is too low (creates natural clearings)
		if noise_val < -0.3:
			_rejected.append(Vector3(pos_x, get_ground_height(pos_x, pos_z), pos_z))
			continue
```

Even the source calls them “natural clearings.” The marks let us read what that phrase stands for here. A number crossed a threshold. In Gaussian, a value beyond the display was kept at its boundary. Here an unsuccessful candidate leaves a recorded position and no body.

Keep pressing KIND until it says “rings.” Green marks pick out the members added by the circle routine. One circle is requested at this bed's six-metre size. Find its arc, then imagine the rest continuing beyond the boards. Its members were given equal angular intervals:

```gdscript
	for i in range(count):
		var angle = (2.0 * PI / count) * i
		var pos_x = center_x + cos(angle) * radius
		var pos_z = center_z + sin(angle) * radius
```

The radius helps set the requested count. Positions outside the bed are skipped. The plate's bracket counts the members actually placed; it does not show the missing ones. A partial circle can carry the trace of two decisions: draw the ring, then admit only what fits.

The next KIND is “clusters.” Two cluster routines choose their own centres, spreads and templates. Their members receive random angles and distances. They do not pass through the scattered candidates' noise test. Bodies from different routines can overlap. Nothing here negotiates for room.

Walk round the west and south margins. Three larger red-capped mushrooms stand just inside the boards. They come from a separate pickable scene and are counted separately. A similar cap has acquired another capability. In the headset, hold one and bring it close to your face: its eating rule starts a visual effect with a ten-second hold and a fade in and out and the mushroom dissolves. The garden has offered a way to change the looking, as well as the thing looked at. The desktop carry lets you inspect it, but holds it beyond that eating distance.

At the smaller arrival stage, wait for a silhouette. Another place is chosen from those still empty. Six arrivals fill it; the program does not keep producing bodies without somewhere to put them. Press REPLAY and watch the places return in the same order.

Choose one figure and press DRESS. A hem widens, a collar appears, the pleats take another colour. Try again. How far can this wardrobe take the figure?

Now press FORMS. Branches extend from the garment. Read the dress number: it has stayed. Switch FORMS back and the earlier dress returns. You did not need a luckier draw to find the branches. They needed another instruction. DRESS samples within the available recipe; FORMS switches between two recipes, one of which adds branches. Neither button changes the six places or the arrival order.[^chance-repertoire]

These figures still turn towards you as flat images. Their new outlines give them no new way to walk, touch or refuse. A different appearance has not yet become a different permission. Which of those changes would you make next?

Beyond the garden, three couture bodies stand together. All begin with the hare head and sheath garment. Their seeds are 41, 42 and 43. Look for differences in proportion, print and pose before pressing NEXT SEED. Three more individuals appear under the same two named constructions.

Keep this trio and press GARMENT. The seeds stay while the sheath gives way to a crinoline, then quilting, bloom and fringe. The body generator receives another construction instruction. Some details may change with the construction too: a seed is not a promise that every branch of a program spends its draws in the same way. RESET restores the starting trio. The garment's possibilities were authored; chance finds individuals within them. Which possibility would you want to add to this wardrobe?

<!-- @ -->

The sampled sizes never grow a seventh template between two others. That would need another rule. Yet these rules could carry other forms, other ranges, other permissions. Which difference would you add first, and what would have to change to let it exist? Carry that question into the recovered gallery: what can the same act of drawing a value become when it meets a brush, a tally or a growing path? After that, Random Game asks your body to answer in time.

[^chance-repertoire]: The “Randomness” chapter of *10 PRINT CHR$(205.5+RND(1)); : GOTO 10*, pp. 125–127, discusses chance operations in Cage, Kelly and Morellet: variation takes place within constructed parameters and arrangements. The distinction between sampling a wardrobe and changing its repertoire is this hall’s experiment, rather than a claim that chance abolishes authorship.



## Random_Space_Geometry

Source: commons/maps/Random_Space_Geometry/final.md

SHA256: 29bf71622aa8c6b6ffb794168029e019f20a1afacef24c3a7a44ca96f7c2e8e4

# What neighbours share

What makes neighbouring random heights belong together?

<!-- @perlin_noise_bridge -->

Look closely at neighbouring columns in the two small grids. On the WHITE NOISE side, compare one height with the next. On the PERLIN NOISE side, follow a group of heights across several cells. Describe the difference before calling either one a landscape.

Keep SEED fixed and adjust FREQUENCY. Watch how the scale of features changes on the coherent side. Then choose another seed or press RESAMPLE and repeat the comparison. The two kinds of field remain distinct even when their particular arrangements change.

Choose three adjacent columns on each side and describe their relative heights: rising, falling, or turning between the two. Move one position along and repeat. You are examining a local relationship rather than asking which grid contains the single tallest column. At a lower frequency, follow how far a broad feature extends on the coherent side; at a higher setting, repeat along the same row. If a small region happens to look similar on both sides, examine a longer stretch before declaring the procedures equivalent. Independent draws can produce a chance run of similar heights, while a coherent field can still contain differences between nearby samples.

Independent samples supply each white-noise height separately. Perlin noise supplies related values at nearby positions through a spatial construction. Those local relationships make broader features possible. The two grids use comparable height displays, but they do not draw from identical distributions merely because their values fit within similar bounds.

The seed makes each construction repeatable under the same settings. Frequency changes how rapidly the coherent field varies across the sampled positions. You are changing a rule about relationships in space, rather than choosing every column individually.

Look for something terrain-like in the independent grid, then for an unexpected edge in the coherent one. Perception is good at supplying landscapes. That skill can help you notice a structure, but it cannot establish that erosion, water or geological forces produced it. These are height fields with a colour mapping, not miniature geological histories.

<!-- @ -->

One productive misuse is to withhold the landscape reading and describe only local differences. A future shared scale or alternative palette could make that comparison easier. The next room uses random samples for estimation: their placement will matter because a numerical answer depends on how the sampling rule covers a region.



## Randomness_Examples_of_Randomness

Source: commons/maps/Randomness_Examples_of_Randomness/final.md

SHA256: 8700525e3fec1c1dbf226b97a001a1b9c50c8c2c3a697c7cca9c4e0a656677dd

# What chance may change

Four works have returned to the gallery. Walk toward the painting on the floor, then take either side around its frame. The dartboard waits to the right, the pipes farther along to the left, and a changing particle study near the rear. Each gives chance a different job.

<!-- @pollock_painting_in_3d -->

Stand at the near edge of the canvas. Find a thin line, a broad mark and a cluster of small splatters. Wait for another layer, then follow the brush cursor as it traces a path. Walk around the frame. A mark that was distant is now close enough to inspect.

This is a Pollock-inspired generative homage, not a reconstruction of a particular painting. The program chooses positions, colours from a fixed palette, drip sizes and line widths. A line begins with a sampled direction, then turns by small sampled angles as it advances. At an edge, the direction reflects back toward the canvas. Chance can bend the route; it cannot enlarge the canvas or invent a colour outside the palette.

The marks are painted into a two-dimensional image shown on the floor. The small three-dimensional cursor follows the generated stroke path. It lets us watch a procedure; it is not a brush whose movement you are controlling, and the drops are not a simulation of falling paint.

Choose a passage you like. Which part could have arrived differently? Which part was already decided by the palette, line rule, canvas and interval between additions? Calling the result random can make those authored choices disappear from view. The work becomes more interesting when we keep them visible.

<!-- @monte_carlo_dartboard -->

Move to the dartboard's console on the right. If new marks are appearing, press AUTO to pause them, then RESET. Press THROW and find the new point. Compare its location with the circle, then check which counter changed. Add a few more points individually before using AUTO to build a larger sample.

An inside point increases both the inside count and the total. An outside point increases only the total. Before requesting another point, predict what each possibility would do to the estimate. Check with THROW, and explain the change from the counters before looking at the distance from pi.

The circle is inscribed in a square. When points are sampled uniformly across that square, the fraction landing inside estimates the fraction of area occupied by the circle. Multiplying that fraction by four gives the displayed estimate of pi:

`estimate = 4 × inside / total`

A growing sample does not require every new estimate to improve. Repeat the prediction when many points are already present: one addition usually changes the ratio less. A steadier number still depends on how the points were sampled.

THROW requests a generated sample. You are not aiming a physical dart with your hand. A sampler that favoured the centre would tend to count too many points inside; adding more of those points would not repair the bias. Pause AUTO and RESET to compare another run. The board keeps at most 500 darts, so RESET also begins a new sample when the board has filled.

Here chance chooses the evidence. The circle's boundary and the counting rule remain fixed. Who gets to decide that the sampling procedure covers the space fairly enough for the answer we want?

<!-- @pipe_dream -->

Cross to the pipe study on the left. Follow a length to its next corner, then look for a place where the path doubles back near an earlier passage. If growth has finished by the time you arrive, the whole retained path is still available to inspect.

The pipe advances in one of six axis directions. A preference sometimes keeps it moving straight; otherwise the program shuffles possible turns and takes a direction that stays inside its bounds. It rejects an immediate reversal. It does not keep a list of occupied cells, so crossing an earlier route is allowed.

The default run stops after 180 segments. A dense tangle therefore does not certify that the volume has been filled, or that every corner was reached. The limit ends the run whether or not its shape looks complete to us.

Look across the empty spaces between pipes. The same local rules could have left different gaps. What would change if a previous visit made a place forbidden? That would add a memory and a new restriction, not merely turn up the amount of randomness.

<!-- @extreme_randomness -->

The particle study occupies the last bay on the right. Stay through a full cycle. Its five chapters change about every ten seconds. Watch for a change in the particles' arrangement as well as their movement; the chapter transition restages them.

For this gallery, every chapter stays inside the same spherical boundary. A particle that would escape is brought back to the edge and its outward velocity reflected. This added limit keeps the changing study above the floor and within its bay.

In the first chapter, random forces change velocities that persist from one frame to the next. Damping slows them, and a boundary turns escaping particles back. Successive positions retain a history. They are not independent points redrawn across the whole volume.

The noise chapter follows a smooth field made from sine and cosine functions in this implementation. The pattern chapter adds spiral motion and oscillation to its opening arrangement. The emergence chapter combines separation, alignment and cohesion with small random nudges. The evolution chapter ranks particles by their distance from a moving target; the leading tenth influence the others.

These are five sketches of different procedures, not five strengths of the same white noise. Nor is the final chapter a population that breeds: the same fixed set of particles keeps moving under a selection rule. A title gives us a starting question; the update rule tells us what is actually happening.

<!-- @ -->

Look back toward the painting. In one work, chance chose marks; in another, samples to count. It chose permitted directions for the pipe and different kinds of variation within the particle study. In every case something decided what a random choice was permitted to change.

Carry that question through the rear exit to Random Game. When a platform moves or a wait changes, distinguish the rule you can learn from the event you still have to discover.



## Random_Pheromone

Source: commons/maps/Random_Pheromone/final.md

SHA256: c5f7c334ffc655035c960f245caa1292af2c63b1d893ea240c5947c8487dd9cb

# A path that recruits its next visit

What changes when a walker helps make the evidence its next decision will read?

<!-- @pheromone_terrain -->

Choose a small patch of terrain and follow more than one visit. Compare it with a quieter patch nearby. Watch where traces gather and where the surface begins to rise, then look for later walkers returning through those regions.

Keep one rising patch as a landmark and attend to the approaches made towards it. Does traffic return along a familiar direction, arrive from several directions, or shift towards a nearby patch? Compare a short interval with a longer observation before calling a route permanent. The visible height lets you retain a place in view even while the current signal changes. That makes it possible to ask whether present movement is still reinforcing an earlier concentration of visits. If the answer is difficult to see, say which evidence is missing: the current scent, the timing of deposits, or a clearer trace of individual movement.

Each visit leaves pheromone and changes the local height. Later choices can favour a stronger pheromone signal, while some movement remains random. A path can therefore become established partly because it has already been used. No walker needs a complete plan of the resulting network for this feedback to occur.

This differs from the terrarium's memoryless step rule. There, the trail helped the observer read the past without steering the next step. Here the environment keeps a signal that participates in future decisions. The mark has become part of the mechanism.

The signal and the raised terrain do not keep identical histories. Pheromone decays; the surface records accumulated visits in another form. A visually prominent ridge and the strongest current scent therefore need not mean exactly the same thing. Distinguish what you can see from what the movement rule reads.

Try identifying a route that may have begun as an accident. Repeated use can reinforce it, but reinforcement does not establish that it is globally shortest, fairest or best. The procedure rewards a particular local signal, and that signal partly reflects its own earlier choices.

<!-- @ -->

A walker that avoided the strongest trace would make a different world from the same act of leaving marks. That comparison is an available direction for development rather than a control offered here. Next, the noise mixer returns to field construction: several contributions at different scales will combine without depending on a history of visits.



## Random_Space

Source: commons/maps/Random_Space/final.md

SHA256: 5ee4f8d430a547742015918ba2cbe935dfd120c197d07f6c27115019bd9b466a

# Layers that look like land

How much of a landscape can be made by repeating a rule at different scales?

<!-- @noise_mixer -->

Reduce OCT to one and look at the broad changes across the picture. Add layers while keeping LAC and PER fixed. Follow one large feature and see how finer variations appear around it rather than assuming each new layer replaces the previous one.

Next adjust PER. Compare how strongly the smaller-scale contributions stand out. LAC changes the frequency ratio between successive layers; PER changes their relative amplitudes. SEED selects another set of offsets, providing a different arrangement under the same kind of construction.

Begin with OCT at one and inspect a broad light region beside a broad dark region. Increase the layer count while tracking their boundary. Then reduce PER and ask which finer variations become less prominent. Return to one layer before changing LAC: with no later layers to separate in frequency, that comparison gives you a baseline for what the spacing control concerns. Add layers again and watch its influence become available across them. Describe a change in feature size separately from a change in colour contrast. The picture remaps its range, so those two visual changes need not report the same numerical difference.

The field adds scaled versions of a base function. Each layer samples at another frequency and contributes another weighted value. In this display the base is made from several sine expressions, so the noise-like surface connects back to the synthesis lab's lesson: a complex appearance can come from adding simpler contributions.

Colour supplies another part of the reading. Low and high values are mapped through an earth-toned palette, encouraging you to see water, vegetation, rock or peaks. Those interpretations are useful associations, but the program has not thereby simulated water movement or the growth of plants.

Describe the picture once using landscape names and once using only high values, low values and spatial variation. Notice what the first description adds. The texture is also normalised to its own range, so a strong colour contrast need not indicate a large absolute numerical difference from another setting.

<!-- @ -->

A neutral palette or fixed shared scale would expose another part of this construction and make a useful later comparison. The cycling platform in the next room puts uncertainty into timing instead of texture. You will know the order of its states while remaining uncertain about when it moves between them.



## Random_Game

Source: commons/maps/Random_Game/final.md

SHA256: a076c53d5357dfd88ce0bedc590695bc168245c07b7f4af0e64b0d6bc42b718b

# Told, or finding out

In the mushroom bed, a draw helped decide which body appeared. In the gallery it became paint, an estimate and a path. Here it helps decide whether a body will still be there when yours arrives.

<!-- @r_c -->

Three cyan stones cross a rectangular pit. Their tops stand a little above the museum floor. Beyond them, a prism carries a five-digit number. Watch the middle stone before stepping onto it. When it leaves, what would you be standing on?

The stone turns orange and sinks. The bed below remains. Then green, a rise, cyan again. Watch a second cycle. The order may already feel familiar while the pauses refuse to settle into a beat.

The stele at the lip names four states: IT STANDS, IT LEAVES, IT IS GONE, IT RETURNS. The procedure follows that order. A draw supplies the standing wait:

```gdscript
var visible_wait: float = _next_random_wait()
_note_step("stands", visible_wait)
await get_tree().create_timer(visible_wait).timeout
```

Inside the function, the interval becomes a number:

```gdscript
return _rng.randf_range(min_wait, max_wait)
```

For this crossing, the standing wait lies between 2.4 and 4.6 seconds; the hidden wait between 1.1 and 2.2. Sinking, rising and the short collider delays take additional time. Knowing those bands does not name the next draw.

Look at the tablet beside the pit. Each stone has a line: its present state, the last drawn wait and the time left of that wait. Now you can know something that watching cyan alone withheld. The current pause has already been chosen. The next one has not yet been drawn.

```gdscript
_step_wait = wait_seconds
_step_until_ms = Time.get_ticks_msec() + int(round(wait_seconds * 1000.0))
```

The counter reads the stored deadline. It does not keep asking for another duration. During LEAVES and RETURNS, the tablet retains the preceding draw at zero remaining time: it is an account of a wait, not a new measurement of movement.

Try the first stone when it stands. Its top is 22 centimetres above the hall floor, approached by a ramp and short landing; the spaces between stones are twelve centimetres. A stone can leave while you are on it. The pit has a bed 1.02 metres below the hall floor and a ramp up its west side. The corridor east of the pit also reaches the far lip. Crossing is one way to investigate this room; going around is another.

Watch the gold rings. They light during the final 1.2 seconds of a standing wait. Press CUE and try observing without them. Each stone still has a small beacon that lights during its movement. The tablet still shows its deadline. This experiment changes the notice carried by the stones; it does not remove every way to anticipate them.

Neither cue draws another wait. Yet the same next event becomes available to you differently: a ring before movement, a beacon during it, a number on a surface you must turn toward. Before describing a missed step as poor timing, ask where its warning was readable.

There is another separation under your feet:

```gdscript
_set_collision_enabled(false)
_set_state(CycleState.HIDDEN)
```

The collider remains enabled through the sink and its short delay. It is disabled while the stone is hidden, then enabled before the rise. Appearance, movement and support have separate instructions. A dim shape below you is not necessarily something the collision system will hold you on. The bed supplies the recovery surface.

REPLAY returns all three stones to their standing positions and restarts their seeded waits. Try it after a stone has begun moving. A repeated seed would mean little if an earlier motion kept pulling that stone down. Restarting must also cancel the old motion and restore support.

The prism names this local construction. NEW SEED chooses a different current number; an older number may eventually return. REPLAY does not rewind the other artifacts or the visitor. You bring knowledge from the previous attempt into a crossing whose first waits have been restored.

<!-- @random_removal_arena -->

The next glass enclosure carries the removal rule under your feet. Here there are eighty-one cells. Entering selects one; walking farther asks for more. Red gives a short warning, then both the visible cell and its support disappear. The basin below burns. The dark apron remains a route around the changing set, and the console outside the entrance can restore it. This is a deliberate return to Random Remove: the rule you inspected there now participates in a crossing.

<!-- @random_doors -->

Beyond it, three doors face you. Stay at the console behind the amber line and choose one. A door lifts. It might remain a passage. It might announce fire, wait one second, then send a short jet toward the line. Watch before moving forward.

One door is assigned passage at the beginning of the round:

```gdscript
rng.seed = run_seed
safe_door = rng.randi_range(0, 2)
```

The other two are assigned fire. Pressing a button reveals an existing choice; it does not redraw the outcome. A jet reaches 2.7 metres and then stops. That door closes again. The passage stays open until reset. There is always one passage in this construction, because we wrote that guarantee before drawing its index.

REPLAY restores the same assignment. NEW SEED makes another seeded round, which may choose the same passage. After looking once, your next attempt is different even when the doors are not. Memory belongs to the player as well as to the machine.

<!-- @cube_projectile_spawner -->

After the doors, cubes arrive from above. Watch from the edge before entering their space. Does the interval between arrivals vary in the way the stones' pauses did?

At the housed panel, press RUN / STOP. Wait. Some cubes continue moving. Press CLEAR and compare what disappears. Stopping the source did not recall what it had already released. Clearing the flights leaves the source's running state as it was, so stop it first when you want an empty field that stays empty.

Here the timer attempts a launch every half-second. It skips the attempt if 24 projectiles are already active. The irregularity begins elsewhere:

```gdscript
var spawn_pos = field_origin + Vector3(
    _rng.randf_range(-half_w, half_w),
    field_spawn_height,
    _rng.randf_range(-half_d, half_d)
)
```

Two draws choose x and z in an eight-metre square. Height is fixed at eight metres above the field origin. The floor lines mark that region of initial centres. They are neither walls nor a forecast of every place a cube may reach.

Another draw gives an initial downward speed between 1.6 and 2.6 metres per second. Small sideways velocities and later changes let the bodies drift. The projectile carries its own generator. A seed that repeats its launch position does not, by itself, repeat those later changes or its collisions.

The crossing drew a duration. This machine draws positions and velocities on a regular launch clock. Both are called random, but the word cannot tell you where to look. Keep track of which encounter supplied your evidence: a sampled wait at the crossing, or a sampled launch in the field.

At the last podium, wait for a small wooden cube. It drops from three metres above the floor onto a two-metre-square surface. Another arrives at the other position. The positions alternate; after the first one-second wait, each new delay is drawn between 0.3 and 1.3 seconds. The places are dependable while the rhythm is not.

Pick one up. Arrivals wait while either cube is held. Release it and the waiting continues. There are at most two cubes: an arrival replaces the cube in its alternating slot. RUN / STOP holds the arrival clock, leaving released cubes to fall. REPLAY restores the arrival sequence, not the history of your hand or an identical physical landing.

Beside the podium, five cutout profiles recede into the room. Their uneven horizons sit around eye height, 1.7 metres. The nearest is dark; those behind grow lighter. Move sideways and watch one contour uncover another. A landscape appears between flat panels.

Each panel joins seventeen heights. The two ends are fixed; the interior samples vary, with smaller permitted deviations near the edges. PROFILE changes the contours. These heights are a separate experiment, not a graph of the cube delays. Here you can look back and forth along the sequence. At the podium you had to wait through it. What did seeing the whole shape let you anticipate?

<!-- @ -->

The room leaves a more specific question than whether a world is predictable. Which decisions are already made, which are still to come, and what tells us the difference? In Noise Types we will carry that question between neighbouring places. A choice can be uncertain and still have a relation to the choice beside it.



# noise

Declared order: Random_Noise_Types → Noise_Columns → Noise_One → Noise_Voxel → Noise_6_Wall → Noise_Inside_Noise → Noise_Space_10 → Noise_Perlin_Simplex → Lab_Path

Museum map-authored order differs: Random_Noise_Types → Noise_Columns → Noise_One → Noise_Voxel → Noise_6_Wall → Noise_Inside_Noise → Noise_Space_10 → Noise_Perlin_Simplex. Treat this as route drift to inspect, not an editorial recommendation.


## Random_Noise_Types

Source: commons/maps/Random_Noise_Types/final.md

SHA256: e4b7453da871c425cbd60134443e95d3730e023bbc7826d0dd56a7a9b1a7f3d0

# Which rules keep acting?

<!-- @randompoint -->

The stones behind us could disappear. Their order of movement stayed intact; the drawn waits changed how long we had to cross. Here, something much smaller asks what can change at all.

A point waits inside a metal square. Carry it sideways. Release it. Try carrying it toward you, out of the square's plane. Where does it end up?

It has a place in this room, yet keeps returning to a surface with no depth. The frame marks a limit you can see. The returning coordinate exposes another one.

At its first appearance, two draws chose x and y. After that, there is no new lottery on release. The point's script repeatedly takes its current position and clips it:

```gdscript
var clamped := Vector3(
	clamp(pos.x, -area_half_extent, area_half_extent),
	clamp(pos.y, -area_half_extent, area_half_extent),
	0.0
)
```

Read the last line again. There is room in the vector for a third number. The code keeps writing zero there.

That zero belongs to the point's local frame. Turn the whole artifact in the museum and its plane turns with it. We have met local and world coordinates before; now their difference determines which movement survives your hand. Within the square, x and y can keep your alteration. Beyond its edges, the excess is clipped. Depth is discarded each process frame.

What looks like a flat existence takes repeated work to maintain. The engine has not forgotten a dimension. This small procedure keeps declining it.

Keep that action in mind at the next bench. A boundary can be drawn on a surface, written into a generator, or continually reapplied. Those arrangements may look alike until somebody moves.

<!-- @randompoints -->

Two shallow frames stand side by side. Find a pair of points that seem almost to touch in the left one. Look for an equally close pair on the right. Lean a little: each frame has twelve centimetres of depth, so an overlap in your view need not be an overlap in space.

The shells help. Each has a radius of half the stated spacing. Two centres at that distance have shells that just touch. Grey specks among the right-hand points record some of the proposals that were refused.

Press REDRAW. The pair of clouds returns. Press NEW SEED and look again. The arrangement changes, but the right-hand spacing survives the new draw.

The left frame keeps each uniformly proposed position. On the right, a candidate is compared with the centres already admitted. Only this condition lets it join them:

```gdscript
if min_dist >= blue_noise_min_dist:
	pts.append(candidate)
	placed = true
	break
```

The candidate's own coordinates are insufficient to decide its place. Its possibility now depends on who arrived before it. Earlier centres stay where they are; the algorithm neither negotiates with them nor rearranges the group.

Press LOAD. The request rises from 24 to 96. The frames and the spacing stay the same size. Read the plate before deciding what the denser cloud means. Candidates split into kept and refused; requested places split into filled and unfilled. These are different accounts.

The generator allows a hundred attempts for each requested place. A place still unfilled after those attempts is skipped, and the next gets its own attempts. The plate names the exhausted budget. It cannot certify that every remaining gap is impossible. Our time for searching has ended before our question about space has been settled.

Only the first 220 refusals receive grey bodies. The full refusal count continues beyond them. Even the display of what was excluded has an exclusion of its own, and this time we can read its limit.

Return LOAD to 24, then press RULE. The right frame gathers toward its centre. This setting makes Gaussian draws for each coordinate and clamps their tails to the frame. It applies no pair-distance test. Shells may already be red before you touch anything. They now show a reference distance that the generator never promised to preserve. A crowded centre and a spacing rule are different ways of making a cloud; the names alone cannot tell us how either was made.

Return to the spaced rule. Carry a point into another's shell.

The red arrives. A count changes. Nothing in the sampling script pushes the pair apart.

```gdscript
if a.position.distance_to(b.position) < blue_noise_min_dist - 0.001:
	touching += 1
	bad[i] = true
	bad[j] = true
```

This passage watches. It counts pairs closer than the spacing minus a one-millimetre tolerance. It writes no replacement position. Compare it with the zero that kept reclaiming the first point's depth.

Release the point, then RESTORE. The cloud returns to the positions recorded when it was generated. That return is available as an action; it does not make the original arrangement inevitable.

A pleasing order has shown us its procedure and the moment that procedure stops governing. There is room to inhabit the difference. We can keep the useful constraint, learn what it made possible, and still discover a relationship it did not authorize at birth.

The seed repeats this local construction when its settings and calls repeat. It does not replay the museum. The left cloud consumes the first part of one generator's stream; the right continues it, so these are not identical candidates subjected to different rules. There are still two works in this hall we have not approached. Their thin bars and their sounds offer other ways to meet a neighbour.

<!-- @WhiteNoiseGallery -->

Walk around the little field of needles. Let your eye follow a row, then cut across it. There are ten thousand bars here. The grid has already given each one an address. Chance decides how far it rises.

The same drawn value gives a bar its height and its place along a colour gradient. Tall and pale can arrive together because one number has been dressed twice. This is something we brought from the colour halls: an arrangement becomes readable through the choices that make its values visible.

```gdscript
var random_val = _rng.randf() # 0.0 to 1.0
var height = random_val * max_height
```

The spacing bench let a neighbour influence whether a new centre could appear. These bars do not consult adjacent heights. Every address receives a draw. A ragged-looking surface has been made from a perfectly regular allocation of places.

Now press WHITE on the console beside it. Then PINK. Listen for a difference while looking at the field. What in the image changes?

The bars stay where they were. The sound has its own stream of draws and its own procedure. It is tempting to let the image explain what we hear, especially when one title seems to cover both. For now, the connection is made by their proximity, their names, and your attention. The sound is not a scan through these ten thousand heights.

That separation leaves an experiment open. What would we hear if a row actually became a sequence of samples? Which row, in which direction, at what speed? A surface offers several ways through; a loudspeaker needs values arriving in time. Choosing the route would already change the work. We can imagine that instrument here without pretending it has been built.

<!-- @NoiseColors3D -->

The neighbouring sculpture keeps five coloured rows together. Brown, pink, white, blue, violet. Try their names on the console. Let each sound last long enough to become a texture before moving on. Return to one you liked.

We are not obliged to hear these as damaged signals. A hiss can be a material to approach, sustain, combine, or leave. The question of what a body may do includes what it may want to remain with.

In the sculpture, a row's height comes from a prescribed curve, disturbed by a random multiplier and clipped to the display's range. A tall plateau can therefore be the place where different large values meet the same ceiling. The apparent agreement of their tops deserves a second look.

The sound is built elsewhere. At the BROWN setting, a stored value receives a small part of the next draw:

```gdscript
_brown_state = clampf(_brown_state + white * 0.02, -1.0, 1.0)
value = _brown_state * 3.5
```

The previous state participates in what comes next. A neighbour has become a previous moment. Notice the bounds here too: accumulation can meet a limit even though new draws continue arriving.

Try VIOLET. Its short passage keeps the previous draw in order to subtract it:

```gdscript
value = (white - _previous_white) * 0.9
_previous_white = white
```

Keeping something from the past does not always make the next moment more similar. Here, what survives into the output is a difference. The two lines give us another way to hear the relation between memory and change.

These are the shipped filters behind the names. The curves above them are illustrations, not measurements of the sound coming from the speakers. Even BLUE's sound uses subtraction from a running low-pass value rather than the exact rising curve that its row illustrates. A name brings several implementations into company; inspecting them keeps that company from becoming an identity claim.

We can leave this hall with more than one discovery. A plane maintained by clipping. A spacing rule that finishes its work. A field that ties colour to height. A sound that holds a previous value, or answers it with a difference. Each gives a different place for a relation to land.

In the next hall, a column is already waiting. What will happen when variation is given an existing form to act on?



## Noise_Columns

Source: commons/maps/Noise_Columns/final.md

SHA256: d5e3f300bcf46bcca41512bd10f6082c4426883345271da3f47e273114bbbc8c

# What keeps a body changing?

Can you tell how a body changes just by looking at its strange shape?

<!-- @MeltingBerniniScene -->

Three marble columns stand in the east half of the room. Their shafts come from the same recipe, at the same resolution. The plates at their feet say nothing yet. Stand where you can see all three at once and watch for a while before you press anything.

One silhouette holds. The other two rise and sink. There may be a familiar movement among them, something the wave halls have already taught your body to expect. Choose one to follow. When it comes back, keep watching. Does the return arrive after the same interval?

FREEZE holds the columns' local clock. You can take time to walk around the shape that was passing. The rest of the museum continues. Even here, stopping has an address.

Try SPIN while the clock is held. The columns turn. A ridge slips out of sight and another arrives. The vertices of each shaft keep their local coordinates; their positions in the room change with the whole column. Transformation has returned as a way to inspect what we thought was deformation.

Stop SPIN and press MARBLE. The shaft loses its veining. The folds remain. The base and capital retain their own patterned materials. Look at the edge of the shaft, then at the surface inside that edge. A changing appearance has several places to happen, and a picture can encourage us to fold them together.

Put the veining back if you prefer it. The pleasure of the surface need not end when we learn how it works.

Now REVEAL names the three drivers. BASELINE holds a fixed value. PERIODIC follows a sine. FIELD follows a path through a seeded coherent field. Release FREEZE and compare the names with the movement you watched.

```gdscript
func driver_phase(kind: String, t: float) -> float:
	match kind:
		"periodic":
			return sin(t * melt_speed) * 0.5 + 0.5          # the shipped driver
		"field":
			return clampf(_noise.get_noise_2d(t * 0.55, 0.0) * 0.5 + 0.5, 0.0, 1.0)
		_:
			return TRIO_BASE_PHASE
```

The sine repeats after a fixed interval. At the room's speed of 0.9, that interval is about seven seconds. The field has a different history. Nearby sample coordinates give related values; the path does not carry the sine's promise of a seven-second return. That does not make it unknowable. With the same seed, settings and coordinate, this implementation gives the same value again.

Both drivers hand the shaft one number between zero and one. The code calls it a phase. For the sine, it is a remapped output rather than the angle inside `sin`. For the field, it is a sample remapped and bounded to the same range. The shared name makes the numbers interchangeable at the next operation, while their histories remain different.

In the previous hall, each bar received its own draw. Here a whole shaft receives one phase. The field is not being sampled separately at every vertex. It proposes a value; the column recipe decides where that value can go.

```gdscript
var melt_factor = pow(v, 0.5) * melt_strength * melt_phase
var height = v * column_height - melt_factor * 2.0
```

`v` marks progress up the shaft, from zero to one. The square root gives different heights different shares of the same phase. At the top, the mapped drop can reach 0.70 metres. The phase also enters a bulge further down the function. Ribs, twists and offsets were already there before the field arrived.

Look again at BASELINE. It is held at 0.10, and it is already strange. The fixed reference is itself a made body. We have chosen something to keep still so that another change can become legible.

This gives a practical answer to what bodies are possible with the tools we have acquired. A coherent field can supply variation, but it does not contain a column. Rings of vertices, a spiral, a height rule and a material make that variation into this body. Give the same values another recipient and another world can appear.

The recognisable column also brings an expectation: it should hold something up. These display columns have no supporting collision bodies. They carry the appearance of architecture without its load. Calling their movement melting names what we see; it does not establish that stone, heat or erosion is being simulated.

There is a smaller interruption inside the smooth movement. Each moving shaft is rebuilt at most twelve times a second. Between updates, the mesh holds its last shape. The readout reports that budget and the last phase actually used. Our earlier trace had gaps between samples; this surface has intervals between rebuilds. What looks continuous is again being afforded in portions.

<!-- @dark_sphere -->

Leave the columns frozen for a moment and turn to the dark orb. Its sheen shifts. Stay long enough to notice the pulse and the widening ring beneath it. The room has not stopped breathing just because one instrument has stopped counting.

This body uses another local clock. Its script also contains a sine:

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
```

This time the value enters brightness and emission. It does not rebuild the sphere's mesh. The body also turns slowly, and the surrounding ring changes size and opacity. A single appearance gathers several operations that our earlier halls let us separate.

The dark sphere was described as a neutral anchor. Looking for longer complicates that description. It is active, but its activity is easy to pass over beside the tall columns. The distinction between foreground and background is also a distribution of our attention.

You need not make it illustrate the columns perfectly. It can keep its quieter presence. It gives the local pause an outside: another process goes on while we concentrate on this one.

<!-- @synthesis_stand -->

Nearby, the darkness has become six small orbs. They turn together in a ring, at alternating heights. There is an empty middle. Walk far enough around them for the gaps to change.

This work belongs to the same dark-sphere family. The stand chooses `presence = hush` and `body = swarm` before the scene builds. The first setting makes the presence smaller and quieter. The second chooses a construction with six members. Their common motion is the rotation of their parent; they are not steering themselves around one another.

```gdscript
var count: int = 6
var ring: float = _radius * 0.95
var small: float = _radius * 0.40
```

The array has come back inside a body. So have the circle and the alternating value. Earlier, a field varied a shaft while its mesh connections remained. Here, selecting a construction changes how many parts the body begins with. These are different kinds of change, and our toolbox contains both.

The stand's plaque records a chosen variant and a score from a saved comparison. That score explains something about the selection procedure; it cannot decide what you should want from this body. Perhaps the small gathering holds your attention precisely because it is difficult to resolve at a glance. Perhaps you prefer the solitary orb.

A family offers possibilities, and choosing one still leaves other members unvisited. We can name the choice without closing the family. The same is true of our route through these halls: enough attention to make a discovery, with other directions still available.

Noise One takes the next step. Two surfaces will receive the same field and spend it differently, as relief and as colour. We leave with a question about the receiver as well as the source: what can this body do with the value it has been given?



## Noise_One

Source: commons/maps/Noise_One/final.md

SHA256: 6d9528ae1be355500cc4842e1e3e573cb0f1588d85fe90cb283e31a04717b8c0

# What does a value become?

<!-- @noisetorus -->

Two rings rest above a bench. One wears its variation as small folds. The other keeps a round outline while colour travels across it. The columns behind us asked where change enters a body. Here the question becomes more intimate: could these two surfaces be receiving the same thing?

Watch a bright patch arrive. Then press FREEZE. The rings hold that moment; the museum carries on. Two pale markers indicate matching coordinates. SAMPLE moves them together around the rings. Before reading the plate, look for a place where the folded ring turns inward and its coloured neighbour goes dark.

The plate gives a signed value. A negative number can become an inward movement. What would negative brightness look like?

At first this colour rule makes every negative sample black. Values that differ on the plate share the same darkness. Their differences have reached the display and been folded together there.

Press REMAP. Some of the dark surface returns. The number at the marker does not change. Neither does the relief. A different reading has made room for something that was already being computed.

```gdscript
func colour_of(value: float) -> float:
	return (value + 1.0) * 0.5 if _remap else maxf(value, 0.0)
```

Read the two invitations inside that line. `maxf(value, 0.0)` gives every negative value the same destination. `(value + 1.0) * 0.5` carries the interval from minus one to one into the interval from zero to one. Minus one becomes black, zero becomes halfway, and one becomes full brightness. The colour channel had room for the difference once we changed its address.

This is a small freedom with a specific mechanism. No hidden body has been rescued whole. We have changed what the display distinguishes. Lighting, the changing hue, screen precision and our eyes will still mediate what becomes visible. The plate reports the brightness factor before those further encounters.

Keep the clock held and try AMPLITUDE. The folds deepen or retreat. At zero they leave a plain ring. The coloured ring keeps its pattern, and the sampled value stays where it was.

```gdscript
func relief_of(value: float) -> float:
	return value * float(PAIR_AMPS[_amp_i])
```

A multiplication is enough to change the force of an appearance. It is not a force calculation. In the vertex shader, the result moves each vertex along its normal, the direction facing away from the surface at that vertex. The two rings have no collision shapes. The bench supports the instrument; its pictured folds will not catch a falling object.

Now change FREQUENCY. Keep watching the same marker. The value itself may change. We have moved the coordinate at which the field is consulted.

```gdscript
var scale: float = float(PAIR_FREQS[_freq_i])
var off: float = fmod(t, 3600.0) * noise_speed
return _noise2(Vector2(x * scale + off, z * scale + off))
```

The field is sampled through the ring's local `x` and `z`. Multiplying those coordinates makes more or less of the field pass across the same small body. Adding the time offset moves the sampling window diagonally. Release FREEZE and that addition resumes from the held moment. A wave of apparent change can come from travelling through values that are already determined by their coordinates.

There is a quiet omission in the expression: no `y`. Two places above and below one another, sharing the same local `x` and `z`, consult the same value. The ring is three-dimensional; this field is addressed in two dimensions. Its normals still point in different directions. One value can therefore move two parts of the body differently.

Look at the rings again. We began by treating their appearances as separate events. We can now follow a shared computation into different recipients. Yet the two views are not identical measurements: relief is evaluated at mesh vertices, while colour is evaluated across rendered fragments. The smooth skin and the bright skin spend different sampling budgets.

The marker is a coordinate probe just outside the surface. The plate rounds its field value to three decimals. Neither is a promise of infinite resolution. The little counters from our first drawn line have reached the ring with us.

<!-- @noiselayers -->

Walk around to the landscape basin. The room's opening now holds a small violet terrain within a pale coordinate frame. Come to its southern edge, where four buttons offer SUM, LOW, MIDDLE and HIGH.

Start with the whole. Choose a ridge to remember. Then press LOW. What survives? Try MIDDLE and HIGH before returning to SUM. One contribution may look modest beside another. Modest does not mean absent: addition has no obligation to give each ingredient an equally dramatic silhouette.

The earlier arrays have become a sheet of addresses. At each address, three existing noise resources supply three weighted numbers.

```gdscript
var low_freq_height = low_freq_noise.get_noise_2d(world_x, world_z) * low_freq_amplitude
var med_freq_height = med_freq_noise.get_noise_2d(world_x, world_z) * med_freq_amplitude
var high_freq_height = high_freq_noise.get_noise_2d(world_x, world_z) * high_freq_amplitude
```

```gdscript
var combined_height = low_freq_height + med_freq_height + high_freq_height
```

The weights are twelve, six and one-and-a-half. The names suggest a tidy progression, but the first two resources have almost equal base frequencies: 0.0056 and 0.0057. They also differ in algorithm, seed and octave count. These are three authored ingredients, not three pure frequency bands. A name can help us enter a construction while still needing inspection.

Each button isolates a contribution before the same further processing. The code calls that processing erosion. Look at what it actually does: in three passes, it lowers samples whose estimated slope exceeds a threshold. No water carries the removed amount elsewhere. The name lends the calculation a landscape story; the implementation gives us a more limited operation to examine.

Because the lowering happens after combination, the displayed SUM need not equal the displayed LOW, MIDDLE and HIGH added together. Combining, then modifying, can differ from modifying, then combining. Transformation taught us to ask about order. It matters here too.

The model keeps 101 by 101 sample points. Its original 200-unit width is shown at one-fiftieth scale, four metres across. The terrain has a collision mesh made from its visible triangles, unlike the shader folds on the rings. That makes a different kind of surface available to the simulation, without making this basin a full-size hiking course.

Keep the violet colour in mind. The geometry code also computes grass, rock and snow vertex colours, but the scene's material wears its own colour instead. A calculation can exist without being selected for display. A mountain can wear violet without its heights changing. The pleasure of dressing a body has arrived inside the terrain pipeline.

<!-- @dark_sphere -->

Near the exit, the dark orb continues its pulse. Leave the rings held and the terrain on HIGH. The orb still has somewhere else to be in time.

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
_sphere_material.emission_energy_multiplier = lerpf(pulse_min * _emit_mul, pulse_max * _emit_mul, pulse_t)
```

Another scalar finds a surface through a brightness rule. This one comes from the familiar sine and the orb's own clock. It need not imitate the landscape to belong in the room. It lets us compare a periodic source with a sampled field, and makes the boundary of FREEZE visible again.

Three works remain three works. Across them, we can follow values into displaced vertices, colour, an added height, a collision surface and a pulse. The shared numerical form permits these crossings. It does not decide which crossings we build, or what each one can support.

Noise_Voxel waits beyond the door. There the field meets another demand: decide whether something occupies a cell. Take the dark patch with you. When a rule says that nothing is there, we now have a reason to ask how it read the value.



## Noise_Voxel

Source: commons/maps/Noise_Voxel/final.md

SHA256: 358343c1f30f73c8a98fa2ec7e7e8688d8074cb4c95489cef7e8d9405b6f341a

# The line that decides

<!-- @perlin_terrain_sculptor -->

A green body waits on the bench, with little daylight between its blocks. The yellow cage names a cell, including when that cell contains nothing you can see. Across the room, a much larger body has the same irregular outline.

Leave SEED alone for a moment. Press THRESHOLD and watch the green body. Then watch the field value on the plate while you press again. Something has disappeared. Which number changed?

The field value stays. The line it must exceed has moved.

```gdscript
static func contract_occupied(value: float, v: float, threshold: float) -> bool:
	return value - contract_bias(v) > threshold
```

The whole decision fits inside that return. A field value arrives; a height-dependent bias is subtracted; what remains must be greater than the threshold. Equality goes with empty. The result has two states, although the values arriving at it can differ by tiny amounts.

There are twenty-four addresses along each axis: 13,824 occasions to ask. A voxel is a volume element, a little region whose occupancy receives this answer. We have carried the array into three dimensions. The field supplies values at its sample positions; the grid supplies the places where those values can count.

Look at the bias on the plate. Lower cells receive help. Higher cells have more subtracted. That preference is written here:

```gdscript
static func contract_bias(v: float) -> float:
	return (v - 0.5) * CONTRACT_BIAS_SCALE
```

`v` runs from zero at the bottom to one at the top, and the scale here is 0.5. The bias runs from −0.25 to +0.25. We have given this field a downstairs before placing anything on it. No gravity has acted on these blocks. Even a fragment hanging in the air stays where its address puts it.

The threshold button visits five values and then returns to the first. Within the rising run, −0.20 through +0.20, occupied cells can only be removed while the field and bias stay fixed. Watch a thin connection; watch a tiny island. They do not necessarily disappear at the same step.

The counter for separate pieces has another rhythm. With the starting seed, 31415, it reads 4, 15, 25, 21, 32 across those five thresholds. At +0.10 there are fewer cells and fewer pieces than at zero. A connection can break and leave two pieces; a small piece can vanish entirely. Counting bodies asks a different question from counting how much is occupied.

Press CUT. Part of the model opens to your gaze. Now check the occupied count. It has stayed put. The cells concealed by CUT are still in the array; this button changes which instances are drawn. Bring them back. A disappearance has acquired two possible explanations within reach of the same hand.

<!-- @science_screen -->

The screen keeps a horizontal slice of that array. On the left, colours vary with the field after the height bias. On the right, each square receives the decision: occupied or empty. A small yellow frame marks the selected coordinate in both.

Press CELL at the bench. The cage visits another address and the screen takes its horizontal layer. Follow a dark square on the right into the coloured square at the same position on the left. There is still a value there. The decision has withheld a block.

Return to THRESHOLD. The right-hand border shifts through a left-hand field that stays still. You can now see several different values receive the same answer. The binary mask cannot tell you how far a rejected value missed the line; the other display can.

This excerpt is the screen asking the bench for the stored answer:

```gdscript
row.append({"value":value,"score":value-PerlinTerrainSculptor.contract_bias(v),"occupied":source.get("_voxels")[x][cell.y][z]})
```

There are two readings beside each other because each lets us ask something the other has lost. The coloured field has already passed through another rule, a colour mapping. We have no unencoded original glowing behind the screen. We have enough distinct readings to follow one transformation and put pressure on its account.

Now try SEED. The field changes, and the decision map changes with it. The coordinate remains an address, but what arrives there is different. The number on the bench lets you notice that the comparison has begun again.

<!-- @voxelnoise -->

Walk towards the large blue volume with its pink edges. The bench lets you look down into the arrangement; here parts of it rise above your head. A recess that looked like a detail becomes somewhere you might want to approach.

Both works ask at the same 24 × 24 × 24 positions in the same Perlin field. Their cell spacing differs: four centimetres at the bench, twenty centimetres here. The model leaves a small gap around each visible block so its addresses remain legible. The large volume joins occupied neighbours and draws their exposed faces. Its surface also supplies the collision triangles.

The coordinate rule is small enough to carry across the room:

```gdscript
return n.get_noise_3d(u * CONTRACT_SPAN, v * CONTRACT_SPAN, w * CONTRACT_SPAN)
```

The three coordinates run from zero to one within either display. `CONTRACT_SPAN` is 9.6. Increasing the physical spacing therefore enlarges the arrangement without reaching into a different part of the field. The same decisions have gained another relation to your height, reach and route.

The plate counts groups joined through cell faces. Stand beside the volume and ask what that count cannot tell you. It does not measure headroom. It does not know your step height, or whether a passage has an entrance. One connected mass can contain a route you cannot use. Empty space can offer passage, or leave you without support.

There is pleasure in a cavity before its usefulness is settled. Try looking from another side. The blocks need not become an enemy, a resource or a successful level to hold your attention. They can make you curious about what sort of body would find a way here. Our own body gives one answer, with particular dimensions and particular permissions.

<!-- @dark_sphere -->

The dark orb is still here, turning above its pool of light. Leave the threshold at one value and watch it for a while. The voxel body holds its arrangement. The orb continues to brighten and dim.

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
_sphere_material.emission_energy_multiplier = lerpf(pulse_min * _emit_mul, pulse_max * _emit_mul, pulse_t)
```

We have met this sine before. It passes through a range of emission strengths while the sphere keeps its form. Nothing here asks whether the sine has earned the right to keep a block.

The same museum can host a continuously dressed body and a body assembled through yes-or-no decisions. The threshold is useful; it gives the volume a boundary you can encounter. The field's other differences remain available to another operation, another material, another question.

<!-- @ -->

Carry a rejected value towards Noise 6 Wall. What else could receive it?



## Noise_6_Wall

Source: commons/maps/Noise_6_Wall/final.md

SHA256: e7a08ec471f7ecb941e512797250f24684056fed92763d79a2350fbd6f943172

# The room wears the sum

<!-- @shader_noise_space -->

There is a room inside the hall. Pink gathers in its corners. The little sphere inside seems to have borrowed something from the walls, although its clouds pull around a different body. Step through one door and look towards the other. The floor carries you while something softer appears to move through it.

What would have to change for those folds to carry your feet?

Keep that question while you return to the panel. Four small windows show the same coordinates with one, two, four and six cloud terms. Press FREEZE. The room holds the moment you arrived at. Its colours and the small windows stop changing together. We can stay with a difference long enough to inspect it.

Press DRESS, then enter again. Grey has taken the place of pink. Something of the cloud remains, but its depth and atmosphere have changed. Follow the wall towards the door. The opening is still there. Your feet meet the same floor.

We have changed what the surface offers the eye. The wall's vertices and the shapes your body collides with have stayed put. This distinction is useful precisely because the surface can be so persuasive. You might still walk differently towards a dark patch, or hesitate before something that looks deep. What the player can physically cross and what the player imagines crossing need not arrive together.

At the panel, compare the first grey window with the second. A smaller variation has entered the same region. The fourth and sixth terms add finer disturbances. LAYERS carries each of those cumulative choices into the room; the four windows keep their separate counts so you can look back.

Here is the loop doing that work:

```glsl
    for (int i = 0; i < layers; i++) {
        vec2 animated_pos = pos * frequency;
        animated_pos.x += sin(t * 0.3 + pos.y * 0.5) * 0.3;
        animated_pos.y += cos(t * 0.2 + pos.x * 0.3) * 0.2;

        value += amplitude * abs(noise2d(animated_pos));
        amplitude *= 0.5;
        frequency *= 2.0;
    }
```

`value` begins at zero, `amplitude` at 0.5 and `frequency` at 1. Each turn reaches further through the field over the same surface, then gives its answer half the weight of the previous turn. The familiar sine and cosine move the sampling coordinates. FREEZE has held their time, too.

Stay with `abs` for a moment. A negative answer returns as a positive magnitude. Positive and negative values of equal size can now contribute the same amount. In the previous room, a threshold decided whether a cell received a block. Here another operation gives differences another destination: both signs can help dress a surface. This is a new two-dimensional shader field; we are carrying a way of thinking forward, rather than transferring the voxel room's stored samples.

The plate lists accumulated weights: 0.5, 0.75, 0.9375, 0.9844. The sixth term weighs only one thirty-second as much as the first. It still has somewhere to act. Look for a region where a small addition changes the edge you were following.

More terms can also make the grey window brighter. Every weighted magnitude is nonnegative. At a fixed coordinate and time, adding one cannot reduce the sum. But the weights alone do not tell us a pixel's brightness: each term brings a sampled value, and the display puts the result through another rule.

```glsl
        float bare = clamp(cloud_noise(uv * cloud_scale, time * time_scale) * term_gain, 0.0, 1.0);
```

The comparison uses a gain of two. Values beyond the display range meet its limits. Two different sums can therefore become the same white. Grey is already an interpretation, with its own capacity to lose a difference. There is no final undressed picture waiting underneath every other picture.

Try BASIS while the moment stays held. Perlin, Value, Cellular and Simplex offer different constructions to the same accumulation. These are the implementations in this shader, with their own scaling constants. Watch what happens to a contour you had begun to recognise. Returning to Perlin restores this construction at the held coordinates. There is no seed button here; the shader's hash uses fixed constants.

Press DRESS again. The pink returns around the same held cloud sum. The finished material adds a second, four-term turbulence calculation:

```glsl
        float cloud_pattern = (cloud_base + cloud_detail * 0.4) * cloud_density;
        cloud_pattern = smoothstep(0.2, 0.8, cloud_pattern);
```

Colour mixing, edge and corner shading, roughness and small changes to the lighting normal follow. LAYERS changes the cloud sum; that separate detail loop still has four terms. A one-term cloud can therefore wear a detailed finish. The button's number names one part of a construction.

Take this knowledge inside. The material has crossed from a small square to an enclosure and a sphere. Can you follow one cloud around a corner?

Each wall piece starts its own UV coordinates. The sphere wraps a different coordinate chart around itself. The same calculation can stretch, repeat or meet a seam when another surface receives it. The room is surrounded by a shared procedure, but it is not an unbroken sample of a world-space cloud.

The seam is an invitation to look at how the room has dressed. A surface can make a box feel intimate, strange or excessive without first earning another geometry. Its pleasure need not be dismissed when we find the instruction that produces it. Now we can change that instruction with a more particular desire.

<!-- @dark_sphere -->

Outside, the dark orb continues to pulse. The room is held; this body is not. Stand between the two and watch the difference in their times.

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
_sphere_material.emission_energy_multiplier = lerpf(pulse_min * _emit_mul, pulse_max * _emit_mul, pulse_t)
```

The orb receives a sine as a changing emission strength. It belongs to the hall without belonging to the panel's clock. A control has a reach, and discovering its edge tells us something about the world's construction.

Press FREEZE once more to let the room continue from its held moment. The orb did not wait. We leave with several times still running, and a surface whose apparent depth has not become a foothold.

<!-- @ -->

In Noise Inside Noise, we will ask what happens when a field changes the coordinates at which another field is read. Here we added answers. Next we follow what happens to the asking.



## Noise_Inside_Noise

Source: commons/maps/Noise_Inside_Noise/final.md

SHA256: 8462d0da760da424c42c952fdf02e91373744247abad021d83ecc35697b597fc

# Borrow an address

<!-- @noisesphere -->

Step through the opening into the sphere. Its colour curves above your head and returns towards the floor behind you. The museum is still visible through the other opening. A pattern that could have been held at a distance has become the inside of where you stand.

Two smaller spheres stand behind a tilted instrument within it. A yellow point marks the same direction on each body. Their colours seem related, but a patch on the left has acquired a different neighbourhood on the right.

Press ZERO. Stay with one patch while the two bodies come to agree. Then press WARP. Where did the difference enter?

Look up. The surrounding sphere changes too. Your feet have stayed on the same circular floor; the wall has not moved closer. Yet a different patch now hangs above the place where you are standing. The operation reaches the room before we have named it.

The outlines remain round in SKIN mode. The yellow points have stayed where they were. We have not enlarged a sphere or chosen a new colour range. Something changed before the value reached the surface.

Look down at the two square images. They read the field across the same coordinate window. Yellow marks the same address, `p`, in both. On the left, a second, pink point names an address nearby. The right-hand image borrows its answer from there.

The little grid beside the images keeps both versions of the coordinates visible: cyan for where we began, pink for where the warp sends us. The yellow line follows the selected address between them. Try SAMPLE. Follow another line before deciding what the whole picture is doing.

```gdscript
func address_at(p: Vector2, amount: float) -> Vector2:
	return p + amount * displacement_at(p)

func value_at(p: Vector2, amount: float) -> float:
	var q: Vector2 = address_at(p, amount)
	return base.get_noise_2d(q.x, q.y)
```

There are two moments inside this short passage. We first make an address, `q`. Then we ask the base field for its value there. That answer goes back to the original place on the display. The yellow point on the right has not travelled to the pink point on the left. It receives a value from the address the pink point names.

This is domain warping: a transformation of the coordinates used to read a function. In the previous room, several weighted answers were added. Here one field helps decide where another field is asked. An addition still appears in the code, but what it adds is a displacement to an address.

The displacement needs two components:

```gdscript
func displacement_at(p: Vector2) -> Vector2:
	return Vector2(warp_x.get_noise_2d(p.x,p.y),warp_z.get_noise_2d(p.x,p.y))
```

We have brought the vector back into the noise sequence. Two Perlin fields provide its components. Their seeds are fixed at 19 and 47; the base is a Value field with seed 4. These are explicit choices for this instrument. We do not change them when WARP changes. Separate seeds give us different patterns without proving statistical independence or promising a particular kind of beauty.

At amount zero, the displacement contributes zero and `q` becomes `p`. That is why the comparison can return. The baseline is still a chosen field, a coordinate window and a colour mapping. It gives us something steady enough to find where an operation enters.

Try the four amounts: zero, 0.35, 0.8 and 1.4. Watch the coordinate grid as well as the coloured result. Some pink lines draw together; others spread apart. The underlying field has not grown extra samples in those regions. The mapping is asking at differently spaced addresses.

Look for a narrow streak you like. At one amount it might resemble a vein; at another it might lose that resemblance. Neither outcome has to be the successful one. A procedure can make something unfamiliar that you want to stay near. Knowing the amount and the sampling rule gives you a way to return to it, and a way to ask for a difference more precise than “make it more organic.”

Now press RELIEF. Keep the warp amount where it is. The square images stay the same, but the values have gained another job on the spheres:

```gdscript
func radius_at(value: float) -> float:
	return 0.94 + (0.16 * value if relief else 0.0)
```

The base radius is 0.94 metres. In RELIEF, a signed sample changes it by up to 0.16 metres. A negative value can draw a point inward; a positive one can push it outward. Both spheres receive this rule. Their difference still comes from the addresses at which they read the base field.

Press ZERO again, now in RELIEF. The two arrangements of vertices agree. Turn RELIEF off and keep WARP active. A changed colour arrangement survives on the round bodies. We have separated changing where to sample from changing what a sample does.

The enclosing sphere keeps its fixed wall, ceiling, floor and two openings through RELIEF. Only the two smaller bodies receive the radial change. Their surfaces have no collision; the room and plinths do. A value has changed one visible body while another body remains a steady place from which to compare it.

Walk to the side and follow a patch around a sphere. This instrument uses the x and z components of a direction on the sphere, multiplied by three, as its two field coordinates. It leaves the y component out. Upper and lower directions can therefore ask at the same address. The field has not discovered a natural way to inhabit a sphere; we have supplied a projection.

The enclosure uses that same projection and the warped field. Its colours are dimmed to sixty-five percent and drawn without the lighting that falls across the smaller bodies. Follow a patch overhead, then look back at the instrument. They share a calculation, but scale, lighting and the part of the surface available to your eyes affect how you meet it.

There is another small difference between the square and the curved body. The image samples a 96 by 96 grid. The small sphere receives colour and relief at mesh vertices, and the renderer interpolates between them. The printed value names a calculation at the selected address; a coloured patch is a finite rendering of many such calculations. Zooming closer can reveal the agreement's conditions.

<!-- @dark_sphere -->

The dark orb keeps pulsing beside the stage. Nothing at this instrument needs to advance while you compare the two spheres. The controls change a configuration; the orb's sine changes with elapsed time.

A field can receive a new address without changing its seed. A body can receive another use for the same value. A scene can continue in one place while holding a comparison in another. These are different ways for change to enter, and each lets us make a different experiment.

<!-- @ -->

Carry the distinction towards Noise Space 10: the coordinate, the value, the surface and the body trying to find a way across it. Which of them must change before the landscape offers another route?



## Noise_Space_10

Source: commons/maps/Noise_Space_10/final.md

SHA256: d348af755b9836b8437747844f12d34d93fa98a92be9a6cd10c723b6d4961c2c

# Which way will carry you?

<!-- @noise_space -->

Two pairs of pale posts face each other across the ground. A gold line joins them. The far opening looks close enough. Before entering, follow the line with your eyes. Where would you expect your pace to change?

The previous sphere surrounded us with a changing field while its floor stayed still. Here the answer reaches the ground itself. Take the ramp onto the dark margin. The instrument stands along its side, leaving the route open.

At HEIGHT 0.25, try walking between the posts. A small dip can disappear from the far view and return under your feet. The colour gathers into contours, but your body meets a surface. Keep those two ways of reading it in play.

Return to the margin. Press HEIGHT until it reads 0.90 and look for the feature you just crossed. The posts have not moved. The field has not been drawn again from another seed. Try the same approach.

In the recorded desktop walk, the first crossing reached the far margin. At 0.90, the same forward input stopped partway across. That is an observation about one body, one approach and two settings. It leaves other ways through the terrain to be found. A line drawn across the ground has made a proposal; it has not given the body permission to follow it.

Press RESET from the margin. The lower terrain returns, with route A and the first sample selected. HEIGHT waits if a player body is still on the patch. We make the alteration from a place that remains steady enough to compare what changed.

The current height rule is short:

```gdscript
func ground_at(p: Vector2) -> float:
	var value: float = noise.get_noise_2d(p.x * noise_scale, p.y * noise_scale)
	return 1.0 + height_scale * edge_weight(p) * value
```

The value is signed. It can lower a point below the one-metre reference as well as raise it above. HEIGHT selects zero, 0.25, 0.65 or 0.90 as the multiplier. At zero, the ground becomes level. The noise calculation still has an answer; its contribution to height has become zero.

One generator supplies this encounter: OpenSimplex2S, with seed zero, four fBM octaves, gain 0.5 and lacunarity 2. Its frequency is 0.1 and the input coordinates are multiplied by five. Those choices remain fixed while we change HEIGHT. This is one slice through the possibilities of the existing terrain, narrow enough for a difference to become attributable.

There is a second multiplier in the code. Look at the place where green ground meets the dark margin. Even at the largest height setting, the two join at the same level.

```gdscript
func edge_weight(p: Vector2) -> float:
	var distance_to_edge: float = minf(4.0 - absf(p.x), 4.0 - absf(p.y))
	return smoothstep(0.0, 0.75, distance_to_edge)
```

The last three-quarters of a metre gradually withhold the noise's contribution. At the edge, that contribution is zero. The margin did not emerge from the field. We made it, so a body could enter and so the place from which we compare would remain available. The transition is part of the landscape's construction.

Now choose ROUTE B. A gold line takes a longer way through the same patch. Nothing in the ground moves when the line changes. Follow it to the instrument, where the proposed route has become a section: distance across the plan runs horizontally, ground height vertically. SAMPLE moves a yellow witness along both the section and the terrain.

The display gives a section length and its steepest sampled segment. At 0.25, route A is about 8.13 metres along the surface; B is about 10.40. B also has a slightly steeper sampled segment. Taking a detour has not automatically made this route easier. It has changed which features the proposal meets.

These readings leave work for the body. The section samples a line; your body has width. A capsule can meet a neighbouring slope the line does not touch. A controller's speed, step and slope rules also enter the encounter. The tested desktop body accepts floor angles up to 45 degrees, while route A's steepest sampled segment rises from about 24 degrees at 0.25 to about 58 at 0.90. The measurement helps us investigate the stalled walk without declaring the whole landscape impassable.

Look down at the yellow witness. Its printed height belongs to the triangle under that point. The terrain is made from 81 by 81 sampled positions, spaced ten centimetres apart. Between those positions, triangles supply a surface. Sampling the noise again between the vertices can give a slightly different answer: the collider is the constructed mesh, not an infinitely detailed function.

```gdscript
var mesh = create_mesh_from_heights(heights)
mesh_instance.mesh = mesh
create_collision_from_mesh(mesh)
```

The same mesh is sent to sight and collision. This is the extra connection the small relief spheres did not have. A displayed height can now catch a foot.

Find a place where the ground seems to fold over itself. Move sideways and look again. Every horizontal position in this heightfield receives one ground height. A cave would need a floor and a roof at some of the same positions. We would have to give the representation something else to hold. Carry the occupied volume from Noise Voxel back into this question.

The crease that catches one body might shelter another. This instrument tests walking; shelter would ask us to place another body and a line of sight. The same terrain can support questions that a successful crossing does not settle. We can learn its construction and still discover another use for what resisted us.

<!-- @dark_sphere -->

The dark orb rests on the raised margin. Its pulse continues while you compare routes or return the terrain to its starting height. RESET has a local reach. It does not recover the time spent choosing a way across.

The margin, the terrain and the orb hold different relations to change. One offers a steady place to return to; one changes when its height multiplier changes; one keeps time. A shared computational world can let those differences coexist, provided we say where each operation acts.

<!-- @ -->

In Noise Perlin Simplex, the next comparison changes the generator. Bring the habit of holding a question steady: if two surfaces differ, which operation changed, and which body makes that difference matter?



## Noise_Perlin_Simplex

Source: commons/maps/Noise_Perlin_Simplex/final.md

SHA256: 0748a01ffa376a61ac6790c252be37add52664da592686c5b9077fb6c7974447

# What counts as the same

A hollow on one side of the aisle faces a ridge on the other. It is easy to call that the difference between Perlin and simplex. Walk a little further before deciding.

Two changes of seed could have made two different pictures too. So could a different scale of sampling. We need a way to ask the fields a narrower question.

<!-- @simplex_noise -->

Start at the Simplex panel. Press REPLAY and choose a feature to recognise. Move FREQ a little, watch that feature change, then replay. The field returns to the declared setting. Its variation has a way back, as the colour grids did in Randomness.

In the previous room a height change caught the walking body. Here the small cubes leave space for us to walk around their arrangement. Each sampled coordinate receives a height and a colour. The underlying field relates neighbouring values; the cubes present selected values as separate steps. The grid we see is one way of reading that relation.

The Simplex visualizer asks for a value like this:

```gdscript
func generate_noise_at(x: float, z: float) -> float:
	return noise_generator.get_noise_2d(x * frequency, z * frequency)
```

The slider changes the coordinate multiplier. The display can keep the same cube positions while asking the field about a different scale. A ridge can change across an unmoving grid.

Find the pink marker. Press SAMPLE on the shared instrument and watch it move to another cube. Across the aisle, another marker takes the same address. Their heights need not agree. The readout now gives the coordinate, each field's answer and their signed difference.

```gdscript
func sample_pair(p: Vector2) -> Vector2:
	return Vector2(pair[0].sample_at(p.x,p.y), pair[1].sample_at(p.x,p.y))
```

One question goes to two functions. The coordinate is shared. The answer belongs to the function that returns it. A positive difference on the display means the Perlin value exceeds the simplex value at this address; it does not award a point to either landscape.

<!-- @perlin_noise -->

Cross to the Perlin panel and compare the readouts. Both begin with the same seed, octave count, frequency and gain. Their displays share amplitude, sample spacing and finish. The Perlin visualizer chooses its basis in this branch of `_noise_type_for`:

```gdscript
"perlin":
	return FastNoiseLite.TYPE_PERLIN
```

The Simplex visualizer chooses `TYPE_SIMPLEX`, which this engine implements as OpenSimplex2. The plate reads the choices back from the instantiated generators. Names can help us find a work; here we also have a way to check what they claim.

Both belong to gradient noise: a local direction contributes through its relation to a displacement, and contributions are combined into the value at an address. Perlin's lattice and OpenSimplex2's construction organise those contributions differently. The dot product from Vectors is still in the toolbox. The library has folded a longer calculation into the small call above; the call has not made that calculation disappear. [The engine's noise definitions](https://docs.godotengine.org/en/4.6/classes/class_fastnoiselite.html#enumerations).

Choose one comparison to keep in view: the turn of a ridge, the spacing of hollows, or the difference between answers at one coordinate. The shared seed makes each field repeatable. It does not make a ridge on one side the partner of a ridge on the other.

Now alter FREQ on just one side. Look back at the central plate. Alongside the different bases, it reports another difference: the scale at which the field is sampled. That one adjustment changes what you might have attributed to the basis. MATCH returns both generators to the declared settings. REPLAY on either side returns that side alone.

Press VIEW. Keep following the pink markers while the relief settles into two flat arrangements. The colour retains the sampled values. Nothing has been flattened inside the noise function; the display has stopped spending its answer on height.

The cubes remain at half-metre intervals. Their square arrangement is still present whichever basis produced the values. It would be easy to mistake the grid of the display for the lattice inside the calculation. VIEW gives us another way to notice that two decisions have been folded together.

Return to relief. The same answers regain height. In Noise Space 10 we joined height to collision so a change could stop a foot. These cubes are a visual comparison with a walking aisle between them. A visible surface and a surface that carries us ask for different work from the implementation.

Matching conditions costs us possibilities. One shared finish helps compare shape while withholding what another colour treatment might reveal. Half-metre samples give the field a body we can inspect; variation between those addresses has no cube of its own. The comparison makes some distinctions easier to see by agreeing to leave others out.

<!-- @perlin_noise_terrain -->

Behind the pair, a small pink sheet stands above a low plinth. Stay with it for a moment. Its surface changes in steps even while the two larger fields wait for another action.

Its timer advances a third sampling coordinate:

```gdscript
func _on_timer_timeout() -> void:
	if not _is_truthy(animate):
		return
	time_offset += 0.5
	generate_terrain()
```

The mesh helper samples a three-dimensional field. The timer visits another slice every half-second. We have met a coordinate changing before; here the change keeps arriving without another gesture. It is neither an erosion calculation nor a memory of the sheet's previous shape.

The artifact is called `perlin_noise_terrain`, but its helper leaves the generator's basis at the engine default, OpenSimplex2S. This retained work makes the room's question recur inside its own collection. Its one-metre sheet samples in index coordinates, uses seed one and has its own clock. It cannot serve as a third matched surface simply because it stands near the pair.

<!-- @dark_sphere -->

The dark orb changes too. Its pulse gives the eye another rhythm to follow, independent of the small sheet's half-second steps. MATCH does not restart either work.

A return always has a scope. We recovered the two fields' parameters, while the other bodies continued. Even a careful comparison takes place in a world that has more going on than the question currently admits.

<!-- @ -->

Look again at the hollow that first caught your attention. If you were choosing a landscape in which to hide, it might matter for a different reason than if you wanted a clear view. There need not be a winner on either side of the aisle. Keep the ability to repeat a field, change a condition and recognise what the comparison supports.

The small sheet keeps changing. A little noise, and something begins to feel organic. Perhaps that is the body we wanted. Its swelling can carry pleasure, uncertainty or a queer promise of becoming. The ease of the operation is useful: we can put a similar gesture on many different objects.

After several rooms, that usefulness can become a mental algorithmic wall. The familiar answer arrives before we have worked out the next question. Different bodies acquire a family resemblance. We can call this tendency blob culture and begin investigating it here, among our own objects. Its cheapness is the ease with which we can add the filter; what someone makes of that gesture can still matter deeply.

Stay with the sheet and ask what else this body could do. Its changing slice has no record of what happened to the preceding surface. We could give it stored states, neighbours that affect its next move, something to exchange with another body. Each would require another decision and something further to learn. Noise can remain part of those constructions.

In the next chapter, Cellular Automata, a row waits for its first update. We will let a cell's next state depend on the states beside it. Bring the pleasure of the moving surface, and leave room for another form.



## Lab_Path

Source: commons/maps/Lab_Path/final.md

SHA256: 30ec6de21896f63ab272d36d012cef582ef4bdd577687830bb8b14eda6512fc2

What can you explain when the busy displays are no longer doing it for you?

The last pair showed why a difference in appearance needs an account of how the pictures were made. This transition asks you to supply that account from one encounter you can remember clearly.

<!-- @dark_sphere -->

Pause where you can see the sphere. Let its slow rotation and changing glow continue while you describe one earlier example. Name the field that supplied values, the positions at which it was sampled, and the way those samples became visible.

Choose a second version in thought. Would changing the threshold alter the same field's classification, or would changing the seed supply different values? Predict one visible consequence of each choice. Use a remembered observation as the reason for your prediction.

Give your explanation twice. First describe only what you saw: a gap widened, a patch changed colour, or a column returned towards its earlier pose. Then describe the operation you think caused it. If the second account introduces a quantity you never observed, identify where you learned about it and what would make it visible. This small separation lets another person follow your reasoning without having to share your first impression of the room.

The sphere is a reference for this pause. It does not present a new noise experiment, and its pulse does not certify that your explanation is correct. A familiar object can help hold attention without measuring what that attention contains.

<!-- @ -->

If two explanations seem possible, keep both for a moment. Name an observation that would distinguish them. You might hold the seed fixed, separate colour from displacement, or compare a direct sample with a displaced sampling coordinate. A useful next action follows from the difference you still need to resolve.

You can also choose what you want to keep from the sequence besides a correct description. Perhaps it is a restless surface, an awkward gap or a route suggested by a ridge. State that attachment without requiring the numerical representation to contain all of it.

The cellular-automata rooms move from a field sampled at positions to states updated through local neighbourhoods. Bring the question of where a value comes from. A point can receive a function's answer, or it can change because of what its neighbours were doing in the previous step.



# cellularautomata

Declared order: CA_Introduction → CA_ElementaryRules → CA_GameOfLife → CA_BeyondBinary → CA_ExpandingSpace → CA_SoftRules → CA_AgentsCircuits → CA_EdgeOfChaos

Museum map-authored order differs: CA_Introduction → CA_ElementaryRules → CA_GameOfLife → CA_BeyondBinary → CA_ExpandingSpace → CA_SoftRules → CA_EdgeOfChaos. Treat this as route drift to inspect, not an editorial recommendation.


## CA_Introduction

Source: commons/maps/CA_Introduction/final.md

SHA256: 6f1d7de34b510fa4f6071ed4ec96432632e8fc8750bcbbecd260ef2574516b82

# What will the next row do?

The rug is already changing. Across the room, a small board holds one green cell and waits. Two ways of making a pattern occupy the same hall. Begin with the one that has left you time to answer.

We have carried noise a long way: across a sheet, into a volume, around the body and under a foot. A little variation can satisfy the first wish for something organic. Its ease is part of its power. It can also make that first answer so familiar that other possible forms remain in its shadow. Keep the pleasure of the blob. Bring an unfinished question with it.

<!-- @ca_rule_explorer -->

Find the board near the entrance side of the hall. The newest row sits along its far edge; the rest of the board is room for a past. Three small marks pick out a cell and its two neighbours. Read their states on the side plate, but leave NEXT for a moment. What would you make from these three?

Press STEP. One generation arrives, and the previous row moves towards you. The pink mark stays at the same address. Its state may change. The plate now reads this new generation and predicts the one that could follow it. We have advanced the local machine; the rug has kept its own time.

Begin with Rule 90 and the single seed. STEP once, then again. Follow one of the diagonal edges. Choose CELL to move the witness along the current row, and check a neighbourhood inside the pattern as well as one at its edge. Counting the green cells is tempting. Keep their order too: left, self, right.

The explorer consults its rule through these actual lines:

```gdscript
func _apply_rule(left: bool, center: bool, right: bool) -> bool:
	var neighborhood = (int(left) << 2) | (int(center) << 1) | int(right)
	return (rule >> neighborhood) & 1 == 1
```

Three on/off states make eight possible arrangements. The shifts place them into an index from zero to seven. The rule number stores eight answers, one bit for each arrangement. Reading the selected bit gives this cell's next state.

For Rule 90, compare `100` with `010`. Each contains one occupied cell. The answers differ. A count would have discarded a relation that this rule uses. A neighbourhood is already a decision about what information may matter.

Choose Rule 30 and keep the single seed. Its rows quickly become harder to anticipate by eye. The board still asks the same small question at every position. A more tangled picture has not made the instruction longer. RUN lets the generations arrive automatically; pressing it again holds them, and STEP always leaves this study held after one update.

The update writes a separate row. Here is the loop inside `_advance`, followed by the moment the new row becomes current:

```gdscript
for i in range(cells_x):
    var left = _current_row[(i - 1 + cells_x) % cells_x]
    var center = _current_row[i]
    var right = _current_row[(i + 1) % cells_x]
    new_row[i] = _apply_rule(left, center, right)

_current_row = new_row
```

All the questions go to the old row. An answer written at the left cannot slip into the question being asked at the right. This installation makes that separation part of its rule. A different update order would be another experiment to specify.

Press SEED. Two adjacent cells now occupy the starting row. The rule has stayed where you left it. Advance again and compare what happens where their consequences meet. Changing the beginning explores something that changing the rule alone could leave unseen. RST returns to the selected beginning and clears the visible history.

Keep stepping until a pattern reaches the boundary. The witness can cross it too: after cell 31 comes cell 0. The modulo operations in the loop join the two ends. What looks like a line on the desk is a ring to the calculation. Twenty-four rows fit on this board; older rows leave the display while their consequences remain in the current state. Once again, the visible past is smaller than the past that brought us here.

<!-- @persian_rug -->

Now approach the rug. A detail in one quarter has partners across the cloth. Find them before naming the symmetry. The pink border and golden interior are another division to follow. Both can change, but they do not consult identical conditions.

This work has a two-dimensional grid, several states and two sets of local rules. The border and interior decide differently when activity begins, continues or fades. After calculating a generation, the program also mirrors one quarter into the others. In `_enforce_quadrant`, one value is written into three reflected positions (comments between these assignments are omitted):

```gdscript
grid[row_offset + (width - 1 - x)] = val
grid[mirror_row_offset + x] = val
grid[mirror_row_offset + (width - 1 - x)] = val
```

The ornament has several makers: local updates, a chosen boundary, a palette, and this repeated act of copying. The mirror remains at work after the first seed. Knowing that can give us another way to enjoy the rug. We can follow a changing detail while noticing the procedure that makes its companions answer together.

The title invites an association with a textile tradition. These few operations do not account for that tradition, its materials or its makers. They produce this particular computational cloth. Its source offers other stencils and divisions to investigate later; the rug in this hall uses the mirrored quarters and frame.

<!-- @line_network_ca -->

Further along, the line network gives the cell another body. Occupied positions are joined by coloured segments. Move around it and let one apparent knot separate into lines at different depths. Some space that looked full can open when your viewpoint changes.

Its growth begins with a random walk. During a bounded burst of updates, occupied frontier positions may add a nearby cell. The drawing then chooses a recorded neighbour to connect to each newly encountered position. There is a detail worth keeping: the parent in the drawing is selected during the scan. The line does not prove which earlier cell caused the birth.

This is another construction of an organic form. Chance proposes an addition; stored occupancy constrains where it can occur; the renderer supplies connections and colour. The work may already have finished its twenty growth updates when you reach it. A still network can be the consequence of that programmed limit. Stillness alone cannot tell us that growth exhausted every possibility.

We can begin to distinguish forms by the relations that sustain them. The board keeps a row and repeatedly rewrites it. The rug combines local activity with an imposed symmetry. The network retains occupied positions and draws a selected account of their connections. Their resemblance to living things can invite us closer; the code gives us further differences to explore.

<!-- @ -->

The other works remain in the room: agents painting a shared surface, a Rule 110 display, the showcase and the orb. Let them offer further directions without asking this first encounter to explain them all.

For now, carry three choices: what a cell can hold, which neighbours it can consult, and when its answer becomes available to others. Our next comparison, the structure-growth specimen, makes the neighbourhood three-dimensional and gives disappearance more than one state. What forms need a little longer to go away?



## CA_ElementaryRules

Source: commons/maps/CA_ElementaryRules/final.md

SHA256: 2638c5ee9765bb8da3c16c383f559b1b35eb7f09dee94dda64005c770c8f3f69

# A cell with a past

How would you recognise a cell that has stopped being active but has not yet disappeared?

The previous hall let three cells answer a question about the next row. Here the neighbourhood reaches behind what we can see. A small volume waits above the opening in the floor. Walk along its rim. Two marks that seemed to touch can separate as you move; another cell has been behind them all along.

<!-- @structure_growth -->

Begin at the console. The structure is held at its starting generation. Pink means active. Press STEP once and look for green. A green cell is still occupied, still drawn where the surface allows it, but it has stopped contributing to its neighbours' active count. Follow it through another step. What does it leave available?

Each position consults a cube of three by three by three positions. Remove the position itself and twenty-six neighbours remain: through faces, along edges, across corners. The source gathers their activity with this test:

```gdscript
for offset in neighbor_offsets:
    if current_state[idx + offset] == 1:
        neighbors += 1
```

The comparison is to `1`. A green neighbour holds `2`. Being present and being counted have parted company.

The inscription `6-8/6-8/3/M` names this installation's agreement. An active cell survives with six, seven or eight active neighbours. An empty cell becomes active with those same counts. Three states are available: empty, active, fading. `M` denotes the surrounding Moore neighbourhood, which this implementation fixes at twenty-six positions.

Now find a place that has turned green and imagine it surrounded by seven active neighbours. Will it become pink at the next step? Birth is tempting, but the code has already sent this cell down another branch. These are the lines for a state above one:

```gdscript
if state < rule_states - 1:
    next_state[idx] = state + 1
else:
    next_state[idx] = 0
```

Here `rule_states` is three, so state two goes to zero. It must first become empty. Only a later generation can consider its birth again. Disappearance takes time, and that interval changes where new activity is possible. We have acquired another means of shaping a body: a position can retain a past that temporarily prevents a beginning.

Every answer is written into a second array. The old volume supplies all the questions before the arrays exchange places. There is no privileged first cell whose new answer reaches its neighbours early. STEP gives this local agreement one generation; the rest of the museum keeps running.

Press VIEW. The structure takes on a gradient from dark to light with height. Nothing has advanced. The same cells can look like one continuous material now that their different states share a colour scale. Press VIEW again and recover the distinction. The finish has changed what we can readily recognise. Which reading did we take for the object itself?

The console also separates ACTIVE, FADING and DRAWN. The last number can be smaller than the first two added together. The renderer omits occupied cells surrounded on all six faces by occupied cells. Their state remains in the calculation. What the surface conceals can still help determine its next form. These visible cubes have no individual collision bodies; their appearance is not a promise of footholds.

Try RUN, then hold it. REPLAY returns to the same seeded beginning, so a second observation can follow a detail missed the first time. Twenty steps fit the initial observation budget. At that limit the machine holds; +20 permits another interval without reseeding. Read CHANGED beside the generation count. A stopped clock alone cannot tell us whether the configuration has stopped changing. Zero changed cells, after an update under these fixed conditions, gives stronger evidence: that whole state reproduced itself.

There is an edge to this world too. Its outer cells stay empty. They do not wrap around to the opposite face as the previous board did. Near that boundary, a cell cannot find the same company it might find in the interior. The body has a rule, a beginning, an edge and a chosen duration of observation. Its organic appearance does not tell us which of these has made a particular feature possible.

<!-- @ -->

The dark orb remains beside the route as a further encounter. For now, carry the difference between an active cell, a lingering cell and a cell hidden by the drawing. The familiar wish to give something life has opened into more particular questions. What must remain? What must become available again? In the next hall, generations will themselves become a structure laid out in space. A past we have just replaced will become something we can approach.



## CA_GameOfLife

Source: commons/maps/CA_GameOfLife/final.md

SHA256: 780fca9f4f6757699d528ddc4e5ab68f33f7585e93c32446deb403f1e2dceff8

# A history you can inhabit

<!-- @ca_bridge -->

A gap in the screen lets you see through. The same gap in the floor asks something else of your body.

Stand at the desk before the basin. Its small coloured squares have relatives ahead: tiles laid across the recess, and a lattice standing along its side. Find the gold line in all three places. Press ROW. The line moves into an earlier part of the pattern. Nothing has been recalculated. You are moving your attention through a record.

The room greets you with twelve rows already made. Stay on the museum floor and press REPLAY. The record returns to one occupied square. There is less floor now, and less ornament. This button resets the experiment; the museum's clock continues.

Before STEP, look at the three positions around that square. Which squares will appear in the next row? Press once. A short line arrives on the desk, another row of support appears ahead, and the screen receives a vertical strip. Make one more prediction before asking it to continue.

The rule reads left, centre and right in one row. Their ordered bits select an answer:

```gdscript
var index = (a << 2) | (b << 1) | c
```

Here `a`, `b` and `c` are the three states. The shifts give their positions different weights: four, two, one. `100` and `001` both contain one occupied cell, but ask different questions of the rule. The bridge's `_apply_rule` reads bit `index` from the number 30. Each answer is written into a new row while the old row remains available to its other neighbours.

The study keeps that new row:

```gdscript
var next_row: Array = work._calculate_next_row(history.back())
history.append(next_row)
```

These lines come from `history_study.gd`, which calls the original bridge's solver. The record holds fifteen sites across and at most twenty-four rows. At the edges, left and right wrap. At the end of the record, this instrument stops adding rows. The first boundary belongs to the neighbourhood; the second belongs to our viewing budget.

Follow the gold line onto the tiles. Depth is doing the work of time. In the earlier volume, neighbours surrounded a cell within one three-dimensional state. Here a nearby row is an earlier or later moment. A solid-looking arrangement can hide that difference.

The same record is dressed three ways. On the desk, a one becomes a coloured square. In the basin, it becomes a tile with collision. In the lattice, it becomes coloured infill in a bronze frame. There is one stored history, but its uses have different consequences. The frame stands independently; the pattern does not calculate structural engineering. The basin has a lower collecting floor and end ramps, and the museum passage continues alongside it.

Try SEED, which changes the beginning while keeping Rule 30. Or return to SINGLE and press FLIP X9: one additional site in the starting row changes. STEP through the consequences. Later rows are made again from this beginning; we cannot honestly keep the old descendants and call them the same experiment.

Would you choose the same beginning for a screen and a crossing? You may want the holes in one and resist them in the other. A body we liked as ornament becomes awkward underfoot. This is a way of testing our desire against an implementation: change its use and discover what the beautiful surface had allowed us to overlook.

The next hall holds a two-dimensional present. A pattern will seem to travel while its cell addresses stay still. Keep the distinction between a recorded body and the procedure that continues it.

<!-- @ -->



## CA_BeyondBinary

Source: commons/maps/CA_BeyondBinary/final.md

SHA256: 4e649666dbd3b3d6a10d68cf8a500aa15e2a6b62c2eaf4b80f50a55434a95c8d

# A pattern visits an address

<!-- @game_of_life_petri -->

Five pale cells wait in the dish. A larger version lies in the floor beyond it. Three lamps stand along its edge. They are dark.

Press STEP four times. The arrangement has changed at every step; now something about it has returned. Compare its position with one of the gold squares. What has travelled?

REPLAY brings the five cells back. This time keep your attention on the square marked A, at address (10,10). Step towards it. A cell becomes occupied; a lamp lights. Step again. Follow the square for a while, even when the more recognisable figure tempts your eye away. The address keeps its place. The pattern is already elsewhere.

You can cross the large display. Its empty cells still support your feet. In the previous room, occupancy became a stepping tile over a lower basin. Here it becomes colour on an ordinary floor. We have carried the array forward and given it another job. A zero does not contain an instruction to make a hole.

Try BLINKER. Three cells lie in a line. One step turns the line; another brings it back. Watch A, the middle cell. The surroundings alternate while this address remains occupied. Its lamp stays lit. Returning, travelling and staying can belong to different parts of the same small event.

The dish runs Conway's Game of Life. Each cell has eight neighbours. An occupied cell survives with two or three occupied neighbours; an empty cell becomes occupied with exactly three. These are the lines that choose its next state:

```gdscript
if alive:
    _next_grid[y][x] = neighbors == 2 or neighbors == 3
else:
    _next_grid[y][x] = neighbors == 3
```

Every answer goes into another array. Only when the whole plane has been read do the two buffers exchange places. A cell later in the loop cannot borrow an answer made earlier in this generation. At the edges, the neighbourhood wraps to the opposite side.

In the glider beginning, four generations reproduce the arrangement one address further along each axis. No instruction has moved a glider object. No cell carries a ticket for that journey. We recognise a body across successive relations among sites. The recognition is useful: it lets us anticipate a visit. It also leaves something out. Following the figure, we can miss the cells that cease to participate.

Try LINK while a lamp is lit. The light goes out; the figure remains. STEP still changes it. The lamp's relation to this world has been written separately:

```gdscript
var occupied: bool = work._grid[site.y][site.x]
receiver.receive(occupied, linked, count_event)
```

That address could have been connected to another object. Here it controls an opal lamp. The lamp does not recognise a glider: any occupied state at its assigned address will light it when connected. Nor does its light return an influence to the cells. We have made a small, one-way traffic between the simulation and the room. Its boundary is a decision we can inspect and change.

Choose MEET. The same glider begins with a four-cell block in its path. Predict which lamps will light. Advance, then compare with GLIDER. Each button prepares a fresh beginning, so the difference can be revisited. In this particular meeting, by generation 24 the field is empty. The rule has stayed the same; what the glider could continue to be depended on what it met.

There is pleasure in the travelling figure and in the room answering it. We need not turn that pleasure into proof of a living creature, or ask a fluid-looking body to stand for every possible difference. This body has particular conditions. Another encounter may interrupt it; another connection may let it do something we have not yet tried.

RUN advances this local experiment slowly and holds it at generation 48. The museum clock continues. We leave a finite observation, not a verdict on everything the rule can make.

<!-- @ -->

So far the visitor has chosen a beginning and watched an output. In the next room, approaching a surface enters the calculation. What happens when the body doing the observing becomes one of the conditions?



## CA_ExpandingSpace

Source: commons/maps/CA_ExpandingSpace/final.md

SHA256: e862892a45edaa1f9a3e0752638b808873835f27f6bf4de0c94fe329f62b9726

# The surface includes you

<!-- @decaying_bridge -->

The path looks available. Five tiles across, a longer line ahead. Its colours repeat in a panel along the wall. Beneath it lies a shallow basin, already drawn with the addresses of tiles that have not yet disappeared.

Begin at the desk. SOURCE can nominate the pink probe in your place. With PROBE / NEAR showing, press RUN. Follow the gold square W. The number falls. The tile changes colour, then becomes a faint sheet through which the basin is visible. Stop the local experiment. How much of a path is still there?

Use NEAR/FAR to withdraw the probe and run again. Watch the edge of the depleted region before its centre. Something returns through what remained around it. There is no separate instruction ordering this particular patch to grow back into its old outline.

RESTORE prepares a full bridge. Change SOURCE to VISITOR and start RUN. Your position now takes the probe's place. Approach the marked region, wait, move away. The ordinary museum floor continues alongside the basin; recovery ramps rise from its left side. On the bridge, lingering can cost you support. The faint tile can still be seen after it can no longer carry you.

The bridge's variable is called health. Here that means a number between zero and one. The name lends it a small biological story, but the operations are available to read. Nearby cells lose a fixed amount on each update:

```gdscript
if present and cell_position(coord).distance_to(local_visitor) < decay_radius:
    next[coord] = maxf(0.0, health - decay_speed * dt * 5.0)
```

Distance is measured in three dimensions from a cell's centre to the tracked body's origin. No scale weighs your feet. The surface can respond before your body is standing on the cell you are watching. The pink probe can produce the same numerical influence without a person above it. Which part of our first explanation came from the event, and which part did the appearance of a bridge invite us to supply?

Outside that radius, a cell can recover through its four immediate axial neighbours. Each neighbour above 0.5 contributes to recovery. At 0.3 a tile can support you, yet it cannot contribute as a healthy neighbour. Below 0.2, its collider is disabled:

```gdscript
colliders[coord].set_deferred("disabled", health < 0.2)
```

One changing value meets two different thresholds. Being visible, carrying a visitor and helping a neighbour recover are separate permissions. The wall uses the same health materials, but its coloured panels supply no bridge collision. A room can wear an answer without offering the same way through it.

There is another condition hidden in “each update.” Choose CHAIN for a small prepared comparison. The bridge begins mostly depleted; three adjacent values are 0.600, 0.495 and 0.000. SOURCE becomes NONE. We can attend to recovery without moving the input at the same time.

STEP once in SYNC. The middle value crosses 0.5. Has the next cell been allowed to use that change already? ORDER switches to SCAN and restores the same beginning. Step again, then use REVERSE and repeat. A different answer can appear even though the neighbouring cells and the amount of time are unchanged. The loop has a direction too.

SYNC reads the previous field throughout the update. SCAN reads answers already written during the same pass. In this study, changing scan direction leaves the synchronous result unchanged; in-place recovery can change. The choice sits in a single line:

```gdscript
var read_states: Dictionary = previous if snapshot_reads else next
```

We have returned to the two arrays from the Life dish. Their separation now changes when a weakened surface can help another part of itself. The rule includes a schedule, even when the picture conceals it.

Restore the full bridge and return to the visitor input. There is pleasure in architecture answering us, and a stranger pleasure when its answer interrupts the role we expected it to play. We can study that relation without deciding that a responsive surface must be alive. A fully depleted field with no healthy neighbours remains depleted. Withdrawal alone does not promise repair.

At thirty simulated seconds this study holds. The museum continues. We leave with a more precise question than whether the path is living: which relations let it carry a body, recover, or become unavailable?

<!-- @ -->

The next room asks what a cell can receive from its neighbourhood when counting healthy neighbours is no longer enough. A softer-looking surface will need another working rule to earn that difference.



## CA_SoftRules

Source: commons/maps/CA_SoftRules/final.md

SHA256: e1a93c05bc84db4fc5bfef8240ff0b5c369181c0cbf31170c15ff4e9ceb82dab

# What can a cell receive?

<!-- @rd_artifact -->

Two small squares wait on the tables. Behind them, the same squares wait on curved walls. The room has already enlarged their answer, although neither field has taken a step.

At the side desk, find W. It lies just outside the seeded square. Its V reading is zero in both fields. Press STEP once. On the left, a little arrives. On the right, nothing. Look back at the pictures: can you find that difference without the numbers?

Press +100 and let the local clock complete its hundred updates. The fields begin to part. They began with the same values, at the same addresses. They have the same reaction. What has the right-hand square been denied?

EXCHANGE B turns its neighbourhood exchange on and restores both beginnings. Advance again. The two fields now agree. Switch exchange off, replay, and look for the first place where they differ. We can locate the missing relation before giving the result a name.

In the previous hall a neighbour above half health counted as one contribution to recovery. Here a cell stores two concentrations, U and V. It receives differences in concentration from the four sites beside it. For each field, the sum is its neighbours minus four copies of itself:

```gdscript
return a[y*N+(x+N-1)%N]+a[y*N+(x+1)%N]+a[((y+N-1)%N)*N+x]+a[((y+1)%N)*N+x]-4.0*a[y*N+x]
```

The repeated subtraction matters. If all five values agree, this part of the update contributes zero. A higher neighbour can send a positive contribution; a lower neighbourhood can draw one away. No neighbour has to cross a health threshold to count. How much it differs is now part of what it can offer.

There is also a reaction at the address itself. The product U × V × V removes some U and adds some V. A feed term replenishes U; another term removes V. The installation uses the same arithmetic as the project's existing Gray–Scott generator, now exposed one update at a time:

```gdscript
var uvv:float=a*b*b
```

```gdscript
next_u[i]=clampf(a+coupling*0.16*lap_u-uvv+FEED*(1.0-a),0.0,1.0)
next_v[i]=clampf(b+coupling*0.08*lap_v+uvv-(KILL+FEED)*b,0.0,1.0)
```

With exchange off, the right-hand field still reacts. But at an unseeded address V is zero, so U × V × V is also zero. Nothing in that local reaction can make its first V arrive. The left-hand field can receive it. This difference is small enough to calculate and large enough to alter the wall.

Keep that distinction in hand. “Soft” is not a promise that the rule is gentle or that every boundary has disappeared. Both fields still occupy a 32-by-32 grid. The arithmetic writes into separate next arrays before swapping them into the present. Values are clamped between zero and one. At an edge, the remainder operator wraps the neighbour index to the opposite side. The wall has a visible border that the calculation does not share.

Use VIEW U/V. Another distribution appears without a single new update. The initial view doubles V before mapping it into colour; the U view has its own palette. A colour can saturate while the stored value still has room to change. An image is already an interpretation of the field.

Now walk between the two curved displays. COAT removes their colour surfaces while the table fields continue. Bring them back. Nothing has moved from the table into the architecture: each pair uses the same texture. The fixed museum floor carries you through both versions. The room can wear this process, and later another body could wear it, but a material assignment has not supplied sensation, growth or agency.

Try INJECT. Both fields receive the same small second patch. Let it run. We are no longer only watching a prepared beginning; we have entered another event into its history. REPLAY can restore that beginning. It cannot make our first encounter with the difference happen again.

<!-- @the_clockmaker_of_rules -->

Further on, the clockmaker has laid out trays, stencils and small worlds. The brass shapes make reading and writing almost look like trades we could perform with our hands. Find the fractional ring. It is a still radial diagram. Its graded appearance does not demonstrate a running Lenia field, and the ornamental crank cannot advance it.

Compare that invitation with the walls we have just left. Both offer pleasure in a patterned body; their means of producing it differ. We need neither reject the ornament nor grant it an operation it does not have. A diagram can help us imagine the machine, then leave us with something still to build.

<!-- @ -->

The local study holds after 2,400 updates. The museum goes on. Carry the matched beginning and the visible clock into the next hall: when a small intervention changes an outcome, how will we tell what actually changed?



## CA_AgentsCircuits

Source: commons/maps/CA_AgentsCircuits/final.md

SHA256: 3aafdee5204f474d53da18dd5fe5a85f3ef9bffe3cae6ab02b0c6a06db855625

# The same pattern, different work

<!-- @ca_rule_explorer -->

Can two constructions resemble one another without doing the same calculation?

Set the rule explorer to Rule 90 and reset its central seed. Follow the triangular gaps that develop between occupied cells. Choose a larger triangle and look for smaller ones arranged within its boundary. Let the rule continue until you can compare more than one scale.

Each new cell is still calculated from a local neighbourhood. No instruction tells the display to draw a large triangle and then decorate it with smaller triangles. The repeated structure becomes visible through many applications of the rule.

Before leaving the rule display, choose one gap whose position you could describe to someone else. Describe the occupied cells around it as well as the empty region itself. A pattern can appear similar because its holes correspond, because its filled parts correspond, or because its outline does. Those are different comparisons. Carry that description to the pyramid and test only the relation you chose first. If it fails, locate the precise mismatch before choosing another relation; otherwise resemblance can become a moving target that never risks being wrong.

<!-- @sierpinski_pyramid -->

Now turn to the Sierpinski pyramid. Find a small pyramid and compare where its neighbours sit. Then step back and look for the same arrangement at the next scale. This construction makes smaller copies recursively at selected corners. Its procedure begins with a shape and a copying arrangement, rather than a row whose next state must be calculated.

The resemblance is useful because it gives you a question to test. At which scales do gaps correspond? Which relations are altered by moving from a flat history to a volume? You need not force every visible feature into a match. A failed correspondence tells you where the analogy stops.

Both encounters produce organised patterns, but neither appearance alone proves the presence of an agent, a circuit or a general-purpose computer. Those claims require additional structure: states that can represent something, operations that transform them, and a way of checking the result.

A useful variation would keep the pyramid fixed while trying several different seeds in Rule 90. Some seeds preserve familiar triangular relations; others overlap them. The comparison would expose how much the resemblance depends on the starting condition.

<!-- @ -->

Next, the sequence asks what happens when a local update admits graded states and disturbance. Keep asking whether a name describes an observed relation or simply encourages you to see one.



## CA_EdgeOfChaos

Source: commons/maps/CA_EdgeOfChaos/final.md

SHA256: 5851c73fa78f74690eb5019fdd7c4facdd6994abddcf995563661073fc30dce9

# How far does one difference go?

<!-- @self_organization_ca -->

Two volumes wait at the same update. Their colours almost agree. Somewhere in B, one address holds a value one greater than its counterpart in A. Can you find it without the instrument telling you where to look?

Walk between them. The floor carries a section of their difference; the cases ahead show A, B and the difference separately. These are ways of looking into the same two volumes. A wall is a slice through space. It is not the next generation. Use Z SLICE and watch what remains unchanged on the counter.

Return to the console. Press STEP. Follow the lit difference for a few updates, then use REPLAY to meet the same beginning again. ONE CELL removes the intervention, or restores it. With the intervention removed, both runs should agree through every update, even when the disturbance is loud. What would it mean if they did not?

The two runs receive the same forcing value at the same address and update. This is a deliberately shared, reproducible schedule. Without that agreement, a second source of difference would enter while we were trying to follow the first. The comparison makes a small experimental world inside a larger one whose clock continues.

Here is the local instruction, before storage:

```gdscript
var drive:float=disturbance*sample(i,tick)
var va:float=clampf(a[i]*(1.0-coupling)+sa/neighbours[i].size()*coupling+drive,0.0,9.0)
```

`sa` is the sum of A's valid neighbours. Interior cells have twenty-six; the corner has seven. Every cell reads the previous volume. PULL changes how far it moves toward that average. DRIVE changes the size of the added disturbance. The controls reset both runs, keeping the comparison legible. One gesture no longer changes both tendencies at once.

Bring DRIVE to zero. Choose the uniform beginning with SEED, leave PULL at 0.25 and ONE CELL enabled. In INTEGER storage, press STEP. The difference is gone. Replay, switch STORE to FRACTIONAL and take the same step. Now twenty-seven addresses differ, but the largest difference is smaller than before: 0.75 instead of one.

More places carry it. Less of it remains at any one place.

The fork is one short line:

```gdscript
na[i]=float(int(va)) if integer_storage else va
```

The integer conversion removes the fractional part of these nonnegative values. The pull that took five toward four produced 4.75. The stored integer is four. Around it, smaller fractional changes also fell away. A rule about neighbours was accompanied by another rule about what a value may keep.

Continue the fractional run. The wall of difference becomes broad and luminous. Look down at the gain printed on the readout. The display is increasing its sensitivity as the largest difference fades. Its brightness is a decision about visibility. Read the maximum alongside the number of affected cells: that count includes only differences above 0.000001. A trace may leave the counter before it leaves the stored values.

Turn PULL down to zero, with DRIVE still zero, and replay. The intervention stays at its original address. This stillness has kept a memory that the smoothing run lost. We would miss something if we arrived already certain that a moving, complicated-looking field must be the more interesting body.

The hall is called Edge of Chaos. Let the name remain a question. Here the fractional update averages nearby values and adds matched forcing; a spreading difference alone does not establish chaotic amplification. The integer conversion introduces thresholds of its own. We have measured some consequences of those choices. We have not located the one permissible region where life, computation or queerness can exist.

The other works remain in the rear gallery: a screen, local transmission and recovery, a cellular fog field and growing cracks. Each asks for its own account of what passes between neighbours, what is stored, and what the image omits. A shared visual restlessness does not make their rules equivalent.

<!-- @ -->

The next hall, Fractal_Recursion, changes the instruction. Instead of waiting for local exchanges to assemble a larger resemblance, a procedure explicitly asks for another instance of itself. Carry this distinction with you: a form can resemble its neighbour, inherit an earlier state, or be told to repeat. The resemblance does not yet explain the making.



# fractals

Declared order: Fractal_Recursion → Fractal_RecursiveTrees → Fractal_CantorSet → Fractal_KochSierpinski → Fractal_MengerSponge → Fractal_GoldenSpiral → Fractal_Synthesis


## Fractal_Recursion

Source: commons/maps/Fractal_Recursion/final.md

SHA256: 3f072d996797876cc871cac46b080ff437270824ad5b70f77c9d0bd9c4926775

How many times can *again* happen?

<!-- @fractal_recursion_2 -->

A square waits above the first desk. Press MORE. Another square appears inside it, half as wide. Ask again. The instruction is brief enough to hold in your head; the shrinking squares soon become harder to hold in your eyes.

Before opening RULE, try LAYOUT. The squares spread into a descending row. Nothing has been added. What looked like an interior can be arranged as a succession. COLLAPSE presses all the drawn squares down to the smallest term, leaving the outer frame where it was. The count does not fall with their visibility.

Here is the self-call from the artifact:

```gdscript
var new_size: float = size * size_reduction
_draw_recursive_pattern(center, new_size, d - 1)
```

The function has just drawn a square. It now calls itself with a smaller size and one less level to spend. At the beginning of each call, this condition can return it to the caller:

```gdscript
if d <= 0 or size < TERM_MIN_SIZE:
    return
```

`TERM_MIN_SIZE` is one centimetre. This desk also caps the requested depth at seven. Those are different limits: a chosen number of calls and a chosen minimum size. Neither is the same as the smallest detail your eye can distinguish in the helmet.

Seven levels produce seven squares. One call makes one further call. We could also write this particular descent as a loop. Seeing a square inside another square does not tell us which program made it. We had to look behind the image.

<!-- @example_8_3_recursion_circles_vr -->

The other desk begins with one ring. Predict the count after MORE. Five. Once more: twenty-one. The footprint remains roughly the same while the number of things occupying it changes quickly.

Each call draws its ring, then makes four smaller calls, shifting their centres right, left, up and down. Four levels leave `1 + 4 + 16 + 64` rings: eighty-five. The fifth leaves three hundred and forty-one. “One more” has acquired a different cost.

Return to depth four and try PACKING. The child radius changes; the number of rings stays. At depth five, DUST loses a whole level: its smallest requested radius falls below the source's one-centimetre cutoff. A depth allowance does not guarantee that every call will draw. Some overlap, some meet, some separate. TURN releases their planes into the artifact's rotating motion. Stop it to return to the frontal comparison. An apparent tangle can come from placement and pose as well as from adding more things.

The room can accommodate three hundred and forty-one rings. That does not mean it has made three hundred and forty-one distinctions easy to read. We already met this gap at the trace: what is stored, what is drawn, and what becomes available to a body do not have identical resolutions.

<!-- @cube_subdivision -->

Now a cube waits on a plinth. Press SPLIT. Eight smaller cubes take its place. Press again. Fifteen, not sixty-four. This machine divides one selected cell at a time.

Choose DRILL and spend the twelve splits. Then choose SPREAD and spend the same allowance. Both end with eighty-five cells. DRILL follows one corner into smaller and smaller scales; SPREAD chooses a cell from the shallowest remaining level. The readout reaches depth twelve in one case and depth three in the other. Equal counts have bought different bodies.

LOTS draws from the remaining population. Its seed is fixed here. BEGIN lets you repeat the same choices and inspect something you missed. Repetition becomes a way of paying attention.

The source sets a child's scale like this:

```gdscript
var new_scale = cube_scale * 0.5 * 0.9
```

Half, then a little smaller. The gaps that make the division legible are authored too. And the tiny cell that DRILL keeps choosing still costs something even after its difference becomes difficult to see. More work need not yield more experience. Where would you spend the next split?

<!-- @recursive_chair -->

At the last desk, NEXT starts to make a chair. After the first cut, press GHOST. Eleven pale cells return around the sixteen that were kept. SCAR marks the discarded centres; GONE hides those witnesses again. The choice of what to keep has become visible beside its result.

Something else moved. The first stage lifts the divided lattice; subsequent stages flatten the seat, extend legs and back, then add armrests. The chair was not simply waiting inside the original cube. Parts are selected, translated, stretched and added according to an intention about chairs.

This artifact carries “recursive” in its name, but its construction runs through five authored stages. There is no self-call in that sequence. Its presence beside the squares is useful precisely because a familiar appearance can conceal a different procedure.

<!-- @ -->

The table, staircase, pagoda and other works remain beyond the desks, a collection to return to with these distinctions in hand. We do not have to make every object evidence for the same claim.

A rule, a stopping condition, a choice of where to continue: we can now separate them. In the next hall the call branches. What does a tree inherit from the branch before it, and where can it differ?



## Fractal_RecursiveTrees

Source: commons/maps/Fractal_RecursiveTrees/final.md

SHA256: 173350e90de9a82d762378768a0a7efcd41b7f7fc7c936dca467d7190f0da0fc

# Where will the next branch go?

<!-- @recursive_tree_2 -->

A trunk waits. Where would you put its first fork?

Press GROW. Two branches appear at its tip. Press again, following one of those branches rather than the outline of the whole tree. Each new pair begins where a previous segment ends. Predict the next fork before asking for it.

The previous room let one call become several. Here we give those calls a place to start, a direction and a length. Four presses leave thirty-one segments, including the trunk. The fourth generation contains sixteen of them. Shorter branches do not mean fewer branches.

Leave the generation count where it is and press ANGLE. The tree opens. Press again: its branches draw closer to the direction their parents were taking. The button cycles through three turns, measured from the parent direction. Follow the same first fork. Its descendants have moved, but none has been added or removed.

Now press LENGTH. The ratio changes from 0.70 to 0.85: each child inherits more of its parent's length. The next press takes it to 0.50. You can make a crowded body or a much smaller one without changing the number of segments. Walk around it. A branch that seemed short from the desk may have been pointing towards you.

These lines come from the growing tree's implementation:

```gdscript
var new_length = parent_data.length * length_reduction
```

And, after the new direction has been calculated:

```gdscript
var end_position = parent_pos + branch_direction * new_length
```

The second line hands the next fork its beginning. A vector, a multiplication and an addition carry the body further. What looked like a tree can be followed as a succession of these handovers.

Press FORKS at the fourth generation. Three descendants now leave each tip. The display rises from thirty-one to one hundred and twenty-one segments. This change adds connections to the branching graph; turning or lengthening its existing edges did not. A visible crossing of two branches still does not join them in the program.

RESET returns to the trunk and the original settings. This specimen uses no random variation. Repeat the same choices and the same branches return. Growth here is a queue of instructions, advanced one generation at a time. The surrounding museum continues while the tree waits.

There is no light to seek, no root taking water, no neighbour whose shade changes the next fork. The branches are visible meshes; they do not offer the player's body a climbable support. Their outline invites a promise that their implementation has not made. What would we have to add for one of these forks to become shelter?

<!-- @recursive_tree -->

Across the approach, the red block tree has already spent its calls. Choose a large branch and follow it towards its smaller descendants. At a fork, predict the next division, then find another fork at a similar depth. A shared procedure need not give them the same dimensions or the same number of children.

Press STRATA. Colour separates three branching levels from the trunk. Follow a route to its last visible block. REACH draws the accumulated bounds; ENDS adds marks at the handover and terminal branches. FORM returns the original colours. These readings belong to the same built geometry. Changing the view does not draw another tree.

This tree does use random choices, from the seed shown on its desk. The choices vary its branches within a fixed construction rule. A seed can repeat an arrangement; it cannot tell us which arrangements the rule never permits. Even the blunt boxes can persuade us to call it organic. We can enjoy that recognition and still ask what it has made too easy to recognise.

<!-- @ -->

Further in, the downward trees, the mesh fractal, the desk and the small subdivision cubes keep other possibilities in view. They need not all answer the same question. The old enclosure remains a detour around something we cannot see from every position. We have more procedures to learn before resemblance becomes our only way to choose a body.

Next comes Cantor: another generation, this time made by deciding what will be removed.



## Fractal_CantorSet

Source: commons/maps/Fractal_CantorSet/final.md

SHA256: 58393f2bf041b51e88f6aa6a00944314f8f485aee169dbb73fe5e8a73c6d7c7e

# More pieces, less material

<!-- @cantor_set -->

One bar is waiting. Where could it go if we let it become two?

Press NEXT. The new pair appears beneath it. Their outside ends reach as far as the first bar, but the middle is missing. Press again. Look for the new gaps before counting the pieces. Each piece has lost its own middle; the first large gap has not been divided or repaired.

The trees sent another branch into space. Here another generation leaves less behind. At the fifth cut, thirty-two pieces share less than a metre of the six metres we began with. The desk counts the latest row. Above it, the old bars are still present. The whole display has become busier while the thing it is recording has become smaller in total length.

Turn HISTORY off. There is much less to look at. The kept length does not change. The earlier rows were a record we added so we could follow the operation. They were never extra members of the latest generation.

GHOST brings back pale marks where this generation cut its middles. They have no collision. The display can remember an absence without filling it with something that supports a body. Turn HISTORY on again and follow the larger absences upwards to the rows where they first appeared.

These two lines make the next pair in the bar's code:

```gdscript
var new_length = bar_length / 3.0
var offset = bar_length / 3.0
```

The new bars are placed at the old centre minus that offset and the old centre plus it. Their width is `new_length`. Two thirds remain, separated by the third for which we create no solid bar. Repeating the operation gives us:

```text
pieces      = 2^n
piece length = 6 / 3^n
kept length  = 6 * (2/3)^n
```

The count rises as the retained length falls. Neither number tells us how much work the renderer is doing. With history visible, it draws every earlier row as well. At five cuts that means sixty-three solid bars, before we count the ghosts, the desk or the rest of the room.

The screen stops at five. Its smallest pieces still have width, height and depth. The mathematical construction asks us to continue without a last cut. Its limiting set has zero total length and uncountably many points. We have not displayed that limit. We have made a finite instrument for approaching its rule.

From here the gaps can look generous. Carry that impression up the ramp.

<!-- @example_8_4_cantor_pagoda_vr -->

There is a broad opening under the pink beam. Walk through it. The same removal that interrupted a bar now offers a passage.

Return to the desk and press CUT twice. Smaller openings appear beside the first one. Choose one that looks wide enough, go up the ramp and try it. At this setting the gaps include three metres, one metre and a third of a metre. All are gaps. They do not all admit the same body.

The rule supplied intervals. The pagoda gave them height and depth, stacked their history above them, and made their surfaces collide with us. Here is the box shape used by its collision code:

```gdscript
shape.size = Vector3(width, block_height, block_thickness)
```

The interval's width is only one of those three decisions. Press DEPTH: the passage becomes longer or shorter while its opening stays the same width. LATEST removes the earlier levels overhead. The ground-level intervals remain; the roof was our way of arranging their past.

Try the narrow gap once more. The simulation does not collide with every fold of your clothes. It tests a proxy body. A passage can exclude that body even when the eye can travel through it. The obstruction belongs to a relation between the gap and the body we have implemented. To make a way through, we could widen the opening, change the body, or change which surfaces count as solid. Each choice makes a different world.

More cuts have made more openings, but many are too small for this visitor. Nothing in the operation promises that more detail will make more room for us. And still we want to look inside. That desire can lead us back to the rule, to ask which of its decisions might move.

<!-- @ -->

The smaller Cantor drawing, the three trees, the cloud and the dark sphere remain around the experiment. Their kinds of repetition do not have to resolve into one shape. Further on, Koch will put a detour into a line; Sierpinski will carry removal into a triangle. We have learned to lose length while multiplying pieces. What happens when the next rule makes the boundary grow instead?



## Fractal_KochSierpinski

Source: commons/maps/Fractal_KochSierpinski/final.md

SHA256: 1bbf37e572fd7a2677a1856231ad6488f7d46603f51e4cb588923c4db9e48342

# The boundary takes a detour

<!-- @fractal_koch_curve -->

Four metres of line wait behind the desk. Keep its ends in view. Where could more line go?

Press NEXT. The middle lifts into a peak. Follow it up and down before reading the counter. The ends have not moved apart, but travelling between them along the line now takes longer. Press again. Each of the four new segments takes its own detour, including the ones already climbing.

At the fourth step, 256 segments share a path a little over twelve and a half metres long. The endpoints still stand four metres apart. Distance between them and distance along the boundary have begun telling different stories.

This is the small decision inside each replacement:

```gdscript
var b := start + dir * (len / 3.0)
var d := start + dir * (2.0 * len / 3.0)
var c := mid_point + perpendicular * height
```

The next list joins `start → b → c → d → end`. Four segments, each a third of the old length. The next call receives these segments as its beginning. A multiplication of four thirds can be followed with the eye.

Try TURN. The detours go to the other side. The count and path length survive the reversal. They have not told us everything about the shape.

RESET, then FORM. A triangle closes the starting line into a boundary. NEXT sends its peaks outward; TURN folds them inward. There is an inside to negotiate now. An instruction about direction has become a decision about where an enclosure extends.

Our machine stops at four replacements. The familiar Koch limit follows the standard construction indefinitely; its boundary has unbounded length while enclosing a bounded area. This desk has finite segments drawn with thickness. We can learn the rule that approaches the limit without pretending the headset contains it. From Trace we still carry a question: how much of the next detail could this encounter distinguish?

<!-- @sierpinski_triangle -->

A filled triangle waits across the aisle. We have spent several rooms making descendants. What if the next generation occupied less of its parent?

Press NEXT. Find the middle before looking at the three corners. The middle is now an opening in the drawing. Another press makes a new opening inside each retained corner. The large absence remains; the small ones accumulate around it.

The code locates three midpoints:

```gdscript
var m1 = (v1 + v2) / 2.0
var m2 = (v2 + v3) / 2.0
var m3 = (v3 + v1) / 2.0
```

The next calls receive the three corner triangles. Their sides are half as long, so each has a quarter of its parent's area. Three quarters remain. At four cuts, eighty-one kept triangles occupy about 4.93 square metres of the original 15.59. There are more pieces to address and less surface to colour.

Now press VIEW. Pale middles appear where the rule made its removals. Press again. The kept corners disappear from the drawing, and the middles stand in their colours. What we had called the waste now holds the room's attention.

The program still computes the same corner triangles. It has changed which results receive meshes. The negative view draws forty removed middles from the four cuts. These are parts the operation already located; we did not need a new fractal to find another subject inside it.

DEPTH gives the drawn pieces more thickness. Their planar area does not change. Neither view makes these pieces load-bearing: the sculpture has no collision, although its control desk does. An opening in an image, a hole in a solid and a passage for our body ask different things of the implementation.

We can change the view back. That matters here. The ease with which this display restores a discarded part belongs to this stored construction. It does not make every act of removal reversible.

<!-- @box_counting_dimension -->

The next triangle arrives as points. This bench has its own generator: eight thousand repeated moves halfway towards a chosen corner. It is related to the triangle we just cut, but it is not reading that sculpture's mesh.

Press FINER. The grid tightens over the same points. Try COVER. Coloured cells mark where at least one sample was found. A crowded cell and a cell holding one point each count once. An empty cell contributes nothing, even when the ideal construction might place detail there.

Here is the counting decision:

```gdscript
var ix := int(shifted.x / box_size)
var iz := int(shifted.z / box_size)
occupied[ix * 10000 + iz] = true
```

The key gives this cell an address. Writing it again does not create another occupied cell. Arrays and grids have returned as a measuring instrument.

RANGE reveals a plot and fits the three coarsest measurements. Press it again for the three finest, then for all six. The reported slope moves while the point cloud stays put. Which value would you have called the triangle's dimension if only one had been shown?

The ideal Sierpinski triangle has dimension `log(3) / log(2)`, about 1.585. This instrument fits a finite sample at six box sizes. The number it returns depends on those choices; it is evidence from a procedure, with a range beyond which we have not tested it. RESET reproduces the same sample so the comparison can begin again.

The unoccupied cells tell us where this reading found no points. They have no authority over what may exist. The question becomes sharper when a model is used to decide what the world should retain: what happens to what it did not count? Here we can start with the smaller act: change the grid, look again, and leave room for an answer the first reading could not hold.

Beyond the instruments, the earlier collection remains: assembled cubes, a bent Koch arch, recursive specimens and the dark sphere on the old raised cell. A name or a beautiful outline invites comparison; neither settles which rule is running. The pyramid's implementation even makes six recursive calls where its comments say five. There is more to inspect than the route can finish.

In the next hall, removal enters a volume. We will approach the Menger sponge with a body that can fly. Which of its openings will become somewhere we can go?



## Fractal_MengerSponge

Source: commons/maps/Fractal_MengerSponge/final.md

SHA256: dd536779ded483cc5dd5bc08bd28addb5e9442aaf699f39e95d74d234b801c7b

# A hole becomes a place

<!-- @menger_sponge -->

The cube has no entrance. Nine metres high, nine across, nine deep. Its surface faces us without offering a way in.

At the desk to the right, press NEXT. Find the opening before counting the blocks. A square of the far side has become visible. Move a little: something opens across it, sideways. The removal did more than shorten the route between two faces. It made a crossing inside the cube.

Press NEXT again. Keep the large opening as a reference and look at the blocks around it. Each now carries smaller openings in the same relation. FRAME marks the outside of the original cube. The construction still reaches those edges, although more of its interior has become air.

The display counts the solids: one, twenty, four hundred. Beside the count, retained volume falls from 729 to 540 to 400 cubic metres. More objects have been made to represent less material. We met that difference in Cantor's rows. Now its gaps have acquired depth.

The source addresses twenty-seven positions, three along each axis:

```gdscript
var x: int = i % 3
var y: int = (i / 3) % 3
var z: int = i / 9
```

Each coordinate runs from zero to two. The retained-position table skips the centre and the six face centres: seven cells making a cross through the parent. Twenty remain. The next call receives each of those twenty cubes, with its scale divided by three. The same selection can now make an opening inside something that was previously kept.

Try GHOST. Pale volumes occupy the removals. After two cuts, seven large ghosts mark the first cross and 140 smaller ones mark the next. These marks have no collision. They are a record of what the construction discarded, drawn in the places our bodies might use.

In the previous hall, the removed middles could become the work. Here the removed volumes may become somewhere to be. Turn GHOST off again and approach the frame at floor level.

The glass cube offers another way of moving. On desktop, Space lifts you and Ctrl lowers you; WASD follows the direction you look. In VR, tilt the left controller and use its stick. Release the movement controls and remain where you are. Flight belongs to this enclosure. Descend to either ground doorway when you want to return to walking.

Rise towards the large opening. What looked like a dark square becomes a passage, with smaller openings in its sides. Try going through, then circle above the sponge and approach from another face. Choose one small retained cube and try identifying it in both views. The openings rearrange in projection even though their positions in the object remain fixed.

Look into a smaller copy of the passage. Its axial opening is a metre across and a metre high. Light can travel through where this standing body cannot. The museum's desktop capsule is 1.5 metres tall; even in flight it keeps that height. Flying does not make it small, and it does not make a retained cube permeable.

There was a connection in the geometry. There was not yet a route for every body.

We changed locomotion without changing the sponge's selection rule. We could also ask what a smaller body would encounter, or what would happen if the opening were enlarged. These would be further experiments. The present room gives us one specific comparison: a large passage we can fly through and a smaller, visibly connected opening that refuses this capsule.

The glass, the support below us and the borrowed flight belong to the installation. The glass confines that movement to a place where its beginning and ending can be found. At the desk, NEXT, BACK and RESET wait while a visitor remains inside; another press is needed after everyone leaves. GHOST and FRAME can still change the reading. We can discuss a different solid shape without rebuilding it around someone already inhabiting the last one.

Two cuts are enough for this encounter. A third would ask for eight thousand retained cubes with edges a third of a metre long. It would bring further openings, each smaller again. That is a cost and a possibility to investigate, not evidence that the next generation would be a better room. The infinite Menger construction has a zero-volume limit; these four hundred one-metre cubes retain positive volume and real collision. The limit is not what our body is touching.

The neighbouring aggregation study remains another way for form to begin: wandering particles can attach to an existing cluster. It has its own clock and rules. The catalyst installations and the dark sphere remain too. They offer detours from the cut-and-repeat procedure; this desk does not control them.

Next, repetition takes a numerical form. Instead of retaining twenty descendants, we will generate each new quantity from the preceding two and inspect how its representation changes what we can compare.



## Fractal_GoldenSpiral

Source: commons/maps/Fractal_GoldenSpiral/final.md

SHA256: 215e1e408713dd455f701897f7eb21cb8d2e7914eb122087127f5be771357284

# A number needs a mapping

<!-- @fibonacci_sequences -->

Two towers wait at the beginning of the row. Each carries a one. Before asking the machine for another, give it a number yourself. What could follow two equal beginnings?

Press NEXT. Two appears. Another press brings three. Stay with the numbers for a few steps: one, one, two, three, five. The next tower is already implied by a relation you can test. Add the preceding pair, then ask the machine to make its next term.

The row grows, but its heights are suspicious. Eight has not become a tower eight times as high as one. Fifty-five, at the end of this ten-term display, still fits comfortably below the wall. Something has happened between the number and the body that stands for it.

Press HEIGHT. The small towers sink towards the floor. Later ones keep more of their height. Read the labels again: none of the numbers has changed.

With the linear mapping, each unit receives five centimetres. A one is now easy to overlook from a distance. The earlier logarithmic mapping gave it half a metre, then compressed the increasing values. One arrangement keeps the small beginnings present. The other lets height carry addition at a common scale. They offer different ways to read the same history.

Try SUM after revealing at least three terms. Beside the row, two colours share a stack. One colour supplies the earlier value, the other the later one. A separate stack carries their sum. At the last term, twenty-one units and thirty-four units reach the same height as fifty-five. Each unit is still five centimetres. The equality can be checked by looking across their tops.

Now return to logarithmic heights. The unit stacks remain equal, but adding the corresponding tower heights would not reconstruct the next tower. The display has not broken the recurrence. It has changed what height means.

Ask for RULE. The source receives two quantities:

```gdscript
var next_fib = fibonacci_numbers[i-1] + fibonacci_numbers[i-2]
fibonacci_numbers.append(next_fib)
```

The display receives a value and gives it a height:

```gdscript
var h = 0.05 * value
# or
var h = 0.5 * log(float(value)) + 0.5
```

There are two decisions here. We can change the representation without changing the relation it represents. We can also lose sight of a small value without removing it from the sequence. The label and the alternative view let us find that difference again.

Walk around the desk and continue beside the supported displays. The earlier examples remain: seed points, stacked scales, shell-like chambers, a helix and a branching diagram. They are held still here so their arrangements can be inspected. Read one of their small plates. The seed pattern uses an index to choose a radius and an angle. The branching diagram uses a remainder after division to choose how many children to make. These are further rules.

The helix is especially useful to look at twice. Its radius grows by phi over a full turn. A curve usually called a golden spiral grows by phi over a quarter turn. A familiar colour and a persuasive title would not make those constructions identical. The plate names what this source actually draws.

The pleasure of recognition can come before the inspection. A shell! A seed head! We can enjoy that resemblance and still ask which operations supplied it. The two ones did not contain instructions to make a flower. We added a way for numbers to take positions, turns and sizes.

<!-- @golden_rectangle -->

A rectangle stands upright farther into the hall. This time there are no towers and no curve. Imagine removing a square whose side is the shorter edge. What shape would be left?

Press NEXT. The square remains visible in one colour; the remainder occupies the other portion. Press again. The next square is smaller and turns the direction of the construction. Follow a few cuts before asking for their measurements.

MEASURE puts side lengths on the squares. They decrease as the cut numbers increase. The first is about 3.090 metres across, the next 1.910, then 1.180. Those are lengths from this five-metre rectangle. They are not the increasing Fibonacci values painted onto another surface.

The readout follows the remainder. Its longer side divided by its shorter side stays close to 1.618034. We have changed the dimensions, yet retained a relation between them. Rotate your attention with each cut: the longer edge becomes the shorter one of the next stage.

For a rectangle of width phi and height one, removing a unit square leaves sides one and phi minus one. To keep the original proportion after turning the remainder, we require:

```text
phi = 1 / (phi - 1)
phi² = phi + 1
```

The positive solution supplies the ratio used here. The code still needs to decide which side loses its square, how many cuts to make, how to colour them and how to bring the result into this upright display. The proportion leaves those choices open.

Try ARC. A line joins circular segments laid through the squares. Turn it off again. The partition remains. Making the curve visible did not cause the subdivisions.

Each segment is a quarter-circle. The resulting joined curve resembles a logarithmic spiral, but its curvature changes from one circular piece to the next. We can follow it and feel its invitation inward without making it evidence of a universal rule of beauty. Another cut makes a smaller square, another length, another demand on the eye. Eventually the record can name a difference the view barely resolves.

The sponge made room by discarding material. This rectangle keeps the pieces together and gives the remainder another turn. The towers changed what a quantity looked like. Each procedure carries something forward and makes other differences harder to encounter. Asking what bodies are possible now includes asking what kind of reading our chosen representation permits.

In the retained room beyond, the recursive cabinet, growing terrain, Romanesco, aggregation study and sphere remain. The Romanesco's cones inherit positions and turns from their parent cones. Its botanical appearance is a construction to inspect, not proof that a plant follows this code. The terrain and aggregation have their own updates. Let their differences interrupt the temptation to call everything here the same pattern.

Next we gather the procedures. Before naming a desired shape, try saying what one step would receive, retain, change and pass on. The next capability will give those instructions a grammar.



## Fractal_Synthesis

Source: commons/maps/Fractal_Synthesis/final.md

SHA256: c4fbd115d47f1fea9b5dff76dc6d0db298da8660cda835f9b42c787029ab3268

# What, exactly, is repeated?

<!-- @cantor_set -->

Can you explain two recursive constructions without using their names?

Start at the interval. Before NEXT, describe one step to another person, or say it quietly to yourself: take an interval, keep two shorter intervals at its ends, and repeat on each survivor. Point to an example of the input, the descendants and the gap. Then identify where the displayed construction stops.

Try the description without pointing. “Shorter” leaves something undecided. How short? At which ends? This desk begins with six metres and keeps thirds. After one cut there are two pieces, each two metres long. Before the second cut, predict both the number of pieces and their combined length. They will not change in the same direction.

Here is the step that actually creates a descendant's size:

```gdscript
var new_length = bar_length / 3.0
```

In `cantor_set.gd`, `perform_iteration()` creates a left bar and a right bar of that length, each centred a third of the parent's length away from its centre. The middle receives no surviving bar. The call preserves the position needed to place its descendants; “repeat” alone would not tell us where they belong.

After three cuts, press HISTORY. The upper rows disappear. Has another third been removed?

The lowest eight pieces stay where they were. Together they retain about 1.778 metres. What disappeared was the visible record of earlier stages. Bring it back, then try GHOST. Pale middles mark the new removals at each row. These markers have no collision bodies and do not re-enter the surviving population. We can change what the drawing lets us examine without undoing the selection rule.

This difference matters to our question about possible bodies. A drawing can omit a history while retaining the state that history produced. It can also make an absence visible without making that place available to stand on. Neither visibility nor omission tells us everything about what the program permits.

The fifth cut is the desk's last. It leaves thirty-two finite pieces. The stopping point gives our attention and this instrument somewhere to stand. It does not establish that further difference is impossible. RESET returns to the uncut beginning; it does not rewind the museum.

<!-- @recursive_tree -->

The red block tree has already branched. Find a fork that seems to end, and follow it backward. What would a call have to remember to place a smaller branch there?

Press STRATA. The blocks change colour according to their recorded branch levels. Press REACH and volumes enclose the extents accumulated through those levels. ENDS adds marks at the deepest recorded blocks. FORM brings the solid reading back. Compare the same fork through these views: none of these buttons grows a new tree.

The source receives a parent, an origin, a number of branches and two depth values. Its stopping condition is small enough to read in one breath:

```gdscript
if current_depth >= max_depth:
    return
```

Later in `recursive_tree.gd`, `generate_branches()` passes the continuation on:

```gdscript
generate_branches(branch, end_point, num_sub, current_depth + 1, max_depth)
```

The surrounding code chooses dimensions, directions and descendant counts with a local random-number generator. This placement starts from seed 12345. The nested calls stop after three branching levels. A seed is one part of that recipe; the generator, draw order and ranges also matter. The desk's changing colours and cages read the resulting geometry without drawing those random choices again.

Try the incomplete description “make several smaller things.” It could describe both desks and reconstruct neither. The intervals need a retained fraction and placement rule. The tree needs inherited origins, directions, dimensions and descendants. A cage around its reach adds another representation: it encloses empty space as well as blocks. It is not a new shelter with solid walls.

We have accumulated ways to make form, and ways to mistake a reading for the form. The queer possibility here is a question we can keep material: which instruction would have to change for another body to have room? Another colour might help us notice a branch. Another branching rule might alter where the branches can go. Those are different interventions, with different consequences.

<!-- @ -->

The collection beyond offers further procedures to compare. Its held examples leave time for looking; the moving works keep their own clocks. We do not need to turn every resemblance into the same law.

Carry one explicit rule into the grammar laboratory. There, a string can be rewritten before it is read as movement. Its preset called “Koch Curve” replaces `F` with `F+F-F-F+F` and turns ninety degrees. Our equilateral snowflake uses a different construction. Even a familiar name leaves work for us to do. What does an instruction become when another reader gives it a body?



# lsystems

Declared order: LSystems_Grammar_Lab → LSystems_Growth → LSystems_Grammars_And_Curves → LSystems_Architecture → LSystems_Competition → LSystems_Living → Assemblage_Same_Desire

Museum map-authored order differs: LSystems_Grammar_Lab → LSystems_Growth → LSystems_Grammars_And_Curves → LSystems_Architecture → LSystems_Living → Assemblage_Same_Desire. Treat this as route drift to inspect, not an editorial recommendation.


## LSystems_Grammar_Lab

Source: commons/maps/LSystems_Grammar_Lab/final.md

SHA256: 47dfbd8be11bd4803e0bc2abe51eb3399ff742565e8639a1f664487747b73a73

# The same sentence, another body

<!-- @lsystem_editor -->

Two upright lines meet us. Below each, the same letter: `F`. Can one sentence have two bodies?

Press NEXT once. The live line acquires turns; the held line stays where it was. Count the live segments before looking at the counter. Then press HOLD. Both drawings now share this sentence:

```text
F+F-F-F+F
```

Leave NEXT alone. Press TURN. Follow the first bend across the two drawings. The letters below them have not changed. One reading turns through ninety degrees; the other now turns through a hundred and twenty. Five drawn segments in each, yet the same route through the symbols takes another route through space. Some segments may overlap. Count the instructions as well as the lines you can distinguish.

We brought a construction out of the fractal halls. Here we can separate two moments within it: making a sentence, and reading that sentence as movement. HOLD gives us time beside a previous reading. TURN changes the live interpreter's angle. NEXT rewrites the sentence from which it draws.

Keep the new angle and press NEXT again. The held drawing remains. The live sentence has forty-nine symbols and twenty-five drawing instructions. The turning signs also take up space in the string; they do not each leave a segment. What has multiplied, and what has merely been carried forward?

RULE opens the replacement used by this preset: each `F` becomes `F+F-F-F+F`. In `lsystem_editor.gd`, the next sentence is assembled from the old one:

```gdscript
var new_string = ""
for c in _current_string:
    new_string += str(_rules.get(c, c))
_current_string = new_string
```

A symbol without a replacement passes through as itself. The newly written letters wait for the next generation; they are not rewritten again during this pass. First one `F`, then five, then twenty-five. The small loop has a rhythm, and a place where its repetition must wait.

Another pass through the resulting string gives it geometry. `F` and `G` advance the turtle and draw. `+` and `-` turn its heading. The turtle is a travelling state: position, direction and a sideways axis. A line does not tell us all of that state by looking like a line.

Try RESET, then PRESET three times to reach PLANT. There is an `X`, and no line above the live plinth. We have encountered an invisible point before. This absence has a different cause: `X` belongs to the rewriting rules, but this interpreter gives it no drawing action. Press NEXT. Drawing instructions appear around the `X` symbols. What was undrawn was still capable of contributing to the next sentence.

The brackets now matter. `[` saves the travelling state; `]` restores it. A branch can end without forcing every later segment to continue from its tip. The next hall will let length enter that inheritance too.

Look again at the two outlines. Each is fitted to its display. More instructions need not make a taller body here. That apparent continuity of size is another operation, performed after the turtle has travelled. Our eyes receive a composed result: rewriting, interpretation, fitting, thickness, light. None is the untouched original behind the others.

This desk stops at four requested generations, with a budget of 4,096 symbols. If a replacement would exceed that budget, the last complete generation remains. Its readout distinguishes the generation shown from the one requested. A long printed sentence also declares that only its first 120 symbols are visible. Two different limits, two different kinds of remainder.

Seven presets give us places to begin. They do not exhaust the bodies that a grammar could permit; the physical desk does not yet let us type a new rule. Nor does a changed outline automatically make another space habitable: these thin drawings have no collision surfaces. The desire to inhabit them brings another body, another requirement, into the question. Which operation would we have to open next?

<!-- @ -->

The earlier trees, string study and city grammar remain beyond the desk. Their resemblance can invite a comparison without proving that they share its live sentence. Carry the bracket into the next room: what must a branch remember so that another branch can begin?



## LSystems_Growth

Source: commons/maps/LSystems_Growth/final.md

SHA256: f01c074ead526b64152eb0b72167e24bee9a575e40856600687e2a88f0f09ef9

# What a branch remembers

<!-- @parametric_lsystem -->

A short upright line, a pale point at its tip. Beside it, a second reading waits. We have brought the turtle out of Grammar Lab. There, we changed the angle of a sentence. Here we can follow what the turtle carries from one instruction to the next.

The sentence is already written:

```text
F[+F]F[-F]F
```

This tree's rule replaced one F with those eleven symbols. Its first F has drawn a line 0.8 metres long. The pale point marks the turtle's current position. What must it keep if it is to leave the trunk, make a branch, and find its way back?

Press STEP once. Nothing extends. The next symbol is `[`. The readout says SAVE; the stack count becomes one. The next length has changed from 0.800 to 0.576 metres, although the point has not moved. An operation has taken place without adding anything to the outline.

STEP again: `+` changes the direction. Another STEP reaches F, and the shorter branch appears. HOLD this reading. The pink point stays at the new tip.

Now comes `]`. Where will the live point go?

It returns to the fork. The branch remains drawn, with no return line joining its tip to the fork. Next length is 0.800 again. Press STEP: the trunk continues upward from the saved position. The branch's turn and shorter stride have not become the trunk's next instructions.

The turtle carries a state: position, orientation, length, angle and branching depth. At `[`, the interpreter puts a copy on a stack. A stack returns the most recently saved record first. One branch may contain another; the inner branch must finish before we return from the outer one. This nesting gives a small program a way to remember several departures without confusing their returns.

After saving, the source changes two values for the branch:

```gdscript
current_length *= length_decay
current_angle *= 0.95
```

The first line means: take the length we have and multiply it by the ratio. Here, 0.8 × 0.72 gives 0.576 metres. The second changes forty degrees to thirty-eight. F still means draw forward, but how far forward now depends on the state in which the turtle reads it.

At `]`, this excerpt from `parametric_lsystem.gd` retrieves the saved record:

```gdscript
var state: Dictionary = stack.pop_back()
pos = state["pos"]
dir = state["dir"]
right = state["right"]
up = state["up"]
depth = state["depth"]
current_length = state["length"]
current_angle = state["angle"]
```

Position returns, the orientation axes return, and the previous length becomes available again. None of these assignments removes a segment already drawn. A return can preserve what happened during a departure while allowing something else to continue.

Keep stepping until all eleven symbols have been read. Five segments, two side branches, a stack empty again. HOLD the complete reading. Then press RATIO once: 0.72 becomes 1.00. Follow a side branch against its held counterpart. It now takes the same 0.8-metre stride as the trunk. The sentence and turning directions have stayed the same. Both drawings use metres; neither is squeezed to fit its plinth.

Press RATIO again. At 1.15, the branch is longer than the segment from which it departs: 0.92 metres. The code calls this value `length_decay`. Its name suggested shortening. The multiplication also permits something else. Which proportion made this drawing look like a proper tree to us?

TREE shows two complete rewriting generations. There are now sixty-one symbols and twenty-five drawn segments. The unshortened trunk reaches 7.2 metres above its starting point. Within a branch inside another branch, the length factor is applied twice: 0.8 × 1.15 × 1.15 = 1.058 metres. The pink first generation remains beside it until we choose to hold another reading. We can follow a local rule and still be surprised by the room it begins to occupy.

STEP reveals a recorded trace of the interpreter; it does not make the computer wait between its calculations. TREE requests another sentence. These are two different ways of looking into a process that would otherwise arrive as a finished drawing. RESET brings back the first line when we want to follow it again.

The stack offers a dependable return, but only for the state its programmer chose to save. It contains no sunlight, weight or account of a neighbouring body. The thin branches have no collision surfaces. Their resemblance to a tree leaves those further requirements open. What would we have to add before this branching could support, shelter or obstruct us?

<!-- @ -->

The animated tree, the obstacle-querying tree, the earlier L-system tree and the cypress remain beyond the desk. They approach growth through other operations. Carry this distinction forward: a sentence supplies instructions; an interpreter decides what they do. In the next hall, even forward may be read sideways.



## LSystems_Grammars_And_Curves

Source: commons/maps/LSystems_Grammars_And_Curves/final.md

SHA256: ede12e1740fc6a9a42d89afcaf39aef661bf98f765c6829b5d6c71cd5a9b31a1

# When forward goes sideways

<!-- @the_believing_turtle -->

Does an instruction say how it must be obeyed?

Three short lines rise from three origins. Each has read the first F of the same sentence, taking a stride of 0.32 metres. We have kept the travelling state from Growth, but the question has moved: what agreement connects an instruction to a movement?

Press READ F. The blue line goes sideways. Its gold arrow still points up; its white arrow points across. The gold arrow shows the stored heading, the white one the direction the reader will draw. Those two directions no longer agree.

The sentence has not changed. Neither has the stride. This reader takes the direction it was given and exchanges its x and y components. What used to contribute to height now contributes to horizontal distance. Before seeing a whole tree, we can catch the disagreement in a single step.

Now press ANGLE. The middle reader changes from twenty-five to forty-five degrees. Its first line stays upright. Why did this change produce no visible turn? Keep pressing STEP until the sixth symbol. The first two Fs extend the stem; a plus turns the heading; a bracket saves it; another plus turns again; the next F draws. The middle reading has departed from the green reference. An angle matters when an instruction uses it.

All three readers follow:

```text
FF+[+F-F-F]-[-F+F+F]
```

There are twenty symbols and eight drawing instructions. Finish the sentence, finding corresponding forks as you go. When the brackets close, the saved positions and headings return, as they did in Growth. Each drawing has read the same bracket at the same moment. Yet one spreads differently, and another seems to have forgotten which way a tree should stand.

Here is the direction calculation in the believing turtle:

```gdscript
var dir := Vector2(cos(heading), sin(heading))
if sideways:
    dir = Vector2(dir.y, dir.x)
```

The angle called heading supplies the two components of a unit direction. The conditional exchanges them. The next line uses that direction to take a step in the museum's drawing plane:

```gdscript
var nxt := pos + Vector3(dir.x, dir.y, 0.0) * step
```

The third component is zero: these drawings remain planar inside a three-dimensional room. The step multiplies the direction; adding it to the current position gives the next position. This is the vector operation we brought through the earlier halls, now given another reading.

Try to match every blue fork to a green one. The correspondence is unusually dependable. With the same angle, exchanging x and y at every step reflects the entire construction across the diagonal x = y, relative to its origin. It preserves lengths, angles between segments and which branches connect. A reflection can overturn our expectation of uprightness while retaining this much structure. It is not simply a ninety-degree rotation; follow an off-axis branch to see the difference.

Press READ F again. The blue reading returns to the green one's arrangement. The exchange is reversible. Its strangeness has a precise operation we can repeat, inspect and undo.

TREE gives all three readers two complete rewriting generations: 172 symbols, 64 drawn segments. The same local differences accumulate across a larger body. No drawing has been resized to fit its case. Find the first fork again before trying to recognise the whole outline. More detail can obscure a relation we understood one step earlier.

STEP reveals recorded interpreter states, not a calculation suspended between button presses. After the last symbol it returns to the beginning of the reading; RESET also restores the initial angles and forward convention. The original lectern and its smaller studies remain behind this desk, including their unequal step lengths and finite drawing prefixes. They offer another comparison, with different conditions.

Calling this reader a believing turtle gives us a way to attend to its commitments. It does not give the turtle an inner conviction. The commitment is executable: F is assigned a direction through this code. We can change that assignment. We can also ask what the change has left untouched. The branches still have no collision surfaces; a sideways drawing has not yet become somewhere we can stand. That further desire needs another operation.

<!-- @ -->

The floor curves and the volumetric path remain in the collection. Their finite constructions let a sentence visit many grid locations; they do not occupy every point of this room. Beyond them lies Architecture. A step will acquire width, a branch may become a corridor, and a return will have to be considered in relation to a body trying to find its way.



## LSystems_Architecture

Source: commons/maps/LSystems_Architecture/final.md

SHA256: a4ce4e370eea3ce4e409ee6fa33f399bab2c29a703cd8095b3e7081e4817d68c

# When a line acquires walls

<!-- @lsystem_dungeon -->

Can a line admit you?

Four pale segments lie on the floor. One leads from the entrance to a junction; two turn away from it; the fourth continues ahead. You can already follow them with your eyes. On the flat plan, your feet can also ignore them. There is no wall asking you to choose.

Press BUILD. A low solid base and glass rise along the boundary. Enter beside the control desk, take a side branch and come back. The junction is open; the side branch ends against a wall. The straight continuation has another opening. Those different endings were decisions someone had to supply.

We have brought the turtle's saved position and direction from Growth. The previous hall changed how it read forward. Here we keep one reading and ask what must be added around it. The dungeon's branch rule rewrites F once into this short program:

```text
F[+RF][-RF]F
```

The first F reaches the junction. The bracket saves that position and direction. A turn, a room marker and another F make the first side branch; closing the bracket returns the turtle to the junction. The second bracketed group does the same on the other side. The last F continues the stem. Each movement becomes four metres in this study.

Two Rs appear in the sentence. Find the two places they mark. Follow the brackets carefully before deciding that there must be two rooms.

In the dungeon's actual interpreter, R does this:

```gdscript
rooms.append(pos)
```

It records the current position without moving. Both branches begin at the same saved junction, so both room records have the same address. A list can count two instructions while the floor contains one shared place.

Leave the brass frame and press ROOMS. The junction spreads into a square, 2.8 metres across. Enter again and step away from its centreline. There is now somewhere to pause while another route continues through. The program has acquired a spatial use through the footprint we assigned to a mark. The mark itself did not contain a gathering, a cupboard or a private retreat.

The construction collects the floor cells covered by all corridor and room footprints. Shared cells are kept once. At each cell edge it asks whether another occupied cell lies beyond it:

```gdscript
if occupied.has(cell + direction): continue
```

An internal edge receives no wall. That small refusal keeps the junction open. At exposed edges the builder places walls, except at the two deliberately chosen main entrances. The grammar supplies the records; the construction supplies a boundary policy. Calling the records architecture did not perform this work for us.

Return outside the frame and try WIDTH. The clear width cycles through 2.2 metres, 0.4 metres and back to 1.4. Watch the pale centrelines: they stay where they were. Try entering the narrow version. The desktop body's collision capsule is sixty centimetres across. A forty-centimetre passage cannot admit it even though the line continues without a break. Opening the junction into a room will not repair that narrow entrance.

This gives us two descriptions of connectivity. Every branch still meets the same junction in the plan. The space available to this body has changed. Its size participates in what counts as a passage. A different body would require another test. More branches would not answer the question that width has made concrete.

The controls refuse construction changes while a visitor remains within the study. Leave its frame, then press again. That rule belongs to this space too: the person at the desk cannot silently rebuild the walls around someone inside. We can examine the rule and imagine other arrangements for agreeing to a change.

PLAN removes the built walls and slabs; RESET returns to the opening comparison. The museum floor remains beneath every state. Behind the study, the original miniature dungeon rests on its plinth. Its more elaborate grammar fits into a small display. Look down at it with the narrow entrance still in mind. A plan can be legible to an eye long before it is usable by a body.

<!-- @ -->

The retained orthogonal structure, folded dragon path, seed and mesh studies offer further readings. We will return to them. Next, in Competition, we ask what happens when a rule's next move must meet a world that other growth already occupies.



## LSystems_Competition

Source: commons/maps/LSystems_Competition/final.md

SHA256: e0af1e67aeb737f9e13f579129d09ffb6bc85b8ef338cfbbf8be033080e303b8

# Who gets the first turn?

<!-- @ForestCompetition -->

Two stems wait above a tiled field. One is amber, one blue. Both begin with F, the same diameter and the same rule. Their colours let us follow them; colour gives neither a different appetite.

Let A take a turn. A small branch appears, and a square patch of soil drops. Now let B take its turn. Both have reached generation one. Look at what they took: A received 2.250, B 1.980. These are the model's resource values. We have not measured grams of food.

Is something wrong with B's instructions?

Press ORDER to begin the comparison again with B first. The same soil returns; the same two starting stems return. Take two turns. B now receives the larger amount. Nothing in the branching sentence had to change.

Architecture separated the line from the boundary that lets a body pass. Here we separate a rewriting rule from the conditions that let it run. The familiar brackets still save and restore a turtle's state. Both specimens use this replacement:

```text
F → F[+F]F[-F][F]
```

The forest does something before applying it. It reads the soil around the selected root, subtracts a portion from each cell, and adds those portions to the tree's uptake. The comparison gives both trees a growth multiplier of one. This excerpt is the subtraction inside that cell loop:

```gdscript
var take := minf(_nutrient_grid[cy][cx] * 0.15 * tree.growth_rate_mult, _nutrient_grid[cy][cx])
_nutrient_grid[cy][cx] -= take
uptake += take
```

Each initial sampling square contains twenty-five cells. The squares overlap in twenty cells. The first tree takes fifteen percent of each cell's current value. The second arrives at a patch partly used by the first. Its rule is intact; its starting world is already different.

The two root markers are close together on the field. The branching displays stand apart, enlarged four times so that we can inspect them. Their display positions do not move the roots. Follow the coloured squares back to the soil before mistaking the distance between the exhibits for the distance in the calculation.

Try SEASON. This also begins a fresh comparison, now holding winter steady. Take two turns. The patch sinks, and the uptake readings change. The stems do not branch.

The consumption happened before this test:

```gdscript
if nutrients > 0.05 and _current_season != Season.WINTER:
    tree.lsystem.generate()
    tree.generation += 1
```

Winter refuses the rewrite. It also stops the separate diameter increment. It does not undo the earlier subtraction. A body can remain visibly still while changing the conditions around it. To discover that here, we needed the field as well as the tree. A picture of the crown alone would have concealed the operation.

Press SOIL. For one simulated second, nearby cell values diffuse and replenishment draws them towards the supplied level. No tree takes a turn; the chosen season stays fixed. In winter replenishment is slower. The desk separates these operations so we can follow them. Behind it, the original forest runs them together over time, with five different grammar strategies and the earlier controls.

Return to spring and let the pair reach three generations. Further turns report a generation limit. The limit belongs to this study. It does not tell us that the trees have matured, exhausted their world or found an ideal form. Soil can still change. Even an ending needs its condition read.

We can now ask something more specific of the forest. Which differences came from instructions, which from resources, and which from whose turn came first? The order is a small piece of code, easy to overlook among the branches. It helps distribute a possibility of growth.

There are other schedules we could write: rotate the first turn after each round, or calculate everyone's request before changing the shared field. Neither is supplied by these buttons yet. Each would give us a different experiment. Calling the first arrangement natural would close that opening too soon.

<!-- @ -->

Stay with the retained coral for a moment. Its branching form has another recipe; it is not drawing food from this soil. Similar-looking bodies need not inhabit the same relations. In Living, we turn towards the controls that let us author a body, and ask which possible changes those controls have made available.



## LSystems_Living

Source: commons/maps/LSystems_Living/final.md

SHA256: c08af7ca6dab5d7b3803743ec05cc5fea1ff812de3545b2887102020ef1d5f8c

# What counts as a change?

<!-- @genetic_tree_sculptor -->

The tree waits above a low plinth. Beside it is a place for another tree. Press HOLD. Now there are two: the design we can change and a witness that will stay where we left it.

In Competition, the same grammar met different conditions. Here we reach further back, towards the numbers from which a grammar is made. The desk begins with Depth selected. Its value is 4.000. Press MORE once. The number changes. Look at the branches.

Try again. And again. By 4.800, the number has moved four times, but the tree still agrees with its witness. Is the control doing anything?

One more press reaches 5.000. Another generation of branching appears.

The control has been changing a value called segments in the DNA resource. DNA here means a collection of parameters used to construct a body. It is a name for this data structure; the name does not establish that the specimen is alive. The tree generator reads that value through this line:

```gdscript
var generations: int = clampi(roundi(dna.segments * 0.5), 2, 5)
```

First halve the raw number. Then round it to a whole number. Finally keep the result between two and five. At 4.800, the intermediate value is 2.400; it rounds to two. At 5.000, it is 2.500; it rounds to three. The number we moved and the instruction the generator received are different records.

We have encountered this gap before. A trace records a hand at particular moments; the record cannot contain every position between them. Here a continuous control is translated into whole rewriting generations. Several distinct settings produce the same instruction. That is useful: a generation must be a count. It is also a place to look when a desired difference disappears.

The tree still starts with F. At each rewrite, F becomes a short stem S followed by bracketed branches. The Forks gene supplies their count and Arrange supplies their turns. S, in turn, becomes FF. The turtle then reads the completed sentence, advancing, turning, saving a state at an opening bracket and returning at its closing partner. The earlier grammar lessons are inside this instrument.

Use GENE to pass through Forks and reach Angle. A small increase now changes the directions of the branches without adding a rewriting generation. Two controls move smoothly under the hand, yet one crosses a counting threshold while the other changes geometry. A control's appearance cannot tell us what kind of change it offers.

Press PLANT. A copy appears on the floor pad beyond the two plinths. Change the editing tree again. The placed one keeps its form. HOLD keeps its own witness too. RESET restores the opening design and leaves these copies for comparison.

This steadiness had to be written. The export used to point at the same editable DNA resource. Moving a slider could therefore change the data that a later consumer would receive. Now the export begins by making a copy:

```gdscript
var snapshot := _dna.duplicate(true) as CritterDNA
Engine.set_meta("sculptor_tree_dna", snapshot)
```

The hall also copies the displayed geometry onto its planting pad. A later PLANT replaces that local specimen. The older branching catalyst has a different use for the exported DNA: it may mutate and rescale a copy when producing a temporary tree. Placing a specimen here does not recruit it into Competition's soil or teach the floor to grow.

The original eight sliders remain on the side rack, including RANDOM. They offer more ways into the same resource. Eight controls are still only a selection from the parameters and rules that make the body. They cannot ask for a new alphabet, a branch joined back to an earlier branch, or a different relation to the ground. Those changes require another part of the program.

Push Depth and Forks towards their upper limits and read the command count. The sentence can request more branches than this preview will draw. At its current detail level, the interpreter stops after two hundred F or S drawing commands; very short segments may produce no mesh at all. The display names that budget. What looks like a finished crown may be the point where drawing was stopped.

There is pleasure in finding a body among these variations. There is another kind of curiosity when the variation we want has no control. Stay with that desire long enough to name what is missing: another connection, another rule, another way of occupying the room. Then we have somewhere specific to continue writing.

<!-- @ -->

The older tree, coral and paper studies remain beyond the workbench, among the authored platforms. Each makes form through its own procedure. Next, two diagonal marks will invite us to see paths in a textile. We carry the distinction between the instructions that made a surface and the possibilities we read in it.



## Assemblage_Same_Desire

Source: commons/maps/Assemblage_Same_Desire/final.md

SHA256: 62afcd353272507d64cbbb3357fdb75d1653b6a3aa4494a8670a4d08f84858ef

# Two marks, many paths

<!-- @ten_print_textile -->

When you see a path in this textile, who connected its pieces?

Choose several neighbouring diagonals and follow the line your eye makes through them. At a fork, notice which continuation you choose. Read the same area from the other end. The marks have stayed still; your route through them may change.

Living gave us a witness that could stay while a design changed. Press HOLD here. A second sheet keeps the current marks beside the one we can edit. Now press ALPHABET.

The diagonals become horizontal and vertical bars. Keep looking at the same small group of cells. Has its path survived? Press ALPHABET again. One outcome becomes a large block, the other a small block. What looked like a route may now look like a density, an enclosure or a scattered set of objects.

The choices have not been made again. Each of the sheet's 144 cells still holds the same random sample. The same threshold still selects its outcome. We changed what that outcome draws.

The original diagonal alphabet gives its bar one of two rotations:

```gdscript
bar.rotation.z = (PI * 0.25) if slash else (-PI * 0.25)
```

PI radians is half a turn; a quarter of PI is forty-five degrees. The sign chooses which way the bar leans. The other alphabet uses zero and half of PI, producing a horizontal or vertical bar. The stored choice can pass through either interpretation. Its address in the array does not move.

The grammar rooms taught us to distinguish a sentence from the turtle that reads it. Here we hold a record of choices and give it another set of marks. A picture can change substantially while the decisions remain intact. That does not make its appearance incidental: the marks give us different relations to follow.

Return to the diagonals. Try ODDS. The next setting is 0.75. Some blue marks become warm ones. This time the decisions changed, although the samples did not.

Each new cell originally receives a sample and compares it with the threshold:

```gdscript
var sample := _rng.randf()
var slash := sample < odds
```

ODDS reuses that recorded sample. A value between 0.5 and 0.75 changes sides when the threshold moves from one to the other. A value below 0.5 was already admitted. The screen counts how many cells choose A; a threshold of 0.5 does not require exactly half of a small sheet to choose it.

The difference is now precise. ALPHABET changes the marks while holding the decisions. ODDS changes the decisions while holding the samples. SEED supplies another reproducible set of samples. HOLD lets one resulting sheet remain beside these experiments. RESET returns the editable sheet to its opening state.

Press STEP. The oldest row leaves the bottom; a new row enters at the top. The other eleven rows keep their samples and shift down. The small automatic textile behind the study runs this operation over time. A finite window lets us watch an ongoing process without keeping every mark it has produced. The discarded row may matter to a route we were following. It is no longer in this window.

Walk onto the pattern beyond the desk. The same choices have been drawn across the floor. Follow a diagonal, then cross it. The floor supports both movements. Changing the marks changes what the surface invites you to follow; it does not cut a passage or raise a wall. No collision boundary follows these lines.

That distinction gives us a next experiment we have not built: let a mark become a barrier, then test whether the same array remains traversable. We would need to decide what counts as a connection, construct its collision and check a route. A maze-like image has done none of those things for us.

The paths can be real features of the image without being planned routes. Your reading and the generator's operation are different contributions to the encounter. The pleasure of finding a way through need not disappear when we learn how little the generator knew about it. We gain a place to intervene: in the choices, the marks, their connections, or the body that will approach them.

<!-- @ -->

Stay with the rest of the room. The working loom computes which thread lies above another from a draft; its crossings depend on several related tables. The pattern galleries retain their maker names, including the gallery dedicated to Kristina Torsson. These are other procedures and histories beside the two-mark textile. Sharing a computational medium does not make them interchangeable.

The plaque and tilted scale invite a question about formal limits. Their presence does not turn this textile into a proof of incompleteness. The room can bring practices into conversation while leaving their differences available for study. The same desire is a question we carry between them: what can this way of making open, and where must we learn another way?

Next, generated forms will be compared using a numerical score. Until now a path could matter because we chose to follow it. What changes when a program is asked to decide which result should continue?



# proceduralgeneration

Declared order: PG_Genetic_Evolution → PG_Space_Colonization → PG_Branching_Growth → PG_Percolation_Network → PG_Caves_Mazes → PG_Sculpted_Forms → PG_Mirrored_Patterns


## PG_Genetic_Evolution

Source: commons/maps/PG_Genetic_Evolution/final.md

SHA256: 6b1ec488e300516648f1de19ae3ae479841e416d590d801debcf43b7a348c2df

# What does the score notice?

<!-- @GeneticProgramming -->

Six boxes wait beyond the desk. One is pink. Before asking why it has been picked, choose a body you would want to keep. Perhaps the small one leaves more room around it. Perhaps you want the largest, though you have no use for it yet. Remember your reason.

We arrived here knowing how to rewrite a description and build from it. Now the program adds a judgement. Each candidate has a genome: a list of primitive names and parameters. A builder reads that list to make the visible body. An evaluator reads it to produce a number. These readers can notice different things.

Press HOLD. The current leader appears on the side plinth, a copy that will stay while the population changes. HOLD keeps the numerical leader; it cannot yet keep whichever candidate you preferred. That is already one limit of this instrument. Your other choice must remain in memory.

Now press TARGET. The number changes from 8 to 16. The boxes move into a different order and another becomes pink. Their descriptions have not changed; the generation counter has not advanced. The held box waits where you left it. What has happened to its claim to be best?

The label below each candidate reports an estimate and a score. With target 8, the box at scale 1 had estimate 8 and score 100. At target 16, the box at scale 1.25 leads: its estimate is 15.625 and its score about 72.73. The larger score means closer to the current target. It does not mean larger, older, more complex or more desirable.

Here is the comparison in the running source:

```gdscript
var volume = estimate_volume(genome)
fitness = 100.0 / (1.0 + abs(volume - target_volume))
```

Subtract the target from the estimate. `abs` keeps the distance without its sign: being one unit above or below incurs the same difference. Adding one prevents division by zero. An exact match scores 100; a difference of one scores 50. This is what fitness means in this room. We can inspect it without agreeing that it measures what we value.

Press RING. A loop appears on the leader. Look through its opening, then back at the score. The body acquired a conspicuous part. The number did not move.

RULE exposes the seam. The builder knows how to draw a torus. The volume estimator has cases for spheres, boxes and cylinders, and no case for a torus. The ring reaches the image but contributes nothing to this score. Removing it with RING leaves the score unchanged too.

Even the counted box asks for another look:

```gdscript
total_volume += scale.x * scale.y * scale.z * 8.0
```

The renderer starts from a unit box, but this estimate multiplies its scale product by eight. It also adds contributions without subtracting overlaps. The label therefore reports the program's proxy, not a measured volume of the completed solid. The missing ring is a defect we can name and repair. For the moment, holding it visible lets us see exactly where the two descriptions part company.

Leave the ring in place and press STEP. The generation advances. Two leading descriptions are copied unchanged; four more places are filled through parent selection, possible crossover and mutation. Each parent is the best of three random draws from the population. A draw can encounter the same candidate again. Selection gives some descriptions more chances to continue; it does not inspect the reason you gave for your first choice.

Find the ring again. An elite copy can carry it into the next generation although it earned no points. Survival does not tell us that every surviving feature was rewarded. The held witness still records the earlier box. RESET restores the six opening boxes and target 8, leaving that witness on its plinth. The opening is repeatable; later offspring depend on random choices and need not repeat.

Walk beyond the study and take the side ramp onto the raised structure. These decks carry you because the museum supplies their collision shapes. The generated candidates have no such support. A form can score well without offering a place to stand. To select for inhabitation we would have to construct and test that relation: an opening, a surface, a particular body attempting passage.

What would your earlier choice ask us to add? A different measurement, another representation, or permission to keep something without justifying it to the score? The question remains useful after this particular omission is fixed. In Space Colonization, next, the target becomes a distribution of points. We will follow the directions they request before changing which growing sites can respond.

<!-- @ -->



## PG_Space_Colonization

Source: commons/maps/PG_Space_Colonization/final.md

SHA256: dea2441bfe7d513ad6c821c8f719df968206ab54648cedb860fa0f779c26674e

# Which points get a say?

<!-- @space_colonization_algorithm -->

Three pink points wait above a small root. Two sit apart at the same height; the third is higher, between them. Before pressing anything, follow a line from the root towards each point. Which way would you go if all three asked at once?

The gold lines show those requests. The short white segment proposes a step. Press STEP and watch a pale branch take its place. The root has moved nowhere. It has acquired a child, half a metre above it. Neither side point has been reached. Something useful happened between their demands.

In the last room, an evaluator compared whole bodies with a target number. Here the target has become a distribution of positions. We call them attraction points. They do not exert a simulated force, and they are not light sensors. They are coordinates that a rule consults while adding segments.

Start with one request. Subtract the site's position from the point's position. This gives a vector pointing from here to there. We have met that subtraction before. Now normalize it: keep its direction, give it length one. A distant point will not get a longer vote merely because it is farther away.

These are the lines in the running program:

```gdscript
var direction = (attr_point - closest_node.position).normalized()
closest_node.growth_direction += direction
```

The opening root receives three unit directions. The leftward and rightward components cancel; the upward components add. The program normalizes their sum and takes a fixed step:

```gdscript
var growth_dir = node.growth_direction.normalized()
var new_position = node.position + growth_dir * segment_length
```

Here `segment_length` is 0.5. The two side requests are at (-2, 3, 0) and (2, 3, 0); the upper request is at (0, 5, 0), measured from the model's root. The first new position is therefore (0, 0.5, 0). The geometry you predicted is the geometry the code builds. The gold construction now shows a decision for the next generation, not a replay of the previous one.

Press FIELD once. Eight known points replace the three, and growth starts again. Their arrangement is uneven. Press STEP several times and follow the strand. Some points pull it sideways; others remain behind. You can keep advancing, one generation at a time. A reached point becomes small and dark. It leaves the active calculation but stays visible, so the encounter does not erase every trace of what mattered.

There is a restriction easy to miss in the name of this artifact. Under TIPS, a growing end can produce one successor. That successor replaces it in the eligible set. From this single root, the rule makes a strand. A sufficiently crooked strand may suggest a tree in silhouette, but it has not made a fork.

Press HOLD when you have a specimen worth comparing. It appears on the side plinth at 0.45 times the display scale; its proportions and parent relations are kept. This is a small witness, not evidence that the algorithm shrank its body. Now press POLICY. The same eight points and the same root return at generation zero, with NETWORK on the readout. Press STEP again.

Watch for a site that has already produced a child and later produces another. The new policy lets earlier sites remain eligible to receive requests. Each active point chooses its nearest eligible site within eight metres. Requests assigned to one site are still summed; each site can add at most one child per generation. A fork becomes possible across generations because an earlier site can act again. Changing who may respond changes what this construction can become.

The held strand remains beside the growing tree. Compare a local fork before comparing their overall outlines. NETWORK is the control's name; this implementation still attaches each new node to one parent. It builds a rooted tree, without joining existing branches into loops. Another topology will require another operation.

FIELD once more opens a canopy of 96 fixed points. Its asymmetry is authored through sine offsets, using a tool we already know. It is not fresh randomness at each step. The field helps make the form; calling the result organic does not remove that authorship. A perfectly balanced field can cancel sideways directions and leave a stem. More points alone do not promise more branches.

Some requests may remain when growth stops. RULE names the operations and the budgets: this study permits at most 192 nodes and 60 generations. A limit reached by the computer is not a tree's natural maturity. RESET restores the three-point opening and TIPS, while keeping the held witness. You can return without pretending that nothing has happened.

Walk around the specimen and onto the rear deck by its side ramp. The museum supports your body. The drawn branches do not have collision surfaces. A connected parent record, a visible shape and a place you can inhabit are three relations we must learn to build together.

We have changed eligibility while keeping the points. In Branching Growth, next, we will change what a site listens to: one nearest invitation, rather than the sum of several. Before admiring another tree, find that smaller difference.

<!-- @ -->



## PG_Branching_Growth

Source: commons/maps/PG_Branching_Growth/final.md

SHA256: fdc634ab54f4d1efcb11c8eb3aecbbd344aabad8033a8443221a268d059d3548

# One nearest invitation

<!-- @branching_growth_algorithm -->

Eight points wait. You have met their arrangement in Space Colonization. There, several requests could contribute to a direction. Before pressing STEP here, find the nearest point to the root. Does the branch listen to the others?

The first segment leans left. In local coordinates the nearest target is (-2, 1.5, 0), two and a half metres away. Normalizing its direction and taking a half-metre step gives (-0.4, 0.3, 0). We can predict this small displacement before we have a tree to admire.

The running program searches unreached attractors inside `attraction_distance`. Each active branch site chooses the nearest one. Its construction begins with:

```gdscript
var direction = (attractor.position - branch.position).normalized()
```

That direction receives optional jitter. A pulsing multiplier can change the segment length. The opening suppresses both so that we can distinguish the choice of target from these additional variations. Press TEN STEPS. It performs ten calls to the same growth operation, without making you hold a button for every generation.

Now compare the readout's records with its distinct positions. They need not agree. Older active sites can produce another child; with no variation, an old site can choose the same target and put that child where it put the last one. Several records may occupy one place. A count of parents with multiple children therefore tells us about the stored tree, not necessarily about visibly separate branches.

This is a useful failure of our first description. We said a branch had appeared; the database agreed. The space may have acquired nothing new. The remainder is not always an extravagant shape. Sometimes it is redundant work concealed by a familiar outline.

Press HOLD to keep a separate mesh witness, displayed at 0.4 scale beside the desk. Then press VARIATION. The root and eight targets return, with jitter and pulsing enabled. Advance again. These settings can separate previously coincident paths, but their presence does not make a biological explanation. They are explicit additions to a directional rule. RESET removes those variations and starts the comparison again; the witness remains.

The museum study caps the record count at 192. The counter includes coincident children. That limit tells us something about what this program spends, not how mature its tree has become. RULE reveals the operation after you have had a chance to follow it.

Keep the nearby organic_space in view. It obtains an organic appearance through a different construction: geometric shells, tunnels and detail. A resemblance does not establish a common method. We are learning to ask what a form did to become available, rather than treating its appearance as its explanation.

Neither a parent record nor a drawn line has yet made a passage for us. In Percolation, next, we ask a narrower question first: under a stated rule of contact, what can reach what?

<!-- @ -->



## PG_Percolation_Network

Source: commons/maps/PG_Percolation_Network/final.md

SHA256: c5c8b14a31152eed0aca31603aac04f0d691cb9e2eed7f5eb3dc2eacd0343fc6

# Touching is not enough

<!-- @percolationnetwork_ca -->

Two cubes stand near the floor of a much larger possible lattice. One is pink, the source. The other is white. Look at their contact before pressing STEP. Where could something pass between them?

At a face contact the white site becomes flowing. Press CONTACT to start again with a different arrangement. The cubes now meet at a corner. STEP leaves the white one waiting. Their visual contact has not disappeared. The program simply does not consult that relation.

Its neighbourhood consists of six positions: one step in either direction along x, y and z. It does not include the diagonal positions. This is an explicit local definition, not a universal meaning of nearness.

```gdscript
Vector3i(x+1, y, z), Vector3i(x-1, y, z),
Vector3i(x, y+1, z), Vector3i(x, y-1, z),
Vector3i(x, y, z+1), Vector3i(x, y, z-1)
```

The update reads the old grid while writing another. An occupied site becomes flowing when a permitted neighbour carries flow. One press advances one generation; it does not instantly colour every reachable site. The source remains supplied. Flow values and state transitions have their own rules beyond the simpler question of whether a path exists.

Press LATTICE. The comparison expands into an 18 by 18 by 18 field, supplied from one z face. STEP lets you follow its spread. DENSITY restarts from the same seeded sequence of occupation draws at a different cutoff: 0.2, 0.4 or 0.6. A larger cutoff admits more sites. The readout counts sites reached and those reached on the opposite face. The desk permits 64 generations before another reset.

One such field cannot establish a universal critical threshold. Its seed, dimensions, boundary source and neighbourhood are part of the experiment. We can learn from a failed crossing without claiming that a whole kind of space has become impossible. Keep changing one condition at a time, and name the condition when you describe the result.

There is another distinction already under your hands. White occupied sites have collision. Pink source and flowing sites do not. The signal travels through the occupied network; as it arrives, that particular obstacle to your body is removed. The same event is connection for one system and a change of resistance for another.

The museum floor supplies an independent way around the field. That support is authored separately from the lattice. We should not call the pink route walkable just because a sequence of neighbour tests succeeded. A body needs dimensions, headroom and somewhere to stand.

The dark sphere and its stand remain in the room as supporting works. They are not hidden steps in this flow calculation. Our next comparison is Caves / Mazes: how can a rule construct the interior that our signal did not need?

<!-- @ -->



## PG_Caves_Mazes

Source: commons/maps/PG_Caves_Mazes/final.md

SHA256: 7fb954ffaf4e794a82e93af17b4787006ebeb55e25fbf505f60c5ddbdb2c56db

# A route needs room

<!-- @caverandomwalk -->

A connected line has no width. Your shoulders do. Stand at the cave opening and look for the space that would have to remain empty if you entered. Then turn on TRACE. Small gold dots mark positions where the carving operation was applied. Some positions were visited more than once.

The walker does not leave a solid trail. It removes cells around its position. The array begins filled; `_set_air` changes selected entries to zero. In this program, zero has a job: it records absence inside the generated volume. The museum's floor beneath the experiment is another object with another responsibility.

The cave is guided more deliberately than its name might suggest. Walkers begin at four sides and are biased towards the centre. They then wander at a prescribed low level and climb through further levels. Around each carving centre, the operation clears a small lateral footprint and two cells of headroom. This is not an unconstrained random walk discovering a cave without prior decisions.

```gdscript
_carve_ball(p)
p = _biased_step_towards(p, to_center, 0.7)
```

CAVE SEED makes another run while retaining that construction. Find an opening that moved and one restriction that did not. TRACE marks carving centres; it does not join separate walkers into a fictitious continuous trajectory. The dots help us read where the work occurred, including work that the final void no longer distinguishes.

At full display scale the cells are one metre wide. The stated two-cell headroom is a construction parameter, not a guarantee that every turn and climbing region admits the player. An interior can exist geometrically while refusing a particular body. That refusal becomes something we can locate and revise.

<!-- @ -->

<!-- @maze_generation -->

Across the court, another grid offers another way to make room. Press MAZE STEP. The program moves to an unvisited cell and removes the wall between it and the previous cell. It also keeps the previous position on a stack.

```gdscript
generation_stack.push_back(current_cell)
current_cell = next_cell
```

Continue until the current cell has no unvisited neighbour. Now the stored path matters: the program pops a position from the stack and tries again from there. Backtracking is not an error to disguise. It is how this construction keeps unfinished alternatives available.

FINISH completes the small nine-by-nine study. RESET restores its construction so that you can step through it again. Its cells are 1.5 metres across. Compare the deliberate openings at the boundary with the cave's carved mouths, then compare their internal turns. The maze stores walls and visitation; the cave stores solid and empty volume. Both have random choices and authored restrictions.

The nearby binary-space-partitioning work remains another comparison: divide a region before deciding how its parts communicate. We need not erase it because today's first argument concerns two generators.

The desktop check follows open maze cells from entrance to exit. That proves a route in its array. Human VR clearance through every generated interior remains a separate review. The independent museum aisle lets us continue while keeping that distinction honest.

In Sculpted Forms, we will reverse the direction of this encounter. Instead of asking a rule to carve space for a body, we will let bodies fall and ask another rule what surface it can record from them.

<!-- @ -->



## PG_Sculpted_Forms

Source: commons/maps/PG_Sculpted_Forms/final.md

SHA256: d1af4deef551f49f2dd38f0722289daa5f44206fb1b540158a7110e194094ba4

# What did the sample keep?

<!-- @cube_mound_scene -->

Press DROP and watch twelve cubes fall. They turn, strike the ground and meet one another. Do not press the next button immediately. Choose the moment you want the next construction to inherit.

SAMPLE freezes the cubes at that moment and builds a surface from their centres. It can record a settled pile or an unfinished fall. The word sample matters: the new mesh is not the physical event preserved in full.

The positions must first belong to the model's local frame:

```gdscript
positions.append(to_local(cube.global_position))
```

Without that conversion, a mesh attached beneath the translated artifact could receive its museum displacement twice. Coordinate systems are part of the construction, even when an object makes us forget that it has a parent.

Each centre is mapped to a voxel address. The implementation then marks an axis-aligned neighbourhood around that address and emits faces where occupied cells meet empty ones. The extent is deliberately described here as the program computes it: `ceil(cube_size / voxel_size)` cells in each direction. It is an enlarged centre-based approximation. The cubes' rotations and exact contact surfaces are not copied.

Press ORIGINAL to alternate the frozen bodies with the sampled surface. They share the recorded centres but need not share their silhouette, openings or contact shapes. The sampled collider stays active during this visual comparison. ORIGINAL does not secretly restore the earlier physics experiment.

VOXEL rebuilds from those same frozen positions at a different cell size. Look for an opening that becomes filled or a boundary that moves. A change of resolution can change the opportunities offered by a surface, not merely its smoothness. More detail has a cost, but less detail also makes decisions. Neither setting is innocent by virtue of being easy to compute.

DROP begins another physical run. The previous generated collider is removed when its mesh is replaced, so an invisible old sample does not remain as an extra law inside the new one.

<!-- @ -->

<!-- @dome -->

Turn to the dome. Here the empty region has not come from a wandering point or a fallen cube. A geometric operand has cut it from a stock volume.

CUT cycles through the cast, the uncut blank, the cutting cores and a section. The cores show the shapes that made the absence. A hole can carry as much authorship as the material around it.

```gdscript
cut.operation = CSGShape3D.OPERATION_SUBTRACTION
```

Return to the cast after seeing its operands. The result may now look less self-evident. It was one possible agreement between volumes and operations. Moving a cutter would make another agreement; it could admit a body, divide an interior or close an opening we had begun to rely upon.

The layered membrane remains nearby. Its repaired scene makes a further contrast available: nested displaced surfaces can suggest thickness without being one filled solid. Look between them. Do not assume that a convincing skin carries the collision or interior its appearance promises.

These works give us different ways to materialize a decision: sample an event, subtract a volume, arrange surfaces. Next we will compose operations we already know, while keeping two questions distinct: how is an image copied, and how are places connected?

<!-- @ -->



## PG_Mirrored_Patterns

Source: commons/maps/PG_Mirrored_Patterns/final.md

SHA256: ce6659a7d7185c18688370169ba7ee6ffdd4f3ecf318c321dbac2f00c6574287

# A repeated image, another way through

<!-- @mirror_cellular_texture_for_3d -->

An uneven cellular field lies before you. The opening is an authored arithmetic arrangement, held still so that we can inspect a comparison without chasing a changing picture. Press STENCIL. Much of what you see now comes from copying part of that same held field.

HOLD stores the current array. STENCIL always returns to that held array before applying the next arrangement: quadrant reflection, eight-way reflection, rotation, or no copying. It does not obtain a different random field and ask you to attribute all the differences to symmetry.

For the quadrant arrangement, the operation reads a cell from one quarter and writes its value to corresponding positions elsewhere:

```gdscript
new_grid[y][grid_size - 1 - x] = value
new_grid[grid_size - 1 - y][x] = value
```

There are consequences at the edges of this promise. This study uses an odd-sized grid; its centre row and column do not belong to every copying loop. The rotational operation also converts floating-point positions into integer addresses. A symmetrical intention still passes through a particular implementation.

STEP performs one cellular update and then its selected symmetry operation. In this desk study, eligible births and deaths have probability one, so the comparison isolates the update and copying rules. HOLD can keep that new result as the input for the next comparison. Cycling STENCIL to none restores the held field with copying disabled; it does not erase what you chose to hold.

We have returned to arrays, cellular neighbourhoods and transformation. Their combination makes a surface whose apparent unity can conceal how little independent information was consulted. That economy can be beautiful. It can also make one repeated fragment stand in for a difference we have not learned to construct.

<!-- @ -->

<!-- @rhizomatic_maze_space -->

Now move your attention from the surface to the network beside it. NETWORK changes the connection policy over six fixed starting positions. The opening is a tree. Its unique connections give one connected component and no cycle. The next policy admits more nearby connections; the third severs connections across a central gap and separates the remaining pieces.

Watch the counts before deciding what the silhouette means. The desk reports distinct undirected connections, components and independent cycles. The generator may store an edge in both directions; those duplicate records do not create another physical route. For this finite undirected graph, the cycle count is `edges - nodes + components`.

Changing NETWORK preserves the six initial positions. The severed result subsequently displaces positions as part of making its gap, so the final coordinates are not all held fixed. This is a comparison of construction policies, not a claim that every visible difference came from deleting one edge.

SURFACE alternates the bare connections with the tunnel surfaces constructed around them. The specimen's collision is disabled in both views: it is an observation model, not a secretly solid set of invisible tubes. Its gaps and curved surfaces are available to examine before we develop a full bodily traversal. A thick skin can obscure connections that were obvious in the skeleton.

The original generator can also add secondary growth. This opening study sets those iterations to zero so that we can inspect the connections between the six seeds first. We have made a restriction to gain a foothold, not discovered the network's final possibilities.

The pattern tunnel remains a bodily application in the collection. Its surface can be dressed while its supporting route persists. A reflected image does not by itself connect two rooms; a graph edge does not by itself guarantee that its tunnel has sufficient clearance. Geometry, connection and access can be composed, but they require their own checks.

Across this sequence, we have selected, guided, branched, connected, carved, sampled and copied. Each operation gives us something to build with and something more precise to question. What bodies are possible now? We can answer with a construction, try its limits, and carry the unresolved part into the next hall.

<!-- @ -->



# softbodies

Declared order: SoftBodies_Soft_Body_Deformation → SoftBodies_Cloth_Physics → SoftBodies_Carusell → SoftBodies_Obsticals → SoftBodies_Obsticals_Part2 → SoftBodies_Playground_of_Joy → SoftBodies_Affect_Theory_Visualization → ProceduralGeneration_Reaction_Diffusion_Systems → Topology_Entropy_Morphogenesis


## SoftBodies_Soft_Body_Deformation

Source: commons/maps/SoftBodies_Soft_Body_Deformation/final.md

SHA256: 4eb71344fc93eb9545cccfdc57591f5291cde906bbfcd9078a7c930bfd913815

# What holds a cube together?

<!-- @jelly_cube -->

The cube gives way. Yet it does not become a collection of loose triangles. Something continues to hold its parts in relation. Before looking at the settings, choose what you expect a softer cube to do: change further, return more slowly, or fail to return at all?

Try STIFFNESS, then change DAMPING separately. The first changes resistance to deformation; the second damps motion. A body that moves less is not necessarily a body that resists deformation more. RESET restores the opening coefficients. It does not put every vertex back where it was before you arrived.

```gdscript
_soft_body.linear_stiffness = stiffness
_soft_body.damping_coefficient = damping
_soft_body.pressure_coefficient = pressure
```

These are parameters of Godot's soft-body solver. The program supplies a subdivided cube and lets its vertices respond under those rules. PRESSURE introduces another contribution. Watch what inflation can conceal: the same outer silhouette can be maintained by different balances of resistance and internal pressure.

We have already changed whole objects by translation, rotation and scale. Here, their constituent positions change relative to one another. The surface connectivity remains prescribed. Yielding is a new capability; tearing, growing a hole or exchanging a neighbour would require more code. A soft appearance does not announce every freedom a body possesses.

<!-- @ -->

<!-- @softmill -->

Turn toward the mill. The moving apparatus brings a repeated encounter to a soft sphere. Use MILL to hold the drive. The sphere's physics continues; stopping a mechanism is different from stopping everything it has set in motion.

The cube made its coefficients available on a desk. The mill makes the source of an encounter visible in the room. Follow the motion from the machinery to the surface, then consider the room around both: the collider, support and pinned points belong to this body's conditions as much as its stiffness does.

The nearby jelly variants remain useful comparisons, and radiolaria offers a different warning: intricate biological resemblance can be constructed without soft-body dynamics. Keep that distinction for later. First we need to see how a surface changes when some of its points are required to stay.

<!-- @ -->



## SoftBodies_Cloth_Physics

Source: commons/maps/SoftBodies_Cloth_Physics/final.md

SHA256: 3d9dfd344d2210c3f40613f86b377b1ef7dfdbb02811ef29c0d0d3a8cc26384c

# Which points must stay?

<!-- @cloth_straps -->

Walk along the hanging strips. Each begins as an open surface. Unlike the pressurized cube, it has no enclosed interior for pressure to inflate. The upper edge holds while the rest hangs below it.

Press PINS to keep only the upper corners. Look for the difference before naming it. The material settings have not changed. The allowed motion has: points that were fixed can now participate in the sag. PINS alternates those two arrangements; RELEASE removes the pins, and REBUILD makes fresh strips with their upper rows fixed again.

```gdscript
sb.set_point_pinned(i, keep)
```

For each strip, the desk finds the top row in its mesh coordinates and chooses which indices to pin. This is a boundary condition written into an array. The frame makes that condition visible, but the frame and the pinning rule are distinct constructions. A convincing support does not prove how the simulation is attached to it.

Try STIFFNESS after choosing a support. We now have two ways to change the silhouette: change the material response, or change which points may move. When we describe an object as compliant, how much of that description belongs to the object, and how much to the arrangement holding it?

<!-- @ -->

<!-- @softstopscene -->

The four falling bodies provide a second encounter. They are soft spheres, retained from the earlier collection, not pieces of woven cloth. LANDING changes the support below them between a floor, a narrow pan, a rail and a cone. Rebuilding that comparison also starts a new fall.

Their timers disable processing and raise damping and stiffness at scheduled moments. This stopping method is not an explicit snapshot of all vertex positions. The apparent crumple depends on the solver as well as the timer; it is not a shape the material was destined to have. Two shipped stop times are equal; four specimens do not automatically mean four different moments.

This prepares two questions we will return to: what makes the body deform, and what makes us stop looking? Carry the fixed edge into the next hall. There, the support itself moves.

<!-- @ -->



## SoftBodies_Carusell

Source: commons/maps/SoftBodies_Carusell/final.md

SHA256: c78d67bb7bd8399808d3748f81fad7d877bbf1ba566b723842cdec183f4e4b17

# The support moves

<!-- @revolving_joy_ride -->

Stand where you can see the hub and the hanging bodies together. The ring turns because its angle is advanced by the program. The joints and deforming bodies respond to a support whose motion has already been prescribed.

Lower the SPEED. Then REVERSE it. Do the bodies immediately take up the new arrangement? STOP sets the angular rate to zero, but it does not erase velocity, gravity or contact. The support can stop commanding a new angle while its consequences continue.

The rate is measured in radians per second. A complete turn is `TAU` radians. The driven rotation connects this hall to Transformation and Oscillation, but the hanging bodies add a different problem: their current state matters to what happens next.

Change STIFFNESS or PRESSURE while watching a particular body. We should not attribute every difference to speed when we have also changed material coefficients. The apparatus makes a limited experiment possible, provided we remember what we touched.

This carousel offers an image of freedom through motion. Its moving parts also show how motion can be organized by obligations: a joint, a pin, a driven hub. The question is which relations can move, and which relations move them.

<!-- @ -->

<!-- @cloth_straps -->

The cloth strips nearby retain a fixed support. Return to them after watching the ride. They make the contrast available at the same bodily scale: a surface can respond while its boundary remains still, or respond because its boundary is driven.

The sticks, pick-up cubes, flex pad and soft mushroom remain part of the collection. They are opportunities for further encounters, rather than evidence that every visible object runs the same solver. Begin with one comparison you can follow, then widen it.

In the next room, the enclosing architecture takes on a deformable surface. The distinction between a body and its surroundings becomes harder to maintain by pointing.

<!-- @ -->



## SoftBodies_Obsticals

Source: commons/maps/SoftBodies_Obsticals/final.md

SHA256: c846f0bdda3f0607001307260d3ef534aaf1064ec1efeb1d049fe731ddb59f18

# The room has a body

<!-- @breathing_room -->

The walls swell. Find a position from which both their edges and their centres remain visible. Selected vertices stay pinned while the surfaces respond between them. Before entering, watch a complete pressure cycle.

AMPLITUDE changes the range of pressure. RATE changes how quickly its driving phase advances. HOLD DRIVE holds that phase; it does not freeze the wall vertices. The soft solver can continue settling under the pressure it last received.

```gdscript
var p = (sin(_time) + 1.0) * 0.5 * breath_amplitude
for sb in _walls:
    sb.pressure_coefficient = p
```

The sine wave supplies pressure to a deformable body. It does not directly specify the location of every point on the wall. The actual surface is a result of the solver, its constraints and its encounters. This is the bridge from the earlier sine spaces: a periodic instruction now enters a system that can respond.

Calling it breathing is an invitation to bodily recognition. This room has no need for air and no sensor deciding when to inhale. The resemblance can be affecting without becoming a description of its mechanism. Its capacity to narrow space still deserves a practical question: how much room remains for the visitor?

<!-- @ -->

<!-- @softbody_gallery_part2 -->

The nearby contact gallery keeps other combinations visible: soft bodies meet rigid obstructions. Look at one named cell before surveying the whole array. The specimen, its support and its settings constitute a particular test; their variety is not a single scale from hard to soft.

The flag dancer remains as another encounter with a driven system. Together these objects begin to distribute softness across the room rather than confine it to one specimen. Yet the museum crossing still has independent support. A deforming wall and an onward route make different promises.

Next we will hold and replay a contact experiment. A spectacle of differences becomes more useful when we can identify which differences were introduced.

<!-- @ -->



## SoftBodies_Obsticals_Part2

Source: commons/maps/SoftBodies_Obsticals_Part2/final.md

SHA256: 7b534d26e0e7413be044726b69f98d95e444683068c70c53a82a77abeba2dd43

# Same fall, another encounter

<!-- @softbody_gallery_part2 -->

The array contains several kinds of encounter. Start with the names: a slippery collider, a corner strike, high drag, a torus. They do not vary just one property. Choose one cell and compare it with a cell whose difference you can describe.

REPLAY restarts the group from its declared seed. The opening study removes the gallery's additional random changes to stiffness and pressure. VARIATION restores those changes. A fixed seed repeats a recipe for initial conditions; it does not promise bit-for-bit identical physics on every computer.

```gdscript
sb.linear_stiffness = 0.5
sb.damping_coefficient = 0.01
sb.pressure_coefficient = 0.0
```

The gallery applies each named cell's settings on top of these defaults. Optional variation then adds another layer. The final coefficients, the starting mesh and the obstruction all matter. A name like “Jelly” cannot substitute for that construction.

HOLD pins the current vertices. RELEASE restores the pins recorded before that hold. Neither action retrieves an untouched original body. GROUP opens another set of encounters; the study disables automatic respawning and ongoing deflation so that bodies do not multiply while you are trying to inspect one.

The most interesting result may be an awkward fold that a smooth rendering would conceal. Hold it and move around it. Ask which part is an effect of contact, which part comes from the triangulation, and which part depends on the solver's finite effort. Those are invitations to further experiments, not conclusions available from a single silhouette.

The array is useful because it holds differences near each other. It becomes misleading if proximity is mistaken for a controlled comparison. The next hall turns that problem toward time: when we keep a shape, what have we selected from the event?

<!-- @ -->



## SoftBodies_Playground_of_Joy

Source: commons/maps/SoftBodies_Playground_of_Joy/final.md

SHA256: db05fd80c8c80097cbb04b95a9f3f5d0c008c8f67246a2bbeb51de36da421206

# When does a body become a form?

<!-- @rounded_softbody_test -->

The rounded body continues to respond while an instrument colours its surface. MEASURE changes what is made legible: strain, collision or volume. The body has not acquired a new material because we changed its reading.

SQUEEZE changes the strength used by the artifact's existing squeeze interaction. STIFFNESS changes resistance in the solver. Watch the instrument as well as the silhouette. A colour scale can bring a small difference forward, or persuade us that its chosen quantity is the whole event.

The strain display compares the current geometry with reference lengths. That reference belongs to the model. Returning toward it is not a universal tendency toward an original or natural body; it is a particular constraint implemented here.

The branching study and field sculpture remain nearby, so the new capability can be compared with earlier ways of constructing an organic-looking form. A branch recipe, a deformed surface and a sampled field may resemble one another without explaining one another.

<!-- @ -->

<!-- @frozen_glass_vessel -->

The glass vessel has already stopped. Its program begins with a sphere, pins an upper region and runs a custom soft-body simulation for a chosen number of steps. It then builds a surface from the resulting positions.

```gdscript
sim.gravity = Vector3(gravity_x, gravity_y, gravity_z)
sim.constraint_passes = 5
```

DURATION reconstructs the vessel using 40, 200 or 400 solver steps. GRAVITY changes the lateral component of the force. Compare duration first while the force remains fixed. These are numerical steps in a reconstruction, not seconds borrowed from the museum clock.

The object is evidence of a process, with most of that process absent. A different stop could have become the sculpture. The walkable glass surface also has limits established by its mesh and collision; resemblance to a vessel does not guarantee an opening large enough for a body.

A frozen result lets us look longer. It also makes the timing of a decision disappear into the apparent permanence of a thing. Next, we will ask what else an image of a body invites us to infer.

<!-- @ -->



## SoftBodies_Affect_Theory_Visualization

Source: commons/maps/SoftBodies_Affect_Theory_Visualization/final.md

SHA256: e5efa5db74ff2c18bf60affae7845d27258c82b32c5406523714ab54150da437

# What makes this look alive?

<!-- @radiolaria -->

The forms invite recognition before explanation. Spikes, rings and lattices suggest organisms, shells, pollen or something that might brush against skin. Let that recognition arrive, then keep it beside the question of how these objects were made.

Stop ROTATION. Toggle EFFECTS to change the particles surrounding the forms. What still looks alive when these motions cease? COLOUR also rebuilds the geometry in this implementation; with the initial unpinned random seed, it can change more than colour. Press SEED to choose a repeatable construction before comparing palettes. SPIKES changes a probability in that recipe; it does not teach an organism to defend itself.

The program constructs several families from geometric elements. Its parameters include `spikiness_probability`, `max_spike_length` and `detail_level`. These names describe decisions available to the generator. They are not measured properties of a living radiolarian.

We have arrived here with the ability to generate patterns, branch, deform a mesh and sample a process. That toolbox makes several accounts of an organic-looking object possible. Which one did you expect when you first saw these forms? What in their colour, repetition or motion supported that expectation?

The gap is productive. Desire can travel ahead of an explanation; a strange body can invite attention before we know how to describe it. Learning the recipe need not cancel that encounter. It gives us something specific to vary when the familiar repertoire begins to close around what a body is allowed to look like.

Radiolaria belongs here as an explicit contrast, not proof that static geometry is a soft-body simulation. In the next hall, spatial differences will be maintained by exchanges in an evolving field. Biological resemblance and a model of morphogenesis will finally meet as different claims we can examine.

<!-- @ -->



## ProceduralGeneration_Reaction_Diffusion_Systems

Source: commons/maps/ProceduralGeneration_Reaction_Diffusion_Systems/final.md

SHA256: e0a3d1a696db3359b160a03bb4361bdf772bca481d5ea7c1093ec23049373a17

# A pattern has a metabolism

<!-- @turing_pattern_generator -->

A patch interrupts the field. Before advancing it, predict where the next change should occur: everywhere at once, around the boundary, or only inside the patch? STEP performs one update. A hundred updates make the consequence easier to see while keeping the same rule.

At each address the program stores two concentrations, U and V. It reads the old arrays, calculates local changes and writes separate arrays for the next state. Only then are the buffers exchanged. The result does not depend on whether the display happened to draw the left edge first.

```gdscript
var uvv = u * v * v
var du = Du * lap_u - uvv + feed * (1.0 - u)
var dv = Dv * lap_v + uvv - (kill + feed) * v
```

Diffusion exchanges with neighbours; reaction, feed and removal change the local quantities. This is the Gray-Scott model, not a direct implementation of Turing's original chemical equations. REGIME chooses another feed/removal preset and restarts the field. SEEDING changes the initial arrangement. Compare those interventions separately.

The grid wraps at its edges. Concentrations are clamped to the interval zero to one. These choices are part of the experiment. A field that seems to continue beyond its frame has a particular way of returning through it.

<!-- @ -->

<!-- @reaction_diffusion -->

The second reaction–diffusion display remains a running comparison with its own implementation and settings. It is not a synchronized duplicate of the desk study. Look for recurring spatial features, then return to the controls before attributing a difference to one coefficient.

The soft-body samples, detailed bulge and Confessing Body theatre preserve further connections to the chapter. A chemical field can colour a wall, displace a surface or feed a growth rule, but each application needs an explicit mapping. Pattern formation alone has not made a solid that can bear your weight.

This matters to the red thread. New combinations become possible, and so do new confusions. A useful bridge should let us inspect the operation that carries a field into a form. The next artifact provides precisely such a mapping—and gives one of its controls an especially demanding name.

<!-- @ -->



## Topology_Entropy_Morphogenesis

Source: commons/maps/Topology_Entropy_Morphogenesis/final.md

SHA256: 08d08cb690cbe43f04b2f7ed1dc5ef3b942cba03522be4f40abf22fb67cf7887

# Who connected the controls?

<!-- @entropy_morphogenesis -->

The surface opens and folds around passages. It recalls the sine and noise spaces we walked earlier, now combined into a sampled field. Before touching S, choose one opening you can follow with your eyes. Keep track of it as the surface is reconstructed.

S changes several parameters together. The desk reports their values so that an impressive transformation does not hide its recipe.

```gdscript
current_frequency = lerpf(base_frequency, high_frequency, S)
current_noise_amp = lerpf(base_noise_amp, high_noise_amp, S)
current_threshold = threshold_center + threshold_wobble * (S - 0.5) * 2.0
```

The parameter is called entropy in the source. Here it is an authored control between settings, not an entropy value calculated from a distribution. Its name cannot establish a law connecting disorder and form. The mapping can nevertheless become a useful instrument if we expose what it does.

NOISE removes or restores the noise contribution. LEVEL changes the threshold arrangement. RESOLUTION changes the number of samples used to construct the surface. Try them separately, then compare that experience with moving S. Which differences had been bundled into its single gesture?

The generated collision belongs to the reconstructed surface. An opening that appears in a rendering may still be too narrow for the player. A change in geometric frequency is not automatically a change in connectivity, and neither alone certifies a traversable route. We can learn to ask each question at the scale where it has consequences.

Across these halls, a body has become a set of relations that can yield, remain attached, be driven, meet an obstruction, or be held as a sculpture. We have also seen appearances that imply mechanisms they do not contain. The point is not to exhaust desire by naming every rule. It is to gain enough purchase on a rule to change what it permits—and notice what the next construction still leaves out.

<!-- @ -->



# isosurfaces

Declared order: ISO_Introduction → ISO_LookupTable → ISO_ShapesGallery → ISO_TorusGyroid → ISO_Sculpting → ISO_FlatTerrain → ISO_PortalLandscape → ISO_Caves → ISO_CaveGeneration → ISO_AnimatedNoise → ISO_Metaballs → ISO_ImplicitModeling → ISO_RhizomeBody

Museum map-authored order differs: ISO_Introduction → ISO_LookupTable → ISO_ShapesGallery → ISO_TorusGyroid → ISO_Sculpting → ISO_FlatTerrain → ISO_Caves → ISO_Metaballs. Treat this as route drift to inspect, not an editorial recommendation.


## ISO_Introduction

Source: commons/maps/ISO_Introduction/final.md

SHA256: 7e06893df3e41621612058768f90b3aa3f24e059425244c454ed5f1c30707fcf

# A boundary made from values

<!-- @voxel_noise_demo -->

Where does this surface come from if nobody drew its outline?

Move around the blue specimen with pink triangle edges. Choose a visible boundary and follow it across several triangular patches. Look for a place where the outline turns sharply, then compare it with a smoother region. The large form is continuous-looking, but its visible surface has been assembled from small pieces.

Choose a short edge between two visible triangles and follow it towards the next patch. Then step back until those small divisions become difficult to distinguish. The overall form remains readable even as its construction recedes from view. Return closer and compare the two readings. Neither distance is the uniquely correct way to see the specimen: one reveals an assembled boundary and the other its larger organisation. What matters is remembering that a smooth-looking silhouette at a distance does not erase the finite pieces from which this display is made.

Before those pieces exist, the generator samples a noise field throughout a volume. Each sample receives a number. A chosen level divides the samples into two classes: values below it and values on the other side. Where neighbouring samples cross that level, the program estimates positions for a boundary.

An isosurface is the set of locations at one selected value of a scalar field. This mesh is a finite approximation to such a set. Its triangles connect estimated crossings; they are not the field itself, and the regions where no triangle appears still have field values.

The porous specimen in the previous room introduced the same distinction between values and visible form. Here, keep it in view while examining the polygon structure. The threshold did not add a decorative skin to a finished cave. It helped determine which boundary would exist in the first place.

Return to the desk. Before pressing LEVEL, choose a neck, an opening or a patch of boundary to watch. LEVEL cycles through 0.50, 0.45 and 0.55. The source field stays fixed: the same seed, noise settings, domain and sample positions. What changes is the value at which we ask for a surface. A piece may retreat, join another or disappear; the button does not promise the same event at every place.

```gdscript
density = (noise_value + 1.0) * 0.5
if density < iso_level:
    config_index |= (1 << i)
```

The first line produces a sample value. The comparison in the second classifies one corner; its bit contributes to a local case number. Lowering the level means fewer samples satisfy this particular comparison. It does not mean that every visible opening must grow. Boundary, enclosed volume and passage are different things to inspect.

Press HOLD to leave a second specimen to the right. Then RESET the live one. The held mesh remains where it was: a record of the earlier level and sampling, labelled with both. It has no collision of its own. The live specimen retains its generated collider. CLEAR removes the copy, leaving the live field alone.

SAMPLES asks a different question. It cycles through 24, 16 and 32 sample positions on each axis: 13,824, 4,096 and 32,768 values. The noise recipe and the extent of the sampled box stay the same. The mesh is displayed at 0.18 of its source size, so that box spans 5.76 metres in the hall. More samples refine this approximation; they do not supply knowledge about an original object hidden behind the noise.

A small passage may depend on both level and sampling. Absence from the mesh does not establish absence from the underlying field, particularly where a feature falls between widely separated samples. Nor does a visible hole establish clearance for your body. Hold that uncertainty beside the usefulness of the procedure: a few rules have made a boundary we can encounter, and its exclusions are now specific enough to test.

<!-- @ -->

The next room opens the local construction. Eight corner samples will select a case, and that case will tell the extractor which edges to join.



## ISO_LookupTable

Source: commons/maps/ISO_LookupTable/final.md

SHA256: 5b5b0c8e3ed24ccce01906b82ae8266b3edbf8dad87842c06aa5d3f45f518f10

# Eight samples, one local decision

<!-- @fifteen_cases_demo -->

What can eight corner samples tell you about the space between them?

Compare two tiles in the fifteen-case display. Find their corner indicators before following their triangle edges. Look for a tile with one separated corner, then another in which several corners share a classification. How does the boundary change when the arrangement of classified corners changes?

Choose a pair of indicators on opposite ends of an edge and ask whether their classifications agree. If they disagree, locate the corresponding boundary crossing where it is visible. Repeat on another edge before trying to read the whole tile. This lets you build an explanation from a relation small enough to check directly. When the corner arrangement becomes more complicated, retain that edge-by-edge reading instead of guessing a familiar shape. The case table organises many such local questions, but each crossing still begins with values at particular sample positions.

The corner values used by the indicators also feed the surface generator. A comparison with the threshold turns each corner into a bit. Eight bits provide a case number, which selects a triangle arrangement from a table. Edge crossings are then positioned using the numerical values at their endpoints.

These are two different uses of the samples. Their signs choose a connection pattern; their magnitudes help decide where a crossing lies along an edge. Two cells can choose the same table case while placing its triangle vertices at different positions.

The previous room showed the assembled surface. This display makes some of its recurring local decisions easier to inspect. The fifteen examples show selected arrangements, while the complete corner classification contains two hundred and fifty-six masks. Symmetries help relate cases; they do not remove every ambiguity about a continuous surface between samples.

There is another scale to attend to: the displayed pieces include surrounding sampled cells. Read the marked corners as the local question under study, rather than assuming every visible triangle belongs to one isolated cube.

Press TRACE. Gold markers appear where the cage edges cross the selected level. Choose one before pressing MARGIN. The values change from 0.30/0.70 to 0.14/0.54, then 0.44/0.84 and 0.48/0.88. The threshold remains 0.50. Every low value stays below it and every high value stays above it.

From the high endpoint toward the low endpoint, the crossing moves through 0.50, 0.10, 0.85 and 0.95 of the edge. Watch the marker before looking at the entire sheet. Its movement follows a small calculation:

```gdscript
t = (threshold - d0) / (d1 - d0)
position = p0.lerp(p1, t)
```

OPERANDS hides the extracted sheets, leaving the cages and samples. SURFACE removes those guides and shows the generated result. RESET restores the complete display and evenly spaced values. MARGIN changes the values in any of these views. Which view lets you explain what just happened, and which invites you to forget the construction?

The labels expose another convention. The inherited arrangement number sets bits for high-valued corners. The extractor sets bits for values below 0.50. Those masks are complements: arrangement 1 has table mask 254. The positions and values agree; the two names count opposite classes. “Inside” has not arrived with an independent physical meaning.

These are fifteen selected arrangements, including empty and full classifications, not a demonstrated exhaustive catalogue of distinct topologies. On alternating faces, corner classifications alone leave a connectivity question for the algorithm. This display shows the installed table’s choice; it does not compare every ambiguity-resolution strategy. Keep that limit available for a later experiment.

<!-- @ -->

Next, the field will describe familiar objects. The triangle-making procedure can remain the same even when the description supplied to it changes between different shape descriptions.



## ISO_ShapesGallery

Source: commons/maps/ISO_ShapesGallery/final.md

SHA256: 7cec856a7ca1d88a9380fd00101ccbf404dd604fd136bd9ddbf9e71749c6dbfe

# The same tool makes a cup

<!-- @mc_shapes_gallery -->

Can the procedure that makes a chair also make a hollow cup?

Compare the labelled Chair and Cup in the shapes gallery. Find a junction between parts of the chair, then look for the cup's inner boundary and its handle. Move to a second viewpoint where a hollow and a projecting part are easier to distinguish. Describe those relations before naming their ingredients.

Inspect a junction on the chair from a second angle. A seam can disappear in the combined surface even though the description still contains separate ingredients. Then compare the cup's hollow with the empty space around its handle. Both are absences in a familiar object, but they arise from different parts of its description. You need not recognise every primitive to establish that these relations differ. Naming one junction and one opening gives you a smaller, more testable account than saying that the generator understands household objects.

Press HOLD. The middle-column chair and cup are copied beside the desk. They keep their current geometry when the live gallery changes. Choose a gap between the chair's legs, or the opening of the cup. What do you expect LEVEL to do there?

Press LEVEL once. The extraction level moves from zero to minus two. Compare the live objects with the held pair. Look for a part that has narrowed or disappeared, then one that still carries the object's name. LEVEL affects all six fields; it does not know which part you meant to protect. Further presses choose plus four and plus ten before returning to zero.

The chair is described by combining box-like fields for a seat, back and legs. The cup uses a different composition: an inner cylinder is subtracted from an outer one, then a ring-like handle is joined to the result. These descriptions provide values throughout space. The same extraction apparatus samples them and builds the visible boundary.

In the shader, joining two fields takes their minimum. Subtracting the interior takes the maximum of the outside field and the negated inside field. The cup's description can be read in one short expression. Here the variable names stand for the fields evaluated at the same point:

```glsl
float cup = min(max(-inside, outside), handle);
```

That line describes a relation at a point. Sampling repeats the question across space; the extractor connects the crossings. Moving the selected level changes the question asked of the whole composition. It is not a command to thicken only the cup wall.

The lookup table does not need to know what a cup is. It receives corner values and performs the local work you examined in the previous room. Recognition belongs to the larger arrangement of those values and to the person reading the resulting form.

This separation makes procedural modelling reusable. A new description can enter an existing extraction process. It also lets us ask whether an error belongs to the description, the sampling, or the way the generated mesh is displayed.

A familiar silhouette is not a complete design for use. A thin handle may disappear at coarse resolution; a chair-like figure may have no suitable support or dimensions for sitting. The label supplies a proposed interpretation, not evidence that the object fulfils every function associated with its name.

Try REPERTOIRE. Household gives way to laboratory, abstract and survey arrangements, using the same extraction machinery. The held pair stays beside you. A field can describe an operator and an instrument through the same numerical substrate; that shared description does not give them the same capabilities.

RESET restores the household at level zero and keeps your comparison. CLEAR removes the held pair. Hold a different pair after changing repertoire, then ask what the new names encourage you to see. At level minus two, the sampled cup disappears entirely. Its labelled place remains empty; a replacement sphere would conceal the result. Even at level zero, gaps in its thin wall expose the coarseness of the mesh. The display samples a finite domain at 64 points per axis. A narrow feature can be absent from the mesh while still present in its formula. Which loss came from the rule you changed, and which was already waiting in the sampling?

We have added another way to make a body, and another way to mistake an available shape for an exhausted possibility. The cup need not remain a cup. But escaping its name will take more than changing the label.

<!-- @ -->

The next room leaves the household repertoire and examines a surface whose repetition extends through three directions without being assembled from separate repeating objects.



## ISO_TorusGyroid

Source: commons/maps/ISO_TorusGyroid/final.md

SHA256: be2406169db2d10d9fe08b2f6a825aeed000c192f6700b9bfe19262b63b52512

# Repetition without separate pieces

<!-- @mc_torus_sculpture -->

Begin with the torus. Follow the tube around its opening until you return to the part where you started. The empty centre has a boundary you can trace. Move sideways: the visible opening narrows, although the object has not changed.

This reference uses the existing torus field with its distortion weights set to zero. We have temporarily put aside the noise that made the earlier sculpture irregular. The ring lets us keep a relation in view while the next specimen makes repetition harder to separate into individual things. An opening is visible here; whether your body can pass through it is another question, involving orientation, size and collision.

<!-- @GyroidDemo -->

Does a repeating surface have to be a collection of repeating objects?

Choose an opening in the gyroid specimen and follow the surrounding fold into the next region. Change viewpoint wherever a crossing obscures the connection. Look for repetition along another direction, then compare its scale with the first. The pattern is not organised only across a flat face.

Keep one opening as a landmark and compare it with the next recognisable opening along a fold. Look at their orientation as well as their apparent size. Repetition in a volume can carry a relation around a bend, so matching silhouettes are not the only evidence available. If the two features differ, consider whether the difference might come from viewpoint before attributing it to the field's perturbation. A second angle can resolve some of that uncertainty while also revealing another layer of the repeating structure behind the first.

The field begins with three linked trigonometric terms: sine in one direction multiplied by cosine in another, repeated cyclically across the coordinates. Together they create a periodic spatial relation. A threshold selects a surface from that relation, and the extractor turns the sampled boundary into triangles.

Start with FORMULA and SHEET, the desk's initial settings. No noise perturbation is applied. The selected level is still one: this is a sampled trigonometric gyroid level set, not a demonstration of an exact minimal surface. Even “formula” has a chosen boundary and a finite sampling grid.

Press HOLD before changing PERIOD. A copy remains behind the live specimen. PERIOD cycles through coordinate multipliers 0.5, 1, 2 and 4. Choose a fold and compare how much of the repeating relation now fits inside the same domain. The specimen has not simply been scaled as a whole. Its sampling budget remains 64 points per axis while the expression asks those samples to describe more repetition.

The shader's central operation is short enough to carry with you:

```glsl
vec3 gp = p * periodScale;
float gyroid = dot(sin(gp), cos(gp.yzx));
```

The dot product adds sin(x)cos(y), sin(y)cos(z) and sin(z)cos(x). Each term couples two coordinates. The extractor compares the combined value with one; it does not assemble a separate little object for every opening.

INTRUSION restores the complications one step at a time: fine noise erosion, then broader field modulation, then coordinate warp as well. Follow the same region through those changes. Noise can make the surface less regular, but what did it add to the relation you could already describe? What did it make harder to follow? RESET restores FORMULA and SHEET while leaving your held comparison intact.

The shapes gallery assembled descriptions of recognisable parts. Here, repetition arises directly from a field expression. There need be no separately stored object corresponding to each opening you recognise.

That shift changes what it means to edit the form. Adjusting the period changes a repeating relation across the volume. Altering a threshold can change thickness and connections. Distorting coordinates changes where the expression is evaluated. Those operations may all affect an opening, but they are different explanations for its altered shape.

A thin gold line marks one straight test through the live specimen. PROBE changes the radius of an upright capsule from 0.20 to 0.35 to 0.60 metres; its height stays 1.70 metres. The readout reports how far this capsule can travel along the marked twelve-metre segment before the gyroid's collider stops it. The warm marker locates that stop. A larger body asks more of the same visible opening.

This is a deliberately narrow question. The probe does not search for a winding route, test footing, or reproduce every part of the player's controller. A blocked straight path does not prove that no route exists. If the generator omitted collision because the mesh was too costly, the desk says the probe is unavailable; an untested wall must not become evidence of freedom.

We now have three accounts in the same room: a periodic expression, a visible surface and a limited test of bodily clearance. They can disagree. That disagreement gives the next experiment its location. Rather than adding roughness until the object seems alive, we can ask which change makes a passage, a refuge, a barrier, or a relation we do not yet have a name for.

<!-- @ -->

The next room introduces a more direct gesture. Instead of changing a repeating expression, your hand will add local contributions and watch the extracted surface join them together.



## ISO_Sculpting

Source: commons/maps/ISO_Sculpting/final.md

SHA256: 59d09eafa7034b1a317fec111cddf214e3b5704ba166e48936bfc76a3d935607

# Add a contribution

<!-- @mc_sculpt_vr -->

When two rounded deposits meet, where does their seam go?

Begin with the two deposits inside the framed volume. Their centres are 0.90 metres apart and each radius is 0.30 metres. There is room between them. Press PAIR to bring their centres to 0.65 metres apart, then 0.45. Before each change, predict whether a neck will appear. The deposits keep their radii; the relation between them changes.

HOLD keeps the current surface beside the live volume. Now press ADD. A gold point marks where the desk places its quarter-metre brush contribution. Inspect the join from another angle before adding again. A short, located edit gives you something you can explain; repeated deposits combine before their effects become easy to separate.

In VR, move a controller into the framed volume and hold its trigger briefly. The active ADD or ERASE mode also applies to this hand gesture. The desk offers a repeatable location for comparison; the controller supplies your own. Move outside the volume and the brush no longer deposits. That frame is a limit of this instrument, not the edge of space.

The brush does not push a particular triangle into a new position. Its location is translated into the generator's coordinates and stored as a contribution with a centre and radius. The field combines sphere-like distance descriptions with a smooth blending operation, then extracts the surface again.

The changed join is therefore a result of several decisions: where you deposited, how wide the contribution is, how contributions are blended and how finely the field is sampled. Your gesture participates in the form without directly specifying every point of its boundary.

The gyroid changed a repeating spatial expression. This sculptor adds local descriptions to a collection. Both approaches return to the same task of finding a visible boundary from values, but they distribute authorship differently across the volume.

Press ERASE. It uses the same marked centre and nominal radius as ADD. Look for the new inward-facing boundary, then compare with your held surface. The earlier implementation accidentally turned erasure into another addition by discarding a negative sign. Here that sign survives into the field calculation.

At the lesson's selected level of zero, the distinction can be written as two operations. The brush field is distance from its centre minus its radius:

```glsl
// deposit
field = smooth_union(field, brush, blend);
// cut
field = max(field, -brush);
```

The cut is a new contribution to the recorded history. It does not remove a record of the earlier gesture. ADD after ERASE can fill some of the cut again; ERASE after ADD leaves the cut. Order has become part of the form. Subtraction also has a sharper junction here than the smooth addition. They are different operations, not perfect opposites or an undo command.

PAIR replaces the live history with the next pair of deposits. RESET returns the wide pair and ADD mode; both keep the held surface. The display records how many contributions remain. Two different histories can leave a similar-looking boundary, and the same number of records can describe quite different bodies.

The extractor still samples 64 points per axis. Your hand moves between samples and between recorded strokes. The brush cannot promise to keep every distinction in the gesture. There is also a less visible limit: after five hundred contributions the generator drops the oldest. A cut may remain in the history after the deposit it once cut has been forgotten. This instrument's memory helps make the body, and also decides what it can cease to remember.

<!-- @ -->

The next room scales the same field-making idea towards terrain. Ask what additional relations a volume can describe beyond the single upper height of a conventional landscape.



## ISO_FlatTerrain

Source: commons/maps/ISO_FlatTerrain/final.md

SHA256: 3c043c81946d8977d6dd1d92c7c6bb915a6045e6e2dc51097676a64bce13044c

# Look beneath the height

<!-- @mc_flat_landscape -->

How many times can the ground be above the same place?

The turquoise landscape begins with hills. Walk around its edge. A gold line passes vertically through it; the small marks show where that line meets the generated surface. The desk reports one crossing. Choose another COLUMN. The height varies, but each tested column still has one answer.

Press HOLD. The earlier surface remains behind the live specimen. Now press INTERIOR once, then again. Look beneath the upper profile before reading the number. Something can disappear from the top view while becoming visible from the side. A fold may give the same vertical line more than one meeting with the boundary.

The first field begins with a familiar description:

```glsl
float terrainDensity = (surfaceHeight - worldPos.y) / 30.0;
float density = terrainDensity - caveNoise * params.caveStrength;
```

Here `surfaceHeight` depends on horizontal position. With cave strength zero, the second line leaves the first alone. Rise through a column and the density decreases steadily; at level zero it crosses at the assigned height. The hills can be rough or smooth. This description still gives each horizontal position only one height. It cannot independently specify a floor, an air gap and a ceiling there.

INTERIOR keeps that height function, sample domain and threshold unchanged. It changes the weight of a three-dimensional cave field: zero, 0.3, 0.4, then 0.8. Because that contribution varies with height too, the final field need no longer decrease steadily as you rise. A column can leave solid, enter air, and meet solid again.

Try the strongest setting. The marked column is chosen from a fixed set of 25 by 25 test positions, with the most crossings shown first after a rebuild. COLUMN moves through that set. These are intersections with the extracted triangles. They are evidence at particular positions, rather than a complete account of the continuous field or the whole landscape.

The cave term can also lower the upper surface. Holding the height function steady does not hold the final skyline steady: both terms contribute to the boundary. Compare with your held copy. Which difference did you notice first—the changed silhouette, or the space beneath it?

The earlier noise rooms gave us variation we could recognise as terrain. Here we ask what that variation is allowed to describe. Adding more detail to a height function cannot give it a second answer at the same position. Changing the description can. Even then, an enclosed pocket may offer no entrance. A visual opening may be too small for a body. This miniature's column counter does not decide either question for us.

<!-- @mc_overhang_landscape -->

The amber landscape starts from a height field too. Press TERMS and watch it acquire contributions one at a time: overhang, cave, arch, then outcrop. Keep the turquoise specimen as it is while you examine the amber one from the side.

Its description gathers several tendencies:

```glsl
density = baseTerrain - overhangDensity - caveStrength
        - archStrength + outcropStrength;
```

Each contribution has its own spatial mask and noise calculation. The two specimens share an extractor, but they are not a matched pair differing by one switch. The left experiment varies the weight of one interior field. The right experiment adds different terms to a composition. Distinguish those questions before comparing the results.

The names suggest things to look for. Does the setting called “arched” give you an arch you can recognise here? Where does it fail to do so? A word on the desk names an intention; the field, sampling and selected domain make the actual surface. The gap between those accounts is part of the encounter.

RESET returns both reference fields and keeps the held surface. Neither specimen is rescaled or lifted to improve its fit as the values change. Some differences are small. Come closer, change your viewpoint, or keep the question open. More terms need not produce more usable space.

<!-- @ -->

The original CPU terrain and rhizome specimen remain further into the hall, offering other ways to return to this question. Our next stop is Portal Landscape: once an opening appears, where can it take us?



## ISO_PortalLandscape

Source: commons/maps/ISO_PortalLandscape/final.md

SHA256: f40c475d123f61a759b1d7c07a401a0027de4d2097e4f1e906d5f8b69baf21bc

# An opening from overlapping terms

<!-- @marchingcubes_portal_landscape -->

How can an opening appear without an instruction that draws a doorway?

Find a projecting ledge in the compound landscape, then compare it with a recess or apparent arch. Shift your viewpoint to test whether a dark patch is a hole, a shadowed face or an overlap in projection. Follow the boundary around a candidate opening before deciding what it connects.

Compare a recess with a neighbouring projection and describe which side of each boundary appears to contain material. An apparent arch seen from the front can be a shallow indentation rather than a passage; changing viewpoint tests that reading. Keep one landmark near the candidate opening so that you do not accidentally compare different features. The goal is a modest claim you can support: this boundary projects, this one recedes, or these visible edges appear to enclose a through-opening. The field's named terms can then help explain those observations without replacing them.

The landscape combines several terms in one density field. A base terrain term supplies an initial relation between ground and air. Other terms reduce density in ways intended to produce overhangs, caves and arches. An outcrop term adds material in selected regions. The extractor sees their combined value at each sample.

An opening can result where those contributions cross the threshold together. It need not exist as a separately modelled doorway. Conversely, adding a term associated with arches does not guarantee a useful opening at every location: its effect depends on the other terms already present.

The preceding terrain introduced a cave contribution beneath an upper surface. This specimen extends that composition. Rather than describing the final silhouette as a single mysterious noise, you can ask what each part of the field is allowed to change.

Despite the specimen's portal name, an opening here is geometry. It does not transport you somewhere else, and its appearance alone does not prove an accessible route through the mesh.

A useful extension would display the existing cumulative settings in order: hillside, overhung, quarried, arched and compound. Preserve common coordinates and scale so that a visitor can follow the consequences of each added term. A second experiment could remove one term from the compound version and ask which features depended on it.

<!-- @ -->

Next, the same kind of boundary will be read as enclosure. The question moves from how an opening looks to what the space on its other side permits.



## ISO_Caves

Source: commons/maps/ISO_Caves/final.md

SHA256: e5faebde69d63adf70b402386cc64ffb9ec288b3eb47dc23363e57136affb658

# On the enclosing side

<!-- @mc_portal_landscape -->

The portal landscape is a promise made by a boundary. From the approach it looks like terrain with openings: stone rises, a ring declares a passage, and the field has been asked to join the two. Walk its edge first. Does the opening meet the floor, or does the name “portal” ask you to supply a route the mesh has not made?

The generator carries a count and a burial choice:

```gdscript
num_portals = 7
burial = "straddling"
```

Press PORTALS and watch the rings multiply. Press BURIAL to move the same family of portals from sunken to standing to floating. A change in count is a change in repetition. A change in burial is a change in the relation between a boundary and the floor. Neither word guarantees that a body can cross.

<!-- @mc_inside_cave -->

Now turn towards the enclosing cave. The same kind of sampled boundary is no longer a facade in front of you. It is above, beside and behind the eye. Press PLUMB once, then OCTAVES once. Notice which changes you can read from outside and which only become legible when the wall closes around your viewpoint.

```glsl
density = ridged_noise(p) - plumbScale * (p.y + 100.0) / 300.0;
```

`plumb` is a written vertical bias: bedded, overturned, weightless or steep. `octaves` decides how many scales of the ridged sum survive. The field is sampled at a level and extracted into triangles. It is not a cave because the label says so; it becomes an interior when the classified air has enough width, headroom and an entrance.

Press HOLD before changing the field. The earlier view stays behind the live specimen as a memory of the surface. A column can show several crossings, but a counter is not a body. Follow the wall, look back to the entrance, and test the route with your own clearance rather than with the most dramatic chamber in view.

<!-- @queer_marching_cave -->

The long cave in the rear aisle keeps a different vocabulary: bulge and resolution. It is a useful remainder, not a third answer to the same control panel. Its folds make the distinction felt: topology is not only whether a surface exists, but which bodies its passages permit.

<!-- @ -->

An isosurface gives inside and outside one calculation. The museum makes the choice visible by changing your side of the boundary. A portal can be a hole that does not connect; an enclosing cave can be a room with no adequate entrance. The field supplies possibilities. A route is authored through width, collision and a body that can arrive.



## ISO_CaveGeneration

Source: commons/maps/ISO_CaveGeneration/final.md

SHA256: 71d94dd8759c7d5f2a75789c40244b27f37148cc895b87e4015e730909c82e3f

# Designing the conditions of a cave

<!-- @marchingcubes_cave -->

Who designed a corridor if nobody placed its walls one by one?

Compare this cave specimen with the one you have just inspected. Look at the scale of surface changes, the sizes of apparent passages and the relation between larger openings and smaller detail. Choose one difference you can describe without yet assigning it a cause.

Choose one comparison at a time: the width of a visible opening, the frequency of small surface ridges, or the way a cavity meets an outer boundary. Keep those descriptions separate, since they may respond differently to the changed settings. If a feature has no clear counterpart in the earlier specimen, say so rather than forcing a match. A useful comparison can establish that the two results differ without yet identifying a single cause. That restraint makes the proposed controlled experiments more informative when the room later provides them.

Both specimens belong to the same generating family. They combine multiple scales of noise with a vertical bias, then extract a threshold boundary. This scene uses different noise-scale and threshold settings from the preceding cave, as well as a different extent. The resulting difference is therefore not a clean experiment on a single parameter.

The program calculates many local values, but people choose the family of expressions, their ranges, the sampling budget and the conditions under which a result is accepted. Procedural generation shifts some design work towards specifying conditions. It does not make those conditions authorless.

The previous room read a threshold through embodied clearance. This comparison asks how the distribution of possible passages was shaped before any visitor approached them. A field can supply an abundance of cavities while supplying very few useful connections between entrances and destinations.

Do not judge a generator only by its most attractive specimen. One successful-looking opening cannot tell you how often the same settings produce inaccessible pockets or overly narrow routes. Likewise, two visually different caves do not isolate which parameter caused each difference.

A useful extension would hold the field coordinates, threshold and sampling fixed while varying noise scale. A second set could retain the scale and vary only the threshold. Mark a common location in every specimen so visitors can follow a particular change instead of comparing unrelated silhouettes.

<!-- @ -->

Next, the field's sampling position will change over time. Ask whether the resulting movement belongs to persistent objects or to successive reconstructions of a changing description.



## ISO_AnimatedNoise

Source: commons/maps/ISO_AnimatedNoise/final.md

SHA256: bbbdbecab0a0f5d32963beced4a914f7f0cfb0deaa9061f93b37c8ef03b2057e

# Which block moved?

<!-- @animated_noise_explorer -->

Are these blocks travelling, or are different blocks appearing?

Choose a small region of the animated display and keep its position in view through several updates. Watch for a block-sized location that changes from empty to occupied, then disappears again. Try following a particular block as if it were a particle. Notice where that reading becomes difficult.

Try looking at the display in two ways over similar intervals. First follow the apparent centre of a visible cluster, as you might follow a moving object. Then hold your attention on one fixed position and record its appearances and disappearances. These readings can produce different descriptions of the same updates. The second makes replacement easier to notice, while the first draws together successive shapes into an imagined traveller. Comparing them gives you an observable reason to question particle-like motion before learning how the representation is rebuilt.

The generator advances an offset through a deterministic spatial field built from several trigonometric terms. At intervals, it samples the field again and rebuilds the displayed geometry. It does not preserve a set of individual blocks and integrate their velocities through the volume.

The current extraction shows whole cells whose corner values lie on both sides of the threshold. Such a cell contains evidence that the boundary passes somewhere through it. Drawing its complete box marks that region without determining the interpolated surface inside it.

That is a coarser representation than the triangle surfaces earlier in the sequence. The blocks should be read as boundary-containing cells, not as a finished marching-cubes mesh with unusually square triangles. The distinction matters when estimating thickness or deciding whether neighbouring features actually connect.

The cave generation room compared different authored fields. This display changes where one field is sampled and lets you see successive representations. Apparent motion can come from replacement, even when no persistent object follows the path your eye invents.

A useful extension would freeze the offset and place this cell view beside the available edge-crossing markers. Those markers locate interpolated boundary positions without yet joining them into triangles. Compare both at the same resolution before asking what a finer sampling would improve.

<!-- @ -->

Next, several local influences will contribute to one boundary. A connecting neck will make another apparently simple event, two bodies joining, available to read as a change in field values.



## ISO_Metaballs

Source: commons/maps/ISO_Metaballs/final.md

SHA256: 992f8bd63ab0445be928573edc502036d6fa42e51e64abc1da7a5f7296c5ef9c

# A neck between sources

<!-- @metaball_world -->

Can two sources make one body before their centres meet? Walk the primary field and look for the narrow neck between rounded regions. The surface does not mark ownership: it is the place where a sum crosses a threshold.

At the desk, press EMPLACE. The same ten sources move from a column to a ring, a pair, a shell and a scatter. Then press KERNEL. The contribution of each source changes from inverse square to Wyvill, Gaussian or cone. Keep the source count fixed while you change the arrangement; keep the arrangement fixed while you change the falloff. That separation is the lesson.

```gdscript
density(p) = sum(kernel(source_i, p))
surface = density(p) > iso_level
```

Press HOLD before making a change. The earlier boundary stays behind the live field, so a neck can be read as a relation rather than a special object. When a bridge pinches off, nothing has been cut from a mesh. A different set of samples simply crosses the same threshold in a different place.

<!-- @raymarched_metaballs -->

The raymarched specimen nearby makes a related surface by another route: signed distance functions are blended while a ray advances. Its smoothness is not evidence that it shares the same field. Look for what the extracted field can show that a ray step keeps implicit, and what the ray can make continuous without storing triangles.

<!-- @nakama_metaballs -->

Nakama keeps the blob vocabulary but changes the implementation and the limits of the body. It is a comparison, not a third control on the desk.

<!-- @metaballs -->

The small rear specimen is the compact reminder: several influences can become one visible mass, but the threshold still decides where the body ends.

<!-- @ -->

A metaball has no outline to defend. It is a negotiation among sources, kernel, sampling grid and threshold. The next hall asks what happens when a boundary is not merely blended, but cut into a passage.



## ISO_ImplicitModeling

Source: commons/maps/ISO_ImplicitModeling/final.md

SHA256: 62ff4147f00f0b832f2c4e81a13698efb1df5e603283a301ca1cc4ddbb953cd0

# A surface found by looking

<!-- @implicit_surface_modeling -->

Must a surface exist as a triangle mesh before you can see it?

Move around the rounded, changing form and inspect a smooth join between lobes. Compare its silhouette with the metaball specimen in the preceding room. Both can look like a continuous body assembled from influences, but their images do not establish that the same calculation produced them.

Keep one rounded join in view as you change position and watch the silhouette and shading change together. The image responds to the viewing direction, yet that alone cannot tell you whether a detailed collision surface exists there. Compare this observation with the earlier wireframe specimen, where small polygon boundaries supplied direct evidence of one representation. Here the smooth image leaves that representation question open until the rendering method is explained. Looking carefully can identify the evidence you have and the evidence a particular kind of display does not supply.

Here, each sphere contributes a signed distance description. A smooth minimum combines those distances, rounding the joins between their regions. That differs from adding the inverse-square influences of the previous specimen. Similar-looking blends can arise from different field definitions.

The display also takes a different route from field to image. For each viewing ray, a shader repeatedly queries the distance-like field and advances towards a possible boundary. When it reaches a sufficiently small value, it shades a surface point. The box used to host the shader does not become the detailed boundary of the visible body.

Earlier rooms sampled a lattice, selected local cases and assembled triangles. This encounter queries the field from the viewer's direction instead. It makes the separation between a geometric description and one way of displaying that description especially clear.

The distinction has practical limits. The ray search stops after a bounded number of steps and distance, and its hit test has a finite tolerance. A visible boundary is also not automatically collision geometry. Seeing a smooth enclosure does not prove that another object, or your hand, can meet that enclosure physically.

A useful extension would show the same distance field through this shader and through a marching-cubes mesh at two resolutions. Compare silhouettes and the geometry available for contact, keeping the underlying description fixed.

<!-- @ -->

The next room turns a description into a building-like body. Its graph will specify intended connections, while its extracted shell must make those connections into passages a visitor can actually use.



## ISO_RhizomeBody

Source: commons/maps/ISO_RhizomeBody/final.md

SHA256: 4e92761846c77a2bbae6e6e0635c7c06243f369d74cd982725859867f781e624

# A connection has to fit a body

<!-- @rhizome_inside -->

Can you return by a route different from the one you arrived along?

Identify an entrance to the rhizome body and trace a possible loop through its visible chambers. Where the passages are accessible, compare a return route with your approach. At each junction, look for evidence that two openings lead to distinct routes rather than different views of the same recess.

At a junction, identify the route you arrived along before choosing another opening. That simple reference helps distinguish a new route from a return that merely looks unfamiliar from the opposite direction. If you can complete a loop, compare the sequence of junctions rather than only the length of the walk. If you cannot establish a loop from accessible passages, record the point where the route became uncertain. A planned cycle and a demonstrated return are different kinds of evidence, and the comparison needs to retain that difference.

The plan begins as chamber positions and connections. A connecting tree joins the chamber graph, and additional edges introduce cycles. The generator checks that the graph is connected and includes more than a single tree's routes.

That graph is then given spatial form. Rounded chamber fields and capsule-like passages are blended together. A shell operation gives the boundary wall thickness, entrances are cut through it, and the resulting field is extracted into mesh and collision chunks.

The preceding room separated a visible field from collision geometry. Here the aim includes a body that can enclose a visitor, so the translation from intended connection to usable passage becomes part of the lesson. A line between two chamber centres describes an intention; its width, bends and joins determine what that intention permits in space.

Graph connectivity alone cannot certify access. Blending can merge features unexpectedly, a narrow passage can defeat an otherwise valid connection, and a collider can differ from what a view suggests. The loop you identify in the plan needs to be checked against the route available to a particular body.

A useful extension would display the connection graph beside a record of a visitor's actual route. Keep the graph fixed while changing one passage width. Then ask which mathematical connections remained and which practical choices changed.

<!-- @ -->

This closes the sequence with a task that needs both description and experience. The next room names operations such as union, intersection and difference. You have already met their consequences in joined chambers, wall shells and cut entrances; now those operations can become explicit tools for composing space.



# boolean_surfaces

Declared order: Boolean_Verbs → Boolean_Gallery → Boolean_Works


## Boolean_Verbs

Source: commons/maps/Boolean_Verbs/final.md

SHA256: f6029c352fd8965410788bef510863cdfe08ef4e0c7708ae29df46981ba28cf3

Three objects on one line down the middle of the room, and the floor rises to either side of you twice on the way, so each one gets a bay to itself without ever being hidden from the next.

They are the same two solids every time. A box and a sphere, one offset from the other, and nothing else changes down the whole length of the hall — not the size, not the spacing, not the material. What changes is a single word set on the sphere, and that word decides whether you are looking at one thing, at the part two things had in common, or at a hole. This room is the argument that the word is doing more work than the shapes.

## What a solid is here

Before the verbs, the thing they operate on. In this engine a solid is not a lump of material with an inside. It is a surface, and a rule for asking whether a point is on one side of it. Nothing is stored in the middle. The middle is an agreement between two systems — the renderer, which will not draw what faces away from you, and the physics, which will refuse to let you pass — and as long as the two agree, you experience an interior.

This matters because it means none of the three verbs can remove anything. There is nothing in there to remove. What they can do is redraw the boundary so that the same test gives different answers. Every operation in this hall is an operation on a *skin*, and every "inside" you meet is a promise about a region that was never filled in.

## Joining is not stacking

<!-- @csg_union_demo -->

```gdscript
# csg_union_demo.gd:59 — what this room is not
#   blend and the ladder is a continuum. CSG union has no k: it fuses absolutely
#   at first contact, so here `necked` is a CREASE with a discontinuous normal and
#   the ladder is a sequence of topological events. Same four states, two
#   ontologies of joining.
```

Walk to the first body and watch the seam. Two solids meet, and the surfaces where they met are gone — not hidden, not coincident, gone, replaced by one new closed surface that neither of them had before the operation ran.

The comment above is the artifact talking about its own cousins in the metaball chapter, and it is the most important sentence in this hall. Over there, a union takes a parameter `k`, and inside a band of width `k` the two fields blend: there is a genuine *partly*, a state that is neither two nor one. Here there is no `k`. The solids are two, and then at one floating-point value of the offset they are one, and there is no frame in between. The ladder is not a gradient. It is a sequence of events.

Same four states, two ontologies of joining. That is the artifact's phrase, not mine, and it is the whole chapter in six words.

Which makes the first rung of its own ladder awkward. The axis `fusion` runs `distinct, necked, lobed, single`, and at `distinct` the two primitives do not touch at all. The operator still runs. It contributes nothing — the output set is exactly the input set, two solids sitting near each other under a union that has no work to do. The artifact's stated desire is *to show that joining is not stacking*, and a quarter of its primary axis is a stack. The file is honest about it in the only place it can be, a comment at line 42: `TWO DISJOINT SOLIDS, still under OPERATION_UNION`.

## The interior was never there

<!-- @csg_intersection_demo -->

```gdscript
# csg_intersection_demo.gd:341 — the instrument, which is not the object
if dx * dx + dy * dy + dz * dz <= r2:
```

The second body keeps only what both solids claimed. Set the offset far enough and it keeps nothing, and nothing is a lawful answer: the operation succeeded, and the result is empty. It is the one verb whose correct output can be no output.

Standing next to it, on three of its four settings, is a number — the volume of A, of B, and of the two together, printed to three decimals. The artifact calls this measuring itself, and says so: *All three are measured by the SAME instrument on purpose*.

They are not measured by the same instrument as the object. That line above is the measurement: an analytic sphere, a point tested against a radius, forty-eight cubed samples of a perfect mathematical ball. The thing on the table is a `CSGSphere3D` whose tessellation is never set, so it renders at Godot's default twelve segments by six rings — a faceted approximation. And on the setting that shows you what was lost, the ghosts of the discarded material are built at twenty-four by twelve, smoother than the sphere that cut them.

So there are three spheres in this exhibit. The one you see, the one that did the cutting, and the one the number is about, and no two of them are the same shape. The instrument is honest, the object is honest, and they are describing different things — which is not a bug so much as the clearest possible demonstration of what a boundary representation is. The sphere on the plinth has no radius. It has twelve segments and six rings, and *radius* is a story told about them.

## A face neither of them brought

<!-- @csg_difference_demo -->

```gdscript
# csg_difference_demo.gd:236 — the cut, and then the skin
csg_sphere.operation = CSGShape3D.OPERATION_SUBTRACTION
_root_csg.add_child(csg_sphere)
var mat := StandardMaterial3D.new()
mat.albedo_color = body_color
_root_csg.material_override = mat
```

Push the sphere into the box and a face appears that neither solid brought with it. It is the sphere's shape, turned inside out, and it is wearing the box's material — because look at the last line: the material is set once, on the root of the whole operation. There is one skin. There was only ever one skin to give it.

That is not a shortcut in the code. It is what a boundary model leaves you no choice about. The moment you carve, you need a surface for an inside that was never stored, and the only surface available is the outside, relabelled. The cavity wall is not revealed by the cut. It is manufactured at the instant of the cut, out of the material of the thing being cut, and assigned to a solid that did not make it.

Of the three verbs this is the one that shows the mechanism plainly, and it is also the one the heavy hall cannot leave alone: subtraction is the operation this whole chapter keeps returning to, because it is the one where the invention is impossible to hide.

## The set is closed

<!-- @the_argument_of_solids -->

```gdscript
# the_argument_of_solids.gd:130 — the label it hangs in the middle of the room
_tag(Vector3(-0.3, 0.94, -0.05), "the three verbs", "an enum on one property - the set is closed")
```

At the far end, after all three, a bench of small verdicts with captions. It rebuilds the three results from scratch at its own scale so you can read them side by side, and it hangs the line above over the middle of them: three verbs, an enum on one property, the set is closed.

Five lines further down the file it builds a fourth thing the enum cannot name. Its helper for making a verdict takes the operation as a parameter but fixes the operand order — box first, sphere second — so B minus A cannot go through it, and the file hand-rolls a duplicate combiner with the two children swapped to get the picture it wants.

The set is closed, and the closure is a property of the enum, not of the argument. Difference is not commutative; the grammar has one slot for the verb and no slot for the order; so the artifact that exists to say the vocabulary is complete has to step outside the vocabulary to finish its own sentence.

You can count the preference in the file. `OPERATION_UNION` appears once. `OPERATION_INTERSECTION` twice. `OPERATION_SUBTRACTION` six times.

## What the grammar cannot say

Three verbs, and each one turned out to be an argument about the boundary rather than about the solids. Union deletes a surface. Intersection reveals there was never anything behind it. Difference invents one and dresses it in somebody else's skin.

And the foreclosure is the same in all three: the predicate is a yes or a no. There is no `k`. A point is in or it is out, two solids are two or they are one, and the transition between those states does not occupy any time or any space — it happens between one float and the next. Everything this chapter can say about relation, it has to say in a vocabulary with no word for *partly*, no word for *becoming*, and no way to hold a thing that belongs to two sets at once except by making a third set and throwing the question away.

The room next door is where you find out that even the four settings on each of these dials are a claim somebody published, and that the published claim and the object do not always agree.



## Boolean_Gallery

Source: commons/maps/Boolean_Gallery/final.md

SHA256: c99174be04428be6ffad757ad5592cb1fcfa8cca37fd93f84370633d0f3644e3

Twenty-four objects in six rows across a wide room, and eighteen of them are things this museum has never shown.

Every artifact in the boolean chapter is a family. Each one declares an axis — a named dial with four settings — and every placement anywhere else in the building shows you exactly one of those settings, the one it shipped with. This hall is the only place the other three stand up. One artifact per band, its four values laid across the room, two on your left and two on your right with the walking lane between them, so you meet the family two at a time and have to cross the floor to finish the sentence.

The six you have already met are here too, one per band, and in five of the six they are the first thing you come to on the left. That is a convention rather than an accident: the registry lists a family's values with the default first, and this hall was laid out from the registry. So each row starts with the object as you know it and then shows you what else it was willing to be.

## A variant is a claim somebody published

The four settings are not in the object. They are in a file. Each artifact's code holds a list of the values it will accept, and the registry — `commons/artifacts/registry/boolean_surfaces.json` and its neighbours — holds a second list, which is what every tool in this project reads: the catalogue builder, the sweep, the deck, the audit. The object obeys the first list. The museum, the gallery pages and this room are built from the second.

So a band in this hall is a published claim about an object, standing next to the object. That is a rare arrangement, and it makes the room usable for something other than looking: you can check.

Three of the six bands here disagree with their own code about what order the ladder goes in. Two agree exactly. One agrees and then checks itself at runtime, which no other artifact in the chapter does.

## The band that agrees

<!-- @csg_difference_demo -->

```gdscript
# csg_difference_demo.gd:73
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]
```

Four readings of one cut. At `outcome` you get the answer and nothing else, a box with a bite out of it. At `trace` the removed material comes back as a ghost, occupying the space it was taken from. At `operands` both original solids return, transparent, so you can see the box and the sphere that were consumed. At `expression` a labelled rod names the operation out loud.

The registry declares those four words in that order, and so does the code, and so does the second axis. This is the only band in the room where the published claim and the object match on both dials, and it is worth standing in front of because it shows what the ladder is *for*: it is not four decorations, it is one operation shown at four degrees of disclosure. The object gets progressively less confident about its own result as you walk right.

There is one seam even here, and it is small and revealing. The dial that positions the cut names only two of its four settings in the code that reads it; `centred` — the one the artifact advertises as producing a clean internal void — arrives through the wildcard. It is not a rung. It is what happens when nothing matches.

## The ladder, published out of order

<!-- @csg_union_demo -->

```gdscript
# csg_union_demo.gd:119 — the code's ladder
const FUSIONS: PackedStringArray = ["distinct", "necked", "lobed", "single"]
```

In the code those four are monotonic. They are four multiples of one offset, running down: far apart, nearly touching, overlapping, concentric. Walk them in that order and you watch two things become one, in four steps, with the topology changing under you.

Walk this band left to right and you get `lobed, distinct, necked, single` — the registry's order, which is the order this hall was built from, and which starts you two-thirds of the way up the ladder, sends you back to the bottom, then part way up again, then to the top. The sequence is the same four states. The *argument* is gone, because the argument was the monotonicity.

The registry did not do this carelessly; the entry says the order is the sweep's tile order, default leftmost. But the disagreement has consequences past this room: a third file, `fusion_ladder.json`, declares the ladder in the code's order and states that it took that order character for character from `csg_union_demo.gd:128`. So one artifact cites this object's code as canonical while the object's own registry entry publishes something else, and both are read by tools.

## A rung that is only a name

<!-- @csg_intersection_demo -->

```gdscript
# csg_intersection_demo.gd:234 — three of the four are here
match consensus:
    "unanimous": ...
    "narrow": ...
    "token": ...
    _: ...
```

The same displacement, one band down. `consensus` asks how much has to be shared before anything survives, and the four values run from complete agreement to a token overlap.

`broad` is not in the match. It reaches its position through the wildcard, which means it is not a defined rung at all — it is the label the artifact wears when nothing matched. The value exists in both lists, in the code and in the registry, and in neither of them does it correspond to a line that says what it is. It is the name of the default, promoted to a name.

And it is the one the registry puts first, so this band opens on it.

## Four degrees of removal, read from somewhere else

<!-- @subtraction_suite -->

```gdscript
# subtraction_suite.gd:162
## The vocabulary and the ratios, read from the family rather than retyped.
var _breach_table: Dictionary = FONTANA_SOURCE.BREACH
```

Here is the counter-example, and the hall needs one. `breach` asks how far a removal can go before the thing is gone, and its four rungs — pierced, opened, severed, husk — are not four numbers in this file. They are read out of `fontana_puncture.gd`, another artifact entirely, which holds them as ratios of the body's own size: 0.54, 0.68, 0.74, 0.80. The enum, the table and the registry agree on all four words, in the same order.

The bench makes an argument out of that: because the ratios are read rather than retyped, they cannot drift. Which is true of every one of them except the one the file retypes fifty lines later as a literal `0.68`, inside the function whose whole purpose is the anti-drift claim. One number, in the file that exists to say numbers do not need to be repeated.

## The degenerate case, painted

<!-- @coincident_face -->

```gdscript
# coincident_face.gd:257 — the coin toss
col = color_a if (i % 2 == 0) else color_b
```

This band is about what happens when two faces occupy the same plane and the depth test has no answer — the flicker every 3D artist has seen, where a surface tears into stripes of two materials because the comparison is a coin toss at every pixel.

The artifact contains no boolean operation and no z-fight. There is not one CSG node in the file; the four places the string "CSG" appears are all text on labels. The stripes are the line above: even bars one colour, odd bars the other, alternating by index. And they are drawn at an explicitly unambiguous depth, four millimetres in front of everything else, so the renderer is never asked the question the artifact is named after. It is a diagram of a failure, executed by a mechanism that cannot fail.

That is not a cheat, exactly — a picture of z-fighting that actually z-fights would be unphotographable and would look different on every machine. But it is worth knowing what you are looking at, because there *is* a real coincident face in this file and it is not the one on the wall: at the `coincident` setting the two rectangle fills are placed at the same depth, the same thickness, overlapping in x, and they genuinely contest. The artifact produced the thing it is about by accident, behind the drawing of it, and says nothing about it.

The band's other seam is the same one union has: code and registry disagree on order, this time by moving the failure state to the front. The registry declares it in its own note, so it is a known disagreement rather than a hidden one.

## The one that checks

<!-- @removal_room -->

```gdscript
# removal_room.gd:341 — reading its own hint string back out
func _check_vocabularies() -> void:
```

Three copies of one cut lattice, differing only in how the removed cells are recorded: not drawn at all, drawn full-size and pale, or shrunk to a fifth and left as a scar. The axis underneath asks which deletion rule made the hole — a cross, a middle third, a gasket, a figure.

Alone in this chapter, this artifact does not trust its own declaration. At runtime it pulls its exported enum's hint string back out of the property list and compares it, both directions, against the constant beside it and against the vocabulary of the upstream artifact it borrowed the registers from. Code, constant and registry agree, and the file makes sure of it every time it builds.

Which makes the error in it more interesting, not less. The header explains why the three copies stand side by side rather than stacked, and derives it from an arithmetic: a scar is 0.22 cubed of its ghost, about one percent. Four hundred lines later the same file says the upstream rule keeps the removed part's length and thins only the section, and implements it that way — which makes a scar 0.22 squared, nearly five percent, four and a half times bigger. The room is built correctly. The justification printed at the top of it is wrong, and it is wrong about the one artifact it names.

## What the room is for

Six bands. Two published exactly as the code has them, one of those checked at runtime. Three published in a different order from the ladder the code walks, one of which scrambles the argument the ladder existed to make. One that measures its own ratios from another file and then retypes one of them anyway. One that has no boolean operation in it at all.

None of that is damage. It is what happens when an object is also a claim about itself, maintained in two places by different hands at different times, and it is only visible from a room where the claim and the object are standing next to each other. Everywhere else in this museum you meet these objects at their default and have no way to know there was a ladder.

The other question this hall raises, it cannot answer: all six of these families were promoted for the still camera, one photograph per value, judged on whether the picture changed. What none of them has ever been asked is whether the *space* changes — whether a variant is something you could walk differently. The heavy hall is where that gets tested, and where it mostly fails.



## Boolean_Works

Source: commons/maps/Boolean_Works/final.md

SHA256: 59b3e5b0809ca20248f56157c5fdc97fe9279d742b17ead465f4826444eb0085

The room gets taller here, and the things in it stop being demonstrations. A workbench, a catalogue rack, a wall with a door cut through it, a five-metre block of rock with a tunnel bored out of the middle. These are the boolean operations at the size where they would have to be architecture, and the question this hall asks is the one the small rooms could not: when the negative gets big enough to stand in, can you stand in it?

You cannot. Not in any of them. That answer took eight bodies to arrive at, and it is the most useful thing in the chapter.

## The bench you cannot reach

<!-- @csg_compose_workbench -->

```gdscript
# csg_compose_workbench.gd:9 — the promise, in the file's own header
# stand at the bench, see all three operators side by side, pick one with the bracelet,
```

Three solids turning slowly above a table, each labelled with the operation that made it. The file calls itself a workbench, the registry sells it with the tag `catalyst_affordance`, and the header above says you pick one up with the bracelet.

There is no picking. Three hundred and fifty-eight lines and not one input handler, no interaction volume, no signal, no mention of the bracelet outside comments. The only thing that happens at runtime is that the presets rotate. And the geometry has already given it away before you try: the bench top is at 0.56 metres and the work is placed at 1.1, so the objects float just over half a metre above the surface they are supposedly on, out of reach, turning. The file half-admits it in a line called `needs` — *Missing: a live player-built composition surface beside the three fixed presets.*

Its dial is the interesting part. `algebra` has four settings, and one of them, `complete`, builds symmetric difference out of two nested combiners and labels it longhand as `(A ∪ B) − (A ∩ B)` — the artifact's own argument that XOR is derived rather than primitive, which is a real and good point about what an algebra holds versus what a tool exposes. The default is `triad`. Eleven placements exist in this museum and not one of them passes a config value. So XOR is in the repository and has never once been in the building.

## The two stations that were supposed to be identical

<!-- @subtraction_suite -->

```gdscript
# subtraction_suite.gd:254 — the one line that breaks the claim
art_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
```

One cube with a sphere taken out of it, built twice, side by side: once dressed as an art object and once as an instrument reading. The bench's stated result — its smallest and firmest, by its own account — is that these are the same object and *what differs between them is the furniture and the palette*.

Cull mode is neither. It is a property of the surface, and the operator's copy does not get it: that station keeps back-face culling, and at every setting past the first the void has already broken through the faces, so the mouths of the cavity are exactly where your eye goes in. One station renders its carved interior. The other deletes it at the moment you look inside. The claim that the difference is not in the object is undone by a line in the object.

Worth a count while you are here: the whole bench builds four CSG combiners and eighty-five plain meshes, sixty-eight of which are the catalogue tray beside it, which contains no boolean operation at all.

## Four of five are not booleans

<!-- @sphere_splitting_showcase -->

```gdscript
# sphere_splitting_showcase.gd:182 — the caption
_add_info_label(csg_sphere, "CSG CUTTING\nBoolean ops\nfor real cuts\n\nPieces: 1\nSplits: 0")
```

Five destructible spheres in a row with balls to throw at them, each shattering by a different algorithm. It stands in a boolean hall today for the first time, though it has been placed five times before in the forces chapter, which is where it comes from and where its registry entry still files it.

Four of the five contain no boolean operation. They are fracture algorithms — segmentation, planar cuts, physics shards — and only one of them reaches for CSG at all, which it uses for an *intersection*, baked offline, to mask a mesh. The caption above sits on that one. The room's name claims all five.

None of them is seeded, either: the cut planes are three unseeded random floats, so two placements of this token are two different objects the instant anything is thrown. It is the most honest thing in the hall about what a boolean is *for* — a tool used once, offline, to make a mesh — and it is filed as the opposite.

## The hole that was never made

<!-- @recursive_boolean_cube -->

```gdscript
# recursive_boolean_cube.gd:118 — the whole mechanism
if zeros >= 2:
    continue
```

A Menger sponge. A cube with square holes bored through it, and smaller holes in what remains, recursively. Of everything in this hall it looks the most like subtraction, and it is the hinge of the entire chapter.

It performs no boolean operation. There is no CSG node anywhere in the hundred and fifty-eight lines, no subtraction operator, nothing but boxes and materials. The holes come from the two lines above: walking the twenty-seven cells of each subdivision, if a cell is on the axial cross, the loop does not build it. Nothing is removed. A cube is declined.

The file's own comment calls this *boolean-like subtraction through recursive geometry*, and the registry, which files it under procedural generation and tags it `procedural`, never uses the word boolean at all. Both are more accurate than the room it now stands in.

And it is the only body here that is fully reproducible — no random number in the file, two placements byte-identical — which is a small joke at the chapter's expense: the artifact that does not do the thing is the one that does it the same way twice.

Take the mechanism seriously and it reframes everything upstream. A boundary model has no interior, so nothing in it can be removed; what looks like removal is always a redrawing of the skin. This artifact skips even that. It gets the appearance of a hole by never putting anything there and then narrating the absence as a cut. Which is not a lesser version of what the verbs do. It is the same thing with the arithmetic taken out.

## Equals room

<!-- @csg_architecture_cavity -->

```gdscript
# csg_architecture_cavity.gd:20 and :52 — thirty-two lines apart
# truth: Every architectural cavity is a difference. A room is a wall that has been subtracted from.
...
#   operator and never delivers the truth line: a wall has no interior.
```

A wall, three and a half metres of it, with a door and an opening and a bitten arch cut through. Floating above it in large text: `wall − (door + porthole + window) = room`.

It is one wall. It has been one wall at all twelve of its placements, because the setting that would add returning runs defaults to `none` and no map in the project sets it otherwise. The two lines above are both in the file, thirty-two apart, and the second one is right: a wall has no interior. One difference makes a hole, not an inside. You read the payoff from outside, which is the only place there is.

Then walk into it. You will not be stopped. There is no collision anywhere in this artifact — no static body, no shape, and the CSG root's own collision flag is never set. This is not something the engine could not do; a tunnel in the alternative-geometries chapter turns exactly that flag on, one line, and you can walk through it. Here the doorway and the wall are the same to your body. The one architectural distinction the object exists to make — that a cut in a solid produces somewhere you can be — is the distinction it does not implement.

Even the porthole is not a hole. Its centre is set 1.4 metres up on a wall whose half-height is 1.3, so it is a scallop bitten out of the top edge.

## Walk the hollow

<!-- @sdf_cavern_room -->

```gdscript
# sdf_cavern_room.gd:55 — the only text in the world
_billboard_label("CARVE THE FUNCTION, WALK THE HOLLOW", Vector3(0.0, 3.6, 0.0), 28, ...)
```

Five metres of rock rendered as a crust of nearly five thousand small boxes, with five spheres subtracted out of the middle of it to make a cave. It is the most beautiful object in the chapter and the sign over it is the plainest instruction in the building.

There is no collider, and this time it would not help. The block is lifted so its underside sits fifteen centimetres off the floor, and the lowest carved air anywhere inside it is 1.2 metres up — more than a metre of unbroken rock between the ground you are standing on and the bottom of the hollow. The tunnel's floor is above your head. There is a floor in this artifact, a seven-metre plate, and it belongs to the tray, not the cave; it also sways, because the whole node rocks gently on its vertical axis and takes the ground with it.

So it is a model of a cavern on a table. Which would be fine — most of this museum is models on tables — except that the verb in its own truth line is the one operation it does not implement, and it is the artifact in the entire chapter that is actually shaped like an interior. It carries no declared axis at all, while the word `interior` has been borrowed from the wall next door by three other registry entries as the term for *whether a solid encloses a void you could occupy*.

## Seventy-five things that look grabbable

<!-- @booleanvariations -->

```gdscript
# booleanvariations.gd:632 — after wrapping each solid in a VR grab cube
grab_cube.set_script(stability_script)
```

A three-by-five-by-five rack of boolean combinations, seventy-five of them, each one wrapped in the project's standard grab cube so it can be picked up. Then the line above replaces that cube's script with a fourteen-line stub, and the pickable behaviour is gone. The highlight ring is removed first, because it would throw errors against the stub. Seventy-five objects built to be handled, presented as handleable, inert.

Two more things about it that are visible if you look. It clears its own children on the first frame with an unconditional loop, and its scene file's camera and its only light are among them, so standalone it goes black. And of the twenty-five distinct variations it advertises, thirteen are marked `# Placeholder` in the source and call another variation's builder, leaving eleven.

## The degenerate case, kept

<!-- @coincident_face -->

At the back wall, the flat plate about two faces in the same plane — the failure mode, the one condition under which the whole boolean grammar has no answer. The gallery next door explains what it is and how it is drawn. It is here as well, at the end of the heavy hall, because it is the only object in the chapter that takes the position that a case where the machinery breaks is worth an exhibit rather than a bug report.

## What the physics never turned up for

An interior, in this engine, is an agreement between two systems: the renderer will not draw the surfaces facing away from you, and the physics will not let you through. Hold both and you have an inside. Drop either and you have a picture of one.

In this hall the physics never arrives. Twelve of the chapter's thirteen artifacts contain no collision construct of any kind — no static body, no shape, no collision flag set on a CSG root. The thirteenth has exactly one: a two-metre grab volume on objects scaled to a tenth of that, bolted to a script the same file throws away eleven lines later. `= room` hangs over a wall you pass through. `WALK THE HOLLOW` hangs over a metre of rock. The workbench floats half a metre above the workbench. Seventy-five objects offer themselves to your hand and are not there.

The project has already written this down, in a place nobody reads. Its own interaction probe filed both the wall and the cavern under `"verdict": "no affordance"` — zero controls, zero grabbables, zero wired. And the still camera reached the same conclusion from the other direction without anyone noticing what it had said: the sweep that grades whether a dial changes the picture rates the wall's `interior` setting at 4.372 percent of pixels for the step from one wall to a four-walled room. That step is the artifact's entire argument, the rung its own source calls *the first rung on which the player is INSIDE*, and it registers as a rounding error — because a camera standing outside a room cannot see the difference between having an inside and not having one. It sees three more slabs, edge-on.

Which is the last thing this chapter has to teach, and the most uncomfortable. The instrument that decides whether a variant is worth keeping is a photograph taken from outside. An interior is precisely the claim that cannot be photographed from outside. So the one property this whole chapter is about is the one property the apparatus is built to miss.

That is the chapter's dark spot, and it is worth being precise about which kind it is. In the small room the missing interior is generative: because a boundary model stores no inside, difference has to *invent* the cavity wall out of the outside, and that invention is the best idea in the chapter. Here the same absence has gone sterile. The claim got bigger — from *this surface is manufactured* to *this is a room* — and nothing underneath it grew to match. The negative was supposed to become inhabitable at this scale. It became a sign saying so.

Which leaves the honest version of what these three halls demonstrate, and it is not the one the labels promise. A solid is a lie told by its skin, and so is its hole. The grammar that carves has no word for *partly*, no word for *becoming*, and nothing to put inside the thing it cuts. Every absence in this chapter is performed rather than found — by inversion, by omission, by parity, by a caption. What you can walk through, you were always going to walk through.



# swarmintelligence

Declared order: SwarmIntelligence_PhysarumColony → SwarmIntelligence_FlowFields → SwarmIntelligence_Boids_Algorithm → SwarmIntelligence_Agent_Based_Modeling_ABM → SwarmIntelligence_Ant_Colony_Optimization → SwarmIntelligence_Particle_Swarm_Optimization → SwarmIntelligence_Swarm_Intelligence_Algorithms

Museum map-authored order differs: SwarmIntelligence_PhysarumColony → SwarmIntelligence_FlowFields → SwarmIntelligence_Boids_Algorithm → SwarmIntelligence_Agent_Based_Modeling_ABM → SwarmIntelligence_Particle_Swarm_Optimization. Treat this as route drift to inspect, not an editorial recommendation.


## SwarmIntelligence_PhysarumColony

Source: commons/maps/SwarmIntelligence_PhysarumColony/final.md

SHA256: 2a527b6831544109fd080fbcee3dfd9b70f975bc5de68d6d905ac7bd2083ec60

# Remembering in the ground

Can a path remember where to grow when no individual carries a map?

<!-- @PhysarumColony -->

Choose one bright connection in the colony and follow it with your eyes. Stay with it when the arrangement of anchors changes. The display moves between a triad, a ring, a pair and scattered positions, changing its arrangement about every twenty seconds. Look for a trace that outlasts the arrangement that helped produce it.

Some paths brighten as they are revisited. Others fade. The ground therefore shows more than where an agent happens to be now: it retains something of earlier movement. A newcomer can encounter a trace left by an agent it never met.

Try following a junction rather than an entire path. Several small movements can enter and leave the same neighbourhood, while the visible trace changes more slowly. You may lose track of an individual agent and still recognise the connection. That difference in timescale is part of what makes the ground useful as memory: the record can be encountered after the event, although decay means the record will not remain equally legible indefinitely.

Each simulated agent samples the field ahead and to either side, turns in response, and deposits more trail. The field also spreads between neighbouring cells and decays. Repetition strengthens a route; spreading broadens it; decay prevents every previous visit remaining equally important forever. The anchors contribute signals too, so the network is made by agents interacting with a deliberately prepared environment.

This is environmental memory. There is no little map hidden inside the moving dots. Information persists outside them, in a medium that changes what later movements are likely to do. The earlier emergence rooms asked how repeated local updates produce a pattern. Here that pattern becomes an input to subsequent updates.

A bright, economical-looking network does not establish that the shortest possible network has been found. The places worth connecting have already been chosen, and a biological name does not make these simulated agents an experimental account of an organism.

For a second observation, attend to the route that is fading rather than the route becoming strongest. How long does an abandoned possibility remain available? Imagine an anchor that could be moved by a visitor: the useful experiment would compare adaptation with the persistence of old traces. That control is a proposal for this room’s development.

<!-- @ -->

The next room supplies directions from outside the population. Similar collective motion will have a different source.



## SwarmIntelligence_FlowFields

Source: commons/maps/SwarmIntelligence_FlowFields/final.md

SHA256: 30e9e9ed291ea280b0a5f220e6b6eeeba0a140016e39ec1a4143538af6af947b

# Directions already in the ground

If hundreds of agents turn together, must they be watching one another?

<!-- @FlowFieldMain -->

Find an arrow near an agent and predict which way that agent will turn. Follow the automatic tour as an open field gains obstacles, then compare those scenes with wind and noise. Give each arrangement time: the tour changes roughly every ten seconds and eventually remains with the noise field.

The arrows offer directions throughout the space. Many agents can follow the same organisation without consulting one another. Around an obstacle, a useful direction may initially point away from the destination you can see, because the direct route is blocked.

During an obstacle scene, compare two agents that arrive at the same patch at different moments. Their immediate histories can differ while the arrow they encounter gives the same local recommendation. Then compare two nearby arrows on opposite sides of an obstacle. Nearness alone need not produce the same direction. This gives you two small checks on your explanation: the field organises movement by position, and the obstacle matters through its effect on that organisation.

In the route-finding scenes, the model first spreads costs outward from a target through a grid. It then assigns directions towards neighbouring cells with lower costs. Each moving agent reads the direction at its present position and steers towards it. The expensive task of organising a route is shared through the field; it is not solved afresh by every agent at every step.

Wind makes the distinction sharper. A field can give a direction without giving a destination. Noise supplies local variation without the same coherent route. Where the direction is zero, the agents have a wandering behaviour rather than a magical knowledge of where to go.

Physarum’s agents helped write the field they subsequently sensed. These agents receive a field prepared for them. From far away, both populations can look collectively intelligent. Looking at the relation between agent and field tells us which explanation the movement supports.

The cost map also contains decisions: which cells are blocked, which routes are costly, and what destination matters. Shared navigation can reproduce those decisions very efficiently. Efficiency alone cannot tell us whether every traveller can use the permitted route.

Try following one arrow that surprises you instead of the largest stream of agents. For a future version, hiding the arrows while holding the scene fixed would test how easily we mistake shared infrastructure for spontaneous agreement.

<!-- @ -->

Boids will remove that supplied direction and let nearby agents become one another’s moving reference.



## SwarmIntelligence_Boids_Algorithm

Source: commons/maps/SwarmIntelligence_Boids_Algorithm/final.md

SHA256: ef27362697ecd55e5d7a7db50cfd6ae5ae59a669c7d0047ac2a33fc7fe7a9360

# Three ways to be near

Which relationship is making this flock hold together?

<!-- @flocking_controls -->

Find the highlighted boid and its coloured arrows. Keep the other controls steady while moving SEP. Watch both the arrow near your chosen agent and the shape of the whole flock. Return to a comparable setting, then try ALIGN or COH. One change at a time makes it easier to connect a local response with the population’s movement.

The red arrow shows separation, the attempt to avoid crowding nearby agents. The blue arrow shows alignment with nearby headings. The green arrow shows cohesion towards the local group’s centre. These requests can disagree: an agent may need to move away from a close neighbour while also turning towards the larger group.

The three arrows need not all point along the boid’s eventual movement. Choose an instant when two contributions disagree and describe the disagreement in ordinary terms: too close here, group centre there, neighbours heading elsewhere. After changing one weight, inspect whether that contribution becomes more prominent before looking for a dramatic change in the whole flock. A small local change can be real even when the population remains recognisably flock-like throughout your observation.

The simulation combines the requests as weighted steering contributions. A slider changes the relative influence of one contribution; it does not issue an instruction to the whole flock. Each boid repeats its own calculation using the neighbours within its perception radius. The large moving shape is the result of those many calculations meeting.

Now change RADIUS while keeping the three weights steady. The same numerical rule can produce a different relationship when a different set of neighbours enters the calculation. Before asking what the flock wants, ask who each agent is able to perceive. Watch the edges too: positions wrap around the display’s bounds, so leaving one side does not mean leaving the population.

Alignment is not consent, and cohesion is not a complete account of belonging. These agents have no way to refuse a relation, remember harm or ask another agent for space. The model makes a few geometrical relationships legible because it omits many other kinds.

Try allowing separation to dominate for a while. Instead of judging every dispersed flock as failed, ask what the extra distance enables you to see. A future experiment could give different agents different perception ranges and examine whose movement sets the group’s direction.

<!-- @ -->

The next room broadens the model: an agent can have an internal state, and the environment can remember what it did.



## SwarmIntelligence_Agent_Based_Modeling_ABM

Source: commons/maps/SwarmIntelligence_Agent_Based_Modeling_ABM/final.md

SHA256: 6ec78d1a6bb4bcad3b145bc53ee7b630a48326c2d47b093bbc017b5205e73277

# Change a rule, watch a population

How much of a collective pattern changes when one local rule changes?

<!-- @ant_colony_optimization -->

Watch the colony long enough to recognise a trail. Raise EVAPORATE and see whether that trail persists between visits. Use RESET before making a second comparison. Keep ANTS steady at first, so a change in the population does not obscure the effect of changing its shared memory.

The trail image is a record of deposits that are also disappearing. With faster evaporation, continued traffic matters more to keeping a route visible. A line that looks like a stable piece of the environment is actually being maintained by repeated events.

A useful comparison separates a trail’s width from its persistence. A busy route can spread across several cells while individual marks still disappear quickly. A narrower route can remain visible between relatively infrequent visits. Try describing both qualities before judging which colony is more organised. The heatmap lets many overlapping events become one visible pattern, so two similar-looking patches need not have been maintained by the same number of agents or the same timing of visits.

This is an agent-based model: individuals carry state and follow rules, while their interactions produce a population-level picture. Here those rules include movement, sensing, depositing traces and responding to food. The field is shared state. Changing evaporation changes what every agent can encounter without directly changing every agent’s position.

Next vary ANTS. This control changes the number of agents and respawns them, so treat it as a new population rather than a continuous observation of the old individuals. Compare fewer agents leaving more persistent marks with more agents leaving shorter-lived marks. They may produce superficially similar pictures for different reasons.

The MODE control offers three behaviours within this model family. It does not turn the room into a language for inventing arbitrary agents. A useful comparison still begins by naming exactly which rule or condition has changed.

An agent can be a convenient unit without being an adequate model of a person. These agents inherit the same limited sensory world, and the shared grid decides which traces can count. A simulation of people would need an argument for those omissions, not simply a change of labels from ants to citizens.

As a proposed extension, give two groups different sensing capacities while keeping the environment shared. Would a path that looks equally available from above remain equally available from within each agent’s world?

<!-- @ -->

The next colony makes one relation particularly clear: information about home and food travels in different channels.



## SwarmIntelligence_Ant_Colony_Optimization

Source: commons/maps/SwarmIntelligence_Ant_Colony_Optimization/final.md

SHA256: d26e1d5319847d4442e2703636bafaa8fed4985d642837109e3d0302ccbb3ceb

# Directions left for someone else

How can an ant leave useful directions without knowing the whole journey?

<!-- @AntColonyV2 -->

Watch an ant move out from home towards one of the food anchors. Then follow returning traffic along the same general connection. Look for a place where a fresh trail meets a fading one. The trace can stay present after the ant that deposited it has passed.

The two journeys use different information. A foraging ant seeks the food trail while leaving a home trail. A returning ant seeks the home trail while leaving a food trail. What one traveller deposits can therefore help another traveller going the other way.

Attend to a traveller near a destination, where the outward and returning journeys meet. A destination is more than a bright place to reach: arriving there changes what information that ant will seek and leave on the next stretch. If you lose the individual in the traffic, follow the two directions of travel instead. The relation still makes sense at the route level, while the state change belongs to individual arrivals.

Each ant samples three nearby directions and turns according to the signals it encounters. Reaching a destination changes its state and reverses the relationship between what it seeks and what it leaves. Its trail energy diminishes along the journey and is renewed at home or food. The ground holds local numerical traces rather than an explicit itinerary.

This coordination through a changed environment is called stigmergy. It lets individual acts affect later acts without requiring a central announcer. The previous room separated individual rules from the population picture; here the trail makes the connection between them visible.

Compare the two food directions instead of assuming the most prominent path tells the whole story. Which connection currently receives more reinforcement? Which parts of the field preserve possibilities that are receiving less traffic? A route’s visibility depends partly on its history of use.

This is a foraging simulation. Its title invites a connection to ant colony optimisation, but an attractive trail is not a proof that a shortest route or an optimal travelling-salesman tour has been found. Such a claim would require a specified problem, an objective and a comparison with alternatives.

Moving a food source would be a useful future interaction: a group could predict how quickly the colony would adapt and how strongly yesterday’s route would persist. For now, the placed scene offers fixed food directions to observe.

<!-- @ -->

Particle swarms next move memory into each agent’s best position and a best position shared by the population.



## SwarmIntelligence_Particle_Swarm_Optimization

Source: commons/maps/SwarmIntelligence_Particle_Swarm_Optimization/final.md

SHA256: 89a97dacc128ad10474efd60f43f028b2639b9dacbbcfd5bc812107646b15ab4

# Better according to which score?

When a swarm improves, who decided what better means?

<!-- @fitness_landscape_politics -->

Watch the population under CONVERGE, then choose SPREAD. Keep INERTIA unchanged while you compare the movement. Next try NOVELTY. Before reading these as success and failure, describe what each setting seems to reward.

CONVERGE rewards movement towards the centre. SPREAD rewards distance from it. NOVELTY rewards distance from positions retained in an archive. The same family of moving particles can therefore gather, disperse or seek unfamiliar territory because the scoring rule has changed.

Keep your attention on one region when you exchange CONVERGE for SPREAD. The region has not moved, but its value under the new objective has changed. Describe the difference as a change of reward before describing any particle as more capable. This also helps with a slow response: the visible position belongs to the current moment, while continuing velocity and remembered positions can still influence where the next update carries the particle.

Each particle remembers a position that scored well for it. The swarm also retains a shared best position. A velocity update combines continuing motion with pulls towards those personal and shared memories, using varying random contributions. INERTIA changes how strongly the existing movement carries into the next update.

“Best” is a relation between a position and an objective. It is not a property the particle discovers independently of the scoring rule. A position can be excellent under one button and poor under another. The ant colony’s traces remembered visits; these particles explicitly remember evaluations.

Spend longer with NOVELTY. Newness depends on what has been remembered, and this archive has a finite capacity. An apparently unexplored place can be unfamiliar to the stored record without being unfamiliar to the world. Every novelty measure needs an answer to the question “new relative to what?”

Now change INERTIA within one objective. Ask whether overshooting is always wasteful. Motion that delays settling can also carry a particle beyond a region it would otherwise keep revisiting. The consequences depend on the landscape and on what the score values.

An optimiser cannot settle a disagreement about what should be optimised. Rewarding dispersion here may be a productive alternative to rewarding concentration; it does not automatically make dispersion good in every social setting. A future comparison could display two conflicting scores together, keeping the compromise visible instead of hiding it inside one number.

<!-- @ -->

The capstone turns from declared objectives to quieter rules that keep an apparently self-organising system alive.



## SwarmIntelligence_Swarm_Intelligence_Algorithms

Source: commons/maps/SwarmIntelligence_Swarm_Intelligence_Algorithms/final.md

SHA256: 9706354bc60e7bfc9f4d24998b6eab48f4f32efbbbfc4b8a090e9a9190ddf290

# Who keeps the ecosystem going?

When a population survives, how can we tell what kept it alive?

<!-- @ecosystem_simulation -->

Choose either prey or predators and watch its count alongside its visible behaviour. Follow an encounter with food or another organism, then return to the population readout. A crowded scene can hide a falling population; a count can reveal a change that is difficult to follow one body at a time.

The organisms move, forage, encounter predators and reproduce. Traits can pass to offspring through a simplified combination and mutation process. These local events give you one explanation for changes in the population. Births, feeding and losses are happening at particular places, even when the readout reports only a total.

Try alternating your scale of attention. Spend a short interval following an encounter, then a similar interval watching the count. The encounter offers a candidate cause; the count reports an aggregate consequence without identifying its cause. If you cannot connect the two confidently, preserve that uncertainty. A useful observation might be “the prey count recovered while I watched this region”, rather than “this particular birth saved the population”. The smaller statement keeps the evidence available for comparison.

There is another explanation to keep alongside it. The model also contains balancing interventions. When prey become scarce, it can add more. It can weaken predators when they become too numerous relative to prey, and it can restore predators under specified conditions. The continuing ecosystem is therefore produced by local behaviour together with rules that watch population totals.

This distinction matters across the sequence. A flock followed neighbours; ants read traces; particles pursued remembered scores. Here the model includes a caretaker that operates at a different scale from its organisms. An overall pattern does not tell us which scale supplied the decisive action.

Watch for a population recovery, but resist assigning its cause from appearance alone. A rising count does not identify whether reproduction or replenishment produced the new bodies. A stronger future version would mark interventions when they occur, allowing you to compare a maintained population with one left to its local rules.

That comparison need not make intervention shameful. Care, repair and replenishment can be necessary. The question is whether they remain visible when someone describes the result as autonomous. A claim about self-organisation should name the support that makes continued organisation possible.

<!-- @ -->

Machine learning begins by asking what changes across generations. Carry this distinction with you: inherited traits, environmental rewards and the rules that keep an experiment running all shape what can survive.



# machinelearning

Declared order: ML_Evolution → ML_Gradient_Landscape → ML_Classification → ML_Neural_Networks → ML_Perception → ML_Sequence_Memory → ML_Generative → ML_Synthesis

Museum map-authored order differs: ML_Evolution → ML_Gradient_Landscape → ML_Classification → ML_Neural_Networks → ML_Perception → ML_Synthesis. Treat this as route drift to inspect, not an editorial recommendation.


## ML_Evolution

Source: commons/maps/ML_Evolution/final.md

SHA256: 1982cda825c0419b4f97e389dff9e3311d6d44d8f9e08d585b437c3b7c879ccc

# Survival without a finish line

If no judge ranks these bodies, does that mean nothing selects between them?

<!-- @non_teleological_evolution -->

Choose a moving body and watch where it travels. Compare a body covering fresh territory with one remaining near places already visited. Stay long enough to notice a new body appear or an existing one disappear, then compare that event with the population’s continuing motion.

The simulation lets bodies gain energy by visiting new cells. Energy also drains with time. A body with enough energy can reproduce, dividing its available energy and giving its offspring slightly altered traits such as size, speed and colour. There is no final shape on a pedestal that every descendant is trying to become.

Look for continuity as well as difference around a reproduction event. A new body can resemble its parent while beginning a different route, and a visible difference need not immediately alter survival. What matters is how a trait enters the subsequent encounters with the grid and its energy rewards. Keep the description in that order: inherited variation, changed behaviour if you can observe it, then a consequence for continued movement or reproduction.

The changes nevertheless have consequences. A trait that alters movement can alter access to the rewarded cells, and that can affect the opportunity to reproduce. The environment supplies a preference even without a separate leaderboard. Removing an explicit fitness ranking has not removed the conditions under which some lineages continue and others stop.

Follow the child as a new trajectory rather than as an improved copy. Mutation introduces variation; it does not know which variation will help. Nor does a crowded population establish that each surviving body is closer to a universal ideal. It tells you that these bodies have continued under this particular energy economy.

The ecosystem in the previous room combined local behaviour with balancing interventions. Here the lesson is to look carefully at the apparently ordinary rule that pays for survival. Rewarding visits to new cells makes movement into unfamiliar territory consequential before anyone announces an objective called exploration.

Imagine changing that rule so that revisiting a dependable place also provides energy. Which traits might become useful? That is a proposed comparison, not a control offered by the present encounter. It would test how much of the population’s story belongs to its environment.

<!-- @ -->

The gradient landscape next puts an objective in full view. Instead of inheriting a reward through survival, a moving point will be told exactly how its position is scored.



## ML_Gradient_Landscape

Source: commons/maps/ML_Gradient_Landscape/final.md

SHA256: 6795babe138f9416e8699971868293245c5772360551cd46a07479f8bff9c06a

# Three meanings of error

Can the same observations lead a learner downhill in different directions?

<!-- @loss_function_comparator -->

Find the moving point on each of the three landscapes. Each landscape scores a straight-line fit to the same set of observations. Keep OUTLIERS low for a first comparison, then raise it and reset. Look for a difference between the responses rather than asking which point arrives first.

The two horizontal coordinates represent the line’s slope and intercept. Height represents the error assigned to that candidate line. Moving across the surface therefore changes the proposed model, while moving down means improving the score under that particular definition of error.

Choose one candidate slope and intercept in your imagination and compare what the three surfaces would say about that same candidate. The candidate line is unchanged; only the rule assigning its height differs. This makes a useful distinction between moving within one landscape and comparing landscapes. An apparent hill on one surface is not a physical obstacle in the observations. It is a way the chosen error calculation rates a set of model parameters.

The squared-error surface punishes a large residual much more heavily than a small one. Huber loss is quadratic near zero and becomes linear for sufficiently large residuals. An unusual observation can therefore pull the two fitted lines differently. The outlier control helps make that difference visible while the basic task remains the same.

The third surface has a deliberately wavy error rule: a sine term is added to a quadratic term. Its label uses the word “adversarial”, but this exhibit is not training a generative adversarial network. It offers a rougher landscape on which local downhill movement can encounter a different arrangement of rises and hollows.

At each step the points estimate a gradient from nearby samples of the surface and move against it. Their allowed slope and intercept are bounded. A final position can therefore reflect the starting point, the local terrain and the allowed region as well as the underlying observations.

Return to an outlying observation in your imagination. Is it a measurement mistake, a rare event or a person whose case the majority fit neglects? The loss function cannot answer that question. Reducing its influence may be sensible in one situation and erase important evidence in another.

<!-- @ -->

The classification room will exchange a fitted line for groups. The same question remains: which differences does the chosen measure treat as important?



## ML_Classification

Source: commons/maps/ML_Classification/final.md

SHA256: 1f1fbee4a528691e9b37ad9429617be4b6d73f96fd34ad1f0e72cbe241a6d2e0

# A boundary that moves with its centre

Why can a point change groups even though the point itself has not moved?

<!-- @enhanced_kmeans -->

Pick a point near the boundary between two coloured groups and follow its colour as the display updates. Keep its position in view while watching the centres nearby. Predict which centre it will belong to after the next assignment.

The points are repeatedly assigned to their nearest centre. Each centre then moves to the mean position of the points assigned to it. Moving a centre changes where the next boundary will fall, so a stationary point can acquire a different group membership. Assignment and centre movement take turns reshaping one another.

Follow a centre during an update and identify the points that are pulling its mean towards one side. A single centre summarises the assigned positions without preserving their whole arrangement. Two differently shaped groups could share a mean, so the centre is already a compression of the data. When the next assignment uses that centre, it acts on the summary. This is one reason to keep watching the points rather than allowing the moving centres to become your only evidence.

This is k-means clustering. The number of centres is chosen in advance; the procedure searches for an arrangement of those centres using distance. The default display starts with four centres, while the generated sample contains three broad blobs and some noise. It is a useful reason to look closely instead of assuming the chosen number reveals the data’s natural categories.

The room sits in a classification sequence, but this encounter does not learn named classes from labelled examples. It groups observations by geometry. Calling a cluster a diagnosis, a personality or a social identity would add an interpretation that the distance calculation did not supply.

Watch a point on the edge of a blob after most colours appear settled. A hard colour boundary reports one assignment and conceals how nearly the alternatives competed. The displayed total distance is also a particular readout; do not confuse it with a complete explanation of why every individual assignment is appropriate.

Imagine replacing the separated blobs with two nested rings. Nearest-centre regions would divide space according to a different geometry from the rings’ apparent membership. That is a proposed alternative dataset for the room: a way to make the representation’s limits visible, rather than simply declaring that clustering is biased.

<!-- @ -->

The neural-network room introduces learned connections between layers. It will still need an account of what its training examples and error measure ask it to preserve.



## ML_Neural_Networks

Source: commons/maps/ML_Neural_Networks/final.md

SHA256: 654ee502f50169df70ab30f1e754bf0708dbe9efafe93435ec2e7903d5a5d70c

# A connection changed by an error

Where does a network store what it has learned?

<!-- @neural_network_visualization -->

Choose one connection between two layers and watch it through several training updates. Compare changes in its appearance with the error history. Try to distinguish the activity passing through a connection from a lasting change to the connection itself.

The moving activity belongs to a forward calculation: inputs contribute to later layers through weighted connections. The connection’s weight belongs to the model’s adjustable state. Changing that weight alters how a future input will influence the next layer, even after the current activity has passed.

Compare two views of progress: a single connection becoming visually different, and the aggregate error changing. They describe different scales of the update. One weight can move while the overall error changes little, because many other contributions still take part in the prediction. Conversely, a clearer improvement in the history does not identify one special wire as the location of the answer. The display asks you to relate a distributed calculation to its numerical summary.

This exhibit trains on a small, fixed set of four examples with four inputs and two desired outputs. It computes predictions, compares them with those targets, and uses the resulting error to adjust the weights. The backward calculation works out how changes to earlier weights contribute to changes in the final error. It does not send a little correct answer backwards through every wire.

The colour and strength of a connection help expose its sign and magnitude. A negative contribution is not a damaged connection, and a large weight is not a complete explanation of an output: the surrounding inputs, other connections and nonlinear transformations still matter. Follow the network as a calculation distributed across those relations.

K-means moved centres according to assigned examples. This learner changes many connected parameters according to the error on its training examples. In both cases, apparent improvement depends on a task and a measure selected beforehand.

The training display can establish that this small network is adjusting to its sample. It cannot establish that an unfamiliar case will be handled well. For a future experiment, hold out an example and compare its error with the training error. A widening difference would make the boundary between fitting and generalising visible.

<!-- @ -->

Perception next asks what enters such a model. Before a network can learn from an image, some distinctions must already be made available as input.



## ML_Perception

Source: commons/maps/ML_Perception/final.md

SHA256: 686ca6d3b2791614b6a686f946a81ff17d692372c9350ac364c6dc678a7a0b12

# An edge is not yet an object

At which point does a difference between pixels become a claim about what is there?

<!-- @computer_vision_vr -->

Find an edge of the cross or disk in the input image. Compare that location with the neighbouring edge image. Follow the small moving window and look at what happens when it crosses a boundary rather than a uniform patch.

The edge image emphasises abrupt changes in intensity. The exhibit applies horizontal and vertical Sobel filters to a small pixel grid, combines their responses into a gradient magnitude, and displays that result. A bright response says that nearby pixel values change sharply; it does not by itself say “circle” or “cross”.

Compare the interior of the disk with its boundary. Both belong to what you recognise as the same object, yet the filter treats them differently because its question is about local change. Then compare a short fragment of the disk’s edge with a fragment of the cross. The image-wide identity that seems obvious to you is not present as a complete object inside either tiny neighbourhood. The window makes that difference of scale inspectable.

The moving window helps you connect a local neighbourhood with a local calculation. The whole boundary is assembled from many such responses. At the outer border, this implementation leaves the result at zero, which is another reminder that an image-processing rule includes a decision about what happens where neighbours are missing.

Now read the object names and confidence percentages. In this exhibit those names and percentages are supplied in advance. They are not predictions learned from the computed edges. The room currently places a real filtering operation beside an illustrated classification claim; the link between the two remains to be built.

That separation gives us a precise question for developing the encounter. What evidence would a recogniser need before it could justify the name, and how would its confidence be checked? A future interaction could alter the input while exposing which stages actually change, allowing an unsupported label to become visible as a broken dependency.

For now, use your own observation: identify one edge fragment that could belong to more than one object. Local contrast can be real while its interpretation remains ambiguous. Adding a confident word does not remove that ambiguity.

<!-- @ -->

The sequence-memory room adds another source of evidence: what happened before the current input arrived.



## ML_Sequence_Memory

Source: commons/maps/ML_Sequence_Memory/final.md

SHA256: 971490b3dfe4fcd40ca80aae3250d71630e53fd3639b2006ee622737cf3ce5f0

# What should survive the next input?

How can a learner use the past without keeping every past event equally active?

<!-- @lstms_vr -->

Walk around the gate diagram and trace the route from incoming information towards the cell-state stream and the outgoing path. Choose one gate and predict what withholding information there would change. Keep that prediction separate from the movement of the decorative particles.

The diagram distinguishes three kinds of decision: what previous state to retain, what new material to admit and what part of the current state to expose as output. These are useful distinctions even when the same stream appears continuous from a distance. A memory has to preserve something while permitting something else to change.

Trace the cell-state route separately from the output route. Imagine retaining a detail for later without displaying it now; then imagine producing an immediate response without keeping every detail of the current input. These are different jobs. The spatial separation helps you ask which job a gate is meant to regulate. It also prevents the stream’s continuity from becoming a vague claim that all information simply passes unchanged from the beginning to the end.

In a working long short-term memory network, learned gates scale numerical contributions to the cell state and output. A gate can take an intermediate value; it is not necessarily a literal door that is either fully open or fully shut. Repeated updates let earlier information influence later predictions through an evolving internal state.

The present arrangement is a spatial diagram of that arrangement. Its particles follow an animation, and it does not yet carry an input sequence through a computed recurrent memory. The gate bodies therefore support tracing the proposed relationships, but their appearance cannot demonstrate that a particular earlier input has been remembered or forgotten.

Take the sentence “the key beside the cabinets is missing”. Which earlier distinction matters when choosing “is” rather than “are”? This thought experiment asks memory to retain the relevant subject across intervening words. It does not imply that a gate comes with an explicit grammatical label or that every trained network solves the problem reliably.

The next useful addition would make an input sequence and cell-state values visible, then compare two sequences differing at one earlier step. That would turn your prediction about a gate into an observable test.

<!-- @ -->

Generative learning next changes the task again: a model produces candidates, while another source of feedback judges them.



## ML_Generative

Source: commons/maps/ML_Generative/final.md

SHA256: 923305fd32806ca72863e89059b90461b449d5f46a46ac1c8a03eb93b78d81e1

# Learning from an opponent’s response

What changes when a learner’s critic is also learning?

<!-- @generative_adversarial_networks_gans_vr -->

Move between the generator and discriminator regions and follow the indicated exchange. First identify where a candidate is supposed to originate. Then trace where a judgement would return. Before watching the scores, say which part would need to change if the critic became better at distinguishing generated examples.

The two roles depend on one another. A generator attempts to produce candidates that a discriminator will accept as resembling the reference data. The discriminator attempts to distinguish the sources of the examples it receives. Improving one role can change the problem faced by the other, so the learning environment is partly made by another learner.

Read the exchange once from the generator’s side and once from the discriminator’s side. The same candidate can be useful to one participant as an attempted success and to the other as a training example to distinguish. The two roles therefore do not share a single meaning of improvement. Keeping their questions separate will matter when the room gains actual examples: a number moving in a favourable direction for one role may signal a changing difficulty for the other.

That relationship differs from descending a fixed surface. In the loss-landscape room, the scoring rule stayed in place while a point moved. Here the intended training process changes the evaluator as well as the evaluated model. A low score needs interpretation in relation to both participants and the examples they have seen.

This room currently illustrates those roles through animated zones, particles and progress displays. Its displayed losses are prescribed curves over time; no generator and discriminator are actually trained by the exhibit. The motion can help you remember the proposed exchange, but it cannot provide evidence that the generated candidates have improved.

Use that boundary to specify the experiment the room still needs: show a changing candidate, the discriminator’s response and the reference example involved in an actual update. Repeating one convincing candidate would then become distinguishable from producing a varied set. A beautiful average or a falling score alone would not settle the difference.

Ask also what the reference set treats as recognisable. Producing more of what an evaluator already accepts can leave unusual forms outside its reward, even when those forms matter to someone encountering the result.

<!-- @ -->

The synthesis room looks directly at that outside: how does a model decide that an observation is an anomaly?



## ML_Synthesis

Source: commons/maps/ML_Synthesis/final.md

SHA256: aa7d3958ace196298215d1f9e7fd01f05e64a6696e22bc9df23860d40c21dc19

# The point outside the rule

When a point is flagged as unusual, what exactly has been discovered?

<!-- @anomaly_detection -->

Find one raised, enlarged point and compare its position with a nearby unflagged point. Read the active detection mode. Before interpreting the raised point as an error, ask which numerical comparison could have put it above the threshold.

In the default view, the exhibit measures displacement from the sample’s mean along each coordinate, scaled by the spread on that coordinate. It adds the two absolute standardised displacements and compares the result with a threshold. Points meeting the threshold are lifted and enlarged, making a numerical decision into a spatial distinction.

Compare a point displaced mainly along one coordinate with a point displaced along both. The default score adds coordinate contributions, so the shape of its decision boundary comes from that addition as well as from the sample’s spread. Do not rely only on the impression of being far from the centre. The exhibit gives you a chance to connect the position of a raised point with the particular arithmetic that made its distance count.

The score depends on the sample used to compute the mean and spread. Here the generated outer points are included in those statistics along with the central cloud. The population helping define normality therefore includes the very observations that may later be called abnormal.

This is a specific coordinate-based rule. It is not a complete judgement about an observation’s origin or importance. A point might be an error, a rare valid case, an emerging pattern or a case the representation describes poorly. The raised position tells you what the score did; it does not choose among those explanations.

The machine-learning sequence has repeatedly separated the operation from the interpretation: a cluster from a named class, an edge from an object, and a training curve from demonstrated generalisation. The same care applies here. A detector’s name cannot supply evidence that its flags are useful.

Choose one flagged point you would investigate rather than discard. State what additional observation would help you decide. For a future version, exposing the threshold and allowing the reference population to change would make the cost of a decision visible: which rare cases become ordinary, and which ordinary cases become suspect?

<!-- @ -->

Graph theory will give us another representation of relations. Instead of asking how far points lie from a centre, we will ask which points are connected and what those connections permit.



# graphtheory

Declared order: GT_Foundations → GT_Layout → GT_Pathfinding → GT_Network_Analysis → GT_Connectivity → GT_Spanning_Trees → GT_Flow → GT_Matching

Museum map-authored order differs: GT_Foundations → GT_Layout → GT_Pathfinding → GT_Network_Analysis → GT_Connectivity → GT_Flow. Treat this as route drift to inspect, not an editorial recommendation.


## GT_Foundations

Source: commons/maps/GT_Foundations/final.md

SHA256: 7e7e883c45e3c3d7f250584cef53e65d99c25e0d3ccdb928f70e02dd3be18dfc

# Two travellers, one graph

Can two travellers obey the same connections and encounter the graph in different orders?

<!-- @two_travelers -->

Choose a lamp several connections away from the starting lamp. Predict whether it will be reached early or late. Watch one traversal, then keep the same destination in mind as the other begins. The exhibit alternates between two visiting rules on the same branching structure.

One traveller explores the nearest layer of neighbours before moving further out. The other follows a branch deeper before returning to alternatives. The lamps and their connections remain available to both; what changes is the order in which unfinished possibilities are kept.

During the breadth-first traversal, look across an entire layer before following the traveller deeper. During the depth-first traversal, keep one unfinished side branch in mind while attention goes elsewhere. The waiting branch has not disappeared from the graph. It has changed position in the procedure’s pending work. This comparison lets you describe order without changing the structure itself, and makes the traveller’s memory as important as the connections directly in front of it.

A graph describes this arrangement with vertices and edges. A vertex is a place in the structure, and an edge records a permitted connection. Its drawing helps us see the graph, but the visiting rule acts on those connections rather than on how attractive or physically close a lamp appears.

Breadth-first search keeps a queue: newly discovered possibilities wait behind earlier ones. Depth-first search uses a stack: the most recently added possibility is taken next. Those small differences in memory produce the two larger rhythms you have watched. A queue spreads attention across a frontier; a stack carries it into a branch.

Return to your chosen lamp and count connections from the start. In this unweighted graph, breadth-first layers correspond to that number of steps. Depth-first search can reach a deep lamp while another shallow branch still waits. Neither visit order is a complete account of which destination matters most.

If the lamps stood for people awaiting attention, the ordering rule would have consequences beyond its neat animation. A procedure that eventually reaches everyone can still make some wait much longer. A proposed extension could let the group choose one urgent destination and compare the waiting time under each rule.

<!-- @ -->

The next room lets the drawing itself move. Keep the graph’s connections separate from the positions used to display them.



## GT_Layout

Source: commons/maps/GT_Layout/final.md

SHA256: d611d7eebda2f9e71cf4b2b56f38f1df5adf47bcc4381975983ec359e406659e

# A connection is not a coordinate

If the drawing moves, has the graph changed?

<!-- @force_directed_layout -->

Choose one vertex and identify two of its connected neighbours. Keep those relationships in view while the drawing settles. Notice which distances change and which connections remain. Try to describe the difference without calling every movement a new network.

The default graph has eight vertices joined in a cube’s connection pattern. Its positions are adjustable. Connected vertices exert a spring-like attraction, while pairs of vertices also repel one another. Damping reduces continuing motion. The final arrangement reflects the balance of these forces rather than an instruction to draw a particular cube in a particular orientation.

Choose an edge whose length changes noticeably as the drawing settles. Describe its endpoints without using left, right or above, since those descriptions may stop helping as positions move. You might identify one endpoint through its neighbours and then follow the same relation through the motion. This is a small exercise in recognising structure independently of its current projection. The drawing remains useful, but it is no longer the only way you know which connection you are seeing.

A force-directed layout is a method for choosing a graph’s visible coordinates. The graph supplies adjacency; the layout supplies positions that may make that adjacency easier to inspect. An edge can stretch without ceasing to connect the same pair. Conversely, two unconnected vertices can pass close together in the drawing without acquiring an edge.

The two travellers in the previous room followed connections. They would still need the adjacency structure even if this layout placed two unrelated vertices almost on top of one another. Visual proximity can suggest a relationship that the visiting rule does not possess.

Now find a vertex that looks central. Is it central in the arrangement, unusually well connected, or simply easy to see from where you stand? Those questions can have different answers. A useful drawing can also invite an unsupported story about influence or importance.

For a future comparison, hold the graph fixed and show several layouts side by side. If a claim about the network disappears when the drawing rotates or rearranges, ask whether the claim belonged to the graph or to its presentation. The present moving layout gives you the beginning of that distinction.

<!-- @ -->

Pathfinding will change a connection’s availability while a traveller is already moving. This time the route really may need to change.



## GT_Pathfinding

Source: commons/maps/GT_Pathfinding/final.md

SHA256: be4cae950e37a4c187602ef3eda78a94746419501008ff005a2b2f9e8f903d28

# The route after a stone disappears

What should a traveller do when the route it planned is no longer available?

<!-- @impatient_river -->

Follow the spark’s route across the stones. Before pressing the button, choose the next connection you expect it to use. The button sinks a stone belonging to the current route. Watch the displayed route change and see whether the spark can still reach the opposite bank.

A route is a sequence through available connections. Removing a stone changes the graph the search can use; it does not merely make the old drawing look different. The exhibit marks that stone unavailable and asks for another path through the remaining graph.

After a removal, compare the old route you remember with the newly highlighted one. Look for a stretch that remains useful to both. Replanning does not imply that every previous choice was wrong; some connections can survive a local change while another segment must be replaced. If no route appears, trace the missing connection in your own proposed crossing. This keeps the observation tied to the available stones instead of treating a failed search as a mysterious refusal.

The connections here come from a spatial rule. Nearby stones are linked, and the banks receive links to nearby stones. The search therefore works with the routes that this constructed graph permits. A gap that your eyes imagine jumping is not automatically an edge, and a bright route is the spark’s calculated route rather than a promise that your own body can walk it.

The exhibit keeps a limited number of stones disabled. As more disappear, older ones can return. A route can consequently change because an option was removed or because an earlier option became available again. Keep both kinds of change in mind when you explain a rerouting.

Sometimes there may be no route. That outcome says something precise about the available graph. It does not prove that no crossing could exist with another bridge, another connection distance or another kind of traveller. Search cannot use an option the representation never supplies.

Try a second removal after the new route is established. Predict whether the remaining network has an alternative before asking the algorithm. A future extension could expose the search frontier, separating the work of finding a route from the spark’s later traversal of it.

<!-- @ -->

Network analysis asks what the arrangement as a whole makes possible: which vertices connect many others, and which only look important in the drawing?



## GT_Network_Analysis

Source: commons/maps/GT_Network_Analysis/final.md

SHA256: 67b9122dbc9cdfb22ffcf7655c553923055ff433749ff58b4b0d1cf5e7263936

# Important by which measure?

What evidence would justify calling one vertex central?

<!-- @network_analysis -->

Find a large, conspicuous vertex and count its incident edges. Compare it with a smaller vertex. Then look at the displayed network measures. Ask which of those quantities you could independently check by following the connections.

Degree is one answer to a narrow question: how many edges meet this vertex? Other questions require other measures. A vertex might connect two regions without having the largest number of neighbours, or it might have many neighbours that are already richly connected to one another. “Important” hides these differences until we name the relation we want to measure.

Use two descriptions for the same vertex: one about how it is drawn, another about a connection you have checked. “Large and high” belongs to the first description; “joined to these neighbours” belongs to the second. You can then ask whether the presentation is helping you discover a relation or asking you to accept one. This distinction is especially useful when an animated number appears authoritative before you know what events or paths it summarises.

This display arranges vertices in authored layers with different sizes and colours. Its centrality values are assigned from ranges, and some summary measures follow an animation over time. They are not all calculated from the displayed edges. The room currently offers a diagram of a network hierarchy; its readouts cannot yet certify that hierarchy through graph analysis.

Your edge count is therefore a useful small piece of evidence. It can be compared with a visual claim without pretending that counting degree settles every possible meaning of centrality. If a large vertex looks authoritative, separate the role of its size, its placement and its actual connections.

The pathfinding room showed how losing an option can alter a route. Extend that thought here: imagine removing your chosen vertex. Which neighbours would still reach one another? Which connection would you need to check before answering? This is a prediction for a future removal experiment, not a claim that the present display performs one.

A stronger version of the room would calculate a named measure and let you inspect its supporting paths. It should also let another measure disagree, so a single visual ranking does not become the definition of value.

<!-- @ -->

Connectivity next gives us one exact question to test: where can a directed traveller go and still return?



## GT_Connectivity

Source: commons/maps/GT_Connectivity/final.md

SHA256: e657d9ac21123ee3f42f0bb4742c7d3db1864212e56fbe50f03ba26b579c7812

# A way back

If you can travel from one vertex to another, can you necessarily return?

<!-- @tarjan_algorithm -->

Choose two vertices joined by a directed path. Trace the arrow directions from the first to the second, then search for a return route. Keep your proposed group in mind while the traversal assigns colours to completed components.

A strongly connected component is a maximal group in which every vertex can reach every other by directed paths. A one-way bridge can connect two groups visually while leaving them separate in this sense. Proximity, shared colour before the search, or a line with the wrong direction cannot substitute for a return path.

Test your proposed component from more than one starting point. A return route for one pair is necessary but does not settle whether every member of a larger group can reach every other. You can make the check manageable by looking for the paths that join a candidate member to the already considered group in both directions. An incoming connection alone may make the drawing feel joined while still leaving the traveller unable to return.

The exhibit runs a depth-first traversal. Each newly visited vertex receives a discovery number and remains on a stack while its group is unresolved. Another value records how far back the current exploration can connect through the relevant routes. This is the low-link information used to recognise when a component can be completed.

Watch the moment several vertices receive one component colour. They are being discharged together from the unresolved stack. The procedure has found a boundary in reachability, not simply collected the next fixed number of vertices. The stack you met with the two travellers now carries information about a question that remains open during the walk.

Try finding an edge between two completed colours. Follow its direction and ask what would need to be added to make the components mutually reachable. One additional return connection can change the component structure much more than its modest length in the drawing suggests.

Strong connectivity is still a limited promise. It establishes the existence of directed routes, not that those routes have equal cost, sufficient capacity or equal accessibility. A long and fragile return journey counts as a return journey under this definition.

<!-- @ -->

Spanning trees will ask how many connections can be removed while everyone remains connected. The useful return route you just found may look like an expendable cycle under a different objective.



## GT_Spanning_Trees

Source: commons/maps/GT_Spanning_Trees/final.md

SHA256: 22a212a47d918e95e32e9a259b8d155312604bf6bac3367105536775c1181434

# The price of one more route

Which connection can you remove without separating anyone from the network?

<!-- @mst_visualization -->

Watch the next edge considered by the display. Before it is accepted or rejected, trace whether its two endpoints are already connected through accepted edges. An edge can look short and useful while adding no new connection between the groups that remain separate.

The default procedure is Kruskal’s algorithm. It considers edges in increasing order of weight and accepts an edge when that edge joins two different components. If the endpoints are already joined, the candidate would complete a cycle and is rejected. A small structure called union-find tracks which vertices already belong to the same component.

When an edge is rejected, trace the accepted route between its endpoints and notice how that route completes the would-be cycle. The rejection has a structural reason even if the edge’s weight is small. When an edge is accepted, identify the two previously separate groups it joins. Alternating these two checks helps you follow the algorithm’s decisions without needing to remember every edge considered earlier or interpret the final green network all at once.

Continue until the selected edges span the connected graph. A tree connects its vertices without cycles; between each pair there is one selected route. With the given edge weights, Kruskal’s rule produces a spanning tree of minimum total weight. “Minimum” refers to that sum, not to every traveller’s individual journey.

Compare a rejected edge with the route now needed between its endpoints. Removing a direct connection can lower the cost of maintaining the whole network while lengthening a particular trip. The criterion that made the tree economical does not make each path shortest.

Now imagine one selected edge failing. In a tree, removing an edge separates the structure into two components. A cycle that looked redundant under the construction budget could have supplied a second route. Redundancy changes meaning when the question changes from cheap connection to surviving a failure.

For a proposed extension, let a group spend the cost of one extra edge after the tree is complete. Which edge would it restore, and whose journey or reliability would improve? That experiment would keep the minimum tree as an understandable baseline while making room for a different objective.

<!-- @ -->

Flow adds another constraint. A route may exist and still be unable to carry everything trying to pass through it.



## GT_Flow

Source: commons/maps/GT_Flow/final.md

SHA256: 246c007bc670ab87e9e8f0579570b08e2d5a6f60fe476726e9a87dcf991673b0

# What a junction cannot pass on

Where does the excess go when a junction receives more than it can send onwards?

<!-- @push_relabel_algorithm -->

Follow the initial flow leaving the source. Choose a junction that accumulates excess and compare its readout with the available outgoing edges. Watch for a PUSH or RELABEL step. Predict whether the next action can send material towards a neighbour or must first change the junction’s label.

Capacity limits how much an edge can carry. Flow is the amount currently assigned to it. Excess records a temporary imbalance at a vertex: more has arrived than has yet left. The height label gives the local procedure a direction in which to attempt a push; it is an algorithmic value, not the physical altitude of the drawn vertex.

Separate an edge that is full from a vertex that has excess. The first describes a limit on one connection; the second describes a temporary balance at a junction. A vertex can have more than one outgoing option, and those options can have different amounts of room left. Following that distinction makes a local PUSH easier to interpret: it transfers an available amount through a particular edge, rather than declaring that the entire junction is solved.

The exhibit begins by filling outgoing source edges. It then tries to move excess through remaining outgoing capacity towards lower labelled neighbours, changing labels when a push is unavailable. Those local changes help make congestion and temporary storage visible.

A complete maximum-flow method also needs a way to revise earlier allocations. Residual reverse capacity represents that possibility: some previously sent flow can be undone so that a better arrangement becomes available. This exhibit does not yet implement those reverse adjustments, so its current run cannot establish the general maximum-flow claim suggested by its title and readout.

Keep the observation smaller and exact: which vertex held excess, which original edge still had room, and what local operation followed? Those are relationships you can inspect without treating every accepted push as an irrevocable good decision.

The next useful experiment would expose a case that requires rerouting and make the reverse adjustment visible. The comparison would show why revision is part of the algorithm’s power. It would also prevent a blocked intermediate allocation being mistaken for a physical impossibility.

<!-- @ -->

Matching will impose a different limit: each vertex may have only one selected partner. Once again, an early acceptable choice may need to be undone.



## GT_Matching

Source: commons/maps/GT_Matching/final.md

SHA256: 086247b960405eca435aaa0c897ea90e5ed0f537cf1ebead258e606e512bbe10

# A pair that blocks two pairs

Can every chosen pair be valid while the collection still leaves avoidable gaps?

<!-- @edmonds_algorithm -->

Watch the edges considered by the matching display. Predict whether the next edge can be selected by checking its endpoints: has either already been paired? Follow one unmatched vertex to see whether its remaining neighbours are all occupied.

A matching is a set of edges with no shared endpoints. Each vertex participates in at most one selected pair. This condition tells us whether a collection is allowed, but it does not tell us that the collection contains as many pairs as possible.

Follow an occupied endpoint into the next few decisions. Several rejected edges can share that same endpoint, so one accepted pair can shape the fate of many later candidates. The rule prevents double booking correctly, but that correctness is only one part of the task. Keeping an unmatched vertex in view makes the consequence visible from the waiting vertex’s side, instead of assessing the procedure solely by how confidently it marks each new pair.

The present exhibit scans edges and accepts a pair whenever both endpoints are free. It keeps those choices. That greedy procedure can reach a maximal matching: no extra edge can simply be added without breaking the rule. A maximum matching answers a stronger question by containing the greatest possible number of pairs.

Try a small example in your head or with four people standing in a line, A, B, C, D. If B pairs with C first, neither outer edge can be added. The matching is maximal with one pair. Choosing A with B and C with D instead gives two pairs. Improving the first result requires undoing an accepted edge, not just looking harder for another unused edge.

The exhibit’s name refers to Edmonds’ algorithm, but its current procedure does not implement that algorithm’s augmenting and blossom-handling steps. Treat the visible greedy process as a starting case; the next development needs to make revision possible and show the example in which it matters.

Matching also leaves the meaning of a good partnership outside its endpoint rule. Maximising a count cannot establish consent, suitability or fairness. Those questions require further conditions and a way for participants’ preferences to matter.

<!-- @ -->

The foundations sequence will question what a formal system can establish. Carry one distinction forward: a procedure meeting its local rule is not automatically a proof of its strongest advertised conclusion.



# foundationscrisis

Declared order: Euclid_Parallel → NonEuclidean_Spaces → Russell_Paradox → Godel_Incompleteness → Escher_Impossible → Brouwer_Intuitionism → Florensky_Paraconsistent → Crisis_Synthesis

Museum map-authored order differs: NonEuclidean_Spaces → Russell_Paradox → Godel_Incompleteness → Escher_Impossible → Brouwer_Intuitionism → Crisis_Synthesis. Treat this as route drift to inspect, not an editorial recommendation.


## Euclid_Parallel

Source: commons/maps/Euclid_Parallel/final.md

SHA256: 24219c28503d382a8bd6fab129aa8c58f7350729e7a7295049c58fb4ed1d7fcb

Click the plaque five times and you arrive back at the first postulate. The counter wraps:

```gdscript
# euclid_postulates_plaque.gd:202
func next_postulate():
	current_postulate = (current_postulate + 1) % 5
```

Five clicks, five postulates, one closed loop. Four of them fit on two short lines. The fifth needs four lines and a parenthesis. That is the whole principle, and you can repeat it after one walk: this space is flat because the room says so, not because anyone measured it.

## 1 — The five, stored as text

<!-- @euclid_postulates_plaque -->
<!-- ~tutorial#p2 ~tutorial#p4 ~critical#the-rule-that-could-not-be-proven -->

Let's start where the build starts. The tutorial keeps the five postulates as strings in a constant array — text, not logic, so a plinth can show them without a parser. The shipped plaque makes the same choice, and bakes its own line breaks in:

```gdscript
# euclid_postulates_plaque.gd:46
	"IV. All right angles are\nequal to one another.",
	"V. If a line crosses two lines\nand interior angles sum < 180°,\nthe two lines meet on that side.\n\n(The Parallel Postulate)"
```

Read those two as sentences. The fourth states an equality and stops. The fifth carries a condition, a threshold, a prediction — and then names itself.

The difference is not length. The first four hand you permissions: what a hand with a straightedge may do. The fifth tells you what will happen once your hand has done it. It is a rule shaped like a forecast, and a forecast asks to be checked. Twenty-three centuries of checking failed, and the failure was read as a gap in the mathematicians.

Fair — and let's say what the array does about it. The fifth is the only entry carrying a blank line inside itself.

It uses that blank line to introduce itself. Nothing else on the plaque has to.

## 2 — Marked before anyone argues

<!-- @euclid_postulates_plaque -->
<!-- ~tutorial#p10 ~tutorial#p11 ~critical#performativity-of-the-obvious -->

Before you have read a word, the room has told you which postulate matters. The gold arrives ahead of the argument.

It does, and we can point at the line that does it. The tutorial tints the fifth plinth and scales it by 1.2; the shipped plaque runs the same move as a branch:

```gdscript
# euclid_postulates_plaque.gd:121
	var is_fifth = current_postulate == 4
	var title_color: Color
	var text_color: Color
	if is_fifth and highlight_fifth:
		title_color = Color(1.0, 0.7, 0.3)
		text_color = Color(1.0, 0.9, 0.7)
```

Two conditions, not one. The same pair guards the announcement further down: `parallel_highlighted.emit()` sits inside `if is_fifth and highlight_fifth:` at line 163. Colour and signal come out of one branch.

Repetition is how obviousness gets made — every grid, every Cartesian axis, every drawn pair of parallels performs the fifth postulate again. Here the performance is one branch, repeated on every click. You are asked to follow the gold, and following feels like noticing.

So let's break the branch. `highlight_fifth` is an exported bool. Set it false and the fifth reads in the same warm grey as the rest, and `parallel_highlighted` never fires — the branch that shouted was the branch that coloured. `postulate_selected` still emits at index four, the way it does at every other. Cycle again and ask whether the fifth still feels like the odd one.

## 3 — Three lines that never meet

<!-- @parallel_lines -->
<!-- ~tutorial#p13 ~tutorial#p14 ~artifacts#parallel-lines ~critical#the-state-of-exception -->

The tutorial draws five lines at `y := -2.0 + i * 1.0` — even spacing, one unit apart, a picture in which Euclid's claim looks like a property of the world. The shipped scene has three, placed by hand:

```gdscript
# parallel_lines.tscn:7
[node name="Line1" parent="." instance=ExtResource("1_line")]
transform = Transform3D(0.258819, 0, 0.965926, 0.965926, 0, -0.258819, 0, 1, 0, -0.0648265, 0, 0)
```

Let's count the gaps. Line2 sits at 0.204004, Line3 at 0.305252. The first gap is about 0.27, the second about 0.10. The registry calls this artifact three line modules arranged to visualize equidistant lines. The transforms are not equidistant.

The parallelism survives. All three share a basis, so they run forever without meeting, whatever the spacing. Equidistance is a consequence the fifth postulate guarantees, and it is the part the declaration asserted instead of building. The word carried what the numbers did not.

Try it yourself: move Line3's offset out to 0.4 and count the gaps again. They change, and the lines still never meet. Spacing you can set by hand; parallelism comes from the shared basis.

And nothing in the room says the word out loud: the scene's `Label3D` ships with `visible = false`.

So you supply it. You look at three lines, name them parallel, and the naming arrives as sight.

## 4 — The triangle that says sixty

<!-- @angle_sum_triangle -->
<!-- ~summary#p3 ~blurb#p3 ~critical#what-the-axiom-conceals -->

The triangle's three corners are literals — apex at `size * 0.5`, base corners at `-size * 0.4` and `size * 0.4`. Then we hand the labels their text:

```gdscript
# angle_sum_triangle.gd:151
	var angles = ["60°", "60°", "60°"]
	var sum_text = "60° + 60° + 60° = 180°"
```

The shape those vertices make is isoceles, not equilateral. The file records its own measured corners: 53.1, 63.4, 63.4. Both triples sum to 180. The three sixties are shipped bytes, handed back rather than measured.

So the sum is true and the parts are ornament. Three equal numbers describe a triangle you are not looking at. It is the plaque's move again in another material: one surface makes unlike things look alike — five postulates in a single row, three identical angles under one figure. What gets hidden is not a falsehood. It is a difference.

The file already knows better, in a function just above. `_angles()` reads each corner off the polyline it actually drew, and at any curved opening the labels print what was measured. At `flat` it prints the shipped strings, because three placements ship them.

Keeping three maps byte-identical is a reason to print sixty. It is a reason about shipping, not about triangles. The geometry never asked for it.

## 5 — The setting you cannot reach from here

<!-- @angle_sum_triangle -->
<!-- ~tutorial#p16 ~tutorial#p17 ~critical#performativity-of-the-obvious -->

Let's measure how far the other spaces sit from this floor. The tutorial toggles the fifth and a second preview fractures. The shipped artifact has a real axis:

```gdscript
# angle_sum_triangle.gd:49
@export_enum("flat", "hyperbolic", "elliptic") var opening: String = "flat"
```

Map tokens reach it only through one gate:

```gdscript
# angle_sum_triangle.gd:203
	if config_data.has("opening"):
		var want: String = str(config_data["opening"]).strip_edges().to_lower()
		if OPENING_VALUES.has(want) and want != opening:
```

Every placement here ships the bare token, so that `has("opening")` is never true and `_polyline()` short-circuits past the arc loop. What happens if a placement hands it `opening=elliptic`? The edges bow outward at six percent of each chord, the corners open, and the printed sum climbs near 260. Hyperbolic falls near 100. Both are legal geometries. Try the token and watch the equation stay true while the number stops being 180.

So the other two spaces are already here, priced in degrees, one word away — and no move a body makes on this floor arrives at them. What a body can reach is the whole question. A geometry that ships in the file and waits on a placement is not absent; it is held back. The room offers one space and lets the absence of the others do the arguing.

## 6 — A screen with nothing to flatten

<!-- @science_screen -->
<!-- ~artifacts#science-screen ~summary#p2 ~critical#the-state-of-exception -->

The screen scans eight metres for neighbours that answer `get_grid_data()` and paints their cells at 768 by 576. Neither script here defines that method. The plaque offers `apply_grid_config`, two signals and three exports; the triangle offers `apply_grid_config` and two exports, `opening` and `size`. Nothing offers the one call the screen makes. So we open on the fallback:

```gdscript
# science_screen.gd:317
	_point_mode = true
```

The fallback is not a blank panel. It is a grid: white, square, right-angled, drawn before anything arrives to be drawn. The screen does not wait to learn what space it is in. It draws right angles whether or not anything is there, and right angles are this room's postulate in pixels.

Test it. Cross the room and watch the picture — it does not change, because nothing here gives it anything to change into. And this file has been fooled by its own paperwork before: its axis block once declared value names that were never in its enum. The sweep set them, the artifact fell back to its default, and sixteen identical frames were published — sixteen pictures of the same screen, filed as four variants. Nothing failed loudly.

A declaration outrunning its code, twice in one room. Here it arrives as a white grid rather than an error, which is how such things usually arrive.

## 7 — What the spec asked for and what stands here

<!-- @angle_sum_triangle -->
<!-- ~intent#p1 ~tutorial#p19 ~walked#what-it-opens ~summary#p4 ~blurb#p2 ~critical#the-state-of-exception -->

The tutorial closes with a scroll — 300 BCE Euclid, 1733 Saccheri, 1829 Lobachevsky, 1832 Bolyai, 1854 Riemann — and a door that unlocks after two seconds of reading. The spec asked for two interactive demos, `parallel_line_demo` and `euclid_parallel_demo`, that let you drag the lines. Neither is placed.

We can see that absence from inside the code. Every placement here ships a bare token, and a bare token arrives as an empty dictionary:

```gdscript
# angle_sum_triangle.gd:197
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
```

Three lines, and the only door into the geometry shuts before it opens. What stands here is a plaque, three lines, a triangle, a screen — and the building itself: an eleven by fifteen floor, pillars three units tall in mirror symmetry down both sides, a walkway left open between them. Walk that walkway and you are standing inside the assumption. The colonnade is the axiom, built at the size of a body.

The absence is honest about the work. You are not here to bend a parallel. You are here to stand where bending is out of reach, and to feel how little effort that costs. The exit asks the question the furniture declines, and the next room takes the fifth away.

Count once more: five postulates, three lines, one triangle, one screen, two rows of pillars. Every number is true. Not one of them is necessary.

You can stand on a floor and still ask what is holding it up.


## NonEuclidean_Spaces

Source: commons/maps/NonEuclidean_Spaces/final.md

SHA256: c52511e05a8b13f1a544812a9031df8d33c6c4a7949c8e3f75caa9ab8792fe9a

A bowl on your left, a dome on your right, and a flat plate between them that no longer looks like the default.

The previous room let you stand inside an assumption until it stopped feeling like one. This room puts the assumption on a dial. There is a slider here with a number on it, and the number is the curvature of space — negative to the left, zero in the middle, positive to the right. Flatness is the detent at zero. It is not the centre because it is correct; it is the centre because it is zero.

## One number, and it is not a metaphor

<!-- @curvature_slider -->

```gdscript
# curvature_slider.gd:10
# critical_parameter: curvature — the ONE number that determines the entire geometry
```

Gaussian curvature, K, running from −1 to +1. That single scalar decides whether parallel lines diverge, stay apart, or converge; whether a triangle's angles sum to less than, exactly, or more than 180°; whether the shortest path between two points looks straight to you from outside. Not three geometries with three rulebooks. One rulebook with one free parameter.

This is the nineteenth century's actual discovery, and it is more unsettling than "there are other geometries." Gauss, Bolyai and Lobachevsky did not find a strange new space next door to the real one. They found that the space we were in had a setting, and that nothing in mathematics specifies which value it should take. Euclid's fifth postulate turns out to be the statement *K = 0* — not an axiom about parallels, a choice about curvature, wearing a sentence about lines.

## Where the wire is missing

<!-- @poincare_disk -->

```gdscript
# curvature_slider.gd:110
curvature_changed.emit(curvature)

# poincare_disk.gd:19 — and the only other place this signal name appears
signal curvature_changed(value: float)
```

Here is the room's own honest gap, and it is worth knowing before you turn anything.

The slider emits. Its registry entry says so plainly — *emits curvature_changed signal for linked surfaces* — and line 110 does exactly that, every time you move it. Search the rest of the project for anything that connects to it and you find one hit: the Poincaré disk, which declares the identical signal and emits it too. Two objects broadcasting the same message into a room where nothing is subscribed.

So the four surfaces standing around you — the saddle, the dome, the disk, the sphere — do not move when you turn the dial. Each one says so in its own header, in the same four words: *VR controls [missing]*. They are four fixed illustrations of four values of a parameter that is, in this room, unconnected to them.

Do not file that as a defect and move on. Notice what it makes the room into. You have a control that publishes a number, and a set of worlds that were each built at one value of it and cannot hear. That is a fairly exact picture of the situation the chapter is describing: the parameter is real, the consistency of each setting is real, and the passage between them is the thing nobody has built.

## The one that listens to itself

<!-- @triangle_curvature_workbench -->

```gdscript
# triangle_curvature_workbench.gd:7
# critical_parameter: K — discrete in {-2, -1, -0.5, 0, +0.5, +1, +2}. Drives surface
#   choice, edge geodesic type, angle measurement, and the excess/deficit readout
```

At the far corner, one bench does work. It carries its own slider — seven detents rather than a continuum — and when you turn it the surface underneath the triangle changes, the edges are rebuilt as geodesics *on that surface*, and the angle sum is measured and printed.

Measured. This is the payoff for the room you just left, where the angle sum was a hard-coded string reading `"60° + 60° + 60° = 180°"`. Here the number comes out of the geometry, and at K = 0 it lands on 180 not because anyone typed it but because that is what the flat case computes to. The same claim, arrived at two different ways, one room apart — and only one of them could ever have come out differently.

What it is showing you is the Gauss–Bonnet theorem: the amount by which a triangle's angles overshoot or fall short of 180° is exactly the curvature enclosed. Angle sum is not a fact about triangles. It is a measurement of the space the triangle is lying in, which is what the artifact's own header says: *the triangle doesn't know it's "in 3D"; it only knows its host*.

## Both neighbours of zero

<!-- @hyperbolic_surface -->

```gdscript
# hyperbolic_surface.gd:9
# essence: y = K(x² - z²) — saddle surface with negative Gaussian curvature K < 0
```

The saddle. Space curving outward, so that two geodesics starting parallel drift apart, and a triangle's angles fall short. Its header says something quietly good: *"straight" on a saddle looks curved from outside*. Straightness is not a property of the line. It is a relationship between the line and the surface it is confined to, and there is no outside vantage from which the surface is wrong.

<!-- @elliptic_surface -->

```gdscript
# elliptic_surface.gd:13
# emerges: the realization that on a positively curved surface there are NO parallel lines at all
```

The dome, and the opposite. Geodesics that begin parallel converge and cross, and the angle sum overshoots. On a sphere, the fifth postulate is not merely false — the thing it asserts cannot happen at all, because every pair of great circles meets. Twice.

Stand between the two and the point of the chapter is available without argument. These are not deformations of a correct space. Each is internally consistent, each has been formalised, each has physical realisations, and neither can be reached from the other by fixing an error. Flatness is the one in the middle. That is a fact about the number line, not about the world.

## The finite that holds the infinite

<!-- @riemann_sphere -->

```gdscript
# riemann_sphere.gd:10
# desire: see the infinite complex plane folded onto a finite sphere — the north pole IS infinity
```

Two objects here do the same trick from different directions and it is worth catching. The Poincaré disk compresses an entire infinite hyperbolic plane inside a finite circle: geodesics are arcs meeting the rim at right angles, and the rim is not an edge, it is infinity, which is why the tiles crowd and never arrive. The Riemann sphere does the mirror of it — the whole complex plane wrapped onto a ball by stereographic projection, with infinity as a single point you can walk around and look at from behind.

Both are saying that "infinite" and "unbounded" are not the same word, and that where you put the boundary is a modelling decision rather than a discovery. Which is the same sentence as the slider, one level up.

## What the dial cannot decide

Geometry was chosen, not found. That is settled by the time you leave this room, and it is settled without anyone having to be wrong.

But notice the shape of what just happened, because the next room breaks it. Every question here was answered by picking a value: what is the angle sum, do parallels meet, is the space finite — each one becomes answerable the moment K is fixed. The crisis so far is only that *we* pick K, and nothing outside picks it for us.

The next question does not have that form. It is not about which setting to choose. It is what happens to a rule that includes itself in the range of things it applies to — and there is no value of any parameter that makes that come out.

Flatness is a special case. The ground itself is a variable.



## Russell_Paradox

Source: commons/maps/Russell_Paradox/final.md

SHA256: e548e10b8e76d79e198099afd722985c0eac90fe239ca484ddf8d1c5244df4ce

Four objects arranged as a cross, with a box at the centre, and every one of them is the same sentence said in a different material.

The last two rooms were about a choice: an axiom is a decision, and the decision has a dial. Both crises were survivable, because in both cases you could pick a value and carry on. This room is where that stops working. Nothing here is waiting for you to choose. The trouble is in the shape of the rule itself, and no setting fixes it.

## The box at the centre

<!-- @russell_set_box -->

```gdscript
# russell_set_box.gd:20
# essence: S = { x | x ∉ x }; S ∈ S ↔ S ∉ S — Russell's paradox as infinite regress
```

Take the set of all sets that are not members of themselves. Ask whether it contains itself.

If it does, then by its own definition it must not. If it does not, then by its own definition it must. There is no third option and no order of operations that gets you out; the two branches feed each other exactly. Russell sent this to Frege in 1902, while the second volume of Frege's *Grundgesetze* was at the printer, and Frege added an appendix beginning with the observation that a foundation had given way under the finished building.

The artifact makes it a box you open, and inside is another box, and inside that another. Its critical parameter is `max_visible_depth` — how many nestings to draw before giving up and showing the regress indicator. That is an honest piece of engineering: the object cannot be built, so the artifact builds as much of it as fits and then admits, in a label, that the remainder is not a rendering budget but the thing itself.

## The same shape, three more times

<!-- @barber_paradox -->

```gdscript
# barber_paradox.gd:11
## truth: he belongs in neither bin; the rule eats itself. If the barber shaves
##   himself he is shaved-by-the-barber (forbidden); if he does not, the rule
##   says the barber must shave him — contradiction either way.
```

Two labelled bins — SHAVES SELF, SHAVED BY BARBER — and one token that will not go in either. The barber shaves exactly those who do not shave themselves. Put him anywhere and the rule immediately requires him somewhere else.

Russell offered this himself, as the version you can tell at dinner, and it is worth noticing that it is not a simplification. The bins are the point: a classification that is exhaustive and exclusive, with one element that the classification generates and cannot place.

<!-- @liar_loop -->

```gdscript
# liar_loop.gd:11
## truth: if it's true it's false, if it's false it's true. There is no stable
##   assignment — the value loops forever.
```

A chalk sign reading THIS STATEMENT IS FALSE, with a lamp above it that cannot settle. The oldest of the four — Epimenides, then Eubulides, twenty-four centuries before set theory — and mechanically identical to the box. A predicate applied to the sentence containing it. The lamp does not flicker because the artifact is animating an effect; it flickers because there is no value to hold.

<!-- @self_membership_set -->

```gdscript
# self_membership_set.gd:12
## truth: a set that is a member of itself, all the way down — and the set of
##   all sets that are NOT members of themselves cannot consistently exist.
```

The fourth arm, and the one that draws the distinction the other three leave implicit. A set that *does* contain itself is perfectly consistent — this artifact builds one, a brace inside a brace inside a brace, and nothing goes wrong. Self-reference on its own is not the fault. The catch is self-reference plus negation: the moment the rule is *not* a member of itself, the loop closes on a contradiction rather than on a regress.

That distinction is what saves mathematics later. The repairs — Zermelo–Fraenkel's axiom of separation, Russell's own type theory — do not ban self-reference. They ban unrestricted comprehension: the assumption that any property whatsoever carves out a set. You may still describe; you may no longer assume the description has an extension.

## The one that settles

<!-- @hilbert_hotel -->

```gdscript
# hilbert_hotel.gd:7
# critical_parameter: the shift map n ↦ n+1 — the bijection that proves |ℕ| = |ℕ + 1|
```

Two cells off the cross stands something that does not belong to the argument, and it is worth a sentence rather than a shrug, because it teaches the opposite lesson and it is standing close enough to be mistaken for a fifth arm.

Hilbert's hotel is full, infinitely, every room occupied. A guest arrives. Everyone moves up one, and there is a room. That looks like a paradox and behaves like one for about ten seconds, and then it resolves completely: the shift map is a bijection, the answer is *yes, there is room*, and the offended intuition was a finite intuition applied outside its range.

That is the difference this room needs you to hold. The hotel is a **surprise**, and it settles. The box, the barber, the liar and the brace are **contradictions**, and they do not. One of them is your intuition being wrong about infinity; the other four are a formal system being unable to say what it just said. Standing beside each other, they mark the line the rest of the chapter walks along.

<!-- @euclid_postulates_plaque -->

The plaque near the entrance is the fifth postulate again, brought forward from the first room. Nothing in this room explains why it is here, so take it as the chapter keeping its own receipt: two rooms ago the crisis was that a foundational statement could not be *proved*. Here it is that a foundational statement cannot be *stated*. The plaque is the earlier, milder version of the trouble, standing where you can see how much worse it got.

## Where the wall is

Something has changed in the kind of problem. The parallel postulate was independent — you could go either way and both ways were consistent. Russell's set is not independent. There is no consistent system in which the question has an answer, and the repair is not to choose a value but to forbid the question from being asked.

That is what a formal system's boundary is, and it is the last quiet moment in this sequence. Two rooms from now the same argument returns with a much harder result attached: not that a system must fence off certain sentences to stay consistent, but that any system strong enough to be interesting will contain a sentence that is true and that it cannot reach — and that fencing will not help, because the sentence is about arithmetic and arithmetic is what the system is for.

Every formal system draws a boundary — and the boundary is where the system meets what it cannot hold.



## Godel_Incompleteness

Source: commons/maps/Godel_Incompleteness/final.md

SHA256: 5b0be4a63f7de2c246cf04c4a888a9d412abc183dc6b15b882ecab5842a39b6c

# A truth outside the proof machine

Does a machine failing to find a proof show that no proof exists?

<!-- @godel_sentence_machine -->

Follow the loop marked by G through one attempt. Watch the mechanism stop and its verdict appear. Before accepting the words “true but unprovable”, ask what the movement has shown you. Has it exhausted every possible proof, or has one illustrated attempt come to an end?

The machine is a timed sculpture of an argument, not a running proof search. Its jam cannot establish incompleteness by itself. That matters because a slow search, a broken search and a proof that no search can succeed are three different things.

Think of a proof as a finite object that can be checked step by step against stated rules. Searching for such an object and checking one that has already been supplied are different tasks. A search might continue while each proposed candidate remains straightforward to reject. Keeping those tasks separate makes the sculpture’s stopped arm less misleading: the absence of a proof on the table has not yet told you what every possible candidate would do.

Gödel’s construction makes statements about proofs expressible within arithmetic itself. Under an effective axiomatisation with sufficient arithmetic, a sentence can be constructed that says, through this encoding, that it has no proof in the given theory. Assuming the theory is sound for the intended natural numbers, the sentence is true there and unprovable in that theory. The assumptions and the phrase “in that theory” are essential. [The École Polytechnique course chapter develops the encoding and fixed-point argument.](https://www.enseignement.polytechnique.fr/informatique/INF412/uploads/Main/chap10english-goodINF412ENGLISH.pdf)

<!-- @provability_sorter -->

Now follow a piece outside the sorter’s inner PROVABLE region but within its TRUE region. This nested picture assumes soundness: whatever the theory proves is true in the intended interpretation. The extra region represents the possibility of truths beyond its proofs. The drawing’s areas and piece counts do not measure how many truths lie outside; the pieces have illustrative destinations chosen in advance.

Russell’s room challenged an unrestricted construction that produced a contradiction. Here the difficulty can remain even when we choose a sound arithmetic theory. Adding a particular unproved truth as a new axiom may enlarge what is provable, but it does not turn effective arithmetic into a final list of every truth.

Try replacing G with a personal conviction. What is missing? You would need a defined formal language, axioms, proof rules and the mathematical argument. Incompleteness does not certify every unsupported belief, and it does not make careful proof pointless.

<!-- @ -->

Escher next changes the medium. Follow locally convincing connections and ask whether they can belong to one consistent spatial whole.



## Escher_Impossible

Source: commons/maps/Escher_Impossible/final.md

SHA256: 52cd6050a999a1fbb8833f2220876120b7f741111e795735a8505007358def89

A staircase that goes up on all four sides and comes back to where it started.

Check any corner of it. The riser is a sensible height, the tread is level, the joint between this flight and the next is square. Check the next corner and the same is true. Walk the whole loop checking as you go, approve every junction individually, and you will arrive back at the step you began on having climbed the entire way. Nothing you inspected was wrong. The object cannot exist.

That is the room, and it is the same result as the one two doors back, arrived at through the eye instead of through arithmetic. Russell's box could not be built because a rule contained itself. This staircase cannot be built because sixteen local truths do not add up to a global one — and there is no local inspection that could ever have told you.

## Sixteen joints, and the impossibility has to live in one of them

<!-- @escher_staircase -->

```gdscript
# escher_staircase.gd:169
@export_enum("none", "hairline", "gap", "scaffold", "field") var seam: String = "none"
```

That line is the best thing in this room, because it is a dial whose settings are *where to put the contradiction*.

The artifact's own header spells the five out: smoothed into one quiet descending side and never named (`none`); gathered into a single closing riser you can point at (`hairline`); refused outright, so the loop is left open with two cut ends facing each other (`gap`); that same opening rigged with a tower and a landing so the walk becomes possible by cheating (`scaffold`); or spread evenly into all sixteen joints so the ring comes out level and no joint can be blamed (`field`).

The impossibility is conserved. It cannot be removed, only relocated — concentrated where it can be pointed at, or distributed until it is undetectable anywhere. That is exactly the property the room is arguing about consistency, expressed as a property of a Godot export.

The staircase here is placed as a bare token, so it stands at `none`: smoothed, and never named. The room's thesis is that the contradiction is in the whole rather than in any step, and its main body is set to the value that makes precisely that true. Whether that is a curatorial decision or an unset default, it is the right setting, and it is the reason the object reads as calm.

## The step you cannot take

```gdscript
# escher_staircase.gd:426
func climb_step() -> void:
```

The artifact has an API for walking it. Completing a full loop fires a `paradox_completed` signal. There is no `_input` handler in the file and no interaction volume anywhere in the scene, so nothing ever calls it — the header says as much, *has climb_step() API but no physical trigger*.

So the staircase whose desire is written down as *climb "up" forever and arrive where you started — feel the paradox in your legs* cannot be climbed. The signal for finishing the loop has no sender.

Worth sitting with rather than logging. The whole claim of this room is that walking the thing step by step is the procedure that fails to detect the fault — that local verification is exactly the method that cannot see a global contradiction. The one interaction that would let you perform that failure is the one that was not wired. You are left doing what the argument says you must do instead: standing back and taking in the whole, because there is no way to check it a piece at a time.

## Where you have to stand

<!-- @penrose_triangle -->

```gdscript
# penrose_triangle.gd:41
@export_enum("marker", "bare", "seam", "exploded", "sealed") var disclosure: String = "marker"
```

Three bars, three right angles, each corner square. The Penrose triangle — published by Roger Penrose and his father Lionel in 1958, described by them as impossibility in its purest form, and the direct source for Escher's *Waterfall*.

It has two settings and both matter. `disclosure` is how much the object confesses, running from a small marker through bare, to a visible seam, to exploded, to sealed. And `_is_at_sweet_spot` tracks whether you are standing in the one place from which the illusion coheres — because a Penrose triangle built in three dimensions is a real object with a gap in it, and there is exactly one line of sight along which the gap is hidden by perspective.

That second parameter is the honest one. The impossibility is not in the object; it is in the relationship between the object and a viewpoint. From anywhere else in this room the triangle is an ordinary bent thing with a break. Move to the sweet spot and it closes. Nothing about the bars changed.

Which reframes the staircase too. Consistency here is not a property the object has. It is a property of a *view* of the object, and the view is a position you can be standing in without knowing you chose it.

## Two prongs, or three

<!-- @impossible_trident -->

```gdscript
# impossible_trident.gd:13
## truth: two prongs become three; the drawing is consistent locally and impossible
##   globally — every junction is fine on its own, no assembly of them is.
```

The blivet, at the far end of the room. Read the base and you count two rectangular prongs. Follow them up and there are three round ones. There is no point along the drawing where the change happens; every band of it, covered at both ends, is a coherent picture.

It is the cleanest of the three because it removes the staircase's narrative and the triangle's perspective trick and leaves only the arithmetic: a count that is well-defined at both ends and different. The contradiction is not at a location. It is distributed across the transition, in the same way the staircase's `field` setting distributes it across sixteen joints so that no joint can be blamed.

## This is not a pipe

<!-- @magritte_pipe -->

```gdscript
# magritte_pipe.gd:2
# essence: sign != signified -- a procedural pipe mesh with label saying this is not a pipe
```

The one tangent, and the blurb seats it deliberately. Magritte's painting is not an impossible object — it is perfectly coherent — and its trouble is one level up: the image of a pipe is not a pipe, and the sentence saying so is not a sentence about pipes but about images.

It is in this room because the other three all depend on the same move. A drawing of a staircase can be locally valid in a way no staircase can, because a drawing is not the thing. The impossible objects are only impossible once you insist the representation is a claim about a buildable world. Take away that insistence and they are just marks that agree with each other locally.

Which is the room's argument pointed at itself: *every data structure is a Magritte painting*, as the header puts it. A model is consistent internally and says nothing, by itself, about whether the thing modelled can be.

## What checking cannot do

Consistency is not compositional. You can verify every step and learn nothing about the loop, and this is not a limitation of care or of time — it is a fact about what local verification is. The information that the staircase does not close is not present at any junction. It appears only in the sum.

That result is about to arrive in its formal version, which is worse, because there the whole under inspection is the checking system itself. Hold on to the trident: a count that is well-defined at both ends and different, with no place in between where it went wrong.

The contradiction isn't in any single step. It's in the whole.



## Brouwer_Intuitionism

Source: commons/maps/Brouwer_Intuitionism/final.md

SHA256: 0007c103b870c74b5166cb6f56eeb095b33282bddc3d47744edd387d9f683fd0

A staircase with a few steps at the bottom and nothing above them, and the nothing is not unfinished. It is the correct state.

Everything so far in this sequence has been a limit discovered from inside: a postulate that cannot be proved, a set that cannot be defined, a loop that cannot close. This room is the first of two answers, and it is the severe one. Brouwer's response to the crisis was not to patch the foundations. It was to say that a large part of what mathematics had been doing was never legitimate, and to give up the results rather than the standard.

The rule is one sentence. **To assert that something exists, you must produce it.**

## The third option

<!-- @excluded_middle_demo -->

```gdscript
# excluded_middle_demo.gd:9
# essence: P ∨ ¬P — the law of excluded middle; Brouwer: "not always!"
```

Two glowing spheres, P and not-P, with the disjunction between them, and a slider that flips the room between classical acceptance and intuitionistic doubt.

Classically, `P ∨ ¬P` is free. Every proposition is true or false; you may use that before knowing which. It is what licenses proof by contradiction: assume not-P, derive absurdity, conclude P — and you have proved P exists without ever exhibiting it.

Brouwer refused the licence. For him a mathematical statement is not a description of a pre-existing fact but a report on a construction, and a construction either has been carried out or has not. So there is a third state, and the tutorial in this room names it exactly: not true, not false, **not yet constructed**. The third option is the whole point, and it is not ignorance. There is no fact of the matter waiting to be uncovered, because on this account the fact is made by the proof.

This is one of two objects in the room you can actually operate. Hold on to that.

## Show me

<!-- @constructive_proof -->

```gdscript
# constructive_proof.gd:9
# essence: ∃x P(x) requires exhibiting x — no proof by contradiction allowed
# critical_parameter: the witness — without an explicit construction, the proof is rejected
```

The distinction, made into an object: knowing something exists, versus being able to point at it.

The classical proof that there exist irrational `a` and `b` with `a^b` rational is the standard demonstration of how wide the gap is. Take √2 to the power √2. Either it is rational, in which case you are done, or it is irrational, in which case raise it to √2 again and you get 2, and you are done. The proof is valid, it is three lines, and at the end of it you cannot say which of the two cases you are in. It has proved that a witness exists without producing one.

Brouwer's answer is that it has therefore proved nothing. The word *exists* was doing work it had not paid for.

What that costs is enormous, and honesty about the cost is part of teaching it: intuitionistic mathematics loses large parts of analysis, most of the theory of infinite sets, and any theorem whose only proof runs through contradiction. Brouwer accepted the loss. Hilbert, who did not, wrote that taking excluded middle from the mathematician was like taking the telescope from the astronomer.

## Always unfinished

<!-- @brouwer_choice_sequence -->

```gdscript
# brouwer_choice_sequence.gd:8
# essence: a₁, a₂, a₃, ... , ?, ? — each term chosen freely, never completed
# critical_parameter: time — the sequence unfolds perpetually, dots gently bobbing
```

A row of terms trailing off into question marks. Brouwer's choice sequences are his positive proposal, not just his prohibition: an infinite object that is never completed, only ever extended, where the next term is chosen and not determined. Infinity as a process rather than a finished set.

Now read the two lines above against each other. The essence says *each term chosen freely*. The critical parameter is `time`, and the sequence unfolds perpetually on its own. Its header names the missing piece without flinching — *could add ability to "choose" the next term* — so the object whose entire content is free choice runs on a timer and chooses for you.

That is the room's central irony and it is not confined to this one body. Of the four stations of the argument, two have controls and two do not; `constructive_proof` says *VR controls [missing]* in the same breath as declaring that the witness must be exhibited. A room whose claim is that nothing exists until a hand makes it, in which most of the hands are absent.

I would not repair that by wiring buttons to everything. The gap is more useful named than closed, because it is the actual condition the philosophy describes: the construction is *possible*, nobody has performed it, and on Brouwer's own terms that means it does not yet exist. The room is in the state it is teaching.

## The step that is not there yet

<!-- @constructive_staircase -->

```gdscript
# constructive_staircase.gd:14
## truth: the next step isn't true-or-false until you build it — existence is
##   construction, not the absence of a contradiction.
```

Built steps are solid. Above them there is nothing, and the nothing is not a gap in the model.

A classical mathematician looks at the unbuilt region and says: either the seventeenth step exists or it does not, we simply have not looked. Brouwer says there is no seventeenth step to have a property, and there will be one when someone builds it. Not hidden. Not undetermined. Absent.

That is the difference between an epistemic gap and an ontological one, and it is the hardest idea in the room, which is why it is worth having it as a thing you can stand at the bottom of and look up from.

## The one that does it properly

<!-- @cantor_diagonal_workbench -->

```gdscript
# cantor_diagonal_workbench.gd:6
# desire: learner viscerally feels uncountability — you can list "all" reals, and we
#   will construct one that isn't in the list, just by flipping the diagonal
```

Nothing in the room says why this bench is here, so here is why it earns its place: it is the model constructive proof, and it is the other object you can operate.

Cantor's diagonal argument is often taught as a proof by contradiction — assume the reals are listable, derive absurdity — but it does not have to be, and this bench does not present it that way. Turn the slider, the list grows, the diagonal extends, and a number is *built*, digit by digit, that differs from the first entry in the first place, the second in the second, and so on. At the end you are holding the witness. It is not that a missing real must exist; it is that here it is, and you watched it being made.

So this is what Brouwer is asking for, standing in the same room as the objects that cannot deliver it. The procedure scales, it terminates at any length you choose, and it hands you the thing.

## The two that assert

<!-- @angle_sum_triangle -->

<!-- @parallel_lines -->

Two objects have been carried forward from the first room and left here without explanation. They are the triangle whose angles sum to 180°, and the pair of parallel lines.

They are also, of everything in this sequence, the two artifacts that *assert rather than construct*. The triangle does not measure its corners; it prints the string `"60° + 60° + 60° = 180°"`, and the `curvature` knob its own header names appears six times in the file, every one of them inside a comment. The parallel lines have no script at all — the scene file is two line instances and two hand-typed transform matrices, parallel because somebody decided so and typed the numbers.

In a room about constructive proof, that is the entire lesson standing in the corner. Both objects state a result. Neither exhibits a witness. Both are, on the strict reading this room is teaching, claims for which no construction has been performed — and both are perfectly convincing to look at, which is the danger Brouwer was pointing at.

Whether they were placed here for that reason, I cannot tell from the map. They earn the position either way.

## What it costs

This is the harder of the two responses to the crisis, and it works by giving things up. Brouwer keeps certainty by shrinking mathematics to what has been made, and pays for it in theorems.

The next room takes the opposite route. Rather than refusing to assert what cannot be built, it refuses to panic about holding two assertions that contradict each other. Where Brouwer removes the third option and calls it *not yet*, Florensky keeps both options at once and declines to let the contradiction spread.

No existence without witness. No truth without a hand that built it.



## Florensky_Paraconsistent

Source: commons/maps/Florensky_Paraconsistent/final.md

SHA256: d83ca81cc54c89cdb3063afc981587d2748c67ad12d4e1150f8aa98a17360c18

A door frame with two leaves in it, one swung open and one shut, both there at once, and you can walk through.

The last room answered the crisis by giving things up: assert only what you have built, and lose the theorems that depended on assuming otherwise. This room answers it the other way. It keeps the contradiction, keeps working, and gives up something much smaller than you would expect.

What it gives up is a single inference rule. Not truth, not rigour, not consistency in any sense you would miss — one rule, called *ex falso quodlibet*, which says that from a contradiction anything whatsoever follows.

## The rule that does the damage

<!-- @both_true_gate -->

```gdscript
# both_true_gate.gd:15
## truth: P and not-P, and the world does not end — the contradiction is contained,
##   not detonated.
```

In classical logic, one contradiction is fatal to a whole system — not locally, everywhere. If both P and not-P are derivable then every sentence in the language is derivable, including every falsehood, and the system stops distinguishing anything from anything. That total collapse is why a single inconsistency is treated as catastrophic. It is not that the contradiction is embarrassing. It is that it spreads.

Paraconsistent logic blocks that step and nothing else. Contradictions may be derivable and are not permitted to imply arbitrary conclusions. The tutorial in this room states the containment exactly: *contradictions exist in the box; they cannot escape as anything follows.*

The gate makes it a thing you walk through. Both leaves are real, the frame holds them, and the room around it is not on fire. That is the entire claim, and the reason it needs to be a body rather than a sentence is that the sentence sounds like a trick and the door does not.

## A resting state, not an exception

<!-- @florensky_sphere -->

```gdscript
# florensky_sphere.gd:21
# critical_parameter: current_state — BOTH (A ∧ ¬A) is the resting state, not the
#   exception; observation collapses it to A or ¬A only briefly
```

A double-faced sphere whose skin reads from both sides, holding A and not-A on one surface.

Read the parameter carefully, because the ordering is the argument. BOTH is where the object rests. Looking at it can knock it briefly to one side, and it returns. This is the inverse of the arrangement you would expect and the inverse of the two objects across the room: the single-valued states are the transient ones, and the contradiction is the stable configuration.

Pavel Florensky was a mathematician, an Orthodox priest and an electrical engineer, and he argued that the deepest truths are antinomic — that a contradiction properly held is not a failure of thought but its highest form. He wrote that while working as a physicist in the Soviet Union; he was executed in 1937. The artifact's header calls the contradiction *a MODE OF BEING* rather than a defect, and that is a fair rendering of his position rather than a decoration on it.

One mechanical detail earns a look. To show both faces of one surface the artifact has to disable back-face culling, so the inside and the outside of the same skin both catch light. Everywhere else in this project turning culling off is a compromise; here it is the argument. A surface that can only be seen from one side cannot hold two readings.

## The foil, and it is a foil

<!-- @schrodinger_box -->

<!-- @superposition_display -->

```gdscript
# schrodinger_box.gd:12  ·  superposition_display.gd:10 — the same axis, twice
# critical_parameter: remainder — where the box puts the part of the state it cannot
#   show you (core | twin | seam | haze | witness)
```

Two quantum objects stand across from the two logical ones, and it would be easy to read them as the same idea in physics dress. They are the opposite idea, and the room is arranged so you can catch the difference.

The cat is both alive and dead until observed — and then it is not. Observation collapses the superposition to one branch and the other is gone. The display says the same thing about a qubit: `|ψ⟩ = α|0⟩ + β|1⟩`, genuinely occupying both, and genuinely resolving to one when measured. Both are contradictions *with an expiry*. The world tolerates them precisely because looking ends them.

Now notice what the two of them share and the other two do not. Both carry an axis called `remainder`, with five settings, and its job is to decide where the object puts *the part of the state it cannot show you*. Core, twin, seam, haze, witness — five architectures for the unshowable.

The gate and the sphere have no such axis, and do not need one. Nothing is being held back. Both leaves are in the frame; both faces are on the sphere. The quantum pair need a hiding place because their contradiction is not permitted to persist in view; the paraconsistent pair do not, because theirs is.

That is the distinction to leave the room with, and it is easy to lose: **collapse-on-observation is the foil, not the model.** Superposition resolves and paraconsistency refuses to. Placing them four metres apart is the room's whole method.

## Two answers, both live

Stand back and this room and the last one are a matched pair, and the sequence puts them in this order deliberately.

Brouwer takes the crisis to mean the standard was too loose: stop asserting what you cannot construct, accept a third state between true and false, lose the theorems. Florensky takes it to mean the demand was too strong: keep both assertions, block the explosion, lose one inference rule.

Neither repairs the foundation. Both are ways of continuing to work on a foundation that is known not to close, and they disagree about which piece of classical logic was the mistake. That they are both viable is the actual state of the field, and it is more interesting than a resolution would have been.

The last room takes that seriously in a way neither of these two quite does. If the gap cannot be closed by tightening or by loosening, then the gap is not a defect in the method — it is what the method runs on.

Paraconsistent logic doesn't resolve contradiction. It refuses the demand that contradiction must resolve.



## Crisis_Synthesis

Source: commons/maps/Crisis_Synthesis/final.md

SHA256: 0ac964e00ea1ba1baf047bb1de87f1b0a009aacb204dcc8b534a0e79e886f953

One line of text floating at eye height, and four wings leading off to the objects that earned each of its terms.

```
QFE = F − λE(S) + φΔE(S,t)
```

You have walked seven rooms of things that could not be closed: a postulate that would not be proved, a geometry that turned out to be a setting, a set that could not be defined, a staircase that checked at every joint and could not exist, and two incompatible ways of carrying on afterwards. This room does not resolve any of it. It says that the not-closing was the productive part.

## The formula, and which term is lit

<!-- @qfep_formula_3d -->

```gdscript
# qfep_formula_3d.gd:11
# critical_parameter: highlighted_term — the book-role privileges φΔE(S,t): it is the
#   queer generative term, the OPEN one
```

Three terms. `F` is fit — how well a system satisfies its own constraints. `λE(S)` is entropy, scaled by λ, subtracted: the pull toward order, toward closing, toward the crystal. `φΔE(S,t)` is the rate of change of entropy over time, scaled by φ, and it is added.

The third term is the one this whole sequence has been arguing for. The first two describe a system that wants to settle: maximise fit, minimise disorder, arrive somewhere and stop. On their own they describe exactly the ambition that Hilbert's programme had and that Gödel ended — a formal system that closes. The third term is what a system does when it cannot close, and its sign is positive.

The artifact's header is explicit that this is a reading rather than a calculation: *to be read, not solved*. Walk up to any single term and it brightens, and the sentence tilts. Under `F` it is an optimisation. Under `λE(S)` it is thermodynamics. Under `φΔE(S,t)` it stops being a balance sheet and becomes a description of something that keeps moving because it has nowhere final to arrive.

## Two dials you can hold

<!-- @lambda_slider -->

```gdscript
# lambda_slider.gd:15
# critical_parameter: lambda — the single number that controls order/chaos balance
#   across the entire QFEP system
```

λ from 0 to 1, on a rail with a colour gradient from blue through green to red, and it broadcasts to the whole room. At the low end the system is loose and noisy; at the high end it crystallises. The interesting readings are not at either end. The header names the zone: *the green zone at 0.3–0.5 where particles and color converge — the sweet spot finds you*.

<!-- @phi_slider -->

```gdscript
# phi_slider.gd:41
# critical_parameter: phi — rate sensitivity that determines whether the system fights
#   or welcomes transformation
```

φ from −1 to +1, purple through grey to gold, and it is the one that carries the argument. Negative φ is a system that resists change — the header says it feels heavy, with the particles falling. Positive φ welcomes it and they rise. Grey in the middle is a system indifferent to its own transformation.

The asymmetry is the point, and it is unusual for a parameter to be built with a preferred direction stated out loud. This one is: the generative reading is the positive one, and the room lets you set it the other way and feel the difference in your hand rather than be told.

## The edge, which you cannot move

<!-- @bifurcation_diagram -->

```gdscript
# bifurcation_diagram.gd:16
# essence: x(n+1) = r·x(n)·(1 - x(n)); period doubling cascade → chaos at r ≈ 3.57
# needs: VR slider for r [missing] — highlight plane tracks current_r but no physical controller
```

The logistic map. One line of arithmetic, one parameter, and a picture that goes from a single stable value, to an oscillation between two, to four, to eight, and then — at r ≈ 3.5699 — to chaos, with windows of order inside the chaos, at every scale.

It is here because it is the clearest available demonstration that the interesting behaviour of a system lives at its boundary and nowhere else. Below the cascade the map is dead: it settles and stays. Above it, structure at every magnification. And Feigenbaum's discovery is that the constants governing the cascade are the same for *every* system that period-doubles, which makes the edge a universal feature rather than an accident of this equation.

Two dials in this room can be grabbed. This one cannot — the highlight plane tracks `r` but nothing lets you move it. The room's claim is that the sliders show life only at the boundary, and the object that *is* the boundary is the one with no slider. Worth naming rather than filing: what you can hold here are the two parameters of the thesis, and the thing they are a thesis about is on rails.

## A room inside the room

<!-- @goedel_atrium -->

```gdscript
# goedel_atrium.gd:28
# needs: nothing. The room is self-contained, which is precisely its [point]
```

An atrium with a plinth at its exact centre, and on the plinth a model of the atrium, at one tenth scale, with a plinth at its centre. Default recursion depth is 2. Stand in the doorway and you can see your own doorway inside it.

Of everything in this sequence this is the object that most nearly *is* its subject rather than depicting it. A formal system strong enough to describe itself contains a description of itself, and that description contains a description, and the regress is not a bug in the encoding — it is the encoding working. Gödel's construction does exactly this: it arithmetises the syntax of arithmetic so that statements about proofs become statements about numbers, and then finds a number that says of itself that it has no proof.

The `needs` field of most artifacts in this project lists what is missing. This one says *nothing*, and gives the reason: self-containment is what it is for. It is the only artifact I have read whose statement of completeness is also its argument.

## The wings

<!-- @godel_statement_plaque -->

<!-- @russell_set_box -->

<!-- @escher_staircase -->

<!-- @florensky_sphere -->

Four objects return here from the rooms they came from: the plaque that asserts its own unprovability, the box that cannot contain itself, the staircase that checks and cannot exist, and the sphere that holds A and not-A at rest.

Three of those are crises. The fourth is a response. Brouwer is not here — the tutorial's own wing list names him, but no constructivist artifact is placed, and the blurb agrees with the map rather than with the tutorial. So the synthesis assembles three demonstrations that formal systems have an outside, plus one demonstration of how to keep working anyway, and the other way of keeping working — build it or do not assert it — is absent from the summit.

That is a real asymmetry and it is arguably the right one. Florensky's answer is the one this formula takes: hold the contradiction, do not let it detonate, keep going. Brouwer's answer is to shrink the system until it closes, which is precisely what the third term of the formula says a living system does not do. The missing wing is a position the room has rejected rather than forgotten.

<!-- @russell_paradox_workbench -->

```gdscript
# russell_paradox_workbench.gd:6
# desire: learner viscerally feels that self-reference per se is not the problem
#   (cell 4, S = {x : x ∈ x}, is consistent) — it is self-reference plus [negation]
```

A second Russell station, and it says the more precise thing than the box does: walk six set definitions on a slider and watch which ones close on a contradiction. The fourth is self-referential and perfectly consistent. Self-reference is not the fault; self-reference plus negation is.

That correction matters at the summit, because otherwise the sequence's moral collapses into *systems that look at themselves break*, which is not true and would make the atrium next door a warning rather than a demonstration.

## The outside is the engine

Hilbert wanted arithmetic proved complete and consistent from inside itself. Gödel showed that a system strong enough to be interesting can have one or the other and not both, and the interesting part is the qualifier: the incompleteness is a consequence of *strength*. A system too weak to describe itself can be complete. The price of being able to talk about yourself is a sentence you cannot reach.

Set that beside the logistic map. Below the cascade, order and no structure. Above it, structure that never repeats. Nothing rich happens in the settled regime. And set it beside the third term of the formula, added rather than subtracted: `φΔE(S,t)`, the rate at which a system's disorder changes, weighted by how much it welcomes changing.

The seven rooms behind you are not seven failures. They are seven places where a system met its own edge and something began there — non-Euclidean geometry from a postulate that would not close, type theory and modern set theory from a definition that ate itself, computability from a sentence that could not be proved. Each crisis produced the field that came after it.

The crisis was never the problem. The crisis is the engine.



# qfeplaboratory

Declared order: QFEP_Introduction → QFEP_F_Term → QFEP_E_Term → QFEP_Lambda_Spectrum → QFEP_Phi_Term → QFEP_Edge_Of_Chaos → QFEP_Sandbox → QFEP_Synthesis

Museum map-authored order differs: QFEP_Introduction → QFEP_E_Term → QFEP_Lambda_Spectrum → QFEP_Phi_Term → QFEP_Edge_Of_Chaos → QFEP_Synthesis. Treat this as route drift to inspect, not an editorial recommendation.


## QFEP_Introduction

Source: commons/maps/QFEP_Introduction/final.md

SHA256: c768c5bb38adc6ea85cdb257517c5bf3be0cdc69f0cc3e26bf3646f2b0246f2a

# Four controls, one result

Can two different arrangements of a model produce the same number?

<!-- @qfep_balance_workbench -->

Move one control on the workbench and watch both the numerical result and the shape of the four-axis display. Then try changing another control to return the result towards its earlier value. Look for two configurations that look different on the axes but give nearly the same total.

The console combines four adjustable quantities. Its current calculation is F minus lambda times E, plus phi times a fixed change value of 0.3. Raising F raises the result. Raising E lowers it in proportion to lambda. Raising phi adds more of the fixed change contribution. When lambda is zero, moving E does not affect the total through that term.

Try the special case with lambda at zero before comparing more complicated settings. Watch what happens to the total when E changes, then give lambda a nonzero value and repeat. The contrast reveals a dependency: E’s contribution passes through another control. A slider can move through its full range without affecting one particular result when its weight is zero. That is a property of this calculation, not evidence that entropy is absent from every surrounding object.

This is an operational introduction to the project’s QFEP expression, QFE = F − λE(S) + φΔE(S,t). F names a modelling or free-energy contribution, E an entropy contribution, lambda their relative weighting, and phi the weighting attached to change. The console lets you inspect that arithmetic. It does not measure these quantities from a living system, and its fixed change value is not an observed rate.

The named phase on the display is selected by comparing the knob arrangement with authored reference configurations. A changing name therefore reports proximity to a project example; it does not announce an experimentally detected physical phase transition.

Return to your two nearly equal totals. What distinction did the total lose? One number can summarise several contributions while concealing how they compensated for one another. Keeping the separate values visible prevents a convenient summary from becoming the whole account.

For a more demanding version, the room could receive measured quantities from one clearly specified simulation. It would then need to show how those measurements were defined and how changing the weights affected a particular decision. That is the route from a manipulable formula to an accountable model.

<!-- @ -->

The next room starts with a smaller, computable question: what makes an outcome easy or difficult to predict?



## QFEP_F_Term

Source: commons/maps/QFEP_F_Term/final.md

SHA256: db3e855ee8ee0bd10b5850a202ab459792189145e0c15a07bdce6d9f6c08fb98

# Predictable according to what model?

When a pattern looks orderly, what exactly can you predict?

<!-- @shannon_workbench -->

Move p towards one end of the workbench’s rail and inspect the bit grid. Then bring it towards the middle. Before reading H, predict which setting would make guessing the next bit easier. Compare p near 0.1 with p near 0.9 as a second pair.

Near either end, one bit value predominates. Near the middle, the two values are more balanced. The entropy readout rises towards the middle and falls towards both ends. Reversing which bit is common can preserve the amount of uncertainty even though the grid’s dominant colour changes.

Look at individual cells after forming your expectation from p. The setting describes a probability, not an instruction that every small neighbourhood must display exactly that proportion. A patch can look unusually mixed or unusually uniform within the same sample. Distinguishing the chosen source from its finite realisation helps you avoid treating one striking patch as a refutation of the parameter. It also keeps the model’s prediction separate from the particular observation you are trying to explain.

The workbench calculates binary Shannon entropy from the chosen probability: H(p) = −p log₂ p − (1−p) log₂(1−p). The grid is one finite sample of the specified source. H describes uncertainty under that source model; it is not a guarantee about the exact shortest encoding of this particular displayed grid.

The room’s F term asks a related but different question about a model’s fit and prediction. Predictability under an assumed distribution, a realised prediction error and variational free energy are not interchangeable quantities. This display computes the first of those. It gives us a precise starting observation without pretending its H readout is already a measurement of F.

Imagine a predictor that always expects zero. It would usually succeed near one end of the rail and usually fail near the other, although the entropy can be the same at those two settings. The example separates uncertainty in a source from mismatch between a source and a particular predictor.

The next useful addition would display that predictor’s expectations and errors beside the grid. It could then change its expectations while the source stays fixed. A learner would see whether improvement came from an easier world or from a better model of it.

<!-- @ -->

The entropy room next counts alternatives explicitly, asking which possibilities the model has allowed into its world.



## QFEP_E_Term

Source: commons/maps/QFEP_E_Term/final.md

SHA256: 4b6e0ea0d9b5cfe06cd4c3922fbe411626802356d9d1f8b0eafd4f22504ee1dc

# Counting what could happen

How quickly can a few choices become many possible futures?

<!-- @entropy_fan -->

Start at the narrow origin of the fan and follow one branch to its end. Count how many choices appear at each level. As the display cycles through its branching arrangements, predict the number of final leaves before checking the readout.

With one continuation at each of four levels, there is one final path. Two continuations per level give sixteen possible leaves. Three give eighty-one. The number of outcomes grows by multiplication because each earlier choice can be followed by several later choices.

Pick two leaves that share the beginning of their paths. Trace backwards until you find the last common branch, then forwards to see where their futures separate. The leaves are different outcomes even though much of their history is identical. This gives you a way to count without treating every end as an unrelated event: shared beginnings organise the possibilities, while later branches multiply the distinct completions that can follow from those beginnings.

The display reports an entropy based on the logarithm of the number of available outcomes. This simple count corresponds to treating those outcomes as equally possible. The logarithm turns multiplication across independent choice stages into addition, making the total easier to compare across different depths of branching.

The assumption about equal possibilities matters. Eighty-one drawn leaves do not tell you that a traveller is equally likely to arrive at each one. A strongly preferred branch could make the actual distribution much more concentrated. To model that situation, we would need probabilities as well as an inventory of paths.

Compare this with the bit workbench. There, the probability changed while the possible bit values remained the same. Here, the fan changes the number of continuations that the diagram offers. Both affect uncertainty, but they are different operations on a model.

Now choose a branch and imagine it being closed. Distinguish an option that was available and then prohibited from an option never drawn at all. A picture of the permitted future can hide the history of how the permissions were chosen. Counting its leaves cannot recover those omitted alternatives.

For a proposed extension, let visitors mark one closed path and preserve its outline. The fan could then show both the current count and the choices excluded from it, instead of making absence look inevitable.

<!-- @ -->

Lambda’s hall will turn a balance between repetition and variation into a spatial invitation. Ask what its preferred route leaves to either side.



## QFEP_Lambda_Spectrum

Source: commons/maps/QFEP_Lambda_Spectrum/final.md

SHA256: d9c6a196f31f52fc58b861a2a7cbaf5555cca54bd2b0a4dc712a22e9c3d8eb4e

# The path the hall recommends

Which part of this hall invites you to stay, and how does it make that invitation?

<!-- @lambda_hall -->

Look towards the repeated lattice on one side, then towards the dispersed moving forms on the other. Compare the rows between them. Locate the lit route and decide what makes it appear preferable before accepting its position as the answer to the room.

The hall distributes an authored contrast across space. Regular repetition occupies one extreme; broken and animated forms occupy the other. Intermediate rows interpolate between them. The highlighted route lies at a chosen lambda value, making a numerical setting into something you can orient yourself towards.

Choose one repeated element and compare its neighbours along the regular side. Then look for a comparable relation among the moving forms. Describe what becomes easier to anticipate and what becomes harder to locate again. This keeps the comparison in the encounter itself: a repeated interval can support orientation, while a change of position can draw attention to a particular element. Those are observable consequences of the staging before either side receives a theoretical label.

In the project formula, lambda weights the contribution associated with entropy. On the introductory console, changing it altered an arithmetic balance. This hall instead provides a spatial analogy for that weighting. Its forms are built from their assigned positions across the spectrum; it does not measure the entropy of each structure and then discover where it belongs.

The lit route is therefore a curatorial argument. Its chosen value is not a universal threshold at which life, creativity or queerness appears. A welcoming middle can be an evocative design without becoming a result established by physics.

Try reversing the expected evaluation. Find something the repeated side offers that the dispersed side makes difficult: a landmark, a dependable interval, a place to compare small differences. Then find something the dispersed side permits that the regular side suppresses. Neither observation needs to erase the other.

The entropy fan asked which alternatives were available. The hall adds another question: which available alternatives are made inviting? A pathway, colour or rhythm can recommend an answer before any explanatory text does.

For a future comparison, move the lit route while keeping the structures fixed. Would a group’s preferred position change? That experiment would examine the architecture’s influence separately from the numerical vocabulary used to describe it.

<!-- @ -->

Phi introduces time. A system’s present arrangement and its response to change will no longer be the same question.



## QFEP_Phi_Term

Source: commons/maps/QFEP_Phi_Term/final.md

SHA256: 207244a11537a994772442c850d74b68b010448eb2fef08a4d2cc93738661b3a

# Giving change a sign

Can change have a direction without that direction already meaning improvement?

<!-- @phi_slider -->

Move PHI through zero and watch the particles belonging to the slider. Compare a negative setting with a positive setting of similar magnitude. The local feedback changes direction and colour: one side sends particles down, the other sends them up.

The handle gives you a signed parameter. Its sign distinguishes two directions of weighting, while its distance from zero gives the magnitude. In the project expression, phi multiplies a term associated with change in entropy. A weight, a measured change and the resulting response are three separate quantities, even when a display uses one colour to connect them.

Compare the midpoint with two settings on opposite sides. Crossing zero changes the sign; moving further along the same side changes magnitude without another sign change. These are distinct comparisons you can repeat on the rail. If you describe both simply as “more change”, you lose what the signed control makes available. Name the direction first and then how strongly it is weighted, before asking what a receiving system would do with that value.

The slider’s particles make the sign easy to recognise. They are visual feedback for its own value, not an instrument measuring whether a nearby system is becoming more open, more rigid or more alive.

<!-- @transforming_pattern -->

Now watch two cells in the transforming pattern. Compare their rises, sizes and colours over time. They share prescribed waves but meet those waves at different phases, so the whole can keep changing while individual places follow related rhythms.

This pattern currently runs independently of PHI. Moving the nearby handle does not control its waves. The room has two representations of change beside one another; a causal experiment connecting them remains to be built.

You can nevertheless make a careful observation: equal-looking states at two moments need not describe the same trajectory. One cell may be rising through a height while another is falling through it. A snapshot loses that direction unless the representation preserves some history.

Consider a pattern worth protecting from an imposed change. Downward, negative or resistant need not mean bad. Conversely, rapid variation can erase something valuable. The sign of a project parameter cannot decide which history deserves continuity.

<!-- @ -->

The next room provides a control connected to a changing pattern. We will keep the parameter, the observed response and the interpretation distinct while comparing them.



## QFEP_Edge_Of_Chaos

Source: commons/maps/QFEP_Edge_Of_Chaos/final.md

SHA256: 8009d98019dee94d7af9f418e9dbe2bff90926f93dcf8b8629076121825b1c59

# A pattern and the way we drive it

Which changes belong to the model, and which belong to the way its calculation is run?

<!-- @edge_of_chaos_unlocked -->

Keep SIM SPEED steady and move LAMBDA slowly. Give the image time to respond before choosing another value. Use RESEED to compare a fresh start at the same setting. Describe what persists, spreads or disappears without relying on the regime name supplied by the display.

The display updates two concentrations on a grid. Local reaction terms change their amounts, while diffusion exchanges concentration with neighbouring cells. The resulting image comes from repeated local updates rather than from replaying a finished picture.

Choose a visible feature small enough to follow, such as the boundary between two coloured regions. Compare its persistence through several updates with the overall impression of activity across the field. A rapidly changing picture can contain local features that last, while a nearly uniform picture can still undergo numerical updates. Describing both scales gives you a better observation than declaring the whole image ordered or chaotic from one glance at its most conspicuous movement.

LAMBDA follows one authored route through several reaction-diffusion parameters. It changes feed, removal and diffusion coefficients together. If the picture changes, the comparison establishes a response to that combined adjustment; it does not isolate the effect of one chemical parameter or discover a universal balance point.

Initial conditions matter too. Reseeding changes the starting concentrations while leaving the chosen parameter setting available for comparison. A pattern that survives one start may not appear in the same way from another. Keep a record in words: what feature are you comparing, and over how much observed time?

The present numerical update has a further limitation: some settings can be dominated by the size of its computational step and by values reaching their allowed bounds. The picture therefore cannot currently certify physical chaos, criticality or a privileged region for life. This is a specific repair needed before stronger claims can be tested reliably.

The hall’s recommended middle was an architectural choice. Here a measured transition would require a stable numerical experiment and a defined observable, such as persistence or spatial correlation, examined across controlled settings. An evocative label cannot perform that work.

As the next development, compare the same starting field under a smaller, controlled timestep while keeping the physical duration comparable. Agreement would give more confidence that the visible difference belongs to the model.

<!-- @ -->

The sandbox extends the question of control across several objects. First we must establish which objects actually receive each change.



## QFEP_Sandbox

Source: commons/maps/QFEP_Sandbox/final.md

SHA256: 83f19c6d22526e30b752d9ecac115b28d2116fc3edd43a36ea8e08793dca736f

# Where the control reaches

How do you tell a control that changes a number from one that changes a system?

<!-- @lambda_slider -->

Move LAMBDA and watch its own value and colour. Keep PHI still. Choose two settings far enough apart to recognise, then return to the first. This gives you a repeatable comparison of the control itself before involving any other object.

The slider exposes a value between zero and one. In the project vocabulary, that value weights one contribution relative to others. A number displayed on a control becomes a system parameter only when the system uses it in its next calculation.

<!-- @phi_slider -->

Now leave LAMBDA steady and move PHI across zero. Compare the direction of its local particles and the sign of its printed value. PHI’s rail here extends from negative to positive values, so its midpoint has a meaning different from the midpoint of LAMBDA’s unsigned range.

Repeat one handle movement while attending only to its local feedback. Then repeat it while attending to a surrounding object. These are observations of different parts of the room, and agreement in timing would still need a demonstrated connection before it counted as a controlled response. The local readout provides a reference for what you set. A receiver’s own readout would provide the missing reference for what it actually used in the experiment.

The intended sandbox would let these controls vary a shared experiment. That connection is not complete in the current room: the surrounding reactor and particle field are not yet reliably linked to these handles. Their continuing movement therefore cannot be used as evidence that they received the values you selected.

This is a boundary of the present encounter, not a claim that independent motion is what the model predicts. We can already compare the two controls and their local feedback. To compare the formula’s effects, the room needs one clearly identified receiver whose actual input values are visible beside its response.

A useful next experiment would keep PHI fixed, change LAMBDA, and measure one property of that receiver. It would then restore the initial conditions before exchanging the roles. Changing both at once could produce an interesting picture while concealing which change caused it.

Give the proposed experiment a concrete observation: a deformation, a persistence time or a numerical error. “More alive” would still require an explanation of what that phrase is intended to describe.

<!-- @ -->

The synthesis specimen supplies a smaller completed connection: its own two controls alter the mechanics of one body.



## QFEP_Synthesis

Source: commons/maps/QFEP_Synthesis/final.md

SHA256: 5b9f36701d1416b8fa4b3836659aa9d3e9d1d061354851a0d6b4532d86a3cc25

# What should this body keep?

Which kind of stability are you asking this body to preserve?

<!-- @queer_morphology_specimen -->

Use the specimen’s own LAMBDA and PHI sliders. Hold one steady while changing the other, and compare the body’s shape and continuing movement. Watch for long enough to separate a persistent response from the timed breathing already present in the specimen.

LAMBDA changes the mapping to stiffness and pressure. PHI changes damping and drag. These properties affect different aspects of the response: resisting a deformation is not the same operation as reducing ongoing motion. A body can resist changing shape while still retaining movement, or deform readily while movement dissipates quickly.

Watch a change settle over time rather than comparing only two instantaneous shapes. A shape can look similar at two moments while the continuing movement differs. Conversely, a temporarily different shape may return towards a familiar arrangement. The separate controls invite you to name these distinctions: resistance to deformation, persistence of motion, and the effects of pressure. Following one region of the specimen through several moments can make the comparison easier than watching every moving surface at once.

The mapping is authored for this specimen. Stiffness decreases across the lambda range, pressure has a designed peak near the middle, and signed phi changes the damping and drag values. The visible response makes those choices inspectable; it does not establish that nature uses the same numerical scale.

Compare two combinations outside the named presets: relatively high stiffness with low damping, and relatively low stiffness with high damping. Which difference do you notice first? Avoid reducing both observations to one word such as rigid or fluid. Naming the distinct mechanical properties gives you a more useful account of what changed.

The laboratory has now used its terms in several ways: arithmetic weights on a console, spatial analogies in a hall, and controls mapped to a body’s mechanics. Their shared vocabulary invites comparison, but the mappings need to remain explicit. Even PHI’s signed range here differs from its range on the introductory console.

A responsive specimen is not an assay of queerness or a test for life. The question its name opens is what forms of continuity and variation a model makes available. A future observation could preserve a trace of deformation over time, letting different responses be compared beyond their immediately attractive appearance.

<!-- @ -->

Post-crisis begins with representation itself. After learning to name a model’s choices, ask whose distinctions those choices make clear and whose they compress.



# postfoundationscrisis

Declared order: CriticalAlgorithms_Algorithmic_Bias_Visualization → CriticalAlgorithms_Applied_Ethics → SpeculativeComputation_Paraconsistent_Engineering → SpeculativeComputation_Situated_Computation → SpeculativeComputation_Collective_Knowledge → SpeculativeComputation_Rhizome_Network → AdvancedLaboratory_Lab_Equipment_Simulation → PostCrisis_Synthesis


## CriticalAlgorithms_Algorithmic_Bias_Visualization

Source: commons/maps/CriticalAlgorithms_Algorithmic_Bias_Visualization/final.md

SHA256: cce23fb029848631f935bd816aa88ecab84dfb084a25282579371ee79c4a6c80

# Less room for a distinction

Which differences become difficult to recognise when a representation gives some words less room?

<!-- @bias_from_inside -->

Choose two warm-coloured labels and keep both in view while moving PERSPECTIVE. Compare their changing separation with two grey labels. Stop partway through the movement and notice which words are still easy to distinguish individually.

The warm group compresses into a smaller region while the grey group spreads and moves away. The words themselves remain, but the space available to tell them apart changes. Presence in a representation is therefore different from being represented with useful distinctions.

The source makes the operation inspectable:

```gdscript
var pos := _marginalized_positions_default[i].lerp(
    _marginalized_positions_compressed[i], blend
)
var xf := Transform3D.IDENTITY
xf.origin = pos
_marginalized_multimesh.multimesh.set_instance_transform(i, xf)
```

The index i keeps a word attached to its two authored positions. lerp blends those positions; blend chooses how far the word has travelled. The same operation learned in transformation can make a distinction easier or harder to see. The script calls this perspective, but it changes the represented geometry. It is not a camera command.

An embedding places items in a numerical space so that relations between positions can be used in later calculations. This exhibit stages an authored analogy for that operation. Its positions interpolate between two designed arrangements; they are not measured coordinates from a trained language model. The slider changes the geometry rather than retraining a model or changing only your camera.

That limitation helps keep the question exact. The piece can show what spatial compression does to your ability to separate its labels. It cannot, by itself, establish the distances those same words occupy in an actual system. An empirical claim would need a named model, a documented measurement and a comparison that someone else could check.

Now scrutinise the groups chosen for the sculpture. Words such as “queer”, “disabled” and “refugee” do not name interchangeable experiences. Nor are “normal”, “professional” and “objective” equivalent claims. The exhibit risks repeating a flattening if its two colours become a sufficient account of everyone they contain.

Choose one distinction within a colour that you want the representation to retain. For a future version, compare several groupings and ask the people represented which distinctions matter to them. Greater distance alone will not guarantee a better account, but it can make an otherwise hidden question available.

<!-- @ -->

The applied-ethics room moves from word positions to furniture. A plan can distribute the ability to participate before anyone begins speaking.



## CriticalAlgorithms_Applied_Ethics

Source: commons/maps/CriticalAlgorithms_Applied_Ethics/final.md

SHA256: 848f231e0387442793524c156e3af9ed16a14d8e022d957327d8a54770f708bd

# Before the first person speaks

Who does this room make easiest to address?

<!-- @room_shape_demonstrator -->

Walk around the two miniature rooms. In the long-table plan, locate the head chair and compare its size with the other chairs. In the circular plan, choose one seat and imagine speaking from it. Trace the distances to the other positions rather than simply choosing the greener model.

The long table gives one position a conspicuous role. Its six smaller accompanying chairs carry less visual weight. The other model places six equal chairs around a round table. The comparison changes more than an outline on the floor: it changes relative size, position and the implied relation between participants.

The source makes the operation inspectable:

```gdscript
for i in 6:
    var a: float = TAU * float(i) / 6.0
    var chair := _make_chair(chair_color_distributed)
    chair.scale = Vector3(s, s, s)
    chair.position = origin + Vector3(cos(a) * 0.4 * s, floor_y + 0.1 * s, sin(a) * 0.4 * s)
    _add_part(chair)
```

Six iterations divide a full turn, TAU, into equal angles. cos and sin place each chair on a ring around origin. The little circle carries the arrays, transformations and waves we have already learned. Equal spacing is what this loop guarantees. Equal opportunity to speak would require another kind of evidence.

These are affordances and invitations. A head position can make it easy to identify a speaker; a circle can support addressing several neighbours around a shared centre. Neither miniature contains actual speech, listening or an agreement about whose turn comes next. The geometry proposes conditions under which those activities might happen.

Notice how the exhibit colours its own argument. Red singles out authority; green recommends the distributed arrangement. That visual judgement arrives before you have tested whether the plan meets a particular group’s needs. Looking critically at a model includes looking at the persuasion built into its presentation.

Find one use for the head position that you would preserve, then one difficulty the circle would not automatically solve. A designated interpreter, a speaker who needs a clear sightline or someone who cannot easily turn towards every other participant can complicate the familiar good-circle story. These possibilities call for observation with people, not a verdict from chair shapes alone.

A future version could compare actual sightlines and turn-taking across the two plans. The ethical question would become a design question with observable consequences: which participant gained access, which difficulty remained, and what change should follow?

<!-- @ -->

The next room lets two requirements meet without immediately deleting one. Participation can be shared while the resulting claims still conflict.



## SpeculativeComputation_Paraconsistent_Engineering

Source: commons/maps/SpeculativeComputation_Paraconsistent_Engineering/final.md

SHA256: 14598897b9a317663615e3999c3f92a57bcd48393f8a1a8a57a27b2ac31d33e0

# Keeping the disagreement visible

Must one account disappear before two accounts can share a system?

<!-- @merge_conflict_visualizer -->

Trace branch A and branch B towards the lit junction. Inspect what remains visible on either side of that meeting point. Before deciding which branch should win, give each one a source and a reason to have arrived there.

The sculpture keeps two versions present around a conflict marker. It does not merge actual files or execute rules of logical inference. Its useful first gesture is spatial: an unresolved relation can be represented without erasing the parts that made the relation difficult.

The source makes the operation inspectable:

```gdscript
func _build_resolved() -> void:
    _build_pillar(branch_a_color, Vector3(0, 0, 0),
        Vector3(0.2, pillar_height, 0.2), "branch A", 0.0, false)
    _build_pillar(branch_b_color, Vector3(BASE_X, 0, 0),
        Vector3(0.2, RESOLVED_STUMP_H, 0.2), "branch B", 0.0, true)
```

There is a second arrangement in the source that this placement does not show. In resolved, A keeps its full height and B becomes a labelled stump. The two builder calls make resolution visible as a change in what remains. That is an authored picture of a decision, not a proof that the decision was warranted.

Try a concrete disagreement. One report says a door is open; another says it is closed. Adding times may reconcile the reports. Adding the door’s identity may reveal that they concern different doors. Preserving provenance gives us ways to investigate before treating every difference as a contradiction about the same thing at the same time.

Formal paraconsistency concerns the inference rules themselves. In a paraconsistent logic, a contradiction need not license an arbitrary conclusion. It does not mean accepting every claim or abandoning the distinction between supported and unsupported inference. [Basu and Roy’s research paper starts from this failure of explosion when developing more general definitions.](https://arxiv.org/abs/2112.00357)

The current junction is an analogy for retaining a conflict, not a demonstration of that formal property. The next useful addition would expose a small rule table: after entering both a proposition and its negation, which consequences remain available, and which unrelated conclusion still cannot be derived?

Return to the pillars and imagine a resolution that shortens one to a stump. What information should remain so the decision can later be reconsidered? Keeping a source, a date and the rejected alternative does not make revision automatic, but it prevents a settled display from hiding how settlement occurred.

<!-- @ -->

Situated computation takes up that provenance. Four panels will judge one subject differently, and their positions will become part of what the judgement tells you.



## SpeculativeComputation_Situated_Computation

Source: commons/maps/SpeculativeComputation_Situated_Computation/final.md

SHA256: a669b53f70ed94170d18888fe1f41b7a68e6c73f73b70deaed128c6bead3b45a

# Four verdicts about the same subject

What changes when the subject stays the same but the source of the judgement changes?

<!-- @situated_readout -->

Read the subject identifier on all four panels. Keep it fixed in your comparison, then note the verdict, the confidence and the footer on each. Look back at the first panel after reading the others: it has not become a different subject because another description is available.

SUBJECT #4729 appears as ORDERLY, CREATIVE, DANGEROUS or IRRELEVANT across the four positions. The associated percentages differ too. The room makes a judgement’s location visible instead of presenting one description as if it came from nowhere.

The source makes the operation inspectable:

```gdscript
var pos := global_position
var key := _resolve_quadrant_key(pos)
var verdict: Dictionary = QUADRANT_VERDICTS.get(key, QUADRANT_VERDICTS["NW"])

_verdict_label.text = verdict.label
_verdict_label.modulate = verdict.color
_confidence_label.text = "confidence %d%%" % int(verdict.confidence * 100.0)
_footer_label.text = "view from %s (%.1f, %.1f)" % [key, pos.x, pos.z]
```

The dictionary supplies a verdict and a confidence; the footer supplies a location. There is a revealing extra decision: this hall explicitly assigns NW, NE, SW and SE through its map tokens. That override takes precedence over the position-based fallback. The four-way disagreement has been composed for us. The percentages have not been earned by measuring the subject.

These are four authored readouts. Each panel retains the verdict assigned to it; your movement changes which panel you read. The percentages are supplied examples, not calibrated probabilities calculated from evidence about a real person. A high number in this room therefore cannot establish that its description is more trustworthy than a lower number.

Separate four parts of a claim: the subject, what is asserted, how certain the speaker appears, and the conditions under which the assertion was produced. Keeping the subject constant helps expose changes in the other parts. It does not imply that all four predicates have the same meaning or answer the same question.

Choose DANGEROUS and ask what evidence would make that judgement accountable. Dangerous to whom, under which circumstances, and according to what consequence? Then apply an equally precise question to CREATIVE. A favourable word also needs criteria; situatedness is not a licence to stop checking an appealing claim.

For the room’s next experiment, each panel could reveal a distinct criterion and the observation it used. A visitor could then compare disagreement caused by different evidence with disagreement caused by different definitions. The current four views supply the scaffold for that comparison.

A small spider moves among the readouts. It can notice and follow you; its controller can bite. The panels do not direct this creature, and their confidence numbers do not describe its behaviour. For now, keep the two encounters distinguishable: an assigned judgement on a screen, and a rule that acts on a body. What would we need to observe before calling either one dangerous?

<!-- @ -->

Collective knowledge asks how contributions from different positions can become a common object without losing the evidence and disagreement that make it revisable.



## SpeculativeComputation_Collective_Knowledge

Source: commons/maps/SpeculativeComputation_Collective_Knowledge/final.md

SHA256: 05ebdd15e35c097636a8b026da75aed417fb3356cf386ae3c38a8dc3ae719c4f

# More contributions than contributors

When many marks accumulate, what makes the result knowledge rather than a pile?

<!-- @peer_production_tool -->

Follow a packet from one of the rim nodes into the central structure. Watch the new facet appear. During one growth cycle, compare a contribution from a node you have already seen with one from a new source. The number of contributions and the number of contributing sources need not increase together.

The exhibit turns contribution into an arrival event. A packet comes from one of twelve positions and adds a piece to a shared form. The form grows to a fixed capacity and starts again. Its visible coherence comes from an assembly rule that knows where to place each arriving facet.

The source makes the operation inspectable:

```gdscript
_placed += 1
_edits += 1
# count distinct contributors this version
if peer_idx >= 0 and peer_idx < _seen_peers.size() and not bool(_seen_peers[peer_idx]):
    _seen_peers[peer_idx] = true
    _contributors += 1
```

Every accepted facet increments the edit count. The Boolean array _seen_peers lets the same source count only once within a version. On the next version those flags clear while the totals persist. A number labelled CONTRIBUTORS can therefore outgrow the twelve source positions. The code tells us what was counted more precisely than the label does.

That is a simulation of accretion, not a live collaborative editor. The peers are generated positions rather than people logged into the museum, and the incoming material is accepted without a dispute over its content. The animation demonstrates one way many sources can feed one object while leaving the harder question of validation open.

Collective knowledge needs more than participation counts. A contribution may repeat an error, correct an earlier claim, supply a missing case or disagree with an accepted account. Those actions can add little to a simple count while changing the usefulness of the shared result dramatically.

The previous room kept four viewpoints separate. Here the common centre can make their differences disappear into a continuous object. Follow a facet and ask what you can still recover about its origin after it joins the whole. Does the shape preserve a reason for accepting that contribution, or only the fact that something arrived?

For a proposed extension, mark one contribution as disputed and keep its source visible. Let revision change an existing piece instead of always adding another. The comparison would show how maintaining knowledge differs from celebrating uninterrupted growth.

<!-- @ -->

The rhizome will make the pattern of connection itself grow. A shared result can have many contributors while its network still develops uneven centres.



## SpeculativeComputation_Rhizome_Network

Source: commons/maps/SpeculativeComputation_Rhizome_Network/final.md

SHA256: 2aef4af9a49d67152457652213b54be6e71628c4dcebf4d8c9ca7533e3f4875d

# Growing without a named root

Can local connections build a network without first choosing its centre?

<!-- @rhizome_grower -->

Watch for a new node and follow the segments it adds. Compare a crowded part of the structure with a sparse part. Predict which existing nodes are likely to receive the next connections, then check the new shoot against your prediction.

The exhibit starts with two nodes. A new shoot is placed within a bounded region and linked to up to three of the nearest existing nodes. Repeating this rule builds a graph from local proximity. The node and edge counts record its growth until the forty-node capacity is reached and the display starts again.

The source makes the operation inspectable:

```gdscript
var targets: Array = _nearest_indices(pos, links_per_node)
var new_idx: int = _add_node(pos)
if new_idx < 0:
    return
var t: int = 0
while t < targets.size():
    _add_edge(new_idx, int(targets[t]))
    t += 1
```

The neighbour search runs before the new node is inserted, so the shoot cannot select itself. It can only select nodes already present. Up to three nearest neighbours receive a link. The rule creates a graph without declaring a family tree; it also gives earlier and nearby nodes opportunities that later or distant nodes do not have.

No vertex is assigned a root role. There is no stored family tree telling every later node to descend from one privileged ancestor. Multiple connections permit the growing structure to contain routes that differ from a simple parent-and-child hierarchy.

The rule still has consequences worth inspecting. Earlier nodes are available to be chosen for longer, and spatially well-placed nodes can attract many nearby additions. A network without a designated root can develop busy regions and uneven degrees. “No root” describes part of the construction; it does not prove that every participant has equal influence.

Find a node with several visible links. Imagine removing it and predict whether the remaining pieces would still connect. Graph theory gave us the tools to ask this precisely. The present exhibit does not offer deletion, so treat the prediction as a proposed test rather than evidence that every rhizome repairs itself.

The peer-production tool gathered contributions at one centre. This growth rule distributes connections through space, but geometry still acts as a gatekeeper: being nearby makes a relationship available. A future variant could let a new node choose a distant connection and compare the network’s routes and dependencies afterwards.

<!-- @ -->

The assembly laboratory adds a catalogue and a target arrangement. When connections must form a recognisable body, we can ask which bodies the catalogue has already imagined.



## AdvancedLaboratory_Lab_Equipment_Simulation

Source: commons/maps/AdvancedLaboratory_Lab_Equipment_Simulation/final.md

SHA256: bb045080b41cf96b870f37eb12ba04af2b32fa1cc657e267609030bedb600bf4

# The inventory before the body

How can one collection of parts become several recognisable structures?

<!-- @MolecularDesigner -->

Choose a recognisable piece in the floating inventory and keep it in view as an assembly begins. Watch it approach a position and acquire relations to other pieces. Stay through another floating phase and a later assembly. Notice whether the same part instance keeps its shape and colour when it takes a new role.

The scene alternates floating and assembling phases, with about ten seconds assigned to each. It moves through authored assemblies drawn from a catalogue that includes bodies, furniture and other structures. Bond lines update between the assigned parts as they move towards their targets.

The source makes the operation inspectable:

```gdscript
var to_target = target_pos - global_position

# Spring force toward target
velocity = (velocity + to_target * dock_spring * delta) * dock_damp
global_position += velocity * delta
```

Here the restoring force returns from the earlier halls. The vector to_target points from a part to its assigned destination. The spring changes velocity and velocity changes position. A moving piece can look as if it has found its place, although another file already supplied the target. dock_damp is applied each frame, which also makes the settling depend on the update rate. The clock remains inside the body we are watching.

There are two distinct descriptions at work. The catalogue defines available kinds of part: shapes, sizes, colours and related properties. An assembly chooses instances, assigns target positions, reapplies shapes from the catalogue, and declares connections. Movement towards those targets is then produced by a damped spring calculation. A recognisable whole results from a specification together with a procedure for approaching it.

This is not a simulation establishing chemical bonds or discovering molecular structures from physical laws. A line between two pieces represents a declared relation. A structure named Molecule or DNAHelix belongs to the exhibit’s authored vocabulary, and the name cannot supply the chemistry that its movement does not calculate.

The rhizome selected neighbours by proximity. Here the assembly already describes where things should end up. Neither method is unrestricted: one inherits a spatial growth rule, the other a catalogue and a target. Understanding those constraints lets us ask for a meaningful variation.

Imagine a body this catalogue makes awkward to describe. Would you need a new kind of part, another connection, or merely different positions for existing pieces? That is a proposed design exercise for a future editable version. The present automatic cycle lets you begin by observing how much changes while the inventory remains available.

<!-- @ -->

The final ledger asks us to record the consequences of those choices. A useful catalogue permits construction while also defining what its builder has to struggle to express.



## PostCrisis_Synthesis

Source: commons/maps/PostCrisis_Synthesis/final.md

SHA256: 74e5044ec6ced1089a0a080fd176369961fdaccf37b8aee79d0dc9e3e86ff254

# One choice you can answer for

Can you name one person a useful design choice could leave out?

<!-- @accountability_ledger -->

Read one complete pair on the ledger before it scrolls away. Choose a concrete case, such as a short name field and someone whose name exceeds it. Say what the designer probably gained, what the person encounters, and one change that could reduce the difficulty.

The exhibit cycles through prewritten examples of choices and exclusions. Six lines remain visible at once, and an amber mark accompanies a new entry. Its form resembles an accumulating record, but these entries are examples: it is not recording your visit, saving your discussion or certifying that any problem has been repaired.

The source makes the operation inspectable:

```gdscript
_entries.push_front(line)
while _entries.size() > visible_lines:
    _entries.pop_back()
_count += 1
```

A line enters at the front; another leaves when the buffer is full. The counter survives that loss. We met a running count near the point at the beginning of the museum. Here counting and remembering separate in four lines of code. The machine can announce progress while the evidence of an earlier problem has already disappeared.

An accountable record would connect a decision with evidence about its effect and someone able to revisit it. Naming an excluded case is a beginning. It becomes useful when it leads to an action, an observation after the action, and a decision about what to change next.

Return mentally to one room you have just walked. Perhaps a slider was difficult to reach, a number concealed several different conditions, or a label promised a computation the exhibit could not yet perform. Choose one case small enough to inspect. State the intended experience, the present obstacle and the smallest improvement that would let you test the difference.

Now ask where else the same relation occurs. A readable control, a preserved alternative or a visible source can be a reusable principle. Reusing it still requires checking the new room: the same height may not suit every body, and the same explanatory sequence may not suit every concept. Generalisation is a claim to test through another encounter.

The ledger does not absolve a choice by displaying its cost. Some exclusions call for repair, some for another route, and some for changing the category that made the case disappear. The response should stay attached to the person’s actual difficulty rather than becoming a decorative admission of imperfection.

<!-- @ -->

Go back to a chosen room with one question, one proposed change and one observable consequence. The museum’s next version begins with that specific return.

