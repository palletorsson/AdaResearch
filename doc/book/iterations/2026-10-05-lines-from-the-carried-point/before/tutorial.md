# Point Lines — what can two lines do?

**Learning elements**

- Endpoints and a segment
- Displacement and distance
- Reusing an object
- Parallel, cross and X
- Position in depth

Take one end of the line in the black room. The other stays. The span turns and changes length. In this tutorial, we will make that relation using the point from Coordinates, then arrange two lines into parallel marks, a plus and an X.

## What we continue

The point already has a surface, a collider and pickup behaviour. We keep that construction. The new work gives it another end and reads the relation between them each frame. The museum's player, lighting and configured XR hands remain supplied.

Work in the same unit-scale `Node3D` student station as the [Coordinates reconstruction](../../../doc/book/iterations/2026-10-05-lesson-state-chain/tutorial.md). The two complete files are printed below. Save them together as `line.gd` and `line_skin.gd`; use `line.gd` in place of the station's preceding point script. They require the XR Tools setup already provided by the working museum.

The station may move or turn, but keep its scale at one. Here one unit represents one metre. Nothing is fetched through an unnamed scene path: the script creates its points and keeps references to them.

## The complete student script — line.gd

The sphere, collision shape, material and pickup settings continue from Coordinates. The additions are the two endpoint references, a copy of the point, the visible segment and `_process()`.

<!-- student-code:line.gd -->

~~~gdscript
extends Node3D

const RADIUS := 0.14
const CENTRE := Vector3(0, 1.12, 0)

# Supplied drawing helper; the station remains in the configured museum.
const LineSkin = preload("line_skin.gd")
var point_a: XRToolsPickable
var point_b: XRToolsPickable
var line: MeshInstance3D
var distance := 0.0

func _ready() -> void:
	var radius := RADIUS
	var centre := CENTRE
	var body := MeshInstance3D.new()
	body.name = "VisiblePoint"
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 48
	sphere.rings = 24
	body.mesh = sphere
	body.material_override = material(Color(0.97, 0.97, 0.95))
	body.position = centre
	add_child(body)
	var solid := XRToolsPickable.new()
	solid.name = "PointCollision"
	solid.position = centre
	solid.freeze = true
	solid.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	solid.release_mode = XRToolsPickable.ReleaseMode.FROZEN
	solid.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	solid.collision_layer = 4
	solid.collision_mask = 196615
	var collider := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = radius
	collider.shape = sphere_shape
	solid.add_child(collider)
	add_child(solid)
	body.reparent(solid)

	point_a = solid
	point_b = solid.duplicate() as XRToolsPickable
	point_b.name = "SecondPoint"
	point_b.position = CENTRE + Vector3(1.0, 0, 0)
	add_child(point_b)
	line = LineSkin.new()
	line.name = "Segment"
	add_child(line)

func material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.32
	return mat

func _process(_delta: float) -> void:
	# Express both held positions in this station's local coordinates.
	var a := to_local(point_a.global_position)
	var b := to_local(point_b.global_position)
	var displacement := b - a
	distance = displacement.length()
	line.show_segment(a, displacement, distance)
~~~

## Read what changed

`point_a = solid` keeps the point we already made. `duplicate()` copies its body and children for B, including the visible surface and collider. The copy has its own position and can be held independently. Mesh and material resources are shared; this lesson changes positions.

The endpoint references belong to the script, so both `_ready()` and `_process()` can use them. The types after `:` say what kind of node each reference holds.

In `_process()`, `to_local` expresses both world positions in this station's frame. We can now subtract like from like. `b - a` is the displacement from A to B: initially `(1, 0, 0)`. Its `.length()` returns `1.0`. The displacement retains direction and length; the distance gives length alone.

The helper receives a start, that displacement and its length. It draws a thin cylinder between the ends. The next frame reads their positions again. Release an endpoint and it stays; the line continues to meet it.

Change B's starting offset to `Vector3(0, 1.0, 0)`. Predict what will happen. The span stands upright but keeps its length. Try `a - b` in the subtraction: the length remains, but the drawing points the other way from A. Restore `b - a`.

## The supplied drawing code — line_skin.gd

A mathematical line has no thickness. This helper gives our finite segment a surface we can see. It positions the cylinder halfway along the displacement and aligns its long axis with it. It supplies no collider or pickup behaviour.

The full helper is here so the example can be reconstructed. Its orientation calculation is supplied for now; understanding basis vectors is not a prerequisite of this lesson.

<!-- student-code:line_skin.gd -->

~~~gdscript
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
~~~

## What can two lines do?

Look at the parallel planks, the plus and the X in the hall. A second segment gives us something to arrange in relation to the first. After `add_child(line)` in `_ready()`, add:

~~~gdscript
	point_a.position = Vector3(-0.6, 1.42, 0)
	point_b.position = Vector3(0.6, 1.42, 0)
	var c := Vector3(0, 0.82, 0)
	var d := Vector3(0, 2.02, 0)
	var other_line := LineSkin.new()
	other_line.name = "OtherSegment"
	add_child(other_line)
	other_line.show_segment(c, d - c, (d - c).length())
~~~

This makes a plus. A and B are still the positions of held bodies. C and D are position values: we have given them no spheres or pickup bodies. The second segment is drawn once in `_ready()` and stays while you move the first. A position can define an end without becoming something we can grab.

Change these four assignments to try another arrangement. All values use the same station frame.

| Arrangement | A | B | C | D |
|---|---|---|---|---|
| Parallel | (-0.6, 1.12, 0) | (0.6, 1.12, 0) | (-0.6, 1.62, 0) | (0.6, 1.62, 0) |
| Plus | (-0.6, 1.42, 0) | (0.6, 1.42, 0) | (0, 0.82, 0) | (0, 2.02, 0) |
| X | (-0.6, 0.82, 0) | (0.6, 2.02, 0) | (-0.6, 2.02, 0) | (0.6, 0.82, 0) |

The first segment joins A to B; the second joins C to D. Complete versions are available for [parallel](../../../doc/book/iterations/2026-10-05-lines-relation-and-rule/student/two_lines_parallel.gd), [plus](../../../doc/book/iterations/2026-10-05-lines-relation-and-rule/student/two_lines_plus.gd) and [X](../../../doc/book/iterations/2026-10-05-lines-relation-and-rule/student/two_lines_x.gd).

Make an X. Then set the Z component of both C and D to `0.2`. Viewed straight on, the lines can still look crossed. Step sideways: they occupy different depths. The hall's plus and X use a smaller separation to make this same distinction available to your movement.

No new shared vertex is created where the drawings cross. Our code still holds four endpoints and two relations. Nor does making an X cause damage: the museum's hurt and recovery passage adds that behaviour separately.

Choose another arrangement of your own. Predict which endpoints need to move, then make it. Can you preserve each segment's length while changing what the pair suggests?

## What the line keeps

Give B the same position as A. The displacement and distance become zero. The supplied helper hides spans of `0.0001` units or less; it cannot orient a segment with no direction.

Separate the ends again. Carry B around a detour and return it to its starting place. The line returns to the same span. It has kept no journey.

Carry forward the two positions and the operation that joins them. Trace will keep more positions, in order, so that a detour can remain.
