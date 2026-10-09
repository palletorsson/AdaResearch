# Primitives — the complete tutorial

Complete current sequence · 6 October 2026


---

<!-- Hall 01: Point_Zero; source: commons/maps/Point_Zero/tutorial.md -->

# Point Zero — Already running

**Learning elements**

- Initialization
- Per-frame updates
- Function calls

This tutorial follows a path through **Endless Museum**. We learn selected operations from the works we encounter. Alongside it, `final.md` follows their critical and poetic questions. Some artifacts belong to both tracks; others remain part of the wider field we explore.

## A number that keeps changing

In Point Zero, the counter is already running. Its number changes as the engine processes frames. We will make the smallest working version of that operation: create a label, then keep updating its text.

Use the working project from Day Zero. Its camera, light and player remain supplied. For this study, attach `counter.gd` to an empty `Node3D` named `CounterStudy`. Place that node where you can see it in your working scene, with its front facing your view. The script creates its own label; there is no child to prepare or fetch through a scene path. The existing museum console is the reference for this study.

Here is the **whole script**.

<!-- student-code:counter.gd -->
```gdscript
extends Node3D

var label: Label3D

func _ready() -> void:
    label = Label3D.new()
    label.text = "0"
    label.font_size = 96
    label.pixel_size = 0.005
    add_child(label)

func _process(_delta: float) -> void:
    label.text = str(Engine.get_process_frames())
```

`var label: Label3D` declares a reference that both functions can use. It does **not** create the label. `Label3D.new()` creates it; `add_child(label)` puts it beneath this node in the scene so its text can appear. The two size settings make the text large enough to read.

Godot calls `_ready()` when the node and its children are ready. Here it creates the label and gives it an initial text, `"0"`. That setup finishes before this node's first `_process()` call.

Godot then calls `_process()` each process frame. `Engine.get_process_frames()` returns the engine's running total; `str()` converts the number to text; `label.text =` replaces the displayed text. The supplied `_delta` is the frame's time interval in seconds. We do not use it: this example reads frames, not seconds.

Run it. The number advances. Its first visible value need not be zero—the engine was running before this label existed.

## Read it once

What would happen if we read the same total only in `_ready()`?

<!-- student-edit:read-once -->
Move `label.text = str(Engine.get_process_frames())` into `_ready()`, immediately after `add_child(label)`. Delete the now-empty `_process()` function. Keep everything else.
<!-- /student-edit:read-once -->

Run again. The number stays where it began, while the room keeps running. The label now holds one reading. Undo the move and the number follows the engine again.

The instruction is the same. Its place determines when it runs. In Point One, `_ready()` will construct a point's visible body.


[Current counter.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Zero/counter.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)

[Complete experiment: counter_once.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Zero/counter_once.gd)


---

<!-- Hall 02: Point_One; source: commons/maps/Point_One/tutorial.md -->

# Point One — give the point a body

**Learning elements**

- Position values
- Variables and constants
- Object references
- Visible and physical boundaries

In the corridor, one point is absent, one is visible, and one stops your movement. A position, a surface and a physical boundary do different work. We will build a small point with all three.

Point Zero introduced `_ready()`. Here it creates the point. Start a new script, `point.gd`, on an empty `Node3D` named `PointStudy` in your working project. Put this study's origin on the floor where the supplied camera or player can see it. Day Zero supplies the room and view; this script creates every part of the point.

## The complete point

<!-- student-code:point.gd -->
```gdscript
extends Node3D

const RADIUS := 0.14
const CENTRE := Vector3(0, 1.12, 0)

var point: StaticBody3D

func _ready() -> void:
    point = StaticBody3D.new()
    point.position = CENTRE

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    point.add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    point.add_child(boundary)

    add_child(point)
```

Run it. A small sphere appears 1.12 metres above the study's origin. The supplied light shows its surface; its collision shape lets the prepared player meet a solid boundary.

## A value, then an object

`CENTRE` holds three numbers: X, Y and Z. Used as a position, they locate the point relative to `PointStudy`. `RADIUS` measures from the sphere's centre to its surface. In this project, one unit represents one metre.

`const` keeps a named value fixed while the script runs. You can change that value in the code and run again. `:=` lets Godot infer its type: `RADIUS` is a decimal number; `CENTRE` is a `Vector3`.

`var point: StaticBody3D` declares a reference. As with Point Zero's label, declaration does not create the object. `StaticBody3D.new()` creates it, and `point =` keeps the reference. A static body provides a fixed physical body; it still needs a shape to define its boundary.

Change `Vector3(0, 1.12, 0)` to `Vector3(0, 1.7, 0)`. Run again. Both surface and boundary rise because they belong to the point. Restore the original value.

## Two kinds of shape

`SphereMesh` describes the visible surface. `MeshInstance3D` displays it. The assignment `surface.mesh = sphere` connects the two. `sphere.height` is the full height, twice the radius.

`SphereShape3D` describes a physical boundary. `CollisionShape3D` attaches it to the physics body. These objects draw nothing. Both shapes use `RADIUS`, so they agree in size.

`point.add_child(surface)` and `point.add_child(boundary)` put both beneath the point. Their default local positions are zero: they share its centre. Finally, `add_child(point)` attaches this whole small construction beneath `PointStudy`. We keep the reference; no scene path is needed to find it later.

Change `RADIUS` from `0.14` to `0.3`. Predict what grows, then run again. The same value controls both shapes. Restore `0.14`.

## Separate seeing from contact

After `boundary.shape = shape`, add `boundary.disabled = true`. Run again. The sphere remains visible, but its boundary no longer stops the player. Remove that line to restore contact.

After `surface.mesh = sphere`, add `surface.visible = false`. The surface disappears; the boundary remains. Remove that line too. Visibility and collision can be changed separately.

Keep this working `point.gd`. In Coordinates, we will give **this same point** pickup behaviour. Its surface and boundary will travel together.


[Current point.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_One/point.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)


---

<!-- Hall 03: Point_Coordinates; source: commons/maps/Point_Coordinates/tutorial.md -->

# Point Coordinates — carry a position

**Learning elements**

- Pickable
- 3D coordinate system
- Local and world position

Take the black point in the museum's coordinate hall. Its surface and boundary follow your hand. Now give the point you made in Point One that same capacity.

Continue with your existing `PointStudy` and `point.gd`. Keep the radius, centre, mesh and collision shape. Change the body's class and pickup settings, then add a position readout. Day Zero supplies the configured XR hands and Godot XR Tools library. Our script supplies the point they can hold.

## The same point, now pickable

Here is the complete resulting script. The shape construction is unchanged; the new parts are the body's type and settings, the readout, and `_process()`.

<!-- student-code:point.gd -->
```gdscript
extends Node3D

const RADIUS := 0.14
const CENTRE := Vector3(0, 1.12, 0)

var point: XRToolsPickable
var readout: Label3D

func _ready() -> void:
    point = XRToolsPickable.new()
    point.position = CENTRE
    point.freeze = true
    point.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    point.release_mode = XRToolsPickable.ReleaseMode.FROZEN
    point.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    point.collision_layer = 4
    point.collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    point.add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    point.add_child(boundary)

    add_child(point)

    readout = Label3D.new()
    readout.position = Vector3(0, 1.6, 0)
    readout.font_size = 36
    readout.pixel_size = 0.005
    add_child(readout)

func _process(_delta: float) -> void:
    var world_position := point.global_position
    var local_position := to_local(world_position)
    readout.text = "LOCAL " + str(local_position) + "\nWORLD " + str(world_position)
```

Run it in the prepared XR scene. Bring your hand to the point, grip, carry it, then release. Its shape is unchanged. Its relation to the hand has changed.

## What the pickup connection adds

`XRToolsPickable` is a physics body with pickup behaviour from the supplied library. It replaces `StaticBody3D`; the same mesh and collider remain its children. The configured hand selects this body and moves it. Our script does not rebuild hand tracking or the grab driver.

`freeze = true` holds the point in place initially. The kinematic freeze mode allows collision checking as a frozen body moves. `ReleaseMode.FROZEN` makes it stay where you release it. `RangedMethod.NONE` limits this example to a nearby hand.

The two collision settings match the prepared museum: `4` puts the point on layer 3, the grab layer; `196615` enables contact with layers 1, 2, 3, 17 and 18. These numbers are supplied configuration. Set them before `add_child(point)`, because the pickup library records its starting settings when the body enters the scene.

To test permission separately, add `point.enabled = false` just before `add_child(point)`. Run again. The visible point and collider remain, but the hand cannot select it. Remove that line to restore pickup.

## One point, two addresses

The readout uses the `Label3D` construction from Point Zero. It belongs to `PointStudy`, so it stays behind when the point moves. `_process()` reads the point again each frame.

`point.global_position` gives the point's position in the world's coordinate system. `to_local(world_position)` converts that position into the coordinate system of the node running this script: **PointStudy**. The two readings describe the same point from different frames.

The last line converts each vector to text. `+` joins the pieces; `\n` starts a new line. It reports the positions without calculating a distance.

If `PointStudy` has the world's origin and orientation, the readings initially agree. Move `PointStudy` two metres along world X and run again. The point still begins at LOCAL `(0, 1.12, 0)`, but WORLD now includes the study's displacement. Changing the parent changes where the point is without changing its local starting value.

Carry the point sideways, up, then forward. Watch which components change. Release it and move your empty hand: the point and its two readings stay where you left them.

## The drawn frame

The museum's pink, grey and black frame helps you see three directions. Its LOCAL card measures from that coloured frame. Our small study measures from `PointStudy`; the choice is explicit in each case. `point.position` would instead mean position relative to the point's parent.

Carry the museum point beyond an arrow's end. The drawing stops; positions continue. A coordinate system can describe more space than its diagram occupies.

Keep this `point.gd`. Lines will continue with the held point and introduce a second endpoint. Distance belongs there.


[Current point.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Coordinates/point.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)


---

<!-- Hall 04: Point_Lines; source: commons/maps/Point_Lines/tutorial.md -->

# Point Lines — what can two lines do?

**Learning elements**

- Endpoints and a segment
- Displacement and distance
- A class and its instances
- Parallel, cross and X
- Position in depth

Take one end of the line in the black room. The other stays. The span turns and changes length. We will make that relation using the point from Coordinates, then arrange two lines into parallel marks, a plus and an X.

## Keep the point; give it another end

