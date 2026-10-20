# Three ways to make a crossing

## Learning elements

- Reusing the same visual class for independent instances
- A function returning the object it places
- A bounded pose fraction and interpolation
- Separating a pose from the clock that selects it

Try the three installed crossings. One carries you, one grows, one turns into alignment. The far bank gives each change a purpose. An object can reach its programmed pose and still fail to reach the bank.

## Bring the completed Pre study

Copy Pre's `lesson.gd` and `box_body.gd` into your working folder here. Keep the pickup version saved. All edits below apply to that completed copy, not the earlier movement-only checkpoint. Keep the same empty `TransformStudy` host, at floor level, with zero rotation and unit scale, in a clear space about ten metres wide.

Carried unchanged from [Pre](../Trans_Pre/tutorial.md): `box_body.gd`.

These are small visual comparisons beside the existing exhibits. They have no blocking collision. Use the installed crossings for standing and riding; their transport system is supplied by the museum.

## 1. Give the bodies separate names

Keep `extends Node3D`, the `BoxBody` preload and `var elapsed := 0.0`. Replace the variables from `var cube` through `var period` with:

<!-- student-edit:intro-values -->
```gdscript
var travel: MeshInstance3D
var grow: MeshInstance3D
var turn: MeshInstance3D
var far_banks: Array[MeshInstance3D] = []
var far_gap := 0.0
var animate := true
var pose := 0.0
var period := 8.0
```

`period` still means a full return cycle. Eight seconds gives four seconds outward and four back. `far_banks` keeps references to the three far banks; `travel`, `grow` and `turn` refer to the three moving models.

## 2. Place what the class can make

In `lesson.gd`, insert this complete `box()` function immediately before `_process()`:

<!-- student-edit:intro-box -->
```gdscript
func box(size: Vector3, at: Vector3) -> MeshInstance3D:
    var body := BoxBody.new(size)
    body.position = at
    add_child(body)
    return body
```

Construction is still in `box_body.gd`. This small function chooses dimensions and a position, attaches the instance to the study, then returns it. Returning the reference lets us change that particular body later.

Replace the complete `_ready()` function, including its collection area and signal connection, with:

<!-- student-edit:intro-ready -->
```gdscript
func _ready() -> void:
    assert(period > 0.0 and far_gap >= 0.0)
    for x in [-4.0, 0.0, 4.0]:
        box(Vector3(1.2, 0.4, 1), Vector3(x, 0.8, -1.5))
        far_banks.append(box(Vector3(1.2, 0.4, 1), Vector3(x, 0.8, 1.5 + far_gap)))
    travel = box(Vector3(1.2, 0.2, 0.8), Vector3(-4, 0.9, -1.4))
    grow = box(Vector3(1.2, 2, 2), Vector3.ZERO)
    turn = box(Vector3(2, 0.2, 0.6), Vector3(4, 0.9, 0))
    apply_pose(pose)
```

The loop makes a pair of banks in each lane: X = −4, 0 and 4. Their tops are one metre above the study's origin. The remaining calls make the three moving models. The growing cube is centred at origin height, so its lower half extends beneath the floor; this is a model of a changing span.

## 3. Make the pose inspectable

Replace `_on_body_entered()` with this complete function. No collection callback remains:

<!-- student-edit:intro-pose -->
```gdscript
func apply_pose(value: float) -> void:
    var t := clampf(value, 0.0, 1.0)
    travel.position.z = lerpf(-1.4, 1.4, t)
    grow.scale = Vector3.ONE * lerpf(0.25, 1.0, t)
    turn.rotation_degrees.y = 90.0 * t
```

`apply_pose(value)` can be called without advancing time. Zero selects the starting pose; one selects the ending pose. `clampf` keeps the fraction within those bounds. `lerpf(a, b, t)` selects a value between two numbers; at 0.5 it gives their average.

In `_process(delta)`, keep the function header and `elapsed += delta`. Replace all the lines below that statement with:

<!-- student-edit:intro-clock -->
```gdscript
    if animate:
        pose = pingpong(2.0 * elapsed / period, 1.0)
    apply_pose(pose)
```

The same clock now selects a shared pose. The earlier phase offset is gone, so the comparison begins at zero. When `animate` is false, time can pass while the chosen pose remains still.

## Hold, predict, move the bank

Set `animate = false` and try `pose = 0.0`, then `0.5`, then `1.0`. Before each run, predict the travelling surface's Z position, the cube's scale factor and the plank's angle. Halfway gives Z = 0, scale = 0.625 and 45 degrees.

At one, the first surface reaches the far bank unchanged in size. The cube reaches bank height and spans the gap by growing around its centre. The plank turns its long dimension along Z; its centre and dimensions stay fixed.

Keep that final pose and set `far_gap = 0.5`. The far banks move half a metre away. The growing cube and turned plank retain their old poses and leave a gap. Reaching a pose and reaching another object are separate conditions.

Restore `far_gap = 0.0` and `animate = true`. The three models take four seconds out and four back. Carry the unchanged visual class, the returning placement function and the distinction between input and pose toward Translation. That next lesson will need its own continuation edit; this edition repairs the handoff through Introduction.

[Complete files, edition 2026-10-16](../../../doc/book/iterations/2026-10-16-transformation-handoff/files.html#Trans_Introduction) · [lesson.gd](../../../doc/book/iterations/2026-10-16-transformation-handoff/Trans_Introduction/lesson.gd) · [unchanged box_body.gd](../../../doc/book/iterations/2026-10-16-transformation-handoff/Trans_Introduction/box_body.gd) · [Download the studies](../../../doc/book/iterations/2026-10-16-transformation-handoff/transformation-handoff.zip)

<details class="full-program">
<summary>Complete lesson.gd — online reference</summary>

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const BoxBody = preload("box_body.gd")

var travel: MeshInstance3D
var grow: MeshInstance3D
var turn: MeshInstance3D
var far_banks: Array[MeshInstance3D] = []
var far_gap := 0.0
var animate := true
var pose := 0.0
var period := 8.0
var elapsed := 0.0

func _ready() -> void:
    assert(period > 0.0 and far_gap >= 0.0)
    for x in [-4.0, 0.0, 4.0]:
        box(Vector3(1.2, 0.4, 1), Vector3(x, 0.8, -1.5))
        far_banks.append(box(Vector3(1.2, 0.4, 1), Vector3(x, 0.8, 1.5 + far_gap)))
    travel = box(Vector3(1.2, 0.2, 0.8), Vector3(-4, 0.9, -1.4))
    grow = box(Vector3(1.2, 2, 2), Vector3.ZERO)
    turn = box(Vector3(2, 0.2, 0.6), Vector3(4, 0.9, 0))
    apply_pose(pose)

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
    var body := BoxBody.new(size)
    body.position = at
    add_child(body)
    return body

func _process(delta: float) -> void:
    elapsed += delta
    if animate:
        pose = pingpong(2.0 * elapsed / period, 1.0)
    apply_pose(pose)

func apply_pose(value: float) -> void:
    var t := clampf(value, 0.0, 1.0)
    travel.position.z = lerpf(-1.4, 1.4, t)
    grow.scale = Vector3.ONE * lerpf(0.25, 1.0, t)
    turn.rotation_degrees.y = 90.0 * t
```

</details>
