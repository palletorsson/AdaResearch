# Three ways to make a crossing

**Learning elements**

- Translation, rotation and scale as different ways to reach
- A bounded fraction controlling a transform
- Interpolation between two values
- A returning function for repeated construction

Try the three installed crossings. One carries you, one grows, one turns into alignment. The far bank gives each change a purpose. A correctly moving object can still fail to reach it.

Keep the `MeshInstance3D` and `BoxMesh` construction from Trans_Pre. Remove its collection area: these examples need to remain for comparison. Make three small studies beside the real crossings. Their geometry is visible but has no blocking collision; use the installed crossings for standing and riding. The museum's rider transport is supplied, not reconstructed here.

## Make the comparison

Attach this complete `lesson.gd` to an empty, unrotated, unit-scale `TransformStudy` in a clear area about ten metres wide. Its origin is at floor level. The three lanes run along local Z, at X = −4, 0 and 4. Their bank tops are one metre above the origin. The centre of the growing cube stays at the origin height; part of its volume extends below the floor.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

var travel: MeshInstance3D
var grow: MeshInstance3D
var turn: MeshInstance3D
var far_banks: Array[MeshInstance3D] = []
var far_gap := 0.0
var animate := true
var pose := 0.0
var duration := 4.0
var elapsed := 0.0

func _ready() -> void:
    assert(duration > 0.0 and far_gap >= 0.0)
    for x in [-4.0, 0.0, 4.0]:
        box(Vector3(1.2, 0.4, 1), Vector3(x, 0.8, -1.5))
        far_banks.append(box(Vector3(1.2, 0.4, 1), Vector3(x, 0.8, 1.5 + far_gap)))
    travel = box(Vector3(1.2, 0.2, 0.8), Vector3(-4, 0.9, -1.4))
    grow = box(Vector3(1.2, 2, 2), Vector3.ZERO)
    turn = box(Vector3(2, 0.2, 0.6), Vector3(4, 0.9, 0))
    apply_pose(pose)

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    body.mesh = mesh
    body.position = at
    add_child(body)
    return body

func _process(delta: float) -> void:
    elapsed += delta
    if animate:
        pose = pingpong(elapsed / duration, 1.0)
    apply_pose(pose)

func apply_pose(value: float) -> void:
    var t := clampf(value, 0.0, 1.0)
    travel.position.z = lerpf(-1.4, 1.4, t)
    grow.scale = Vector3.ONE * lerpf(0.25, 1.0, t)
    turn.rotation_degrees.y = 90.0 * t
```

The `box` function repeats the construction you already know. Its two arguments choose dimensions and position. It returns the new instance so `travel`, `grow` and `turn` can refer to different bodies. The loop places the same pair of banks in each lane.

`apply_pose` gives the three operations the same fraction, `t`. Zero selects their first pose; one selects their last. `clampf` keeps the fraction within those bounds. `lerpf(a, b, t)` chooses a value between `a` and `b`: halfway gives their average.

## Hold the two ends

Set `animate` to `false` and `pose` to `0.0`. The travelling surface waits at the near bank. The small cube does not reach the bank tops. The long plank lies across X, away from the route.

Change `pose` to `1.0`. The first surface reaches the far bank without changing size or orientation. The cube has grown around its fixed centre: its top reaches bank height and its Z edges meet the banks. The plank has turned 90 degrees around Y, putting its long dimension along Z. Its centre and dimensions stay fixed.

One operation moves a surface between banks. The others make a span. They solve different spatial problems using the same three properties from Trans_Pre.

## Follow the intervening poses

Restore `animate` to `true`. `pingpong` moves the fraction from zero to one, then back. With `duration = 4.0`, each outward journey takes four seconds; the full return takes eight. This timing turns immediately at its endpoints. The installed crossings also have pauses and rider support.

## Move the place it must reach

For a held comparison, set `animate` to `false`, `pose` to `1.0` and `far_gap` to `0.5`. The far banks move half a metre farther along Z. The growing cube and turned plank keep their previous end poses. Each now leaves half a metre unbridged.

Return `far_gap` to zero and choose `pose = 0.5`. Predict the travelling surface's position, the cube's size and the plank's angle before running it. Carry the distinction between changing an object and changing the relation it must satisfy.
