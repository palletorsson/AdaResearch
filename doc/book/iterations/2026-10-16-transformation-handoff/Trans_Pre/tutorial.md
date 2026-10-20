# A cube that moves, turns and grows

## Learning elements

- Reusing a class; construction versus transform
- Translation, rotation and uniform scale
- Elapsed seconds and a returning fraction
- Overlap detection, signals and a player filter

In Trans_Pre, one cube rises. Another rises and turns. A third also changes size. Follow one corner: each example adds an operation to the same kind of body.

## Bring your arrangement

Save your Melencolia arrangement. Work on a copy of its `lesson.gd` in this hall; leave the original intact. The museum already supplies the room, light, camera and player. Use an empty, floor-level `Node3D` named `TransformStudy`, with zero rotation and unit scale, as the host for this copy. We replace its arrangement with one animated pickup.

There is a deliberate change of representation. `CubeBody` exposed vertices and faces. Here `BoxBody` will use Godot's `BoxMesh` to study the whole body's transform. Both describe a one-metre cube, but `CubeBody` starts at its bottom; `BoxMesh` is centred on its origin. Keep the old files with your arrangement. Their face-list construction and pickable point are not dependencies of this branch.

The coordinate frame, instance, parent-child relation and `_ready()` carry forward. Point Zero's `_process(delta)` returns as the clock. This is a new construction of a familiar shape; the museum does not transfer the same running instance between halls.

## 1. Give the visual a small class

Create `box_body.gd` beside `lesson.gd`. This is its whole file.

<!-- student-edit:box-body -->
<!-- student-code:box_body.gd -->
```gdscript
extends MeshInstance3D

func _init(size: Vector3 = Vector3.ONE) -> void:
    var shape := BoxMesh.new()
    shape.size = size
    mesh = shape
```

`BoxBody.new()` gives one visible, centred cube. The optional `size` argument gives its dimensions in metres. Each call creates its own mesh. This class adds no collider, player or movement. The next hall will carry this file unchanged.

## 2. Replace the arrangement, keep the host

In `lesson.gd`, keep `extends Node3D`. Replace the declarations between it and `func _ready()` with:

<!-- student-edit:pre-values -->
```gdscript
const BoxBody = preload("box_body.gd")

var cube := BoxBody.new()
var start := Vector3(0, 1.3, 0)
var rise := 0.35
var turn_speed := 45.0
var pulse := 0.2
var period := 4.0
var elapsed := 0.0
```

Replace the complete `_ready()` function with this one. There is still only one `_ready()`:

<!-- student-edit:pre-ready -->
```gdscript
func _ready() -> void:
    assert(period > 0.0 and pulse >= 0.0 and pulse < 1.0)
    add_child(cube)
    cube.position = start
```

Append `_process()` after `_ready()`:

<!-- student-edit:pre-clock -->
```gdscript
func _process(delta: float) -> void:
    elapsed += delta
    var t := pingpong(2.0 * elapsed / period + 0.5, 1.0)
    cube.position = start + Vector3.UP * lerpf(-rise, rise, t)
    cube.rotation_degrees.y = turn_speed * elapsed
    cube.scale = Vector3.ONE * lerpf(1.0 - pulse, 1.0 + pulse, t)
```

The cube now rises, turns and pulses. `elapsed += delta` keeps seconds between updates. `pingpong` makes a fraction travel from zero to one and back. `period` is **one complete return cycle**, in seconds. The `0.5` offset starts the cube halfway up, moving upward.

`lerpf(-rise, rise, t)` chooses a height offset. At `t = 0.5`, that offset is zero. Multiplying `Vector3.ONE` by the second interpolation scales all axes equally. The turn uses elapsed seconds directly: 45 degrees per second, independent of `period`.

Each update assigns the pose from the starting values. Repeatedly adding the whole pose would make it drift. The assertion prevents a zero period and a pulse that collapses or inverts the cube.

Set `turn_speed` and `pulse` to `0.0`: only the rise remains. Restore `turn_speed = 45.0`, then `pulse = 0.2`. The same mesh acquires another behaviour at each step. With `period = 4.0`, the height is 1.3 m initially, 1.65 m after one second, 0.95 m after three, and 1.3 m after four. The change reverses immediately at each end; easing would be another timing choice.

## 3. Let an overlap collect it

Inside `_ready()`, immediately after `cube.position = start`, insert these lines at the same indentation:

<!-- student-edit:pre-sensor -->
```gdscript
    var sensor := Area3D.new()
    sensor.collision_layer = 0
    sensor.collision_mask = 1
    sensor.set_collision_mask_value(20, true)
    cube.add_child(sensor)
    var hitbox := CollisionShape3D.new()
    hitbox.shape = BoxShape3D.new()
    sensor.add_child(hitbox)
    sensor.body_entered.connect(_on_body_entered)
```

Append this function after `_process()`. It is the receiver connected above:

<!-- student-edit:pre-collect -->
```gdscript
func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("em_walker") or body.is_in_group("player_body"):
        print("Collected")
        queue_free()
```

An `Area3D` reports overlap; it does not block a body. Its one-metre `BoxShape3D` matches the unscaled visual. As a child of the cube, the area follows its movement, rotation and uniform scale. `body_entered.connect(...)` connects the event to our receiver.

The museum supplies `player_body` on collision layer 20. The prepared desktop preview uses `em_walker` on layer 1. The mask admits those layers; the group condition identifies the player. A prop is ignored. A qualifying overlap prints `Collected`, then `queue_free()` removes this study at the end of the frame. Score and celebration effects remain with the installed exhibit.

## Predict, change, carry

Change only `period` to `8.0`. Rise and pulse should take twice as long; turning should retain its speed. Explain why, then choose another rise without changing the cube's proportions.

Keep a saved copy of this collectible version for Arrays. Introduction branches from it: the visual class and clock continue, while the collection code is removed so the comparison stays visible.

[Complete files, edition 2026-10-16](../../../doc/book/iterations/2026-10-16-transformation-handoff/files.html#Trans_Pre) · [lesson.gd](../../../doc/book/iterations/2026-10-16-transformation-handoff/Trans_Pre/lesson.gd) · [box_body.gd](../../../doc/book/iterations/2026-10-16-transformation-handoff/Trans_Pre/box_body.gd) · [Download the studies](../../../doc/book/iterations/2026-10-16-transformation-handoff/transformation-handoff.zip)

<details class="full-program">
<summary>Complete lesson.gd — online reference</summary>

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const BoxBody = preload("box_body.gd")

var cube := BoxBody.new()
var start := Vector3(0, 1.3, 0)
var rise := 0.35
var turn_speed := 45.0
var pulse := 0.2
var period := 4.0
var elapsed := 0.0

func _ready() -> void:
    assert(period > 0.0 and pulse >= 0.0 and pulse < 1.0)
    add_child(cube)
    cube.position = start

    var sensor := Area3D.new()
    sensor.collision_layer = 0
    sensor.collision_mask = 1
    sensor.set_collision_mask_value(20, true)
    cube.add_child(sensor)
    var hitbox := CollisionShape3D.new()
    hitbox.shape = BoxShape3D.new()
    sensor.add_child(hitbox)
    sensor.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
    elapsed += delta
    var t := pingpong(2.0 * elapsed / period + 0.5, 1.0)
    cube.position = start + Vector3.UP * lerpf(-rise, rise, t)
    cube.rotation_degrees.y = turn_speed * elapsed
    cube.scale = Vector3.ONE * lerpf(1.0 - pulse, 1.0 + pulse, t)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("em_walker") or body.is_in_group("player_body"):
        print("Collected")
        queue_free()
```

</details>
