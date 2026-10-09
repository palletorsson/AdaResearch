# The relation between two points

**Learning elements**

- Displacement
- Magnitude
- Zero and normalization
- Vector addition
- Signed projection

Take the two familiar points. Move one, then move both by the same amount. The cylinder follows the gap. Its length changes only when their relation changes. In the other stations, two moves become one arrival, and a rail keeps one component of a movement.

## Continue the object

Keep the point class from Lines. This small study returns to two endpoints before adding a force. First read the displacement and its length. Then read direction. Finally inspect the X projection and the remainder in `relation()`; together they reconstruct the same displacement.

Keep `point_body.gd`, `free_point.gd` and `study.gd` together in your Forces study folder. Their complete source and the supplied museum boundary are in [Shared code](../../../doc/book/course/forces-shared-code.md). `PointBody` is the unchanged Lines class; `study.gd` only supplies captions, buttons and cylinder drawing. It contains no force rule.

Save the following as `01_vectors.gd` and attach it to your existing `PointStudy` Node3D inside this museum hall. Replace the previous lesson script; keep its file. Use a clear working bay with floor-level origin and unit scale, away from other experiments. The museum supplies the room, floor, lights, camera and XR hands. Restart the study between matched trials. This reconstructs the selected operation, not every object in the hall.

## Complete continuation — 01_vectors.gd

<!-- student-code:01_vectors.gd -->

```gdscript
extends "study.gd"
var a = Point.new()
var b = Point.new()
var segment: MeshInstance3D
var reading: Label3D

func _ready() -> void:
    add_child(a)
    add_child(b)
    for point in [a, b]:
        point.freeze = true
        point.release_mode = XRToolsPickable.ReleaseMode.FROZEN
    a.position = Vector3(-0.5, 1.2, 0)
    b.position = Vector3(0.5, 1.5, 0)
    segment = rod()
    reading = caption("")

func relation() -> Dictionary:
    var displacement: Vector3 = b.position - a.position
    var length := displacement.length()
    var direction := Vector3.ZERO
    if length > 0.0001:
        direction = displacement / length
    var along_x := Vector3.RIGHT * displacement.dot(Vector3.RIGHT)
    return {"displacement": displacement, "length": length,
        "direction": direction, "along_x": along_x,
        "remainder": displacement - along_x}

func _process(_delta: float) -> void:
    var r := relation()
    join(segment, a.position, b.position)
    reading.text = "gap %s m\nlength %.2f m\ndirection %s" % [
        r.displacement, r.length, r.direction]
```

## Read what changes

`b.position - a.position` uses the study’s local frame. Dividing by length keeps direction while giving it unit length. The condition avoids inventing a direction at zero. `dot(Vector3.RIGHT)` keeps a signed X component: a negative result points left. Adding `along_x` and `remainder` returns the original vector. In the addition station, the same addition joins two chosen displacements. None of these arrows pushes a body.

## Try another beginning

Place the endpoints three metres apart along X and four along Y. Predict a five-metre gap. Translate both together; the result should stay unchanged. Then bring them together: the cylinder disappears and direction becomes zero.

## Carry onward

A displacement can begin elsewhere. In Launch, a vector will acquire units of metres per second and become an initial velocity.

[Reflection](final.md) asks what this encounter permits and leaves out. It need not explain all this code. The archived earlier tutorial remains in the dated [before record](../../../doc/book/iterations/2026-10-08-forces-one-body-through-the-halls/before/commons/maps/Vectors_Act1_WhatAVectorIs/tutorial.md).
