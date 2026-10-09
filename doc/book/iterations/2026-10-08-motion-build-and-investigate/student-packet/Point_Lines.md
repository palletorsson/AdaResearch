# Point Lines — what can two lines do?

**Learning elements**

- Endpoints and a segment
- Displacement and distance
- A class and its instances
- Parallel, cross and X
- Position in depth

Take one end of the line in the black room. The other stays. The span turns and changes length. We will make that relation using the point from Coordinates, then arrange two lines into parallel marks, a plus and an X.

## Keep the point; give it another end

Continue from your working [Coordinates script](Point_Coordinates.md). Save `point_body.gd`, `line.gd` and `line_skin.gd` together. All three files are printed below; only the drawing helper is supplied. On your existing `PointStudy` node, replace the attached `point.gd` with `line.gd`. Keep `point.gd` as the previous working version. The prepared museum supplies the room, light and configured XR hands.

Keep `PointStudy` at scale `(1, 1, 1)`. With this scale, our measured units remain metres.

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

`_init()` runs when we call `.new()`. It builds the point before the lesson adds it to the scene. We leave XR Tools' `_ready()` in place.

## The complete continuation — line.gd

This smaller lesson places two instances and reads their relation each frame. The coordinate readout stays here.

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

The class holds what makes this a pickable point. The station holds what makes these two points a line.

Coordinates already produced `local_position` for the first point. Here `a` keeps that value. `to_local(point_b.global_position)` expresses B in the same `PointStudy` frame. Now we can subtract like from like.

`b - a` is the displacement from A to B: initially `(1, 0, 0)`. Its `.length()` returns `1.0`. The displacement holds direction and length; the distance holds length alone. The final `+=` adds a DISTANCE line to the coordinate text written earlier in that frame.

Each frame reads the bodies again; the line remains a relation between their current positions.

Change B's starting offset from `Vector3(1.0, 0, 0)` to `Vector3(0, 1.0, 0)`. Predict the distance, then run. The line stands upright and keeps its length. Restore the original offset.

Try `a - b` instead of `b - a`. The distance stays the same, but the cylinder now points the opposite way from A and misses B. Subtraction has an order. Restore `b - a`.

## The supplied drawing code — line_skin.gd

A mathematical line has no thickness. Our example joins two endpoints into a finite segment; this helper gives that segment a surface. It supplies no collider or pickup behaviour.

It places the cylinder halfway between the ends and turns its long axis along their displacement. The orientation calculation is supplied for now; basis vectors are not a prerequisite for this lesson.

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

[Current line.gd](file:///C:/Users/palle/Documents/GitHub/AdaResearch_46/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Lines/line.gd) · [Complete working project](file:///C:/Users/palle/Documents/GitHub/AdaResearch_46/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](file:///C:/Users/palle/Documents/GitHub/AdaResearch_46/doc/book/iterations/2026-10-06-starter-one-course/index.html)

[Complete experiment: line_reversed.gd](file:///C:/Users/palle/Documents/GitHub/AdaResearch_46/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Lines/line_reversed.gd)
