# Ada — the tutorial manuscript

Current tutorial.md files, 4 October 2026. Read-only compilation in live museum order. Missing files and teaching intents are retained as gaps. Critical final.md chapters and preparation documents are separate.

---

## 01. Primitives: Points Build Worlds

### Point_Zero

Source: `commons/maps/Point_Zero/tutorial.md`

# Point Zero — Already running

This tutorial follows a path through **Endless Museum**. You will walk its halls, encounter works, and learn to build and change selected parts of what you find. Each lesson adds something you can carry into work of your own.

The tutorial track follows particular artifacts and operations. Alongside it, reflective texts explore questions raised by the works: what a form makes possible, what its rules assume, and how we experience it. You can read these texts beside the lessons. Some artifacts take part in both tracks; others belong to only one.

You will also encounter artifacts that appear in neither track. They are part of the field we explore: neighbours, comparisons, experiments and possibilities we have not yet followed. You can stop with them without needing a lesson to tell you what they are for.

The museum is larger than the route we take through it. We begin by choosing where to pay attention.

## The counter is already here

You arrive in front of a number that is already increasing. The museum was processing frames before you could see it. We will use this counter to follow what happens once and what repeats.

Work in your existing Ada project, in Endless Museum's **Point Zero** hall. Open `commons/visualaid/frame_counter/frame_counter_display.gd`. The script already creates the console and its text in code. We will borrow that construction and change how the number is updated.

## Ready

Find this function:

```gdscript
func _ready() -> void:
    _build()
    _arrival_frame = int(Engine.get_process_frames())
    _built = true
    _refresh_caption()
```

`func` defines a function: a named block of instructions. The colon begins its indented body. `-> void` says this function returns no value. Godot calls `_ready()` when this node and its children are ready in the scene.

`_build()` is a supplied function in the same script. It creates the console, including a `Label3D` for the number, and keeps a reference to that label in `label`. The remaining lines record the panel's starting frame and prepare its caption. Leave them in place. Making the housing is work we can return to; here we are following when instructions run.

## Every frame

Find `func _process(delta: float) -> void:` further down the file. Replace that function, including its indented body, with these two lines. Keep the next function, `_count()`, and everything below it.

```gdscript
func _process(_delta: float) -> void:
    label.text = str(Engine.get_process_frames())
```

Save and restart the museum. The existing counter keeps increasing. You have reduced its update to the operation we are studying.

Godot calls `_process()` on each process frame. `Engine.get_process_frames()` reads the engine's total since startup. `str()` turns that number into text; `label.text =` assigns it to the display. Each call reads a new total and replaces the previous text.

Godot also passes the time interval for the frame as `_delta`, measured in seconds. `float` means a number that can have a fractional part. The leading underscore marks an input we do not use here. We are displaying a frame count, not elapsed seconds.

## Read it once

Move the assignment into the end of `_ready()`. Remove the two-line `_process()` function you just added. Your `_ready()` now reads:

```gdscript
func _ready() -> void:
    _build()
    _arrival_frame = int(Engine.get_process_frames())
    _built = true
    _refresh_caption()
    label.text = str(Engine.get_process_frames())
```

Save and restart. The counter shows a number and holds it. Walk around: the museum still runs. You have stopped this display from receiving new readings, not stopped the engine.

The number need not be zero. `_ready()` marks this node's readiness; the engine has already processed frames getting here.

Put the assignment back into `_process()` and remove it from `_ready()`. Restart: the display follows the running total again. The instruction is the same. Its place determines whether it runs once or repeatedly.

These are edits to the existing artifact's shared script in your working copy. When you finish experimenting, restore the original functions to keep its other readout modes available.

In Point One, we will use `_ready()` again, this time to give a point a position.

### Point_One

Source: `commons/maps/Point_One/tutorial.md`

# Point One — give the point a body

Three labels say “Point one”. Above the first, nothing. Above the next two, a white sphere. Walk towards each. Only the last stops your movement.

Point Zero followed when an instruction runs. Here we follow what has to be made for a point to appear and resist us.

In your working Ada project, open `commons/primitives/point/point_condition.gd`. This is the script already used by the corridor’s points. Work in the museum’s **Point One** hall. The excerpts below identify parts of this file; make only the specified edits. After each edit, save and restart the scene.

## A position before a surface

Near the top of the script:

```gdscript
const CENTRE := Vector3(0, 1.12, 0)
```

`Vector3` holds three numbers. Here they locate a position relative to each station. The middle number places it 1.12 metres above that station’s origin. The next hall will examine the three directions and their reference frame.

`CENTRE` names this value. `const` makes it a constant: the script cannot reassign it while running. You can edit its starting value and run again. `:=` lets Godot infer its type from that value: here, `Vector3`.

Change `1.12` to `1.7`. The small white spheres rise. The first station remains empty: its code finishes after creating the label. A position does not draw a surface by itself. Restore `1.12`.

The large sphere on the final pedestal stays where it is. The same script gives that condition a separate centre and radius. We will leave its arrangement in place.

## A surface at that position

Further down, the script creates the visible sphere:

```gdscript
var sphere := SphereMesh.new()
sphere.radius = radius
sphere.height = radius * 2.0
```

`var` declares a variable. `sphere` keeps a reference to the object made by `.new()`. `SphereMesh` is a resource: it holds the surface data that a scene node can display.

The station setup has already chosen a value for `radius` and a position called `centre`. For the small spheres these come from `RADIUS` and `CENTRE` near the top of the file. A radius measures from centre to surface; `* 2.0` makes the sphere’s full height twice that distance.

Look around these assignments in `_ready()`:

```gdscript
var body := MeshInstance3D.new()
```

```gdscript
body.mesh = sphere
```

```gdscript
body.position = centre
add_child(body)
```

`MeshInstance3D` displays the mesh. The dot selects a property of that node: its mesh, then its position. `add_child(body)` adds the new node beneath this station in the scene tree. The script creates both resource and node; it does not fetch a hidden sphere from a scene file.

Change `const RADIUS := 0.14` to `const RADIUS := 0.3`. Both small spheres grow around their unchanged centres. Walk towards the first white sphere. You can still cross its surface. Restore `0.14`.

## A boundary made separately

Find the part that creates `PointCollision`. It runs for the solid and pedestal conditions. These are its construction lines, with the naming and collision-layer setting left out:

```gdscript
var solid := StaticBody3D.new()
solid.position = centre
var collider := CollisionShape3D.new()
var sphere_shape := SphereShape3D.new()
sphere_shape.radius = radius
collider.shape = sphere_shape
solid.add_child(collider)
add_child(solid)
```

`StaticBody3D` is a fixed physics body. `SphereShape3D` describes its boundary; `CollisionShape3D` attaches that shape to the body. These lines draw nothing. The visible surface was made above them.

Both constructions use `centre` and `radius`, so their positions and sizes agree.

Change only `sphere_shape.radius = radius` to `sphere_shape.radius = radius * 2.0`. The small solid sphere looks unchanged, but your movement stops farther away. Its invisible radius has doubled. Your player has a width too, so the stopping distance depends on both bodies. The pedestal sphere’s boundary doubles too: this part of the shared script serves both.

Restore the line. Now change `RADIUS` to `0.3` again. The small solid sphere’s surface and boundary grow together because both use that value. Restore `0.14` when finished.

## The light remains another condition

Use the wall switch. The long shadows disappear; the solid sphere still stops your movement. The light is another existing artifact, and its code can wait. We have enough here to distinguish a position, a visible surface and a physical boundary.

In Point Coordinates, the point can move with your hand. We will follow the position as it changes.

### Point_Coordinates

Source: `commons/maps/Point_Coordinates/tutorial.md`

# Point Coordinates — carry a position

Take the black sphere at the entrance. Its label stays behind. The point now follows your hand.

Point One separated a position, a surface and a physical boundary. Here the body can be held, and two cards report where it is. We will change its starting position and examine how the same place receives different numbers.

Work in the existing **Point Coordinates** hall. The point, frame and cards are already there. The code below identifies parts of their scripts; make only the specified edits in your working copy. Save and restart the museum after each edit.

## A body that can follow

The black point uses the supplied `XRToolsPickable` component. It connects the body to the prepared player's grab and release. Try taking it, moving it and letting go. We borrow that interaction here; building the player or its input system would be another lesson.

Open `commons/primitives/point/point_condition.gd`, the same script we read in Point One. Inside the `held` condition, find:

```gdscript
held.position = CENTRE
```

`held` refers to the pickable body created just above this line. `CENTRE` is still `Vector3(0, 1.12, 0)`. The three components are X, Y and Z; here they place the body relative to its station.

Replace only this assignment with:

```gdscript
held.position = CENTRE + Vector3(0, 0.5, 0)
```

Adding two vectors adds their corresponding components. X and Z stay unchanged; Y becomes `1.62`. The same black point starts half a metre higher. Its surface and collider move together because both belong to the held body. The station's label stays put.

Restore `held.position = CENTRE`. We changed where this body begins, without changing the shared constant or the earlier white points.

## Give the movement three directions

Carry the point towards the frame in the L-shaped basin. Move along one arm, then another. Pink marks X, grey marks Y, black marks Z. The black arm is labelled **−Z**: moving along it away from the origin decreases the local Z value.

Watch the LOCAL card. Lifting the point changes Y; moving sideways changes X or Z. Your hand will rarely change only one component. The frame gives those movements directions we can distinguish.

The two cards follow this same point. WORLD reports its position in the museum's world coordinates. LOCAL reports it relative to the coloured frame.

## The same place, another address

Open `algorithms/vectors/00_coordinates/CoordinateSystem3M.gd`. Within `_process()`, the script reads the point in two ways. These lines already exist at separate places in that function:

```gdscript
var world_p: Vector3 = pt.global_position
```

```gdscript
var lp: Vector3 = to_local(pt.global_position)
```

`pt` is the reference to the held point, found by the supplied reporting connection. `: Vector3` states the variable's type explicitly. `world_p` keeps its world position. `to_local(...)` expresses that position relative to the node running this script: the coloured frame. `lp` keeps the result.

The conversion includes the frame's position, orientation and scale. This frame is scaled by `1.5`, so one local unit spans 1.5 metres in the hall. Its LOCAL numbers are not simply WORLD numbers with another starting zero.

The earlier `held.position` belongs to the held body's parent. That parent and this coloured frame are different nodes. Whenever we say “local”, we need to say local to what.

Point Zero introduced `_process()`. Here it repeatedly reads a position that the pickup system changes. We can follow the movement without writing the hold again.

## How much can the card say?

Open `commons/primitives/point/coordinate_readout.gd`. In `show_coordinates()`, find:

```gdscript
t = "x = %.2f\ny = %.2f\nz = %.2f" % [p.x, p.y, p.z]
```

`p` is the position received by this card. `p.x`, `p.y` and `p.z` select its components. Each `%.2f` prints one number with two decimal places; `\n` starts another line. The formatting fills the three places in order.

Change the three occurrences of `%.2f` on this line to `%.3f`. Both cards now show another decimal place. A movement too small to alter the old display can become visible in the numbers.

The edit changes the report, not the position or the accuracy of your tracked hand. Restore `%.2f` when finished.

We can now place a body, carry it and name the reference for its address. Point Lines will relate two positions: how far apart they are, and what can join them.

### Point_Lines

Source: `commons/maps/Point_Lines/tutorial.md`

# Point Lines — keep two ends in relation

Take one endpoint. The other stays where it is. Between them, a pale segment turns and changes length. Two readings follow: a displacement and its length.

Point One gave a position a body. Point Coordinates adds a working hold and a frame in which to read its position. Here we use two positions in that same frame. The prepared handles supply the hold; the new work is the relation between them.

Open `point_lines.tscn` in the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md). Use **Run Current Scene** (F6). Open `studies/point_lines/line.gd`. On desktop, approach a point, aim at it and press E to hold it. Move, then press E to release. It stays where you leave it. The XR route uses the supplied near-grip interaction.

## 1. Keep two positions

Inside `_ready()`, the script places two handles:

```gdscript
    a.position = Vector3(-0.75, 1.12, 0.0)
    b.position = Vector3(0.75, 1.12, 0.0)
```

`a` and `b` are references to the handles. Each `.position` is a `Vector3`. Both handles belong to `Study`, so their positions use the same reference frame. Keep Study's scale at one. In this room, one unit represents one metre.

The middle and last numbers agree. The first numbers place the handles 1.5 metres apart.

## 2. Subtract, then measure

Inside `_process()`, we read the relation again:

```gdscript
    var displacement := b.position - a.position
    var distance := displacement.length()
```

Subtract the start from the end. `displacement` is the change needed to get from A to B: initially `(1.5, 0.0, 0.0)`. It has a direction and a length.

`.length()` measures that vector and returns one number: `1.5`. The displacement is a `Vector3`; the distance is a `float`. A distance alone does not say which way to go.

Change B's first number from `0.75` to `0.25` in `_ready()`. Run again. The segment is now one metre long. You changed one endpoint; the relation supplied the new length. Restore `0.75`.

## 3. Turn without lengthening

Replace B's starting position with `Vector3(-0.75, 2.62, 0.0)`.

The segment stands upright. Its length is still 1.5 metres. The displacement is now `(0.0, 1.5, 0.0)`. A different direction can have the same length.

Restore B's original position. Change the subtraction to `a.position - b.position`. The displacement reverses. The distance stays the same, and the segment still joins the same two ends. Restore `b.position - a.position`.

## 4. Read it while it changes

This is the whole repeated part of `line.gd`:

```gdscript
func _process(_delta):
    var displacement := b.position - a.position
    var distance := displacement.length()
    segment.show_between(a.position, b.position)
    displacement_readout.text = str(displacement)
    distance_readout.text = "%.2f m" % distance
```

We reuse Point Zero's `_process()`. Each frame reads the current positions, draws between them and updates the text. `str()` makes text from a value. In the last line, `%` puts the distance into the `%.2f` slot: a number shown with two decimal places, followed by “m”. This rounds the display, not the stored positions. A small movement can leave the displayed number unchanged.

`show_between()` is a function in our supplied `Segment` script. We pass it the two positions. It places a thin cylinder between them and adjusts its length and orientation. The cylinder has a thickness chosen so we can see it. Its drawing code is included, but turning a mesh is not today's new operation.

Take one endpoint and move it. The handle supplies a new position; the relation responds. Release it. The script keeps reading even when nothing moves.

## What we borrowed

At the top of the file, `preload()` loads the two supplied scripts. `const` gives each a fixed name:

```gdscript
const PointHandle = preload("res://prepared/point_handle.gd")
const Segment = preload("res://prepared/segment.gd")
```

`PointHandle.new()` creates a point with the supplied pickup behaviour. `Segment.new()` creates the cylinder. The lesson also creates its two `Label3D` readouts. Each node is added in `_ready()`; no teaching mesh or display is fetched from a scene file.

These are named dependencies. We can inspect or replace them while keeping the calculation between two positions.

## Two ends cannot keep a journey

Give B the same starting position as A. The distance becomes zero. The renderer hides a segment too short to draw; at coincidence there is no direction from one end to the other. Separate them again and it reappears.

Carry an endpoint around a detour, then return it to the same place. The calculation returns to the same result. It has kept no route.

The museum's walking line makes that absence visible beside a recorded trail. In Trace, we will keep the positions in between.

### Point_Trace

Source: `commons/maps/Point_Trace/tutorial.md`

# Point Trace — keep the way through

Move the point in a loop. Let go. The point stops, but the loop remains: a line through positions the point has left behind.

In Point Lines, two positions were enough to draw a segment. Each frame replaced the previous reading. Here we keep readings in order, so the route can outlast the movement.

Open `point_trace.tscn` in the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md). The lesson script is `studies/point_trace/trace.gd`. Hold the point as you did in Lines. This study makes one continuous record; releasing holds the point still, and taking it again continues that record. Restart the scene for a fresh drawing. Releasing also saves a copy for Point Grid; look for **Saved for Point Grid**. The supplied `TraceMemory` carries the list between scenes and separate runs.

## 1. Give positions somewhere to stay

```gdscript
var points: Array[Vector3] = []
var spacing := 0.08
var capacity := 128
```

`points` is an **Array**: an ordered list. `Array[Vector3]` says what it can hold. Each entry is one position, with three coordinates. The list itself has one index: first entry, second entry, third entry. It is a one-dimensional list of three-dimensional positions.

`[]` starts it empty. Inside `_ready()`, after placing the point, we keep its first position:

```gdscript
    points.append(point.position)
```

`append()` adds a value at the end. It stores the position at that moment. Moving the point later does not move that saved position.

## 2. Decide when to keep another

These lines run inside `_process()`:

```gdscript
    var displacement := point.position - points[-1]
    if displacement.length() >= spacing:
        points.append(point.position)
```

`points[-1]` reads the last entry. We reuse Lines' subtraction and length to measure from that saved position to the point now.

`if` introduces a condition. `>=` means “greater than or equal to”. The indented line runs only when the distance reaches `spacing`: here, 0.08 metres, or eight centimetres. Smaller movements accumulate as a separation from the last saved position; they do not each become entries.

Move slowly, then stop. The count stops increasing. Point Zero's frames still pass, but this list records positions rather than elapsed time. A long pause leaves no extra entry to show how long you waited.

## 3. Join neighbours in the list

After adding a position, the script redraws the retained route:

```gdscript
        drawing.clear()
        for i in range(1, points.size()):
            drawing.join(points[i - 1], points[i])
```

`size()` gives the number of entries. Their indexes start at zero. With four positions, the indexes are `0, 1, 2, 3`.

The **for loop** repeats its indented line. `range(1, points.size())` supplies indexes from 1 up to, but excluding, the size. With four entries, `i` becomes 1, then 2, then 3. The pairs are therefore `0–1`, `1–2`, `2–3`: three segments through four positions.

This loop finishes a traversal of the saved list. `_process()` returns each frame to inspect movement. One repeats through entries; the other repeats over time.

`TraceDrawing` is the supplied display. `clear()` clears the drawing; it leaves `points` alone. Each `join(a, b)` reuses Lines' segment renderer and marks its endpoints with small pink dots. Drawing thickness and mesh construction stay in that helper. The loop deciding which positions to join is yours.

## 4. Change what the route can retain

Change `spacing` to `0.25`. Run again and make a similar loop. Fewer positions are kept; the straight connections cut across more of the curve. Restore `0.08` and compare.

Spacing is a minimum separation, not a guarantee that every eight centimetres is recorded. We inspect once per frame. A fast move can leave a larger gap, and the drawing joins its ends without knowing what happened between them.

The record also has a limit:

```gdscript
        if points.size() > capacity:
            points.pop_front()
```

`pop_front()` removes the oldest entry. The remaining entries keep their order. Change `capacity` to `32` and continue drawing. Once the count reaches 32, a new position replaces the oldest; the far end of the route begins to disappear. Waiting alone removes nothing. Restore `128` when you want a longer record.

The museum's pens combine a movement threshold with a grid that shapes each saved position. This smaller study follows the handle's centre without snapping it to a grid. All positions use Study's reference frame. Release your drawing before leaving. Grid will reuse this saved list, keeping the original beside a version given grid addresses. You will change the rule without having to make the gesture again.

### Point_Line_Grid

Source: `commons/maps/Point_Line_Grid/tutorial.md`

# Point Grid — your trace returns

Find the bend you made in Trace. It is here again. Beside it, the same record has been placed on a grid. Change the spacing and compare what happens to that bend.

## 1. Bring the drawing with you

In the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md), open `point_trace.tscn`. Hold the point, draw, then release it. On desktop, mouse movement directs the held point; in VR, your tracked hand moves it. Wait for **Saved for Point Grid**.

Stop the scene and run `point_grid.tscn`. It loads that saved trace. If no usable trace has been saved, it asks you to return and draw one. It does not substitute a demonstration for your gesture.

The supplied `TraceMemory` keeps the latest released record on this device. It carries positions between the two lessons, including across separate runs. Opening Grid does not change the saved record. Returning to Trace, drawing and releasing saves a new one.

## 2. Keep the source and the result separate

Open `studies/point_grid/grid.gd`. We have two lists:

```gdscript
var source_points: Array[Vector3] = []
var grid_points: Array[Vector3] = []
var grid_size := 0.25
```

Both hold positions in metres. `source_points` receives the saved trace:

```gdscript
    source_points = TraceMemory.read_trace()
```

`grid_points` begins empty. We will fill it with new values, leaving the source alone. A quarter of a metre is our chosen grid spacing. All calculations use the Study frame in which Trace recorded the points.

## 3. Give each saved position an address

Trace's drawing loop visited neighbouring entries by index. This loop takes each stored value in turn:

```gdscript
    for p in source_points:
        var address := Vector3i(
            roundi(p.x / grid_size),
            roundi(p.y / grid_size),
            roundi(p.z / grid_size)
        )
        var placed := Vector3(address) * grid_size
        grid_points.append(placed)
```

For every position `p`, divide each coordinate by the spacing to count grid intervals. `roundi()` gives the nearest integer. `Vector3i` holds these three whole-number counts: the grid address.

For example, X = `0.12` metres is `0.48` quarter-metre steps, which rounds to zero. X = `0.13` metres is `0.52` steps, which rounds to one. A small difference in the saved input can put two results a quarter of a metre apart.

`Vector3(address)` turns the integer components into floating-point components. Multiplying by `grid_size` gives metres again. `append()` adds that result to the new list. Negative coordinates use the same rule; exact halfway values round away from zero.

Each input produces one output. Nearby samples may acquire exactly the same position, but we keep their entries and their order. An array index names a sample in the record; a grid address names a place. Several samples can name that same place.

## 4. Change the reading, keep the gesture

The supplied display draws the two lists:

```gdscript
    comparison.show_traces(source_points, grid_points, grid_size)
```

Pink shows your saved trace. White shows the grid version. Both use the same centring and display scale, with a sideways offset so you can compare them. These display adjustments do not edit either list. The faint ruling is one XY section; the rounding still uses all three coordinates.

Change `grid_size` from `0.25` to `0.5` and run Grid again. You do not have to redraw. It rereads the original trace and calculates another result. Pink stays the same while the white drawing changes. Try `0.1` next. Use a positive spacing.

The display joins consecutive entries directly. Equal neighbours produce no segment; a jump can produce a diagonal. It does not invent samples between those you made. A finer grid can retain more of the saved shape, but it cannot recover movements that Trace never recorded.

We have reused a drawing as data. Its shape can now be read under another rule without losing the earlier record. In Triangle, we will choose corners and give their connections another job: closing a boundary, then making a face.

### Point_Triangle_Context

Source: `commons/maps/Point_Triangle_Context/tutorial.md`

# Triangle — three corners, then a face

Your trace has already become a grid drawing. Now choose three of its stored positions. Join them into a closed boundary. Then give that boundary a visible face.

Open `point_triangle.tscn` in the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md), using **Run Current Scene** (F6). Edit `studies/point_triangle/triangle.gd`. If the room asks for a trace, draw a bend in `point_trace.tscn` and release to save it first.

The lesson reuses Trace's original record, as Grid did. It does not read Grid's rounded display or replace your gesture with an example. `PointHandle`, `Segment` and `TraceMemory` are the supplied components we already use. The room and two appearance materials are supplied too.

## 1. Choose three positions

The script reads the saved list into `source_points`. With at least three entries, it selects these:

```gdscript
    var third := source_points.size() / 3
    a.position = source_points[0]
    b.position = source_points[third]
    c.position = source_points[third * 2]
```

Both values in the division are integers, so the result is an integer: any fractional part is discarded. With ten entries, `third` is `3`. We select entries `0`, `3` and `6`.

These are three places in the list, not three equal distances along the drawing. The rule does not recognise corners. Each selected `Vector3` becomes the position of a new grabbable handle. Moving a handle changes that copy; the saved trace stays intact.

## 2. Close the boundary

Each frame, reuse Lines' `show_between()`:

```gdscript
    ab.show_between(a.position, b.position)
    bc.show_between(b.position, c.position)
    ca.show_between(c.position, a.position)
```

The third segment returns from C to A. Hold a pink corner and move it. The two segments meeting there follow. On desktop, aim and press E; in VR, use the near grip.

Look through the centre. The boundary is closed, but we have made no face. If your selected positions lie along one line, move a corner away from it.

## 3. Add the face

Point One used `SphereMesh` to supply a surface. Here we specify its vertices ourselves. A **vertex** is a position used to construct a mesh.

```gdscript
var face_mesh := ImmediateMesh.new()
var face := MeshInstance3D.new()
```

`ImmediateMesh` is a mesh resource we can build by adding vertices. `MeshInstance3D` displays it. The script assigns `face_mesh` to `face.mesh` and adds the node to the room.

Change `show_face` from `false` to `true` and run again. These lines now execute each frame:

```gdscript
    face_mesh.clear_surfaces()
    if show_face:
        face_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
        face_mesh.surface_add_vertex(a.position)
        face_mesh.surface_add_vertex(b.position)
        face_mesh.surface_add_vertex(c.position)
        face_mesh.surface_end()
```

`clear_surfaces()` removes the previous mesh surfaces. `surface_begin()` starts a surface; `Mesh.PRIMITIVE_TRIANGLES` tells Godot to interpret each group of three vertices as a triangle. We add our three positions, then `surface_end()` finishes it.

The face and segments read the same corners. Hold one again: both follow. Setting `show_face` back to `false` leaves the boundary available without the face.

## 4. Change the view, then the shape

Leave the corners still and walk towards an edge-on view. The visible face narrows. Walk back: it returns.

Now move one corner onto the line between the other two. The triangle has zero area. Another viewpoint cannot recover it; move the corner away to open the face again.

The supplied off-white material shows both sides without lighting variation, so this comparison does not depend on a dark back or back-face culling. It adds neither thickness nor collision. The handles have colliders; the face does not.

Three non-collinear positions define one triangular face. They do not fill the whole trace we selected them from. Longer outlines need another decision about how to connect their corners.

Next, Polyhedra asks how these faces can meet to enclose a volume.

### Primitives_Polythedra

Source: `commons/maps/Primitives_Polythedra/tutorial.md`

# Polyhedra — which faces make an inside?

Three faces meet at one point. Look into the opening opposite it. What would close this little room?

Open `point_polyhedra.tscn` in the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md), using **Run Current Scene** (F6). Edit `studies/point_polyhedra/polyhedra.gd`.

The script reads the same saved trace as Triangle and selects the same three original positions. Edits to Triangle's handles were temporary; they did not change that record. If no record is available, draw a bend in Trace and release to save it first.

We reuse the handles, segments and face material. The new construction separates **where vertices are** from **which vertices a face connects**.

## 1. Add a fourth position

The three selected positions are `a`, `b` and `c`. The script adds them and divides by three to find their centre:

```gdscript
    var centre := (a + b + c) / 3.0
    positions = [centre + Vector3(0.0, 0.0, -0.7), a, b, c]
```

`positions` is an `Array[Vector3]`. Entry `0` is the new point, placed 0.7 metres along negative Z from that centre. Entries `1`, `2` and `3` keep the earlier corners. The saved trace is unchanged.

Four pink handles carry these numbers. Their labels stay readable through the faces. Hold one and move it. We chose a depth direction in the room, not a direction calculated from your triangle. If all four points lie in one plane, move point `0` out of it. If the three earlier corners lie along one line, separate one as you did in Triangle.

## 2. Keep connections in a list

```gdscript
var faces := [
    [0, 1, 2],
    [0, 2, 3],
    [0, 3, 1],
]
```

`faces` is an array containing three smaller arrays. Each row gives three **indices into `positions`**. The numbers refer to vertices; they are not coordinates.

Read the first row: connect position `0`, then `1`, then `2`. Follow that triangle on the object. All three rows include `0`, so all three faces meet there. None joins `1`, `2` and `3` across the opening.

## 3. Reuse the triangle operation

Triangle submitted three positions directly. This version reads them from the face list:

```gdscript
        face_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
        for triangle in faces:
            for index in triangle:
                face_mesh.surface_add_vertex(positions[index])
        face_mesh.surface_end()
```

The outer `for` loop takes one face row. The inner loop takes each index in that row and adds its position to the mesh. It completes those three vertices before the outer loop takes the next face.

This is a **nested loop**: one loop runs inside another. Three rows submit nine vertices. Some positions are submitted more than once because neighbouring faces share corners.

As before, the script clears the old surface each frame. Before rebuilding, it copies the current handle positions into `positions`. Moving a corner changes every face that refers to its index. The face list stays the same.

## 4. Close the opening

Add one row to `faces`:

```gdscript
    [1, 3, 2],
```

Keep the comma and place the row before the array's closing `]`. Run again. The four positions remain where they started; the new row adds a face across the opening.

With four non-coplanar positions, these four faces enclose a **tetrahedron**. Non-coplanar means the positions do not all lie in one plane. Its edges need not have equal lengths; equal edges would make it regular.

Remove the row and run again. You recover the opening without deleting any position. In code, a hole can be an omitted connection.

## Keep two boundaries distinct

The mesh displays a surface. It adds no collision or material filling the interior. Only the small handles have colliders for pickup.

The museum's open trihedron makes a different choice: its convex collision hull closes the missing side even while the rendering leaves it open. The museum's barriers and slopes extend that investigation to the moving body.

For now, you can change a surface by moving its vertices or by changing its face list. The next hall carries those two decisions into a cube.

### Point_Animatedcube

Source: `commons/maps/Point_Animatedcube/tutorial.md`

# Cube — the diagonal was already there

A cube has six square faces. Our mesh draws them with twelve triangles. Move one corner and the difference becomes visible.

Open `point_cube.tscn` in the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md), using **Run Current Scene** (F6). Edit `studies/point_cube/cube.gd`.

Polyhedra separated positions from connections. We reuse that construction with eight specified positions, rather than selecting them from the saved trace. No recording is needed here; your earlier trace remains available.

## 1. Read the corners

`positions` contains eight `Vector3` values. Corners `0`–`3` form the back square at Z = −0.5. Corners `4`–`7` form the front square at Z = 0.5. Each side is one metre long.

The same PointHandle and Segment components draw the corners and edges. Number labels remain readable through the faces. Find `4`, `5`, `6` and `7` on the front square.

The first two rows of `faces` are:

```gdscript
    [4, 5, 7], [5, 6, 7],
```

Both triangles use `5` and `7`. The amber line marks this shared **diagonal**: an edge across the square between opposite corners. The first triangle is off-white; the second is pink so we can follow it.

## 2. Move only corner 6

Hold corner `6` and pull it a little towards you, out of the front square's plane. Use aim and E on desktop, or near grip in VR. Leave `4`, `5` and `7` where they are.

The white triangle stays fixed. The pink triangle tilts. Their shared diagonal becomes a crease.

Each frame, the script copies the handle positions back into the list:

```gdscript
    for i in range(handles.size()):
        positions[i] = handles[i].position
```

The face-building loop then reads those positions through the unchanged index rows. Only the second front triangle refers to `6`. Other triangles around that corner move too; follow its neighbours around the top and right side.

Release the corner. It stays where you left it. Restarting the scene restores the authored positions. Holding and moving a corner has edited the mesh, not translated or rotated the whole object.

For a repeatable change, set this variable to `0.35`:

```gdscript
var corner_shift := 0.0
```

At startup, the script applies it to corner `6`:

```gdscript
    positions[6].z += corner_shift
```

Run again. The same corner starts 0.35 metres farther along positive Z. Set `corner_shift` back to `0.0` to restore the cube.

## 3. Choose the other diagonal

First use `corner_shift = 0.0`. Replace the two front rows with:

```gdscript
    [4, 5, 6], [4, 6, 7],
```

Change `diagonal_pair` from `[5, 7]` to `[4, 6]` so the amber guide follows the new shared edge. Run again. Two triangles still cover the same flat square.

Now set `corner_shift` to `0.35`. Both front triangles contain `6`, so both tilt. The four corner positions match the previous deformed example, but the crease follows another connection. Changing the triangulation has changed the surface between them.

Restore the original rows, `[5, 7]` and `corner_shift = 0.0` when finished.

## What remains a cube?

Set `show_diagonal` to `false`. The guide disappears; the two triangles remain. Set `show_faces` to `false` to keep just the corner handles and twelve boundary edges. Restore both to `true`.

The initial shape has six geometric square faces. The `faces` list contains twelve rendering triangles. Counting those rows does not prove that the edited result still has equal edges, right angles or flat squares.

The colours and amber guide are supplied display aids. Both sides of each triangle are visible. This study gives the surface no thickness or collider; the handles have pickup colliders. The museum adds replay, a net that folds and falls, and the prefab collection as separate encounters. Follow those comparisons in the [museum companion](/book-review/doc/book/iterations/2026-10-04-cube-another-one/making.html).

We have used a position list, a connection list and a loop to construct a familiar body. In the next hall, we can ask how a short rule might generate some of that data for us.

### Primitives_Ignorance

Source: `commons/maps/Primitives_Ignorance/tutorial.md`

# Primitives — a rule for positions

An octahedron has six corners: two on each axis, equally far from its centre. We can use that regularity to generate its positions.

Open `primitive_rules.tscn` in the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md). The left study is the octahedron; the right is a sphere with its triangle edges exposed. Both use the same room and player as Cube.

## 1. Give a rule a name

Open `studies/primitive_rules/octahedron.gd`. Find this function:

```gdscript
func octahedron_positions(radius: float) -> Array[Vector3]:
    var directions: Array[Vector3] = [
        Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1),
    ]
    var points: Array[Vector3] = []
    for direction in directions:
        points.append(direction * radius)
        points.append(-direction * radius)
    return points
```

The three directions point along positive X, Y and Z. The loop scales each by `radius`, then adds its opposite. The minus sign reverses the direction. Six positions enter the list in order: +X, −X, +Y, −Y, +Z, −Z.

`radius` is a **parameter**: a named input to the function. Here it means the distance from the centre to a corner. Use a positive value. `float` declares a number that can have a fractional part. `-> Array[Vector3]` declares the result: a list of positions. `return points` sends that list back to the code that called the function.

The function calculates coordinates around `(0, 0, 0)`. It creates no visible object. The scene places this whole study above the floor, to your left.

## 2. Call it with another value

In `_ready()`, the script asks for the positions:

```gdscript
    positions = octahedron_positions(0.55)
```

`0.55` is the **argument**, the value passed into `radius` for this call. The returned list becomes `positions`.

Godot calls `_ready()` when the node is ready. Our new function runs because we call it there. It is not another automatic callback.

Change `0.55` to `0.75` and run again. All six corners move farther from the centre. Their opposite pairing and equal distances remain. The edge length changes too: this radius measures centre to corner, not corner to corner.

The existing face list connects these positions into eight triangles. Its indices were supplied separately; the function does not discover which corners belong to a face. We reuse Cube's handles, segments and nested face-building loop.

## 3. Move outside the rule

Restore `0.55` and run again. Hold one numbered corner and move it sideways. Use aim and E on desktop, or near grip in VR.

The neighbouring triangles follow. The result still has the same connections, but it is no longer a regular octahedron. The generated list was a starting arrangement, not a constraint on your hand.

`_process()` reads the edited handle positions each frame. It does not call the generator again. Restarting runs `_ready()` and restores the rule's result; temporary edits are not saved.

## 4. Return to the sphere

In Point One, SphereMesh gave a point a visible body. Open `studies/primitive_rules/sphere.gd`:

```gdscript
    sphere_mesh.radius = 0.55
    sphere_mesh.height = 1.1
    sphere_mesh.radial_segments = 8
    sphere_mesh.rings = 4
```

Radius and full height set the dimensions. `radial_segments` divides the turn around the vertical axis; `rings` controls subdivisions along the height.

Change only `radial_segments` to `16` and run again. Follow the additional edges around the sphere. Restore `8`, then change only `rings` to `8`. The subdivision changes in the other direction. The radius and height settings stay fixed in both trials.

SphereMesh generates its own positions and connections. The supplied MeshEdges guide reads that resulting mesh and draws its edges; it does not make a different sphere. The guide and numbered handles are teaching aids. Neither study's surface has a collider.

The museum's pillars, sphere comparisons and capsule extend this investigation. Here we have gained one reusable operation: a function that takes a value and returns data. A short rule can produce a body; its output remains something we can inspect and alter.

Continue through [Godot’s supplied forms](../Primitives_Godot/summary.md) to [Columns](../Primitives_Columns/summary.md). The existing [One column — an outline made of numbers](tutorial-column.md) study uses the same list, loop and function to separate a profile, its full height and the number of sides. Borrowed Outlines follows before Portals. The column study remains at this link so existing references continue to work.

### Primitives_Godot

Source: `commons/maps/Primitives_Godot/tutorial.md`

# Primitives Godot — teaching intent

This is a proposed summary, not a new full lesson. Read the `Primitives_Godot` entry in [the current storyboards](../../../doc/book/course/storyboards/opening.json).

Select one familiar generated mesh and compare a documented resource setting with the material, collision and behaviour supplied by its scene. A small edit should remain inspectable; the library itself has no universal parameter controls.

Sources: [mesh library](../../artifacts/ignorance_gallery/primitive_mesh_library.gd) and [seven-form choir](../../artifacts/seven_words_choir/seven_words_choir.gd). The learner's edit host remains to be chosen. Continue to [Columns](../Primitives_Columns/summary.md).

### Primitives_Columns

Source: `commons/maps/Primitives_Columns/tutorial.md`

# Columns — teaching intent and existing study

The proposed hall summary is `Primitives_Columns` in [opening.json](../../../doc/book/course/storyboards/opening.json). No new full tutorial is added here.

Use [One column — an outline made of numbers](../Primitives_Ignorance/tutorial-column.md), the existing reduced study. It separates radii, full height and side count while supplying the sampler and renderer. Its straight intervals differ from the curved-section museum builder.

The museum first compares equal forms at 4, 6, 8, 12 and 16 sides, then opens into a varied family. There are no live museum parameter knobs. Where an edited learner column belongs in this setting remains open. Continue to [Borrowed Outlines](../Primitives_Profiles/summary.md).

### Primitives_Profiles

Source: `commons/maps/Primitives_Profiles/tutorial.md`

# Borrowed outlines — teaching intent

This is a proposed summary, not a new full lesson. Read `Primitives_Profiles` in [opening.json](../../../doc/book/course/storyboards/opening.json) and the [existing source study](../../../doc/book/studies/glyph-form-atlas/README.md).

Follow one flat source profile into a body. Distinguish the region carried from the section route and scale. The font, triangulation and sweep builder stay supplied. A later small edit can change one disclosed recipe input after its learner host is agreed.

Keep the O sill, the vessel's missing bottom and the colon's disconnected parts explicit. A general account of topology, arbitrary paths and contour changes is deferred. Continue to [Portals](../Primitives_Portals/summary.md).

### Primitives_Portals

Source: `commons/maps/Primitives_Portals/tutorial.md`

# Portals — how close is useful?

The sphere became rounder as we added divisions. How many would be enough for something we want to make?

Open `primitive_portals.tscn` in the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md). A pink hexagon sits inside a grey circle guide. This is a reduced version of the planar comparison beside the museum's rings.

## 1. Follow the closed line

Open `studies/primitive_portals/perimeter.gd`. A supplied sampler gives us six positions equally spaced around a circle of radius one metre. They are in order; the first position is not repeated at the end.

We reuse the segment from Lines. To measure the whole boundary, we add the distances between neighbours, then close the line:

```gdscript
func polygon_perimeter(positions: Array[Vector3]) -> float:
    var total := 0.0
    for i in range(positions.size() - 1):
        total += positions[i].distance_to(positions[i + 1])
    total += positions[positions.size() - 1].distance_to(positions[0])
    return total
```

The loop measures all but the closing edge. The next line measures from the last position back to the first. Together they make the **perimeter**. This function takes a list and returns a number; it does not change the list or draw anything.

The hexagon's perimeter is about six metres. The corresponding circle's circumference is about 6.283185 metres. The straight edges take a shorter route.

## 2. Add sides

Find the settings:

```gdscript
var divisions := 6
var radius := 1.0
var tolerance := 0.01
```

Change `divisions` to `12`, then `24`, then `48`, running the scene after each edit. Keep the radius fixed. Watch the corners become less visible and the measured shortfall decrease. Walk closer when a corner becomes hard to see.

Each doubling uses twice as many segments. More detail has a construction cost, though a segment count alone does not tell us the frame rate.

The grey guide stays at 256 segments throughout. It is another finite drawing, not the exact circle against which the number is calculated.

## 3. Choose what counts as enough

The script compares the measured perimeter with the circumference formula:

```gdscript
    var circle_length := TAU * radius
    gap = circle_length - perimeter
```

`TAU` is Godot's approximation to 2π. The gap is a difference between total lengths, in metres. It is not the visible distance from a pink edge to the grey guide.

A **tolerance** is the difference we agree to accept. The supplied readout says *within tolerance* when `gap <= tolerance`. With `0.01`, 48 sides is the first of our four trials to pass.

Keep 48 sides and change the tolerance to `0.001`. Run again. The same polygon now falls outside the requirement. We changed the decision, not the geometry.

In exact geometry, these polygons approach the circle without becoming it. The displayed numbers also have limited precision. Neither a pleasing outline nor a passing comparison makes the construction exact.

The sampler and display are supplied, with their source included. You own the perimeter calculation and the settings. The museum's torus ladder and halving track give other ways to encounter a limit; this study measures neither their surfaces nor their motion.

We can now give a construction a purpose and a stopping criterion. Melencolia gathers these tools and asks what we want to do with them.

### Primitives_Melencolia

Source: `commons/maps/Primitives_Melencolia/tutorial.md`

# Melencolia — arrange what you can make

We can place points, connect faces and generate a form. Portals gave us a way to check one requirement. Now make an arrangement with the constructions we know.

Open `primitive_composition.tscn` in the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md). Three identical pyramids stand on the floor. The middle one is farther away. Walk to the side and compare their outlines.

## 1. Place the same form three times

Open `studies/primitive_composition/arrangement.gd`:

```gdscript
var positions: Array[Vector3] = [
    Vector3(-1.15, 0, 0),
    Vector3(0, 0, -0.8),
    Vector3(1.15, 0, 0),
]
```

These are positions for whole bodies. They are measured from the study's origin, which the scene places 0.7 metres behind the room's centre. Each pyramid's local origin is at the centre of its base. Keeping Y at zero leaves its base on the floor.

The familiar list and loop now arrange objects:

```gdscript
func _ready():
    for at in positions:
        var body := Pyramid.new()
        body.position = at
        add_child(body)
        bodies.append(body)
```

`Pyramid` is the supplied script in `pyramid.gd`. Each call to `Pyramid.new()` creates a mesh instance and builds its geometry in code. It uses five positions and a face list, as in Polyhedra. Its square base uses two triangles, as in Cube.

The six render triangles make five geometric faces. Every copy has the same dimensions and material. The loop gives each copy a different position and keeps its reference in `bodies`.

## 2. Bring the centre forward

Change the middle entry's Z value from `-0.8` to `0.8` and run again. From the entrance, the middle pyramid is now closer than its neighbours.

Its vertex positions inside the mesh have not changed. Its size on the screen has. Walk around it: which overlaps belong to this viewpoint?

Moving a body places its local construction elsewhere. In Cube, moving a corner changed the construction itself. Those operations can look related while changing different data.

## 3. Change the distance between neighbours

Keep the centre forward. Change the outer X values from `-1.15` and `1.15` to `-0.55` and `0.55`. Run again.

The arrangement becomes tighter. From some positions the outlines overlap; from others they separate. No pyramid has gained a vertex, and no face has been removed. The gaps and the view have changed.

These surfaces have no colliders. The gaps are visual and spatial relationships, not a tested walking clearance. The museum's raised court and solid obstacles are separate constructions.

## 4. Make one arrangement to keep

Restore the outer X values to `-1.15` and `1.15`. Place the middle pyramid somewhere else on the floor. Keep its Y value at zero and its X and Z values between `-2` and `2` for this room.

Look from the entrance, then from one side. Keep an arrangement that gives you something different from both positions. Save the script: restarting rebuilds the positions you wrote. Walking changes your view, not the saved arrangement.

This is a reduced study of the museum's geometric court. It does not reconstruct Dürer's engraving. The court, the tableau and the magic square have different tasks; the [museum source notes](tutorial-museum.md) keep those distinctions available.

We have made something exact enough to inspect and open enough to compose. Nothing in the pyramid's face list decided where it should stand. The critical text follows the desire invested in such forms. Here we have a small means of acting on it.

Transformation begins with these bodies. Next, their positions can change while the program runs.

---

## 02. Transformation: What Stays the Same When Everything Changes

### Trans_Pre

Source: `commons/maps/Trans_Pre/tutorial.md`

# A body that changes

In the last lesson, you placed three bodies. They stayed where you put them. Now keep one cube and change its position while the scene runs. Then add a turn and a change in size.

Open `trans_pre.tscn` in the [shared starter](../../../doc/book/studies/ada-xr-starter/README.md). Edit `studies/trans_pre/motion.gd`. The supplied `Cube` makes a 0.6-metre box with a dark mark on one face. The room and the small numerical display are also supplied. Every lesson object is created in code.

## 1. Let the clock run

The study starts with:

```gdscript
var stage := 0
var elapsed := 0.0
```

Run it. The cube stays still, but the elapsed time below it increases.

Point Zero counted frames. Here `_process(delta)` receives the time since the previous frame, in seconds:

```gdscript
    elapsed += delta
```

Adding those intervals gives us a clock. The animation will use seconds, so rendering more frames does not make it run faster.

## 2. Move between two heights

Set `stage` to `1` and run again. The cube rises, reverses and returns. These variables determine its journey:

```gdscript
var centre := Vector3(0, 1.3, 0)
var travel := 0.25
var leg_seconds := 1.5
```

The centre starts 1.3 metres above the floor. Its lower and upper limits are 1.05 and 1.55 metres. `travel` is the distance from the middle to either end.

Inside `_process`, one value carries time into position:

```gdscript
    var t := pingpong(elapsed / leg_seconds + 0.5, 1.0)
    if stage >= 1:
        cube.position.y = lerp(centre.y - travel, centre.y + travel, t)
```

`pingpong` produces a value that travels from 0 to 1 and back at a steady rate. The added `0.5` starts it halfway up. `lerp` uses that value to choose a position between the two heights: 0 gives the lower end, 1 the upper end, and 0.5 their midpoint.

`if stage >= 1` runs this indented line whenever the stage is at least 1. The later stages will keep this movement.

Set `travel` to `0.4`. The cube now reaches 0.9 and 1.7 metres. Restore `0.25`, then set `leg_seconds` to `3.0`. The distance stays fixed; the journey slows. This value is the time between the ends. A complete return takes twice as long. Because we start in the middle, the first arrival takes only half a leg.

Restore `leg_seconds` to `1.5` before continuing.

## 3. Add a turn

Set `stage` to `2`. The same cube keeps rising and falling, and now turns:

```gdscript
    if stage >= 2:
        cube.rotate_y(turn_speed * delta)
```

The dark mark lets you follow a particular face. The turn is around the cube's centre, about the vertical Y axis. Its centre still follows the same path.

`turn_speed` is `TAU / 8.0` radians per second. `TAU` is one complete turn in radians, so this setting takes eight seconds per turn. Multiplying by `delta` gives the angle to add in this frame. Change the divisor to `4.0` for a four-second turn, then restore `8.0`.

## 4. Change size as well

Set `stage` to `3`:

```gdscript
    if stage >= 3:
        var factor: float = lerp(1.0 - pulse, 1.0 + pulse, t)
        cube.scale = Vector3.ONE * factor
```

With `pulse` at `0.3`, the factor travels between 0.7 and 1.3. `Vector3.ONE` is `(1, 1, 1)`: multiplying all three components by the same factor preserves the cube's proportions. Its mesh remains 0.6 metres wide; the displayed width ranges from 0.42 to 0.78 metres.

The assignment writes a new scale each frame. It does not keep multiplying the previous scale. The same `t` drives height and size, so the cube is largest at the top. Turning has its own rate.

Try `pulse` at `0.1`. Keep a version whose timing and extent you like. You can now change a body's position, orientation and size without rebuilding its mesh.

For a short comparison, [replace steady travel with sine](tutorial-sine.md). The endpoints stay fixed; the way the cube arrives changes.

The museum adds touch detection and collection to these operations. This reduced study animates a visible body. In the next hall, a moving surface will also have to support the visitor.

### Trans_Introduction

Source: `commons/maps/Trans_Introduction/tutorial.md`

# Transformation Introduction

Three gaps in sequence: translation, scale, rotation. First watch what changes, then cross during the opening. The source scenes are `transport_cube.tscn`, `scale_cube.tscn` and `rotation_cube.tscn` in `commons/scenes/mapobjects/`.

Define a transform from scratch.

```gdscript
var t := Transform3D.IDENTITY
```

The identity transform: origin at zero, no rotation, unit scale.

Apply translation.

```gdscript
func translate(t: Transform3D, offset: Vector3) -> Transform3D:
    return t.translated(offset)
```

Adds the offset to the origin. The orientation and scale are preserved.

Apply rotation.

```gdscript
func rotate_y(t: Transform3D, angle_rad: float) -> Transform3D:
    return t.rotated(Vector3.UP, angle_rad)
```

Rotates around the Y axis by the given angle. Other axes work the same way.

Apply scale.

```gdscript
func scale(t: Transform3D, factors: Vector3) -> Transform3D:
    return t.scaled(factors)
```

Scales each axis independently. Uniform scale uses Vector3.ONE times a single factor.

Compose three transforms in order.

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

Scale, then rotate, then translate. The order matters: different orders produce different final transforms.

The first crossing changes position.

```gdscript
global_position = global_position.move_toward(target_position, move_speed * delta)
var movement_delta = global_position - previous_position
_translate_rider(carried_player, movement_delta)
```

These are excerpts from `transport_cube.gd`. The hall's `tc:2:z:auto` places a one-metre cube over a three-metre gap and moves its centre two metres along Z. At each endpoint one edge meets the bank. Automatic motion lets the visitor watch first and board when it returns. `_translate_rider` applies each small displacement to the supported rider; in VR it keeps the collision body and the camera's rig together. Moving only an image, or only the player's collision body, would leave part of the crossing behind.

The second crossing changes size.

```gdscript
var scale_vec: Vector3 = Vector3(safe_scale, safe_scale, safe_scale)
mesh_instance.scale = scale_vec
box_shape.size = scale_vec
```

In `scale_cube.gd`, `current_scale` travels between 0.5 and 3.0, then holds at full size for four seconds. The centre is 1.5 metres below the bank. At maximum size its top reaches the floor; at minimum it withdraws below it. Both the visible mesh and the collision box change size. The map uses `#seat:deck` with zero additional Y offset: seating already accounts for the box's half-height.

The third crossing changes orientation.

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
static_body.transform = mesh_instance.transform
```

These excerpts from `rotation_cube.gd` connect the visible angle to the physical surface. The hall opts into `profile:bridge`: a plank three metres long, one metre wide and 0.2 metres thick. Its centre stays fixed. At zero degrees it lies across the route, with a gap ahead and behind; at ninety degrees its length reaches across the three-metre opening, meeting both banks edge to edge. Its top stays level with the floor throughout the Y turn. The four-second pauses give time to cross while aligned.

Now compare the three events. Translation carries the surface between banks. Scale grows a surface until it meets them. Rotation aligns a length with them. The banks supply a shared reference, while the player's body tests whether the apparent opening is physically usable.

The helpers below concern transforms as data. They are additional experiments for the nearby matrix and composition artifacts, rather than the controls of these three crossings.

Check identity.

```gdscript
func is_identity(t: Transform3D) -> bool:
    return t.is_equal_approx(Transform3D.IDENTITY)
```

Identity preserves the input. Useful as a test for whether a chain of transforms cancels out.

Invert a transform.

```gdscript
func invert(t: Transform3D) -> Transform3D:
    return t.affine_inverse()
```

Undo the transform. Composing t with t.affine_inverse() produces identity.

Compose with multiplication.

```gdscript
func combine(a: Transform3D, b: Transform3D) -> Transform3D:
    return a * b
```

Right-to-left application order. a * b applies b first, then a.

Extract the origin.

```gdscript
func get_origin(t: Transform3D) -> Vector3:
    return t.origin
```

The origin is the translation part of the transform. Ignore the basis to get just the position.

## Change the reference: an adjustable landing

After the third crossing, MOVE THE BANK gives the far landing a one-metre range along local +z. Its top remains at the grid deck. A single slider sets `target_displacement`; `_physics_process` advances at 0.25 m/s. RESET returns both the target and slider to zero. The three-metre plank and its timer are unchanged.

At the aligned pose, the three-metre plank meets the original bank with zero overlap. The surface separation is `displacement`: zero means the edges meet, positive means an open gap. This is not a traversal predicate. Body radius, floor snapping, gravity and movement all enter the crossing test. Walk the side aisle to compare settings and return without crossing the moving joint.

Source: `commons/artifacts/adjustable_landing/adjustable_landing.gd`. The artifact owns the movable slab and its controls; the map leaves a recess for it and supplies fixed side aisles. It does not resize or rotate the bridge.

## Move the destination — 23 September

At the approach to the rotation crossing, MOVE THE BANK translates the landing through one metre while the plank keeps its existing turn. Compare the originally meeting edges with the gap after moving the bank, then RESET. The control is about 1.13 m above the floor; the still side aisles remain available. The production artifact separates control placement from the landing transform.

### Trans_Translation

Source: `commons/maps/Trans_Translation/tutorial.md`

# Trans Translation

Moving. Displacement. Position as coefficients.

Translate a single object.

```gdscript
func move_to(node: Node3D, target: Vector3) -> void:
    node.global_position = target
```

Direct assignment. One frame, the object is there.

Translate smoothly over time.

```gdscript
func tween_to(node: Node3D, target: Vector3, duration: float) -> void:
    var tween := create_tween()
    tween.tween_property(node, "global_position", target, duration)
```

The tween interpolates linearly. Duration in seconds.

Translate along a local axis.

```gdscript
func move_forward(node: Node3D, distance: float) -> void:
    var forward: Vector3 = -node.global_transform.basis.z
    node.global_position += forward * distance
```

Local translation respects the node's current orientation. Forward is -Z in Godot.

Apply a translation impulse to a rigid body.

```gdscript
func nudge(body: RigidBody3D, impulse: Vector3) -> void:
    body.apply_central_impulse(impulse)
```

Impulse is velocity times mass. Physics integrates the impulse into velocity on the next step.

Translate relative to another node.

```gdscript
func move_relative_to(node: Node3D, reference: Node3D, offset_local: Vector3) -> void:
    var offset_world: Vector3 = reference.global_transform.basis * offset_local
    node.global_position = reference.global_position + offset_world
```

Local offset is transformed through the reference's basis. The result is a world-space position.

Chain multiple translations.

```gdscript
func move_sequence(node: Node3D, steps: Array, duration_per_step: float) -> void:
    var tween := create_tween().set_parallel(false)
    for target in steps:
        tween.tween_property(node, "global_position", target, duration_per_step)
```

Sequential tweens move the node through a sequence of positions. Useful for scripted paths.

Interpolate along a curved path.

```gdscript
func move_along_bezier(node: Node3D, curve: Curve3D, duration: float) -> void:
    var tween := create_tween()
    tween.tween_method(
        func(t): node.global_position = curve.sample_baked(t * curve.get_baked_length()),
        0.0, 1.0, duration
    )
```

Sample the Bezier curve at interpolated positions. The node follows the curve's shape over the duration.

You can now translate a node instantly or over time, locally or relative to another node, along straight lines or curves. The seven rides in this hall already separate and combine those components. Trans_Rotation follows in the active sequence.

Check identity.

```gdscript
func is_identity(t: Transform3D) -> bool:
    return t.is_equal_approx(Transform3D.IDENTITY)
```

Identity preserves the input. Useful as a test for whether a chain of transforms cancels out.

Invert a transform.

```gdscript
func invert(t: Transform3D) -> Transform3D:
    return t.affine_inverse()
```

Undo the transform. Composing t with t.affine_inverse() produces identity.

Compose with multiplication.

```gdscript
func combine(a: Transform3D, b: Transform3D) -> Transform3D:
    return a * b
```

Right-to-left application order. a * b applies b first, then a.

Extract the origin.

```gdscript
func get_origin(t: Transform3D) -> Vector3:
    return t.origin
```

The origin is the translation part of the transform. Ignore the basis to get just the position.


## Same destination, different permission

On the final terrace, `translation_cube_demo` is instantiated twice: `course:lift_lateral` with a rail guide, and `course:free` with ghost endpoints. Their knobs begin 0.5 m above each artifact root; the 0.8 m plinth brings that to 1.3 m above the deck.

The guided mechanism projects hand displacement onto a permitted axis, clamps the distance and admits the next axis only after the lift threshold. The free mechanism admits both components at once within the same bounds. In `constrained_door.gd`:

```gdscript
var t = _clamp_run((knob_pos - start).dot(phase1_dir), target_y, 0.0, 0.05)
knob_pos = start + phase1_dir * t
```

Pure translations commute: adding the same two displacement vectors in reverse order gives the same endpoint. This puzzle imposes an order through its constraints; that is a property of the mechanism, not a limitation of vector addition.

## Watch the accepted movement

The exit mechanisms now leave a pale trace when a handle is held. Try the same small upward-and-outward gesture on each. The guided door records the lift after discarding the sideways component; the free door keeps both components within its bounds. Then follow the rail to its corner and outwards. Compare that bend with a direct diagonal in the other mechanism.

The free handle can be brought back towards its starting corner to try a curved route. The short recent history remains visible, with older samples eventually rolling off. This returns to Point_Trace with a changed receiver: the record belongs to the constrained knob, not to the whole hand gesture. Release does not reset the mechanism or erase its trail; the artifact’s existing reset method clears it when called, and reloading the hall starts a fresh record.

### Trans_Rotation

Source: `commons/maps/Trans_Rotation/tutorial.md`

# One centre, many centres, an enclosure

1. Find the fixed middle of each 8.4 m blade. Y offers a level crossing; X and Z retain held climbing slopes. Then board their small level end-platforms: X travels forward along z and up3m, Z travels sideways along x and up3m. Each platform follows a180-degree upper arc while remaining upright, with12-second docking pauses and a12-second turn. It reverses along the upper arc for the return. Compare the blade's changing orientation with the platform's fixed upright basis; remaining on a bare blade through vertical cannot be a standing ride. Grid wedges and still aisles provide returns.
2. Walk forward through each two-column, six-row array. The angles are 0, 18, 36, 54, 72 and 90 degrees. Compare X, Y, Z and fixed X-then-Y-then-Z order without changing cube size or centre spacing. Then compare the cyan 0.44 m and pink 1.20 m test bodies: the same 1.6 m height, 2 m/s forward input, gravity, 45-degree slope limit and 0.15 m floor snap. Rings retain endpoints; readouts include sideways displacement. REPLAY starts both passes again. A wider body need not stop sooner: Z can carry it sideways into a continuing route. These are collision trials, not a proof that another body or movement cannot pass. Inspect a stopped route from an aisle. Ninety degrees can restore a flat-looking endpoint without making the intervening passage easy.
3. Walk through five hollow tunnel segments with the same eighteen-degree spatial increment. Then observe the five carousel profiles: their layers use angular speeds of `0.5 * pow(1.2, i)` radians per second. Separate an angle assigned by position from an angle accumulating with time.

```gdscript
station.pivot.basis = Basis(station.axis, deg_to_rad(degrees * float(station.sign)))
var degrees := float(cube.get_meta("row")) * row_angle_step
cube.basis = rotation_for_band(band, degrees)
```

A rigid rotation preserves a solid's internal distances and topology. Passage also depends on its neighbours, pivot, collision and the moving body. The tunnel's subtraction supplies its hole; rotation arranges the holes. Compare the room left around the five carousel profiles. Carry the relation between an object's dimensions and your body into Scale, where the surroundings grow while the visitor keeps the same size.

The compact arrangement retains full-size crossing blades and array cubes. It reduces repetition counts and removes one duplicate cake; the five distinct cake profiles remain available together. Headset traversal and comfort still require a human review.

## Standing through the turn

`wall_crossings.gd` now advances on physics ticks at priority−110. `rotation_rider_deck.gd` detects actual supported feet and applies each platform displacement to the rider. For XR it uses the same incremental body/origin movement as the transport cube and rebases only its own moving-ground contact, preventing double carry. A jump or step off releases the rider. The player's pitch, roll and room-scale camera offset are preserved.

The deck's top follows `(0,1.5,0) + R(axis, angle) * radial + side_offset`. X uses radial `(0,-1.5,-3.5)` and side offset `(-2.2,0,0)`; Z uses radial `(-3.5,-1.5,0)` and side offset `(0,0,-2.2)`, turning in the opposite sense so both trips use the upper arc. The platform's basis stays upright. Its fixed bracket height compensates for the original blade's thickness-adjusted axle. Both endpoint tops meet grid heights0m and3m.

Tests must cover the moving ride, natural boarding, departure and the full body volume around the arc. A static ramp crossing test alone did not cover the failure reported in VR.

## Following a marked orientation — 23 September

Compare the first and last top marks in the Y array: at ninety degrees the occupied cube shape repeats while the L points another way. Beyond the combined array, the restored composition workbench starts on pair four, X30° and Y45°. Follow the intermediate forms to compare `Y * X` with `X * Y`. Pair two is the counterexample: rotation and uniform scale about the same origin commute, although their intermediate states differ. The stage separates the drawings for visibility; both calculations use the same origin.

The array has two batched mark surfaces per band; the sweep’s mark is attached to its rotating cube. Neither changes collision. The grid parser now recognises `initial_pair` as a numeric parameter rather than a tutorial rotation shorthand.


<!-- study-spine:hinge_release -->

## Return: A pose left

Change the return speed while keeping the reference pose. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses loop, transform, trace. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`hinge`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-clark-a-pose-left/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:hinge_release -->

### One source change: A pose left

Change the existing degrees_per_second value from 45 to 20. Return takes longer; the destination angle stays the same.

```gdscript
degrees_per_second = 20.0
```

Source: `commons/artifacts/spine_studies/hinge_score.gd`. Use the prepared scene to run and compare.

### Trans_Scale

Source: `commons/maps/Trans_Scale/tutorial.md`

# What changed enough to let you through?

Enter the room and inspect the tiny door beside the standing figure. Try it before taking the bottle. Look at the food tower's plates and at the distance between the table and the figure.

Take the DRINK ME bottle on the top plate: VR grip/pickup, or the museum's desktop right-button carry gesture. The room changes size in a cut, and your next position is on the enlarged table. You do not see the sizes between. Find the figure and door again before descending the porcelain steps.

Only after comparing the two views, inspect the implementation:

```gdscript
room.scale = Vector3.ONE * FACTOR
var feet := table.to_global(landings[0]) + Vector3.UP*0.08
```

The first line multiplies the room and its children's dimensions and relative positions. The second computes the arrival point; moving the body is a separate operation. `FACTOR` is four. The assignment changes the scale at once. After a physics frame, the program relocates the body to the enlarged table; it does not animate growth. The museum, body, gravity and walking speed are outside that multiplication.

Descend the serving plates and walk out of the room through the former tiny door. It has changed from 0.45 by 0.60 metres to 1.8 by 2.4 metres. Pass through the equally sized gold frame beyond it: that frame remained fixed throughout. Then turn toward the museum exit. The fixed wall at the room entrance makes this a route through the experiment; it does not scale with the room. Which proportions survived? Which distances became tasks? If the body and its movement had also scaled, would the door have become usable?


<!-- study-spine:reference_passage -->

## Return: Who fits through?

Change opening width while keeping the body and opening height. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses coordinates, transform. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`passage`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-five-reference-rooms/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:reference_passage -->

### One source change: Who fits through?

Change the minimum opening from 0.48 to 0.60 metres. Keep the 0.56-metre comparison strip and test the narrow state again.

```gdscript
var width := lerpf(0.60, 1.68, amount)
```

Source: `commons/artifacts/reference_studies/passage.gd`. Use the prepared scene to run and compare.

### Trans_Body

Source: `commons/maps/Trans_Body/tutorial.md`

# Trans Body — approach, change, memory

Watch each threshold before entering. Cross it, then look back. The sequence is rotation, deletion and scaling; the comparison is what the room restores and what it keeps.

## Slats turn

`approach_wall.gd` reads visitor coordinates in the wall's local space. Within its reach, the distance calculation includes:

```gdscript
var t: float = absf(cx - _vx[v]) / ap
var d: float = absf(_vz[v]) / rc
var o: float = (1.0 - t) * (1.0 - d)
o = o * o * (3.0 - 2.0 * o)
```

The complete function skips visitors outside the aperture or reach. The final line eases the response. A separate clearance rule opens enough neighbouring slats for the body. The default swing mode rotates the slats around their hinges. Move outside its reach and wait for the response to settle. Merely crossing the wall can leave you close enough to hold it open.

## Cells are removed

`carve_grid.gd` tests the visitor's collision volume with a small added reach:

```gdscript
cut += _bite_at(c, _v_r[i] + bite_m, _v_hs[i])
```

Here `c` is the collision shape's centre in lattice coordinates, `_v_r[i]` its radius and `_v_hs[i]` its vertical half-segment. `bite_m = 0.16` extends the cut beyond the surface where collision stops the visitor. Removed cells leave both the visible lattice and the collision representation. `regrow_s = 0` keeps the cut while this room remains loaded. The current map also places `carve_grid#leak:keep`. On unload, `_leak_spill()` sends removed local cell centres to the `LeakData` autoload; on rebuilding, `_leak_restore()` reapplies the recorded cells that still match the lattice. The store is in memory, limited to 64 events and 2,048 points per event, and can be cleared. It does not save to disk. Returning during the same session can therefore meet an earlier cut, but this is not an unlimited or permanent record.

The default lattice has four vertical layers at 0.34 m spacing, with 0.29 m cubes. Its top is about 1.335 m above the base. A standing visitor can see above it: the cut is open-topped. The record is a discretised intersection with the visitor collider plus its bite margin, rather than a full cast of a person.

Moving the visitor is translation; deleting lattice cells is a separate operation. Count the cells before and after a cut to see the difference.

## Blocks shrink and return

`approach_scale.gd` converts the nearest body's distance into a size factor:

```gdscript
var t: float = clampf(sqrt(_dist2[i]) / reach_m, 0.0, 1.0)
t = t * t * (3.0 - 2.0 * t)
return lerpf(min_scale, 1.0, t)
```

Near the body, the factor approaches `min_scale`; far away it approaches one. The artifact applies the same size to mesh and collision box. It also sets the block centre to half the new height, keeping the base on the floor. Horizontal grid locations remain fixed.

At the caption beyond the last row the last row can still be within the 2.2 m sensing reach. Continue into the exit area and wait: these blocks then return. The lattice's missing cells do not. This difference in memory is the room's final comparison. The next hall's growers also resize, but their input is elapsed time, not distance to a visitor.

The encounter recognises supported player collision bodies. A 52 cm-wide test capsule is one model, not a universal body. Player size, controller motion, collision proxies and response time all affect what passage is possible.


## Current museum illustration and seating repair — 23 September

The book's before/after lattice figure uses a fixed elevated camera in the actual isolated museum. Its normal Walker, with a 0.64 m wide and 1.5 m high capsule, was driven through the lattice by physics-tick movement; no cells were removed directly by the capture script. This selected straight walk removed 132 of 484 cells. The cut remains after the body is moved away. These are supplied inputs, not a human or headset observation.

That pass exposed a construction defect in `approach_scale`: the initial AnimatableBody3D pose was centred at y=0 before the node entered the scene tree. Physics synchronization restored that pose after the initial size assignment, and automatic grounding compensated by raising the artifact root 0.575 m. Blocks then rose above the floor on their first size response. Each block is now given its standing centre height before it enters the tree. Mesh and collider bases stay on the deck at full, reduced and restored sizes. No map token, dimensions, sensing reach or size law changed.

`tools/probes/body_book_illustrations.gd` records selected continuous walks through each of the three thresholds, with the body placed at each separate approach. The slats and blocks return after leaving reach; the lattice keeps its removed cells. `tools/probes/body_block_seating.gd` is the small diagnostic used to isolate the old height drift. [Images, exact changes and full evidence](../../../doc/book/iterations/2026-09-23-body-what-remains/index.html).

### Trans_Pit

Source: `commons/maps/Trans_Pit/tutorial.md`

# The Moving Boundary — read the timed study

The three zones use position, rotation and size as timed obstacles. The floor remains level, and a bypass remains available. Watch a complete cycle from beside the lane before choosing to enter it. The source artifacts are `pusher_block.gd`, `rotation_cube.gd` and `grower_block.gd`; the middle zone also retains four `free_ball_launcher` instances.

## Translate between endpoints, with a pause

The pusher caches a world-space start and endpoint:

```gdscript
_end_pos = _start_pos + push_axis.normalized() * push_distance
```

A late grid configuration refreshes this cached endpoint and its direction arrow. Without that refresh, a block configured for Z could keep the default path along X.

During the moving part of its physics update:

```gdscript
var speed_normalized: float = push_speed / push_distance
_t += _direction * speed_normalized * delta
_t = clampf(_t, 0.0, 1.0)
var target_pos: Vector3 = _start_pos.lerp(_end_pos, _t)
_body.global_position = target_pos
```

At `_t = 0` or `_t = 1`, the block waits for `pause_time`, then reverses `_direction`. The moving surface is an `AnimatableBody3D`.

| Placement (x,z) | Direction | Travel | Speed | One-way time | Pause at each end |
|---|---|---|---|---|---|
| (3,3) | +Z | 2 m | 1.5 m/s | about 1.33 s | 1.5 s |
| (7,3) | +Z | 2 m | 2 m/s | 1 s | 1 s |
| (5,5) | −Z | 2 m | 1.8 m/s | about 1.11 s | 1.2 s |

Each token places the block centre 0.49 m above the floor, half its 0.98 m side. Its cached endpoints therefore keep the whole block above the deck. The three paths are separate and stop before the solid transverse walls. The eastern route avoids these lanes. Compare travel and waiting by choosing a lane, rather than treating progress through the room as proof that its timing was learned.

## Rotate a wall profile

The middle zone places `rc:90:y:4:-0.6` and `rc:90:y:3:-0.6`. These are step-and-pause rotation cubes, not continuous revolving walls. Their box profile is 2.2 × 2.2 × 1 metre; the authored vertical offset sinks part of that profile below the deck.

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
static_body.transform = mesh_instance.transform
```

The angle moves between zero and ninety degrees around Y at 45 degrees per second. Each turn takes two seconds; pauses are four and three seconds respectively. Measure the available width beside a slab at both orientations. Its own dimensions are fixed while its projection across the route changes.

## Grow from the floor on a clock

All three map tokens specify `min:0.3`, `max:3.5`, `speed:0.15`, `anchor:floor`, and `plinth:0`. Configuration reaches the live artifact.

```gdscript
_time += delta * grow_speed * TAU
```

For floor anchoring, the interpolation value is:

```gdscript
var t: float = (1.0 - cos(_time)) * 0.5
var current_scale: float = lerpf(min_scale, max_scale, t)
```

All three growers share this rate and small starting configuration. The cosine starts this configuration small. A complete cycle takes `1.0 / grow_speed`, about 6.67 seconds. No visitor distance is read.

The artifact sets the same side length on its mesh and collision box. It keeps their centres half that length above the root's floor position:

```gdscript
var centre_y: float = s * 0.5 if anchor == "floor" else 0.0
_col_shape.position.y = centre_y
_mesh.position.y = centre_y
```

The `AnimatableBody3D` origin remains fixed. Updating the child geometry avoids its physics synchronization restoring an old body position while the collision shape has already changed size. Existing placements without `anchor:floor` retain their centre-anchored sine cycle.

## What to compare

Ask what stays invariant in the object, then ask what happens to the visitor's available space. Translation preserves the object's dimensions; rotation preserves its internal distances; this positive uniform scaling preserves proportions. Nonuniform scaling would change those proportions.

The legacy fire utilities have been removed, so their flames no longer occupy the observation floor. This is a ground-level study without an enforced failure consequence. A clear route around a lane is part of the current design; do not describe it as a lethal pit or a compulsory timing gate.

Compare clearances for particular bodies. A capsule test checks one radius and height. It does not stand in for all player sizes, locomotion choices or comfort needs.

---

## 03. Arrays and Regularity

### Array

Source: `commons/maps/Array/tutorial.md`

**Missing tutorial.md — no substitute text added.**

### Tutorial_3D

Source: `commons/maps/Tutorial_3D/tutorial.md`

Current encounter, 2026-09-17

array_flight_lab reuses the existing pickup-cube grid and the Menger flight enclosure. X/Y/Z selects an address. Collection writes zero without shifting other indices. Flight belongs to a locomotion region, not to the array data structure.

The step-by-step reading is in final.md. Earlier objects and layouts remain in the archive; they are not the current walkthrough.


<!-- study-spine:open_structures -->

## Return: A rule takes up space

Replace (column + row) % 5 with column; keep all 25 addresses. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses line, coordinates, transform, array. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`open`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-lewitt-reading-a-rule/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-spine:reference_suspension -->

## Return: A place still held

Change fragment roughness without changing any of the 75 positions. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses array, coordinates. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`suspension`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-hatoum-grid-under-load/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:open_structures -->

### One source change: A rule takes up space

In form_at(), replace the cyclic return with this expression. Read one row, then one column; every address remains occupied.

```gdscript
return column
```

Source: `commons/artifacts/spine_studies/open_rules.gd`. Use the prepared scene to run and compare.

<!-- study-edit:reference_suspension -->

### One source change: A place still held

This is the existing corner rule in fragment(). Change only the multiplier on offset, for example amount * 0.5. The enclosing loops still place 75 fragments.

```gdscript
corners.append(base + offset * amount)
```

Source: `commons/artifacts/reference_studies/suspension.gd`. Use the prepared scene to run and compare.

### Tutorial_Tiling_Floor

Source: `commons/maps/Tutorial_Tiling_Floor/tutorial.md`

Current encounter, 2026-09-17

tiling_principles uses the same binary diagonal tile across six five-metre floor fields. TURN MOTIF changes the source orientation. EXCEPTION changes one designated cell in one field. This introduces arrangement before the Color chapter.

The step-by-step reading is in final.md. Earlier objects and layouts remain in the archive; they are not the current walkthrough.

### Tutorial_Tiling_Walls

Source: `commons/maps/Tutorial_Tiling_Walls/tutorial.md`

Current encounter, 2026-09-20

The wall mode of tiling_principles preserves the six image rules on five-metre panels with solid backing. Changing the receiver changes projection and bodily access without changing the generating image.

After the six fields, wall_exception carries the ONE EXCEPTION texture onto a hinged section of the actual museum enclosure. TURN WALL rotates its visible surface and collision together. The visitor can step onto the exterior landing, inspect the reverse, and return; the occupied opening and landing inhibit turning. This is a second primary encounter, not another image rule.

The hall now uses the museum's authored floor and enclosure directly, rather than an embedded GridSystem. The map's museum.turning_wall declaration and placed wall_exception jointly reserve the opening. Other halls retain their existing simulation settings.

The step-by-step reading is in final.md. Earlier objects and layouts remain in the archive; they are not the current walkthrough.

### Tutorial_Disco

Source: `commons/maps/Tutorial_Disco/tutorial.md`

# Disco

A 17×17 dance floor. Each tile triggers when stepped on. A step sequencer loops the pattern.

Build the floor.

```gdscript
const FLOOR_SIZE := Vector2i(17, 17)

func build_dance_floor() -> void:
    for y in FLOOR_SIZE.y:
        for x in FLOOR_SIZE.x:
            var tile := DANCE_TILE_SCENE.instantiate()
            tile.position = Vector3(x, 0, y)
            tile.set_meta("coords", Vector2i(x, y))
            tile.body_entered.connect(_on_tile_entered.bind(tile))
            add_child(tile)
```

289 tiles. Each is an Area3D that detects body entry.

Handle tile activation.

```gdscript
func _on_tile_entered(tile: Area3D) -> void:
    var coords: Vector2i = tile.get_meta("coords")
    play_tone_for(coords)
    light_tile(tile, 0.5)
    if recording:
        record_in_step(coords)
```

Playback plus recording, depending on current mode.

Map a tile to a pitch.

```gdscript
const PENTATONIC := [0, 2, 4, 7, 9]  # semitones from root

func pitch_for(coords: Vector2i) -> float:
    var scale_index: int = coords.x % PENTATONIC.size()
    var octave: int = coords.y / PENTATONIC.size()
    var semitones: int = octave * 12 + PENTATONIC[scale_index]
    return 440.0 * pow(2.0, (semitones - 9) / 12.0)  # A4 = 440 Hz
```

Pentatonic scale avoids dissonance. The floor's columns map to scale degrees; rows map to octaves.

Light a tile briefly.

```gdscript
func light_tile(tile: Area3D, duration: float) -> void:
    var mesh := tile.get_node("Mesh")
    var original: Color = mesh.material_override.albedo_color
    mesh.material_override.emission_enabled = true
    mesh.material_override.emission = Color(1, 1, 0)
    var tween := create_tween()
    tween.tween_property(mesh.material_override, "emission_energy_multiplier", 0.0, duration)
```

Bright yellow emission that fades over the duration. The visual cue lasts long enough to register but not long enough to overlap with the next beat.

Record into the step sequencer.

```gdscript
var steps: Array = []  # array of arrays of Vector2i
const STEP_COUNT := 16
var current_step: int = 0

func _ready() -> void:
    for _i in STEP_COUNT:
        steps.append([])

func record_in_step(coords: Vector2i) -> void:
    if not coords in steps[current_step]:
        steps[current_step].append(coords)
```

Each step holds the set of tiles active during that beat. Multiple activations at the same beat stack into one step.

Advance the sequencer.

```gdscript
@export var bpm: float = 120.0
var time_since_step: float = 0.0

func _process(delta: float) -> void:
    time_since_step += delta
    var step_duration: float = 60.0 / bpm / 4.0  # 16th notes
    if time_since_step >= step_duration:
        time_since_step = 0.0
        current_step = (current_step + 1) % STEP_COUNT
        play_step(steps[current_step])
```

Tempo-based advancement. At 120 BPM with 16th notes, the sequencer advances every 0.125 seconds.

Play a step.

```gdscript
func play_step(active_tiles: Array) -> void:
    for coords in active_tiles:
        var tile := find_tile(coords)
        if tile:
            play_tone_for(coords)
            light_tile(tile, 0.1)
```

Every tile in the step fires simultaneously. A strummed chord or a polyrhythmic pulse.

You can now build a dance floor, map tiles to pitches via a pentatonic scale, record into a step sequencer, and play the sequence back at any tempo. Chamber_Arrays closes the sequence with arrangement-as-catalyst.

---

## 04. Color and Composition

### Color_Context_Placed

Source: `commons/maps/Color_Context_Placed/tutorial.md`

# Add colour to the construction

This opening gathers primitives, transformations and arrays already encountered. Follow the current final.md: the tutorial progression is comparison between fixed objects, with the visitor supplying movement.

1. Recognise the same five-piece column under four colour assignments. Read the actual elements array: an index supplies the next entry, while the construction loop gives that ordering an upward direction. Separate geometry from how its pieces receive colour.
2. Keep colour by shape while changing the primitive alphabet. A category in code can group a cone and a wedge without making them identical.
3. Keep the cut alphabet and its colour assignment while changing static pose. Successive levels turn around Y, narrow across X/Z, or combine both. Their heights remain unchanged.
4. Compose richer stacks from the same vocabulary: unequal heights, broad discs, small beads, sideways offsets and chosen colours. These fixed sculptures do not simulate balance.
5. Read art and design DNA as composed choices: proportion, ordering and palette. The gallery configurations are the actual source data.
6. Inspect the rainbow pedestal shaft raised to 6.2 m with its broad cap. Thirty stripes use six palette entries: i % stripe_colors.size() repeats the colour order five times. Walk around it and relate the visible pattern to array indexing and rotation. The changed height also changes the form's relation to your reach.
7. Combine whole configurations into taller stacks: rainbow plus Bauhaus; Memphis plus rainbow plus beads.

Relevant implementation: `commons/artifacts/chroma_stack/chroma_stack.gd` and `commons/artifacts/color_dna_stack/color_dna_stack.gd`. The code sets these transformations during construction and does not animate them. The three coordinates of a material colour are not a complete account of its appearance; later halls investigate that relation through light, surfaces and displays.

The earlier tutorial's hypothetical perceived() function is archived with the previous draft. It is not an implemented model of the viewer's perception and should not be presented as one.

The prose introduces colour science through a reproducible assignment and the conditions of appearance, while leaving full accounts of light, surface and perception for the following halls. Memories and cultural associations are invited as possibilities, not coded outcomes or universal colour meanings.

## Shared book illustrations — 23 September

The current chapter uses native renders of the four placed opening columns and two views of the fixed rainbow column. The four-rule comparison keeps the same orthographic camera offset relative to each artifact; the source meshes and local transforms match. Existing illumination and backgrounds vary across the hall, so the photographs compare colour assignment in place, not calibrated display colour. The rainbow cameras are 1.65 m above the column base and the object remains fixed between views. No new viewer controls or production geometry were added.

Figures and exact manuscript comparison: `doc/book/iterations/2026-09-23-colour-gathering/`. The focused isolated-museum run checks 24 conditions, including the four assignments and the retained 6.2/7.2/7.4 m heights. Existing 17 September route evidence is historical; no new walking, headset or learner trial is claimed.


## Another order among the same parts — 28 September 2026

The writing now connects Disco's held states to the simultaneous colour assignments standing in this hall. The opening follows the red blocks across the intervening blue sphere, then distinguishes shape, height and neighbour as different inputs to an assignment. The ochre/blue alternation in the neighbour column is held spatially rather than advanced by a clock. No new algorithm, geometry or control is implied.

The builders and map still match the 23 September native evidence. The only difference in the tested studies.json is the rainbow plate's already-authored wording: a source ID was replaced with the table-sized study's 72 cm height. Its parts and configuration are unchanged. The existing four-rule and rainbow figures remain dated views, not new captures or calibrated-colour measurements. The scientific/associative paragraph, all three code excerpts, the taller gallery stacks and the illumination handoff remain unchanged.

Comparison, source audit and current reading: doc/book/iterations/2026-09-28-colour-another-order/.


<!-- study-spine:reference_landscape -->

## Return: A world from a cone

Change the height factor; keep the 48 sites and three cones per tree. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses array, transform, colour. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`landscape`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-five-reference-rooms/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:reference_landscape -->

### One source change: A world from a cone

In build(), reduce the maximum height from 1.85 to 1.25. Leave the seeded tree_sites generation and tier count intact. Random shape variation is supplied at this point in the spine.

```gdscript
var height := lerpf(0.28, 1.25, amount) * random.randf_range(0.65, 1.15)
```

Source: `commons/artifacts/reference_studies/landscape.gd`. Use the prepared scene to run and compare.

### Color_Flashlight

Source: `commons/maps/Color_Flashlight/tutorial.md`

# Move a condition of appearance

Primary encounters: `flashlight_demo`, then `colour_light_rooms`. Read `final.md` for the book voice and `technical.md` for the implementation.

1. Find the boundary of one coloured pool on the board. Identify the lamp responsible by aiming it aside, then back.
2. Leave that lamp aimed at the board. Move another so the pools separate and overlap. Describe the change before naming additive colour.
3. Bring the white lamp into the comparison. If the overlap becomes hard to distinguish, separate the beams again.
4. Aim onto the floor or side cube. Carry the same light across the faceted sphere; compare neighbouring faces before naming their normals. No face has been repainted.
5. After following the light between these receivers, inspect `spot.light_color = light_color` in `flashlight_color.gd`. The assignment stays fixed while position and direction change.
6. Enter the side white room. Keep one corner in view while the central light changes. Compare this fixed lamp/changing value with the handheld lamps' fixed values/changing positions. Approach the pink recess, then move sideways to find its return walls. Its two sources keep their pink value while the surrounding room changes.
7. Enter the taller room and look through the stepped light well. Wait for its light to change, then walk up the ramp and compare the lips from the raised landing. Separate these observations: first change time while holding the viewpoint, then change viewpoint. The room's script does not recolour the museum sky.
8. Carry light-versus-material into Color_Nails, where a colour choice addresses a surface resembling part of a body.

The lamp's grab and orientation are the interaction. Do not instruct the visitor to switch it off, choose a hue, spawn a prism or select a receiving-ground variant: this placement provides none of those controls. Ask what the RGB model can show and what it leaves unrepresented, without treating this renderer as a spectral optics laboratory.

## Making score: a room receives a value

After reading the encounter, return to the supplied `colour_light_rooms` scene. Its `set_phase()` method includes the same kind of assignment used by the handheld lamp:

```gdscript
central_light.light_color = c
```

First give `c` one fixed RGB value, run the scene, then substitute another. Keep the white receiving material and camera position. This reuses the light assignment already introduced in this hall; building all the room geometry is a separate exercise. The luminous reveal has its own material and is not the source that lights the walls.

Then inspect `_process(delta)`: Point Zero's repeating callback advances the phase of a 110-second cycle. Pause the cycle with `running = false` and call `set_phase(0.16)` or `set_phase(0.38)` to compare two moments. Those are authoring changes in the script, not controls installed in the hall. The transferable operations are assigning a light colour, changing it over time, and holding conditions fixed to read a difference.


<!-- study-spine:sphere_in_pink -->

## Return: A sphere in pink

Change one lamp state; compare pink light with a pink surface. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses point, colour. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`pink`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-sphere-in-pink/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:sphere_in_pink -->

### One source change: A sphere in pink

Replace the final set_lights(1) call in _ready(). Mask 3 enables the first two lamps. Bit-mask construction is supplied here; the first task is to compare illumination while the sphere stays fixed.

```gdscript
set_lights(3)
```

Source: `commons/artifacts/spine_studies/pink_sphere.gd`. Use the prepared scene to run and compare.

### Color_Nails

Source: `commons/maps/Color_Nails/tutorial.md`

# A small gesture, a very large nail

1. Approach the manicure table. Compare the giant hand with the petite hand on the cushion before choosing a colour.
2. Grab the point in the NAILS RGB box. Move mainly along one axis. Watch the swatch, then compare the nails at both scales.
3. Repeat at SKIN while keeping the selected nail colour. Look again at the same nails against their changed background; distinguish the fixed assignment from what you perceive.
4. Return to one colour. Trace the coordinate-to-RGB mapping, the GameManager signal and the material albedo assignment.
5. Compare the same selected value on the swatch, the small hand and the giant. Equal channel values do not promise identical viewed appearance.
6. In the museum's standard VR controller setup, raise the controller hand and compare its nails and skin. On desktop, use the two salon displays. Receiver wiring is checked; physical headset reach and wearer experience remain untested.

Primary encounters: nail_color_controller and hand_color_controller. Their shared receiving installation, nail_salon, is secondary. Tiny bottles and the file stage the salon but are not interactive palette tools. Carry a chosen colour toward Rainbow's ordering of colour; this room does not establish an automatic handoff to its bands.

### Color_Rainbow

Source: `commons/maps/Color_Rainbow/tutorial.md`

# A celebration you can re-divide

1. Enter along the level coloured centre path. The welcome patch starts confetti; the left-hand steps are optional.
2. Follow a boundary in the arch. Press RE-DIVIDE on the control plinth and find what changed.
3. Repeat through the four configurations. Compare boundaries, opening, step positions and colour addresses before explaining the list.
4. Inspect the fixed-total-width rule in rainbow.gd. Look for seams in the 48-band version before reading the HSV hue rule behind the mode called continuous.
5. Press CELEBRATE whenever you want another burst. Repetition is available without solving a colour puzzle.
6. Look for a colour chosen in the salon among the bands, banners and mushrooms. Cycle back to the first arrangement. Keep one you like, or ask what additional list or rule would give another colour a place in the arch.

The rainbow is primary. Its arches and mushrooms are scenery; the low steps have collision. Do not instruct visitors to climb the arch, punch a missing MarioCube, adjust an optical spectrum, or wait for animated band colours: the implemented colour change comes from RE-DIVIDE.


## Along the walk

The five small wire cubes in the centre use the familiar pickup body. Walk into one and follow a spark from its bright head along the thinning tail. The tail holds a short history of the spark's positions. The cubes disappear when collected and return on the next hall load. The CELEBRATE button still repeats the separate confetti burst.

Walk beneath the six-stripe banner at the far end. Two poles hold it clear of the path. Leaving cubes behind does not close the route. The banner keeps its colours when RE-DIVIDE changes the arch.

The footnote in final.md records a possible later investigation of colour, boundaries and continuous controls. Those controls are not part of the current artifact.

### Color_Pillar

Source: `commons/maps/Color_Pillar/tutorial.md`

# Three directions through colour

Begin on the near-black floor and look up. X changes hue; Z changes saturation. The ceiling holds value at 1 and meets the pillar tops at 4.6 m. At each pillar centre, its ceiling colour matches the top of that pillar. The ceiling extends beyond the outer samples; the extension clamps to the field edges, so the added width does not stretch the colour coordinates.

Look up the thirty-five columns. Each keeps the hue and saturation of its x/z address, while value rises from 0 at the coloured mesh's bottom (0.46 m) to 1 at its top (4.6 m). A separate zero-saturation column runs from black to white. The main field keeps saturation between 0.25 and 1, so its coloured tops do not turn white merely by reaching value 1.

Pick up the sampling card using the existing grab interaction. Its x/z position samples the horizontal field. A physical hand-height range of 0.65–1.85 m covers value 0–1; the marker and FIELD Y readout show the corresponding position in the taller field. This is an explicit change of scale. At the two limits the value clamps. Beyond the horizontal field it samples the closest edge and displays EDGE. Release leaves the frozen card available where it was placed.

Raise the card without deliberately moving sideways. Compare HSV and RGB: hue and saturation stay fixed, value changes, and the RGB channels scale together. Then carry it across a gap to change hue, or farther along the field to change saturation. At value zero every colour becomes RGB (0,0,0), while the address can retain its hue and saturation coordinates. The display's value is not a promise of equal perceived brightness across hues.

The upright columns, ceiling, marker and sampler use the same unshaded colour calculation. The ceiling is the full-value boundary, the columns are vertical ranges, and the marker is a selected sample. The dark floor is a neutral near-black surface over the existing walkable floor. The zero-saturation reference remains beside the coloured canopy.

Finally take a swatch from the named collection wall. That existing swatch keeps its assigned colour when you move it; the new sampler changes colour as you move it. The two actions now offer a useful comparison: carrying a chosen value, and evaluating a value at a new position. The wall titles are authored associations, not complete representations of the artists or movements they name.

The next hall, Color_Grid_Pallet, lets you write a colour to an address and return to find it there.

### Color_Grid_Pallet

Source: `commons/maps/Color_Grid_Pallet/tutorial.md`

# Find the colour again

1. Read the two-coordinate address on the console. Follow the outlined floor cell.
2. Press X +, then Z +. Notice which direction each changes. Each coordinate wraps through five positions.
3. Press COLOUR to assign an ink. Move away through five X steps and return. The edited colour stays at its address.
4. Walk to the edited square and stand on it. Return to the console and press RULE. The colour returns to the coordinate-based assignment; the same floor still supports you.
5. Press PALETTE. A different collection supplies the same assignment rule.

The selected coordinate maps to an actual room-floor instance. This room does not infer cell coordinates from a square instance count: stacked walls and gaps make that inference unreliable.

```gdscript
colorizer.multimesh.set_instance_color(cells[selected], INKS[ink_index])
```

That write changes one instance. The rule visits all mapped floor cells:

```gdscript
var colour_index: int = (address.x + address.y) % palette.size()
colorizer.multimesh.set_instance_color(cells[address], palette[colour_index])
```

In this Vector2i, y stands for room z. The remainder chooses the palette entry. Equal remainders give different cells the same colour.

Compare the scope of the two actions. You can edit twenty-five addresses; the rule reaches the interior floor. What would need to change to let your exception survive a rule pass?

Follow the current value into Color_Paint, where successive marks can accumulate on a surface.

### Color_Paint

Source: `commons/maps/Color_Paint/tutorial.md`

# Enter an ongoing painting

Watch the automatic can before taking a colour from the two-row tray. Hold a can, aim its nozzle at the canvas and hold the trigger. On desktop, right-click carries or returns the can and holding the left mouse button sprays. Merely picking it up makes no marks.

Try the same colour close to the canvas, then farther away. The closer mark is tighter and denser; the farther mark spreads thinner. Keep the nozzle still to build coverage. Tilt it to stretch the footprint. Release the trigger while keeping the can in your hand, then let go to return it to its dock.

The nozzle ray must hit this canvas without a wall or another object in between. Its range is three metres. The actual surface transform and four-by-two-and-a-half-metre mesh determine UV coordinates and the projected footprint. No coarse grid snap is applied to spray input.

```gdscript
last_radius_m = 0.012 + distance * tan(deg_to_rad(7.0))
```

This rule makes distance visible as the size of a mark. The pigment budget spreads over that area; trigger pressure and time spent in place affect coverage. The current code approximates a spray cone, not aerosol physics.

The automatic painter supplies its position from two oscillations and deposits through the same surface method. Its prescribed motion continues beside your gesture. The canvas stores the resulting image, not a recoverable list of strokes.

Compare that changing surface with a fixed arrangement in the Albers gallery. Continue into Color_Walls with the difference between a colour value, its neighbours and its receiving surface in mind.

### Color_Walls

Source: `commons/maps/Color_Walls/tutorial.md`

# Three ways to pass

Begin with a chair seen through two coloured panes. Step sideways until only one pane covers it. The chair, its position and its material have stayed fixed. Follow the edge to a gap and walk around the pane. A view through a surface does not promise passage through it.

Return to the entrance and press FILTER / OPAQUE. Repeat your route. Inspect `toggle_office_glass()` in `algorithms/color/color_mixing/color_constellation_office.gd`: it changes the surface material and shadow setting, without rebuilding the collider. The twelve panes are positioned by `PANES` in `office_planes.gd`. Each row contains x, z, yaw, width, height and colour. The geometry uses transforms already introduced in Transformation and a repeated construction already introduced in Arrays.

The new decision is how the surface combines with the view behind it. Both states use `BLEND_MODE_MIX`. Filter mode enables alpha transparency with alpha 0.52; opaque mode disables transparency and sets alpha to 1.0. Start with one pane. Change only its colour, then compare the same chair with and without a second pane in front of it. Keep the supplied pale backing so dark surroundings do not obscure the furniture. This operation blends rendered RGB colours; it is not a model of spectral absorption. Transparent surfaces are sorted for rendering, so their order contributes to the result.

For a first alteration, change one row's yaw, rebuild, and find a new overlap by walking. Keep widths and gaps fixed until you have checked which routes remain possible. The furniture, support geometry and comparison button are supplied apparatus; rebuilding them is not the learning target here.

At the navigator, identify the RGB axes. Each displayed sample uses its three channels as coordinates relative to the model centre. Locate the same general colour region in the HSV cylinder. Hue is now an angle, saturation a radius, value a height. Compare up in each model: RGB increases green, while HSV increases value, returning to the vertical rule of the Pillar field. Each model shows 500 samples, not every colour. Inspect the black corner's deliberate brightness adjustment.

At the interpolator, leave the initial red and blue endpoints unchanged and switch RGB / HSV. Describe the middle before reading `_recalculate()` and `_lerp_hsv()` in `algorithms/color/gradient_interpolator/gradient_interpolator.gd`. RGB linearly interpolates channels. HSV chooses the shorter hue arc, then interpolates saturation and value. Use COLOUR A and COLOUR B to choose another pair and repeat.

Carry three distinctions into Pattern_Disco: a material can change a view, coordinates can organise values, and an interpolation rule can choose a path. Keep the floor arrangement while changing its palette, then keep the palette while changing the pattern. Compare what each change makes visible.


<!-- study-spine:colour_assembly -->

## Return: Room to gather

Shift the colour index by one without moving a panel. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses coordinates, transform, array, colour. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`assembly`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-02-gillick-room-to-gather/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-spine:colour_wall_studies -->

## Return: Wall relations

Change the pitch of 24 rails without changing their count. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses line, coordinates, array, colour. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`wall`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-02-gillick-wall-relations/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:colour_assembly -->

### One source change: Room to gather

In colour_for(), replace the initial palette_index assignment with this line. In the alternating colour mode, each numbered panel gets the next colour; its transform stays fixed.

```gdscript
var palette_index := (index + 1) % PALETTE.size()
```

Source: `commons/artifacts/colour_assembly/colour_assembly.gd`. Use the prepared scene to run and compare.

<!-- study-edit:colour_wall_studies -->

### One source change: Wall relations

The installed SPACING control calls this setter. Try 0.18 as a third state inside station.gd’s wall branch. Twenty-four centres retain their order and count.

```gdscript
set_spacing(0.21)
```

Source: `commons/artifacts/colour_wall_studies/colour_wall_studies.gd`. Use the prepared scene to run and compare.

---

## 05. Patterns: Dress the Architecture

### Pattern_Disco

Source: `commons/maps/Pattern_Disco/tutorial.md`

# The same value, another colour

The coloured return follows the eight Colour halls and opens the tiling sequence. Read final.md for the book encounter.

1. Step onto the familiar checker before returning to its console.
2. Hold the floor and stop the sequencer. Follow one square through the four COLOUR choices. The palette changes while the calculated zero/one values and current phase remain fixed.
3. ONE STEP exchanges the checker values; a second step restores them. Compare a changed input to the rule with a changed pair of colours used to display its output.
4. Trace the nested palette lookup. Compare this shared assignment with the earlier palette grid's single-square edit.
5. Leave the palette fixed and compare PATTERN and SPEED. Pattern restarts at phase zero; palette preserves phase. Five modes are available, including SUPER TRIANGLE.
6. Hold a triangle turn between its integer poses and change COLOUR. Follow the same edge through both pairs.
7. Walk with and across a moving band. The supporting floor is unchanged and does not drive the visitor's body.
8. Add notes to the sequencer. Hold the visual clock while musical events continue, then stop the sequencer too for a still comparison. Listen freely; phase agreement is not the task's success condition.

Foundry follows with editable source patterns and architectural receivers. This return does not need another interface: choosing the pair for every matching address is its concrete power and limit.

### Pattern_Foundry

Source: `commons/maps/Pattern_Foundry/tutorial.md`

# From a mark to a receiving body

Pattern_Disco supplied a pattern and a palette. Here the visitor authors a source. Notice the machine output already on the hall, then begin with the two primary tile stations; their previews are separate from that architectural print. Place an asymmetric pair of marks at `pattern_tile_4x4` and locate its repeated appearances. At `pattern_tile_mirror`, compare which copies reverse the pair. Keep source and operation separate.

At `pattern_machine_a`, use the specimen console's MARK button. Observe the same edit on the flat and curved sheets. Their surface dimensions and UV order match; their projected widths do not. Move to another viewpoint before attributing the visible compression to the pattern generator.

The live sampling code in `recipe_study.gd` asks the selected wallpaper rule for a palette index at each pixel. The resulting image goes to both receiver materials. The display begins with CURVE selected. LINK / HOLD makes that receiver decline later images; pressing it again catches up. This is a whole-image exception, not independent editing of one repeated cell.

SAVE, edit, RESTORE tests the separation between a recipe and its momentary presentation. The source card, palette, group and short carpet history return, with the saved animation phase. The loom keeps running afterwards. The specimens show the current rule; the carpet also displays previous bands.

The earlier four-machine comparison is preserved in `doc/space/pattern-recipe-2026-09-10/before/Pattern_Foundry/tutorial.md`. Its proposal to feed one motif into every machine was not an implemented interaction. The wall now supplies an architectural receiver: the same sampling scale extends along 4.8 metres of the existing inner wall. TARGET selects CURVE, WALL, FLAT, ALL FIVE, ARCHITECTURE, NORTH or EAST; LINK / HOLD acts on that scope. A mixed scope becomes live when linked. UNDO LINK can restore a held image after re-linking. MARK, SAVE and RESTORE always address the shared source. The separate DRESS THE ARCHITECTURE controller already supplies whole-hall floor and wall skins from machine output textures. Garment transfer remains separate.

See `technical.md` for the actual recipe boundary and `final.md` for the book encounter.

REPEAT SIZE now cycles 15, 30 and 60 centimetres per source-card span. The motif stays fixed; linked surfaces accept the changed spacing and held surfaces retain their earlier image and value. SAVE/RESTORE includes source spacing. The historical carpet keeps its own display spacing. ARCHITECTURE now groups WALL, NORTH and EAST: three existing inner-wall faces, with independent hold and group undo. OFFSET +5CM now advances surface sampling from 0 to 30 cm, with saved source state and independent held receivers. Next: an explicit held-hand input for this bounded offset.

For the first visit, continue from the held curve into the curved room in the annex. The room begins with both wall and floor linked to the studio, and ROOM selected on its surface console. Choose a palette colour and paint one studio cell, then follow it across the room. Select ROOM FLOOR, HOLD, and edit the source again. The floor retains its visible print while the curved wall follows. APPLY LIVE catches the floor up; UNDO LINK can recover its earlier held image. Entering, moving inside and leaving use the existing opening and museum floor. WALL alone names the older low wall beside the loom, so reserve source takeover of that receiver for a return visit.

The native check must compare the visible floor, not only its stored texture. A raised hall-wide print previously hid the local floor despite successful source updates. The architectural skins now account for the console's height; the local room print lies above them without changing physical support.

### Tutorial_Pattern

Source: `commons/maps/Tutorial_Pattern/tutorial.md`

# One source, two rules

Begin at the Pattern Maker in the side bay. Find the red bend in the sixteen source cells, then follow it across the two panels. What stays the same? What changes its facing?

1. Press PM, then P1. Inspect the floor and source after each press. The reference panels keep their rules.
2. Press FLIP X. This time watch the source cells. Press it again to return.
3. Follow the blue corner through four ROTATE presses.
4. Choose a paint colour, then press a source cell. Find its copies in both fields.
5. Use UNDO to reverse an operation. RESET returns the starting motif and P1 floor; UNDO can reverse that reset too.

Make the floor-rule comparison and the source reflection visible before explaining either address operation. The shader splits a position into a tile index and a local address. Translation keeps that address. This reflection rule reverses x on alternate columns. The source-reflection button instead rebuilds each source row in reverse order. The technical chapter contains the corresponding implementation excerpts.

Each displayed tile spans 40 cm, whether on a panel or the floor. A reflected pair spans two tile columns. Make a source symmetrical enough to conceal a reversal, then break its symmetry with one mark and compare again.

Array_Patterns next asks how these repeated relations meet an environment. Headset and continuous gesture work remain deferred; these controls also accept the desktop pointer.

### Array_Patterns

Source: `commons/maps/Array_Patterns/tutorial.md`

# Follow an address

1. Find the marked floor cell and compare its `[row,column]` with the source address on the side console.
2. Press COL + four times. The surface column advances; the source column returns. Try ROW +.
3. Press FACE. Inspect the right wall and work out which way its rows and columns run.
4. Change CELL SIZE from 40cm to 60cm. The motif still has four cells across, but its physical span changes from 1.6m to 2.4m.
5. Press GRID and walk through the tunnel. Hiding drawn divisions leaves supports and collision unchanged. Use UNDO to return.
6. Inspect the corner and a cut boundary cell. Compare with the staggered rows at pattern_tile_brick.

Each face starts its own UV grid. The inspector selects complete cells only. The source is fixed for this encounter; the preceding room supplies editing. Headset and continuous gestures remain deferred.

### Symmetry_Seventeen

Source: `commons/maps/Symmetry_Seventeen/tutorial.md`

# One mark, three rules

Start with the implemented comparison in `final.md`: P1, PM, PG, HOLD, source paint and UNDO. This placement uses `#lesson:symmetry_compare`; other tile editors retain their existing controls.

The source is a 4 by 4 palette-index array. `WallpaperGroups.get_symmetric_color` reads this array using a selected rule. P1 wraps source coordinates. PM reverses x in odd source blocks. PG also shifts the source row by two, wrapping at four. `VRTileEditor._update_carpet_texture` samples 32 by 32 pixels. The live wall panel and carpet share that image; HOLD copies its pixels into a separate texture.

The console offers 16 source addresses, four paint colours, three rules, HOLD, UNDO and RESET. Undo retains up to 32 changes including the held sample. Reset restores the initial source and P1, keeping the held sample. No headset buttons or keyboard navigation are required by this lesson. The nested legacy cube editor is hidden and suspended here to avoid competing edits.

A source block is not always the translation unit cell. PM and PG reverse every other x block; the x translation period generally spans two blocks. A symmetric source can add symmetries beyond those supplied by the selected construction. Classification concerns the symmetry of the resulting whole field, not merely its selected button.

Only the three selected renderers are checked in this lesson. The other exhibits remain available as supporting material; their full set of numerical wallpaper renderers has not been certified by this comparison. The cage supplies a diagram of the crystallographic restriction. Neither counting enum values nor reading that diagram proves the seventeen-group theorem.

Continue to Ribbon_Patterns_01, then the other ribbon halls before Change. Headset reach and gesture work remain deferred.

### Ribbon_Patterns_01

Source: `commons/maps/Ribbon_Patterns_01/tutorial.md`

**Missing tutorial.md — no substitute text added.**

### Ribbon_Patterns_02

Source: `commons/maps/Ribbon_Patterns_02/tutorial.md`

**Missing tutorial.md — no substitute text added.**

### Ribbon_Patterns_03

Source: `commons/maps/Ribbon_Patterns_03/tutorial.md`

**Missing tutorial.md — no substitute text added.**

---

## 06. Change: Rate, Accumulation, and Flow

### Change_Intro

Source: `commons/maps/Change_Intro/tutorial.md`

# Three experiments

# Two samples before the tangent

This room carries the position/address reasoning of Ribbon_Patterns_03 into a rate with respect to position. Its independent variable is x, not elapsed time. It prepares for the accumulation workbench later in this same hall.

The primary is `tangent_slope_workbench`, with the map-only `comparison:true` adapter in `rate_comparison.gd`. The existing slider and five buttons share a widened console. The base workbench retains its single smooth function and analytic derivative:

```gdscript
static func _f(x: float) -> float:
    return 0.5 + 0.4 * sin(2.0 * x) + 0.15 * cos(5.0 * x)

static func _df(x: float) -> float:
    return 0.8 * cos(2.0 * x) - 0.75 * sin(5.0 * x)
```

At first the tangent, derivative subplot and sign indicator are hidden. A second green point and the segment joining it to the red sample show a finite difference. STEP cycles h through 0.5, 0.25, 0.125 and 0.0625; near x=5, h is negated to keep the other sample inside the domain. The readout displays the actual signed interval.

```gdscript
var rise = bench._f(x + h) - bench._f(x)
var rate = rise / h
```

At initial x=1, the h=0.5 estimate is about -0.5956, while the analytic derivative is about +0.3863. At h=0.0625 the estimate is about +0.2971. The wider interval crosses a crest. This gives the learner a concrete disagreement to investigate before DERIVATIVE reveals the analytic tangent and plot.

The slider selects x continuously; x - and x + change it by 0.125 with endpoint clamping. RESET restores x=1, h=0.5 and the hidden analytic comparison. DERIVATIVE toggles the comparison without changing either function. Source curve vertices remain fixed; only sample markers, tangent, secant and readouts change.

The rendered polyline uses 200 intervals. The two sample values and derivative are evaluated from the formula, not estimated from those rendered vertices. The plotted axes have different drawing scales; the numeric derivative is df/dx in model coordinates. The sign indicator's magnitude threshold (0.05) is labelled near zero, not an extremum detector. Four finite sample intervals are not a numerical proof of a limit or an assertion that smaller always means more accurate.

The comparison adapter is opt-in. Other placements retain the existing slider/tangent interface. This does not connect the displayed slope to the player's walking physics. Headset legibility, tracked-hand slider use and comfort remain to be checked.


# Accumulation: one height represents an interval

Continue to the second bay with the same function, `0.5 + 0.4*sin(2*x) + 0.15*cos(5*x)`, on [0,5]. The earlier bench compared local rates; this bench adds height-times-width contributions. Its axis is position, not elapsed time.

1. Begin with four midpoint rectangles. Use CELL +/- to follow the selected sample and read its height, width and contribution.
2. HOLD the current picture and total. RULE cycles MID, RIGHT, LEFT. Compare equal counts before changing resolution.
3. Return to MID and move the existing count slider through 4, 8, 16, 32, 64, 128. The held panel remains unchanged until another HOLD or RESET.
4. Reveal REFERENCE after predicting which total is closer. It is a separate 4096-midpoint computation. Toggle it off to recover the contribution readout.
5. RESET restores four midpoint rectangles, hides the reference and clears the held comparison.

The calculation is `width=(b-a)/n`, `x=a+(i+fraction)*width`, `total+=f(x)*width`. The sample fractions are 0, 0.5 and 1. Selected samples, rectangle heights and total all use the same rule. The curve drawing stays fixed at 200 intervals. Held geometry copies vertex arrays so later live rebuilds cannot alter it.

At N=4, MID is about 2.23665, RIGHT about 3.26367 and LEFT about 3.53733. The reference is about 2.86384. RIGHT is closer than MID here, disproving the old claim that midpoint always wins. For this smooth function, fine partitions converge toward the integral; six finite slider stops are an experiment, not the limit itself.

The difference bar saturates at 0.05. Its numeric readout retains the signed difference. The function is positive throughout this encounter; signed cancellation and total distance are later experiments, not demonstrations already present here. The rectangles are a mounted plot, not walkable steps.

The third bay is the ftc_bridge. Compare its signed derivative contributions with its endpoint height difference. Its arch is a different function from the two workbenches. Flow_Field follows this encounter, introducing trajectories whose sampling addresses depend on prior movement.


The ftc_bridge uses evidence:longhand with reveal_on_request:true. The arch and signed derivative strips remain visible; COMPARE TOTALS reveals or hides the endpoint height readings, difference marker and 512-interval trapezoid comparison. Other placements retain their configured evidence behavior unless they opt into this reveal. Keep its different source function explicit. The consolidated final.md supplies the traversal order and transitions.

## Operating details retained beside the reading — 24 September 2026

The revised final.md keeps the finite-difference and Riemann-sum sketches and the bridge's trapezoid loop. The full analytic function and derivative remain above; the gold tangent uses that calculation rather than extrapolating the four STEP settings. Pressing DERIVATIVE again hides the comparison. RESET returns the opening wide interval and sample. A hypothetical sharp corner is not part of the smooth function currently offered.

The bridge's signed-rate sum uses 512 intervals; its source curve is a symmetric arch distinct from the two workbenches. Adding magnitudes would be a separate quantity from the signed sum. A net height change is not a complete account of effort, path length or accumulated absolute height change. The rate uses horizontal position; the pulse's animation does not turn that independent variable into time.

The manuscript no longer interrupts the encounter with every display threshold, slider count or stored decimal. Those values remain in this companion: four finite-difference intervals, six rectangle counts, the 200-interval drawn curve, the 0.05 sign/difference-bar thresholds, and the finite 4,096-sample reference. The reference is not an exact integral. Its midpoint estimates include N=8 at about 2.88669, compared with N=4 at about 2.23665 and the reference at about 2.86384.

### Further encounter, not a current capability

A measured visitor-velocity arrow or a slope-responsive walking body could turn these comparisons into locomotion. The present plots do not implement that connection. Keep the question of which rate a body needs, while testing such an encounter before writing it as an accomplished walk. Existing secondary artifacts remain available for that development.

Full previous prose, including all former operating passages: [before this revision](../../../doc/book/iterations/2026-09-24-change-reading/before/commons/maps/Change_Intro/final.md).

### Flow_Field

Source: `commons/maps/Flow_Field/tutorial.md`

# Shared field experiment

The primary `flow_field_painter` is a 4.8 × 3.2 metre wall monitor in the first bay, with separate waist-height controls. Its opt-in `shared_field` lesson uses 80 particles and seed 43, and starts with field evolution held. The `wall_monitor` display moves the canvas, trails and arrows together: the local XZ drawing plane becomes vertical, with the second canvas coordinate running down the screen. Sampling and particle updates still use the same local two-dimensional positions.

## Two clocks and one sampler

ARROWS reveals 24 glyphs. Both glyphs and particle updates call `field_direction`. Arrow geometry refreshes at 10 Hz; particles update every rendered frame. A nearby arrow samples its own address and has its own refresh schedule: it is a representation of the field, not the source steering the particle.

FIELD TIME toggles only the field clock, holding its current time on pause. Particles continue. In lesson mode SCALE affects the noise frequency once; legacy instances retain their existing sampling behaviour. Existing SCALE and SPEED controls remain.

The field takes a noise value, turns it into an angle and constructs a unit direction with cosine and sine. It does not calculate the gradient of the noise. The two short code blocks in final.md are teaching sketches of the angle conversion and the position update, with the coordinate mapping and renderer omitted.

## What the controls retain

RESET scatters new particle positions and clears their trails without selecting a new seed. SEED changes the seed and resets those particles. Neither rewinds every clock. Changes to speed or scale leave existing trail positions present until new samples replace them; they therefore temporarily show the history of more than one setting.

The fixed sample capacity limits each trail's memory; it is not a fixed duration. Increasing speed changes the distance travelled between samples at a given update interval. Different display timing can change the sampling and numerical trajectory. Finite updates hold a sampled direction for a whole step before looking up another.

## The return seam

Opposite edges wrap the particle coordinates. The renderer joins consecutive stored positions, including across a wrap, so a long visible segment can cross an interior the particle did not traverse. The noise itself is not periodic: wrapping position does not ensure that directions agree at opposite edges.

## Which body this makes

This is prescribed motion through a direction field, not a force, gradient or fluid model. The update stores no inertial velocity, mass or particle-to-particle collision negotiation. Neighbours can change the aggregate picture without changing one another's movement. The standalone `vector_field_visualizer`, `vector_field_grid` and other supporting artifacts are independent examples; their arrows do not steer this painter.

The revised final.md follows a single particle, the held field, a changing field, and the edge's return before introducing the missing interaction. An immersive field affecting the visitor would require a separate receiver and a verified movement connection. That remains development material, not a capability added by this prose pass.

Full previous prose: [before the reading revision](../../../doc/book/iterations/2026-09-24-change-reading/before/commons/maps/Flow_Field/final.md). The wall display and control placement were updated on 4 October 2026; its museum captures and desktop checks are recorded in [the wall-monitor review](../../../doc/book/iterations/2026-10-04-flow-wall-monitor/index.html). Headset testing remains separate.

---

## 07. Vectors & Forces: From Direction to Dynamics

### Vectors_Act1_WhatAVectorIs

Source: `commons/maps/Vectors_Act1_WhatAVectorIs/tutorial.md`

# One displacement, two wall projections

The opt-in `lesson:room_reading` layer on VectorBasics starts with its input arrow and hides the legacy decomposition displays. A floor console offers SHORT, LONG, SHIFT, ZERO and PARTS. The input arrow is brought forward above the console. The projection screen occupies a cleared side bay; former interior grid columns in that footprint have been removed.

Both projections read `end.global_position - start.global_position`. SHORT selects magnitude 0.25 m and LONG selects 1 m. They retain direction above magnitude 0.0001; at or below that threshold they supply normalised (1,1,1). This preset threshold differs from the normalisation companion's 0.001 threshold. SHIFT alternates a common 0.2 m translation of both pins along the console axis. ZERO makes them coincide. PARTS reveals world components and two component-leg drawings. This is a description of displacement, not a force controller.

The wall's XY and XZ diagrams use 0.85 display metres per world metre. Each projection is limited to radius 1.05 display metres. The clipping label names that bound; the numeric displacement is unchanged. The adapter samples at 20 Hz and rebuilds only after a measured vector or reveal-state change. Body, world and drawing coordinates are kept explicit. Existing VectorBasics placements without the lesson metadata retain their interface.

The companion vector_normalize_demo uses a 0.001 magnitude threshold. Its numeric readout uses the computed unit.length(), including 0.000 for the zero result. Its drawn unit sphere belongs to the illustration's scale, not the world-metre scale of the first wall.

Before expanding this into bodily locomotion, introduce velocity state, acceleration and integration. The existing force_pad assigns launch velocity; force_field_zone adjusts velocity over time. They require distinct adapters and distinct comparisons.

## Reading and retained detail

The canonical [chapter](final.md) follows the encounter. Exact scales, control steps, timing and implementation qualifications remain here. The complete [pre-pass chapter](../../../doc/book/iterations/2026-09-24-forces-relations/before/commons/maps/Vectors_Act1_WhatAVectorIs/final.md) is retained for comparison.

### VFM_02_Operations

Source: `commons/maps/VFM_02_Operations/tutorial.md`

# Two contributions, one destination

Primary: `adder_board`, opt-in `lesson:room_sum`. Start with GO; then SWAP and GO. Predict the endpoint before revealing RULE. Compare PATH via A with direct. CANCEL makes B = -A; compare nonzero out-and-back distance with zero resultant.

Controls use real push_button pointer events: A/B selects input; X-/X+/F-/F+ change components by 0.5 m within [-1,1]. PATH switches route, SWAP exchanges inputs, CANCEL opposes them, GO homes and runs, RULE toggles arithmetic. There are no draggable pins in this room variant. The ordinary board retains its original interface in other placements.

`result = a + b` drives both wall and floor. Vector2 stores (local X, local forward) in metres; floor placement is Vector3(v.x, height, -v.y). Wall plotting uses 0.48 display metres per input metre. Both operands and all sums fit the chart; no projection component or result is clipped. Carriage speed is prescribed at 0.8 m/s. Waypoint traversal consumes leftover time across corners; movement is updated in the physics callback. The guarded AnimatableBody is not a force experiment or a player transport platform.

GO instantly resets position and travelled distance. Input/path changes stop and reset the trip; input selection and RULE do not stop it. The old 26 supporting instruments remain in their original relative arrangement, shifted ten source rows behind this arena. The next sequence hall remains Vectors_Act2_VectorArithmetic.

## From the floor plan into the scene

The carriage's coordinate conversion is:

```gdscript
return Vector3(v.x, height, -v.y)
```

The second plan component becomes local negative Z; height is supplied separately. The wall's upward diagram axis denotes forward movement on the stage, not a climb. Starting values A=(1,0), B=(0,1) give route length 2 m and direct length sqrt(2) m. The travelled counter starts again after GO's instantaneous homing; it does not include the reset movement.

## Reading and retained detail

The canonical [chapter](final.md) follows the encounter. Exact scales, control steps, timing and implementation qualifications remain here. The complete [pre-pass chapter](../../../doc/book/iterations/2026-09-24-forces-relations/before/commons/maps/VFM_02_Operations/final.md) is retained for comparison.

### Vectors_Act2_VectorArithmetic

Source: `commons/maps/Vectors_Act2_VectorArithmetic/tutorial.md`

# One gap, two stations

Keep five existing primary tokens in order: vector_add, vector_sub, dot_aligner, projection_shadow, torque_crank. All twelve artifacts remain. The new work upgrades vector_sub and projection_shadow through opt-in room_gap and room_projection configurations; other placements keep their original consoles.

Subtraction: A/B selects an address, X-/X+/F-/F+ change a component by 0.5 coordinate metres, SWAP reverses A-B, SHIFT translates both by 0.5 along X and reverses on next accepted press, SAME copies A to B, RESET restores A=(1,.5), B=(-.5,0), RULE reveals arithmetic. Components are bounded to [-1.5,1.5]; common moves are refused atomically at the boundary.

Projection: binds to the gap source inside the same museum segment. TURN rotates a unit rail 30 degrees, SLIDE moves source A perpendicular to that rail by 0.5 metres (alternating sign), FLIP reverses rail orientation, RESET restores both source inputs and rail, RULE reveals arithmetic. The actual shared gap feeds kept=axis*gap.dot(axis), remainder=gap-kept. One coordinate metre is displayed as half a metre on both stages and walls. This is a diagram scale, not player/world position measurement. Values are live while the hall is loaded, not a saved cross-session state.

Test sequence: swap; common translation; coincidence; perpendicular slide; rail turn; sign reversal. Predict first, reveal second. Keep the input fixed while changing the receiver, then change the input in a direction the receiver cannot record. The closed loop is kept+remainder=gap. Zero gaps remain finite; the rail is never a zero direction.

Existing dot and torque consoles are distinct examples, not subscribers to this pair. Dot uses an alignment slider and a chosen threshold; torque uses normalized directions and a displayed wheel angle. Its readout reports sin(theta), the chosen angle and a static wheel pose. The unit-direction cross product sets that pose; it does not integrate angular velocity or report rpm. The final chapter now identifies those limits instead of claiming free aiming, continuous physical wheel motion or a newly simulated force.

Next on the unchanged route: VFM_05_Launch. Motion-before-Launch remains an editorial proposal.

The remaining dot console uses normalized directions and FRIEND at dot >= 0.985. Its ordinary slider spans a limited range; the full signed range of a dot product is mathematical context, not a claim that this control reaches every angle. The crank computes r_dir.cross(f_dir) from unit directions. Actual torque would include arm length and force magnitude; the displayed angular factor alone is not physical torque. Projection recombination and perpendicularity hold to ordinary floating-point precision.

## Reading and retained detail

The canonical [chapter](final.md) follows the encounter. Exact scales, control steps, timing and implementation qualifications remain here. The complete [pre-pass chapter](../../../doc/book/iterations/2026-09-24-forces-relations/before/commons/maps/Vectors_Act2_VectorArithmetic/final.md) is retained for comparison.

### VFM_05_Launch

Source: `commons/maps/VFM_05_Launch/tutorial.md`

# Control a flight from inside its diagram

Primary launch_arc uses lesson:launch_chamber at source cell (17,7), yaw 180, floor placement without a plinth. All 17 artifact identities remain; the 16 supporting instruments keep their relative configuration shifted 14 rows behind the new arrival chamber. Footprint 34x38. gate_depth_rows=0 prevents an extra entrance partition from cutting through the flight lanes.

The visitor stands between two control banks, with analytic flight lanes at local Z=-3 and +3. Launches start at X=-5, Y=.3; landing is the same centre height. Local positions use metre scale. No collider, rigid-body force or player-velocity command belongs to the flight markers.

ANGLE-/ANGLE+ choose 15..75 degrees in five-degree steps. SPEED cycles 10→6→8→10 m/s. PAIR adds 90-angle at the same speed. GRAVITY toggles 10/15 m/s². These controls reset the current flight. FIRE restarts playback; SLOW toggles local elapsed-time speed 1/.25, and PATH/PARTS/RULE toggle representations without resetting flight.

Position is origin+v0*t+Vector3.DOWN*.5*gravity*t*t. Each lane clamps its own t at 2*v0.y/gravity. Landing freezes the pre-impact state, without collision resolution. Uniform gravity, equal endpoint heights and absent drag are explicit assumptions. Velocity arrows use 0.2 display m per m/s; acceleration arrows 0.1 display m per m/s². PATH draws 64 equal-time straight segments per trajectory; live markers are evaluated analytically at render time. Dynamic arrows reuse at most eight rigs during playback.

Discovery: launch before showing the prediction; compare complementary angles; observe different landing times; inspect zero vertical velocity at apex with continuing acceleration; vary one parameter at a time. Keep computed diagrams distinct from the other room's force pads and player-launch mechanisms.

Next on the unchanged route: VFM_03_Motion.

## Reading and retained detail

The canonical [chapter](final.md) follows the encounter. Exact control steps, arrow scales, timing, bounded histories and reset rules remain here. The complete [pre-pass chapter](../../../doc/book/iterations/2026-09-24-launch-and-motion/before/commons/maps/VFM_05_Launch/final.md) is retained for comparison. This reading pass does not claim a new runtime or headset test.

### VFM_03_Motion

Source: `commons/maps/VFM_03_Motion/tutorial.md`

# Motion: a command meets a stored velocity

The two primary encounters are `VectorMotion` (this map's `motion_chamber` variant), then `friction_ramp`. Begin with the observable comparisons in final.md; use this page to inspect the mechanisms afterward.

## The chamber

Stand between the control banks. PUSH X and PUSH F each request a 2 N force for one second, in local +X or local -Z. A new push replaces the previous command and restarts its duration. COAST cancels commanded force and braking while preserving velocity. BRAKE applies force opposite the current velocity, capped at 2 N; a smaller final step avoids deliberately accelerating past rest. RESET clears position, velocity, local clock and history. MASS cycles 1/2/4 kg and resets the run. Neither reset changes the selected damping or reveal switches.

A `RigidBody3D` integrates motion. There is no manual position update during ordinary motion. Force is converted from the chamber frame to the world frame:

```gdscript
body.apply_central_force(global_basis * local_force)
```

For a constant force away from contacts, the useful prediction is delta_v = force / mass * duration. At 1 kg the full 2 N pulse gives about 2 m/s; at 2 kg about 1 m/s. PUSH F after PUSH X adds a perpendicular velocity component. It does not erase the earlier one.

The body has zero gravity, explicit replacement damping, locked height and rotation, no sleeping and continuous collision detection. DRAG toggles linear damping between 0 and 0.8. COAST does not disable damping. The cube and four static boundaries share only collision bit 19; the visitor and furniture are excluded. Boundary materials produce an elastic reflection under the tested desktop solver. This is a selected horizontal collision world, not the museum's complete contact world.

PARTS reveals three reused arrow rigs: velocity (0.35 m per m/s), measured acceleration (0.2 m per m/s squared), commanded force (0.3 m per N). All cap at 2.5 m. Measured acceleration is the change in solver velocity divided by the physics interval. It can include contacts and damping absent from commanded force. The readout updates at 10 Hz, so brief contact peaks are not a complete force record.

TRAIL displays at most 120 position samples at nominally 10 Hz. It records even while hidden and discards the oldest sample when full. The geometry rebuilds only on sampling; arrow nodes are reused. The running time belongs to this resettable experiment, not the engine's total lifetime.

## The smaller friction ramp

At 30 degrees, vary the coefficient mu; then hold mu fixed and vary angle. Reset between comparisons of descent. The custom scalar model tests:

```gdscript
_is_sliding = sin(angle_rad) > friction_mu * cos(angle_rad)
```

When sliding, acceleration is `G * (sin(angle_rad) - friction_mu * cos(angle_rad))`. Velocity accumulates acceleration times delta. Displayed travel accumulates velocity times delta times 0.01, and reaching the end resets the block. The STATIC branch immediately sets velocity to zero. One coefficient serves the model's starting and sliding conditions. Do not treat that discontinuous reset as the large chamber's braking response or the display distance as an unscaled physical measurement.

The map opts into a physical stand via `#table:1`. Its placement offset is 0.1 m above the museum's 1 m support; the panel is at world height 1.06 m. Other ramp placements are unchanged.

## Red thread and evidence

Launch calculated a complete flight from its initial conditions. Motion keeps a current state for the next intervention. `Vectors_Act3_FieldsAndMotion` follows: inspect whether its spatial instructions prescribe velocity or change it through acceleration before calling them forces.

34 desktop checks pass in `commons/testing/probe_motion_chamber.gd`: real pointer presses, pulse/mass/coast/brake/drag/contact response, bounded history, stable arrow allocation, sampled approaches, control heights, ramp threshold and legacy compact scene. Headset reach, comfort and performance remain untested. All 17 source artifact identities remain; two are primary.

## Reading and retained detail

The canonical [chapter](final.md) follows the encounter. Exact control steps, arrow scales, timing, bounded histories and reset rules remain here. The complete [pre-pass chapter](../../../doc/book/iterations/2026-09-24-launch-and-motion/before/commons/maps/VFM_03_Motion/final.md) is retained for comparison. This reading pass does not claim a new runtime or headset test.

### Vectors_Act3_FieldsAndMotion

Source: `commons/maps/Vectors_Act3_FieldsAndMotion/tutorial.md`

# One field, two receiver rules

This follows VFM_03_Motion, where finite force pulses changed a rigid body's stored velocity. It prepares Vectors_Act4a_KineticForces, where named forces must be connected to particular bodies and units.

The sole book primary is VectorFieldFlow, opting into `field_receivers` in this map. Its ordinary compact scene remains available in other placements. VectorMotion and the other eleven supporting artifacts remain placed.

## Compare before explaining

Start in SINK at gain 1, positive sign. RUN for about four model seconds. Cyan approaches the centre without crossing; pink crosses and starts returning later. Reveal TRAILS, then ARROWS and RULE. Pause with RUN. RESET clears both states and histories and pauses, retaining parameters and reveals.

FIELD cycles SINK, SWIRL, UNIFORM. REVERSE flips sign. GAIN cycles 1 -> 1.5 -> 0.5 -> 1. Parameter edits preserve state, making a reversed influence different from a velocity reset. RESET between controlled comparisons.

## Spatial rule

SINK returns `Vector3(-p.x, 0, -p.z) * 0.35`; SWIRL returns `Vector3(-p.z, 0, p.x) * 0.35`; UNIFORM returns `Vector3.RIGHT * 0.8`. The base value is capped at length 2 before gain and sign. These are dimensionless samples in this apparatus. The floor shows 63 samples through two MultiMeshes, with 0.4 m of arrow per field unit. Samples are rebuilt only when parameters change. Hiding arrows does not change the model.

## Receiving the sample

Cyan sets `velocities[i] = sample`, using a conversion of 1 m/s per field unit. Pink adds `velocities[i] += sample * STEP`, using 1 m/s squared per field unit. Both then perform `positions[i] += velocities[i] * STEP`. Each samples at its own position, so their inputs diverge after their positions diverge.

This is an explicit numerical, collision-free comparison. Pink uses a semi-implicit Euler acceleration update; it is not a RigidBody3D and has no mass or applied force. In the previous hall the physics engine integrated a real rigid body. Here the two update rules are deliberately exposed side by side.

The fixed model step is 1/120 s. A call advances at most 0.25 model seconds; longer stalls discard excess wall time. At the frame limits |X| >= 5 or |Z| >= 4 a receiver freezes just beyond the threshold, keeping its outgoing velocity. This is an observation cutoff, not a collision. Both exiting pauses the run.

Markers are displayed at heights 1.45 and 1.9 m, but use identical planar coordinates and initial position (-2, -2). Their history buffers keep at most 240 positions, sampled every 12 steps. The same positions draw a floor-space path and a wall plan with X scaled by 0.5 and Z by 0.28. Different projection scales mean wall lengths and angles cannot be read as metre-scale geometry. Controls stand at 1.04 m; routes to either side remain open.

## Relation to the old scene

The preserved compact VectorFieldFlow blends previous velocity toward a sample with `lerp(sample, 0.35)` and multiplies by 0.985 each rendered update. It retains velocity state and is neither the new direct velocity assignment nor the new acceleration integrator. Its coefficients are per frame. The old chapter's memoryless claim was inaccurate. Its manuscript is backed up with the room's before state.

39 desktop checks cover the pointer controls, sink overshoot, uniform quantitative predictions, reversal, parameter cycles, pause/reset, timestep partition agreement, history limits, exit convention, stable geometry, sampled approaches, control height and legacy scene creation. Headset reach, comfort and sustained performance remain open.

## Reading and retained detail

The canonical [chapter](final.md) follows approach, overshoot, reversal and the observation boundary. The opening trail comparison concerns overlaid return travel: pink's extent beyond the centre can show that it crossed, while a static line does not by itself show timing, repeated visits or current direction. The exact integration, history, arrow sampling, gain cycle and exit conventions remain above. The complete [pre-pass chapter](../../../doc/book/iterations/2026-09-24-field-and-receiver/before/commons/maps/Vectors_Act3_FieldsAndMotion/final.md) is retained for comparison. This reading pass adds no runtime or headset result.

### Vectors_Act4a_KineticForces

Source: `commons/maps/Vectors_Act4a_KineticForces/tutorial.md`

# Kinetic forces: inspect the receiver

This hall follows the field receiver comparison and precedes Vectors_Act4b_Oscillation. Book primary order: drag_corridor, force_mower, centrifuge_ring. All eight source artifacts remain.

## Physical drag

The map opts drag_corridor into kinetic_drag. Three RigidBody3D probes start at local X=-4 with velocity 4 m/s along +X. Each holds a fixed coefficient b: 0.4, 1.3, 3.2 kg/s. The applied force is -b times world velocity. Default mass is 1 kg; MASS cycles 1/2/4 and resets the bodies to a held state. FIRE restarts. Linear and angular damping are explicitly replaced by zero, gravity is zero, rotation is locked and the local scene is at unit scale with no yaw. The observation freezes a probe after X reaches +4, retaining its outgoing state. There is no collision response at that cutoff.

Away from the cutoff the continuous prediction is v(t)=v0 exp(-b t/m). The discrete engine response is checked against this with a numerical tolerance. The coefficient is a chosen model value, not a measured fluid property. Pink force arrows reuse three rigs, drawn at 0.12 m/N. Readouts update at 10 Hz. The force calculation continues each physics update.

WALK starts off. In the central strip |X|<=1.35, Z from -4.5 to +4.5 and local Y between -0.2 and 2.3, it returns a locomotion multiplier 1/(1+b_numeric), where b_numeric is the numeric coefficient in kg/s. This is an explicit illustrative mapping, equivalent to normalising b by 1 kg/s, not another integration of the probe's force.

The ordinary endless-museum desktop path applies that factor to horizontal velocity after input/feel computes it and before move_and_slide. It leaves vertical velocity untouched. The XR adapter runs at order 90 after direct movement requests and scales ground_control_velocity. It respects exclusive movement. Because XRTools caches its providers at ready, the body-owned adapter is inserted once into the cached list when this opted-in room finds an XR body; newly added XR bodies are handled too. It remains a no-op when no enabled medium contains the body. Tracked physical walking is not damped. Headset comfort is untested.

## Signed mower work

The mower remains a constrained pickable prop. Its path counter sums displacement lengths. Signed nominal work now sums nominal_force.dot(displacement), with the drawn F_MAG=0.95 N force aligned to current mower orientation and configured angle. A forward-and-back traversal with fixed orientation cancels nominal work but adds two legs of path. A sideways move contributes zero nominal work. This is not measured hand effort or a physical energy budget. Grass cutting remains a proximity operation and is not undone by returning. The initial placement is excluded from the ledger by seeding the first measured position on the first process update.

## Prescribed circle

The ring's actual angular speed now equals its displayed linear speed divided by radius. The prior two unrelated speed mappings disagreed. This map adds a SPEED button cycling 2/4/6 m/s at radius 3.4 m. An angular phase accumulates independently, so speed edits preserve position on the circle. The button rebuild is deferred until after its press event completes. Two arrows are built on parameter changes and transformed with the pod each frame, avoiding repeated mesh creation. Velocity uses 0.18 m per m/s; required centripetal acceleration uses 0.10 m per m/s squared. The inward arrow is an acceleration, not a mass-specific applied force.

## Verification

The desktop probe exercises actual physics decay, mass response, live pointer controls, the ordinary desktop movement path, XRTools adapter registration and stick-request transformation without hardware, exclusive movement, signed mower work, ring speed/phase, clear corridor samples and control reach. This is not a headset playtest. See the illustrated guide and machine-readable check report for the final count.

### Vectors_Act4b_Oscillation

Source: `commons/maps/Vectors_Act4b_Oscillation/tutorial.md`

# Restoring Forces and Balance

This hall builds on accumulated velocity in Motion and linear drag in Kinetic Forces. Its one primary, spring_tower with lesson:restoring_forces, uses a horizontal spring-damper variant. The legacy tower remains a prescribed cosine animation elsewhere. The later Wavefunctions chapter develops rhythm, records, phase and sound.

## State and update

restoring_forces.gd stores scalar displacement x in metres, velocity v in m/s, mass m in kg and stiffness k in N/m. It integrates F = -kx - cv with semi-implicit Euler: velocity first, then position using the new velocity. A 1/120 s accumulator produces identical results for 30/60 Hz frame partitions. Each external update caps catch-up at 0.25 seconds. The frozen XRToolsPickable is the model's view and input handle, not an independently simulated rigid body.

Default x=1.25, v=0, m=2, k=8, damping ratio zero, initially held. A horizontal rail assumes support: gravity, contact friction and collision forces are absent. Equilibrium is x=0. The drawn coil stretches between x=-3.2 and the cube; its geometry is illustrative and is not a soft-body solver.

Damping coefficient c=2*zeta*sqrt(k*m), in kg/s. Ratios are 0, 0.25, 1 and 2.5. Critical/overdamped non-crossing comparisons use release from rest in this linear undriven model. Parameter changes retain x and v. Changing m/k can alter calculated energy; changing either recalculates c to retain the selected ratio.

## Input

Two banks offer PULL / RELEASE / RESET and DAMP / MASS / SPRING / PARTS / RULE. PULL cycles held displacements -1.25, +0.625, +1.25; RESET returns to +1.25. Both zero velocity, elapsed model time and crossings while retaining parameters and reveal settings. RELEASE zeros velocity and begins from the current position. DAMP cycles the four ratios; MASS cycles 2/4/1; SPRING cycles 8/16/4.

Actual XRTools pickup and drop signals are connected. spring_handle.gd runs at physics priority 100 after the grab driver, projects its requested world position onto local X, clamps to +/-1.5 m, and keeps Y=1.35, Z=0 with fixed orientation. Dropping begins motion from rest, ignoring throwing velocity. PULL/RELEASE/RESET are ignored while grabbed. The handle belongs to no_gravity_gun and releases frozen. Collision mask zero prevents a competing contact solver. Tracked-hand comfort is untested.

## Displays and limits

PARTS shows cyan restoring, orange damping and gold total force, on the body and wall. Both use the same samples and 0.04 m/N scale. RULE reveals the update; numerical readouts run at 10 Hz. Coil mesh and six arrow rigs are allocated once and transformed thereafter. There is no time-history plot here.

A crossing counts a displacement sign change during free integration. The cutoff at |x|>2.25 freezes outgoing state and retains velocity in the readout. It does not bounce, clamp the model to a wall or dissipate its velocity. The model continues arbitrarily small motion near rest rather than inventing an exact stopping threshold.

## Space and checks

All 22 identities remain. A sixteen-row arrival extends the room from 30x30 to 30x46. Spring moves to (15,8) at unit scale; the other 21 placements shift together. surreal_kinetic_sculpture is compacted to scale 0.12 and raised 0.7 m. Its opt-in presentation:museum disables standalone lights, cameras and screen overlays while retaining its moving forms.

The actual museum probe verifies analytical free-spring response, energy error tolerance, damping comparisons, mass response, frame partition agreement, live pointer controls, supplied XRTools pickup/drop, retained state, force signs, matching wall arrows, allocation stability and sampled approaches. See restoring-forces-check.json in the illustrated guide for the current count. Headset testing and detailed supporting-exhibit review remain open.

### Change_Choreography

Source: `commons/maps/Change_Choreography/tutorial.md`

# Timing machines: period, phase and throughput

This hall follows Vectors_Act4b_Oscillation in Forces. It returns to the rate and accumulation ideas from Change. Its primary order is phase_rod_array then conveyor_backlog; the later gravity hall retains its position.

## Twenty rotors

A four-by-five indexed array uses `angle = TAU * frequency * elapsed + phase`. Base frequency is 1/6 Hz. ONE + changes index 9 by PI/4 modulo TAU. WAVE sets phase `(index % 5) * TAU/5`. DRIFT sets indices 10..19 to 1.04 times the base frequency. Relative frequency is 1/150 Hz, so the two groups align every 150 seconds. Controls switch configurations immediately; elapsed time remains continuous. RESET restores equal phases and frequencies, not elapsed zero. RULE toggles the displayed equation. Rotation is prescribed, not simulated by torque. The light rods are visual moving parts above collidable bases.

## The receiver

The existing conveyor_belt scene supplies the visual deck. A new StaticBody3D provides a moving surface, with world-oriented `constant_linear_velocity` of 0.9 m/s. Spawned RigidBody3D parcels have mass 0.5, side 0.44 m, friction 0.75 and bounce 0.05. Continuous collision detection is enabled. Parcel sleeping is disabled so a queue released on a moving static surface resumes contact-driven motion. The belt surface is 1.2 m above the floor; the narrow receiving tray has its floor at 0.45 m. Belt, side rails and receiving tray have colliders. Finite contacts and the physics timestep govern the resulting arrangement.

Feed attempts occur every 1.2 seconds. Each collection pulse removes at most the oldest live parcel whose local x is at least 2.9 m and whose centre has dropped below 1.12 m into the tray. The receiver intervals are MATCHED 1.2 s, BACKLOG 3.0 s, RECOVERING 0.6 s. A pulse with no arrived parcel does nothing. Entering a receiver mode restarts its interval timer; it does not reset the feed timer or existing parcels. RESET clears parcel bodies and local counts, restores matched operation and preserves elapsed time.

`admitted - collected == boxes.size()` is the accounting invariant. Admission pauses if the inlet is occupied or the 48-body cap is reached. Capacity is shown on the console. The experiment is bounded; it is not an unlimited source of physics bodies. Parcels are rigid bodies, not XR pickables, and the pile is not a certified climbing route.

## Review

Compare one phase offset before a phase wave, then frequency drift. Compare actual transport under matched intervals, backlog and recovery. Desktop scripted-pointer and physics tests accompany the first implementation. Headset reach, hand interaction, label comfort and live performance remain to be walked.


<!-- study-spine:paired_time -->

## Return: A second together

Halve the rate difference; compare the growing gap with an unchanged phase offset. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses loop, rate, transform. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`paired_time`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-02-gonzalez-torres-a-second-together/index.html). These controls change only the dial state. RESET restores this pair without restarting the hall.

<!-- study-edit:paired_time -->

### One source change: A second together

Change DRIFT_RATIO from 1.04 to 1.02 in paired_time_score.gd. After RESET and DRIFT RIGHT, predict the gap after 30 seconds: 18° instead of 36°. Keep the 12-second base period. Then choose SAME RATE and observe that the gap stops growing without closing.

```gdscript
const DRIFT_RATIO := 1.02
```

Source: `commons/artifacts/spine_studies/paired_time_score.gd`. Use the prepared scene to run and compare.

<!-- paired-time-reference -->

### Compare a rate with an offset

This encounter follows the phase rods and the conveyor in **Forces → Choreography**. The map ID retains the name `Change_Choreography`. Day Zero supplied the repeating update; Change supplied a rate and its accumulation; Oscillation and this hall supplied returning movement and phase. The two dials are an application of that existing toolbox.

Begin with RESET. Each hand makes one turn in twelve seconds. Use DRIFT RIGHT, wait thirty seconds and then reveal READING: the right hand has gained 36°. SAME RATE gives the right hand the left hand's speed while preserving both current positions. The gap stops growing. OFFSET +45° changes only the right position, immediately. ALIGN copies the left position to the right without changing either rate. If their rates still differ, alignment lasts only an instant.

HOLD / RUN pauses these two stored angles, not the player or the museum. READING reveals the current ratio and clockwise phase gap. RESET restores the original angles, equal rates, running state and hidden readout. No controls move the wall or its collider.

The one-line edit above halves the rate difference. Before running it, predict the gap after the same thirty seconds. The relative rate is `(1.02 - 1.0) / 12` turns per second. It gains 0.05 turns, or 18°. At a 4% difference the dials align every 300 seconds; at 2%, every 600 seconds. This is visual alignment modulo a turn, not recovery of a lost history.

### What the program keeps

The production score stores two angles. Each update adds its chosen rate multiplied by the same `delta`:

```gdscript
left_angle = fposmod(left_angle + TAU / PERIOD_SECONDS * delta, TAU)
right_angle = fposmod(right_angle + TAU / PERIOD_SECONDS * right_ratio * delta, TAU)
```

Changing `right_ratio` does not replace either angle. That is why changing speed has no immediate jump. `align()` assigns `right_angle = left_angle`; it has a different job. `fposmod` keeps the displayed angles within one turn. The code discards whole-turn counts, so its readout cannot tell you how many times one dial has lapped the other.

The renderer maps those angles onto identical single-hand dials; all fabrication, pointer controls and the museum player are supplied. Neither dial is a wall clock. They have no independent oscillator, battery or ageing mechanism. Engine stalls advance both through the same elapsed delta; the rate difference is authored explicitly. Full hardware clock synchronization, audio, independent oscillators and lifetime simulation are outside this first edit.


### References and model limits

[Whitney: Felix Gonzalez-Torres](https://whitney.org/artists/3454). The Whitney research led to this artist. This particular paired-clock reference is not presented as a Whitney collection work.

[Foundation: “Untitled” (Perfect Lovers), 1991](https://www.felixgonzalez-torresfoundation.org/works/untitled-perfect-lovers2). The Foundation records two wall clocks and wall paint, ideally installed above head height. Ada uses enlarged single-hand dials and explicit rate controls; it is an original application, not an authorized installation or reconstruction of that work.

[MoMA: “Untitled” (Perfect Lovers), 1991](https://www.moma.org/collection/works/81074). MoMA describes initially synchronized battery-powered clocks, possible drift or stoppage, resetting, and the context of the artist’s partner being diagnosed with AIDS. The digital study models none of that bodily or material vulnerability.

<!-- /paired-time-reference -->

### VFM_07_Gravity

Source: `commons/maps/VFM_07_Gravity/tutorial.md`

# Gravity: two encounters, one interaction law

Start with RUN, watch, then use the left bank to change a beginning. PARTS and RULE reveal the model after observation. Stable primary tokens are orbital_mechanics_demo and three_body_problem. Both opt into commons/artifacts/orbital_mechanics_demo/gravity_relations.gd; the original standalone scenes remain available without the lesson metadata.

## Controls

| Control | Effect |
| --- | --- |
| RUN | Pause/resume retained state; a frame exit requires RESET. |
| RESET | Reset both copies and their clocks/trails, retaining selected parameters; wait paused. |
| SPEED, first station | Reset with 0.6, 1, 1.25 or 1.6 times this softened model's circular speed at radius 3 m. |
| REVERSE, first station | Negate current satellite velocity without resetting position or time. |
| BODIES, second station | Toggle two/three equal 4 kg masses; reset. The first pair's initial states remain the same. |
| NUDGE, second station | Reset paired copies with 0, 0.03 or 0.15 m added only to the last body's initial X in copy B. |
| PATH | Hide/show history; recording continues. |
| PARTS | Show acceleration arrows, scaled 0.30 m per m/s² and capped at 2 m; baseline maximum acceleration stays numerical on the board. |
| RULE | Reveal softened law, units, integration frequency and fixed/mutual response. |

## Model and retained state

G=1 m³/(kg s²), epsilon=0.25 m. Pair force is G mi mj r/(r²+epsilon²)^(3/2). The first experiment assigns no acceleration to source zero (12 kg); satellite mass is 1 kg. The second adds equal and opposite pair forces before dividing by each 4 kg receiving mass. This is a changed model of close attraction, not an exact point-gravity solver.

Velocity Verlet advances at 1/240 s. Each step computes all accelerations, half-kicks velocity, drifts positions, recomputes accelerations and finishes the kick. Frame-delta catch-up caps at 0.25 s, so a longer stall does not simulate all elapsed wall time.

The equal pair begins at X=-2/+2 with opposite tangential velocities calculated for a softened circular pair. The third begins at (0,0,2.6), velocity zero. A nudged comparison retains its changed centre of mass: no recentering or velocity adjustment. RMS separation measures corresponding positions at the same model time; it is not a Lyapunov exponent.

Both models calculate in X–Z. Opaque bodies render at Y=1.45; translucent comparison bodies at Y=2.10. This offset is display only. Bodies have no mutual collision or player-force coupling. The visitor can stand within the plan.

Trails sample at 20 Hz, retain 240 positions per body and reuse mesh resources. The entire experiment freezes when any body's absolute X or Z exceeds 5.2 m. Outgoing velocity is preserved. This is an observation cutoff, neither a wall response nor a proof of escape.

## Evidence

The actual-museum desktop probe commons/testing/probe_gravity_relations.gd passes 51 checks: circular motion, reversal, conservation tolerances, third-body contributions, controlled nudges, deterministic replay, frame cutoff, bounded trails, controls and sampled capsule approaches. At four seconds, the selected three-body baseline has momentum residual 0.00001985 kg m/s and energy ratio 0.99992286 relative to its beginning. Tested momentum tolerance is 0.001 kg m/s; the solver uses finite-precision Vector3 state. These bounds describe this checked interval, not all possible configurations. Headset reach, comfort, performance and detailed secondary review remain open.

### VFM_09_Legs

Source: `commons/maps/VFM_09_Legs/tutorial.md`

# Support before a step

## Primary 1: support_polygon_lab

The 3.4 × 0.25 × 3.4 m plate is an actual RigidBody3D, mass 10 kg, gravity_scale=1, no added linear/angular damping and no sleep. Its custom centre of mass cycles (0,0,0), (-0.65,0,+0.65), (+0.65,0,-0.65). Inertia remains (12,20,12) kg m², a prescribed tensor rather than an automatic recalculation of a material load. A gold X-ray cube sits at that exact mass centre.

Four posts at X/Z=±1.35 m have 0.16 m square tops at Y=1.5 m. The held plate begins with its underside 0.01 m above them. Plate, posts and catching floor share friction 0.8 and bounce 0. They use private collision bit 22. The player and ordinary museum furnishings do not collide with the load.

| Control | Implemented action |
| --- | --- |
| RELEASE | Unfreeze and wake the load; engine gravity/contact then determine motion. |
| RESET | Restore level pose and zero velocities, freeze, retain choices. |
| FEET | Cycle four posts; three excluding corner 1; adjacent pair 3/4; diagonal pair 2/4. Reset held on each edit. |
| SHIFT | Cycle the three custom mass centres and reset held. |
| PARTS | Show X-ray mass centre, its floor projection, initial footprint on floor and wall, live wall cross, measured tilt and initial signed margin. |
| RULE | State the assumptions and material/body settings. |

Geometry2D.convex_hull encloses the corners of the selected pad squares. Signed margin is the shortest distance from the initial mass projection to that outline, positive inside and negative outside. The footprint is a prediction for the initial horizontal arrangement, not a live collision/contact sensor. The wall compresses floor Z by a factor of 0.6; it is a plan of the same geometry, not a second experiment. Measured tilt is acos of body-up dotted with world-up.

With vertical weight and suitable upward support forces, a mass projection inside the support polygon allows static balance. Finite contact patches matter: two opposed squares span a narrow area; two ideal points span only a line. Boundary equilibrium is marginal. This does not decide dynamic balance, frictional sliding, arbitrary contact orientations or a gait controller.

## Primary 2: four_leg_critter

The original scene is retained. Body extends leg_walker_base.gd, a MeshInstance3D. Patrol advances position directly. Ground sampling helps place foot targets; it does not integrate body gravity. _update_gait chooses the most overstretched planted foot when no foot is stepping. Swing interpolates a target with smoothstep and adds a parabolic vertical arc. FABRIK reaches toward the target. No support-polygon test governs lifting and no body tipping results from unsupported configurations.

The other six walkers remain as supporting variations. The row changes more than leg count; rig dimensions and stepping rules differ. Neither diagonal pairing nor a particular gait follows necessarily from having four legs. Do not reuse the earlier map prose as physical evidence; it is archived in the before record.

## Verification

The actual-museum probe exercises pointer buttons, held/reset behavior, real contact support and tipping, finite-pad geometry, shared material, exact mass marker, paired floor/wall display, original four-leg scene and five sampled standing approaches. Captures are actual Godot desktop views. Headset legibility, reach, comfort and sustained performance remain open. The experiment does not give the player physical weight on its plate.

### VFM_08_Arena

Source: `commons/maps/VFM_08_Arena/tutorial.md`

# Arena: selection, state and collision

## arena_relation_lab

A full-scale station wraps the existing head_crab.gd controller using lesson_crab.gd. That subclass replaces only candidate selection and fallback target acquisition. It nominates this station's food and either a beacon or one actual museum-player node. The nearest visible candidate strictly within 6 m is eligible, excluding the inherited temporary ignore list. A strict less-than comparison means an exact distance tie retains the food candidate encountered first. No sight memory is used; stale targets are cleared on selection. This is explicitly different from the base crab's global candidate groups and brief sight memory.

Candidate distance uses 3D node positions; _sees uses the existing horizontal ray at floor + 0.20 m with collision mask 1. The screen is real query-blocking geometry. It can also block the visitor's route when present; passages remain at both ends. The displayed candidate line lies at a fixed display height and is not the ray itself.

Crab scale is 0.3, chase speed 0.8 m/s, patrol speed zero, path grid disabled. Existing whisker/shape-query avoidance and plant/swing gait remain. Movement writes position; this is not a RigidBody3D and does not model momentum transfer. The scoped crab cannot bite. Existing crabs and turret deeper in the hall retain their own behavior.

| Control | Action |
| --- | --- |
| RUN | Pause/resume this crab's controller, including the feeding timer. |
| RESET | Replace crab with an unfed instance, remove this station's food, pause; retain beacon, screen, visitor and reveal choices. |
| BEACON | Cycle centre, right, left target positions without resetting the animal. |
| VISITOR | Switch nominated target between beacon and actual museum player. |
| FOOD | Offer one native mushroom on the pink pad; no stacking, none after the stopping threshold. |
| SCREEN | Show/hide a 2.4 × 1.4 m collision screen and its sight obstruction. |
| PARTS | Reveal candidate, candidate line, distance, feeding timer and completed meals. |
| RULE | Expose selection scope, distance/sight geometry, lack of sight memory and the five-meal threshold. |

Food reuses SporeMushroom via lesson_food.gd. _plant removes global spider_bait membership; only this station's selector considers it. Walking pickup is disabled. begin_absorb, consume, eating animation and the meal count use the existing code. A meal begins within feed_reach=0.26 m measured horizontally and takes feed_time=2 seconds of controller updates. Once begun, feeding completes before selection resumes. The fifth completed meal calls _root, disables bite and both speeds. No branches are created and no policy is learned.

At absolute local X or Z greater than 5 m, the station pauses its crab. This is an observation bound, not a wall. RUN cannot resume a boundary exit until RESET. Food's short planting/consumption tweens are separate from pausing the crab.

## collision_carts

The existing scene and passage are retained. MASS RATIO maps 0..1 to striker mass 0.4..2.6; target mass is 1, incoming striker speed 1, target initially still. Analytic elastic 1D outcomes are vA=(mA-mB)/(mA+mB)*u and vB=2*mA/(mA+mB)*u. Upper/lower lanes show before/after. Both momentum and kinetic energy balance under those stated conditions. Arrows have a visibility threshold and a fixed length offset, so their drawn length is not a precision speed scale.

## Verification scope

The desktop probe runs in the actual museum and checks live pointer controls, selection/occlusion, autonomous arrival and feeding, timed consumption, five-meal state, reset, actual player nomination, observation boundary, approaches and the retained collision-carts model. It also tests conservation at three ratios independently of the displayed arrows. These do not certify every retained Arena artifact. Headset reach, legibility, comfort and sustained performance remain open.

### Vectors_Act5_ForceAsPlace

Source: `commons/maps/Vectors_Act5_ForceAsPlace/tutorial.md`

# A local acceleration and three receivers

Start with vector_machine, force_cube, then force_field_zone. Compare the preserved plank with entry into the field. The machine exposes pitch [-pi/2,pi/2], yaw [0,2pi], magnitude [0,15] m/s². Yaw zero points world +Z. Opening acceleration (0,-9.8,0); for an initial up/forward trial choose pitch about 45 degrees, yaw zero, magnitude about 7.5. These values invite a crossing attempt, not a guaranteed landing for every incoming velocity.

The lesson is opted in by #lesson:force_as_place on the machine, zone and three probes. The machine locates the shared em_map ancestor and updates only opted-in zones there, including zones loaded after its controls. Legacy machines skip these scoped zones.

Released RigidBody3D receivers in the real Area3D save gravity_scale, replace it with zero, then add field_vector * delta directly to linear_velocity. This is acceleration, independent of mass. Godot retains body damping/contact. Leaving the area, becoming frozen, or removing the field restores saved gravity. There is no claim that this overrides every other force.

Desktop locomotion samples incoming velocity before its ordinary update, then asks the opted-in containing field for its retained post-collision velocity plus a*dt. The final handoff happens before move_and_slide; collision output is recorded for the next step. While inside, this replaces keyboard steering/jump output. Exit clears field history, ordinary horizontal input takes over, and the vertical state returns to normal gravity. First containing field owns a visitor if volumes overlap.

The XRTools provider runs at order 95, respects earlier exclusive providers, uses move_player and returns exclusive ownership inside. It installs for both existing and late XRTools player bodies without duplicates. This changes software locomotion, not tracked physical movement. Headset comfort and embodied testing remain pending.

Field dimensions: five metres, centred in X/Z and extending from local y=0 to 5. Visitor feet use strict X/Z interior and y in [-0.02,5]; physical cubes use area overlap. On entry, velocity is retained. Zero field acceleration does not stop motion. The carry receiver has no added damping; the loose probes retain linear_damp 0.3 plus project defaults.

ForceCube displays sampled velocity * 0.5, capped at 2.6 m, decomposed in body-local axes. This lesson removes the legacy seeded rest arrow; stationary means zero. Its readout declares the visual scale/cap instead of calling the arrow force. Recovery below four metres from its home height restores the initial transform and freezes; basin floor contact can prevent reaching that threshold.

The map is reversed in Z across all layers to place the machine before the field in museum travel. All eight artifact placements and six identities remain. Original walls, five-row pit and two-cell plank are preserved. Field geometry is an Area and drawing, not a wall; its opt-in placement must not erase the plank from the museum walk graph.

---

## 08. Form Finding: Rules, Constraints and Possible Shapes

### FormFinding_Descent

Source: `commons/maps/FormFinding_Descent/tutorial.md`

# One local update, several endings

Primary: descent_landscape_lab. Ask for a predicted next position, press STEP, then RUN. Reveal PARTS and RULE after observing. RUN performs one discrete optimisation update per presentation interval of at least 0.22 seconds; there is no physical delta in the descent equation.

The parameter domain is x,z in [-3,3]. Bowl cost: 0.25*(x*x+z*z). Two valleys: 0.08*(x*x-4)^2+0.25*z*z+0.15*x. Central differences sample the analytic cost at offsets +/-0.03 along each axis. The drawing has 48 by 48 cells; height is 0.40+0.22*cost. Its surface has no collision; the pedestal does. The arrow shows negative gradient horizontally, capped at one metre.

Rates: 0.2, 0.7, 2.5, 5.0. Slope tolerances: 0.01, 0.08, 0.3. Starts: (-2.8,-2), (2.8,-2), (0,-2). Default rate 0.7 and tolerance 0.01. Settings reset the run; RESET preserves settings. PARTS and RULE reveal representations without resetting. STEP pauses continuous playback.

At each update, reaching 160 moves reports STEP LIMIT; a sampled gradient below tolerance reports SMALL SLOPE; a proposed address outside the domain reports LEFT FRAME without committing the move. Otherwise position changes by -rate*gradient and the trail gains a sample. No velocity, momentum, mass or gravity participates. At most 161 samples are retained in a reused ImmediateMesh.

Compare first and second starts on two valleys: observed final costs -0.304257 and 0.295496 with identical rate/tolerance. Compare loose versus tight tolerance on the bowl. Large finite steps can increase cost or leave the domain despite following a locally descending direction.

Five earlier exhibits remain secondary. The marble toy retains velocity and periodically receives random kicks; it is not a hand-tipped rigid marble or this optimiser. Legacy gradient_descent is scaled to 0.14 and raised 0.8 to contain its original 20-metre surface in a side exhibit. The well has momentum and multiple starts. Science Screen has not been connected to the new lab; the lab has its own display. Do not claim those exhibits share a single solver or stopping rule.

### FormFinding_Catenary

Source: `commons/maps/FormFinding_Catenary/tutorial.md`

# Form-Finding: Catenary

Two of the oldest solved minimisations, side by side. Before them, a boundary must be fixed — two anchors for the chain, two rings for the film.

Fix the anchors.

```gdscript
for i in range(control_point_count):
    var point: Node3D = point_scene.instantiate()
    var t: float = float(i) / float(control_point_count - 1)
    point.position = Vector3((t - 0.5) * cable_length, 1, 0)
    $ControlPoints.add_child(point)
    control_points.append(point)
```

Grabbable spheres. These are the only decisions you make. The curve between them is not yours.

Pull each span down by a fraction of its own length.

```gdscript
var p1: Vector3 = to_local(control_points[i].global_position)
var p2: Vector3 = to_local(control_points[i + 1].global_position)
var distance: float = p1.distance_to(p2)
var handle_length: float = distance * 0.3
curve.set_point_out(i, Vector3(handle_length, -gravity_sag * distance * 0.5, 0))
curve.set_point_in(i + 1, Vector3(-handle_length, -gravity_sag * distance * 0.5, 0))
```

The sag scales with the span. Move an anchor and the depth follows. That dependence is the whole difference between a curve derived and a curve drawn.

Sweep a tube along the baked curve.

```gdscript
var total_length: float = curve.get_baked_length()
var sample_count: int = maxi(2, int(total_length * spline_resolution))
for i in range(sample_count):
    var t: float = float(i) / float(sample_count - 1)
    positions.append(curve.sample_baked(t * total_length))
```

`sample_baked` walks the curve by arc length, not by parameter. Even sampling along a cable that sags unevenly.

Draw the alternative, so you can see what it costs.

```gdscript
var depth: float = 0.45
var out := PackedVector3Array()
for k in range(41):
    var t: float = float(k) / 40.0
    var p: Vector3 = a[0].lerp(a[a.size() - 1], t)
    p.y -= depth * 4.0 * t * (1.0 - t)
    out.append(p)
```

One fair bow of fixed depth between the end anchors only. The interior control spheres visibly do not sit on it. A drawn curve has stopped agreeing with its own data.

Revolve a cosh to get the soap film.

```gdscript
@export var c: float = 0.5      # waist radius

var r: float = c * cosh(u / c)
var x: float = r * cos(v)
var y: float = r * sin(v)
var z: float = u
```

The catenary rotated is the catenoid — the least area that can span two rings. Galileo guessed the hanging chain was a parabola. It is `cosh`, and the chain had been getting it right the whole time. Pull the rings too far apart and no catenoid exists; the film breaks into two discs.

Rule the other minimal surface.

```gdscript
@export var pitch: float = 0.3

var x: float = u * cos(v)
var y: float = u * sin(v)
var z: float = pitch * v
```

A straight line swept as it rises. The helicoid and the plane are the only ruled minimal surfaces, and the helicoid bends continuously into a catenoid without ever stretching.

Give the surfaces a body so hands can move the boundary.

```gdscript
var cylinder := CylinderShape3D.new()
cylinder.radius = c * cosh(u_max / c) * scale_factor
cylinder.height = (u_max - u_min) * scale_factor
collision.shape = cylinder
```

The surface is a function of its frame and nothing else. Move the frame and the minimum moves with it, instantly, with no solver in between.

You can now hang a cable whose sag is derived rather than drawn, revolve a catenary into a minimal surface, rule a helicoid, and hold both by their boundaries. The draftsman proposes; gravity computes. FormFinding_Relaxation replaces the closed form with a mesh that has to settle.

### FormFinding_Relaxation

Source: `commons/maps/FormFinding_Relaxation/tutorial.md`

# Form-Finding: Relaxation

A mesh released settles into a shape nobody specified. Before it, particles that remember where they were and springs that know their rest length.

Store the previous position, not the velocity.

```gdscript
var positions: PackedVector3Array = PackedVector3Array()
var prev_positions: PackedVector3Array = PackedVector3Array()
var pinned: Array = []

func add_particle(pos: Vector3, is_pinned: bool = false, mass: float = 1.0) -> int:
    positions.append(pos)
    prev_positions.append(pos)
    pinned.append(is_pinned)
    return positions.size() - 1
```

Velocity is implied by the difference. This is Verlet: integrate position straight from position, never storing a speed.

Step it forward.

```gdscript
var pos: Vector3 = positions[i]
var prev: Vector3 = prev_positions[i]
var vel: Vector3 = (pos - prev) * damping
var new_pos: Vector3 = pos + vel + gravity * dt * dt
prev_positions[i] = pos
positions[i] = new_pos
```

Gravity enters as `dt` squared because it is an acceleration and this is a position. Damping multiplies the implied velocity, bleeding energy without ever naming it.

Add a spring and let it read its own rest length.

```gdscript
func add_spring(a: int, b: int, rest_length: float = -1.0) -> void:
    if rest_length < 0.0:
        rest_length = positions[a].distance_to(positions[b])
    springs.append([a, b, rest_length])
```

You specify the connections. The rest lengths are read off the lattice you built. Nobody types in a shape.

Nudge every constraint halfway back, several times a frame.

```gdscript
for _p in constraint_passes:
    for s in springs:
        var diff: Vector3 = positions[s[1]] - positions[s[0]]
        var cur: float = diff.length()
        var cv: Vector3 = (diff / cur) * (cur - s[2]) * 0.5 * stiffness
        if not pinned[s[0]]:
            positions[s[0]] += cv
        if not pinned[s[1]]:
            positions[s[1]] -= cv
```

No linear system is ever assembled. Each spring corrects its ends by half the error, and the network agrees by repetition.

Turn the number of passes.

```gdscript
const RELAXATION_PASSES := {
    "nudged": 1,
    "worked": 4,
    "pressed": 8,
    "held": 12,
}
```

One pass sags, twelve is taut. At equilibrium the cloth hangs at 0.6406 m against 0.5988 m and mean spring stretch falls from 0.701% to 0.051% — a one-over-passes law. Four resting shapes, not four stages of one.

Wire a lattice and let gravity argue with it.

```gdscript
var sim = SBShapes.make_jelly_grid(nx, ny, nz, cell, stiffness)
sim.gravity = Vector3(0.0, -4.5, 0.0)
sim.damping = 0.985
for _i in pre_steps:
    sim.step()
```

Edge springs plus face diagonals, eighty steps, and the argument is over. The bulge is where the disagreement ended, not where anyone put it.

Pin the top ring and run the clock.

```gdscript
var pin_y: float = radius * (1.0 - pin_top_fraction * 2.0)
for v in initial_verts:
    var is_pinned: bool = v.y > pin_y
    if not is_pinned:
        v = v * (1.0 + preinflate)
    sim.add_particle(v, is_pinned)
sim.simulate(sim_steps)
```

A sphere, a pinned collar, a pressure pulse, 200 steps of gravity. Duration is a design parameter — a short run is a bowl, a long one a neck. The clock is part of the genome.

Freeze the pose and keep it.

```gdscript
arrays[Mesh.ARRAY_VERTEX] = sim.positions
arrays[Mesh.ARRAY_NORMAL] = normals
arrays[Mesh.ARRAY_INDEX] = indices
var am := ArrayMesh.new()
am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
```

The simulation runs once, at `_ready`. What stands in the room is not a model of the forces but a recording of them. A form is a fossil of what made it.

You can now integrate positions from positions, hold constraints by correcting rather than solving them, tune insistence with a pass count, and freeze a settled pose. FormFinding_Equilibrium asks what holds a shape still once the settling stops.

### FormFinding_Equilibrium

Source: `commons/maps/FormFinding_Equilibrium/tutorial.md`

# Form-Finding: Equilibrium

Where forces cancel, form holds still. Before it, weights that are real numbers and distances you are free to choose.

Weigh a leaf from its own geometry.

```gdscript
const SHEET_T := 0.003      # 3 mm aluminium sheet
const DENSITY := 2700.0     # kg/m³

var r: float = _rng.randf_range(0.09, 0.24)
var mass: float = PI * r * r * SHEET_T * DENSITY
```

The mass is not a label on the disc. It is the disc — radius, thickness, density. Change the radius and the whole mobile is re-solved.

Place the pivot by the lever law.

```gdscript
var wl: float = left["mass"]
var wr: float = right["mass"]
var total: float = wl + wr
var arm: float = span * (0.7 + 0.35 * float(d))
var dl: float = arm * wr / total
var dr: float = arm * wl / total
```

τ = w·d. The heavier child gets the shorter arm, because each distance is scaled by the *other* one's weight. The arm is solved, not drawn.

Let every arm hang from the arm above.

```gdscript
func _build_subtree(d: int) -> Dictionary:
    if d <= 0:
        return {"node": root, "mass": _make_leaf(pivot)["mass"]}
    var left: Dictionary = _build_subtree(d - 1)
    var right: Dictionary = _build_subtree(d - 1)
    return {"node": root, "mass": left["mass"] + right["mass"]}
```

Each subtree reports its mass upward. A parent balances two numbers without looking inside either.

Break the law, and let the leftover moment become an angle.

```gdscript
dl = arm * 0.5      # halved — the rod cut in the middle instead
dr = arm * 0.5
var tilt: float = asin(clampf((wr * dr - wl * dl) / (arm * total), -1.0, 1.0))
lp = pivot + Vector3(-dl * cos(tilt), dl * sin(tilt), 0)
rp = pivot + Vector3(dr * cos(tilt), -dr * sin(tilt), 0)
```

Residual moment, normalised by the largest moment the arm could carry. Zero residual is zero tilt — which is why a balanced mobile never reaches this branch.

Brace a section instead of thickening it.

```gdscript
var br: float = leg_r * 0.55
for i in range(4):
    var j: int = (i + 1) % 4
    parent.add_child(_cylinder_between(corners_b[i], corners_t[j], br, brace_mat))
    parent.add_child(_cylinder_between(corners_b[j], corners_t[i], br, brace_mat))
    parent.add_child(_cylinder_between(corners_t[i], corners_t[j], br, brace_mat))
```

Two diagonals and a tie per face, at just over half the leg radius. The strength is in the bracing, not the bulk.

Recurse the bracing.

```gdscript
var ym: float = (y0 + y1) * 0.5
var w_mid: float = (w_bot + w_top) * 0.5
_truss_segment(parent, y0, ym, w_bot, w_mid, d - 1, leg_mat, brace_mat)
_truss_segment(parent, ym, y1, w_mid, w_top, d - 1, leg_mat, brace_mat)
```

Every strut becomes a truss of thinner struts; `leg_r` runs 0.05 down to 0.018 with depth. Strength from geometry, not mass. Walk inside and you are in a beam made of beams.

Lock three angles.

```gdscript
var v_top := Vector3(0.0, tri_height * 0.6, 0.0)
var v_bl := Vector3(-tri_width * 0.5, -tri_height * 0.4, 0.0)
var v_br := Vector3(tri_width * 0.5, -tri_height * 0.4, 0.0)
_add_strut(v_top, v_bl, strut_mat)
_add_strut(v_bl, v_br, strut_mat)
_add_strut(v_br, v_top, strut_mat)
```

Push a square and it racks into a diamond. A triangle cannot: its angles are already fixed by the lengths of its sides.

Load it, and watch it refuse.

```gdscript
_phase += delta * load_speed
var load: float = maxf(0.0, sin(_phase)) * load_amplitude
scale = Vector3(1.0 + load * 0.4, 1.0 - load, 1.0)
```

It squashes and springs back. Nothing here is stacked. The form holds because forces balance in a field, not because mass piles up in a column.

You can now weigh a part from its geometry, solve a pivot instead of drawing one, recurse bracing into a self-similar truss, and lock a frame with three members. Gaudí hung weighted chains and turned the photograph upside down — tension inverted is compression, and the arch was found rather than imposed. FormFinding_Annealing asks what to do when the rest you reach is only the nearest one.

### FormFinding_Annealing

Source: `commons/maps/FormFinding_Annealing/tutorial.md`

# Form-Finding: Annealing

Descent is greedy and gets stuck. Before this map, a landscape with more than one valley.

Wrinkle the surface so it has many rests.

```gdscript
@export var amp: float = 0.09

func _energy(x: float, z: float) -> float:
    return amp * (sin(x * 9.0) * 0.6 + cos(z * 7.0) * 0.5 + sin((x + z) * 5.0) * 0.4)
```

Three sines at different frequencies. Height is energy, so every trough is a possible rest. The annealing table uses Rastrigin for the same job — a bowl with a cosine lattice milled into it, one global minimum in a regular grid of traps.

Drop a body on it and nudge it downhill.

```gdscript
var p: Vector3 = _sim.positions[i]
var floor_h: float = _energy(p.x, p.z) + blob_size * 0.28
if p.y < floor_h:
    _sim.positions[i].y = floor_h
    var gx: float = (_energy(p.x + 0.01, p.z) - _energy(p.x - 0.01, p.z)) / 0.02
    var gz: float = (_energy(p.x, p.z + 0.01) - _energy(p.x, p.z - 0.01)) / 0.02
    _sim.positions[i].x -= gx * 0.0008
    _sim.positions[i].z -= gz * 0.0008
```

It finds the nearest valley, not the deepest. Descent is local and has no view of the map.

Propose a jump instead of taking a step.

```gdscript
var strength: float = current_temperature / initial_temperature * search_space_size * 0.3
var neighbor := Vector2(
    current_solution.x + randf_range(-strength, strength),
    current_solution.y + randf_range(-strength, strength)
)
```

The step size is the temperature. Hot proposes wildly, cold barely moves. No gradient is read at all — the candidate is guessed, then asked its energy.

Accept a worse position with a probability.

```gdscript
var delta_energy: float = neighbor_energy - current_energy
var accept: bool = false
if delta_energy < 0:
    accept = true
else:
    var probability: float = exp(-delta_energy / maxf(current_temperature, 0.0001))
    accept = randf() < probability
```

Downhill is always taken. Uphill is taken with probability `exp(-ΔE/T)`. You have to be willing to get worse to get better, and that willingness gets dearer as the system cools.

Cool.

```gdscript
match cooling_schedule:
    "exponential":
        current_temperature *= cooling_rate
    "logarithmic":
        current_temperature = initial_temperature / log(2.0 + current_iteration)
```

Anneal, do not quench. At `cooling_rate = 0.95` the shaking dies slowly enough to still leave a shallow trap; cool fast and you freeze into whichever valley you were shaken into. The adaptive schedule tunes the rate to hold acceptance near 0.44.

Hop when nothing has improved for a while.

```gdscript
if basin_hop_enabled and steps_since_improvement >= stagnation_threshold:
    if basin_hops_performed < max_hops:
        _perform_basin_hop()
```

Stagnation is information. A run that stops improving is not converged but trapped, and the cure is a deliberate throw.

Cut two wells and choose between them.

```gdscript
var depth_f: float = (sqrt(f) if narrow else (f * f))
var y: float = -depth * depth_f
```

`sqrt(f)` drops fast — a deep narrow pit, radius 0.9, depth 2.2, holding one rigid cube that will never move again. `f * f` is a soft parabola: radius 2.2, depth 0.7, holding a body that keeps re-finding a slightly different rest.

Jostle the live one so it never finishes.

```gdscript
if fmod(_t, 2.5) < delta:
    for i in _sim.positions.size():
        _sim.positions[i] += Vector3(_rng.randf_range(-0.08, 0.08), _rng.randf_range(0.02, 0.12), _rng.randf_range(-0.08, 0.08))
_constrain_alive()
_sim.step()
```

You can now build a landscape with many rests, propose by temperature instead of gradient, accept a worse position on purpose, cool on a schedule and hop when you stall. But the deepest well is a dead-perfect crystal — finished, frozen, incapable of the next change. Max Q is the liveliest minimum, not the deepest: low enough to hold a shape, high enough to still be moved. FormFinding_Forge hands you the landscape and asks you to let something fall down it.

### FormFinding_Forge

Source: `commons/maps/FormFinding_Forge/tutorial.md`

# Form-Finding: Forge

Shape your own — by arranging the landscape, not the form. Before it, everything this chapter has built: a cost, a slope, a body willing to fall.

Write the cost you want matter to fall down.

```gdscript
@export var amp: float = 0.13

func _energy(x: float, z: float) -> float:
    var bowl: float = (x * x + z * z) * 0.5
    var wrinkle: float = sin(x * 7.0) * 0.18 + cos(z * 6.0) * 0.16
    return amp * (bowl + wrinkle)
```

A clear global basin with local minima cut into its walls. This is the only authorship left to you: set the landscape, then stop.

Take the gradient and step.

```gdscript
@export var learning_rate: float = 0.06

func _grad(x: float, z: float) -> Vector2:
    var e: float = 0.012
    var gx: float = (_energy(x + e, z) - _energy(x - e, z)) / (2.0 * e)
    var gz: float = (_energy(x, z + e) - _energy(x, z - e)) / (2.0 * e)
    return Vector2(gx, gz)

_p -= _grad(_p.x, _p.y) * learning_rate
```

The same three lines as the first map's marble: two samples, a subtraction, a step against the result. The readout beside it prints the step count and the energy falling — settling a soft body and training a model are one algorithm on two landscapes.

Restart once the slope dies.

```gdscript
if _grad(_p.x, _p.y).length() < 0.002 and _step > 30:
    _p = Vector2(_rng.randf_range(-span * 0.4, span * 0.4), _rng.randf_range(-span * 0.4, span * 0.4))
    _step = 0
    _trail.clear()
```

Converged is not solved. A fresh start on a different slope is the cheapest way to find out whether the basin you reached was the only one.

Name the form you are descending toward.

```gdscript
var parts := [
    { "c": Vector3(0.0, 0.0, 0.0), "r": 0.16, "w": 80 },     # torso
    { "c": Vector3(0.0, 0.20, 0.04), "r": 0.10, "w": 45 },   # head
    { "c": Vector3(-0.18, -0.06, 0.0), "r": 0.07, "w": 28 }, # limbs
    { "c": Vector3(0.18, -0.06, 0.0), "r": 0.07, "w": 27 },
]
```

180 particles across four blobs, and a readout that says only "settling" or "MAX Q". The forge does not press this shape onto the matter. It is where the matter ends up.

Carry the cloud toward it, and freeze the jitter as you go.

```gdscript
var jit := Vector3(
    sin(_t * 2.0 + float(i) * 0.9),
    cos(_t * 1.6 + float(i) * 0.6),
    sin(_t * 2.3 + float(i) * 1.4),
) * 0.035 * (1.0 - q)
var p: Vector3 = raw.lerp(target, q) + jit
```

The jitter is the last map's temperature, scaled by `1.0 - q` — loud while Q is low, gone by the time Q is high. Annealing and arrival are one motion seen from two ends.

Prove it with your hands: stack until nothing moves.

```gdscript
var all_stable: bool = true
for piece in _pieces:
    if piece is RigidBody3D:
        if piece.linear_velocity.length() > stability_velocity_threshold \
                or piece.angular_velocity.length() > stability_velocity_threshold * 2:
            all_stable = false
            break
```

Threshold 0.05 m/s, twice that in radians. The win condition is not a shape matched against a template. It is a configuration that has stopped arguing.

Make the stillness cost something to hold.

```gdscript
if all_stable:
    _stability_timer += delta
    if _stability_timer >= stability_time:
        _trigger_transformation()
else:
    _stability_timer = maxf(0, _stability_timer - delta * 2)  # Decay faster than gain
```

One wobble costs two. Rest has to be held for 1.5 seconds, not touched once.

You can now write a landscape, descend it, watch a cloud fall into a coherent body as its temperature drains away, and win by making a system stop rather than making it obey. You carved none of these forms. You arranged the conditions and let them fall. The next sequence, wavefunctions, takes the same minimisation into a space where the resting state is a standing wave.

---

## 09. Wavefunctions: What Returns

### WaveFunctions_Intro

Source: `commons/maps/WaveFunctions_Intro/tutorial.md`

# Wavefunctions Intro

One pendulum you release by hand, a line that does not move, and cubes that were only told where to be. The order below is the order of the room.

Find the still reference first. From the pivot a hairline hangs to a ring. Nothing about it changes while the bob swings.

Take the bob and release it from one side. It is an XR Tools pickable; the pendulum listens to its `picked_up` and `dropped` signals.

```gdscript
func _on_bob_picked_up(_pickable):
	_is_grabbed = true
	_grab_velocity_samples.clear()
```

While the bob is held, the pendulum only follows your hand and computes the angle from the bob's position. No swing is integrated and no crossing is counted.

Watch the ring. It brightens once as the bob passes through, and once again on the way back. Read the label: the angle, and the angular velocity with its sign. The sign differs between the two crossings.

```gdscript
if signf(_angle) != signf(_prev_angle) and signf(_angle) != 0.0 \
		and absf(_angular_velocity) > CROSSING_MIN_OMEGA:
	_crossings += 1
	_last_crossing_dir = 1 if _angular_velocity > 0.0 else -1
	centre_crossed.emit(_last_crossing_dir, _angular_velocity)
```

A crossing is a sign change of the angle while the bob is moving. The room counts them and says which way the last one went.

Release from the other side and compare the direction of the first crossing.

Follow the swing to a turning point. The velocity reading passes through zero and changes sign; the angle is at its extreme.

Read the update that makes all of this happen. Each physics step:

```gdscript
var angular_acceleration: float = -(gravity / pendulum_length) * sin(_angle)
_angular_velocity += angular_acceleration * delta
_angular_velocity *= _damping_multiplier(delta)
_angle += _angular_velocity * delta
```

Gravity pulls toward the hanging position in proportion to sin(θ); the pull changes the velocity; the velocity changes the angle. Under the shipped `free` regime the damping multiplier is a constant 0.995 per physics frame.

Release again, faster. On release the pendulum averages the bob's last positions into a velocity and keeps only the part along the swing:

```gdscript
var tangent_velocity = avg_velocity.dot(tangent_direction)
_angular_velocity = tangent_velocity / pendulum_length
```

At a desk, the hand is the pointer. Right-click the bob, turn the view to carry it out, hold still and right-click again. The pointer does not know what a pendulum is, so the bob tells it who to tell:

```gdscript
_bob_sphere.set_meta("desktop_hook_target", self)
```

and the two hooks go to the same handlers a headset's grab reaches:

```gdscript
func on_desktop_grab(_pointer: Node) -> void:
	if _bob_sphere != null and not _is_grabbed:
		_on_bob_picked_up(_bob_sphere)
```

```gdscript
func on_desktop_drop(_pointer: Node) -> void:
	if _bob_sphere != null and _is_grabbed:
		_on_bob_dropped(_bob_sphere)
```

Held still before letting go, the release is from rest: the hand's last samples are zero, so the tangent velocity is zero too.

Try a small release and a large one and count crossings for each. Behind the swing the predicted θ(t) is drawn for the standard starting angle of 0.3 rad. A large release does not follow it: the sine in the acceleration lengthens a wide swing and the damping shortens each pass.

Then look at the cubes. `y_oscillation_cube` and `transformation_cube` set their height from a sine of the clock; `rotating_cube` spins at a constant rate; `oscillation_controlled_cube` listens to this pendulum's `oscillation_updated` signal and maps one swing to height, tilt and size. Take the bob and the driven cube stops with it; the clock-driven cubes do not notice.

The next room, Pendulum, records the swing along a depth axis. Carry the centre crossing with you.

### WaveFunctions_Pendulum

Source: `commons/maps/WaveFunctions_Pendulum/tutorial.md`

# Pendulum

A swing that keeps returning, and a record of it that keeps receding. Build the pendulum on the fixed step, then decide what its record is allowed to keep. All code below is from `algorithms/wavefunctions/oscillation_driver/PendulumWave.gd`.

Integrate the swing on the physics step.

```gdscript
angular_acceleration = -(gravity / length) * sin(angle)
angular_velocity += angular_acceleration * delta
angular_velocity *= (1.0 - damping * delta) # Apply damping
angle += angular_velocity * delta
time += delta
```

Gravity over length, times the sine of the angle, pulls the bob back toward hanging. Velocity accumulates the pull; the angle accumulates the velocity. `delta` is one sixtieth of a second at this project’s current physics setting, and `time` is this experiment's own clock. With `damping` at zero there is no deliberate energy loss; numerical integration still approximates the motion.

Keep a sample with the time it was taken.

```gdscript
_sample_clock += delta
if _sample_clock >= sample_interval:
	_sample_clock -= sample_interval
	if _sample_clock >= sample_interval:
		_sample_clock = fmod(_sample_clock, sample_interval)
	var bob_local := Vector3(length * sin(angle), pivot_height - length * cos(angle), 0.0)
	trail_points.push_front(Vector3(bob_local.x, bob_local.y, time))
```

A sample is where the bob is and when. The third component is not a position; it is the clock reading. Nothing is kept between samples. A 25 ms target at 60 physics ticks per second is serviced on alternating one/two-tick gaps, about 16.7/33.3 ms. The display reports those actual gaps alongside the target.

Give the record two limits.

```gdscript
while trail_points.size() > max_trail_length:
	trail_points.pop_back()
while not trail_points.is_empty() and time - trail_points.back().z > max_history_seconds:
	trail_points.pop_back()
```

Three hundred marks, or ten seconds, whichever runs out first. At the 25 ms target the count binds near 7.5 seconds. At 200 ms the age binds around fifty marks; entry count and time span are different quantities.

Draw depth from age.

```gdscript
var depth: float = (time - p.z) * time_speed
var at := Vector3(p.x, p.y, -depth)
```

Age times 0.6 metres per second. The newest mark sits at the bob; the oldest retained mark is the farthest. The line joining them is a list laid out along the hall, not a path anything travelled.

Let the pendulum time itself.

```gdscript
if _prev_angle < 0.0 and angle >= 0.0 and angular_velocity > 0.0:
	if _last_upward_crossing >= 0.0:
		_period_measured = time - _last_upward_crossing
```

Two successive upward crossings of the centre give a period. STROBE sets the sampling interval to that period, and marks nearly align. The period and the sampling instants are both quantized to ticks.

Reset this experiment only.

```gdscript
angle = deg_to_rad(initial_angle)
angular_velocity = 0.0
time = 0.0
trail_points.clear()
```

The swing back to its starting angle, the clock to zero, the list to empty. The hall's clock, and everything else swinging in it, is untouched.

## The walk

Enter from the north and pass the raised stage on either side. At the head of the open south half the pendulum swings under its frame; the record recedes away from you toward the exit. Stand at the east post and pick one mark to follow. Walk south beside the record and find two crossings a whole swing apart; count the marks between them. Read the plate: count, span, interval, rate, period, step. Divide the period by the interval. Return to the post and press COARSE; read the plate again. Walk to the far end and wait for a mark to leave. Press STROBE and watch the record stand still while the bob swings. Press RESET. On the way to the south door, ask the seismograph on the west walkway the same questions.

You have seen a record made from a motion, and the rules that end it. The next map, Sine Space, lays the rising and falling along a passage you walk.
<<</MAP>>>

Change the depth rate.

```gdscript
@export var time_speed: float = 0.6
```

A faster rate stretches the same ten seconds over more of the hall; the marks do not change, only their spacing. Any placement can set it, and the readout prints whatever value is in force.

### WaveFunctions_Sine_Space

Source: `commons/maps/WaveFunctions_Sine_Space/tutorial.md`

# Sine Space

A passage whose walls are a rule. Build one wall from a sum of sines, give the other wall the same rule shifted, and read the space between them. All code below is from `algorithms/wavefunctions/sine_wall/SineWallCorridor.gd`.

Add one sine.

```gdscript
offset += base_amplitude * amp_multiplier * amp_mul * sin((base_frequency * freq_multiplier * freq_mul) * z_norm * PI + phase_shift + phase_layer)
```

`z_norm` runs from -1 at one mouth to 1 at the other. `base_frequency` is therefore the number of crests along the length, 4.5 over seven metres here, not a rate in hertz. The caller passes the running phase as `phase_shift` for the left wall and phase plus offset for the right; `phase_layer` belongs to the layer. Each running phase enters the sum once.

Sum three of them.

```gdscript
	for layer in wave_layers:
		var freq_mul: float = float(layer.get("freq_mul", 1.0))
		var amp_mul: float = float(layer.get("amp_mul", 1.0))
		var phase_layer: float = float(layer.get("phase_shift", 0.0))
```

The second layer runs at 1.8 times the spatial frequency with 0.35 of the amplitude, the third at 2.6 times with 0.18. Together they put a finer ripple on the crests. The sum is still one number per column.

Place the wall.

```gdscript
			var base_x: float = side * half_width
			var x_pos: float = base_x - side * displacement
```

`side` is -1 for the left wall and 1 for the right, so a positive displacement moves either wall toward the middle. The displacement does not depend on height; every row of a column stands at the same x.

Give the right wall the offset.

```gdscript
	_right_wall.mesh = _create_wall_mesh(1, half_length, half_width, half_height, phase + phase_offset_between_walls, 1.0, 1.0)
```

The right wall is the left wall's rule with `phase_offset_between_walls` added. At zero the walls agree and bulge in together. At half a turn every sine changes sign, so the right wall moves out by exactly what the left moves in, and the separation along local X is the width everywhere. Shortest or normal clearance around a bend is a different measurement.

Run the phase.

```gdscript
			phase += delta * animation_speed
```

0.35 radians per second in this placement. The whole sum repeats at a fixed position after about eighteen seconds. Each layer travels toward the -z mouth at its own speed because its spatial frequency differs. FREEZE stops this line from running and nothing else.

Read the gap.

```gdscript
	return corridor_width - float(d[0]) - float(d[1])
```

The width minus both inward displacements. The readout prints the narrowest and widest local-X separations along the length as x-gap.

Decide what the wall can do to a body.

```gdscript
	if not enable_collision:
		shape_node.shape = null
		return
```

This placement leaves wall collision off. The walls are drawn every frame and touch nothing; the passage floor is a 24 mm slab with a collider of its own, and that is what holds the body (and what tells the museum's walk map the passage is this body's ground, so nothing else is dealt into it). A wall that must stop a body needs a shape here, and a shape that is rebuilt as often as the mesh.

## The walk

Try the forecourt tray, then continue through the original antechamber. Turn west along its first row, and step into the corridor at its west mouth. Stand still and watch a crest come toward you. Press FREEZE and walk the same stretch. Slide PHASE to the top and read the gap; slide it to the bottom and read it again. Bring AMP up and walk into the pinch. Press RESET. Leave by the east mouth onto the bridge, and look down at the basin's floor of spheres on the way to the south door.

You have walked a rule laid along a passage. The next map, Effect Sound, puts one oscillation inside another and makes the offset audible.
<<</MAP>>>

Show the samples.

```gdscript
@export_enum("skin", "ribs", "strata", "lattice") var cut: String = "skin"
```

`ribs` keeps every sixteenth run of columns as a fin and lets you see the far wall through the near one; the relation between the walls becomes visible from outside the passage. Any placement can ask for it with `#cut:ribs`.


## The forecourt: give the sine a collision surface

Start with `sine_flow_tray` at (3,4). Predict what leaves, press RELEASE, then change only SIZE and repeat. RESET before changing RELIEF. RULE comes after the observation. This is a separate artifact from the recorded four-tray article apparatus; it has one stationary surface and a smaller control set.

```gdscript
samples.append(sin(TAU*0.9*x) * sin(TAU*0.9*z))
```

This expression fills a 21 by 33 vertex array across 2 by 3.2 metres. Min/max normalisation maps it into [0, relief]. Each of the 20 by 32 cells becomes two triangles. The collision shape is constructed from the resulting mesh:

```gdscript
collision.shape = mesh.create_trimesh_shape()
```

The surface is fixed at twenty degrees about local X. Every release creates 32 spheres in the same four-column, eight-row arrangement at local height 1.1 m. Radii are 0.045/0.075/0.105 m; mass remains 0.1 kg, so scaling does not preserve density. Explicit linear/angular damping is 0.05, sphere/terrain friction 0.45, bounce zero, gravity inherited from the project (9.8 m/s² in the checked run). Spheres collide with one another.

An outlet crossing occurs when a sphere centre passes local z=1.6 by more than its radius. Side, back and below-tray exits are classified separately before this test. Departed bodies freeze, stop colliding, and move to the collection display. At 12*physics_ticks_per_second the remaining bodies freeze too. The declared counter includes the activation tick; this is a finite observation window, not a settling detector. The full source is `commons/artifacts/sine_flow_tray/sine_flow_tray.gd`.

SIZE resets the batch without changing any height sample. RELIEF rebuilds the heightfield and resets the batch. RESET restores the declared middle radius/relief and hides RULE. RELEASE always replaces the previous batch, so at most 32 trial spheres are active. The side console sits at standing hand height; its tilted readout and transparent side guards keep the surface visible.

### WaveFunctions_Unit_Circle

Source: `commons/maps/WaveFunctions_Unit_Circle/tutorial.md`

# Unit Circle

A point travels a circle; its shadow traces a wave. Build the amphitheater where rotation becomes oscillation.

Declare the rotating point.

```gdscript
class_name CircleRunner
extends Node3D

@export var radius: float = 1.0
@export var omega: float = 1.0
var angle: float = 0.0
```

Radius and angular velocity. The runner travels the unit circle at rate omega.

Step the angle.

```gdscript
func _process(dt: float) -> void:
    angle += omega * dt
    position = Vector3(cos(angle) * radius, sin(angle) * radius, 0.0)
```

Position follows cosine and sine of angle. The runner traces a circle in the xy plane.

Project the shadow.

```gdscript
func project_shadow(screen_x: float, time: float) -> Vector3:
    return Vector3(screen_x, sin(omega * time) * radius, 0.0)
```

The shadow is sine against time. It strips away the x-component and leaves the sine trace scrolling along a screen.

Draw the projection line.

```gdscript
func draw_projection(line: ImmediateMesh, runner_pos: Vector3, shadow_pos: Vector3) -> void:
    line.clear_surfaces()
    line.surface_begin(Mesh.PRIMITIVE_LINES)
    line.surface_add_vertex(runner_pos)
    line.surface_add_vertex(shadow_pos)
    line.surface_end()
```

A faint line connects the runner to its shadow. The line lengthens and shortens; the learner sees where the sine comes from.

Build the oscillating bridge.

```gdscript
func update_bridge(plank: Node3D, offset: float) -> void:
    plank.position.y = sin(omega * Time.get_ticks_msec() / 1000.0 + offset) * 0.3
```

Planks rise and fall with staggered phase. The bridge becomes a travelling wave the learner walks across.

Label the angle readout.

```gdscript
func update_angle_label(label: Label3D) -> void:
    label.text = "θ = %.2f rad\nsin(θ) = %+0.2f\ncos(θ) = %+0.2f" % [angle, sin(angle), cos(angle)]
```

Three numbers update each frame. The label makes the mapping between angle and projection explicit.

Offer a second runner for cosine.

```gdscript
func spawn_cosine_runner() -> void:
    cos_runner = preload("res://commons/artifacts/wavefunctions/runner.tscn").instantiate()
    cos_runner.phase_offset = PI / 2.0
    add_child(cos_runner)
```

A second runner lags by 90 degrees. Its shadow traces cosine. Two shadows on one screen show the fundamental phase relationship.

You have seen the origin of trigonometry. The next map, 3D Wave Propagation, releases the wave to travel.
<<</MAP>>>

Draw the chord from cosine to sine runners.

```gdscript
func draw_chord(mesh: ImmediateMesh, a: Vector3, b: Vector3) -> void:
    mesh.clear_surfaces()
    mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    mesh.surface_add_vertex(a)
    mesh.surface_add_vertex(b)
    mesh.surface_end()
```

The chord length visualises the phase difference as distance. When phase equals a quarter turn, chord length equals the radius.

Label the two runners.

```gdscript
func label_runners() -> void:
    sin_runner.label = "sin"
    cos_runner.label = "cos"
```

Each runner wears its function name. The amphitheater becomes legible to a first-time visitor.

### WaveFunctions_3D_Wave_Propagation

Source: `commons/maps/WaveFunctions_3D_Wave_Propagation/tutorial.md`

# 3D Wave Propagation

Waves spread from a source. Build ripples that attenuate with distance and interfere where they meet.

Declare the source.

```gdscript
class_name WaveSource
extends Node3D

@export var frequency: float = 1.0
@export var amplitude: float = 1.0
@export var speed: float = 3.0
```

Source holds the three numbers every wave needs. Speed is how fast a crest travels outward.

Sample the wave field at a point.

```gdscript
func sample_at(p: Vector3, t: float) -> float:
    var d := p.distance_to(global_position)
    var falloff: float = 1.0 / max(d, 0.1)
    return amplitude * falloff * sin(TAU * frequency * (t - d / speed))
```

Distance becomes delay. Amplitude falls as one over distance. The sample returns displacement at that point and time.

Render the field on a mesh.

```gdscript
func update_field(mesh: ArrayMesh, t: float) -> void:
    for i in vertices.size():
        var h := 0.0
        for source in sources:
            h += source.sample_at(vertices[i], t)
        heights[i] = h
    mesh.surface_update_vertex_region(0, 0, heights.to_byte_array())
```

Each vertex sums contributions from every source. The mesh updates every frame. Interference emerges from the sum.

Place two sources for a double slit.

```gdscript
func build_double_source() -> void:
    var a := preload("res://commons/artifacts/wavefunctions/source.tscn").instantiate()
    var b := preload("res://commons/artifacts/wavefunctions/source.tscn").instantiate()
    a.position = Vector3(-1.0, 0, 0)
    b.position = Vector3(1.0, 0, 0)
    sources = [a, b]
```

Two sources, one metre apart. The interference pattern appears as bands. The bands move toward either source as amplitudes change.

Colour peaks and troughs.

```gdscript
func tint_by_height(material: ShaderMaterial) -> void:
    material.set_shader_parameter("peak_color", Color(0.9, 0.7, 0.3))
    material.set_shader_parameter("trough_color", Color(0.2, 0.4, 0.7))
```

Peaks warm, troughs cool. The field becomes weather across a reflective surface.

Let the learner drop a pebble.

```gdscript
func _on_pebble_dropped(pos: Vector3) -> void:
    var s := preload("res://commons/artifacts/wavefunctions/source.tscn").instantiate()
    s.position = pos
    s.amplitude = 1.5
    s.lifetime = 3.0
    sources.append(s)
```

A dropped pebble spawns a short-lived source. Ripples expand outward. The learner makes weather.

Attenuate lifetime.

```gdscript
func _process(dt: float) -> void:
    for s in sources:
        s.lifetime -= dt
    sources = sources.filter(func(s): return s.lifetime > 0.0)
```

Sources fade out. The field returns to stillness unless the learner keeps dropping pebbles.

You have released the wave to travel. The next map, Effect Sound, turns the wave audible.
<<</MAP>>>

Readout the nearest source's phase at the player.

```gdscript
func readout_phase(player: Vector3) -> float:
    if sources.is_empty(): return 0.0
    var nearest: Node3D = sources[0]
    for s in sources:
        if s.global_position.distance_to(player) < nearest.global_position.distance_to(player):
            nearest = s
    return nearest.global_position.distance_to(player) / nearest.speed
```

Phase delay is distance divided by speed. The readout shows how far behind the source the learner is standing.

### WaveFunctions_Effect_Sound

Source: `commons/maps/WaveFunctions_Effect_Sound/tutorial.md`

# One wave enters another rule

In Sine Space we applied sine to a position and asked what the resulting surface let a body do. Effect Sound keeps the oscillation and changes its destination: one sine enters the phase of another. AirMusic will carry this listening into a struck body whose response continues after contact.

Begin at the two desks. Press BASELINE, wait for the note, then HOLD. Lift only the orange ball, let it settle and press COMPARE. A is the held note; B is the current setting, played after A and a quarter-second gap. Decide where the change happens before reading the formula: near the onset, through the middle, or in the tail.

## A position becomes three values

The primary artifact is `DualBallFMController`. Each ball belongs to a `ValueMapper3D` cage with a half-metre span. Its three local axes supply three numbers.

| Ball | Local x | Local y | Local z |
|---|---|---|---|
| Blue carrier | Frequency, 100–2000 Hz | Attack, 0.01–0.5 s | Decay, 0.1–3 s |
| Orange modulator | Frequency ratio, 0.5–8 | Phase depth / index, 0–10 | Modulator decay, 0.1–2 s |

These are the cage's axes. The whole instrument faces north in this room, so follow its arrows rather than assuming screen-right is positive world x. Translation supplies a parameter here; it does not carry the sound to the ball's new location. The rig's audio player stays with the instrument.

The orange cage's signal reaches this assignment in `_on_modulator_changed`:

```gdscript
mod_ratio = x
mod_index = y
mod_decay = z
```

A hand can change several values at once. The `differs:` line compares the six current values with the held reference. Use it to make a deliberate one-variable comparison. It has a reporting tolerance: changes up to 1 Hz for carrier frequency, or 0.005 for another value, are not listed. An empty list is agreement within those tolerances.

## The other wave goes inside the sine

The generator computes a time for each sample:

```gdscript
var t = float(i) / SAMPLE_RATE
```

`SAMPLE_RATE` is 44,100. This is an index into the note being generated, not the running museum clock. All the samples are calculated before that note begins playback. The baseline's 1.8 seconds contain 79,380 samples.

The orange values make a decaying contribution to phase:

```gdscript
var mod_env = exp(-t / mod_decay)
```

```gdscript
var modulator_freq = carrier_freq * mod_ratio
var modulator = sin(2.0 * PI * modulator_freq * t) * mod_index * mod_env
```

The ratio gives the modulator frequency relative to the carrier. Index sets how far it displaces the carrier's phase; its unit here is radians. The decay controls how quickly that displacement fades. At index zero the entire contribution is zero, whatever its frequency or decay.

Now read the carrier's line:

```gdscript
var carrier_env = attack_env * decay_env
var output = sin(2.0 * PI * carrier_freq * t + modulator) * carrier_env
```

The modulator is added inside the argument. It advances and delays the carrier's phase. It is not added to the final signal as a separate voice. The instrument is called FM; this expression implements phase modulation, whose changing phase also changes instantaneous frequency.

Return to the orange ball. Keep its height and left-to-right position steady while changing depth. COMPARE again. A longer modulator decay can keep changing the character while the carrier's own envelope grows quiet. One apparent fading contains two adjustable processes.

## An envelope is another rule

Before the carrier line, the actual generator constructs its amplitude envelope:

```gdscript
var attack_env = 1.0
if t < attack_time:
    attack_env = t / attack_time
```

```gdscript
var decay_env = 1.0
if t > attack_time:
    decay_env = exp(-(t - attack_time) / decay_time)
```

The attack ramps to one; the subsequent decay falls exponentially. The generator later applies:

```gdscript
output = tanh(output * 0.8) * 0.5
```

Even BASELINE has an envelope, this nonlinear shaping, gain and 16-bit quantisation. Index zero gives an unmodulated reference, not a sound before processing.

The note's file ends according to a separate rule:

```gdscript
var duration = min(decay_time * 1.2, 3.0)
```

An exponential has not mathematically reached zero when this finite buffer ends. Listen to the tail as an ending the implementation chose. PLAY lets the whole buffer run if another action does not replace it. During a drag the movement threshold and 0.3-second minimum interval can repeatedly restart playback, so moving continuously does not audition the same thing as letting one note finish.

## What HOLD saves, and what the scope selects

HOLD captures both parameters and a rendered sample buffer. Changing B does not regenerate A. COMPARE replays A, waits its duration plus 0.25 seconds, then renders the current B. Leave the controls alone during that pair if you want the comparison you prepared.

The scope is computed from the synthesis expression. It is a selected window, two carrier periods beginning at `attack_time`, with 1,200 points in each waveform lane. The orange lane is divided by index; the output lane is magnified twofold. The carrier lane is shown without its amplitude envelope. These choices make shapes inspectable, but equal screen heights do not mean equal signal amplitudes. The scope is neither a microphone recording nor the whole note.

Keep one sound because you want to hear it again. Change one relation that made it, then listen. This is the capability we carry to AirMusic: a body can answer a brief contact over time, and the way we inspect that answer can reveal one difference while hiding another.

### Wavefunctions_Bernini

Source: `commons/maps/Wavefunctions_Bernini/tutorial.md`

# Bernini

Solomonic columns are sines wrapped around cylinders. Build the vertex displacement that turns stone into frozen motion.

Declare the column generator.

```gdscript
class_name SolomonicColumn
extends MeshInstance3D

@export var height: float = 4.0
@export var base_radius: float = 0.3
@export var twist_amount: float = 0.4
@export var twist_frequency: float = 3.0
```

Height, base radius, twist amount, twist frequency. The solomonic spiral is two sines along the vertical axis.

Build the ring loop.

```gdscript
func ring_at(y: float) -> PackedVector3Array:
    var ring := PackedVector3Array()
    var twist_x: float = twist_amount * sin(TAU * twist_frequency * y / height)
    var twist_z: float = twist_amount * cos(TAU * twist_frequency * y / height)
    for i in 24:
        var angle := TAU * i / 24.0
        var x := base_radius * cos(angle) + twist_x
        var z := base_radius * sin(angle) + twist_z
        ring.append(Vector3(x, y, z))
    return ring
```

Each ring is 24 vertices around the central axis, with its centre displaced by a small sine. The stack of displaced rings produces the helix.

Stack the rings into a mesh.

```gdscript
func build_mesh() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
    for i in 40:
        var y := float(i) / 40.0 * height
        for v in ring_at(y):
            st.add_vertex(v)
    mesh = st.commit()
```

Forty rings yield a smooth column. Each ring is the same size; the centres spiral. Baroque geometry with twenty-odd lines.

Add vertex colours for depth.

```gdscript
func colour_vertex(st: SurfaceTool, pos: Vector3) -> void:
    var t: float = clamp(pos.y / height, 0.0, 1.0)
    st.set_color(Color(0.8 - t * 0.2, 0.7 - t * 0.1, 0.6))
```

The column darkens slightly at the top. Ambient light reads as contour. Bernini's drama becomes geometric tinting.

Layer noise on the surface.

```gdscript
func perturb(vertex: Vector3, noise: FastNoiseLite) -> Vector3:
    var offset: float = noise.get_noise_3dv(vertex * 4.0) * 0.02
    return vertex + vertex.normalized() * offset
```

Tiny perturbations break the mathematical smoothness. The column reads as stone, not plastic.

Animate the twist over time.

```gdscript
func animate_twist(t: float) -> void:
    twist_amount = 0.3 + 0.1 * sin(t * 0.5)
    build_mesh()
```

The column breathes. It rebuilds slowly as if still being carved. The studio becomes active.

Place a candle at the base for raking light.

```gdscript
func place_candle_light() -> void:
    var light := OmniLight3D.new()
    light.position = Vector3(1.5, 0.3, 0.0)
    light.light_color = Color(1.0, 0.85, 0.6)
    add_child(light)
```

A warm off-centre light grazes the surface. Highlights trace the spiral. Baroque lighting completes the effect.

You have cast sine into stone. The next map, John Cage, turns from oscillation to silence.
<<</MAP>>>

### WaveFunctions_John_Cage

Source: `commons/maps/WaveFunctions_John_Cage/tutorial.md`

# John Cage

4'33" made the silence the piece. Build a room where absence is measurable and the noise floor is never actually zero.

Declare the listener.

```gdscript
class_name SilenceListener
extends Node3D

@export var sample_seconds: float = 0.25
var noise_floor_db: float = -60.0
```

A listener records short windows and computes the noise floor. Nothing is ever fully silent; the listener measures how quiet the room actually is.

Sample the ambient level.

```gdscript
func sample_ambient(bus: int) -> float:
    return AudioServer.get_bus_peak_volume_left_db(bus, 0)
```

Godot's AudioServer reports the bus peak in dB. Lower numbers are quieter. The method returns the current read.

Update the floor display.

```gdscript
func update_floor_display(label: Label3D) -> void:
    var level := sample_ambient(ambient_bus)
    noise_floor_db = lerp(noise_floor_db, level, 0.1)
    label.text = "floor: %.1f dB" % noise_floor_db
```

Exponential smoothing keeps the reading stable. The label shows the floor changing with the learner's own breath and movement.

Mark the 4'33" sections.

```gdscript
const CAGE_SECTIONS := [30.0, 162.0, 81.0]

func compute_total() -> float:
    var total := 0.0
    for s in CAGE_SECTIONS: total += s
    return total
```

Cage's score prescribes three movements with specific durations. The total matches the title. The constant records the piece.

Drive a timer against the sections.

```gdscript
func _process(dt: float) -> void:
    elapsed += dt
    if elapsed > CAGE_SECTIONS[current_section]:
        current_section = min(current_section + 1, CAGE_SECTIONS.size() - 1)
        elapsed = 0.0
        movement_label.text = "movement %d" % (current_section + 1)
```

The timer advances through the sections. Movement labels change quietly. The piece performs itself without a musician.

Generate an aleatoric event.

```gdscript
func aleatoric_event() -> void:
    if randf() < 0.005:
        var sound := preload("res://commons/artifacts/wavefunctions/ambient_click.tscn").instantiate()
        sound.position = Vector3(randf_range(-3, 3), randf_range(1, 2), randf_range(-3, 3))
        add_child(sound)
```

Rare, random clicks. The room performs chance. Cage's indeterminacy as a spawn rule.

Log each event for reflection.

```gdscript
func log_event(at: float, kind: String) -> void:
    events.append({"at": at, "kind": kind})
```

The log captures what happened in the silence. Every visit generates a different piece. The score is the rule; the performance is unique.

You have listened to the space between. The next map, AirMusic, lets position in space become note.
<<</MAP>>>

Offer a print mode of the generated piece.

```gdscript
func print_piece() -> String:
    var out := "events:
"
    for e in events:
        out += "  %5.2f  %s
" % [e.at, e.kind]
    return out
```

The piece can be exported as text. The silence becomes a score.

Dim the lights during the movements.

```gdscript
func dim_room(dt: float) -> void:
    world_environment.environment.ambient_light_energy = lerp(world_environment.environment.ambient_light_energy, 0.2, dt)
```

Ambient drops gradually. The room prepares the listener for attention.

### WaveFunctions_AirMusic

Source: `commons/maps/WaveFunctions_AirMusic/tutorial.md`

# A strike gives a note its own beginning

Effect Sound let us keep a reference while changing the parameters of another note. In AirMusic, the comparison concerns events: one strike, a repeated strike on the same bar, and a second bar struck while the first continues. Synthesis Lab will build on the sum that appears here.

Take the striker from its cradle at the table's left end. Strike the longest bar, lift the stick away, and listen. Read the frequency and age above the row. Make the same contact again before the sound ends: the age restarts. Now use a different bar. Two ages continue together.

## One player belongs to each bar

`ResonatingMetallophone` creates eight `ResonatingBar` bodies for this room. Their notes are C4, D4, E4, G4, A4, C5, D5 and E5. Each owns its own `AudioStreamPlayer3D`. Starting one player again replaces that bar's current playback; starting a different player's note leaves the first one running.

The length is assigned from the chosen frequency:

```gdscript
return BAR_LENGTH * sqrt(root / maxf(1.0, freq))
```

The lowest note keeps a length of 0.30 m. Higher notes get shorter bars. This is a mapping from frequency to visible form, not a simulation deriving sound from the material. Other tunings exist as source configurations; this hall has no visitor tuning selector.

## A recognised contact starts the response

The rigid body's contact signal and its `StrikeZone` area feed `_on_body_hit`. The handler follows the hitting node's ancestors to recognise the striker's tip, which is a child collider rather than the stick's root. It ignores the stick while it is returning to its cradle and suppresses closely spaced duplicate notifications.

Strike strength comes from velocity, including the speed measured from a held stick's changing position. The handler applies:

```gdscript
hit_velocity = clamp(velocity_magnitude * 2.0, 0.1, 1.0)
```

Try a slow and a quick contact on the same bar. Above 0.5 m/s this mapping has already reached its ceiling of one. Below it, strength changes without changing the chosen frequency. The bar then starts its response:

```gdscript
is_resonating = true
resonance_time = 0.0
current_amplitude = impact_strength * max_amplitude
```

```gdscript
audio_player.volume_db = -6.0 + (impact_strength * 6.0)
audio_player.play()
```

The visible response starts from strength times `max_amplitude`. Playback volume uses a decibel mapping. At strength 0.1, glow starts at one tenth of its full-strength value, while the player's gain is about 0.54 of its full-strength gain. These are different representations of the same strike, not equal measurements of loudness.

## The buffer was made before you touched it

Each bar generates its mono PCM note once during setup, at 44,100 samples per second. Inside that loop:

```gdscript
var envelope = exp(-t / decay_time)
```

```gdscript
var wave = sin(2.0 * PI * frequency * t)
```

```gdscript
var sample_value = wave * envelope * max_amplitude
var sample_int = int(sample_value * 32767.0)
```

The sine and envelope are multiplied, then encoded as a signed 16-bit sample. The collision does not solve a metal bar's vibration or regenerate this buffer. It chooses when the stored note starts and at what player gain.

The default decay constant is three seconds. After three seconds the exponential is `exp(-1)`, about 0.368 of its initial amplitude. Its mathematical tail has no finite end. The implementation makes a finite buffer:

```gdscript
return maxf(1.0, decay_time * 2.5)
```

For this room that is 7.5 seconds. The last 0.1 seconds receive an additional fade. The bar clears its resonance state when the player stops, so the glow cannot remain as a claim that the note still plays. The final audio fade and the glow's exponential are not identical curves.

## Two notes, two clocks, one picture

Strike C4, wait a little, then strike A4. Each audio player has its own playback position. The table's scope reads a 12 ms window near each position using 512 points. For every point it decodes that bar's PCM and includes the player's gain:

```gdscript
samples[i] = float(pcm.decode_s16(frame * 2)) / 32768.0 * gain
```

The visualiser adds the windows:

```gdscript
_summed_samples[i] += values[i]
```

The gain is fixed: one signal unit becomes 0.15 m of height. The drawn range is limited to ±1 and the readout reports `display limit` if the sampled sum exceeds it. The stored sum remains available for inspection. The picture does not automatically enlarge a fading signal.

This display follows source playback positions, which advance with audio mixing. It is not a microphone at the listener's head and does not include spatial attenuation, bus effects or the output device. The reported ages can differ slightly from the frame-updated glow ages. Watching the ribbon does not replace listening to the overlap.

The striker returns when left more than 0.5 m from its rest, unheld, for three seconds. Its three-part return takes another 0.75 seconds and is excluded from striking. A returning tool should not compose extra notes on its way across the row.

Try the same pair far apart and then overlapping. The pitches can stay fixed while the relation changes through their starting times. That is what the Synthesis Lab inherits: a sum depends on the terms, their levels and where they are in their cycles.

### Wavefunctions_Sky_Stairs

Source: `commons/maps/Wavefunctions_Sky_Stairs/tutorial.md`

# Current hall: what a curve needs from a stair

The primary `sine_cylinder_staircase` builds one helix of eighty treads. With the shipped scene parameters, the tread top rises by 0.11 per sample while the radius is `2.5 + 0.45 * sin(2 * angle)`. The angle completes two turns. This is radial modulation with uniform rise, not three parallel staircases or a sine-shaped height profile.

The default `membrane` provision joins neighbouring tread edges with visible quads and matching colliders, lifted by the configured 0.3 offset. Other source options are `none`, `rail` and `posts`; they change the provision around the same sampled path. The chapter begins with three visible treads inspected from the surrounding floor. Treads and colliders alone do not establish a complete ascent, suitable headroom or headset comfort. `math_objects`, `cube_scene` and `dark_sphere` remain in the hall; their presence does not implement the floating wave-density field described in the earlier proposal. See [the chapter](final.md) and `algorithms/wavefunctions/sine_cylinder_staircase/sine_cylinder_staircase.gd`.

## Archived design proposal

The text below is preserved from an earlier design. Its three staircases, variable-rise climb, altitude chart and wave-density cube fields are proposals, not descriptions of the current hall. Its code is illustrative, not an extract from the shipped artifact. Full walking and headset claims remain unverified.

---

# Sky Stairs

Stairs climb along a sine curve. Build the vertical amphitheater and mount the wave one step at a time.

Declare the staircase.

```gdscript
class_name SineStaircase
extends Node3D

@export var step_count: int = 60
@export var horizontal_span: float = 15.0
@export var amplitude: float = 6.0
@export var frequency: float = 0.25
```

Sixty steps across fifteen horizontal metres. Amplitude peaks six metres above the base line.

Place each step.

```gdscript
func build_steps() -> void:
    for i in step_count:
        var t: float = float(i) / float(step_count)
        var x := t * horizontal_span - horizontal_span * 0.5
        var y := amplitude * sin(TAU * frequency * x)
        var step := preload("res://commons/artifacts/wavefunctions/stair_step.tscn").instantiate()
        step.position = Vector3(x, y, 0.0)
        add_child(step)
```

Each step sits at sine of its x. The staircase is the waveform; walking the staircase is tracing the wave.

Set step sizes.

```gdscript
func size_step(step: Node3D) -> void:
    step.scale = Vector3(0.25, 0.15, 0.6)
```

Narrow and deep. The learner can walk at a normal stride. Depth matters because the wave steepens near peaks.

Tilt the step to the local slope.

```gdscript
func tilt_step(step: Node3D, x: float) -> void:
    var slope: float = TAU * frequency * amplitude * cos(TAU * frequency * x)
    step.rotation.z = -atan(slope * 0.1)
```

Steps tilt into the wave so the walker's foot finds a level top. The tilt is tiny but prevents the feeling of climbing a corrugated roof.

Spawn floating cubes sampling the air.

```gdscript
func populate_cubes() -> void:
    for i in 40:
        var cube := preload("res://commons/artifacts/wavefunctions/float_cube.tscn").instantiate()
        cube.position = Vector3(randf_range(-7, 7), randf_range(0, 12), randf_range(-3, 3))
        add_child(cube)
```

Cubes hang in the air around the staircase. Most are above the wave; some are below. The sample makes the invisible field legible.

Light peaks with a lamp.

```gdscript
func place_peak_lamps() -> void:
    var wavelength: float = 1.0 / frequency
    for i in int(horizontal_span / wavelength) + 1:
        var x: float = i * wavelength - horizontal_span * 0.5
        var lamp := OmniLight3D.new()
        lamp.position = Vector3(x, amplitude + 1.0, 0.0)
        lamp.light_color = Color(1.0, 0.9, 0.6)
        add_child(lamp)
```

Lamps sit above each peak. The learner climbs toward light and descends into cooler air.

Chime on reaching a peak.

```gdscript
func _on_peak_entered(index: int) -> void:
    peak_chime.pitch_scale = 1.0 + index * 0.05
    peak_chime.play()
```

Each peak sounds slightly higher. The climb becomes a melody. Walking is performance.

You have climbed the wave. The next map, TrigWalkingPath, splits sine from cosine into parallel paths.
<<</MAP>>>

### WaveFunctions_TrigWalkingPath

Source: `commons/maps/WaveFunctions_TrigWalkingPath/tutorial.md`

# Current hall: a slow pulse from fast motions

`beat_frequency_demo` is the primary. Its two controls set frequencies from 1 to 10 Hz. The three rows show A, B and half of their raw sum. Close frequencies give a slow envelope; equal frequencies remove the beating in this fixed-phase demonstration. The display is visual only. See [the chapter](final.md) for the encounter and `algorithms/wavefunctions/beat_frequency/beat_frequency_demo.gd` for the implementation.

The secondary `TrigWalkingPath` remains in the room. Its shipped scene creates forty pairs of collidable steps once, adds end platforms, then circulates the two rows in opposite directions. Their heights combine a shared sloping base with sine or cosine. There is no visitor-triggered generation, cross-bridge or linked chart in that source. The other secondary works are `sine_oscillation`, `lissajous_curves` and `wave_interference`; `dark_sphere` remains the reference object. The next hall compares five fixed harmonic frequencies in the Synthesis Lab.

## Archived design proposal

The text below is preserved from an earlier design. Its endless generation, cross-bridge, entrance controls and linked chart are proposals, not descriptions of the current hall. Its code is illustrative, not an extract from the shipped artifact. The current chapter and the source named above take precedence.

---

# Trig Walking Path

Two lanes, 90 degrees out of phase. Build the path that generates itself under the learner's feet.

Declare the path generator.

```gdscript
class_name TrigPath
extends Node3D

@export var lane_spacing: float = 1.5
@export var amplitude: float = 0.8
@export var frequency: float = 0.5
@export var ahead_distance: float = 8.0
```

Two lanes spaced apart. Amplitude is vertical. Ahead distance is how far the path pre-generates beyond the learner.

Sample both lanes at a distance.

```gdscript
func sample_lanes(z: float) -> Array:
    var sin_y: float = amplitude * sin(TAU * frequency * z)
    var cos_y: float = amplitude * cos(TAU * frequency * z)
    return [
        Vector3(-lane_spacing * 0.5, sin_y, z),
        Vector3(lane_spacing * 0.5, cos_y, z),
    ]
```

Sine on the left, cosine on the right. The 90-degree phase difference gives the visual rhythm of the dual path.

Generate new steps ahead of the player.

```gdscript
func extend_path(player_z: float) -> void:
    while last_z < player_z + ahead_distance:
        last_z += 0.4
        var points := sample_lanes(last_z)
        spawn_step(points[0])
        spawn_step(points[1])
```

As the learner walks forward, steps spawn ahead. The path never ends because it is always being drawn in front of them.

Spawn each step.

```gdscript
func spawn_step(pos: Vector3) -> void:
    var step := preload("res://commons/artifacts/wavefunctions/trig_step.tscn").instantiate()
    step.position = pos
    add_child(step)
    steps.append(step)
```

Each spawned step is tracked for despawn. The steps are small floating plates. The learner steps from one to the next.

Despawn steps behind.

```gdscript
func cull_behind(player_z: float) -> void:
    steps = steps.filter(func(s):
        if s.position.z < player_z - 5.0:
            s.queue_free()
            return false
        return true
    )
```

Old steps free themselves. Memory stays low. The path is finite at any moment but infinite over time.

Label each step with its angle.

```gdscript
func label_step(step: Node3D, z: float) -> void:
    var label: Label3D = step.get_node("Label3D")
    label.text = "θ = %.2f" % (TAU * frequency * z)
```

Each step carries its angle. The learner can read their position in the waveform by looking down.

Colour the lanes differently.

```gdscript
func tint_lanes() -> void:
    for step in steps:
        var is_left: bool = step.position.x < 0.0
        var mat := step.get_node("MeshInstance3D").material_override as StandardMaterial3D
        mat.albedo_color = Color(0.4, 0.7, 0.9) if is_left else Color(0.9, 0.6, 0.3)
```

Sine lane cool, cosine lane warm. The colour lets the learner cross-reference the phase without checking numbers.

You have walked the two fundamentals. The next map, Synthesis Lab, stacks harmonics until any waveform appears.
<<</MAP>>>

### WaveFunctions_Synthesis_Lab

Source: `commons/maps/WaveFunctions_Synthesis_Lab/tutorial.md`

# Five amounts and one shared phase

AirMusic gave each struck bar its own beginning. Synthesis Lab gives five components one phase and asks what their amounts can make together. The primary is `additive_wave_demo`, a visual instrument. It does not render these curves to an audio stream. All code excerpts below come from `commons/artifacts/additive_wave_demo/additive_wave_demo.gd`.

## Take the assembled shape apart

Press HOLD to stop the display's drift. Lower H2 through H5 and compare the remaining row with the pale sum. H1 ALONE performs that removal together; BASELINE restores the five arrival coefficients. These buttons preserve the current held phase. H1 ALONE keeps H1's current amount, restoring it to one only if it was below 0.01.

The state begins as five coefficients. The map then selects the sawtooth preset:

```gdscript
var harmonic_amplitudes: Array[float] = [1.0, 0.0, 0.0, 0.0, 0.0]
```

```gdscript
_set_amplitudes([1.0, 0.5, 0.333, 0.25, 0.2])
```

At a chosen phase, each coefficient scales one sine. The harmonic index selects how many returns it makes in a cycle:

```gdscript
func _calculate_wave_value(phase: float) -> float:
    var value = 0.0
    for h in range(harmonic_amplitudes.size()):
        value += harmonic_amplitudes[h] * sin(phase * (h + 1))
    return value
```

Raise H2 again. At the amber mark, predict whether it adds or subtracts from the total before reading the plate. A coefficient is nonnegative, but its sine can be above or below zero. Addition can therefore lower the sum.

## One position, several rates

The drawing evaluates 256 samples across two metres and four cycles:

```gdscript
var t = float(i) / (WAVE_POINTS - 1)
var x = (t - 0.5) * WAVE_LENGTH
var phase = t * TAU * 4.0 + _time * TAU
```

The combined wave is drawn at 0.30 m per signal unit. The ladder uses 0.20 m per unit and separates the rows vertically:

```gdscript
return Vector3(x, y * 0.2 - 0.35 - h * 0.15, 0.1)
```

Adding literal screen heights would also add the offsets. Read the values at the shared mark instead. The `overlay` source configuration uses the sum's scale and axis; there is no visitor mode selector on this placed bench.

The clock moves only when the display is not held:

```gdscript
if not held:
    _time = fmod(_time + delta * base_frequency, 1000.0)
```

Multiplying the whole phase by `h + 1` keeps the components related as the picture scrolls. There are no separate phase controls, signed coefficients, constant offset or harmonics above five. This finite family is useful without containing every periodic shape. The older source preset ID `triangle` keeps its positive odd 1/n² coefficients; the label now names that mix. A triangle series with this sine orientation would require alternating signs, which these sliders cannot supply.

In this hall, read the amounts and compare the rows before naming the recipe. `name_after_compare:true` leaves the preset name at `ARRIVAL RECIPE` until H1 ALONE or BASELINE is used; HOLD does not reveal it. After a manual edit it instead says `COMPARE THE SUM`. Those invitations do not change the coefficients or their drawing.

## The slider and the name are different operations

Moving a real slider updates its own coefficient from the handle position:

```gdscript
harmonic_amplitudes[harmonic_index] = harmonic_sliders[harmonic_index].get_normalized_value()
```

The geometry uses that value. The recipe label compares all five amounts relative to H1:

```gdscript
for h in range(NUM_HARMONICS):
    if absf(harmonic_amplitudes[h] / first - float(recipe[h])) > RECIPE_TOLERANCE:
        return false
```

`RECIPE_TOLERANCE` is 0.025. At H1 = 1, moving H5 from the sawtooth's 0.20 to 0.22 retains the name; 0.24 leaves it. Scaling every coefficient together preserves the ratios. An all-zero state gets its own label, and any single nonzero harmonic is a sine. A new name does not change the accumulation loop.

## A contribution can leave the picture first

Component ribbons disappear below amplitude 0.01. The formula label rounds to one decimal place and omits small terms; the housed readout rounds to two decimals. The sum continues using the stored coefficients. Its marker readout compares the sum of visible rows with the full sum, reporting inequality when their difference exceeds 0.005. Display precision and signal state are distinct.

With the arrival coefficients, the finite sum rounds the ideal sawtooth's jump and ripples along its descent. The current capture spans about 0.086 m from trough to the following crest in a 0.5 m cycle. That is a measurement of this sampled, five-term construction. It does not measure all possible settings or give the sum a universal amplitude ceiling.

Hold a phase, alter the five amounts, then restore BASELINE. The shape returns at that phase. Release HOLD and the phase continues; BASELINE restores coefficients without rewinding time. The next hall, Random_Definition, asks which other state must be retained for a result to return.

## A companion you can hear: Slow Circuits

The ambient console at (4,6) is independent of the coefficient bench. Press PLAY and wait for the two voices to prepare. Three clocks propose notes at different intervals. DENSITY decides how often a proposal sounds; the scale limits which pitches it can become. Lower density before adding more SPACE: does the silence stay empty, or does a previous note inhabit it?

WARMTH lowers the filter cutoff. DRIFT deepens a 29-second modulation; LFO ROUTE moves it between filter and stereo position. RATE changes the three clocks together. NEW SEED changes future choices; stopping and starting with the same seed and unchanged controls reproduces the event sequence. The drawn output is captured sound. The fixed cables explain the patch; they are not loose plugs.

The synthesis comes from `DiscreetAudioGenerator` and `FMPianoGenerator`, prepared once through `AsyncAudioGenerator`. The console schedules at most eight finite voices. Excess requests are skipped. The room can keep an echo without accumulating an unlimited number of bodies.

---

## 10. Randomness: What Can Chance Change?

### Random_Definition

Source: `commons/maps/Random_Definition/tutorial.md`

# Make a colour return

In the room, a seed helped us recover a colour arrangement. Here we will make that return ourselves: give one cube a generated colour, repeat it, then change the result without changing the seed.

This builds on `_ready()` from Point Zero, arrays and loops from Array, and material colour from Colour. The new tool is a local `RandomNumberGenerator`. We borrow its internal algorithm, just as we borrow the renderer. What we will control is when it draws and what those draws become. Random Entropy will ask what remains when we count the values instead of keeping their arrangement.

Use the [standalone study](/book-review/doc/book/iterations/2026-09-30-random-definition-making/random-definition-study.zip), with Day Zero's editor and run workflow already in place. Work in `study.gd`; keep `study.tscn` as the main scene. `display.gd` supplies the cubes, one material per cube and a REPLAY button. It does not request random values. Each numbered file in `steps/` is a complete version you can copy into `study.gd` if you lose your place.

## 1. Give one cube three values

The project opens at this first step. Its complete script is:

```gdscript
extends Node3D

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	$Display.build(1, false)
	replay()

func replay() -> void:
	var cube: MeshInstance3D = $Display.left[0]
	var material: StandardMaterial3D = cube.material_override
	var a := rng.randf()
	var b := rng.randf()
	var c := rng.randf()
	material.albedo_color = Color(a, b, c)
```

`$Display.build(1, false)` asks the supplied display for one cube and no second grid. The cube is the first member, `[0]`, of its `left` array. `material` refers to that cube's own material. These are the things already prepared for us; the three calls to `rng.randf()` are our new work.

Each call returns one number between zero and one. `Color(a, b, c)` assigns them to red, green and blue, in that order. Press REPLAY or Space. The helper calls `replay()` again; the generator continues from where the previous calls left it. Repetition is possible, but we have given it no instruction to recover a chosen colour.

## 2. Give the return a beginning

Add this variable beside `rng`:

```gdscript
var seed_value := 42
```

Then make this the first line inside `replay()`:

```gdscript
rng.seed = seed_value
```

Press REPLAY several times. Nothing appears to happen, although the code has requested three values again. Setting the seed puts this generator back at the same beginning. Change `42` to `137` and run again. Keep a colour you like by keeping its seed and this procedure. The complete version is `steps/02-seed.gd`.

## 3. Let the array receive the sequence

Change the display request to `$Display.build(4, false)`. It now gives us a 4 × 4 grid. In `replay()`, keep the seed reset once at the start, then colour each cube:

```gdscript
rng.seed = seed_value
for cube in $Display.left:
	var a := rng.randf()
	var b := rng.randf()
	var c := rng.randf()
	var colour := Color(a, b, c)
	var material: StandardMaterial3D = cube.material_override
	material.albedo_color = colour
```

The loop reuses Array's ordered collection. Three draws per cube, sixteen cubes: forty-eight values receive a place. The supplied display orders cubes left to right, bottom row first, as the museum instrument does. REPLAY keeps the arrangement. The complete version is `steps/03-grid.gd`.

Try moving the seed reset inside the loop, just before `var a`. Every cube now starts at the same three values. Move the reset back outside. Its position changes the pattern without changing the seed.

## 4. Put two beginnings beside each other

Use `steps/04-pair.gd`. Its display request is `$Display.build(4, true)`. The same colouring loop is now a function called `colour_grid(cubes)`. `replay()` calls it once with the left array and once with the right:

```gdscript
colour_grid($Display.left)
colour_grid($Display.right)
```

The function resets the generator **before each grid**. Check the same cell on both sides. Press REPLAY and check another. If we reset only once before both grids, the right would continue after the left's forty-eight draws. Equal seeds are useful here because we also keep the requests and their assignment equal.

## 5. Spend one value without colouring anything

Use `steps/05-unused-draw.gd`. A `skip_first` argument tells `colour_grid` whether to make this extra request, after resetting the seed and before entering the cube loop:

```gdscript
if skip_first:
    rng.randf()
```

`replay()` passes `false` for the left grid and `true` for the right. The left uses forty-eight draws; the right consumes forty-nine but still gives forty-eight to its colours. REPLAY now recovers the difference too.

Follow the first cube: the left takes `(a, b, c)`; the right takes `(b, c, d)`. No value has changed its position in the generated stream. A different part of that stream is being assigned to each channel.

## 6. Keep the draws. Change their roles.

Return to the matched pair from step 4, removing the unused draw. This time keep both beginnings equal and swap the right grid's red and blue assignments. `steps/06-channel-roles.gd` is the complete version. Its loop first constructs:

```gdscript
var colour := Color(a, b, c)
```

Then, only for the right grid:

```gdscript
if swap_channels:
    colour = Color(c, b, a)
```

Find a cube with visibly different red and blue amounts. Its green stays the same. Both grids consumed the same forty-eight values. We changed what a value does, without requesting another one.

Choose which comparison you want to keep. Then replace the right-hand assignment with `Color(a, a, a)`: one requested value now supplies all three channels. The other two requests remain in the loop, so later cells still begin at the same place in the stream.

You now have a small construction you can alter: a generator, a repeatable beginning, an ordered array and a choice about what each value becomes. The colour grids are one use of those parts. Their arrangement no longer has to exhaust what the program can do.

## Beside this lesson

The museum has 8 × 8 grids and twenty-four-draw bar strips; this study uses 4 × 4 grids so individual cells stay easy to compare. Both use Godot's generator and the same reset → request → assign order. The bars show a short prefix, not evidence from which to infer the generator's period. Godot documents reproducible seeded sequences but treats the underlying algorithm as an implementation detail: keep the engine version with a study you need to reproduce.

[Technical companion](/book-review/commons/maps/Random_Definition/technical.md): current placement, controls, state restoration and implementation references. [Godot's generator reference](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html).

### Random_Entropy

Source: `commons/maps/Random_Entropy/tutorial.md`

# Keep the counts, change the neighbours

Random_Definition made repeatability depend on a seed and a procedure. Random_Entropy takes another seeded sequence and asks what its measurement retains. The primary is `shannon_entropy_meter:90#stand:ledger#disclosure:ledger` at (5,6). All excerpts below come from `commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd`.

## Read two records of the same sample

Find a pair among the 200 tiles on the desk. The first forty are marked there, spelled out on the upper panel, and shown enlarged on the front face. The enlarged excerpt stays in draw order even when SORT regroups the upper ribbon. It is an excerpt of the active sample, not another sample.

The opening sequence is drawn once from a local seeded generator:

```gdscript
for i in range(sequence_length):
    sequence.append(_rng.randi_range(0, num_symbols - 1))
```

The map uses ten symbols and 200 draws. The default seed is `hash("shannon_entropy")`, exposed in the source readout. These draws are independent of the previous hall's RGB generator. The continuity between rooms is the question of procedure, not a transfer of that room's colours into this meter.

## Sort before explaining the invariant

Press SORT and watch both the ribbon and the bars. The tiles move into symbol groups over 1.2 seconds. Their counts and entropy remain. SORT does not resample or overwrite the original sequence. It changes where the existing tile instances are drawn, using a stable order within each symbol group. Press again to restore their positions.

The sorted copy used by the readout is constructed as follows:

```gdscript
func sorted_copy() -> Array[int]:
    var out: Array[int] = []
    for sym in range(num_symbols):
        for i in range(_sequence.size()):
            if _sequence[i] == sym:
                out.append(sym)
    return out
```

The measurement visits one symbol at a time:

```gdscript
for s in sequence:
    counts[s] += 1
```

Every permutation of this sample gives the same counts. The entropy loop receives those counts, without the positions:

```gdscript
for c in counts:
    if c > 0:
        var p: float = float(c) / float(sequence_length)
        entropy -= p * (log(p) / log(2.0))
```

Each observed share p weights its own information value, −log₂(p). The result is an average in bits per symbol under these empirical shares, not the total information in a 200-symbol message. Zero-count terms contribute zero and are skipped before the logarithm. An all-one-symbol sample gives zero. Twenty copies of each of ten symbols give log₂(10), about 3.321928. The arrival sample gives approximately 3.255647 because its counts differ from twenty each.

SORT can make groups easier to find without changing this number. A repeating cycle of ten symbols can also have maximum marginal entropy. The loop does not condition a prediction on the previous symbol. It therefore cannot measure every kind of predictability, dependency, meaning or compressibility in the ordered sequence.

## Change the source, keeping the alphabet and N

CONTRAST selects a cached second sample with its own seed, the first seed plus one. Its source weights decrease by a factor of two:

```gdscript
for k in range(num_symbols):
    weights.append(pow(2.0, -float(k)))
```

A local generator draws against their cumulative sum. The normalized source probabilities are approximately 0.50049, 0.25024, 0.12512, and so on. They imply expected counts; they do not impose those counts on a finite sample. The captured sample has counts [109,46,20,17,6,2,0,0,0,0] and H ≈ 1.817600. CONTRAST again restores the original 200 draws. The current sorting choice is retained.

## Ask the display what its heights mean

The upper bars use a height relative to the largest count in the active sample:

```gdscript
var height: float = (float(counts[i]) / float(max_count)) * FREQ_BAR_HEIGHT if max_count > 0 else 0.0
height = max(0.002, height)
```

The largest bar is 0.10 m tall whether its count is 31 or 109. Four zero counts in the concentrated sample still get 0.002 m marks. These choices make the marks visible and fit each histogram into the panel. They prevent direct comparison of absolute counts by height across samples. The desk prints the counts so the reader can check the scaling.

## Disclose a model after observing its sample

DISCLOSE moves through ledger → works → origin → oracle → tally → ledger. Works reveals the formula. Origin names the generator and seed and adds pale expected-count bars from the active source: 20 each for the uniform law; approximately [100.1,50.0,25.0,12.5,6.3,3.1,1.6,0.8,0.4,0.2] for the concentrated law. The ghosts share the sample's vertical scale, are capped at its maximum display height, and have the same 2 mm minimum. Small positive expectations and zero observed counts may therefore have the same drawn height.

Oracle withholds the upper panel's supporting displays. It does not remove the desk's tiles, excerpt or readout. The source is still available elsewhere in the installation. Repeated disclosure changes rebuild the upper panel once while keeping the desk, sorting state and the selected built-in sample consistent.

The next hall, Random_Remove, makes selection spatial. Before a random choice removes a cell, another rule has already decided which cells are eligible.


## Spatial staging — 16 September 2026

The map keeps a reachable instrument alongside its spatial applications. `map_data.json` is authoritative for placements. `#controls:compact` gathers the existing Rack panels, preserving their callbacks, into an 80 cm console. `#glass_width` opts into an enclosure with open entrances; its grid marks are not floor colliders.


<!-- study-spine:signal_room -->

## Return: Different neighbours

Shuffle the retained values; compare unchanged counts with changed neighbours. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses array, random. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`signal`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-signal-room/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:signal_room -->

### One source change: Different neighbours

Call this on the supplied signal_room component. Mode 2 permutes cells with a repeatable seed. Compare values.count(1) and the neighbour-change readout before and after; then try another seed.

```gdscript
set_pattern(2, 2026)
```

Source: `commons/artifacts/signal_room/signal_room.gd`. Use the prepared scene to run and compare.

### Random_Remove

Source: `commons/maps/Random_Remove/tutorial.md`

# The set before the choice

Random Definition gave us a procedure that can return. Random Entropy showed what counting leaves out. At this bench, look first for a cube whose chance of removal is zero.

## Find the boundary before drawing

Sixteen amber cubes form a 4×4 range, columns 2–5 and rows 2–5. Forty-eight grey cubes stand outside it. Read the set on the cased plate to the left. Use REMOVE ONE on the right: one candidate becomes red for 0.3 seconds, then disappears while its address plate remains.

Follow a grey cube through several removals. Its exclusion comes from the filter in `algorithms/randomness/RemoveRandom.gd`:

```gdscript
	match selection_mode:
		"All": return true
		"Column": return is_equal_approx(pos.x, float(target_column))
		"Row": return is_equal_approx(pos.z, float(target_row))
		"Range":
			return pos.x >= x_min and pos.x <= x_max and pos.y >= y_min and pos.y <= y_max and pos.z >= z_min and pos.z <= z_max
```

These coordinates belong to the explicit grid. Its instances sit at integer x/z addresses, then the whole MultiMesh is scaled by 0.14 and placed on the table. Row 3 stays row 3 when the museum turns the bench.

The candidate list keeps the permitted indices, skipping earlier removals:

```gdscript
		if _removed.has(i):
			continue
		var included := _should_include_instance(_original[i].origin)
		if included:
			active_instances.append(i)
```

## Draw within the remaining set

Only the remaining candidates reach the draw:

```gdscript
	var offset := _rng.randi_range(0, active_instances.size() - 1)
	var index := active_instances[offset]
```

On the first RANGE draw there are sixteen possible offsets. Next time there are fifteen. A cube that survives has a changing chance on the next press: 1/16 initially, then 1/15 if it remains. The forty-eight excluded cubes keep chance zero throughout this run. Exhausting the set removes every candidate exactly once, so randomness determines the order while the initial range determines the final empty shape.

The selected cube goes red. After the delay, a valid pending operation scales its transform to zero and removes its index from the candidate list:

```gdscript
	transform.basis = Basis().scaled(Vector3.ZERO)
	multimesh.set_instance_transform(index, transform)
	_removed[index] = true
	active_instances.remove_at(offset)
```

The slot plate and board remain. This operation does not remove museum floor or create a traversable pit. The original transforms remain in memory for RESET.

## Replay a procedure, then change a rule

RESET restores all transforms and, on this bench, resets the private removal generator:

```gdscript
	if replay_on_reset:
		_rng.seed = run_seed
```

Compare ROW and COLUMN under the same seed. Both start with eight candidates, so they use equal bounds on every draw and choose equal offsets in their respective lists. One set runs across row 3; the other down column 3. Their counts agree while their available places differ.

RANGE and ALL have sixteen and sixty-four candidates. The draw bounds now differ, so the same seed is insufficient to claim the same offsets. NEW SEED picks a five-digit value through the fixture and resets. A repeated seed is possible. The bench exposes the chosen value but has no seed-entry control.

## What waits, and what is cancelled?

There is no START or STOP button on this fixture. The remover has a timer API; this bench uses one press per removal. Waiting between completed removals does not consume removal draws. During the red highlight a second REMOVE ONE press is ignored. RESET or a mode change invalidates the pending operation:

```gdscript
	if generation != _generation or not is_inside_tree():
		return
```

The older draw cannot return from its delay and erase a cube in the new run. That small guard is part of what makes a reset mean a beginning.

Keep an unfinished pattern before resetting. Its visible gaps preserve some of the history that a completely emptied range would lose. Random Walk will make each choice alter where a body goes and which choices are available next.


## Spatial staging — 16 September 2026

The map keeps a reachable instrument alongside its spatial applications. `map_data.json` is authoritative for placements. `#controls:compact` gathers the existing Rack panels, preserving their callbacks, into an 80 cm console. `#glass_width` opts into an enclosure with open entrances; its grid marks are not floor colliders.

`random_removal_arena` uses the existing owned-set `RemoveRandom` algorithm and one collider per cell. Entry and accumulated walking request draws; a reset restores both drawings and support. The basin fire uses the museum death/respawn path.

### Randomness_10_PRINT_Algorithm

Source: `commons/maps/Randomness_10_PRINT_Algorithm/tutorial.md`

# 10 PRINT Algorithm

One coin flip per cell, infinite visual structure. Build the maze from the simplest random choice.

Declare the maze grid.

```gdscript
class_name TenPrintMaze
extends Node3D

@export var rows: int = 20
@export var cols: int = 20
@export var cell_size: float = 0.4
```

Three numbers. Two for extent, one for cell size. The algorithm needs nothing else.

Flip a cell.

```gdscript
func flip_cell() -> String:
    if randi() % 2 == 0:
        return "/"
    return "\\"
```

A single coin flip returns one of two slashes. The entire maze grammar is this function.

Spawn the slash.

```gdscript
func spawn_slash(x: int, y: int, kind: String) -> void:
    var scene := preload("res://commons/artifacts/randomness/maze_slash.tscn")
    var slash := scene.instantiate()
    slash.position = Vector3(x * cell_size, 0.0, y * cell_size)
    slash.rotation.y = deg_to_rad(45.0 if kind == "/" else -45.0)
    add_child(slash)
```

Each cell gets a diagonal bar. The two rotations produce the two slashes. The mesh is one plank used twice.

Build the full maze.

```gdscript
func build_maze() -> void:
    for x in cols:
        for y in rows:
            spawn_slash(x, y, flip_cell())
```

400 cells, 400 flips, 400 bars. The maze completes in one frame.

Animate the build.

```gdscript
func animate_build() -> void:
    var i := 0
    while i < cols * rows:
        var x := i % cols
        var y := i / cols
        spawn_slash(x, y, flip_cell())
        i += 1
        await get_tree().create_timer(0.01).timeout
```

A coroutine paces the build. The learner watches the maze emerge one cell at a time. Emergence is performed.

Reseed to replay.

```gdscript
func reseed(new_seed: int) -> void:
    seed(new_seed)
    _clear()
    build_maze()
```

A new seed gives a new maze. The learner can compare two mazes drawn from two seeds.

Measure path length.

```gdscript
func count_paths_hint() -> int:
    return cols * rows
```

The maze always has as many segments as cells. Path lengths and connections vary by seed. Counting is left as a small exercise.

Overlay a grid for reference.

```gdscript
func draw_grid() -> void:
    for x in cols + 1:
        grid_lines.add_line(Vector3(x * cell_size, 0, 0), Vector3(x * cell_size, 0, rows * cell_size))
    for y in rows + 1:
        grid_lines.add_line(Vector3(0, 0, y * cell_size), Vector3(cols * cell_size, 0, y * cell_size))
```

A faint grid underlies the slashes. The coin flip becomes visible as choice over structure.

You have generated infinite pattern from one flip. The next map, Random Cubes, turns randomness onto objects.
<<</MAP>>>

Expose the flip bias.

```gdscript
func set_bias(p: float) -> void:
    bias = clamp(p, 0.0, 1.0)

func flip_cell_biased() -> String:
    return "/" if randf() < bias else "\\"
```

A bias slider tilts the coin. At 0.5 the maze is symmetric. At the extremes the maze degenerates into a single diagonal.

### Random_Cubes

Source: `commons/maps/Random_Cubes/tutorial.md`

# Random Cubes

Each cube remembers its coin flips. Build the arena where form encodes chance.

Declare the random cube.

```gdscript
class_name RandomEdgeCube
extends Node3D

@export var edge_chance: float = 0.5
var edge_profile: PackedInt32Array = PackedInt32Array()
```

A cube has 12 edges. Each edge is flipped on or off by a chance. The profile records the result.

Flip the edges.

```gdscript
func flip_edges() -> void:
    edge_profile.clear()
    for i in 12:
        edge_profile.append(1 if randf() < edge_chance else 0)
```

Twelve flips per cube. Each flip decides whether that edge is beveled, hollowed, or plain. The profile is the cube's signature.

Build the cube mesh from the profile.

```gdscript
func build_mesh() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in 12:
        if edge_profile[i] == 1:
            _add_beveled_edge(st, i)
        else:
            _add_plain_edge(st, i)
    mesh_instance.mesh = st.commit()
```

The mesh assembles from per-edge rules. Beveled edges get a small chamfer; plain edges stay sharp. The visual is the profile made stone.

Place a field of cubes.

```gdscript
func populate_field() -> void:
    for x in 6:
        for y in 6:
            var cube := preload("res://commons/artifacts/randomness/random_edge_cube.tscn").instantiate()
            cube.position = Vector3(x * 1.5, 0.0, y * 1.5)
            cube.flip_edges()
            cube.build_mesh()
            add_child(cube)
```

36 cubes, 36 unique profiles. No two cubes match. The grid makes differences legible side by side.

Highlight the current cube on inspection.

```gdscript
func highlight(cube: Node3D, active: bool) -> void:
    cube.material_override.emission = Color.WHITE if active else Color.BLACK
    cube.material_override.emission_energy_multiplier = 0.3 if active else 0.0
```

Inspection tints the cube. The learner can see which one they are reading.

Readout the profile.

```gdscript
func readout(cube: RandomEdgeCube, label: Label3D) -> void:
    label.text = "profile: " + str(cube.edge_profile)
```

A label shows the 12-bit profile beside the cube. The number is the cube; the cube is the number.

Offer a dice throw.

```gdscript
func _on_dice_thrown(face: int) -> void:
    edge_chance = float(face) / 6.0
    for cube in cubes:
        cube.flip_edges()
        cube.build_mesh()
```

Throwing a die changes the edge chance for the whole field. The population responds to a single roll. Randomness scales.

You have seen form encoding chance. The next map, Random Rotate, moves randomness into three axes.
<<</MAP>>>

Save a profile to disk.

```gdscript
func save_profile(cube: RandomEdgeCube, slot: int) -> void:
    UserSettings.set_value("cubes/slot_%d" % slot, cube.edge_profile)
```

Any profile can be saved and reloaded later. Randomness becomes archivable.

More rolls produce more varied profiles. The field reads richer over time.

### Random_Rotate_Random_XYZ

Source: `commons/maps/Random_Rotate_Random_XYZ/tutorial.md`

# Random Rotate Random XYZ

Three axes, three independent rolls. Build the orientation generator that proves 3D randomness is qualitatively different.

Declare the triple roll.

```gdscript
class_name TripleRoll
extends Node3D

var x_angle: float = 0.0
var y_angle: float = 0.0
var z_angle: float = 0.0
```

Three angles, three floats. Each is rolled independently.

Roll all three.

```gdscript
func roll() -> void:
    x_angle = randf() * TAU
    y_angle = randf() * TAU
    z_angle = randf() * TAU
    rotation = Vector3(x_angle, y_angle, z_angle)
```

Three calls to randf, three assignments. The resulting orientation is almost never anything the learner would predict.

Animate a continuous roll.

```gdscript
func _process(dt: float) -> void:
    if auto_roll:
        x_angle += randf_range(-1.0, 1.0) * dt
        y_angle += randf_range(-1.0, 1.0) * dt
        z_angle += randf_range(-1.0, 1.0) * dt
        rotation = Vector3(x_angle, y_angle, z_angle)
```

Auto-roll adds noise to the angles each frame. The object tumbles irregularly. No two frames share an orientation.

Expose axis buttons.

```gdscript
func _on_axis_button_pressed(axis: String) -> void:
    match axis:
        "x": x_angle = randf() * TAU
        "y": y_angle = randf() * TAU
        "z": z_angle = randf() * TAU
    rotation = Vector3(x_angle, y_angle, z_angle)
```

Three buttons let the learner reroll one axis at a time. The other two stay put. The interaction isolates each axis.

Sample from hardware entropy.

```gdscript
func hardware_roll() -> float:
    var t := Time.get_ticks_usec()
    return float((t ^ (t >> 7)) & 0xffff) / float(0xffff) * TAU
```

Hardware entropy replaces the PRNG. Same shape, different source. The method swaps cleanly.

Record the roll history.

```gdscript
func log_roll() -> void:
    rolls.append(Vector3(x_angle, y_angle, z_angle))
```

The log stores each orientation. A small panel plots the history as a scatter of rotated arrows.

Show the Euler angles.

```gdscript
func readout_euler(label: Label3D) -> void:
    label.text = "X: %5.1f°\nY: %5.1f°\nZ: %5.1f°" % [
        rad_to_deg(x_angle), rad_to_deg(y_angle), rad_to_deg(z_angle)
    ]
```

The readout shows degrees. Three independent numbers describe the orientation. The tutorial refuses to collapse them into one.

You have seen randomness expand into three dimensions. The next map, Random Walk, turns randomness into a path.
<<</MAP>>>

Save the current orientation as a preset.

```gdscript
func save_preset(name: String) -> void:
    presets[name] = Vector3(x_angle, y_angle, z_angle)
```

Presets capture a favourite orientation. The learner can return to a surprise they liked.

Animate between presets.

```gdscript
func tween_to_preset(name: String) -> void:
    if not presets.has(name): return
    var target: Vector3 = presets[name]
    create_tween().tween_property(self, "rotation", target, 0.8)
```

A tween smoothly rotates from the current angle to the preset. The transition reads as a handwritten arc.

### Random_Walk

Source: `commons/maps/Random_Walk/tutorial.md`

# Random Walk — draw, fold, keep

The primary is `random_walk_terrarium:90#stand:logbook` at map cell (4,1). Read the final passage as the encounter; use this chapter to follow the implementation. All GDScript excerpts are from `commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd`.

## What the previous rooms supply

Coordinates locate the bead, a vector proposes its displacement, an array keeps sampled positions, and repeated addition accumulates movement. Random Remove asked which addresses a draw could choose. This room asks what follows when the choice changes a position and the enclosure then corrects it.

## Try the rule before naming it

Follow red under ONE. Predict a direction, then compare 2D and 3D. Move around a suspected crossing. Try LEVY last. The cabinet has no pause control; mode changes and RESET restart the run. The logbook wing offers ONE, ALL and NEW SEED.

## Draw a heading

```gdscript
		WalkMode.WALK_2D:
			var angle = _rand() * TAU
			return Vector3(cos(angle), 0, sin(angle)) * step_size
```

One draw chooses an angle in the xz plane. The proposed length is 0.015 m and the y increment is zero. In 3D two draws produce a uniformly sampled direction on the sphere:

```gdscript
			var theta = _rand() * TAU
			var phi = acos(2.0 * _rand() - 1.0)
			return Vector3(
				sin(phi) * cos(theta),
				sin(phi) * sin(theta),
				cos(phi)
			) * step_size
```

Here theta is the xy azimuth and z is the polar coordinate. Do not describe this as adding a y component to an unchanged 2D path. The draw consumption also changes: one, two or three draws per walker per step in 2D, 3D or LEVY. All five walkers share this private generator in a fixed order.

LEVY uses the same 3D direction construction, then draws a length:

```gdscript
			var u = _rand()
			var levy_step = step_size * pow(u + LEVY_OFFSET, LEVY_EXPONENT)
			levy_step = minf(levy_step, step_size * LEVY_STEP_CAP)
			return direction * levy_step
```

With offset 0.01 and exponent −0.5, the proposed lengths range from approximately 0.01493 to 0.15 m. The power already bounds the maximum at ten base steps. Under an ideal uniform draw, length > 0.10 m corresponds to u < 0.0125: about one in eighty. This is a bounded power-law rule; it does not instantiate an unbounded Lévy process or a full physical model of Brownian motion.

## The enclosure participates

```gdscript
	if pos.x < -half.x: pos.x = -half.x + (-half.x - pos.x)
	if pos.x > half.x: pos.x = half.x - (pos.x - half.x)
```

The box spans x,z = −0.25..0.25 and y = 0..0.4. An endpoint past a wall folds back by its overshoot. Under 2D, y is pinned to 0.2. With these defaults, even the 0.15 m maximum proposal is shorter than the smallest half-extent, so the single reflection per side suffices. Arbitrary larger configuration values would need a separate boundary review.

The accepted increment may differ from the proposal. The connected trail is a chord between accepted samples, not a collision path that includes the wall-contact point. After reflection, even fixed-length proposals can yield shorter displayed segments.

## Keep an ordered window

```gdscript
		_walker_trails[i].append(_walker_positions[i])
		if _walker_trails[i].size() > trail_length:
			_walker_trails[i] = _walker_trails[i].slice(1)

		_walker_positions[i] = new_pos
```

The default trail keeps 200 positions before their updates. At step N it contains positions max(0,N−200)..N−1; the bead is at N. No trail term appears in the generator or boundary rule. A controlled test can delete this history and continue the same positions. That is an internal test, not an eraser control offered to the visitor.

## Distinguish step time from frame time

```gdscript
	var interval = 1.0 / maxf(steps_per_second, 0.001)
	_step_timer = minf(_step_timer + delta, interval * MAX_CATCHUP_STEPS)

	while _step_timer >= interval:
		_step_timer -= interval
		_step_all_walkers()
```

The cadence is 30 step batches per second, with five walkers advanced in each batch. A two-second frame accepts five batches and discards the excess time. The logbook's frame clock still gains two seconds; the simulation-time field gains 5/30 seconds. No backlog remains to be recovered in later frames.

## Replay a procedure

```gdscript
	if walk_seed >= 0:
		if _rng == null:
			_rng = RandomNumberGenerator.new()
		_rng.seed = walk_seed
```

RESET restores the centre positions, clears trails and counters, and re-seeds this room's generator. It does not clear the residual step timer or logbook refresh accumulator. Compare equal step counts rather than assuming identical timestamps after reset. The generator implementation, mode, population and draw order must also agree.

NEW SEED explicitly rejects the immediately current number, but can revisit an earlier one. ONE/ALL affects visual emphasis only. The unconfigured artifact uses `walk_seed = -1` and the global stream; resetting it does not rewind that stream. The room's named private seed makes a stronger replay promise.

## Read the measurement

MSD is the average of five squared distances from (0,0.2,0), in square metres. It can rise or fall. The finite box gives bounds of 0.125 m² in 2D and 0.165 m² in 3D/LEVY; these are geometric upper bounds, not promised plateaus. It measures neither total distance travelled nor the complexity of the line.

Next: Random Gaussian. Keep the distinction between a draw, an accumulation and the way a display gathers its evidence.


## Spatial staging — 16 September 2026

The map keeps a reachable instrument alongside its spatial applications. `map_data.json` is authoritative for placements. `#controls:compact` gathers the existing Rack panels, preserving their callbacks, into an 80 cm console. `#glass_width` opts into an enclosure with open entrances; its grid marks are not floor colliders.

### Gallery, basin, field

Following Transformation staging, a 2.5 m basin separates the existing glass field from the gallery. The source floor cuts the moat; it is not a dark decal. Two bridges and the inner apron stay at gallery level. Outer glass rails border the gap, with openings at the bridges. The field retains its existing walk and raised-cell behaviour.

### Random_Gaussian

Source: `commons/maps/Random_Gaussian/tutorial.md`

# Random Gaussian — a sample and its account

The primary is `distribution_sampler:180#stand:cabinet` at (11,19). This builds on Random Walk's distinction between a sampled event and its stored record. The next room, Random Mushrooms, uses sampled parameters to vary forms. All excerpts below are from `commons/artifacts/distribution_sampler/distribution_sampler.gd`.

## Begin with the existing controls

PAUSE toggles new automatic draws. Existing airborne markers still land. CLEAR removes both their records and meshes, resets the counts and re-seeds the current private generator; it preserves the running/paused setting. For an exact comparison, PAUSE then CLEAR, choose a law and press BATCH three times. BATCH lands up to one hundred immediately; the full run reserves capacity at issue time, including draws still in flight, and caps at one thousand.

UNIFORM, GAUSS, POISSON and EXPON each clear when selected. BINS cycles 30 → 60 → 10 → 30 without redrawing stored values. The button marked PAUSE is used again to resume; the readout names running/paused. There is no mean/deviation slider or seed-entry field on the cabinet.

## A uniform number acquires another law

```gdscript
		DistType.UNIFORM:
			return _rand()
```

```gdscript
		DistType.GAUSSIAN:
			var u1 := maxf(_rand(), 0.0001)
			var u2 := _rand()
			var z := sqrt(-2.0 * log(u1)) * cos(TAU * u2)
			return _fit(gaussian_mean + z * gaussian_std)
```

This guarded Box–Muller construction approximates the normal law directly, using two uniform draws per returned value. Mean 0.5 and deviation 0.15 are parameters. Collecting more values does not turn the UNIFORM law into a Gaussian law. The cabinet's expected frames use the ideal model; its finite generator and lower guard remain approximations.

The lower guard is applied before the logarithm. Adding epsilon to every draw, as the previous version did, allowed inputs greater than one inside `log`, making the Gaussian square-root argument negative. It also shifted all valid draws. Clamping only the lower input fixes that domain error while preserving the two-draw consumption. The computed standard-normal component is bounded by sqrt(−2 log(0.0001)) ≈ 4.29193.

POISSON counts repeated products until a threshold is crossed, then rescales its integer result:

```gdscript
		DistType.POISSON:
			var L := exp(-poisson_lambda)
			var k := 0
			var p := 1.0
			while p > L:
				k += 1
				p *= _rand()
			return _fit(float(k - 1) / maxf(poisson_lambda * 3, 0.0001))
```

With λ=5, its displayed values lie at integer multiples of 1/15 before clamping. It is a discrete law, even when its bars suggest a continuous mound. The number of random draws consumed per value varies.

EXPON also guards its logarithm:

```gdscript
		DistType.EXPONENTIAL:
			var u := maxf(_rand(), 0.0001)
			var val := -log(u) / maxf(exponential_rate, 0.0001)
			return _fit(val / 2.0)
```

At rate 3, the ideal displayed tail beyond one has probability exp(−6) ≈ 0.002479. A sample of a thousand need not include it. The numerical guard bounds the raw result at approximately 1.535 before `_fit` clamps it.

## A boundary and an interval

```gdscript
func _fit(raw: float) -> float:
	if raw < 0.0 or raw > 1.0:
		_clipped += 1
	return clampf(raw, 0.0, 1.0)
```

This operation clips rather than reflects. The clipped count concerns issued draws; the bars and edge counts concern landed values. Pause and let the current flight finish before treating them as the same population. Edge bins also contain valid interior values, so their counts are not a count of clipped draws.

A value landing in the histogram uses:

```gdscript
		var bin_idx := int(sample.value * num_bins)
		bin_idx = clampi(bin_idx, 0, num_bins - 1)
```

The value one belongs to the last bin. Landed values are retained as a `PackedFloat32Array`. BINS uses that same stored record to rebuild counts. Under a new partition, the binned mean and deviation can change while the values and number of draws stay fixed.

## Counts, expectation and shape

`expected_counts()` multiplies each ideal-model bin probability by the current landed N. Gaussian and exponential edge probabilities include the model mass beyond the display. Blue bars and pale model bars share the observed-maximum count scale and the 0.01 m baseline. Empty bins still have that baseline.

The orange model curve is divided by its own sampled peak and drawn to 80% of display height. The sign labels it a shape at a separate scale. This keeps it inside the panel; it cannot serve as a count axis. Expected-count frames, rather than the orange line, provide the quantitative comparison.

## What replay keeps

CLEAR resets the named generator and sample timer as well as values, counters and markers. NEW SEED rejects the immediately current number but can revisit an older one. Replaying a law with equal sample count repeats its values in order. Keeping the seed while changing laws changes how draws are consumed. Rebinning is a different operation: no new draw is consumed.

Next: identify which properties of a mushroom a sampled value is allowed to change.


## Spatial staging — 16 September 2026

The map keeps a reachable instrument alongside its spatial applications. `map_data.json` is authoritative for placements. `#controls:compact` gathers the existing Rack panels, preserving their callbacks, into an 80 cm console. `#glass_width` opts into an enclosure with open entrances; its grid marks are not floor colliders.

### Random_Mushrooms

Source: `commons/maps/Random_Mushrooms/tutorial.md`

# Read a population by changing one rule

Build on Random_Gaussian's distinction between a value and the account made from it. Here draws are assigned to construction tasks. Use the six-metre specimen bed and its five buttons; there is no mean/variance slider or live shape morphing control.

1. Choose two apparently related mushrooms. SHOW cycles template 0–5, marks that disc and its field copies. Zero copies is a possible observation. SHOW returns KIND to template selection.
2. Press SIZE. Follow the same instances. Their positions, templates, groups, yaw and ground should remain; their transform scales become 1. Distinct templates retain distinct dimensions. Press again to restore the sampled scales.
3. Press REGROW under the displayed seed. Compare specific instances, not only total count. NEW SEED changes the current seed; earlier numbers may recur.
4. KIND cycles scattered → rings → clusters → rejected → template. Read the current label rather than assuming a fixed number of presses. Accepted plus rejected counts only the eighty scattered candidates. Ring and cluster members are added separately.
5. Inspect the edible mushrooms from the west and south margins. Their pickable/eating behaviour belongs to a separate scene. Headset eating depends on holding one within 0.25 m of the active camera. Desktop carrying does not reach that distance by itself.

## The scale comparison

The scattered-body code evaluates the draw before calling `_size`:

```gdscript
		var scale_factor = _size(0.7 + _rf() * 0.6)  # 0.7 to 1.3
		mushroom.scale = Vector3(scale_factor, scale_factor, scale_factor)
```

```gdscript
func _size(v: float) -> float:
	return v if size_variation else 1.0
```

Taking the draw out would change subsequent generator state. Keeping it and replacing its use preserves the comparison. The ranges differ by construction routine: scattered 0.7–1.3, rings 0.8–1.2, clusters 0.5–1.2. These scale draws are uniform within their respective ranges; the room does not use Gaussian sizing.

## More than one source of draws

```gdscript
func _rf() -> float:
	return _pop_rng.randf() if _pop_rng != null else randf()

func _ri() -> int:
	return _pop_rng.randi() if _pop_rng != null else randi()
```

These helpers serve the templates, placement routines and ground cover. A separate `ground_rng` produces vertex heights, seeded by population seed + 1 unless an explicit ground seed overrides it. NEW SEED uses another temporary generator to choose a seed. `_rf` is not the file's only random call.

## Candidate selection and explicit arrangement

```gdscript
		var pos_x = _rf() * meadow_size - meadow_size / 2
		var pos_z = _rf() * meadow_size - meadow_size / 2
```

These draw candidates in a square. A fixed-count sample filtered by a noise threshold is not a spatial Poisson point process. The `density` parameter multiplies the requested count; the computed `area` variable is unused, so it does not maintain a number per square metre as bed size changes.

```gdscript
	var ring_count = int(meadow_size / 5)
```

```gdscript
	var cluster_count = int(meadow_size / 3)
```

Six metres gives one ring and two clusters. Their members are generated separately, rejected outside the square, and permitted to overlap existing bodies. The plate reports placed membership; requested ring/cluster counts are available in source inspection and the review data.

```gdscript
		var angle = _rf() * PI * 2
		var distance = _rf() * cluster_size
```

Uniform radius is not uniform area: equal-width radial bands receive equal probability while outer bands contain more area. That choice can thicken a cluster near its centre without any attraction between mushrooms.

## Carry the question forward

Template selection is discrete, while scale and yaw vary numerically. SIZE does not interpolate between templates. A proposed future experiment could replace one discrete choice with a shape parameter, but it would need its own implementation and comparison. Random_Game takes the next step in the active route: sampled choices with consequences for an encounter.


## Spatial staging — 16 September 2026

The map keeps a reachable instrument alongside its spatial applications. `map_data.json` is authoritative for placements. `#controls:compact` gathers the existing Rack panels, preserving their callbacks, into an 80 cm console. `#glass_width` opts into an enclosure with open entrances; its grid marks are not floor colliders.

### Arrival stage

`silhouette_arrivals` samples six distinct places without replacement. AUTO waits a seeded 1.5–3.5 seconds between arrivals; ARRIVE advances manually. REPLAY clears the population and restores the placement/timing stream. DRESS changes a separate wardrobe seed, retaining occupied places. The figures use the existing silhouette generator plus sampled collars, hems and pleats. They are non-colliding billboard visitors, not autonomous walking agents. Appearance does not determine hostility. The compact console retains all five touch callbacks.

FORMS toggles `repertoire` between 0 (tailored) and 1 (tailored plus branches). It retains both seeds, arrival RNG state and occupied slots. Branches are drawn after the original garment parameters are sampled, so adding that rule preserves the earlier choices. Switching back recovers the earlier texture. REPLAY retains dress and repertoire while restarting arrivals.

### DNA comparison

Three dream_couture_beast instances use seeds 41,42,43 and head=hare. GARMENT cycles sheath, crinoline, quilted, bloom and fringe with seeds retained. NEXT SEED advances all by three. RESET restores the starting trio. Controls share the compact console.

### Random_Space_Geometry

Source: `commons/maps/Random_Space_Geometry/tutorial.md`

# Random Space Geometry

Space itself becomes stochastic. Build two chambers where random transformations sculpt the arena.

Declare the chamber pair.

```gdscript
class_name ChamberPair
extends Node3D

@export var north_seed: int = 1
@export var south_seed: int = 2
```

Two seeds, two chambers. Each seed determines every random transform applied to its chamber's geometry.

Generate a chamber mesh.

```gdscript
func generate_chamber(seed_value: int) -> ArrayMesh:
    seed(seed_value)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in 120:
        var pos := Vector3(randf_range(-3, 3), randf_range(0, 3), randf_range(-3, 3))
        _add_random_panel(st, pos)
    return st.commit()
```

120 panels placed randomly. The seed ensures reproducibility. A given seed always builds the same chamber.

Add a panel.

```gdscript
func _add_random_panel(st: SurfaceTool, centre: Vector3) -> void:
    var rot := Basis.from_euler(Vector3(randf(), randf(), randf()) * TAU)
    var size := Vector3(randf_range(0.3, 1.2), 0.05, randf_range(0.3, 1.2))
    st.add_triangle_fan([
        centre + rot * Vector3(-size.x * 0.5, 0, -size.z * 0.5),
        centre + rot * Vector3(size.x * 0.5, 0, -size.z * 0.5),
        centre + rot * Vector3(size.x * 0.5, 0, size.z * 0.5),
        centre + rot * Vector3(-size.x * 0.5, 0, size.z * 0.5),
    ])
```

Each panel has a random centre, rotation, and size. The chamber becomes an array of irregular plates.

Connect the chambers by a spine.

```gdscript
func build_spine(from: Vector3, to: Vector3) -> void:
    var segments := 12
    for i in segments:
        var t: float = float(i) / float(segments - 1)
        var pos: Vector3 = from.lerp(to, t)
        pos.y += sin(t * PI) * 0.5
        var seg := preload("res://commons/artifacts/randomness/spine_segment.tscn").instantiate()
        seg.position = pos
        add_child(seg)
```

A gentle arch connects north and south. Walking from one chamber to the other crosses from one random geometry to another.

Render the chamber ceilings.

```gdscript
func place_ceilings() -> void:
    var mesh := generate_chamber(north_seed)
    north_ceiling.mesh = mesh
    south_ceiling.mesh = generate_chamber(south_seed)
```

Each ceiling is the random panel array mounted overhead. The learner looks up and sees a different randomness in each chamber.

Reroll on demand.

```gdscript
func _on_reroll_button_pressed(side: String) -> void:
    if side == "north":
        north_seed = randi()
    else:
        south_seed = randi()
    place_ceilings()
```

A button rerolls one side. The other stays. Comparison becomes live.

Label the seeds.

```gdscript
func label_seeds() -> void:
    north_label.text = "N: seed %d" % north_seed
    south_label.text = "S: seed %d" % south_seed
```

The seeds are visible. Reproducibility is shown, not assumed. Two learners with the same seeds build the same chambers.

You have made space itself stochastic. The next map, Examples of Randomness, surveys randomness across domains.
<<</MAP>>>

### Randomness_Examples_of_Randomness

Source: `commons/maps/Randomness_Examples_of_Randomness/tutorial.md`

# Four uses of a random draw

Read these works by following a sampled value into the operation that consumes it. Their shared use of random numbers does not make their outputs the same kind of process.

## A mark and a path

`algorithms/randomness/proceduralrandomness/movementbased/scenes/pollock2d/paint_dripping_2d.gd` draws into an `Image`. `_add_drip()` samples a position, palette index and radius. `_add_line()` begins at a sampled position and repeatedly turns a direction:

```gdscript
direction = direction.rotated(rng.randf_range(-line_curviness, line_curviness)).normalized()
var next_pos: Vector2 = points[-1] + direction * line_segment_length
```

Boundary checks reflect the direction when a step would leave the canvas. The resulting line segments are rasterized into the image; `stroke_path_generated` also sends their path to the 3D host. In `pollock_painting_in_3d.gd`, the host shows the SubViewport texture on a framed floor sprite and moves a cursor along that path. The gallery token chooses `#support:floor`.

This is a generative homage using marks and paths. There is no falling-paint collision calculation, and the visitor does not steer the cursor.

## A sample that contributes to an estimate

`algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.gd` draws two uniform coordinates in a unit square. `_throw_dart()` classifies the point against an inscribed circle, adds one to the total and, if inside, one to the inside count.

For a uniform square sampler:

`area(circle) / area(square) = pi / 4`

Therefore `4 × inside_count / total_count` estimates pi. An additional point can increase or decrease that estimate; convergence is not a promise of improvement after every throw. Sampling bias changes what the count measures.

The museum token selects `#disclosure:works` and `#controls:compact#control_front:1.0`. `museum_exhibit_stage.gd` relocates the existing button panel to a reachable console while preserving its signals. AUTO toggles continuous sampling; RESET clears the counts without toggling AUTO. Pause AUTO before making a sequence of individual THROW observations. The default maximum is 500 darts.

## A direction admitted by local rules

`algorithms/randomness/pipedream/PipeDream.gd` grows a path in six cardinal directions. `_choose_next_direction()` first gives straight-ahead motion a chance, then tests a shuffled list that excludes immediate reversal. `_is_outside_bounds()` rejects candidate endpoints beyond the configured box.

The default bounds extend ±6 m in x/z and ±4 m in y. Scaling the artifact to 0.25 gives a centreline volume 3 × 2 × 3 m; the pipe and joint radii add a small margin. Lifting its root 1.15 m keeps that volume above the gallery floor. `#residue:path` retains every segment of the run.

There is no occupancy set. The path can revisit earlier positions, and its 180-segment budget does not guarantee full coverage of the box. Changing that rule to reject visited cells would change the set of available choices at every later step.

## An update rule that changes with the chapter

`algorithms/randomness/proceduralrandomness/particlerandomness/extrem_randomness.gd` uses `#chapter:all` to cycle its five existing chapters. `start_demo()` restages the same particles at each transition; their update function then changes.

| Chapter | Procedure |
| --- | --- |
| Chaos | Add random forces to retained velocities, damp velocity and reflect particles at a radial boundary. |
| Noise | Sample a smooth field from the local `noise3()` helper, which is a product of sine and cosine terms rather than an implementation of Perlin noise. |
| Pattern | Combine spiral motion and oscillation with the opening sampled arrangement. |
| Emergence | Apply separation, alignment, cohesion and random nudges. |
| Evolution | Rank distance to a moving target; the leading tenth influence the other particles under the default selection rule. |

The particle count stays fixed. There is no reproduction, no heavy-tail sampler and no basis for interpreting all five chapters as independent uniform draws. The stage is a comparison of procedures, each with different dependencies and retained state.

The gallery token also opts into `#gallery_radius:7`. After restaging and each update, this boundary confines the entire particle sphere and reflects outward velocity. At scale 0.2 its diameter is 2.8 m, and the 1.5 m lift leaves a 0.1 m gap above the floor. The unconfigured artifact keeps its original behavior; the restored gallery is a bounded presentation of all five chapters.

Return to the room's question before entering Random Game: which variables may chance alter, and which constraints keep acting after the draw?

### Random_Pheromone

Source: `commons/maps/Random_Pheromone/tutorial.md`

# Random Pheromone

Each ant walks randomly; the trail it leaves biases the next. Build stigmergy from a floor-grid of pheromone values.

Declare the pheromone grid.

```gdscript
class_name PheromoneGrid
extends Node3D

@export var size: Vector2i = Vector2i(40, 40)
var field: PackedFloat32Array = PackedFloat32Array()
```

A flat grid of floats, one per cell. The values decay over time and grow with deposits.

Deposit pheromone at a position.

```gdscript
func deposit(pos: Vector3, amount: float) -> void:
    var cell := _world_to_cell(pos)
    var idx := cell.y * size.x + cell.x
    if idx >= 0 and idx < field.size():
        field[idx] = min(field[idx] + amount, 1.0)
```

Deposits cap at 1.0. The field stays bounded. Every ant step thickens the floor under it.

Decay the field.

```gdscript
func decay(dt: float, rate: float) -> void:
    for i in field.size():
        field[i] = max(0.0, field[i] - rate * dt)
```

All cells lose a little each frame. Without fresh deposits, trails fade. Memory is finite.

Spawn ants.

```gdscript
func spawn_ants(count: int) -> void:
    for i in count:
        var ant := preload("res://commons/artifacts/randomness/ant.tscn").instantiate()
        ant.position = Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
        add_child(ant)
```

Ants start scattered. Each carries its own position and heading.

Bias each step by local pheromone.

```gdscript
func step_ant(ant: Node3D, dt: float) -> void:
    var dir := _pick_direction_with_bias(ant.global_position)
    ant.position += dir * ant_speed * dt
    deposit(ant.global_position, 0.05)
```

Direction is chosen by sampling neighbouring cells and weighting toward higher pheromone. The ant tends to follow a trail without committing to it.

Sample the bias.

```gdscript
func _pick_direction_with_bias(pos: Vector3) -> Vector3:
    var weights := []
    var dirs := [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
    for d in dirs:
        var sample_pos: Vector3 = pos + d * cell_size
        weights.append(field[_index(sample_pos)] + 0.05)
    return dirs[_weighted_pick(weights)]
```

Four cardinal directions sampled. Weights are the local pheromone plus a small constant so ants still explore empty cells.

Render the pheromone as a heatmap.

```gdscript
func update_heatmap(image: Image) -> void:
    for i in field.size():
        var v: float = field[i]
        var x: int = i % size.x
        var y: int = i / size.x
        image.set_pixel(x, y, Color(v, v * 0.3, 0.0))
```

Orange trails glow over a dark floor. The learner watches paths consolidate from noise.

Log the trail shape.

```gdscript
func trail_entropy() -> float:
    var mean: float = 0.0
    for v in field: mean += v
    mean /= field.size()
    return mean
```

A scalar describes how much of the grid is active. As ants converge on a trail, the scalar drops.

You have built emergence from individual chance. The next map, Random Space, saturates space with randomness.
<<</MAP>>>

### Random_Space

Source: `commons/maps/Random_Space/tutorial.md`

# Random Space

The sequence finale. Build the arena where every thread of the randomness curriculum converges.

Declare the finale environment.

```gdscript
class_name RandomSpaceArena
extends Node3D

@export var gaussian_sources: int = 4
@export var butterfly_count: int = 16
@export var pollock_drippers: int = 3
```

Four Gaussians, sixteen butterflies, three drip sources. The numbers are small enough to read and large enough to layer.

Place Gaussian field markers.

```gdscript
func place_gaussians() -> void:
    for i in gaussian_sources:
        var marker := preload("res://commons/artifacts/randomness/gaussian_marker.tscn").instantiate()
        marker.position = Vector3(randfn(0, 4), 0.1, randfn(0, 4))
        add_child(marker)
```

Gaussian random positions. Markers cluster near the origin with rare outliers. The distribution shape is felt through placement.

Scatter butterflies.

```gdscript
func scatter_butterflies() -> void:
    for i in butterfly_count:
        var b := preload("res://commons/artifacts/randomness/butterfly.tscn").instantiate()
        b.position = Vector3(randf_range(-5, 5), randf_range(0.5, 2.5), randf_range(-5, 5))
        add_child(b)
```

Butterflies occupy the air at random heights and floor positions. Each has its own noise-driven path.

Start the drippers.

```gdscript
func start_drippers() -> void:
    for i in pollock_drippers:
        var dripper := preload("res://commons/artifacts/randomness/dripper.tscn").instantiate()
        dripper.position = Vector3(randf_range(-3, 3), 3.0, randf_range(-3, 3))
        add_child(dripper)
```

Drippers hover above the floor, releasing drops at random intervals. The floor collects the splatter over time.

Blend the three into one reading.

```gdscript
func compose_reading() -> Dictionary:
    return {
        "gaussian_count": gaussian_sources,
        "butterfly_count": butterflies.size(),
        "pollock_drops": drop_log.size(),
    }
```

The reading summarises the three modes in one dictionary. A panel displays the numbers.

Fade audio in layers.

```gdscript
func layer_audio(dt: float) -> void:
    gaussian_bus.volume_db = lerp(gaussian_bus.volume_db, -6.0, dt)
    butterfly_bus.volume_db = lerp(butterfly_bus.volume_db, -9.0, dt)
    drip_bus.volume_db = lerp(drip_bus.volume_db, -12.0, dt)
```

Three audio buses ride the three modes. The room sounds like layered randomness rather than one noise.

Write the closing sign.

```gdscript
func write_closing(label: Label3D) -> void:
    label.text = "randomness saturates space"
    label.modulate = Color(0.9, 0.8, 0.7)
```

The sign names the finale. The arena is not about any one example; it is about saturation.

You have walked the finale. The next map, Random Game, makes randomness playable.
<<</MAP>>>

Pulse the room lights slightly on each drip.

```gdscript
func _on_drop_landed() -> void:
    arena_light.light_energy = 3.0
    create_tween().tween_property(arena_light, "light_energy", 1.5, 0.4)
```

Each splat pulses the ambient. The finale feels like it has a pulse. The pulse is random, not rhythmic.

The pulse is a memory of the drip. The finale lives in these small recalls.

### Random_Game

Source: `commons/maps/Random_Game/tutorial.md`

# Read the decision before naming the randomness

From Random_Mushrooms, carry the distinction between a recipe and its choices. Random_Game has two primary encounters: the three-stone crossing, then the falling field. Noise_Types follows on the active route.

At the crossing, watch two cycles from the lip. Say the state order aloud. Then compare the three lines on the tablet. Distinguish knowing the next state, knowing the current stored deadline, and knowing the next random draw.

Try the crossing or use the east corridor. Observe a ring before movement and a beacon during it. CUE changes all three stones' rings; it leaves the tablet available. REPLAY restores standing positions, collision support and the seeded wait streams. It is a local reset, not a rewind of the visitor or room.

```gdscript
var visible_wait: float = _next_random_wait()
_note_step("stands", visible_wait)
await get_tree().create_timer(visible_wait).timeout
```

At the field's east panel, stop the source, observe the flights that remain, then clear them. Start it again. The attempt interval is fixed; the centres and initial velocities are sampled. The 24-body cap can suppress an attempted launch.

```gdscript
if active_projectiles.size() >= max_projectiles:
    print("CubeSpawner: Max projectiles reached (%d)" % max_projectiles)
    return
```

Use the yellow floor rectangle to compare initial positions. It marks a sampling region, not containment. The independent projectile jitter means a fixed spawner seed is insufficient to replay the whole flight. The browser review provides captured initial values; it is not an added VR seed-entry control.

Ask which observation belongs to which mechanism. The nearby folding creatures and the Monte Carlo study remain secondary; neither is evidence that the crossing or field has another distribution switch.

The map still names `monte_carlo`, but the current museum loader reports no living scene for it and omits that body. It is a secondary candidate, not a verified encounter in this lane. Eight of the nine requested artifact placements currently build.


## Spatial staging — 16 September 2026

The map keeps a reachable instrument alongside its spatial applications. `map_data.json` is authoritative for placements. `#controls:compact` gathers the existing Rack panels, preserving their callbacks, into an 80 cm console. `#glass_width` opts into an enclosure with open entrances; its grid marks are not floor colliders.

`random_removal_arena` uses the existing owned-set `RemoveRandom` algorithm and one collider per cell. Entry and accumulated walking request draws; a reset restores both drawings and support. The basin fire uses the museum death/respawn path.

---

## 11. Noise: Fields and Possible Bodies

### Random_Noise_Types

Source: `commons/maps/Random_Noise_Types/tutorial.md`

# Carry, compare, then read the procedure

1. At **randompoint**, carry the point within its metal frame, then out of its plane. Release it. Compare local x/y with local z. Release does not draw a replacement position.
2. At **randompoints**, compare the two framed slabs, each 0.90 × 0.90 × 0.12 m. Move your viewpoint before treating projected overlaps as close spatial pairs.
3. Use REDRAW, then NEW SEED. A repeated construction requires the same settings and generator call order as well as the seed.
4. LOAD alternates the initial request and four times that request: 24 / 96 in this map. Dimensions and minimum distance stay fixed. Read filled/unfilled separately from kept/refused candidates.
5. RULE alternates minimum-distance rejection and the clamped Gaussian. Red shells in the latter are comparisons with a reference spacing, not breaches of a promise the Gaussian made.
6. Return to spacing, carry a point into another shell, release, then RESTORE. Separate a constraint at construction from the first artifact's continuously applied coordinate clipping.

Read these actual source passages after the encounters.

The single point clips coordinates on each process frame:

```gdscript
if clamped != pos:
	point_node.position = clamped
_update_label(point_node)
```

The bench counts neighbours; this branch changes no position:

```gdscript
if a.position.distance_to(b.position) < blue_noise_min_dist - 0.001:
	touching += 1
	bad[i] = true
	bad[j] = true
```

Try a three-point overlap. Three coincident centres contain three close pairs, even though only three points change colour. The observer reports pairs, not half the number of coloured shells.

## The galleries extend the route

7. At **WhiteNoiseGallery**, follow a row of the existing 100 × 100 field. Compare height with colour. Both use the same uniform draw; adjacent heights do not constrain one another.
8. Try its WHITE, PINK, BROWN, BLUE and VIOLET controls, then STOP. Compare sound while watching the image remain fixed. These are separate generators. Reading the field into sound is a proposed extension, not an implemented control.
9. At **NoiseColors3D**, compare the five illustrated rows, then audition the sounds. Examine the tall plateaus: display clamping makes different powers share one height. The bars are not a measured audio spectrum.
10. Read the BROWN accumulation and VIOLET difference passages in final.md after listening. What does each retain from its previous step? Carry several discoveries out of the room; every work need not answer the first question in the same way.

### Noise_Columns

Source: `commons/maps/Noise_Columns/tutorial.md`

# Noise Columns — follow what receives the value

Begin with the three columns together. Follow an unnamed silhouette through more than one apparent return. FREEZE pauses this instrument's local clock. SPIN turns a held shape; MARBLE removes the shaft's veining. Let observation precede REVEAL.

The source contains three drivers:

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

The output called phase is a normalized scalar, not necessarily an angular phase. Both moving drivers feed the same shaft recipe; the field samples along time rather than independently at every vertex. The recipe distributes that scalar using longitudinal progress v:

```gdscript
var melt_factor = pow(v, 0.5) * melt_strength * melt_phase
var height = v * column_height - melt_factor * 2.0
```

The shared 0.00–0.70 m range describes mapped drop at the shaft's top. Observe that the held reference is already ribbed and twisted. Geometry and its reference state were constructed before the new driver was added.

Keep the columns paused and observe the dark orb. Its own clock continues. Its sine enters brightness rather than shaft height:

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
```

Then approach the six-orb variant. The stand chose hush/swarm before construction. Six spheres turn with a parent; their gaps and alternating heights come from an array and a circle, not flocking. Compare the solitary body and the distributed body without requiring one to be an improvement over the other.

The red thread is the value and its recipient: sampled draws in the previous hall; a phase becoming shaft deformation here; another sine becoming light; configuration selecting body parts. Noise_One will give two recipients the same field, as relief and colour. Follow both what changes and what the receiving code keeps fixed.

### Noise_One

Source: `commons/maps/Noise_One/tutorial.md`

# Noise One: follow the receiving operation

Book route: **noisetorus → noiselayers → dark_sphere**. All three are primary. Teach from their actual controls; leave explanations until after the comparison.

1. Watch the two rings, then FREEZE at the current moment. SAMPLE moves matching coordinate probes. Find a negative value and compare inward relief with black colour.
2. REMAP changes negative-to-black clipping into a mapping of the full signed range. The field and relief stay fixed. Return to CLIP to compare.
3. While held, compare AMPLITUDE with FREQUENCY. The former changes displacement gain; the latter changes the coordinates consulted. Resume FREEZE and watch the local time continue.
4. Walk to the basin's south-facing panel. Inspect SUM before LOW, MIDDLE and HIGH. These isolate three supplied noise resources, each followed by the same slope-lowering pass; do not describe them as isolated octave bands.
5. Return to SUM. The terrain restores its complete generated vertex array and matching collision mesh. Compare this collider with the rings' shader-only relief.
6. Leave the rings frozen and observe the orb's continued pulse. Compare sources and recipients without calling every animation noise.

The book's code blocks are excerpts from the actual GDScript. The torus field has a pair-only integer lattice hash and cubic interpolation; the legacy single-ring mode keeps its original floating hash. Two shader stages consult the same field expression at different sampling locations: mesh vertices versus interpolated fragment positions. A marker names a probe coordinate, not an exact fragment-pixel measurement.

The terrain's material is violet. Generated vertex colours are not enabled as its albedo. All three authored grids remain, with lower line density and opacity in this compact staging. The inherited large-scale terrain still exists outside `stand:basin`.

Do not promise a brush, octave slider, torus collider, hydraulic erosion, procedural audio, or a walkable 200-metre mountain inside this hall. Headset reach and comfort are still pending. The next question is the occupancy threshold in Noise_Voxel.

### Noise_Voxel

Source: `commons/maps/Noise_Voxel/tutorial.md`

# Read a decision before changing its source

The room builds on Noise_One: one scalar can become displacement or colour. Here it becomes a stored occupancy decision. Four primary works carry different parts of that argument.

1. At **perlin_terrain_sculptor**, keep the initial seed. Press THRESHOLD and compare the field value at the yellow cell with the changing line. Read `contract_occupied` in the book only after noticing which quantity stayed fixed. The button wraps from +0.20 to −0.20.
2. Compare occupied cells with separate pieces. The first count decreases through ascending thresholds; the second need not. A component may split or disappear. This is six-face adjacency, not a route test.
3. Try CUT and inspect the unchanged occupied count. It changes the visible MultiMesh instances. Restore the view, then use CELL to choose another sample.
4. At **science_screen**, follow the yellow coordinate between the score slice and the binary mask. Change threshold at the bench. Inspect a value whose answer changes. Change CELL to view another horizontal layer. SEED then changes the field itself.
5. Approach **voxelnoise** through a ground door in its glass flight enclosure. Find a form shared with the model. Both have 24³ decisions; the physical spacing grows from 0.04 to 1.00 m. Rise in the clear margin, release movement to hover, and approach an opening. Distinguish the occupied set from what a body of your size can traverse. Desktop: look + WASD, Space up, Ctrl down. VR: tilt the left controller and use its stick. Descend and leave through either ground doorway to resume walking.
6. Find **dark_sphere**. Its emission and rotation continue independently. Compare a value used as a varying material strength with a value used in an occupancy test.

For a group, one person controls the bench while others compare the screen and volume. Swap positions. Alone, keep the seed fixed while returning between the three views. The question to carry into Noise_6_Wall is what another receiver can make of a value the threshold rejected.

The full code account is in technical.md. The chapter excerpts are actual source; proposed extensions in critical.md are future experiments, not present controls.

### Noise_6_Wall

Source: `commons/maps/Noise_6_Wall/tutorial.md`

# Noise 6 Wall — hold, accumulate, dress

1. Enter through either side door. Look along the floor towards the other opening and notice the cloud finish on the room's sphere.
2. Turn to the panel on the inner wall and press FREEZE. Compare the current moment before and after the press; it should hold without jumping to time zero.
3. Press DRESS while staying inside the room. Compare greyscale cloud accumulation with the full pink material. Check the same doorway and floor; the controls change material parameters, not collision.
4. At the panel, compare the fixed 1/2/4/6 windows. Press LAYERS to carry each cumulative bound into the enclosure. Keep BASIS and the moment fixed for this comparison.
5. Read the loop below. Each term folds noise through abs, adds a weighted magnitude, halves amplitude and doubles frequency. The sine/cosine offsets are held by the same local clock.

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

The first weight is .5 and the frequency is 1. The cumulative weights are .5, .75, .9375 and .984375. These are not predicted brightness values: each term has its own sampled magnitude, followed by gain and clipping.

6. Change BASIS separately. The control cycles the implementations Perlin → Value → Cellular → Simplex → Perlin. Return to Perlin at the held moment. There is no exposed seed control.
7. Restore the dress. The complete finish adds an independent four-term turbulence calculation, density, smoothstep, colour, corner/edge shading, roughness and lighting-normal variation. Reducing LAYERS does not disable that second calculation.
8. Follow a cloud towards a door or corner. Each quad restarts its UV chart; the sphere has another chart. A shared procedure does not guarantee continuity between those surfaces.
9. Watch the independent dark orb while the room is held. Resume with FREEZE again. The room continues from its held phase; the orb has been advancing throughout.

Both shaders expose the same cloud term bound and sum-only mode. The comparison patches always show the sum at gain 2, while DRESS selects what the enclosure and its sphere wear. The actual desktop pointer operates all four controls in the accepted rendered run. The current panel is at (6,4), facing into the room; earlier entrance photographs describe the previous placement. Human VR reach and comfort remain for the deferred headset session.

Next: Noise_Inside_Noise. Keep the distinction between changing the value returned at a coordinate and changing the coordinate at which the question is asked.

### Noise_Inside_Noise

Source: `commons/maps/Noise_Inside_Noise/tutorial.md`

# Noise Inside Noise — find the borrowed address

1. Enter through a side opening and stand inside the noise sphere. Look at the relief overhead, then press RELIEF once to enter SKIN mode. Compare the now-round smaller spheres and press ZERO. The two sampled fields agree while the same palette and round support remain.
2. Press WARP. Look up as the enclosing field changes while the room stays in place. Find the hollow yellow ring on the enclosing surface, then follow the yellow point on each small body and image. It still names p. The pink point on the left names q, the address from which the right-hand display obtains its answer.
3. Compare the cyan original grid and pink displaced grid. The selected yellow line follows p to q. SAMPLE chooses another witness, including the hollow ring on the enclosing surface, without rebuilding or changing the field images or sphere meshes. In SKIN the ring stays put through WARP and ZERO. In RELIEF its radius follows the changed surface while its direction remains the same. Its open centre lets you inspect the field it marks.
4. Read address_at and value_at in final.md: q = p + amount × displacement(p), then evaluate base at q. The offset uses two components from fixed Perlin fields; the base is a fixed Value field.
5. Cycle WARP through 0, .35, .8 and 1.4. The numbers measure displacement in field-coordinate units, not metres walked by the player. ZERO is a direct return, not a random reseed.
6. Press RELIEF while retaining the warp amount. The plate images keep their values. Both small sphere meshes now use radius .94 + .16 × value metres. This is a separate, post-sampling application. The enclosing sphere uses a vertex shader to change radius by up to .8 m, weighted to pin floor and doorway edges; its collision follows the same displaced vertices.
7. Press ZERO in RELIEF and compare the two silhouettes. The room keeps relief sampled from the unwarped field. Then return to SKIN and change WARP again. Input-coordinate displacement and output mesh displacement can be varied separately.
8. Walk around the pair. Sphere direction x and z supply the 2D coordinates; y is omitted. Look for the resulting relationship between upper and lower parts. A coordinate chart is part of the work.
9. Watch the dark orb. The study has no automatic clock, while the orb continues. The comparison remains available without claiming that the game has paused.

Current controls do not edit seeds, iteration count, frequency or time. The two small sphere surfaces have no collision; the enclosing wall, ceiling, circular floor and plinths do. Walk out through the opposite opening. Headset reach and comfort remain for the deferred headset session.

### Noise_Space_10

Source: `commons/maps/Noise_Space_10/tutorial.md`

# Test a route, then change its height

1. Take the entry ramp onto the raised margin. Choose the far pair of posts as the destination and inspect route A before crossing.
2. Try the terrain at HEIGHT .25. Return to the margin and compare the same route at .90. Look back at the automatic pink trace from the margin. It records this body's supported movement, while the gold line remains a proposal; stopping is not proof that every route is blocked. Entry starts a new trail, leaving holds it, and accepted HEIGHT/RESET clears it.
3. RESET from the margin returns .25, route A and sample 1. HEIGHT and RESET refuse while a detected player body remains on the patch. A refused press preserves both ground and trail; it is not queued.
4. Read ground_at in final.md: the fixed noise value becomes 1 + height_scale × edge_weight × value. HEIGHT zero gives a level surface while preserving the field's settings.
5. Follow the .75 m transition towards the margin. The edge envelope makes the noise contribution zero at the boundary. This is an authored access condition.
6. Select ROUTE B. Compare its section length and steepest sampled segment with A. The ground, collider and pink trail do not change. A longer proposed path may still be steeper.
7. SAMPLE selects five positions along the chosen section. Match the yellow marker on the plot with the marker on the actual ground. The readout distinguishes the raw field, edge weight and mesh height.
8. Read the mesh/collision passage. Each triangle is shared between visibility and collision; between vertices, the finite triangle can differ from a newly queried noise value.
9. From the margin, enter SMALLER. Walk on the unchanged surface at one-eighth size; look for its sampled triangles and compare a ripple with your new eye height. Find the small pink RETURN doorway beneath its beacon to regain the previous size on the margin.
10. Look for an overhang, then move to another view. One height per x/z cannot represent both a cave floor and roof there. Recall Noise Voxel's occupied volume.
11. Watch the retained orb when resetting terrain. Its independent pulse continues. Carry this distinction to the generator comparison in Noise_Perlin_Simplex.

The desktop input tests use the real DesktopPlayer rig with synthetic events. Headset movement, comfort, controller reach and Quest performance remain for the later headset session.

### Noise_Perlin_Simplex

Source: `commons/maps/Noise_Perlin_Simplex/tutorial.md`

# Try a comparison, then test its conditions

1. Choose a feature in each field before looking at their names. REPLAY the Simplex field, move FREQ, then replay it again.
2. Press SAMPLE on the central instrument. Follow the pink markers to the same local coordinate in both displays. Read their two values and the signed difference.
3. Compare the live generator settings. The matched pair differs in noise_type; a shared seed gives repeatability within each basis, not corresponding ridges.
4. Move one FREQ or OCTAVES slider. Watch the plate name the changed condition. Use MATCH to restore both declared configurations; use either REPLAY to restore only its own side.
5. Press VIEW. Check whether the answers change when relief becomes a flat colour display. Return to relief. The cube grid is a display choice shared by two different generators.
6. Step beneath each arch. Come out and press VIEW: why do the cube fields flatten while the arches remain curved? Follow the shared sample into the arch; then change a frequency from outside and walk beneath the changed surface. An occupied arch holds its shape until the visitor leaves.
7. Visit the small pink terrain. Its third noise coordinate advances by .5 every .5 seconds. Then watch the independent orb. MATCH belongs to the pair and does not restart either clock.
8. Follow the central aisle onward. The labelled Lab Path side portal is not connected. Cellular Automata changes the operation from querying a field to updating stored neighbourhood states.

No walkability, isotropy or performance ranking follows from these small display fields. A shelter comparison would need bodies and lines of sight; a speed comparison would need measurements. Keep those questions available for a later instrument.

### Lab_Path

Source: `commons/maps/Lab_Path/tutorial.md`

# Lab Path

The corridor back. Shared template across every sequence.

Build the corridor.

```gdscript
class_name LabPath extends Node3D

@export var source_sequence: String = ""
@export var target_lab_state: String = ""

func _ready() -> void:
    build_corridor_geometry()
    place_ambient_sphere()
    place_teleporter()
    configure_lighting()
```

Four standard components. Every sequence's exit uses the same recipe.

Build corridor geometry.

```gdscript
func build_corridor_geometry() -> void:
    var floor := MeshInstance3D.new()
    floor.mesh = BoxMesh.new()
    floor.mesh.size = Vector3(5, 0.1, 5)
    floor.position = Vector3(2.5, -0.05, 2.5)
    add_child(floor)
    var ceiling := MeshInstance3D.new()
    ceiling.mesh = BoxMesh.new()
    ceiling.mesh.size = Vector3(5, 0.1, 5)
    ceiling.position = Vector3(2.5, 2.5, 2.5)
    add_child(ceiling)
```

5x5 floor and ceiling. Low-key; nothing draws attention.

Place the ambient sphere.

```gdscript
func place_ambient_sphere() -> void:
    var sphere := DARK_SPHERE_SCENE.instantiate()
    sphere.position = Vector3(2.5, 1.5, 2.5)
    add_child(sphere)
```

A slow-pulsing dark sphere at the centre. The only visual feature.

Place the teleporter.

```gdscript
func place_teleporter() -> void:
    var teleporter := TELEPORTER_SCENE.instantiate()
    teleporter.position = Vector3(2.5, 0, 4.5)
    teleporter.target = "res://commons/maps/Lab/map.tscn"
    teleporter.target_state = target_lab_state
    add_child(teleporter)
```

At the far end of the corridor. Entering returns the learner to the Lab.

Configure soft lighting.

```gdscript
func configure_lighting() -> void:
    var light := DirectionalLight3D.new()
    light.light_energy = 0.3
    light.rotation = Vector3(-0.5, 0.3, 0)
    add_child(light)
    var environment := WorldEnvironment.new()
    environment.environment = preload("res://commons/environments/lab_path.tres")
    add_child(environment)
```

Low-energy light, plus a shared environment resource. Consistent across every sequence's corridor.

Fade to black on exit.

```gdscript
func _on_teleporter_activated() -> void:
    var fade := ColorRect.new()
    fade.color = Color(0, 0, 0, 0)
    add_child(fade)
    var tween := create_tween()
    tween.tween_property(fade, "color:a", 1.0, 0.3)
    tween.tween_callback(func():
        get_tree().change_scene_to_file("res://commons/maps/Lab/map.tscn")
    )
```

Brief fade prevents cut-to-Lab. Eye-friendly transition.

Pass state to the Lab.

```gdscript
func prepare_handoff() -> void:
    GameState.last_sequence_completed = source_sequence
    GameState.lab_target_state = target_lab_state
```

The Lab reads the state to decide how to present itself. Different sequences complete differently.

You can now build the shared corridor, ambient sphere, teleporter with target state, soft lighting, and fade-to-black transition. Chamber_Noise extends into the chamber for the Noise sequence.

Clamp to valid range.

```gdscript
func clamp_noise(value: float, low: float = -1.0, high: float = 1.0) -> float:
    return clamp(value, low, high)
```

Guarantees output stays in the expected range. Useful before writing to textures.

Log state each frame for later replay.

```gdscript
var state_log: Array = []

func log_state() -> void:
    state_log.append(current_snapshot())
    if state_log.size() > 600:
        state_log.pop_front()
```

Ring buffer of ten seconds at 60 Hz. Useful for replay or debugging.

---

## 12. Shaders: What a Surface Answers To

### Shader_01_Shaping

Source: `commons/maps/Shader_01_Shaping/tutorial.md`

**Missing tutorial.md — no substitute text added.**

### Shader_05_Patterns

Source: `commons/maps/Shader_05_Patterns/tutorial.md`

# The pattern crosses over


<!-- study-spine:reference_pattern_garden -->

## Return: The pattern crosses over

Change pattern phase while retaining every flower position. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses array, shader. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`garden`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-five-reference-rooms/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:reference_pattern_garden -->

### One source change: The pattern crosses over

In surface(), halve the original 0.5 phase range. Watch the same petal through the parameter change; keep density and flower positions.

```gdscript
result.set_shader_parameter("phase", amount * 0.25)
```

Source: `commons/artifacts/reference_studies/pattern_garden.gd`. Use the prepared scene to run and compare.

### Shader_11_QueerRubber

Source: `commons/maps/Shader_11_QueerRubber/tutorial.md`

**Missing tutorial.md — no substitute text added.**

### Shader_09_FBM

Source: `commons/maps/Shader_09_FBM/tutorial.md`

**Missing tutorial.md — no substitute text added.**

### Shader_12_PinkExtravaganza

Source: `commons/maps/Shader_12_PinkExtravaganza/tutorial.md`

# A body in the plural


<!-- study-spine:reference_plural_body -->

## Return: A body in the plural

Change the unfolding parameter; retain six limbs and three heads. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses transform, shader. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`body`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-five-reference-rooms/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:reference_plural_body -->

### One source change: A body in the plural

This existing expression controls one lateral control point of the limb curve. Change 2.3 to 1.8. Keep the outer loops and compare all six limbs at the same unfolding setting.

```gdscript
lerpf(1.0, 2.3, amount)
```

Source: `commons/artifacts/reference_studies/plural_body.gd`. Use the prepared scene to run and compare.

### Shader_10_ReactionDiffusion

Source: `commons/maps/Shader_10_ReactionDiffusion/tutorial.md`

**Missing tutorial.md — no substitute text added.**

---

## 13. Cellular Automata: Local Rules, Global Patterns

### CA_Introduction

Source: `commons/maps/CA_Introduction/tutorial.md`

# What will the next row do?

1. Start at the held rule explorer. Read the three marked states in order and predict a result before STEP.
2. STEP through Rule 90. Inspect a boundary and an interior cell; compare neighbourhoods 100 and 010.
3. Switch to Rule 30 with the same seed. Use RUN/hold to vary observation time; speed does not select the rule.
4. Inspect `_apply_rule`: three input bits select one of eight answer bits. Trace the separate old and new arrays through `_advance`.
5. SEED changes one cell into an adjacent pair while retaining the rule. STEP through the consequence. RST clears both stored and visible history.
6. CELL reaches the edge: index 31 is adjacent to index 0. Find the pair on the overhead ring. STEP moves the same stored history on both displays; RUN lets it unfold while you stand beneath it. Distinguish the current one-dimensional row from the time history rising above it.
7. Examine the rug's four matching quarters. Read `_enforce_quadrant` and the border/interior rules; the symmetry is reimposed each step.
8. Walk around the line network. Compare stored occupancy, the growth proposal and the renderer's later choice of a parent. A connecting line is not a complete causal record.
9. Carry state, neighbourhood and update schedule into the next hall's three-dimensional specimen.

Three principal works teach different mechanisms. The remaining six placements stay in the hall as secondary encounters. Native museum evidence is in the current encounter notes. Tracked headset comfort, reach and Quest performance remain pending.

### CA_ElementaryRules

Source: `commons/maps/CA_ElementaryRules/tutorial.md`

# A cell with a past

1. Walk around the retained volume from the floor rim. Separate apparent neighbours by changing viewpoint.
2. At the held console, STEP once. Find pink active and green fading cells; follow a green cell to empty on the next step.
3. Walk between the enlarged 3×3×3 positions beside the specimen. Gold marks the centre. Remove it from the count: 26 neighbours. Inspect the source's `== 1` comparison.
4. REPLAY then STEP: the golden centre is green beside seven pink neighbours. STEP again: it empties. Empty can be born, active can survive, fading must finish its interval before rebirth is considered.
5. VIEW changes state colours into height colours without advancing or resetting the automaton. Compare what each finish reveals.
6. Compare ACTIVE + FADING with DRAWN. Six-face shell culling hides occupied interior cells while they remain in the 26-neighbour calculation.
7. RUN and hold; REPLAY repeats the same seed. At the twenty-step budget, +20 permits further observation without restarting. Compare CHANGED with mere stillness.
8. Carry state, neighbourhood, edge and time into CA_GameOfLife's generation-as-space comparison.

All five controls have passed real desktop pointer checks in Godot. The supplied walking body passes through the enlarged neighbourhood on the existing floor. Full-route and headset acceptance, plus update-cost optimisation, remain pending. The web exercise is an independent smaller model for remote review.

### CA_GameOfLife

Source: `commons/maps/CA_GameOfLife/tutorial.md`

# Read a row, wear a history

1. At the desk, find the gold row in the flat record, stepping tiles and lattice. ROW moves attention through the retained record without changing it.
2. From the rim, REPLAY to the beginning. Predict the next row, then STEP. Compare ordered left/centre/right bits with the answer in Rule 30.
3. Walk along the basin margin: gold follows the nearest recorded row through all three mappings. Walk back and check that later rows remain. Name which direction carries site address and which carries generation. Beyond the record, walking cannot select an unmade row.
4. RUN to a fuller record. It stops after twenty-four rows; this is the display budget. X wraps according to the neighbourhood rule.
5. Use SEED or FLIP X9 and repeat. Explain why later rows are recalculated when the beginning changes.
6. Compare a gap in ornament with a gap in support. Inspect from the side passage before entering the shallow basin; use the end ramps to return. Replay and seed controls alter support, so operate them from the desk on the museum floor.
7. Continue into the retained rear collection, then the next hall's Life dish. The lab, columns and mirrored work are secondary comparisons, not evidence that this Rule 30 history implements Conway Life or a working universal circuit.

Primary: `ca_bridge:0:0#study:history#plinth:0#follow:walk`. Its three mappings belong to this one anchored encounter. Existing secondary roles and the orb remain.

### CA_BeyondBinary

Source: `commons/maps/CA_BeyondBinary/tutorial.md`

# Follow a cell, then follow a body

Begin at the dish with GLIDER held at generation zero. Let students predict what four presses of STEP will change before explaining Life. REPLAY gives the same beginning to a student exploring alone.

1. Compare the arrangement after four steps with its starting shape and address. Keep shape, location and generation as separate observations.
2. Replay and follow gold A=(10,10). Notice the occupied cell and lamp together. Then follow the whole pattern while A stays in place.
3. Walk the enlarged floor image and stay beside a fixed gold address while its state changes. Your presence does not enter this update rule. Recall the previous history bridge: this room maps occupancy to colour, with continuous support beneath both values.
4. Choose BLINKER. Predict its next phase. Its centre stays occupied, so A stays lit although the line changes orientation.
5. Read the actual B3/S23 branch in final.md. Work through an empty cell with three neighbours and an occupied cell with one. Explain the second buffer after these observations.
6. Return to GLIDER and disconnect LINK during a lit moment. STEP again. Identify which output was removed and which process continues. Read the receiver call.
7. Choose MEET. Predict visits to the witnesses, then compare this prepared beginning with GLIDER. Presets replace the beginning; they do not insert into the current board.

Ask students to explain a lamp using a single address, without saying “it senses the glider.” Then ask what the glider description helps them predict that the single-address record does not. Neither account exhausts the event.

For an independent reader, the readout names generation, population, changed cells, preset, link state and the finite observation limit. REPLAY is local to this experiment. The next hall will make proximity an input; it must earn that claim through its own source and support tests.


TRACE offers a second reading of the travelling figure: blue marks newly occupied cells, red marks cells that just stopped. Switching it off restores the ordinary colours immediately, without advancing. In the rear gallery, the hexagonal table changes both neighbourhood and birth condition and allows random flips; it is not just the square rule drawn with another tile shape.

### CA_ExpandingSpace

Source: `commons/maps/CA_ExpandingSpace/tutorial.md`

# Approach, wait, withdraw; then inspect the update

Start with the inherited array and the Life dish's explicit output connection. The new capability is a graded field whose external input can be the observing body.

1. From the desk choose SOURCE → PROBE and inspect NEAR. Run, watch W=(2,6), and hold. Name separately the colour, health and support changes.
2. Move the probe FAR and run. Follow recovery from a healthier edge into the depleted region. The probe controls a position, not a load.
3. RESTORE the full beginning. Select VISITOR and RUN. Approach, wait, withdraw; inspect the actual tracked body's distance. The ordinary margin and the basin ramps let the learner return after lost support.
4. Explain the proximity subtraction and four-neighbour recovery after observation. Compare the >0.5 participation threshold with the ≥0.2 support threshold. A value between them is a useful counterexample to “healthy or dead.”
5. Read the same state in the wall frieze. Ask which parts change colour, which support a body, and which influence the next update.
6. Choose CHAIN. With input NONE, STEP in SYNC. Switch ORDER to SCAN (the beginning resets), then STEP. REVERSE resets again; compare the same three addresses. Follow the `read_states` reference into the code.
7. Return to FULL and VISITOR. Describe one observation through an input, a state update, a threshold and a physical consequence.

Do not require a learner to fall to understand the rule; PROBE and the readout permit inspection from the stable floor. A desktop body has been tested on the bridge and recovery ramp. Headset comfort and reach are deferred. The next hall needs a live weighted-neighbour or coupled-field experiment before the book can claim richer exchange.

### CA_SoftRules

Source: `commons/maps/CA_SoftRules/tutorial.md`

# Try one missing relation

1. Carry in graded health, synchronous updates and the distinction between appearance and support.
2. Find W outside the beginning square. Predict which field can give it V; press STEP and read both concentrations.
3. Use +100. Then switch EXCHANGE B on; both beginnings are restored. Compare equal ticks before attributing a difference to exchange.
4. Switch exchange off and repeat. The reaction remains active in B. Explain why an unseeded site with V=0 cannot supply its own first V through U×V×V.
5. Change VIEW while held. Follow the changed colour map and unchanged numerical state. Hide and restore COAT; the floor and table experiments remain.
6. Inject the same patch into both current fields. Observe, then replay. Distinguish an intervention from a new rule.
7. Visit the clockmaker bench. Identify stencils, buffer trays, calculated histories and still illustrations. The crank is ornamental.

Extension: nominate what another body should receive from the field—a colour, displacement, force or control signal. Those are distinct mappings requiring distinct implementation and evidence. The current installation applies colour to tables and walls.

### CA_AgentsCircuits

Source: `commons/maps/CA_AgentsCircuits/tutorial.md`

# CA Agents Circuits

Wireworld. Cells can be empty, electron head, electron tail, or conductor.

Define cell states.

```gdscript
enum Cell { EMPTY, CONDUCTOR, HEAD, TAIL }
```

Four states. Empty never changes; the other three cycle in specific ways.

Apply the Wireworld rule.

```gdscript
func wireworld_rule(current: int, neighbours: Array) -> int:
    match current:
        Cell.EMPTY: return Cell.EMPTY
        Cell.HEAD: return Cell.TAIL
        Cell.TAIL: return Cell.CONDUCTOR
        Cell.CONDUCTOR:
            var head_count: int = 0
            for n in neighbours:
                if n == Cell.HEAD: head_count += 1
            if head_count == 1 or head_count == 2:
                return Cell.HEAD
            return Cell.CONDUCTOR
    return current
```

HEAD decays to TAIL; TAIL to CONDUCTOR; CONDUCTOR ignites when exactly 1 or 2 neighbours are HEAD. This rule supports signal propagation and logic.

Draw a wire.

```gdscript
func draw_wire(start: Vector2i, end: Vector2i) -> void:
    var current := start
    while current != end:
        grid[current.y][current.x] = Cell.CONDUCTOR
        var diff := end - current
        if abs(diff.x) > abs(diff.y):
            current.x += sign(diff.x)
        else:
            current.y += sign(diff.y)
    grid[end.y][end.x] = Cell.CONDUCTOR
```

Bresenham-style wire drawing. The learner can paint conductors with a controller.

Inject a signal.

```gdscript
func inject_electron(position: Vector2i) -> void:
    grid[position.y][position.x] = Cell.HEAD
```

A single HEAD cell. The signal propagates along any connected conductor.

Build an AND gate.

```gdscript
const AND_GATE := [
    [C, C, C, C, C, C, C],
    [C, 0, 0, 0, 0, 0, C],
    [C, 0, 0, 0, 0, 0, C],
    [C, C, C, C, C, C, C],
]
```

Two input wires converge. When both carry signals, the output wire ignites. Single inputs stall.

Test the gate.

```gdscript
func test_gate(gate_pattern: Array, inputs: Dictionary) -> int:
    place_pattern(gate_pattern, 0, 0)
    for input_pos in inputs:
        if inputs[input_pos]:
            inject_electron(input_pos)
    for _i in 20:  # run for 20 generations
        step()
    return read_output()
```

Place the gate; inject signals; run; read the output. Boolean logic via cellular automata.

Build a clock.

```gdscript
const CLOCK_RING := [
    [0, C, C, C, 0],
    [C, 0, 0, 0, C],
    [C, 0, 0, 0, C],
    [C, 0, 0, 0, C],
    [0, C, C, C, 0],
]
```

A closed loop of conductors. A HEAD placed on the ring circulates forever, producing periodic pulses.

You can now implement Wireworld, draw wires, inject signals, build logic gates, and test them via simulation. CA_EdgeOfChaos extends into classification.

Reset the grid to random.

```gdscript
func reset_random(density: float = 0.3) -> void:
    for y in size.y:
        for x in size.x:
            grid[y][x] = 1 if randf() < density else 0
```

Useful for exploring the rule's behaviour from different starting conditions.

### CA_EdgeOfChaos

Source: `commons/maps/CA_EdgeOfChaos/tutorial.md`

# Follow a difference before naming a regime

Primary: **self_organization_ca**, configured as the paired difference study. The four rear works remain secondary; their presence is not a claim that they demonstrate one shared critical point.

1. Inspect the two volumes and their selected spatial slice. STEP once; REPLAY and repeat.
2. Toggle ONE CELL off. The fields should agree even with DRIVE enabled. This checks the comparison before interpreting a difference.
3. Set DRIVE to zero, PULL to 0.25, SEED to UNIFORM and ONE CELL on. In INTEGER storage, STEP once.
4. Switch STORE to FRACTIONAL, which resets the same beginning. STEP: twenty-seven addresses differ; the maximum is 0.75.
5. Continue to G20. Read the count, maximum and printed display gain together. Try Z SLICE without advancing time.
6. Set PULL to zero and replay with DRIVE zero. The local intervention persists without spreading. Discuss whether stillness can retain something that smoothing erases.
7. Return to the scattered beginning and add disturbance. Keep the forcing shared between A and B. Describe the observed history before using “chaos”.

The floor carries an image of difference on fixed support. Body movement does not change this model. In the next hall, Fractal_Recursion, an explicit recursive call supplies a different way of making large form from a compact instruction.

---

## 14. Fractals: Rules, Scale and Room to Move

### Fractal_Recursion

Source: `commons/maps/Fractal_Recursion/tutorial.md`

# Fractal Recursion

A function that calls itself. Depth bounded, structure unbounded.

Recursive factorial.

```gdscript
func factorial(n: int) -> int:
    if n <= 1: return 1
    return n * factorial(n - 1)
```

Base case at 1; recursive call with smaller argument. The call stack captures the recursion depth.

Recursive tree structure.

```gdscript
func recursive_tree(start: Vector3, direction: Vector3, length: float, depth: int) -> void:
    if depth <= 0: return
    var end := start + direction * length
    draw_segment(start, end)
    var axis: Vector3 = direction.cross(Vector3.UP).normalized()
    var left: Vector3 = direction.rotated(axis, deg_to_rad(20))
    var right: Vector3 = direction.rotated(axis, deg_to_rad(-20))
    recursive_tree(end, left, length * 0.7, depth - 1)
    recursive_tree(end, right, length * 0.7, depth - 1)
```

Binary branching. Each call spawns two shorter children.

Memoisation.

```gdscript
var memo: Dictionary = {}

func fib(n: int) -> int:
    if n in memo: return memo[n]
    if n <= 1: return n
    var result: int = fib(n - 1) + fib(n - 2)
    memo[n] = result
    return result
```

Cache results. Fibonacci without memoisation is exponential; with it, linear.

Tail-recursive form.

```gdscript
func sum_tail(n: int, acc: int = 0) -> int:
    if n == 0: return acc
    return sum_tail(n - 1, acc + n)
```

Accumulator carries state forward. Compilers can optimise this into a loop.

Iterative equivalent.

```gdscript
func sum_iterative(n: int) -> int:
    var total: int = 0
    while n > 0:
        total += n
        n -= 1
    return total
```

Same computation; no call stack. Faster and safer for large n.

Detect stack depth.

```gdscript
func measure_depth(n: int, depth: int = 0) -> int:
    if n <= 0: return depth
    return measure_depth(n - 1, depth + 1)
```

Returns the number of recursive calls made. Useful for testing stack-overflow limits.

Self-similar structure.

```gdscript
func render_fractal_at(position: Vector3, size: float, depth: int) -> void:
    if depth <= 0:
        spawn_cube_at(position, size * 0.3)
        return
    var offset: float = size * 0.5
    for dx in [-1, 1]:
        for dy in [-1, 1]:
            for dz in [-1, 1]:
                render_fractal_at(position + Vector3(dx, dy, dz) * offset, size * 0.5, depth - 1)
```

Each cube spawns 8 smaller cubes. Cantor dust in 3D.

You can now write recursive functions, memoise their results, recognise tail recursion, convert to iteration, measure call depth, and build self-similar 3D structures. Fractal_RecursiveTrees extends into tree morphologies.

Convert iteration to pixel coordinates.

```gdscript
func complex_to_pixel(c: Vector2, bounds: Rect2, resolution: Vector2i) -> Vector2i:
    return Vector2i(
        int((c.x - bounds.position.x) / bounds.size.x * resolution.x),
        int((c.y - bounds.position.y) / bounds.size.y * resolution.y)
    )
```

Maps math-space to image-space. Inverse of pixel-to-complex used in rendering.

### Fractal_RecursiveTrees

Source: `commons/maps/Fractal_RecursiveTrees/tutorial.md`

# Encounter order

1. At recursive_tree_2, predict a fork and press GROW. Follow a parent endpoint into the next generation.
2. Compare ANGLE and LENGTH at a held generation. Move around the tree to distinguish projection from shorter geometry.
3. At generation four, switch FORKS. Compare 31 and 121 actual segments. RESET and replay; RULE gives a short code summary.
4. At recursive_tree, trace a fork before pressing STRATA. Compare REACH, ENDS and FORM on the unchanged sculpture.
5. Explore the retained collection and the historical enclosure as secondary encounters. Continue to Fractal_CantorSet.

Two primary tokens are anchored in final.md and listed in the Necklace primary view. Other works remain present without being forced into those two experiments. Headset reach and comfort are pending.

Earlier material remains in the [archived version](../../../doc/space/recursive-trees-2026-09-14/before/commons/maps/Fractal_RecursiveTrees/tutorial.md) for comparison and future development.

### Fractal_CantorSet

Source: `commons/maps/Fractal_CantorSet/tutorial.md`

# Encounter order

1. At cantor_set, predict the first gap. NEXT advances one cut; BACK returns. Count the latest row and compare its kept length.
2. At five cuts, use HISTORY to separate current state from its record. Use GHOST to locate the new removals. The ghosts have no collision. RULE offers a summary after the experiment.
3. At example_8_4_cantor_pagoda_vr, try the original broad opening via either retained ramp. Return to CUT twice and compare the broad, one-metre and narrow gaps.
4. DEPTH changes the passage length. LATEST removes the earlier storeys overhead. Neither changes the latest X intervals. RESET returns the starting configuration.
5. Explore the retained linear reference, cloud, three trees and sphere. Continue to Koch and Sierpinski: boundary growth and removal across a surface.

Two book anchors and the same two Necklace primary entries establish the guided route. The remaining collection stays available for detours.

### Fractal_KochSierpinski

Source: `commons/maps/Fractal_KochSierpinski/tutorial.md`

# Walk: the boundary takes a detour

1. At **fractal_koch_curve**, find both ends of the waiting line. Predict what NEXT might change. Compare endpoint distance, segment count and measured path length. Try TURN, then RESET → FORM → NEXT. Ask which geometric differences survive in the same count. Reveal RULE after the comparison.
2. At **sierpinski_triangle**, cut once and find the removed middle. Continue to four cuts, comparing area with number of pieces. VIEW cycles kept parts, pale removals, then removals alone. DEPTH changes thickness. Ask what is being computed and what is merely being drawn. The sculpture has no collision.
3. At **box_counting_dimension**, hold the 8,000-point sample. FINER and COARSER change the grid; COVER marks occupied cells. RANGE compares coarse, fine and all six measurements. Check that the sample stays unchanged. Reveal RULE and compare the finite fit with the ideal triangle's scaling law.
4. Explore the retained secondary collection. The bent arch, assembled cubes and six-call pyramid offer related but distinct procedures. Do not assign the triangle's rule to every triangular-looking object.
5. Pass around the original raised cell and follow the exit to **Fractal_MengerSponge**. Ask which holes can become passages for a finite body.

The first three artifacts are primary and own the three book anchors, in this order. The other seven placements remain. The learner may follow the desks alone or discuss held quantities and changed quantities with a group. Headset reach and comfort still need a physical review.

### Fractal_MengerSponge

Source: `commons/maps/Fractal_MengerSponge/tutorial.md`

# Encounter order: a hole becomes a place

1. Find the uncut nine-metre cube and the compact desk to the right of the front entrance. Predict what removal could make possible. NEXT opens the first cross; compare the front opening with its side connection.
2. NEXT again. Keep the large opening in view while finding its smaller copies. Read the cube count beside retained volume. FRAME holds the outside size still. GHOST locates the removed volume without restoring collision.
3. Reveal RULE. The three coordinates address twenty-seven cells; seven are skipped and twenty receive descendants. Keep the finite result distinct from the limiting construction.
4. Leave two cuts showing. Enter the glass frame at floor level, rise towards the large passage, release to hover, and fly through. Circle above and view from another face. The source geometry stays fixed while the projected openings rearrange.
5. Inspect a smaller axial opening. Compare what can be seen with what this body can enter. Flight supplies reach, while the retained cubes and the player's dimensions still constrain passage.
6. Descend and leave through a ground door. If a visitor remains inside, the desk will refuse NEXT/BACK/RESET. Non-solid GHOST/FRAME views remain available. An empty enclosure and a fresh press are required for another shape.
7. The DLA study, catalyst installations and dark sphere remain optional comparisons, with their own rules. Continue to Fractal_GoldenSpiral: a numerical recurrence now needs a mapping into form.

One primary artifact owns this multi-part encounter and its book passage. The four other placements remain secondary/decoration. Headset reach, comfort and performance still need a human review.

### Fractal_GoldenSpiral

Source: `commons/maps/Fractal_GoldenSpiral/tutorial.md`

# Encounter order

1. Read the two equal seeds. Predict the next value before NEXT. Reveal up to ten terms and check successive additions from the labels.
2. HEIGHT keeps those values while changing the height mapping. Compare the same terms. SUM supplies a fixed-unit addition witness beside the row; compare its tops before asking for RULE.
3. Walk around the desk and the supported examples. Read the seed, helix, shell-like, layered and branching constructions as different additional mapping rules. They are held still for inspection.
4. At the upright rectangle, imagine cutting off a square before NEXT. Follow several cuts. MEASURE reads actual shrinking sides and the remainder ratio.
5. ARC makes the circular construction visible. Toggle it off while retaining the partition. RULE gives the equation for the preserved proportion. More cuts introduce a resolution question.
6. Continue through the retained room: recursive cabinet, DLA, dark sphere, terrain and Romanesco. Distinguish their procedures. Proceed to Fractal_Synthesis, then LSystems_Grammar_Lab.

Two primaries, in order: fibonacci_sequences, golden_rectangle. Five secondary/decoration placements remain. Original material is archived; human headset review remains pending.

### Fractal_Synthesis

Source: `commons/maps/Fractal_Synthesis/tutorial.md`

# Encounter order

1. At Cantor, describe a replacement step before NEXT. Predict the count and combined length after two or three cuts.
2. HISTORY: compare the latest row before and after older rows vanish. GHOST: distinguish visible middles from surviving, collidable intervals. RULE follows the comparison.
3. At the block tree, find one fork. Follow it through STRATA, REACH, ENDS and FORM. Determine which operations reveal the existing tree and which would need a rebuild.
4. Read the stopping condition and the recursive call. Explain why “make smaller things” is insufficient to reconstruct either work.
5. Browse the retained collection. Its plaque identifies held examples; their presentation is not a shared entropy scale.
6. Continue to LSystems_Grammar_Lab. Inspect the specific production rule before treating a familiar preset name as the same construction.

Primary order: cantor_set, recursive_tree. The ten original works remain; a new decoration fixture supports the comparison. Deeper secondary controls and headset review remain later work.

---

## 15. L-Systems: Rules Grow Structure

### LSystems_Grammar_Lab

Source: `commons/maps/LSystems_Grammar_Lab/tutorial.md`

# A sentence and two readings

1. Begin at the six-button editor desk. Predict what NEXT will do to the live F. Count its five segments and nine symbols after one rewrite.
2. HOLD that reading, then TURN once: 90° becomes 120°. Compare corresponding segments and identical printed sentences. The held view retains its angle and geometry.
3. Keep the angle; NEXT rewrites. Compare 49 symbols and 25 drawn segments with the held first generation. RULE exposes the actual production after observing the difference.
4. RESET; PRESET three times reaches Plant at generation zero. Its X draws nothing. NEXT introduces F commands and brackets. Distinguish an undrawn symbol from a missing state.
5. Compare local bends and symbol counts rather than height: both drawings are independently fitted to their display. Four requested generations, a 4096-symbol allocation budget and a labelled 120-symbol text prefix are separate limits.
6. Continue around either end of the plinths into the retained collection. The existing string artifact is its own study, not a live readout of this editor. Take saved state into LSystems_Growth.

Primary: lsystem_editor. All eight existing artifacts remain. The primary contains two views of its actual output; it is not two independent generators. Physical rule typing is future work. Desktop pointer and route checks precede headset reach, comfort and performance review.

### LSystems_Growth

Source: `commons/maps/LSystems_Growth/tutorial.md`

# Follow the saved state

1. Begin at the parametric tree's compact desk, after the first F has drawn 0.8 m. Read the eleven-symbol sentence F[+F]F[-F]F.
2. STEP to `[`: predict what the point will do. It stays at the fork; stack depth becomes one and the next length becomes 0.576 m.
3. STEP to `+`, then F. The branch turns 38 degrees and draws 0.576 m. HOLD its tip and geometry as a reference.
4. STEP to `]`. Compare the live point back at the fork with the held point at the tip. No segment is added or erased. STEP again to draw the trunk's next 0.8 m segment upward. Explain the saved record and last-in, first-out stack through this return.
5. Finish the eleven symbols and HOLD. RATIO changes 0.72 to 1.00, then 1.15: branches shorten, match, or exceed their parent's stride. Grammar, turning choices and metre scale stay fixed; the held state stays available.
6. TREE shows two rewriting generations, 61 symbols and 25 segments. At ratio 1.15, a twice-nested stride is 1.058 m; the depth-zero trunk reaches 7.2 m. TREE toggles between one and two complete generations. RESET restores the initial line and reference.
7. Walk around the plinths into the retained collection. Their separate algorithms do not share the primary's sentence or constitute a controlled corridor-versus-clearing experiment. Continue to LSystems_Grammars_And_Curves and the believing turtle.

Primary: parametric_lsystem. All five existing works remain. STEP replays actual interpreter records; it is not a per-frame execution debugger. Six physical controls are STEP, RATIO, HOLD, TREE, RESET, RULE. RATIO also cycles through 0.45. The small tilted screen remains transparent. Desktop pointer and route checks precede human headset reach, readability and comfort review.

### LSystems_Grammars_And_Curves

Source: `commons/maps/LSystems_Grammars_And_Curves/tutorial.md`

# Read one sentence three ways

1. Begin with all three readers at 25 degrees, forward, after one 0.32 m F. READ F exchanges x/y only in the blue reader. Compare its stored heading (gold) with its drawing direction (white).
2. ANGLE changes only the middle reader to 45 degrees. The first F does not move. STEP five times to symbol six, where the first branch segment makes the changed turns visible.
3. Finish all 20 symbols / 8 drawn segments. Match local forks; brackets save and restore position/heading. Reference and blue reader retain the same angle and stride.
4. RULE exposes the direction exchange. Compare corresponding points relative to each origin: (x,y) becomes (y,x). This reflection preserves lengths and branching connections. It is not a ninety-degree rotation or a new branching graph.
5. READ F undoes the exchange. TREE toggles one/two generations and shows the full reading: 172 symbols / 64 segments at generation two. STEP then cycles from the end to START. RESET restores the opening conditions.
6. Continue around the cases to the original lectern and four other works. The smaller original comparison uses different strides and capped prefixes. The floor gallery uses different grammar depths. Do not treat either as the new desk's controlled comparison.

Primary: the_believing_turtle. All five authored works now instantiate. The original artifact's internal studies remain behind the new desk. The next hall is LSystems_Architecture. Headset review remains pending.


<!-- study-spine:tube_painting -->

## Return: A line takes up room

Change the middle ring side count from twelve to eight. Keep the path and radius; compare the skin. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This lesson introduces sweep using trace, mesh, refinement, rotation and array. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`tube`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-02-tube-painting-a-line-takes-room/index.html). Finish the current gesture before editing the work. RESET returns the original comparison.

<!-- study-edit:tube_painting -->

### One source change: A line takes up room

Replace the middle value 12 with 8 in SIDE_COUNTS. Restart the prepared study. Each supplied path still has 41 points and the same radius. A capped tube now has 656 triangles instead of 984. Compare PATH, RINGS and TUBE before drawing your own continuation.

```gdscript
const SIDE_COUNTS := [6, 8, 24]
```

Source: `commons/primitives/pipes/swept_tube.gd`. Use the prepared scene to run and compare.

<!-- tube-making -->

## Continue a drawing that has already begun

This is the later **sweep** lesson, in **L-systems → Grammars and Curves**, before Architecture. Point Trace introduced keeping positions. Mesh introduced vertices and triangle connections; refinement introduced circular sampling; rotation supplied changing orientation. Here those tools meet: a path carries a ring, and neighbouring rings carry faces. Point Trace keeps its earlier, simpler encounter.

### First use what is here

Three supplied strokes are suspended in front of the wall. Their six pink end grips are part of the interface. Grab a lower end and move your hand slowly. The old length stays where it was; sampled positions are added beyond it. Release to leave the addition in the air. You can also continue from the other end; the stored path reverses its order before growing there.

Bring an end close to the receiving wall. Its centre snaps to the wall surface and sampling stops until you release. This makes a visible attachment. It is not a structural joint or a gravity simulation. The runs can now join through explicit sockets. Their skins can overlap and do not become a welded solid or block the visitor. Together their paths can compose another, incomplete wall in front of the room's wall.

The pen on the plinth begins a separate stroke. Pick it up, hold its trigger while moving, and release the trigger to keep the line. On desktop, the existing right-click pickup/drop and left-button held action drive the same pen. The artifact adds no player, controller mapping or installation step.

**UNDO** restores the whole drawing before the last completed gesture or geometry edit. Extending a supplied line and undoing leaves the supplied line intact. **CLEAR** removes the strokes; **EXAMPLE** replaces them with the three opening strokes using the current radius and side count. Both can be undone. **RESET** also restores default settings and returns the pen; put it down first. Undo restores geometry, not the pen pose or the next-stroke settings. History keeps the last sixteen states during this visit. Closing or unloading the hall does not save a drawing to disk.

### Inspect the same work three times

**VIEW** cycles TUBE → PATH → RINGS → TUBE. It changes the representation, not the stored positions. PATH is the retained centreline. RINGS shows the sampled cross-sections. TUBE connects them with faces and closes the two ends. The controls are available after you finish a gesture.

**THICKNESS**, **SIDES** and **COLOUR** edit the last stroke in the list and choose the setting for the next new pen stroke. Continuing an earlier stroke preserves that stroke's own material and resolution. Undo an extension before trying a different route. The readout counts the last stroke in the list, not the sum of the whole work.

### What one ring needs

The production builder is `commons/primitives/pipes/swept_tube.gd`. Its `build(path, radius, sides)` function receives positions we already know how to retain. At each position it supplies two perpendicular directions, `frame_normal` and `binormal`, across the path. This is the ring expression, taken from that builder:

```gdscript
var angle := TAU * j / float(sides)
var radial := frame_normal*cos(angle)+binormal*sin(angle)
vertices.append(points[i]+radius*radial)
```

`i` addresses a point along the path; `j` addresses a place around its ring. Changing `sides` changes the second count. It does not take more samples of your hand movement. Changing `radius` moves each ring vertex away from its centre without moving the centre.

The supplied frame transport carries the ring around bends without making it suddenly look towards world-up. Understanding or rewriting quaternion transport is not required for this first edit. First locate the familiar circular rule inside the supplied construction.

### Join two rings

Let `a` and `b` be neighbouring vertices on one ring, and `c` and `d` their corresponding neighbours on the next. This production line adds two triangles:

```gdscript
indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
```

The last address wraps to the first with `% sides`. That closes the seam around a ring. Separate triangles cap the two ends. For N path points and S sides, the body has `2 × (N - 1) × S` triangles and the two caps add `2 × S`. The total is `2 × N × S`.

Make the one source edit above before changing the path: twelve sides become eight. Each opening stroke retains its 41 centres and 0.065 m radius. The capped mesh changes from 984 to 656 triangles. Look near a curved silhouette. Then make your own continuation and compare again. The number is a check on a visible decision, not the reason to prefer one drawing.

### After the first sweep: a connected system

Choose **NETWORK** to load the three-form example. **FORM** cycles the last run and next pen stroke through tube, pipe and cable. A tube retains the path you drew. A pipe uses outer and inner rings with annular rims, leaving an open bore; its sleeves make the mouths visible. A cable redraws between its endpoints and any joined supports with a downward parabolic offset. **SAG** changes that offset while keeping the supports fixed. This is authored drape, not a simulation of gravity or cable length.

Hold the pen trigger beside another run and draw away to start a branch. To join a free end, continue it close to another run, wait for the amber marker, then release. The shared port is recorded only on release. Silver fittings mark these sockets. Connected endpoint grips disappear so extending cannot silently pull a joint apart. Use the pen there to branch, or UNDO to restore both runs and their port records. Merely crossing two skins makes no connection.

`run_network.gd` owns that relationship; `swept_tube.gd` owns the mesh. The reusable `PipeLayout` accepts named anchors and per-run `kind`, radius, sides, sag and optional sampled points. Moving an anchor rebuilds its dependent runs. Its existing glass and drain command builders remain available. See `commons/primitives/pipes/README.md` and `layouts/three_forms.json` for an executable layout example. The hand-drawn runs have no fluid, audio or electrical routing and does not save a drawing between hall visits.

### Explore the form library

**PARTS** cycles four groups from the existing pipe and glass library: straight, 45° and 90° bends, U-bend and S-bend; tee, Y-junction, cross and reducer; coil, wave, flask and beaker; cap, drip and condenser. **CABLES** shows five existing cable arrangements: chord, spline, authored sag, festoon and truss. These are supplied forms to work from, rather than five new algorithms to learn now.

Each group replaces the current drawing; UNDO brings that drawing back. A pink grip marks every declared free port, including the third and fourth arms of a junction. Choose FORM, then take a grip and draw onward. The supplied piece stays in place while a new tube, hollow pipe or cable grows from its port. Release beside another free port to connect two pieces. On supplied parts only the declared ports accept a connection; on drawn runs you can also branch along the path.

The catalogue reuses the existing geometry and port metadata through `part_library.gd`. Some stock pieces are solid display meshes; they are not all hollow plumbing. The new PIPE run has an open bore. Neither kind simulates flow. The supplied pieces keep their shape in PATH and RINGS views while your new runs reveal their construction. THICKNESS and SIDES apply to drawn runs, not the supplied part meshes. COLOUR can recolour the last supplied piece. Eight pieces and runs share the workbench budget, so a five-piece group leaves room for three additions.

### What is supplied, and what is limited

`tube_painting.gd` owns the retained strokes, undo states, view modes and bounded input. `tube_pen.gd` reuses the existing drawing pen. `tube_end.gd` reuses the existing pickup handle. `station.gd` supplies the museum console. Their complete source accompanies this tutorial; keep them intact for the first ring edit.

New samples are actual nib or end-grip positions at least 0.045 m apart. A sudden jump above 0.75 m stops further additions until release. Each stroke can retain 256 positions; the work can keep eight pieces and runs. The drawing volume and feedback keep an endpoint from writing into another exhibit. A tube at the point limit needs a separate new stroke. Tight turns and self-intersections are not repaired into a manifold solid. The pink grips and the wall are interactive/collidable; the tube skin is visual geometry. Native automated pickup and input tests are recorded separately from physical headset testing.

### Optional application: patch a sound, wake a machine

Beside the drawing workbench, the existing modular rack now has a focused VCO → VCF → VCA → SPEAKER patch. Close POWER with the physical lever or its matching button. WAVE selects saw, square, triangle or sine (0–3); FREQ and FINE change pitch, AMP changes level, and PAN moves the sound between channels. Turn CUTOFF, then switch the FILTER lever. You should hear the high harmonics change. The sound is generated continuously; adjusting the filter does not restart a recorded note.

Unplug the VCF route and connect VCO OUT directly to VCA IN. The signal bypasses the filter. An incomplete path to SPEAKER is silent. Grab and release plugs close to a compatible socket, or select an output then an input with the museum pointer. A selected occupied socket removes its cord. PATCH EXAMPLE restores the four supplied cords; UNPATCH removes them. Put down a held plug before either operation.

The second route is POWER GATE → MOTOR. Unplugging it stops the coloured bodies without breaking the sound patch. Opening the power lever stops both. Audio and gate sockets accept their own signal kind; a drawn tube crossing a socket cannot silently become an electrical connection. Moving beads show route direction and enabled state at an illustrative speed, not audio frequency or electrical propagation.

The bodies reuse transformed primitives and swept limbs. Their cranks use a shared elapsed phase at three different rates. This is a kinematic study after Jean Tinguely and Niki de Saint Phalle, not a physical motor model or a reconstruction of a particular sculpture. The connected system extends the sweep lesson; synthesizer implementation is supplied. Inspect `commons/audio/cables/live_patch.gd` for the bounded audio graph and `commons/artifacts/spine_studies/patch_and_motion.gd` for its motor receiver. Other rack presets retain their existing sound behavior.

### Optional application: let the line become a ceiling

Look above the drawing bay. The small console on the left controls a canopy made with the same `PipeLayout` and hollow sweep. **RULE** cycles woven crossings, returning U-bends and branching ribs. **DIAMETER** selects 0.36, 0.60 or 0.84 metres; **REPEAT** selects three, five or seven lanes or branch stations. **FINISH** changes pink lacquer to pale enamel and chrome. **RESET** restores the pink five-lane weave without changing the drawing or synth patch.

Keep diameter and repetition fixed. Change only the rule, then look up from the same position. In WEAVE, the two families have opposite heights at every crossing. A cosine raises and lowers each run; the next lane adds half a cycle. In RIBS, repeated branches meet a central run at named anchors. In RETURNS, each lane runs to a semicircular bend and comes back. The same rings and faces make all three; the path rule changes their relation.

`commons/primitives/pipes/pipe_canopy.gd` is the reusable generator. Its `make_layout(mode, count, radius)` returns an ordinary layout dictionary, so another scene can use it with the existing PipeLayout. The museum wrapper adds a frame, hangers, controls, luminaires and a local reflection probe. The inherited museum ceiling presets still handle conventional tiles, vents and fixtures. This installation is an open canopy above the work, leading towards Architecture.

The pipes have real inner surfaces and open mouths. The rib intersections share logical anchors but their surfaces overlap; they are not welded plumbing and carry no simulated flow. The canopy is visual geometry above the reachable drawing volume. Support posts and the console collide. Meshes rebuild only when the layout changes; changing finish reuses them. A local probe captures the surrounding room once, so it is not a live mirror of subsequent drawing or machine movement. Settings last for this hall visit. Physical Quest performance remains untested.

<!-- /tube-making -->

### LSystems_Architecture

Source: `commons/maps/LSystems_Architecture/tutorial.md`

# When a line acquires walls — encounter

Primary: `lsystem_dungeon`. All nine authored works remain; the miniature has an opt-in full-size lesson.

1. Read the four centrelines and predict the route before pressing BUILD.
2. Enter at 1.4 m clear width. Follow a side branch, return and take the other main opening.
3. Read `F[+RF][-RF]F`. Trace the two R instructions through the saved state. The opening labels give their count without giving the address count. RULE or the first enabling of ROOMS reveals that they mark the same junction.
4. Leave the brass frame. ROOMS adds one 2.8×2.8 m footprint at that shared address. Walk off the centreline there.
5. WIDTH cycles 1.4 → 2.2 → 0.4 → 1.4 m. Compare the same plan with the same 0.6 m diameter desktop collision body.
6. PLAN removes the construction; RESET restores the initial plan, 1.4 m width, rooms off and the undisclosed address count. RULE explains the two operations without rebuilding. A discovered address remains visible through subsequent changes until RESET.

All construction controls refuse while a player is inside the fixed study bounds; they require another press after exit. The desk stands outside. Museum support stays under the whole experiment. A clear outer route continues past the retained gallery.

The next room is LSystems_Competition. Carry the distinction between a generated instruction and the conditions that let it take effect. Headset reach, comfort and performance remain for later testing.

### LSystems_Competition

Source: `commons/maps/LSystems_Competition/tutorial.md`

# Who gets the first turn? — encounter

Primary: ForestCompetition. Retain branching_coral as secondary and dark_sphere as decoration.

1. Compare the two F stems, equal initial values, and overlapping soil squares.
2. STEP twice. Follow the selected tree, the field and uptake: 2.250 then 1.980.
3. ORDER starts a fresh comparison with B first. STEP twice and compare the allocation.
4. SEASON resets in winter. STEP twice: consumption occurs without a rewrite or diameter increment.
5. SOIL advances diffusion and replenishment by one second without a tree turn or season change.
6. RESET returns to spring/A first. Six STEP presses give both trees three generations. Further turns report their cap.
7. Read the consume-then-gate code. Visit the automatic original forest, its four controls and the independent coral.

The two branch displays are enlarged 4× and separated for inspection. Their actual root addresses are the close markers on the soil. Carry the difference between a rule and conditions on its execution into LSystems_Living.

### LSystems_Living

Source: `commons/maps/LSystems_Living/tutorial.md`

# Living — what counts as a change?

Primary: genetic_tree_sculptor. Begin with RESET, then HOLD a witness. Depth starts at 4.000. Press MORE four times, watching both the value and the unchanged branch plan. The fifth press reaches 5.000 and three generations. Explain halving, rounding and clamping only after that comparison.

GENE cycles Depth, Forks, Angle, Taper, Leaves, Tropism, Twist, Arrange. Use Angle to change direction without changing generation count. The original eight sliders and RANDOM remain on the side rack. The compact six-button desk reaches the same underlying gene mapping.

PLANT puts one snapshot on the floor pad and exports independent DNA for the older catalyst consumer. Change the preview; the placed tree stays. HOLD replaces its witness; PLANT replaces its floor specimen; RESET restores only the editing design. Neither local tree collides with the visitor or alters the map floor.

Read requested F/S commands against the 200-command drawing budget at high Depth/Forks. Ask which desired body can be reached by these controls and which needs a new rule. Continue to the retained tree, coral and three paper drawings, then the face-operation study in LSystems_Shape_Grammars before Assemblage_Same_Desire. Preserve that distinction between procedure and what we see in its result.

### LSystems_Shape_Grammars

Source: `commons/maps/LSystems_Shape_Grammars/tutorial.md`

**Missing tutorial.md — no substitute text added.**

### Assemblage_Same_Desire

Source: `commons/maps/Assemblage_Same_Desire/tutorial.md`

# Assemblage — two marks, many paths

Primary: ten_print_textile. Begin with RESET, then read a small group of diagonals in both directions. HOLD a witness. Change ALPHABET through orthogonals and blocks, returning to diagonals. The samples and binary decisions stay fixed; the geometric interpretation changes.

Try ODDS. At .75 compare the same samples with a higher threshold. The count changes; a half-probability setting did not demand exactly half of the 144 cells. SEED supplies a new recorded sheet. RESET restores the starting sheet; HOLD keeps a comparison. STEP discards one oldest row, shifts eleven and adds one new row. The original automatic textile behind the study runs the repaired bounded queue over time.

Walk over the floor version. Follow and cross its lines. Its support and collision do not depend on which mark was chosen. Explain what additional construction and graph checks would be needed if these marks became barriers; that variation is proposed, not implemented.

## Continue through the collection

At panel_bridge_loom, inspect the threading, tie-up, treadling and drawdown panels. The draft relates warp threads to shafts, treadles to shaft sets, and picks to treadles; the computed crossing records whether warp or weft is on top. This is a different dependency structure from the independent two-mark choices. The analogy to a grammar is a useful comparison, not a historical claim that a weaving draft is an L-system.

The pattern atlas and Mamma Monster gallery retain their maker labels and shader interpretations. Read the credits alongside the forms. The origin gallery names Kristina Torsson and the Mah-Jong collective; its presence locates the project's history. Keep these particular histories beside the procedural comparison.

The dragon bench returns to deterministic construction. The Gödel plaque and incompleteness scale introduce questions about formal limits. The scale's thirteen-degree tilt is authored geometry, not the outcome of a self-weighing physical experiment. The display of a sentence is not its proof. Those distinctions belong in the discussion rather than being erased by the room's shared theme.

Next: PG_Genetic_Evolution. Move from an outcome someone chooses to follow towards an algorithm that compares outcomes with a score. Inspect that score and its representation before describing what it selects for.

---

## 16. Procedural Generation: Rules Build Worlds

### PG_Genetic_Evolution

Source: `commons/maps/PG_Genetic_Evolution/tutorial.md`

# Genetic Evolution — a body and two readers

Carry forward the list of parameters from Living and the distinction between generation and interpretation from Assemblage. A genome is a list of primitive types with position, rotation and scale. One program builds its image; another evaluates it.

1. RESET. Compare the six boxes and choose a reason for preferring one before reading scores.
2. HOLD the current leader. Explain that this control keeps the leader, not an arbitrary nominated candidate.
3. TARGET once: 8 becomes 16. The same six descriptions are reordered, the generation stays zero and the held witness is unchanged. Read estimate 15.625 and score about 72.73 on the new leader.
4. Explain the exact score formula in final.md. Compute what happens at differences zero and one. Avoid calling the proxy measured solid volume.
5. RING. Observe the new part and unchanged score. RULE reveals that the builder draws toruses but the estimate omits them. Find the box's factor eight and discuss what an exact union-volume measurement would need to handle.
6. Leave the ring and STEP. Find an unchanged elite among the new generation. Two elites are copied and four slots filled through tournament selection, possible crossover and mutation. A feature can continue without having contributed to its carrier's score.
7. RESET. The opening population returns; the held witness remains. Later random offspring need not replay. A run stops advancing at the original limit of 50 generations.
8. Take the side ramp to the retained two-metre deck. Distinguish its physical support from the collision-free generated specimens. Describe the additional construction and test needed to select forms for a visitor's passage.

Preserve the secondary science_screen as existing material; its grid display is not connected to this scoring experiment. Ask what a useful genome/score view should expose before promising integration. Continue along the eastern aisle and around the rear partition to PG_Space_Colonization, next on the active museum route. Space Colonization now leads directly into Branching Growth, before Percolation.

### PG_Space_Colonization

Source: `commons/maps/PG_Space_Colonization/tutorial.md`

# Teach one decision, then change eligibility

1. Begin at the compact console in PG_Space_Colonization. Read the three pink positions from the root. Predict the first half-metre segment before pressing STEP. Side components cancel and upward components add.
2. Explain subtraction, normalization, unit-direction accumulation and normalization of the sum using the actual SpaceColonizationAlgorithm.gd lines in final.md. Gold previews the next decision; it is not a reconstruction of the last one.
3. FIELD opens the fixed eight-point array and restarts growth. STEP repeatedly under TIPS. Follow the active end and small/dark reached witnesses. One successor per replaced leaf makes a strand from this root.
4. HOLD a specimen, then POLICY to restart the same field under NETWORK. Step until an earlier site has two children. Compare an actual fork with the held strand at its labelled .45 display scale. Each site still makes at most one child per generation; the new permission is to answer again later.
5. FIELD opens the 96-point asymmetric canopy. The same rule operates at a larger scale; sine offsets are authored input. Remaining requests and stop reasons matter. Do not equate a budget with completion. RULE exposes the decision; RESET restores the opening and keeps the witness.
6. Walk the side ramp onto the retained rear deck and take the eastern route to the exit. Distinguish parent connectivity, visible segments and the collision that carries the visitor.

Continue directly to PG_Branching_Growth: compare a nearest-target decision with the accumulated direction just learned. Keep its existing organic_space comparison available. This first traverse does not impose a one-artifact quota on later rooms.

### PG_Branching_Growth

Source: `commons/maps/PG_Branching_Growth/tutorial.md`

# One nearest invitation — encounter

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

### PG_Percolation_Network

Source: `commons/maps/PG_Percolation_Network/tutorial.md`

# Touching is not enough — encounter

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

### PG_Caves_Mazes

Source: `commons/maps/PG_Caves_Mazes/tutorial.md`

# A route needs room — encounter

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

### PG_Sculpted_Forms

Source: `commons/maps/PG_Sculpted_Forms/tutorial.md`

# What did the sample keep? — encounter

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



<!-- @dome -->

Turn to the dome. Here the empty region has not come from a wandering point or a fallen cube. A geometric operand has cut it from a stock volume.

CUT cycles through the cast, the uncut blank, the cutting cores and a section. The cores show the shapes that made the absence. A hole can carry as much authorship as the material around it.

```gdscript
cut.operation = CSGShape3D.OPERATION_SUBTRACTION
```

Return to the cast after seeing its operands. The result may now look less self-evident. It was one possible agreement between volumes and operations. Moving a cutter would make another agreement; it could admit a body, divide an interior or close an opening we had begun to rely upon.

The layered membrane remains nearby. Its repaired scene makes a further contrast available: nested displaced surfaces can suggest thickness without being one filled solid. Look between them. Do not assume that a convincing skin carries the collision or interior its appearance promises.

These works give us different ways to materialize a decision: sample an event, subtract a volume, arrange surfaces. Next we will compose operations we already know, while keeping two questions distinct: how is an image copied, and how are places connected?

### PG_Mirrored_Patterns

Source: `commons/maps/PG_Mirrored_Patterns/tutorial.md`

# A repeated image, another way through — encounter

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



<!-- @rhizomatic_maze_space -->

Now move your attention from the surface to the network beside it. NETWORK changes the connection policy over six fixed starting positions. The opening is a tree. Its unique connections give one connected component and no cycle. The next policy admits more nearby connections; the third severs connections across a central gap and separates the remaining pieces.

Watch the counts before deciding what the silhouette means. The desk reports distinct undirected connections, components and independent cycles. The generator may store an edge in both directions; those duplicate records do not create another physical route. For this finite undirected graph, the cycle count is `edges - nodes + components`.

Changing NETWORK preserves the six initial positions. The severed result subsequently displaces positions as part of making its gap, so the final coordinates are not all held fixed. This is a comparison of construction policies, not a claim that every visible difference came from deleting one edge.

SURFACE alternates the bare connections with the tunnel surfaces constructed around them. The specimen's collision is disabled in both views: it is an observation model, not a secretly solid set of invisible tubes. Its gaps and curved surfaces are available to examine before we develop a full bodily traversal. A thick skin can obscure connections that were obvious in the skeleton.

The original generator can also add secondary growth. This opening study sets those iterations to zero so that we can inspect the connections between the six seeds first. We have made a restriction to gain a foothold, not discovered the network's final possibilities.

The pattern tunnel remains a bodily application in the collection. Its surface can be dressed while its supporting route persists. A reflected image does not by itself connect two rooms; a graph edge does not by itself guarantee that its tunnel has sufficient clearance. Geometry, connection and access can be composed, but they require their own checks.

Across this sequence, we have selected, guided, branched, connected, carved, sampled and copied. Each operation gives us something to build with and something more precise to question. What bodies are possible now? We can answer with a construction, try its limits, and carry the unresolved part into the next hall.

---

## 17. Soft Bodies & Morphogenesis: Matter That Finds Its Shape

### SoftBodies_Soft_Body_Deformation

Source: `commons/maps/SoftBodies_Soft_Body_Deformation/tutorial.md`

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



<!-- @softmill -->

Turn toward the mill. The moving apparatus brings a repeated encounter to a soft sphere. Use MILL to hold the drive. The sphere's physics continues; stopping a mechanism is different from stopping everything it has set in motion.

The cube made its coefficients available on a desk. The mill makes the source of an encounter visible in the room. Follow the motion from the machinery to the surface, then consider the room around both: the collider, support and pinned points belong to this body's conditions as much as its stiffness does.

The nearby jelly variants remain useful comparisons, and radiolaria offers a different warning: intricate biological resemblance can be constructed without soft-body dynamics. Keep that distinction for later. First we need to see how a surface changes when some of its points are required to stay.

### SoftBodies_Cloth_Physics

Source: `commons/maps/SoftBodies_Cloth_Physics/tutorial.md`

# Which points must stay?

<!-- @cloth_straps -->

Walk along the hanging strips. Each begins as an open surface. Unlike the pressurized cube, it has no enclosed interior for pressure to inflate. The upper edge holds while the rest hangs below it.

Press PINS to keep only the upper corners. Look for the difference before naming it. The material settings have not changed. The allowed motion has: points that were fixed can now participate in the sag. PINS alternates those two arrangements; RELEASE removes the pins, and REBUILD makes fresh strips with their upper rows fixed again.

```gdscript
sb.set_point_pinned(i, keep)
```

For each strip, the desk finds the top row in its mesh coordinates and chooses which indices to pin. This is a boundary condition written into an array. The frame makes that condition visible, but the frame and the pinning rule are distinct constructions. A convincing support does not prove how the simulation is attached to it.

Try STIFFNESS after choosing a support. We now have two ways to change the silhouette: change the material response, or change which points may move. When we describe an object as compliant, how much of that description belongs to the object, and how much to the arrangement holding it?



<!-- @softstopscene -->

The four falling bodies provide a second encounter. They are soft spheres, retained from the earlier collection, not pieces of woven cloth. LANDING changes the support below them between a floor, a narrow pan, a rail and a cone. Rebuilding that comparison also starts a new fall.

Their timers disable processing and raise damping and stiffness at scheduled moments. This stopping method is not an explicit snapshot of all vertex positions. The apparent crumple depends on the solver as well as the timer; it is not a shape the material was destined to have. Two shipped stop times are equal; four specimens do not automatically mean four different moments.

This prepares two questions we will return to: what makes the body deform, and what makes us stop looking? Carry the fixed edge into the next hall. There, the support itself moves.


<!-- study-spine:tension_membrane -->

## Return: A little give

Change the added load while preserving the four anchors and material compliance. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses soft, constraint, force. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`tension`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-02-nengudi-a-little-give/index.html). Release the pink handle before RESET or the preset pull. The four supports stay fixed throughout.

<!-- study-edit:tension_membrane -->

### One source change: A little give

In tension_score.gd, change the last entry of LOAD_KG from 3.0 to 2.0. Predict and compare the settled centre height after the same pull and release. Keep the pins and compliance fixed. The constraint solver and mesh renderer are supplied; no new foundational capability is required.

```gdscript
const LOAD_KG := [0.0, 1.0, 2.0]
```

Source: `commons/artifacts/spine_studies/tension_score.gd`. Use the prepared scene to run and compare.

<!-- tension-reference -->

### Pull, wait, release

This return follows the hanging strips: those changed the fixed points. Here the four corner points stay pinned. The pink bead is one additional prescribed point only while you hold it. Desktop: right-click the bead, move your view, then right-click to release. XR uses the ordinary pickup grip. HOLD A PULL supplies the same target each time; RELEASE lets it move again. Release a hand-held bead before using the preset or RESET.

Start unloaded, use HOLD A PULL, then RELEASE. Watch the bead and the centre height. LOAD selects the next downward load: 0, 1, 3, then 0 kg. Compare one load at a time. MORE / LESS GIVE changes the links' compliance independently of that load. RESET restores the unloaded, settled starting configuration and the firmer setting.

The bead and black load marker are representations. The solver distributes the additional downward force over nine central nodes; there is no separate falling rigid weight. The remaining mesh is visual, not a barrier to the player. The four supports and the museum floor are solid. A bounded grip target and floor limit keep the small study in its space.

### The next close reading

Begin with the single array edit above. The supplied solver keeps three arrays: current positions, previous positions and rest positions. Gravity changes the free points. Distance links share the displacement between their ends; four indices are excluded from movement. A held bead temporarily adds another exclusion. Releasing it removes that exclusion without replacing its current position with its rest position.

`compliance` controls the distance links' response; `damping` removes motion over time. They do different jobs. A softer response may settle lower, while greater damping makes the journey quieter. Neither creates wear or a remembered injury. The rest lengths remain unchanged.


### Reference

Whitney identifies nylon hosiery and places the work in the RSVP series. Nengudi discusses bodily and psychological elasticity and the energy associated with previously worn material. Ada makes an original four-anchor membrane encounter, not a reconstruction or a measurement of her sculpture. Its knit-like opaque surface is procedural. It models reversible distance constraints, damping and a distributed downward load, with a floor limit; it does not simulate nylon, damage, self-collision, skin or a human body.

[Senga Nengudi: Internal I (1977, refabricated 2014)](https://whitney.org/collection/works/46609).

### SoftBodies_Carusell

Source: `commons/maps/SoftBodies_Carusell/tutorial.md`

# The support moves

<!-- @revolving_joy_ride -->

Stand where you can see the hub and the hanging bodies together. The ring turns because its angle is advanced by the program. The joints and deforming bodies respond to a support whose motion has already been prescribed.

Lower the SPEED. Then REVERSE it. Do the bodies immediately take up the new arrangement? STOP sets the angular rate to zero, but it does not erase velocity, gravity or contact. The support can stop commanding a new angle while its consequences continue.

The rate is measured in radians per second. A complete turn is `TAU` radians. The driven rotation connects this hall to Transformation and Oscillation, but the hanging bodies add a different problem: their current state matters to what happens next.

Change STIFFNESS or PRESSURE while watching a particular body. We should not attribute every difference to speed when we have also changed material coefficients. The apparatus makes a limited experiment possible, provided we remember what we touched.

This carousel offers an image of freedom through motion. Its moving parts also show how motion can be organized by obligations: a joint, a pin, a driven hub. The question is which relations can move, and which relations move them.



<!-- @cloth_straps -->

The cloth strips nearby retain a fixed support. Return to them after watching the ride. They make the contrast available at the same bodily scale: a surface can respond while its boundary remains still, or respond because its boundary is driven.

The sticks, pick-up cubes, flex pad and soft mushroom remain part of the collection. They are opportunities for further encounters, rather than evidence that every visible object runs the same solver. Begin with one comparison you can follow, then widen it.

In the next room, the enclosing architecture takes on a deformable surface. The distinction between a body and its surroundings becomes harder to maintain by pointing.

### SoftBodies_Obsticals

Source: `commons/maps/SoftBodies_Obsticals/tutorial.md`

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



<!-- @softbody_gallery_part2 -->

The nearby contact gallery keeps other combinations visible: soft bodies meet rigid obstructions. Look at one named cell before surveying the whole array. The specimen, its support and its settings constitute a particular test; their variety is not a single scale from hard to soft.

The flag dancer remains as another encounter with a driven system. Together these objects begin to distribute softness across the room rather than confine it to one specimen. Yet the museum crossing still has independent support. A deforming wall and an onward route make different promises.

Next we will hold and replay a contact experiment. A spectacle of differences becomes more useful when we can identify which differences were introduced.

### SoftBodies_Obsticals_Part2

Source: `commons/maps/SoftBodies_Obsticals_Part2/tutorial.md`

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

### SoftBodies_Playground_of_Joy

Source: `commons/maps/SoftBodies_Playground_of_Joy/tutorial.md`

# When does a body become a form?

<!-- @rounded_softbody_test -->

The rounded body continues to respond while an instrument colours its surface. MEASURE changes what is made legible: strain, collision or volume. The body has not acquired a new material because we changed its reading.

Keep the reading on volume and press FEEDBACK. Now the instrument acts back: it adjusts pressure to bring its reading toward the recorded value. Switching FEEDBACK off restores the selected pressure. It does not retrieve the body you had before.

What has been asked to stay the same? This instrument measures the box around the vertices, aligned with the room's axes. It does not measure the space enclosed by the skin. A fold can change the body without changing that box. A number that helped us look has become a number the body is asked to follow.

SQUEEZE changes the strength used by the artifact's existing squeeze interaction. STIFFNESS changes resistance in the solver. Watch the instrument as well as the silhouette. A colour scale can bring a small difference forward, or persuade us that its chosen quantity is the whole event.

The strain display compares the current vertex positions with recorded positions. That reference belongs to the model. Returning toward it is not a universal tendency toward an original or natural body; it is a particular constraint implemented here.

The branching study and field sculpture remain nearby, so the new capability can be compared with earlier ways of constructing an organic-looking form. A branch recipe, a deformed surface and a sampled field may resemble one another without explaining one another.



<!-- @frozen_glass_vessel -->

The glass vessel has already stopped. Its program begins with a sphere, pins an upper region and runs a custom soft-body simulation for a chosen number of steps. It then builds a surface from the resulting positions.

```gdscript
sim.gravity = Vector3(gravity_x, gravity_y, gravity_z)
sim.constraint_passes = 5
```

DURATION reconstructs the vessel using 40, 200 or 400 solver steps. GRAVITY changes the lateral component of the force. Compare duration first while the force remains fixed. These are numerical steps in a reconstruction, not seconds borrowed from the museum clock.

The object is evidence of a process, with most of that process absent. A different stop could have become the sculpture. Walk up to the frozen skin. Its surface can meet your body; transparency has not made it passable. Look for a mouth. This specimen began as a closed sphere, and deforming it has not cut an opening. To make a vessel we could enter, we would have to change more than its silhouette.

A frozen result lets us look longer. It also makes the timing of a decision disappear into the apparent permanence of a thing. Next, we will ask what else an image of a body invites us to infer.

### SoftBodies_Affect_Theory_Visualization

Source: `commons/maps/SoftBodies_Affect_Theory_Visualization/tutorial.md`

# What makes this look alive?

<!-- @radiolaria -->

The forms invite recognition before explanation. Spikes, rings and lattices suggest organisms, shells, pollen or something that might brush against skin. Let that recognition arrive, then keep it beside the question of how these objects were made.

Stop ROTATION. Toggle EFFECTS to change the particles surrounding the forms. What still looks alive when these motions cease? COLOUR also rebuilds the geometry in this implementation; with the initial unpinned random seed, it can change more than colour. Press SEED to choose a repeatable construction before comparing palettes. SPIKES changes a probability in that recipe; it does not teach an organism to defend itself.

The program constructs several families from geometric elements. Its parameters include `spikiness_probability`, `max_spike_length` and `detail_level`. These names describe decisions available to the generator. They are not measured properties of a living radiolarian.

We have arrived here with the ability to generate patterns, branch, deform a mesh and sample a process. That toolbox makes several accounts of an organic-looking object possible. Which one did you expect when you first saw these forms? What in their colour, repetition or motion supported that expectation?

The gap is productive. Desire can travel ahead of an explanation; a strange body can invite attention before we know how to describe it. Learning the recipe need not cancel that encounter. It gives us something specific to vary when the familiar repertoire begins to close around what a body is allowed to look like.

Radiolaria belongs here as an explicit contrast, not proof that static geometry is a soft-body simulation. In the next hall, spatial differences will be maintained by exchanges in an evolving field. Biological resemblance and a model of morphogenesis will finally meet as different claims we can examine.

### ProceduralGeneration_Reaction_Diffusion_Systems

Source: `commons/maps/ProceduralGeneration_Reaction_Diffusion_Systems/tutorial.md`

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



<!-- @reaction_diffusion -->

The second reaction–diffusion display remains a running comparison with its own implementation and settings. It is not a synchronized duplicate of the desk study. Look for recurring spatial features, then return to the controls before attributing a difference to one coefficient.

The soft-body samples, detailed bulge and Confessing Body theatre preserve further connections to the chapter. A chemical field can colour a wall, displace a surface or feed a growth rule, but each application needs an explicit mapping. Pattern formation alone has not made a solid that can bear your weight.

This matters to the red thread. New combinations become possible, and so do new confusions. A useful bridge should let us inspect the operation that carries a field into a form. The next artifact provides precisely such a mapping—and gives one of its controls an especially demanding name.

### Topology_Entropy_Morphogenesis

Source: `commons/maps/Topology_Entropy_Morphogenesis/tutorial.md`

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

---

## 18. Isosurfaces: Implicit to Explicit

### ISO_Introduction

Source: `commons/maps/ISO_Introduction/tutorial.md`

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

### ISO_LookupTable

Source: `commons/maps/ISO_LookupTable/tutorial.md`

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

### ISO_ShapesGallery

Source: `commons/maps/ISO_ShapesGallery/tutorial.md`

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

### ISO_TorusGyroid

Source: `commons/maps/ISO_TorusGyroid/tutorial.md`

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

### ISO_Sculpting

Source: `commons/maps/ISO_Sculpting/tutorial.md`

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

### ISO_FlatTerrain

Source: `commons/maps/ISO_FlatTerrain/tutorial.md`

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

### ISO_PortalLandscape

Source: `commons/maps/ISO_PortalLandscape/tutorial.md`

# Portal Landscape

The museum desk now exposes the existing ladder directly. TERMS adds overhang, cave, arch and outcrop contributions in order. HOLD keeps a mesh copy in the neighbouring bay, without collision. RESET returns the live hillside and preserves the copy; CLEAR removes it. The domain, sample grid, selected level and display transform remain fixed during the comparison. The names below describe intended tendencies to inspect, not guaranteed arches or traversable passages. RULE reveals the combined expression after observation.

Build a landscape by summing signed terms. Before it, the density must already be allowed to read `y` — a heightfield alone can hold no doorway.

Start from the heightfield.

```gdscript
func surface_height(p: Vector3) -> float:
    return noise.get_noise_2d(p.x * 0.01, p.z * 0.01) * 15.0 \
         + noise.get_noise_2d(p.x * 0.03, p.z * 0.03) * 5.0

func base_terrain(p: Vector3) -> float:
    return (surface_height(p) - p.y) / 30.0
```

Positive below the ground, negative above. One height per column. Nothing here can fold over your head.

Subtract an overhang.

```gdscript
func overhang(p: Vector3, w: float) -> float:
    var n := fbm(p, 4)
    var elevation := smoothstep(-10.0, 20.0, surface_height(p))
    var height_mod := sin(p.y * 0.1) * 0.5 + 0.5
    return n * elevation * w * lerp(0.3, 1.0, height_mod)
```

The term reads `p.y`, so density stops being a function of the column. `elevation` zones it: overhangs on the hills, none in the valleys.

Subtract a cave.

```gdscript
func cave(p: Vector3, w: float) -> float:
    return ridged(p, 3) * smoothstep(40.0, -10.0, p.y) * w
```

Below y = 40 the mask opens. This is the rung at which the landscape acquires an interior.

Subtract an arch.

```gdscript
func arch(p: Vector3, w: float) -> float:
    var pillars := absf(noise.get_noise_2d(p.x * 0.05, p.z * 0.05))
    var bands := sin(p.y * 0.15) * 0.5 + 0.5
    var mask := smoothstep(0.3, 0.7, noise.get_noise_2d(p.x * 0.02, p.z * 0.02))
    mask *= smoothstep(30.0, 5.0, absf(p.y - surface_height(p)))
    return pillars * bands * mask * w
```

Vertical pillars times horizontal bands. Solid columns with air between them — a passage, made by multiplying two periodic things.

Add an outcrop.

```gdscript
func outcrop(p: Vector3, w: float) -> float:
    var n := maxf(0.0, noise.get_noise_3d(p.x * 1.5, p.y * 1.5, p.z * 1.5))
    return n * n * smoothstep(surface_height(p) - 5.0,
                              surface_height(p) + 15.0, p.y) * w
```

The only added term. Clamped positive, then squared: it can put rock above the ground, never take any away.

Sum the five.

```gdscript
func density(p: Vector3, w: Array) -> float:
    return base_terrain(p) \
         - overhang(p, w[0]) - cave(p, w[1]) - arch(p, w[2]) \
         + outcrop(p, w[3])
```

No term draws a portal. A portal is where two subtractions overlap enough to drag the sum across the threshold.

Name the rungs.

```gdscript
const LANDFORM_WEIGHTS: Dictionary = {
    "hillside": [0.0, 0.0, 0.0, 0.0],
    "overhung": [0.8, 0.0, 0.0, 0.0],
    "quarried": [0.8, 0.6, 0.0, 0.0],
    "arched":   [0.8, 0.6, 0.4, 0.0],
    "compound": [0.8, 0.6, 0.4, 0.3],
}
@export_enum("hillside", "overhung", "quarried", "arched", "compound") var landform: String = "compound"
```

A ladder, not four knobs. Each rung adds exactly one claim to the one before it, so any change in the picture is attributable to a single term.

Threshold the sum.

```gdscript
func corner_bits(corners: PackedFloat32Array, iso: float) -> int:
    var bits := 0
    for i in 8:
        if corners[i] < iso:
            bits |= 1 << i
    return bits
```

Ground, cliff and doorway leave the field the same way: a sign change on one edge of one cell. The terrain does not contain the passage. The passage was already in the sum.

### ISO_Caves

Source: `commons/maps/ISO_Caves/tutorial.md`

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

### ISO_CaveGeneration

Source: `commons/maps/ISO_CaveGeneration/tutorial.md`

# Cave Generation

Give a volume one number per point and march it. Before it, the noise must be given a scale — a ratio between the field and the box that holds it.

Fix the ratio.

```gdscript
@export var noise_scale: float = 13.5
@export var chunk_scale: float = 300.0
@export var iso_level: float = 0.85

func sample_pos(world_pos: Vector3) -> Vector3:
    return (world_pos + noise_offset) * noise_scale / chunk_scale
```

13.5 over 300 metres is 0.045 per metre, so the first octave spans about 22 m. Noise has no size of its own. This division is where the cave gets one.

Sum ridged octaves.

```gdscript
func ridged_sum(p: Vector3, octaves: int) -> float:
    var sum := 0.0
    var amplitude := 1.0
    var weight := 1.0
    for i in octaves:
        var n := 1.0 - absf(noise.get_noise_3d(p.x, p.y, p.z))
        n *= n * weight
        weight = clampf(n * 10.0, 0.0, 1.0)
        sum += n * amplitude
        p *= 2.0
        amplitude *= 0.5
    return sum
```

`1 - abs` folds the noise at zero, so its crossings become creases; squaring sharpens them. `weight` carries forward, so an octave may only paint where the one before it already ridged. Fissures, not static.

Add the one term that knows which way is down.

```gdscript
func density(world_pos: Vector3, plumb_scale: float, octaves: int) -> float:
    var sum := ridged_sum(sample_pos(world_pos), octaves)
    return -(world_pos.y + 100.0) / 300.0 * plumb_scale + sum
```

Everything above it is isotropic. One linear bias makes low regions solid and high air — a horizon from outside, a floor from inside.

Scale that one term.

```gdscript
const PLUMB_SCALES: Dictionary = {
    "bedded": 1.0, "overturned": -1.0, "weightless": 0.0, "steep": 3.0,
}
@export_enum("bedded", "overturned", "weightless", "steep") var plumb: String = "bedded"
```

At `weightless` the term is gone and the sponge is isotropic. Nothing else in the field separates up from down, so the cave stops having a floor.

Choose how many scales to compute.

```gdscript
@export_range(1, 6) var octaves: int = 6

func get_params_array():
    var params = super.get_params_array()
    params.append(float(clampi(octaves, 1, 6)))
    return params
```

Octave k spans about 22 m / 2^k, and the lattice below samples every 4.69 m. Past the second octave the detail is computed and thrown away by the grid that reads it.

Lay the lattice.

```gdscript
const num_voxels_per_axis: int = 8 * 8   # work groups x local size

func run_compute() -> void:
    var list := rendering_device.compute_list_begin()
    rendering_device.compute_list_dispatch(list, 8, 8, 8)
    rendering_device.compute_list_end()
    rendering_device.submit()
```

262,144 cubes, each evaluated at its eight corners and cut against `iso_level`. No cell asks a neighbour anything, so one dispatch does the whole cave.

Count what came back.

```gdscript
num_triangles = counter_data_bytes.to_int32_array()[0]
verts.resize(num_triangles * 3)
```

A counter the cells incremented, not a size known in advance. How much cave there is cannot be told until the field has been evaluated.

Then look at the other body in the room.

```gdscript
@export var use_fallback: bool = false

func _create_simple_cave_mesh() -> void:
    for ring in range(101):
        var t: float = float(ring) / 100.0
        var r: float = 12.0 * (0.7 + 0.6 * sin(t * PI * 8.0))
        for seg in range(40):
            var a: float = float(seg) / 40.0 * TAU
            vertices.append(Vector3(cos(a) * r, sin(a) * r, (t - 0.5) * 200.0))
            normals.append(-Vector3(cos(a), sin(a), 0.0))
```

`marchingcave` sets `use_fallback = true`, so this runs and the shader never loads: a tube of rings around a winding line, normals turned inward. It reads as a cave and shares nothing with one. One surface was found in a field, the other was drawn, and the hall stands them side by side without saying which is which.

### ISO_AnimatedNoise

Source: `commons/maps/ISO_AnimatedNoise/tutorial.md`

# The Surface Chases the Field

Noise evolves; the isosurface follows. Animation here is not motion — it is re-extraction.

The cheapest time axis is a scrolling offset through 3D noise:

```gdscript
var t := 0.0

func density(p: Vector3) -> float:
    return noise.get_noise_3d(p.x, p.y, p.z + t * 0.6)   # slide the field past

func _process(delta: float) -> void:
    t += delta
    remesh()
```

The honest time axis is a fourth dimension — sample 4D noise so the field *changes in place* instead of drifting past:

```gdscript
func density_4d(p: Vector3) -> float:
    # two 3D samples faked into 4D: blend between two noise spaces over time
    var a := noise_a.get_noise_3d(p.x, p.y, p.z)
    var b := noise_b.get_noise_3d(p.x, p.y, p.z)
    return lerp(a, b, 0.5 + 0.5 * sin(t * 0.4))
```

With a scroll, blobs migrate across the room. With in-place evolution, they breathe — swelling, splitting, merging where they stand. Watch a blob divide: there is no "split" event anywhere in the code. Two maxima in the field drifted apart, and the threshold stopped connecting them.

Re-extracting every frame is the cost, so budget it:

```gdscript
func remesh() -> void:
    frame_counter += 1
    if frame_counter % 2 == 0:            # every other frame is plenty
        mesh_instance.mesh = extract(density, 24)   # modest resolution
```

Halving resolution is an 8× saving in cells; the eye forgives coarse triangles on a moving surface far more than it forgives a stutter.

Try: freeze `t` with a button. The mysterious breathing thing becomes an ordinary static sculpture instantly — proof that all the life was in the field's evolution, none of it in the geometry. Motion here is the *derivative of the field*, rendered; the previous sequence's calculus is running under this room.

### ISO_Metaballs

Source: `commons/maps/ISO_Metaballs/tutorial.md`

# Influence, summed

A metaball is a source, not a small solid. At every sample position the generator adds the source contributions, then extracts the surface at one threshold.

```gdscript
var total := 0.0
for source in sources:
    total += kernel(source, p)
return total - iso_level
```

Start with EMPLACE. The count remains ten while the same sources are arranged as column, ring, pair, shell or scatter. This is a change in provenance: where the contributors stand. KERNEL changes the falloff while the positions remain fixed. Compare the neck, the isolated lobes and the points where a bridge disappears.

HOLD keeps a copy of the earlier mesh. RULE opens the short statement that the visible surface is a threshold event, not a census of objects. The raymarched and Nakama specimens keep alternative implementations in view without collapsing them into one answer.

### ISO_ImplicitModeling

Source: `commons/maps/ISO_ImplicitModeling/tutorial.md`

# Shape as a Condition

A sphere is not vertices. It is a sentence: every point whose distance from the center equals the radius. Implicit modeling takes the sentence as the object.

Signed distance functions are the cleanest dialect — each returns *how far to the surface*, negative inside:

```gdscript
func sd_sphere(p: Vector3, r: float) -> float:
    return p.length() - r

func sd_box(p: Vector3, b: Vector3) -> float:
    var q := p.abs() - b
    return q.max(Vector3.ZERO).length() + min(max(q.x, max(q.y, q.z)), 0.0)

func sd_torus(p: Vector3, R: float, r: float) -> float:
    return Vector2(Vector2(p.x, p.z).length() - R, p.y).length() - r
```

The payoff is an algebra. Solid modeling becomes three one-liners:

```gdscript
func op_union(a: float, b: float) -> float:        return min(a, b)
func op_intersect(a: float, b: float) -> float:    return max(a, b)
func op_subtract(a: float, b: float) -> float:     return max(a, -b)
```

`min` says "the nearer surface wins" — union. `max` keeps only where both are inside — intersection. Negating one flips its inside out — subtraction. The entire CSG chapter of this curriculum, three functions.

The distinctly implicit move is the *smooth* union — blending shapes no mesh operation can blend:

```gdscript
func op_smooth_union(a: float, b: float, k: float) -> float:
    var h := clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return lerp(b, a, h) - k * h * (1.0 - h)
```

`k` is the fillet radius: 0 gives a hard seam, 0.5 melts the joint like wax. A model, then, is one function:

```gdscript
func model(p: Vector3) -> float:
    var body := op_smooth_union(sd_sphere(p - Vector3(0, 1, 0), 1.0),
                                sd_box(p, Vector3(1.2, 0.4, 1.2)), 0.3)
    return op_subtract(body, sd_torus(p - Vector3(0, 1.2, 0), 0.9, 0.25))
```

Feed `model` to marching cubes and it becomes walkable; hand it to a raymarcher and it renders without ever becoming a mesh at all.

Try: change one constant and re-extract. There is no undo stack because there was never an edit — only a claim about space, revised. The mesh was always just a quotation from the function.

### ISO_RhizomeBody

Source: `commons/maps/ISO_RhizomeBody/tutorial.md`

**Missing tutorial.md — no substitute text added.**

---

## 19. Boolean Surfaces: CSG as Composition

### Boolean_Verbs

Source: `commons/maps/Boolean_Verbs/tutorial.md`

# Tutorial · The Three Verbs

Start at the near end of the hall. Box and sphere recur in every bay, but their dimensions, offsets and colours also differ. Follow what each operation retains without attributing every visible difference to the verb alone. Read the result before reading the label. What does the boundary let your body do?

At **union**, the two surfaces become one result. The seam disappears because the region belonging to either operand is kept. In code the verb is an enum, not a second object:

```gdscript
combiner.operation = CSGShape3D.OPERATION_UNION
```

At **intersection**, keep only the region both operands claim. The placed overlap gives a survivor; if the operands were separated far enough, a successful operation could return no surface at all. This is an explanation of the rule, not a claim that this bay offers an offset control. At **difference**, subtract the sphere from the box. The cavity wall is generated by the operation; neither input carried that face as a separate object.

The three bays are one lesson in a fixed order: include, agree, remove. Return to the centre and say the expression aloud: `A ∪ B`, `A ∩ B`, `A − B`. Then ask what the grammar cannot say. The operation list does not settle operand order, placement or composition. Boundaries can vary continuously as operands move; connectedness can change at particular contacts. Reversing subtraction uses the same operator and produces a different result.

The next hall, **Boolean_Gallery**, lays out the hidden variants of these verbs. It asks whether a published ladder of values agrees with the code that builds it.

### Boolean_Gallery

Source: `commons/maps/Boolean_Gallery/tutorial.md`

# Tutorial · Where the Variants Stand

This hall is a catalogue you can walk. Each row is one artifact family. The four copies are the four values declared by its axis; the operands stay as constant as possible so the value is the thing you notice.

Begin with the first row, `csg_difference_demo`. Read the outcome, then the trace, then the operands, then the expression. The result becomes less hidden at every step. Continue to the union row and walk its fusion values in the code order: distinct, necked, lobed, single. Notice whether the museum presents them in that order.

At intersection, compare the survivors and the expectations their names bring. At subtraction_suite, follow the cutter growing relative to its body. At coincident_face, separate a picture of z-fighting from an actual depth contest. Finish with removal_room: the same survivors can be accompanied by no trace, a ghost of the removed volume, or a smaller scar.

The exercise is not to choose the prettiest copy. It is to compare three descriptions: the code, the registry, and the rendered body. Where they disagree, the disagreement is the material. The next hall, **Boolean_Works**, asks whether these operations can become inhabitable architecture.

### Boolean_Works

Source: `commons/maps/Boolean_Works/tutorial.md`

# Tutorial · When the Negative Gets Big

This is the scale test. In the first hall a subtraction made a cavity in a small solid. Here the negative is enlarged until it claims to be a room. Walk the hall in order and test that claim with your body.

Begin at the compose workbench. Five results turn above a table: union, intersection, both ordered differences and symmetric difference. Look for the promised handoff and notice what the scene actually affords. Then cross to the paired subtraction stations. Compare the cut and its material before you trust the word *same*.

The recursive cube is the hinge. Its holes resemble boolean subtraction, but the code never removes a volume; it declines to build selected cells. Between the visual wall and the SDF cavern, enter Boolean Burrow and return through the same opening. Its cylindrical cutters retain the old seeded centres but make the floor level. Compare the solid wall with the opening; collision is part of what makes that difference matter. At the architectural cavity and the SDF cavern, ask the practical question: where is the floor, and what collides with your body? A rendered hollow is not automatically an inhabitable hollow.

At the Boolean eggs, carry the three operations into a sculptural arrangement. The operands differ between specimens; this is not a controlled comparison of the verbs. In the teal egg, separate the geometric cut from the way its material presents depth.

For a small making exercise, duplicate `commons/artifacts/kapoor_void_studies/boolean_eggs.tscn` in the Day Zero project. In `_add_subtracted_egg`, change only `void_material.shading_mode` from `SHADING_MODE_UNSHADED` to `SHADING_MODE_PER_PIXEL`. Keep the camera, lights and cutter fixed. Compare the curved rim and the interior before touching the shape. The existing CSG construction and lighting are borrowed apparatus; this exercise changes one material decision.

Finish at the boolean variations and coincident face. The room has moved from verb to apparatus: a label, a camera, and a mesh can all claim an inside while the player remains outside it. The next sequence, swarm intelligence, changes the question from carving a body to coordinating many bodies.


<!-- study-spine:conical_sightline -->

## Return: One cut, three rooms

Translate the shared cutter 0.75 metres; keep the three walls. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses coordinates, transform, boolean. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`cut`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-matta-clark-one-cut/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-spine:kapoor_void_studies -->

## Return: The surface that says depth

Change the cavity from unlit black to lit chalk; keep its geometry. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses boolean, shader. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`void`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-kapoor-surface-and-depth/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:conical_sightline -->

### One source change: One cut, three rooms

The SHIFT CUT control uses this setter. Try 0.35 metres instead; all six cutter instances share the same offset, including the retained intersections.

```gdscript
set_cut_x(0.75)
```

Source: `commons/artifacts/conical_sightline/conical_sightline.gd`. Use the prepared scene to run and compare.

<!-- study-edit:kapoor_void_studies -->

### One source change: The surface that says depth

The BLACK / CHALK control calls this setter. Compare from one fixed position. It replaces materials without rebuilding the bowl mesh.

```gdscript
set_black_surface(false)
```

Source: `commons/artifacts/kapoor_void_studies/kapoor_void_studies.gd`. Use the prepared scene to run and compare.

---

## 20. Swarm Intelligence: Where Coordination Lives

### SwarmIntelligence_PhysarumColony

Source: `commons/maps/SwarmIntelligence_PhysarumColony/tutorial.md`

# Physarum Colony

Slime mould finds shortest paths. Deposits chemical trails.

Build a scalar trail field.

```gdscript
@export var grid_size: Vector2i = Vector2i(256, 256)
var trail: Array = []

func initialise_trail() -> void:
    trail.clear()
    for y in grid_size.y:
        var row: Array = []
        for x in grid_size.x:
            row.append(0.0)
        trail.append(row)
```

A 2D scalar field. Each cell stores the local trail intensity.

Spawn physarum agents.

```gdscript
class_name PhysarumAgent

var position: Vector2
var direction: float  # radians

func random_agent(bounds: Vector2) -> PhysarumAgent:
    var a := PhysarumAgent.new()
    a.position = Vector2(randf() * bounds.x, randf() * bounds.y)
    a.direction = randf() * TAU
    return a
```

Each agent has position and heading. Thousands cover the grid.

Sense the trail ahead.

```gdscript
@export var sensor_angle: float = 0.5  # radians
@export var sensor_distance: float = 5.0

func sense(agent: PhysarumAgent) -> float:
    var sensor_pos := agent.position + Vector2(cos(agent.direction), sin(agent.direction)) * sensor_distance
    var x: int = clamp(int(sensor_pos.x), 0, grid_size.x - 1)
    var y: int = clamp(int(sensor_pos.y), 0, grid_size.y - 1)
    return trail[y][x]
```

Sample the trail at a point ahead of the agent. Three sensors (left, centre, right) let the agent turn toward the strongest trail.

Move toward the strongest sensor.

```gdscript
func turn_toward_trail(agent: PhysarumAgent) -> void:
    var forward := sense(agent)
    var left := sense_with_offset(agent, -sensor_angle)
    var right := sense_with_offset(agent, sensor_angle)
    if left > forward and left > right:
        agent.direction -= sensor_angle * 0.5
    elif right > forward and right > left:
        agent.direction += sensor_angle * 0.5
```

Three sensors; turn toward the strongest. Stays straight when forward is strongest.

Deposit trail.

```gdscript
@export var deposit_amount: float = 0.1

func deposit(agent: PhysarumAgent) -> void:
    var x: int = clamp(int(agent.position.x), 0, grid_size.x - 1)
    var y: int = clamp(int(agent.position.y), 0, grid_size.y - 1)
    trail[y][x] += deposit_amount
```

Every step adds to the trail. Repeated visits reinforce the path.

Diffuse the trail.

```gdscript
@export var diffusion_rate: float = 0.1
@export var decay_rate: float = 0.02

func diffuse_trail() -> void:
    var new_trail: Array = []
    for y in grid_size.y:
        var row: Array = []
        for x in grid_size.x:
            var sum: float = 0.0
            for dy in [-1, 0, 1]:
                for dx in [-1, 0, 1]:
                    sum += trail[(y + dy + grid_size.y) % grid_size.y][(x + dx + grid_size.x) % grid_size.x]
            var avg: float = sum / 9.0
            var blended: float = trail[y][x] * (1 - diffusion_rate) + avg * diffusion_rate
            row.append(blended * (1 - decay_rate))
        new_trail.append(row)
    trail = new_trail
```

Gaussian-like blur followed by exponential decay. Diffusion spreads the trail; decay erases it.

Full simulation loop.

```gdscript
func _physics_process(_delta: float) -> void:
    for agent in agents:
        turn_toward_trail(agent)
        agent.position += Vector2(cos(agent.direction), sin(agent.direction)) * 1.0
        deposit(agent)
    diffuse_trail()
```

Turn, move, deposit, diffuse. Over many frames, stable paths emerge between food sources.

You can now build a physarum colony with sensory agents, a scalar trail field, and diffusion-decay dynamics. SwarmIntelligence_FlowFields extends into pre-computed navigation fields.

### SwarmIntelligence_FlowFields

Source: `commons/maps/SwarmIntelligence_FlowFields/tutorial.md`

# Flow Fields

Precompute directions across a grid. Agents follow the field.

Build a 2D vector field.

```gdscript
@export var grid_size: Vector2i = Vector2i(32, 32)
var field: Array = []  # 2D array of Vector2

func initialise_field() -> void:
    for y in grid_size.y:
        field.append([])
        for x in grid_size.x:
            field[y].append(Vector2.ZERO)
```

Each cell stores a direction. Agents sample the field at their position.

Compute a radial field.

```gdscript
func compute_radial_field(centre: Vector2i) -> void:
    for y in grid_size.y:
        for x in grid_size.x:
            var direction: Vector2 = Vector2(centre.x - x, centre.y - y)
            if direction.length() > 0:
                field[y][x] = direction.normalized()
```

Every cell points toward the centre. Agents released into this field converge.

Compute a Dijkstra field.

```gdscript
func compute_dijkstra_field(goal: Vector2i, is_passable: Callable) -> void:
    var distance: Array = []
    for y in grid_size.y:
        distance.append([])
        for x in grid_size.x:
            distance[y].append(INF)
    distance[goal.y][goal.x] = 0
    var queue: Array = [goal]
    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        for neighbour in get_neighbours(current):
            if not is_passable.call(neighbour): continue
            var new_dist: float = distance[current.y][current.x] + 1
            if new_dist < distance[neighbour.y][neighbour.x]:
                distance[neighbour.y][neighbour.x] = new_dist
                queue.push_back(neighbour)
    for y in grid_size.y:
        for x in grid_size.x:
            field[y][x] = steepest_descent(x, y, distance)
```

BFS-based. The field points agents toward the nearest goal along the shortest walkable path.

Find steepest descent.

```gdscript
func steepest_descent(x: int, y: int, distance: Array) -> Vector2:
    var best := Vector2.ZERO
    var best_dist: float = distance[y][x]
    for dy in [-1, 0, 1]:
        for dx in [-1, 0, 1]:
            if dx == 0 and dy == 0: continue
            var nx: int = x + dx; var ny: int = y + dy
            if nx < 0 or nx >= grid_size.x or ny < 0 or ny >= grid_size.y: continue
            if distance[ny][nx] < best_dist:
                best_dist = distance[ny][nx]; best = Vector2(dx, dy)
    return best.normalized()
```

Search neighbours for the cell with lowest distance. Field direction points there.

Sample the field for an agent.

```gdscript
func sample_field(position: Vector2) -> Vector2:
    var x: int = clamp(int(position.x), 0, grid_size.x - 1)
    var y: int = clamp(int(position.y), 0, grid_size.y - 1)
    return field[y][x]
```

Direct cell lookup. For smoother motion, bilinear interpolation between four corners.

Agents follow the field.

```gdscript
func _physics_process(delta: float) -> void:
    for agent in agents:
        var force: Vector2 = sample_field(agent.position) * 2.0
        agent.velocity += force * delta
        agent.velocity = agent.velocity.limit_length(3.0)
        agent.position += agent.velocity * delta
```

Apply field force; cap velocity; move. The agent traces a path along the field.

You can now build a 2D flow field, compute radial and Dijkstra variants, and steer agents through it. SwarmIntelligence_Boids_Algorithm extends into reynolds flocking.

### SwarmIntelligence_Boids_Algorithm

Source: `commons/maps/SwarmIntelligence_Boids_Algorithm/tutorial.md`

# Boids Algorithm

Reynolds' three rules. Separation, alignment, cohesion.

Define a boid.

```gdscript
class_name Boid

var position: Vector3
var velocity: Vector3

func random_boid(bounds: AABB, max_speed: float) -> Boid:
    var b := Boid.new()
    b.position = Vector3(
        randf_range(bounds.position.x, bounds.end.x),
        randf_range(bounds.position.y, bounds.end.y),
        randf_range(bounds.position.z, bounds.end.z)
    )
    b.velocity = Vector3(randfn(0, 1), randfn(0, 1), randfn(0, 1)).normalized() * max_speed
    return b
```

Position and velocity. No acceleration — the steering forces drive the velocity directly.

Compute separation.

```gdscript
@export var separation_radius: float = 1.0

func separation(self_boid: Boid, flock: Array) -> Vector3:
    var steer := Vector3.ZERO
    var count: int = 0
    for other in flock:
        if other == self_boid: continue
        var distance: float = self_boid.position.distance_to(other.position)
        if distance < separation_radius and distance > 0:
            var away: Vector3 = (self_boid.position - other.position).normalized() / distance
            steer += away
            count += 1
    if count > 0: steer /= count
    return steer
```

Push away from close neighbours. Weighted by inverse distance — closer neighbours repel harder.

Compute alignment.

```gdscript
@export var perception_radius: float = 3.0

func alignment(self_boid: Boid, flock: Array) -> Vector3:
    var avg_velocity := Vector3.ZERO
    var count: int = 0
    for other in flock:
        if other == self_boid: continue
        if self_boid.position.distance_to(other.position) < perception_radius:
            avg_velocity += other.velocity
            count += 1
    if count == 0: return Vector3.ZERO
    return (avg_velocity / count - self_boid.velocity).normalized()
```

Match the average velocity of nearby boids. The boid turns toward the flock's shared direction.

Compute cohesion.

```gdscript
func cohesion(self_boid: Boid, flock: Array) -> Vector3:
    var centre := Vector3.ZERO
    var count: int = 0
    for other in flock:
        if other == self_boid: continue
        if self_boid.position.distance_to(other.position) < perception_radius:
            centre += other.position
            count += 1
    if count == 0: return Vector3.ZERO
    return ((centre / count) - self_boid.position).normalized()
```

Move toward the centre of nearby boids. The flock stays together.

Combine the three forces.

```gdscript
@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0

func compute_steering(self_boid: Boid, flock: Array) -> Vector3:
    return (
        separation(self_boid, flock) * separation_weight +
        alignment(self_boid, flock) * alignment_weight +
        cohesion(self_boid, flock) * cohesion_weight
    )
```

Three rules, three weights. Tuning the weights changes the flock's character.

Update all boids.

```gdscript
@export var max_speed: float = 4.0

func _physics_process(delta: float) -> void:
    for boid in flock:
        var steering: Vector3 = compute_steering(boid, flock)
        boid.velocity += steering * delta
        boid.velocity = boid.velocity.limit_length(max_speed)
        boid.position += boid.velocity * delta
```

Each boid computes its steering independently. O(N²) for a naive implementation; spatial partitioning reduces this.

You can now build boids, compute Reynolds' three rules, combine them with weights, and update the flock. SwarmIntelligence_Agent_Based_Modeling_ABM extends into stateful agents.

### SwarmIntelligence_Agent_Based_Modeling_ABM

Source: `commons/maps/SwarmIntelligence_Agent_Based_Modeling_ABM/tutorial.md`

# Agent Based Modeling

Stateful agents with perception radius. Each acts on local information.

Define a stateful agent.

```gdscript
class_name ABMAgent extends CharacterBody3D

@export var perception_radius: float = 3.0
@export var max_speed: float = 2.0

enum State { FORAGING, FOLLOWING, RESTING }
var current_state: int = State.FORAGING
```

State machine. The state determines behaviour; transitions happen based on perception.

Perceive neighbours.

```gdscript
func perceive() -> Array:
    var neighbours: Array = []
    for other in get_tree().get_nodes_in_group("abm_agents"):
        if other == self: continue
        if global_position.distance_to(other.global_position) < perception_radius:
            neighbours.append(other)
    return neighbours
```

Local view. Agents don't know about other agents outside the radius.

State transitions.

```gdscript
func update_state(neighbours: Array) -> void:
    var nearby_states: Dictionary = {}
    for n in neighbours:
        nearby_states[n.current_state] = nearby_states.get(n.current_state, 0) + 1
    var dominant: int = dominant_state(nearby_states)
    if nearby_states.get(dominant, 0) > 3:
        current_state = dominant  # copy the local majority
```

Copy the majority. Social conformity at the local scale; polarisation at the global scale.

Behaviour by state.

```gdscript
func _physics_process(delta: float) -> void:
    var neighbours := perceive()
    update_state(neighbours)
    match current_state:
        State.FORAGING: forage(delta)
        State.FOLLOWING: follow(neighbours, delta)
        State.RESTING: rest(delta)
    move_and_slide()
```

Different behaviours per state. The state machine drives the agent's action.

Foraging: random walk.

```gdscript
func forage(delta: float) -> void:
    if randf() < 0.1:
        var new_direction := Vector3(randfn(0, 1), 0, randfn(0, 1)).normalized()
        velocity = new_direction * max_speed
```

Random direction changes every few frames. The agent wanders.

Following: move toward neighbours' centroid.

```gdscript
func follow(neighbours: Array, delta: float) -> void:
    if neighbours.is_empty(): return
    var centroid := Vector3.ZERO
    for n in neighbours:
        centroid += n.global_position
    centroid /= neighbours.size()
    var direction: Vector3 = (centroid - global_position).normalized()
    velocity = direction * max_speed
```

Head toward where the crowd is. Produces clumping.

Resting: stay still.

```gdscript
func rest(delta: float) -> void:
    velocity = Vector3.ZERO
    if randf() < 0.005:  # occasionally wake up
        current_state = State.FORAGING
```

Zero velocity. Low wake probability means rest is the default stable state once entered.

Count agents by state.

```gdscript
func population_by_state() -> Dictionary:
    var counts: Dictionary = {}
    for agent in get_tree().get_nodes_in_group("abm_agents"):
        counts[agent.current_state] = counts.get(agent.current_state, 0) + 1
    return counts
```

Global statistics. Tracks the population's state distribution over time.

You can now build stateful ABM agents with perception, majority-based state transitions, per-state behaviours, and global state statistics. SwarmIntelligence_Ant_Colony_Optimization extends into path-finding via pheromones.

Reset the simulation.

```gdscript
func reset_swarm(count: int, bounds: Rect2) -> Array:
    return initialise_swarm(count, bounds)
```

Fresh start. Same bounds, new random initial conditions.

### SwarmIntelligence_Ant_Colony_Optimization

Source: `commons/maps/SwarmIntelligence_Ant_Colony_Optimization/tutorial.md`

# Ant Colony Optimization

Ants find shortest paths. Pheromones mark good routes.

Define a pheromone graph.

```gdscript
class_name ACOGraph

var vertices: Array = []
var distance: Dictionary = {}      # [u, v] -> distance
var pheromone: Dictionary = {}     # [u, v] -> pheromone amount

func add_edge(u, v, d: float) -> void:
    distance[[u, v]] = d
    distance[[v, u]] = d
    pheromone[[u, v]] = 1.0
    pheromone[[v, u]] = 1.0
    if not u in vertices: vertices.append(u)
    if not v in vertices: vertices.append(v)
```

Bidirectional edges with distance and initial pheromone. The pheromone is mutable.

Probability of picking an edge.

```gdscript
@export var alpha: float = 1.0  # pheromone weight
@export var beta: float = 2.0   # distance weight

func edge_probability(u, v, visited: Array) -> float:
    if v in visited: return 0.0
    var tau: float = pheromone.get([u, v], 0.1) ** alpha
    var eta: float = pow(1.0 / distance[[u, v]], beta)
    return tau * eta
```

Higher pheromone + shorter distance → higher probability. Alpha and beta tune the balance.

Choose the next vertex.

```gdscript
func choose_next(current, visited: Array, graph: ACOGraph) -> Variant:
    var probabilities: Dictionary = {}
    var total: float = 0.0
    for v in graph.vertices:
        if v == current or v in visited: continue
        var p: float = graph.edge_probability(current, v, visited)
        probabilities[v] = p
        total += p
    if total == 0.0: return null
    var r: float = randf() * total
    var cumulative: float = 0.0
    for v in probabilities:
        cumulative += probabilities[v]
        if r < cumulative: return v
    return null
```

Roulette-wheel selection. Higher-probability edges are chosen more often.

One ant builds a tour.

```gdscript
func build_tour(start, graph: ACOGraph) -> Array:
    var tour: Array = [start]
    var current = start
    while tour.size() < graph.vertices.size():
        var next = choose_next(current, tour, graph)
        if next == null: break
        tour.append(next)
        current = next
    if tour.size() == graph.vertices.size():
        tour.append(start)  # return home
    return tour
```

Greedy construction guided by probabilities. Ants don't backtrack.

Deposit pheromone.

```gdscript
@export var pheromone_deposit: float = 1.0

func deposit_on_tour(tour: Array, graph: ACOGraph) -> void:
    var total_distance: float = 0.0
    for i in range(tour.size() - 1):
        total_distance += graph.distance[[tour[i], tour[i + 1]]]
    var amount: float = pheromone_deposit / total_distance
    for i in range(tour.size() - 1):
        graph.pheromone[[tour[i], tour[i + 1]]] += amount
        graph.pheromone[[tour[i + 1], tour[i]]] += amount
```

Shorter tours deposit more pheromone. Good paths reinforce themselves.

Evaporate pheromone.

```gdscript
@export var evaporation_rate: float = 0.1

func evaporate(graph: ACOGraph) -> void:
    for edge in graph.pheromone:
        graph.pheromone[edge] *= (1.0 - evaporation_rate)
```

Reduces all pheromones each iteration. Prevents early paths from dominating forever.

Run one iteration.

```gdscript
func iteration(graph: ACOGraph, ant_count: int) -> Array:
    var best_tour: Array = []
    var best_length: float = INF
    for _i in ant_count:
        var tour: Array = build_tour(graph.vertices[0], graph)
        if tour.size() == graph.vertices.size() + 1:
            deposit_on_tour(tour, graph)
            var length: float = tour_length(tour, graph)
            if length < best_length:
                best_length = length; best_tour = tour
    evaporate(graph)
    return best_tour
```

Each iteration: all ants build tours; deposit pheromones; evaporate. Over iterations, the best tour emerges.

You can now build an ACO graph, compute edge probabilities, construct tours, deposit and evaporate pheromones, and iterate the algorithm toward shortest paths. SwarmIntelligence_Particle_Swarm_Optimization extends to continuous optimisation.

### SwarmIntelligence_Particle_Swarm_Optimization

Source: `commons/maps/SwarmIntelligence_Particle_Swarm_Optimization/tutorial.md`

# Particle Swarm Optimization

Particles search the space. Each remembers its best; all share the global best.

Define a particle.

```gdscript
class_name PSOParticle

var position: Vector2
var velocity: Vector2
var personal_best_position: Vector2
var personal_best_score: float = INF
```

Position, velocity, and personal best tracked. Each particle is self-contained.

Initialise a swarm.

```gdscript
func initialise_swarm(count: int, bounds: Rect2) -> Array:
    var swarm: Array = []
    for _i in count:
        var p := PSOParticle.new()
        p.position = Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))
        p.velocity = Vector2(randfn(0, 1), randfn(0, 1))
        p.personal_best_position = p.position
        swarm.append(p)
    return swarm
```

Random initial positions and velocities. Covers the search space broadly.

Evaluate the fitness function.

```gdscript
func rastrigin(p: Vector2) -> float:
    var A: float = 10.0
    var n: int = 2
    return A * n + (p.x * p.x - A * cos(2.0 * PI * p.x)) + (p.y * p.y - A * cos(2.0 * PI * p.y))
```

Rastrigin has many local minima and one global minimum at the origin. Standard test function.

Update velocity.

```gdscript
@export var inertia: float = 0.7
@export var cognitive: float = 1.5
@export var social: float = 1.5

func update_velocity(particle: PSOParticle, global_best: Vector2) -> void:
    var r1: float = randf()
    var r2: float = randf()
    particle.velocity = (
        particle.velocity * inertia +
        (particle.personal_best_position - particle.position) * cognitive * r1 +
        (global_best - particle.position) * social * r2
    )
    particle.velocity = particle.velocity.limit_length(5.0)
```

Three contributions: inertia (keep going), cognitive (toward personal best), social (toward global best). Random factors add exploration.

Update position.

```gdscript
func update_position(particle: PSOParticle) -> void:
    particle.position += particle.velocity
```

Simple Euler step. The particle moves according to its new velocity.

Update bests.

```gdscript
var global_best_position: Vector2
var global_best_score: float = INF

func update_bests(particle: PSOParticle) -> void:
    var score: float = rastrigin(particle.position)
    if score < particle.personal_best_score:
        particle.personal_best_score = score
        particle.personal_best_position = particle.position
    if score < global_best_score:
        global_best_score = score
        global_best_position = particle.position
```

Check current position against personal and global bests. Update if improved.

Run one iteration.

```gdscript
func iteration(swarm: Array) -> void:
    for particle in swarm:
        update_velocity(particle, global_best_position)
        update_position(particle)
        update_bests(particle)
```

One update per particle. Over many iterations, the swarm converges on the global minimum.

You can now initialise a swarm, evaluate fitness via Rastrigin, update velocities with inertia/cognitive/social terms, and track personal and global bests. SwarmIntelligence_Swarm_Intelligence_Algorithms extends into a gallery of algorithms.

Reset the simulation.

```gdscript
func reset_swarm(count: int, bounds: Rect2) -> Array:
    return initialise_swarm(count, bounds)
```

Fresh start. Same bounds, new random initial conditions.

### SwarmIntelligence_Swarm_Intelligence_Algorithms

Source: `commons/maps/SwarmIntelligence_Swarm_Intelligence_Algorithms/tutorial.md`

# Swarm Intelligence Algorithms

A gallery of swarm methods. Common agent interface.

Define the common interface.

```gdscript
class_name SwarmAlgorithm

func initialize(agent) -> void: pass
func perceive(agent, environment) -> Dictionary: return {}
func decide(agent, perceptions: Dictionary) -> Dictionary: return {}
func act(agent, decision: Dictionary) -> void: pass
func update_environment(environment, agent, action) -> void: pass
```

Five-phase agent loop. Each algorithm overrides these hooks.

Physarum algorithm.

```gdscript
class_name PhysarumAlgorithm extends SwarmAlgorithm

func perceive(agent, env) -> Dictionary:
    return {
        "trail_forward": env.sample_trail(agent.position + agent.forward()),
        "trail_left": env.sample_trail(agent.position + agent.left()),
        "trail_right": env.sample_trail(agent.position + agent.right()),
    }

func decide(agent, perceptions: Dictionary) -> Dictionary:
    if perceptions.trail_left > perceptions.trail_forward:
        return {"turn": -1}
    elif perceptions.trail_right > perceptions.trail_forward:
        return {"turn": 1}
    return {"turn": 0}

func act(agent, decision: Dictionary) -> void:
    agent.rotate(decision.turn * 0.1)
    agent.move_forward(1.0)

func update_environment(env, agent, action) -> void:
    env.deposit_trail_at(agent.position, 0.1)
```

Trail sensing and deposition. The agent navigates by gradients in the environment.

Boids algorithm.

```gdscript
class_name BoidsAlgorithm extends SwarmAlgorithm

func perceive(agent, env) -> Dictionary:
    return {"neighbours": env.neighbours_of(agent, 3.0)}

func decide(agent, perceptions: Dictionary) -> Dictionary:
    var sep := separation(agent, perceptions.neighbours)
    var ali := alignment(agent, perceptions.neighbours)
    var coh := cohesion(agent, perceptions.neighbours)
    return {"steering": sep * 1.5 + ali + coh}
```

Perception is local neighbours; decision is Reynolds' three rules combined.

Stack algorithms.

```gdscript
class_name LayeredSwarm

var algorithms: Array = []

func run_frame(agents: Array, environment):
    for agent in agents:
        for algo in algorithms:
            algo.initialize(agent)
            var perceptions: Dictionary = algo.perceive(agent, environment)
            var decision: Dictionary = algo.decide(agent, perceptions)
            algo.act(agent, decision)
            algo.update_environment(environment, agent, decision)
```

Multiple algorithms applied in sequence. Each layer adds behaviour.

Compare algorithms.

```gdscript
func run_comparison(algorithms: Array, env, duration: float) -> Dictionary:
    var results: Dictionary = {}
    for algo in algorithms:
        var agents := spawn_agents(30)
        for algo_instance in algorithms:
            pass  # setup
        await get_tree().create_timer(duration).timeout
        results[algo.get_name()] = measure_performance(agents, env)
    return results
```

Run each algorithm on the same environment. Compare metrics like coverage, convergence, trail density.

Visualise the gallery.

```gdscript
func populate_gallery(algorithms: Array) -> void:
    for i in algorithms.size():
        var position := Vector3(i * 4, 0, 0)
        var ghost_env := create_gallery_zone(position)
        var ghost_agents := spawn_agents_in(ghost_env, 20)
        ghost_env.run_algorithm(algorithms[i])
```

Each algorithm gets its own zone in the gallery. Visitors see them side by side.

You can now define a common agent interface, implement physarum and boids variants, stack algorithm layers, compare performance, and populate a gallery. Chamber_Swarm closes the sequence with swarm-on-swarm encounter.

---

## 21. Machine Learning: What Changes, and Why?

### ML_Evolution

Source: `commons/maps/ML_Evolution/tutorial.md`

# ML Evolution

A genetic algorithm. Population, selection, mutation.

Define a creature genome.

```gdscript
class_name Genome

var genes: Array = []  # array of floats in [-1, 1]

func random_genome(size: int) -> void:
    genes.clear()
    for _i in size:
        genes.append(randf_range(-1.0, 1.0))
```

An array of real-valued parameters. Each gene influences one behaviour weight.

Build a creature from a genome.

```gdscript
func spawn_creature(genome: Genome) -> CharacterBody3D:
    var creature := CREATURE_SCENE.instantiate()
    creature.set_weights(genome.genes)
    add_child(creature)
    return creature
```

The creature reads the weights and uses them to drive its motion.

Evaluate fitness.

```gdscript
func evaluate_fitness(genome: Genome) -> float:
    var creature := spawn_creature(genome)
    var start := creature.global_position
    await get_tree().create_timer(10.0).timeout
    var distance: float = start.distance_to(creature.global_position)
    creature.queue_free()
    return distance
```

Run the creature for 10 seconds; measure distance travelled. Fitness is the distance.

Tournament selection.

```gdscript
func tournament_select(population: Array, k: int = 3) -> Genome:
    var contestants: Array = []
    for _i in k:
        contestants.append(population[randi() % population.size()])
    contestants.sort_custom(func(a, b): return a.fitness > b.fitness)
    return contestants[0]
```

Pick k random genomes; return the best. Larger k means stronger selection pressure.

Crossover.

```gdscript
func crossover(parent_a: Genome, parent_b: Genome) -> Genome:
    var child := Genome.new()
    for i in parent_a.genes.size():
        child.genes.append(parent_a.genes[i] if randf() < 0.5 else parent_b.genes[i])
    return child
```

Uniform crossover. Each gene comes from one parent at random.

Mutation.

```gdscript
func mutate(genome: Genome, rate: float = 0.1, strength: float = 0.2) -> void:
    for i in genome.genes.size():
        if randf() < rate:
            genome.genes[i] += randfn(0.0, strength)
            genome.genes[i] = clamp(genome.genes[i], -1.0, 1.0)
```

Each gene has a chance of Gaussian perturbation. Rate and strength are tunable.

Run the generation loop.

```gdscript
func run_generation(population: Array, size: int) -> Array:
    for g in population:
        g.fitness = await evaluate_fitness(g)
    var next_gen: Array = []
    population.sort_custom(func(a, b): return a.fitness > b.fitness)
    # Elitism: top 20% carry over
    for i in size / 5:
        next_gen.append(population[i])
    while next_gen.size() < size:
        var parent_a := tournament_select(population)
        var parent_b := tournament_select(population)
        var child := crossover(parent_a, parent_b)
        mutate(child)
        next_gen.append(child)
    return next_gen
```

Elitism preserves the best; the rest are produced by crossover and mutation. Elitism prevents regression.

You can now build a genetic algorithm with genomes, fitness evaluation, tournament selection, crossover, and mutation. ML_Gradient_Landscape extends into calculus-driven optimisation.

Reset a population.

```gdscript
func reset_population(size: int, gene_count: int) -> Array:
    var p: Array = []
    for _i in size:
        var g := Genome.new()
        g.random_genome(gene_count)
        p.append(g)
    return p
```

Start fresh. Used when the current population has collapsed onto a local optimum.

### ML_Gradient_Landscape

Source: `commons/maps/ML_Gradient_Landscape/tutorial.md`

# ML Gradient Landscape

Gradient descent. Compute the slope; step downhill.

Define a loss function.

```gdscript
func loss(p: Vector2) -> float:
    return (p.x * p.x + p.y - 11) ** 2 + (p.x + p.y * p.y - 7) ** 2  # Himmelblau
```

Himmelblau's function. Four global minima at comparable values.

Compute the gradient numerically.

```gdscript
func gradient(p: Vector2, h: float = 0.001) -> Vector2:
    var dx: float = (loss(Vector2(p.x + h, p.y)) - loss(Vector2(p.x - h, p.y))) / (2 * h)
    var dy: float = (loss(Vector2(p.x, p.y + h)) - loss(Vector2(p.x, p.y - h))) / (2 * h)
    return Vector2(dx, dy)
```

Central-difference approximation. Two function evaluations per axis.

Vanilla gradient descent step.

```gdscript
func gd_step(p: Vector2, lr: float = 0.05) -> Vector2:
    return p - gradient(p) * lr
```

Move opposite to the gradient, scaled by the learning rate.

Momentum gradient descent.

```gdscript
var velocity: Vector2 = Vector2.ZERO

func momentum_step(p: Vector2, lr: float = 0.05, momentum: float = 0.9) -> Vector2:
    velocity = velocity * momentum - gradient(p) * lr
    return p + velocity
```

Accumulate velocity across steps. Escapes shallow local minima.

Adam optimiser.

```gdscript
var m: Vector2 = Vector2.ZERO  # first moment
var v: Vector2 = Vector2.ZERO  # second moment
var t: int = 0
@export var beta1: float = 0.9
@export var beta2: float = 0.999
@export var eps: float = 1e-8

func adam_step(p: Vector2, lr: float = 0.05) -> Vector2:
    t += 1
    var g := gradient(p)
    m = m * beta1 + g * (1 - beta1)
    v = Vector2(v.x * beta2 + g.x * g.x * (1 - beta2), v.y * beta2 + g.y * g.y * (1 - beta2))
    var m_hat: Vector2 = m / (1 - pow(beta1, t))
    var v_hat: Vector2 = v / (1 - pow(beta2, t))
    return p - Vector2(lr * m_hat.x / (sqrt(v_hat.x) + eps), lr * m_hat.y / (sqrt(v_hat.y) + eps))
```

Per-parameter adaptive learning rates. Adam is the default optimiser in modern deep learning.

Render the loss surface.

```gdscript
func render_surface(bounds: Vector2, resolution: int = 64) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for y in resolution:
        for x in resolution:
            var p := Vector2(x, y) / resolution * bounds - bounds / 2
            var height: float = loss(p)
            st.add_vertex(Vector3(p.x, height, p.y))
    # ... triangulation
    return st.commit()
```

A grid of vertices at computed heights. The mesh shows the terrain gradient descent walks.

Animate the descent.

```gdscript
func animate_descent(p_start: Vector2, steps: int) -> void:
    var p := p_start
    for _i in steps:
        p = adam_step(p)
        mark_position(p)
        await get_tree().create_timer(0.1).timeout
```

Each step drops a marker. The trail shows the optimiser's trajectory.

You can now compute gradients numerically, step via vanilla/momentum/Adam, render a loss surface, and animate the descent. ML_Classification extends into decision boundaries.

### ML_Classification

Source: `commons/maps/ML_Classification/tutorial.md`

# ML Classification

Separate classes in feature space. K-means, SVM, neural network.

Label a dataset.

```gdscript
class_name LabeledDataset

var points: Array = []   # Vector2
var labels: Array = []   # int (class indices)

func add_point(p: Vector2, label: int) -> void:
    points.append(p)
    labels.append(label)
```

A labelled point cloud. Two classes for the simplest case.

K-means clustering.

```gdscript
func kmeans(points: Array, k: int, max_iter: int = 50) -> Array:
    var centroids: Array = []
    for _i in k:
        centroids.append(points[randi() % points.size()])
    for _iter in max_iter:
        var clusters: Array = []
        for _i in k: clusters.append([])
        for p in points:
            var best: int = 0
            var best_dist: float = INF
            for i in k:
                var d: float = p.distance_to(centroids[i])
                if d < best_dist:
                    best_dist = d; best = i
            clusters[best].append(p)
        var changed: bool = false
        for i in k:
            if clusters[i].is_empty(): continue
            var mean := Vector2.ZERO
            for p in clusters[i]: mean += p
            mean /= clusters[i].size()
            if not mean.is_equal_approx(centroids[i]):
                centroids[i] = mean; changed = true
        if not changed: break
    return centroids
```

Iterate: assign points to nearest centroid, update centroid to cluster mean, repeat. Converges when assignments stabilise.

Linear SVM decision boundary.

```gdscript
class_name SimpleSVM

var weights: Vector2 = Vector2.ZERO
var bias: float = 0.0

func predict(p: Vector2) -> int:
    return 1 if weights.dot(p) + bias > 0 else -1

func train(dataset: LabeledDataset, lr: float = 0.01, epochs: int = 100) -> void:
    for _e in epochs:
        for i in dataset.points.size():
            var p: Vector2 = dataset.points[i]
            var y: int = dataset.labels[i]
            if y * (weights.dot(p) + bias) < 1:
                weights += lr * (y * p - 0.01 * weights)
                bias += lr * y
            else:
                weights -= lr * 0.01 * weights
```

Hinge-loss SGD. Simple but effective for linearly separable data.

Neural classifier forward pass.

```gdscript
class_name SimpleNN

var W1: Array  # input-to-hidden
var b1: Array
var W2: Array  # hidden-to-output
var b2: Array

func forward(x: Vector2) -> float:
    var h1: Array = [
        max(0.0, W1[0][0] * x.x + W1[0][1] * x.y + b1[0]),
        max(0.0, W1[1][0] * x.x + W1[1][1] * x.y + b1[1]),
        max(0.0, W1[2][0] * x.x + W1[2][1] * x.y + b1[2]),
        max(0.0, W1[3][0] * x.x + W1[3][1] * x.y + b1[3]),
    ]
    return 1.0 / (1.0 + exp(-(W2[0] * h1[0] + W2[1] * h1[1] + W2[2] * h1[2] + W2[3] * h1[3] + b2)))
```

Two inputs, four hidden units with ReLU, one sigmoid output. A canonical small network.

Render a decision boundary.

```gdscript
func render_boundary(predict_func: Callable, bounds: Rect2, resolution: int = 100) -> ImageTexture:
    var image := Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
    for py in resolution:
        for px in resolution:
            var p := Vector2(px, py) / resolution * bounds.size + bounds.position
            var label = predict_func.call(p)
            image.set_pixel(px, py, Color.RED if label == 1 else Color.BLUE)
    return ImageTexture.create_from_image(image)
```

Sample the classifier on a grid. Paint each sample according to the predicted label.

Visualise the dataset.

```gdscript
func render_points(dataset: LabeledDataset) -> void:
    for i in dataset.points.size():
        var marker := SphereMesh.new()
        var mi := MeshInstance3D.new()
        mi.mesh = marker
        mi.position = Vector3(dataset.points[i].x, 0.1, dataset.points[i].y)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color.RED if dataset.labels[i] == 1 else Color.BLUE
        mi.material_override = mat
        add_child(mi)
```

Each data point becomes a coloured sphere. The classifier's boundary can be overlaid.

You can now build a labelled dataset, cluster with k-means, train an SVM with hinge-loss SGD, forward-pass a small neural network, and render decision boundaries. ML_Neural_Networks extends into multi-layer architecture.

### ML_Neural_Networks

Source: `commons/maps/ML_Neural_Networks/tutorial.md`

# ML Neural Networks

Layers stacked. Each transforms its input.

Build a feedforward network.

```gdscript
class_name FeedforwardNet

var layers: Array = []  # array of layer dicts with W, b, activation

func add_layer(input_size: int, output_size: int, activation: String) -> void:
    var W: Array = init_he(input_size, output_size)
    var b: Array = []
    for _i in output_size: b.append(0.0)
    layers.append({"W": W, "b": b, "activation": activation})
```

Each layer stores a weight matrix and a bias vector. The activation is a string key.

He initialisation.

```gdscript
func init_he(fan_in: int, fan_out: int) -> Array:
    var std: float = sqrt(2.0 / fan_in)
    var W: Array = []
    for _i in fan_out:
        var row: Array = []
        for _j in fan_in:
            row.append(randfn(0.0, std))
        W.append(row)
    return W
```

Scale inversely with fan_in. Prevents vanishing gradients in deep networks with ReLU.

Matrix-vector product.

```gdscript
func matmul(W: Array, x: Array) -> Array:
    var result: Array = []
    for i in W.size():
        var sum: float = 0.0
        for j in x.size():
            sum += W[i][j] * x[j]
        result.append(sum)
    return result
```

Simple nested loop. For production use, GPU-accelerated libraries.

Activation functions.

```gdscript
func activate(v: Array, name: String) -> Array:
    var r: Array = []
    for x in v:
        match name:
            "relu": r.append(max(0.0, x))
            "sigmoid": r.append(1.0 / (1.0 + exp(-x)))
            "tanh": r.append(tanh(x))
            _: r.append(x)
    return r
```

ReLU, sigmoid, tanh are standard. Each has different gradient characteristics.

Forward pass.

```gdscript
func forward(x: Array) -> Array:
    var h: Array = x
    for layer in layers:
        h = matmul(layer.W, h)
        for i in h.size(): h[i] += layer.b[i]
        h = activate(h, layer.activation)
    return h
```

Chain matrix-vector product and activation through each layer. Final output is the network's prediction.

Compute mean-squared error.

```gdscript
func mse_loss(predictions: Array, targets: Array) -> float:
    var sum: float = 0.0
    for i in predictions.size():
        var err: float = predictions[i] - targets[i]
        sum += err * err
    return sum / predictions.size()
```

Standard regression loss. Lower is better.

Backward pass sketch.

```gdscript
func backward(x: Array, target: Array, lr: float) -> void:
    var activations: Array = [x]
    var h: Array = x
    for layer in layers:
        h = matmul(layer.W, h)
        for i in h.size(): h[i] += layer.b[i]
        h = activate(h, layer.activation)
        activations.append(h)
    var delta: Array = []
    for i in h.size(): delta.append(h[i] - target[i])
    for i in range(layers.size() - 1, -1, -1):
        var prev_h: Array = activations[i]
        for out_idx in delta.size():
            for in_idx in prev_h.size():
                layers[i].W[out_idx][in_idx] -= lr * delta[out_idx] * prev_h[in_idx]
            layers[i].b[out_idx] -= lr * delta[out_idx]
        if i > 0:
            var new_delta: Array = []
            for in_idx in prev_h.size():
                var sum: float = 0.0
                for out_idx in delta.size():
                    sum += delta[out_idx] * layers[i].W[out_idx][in_idx]
                new_delta.append(sum)
            delta = new_delta
```

Chain rule through layers. Simplified — assumes MSE and linear output.

You can now build a feedforward network with He initialisation, compute forward passes through arbitrary layers and activations, measure loss, and run a backward pass for training. ML_Perception extends into the single neuron.

### ML_Perception

Source: `commons/maps/ML_Perception/tutorial.md`

# ML Perception

One neuron. Weighted sum, threshold, output.

Build a perceptron.

```gdscript
class_name Perceptron

var weights: Array = []
var bias: float = 0.0

func initialize(input_size: int) -> void:
    weights.clear()
    for _i in input_size:
        weights.append(randf_range(-0.5, 0.5))
    bias = randf_range(-0.5, 0.5)
```

Random weights in [-0.5, 0.5]. The bias is a constant offset.

Compute the output.

```gdscript
func predict(inputs: Array) -> int:
    var sum: float = bias
    for i in inputs.size():
        sum += weights[i] * inputs[i]
    return 1 if sum > 0 else 0
```

Binary output: positive threshold produces 1, otherwise 0.

Update on a misclassified example.

```gdscript
func train_step(inputs: Array, label: int, lr: float = 0.1) -> void:
    var predicted := predict(inputs)
    var error: int = label - predicted
    if error != 0:
        for i in weights.size():
            weights[i] += lr * error * inputs[i]
        bias += lr * error
```

The perceptron learning rule. Correct classifications don't update; errors nudge the weights.

Run several epochs.

```gdscript
func train(dataset: Array, epochs: int = 50, lr: float = 0.1) -> bool:
    for _e in epochs:
        var errors: int = 0
        for entry in dataset:
            var predicted := predict(entry.inputs)
            if predicted != entry.label:
                train_step(entry.inputs, entry.label, lr)
                errors += 1
        if errors == 0: return true
    return false
```

Converges when all examples are classified correctly. Fails on linearly inseparable data (XOR).

Apply a convolution kernel.

```gdscript
func convolve(image: Array, kernel: Array) -> Array:
    var h := image.size()
    var w := image[0].size()
    var kh := kernel.size()
    var kw := kernel[0].size()
    var out: Array = []
    for y in h - kh + 1:
        out.append([])
        for x in w - kw + 1:
            var sum: float = 0.0
            for dy in kh:
                for dx in kw:
                    sum += image[y + dy][x + dx] * kernel[dy][dx]
            out[y].append(sum)
    return out
```

Slide the kernel across the image. Each output pixel is a weighted sum of a local window.

Edge-detection kernel.

```gdscript
const SOBEL_X := [
    [-1, 0, 1],
    [-2, 0, 2],
    [-1, 0, 1],
]

const SOBEL_Y := [
    [-1, -2, -1],
    [0, 0, 0],
    [1, 2, 1],
]
```

Sobel filters detect horizontal and vertical edges. Combining the two gives edge magnitude.

Compute edge magnitude.

```gdscript
func edge_magnitude(image: Array) -> Array:
    var gx := convolve(image, SOBEL_X)
    var gy := convolve(image, SOBEL_Y)
    var mag: Array = []
    for y in gx.size():
        mag.append([])
        for x in gx[0].size():
            mag[y].append(sqrt(gx[y][x] * gx[y][x] + gy[y][x] * gy[y][x]))
    return mag
```

Pythagorean combination. The result is a single edge-strength image.

You can now build a perceptron with training, convolve an image with a kernel, and detect edges with Sobel filters. ML_Sequence_Memory extends into recurrent networks.

### ML_Sequence_Memory

Source: `commons/maps/ML_Sequence_Memory/tutorial.md`

# ML Sequence Memory

Recurrent network. The hidden state carries the past forward.

Build a simple RNN cell.

```gdscript
class_name RNNCell

var W_xh: Array
var W_hh: Array
var W_hy: Array
var h: Array

func step(x: Array) -> Array:
    var pre_activation: Array = []
    for i in h.size():
        var sum: float = 0.0
        for j in x.size(): sum += W_xh[i][j] * x[j]
        for j in h.size(): sum += W_hh[i][j] * h[j]
        pre_activation.append(sum)
    var h_new: Array = []
    for v in pre_activation: h_new.append(tanh(v))
    h = h_new
    var y: Array = []
    for i in W_hy.size():
        var sum: float = 0.0
        for j in h.size(): sum += W_hy[i][j] * h[j]
        y.append(sum)
    return y
```

Three weight matrices: input-to-hidden, hidden-to-hidden, hidden-to-output. The state h carries forward.

Build an LSTM cell.

```gdscript
class_name LSTMCell

var W_f: Array; var b_f: Array  # forget gate
var W_i: Array; var b_i: Array  # input gate
var W_o: Array; var b_o: Array  # output gate
var W_g: Array; var b_g: Array  # candidate
var h: Array
var c: Array

func step(x: Array) -> Array:
    var combined := concat(x, h)
    var f := sigmoid_vector(add_bias(matmul_vec(W_f, combined), b_f))
    var i := sigmoid_vector(add_bias(matmul_vec(W_i, combined), b_i))
    var o := sigmoid_vector(add_bias(matmul_vec(W_o, combined), b_o))
    var g := tanh_vector(add_bias(matmul_vec(W_g, combined), b_g))
    c = add_element(multiply_element(f, c), multiply_element(i, g))
    h = multiply_element(o, tanh_vector(c))
    return h
```

Three gates control the cell state. Forget drops information; input adds; output reads.

Concatenate vectors.

```gdscript
func concat(a: Array, b: Array) -> Array:
    var result: Array = []
    for x in a: result.append(x)
    for x in b: result.append(x)
    return result
```

Side-by-side. Used wherever two inputs must be combined into one.

Process a sequence.

```gdscript
func process_sequence(sequence: Array) -> Array:
    var outputs: Array = []
    for x in sequence:
        outputs.append(step(x))
    return outputs
```

One step per input. The outputs together form the network's response.

Detect vanishing gradient.

```gdscript
func measure_gradient_over_time(sequence: Array) -> Array:
    var gradients: Array = []
    for t in sequence.size():
        var g: float = gradient_at_timestep(t, sequence)
        gradients.append(g)
    return gradients
```

Trace how much influence each earlier input has on the final output. Decays exponentially in vanilla RNNs; much slower in LSTMs.

Teacher forcing.

```gdscript
func train_with_teacher_forcing(inputs: Array, targets: Array) -> void:
    for t in inputs.size():
        step(inputs[t])
        var target: Array = targets[t]
        # Use target rather than prediction as next input
```

During training, the model always sees the true previous token. Stabilises training; creates an inference-time discrepancy.

You can now build RNN and LSTM cells, process sequences, measure gradient decay, and train with teacher forcing. ML_Generative extends into models that produce new data.

### ML_Generative

Source: `commons/maps/ML_Generative/tutorial.md`

# ML Generative

Generate new data from a learned distribution. GAN, VAE, diffusion.

Build a GAN generator.

```gdscript
class_name Generator extends FeedforwardNet

func generate(noise: Array) -> Array:
    return forward(noise)
```

Takes random noise; produces a sample. The network's weights encode the learned distribution.

Build a GAN discriminator.

```gdscript
class_name Discriminator extends FeedforwardNet

func is_real(sample: Array) -> float:
    var output := forward(sample)
    return output[0]  # scalar probability
```

Outputs the probability the input is real (rather than generated).

Train the GAN.

```gdscript
func train_step(real_batch: Array, generator: Generator, discriminator: Discriminator, lr: float = 0.001) -> void:
    var fake_batch: Array = []
    for _i in real_batch.size():
        var z: Array = sample_noise(32)
        fake_batch.append(generator.generate(z))
    discriminator.backward_real_batch(real_batch, lr)
    discriminator.backward_fake_batch(fake_batch, lr)
    var fake_batch_new: Array = []
    for _i in real_batch.size():
        var z: Array = sample_noise(32)
        fake_batch_new.append(generator.generate(z))
    generator.backward_fool_discriminator(fake_batch_new, discriminator, lr)
```

Alternating training. First the discriminator learns to distinguish; then the generator learns to fool.

Sample noise.

```gdscript
func sample_noise(size: int) -> Array:
    var noise: Array = []
    for _i in size:
        noise.append(randfn(0.0, 1.0))
    return noise
```

Standard Gaussian. Each generator input is an independent noise vector.

Build a VAE encoder.

```gdscript
func vae_encode(x: Array) -> Dictionary:
    var h := encoder_forward(x)
    return {
        "mu": extract_mu(h),
        "log_var": extract_log_var(h),
    }
```

The encoder produces mean and log-variance of a Gaussian. Sampling from this distribution gives the latent code.

Reparameterise for gradient flow.

```gdscript
func reparameterize(mu: Array, log_var: Array) -> Array:
    var z: Array = []
    for i in mu.size():
        var std: float = exp(0.5 * log_var[i])
        var eps: float = randfn(0.0, 1.0)
        z.append(mu[i] + eps * std)
    return z
```

Reparameterisation moves the randomness outside the network. Gradient flows through mu and log_var.

Compute VAE loss.

```gdscript
func vae_loss(x: Array, reconstructed: Array, mu: Array, log_var: Array) -> float:
    var recon_loss: float = 0.0
    for i in x.size():
        recon_loss += (x[i] - reconstructed[i]) ** 2
    var kl_loss: float = 0.0
    for i in mu.size():
        kl_loss += 0.5 * (exp(log_var[i]) + mu[i] * mu[i] - 1.0 - log_var[i])
    return recon_loss + kl_loss
```

Reconstruction plus KL divergence. Balances fidelity against latent-space regularity.

Run a single diffusion step.

```gdscript
func diffusion_forward(x_0: Array, t: float, beta: float = 0.01) -> Array:
    var alpha: float = 1.0 - beta * t
    var noise: Array = sample_noise(x_0.size())
    var x_t: Array = []
    for i in x_0.size():
        x_t.append(sqrt(alpha) * x_0[i] + sqrt(1.0 - alpha) * noise[i])
    return x_t
```

Add progressively more noise. The reverse process is a learned neural network.

You can now build GAN generators and discriminators, train with alternating optimisation, encode and decode with VAEs using reparameterisation, compute VAE loss, and run one diffusion step. ML_Synthesis extends into a multi-paradigm synthesis map.

### ML_Synthesis

Source: `commons/maps/ML_Synthesis/tutorial.md`

# ML Synthesis

Reinforcement learning, generation, classification. Three islands.

Build a Q-table.

```gdscript
class_name QLearner

var q_table: Dictionary = {}  # state -> array of Q values per action

func get_q(state, action: int) -> float:
    return q_table.get(state, Array([0, 0, 0, 0]))[action]

func set_q(state, action: int, value: float) -> void:
    if not state in q_table:
        q_table[state] = [0.0, 0.0, 0.0, 0.0]
    q_table[state][action] = value
```

One row per state, one column per action. Values track expected future reward.

Epsilon-greedy action selection.

```gdscript
@export var epsilon: float = 0.1

func choose_action(state) -> int:
    if randf() < epsilon:
        return randi() % 4
    var q_values: Array = q_table.get(state, [0, 0, 0, 0])
    var best: int = 0
    for i in range(1, 4):
        if q_values[i] > q_values[best]:
            best = i
    return best
```

With probability epsilon explore; otherwise exploit the best known action.

Q-learning update.

```gdscript
@export var alpha: float = 0.1  # learning rate
@export var gamma: float = 0.99  # discount factor

func update(state, action: int, reward: float, next_state) -> void:
    var max_next_q: float = -INF
    for a in 4:
        max_next_q = max(max_next_q, get_q(next_state, a))
    var old_q: float = get_q(state, action)
    var new_q: float = old_q + alpha * (reward + gamma * max_next_q - old_q)
    set_q(state, action, new_q)
```

Temporal-difference update. Blends current reward with discounted future expectations.

Run an episode.

```gdscript
func run_episode(env) -> float:
    var state = env.reset()
    var total_reward: float = 0.0
    while not env.is_done():
        var action := choose_action(state)
        var result: Dictionary = env.step(action)
        update(state, action, result.reward, result.next_state)
        state = result.next_state
        total_reward += result.reward
    return total_reward
```

One episode from start to terminal state. The total reward measures how well the policy performed.

Policy gradient (REINFORCE).

```gdscript
func reinforce_update(trajectory: Array, learning_rate: float = 0.01) -> void:
    var returns: Array = compute_returns(trajectory, gamma)
    for i in trajectory.size():
        var state = trajectory[i].state
        var action: int = trajectory[i].action
        var G: float = returns[i]
        var grad: Array = policy_gradient(state, action)
        update_policy(grad, learning_rate * G)
```

Gradient ascent on expected return. Unlike Q-learning, learns a stochastic policy directly.

Sample from a trained language model.

```gdscript
func sample_from_lm(prompt: String, max_tokens: int, temperature: float = 0.7) -> String:
    var output: String = prompt
    for _i in max_tokens:
        var logits: Array = lm_forward(tokenize(output))
        var scaled: Array = []
        for l in logits: scaled.append(l / temperature)
        var probs: Array = softmax(scaled)
        var token_idx: int = sample_categorical(probs)
        output += detokenize([token_idx])
    return output
```

Autoregressive generation. Temperature controls randomness; higher is more diverse.

Retrain a classifier on new data.

```gdscript
func online_retrain(classifier, new_examples: Array) -> void:
    for _epoch in 5:
        for example in new_examples:
            classifier.backward(example.features, example.label)
```

Fine-tune on incoming data. Useful for classifiers that must adapt to distribution shift.

You can now build a Q-learner with epsilon-greedy and temporal-difference updates, run policy gradient, sample from a language model with temperature, and retrain a classifier online. Chamber_ML closes with an adversarial optimiser.

---

## 22. Graph Theory: What Connections Permit

### GT_Foundations

Source: `commons/maps/GT_Foundations/tutorial.md`

# GT Foundations

A graph is vertices and edges. The Königsberg bridges have no Eulerian walk.

Build a graph.

```gdscript
class_name Graph

var vertices: Array = []
var edges: Array = []  # array of [a, b] pairs

func add_vertex(id) -> void:
    if not id in vertices:
        vertices.append(id)

func add_edge(a, b) -> void:
    add_vertex(a); add_vertex(b)
    edges.append([a, b])
```

Unordered pairs. The graph is undirected.

Count degrees.

```gdscript
func degree(v) -> int:
    var count := 0
    for edge in edges:
        if edge[0] == v or edge[1] == v:
            count += 1
    return count

func degrees() -> Dictionary:
    var d: Dictionary = {}
    for v in vertices:
        d[v] = degree(v)
    return d
```

Degree is the count of edges touching a vertex. Koenigsberg has four vertices of odd degree.

Test Eulerian walk.

```gdscript
func eulerian_walk_possible() -> bool:
    var odd_count := 0
    for v in vertices:
        if degree(v) % 2 == 1:
            odd_count += 1
    return odd_count == 0 or odd_count == 2
```

At most two odd-degree vertices. Zero means a closed tour; two means start and end at the odd vertices.

Build the Königsberg graph.

```gdscript
func build_konigsberg() -> Graph:
    var g := Graph.new()
    for land in ["A", "B", "C", "D"]:
        g.add_vertex(land)
    # Seven bridges
    g.add_edge("A", "B"); g.add_edge("A", "B")  # two bridges
    g.add_edge("A", "C"); g.add_edge("A", "C")  # two bridges
    g.add_edge("A", "D"); g.add_edge("B", "D"); g.add_edge("C", "D")
    return g
```

Four land masses, seven bridges. All four vertices have odd degree; no Eulerian walk exists.

Build an adjacency list.

```gdscript
func adjacency_list() -> Dictionary:
    var adj: Dictionary = {}
    for v in vertices: adj[v] = []
    for edge in edges:
        adj[edge[0]].append(edge[1])
        adj[edge[1]].append(edge[0])
    return adj
```

Faster neighbour lookup than iterating edges. Space is O(V + E).

Spawn graph vertices as spheres.

```gdscript
func render_vertices(positions: Dictionary) -> void:
    for v in vertices:
        var sphere := MeshInstance3D.new()
        sphere.mesh = SphereMesh.new()
        sphere.position = positions[v]
        sphere.set_meta("vertex_id", v)
        add_child(sphere)
```

One sphere per vertex. Metadata ties the visual to the graph vertex.

Spawn edges as cylinders.

```gdscript
func render_edges(positions: Dictionary) -> void:
    for edge in edges:
        var a: Vector3 = positions[edge[0]]
        var b: Vector3 = positions[edge[1]]
        spawn_cylinder_between(a, b)
```

Cylinder stretched between endpoints. Multiple edges on the same pair produce overlapping cylinders.

You can now build a graph, compute degrees, test Euler's walk condition, render vertices and edges, and reproduce the Königsberg problem. GT_Layout extends the graph into a force-directed layout.

### GT_Layout

Source: `commons/maps/GT_Layout/tutorial.md`

# GT Layout

Force-directed layout. Nodes repel; edges pull.

Track vertex positions and velocities.

```gdscript
var positions: Dictionary = {}  # vertex_id -> Vector3
var velocities: Dictionary = {}
```

Two dictionaries keyed on vertex id. Initialised with random positions and zero velocities.

Compute repulsion.

```gdscript
@export var repulsion_k: float = 1.0

func repulsion_force_on(v) -> Vector3:
    var total := Vector3.ZERO
    for other in vertices:
        if other == v: continue
        var direction: Vector3 = positions[v] - positions[other]
        var distance: float = direction.length() + 0.01
        total += direction.normalized() * repulsion_k / (distance * distance)
    return total
```

Inverse-square repulsion. Every pair of vertices pushes apart.

Compute attraction.

```gdscript
@export var spring_k: float = 0.5

func spring_force_on(v) -> Vector3:
    var total := Vector3.ZERO
    for edge in edges:
        if edge[0] == v or edge[1] == v:
            var other = edge[0] if edge[1] == v else edge[1]
            var direction: Vector3 = positions[other] - positions[v]
            total += direction * spring_k
    return total
```

Linear attraction along edges. Connected vertices pull together.

Step the simulation.

```gdscript
@export var damping: float = 0.9

func _physics_process(delta: float) -> void:
    for v in vertices:
        var force: Vector3 = repulsion_force_on(v) + spring_force_on(v)
        velocities[v] += force * delta
        velocities[v] *= damping
        positions[v] += velocities[v] * delta
    update_visual_positions()
```

Each step: compute forces, integrate, damp. The graph settles to equilibrium.

Update visuals.

```gdscript
func update_visual_positions() -> void:
    for child in get_children():
        if child.has_meta("vertex_id"):
            var v = child.get_meta("vertex_id")
            child.global_position = positions[v]
```

Visual meshes follow the computed positions. Update every frame.

Compute layout stress.

```gdscript
func layout_stress() -> float:
    var adj: Dictionary = adjacency_list()
    var total: float = 0.0
    for u in vertices:
        var distances: Dictionary = bfs_distances(u, adj)
        for v in vertices:
            if u == v: continue
            var gd: int = distances[v]
            var sd: float = positions[u].distance_to(positions[v])
            total += (gd - sd) * (gd - sd)
    return total
```

Stress measures mismatch between graph distances and spatial distances. Lower is better.

Seed random positions.

```gdscript
func seed_positions(bounds: Vector3) -> void:
    for v in vertices:
        positions[v] = Vector3(randf(), randf(), randf()) * bounds
        velocities[v] = Vector3.ZERO
```

Random initial positions in a bounded volume. The simulation will settle to a layout.

You can now build a force-directed layout with repulsion and spring attraction, integrate the dynamics, update visuals, and measure layout stress. GT_Pathfinding extends into maze navigation.

Snap positions to a grid.

```gdscript
func snap_positions(cell_size: float = 0.5) -> void:
    for v in vertices:
        positions[v] = (positions[v] / cell_size).round() * cell_size
```

Discretise for cleaner visuals. Useful when the layout looks right but jitters slightly.

### GT_Pathfinding

Source: `commons/maps/GT_Pathfinding/tutorial.md`

# GT Pathfinding

The maze is a graph. Walk it with DFS, BFS, or A*.

Build a grid graph.

```gdscript
func grid_graph(size: Vector2i) -> Graph:
    var g := Graph.new()
    for y in size.y:
        for x in size.x:
            g.add_vertex(Vector2i(x, y))
    for y in size.y:
        for x in size.x - 1:
            g.add_edge(Vector2i(x, y), Vector2i(x + 1, y))
    for y in size.y - 1:
        for x in size.x:
            g.add_edge(Vector2i(x, y), Vector2i(x, y + 1))
    return g
```

Every cell is a vertex; adjacent cells are connected by edges. The base for maze algorithms.

Remove random edges to form walls.

```gdscript
func remove_walls(g: Graph, remove_ratio: float = 0.3) -> void:
    var to_remove: Array = []
    for edge in g.edges:
        if randf() < remove_ratio:
            to_remove.append(edge)
    for edge in to_remove:
        g.edges.erase(edge)
```

Removing edges creates walls. The maze is the resulting sparse graph.

Depth-first search.

```gdscript
func dfs(g: Graph, start, goal) -> Array:
    var stack: Array = [start]
    var came_from: Dictionary = {start: null}
    while not stack.is_empty():
        var current = stack.pop_back()
        if current == goal: break
        for neighbour in g.neighbours(current):
            if not neighbour in came_from:
                came_from[neighbour] = current
                stack.push_back(neighbour)
    return reconstruct_path(came_from, goal)
```

Stack-based. Goes deep; backtracks on dead ends.

Breadth-first search.

```gdscript
func bfs(g: Graph, start, goal) -> Array:
    var queue: Array = [start]
    var came_from: Dictionary = {start: null}
    while not queue.is_empty():
        var current = queue.pop_front()
        if current == goal: break
        for neighbour in g.neighbours(current):
            if not neighbour in came_from:
                came_from[neighbour] = current
                queue.push_back(neighbour)
    return reconstruct_path(came_from, goal)
```

Queue-based. Explores in concentric waves. Finds the shortest path on unweighted graphs.

Reconstruct a path.

```gdscript
func reconstruct_path(came_from: Dictionary, goal) -> Array:
    var path: Array = []
    var current = goal
    while current != null:
        path.push_front(current)
        current = came_from[current]
    return path
```

Walk backward from goal to start via the came_from dictionary. Reverse order.

A* search.

```gdscript
func astar(g: Graph, start, goal, heuristic: Callable) -> Array:
    var open := PriorityQueue.new()
    open.push(start, 0.0)
    var came_from: Dictionary = {start: null}
    var g_score: Dictionary = {start: 0.0}
    while not open.is_empty():
        var current = open.pop()
        if current == goal: break
        for neighbour in g.neighbours(current):
            var tentative: float = g_score[current] + 1.0
            if tentative < g_score.get(neighbour, INF):
                came_from[neighbour] = current
                g_score[neighbour] = tentative
                var f: float = tentative + heuristic.call(neighbour, goal)
                open.push(neighbour, f)
    return reconstruct_path(came_from, goal)
```

Priority queue orders by estimated total cost. The heuristic focuses the search.

Manhattan distance heuristic.

```gdscript
func manhattan(a: Vector2i, b: Vector2i) -> float:
    return abs(a.x - b.x) + abs(a.y - b.y)
```

Sum of axis-aligned distances. Admissible for 4-connected grids.

You can now build a grid graph, carve walls, implement DFS, BFS, A*, reconstruct paths, and use Manhattan distance as a heuristic. GT_Network_Analysis extends into centrality measures.

### GT_Network_Analysis

Source: `commons/maps/GT_Network_Analysis/tutorial.md`

# GT Network Analysis

Which node matters most? Degree, betweenness, eigenvector.

Compute degree centrality.

```gdscript
func degree_centrality(g: Graph) -> Dictionary:
    var c: Dictionary = {}
    for v in g.vertices:
        c[v] = float(g.degree(v)) / (g.vertices.size() - 1)
    return c
```

Normalised by the maximum possible degree. Values in [0, 1].

Compute betweenness via Brandes.

```gdscript
func betweenness_centrality(g: Graph) -> Dictionary:
    var c: Dictionary = {}
    for v in g.vertices: c[v] = 0.0
    for s in g.vertices:
        var dist: Dictionary = {s: 0}
        var sigma: Dictionary = {s: 1}
        var pred: Dictionary = {}
        var queue: Array = [s]
        var stack: Array = []
        while not queue.is_empty():
            var u = queue.pop_front()
            stack.push_back(u)
            for w in g.neighbours(u):
                if not w in dist:
                    dist[w] = dist[u] + 1
                    queue.push_back(w)
                if dist[w] == dist[u] + 1:
                    sigma[w] = sigma.get(w, 0) + sigma[u]
                    pred.get_or_add(w, [])
                    pred[w].append(u)
        var delta: Dictionary = {}
        for v in g.vertices: delta[v] = 0.0
        while not stack.is_empty():
            var w = stack.pop_back()
            for u in pred.get(w, []):
                delta[u] += sigma[u] / float(sigma[w]) * (1 + delta[w])
            if w != s:
                c[w] += delta[w]
    return c
```

Brandes' algorithm computes betweenness in O(V·(V+E)). Counts shortest paths passing through each vertex.

Compute eigenvector centrality via power iteration.

```gdscript
func eigenvector_centrality(g: Graph, iterations: int = 50) -> Dictionary:
    var c: Dictionary = {}
    for v in g.vertices: c[v] = 1.0
    for _i in iterations:
        var next: Dictionary = {}
        for v in g.vertices:
            next[v] = 0.0
            for u in g.neighbours(v):
                next[v] += c[u]
        var norm: float = 0.0
        for v in g.vertices: norm += next[v] * next[v]
        norm = sqrt(norm)
        if norm > 0:
            for v in g.vertices: next[v] /= norm
        c = next
    return c
```

Power iteration on the adjacency matrix. Converges to the dominant eigenvector.

Compute closeness centrality.

```gdscript
func closeness_centrality(g: Graph) -> Dictionary:
    var c: Dictionary = {}
    for v in g.vertices:
        var total: int = 0
        var distances: Dictionary = bfs_distances(v, g.adjacency_list())
        for other in distances:
            total += distances[other]
        c[v] = 1.0 / total if total > 0 else 0.0
    return c
```

Reciprocal of average shortest-path distance. High closeness means short average reach.

Colour vertices by centrality.

```gdscript
func colour_by_centrality(centrality: Dictionary) -> void:
    var max_c: float = centrality.values().max()
    for child in get_children():
        if child.has_meta("vertex_id"):
            var v = child.get_meta("vertex_id")
            var t: float = centrality[v] / max_c if max_c > 0 else 0.0
            var mat: StandardMaterial3D = child.material_override
            mat.albedo_color = Color.BLUE.lerp(Color.RED, t)
```

Blue for low centrality, red for high. Visual ranking of importance.

You can now compute degree, betweenness, eigenvector, and closeness centralities, and colour the graph by any of them. GT_Connectivity extends into directed graphs.

Detect a central node.

```gdscript
func most_central(centrality: Dictionary):
    var best = null
    var best_score: float = -INF
    for v in centrality:
        if centrality[v] > best_score:
            best_score = centrality[v]
            best = v
    return best
```

Return the vertex with highest centrality. Useful as a graph's designated hub.


<!-- study-spine:evidence_network -->

## Return: A relation needs a record

Remove one recorded relation; compare incoming and outgoing counts before moving the layout. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses graph, line, array. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`network`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Study and making notes](/book-review/doc/book/iterations/2026-10-02-relations-sentences-and-witnesses/index.html). The display stays fixed while its data, words or images change. RESET returns the original comparison.

<!-- study-edit:evidence_network -->

### One source change: A relation needs a record

In RECORDS, remove this final entry. Predict whose incoming and outgoing counts fall by one. FILTER to payment, then change LAYOUT: a different position must not create a different count. These are fictional source records, not historical evidence. The curved-line renderer is supplied.

```gdscript
[3,7,"payment","04-16","P04: Office pays Maintenance 1 unit."]
```

Source: `commons/artifacts/spine_studies/evidence_network.gd`. Use the prepared scene to run and compare.

<!-- study-reference:evidence_network -->

### Reference and scope

Lombardi assembled narrative structures from researched relations. Our invented institutional records make provenance inspectable without pretending to reconstruct his historical investigations.

[Whitney Museum: Mark Lombardi](https://whitney.org/artists/7340).

### GT_Connectivity

Source: `commons/maps/GT_Connectivity/tutorial.md`

# GT Connectivity

Directed edges. Strong components. Tarjan's algorithm.

Build a directed graph.

```gdscript
class_name DirectedGraph

var vertices: Array = []
var edges_out: Dictionary = {}  # vertex -> array of out-neighbours

func add_edge(from_v, to_v) -> void:
    if not from_v in vertices: vertices.append(from_v)
    if not to_v in vertices: vertices.append(to_v)
    edges_out.get_or_add(from_v, [])
    edges_out[from_v].append(to_v)
```

Edges have direction. Out-neighbours and in-neighbours are separate.

Compute Tarjan's strongly connected components.

```gdscript
func tarjan_scc(g: DirectedGraph) -> Array:
    var index: int = 0
    var stack: Array = []
    var on_stack: Dictionary = {}
    var indices: Dictionary = {}
    var lowlink: Dictionary = {}
    var sccs: Array = []
    
    var strong_connect = func(v):
        indices[v] = index
        lowlink[v] = index
        index += 1
        stack.push_back(v)
        on_stack[v] = true
        for w in g.edges_out.get(v, []):
            if not w in indices:
                strong_connect.call(w)
                lowlink[v] = min(lowlink[v], lowlink[w])
            elif on_stack.get(w, false):
                lowlink[v] = min(lowlink[v], indices[w])
        if lowlink[v] == indices[v]:
            var component: Array = []
            while true:
                var w = stack.pop_back()
                on_stack[w] = false
                component.append(w)
                if w == v: break
            sccs.append(component)
    
    for v in g.vertices:
        if not v in indices:
            strong_connect.call(v)
    return sccs
```

Single DFS pass with the lowlink invariant. Components emerge when the DFS returns to a root.

Compute the condensation.

```gdscript
func condensation(g: DirectedGraph, sccs: Array) -> DirectedGraph:
    var scc_id: Dictionary = {}
    for i in sccs.size():
        for v in sccs[i]:
            scc_id[v] = i
    var cond := DirectedGraph.new()
    for edge_from in g.edges_out:
        for edge_to in g.edges_out[edge_from]:
            var a: int = scc_id[edge_from]
            var b: int = scc_id[edge_to]
            if a != b:
                cond.add_edge(a, b)
    return cond
```

Each SCC becomes a single vertex. The condensation is always a DAG.

Topological sort via Kahn.

```gdscript
func topological_sort(g: DirectedGraph) -> Array:
    var in_degree: Dictionary = {}
    for v in g.vertices: in_degree[v] = 0
    for u in g.edges_out:
        for v in g.edges_out[u]:
            in_degree[v] = in_degree.get(v, 0) + 1
    var queue: Array = []
    for v in g.vertices:
        if in_degree[v] == 0:
            queue.push_back(v)
    var result: Array = []
    while not queue.is_empty():
        var u = queue.pop_front()
        result.push_back(u)
        for v in g.edges_out.get(u, []):
            in_degree[v] -= 1
            if in_degree[v] == 0:
                queue.push_back(v)
    return result
```

Remove zero-in-degree vertices one at a time. The order is the topological sort.

Spawn component rooms.

```gdscript
func spawn_scc_rooms(sccs: Array) -> void:
    for i in sccs.size():
        var room := COMPONENT_ROOM_SCENE.instantiate()
        room.position = Vector3(i * 5, 0, 0)
        room.populate(sccs[i])
        add_child(room)
```

Each SCC becomes a physical room. The learner walks between rooms via one-way doors.

Highlight one-way edges.

```gdscript
func render_inter_room_edges(cond: DirectedGraph, room_positions: Dictionary) -> void:
    for u in cond.edges_out:
        for v in cond.edges_out[u]:
            var start: Vector3 = room_positions[u]
            var end: Vector3 = room_positions[v]
            spawn_directional_arrow(start, end)
```

Arrows between rooms show the directed edges in the condensation. The DAG structure is physically legible.

You can now build a directed graph, find strongly connected components via Tarjan, compute the condensation, topologically sort the DAG, and render SCCs as rooms connected by one-way arrows. GT_Spanning_Trees extends to optimal connection.

### GT_Spanning_Trees

Source: `commons/maps/GT_Spanning_Trees/tutorial.md`

# GT Spanning Trees

Connect every vertex. Minimise total weight. MST via Kruskal.

Build a weighted graph.

```gdscript
class_name WeightedGraph

var vertices: Array = []
var edges: Array = []  # [a, b, weight]

func add_edge(a, b, weight: float) -> void:
    if not a in vertices: vertices.append(a)
    if not b in vertices: vertices.append(b)
    edges.append([a, b, weight])
```

Each edge carries a weight. The MST minimises the sum of chosen weights.

Union-find data structure.

```gdscript
class_name UnionFind

var parent: Dictionary = {}
var rank: Dictionary = {}

func make_set(x) -> void:
    parent[x] = x
    rank[x] = 0

func find(x):
    if parent[x] != x:
        parent[x] = find(parent[x])  # path compression
    return parent[x]

func union(x, y) -> bool:
    var rx = find(x); var ry = find(y)
    if rx == ry: return false
    if rank[rx] < rank[ry]:
        parent[rx] = ry
    elif rank[rx] > rank[ry]:
        parent[ry] = rx
    else:
        parent[ry] = rx
        rank[rx] += 1
    return true
```

Path compression and union by rank give effectively O(α(n)) per operation.

Kruskal's algorithm.

```gdscript
func kruskal(g: WeightedGraph) -> Array:
    var uf := UnionFind.new()
    for v in g.vertices: uf.make_set(v)
    var sorted_edges = g.edges.duplicate()
    sorted_edges.sort_custom(func(a, b): return a[2] < b[2])
    var tree: Array = []
    for edge in sorted_edges:
        if uf.union(edge[0], edge[1]):
            tree.append(edge)
            if tree.size() == g.vertices.size() - 1: break
    return tree
```

Sort by weight, add if it doesn't form a cycle. Stops when V-1 edges are added.

Prim's algorithm.

```gdscript
func prim(g: WeightedGraph, start) -> Array:
    var tree: Array = []
    var in_tree: Dictionary = {start: true}
    var candidates: Array = []
    for edge in g.edges:
        if edge[0] == start or edge[1] == start:
            candidates.append(edge)
    while tree.size() < g.vertices.size() - 1:
        candidates.sort_custom(func(a, b): return a[2] < b[2])
        var best = candidates.pop_front()
        var other = best[1] if best[0] in in_tree else best[0]
        if other in in_tree: continue
        tree.append(best)
        in_tree[other] = true
        for edge in g.edges:
            if edge[0] == other or edge[1] == other:
                candidates.append(edge)
    return tree
```

Grow from the root. Always add the cheapest edge that connects a new vertex.

Verify the MST.

```gdscript
func verify_mst(tree: Array, g: WeightedGraph) -> bool:
    if tree.size() != g.vertices.size() - 1: return false
    var uf := UnionFind.new()
    for v in g.vertices: uf.make_set(v)
    for edge in tree:
        if not uf.union(edge[0], edge[1]): return false
    return true
```

V-1 edges, no cycles. Valid spanning tree.

Compute total weight.

```gdscript
func total_weight(tree: Array) -> float:
    var total: float = 0.0
    for edge in tree:
        total += edge[2]
    return total
```

Sum of selected edges' weights. Kruskal and Prim produce the same total on a connected weighted graph with unique weights.

Animate the MST construction.

```gdscript
func animate_mst(tree: Array, delay: float = 0.3) -> void:
    for edge in tree:
        highlight_edge(edge)
        await get_tree().create_timer(delay).timeout
```

One edge at a time, with a pause between. The learner watches the tree grow.

You can now build a weighted graph, compute the MST via Kruskal or Prim using union-find, verify the result, and animate the construction. GT_Flow extends into network flow.

### GT_Flow

Source: `commons/maps/GT_Flow/tutorial.md`

# GT Flow

Max flow from source to sink. Edmonds-Karp via BFS.

Build a flow network.

```gdscript
class_name FlowNetwork

var capacity: Dictionary = {}  # [u, v] -> capacity
var flow: Dictionary = {}       # [u, v] -> current flow

func add_edge(u, v, cap: float) -> void:
    capacity[[u, v]] = cap
    flow[[u, v]] = 0.0
    flow[[v, u]] = 0.0  # reverse edge with zero capacity
    if not capacity.has([v, u]):
        capacity[[v, u]] = 0.0
```

Each edge has a capacity. Reverse edges are created automatically for residual flow.

Residual capacity.

```gdscript
func residual(u, v) -> float:
    return capacity.get([u, v], 0.0) - flow.get([u, v], 0.0)
```

How much more can flow along (u, v). Forward flow reduces it; reverse flow increases it.

BFS for augmenting path.

```gdscript
func bfs_augmenting(source, sink) -> Array:
    var came_from: Dictionary = {source: null}
    var queue: Array = [source]
    while not queue.is_empty():
        var u = queue.pop_front()
        if u == sink: break
        for v in all_vertices():
            if v in came_from: continue
            if residual(u, v) > 0:
                came_from[v] = u
                queue.push_back(v)
    if not sink in came_from: return []
    return reconstruct_path(came_from, sink)
```

Standard BFS; edges are considered only if they have residual capacity. Returns the shortest augmenting path.

Push flow along the path.

```gdscript
func push_flow(path: Array) -> float:
    var bottleneck: float = INF
    for i in range(path.size() - 1):
        bottleneck = min(bottleneck, residual(path[i], path[i + 1]))
    for i in range(path.size() - 1):
        flow[[path[i], path[i + 1]]] += bottleneck
        flow[[path[i + 1], path[i]]] -= bottleneck
    return bottleneck
```

Find the path's bottleneck and push that amount. Reverse edges track allowing flow to be undone.

Edmonds-Karp loop.

```gdscript
func max_flow(source, sink) -> float:
    var total: float = 0.0
    while true:
        var path := bfs_augmenting(source, sink)
        if path.is_empty(): break
        total += push_flow(path)
    return total
```

Push flow along augmenting paths until no more exist. The total is the maximum flow.

Find the min cut.

```gdscript
func min_cut(source) -> Array:
    var reachable: Array = [source]
    var visited: Dictionary = {source: true}
    var queue: Array = [source]
    while not queue.is_empty():
        var u = queue.pop_front()
        for v in all_vertices():
            if v in visited: continue
            if residual(u, v) > 0:
                visited[v] = true
                reachable.append(v)
                queue.push_back(v)
    var cut: Array = []
    for u in reachable:
        for v in all_vertices():
            if not v in visited and capacity.get([u, v], 0) > 0:
                cut.append([u, v])
    return cut
```

After max flow, the min cut is the set of saturated edges from reachable to unreachable vertices. Their total capacity equals the max flow.

Animate flow propagation.

```gdscript
func animate_push(path: Array, amount: float) -> void:
    for i in range(path.size() - 1):
        var start: Vector3 = position_of(path[i])
        var end: Vector3 = position_of(path[i + 1])
        spawn_flow_particle(start, end, amount)
```

Particles travel along the augmenting path. Scale reflects the flow amount.

You can now build a flow network, find augmenting paths via BFS, push flow along them, compute the max flow via Edmonds-Karp, extract the min cut, and animate flow propagation. GT_Matching closes the sequence.

### GT_Matching

Source: `commons/maps/GT_Matching/tutorial.md`

# GT Matching

Pair nodes. Each node claimed by at most one edge. Hungarian algorithm for bipartite weighted matching.

Build a bipartite graph.

```gdscript
class_name BipartiteGraph

var left_vertices: Array = []
var right_vertices: Array = []
var edges: Array = []  # [u, v, weight]

func add_edge(u, v, weight: float = 0.0) -> void:
    if not u in left_vertices: left_vertices.append(u)
    if not v in right_vertices: right_vertices.append(v)
    edges.append([u, v, weight])
```

Two disjoint vertex sets. Edges only cross from left to right.

Greedy matching.

```gdscript
func greedy_matching(g: BipartiteGraph) -> Dictionary:
    var matching: Dictionary = {}  # right_vertex -> left_vertex
    var left_used: Dictionary = {}
    for edge in g.edges:
        if not edge[0] in left_used and not edge[1] in matching:
            matching[edge[1]] = edge[0]
            left_used[edge[0]] = true
    return matching
```

Linear scan. Not optimal; demonstrates why the Hungarian approach exists.

Hopcroft-Karp for maximum matching.

```gdscript
func hopcroft_karp(g: BipartiteGraph) -> Dictionary:
    var matching: Dictionary = {}
    while true:
        var levels: Dictionary = bfs_layers(g, matching)
        if levels.is_empty(): break
        var any_augmented: bool = false
        for u in g.left_vertices:
            if not matching.values().has(u):
                if dfs_augment(u, levels, matching, g):
                    any_augmented = true
        if not any_augmented: break
    return matching
```

BFS to find layered structure; DFS to find augmenting paths. Runs in O(E·√V).

Hungarian algorithm for weighted matching.

```gdscript
func hungarian(cost_matrix: Array) -> Array:
    var n: int = cost_matrix.size()
    var u_dual: Array = []
    var v_dual: Array = []
    for _i in n + 1: u_dual.append(0); v_dual.append(0)
    var assignment: Array = []
    for _i in n + 1: assignment.append(-1)
    # Full Hungarian loop omitted for brevity — finds optimal assignment
    return assignment
```

Solves in O(V³). Finds the minimum-cost perfect matching in a bipartite graph.

Blossom contraction.

```gdscript
func contract_blossom(blossom: Array, graph) -> void:
    var super_vertex := "blossom_" + str(randi())
    for v in blossom:
        for e in graph.edges_touching(v):
            var other = e.other(v)
            if not other in blossom:
                graph.add_edge(super_vertex, other)
    for v in blossom:
        graph.remove_vertex(v)
```

Odd cycles contract into super-vertices. After augmenting through the contraction, the super-vertex expands back into the original blossom.

Detect stable marriage.

```gdscript
func gale_shapley(proposers: Array, receivers: Array, prefs: Dictionary) -> Dictionary:
    var engaged: Dictionary = {}  # receiver -> proposer
    var free_proposers: Array = proposers.duplicate()
    var next_proposal: Dictionary = {}
    for p in proposers: next_proposal[p] = 0
    while not free_proposers.is_empty():
        var p = free_proposers.pop_front()
        var r = prefs[p][next_proposal[p]]
        next_proposal[p] += 1
        if not r in engaged:
            engaged[r] = p
        elif prefs[r].find(p) < prefs[r].find(engaged[r]):
            free_proposers.append(engaged[r])
            engaged[r] = p
        else:
            free_proposers.append(p)
    return engaged
```

Proposers propose in preference order; receivers reject less-preferred matches. Produces a stable matching.

You can now build a bipartite graph, compute greedy, Hopcroft-Karp, and Hungarian matchings, contract blossoms in general matching, and run Gale-Shapley for stable marriage. The Graph Theory sequence closes; the curriculum's spine ends with the matching problem.

---

## 23. Foundations Crisis: The Limits of Formalization

### Euclid_Parallel

Source: `commons/maps/Euclid_Parallel/tutorial.md`

# Euclid Parallel

Five postulates. The first four feel inevitable. Build a room that exposes the fifth as a choice.

Declare the five postulates as data.

```gdscript
const POSTULATES := [
    "Any two points can be joined by a straight line.",
    "Any finite line can be extended indefinitely.",
    "Any line segment and radius define a circle.",
    "All right angles are equal.",
    "Through a point not on a line, exactly one parallel can be drawn.",
]
```

Text, not logic. The postulates live as strings in a constant array so the room can render them on five plinths without a parser.

Lay the plinths in a horseshoe.

```gdscript
func place_plinths(parent: Node3D) -> void:
    var count := POSTULATES.size()
    for i in count:
        var angle := PI * (i + 1) / (count + 1)
        var p := preload("res://commons/maps/elements/text_plinth.tscn").instantiate()
        p.position = Vector3(cos(angle) * 4.0, 0.0, -sin(angle) * 4.0)
        p.text = POSTULATES[i]
        parent.add_child(p)
```

The horseshoe lets the learner read the sequence by walking it. Four feel like description; the fifth feels like an extra step.

Mark the fifth plinth.

```gdscript
func emphasize_fifth(plinth: Node3D) -> void:
    var label: Label3D = plinth.get_node("Label3D")
    label.modulate = Color(0.9, 0.7, 0.3)
    plinth.scale = Vector3.ONE * 1.2
```

Gold tint and a slightly larger scale. The fifth is set apart before any argument is made. The architecture performs the claim.

Animate parallel lines that actually stay parallel.

```gdscript
func draw_parallels(mesh: ImmediateMesh) -> void:
    mesh.clear_surfaces()
    mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    for i in 5:
        var y := -2.0 + i * 1.0
        mesh.surface_add_vertex(Vector3(-5, y, 0))
        mesh.surface_add_vertex(Vector3(5, y, 0))
    mesh.surface_end()
```

Five lines, all parallel, all horizontal. The demonstration is quiet. Euclid's claim looks like a property of the world.

Toggle the fifth postulate.

```gdscript
func toggle_fifth() -> void:
    fifth_active = not fifth_active
    if fifth_active:
        parallel_preview.visible = true
    else:
        parallel_preview.visible = false
        chaos_preview.visible = true
```

Turn the fifth off and a second preview appears. Lines that should stay parallel begin to diverge. The postulate was doing work; without it, the picture fractures.

Record the 2300-year history on a scroll.

```gdscript
func populate_history(scroll: Label3D) -> void:
    scroll.text = "300 BCE Euclid\n1733 Saccheri\n1829 Lobachevsky\n1832 Bolyai\n1854 Riemann"
```

Five names across two millennia. Every one tried to prove the fifth from the first four. Every one failed — because it is independent.

Open the door once the learner reads the scroll.

```gdscript
func _on_scroll_read(duration_ms: int) -> void:
    if duration_ms > 2000:
        door.unlock()
```

The door waits until the scroll has been dwelt with. Reading is the action, not clicking.

You have seen geometry as a list of choices. The next map, NonEuclidean Spaces, turns the fifth postulate off and walks what remains.
<<</MAP>>>

### NonEuclidean_Spaces

Source: `commons/maps/NonEuclidean_Spaces/tutorial.md`

# NonEuclidean Spaces

Two alternatives, equally consistent with the first four postulates. Build a curvature slider that moves continuously between hyperbolic, Euclidean, and elliptic space.

Declare the curvature state.

```gdscript
class_name CurvatureField
extends Node3D

@export var curvature: float = 0.0

func set_curvature(k: float) -> void:
    curvature = clamp(k, -1.0, 1.0)
    _update_grid()
```

A single scalar controls everything. Negative is hyperbolic, zero is Euclidean, positive is elliptic. The slider is the curvature.

Build the base grid.

```gdscript
func _update_grid() -> void:
    for i in grid_vertices.size():
        var v := grid_vertices[i]
        grid_vertices[i] = _warp(v, curvature)
    grid_mesh.update_from(grid_vertices)
```

The grid starts flat. Each frame, vertices warp according to the current curvature. The mesh is the same vertex list differently placed.

Warp a vertex.

```gdscript
func _warp(v: Vector3, k: float) -> Vector3:
    var r := v.length()
    var factor: float = 1.0 + k * r * r * 0.02
    return v * factor
```

Parabolic scaling with distance from origin. Close to the slider, the warp is subtle; far away, it bends dramatically.

Draw two parallel geodesics.

```gdscript
func draw_parallels(k: float) -> void:
    var a := _geodesic(Vector3(-2, 0, -5), Vector3.FORWARD, k)
    var b := _geodesic(Vector3(2, 0, -5), Vector3.FORWARD, k)
    parallels_mesh.draw(a, b)
```

Two lines start parallel. At k=-1 they diverge.

At k=0 they stay parallel. At k=+1 they converge and meet.

Integrate a geodesic step by step.

```gdscript
func _geodesic(start: Vector3, direction: Vector3, k: float) -> PackedVector3Array:
    var points := PackedVector3Array()
    var pos := start
    var dir := direction
    for i in 40:
        pos += dir * 0.2
        dir = (_warp(pos + dir * 0.1, k) - _warp(pos, k)).normalized()
        points.append(_warp(pos, k))
    return points
```

Forty steps per geodesic. Direction updates each step by tangent to the warped grid. The line walks the curvature rather than assuming it.

Label the three regimes.

```gdscript
func label_regime(k: float) -> void:
    if k < -0.1: regime_label.text = "hyperbolic"
    elif k > 0.1: regime_label.text = "elliptic"
    else: regime_label.text = "euclidean"
```

Hyperbolic, euclidean, elliptic. The slider passes through all three continuously. No regime is privileged.

Colour the floor by curvature sign.

```gdscript
func tint_floor(k: float) -> void:
    var mat: StandardMaterial3D = floor.material_override
    mat.albedo_color = Color(0.5 - k * 0.3, 0.5, 0.5 + k * 0.3)
```

Cool toward negative, warm toward positive. The learner's steps tell them which geometry they're inside.

You have moved continuously through three geometries. The next map, Russell Paradox, turns from geometry to logic and finds the first genuine contradiction.
<<</MAP>>>

### Russell_Paradox

Source: `commons/maps/Russell_Paradox/tutorial.md`

# Russell Paradox

The set of all sets that don't contain themselves. Build two boxes and the third box that breaks both.

Declare a set container.

```gdscript
class_name SetBox
extends Node3D

@export var members: Array[String] = []

func contains_self() -> bool:
    return members.has(label)
```

A box holds named members. `contains_self` checks whether the box's own label is in its own member list. Recursion as a property.

Populate two example boxes.

```gdscript
func populate() -> void:
    even_box.members = ["2", "4", "6"]
    boxes_box.members = ["box1", "box2", "boxes_box"]
```

The even-number box does not contain itself. The box-of-boxes does. Two clean examples before the paradox.

Build Russell's set.

```gdscript
func collect_non_self_containing(all_sets: Array[SetBox]) -> Array[String]:
    var out: Array[String] = []
    for s in all_sets:
        if not s.contains_self():
            out.append(s.label)
    return out
```

The filter returns all boxes that do not contain themselves. This list is the rule for the third box.

Create the paradox box.

```gdscript
func build_russell_box(all_sets: Array[SetBox]) -> void:
    russell.members = collect_non_self_containing(all_sets)
    russell.label = "russell"
```

Russell's box collects every non-self-containing box. Then ask whether it belongs to itself.

Check membership.

```gdscript
func russell_paradox() -> String:
    var in_self := russell.members.has("russell")
    if in_self:
        return "russell is in russell → russell must NOT contain itself"
    else:
        return "russell is not in russell → russell MUST contain itself"
```

Either answer produces the opposite requirement. The function returns the two halves of the paradox as a sentence.

Render the paradox as a spinning box.

```gdscript
func _process(dt: float) -> void:
    russell_mesh.rotation.y += dt * 0.6
    var t := sin(Time.get_ticks_msec() / 500.0)
    russell_mesh.scale = Vector3.ONE * (1.0 + 0.1 * t)
```

The box pulses because it cannot resolve. Its geometry is a visual restlessness.

Alarm when the learner opens the box.

```gdscript
func _on_russell_opened() -> void:
    alarm_sound.play()
    alarm_light.visible = true
    readout.text = russell_paradox()
```

The alarm is not playful. Naive set theory is broken at the foundation. The readout says so in full.

You have met the first genuine contradiction. The next map, Gödel Incompleteness, encodes logic in numbers and finds the limit even careful systems share.
<<</MAP>>>

Count the members of each box on a readout.

```gdscript
func readout_counts(panel: Label3D) -> void:
    panel.text = "even: %d
boxes: %d
russell: %d" % [
        even_box.members.size(),
        boxes_box.members.size(),
        russell.members.size(),
    ]
```

The counts let the learner compare sizes at a glance. Russell's count shifts whenever a non-self-containing set is added elsewhere in the room.

Disable inference when Russell is opened.

```gdscript
func disable_inference() -> void:
    classical_engine.enabled = false
    inference_lamp.light_energy = 0.0
```

Classical inference halts. The lamp darkens. The room makes the failure of the system visible.

Offer a restart.

```gdscript
func _on_reset_pressed() -> void:
    russell.members.clear()
    alarm_light.visible = false
    classical_engine.enabled = true
```

Reset clears the paradox and re-enables inference. The learner can rebuild from scratch. The sequence continues.

### Godel_Incompleteness

Source: `commons/maps/Godel_Incompleteness/tutorial.md`

# Gödel Incompleteness

Encode statements as numbers. Build a statement that refers to its own unprovability and watch the system refuse to prove or disprove it.

Declare a Gödel encoding.

```gdscript
func godel_encode(statement: String) -> int:
    var primes := [2, 3, 5, 7, 11, 13, 17, 19, 23]
    var code := 1
    for i in statement.length():
        var ord_c: int = statement.unicode_at(i)
        code *= int(pow(primes[i % primes.size()], ord_c % 10))
    return code
```

A toy encoding using primes. Real Gödel numbering is more careful; the principle is the same. Statements become integers, and integers become arguments inside arithmetic.

Decode a code back to a key.

```gdscript
func godel_key(code: int) -> String:
    return "stmt_%d" % (code % 100000)
```

The decoded key is what the system uses to look up a statement. Lookup on integers is the trick that lets the system talk about itself.

Declare the self-referential statement.

```gdscript
const GODEL_STATEMENT := "This statement is not provable in this system."
var godel_code: int = 0

func prepare_godel() -> void:
    godel_code = godel_encode(GODEL_STATEMENT)
```

The statement is stored as text and as a code. The system can hold both representations and reason about the code numerically.

Run the proof search.

```gdscript
func search_proof(code: int, depth: int) -> String:
    var axioms := ["PA1", "PA2", "PA3", "PA4"]
    for step in depth:
        if _derives(axioms, code):
            return "proved"
    return "not found"
```

A finite search. The function returns either a proof or the absence of one within the depth budget. Gödel's theorem says the absence is permanent, not a budget issue.

Detect the impossibility.

```gdscript
func evaluate_godel() -> String:
    var result := search_proof(godel_code, 1000)
    if result == "proved":
        return "contradiction: system proved its own unprovability claim"
    else:
        return "incomplete: a true statement no proof can reach"
```

Either outcome is an incompleteness. The text says so. The formal system is closed; the question is not.

Render the verdict on the plaque.

```gdscript
func show_verdict(label: Label3D) -> void:
    label.text = evaluate_godel()
    label.modulate = Color(0.85, 0.85, 0.6)
```

Cream-yellow on a stone plaque. The verdict is not rewritten on each visit; the result is stable and inescapable.

Dim the lights on the verdict.

```gdscript
func dim_for_verdict() -> void:
    world_environment.environment.ambient_light_energy = 0.35
    spotlight_on_plaque.light_energy = 2.5
```

The ambient drops; a spot focuses on the plaque. The statement is a monument. Incompleteness is what the room is for.

You have encountered the hardest limit on formal systems. The next map, Escher Impossible, translates the limit into architecture the body can walk.
<<</MAP>>>

### Escher_Impossible

Source: `commons/maps/Escher_Impossible/tutorial.md`

# Escher Impossible

Local truth, global impossibility. Build a staircase where every step is correct and the whole cannot exist.

Declare the staircase graph.

```gdscript
class_name StairGraph
extends Node3D

const SIDES := [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]

@export var rise_per_side: float = 1.0
```

Four sides, each rising by the same amount. The graph is a perimeter loop with monotonic height. Locally consistent by construction.

Place the corners.

```gdscript
func build_corners() -> void:
    var height := 0.0
    for i in SIDES.size():
        var corner := MeshInstance3D.new()
        corner.mesh = BoxMesh.new()
        corner.position = Vector3(i * 2, height, 0.0)
        height += rise_per_side
        add_child(corner)
```

Four corners, each raised by rise_per_side above the previous. Every edge feels like a normal staircase.

Connect the last corner back to the first.

```gdscript
func close_loop() -> void:
    var first := corners[0].position
    var last := corners[-1].position
    var line := ImmediateMesh.new()
    line.surface_begin(Mesh.PRIMITIVE_LINES)
    line.surface_add_vertex(last)
    line.surface_add_vertex(first)
    line.surface_end()
    loop_mesh.mesh = line
```

The edge from the last corner back to the first is the impossibility. Height has risen four times; the return edge must descend all four rises in one step or the loop does not close.

Hide the return seam.

```gdscript
func camouflage_seam(segment: MeshInstance3D, cam: Camera3D) -> void:
    var to_cam := (cam.global_position - segment.global_position).normalized()
    segment.visible = abs(to_cam.dot(Vector3.UP)) < 0.2
```

The seam only disappears from one viewing angle. The illusion depends on perspective. Move your head and the trick shows.

Simulate a creature walking the loop.

```gdscript
func step_creature(creature: Node3D, t: float) -> void:
    var idx := int(t) % corners.size()
    var next_idx := (idx + 1) % corners.size()
    creature.position = corners[idx].position.lerp(corners[next_idx].position, fmod(t, 1.0))
```

The creature walks forever. Each step is valid locally. The loop never ends because height climbs every leg.

Label each edge as locally valid.

```gdscript
func label_edge(label: Label3D, from: Vector3, to: Vector3) -> void:
    label.text = "Δh = %+0.2f" % (to.y - from.y)
    label.position = (from + to) * 0.5 + Vector3.UP * 0.5
```

Each edge reports its height change. All four read positive. The contradiction is global only; no edge is lying.

Show the global sum.

```gdscript
func show_global_sum(label: Label3D) -> void:
    var total := 0.0
    for i in corners.size():
        var a := corners[i].position
        var b := corners[(i + 1) % corners.size()].position
        total += b.y - a.y
    label.text = "loop Δh = %+0.2f" % total
```

The sum around the loop must be zero for the staircase to close. The plaque shows it is not. Gödel's result, rendered as a floor plan.

You have walked a local truth with a global impossibility. The next map, Brouwer Intuitionism, responds by restricting logic to what can be built.
<<</MAP>>>

### Brouwer_Intuitionism

Source: `commons/maps/Brouwer_Intuitionism/tutorial.md`

# Brouwer Intuitionism

No existence without construction. Build a room where claims are only valid if the learner assembles them step by step.

Declare an intuitionistic proposition.

```gdscript
class_name Proposition
extends Resource

@export var name: String = ""
@export var constructed: bool = false
@export var steps: Array[String] = []
```

A proposition has a name and a record of construction. It is not true until `constructed` flips. Proof is assembly, not assertion.

Instantiate a construction bench.

```gdscript
func begin_construction(prop: Proposition) -> void:
    prop.constructed = false
    prop.steps.clear()
    bench.display(prop)
```

The bench resets every time a proposition begins. No carryover from a previous proof. Each construction starts cold.

Append a step.

```gdscript
func add_step(prop: Proposition, step: String) -> void:
    prop.steps.append(step)
    bench.display(prop)
```

Each step is a text operation the learner performs. The display updates so the learner sees the proof growing in front of them.

Validate the construction.

```gdscript
func validate(prop: Proposition) -> bool:
    for required in required_steps_for(prop.name):
        if not prop.steps.has(required):
            return false
    prop.constructed = true
    return true
```

Required steps are listed per proposition. Missing any means the proposition stays unconstructed. No proof by absence.

Reject law of excluded middle.

```gdscript
func attempt_lem(prop: Proposition) -> String:
    if prop.constructed:
        return "true"
    return "not yet constructed"
```

Classical logic returns either "true" or "false" for every proposition. Brouwer's room returns "not yet constructed" instead of "false". The third option is the whole point.

Light the proposition when constructed.

```gdscript
func _on_prop_constructed(prop: Proposition) -> void:
    var light: OmniLight3D = lights[prop.name]
    light.light_energy = 2.5
    construction_chime.play()
```

Constructed propositions glow. Unbuilt ones stay dim. The room is a topology of what the learner has actually made.

Offer a palette of building blocks.

```gdscript
func present_blocks(panel: Node3D) -> void:
    for block_name in block_library:
        var block := preload("res://commons/artifacts/foundations/proof_block.tscn").instantiate()
        block.set_name(block_name)
        panel.add_child(block)
```

Blocks are physical. The learner assembles proofs by moving blocks onto the bench. Construction is a bodily act.

Refuse to finalize without all steps.

```gdscript
func _on_finalize_pressed(prop: Proposition) -> void:
    if validate(prop):
        lock_proof(prop)
    else:
        show_missing(prop)
```

Finalization either locks the proof or lists the missing steps. Errors are named, not silent. The rule is that claims require construction.

You have built without proving by contradiction. The next map, Florensky Paraconsistent, accepts contradictions without collapse.
<<</MAP>>>

Count constructed propositions on a tally.

```gdscript
func update_tally(label: Label3D) -> void:
    var built := 0
    for p in propositions:
        if p.constructed: built += 1
    label.text = "%d / %d constructed" % [built, propositions.size()]
```

The tally rises only when propositions are actually built. Claims without construction do not count. The tally is a running honesty check.

### Florensky_Paraconsistent

Source: `commons/maps/Florensky_Paraconsistent/tutorial.md`

# Florensky Paraconsistent

Classical logic collapses from one contradiction. Florensky's supralogic holds both. Build a Schrödinger box where A and not-A coexist.

Declare the dual state.

```gdscript
class_name DualState
extends Resource

@export var value: String = ""
@export var anti_value: String = ""
@export var confidence: Vector2 = Vector2(0.5, 0.5)
```

Two values, two confidences. The resource holds both without preferring one. The observer decides what the reading means, later.

Initialise the Schrödinger box.

```gdscript
func initialise_box() -> void:
    dual.value = "alive"
    dual.anti_value = "dead"
    dual.confidence = Vector2(0.5, 0.5)
```

Equal confidence in both states. The box is properly superposed before any observation. Classical logic would already have panicked.

Render the box as a translucent sphere.

```gdscript
func render_box(mesh: MeshInstance3D) -> void:
    var mat := StandardMaterial3D.new()
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color = Color(0.7, 0.5, 0.9, 0.4)
    mesh.material_override = mat
```

Lavender, translucent. The sphere is readable from every angle. Its colour shifts gently as confidences diverge.

Update confidence with a nudge.

```gdscript
func nudge(toward: String, amount: float) -> void:
    if toward == dual.value:
        dual.confidence.x = clamp(dual.confidence.x + amount, 0.0, 1.0)
        dual.confidence.y = 1.0 - dual.confidence.x
    else:
        dual.confidence.y = clamp(dual.confidence.y + amount, 0.0, 1.0)
        dual.confidence.x = 1.0 - dual.confidence.y
```

A nudge shifts confidence but never zeroes the opposite. Both sides stay in play. The system is tolerant of disagreement.

Run classical inference on the stable parts.

```gdscript
func safe_infer() -> Array[String]:
    var safe: Array[String] = []
    if dual.confidence.x > 0.9: safe.append(dual.value)
    if dual.confidence.y > 0.9: safe.append(dual.anti_value)
    return safe
```

Only near-certain claims pass to classical inference. The box shields the rest of the system from its own superposition.

Detect ex falso prevention.

```gdscript
func prevent_ex_falso(claim: String) -> bool:
    return claim in safe_infer()
```

Any derivation must cite a safe claim. Contradictions exist in the box; they cannot escape as "anything follows."

Render the two confidences on dials.

```gdscript
func update_dials(dual: DualState) -> void:
    alive_dial.value = dual.confidence.x
    dead_dial.value = dual.confidence.y
    sum_label.text = "Σ = %.2f" % (dual.confidence.x + dual.confidence.y)
```

Two dials, one sum. The sum is always 1.0; the distribution is what changes. The box is stable under contradiction.

You have held both A and not-A. The next map, Crisis Synthesis, gathers the four responses into a single architecture.
<<</MAP>>>

### Crisis_Synthesis

Source: `commons/maps/Crisis_Synthesis/tutorial.md`

# Crisis Synthesis

Four wings, one summit, one complete formula. Build the synthesis that turns crisis into capacity.

Declare the wing registry.

```gdscript
class_name WingRegistry
extends Node3D

const WINGS := {
    "russell": "paradox",
    "godel": "incompleteness",
    "brouwer": "construction",
    "florensky": "paraconsistency",
}
```

Four wings, four names, four words. The registry is the map key. Each wing hosts one artifact from the sequence.

Place the wings around the summit.

```gdscript
func place_wings() -> void:
    var angle := 0.0
    for key in WINGS:
        var wing := preload("res://commons/maps/elements/crisis_wing.tscn").instantiate()
        wing.position = Vector3(cos(angle) * 8.0, 0, sin(angle) * 8.0)
        wing.set_meta("key", key)
        add_child(wing)
        angle += TAU / WINGS.size()
```

Eight-metre radius around the summit. Equal spacing. No wing is privileged; each presents a distinct response to the crisis.

Render the summit formula.

```gdscript
func render_summit(label: Label3D) -> void:
    label.text = "QFE = F − λ·E(S) + φ·ΔE(S,t)"
    label.font_size = 80
    label.modulate = Color(1.0, 0.95, 0.8)
```

The complete formula for the first time. Earlier maps showed fragments. The summit holds the whole.

Wire the bifurcation diagram.

```gdscript
func update_bifurcation(diagram: MeshInstance3D, lambda_value: float) -> void:
    var samples: Array = []
    for i in 100:
        var x := float(i) / 100.0
        samples.append(Vector2(x, _logistic_step(lambda_value, x)))
    diagram.mesh = _mesh_from_samples(samples)
```

The bifurcation rides λ. Low λ is stable; moving λ up opens doublings and then chaos. The diagram explains the critical zones visually.

Slide λ and φ.

```gdscript
func _on_lambda_slider_moved(v: float) -> void:
    lambda_value = v
    update_bifurcation(bif_diagram, v)

func _on_phi_slider_moved(v: float) -> void:
    phi_value = lerp(-1.0, 1.0, v)
    update_wings(phi_value)
```

Each slider rewrites the summit's readout. The wings update to show what their response implies under the current parameters.

Open the wings by proximity.

```gdscript
func _on_player_near_wing(wing: Node3D) -> void:
    wing.set_meta("open", true)
    wing.play_open_animation()
```

Proximity is the trigger, not a button. Walking toward Gödel unlocks Gödel. The learner pieces the argument together at their own pace.

Mark completion on all four visits.

```gdscript
func mark_wing_visited(wing: Node3D) -> void:
    visited[wing.get_meta("key")] = true
    if visited.size() == WINGS.size():
        summit_light.light_energy = 4.0
```

All four wings must be visited before the summit lights fully. The formula only reads complete after every response to the crisis has been witnessed.

You have assembled the crisis into capacity. The next map, Chamber Foundations, embodies Gödel as a creature you cannot distinguish from itself.
<<</MAP>>>

Animate the summit light on full completion.

```gdscript
func animate_summit() -> void:
    var t := Time.get_ticks_msec() / 1000.0
    summit_light.light_energy = 3.0 + sin(t * 0.8) * 0.8
    summit_light.light_color = Color(1.0, 0.9, 0.7)
```

A gentle pulse once the four wings are visited. The pulse is slow enough to read as breath.


<!-- study-spine:sentence_authority -->

## Return: Permission at three scales

Change one sentence once; follow the same words across label, strip and wall. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses loop, array, inscription, limit. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`sentence`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Study and making notes](/book-review/doc/book/iterations/2026-10-02-relations-sentences-and-witnesses/index.html). The display stays fixed while its data, words or images change. RESET returns the original comparison.

<!-- study-edit:sentence_authority -->

### One source change: Permission at three scales

Replace this first entry in SENTENCES with your own short sentence. All three displays read the same array entry. Compare WORD / WHOLE and PACE while keeping that entry fixed. The loop and string array are the learner’s tools; font geometry and pointer fabrication are supplied. Keep the sentence short enough to fit and test all displays.

```gdscript
"YOU MAY REMAIN HERE"
```

Source: `commons/artifacts/spine_studies/sentence_authority.gd`. Use the prepared scene to run and compare.

<!-- study-reference:sentence_authority -->

### Reference and scope

Holzer circulated statements in different public formats. The installation uses original Ada sentences; changing their scale or rhythm does not establish their truth and is not an illustration of an incompleteness proof.

[MoMA: Jenny Holzer, Truisms](https://www.moma.org/collection/works/63755).

---

## 24. QFEP Laboratory: The Formula Made Interactive

### QFEP_Introduction

Source: `commons/maps/QFEP_Introduction/tutorial.md`

# QFEP Introduction

The formula arrives as four grabbable spheres on a plinth. Pick them up, read their names, feel the weights.

Declare a term sphere.

```gdscript
class_name TermSphere
extends RigidBody3D

@export var symbol: String = "F"
@export var description: String = ""
@export var base_color: Color = Color.WHITE
```

Each sphere is a RigidBody3D that carries a symbol and a description. The formula is a bag of four such spheres. Physics treats them as objects; the learner treats them as ideas.

Instantiate the four terms.

```gdscript
func build_formula(parent: Node3D) -> void:
    _add_term(parent, "F", "free energy", Color(0.9, 0.7, 0.3))
    _add_term(parent, "E", "entropy", Color(0.3, 0.6, 0.9))
    _add_term(parent, "λ", "order-chaos mix", Color(0.8, 0.4, 0.7))
    _add_term(parent, "φ", "rate sensitivity", Color(0.5, 0.9, 0.5))
```

Warm gold for F. Cool blue for E. Magenta for λ.

Green for φ. The colour key stays stable across every map in the sequence.

Lay the spheres on a plinth.

```gdscript
func _add_term(parent: Node3D, sym: String, desc: String, col: Color) -> void:
    var sphere := preload("res://commons/artifacts/qfep/term_sphere.tscn").instantiate()
    sphere.symbol = sym
    sphere.description = desc
    sphere.base_color = col
    parent.add_child(sphere)
```

The helper loads the prefab and configures it from the scene. Changing term data means changing exports, not rewriting the artifact.

Render the symbol on the sphere.

```gdscript
func render_label(label: Label3D) -> void:
    label.text = symbol
    label.modulate = base_color
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
```

Billboarded labels stay readable at every angle. The sphere is both a body and a sign.

Speak the description when grabbed.

```gdscript
func _on_grabbed(_hand: Node) -> void:
    var panel: Label3D = get_tree().get_first_node_in_group("term_readout")
    panel.text = "%s — %s" % [symbol, description]
```

Grabbing a sphere publishes its meaning to a shared panel. The learner reads by touching. The formula becomes a conversation with the body.

Display the assembled formula.

```gdscript
func show_formula(label: Label3D) -> void:
    label.text = "QFE = F − λ·E(S) + φ·ΔE(S,t)"
    label.font_size = 64
    label.modulate = Color(1.0, 1.0, 0.95)
```

The full line hangs above the plinth. Learners see the whole before the parts. Later maps will isolate each term.

You have met the formula. The next map, F Term, zooms into free energy and the trap of pure order.
<<</MAP>>>

Colour-key the readout panel.

```gdscript
func colorize_panel(panel: Label3D, sym: String) -> void:
    match sym:
        "F": panel.modulate = Color(0.9, 0.7, 0.3)
        "E": panel.modulate = Color(0.3, 0.6, 0.9)
        "λ": panel.modulate = Color(0.8, 0.4, 0.7)
        "φ": panel.modulate = Color(0.5, 0.9, 0.5)
```

The panel tints to match the sphere the learner just grabbed. Name and colour arrive together.

### QFEP_F_Term

Source: `commons/maps/QFEP_F_Term/tutorial.md`

# F Term

F is free energy — the prediction error that every adaptive system tries to minimize. Build a room where minimizing F is both the task and the trap.

Declare the F meter.

```gdscript
class_name FMeter
extends Node3D

@export var prediction: float = 0.0
@export var observation: float = 0.0

func f_value() -> float:
    return abs(prediction - observation)
```

F is the distance between prediction and observation. The meter reads the absolute difference. Other formulations add log terms; this one is the floor model.

Crystallize particles to minimize F.

```gdscript
func settle_toward(target: Vector3) -> void:
    for particle in particles:
        var d := target - particle.position
        particle.linear_velocity += d * settle_strength
```

Particles drift toward a lattice point. The lattice is the prediction; the particle position is the observation. Over time, the cluster becomes a crystal.

Update F from the cluster state.

```gdscript
func update_f() -> void:
    var total := 0.0
    for particle in particles:
        total += particle.position.distance_to(target_for(particle))
    prediction = 0.0
    observation = total / particles.size()
```

Average distance from lattice gives the observation. Prediction is zero — the lattice is the expectation. F falls as the crystal forms.

Show the dark room.

```gdscript
func enter_dark_room() -> void:
    particles.clear()
    environment.ambient_light_energy = 0.0
    status_label.text = "F = 0.000  (nothing moves)"
```

A sealed room with no particles. F is zero.

Nothing surprises the system because nothing happens. Perfect prediction, no life.

Gate progress on F curiosity.

```gdscript
func _on_dark_room_timer_timeout() -> void:
    if time_in_dark > 3.0:
        prompt.text = "F = 0 is also a grave."
        door.unlock()
```

The door only opens after the learner has stood in the zero-F room long enough to feel it. The prompt writes the lesson. F-minimization without entropy is closure.

Solve the snap puzzle to reduce F.

```gdscript
func _on_piece_snapped(piece: Node3D) -> void:
    score += 1
    prediction = float(score) / float(total_pieces)
    observation = 1.0
    meter.update_visual(f_value())
```

Each snapped piece reduces the gap between prediction and observation. The meter visibly drops. The learner's body performs the gradient descent.

Celebrate minimization and warn against it.

```gdscript
func on_puzzle_solved() -> void:
    play_chime()
    warning.text = "Beautiful. Now notice: nothing new can happen here."
```

The chime is the reward; the warning is the lesson. Closed puzzles are local optima. The F room tells the truth about both.

You have built the F side of the dialectic. The next map, E Term, introduces the counterweight: entropy as possibility.
<<</MAP>>>

Throttle the settle strength.

```gdscript
func throttle_settle(meter: float) -> void:
    settle_strength = lerp(0.2, 1.5, clamp(meter, 0.0, 1.0))
```

Faster settle means sharper crystallization. A slower one lets the learner watch F fall gradually toward zero.

Record the descent curve.

```gdscript
func log_f_descent(sample_rate: float) -> void:
    if Time.get_ticks_msec() - last_log < sample_rate: return
    f_history.append(f_value())
    last_log = Time.get_ticks_msec()
```

Every sample stores a data point. The history line shows the gradient. F-minimization becomes a trace on a chart.

### QFEP_E_Term

Source: `commons/maps/QFEP_E_Term/tutorial.md`

# E Term

E(S) is the size of the possibility space. Build a room where freedom is felt as cubes refusing to stay still.

Declare the entropy meter.

```gdscript
class_name EMeter
extends Node3D

@export var sample_count: int = 256
var positions: PackedVector3Array = PackedVector3Array()

func entropy() -> float:
    return _spread(positions)
```

The meter holds recent positions and computes their spread. Spread is the entropy proxy; more spread means more possibility.

Spawn a cloud of random cubes.

```gdscript
func spawn_random() -> void:
    for i in sample_count:
        var cube := preload("res://commons/artifacts/qfep/entropy_cube.tscn").instantiate()
        cube.position = _sample_in_box()
        add_child(cube)
        positions.append(cube.position)
```

Each cube is placed inside the room's volume by rejection sampling. No two cubes share a target. The room begins in high entropy.

Kick every cube randomly per frame.

```gdscript
func _physics_process(_dt: float) -> void:
    for cube in cubes:
        cube.linear_velocity += Vector3(
            randf_range(-1.0, 1.0),
            randf_range(-0.5, 0.5),
            randf_range(-1.0, 1.0)
        )
```

Brownian kicks keep the entropy alive. Nothing settles. The room refuses to predict itself.

Compute spread as a proxy for E(S).

```gdscript
func _spread(pts: PackedVector3Array) -> float:
    if pts.is_empty(): return 0.0
    var mean := Vector3.ZERO
    for p in pts: mean += p
    mean /= pts.size()
    var total := 0.0
    for p in pts: total += mean.distance_squared_to(p)
    return sqrt(total / pts.size())
```

Standard deviation from the centre of mass. Not true Shannon entropy, but proportional in this volume. The meter updates each physics frame.

Render the meter as a glass column.

```gdscript
func update_visual(level: float) -> void:
    var mapped: float = clamp(level / max_spread, 0.0, 1.0)
    column.scale.y = mapped
    column.position.y = mapped * 0.5
```

The column rises and falls with the cloud. Entropy becomes posture in the room.

Offer a freeze button.

```gdscript
func _on_freeze_pressed() -> void:
    for cube in cubes:
        cube.freeze = true
    meter.update_visual(0.01)
```

Freezing the cubes collapses the cloud. The column shrinks. The learner sees that entropy is a rate, not a property.

Offer a release button.

```gdscript
func _on_release_pressed() -> void:
    for cube in cubes:
        cube.freeze = false
```

Released cubes resume Brownian motion. Entropy returns. The two buttons make the dialectic interactive.

You have built the E side of the dialectic. The next map, Lambda Spectrum, combines F and E into a walkable gradient.
<<</MAP>>>

Clamp cubes to the room.

```gdscript
func clamp_to_room(cube: Node3D) -> void:
    cube.position.x = clamp(cube.position.x, -5.0, 5.0)
    cube.position.z = clamp(cube.position.z, -5.0, 5.0)
```

Walls keep the cloud inside the readable volume. Entropy stays bounded by the room's geometry.

### QFEP_Lambda_Spectrum

Source: `commons/maps/QFEP_Lambda_Spectrum/tutorial.md`

# Lambda Spectrum

Your position is the λ value. Walk from crystal at λ=0 to dissolution at λ=1, through the edge of chaos in between.

Declare the lambda reader.

```gdscript
class_name LambdaReader
extends Node3D

@export var track_start: Vector3 = Vector3.ZERO
@export var track_end: Vector3 = Vector3(20.0, 0.0, 0.0)

func lambda_for(player_pos: Vector3) -> float:
    var total := track_start.distance_to(track_end)
    var here := track_start.distance_to(player_pos)
    return clamp(here / total, 0.0, 1.0)
```

A straight track with a start and end. Player position projects onto the track to yield λ. The reader is the only translator between body and number.

Sample the player every frame.

```gdscript
func _process(_dt: float) -> void:
    var l := lambda_for(player.global_position)
    lambda_label.text = "λ = %.2f" % l
    world.apply_lambda(l)
```

The label updates with each step. The world reshapes itself to match.

Shape the world by λ.

```gdscript
func apply_lambda(l: float) -> void:
    crystallizer.strength = 1.0 - l
    chaos_field.strength = l
    edge_field.strength = _edge_weight(l)
```

Three fields scale with λ. Order dominates near zero.

Chaos dominates near one. Edge peaks in the middle.

Compute the edge weight.

```gdscript
func _edge_weight(l: float) -> float:
    return exp(-pow((l - 0.4) / 0.12, 2.0))
```

A Gaussian centred on λ=0.4 with tight sigma. The edge is narrow. Miss by 0.2 and complexity falls off sharply.

Populate the edge with living patterns.

```gdscript
func populate_edge() -> void:
    for i in 18:
        var pattern := preload("res://commons/artifacts/qfep/edge_creature.tscn").instantiate()
        pattern.position = Vector3(track_start.x + 8.0 + randf_range(-2, 2), 0, randf_range(-2, 2))
        add_child(pattern)
```

Eighteen small creatures live only in the middle band. Their meshes breathe. They vanish at either end.

Drain each creature's life by distance from the edge.

```gdscript
func update_creature(creature: Node3D, l: float) -> void:
    var life := _edge_weight(l)
    creature.scale = Vector3.ONE * life
    creature.modulate.a = life
```

Outside the edge band, the creatures shrink and fade. The learner watches complexity retreat as they step toward either end.

Mark the three stations.

```gdscript
func label_stations() -> void:
    crystal_sign.text = "λ = 0\ncrystal"
    edge_sign.text = "λ ≈ 0.4\nthe edge"
    dissolution_sign.text = "λ = 1\ndissolution"
```

Signs name the three regimes. The learner is not reading about them; the learner is standing in them.

You have walked the spectrum. The next map, Phi Term, adds the system's attitude toward movement along it.
<<</MAP>>>

Log the learner's λ trajectory.

```gdscript
func log_trajectory(l: float) -> void:
    var now := Time.get_ticks_msec() / 1000.0
    trajectory.append({"t": now, "lambda": l})
```

Each λ reading is stamped with time. The trajectory reveals where the learner lingered and where they raced through.

### QFEP_Phi_Term

Source: `commons/maps/QFEP_Phi_Term/tutorial.md`

# Phi Term

φ is the attitude toward change. Negative φ resists; positive φ welcomes. Build a room where your φ choice reshapes what the world lets you do.

Declare the phi dial.

```gdscript
class_name PhiDial
extends Node3D

signal phi_changed(value: float)

@export var value: float = 0.0

func set_value(v: float) -> void:
    value = clamp(v, -1.0, 1.0)
    phi_changed.emit(value)
```

One exported value, clamped to [-1, 1]. Negative resists, zero is neutral, positive welcomes. The signal is how the world hears it.

Grab the dial.

```gdscript
func _on_dial_grabbed(offset: float) -> void:
    set_value(value + offset * turn_gain)
    dial_label.text = "φ = %+.2f" % value
```

The learner turns a physical dial. Each degree updates φ. The label shows the sign explicitly because the sign is the lesson.

Apply φ to a morphing object.

```gdscript
func _on_phi_changed(v: float) -> void:
    morph_target.blend_shapes = _shape_for(v)
    morph_target.metallic = 0.3 + 0.5 * clamp(v, 0.0, 1.0)
```

The object becomes smoother and more iridescent as φ rises. Negative φ hardens it. Zero holds a neutral pose.

Let the rate of change matter.

```gdscript
func delta_energy(prev_state: float, state: float, dt: float) -> float:
    return (state - prev_state) / max(dt, 0.0001)
```

ΔE/Δt is the instantaneous rate. φ multiplies this rate. The formula's third term is a response to motion, not to position.

Accumulate the φ·ΔE contribution.

```gdscript
func phi_contribution(v: float, prev: float, state: float, dt: float) -> float:
    return v * delta_energy(prev, state, dt)
```

Positive φ amplifies fast change into reward. Negative φ amplifies it into penalty. The same rate becomes two very different forces depending on sign.

Paint the room's floor by φ sign.

```gdscript
func tint_floor(v: float) -> void:
    var mat: StandardMaterial3D = floor_mesh.material_override
    if v < 0.0:
        mat.albedo_color = Color(0.3, 0.2, 0.2)
    else:
        mat.albedo_color = Color(0.2, 0.3, 0.4)
```

Burgundy floor for preservation; cool blue for becoming. The room changes under the learner's feet with the dial.

Display the political reading.

```gdscript
func update_reading(v: float) -> void:
    if v < -0.2: reading.text = "conservative"
    elif v > 0.2: reading.text = "queer"
    else: reading.text = "neutral"
```

The reading names φ without euphemism. The formula is a politics; the dial lets the learner declare one.

You have built the attitude term. The next map, Edge Of Chaos, zooms into where φ-positive systems find their most productive balance.
<<</MAP>>>

Lock the dial if the learner requests it.

```gdscript
func lock_dial(locked: bool) -> void:
    dial.can_turn = not locked
    dial_lock_label.text = "locked" if locked else ""
```

Locking preserves a chosen φ while the learner explores. The dial stays readable but stops accepting input.

### QFEP_Edge_Of_Chaos

Source: `commons/maps/QFEP_Edge_Of_Chaos/tutorial.md`

# Edge Of Chaos

λ near 0.4, φ positive, both held. Build the narrow band where Turing patterns, Langton's rules, and life itself live.

Declare the edge controller.

```gdscript
class_name EdgeController
extends Node3D

@export var lambda_value: float = 0.4
@export var phi_value: float = 0.6
@export var window: float = 0.12
```

Two live values and a tolerance. The controller holds the target and reports whether the learner is in the window.

Test the window.

```gdscript
func in_edge(l: float, p: float) -> bool:
    return abs(l - lambda_value) < window and p > 0.0
```

Inside the window means close to target λ and positive φ. Outside means nothing bad; only less complex. The edge is a location, not a judgement.

Drive a reaction-diffusion field by λ.

```gdscript
func step_rd(field: Image, l: float) -> void:
    var feed: float = 0.035 + l * 0.025
    var kill: float = 0.06 + l * 0.005
    _apply_rd(field, feed, kill)
```

Feed and kill parameters shift with λ. The Gray-Scott system produces spots, stripes, and dissolution across the swept range. The edge hosts the patterns.

Render the RD field to a floor texture.

```gdscript
func update_floor(field: Image) -> void:
    var tex := ImageTexture.create_from_image(field)
    floor_material.albedo_texture = tex
```

The texture updates live. The learner walks on the pattern. The pattern is λ made visible on the ground.

Spawn Langton ants at the edge.

```gdscript
func spawn_ants_if_edge(l: float, p: float) -> void:
    if not in_edge(l, p): return
    for i in 6:
        var ant := preload("res://commons/artifacts/qfep/langton_ant.tscn").instantiate()
        ant.position = Vector3(randf_range(-4, 4), 0.05, randf_range(-4, 4))
        add_child(ant)
```

Ants appear only when the conditions are met. They leave trails that remember the learner's location history. Rule 110 and Langton's ant both live in this neighbourhood.

Chime on entering the window.

```gdscript
func _on_window_entered() -> void:
    audio.stream = edge_chime
    audio.play()
    window_label.text = "you are at the edge"
```

The chime marks the threshold without spotlighting it. The window is a discovery, not a level.

Fade everything outside the window.

```gdscript
func _on_window_exited() -> void:
    for creature in creatures:
        creature.queue_free()
    rd_enabled = false
```

Leaving the edge clears the patterns. The learner sees complexity as something sustained, not something earned. Step back in and it returns.

You have inhabited the edge. The next map, Sandbox, removes every guardrail and gives the parameters to the learner.
<<</MAP>>>

Count ants visible in the frame.

```gdscript
func count_visible_ants(cam: Camera3D) -> int:
    var count := 0
    for ant in ants:
        if cam.is_position_in_frustum(ant.global_position):
            count += 1
    return count
```

Ant-count rises when the learner stands inside the window. A small readout on the wall updates from this value.

### QFEP_Sandbox

Source: `commons/maps/QFEP_Sandbox/tutorial.md`

# Connect one route

Move a handle before connecting it. Compare the handle value with the reactor's used value. Press CONNECT / CUT and repeat the gesture. Leave the other handle steady.

Cut the route, then move the handle back. The reactor holds its last inputs. Connect again to deliver the present settings. REPEAT restarts its animation while retaining those inputs.

Lambda changes this reactor's colour and particle speed. Phi lightens or darkens its colour. Neither operation measures entropy. The neighbouring particle field keeps moving independently.

The implementation and reset limits are in technical.md. Earlier imagined global controls and score-driven motion are preserved in design-proposals.md.

### QFEP_Synthesis

Source: `commons/maps/QFEP_Synthesis/tutorial.md`

# Follow one response

Choose PAIR B. Compare pressure base with pressure now. Use PULSE / STEADY to hold pressure at its baseline; keep watching the body rather than assuming it was paused.

Keep Phi steady and change Lambda. Compare stiffness and baseline pressure. Then hold Lambda and move Phi across zero: damping and drag change while that pressure baseline remains. Compare one visible region through time.

The three PAIR buttons select examples. They do not reset the body's previous motion. The live plate reports coefficients, not measured entropy or a biological state. The implementation is in technical.md; the earlier imagined noise-deformed specimen is preserved in design-proposals.md.

---

## 25. Post-Crisis: Applied Limits

### CriticalAlgorithms_Algorithmic_Bias_Visualization

Source: `commons/maps/CriticalAlgorithms_Algorithmic_Bias_Visualization/tutorial.md`

# How much space does a distinction need?

Transformation gave us interpolation; arrays gave each word an address. Those operations now distribute room between labels.

<!-- @bias_from_inside -->

Choose two pink labels. Move the COMPRESSION slider partway, compare their separation, then repeat with two grey labels. Hold the slider at one value while moving your own viewpoint.

The slider changes the positions of the labels themselves. Moving your head changes the view of that arrangement. Keep these two transformations separate.

The source makes the operation inspectable:

```gdscript
var pos := _marginalized_positions_default[i].lerp(
    _marginalized_positions_compressed[i], blend
)
var xf := Transform3D.IDENTITY
xf.origin = pos
_marginalized_multimesh.multimesh.set_instance_transform(i, xf)
```

The index i keeps a word attached to its two authored positions. lerp blends those positions; blend chooses how far the word has travelled. The same operation learned in transformation can make a distinction easier or harder to see. The handle changes the represented geometry. Moving your head changes its projection from where you stand.

[Implementation](../../../commons/artifacts/bias_from_inside/bias_from_inside.gd). This is an excerpt from the artifact, not a standalone program.

The two groups and both arrangements were chosen by the maker. This is a spatial argument about compression, not a measurement of a trained language model. Its pink category can itself flatten the people it asks us to distinguish. Name one difference within that category that matters to you. The queer opening is a demand to revise the representation, not a promise that expanding every distance will produce justice.

<!-- @ -->

A representation allocates distinctions. A room allocates opportunities to address one another.

## Next experiment — not yet a visitor control

Compare a named pair at three slider positions from the same viewing distance, then ask whether the labels remain distinguishable from the intended approach. Record the pair and viewpoint before generalising this to other dense displays.

### CriticalAlgorithms_Applied_Ethics

Source: `commons/maps/CriticalAlgorithms_Applied_Ethics/tutorial.md`

# Who becomes easy to address before anyone speaks?

The previous hall moved labels. Here positions, count and scale arrange possible participants.

<!-- @room_shape_demonstrator -->

Select HEAD, then CIRCLE, before choosing PAIR. Count every chair in each model. Compare the head chair with a side chair, then compare two chairs around the round table. Imagine a participant who needs a clear sightline to an interpreter.

The long-table model has a head chair and six smaller side chairs. The circle has six equally scaled chairs. Count, scale and position change between the plans; COLOUR restores the original red/green contrast; the pair is not an experiment that isolates table shape.

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

[Implementation](../../../algorithms/postfoundationscrisis/room_shape_demonstrator.gd). This is an excerpt from the artifact, not a standalone program.

Press COLOUR while keeping PAIR selected. The chairs stay in place, but green now recommends the circle. NEUTRAL removes this colour contrast without changing the arrangement. Before accepting that judgement, consider sightlines, hearing, turning and entry. A shared centre can be useful without meeting every body's needs. Geometry sets conditions for participation; it does not contain the participants' agreements or resolve unequal authority. The next design should let those conditions be compared with people using the space.

<!-- @ -->

A place at the table does not make every account agree. The next hall keeps two accounts visible.

## Next experiment — with participants

Build a comparison with equal chair count, scale and colour, changing only the arrangement. Test sightlines and approach routes before claiming the circle is more accessible. Retain the original coloured pair as a comparison visitors can choose after inspecting each plan.

### SpeculativeComputation_Paraconsistent_Engineering

Source: `commons/maps/SpeculativeComputation_Paraconsistent_Engineering/tutorial.md`

# What disappears when a disagreement is declared resolved?

Different positions can produce different requirements. Preserving the requirements is the first step towards inspecting their conflict.

<!-- @merge_conflict_visualizer -->

Read branch A and branch B and locate the light between them. Give each branch a concrete report about one door, including a time and a source. Decide whether your reports actually contradict each other before proposing a resolution.

JUNCTION keeps two separate upright pillars and a pulsing marker. OVERLAP leans them into a shared volume; FORK leans them apart. MARKER hides or reveals the glow without moving either branch. The sculpture displays relations; it does not run a merge algorithm or derive logical consequences.

The source makes the operation inspectable:

```gdscript
func _build_resolved() -> void:
    _build_pillar(branch_a_color, Vector3(0, 0, 0),
        Vector3(0.2, pillar_height, 0.2), "branch A", 0.0, false)
    _build_pillar(branch_b_color, Vector3(BASE_X, 0, 0),
        Vector3(0.2, RESOLVED_STUMP_H, 0.2), "branch B", 0.0, true)
```

The MERGE panel exposes JUNCTION, OVERLAP, RESOLVED and FORK. In RESOLVED, A keeps its full height and takes the centre; B becomes a labelled stump. Return to OVERLAP to recover both full-height branches. This is an authored picture of a decision, not a proof that the decision was warranted.

[Implementation](../../../algorithms/postfoundationscrisis/merge_conflict_visualizer.gd). This is an excerpt from the artifact, not a standalone program.

Two stored reports need not be a contradiction: they might concern different doors or different times. Preserving sources helps investigate that difference. It does not by itself change the rules of inference. The paraconsistent question is narrower: when both P and not-P are admitted, can unrelated conclusions still be refused? The sculpture makes room for that question but cannot answer it through overlapping meshes. Its unresolved glow should invite investigation rather than make conflict desirable in every case.

<!-- @ -->

To investigate disagreement we need to know where each claim came from.

## Next experiment — not yet a visitor control

Add a small inspectable inference table with a contradictory pair and an unrelated proposition. Require the visitor to predict which consequences follow. Compare that with preserving two source-tagged reports, so storage and inference remain distinct lessons.

### SpeculativeComputation_Situated_Computation

Source: `commons/maps/SpeculativeComputation_Situated_Computation/tutorial.md`

# Which part of a judgement tells you where it came from?

The conflict room asked for sources. Here the source travels visibly with the verdict.

<!-- @situated_readout -->

Read all four panels. Keep SUBJECT #4729 fixed in your comparison and record each verdict, confidence and footer. Return to the first panel and identify which fields changed between panels.

Then keep one panel in view. COVER puts a strip over its address; FOOTNOTE restores the footer; WITNESS adds a symbolic eye and station frame. The verdict and percentage remain unchanged. What has become easier to question, and what evidence is still missing?

Four authored verdicts share one identifier. Your movement changes which panel you read. It does not make a panel recalculate an assessment of you.

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

[Implementation](../../../commons/artifacts/situated_readout/situated_readout.gd). This is an excerpt from the artifact, not a standalone program.

A visible address makes a claim easier to question, but cannot make it correct. ORDERLY and CREATIVE are not logical negations; they could both describe someone under different criteria. DANGEROUS demands an account of danger to whom and in what circumstances. Even an agreeable label needs evidence. The room's productive limit is the gap between displaying a standpoint and exposing the method that produced its judgement.

<!-- @ -->

Keeping viewpoints visible is different from combining their contributions into a common object.

## Next experiment — not yet a visitor control

Give each panel an inspectable criterion and the evidence used. Compare disagreement caused by different criteria with disagreement caused by different observations. First verify that all four small panels can be read without losing their footers.


<!-- study-spine:museum_witnesses -->

## Return: The room arrives late

Change the delay from three seconds to one; retain the camera and compare the recorded times. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses loop, trace, array, situation. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`witness`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Study and making notes](/book-review/doc/book/iterations/2026-10-02-relations-sentences-and-witnesses/index.html). The display stays fixed while its data, words or images change. RESET returns the original comparison.

<!-- study-edit:museum_witnesses -->

### One source change: The room arrives late

Change the initial delay from 3.0 to 1.0 and reload. D stays blank until enough frames exist. Compare A and D using their exposure times; then HOLD E and change VIEWPOINT. The first edit uses the clock and retained state. The supplied SubViewport cameras share the current museum World3D; the bounded image buffer is a close-reading extension, not a prerequisite for the edit.

```gdscript
var delay_seconds := 1.0
```

Source: `commons/artifacts/spine_studies/museum_witnesses.gd`. Use the prepared scene to run and compare.

<!-- study-reference:museum_witnesses -->

### Reference and scope

The ZKM presentation describes five episodes on separate monitors linked by steel tubing. Our five monitors carry museum cameras, not Gilligan’s films. The relation concerns distributed attention, mediation and dependence on a shared system.

[ZKM: Melanie Gilligan, The Common Sense](https://zkm.de/en/artwork/the-common-sense).

<!-- witness-portable-cameras -->

### Take a view

Cameras A and B are the pink grabbable bodies beside the original readouts; C stays fixed. On desktop, right-click to pick up, look to aim, and right-click again to release. The usual XR pickup grip moves and turns the same bodies. They stay in the released pose. RETURN CAMERAS restores the current starting views; release the cameras before using return, VIEWPOINT or RESET. Returning the cameras keeps an explicitly held screen image. RESET also clears the held image.

The camera follows the physical body's transform, with its lens 0.32 metres forward. The delayed and held records retain their exposure pose and source label as well as the image and time. Moving A does not rewrite those earlier frames. This reuses coordinates and transforms; constructing the camera housing and pickup system remains supplied.

### SpeculativeComputation_Collective_Knowledge

Source: `commons/maps/SpeculativeComputation_Collective_Knowledge/tutorial.md`

# Does more activity mean more voices?

When many marks accumulate, what makes the result knowledge rather than a pile?

<!-- @peer_production_tool -->

Follow a packet from one of the rim nodes into the central structure. Watch the new facet appear. During one growth cycle, compare a contribution from a node you have already seen with one from a new source. The number of contributions and the number of contributing sources need not increase together. Press FLOW to hold the arrivals. The work can wait while you look.

The exhibit turns contribution into an arrival event. A packet comes from one of twelve positions and adds a piece to a shared form. At sixty pieces this workbench holds its form until you choose VERSION; FLOW starts the arrivals again. Its visible coherence comes from an assembly rule that knows where to place each arriving facet.

Press COLOUR. The smooth progression from purple to teal gives way to the colours of the sources. Nothing has moved. Some pieces that looked like neighbours now belong to different contributors; distant pieces may share one. Press PIECE to follow a piece back to its numbered rim node. The common form has kept an address for each arrival.

The source makes the counting operation inspectable:

```gdscript
_placed += 1
_edits += 1
# count distinct contributors this version
if peer_idx >= 0 and peer_idx < _seen_peers.size() and not bool(_seen_peers[peer_idx]):
    _seen_peers[peer_idx] = true
    _contributors += 1
```

Every accepted facet increments the addition count. The Boolean array _seen_peers lets the same source count only once within a version. On the next version those flags clear while the totals persist. In the earlier display, a number labelled CONTRIBUTORS could therefore outgrow the twelve source positions. That number is now called PARTICIPATIONS. SOURCES counts distinct nodes in this version; EVER counts distinct nodes across versions. The old discrepancy was useful: it showed how a label could quietly turn repeated attendance into an expanding community.

That is a simulation of accretion, not a live collaborative editor. The peers are generated positions rather than people logged into the museum, and the incoming material is accepted without a dispute over its content. The animation demonstrates one way many sources can feed one object while leaving the harder question of validation open.

Collective knowledge needs more than participation counts. A contribution may repeat an error, correct an earlier claim, supply a missing case or disagree with an accepted account. Those actions can add little to a simple count while changing the usefulness of the shared result dramatically.

The previous room kept four viewpoints separate. Here the common centre can make their differences disappear into a continuous object. Switch COLOUR back to ORDER, then recover a piece with PIECE. Its source remains in the record even when the surface no longer shows it. Does the shape preserve a reason for accepting that contribution, or only the fact that something arrived?

Choose a piece and press DISPUTE. Its frame turns red. Press REVISE and watch that same piece turn and change height. The pile has not gained a piece; the revision count has increased. The source is still named, and the change is attributed to VISITOR. The red frame stays. A change has happened, but who agreed that the dispute was settled?

Here revision is a geometric operation we have supplied. It has no evidence to weigh and no argument to answer. The original and previous poses remain in the record, but there is no complete history you can browse. Keeping a name and a trace makes reconsideration possible; it does not perform the reconsideration for us.

Before pressing VERSION, look once more at the disputed piece. The next form starts empty. Its current source count begins again while additions and participations carry on; EVER does not count an old source as a new one. The device keeps only the previous version in memory. What would have to survive for someone else to understand why you changed that piece?

<!-- @the_commons_table -->

Leave the growing helix for the round table. There is no object at its centre to receive another contribution. A small ring of light surrounds an opening. Through it, the floor is still there.

Take a place at the rim, then walk to another. Each little instrument has its card turned towards a different approach. From where you first stood, some of those cards faced away. There is no position from which every account addresses you at once.

One station holds three labelled trays and another marked OTHER. The small spheres have been assigned by a rule. The counts belong to this batch; OTHER holds the specimens that did not meet the three tests. Its name says almost nothing about what they share with one another.

Beside it, five bars stand in order of height. We know how to make that order:

```gdscript
heights.sort()
```

The instruction acts on a list. The bars give its result a place on the table. From the entrance, the arrangement may have looked settled before you knew what had settled it. The card says which comparison was used. It does not ask whether height was the comparison you needed.

Continue around. Two pointers face different ways inside one bracket. A model camera aims towards the middle. Cords join small points by several routes. Four little blocks recall defaults the engine supplied. These are familiar operations and incomplete instruments, gathered into a common piece of furniture. Sharing the table has not made them agree.

The table has no head. The classification still has an author.

Look back at the helix, where every arrival found a place through one central rule. Here the middle has been left open, but the rules have moved to the rim. Which of them could somebody joining you change? Which would they first have to notice?

Perhaps a commons begins with making room for that question. An empty centre gives us somewhere to look through. It does not, by itself, distribute the power to revise.

<!-- @ -->

The rhizome will make the pattern of connection itself grow. A shared result can have many contributors while its network still develops uneven centres.

### SpeculativeComputation_Rhizome_Network

Source: `commons/maps/SpeculativeComputation_Rhizome_Network/tutorial.md`

# Passages, returns and connections

Start with the cave. Enter its near opening, find a coloured junction and return to it by another passage. Compare a junction you can turn through with the upper route passing above a lower one. Follow the climb to its return. This first comparison requires walking, not an interface.

<!-- @rhizome_cave_demo -->

The cave has an authored graph. Around each link, the field calculation opens a corridor with an interpolated floor. At junctions, the minimum of the signed passage values joins their interiors. Surface extraction supplies the walls and floors; collision determines whether the player can actually take the route. A graph crossing is not necessarily a shared opening, and a wider passage can intersect a neighbour without adding a graph edge.

The current wall cannot be cut by the visitor. Sketching a desired new opening is a further design question. The small model below lets us vary connections while keeping its points fixed; its rule and geometry are independent of the cave.

<!-- @rhizome_grower -->

Watch a new shoot and trace its links. Press GROW to hold the arrivals, then REPLAY to return to the first two points. STEP admits one new point and waits. Compare a crowded region with a sparse one. Predict which nearby points the next shoot could reach, then inspect what appears.

Hold an arrangement and press LINKS. The positions stay while the rule switches between one and three earlier neighbours. Trace a route before and after the switch. Which points remain connected?

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

[Implementation](../../../commons/artifacts/rhizome_grower/rhizome_grower.gd). This is an excerpt from the artifact, not a standalone program.

Select a busy node with NODE and predict the consequence of removing it. CUT hides its incident links and leaves a small grey ghost. Trace the surviving paths, then read COMPONENTS: it counts connected groups, including isolated active points. Restore the node with CUT, switch LINKS and repeat at the same point. Neither comparison moves the points or repairs missing relations.

No named root is a construction rule, not a certificate of equal power. Proximity and arrival time still shape access. DEGREE counts links, not authority. REPLAY can recover the same positions and forty-node growth holds for inspection; there is time to reconsider the arrangement.

<!-- @ -->

The assembly laboratory replaces nearest-neighbour growth with a catalogue and an authored target.

## Further experiment

Compare nearby links with a distant connection, or let the graph alter the region in which points can arrive. These are proposals; the current controls compare link count and temporary removal within a fixed region.

### AdvancedLaboratory_Lab_Equipment_Simulation

Source: `commons/maps/AdvancedLaboratory_Lab_Equipment_Simulation/tutorial.md`

# Where was this body's destination decided?

We carry primitives, arrays, transformations and restoring forces into a catalogue of possible assemblies.

<!-- @MolecularDesigner -->

Walk around the floating inventory and follow the part carrying the amber ring. Keep that instance in view as the body gives way to a chair or another assembly. Its position and visible form can change while the ring remains with it.

The controller reuses part instances, but can replace their mesh, type and colour when assigning a new assembly. The same instance need not keep the same visual identity. Target positions are authored before the parts move.

The source makes the operation inspectable:

```gdscript
var to_target = target_pos - global_position

# Spring force toward target
velocity = (velocity + to_target * dock_spring * delta) * dock_damp
global_position += velocity * delta
```

Here the restoring force returns from the earlier halls. The vector to_target points from a part to its assigned destination. The spring changes velocity and velocity changes position. A moving piece can look as if it has found its place, although another file already supplied the target. dock_damp is applied each frame, which also makes the settling depend on the update rate. The clock remains inside the body we are watching.

[Implementation](../../../algorithms/computationalbiology/molecular_framework/Part.gd). This is an excerpt from the artifact, not a standalone program.

The name MolecularDesigner suggests chemistry, but the current controller arranges catalogue parts and draws declared bonds. It does not establish chemical validity. Its constructive question is still substantial: can a new body be made by changing positions and relations, or does it demand a kind of part the catalogue does not describe? The initial inventory is mutable: an assembly can retype an existing instance or create more instances. Reusing an instance while replacing its visible form offers another question about identity. Neither physical emergence nor freedom is established by a persuasive animation.

<!-- @ -->

A useful catalogue is a choice with consequences. The last hall asks us to keep one consequence available for revision.

## Next experiment — not yet a visitor control

Expose one editable target with a visible link to its source assembly. Compare the same docking motion at two fixed update rates before changing damping. Let a visitor alter one relation and keep the resulting body beside the original.

### PostCrisis_Synthesis

Source: `commons/maps/PostCrisis_Synthesis/tutorial.md`

# Which consequence will you keep in view after the next line arrives?

Every hall made a choice inspectable. Here we turn that practice towards the museum itself.

<!-- @accountability_ledger -->

Read one choice/exclusion pair and keep it in mind after it scrolls away. Choose a room you have walked and name one obstacle, one possible change and one observation that would tell you whether it helped.

The entry count increases while old entries leave the six-line buffer. The examples are prewritten and arrive every six seconds. The display records no visitor decisions and does not save the discussion.

The source makes the operation inspectable:

```gdscript
_entries.push_front(line)
while _entries.size() > visible_lines:
    _entries.pop_back()
_count += 1
```

A line enters at the front; another leaves when the buffer is full. The counter survives that loss. We met a running count near the point at the beginning of the museum. Here counting and remembering separate in four lines of code. The machine can announce progress while the evidence of an earlier problem has already disappeared.

[Implementation](../../../commons/artifacts/accountability_ledger/accountability_ledger.gd). This is an excerpt from the artifact, not a standalone program.

Naming an exclusion does not repair it. Nor should every design limitation be treated as the same kind of harm. Keep the specific body, activity and consequence in view. The next iteration needs a durable record of a change and its outcome, including an outcome we did not expect. Generalisation begins when another hall presents the same relation; it remains a proposal until someone can test that second encounter.

<!-- @ -->

Return to one earlier hall. Remember both an obstacle and a form you wanted to enter. Desire can locate a next experiment as clearly as a fault. The spine has supplied tools for another pass, not a final inventory of possible bodies.

## Next experiment — not yet a visitor control

Make the ledger accept a real museum observation with hall, affected activity, proposed change and later result. Preserve unresolved entries across visits. Begin with the contributor-counter ambiguity or a control whose reach has actually been tested.
