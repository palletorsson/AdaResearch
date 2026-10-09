# Give the turn a centre

**Learning elements**

- Axis, angle and pivot
- Degrees and radians
- A child offset from a rotating parent
- A face mark that makes orientation visible

A quarter-turn can restore a cube's square outline without returning the same face. Follow the mark on the installed cube. Then watch the end of a turning blade: a fixed centre does not mean the whole body stays in one place.

Keep the box construction and elapsed clock. Remove the translation route. Put the cube under a new `pivot`, and make the pivot turn. The small dark mark belongs to the cube so it follows the same transform.

## The complete study

Attach `lesson.gd` to an empty, unrotated, unit-scale `TransformStudy` on clear museum floor. Leave room around it for a two-metre offset. The museum supplies the room and viewer; this script creates the pivot, cube and mark.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

var pivot := Node3D.new()
var cube := MeshInstance3D.new()
var mark := MeshInstance3D.new()
var axis := Vector3.UP
var offset := Vector3.ZERO
var speed := 45.0
var elapsed := 0.0

func _ready() -> void:
    assert(axis.length() > 0.0)
    add_child(pivot)
    pivot.position = Vector3(0, 1.2, 0)
    cube.mesh = BoxMesh.new()
    pivot.add_child(cube)
    cube.position = offset

    var mark_mesh := BoxMesh.new()
    mark_mesh.size = Vector3(0.3, 0.12, 0.02)
    mark.mesh = mark_mesh
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.06, 0.06, 0.06)
    mark.material_override = ink
    cube.add_child(mark)
    mark.position = Vector3(0.18, 0.2, 0.51)

func _process(delta: float) -> void:
    elapsed += delta
    var angle := deg_to_rad(speed * elapsed)
    pivot.basis = Basis(axis.normalized(), angle)
```

`axis` chooses the direction of the rotation axis in the study's frame. `Vector3.UP` means Y. `normalized()` keeps that direction and gives it length one. `Basis(axis, angle)` constructs the orientation for a turn about that axis. It expects radians, so `deg_to_rad` converts the degrees produced by `speed * elapsed`.

At 45 degrees per second, two seconds gives a quarter-turn and eight gives a full turn. We assign the orientation from elapsed time, rather than repeatedly adding the accumulated angle.

## Move the cube away from the pivot

With `offset = Vector3.ZERO`, the pivot passes through the cube's centre. Its centre stays fixed while its corners move.

Change `offset` to `Vector3(2, 0, 0)`. The cube remains two metres along the pivot's **local** X axis. As the parent turns, that local direction turns in the museum. The cube's centre now travels around the pivot while its orientation turns with it. The mark remains attached to the same face.

The child's local position has stayed fixed; its world position has changed. This returns to Coordinates with a moving reference frame. Internal distances stay the same in both examples, but the offset version needs more surrounding space.

## Choose the axis

Keep the two-metre offset and change `axis` to `Vector3.FORWARD`. In Godot this is negative Z. The centre now follows a vertical circle instead of a horizontal one. At two seconds, predict which side of the pivot it reaches. Part of the circle goes below the floor; raise the study if you want to see the complete orbit.

The museum's standing platforms use an additional rule to keep their riders upright. Our cube turns with its parent; it is not a rider mechanism. Reversing two rotations is another comparison in the hall, beyond this lesson's single axis.

Carry the pivot with you. In Scale, the location of the origin will also decide which part of a change stays put.
