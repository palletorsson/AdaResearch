# The relation between two points

**Learning elements**

- Displacement
- Length and direction
- Zero length
- Addition and projection

Take the two familiar points. Move one and watch the cylinder between them. Then move both by the same amount. Their addresses change; the gap between them stays the same.

## Make the small study

Continue the point class from Lines. Make two points report their separation as a vector, a length and a direction. Begin with those three readings; return to the projection after they make sense.

**The hall adds:** The hall adds two stations: joining movements by addition, and keeping the part of a movement along a rail.

Save `01_vectors.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](shared-code.md).

## Complete code — 01_vectors.gd

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

## Read the change

`b.position - a.position` gives the movement from a to b in the study’s local coordinates. Its three components tell us how far to move along each axis. `length()` measures the whole gap.

Divide that displacement by its length to keep only direction. The result has length one. When the points meet, the `if` leaves direction at zero: there is no direction to recover from a zero-length gap.

Read the projection last. `dot(Vector3.RIGHT)` takes the signed X component. Multiplying it by `Vector3.RIGHT` makes a vector along X; subtracting it from the full displacement leaves the remainder. Add the two parts and you get the original displacement back. This is another use of vector addition.

## Change one thing

Place the endpoints three metres apart along X and four along Y. Predict a five-metre gap, then check it. Move both together and check again. Finally bring them together: the cylinder disappears and the direction reads zero.

To inspect the projection, temporarily display `r.along_x` and `r.remainder` in the caption. The complete example already calculates both; its first readout shows only gap, length and direction.

## Model notes

The cylinder draws a relation. It applies no force. These positions share the PointStudy frame, so subtracting them is meaningful.

## Into the next room

Keep the distinction between a position and a displacement. In Launch, a vector describes how much position changes each second.

[Reflective text](file:///C:/Users/palle/Documents/GitHub/AdaResearch_46/commons/maps/Vectors_Act1_WhatAVectorIs/final.md).
