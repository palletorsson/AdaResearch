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

[Download point.gd](../../../doc/book/iterations/2026-10-05-points-built-and-carried/states/001-point-one/point.gd)