Continue from your working [Coordinates script](http://localhost:3003/book-review/commons/maps/Point_Coordinates/tutorial.md). Its point, surface, collider, pickup settings and local/world readout remain. We will put its familiar construction in a class, make two instances, and draw the relation between them.

Save `point_body.gd`, `line.gd` and `line_skin.gd` together. All three files are printed below; only the drawing helper is supplied. On your existing `PointStudy` node, replace the attached `point.gd` with `line.gd`. Keep `point.gd` as the previous working version. Run this one station; the script creates both endpoints. The prepared museum supplies the room, light and configured XR hands.

Keep `PointStudy` at scale `(1, 1, 1)`. Its position and orientation may change. With this scale, our measured units remain metres.

## Give the familiar point a class — point_body.gd

We have already built a sphere with a matching boundary and made it pickable. Move those instructions into `point_body.gd`. A class gives us a repeatable construction: each call to `PointBody.new()` makes a separate point.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```

`extends XRToolsPickable` keeps the pickup behaviour supplied by XR Tools. Our class adds the sphere, its collider and the settings chosen in Coordinates. Inside this file, `add_child(surface)` attaches the surface to this point; there is no outer `point.` prefix.

`_init()` runs when we call `.new()`. It builds the point before the lesson adds it to the scene. We leave XR Tools' `_ready()` in place. The lesson has its own `_ready()` for placing the points and creating the readout.

Each instance gets its own mesh and collision shape. They begin with the same dimensions, but they are separate objects. The class contains no endpoint relation or trace: those belong to the lesson using it.

## The complete continuation — line.gd

The point construction now lives in `point_body.gd`. This smaller lesson places two instances and reads their relation each frame. The coordinate readout stays here.

<!-- student-code:line.gd -->
```gdscript
extends Node3D

const CENTRE := Vector3(0, 1.12, 0)

const PointBody = preload("point_body.gd")

const LineSkin = preload("line_skin.gd")

var point: XRToolsPickable
var readout: Label3D
var point_b: XRToolsPickable
var line: MeshInstance3D
var distance := 0.0

func _ready() -> void:
    point = PointBody.new()
    point.position = CENTRE
    add_child(point)

    readout = Label3D.new()
    readout.position = Vector3(0, 1.6, 0)
    readout.font_size = 36
    readout.pixel_size = 0.005
    add_child(readout)

    point_b = PointBody.new()
    point_b.position = CENTRE + Vector3(1.0, 0, 0)
    add_child(point_b)

    line = LineSkin.new()
    add_child(line)

func _process(_delta: float) -> void:
    var world_position := point.global_position
    var local_position := to_local(world_position)
    readout.text = "LOCAL " + str(local_position) + "\nWORLD " + str(world_position)

    var a := local_position
    var b := to_local(point_b.global_position)
    var displacement := b - a
    distance = displacement.length()
    line.show_segment(a, displacement, distance)
    readout.text += "\nDISTANCE " + str(distance)
```

Run it. Two equal points begin one metre apart. Carry either one: the pink segment follows, and DISTANCE changes. Release it: the endpoint stays where you left it.

## One class, two instances

`preload("point_body.gd")` loads our script class and gives it the local name `PointBody`. Calling `.new()` twice makes two instances. They share the construction and inherited pickup behaviour; each has its own position, surface and collider. Carry A, then B. Moving one must leave the other where you put it.

`point` is our first endpoint, A. `point_b` is B. The references live outside `_ready()`, so `_process()` can read them too. `preload("line_skin.gd")` loads the drawing helper printed below; `LineSkin.new()` creates its visible segment.

The class holds what makes this a pickable point. The station holds what makes these two points a line. We can later extend point behaviour in one file without moving distance calculations or a position history into it.

Coordinates already produced `local_position` for the first point. Here `a` keeps that value. `to_local(point_b.global_position)` expresses B in the same `PointStudy` frame. Now we can subtract like from like.

`b - a` is the displacement from A to B: initially `(1, 0, 0)`. Its `.length()` returns `1.0`. The displacement holds direction and length; the distance holds length alone. The final `+=` adds a DISTANCE line to the coordinate text written earlier in that frame.

The drawing helper receives A, the displacement and its length. It draws a thin cylinder between the ends. Each frame reads the bodies again; the line remains a relation between their current positions.

Change B's starting offset from `Vector3(1.0, 0, 0)` to `Vector3(0, 1.0, 0)`. Predict the distance, then run. The line stands upright and keeps its length. Restore the original offset.

Try `a - b` instead of `b - a`. The distance stays the same, but the cylinder now points the opposite way from A and misses B. Subtraction has an order. Restore `b - a`.

## The supplied drawing code — line_skin.gd

A mathematical line has no thickness. Our example joins two endpoints into a finite segment; this helper gives that segment a surface. It supplies no collider or pickup behaviour.

Save the following beside `line.gd`. It places the cylinder halfway between the ends and turns its long axis along their displacement. The orientation calculation is supplied for now; basis vectors are not a prerequisite for this lesson. The complete code makes that borrowed part available to inspect and reuse.

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

Before adding another line, change `var displacement := b - a` to `var displacement := a - b`. The distance stays the same, but the segment now extends from A in the opposite direction and misses B. The subtraction drives the drawing, not only its readout. Restore `b - a`.

## What can two lines do?

Look at the parallel planks, the plus and the X in the hall. A second segment gives us something to arrange in relation to the first. Add this block in `_ready()`, immediately after `add_child(line)`:

<!-- student-code:two-lines-plus -->
```gdscript
    point.position = Vector3(-0.6, 1.42, 0)
    point_b.position = Vector3(0.6, 1.42, 0)
    var c := Vector3(0, 0.82, 0)
    var d := Vector3(0, 2.02, 0)
    var other_line := LineSkin.new()
    add_child(other_line)
    other_line.show_segment(c, d - c, (d - c).length())
```

This makes a plus. A and B still belong to held bodies. C and D are position values: we have given them no spheres or pickup bodies. The second segment is drawn once in `_ready()` and stays while you move the first. An endpoint can define a relation without becoming a separate object we can grab.

Change those four assignments to try another arrangement. A means `point.position`; B means `point_b.position`. C and D are the two vector values. All use the same station frame.

| Arrangement | A | B | C | D |
|---|---|---|---|---|
| Parallel | (-0.6, 1.12, 0) | (0.6, 1.12, 0) | (-0.6, 1.62, 0) | (0.6, 1.62, 0) |
| Plus | (-0.6, 1.42, 0) | (0.6, 1.42, 0) | (0, 0.82, 0) | (0, 2.02, 0) |
| X | (-0.6, 0.82, 0) | (0.6, 2.02, 0) | (-0.6, 2.02, 0) | (0.6, 0.82, 0) |

Make an X. Then set the Z component of both C and D to `0.2`. Viewed straight on, the lines can still look crossed. Step sideways: they occupy different depths. No shared vertex has been created where the drawings cross. We still have four endpoints and two relations.

Choose an arrangement of your own. Predict which endpoints need to move, then make it. Can you keep both lengths while changing what the pair suggests?

## What the line keeps

Return to the one-line version. Replace `CENTRE + Vector3(1.0, 0, 0)` with `CENTRE` for B's initial position. Both ends now occupy the same place: displacement and distance are zero. The helper hides spans of `0.0001` units or less; it cannot orient a segment with no direction.

Restore the offset. Carry B around a detour and return it to its starting place. The line returns to the same span. It has kept no journey.

Keep `point_body.gd`, `line.gd` and `line_skin.gd`. Trace will keep more positions, in order, so that a detour can remain.


Class reference: [GDScript classes and constructors](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#class-constructor).

[Current line.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Lines/line.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)

[Complete experiment: line_reversed.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Lines/line_reversed.gd)


---

<!-- Hall 05: Point_Trace; source: commons/maps/Point_Trace/tutorial.md -->

# Point Trace — keep where the point has been

**Learning elements**

- Reusing the point class
- Arrays of positions
- Appending and reading an index
- A distance condition with if
- Neighbour loops with for
- Saving the drawing for the next hall

In Lines, you could carry an endpoint around a detour and return it. The segment returned too; nothing kept the journey. Now let the point leave a trace.

The Trace hall offers pens and a ball whose movement leaves a line. Our small program follows the centre of the same pickable point we have already built. We will keep its positions in an array and reuse the line between each neighbouring pair.

## Continue the point

Start from the working [Lines example](http://localhost:3003/book-review/commons/maps/Point_Lines/tutorial.md). Keep the `PointBody` class from Lines, with its mesh, collider and pickup settings, and keep the coordinate readout. Replace the second endpoint and their live segment with a list of positions and a group of drawn segments.

Save the complete continuation below as `trace.gd` beside the unchanged `point_body.gd` and `line_skin.gd`. Replace `line.gd` on your existing `PointStudy` with `trace.gd`. Keep the previous file. Work inside the existing Endless Museum Trace hall. Its room, light and XR hands remain supplied; this code creates the point, record and drawing. Keep the station's scale at `(1, 1, 1)`.

## The complete trace — trace.gd

<!-- student-code:trace.gd -->
```gdscript
extends Node3D

const CENTRE := Vector3(0, 1.12, 0)
const MIN_SEGMENT_DISTANCE := 0.05

const PointBody = preload("point_body.gd")

const LineSkin = preload("line_skin.gd")
const TraceArchive = preload("trace_archive.gd")

var point: XRToolsPickable
var readout: Label3D
var positions: Array[Vector3] = []
var trail: Node3D

func _ready() -> void:
    point = PointBody.new()
    point.position = CENTRE
    add_child(point)

    readout = Label3D.new()
    readout.position = Vector3(0, 1.6, 0)
    readout.font_size = 36
    readout.pixel_size = 0.005
    add_child(readout)

    trail = Node3D.new()
    add_child(trail)
    positions.append(point.position)
    TraceArchive.keep_on_release(point, trail, positions)

func _process(_delta: float) -> void:
    var world_position := point.global_position
    var local_position := to_local(world_position)
    readout.text = "LOCAL " + str(local_position) + "\nWORLD " + str(world_position)

    var last := positions[positions.size() - 1]
    if (local_position - last).length() >= MIN_SEGMENT_DISTANCE:
        positions.append(local_position)

        for segment in trail.get_children():
            segment.queue_free()

        for i in range(1, positions.size()):
            var a := positions[i - 1]
            var displacement := positions[i] - a
            var segment := LineSkin.new()
            trail.add_child(segment)
            segment.show_segment(a, displacement, displacement.length())

    readout.text += "\nPOINTS " + str(positions.size())

```

Run it. The count begins at one: the point's starting position. Carry the point sideways, turn a corner, then pause. The line remains and the count stops growing. Release it; pick it up again and continue. This record keeps going until the study ends.

`PointBody.new()` makes the familiar point. Its class needs no change for this lesson: the recorder reads its position. The array belongs to this study, so later we can keep the record or change its drawing without changing the point.

## An array keeps an order

`positions` is an `Array[Vector3]`: an ordered list whose entries are position values. `[]` starts it empty. The type inside the brackets says what it may hold. We store a position, not the point node that can keep moving. Declaring `positions` outside the functions lets each frame use the same array.

`positions.append(point.position)` adds the first value in `_ready()`. At that moment the point is a direct child of `PointStudy`, so this is its position in the study's frame. Seeding the list gives the recorder a first position to compare against.

`positions[0]` reads the first entry. `positions[1]` reads the second, once it exists. Code counts indices from zero. With four positions, the valid indices are 0, 1, 2 and 3.

`positions.size()` returns the number of entries. Subtract one to get the last valid index: `positions[positions.size() - 1]`. That is the last position we kept. Moving the point afterwards does not move an earlier value in the array.

This is a one-dimensional list of three-dimensional positions: one index chooses an entry; that entry holds X, Y and Z.

## If it has moved far enough

The line lesson gave us the length of a displacement. Here `(local_position - last).length()` measures from the last **retained** position to the point's current one.

`>=` means greater than or equal to. The `if` asks whether that distance has reached `MIN_SEGMENT_DISTANCE`: `0.05` metres, or five centimetres. When the answer is true, Godot runs the indented block: append the position and redraw the trace. When it is false, that block is skipped. The coordinate readout still updates each frame.

The indentation belongs to the code. The POINTS readout sits outside the `if`; it runs whether or not we add an entry.

Move by a little, then a little more. The smaller movements can accumulate because we keep comparing with the last accepted position, not the previous frame. Holding still adds no duplicate positions merely because time passes.

The threshold is a minimum movement for acceptance, not a promise of equally spaced points. Move a long way between two frames and the next segment can be longer than five centimetres. The program joins the positions it kept; it does not recover every bend between them.

## A loop joins the neighbours

`for i in range(1, positions.size())` visits the indices from 1 up to, but not including, the size. With four entries, `i` becomes 1, then 2, then 3. Each visit runs the indented instructions again with that index.

`positions[i - 1]` is the preceding position. `positions[i]` is the next. The loop therefore draws 0–1, 1–2 and 2–3: three segments for four retained positions. Starting at 1 keeps the previous index valid. With only the seeded entry, the range is empty and no segment is drawn.

Inside that loop, the construction from Lines returns: find the displacement, create a `LineSkin`, and give it the start, displacement and length. We can join many positions without creating a pickup body for every one.

The shorter loop above it visits the old segment nodes in `trail.get_children()`. `queue_free()` schedules their removal at the end of the frame. Then we draw the retained list afresh. This keeps the teaching example small and makes the neighbour loop visible; it is intended for short drawings. Clearing these drawings does not erase `positions`.

`_process()` repeats over frames. The `for` loop visits entries within one update. These are different kinds of repetition.

## Change the record

Change `MIN_SEGMENT_DISTANCE` from `0.05` to `0.20`. Draw a small bend, then enlarge it. More movement is needed to add another entry; fewer corners may survive. Restore `0.05`.

For a loop experiment, change `range(1, positions.size())` to `range(1, positions.size() - 1)`. Draw again. The array and count still grow, but the last neighbouring pair is not drawn. You changed the display's traversal, not the record. Restore the original range.

Now make your own short shape and return towards its beginning. Predict the next retained entry before moving. A return can add an earlier location again at a later index: the list keeps order, not just distinct places.

## The carried point — point_body.gd

Keep this file unchanged from Lines. It is repeated here so the complete example is visible; it creates the same body and inherits the same pickup behaviour.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```

## The drawing helper — line_skin.gd

Keep the same helper from Lines. It draws a visible cylinder for a supplied start, displacement and length; it neither records movement nor adds collision. Its complete code is repeated here so these three files are sufficient within the prepared project. The orientation calculation remains supplied.

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

## Keep the record for what comes next

Our positions belong to `PointStudy`'s local frame. Moving or turning the station carries the drawing with it. We record the point's centre whenever it moves far enough; this small recorder follows the point itself, with no separate pen-tip model.

Release the held point when you have a drawing to keep. The supplied `TraceArchive` saves the retained positions **and the segments already made from them**. Grid will place this saved drawing as a sculpture. You will not draw it again or make another sphere there.

`TraceArchive.keep_on_release(point, trail, positions)` supplies the release connection and waits for the current redraw before packing the snapshot. An intentional release keeps the drawing; removing the study or closing its scene does not replace the saved work. The transport uses local positions in metres; the museum hall's world offset is not baked into the gesture. The archive has no timestamps. A later valid release replaces your saved drawing. Releasing before two positions exist leaves the previous file alone.

## Supplied transport — trace_archive.gd

Keep this file beside the lesson scripts. It packs a snapshot of the existing segment nodes and stores the position array as metadata. The source trace remains live and unchanged. `user://ada_student_trace.scn` belongs to this Godot project's user-data directory, so Trace and Grid must run in the same project. Serialization is supplied here; arrays, sampling and traversal remain this lesson's focus.

<!-- student-code:trace_archive.gd -->
```gdscript
# Supplied transport between museum halls. The lesson owns the drawing.
extends RefCounted

const PATH := "user://ada_student_trace.scn"

static func keep_on_release(point: Node3D, trail: Node3D, positions: Array[Vector3]) -> void:
    # Supplied lifecycle boundary: removing a scene is not a request to save.
    point.dropped.connect(func(_body):
        if point.get_meta("ada_release_cleanup", false):
            return
        if not is_instance_valid(trail) or not trail.is_inside_tree():
            return
        await trail.get_tree().process_frame
        if not is_instance_valid(point) or not is_instance_valid(trail):
            return
        if not point.is_inside_tree() or not trail.is_inside_tree():
            return
        if point.is_queued_for_deletion() or trail.is_queued_for_deletion():
            return
        if positions.size() >= 2:
            var error := save_drawing(trail, positions)
            if error != OK:
                push_error("Could not keep the trace: " + error_string(error))
    )

static func save_drawing(trail: Node3D, positions: Array[Vector3]) -> Error:
    if positions.size() < 2:
        return ERR_INVALID_DATA
    var saved := Node3D.new()
    saved.name = "SavedTrace"
    saved.set_meta("positions", PackedVector3Array(positions))
    saved.set_meta("frame", "PointStudy local metres")
    saved.set_meta("version", 1)
    for child in trail.get_children():
        if child.is_queued_for_deletion():
            continue
        var segment := MeshInstance3D.new()
        segment.transform = child.transform
        segment.visible = child.visible
        segment.mesh = child.mesh.duplicate()
        segment.mesh.resource_local_to_scene = true
        segment.material_override = child.material_override.duplicate()
        segment.material_override.resource_local_to_scene = true
        saved.add_child(segment)
        segment.owner = saved
    var scene := PackedScene.new()
    var error := scene.pack(saved)
    if error == OK:
        error = ResourceSaver.save(scene, PATH)
    saved.free()
    return error

static func load_drawing() -> Node3D:
    if not FileAccess.file_exists(PATH):
        return null
    var scene := ResourceLoader.load(PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if scene == null:
        return null
    var drawing := scene.instantiate() as Node3D
    if drawing == null:
        return null
    if drawing.get_meta("version", 0) != 1 or drawing.get_meta("frame", "") != "PointStudy local metres":
        drawing.free()
        return null
    var record = drawing.get_meta("positions", null)
    if not record is PackedVector3Array or record.size() < 2 or drawing.get_child_count() != record.size() - 1:
        drawing.free()
        return null
    return drawing
```

Carry that saved drawing into Grid. Its position data can be read again; its existing visible form can be placed in another hall.


[Current trace.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Trace/trace.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)


---

<!-- Hall 06: Point_Line_Grid; source: commons/maps/Point_Line_Grid/tutorial.md -->

# Point Grid — place the drawing you made

**Learning elements**

- Loading your saved trace
- Reusing a drawing as a sculpture
- One record, different representations
- Source positions and grid addresses
- Integer coordinates and rounding
- Changing a copy while keeping the original

We are in the Endless Museum. In Trace, you moved the held point and released it to save the drawing. Here, place that drawing beside the ruled field. The gesture has become something you can walk around.

The pink sculpture is your saved work: the same retained positions and the same segment geometry. We do not build another point or ask for another gesture. **One record can support different representations.** Here we derive grid addresses from it and change a separate green copy.

Trace stored selected samples of movement, not the whole continuous gesture. Its ordered array, visible segments and rounded addresses each let us do different work. Keeping the source means another interpretation can begin without pretending that rounding recovered everything the hand did.

## Bring your drawing

Continue in the **same working copy of the museum**. Keep `trace.gd` for returning to Trace. Save `grid.gd` beside `trace_archive.gd` and the unchanged `line_skin.gd`, then attach it to your unit-scale `PointStudy` on the clear floor beside Grid's glass field. The museum provides the hall, light and player.

Release the point in Trace before leaving. The supplied archive stores a snapshot under `user://ada_student_trace.scn`; opening Grid loads that snapshot. Without a saved drawing, the readout asks you to return to Trace. It does not invent a replacement. Grid never writes this file.

The first copy stays pink. The two copies stand 1.6 metres apart so you can compare them; these display offsets do not change the saved positions or the grid calculation. A second copy receives its own mesh and material resources before any changes. We reuse the segment renderer from Lines to place those copied segments between rounded positions. The original sculpture keeps the hand's recorded form.

## The complete Grid program — grid.gd

<!-- student-code:grid.gd -->
```gdscript
extends Node3D

const TraceArchive = preload("trace_archive.gd")
const LineSkin = preload("line_skin.gd")

var sculpture: Node3D
var grid_copy: Node3D
var positions := PackedVector3Array()
var addresses: Array[Vector3i] = []
var grid_step := 0.25
var readout: Label3D

func _ready() -> void:
    readout = Label3D.new()
    readout.position = Vector3(0, 2.0, 0)
    readout.font_size = 36
    readout.pixel_size = 0.003
    add_child(readout)

    sculpture = TraceArchive.load_drawing()
    if sculpture == null:
        readout.text = "Draw in Trace, then release the point to save."
        return
    add_child(sculpture)
    positions = sculpture.get_meta("positions").duplicate()

    grid_copy = sculpture.duplicate() as Node3D
    add_child(grid_copy)
    sculpture.position.x = -0.8
    grid_copy.position.x = 0.8
    for i in grid_copy.get_child_count():
        var segment := grid_copy.get_child(i)
        var original := sculpture.get_child(i)
        segment.set_script(LineSkin)
        segment.mesh = original.mesh.duplicate()
        segment.material_override = original.material_override.duplicate()
        segment.material_override.albedo_color = Color(0.25, 0.85, 0.60)
    _place_on_grid()

func _place_on_grid() -> void:
    addresses.clear()
    for p in positions:
        addresses.append(Vector3i(
            roundi(p.x / grid_step),
            roundi(p.y / grid_step),
            roundi(p.z / grid_step)
        ))
    for i in range(1, addresses.size()):
        var a := Vector3(addresses[i - 1]) * grid_step
        var b := Vector3(addresses[i]) * grid_step
        var displacement := b - a
        grid_copy.get_child(i - 1).show_segment(a, displacement, displacement.length())
    readout.text = "YOUR SAVED TRACE\nPOINTS " + str(positions.size())
    readout.text += "\nGRID " + str(grid_step) + " m"
```

`load_drawing()` returns the saved sculpture, including its recorded positions. `add_child(sculpture)` places it under this study. The positions are local to the study and measured in metres; the hall supplies the study's location. Moving the study moves the sculpture as a whole without rewriting the gesture.

`duplicate()` makes a second node tree. The saved sculpture is static. We attach the familiar `LineSkin` script only to the copy we want to change, then give each copied segment its own saved mesh and material. Otherwise changing a segment's length or colour could change the pink original. This is the same ownership question we met with two PointBody instances. The archive saves shapes and transforms, so loading the pink sculpture does not rerun its construction script.

## An entry is not an address

`positions[2]` means the third sample in the recorded order. A `Vector3i` address instead counts grid intervals from this study's origin. At a spacing of 0.25 metres, X = 0.10 rounds to address 0; X = 0.15 rounds to 1. X = -0.15 rounds to -1. At exact halfway values, `roundi()` rounds away from zero.

Multiplying the address by the spacing returns a position in metres. The loop visits neighbouring addresses and calls the renderer we already used in Trace. Two entries can receive the same address; they stay in the record, while their zero-length connecting segment becomes invisible. All three coordinates are rounded, including height.

The saved original remains untouched. We change only the green copy's existing segments. Their connections can be diagonal; this is not a route restricted to grid edges.

## Change a rule, keep your work

Change `grid_step` from `0.25` to `0.50` and run the study again. Both versions load the same saved sculpture; you do not repeat the gesture. Walk around it and compare the two forms. Restore `0.25` afterwards.

Before switching, choose a corner and predict its new address. Find two visits that acquire the same address. Switch back: the finer interpretation returns because the original data was kept, not because coarse rounding can be reversed.

For one experiment, replace `roundi(p.y / grid_step)` with `0`. Run Grid again. Pink keeps the recorded height; green is placed on the study's Y = 0 plane. Restore the expression. This is a one-line edit to the complete program above.

## Carried renderer — line_skin.gd

The saved segments use this same file from Lines and Trace. Its full code is here for completeness; Grid introduces no new recipe for a sphere, cylinder or face.

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

## Supplied archive — trace_archive.gd

This is the same transport used by Trace. Grid calls its loading function; it does not call `save_drawing()`. Keep the file and renderer paths stable in your working project while using the saved scene.

<!-- student-code:trace_archive.gd -->
```gdscript
# Supplied transport between museum halls. The lesson owns the drawing.
extends RefCounted

const PATH := "user://ada_student_trace.scn"

static func keep_on_release(point: Node3D, trail: Node3D, positions: Array[Vector3]) -> void:
    # Supplied lifecycle boundary: removing a scene is not a request to save.
    point.dropped.connect(func(_body):
        if point.get_meta("ada_release_cleanup", false):
            return
        if not is_instance_valid(trail) or not trail.is_inside_tree():
            return
        await trail.get_tree().process_frame
        if not is_instance_valid(point) or not is_instance_valid(trail):
            return
        if not point.is_inside_tree() or not trail.is_inside_tree():
            return
        if point.is_queued_for_deletion() or trail.is_queued_for_deletion():
            return
        if positions.size() >= 2:
            var error := save_drawing(trail, positions)
            if error != OK:
                push_error("Could not keep the trace: " + error_string(error))
    )

static func save_drawing(trail: Node3D, positions: Array[Vector3]) -> Error:
    if positions.size() < 2:
        return ERR_INVALID_DATA
    var saved := Node3D.new()
    saved.name = "SavedTrace"
    saved.set_meta("positions", PackedVector3Array(positions))
    saved.set_meta("frame", "PointStudy local metres")
    saved.set_meta("version", 1)
    for child in trail.get_children():
        if child.is_queued_for_deletion():
            continue
        var segment := MeshInstance3D.new()
        segment.transform = child.transform
        segment.visible = child.visible
        segment.mesh = child.mesh.duplicate()
        segment.mesh.resource_local_to_scene = true
        segment.material_override = child.material_override.duplicate()
        segment.material_override.resource_local_to_scene = true
        saved.add_child(segment)
        segment.owner = saved
    var scene := PackedScene.new()
    var error := scene.pack(saved)
    if error == OK:
        error = ResourceSaver.save(scene, PATH)
    saved.free()
    return error

static func load_drawing() -> Node3D:
    if not FileAccess.file_exists(PATH):
        return null
    var scene := ResourceLoader.load(PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if scene == null:
        return null
    var drawing := scene.instantiate() as Node3D
    if drawing == null:
        return null
    if drawing.get_meta("version", 0) != 1 or drawing.get_meta("frame", "") != "PointStudy local metres":
        drawing.free()
        return null
    var record = drawing.get_meta("positions", null)
    if not record is PackedVector3Array or record.size() < 2 or drawing.get_child_count() != record.size() - 1:
        drawing.free()
        return null
    return drawing
```

One drawing can now be a record, a sculpture and material for another calculation. Keep its original positions. Triangle can select three corners from them and ask what closes the boundary and gives it a face.


[Current grid.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Line_Grid/grid.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)

[Complete experiment: grid_flat_y.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Line_Grid/grid_flat_y.gd)


---

<!-- Hall 07: Point_Triangle_Context; source: commons/maps/Point_Triangle_Context/tutorial.md -->

# Three positions become a face

## Learning elements

- Three selected array entries
- A closed boundary and a face
- Clockwise vertex order
- A guard for a collapsed triangle

## In the museum

Your drawing has reached Grid as a sculpture. Here, choose three positions from its original record. The triangle tools in this hall show the difference between connecting corners and giving the space between them a surface. We will make that difference with the point and line classes already used.

The saved record still uses the drawing station's local metres. Grid's rounded copy did not replace it. This lesson reads the original archive and creates three temporary PointBody handles at selected entries. It does not save their later edits back to the drawing.

Lines already connected two positions. The new step is to store a connection as a recipe that refers to entries in a position list. Three Vector3 values alone do not instruct Godot to draw a face. We choose which entries belong together and in which order; the same stored position can later belong to several faces.

## Make this study

Start with CORNERS = Vector3i(0, 1, 2). These are **entry numbers**, not spatial coordinates. If those entries lie on one straight segment of your drawing, lift one handle to make a face, or choose another triple in the record. A trace with fewer than three entries needs another visit to Trace.

Attach lesson.gd to an empty Node3D named TriangleStudy in your working copy of this museum hall. Keep its scale at one; its translation places the study without changing the saved local measurements. The existing museum supplies the player, camera, light and XR pickup functions. This program constructs its own handles, edges, face and label.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const FaceBody = preload("face_body.gd")
const Archive = preload("trace_archive.gd")
const CORNERS := Vector3i(0, 1, 2)
var handles: Array[Node3D] = []
var points: Array[Vector3] = []
var face := FaceBody.new()
var message := Label3D.new()

func _ready() -> void:
    add_child(face)
    add_child(message)
    message.position = Vector3(0, 2, 0)
    message.font_size = 32
    message.pixel_size = 0.003
    var drawing := Archive.load_drawing()
    if drawing == null:
        message.text = "Return to Trace; draw and release the point."
        return
    var record: PackedVector3Array = drawing.get_meta("positions")
    drawing.free()
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        if index < 0 or index >= record.size():
            message.text = "Choose three indices inside the saved record."
            return
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        var point := PointBody.new()
        point.position = record[index]
        add_child(point)
        handles.append(point)

func _process(_delta: float) -> void:
    if handles.size() != 3:
        return
    var current: Array[Vector3] = []
    for point in handles:
        current.append(point.position)
    if current == points:
        return
    points = current
    if face.show_faces(points, [Vector3i(0, 1, 2)]):
        message.text = "Three positions; one face."
    else:
        message.text = "Separate the corners; lift one off the line."
```

### Dependency: face_body.gd

<!-- student-code:face_body.gd -->
```gdscript
extends Node3D
## Visible triangular faces and their edges. This class adds no collision.
const LineSkin = preload("line_skin.gd")
var surface := MeshInstance3D.new()
var edges := Node3D.new()

func _init() -> void:
    add_child(surface)
    add_child(edges)
    var paper := StandardMaterial3D.new()
    paper.albedo_color = Color(0.92, 0.91, 0.87)
    paper.roughness = 0.75
    surface.material_override = paper

func show_faces(points: Array[Vector3], faces: Array[Vector3i]) -> bool:
    surface.mesh = null
    for edge in edges.get_children():
        edge.free()
    if faces.is_empty():
        return false
    for face in faces:
        for index in [face.x, face.y, face.z]:
            if index < 0 or index >= points.size():
                return false
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        if (c - a).cross(b - a).length() < 0.00001:
            return false
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in faces:
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        # Godot's front faces use clockwise winding.
        var normal := (c - a).cross(b - a).normalized()
        for point in [a, b, c]:
            builder.set_normal(normal)
            builder.add_vertex(point)
        for pair in [[a, b], [b, c], [c, a]]:
            var edge := LineSkin.new()
            edge.material_override.albedo_color = Color(0.04, 0.04, 0.045)
            edges.add_child(edge)
            var difference: Vector3 = pair[1] - pair[0]
            edge.show_segment(pair[0], difference, difference.length())
    surface.mesh = builder.commit()
    return true
```

### Dependency: line_skin.gd

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

### Dependency: point_body.gd

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```

### Dependency: trace_archive.gd

<!-- student-code:trace_archive.gd -->
```gdscript
# Supplied transport between museum halls. The lesson owns the drawing.
extends RefCounted

const PATH := "user://ada_student_trace.scn"

static func keep_on_release(point: Node3D, trail: Node3D, positions: Array[Vector3]) -> void:
    # Supplied lifecycle boundary: removing a scene is not a request to save.
    point.dropped.connect(func(_body):
        if point.get_meta("ada_release_cleanup", false):
            return
        if not is_instance_valid(trail) or not trail.is_inside_tree():
            return
        await trail.get_tree().process_frame
        if not is_instance_valid(point) or not is_instance_valid(trail):
            return
        if not point.is_inside_tree() or not trail.is_inside_tree():
            return
        if point.is_queued_for_deletion() or trail.is_queued_for_deletion():
            return
        if positions.size() >= 2:
            var error := save_drawing(trail, positions)
            if error != OK:
                push_error("Could not keep the trace: " + error_string(error))
    )

static func save_drawing(trail: Node3D, positions: Array[Vector3]) -> Error:
    if positions.size() < 2:
        return ERR_INVALID_DATA
    var saved := Node3D.new()
    saved.name = "SavedTrace"
    saved.set_meta("positions", PackedVector3Array(positions))
    saved.set_meta("frame", "PointStudy local metres")
    saved.set_meta("version", 1)
    for child in trail.get_children():
        if child.is_queued_for_deletion():
            continue
        var segment := MeshInstance3D.new()
        segment.transform = child.transform
        segment.visible = child.visible
        segment.mesh = child.mesh.duplicate()
        segment.mesh.resource_local_to_scene = true
        segment.material_override = child.material_override.duplicate()
        segment.material_override.resource_local_to_scene = true
        saved.add_child(segment)
        segment.owner = saved
    var scene := PackedScene.new()
    var error := scene.pack(saved)
    if error == OK:
        error = ResourceSaver.save(scene, PATH)
    saved.free()
    return error

static func load_drawing() -> Node3D:
    if not FileAccess.file_exists(PATH):
        return null
    var scene := ResourceLoader.load(PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if scene == null:
        return null
    var drawing := scene.instantiate() as Node3D
    if drawing == null:
        return null
    if drawing.get_meta("version", 0) != 1 or drawing.get_meta("frame", "") != "PointStudy local metres":
        drawing.free()
        return null
    var record = drawing.get_meta("positions", null)
    if not record is PackedVector3Array or record.size() < 2 or drawing.get_child_count() != record.size() - 1:
        drawing.free()
        return null
    return drawing
```

## Read the construction

`record[index]` reads one saved position. `PointBody.new()` gives it the same visible, pickable body you already know. The three handles can move independently; their current local positions form a short array.

`Vector3i(0, 1, 2)` tells FaceBody which three entries to visit, in order. Its renderer adds three edges and a triangular surface. The points specify **where**; the triple specifies **how they connect**. This is a face recipe, not another set of positions.

Order matters. Godot treats clockwise vertices, viewed from the front, as a front face. Walk around the triangle: this example keeps normal back-face culling. Reversing the triple to `Vector3i(0, 2, 1)` reverses the front. The outline remains visible from either side.

Three collinear positions enclose no area. FaceBody checks the cross-product magnitude before submitting vertices and clears the previous face when the triangle collapses. The cross product is supplied here as the area-and-normal calculation; vector products return in Forces. The small threshold also rejects nearly collapsed triangles. The helper creates visible geometry, not a physical barrier.

## Make it your own

Choose another three saved entries. Make a valid face, flatten it until it disappears, then restore it. Reverse the order and explain which side is now the front. Keep the original saved drawing unchanged.

Carry forward the position array, its ordered face recipe, and FaceBody. The next hall adds a fourth position and asks whether several faces can enclose a volume.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.

Godot documents clockwise front faces and ordered vertex submission in [SurfaceTool](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html).

[Current lesson.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Triangle_Context/lesson.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)


---

<!-- Hall 08: Primitives_Polythedra; source: commons/maps/Primitives_Polythedra/tutorial.md -->

# Four positions enclose a body

## Learning elements

- Shared vertices
- A list of face-index triples
- Tetrahedron connectivity
- Surface enclosure versus collision

## In the museum

A tetrahedron is the smallest closed body made entirely of triangular faces. The museum's polyhedra let you encounter a surface from outside and imagine the volume it encloses. Our construction begins with the same three saved entries used for Triangle and adds one point behind their face.

This lesson reloads the original Trace record. Moving a temporary Triangle handle did not change that file. Use the same CORNERS triple you selected there; the number of stored drawing entries determines which indices are available.

## Make this study

Attach lesson.gd to a unit-scale Node3D named PolyhedronStudy in this hall's working copy. Copy FaceBody, LineSkin and TraceArchive alongside it. All are printed below. No replacement camera, player or room is required.

The body uses a two-sided material so that removing a face lets you see the remaining surfaces from inside. Their winding still defines a front, as in Triangle; this display choice does not add volume or collision.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const Archive = preload("trace_archive.gd")
const FaceBody = preload("face_body.gd")
const CORNERS := Vector3i(0, 1, 2)
const DEPTH := 0.6
var points: Array[Vector3] = []
var faces: Array[Vector3i] = [
    Vector3i(0, 1, 2), Vector3i(0, 3, 1),
    Vector3i(1, 3, 2), Vector3i(2, 3, 0)]
var body := FaceBody.new()
var message := Label3D.new()

func _ready() -> void:
    body.surface.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
    add_child(body)
    add_child(message)
    message.position = Vector3(0, 2, 0)
    message.pixel_size = 0.003
    var drawing := Archive.load_drawing()
    if drawing == null:
        message.text = "Bring a drawing from Trace."
        return
    var record: PackedVector3Array = drawing.get_meta("positions")
    drawing.free()
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        if index < 0 or index >= record.size():
            message.text = "Choose three saved indices."
            return
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        points.append(record[index])
    var normal := (points[2] - points[0]).cross(points[1] - points[0])
    if normal.length() < 0.00001 or DEPTH <= 0.0:
        message.text = "Use a valid triangle and a positive depth."
        return
    var centre := (points[0] + points[1] + points[2]) / 3.0
    points.append(centre - normal.normalized() * DEPTH)
    body.show_faces(points, faces)
    message.text = "%d positions; %d faces." % [points.size(), faces.size()]
```

### Dependency: face_body.gd

<!-- student-code:face_body.gd -->
```gdscript
extends Node3D
## Visible triangular faces and their edges. This class adds no collision.
const LineSkin = preload("line_skin.gd")
var surface := MeshInstance3D.new()
var edges := Node3D.new()

func _init() -> void:
    add_child(surface)
    add_child(edges)
    var paper := StandardMaterial3D.new()
    paper.albedo_color = Color(0.92, 0.91, 0.87)
    paper.roughness = 0.75
    surface.material_override = paper

func show_faces(points: Array[Vector3], faces: Array[Vector3i]) -> bool:
    surface.mesh = null
    for edge in edges.get_children():
        edge.free()
    if faces.is_empty():
        return false
    for face in faces:
        for index in [face.x, face.y, face.z]:
            if index < 0 or index >= points.size():
                return false
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        if (c - a).cross(b - a).length() < 0.00001:
            return false
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in faces:
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        # Godot's front faces use clockwise winding.
        var normal := (c - a).cross(b - a).normalized()
        for point in [a, b, c]:
            builder.set_normal(normal)
            builder.add_vertex(point)
        for pair in [[a, b], [b, c], [c, a]]:
            var edge := LineSkin.new()
            edge.material_override.albedo_color = Color(0.04, 0.04, 0.045)
            edges.add_child(edge)
            var difference: Vector3 = pair[1] - pair[0]
            edge.show_segment(pair[0], difference, difference.length())
    surface.mesh = builder.commit()
    return true
```

### Dependency: line_skin.gd

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

### Dependency: trace_archive.gd

<!-- student-code:trace_archive.gd -->
```gdscript
# Supplied transport between museum halls. The lesson owns the drawing.
extends RefCounted

const PATH := "user://ada_student_trace.scn"

static func keep_on_release(point: Node3D, trail: Node3D, positions: Array[Vector3]) -> void:
    # Supplied lifecycle boundary: removing a scene is not a request to save.
    point.dropped.connect(func(_body):
        if point.get_meta("ada_release_cleanup", false):
            return
        if not is_instance_valid(trail) or not trail.is_inside_tree():
            return
        await trail.get_tree().process_frame
        if not is_instance_valid(point) or not is_instance_valid(trail):
            return
        if not point.is_inside_tree() or not trail.is_inside_tree():
            return
        if point.is_queued_for_deletion() or trail.is_queued_for_deletion():
            return
        if positions.size() >= 2:
            var error := save_drawing(trail, positions)
            if error != OK:
                push_error("Could not keep the trace: " + error_string(error))
    )

static func save_drawing(trail: Node3D, positions: Array[Vector3]) -> Error:
    if positions.size() < 2:
        return ERR_INVALID_DATA
    var saved := Node3D.new()
    saved.name = "SavedTrace"
    saved.set_meta("positions", PackedVector3Array(positions))
    saved.set_meta("frame", "PointStudy local metres")
    saved.set_meta("version", 1)
    for child in trail.get_children():
        if child.is_queued_for_deletion():
            continue
        var segment := MeshInstance3D.new()
        segment.transform = child.transform
        segment.visible = child.visible
        segment.mesh = child.mesh.duplicate()
        segment.mesh.resource_local_to_scene = true
        segment.material_override = child.material_override.duplicate()
        segment.material_override.resource_local_to_scene = true
        saved.add_child(segment)
        segment.owner = saved
    var scene := PackedScene.new()
    var error := scene.pack(saved)
    if error == OK:
        error = ResourceSaver.save(scene, PATH)
    saved.free()
    return error

static func load_drawing() -> Node3D:
    if not FileAccess.file_exists(PATH):
        return null
    var scene := ResourceLoader.load(PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if scene == null:
        return null
    var drawing := scene.instantiate() as Node3D
    if drawing == null:
        return null
    if drawing.get_meta("version", 0) != 1 or drawing.get_meta("frame", "") != "PointStudy local metres":
        drawing.free()
        return null
    var record = drawing.get_meta("positions", null)
    if not record is PackedVector3Array or record.size() < 2 or drawing.get_child_count() != record.size() - 1:
        drawing.free()
        return null
    return drawing
```

## Read the construction

`points` holds four positions. `faces` holds four **triples of indices into points**. In `Vector3i(0, 3, 1)`, the renderer reads entries zero, three and one; it does not create three new independent corners.

The fourth position starts at the base triangle's centre and moves DEPTH metres behind its front. Using the base normal means the apex remains off the base plane whichever way the saved triangle faces. A zero-area base cannot define that normal; the guard stops before normalizing it. DEPTH must be positive.

Each of the tetrahedron's six edges belongs to exactly two faces. Adjacent faces traverse their common edge in opposite directions, keeping their fronts outside. The renderer reads the same position again wherever its index occurs. For flat lighting it submits separate render vertices per face, but the construction still has four shared positions.

Change `points[3]`, then call `body.show_faces(points, faces)` again. Three faces move with that one entry. Editing an index changes a connection instead. A closed mesh is still only a visible surface: this program adds no collision shape.

## Make it your own

Replace the selected base with another valid triple, then halve DEPTH. Check that all four faces remain and that the apex is still off the base plane. Explain why a fifth copied point would not automatically become part of the enclosure.

Carry the separation between positions and connectivity into Cube. A longer face list will reuse the same renderer.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.

Godot documents clockwise front faces and ordered vertex submission in [SurfaceTool](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html).

[Current lesson.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Polythedra/lesson.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)


---

<!-- Hall 09: Point_Animatedcube; source: commons/maps/Point_Animatedcube/tutorial.md -->

# Eight corners, twelve triangles

## Learning elements

- A reusable CubeBody class
- Shared corner data
- Two triangles per square side
- Connectivity versus object position

## In the museum

The cube appears simple enough to arrive ready-made. The diagonal study in this hall exposes a decision hidden by that familiar outline: a square surface is represented here by two triangles. Build one cube, then a second with the other diagonal on its front side.

We keep FaceBody from the preceding halls. CubeBody adds a particular set of eight positions and twelve index triples. It is the cube we can carry into Transformation and Arrays.

## Make this study

Put the four printed files in one lesson folder and attach lesson.gd to an empty unit-scale Node3D named CubeStudy in the museum hall. CubeBody constructs its visible mesh itself. The placements in lesson.gd leave room between two one-metre cubes; they do not alter their local vertex data.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const CubeBody = preload("cube_body.gd")
var first := CubeBody.new()
var second := CubeBody.new()

func _ready() -> void:
    first.position = Vector3(-0.7, 0.7, 0)
    second.position = Vector3(0.7, 0.7, 0)
    add_child(first)
    add_child(second)
    second.other_diagonal()
```

### Dependency: cube_body.gd

<!-- student-code:cube_body.gd -->
```gdscript
extends "face_body.gd"
# Eight shared positions; each triple addresses three entries.
var points: Array[Vector3] = [
    Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, -0.5),
    Vector3(0.5, 1, -0.5), Vector3(-0.5, 1, -0.5),
    Vector3(-0.5, 0, 0.5), Vector3(0.5, 0, 0.5),
    Vector3(0.5, 1, 0.5), Vector3(-0.5, 1, 0.5)]
var faces: Array[Vector3i] = [
    Vector3i(4, 7, 5), Vector3i(5, 7, 6),
    Vector3i(0, 4, 1), Vector3i(1, 4, 5),
    Vector3i(2, 6, 3), Vector3i(3, 6, 7),
    Vector3i(1, 2, 0), Vector3i(0, 2, 3),
    Vector3i(0, 3, 4), Vector3i(4, 3, 7),
    Vector3i(5, 6, 1), Vector3i(1, 6, 2)]

func _init() -> void:
    super()
    show_faces(points, faces)

func other_diagonal() -> void:
    faces[0] = Vector3i(4, 6, 5)
    faces[1] = Vector3i(4, 7, 6)
    show_faces(points, faces)
```

### Dependency: face_body.gd

<!-- student-code:face_body.gd -->
```gdscript
extends Node3D
## Visible triangular faces and their edges. This class adds no collision.
const LineSkin = preload("line_skin.gd")
var surface := MeshInstance3D.new()
var edges := Node3D.new()

func _init() -> void:
    add_child(surface)
    add_child(edges)
    var paper := StandardMaterial3D.new()
    paper.albedo_color = Color(0.92, 0.91, 0.87)
    paper.roughness = 0.75
    surface.material_override = paper

func show_faces(points: Array[Vector3], faces: Array[Vector3i]) -> bool:
    surface.mesh = null
    for edge in edges.get_children():
        edge.free()
    if faces.is_empty():
        return false
    for face in faces:
        for index in [face.x, face.y, face.z]:
            if index < 0 or index >= points.size():
                return false
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        if (c - a).cross(b - a).length() < 0.00001:
            return false
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in faces:
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        # Godot's front faces use clockwise winding.
        var normal := (c - a).cross(b - a).normalized()
        for point in [a, b, c]:
            builder.set_normal(normal)
            builder.add_vertex(point)
        for pair in [[a, b], [b, c], [c, a]]:
            var edge := LineSkin.new()
            edge.material_override.albedo_color = Color(0.04, 0.04, 0.045)
            edges.add_child(edge)
            var difference: Vector3 = pair[1] - pair[0]
            edge.show_segment(pair[0], difference, difference.length())
    surface.mesh = builder.commit()
    return true
```

### Dependency: line_skin.gd

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

## Read the construction

CubeBody extends FaceBody, so it inherits the face renderer. Its `_init()` first calls `super()` to attach the parent's surface and edge container, then calls the renderer with this cube's recipe. Each call to `CubeBody.new()` creates a new object with its own position array, face array and mesh.

The corners use x and z values of −0.5 or 0.5 and y values of zero or one. The first two triples cover the positive-z side. `other_diagonal()` changes those two triples, keeping the four corner positions fixed. The black internal line moves to the other diagonal; the square's boundary and area stay the same.

Node position and vertex position do different jobs. `second.position` places the whole cube in the study. `second.points[6] += Vector3(0, 0, 0.35)` changes one local corner; call `second.show_faces(second.points, second.faces)` afterward to redraw it. Every face using entry six changes. A formerly square side can become two angled planes, making the diagonal matter to the surface itself.

These cubes have visible edges and faces, without colliders. The wider prefab collection in the museum remains available for reflection; it is not another construction dependency.

## Make it your own

Make a third CubeBody and place it somewhere else. Change one corner on that instance and redraw it. Verify that the first two cubes keep their shapes. Then explain the difference between moving a body and editing the data from which it is made.

Keep CubeBody. The next hall asks whether a short rule can generate a position list that we have so far written out.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.

Godot documents clockwise front faces and ordered vertex submission in [SurfaceTool](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html).

[Current lesson.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Animatedcube/lesson.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)


---

<!-- Hall 10: Primitives_Ignorance; source: commons/maps/Primitives_Ignorance/tutorial.md -->

# A rule produces positions

## Learning elements

- Functions and typed return values
- Parameters and arguments
- Symmetry as a construction rule
- Independent generated results

## In the museum

Among the Platonic solids, the octahedron offers a compact rule: put a position at each end of three perpendicular axes. Six positions replace a long list of coordinates. The geometry courtyard gives the result a place; this lesson makes its construction available to you.

The hanging black point near the exit previews the next lesson: holding it reduces its rings and segments, and the trigger sends its current form. You can try it here; this tutorial stays with the rule that produces positions. Primitives_Godot returns to the same point to explain its resolution parameters.

In Cube, you wrote the corner positions into a list. Here you write a rule that returns a list for each radius you give it. Arrays, loops and the face renderer return; a named function makes their work reusable. We supply the eight face triples so that the lesson stays with generating positions.

You can still work out every coordinate. What changes is where you make the decision: choose the rule and its input, then inspect the positions they produce. Later generators can produce more than you would want to place one point at a time.

## Make this study

Attach lesson.gd to a Node3D named GeneratorStudy in this museum hall. FaceBody and LineSkin are unchanged. The two calls deliberately use different radii and store their results separately.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const FaceBody = preload("face_body.gd")
# Connectivity is supplied; this lesson generates the positions.
const FACES: Array[Vector3i] = [
    Vector3i(2, 0, 4), Vector3i(2, 4, 1),
    Vector3i(2, 1, 5), Vector3i(2, 5, 0),
    Vector3i(3, 4, 0), Vector3i(3, 1, 4),
    Vector3i(3, 5, 1), Vector3i(3, 0, 5)]
var small_points: Array[Vector3] = []
var large_points: Array[Vector3] = []

func _ready() -> void:
    small_points = octahedron_positions(0.3)
    large_points = octahedron_positions(0.6)
    var small := FaceBody.new()
    var large := FaceBody.new()
    small.position = Vector3(-0.7, 1.1, 0)
    large.position = Vector3(0.7, 1.1, 0)
    add_child(small)
    add_child(large)
    small.show_faces(small_points, FACES)
    large.show_faces(large_points, FACES)

func octahedron_positions(radius: float) -> Array[Vector3]:
    assert(radius > 0.0)
    var result: Array[Vector3] = []
    for axis in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
        result.append(axis * radius)
        result.append(-axis * radius)
    return result
```

### Dependency: face_body.gd

<!-- student-code:face_body.gd -->
```gdscript
extends Node3D
## Visible triangular faces and their edges. This class adds no collision.
const LineSkin = preload("line_skin.gd")
var surface := MeshInstance3D.new()
var edges := Node3D.new()

func _init() -> void:
    add_child(surface)
    add_child(edges)
    var paper := StandardMaterial3D.new()
    paper.albedo_color = Color(0.92, 0.91, 0.87)
    paper.roughness = 0.75
    surface.material_override = paper

func show_faces(points: Array[Vector3], faces: Array[Vector3i]) -> bool:
    surface.mesh = null
    for edge in edges.get_children():
        edge.free()
    if faces.is_empty():
        return false
    for face in faces:
        for index in [face.x, face.y, face.z]:
            if index < 0 or index >= points.size():
                return false
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        if (c - a).cross(b - a).length() < 0.00001:
            return false
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in faces:
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        # Godot's front faces use clockwise winding.
        var normal := (c - a).cross(b - a).normalized()
        for point in [a, b, c]:
            builder.set_normal(normal)
            builder.add_vertex(point)
        for pair in [[a, b], [b, c], [c, a]]:
            var edge := LineSkin.new()
            edge.material_override.albedo_color = Color(0.04, 0.04, 0.045)
            edges.add_child(edge)
            var difference: Vector3 = pair[1] - pair[0]
            edge.show_segment(pair[0], difference, difference.length())
    surface.mesh = builder.commit()
    return true
```

### Dependency: line_skin.gd

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

## Read the construction

`radius` is the function's parameter. The numbers 0.3 and 0.6 are arguments supplied by two calls. `-> Array[Vector3]` names the kind of value returned: a list of positions. The positive-radius assertion states the function's domain.

For each positive axis, the loop appends one position and its opposite. The order is +X, −X, +Y, −Y, +Z, −Z. The supplied face list depends on that order. Rearranging the list without changing the faces would make a different set of connections.

The function builds a fresh `result` on every call and returns it. It does not place a body in the room or draw anything. FaceBody takes the returned data and renders it. This separates generating positions from displaying them without introducing a general-purpose factory.

Changing a returned position changes one result. Changing the rule changes future results. Neither operation makes a claim about which sculpture is better. Radius, geometric relationship and aesthetic judgment are different decisions.

## Make it your own

Call the function with 0.45. Use the returned array to display a third body. Move one entry in that array, redraw only that body, and verify that the other two remain unchanged. Describe the symmetry your edit broke.

Carry the idea of a parameter controlling a construction. In Godot Primitives, return to your original sphere and make two of the engine's construction parameters available while holding it.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.


[Current lesson.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Ignorance/lesson.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)


---

<!-- Hall 11: Primitives_Godot; source: commons/maps/Primitives_Godot/tutorial.md -->

# The held sphere loses resolution

## Learning elements

- Resolution as a construction parameter
- Rings and radial segments
- Visible construction and collision
- Independent mesh resources

## In the museum

Return to the small white sphere you could pick up in Coordinates and use to draw in Trace. In this hall, holding it changes its visible construction. Rings and radial segments decrease in small timed steps. Release it and the change pauses. Its size and physical boundary remain the same.

The lesson is **resolution as a parameter of construction**: the same named sphere can have several finite meshes. Change rings while keeping radial segments fixed, then reverse that comparison. Keep radius and the spherical collider unchanged.

Pickup returns from Coordinates. PointBody and the class extension return from earlier lessons; the short held-time controller is supplied support for this comparison. Its complete code and explanation remain below, but reconstructing the timer is not the new learning goal. The museum's wider primitive library is available to explore.

## Make this study

Attach lesson.gd to a unit-scale Node3D named ResolutionStudy in the working museum hall. The existing XR Tools hands provide pickup. The two spheres use the same class but own separate resources. To repeat the comparison, restart the study. The supplied `ui_accept` action also calls `reset_resolution()` on both spheres; its input binding belongs to Day Zero.

PointBody is a small later edition of the earlier file: `sphere` is now a member variable instead of a local `_init` variable. Its radius, height, collider, material defaults and pickup settings are unchanged. Keep this edition in this lesson folder; earlier tested scripts need no edits.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const ResolutionPoint = preload("resolution_point.gd")
var point := ResolutionPoint.new()
var comparison := ResolutionPoint.new()
var message := Label3D.new()

func _ready() -> void:
    point.position = Vector3(-0.3, 1.12, 0)
    comparison.position = Vector3(0.3, 1.12, 0)
    add_child(point)
    add_child(comparison)
    add_child(message)
    message.position = Vector3(0, 1.65, 0)
    message.pixel_size = 0.002

func _process(delta: float) -> void:
    point.advance(delta)
    comparison.advance(delta)
    if Input.is_action_just_pressed("ui_accept"):
        point.reset_resolution()
        comparison.reset_resolution()
    message.text = "RINGS %d   SEGMENTS %d" % [point.sphere.rings, point.sphere.radial_segments]
```

### Dependency: point_body.gd

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14
var sphere := SphereMesh.new()

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```

### Dependency: resolution_point.gd

<!-- student-code:resolution_point.gd -->
```gdscript
extends "point_body.gd"
const START_RINGS := 16
const START_SEGMENTS := 32
const STEP_SECONDS := 0.15
var elapsed := 0.0

func _init() -> void:
    super()
    reset_resolution()

func advance(delta: float) -> void:
    if not is_picked_up():
        return
    elapsed += delta
    while elapsed + 0.000001 >= STEP_SECONDS:
        elapsed = maxf(0.0, elapsed - STEP_SECONDS)
        sphere.rings = maxi(1, sphere.rings - 1)
        sphere.radial_segments = maxi(4, sphere.radial_segments - 1)

func reset_resolution() -> void:
    elapsed = 0.0
    sphere.rings = START_RINGS
    sphere.radial_segments = START_SEGMENTS
```

## Read the construction

ResolutionPoint extends PointBody. `super()` runs the base constructor, which constructs the visible sphere and physical boundary; the added class controls the existing sphere mesh. `sphere.rings` divides the construction along its height; `sphere.radial_segments` divides it around the axis. Neither setting changes its radius.

`advance(delta)` receives elapsed seconds from the hall's `_process`. Its first condition returns immediately while the point is not held. Otherwise it accumulates time. A `while` loop consumes every complete 0.15-second interval, including several intervals during a long frame. Release preserves the remaining fraction, and re-grabbing continues it.

`maxi` stops rings at one and radial segments at four, the valid lower bounds used here. We approach a coarse sphere, not a zero-vertex object. The analytical sphere collider remains round: seeing a faceted mesh does not imply feeling a faceted boundary.

`reset_resolution()` restores the two starting counts and clears the clock. Both calls to `ResolutionPoint.new()` construct their own mesh; changing one must not quietly change its neighbour.

## Make it your own

First hold only the left sphere. Make a variant that decrements rings but leaves radial segments unchanged; make a second variant that changes only radial segments. Predict and compare the visible results. Identify what stayed the same: radius, collider and the untouched neighbour.

As a separate check of the supplied controller, release halfway through an interval, wait, and resume. Its change should follow held time, not time spent looking at the sphere.

Carry the same body and the distinction between shape, appearance, interaction and construction parameters. Columns next gives a family of forms three separate inputs.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.

Parameter meanings: [Godot 4.6 SphereMesh](https://docs.godotengine.org/en/4.6/classes/class_spheremesh.html). The minimum counts are checked by this lesson’s native tests.

[Current lesson.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Godot/lesson.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)


---

<!-- Hall 12: Primitives_Columns; source: commons/maps/Primitives_Columns/tutorial.md -->

# One profile, several resolutions

## Learning elements

- A profile as a radius list
- Nested loops over rings and sides
- Independent height and resolution
- Comparing one variable at a time

## In the museum

The colonnade varies outlines, heights and resolution. Begin with a controlled row: the same profile and height at 4, 6, 8, 12 and 16 sides. Once you can identify what resolution changes, give the columns different silhouettes.

The octahedron lesson generated positions with a function. Here another function generates a stack of rings. Circle sampling and the surface stitcher are supplied below so that the new work stays with the profile, the two loops and their indexing.

## Make this study

Attach lesson.gd to a Node3D named ColumnStudy in this hall's working copy. Allow roughly five metres for the row. The program creates its own meshes and pale material. Keep positive radii, at least two profile entries, a positive height and at least three sides. For the first variations stay near the displayed dimensions; more samples consume more memory and drawing work.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const Circle = preload("circle_samples.gd")
const ColumnSurface = preload("column_surface.gd")
const PROFILE: Array[float] = [0.35, 0.35, 0.18, 0.25, 0.4, 0.4]
const HEIGHT := 2.2

func _ready() -> void:
    var choices := [4, 6, 8, 12, 16]
    for i in range(choices.size()):
        var column := MeshInstance3D.new()
        var points := column_positions(PROFILE, HEIGHT, choices[i])
        column.mesh = ColumnSurface.make(points, choices[i])
        column.position.x = (i - 2) * 1.0
        var finish := StandardMaterial3D.new()
        finish.albedo_color = Color(0.92, 0.91, 0.87)
        finish.roughness = 0.7
        column.material_override = finish
        add_child(column)

func column_positions(profile: Array[float], height: float, sides: int) -> Array[Vector3]:
    assert(profile.size() >= 2 and height > 0.0 and sides >= 3)
    var result: Array[Vector3] = []
    for ring in range(profile.size()):
        var y := height * ring / (profile.size() - 1)
        for point in Circle.make(sides, profile[ring]):
            result.append(point + Vector3(0, y, 0))
    return result
```

### Dependency: circle_samples.gd

<!-- student-code:circle_samples.gd -->
```gdscript
extends RefCounted
# Supplied circle sampler. Angles return in the Waves sequence.
static func make(sides: int, radius: float) -> Array[Vector3]:
    assert(sides >= 3 and radius > 0.0)
    var points: Array[Vector3] = []
    for side in range(sides):
        var angle := TAU * side / sides
        points.append(Vector3(cos(angle), 0, sin(angle)) * radius)
    return points
```

### Dependency: column_surface.gd

<!-- student-code:column_surface.gd -->
```gdscript
extends RefCounted
## Supplied renderer. Consecutive rings have the same number and order of samples.
## It joins neighbours, closes the seam, and adds two planar caps. No collider.

static func make(points: Array[Vector3], sides: int) -> ArrayMesh:
    assert(sides >= 3 and points.size() >= 2 * sides and points.size() % sides == 0)
    var rings: int = points.size() / sides
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for ring in range(rings - 1):
        for side in range(sides):
            var next := (side + 1) % sides
            var a := points[ring * sides + side]
            var b := points[(ring + 1) * sides + side]
            var c := points[ring * sides + next]
            var d := points[(ring + 1) * sides + next]
            triangle(builder, a, b, c)
            triangle(builder, c, b, d)
    var bottom := Vector3(0, points[0].y, 0)
    var top := Vector3(0, points[-1].y, 0)
    var last := (rings - 1) * sides
    for side in range(sides):
        var next := (side + 1) % sides
        triangle(builder, bottom, points[side], points[next])
        triangle(builder, top, points[last + next], points[last + side])
    return builder.commit()

static func triangle(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    # Outward normal from the ordered construction; Godot front faces are clockwise.
    var normal := (b - a).cross(c - a).normalized()
    for point in [a, c, b]:
        builder.set_normal(normal)
        builder.add_vertex(point)
```

## Read the construction

PROFILE stores a radius for each height level. Its entries are spaced evenly from the bottom to the full HEIGHT. The outer loop visits a level; the inner loop visits positions around that level's circle. A profile of six entries at eight sides produces 48 positions.

`height * ring / (profile.size() - 1)` places the last ring exactly at the requested height. Circle.make supplies a ring in the x–z plane. Adding `(0, y, 0)` lifts it to the current level. Its cosine and sine are borrowed circle coordinates here; periodic motion returns to their meaning in Waves.

ColumnSurface joins neighbouring rings, closes the last side to the first, and caps both ends. The side order must match at every ring. It connects samples with straight faces, so this small construction has piecewise straight profiles rather than the museum gallery's more elaborate curves. It adds no collision.

Changing sides changes angular sampling. Changing PROFILE changes the silhouette. Changing HEIGHT stretches the spacing between its levels. A higher resolution is not a better proportion or a more interesting sculpture.

## Make it your own

Keep eight sides and make a new positive-radius profile. Then keep that profile and change only its height. Finally use it for all five resolutions. Explain which differences come from your rule and which come from sampling it.

Carry the profile-and-path distinction into the next hall, where the cross-section is borrowed from a letter rather than written as a radius list.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.


[Current lesson.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Columns/lesson.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)


---

<!-- Hall 13: Primitives_Profiles; source: commons/maps/Primitives_Profiles/tutorial.md -->

# A letter carries its opening

## Learning elements

- A supplied outline with a hole
- Cross-section versus route
- Sampling placements along a path
- Declaring a dependency

## In the museum

An O can become a short hollow passage. Its interior opening is part of the source outline, not a hole we draw afterward. The museum's glyph gallery explores this relation at architectural scale. Here we use its existing outline-and-sweep builder for one small visible body.

The lesson is **a section carried along a route**. Return first to the familiar column: at each height, its radius list chose the size of a ring. Imagine keeping those rings the same size and placing them along a straight route. Now substitute the supplied O outline for the ring. The section tells us what is carried; the route tells us where it goes.

Start with the same O and width throughout. Change only the sideways travel, OFFSET. The font record, placement formula and surface builder are supplied support. Font extraction, triangulation, holes and general path orientation are not additional tasks to solve here.

## Make this study

Put lesson.gd, profile_sweep.gd, JetBrainsMono-Medium.ttf and its OFL licence in one folder. The font and licence are in this lesson's downloadable folder; let Godot import the font. Attach lesson.gd to a Node3D named ProfileStudy in the existing museum.

This small example is a visible hollow mesh, without a collider. Its O has a lower sill, so “opening” does not mean a floor-level walk-through doorway. The museum's larger passage uses its own placement and collision setup.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const Sweep = preload("profile_sweep.gd")
const FONT = preload("JetBrainsMono-Medium.ttf")
const WIDTH := 1.4
const DEPTH := 1.6
const OFFSET := 0.5
var section: Dictionary
var frames: Array[Transform3D] = []
var body := MeshInstance3D.new()

func _ready() -> void:
    section = Sweep.profile(FONT, "O")
    for i in range(5):
        var fraction := i / 4.0
        var at := Vector3(OFFSET * fraction, 1.1, DEPTH * fraction)
        var frame := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * WIDTH), at)
        frames.append(frame)
    body.mesh = Sweep.make(section, frames)
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.78, 0.62, 0.72)
    finish.roughness = 0.4
    body.material_override = finish
    add_child(body)
