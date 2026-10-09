# Voice references — current complete chapters

These are reference chapters for pacing and specificity, not templates. Each hall asks a different question.

## Point_One

Source: commons/maps/Point_One/final.md

> *The first point has already broken the promise of taking things one step at a time.*

… You arrive late.[^1]

<!-- @frame_counter_display -->

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

We have read the line that asks for that number. Much of the code making it readable remains unopened. It is like standing on the shoulders of giants in fog: other people's work has brought us here, but height alone does not give us a clear view.

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

Nearby, four words are printed on the floor: “~~you~~ are here.” The first is struck through.

Take hold of the struck word. It lifts. The crossed-out “you” comes away as a thing you can carry, and the rest of the sentence stays exactly where it was printed, still saying *are here* to the room. Set it down somewhere else and look back at what is left behind.

The location remained legible without its visitor. That is not a trick of this decal; it is what an address is for. What part of you has arrived at this one?[^point-one-ahmed-reach]

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

The dark point offers itself to your hands. Pick it up. Move it a little to one side, then back. Its surface changes when you take hold. Put it down and pick it up again: its coordinate label changes format with each pickup. One format leaves the body without a printed address.

The first point has already broken the promise of taking things one step at a time. There is shine here, a surface, a changing body. We are already Alice. We can follow that interest into the construction, where the things meeting us at once were made separately.

A mathematical point specifies a location without extension.[^point-one-euclid] Here, a sphere makes the position visible. A collision shape and pickup code make the artifact available to your controller. Seeing it and being able to hold it are different things the program has to arrange.

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

`%.2f` rounds each component to two decimal places in the text: `1.231` and `1.234` both print as `1.23`. The stored position is left alone. Several nearby positions can share this shorter address. Your hand can move without the number changing. The apparent stillness belongs to the report.

Now compare it with the card marked `LOCAL`. Move the same point between two places. Both cards answer, but with different numbers. What would you need to know to read either address?

<!-- @CoordinateSystem3M -->

Follow the coloured frame's guides as you move the point in your hand. Red follows X, green follows Y, blue follows Z. Move along one direction, then across it. The guides separate a movement into components, letting you follow several directions within one gesture.

`WORLD` measures the point's position in the scene's coordinate system. The coloured frame supplies another reference, with its own origin, orientation and scale. Its script uses `to_local()` to express that same position relative to the frame. The `LOCAL` card prints the result beside `WORLD`. The numbers differ because they answer to different references. Remember the case's `FOCUS`: its 1.25 was measured from the case, too.

A coordinate needs its reference. Reading more digits cannot supply one that has been left unnamed.[^point-one-haraway]

Carry the point beyond an arrow's end. The drawn axis has a length; the coordinate system can describe positions beyond it. An earlier version confined the point to the arrows' span. A drawing made to explain movement had also been deciding where movement could end. The frame now keeps describing the point outside that span.

<!-- @drag_point_target -->

The red arrow says “drag point here”. Carry the point towards it without letting go. Watch for the falling balls.

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

Return again, and a destination can become an instrument. Come straight back once; next time, take a longer way round. The target accepts both arrivals, but you have changed the pause between them. A detour may matter to what you are making while remaining absent from the distance test. We could give the target a memory of the journey; we would then have to decide what it remembers, and what someone else could read from it.

<!-- @ -->

The counter has continued through all of this. A position has acquired a body, different addresses, a tolerance for arrival. It still leaves questions unanswered.

One of them travels with us: how did it get there?

The next room brings two points into relation. A line begins.

