# Point One

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

Godot calls `_process` once per process frame while this node is processing. The engine supplies the repetition. Each call reaches the indented line: add one to `_count`. One, then two, then three. Declared outside the function, `_count` keeps its value between calls. Its zero belongs to the beginning of this node.

`delta` carries this update's time interval in seconds. We receive it here but do not use it yet. Adding one counts calls. The same count could have accumulated through different durations; the number keeps how many, leaving how long unanswered.

The room's counter reads a total that began earlier:

```gdscript
var frames: int = int(Engine.get_process_frames())
```

`Engine.get_process_frames()` counts process frames since the engine started. The panel reads and displays that total on each `_process` call. It includes frames before the panel existed, and before you found the number. The work of building the room has already occupied some of those intervals.

We begin with a number that includes something we did not witness.

We have read the line that asks for that number. Much of the code making it readable remains unopened.

<!-- @folding_past -->

Through the entrance window, frames recede within frames. They keep folding while you look elsewhere. There is a temptation to follow them back to a first frame, a place from which everything here might be explained in order.

The source gives this particular depth a small inventory: ten frames, scaled and moved through a repeating cycle. It makes a figure of a past. It has no record of the route you took to arrive here. A few repeated shapes can invite a much longer journey than the one their program keeps.

We could turn back into the counter: how a digit gets its shape, how its glass is drawn, how the engine returns to `_process`. Any of those questions could take the rest of our time here. To begin with the point, we have to leave some invitations unanswered. The lesson borrows operations we have not learned to examine yet.

The code we leave unread keeps working. It gives the number its appearance and the room its possibilities while our attention moves elsewhere. Choosing a first principle also means choosing what we will, for now, take on trust. Who gets to decide which questions can wait?

Alice's rabbit is already ahead. There are functions we would like to open, but we still have a point to find. We carry a question forward; others fold behind us.

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

<!-- @origin -->

Find the origin marker. Zero has been given a place in this room too.

```gdscript
var origin := Vector3.ZERO
```

The origin is a point chosen as the reference from which these coordinates are measured. Calling it zero establishes a relation with other positions. It does not put zero outside the world it helps describe.

<!-- @coordinate_readout -->

Put down the dark point. The coloured frame carries a second, movable point of its own. Take that one for the next comparison: the frame's guides and the white card follow this point.

The card marked `WORLD` puts its position into another visible form. Move the point slightly while watching the card. A printed component may stay unchanged through a movement you can see.

The reporting operation can be written like this:

```gdscript
func report_position(point: Node3D) -> String:
    var p := point.global_position
    return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
```

`%.2f` rounds each component to two decimal places in the text. The stored position is left alone. The card has made the location easier to read by allowing several nearby positions to share a printed address. The apparent stillness belongs to that report.

<!-- @CoordinateSystem3M -->

Follow the coloured frame's guides as you move its point. Red follows X, green follows Y, blue follows Z. Move along one direction, then across it. The guides separate a movement into components, letting you follow several directions within one gesture.

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

<!-- @wireframe_threshold -->

The ring on the floor offers another way to look. Step inside it, then outside. It asks the renderer for a wireframe view while occupied and restores the previous view when the last visitor leaves.

The surfaces become available as edges. The case's glass, arrows and lines have geometry; the point they locate has no triangles of its own. Seeing these meshes will not reveal the comparison that accepted your arrival at the red arrow. That was another kind of construction, accessible in the source.

One opening leads to another. No single view has supplied everything.

<!-- @fontana_puncture -->

The punctured surface houses another instance of the changing point. Look into it from another opening. The body remains inside, while a different part of it becomes available through the cut. Here the surface gives us another way to approach a “here”, alongside the sphere, the arrows and the written address.

<!-- @floating_sphere_field -->

Small spheres drift nearby. Their bodies carry positions too, but they give those positions another pace and appearance. There are already several ways for a point to become part of a world, and several ways for us to take an interest in it.

<!-- @ -->

The counter has continued through all of this. A position has acquired a body, different addresses, a tolerance for arrival. It still leaves questions unanswered.

One of them travels with us: how did it get there?

The next room brings two points into relation. A line begins.

# Point–Line

The point gave us somewhere to begin. Now there is something to follow.

<!-- @line_demo -->

Two black points wait beside a barrier: **DO NOT CROSS.** Bring the points near one another and release to request a connection. Watch for the segment between them. What else moved?

The barrier flies apart. You joined two positions, and something nearby lost its power to stop you. Move an endpoint. The connection can remain while its length and direction change.

The connection manager keeps each point as the other's neighbour. On their first connection, this demonstration also calls the barrier's `trigger_explosion()`. Someone joined those events in code. Making a line has become a way to open a passage. We could have written a different consequence. Keep that possibility beside the one you have just tried.

