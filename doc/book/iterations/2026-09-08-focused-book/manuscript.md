# Ada Research: the focused room manuscript

Snapshot, 2026-09-08. All 190 live-spine rooms, in their current order. Existing chapter text and supporting passages are retained. New chapters are source-checked first drafts; this export does not certify that their encounters are working or reachable. The live source remains each room's final.md.

## Primitives: Points Build Worlds

### 001. Point One

[Live text](http://localhost:3003/compose?map=Point_One)

You arrive late.

The room was running before you entered. You are here now. Before learning what a point is, try to locate one: what would you have to see, touch or read to be certain it had moved?

<!-- @frame_counter_display -->

Watch the counter long enough to see several increments. Pause for a breath, then look again. Does a change of one tell you how long you waited?

The counter's default reading is the engine's total processed frames since startup:

```gdscript
var frames: int = int(Engine.get_process_frames())
```

One more frame, one more count. The interval between counts can change. This is a count, not a frames-per-second reading. Equal increments can contain unequal waits. Already, something has happened that the number does not describe.

<!-- @ -->

##### Hold a location

<!-- @interactive_point_origin_force -->

Pick up the dark point. Move it a little to one side, then back. Follow its position label and the line toward the origin. If the label disappears, put the point down and pick it up again: successive pickups cycle the display formats, including a hidden one.

The held object also changes its appearance and can act as a force catalyst. For this first experiment, follow the position through that change. What remains locatable when its visible form changes?

What you can see is a sphere. A mathematical point has no extension; it specifies a location. The sphere gives that location a visible body and something the hand can acquire. Its surface, collision shape and force behavior are properties of this artifact, added around the point it lets us investigate.

Three numbers can express the position in a chosen frame:

```gdscript
var p := Vector3(1.0, 0.5, 0.0)
```

Those numbers do not include the sphere's radius, the shape of your hand or why you moved. A `Vector3` stores three components; deciding to use them as a position gives those components their job.

<!-- @origin -->

Find the origin marker. Compare it with the moving point. One can move while the reference remains still.

```gdscript
var origin := Vector3.ZERO
```

The origin is a point made special by convention. What is chosen is that *this* one is called zero. A world can be described from that reference without making it the only possible reference.

<!-- @ -->

##### Read where you are

The wall readout, the red target and the coloured frame belong to one experiment. Keep hold of the same point as you move between them.

<!-- @coordinate_readout -->

Move very slightly while looking at the white card marked `WORLD`. Find a movement small enough that a printed component stays still, then make a larger movement along the same direction. Compare the card with the point itself before reading on.

The numbers have moved away from the point and onto a white card. You have to look between the moving thing and the sentence that locates it. The readout's operation can be written as:

```gdscript
func report_position(point: Node3D) -> String:
    var p := point.global_position
    return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
```

`%.2f` rounds the report to two decimal places. It leaves the stored position alone. The apparent stillness belongs to the display. How much movement can disappear inside a readable number?

<!-- @CoordinateSystem3M -->

Bring the point to the coloured frame. Red for X, green for Y, blue for Z. Move mainly along one axis and watch its marker, then move diagonally. Name which readings change before trying the next movement.

The axes name directions. Their common crossing supplies an origin, and their scale supplies units. Each marker shows a component of the position; the guide lines let you read the three together.

The white card reports world coordinates. The coloured frame has its own origin, orientation and scale; its script uses `to_local()` to describe the same position relative to that frame. Two addresses can locate the same point. The caption matters.

Carry the point past an arrow's end. Take it behind the crossing, into negative coordinates. The drawing has an edge, but the coordinate system continues.

An earlier version confined the point to the span of the arrows. Keeping the demonstration tidy had made its lines into walls. The frame can instead keep describing where the point went. Knowing a position need not mean keeping it in place.

<!-- @ -->

##### Find out what “here” means

<!-- @drag_point_target -->

Carry the same point toward the red arrow. The instruction says “drag point here”. Predict how exact the arrival must be. Approach from one side, leave, and approach from another. Watch for the falling balls, then compare the two arrivals.

A coordinate has become a request. Here is the target's distance test, reduced to a function for one position:

```gdscript
@export var catch_radius: float = 0.45
@export var catch_height: float = 1.20

func accepts_position(p: Vector3) -> bool:
    var centre := global_position + Vector3(0.0, catch_height, 0.0)
    return p.distance_to(centre) <= catch_radius
```

“Here” is a region: a sphere of radius 0.45 metres, centred 1.20 metres above the target's origin. A hand has room to arrive. The test asks whether the point is close enough; it does not make that position identical to the centre.

The target requires no release and accepts points registered in its coordinate-point group. Your intention never enters the comparison. A careful delivery and an accidental pass can produce the same weather.

Take the point out and bring it back. The target is configured to rearm. The room asked you to complete a task; you can make a rhythm out of completing it. How long before the reward becomes the material you came to play with?

Try a detour before the next arrival. What would the target have to remember to distinguish that journey from a direct delivery? A success test can recognise a destination while leaving the journey unrepresented.

<!-- @ -->

##### Follow the fold

<!-- @folding_past -->

Look into the nested frames. Follow the recession with your eyes, then turn back toward the point you moved. The frames offer a way to picture a past: a nesting, the present caught within what came before. That is an interpretation of their arrangement, not a history recovered from the point's coordinates.

You arrived late, but you can choose what happens next.

<!-- @ -->

Before leaving, choose a position and predict which readings will change if you move it upward. Make the movement. Then name one difference between two arrivals that the target cannot recognise.

One point gives a position. Two points make a relation. Repeated positions can become a trace; a grid limits where samples may land; three non-collinear points can close a triangle. Every step gains expressive power by deciding what to keep, and every decision leaves something at its edge.

The next room connects two points and asks what a line can be made to do.

### 002. Point Lines

[Live text](http://localhost:3003/compose?map=Point_Lines)

A point had no parts. Keep two positions now, in the same coordinate system. What can you change about their connection without changing which points are connected?

<!-- @line_demo -->

Bring the two black points near one another and release to request a connection. Watch for the segment between them. Once it appears, move one endpoint a short distance. Predict which part of the connection will change, then move it another way.

The connection manager keeps the relation in both directions:

```gdscript
_adjacency[point_a].append(point_b)
_adjacency[point_b].append(point_a)
```

These lines sit inside checks against duplicate connections. Each point gets a neighbour. A changed length or direction need not be a changed neighbour.

<!-- @line -->

Compare the connection you made with the already drawn line. A visible segment can be represented by its two endpoints:

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(1, 0, 0)
var displacement := b - a
var distance := displacement.length()
```

Here the distance is one metre. The displacement also tells us which way from A to B. Two distinct points determine an infinite straight line; restricting it to what lies between them gives a segment. Storing that geometry and storing a neighbour relation answer different questions.

The demonstration had to learn how to show this. When its spheres grew larger, they swallowed the short connecting line. The connection existed in the program and disappeared in the picture. Making a relation legible takes another decision after making it exist.

<!-- @ -->

##### Read it with your feet

<!-- @walk_this_line_marking -->

The white stripe comes with a verb: *WALK THIS LINE.*

Follow it for a few steps, then walk beside it. Try following it backwards. Compare what happens in the room with the correction you may feel tempted to make to your own gait.

The marking draws an instruction. It has no tracking code that rewards your obedience or registers your departure. Whatever correction you made through reading belongs to an encounter between a sign and a reader.

A line can be a useful guide. It can also make walking alongside it feel like getting something wrong. Walking it backwards keeps to the geometry and changes the walk.

<!-- @do_not_cross_barrier -->

*DO NOT CROSS.* Approach this one and compare it with the paint. Look below the visible plank before testing passage.

The barrier has acquired a collider: a box extending from the floor to the bar. A gap below the visible plank need not offer a gap in that box. Changing the words changes the request; changing the collider changes the obstruction. Neither requires moving the two ends.

Geometry, instruction and enforcement can occupy the same place. They still have to be made separately.

<!-- @ -->

##### Carry the whole line

<!-- @grabbable_line -->

Pick up the short rod. Turn it, carry it, then compare that movement with pulling the demonstration's endpoints apart. Which length stayed fixed?

The rod's ends belong to one body, so moving it carries both together. Turning changes its direction while its length stays fixed. A fixed span can become a unit for comparing other spans.

Move the held rod slowly through the room. Near whole-number values on a world axis, its centre triggers jitter, changing sound and, with a tracked controller, pulses. The disturbance belongs to its address, not its length.

Use that disturbance as an instrument: search for a quiet position, then find an edge where the noise returns. An imposed interruption can become a way to investigate the rule imposing it.

<!-- @two_point_ruler -->

The ruler holds a half-metre span between two marks. Beside it stand a pale block and a blue one. Compare the span with the pale block by looking. A unit is a distance somebody has decided to hold steady.

This placed display does not yet provide a hand-operated measurement action. Its intended extension is a more difficult question: measuring one object would alter the other while leaving the reported dimension true. For the working encounter here, keep the fixed span; the laser supplies a measurement you can perform.

<!-- @ -->

##### Move between the ends

<!-- @two_points_line -->

Watch the bright bead move between the two coloured endpoints. Before it turns, predict where it will slow down. Would the same segment require the same pace?

Interpolation places a point along a segment:

```gdscript
var p := a.lerp(b, t)
```

At `t = 0`, it is at A; at `t = 1`, at B. Values between them stay on the segment. This bead's script moves the parameter back and forth with a cosine, slowing near each end.

The geometry supplies a route. Another function supplies a pace. Straightness alone never required haste, constant speed, or arrival at B as the end of the story. Watch the bead return.

<!-- @ -->

##### Measure, then change the measurement

<!-- @laser_measure -->

Take up the measuring instrument. Aim along the barrier, then at what stands behind it. Keep the beam on the barrier and watch for its response. Compare the reading before and after the obstruction breaks.

A ray needs a starting position and a direction. For distinct endpoints, dividing displacement by its length gives a unit direction:

```gdscript
var direction := displacement / distance
```

The tool casts forward up to its maximum range and reports the first physics body it hits. Its visible beam ends at that collision. This room enables its burning behavior: dwelling on the barrier calls the barrier's explosion action and removes its collider.

You have used measurement to change what can be measured. The number alone cannot explain why the distance changed.

<!-- @laser_exploding_sphere -->

The orange sphere provides another response to compare: controller pointer entry triggers its burst, and it returns after a cooldown. The measuring beam and the controller pointer are separate interfaces here. Similar-looking lines need not ask the same question of an object.

The sphere can return; the broken barrier stays gone for this loaded instance. One response supports repetition, while the other changes the route. That difference was authored after the geometry.

<!-- @parallel_lines -->

Walk around the three fixed parallel segments. Their apparent separation changes with your viewpoint. Their shared orientation remains, and their spacing need not be equal. Staying alongside one another leaves more undecided than a command to walk in one direction.

<!-- @ -->

Choose two positions in the room. Travel between them directly, then by a detour. Explain what a segment between the endpoints would keep from both journeys, and what it could not distinguish. You can do this alone, or let someone else choose the second route before comparing.

Next comes Point Trace. Instead of keeping only the ends, we will keep positions along a movement. Bring the detour. The next room has somewhere to store it.

### 003. Point Trace

[Live text](http://localhost:3003/compose?map=Point_Trace)

Bring the detour.

The last room could connect the place you started with the place you finished. Could the same connection tell a direct walk from a wandering one? Here you can give the journey a record, then find out what that record still cannot keep.

##### What the line forgot

<!-- @draw_dot -->

Pick up the first drawing point. In free space, make a short loop, pause, and return near where you began. Watch the line grow and read the retained-point count. During the pause, does another point enter merely because time passes?

Now make a second gesture: a small bend followed by a larger one. Look for the places where the line turns. Compare them with the turns you remember making.

A segment can be described by two endpoints and a rule for the between. There is nowhere in that description for a hesitation to be. This pen adds an ordered list of positions. It can keep an overshoot or correction when those movements produce different accepted samples. A stationary pause, by itself, supplies no new position.

The readout gives a retained count and its capacity, the movement threshold and the recording grid. These placed pens use a **5 mm movement threshold** and a capacity of **4096 accepted points**. The recorder first checks movement, then shapes the position, then rejects a shaped sample if it duplicates the last one.

That is three decisions before the line reaches your eyes: whether to look, where to put the reading, and whether another reading adds anything the list distinguishes.

<!-- @ -->

##### The same gesture, on four different grids

The four pens in the row offer a comparison. One has no added recording grid. The other three round to **10 mm**, **40 mm** and **80 mm** spacing. They are instances of one recorder, told differently where a reading is allowed to stand.

Repeat the small bend with the 80 mm pen. Then make a larger loop. Find a movement that changes the finer record while leaving the coarse pen at the same stored lattice position. Use the readout to check which pen you have, rather than relying on colour alone.

Away from a whiteboard, the spatial part of its rule is:

```gdscript
var s: float = resolution_mm / 1000.0
rec = Vector3(snappedf(rec.x, s), snappedf(rec.y, s), snappedf(rec.z, s))
```

This controls **where** a reading may land. The movement threshold is another rule, controlling when the tool considers a new reading. Coarse spacing can collapse different hand positions onto a position already occupied. The duplicate is never added to the list.

The accepted positions are connected by straight segments. Some segments may be diagonal; the tool does not promise an axis-by-axis staircase. The corners it keeps belong to the recording lattice, not necessarily to every bend of the hand.

None of these records is the movement. Even the finer pen receives discrete measurements. Its line connects them, making the unobserved between look continuous.

<!-- @draw_stick -->

Take the stick and try the loop again. Keep your fist nearly still and turn your wrist. Compare the movement of the fist with the movement at the tip.

The stick uses the same recorder as the dot, but the recording point sits at the end of a rod. A small turn of the hand can move that tip through a much larger arc. Changing what is sampled changes what the gesture becomes, even before changing the sampling rule.

<!-- @ -->

##### It forgets too

Go back to the beginning of a line you have made. Can you still locate it after a pause? What would have to happen for that earliest retained point to leave?

The current pens do not fade the live trail with age. Their capacity rule is:

```gdscript
if _trail_points.size() > trail_max_points:
    _trail_points.pop_front()
```

After 4096 accepted points, another accepted point pushes the oldest out. This is a point-count horizon, not a fixed number of frames or seconds. A pause does not spend another place. A gesture that repeatedly reaches new stored positions spends them differently from one that keeps returning to the same coarse position.

A smaller capacity would make that eviction easier to watch; changing it is a possible later experiment. The current encounter asks you to distinguish the rule from the number of seconds you have been drawing.

The prepared marks beside some pens are illustrations of ways a record might remain. They are not evidence that the tool has recovered a previous visitor's stroke. An archive needs both something retained and an account of where it came from.

<!-- @whiteboard -->

Bring the pen close to the whiteboard and compare a stroke along its face with one in free space. Near the board, the tool can project samples onto its plane and apply the recording grid in board coordinates. A board supplies a surface and another frame for writing. It does not, simply by being a board, turn this recorder into permanent storage.

<!-- @ -->

##### A record of whom?

<!-- @hand_telemetry_diptych -->

At the paired monitors, read the footer first: `TRACKING` or `DEMO FEED`. With a tracked controller, move one hand and follow its own panel. Keep it still for a moment and look at the timed rows. Compare that recording with the pen that waits for qualifying movement.

In desktop use, a demonstration feed can supply the moving numbers. It illustrates a log; it does not establish that your hand was measured. A full-looking record still needs a source.

The two panels divide a body into independently tracked parts. That can be useful. It also leaves the reader to decide what those parts mean together, and neither a coordinate nor a blinking recording light can supply that meaning by itself.

<!-- @automatic_writing_desk -->

The desk writes a different-looking record. When it finds a headset camera, movement of the camera's position changes the amplitude of its wordless script. Try leaning while watching the page, then holding still. Without that input, its demonstration motion can keep the page writing.

Head movement is not attention, and the marks are not words you composed. The warmth of handwriting can make a mechanical reading feel like a confession. Keep the movement, the encoding and the interpretation apart long enough to ask who is claiming to have read whom.

<!-- @ -->

Before leaving, invent two gestures the coarse pen struggles to distinguish. One could include a deliberate pause; another could vary within one lattice position. Say what extra information would preserve the difference you care about: a timestamp, another sample, a pressure reading, a note in your own words. Those are proposals for another recorder, not information this line secretly contains.

**The trace is transmissible as data and irrecoverable as event.** Copy every retained position and the original gesture still does not happen again. Yet the copy can be useful, and choosing what it needs to preserve is work you can participate in.

The next room takes this pen-scale question under your feet: how far can you move while a grid continues to report the same place?

### 004. Point Line Grid

[Live text](http://localhost:3003/compose?map=Point_Line_Grid)

How far can you move while the record continues to report the same place?

The last room let your hand write on several grids. Here your walk supplies the positions. Begin with a small movement whose differences matter to you, and see which of them the recorder admits.

##### A grid in the hand

<!-- @grab_sphere_point_snap -->

Pick up the snapping sphere. Read the ground table's spacing, retained positions in metres and lattice indices. Move slowly along one direction until two successive retained positions are neighbours. How far apart are the numbers? Release, then compare the marker with the last retained position.

This artifact uses a **0.05 m grid: five centimetres**. Keep that spacing in mind. The walking recorder will apply a related rule on a much larger lattice.

At five-centimetre spacing, successive coordinates along one axis can read `0.10`, `0.15`, `0.20` metres while the corresponding lattice indices read `2`, `3`, `4`. The index names a position in units of the grid spacing. The metre value gives the retained position in world units. They are two ways to read the same stored sample.

The table is a history of retained positions, not a raw-versus-rounded comparison. Follow the small drawing marker: the tool samples that point and aligns the same marker to the lattice on release. The retained table stays visible so you can compare the released marker with its last recorded position. Use this table for the experiment; the tiny floating label is a separate position display.

Try two nearby hand positions whose samples round to the same lattice point. Then cross the boundary that admits a different point. At what spacing would the difference you intended become readable?

<!-- @ -->

##### Put the grid under your feet

<!-- @player_trace -->

Walk a small loop beside the recorder, then a wider diagonal. Look behind you for the two paths. Compare their turns before trying to explain the gap between them. Pause, retrace part of your route, and watch what another crossing adds.

One path is a finer sampled reference. The other records positions rounded onto this placement's **one-metre lattice**. Both are records made by the machine; the fainter line is not an unsampled copy of your movement.

The recorder translates the tracked position into its own frame, then rounds local X and Z. It retains the local height with a small display offset, so the vertical coordinate is not rounded by this lattice. The result is an ordered path, with consecutive duplicate positions suppressed.

The spatial operation in this recorder is:

```gdscript
local_point.x = roundf(local_point.x / seam_grid) * seam_grid
local_point.z = roundf(local_point.z / seam_grid) * seam_grid
```

Divide by the spacing, round to an integer, multiply back. Several input positions become the same lattice position. Starting at a lattice node with one-metre spacing, half a metre along an axis reaches the boundary between neighbouring rounding regions. Near such a boundary, a small movement can change the recorded address abruptly.

Find one of those changes by walking. Then find a smaller loop that stays within a single rounding region. A large difference in your experience can become a small difference in the record; a small step across a boundary can become a whole metre in the record's coordinates.

<!-- @grid_lines -->

Compare the ruled grid with the path it helps you read. A lattice supplies addresses before any visitor occupies them. A line on a grid can continue across a gap in the floor; the existence of an address does not make its location a place you can stand.

That distinction matters whenever a plan begins to look like the territory it names. First ask where the reference is and how far apart its marks are. Then ask what the drawing authorises you to infer.

<!-- @ -->

##### A path, not a census

Return to a part of the room you have already crossed. Does the line retain the new journey, or merely announce that this place has been visited before?

The current recorder keeps lists of positions, sample times and speeds. Its capacity is **1024 accepted points**, and it removes the oldest entries when that capacity is exceeded. It is not a permanent dictionary with one entry per visited cell. A position can recur later in the ordered path.

Revisiting, pausing and remaining within one coarse position are different events. The record can distinguish only what its sample trigger and retained fields allow. In particular, a stationary pause does not continually add more position samples. Default fading is off, so merely waiting does not erase an older point either.

Applying the same rounding rule again to an already rounded position leaves it in place. This property is called *idempotence*. It says something precise about repeating the operation. It does not say the first application lost nothing.

The segments between accepted positions can be diagonal. The recorder connects what it kept; it does not reconstruct every step of a walk by choosing one axis at a time. Look for where a straight connection crosses ground you did not actually traverse.

<!-- @ -->

##### Whose grid, and for what?

<!-- @floating_sphere_field -->

The floating field offers movement you can watch while your own path is being recorded. A room can contain much more motion than one instrument follows. Being in the room is not the same as being in the dataset.

<!-- @room_grammar -->

A plan generated by rules asks a related question at the scale of walls and doors. An address is useful for composing a room, but the address alone does not say whether a visitor can reach what has been placed there. A second account of bodies, access and purpose is needed.

<!-- @ -->

A grid can make positions comparable under shared units and a shared frame. The same choices decide which differences that comparison can express. That does not make every use of a grid surveillance, nor every lost difference harmful. It makes the choice answerable to a task and to the people whose movement supplies the record.

Choose a purpose for your path other than reaching an endpoint: a pause beside something interesting, a detour to accompany someone, a small loop made for its own pleasure. Repeat it so that the coarse path looks as similar as you can make it. Explain which difference matters to your purpose and which additional record would let it count.

You can also keep the coarse record and decline to make it a complete account of you. The fit and the misfit can remain visible together.

The next room adds a third point. A path has been able to return to where it began; now we will ask what a closed boundary needs before it becomes a face.

### 005. Point Triangle Context

[Live text](http://localhost:3003/compose?map=Point_Triangle_Context)

Three points can close a boundary. What must the machine add before there is a face to look at?

You have connected endpoints, recorded a path and watched a grid choose where samples may land. Begin here by making the first closed triangle. Its applications can wait until you have something to apply.

<!-- @triangle_line_puzzle -->

Bring the line endpoints to the triangle's three targets and complete the boundary. Before the last connection, predict what will change when the open chain becomes a loop. Look at the result from another side.

Three distinct, non-collinear points determine a triangle and a unique plane. “Non-collinear” means that the third point is not on the line through the other two. Without that condition, the boundary can collapse into a line with no area.

<!-- @interactivetriangle -->

Move one corner toward the line between the other two. Watch the face narrow. Move the corner away again, then to the other side. Predict how the area will change before the next movement.

The handles alter vertex positions and the face follows. They do not hold the edge lengths fixed. A triangle made from three rigid rods cannot change its shape freely while keeping their lengths; this editor allows a different operation, changing the lengths themselves.

Two edges from the same corner give a way to calculate area:

```gdscript
var cross := (b - a).cross(c - a)
var area := 0.5 * cross.length()
```

At the collinear case, that cross product is zero. Away from it, the cross product also supplies a direction perpendicular to the plane. A rendered face needs more than the statement “three points”: it needs their positions and an order in which to use them.

<!-- @triangle -->

Compare the separate triangle example with the one you deformed. Colour and material can change how a face reads without changing the geometric relation that makes it a triangle.

<!-- @ -->

##### Close a loop, then inspect the fill

<!-- @draw_triangle_faces -->

Pick up the drawing point and make a small triangle in the air. The tool places a point while held when its one-second interval has elapsed and the tip has moved far enough from the previous point. Move to each intended corner, watch for the placed point, then return near the first to close the loop. The tool also rounds positions to its ten-centimetre grid.

Look for the filled face. Compare it with the lines you made. A boundary and its fill are separate constructions.

For another independent outline, release the pen and press **NEW OUTLINE**, then pick it up again. The button keeps completed faces and lets you choose a new first corner. Use it before each comparison below.

Make a six-corner L in one horizontal plane. Think of a 1.2-metre square with a 0.8-metre square missing from one corner. Each arm of the L is 0.4 metres wide. Keep the line from crossing itself.

For a precise version, the coordinates below name the two horizontal directions in metres, relative to the lower-left outer corner; keep every point at the same height:

```text
A (0.0, 0.0)     B (1.2, 0.0)     C (1.2, 0.4)
D (0.4, 0.4)     E (0.4, 1.2)     F (0.0, 1.2)
```

First follow **A → B → C → D → E → F → A**. Inspect the fill. Begin a new outline and follow the same boundary from its next corner: **B → C → D → E → F → A → B**. You can reuse the six existing corner points. Predict whether changing the first corner should change the intended region before closing the second loop.

The polygon has the same boundary and the same interior. The tool can produce a different fill. From B, some of its triangles extend into the missing notch. That is a failure to respect this boundary, not another equally valid interior of the same simple planar polygon.

Here is the choice the tool makes: it uses the first point as the centre of a triangle fan, connecting it to successive pairs around the loop. A six-point loop gives four fan triangles. The triangle count alone cannot tell whether those triangles fill the intended region without overlap or overspill.

The method works for a triangle and for a convex planar polygon. Some concave polygons also work from suitable starting vertices. Concavity by itself does not guarantee failure, which is why this comparison keeps the boundary fixed and changes the start deliberately.

Now choose what to preserve: the outline you intended, or this particular filling method. You could redraw a shape the fan handles, choose a better starting vertex where one exists, or propose another triangulation algorithm. The machine's convenient rule need not become a rule requiring every visitor to want a convenient shape.

<!-- @ -->

##### Which side you are on

<!-- @parasol_triangle -->

Walk around the triangle on its stick and compare its two sides. The different colours make a choice about visibility available to look at.

A triangle's ordered vertices determine an orientation. Swapping two reverses it. A material may hide back-facing triangles or display both sides. The geometric points do not by themselves decide which side a visitor is allowed to see.

Find a viewpoint from which the face becomes narrow. Has the triangle lost its area, or has its projected image become small? Compare that change of viewpoint with the earlier movement toward collinearity. Two similar pictures can have different causes.

<!-- @ -->

##### Four points, and a fold

<!-- @quad -->

At the split quad, move one corner out of the other corners' plane. Watch the two triangles beside the diagonal. What had looked like one flat face can acquire a crease while keeping its connectivity.

Three non-collinear points determine a plane. An arbitrary fourth point need not lie on it. Dividing the four-point patch into triangles gives each triangle its own plane; it does not force all four points to agree on one.

<!-- @quad_line_puzzle -->

Compare the four-line puzzle with your triangle. A square is one particular quadrilateral. Four fixed side lengths alone allow a hinged quadrilateral to lean, while three suitable fixed lengths determine a triangle's shape up to rigid movement and reflection. A square task therefore needs more constraints than a closed four-edge loop.

<!-- @pythagorean_triangle_angles -->

Use the squares on the triangle's sides as another comparison. For a right triangle, the areas on the two shorter sides sum to the area on the hypotenuse. Check which angle the displayed claim requires. A theorem about a specified triangle is more useful than a promise about every three-sided figure.

<!-- @triangleprofiles -->

Follow the pleats of the profile. Where one face meets another, a local relationship becomes part of a larger form. The unit you constructed can now take on a different role.

<!-- @folded_strip -->

Look along the folded strip and identify a seam whose angle changes the whole silhouette. A collection of triangles is more than a count; the way they meet determines what their surface can do.

<!-- @ -->

Before leaving, distinguish three things with an example: closing a boundary, filling it, and deciding which side is visible. Then explain why a different result from the L-shaped outline does not mean that your intended shape was wrong.

The next room brings faces together at a corner and asks what must still be added to enclose a volume.

### 006. Primitives Polythedra

[Live text](http://localhost:3003/compose?map=Primitives_Polythedra)

Volume does not begin here as a container. It begins as a question about a corner: what must be added before three meeting faces enclose anything?

<!-- @grab_trihedron -->

Pick up the open corner and turn it. Find the shared apex. Follow each edge away from it, then look across the opening opposite that apex. Count the visible triangles before looking for a base.

Three triangles meet at one vertex. The corner is not any one of those faces; it is a relation between them. Three flat things have stopped lying flat together.

The rendered object has no base face. Its script builds exactly these three faces from four vertices:

```gdscript
[0, 1, 2]
[0, 2, 3]
[0, 3, 1]
```

The missing fourth triangle matters. An open corner can suggest an inside without closing a boundary around a volume.

<!-- @grab_tetrahedron -->

Turn the tetrahedron beside it. Find the face that closes the corresponding opening. Count its vertices, edges and faces, touching or pointing to each once: four vertices, six edges, four faces.

Adding a base to the first corner would close a tetrahedral boundary. The neighbouring tetrahedron is a regular example of that closed family: four congruent equilateral triangles. The open wedge and the regular solid have different proportions, so compare their connections and closure before comparing their angles.

A surface encloses a region without having to fill that region with rendered material. What looks like a solid in a game is often a boundary mesh. What can collide with it is another decision.

<!-- @ -->

##### The opening that physics closes

Look again through the open corner. Predict what a small colliding object should do if brought through the missing base. What information would the physics system need to answer that question?

This artifact builds its collider as the **convex hull of all four vertices**. That hull includes the missing base. The visual opening and the collision enclosure therefore describe different boundaries.

The mismatch is useful only if we keep the two accounts distinct. A blocked physics object would establish something about the collider and its collision layers. It would not establish that an open geometric surface secretly has a base. Conversely, seeing through the opening does not establish a passage for every simulated body.

A possible extension is to place two visually identical corners with different colliders and let visitors choose which should admit an object. The question would become who gets to decide what counts as open, with the decision exposed in an interaction rather than hidden in an invisible wall.

<!-- @ -->

##### A corner with a handle

<!-- @pyramid_edit -->

Find the apex handle and the four base handles. Leave the base alone and raise the apex a little. Predict which side faces will change before lowering it again. Then move one base corner and compare the effect.

This is a five-vertex pyramid editor. Its four triangular sides meet at the apex, and its base is drawn with triangles too. Moving a handle rebuilds the faces that depend on it. The tool's default arrangement is a square-based pyramid; free handles can take it outside that initial shape.

A corner can be measured by adding the face angles that meet there. Compare their sum with a full turn:

```text
angular defect = 360 degrees - sum of incident face angles
```

At a cube corner, three right angles total 270 degrees, leaving a defect of 90. At a regular tetrahedron corner, three 60-degree angles leave 180. The faces meet in space with less than a full planar turn between them.

Keep the pyramid's base flat and move its apex toward that plane. The side faces change as the corner opens out. At a collapsed or crossing configuration, stop applying the language of an ordinary enclosed solid without checking it: the editor follows points, and does not certify every result as a valid pyramid.

<!-- @cube_scene -->

Count the cube's eight vertices, twelve edges and six square faces. Compare with the tetrahedron:

```text
tetrahedron: 4 - 6 + 4 = 2
cube:       8 - 12 + 6 = 2
```

This is the Euler characteristic, `V - E + F`. It is two for these closed surfaces with sphere topology. It is not two for every closed surface: a torus later in the chapter gives zero. Likewise, the total angular defect of a convex polyhedral surface is 720 degrees; that number is not a volume or a guarantee that anything counted as a “solid” has the same topology.

The faces are where you look. Their connections give you another account of what you are holding.

<!-- @ -->

##### The prism, twice

<!-- @prism_block -->

Follow the prism arrangement with your body. Approach a broad face, then look for the spaces between neighbouring pieces. Compare blocking a route with supporting one. Do the visible gaps and the available passage agree?

A triangular prism carries two triangular ends joined by three quadrilateral sides: six vertices, nine edges, five geometric faces. A renderer can split those quadrilaterals into triangles without changing the boundary's Euler characteristic. The face count has to say which decomposition it is counting.

The same general form can be stood as a barrier or laid as a slope. Orientation, collision and surrounding floor turn its geometry into a use. A slope does not carry a visitor merely because its cross-section is a triangle; the room must make that surface reachable and give it the right physical behavior.

Choose one gap in the arrangement that you would preserve if asked to make a more regular wall. What does that opening permit? A wall's success might mean keeping things out, letting someone through, or giving them a place to pause. The shape alone does not choose among those purposes.

<!-- @diamonds -->

The stacked diamonds make another use of a repeated solid. Follow how their orientations change up the stack. The pattern belongs to a relation repeated between objects, not to a property contained in one stone.

<!-- @rock_spawner -->

The rocks offer irregular boundaries to compare with the regular ones. Look at the spaces they leave between them. Those spaces arise from shape, arrangement and physics; they are not outside computation merely because they look irregular.

<!-- @rock_scanner -->

Follow the scanning plane through the pile and compare successive sections. A section keeps one cut through a three-dimensional arrangement. Different heights can produce different outlines from the same pile. Predict a change before the plane reaches it.

<!-- @ -->

Before leaving, point to a visual boundary, a collision boundary and a connection pattern. Explain what each can tell you that the others cannot. Then choose a use for one of the forms that does not follow automatically from its name.

The next room takes the eight-cornered example apart. A cube will be built from the relations you can now count, and then handed over to you to change.

### 007. Point Animatedcube

[Live text](http://localhost:3003/compose?map=Point_Animatedcube)

You have been inside boxes since the first room. What makes one of them a cube, and what remains when you move one corner until it no longer deserves that name?

<!-- @cube_lines -->

Begin with the outline. Pick one corner to follow and count the edges leaving it. Trace the outline around one face, then look through to the corresponding corners on the far side. Predict what would have to be added to close it.

<!-- @polyhedron_nets_cube -->

Watch the flat net fold. Choose one square and follow it all the way into the enclosure and back out as the loop repeats. Before the next fold, predict which squares will become neighbours.

Six squares, cut into a connected sheet, can hinge into the boundary of a cube. The net does not fill a volume with material; it shows how faces can meet around one. Cutting along other edges can produce other valid nets. The closed cube does not preserve the history of which cuts you chose.

<!-- @animatedcubebuilder -->

Watch the builder add its layers: vertices, edges, then triangles. If the assembly has already finished when you arrive, begin by counting those layers in the object that remains. The nearby folding net repeats its construction; this builder's first assembly starts automatically.

Once the vertex handles are available, choose one and move it slightly. Predict which edges will follow and which triangles will tilt. Leave the other corners in place. Compare with the unchanged builder nearby before making a larger deformation.

The initial cube has eight vertices, twelve edges and six square faces. Each square is drawn as two triangles, so the rendered surface uses twelve triangles. Counting the geometric squares gives `8 - 12 + 6 = 2`. Counting the triangulation introduces six face diagonals as additional edges and gives `8 - 18 + 12 = 2`.

The builder reads new handle positions against the same lists of connected vertices. That keeps its combinatorial pattern while you move the points. It does not keep every edge equal, every angle right or every pair of triangles coplanar.

If a formerly flat face acquires a crease, locate its diagonal. The seam was already part of the triangulation. Moving a corner made its consequence visible.

<!-- @ -->

##### What stays the same?

Choose a modest deformation and name one property that survived and one that did not. “It is still a cube” is a stronger statement than “the connection list is unchanged.” Try to say which you mean.

A sufficiently free deformation can make triangles collapse or cross. At that point a list with the old counts is not proof of a valid enclosure. The tool follows the vertices; a validator would have to ask additional questions about the resulting geometry.

The other builder can remain your reference. Use the changed one to make something whose purpose you choose: a bent shelter, an awkward opening, a form valued for the silhouette it casts. Give it a name based on that purpose, then separately state which geometric properties changed. Leaving the category of “cube” need not end the experiment.

<!-- @ -->

##### Given time

The folding net changed the angles between faces. The builder changed which pieces were visible. Your hand changed vertex positions. All three can look like a cube “moving”, although they act on different data.

A small animation can be written as a transition toward a target:

```gdscript
var tween := create_tween()
tween.tween_property(cube, "position", target_position, duration)
```

That example changes position. It does not describe every animation or rebuild a mesh. Specifying the property matters as much as specifying the duration.

You met interpolation from the other side in the trace room. There the renderer connected retained samples of a movement. Here a target and a timing rule can generate intermediate states. A convincing between still needs an account of how it was made.

<!-- @ -->

##### A world without composition yet

<!-- @crate -->

A crate makes the box familiar again: a thing to ship, stack, open or hide behind. Compare its edges with the builder's. A detailed crate can use many more triangles than a bare cube; its resemblance to a box is not an invoice for exactly twelve.

<!-- @wooden_pallet -->

Read the words on the cartons: **A WORLD / WITHOUT / COMPOSITION**.

<!-- @hangar_supply_pile -->

The supply pile adds **WITHOUT COMPOSITION / YET**. The *yet* makes a promise about what the curriculum will ask next.

These objects have already been arranged. Their words cannot erase that arrangement. What remains to learn is how to choose and examine it: what should be next to what, what deserves attention, and whose movement a collection invites. Knowing the parts does not settle those questions.

<!-- @station_crates -->

Look at the stack as an arrangement rather than as several examples of the same primitive. Which piece seems accessible, protected or forgotten? Those readings come from relations between bodies and a visitor.

<!-- @glove_box -->

The sealed chamber puts a glove between an imagined worker and the contents. Compare the permission it suggests with the exposed vertex handles. A box can frame an encounter with work as well as enclose a space.

<!-- @first_shadow -->

Compare the small triangle and line in the shadow display. Look for the shadow, then for the object that produces it. What a rendered mark can occlude depends on its geometry, material and light settings. A line drawn as a thin body is different from an ideal dimensionless line.

<!-- @first_phosphor -->

On the dark glass, a green dot. The point is here again, now encountered through an instrument and its glow. After learning a solid, you can still return to a single location and ask what was added to make it visible.

<!-- @ -->

Leave the room able to distinguish moving a whole object, deforming its vertices, folding its faces and revealing its layers. Predict one invariant before choosing an operation, then check it on the available example.

The next room puts the familiar names under pressure. When an engine offers a sphere, how much geometry has it spent to make that name seem obvious?

### 008. Primitives Ignorance

[Live text](http://localhost:3003/compose?map=Primitives_Ignorance)

You can recognise a cube and change one until it stops being a cube. What happens when the familiar name is “sphere”? How much must the machine build before you are willing to call something round?

<!-- @sphere_low -->
<!-- @sphere_mid -->
<!-- @sphere_high -->

Compare the three sphere approximations from one place. Choose the one whose silhouette looks smoothest, then move closer. Walk around the coarsest one. Count a few visible edges and look for a direction from which the difference becomes especially clear.

Keep the viewing distance part of the experiment. A distinction you can find with your face close to the surface may disappear from the doorway. Decide what you can actually see before checking the construction.

The three scripts spend their geometry differently. The current low sphere starts with one ring and ten radial segments; the middle uses seven of each; the high uses sixteen of each. These are not simply three steps of one integer being doubled. Rings and radial segments divide different directions of the surface.

A mathematical sphere consists of the points at a fixed distance from a centre. These mesh boundaries approximate it with finite geometry. Shading can make adjacent facets appear smooth without removing their edges from the underlying mesh.

The machine's sphere is a polyhedron that has agreed to be called round. That agreement can be useful, but it has conditions: the representation, the viewpoint, and what you need to do with it.

<!-- @sphere -->

Compare the ordinary sphere with the three explicit examples. Does a familiar name make you stop inspecting sooner? What would you ask before using it for a close view, a silhouette, or a collision surface?

<!-- @ -->

##### Read the invoice

<!-- @budget_of_smoothness -->

At the counter, compare the four segment settings: 4, 8, 16 and 64. Cover the price tags with your attention for a moment and choose the least elaborate example that would serve a distant background object. Then read the displayed triangle budgets.

Move closer and make the choice again, this time for something a visitor will hold beside their face. Does the same answer still serve?

The display constructs each sphere from its segment setting and a corresponding ring count, then calculates the number on its tag. The settings increase together, so the cost grows faster than the side count alone. The experience you gain need not grow at the same rate.

The last examples may look almost alike from some distances. Their invoices do not. That is a question to test with your own viewpoint, not an instruction to pretend the difference is invisible.

Resolution is part of the form you receive. A coarse sphere mesh is not, in general, a prism. A prism has two matching polygonal ends joined by side faces; the sphere's rings and poles construct a different boundary. Knowing both shapes lets you ask what the approximation actually made instead of forcing it into the nearest familiar name.

<!-- @ -->

##### The ideal set

<!-- @platonic_grabbables -->

Choose a tetrahedron and a cube from the held solids. Turn each until you have inspected more than one face and corner. What kind of sameness repeats within each object? Then compare with another member of the family.

The five convex regular polyhedra have congruent regular polygonal faces and the same arrangement at every vertex. They do not look identical from every possible viewpoint. Their regularity is a specified symmetry of the object, not a promise that the eye sees the same picture everywhere.

Why only five in this family? Regular face angles must fit around a convex vertex with a positive angular defect. Triangles permit three, four or five faces there; squares permit three; pentagons permit three. Six equilateral triangles or four squares already fill a flat turn. Those constraints lead to the tetrahedron, octahedron, icosahedron, cube and dodecahedron.

The list is finite because the question is restrictive. It does not list every useful solid, every beautiful object, or every possible way of making a world.

<!-- @grab_octahedron -->

Count six vertices, twelve edges and eight faces. Compare those numbers with the cube's eight, twelve and six. Vertices and faces exchange roles in their dual relationship. A different way of organising the same comparison reveals a relation the individual names conceal.

<!-- @truncatedtetrahedron -->

Look at what cutting the tetrahedron's corners adds. New faces appear where vertices used to be. A construction can leave the five-member regular family while remaining precise and usable. Exclusion from a catalogue is not exclusion from geometry.

<!-- @ -->

##### The one that refuses a half-turn

<!-- @capsule -->

Watch the five-sided capsule turn. Choose a visible ridge and predict what will face you after half a turn. Check that prediction against the object as it rotates.

With five radial segments, a half-turn around its long axis does not map the cross-section onto itself. An even-sided regular cross-section has a different answer. This is a specific symmetry question, not a claim that the object has become unequal to itself or impossible to know.

The interesting form is already in the standard kit, under the plain name “capsule”. You can value its facets rather than treat them only as a failure to be smooth.

<!-- @star_primitive -->

Compare the star's five-point pattern under the same imagined half-turn. A familiar outline can answer one symmetry test and fail another. Name the transformation before saying an object is symmetrical.

<!-- @roughrock -->

Look for a feature on the irregular rock that you would lose by replacing it with a regular solid. Choose a use for that feature: recognition, shelter, a grip, a distinctive silhouette. What resists your first abstraction may be exactly what another task needs to keep.

<!-- @righttriangle -->

The right triangle offers an invariant to compare: move or turn a rigid right triangle and the right angle remains. An invariant says which changes you are considering and which relation survives them. It is not a ranking of the objects that possess it.

<!-- @hole_with_cones -->

The cones mark a place that invites you to look for something absent. A marker can preserve an expectation even when the thing it names is no longer there. Read the marking, then check the place.

<!-- @ -->

Now choose a geometry budget as a design proposal. Spend it on the distinctions you want a visitor to encounter. You might keep a deliberately faceted silhouette and use the saved detail elsewhere, or spend more where a hand will inspect an edge. Explain whose viewpoint and purpose made your choice reasonable.

A model keeps by omitting, and the omitted does not vanish. It can become the next question.

The next room takes a finite sequence of round-looking objects and asks what “closer” means when every example still has a count.

### 009. Primitives Portals

[Live text](http://localhost:3003/compose?map=Primitives_Portals)

The last room compared what a finite budget makes visible. This one stretches that comparison into a walk. When each ring has more sides, what are you approaching, and what would count as arriving?

<!-- @combine_portals -->

Begin beside an early faceted ring. Follow a straight edge around its opening, then compare with a later ring along the route. Move far enough away that the facets become harder to distinguish. Turn back and read the progression in reverse.

Before looking for an explanation, choose one ring that seems sufficiently round for the view you have. Keep that choice in mind as you move closer.

The placed ladder constructs twenty torus meshes. Its first has three rings and three segments; each subsequent member adds one ring and two segments. At the twentieth, those counts are twenty-two and forty-one. The sequence is finite, and both subdivisions of the torus are changing.

The order makes a claim: that coarse-to-fine is a direction worth walking. Walking back does not change any mesh. It changes the story the same collection can tell. You can prefer the early facets for a different purpose without having misunderstood the later refinement.

<!-- @ -->

##### Closer is a relation

To study circularity precisely, simplify the torus's two surface directions to one planar circle. Place a regular polygon inside a circle of radius `r` and measure its perimeter:

```gdscript
func polygon_perimeter(n: int, r: float) -> float:
    var total := 0.0
    for i in range(n):
        var a := Vector2.RIGHT.rotated(TAU * i / n) * r
        var b := Vector2.RIGHT.rotated(TAU * (i + 1) / n) * r
        total += a.distance_to(b)
    return total
```

Each finite polygon joins points by straight chords. Its perimeter is shorter than the circle's `TAU * r`, and the gap approaches zero as the side count grows without bound. This is a mathematical comparison, not a live perimeter readout hidden in the portals.

No finite member becomes the circle merely by having many sides. Yet a finite approximation can meet a chosen tolerance. “Close enough from here” and “exactly the mathematical circle” answer different questions.

Return to the ring you chose. State a tolerance in terms of a use: readable as a circle at the entrance, visibly faceted at arm's length, an opening whose silhouette you enjoy. The purpose supplies a stopping rule that endless refinement does not supply on its own.

<!-- @ -->

##### Achilles, and the staging of a limit

<!-- @achilles_tortoise -->

Watch the two markers on the track. Before the next advance, point to where you expect Achilles to go. Follow the shrinking intervals toward the end marked *limit*. Stay long enough to see the demonstration pause and begin again.

The model sets Achilles' position after step `n` to:

```gdscript
var covered := track_length * (1.0 - 1.0 / pow(2.0, float(n)))
```

The tortoise is placed one halving step ahead. The initial gap and the successive remaining distances shrink under that rule. Each finite stage has a next one in the mathematical sequence.

The scene shows ten stages on a six-metre track, separated by two-second display intervals, then pauses and resets. Equal pauses make the stages readable. They do not model the durations of an infinitely subdivided journey.

An infinite sequence of decreasing intervals can have a finite sum. Dividing a distance endlessly does not prove that crossing it takes endless time. Conversely, an animation ending its ten-stage performance does not prove that its last marker is the exact limit.

A separate numerical experiment could ask when a chosen floating-point calculation rounds a remaining gap away. This placed animation does not run that experiment. A rounded value, a completed display cycle and a mathematical limit each need their own test.

<!-- @ -->

##### The hole survives the refinement

<!-- @capsule -->

Compare the capsule's closed outline with the rings. Find a view that makes the opening unmistakable. Increasing the side count changes the approximation; it does not remove the torus's central passage.

The tetrahedral and cubic surfaces gave an Euler characteristic of two. A torus surface gives zero. An idealised grid drawn around a torus with `m` divisions in one direction and `n` in the other has:

```text
vertices = mn
edges    = 2mn
faces    = mn
V - E + F = 0
```

Splitting each grid face into two triangles adds one edge and one face together, leaving the result unchanged. These counts concern identified surface vertices and faces; a rendering buffer may duplicate vertices for seams or shading.

The hole belongs to the topology of the surface, while the side count belongs to a particular tessellation. Both matter, but increasing one number does not change the other kind of fact.

Passing your body through an aperture additionally depends on its size, placement and collision. Euler characteristic alone does not make a ring a walkable doorway. Nor does a ring mesh teleport you: that would require another mechanism for moving and reorienting the visitor.

<!-- @ -->

Choose two ways to complete this room. One might be reaching a later ring whose facets you can no longer see from a chosen distance. Another might be returning to a coarse ring and making its corners the point of the encounter. Describe what each ending values and what each leaves unresolved.

The next room gathers tools, forms and tests that can give exact answers. It asks you to choose a purpose those answers cannot choose for you.

### 010. Primitives Melencolia

[Live text](http://localhost:3003/compose?map=Primitives_Melencolia)

Tools in hand, what would make the work complete?

You can name a point, make a connection, record a movement, close faces and count a boundary. You can also find places where a representation gives a correct answer to a smaller question than the one you hoped to ask. Use that distinction here.

<!-- @snap_pyramid_puzzle -->

Begin with the five-point puzzle. Before joining anything, choose four points for a base and one for an apex. Predict the connections a pyramid would need. Make the base cycle and connect its four corners to the apex, using the snap-and-release interaction you met in the line room. Compare the completion response with the shape you actually made.

A square pyramid has a square base and an apex outside the base plane. Its geometric boundary has five vertices, eight edges and five faces: one square and four triangles. Those are claims about a shape.

This puzzle's connection manager asks a narrower question. It searches for four connected points in a cycle and a fifth connected to all four. That test does not measure base angles, equal side lengths, planarity or apex height. The signal named `square_pyramid_formed` establishes that the connection pattern was found. The name is stronger than the test.

Watch the completion response: the points lock and the puzzle is later hidden. That response recognises a connection pattern. The raised pyramid court and the separate Dürer platform are already parts of the room before you solve anything. Compare what the detector recognises with what those built surfaces let a body do. Recognition and usefulness are different things to investigate.

Now propose a variation. Keep the connections while making the base rhombic instead of square. Predict what the detector would still recognise and what the geometric definition would no longer permit. A configured rhombic version can make that comparison repeatable; a claim about whether a particular hand-made example succeeds still needs the actual test.

You do not have to choose between pretending the shape is square and discarding what you made. You can keep its geometry explicit and choose a broader category or another purpose. Who gets to decide whether that is a failed square pyramid or the beginning of something else?

<!-- @ -->

##### Four corners and a centre

<!-- @pyramid -->

Approach the raised square court. Four equal pyramids mark its corners. Use the ramp beside the court to look from their level, then compare that view with the one from the surrounding floor. Choose two corners and predict which counts agree before comparing them.

Five vertices, eight edges, five faces. Repeating the same shape gives the court a boundary you can read from several sides. The four pyramids keep their dimensions while your position changes. A corner is a role in an arrangement as well as a place on an object.

<!-- @pyramidlong -->

Compare those corners with the long pyramid in the centre. What changes when one form becomes taller while the others repeat around it? A count can remain unchanged while proportions change, just as the cube builder could keep connections while moving vertices.

<!-- @cube_scene -->

Four small cubes surround the central pyramid in a cross. Look along that cross, then across the diagonals toward the corner pyramids. The same few forms make different relationships available from different positions. Choose which arrangement you would preserve if you gave this court another purpose.

<!-- @prism_block -->

The triangular prism gives another comparison: six vertices, nine edges and five faces. Decide whether your purpose needs a sloping face, a particular height, a passage or simply a form you want to look at. The number two from `V - E + F` cannot decide among those purposes.

<!-- @ -->

##### Look at the tools

<!-- @durer_scene -->

Follow the raised connection and its next ramp to the separate, higher platform carrying the tableau after Dürer's *Melencolia I*. You can also circle it from the surrounding floor. Find one object that recalls an earlier room: the compass, the polyhedron, the sphere, the numbered square. Choose the relation it recalls and explain it to yourself or a companion before reading on.

The compass can recall two positions and a distance. The numbered square can recall a grid with something assigned to every cell. The polyhedron can recall a surface constructed from faces. These are readings invited by this museum's arrangement, not proof of what every object in the engraving was intended to mean.

The solid here is a constructed interpretation of Dürer's polyhedron. Its irregular proportions and cut faces are worth inspecting on their own. A recognisable historical reference does not make every detail of a reconstruction geometrically or historically exact.

One way to read the scene is as mastery interrupted: the tools are present, and the next purpose remains undecided. Another is as attention, fatigue, refusal or desire. Geometry can help us describe the objects without settling the figure's motive. Let the interpretation stay available for disagreement.

##### Every row is 34

Choose a row of the displayed square and add its entries. Try a column, then a diagonal. Make a prediction about a second row before counting it.

```text
16   3   2  13
 5  10  11   8
 9   6   7  12
 4  15  14   1
```

Each row and column, and the two main diagonals, sums to 34. The square uses the numbers one through sixteen once each. The highlighted 15 and 14 recall the engraving's date, 1514.

Now choose another group of four entries. Must it also sum to 34? Find one that does not. The rule names particular relations; it never claimed that every possible selection would behave alike.

An exact arrangement can be wanted for itself. It need not earn its place by becoming a measuring tool or a platform. Wanting to contemplate, decorate, play or leave something unresolved is also a possible purpose, and the sum does not rank those purposes for you.

<!-- @ -->

##### Frame, image, passage

<!-- @bigframe -->

Move until the large frame gathers part of the tableau into a picture, then step aside. What relation becomes easier to see from the framed view, and what disappears outside it? Look for the passage the physical opening offers as well as the picture it composes.

A frame selects. Its boundary can support attention without becoming the boundary of what exists. The same step that improves one view can conceal another.

<!-- @code_display -->

At the code display, choose one statement and connect it to something you have actually done in the chapter. Name the conditions under which that statement helps. Then name a question it does not answer.

An axiom, a function and an instruction each establish a different kind of starting point. Making a system legible includes making those differences legible. A screen of confident statements is an invitation to investigate their scope, not a guarantee that every visitor's question has already been settled.

<!-- @diamondtoruscollection -->

Above, the torus and diamonds make the chapter's vocabulary ornamental. Notice the pleasure or indifference that arrangement produces. Composition has begun even if the choice of what to make remains open.

The torus contributes a different topology from the closed sphere-like boundaries. An assembly of separate objects is not one solid whose count can be obtained by repeating “two”. Counting begins by deciding what is connected to what and which surface is under discussion.

<!-- @ -->

##### Build anyway

Return to one thing you made or inspected. State three judgments separately: what the geometric description says, what the software checked, and what would make it useful or meaningful to you.

Then choose a next action. You might alter the construction, keep it and change its task, arrange it beside another object, or decline the demand to improve it. Give the choice a reason someone else can understand without requiring them to share it.

Master the tools. Recognise their limits. Build anyway. Or keep looking long enough to discover that building was not yet your question.

The transformation sequence begins from something you can now distinguish: moving, turning and scaling preserve some relations while changing others. Bring one prediction about what will stay the same, and one purpose for which that invariant matters.

## Transformation: What Stays the Same When Everything Changes

### 011. Trans Pre

[Live text](http://localhost:3003/compose?map=Trans_Pre)

This chapter begins with three kinds of difference between a thing and its copy: translation, rotation and scale.

It comes first because everything after it uses these three differences to get you somewhere. Here nothing moves and nothing is crossed - but the room does climb, in three levels, and the climb is part of the argument: the deck where the cube stands alone, a shelf a metre up, a summit two metres up. One yellow block stands alone, and then the same block stands twice, four times over, and each time the copy differs from the original in one way only. You walk the difference. That is the lesson, and it is the whole of it.

```gdscript
func difference(a: Transform3D, b: Transform3D) -> Transform3D:
    return a.affine_inverse() * b
```

Take the copy's transform and divide out the original's, and what is left is the transformation: a translation if only the origin differs, a rotation if only the basis has turned, a scale if only the basis has stretched. The room lays the answer out in space so you can read it without the division.

##### One cube, then the difference

<!-- @mario_cube -->

A yellow block with an orange wire, half a metre on a side, alone on the deck behind a two-metre wall that closes off the rest of the room. That is the cube. It is the unit the whole museum is built from, and in this room it is also the thing being copied. Walk into it and a rainbow of seven bands stands up over it; every block in the room does that once, and the first one you reach does it first.

Two blocks, four cells apart on the same row - and the second stands a metre up, on a plinth you reach by the ramp between them. Nothing about it is different from the first except where it is. Down here that difference is a vector with a metre of height in it, and the ramp is the part of it you walk. That difference is translation, and it is the only one of the three you could describe without looking at the block at all: a vector, four along x and one up.

Two blocks again, and the second is turned forty-five degrees about the upright. It stands in the same place and it is the same size, and its corners point where the first block's faces do. That difference is rotation, and its change of facing needs a shape to make it visible: a dimensionless point has no facing of its own to compare.

Two blocks, and the second is one and a half times the size. Same place, same facing, more of it. That difference is scale, and it is the one you cannot see from inside: were you scaled with it, nothing would have happened.

The last pair does all three at once. The copy is moved along the row and lifted a metre, turned forty-five degrees, and grown by half. One block, one copy, three differences, and the point of the chapter in a single object: those three are added one at a time to read, and applied all at once to do. The next hall gives each of them a hole to cross.

<!-- @clipboard -->

A card on the landing as the room comes back down. Walk within a metre and a half and its page fades up: the axioms of transformation, which say what the room just showed you in the language of a four-by-four matrix. Sixteen numbers, and every move a thing can make.

<!-- @ -->

##### Before the holes

Every later room in this chapter is a floor with holes in it, and every hole is the trace of one of these three differences, used as a way through. This room is the differences at rest. Learn to see them here, between a block and its copy, and you will see them in the floor.

Next: three cubes, three pits, and the same three differences put to work.

##### And then the same three, in time

<!-- @pick_up_cube -->

A wall closes the climb, with one door in it. Everything behind you needed two
cubes, a thing and its copy, differing in one way. Everything ahead needs one,
because the copy is the same cube a moment later.

Three cubes stand in single file down the middle of a flat hall, one to a row,
and each does exactly one thing. The first only rises and falls. The second only
turns. The third only grows and shrinks. You walk past them one at a time and
you cannot see two at once, which is the difference between the two halves of
this room: a difference in space you compare by looking, a difference in time
you compare by remembering.

```gdscript
rotate_y(rotation_speed * delta)
global_position.y = original_y + sin(time_passed * bob_speed) * bob_height
```

Then the room goes back to pairs. On the left a cube doing all three at once. On
the right a plain pick-up cube, the object this museum has handed you a hundred
times, and the two lines above are its whole idle animation: a rotation and a
translation, composed, forever. It has always been two of the three. The third
it performs exactly once, when you walk into it and it swells and is gone.

A transformation applied once is a difference. Applied every frame, it is a
motion. There is nothing else in it.

### 012. Trans Introduction

[Live text](http://localhost:3003/compose?map=Trans_Introduction)

A transformation is defined by what it refuses to change.

The previous room compared transformed copies, then repeated the changes over time. This hall puts three of those operations to work across gaps: a thing can go somewhere else, it can turn, or it can grow. The chapter's whole question is asked in the first hall and answered in the last: when everything changes, what stays the same? Each of the three moves has a different answer, and each is named for the one thing it gives up.

##### Three ways to close a gap

One lane runs the length of this hall and three pits are cut into it, and there is a different cube at each one. The cyan cube carries you across by going somewhere else: your position changes and nothing else does. The orange cube is a slab that turns a quarter circle about the upright, holds for four seconds and turns back. It does not tilt and it does not grow; the gap is bridged by facing differently. The green cube swells until there is no gap left to cross, holds while you walk over it, and shrinks away again. Same pit, three answers, and you will walk all three before the chapter is out.

```gdscript
func srt(position: Vector3, rotation_rad: Vector3, scale_factors: Vector3) -> Transform3D:
    var t := Transform3D.IDENTITY
    t = t.scaled(scale_factors)
    t = t.rotated(Vector3.UP, rotation_rad.y)
    t = t.rotated(Vector3.RIGHT, rotation_rad.x)
    t = t.rotated(Vector3.FORWARD, rotation_rad.z)
    t.origin = position
    return t
```

Scale, then rotate, then translate. The order is not a convention. Do it in another order and the same three numbers land the same point somewhere else, and the machine can show you exactly where.

##### What each refuses

<!-- @invariants_demo -->

A triangle with its measurements written on it: side lengths, angles, area. Press a button and watch which numbers survive. The ones that survive glow green, the ones that change glow red. Slide it and every number stays green. Turn it and every number stays green. Grow it and the angles stay green while the sides and the area go red. Shear it and all three angles go red, two of the sides go with them, and the base and the area hold. Each transformation has a signature, and the signature is what it cannot touch.

<!-- @x_translation_cube -->

Three cubes stand apart in this hall, each allowed one axis. This one slides sideways, on a rail, with four fading ghosts behind it and its one coordinate counting on a label.

<!-- @y_translation_cube -->

This one lifts. The same operation, and the one that reads least like it.

<!-- @z_translation_cube -->

This one goes into the depth, where the same displacement reads almost entirely as getting bigger. Translation, taken apart, is three of these, and the room after next will forbid you two of them at a time to prove it.

<!-- @ -->

##### Order

<!-- @spin -->

A row of copies that slides, then turns, then slides again. The turn is inserted in the middle of the process, and it changes the copies without changing where they go. The row stays straight, because every phase adds the same step along the same axis and only the basis is turned. Twelve copies tumble fifteen degrees each, and the last ten stand upside down and still in line.

<!-- @transform_composition -->

The same house twice: rotated then moved, in blue, and moved then rotated, in red. It lands in two different places, and the two matrices beside it are written out so you can see that the product is different when the factors change sides. Order matters here in a way it never did for adding.

<!-- @rotation_gimbal -->

Three rings, one inside the other, one per axis, driven by a pad of three sliders. Push the Y slider toward ninety degrees and the outer and inner rings come into line, and at that moment one of your three freedoms is gone: gimbal lock. It is the reason a rotation is better kept as a single turn about a single axis than as three angles, and the rest of the chapter keeps it that way.

<!-- @ -->

##### One matrix

<!-- @homogeneous_coordinates -->

Why four by four for a three-dimensional world. The panel is colour-coded: the block of nine carries rotation and scale, the last column carries translation, and the bottom row is three zeros and a one. That extra row is the trick. It lets a move that is really an addition ride along with the moves that are multiplications, so that all three become one multiplication, and a chain of them is a chain of products.

<!-- @matrix_4x4_viewer -->

The same matrix, live. Sliders for the three translations, one rotation and a uniform scale, and a wireframe cube that obeys them while the sixteen numbers update in front of you. This is where the abstraction and the object are the same thing at the same time.

<!-- @ -->

##### Moves with something at stake

<!-- @balance_puzzle -->

Eight pieces, and a line at forty centimetres. Stack them past it and hold every piece still for a second and a half, and the pile stops being a pile: the eight blocks gather and walk away as a creature. Every drop is a translation and a small rotation, and the test is not the moves. The test is whether the stack is still standing when you take your hands off it.

<!-- @scale_me -->

A sphere you can take hold of. Do, and the dark sphere across the hall swells ten times over two seconds. You are not carried with it. In the instant you close your hand, before anything has started to grow, your distance from the room's corner is doubled and your height set to five metres, so you arrive at the new view before the sphere does. It does not come back while you are here, and neither do you. Alice had a bottle for this.

<!-- @pick_up_cube -->

A black cube in orange wireframe, turning and bobbing on its own axis. You cannot carry it. Walk into it and it is gone with a rising chirp and one point on the score, so the translation the room counts here is yours and not the cube's.

<!-- @head_crab -->

A small black crab on four jointed legs, which finds you at fourteen metres and comes. Inside two metres it dashes. The bite takes a third of your health and puts you back at the door, so the one thing in this hall that moves itself is also the only one that can undo your walk.

<!-- @dark_sphere -->

This is the sphere the grab handle goes looking for. It turns slowly and its purple emission breathes, and otherwise it is only ever acted upon, which is what makes a tenfold change in it legible.

<!-- @ -->

##### What stays the same

Here is the question in one sentence: what stays the same when everything changes? Translation keeps everything but position. Rotation keeps everything but direction. Scale keeps the angles and the proportions and gives up the sizes. Shear keeps the area and the side it stands on, and gives up the rest; it is the fourth button on the first panel in the hall, and the chapter does not give it a lane, which is a choice the panel quietly argues with. A transformation is a promise about what will not be touched, and the chapter is a walk through three promises and one that did not get a door.

The next hall is translation on its own, and its floor has holes in it.

### 013. Trans Translation

[Live text](http://localhost:3003/compose?map=Trans_Translation)

Translation changes nothing about a thing except where it is. That is why a void can be crossed by it, and why a path can be kept as nothing but a list of positions.

This hall has holes in its floor, and every one of them is the trace of a translation. Three slots run away from you, each exactly as wide and as long as the cube that travels it, and the cube is the only way across: the first carries you straight, the second turns you a quarter on the way, the third grows the space around you by a third and gives it back on the return. One slot runs sideways. Three holes stand in the front of a raised floor with a lift in each, and you enter them by dropping in and leave them on top. One slot runs down through that floor, a cube sliding forward and down at once. The whole room is displacement made into infrastructure, and the emptiness is the drawing of it. Nothing here is reshaped by being moved, which is not the same as nothing turning: the cubes you collect spin on the spot, and two of the rides turn you with them.

```gdscript
func move_to(node: Node3D, target: Vector3) -> void:
    node.global_position = target
```

One assignment, and the object is elsewhere. Everything it was, it still is.

##### Over the void

<!-- @player_trace -->

Before crossing a slot, walk a short stretch of solid floor, return, and repeat it faster. The trace can follow the same route while changing colour: toward green for a slower passage, toward amber for a faster one. Compare the route you took with the pace the recorder has retained. Translation between two endpoints names a displacement; this recorder also keeps something about the journey between them.

Stop for a moment. The pause adds no new position. The next speed value averages the movement over the elapsed interval since the previous accepted position, including the pause; it is not an instantaneous reading of your next step. The recorder keeps positions, times and speeds together, admits a new position only after at least a centimetre of movement, and holds at most 1,024 positions. When that store fills, its oldest positions leave. The visible line is a bounded account of selected movement, not the whole time you spent here.

Try two walks with the same endpoints and different hesitations. Decide what difference you would want their records to preserve. A route, a duration and a speed pattern answer different questions; choosing one does not make the others unimportant.

<!-- @z_translation_cube -->

A cube on a rail that runs away from you, sliding forty centimetres out and forty back, with four ghosts of itself shrinking behind it. Watch what your eye does. Depth is the one direction in which a pure displacement is read as a change of size, and nothing about the cube has changed at all.

<!-- @y_translation_cube -->

This one lifts, on its own rail, with its own ghosts. Those are the two directions this hall mostly uses to get you across: the transport cubes go forward, and they go up. Once, in the middle of the hall, one goes sideways, and once one goes forward and down at the same time.

<!-- @pick_up_cube -->

Seven cubes, each turning on its own axis and bobbing: six standing on the ground, one of those up on the raised floor, and one hanging over the hole near the entrance. You cannot pick one up. Walk into it and it is gone with a rising chirp, and the score is one larger. The only thing translated here is you: the cube never moves at all, and the count is what your crossing leaves behind.

<!-- @pickup_gate -->

The gate at the end counts. It wants seven on the score you have been carrying since the first hall, and for the first time the hall holds seven of its own, the last of them up on the raised floor. The cube beside the gate displays the number, and the gate is closed until the count gets there and open the moment it does. Nothing about the gate is clever, and that is the point: enough crossings changed a number, and the number changed a wall.

<!-- @synthesis_stand -->

The cube you have been walking into has a family: wire, steel, clay, crate and foam, five stocks of the same object. The measurements ruled the family a series, so there is no hero to pin. Told to show one anyway, the plinth takes the far end of the measured ladder and stands it up: foam. The plaque says pick_up_cube stock=foam and nothing else, because a series verdict carries no single number to print. Every cube in the room is the near end, wire, the shipped form nobody chose.

<!-- @science_screen -->

The screen is set to track a point, and there is no point in this hall for it to track. It wants a neighbour with the word point in its name and a body it can hold, finds none, and draws the instrument anyway: POINT POSITION, P = (x, y), a grid, and a dot pinned at the origin reading plus zero with a trail of nothing. Along the bottom it recites this map's own blurb. A diagram of translation with the translation left out is the most honest object in the room.

<!-- @transform_composition_workbench -->

A workbench with a slider that picks one of four pairs of moves. The same tetrahedron is shown three times: pale and untransformed in the middle, then done in one order on the left and the other on the right, with an arrow from the ghost to each result. Three of the four pairs land in different places, and a badge over the stage says so. None of the four is the pair this hall is about. Two translations always commute, whatever their directions and however many, which is why nothing you do in this room has an order: take the cubes in any sequence and you reach the gate with the same count. Translation is the operation that does not care, and the rotation halls are where that stops being true.

<!-- @dark_sphere -->

A dark sphere that never leaves its cell while you cross. It is not still: it turns slowly, it wobbles, and its glow breathes between dim and dimmer. It is the room's control, and a strict one, because the only thing it refuses to do is the one thing everything else here does.

<!-- @mario_cube -->

Eight yellow cubes, one at the far end of every hole: past the three slots, at the landing of the sideways slot, on top of the raised floor where each lift arrives, and at the foot of the slot that comes down. They are the places you were meant to reach, and they know when you have. Walk into one and a rainbow of seven bands stands up three metres over it. The first one you reach does something more: the dark sphere shrinks to nothing in little more than a second and is gone. The room's control is the price of the first crossing, and darkness becomes colour at the moment a hole has been crossed. The others keep their rainbows, and the sphere does not come back.

<!-- @ -->

##### Here becomes there

The gaps in this floor are not obstacles. They are invitations, because translation is the operation that does not care what lies between two positions, and every gap here is the exact size of the move that crosses it: the hole is the drawing of the translation, and the translation is the only way through the drawing. And the transport cube does cross the void, slowly. Stand on it, wait a second, and it moves at two metres a second toward the far side, and on every frame it adds the distance it just moved to your position as well as to its own. You are not transported. You are added to, frame by frame, by a cube doing to you exactly what the first line of code did to the object.

That is translation's promise, and it is the only transformation in the chapter whose promise covers you.

The next hall takes the same operation apart into three, in a room that forbids you two of them at a time.

### 014. Trans AxisDecomposition

[Live text](http://localhost:3003/compose?map=Trans_AxisDecomposition)

Every displacement is three independent displacements, one per axis, and you only feel that when the room forbids you two of them.

More than a third of this hall's floor is missing, and every missing cell is where a cube goes. What floor there is comes in islands, and the way between them is five transport cubes, each of which moves on one line only: one runs the length of the hall to the island, one runs back the other way, one runs across to the west, one runs diagonally into the last room, and one stands in a hole in a raised floor and lifts. Four of them wait until you are standing on them. The lift does not, so you have to arrive when it does. You arrive high on the east ledge, and the gate and the way out are both two steps from where you land. Everything the hall has to teach is west of them, across the missing floor, and nothing makes you go. Cross anyway, and you find that wanting to be somewhere means wanting three directions in turn, because no cube gives you two at once, until the diagonal does, and the slot it cuts is the sum of the two it replaces.

```gdscript
func components_on_axes(v: Vector3) -> Array:
    return [v.x, v.y, v.z]

func reconstruct(cx: float, cy: float, cz: float) -> Vector3:
    return Vector3.RIGHT * cx + Vector3.UP * cy + Vector3.FORWARD * cz
```

Take a displacement apart into three numbers, and put it back together from three arrows laid tip to tail. The three are all there is, with one catch the machine will show you if you try it: forward in this engine is minus z, so the third arrow comes back pointing the other way unless you say which way forward is. Decomposition is exact. Reconstruction has to agree about the axes.

##### One axis at a time

<!-- @translation_cube_demo -->

Two doors in a wireframe box, one red and one blue, each of which will only move along the axis the box currently allows. Push one sideways when it wants to go up and it resists. Complete the lift, and the slide is permitted, and then you do the whole of it again with the other. The constraint is the lesson: direction is part of the operation, not a detail added afterwards. The order belongs to the door and not to the arithmetic. The two displacements add to the same place either way, so the door has to impose a sequence to make you feel them apart.

<!-- @x_translation_cube -->

<!-- @z_translation_cube -->

The sideways cube and the depth cube, each on its own rail, each trailing four shrinking ghosts of where it just was, each printing its one coordinate to three decimals as it goes. There is a speed slider on the rack in front of them. Slow the cube down until you can read the number changing, and watch the other two digits not change at all.

<!-- @cube_scene -->

One cube, a metre on a side, hanging three metres above the widest gap in the floor. It is the chapter's plain solid, the thing everything else is measured against, and here it is out of reach, marking the crossing rather than making it.

<!-- @toruscylinder -->

Beside the maze, two motions that are not the same family. A torus turns, and a cylinder rises and falls and leaves a trail. The turning never changes where the torus is. The rising never changes which way the cylinder faces. Put side by side, the two show what this chapter keeps separate: a rotation and a translation can happen in the same place at the same time and share nothing.

<!-- @pick_up_cube -->

Six cubes, turning and bobbing: one in the north room, one up on the raised floor, four on the south floor. You do not carry them. Walk into one and it is gone with a rising chirp, and the number the gate is watching goes up by one.

<!-- @pickup_gate -->

The gate wants six on the running score. The last hall would not let you leave until you had seven, so this one is open before you reach it: the same rule, already satisfied, standing there so you can watch a condition follow you between rooms. The six cubes in this hall are the count it would have asked for on its own.

<!-- @dark_sphere -->

A dark sphere on the floor of the northern island, turning slowly on itself and breathing light. It turns and it never changes where it is, which is what makes it the thing to read every other motion against.

<!-- @mario_cube -->

Four yellow cubes, at the four places the crossings lead: the north room, the west landing, the south room, and the top of the raised floor. Walk into one and a rainbow of seven bands stands up three metres over it. The first one you reach does something more: the dark sphere shrinks to nothing in little more than a second and is gone. The thing you were reading every motion against is the first casualty of arriving.

<!-- @ -->

##### The skeleton of displacement

The coordinate system is not a description of space laid on afterwards. It is the skeleton of every move. When the room gives you a cube that goes only up, you learn that up was already a separate thing inside every step you have ever taken, and that a walk is a sum of three sums. The crossing is slow because it makes you do the arithmetic with your body, one term at a time. It is passable because the arithmetic is exact. The one cube that runs diagonally is not an exception to that. It is the proof: two of the terms changing at once, and a slot in the floor that is exactly their sum.

Next: the transformation that makes direction matter.

### 015. Trans Rotation

[Live text](http://localhost:3003/compose?map=Trans_Rotation)

Rotation is the first operation where the order you do things in changes where you end up.

Translation left direction alone: space was the same in every direction and a move was a move. Rotation makes facing matter. Front is now different from back, left from right, and the sentence on the wall says it: rotation produces space as anisotropic. Every turning form in this hall carves an orientation into the void, and declares this way and not that way.

```gdscript
func euler_rotate(node: Node3D, euler: Vector3) -> void:
    node.rotate(Vector3.UP, euler.y)
    node.rotate(Vector3.RIGHT, euler.x)
    node.rotate(Vector3.FORWARD, euler.z)
```

Three turns about three axes, and the order is in the body, not the name: up first, then right, then forward. Turn about up and then about right, or about right and then about up, and the same two angles leave the thing facing two different ways. Adding never did this. Rotation in three dimensions does, and it is the first thing in the chapter that cannot be undone by doing the same steps backwards in the same order.

##### Direction

<!-- @rotate_grid_cubes -->

Look down. The field of cubes in rows is the floor of this hall. It has no geometry of its own. It reaches into the grid the room is built from and turns that. The rows turn to a score. Six tip about one axis, four stay flat, six about the next axis, four flat, six about the third, four flat, and then six that tip about all three at once, thirty-five degrees on two of the axes and twenty-five on the third. The score runs forty-four rows and the hall is forty long, so you meet it once and walk off the end of it before it can come round. The collision cubes turn with the picture, so a tilted band is tilted underfoot.

<!-- @science_screen -->

The screen is not looking at the room. It is running as a waveform instrument, and what it draws is a sine rolling across an axis grid with an angle read out beside it. That is a rotation seen sideways: take a point going round a circle, keep one of its two numbers and plot it against time, and this is the curve you get. The diagram is a loss on purpose, and the number it threw away is the one that tells you where the point is.

<!-- @furniture_turntable -->

A record deck, playing a crate at thirty-three and a third. Watch the needle. It never moves, and the platter turns under it, and the point where they meet holds one radius forever, tracing the circle that was hidden in the motion. Thirty-three homecomings a minute. This is the second thing rotation makes, after direction: it makes a form come back to itself.

<!-- @spin -->

Thirty-three small cubes in a straight line against a red bar, alternating black and white. The first eleven all lean the same way. Through the middle twelve each copy is turned fifteen degrees further than the last, a hundred and eighty in all, and the ten that follow keep the new lean. The row never bends. Every step is the same step; only the orientation it is carrying has changed, and that is what the order cost. Placed twice on their plinths, one of them yawed half round, and the difference is the claim: the turn inside the sequence changes what each copy is doing, and the turn applied to the finished row only changes which way the row is pointing. Same angle, two places to put it, two different objects.

<!-- @dark_sphere -->

A dark sphere with no front. It is turning the whole time you stand there, slowly, and nothing about it changes, which is why it is the reference: it is the one thing in the hall a rotation cannot get hold of.

<!-- @ -->

##### The hole is the way

The floor of this hall is cut across three times, and each cut is the shape of a turn. The first is a row of three square holes, each the width of a plank turning about its centre: one turns a quarter and pauses, one a half, one forty-five degrees, and you cross when the corners meet the banks. There is no other way over. The second is three holes with the floor left round them, where cubes turn without stopping: a turntable you can cross while it turns under you, and two cubes rolling about the axes you walk along and across, which are no way at all. The third is three slots the width of a turning cube, crossed only carried: a quarter, the other way, half round. Past them a raised floor with a hole in its front, and in the hole a lift that turns you once around on the way up, the screw; and a slot down through its back, where a cube slides forward and down and turns you half round as it goes. Every empty cell here is the sweep of one rotation, and the rotation is the only way through it.

<!-- @mario_cube -->

Eight yellow cubes, one at the far side of every crossing. Walk into one and a rainbow of seven bands stands up three metres over it. The first one you reach does something more: the dark sphere shrinks to nothing in little more than a second and is gone. The thing with no front is the price of the first crossing.

<!-- @ -->

##### Sameness of form

Turn a square a quarter of a turn and it is the same square, corner for corner. Turn it an eighth and it is not. The turns that change nothing are a form's symmetry, and they are the part of rotation this chapter cares about most: not where a thing ends up, but which turns bring it home. A circle comes home under every turn, which is why the needle can hold one radius forever. A square comes home under four. And this is not only a fact about shapes. When physics asks what a particle is, one of the answers is how many turns it takes to come home, and there are particles that need two. How many turns a thing needs is a number physics gives to every particle, and it calls that number spin. It is sameness of form, taken as far as it goes.

##### What a turn does to a body

<!-- @catalyst_prompter_box -->

A floor hatch, one cell wide, whose lid slides open as you approach. A crystal rises from the recess. Walk away without taking it and the lid slides shut again. Take it and it is yours for forty-five seconds; let the lease run out and the floor takes it back, and the vent goes quiet with it.

<!-- @catalyst_vent -->

Turn round. Back up the hall a grey pillar four metres tall has been standing there all along, ringed on the floor at its foot with a dark orb sitting in it, and now that the crystal is in your hand it starts to breathe out bodies: five seconds, then one every two and a half, three of them, and then it goes quiet. They come as foes. The crystal does not damage them. Each hit walks one body a single step along an arc, foe to wary to neutral to curious to friend, so a friend costs four. That is the chapter's argument done to something living: a transformation is contact, not harm, and it does not finish in one go. Folded is not less.

<!-- @pick_up_cube -->

<!-- @pickup_gate -->

Seven cubes and a gate that wants seven on the running score, as before: two past the plank holes, two past the carried turns, one up on the raised floor, one at the foot of the slot down, and the last beside the gate. You do not carry them. You walk into one and it is gone with a chirp, one point richer, and the gate reads the total. The rule has not changed since the first hall, and here it is the calm part of the room.

<!-- @ -->

##### Process and outcome

In the translation halls a move was reducible to its result: here, then there, and the between did not matter. Rotation ends that. Two turns in one order and two turns in the other are the same two turns and two different outcomes, so the process is now part of the thing. From this hall on, how you got somewhere is a fact about where you are.

Next: the same turn, repeated, until it becomes architecture.

### 016. Trans RotationSpectacle

[Live text](http://localhost:3003/compose?map=Trans_RotationSpectacle)

One angular rule, repeated, is a building if you repeat it in space and a spectacle if you repeat it in time.

The last hall taught that order matters. This one teaches that a speed compounds. It is a long hall, a procession, with a corridor along one wall and a carousel at the far end, and everything in it is one rule applied again and again until the rule has become architecture.

```gdscript
func tunnel_angle(i: int) -> float:
    return i * rotation_per_segment        # ten degrees, added

func layer_speed(i: int) -> float:
    return base_rotation_speed * pow(1.2, i)   # a fifth, multiplied
```

Two rules and one counter. The corridor adds ten degrees for every segment you pass; the cake multiplies its speed by a fifth for every layer you look up. That is the whole machinery of this hall: an index, and something that reads it.

##### What you can trust

<!-- @righttriangle -->

A right triangle, on its own by the entrance, with no moving part anywhere in it. Move it, turn it, and the ninety degrees between its two short sides is still ninety. It is here as a diagnostic: with everything in this hall turning, you need one thing whose angle you can trust.

<!-- @dark_sphere -->

The dark sphere, which is not still either. It turns once in about forty seconds, slowly enough that you have to look away and back to catch it doing anything. In this hall even the witness is spinning, and the only thing that is not is the triangle.

<!-- @ -->

##### The rule, accrued

<!-- @boolean_tunnel -->

Along the east wall, a corridor of eighteen hollowed cubes set end to end, each three metres deep, each rolled ten degrees further about the corridor's own axis than the one before. Ten degrees is nothing. Seventeen of them is a hundred and seventy, and the corridor spends fifty-one metres rolling that far about the line you walk along. The ground stays flat. Everything round it does not. Nobody designed the twist: a local rule about one segment and its neighbour was repeated, and the repetition became a building.

<!-- @baggage_grammar -->

A baggage carousel, and one suitcase going round it forever. On the straights it translates. At the corners it rotates. Through the customs arch it is scaled down, and on the far side it is restored, nothing to declare. Twelve seconds a lap. All three rigid motions, one after another, on one object, in a loop: the grammar of the chapter, spoken by a suitcase.

<!-- @ -->

##### The hole is the way

Between the suitcase and the cakes the floor is cut five times, and each cut is the shape of one turn. Three square holes with planks in them: a quarter turn about the vertical, a quarter about the axis you walk along, so that it tips, and a half turn. Three holes with the floor left round them, where cubes turn without pausing: a turntable at forty degrees a second, and two rolling about the two floor axes. Three slots the width of a turning cube, crossed carried: a quarter, the other way, a full circle. Two more slots, one crossed turned half round while the space grows a fifth around you, one with the space growing by a third and nothing turning. Then a staircase of single holes cut on the diagonal, a lift beside the wall that takes you up two metres and once around and back, the square of empty floor a cube needs to grow into, and a last cut of three ways: a turntable at ten degrees a second that you cross while it turns, a plank that pauses open at forty-five, and a bridge, which is translation made still. Every empty cell in the procession is the sweep of one rotation, and the rotation is the only way through it.

<!-- @mario_cube -->

Twelve yellow cubes, one at the far side of every crossing. Walk into one and a rainbow of seven bands stands up three metres over it. The first one you reach does something more: the dark sphere shrinks to nothing in little more than a second and is gone. From then on the only thing in the hall you can trust is the triangle.

<!-- @two_cakes -->

Two cakes of three tiers each, assembled from the same tiers. One was turned and then slid, the other slid and then turned, and the candles stand at two different addresses. It is the last hall's lesson baked: the product changes when the factors change sides.

<!-- @pick_up_cube -->

A cube near the end, bobbing and turning once every three seconds on its own axis, which makes it the fastest thing turning in this hall: quicker than the carousel's top layer, and the only turn here you can end. Walk into it and it is gone.

<!-- @carousel_cake -->

At the end, the carousel itself, and it is bigger than it sounds: three thin plates at your ankles, a three-metre column above them, then four slabs widening to a brim ten metres across, six metres up, spanning most of the hall. Eight layers, one rule, each turning a fifth faster than the one below. The bottom takes twelve seconds to come round. The top takes three and a half. Between them the layers slide past each other in patterns that repeat and interfere and repeat. The rule is the same at every level; only the multiplier compounds, and it compounds until the object reads as rhythm rather than as a spin. Stand close, and forget which way you were going.

<!-- @ -->

##### Perpetual return

Translation goes somewhere and stops. Rotation goes round and comes back, and if you let it run it never has to stop, which is why a carousel is a spectacle and a walkway is not. What this hall adds to the chapter is time. One is added and one is multiplied: ten degrees per segment down the corridor, a fifth per layer up the cake. The difference between a building and a performance is only whether the repetition has finished.

Next: the last of the three moves, and the one that changes what everything else is worth.

### 017. Trans Scale

[Live text](http://localhost:3003/compose?map=Trans_Scale)

There is no size, only size relative to something else: scaling the object and scaling yourself are one operation seen from two sides, and proportion is what survives it.

Translation changed position. Rotation changed direction. Scale is the last freedom in the matrix, and it is the strange one, because it is the only transformation you cannot see from inside. Double everything, including your ruler, and nothing has happened. Size is not a property a thing has. It is a comparison, and this hall is a room full of things to compare.

```gdscript
func volume_ratio(before: Vector3, after: Vector3) -> float:
    return (after.x * after.y * after.z) / (before.x * before.y * before.z)
```

Double every length and the volume goes up eight times. That is the one place scale is not gentle: lengths scale as the factor, areas as its square, volumes as its cube, and a body at double the size is eight times heavier standing on four times the bone, which is why nothing shaped like a mouse is ever the size of a horse.

##### Scale me

<!-- @scale_me -->

A sphere that asks to be held. Take it, and the sphere it finds grows ten times over two seconds. You do not travel with it. At the moment you close your hand the machine sets your height to five metres and doubles your distance from the room's origin, so you arrive at the new view before anything has started to move. It does not come back while you are here. The timer is set to a thousand seconds, and even when it fires it shrinks only the sphere, over two, and leaves you exactly where it put you. Alice ate a cake and drank from a bottle for this. What has changed is the comparison, and that is enough to make the same hall intimate, then monumental.

<!-- @prism_block -->

Seven triangular prisms, every one a metre on a side, scattered across the floor of the far chamber, with a single one left behind on the near side of the low wall that crosses the hall. They are here because a cube is too symmetrical to show the difference: turn a prism and a different face takes the light, which is a thing a cube will never show you.

<!-- @cube_scene -->

Three cubes among them, the same metre, seated two-tenths higher off the floor. They are the comparison. Without them the hall is a room, and with them it is a room of a known size, and when the sphere changes you it is against these that you know it.

<!-- @chair_assembly_puzzle -->

Ten identical cubes on a bench, each shrunk to a tenth, and six cyan ghosts standing at full size where a seat, four legs and a back should go. Six of the cubes have a ghost waiting for them and four are spares. Move, turn and scale the cubes into the ghosts, and when the sixth one lands the puzzle does something stranger than finishing. Every cube you placed is deleted, and a solid wooden chair appears where they were, a fifth larger than the ghosts you were matching. You did not build that chair. You proved it could be built, and the room took the proof and handed you the object.

<!-- @clipboard -->

A clipboard at half size, turned to face you. Walk within a metre and a half and the page fades up: a drawing of the right-hand controller with one button marked, and a line saying that scale snaps to fixed sizes. It is the only writing in the hall, and it is printed at half the size of the thing it describes.

<!-- @science_screen -->

A screen on the wall, and it is the one thing here that is not looking at the room. It was set to a bar chart before it could scan, and nothing in this hall feeds a bar chart, so it draws twenty bars from a fixed seed. Take the sphere and it will not notice. A measuring instrument that has been told what to measure is not measuring.

<!-- @dark_sphere -->

The dark sphere, where the prisms end. It turns on itself the whole time you are here and never leaves its cell, and it is the one thing in this hall the pill goes looking for.

<!-- @ -->

##### The hole is the way

The wall on your right has two doorways in it, and through them a second hall with its floor cut four times. Two slots run away from you, each crossed by a cube you ride: on one the space grows by a third around you as you go, on the other it shrinks by nearly a quarter, and both give it back on the way back. Between them and the next cut, a square of empty floor three cells across with a small cube at its middle, which grows to the size of the square and shrinks again: the hole is the room a scaling needs, and the cube is exactly the size of it. A slot runs sideways, crossed with the space growing. At the end a lift stands on the floor and takes you up two metres with the space growing by half, and brings you down again. Nothing here scales the things; it scales the distance between you and them, which the first sentence of this room said was the only kind of size there is.

<!-- @mario_cube -->

Two yellow cubes, one at the end of the landing the two slots share and one past the sideways slot. Walk into one and a rainbow of seven bands stands up three metres over it. The first one you reach does something more: the dark sphere shrinks to nothing in little more than a second and is gone. The thing the pill goes looking for is the price of the first crossing.

<!-- @ -->

##### What survives

Every transformation in this chapter was a promise about what would not be touched. Scale's promise is proportion: every ratio is kept, every angle is kept, and every size is given up. That is why it is the transformation that most directly shows what invariance means. Nothing here scales you. The pill moves you instead, and moving you is enough: from five metres up and twice as far out, the room is the same shape and none of it is the size it was.

That is the chapter's question answered three times. Position, direction, size: each move gives one of them up and keeps the rest. What stays the same when everything changes is whatever the move refused to touch, and the refusing is the move.

Next: the three moves from inside, where each one is a way of being removed.

### 018. Trans Pit

[Live text](http://localhost:3003/compose?map=Trans_Pit)

The neutrality of a transformation is only available from outside the space it acts on. Inside it, move and turn are ways of being removed, and the pit is the constant.

Three rooms in a row, one per transformation, and fire in all of them. Everything the chapter did to objects, this hall does to you. A block translates, and it crosses the ground you are standing on. A slab turns, and the way through is somewhere else.

```gdscript
func _physics_process(delta: float) -> void:
    phase = fmod(phase + delta * speed / distance, 2.0)
    var t: float = phase if phase < 1.0 else 2.0 - phase  # triangle wave
    global_position = start_position + axis * distance * t
```

A number that climbs from zero to two and wraps, folded into a wave that goes out and comes back. That is all a pusher is: a translation on a timer, going three metres out and three back, forever.

##### Translation, from inside

<!-- @pusher_block -->

Three red blocks in the first corridor, each with an arrow on its face saying where it will go. Each crosses three metres of the corridor in about half a second, straight over a fire pit, waits a second, and comes back. They differ only in how fast. From outside, a pusher is the mildest thing in the chapter: position changes and nothing else does. From inside, standing where it wants to be, it is a wall that arrives. The pit is two cells along the block's line, and the block crosses it. Not every hole in this corridor burns, and the ones that do not are the same distance down.

<!-- @ -->

##### Rotation, from inside

The middle room has two turning slabs, orange and wireframed, each a little over two metres across and knee high. They stand in the two clear channels between three blocks of fire. Each takes two seconds to make a quarter turn about a vertical axis and then stops: one waits four seconds before the next quarter, the other three. A rotation has a pivot, and from outside you would say the slab goes nowhere, it only turns. From inside you learn the other half of the fact: a turn changes what the same slab occupies. Side on it nearly closes the channel. End on it leaves a metre either side. Nothing about the slab changed, and the gap did.

##### Scale, from inside

<!-- @grower_block -->

The last room has three cubes in a row, a metre each, and they do not move. Each was placed asking for a swelling that runs from a third of a metre to three and a half, and the grid does not pass those two words through, so nothing arrives and nothing grows. Scale is the one transformation this hall never performs on you, and you will walk past it without noticing, which is very nearly what scale does anyway.

<!-- @ -->

##### The constant

The pit does not care which move sent you into it. Fire is the same fire under all three rooms, and the reload is the same reload. The matrices in the first hall were true: translation preserved everything but position, rotation everything but direction, scale everything but size. They were true of the blocks and the slabs. You were not in the matrix. You were in the room, and from inside the room every one of those preservations arrives as a body coming toward you.

That is the end of the chapter, and it is the chapter turned round. Three ways of closing a gap, seen from the gap. The teleporter is at the far end, past the last block. The next rooms introduce arrays: positions that can keep their addresses while their occupants change.

## Array Tutorial Sequence

### 019. Array

[Live text](http://localhost:3003/compose?map=Array)

What remains at an address after its occupant has gone?

The transformation rooms let a position change while a shape remained recognisable. Here, keep a position in mind while the thing occupying it disappears. Begin with the row before extending the same question across a grid.

<!-- @row_3_x -->

Find the four numbered positions. Choose one cube and read its address before approaching it. Predict which entry in the accompanying table will change when your body collects the cube. Then make contact and compare the table with the space you remember.

The cube disappears. Its entry changes from one to zero, while the other entries keep their values. Point to the former position without relying on the cube to mark it. An empty slot can still have an address.

An array keeps values in an indexed sequence. In this row, the index identifies a slot and the value records whether its cube remains present. The number naming the slot and the number stored there do different jobs. Changing the stored value does not require renumbering every position after it.

The removal event supplies the update. This is a collection by contact; the exercise does not require carrying the cube somewhere else. The table knows that its occupant has left, without keeping a destination for it.

<!-- @grid_2d_4x4 -->

Now choose a cube in the grid. Give its two indices to a companion, or say them to yourself before moving. Predict the table entry that will change, collect the cube, and locate the empty place again.

Two indices distinguish positions along two directions. One selects a row or column; the other selects a position within it. Their order matters to the addressing convention. Exchanging the two can name a different slot even though the same two numbers were used. Try choosing an off-diagonal position where that exchange would be visible.

The grid adds a way of locating values, rather than a new kind of cube. A zero here means absence under this particular rule. In another array it could mean a measured quantity, a silent beat or a legitimate category. The data structure does not supply that meaning on its own.

<!-- @ -->

After collection, the label attached to a cube leaves with it. Your memory can still distinguish the empty position, but the display has made that work harder. Would you keep addresses attached to occupants, or mark the places themselves? Imagine a version with permanent floor labels and name the difference it would make before asking for it to be built.

Carry forward two separate questions: where is the slot, and what happened to its occupant? The next room slows one collection down so the event behind the changed entry can be inspected.

### 020. Tutorial Single

[Live text](http://localhost:3003/compose?map=Tutorial_Single)

What has the world recognised when one cube disappears?

The array used a disappearance to change a stored value. Here the same event has room around it. There is one pickup to inspect, and no need to make a complicated arrangement before asking what counts as an action.

<!-- @pick_up_cube -->

Stop short of the cube. Watch its bobbing and turning for a moment. It moves while you remain still. Choose a position from which you can inspect it without touching it, then predict what will happen as you approach.

Move into its detection area. Watch the collection response and the space it leaves behind. Compare that with the movement you saw before contact. One was the cube's repeating animation; the other was a change in whether the cube remained available at all.

This pickup responds to a body entering its detection area. Holding out a hand and carrying a rigid object is a different interaction, and this exercise uses approach and contact. The visible surface helps you find the object, while a detection volume establishes where an entry can be recognised.

Once collection begins, a stored flag prevents the same instance from being collected again. The response can award its configured points, play a sound and remove the cube. That small sequence makes a useful distinction: an event is something that happens; a state records what is now the case. Entering the area is an event. Having already been collected is a state that changes which later events can have an effect.

Before leaving, describe the encounter in those terms. What was present beforehand? What event changed it? What remains available afterwards? You have enough evidence for that account without treating every movement you made as something the program recorded.

<!-- @ -->

Now give your pause before contact its own significance. Perhaps you were curious, cautious, distracted or simply enjoying the moving cube. The detector did not need to distinguish those possibilities to collect it. A successful collection therefore says little about why you approached, and it cannot certify that you understood the room.

If you designed a second version, what response would let inspection count without making the cube disappear? State a condition the program could recognise, then name something important that condition would still miss. That is a design proposal to compare with this encounter, rather than an ability already hidden inside it.

The next room separates the event from your arrival. A sequencer stores places where sounds should occur, then revisits those places in time. One recognised contact becomes the starting point for thinking about a repeatable pattern.

### 021. Tutorial Disco

[Live text](http://localhost:3003/compose?map=Tutorial_Disco)

How can an arrangement that sits still make a rhythm?

You have seen slots hold values and a single event change what is present. In this room, a moving reader revisits a stored arrangement. Begin with one cell and listen for the time it becomes audible.

<!-- @step_sequencer -->

Find the sequencer's grid and its moving playhead. Start playback if it is stopped. Choose one cell, change its state, and wait for the playhead to reach its column. Predict when its sound will return. Let the loop come round before changing anything else.

Add another active cell in the same track. Listen to the distance between the two events. Then move the second event by turning its old cell off and another cell on. The instrument can remain the same while the rhythm changes, because a position in the pattern determines when that instrument is asked to sound.

Each row is a track, each column a step. An active cell requests an event when the playhead reaches it. The visible grid is stored state; playback repeatedly reads that state in a particular order. The pattern can wait without making a sound, and the playhead can move past inactive cells without adding a note.

Change the tempo and listen again. The active cells retain their addresses while the time taken to visit them changes. A pattern's arrangement and its rate of playback are separate choices. Return to the earlier tempo before making your next comparison, so you can hear which change belongs to the pattern itself.

<!-- @standalone_disco -->

Compare the floor's pulses with the sequencer. Its bridge listens for active steps and flashes a corresponding column. The floor gives the repeating score another visible form, spread across a space you can enter.

Walk with a pulse, then keep your own rhythm across it. Attend to which events follow the score and which belong to your movement. This connection runs from sequencer to floor: it does not record your footsteps into the pattern. Sharing a space with a rhythm is different from being measured by it.

<!-- @ -->

Put a beat somewhere that interrupts the repetition you expected. Does it become a mistake, an accent, or the part you wait for? The grid supplies available positions and sounds. It does not decide which of their arrangements you should want.

A gesture falling between steps would need another representation if its timing were to be retained. Imagine what you would add to preserve that chosen difference, then listen to what can already be made within the current grid. Precision and pleasure need not ask the same question.

The colour rooms continue with another arrangement whose parts change how their neighbours are experienced. Carry the distinction between a stored value and the relation through which you encounter it.

## Color and Composition

### 022. Color Context Placed

[Live text](http://localhost:3003/compose?map=Color_Context_Placed)

How much of a colour belongs to its surroundings?

The sequencer let a fixed arrangement become a rhythm through the order in which it was read. Here an arrangement is read through enclosure, proportion and attention. Begin with one canvas rather than trying to name every colour in the gallery.

<!-- @albers_wall_gallery -->

Choose a set of nested squares. Look first at its centre, then at the larger bands around it. Step back enough to take in the whole canvas. Which region holds your attention now? Describe a difference in the way the composition appears before reaching for a rule about what colours ought to do together.

Compare a neighbouring canvas. The construction repeats, but its palette changes. Find a pair in which the centre seems prominent in one composition and less insistent in the other. Treat that as a report of this viewing, not a response every visitor must share.

Each canvas is built from successively smaller squares. Their sizes follow a repeated inset ratio, while a seeded selection supplies the colours. The seed makes the generated palette repeatable; it does not make your experience of it independent of the display, surrounding light or where you look.

Composition concerns the relations among the regions. A stored colour supplies values to a material. Its appearance also depends on the conditions in which it is encountered. Describing those two things separately lets a numerical account and a visual account both be useful without pretending they answer identical questions.

These canvases have different palette values. They therefore do not prove that an identical centre colour changes appearance against different backgrounds. That would require a controlled pair with the centre held fixed. Keep that possible next experiment in mind while being precise about what this gallery already lets you compare.

<!-- @ -->

Reduce how much of the surrounding bands you attend to, then look at the whole canvas again. Try allowing an outer band to become the subject and the centre to become its interruption. The geometry has not moved, but the hierarchy of attention can change.

Which part of a composition gets to count as background? Your answer need not agree with the largest region or the one placed in the middle. A different way of looking can make another relationship available.

The next room brings colour onto the surfaces of a represented body. Carry this distinction with you: choosing channel values is one action; discovering how those values appear on a particular surface is another.

### 023. Color Nails

[Live text](http://localhost:3003/compose?map=Color_Nails)

What changes when a colour becomes part of the body you act through?

The gallery supplied finished palettes. Here you can make a choice and watch a preview answer it. The first comparison is between a movement in a coordinate box and a change in colour.

<!-- @nail_color_controller -->

Find the movable point in the RGB box. Take hold of it and move mainly along one axis. Watch the preview swatch before moving along another. Predict which part of the colour will change on the next movement, then test that prediction with a short return journey.

The point's three coordinates are constrained to the box and converted into red, green and blue channel values. Moving along one axis changes one channel. Moving diagonally can change several at once. The box turns a colour choice into a position that your hand can revisit.

This is a three-channel description of colour. It does not divide every difference you can perceive into three equally noticeable kinds. Equal distances in the box need not feel like equal changes in the preview.

When tracked hands are available and connected, compare the nail surface with the swatch. The nail material adds its own response to light. A colour selected in the box can look different on a small glossy surface from the way it appears on the flat preview.

<!-- @hand_color_controller -->

Repeat the comparison at the controller for the hand surface. Keep the coordinate gesture simple enough to recognise. Which difference seems to belong to your chosen channels, and which to the surface receiving them?

The two stations use the same position-to-colour mechanism but target different surfaces. The preview remains useful when tracked hands are unavailable; seeing that preview change does not establish that a hand material has been updated. Compare the surfaces that are actually present in your encounter.

<!-- @ -->

Choose a colour because you want it, without requiring a naturalistic match. Try a nail or hand that interrupts the palette you expected from this body. What does that choice make possible for your sense of the figure you act through?

The editable channels are a material choice, not a complete description of identity. A system can make a surface adjustable while leaving many other bodily possibilities fixed. Name one choice the box gives you and another it does not.

From here, colour expands from a body surface into a spatial composition. The next room asks how coloured objects become readable through their positions, overlaps and scale.

### 024. Color Pillar

[Live text](http://localhost:3003/compose?map=Color_Pillar)

Can a small arrangement help you see a larger one?

You have chosen colours on a represented body. Now let coloured bodies arrange a space. Begin by changing your view, then change the composition itself.

<!-- @pillarcolorcollection -->

Look along a row of coloured pillars. Move across the row until gaps open between bodies that overlapped from your first position. Choose one colour to follow through that change. Which neighbours does it seem to acquire or lose?

The pillars receive colours from a repeating palette as they occupy a grid. Their values can stay fixed while their visible relationships change with your position. An overlap is a relation among objects and a viewpoint; it is not stored in a colour alone.

Look for an interval that you want to preserve. It might be a balanced spacing, a narrow glimpse, or an awkward obstruction. You are choosing a compositional purpose before asking the next instrument to help realise it.

<!-- @composition_twins -->

At the small composition, move one of the movable primitives. Watch its larger partner in the basin. Make a short displacement, predict the direction of the response, and return the smaller piece toward its earlier position. Use colour and shape to keep track of which pair you are following.

Arrange a second piece while leaving the first as a reference. A relationship at the table becomes a relationship among larger bodies. Walk to another viewpoint and compare what the arrangement now conceals or reveals.

The larger partner follows the smaller leader's transform. Displacement from the table's anchor is multiplied for the larger composition, and the body's size has its own scale factor. The two are coupled by a rule; the larger object is not making an independent decision about where to stand.

That coupling preserves useful relationships without guaranteeing identical experiences at both scales. A gap that is easy to see over at the table may interrupt a view among the larger bodies. Your height, viewing angle and distance have become part of the comparison.

<!-- @ -->

Try arranging a deliberate occlusion. Make one view difficult and another unexpectedly clear. Explain whom or what position the composition seems to favour. You can use the same controls to produce a harmonious arrangement or a difficult one; the mechanism does not choose that purpose for you.

The following room moves from relationships in space to paths through colour coordinates. Keep the question of what a transformation preserves, and what a changed way of encountering it adds.

### 025. Color Walls

[Live text](http://localhost:3003/compose?map=Color_Walls)

Must two paths between the same colours pass through the same middle?

The pillar room let an arrangement change while identifiable partners remained connected. Here the endpoints are your reference. Hold them fixed while changing the rule that supplies what lies between them.

<!-- @gradient_interpolator -->

At GRADIENT, choose two colours with the endpoint selectors. Use MODE to compare RGB and HSV while leaving those endpoints alone. Start with a visibly separated pair, such as red and blue. Predict a middle colour before inspecting the intermediate cubes.

The endpoints can agree while the interior of the gradient changes. In RGB, the program interpolates the three channel values directly. In HSV, it treats hue as an angle and follows the shorter way around its wrap, while interpolating saturation and value. Each method defines a path in its own coordinates.

An interpolation parameter says how far to travel along that chosen path. It does not, by itself, determine which path should be used. Halfway therefore needs a rule as well as two endpoints.

Choose two nearby colours and repeat the comparison. Then return to a pair whose intermediate colours differ strongly. Find a case where the choice of method matters to an effect you want, rather than deciding that one mode must be the correct answer for every composition.

<!-- @color_space_navigator -->

Examine the sampled RGB cube from outside. Look at how its three spatial directions distribute colour, then compare the cylindrical companion. These small models let different coordinate organisations stand beside one another. They are displays to inspect, rather than spaces you need to enter or points you can select.

The cylindrical companion carries an HSL label, but its current colour generation uses HSV. That label therefore cannot establish an HSL comparison. Use the working RGB/HSV gradient to test the path question, and keep the companion's naming mismatch visible as something the display needs to resolve.

<!-- @ -->

A straight path through coordinates need not produce equally noticeable visual steps. Nor does a finite sample contain every possible colour. The representation gives you ways to arrange a choice, and those ways have their own limits.

Imagine taking the longer route around hue while retaining the same endpoints. The current HSV mode chooses the shorter route; a longer-route control would be an extension. What intermediate colours would make that detour worth choosing?

The next sequence repeats forms across surfaces. Carry the distinction between the parts you begin with and the rule that determines their relationships.

## Tiling and Symmetry

### 026. Pattern Foundry

[Live text](http://localhost:3003/compose?map=Pattern_Foundry)

How many places can one small decision change?

The colour rooms separated a chosen value from the rule that relates it to other values. Here a small arrangement supplies a much larger field. Make one decision where you can see exactly where it began.

<!-- @pattern_tile_4x4 -->

Take a coloured cube from the palette and release it over an off-centre cell in the small tile. Watch the repeated preview. Find several places where your mark appears, then locate the one source cell you changed.

Add a second mark beside the first. Predict the repeated pair before looking across the whole field. The size of the result can make the action seem more complicated than it was. Many visible changes have followed one local edit.

The tile stores a finite array of colour choices. To draw the larger field, the repetition rule maps each preview position back to a position in that array. Copies share a source. They do not each contain a separately authored decision.

<!-- @pattern_tile_mirror -->

Make a recognisably asymmetric mark at the mirror station. A mark away from the centre, with a differently coloured neighbour on one side, makes reversal easier to notice than a centred dot would. Follow the pair through the preview and compare the directions in which it faces.

The simple repetition keeps the tile's orientation. The mirror rule reverses selected copies along its directions. The source motif and the transformation applied to its copies do different work: changing either can change the field.

Now try to make the mark appear only once while the rest of the field stays unchanged. Editing the shared source makes it recur. The difficulty is evidence about the way this instrument stores authorship, rather than a failure to choose the right colour.

<!-- @ -->

A repeated field can be economical, recognisable and pleasurable. It can also make a wanted exception difficult to express. Choose a reason for keeping one copy different: a direction marker, a mistake you want to retain, or a place that should resist the general pattern.

A separate exception layer or an independently editable copy would make that possible, but it would add something to the present design. Name what should stay shared and what you would let separate. Uniformity and difference can then become choices with explicit consequences.

The next station keeps the motif while changing the larger symmetry rule. Carry an asymmetric mark with you in memory; it will help you see which operation has been applied.

### 027. Tutorial Pattern

[Live text](http://localhost:3003/compose?map=Tutorial_Pattern)

What can change when you keep the painted cells exactly as they are?

The foundry gave one tile many appearances. Here you can distinguish editing the tile from editing the rule that repeats it. Begin with a motif whose orientation is easy to recognise.

<!-- @pattern_maker_station -->

Select a palette colour and touch a few cells on the upright grid. Put an off-centre mark beside another colour rather than making every side alike. Follow that small arrangement into the carpet.

Keep the painted cells fixed and cycle the group control. Predict one thing that might move, turn or reverse before looking at the new result. Locate a copy of your original mark after the change. Its colours can help you recognise it even when its facing differs.

The local array supplies the motif. A symmetry rule determines how positions in the larger field refer back to that array. Changing the rule can reorganise the field without adding paint to the source. A large visible difference therefore need not imply a large number of local edits.

Return to a rule you recognise. This time use the buttons that mirror or rotate the source itself. Look back at the painted grid as well as at the carpet. Those operations rewrite the source arrangement. They are a different intervention from leaving that arrangement intact and changing how copies are made.

Two operations can sometimes produce similar-looking results. The picture alone may not tell you which one was used. Keeping track of what you held fixed lets you make a stronger account of the change than simply naming the finished pattern.

<!-- @ -->

Make a motif that appears symmetrical, then add one cell that breaks that local symmetry. Watch what the repetition does to your interruption. Some regularities belong to the source; others are supplied by the way its copies are related.

The palette and grid establish which marks this station can retain. They cannot contain every texture, irregular edge or gesture you might want to make. Choose one feature that would be lost in translating a hand-drawn mark into these cells, and decide whether that loss matters for your purpose.

A group name describes mathematical relationships within a pattern. It does not settle what the pattern means, who made it, or what uses it should have. Those questions can remain open while the repeating operation becomes precise.

The next room puts a repeated pattern onto a surface that extends through space. Watch for the difference between the rule of a field and the way that field is revealed to you.

### 028. Array Patterns

[Live text](http://localhost:3003/compose?map=Array_Patterns)

When does repetition become an environment rather than a picture?

You can now separate a motif from the rule that repeats it. This room adds a receiving surface and a timed reveal. Keep those choices apart while trying the console.

<!-- @pattern_tunnel_machine -->

Choose a motif and palette you can recognise. Leave both fixed and change GROUP. Watch how the tube is covered again. Find a small feature of the motif and follow the orientations in which it returns.

Then keep the same pattern choices and adjust SPEED. Compare the time taken for the covering to appear with the arrangement left when it is complete. A change in the speed of revealing a pattern need not change the pattern that is revealed.

The machine passes the motif and repetition choices to the surface's covering rule. It controls the rate of the reveal separately. The distinction matters because a performance can make a static arrangement appear to have a direction, beginning or climax. Those features can belong to its presentation rather than to the finished field.

Look at the surface from another position. Curvature and perspective can hide a repeated unit or make one interval seem wider than another. Describing the local rule gives you a way to recognise something that the view does not always make obvious.

<!-- @pattern_tile_brick -->

At the brick station, place a coloured cube away from the centre of the source tile. Follow its mark through two neighbouring rows of the preview. Predict where the next row's boundary will fall.

Alternate rows are offset. The same source is still being read repeatedly, but the seams no longer line up in the same way. A small change in the lookup rule creates a different relation among whole rows.

Compare that stagger with the tube's covering. You have a motif, a rule and a surface in each case. Naming those parts separately helps you choose which one to change when the result is not what you wanted.

<!-- @ -->

Try a palette and motif that seem stylistically mismatched. Describe their structural relationship without relying on a preset's historical name. A preset offers a usable selection; it cannot stand for every practice, maker or variation associated with a period.

The tube is finite, however continuous its pattern may look. The next room asks about an ideal pattern that repeats indefinitely in two independent directions. Keep the distinction between the rendered example you can inspect and the mathematical conditions under which a classification is made.

### 029. Symmetry Seventeen

[Live text](http://localhost:3003/compose?map=Symmetry_Seventeen)

What assumptions make a catalogue of symmetries finite?

The preceding stations changed repetition rules while keeping a recognisable motif. Here, use that skill to inspect the scope of a classification. Begin with a mark that makes turning and reversal visible.

<!-- @vr_tile_editor -->

Use the editor's coloured cubes to make an asymmetric motif. If the editor is in its initial mirror mode, switch to its wallpaper-group mode before using group navigation. Compare two group choices while keeping your painted source fixed.

Find one copy that has turned and one that has reversed, when the selected rule supplies them. Follow the relationship between your local mark and the larger field. A decorative shape can occur inside a tile without being a symmetry of the whole pattern.

Wallpaper groups classify the symmetries of ideal patterns that repeat in two independent directions on the Euclidean plane. Under those conditions there are seventeen types. Translation, rotation, reflection and glide reflection combine within that classification. Its scope is stated alongside the [IUCr plane-group tables](https://it.iucr.org/Ab/).

The finite carpet is an example through which to inspect a rule. It does not become an infinite plane merely because its edges are outside your current view.

<!-- @wallpaper_cage -->

Inspect the cage's marked rotational orders. It marks one, two, three, four and six as compatible with a periodic planar lattice, and crosses five and seven. These are the counts of equal turns that return a rotation to its starting orientation.

The cage is a diagram of a restriction. It does not run an experiment that attempts to close each lattice, and looking at its marks is not a proof of the full classification. Use it to form a question that you can carry back to the editor.

Try a fivefold-looking motif within a repeating cell. What repeats is the whole cell. That local fivefold figure does not require the entire periodic pattern to have fivefold rotational symmetry. Distinguishing a shape inside the pattern from a symmetry of the pattern resolves an apparent contradiction.

<!-- @ -->

Seventeen does not count every textile, finite ornament, aperiodic arrangement or meaning someone can make with a pattern. The conditions make the result precise, and also name where it stops applying. A useful classification leaves those conditions visible.

Choose a feature you would want to investigate beyond the periodic plane. A nonperiodic comparison would need another example, rather than another name forced into this catalogue.

The next sequence studies change itself. Carry the habit of asking which quantities a rule relates and what must be held fixed before its answer can be interpreted.

## Change: Rate, Accumulation, and Flow

### 030. Change Intro

[Live text](http://localhost:3003/compose?map=Change_Intro)

Where can a high curve be changing very little?

The pattern rooms taught you to keep an input fixed while changing the rule applied to it. Here the curve stays fixed while you move the position at which it is inspected. Begin by separating height from change.

<!-- @tangent_slope_workbench -->

Move the sample-position slider slowly along the curve. Stop near a high point and look at the tangent. Then choose a visibly steep section, even if it lies lower. Compare the value labelled f(x) with the value labelled f′(x).

Before moving again, predict the tangent's direction at your next position. Check the direction and the derivative display together. Find a place where the curve rises as you move along it and another where it falls. The signs distinguish those local directions of change.

The function assigns a height to each horizontal position. Its derivative describes the local rate at which that height changes with position. A high value can coexist with a nearly horizontal tangent. A lower value can have a large positive or negative slope. Neither quantity can replace the other.

This bench uses a smooth combination of sine and cosine terms and evaluates its derivative directly. The displayed tangent follows the selected position, while the derivative plot lets the sequence of local slopes become a second curve.

Follow a short section near the point of contact. The tangent can approximate the curve there, but extending the same straight line farther does not make it an account of the whole curve. Local information is useful partly because it asks a smaller question.

<!-- @ -->

Find two positions of similar height with opposite slopes. Imagine receiving only their height values. What difference in the situation would that report conceal? A measurement can be accurate and still omit the distinction needed for your next action.

A near-zero slope also needs context. It does not mean the function never changes, and a stationary point alone does not classify every possible shape around it. Inspect the neighbouring values before deciding what kind of event you have found.

A curve with a sharp corner would pose another question: whether one tangent can describe the rate from both sides. That comparison would require another function in this bench. For now, state what you would expect to differ from the smooth example you have inspected.

The next room accumulates many small contributions. Carry the distinction between the value of a function and the way that value changes, because the two will meet again from the other direction.

### 031. Accumulation Riemann

[Live text](http://localhost:3003/compose?map=Accumulation_Riemann)

How much can an estimate change when its pieces become thinner?

The tangent bench inspected one position at a time. This bench uses many sampled positions together. The question is what their contributions can tell you about an interval.

<!-- @riemann_sum_workbench -->

Begin with four rectangles. Look where their tops differ from the curve, then predict what eight rectangles might change. Move the count slider and compare the estimate with the reference shown beside it.

Continue through sixteen, thirty-two, sixty-four and one hundred and twenty-eight. Watch the rectangles become thinner. Distinguish a change in the approximation from a change in the underlying curve: it is the same curve receiving a different number of samples.

Each rectangle uses the function's height at its midpoint. Its contribution is that height multiplied by the interval's width. Adding those contributions produces the midpoint sum. The operation joins a value and the extent over which that value is being used to stand in for the curve.

The displayed reference is itself a numerical midpoint sum, made with 4,096 rectangles. Its density makes it a useful comparison here, but the label does not turn a finite computation into an exact symbolic integral. Compare estimates while keeping that distinction visible.

For suitable functions, refinement lets midpoint sums converge to the integral. This smooth example lets you investigate that approach; it does not prove that every increase in sample count improves every function monotonically. The conditions and error estimates are developed in [OpenStax's numerical integration chapter](https://openstax.org/books/calculus-volume-2/pages/3-6-numerical-integration).

<!-- @ -->

Choose a tolerance you would accept for a particular use, then find the coarsest estimate you would keep. Compare that choice with another visitor's, or repeat the decision under a stricter tolerance. More samples cost additional work. Whether the difference matters depends on what the estimate will be used to decide.

Imagine a narrow peak falling between two sample positions. A coarse picture might miss it while looking perfectly regular. That curve is a proposed further test, rather than a feature you can select at this bench. Name what the missed contribution would do to the estimate.

The next room also accumulates small steps, but its result is a moving path. Keep track of which information is sampled locally and which larger pattern becomes visible only after those samples have been used together.

### 032. Flow Field

[Live text](http://localhost:3003/compose?map=Flow_Field)

Can local directions produce a picture nobody drew as a whole?

The rectangle sum accumulated sampled contributions across an interval. Here repeated local readings move particles, and their trails make the accumulated result visible. Begin with one path before reading the whole canvas.

<!-- @flow_field_painter -->

Follow one trail through a bend. Predict its next direction from the nearby flow, then watch the particle continue. Notice whether neighbouring particles remain close, separate, or approach similar routes.

Hold SPEED fixed and change SCALE. Look for a change in how directions are organised across the canvas. Then leave SCALE alone and change SPEED. Compare the distance particles travel in a short interval with the shape of the field they are reading.

The painter samples a scalar noise value at a particle's location and converts that value into an angle. Cosine and sine turn the angle into a direction. A small movement along that direction is repeated on the next update, at the particle's new position. The field supplies local instructions; the trail retains a bounded record of the resulting path.

This direction is made from a noise value. It is not the noise function's gradient, which would require measuring how that value changes with position. The distinction matters when deciding what the picture demonstrates.

Use RESET to begin with a fresh particle distribution, or SEED to change the noise field. Keep track of which choice you made. Different paths can result from new starting positions under one field, as well as from a different field.

<!-- @ -->

Watch a particle approach an edge and predict where it will reappear. Opposite edges are connected by wrapping. Leaving the right side returns it on the left, so the edge is a join in this world's rule rather than an opening into unmodelled space.

The streams may recall a fluid, but this painter does not compute pressure, mass or interactions among particles. The resemblance gives you a way to notice the motion; it does not supply the missing physical quantities.

Choose a different boundary rule in thought. A particle might stop, reflect or leave permanently. What pattern would you expect each choice to preserve or disrupt? Those alternatives would require changing the implementation. The current wrapped canvas is one particular world in which the local rule operates.

The next room distinguishes everything that happened along a path from the difference left between its endpoints. Bring one trail whose journey would be poorly described by its final position alone.

### 033. Change Reconciliation

[Live text](http://localhost:3003/compose?map=Change_Reconciliation)

Can a process return to its starting value after changing all the way?

The preceding rooms separated a local rate, an accumulated quantity and a path made from repeated steps. This bridge gives you a small observation through which to bring those distinctions together.

<!-- @ftc_bridge -->

Watch the pulse move along the arch. Compare its height near the first end, at the top, and near the other end. Before it reaches the far side, predict the height difference that will remain between its beginning and end.

The default arch rises and falls to a level endpoint. The pulse visits many different heights, while its final height difference is zero. Describe both facts. Zero net change does not mean that nothing happened along the way.

Take horizontal position as the input and height as the function's value. On the rising side, the local height rate is positive; on the falling side it is negative. For a continuously differentiable height function, integrating that signed rate across the interval recovers the final height minus the initial height. This is the net-change relationship of the fundamental theorem of calculus. [OpenStax develops the distinction between net change and total movement](https://openstax.org/books/calculus-volume-2/pages/1-4-integration-formulas-and-the-net-change-theorem).

The bridge supplies a moving marker and an equation. Its current display does not lay out a live numerical sum of the positive and negative rate contributions. Observing cancellation in the endpoint heights is therefore a useful illustration, rather than a visible computation or a proof of the theorem. Inspect the marker from the surrounding floor; the comparison does not require climbing onto the model.

<!-- @ -->

Think of a journey that returns to its starting place. Its displacement can be zero while its travelled distance remains positive. Likewise, adding signed height changes is a different operation from adding their absolute amounts. Choose which account you would want if you were planning a route, describing effort, or simply asking where someone ended.

Now imagine an arch that finishes higher than it begins. The signed contributions would leave a nonzero difference. A version showing that curve alongside its accumulated rate would extend this encounter. Name what should be held fixed so that the comparison answers the question you intended.

The forces sequence puts rates into motion: position can change through velocity, and velocity through acceleration. Carry forward the habit of naming what is changing, with respect to what, before interpreting a number or a path.

## Vectors & Forces: From Direction to Dynamics

### 034. Vectors Act1 WhatAVectorIs

[Live text](http://localhost:3003/compose?map=Vectors_Act1_WhatAVectorIs)

The question is on the wall before anything else is.

<!-- @3t -->

**WHAT IS A VECTOR, BEFORE IT IS ANY PARTICULAR ARROW?** The room asks it in capitals at the door and then refuses to answer it in words. It answers in four stations instead, walked in order, and the order is the definition: a where, a which-way, a how-far, and a how-far refused.

Nothing in this hall is added to anything. Nothing is multiplied. You are here to meet the object before anyone does anything to it.

<!-- @ -->

##### A where

```gdscript
func project_onto_axes(p: Vector3) -> Array[Vector3]:
    return [
        Vector3(p.x, 0.0, 0.0),
        Vector3(0.0, p.y, 0.0),
        Vector3(0.0, 0.0, p.z),
    ]
```

Three axes and an origin have to exist before a single fact about a vector can be stated. Before the arrow, the frame.

<!-- @CoordinateSystem3M -->

You have stood in this frame before, in the first room of the first chapter, where it was the thing you were thrown into. Stand in it again and read your own address off it: three markers ride the three axes, and each is where your shadow lands when the light comes from one direction at a time.

A coordinate is not a property of you. It is a property of you *and the frame*, and the frame was chosen by somebody else. Move the axes and every address in the room changes while nobody in the room has moved. The first fact about a vector is that a *where* is not yet one.

<!-- @ -->

##### A which-way, and a how-far

```gdscript
func get_vector(start: Node3D, end: Node3D) -> Vector3:
    return end.global_position - start.global_position
```

A subtraction. That is what a vector is made of: not a place but the difference between two, and the difference has thrown both places away in the making. Grab either handle and the vector changes. Grab both and carry them together, and it does not.

<!-- @VectorBasics -->

Take the tip and pull. Two facts survive whatever you do to it, and only two: the way it points, and how far it goes. Everything else about the arrow, where it sits, what it is near, which hand is holding it, is furniture.

```gdscript
func slide(arrow: Node3D, offset: Vector3) -> void:
    arrow.global_position += offset
```

Now slide the whole thing across the room. Same direction, same length, and the subtraction above returns an identical `Vector3` afterwards, to the last float. The arrow moved and the vector did not, because the vector was never *at* anywhere.

<!-- @route_vector -->

A from-pin, a to-pin, and one arrow between them, with a courier walking it to show that the trip is a single move. It is the sentence the whole room is built to say, and it says it once: **a vector is a journey with no starting address.**

Keep hold of how strange that is. Every journey you have ever taken began somewhere. This one keeps the going and discards the from, and it is more useful for it, because a going that belongs to no particular place can be reused in every place.

```gdscript
func component_legs(v: Vector3) -> Array[Vector3]:
    var x_end := Vector3(v.x, 0.0, 0.0)
    var z_end := Vector3(v.x, 0.0, v.z)
    return [x_end, z_end, v]
```

Take it apart and it stays one thing. Along the floor, then across it, then up: three legs laid tip to tail arrive exactly where the single arrow arrived. The room's three axes were never a cage. They were the three directions a journey can be told in.

<!-- @ -->

##### How far

```gdscript
func magnitude(v: Vector3) -> float:
    var floor_diagonal := sqrt(v.x * v.x + v.z * v.z)
    return sqrt(floor_diagonal * floor_diagonal + v.y * v.y)
```

Two Pythagoras theorems, stacked. One lies flat on the floor and finds the diagonal of the x and the z. The second stands that diagonal up against the y and finds the diagonal of *that*. `v.length()` returns the same float in a single call and hides the nesting, which is fine until the day you need to know that "how far" was built out of two right angles.

<!-- @length_lantern -->

Stretch it and it brightens. The glow is the square root of x squared plus y squared plus z squared, and nothing else feeds it, so the lantern is a ruler that reports in light.

```gdscript
func magnitude_under(v: Vector3, norm: String) -> float:
    if norm == "taxicab":
        return absf(v.x) + absf(v.y) + absf(v.z)
    if norm == "chebyshev":
        return maxf(absf(v.x), maxf(absf(v.y), absf(v.z)))
    return v.length()
```

But read what the code allows. *Far* is a choice, and there are at least three. Euclidean is the diagonal, the way a crow goes. Taxicab is the walk along the legs, the way a body goes through a city with buildings in it. Chebyshev is the longest leg alone, the way a king moves on a board. The arrow never moves between these. The ruler does, and the same journey is three different distances depending on who is measuring.

The lantern here glows with the diagonal. It could be told otherwise. Two rooms ago, a ruler that altered what it did not measure; here, a ruler that is one of several and does not say so.

<!-- @ -->

##### A how-far refused

```gdscript
func unit(v: Vector3) -> Vector3:
    var m := v.length()
    if m < 0.001:
        return Vector3.ZERO
    return v / m
```

Divide the vector by its own length. What is left has a length of exactly one and keeps nothing but the which-way, and every direction there is, in the whole room, lands somewhere on a single sphere of radius one. That sphere is where direction lives once distance has been sent away.

<!-- @vector_normalize_demo -->

Pull an arrow of any size and watch it snap to the sphere. Long or short, it lands on the same surface, and the only thing it brings with it is where on the surface it lands. This is the fourth fact, and it is a refusal: a vector can be asked to give up its how-far and it still has something to say.

```gdscript
func is_degenerate(v: Vector3, threshold: float = 0.18) -> bool:
    return v.length() < threshold
```

Except one. Zero has a magnitude, and it is zero, but it has no direction at all, and asking it for one is a division by zero. So the function hands back zero rather than lie about which way it points, and the demo has nowhere on its sphere to put it. That is worth more than it looks: a system that says *I cannot tell you* is rarer than one that tells you something wrong.

<!-- @ -->

##### Four facts, one arrow

A where, which was not yet a vector. A which-way and a how-far, which are the whole of one. A how-far refused, which leaves direction alone on its sphere. Walked in order, they are a definition that no sentence could give you, because each fact was something you did with your hand before it was something you knew.

Nothing in this hall acted on anything else. The next one is where vectors first act on each other: to add is to walk, to dot is to agree, to cross is to turn. Carry the sentence in. *A vector is a journey with no starting address.* Everything that follows is what such journeys do when they meet.

### 035. VFM 02 Operations

[Live text](http://localhost:3003/compose?map=VFM_02_Operations)

You arrive in the middle of the row.

The spawn is at the eleventh column of the north wall, and there are instruments on both sides of you before you have taken a step — five to the west, five to the east, all at arm's height, all facing the same way. Twenty-seven in the room. Until this afternoon not one of them said a word about itself.

This is a bench. Everything on it is true, and almost nothing on it is the lesson. The lesson is next door, where the same operations stand at the size of a room with a caption panel each. What a bench is for is the other thing: to let you hold six answers to one question at once and find out that they disagree.

##### Pick one up before you read its label

<!-- @sub:intro -->

The first panel asks you to do exactly that, and it is not a rhetorical move. Every instrument in here is a vector operation rendered as furniture: a board, a barrel, a crank, a rail, a gauge. The rendering is not decoration and it is not neutral. It is a claim about what the operation *is like*, made before any arithmetic is shown, and you can test it with your hands before anyone tells you the answer.

Walk east first — the floor takes you that way, because there is more room on that side.

<!-- @ -->

##### Add by walking

<!-- @adder_board -->

The one artifact in this room ruled primary. Two operands go in, a sum comes out, and the board's own export decides how much of that you are allowed to see:

```gdscript
#### adder_board.gd
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "expression"
```

Four settings, and they are four different pedagogies. `outcome` shows the answer. `operands` shows what went in. `trace` shows the path. `expression` — the shipped default — shows the whole sentence, both sides of the equals.

That export is not unique to this board. `torque_crank` has the same four values and ships set to `trace`. So two instruments in one room have been given opposite instructions about how much of their own working to show, and nothing in the room announces which is which. You are standing in a bench where the answer to *show your work?* was decided per object, by whoever built each one.

<!-- @sub:ask_add -->
<!-- @sub:truth_add -->

The caption at the third row asks where you end up if you walk a then b; the answer waits two rows further south, at row five, so the question is behind you by the time it is answered. That is deliberate and it is the room's method: you are meant to have done the walking in the gap.

<!-- @ -->

##### Find out what the gauge is blind to

<!-- @agreement_gauge -->

This is the instrument worth staying with, because it is the one that admits the room has a problem.

```gdscript
#### agreement_gauge.gd
const MEASURES: Array[String] = ["cosine", "projection", "angle"]
const SHIPPED_A: Vector3 = Vector3(0.9, 0.55, 0.2)
const SHIPPED_B: Vector3 = Vector3(0.35, 0.85, 0.6)
```

Three measures of the same thing. Grab either tip, change the angle, and the gauge reports how much the two arrows agree — as a cosine, as a projection, or as an angle. They are not interchangeable. The source says so in its own comment: cosine is *magnitude-blind*, and under `projection` "length now contaminates" the reading.

So the question the room keeps asking — *how much do these two agree?* — has three answers, and picking one is picking what you are willing to ignore. The shipped default is `cosine`, the blind one. Make one arrow four times longer and the needle does not move. That is either the correct abstraction or a discarded fact, and the gauge cannot tell you which, because the decision was made before you arrived.

Two arrows agreeing is a·b = |a||b|cos θ. Divide the magnitudes out and you have kept the angle and thrown away the size. Every instrument on this bench has made a trade of that shape. Most of them do not have a switch on the front to show you it happened.

<!-- @dot_aligner -->

The barrel beside it takes the same number and gives it a job. Where the gauge reports agreement, the aligner *hunts* for it: turn the rig until the reading peaks and the lock beam fires, and the foe turns from red to green. The dot product stops being a measurement and becomes a targeting condition — the first place in the chapter where an operation is used for something rather than shown.

<!-- @sub:truth_sub -->
<!-- @sub:truth_scale -->
<!-- @sub:truth_dot -->

<!-- @ -->

##### Watch a shadow do the arithmetic

<!-- @projection_shadow -->

```gdscript
##### projection_shadow.gd
##### proj_n(a) = (a · n̂) n̂ — the shadow's distance from the origin IS a · n̂
```

A rail, a vector, and a light. The shadow the vector casts along the rail is not an illustration of the projection; it is the projection, at full size, and its distance from the origin is the dot product itself. Nothing is computed for display here that is not already the thing.

That is the strongest claim this bench makes and it is made without a caption panel, in a comment, in a file. Slide the vector until it stands perpendicular to the rail and the shadow collapses to a point: the two share nothing, the dot product is zero, and the geometry and the arithmetic arrive at zero together and for the same reason.

<!-- @sub:truth_cross -->
<!-- @sub:close -->

<!-- @ -->

##### Turn the crank and watch what is left over

<!-- @torque_crank -->

```gdscript
#### torque_crank.gd
@export_range(0.0, 1.0, 0.01) var leverage: float = 0.78
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "trace"
```

An arm, a push, and an axis that appears when the two refuse to line up. `leverage` runs 0 to 1 and the flywheel turns hardest in the middle of that range, not at the end of it — push along the arm and nothing happens at all, because a cross product of two parallel vectors is the zero vector.

Set to `trace`, this one shows you the path rather than the sentence. The board across the room shows you the sentence. Between them the room has quietly taken both positions on how an operation should be taught, and left you to notice.

<!-- @ -->

##### Twenty-six other answers

<!-- @vector_add -->
<!-- @vector_dot_product_xl -->
<!-- @vector_cross_product_xl -->
<!-- @vector_projection_reflection_xl -->
<!-- @vector_addition_demo -->
<!-- @vector_addition_xl -->
<!-- @vector_subtraction_demo -->
<!-- @VectorSubtraction -->
<!-- @vector_magnitude_demo -->
<!-- @stretch_bench -->
<!-- @basis_vectors_rig -->
<!-- @coordinate_system_switcher -->
<!-- @2d_in_3d_vectors_vis -->
<!-- @VectorWorkbench -->
<!-- @VectorTorque -->
<!-- @torque_demo -->
<!-- @dot_product_projector -->
<!-- @opening_pair -->
<!-- @vector_translation_demo -->
<!-- @example_1_4_vector_multiplication_vr -->
<!-- @exercise_5_9_angle_between -->
<!-- @vector_projection_demo -->

Every one of these is ruled secondary, and the ruling is not a demotion. Each says something the room has already said, or will say again next door at walk-in scale, and the arrangement records that so a reader knows this is a bench and not a curriculum. Six of them carry `_xl` in the name and delegate to the algorithm scenes at five times the size; two of them are the same operation as `adder_board` with different furniture around it.

A room can afford to say a thing six ways. What it cannot afford is to leave you unable to tell which of the six you were supposed to learn from. That is what the thread is: the one order through here that somebody decided, and everything else standing beside it.

<!-- @ -->

##### Who decided these seven

The bench closes on a question rather than a summary, at the last panel before the door:

> Seven operations, laid out in a row like a shop. ? who decided these seven were the operations ?

Add, subtract, scale, dot, cross, project, torque. It is a good list. It is also a catalogue, and a catalogue is a claim about what exists — the same claim a marketplace of purchasable bodies makes when you go looking for a model and find that the categories were waiting for you. There are other operations. Nothing in this room is the reason you have not met them.

The door goes to `Vectors_Act2_VectorArithmetic`, where these same seven stand at the size of a room, each under its own caption, down a single corridor in the order somebody chose. This room is where they are all true at once. The next one is where they are taught.

### 036. Vectors Act2 VectorArithmetic

[Live text](http://localhost:3003/compose?map=Vectors_Act2_VectorArithmetic)

Nothing in the last hall acted on anything. This one is where vectors first act on each other, and the hall is built to say it twice: every idea once as a toy in your hand, then once at the size of a room you step into.

There are six operations. Three verbs carry them, and the room's own reflection puts them in one line at the end. You will arrive there having done each one with your hands.

##### To add is to walk

```gdscript
func head_to_tail(a: Vector3, b: Vector3) -> Array[Vector3]:
    var origin := Vector3.ZERO
    return [origin, a, a + b]   # tail, joint, resultant head
```

<!-- @vector_add -->

Two pads on the front of a console, one per vector. Drag a pad and that arrow's tip follows your hand: cyan for the first, amber for the second, and the second is drawn *from the first's tip*, not from the origin. Moving it there costs nothing, because you learned in the last hall that a vector has no address. The green arrow that closes the walk is the sum.

That is the whole of addition. Not a count. A walk: go a, then go b, and a plus b is where you are standing.

<!-- @vector_addition_walk -->

Now step into it. Three metres of grid, half a metre to a line, and the endpoints at body height where you can take hold of them. Walk the first arrow. Walk the second from where the first left you. The parallelogram draws itself around you, and the resultant is the diagonal you would have taken if you had known where you were going.

<!-- @ -->

##### Subtraction is the gap

```gdscript
func difference(a: Vector3, b: Vector3) -> Vector3:
    var b_flipped := -b
    return a + b_flipped
```

<!-- @vector_sub -->

The same console, flipped. Set a and b, and watch what is drawn: a, then *minus* b head to tail, with a faint ghost of the original b left standing so you can see the flip happen. The result points from b's tip back to a's. That is what subtraction is, and read the code again to see what it is not: there is no second operation. a minus b is a plus the reverse of b, and the arrow you get is the arrow of the gap between them, the one that says how far, and which way, one thing is from another.

<!-- @ -->

##### A volume knob for a direction

```gdscript
func weight_of(mass: float) -> Vector3:
    return Vector3.DOWN * 9.8 * mass
```

<!-- @example_2_3_gravity_scaled_by_mass_vr -->

Three masses on a ladder, half a kilogram, one and a half, three, and over each a force arrow pointing at the floor. Every arrow points the same way. Only the lengths differ, and they differ in exactly the ratio of the masses, because a scalar multiplies a length and leaves the line alone.

A scalar cannot turn a vector. It can stretch it, shrink it, and, if it is negative, reverse it along the same line, and that is the whole of what a plain number can do to a direction. Gravity is the room's example because it is the one scalar you have been carrying since you arrived: nine point eight, times whatever you weigh, straight down.

<!-- @ -->

##### To dot is to agree

```gdscript
func agreement(a: Vector3, b: Vector3) -> float:
    return clampf(a.normalized().dot(b.normalized()), -1.0, 1.0)
```

<!-- @dot_aligner -->

A turret on a pedestal, and a cube drifting past it. The gold arrow is where the turret aims; the cyan arrow is the direction to the cube. Swivel until they agree, and watch the charge: it is one number, the dot of the two directions, and it climbs from nothing as the angle closes. At an agreement of 0.985, which is within ten degrees, the beam locks and the cube turns from red to green.

That number is the cosine of the angle between them, once both lengths have been divided out. One float stands in for a whole angle: one is the same direction, zero is square on, minus one is opposed. The dot product was never an angle. It is what an angle *costs*.

```gdscript
func angle_between(a: Vector3, b: Vector3) -> float:
    return rad_to_deg(acos(agreement(a, b)))
```

<!-- @vector_dot_product_xl -->

Five metres square, and the two arrows share an origin you can stand at. Take hold of either and swing it; the readout above you gives the dot and the angle side by side, so you can watch one fall as the other opens. Stretch the second with the slider and the dot grows while the angle does not move. The hinge between them is the angle made into a thing you can push.

<!-- @ -->

##### The part of you that lives on someone else's line

```gdscript
func project(a: Vector3, onto: Vector3) -> Vector3:
    var n := onto.normalized()
    return n * a.dot(n)
```

<!-- @projection_shadow -->

A sun overhead, a rail on the floor, and an object floating off to one side of it. Its shadow lands on the rail, and the distance of that shadow from the origin is the dot of the object's position with the rail's direction. Multiply that number back along the rail and you have the projection: the part of the object that lives on the rail's line.

```gdscript
func reject(a: Vector3, onto: Vector3) -> Vector3:
    return a - project(a, onto)
```

The perpendicular drop from the object to its shadow is the rest. Every vector splits this way, into a part along another and a part square to it, and the two parts add back to the original exactly.

<!-- @vector_projection_reflection_xl -->

Walk into it. A vector arrives at a glowing plane and comes apart against it: the projection lying in the plane, the reflection leaving it. Take hold of the plane's normal and tilt it, and both halves recompute as you turn. This is the operation a mirror performs, and a floor, and every surface a thing has ever bounced off.

<!-- @ -->

##### To cross is to turn

```gdscript
func torque(arm: Vector3, force: Vector3) -> Vector3:
    return arm.cross(force)
```

<!-- @torque_crank -->

A lever arm on a flywheel's hub, and a push. The cross product of the arm and the push is a third arrow, gold, pointing up the axle, and the wheel turns about it. Its length is the two lengths times the sine of the angle between them, and read what that means with your hands: push straight along the arm and nothing happens at all. Push square across it and the wheel spins hardest. The cross product is the turn left over when two directions refuse to align.

You have used it before without being told. Two rooms into the first chapter, every face in the museum got its direction from two edges crossed at a corner. Here the same operation, with a push instead of an edge, is what makes anything turn.

<!-- @vector_cross_product_xl -->

Five metres square. Two arrows span a glowing parallelogram on the floor, and the purple arrow rises out of it, perpendicular to both. Swing either arrow and the parallelogram thins toward nothing as they line up, and the purple arrow shrinks with it. The paddle wheel spins by the right-hand rule, and the readout confirms what you can see: the product is square to both of its parents, always.

```gdscript
func wasted_half(arm: Vector3, force: Vector3) -> Vector3:
    var r := arm.normalized()
    return r * force.dot(r)
```

Now put the two products beside each other. What the projection keeps of a push, the part along the arm, is exactly what the cross product throws away, and what the cross product keeps is exactly what the projection discarded. Dot and cross are one question asked in opposite directions: how much do these two agree, and how much do they refuse to.

<!-- @ -->

##### Out of reach

<!-- @vector_addition_xl_laser -->

<!-- @vector_subtraction_xl_laser -->

At the far end, addition and subtraction once more, built so large that the tips are past your arm. Point a hand's laser at an endpoint, hold, and sweep, and the sum and the difference redraw at a scale no hand could hold. The room has now shown you each operation three ways: in your hand, around your body, and beyond your reach, which is the size most of them come at.

<!-- @ -->

##### Three verbs

To add is to walk. To dot is to agree. To cross is to turn.

That is the act, and it is a definition no page could give you, because each verb was something your body did before it was something you knew. Nothing here was a symbol. Every operation was a thing one vector did to another, and you were the thing doing it.

Before these operations spread into fields, the next room uses them to separate a launch velocity into components and compare the resulting arcs.

### 037. VFM 05 Launch

[Live text](http://localhost:3003/compose?map=VFM_05_Launch)

#### The curve after the launch

Does aiming higher always send something farther?

<!-- @launch_arc -->

Move the ANGLE control slowly. Follow the arc from its starting arrow to the landing mark, then compare how the highest point changes. Before moving the control again, predict whether the next, steeper arc will land nearer or farther away.

Keep going until your prediction has to change. A higher arc can land nearer in horizontal distance. Now look for two angles with similar landing positions: one shallow, one steep. Their destinations can agree while their routes disagree.

Make the landing mark your reference for a second comparison. Choose a shallow arc and remember where it ends relative to the track. Increase the angle until a steeper arc ends near that place again. Compare the space above the track that each curve occupies, following the whole outline rather than only its highest point. If your imagined obstruction stood near the start instead of halfway along, would the same choice still work? Explain your answer by pointing to the relevant part of the curve. A shared endpoint has left the intervening positions available for different uses, even before you add another force.

The launch begins with the vector arithmetic of the previous room. One velocity has an upward component and a horizontal component. Turning the launch direction towards the vertical gives more of the same initial speed to height and less to horizontal travel. Gravity then changes the vertical velocity throughout the flight. The initial arrow is straight; the trajectory records what happens after that first condition meets the continuing influence of gravity.

These traced positions show a calculation. They let you compare possible flights without requiring a projectile to cross the museum each time. The model keeps launch speed fixed while you change angle, and assumes that the landing is at the same height as the launch. Air resistance and obstacles have no part in this particular answer.

Imagine a low archway between the launch and the landing. Which of your two routes would you choose? Now imagine a low wall instead. The longest range is not always the useful flight. A question about reaching a place becomes more interesting when the journey itself has conditions.

<!-- @ -->

In the next room, motion continues to accumulate under forces that can change its course or prevent it from beginning. Keep the distinction between the initial condition and what acts afterwards.

### 038. VFM 03 Motion

[Live text](http://localhost:3003/compose?map=VFM_03_Motion)

#### The moment it starts

How can a small adjustment make a still object begin to move?

<!-- @friction_ramp -->

Choose an angle on the ramp and leave it there. Move the control marked μ until the block changes between STATIC and SLIDING. Watch the block, its arrows and the readout together. Then keep μ fixed and change ANGLE. Can you approach the same boundary from another direction?

Use RESET to compare runs from the same starting place. Just before the block moves, it is tempting to say that nothing is happening. The arrows offer another account: influences are present, but their balance does not yet produce motion along the ramp.

At a setting that clearly slides, use RESET and follow the block from its starting position. Watch whether it covers comparable distances during successive, equally counted intervals. Repeat after increasing the resistance a little, keeping the angle unchanged and resetting first. You need not obtain an exact speed to distinguish moving steadily from gaining speed. Describe separately whether the block starts, how its motion develops, and when the demonstration returns it to the beginning. The return is part of presenting another run; it is not a physical reversal caused by friction. Keeping these events distinct will make your comparison easier to explain alone.

Gravity has a component pulling down the slope and a component pressing into its surface. The surface supports the block, and friction can resist the downhill pull. Here μ sets the strength of that resistance relative to the normal force. Increasing the slope changes both components. The block starts sliding when the downhill part exceeds the friction bound.

Once it moves, acceleration changes velocity and velocity changes position. A small difference between the forces keeps adding up. The changing speed is therefore part of the observation: the block does not simply switch from one place to another.

This is a deliberately simplified contact model. It uses one friction coefficient and one transition rule; actual surfaces can distinguish the threshold for starting from the resistance during sliding. A still block also does not prove that no force acts on it. Stillness may be the visible consequence of several forces answering one another.

Try finding the shallowest incline that slides at your chosen μ. Another visitor can look for the largest μ that slides at that same incline. You are investigating one boundary through two different choices of what to hold constant.

<!-- @ -->

Vectors, fields and motion follow. Carry forward this habit: identify what is changing, what is accumulating, and which influences the model includes.

### 039. Vectors Act3 FieldsAndMotion

[Live text](http://localhost:3003/compose?map=Vectors_Act3_FieldsAndMotion)

Everything you have done to a vector so far, it held still for.

You walked it, flipped it, stretched it, asked two of them how much they agreed, crossed them and got a turn. Through all of it the arrow waited to be operated on. This hall is where it stops waiting, and it stops in two ways, so the hall is in two halves. In the first, there is an arrow at every point, and the room decides where you drift. In the second, there is one arrow, and the world keeps editing it.

##### Everywhere at once

```gdscript
func field_at(p: Vector3) -> Vector3:
    var swirl := Vector3(-p.z, 0.0, p.x) * SWIRL_GAIN
    var radial := p * RADIAL_GAIN
    return (swirl - radial).limit_length(2.5)
```

<!-- @VectorFieldFlow -->

A console, and on it a floor of small arrows. Read the function that makes them: two terms, one that circles the origin and one that runs at it, subtracted. Nothing is stored. There is no list of arrows anywhere; the field is a *rule*, evaluated wherever anything asks, and the arrows you see are only the places where somebody asked. Between them the field is just as real and just as unseen.

```gdscript
func advect(pos: Vector3, vel: Vector3, delta: float) -> Array:
    var sample := field_at(pos)
    vel = vel.lerp(sample, 0.08) * 0.98
    return [pos + vel * delta, vel]
```

Watch a particle. It has no memory and no plan. It reads the arrow under its feet, leans toward it, and moves, and that is the whole of its intelligence. A field is force that has decided to be everywhere at once, and a thing inside a field does not need to know anything except where it is.

<!-- @weather_vector_field -->

Now step into one. Five metres square, a hundred and forty-four arrows on the floor, and two wind vectors at body height that you can take hold of. Pull them. They add the way you learned to add in the last hall, head to tail, and the sum is the weather.

```gdscript
func drive_storm(a: Vector3, b: Vector3) -> void:
    var sum := a + b
    _rain_material.gravity = rain_acceleration(sum, gravity_strength)
    _windsock.rotation.y = atan2(sum.x, sum.z)
    _anemometer_speed = sum.length()
```

Everything in the chamber answers to that one sum. The rain slants at it, and the slant is not decided by anyone: it is the ratio of the wind across to the gravity down, and equal amounts give exactly forty-five degrees. The windsock turns to its heading and stretches with its strength. The anemometer spins at its speed. The debris streaks downwind. None of those instruments measures the storm. Each is one projection of the storm's single vector into whatever that instrument can show, a yaw, a length, a slant, which is the last hall's projection again, with weather for the rail.

It is calm when you arrive. The weather is yours to make, and it is made by addition.

<!-- @ -->

##### Edited over time

```gdscript
func _physics_process(_delta: float) -> void:
    ball.apply_central_force(acceleration * ball.mass)
    var velocity := ball.linear_velocity
    var position := ball.global_position
    _aim(velocity_arrow, velocity)
    _aim(position_arrow, position)
```

<!-- @VectorMotion -->

One ball, three arrows. Green from the origin to the ball: where it is. Cyan at the ball: where it is going. Orange, and this is the one you can take hold of: how its going is changing. Only the orange one is driven. Velocity is its running sum and position is velocity's, so the other two arrows are read back off the ball rather than set, and the fading trail behind it is the running sum of the running sum, drawn.

Grab the orange arrow and hold it still and the trail becomes a parabola. Position, velocity and acceleration are not three things. They are one quantity seen at three depths of change, and the ball is where all three depths are visible at once.

<!-- @launch_arc -->

Set an angle and a power and fire. You only ever launch a straight vector.

```gdscript
func launch_components(v0: float, theta: float) -> Vector2:
    return Vector2(v0 * cos(theta), v0 * sin(theta))
```

The launch splits into two parts the moment it leaves the pad: a sideways part that carries and never changes, and an upward part that fights gravity and loses. The angle is the whole negotiation between them.

```gdscript
func height_at(vy: float, t: float, gravity: float = 9.8) -> float:
    return vy * t - 0.5 * gravity * t * t
```

The curve is not yours. It is the world's answer to your straight line, and it costs exactly one squared term. Where the two parts are equal, at forty-five degrees, neither is wasted on the other and the range is greatest; thirty and sixty land in the same place, one high and slow, one low and fast. Aim straight up and the range is nothing and all the power goes into height. The pad knows all of this and marks the apex and the landing for you before the arc is flown.

<!-- @bubble_blaster -->

And a gun that wears its velocity on the outside. Pull the trigger and bubbles pour out; on the muzzle, an arrow shows the speed they leave with, and a faint cone shows how they spread. Crank the output and the arrow stretches, the cone widens, and the bubbles fly faster and further.

This is where the two halves of the hall meet. One bubble leaving the muzzle is motion, a vector the world will edit, and gravity begins editing it at once. A stream of them is a field, a velocity assigned to every point of the cone. Every emitter is a little field, and every particle in it is a little motion, and the difference between the halves was only ever whether you were looking at one arrow or all of them.

<!-- @ -->

##### Spread over space, spread over time

A field is force spread over space. Motion is force spread over time. Both are vectors that refuse to hold still, and you have now stood inside one and thrown the other.

What has not happened yet is a name. The storm pushed you and the pad threw you and gravity bent the arc, and none of them was called anything but a vector. The next act names them: the forces doing the spreading, met at the size of your body.

### 040. Vectors Act4a KineticForces

[Live text](http://localhost:3003/compose?map=Vectors_Act4a_KineticForces)

In the last hall the arrow was pushed and bent and thrown, and nothing doing the pushing had a name. This is a park, thirty metres a side, and every machine in it is a force with its name on it. Work, drag, launch, turn, fall. Each one is a force bending a path, and each is built at the size of your body so that it is a place you walk into rather than a line you read.

Walk it south to north. The room's own beats are on the floor, one per force.

##### Work

```gdscript
func work_done(force: Vector3, displacement: Vector3) -> float:
    return force.dot(displacement)
```

<!-- @force_mower -->

A lawn mower with a handle at an angle, and a push arrow living on the handle. Push it. The arrow splits at once into two, the part along the ground and the part driven down into the dirt, and only the first of them moves the mower. Raise the handle and watch the along-part shrink and the down-part grow while the push itself stays the same length.

That is work, and it is the dot product with its costume off. The world only feels the part of a force that goes its way. Push square to the motion and the work is zero, however hard you push, however long.

```gdscript
func push_split(magnitude: float, theta: float) -> Array[Vector3]:
    var along := Vector3(magnitude * cos(theta), 0.0, 0.0)
    var into_ground := Vector3(0.0, -magnitude * sin(theta), 0.0)
    return [along, into_ground]
```

<!-- @sisyphus_mower -->

And here it is forever: a mower pushed up a striped hill by hands that are not there, handle at thirty-two degrees, sixty newtons a shove, and a ledger counting the joules that bank. Only the cosine of every shove goes into the hill. The rest goes into the dirt, and gravity spends what was banked on the way back down. Effort is conserved. Usefulness is not. One must imagine the mower happy.

<!-- @ -->

##### Drag

```gdscript
func drag_step(velocity: Vector3, b: float, delta: float) -> Vector3:
    return velocity * (1.0 - clampf(b * delta, 0.0, 0.6))
```

<!-- @drag_corridor -->

Three zones, three metres each: air, then water, then honey. Walk them and feel your own pace taxed more in each. In every zone a dart is launched at the same speed and glides and dies, its velocity arrow shrinking as it goes, and the same launch that crosses the air zone barely lunges in the honey.

Drag is the world charging you rent on speed. It is proportional to how fast you go and it points against you, so it can slow you to nothing and can never turn you round, because the moment you stop there is nothing left to charge.

```gdscript
func distance_under_drag(v0: float, b: float, t: float) -> float:
    return (v0 / b) * (1.0 - exp(-b * t))
```

Read what that means for how far you get. Coast as long as you like, and the distance approaches a number and stops: your launch speed divided by the medium's rate. In honey that number is close. In air it is far. It is never infinite. A thing that pays rent on its speed has a finite reach, however long it is allowed to travel.

<!-- @ -->

##### Launch

<!-- @force_pad -->

A glowing square on the floor, one metre a side, with chevrons pointing the way it will send you. Step on it. It hands you a velocity, six metres a second forward and seven up, and then it has nothing more to do with you: gravity writes the rest, and the rest is an arc.

You met the arc in the last hall as a thing you aimed. Here you are the thing launched. A launch is a velocity you are given, and everything after it is the world's answer, one squared term long. The pad cannot give you a curve. Nothing can. It can only give you a straight line and let gravity bend it.

<!-- @ -->

##### Turn

```gdscript
func centripetal(speed: float, radius: float, angle: float) -> Vector3:
    var pos := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
    return -pos.normalized() * (speed * speed / radius)
```

<!-- @centrifuge_ring -->

A pod laps a neon ring three and a half metres across, and two arrows ride it. The velocity is always tangent, along the ring, the way the pod is going. The force is always toward the centre, square to the velocity, and because it is square it never changes the speed, only the direction, which is what going in a circle is: a constant acceleration toward a centre you never reach.

Crank the speed and watch the inward arrow. It grows as the square. Double the speed and the pull quadruples. That is why fast turns throw you, and it is the whole of what a turn costs.

<!-- @prop_carousel -->

A fairground carousel of museum props hung on chains, turning under a canopy. Look at the chains. They lean outward, and every child who has ridden one knows it as being flung out. The chains lean out because they have to pull *in*: the angle of every chain is exactly what it takes to supply the inward pull the prop needs to keep circling, and nothing anywhere pulls outward. The outward feeling is your body wanting to go straight, and the chain refusing.

<!-- @ -->

##### Fall

```gdscript
func barycenter_offsets(m1: float, m2: float, separation: float) -> Vector2:
    var total := m1 + m2
    return Vector2(separation * m2 / total, separation * m1 / total)
```

<!-- @orbit_walk -->

Stand at the centre. A heavy star and a lighter planet wheel around you on opposite sides, three and a half metres apart, and on each of them rides a red arrow of exactly the same length pointing at the other. One force, handed out in two opposite directions, stronger as the square of the distance closes.

The point you are standing on belongs to neither of them. It sits where the heavy mass times its distance equals the light mass times its distance, closer to the heavy one, and make one heavier and it slides toward that one while both orbits resize to keep the trade. An orbit is two things falling toward each other and missing, forever, around a centre that neither of them is at.

```gdscript
func slides(theta: float, mu: float) -> bool:
    var down_slope := sin(theta)
    var friction := minf(mu * cos(theta), down_slope)
    return down_slope - friction > 0.0
```

<!-- @wedge_slide -->

At the far end, the smallest fall there is. A block on a wedge, a slider for the angle, and the textbook triangle drawn live beside it: weight, normal, friction, and what is left. A slope does not change gravity. It changes how much of gravity points along the way out, which is the projection of one downward arrow against a ramp, and friction can match that part but never exceed it. So the angle decides, and the weight cancels out of the deciding: at this block's friction the hill holds at fifteen degrees and gives at sixteen, and it would do the same for a block ten times the mass.

<!-- @ -->

##### What edits motion

Work, drag, launch, turn, fall. Every one of them is a force bending a path, and every one was met on foot. That is the act's whole claim, and it is worth saying in the plainest words the sequence has: forces are what edit motion. Position is where you are, velocity is where you are going, and a force is the thing with the pen.

The next half of the act holds the forces that give the path back: the ones that pull toward a rest and overshoot, and keep time by doing it.

### 041. Vectors Act4b Oscillation

[Live text](http://localhost:3003/compose?map=Vectors_Act4b_Oscillation)

The last hall's forces bent a path and let it go. These give it back.

A hall of clocks and balances. Every force in it pulls toward a rest and overshoots, or holds a beam level, or hands a motion on without losing any of it, and the reason they keep time is one sign in one line of code. Walk it south to north, the way the room's own beats run.

```gdscript
func restoring_force(displacement: float, k: float) -> float:
    return -k * displacement
```

The minus sign is the entire law. Take a thing from where it rests and the force points *back*, in exact proportion to how far you took it. Everything in this hall that keeps a rhythm keeps it because of that sign.

##### Momentum

```gdscript
func total_momentum(masses: Array[float], velocities: Array[Vector3]) -> Vector3:
    var total := Vector3.ZERO
    for i in masses.size():
        total += masses[i] * velocities[i]
    return total
```

<!-- @momentum_cradle -->

Five steel balls on strings. Lift the end one and let it go. The blow travels through the three in the middle, which do not move, and kicks the far ball out to the same height the first one fell from. One in, one out. Sum mass times velocity before and after and the number has not changed; the middle of the cradle is where the momentum is owed but not spent. Motion refuses to be destroyed. It can only be handed on.

<!-- @ -->

##### Restitution

```gdscript
func apex_after(bounces: int, drop_height: float, e: float) -> float:
    return drop_height * pow(e, bounces)
```

<!-- @bounce_well -->

A ball dropped into a well, frozen stroboscopically, so that every arc stands beside the last. Each rises to a fixed fraction of the one before it. Set the fraction with the slider: at one the ball never stops, at zero it lands with a dead thud, and everything between is a geometric series. Every bounce is a tax on a fall.

And here is the thing about a geometric series that the well lets you watch: there are infinitely many bounces, and they take a finite time. The four-hundredth adds nothing you could measure. The ball is still, and it got there through an infinity of ever-smaller arrivals, which the portal room said the finite could not do, and which it does here by shrinking faster than it repeats.

<!-- @ -->

##### Lever

```gdscript
func balances(f_left: float, d_left: float, f_right: float, d_right: float) -> bool:
    return absf(f_right * d_right - f_left * d_left) < 0.06
```

<!-- @lever_balance -->

A beam on a fulcrum and a slider that moves the right-hand weight along the arm. It does not change the weight. It changes the *torque*, force times distance, and the beam tips toward the bigger product and sits level only when the two agree. A small load far out holds a big one near in. That is the same trade the orbit made in the last hall, with weight for mass and arm for radius, and the room says it plainly: a lever trades force for distance and never gets something for nothing.

```gdscript
func place_pivot(arm: float, w_left: float, w_right: float) -> Vector2:
    var total := w_left + w_right
    return Vector2(arm * w_right / total, arm * w_left / total)
```

<!-- @calder_mobile -->

Calder's mobile, and it is actually balanced. Every rod obeys the lever law: its two children are weighed, the pivot is placed so the heavier rides the shorter arm, and the whole thing hangs level from one point at the ceiling. Read the function: weigh both subtrees before you cut the rod, then recurse. The drift you are watching is not decoration. Every arm is answered by a real weight, and the mobile is the lever law four levels deep, moving.

<!-- @calder_object_mobile -->

The same law, hung with the museum's own objects: a point, a sphere, a pyramid, an arch, each with a plausible mass, drifting in equilibrium. The first chapter's shapes, balanced by the fifth chapter's rule. The foundational things do not float here. They are weighed.

<!-- @ -->

##### Wind

```gdscript
func wind_drag(speed: float, rho: float, c_d: float, area: float) -> float:
    return 0.5 * rho * speed * speed * c_d * area
```

<!-- @weather_vane -->

A vane, a flag, and a slider for the wind. The vane swings to point downwind, the flag streams, and the drag arrow grows, and watch how it grows: with the square of the speed. Double the wind and the push quadruples, and the flag goes from a lazy ripple to horizontal. This is not the linear rent of the drag corridor. Squared, the force stops being polite, and it is a force you can only see in the bend of what it pushes.

<!-- @example_6_4_windmill_vr -->

The older windmill beside it is the demonstration the vane replaced, kept because it turns.

<!-- @ -->

##### Pendulum

```gdscript
func swing(t: float, amplitude: float, arm_length: float) -> float:
    var omega := sqrt(9.8 / arm_length)
    return amplitude * cos(t * omega)
```

<!-- @pendulum_hall -->

A real pendulum, four and a half metres of string from a six-metre gantry, swinging at its true period, a little over four seconds, with a glowing arc on the floor recording the sweep. Look at what is in the period and what is not. The length is in it. Gravity is in it. The mass is not: a heavy bob and a light one on the same string keep the same time, and the amplitude is not either, which is why a pendulum can be a clock.

```gdscript
func restoring_torque(theta: float, mass: float = 1.0) -> float:
    return -mass * 9.8 * sin(theta)
```

Except that it is only honest for small swings. The true pull back is mg sin θ, not mg θ, and the pendulum is a spring only while those two are close. At this hall's swing of twenty-four degrees they differ by three percent. Pull it far enough and the period stops being a constant. The clock keeps time on the condition that you do not push it too hard, which is a condition every clock has.

<!-- @ -->

##### Spring

```gdscript
func spring_period(mass: float, k: float) -> float:
    var omega := sqrt(k / mass)
    return TAU / omega
```

<!-- @spring_tower -->

A heavy mass bobbing on a giant coil, and a slider for the stiffness. Stiffen it and two things happen at once: it gives less, and it ticks faster. The period has the mass in it and the stiffness in it and nothing else. A spring is honest; it returns exactly what it is given, and a big bounce and a small one take the same time, which is the second reason a thing can be a clock.

<!-- @ -->

##### The bench

Along the north wall, thirteen more, folded in from a room that used to stand between this hall and the last. They are the same sign at every scale and in every costume, and they are worth a walk.

<!-- @mass_spring_damper -->

The canonical second-order system: a mass, a spring, and a damper that charges rent on speed the way the corridor did. Stiffness pulls back, damping bleeds energy, and between them every vibration that has ever been engineered: the ring that dies away, the door that closes without slamming, the suspension that neither bounces nor jars. Underdamped, critical, overdamped, and the third is the one every engineer is paid to find.

<!-- @coupled_pendulums -->

Two pendulums joined by a spring. Start one and watch the energy cross to the other and come back, sloshing between them at a beat you can count. This is resonance in its smallest form, and everything from a tuning fork to a bridge that shook itself down is this with more parts.

<!-- @spring_system -->

Twenty masses in a chain. A complex vibration is not complex. It is a sum of simple ones, each with its own frequency, and when two of them nearly agree the energy beats between them. That decomposition is the whole of how a sound is analysed, and it is two chapters away.

<!-- @slingshot_pull -->

Draw the pouch back and the band stores energy as the square of the pull: twice as far, four times as much. Release, and the stored square becomes launch speed. This is the spring's law read as a bank account, and it is the one machine in this hall that hands its rhythm to the last hall's arc.

<!-- @vector_joint_playground -->

Six stations of joints, each paired with a vector you can drag: a crane, pistons, a door, a seesaw, a waterwheel, a spring tower. A joint is a subtraction: it takes degrees of freedom away from a thing until only the motion you wanted is left, a hinge leaving one turn, a slider leaving one slide, a cone leaving a wobble inside a limit. The swings and the crank and the press beside it are each one such subtraction made large.

<!-- @surreal_kinetic_sculpture -->

And one that is not a lesson. Gears drive pendulums that scatter particles through fields while banners ripple in a simulated wind, every system in the chapter woven into one perpetually moving thing. It is here as a celebration, and it is allowed to be.

<!-- @ -->

##### These keep a rhythm

Spring, pendulum, cradle, bounce, lever and wind do not repeat or balance for one shared reason. An ideal spring supplies a restoring force proportional to displacement; a pendulum approximates that relation at small angles. Collisions, static balance and wind need their own accounts.

The next room follows gravity through orbits. Keep the direction of the force distinct from the body's continuing motion.

### 042. VFM 07 Gravity

[Live text](http://localhost:3003/compose?map=VFM_07_Gravity)

Attraction at a distance, and then what happens when more than two things believe in it.

This is a bench, not a walk: two plinth rows in a south gallery and a north row of larger machines, every one of them the same law. You met the law in the park as one machine among five. Here it is on its own, and the room takes it from two bodies to three, which is where the arithmetic stops being able to tell you the future.

##### The law

```gdscript
func attract(a: Body, b: Body, G: float) -> Vector3:
    var arm := a.position - b.position
    var d := clamp(arm.length(), 1.0, 25.0)
    var strength := G * a.mass * b.mass / (d * d)
    return arm.normalized() * strength
```

<!-- @exercise_1_8_solution_attraction_magnitude_vr -->

A ball orbits a mass you can take hold of. Drag the mass and the orbit reshapes under your hand. The force runs along the line between them, and its strength is the product of the two masses divided by the distance *squared*. Read what the square costs: double the distance and you keep a quarter of the pull. Double it again and you keep a sixteenth. Closer means stronger, and not politely.

<!-- @example_2_8_two_body_attraction_vr -->

Two bodies, and the clamp in the code is worth a look. Without it a close encounter divides by nearly nothing and the numbers explode. That is not a fault in the law. It is the law taken further than a simulation can follow, and the clamp is honest engineering: it says where the machine stops trusting itself.

<!-- @ -->

##### Falling and missing

```gdscript
#### a stable orbit: sideways velocity exactly countering the fall
body.velocity = tangent * sqrt(G * central_mass / radius)
```

<!-- @orbit_pair -->

Two bodies orbiting a point that belongs to neither, the barycenter, each pulled toward the other by an arrow of exactly the same length. You stood on that point in the park. Here you can watch the trick of every moon from outside: it falls forever and forever misses, because its sideways speed exactly counters the fall, and there is one speed at every distance that does that.

<!-- @orbital_mechanics_demo -->

Launch a satellite and set that sideways speed yourself. Too slow and it spirals in. Too fast and it leaves and does not come back. The orbit that never returns has a number, and it is not far above the circular one: the square root of two times it. Go by increments and you will find it. Between the two, every ellipse Kepler drew, and beyond it, the hyperbola that is a visit rather than a stay.

<!-- @ -->

##### Three

```gdscript
for i in bodies.size():
    for j in bodies.size():
        if i != j:
            bodies[i].acceleration += attract_accel(bodies[j], bodies[i])
```

Every body attracts every body. With two, the futures are circles and ellipses, and a formula will tell you where either body is at any time you name.

<!-- @three_body_problem -->

With three, stand at the three-body problem and watch prediction die.

There is no formula for where three bodies will be. There is a series, a century old, that converges so slowly it is useless for anything, and so in practice there is only simulation: step the law forward and see. And here is the part the machine can prove to you. Nudge one body by a millionth of a metre and run both versions. With two bodies the difference stays a few millionths. With three it grows to metres, half a million times as far, and then the two futures have nothing to do with each other. Same law, same code. Restart it three times and find what was different: the initial conditions are the third body's secret.

Two famous exceptions stand in this station's settings, the figure-eight and the Lagrange triangle, orbits so balanced that three bodies do repeat. They are exceptions, and they were found by searching, not by solving.

<!-- @chaos_attractor -->

The shape of that unpredictability, drawn. This is a different system, the one Lorenz found in the weather, but it has the same property, and eight thousand points of it trace the butterfly: a path that never repeats and never leaves. Chaos is not randomness. It is a law followed exactly, by a future that cannot be known in advance.

<!-- @ -->

##### Many

<!-- @example_2_9_n_body_attraction_vr -->

More than three, and the law does not change; only the count does. Every body pulls on every other, which is a pair of forces for every pair of bodies.

<!-- @nbody_simulation -->

Twenty bodies from a cloud, and watch what the law does with them: a disc forms, a binary pair, a cluster that scatters. Nothing organises them. The pairwise pull does, and the cost of computing it is the number of pairs, which grows as the square of the count. That square is the bottleneck that drove astronomers to invent the tree methods that made galaxies simulable, and it is the same square as the law's own. Gravity is expensive in exactly the way it is strong.

<!-- @ -->

##### The well

```gdscript
func well_depth(pos: Vector3, center: Vector3) -> float:
    return -G_well / max((pos - center).length(), 0.5)
```

<!-- @gravity_well -->

The rubber sheet, made real. A grid warps around a mass you can move, and coloured particles roll along the curve: orbiting, spiralling in, escaping, depending on how fast they arrive. The depth is not decoration. It is the energy a thing would need to climb out, drawn as geometry, and deeper always means closer in. This is the picture everyone reaches for when they explain gravity, and it is worth knowing that it is a picture of a *potential*, not of a force: the slope is the force, and the height is what the slope has cost you.

<!-- @ -->

##### Gravity's office job

```gdscript
#### force-directed layout: edges are springs, nodes repel like masses
for pair in node_pairs:
    apply(repulsion(pair))   # gravity's mirror
for edge in edges:
    apply(spring(edge))      # last room's force law
```

<!-- @forcedirected3d -->

A graph laying itself out. Every node repels every other by the inverse square, gravity's mirror, and every edge is a spring from the last hall pulling connected nodes together. Nobody arranges it. The two forces argue until they agree, and the arrangement is the equilibrium: the picture of the graph that costs the least.

<!-- @grid3d_force_directed -->

The same, on a grid, watching it settle. This is the sequence eating its own tail: attraction and springs, repurposed from physics into layout, so that a diagram can find its own shape. Graph theory is eleven chapters ahead, and it starts here, in a room about planets.

<!-- @ -->

##### What three bodies cost

Two bodies and a formula. Three bodies and a simulation, which is the machine inventing the between, one step at a time, with no formula to check it against, because there is none. That is a strange place for a physics room to end, and it is the honest one: the law is exact, the future is not, and the difference between them is the number of things that believe in it.

The next bench takes one law you know, legs, and asks what a gait is once you know how many feet are on the ground.

### 043. VFM 09 Legs

[Live text](http://localhost:3003/compose?map=VFM_09_Legs)

Count the legs, and the walk follows: not as a style, but as arithmetic.

Seven walkers stand in one row on the floor, one leg to eight, and nothing about them is on a plinth, because a thing that paces wants the ground. Every one of them is the same build: a small box body a hand above the floor, and long arching legs, taller than you are at the knee, reaching out to feet more than two metres from the centre. Every one glides at the same slow pace, turns when it likes, and turns for home when it has strayed a metre and a half. The only thing that changes from bay to bay is the count. That is the experiment.

##### The rule

```gdscript
#### a body is statically stable while its centre of mass sits inside the
#### polygon formed by the feet that are currently planted
func can_lift(planted: Array[Vector3], com: Vector3) -> bool:
    if planted.size() < 3:
        return false          # two points make a line, and a line is a fall
    return _inside_polygon(planted, com)
```

Read it once and carry it down the row. Fewer than three feet on the ground is a fall. Three or more, and the body stands only while its centre is inside the shape they make. Nothing else is needed. Now the count decides.

##### The row

<!-- @one_leg -->

One leg, and no step at all. A step needs another foot to stand on while this one is in the air, and there is no other. So the one foot does the only thing the rule leaves it: it stays down, and it is dragged along the floor beside the body as the body glides, swinging round when the body turns. The honest gait for one leg is a hop, and a hop needs the whole body to leave the ground. Nothing in this row leaves the ground.

<!-- @two_leg_critter -->

Two legs, and here is the rule that the next four walkers all share, so learn it once. A foot stays planted where it landed while the body glides on. When it has been left a metre and a half behind its shoulder, it steps: a quarter of a second, a metre high, landing a little ahead. One foot in the air at a time, never two, and always the foot that has been left furthest behind. With two legs, one foot up leaves one foot down. A single point is not a shape. By the rule, every step is a fall.

<!-- @three_leg_critter -->

Three legs, and one foot up leaves two, which is a line, which is a fall. Three is the smallest number that stands still by the rule, and the first number that cannot take a step by it. Watch the burst: after a turn the three feet find themselves stretched together, and they step one after another, a quarter of a second each, and then all three are down for a long while as the body slides on bent legs.

<!-- @four_leg_critter -->

Four legs, and now the rule gets interesting. One foot up leaves three, a triangle, and a triangle is a shape. But look where the centre sits: on the diagonal of the square the feet make, which is exactly the edge of the triangle that remains. On the line, and a line is a fall. A four-legged animal steps by leaning first, a hand's width off the diagonal, and then lifting. This one never leans. Its body is held level and slid forward, and its feet catch up.

<!-- @five_leg_critter -->

Five legs at equal angles, and the rule starts to pass. One foot up leaves four, and the centre is well inside. Five is also where a pattern appears that no even walker has: lift any two feet that are apart, and the animal stands; lift any two that are neighbours, and it falls. Five pairs pass, five fail, and no mirror maps the passing set onto itself.

<!-- @six_leg_critter -->

Six legs, and one foot up leaves five. The rule is satisfied with room to spare, and the same is true of any way of lifting three at once so long as they alternate: the other three make a triangle round the centre. This walker takes the cautious road and lifts one.

<!-- @octapod_ik -->

Eight legs, and a different animal. It is about half the size of the others, faster on its feet, and it is the only one in the row that lifts a group: four feet at once, every other leg, so that the four still down make a square round the centre, and then the other four. Four on the ground at every instant. Of the seven, it is the only one whose stepping passes the rule while it moves.

<!-- @ -->

##### What the count buys

A gait is not a style. It is what is left once you know how many feet are on the ground and how many can be in the air at once.

Lay the row against the rule and it reads like a table. One cannot step. Two and three step and fall. Four steps and falls unless it leans, which it does not. Five and six step and stand. Eight lifts four and stands. None of them fall, because nothing in this hall is a body that gravity can catch: they are drawings of walkers, held at their height and slid along, and the rule on the wall is the exam gravity would set if it were here. Gravity was the last hall. Here it has been left outside, so that you can read the exam instead of watching it marked.

That is what a diagram is for. A fall you could only have felt; the reason for it you can see. Count the feet on the ground, subtract the ones in the air, and ask whether the centre is inside what is left. Everything a gait is comes out of that subtraction.

One teleport on, in the Arena, a small black crab on four long jointed legs is walking the only true plant-and-step gait in this museum, at a tenth of this size, and it is looking for you.

### 044. VFM 08 Arena

[Live text](http://localhost:3003/compose?map=VFM_08_Arena)

#### What the collision shares

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

### 045. Vectors Act5 ForceAsPlace

[Live text](http://localhost:3003/compose?map=Vectors_Act5_ForceAsPlace)

A hole in the floor, and two ways over it. One of them somebody built. The other one you have to set.

This is the last room of the forces field, and it asks one question you have to walk through: what is a floor *for*? Everything up to here drew vectors on things: on an arrow, on a thrown ball, on a limb. Here the vector is not on anything. It is on a volume of air, and whatever enters that air obeys it. A force has always been something a thing *has*; this room takes it away from the thing and gives it to the place.

##### No starting address

<!-- @free_vector -->

Four arrows on a small grid by the door, and they are all the same arrow. One is drawn in colour with its two facts beside it, a length and an angle. The other three stand somewhere else.

That is the whole of what a vector is, and this room spends five metres of cage on its consequences. A vector is two facts, a direction and a length. It has no third fact called *where*. Slide it across the floor and it has not changed, because there was never anything about it that knew where it was.

If a vector has no address, then attaching one to an object was always a convenience rather than a truth. And if it was only a convenience, you can attach it to something else. To a region, for instance.

##### The cage

```gdscript
#### force_field_zone.gd, the whole of the physics, both branches
rb.gravity_scale = 0.0                    # on entry, remembered
rb.linear_velocity += f * delta           # every tick, thereafter

pb.velocity += (f - pg) * delta           # you: your own gravity, subtracted
```

<!-- @force_field_zone -->

Five metres of nothing, marked by a wire cage and one arrow. Five is not a round number: the chasm is five rows deep, so the volume is exactly as wide as the gap it hangs over. Its floor is the floor you are standing on.

Those two lines are shorter than they should be, and the missing thing is mass. A force divided by a mass gives an acceleration; this skips the division and adds `f` to velocity directly. A heavy thing and a light thing move identically. Not because the code checks and compensates, but because it never asks. The field has no way to find out what you are and nowhere to put the answer if it did.

The book this field grew from, Daniel Shiffman's *The Nature of Code*, defines a force as a vector that causes an object *with mass* to accelerate, and then spends a section on the awkwardness. To make falling look right you multiply gravity by an object's mass so that dividing by the same mass cancels it again: two operations that exist to undo each other, and a generation of us have typed them.

This room does not cancel the mass. It never introduces it. That is the difference between reading the sentence and standing inside it.

Your own body arrives at the same rule by subtraction. Your legs are already adding gravity every frame, so the volume adds `f` minus the gravity you brought, and the two cancel exactly. Inside, the only force in the world is the one on the dial.

##### The dial

```gdscript
#### vector_machine.gd, three numbers into one direction
f = Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * mag
```

<!-- @vector_machine -->

Three sliders: how steep, which way round, how hard. Fourteen centimetres of travel each, and between them every direction there is, up to a ceiling of fifteen.

It ships pointing straight down at 9.8, which is gravity: the setting where this room looks exactly like every other room you have been in. That is the lesson before you touch anything. The ordinary world is not the absence of a setting. It is a setting. Somebody chose down.

Now watch what the steepness slider costs. At the bottom of its travel the field points straight down, `cos(pitch)` is zero, and the slider beside it does nothing at all. Run it through its whole range and the world will not move. Lift the field off the floor by even a little and the same slider becomes the most powerful control on the console.

That is not a fault, it is what a direction *is* when you name it with two angles. At the poles the second angle has nothing left to mean. So the console tells you: while the field is vertical the readout says the yaw is idle and at what bearing it is waiting, and a faint arrow on the stage holds that bearing where you can see it. The fader is not dead. It is aimed, and the field cannot hear it yet.

It is the oldest problem in spherical coordinates, and here it is at hand height, in metal, where you can feel it happen.

<!-- @ -->

##### The probe

```gdscript
#### force_cube.gd, the arrow is measured, not scripted
var v := (global_position - _last) / delta
_draw(v * 0.5)                            # clamped at 2.6 m
```

<!-- @force_cube -->

Three glass cubes, forty centimetres, each drawing its own motion out of its centre as a yellow arrow with three coloured legs and a readout.

Nothing tells the cube what the field is, and it has not been given the rule. It differences its own position against where it was last frame and draws the answer, so the arrow is not a prediction: it is the field, having already happened, to something that was in the way. That is the only honest way to read a field you cannot see: put something in it and watch.

These have weight, which is the point of throwing one. Let it go over the gap with the field pointing down and it drops. Aim the field up and across first and the same cube sails. The difference between those two throws is the whole claim of the room, and you can only make it with something that would otherwise have fallen.

A cube that goes into the hole comes back. It has to: there is no floor to catch it and no button to fetch it with, and a probe you can lose is a probe you stop throwing.

##### What the plank is for

<!-- @force_field -->

Two cells wide, straight across the gap, and it was not in the plan. The museum's walker cannot be carried by a field. Every carry volume in the building ignores it, in silence, so a hall built entirely around being carried arrived severed, its far half unreachable and every object in it stranded. Somebody laid a plank. It was the right call, and why you are standing here.

Stand on it and look down, then up at the cage hanging over the same hole, and the room has said its sentence without a word. There are two ways to make a place crossable. You can put matter under the walk: a floor, a bridge, nearly every building you have been inside. Or you can leave the hole and change what happens in the air above it.

The plank works for anyone, forever, and nobody has to know why. The field works only for whoever set it, only while it is set, and it can be set wrong. A floor is a decision somebody made once and then stopped thinking about. Falling is not a property of the hole; it is a property of the rule over the hole, and somebody chose the rule.

A place has an edge, and an edge is geometry rather than intent. If a force belonged to you, being near it would be enough.

##### The green

<!-- @invisible_hill -->

Off at the far end, a dark green disc four and three quarter metres across with a brass lip, over which glowing pucks glide in from the rim, bend hard away from a centre that has nothing in it, and leave.

No collider, nothing to touch. A diorama, placed where you can look at it from outside and see the shape of the thing you have been standing in. It answers the little grid of arrows at the other end: that one says a vector has no address, this one says what happens when you give an address a vector.

Nothing at that centre is doing the bending. No mass, no attractor, no object. The curve is the entire content, and it belongs to the region rather than to anything in it.

<!-- @ -->

##### Out

The way out returns to Act I, where a vector was an arrow you could take by the tip. It has not changed since. What changed is where you are willing to put one: on an object, then a motion, then a limb, and now a room-sized piece of empty air with you inside it.

The field is a circle. Go round again, and notice that the first arrow was always this.

## Form-Finding: Matter Solves for Its Own Shape

### 046. FormFinding Descent

[Live text](http://localhost:3003/compose?map=FormFinding_Descent)

Nothing places a form at the bottom. A body that can read only the slope under its own feet gets there anyway, and that is the whole chapter.

You arrive inside a hill. One of the exhibits in this room builds a twenty-metre landscape in a room fourteen metres wide, so the terrain swallows the walls, the way out and everything else standing here, and it has no collision at all: you walk through the hillside as though it were weather. Do that, and then find the small things inside it.

A marble in a bowl comes to rest at the bottom and nowhere else. Not because anything put it there, and not because it knows where the bottom is. It follows the slope down until the slope is zero, and where the slope is zero it stops. Every shape in the four halls after this one is found the same way, by something that cannot see the answer and can feel which way is down.

```gdscript
func _gradient_at(pos: Vector2) -> Vector2:
    var eps: float = gradient_sample_distance
    var gx: float = (_sample_height(pos.x + eps, pos.y) - _sample_height(pos.x - eps, pos.y)) / (2.0 * eps)
    var gz: float = (_sample_height(pos.x, pos.y + eps) - _sample_height(pos.x, pos.y - eps)) / (2.0 * eps)
    return Vector2(gx, gz)
```

Look at what that does. It does not know the surface. It takes two small steps either side of where it is, compares the two heights, and divides. The slope is measured, not known, and it is measured from nothing but the neighbourhood. On the bowl in this room, whose wall rises as the square of the distance from the centre, that measurement returns the true slope exactly.

##### The oldest optimiser

<!-- @descent_marble_toy -->

A bowl the width of two hands, twelve centimetres deep, with a marble rolling in it. You cannot tip it and you cannot touch it; it is a thing to watch, damped, going round for as long as you stand there. This is the chapter in one object, and it is worth staying at until it is boring. The marble is not solving anything. It has no picture of the bowl, no memory of where it has been and no idea that a bottom exists. It reads the tilt under itself and moves that way, and the tilt runs out at exactly one place.

<!-- @gradient_descent -->

This is the hill you are standing in. The same rule as the marble, on a landscape nobody smoothed: a gold sphere takes a step down the steepest way about five times a second, trailing a line behind it and an arrow ahead of it. Watch where it ends. It ends in whichever valley it happened to start above, which on a wrinkled surface is not the lowest valley and has nothing to do with the lowest valley. The rule that always works in a bowl is a rule that works locally, and a wrinkled world is where those two stop being the same sentence.

<!-- @gradient_descent_well -->

A glowing basin banded with contour lines, one deep well off to one side, two shallow dips, and three marbles let go on it. They do not do the same thing. The difference is momentum, which here is set to a little under nine tenths: a marble carrying that much memory of its own motion rolls through a shallow dip and out the other side, and a marble with less settles in the first dip it meets. Same landscape, same rule, and the only thing separating a good answer from a mediocre one is how much of its past each marble is still carrying.

That is the problem the last hall in this chapter is about, posed here on the first bench, four rooms early.

<!-- @settling_tremble -->

A wall chart, a hand's span across, with two curves drawn over each other and nothing moving on it. The amber one is the true catenary, the exact shape a hanging chain takes, where every link balances. The blue one is seventeen nodes of a solver that was trying to reach it, stopped at the moment the largest move in a pass fell below six thousandths of a metre. They do not lie on top of each other. The blue nodes sit scattered a hair off the amber line, and that scatter is the whole point: the solver never arrives, it gets inside a band and stops, and the band is a number somebody chose.

The chart does not animate. It is a photograph of the tremble rather than the tremble, which is the correct way to show something whose whole content is that it never settles. Settled means tired, not still. Keep that. Every shape in the next three halls is a shape that stopped moving because a tolerance said it could.

<!-- @science_screen -->

The screen sweeps eight metres around itself once a second, looking for something it can redraw as a flat diagram. It finds nothing. Not one of the four things in this room answers the questions it knows how to ask, so it stands there lit and empty, facing away from where you came in. A measuring instrument surrounded by four objects it cannot read is a fair enough emblem for a room about a rule that only ever looks at the ground directly under itself.

<!-- @ -->

##### Down is enough

The gradient is a local instrument. It has no opinion about the landscape, only about the ground beneath the object, and from that alone a form appears. That is the strange economy this chapter is about: nature does not compute a shape and then make it. It lets something fall, and the falling is the computation.

Three things in this room already complicate it, and all three come back. A marble finds the nearest bottom rather than the best one. A solver never actually finishes; it stops. And nothing here can be touched: five objects, not one collider between them, so the only thing you can do with a room about falling is watch other things fall.

Next: the two oldest of these problems, solved by matter itself, without a solver anywhere.

### 047. FormFinding Catenary

[Live text](http://localhost:3003/compose?map=FormFinding_Catenary)

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

##### The chain

<!-- @cable_builder -->

Four cyan beads at ankle height, and a four-metre cable glowing magenta into blue slung through them with its belly grazing the floor. The beads are the only thing in this room you can actually take hold of. Move one and the whole curve recomputes and re-skins in your hands, every frame.

Read it carefully, because it is the room's honest object. The cable is not a chain solving its own equation. It is a spline whose sag is two Bezier handles per span, each pulled down by a fixed fraction of that span's length, so the depth is drafted rather than found. It is a very good drawing of a catenary made by somebody who knew what one looks like, and the difference matters enormously here, because everything else in this room got its shape without anybody knowing in advance what the shape would be.

<!-- @laundry_line_cathedral -->

Three washing lines pegged with towels and shirts, and these are true `cosh` curves rather than good drawings. Only one of the three has a pole under either end; the other two simply begin and end in the air, which nothing in the room admits. Then look up. Above each line hangs its ghost: the same curve mirrored upward as a pale arch. That is Gaudí's trick, and it is the reason this is the hero of the room. He hung chains from a ceiling, photographed them, and turned the photograph upside down, because a chain in pure tension inverted is an arch in pure compression, and the curve that costs least to hang is the curve that costs least to stand. He let gravity do the drawing and then read the drawing the other way up.

<!-- @ -->

##### The film

<!-- @catenoid -->

The chain, spun. A soap film between two rings makes this surface and no other, because surface tension is a cost per unit area and this is the least area that will reach both rings. It lies low and wide on the floor, a cyan wireframe hourglass about a metre and a fifth across and only a third of a metre tall, and it is the same `cosh` as the laundry line, revolved.

It looks as though you could pick it up, and you cannot. It is built as a physics body on the layer the world's static geometry uses, which is the one layer a hand is told to ignore, so it carries a collider that no grab will ever find. Three separate documents in this project say you can lift it.

<!-- @helicoid -->

In a slot between two pillars, the other one, and you will step over it before you notice it: a green wireframe corkscrew twenty centimetres across and a third of a metre high, six thousand triangles in a thing the size of a mug. A plane rotating as it rises, two full turns, three tenths of a turn's height gained per turn.

Apart from a flat plane, the helicoid and the catenoid are the only ruled minimal surfaces there are, and one bends continuously into the other without a single point of either ever stretching. They are the same film in two poses. Nothing in this room performs that bend. Both surfaces are computed once when the hall loads and then never touched again, so the deformation is a fact you are told and not a thing you can watch.

<!-- @science_screen -->

One thing in this room would draw a curve rather than be one, and it misses by sixty-six centimetres. The screen looks eight metres for a name it knows; the washing lines are the only match and they stand eight and two thirds metres off. A record-keeper just out of range of the thing worth recording.

<!-- @ -->

##### Matter as the solver

The chain does not iterate. It does not sample its neighbourhood, take a step, and check whether things improved. It is already in the shape that costs least, at every instant, and if you move an end it is in the new one immediately. That is what makes these two problems the oldest solved ones: they were solved before anybody could state them, by rope and by water, and the mathematics arrived centuries later to describe what the rope had been doing all along.

The calculus of variations is that description. The room is the thing it describes.

Next: what happens when the solving has to be done in steps after all, by a machine with a frame budget.

### 048. FormFinding Relaxation

[Live text](http://localhost:3003/compose?map=FormFinding_Relaxation)

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

##### Nudged, not solved

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

##### A fossil of forces

The vessel in this room was never designed and it is not a simulation you are watching. It is the frozen output of one, kept because it was interesting, in the same way a fossil is a shape that some process left behind and then stopped.

That is the chapter's argument at its most literal. Nobody drew the amphora. Somebody chose a stiffness, a pin ring, a pulse and a number of steps, and the amphora is what those choose.

Next: forms that are not settling at all, but held, by forces that exactly cancel.

### 049. FormFinding Equilibrium

[Live text](http://localhost:3003/compose?map=FormFinding_Equilibrium)

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

##### Balanced by arithmetic

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

##### Gravity as co-designer

Gaudí hung chains from a ceiling and turned the photograph upside down. The chain finds the curve of least cost in tension; inverted, it is the arch of least cost in compression; and the shape nobody could calculate in 1890 was already hanging in the room, waiting to be photographed.

That is the same move all three objects here make. The mobile does not represent a balance, it is one. The triangle does not depict rigidity, it refuses a load in front of you. The truss does not illustrate efficiency, it is what is left after everything unnecessary was removed. In each case the designer's job was to set up a situation in which the answer would appear, and then to stop.

One thing to carry out. Everything in this room is holding still at the bottom of something. The last hall asks whether the bottom is where you want to be.

Next: how to leave a hole you have already fallen into, and why you might not want the deepest one.

### 050. FormFinding Annealing

[Live text](http://localhost:3003/compose?map=FormFinding_Annealing)

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

##### Getting out

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

##### Low enough to hold, high enough to be moved

That is the chapter, and it ends by turning against its own first sentence. A form is the answer to a minimisation problem, and matter finds those answers by falling. Four halls of that: the marble, the chain, the settling mesh, the balanced mobile, none of them drawn, each one the shape that costs the least.

Then this one. Reaching the lowest value in a model is not the same as finding the form you want. A shallow basin can preserve a useful response to disturbance even when a deeper basin gives a lower score. That comparison is a choice about this model's purpose, not a test that separates living matter from dead matter.

Next: build a form and inspect the rule that decides whether it has settled well enough.

### 051. FormFinding Forge

[Live text](http://localhost:3003/compose?map=FormFinding_Forge)

#### A shape that counts

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

## Wavefunctions: Everything Oscillates

### 052. WaveFunctions Intro

[Live text](http://localhost:3003/compose?map=WaveFunctions_Intro)

#### Returning differently

What makes a return become a rhythm?

<!-- @control_pendulum -->

Take the pendulum bob, draw it away from its resting position, and release it. Watch more than one swing. Choose the centre as a reference and notice the direction in which the bob crosses it. Now release from the other side and compare.

The bob occupies the centre repeatedly, but those visits are not identical. On one crossing it travels left; on another it travels right. At an end of the swing it turns back. Position alone cannot describe all of this. To distinguish two visits to the same place, you also need something about the motion.

Choose a height below the end of the swing and follow the bob through that height twice. On one visit it is moving towards the centre; on the other it is moving away. Keep watching until you can predict which visit comes next without counting every position along the way. Now attend to the centre and compare its crossings with the slower movement near a turning point. The repeated route contains different speeds as well as different directions. You can describe that difference before measuring a period: say where the movement appears fastest, where it pauses, and what happens immediately after each apparent pause.

Gravity supplies a restoring influence towards the hanging position. The bob continues past that position because it has acquired velocity; then the restoring influence changes that velocity again. The returning pattern comes from this relationship between position and motion. It is not a list of destinations the bob has been told to visit.

Try a small release and then a larger one. Count crossings instead of immediately declaring one faster. The familiar claim that pendulum length sets the period is most accurate for small swings. Large angles and damping complicate the comparison. A larger movement is not simply a request for a proportionally quicker rhythm.

You can interrupt the swing by taking the bob again. This makes your hand part of the experiment without making the pendulum a model of every rhythm. A heartbeat, a timetable and a swinging weight can all repeat, but their causes and conditions differ.

<!-- @ -->

The next room gives the returning movement somewhere to leave its history. Keep your centre crossing in mind: a single recurring position will become a series of distinct marks when time is given its own axis.

### 053. WaveFunctions Pendulum

[Live text](http://localhost:3003/compose?map=WaveFunctions_Pendulum)

#### Where a swing leaves its past

How can a motion that keeps returning leave a line that keeps extending?

<!-- @PendulumWave -->

Watch the pendulum first. Choose one end of its swing, then follow it back through the centre. Now look at the cyan line receding from the bob. Find the marks belonging to successive returns rather than treating the line as another string attached to the weight.

The bob moves back and forth in its own plane. The line does something else: it keeps samples of where the bob has been and moves the older samples away along a depth axis. What looks like a wave extending through the room is a history of a movement that remains near its starting place.

Look for two marks in the receding trace that represent the bob on the same side of its swing. Check the intervening line before calling them equivalent moments. Does it pass through the opposite side before returning, or have you selected the outward and inward parts of one excursion? Follow a complete repetition along the record and compare it with the live bob completing another. The drawing lets you inspect earlier movement while the bob continues. Its depth is therefore useful for reading order, but the farthest mark is simply the oldest retained sample, not a place the pendulum is trying to reach.

This separates an event from its record. The pendulum has a physical position; the trace gives that position another coordinate representing time. Two visits to the same end of the swing no longer occupy the same place in the drawing, because one happened earlier. You can compare their heights and spacing without needing to hold the entire movement in memory.

Follow the line to its far end. It does not keep everything forever. A limited number of samples survives, so the oldest part disappears as new marks arrive. The record therefore has its own rule of remembering, separate from the rule moving the pendulum. It also samples the movement at discrete moments; a smooth-looking line joins those samples.

Choose a crossing and locate the next comparable crossing in the history. Then imagine that depth represented speed rather than elapsed history. The same moving bob would make a different kind of drawing. That is a possible remapping, not a control on this demonstration.

<!-- @ -->

The sine-space room brings repeated change into the shape of the surroundings. Here depth has carried the past; there, position through a surface will reveal another use of the same cyclic vocabulary.

### 054. WaveFunctions Sine Space

[Live text](http://localhost:3003/compose?map=WaveFunctions_Sine_Space)

#### Beside the wave

What can your position reveal about a repeated change?

<!-- @sine_wall_corridor -->

Look along the facing wave walls. Choose a crest near you and another farther away. Move to a different viewpoint and compare the outline again, keeping one fixed feature in sight. Then stay still long enough to notice the slow animation.

Your movement and the walls' changing phase can both alter what lines up. Distinguish them. One comparison comes from looking at different positions across the surfaces; another comes from watching the same part over time. You do not have to confuse those operations to notice that they share a pattern of rising, falling and returning.

Use a crest as a temporary landmark and compare the wall immediately before and after it along the corridor. A height that appears on one side of the crest may appear again on the other side, although the surrounding slopes differ. Next compare the facing wall at approximately the same position. Do its inward and outward regions line up with the first wall's, or is the space between them changing? Stay with a small section while the animation continues. Describe the two outlines separately before describing the gap between them. That gap is a relation between two changing surfaces, not another wall with its own movement.

A sine function can assign a value to a position as readily as to a moment. Here several sine contributions combine to shape each wall. Their frequencies, amplitudes and relative phases determine where the surface moves inward or outward. The two walls do not have identical settings, so their relationship changes as you look along them.

The smooth surface is assembled from finite samples. It represents a calculation over space; it is not a material simulation in which one patch of wall pushes its neighbours. Its visual presence also does not guarantee a physical barrier. Treat the changing profile as something to examine rather than as a surface whose support has been established by its appearance.

Try following a crest with your eyes while standing still. Then move your viewpoint while attending to a different crest. Explain which change came from the pattern and which came from you. A live phase control would make another useful comparison, but this room currently supplies the changing view rather than that control.

<!-- @ -->

At the unit circle, the next room will make the relation between rotation and rising-and-falling coordinates explicit. Bring the question of what an axis is being used to represent.

### 055. WaveFunctions Unit Circle

[Live text](http://localhost:3003/compose?map=WaveFunctions_Unit_Circle)

#### A circle becoming a graph

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

### 056. WaveFunctions 3D Wave Propagation

[Live text](http://localhost:3003/compose?map=WaveFunctions_3D_Wave_Propagation)

#### The motion that travels

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

### 057. WaveFunctions Effect Sound

[Live text](http://localhost:3003/compose?map=WaveFunctions_Effect_Sound)

#### One wave inside another

Can one oscillation change the character of another?

<!-- @DualBallFMController -->

Move the carrier ball a little and listen to the tone it triggers. Find the axes labelled for its frequency, attack and decay. Make one small change, listen, then let the sound finish before moving again.

Keep the carrier frequency roughly fixed and turn your attention to the modulator ball. Compare a low and a high Mod Index setting, moving mostly along that axis. The note can become much more complex without replacing the instrument with a recording of something else. Mod Decay changes how that complexity evolves during the note.

Choose one carrier position and leave it as your reference. Make a small change to Mod Index, listen to the new note, and describe its beginning separately from its fading end. Return near the earlier setting and compare again before moving Mod Decay. With a slower or faster loss of modulation, the sound's changing character can become easier to distinguish from its overall loudness fading. Work with one brief description at a time: a bright beginning, a quieter tail, or a roughness that persists. These descriptions need not be instrument names. They give your next adjustment an audible feature to test rather than an unexplained preference.

The carrier supplies a base oscillation. Another oscillation alters its phase, with the ratio determining their frequency relationship and the index determining the depth of the change. An attack-and-decay envelope shapes the note's duration. These ingredients combine before the sound reaches you; the two balls are ways of choosing their values through position.

The movement also triggers a new sound. Holding the balls still does not request an endless drone, and quick gestures may begin another note before the previous one finishes. Take enough time between comparisons to hear which part of the result belongs to your changed setting.

Try making an awkward or metallic sound instead of reproducing a familiar instrument. Describe what changes without needing a preset name to certify it. The nearby colour preview is a sign of selected values, not a drawing of the waveform or a complete explanation of what you hear.

<!-- @ -->

This is one method of synthesis, with particular ranges and envelopes; it is not a universal account of timbre. The next room turns cyclic functions into twisting columns. The same vocabulary of phase and repetition can organise a form in space as well as a sound in time.

### 058. Wavefunctions Bernini

[Live text](http://localhost:3003/compose?map=Wavefunctions_Bernini)

#### A movement kept in a column

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

### 059. WaveFunctions John Cage

[Live text](http://localhost:3003/compose?map=WaveFunctions_John_Cage)

#### The limits of the unexpected

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

### 060. WaveFunctions AirMusic

[Live text](http://localhost:3003/compose?map=WaveFunctions_AirMusic)

#### After the strike

What does a strike set in motion, and what decides the note you hear?

<!-- @resonating_metallophone -->

Take the supplied stick and strike one bar. Listen after the contact has ended. Watch the response fade, then compare a longer bar with a shorter one. Give each sound enough time to reveal its decay before making the next comparison.

Now strike two bars close together. The second note need not erase the first; they can overlap while their contributions diminish. Look at the combined visual trace and distinguish the moment of excitation from the movement that continues afterwards.

Choose two separated bars and remember their positions. Strike the first, wait until its response has nearly faded, and strike the second. Now reverse the order while keeping your strikes comparably brief. The two available pitches have not changed, but their order has. Next shorten the gap so that the second enters while the first still sounds. Compare the overlap with the separate notes rather than treating it as a new bar hidden between them. If one sound masks the other, let them separate again. Repeating this small pair gives you a manageable way to hear the difference between pitch choice, timing and continuing resonance.

Each bar is associated with a frequency and a decaying oscillation. Its length is chosen in relation to that frequency, making the tuning visible as a sequence of differently sized bodies. Shorter bars correspond to higher pitches in this instrument. The sound is synthesised from the assigned values rather than discovered by solving the complete material vibration of a metal bar.

That distinction leaves a useful experiment intact: a brief action can begin a response that has its own duration. The hand supplies an event; the instrument supplies how that event continues. Repeated strikes create relationships between those continuing responses.

The available notes come from a chosen tuning. This version uses a pentatonic collection, which gives you a particular set of intervals to work with. It does not prove that every combination is harmonious to every listener, or that other notes are mistakes.

Try repeating one note while letting another enter at irregular moments. Listen for a rhythm made from overlap rather than a neat journey up the row. Another tuning would change what relationships are available, but the room does not currently offer a live tuning selector.

<!-- @ -->

The stairs ahead return the cycle to architecture. A sequence of samples can become a visible route, but supporting a walker asks for more than choosing the positions of its steps.

### 061. Wavefunctions Sky Stairs

[Live text](http://localhost:3003/compose?map=Wavefunctions_Sky_Stairs)

#### What a curve needs from a stair

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

### 062. WaveFunctions TrigWalkingPath

[Live text](http://localhost:3003/compose?map=WaveFunctions_TrigWalkingPath)

#### A slow pulse from fast motions

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

### 063. WaveFunctions Synthesis Lab

[Live text](http://localhost:3003/compose?map=WaveFunctions_Synthesis_Lab)

#### Taking a waveform apart

How much complexity can you make from five simple contributions?

<!-- @additive_wave_demo -->

The display begins with a sawtooth approximation already assembled. Look at the component rows before touching the controls. Lower the higher-harmonic sliders until only the first contribution remains. Compare the resulting smooth wave with the shape you met on arrival.

Now raise one higher harmonic. Watch its own line and the combined curve together. Add another contribution, then reduce the first. Instead of treating the result as one shape with a mysterious identity, follow what each decision adds or removes.

With only the first component raised, choose a location where its curve crosses the middle and another near an extreme. Raise the second component and compare those same locations in the combined curve. Its contribution need not change both places equally. Then lower it and raise the third instead. Count the additional rises and falls in that component's own row before interpreting the new total. This separates the component's frequency from the amount you have admitted through its slider. Return to the first component alone whenever the comparison becomes difficult to follow; a familiar baseline lets you test another contribution without remembering the whole initial mixture.

The components are sine waves at integer multiples of a fundamental frequency. Their amplitudes determine how much each contributes. At every sampled position, the display adds their values to obtain the combined waveform. The formula beside the drawing records those coefficients. A control changes an amplitude; even the first harmonic's slider changes its contribution, not the underlying fundamental frequency.

Look for a place where a component reinforces the others and another where it opposes them. The total is not a collage of separate sections. Each component participates throughout the cycle, so removing a small contribution can change several features at once.

Five harmonics give a limited vocabulary. They can suggest a square or sawtooth shape, but cannot reproduce an infinitely sharp discontinuity. The curve is also drawn from a finite set of samples. A familiar name for the approximation does not make those limits disappear.

Build an unnamed waveform and describe it before looking for resemblance to a preset. Then remove the component you think matters least. Where does its absence become visible? This is a way to investigate the sum rather than merely recognise its silhouette.

<!-- @ -->

The next sequence begins with randomness. Keep this room's lesson about construction: a complex-looking result can arise from a small, definite procedure. Appearance alone will not tell you whether the next pattern can be reproduced.

## Randomness: Freedom from Pattern

### 064. Random Definition

[Live text](http://localhost:3003/compose?map=Random_Definition)

#### A pattern that returns

Can a pattern look unpredictable and still return exactly?

<!-- @seed_replay_demo -->

Choose a small part of the coloured grid that you can recognise: perhaps a bright corner or a surprising pair of neighbouring colours. Press REPLAY and look there again. Compare more than one cell before deciding whether anything changed.

Use RANDOM to choose another seed, then replay that result too. The grid changes when its starting state changes; replaying the same starting state reconstructs the same arrangement. You can also choose a seed with the slider. Nearby numbers need not produce nearby-looking pictures.

Choose a little arrangement involving several cells, such as a corner and its two neighbours. Name their colours and their order before pressing REPLAY. Matching one colour might happen by coincidence; matching the arrangement gives you a more demanding check. Try another location as well. After RANDOM, inspect the same positions rather than searching elsewhere for something that resembles your original patch. The comparison concerns what the procedure reconstructs at particular addresses. Moving your attention to a convenient match would change the question. If you remember the earlier seed, returning the slider to that value offers another way to test the same construction across an intervening change.

The colours are produced by a pseudorandom generator. It begins in a state selected by the seed and follows a definite procedure to supply successive values. Those values become colour channels in a fixed sequence of cells. The picture can be difficult to predict by looking at it while remaining reproducible by repeating its construction.

This separates irregular appearance from uncertainty about the procedure. Calling a grid random because you cannot see a pattern is a report about your reading. Reconstructing it from the same seed is evidence about how this particular generator behaves.

Ask another visitor to choose the picture they find least predictable. Replaying it does not make their first impression foolish; it answers a different question. A surprising result can have a repeatable cause.

The seed is not an independent name for the image under every possible program. Change the generator, its parameters or the order in which values are used, and the same seed can yield another result. Reproducibility belongs to the whole procedure.

<!-- @ -->

The entropy gauge next asks what a numerical description can retain from a sequence. Keep appearance, construction and measurement separate: a number about the output will not automatically tell you everything about how it was made.

### 065. Random Entropy

[Live text](http://localhost:3003/compose?map=Random_Entropy)

#### What the gauge forgets

What can one number tell you about the uncertainty in a sequence?

<!-- @shannon_entropy_meter -->

Look at the symbol strip and the frequency bars before reading the large number. Find a symbol that appears often in the visible strip and another that appears less often. Compare their bars, remembering that the strip shows only part of the sample used to make the histogram.

Now compare the entropy reading with the maximum marked on the gauge. The source gives each of ten symbols an equal chance, but a finite collection of draws need not contain exactly equal counts. The bars record that particular sample, rather than drawing the ideal distribution as if it had already happened.

Choose two neighbouring symbols in the strip and ask whether their closeness tells you which has the taller frequency bar. Then look for another occurrence of either symbol elsewhere in the strip. The strip makes order visible; the bars collect occurrences regardless of where they appeared. Describe one fact that is easy to read from each view and difficult to recover from the other. You might follow a repeated pair in the strip while comparing a whole symbol's share in the histogram. Keep the sample sizes in mind: the shorter strip is a window into the sequence, so its apparent favourite need not lead the full count.

The calculation uses each symbol's proportion in the sample. A more concentrated distribution makes some outcomes easier to anticipate; a more even distribution over the same symbols has greater entropy by this measure. The maximum also depends on how many symbols are available. A number without that context would be difficult to interpret.

Imagine gathering all occurrences of each symbol together so the sequence reads as a series of sorted blocks. You have changed the order dramatically without changing a single count. What would happen to this gauge's number?

It would remain the same. This calculation measures individual-symbol frequencies. It does not inspect the dependencies between successive symbols, and it does not know whether their order forms a message, a rhythm or a useful instruction. A high reading is not a certificate of meaninglessness; a low one is not a certificate of value.

<!-- @ -->

The gauge presents a completed sample rather than a distribution you can edit here. A future ordering comparison could make its omission visible side by side. In the next room, the eligible set becomes spatial: before anything is removed at random, a rule has already decided what can be chosen.

### 066. Random Remove

[Live text](http://localhost:3003/compose?map=Random_Remove)

#### The set before the choice

What does a removal rule choose before chance chooses an object?

<!-- @remove_random -->

Begin by distinguishing the objects in a region from the empty spaces between them. Imagine selecting one object to remove. Before making the selection, say which objects are eligible. Are you choosing from a row, a column, a bounded region or the whole arrangement?

The removal demonstration is meant to turn that distinction into a visible sequence: one eligible piece is highlighted, then shrinks or disappears, leaving a gap. If it is active, follow several selections and compare the region that changes with the region that remains. The current museum version still needs an explicitly connected demonstration grid; a silent or missing removal is an unfinished encounter, not an example of randomness refusing to act.

Make a small paper or imagined example while the local removal grid awaits its connection. Label six occupied positions in two rows of three. First allow only the upper row, then allow all six positions. List the possible first removals in each case before choosing one. After taking one away, list what remains eligible. This exercise supplies no evidence that the museum mechanism has run; it makes the missing comparison precise enough to build and check. A viewer should be able to identify the candidate set, the selected member and the changed set without guessing which hidden boundary the rule used for that step.

The conceptual difference is precise. A random choice operates over a set supplied to it. An object outside that set has no chance of being selected, however unpredictable the choices within it may look. Chance does not make the boundary disappear or justify why it was drawn there.

Removal also changes what remains available. When a selected piece leaves the set, later choices take place among fewer pieces. The final negative space records some consequences of those choices, but may not preserve their order. Two removal histories can leave the same gap.

Try describing an empty region in two ways: as something never placed and as something taken away. Its present appearance alone may not distinguish those histories. A retained before-state, a visible eligible region and an undo would make this room's question more fully testable; those are the next additions the encounter needs.

<!-- @ -->

The following room keeps every cell and gives each one a binary choice of mark. Instead of subtracting from an arrangement, it asks how much structure can appear when a very small decision is repeated across it.

### 067. Randomness 10 PRINT Algorithm

[Live text](http://localhost:3003/compose?map=Randomness_10_PRINT_Algorithm)

#### A maze made of marks

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

### 068. Random Cubes

[Live text](http://localhost:3003/compose?map=Random_Cubes)

#### One throw and many throws

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

### 069. Random Rotate Random XYZ

[Live text](http://localhost:3003/compose?map=Random_Rotate_Random_XYZ)

#### What remains in a changing stack

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

### 070. Random Walk

[Live text](http://localhost:3003/compose?map=Random_Walk)

#### A trail without a plan

What can a path remember that its next step does not use?

<!-- @random_walk_terrarium -->

Choose one walker in the glass enclosure and follow it for several steps. Look at its trail, then predict whether the next movement must continue the apparent direction of that trail. Watch what happens when the path crosses somewhere it has already been.

Use the 2D and 3D buttons to compare a planar walk with a walk through volume. Then try LEVY and look for longer steps among the shorter ones. RESET begins another run. Keep the comparison focused on the step rule rather than expecting a particular final picture.

Follow a walker approaching a wall and compare its next positions with a walker still in the interior. The enclosure gives those situations different possibilities even when the same sampling procedure supplies their attempted steps. Next inspect a section where the trail doubles back. Look for evidence of a boundary encounter before describing the return as a preference for an earlier place. In the 2D mode, keep attention on the plane occupied by the path; in 3D, change viewpoint before deciding that two stretches intersect. A crossing in your view can come from separate depths, so the record needs spatial reading as well as following in time.

Each new position adds a sampled increment to the previous position. The ordinary modes use fixed-length steps in random directions; the LEVY option varies step length with a capped heavy-tailed rule. The walker does not need to consult the drawn trail to choose its next increment.

The trail is therefore the display's memory. It helps you see a history that the step generator itself does not use. A tangle can suggest hesitation, exploration or an intention to return, but those readings do not establish an internal plan.

The walls matter as much as the steps. Positions are reflected at the enclosure's boundaries, so these walks remain bounded. You cannot use their long-term displacement to claim that they follow the same unlimited spreading law as an unconfined walk. The LEVY option is also capped; its long jumps do not extend without limit.

<!-- @ -->

A walker that avoided its trail or followed a deposited trace would be making a different decision. In the next room, distributions become the primary comparison. Instead of asking where accumulated steps go, you will inspect how a law shapes the frequencies of many sampled values.

### 071. Random Gaussian

[Live text](http://localhost:3003/compose?map=Random_Gaussian)

#### The shape of many draws

What changes when randomness follows a different law?

<!-- @distribution_sampler -->

Select GAUSS and watch the falling samples add to the histogram. Notice how uneven the first few bars can be. Use CLEAR and watch the early picture form again, resisting the temptation to declare the first visible cluster the final shape.

Now select UNIFORM. Compare the whole interval with the concentrated middle you saw before. One next sample may not reveal which law supplied it; a collection makes their different tendencies easier to see.

Keep one distribution selected and choose two bins to watch: one near the middle and another nearer an end. Follow their counts over several additions without expecting the next sample to repair an imbalance. Then use CLEAR and compare the early ordering again. A bin that led in one short run may trail in another even though the sampling law stayed the same. Describe the tendency you expect across many draws separately from the particular contest you just watched between two bins. This makes the growing histogram a record of evidence, rather than a picture that every new sample is obliged to make more symmetrical.

A probability distribution assigns weight to possible outcomes. The histogram records how often ranges of values occurred in the sample so far. The two are related but distinct. A theoretical curve describes the rule, while finite bars contain sampling fluctuation as well as information about that rule.

The Gaussian option transforms uniform random values into a distribution concentrated around a mean. The uniform option draws across the interval without that central preference. Other buttons offer Poisson and exponential examples, but one careful comparison is enough to establish the distinction before expanding the collection.

This display bounds its values between zero and one. Values from the wider mathematical distributions are rescaled or clipped to fit, so the visible Gaussian does not possess an unlimited tail. The number of bins also affects the picture: a histogram is a representation chosen for reading, not the distribution made physically exact.

Choose a sparse early histogram and describe what you cannot yet conclude. Then compare another run. The middle of a bell curve is a frequent region under a model, not a measure of how normal, acceptable or valuable a person ought to be.

<!-- @ -->

The mushroom meadow next combines placement rules and recognisable forms. Carry the same caution into it: an overall appearance does not tell you which generating procedure supplied each feature.

### 072. Random Mushrooms

[Live text](http://localhost:3003/compose?map=Random_Mushrooms)

#### The ring someone specified

Which parts of a seemingly natural arrangement were explicitly designed?

<!-- @mushrooms -->

Compare a scattered patch with a ring or cluster. Follow the spacing between neighbouring mushrooms and look at which forms repeat. Then move your attention to a clearing. Describe what is present and absent before offering an explanation of how it arose.

Choose two mushrooms with a similar cap and stem, then inspect their surroundings. Do similar bodies occur at a similar spacing, or does one belong to a ring while the other stands in a scattered patch? Next reverse the comparison: follow one ring and look for differences among its bodies. Shape selection and placement can vary independently. You can recognise a common arrangement without requiring identical mushrooms, and recognise a repeated mushroom form without requiring a common arrangement. Keeping those two observations separate will help you reconstruct the meadow's procedures. Begin with one small patch before making a claim about how the entire field was generated.

Several procedures contribute to this meadow. Scattered candidates are accepted or rejected using a noise field, leaving uneven gaps. Other routines deliberately place rings and clusters. The recognisable mushroom bodies come from a small collection of templates, varied and repeated across the ground.

A ring can therefore look as though it organised itself while being the result of a ring-making instruction. The scattered part and the circular part need not have the same cause merely because they share one scene. The visual continuity of the meadow can hide the difference between its generating operations.

Choose a feature and propose two possible histories for it. A gap might result from rejected candidates, from later removal, or from a region where no candidates were ever considered. Looking at the final gap may not distinguish those accounts. A generation history or controlled comparison would provide evidence the finished image does not retain.

The meadow is generated for viewing; it is not a living ecological simulation. It does not calculate nutrient exchange, reproduction or competition because the forms resemble organisms. Its terrain and placements let you inspect a composed environment, without making every association that environment invites into a demonstrated mechanism.

<!-- @ -->

Try describing one patch without the words natural or artificial. Name the relationships you can actually inspect: spacing, repetition, variation and enclosure. The next room places independent and coherent height fields beside each other, making one such relationship, what neighbours share, available for a more controlled comparison.

### 073. Random Space Geometry

[Live text](http://localhost:3003/compose?map=Random_Space_Geometry)

#### What neighbours share

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

### 074. Randomness Examples of Randomness

[Live text](http://localhost:3003/compose?map=Randomness_Examples_of_Randomness)

#### An area from points

How can random points estimate a shape's area?

<!-- @monte_carlo_dartboard -->

Press THROW and find the new point. Compare its location with the circle, then check which counter changed. Add a few more points individually before using AUTO to build a larger sample. Watch the estimate as well as the marks that support it.

A point inside the circle increases both the inside count and the total. A point outside increases only the total. Each addition can move the estimate up or down; a growing sample does not require every new answer to be closer to the target than the last.

Before requesting another point, predict what the estimate would do in each possible case: inside or outside the circle. An inside point adds to both counters, while an outside point enlarges only the denominator. Check your prediction with THROW, then explain the result using the counters before looking at its distance from pi. Repeat when many points are already present. One new point then usually changes the ratio less than it did near the beginning. That reduced influence helps explain why a longer run can look steadier, although steadiness by itself cannot tell you whether the sampler covers the square in the required way.

The circle is inscribed in a square. When points are sampled uniformly across that square, the fraction landing inside the circle estimates the fraction of area the circle occupies. Multiplying the fraction by four gives the displayed estimate of pi. A geometric relation becomes accessible through repeated classification of sampled points.

The THROW button requests a generated sample. You are not aiming a physical dart with your hand, and that distinction is essential to the method. If you deliberately concentrated throws near the centre, the inside fraction would describe your aim as well as the geometry. More samples would make that biased procedure more consistent without making its answer correct.

RESET and compare a second run. Notice both the fluctuations and what becomes more stable as the count grows. One unusually good early estimate is not evidence that a short run is enough for every purpose.

<!-- @ -->

Imagine changing the sampler so it favours one region. Predict the direction of the error before asking for such a variation to be built. In the pheromone room, repeated visits really will favour places already visited. The process there changes the evidence its later decisions read.

### 075. Random Pheromone

[Live text](http://localhost:3003/compose?map=Random_Pheromone)

#### A path that recruits its next visit

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

### 076. Random Space

[Live text](http://localhost:3003/compose?map=Random_Space)

#### Layers that look like land

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

### 077. Random Game

[Live text](http://localhost:3003/compose?map=Random_Game)

#### Knowing what, not when

What can you know about a platform without knowing when it will move?

<!-- @r_c -->

Watch the cycling cube from the surrounding floor. Follow its departure, absence and return through several cycles. Pay attention to its colour and small indicator, then compare how long it waits before changing state again.

The order is recognisable. The cube waits, moves down, remains hidden, begins its return and waits again. The durations vary. You can therefore predict the next kind of event without being able to give its exact starting time.

Pick one easily recognised event, such as the beginning of the downward movement, and use it to divide your observation into cycles. During each cycle, name the events in order before trying to compare their durations. Then attend to the interval when the cube is visible and waiting. Is the next motion the same kind as last time, even if the wait feels different? Finally watch the indicator at the instant movement begins. This separates recognising a state, noticing a transition and anticipating its timing. A single signal may help with one of those tasks while supplying little information for another.

This is a state machine with randomly chosen waiting intervals. Each state specifies a limited set of behaviours: motion, appearance and whether the cube supplies its own collision surface. Random timing changes when a transition occurs; it does not allow the cube to invent an arbitrary new state in the middle of the cycle.

Look closely at what the indicator tells you. It lights during movement, rather than counting down through a guaranteed advance warning. A signal that reports a change already underway supports a different kind of planning from a signal that announces it beforehand.

The cube's own support is disabled while it is hidden, but that does not by itself tell you whether the museum floor beneath it also disappears. A visible movement and a body's possible fall are separate facts to establish. Observation is enough for this first comparison; the room still needs a support check before treating the cube as a tested crossing challenge.

Try predicting the next state while refusing to guess the exact moment it will begin. That is a legitimate form of knowledge about uncertainty. A countdown or a longer advance cue would change what a visitor can plan without changing the state sequence.

<!-- @ -->

Noise Types follows. Carry the distinction between a procedure's fixed structure and its variable choices: neither irregular timing nor an irregular surface means that every aspect of the process is unspecified.

## Noise: Entropy with Memory

### 078. Random Noise Types

[Live text](http://localhost:3003/compose?map=Random_Noise_Types)

Can randomly chosen positions still keep their distance from one another?

The randomness sequence offered several ways for a rule to admit variation. Here the relation between accepted positions matters as much as the way each candidate is proposed. Inspect the original cloud before moving any of its points.

<!-- @randompoints -->

Choose what looks like the closest pair. Move to another side of the cloud and compare the gap again. A pair that overlapped in your first view may be separated in depth. Find a gap whose separation you can judge from both positions.

Choose a third point near your first pair. Judge its separation from each member independently. A convincing gap between two points does not establish the condition for their whole neighbourhood; the generator has to consider more than that single relation.

Look across the cloud for crowding and open patches. The generator proposes positions, then rejects a candidate if it is too close to an accepted point. The resulting sample has a minimum separation at the time it is made. The random choice and the acceptance condition work together.

This construction is often called a blue-noise sample. Its spacing is a constraint on the relationship among points, rather than a promise that every point sits on a regular lattice. The generator also limits the number of attempts it will make. A requested count is therefore not an unconditional guarantee that a crowded volume will accept that many positions.

Now move a pickable point toward another one. The original generation rule does not continually rearrange the cloud to preserve its spacing after your intervention. A rule that made a sample and a rule that maintains it over time are different mechanisms.

<!-- @ -->

Choose a reason to want a cluster in this otherwise separated field. It might mark an event, make a gathering visible or interrupt the distribution's evenness. Keep that choice distinct from claiming the altered cloud still obeys the original condition.

An unconstrained sample beside this one would help isolate the effect of rejection. Such a paired display would need matched volume and requested count; a different-looking cloud alone would not make a fair comparison.

The next room looks irregular while being driven by repeating deformations. Carry a question about provenance: what rule made the variation you can see, and what evidence distinguishes it from another rule?

### 079. Noise Columns

[Live text](http://localhost:3003/compose?map=Noise_Columns)

What remains recognisable while a column changes shape?

The point cloud used random proposals constrained by spacing. These columns offer another way for a field of differences to arise. Begin by following one body through time, rather than assuming that a complicated scene must come from a complicated source of randomness.

<!-- @MeltingBerniniScene -->

Choose a column and watch its shaft bend and droop. Keep following it long enough to recognise a return in the movement. Then compare a neighbour at the same moment. Which changes occur together, and which seem to arrive at different times?

Use one neighbour as a reference while following the other through its cycle. Describe a moment when their outlines resemble each other, then wait to see whether they continue together. Agreement at one instant gives you less information than agreement across a sustained movement.

The columns have distinct rotation rates and phases of deformation. Their shafts are rebuilt as a time-dependent amount changes, while the overall repeated profile remains recognisable. Different phases can make the group seem less regular than any one member's movement.

A sine-based cycle supplies the deformation. This matters because periodic movement and noise are different ways of producing variation. Watching a complicated result from one instant cannot establish which one is at work. Following a single column gives you a stronger comparison than judging the whole moving group at once.

The appearance can suggest melting stone, but the model does not calculate heat, material strength or irreversible loss. A return toward an earlier form belongs to its programmed cycle. It is not evidence that stone can undergo that physical history and recover unchanged.

<!-- @ -->

Look for the point at which you stop calling the body a column. Does that judgment depend on its outline, uprightness, repetition or an expectation about what columns should support? The display can preserve a construction while making its familiar architectural role uncertain.

Imagine keeping one neighbour undeformed, or freezing both at a chosen instant. Either comparison would help separate changing shape from changing orientation. Those controls would extend the present observation; they are not required to notice the returning motion already here.

The following ring uses a sampled field to alter a surface. Carry the distinction between the geometry that supports a change and the rule that supplies its changing values.

### 080. Noise One

[Live text](http://localhost:3003/compose?map=Noise_One)

What holds a restless surface together?

The columns let a repeating deformation move through a recognisable form. Here a field supplies values across a ring. Begin by separating the ring's overall organisation from the changing detail on its surface.

<!-- @noisetorus -->

Watch one patch of the ring. Follow a raised region or a change in hue for a short interval, then move so that you can compare the opening and the outer silhouette. Which features help you keep recognising the ring while its surface changes?

Let the surface move while keeping your own viewpoint still. Then change your viewpoint and notice the additional change that creates. Holding one source of motion steady helps you avoid attributing everything that moves in your view to the noise calculation.

The shader samples interpolated noise values at coordinates associated with the mesh. Time shifts those sampling coordinates. The sampled value can move a vertex along its normal and contribute to the visible colour. A spatial value has become a geometric or material effect through a chosen reading rule.

Nearby sample positions tend to produce related values. This spatial correlation helps distinguish the surface from a collection of wholly independent changes. It does not mean that the field remembers you, or that neighbouring vertices negotiate with one another. A shared function can produce related values without either kind of interaction.

Look again at the silhouette. Colour can change while leaving it in place; displacement can change where the surface appears against the background. Those readings can make the same family of values answer different visual questions.

<!-- @ -->

Choose the feature you would retain if this ring had a new purpose. You might want its opening to remain easy to find, its relief to become difficult to read, or its changing colour to carry the attention. The field does not decide which of those purposes should dominate.

A frozen field shown once as colour and once as relief would make the comparison more controlled. It would be a further version of this encounter, with the sampled values held fixed while their visible interpretation changes.

The next room makes a sharper cut. A threshold will use sampled values to decide whether a small volume is present at all. Carry forward the distinction between the field and the rule that turns it into something visible.

### 081. Noise Voxel

[Live text](http://localhost:3003/compose?map=Noise_Voxel)

Can visible matter disappear while the field underneath stays the same?

The ring turned sampled values into relief and colour. This bench uses a threshold to turn a value into a decision about occupancy. Begin with the threshold while leaving the other choices alone.

<!-- @perlin_terrain_sculptor -->

Move THRESH slowly and watch which small volumes remain. Keep SCALE and SEED fixed. Predict what raising the threshold will do to a thin connection, then compare the result. Return to an earlier threshold and look for the earlier classification.

Follow one small region through the change and back again. A count of all remaining cubes would conceal which connection your attention was tracking.

Each sampled position receives a scalar value, with a height bias included in this bench's calculation. A comparison with the threshold decides whether its voxel is kept. Raising the threshold makes the acceptance condition harder to meet, so fewer sampled volumes remain.

The field supplies values before that decision. Changing the threshold can redraw the occupied region without choosing a new seed. Changing the seed instead asks a different field to supply the values. Those two interventions can both change the picture while changing different parts of its construction.

<!-- @voxelnoise -->

Compare the linked voxel display as the controls change. It also rebuilds in response to the shared settings. Look for a common direction of change, such as reduced occupancy, rather than expecting every cube to match the small volume.

The bench and receiver use different noise bases and sampling calculations. Their connection shares controls, not identical field values. Agreement in a parameter therefore does not guarantee agreement in geometry. A comparison becomes clearer when you name exactly what is shared.

<!-- @ -->

Find a threshold where a narrow connection is about to disappear. Would you keep it if it mattered as a passage, a branch or a link between regions? The same numerical cut can be useful for one purpose and erase something important for another.

Present or absent is the decision made by this encoding. It does not establish that the underlying world is intrinsically binary. You can ask whether a gradual material response or a second category would serve your purpose better, while keeping the current threshold rule precise.

The following room spreads variation across enclosing surfaces. Carry the distinction among the field, its samples and the visible decision made from them.

### 082. Noise 6 Wall

[Live text](http://localhost:3003/compose?map=Noise_6_Wall)

Which scale of variation do you notice first?

The voxel bench made a threshold's decision visible one sample at a time. Here the field appears as a changing surface. Begin with the largest feature you can follow, then look for detail within it.

<!-- @shader_noise_space -->

Choose a broad cloudy patch on a visible wall. Follow its boundary briefly, then attend to a smaller variation inside it. Compare another face of the display. Does the larger organisation remain easy to see once the fine detail has caught your attention?

Choose two neighbouring patches and watch whether their shared boundary remains recognisable. Compare that local relation with the broader movement across the face; they need not be equally easy to follow.

The wall shader combines six spatial scales. Successive contributions use higher frequency and smaller amplitude: finer changes can sit inside broader ones without replacing them. Their sum becomes the value used by the material.

These scales are often called octaves. They are components of the calculation, rather than six separate strips you can necessarily point to in the finished image. The image shows their combined effect. Looking at it can suggest different levels of detail without allowing you to recover each contribution uniquely.

Time, colour and density also affect the display. Related surfaces can run at different rates, so a difference between faces need not indicate a different number of scales. Hold your attention on one feature long enough to distinguish a changing view from a changing material.

<!-- @ -->

Try treating a small irregularity as the subject and the larger cloud as its surroundings. Then reverse that attention. A field can support both readings while giving neither a permanent claim to be the main event.

To isolate the contribution of one octave, a further experiment would freeze the field and compare the sum with selected components under the same framing and brightness. The present surface lets you inspect the composite result; it does not offer that controlled separation through a headset button.

What scale would you keep if this field were used to mark a route or make a boundary legible? A visually rich texture can also obscure the distinction a visitor needs. More detail is a choice whose usefulness depends on the encounter.

Next, a curved support changes how the field is met. Keep separate the shape receiving the values and the coordinates at which those values are sampled.

### 083. Noise Inside Noise

[Live text](http://localhost:3003/compose?map=Noise_Inside_Noise)

Does noise on a curved surface mean that one noise is being fed into another?

The enclosing walls showed several scales combined in one material. This sphere changes the support on which a related kind of field is read. Begin with what that change lets you observe.

<!-- @noisesphere -->

Follow a patch across the curved surface, then compare it with the outline against the background. Recall the ring from earlier in the sequence. Which differences seem to come from the support's shape, and which from the scale or speed of the changing detail?

Inspect a region near the silhouette as well as one facing you. The same kind of displacement is easier to see where it changes the boundary against the background.

The sphere uses a value-noise shader from the same family as the ring. It samples a field and displaces the mesh along its normals. Curvature changes those normal directions and the way the result faces you. The noisy surface can therefore look different without requiring a wholly different kind of field.

The sampling domain is the collection of coordinates at which the function is evaluated. That is a different part of the construction from the mesh carrying the visible result. Keeping them separate makes a more involved operation possible to describe.

In domain warping, a field changes the coordinates used to sample another field. A noisy outline alone cannot demonstrate that operation. This placed sphere uses direct sampling; it does not supply the paired, displaced-coordinate comparison that the broader room idea calls for.

<!-- @ -->

Imagine two otherwise matching surfaces. One would sample at the original coordinates; the other would first displace those coordinates using another field. What visible record of the displacement would help you attribute a difference to warping rather than to a new seed, colour or support?

That comparison is a concrete extension for this room. The current sphere supplies a direct-sampling reference against which it could be made. Treating the reference clearly keeps the missing experiment available to build.

Choose a reason to warp the coordinates: to disturb a regular band, gather detail around a feature or make a familiar surface harder to classify. The extra rule should answer that purpose, rather than serve only as another layer of complexity.

The next terrain makes the relationship between coordinates and visible height particularly direct. Carry the question of what a representation permits at each position.

### 084. Noise Space 10

[Live text](http://localhost:3003/compose?map=Noise_Space_10)

When a field becomes ground, which variations become a possible route?

The sphere separated the sampling coordinates from the surface receiving their values. Here each planar position receives one height. Start at the visible edge and let your eye follow the terrain before making a claim about crossing it.

<!-- @noise_space -->

Find a broad ridge and follow a smaller feature along it. Compare a gentle-looking route with a steeper alternative. What would you need to know about the surface and your means of moving before choosing one?

Choose a landmark at each end of the proposed route. Keeping those destinations fixed makes it easier to compare possible ways between them.

The terrain samples a two-dimensional noise function across a grid, multiplies its values by a height scale, and connects those samples into a mesh. Neighbouring heights create a continuous-looking surface with features at several sizes. The construction also supplies collision geometry, although the surrounding museum still determines how a visitor can approach and enter it.

This is a heightfield. Each horizontal location has one represented ground height. The rule is well suited to a surface that can be described that way. It cannot describe a cave roof and cave floor at the same horizontal location without another layer or a different representation.

Look for an apparent overhang from your current angle, then change the view. Perspective can make a single-valued surface seem more complicated than the representation allows. The distinction between an image and its construction helps you interpret that ambiguity.

<!-- @ -->

The terrain is built when the scene starts and remains fixed for this encounter. Its title does not give you a ten-slider control room. Your present intervention is a choice of view and a proposed route, rather than live editing of ten independent parameters.

Choose a feature you would preserve if the terrain were redesigned for passage. Another visitor might prefer the feature you would smooth away. A field can generate many differences without deciding which differences should matter for access, difficulty or pleasure.

A useful next comparison would place two patches side by side with one generation choice changed and the others fixed. State that choice and predict its effect before asking for the pair to be built.

The following room asks what makes two generated surfaces a fair comparison. Bring the distinction between a changed appearance and evidence for a changed algorithm.

### 085. Noise Perlin Simplex

[Live text](http://localhost:3003/compose?map=Noise_Perlin_Simplex)

Can two different pictures tell you which rule made them?

The terrain showed how a sampled field becomes visible geometry. Here two cube fields invite comparison. Begin by naming what you can inspect without relying on the names attached to them.

<!-- @simplex_noise -->

Follow a run of neighbouring sample heights. Compare a broad feature with a smaller variation, then look at how colour makes those values readable. Choose a feature you could describe to someone facing the other display.

<!-- @perlin_noise -->

Look for a comparable feature here. Does a difference in its appearance establish a different noise basis, or could seed, sampling frequency, scale or colour mapping also account for it? Name one of those alternatives before deciding what the comparison proves.

Describe that feature using position, extent and neighbouring heights. Another visitor can check those observations even before either of you knows which basis the display uses.

Both current displays begin with simplex-family noise under their default settings. The one named Perlin does not select a Perlin basis merely by carrying that name. Their independent seeds and sampling paths can produce different pictures while leaving the claimed basis comparison unperformed.

A noise basis supplies the procedure for generating the field. A seed selects a repeatable instance within the procedure. Sampling chooses where the field is evaluated, and a visible mapping turns those values into heights or colours. Each stage can change what you see. A useful comparison identifies which stage is meant to differ.

<!-- @ -->

The intended Perlin-versus-simplex encounter needs one display explicitly set to each basis, with controlled sampling, scale and visible mapping. A fixed seed helps make each repeatable; the same seed number in different algorithms does not guarantee matching samples. That is the next build this pair calls for.

Until then, use the two fields to practise describing an observation and its possible causes separately. You can be precise about a broad patch or a sharp height change without assigning it to an algorithm that the display has not established.

Choose a property that matters for a purpose of your own: continuity along a path, the appearance of repeated features, or how easily a height difference can be read. That choice gives a future comparison a question stronger than which picture looks more like its title.

The next room gives you space to retain that distinction in your own account of the sequence.

### 086. Lab Path

[Live text](http://localhost:3003/compose?map=Lab_Path)

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

## Cellular Automata: Local Rules, Global Patterns

### 087. CA Introduction

[Live text](http://localhost:3003/compose?map=CA_Introduction)

#### What will the next row do?

<!-- @ca_rule_explorer -->

Can you predict a whole pattern from what happens to three neighbouring cells?

Begin with the rule explorer. Select Rule 90 and reset it. Follow the single starting cell into the rows that appear beneath it. Before each new row, choose one position and predict whether it will be occupied. Look only at the three positions immediately above it: left, centre and right. Then check your prediction against the new row.

Try Rule 30 with the same reset. The starting mark has barely changed; the expanding pattern has. Follow an edge, then examine the less easily predicted interior. Changing the speed gives you more time to look, but does not select a different rule.

Choose a position well inside the row, where its three inputs are easy to distinguish. Say the three states in order and keep their order when you compare another occurrence. Left-occupied and right-occupied are different neighbourhoods even if both contain one occupied cell. This stops counting from silently replacing the rule's actual question. Once you have checked a few positions, follow one diagonal boundary through several generations. Its regularity can make some predictions easy while nearby interior positions remain harder to anticipate from a quick glance.

Here a cell holds one of two states. Three neighbouring states make eight possible neighbourhoods. The selected rule supplies one answer for each neighbourhood. Every position reads the old row before the new row replaces it, so a newly written answer cannot influence its neighbour prematurely. The two ends of the row wrap together: the apparent edge of the display is not the end of the neighbourhood.

The field you met in the noise rooms assigned values to positions. This system adds a different relation: a position receives its next state from nearby states. A large arrangement becomes the accumulated consequence of small, repeated decisions.

The picture alone does not reveal every rule entry. Some neighbourhoods may never occur from this particular starting cell. A useful extension would let you supply a second seed and ask whether two rules that looked identical now separate. That is a test of what the first experiment left unexamined.

<!-- @ -->

Carry one distinction forward: the state of a cell, its neighbourhood and its update rule are separate choices. The next room changes the state space and the neighbourhood of that arrangement.

### 088. CA ElementaryRules

[Live text](http://localhost:3003/compose?map=CA_ElementaryRules)

#### A cell with a past

<!-- @structure_growth -->

How would you recognise a cell that has stopped being active but has not yet disappeared?

Look into the structure growth specimen. Choose a small cluster and distinguish its occupied positions from the spaces around them. If the generation is still advancing, follow the cluster through several updates. Some positions remain active; others pass through a dying state. If the specimen has already stopped, read it as one generation held for inspection, not as proof that the pattern can no longer change.

Try a second reading through the depth of the specimen. A cell that looks isolated from one viewpoint may have neighbours behind it. Move sideways and check the apparent gap before calling it empty. Choose a cluster near an outer boundary and compare its available surroundings with a cluster farther inside. You need not count every neighbour to notice that a flat photograph can hide the very relations the update consults. Keep that difference between the visible projection and the three-dimensional neighbourhood in your account of the pattern.

The rule explorer used a row with left and right neighbours. This specimen uses a volume. Around an interior cell are twenty-six neighbouring positions: those sharing a face, an edge or a corner. A cell counts active neighbours, and that count determines whether activity survives or is born. Other states record the stages through which activity decays.

The current rule accepts a restricted band of neighbour counts for birth and survival. It therefore does more than colour a random cloud. It repeatedly selects arrangements that meet a local condition, while a finite sequence of states makes disappearance take time. The visible body is the result of those updates and the chosen initial population.

This is a three-dimensional, multistate comparison with elementary cellular automata. It does not display the complete one-dimensional rule table suggested by the room's title. Keep that elementary table from the previous room as your reference, and ask precisely what has changed here.

The demonstration also has a generation limit. A stopped animation may have reached that limit rather than equilibrium. An improved comparison would display the generation count beside an unchanged-cell count, allowing a visitor to distinguish an imposed stop from a pattern that repeats itself.

<!-- @ -->

Next, we will separate space from recorded time by reading successive generations as a structure you can inspect from the side.

### 089. CA GameOfLife

[Live text](http://localhost:3003/compose?map=CA_GameOfLife)

#### A bridge made from generations

<!-- @ca_bridge -->

Are the rows ahead of you neighbouring places, or different moments?

Stand where you can see the cellular bridge from an angle. Find a row of occupied cubes, then follow the next row along its length. Compare several positions directly across neighbouring rows. Try to read a small triangle of cells as evidence: three states in one row determine a state in the following row.

Pick a conspicuous gap and locate the occupied cells in the row immediately before it. Then look one row farther back. Reading backwards this way does not necessarily recover a unique earlier state, but it tests whether you have identified the order of the record correctly. Compare your backward reconstruction with a forward prediction from a visible row. The asymmetry is useful: a deterministic next step need not give an equally determinate way to recover everything that came before. The bridge retains history that the newest row alone would lose.

The bridge begins with a central occupied cell and applies Rule 30. Each new generation is laid down farther along the structure. Its length therefore records elapsed updates. A coordinate that looks like a direction through space is also a direction through the calculation's history.

This differs from the volume in the previous room. There, neighbours surrounded a cell within a three-dimensional state. Here, the displayed depth retains old rows of a one-dimensional state. Counting every nearby cube as a simultaneous neighbour would mistake the record for the system being recorded.

Occupied cubes receive collision shapes. That turns some of the record into physical support, although a visible sequence of cubes is not by itself a promise of a continuous route. Observe the pattern before treating it as a path; gaps are results of the rule, not instructions to jump.

The name of this room points towards the Game of Life, but this particular bridge uses an elementary rule. Hold that distinction. Life needs a two-dimensional present whose next state is calculated from eight neighbours; the next room provides that comparison on a living display.

<!-- @ -->

A useful variation would place the same Rule 30 history flat on a wall beside this bridge. Neither record would be more mathematically correct, but each would make different relations easier to notice. Then reverse the displayed order of generations and ask what evidence would reveal the reversal. The rule creates time's ordering; the museum gives that ordering a spatial reading.

### 090. CA BeyondBinary

[Live text](http://localhost:3003/compose?map=CA_BeyondBinary)

#### A travelling pattern

<!-- @game_of_life_petri -->

What moves when a pattern crosses a field of cells that stay in place?

Watch the petri display before adding anything. Find a small moving arrangement or a cluster that changes and returns. Choose a fixed position on the board and observe its state as the pattern passes. The position does not travel with the figure. Its state changes, and the neighbouring positions take their turns in making the figure visible.

Use the pattern controls to introduce a glider or pulsar. Give the addition time to develop. A new pattern may meet cells already present, so its behaviour need not match a clean, isolated example. Reduce the speed when you need to follow one update.

Keep one landmark in the display in view while you follow the moving pattern. Describe its position relative to that landmark after several updates. Then describe the individual cells that made it visible at the beginning. Those are two different records: the route of a recognisable arrangement and the changing occupancy of fixed sites. A repeating cluster offers another comparison. It can return to an earlier appearance without travelling across the board, so repetition and displacement need to be identified separately before they are explained together.

This is Conway's Game of Life. Every cell is either occupied or empty. An occupied cell survives with two or three occupied neighbours; an empty cell becomes occupied with exactly three. The eight surrounding positions supply the count, and all cells read the same old state before the next one appears. The board wraps at its boundaries.

The bridge in the previous room displayed successive rows as depth. Here the present occupies a plane, and its earlier states disappear from the display. You must remember them, or reconstruct them by watching a repeating pattern.

This encounter remains binary. A pattern involving many cells does not give any individual cell more than two possible states. A multistate comparison would need another working update rule. The glider is a recurring relation among binary cells, not a special moving cell or evidence of a richer state stored in one place.

<!-- @ -->

An improved comparison would run the same inserted pattern on an empty board and on an inhabited one. That would reveal which behaviour belongs to the isolated pattern and which arises from an encounter. The next room makes your own proximity part of such an encounter.

### 091. CA ExpandingSpace

[Live text](http://localhost:3003/compose?map=CA_ExpandingSpace)

#### The bridge notices proximity

<!-- @decaying_bridge -->

Can approaching a path help change whether it remains a path?

Begin beside the decaying bridge, where you can observe it without relying on its cubes for support. Choose a patch near you, then step closer. Wait and compare it with a more distant patch. Withdraw and continue watching the same region. Look for recovery as carefully as disappearance.

Repeat the approach at a slower pace and stop at a place you can recognise again. Watch the near patch for a little longer before withdrawing. This helps distinguish a response to time spent nearby from a response that happens only when a boundary is crossed. During recovery, compare the centre of the affected region with its edge beside healthier cells. The same damaged appearance may recover differently depending on what remains around it. Record where you stood as part of the observation, alongside what the bridge did.

The bridge checks the position of the player. Nearby cells lose health over time. Farther away, a damaged cell can recover when enough neighbouring cells are healthy. As health falls, the appearance changes; below a further threshold, the cell's collision is disabled. The visible record and the supporting surface are related by a rule, rather than guaranteed to remain identical.

This is not a measurement of the force of your feet. Proximity is the input. Standing close to a cell can affect it even without stepping on it. That distinction matters if you are trying to explain an observation: what felt like damage from weight may have been a response to distance.

The petri display let a pattern encounter another pattern. Here the system includes a participant whose movement changes its local conditions. The player also reads the bridge and changes direction in response. The loop joins a numerical update with a decision made outside it.

Recovery has conditions too. A heavily depleted region may lack the healthy neighbours needed to regrow promptly. Waiting is therefore an experiment, not a guarantee that every route will return.

<!-- @ -->

A useful extension would show a faint outline wherever collision has been disabled, then compare this with the existing appearance alone. Visitors could ask what information they need before deciding to proceed. That question leads towards the next room: which parts of a rule are available to inspect, and which remain hidden behind its presentation?

### 092. CA SoftRules

[Live text](http://localhost:3003/compose?map=CA_SoftRules)

#### Reading a rule-making bench

<!-- @the_clockmaker_of_rules -->

How much of an algorithm can you infer from a machine that appears to explain it?

Approach the clockmaker's bench and follow the arrangement from its reading side towards its writing side. Compare the discrete row, the circuit-like path and the circular field illustration. First describe what each actually presents: separated states, a route through connected pieces, or a region with a graded appearance. Avoid naming its behaviour until you have identified the evidence for it.

Choose one relation that the bench makes easy to see, such as the separation between a reading region and a writing region. Then identify what a still arrangement cannot show: when a value is read, whether a displayed state is replaced, or how one update follows another. Move to a second viewpoint and ask which of those uncertainties the extra view actually resolves. Spatial access can clarify an arrangement without supplying its missing time history. That is a useful distinction when a diagram is presented with the appearance of a machine.

The elementary row is constructed by applying a neighbourhood rule. It offers a concrete link back to the first room: three bits select a next bit. The other parts of this bench are visual models of different possible organisations. Their presence does not mean that a circuit signal or a continuous cellular field is currently evolving inside them.

The crank and levers belong to the bench's physical language. Their shape invites a story about operation, but they do not presently provide working visitor controls. Read the arrangement as a diagram you can move around. The intended soft-rule experiment still needs a functioning field that changes over time and exposes a parameter you can vary.

That missing step is precise. A continuous-state automaton would store more than an occupied-or-empty value and calculate a new value from a weighted neighbourhood. To teach it here, the room must let you observe those values changing, rather than merely presenting a smooth-looking object.

For an extension, place a live continuous-state patch beside the calculated binary row, give both a visible clock, and let one neighbourhood parameter change while the initial state stays fixed. Then the comparison could concern mechanisms instead of appearances.

<!-- @ -->

Take the bench's invitation seriously enough to test it. In the next room, two visibly related patterns will ask whether sharing a shape also means sharing a procedure.

### 093. CA AgentsCircuits

[Live text](http://localhost:3003/compose?map=CA_AgentsCircuits)

#### The same pattern, different work

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

### 094. CA EdgeOfChaos

[Live text](http://localhost:3003/compose?map=CA_EdgeOfChaos)

#### Between smoothing and disturbance

<!-- @self_organization_ca -->

When a patch changes, is it following its neighbours or being disturbed away from them?

Watch the self-organisation display for several updates. Choose a boundary between differently coloured regions. Does the boundary soften, spread, break apart or persist? Compare one small patch with the larger arrangement before deciding that the whole display is orderly or chaotic.

Try following two patches at different scales. In a small patch, individual changes may appear abrupt; across a larger region, their combined effect may look gradual. Keep the observation time similar for both readings. Also distinguish an enduring boundary from a boundary that repeatedly disappears and returns nearby. A single glance can make those histories look alike. Before reaching for a category such as chaos, state the shorter description you can support: a patch persisted, a difference spread, or several neighbouring values became more alike during the interval you watched.

The cells hold integer states from zero to nine. Their next values combine a response to a neighbourhood average with a random disturbance, followed by conversion back to the allowed range. The displayed configuration therefore makes two tendencies compete: neighbours can pull states towards one another, while disturbance can separate them again.

An authored parameter called lambda couples those tendencies. Across its range, neighbour coupling decreases as the amount of random disturbance increases. That is a particular design for exploring a transition. It is not the same thing as measuring every possible cellular rule and locating a universal boundary between order and chaos.

The display uses labels for a supposed critical region, but those labels are not an experimental result. To support such a claim, we would need to define what is measured: persistence, sensitivity to a changed seed, correlation length, or something else. A complex-looking picture cannot decide between them.

The most useful extension would show two runs with the same starting state and random sequence, differing only in one cell. We could then watch whether the difference disappears, remains local or spreads. A second comparison could vary neighbour coupling independently of disturbance, revealing what the current single parameter combines.

<!-- @ -->

You have now met repeated local updates that create structures larger than their neighbourhoods. The next sequence approaches repetition from another direction: a construction that explicitly calls for smaller instances of itself. Carry the difference between an emerging resemblance and an instruction to repeat.

## Fractals: Infinite Within Finite

### 095. Fractal Recursion

[Live text](http://localhost:3003/compose?map=Fractal_Recursion)

A rule fed its own output is the whole engine, and only the base case stops it.

You arrive in mid-air and drop a metre and a bit onto the floor, because nobody marked a spawn here and the room worked one out from its own centroid. That is a fair introduction. This is the engine room of the chapter, and almost nothing in it is the size it was meant to be.

```gdscript
func draw_recursive(centre: Vector3, size: float, depth: int) -> void:
    if depth <= 0:
        return                      # the base case, and the only thing that stops it
    add_square(centre, size)
    draw_recursive(centre, size * size_reduction, depth - 1)
```

Output becomes input. The function calls itself with a smaller argument and the smaller call calls itself again, and the whole structure is that one line repeated until a counter runs out. Everything in this chapter is built by something shaped like this.

##### One call, or many

<!-- @fractal_recursion_2 -->

Six squares inside each other, each half the last, hanging edge-on above head height. Read the code behind it and there is exactly one self-call, which makes this a tail call: one square per level, a straight line down. It is recursion in the strict sense and it is not branching, so nothing here multiplies. The corpus keeps a blunter description of it than the label on the wall does: a loop wearing recursion's clothes.

Keep it in mind for the next object, which is what happens when the call is made four times instead of once.

<!-- @example_8_3_recursion_circles_vr -->

Four metres of tori, eighty-five of them, each ring carrying four smaller rings at six tenths the radius. Four calls per level and four levels: eighty-five is what one, four, sixteen and sixty-four come to. The whole assembly turns for about seven seconds, freezes for ten, and turns again. That pause is worth the wait. A branching recursion is not more complicated than a tail call by a little; it is a different order of thing, and the difference between this and the flat squares beside it is one number in one line.

<!-- @cube_subdivision -->

The only thing in this room you cannot walk through. A cube splits into eight at a bit under half scale, then one of those eight is picked at random and split again, and again, for about ten seconds until the pile stops at eighty-five cubes. The pick is unseeded, so the pile is different every time the room loads, and it is the one object here that shows the engine choosing. Recursion in a program is exhaustive. Recursion in a world has to decide where to spend.

<!-- @ -->

##### Built and buried

<!-- @recursive_table -->

<!-- @recursive_chair -->

A table and a chair, each assembled from a subdivided cube in five timed steps: split, keep the top layer and four corners, flatten the top, stretch the legs. Both are here and neither can be seen. Each was placed at a fifth of its size and dropped half a metre, which puts the whole of both inside the solid cube of the floor. The chair finishes building about two and a half seconds after the room loads, underneath you.

They are the chapter's best argument about what recursion is for, which is that a chair is not a special shape but a cube with the right cells kept, and you cannot look at either of them.

<!-- @cube_staircase -->

A staircase builds itself over two and a half seconds, six treads and a handrail, twenty-six boxes. It stands in one of the nine holes in this floor, and it has no collision, so it is a staircase you cannot climb standing in a gap you can fall through.

<!-- @fibonacci_pagoda -->

Eight tiers, each scaled down by the golden ratio to the power of a half, with a five-part finial on top: a hundred and nine pieces in all, and nine and a half metres of them in a room whose walls stop at two. It goes straight out through the roofline. This is the chapter's other recursion, the one that shrinks by an irrational number instead of a half, and you have to stand well back and look up through where the wall should be.

<!-- @ -->

##### Watching and not watching

<!-- @science_screen -->

A screen, floating a metre and a half up with its stand's foot hanging in air, set to draw a bar chart. Twenty bars, and they come from a random number generator with a fixed seed inside the screen itself. No object in this room feeds it. It is a graph of nothing, drawn accurately, refreshed forever.

<!-- @dark_sphere -->

A dark sphere turning slowly over a disc of light, breathing on a sine. It carries a hit body that a catalyst could shoot, and in this room shooting it does nothing at all, because the response is chosen from the map's name and this map's name matches none of the rungs that respond.

<!-- @synthesis_stand -->

And beside it the same sphere again, on a low slab, as the one variant of its family the measurements ranked highest, with the values on a plaque. A family reduced to its best member is the opposite move from everything else here: recursion makes many from one, and this makes one from many.

<!-- @ -->

##### The base case

Everything in this room is one line calling itself. The squares call once and make a ladder. The rings call four times and make a swarm. The cube calls once but chooses where, and the pagoda calls with an irrational ratio and climbs out of the building.

What stops any of them is the same thing: a counter, checked at the top, that eventually says no. Without it the engine does not make an infinitely detailed object; it makes nothing, because it never returns. The base case is not a safety rail bolted on afterwards. It is the half of the rule that makes the other half mean anything.

Next: follow a branch into its descendants and test which relationships repeat as their sizes and directions change.

### 096. Fractal RecursiveTrees

[Live text](http://localhost:3003/compose?map=Fractal_RecursiveTrees)

#### Find the next branch

<!-- @recursive_tree -->

Where would you expect another branch if you could continue this tree yourself?

Choose a large branch and follow it towards its smaller descendants. At a fork, pause and predict the direction and size of the next division. Then move your attention to another fork at a similar depth. The branches share a procedure, but they need not have identical lengths or directions.

Choose a fork with a clear view of both descendants. Follow one route to its last visible branch, return to the fork and follow the other. Compare the number of divisions as well as the final lengths. A short-looking route can be shortened by scale changes, by its direction relative to you, or by where construction stops. Moving around the tree helps separate foreshortening from a shorter branch. The task is to identify relations you could describe without relying on the tree's outline from one preferred viewpoint.

The previous room separated one recursive call from many. Here, each call creates a branch and then creates further branches from it. A depth counter limits how far the construction continues. The smaller branches repeat the task performed by their parents, with changed dimensions and directions.

Random variation enters that construction, but the generator uses a fixed seed. The seed makes this particular arrangement repeatable. Randomness describes how the choices are generated; it does not require the tree to change each time you look away. The boxes that represent branches remain a finite arrangement produced by a bounded calculation.

Try reading the tree twice. First attend to the outline, which encourages you to see a familiar living form. Then attend to the parent-child relations: which branch begins where another finishes, which parameters shrink, and where the counter must have stopped. The second reading explains something the silhouette cannot.

The resemblance to a tree does not give the model roots, light-seeking, competition or a material cost for growth. Those would require additional mechanisms. Its lesson is recursive organisation, with a controlled source of variation.

<!-- @ -->

A useful extension would place two specimens with the same seed beside one another and change only the depth limit. You could locate exactly where the added calls begin. In the next room, recursion will make its structure visible through removal: the descendants will be the intervals left after a repeated cut.

### 097. Fractal CantorSet

[Live text](http://localhost:3003/compose?map=Fractal_CantorSet)

#### Keep the two ends

<!-- @cantor_set -->

How much can disappear while the same arrangement remains recognisable?

Find the longest bar in the Cantor display. Read the row beneath it: two shorter bars occupy its outer thirds, with the middle third absent. Follow one of those shorter bars into the next row. Predict where its two descendants should appear before checking the result.

The display may still be building when you arrive. Watch a new row form, but keep the earlier rows in view. They remain as a record. This arrangement is important: the bars above are earlier stages of the construction, not extra pieces that belong to the final stage below.

Use one retained bar as a temporary unit. In the row below, identify the two smaller bars and the gap that together span its former extent. Then choose another retained bar at the same level and check the relation again. You can repeat this reading without counting the whole display. It reveals how a rule can be local and still determine every part of a much larger arrangement. If a fine bar becomes difficult to distinguish, stop there: that is a limit of this encounter's resolution, not permission to invent the unseen detail.

The rule replaces each surviving interval with two copies, each one-third of its length. Applying the same rule to those copies creates the next level. The branching tree added descendants along a growing structure; this construction uses descendants to retain selected portions of an interval.

After one step, two-thirds of the original length remains in that row. Each further step keeps two-thirds of what the preceding row retained. You can check that reduction with a small number of bars, before thinking about repeating it indefinitely.

The museum displays a finite number of thick bars. They are not the infinite Cantor set, and their thickness cannot demonstrate the properties of the mathematical limit. What they do provide is a sequence whose rule you can inspect and continue in thought.

For a variation, imagine retaining a faint mark wherever a middle third was removed. Would you find the surviving intervals more easily, or start reading the removed intervals as the main structure? That change would leave the selection rule intact while changing what the display helps you remember.

<!-- @ -->

The next room compares removal with replacement. Keep track of which quantity changes when a segment is replaced by several smaller segments rather than simply cut away.

### 098. Fractal KochSierpinski

[Live text](http://localhost:3003/compose?map=Fractal_KochSierpinski)

Replace and remove are the two fractal moves, both land between the integers, and dimension is a number you can measure rather than a number you are given.

You arrive standing five centimetres inside a pyramid. Nobody marked a spawn, so the room put you at its own centre, and its own centre is occupied by the base of the largest solid object in the chapter. Step out of it first.

```gdscript
D = log(N) / log(S)
```

Count how many copies of itself a shape contains, count how many times smaller each copy is, and divide one logarithm by the other. For a line cut in two you get one. For a square quartered you get two. For the two shapes in this room you get numbers that are not whole, and that is the whole content of the word fractal.

##### The two moves

<!-- @fractal_koch_curve -->

The first move is replace. Take a segment, take out its middle third, and put two sides of a triangle there instead: four segments where there was one, each a third as long, so the length goes up by a third at every step and never stops going up. Four copies at one third: the dimension is about 1.26.

It is also the one thing here a hand can change. There is a slider on it, and turning it walks the depth up and down while you watch. Watch the size, though, not just the shape. At depth four this drawing measures the same bounding box as at depth zero, to the millimetre, because its spikes are built pointing inward. Infinite perimeter inside a finite box is the honest headline of the Koch curve, and this object demonstrates it by accident, in the wrong direction, which is a better demonstration than the intended one.

<!-- @koch_curve_3d -->

The same curve bent into an archway, drawn as two thousand three hundred cylinders. Look at it and then look at the note the corpus keeps about it: at this line thickness, iterations three, four, five and six are the same photograph. The detail is really there and the pipe drawn around it is thicker than the detail is fine. Resolution is a property of the drawing, not of the object.

<!-- @sierpinski_triangle -->

The second move is remove. Take a triangle, take out the middle one of the four you can quarter it into, and repeat on the three that are left: three copies at one half, dimension about 1.585. It builds over six seconds, a thousand and ninety-two slabs of it, ten metres wide in a room thirteen across, and it goes out through the east wall, out through the south wall and three and a half metres down through the floor. Nothing stops you walking through it, because it has no collision anywhere.

<!-- @sierpinski_pyramid -->

The same removal in three dimensions, and the only thing in this room that is solid. Twelve metres of lattice built out of nearly thirteen hundred separate cubes, each one carrying its own collision body, which is why you started inside it and why it is the one object here you can be stopped by. Four copies at one half in three dimensions gives a dimension of exactly two: a solid that fills area like a sheet and volume like nothing at all.

<!-- @ -->

##### Measuring it

<!-- @box_counting_dimension -->

The bench that turns the formula into an instrument. Eight thousand points scattered into a Sierpinski gasket, a grid laid over them at six different scales, and a count at each scale of how many boxes have anything in them. Plot the counts against the scales on log paper and the points fall on a line, and the slope of that line is the dimension. It reads 1.585.

That number was not put in. It was measured off a scatter of points, and it agrees with the three-copies-at-one-half arithmetic to three decimal places. This is the moment the chapter stops describing and starts checking.

<!-- @recursion_observatory -->

Four of them side by side on one bench, ordered along a rail marked from zero to three: Cantor dust, the Koch curve, the Sierpinski pyramid, the Menger sponge. Nothing here moves. It is a shelf of specimens arranged by a quantity, which is what a museum does with anything once it can measure it.

<!-- @ -->

##### Built without either move

<!-- @cube_cabin -->

<!-- @cube_bookshelf -->

A cabin and a bookshelf, each assembling itself out of boxes over a couple of seconds. They are here as the control, and they are more honest as a control than their labels admit: both are described as made by cube subdivision, and neither subdivides anything. The cabin is thirty-one hard-coded boxes and the shelf is twelve. Put them next to a Sierpinski pyramid and the difference is exact. One of these was written out part by part. The other was written once and applied to itself.

<!-- @science_screen -->

<!-- @dark_sphere -->

A screen set to record a trace, with nothing in the room drawing one, and a dark sphere turning over its halo. Between them they are the room's only two things at human scale, in a hall where the two objects that matter are five and ten metres taller than the walls.

<!-- @ -->

##### Between the integers

A line is one-dimensional and a plane is two, and everything you were taught to draw sits on one of those whole numbers. Replace and remove both break that. The Koch curve is more than a line and less than a plane, at 1.26. The Sierpinski triangle is 1.585. The pyramid is exactly two and is not a surface.

The number is not a metaphor and not a ranking. It is a measured slope, taken off a log-log plot on the bench in the corner, and it says how fast detail appears as you look closer. That is what a dimension has always been. Here, a non-integer dimension describes a scaling relation that an integer label would conceal.

Next: removal enters a volume, where openings repeat through the faces of a cube.

### 099. Fractal MengerSponge

[Live text](http://localhost:3003/compose?map=Fractal_MengerSponge)

#### A hole with smaller holes

<!-- @menger_sponge -->

Can you find the same opening at two different scales?

Begin with one face of the sponge. Locate its large central opening, then inspect the smaller square regions around it. Look for smaller openings arranged in the same relation. Move to a neighbouring face and test whether the organisation continues around the corner.

Choose a corner of the outer cube and keep it as a reference while you change viewpoint. The openings can rearrange dramatically in projection even though their positions in the object remain fixed. Try identifying one small retained cube on both views, then follow the opening beside it. This makes the repeated unit more concrete than a general impression of porosity. It also gives you a way to describe an occluded feature carefully: you saw its entrance and another face, but may not yet have established the route between them.

The construction begins with a cube divided into twenty-seven smaller cubes: three along each axis. Seven positions are removed, leaving twenty. The same selection is then applied within every retained cube. Instead of drawing each visible opening independently, the generator repeats a single spatial instruction at a smaller size.

The preceding room compared replacement and removal in curves and triangular constructions. The sponge gives removal a volumetric setting. A gap on one face may meet a gap from another direction, making an opening part of a larger passage through the object.

Follow that possibility with your eye rather than assuming every dark square is a through-hole. A viewpoint can conceal a back wall, and separate holes can overlap in a projection. Moving around the specimen helps distinguish a drawing of an opening from a connection through a volume.

At each completed stage, twenty twenty-sevenths of the previous volume remains. The displayed sponge has only a finite number of stages and retains positive volume. Claims about the infinite construction concern a limit that this mesh cannot physically finish.

A useful extension would pair two recursion depths at the same outer size and colour the newly removed positions. That would reveal what the extra step changed without relying on a visitor to distinguish details smaller than the display can resolve.

<!-- @ -->

Next, repetition takes a numerical form. Instead of retaining twenty copies, we will generate each new quantity from the preceding two and inspect how its visual representation changes what we can compare.

### 100. Fractal GoldenSpiral

[Live text](http://localhost:3003/compose?map=Fractal_GoldenSpiral)

#### Read the numbers before the height

<!-- @fibonacci_sequences -->

Do the growing towers make the gaps between successive numbers look larger or smaller than they are?

Follow the Fibonacci display from its first small values. Read several consecutive numbers and predict the next one by adding the preceding pair. Then compare their tower heights. A value can increase substantially without its tower increasing by the same proportion.

Take three consecutive values that are still easy to read. Add the first two yourself, then check the third rather than guessing from its height. Repeat with a later group. The arithmetic relation stays simple while the visual distances become less transparent. Now compare the first equal pair: equal values should not be mistaken for a missing step merely because their towers have the same height. Position in the sequence records a term's place in the recurrence, which is a different property from the number stored there.

The sequence begins with one and one. Each later number is the sum of the two before it: two, three, five, eight, then thirteen. The moving highlight helps locate a term, but the recurrence is the relationship between terms. It continues to hold when no highlight is passing over them.

The towers use a logarithmic height mapping, with an added base height. That compresses the numerical range so that later terms can share a display with earlier ones. It also means that equal-looking differences in height are not equal differences in number. Use the values to check the recurrence; use the heights to follow the overall growth.

The sponge repeated a spatial construction inside its retained parts. This display repeats a numerical operation on a short history. Both reuse a procedure, but they do not repeat the same kind of object. Naming what is passed to the next step prevents the word recursion from flattening that distinction.

The room's spiral theme points towards further constructions using these numbers. This particular encounter supplies the recurrence, not evidence that every spiral in nature follows it. A spiral requires an additional rule translating quantities into positions, lengths or turns.

<!-- @ -->

A useful extension would place linear and logarithmic versions of the same towers side by side. Ask which version makes addition easier to verify and which keeps more terms visible. The next room also begins with a recurrence, but asks what happens when it is repeatedly applied to each starting point in a plane.

### 101. Fractal JuliaSet

[Live text](http://localhost:3003/compose?map=Fractal_JuliaSet)

Nobody builds this one. The boundary between two fates draws itself, and a single number decides which boundary you get.

The last two halls were made things: a rule you wrote, applied to a shape you chose, as many times as you said. This is the hall where that stops. There is no construction here. There is a question asked of every point in a plane, and the answer, plotted, is the picture.

```gdscript
func escapes(z: Vector2, c: Vector2, limit: int) -> int:
    for i in limit:
        z = Vector2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c
        if z.length_squared() > 4.0:
            return i          # it left. how long it took is the colour
    return limit              # it stayed
```

Square it and add c. Do that forever. Some starting points run away to infinity and some never leave, and the only thing the machine records is how many steps the runaways lasted. Nobody draws a shape. The shape is the border between the ones that stay and the ones that go.

##### The set, on the floor

<!-- @julia_set -->

Not a picture and not a screen: a carpet of eight-centimetre cubes lying flat on the ground, one cube per point that survived the test. It is sparse, a scatter rather than a field, and it breathes on a thirty-second cycle as the zoom drifts, thickening to four hundred and sixty cubes and thinning back to forty-five. About a third of it hangs off the edge of the platform over nothing.

Walk around it rather than looking at it from one side. The cubes are the points that never escaped, and the empty floor between them is not background: it is every point that did. The picture is made of one answer and the absence of the other.

<!-- @julia_set_explorer -->

The instrument, and the only thing in this room you can operate. A table with a shader running on its top face, computing the same escape test per pixel in real time, and two grabbable sliders and four buttons on a panel at the near edge. The sliders move c.

That is the room in one gesture. c is a single complex number, two dials, and it is not a setting for the picture; it is the picture's entire identity. Move it a little and the shape deforms. Move it past a certain boundary and the set shatters from one connected object into infinitely many disconnected specks, with no intermediate state. There is a knife edge in the dial and you can find it with your hand.

<!-- @lyapunov_fractal -->

Flat on the floor beside it, a small painted square computed once and never again. Different equation, same idea: run a simple rule over and over for each point and colour by whether the running is stable or divergent. The order of the letters in its pattern is chosen before anything is drawn, and the picture is what that order produces. It is here to say that the trick is not special to one formula.

<!-- @dark_sphere -->

A dark sphere over a disc of light, turning, breathing. The one object in this hall that has a surface you could point at and a size you could state.

<!-- @ -->

##### Found, not made

Six metres above the west edge of the floor, well past where you can walk, a red marker drags a comet trail through empty air. That is c, moving along a slow closed path, and the carpet on the floor is what c currently is. The parameter is out of reach and the picture is at your feet, and neither of them is a thing anybody drew.

This is the chapter's turn. Recursion was an engine you fed. The Koch curve and the Sierpinski triangle were rules you applied to a shape you chose. Here the rule is three operations long, the shape is not chosen at all, and what appears has a boundary of infinite intricacy that no one designed and no one can fully specify. The authorship has moved. You set one number; everything else is discovered.

And there are as many of these as there are complex numbers.

Next: the map of all of them at once.

### 102. Fractal MandelbrotSet

[Live text](http://localhost:3003/compose?map=Fractal_MandelbrotSet)

Five characters index every Julia world at once, and the edge of that index is where the interesting ones live.

The last hall gave you one dial and one picture. Turn the dial and you get a different picture; turn it far enough and the picture stops being connected and falls into dust. That raises an obvious question, and this hall is the answer to it: for which values of c does the set hold together?

```gdscript
z = z * z + c
```

The same five characters, asked a different question. In the last hall c was fixed and you swept the starting points. Here the starting point is always zero and you sweep c, and you mark every c whose orbit stays bounded. What you get is not another fractal in the family. It is the catalogue of the family.

##### The catalogue overhead

<!-- @mandelbrot_set -->

Ten thousand cubes in a field nine and a half metres square, hanging about four metres up, which is wider than the floor it hangs over and higher than anything you can climb. Each cube is one value of c, coloured by how long that c took to escape, and the black region in the middle is the set itself: every c whose Julia set is connected.

You are standing under a map, and each pixel of the map is an entire world from the previous hall. Look up long enough and the shape resolves: a cardioid with a disc stuck to it, and smaller discs on that, and filaments running out. The filaments are where the two behaviours meet, and every one of them is a place where a hair's difference in c is the difference between a connected Julia set and a cloud of dust.

Do not jump while you are looking at it. The jump key is bound to the same action that resets the field's zoom, so the whole thing re-rolls over your head.

<!-- @mandelbrot_dive -->

The instrument, on a table that floats a little off the floor: the same computation as a shader, live, with two sliders and four buttons. Zoom in anywhere on the boundary and there is more boundary, at every magnification, forever, and small complete copies of the whole shape appear inside the filaments, each one slightly distorted and unmistakably the same object.

There is a catch worth knowing before you use it. The pan controls answer to the same keys as walking, so on a desktop, crossing the room drags the fractal along with you. The instrument and the visitor are wired to the same hands.

<!-- @dark_sphere -->

A dark sphere pulsing on the floor at knee height, seventy centimetres across. In a room whose subject has no scale at all, it is useful to have one object whose size you can state.

<!-- @ -->

##### The honest cap

Every picture here is a lie about depth, and the lie is measurable. The field overhead runs its test a hundred times per point and then gives up; anything still bounded after a hundred steps is painted black and called a member. Some of those points are not members. They would have escaped on the hundred and first step, or the thousandth.

So the black region you are looking at is slightly too big, and it is too big in a way that depends entirely on a number somebody chose. Zoom the table in far enough and the boundary goes soft and blocky, not because the object ran out of detail but because the arithmetic ran out of digits. The object has infinite detail. Every image of it has a budget.

That is the chapter's last honesty, and it belongs here rather than in the halls before it. Recursion had a base case that stopped it. The Koch curve had a line thickness that hid it. Julia had a zoom that breathed. And the atlas of all Julia sets has an iteration cap, which is the same admission in its final form: the rule is infinite and every look at it is finite.

Next: compare two recursive constructions and explain exactly what each repeats.

### 103. Fractal Synthesis

[Live text](http://localhost:3003/compose?map=Fractal_Synthesis)

#### What, exactly, is repeated?

<!-- @cantor_set -->

Can you explain two recursive constructions without using their names?

Start at the Cantor display. Describe one step to another person, or say it quietly to yourself: take an interval, keep two shorter intervals at its ends, and repeat on each survivor. Point to an example of the input, the descendants and the gap. Then identify where the displayed construction stops.

Try the description without pointing. If it leaves the scale or position of the descendants unspecified, it could produce a different arrangement. A useful explanation needs enough information to reconstruct the relation, rather than merely recognise the finished picture.

Ask someone to follow your instruction using a short sketch, or imagine where their first uncertainty would arise. Did you specify whether earlier intervals remain as a record? Did you say how a descendant is positioned relative to its parent? These are not ornamental details when the aim is reconstruction. The displayed arrangement contains choices about presenting successive stages as well as choices about generating them. Separating those two sets of instructions helps explain why another display of the same construction could look different without implementing a different selection rule.

<!-- @recursive_tree -->

Move to the recursive tree and repeat the exercise. Here a branch produces smaller branches with altered directions and dimensions. Variation makes individual forks different, while a depth counter bounds the process. The tree stores its descendants in a branching structure; the Cantor display arranges successive stages in separate rows.

Look for three distinctions across the pair: what a call receives, what it creates, and what makes it stop. They connect these constructions without claiming that every fractal is a tree or every repeated pattern is recursive.

The Julia and Mandelbrot rooms added another kind of repetition: following numerical orbits and displaying the results of tests. Their boundaries were not made by placing miniature copies one by one. The visible resemblance across scales can therefore outlive a single recipe for producing it.

An extension worth trying would hide the names and give visitors two incomplete instructions. They could repair each instruction by looking closely at the corresponding construction. A wrong reconstruction would then identify a missing relation, not a failure to remember a label.

<!-- @ -->

In the next room, instructions become a path. We will ask how a finite sequence of turns can organise a line across an area, preparing the move from recursion into grammars.

### 104. Fractal CrossSequence

[Live text](http://localhost:3003/compose?map=Fractal_CrossSequence)

#### A line learns its way around

<!-- @space_filling_curve_gallery -->

How can one line visit many parts of a square without becoming a filled square?

Compare the three panels in the curve gallery. Choose a short stretch of line and follow its turns with your eye. Look for a larger region organised like a smaller one, then move to another panel and test whether its turning pattern is the same. Similar coverage can be produced by different orders of travel.

Follow a route until a tight turn makes you lose it, then resume from the last position you can identify reliably. Notice whether your difficulty comes from closely spaced segments, a repeated motif or uncertainty about direction. Those are different demands on a reader. Compare them across the panels without declaring the most visually dense image the best route. A path can order visits well for one purpose while being difficult to follow by eye. The representation's scale and line thickness participate in that difficulty alongside the construction itself.

The panels show finite Hilbert, Peano and Moore constructions. The generator expands symbolic instructions through repeated rewriting, then interprets the result as forward movements and quarter-turns. A string becomes a route because an interpreter gives its symbols spatial consequences.

This is a new way to read the repeated structures gathered in the previous room. Rather than directly placing a smaller copy of a mesh, the program first produces instructions. The line is drawn afterwards by following them. Changing an instruction and changing the interpretation of an instruction are therefore different operations.

The displayed panels are textures. They offer paths for your eye to follow; they do not provide collision geometry for a walking route. Their finite lines also leave gaps. The mathematical idea of a space-filling curve concerns the limiting construction, not a claim that this particular image has already visited every point of an area.

That distinction suggests a useful extension: display two successive construction depths at equal size, preserving a visible marker for their start and finish. Ask what changes in the order of visits, what changes in the remaining gaps, and what becomes too fine to follow.

<!-- @ -->

You can now carry a precise question into the grammar laboratory. If the drawn line is the result of a symbolic sentence, which changes come from rewriting the sentence, and which come from teaching its interpreter a different meaning for a symbol?

## L-Systems: Rules Grow Structure

### 105. LSystems Grammar Lab

[Live text](http://localhost:3003/compose?map=LSystems_Grammar_Lab)

#### Change the sentence, change the reading

<!-- @lsystem_editor -->

Can you change a drawing without changing the instructions it contains?

Choose a preset in the L-system editor. Leave GEN where it is and move ANGLE. Follow one branch as its direction changes. You have altered how a turning instruction is interpreted while keeping the generated sentence at the same generation.

Now hold ANGLE still and increase GEN by one. Look for added segments and repeated branch arrangements. This time the sentence itself has changed: another round of rewriting has replaced its symbols before the drawing begins.

Choose a branch near the beginning of the drawing as your reference during both changes. An angle adjustment should let you follow corresponding segments through a changed orientation. An added generation can introduce segments that have no one-to-one counterpart at the earlier level. Do not rely only on the bounding outline, which the display fits to its available space. Compare a local fork and the route leading into it. That gives you a more stable basis for distinguishing a changed interpretation from an expanded sentence when both alter the silhouette.

The curve gallery introduced a route described through symbols. Here the two stages of that process are available for comparison. First, an L-system rewrites a string. Each symbol in the old string is replaced according to the selected rule, with the replacements collected into a new string. Next, a turtle interpreter reads that result as movements, turns and saved positions.

The turtle is a travelling state: it has a position and direction. Drawing symbols move it while leaving a segment; turning symbols change its heading. Brackets save the state and later restore it, allowing a branch to finish before the turtle resumes elsewhere.

Watch the overall size carefully. The drawing is fitted into its display after generation. A more elaborate sentence may therefore occupy roughly the same space as a simpler one. Height alone cannot tell you how much rewriting has occurred.

The current editor offers presets and numerical controls, rather than a place to type any replacement rule. A useful extension would show the unchanged sentence beside two angle settings, then let you alter one replacement and predict its first consequence.

<!-- @ -->

In the next room, the travelling state carries more than position and heading. Branch length will change as the interpreter enters and leaves nested branches.

### 106. LSystems Growth

[Live text](http://localhost:3003/compose?map=LSystems_Growth)

#### What a branch inherits

<!-- @parametric_lsystem -->

How can a branch become shorter while another branch resumes at its earlier length?

Start near the base of the parametric tree and trace a route through several forks. Compare an early branch with one nested farther towards a tip. Then return your attention to the fork and follow its other descendant. Look for a repeated relation of scale, even where the directions differ.

At one junction, mentally mark the place where a branch begins. Follow that branch to its end, then return to the marked place and continue along another route. This is a spatial way to rehearse saving and restoring a state. Ask what information your rehearsal needed: a location alone would not tell you which direction to face or how long the next segment should be. The visible tree gives you those relations together; naming them separately reveals why the interpreter stores more than a collection of disconnected positions.

The grammar produces a string before the tree is drawn. Its interpreter carries numerical state as it travels: position, orientation, branch length and depth. Entering a branch saves that state, changes the length used by its descendants, and continues drawing. Leaving the branch restores the saved state so that another route can begin from the appropriate place and scale.

That restoration is easy to miss in a finished silhouette. Without it, the shortened length or altered direction of one branch could accidentally become the starting condition for its sibling. The saved state keeps a branch's local history from rewriting every route that follows it.

The turn variation is generated with a fixed seed. It introduces differences between branches while keeping this particular specimen reproducible. It does not mean the tree is responding to light, weight or the visitor's position.

The previous room let you distinguish rewriting from interpretation. This tree develops the second part: a symbol can act on numerical state, so the same kind of instruction has different dimensions at different nesting depths. That is a precise sense in which parameters participate in the construction.

<!-- @ -->

For an extension, compare two copies with identical grammar and seed but different length decay, keeping their scales comparable. Ask where the difference first appears and how it accumulates towards the tips. The next room will go further by letting an interpreter give an ordinary movement symbol an unfamiliar meaning.

### 107. LSystems Grammars And Curves

[Live text](http://localhost:3003/compose?map=LSystems_Grammars_And_Curves)

#### The turtle that reads sideways

<!-- @the_believing_turtle -->

Does an instruction say how it must be obeyed?

Compare the three drawings at the believing turtle. Find the version labelled with a twenty-five-degree turn, then its forty-five-degree neighbour. Trace an early fork in each and look for a corresponding fork farther out. They share a sequence of instructions, yet the increased turn changes how branches gather or spread.

Now inspect the drawing in which forward means sidle. Try to follow the same early sequence again. A familiar instruction has acquired another spatial consequence. The change can make correspondence harder to see without removing the shared sentence that links the drawings.

Begin your comparison close to the drawing's origin, where fewer previous turns have accumulated. Once you find a correspondence there, try carrying it farther along the sentence. A small difference in turning convention can produce a large separation after repeated use. That accumulation is easier to see when you retain a known starting relation. If correspondence becomes unclear, step back to the last fork you could match. You are comparing the consequences of successive instructions, so a local match is more informative than an overall resemblance between the finished outlines.

The display expands one L-system string and sends it to three interpreters. The interpreters read drawing and turning symbols and restore saved positions at brackets. Their turn settings and movement conventions differ. A symbol therefore has a role within an agreement; its printed shape does not contain an inevitable motion.

The parametric tree showed how numerical state changes the dimensions of an instruction. This comparison changes the convention by which an instruction becomes action. It gives you a practical way to question a default: retain the sentence, change what one symbol does, and examine what remains recognisable.

The comparison has limits. The drawings use slightly different step lengths and a finite segment cap, so their overall sizes are not a controlled measurement of angle alone. Focus first on the correspondence between local instructions and local changes of direction.

A further interpretation might make forward leave a sound at each reached position, or place a mark without drawing the connecting segment. Before building it, decide which relation you want to preserve and which you want to disturb.

<!-- @ -->

Next, the same separation between sentence and interpreter turns branches into rooms and corridors. The question becomes what an architectural reading adds to a grammatical one.

### 108. LSystems Architecture

[Live text](http://localhost:3003/compose?map=LSystems_Architecture)

#### When a branch becomes a corridor

<!-- @lsystem_dungeon -->

What makes a branching line become a plan for a place?

Look across the dungeon model and choose a corridor near a junction. Follow it until it ends or meets a room. Return to the junction and take another branch with your eye. Notice where the repeated arrangement resembles a tree, and where walls and floor slabs encourage you to read it as architecture.

Choose a place in the model where someone might pause, then describe the route needed to reach it from a visible approach. Count the decisions at junctions separately from the length of the route. A long corridor can require few choices, while a short route through several branches can be difficult to explain. The model gives you a chance to notice both without first assuming that more branching creates a richer experience. Its generated plan still needs to be read in relation to an activity and a person undertaking it.

The model begins with a grammar. Rewriting produces a sentence; a turtle turns that sentence into segments and room positions. Another stage gives those records corridor geometry, walls and floor pieces. The completed arrangement is fitted into the display.

Each stage makes a different decision. The grammar organises repetition, the interpreter determines directions and connections, and the geometry supplies width and enclosure. Calling a segment a corridor does not collapse those decisions into a single instruction.

The previous room changed the meaning of forward. This room gives forward an architectural use. That interpretation is productive: a branching structure can suggest routes, pauses and destinations. It also brings requirements that the grammar did not automatically solve.

A route shown in a model may be too narrow to traverse at another scale. A dead end may be inconvenient, useful for privacy, or an excellent place to gather. The calculation has not decided those uses merely by reaching a terminating symbol. Nor does a large room count tell you whether a place is welcoming or legible.

For a variation, keep the grammatical connections and redesign one dead end as a shared destination. Compare the route before and after giving that end a purpose. The useful question is not only whether the grammar generates more space, but what someone can do there.

<!-- @ -->

The next room adds conditions that interrupt generation itself. A tree will need access to a resource before its next grammatical instruction can become growth.

### 109. LSystems Competition

[Live text](http://localhost:3003/compose?map=LSystems_Competition)

#### A rule waits for resources

<!-- @ForestCompetition -->

Why might two trees with similar instructions stop at different stages?

Watch neighbouring trees in the forest competition display. Choose two whose positions you can keep track of, and compare their branch development over several growth steps. Attend to the soil display and the recorded health alongside the trees. A change in form may follow a change in conditions rather than a new grammar.

Choose neighbouring trees you can distinguish by position, rather than switching attention to whichever changes most dramatically. Compare the order of their visible growth with their recorded condition. If one pauses, continue observing long enough to distinguish a temporary wait from an apparent end. Also notice whether your first impression of success depends on height, branch count or the health display. Those measures need not tell the same story. State which one you followed before attributing a different outcome to access to the shared field.

This forest places rewriting inside a larger process. Nutrients diffuse and replenish across a field. Trees take turns attempting growth, consume nutrients near their roots, and update a health record. A tree advances its grammar only when sufficient nutrients are available and the simulated season permits it.

The order of attempts matters as a condition too. The model visits trees in a round-robin schedule; it does not give every root access to a perfectly simultaneous, undiminished supply. Spatial position and update timing can therefore affect what a shared resource permits.

The dungeon model generated a complete plan from a sentence. Here the sentence's development can be delayed or curtailed by the environment in which it runs. The grammar remains part of the explanation, but it is no longer the whole explanation.

The display's health is a quantity defined by this model. It is not a biological measurement, and an imposed generation cap is not evidence that a tree has reached ecological maturity. To explain a stopped specimen, distinguish exhausted opportunities, seasonal pauses and the calculation's own limit.

A useful extension would compare competition with a rule that redistributes some resources among neighbours. Keep the initial soil and trees fixed, then choose what to measure: total growth, the smallest surviving tree, or unevenness across the forest. Different measurements can favour different arrangements.

<!-- @ -->

Next, you will meet a tool that puts the tree's parameters directly into your hands. Ask which forms become easy to request and which have no control at all.

### 110. LSystems Living

[Live text](http://localhost:3003/compose?map=LSystems_Living)

#### The tree the controls permit

<!-- @genetic_tree_sculptor -->

Which part of this tree can you ask to become different?

Begin with the preview at the genetic tree sculptor. Move Angle a little and wait for the tree to rebuild. Compare a branch before and after the change. Return the slider near its earlier setting, then try Depth or Forks. Change one control at a time so that you can name a cause for the difference you see.

Compare Angle and Depth through one recognisable fork in the preview. Angle asks you to track a changed direction; Depth can add further descendants beyond a route that previously ended. The same increase in visual complexity can therefore have different causes. Wait for each rebuild before making the next adjustment, and keep a mental reference to the earlier fork. If the overall preview changes scale or becomes difficult to follow, return to a local branch relation rather than treating the outer height as a direct measurement of a gene.

Angle changes the interpreter's turns. Depth changes the number of rewriting generations, while Forks changes the branching structure encoded by the grammar. Taper, Leaves and the remaining controls provide other bounded ways to alter the result. The preview is a reading of that parameter set, rebuilt after a short delay.

The tool calls its parameters genes. Their values are translated into an L-system and the geometry made by its turtle. That mapping is an authored model: a number becomes a permitted branch angle or a probability of placing leaves because the generator assigns it that role.

RANDOM supplies another parameter set. It does not, by itself, select descendants through generations of competition. Likewise, PLANT records the current design for other systems to use; pressing it here is not evidence that a new tree has already appeared in the museum.

Compare this direct design with the resource-constrained forest. There, conditions affected whether growth could proceed. Here, the controls make certain descriptions easy to request, while their ranges and the generator limit what can answer.

An extension could give the same parameter values to two different mappings, then ask which tree better serves a chosen purpose: shade, shelter, climbing or simply an unfamiliar shape. A form need not be judged only by the criteria already built into a search function.

<!-- @ -->

The next room strips generation down to two marks and a repeated choice. Watch what your eye contributes when the available alphabet becomes that small.

### 111. Assemblage Same Desire

[Live text](http://localhost:3003/compose?map=Assemblage_Same_Desire)

#### Two marks, many paths

<!-- @ten_print_textile -->

When you see a path in this textile, who connected its pieces?

Watch a new row enter the display. Each small position receives one of two diagonal marks. Choose several neighbouring marks and follow the line your eye makes through them. Then watch another row appear and notice how a new choice can extend, interrupt or redirect the apparent route.

Trace one apparent route until it reaches a place with more than one possible continuation. Pause and name the choice your eye makes there. Then trace the same area beginning from the other end. You may group the marks differently even though their arrangement has not changed. This is a useful way to notice the reader's contribution without dismissing the image's real constraints. A diagonal meets some neighbouring marks and misses others; your reading selects among those relations rather than connecting absolutely anything to anything else.

The generator makes a separate random choice at each position. With the current settings, either diagonal has the same chance. The rows accumulate and scroll, giving those independent choices a shared surface on which relations become visible.

Nothing in that local choice searches for the entrance or exit of a maze. There is no instruction asking whether your chosen path remains connected. The maze-like appearance arises from the geometry of the marks, their adjacency and the way you read them together.

The grammar rooms distinguished a sentence from its interpretation. This loom gives that distinction another setting. A repeated selection process works through a small alphabet, and the shape of that alphabet strongly affects what the results invite you to do. Two diagonals encourage following; other marks could encourage counting, grouping or seeing a woven density.

The paths can be real features of the image without being planned routes. Yet a recognisable route should not be mistaken for evidence that the system has solved a navigation problem. Your reading and the generator's operation are different contributions to the encounter.

A useful variation would preserve a recorded sequence of choices while replacing the two diagonals with two orthogonal marks or two kinds of block. Ask what remains the same when the decisions stay fixed but their material expression changes.

<!-- @ -->

The next sequence begins with selection of another kind: generated forms are compared using a numerical score. Keep the distinction between a procedure's choices and the purposes a viewer finds in their result.

## Procedural Generation: Rules Build Worlds

### 112. PG Genetic Evolution

[Live text](http://localhost:3003/compose?map=PG_Genetic_Evolution)

#### What would you keep?

<!-- @GeneticProgramming -->

Which of these generated forms would you choose to keep, and why?

Compare two candidates in the genetic programming display. Choose a reason before looking for a score: perhaps an opening, a balance between parts, an awkward projection or a shape you cannot readily name. Then ask whether the scoring rule has any way to notice your reason.

Look for a candidate with overlapping parts and compare it with one whose parts are more clearly separated. Describe what you can establish from the visible silhouette and what remains hidden behind it. Then revisit your original reason for preferring a form. Was it a property of the complete volume, an opening visible from one angle, or an association prompted by its shape? The distinction helps locate where a score and a visitor's judgement consult different evidence, even before deciding whether either criterion should be changed.

The candidates are descriptions assembled from geometric primitives. The current fitness calculation rewards closeness to a target volume. It estimates a candidate's volume, compares that estimate with the target and gives a higher score to a smaller difference. A good score therefore has a specific meaning. It does not mean that a form is generally better, more useful or more interesting.

The estimate adds the volumes of individual primitives. Where two primitives overlap, their shared region is counted more than once. The score consequently describes the estimate the program actually uses, rather than an exact measurement of the visible union.

When an evolution step is run, the process retains selected candidates, chooses parents through small tournaments, combines descriptions and sometimes mutates them. Those operations make a new population available for another comparison. The current initial display can teach the representation and the criterion; demonstrating improvement over time also requires a visible sequence of generations.

The textile in the previous room made independent choices without evaluating their result as a maze. This search adds evaluation, but the purpose still comes from the criterion supplied to it.

<!-- @ -->

A useful extension would preserve one rejected candidate nominated by a visitor, alongside the numerical winner. Give the nomination a reason the score ignores. Then expose one generation step and inspect what selection retains or loses. The next room replaces a single score with many spatial targets, letting local growth respond to their distribution.

### 113. PG Space Colonization

[Live text](http://localhost:3003/compose?map=PG_Space_Colonization)

#### A shape waiting in points

<!-- @space_colonization_algorithm -->

Can a branch follow a shape that exists only as a distribution of points?

Trace the space-colonisation specimen from its base towards a tip. Compare the direction of a branch with the nearby attraction points. Then inspect another tip whose surroundings differ. The displayed construction is already generated when you arrive, so use the remaining points and branch relations to reconstruct possible decisions rather than expecting to witness every step.

At a fork, compare the two descendant directions with the points you can still see around them. A branch may look as though it aimed at one point even when its direction combined several requests at the time. The finished arrangement alone can leave that history uncertain. Mark the difference between an explanation consistent with the specimen and a decision you actually observed being made. This matters when a tidy final tree encourages an equally tidy story about a sequence whose earlier targets have already disappeared.

At each growth iteration, an attraction point is assigned to its nearest eligible branch tip within an influence distance. Points close enough to have been reached are removed. For each participating tip, directions towards its assigned points are accumulated; their combined direction determines a new short segment.

No point supplies a complete branch plan. Several local requests can pull a tip towards an intermediate direction, and subsequent steps encounter a changed arrangement of remaining requests. The finished branching form records those repeated negotiations.

The genetic display evaluated whole candidates with a score. This procedure distributes its demands through space. The choice of target distribution is still an act of authorship, even though no one separately draws each resulting branch.

There is an evidential difficulty in the finished object: reaching a point removes it from the calculation. The form does not preserve all of the targets that guided earlier decisions. A gap in the visible points can therefore be a record of successful contact rather than a region that never mattered.

A useful extension would keep reached points as faint witnesses and compare two starting positions inside the same target field. Ask which branches correspond, which targets become difficult to reach, and whether a different beginning changes what counts as a completed form.

<!-- @ -->

The next room turns from growing towards points to finding a connected route among occupied sites. A crowded field will not necessarily be a connected one.

### 114. PG Percolation Network

[Live text](http://localhost:3003/compose?map=PG_Percolation_Network)

#### Enough cells, or the right connections?

<!-- @percolationnetwork_ca -->

Can a dense cluster remain unreachable from a nearby source?

Locate the source in the percolation display and follow the changing flow colours away from it. Look for an occupied cluster that remains unreached. Compare the gap separating it from the flow with the size of the cluster itself. Many occupied sites can be close together without making the particular chain this system requires.

Find two occupied sites that appear close from your current viewpoint and examine how they meet. A shared face, an edge and a corner can all look like contact in a crowded projection. Move sideways to distinguish them before predicting whether flow should cross. Then compare the prediction with the changing display. This small check makes the neighbourhood definition something you can use, rather than a fact to memorise. It also explains why an apparently tiny missing connection can separate large clusters that each contain many occupied cells.

Here, connection is defined through the six faces of a cell. A neighbour across a face can carry flow onward; merely meeting at a corner does not create the same relation. Occupied cells activate when an eligible neighbour carries flow, while the source continues to supply it.

Updates use a separate next-state buffer. That makes one step a reading of the current field rather than a cascade whose reach depends on which cell happened to be visited first in a loop. A spreading front can therefore be understood as a sequence of local transfers.

The attraction points in the preceding room guided the construction of new branches. This field begins with occupied sites and asks which are connected to a source under a specified neighbourhood relation. Quantity and connectivity are different properties.

One displayed sample cannot establish a universal density at which connection begins. The field's size, boundary, neighbourhood and random arrangement all affect the observation. Nor does a highlighted chain automatically provide a route for a museum visitor: some flowing cells are drawn without collision.

A useful extension would repeat several seeds at each occupation setting and mark whether the source reaches an opposite boundary. Before calling a result a threshold, decide what counts as reaching and which boundary matters.

<!-- @ -->

Next, a branch will again seek a target. Compare that choice with both the shared influences of space colonisation and the strict adjacency that controls flow here.

### 115. PG Branching Growth

[Live text](http://localhost:3003/compose?map=PG_Branching_Growth)

#### The nearest invitation

<!-- @branching_growth_algorithm -->

Which target does a growing tip appear to follow?

Watch an active tip in the branching growth display. Locate the nearest visible attractor it has not reached and compare the tip's next direction with the direction towards that point. Follow a few steps, then choose another tip with a different arrangement of targets. If growth has finished, trace a branch back through its bends and identify where a nearer invitation might have taken over.

Choose a bend rather than an entire branch as the unit of your observation. Compare the direction entering the bend with the direction leaving it and the targets visible nearby. A long branch can combine many local choices, so its final orientation is not a reliable account of any single step. Where two targets look similarly close, note the uncertainty instead of treating your estimate as the generator's exact distance calculation. Changing viewpoint can improve your reading of their positions without recreating the complete history of which targets remained active.

This generator chooses a nearest unreached attractor for a growth tip. It normalises the direction towards that target, introduces variation and advances by a short step. The process records parent and generation information as it adds branches. Reached targets cease to make the same request, while distant or exhausted opportunities can leave a tip without a further step.

That is a different rule from the earlier space-colonisation specimen. There, several assigned targets contributed to a combined direction. Here the nearest target supplies the main direction before variation is added. Similar tree-like outlines can conceal this difference in what a tip consults.

The percolation field made contact depend on a fixed neighbourhood. This growth process makes relevance depend on distance and target status. In both cases, the relation called local has been chosen; it is not simply whatever happens to look nearby to a visitor.

A stopped branch also needs careful interpretation. The demonstration has a branch limit that bounds the work it performs. Reaching that limit is different from proving that no target remains or that the form has reached a natural maturity.

<!-- @ -->

For an extension, place nearest-target and averaged-target versions over the same points and starting position. Preserve ignored targets visibly so that the comparison can explain a choice, not just display two silhouettes. The next room lets a moving process leave its record by removing material instead of adding branches.

### 116. PG Caves Mazes

[Live text](http://localhost:3003/compose?map=PG_Caves_Mazes)

#### A route cut into a solid

<!-- @caverandomwalk -->

Can you read the memory of a walk in the space it removed?

Examine an opening in the cave model from the museum floor. Follow the passage with your eye as far as the view permits. Look for a widening, a change of direction or a junction with another passage. Then change viewpoint and test whether the apparent connection continues behind the foreground wall.

Compare a narrow stretch with a junction where two passages seem to meet. Try to distinguish a wider carving neighbourhood from the overlap of several visited regions. Either can produce extra empty space, but they imply different histories. An opening viewed from outside may not let you decide between them. State that uncertainty while continuing to trace the boundary you can see. Reconstructing a procedure from its result is an investigation: several sequences of movements can leave a similar passage, and a finished model does not display every earlier step.

The generator begins with a solid grid. A moving carving position marks nearby cells as empty, sweeping out a passage rather than placing its walls individually. The carving operation also clears a region above the route to provide intended headroom.

Several starting positions approach from different sides. Their movements are biased towards a central region, followed by wandering through higher levels. The fixed seed makes this particular outcome repeatable. The term random walk therefore needs qualification: randomness enters a route whose starting points, directional preferences and stages are already organised.

The branching room added material along successive choices. Here the same broad relation between a trajectory and a form is inverted: the visited region becomes absence. The remaining solid gives that absence a boundary.

Connectivity in the grid is only one part of evaluating the result. The displayed scale, passage width, headroom and collision geometry determine whether a person could use the route. A connected chain of empty cells cannot answer all those questions, and this model need not be entered to study its construction.

A useful extension would preserve one coloured walker trace inside the finished cave. Compare a centre-seeking version with one whose walker avoids the centre, keeping its step budget and carving radius fixed. The difference would make the destination's influence visible.

<!-- @ -->

The next room also turns an event into geometry, but takes its starting arrangement from falling physical bodies rather than a deliberately carved path.

### 117. PG Sculpted Forms

[Live text](http://localhost:3003/compose?map=PG_Sculpted_Forms)

#### Keep the pile, change the record

<!-- @cube_mound_scene -->

When a pile becomes a generated surface, which details of the pile survive?

If the cubes are still falling when you arrive, watch how their contacts redirect the next ones. Then compare the settled arrangement with the surface produced around it. If the capture has already happened, look for block-like features and ask which might correspond to a cube's position rather than its precise orientation.

Choose a projecting corner or a shallow recess in the generated surface. Compare it with the block positions still available to inspect, rather than assuming every visible face belonged to an original cube. Then look for a region where several nearby centres could contribute to one connected patch. The same surface can retain a coarse memory of the pile while losing the identity of its individual bodies. Describing one retained relation and one uncertain detail makes that change of representation more concrete than simply calling the result a smoother pile.

The scene first releases separate rigid bodies. It waits until they appear to be sleeping or a settling time has elapsed, then begins another stage. That stage reads their centres, marks a grid around those positions and builds the exposed faces of the occupied cells.

The surface is therefore a geometric interpretation of a physical arrangement. It is not an exact union of every rotated cube. Corners and contact details can change when continuous positions are converted into occupied grid cells.

The cave preserved a record of carving. This mound preserves a record of a selected moment in a simulation. In both cases, a later representation retains some information while discarding other information. Knowing what was sampled helps explain why the resulting shape differs from the process that produced it.

The stopping condition matters. A time limit can trigger capture even if a cube has not fully settled. The generated form should not be treated as proof that the original pile had reached a unique equilibrium.

An extension could retain the cubes and the generated surface as alternate readings, with a visible capture time. Hold the release fixed and compare an early capture with a later one. That would make the choice of when to record as available for inspection as the choice of how to record.

<!-- @ -->

The next room asks a related question about copying: which parts of a patterned field are newly computed, and which come from repeating an earlier fragment?

### 118. PG Mirrored Patterns

[Live text](http://localhost:3003/compose?map=PG_Mirrored_Patterns)

#### Where the repetition begins

<!-- @mirror_cellular_texture_for_3d -->

Which part of this regular pattern was invented once and then repeated?

Look closely at the patterned plate. Choose a small motif with a distinctive corner or gap and search for another occurrence. Follow its boundary into a neighbouring region. Compare the relation inside the motif with the relation between one copy and the next.

Use a distinctive gap as a marker and search for it in a neighbouring repeated region. Check whether its orientation is preserved or reflected before calling the regions identical. A copy and a mirror image can share many features while arranging handed relations differently. If the field updates during your inspection, keep that time change separate from the spatial comparison. You may otherwise compare one region before an update with another afterwards and attribute the difference to symmetry. A careful reading names both where and when the two samples were observed.

The current arrangement begins by generating a small five-by-five motif and using a symmetry operation to repeat it across a larger field. A cellular process can subsequently update the displayed cells. These are separate stages: choosing initial values, arranging their copies and allowing local updates to act on the resulting field.

That separation gives you a way to examine a strikingly regular image without assuming that local evolution discovered its symmetry unaided. The construction already supplied a repeating initial arrangement. A later pattern inherits conditions that were chosen before its first update.

The cube mound turned a physical arrangement into a sampled surface. Here an intermediate result also becomes material for another operation. The motif is not the finished field, just as the pile's recorded centres were not the finished mesh.

Symmetry can make a large display legible, but it can also hide where independent choices stopped. Two matching regions may look like evidence that the same event happened twice when they are copies of a single event. Following a distinctive detail across the field helps make that distinction concrete.

A useful extension would keep the initial random choices fixed and compare an unrepeated field with quadrant, octant and motif arrangements. Let visitors choose whether repetition should be preserved, interrupted or used as the basis of a new composition. The useful criterion need not be maximum regularity.

<!-- @ -->

The next sequence moves into soft bodies. There the form will continue to change after it is generated, as its internal constraints and its encounters with the surrounding space act on it.

## Soft Bodies & Morphogenesis: Matter That Finds Its Shape

### 119. SoftBodies Soft Body Deformation

[Live text](http://localhost:3003/compose?map=SoftBodies_Soft_Body_Deformation)

A shape is only a rest configuration, and the springs keep renegotiating it with whatever arrives.

This chapter asks one question of a deformable body and answers it outward: who decides the form? Here the answer is the material itself. Nothing in this room is being shaped by anything except its own internal tension and the floor.

```gdscript
for s in springs:
    var diff: Vector3 = positions[s.b] - positions[s.a]
    var cur: float = diff.length()
    var pull: Vector3 = diff.normalized() * (cur - s.rest) * stiffness
    velocity[s.a] += pull
    velocity[s.b] -= pull
```

Every spring wants one length and pulls both its ends toward it. No spring knows the shape. There is no shape anywhere in the code, only a rest length repeated a few hundred times, and what you see is the standing disagreement between all of them and gravity.

##### The body on its own

<!-- @jelly_cube -->

A green cube of jelly on a plinth, hanging just under half a metre clear of the floor. Push a hand into it and it gives and comes back. This is the chapter's first claim, and it is worth pressing more than once: the cube has no stored shape to return to. It returns because the springs are still pulling, and the returning is not a memory, it is the same argument continuing.

There is no update loop anywhere in its script. Everything you see moving is the physics solver, working on the mesh, all the time.

<!-- @jelly_variants -->

The same cube, five times, in a row two metres long, with fifteen sliders and ten buttons crowded between them. Stiffness, damping, pressure. Turn one and the same object becomes a different material, and the interesting reading is at the ends: soft enough and it stops behaving like a solid and starts behaving like a bag of liquid; stiff enough and it stops deforming at all and is simply a box.

Nothing was swapped to get there. It is one number, and the categories we have names for are regions of it.

<!-- @ -->

##### The body under a machine

<!-- @softmill -->

A stand with two pink bars turning at thirty degrees a second, one revolution every twelve seconds, and a specimen hanging above them. Watch it a while and you will see the bars pass through the specimen without touching it.

That is not a rendering fault. The long arm is on one collision layer and the soft body listens to another, so the two are transparent to each other by arithmetic. The mill is here to be the outside force, the first thing in the chapter that would decide a form from outside the material, and it misses. Take it as the chapter's own timetable: the encounter is two rooms away, and here the body is still alone with itself.

<!-- @science_screen -->

A screen floating with the foot of its stand a metre and a half above the floor, set to draw a field map. It reads nothing in this room and says so: the panel is labelled SOURCE: DEMO, and the field rippling across it is the screen's own test pattern.

<!-- @radiolaria -->

In the corner, nine glass skeletons that do not belong to this argument yet. They are the geometric skeletons that a later room will return to; here they stand early in the chapter, before the comparisons that make their role clearer. Look at them and move on; the sentence that makes sense of them needs the rest of the walk.

<!-- @ -->

##### Rest is a negotiation

The word for the shape a soft body holds is the rest configuration, and both halves of that are misleading. It is not rest: the springs are pulling the whole time, and the stillness is a balance of pulls rather than an absence of them. And it is not a configuration in the sense of a plan, because nothing anywhere holds a picture of the cube. There is a list of rest lengths and a solver, and the cube is what those two produce when they are left alone together.

Which is why the cube comes back when you push it, and why turning one slider by a tenth turns a solid into a fluid. The form was never a thing the material had. It is a thing the material is doing.

Next: the same body, in a field that will not leave it alone.

### 120. SoftBodies Carusell

[Live text](http://localhost:3003/compose?map=SoftBodies_Carusell)

Rotation makes a force field legible through softness: every point of a hanging body reads out a force you could not otherwise see.

You arrive inside the machine. The spawn puts you under four metres from the axis of a carousel three metres across, close enough that the soft bodies sweep past at chest height about half a metre clear of you. Stand still for one revolution, six and a quarter seconds, before you do anything else.

```gdscript
func _physics_process(delta: float) -> void:
    ride_hub.rotation.y += ride_speed * delta
```

That is the entire machine. One rotation applied to one hub, and everything hanging under it works out its own consequences.

##### The field, made visible

<!-- @revolving_joy_ride -->

A torus overhead turning once every six seconds, four arms of chained capsules hanging from it, and four soft spheres half a metre across swinging at the bottom of those arms. Nothing tells the spheres where to go. They are dragged by the arms, the arms are dragged by the joints, and the angle each arm hangs at is the balance of the pull inward and the swing outward at that radius.

A rigid arm would tell you nothing: it would simply be where it was put. The softness is the instrument. The bodies are being deformed by exactly the force at their radius, so their shape is a reading of a field that has no appearance of its own.

Two of the four arms sweep through the room's own wall pillars on every revolution, and the twelve frosted posts ringing the ride stand five metres tall against walls of two, sunk half a metre into the floor. The ride was built for a bigger room than this one.

<!-- @cloth_straps -->

Ribbons of cloth hanging from gantries, and you can walk through them. This is the gentlest measurement in the room: the cloth reads whatever is moving nearby, including you, and goes on reading it for a second or two after you have passed. A field written on a surface that keeps a short memory of it.

<!-- @soft_mushroom -->

Fifteen mushrooms, each a rigid stem with a soft cap pinned to the top of it. Push a cap and it wobbles and settles; the stem does not move at all. One object, two materials, and the join between them is where you can feel the difference: the same push does nothing to one half and everything to the other.

<!-- @flex_cloth_pad -->

A small hanging cloth on a pedestal, rebuilt point by point every frame. It sways gently and nothing here disturbs it. Of everything in this room it is the only soft body that is not reading a force from something else, which makes it the control.

<!-- @ -->

##### What you can pick up

<!-- @grab_long_stick -->

Two rods lying on the floor, and the only things in this room a hand can actually take. Pick one up and you can put a force into the field yourself: swing it through the ribbons, prod a mushroom cap. Everything else here reads forces. This is the one object that makes them.

<!-- @pick_up_cube -->

Three cubes hovering and turning near the west gap. You cannot carry these, despite the name. Walk into one and it is gone with a chirp and the count goes up by one.

<!-- @synthesis_stand -->

And the same cube's family on a plinth: five stocks of one object, ruled a series by measurement, with the far end of the ladder stood up as its representative. A cabinet card in a room full of things in motion.

<!-- @ -->

##### Softness as an instrument

A force field is nothing you can look at. It has no surface, no colour and no edge, and the only way to see one is to put something in it that responds and then watch the response.

That is what this whole room is. The carousel does not demonstrate rotation; you could demonstrate rotation with a rigid bar. It demonstrates the field the rotation creates, and it does that by hanging things in the field that cannot help showing it. Every deformation you can see is a measurement, taken by a body that has no choice about taking it.

The chapter's question was who decides the form. In the last hall the material decided alone. Here the field decides, and the material is what makes the decision visible.

Next: what happens when the thing it meets pushes back.

### 121. SoftBodies Obsticals

[Live text](http://localhost:3003/compose?map=SoftBodies_Obsticals)

When soft meets hard, collision is not an instant but a negotiation that unfolds over time.

A rigid body's collision is a moment: it arrives, a number is computed, it leaves changed. A soft body has no such moment. It arrives, and then for the next second the news of the arrival travels through it, spring by spring, and what happens at the far side depends on everything in between. This room is twenty metres square and mostly empty so that you can watch that take its time.

```gdscript
if p.y < floor_h:
    positions[i].y = floor_h            # the contact is a constraint, not an impulse
```

The whole of collision, for a soft body, is that: a point that has gone somewhere it should not be is put back, and the springs attached to it spend the following frames arguing about what that means for everyone else.

##### The rack

<!-- @softbody_gallery_part2 -->

The south half of the room is a drop rack, twelve cells of magenta wireframe with soft spheres falling onto them every couple of seconds, six columns of different stiffness. Stand at the end of the row and look along it, because the row is the experiment: the same fall, the same frame, and a different material each time.

The soft ones spread across the wire and take a full second to decide what shape they are. The stiff ones bounce and keep their corners. Somewhere in the middle a sphere lands, holds an obviously wrong shape for a moment, and then remembers. That interval is what the room is about, and it exists only because the material has to pass the news along.

One warning: pressing the jump key reloads this map. The rack listens for it.

<!-- @breathing_room -->

Two grey slabs standing across the north corner, four metres high and seven long, with a five-metre gap between them. They are named for the thing they do not do. The scene loads a version of the script with no update loop in it at all, so there is no breathing, no expansion and no contraction: two walls, still, forever. Its twin slab stands outside the room, behind the north wall.

Take it as the room's honest failure. A corridor whose walls close on you would have been the hard case of this argument, where the negotiation has no way out. What is here instead is the geometry of that idea with the time taken out.

<!-- @flagdancer -->

A rainbow flag rippling along the north wall, its bottom two metres below the floor and two metres of its width inside the wall. It looks like the softest thing in the room and it is the only one with no physics whatsoever: seventeen bones driven by sine waves, no cloth solver, no forces, nothing to collide with. It cannot be touched and it does not respond.

It is worth standing in front of for exactly that reason. It is what soft looks like when it is animated rather than simulated, and next to the rack, which is genuinely negotiating, the difference is visible without being told. One is obeying a curve. The other is working something out.

<!-- @pick_up_cube -->

A black cube in orange wireframe turning and bobbing beside the slabs. Walk into it and it is gone.

<!-- @grab_long_stick -->

A rod on the floor by the south wall, and the only object here a hand can take. Carry it into the rack and you become the hard thing in the encounter. That is the room's best use of a minute: hold something rigid, push it into something soft, and watch how long the answer takes to arrive.

<!-- @ -->

##### Resistance is morphology

An obstacle does not stop a soft body. It reshapes it, and the shape it leaves is a record of the meeting: where the contact was, how stiff both parties were, how long they were in touch.

That is why the negotiation matters more than the moment. A rigid collision destroys its own evidence, resolving into two new velocities and nothing else. A soft collision leaves the encounter written into the object, for as long as the springs take to argue it away, and sometimes longer.

The chapter has now had three answers to who decides the form. The material alone. The field it hangs in. And here, the thing it runs into. The next gallery keeps contact in view while changing its surfaces and configurations. Compare the setup before assigning the result to a property of the body.

Next: softness meets a different surface.

### 122. SoftBodies Obsticals Part2

[Live text](http://localhost:3003/compose?map=SoftBodies_Obsticals_Part2)

#### Softness meets a different surface

<!-- @softbody_gallery_part2 -->

Does a changing shape tell you only about the body that changes?

Compare the stations labelled Bouncy Collider and Slippery Collider in the soft-body gallery. First inspect their arrangements: the surface under the body, its angle and the place from which contact begins. Then look at the body's movement or settled pose. Keep the setup in your explanation of the result.

Read two station labels before comparing their results, then list the differences you can see in the setups. If both the surface angle and the body shape differ, keep both in your account. You can still make a useful observation without claiming a controlled experiment: one configuration concentrates contact at an edge, while another spreads it across a broader region. The next question is which difference to isolate. This turns the gallery into a source of testable comparisons rather than a collection of appearances ranked from lively to dull.

The bouncy station gives the collider a high bounce setting. The slippery station places a body against a ramp whose friction is set to zero. Other stations change contact geometry or the body itself: a torus, a prism, a corner strike, altered drag, pressure or stiffness. Together they offer a collection of encounters, not a row in which every neighbour differs by only one variable.

The previous room introduced contact as something whose effects continue through a deformable body. This gallery widens the question. What looks like a quality of the specimen can also depend on the shape and material settings of what it meets.

Choose a torus or a corner-strike example and describe where contact is concentrated. A different initial contact can distribute deformation differently even before you change the body's material parameters. Shape, release, environment and numerical settings participate in the observed response.

A station label names its configuration; it is not a measurement of how much energy was returned or lost. Nor should the most dramatic motion automatically be called the softest material. Several changes can contribute to the same visible result.

<!-- @ -->

A useful extension would pair identical bodies with the same release and vary only collider friction. Preserve a small witness of the starting pose so visitors can check the comparison. The next room asks about another condition that changes the result: the moment at which an experiment is stopped, and what stopping actually does.

### 123. SoftBodies Cloth Physics

[Live text](http://localhost:3003/compose?map=SoftBodies_Cloth_Physics)

#### A stopped experiment

<!-- @softstopscene -->

If a body has almost stopped moving, has it settled, or has the experiment intervened?

Compare the four soft bodies arranged in a square. Look for differences in outline and any remaining movement. If their release is still underway, keep one specimen in view as its timer reaches the stopping intervention. If you arrive later, treat the resulting poses as records whose histories you have not fully seen.

Choose two specimens and distinguish three observations: their current outlines, any motion still visible, and whether you witnessed the stopping moment. These do not provide interchangeable evidence. A still pose can show a deformation clearly while concealing how it arose. If you did see the intervention, compare the rate of change just before and after it rather than relying only on the final position. The square arrangement makes comparison convenient, but convenience alone does not establish that all differences between the bodies came from their scheduled stopping times.

The bodies begin in a shared release arrangement, but their timers intervene at different moments. Each intervention disables the body's processing and changes its damping and stiffness sharply. The intention is to arrest a changing form, but increasing damping and stiffness is not the same as preserving an exact mathematical snapshot of every physical state.

The contact gallery showed how the environment helps determine a deformation. Here, the schedule and conditions of observation also matter. A pose can be the result of an ongoing response, a natural settling process, or a deliberate change in how the simulation continues.

The room's cloth lesson still needs a pinned sheet or another clear cloth specimen. These four bodies provide a narrower encounter with stopping and deformation. They cannot establish how a sheet drapes between supports or how a pin constrains neighbouring fabric.

That gives the next improvement a concrete shape. Add a sheet held at two points, with an initial pose and a visible clock. Compare its uninterrupted fall with an otherwise identical run that is heavily damped at a chosen moment. Then release one support and ask which changes come from boundary conditions and which from the stopping intervention.

<!-- @ -->

For now, keep your explanation close to the four bodies you can inspect. The next room adds diagnostic colours and controls, asking how a measurement can help you distinguish changes that a silhouette alone leaves ambiguous.

### 124. SoftBodies Playground of Joy

[Live text](http://localhost:3003/compose?map=SoftBodies_Playground_of_Joy)

#### What the colour measures

<!-- @rounded_softbody_test -->

When this body changes colour, what has actually changed?

Look at the rounded specimen beside its reference outline. Find a region whose current position differs from the resting form, and compare its colour with a less displaced region. Use MODE to inspect another reading, then return to the strain display. After that comparison, vary STIFFNESS while leaving the other controls alone and watch the response.

Select one part of the body and compare it in the strain view and with the readout removed. Keep your viewpoint similar so that a change in silhouette does not come merely from moving around it. Ask what the colour made easier to locate and what you can still establish from shape alone. Then inspect another region whose outline changes less obviously. An overlay can draw attention to a numerical difference you might otherwise miss, but that attention is guided by the quantity and colour mapping chosen for the display.

The strain display calculates an energy-like quantity from each point's displacement from a captured rest position and the selected stiffness. It maps those values to colour using a running maximum. Red therefore means high within that evolving display scale; it is not a fixed unit of damage, pain or permanent change.

Changing stiffness affects both the body's behaviour and the scale of the quantity being calculated. You cannot establish that two settings store the same amount simply because they produce the same colour. The reference outline and numerical readout provide evidence that colour by itself omits.

The modes are not all passive views. Volume Preservation also adjusts pressure in response to a difference from the target volume. Selecting it changes how the body is regulated as well as what the display emphasises. No Readout removes the overlays while the body continues its simulation.

The previous room made stopping an intervention to examine. This specimen gives you a related distinction between observing a state and changing the process in order to maintain a state.

A useful extension would preserve a common colour scale across two stiffness settings and separate volume measurement from volume correction with distinct controls. Visitors could then decide what evidence they need before choosing an intervention.

<!-- @ -->

The following room turns towards the language of being affected. Carry this precision with you: the measured displacement is available to inspect, while the meaning assigned to it needs its own argument.

### 125. SoftBodies Affect Theory Visualization

[Live text](http://localhost:3003/compose?map=SoftBodies_Affect_Theory_Visualization)

Softness is the capacity to be affected, and this room is full of the hard record of it.

You arrive standing inside them. There is no door, no case and no plinth: a slab of floor a metre thick, open sky above and on every side, and nine glass skeletons on a grid around you, close enough that the outermost hang over the edge with nothing beneath. Turn on the spot before reading further. That is the exhibit.

```gdscript
for i in 9:
    var kind: int = randi() % 6          # unseeded, re-rolled every load
    build_radiolarian(kind, grid_position(i))
```

<!-- @radiolaria -->

Radiolaria are single-celled organisms that build lattices of glass around themselves. The mineral is silica, the same as window glass, and the geometry is not decoration: a shell that has to be light enough to stay suspended and strong enough not to implode is a solved problem, and the solution is a lattice with holes in it.

Nine of them here, on a three-by-three grid two and a half metres apart, and they are not the same nine you would have met yesterday. Six body types, chosen at random when the room loads, never seeded, so the exhibit re-rolls itself every visit. Four hundred and fifty motes drift between them.

Walk through one. You can, because none of them has a collider anywhere, and it is the right thing to do in a room about being affected: the objects that made the strongest case in this chapter for responding to contact cannot register that you are there.

<!-- @ -->

##### The record and the responding

Everything else in this chapter was soft while you watched. The jelly renegotiated its shape under your hand, the ride's bodies read a field they were swinging through, the rack spent a second passing news of a collision along its springs. Softness was a thing happening.

These are the opposite, and they are the chapter's last word for exactly that reason. A radiolarian skeleton is not soft. It is the hardest thing here, and it is entirely a record of softness: every strut sits where a living membrane pushed the mineral, and every hole is where the membrane did not. The animal was the capacity to be affected. The glass is what that capacity left behind after it stopped.

That is the chapter's question answered a fourth time, and answered past its own frame. The material decides the form. The field it hangs in decides. What it meets decides. And in the end the form is a fossil of all three, still standing after the thing that could respond is gone.

##### What is missing here

It is worth saying plainly, because the room does not. This exhibit is described everywhere as a single specimen in a display case. There is no case, there is no specimen, and there are nine. The lighting the map declares is never read, and the light you are standing in arrives with the organisms themselves. The way out is at the bottom of a hole in the floor.

A room about the capacity to be affected, in which nothing can be touched, nothing registers a visitor, and the exhibit is different every time anybody looks. Some of that is a fault. Some of it is the truest thing in the chapter.

Next: pattern that needs no blueprint at all.

### 126. ProceduralGeneration Reaction Diffusion Systems

[Live text](http://localhost:3003/compose?map=ProceduralGeneration_Reaction_Diffusion_Systems)

#### A pattern without an outline

<!-- @turing_pattern_generator -->

Can a shape develop without a rule that draws its boundary?

Choose a preset at the Turing pattern generator and watch the image develop. Find a small patch and observe whether it spreads, separates or joins a neighbour. Let the pattern establish itself before changing FEED slightly. Leave KILL fixed so that you can relate the next difference to one chosen control.

Use RESET to begin another run. Notice that the early seeded arrangement and the time allowed for development both matter. A later image is a record of many updates, not simply a direct illustration of the current slider position.

Follow a boundary between two regions rather than trying to name the complete picture. Choose a small bend or isolated patch that you can recognise again after several updates. Notice whether it expands, divides or is absorbed into a neighbouring region. Then look at the wider field and ask whether the local event changes your description of the whole pattern. A spot can disappear while a spotted arrangement persists elsewhere. Keeping those scales separate helps you describe what the system maintains without assuming that it preserves every individual visible feature.

The display stores two concentration fields. At each step, local reaction terms exchange their contributions, a weighted neighbourhood calculation spreads concentrations, and feed and removal terms alter the balance. New values are written into another buffer before replacing the old field. The boundaries wrap, so the edge of the image is not a sealed edge of the simulated material.

The outlines you see arise from reading that changing field. No separate instruction places each spot or traces each stripe. Neighbouring locations acquire relations through reaction and exchange, and the visible pattern makes those relations available to inspect.

The earlier soft-body rooms followed deformation through a material model. This encounter produces organisation through changing quantities on a field. A resemblance to a biological marking can motivate a question, but it does not make the simulation a complete explanation of a living organism.

A useful extension would preserve an identical initial field across two feed settings and display equal elapsed times. Then add one local disturbance and ask which aspects recover and which persist differently. That would make sameness a criterion to discuss rather than a preset name to accept.

<!-- @ -->

Next, a field will become a surface with openings. Keep the distinction between the values being calculated and the visible form chosen to represent them.

### 127. Topology Entropy Morphogenesis

[Live text](http://localhost:3003/compose?map=Topology_Entropy_Morphogenesis)

#### Follow the opening

<!-- @entropy_morphogenesis -->

Do two openings belong to one passage, or do they only overlap from where you stand?

Choose an opening in the porous specimen and follow its boundary with your eye. Move to another viewpoint and test your first reading. A fold that looked like a wall may reveal a passage; two apparent passages may separate when the foreground no longer conceals their relation.

Use one recognisable fold as a landmark while you move. The apparent position of a neighbouring opening may change quickly in projection, while the landmark keeps you oriented to the same part of the specimen. Try describing a connection as a route along the boundary before describing a route through empty space. Those tasks use different evidence. Following a continuous surface patch does not necessarily prove that the air on one side connects to the air on the other. The extra viewpoint helps test a particular relation rather than merely supplying another attractive silhouette.

The form begins as values throughout a volume. A gyroid-like expression combines sine and cosine terms in three directions, with noise added as a perturbation. A threshold selects the boundary that is extracted as a mesh. The openings belong to that particular selection, rather than to holes individually cut into a pre-existing solid.

The reaction-diffusion display made a changing field visible as an image. Here, the relation between field and display becomes spatial: the selected level is presented as a surface that you can inspect from more than one side.

The model also has an authored parameter called S. It links changes in frequency, noise amplitude and threshold. The current specimen is a fixed result of those choices; there is no visitor slider here that isolates their effects.

Despite the room's entropy theme, S is not a measurement of thermodynamic entropy. It is a coordinated way to alter a generated form. Calling the form more disordered would not tell you which parameter changed or which connection was gained or lost.

A useful extension would first compare the same field at several thresholds. A second comparison could vary frequency while holding the threshold and noise seed fixed. Only then would the combined control have a clear set of changes to combine.

<!-- @ -->

The next sequence begins with that separation. A scalar field supplies values, a chosen level supplies a question, and an extraction procedure supplies the surface you can see. Your first task will be to locate the boundary before learning how its small pieces are made.

## Isosurfaces: Implicit to Explicit

### 128. ISO Introduction

[Live text](http://localhost:3003/compose?map=ISO_Introduction)

#### A boundary made from values

<!-- @voxel_noise_demo -->

Where does this surface come from if nobody drew its outline?

Move around the glass and wireframe specimen. Choose a visible boundary and follow it across several triangular patches. Look for a place where the outline turns sharply, then compare it with a smoother region. The large form is continuous-looking, but its visible surface has been assembled from small pieces.

Choose a short edge between two visible triangles and follow it towards the next patch. Then step back until those small divisions become difficult to distinguish. The overall form remains readable even as its construction recedes from view. Return closer and compare the two readings. Neither distance is the uniquely correct way to see the specimen: one reveals an assembled boundary and the other its larger organisation. What matters is remembering that a smooth-looking silhouette at a distance does not erase the finite pieces from which this display is made.

Before those pieces exist, the generator samples a noise field throughout a volume. Each sample receives a number. A chosen level divides the samples into two classes: values below it and values on the other side. Where neighbouring samples cross that level, the program estimates positions for a boundary.

An isosurface is the set of locations at one selected value of a scalar field. This mesh is a finite approximation to such a set. Its triangles connect estimated crossings; they are not the field itself, and the regions where no triangle appears still have field values.

The porous specimen in the previous room introduced the same distinction between values and visible form. Here, keep it in view while examining the polygon structure. The threshold did not add a decorative skin to a finished cave. It helped determine which boundary would exist in the first place.

The displayed object offers one threshold at one sampling resolution. A small passage may depend on both. Absence from the mesh does not establish absence from the underlying continuous field, particularly where a feature falls between widely separated samples.

A useful extension would place the same field beside two other thresholds, keeping its seed and sampling grid fixed. You could then identify which connections changed without also changing the source of the values.

<!-- @ -->

The next room opens the local construction. Eight corner samples will select a case, and that case will tell the extractor which edges to join.

### 129. ISO LookupTable

[Live text](http://localhost:3003/compose?map=ISO_LookupTable)

#### Eight samples, one local decision

<!-- @fifteen_cases_demo -->

What can eight corner samples tell you about the space between them?

Compare two tiles in the fifteen-case display. Find their corner indicators before following their triangle edges. Look for a tile with one separated corner, then another in which several corners share a classification. How does the boundary change when the arrangement of classified corners changes?

Choose a pair of indicators on opposite ends of an edge and ask whether their classifications agree. If they disagree, locate the corresponding boundary crossing where it is visible. Repeat on another edge before trying to read the whole tile. This lets you build an explanation from a relation small enough to check directly. When the corner arrangement becomes more complicated, retain that edge-by-edge reading instead of guessing a familiar shape. The case table organises many such local questions, but each crossing still begins with values at particular sample positions.

The corner values used by the indicators also feed the surface generator. A comparison with the threshold turns each corner into a bit. Eight bits provide a case number, which selects a triangle arrangement from a table. Edge crossings are then positioned using the numerical values at their endpoints.

These are two different uses of the samples. Their signs choose a connection pattern; their magnitudes help decide where a crossing lies along an edge. Two cells can choose the same table case while placing its triangle vertices at different positions.

The previous room showed the assembled surface. This display makes some of its recurring local decisions easier to inspect. The fifteen examples group familiar arrangements, but the complete corner classification contains two hundred and fifty-six masks. Symmetries help relate cases; they do not remove every ambiguity about a continuous surface between samples.

There is another scale to attend to: the displayed pieces include surrounding sampled cells. Read the marked corners as the local question under study, rather than assuming every visible triangle belongs to one isolated cube.

A useful variation would hold the corner signs fixed and move their values closer to or farther from the threshold. Predict which connections remain and which vertex positions shift. A second comparison could expose an ambiguous face and show the convention used to connect it.

<!-- @ -->

Next, the field will describe familiar objects. The triangle-making procedure can remain the same even when the description supplied to it changes from a chair to a cup.

### 130. ISO ShapesGallery

[Live text](http://localhost:3003/compose?map=ISO_ShapesGallery)

#### The same tool makes a cup

<!-- @mc_shapes_gallery -->

Can the procedure that makes a chair also make a hollow cup?

Compare the labelled Chair and Cup in the shapes gallery. Find a junction between parts of the chair, then look for the cup's inner boundary and its handle. Move to a second viewpoint where a hollow and a projecting part are easier to distinguish. Describe those relations before naming their ingredients.

Inspect a junction on the chair from a second angle. A seam can disappear in the combined surface even though the description still contains separate ingredients. Then compare the cup's hollow with the empty space around its handle. Both are absences in a familiar object, but they arise from different parts of its description. You need not recognise every primitive to establish that these relations differ. Naming one junction and one opening gives you a smaller, more testable account than saying that the generator understands household objects.

The chair is described by combining box-like fields for a seat, back and legs. The cup uses a different composition: an inner cylinder is subtracted from an outer one, then a ring-like handle is joined to the result. These descriptions provide values throughout space. The same extraction apparatus samples them and builds the visible boundary.

The lookup table does not need to know what a cup is. It receives corner values and performs the local work you examined in the previous room. Recognition belongs to the larger arrangement of those values and to the person reading the resulting form.

This separation makes procedural modelling reusable. A new description can enter an existing extraction process. It also lets us ask whether an error belongs to the description, the sampling, or the way the generated mesh is displayed.

A familiar silhouette is not a complete design for use. A thin handle may disappear at coarse resolution; a chair-like figure may have no suitable support or dimensions for sitting. The label supplies a proposed interpretation, not evidence that the object fulfils every function associated with its name.

For an extension, keep the extractor fixed while thickening only the cup wall. Compare the inner opening and outer silhouette, then try removing a chair leg. Discuss both geometric changes and changes in possible use.

<!-- @ -->

The next room leaves the household repertoire and examines a surface whose repetition extends through three directions without being assembled from separate repeating objects.

### 131. ISO TorusGyroid

[Live text](http://localhost:3003/compose?map=ISO_TorusGyroid)

#### Repetition without separate pieces

<!-- @GyroidDemo -->

Does a repeating surface have to be a collection of repeating objects?

Choose an opening in the gyroid specimen and follow the surrounding fold into the next region. Change viewpoint wherever a crossing obscures the connection. Look for repetition along another direction, then compare its scale with the first. The pattern is not organised only across a flat face.

Keep one opening as a landmark and compare it with the next recognisable opening along a fold. Look at their orientation as well as their apparent size. Repetition in a volume can carry a relation around a bend, so matching silhouettes are not the only evidence available. If the two features differ, consider whether the difference might come from viewpoint before attributing it to the field's perturbation. A second angle can resolve some of that uncertainty while also revealing another layer of the repeating structure behind the first.

The field begins with three linked trigonometric terms: sine in one direction multiplied by cosine in another, repeated cyclically across the coordinates. Together they create a periodic spatial relation. A threshold selects a surface from that relation, and the extractor turns the sampled boundary into triangles.

The placed specimen also perturbs that base expression. Noise displaces the coordinates before evaluation, adds finer variation and alters the field over broader distances. Its folds therefore resemble a gyroid while departing from the pure mathematical construction. A smooth, porous appearance is not evidence of an exact minimal surface.

The shapes gallery assembled descriptions of recognisable parts. Here, repetition arises directly from a field expression. There need be no separately stored object corresponding to each opening you recognise.

That shift changes what it means to edit the form. Adjusting the period changes a repeating relation across the volume. Altering a threshold can change thickness and connections. Distorting coordinates changes where the expression is evaluated. Those operations may all affect an opening, but they are different explanations for its altered shape.

A useful extension would first show the pure expression beside the perturbed specimen. Then compare period settings with the perturbation held fixed. Follow one connection across the comparison rather than judging only overall roughness.

<!-- @ -->

The next room introduces a more direct gesture. Instead of changing a repeating expression, your hand will add local contributions and watch the extracted surface join them together.

### 132. ISO Sculpting

[Live text](http://localhost:3003/compose?map=ISO_Sculpting)

#### Add a contribution

<!-- @mc_sculpt_vr -->

When two rounded deposits meet, where does their seam go?

Inspect the sculpture already present in the brush volume. Choose a join between rounded regions. Then place the brush inside the volume near an existing part and hold the trigger briefly to add material. Release it and examine the changed boundary from another angle. A short gesture makes its contribution easier to distinguish than a long sweep.

Before adding again, identify which part of the boundary changed after your first short gesture. Follow the join from one side to the other and compare it with the adjacent surface that received no nearby deposit. This keeps the experiment local enough to explain. A long sweep would combine many contributions before you could inspect their individual effects. If the response is difficult to distinguish, change your viewpoint and locate the brush volume again rather than assuming the absence of an obvious silhouette change means no contribution was recorded.

The brush does not push a particular triangle into a new position. Its location is translated into the generator's coordinates and stored as a contribution with a centre and radius. The field combines sphere-like distance descriptions with a smooth blending operation, then extracts the surface again.

The changed join is therefore a result of several decisions: where you deposited, how wide the contribution is, how contributions are blended and how finely the field is sampled. Your gesture participates in the form without directly specifying every point of its boundary.

The gyroid changed a repeating spatial expression. This sculptor adds local descriptions to a collection. Both approaches return to the same task of finding a visible boundary from values, but they distribute authorship differently across the volume.

Use the additive behaviour as the current experiment. The displayed erase mode does not yet supply reliable subtraction: its deposit reaches the generator as a positive radius. A negative-looking control state cannot establish that material has been removed. That operation needs repair and a direct add-versus-remove comparison before it can carry a lesson.

A useful variation would make two equal deposits at several fixed separations. Predict whether their extracted boundaries will remain distinct or acquire a neck, then compare the prediction with the result.

<!-- @ -->

The next room scales the same field-making idea towards terrain. Ask what additional relations a volume can describe beyond the single upper height of a conventional landscape.

### 133. ISO FlatTerrain

[Live text](http://localhost:3003/compose?map=ISO_FlatTerrain)

#### Look beneath the height

<!-- @mc_flat_landscape -->

Can a landscape have more than one boundary above the same place on the ground?

Read the upper profile of the terrain specimen. Then move to a view of its side and inspect recesses, openings or undercuts. Compare what this viewpoint reveals with what you could infer from looking down on the surface. A top view can make very different interiors appear similar.

Choose a recognisable point on the upper profile and keep it as a reference while you inspect the side below it. Ask how many distinct boundary pieces you can identify along an imagined vertical line through that region. You may see only one, or a more complicated arrangement of openings and surfaces. The exercise does not require every part of the specimen to contain a cave. It establishes what evidence would distinguish a single-valued upper height from a description that can support several boundaries through a volume.

A heightfield assigns one height to each horizontal position. Its description is enough for an upper surface but cannot independently place a ceiling, a floor and an intervening void above the same horizontal coordinate.

This generator evaluates a volume. It begins with a terrain term based on the difference between an upper height and the sample's vertical position. The current configuration also subtracts a weighted three-dimensional cave field. The final threshold therefore acts on a description that can include interior variation, not merely a surface displaced upwards and downwards.

The sculpting room let a local contribution alter a field. Here, broad terrain and interior variation contribute different spatial tendencies. Examining a side view helps separate their consequences even when both participate in the same visible mesh.

Do not infer a complete passage network from one opening. A recess can end out of sight, and a connection in sampled geometry can be too small for a visitor. Sampling resolution also limits the thin features the boundary can retain.

A useful extension would pair the current caverned setting with the same terrain using no interior cave term. Keep the threshold and field coordinates fixed. Then ask which differences could have been represented by changing only a heightfield and which require a volume.

<!-- @ -->

The next room adds more field terms. A ledge, an arch and an outcrop will become clues to how a compound landscape is described before any triangles are built.

### 134. ISO PortalLandscape

[Live text](http://localhost:3003/compose?map=ISO_PortalLandscape)

#### An opening from overlapping terms

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

### 135. ISO Caves

[Live text](http://localhost:3003/compose?map=ISO_Caves)

#### On the enclosing side

<!-- @mc_inside_cave -->

What changes when a surface surrounds a viewpoint instead of standing in front of it?

From the available approach, compare the cave's enclosing side with a view through an opening. Follow a boundary visually before treating it as a route. Look for a narrowing and imagine the clearance a body would need to pass it. If the passage is accessible, compare what becomes visible as you approach with what the entrance concealed.

Keep track of how the view changes as you move towards an opening. A turn can reveal an apparently generous chamber only after a narrow approach, while a broad entrance can conceal a constriction farther inside. Record those as separate features of the route. The widest visible region is not a reliable summary of the clearance needed to reach it. This is also why inspecting the enclosing surface from several positions matters: access depends on a sequence of spaces and transitions, not just the dimensions of one impressive interior view.

The cave's field combines several scales of ridged noise with a vertical bias. The noise creates spatial variation; the bias changes the tendency towards material or air at different heights. A threshold selects the boundary that is sampled into a mesh.

From outside, that boundary can be read as the surface of an object. From an enclosing side, its folds determine available space: a ceiling, a wall, a recess or a constriction. The mathematical classification is the same, while the consequences for a situated viewer differ.

The compound landscape made field terms visible through ledges and openings. Here, a chosen cutoff becomes relevant to clearance. The threshold is an authored condition of the space, not a value each visitor has necessarily been invited to choose.

Connected empty regions do not automatically provide an adequate route. Width, headroom, collision geometry and access to an entrance all matter. A graph of connected samples may omit exactly the bodily requirements that decide whether a passage can be used.

A useful extension would compare the same cave at two thresholds and measure one narrow passage against several clearance requirements. Preserve the field so that a changed route can be traced to the changed cutoff.

<!-- @ -->

The next room compares another cave from the same generating family. Resist explaining every difference with the word random; several authored parameters have changed and need to be distinguished.

### 136. ISO CaveGeneration

[Live text](http://localhost:3003/compose?map=ISO_CaveGeneration)

#### Designing the conditions of a cave

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

### 137. ISO AnimatedNoise

[Live text](http://localhost:3003/compose?map=ISO_AnimatedNoise)

#### Which block moved?

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

### 138. ISO Metaballs

[Live text](http://localhost:3003/compose?map=ISO_Metaballs)

#### A neck between sources

<!-- @metaball_world -->

Can two sources make one body before their centres meet?

Look for a narrow neck joining rounded regions in the metaball specimen. Follow it towards an outer lobe and compare the curvature. If the short initial evolution is still running, watch a changing join; if it has finished, inspect the fused form as a held result rather than waiting for an endless animation.

Compare the neck with two outer regions that appear more rounded. Move sideways to check whether its narrowness is a feature of the boundary or an overlap in projection. Then ask where you would draw a dividing line between the presumed contributors. A line through the narrowest part might be convenient, but the surface does not necessarily mark it as an ownership boundary. The visible body gives you a combined result. Recovering its individual sources would require more information than a silhouette, especially where several contributions overlap in the same region.

Each source contributes a value around its centre. In the current configuration, that influence decreases approximately as the inverse square of distance, weighted by the source's strength and radius. The contributions are added at each sampled position. A shared threshold selects the resulting boundary.

Between nearby sources, neither contribution has to dominate alone. Their sum can cross the threshold and form a connecting region. The neck belongs to the combined field; it does not need to be a separate object inserted between two completed spheres.

The animated noise display rebuilt a representation from changing samples. Here, a similar reconstruction can reveal changes in connectivity. What looks like a body joining or separating can be produced without preserving one mesh whose vertices must be pulled through every intermediate arrangement.

The sources are numerical descriptions, not tiny physical bodies exerting a measured attraction. Nor does every point of the visible surface belong uniquely to one source. Sampling, finite influence bounds and the chosen threshold all affect the extracted result.

A useful extension would stage just two equal sources at increasing fixed separations. Keep the threshold and sample grid unchanged, and ask where the neck first disappears. Then change the threshold while holding their positions fixed to see a different way of altering the same connection.

<!-- @ -->

The next room presents another blended surface but changes how the image is produced. A smooth appearance does not require the visible boundary to have been extracted into triangles first.

### 139. ISO ImplicitModeling

[Live text](http://localhost:3003/compose?map=ISO_ImplicitModeling)

#### A surface found by looking

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

### 140. ISO RhizomeBody

[Live text](http://localhost:3003/compose?map=ISO_RhizomeBody)

#### A connection has to fit a body

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

## Boolean Surfaces: CSG as Composition

### 141. Boolean Verbs

[Live text](http://localhost:3003/compose?map=Boolean_Verbs)

Three objects on one line down the middle of the room, and the floor rises to either side of you twice on the way, so each one gets a bay to itself without ever being hidden from the next.

They are the same two solids every time. A box and a sphere, one offset from the other, and nothing else changes down the whole length of the hall — not the size, not the spacing, not the material. What changes is a single word set on the sphere, and that word decides whether you are looking at one thing, at the part two things had in common, or at a hole. This room is the argument that the word is doing more work than the shapes.

##### What a solid is here

Before the verbs, the thing they operate on. In this engine a solid is not a lump of material with an inside. It is a surface, and a rule for asking whether a point is on one side of it. Nothing is stored in the middle. The middle is an agreement between two systems — the renderer, which will not draw what faces away from you, and the physics, which will refuse to let you pass — and as long as the two agree, you experience an interior.

This matters because it means none of the three verbs can remove anything. There is nothing in there to remove. What they can do is redraw the boundary so that the same test gives different answers. Every operation in this hall is an operation on a *skin*, and every "inside" you meet is a promise about a region that was never filled in.

##### Joining is not stacking

<!-- @csg_union_demo -->

```gdscript
#### csg_union_demo.gd:59 — what this room is not
####   blend and the ladder is a continuum. CSG union has no k: it fuses absolutely
####   at first contact, so here `necked` is a CREASE with a discontinuous normal and
####   the ladder is a sequence of topological events. Same four states, two
####   ontologies of joining.
```

Walk to the first body and watch the seam. Two solids meet, and the surfaces where they met are gone — not hidden, not coincident, gone, replaced by one new closed surface that neither of them had before the operation ran.

The comment above is the artifact talking about its own cousins in the metaball chapter, and it is the most important sentence in this hall. Over there, a union takes a parameter `k`, and inside a band of width `k` the two fields blend: there is a genuine *partly*, a state that is neither two nor one. Here there is no `k`. The solids are two, and then at one floating-point value of the offset they are one, and there is no frame in between. The ladder is not a gradient. It is a sequence of events.

Same four states, two ontologies of joining. That is the artifact's phrase, not mine, and it is the whole chapter in six words.

Which makes the first rung of its own ladder awkward. The axis `fusion` runs `distinct, necked, lobed, single`, and at `distinct` the two primitives do not touch at all. The operator still runs. It contributes nothing — the output set is exactly the input set, two solids sitting near each other under a union that has no work to do. The artifact's stated desire is *to show that joining is not stacking*, and a quarter of its primary axis is a stack. The file is honest about it in the only place it can be, a comment at line 42: `TWO DISJOINT SOLIDS, still under OPERATION_UNION`.

##### The interior was never there

<!-- @csg_intersection_demo -->

```gdscript
#### csg_intersection_demo.gd:341 — the instrument, which is not the object
if dx * dx + dy * dy + dz * dz <= r2:
```

The second body keeps only what both solids claimed. Set the offset far enough and it keeps nothing, and nothing is a lawful answer: the operation succeeded, and the result is empty. It is the one verb whose correct output can be no output.

Standing next to it, on three of its four settings, is a number — the volume of A, of B, and of the two together, printed to three decimals. The artifact calls this measuring itself, and says so: *All three are measured by the SAME instrument on purpose*.

They are not measured by the same instrument as the object. That line above is the measurement: an analytic sphere, a point tested against a radius, forty-eight cubed samples of a perfect mathematical ball. The thing on the table is a `CSGSphere3D` whose tessellation is never set, so it renders at Godot's default twelve segments by six rings — a faceted approximation. And on the setting that shows you what was lost, the ghosts of the discarded material are built at twenty-four by twelve, smoother than the sphere that cut them.

So there are three spheres in this exhibit. The one you see, the one that did the cutting, and the one the number is about, and no two of them are the same shape. The instrument is honest, the object is honest, and they are describing different things — which is not a bug so much as the clearest possible demonstration of what a boundary representation is. The sphere on the plinth has no radius. It has twelve segments and six rings, and *radius* is a story told about them.

##### A face neither of them brought

<!-- @csg_difference_demo -->

```gdscript
#### csg_difference_demo.gd:236 — the cut, and then the skin
csg_sphere.operation = CSGShape3D.OPERATION_SUBTRACTION
_root_csg.add_child(csg_sphere)
var mat := StandardMaterial3D.new()
mat.albedo_color = body_color
_root_csg.material_override = mat
```

Push the sphere into the box and a face appears that neither solid brought with it. It is the sphere's shape, turned inside out, and it is wearing the box's material — because look at the last line: the material is set once, on the root of the whole operation. There is one skin. There was only ever one skin to give it.

That is not a shortcut in the code. It is what a boundary model leaves you no choice about. The moment you carve, you need a surface for an inside that was never stored, and the only surface available is the outside, relabelled. The cavity wall is not revealed by the cut. It is manufactured at the instant of the cut, out of the material of the thing being cut, and assigned to a solid that did not make it.

Of the three verbs this is the one that shows the mechanism plainly, and it is also the one the heavy hall cannot leave alone: subtraction is the operation this whole chapter keeps returning to, because it is the one where the invention is impossible to hide.

##### The set is closed

<!-- @the_argument_of_solids -->

```gdscript
#### the_argument_of_solids.gd:130 — the label it hangs in the middle of the room
_tag(Vector3(-0.3, 0.94, -0.05), "the three verbs", "an enum on one property - the set is closed")
```

At the far end, after all three, a bench of small verdicts with captions. It rebuilds the three results from scratch at its own scale so you can read them side by side, and it hangs the line above over the middle of them: three verbs, an enum on one property, the set is closed.

Five lines further down the file it builds a fourth thing the enum cannot name. Its helper for making a verdict takes the operation as a parameter but fixes the operand order — box first, sphere second — so B minus A cannot go through it, and the file hand-rolls a duplicate combiner with the two children swapped to get the picture it wants.

The set is closed, and the closure is a property of the enum, not of the argument. Difference is not commutative; the grammar has one slot for the verb and no slot for the order; so the artifact that exists to say the vocabulary is complete has to step outside the vocabulary to finish its own sentence.

You can count the preference in the file. `OPERATION_UNION` appears once. `OPERATION_INTERSECTION` twice. `OPERATION_SUBTRACTION` six times.

##### What the grammar cannot say

Three verbs, and each one turned out to be an argument about the boundary rather than about the solids. Union deletes a surface. Intersection reveals there was never anything behind it. Difference invents one and dresses it in somebody else's skin.

And the foreclosure is the same in all three: the predicate is a yes or a no. There is no `k`. A point is in or it is out, two solids are two or they are one, and the transition between those states does not occupy any time or any space — it happens between one float and the next. Everything this chapter can say about relation, it has to say in a vocabulary with no word for *partly*, no word for *becoming*, and no way to hold a thing that belongs to two sets at once except by making a third set and throwing the question away.

The room next door is where you find out that even the four settings on each of these dials are a claim somebody published, and that the published claim and the object do not always agree.

### 142. Boolean Gallery

[Live text](http://localhost:3003/compose?map=Boolean_Gallery)

Twenty-four objects in six rows across a wide room, and eighteen of them are things this museum has never shown.

Every artifact in the boolean chapter is a family. Each one declares an axis — a named dial with four settings — and every placement anywhere else in the building shows you exactly one of those settings, the one it shipped with. This hall is the only place the other three stand up. One artifact per band, its four values laid across the room, two on your left and two on your right with the walking lane between them, so you meet the family two at a time and have to cross the floor to finish the sentence.

The six you have already met are here too, one per band, and in five of the six they are the first thing you come to on the left. That is a convention rather than an accident: the registry lists a family's values with the default first, and this hall was laid out from the registry. So each row starts with the object as you know it and then shows you what else it was willing to be.

##### A variant is a claim somebody published

The four settings are not in the object. They are in a file. Each artifact's code holds a list of the values it will accept, and the registry — `commons/artifacts/registry/boolean_surfaces.json` and its neighbours — holds a second list, which is what every tool in this project reads: the catalogue builder, the sweep, the deck, the audit. The object obeys the first list. The museum, the gallery pages and this room are built from the second.

So a band in this hall is a published claim about an object, standing next to the object. That is a rare arrangement, and it makes the room usable for something other than looking: you can check.

Three of the six bands here disagree with their own code about what order the ladder goes in. Two agree exactly. One agrees and then checks itself at runtime, which no other artifact in the chapter does.

##### The band that agrees

<!-- @csg_difference_demo -->

```gdscript
#### csg_difference_demo.gd:73
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]
```

Four readings of one cut. At `outcome` you get the answer and nothing else, a box with a bite out of it. At `trace` the removed material comes back as a ghost, occupying the space it was taken from. At `operands` both original solids return, transparent, so you can see the box and the sphere that were consumed. At `expression` a labelled rod names the operation out loud.

The registry declares those four words in that order, and so does the code, and so does the second axis. This is the only band in the room where the published claim and the object match on both dials, and it is worth standing in front of because it shows what the ladder is *for*: it is not four decorations, it is one operation shown at four degrees of disclosure. The object gets progressively less confident about its own result as you walk right.

There is one seam even here, and it is small and revealing. The dial that positions the cut names only two of its four settings in the code that reads it; `centred` — the one the artifact advertises as producing a clean internal void — arrives through the wildcard. It is not a rung. It is what happens when nothing matches.

##### The ladder, published out of order

<!-- @csg_union_demo -->

```gdscript
#### csg_union_demo.gd:119 — the code's ladder
const FUSIONS: PackedStringArray = ["distinct", "necked", "lobed", "single"]
```

In the code those four are monotonic. They are four multiples of one offset, running down: far apart, nearly touching, overlapping, concentric. Walk them in that order and you watch two things become one, in four steps, with the topology changing under you.

Walk this band left to right and you get `lobed, distinct, necked, single` — the registry's order, which is the order this hall was built from, and which starts you two-thirds of the way up the ladder, sends you back to the bottom, then part way up again, then to the top. The sequence is the same four states. The *argument* is gone, because the argument was the monotonicity.

The registry did not do this carelessly; the entry says the order is the sweep's tile order, default leftmost. But the disagreement has consequences past this room: a third file, `fusion_ladder.json`, declares the ladder in the code's order and states that it took that order character for character from `csg_union_demo.gd:128`. So one artifact cites this object's code as canonical while the object's own registry entry publishes something else, and both are read by tools.

##### A rung that is only a name

<!-- @csg_intersection_demo -->

```gdscript
#### csg_intersection_demo.gd:234 — three of the four are here
match consensus:
    "unanimous": ...
    "narrow": ...
    "token": ...
    _: ...
```

The same displacement, one band down. `consensus` asks how much has to be shared before anything survives, and the four values run from complete agreement to a token overlap.

`broad` is not in the match. It reaches its position through the wildcard, which means it is not a defined rung at all — it is the label the artifact wears when nothing matched. The value exists in both lists, in the code and in the registry, and in neither of them does it correspond to a line that says what it is. It is the name of the default, promoted to a name.

And it is the one the registry puts first, so this band opens on it.

##### Four degrees of removal, read from somewhere else

<!-- @subtraction_suite -->

```gdscript
#### subtraction_suite.gd:162
##### The vocabulary and the ratios, read from the family rather than retyped.
var _breach_table: Dictionary = FONTANA_SOURCE.BREACH
```

Here is the counter-example, and the hall needs one. `breach` asks how far a removal can go before the thing is gone, and its four rungs — pierced, opened, severed, husk — are not four numbers in this file. They are read out of `fontana_puncture.gd`, another artifact entirely, which holds them as ratios of the body's own size: 0.54, 0.68, 0.74, 0.80. The enum, the table and the registry agree on all four words, in the same order.

The bench makes an argument out of that: because the ratios are read rather than retyped, they cannot drift. Which is true of every one of them except the one the file retypes fifty lines later as a literal `0.68`, inside the function whose whole purpose is the anti-drift claim. One number, in the file that exists to say numbers do not need to be repeated.

##### The degenerate case, painted

<!-- @coincident_face -->

```gdscript
#### coincident_face.gd:257 — the coin toss
col = color_a if (i % 2 == 0) else color_b
```

This band is about what happens when two faces occupy the same plane and the depth test has no answer — the flicker every 3D artist has seen, where a surface tears into stripes of two materials because the comparison is a coin toss at every pixel.

The artifact contains no boolean operation and no z-fight. There is not one CSG node in the file; the four places the string "CSG" appears are all text on labels. The stripes are the line above: even bars one colour, odd bars the other, alternating by index. And they are drawn at an explicitly unambiguous depth, four millimetres in front of everything else, so the renderer is never asked the question the artifact is named after. It is a diagram of a failure, executed by a mechanism that cannot fail.

That is not a cheat, exactly — a picture of z-fighting that actually z-fights would be unphotographable and would look different on every machine. But it is worth knowing what you are looking at, because there *is* a real coincident face in this file and it is not the one on the wall: at the `coincident` setting the two rectangle fills are placed at the same depth, the same thickness, overlapping in x, and they genuinely contest. The artifact produced the thing it is about by accident, behind the drawing of it, and says nothing about it.

The band's other seam is the same one union has: code and registry disagree on order, this time by moving the failure state to the front. The registry declares it in its own note, so it is a known disagreement rather than a hidden one.

##### The one that checks

<!-- @removal_room -->

```gdscript
#### removal_room.gd:341 — reading its own hint string back out
func _check_vocabularies() -> void:
```

Three copies of one cut lattice, differing only in how the removed cells are recorded: not drawn at all, drawn full-size and pale, or shrunk to a fifth and left as a scar. The axis underneath asks which deletion rule made the hole — a cross, a middle third, a gasket, a figure.

Alone in this chapter, this artifact does not trust its own declaration. At runtime it pulls its exported enum's hint string back out of the property list and compares it, both directions, against the constant beside it and against the vocabulary of the upstream artifact it borrowed the registers from. Code, constant and registry agree, and the file makes sure of it every time it builds.

Which makes the error in it more interesting, not less. The header explains why the three copies stand side by side rather than stacked, and derives it from an arithmetic: a scar is 0.22 cubed of its ghost, about one percent. Four hundred lines later the same file says the upstream rule keeps the removed part's length and thins only the section, and implements it that way — which makes a scar 0.22 squared, nearly five percent, four and a half times bigger. The room is built correctly. The justification printed at the top of it is wrong, and it is wrong about the one artifact it names.

##### What the room is for

Six bands. Two published exactly as the code has them, one of those checked at runtime. Three published in a different order from the ladder the code walks, one of which scrambles the argument the ladder existed to make. One that measures its own ratios from another file and then retypes one of them anyway. One that has no boolean operation in it at all.

None of that is damage. It is what happens when an object is also a claim about itself, maintained in two places by different hands at different times, and it is only visible from a room where the claim and the object are standing next to each other. Everywhere else in this museum you meet these objects at their default and have no way to know there was a ladder.

The other question this hall raises, it cannot answer: all six of these families were promoted for the still camera, one photograph per value, judged on whether the picture changed. What none of them has ever been asked is whether the *space* changes — whether a variant is something you could walk differently. The heavy hall is where that gets tested, and where it mostly fails.

### 143. Boolean Works

[Live text](http://localhost:3003/compose?map=Boolean_Works)

The room gets taller here, and the things in it stop being demonstrations. A workbench, a catalogue rack, a wall with a door cut through it, a five-metre block of rock with a tunnel bored out of the middle. These are the boolean operations at the size where they would have to be architecture, and the question this hall asks is the one the small rooms could not: when the negative gets big enough to stand in, can you stand in it?

You cannot. Not in any of them. That answer took eight bodies to arrive at, and it is the most useful thing in the chapter.

##### The bench you cannot reach

<!-- @csg_compose_workbench -->

```gdscript
#### csg_compose_workbench.gd:9 — the promise, in the file's own header
#### stand at the bench, see all three operators side by side, pick one with the bracelet,
```

Three solids turning slowly above a table, each labelled with the operation that made it. The file calls itself a workbench, the registry sells it with the tag `catalyst_affordance`, and the header above says you pick one up with the bracelet.

There is no picking. Three hundred and fifty-eight lines and not one input handler, no interaction volume, no signal, no mention of the bracelet outside comments. The only thing that happens at runtime is that the presets rotate. And the geometry has already given it away before you try: the bench top is at 0.56 metres and the work is placed at 1.1, so the objects float just over half a metre above the surface they are supposedly on, out of reach, turning. The file half-admits it in a line called `needs` — *Missing: a live player-built composition surface beside the three fixed presets.*

Its dial is the interesting part. `algebra` has four settings, and one of them, `complete`, builds symmetric difference out of two nested combiners and labels it longhand as `(A ∪ B) − (A ∩ B)` — the artifact's own argument that XOR is derived rather than primitive, which is a real and good point about what an algebra holds versus what a tool exposes. The default is `triad`. Eleven placements exist in this museum and not one of them passes a config value. So XOR is in the repository and has never once been in the building.

##### The two stations that were supposed to be identical

<!-- @subtraction_suite -->

```gdscript
#### subtraction_suite.gd:254 — the one line that breaks the claim
art_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
```

One cube with a sphere taken out of it, built twice, side by side: once dressed as an art object and once as an instrument reading. The bench's stated result — its smallest and firmest, by its own account — is that these are the same object and *what differs between them is the furniture and the palette*.

Cull mode is neither. It is a property of the surface, and the operator's copy does not get it: that station keeps back-face culling, and at every setting past the first the void has already broken through the faces, so the mouths of the cavity are exactly where your eye goes in. One station renders its carved interior. The other deletes it at the moment you look inside. The claim that the difference is not in the object is undone by a line in the object.

Worth a count while you are here: the whole bench builds four CSG combiners and eighty-five plain meshes, sixty-eight of which are the catalogue tray beside it, which contains no boolean operation at all.

##### Four of five are not booleans

<!-- @sphere_splitting_showcase -->

```gdscript
#### sphere_splitting_showcase.gd:182 — the caption
_add_info_label(csg_sphere, "CSG CUTTING\nBoolean ops\nfor real cuts\n\nPieces: 1\nSplits: 0")
```

Five destructible spheres in a row with balls to throw at them, each shattering by a different algorithm. It stands in a boolean hall today for the first time, though it has been placed five times before in the forces chapter, which is where it comes from and where its registry entry still files it.

Four of the five contain no boolean operation. They are fracture algorithms — segmentation, planar cuts, physics shards — and only one of them reaches for CSG at all, which it uses for an *intersection*, baked offline, to mask a mesh. The caption above sits on that one. The room's name claims all five.

None of them is seeded, either: the cut planes are three unseeded random floats, so two placements of this token are two different objects the instant anything is thrown. It is the most honest thing in the hall about what a boolean is *for* — a tool used once, offline, to make a mesh — and it is filed as the opposite.

##### The hole that was never made

<!-- @recursive_boolean_cube -->

```gdscript
#### recursive_boolean_cube.gd:118 — the whole mechanism
if zeros >= 2:
    continue
```

A Menger sponge. A cube with square holes bored through it, and smaller holes in what remains, recursively. Of everything in this hall it looks the most like subtraction, and it is the hinge of the entire chapter.

It performs no boolean operation. There is no CSG node anywhere in the hundred and fifty-eight lines, no subtraction operator, nothing but boxes and materials. The holes come from the two lines above: walking the twenty-seven cells of each subdivision, if a cell is on the axial cross, the loop does not build it. Nothing is removed. A cube is declined.

The file's own comment calls this *boolean-like subtraction through recursive geometry*, and the registry, which files it under procedural generation and tags it `procedural`, never uses the word boolean at all. Both are more accurate than the room it now stands in.

And it is the only body here that is fully reproducible — no random number in the file, two placements byte-identical — which is a small joke at the chapter's expense: the artifact that does not do the thing is the one that does it the same way twice.

Take the mechanism seriously and it reframes everything upstream. A boundary model has no interior, so nothing in it can be removed; what looks like removal is always a redrawing of the skin. This artifact skips even that. It gets the appearance of a hole by never putting anything there and then narrating the absence as a cut. Which is not a lesser version of what the verbs do. It is the same thing with the arithmetic taken out.

##### Equals room

<!-- @csg_architecture_cavity -->

```gdscript
#### csg_architecture_cavity.gd:20 and :52 — thirty-two lines apart
#### truth: Every architectural cavity is a difference. A room is a wall that has been subtracted from.
...
####   operator and never delivers the truth line: a wall has no interior.
```

A wall, three and a half metres of it, with a door and an opening and a bitten arch cut through. Floating above it in large text: `wall − (door + porthole + window) = room`.

It is one wall. It has been one wall at all twelve of its placements, because the setting that would add returning runs defaults to `none` and no map in the project sets it otherwise. The two lines above are both in the file, thirty-two apart, and the second one is right: a wall has no interior. One difference makes a hole, not an inside. You read the payoff from outside, which is the only place there is.

Then walk into it. You will not be stopped. There is no collision anywhere in this artifact — no static body, no shape, and the CSG root's own collision flag is never set. This is not something the engine could not do; a tunnel in the alternative-geometries chapter turns exactly that flag on, one line, and you can walk through it. Here the doorway and the wall are the same to your body. The one architectural distinction the object exists to make — that a cut in a solid produces somewhere you can be — is the distinction it does not implement.

Even the porthole is not a hole. Its centre is set 1.4 metres up on a wall whose half-height is 1.3, so it is a scallop bitten out of the top edge.

##### Walk the hollow

<!-- @sdf_cavern_room -->

```gdscript
#### sdf_cavern_room.gd:55 — the only text in the world
_billboard_label("CARVE THE FUNCTION, WALK THE HOLLOW", Vector3(0.0, 3.6, 0.0), 28, ...)
```

Five metres of rock rendered as a crust of nearly five thousand small boxes, with five spheres subtracted out of the middle of it to make a cave. It is the most beautiful object in the chapter and the sign over it is the plainest instruction in the building.

There is no collider, and this time it would not help. The block is lifted so its underside sits fifteen centimetres off the floor, and the lowest carved air anywhere inside it is 1.2 metres up — more than a metre of unbroken rock between the ground you are standing on and the bottom of the hollow. The tunnel's floor is above your head. There is a floor in this artifact, a seven-metre plate, and it belongs to the tray, not the cave; it also sways, because the whole node rocks gently on its vertical axis and takes the ground with it.

So it is a model of a cavern on a table. Which would be fine — most of this museum is models on tables — except that the verb in its own truth line is the one operation it does not implement, and it is the artifact in the entire chapter that is actually shaped like an interior. It carries no declared axis at all, while the word `interior` has been borrowed from the wall next door by three other registry entries as the term for *whether a solid encloses a void you could occupy*.

##### Seventy-five things that look grabbable

<!-- @booleanvariations -->

```gdscript
#### booleanvariations.gd:632 — after wrapping each solid in a VR grab cube
grab_cube.set_script(stability_script)
```

A three-by-five-by-five rack of boolean combinations, seventy-five of them, each one wrapped in the project's standard grab cube so it can be picked up. Then the line above replaces that cube's script with a fourteen-line stub, and the pickable behaviour is gone. The highlight ring is removed first, because it would throw errors against the stub. Seventy-five objects built to be handled, presented as handleable, inert.

Two more things about it that are visible if you look. It clears its own children on the first frame with an unconditional loop, and its scene file's camera and its only light are among them, so standalone it goes black. And of the twenty-five distinct variations it advertises, thirteen are marked `# Placeholder` in the source and call another variation's builder, leaving eleven.

##### The degenerate case, kept

<!-- @coincident_face -->

At the back wall, the flat plate about two faces in the same plane — the failure mode, the one condition under which the whole boolean grammar has no answer. The gallery next door explains what it is and how it is drawn. It is here as well, at the end of the heavy hall, because it is the only object in the chapter that takes the position that a case where the machinery breaks is worth an exhibit rather than a bug report.

##### What the physics never turned up for

An interior, in this engine, is an agreement between two systems: the renderer will not draw the surfaces facing away from you, and the physics will not let you through. Hold both and you have an inside. Drop either and you have a picture of one.

In this hall the physics never arrives. Twelve of the chapter's thirteen artifacts contain no collision construct of any kind — no static body, no shape, no collision flag set on a CSG root. The thirteenth has exactly one: a two-metre grab volume on objects scaled to a tenth of that, bolted to a script the same file throws away eleven lines later. `= room` hangs over a wall you pass through. `WALK THE HOLLOW` hangs over a metre of rock. The workbench floats half a metre above the workbench. Seventy-five objects offer themselves to your hand and are not there.

The project has already written this down, in a place nobody reads. Its own interaction probe filed both the wall and the cavern under `"verdict": "no affordance"` — zero controls, zero grabbables, zero wired. And the still camera reached the same conclusion from the other direction without anyone noticing what it had said: the sweep that grades whether a dial changes the picture rates the wall's `interior` setting at 4.372 percent of pixels for the step from one wall to a four-walled room. That step is the artifact's entire argument, the rung its own source calls *the first rung on which the player is INSIDE*, and it registers as a rounding error — because a camera standing outside a room cannot see the difference between having an inside and not having one. It sees three more slabs, edge-on.

Which is the last thing this chapter has to teach, and the most uncomfortable. The instrument that decides whether a variant is worth keeping is a photograph taken from outside. An interior is precisely the claim that cannot be photographed from outside. So the one property this whole chapter is about is the one property the apparatus is built to miss.

That is the chapter's dark spot, and it is worth being precise about which kind it is. In the small room the missing interior is generative: because a boundary model stores no inside, difference has to *invent* the cavity wall out of the outside, and that invention is the best idea in the chapter. Here the same absence has gone sterile. The claim got bigger — from *this surface is manufactured* to *this is a room* — and nothing underneath it grew to match. The negative was supposed to become inhabitable at this scale. It became a sign saying so.

Which leaves the honest version of what these three halls demonstrate, and it is not the one the labels promise. A solid is a lie told by its skin, and so is its hole. The grammar that carves has no word for *partly*, no word for *becoming*, and nothing to put inside the thing it cuts. Every absence in this chapter is performed rather than found — by inversion, by omission, by parity, by a caption. What you can walk through, you were always going to walk through.

## Swarm Intelligence: No Leader, Yet Coordinated

### 144. SwarmIntelligence PhysarumColony

[Live text](http://localhost:3003/compose?map=SwarmIntelligence_PhysarumColony)

#### Remembering in the ground

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

### 145. SwarmIntelligence FlowFields

[Live text](http://localhost:3003/compose?map=SwarmIntelligence_FlowFields)

#### Directions already in the ground

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

### 146. SwarmIntelligence Boids Algorithm

[Live text](http://localhost:3003/compose?map=SwarmIntelligence_Boids_Algorithm)

#### Three ways to be near

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

### 147. SwarmIntelligence Agent Based Modeling ABM

[Live text](http://localhost:3003/compose?map=SwarmIntelligence_Agent_Based_Modeling_ABM)

#### Change a rule, watch a population

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

### 148. SwarmIntelligence Ant Colony Optimization

[Live text](http://localhost:3003/compose?map=SwarmIntelligence_Ant_Colony_Optimization)

#### Directions left for someone else

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

### 149. SwarmIntelligence Particle Swarm Optimization

[Live text](http://localhost:3003/compose?map=SwarmIntelligence_Particle_Swarm_Optimization)

#### Better according to which score?

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

### 150. SwarmIntelligence Swarm Intelligence Algorithms

[Live text](http://localhost:3003/compose?map=SwarmIntelligence_Swarm_Intelligence_Algorithms)

#### Who keeps the ecosystem going?

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

## Machine Learning: Algorithms That Learn

### 151. ML Evolution

[Live text](http://localhost:3003/compose?map=ML_Evolution)

#### Survival without a finish line

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

### 152. ML Gradient Landscape

[Live text](http://localhost:3003/compose?map=ML_Gradient_Landscape)

#### Three meanings of error

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

### 153. ML Classification

[Live text](http://localhost:3003/compose?map=ML_Classification)

#### A boundary that moves with its centre

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

### 154. ML Neural Networks

[Live text](http://localhost:3003/compose?map=ML_Neural_Networks)

#### A connection changed by an error

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

### 155. ML Perception

[Live text](http://localhost:3003/compose?map=ML_Perception)

#### An edge is not yet an object

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

### 156. ML Sequence Memory

[Live text](http://localhost:3003/compose?map=ML_Sequence_Memory)

#### What should survive the next input?

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

### 157. ML Generative

[Live text](http://localhost:3003/compose?map=ML_Generative)

#### Learning from an opponent’s response

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

### 158. ML Synthesis

[Live text](http://localhost:3003/compose?map=ML_Synthesis)

#### The point outside the rule

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

## Graph Theory: Connections Define Structure

### 159. GT Foundations

[Live text](http://localhost:3003/compose?map=GT_Foundations)

#### Two travellers, one graph

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

### 160. GT Layout

[Live text](http://localhost:3003/compose?map=GT_Layout)

#### A connection is not a coordinate

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

### 161. GT Pathfinding

[Live text](http://localhost:3003/compose?map=GT_Pathfinding)

#### The route after a stone disappears

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

### 162. GT Network Analysis

[Live text](http://localhost:3003/compose?map=GT_Network_Analysis)

#### Important by which measure?

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

### 163. GT Connectivity

[Live text](http://localhost:3003/compose?map=GT_Connectivity)

#### A way back

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

### 164. GT Spanning Trees

[Live text](http://localhost:3003/compose?map=GT_Spanning_Trees)

#### The price of one more route

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

### 165. GT Flow

[Live text](http://localhost:3003/compose?map=GT_Flow)

#### What a junction cannot pass on

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

### 166. GT Matching

[Live text](http://localhost:3003/compose?map=GT_Matching)

#### A pair that blocks two pairs

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

## Foundations Crisis: The Limits of Formalization

### 167. Euclid Parallel

[Live text](http://localhost:3003/compose?map=Euclid_Parallel)

Click the plaque five times and you arrive back at the first postulate. The counter wraps:

```gdscript
#### euclid_postulates_plaque.gd:202
func next_postulate():
	current_postulate = (current_postulate + 1) % 5
```

Five clicks, five postulates, one closed loop. Four of them fit on two short lines. The fifth needs four lines and a parenthesis. That is the whole principle, and you can repeat it after one walk: this space is flat because the room says so, not because anyone measured it.

##### 1 — The five, stored as text

<!-- @euclid_postulates_plaque -->
<!-- ~tutorial#p2 ~tutorial#p4 ~critical#the-rule-that-could-not-be-proven -->

Let's start where the build starts. The tutorial keeps the five postulates as strings in a constant array — text, not logic, so a plinth can show them without a parser. The shipped plaque makes the same choice, and bakes its own line breaks in:

```gdscript
#### euclid_postulates_plaque.gd:46
	"IV. All right angles are\nequal to one another.",
	"V. If a line crosses two lines\nand interior angles sum < 180°,\nthe two lines meet on that side.\n\n(The Parallel Postulate)"
```

Read those two as sentences. The fourth states an equality and stops. The fifth carries a condition, a threshold, a prediction — and then names itself.

The difference is not length. The first four hand you permissions: what a hand with a straightedge may do. The fifth tells you what will happen once your hand has done it. It is a rule shaped like a forecast, and a forecast asks to be checked. Twenty-three centuries of checking failed, and the failure was read as a gap in the mathematicians.

Fair — and let's say what the array does about it. The fifth is the only entry carrying a blank line inside itself.

It uses that blank line to introduce itself. Nothing else on the plaque has to.

##### 2 — Marked before anyone argues

<!-- @euclid_postulates_plaque -->
<!-- ~tutorial#p10 ~tutorial#p11 ~critical#performativity-of-the-obvious -->

Before you have read a word, the room has told you which postulate matters. The gold arrives ahead of the argument.

It does, and we can point at the line that does it. The tutorial tints the fifth plinth and scales it by 1.2; the shipped plaque runs the same move as a branch:

```gdscript
#### euclid_postulates_plaque.gd:121
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

##### 3 — Three lines that never meet

<!-- @parallel_lines -->
<!-- ~tutorial#p13 ~tutorial#p14 ~artifacts#parallel-lines ~critical#the-state-of-exception -->

The tutorial draws five lines at `y := -2.0 + i * 1.0` — even spacing, one unit apart, a picture in which Euclid's claim looks like a property of the world. The shipped scene has three, placed by hand:

```gdscript
#### parallel_lines.tscn:7
[node name="Line1" parent="." instance=ExtResource("1_line")]
transform = Transform3D(0.258819, 0, 0.965926, 0.965926, 0, -0.258819, 0, 1, 0, -0.0648265, 0, 0)
```

Let's count the gaps. Line2 sits at 0.204004, Line3 at 0.305252. The first gap is about 0.27, the second about 0.10. The registry calls this artifact three line modules arranged to visualize equidistant lines. The transforms are not equidistant.

The parallelism survives. All three share a basis, so they run forever without meeting, whatever the spacing. Equidistance is a consequence the fifth postulate guarantees, and it is the part the declaration asserted instead of building. The word carried what the numbers did not.

Try it yourself: move Line3's offset out to 0.4 and count the gaps again. They change, and the lines still never meet. Spacing you can set by hand; parallelism comes from the shared basis.

And nothing in the room says the word out loud: the scene's `Label3D` ships with `visible = false`.

So you supply it. You look at three lines, name them parallel, and the naming arrives as sight.

##### 4 — The triangle that says sixty

<!-- @angle_sum_triangle -->
<!-- ~summary#p3 ~blurb#p3 ~critical#what-the-axiom-conceals -->

The triangle's three corners are literals — apex at `size * 0.5`, base corners at `-size * 0.4` and `size * 0.4`. Then we hand the labels their text:

```gdscript
#### angle_sum_triangle.gd:151
	var angles = ["60°", "60°", "60°"]
	var sum_text = "60° + 60° + 60° = 180°"
```

The shape those vertices make is isoceles, not equilateral. The file records its own measured corners: 53.1, 63.4, 63.4. Both triples sum to 180. The three sixties are shipped bytes, handed back rather than measured.

So the sum is true and the parts are ornament. Three equal numbers describe a triangle you are not looking at. It is the plaque's move again in another material: one surface makes unlike things look alike — five postulates in a single row, three identical angles under one figure. What gets hidden is not a falsehood. It is a difference.

The file already knows better, in a function just above. `_angles()` reads each corner off the polyline it actually drew, and at any curved opening the labels print what was measured. At `flat` it prints the shipped strings, because three placements ship them.

Keeping three maps byte-identical is a reason to print sixty. It is a reason about shipping, not about triangles. The geometry never asked for it.

##### 5 — The setting you cannot reach from here

<!-- @angle_sum_triangle -->
<!-- ~tutorial#p16 ~tutorial#p17 ~critical#performativity-of-the-obvious -->

Let's measure how far the other spaces sit from this floor. The tutorial toggles the fifth and a second preview fractures. The shipped artifact has a real axis:

```gdscript
#### angle_sum_triangle.gd:49
@export_enum("flat", "hyperbolic", "elliptic") var opening: String = "flat"
```

Map tokens reach it only through one gate:

```gdscript
#### angle_sum_triangle.gd:203
	if config_data.has("opening"):
		var want: String = str(config_data["opening"]).strip_edges().to_lower()
		if OPENING_VALUES.has(want) and want != opening:
```

Every placement here ships the bare token, so that `has("opening")` is never true and `_polyline()` short-circuits past the arc loop. What happens if a placement hands it `opening=elliptic`? The edges bow outward at six percent of each chord, the corners open, and the printed sum climbs near 260. Hyperbolic falls near 100. Both are legal geometries. Try the token and watch the equation stay true while the number stops being 180.

So the other two spaces are already here, priced in degrees, one word away — and no move a body makes on this floor arrives at them. What a body can reach is the whole question. A geometry that ships in the file and waits on a placement is not absent; it is held back. The room offers one space and lets the absence of the others do the arguing.

##### 6 — A screen with nothing to flatten

<!-- @science_screen -->
<!-- ~artifacts#science-screen ~summary#p2 ~critical#the-state-of-exception -->

The screen scans eight metres for neighbours that answer `get_grid_data()` and paints their cells at 768 by 576. Neither script here defines that method. The plaque offers `apply_grid_config`, two signals and three exports; the triangle offers `apply_grid_config` and two exports, `opening` and `size`. Nothing offers the one call the screen makes. So we open on the fallback:

```gdscript
#### science_screen.gd:317
	_point_mode = true
```

The fallback is not a blank panel. It is a grid: white, square, right-angled, drawn before anything arrives to be drawn. The screen does not wait to learn what space it is in. It draws right angles whether or not anything is there, and right angles are this room's postulate in pixels.

Test it. Cross the room and watch the picture — it does not change, because nothing here gives it anything to change into. And this file has been fooled by its own paperwork before: its axis block once declared value names that were never in its enum. The sweep set them, the artifact fell back to its default, and sixteen identical frames were published — sixteen pictures of the same screen, filed as four variants. Nothing failed loudly.

A declaration outrunning its code, twice in one room. Here it arrives as a white grid rather than an error, which is how such things usually arrive.

##### 7 — What the spec asked for and what stands here

<!-- @angle_sum_triangle -->
<!-- ~intent#p1 ~tutorial#p19 ~walked#what-it-opens ~summary#p4 ~blurb#p2 ~critical#the-state-of-exception -->

The tutorial closes with a scroll — 300 BCE Euclid, 1733 Saccheri, 1829 Lobachevsky, 1832 Bolyai, 1854 Riemann — and a door that unlocks after two seconds of reading. The spec asked for two interactive demos, `parallel_line_demo` and `euclid_parallel_demo`, that let you drag the lines. Neither is placed.

We can see that absence from inside the code. Every placement here ships a bare token, and a bare token arrives as an empty dictionary:

```gdscript
#### angle_sum_triangle.gd:197
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
```

Three lines, and the only door into the geometry shuts before it opens. What stands here is a plaque, three lines, a triangle, a screen — and the building itself: an eleven by fifteen floor, pillars three units tall in mirror symmetry down both sides, a walkway left open between them. Walk that walkway and you are standing inside the assumption. The colonnade is the axiom, built at the size of a body.

The absence is honest about the work. You are not here to bend a parallel. You are here to stand where bending is out of reach, and to feel how little effort that costs. The exit asks the question the furniture declines, and the next room takes the fifth away.

Count once more: five postulates, three lines, one triangle, one screen, two rows of pillars. Every number is true. Not one of them is necessary.

You can stand on a floor and still ask what is holding it up.

### 168. NonEuclidean Spaces

[Live text](http://localhost:3003/compose?map=NonEuclidean_Spaces)

A bowl on your left, a dome on your right, and a flat plate between them that no longer looks like the default.

The previous room let you stand inside an assumption until it stopped feeling like one. This room puts the assumption on a dial. There is a slider here with a number on it, and the number is the curvature of space — negative to the left, zero in the middle, positive to the right. Flatness is the detent at zero. It is not the centre because it is correct; it is the centre because it is zero.

##### One number, and it is not a metaphor

<!-- @curvature_slider -->

```gdscript
#### curvature_slider.gd:10
#### critical_parameter: curvature — the ONE number that determines the entire geometry
```

Gaussian curvature, K, running from −1 to +1. That single scalar decides whether parallel lines diverge, stay apart, or converge; whether a triangle's angles sum to less than, exactly, or more than 180°; whether the shortest path between two points looks straight to you from outside. Not three geometries with three rulebooks. One rulebook with one free parameter.

This is the nineteenth century's actual discovery, and it is more unsettling than "there are other geometries." Gauss, Bolyai and Lobachevsky did not find a strange new space next door to the real one. They found that the space we were in had a setting, and that nothing in mathematics specifies which value it should take. Euclid's fifth postulate turns out to be the statement *K = 0* — not an axiom about parallels, a choice about curvature, wearing a sentence about lines.

##### Where the wire is missing

<!-- @poincare_disk -->

```gdscript
#### curvature_slider.gd:110
curvature_changed.emit(curvature)

#### poincare_disk.gd:19 — and the only other place this signal name appears
signal curvature_changed(value: float)
```

Here is the room's own honest gap, and it is worth knowing before you turn anything.

The slider emits. Its registry entry says so plainly — *emits curvature_changed signal for linked surfaces* — and line 110 does exactly that, every time you move it. Search the rest of the project for anything that connects to it and you find one hit: the Poincaré disk, which declares the identical signal and emits it too. Two objects broadcasting the same message into a room where nothing is subscribed.

So the four surfaces standing around you — the saddle, the dome, the disk, the sphere — do not move when you turn the dial. Each one says so in its own header, in the same four words: *VR controls [missing]*. They are four fixed illustrations of four values of a parameter that is, in this room, unconnected to them.

Do not file that as a defect and move on. Notice what it makes the room into. You have a control that publishes a number, and a set of worlds that were each built at one value of it and cannot hear. That is a fairly exact picture of the situation the chapter is describing: the parameter is real, the consistency of each setting is real, and the passage between them is the thing nobody has built.

##### The one that listens to itself

<!-- @triangle_curvature_workbench -->

```gdscript
#### triangle_curvature_workbench.gd:7
#### critical_parameter: K — discrete in {-2, -1, -0.5, 0, +0.5, +1, +2}. Drives surface
####   choice, edge geodesic type, angle measurement, and the excess/deficit readout
```

At the far corner, one bench does work. It carries its own slider — seven detents rather than a continuum — and when you turn it the surface underneath the triangle changes, the edges are rebuilt as geodesics *on that surface*, and the angle sum is measured and printed.

Measured. This is the payoff for the room you just left, where the angle sum was a hard-coded string reading `"60° + 60° + 60° = 180°"`. Here the number comes out of the geometry, and at K = 0 it lands on 180 not because anyone typed it but because that is what the flat case computes to. The same claim, arrived at two different ways, one room apart — and only one of them could ever have come out differently.

What it is showing you is the Gauss–Bonnet theorem: the amount by which a triangle's angles overshoot or fall short of 180° is exactly the curvature enclosed. Angle sum is not a fact about triangles. It is a measurement of the space the triangle is lying in, which is what the artifact's own header says: *the triangle doesn't know it's "in 3D"; it only knows its host*.

##### Both neighbours of zero

<!-- @hyperbolic_surface -->

```gdscript
#### hyperbolic_surface.gd:9
#### essence: y = K(x² - z²) — saddle surface with negative Gaussian curvature K < 0
```

The saddle. Space curving outward, so that two geodesics starting parallel drift apart, and a triangle's angles fall short. Its header says something quietly good: *"straight" on a saddle looks curved from outside*. Straightness is not a property of the line. It is a relationship between the line and the surface it is confined to, and there is no outside vantage from which the surface is wrong.

<!-- @elliptic_surface -->

```gdscript
#### elliptic_surface.gd:13
#### emerges: the realization that on a positively curved surface there are NO parallel lines at all
```

The dome, and the opposite. Geodesics that begin parallel converge and cross, and the angle sum overshoots. On a sphere, the fifth postulate is not merely false — the thing it asserts cannot happen at all, because every pair of great circles meets. Twice.

Stand between the two and the point of the chapter is available without argument. These are not deformations of a correct space. Each is internally consistent, each has been formalised, each has physical realisations, and neither can be reached from the other by fixing an error. Flatness is the one in the middle. That is a fact about the number line, not about the world.

##### The finite that holds the infinite

<!-- @riemann_sphere -->

```gdscript
#### riemann_sphere.gd:10
#### desire: see the infinite complex plane folded onto a finite sphere — the north pole IS infinity
```

Two objects here do the same trick from different directions and it is worth catching. The Poincaré disk compresses an entire infinite hyperbolic plane inside a finite circle: geodesics are arcs meeting the rim at right angles, and the rim is not an edge, it is infinity, which is why the tiles crowd and never arrive. The Riemann sphere does the mirror of it — the whole complex plane wrapped onto a ball by stereographic projection, with infinity as a single point you can walk around and look at from behind.

Both are saying that "infinite" and "unbounded" are not the same word, and that where you put the boundary is a modelling decision rather than a discovery. Which is the same sentence as the slider, one level up.

##### What the dial cannot decide

Geometry was chosen, not found. That is settled by the time you leave this room, and it is settled without anyone having to be wrong.

But notice the shape of what just happened, because the next room breaks it. Every question here was answered by picking a value: what is the angle sum, do parallels meet, is the space finite — each one becomes answerable the moment K is fixed. The crisis so far is only that *we* pick K, and nothing outside picks it for us.

The next question does not have that form. It is not about which setting to choose. It is what happens to a rule that includes itself in the range of things it applies to — and there is no value of any parameter that makes that come out.

Flatness is a special case. The ground itself is a variable.

### 169. Russell Paradox

[Live text](http://localhost:3003/compose?map=Russell_Paradox)

Four objects arranged as a cross, with a box at the centre, and every one of them is the same sentence said in a different material.

The last two rooms were about a choice: an axiom is a decision, and the decision has a dial. Both crises were survivable, because in both cases you could pick a value and carry on. This room is where that stops working. Nothing here is waiting for you to choose. The trouble is in the shape of the rule itself, and no setting fixes it.

##### The box at the centre

<!-- @russell_set_box -->

```gdscript
#### russell_set_box.gd:20
#### essence: S = { x | x ∉ x }; S ∈ S ↔ S ∉ S — Russell's paradox as infinite regress
```

Take the set of all sets that are not members of themselves. Ask whether it contains itself.

If it does, then by its own definition it must not. If it does not, then by its own definition it must. There is no third option and no order of operations that gets you out; the two branches feed each other exactly. Russell sent this to Frege in 1902, while the second volume of Frege's *Grundgesetze* was at the printer, and Frege added an appendix beginning with the observation that a foundation had given way under the finished building.

The artifact makes it a box you open, and inside is another box, and inside that another. Its critical parameter is `max_visible_depth` — how many nestings to draw before giving up and showing the regress indicator. That is an honest piece of engineering: the object cannot be built, so the artifact builds as much of it as fits and then admits, in a label, that the remainder is not a rendering budget but the thing itself.

##### The same shape, three more times

<!-- @barber_paradox -->

```gdscript
#### barber_paradox.gd:11
##### truth: he belongs in neither bin; the rule eats itself. If the barber shaves
#####   himself he is shaved-by-the-barber (forbidden); if he does not, the rule
#####   says the barber must shave him — contradiction either way.
```

Two labelled bins — SHAVES SELF, SHAVED BY BARBER — and one token that will not go in either. The barber shaves exactly those who do not shave themselves. Put him anywhere and the rule immediately requires him somewhere else.

Russell offered this himself, as the version you can tell at dinner, and it is worth noticing that it is not a simplification. The bins are the point: a classification that is exhaustive and exclusive, with one element that the classification generates and cannot place.

<!-- @liar_loop -->

```gdscript
#### liar_loop.gd:11
##### truth: if it's true it's false, if it's false it's true. There is no stable
#####   assignment — the value loops forever.
```

A chalk sign reading THIS STATEMENT IS FALSE, with a lamp above it that cannot settle. The oldest of the four — Epimenides, then Eubulides, twenty-four centuries before set theory — and mechanically identical to the box. A predicate applied to the sentence containing it. The lamp does not flicker because the artifact is animating an effect; it flickers because there is no value to hold.

<!-- @self_membership_set -->

```gdscript
#### self_membership_set.gd:12
##### truth: a set that is a member of itself, all the way down — and the set of
#####   all sets that are NOT members of themselves cannot consistently exist.
```

The fourth arm, and the one that draws the distinction the other three leave implicit. A set that *does* contain itself is perfectly consistent — this artifact builds one, a brace inside a brace inside a brace, and nothing goes wrong. Self-reference on its own is not the fault. The catch is self-reference plus negation: the moment the rule is *not* a member of itself, the loop closes on a contradiction rather than on a regress.

That distinction is what saves mathematics later. The repairs — Zermelo–Fraenkel's axiom of separation, Russell's own type theory — do not ban self-reference. They ban unrestricted comprehension: the assumption that any property whatsoever carves out a set. You may still describe; you may no longer assume the description has an extension.

##### The one that settles

<!-- @hilbert_hotel -->

```gdscript
#### hilbert_hotel.gd:7
#### critical_parameter: the shift map n ↦ n+1 — the bijection that proves |ℕ| = |ℕ + 1|
```

Two cells off the cross stands something that does not belong to the argument, and it is worth a sentence rather than a shrug, because it teaches the opposite lesson and it is standing close enough to be mistaken for a fifth arm.

Hilbert's hotel is full, infinitely, every room occupied. A guest arrives. Everyone moves up one, and there is a room. That looks like a paradox and behaves like one for about ten seconds, and then it resolves completely: the shift map is a bijection, the answer is *yes, there is room*, and the offended intuition was a finite intuition applied outside its range.

That is the difference this room needs you to hold. The hotel is a **surprise**, and it settles. The box, the barber, the liar and the brace are **contradictions**, and they do not. One of them is your intuition being wrong about infinity; the other four are a formal system being unable to say what it just said. Standing beside each other, they mark the line the rest of the chapter walks along.

<!-- @euclid_postulates_plaque -->

The plaque near the entrance is the fifth postulate again, brought forward from the first room. Nothing in this room explains why it is here, so take it as the chapter keeping its own receipt: two rooms ago the crisis was that a foundational statement could not be *proved*. Here it is that a foundational statement cannot be *stated*. The plaque is the earlier, milder version of the trouble, standing where you can see how much worse it got.

##### Where the wall is

Something has changed in the kind of problem. The parallel postulate was independent — you could go either way and both ways were consistent. Russell's set is not independent. There is no consistent system in which the question has an answer, and the repair is not to choose a value but to forbid the question from being asked.

That is what a formal system's boundary is, and it is the last quiet moment in this sequence. Two rooms from now the same argument returns with a much harder result attached: not that a system must fence off certain sentences to stay consistent, but that any system strong enough to be interesting will contain a sentence that is true and that it cannot reach — and that fencing will not help, because the sentence is about arithmetic and arithmetic is what the system is for.

Every formal system draws a boundary — and the boundary is where the system meets what it cannot hold.

### 170. Godel Incompleteness

[Live text](http://localhost:3003/compose?map=Godel_Incompleteness)

#### A truth outside the proof machine

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

### 171. Escher Impossible

[Live text](http://localhost:3003/compose?map=Escher_Impossible)

A staircase that goes up on all four sides and comes back to where it started.

Check any corner of it. The riser is a sensible height, the tread is level, the joint between this flight and the next is square. Check the next corner and the same is true. Walk the whole loop checking as you go, approve every junction individually, and you will arrive back at the step you began on having climbed the entire way. Nothing you inspected was wrong. The object cannot exist.

That is the room, and it is the same result as the one two doors back, arrived at through the eye instead of through arithmetic. Russell's box could not be built because a rule contained itself. This staircase cannot be built because sixteen local truths do not add up to a global one — and there is no local inspection that could ever have told you.

##### Sixteen joints, and the impossibility has to live in one of them

<!-- @escher_staircase -->

```gdscript
#### escher_staircase.gd:169
@export_enum("none", "hairline", "gap", "scaffold", "field") var seam: String = "none"
```

That line is the best thing in this room, because it is a dial whose settings are *where to put the contradiction*.

The artifact's own header spells the five out: smoothed into one quiet descending side and never named (`none`); gathered into a single closing riser you can point at (`hairline`); refused outright, so the loop is left open with two cut ends facing each other (`gap`); that same opening rigged with a tower and a landing so the walk becomes possible by cheating (`scaffold`); or spread evenly into all sixteen joints so the ring comes out level and no joint can be blamed (`field`).

The impossibility is conserved. It cannot be removed, only relocated — concentrated where it can be pointed at, or distributed until it is undetectable anywhere. That is exactly the property the room is arguing about consistency, expressed as a property of a Godot export.

The staircase here is placed as a bare token, so it stands at `none`: smoothed, and never named. The room's thesis is that the contradiction is in the whole rather than in any step, and its main body is set to the value that makes precisely that true. Whether that is a curatorial decision or an unset default, it is the right setting, and it is the reason the object reads as calm.

##### The step you cannot take

```gdscript
#### escher_staircase.gd:426
func climb_step() -> void:
```

The artifact has an API for walking it. Completing a full loop fires a `paradox_completed` signal. There is no `_input` handler in the file and no interaction volume anywhere in the scene, so nothing ever calls it — the header says as much, *has climb_step() API but no physical trigger*.

So the staircase whose desire is written down as *climb "up" forever and arrive where you started — feel the paradox in your legs* cannot be climbed. The signal for finishing the loop has no sender.

Worth sitting with rather than logging. The whole claim of this room is that walking the thing step by step is the procedure that fails to detect the fault — that local verification is exactly the method that cannot see a global contradiction. The one interaction that would let you perform that failure is the one that was not wired. You are left doing what the argument says you must do instead: standing back and taking in the whole, because there is no way to check it a piece at a time.

##### Where you have to stand

<!-- @penrose_triangle -->

```gdscript
#### penrose_triangle.gd:41
@export_enum("marker", "bare", "seam", "exploded", "sealed") var disclosure: String = "marker"
```

Three bars, three right angles, each corner square. The Penrose triangle — published by Roger Penrose and his father Lionel in 1958, described by them as impossibility in its purest form, and the direct source for Escher's *Waterfall*.

It has two settings and both matter. `disclosure` is how much the object confesses, running from a small marker through bare, to a visible seam, to exploded, to sealed. And `_is_at_sweet_spot` tracks whether you are standing in the one place from which the illusion coheres — because a Penrose triangle built in three dimensions is a real object with a gap in it, and there is exactly one line of sight along which the gap is hidden by perspective.

That second parameter is the honest one. The impossibility is not in the object; it is in the relationship between the object and a viewpoint. From anywhere else in this room the triangle is an ordinary bent thing with a break. Move to the sweet spot and it closes. Nothing about the bars changed.

Which reframes the staircase too. Consistency here is not a property the object has. It is a property of a *view* of the object, and the view is a position you can be standing in without knowing you chose it.

##### Two prongs, or three

<!-- @impossible_trident -->

```gdscript
#### impossible_trident.gd:13
##### truth: two prongs become three; the drawing is consistent locally and impossible
#####   globally — every junction is fine on its own, no assembly of them is.
```

The blivet, at the far end of the room. Read the base and you count two rectangular prongs. Follow them up and there are three round ones. There is no point along the drawing where the change happens; every band of it, covered at both ends, is a coherent picture.

It is the cleanest of the three because it removes the staircase's narrative and the triangle's perspective trick and leaves only the arithmetic: a count that is well-defined at both ends and different. The contradiction is not at a location. It is distributed across the transition, in the same way the staircase's `field` setting distributes it across sixteen joints so that no joint can be blamed.

##### This is not a pipe

<!-- @magritte_pipe -->

```gdscript
#### magritte_pipe.gd:2
#### essence: sign != signified -- a procedural pipe mesh with label saying this is not a pipe
```

The one tangent, and the blurb seats it deliberately. Magritte's painting is not an impossible object — it is perfectly coherent — and its trouble is one level up: the image of a pipe is not a pipe, and the sentence saying so is not a sentence about pipes but about images.

It is in this room because the other three all depend on the same move. A drawing of a staircase can be locally valid in a way no staircase can, because a drawing is not the thing. The impossible objects are only impossible once you insist the representation is a claim about a buildable world. Take away that insistence and they are just marks that agree with each other locally.

Which is the room's argument pointed at itself: *every data structure is a Magritte painting*, as the header puts it. A model is consistent internally and says nothing, by itself, about whether the thing modelled can be.

##### What checking cannot do

Consistency is not compositional. You can verify every step and learn nothing about the loop, and this is not a limitation of care or of time — it is a fact about what local verification is. The information that the staircase does not close is not present at any junction. It appears only in the sum.

That result is about to arrive in its formal version, which is worse, because there the whole under inspection is the checking system itself. Hold on to the trident: a count that is well-defined at both ends and different, with no place in between where it went wrong.

The contradiction isn't in any single step. It's in the whole.

### 172. Brouwer Intuitionism

[Live text](http://localhost:3003/compose?map=Brouwer_Intuitionism)

A staircase with a few steps at the bottom and nothing above them, and the nothing is not unfinished. It is the correct state.

Everything so far in this sequence has been a limit discovered from inside: a postulate that cannot be proved, a set that cannot be defined, a loop that cannot close. This room is the first of two answers, and it is the severe one. Brouwer's response to the crisis was not to patch the foundations. It was to say that a large part of what mathematics had been doing was never legitimate, and to give up the results rather than the standard.

The rule is one sentence. **To assert that something exists, you must produce it.**

##### The third option

<!-- @excluded_middle_demo -->

```gdscript
#### excluded_middle_demo.gd:9
#### essence: P ∨ ¬P — the law of excluded middle; Brouwer: "not always!"
```

Two glowing spheres, P and not-P, with the disjunction between them, and a slider that flips the room between classical acceptance and intuitionistic doubt.

Classically, `P ∨ ¬P` is free. Every proposition is true or false; you may use that before knowing which. It is what licenses proof by contradiction: assume not-P, derive absurdity, conclude P — and you have proved P exists without ever exhibiting it.

Brouwer refused the licence. For him a mathematical statement is not a description of a pre-existing fact but a report on a construction, and a construction either has been carried out or has not. So there is a third state, and the tutorial in this room names it exactly: not true, not false, **not yet constructed**. The third option is the whole point, and it is not ignorance. There is no fact of the matter waiting to be uncovered, because on this account the fact is made by the proof.

This is one of two objects in the room you can actually operate. Hold on to that.

##### Show me

<!-- @constructive_proof -->

```gdscript
#### constructive_proof.gd:9
#### essence: ∃x P(x) requires exhibiting x — no proof by contradiction allowed
#### critical_parameter: the witness — without an explicit construction, the proof is rejected
```

The distinction, made into an object: knowing something exists, versus being able to point at it.

The classical proof that there exist irrational `a` and `b` with `a^b` rational is the standard demonstration of how wide the gap is. Take √2 to the power √2. Either it is rational, in which case you are done, or it is irrational, in which case raise it to √2 again and you get 2, and you are done. The proof is valid, it is three lines, and at the end of it you cannot say which of the two cases you are in. It has proved that a witness exists without producing one.

Brouwer's answer is that it has therefore proved nothing. The word *exists* was doing work it had not paid for.

What that costs is enormous, and honesty about the cost is part of teaching it: intuitionistic mathematics loses large parts of analysis, most of the theory of infinite sets, and any theorem whose only proof runs through contradiction. Brouwer accepted the loss. Hilbert, who did not, wrote that taking excluded middle from the mathematician was like taking the telescope from the astronomer.

##### Always unfinished

<!-- @brouwer_choice_sequence -->

```gdscript
#### brouwer_choice_sequence.gd:8
#### essence: a₁, a₂, a₃, ... , ?, ? — each term chosen freely, never completed
#### critical_parameter: time — the sequence unfolds perpetually, dots gently bobbing
```

A row of terms trailing off into question marks. Brouwer's choice sequences are his positive proposal, not just his prohibition: an infinite object that is never completed, only ever extended, where the next term is chosen and not determined. Infinity as a process rather than a finished set.

Now read the two lines above against each other. The essence says *each term chosen freely*. The critical parameter is `time`, and the sequence unfolds perpetually on its own. Its header names the missing piece without flinching — *could add ability to "choose" the next term* — so the object whose entire content is free choice runs on a timer and chooses for you.

That is the room's central irony and it is not confined to this one body. Of the four stations of the argument, two have controls and two do not; `constructive_proof` says *VR controls [missing]* in the same breath as declaring that the witness must be exhibited. A room whose claim is that nothing exists until a hand makes it, in which most of the hands are absent.

I would not repair that by wiring buttons to everything. The gap is more useful named than closed, because it is the actual condition the philosophy describes: the construction is *possible*, nobody has performed it, and on Brouwer's own terms that means it does not yet exist. The room is in the state it is teaching.

##### The step that is not there yet

<!-- @constructive_staircase -->

```gdscript
#### constructive_staircase.gd:14
##### truth: the next step isn't true-or-false until you build it — existence is
#####   construction, not the absence of a contradiction.
```

Built steps are solid. Above them there is nothing, and the nothing is not a gap in the model.

A classical mathematician looks at the unbuilt region and says: either the seventeenth step exists or it does not, we simply have not looked. Brouwer says there is no seventeenth step to have a property, and there will be one when someone builds it. Not hidden. Not undetermined. Absent.

That is the difference between an epistemic gap and an ontological one, and it is the hardest idea in the room, which is why it is worth having it as a thing you can stand at the bottom of and look up from.

##### The one that does it properly

<!-- @cantor_diagonal_workbench -->

```gdscript
#### cantor_diagonal_workbench.gd:6
#### desire: learner viscerally feels uncountability — you can list "all" reals, and we
####   will construct one that isn't in the list, just by flipping the diagonal
```

Nothing in the room says why this bench is here, so here is why it earns its place: it is the model constructive proof, and it is the other object you can operate.

Cantor's diagonal argument is often taught as a proof by contradiction — assume the reals are listable, derive absurdity — but it does not have to be, and this bench does not present it that way. Turn the slider, the list grows, the diagonal extends, and a number is *built*, digit by digit, that differs from the first entry in the first place, the second in the second, and so on. At the end you are holding the witness. It is not that a missing real must exist; it is that here it is, and you watched it being made.

So this is what Brouwer is asking for, standing in the same room as the objects that cannot deliver it. The procedure scales, it terminates at any length you choose, and it hands you the thing.

##### The two that assert

<!-- @angle_sum_triangle -->

<!-- @parallel_lines -->

Two objects have been carried forward from the first room and left here without explanation. They are the triangle whose angles sum to 180°, and the pair of parallel lines.

They are also, of everything in this sequence, the two artifacts that *assert rather than construct*. The triangle does not measure its corners; it prints the string `"60° + 60° + 60° = 180°"`, and the `curvature` knob its own header names appears six times in the file, every one of them inside a comment. The parallel lines have no script at all — the scene file is two line instances and two hand-typed transform matrices, parallel because somebody decided so and typed the numbers.

In a room about constructive proof, that is the entire lesson standing in the corner. Both objects state a result. Neither exhibits a witness. Both are, on the strict reading this room is teaching, claims for which no construction has been performed — and both are perfectly convincing to look at, which is the danger Brouwer was pointing at.

Whether they were placed here for that reason, I cannot tell from the map. They earn the position either way.

##### What it costs

This is the harder of the two responses to the crisis, and it works by giving things up. Brouwer keeps certainty by shrinking mathematics to what has been made, and pays for it in theorems.

The next room takes the opposite route. Rather than refusing to assert what cannot be built, it refuses to panic about holding two assertions that contradict each other. Where Brouwer removes the third option and calls it *not yet*, Florensky keeps both options at once and declines to let the contradiction spread.

No existence without witness. No truth without a hand that built it.

### 173. Florensky Paraconsistent

[Live text](http://localhost:3003/compose?map=Florensky_Paraconsistent)

A door frame with two leaves in it, one swung open and one shut, both there at once, and you can walk through.

The last room answered the crisis by giving things up: assert only what you have built, and lose the theorems that depended on assuming otherwise. This room answers it the other way. It keeps the contradiction, keeps working, and gives up something much smaller than you would expect.

What it gives up is a single inference rule. Not truth, not rigour, not consistency in any sense you would miss — one rule, called *ex falso quodlibet*, which says that from a contradiction anything whatsoever follows.

##### The rule that does the damage

<!-- @both_true_gate -->

```gdscript
#### both_true_gate.gd:15
##### truth: P and not-P, and the world does not end — the contradiction is contained,
#####   not detonated.
```

In classical logic, one contradiction is fatal to a whole system — not locally, everywhere. If both P and not-P are derivable then every sentence in the language is derivable, including every falsehood, and the system stops distinguishing anything from anything. That total collapse is why a single inconsistency is treated as catastrophic. It is not that the contradiction is embarrassing. It is that it spreads.

Paraconsistent logic blocks that step and nothing else. Contradictions may be derivable and are not permitted to imply arbitrary conclusions. The tutorial in this room states the containment exactly: *contradictions exist in the box; they cannot escape as anything follows.*

The gate makes it a thing you walk through. Both leaves are real, the frame holds them, and the room around it is not on fire. That is the entire claim, and the reason it needs to be a body rather than a sentence is that the sentence sounds like a trick and the door does not.

##### A resting state, not an exception

<!-- @florensky_sphere -->

```gdscript
#### florensky_sphere.gd:21
#### critical_parameter: current_state — BOTH (A ∧ ¬A) is the resting state, not the
####   exception; observation collapses it to A or ¬A only briefly
```

A double-faced sphere whose skin reads from both sides, holding A and not-A on one surface.

Read the parameter carefully, because the ordering is the argument. BOTH is where the object rests. Looking at it can knock it briefly to one side, and it returns. This is the inverse of the arrangement you would expect and the inverse of the two objects across the room: the single-valued states are the transient ones, and the contradiction is the stable configuration.

Pavel Florensky was a mathematician, an Orthodox priest and an electrical engineer, and he argued that the deepest truths are antinomic — that a contradiction properly held is not a failure of thought but its highest form. He wrote that while working as a physicist in the Soviet Union; he was executed in 1937. The artifact's header calls the contradiction *a MODE OF BEING* rather than a defect, and that is a fair rendering of his position rather than a decoration on it.

One mechanical detail earns a look. To show both faces of one surface the artifact has to disable back-face culling, so the inside and the outside of the same skin both catch light. Everywhere else in this project turning culling off is a compromise; here it is the argument. A surface that can only be seen from one side cannot hold two readings.

##### The foil, and it is a foil

<!-- @schrodinger_box -->

<!-- @superposition_display -->

```gdscript
#### schrodinger_box.gd:12  ·  superposition_display.gd:10 — the same axis, twice
#### critical_parameter: remainder — where the box puts the part of the state it cannot
####   show you (core | twin | seam | haze | witness)
```

Two quantum objects stand across from the two logical ones, and it would be easy to read them as the same idea in physics dress. They are the opposite idea, and the room is arranged so you can catch the difference.

The cat is both alive and dead until observed — and then it is not. Observation collapses the superposition to one branch and the other is gone. The display says the same thing about a qubit: `|ψ⟩ = α|0⟩ + β|1⟩`, genuinely occupying both, and genuinely resolving to one when measured. Both are contradictions *with an expiry*. The world tolerates them precisely because looking ends them.

Now notice what the two of them share and the other two do not. Both carry an axis called `remainder`, with five settings, and its job is to decide where the object puts *the part of the state it cannot show you*. Core, twin, seam, haze, witness — five architectures for the unshowable.

The gate and the sphere have no such axis, and do not need one. Nothing is being held back. Both leaves are in the frame; both faces are on the sphere. The quantum pair need a hiding place because their contradiction is not permitted to persist in view; the paraconsistent pair do not, because theirs is.

That is the distinction to leave the room with, and it is easy to lose: **collapse-on-observation is the foil, not the model.** Superposition resolves and paraconsistency refuses to. Placing them four metres apart is the room's whole method.

##### Two answers, both live

Stand back and this room and the last one are a matched pair, and the sequence puts them in this order deliberately.

Brouwer takes the crisis to mean the standard was too loose: stop asserting what you cannot construct, accept a third state between true and false, lose the theorems. Florensky takes it to mean the demand was too strong: keep both assertions, block the explosion, lose one inference rule.

Neither repairs the foundation. Both are ways of continuing to work on a foundation that is known not to close, and they disagree about which piece of classical logic was the mistake. That they are both viable is the actual state of the field, and it is more interesting than a resolution would have been.

The last room takes that seriously in a way neither of these two quite does. If the gap cannot be closed by tightening or by loosening, then the gap is not a defect in the method — it is what the method runs on.

Paraconsistent logic doesn't resolve contradiction. It refuses the demand that contradiction must resolve.

### 174. Crisis Synthesis

[Live text](http://localhost:3003/compose?map=Crisis_Synthesis)

One line of text floating at eye height, and four wings leading off to the objects that earned each of its terms.

```
QFE = F − λE(S) + φΔE(S,t)
```

You have walked seven rooms of things that could not be closed: a postulate that would not be proved, a geometry that turned out to be a setting, a set that could not be defined, a staircase that checked at every joint and could not exist, and two incompatible ways of carrying on afterwards. This room does not resolve any of it. It says that the not-closing was the productive part.

##### The formula, and which term is lit

<!-- @qfep_formula_3d -->

```gdscript
#### qfep_formula_3d.gd:11
#### critical_parameter: highlighted_term — the book-role privileges φΔE(S,t): it is the
####   queer generative term, the OPEN one
```

Three terms. `F` is fit — how well a system satisfies its own constraints. `λE(S)` is entropy, scaled by λ, subtracted: the pull toward order, toward closing, toward the crystal. `φΔE(S,t)` is the rate of change of entropy over time, scaled by φ, and it is added.

The third term is the one this whole sequence has been arguing for. The first two describe a system that wants to settle: maximise fit, minimise disorder, arrive somewhere and stop. On their own they describe exactly the ambition that Hilbert's programme had and that Gödel ended — a formal system that closes. The third term is what a system does when it cannot close, and its sign is positive.

The artifact's header is explicit that this is a reading rather than a calculation: *to be read, not solved*. Walk up to any single term and it brightens, and the sentence tilts. Under `F` it is an optimisation. Under `λE(S)` it is thermodynamics. Under `φΔE(S,t)` it stops being a balance sheet and becomes a description of something that keeps moving because it has nowhere final to arrive.

##### Two dials you can hold

<!-- @lambda_slider -->

```gdscript
#### lambda_slider.gd:15
#### critical_parameter: lambda — the single number that controls order/chaos balance
####   across the entire QFEP system
```

λ from 0 to 1, on a rail with a colour gradient from blue through green to red, and it broadcasts to the whole room. At the low end the system is loose and noisy; at the high end it crystallises. The interesting readings are not at either end. The header names the zone: *the green zone at 0.3–0.5 where particles and color converge — the sweet spot finds you*.

<!-- @phi_slider -->

```gdscript
#### phi_slider.gd:41
#### critical_parameter: phi — rate sensitivity that determines whether the system fights
####   or welcomes transformation
```

φ from −1 to +1, purple through grey to gold, and it is the one that carries the argument. Negative φ is a system that resists change — the header says it feels heavy, with the particles falling. Positive φ welcomes it and they rise. Grey in the middle is a system indifferent to its own transformation.

The asymmetry is the point, and it is unusual for a parameter to be built with a preferred direction stated out loud. This one is: the generative reading is the positive one, and the room lets you set it the other way and feel the difference in your hand rather than be told.

##### The edge, which you cannot move

<!-- @bifurcation_diagram -->

```gdscript
#### bifurcation_diagram.gd:16
#### essence: x(n+1) = r·x(n)·(1 - x(n)); period doubling cascade → chaos at r ≈ 3.57
#### needs: VR slider for r [missing] — highlight plane tracks current_r but no physical controller
```

The logistic map. One line of arithmetic, one parameter, and a picture that goes from a single stable value, to an oscillation between two, to four, to eight, and then — at r ≈ 3.5699 — to chaos, with windows of order inside the chaos, at every scale.

It is here because it is the clearest available demonstration that the interesting behaviour of a system lives at its boundary and nowhere else. Below the cascade the map is dead: it settles and stays. Above it, structure at every magnification. And Feigenbaum's discovery is that the constants governing the cascade are the same for *every* system that period-doubles, which makes the edge a universal feature rather than an accident of this equation.

Two dials in this room can be grabbed. This one cannot — the highlight plane tracks `r` but nothing lets you move it. The room's claim is that the sliders show life only at the boundary, and the object that *is* the boundary is the one with no slider. Worth naming rather than filing: what you can hold here are the two parameters of the thesis, and the thing they are a thesis about is on rails.

##### A room inside the room

<!-- @goedel_atrium -->

```gdscript
#### goedel_atrium.gd:28
#### needs: nothing. The room is self-contained, which is precisely its [point]
```

An atrium with a plinth at its exact centre, and on the plinth a model of the atrium, at one tenth scale, with a plinth at its centre. Default recursion depth is 2. Stand in the doorway and you can see your own doorway inside it.

Of everything in this sequence this is the object that most nearly *is* its subject rather than depicting it. A formal system strong enough to describe itself contains a description of itself, and that description contains a description, and the regress is not a bug in the encoding — it is the encoding working. Gödel's construction does exactly this: it arithmetises the syntax of arithmetic so that statements about proofs become statements about numbers, and then finds a number that says of itself that it has no proof.

The `needs` field of most artifacts in this project lists what is missing. This one says *nothing*, and gives the reason: self-containment is what it is for. It is the only artifact I have read whose statement of completeness is also its argument.

##### The wings

<!-- @godel_statement_plaque -->

<!-- @russell_set_box -->

<!-- @escher_staircase -->

<!-- @florensky_sphere -->

Four objects return here from the rooms they came from: the plaque that asserts its own unprovability, the box that cannot contain itself, the staircase that checks and cannot exist, and the sphere that holds A and not-A at rest.

Three of those are crises. The fourth is a response. Brouwer is not here — the tutorial's own wing list names him, but no constructivist artifact is placed, and the blurb agrees with the map rather than with the tutorial. So the synthesis assembles three demonstrations that formal systems have an outside, plus one demonstration of how to keep working anyway, and the other way of keeping working — build it or do not assert it — is absent from the summit.

That is a real asymmetry and it is arguably the right one. Florensky's answer is the one this formula takes: hold the contradiction, do not let it detonate, keep going. Brouwer's answer is to shrink the system until it closes, which is precisely what the third term of the formula says a living system does not do. The missing wing is a position the room has rejected rather than forgotten.

<!-- @russell_paradox_workbench -->

```gdscript
#### russell_paradox_workbench.gd:6
#### desire: learner viscerally feels that self-reference per se is not the problem
####   (cell 4, S = {x : x ∈ x}, is consistent) — it is self-reference plus [negation]
```

A second Russell station, and it says the more precise thing than the box does: walk six set definitions on a slider and watch which ones close on a contradiction. The fourth is self-referential and perfectly consistent. Self-reference is not the fault; self-reference plus negation is.

That correction matters at the summit, because otherwise the sequence's moral collapses into *systems that look at themselves break*, which is not true and would make the atrium next door a warning rather than a demonstration.

##### The outside is the engine

Hilbert wanted arithmetic proved complete and consistent from inside itself. Gödel showed that a system strong enough to be interesting can have one or the other and not both, and the interesting part is the qualifier: the incompleteness is a consequence of *strength*. A system too weak to describe itself can be complete. The price of being able to talk about yourself is a sentence you cannot reach.

Set that beside the logistic map. Below the cascade, order and no structure. Above it, structure that never repeats. Nothing rich happens in the settled regime. And set it beside the third term of the formula, added rather than subtracted: `φΔE(S,t)`, the rate at which a system's disorder changes, weighted by how much it welcomes changing.

The seven rooms behind you are not seven failures. They are seven places where a system met its own edge and something began there — non-Euclidean geometry from a postulate that would not close, type theory and modern set theory from a definition that ate itself, computability from a sentence that could not be proved. Each crisis produced the field that came after it.

The crisis was never the problem. The crisis is the engine.

## QFEP Laboratory: The Formula Made Interactive

### 175. QFEP Introduction

[Live text](http://localhost:3003/compose?map=QFEP_Introduction)

#### Four controls, one result

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

### 176. QFEP F Term

[Live text](http://localhost:3003/compose?map=QFEP_F_Term)

#### Predictable according to what model?

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

### 177. QFEP E Term

[Live text](http://localhost:3003/compose?map=QFEP_E_Term)

#### Counting what could happen

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

### 178. QFEP Lambda Spectrum

[Live text](http://localhost:3003/compose?map=QFEP_Lambda_Spectrum)

#### The path the hall recommends

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

### 179. QFEP Phi Term

[Live text](http://localhost:3003/compose?map=QFEP_Phi_Term)

#### Giving change a sign

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

### 180. QFEP Edge Of Chaos

[Live text](http://localhost:3003/compose?map=QFEP_Edge_Of_Chaos)

#### A pattern and the way we drive it

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

### 181. QFEP Sandbox

[Live text](http://localhost:3003/compose?map=QFEP_Sandbox)

#### Where the control reaches

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

### 182. QFEP Synthesis

[Live text](http://localhost:3003/compose?map=QFEP_Synthesis)

#### What should this body keep?

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

## Post-Crisis: Applied Limits

### 183. CriticalAlgorithms Algorithmic Bias Visualization

[Live text](http://localhost:3003/compose?map=CriticalAlgorithms_Algorithmic_Bias_Visualization)

#### Less room for a distinction

Which differences become difficult to recognise when a representation gives some words less room?

<!-- @bias_from_inside -->

Choose two warm-coloured labels and keep both in view while moving PERSPECTIVE. Compare their changing separation with two grey labels. Stop partway through the movement and notice which words are still easy to distinguish individually.

The warm group compresses into a smaller region while the grey group spreads and moves away. The words themselves remain, but the space available to tell them apart changes. Presence in a representation is therefore different from being represented with useful distinctions.

Keep one chosen pair as your reference while the rest of the display changes. You do not need to remember every word to notice that two labels have become harder to distinguish. Then choose a pair within the other colour and repeat the observation. The contrast concerns available distinctions within each group, not merely distance between the groups. That is why separating two coloured clouds would not by itself repair every compression the piece asks you to consider.

An embedding places items in a numerical space so that relations between positions can be used in later calculations. This exhibit stages an authored analogy for that operation. Its positions interpolate between two designed arrangements; they are not measured coordinates from a trained language model. The slider changes the geometry rather than retraining a model or changing only your camera.

That limitation helps keep the question exact. The piece can show what spatial compression does to your ability to separate its labels. It cannot, by itself, establish the distances those same words occupy in an actual system. An empirical claim would need a named model, a documented measurement and a comparison that someone else could check.

Now scrutinise the groups chosen for the sculpture. Words such as “queer”, “disabled” and “refugee” do not name interchangeable experiences. Nor are “normal”, “professional” and “objective” equivalent claims. The exhibit risks repeating a flattening if its two colours become a sufficient account of everyone they contain.

Choose one distinction within a colour that you want the representation to retain. For a future version, compare several groupings and ask the people represented which distinctions matter to them. Greater distance alone will not guarantee a better account, but it can make an otherwise hidden question available.

<!-- @ -->

The applied-ethics room moves from word positions to furniture. A plan can distribute the ability to participate before anyone begins speaking.

### 184. CriticalAlgorithms Applied Ethics

[Live text](http://localhost:3003/compose?map=CriticalAlgorithms_Applied_Ethics)

#### Before the first person speaks

Who does this room make easiest to address?

<!-- @room_shape_demonstrator -->

Walk around the two miniature rooms. In the long-table plan, locate the head chair and compare its size with the other chairs. In the circular plan, choose one seat and imagine speaking from it. Trace the distances to the other positions rather than simply choosing the greener model.

The long table gives one position a conspicuous role. Its six smaller accompanying chairs carry less visual weight. The other model places six equal chairs around a round table. The comparison changes more than an outline on the floor: it changes relative size, position and the implied relation between participants.

Count the places as well as comparing the table shapes. The long-table model includes a head position in addition to its smaller side chairs, while the circular model has six equal chairs. The exhibit therefore does not hold every variable fixed. If you attribute a difference only to circular geometry, you may overlook the number and relative scale of participants it displays. Naming those simultaneous changes is the beginning of designing a more controlled comparison.

These are affordances and invitations. A head position can make it easy to identify a speaker; a circle can support addressing several neighbours around a shared centre. Neither miniature contains actual speech, listening or an agreement about whose turn comes next. The geometry proposes conditions under which those activities might happen.

Notice how the exhibit colours its own argument. Red singles out authority; green recommends the distributed arrangement. That visual judgement arrives before you have tested whether the plan meets a particular group’s needs. Looking critically at a model includes looking at the persuasion built into its presentation.

Find one use for the head position that you would preserve, then one difficulty the circle would not automatically solve. A designated interpreter, a speaker who needs a clear sightline or someone who cannot easily turn towards every other participant can complicate the familiar good-circle story. These possibilities call for observation with people, not a verdict from chair shapes alone.

A future version could compare actual sightlines and turn-taking across the two plans. The ethical question would become a design question with observable consequences: which participant gained access, which difficulty remained, and what change should follow?

<!-- @ -->

The next room lets two requirements meet without immediately deleting one. Participation can be shared while the resulting claims still conflict.

### 185. SpeculativeComputation Paraconsistent Engineering

[Live text](http://localhost:3003/compose?map=SpeculativeComputation_Paraconsistent_Engineering)

#### Keeping the disagreement visible

Must one account disappear before two accounts can share a system?

<!-- @merge_conflict_visualizer -->

Trace branch A and branch B towards the lit junction. Inspect what remains visible on either side of that meeting point. Before deciding which branch should win, give each one a source and a reason to have arrived there.

The sculpture keeps two versions present around a conflict marker. It does not merge actual files or execute rules of logical inference. Its useful first gesture is spatial: an unresolved relation can be represented without erasing the parts that made the relation difficult.

Try a concrete disagreement. One report says a door is open; another says it is closed. Adding times may reconcile the reports. Adding the door’s identity may reveal that they concern different doors. Preserving provenance gives us ways to investigate before treating every difference as a contradiction about the same thing at the same time.

Keep three possible responses apart while inspecting the junction: investigate the source, choose one version for a particular use, or retain the conflict within a reasoning system. They do different work. A practical decision about which report to act on does not erase the other report’s existence, and preserving both reports does not automatically endorse both contents. The two visible branches give you a place to hold those distinctions before any resolution changes what the shared display contains.

Formal paraconsistency concerns the inference rules themselves. In a paraconsistent logic, a contradiction need not license an arbitrary conclusion. It does not mean accepting every claim or abandoning the distinction between supported and unsupported inference. [Basu and Roy’s research paper starts from this failure of explosion when developing more general definitions.](https://arxiv.org/abs/2112.00357)

The current junction is an analogy for retaining a conflict, not a demonstration of that formal property. The next useful addition would expose a small rule table: after entering both a proposition and its negation, which consequences remain available, and which unrelated conclusion still cannot be derived?

Return to the pillars and imagine a resolution that shortens one to a stump. What information should remain so the decision can later be reconsidered? Keeping a source, a date and the rejected alternative does not make revision automatic, but it prevents a settled display from hiding how settlement occurred.

<!-- @ -->

Situated computation takes up that provenance. Four panels will judge one subject differently, and their positions will become part of what the judgement tells you.

### 186. SpeculativeComputation Situated Computation

[Live text](http://localhost:3003/compose?map=SpeculativeComputation_Situated_Computation)

#### Four verdicts about the same subject

What changes when the subject stays the same but the source of the judgement changes?

<!-- @situated_readout -->

Read the subject identifier on all four panels. Keep it fixed in your comparison, then note the verdict, the confidence and the footer on each. Look back at the first panel after reading the others: it has not become a different subject because another description is available.

SUBJECT #4729 appears as ORDERLY, CREATIVE, DANGEROUS or IRRELEVANT across the four positions. The associated percentages differ too. The room makes a judgement’s location visible instead of presenting one description as if it came from nowhere.

Write a mental four-part description of one panel: identifier, verdict, confidence and viewpoint. Then exchange only the panel in that description. Some fields remain constant while others change, which gives you a simple comparison without inventing hidden changes in the subject. The footer is part of the evidence for where the claim is presented. Keeping it with the verdict helps prevent a memorable word such as DANGEROUS from travelling through the discussion as if it had no source.

These are four authored readouts. Each panel retains the verdict assigned to it; your movement changes which panel you read. The percentages are supplied examples, not calibrated probabilities calculated from evidence about a real person. A high number in this room therefore cannot establish that its description is more trustworthy than a lower number.

Separate four parts of a claim: the subject, what is asserted, how certain the speaker appears, and the conditions under which the assertion was produced. Keeping the subject constant helps expose changes in the other parts. It does not imply that all four predicates have the same meaning or answer the same question.

Choose DANGEROUS and ask what evidence would make that judgement accountable. Dangerous to whom, under which circumstances, and according to what consequence? Then apply an equally precise question to CREATIVE. A favourable word also needs criteria; situatedness is not a licence to stop checking an appealing claim.

For the room’s next experiment, each panel could reveal a distinct criterion and the observation it used. A visitor could then compare disagreement caused by different evidence with disagreement caused by different definitions. The current four views supply the scaffold for that comparison.

<!-- @ -->

Collective knowledge asks how contributions from different positions can become a common object without losing the evidence and disagreement that make it revisable.

### 187. SpeculativeComputation Collective Knowledge

[Live text](http://localhost:3003/compose?map=SpeculativeComputation_Collective_Knowledge)

#### More contributions than contributors

When many marks accumulate, what makes the result knowledge rather than a pile?

<!-- @peer_production_tool -->

Follow a packet from one of the rim nodes into the central structure. Watch the new facet appear. During one growth cycle, compare a contribution from a node you have already seen with one from a new source. The number of contributions and the number of contributing sources need not increase together.

The exhibit turns contribution into an arrival event. A packet comes from one of twelve positions and adds a piece to a shared form. The form grows to a fixed capacity and starts again. Its visible coherence comes from an assembly rule that knows where to place each arriving facet.

Look for a repeated source during a single growing form. Its next arrival can add another facet without adding another distinct position around the rim. That gives you a concrete distinction between activity and breadth of participation. The central object does not reveal that distinction merely by becoming larger. You need to look back at the sources and the sequence of arrivals, preserving information that the finished shape alone does not make equally easy to recover.

That is a simulation of accretion, not a live collaborative editor. The peers are generated positions rather than people logged into the museum, and the incoming material is accepted without a dispute over its content. The animation demonstrates one way many sources can feed one object while leaving the harder question of validation open.

Collective knowledge needs more than participation counts. A contribution may repeat an error, correct an earlier claim, supply a missing case or disagree with an accepted account. Those actions can add little to a simple count while changing the usefulness of the shared result dramatically.

The previous room kept four viewpoints separate. Here the common centre can make their differences disappear into a continuous object. Follow a facet and ask what you can still recover about its origin after it joins the whole. Does the shape preserve a reason for accepting that contribution, or only the fact that something arrived?

For a proposed extension, mark one contribution as disputed and keep its source visible. Let revision change an existing piece instead of always adding another. The comparison would show how maintaining knowledge differs from celebrating uninterrupted growth.

<!-- @ -->

The rhizome will make the pattern of connection itself grow. A shared result can have many contributors while its network still develops uneven centres.

### 188. SpeculativeComputation Rhizome Network

[Live text](http://localhost:3003/compose?map=SpeculativeComputation_Rhizome_Network)

#### Growing without a named root

Can local connections build a network without first choosing its centre?

<!-- @rhizome_grower -->

Watch for a new node and follow the segments it adds. Compare a crowded part of the structure with a sparse part. Predict which existing nodes are likely to receive the next connections, then check the new shoot against your prediction.

The exhibit starts with two nodes. A new shoot is placed within a bounded region and linked to up to three of the nearest existing nodes. Repeating this rule builds a graph from local proximity. The node and edge counts record its growth until the forty-node capacity is reached and the display starts again.

Compare the moment just before a shoot arrives with the moment just after. The new node chooses from nodes already present; those existing nodes do not acquire new positions merely because they have been chosen. This separates growth of the connection structure from movement of the whole display. It also exposes a small asymmetry in time: an existing node can receive a new relationship from a later arrival, while the newcomer cannot choose a future node that does not yet exist.

No vertex is assigned a root role. There is no stored family tree telling every later node to descend from one privileged ancestor. Multiple connections permit the growing structure to contain routes that differ from a simple parent-and-child hierarchy.

The rule still has consequences worth inspecting. Earlier nodes are available to be chosen for longer, and spatially well-placed nodes can attract many nearby additions. A network without a designated root can develop busy regions and uneven degrees. “No root” describes part of the construction; it does not prove that every participant has equal influence.

Find a node with several visible links. Imagine removing it and predict whether the remaining pieces would still connect. Graph theory gave us the tools to ask this precisely. The present exhibit does not offer deletion, so treat the prediction as a proposed test rather than evidence that every rhizome repairs itself.

The peer-production tool gathered contributions at one centre. This growth rule distributes connections through space, but geometry still acts as a gatekeeper: being nearby makes a relationship available. A future variant could let a new node choose a distant connection and compare the network’s routes and dependencies afterwards.

<!-- @ -->

The assembly laboratory adds a catalogue and a target arrangement. When connections must form a recognisable body, we can ask which bodies the catalogue has already imagined.

### 189. AdvancedLaboratory Lab Equipment Simulation

[Live text](http://localhost:3003/compose?map=AdvancedLaboratory_Lab_Equipment_Simulation)

#### The inventory before the body

How can one collection of parts become several recognisable structures?

<!-- @MolecularDesigner -->

Choose a recognisable piece in the floating inventory and keep it in view as an assembly begins. Watch it approach a position and acquire relations to other pieces. Stay through another floating phase and a later assembly. Compare the part’s changing role with the properties it retains.

The scene alternates floating and assembling phases, with about ten seconds assigned to each. It moves through authored assemblies drawn from a catalogue that includes bodies, furniture and other structures. Bond lines update between the assigned parts as they move towards their targets.

During assembly, compare a part’s route with its final relation to its neighbours. The route can curve or settle gradually because motion is being calculated over time, while the target arrangement already specifies where the part is meant to finish. A convincing settling motion is therefore not evidence that the arrangement was discovered by trial and error. Watching both the approach and the endpoint helps you separate a procedure for moving parts from a procedure for inventing a structure.

There are two distinct descriptions at work. The catalogue defines available kinds of part: shapes, sizes, colours and related properties. An assembly chooses instances, assigns target positions and orientations, and declares connections. Movement towards those targets is then produced by a damped spring calculation. A recognisable whole results from a specification together with a procedure for approaching it.

This is not a simulation establishing chemical bonds or discovering molecular structures from physical laws. A line between two pieces represents a declared relation. A structure named Molecule or DNAHelix belongs to the exhibit’s authored vocabulary, and the name cannot supply the chemistry that its movement does not calculate.

The rhizome selected neighbours by proximity. Here the assembly already describes where things should end up. Neither method is unrestricted: one inherits a spatial growth rule, the other a catalogue and a target. Understanding those constraints lets us ask for a meaningful variation.

Imagine a body this catalogue makes awkward to describe. Would you need a new kind of part, another connection, or merely different positions for existing pieces? That is a proposed design exercise for a future editable version. The present automatic cycle lets you begin by observing how much changes while the inventory remains available.

<!-- @ -->

The final ledger asks us to record the consequences of those choices. A useful catalogue permits construction while also defining what its builder has to struggle to express.

### 190. PostCrisis Synthesis

[Live text](http://localhost:3003/compose?map=PostCrisis_Synthesis)

#### One choice you can answer for

Can you name one person a useful design choice could leave out?

<!-- @accountability_ledger -->

Read one complete pair on the ledger before it scrolls away. Choose a concrete case, such as a short name field and someone whose name exceeds it. Say what the designer probably gained, what the person encounters, and one change that could reduce the difficulty.

The exhibit cycles through prewritten examples of choices and exclusions. Six lines remain visible at once, and an amber mark accompanies a new entry. Its form resembles an accumulating record, but these entries are examples: it is not recording your visit, saving your discussion or certifying that any problem has been repaired.

Stay with your chosen example after the next line arrives. The display’s attention has moved on, but the consequence you identified has not been resolved by that movement. Compare an entry being added with a change actually being made: they are different events and require different evidence. The scrolling format makes it easy to feel that work is progressing. A useful record would keep the unresolved question available until someone could check what happened to the person encountering it.

An accountable record would connect a decision with evidence about its effect and someone able to revisit it. Naming an excluded case is a beginning. It becomes useful when it leads to an action, an observation after the action, and a decision about what to change next.

Return mentally to one room you have just walked. Perhaps a slider was difficult to reach, a number concealed several different conditions, or a label promised a computation the exhibit could not yet perform. Choose one case small enough to inspect. State the intended experience, the present obstacle and the smallest improvement that would let you test the difference.

Now ask where else the same relation occurs. A readable control, a preserved alternative or a visible source can be a reusable principle. Reusing it still requires checking the new room: the same height may not suit every body, and the same explanatory sequence may not suit every concept. Generalisation is a claim to test through another encounter.

The ledger does not absolve a choice by displaying its cost. Some exclusions call for repair, some for another route, and some for changing the category that made the case disappear. The response should stay attached to the person’s actual difficulty rather than becoming a decorative admission of imperfection.

<!-- @ -->

Go back to a chosen room with one question, one proposed change and one observable consequence. The museum’s next version begins with that specific return.