```

### Dependency: profile_sweep.gd

<!-- student-code:profile_sweep.gd -->
```gdscript
extends RefCounted
## TextMesh supplies a triangulated 2D region, including holes and components.
## A sequence of section frames turns that region into a body. No font is edited.

static func profile(font: Font, glyph: String) -> Dictionary:
    var flat := TextMesh.new()
    flat.font = font
    flat.text = glyph
    flat.font_size = 48
    flat.pixel_size = .04
    flat.curve_step = .5
    flat.depth = 0
    var arrays := flat.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    var bounds := flat.get_aabb()
    assert(not vertices.is_empty() and bounds.size.y > 0, "No vector glyph")
    var points: Array[Vector2] = []
    var ids: Array[int] = []
    var lookup := {}
    for vertex in vertices:
        var p := Vector2(vertex.x - bounds.get_center().x, vertex.y - bounds.get_center().y) / bounds.size.y
        var key := Vector2i(roundi(p.x * 1000000), roundi(p.y * 1000000))
        if not lookup.has(key):
            lookup[key] = points.size()
            points.append(p)
        ids.append(lookup[key])
    var faces: Array[Vector3i] = []
    var edges := {}
    var count := indices.size() if not indices.is_empty() else vertices.size()
    for i in range(0, count, 3):
        var f := Vector3i(ids[indices[i]] if not indices.is_empty() else ids[i],
            ids[indices[i+1]] if not indices.is_empty() else ids[i+1],
            ids[indices[i+2]] if not indices.is_empty() else ids[i+2])
        faces.append(f)
        for e in [Vector2i(f.x, f.y), Vector2i(f.y, f.z), Vector2i(f.z, f.x)]:
            var key := Vector2i(mini(e.x, e.y), maxi(e.x, e.y))
            if edges.has(key):
                edges[key][0] += 1
            else:
                edges[key] = [1, e]
    var boundary: Array[Vector2i] = []
    for entry in edges.values():
        assert(entry[0] <= 2, "Non-manifold source face")
        if entry[0] == 1:
            boundary.append(entry[1])
    return {"glyph": glyph, "points": points, "faces": faces, "boundary": boundary}

