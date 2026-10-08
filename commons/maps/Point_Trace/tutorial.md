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

Start from the working [Lines example](../Point_Lines/tutorial.md). Keep the `PointBody` class from Lines, with its mesh, collider and pickup settings, and keep the coordinate readout. Replace the second endpoint and their live segment with a list of positions and a group of drawn segments.

Save the complete continuation below as `trace.gd` beside the unchanged `point_body.gd` and `line_skin.gd`. Replace `line.gd` on your existing `PointStudy` with `trace.gd`. Keep the previous file. Work inside the existing Endless Museum Trace hall. Its room, light and XR hands remain supplied; this code creates the point, record and drawing. Keep the station's scale at `(1, 1, 1)`. Carried unchanged from [Lines](../Point_Lines/tutorial.md): `point_body.gd`, `line_skin.gd`.

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

`PointBody.new()` makes the familiar point. Its class needs no change for this lesson: the recorder reads its position.

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

The shorter loop above it visits the old segment nodes in `trail.get_children()`. `queue_free()` schedules their removal at the end of the frame. Then we draw the retained list afresh. Clearing these drawings does not erase `positions`.

`_process()` repeats over frames. The `for` loop visits entries within one update. These are different kinds of repetition.

## Change the record

Change `MIN_SEGMENT_DISTANCE` from `0.05` to `0.20`. Draw a small bend, then enlarge it. More movement is needed to add another entry; fewer corners may survive. Restore `0.05`.

For a loop experiment, change `range(1, positions.size())` to `range(1, positions.size() - 1)`. Draw again. The array and count still grow, but the last neighbouring pair is not drawn. You changed the display's traversal, not the record. Restore the original range.

Now make your own short shape and return towards its beginning. Predict the next retained entry before moving. A return can add an earlier location again at a later index: the list keeps order, not just distinct places.

## Keep the record for what comes next

Our positions belong to `PointStudy`'s local frame. Moving or turning the station carries the drawing with it. We record the point's centre whenever it moves far enough; this small recorder follows the point itself, with no separate pen-tip model.

Release the held point when you have a drawing to keep. The supplied `TraceArchive` saves the retained positions **and the segments already made from them**. Grid will place this saved drawing as a sculpture. You will not draw it again or make another sphere there.

`TraceArchive.keep_on_release(point, trail, positions)` supplies the release connection and waits for the current redraw before packing the snapshot. An intentional release keeps the drawing; removing the study or closing its scene does not replace the saved work. The archive has no timestamps. A later valid release replaces your saved drawing. Releasing before two positions exist leaves the previous file alone.

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


[Current trace.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Trace/trace.gd) · [Complete working project](../../../doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](../../../doc/book/iterations/2026-10-06-starter-one-course/index.html)
