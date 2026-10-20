# Give the carried body a centre

## Learning elements

- Axis, angle and pivot
- Degrees converted to radians
- A fixed local offset under a rotating parent
- A face mark that makes orientation visible

Follow the end of a blade in the Rotation hall. Its middle stays put while its end crosses the gap. Then follow the mark on the small turning cube: an outline can return before the mark does.

## Bring the body and its clock

Start with a copy of Translation's completed `lesson.gd` and `box_body.gd`, edition 2026-10-16. Keep `BoxBody`, `var travel`, `var elapsed`, the whole `box(size, at)` function and the whole `_process(delta)` function. The box keeps its dimensions: 1.2 metres by 0.2 by 0.8. The new relation is a rotating parent.

Carried unchanged from [Translation](../Trans_Translation/tutorial.md): `box_body.gd`, the class that constructs the visual.

Use the same empty, floor-level `TransformStudy` in the prepared museum, with zero rotation and unit scale. The museum supplies the light and viewer. These are visual bodies; the installed rides supply collision and rider support. Keep your Translation folder so its journeys remain available.

## 1. Give the body a pivot

In `lesson.gd`, replace the declarations from `var start` through `var via_corner` with:

<!-- student-edit:pivot-values -->
```gdscript
var pivot := Node3D.new()
var axis := Vector3.UP
var offset := Vector3.ZERO
var duration := 8.0
```

`pivot` is a new coordinate frame. Its Y axis will be the axis of the turn. `offset` will place the body relative to that frame. `duration` now means seconds per full turn, replacing Translation's time to reach one destination.

Replace `_ready()` with this complete function. Keep `box()` unchanged:

<!-- student-edit:parent-the-body -->
```gdscript
func _ready() -> void:
    assert(duration > 0.0 and axis.length() > 0.0)
    add_child(pivot)
    pivot.position = Vector3(0, 1.2, 0)
    travel = box(Vector3(1.2, 0.2, 0.8), offset)
    travel.reparent(pivot, false)
    apply_pose(0.0)
```

`box()` still creates a visual as a child of the study. `reparent(pivot, false)` moves that child beneath the pivot while retaining its **local** transform. The `false` matters: the default keeps the world transform instead. Here we want the supplied `offset` to be interpreted in the new parent's frame. With zero offset, the body's centre is at the pivot, 1.2 metres above the study's origin.

The hierarchy is now `TransformStudy → pivot → travel`. Both nodes exist before `apply_pose()` uses them.

## 2. Turn the frame

Keep `_process(delta)` exactly as Translation left it. It already adds `delta` to `elapsed` and passes `elapsed / duration` to `apply_pose()`.

Replace the complete `apply_pose(value)` function, including its clamp and route branches, with:

<!-- student-edit:turn-the-frame -->
```gdscript
func apply_pose(value: float) -> void:
    var angle := deg_to_rad(360.0 * value)
    pivot.basis = Basis(axis.normalized(), angle)
```

Run this checkpoint. At two seconds, `value` is 0.25: a quarter of the eight-second turn, or 90 degrees. Godot's `Basis(axis, angle)` expects radians. `deg_to_rad()` converts 90 degrees to π/2; `axis.normalized()` gives the axis a length of one. Assigning the basis sets the pivot's orientation from that angle.

We removed the clamp because this turn continues. At eight seconds the body returns to its initial pose. At ten it has completed another quarter-turn. The clock supplies an absolute angle; we set that orientation rather than add the whole accumulated angle on every frame.

The centre stays still. The corners move. A rotation changes their direction from the centre while preserving their distances from it and from each other.

## 3. Keep sight of one face

In `_ready()`, insert these lines immediately before `apply_pose(0.0)`. Keep that existing call:

<!-- student-edit:attach-the-mark -->
```gdscript
    var mark := box(Vector3(0.3, 0.02, 0.18), Vector3(0.35, 0.11, 0.2))
    mark.reparent(travel, false)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.06, 0.06, 0.06)
    mark.material_override = ink
```

The mark is another small `BoxBody`, placed just above the top face. It becomes a child of `travel`, so its coordinates belong to that body. The material makes it dark enough to follow; material design is a later lesson. Only the pivot needs an orientation update. The body and mark inherit it.

Run again. Our rectangular body has the same outline after a half-turn, at four seconds. The off-centre mark is on the other side. At eight seconds both return. The hall's cube has more rotational symmetry: its outline can return after a quarter-turn. What counts as a return depends on what you follow.

## Move the centre through space

Change the existing `offset` declaration to `var offset := Vector3(2, 0, 0)`. Predict the body's position after two seconds, then run. Its local position stays `(2, 0, 0)` throughout. Its parent turns that direction in the study, so its centre now travels in a circle of radius two.

After the quarter-turn about positive Y, the body's centre is at `(0, 1.2, -2)` in the study's frame. Its top still faces up, but its long edge has turned. The face mark stays attached. Moving the study elsewhere in the museum changes world coordinates without changing this local relation.

Keep the two-metre offset and change `axis` to `Vector3.FORWARD`, Godot's negative Z direction. Predict the quarter-turn. The centre now reaches `(0, -0.8, 0)`: below the study's origin. Raise the study two metres to see the entire vertical circle above the floor. The installed platforms use an additional rule to keep riders upright; this body turns with its parent.

Finally change `duration` to `16.0`. Where will the body be after four seconds? Explain which values change the orbit's size, its plane and its timing. The complete versions of these three experiments are linked below.

Carry the pivot, body and mark onward. Scale will reuse the fact that changing a parent reaches its children, and that the origin determines what stays in place. Combining rotations around different axes remains another encounter in the hall; this lesson gives one turn a clear centre first.

[Complete files, edition 2026-10-16](../../../doc/book/iterations/2026-10-16-rotation-carried-body/files.html#complete) · [lesson.gd](../../../doc/book/iterations/2026-10-16-rotation-carried-body/complete/lesson.gd) · [unchanged box_body.gd](../../../doc/book/iterations/2026-10-16-rotation-carried-body/complete/box_body.gd) · [Download files and variants](../../../doc/book/iterations/2026-10-16-rotation-carried-body/rotation-studies.zip)

<details class="full-program">
<summary>Complete lesson.gd — online reference</summary>

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const BoxBody = preload("box_body.gd")

var travel: MeshInstance3D
var pivot := Node3D.new()
var axis := Vector3.UP
var offset := Vector3.ZERO
var duration := 8.0
var elapsed := 0.0

func _ready() -> void:
    assert(duration > 0.0 and axis.length() > 0.0)
    add_child(pivot)
    pivot.position = Vector3(0, 1.2, 0)
    travel = box(Vector3(1.2, 0.2, 0.8), offset)
    travel.reparent(pivot, false)
    var mark := box(Vector3(0.3, 0.02, 0.18), Vector3(0.35, 0.11, 0.2))
    mark.reparent(travel, false)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.06, 0.06, 0.06)
    mark.material_override = ink
    apply_pose(0.0)

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
    var body := BoxBody.new(size)
    body.position = at
    add_child(body)
    return body

func _process(delta: float) -> void:
    elapsed += delta
    apply_pose(elapsed / duration)

func apply_pose(value: float) -> void:
    var angle := deg_to_rad(360.0 * value)
    pivot.basis = Basis(axis.normalized(), angle)
```

</details>