static func make(section: Dictionary, frames: Array[Transform3D], loop: bool = false) -> ArrayMesh:
    assert(frames.size() >= 2)
    var points: Array[Vector2] = section.points
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    if not loop:
        for f: Vector3i in section.faces:
            _tri(vertices, normals, _at(points[f.x], frames[-1]), _at(points[f.y], frames[-1]), _at(points[f.z], frames[-1]))
            _tri(vertices, normals, _at(points[f.z], frames[0]), _at(points[f.y], frames[0]), _at(points[f.x], frames[0]))
    # Smooth only side walls. Cap normals remain distinct at the rim.
    var side_start := vertices.size()
    var smooth := {}
    for e: Vector2i in section.boundary:
        for i in range(frames.size() if loop else frames.size()-1):
            var j := (i+1) % frames.size()
            var a := _at(points[e.x], frames[i])
            var b := _at(points[e.y], frames[i])
            var c := _at(points[e.y], frames[j])
            var d := _at(points[e.x], frames[j])
            _tri(vertices, normals, a, b, c)
            _tri(vertices, normals, a, c, d)
    for i in range(side_start, vertices.size(), 3):
        var normal := (vertices[i+2]-vertices[i]).cross(vertices[i+1]-vertices[i])
        for j in 3:
            var key := Vector3i((vertices[i+j]*100000).round())
            smooth[key] = smooth.get(key, Vector3.ZERO) + normal
    for i in range(side_start, vertices.size()):
        normals[i] = (smooth[Vector3i((vertices[i]*100000).round())] as Vector3).normalized()
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    mesh.set_meta("glyph", section.glyph)
    mesh.set_meta("loop", loop)
    return mesh

