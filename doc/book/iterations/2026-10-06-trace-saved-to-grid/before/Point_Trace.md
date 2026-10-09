# Point Trace — keep where the point has been

**Learning elements**

- Reusing the point class
- Arrays of positions
- Appending and reading an index
- A distance condition with if
- Neighbour loops with for

In Lines, you could carry an endpoint around a detour and return it. The segment returned too; nothing kept the journey. Now let the point leave a trace.

The Trace hall offers pens and a ball whose movement leaves a line. Our small program follows the centre of the same pickable point we have already built. We will keep its positions in an array and reuse the line between each neighbouring pair.

## Continue the point

Start from the working [Lines example](../Point_Lines/tutorial.md). Keep the `PointBody` class from Lines, with its mesh, collider and pickup settings, and keep the coordinate readout. Replace the second endpoint and their live segment with a list of positions and a group of drawn segments.

Save the complete continuation below as `trace.gd` beside the unchanged `point_body.gd` and `line_skin.gd`. Replace `line.gd` on your existing `PointStudy` with `trace.gd`. Keep the previous file. The prepared room, light and XR hands remain supplied; this code creates the point, record and drawing. Keep the station's scale at `(1, 1, 1)`.

## The complete trace — trace.gd

<!-- student-code:trace.gd -->
```gdscript
extends Node3D

const CENTRE := Vector3(0, 1.12, 0)
const MIN_SEGMENT_DISTANCE := 0.05

const PointBody = preload("point_body.gd")

const LineSkin = preload("line_skin.gd")

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

Our positions belong to `PointStudy`'s local frame. Moving or turning the station carries the drawing with it. We record the point's centre whenever it moves far enough, including movement into a pickup pose; this small recorder has no separate pen-tip or grip-settling rule.

The museum pens add their own sampling and session-transfer behaviour. This learner script keeps its array while the station exists. It has no timestamps and saves no file; restarting the study begins again with one position. Grid will continue from this code and reuse its retained positions. That transfer is the next lesson's work.

[Download trace.gd](../../../doc/book/iterations/2026-10-05-point-a-reusable-class/trace/trace.gd) · [Download point_body.gd](../../../doc/book/iterations/2026-10-05-point-a-reusable-class/trace/point_body.gd) · [Download line_skin.gd](../../../doc/book/iterations/2026-10-05-point-a-reusable-class/trace/line_skin.gd) · [Complete experiments and tests](../../../doc/book/iterations/2026-10-05-point-a-reusable-class/index.html)
