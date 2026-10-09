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

## Bring your drawing

Continue in the **same working copy of the museum**. Keep `trace.gd` for returning to Trace. Save `grid.gd` beside `trace_archive.gd` and the unchanged `line_skin.gd`, then attach it to your unit-scale `PointStudy` on the clear floor beside Grid's glass field. The museum provides the hall, light and player. Carried unchanged from [Lines](../Point_Lines/TUTORIAL.md): `line_skin.gd`. Carried unchanged from [Trace](../Point_Trace/TUTORIAL.md): `trace_archive.gd`.

Release the point in Trace before leaving. The supplied archive stores a snapshot under `user://ada_student_trace.scn`; opening Grid loads that snapshot. Without a saved drawing, the readout asks you to return to Trace. It does not invent a replacement. Grid never writes this file.

The first copy stays pink. The two copies stand 1.6 metres apart so you can compare them; these display offsets do not change the saved positions or the grid calculation.

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

For one experiment, replace `roundi(p.y / grid_step)` with `0`. Run Grid again. Pink keeps the recorded height; green is placed on the study's Y = 0 plane. Restore the expression.

One drawing can now be a record, a sculpture and material for another calculation. Keep its original positions. Triangle can select three corners from them and ask what closes the boundary and gives it a face.


[Current grid.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Line_Grid/grid.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)

[Complete experiment: grid_flat_y.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Line_Grid/grid_flat_y.gd)