static func _at(point: Vector2, frame: Transform3D) -> Vector3:
    return frame * Vector3(point.x, point.y, 0)

static func _tri(v: PackedVector3Array, n: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
    var normal := (c-a).cross(b-a).normalized() # Godot's clockwise front faces.
    v.append_array(PackedVector3Array([a,b,c]))
    n.append_array(PackedVector3Array([normal,normal,normal]))
```

## Read the construction

`Sweep.profile(FONT, "O")` returns a Dictionary: named entries containing the outline positions, cap triangles and boundary edges. You borrow that record intact. Its inner boundary matters as much as its outside edge.

Each Transform3D is a placement for one copy of that cross-section. The supplied expression uses a uniform WIDTH and the position `at`; it leaves all sections parallel. Transformation will examine the basis more closely. The loop creates five placements from fraction zero to one. DEPTH sets their z travel and OFFSET their total sideways travel. This version shears along a straight route; it does not solve arbitrary curved-path orientation.

`Sweep.make(section, frames)` connects corresponding boundary edges between placements and caps the material at the ends. It preserves the O's opening through those caps. The full helper is printed below as a declared dependency. The student-owned decisions are the chosen glyph, size and route—not a claim to have rebuilt font triangulation.

## Make it your own

Set OFFSET to zero; then give it the opposite sign. Keep the O, WIDTH and DEPTH unchanged. Predict the direction of travel and verify that the opening survives. Point to what belongs to the unchanged section and what came from its route.

Once that distinction is clear, try C with the same route. Its gap connects the hollow to the outside; the material outline itself still has a closed boundary. Some glyphs have disconnected components, so one character need not make one connected solid.

Carry the distinction between a rule you write and a structure you borrow. Portals asks how a finite construction can answer a question about an ideal form.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.

The supplied sweep is copied from `commons/artifacts/glyph_profile_gallery/profile_sweep.gd`; JetBrains Mono is distributed with its OFL licence. Font geometry uses [Godot TextMesh](https://docs.godotengine.org/en/4.6/classes/class_textmesh.html).

[Current lesson.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Profiles/lesson.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)


---

<!-- Hall 14: Primitives_Portals; source: commons/maps/Primitives_Portals/tutorial.md -->

# Choose a useful limit

## Learning elements

- A closed neighbour loop
- Error in a stated unit
- A while loop with a stopping rule
- A finite work budget

## In the museum

A circle's perimeter offers a question that a finite polygon can answer approximately. How many sides are enough for a chosen measurement? The hall's encounters with limits give that question a wider setting; our program makes one bounded decision visible.

Reuse Circle.make from Columns and LineSkin from Lines. There is no new shape factory. Add the lengths between neighbouring samples, including the last sample back to the first.

## Make this study

Attach lesson.gd to a unit-scale Node3D named LimitStudy in this museum hall. The polygon is drawn horizontally at hand height. TOLERANCE is an absolute perimeter error in metres; BUDGET is the maximum number of sides this run may use.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const Circle = preload("circle_samples.gd")
const LineSkin = preload("line_skin.gd")
const RADIUS := 0.7
const TOLERANCE := 0.01
const BUDGET := 96
var sides := 3
var points: Array[Vector3] = []
var error := 0.0
var met := false
var message := Label3D.new()

func _ready() -> void:
    choose_resolution(TOLERANCE, BUDGET)
    for i in range(points.size()):
        var a := points[i] + Vector3(0, 1.1, 0)
        var b := points[(i + 1) % points.size()] + Vector3(0, 1.1, 0)
        var line := LineSkin.new()
        add_child(line)
        line.show_segment(a, b - a, a.distance_to(b))
    add_child(message)
    message.position = Vector3(0, 1.8, 0)
    message.pixel_size = 0.002
    message.text = "%d sides; error %.5f m; met: %s" % [sides, error, str(met)]

func perimeter(record: Array[Vector3]) -> float:
    var total := 0.0
    for i in range(record.size()):
        total += record[i].distance_to(record[(i + 1) % record.size()])
    return total

func choose_resolution(tolerance: float, budget: int) -> void:
    assert(tolerance > 0.0 and budget >= 3)
    sides = 3
    while true:
        points = Circle.make(sides, RADIUS)
        error = absf(TAU * RADIUS - perimeter(points))
        met = error <= tolerance
        if met or sides == budget:
            break
        sides = mini(sides * 2, budget)
```

### Dependency: circle_samples.gd

<!-- student-code:circle_samples.gd -->
```gdscript
extends RefCounted
# Supplied circle sampler. Angles return in the Waves sequence.
static func make(sides: int, radius: float) -> Array[Vector3]:
    assert(sides >= 3 and radius > 0.0)
    var points: Array[Vector3] = []
    for side in range(sides):
        var angle := TAU * side / sides
        points.append(Vector3(cos(angle), 0, sin(angle)) * radius)
    return points
```

### Dependency: line_skin.gd

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

## Read the construction

`(i + 1) % record.size()` wraps the last index to zero. Without that closing edge, the sum would measure an open path. `perimeter` returns one number rather than creating geometry.

The program compares that sum with `TAU * RADIUS`, the floating-point circle circumference used as its numerical reference. Starting with three sides, it doubles the side count, stopping at the budget if a doubling would exceed it. After each new polygon it recomputes error.

There are two honest endings: the requested tolerance is met, or the available work is spent. `met` records which happened. A very small tolerance and a small budget should report false, not run forever or silently claim success. The budget counts samples, not elapsed GPU time.

This does not calculate every digit of pi or prove a limit. Both the circle reference and the sampled coordinates use finite precision. It makes the choice of an adequate approximation inspectable.

The circle sampler returns from Columns. Its sine and cosine calls are printed support; deriving them is a later investigation. Here, use the sampled positions to choose and test a stopping rule. You can understand the condition for stopping before explaining every operation that supplied the points.

## Make it your own

Compare tolerances 0.05 and 0.005 with the same radius and budget. Then request 0.000001 with a budget of twelve. Predict which run will exhaust its budget. Explain what “enough” means in each case and why the last case must still stop.

Carry the ability to name a criterion and a limit. The final Primitives hall gives you room to decide what to make with the constructions already available.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.


[Current lesson.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Portals/lesson.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)


---

<!-- Hall 15: Primitives_Melencolia; source: commons/maps/Primitives_Melencolia/tutorial.md -->

# Arrange what you can already make

## Learning elements

- Composition with known classes
- Independent instances
- Placement versus construction
- Reusing a learned capability

## In the museum

Dürer's objects gather in the museum's Melencolia hall. Our tutorial closes this sequence with a smaller task: make an arrangement from two instances of your cube and the familiar sphere point. The reflective text can ask what geometry promises; the tutorial gives you enough control to make an arrangement of your own.

There is no new mesh recipe here. Keep CubeBody from Cube and PointBody from the earlier point lessons. These are recognizable constructions, not substitutes downloaded for the closing image.

## Make this study

Attach lesson.gd to a unit-scale Node3D named ArrangementStudy in this hall's working copy. Place that study at floor level. The cube's local bottom is y = 0; the sphere's centre is one radius above the floor. PointBody retains pickup and frozen release; the cubes remain visible mesh objects without colliders.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const CubeBody = preload("cube_body.gd")
const PointBody = preload("point_body.gd")
var places: Array[Vector3] = [Vector3(-0.8, 0, 0), Vector3(0.5, 0, -0.7)]
var cubes: Array[Node3D] = []
var point := PointBody.new()

func _ready() -> void:
    for place in places:
        var cube := CubeBody.new()
        cube.position = place
        add_child(cube)
        cubes.append(cube)
    point.position = Vector3(0.1, PointBody.RADIUS, 0.6)
    add_child(point)
```

### Dependency: cube_body.gd

<!-- student-code:cube_body.gd -->
```gdscript
extends "face_body.gd"
# Eight shared positions; each triple addresses three entries.
var points: Array[Vector3] = [
    Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, -0.5),
    Vector3(0.5, 1, -0.5), Vector3(-0.5, 1, -0.5),
    Vector3(-0.5, 0, 0.5), Vector3(0.5, 0, 0.5),
    Vector3(0.5, 1, 0.5), Vector3(-0.5, 1, 0.5)]
