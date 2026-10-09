# Point Grid — place the drawing you made

**Learning elements**

- Loading your saved trace
- Reusing a drawing as a sculpture
- Source positions and grid addresses
- Integer coordinates and rounding
- Changing a copy while keeping the original

We are in the Endless Museum. In Trace, you moved the held point and released it to save the drawing. Here, place that drawing beside the ruled field. The gesture has become something you can walk around.

The pink sculpture is your saved work: the same retained positions and the same segment geometry. We do not build another point or ask for another gesture. Its data gives us a second question: what changes when those positions receive grid addresses?

## Bring your drawing

Continue in the **same working copy of the museum**. Keep `trace.gd` for returning to Trace. Save `grid.gd` beside `trace_archive.gd` and the unchanged `line_skin.gd`, then attach it to your unit-scale `PointStudy` on the clear floor beside Grid's glass field. The museum provides the hall, light and player.

Release the point in Trace before leaving. The supplied archive stores a snapshot under `user://ada_student_trace.scn`; opening Grid loads that snapshot. Without a saved drawing, the readout asks you to return to Trace. It does not invent a replacement. Grid never writes this file.

The first copy stays pink. A second copy receives its own mesh and material resources before any changes. We reuse the segment renderer from Lines to place those copied segments between rounded positions. The original sculpture keeps the hand's recorded form.

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
    for i in grid_copy.get_child_count():
        var segment := grid_copy.get_child(i)
        var original := sculpture.get_child(i)
        segment.set_script(LineSkin)
        segment.mesh = original.mesh.duplicate()
        segment.material_override = original.material_override.duplicate()
        segment.material_override.albedo_color = Color(0.25, 0.85, 0.60)
    _place_on_grid()

func _process(_delta: float) -> void:
    if grid_copy != null and Input.is_action_just_pressed("ui_accept"):
        grid_step = 0.50 if grid_step == 0.25 else 0.25
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

On desktop, press Enter or Space to compare 0.25 and 0.50 metre spacing. In your code, changing the initial `grid_step` gives the same comparison when you return in VR. Input mapping is supplied here, not the new subject. Both versions load the same saved sculpture; you do not repeat the gesture.

Before switching, choose a corner and predict its new address. Find two visits that acquire the same address. Switch back: the finer interpretation returns because the original data was kept, not because coarse rounding can be reversed.

For one experiment, replace `roundi(p.y / grid_step)` with `0`. Run Grid again. Pink keeps the recorded height; green is placed on the study's Y = 0 plane. Restore the expression. The download includes this tested version.

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

[Download the complete lesson](../../../doc/book/iterations/2026-10-06-trace-saved-to-grid/grid-files.zip) · [Museum handoff and tests](../../../doc/book/iterations/2026-10-06-trace-saved-to-grid/index.html)