[^1]: Heidegger’s *thrownness* names finding ourselves already delivered into an existence we did not choose—not simply arriving after the clock started. Here, the room offers a small encounter with that condition. Genesis, first light: we look for a beginning. But is this the world beginning, or our first glimpse of something already underway? See [*Being and Time*, §29](https://www.beyng.com/pages/en/BeingandTimeMR/BeingandTimeMR.174.html).

[^point-one-ahmed-reach]: Sara Ahmed, [*Queer Phenomenology: Orientations, Objects, Others*](https://www.dukeupress.edu/queer-phenomenology) (Duke University Press, 2006), introduction. Ada’s questions about orientation and reach draw on her account of bodies finding their bearings through relations with objects, spaces and others. Lines will make this conversation more explicit.

[^point-one-euclid]: Euclid, [*Elements*, Book I, Definition 1](https://mathcs.clarku.edu/~djoyce/elements/bookI/defI1.html), defines a point as that which has no part. This is a historical starting point for the abstraction, not a specification of a Godot object. A stored position, a visible marker and a collision body require different constructions; the invisible point lets us keep them apart.

[^point-one-haraway]: Donna Haraway, [“Situated Knowledges: The Science Question in Feminism and the Privilege of Partial Perspective”](https://doi.org/10.2307/3178066), *Feminist Studies* 14, no. 3 (1988), 575–599, especially 581–585. Haraway argues for embodied, situated and accountable knowledge, challenging both a view from nowhere and an easy relativism. Naming a coordinate frame is not equivalent to that epistemology. It gives this room a technical way to ask a related question: what must accompany a reading for someone else to understand its reference and limits?

[^point-one-room-history]: Ivan E. Sutherland, [“A Head-Mounted Three Dimensional Display”](https://doi.org/10.1145/1476589.1476686) (1968), especially “Results”; [accessible paper](https://archive.aec.at/media/assets/636b23b07bfd1b4f1d1154827ac9d9ab.pdf). The wireframe room and response to head movement are described there. The acknowledgments name a collective effort, and the funding note names ARPA, the Office of Naval Research and Bell Telephone Laboratories. This is one historical encounter with these problems, not a claim that the museum follows a single line of descent.


## Trans_Scale

Source: commons/maps/Trans_Scale/final.md

## A door, at last

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

`FACTOR` is four. The food and the figure belong to `room`, so the same multiplication reaches their positions as well as their dimensions. The figure is farther from the table now. Increasing only their dimensions would have left the distance between them unchanged.

The arrival on the plate is another operation. Scaling the room would not put you there. The program takes the top plate's local position and asks where it has arrived in the enlarged world:

```gdscript
var feet := table.to_global(landings[0]) + Vector3.UP*0.08
```

Then it moves your body to that position. The multiplication and the relocation arrive together as an encounter, but they do different work. One changes the room; the other chooses where you meet it again. A small clearance keeps your feet out of the porcelain.

Follow the plates down. Their winding descent was already present when they were small. Nothing in their arrangement needed to be invented after you took the bottle. Yet the distance from one to the next now belongs to balance, gravity and the time spent falling. The program did not multiply your walking speed or the gravity with the room. Uniform scaling has left a very uneven experience.

Find the little door again. It was forty-five centimetres wide and sixty high. Now it is 1.8 metres wide and 2.4 high. Walk through.

Just beyond it stands a second gold frame, also 1.8 metres wide and 2.4 high. Pass through that one too. It stood at this size before you took the bottle.

![The tiny gold doorway and its enlarged version in the actual museum, viewed from the same standing height and distance.](/book-review/doc/book/iterations/2026-09-23-scale-door-and-body/door-and-body.png)

*The camera stays 1.65 metres above the floor and 2.5 metres from the opening in both views. On the right, the second gold frame beyond the doorway has stayed at its original size.*

The little doorway has kept its proportions. There is a difference between preserving a shape and preserving what someone can do there. If the bottle had enlarged you by the same factor, would that doorway have become an exit?

The figure has not become hostile by becoming enormous. Her unfamiliar body remains with you through the change. The same is true of the food: its strangeness preceded its usefulness as a landscape. You can learn a route through something without exhausting what it is.

Beyond the two frames, turn toward the museum's own exit. The little door has brought you out of the furnished room; there is still a short walk to the next hall. The museum continues at its ordinary scale. The second frame belongs to it. That boundary belongs to the code too: this room was chosen as the thing that could grow. The next hall returns the question to the body that made the comparison possible.

<!-- @ -->


## Tutorial_Tiling_Walls

Source: commons/maps/Tutorial_Tiling_Walls/final.md

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

<!-- @wall_exception -->

Near the far end, on the right, the same pattern reaches a narrow part of the museum wall. EXCEPTION changes a tile here too. Walk towards it. The image has changed; the wall still holds you on this side.

Find TURN WALL beside it. Press, then wait for the sheet to finish turning. Its pattern travels with it. The opening leads onto a small landing outside the hall. Step through and look back along the edge.

From here the panel is almost nothing. A thin sheet, a hinge, the plain reverse of the image. It was enough to stop us. Beyond the landing there is no floor to continue this walk. Until now, it was easy to keep looking ahead: another room, another thing to learn. Room after room, a thin enclosure kept an inside around our forward walk. Here we can look at its other side.

The two turns have done different work. EXCEPTION changed an orientation inside the image. TURN WALL moved the surface and the collision shape that travels with it. The first changed what we could read; the second changed where we could go. A quarter turn, learned among the transformations, has returned as a way to question the enclosure.

![The patterned wall closed and turned open, seen from the same position.](/book-review/doc/book/iterations/2026-09-23-tiling-wall-and-outside/two-turns.png)

*The same pattern, on the same sheet. Left: a tile has turned, but the wall is still closed. Right: the sheet has turned through a quarter turn, opening onto the landing.*

The landing was made too. Even this little outside has a floor and a rail. What else would we have to build to carry the walk further?

Return inside before turning the wall back. The wall will not turn through a body: it waits while someone occupies the landing or the space it sweeps, and pauses if someone enters during a turn. We can leave the path here, and we can rejoin it.

<!-- @ -->

We have carried one small motif through several relations, then changed the surface that receives it. The image gives the wall a rhythm; the wall gives that rhythm a place in your walk. Neither account is complete on its own.

The next floor will add a clock. Keep watching the distinction between a value, an address and the act of reading it. Repetition is about to arrive in time as well as space.


## SpeculativeComputation_Rhizome_Network

Source: commons/maps/SpeculativeComputation_Rhizome_Network/final.md

# Another way through

<!-- @rhizome_cave_demo -->

From outside, you can follow several passages with your eyes. One rises across another. Openings disappear into the tangle. There seems to be a way through.

Inside, the wall takes away that view. The passage divides. A coloured light gathers at a junction; further on, another opening offers another direction. You can leave a place and find it again without walking back along the way you came.

Try returning to the violet light by a different passage. What did you recognise first: the colour, the opening, the direction from which you expected it? A place can become familiar before you can draw its position in the whole.

We began with a line to walk. Here the line divides and meets another. The return is possible because the connections contain a circuit. A branching tree could offer many directions too, but, if its branches never rejoin, coming back would require retracing part of your route. One added connection can change what a journey is.

Above the lower passages, a longer route climbs and comes down elsewhere. From outside, two paths may seem to intersect. Inside, one passes over the other. You cannot turn at that crossing. Nearness is not yet a relation you can enter.

The distinction has followed us from the drawn line. A crossing on a screen may conceal a difference in depth. The triangle gave a surface to the image; here the surface surrounds you, supports your feet and keeps two journeys apart. The engine must decide where it holds. Your body encounters that decision as a floor, a slope, a wall.

These passages begin as connections between positions. For this encounter, their junctions and heights have been composed so that we can walk several returns, including the upper crossing. The small growing network nearby follows a different rule. It has not secretly designed this cave.

To give a connection room, the cave calculation opens a volume around it. Where two such volumes meet, their interiors join. There must be no leftover wall sealing the junction. A small line of code performs this union:

```gdscript
air[index] = minf(air[index], passage)
```

Each sample holds a signed value: negative inside a passage, positive outside it. The smaller value lets either passage admit the sample. The surface extractor finds the boundary afterwards. A line becomes a volume; overlapping volumes can become a shared interior.

But the width matters. Make a passage wider and it may meet a neighbour that its centre line never touched. Make it narrower and the drawn connection can remain while the body loses its way through. We have not escaped geometry by drawing a network. We have acquired another place to work on it.

Deleuze and Guattari give the rhizome multiple entryways and connections between unlike things. Their map is something that can be made and altered in contact with the world.[^1] The invitation exceeds this cave. We can enter its relations and choose among them; we cannot yet make a new opening in its wall. That is a desire the encounter can produce. Where would you put one? Which two places would become neighbours?

There is pleasure in finding another way. There can also be shelter in the turn that takes you out of sight, or company at a junction where separate routes arrive. These possibilities give a connection more than one use. A space can be legible to a drawing and still hold something for the body to discover.

<!-- @rhizome_grower -->

The small grower offers a different kind of arrival. A new point appears and reaches towards points already there. An older point can receive a relation it could not have anticipated. The newcomer cannot reach into its own future.

Hold the growth and compare one link with three. The positions stay. Some of the ways between them disappear. You have changed no point's address, yet moving through the network would be a different undertaking.

Here we can inspect the rule more closely. Each arrival chooses nearby earlier points. There is no declared root, but proximity and time still make some points more available than others. Removing a busy point asks a further question: which relations survive without it? The model can restore the point and its former links. Inventing a new connection would be another act.

The ring does not spread with the shoots. The machine keeps finding new places inside a boundary it chose before the network began. Something is growing, but its territory has already been given.

That boundary is easier to see at this scale. Inside the cave, its equivalent was a wall. We can enjoy what these rules make possible and still want to change where they stop.

<!-- @ -->

The museum has an onward direction. You have just spent time returning, approaching from another side, making a route that was yours to choose. Carry that desire into the assembly laboratory. There, the available parts will ask what other body they could become.

[^1]: Gilles Deleuze and Félix Guattari, *A Thousand Plateaus*, translated by Brian Massumi (University of Minnesota Press, 1987), “Introduction: Rhizome,” especially pp. 7–15. Connection, heterogeneity, rupture and a modifiable map extend beyond the shape of a branching object. The cave offers a material experiment in passages and returns; it does not make a network's complexity a guarantee of freedom.