var faces: Array[Vector3i] = [
    Vector3i(4, 7, 5), Vector3i(5, 7, 6),
    Vector3i(0, 4, 1), Vector3i(1, 4, 5),
    Vector3i(2, 6, 3), Vector3i(3, 6, 7),
    Vector3i(1, 2, 0), Vector3i(0, 2, 3),
    Vector3i(0, 3, 4), Vector3i(4, 3, 7),
    Vector3i(5, 6, 1), Vector3i(1, 6, 2)]

func _init() -> void:
    super()
    show_faces(points, faces)

func other_diagonal() -> void:
    faces[0] = Vector3i(4, 6, 5)
    faces[1] = Vector3i(4, 7, 6)
    show_faces(points, faces)
```

### Dependency: face_body.gd

<!-- student-code:face_body.gd -->
```gdscript
extends Node3D
## Visible triangular faces and their edges. This class adds no collision.
const LineSkin = preload("line_skin.gd")
var surface := MeshInstance3D.new()
var edges := Node3D.new()

func _init() -> void:
    add_child(surface)
    add_child(edges)
    var paper := StandardMaterial3D.new()
    paper.albedo_color = Color(0.92, 0.91, 0.87)
    paper.roughness = 0.75
    surface.material_override = paper

func show_faces(points: Array[Vector3], faces: Array[Vector3i]) -> bool:
    surface.mesh = null
    for edge in edges.get_children():
        edge.free()
    if faces.is_empty():
        return false
    for face in faces:
        for index in [face.x, face.y, face.z]:
            if index < 0 or index >= points.size():
                return false
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        if (c - a).cross(b - a).length() < 0.00001:
            return false
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in faces:
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        # Godot's front faces use clockwise winding.
        var normal := (c - a).cross(b - a).normalized()
        for point in [a, b, c]:
            builder.set_normal(normal)
            builder.add_vertex(point)
        for pair in [[a, b], [b, c], [c, a]]:
            var edge := LineSkin.new()
            edge.material_override.albedo_color = Color(0.04, 0.04, 0.045)
            edges.add_child(edge)
            var difference: Vector3 = pair[1] - pair[0]
            edge.show_segment(pair[0], difference, difference.length())
    surface.mesh = builder.commit()
    return true
