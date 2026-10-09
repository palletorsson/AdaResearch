# primitives: the chapters

## Point Zero

*Point_Zero*

### Point Zero — You arrive late

… You arrive late.[^Point_Zero--1]


You fall through a dark shaft into a lit room. In front of you, a number is running. Like Alice, you have entered before you know what kind of place you have entered. The floor catches you; the number goes on.


The number is already changing. Its first number for you is not its first number. While you find somewhere to stand, the room continues with whatever it was doing before you arrived.

You can stand in a room you did not build. Someone has made that possible. Their work gives us somewhere to begin, and brings decisions with it. We inherit possibilities before we know their conditions. What are we forced to borrow for now, and what must we understand to make the work our own?

Let it run while you look around. When you return to the number, it has moved on.

Where does the next one come from?

A small counter can begin here:

```gdscript
extends Node3D

var _count := 0

func _process(delta: float) -> void:
    _count += 1
```

Godot repeatedly calls `_process`. Each call runs `_count += 1`, adding one to the stored number: one, then two, then three. The starting value, `0`, is set outside the function, so each call keeps what the previous one left behind.

`delta` supplies this update's time interval, in seconds. Our counter ignores it. A hundred calls add a hundred, however long they took. The number keeps how many, leaving how long unanswered.

That example has its own count. The room's counter reads a total that began earlier:

```gdscript
var frames: int = int(Engine.get_process_frames())
```

`Engine.get_process_frames()` counts process frames since the engine started. The panel displays that total, including frames from before the panel existed, before you found the number.

We begin with a number that includes something we did not witness.

The view of this room has to be drawn again while you are in it. Turn your head and another view is drawn. That is the demand of real time here: the program must keep answering a body that has already moved. The counter gives this continuing work a visible trace. It does not count the years it took to make the room possible.

There is another clock outside the room. Software is revised while we are learning to use it. AI makes the feeling of arriving late harder to put aside: before we understand one possibility, another is offered. How much of our time can go into catching up? When do we get time to play?

We have read the line that asks for that number. Much of the code making it readable remains unopened. It is like standing on the shoulders of giants in fog: other people's work has brought us here, but height alone does not give us a clear view.


Through the entrance window, rectangular frames recede within frames. They keep folding while you look elsewhere. There is a temptation to follow them back to a first frame, a place from which everything here might be explained in order.

Ten frames, scaled and moved through a repeating cycle, make this depth. They hold no record of the route you took to arrive here. A few repeated shapes can invite a much longer journey than the one their program keeps.

In 1968, an experimental head-mounted display put its viewer inside a room drawn in wireframe. Turning the head changed the view; walls, ceiling and floor were already part of the experiment.[^Point_Zero--point-one-room-history] Before we could take a room like this for granted, people had to make it possible to look around one. You are here now, with some time to play.

We could turn back into the counter: how a digit gets its shape, how its glass is drawn, how the engine returns to `_process`. Any of those questions could take the rest of our time here. We would also like time to pick something up and see what happens. To begin with the point, we have to leave some invitations unanswered.

The code we leave unread keeps working. It gives the number its appearance and the room its possibilities while our attention moves elsewhere. Choosing a first principle also means choosing what we will, for now, take on trust. Who gets to decide which questions can wait?

Like Alice after the White Rabbit, we could keep following one opening into another. The desire is real. So is the time it takes from other things. We want to see what happens next, even when we cannot yet judge what we are risking.

We can call that desire progress. We can also ask where it becomes a death drive: an insistence on going further that makes the cost of continuing harder to see. The room can hold the question without settling it. We are here because we wanted to enter.

First light, or the light at the end of a tunnel? The folding frames keep offering a further opening. Light makes a way visible before we know where it leads.


#### Somewhere to count from

We cannot follow everything back to its beginning. But we can choose somewhere to count from.

Find the black sphere with its pink glow and wireframe cube. Its label says “Point zero”. Zero has been given a place in this room too. This zero is a reference in space, not the first moment of the running clock.

```gdscript
var origin := Vector3.ZERO
```

`Vector3.ZERO` is shorthand for three zeroes: `(0, 0, 0)`. Used as a position, it names the origin of a coordinate system. From there we can measure where something else is. Nothing in those three zeroes explains why this place was chosen.

Nearby, three words are printed on the floor: “~~you~~ are here.” The first is struck through.

Take hold of the struck word. It lifts. The crossed-out “you” comes away as a thing you can carry, and the rest of the sentence stays exactly where it was printed, still saying *are here* to the room. Set it down somewhere else and look back at what is left behind.

The location remained legible without its visitor. That is not a trick of this decal; it is what an address is for. What part of you has arrived at this one?[^Point_Zero--point-one-ahmed-reach]


We have chosen a place to count from. In the next corridor, a label is waiting for something to appear above it.

Point one.