<!-- @line -->

Compare your connection with the already drawn line. Its two endpoints give us a compact way to describe a segment:

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(1, 0, 0)
var displacement := b - a
var distance := displacement.length()
```

From A to B: one metre along the positive X-axis. The subtraction keeps a direction as well as an amount. The length gives us the amount alone. Two distinct positions determine a straight line; the part between them is a segment. These few lines let us hold a relation steady enough to compare it with another.

## Read it with your feet

<!-- @walk_this_line_marking -->

On the floor, a white stripe: **WALK THIS LINE.**

Try moving along it. Let your pace be your own. You might look down to keep it under you, then look ahead and trust it for a while. Move alongside it. The stripe is still available. It can help you find a direction without having to become the whole of your journey.

I keep thinking of a dance pole: the rod stays straight; the body finds turns around it. Here the line lies on the floor. What movements does that change invite? Following, crossing, keeping company at a small distance. There is pleasure in having something steady to vary a relation with.

The words may also make you correct yourself. A little sideways movement can begin to feel like a mistake. This marking does not score your walk. Its script makes the stripe and lettering; it does not check whether you obey. Yet you have read an instruction, and perhaps begun to arrange yourself around it. Stay with that perhaps. Another visitor may read an invitation where you read a demand.

<!-- @do_not_cross_barrier -->

The barrier made a different kind of request. While intact, its collider extended from the floor to the bar: the visible gap beneath the plank did not offer passage. Now its former position can be crossed. Disconnecting your points does not put it back.

A phrase, a painted stripe, an invisible collision boundary: each can take part in directing a body. They have been made separately. Changing the words and opening the way are different acts.

## Carry the whole line

<!-- @grabbable_line -->

Pick up the short rod. Carry it across your view. Turn it. Its two ends move together, keeping their distance. A direction you followed on the floor can now be a direction you hold in your hand.

Compare turning it with pulling the demonstration's endpoints apart. One operation carries a fixed span; the other changes the span itself. A length that stays fixed can become a unit for comparing other lengths.

Move the held rod slowly through the room. Near whole-number values on a world axis, it begins to jitter and sound; a tracked controller can pulse too. Its position has met an authored rule. Search for a quiet place, then return to the disturbance. Something that interrupts carrying can become an instrument you play by carrying.

<!-- @two_point_ruler -->

The ruler offers a half-metre span beside two blocks. Compare them by looking. Here the unit stays still for you. Later we could make measuring one object change another. For now, there is already something to borrow: a distance held steady so other distances can be read.

<!-- @two_points_line -->

Watch the bead travel between its two endpoints. Wait for its return. It slows near the ends; a straight route has room for a changing pace.

```gdscript
var p := a.lerp(b, t)
```

`lerp` interpolates: at `t = 0`, the position is A; at `t = 1`, B. Values between them give positions along the segment. The bead's script uses a cosine to move `t` back and forth. One operation supplies the route, another the rhythm. We will return to that rhythm when we learn how values change over time.

## Where the beam ends

<!-- @laser_measure -->

Take the measuring instrument and aim through the place where the barrier stood. The beam reports the first physics body it hits. If the barrier is still intact, hold the beam on it: this hall enables burning, and the barrier can break that way too. Watch where the measurement ends afterward.

A ray begins at a position and goes in a direction. The bodies it encounters help determine the answer it returns. Here a measurement can participate in changing what can be measured.

<!-- @laser_exploding_sphere -->

The orange sphere bursts when the controller pointer enters it, then returns after a cooldown. That pointer is another interface, separate from the measuring beam. Similar-looking lines can ask different things of the room. The returning sphere invites another try; the broken barrier leaves a changed route.

<!-- @parallel_lines -->

Walk around the three parallel segments. Their apparent separation changes with your viewpoint. They keep their shared orientation. Alongside is another relation a line can offer: company without a meeting point.

<!-- @ -->

Choose two positions and travel between them by a detour. The subtraction `b - a` still gives the same answer as it would for a direct passage. Your curve, your hesitation, the time spent looking at something halfway: none of those events entered those two variables.

There is usefulness in that small answer. We can measure without carrying every journey into the measurement. There is also a reason to want more. I want to keep the turn your hand made, the movement the two ends cannot tell apart from a direct passage.

The next room gives us a way to begin keeping it. We will save positions along the movement. Even then, we will have to choose how many.

Bring the detour.

# Point Trace

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

# Point–Line–Grid

Your hand may have been here before you.

If you released a drawing dot or stick in Trace, a copy of its retained positions can arrive ahead of you. Look for the line over the ruled field. A small movement may now occupy enough space to suggest a route. Keep it in view while we learn what a grid can help us do with it.

## Hold a place

<!-- @grab_sphere_point_snap -->

Pick up the snapping sphere. Move it a little, then a little more. Follow its drawing marker and read the ground table. Can your hand move while the retained line admits no new place?

This tool uses a five-centimetre grid. Along one axis, a sequence of stored positions might read `0.10`, `0.15`, `0.20` metres. Their grid indices would be `2`, `3`, `4`: count the spacings from zero, or measure them in metres. Two readings of the same position.

Release the sphere and compare the marker with the last retained row. The marker aligns to the lattice on release. The grid gives a place you can return to, with an interval around it in which small differences can share an address.

## Let a walk draw

<!-- @player_trace -->

Walk a small loop beside the recorder, then a wider diagonal. Look behind you. One path keeps a finer sampled reference; the other rounds positions onto a one-metre lattice. Both are drawings made from readings of movement.

In the headset, try leaning with your feet planted, then standing upright and taking a step. The paths can respond to both. The recorder uses the headset's horizontal position and the rig origin's height. It needs some point to follow before it can call the result a path.

The recorder brings that position into its own frame. Then it rounds the horizontal components:

```gdscript
local_point.x = roundf(local_point.x / seam_grid) * seam_grid
local_point.z = roundf(local_point.z / seam_grid) * seam_grid
```

Divide by the spacing, round to an integer, multiply back. At one-metre spacing, several nearby positions become the same address. Near the boundary between two rounding regions, a small movement can change that address by a metre.

Find an edge by moving slowly. Cross it and return. Give the change a rhythm. Then find room to move while keeping one address steady. There is a dance available on either side of the rule: using the jump, inhabiting the interval.

The line connects successive retained positions, sometimes diagonally across places you did not traverse. You can return to a place and add another part of the journey; this is an ordered path, rather than a single mark for each visited cell. The record gives us a construction we can compare with our walk.

## A gesture becomes a score

<!-- @grid_lines -->

Return to the ruled field and look for the bend you made in Trace. If the instrument reports no released trace, make a line there with at least two retained points, let go of the dot or stick, and return. The release supplies the copy. The whiteboard's ink and the path now growing behind you are separate records.

Pink carries the received shape after recentering and enlargement. Green rounds that displayed shape again. Find one small turn in pink and follow what green does with it.

The display starts with the midpoint of the source's bounding box, `center`. It subtracts that centre from each position `p` and multiplies the result by `final_scale`:

```gdscript
mesh.surface_add_vertex((p - center) * final_scale)
```

A small trace is enlarged five times. A larger one is scaled less if necessary to fit within five metres along its longest dimension. The stored positions remain available; the display makes another set of positions from them. Green applies its grid afterward, with six intervals per metre along each displayed axis.

Look back at your hand. A little bend of the wrist has acquired another extent. Imagine another body following it. What was easy to draw might ask for a detour; a turn made without thought might become the part someone else wants to repeat.

This is one reason to keep a record: it can become useful for something we did not do the first time. We could treat the enlarged line as a score. We would still have to decide how to read it together—where to begin, what counts as following, how much room to leave for another person's movement.

The instrument's coordinate rows describe the source positions, even while the line stands somewhere else at a different scale. Follow a row, then look up. A number needs its frame; an instruction needs someone to interpret it. The shared record does not settle either relation by itself.

Below the glass, five-by-five cells continue across the lowered basin. The museum's glass supports you above the ruled field. The lines have no collision surface of their own. A grid can supply addresses for building; something else must make a floor that carries a body.

<!-- @floating_sphere_field -->

Small spheres drift while your path is being recorded. Their movement accompanies yours without entering that recorder. The room has more going on than one instrument follows.

<!-- @room_grammar -->

A plan generated by rules brings the question to walls and doors. An address lets us place something. We still have to make an approach to it, leave room beside it, decide what kinds of bodies should be able to pass. A plan can hold an arrangement before anyone has found a way to inhabit it.

<!-- @plan_vitrine -->

Step into the glass enclosure around the small five-by-five plan beside the main gallery. Count a row, then a column. Twenty-five cells, each one metre across. Their numbers run from zero to four along each direction.

Walk across a row and cut diagonally. These edges can help us place objects without becoming walls for our bodies. Here a cube could stand; beside it, a wedge could become a ramp. A few relations could begin to make a level. The line that asked you to follow now gives you places to compose.

<!-- @ -->

Keep a purpose for your path: accompanying someone, returning to a view, making a loop for its own pleasure. The coarse record may be enough to share part of that purpose. You may want to add something—a time, a word, another position—or leave the record open to another interpretation.

We began with a location. A line offered a relation; a trace kept positions from a movement; a grid made places comparable and available for another construction. Each gives us more to work with, and another choice about what matters.

The next room adds a third point. We can return a path to its beginning. What else must we make before that closed boundary becomes a face?