```

### Dependency: line_skin.gd

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

### Dependency: point_body.gd

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```

## Read the construction

The loop constructs two independent CubeBody instances and assigns positions from places. Reusing a class does not mean sharing one mutable vertex array. Moving an instance should leave its geometry and its neighbour unchanged.

The point is the same white sphere with the same size and interaction settings. It can be picked up and left somewhere else during a run. That temporary placement is not written back into this script. To keep an arrangement across runs, put your chosen coordinates in the source; persistent composition is a later capability.

The program uses constructors, arrays, a loop and positions you have already met. Scale and rotation stay for Transformation. You can still change the relation between bodies through distance, overlap and placement. The resulting arrangement is your decision, not the inevitable output of the cube rule.

## Make it your own

Make a second arrangement by changing only places and the point's initial position. Keep the classes unchanged. Show how a different interval or overlap changes what you notice. You should be able to reconstruct both arrangements from their saved script values.

## After the chapter: an arrangement without a recipe

Choose a different arrangement in a clear part of your working museum hall. Use the earlier files as references, but write your own small main script. This is an independent challenge; there is no new construction hidden in a supplied answer.

- Generate a list of at least five positions with a rule you can explain. Keep an unchanged source list and modify an independently owned copy.
- Reuse PointBody and FaceBody. Choose three non-collinear entries from the list and connect them as a face.
- Show two spheres of equal radius with different resolutions, using the construction already studied in Godot Primitives.
- Decide their spacing and arrangement. Keep the known collider behaviour; making a new walkable structure is outside this task.

Show the arrangement to someone who has not seen your script. Locate the stored values, the variable referring to each body, and the indices establishing the face. Explain what the generator decided, what resolution changed, what you preserved, and one aesthetic choice that no calculation required.

Run your script and check that changing the copy leaves the source intact, that the selected face has area, and that each sphere keeps its own mesh. Then change one choice and predict the result before running again. Successful execution is evidence about the program; explaining and transferring the choices gives evidence about what you learned.

Carry CubeBody and PointBody into Transformation. A body that you can place is ready to become a body whose position, rotation or scale changes over time.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.


[Current lesson.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Melencolia/lesson.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)