[^Point_Zero--1]: Heidegger’s *thrownness* names finding ourselves already delivered into an existence we did not choose—not simply arriving after the clock started. Here, the room offers a small encounter with that condition. Genesis, first light: we look for a beginning. But is this the world beginning, or our first glimpse of something already underway? See [*Being and Time*, §29](https://www.beyng.com/pages/en/BeingandTimeMR/BeingandTimeMR.174.html).

[^Point_Zero--point-one-room-history]: Ivan E. Sutherland, [“A Head-Mounted Three Dimensional Display”](https://doi.org/10.1145/1476589.1476686) (1968), especially “Results”; [accessible paper](https://archive.aec.at/media/assets/636b23b07bfd1b4f1d1154827ac9d9ab.pdf). The wireframe room and response to head movement are described there. The acknowledgments name a collective effort, and the funding note names ARPA, the Office of Naval Research and Bell Telephone Laboratories. This is one historical encounter with these problems, not a claim that the museum follows a single line of descent.

[^Point_Zero--point-one-ahmed-reach]: Sara Ahmed, [*Queer Phenomenology: Orientations, Objects, Others*](https://www.dukeupress.edu/queer-phenomenology) (Duke University Press, 2006), introduction. Ada’s questions about orientation and reach draw on her account of bodies finding their bearings through relations with objects, spaces and others. Lines will make this conversation more explicit.

---

## Point One

*Point_One*

### Point One — A body for a position


The corridor begins with a label: “Point one”. Above it, nothing.

There is somewhere to look because the words have given you a place to look. The name arrives before its object. You can stand in front of it, lean closer, pass your hand through the empty space.


Further along, the same label sits below a small white sphere. Now there is something to look around. Its curved surface holds a highlight; as you move, the highlight moves too.

Walk towards it. The sphere does not stop you. Your view can pass through its surface and come out the other side. You have crossed something you could see.

A mesh supplies the visible shape. Drawing it has not made a boundary for the visitor's body.


The next white sphere has the same size and finish. It says “Point one” too. Try the same approach.

This time a collision body occupies the place the surface describes. Your movement meets a limit. The difference was invisible until you tried to cross it. Two objects can look alike and permit different lives around them.

The program has given the second sphere a `SphereShape3D` inside a `StaticBody3D`. One part tells the renderer what to draw; another tells the physics system where movement meets resistance. We have made those surfaces coincide. They could have been arranged otherwise.


At the fourth label the sphere is black. Take hold of it. The place you were looking towards can now leave with your hand.

Its visible size has not changed. Pickup code has added another relation: while held, the body's movement answers to yours. Put it down and look back at the label. “Point one” stays in the corridor; the point has gone elsewhere.

Which part did the name belong to? The position, the sphere, the possibility of taking hold?

A mathematical point specifies a location without extension.[^Point_One--point-one-euclid] Each sphere occupies space. Each station also has a different address, although its label repeats the same name. A position can be written with three numbers:

```gdscript
var point_position := Vector3(1.0, 0.5, 0.0)
```

`Vector3` holds the components X, Y and Z. Here they name a position relative to an origin. They say nothing about white or black, a radius, a collision, a hand. Those decisions need something beyond the address.

The corridor lets us encounter the decisions separately. In an ordinary object they arrive together, and we can forget that what appears solid has been given a separate reason to resist us.

Keep the black point. There are other ways to approach it in the wider room: arrows meeting at an empty centre, a screen unfolding the code, another point whose surface changes in your hand. We can return to them. For now, carry this one towards the coloured frame.


#### Two addresses

Keep the point in your hand and watch the white card as you move.

The corridor opens into the coordinate room. Its guides and the card follow the point you are already holding.

The card marked `WORLD` puts its position into another visible form. Move the point slightly while watching the card. A printed component may stay unchanged through a movement you can see.

The reporting operation can be written like this:

```gdscript
func report_position(point: Node3D) -> String:
    var p := point.global_position
    return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
```

`%.2f` rounds each component to two decimal places in the text: `1.231` and `1.234` both print as `1.23`. The stored position is left alone. Several nearby positions can share this shorter address. Your hand can move without the number changing. The apparent stillness belongs to the report.

Now compare it with the card marked `LOCAL`. Move the same point between two places. Both cards answer, but with different numbers. What would you need to know to read either address?


Follow the coloured frame's guides as you move the point in your hand. Red follows X, green follows Y, blue follows Z. Move along one direction, then across it. The guides separate a movement into components, letting you follow several directions within one gesture.

`WORLD` measures the point's position in the scene's coordinate system. The coloured frame supplies another reference, with its own origin, orientation and scale. Its script uses `to_local()` to express that same position relative to the frame. The `LOCAL` card prints the result beside `WORLD`. The numbers differ because they answer to different references.

A coordinate needs its reference. Reading more digits cannot supply one that has been left unnamed.[^Point_One--point-one-haraway]

Carry the point beyond an arrow's end. The drawn axis has a length; the coordinate system can describe positions beyond it. A drawing made to explain movement could also become a limit on movement. Here the guides keep following your hand.


#### Room to arrive

The red arrow says “drag point here”. Carry the point towards it without letting go, and watch what falls.

“Here” has become a request, and the request has a tolerance. This is the distance test, reduced to one position:

```gdscript
@export var catch_radius: float = 0.45
@export var catch_height: float = 1.20

func accepts_position(p: Vector3) -> bool:
    var centre := global_position + Vector3(0.0, catch_height, 0.0)
    return p.distance_to(centre) <= catch_radius
```

`distance_to()` measures the gap between the point and the target's centre. `<=` asks whether that distance is 0.45 metres or less. The centre sits 1.20 metres above the target's origin. A hand has room to arrive. “Here” has become a small region.

The target remembers whether the point is already inside. Staying there produces no further fall; leaving and returning allows another. A careful delivery and an accidental pass can bring the same rain. Your intention never enters this comparison.

Return again, and a destination can become an instrument. Come straight back once; next time, take a longer way round. The target accepts both arrivals, but you have changed the pause between them. Your detour has given the falling balls another rhythm.


#### The size of a point

Before leaving, you meet a white sphere on a pedestal. It is 1.3 metres across. The text still says “Point one”.

The small sphere travelled in your hand. This one asks you to walk around it. A change in size has changed how much of the room you can see, and where your body can go. Its centre can still be written with three numbers. The same short address leaves a great deal unsaid.

Look from the sphere you carried to the sphere on the pedestal. We have given each a body and called each a point. Neither has to stop being interesting once we know the difference.

The next room brings two points into relation. A line begins.

[^Point_One--point-one-euclid]: Euclid, [*Elements*, Book I, Definition 1](https://mathcs.clarku.edu/~djoyce/elements/bookI/defI1.html), defines a point as that which has no part. This is a historical starting point for the abstraction, not a specification of a Godot object. A stored position, a visible marker and a collision body require different constructions; the invisible point lets us keep them apart.

[^Point_One--point-one-haraway]: Donna Haraway, [“Situated Knowledges: The Science Question in Feminism and the Privilege of Partial Perspective”](https://doi.org/10.2307/3178066), *Feminist Studies* 14, no. 3 (1988), 575–599, especially 581–585. Haraway argues for embodied, situated and accountable knowledge, challenging both a view from nowhere and an easy relativism. This room asks a related question through its two coordinate readings: what must accompany a reading for someone else to understand its reference and limits?

---

## Point Lines

*Point_Lines*

### Lines, Networks, Measure

The point gave us somewhere to begin. Now put two positions into relation.


Two black points wait beside a barrier: **DO NOT CROSS.** Bring one close to the other, then let go. Watch for the segment that joins them. What else moved?

The barrier flies apart.

Keep hold of this small beginning: **two distinct points determine a straight line.**[^Point_Lines--point-lines-euclid] Here we draw only the part between them: a segment. Move an endpoint. The segment changes length and direction while the connection remains.

Already something else has attached itself to the lesson. Joining two points has opened a passage.


Try crossing where the barrier stood. Before it broke, an invisible collision shape filled the space from the floor to the bar. The space looked open beneath the plank, but you could not pass through it. The explosion removes that shape too. Disconnecting the points does not put it back.

On the first connection, the demonstration calls the nearby barrier's `trigger_explosion()`. Someone joined those events in code. Geometry supplies a relation; another instruction gives that relation a consequence for your body. We could have made the connection ring a bell, or left the barrier standing.

The words, the plank and the collision boundary all helped to say **DO NOT CROSS**. Opening the way required changing what enforced that instruction. For a moment, a line has given us passage through another line's prohibition.

In Point One, leaving the target made another arrival possible. Here, the first connection leaves a passage open even after the points separate. The rooms keep different things from the gestures we make in them.


This line has two ends you can hold. Pull them apart, then bring them closer. Watch the length display. Can you find a span of one metre?

Hold one end still and move the other around it. Try keeping the same distance. The segment can turn while its length stays steady. Once we choose to go from A to B, we can calculate a displacement with a distance and a direction.

Here is an example using the positions we began learning to write in Point One:

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(1, 0, 0)
var displacement := b - a
var distance := displacement.length()
```

`b - a` subtracts the starting coordinates from the ending coordinates. Here the result is `(1, 0, 0)`: one unit along X, none along Y or Z. In this room we use that unit as a metre. `length()` returns one number for the size of that displacement: `1.0`.

Reverse the subtraction: `a - b` gives `(-1, 0, 0)`. Its length is still one metre. The points have stayed where they are; the direction between them has changed because we chose the other point as the start.

Even here, another question appears. Your hand may keep moving while the rounded number stays the same. How much difference can a display show? Remember it when we reach Trace and Grid.

Two points were enough to begin. They have not made the world small.

Beyond the crossing, the room opens into four views. Lines wait in pairs, in crosses, upright and in a grid. There is pleasure in following these associations, in finding how quickly a familiar mark acquires another use.[^Point_Lines--point-lines-ingold]

The clock in the first room was already running when we arrived. Beginning required leaving some code unread. Continuing asks us to choose a thread and let other questions remain open.

You have changed a line with your hands. Ahead, a line has acquired words.


Across the glass cover of a shallow basin, a black stripe: **WALK THIS LINE.** The glass supports your crossing.

Try following it. Then walk alongside it. Cross it at an angle. The stripe stays straight through all three journeys.

Did a sideways step feel like a mistake? The marking does not measure how closely you follow it. Its script draws the stripe and lettering. Yet you may already have corrected a step in answer to the words.[^Point_Lines--point-lines-ahmed-paths] You might also find yourself dancing around the same steady line.

Choose which end to start from, and the line gives you a direction to follow. It cannot settle what following will mean to a body.


Turn and look at the route your movement has left behind. Compare it with the stripe. Where do the two lines part company?[^Point_Lines--point-lines-ahmed-deviation] One was waiting for you; the other has taken shape while you moved.

The recorder saves positions and joins them with straight segments. The X and Z come from your headset; the line is drawn near floor level. A lean can change the drawing even when your feet stay put.

Choose a start and an end. Walk between them with a detour. Imagine walking directly between those same positions instead. The endpoint calculation, `b - a`, gives the same answer for both journeys. It contains no record of the turn you took.

The trace has kept more positions. How many did it need? What happened between the ones it kept?


#### A body for the line

The point needed a sphere before we could see it. Here a line takes the form of a stick, a plank, a luminous rod, a measure, a beam. The mathematical line has no width. Each of these has enough width to appear, and a shape the hand can find.

We might call this a *conceptual skin*: the body we give an idea so that we can encounter it. Look at what comes with that gift. The plank has a broad face and a narrow edge. The ruler divides its length into intervals. The light can seem to have hardly any substance, although this one is a mesh with a pickup body. Their common direction does not tell us what it will be like to hold them.

The barrier already gave this distinction consequences. Its visible plank and its invisible collision shape occupied different amounts of space. Here the thin rods have slightly wider pickup shapes so a hand can find them. What we can see and what we can touch are being decided together, but they need not coincide.

Two long black lines run along the floor, with equal intervals marked beside them. Walk between them. Their distance apart stays the same, although the gap seems to narrow ahead. A pair of lines can suggest depth in a flat drawing. Here you can walk into the depth they describe.

Look up at the edge of the ceiling. A shorter length hangs nearer to you. Move a little sideways until it seems to join the edge. A lower or taller eye finds that agreement from another place. Then take another step. The line comes away from the ceiling and hangs over the room again.

The two objects have stayed still. Your movement let them become one edge, then gave them back their distance. What else in the room is held together by the place from which you see it?

#### Four views

Two sticks make a plus. Further along, two of the same length make an X. From the marked starting position, each reads as one familiar sign. Step sideways. The sticks sit in slightly different depth planes; the crossing belongs to your view. Take one in your hand and bring it forward. How far can the sign come apart before you stop seeing it?

Beside them, two planks lie parallel. Walk between them. From one end the gap narrows into the distance; moving your head changes that appearance without moving either plank. Then move a plank. Now you have changed the relation itself. The two graduated measures beyond them give the hand another pair to compare.

In the third view, two beams stand upright. A thin luminous horizon crosses the space behind them. Your own upright posture has company. Turn one beam in your hand and keep it there. The room does not correct it when you let go.

The fourth view begins with six lines: three in each direction. Together they suggest a plane divided into places. Pull one line towards you. Its crossings separate as you move around it; a regular drawing opens into depth. Behind it, three more bars already occupy different directions. There are edges here without a surface stretched between them.

The fixed lines on the walls keep another version of these arrangements. Your hands can change the bodies in the room while the wall keeps its own arrangement.

#### Follow this line

On the floor: **FOLLOW THIS LINE.**

The mark reaches the wall. It turns upwards and continues across the plaster. You can follow it with your eyes. Your next step meets the wall's collision boundary.

The earlier connection opened a barrier. This line opens nothing. An instruction has reached the limit of the body to which it was addressed. Do you stop, turn, look up? The mark remains available to another kind of following.


Look back at the route you have left among these arrangements. The question taking us towards the exit has become precise: **what must we save if we want to keep something of the journey?**

Two endpoints were enough for the segment. To remember the detour, we will need to add something.

Bring the detour.

[^Point_Lines--point-lines-euclid]: See Euclid, [*Elements*, Book I, Postulate 1](https://mathcs.clarku.edu/~djoyce/elements/bookI/post1.html), on drawing a straight line between two points. The construction concerns the finite segment; extending it and treating it as an unbounded line are further steps. The postulate is a historical reference, not an account of the renderer or the barrier’s programmed response.

[^Point_Lines--point-lines-ingold]: Tim Ingold, [*Lines: A Brief History*](https://www.routledge.com/Lines-A-Brief-History/Ingold/p/book/9781138640399) (Routledge Classics edition, 2016), especially “Traces, Threads and Surfaces” and “Up, Across and Along.” Walking, drawing, weaving and connecting enter his inquiry as different practices of making lines. This helps us take the room’s proliferation seriously: a connector, a trace and a boundary need not perform the same work merely because we call each a line.

[^Point_Lines--point-lines-ahmed-paths]: Sara Ahmed, [*Queer Phenomenology*](https://www.dukeupress.edu/queer-phenomenology) (2006), 15–20, especially 16: repeated journeys make paths, while established paths help direct later journeys. Ada takes up this relation as an experiment. Its stripe is authored rather than worn into the ground, and its instruction does not score compliance. Being oriented by a line, evaluated against one and physically blocked by one remain different operations to investigate.

[^Point_Lines--point-lines-ahmed-deviation]: Ahmed, [*Queer Phenomenology*](https://www.dukeupress.edu/queer-phenomenology), 20, considers how deviations can leave marks and generate other lines. This sampled drawing offers one specific record, not the whole history of the body’s deviation.

---

## Point Trace

*Point_Trace*

### Duration and Residue

Bring the detour.

There was time between the ends. We passed through it. Let the next line try to keep something of the passage.[^Point_Trace--point-trace-klee]

#### Let the hand leave a line


The drawing points wait on their plinths. Take the first dot and draw a short loop in the air. Pause with it still in your hand. Beside the line, a small instrument tilts its face towards reading: a count above a table of positions.

Watch during the pause. Does another point enter merely because time passes?

Move again. Give the loop a tail, then release the dot. Your hand can rest while the line stays. Something of the movement has become available to look at from another side.

The count comes from a list:

```gdscript
var point_count = _trail_points.size()
```

`_trail_points` holds positions in the order they were kept; `size()` counts them. The recorder joins each position to the next with a straight segment. Repeated in small enough steps, the two-point construction from the last room lets us see a curve. The gesture has acquired joints. Between those joints, the program draws a connection; your hand may have taken another way.[^Point_Trace--point-trace-sampling]

The recorder waits for at least five millimetres of movement before considering another position. A still pause can leave the count unchanged while Point Zero's counter keeps running. You spend time holding the line still; the position list does not say how long you waited.

Pickup, tracking, drawing, the letters on the screen: more code is running than we can read here. We follow the movement gate because it answers the question our hand just asked.

Each row gives three coordinates for a retained position. As the drawing grows, earlier rows leave the small table. The drawing still has its beginning. What has left the screen has not yet left the line.

#### Another resolution, another gesture

The other dots give the line a coarser grain. From red through green to blue, their grids grow wider. The first dot adds no such grid.

Repeat a small bend with the blue dot. Then enlarge the movement until another turn appears. Your wrist is negotiating with a spacing. A gesture that one recorder can distinguish may need to become larger for another.

The program rounds each coordinate to the nearest grid position. Several movements of your hand can arrive at the same saved address. Until a different address is kept, the line has no new corner.[^Point_Trace--point-trace-quantisation]

The saved positions lie on the grid, but the segments between them can cut across it diagonally. A grid of corners does not require a drawing made only of right angles.

Now give the coarse recorder something it might do well. Make a corner you can return to. Let your hand wander while one address stays steady, then find the edge where it changes. The same interval that swallowed a small flourish can help you repeat a shape. What kind of drawing do you want to make with it?

There is also a limit to how many positions a dot can keep. Near the exit, another dot has a shorter memory. We will reach its limit while drawing.

#### Move the place that draws


Take the stick. Keep your fist nearly still and turn your wrist. The tip travels an arc. This tool uses the same recorder, but puts the sampling point at the end of a rod. A small turn can become a large mark.

The recording rule is unchanged. We moved the place it observes. Your wrist can stay in one place while the line describes a journey.

#### After the hand lets go


A black ball rests on a pale plinth. A plank slopes from its edge to the floor. Pick up the ball, set it near the top of the plank and let go.

The ball continues. A thin black line stays behind it.

The point has acquired weight. Your hand chose where to release it; gravity, the slope and contact with the plank carry the movement further. Here the recorder follows the ball's centre. The mark hangs a radius above the surface it seems to draw on.

Wait until the ball settles in the shallow tray. The line stops growing. Walk alongside it: the slope has become part of the drawing. Carry the ball back and release it from another place. The next release begins a new trace.

You have set a line in motion and let something else continue it. How much of the drawing did you make when you placed the ball?

#### A line you did not hold


Put the tool down. Enter the outlined square beside the plinths. Lean a little, lower your head, then rise. Step outside the square and look back.

A pink line hangs where your head has been. A cyan line lies beneath it. Find the place where you lowered yourself. Can you find that movement in both?

The hand needed a tool. Here the point being followed is in the headset. You were making a line while looking for one.

Both views use the same retained positions. For the floor version, each position gives up its height:

```gdscript
return Vector3(p.x, FLOOR_Y, p.z)
```

`p` is a position measured relative to the square. X and Z remain; the floor height takes Y's place. Positions above one another meet on the same spot below. The line can keep where you went across the room while losing how low you bent.

Walk around what remains. Neither line has shoulders, a face, or a reason for leaning. Yet you may recognise something you just did. You know the movement from inside; another observer has these marks.

Return to the square to begin again. Try giving the floor line a bend. Then try moving without extending it. The same body can make more than one account of its passage.

#### The pause leaves a line


Come close to the small writing desk. Let the nib cross a little paper while you hold still. Lower your head, wait there, then rise. Your hands can remain empty.

Look for the waits in the writing. A level stretch can keep something the drawing dot left out.

At this desk, time moves the pen across the page. The height of your headset moves the mark above or below the row. The height at which you arrived becomes its starting level. Small movements still belong to the recording; stillness need not be perfectly straight.

```gdscript
_elapsed += delta
```

Each update adds the elapsed time. The nib keeps travelling while a measured height stays the same. Lower yourself and the line bends; stay lower and another level stretch can appear. We have given waiting a length.

The page can also have blanks. When measured input disappears, the clock can carry on without a mark. A horizontal line and an empty interval make different claims about what the instrument received.

A completed page waits. Step away and return to begin another. Give one pause more room than the last. Your reason for waiting stays with you.

#### Touch the page


Four pens and an eraser wait on the shelf beneath the whiteboard. These belong to the board. Take the red one and touch its nib to the face. Make a short stroke, lift the pen, cross a little space, and touch down again.

Your hand travelled across the gap. The picture leaves it white.

The pen writes within the board's edges and close enough to its face. Lift beyond that contact allowance, and the next touch begins a new stroke. Your hand keeps moving across the gap; the rule stops admitting it to the picture. You can use that interruption to give two marks some space.

The board turns the accepted contacts into a painted image. The coloured pens have the familiar spacings. A lift of the hand gives the drawing a gap.

#### A line with a short memory


The amber point near the exit has room for thirty-two positions. Draw a loop, then lead it away. Small beads mark the positions the cord joins. Watch its far end.

At first you make more line. Then you begin to unmake it.

Hold your hand still. Does the remaining line wait with you?

This recorder uses the same movement gate as the first dot. We have given its list less room. When a new position takes it over that limit, the oldest goes:

```gdscript
if _trail_points.size() > trail_max_points:
    _trail_points.pop_front()
```

Waiting does not spend another place. Continuing the drawing can. Thirty-two positions are neither thirty-two seconds nor a fixed length of line.

Now try drawing with the loss. Give yourself a tail. Curl it around your other hand, then lead it elsewhere. The space you just marked can open again. What would you make with a line that follows you without keeping all of where you have been?


Return to a line you want to keep. Release the drawing dot or stick after making it: that release sends a copy onward. With the amber dot, only the surviving positions travel.[^Point_Trace--point-trace-carry]

We can carry the record forward. The movement that made it has already passed.[^Point_Trace--point-trace-inscription] The copied positions can enter another program and be given another task.

In the next room, look for your bend. It may have grown.

[^Point_Trace--point-trace-klee]: Paul Klee, [*Pedagogical Sketchbook*](https://openendedgroup.com/field2/assets/Klee_Paul_Pedagogical_Sketchbook_1960.pdf), translated by Sibyl Moholy-Nagy (1960 edition; German original 1925), opening section. Klee begins with an “active line on a walk” and a moving point. Ada makes the recording conditions part of that encounter: which point moves, when a position is accepted, and how retained positions become a line.

[^Point_Trace--point-trace-sampling]: Claude E. Shannon, [“Communication in the Presence of Noise”](https://fab.cba.mit.edu/classes/S62.12/docs/Shannon_noise.pdf), *Proceedings of the IRE* 37, no. 1 (1949), 10–21, Theorem 1, gives a reconstruction result for band-limited signals sampled uniformly in time. It is a technical neighbour, not a guarantee for this trace: frame timing, a movement threshold and spatial rounding do not meet those assumptions. Joining retained positions with straight segments cannot by itself recover the intervening gesture.

[^Point_Trace--point-trace-quantisation]: Godot’s [`snappedf`](https://docs.godotengine.org/en/4.6/classes/class_%40globalscope.html#class-globalscope-method-snappedf) returns the nearest multiple of a spacing. Here this quantises spatial components; it does not set a fixed temporal sampling rate. The separate movement gate determines whether to consider another reading. Changing either operation can alter the record, for different reasons. The [technical companion](/book?map=Point_Trace&section=technical) gives the spacings, recording gate and list capacities.

[^Point_Trace--point-trace-carry]: A dot or stick must retain at least two positions to send a copy onward. The whiteboard's image, the ball's path, the head trace and the desk's page stay in this hall. The [technical companion](/book?map=Point_Trace&section=technical) distinguishes these records and their transfer routes.

[^Point_Trace--point-trace-inscription]: Sigmund Freud’s [“A Note upon the ‘Mystic Writing-Pad’”](https://web.english.upenn.edu/~cavitch/pdf-library/Freud_WritingPad.pdf) (1925) and Jacques Derrida’s “Freud and the Scene of Writing,” in [*Writing and Difference*](https://press.uchicago.edu/ucp/books/book/chicago/W/bo27619783.html), translated by Alan Bass (1978), open a neighbouring inquiry into inscription, retention and the relation between a mark and what is no longer present. Here they open a question to pursue: what can a retained mark tell us about a movement that has already passed?

---

## Point Line Grid

*Point_Line_Grid*

### Grid Quantizes Movement

Look for your bend. It may have grown.

A drawing released in Trace can arrive here as a list of positions. Over the ruled field, a small movement has acquired another size. Keep it in view. We are going to give positions addresses, then ask what those addresses help us make.

#### Find somewhere to return


Pick up the snapping sphere and move it slowly. Its marker follows your hand while the retained line waits, then gains another corner. Between those changes, there is room to move.

Trace already made choices about which positions to keep. Here the table shows the last ten kept positions, naming each in metres and in whole-number steps from the origin. With five centimetres between grid positions, `0.15` metres along X has index `3`: three steps from world zero. The same place has two names.

The calculation, reduced to one axis, is:

```gdscript
var index = roundi(pos.x / grid_size)
var placed_x = index * grid_size
```

Divide by the spacing. Round to the nearest integer. Multiply back to get metres. At this spacing, `0.12` becomes `0.10`; `0.13` becomes `0.15`. One centimetre of movement can carry the record across a five-centimetre interval. Elsewhere, a larger movement can leave its address unchanged.

Let go. The tool brings its marker onto the lattice. Pick it up, move away, then try to return to that address. Several nearby positions can round to the same result. Your hand has room to vary while the point finds its place again. This can help us make two pieces meet without placing them exactly by eye.[^Point_Line_Grid--point-grid-bowker-star]

Both columns in the table describe the position the program kept. Your hand can still be somewhere between the addresses.

#### Give the interval a rhythm


Walk a small loop, then look behind you. Two accounts of the walk remain: a finer sampled reference and a path rounded to one-metre spacing in the recorder's own frame.

Find a place where you can move while the coarse address holds. Slowly cross into another. Cross back. There is a rhythm in the jump, and room to move within the interval. A rule for making positions agree has also given us something to dance with.[^Point_Line_Grid--point-grid-ahmed-return]

A lean with your feet planted can enter this record too: it follows your headset across the floor. It must choose a point before it can draw a path called yours.

The lines connect the positions it keeps. A diagonal can cut across ground you went around. Returning to an earlier address can add another turn to the record; the program keeps an order of visits, not just a collection of places visited once. The address marks a return; your reason for coming back has stayed with you.

#### Let the drawing find another use


Return to the ruled field. Find your bend in pink, then compare green. Is it still your bend at this size?[^Point_Line_Grid--point-grid-carry]

This display subtracts the centre of the received drawing's bounds and applies a scale:

```gdscript
mesh.surface_add_vertex((p - center) * final_scale)
```

Pink gives the drawing another centre and size. Green rounds those displayed positions onto a new grid. The panel still lists the original positions: the program can give a record another appearance without rewriting what it received.[^Point_Line_Grid--point-grid-replay]

A turn made by your wrist might now suggest a route for your whole body. Is there a part you would want to follow? A record can become a score, but it needs another decision about what following means.

#### Give the address a floor


Step onto the small plan in its glass enclosure. Five rows cross five columns: twenty-five one-metre cells. Their printed indices run from zero to four.

Entering in VR gives each hand a pen. Draw a small circle with the cyan left hand, then try it with the amber right. Cyan follows the sampled movement. Amber places its horizontal positions above the nearest cell centres. A small circle of your hand may leave the amber line waiting at one address.

The floor has entered the drawing. Its addresses reach up into the air, but they have not taken over every direction. Lift the amber hand without moving it sideways: height still has room to vary. Stepping out returns the pens; the traces linger briefly, then clear.

Find a cell using both numbers. Leave it and find it again. You can now describe where a cube might stand without pointing. Two indices can become an instruction for placing it.[^Point_Line_Grid--point-grid-scott]

Cross a row, then cut diagonally. The drawn divisions do not stop you. A continuous collision surface supports the plan. Over the other basin, the museum supplies walkable glass; the replayed lines provide no floor of their own.

An address can tell a program where to put something. What lets a body reach it needs further work.[^Point_Line_Grid--point-grid-lefebvre]


A shared address can help us repeat a placement or coordinate a meeting. The grid gives us a way to name a place and return to it together.

Next, three points can close a boundary. What must we add before there is a face inside it?

[^Point_Line_Grid--point-grid-bowker-star]: Geoffrey C. Bowker and Susan Leigh Star, [*Sorting Things Out: Classification and Its Consequences*](https://mitpress.mit.edu/9780262024617/sorting-things-out/) (MIT Press, 1999), study classifications and standards as information infrastructure, including whose differences become visible or disappear within them. The operational comparison here is treating different inputs as equivalent: it can support coordination while leaving distinctions out. Its consequences depend on what we build with that equivalence.

[^Point_Line_Grid--point-grid-ahmed-return]: Return to Ahmed, [*Queer Phenomenology*](https://www.dukeupress.edu/queer-phenomenology), introduction: bodily orientation involves relations of alignment and reach. Dancing with the interval is Ada’s proposed use of this rule, not a result already established by her argument.

[^Point_Line_Grid--point-grid-scott]: James C. Scott, [*Seeing Like a State: How Certain Schemes to Improve the Human Condition Have Failed*](https://yalebooks.yale.edu/book/9780300252989/seeing-like-a-state/) (Yale University Press, 1998), chapter 1, examines practices of administrative legibility, including cadastral mapping. The connection here is narrow: a plan can make a placement describable to someone not standing beside it. This does not make every grid coercive or establish that a legible plan is sufficient for inhabiting the place.

[^Point_Line_Grid--point-grid-lefebvre]: Henri Lefebvre, [*The Production of Space*](https://www.wiley-vch.de/de?isbn=9780631181774&option=com_eshop&title=The+Production+of+Space&view=product), translated by Donald Nicholson-Smith (Blackwell, 1991; French original 1974), chapter 1, distinguishes spatial practice, representations of space and representational spaces. His account keeps planning, practical activity and lived meanings in relation. The vitrine enters that problem without reproducing the whole theory: addresses and a plan do not by themselves establish access, habits, belonging or a place’s meaning to its inhabitants.

[^Point_Line_Grid--point-grid-carry]: If the field is empty, return to Trace, draw with a dot or stick until it retains at least two points, and release it. That release sends the record onward. The whiteboard and walking recorder keep separate records.

[^Point_Line_Grid--point-grid-replay]: Small drawings grow fivefold; larger ones receive a smaller multiplier to fit within five metres. Green rounds the displayed positions with six intervals per metre along each axis. The [technical companion](/book?map=Point_Line_Grid&section=technical) gives the transforms and the panel's page controls.

---

## Point Triangle Context

*Point_Triangle_Context*

### Closing a boundary, adding a face

Three points can close a boundary. What must the machine add before there is a face to look at?

You have connected endpoints, recorded a path and given positions addresses you can return to. Now bring three edges together. Something can close without becoming a surface.


Bring two edges into place. Look through the remaining opening before adding the third. What do you expect to arrive with the last connection?

The boundary closes. You can still look through its centre into the room. Press **SHOW / HIDE FILL** on the small panel beside it. A translucent patch now hangs between the same three corners. Press again: the patch disappears and the edges stay.

We have made two things happen separately. Connecting the endpoints closes a loop. Adding a triangle mesh gives that loop a visible face. The first operation does not secretly contain the second.

The button waits for the completed boundary. Once it is closed, its mesh receives the three target positions:

```gdscript
mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
for p: Vector3 in target_positions: mesh.surface_add_vertex(p)
mesh.surface_end()
```

The word `TRIANGLES` asks the renderer to treat each three vertices as a face. The positions alone did not ask for this. Their order, the primitive type and the material participate in what you see.


The wall plate places the same three corners side by side: first as points, then as a boundary, then as a face.

![Three identical sets of points A, B and C: points alone, connected boundary, and pink triangular face.](/book-review/doc/book/figures/Point_Triangle_Context/triangle-construction.png)

*One set of positions. Connecting them closes a boundary; filling it adds a face.*


This fill is visible from both sides. Walk around it, looking for a view where the patch narrows almost to a line. Its three corners have not moved; you have. Move back and watch the face open again.[^Point_Triangle_Context--point-triangle-winding]

Three distinct, non-collinear points determine a triangle and a unique plane. “Non-collinear” means that the third point is not on the line through the other two. Without that condition, the boundary can collapse into a line with no area.

#### Close a loop, then inspect the fill


If you released a drawing in Trace, your bend waits here as black corners joined into an open path. Without a carried drawing, a small white triangle waits for you to reshape.[^Point_Triangle_Context--point-triangle-carry]

Three decisions were taken to bring that trace this far. Six positions were kept out of the hundreds you made, sampled at even intervals along the stored order rather than at the turns you thought you were making. The shape was scaled to arm's reach. And your height was dropped, because a fan asks what lies inside a plane, and your hand was not working in one. Your drawing has been made fillable. Look at what that cost before you close it.

Pick up the drawing point and finish the loop: move near the first corner and wait for it to take. Positions fall on a ten-centimetre grid. The addresses we met in Grid now help corners meet.


Look up from the small drawing. Its twin hangs in the middle of the hall, more than three times its size. Take a corner of the small figure and move it. The large corner moves with your hand. Lift it out of the plane, then walk around what changed.

White faces catch the room's light; black edges keep their joins visible. A small adjustment can become a fold large enough to face you. Both figures use the same ordered corners. The enlargement lets your body meet a drawing your hand can still reach.


Look for the filled face. The side instrument counts **loops** and **triangles** separately. Press **SHOW / HIDE FILL** and compare the surface with its retained boundary. Both copies lose their white faces together; their black points and edges stay.

Now release the tool at the corner where your loop began, and press **SHIFT START** once. The same corners begin their order one place along.

If your bend turned back on itself, the fill may have reached into somewhere your hand never went. Look for a patch beyond the boundary.

Try a six-corner L, drawn flat, with two equal arms. Begin where the two long outer edges meet and follow the boundary around the notch. **NEW OUTLINE** lets you begin without erasing your earlier faces; the drawing guide gives the dimensions and timing.[^Point_Triangle_Context--point-triangle-construction]

Once the L closes, release the tool at its first corner and press **SHIFT START**. The same six points now begin at the next corner. Should beginning elsewhere change what lies inside the L?

The boundary has not moved, but the added fill reaches into the missing notch. Something is covering a place you left open.

Every triangle in this fill shares the first corner. The tool connects it to successive pairs around the loop: a fan of triangles. Call the original start A and the next corner B. Beginning at B, it submits these four triangles:

```text
B C D
B D E
B E F
B F A
```

Follow their edges across the notch. The code kept its rule; the rule failed to keep your boundary. Choosing another start changed the input order, not the polygon's interior.

Keep shifting the start around the six corners. The fill changes; the count remains four triangles for this L. When START returns to A, the original fill returns. The counter includes the triangles that overspill. It can count a construction without deciding whether it fills the intended region.

The method works for a triangle and for a convex planar polygon. Some concave polygons also work from suitable starting vertices. Concavity by itself does not guarantee failure, which is why this comparison keeps the boundary fixed and changes the start deliberately.

You could choose a better starting vertex where one exists, redraw a shape the fan handles, or keep this outline and ask for another filling algorithm.[^Point_Triangle_Context--point-triangle-triangulation]

Or keep the overspill. Follow the patch beyond the notch: a wing, a pleat, something extending beyond its frame. It has failed to fill this L; it may have given you a shape you want to make.

Carry this distinction onward: closing a boundary, making a face and choosing how to show it are operations we can separate. A convenient method need not require everyone to want a convenient shape.

Try the four-edge puzzle too. Its closed outline still has no face. Nearby, the quad joins two triangular patches along a diagonal. Move a corner away from that diagonal: one patch follows while the other stays. Move an end of the diagonal and both change. Four corners have given us two faces that can tilt differently. Remember their shared edge when a cube offers you what looks like a single square.

Next, faces meet at a corner. What must we add to enclose a volume?

[^Point_Triangle_Context--point-triangle-winding]: For the rendering convention, see [Godot 4.6’s SurfaceTool documentation](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html): triangle front faces use clockwise winding. Vertex order, shading normals and the material’s culling setting have different jobs. The puzzle deliberately displays both sides. That choice changes visibility; it does not give the face thickness or a collider.

[^Point_Triangle_Context--point-triangle-triangulation]: One available development route is Godot’s [`Geometry2D.triangulate_polygon`](https://docs.godotengine.org/en/4.6/classes/class_geometry2d.html#class-geometry2d-method-triangulate-polygon), which returns triangle indices for a 2D polygon and an empty result if triangulation fails. A planar 3D drawing would first need coordinates in its plane, followed by mapping the returned indices back to its vertices and handling winding. This room still uses its first-vertex fan; no alternate triangulator is installed by this note.

[^Point_Triangle_Context--point-triangle-carry]: The trace travels on the same `TraceData` autoload that brings your drawing to the ruled field in Grid: releasing a drawing dot or stick in Trace appends a snapshot of its retained positions, and this tool reads the most recent one. If nothing was released there, or you have come to this room first, the tool opens with one editable triangle, also shown by the large twin. NEW OUTLINE begins another drawing while keeping that triangle. A carried trace is left open; the twin does not close it for you. The reduction to six corners, the rescaling and the flattening happen on arrival, not in Trace; the stored positions are unchanged, and the whiteboard's image travels by no route at all.

[^Point_Triangle_Context--point-triangle-construction]: The [technical companion](/book?map=Point_Triangle_Context&section=technical) gives the six coordinates and the manual two-fill comparison. SHIFT START changes the last completed loop; release the pen and every corner, and leave no unfinished outline. The instrument reports START and whether the action is ready. Letters A–F name our route here; the tool displays numbered corners.

---

## Primitives Polythedra

*Primitives_Polythedra*

### Trihedra and First Solids

The face you made in the last room could be seen from either side. Now let faces meet. When do they begin to enclose something?


Pick up the open corner and turn it. Follow the three triangles toward the point they share. Then look through the opening opposite that point. Something suggests an inside, although one side is missing.

Count the faces before looking at the code. Three. The artifact is a finite model of a trihedral corner: three faces meeting at one vertex. Its four stored positions are connected like this:

```gdscript
[0, 1, 2]
[0, 2, 3]
[0, 3, 1]
```

Position `0` belongs to all three triangles. The other positions make a rim around the opening. No row joins those three rim points into a base.

We have turned the face into a corner. We have not yet closed a surface around a volume.


Turn the tetrahedron a few steps on. Find a face where the first object has an opening. Follow its edges toward the opposite vertex. Four faces now complete the enclosure.[^Primitives_Polythedra--polyhedra-separation]

Adding a base to the open corner would close a tetrahedron. This neighbouring example is regular, with four congruent equilateral faces. Its proportions differ, so compare how the faces connect before comparing their shapes.

Look at the tetrahedron as a little room with no door. Imagine it large enough to stand inside: where would you enter? The renderer draws the boundary without filling the interior with material. Enclosing a region has not supplied a way into it.

Now look back through the open corner. Would a small object fit through its missing side?

The same four positions used for drawing enter another construction:

```gdscript
var convex_shape = ConvexPolygonShape3D.new()
convex_shape.points = geometry["vertices"]
collision_shape.shape = convex_shape
```

The convex collision hull spans the four positions, including the base absent from the drawing.[^Primitives_Polythedra--polyhedra-hull] Rendering leaves an opening; physics receives a closed shape. The points have entered two rules and acquired different boundaries.


Look at the two versions on the wall. The amber base makes visible a boundary you could not see on the object in your hand.

![The open trihedron beside the convex hull of the same four points; an amber face shows where physics closes the missing base.](/book-review/doc/book/figures/Primitives_Polythedra/polyhedra-boundaries.png)

*Four positions, two boundaries. The amber face shows where the convex hull closes the opening.*

That does not mean your tracked hand must stop there. Which body collides, with which layers, matters too. The geometric surface remains open; passage for a particular simulated body is another question.

#### A corner makes room

Walk toward a pink corner. A triangular face meets you before the two walls do. Follow its lower edge across the floor, then look up to the point where it ends. The corner looks cut away because we have filled it.

Imagine four points: one at the old floor corner, one farther along each wall at floor level, and one directly above the corner. Join every pair. Three triangular faces lie against the floor and the two walls. The fourth faces you. Behind it, the collision hull occupies the enclosed volume.

This tetrahedron is a **three-dimensional simplex**. We have been approaching it all along: a point, a line segment, a triangle, a tetrahedron. Each step adds a point outside the space spanned by the previous ones. Here four points that do not lie in one plane are enough to enclose a volume.

The small regular tetrahedron has equal edges. This one takes its proportions from the room: three edges leave the old corner at right angles. Follow the pink face into the walls. Its fit depends on their agreement.

Walk up to it. The room has gained a solid and lost a little space for your walk. To make one body fit, we have changed the room available to another.

#### A face meets the floor


Find the bare prism examples toward the entrance side of the room. Follow a triangular end, then an edge joining it to the other end. The triangle has acquired a length. Two triangular ends and three connecting faces bound a triangular prism.

Compare the whole block with the quartered version and the open frame. Their visible construction changes; all three retain the original prism's collision surface. The gaps offered to your eye have no corresponding cutouts in that surface.

Approach a utility wedge from its low end and try walking toward the raised floor. Compare that approach with an upright face. Where can forward movement become upward movement?

The museum builds these wedges from a walkable prism scene, scaling the rise and the run:

```gdscript
w.scale = Vector3(1.0, maxf(0.05, rise), maxf(0.2, run_cells))
```

The low edge must meet the floor; the upper edge needs somewhere to arrive. The moving body's collision and slope settings also participate.[^Primitives_Polythedra--polyhedra-gibson] If a join catches you, notice where. A continuous-looking route still has to work as a route.

You can hold a small solid and inspect it. A larger arrangement of faces begins to carry the inspector. The lesson has moved from the object in your hand to the conditions of your own movement.


Approach the striped concrete enclosure and follow its outside edge. Its stepped profile is carried along a length too, with a collision body added. Related constructions can offer ascent or interrupt a route. Geometry does not decide the use.

A barrier might protect a place to stand; a slope might lead somewhere difficult to leave. Follow what this arrangement permits before deciding what you would change.


STOP stands beside the concrete. Did you pause at the word or at the physical boundary? Recall WALK THIS LINE: an instruction can orient you without enforcing collision. This sign has no collision body of its own.[^Primitives_Polythedra--polyhedra-ahmed]

Read one arrow on its blue disc, then look where it points. An arrow can propose a direction without knowing whether the route is traversable.

Look back at the barrier and the slope. Which would you change, and whose movement would it change? The fixtures are fixed here; this is a proposal to carry onward.

Keep the distinction: enclosing a region, admitting a body and suggesting a direction require different decisions. Next, a cube is taken apart so we can follow how its faces are made.

[^Primitives_Polythedra--polyhedra-separation]: For the Jordan–Brouwer separation theorem, see Zuoqin Wang's [Topology lecture 23](https://staff.ustc.edu.cn/~wangzuoq/Courses/20S-Topology/Notes/Lec23.pdf), Theorem 2.7 (2020). In three dimensions, a surface embedded in Euclidean space and homeomorphic to a sphere separates its complement into two components, one bounded and one unbounded. The tetrahedron's boundary fits these conditions. This establishes separation, not a collider, an entrance or habitability.

[^Primitives_Polythedra--polyhedra-hull]: Godot's [ConvexPolygonShape3D](https://docs.godotengine.org/en/4.6/classes/class_convexpolygonshape3d.html) is a solid collision shape. The opening here belongs to the rendered mesh, not to that hull. A collision model assembled from surface triangles is a different construction; Godot's [ConcavePolygonShape3D](https://docs.godotengine.org/en/4.6/classes/class_concavepolygonshape3d.html) is intended chiefly for static geometry. This is not an instruction to replace a held object's hull with a concave shape without considering its physics behavior.

[^Primitives_Polythedra--polyhedra-gibson]: James J. Gibson, [The Ecological Approach to Visual Perception](https://memoof.me/download/1058/pdf/1058.pdf) (1979; linked Classic Edition), chapter 8, relates a surface's affordance of support to the animal's size, weight and behavior. The wedge invites a computational comparison: passage depends on the surface and the moving body's implementation. The engine's settings do not exhaust Gibson's account of perception or the visitor's bodily experience.

[^Primitives_Polythedra--polyhedra-ahmed]: See Sara Ahmed, [Queer Phenomenology](https://www.dukeupress.edu/queer-phenomenology) (2006), Introduction; the fuller discussion accompanies WALK THIS LINE. Here orientation returns through a sign beside a physical boundary. Reading an instruction and meeting collision remain different operations.

---

## Point Animatedcube

*Point_Animatedcube*

### Cube Assembly from Primitives

You have been inside boxes since the first room. Now one of them lets you take hold of a corner. What must stay in place for it to remain a cube?


Begin with the outline. Follow the three edges leaving one corner. Look through to the far side. You can recognise a cube before any faces have appeared, although nothing has yet closed the gaps between these lines.

The previous room gave us forms that could support a foot or interrupt a route. Here we return to their construction. What happens when the parts remain connected but their positions change?


The builder may have finished before you arrive. Press **REPLAY** on its front instrument. Corners appear, then edges, then triangular patches. Press **PAUSE** at the moment you recognise the shape. How much did you need to see?

Only this assembly pauses. The folding net and the rest of the room continue. We have borrowed a little attention from a world already running.

The source has prepared the geometry before this presentation begins. The animation reveals pieces that were hidden. What looks like construction is also an arrangement of when we are allowed to see.

Resume. Once the assembly finishes, the numbered corner handles become available. Keep the second builder unchanged as a reference. On the one you will alter, find `v6`. Follow the square face containing `v4`, `v5`, `v6` and `v7`. Predict what will happen if you pull `v6` out of that face's plane, leaving its other corners where they are.

Move it a little. Look along the face. Where did the crease appear?

Try to locate the seam before pressing **DIAGONALS**. The yellow lines show the six diagonals that divide the cube's square faces into triangle pairs. Your hand has made one of those divisions matter.[^Point_Animatedcube--animatedcube-triangulation]

That face is stored as two triples:

```gdscript
[4, 5, 7]
[5, 6, 7]
```

Each number names a vertex. Both triples contain `5` and `7`: their shared edge. Only the second contains `6`. When you move that corner, the second triangle tilts while the first stays in place. A face that appeared to be one flat square can now bend along a choice made in its construction.


![The same cube face before and after corner 6 moves out of its plane. Triangles 4-5-7 and 5-6-7 share the amber diagonal; only the second triangle tilts.](/book-review/doc/book/figures/Point_Animatedcube/cube-hidden-diagonal.png)

*The diagonal was already there. Corners 4, 5 and 7 stay still. Moving corner 6 makes the shared edge into a crease.*


The builder reads a moved handle back into its position list:

```gdscript
vertices[i] = handle_nodes[i].position / cube_size
```

The edge and triangle lists still refer to the same vertex numbers. The neighbours remain; equal lengths, right angles and flat square faces need not.[^Point_Animatedcube--animatedcube-boundary] The display measures the largest corner shift in local metres. It cannot tell us what the changed form is worth.

Release the handle and press **REPLAY**. The layers return around your altered shape. Then try **RESTORE CUBE**. This time the initial corner positions return too. Repeating a presentation and undoing a change are different ways of beginning again.

Compare the two builders. Name one property your alteration preserved and one it lost. You can keep a crease you like without claiming the result is still a cube.


Further on, watch the net fold. Choose one square and follow it from the flat arrangement into the closed form. Before it folds again, predict which faces will meet.

Here each square stays rigid. The hinges turn. In the builder, you moved a corner and bent a square into two differently tilted triangles. Similar-looking movement can come from different operations. Knowing which data changes helps you predict what a form can do.


Now look down at the floor, then along a wall. Find the box form again in the crates. The museum builds its floor slabs and wall blocks from scaled box meshes. The primitive on display has also been carrying us from room to room.

The initial cube pairs twelve triangle patches into six square faces.[^Point_Animatedcube--animatedcube-counts] The crates add geometry for planks and reinforcing strips. We can recognise the box across these different meshes.

You can move a corner on the instrument while the museum's boxes support and redirect your body. What we are learning to inspect is also the place from which we inspect it.


A long shelf holds boxes. Brown cardboard, wooden crates, dark cargo cases, bright printed cartons. Four columns repeat four different models. In the last two, the crate and the printed carton return with changed colours, boards and words. The eye starts sorting before the hand reaches anything.

![The Cube hall’s shelf of cardboard boxes, wooden crates, cargo cases and printed cartons, with an empty table in front.](/book-review/doc/book/figures/Point_Animatedcube/prefab-library.png)

*The first four columns repeat their models. The last two let the same model differ.*

These are *prefabs*: reusable objects stored as scenes. A placed copy is an *instance*. The planks, straps and lettering arrive together, carrying decisions someone has already made. We can begin with a furnished object before knowing how to build each of its parts.

One carton says **AGAIN**. Take it down. Another says the same thing from the shelf. Moving your copy has left the others where they were.

There is pleasure in finding it again: a familiar shape, an interval kept, a difference small enough to search for. A crate can belong to the scenery of many games before it belongs to this room. Its familiarity travels with it.

Warhol's *Brillo Boxes* bring another kind of repetition here. His 1964 sculptures were fabricated plywood boxes, painted and screenprinted with commercial packaging imagery. Their exhibition arrangement recalled a warehouse.[^Point_Animatedcube--cube-warhol] Work had gone into making something whose appearance was already familiar. Our printed carton is an original design, but it borrows that tension between an ordinary package and an object given our attention.

The table is empty. Put two identical copies together. Add a different box. Turn its lettering away, or let **AGAIN** face **OTHER**. You have kept the supplied shape and changed its neighbours. The collection offers a vocabulary; it also makes some choices easier to imagine than others.

Look back at the gaps on the shelf. The arrangement records what you took.


Read the cartons: **A WORLD / WITHOUT / COMPOSITION**. The supply pile and the stamped crate add **YET**.

*A world without composition yet.* There was already an arrangement around us. On the table, another has begun. We have borrowed its parts, and made a relation between them.

Take the crease with you: a small movement exposed a decision inside a familiar shape.

The next room asks what an engine gives us when it supplies another familiar name: a sphere.

[^Point_Animatedcube--animatedcube-triangulation]: Godot Engine 4.6, [Using the ArrayMesh](https://docs.godotengine.org/en/4.6/tutorials/3d/procedural_geometry/arraymesh.html), rectangle example: four positions are connected by two triangle triples. This builder submits its patches through `SurfaceTool` in triangle mode. A flat convex quadrilateral admits either diagonal; moving a corner out of its plane can make that choice visible as a different crease.

[^Point_Animatedcube--animatedcube-boundary]: *Connectivity* names which vertices, edges and faces are incident; their positions place that structure in space. Compare the separate point and connectivity properties in Botsch, Sieger, Moeller and Fabri's [Surface Mesh manual](https://doc.cgal.org/latest/Surface_mesh/index.html), CGAL 6.2.1, “Connectivity” and “Properties.” Here the index lists preserve the combinatorial structure, but moving vertices may produce crossings or collapsed faces, so a valid geometric embedding is not guaranteed. The builder's patches also lack enclosing collision geometry; its handles have pickup colliders. See the [technical chapter](/book?map=Point_Animatedcube&section=technical).

[^Point_Animatedcube--animatedcube-counts]: Euler's [Elementa doctrinae solidorum](https://scholarlycommons.pacific.edu/euler-works/230/) (1758) investigates polyhedral counts. For the initial cube, `V - E + F = 8 - 12 + 6 = 2`. Splitting its squares adds six diagonals and six faces: `8 - 18 + 12 = 2` again. A proof for the sphere's triangulation appears in Heinz Hopf's [Selected Chapters of Geometry](https://pi.math.cornell.edu/~hatcher/Other/hopf-samelson.pdf), §I.3, from his 1940 lectures reconstructed and translated by Hans Samelson. The equality does not certify cube shape or a valid embedding. The instrument counts twelve patches, excluding reverse rendering copies.

[^Point_Animatedcube--cube-warhol]: The Andy Warhol Museum, [Brillo: Is It Art?](https://www.warhol.org/lessons/brillo-is-it-art/), on the fabrication and 1964 Stable Gallery exhibition. These were constructed sculptures carrying packaging imagery. The library’s AGAIN carton is a new design for this encounter.

---

## Primitives Ignorance

*Primitives_Ignorance*

### Limits of Geometric Knowledge

You left a cube whose connections could outlast its name. Now try the name sphere. What are you accepting when you recognise something as round?


Begin with the ordinary sphere near the entrance. Look at it from a distance, then approach. Follow its silhouette against the room beyond it. Where does the outline give you something to inspect that the name had allowed you to pass over?

Above the entrance: **Let No One Ignorant of Geometry Enter.** It recalls the motto traditionally associated with Plato's Academy.[^Primitives_Ignorance--ignorance-inscription] Here we have entered with a little geometry. We will use it to inspect the limits of the forms that seemed to admit us.


Inside, five solids have been given five places. Tetrahedron, cube, octahedron, dodecahedron, icosahedron. Off-white and almost black, each rests on a plain block. You can lift one and bring a face toward you. Its edges remain sharp. There is nothing unfinished about that sharpness.

Columns surround the group. Near the entrance their sides are easy to count; farther along, the corners draw closer together. Four divisions, then five, six, eight. Eventually the column looks round. Walking along the court, you pass through several constructions of the same architectural name.

The solids do not take that journey. An icosahedron has twenty faces because it is an icosahedron. Adding more would give you something else. In the next room, the sphere keeps its name while the number of faces changes. What did the name ask us to preserve?


The next room holds three pairs of spheres. Start with the first pair in the resolution display. One sphere wears lines along its triangle edges; the other has plain shading. Predict whether removing the lines also changes the sphere's outline. Walk around the pair and compare.

The two meshes have the same vertex positions and triangle connections. The lines are an added overlay. They make a construction easier to follow without rebuilding its surface.

Choose one place where the silhouette changes direction. Step back until that distinction becomes difficult to see, then approach again. Your distance changed. The mesh did not.


Continue to the middle pair. Inspect it from a comparable distance. Which distinctions are easier to find now? Compare the marked example with its plain neighbour before comparing it with the finer pair behind you.

The finer pair uses sixteen rings and sixteen radial segments; this pair uses seven of each. Those two settings divide different directions of the surface. Changing them changes the positions and connections available for making it.


At the coarsest pair, follow one flat patch toward its edge. Is this merely a sphere missing something, or is there a feature here you would choose to keep?

Its construction uses one ring and ten radial segments. One direction is divided more often than in the middle example, the other much less. Resolution has a distribution. It does not arrive as a single quantity called detail.

The script gives the two choices separate names:

```gdscript
sphere_mesh.radial_segments = segment_count
sphere_mesh.rings = ring_count
```


Across the room, twelve smaller spheres spread the two choices out in space. Across each row, more rings divide the height. Along each column, more segments divide the circumference. Their triangle edges remain visible. You can follow one change while the other holds still.

A crowded equator can belong to a sparsely divided body. One figure has a broad flat face where another gathers many narrow triangles. Both answer to sphere. Before deciding which is more convincing, look for a shape you had not expected to find there.

A mathematical sphere consists of points at a fixed distance from a centre. The mesh joins sampled positions with flat triangles. Adding triangles can improve that approximation; no finite collection of flat patches acquires the sphere's continuous curvature. Shading can soften their appearance while the polygonal outline remains.

![The existing high, middle and low sphere artifacts in matched views: triangle edges visible above, hidden below. Each column keeps the same mesh.](/book-review/doc/book/figures/Primitives_Ignorance/sphere-visible-construction.png)

*The lower row keeps every triangle in the upper row. The lines disappear; the construction remains.*

This is where ignorance turns around. Plato distinguishes the drawn figure from the geometric object considered in thought. Here we turn our attention toward the constructed figure: what its polygons leave out, and what their particular arrangement makes available.[^Primitives_Ignorance--ignorance-plato]

The formula specifies a sphere. The mesh gives us one finite construction through which to encounter it. The ridge is available too. We can learn from its shape without requiring it to disappear into a smoother answer.


At the far end of this room, a counter makes the cost of these choices countable. Four numbered spheres turn at the same rate. Keep the counts hidden at first. Choose one for a distant background and one for someone to inspect close to their face. The spheres stay on their stands; you are choosing possible uses.

Press **SHOW / HIDE COUNTS**. Did the numbers change your choice? Then press **SHOW / HIDE EDGES** and follow the lines toward a pole.

Each tag gives two triangle counts. Even counting depends on what the instrument agrees to include.[^Primitives_Ignorance--ignorance-counts]

Hide the counts while keeping the edges visible, then try the reverse. What becomes easier to judge? Both controls alter what is shown while keeping the sphere meshes in place.

A triangle count does not measure frame time or tell us which object deserves to exist. For your proposed use, name the distinction worth spending geometry on. You might spend more on a close silhouette, or keep a facet because it makes this body recognisable.


At the centre, the five-sided capsule turns above a stepped pedestal. Eight pale tiers carry it: cylinders with four divisions through eleven, each smaller than the one beneath. Corners shift around the stack. The support is making its own argument about roundness.

The capsule is taller now, nearly the height of a person. Its dark surface receives the light slowly as it turns. A small, awkward construction has been given the place of an object worth lingering before. When a ridge faces you, picture the other side. Would the same ridge be waiting there? Follow the silhouette as another side comes into view.

Five segments divide the body around its long axis. Opposite a ridge is the middle of a facet. Half a turn does not bring this cross-section back onto itself. The divisions are evenly spaced, but their odd number interrupts that particular symmetry.[^Primitives_Ignorance--ignorance-capsule]

You cannot fold your understanding around this corner by simply repeating the front at the back. The shortcut fails. You have to follow another side, or learn the rule well enough to work it out. The object remains knowable; recognising a capsule was not yet knowing this one.

Stay with what the five divisions produced. Between the familiar pill and its polygonal construction, a body appears that the name did not prepare you for. Its surprise is made within the restriction. What would you miss if you corrected it into the capsule you expected?

This gives ignorance another direction: a limit in our expectation becomes somewhere to look. The same small set of instructions that confines the form can make more available than we first knew to ask of it.

![The five-segment capsule raised on eight cylinders, with resolutions four through eleven.](/book-review/doc/book/iterations/2026-09-27-ignorance-courtyard/five-on-four-to-eleven.png)

*The capsule keeps its five divisions. The pedestal changes the attention we give them.*


The third room has another collection of beginnings. A wedge, a ring, a plane. A pair of letters with depth. The engine supplies these constructions before we decide what to make of them. Each has been wrapped in a reusable scene, like the boxes in the previous hall.

Here, even the word primitive has practical habits. A plane offers a surface to subdivide. A quad supplies two triangles. Move beside them and their broad faces narrow toward an edge. The letters already carry a language; their geometry lets that language cast a shadow.

One stand holds a point drawn twenty-two screen pixels wide. Approach it: its mark keeps that pixel width while the stand grows in your view. This is another way of giving a point a visible body. It does not behave like the sphere we first called Point One.[^Primitives_Ignorance--ignorance-prefabs]

Two longer forms belong to the engine's trail meshes. Here they are shown at rest, before particles or moving bones would shape them into trails. Some of the engine's simplest forms are beginnings of movement.

The old studies remain through the side opening: the rock, the star, the choir, the extra cubes. The court has made a clear arrangement without exhausting what these forms might become.


Carry a more specific question than whether the sphere is good enough: **enough to hold which distinction, for whom, at what distance?**

The polygonal model has a limit; our first understanding of its possibilities has one too. The next room follows a finite sequence of round-looking objects toward a boundary none of its examples reaches.

[^Primitives_Ignorance--ignorance-inscription]: The Academy motto is a later tradition, not a securely documented inscription from Plato's lifetime. See [The Academy of Plato](https://mathshistory.st-andrews.ac.uk/Societies/Plato/), MacTutor History of Mathematics. The museum stages the familiar wording as an instruction whose authority we can question.

[^Primitives_Ignorance--ignorance-plato]: Plato, [Republic, Book VI](https://classics.mit.edu/Plato/republic.7.vi.html), Benjamin Jowett translation, the divided-line discussion: drawn figures serve reasoning about geometric objects rather than being its ultimate objects. Ada's reversal is methodological: stay with the implemented figure and investigate its limits and possibilities. This does not establish that Plato was unaware of imperfect drawings, or that geometry cannot describe curves.

[^Primitives_Ignorance--ignorance-counts]: Some generated triangle triples collapse at the poles. The counter distinguishes all submitted triples from those with measurable area in [Godot 4.6 SphereMesh](https://docs.godotengine.org/en/4.6/classes/class_spheremesh.html) arrays. “With area” excludes triangles below a local squared-cross-product tolerance of `1e-16`; it is a practical threshold. The [technical chapter](/book?map=Primitives_Ignorance&section=technical) records all four measured pairs of counts. Overlays and counter furniture are excluded. Analytic sphere descriptions and this finite polygonal rendering are different representations.

[^Primitives_Ignorance--ignorance-capsule]: The central installation reuses `capsule.tscn`, enlarged uniformly to 1.6 times its authored size. It uses a [CapsuleMesh](https://docs.godotengine.org/en/4.6/classes/class_capsulemesh.html) with five radial segments and five rings. Its regular pentagonal cross-section repeats after 72 degrees, but not after 180 degrees about the long axis. The absent half-turn symmetry does not make all symmetry disappear. The scene turns at 45 degrees per second. These are the authored mesh and spin settings, not controls available on the plinth.

[^Primitives_Ignorance--ignorance-prefabs]: Godot 4.6 [PrimitiveMesh](https://docs.godotengine.org/en/4.6/classes/class_primitivemesh.html) is a family of generated mesh resources. The new room wraps PrismMesh, TorusMesh, PlaneMesh, QuadMesh, PointMesh, TextMesh, RibbonTrailMesh and TubeTrailMesh in reusable scenes. Box, cylinder, sphere and capsule have already appeared; a cone is a CylinderMesh with one radius set to zero. QuadMesh inherits PlaneMesh. The [PointMesh](https://docs.godotengine.org/en/4.6/classes/class_pointmesh.html) display uses a point-size material: its 22 pixels describe the rendered mark, not a world-space diameter. Trail specimens show their undeformed rest geometry.

---

## Primitives Portals

*Primitives_Portals*

### Circular Approximation and Limits

The previous room asked when a finite model was enough to hold a distinction. Here we make that question move. Add a division, then another. **What would count as arriving?**


Begin beside an early faceted ring. Follow a straight edge around its opening, then look along the progression. Choose a later ring that seems round enough from where you stand. Keep that choice in mind as you approach it. Does the edge you had stopped seeing return?

These are portals for looking through: twenty rings that frame the space beyond. Near the beginning, their flat patches are easy to see. Each following member divides both surface directions more finely.[^Primitives_Portals--portals-mesh]

At the side instrument, use **NEXT RING** and **PREVIOUS** to select a member. It turns gold. Find the selected ring in the space. The button directs your attention while leaving your body where it is.

Beside the counts, a rose-coloured polygon sits inside a grey circle. Selecting a finer ring adds sides to the polygon while the circle stays. This separate, flat figure borrows one of the torus's subdivision counts to ask a simpler question: how closely can straight sides approach a circle?

The circle has radius one. For its inscribed polygon, the code calculates:

```gdscript
var perimeter: float = 2.0*mesh.rings*sin(PI/mesh.rings)
```

Each straight side is a chord between two points on the circle. Adding sides brings their total length closer to the circumference, which the panel labels **Circle**. The positive gap belongs to this planar comparison; a measure of the whole torus's accuracy would need its own definition.[^Primitives_Portals--portals-circle]

![Three states of the museum diagram: three, eight and twenty-two straight sides approach the same circle.](/book-review/doc/book/figures/Primitives_Portals/portals-visible-limit.png)

*The corner becomes harder to see. The gap remains. These are three states of the same diagram beside the rings; the numbers compare boundary lengths.*

This is **convergence**: as the rule continues, the perimeters approach a limit. They can get arbitrarily close to the circumference, though no finite polygon in this sequence has that exact perimeter. Twenty examples show part of an approach that can continue beyond the display.

Suppose you needed this polygon for something you were making. You could set a small positive gap you were willing to accept and stop when a member met it. That bound is a **tolerance**. It might lead you to a different choice from the ring that first looked round enough.

Press **REVERSE** and return to the beginning. The positions stay; the same family of resolutions appears in the opposite order. What the earlier arrangement kept for later has become the entrance.

The sequence had quietly given refinement a direction. Walking the other way, corners become available again. You might want one of those corners. Adding more sides would take it away.

Through this change, the openings remain. More divisions need not give the body another kind of passage.[^Primitives_Portals--portals-hole]


Two figures wait along the next instrument's track. Press **NEXT STEP** and watch the space between them.

Achilles is placed where the tortoise was. The tortoise moves ahead again. In this construction the gaps halve at each stage. The marked end of the track stays where it is.[^Primitives_Portals--portals-zeno]

The first stage carries Achilles halfway along the track, the second three quarters of the way. Each new stage leaves half the remaining distance. The endpoint is close enough to point to. The rule keeps putting him short of it.

At stage ten, the instrument holds. The bodies may look as though they have arrived together, but Achilles' anchor is still less than six millimetres from the limit. His visible body is larger than the gap. The display has a last stage. Does the sequence it represents have one?

Use **RESTART**, then **PLAY** to let the figures move between stages. Pause them partway through a movement. The panel keeps both distances in view: where Achilles is now, and where this step was taking him.

The program gives these stages a regular schedule and adds movement between them. That schedule does not reproduce the shrinking durations of a continuous runner's journey. An infinite subdivision can have a finite total; it does not make ordinary motion impossible.

This instrument can pause while the museum continues. We have held one process still long enough to ask about it.


Twenty rings. Ten stages. Each display has a last member because someone chose where to stop building it. Neither mathematical approach acquires a last step merely because its display has ended.

**The limit gives the sequence a direction. It does not tell us where to stop.**

There may already be a ring you want to return to. A finite encounter can teach us something without exhausting what its rules make possible.

Melencolia gathers the tools we have learned to use. They can give exact answers. What would make the work complete?

[^Primitives_Portals--portals-mesh]: The installed `combine_portals` uses [Godot 4.6 TorusMesh](https://docs.godotengine.org/en/4.6/classes/class_torusmesh.html). `rings` divides the torus around its opening; `ring_segments` divides the tube's cross-section. The authored linear rule uses `(3 + i, 3 + 2i)` for indices 0–19. The panel calls the latter **Tube sides**. Its selection highlights a mesh; these rings do not implement teleportation.

[^Primitives_Portals--portals-circle]: For a regular `n`-gon inscribed in a unit circle, each chord has length `2 * sin(PI/n)`, giving perimeter `2 * n * sin(PI/n)`. `TAU = 2 * PI` is the circle's circumference. In exact mathematics the perimeter is smaller for every finite `n ≥ 3` and converges to `TAU`. A useful tolerance can be met before equality. A floating-point calculation may eventually round a gap away; that is a separate computational event. The [technical chapter](/book?map=Primitives_Portals&section=technical) explains what the instrument measures.

[^Primitives_Portals--portals-hole]: These subdivisions preserve the torus surface's central opening. Resolution and topology are different questions: more triangles do not give this surface another hole. Whether an opening is a usable passage also depends on scale, placement and collision. Keep that distinction for the later investigations of possible spaces.

[^Primitives_Portals--portals-zeno]: Aristotle discusses the Achilles argument and the bisection argument in [Physics, Book VI, parts 2 and 9](https://classics.mit.edu/Aristotle/physics.6.vi.html), translated by R. P. Hardie and R. K. Gaye. This exhibit stages a particular halving construction: `A_n = L(1 − 2⁻ⁿ)` and `T_n = L(1 − 2⁻⁽ⁿ⁺¹⁾)`. Its six-metre track ends the display at stage ten, leaving `6/1024` metres between Achilles' anchor and the limit. Autoplay schedules stages two seconds apart and eases movement for one second. That theatrical timing is part of the implementation, not a proof about the duration of a physical race.

---

## Primitives Melencolia

*Primitives_Melencolia*

### Melancholy of Finitude

What keeps you looking after you know the form?


Four pale blue pyramids mark the corners of a raised square. Before going closer, try to hold the arrangement in mind. Where would you put a fifth?

Walk around the court. One pyramid passes in front of another. A gap opens where two outlines seemed to meet. The objects have stayed still; your movement changes the picture. You have met this distinction before, but now the picture has become a place with room around it.

Take the side ramp onto the platform. The four corners repeat a form you can describe: a square base, four triangular sides, one apex. Five vertices, eight edges, five faces. Knowing those counts helps you recognise the family. It leaves you free to notice something else.


The fifth pyramid is pink, taller, and stands in the centre on a matching block. Look back at a corner. Does the centre seem to organise the others, or have you made it important because it rises above them?

Its base is still square. Its apex is still a single point above it. The tall pyramid's source collects the base vertices and then adds that point:

```gdscript
vertices.append_array(ring)
vertices.append(_apex_position(ring))
```

The same connections can carry a different height. In this version the pyramid's base is 0.8 metres wide and its apex rises 2.8 metres above that base. The pink block lifts the whole pyramid another 0.8 metres above the court. The script triangulates the square base into two faces for rendering; together with the four sides, that makes six triangles. We can explain how it is built without settling what its height does to the arrangement.


Four ochre cubes sit around the spire in a cross. Follow that cross with your eyes, then look toward the corner pyramids. A few familiar solids are becoming a court, a monument, perhaps a model of somewhere you would like to go. Which reading arrived first?

The arrangement returns to the room's earlier floor plan. Its reference belongs to an anonymous sixteenth-century manuscript of geometric and perspective studies: solids drawn, combined and staged until a study begins to suggest an unfamiliar architecture.[^Primitives_Melencolia--solids] Here the forms stand on a platform made from the same cube vocabulary as the museum floor. The support is already part of the picture.

Imagine one cube placed outside the cross. Its construction would be unchanged; its relation to the court would be different. You do not need to build every possibility before leaving this one.

![The museum court from three viewpoints: aligned, oblique and a plan from above.](/book-review/doc/book/figures/Primitives_Melencolia/melencolia-one-arrangement.png)

*The same court, from three viewpoints. At the left, two corner pyramids hide two others. None of the objects has moved.*


Beside the front of the court, five snap points offer a small construction. Connect four into a base cycle and join each to the fifth. Watch what the puzzle accepts.

Its detector recognises those connections. It does not measure whether the base is square. Keep that distinction close: the program can complete its test while your question about the form remains open. The court was here before the test succeeded. Its place in the room has another history.


#### The tools are still here


Follow the raised connection to the next platform. The large stone stands to the left; the winged figure sits to the right, her head resting on a fist. A sphere lies near the sleeping dog. Above them, the ladder, scales, hourglass and bell give the wall its own order. Beneath them, a saw and a carpenter's plane lie among the small tools. Here the forms have company.[^Primitives_Melencolia--durer]

The compass is in her hand. She has not lost the instrument. A book lies on her lap, and the skirt falls in heavy folds over her knees. Beside her, a smaller winged figure bends over a tablet. One is drawing. The other looks away.

Earlier, a sphere could introduce a primitive. Here it occupies ground beside a tired animal. Nothing has happened to the sphere's definition. Much has happened to what we can see in it.

We have carried something from the court of ideal forms into this clutter of work and waiting. We might call it *geometric desire*: the wish that a form might let us see further, or give us somewhere else to stand. Here that wish meets a body that cannot be reduced to its instruments. Knowing how to construct another solid does not tell her what to do next.

Walk sideways. The stone hides the smaller figure, then lets it appear again. Our sculpture gives depth to an engraving; Dürer did not leave us the far side of this room. Those hidden surfaces are decisions we have made. The apparent completeness of the model rests on what the picture could not tell us.

![The reconstructed Melencolia tableau inside the museum.](/book-review/doc/book/figures/Primitives_Melencolia/melencolia-tableau.png)

*After Dürer's engraving: an arrangement of sculpted figures, tools and solids. Their placement follows the image; their depth is an interpretation. Walking changes which objects conceal one another.*

The stone has six pentagonal faces and two triangular ends. Its mesh begins with a rhombohedron and cuts off two opposite corners. The proportions are one possible reading of the printed form. We can make a closed solid without claiming to have recovered the only solid the image permits.

Now look up at the numbered square. Choose a row and add it before reading further.

```text
16   3   2  13
 5  10  11   8
 9   6   7  12
 4  15  14   1
```

Try a column. Each row and column, and the two main diagonals, sums to 34. The 15 and 14 in the bottom row recall 1514, the year of the engraving. The numbers work.

Stay a little longer. Has that correct answer finished what you came to look at?

#### What do we want a form to promise?

This desire will return with different demands. In the patterned surfaces of the Alhambra, geometry belongs to built space; Escher's study of its mosaics later fed his own investigations of repeating figures.[^Primitives_Melencolia--pattern] A rule can continue beyond the piece of wall that holds it. Our museum also stops building at an edge while letting us imagine more.

Malevich's tilted square in *White on White* offers another possibility: a painted surface can suggest release into unbounded space. Hilma af Klint's *Paintings for the Temple* give abstract forms a different task, within a spiritual inquiry.[^Primitives_Melencolia--abstraction] The same circle would not mean the same thing in each of these worlds. What someone asks of it matters.

And abstraction need not carry us away from the body. Lygia Clark's hinged metal *Bichos* ask for hands: a flat arrangement opens into a changing object.[^Primitives_Melencolia--clark] To call this Brazilian work only escapist would miss that return to touch. Perhaps the escape is from having to remain a spectator. What can geometry make possible between a form and the person who meets it?

Keep that question beside the seated figure. The tools are here. Their next use is not settled.

#### The number that was already running


By the way out, a number is changing. It is the same counter you met on your first step into this chapter: `Engine.get_process_frames()`, process frames since the engine started, read fresh on every call.

It is much larger now. Some of that is yours — the picking up, the drawing, the walking, the shifting of a start. A fixed quantity of it is not, and never will be. The frames that passed before you had somewhere to stand did not become yours by being counted alongside the ones that followed. This number adds them together anyway. It has no field for the difference.

In the first room we said that its first number for you was not its first number. That is still the one thing it will not tell you, and you now know several reasons why. A record keeps what its rule admits. Someone chose the rule. The number keeps growing while you read it.

#### Enough to continue

Dürer's engraving is itself a made thing. An accomplished image gives us an encounter with unfinished work. That matters here. Looking, arranging, imagining and taking pleasure in a form can keep an investigation moving while its purpose is unsettled. The aesthetic attention is already doing work.

A few tools, and more possible constructions than we have time to pursue.[^Primitives_Melencolia--sublime]

Look back toward the five pyramids. They have become another picture from here. The objects stayed still while your viewpoint changed. In transformation, you can watch from one place as objects move, turn and scale. Choose one relation from this court—the repeated corners, the tall centre, the distance between the platforms—and ask what would survive such a change.

We leave with enough to continue. There is still something here we have not finished looking at.


[^Primitives_Melencolia--solids]: Anonymous, sixteenth-century geometric and perspective manuscript, Herzog August Bibliothek, Cod. Guelf. 74.1 Aug. 2°. See [*Solid Objects*](https://publicdomainreview.org/collection/solid-objects/) and the [image selected for this room](https://pdimagearchive.org/images/4577a16c-d0e9-43d6-96fc-f125c47c6afe/). The court follows the drawing's blue corner spires, pink centre and ochre blocks within the earlier AdaResearch floor arrangement. Its dimensions are adapted for the museum. The manuscript is not attributed here to Dürer; its additional compound solids remain references for later studies.

[^Primitives_Melencolia--durer]: Albrecht Dürer, *Melencolia I* (1514), [Metropolitan Museum of Art](https://www.metmuseum.org/art/collection/search/360018). The museum describes several interpretations rather than a settled key. The [National Gallery of Art](https://www.nga.gov/artworks/6641-melencolia-i) provides a detailed visual description. AdaResearch follows the principal objects and their image relationships in a stylised sculptural arrangement. Depth, rear surfaces, dimensions and the solid's proportions are authored interpretations. The passage from ideal form to embodied hesitation is this book's reading, not a settled account of Dürer's intention.

[^Primitives_Melencolia--sublime]: Kant's [*Critique of Judgement*](https://www.gutenberg.org/files/48433/48433-h/48433-h.htm), §§25–27, discusses the mathematical sublime through the distinction between apprehending parts and comprehending a whole; §49 describes aesthetic ideas as occasioning thought beyond what a determinate concept can exhaust. These offer a later vocabulary for this room's investigation: how a finite arrangement can keep attention moving among possibilities we have not yet specified.

[^Primitives_Melencolia--pattern]: The [Metropolitan Museum's account of geometric pattern](https://www.metmuseum.org/essays/geometric-patterns-in-islamic-art) describes its construction and combination with other ornament. It does not license a single spiritual meaning for all Islamic geometry. [Escher in The Palace's timeline](https://escherinhetpaleis.nl/en/about-escher/timeline) records his sustained study of the Alhambra and Córdoba mosaics in 1936; tessellation already appeared in his earlier work.

[^Primitives_Melencolia--abstraction]: Kazimir Malevich, [*Suprematist Composition: White on White* (1918)](https://www.moma.org/collection/works/80385), MoMA; Hilma af Klint, [*Paintings for the Temple*](https://www.guggenheim.org/teaching-materials/hilma-af-klint-paintings-for-thefuture/paintings-for-the-temple), Guggenheim. These are distinct historical projects. Their juxtaposition here asks what abstraction promises; it does not establish a direct line of influence from Dürer or treat spiritual claims as scientific evidence.

[^Primitives_Melencolia--clark]: Lygia Clark, [*Poetic Shelter* (1964)](https://www.moma.org/collection/works/91767), MoMA, and the museum's account of [Neo-Concrete art](https://www.moma.org/collection/terms/neo-concrete-art). Clark's participatory work is a particular Brazilian response to geometric abstraction, not a description of every South American modernism. The suggestion that participation changes what escape can mean is this book's proposal.

---
