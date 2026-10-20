# Let your approach choose the size

## Learning elements

- The existing viewpoint as an input
- World positions and horizontal separation
- Mapping metres to a bounded fraction
- Using that fraction to choose a scale
- A reversible response without a stored path

Approach the slat wall, then step back. It opens and returns. Farther on, blocks shrink around you and recover when you leave. Your position supplies the changing value.

Keep the doorway and black sphere you made in Scale. This time the opening grows as you approach. Shrinking a block can make space between blocks; enlarging our frame makes space inside it. We carry the distance-to-size relation into the object we already have.

## Bring the completed Scale files

Copy `lesson.gd`, `box_body.gd` and `study.tscn` from Scale, edition 2026-10-16. Keep that folder as a checkpoint. [BoxBody and the complete incoming files](../../../doc/book/iterations/2026-10-16-scale-carried-frame/files.html#complete) remain available online.

Keep `BoxBody`, `box()`, `apply_pose()`, the three doorway parts, their parent and the sphere. Leave `var factors := Vector3.ONE` in place: it supplies the starting size. We add an input and two functions; we do not rebuild the objects.

Place this study on clear floor in the existing Endless Museum, under a host with unit scale and no tilt. Its origin is the threshold. Translation and a turn around Y are allowed. The museum supplies the room, light and active walking or XR camera, in the same viewport as the study. Start about five metres from the threshold. These lesson meshes remain visual: they have no collision, pickup or automatic passage test.

Apply all three edits before running.

## 1. Choose the reach

In `lesson.gd`, insert these declarations immediately before `var factors := Vector3.ONE`. Keep that existing declaration:

<!-- student-edit:approach-values -->
```gdscript
var near_distance := 1.0
var far_distance := 4.0
var largest := 4.0
```

The distances are metres from the threshold, measured across the floor. At the far limit the frame has its original size. At the near limit it reaches `largest` times that size. `largest` is a scale factor, not a distance.

Inside the existing `_ready()`, insert these two indented lines immediately before `add_child(pivot)`. Keep the rest of `_ready()`:

<!-- student-edit:check-range -->
```gdscript
    assert(far_distance > near_distance and near_distance >= 0.0)
    assert(largest >= 1.0)
```

The first assertion prevents a zero or reversed range; the second keeps this study an enlargement. Assertions expose a mistaken setting during development. They do not replace checking input in a released application.

## 2. Read the viewpoint, choose the factor

Insert these two complete functions immediately before `func box(...)`. Keep `box()` and `apply_pose()` unchanged:

<!-- student-edit:read-and-respond -->
```gdscript
func _process(_delta: float) -> void:
    var visitor := get_viewport().get_camera_3d()
    if visitor == null:
        return
    var separation := visitor.global_position - pivot.global_position
    separation.y = 0.0
    respond(separation.length())

func respond(distance: float) -> void:
    var fraction := clampf((distance - near_distance) / (far_distance - near_distance), 0.0, 1.0)
    var factor := lerpf(largest, 1.0, fraction)
    apply_pose(Vector3.ONE * factor)

```

`get_camera_3d()` returns the active camera for this viewport. The camera already exists; this line refers to it. We read it again each frame, so a replacement camera can take over. If there is none yet, `return` leaves the last pose alone. A camera arriving later starts the response.

This choice measures your **viewpoint**, not your collision body. In XR it follows the tracked head; in desktop walking it follows the walking camera. A spectator camera would become the input instead. The installed exhibits identify bodies and handle collision; that wider machinery is not required to learn this relation.

Both positions are world positions. Their difference works even when the study and camera have different parents. Setting Y to zero projects the separation onto the horizontal plane. Moving the head straight up or down therefore leaves the factor unchanged. Leaning sideways can change it. `length()` then gives the distance in metres.

Subtract the near distance, divide by the range, then clamp to zero through one. The table makes that conversion visible:

| Horizontal distance | Bounded fraction | Scale factor | Clear opening: width × height |
|---|---|---|---|
| 4 m or farther | 1 | 1 | 0.45 × 0.60 m |
| 2.5 m | 0.5 | 2.5 | 1.125 × 1.50 m |
| 1 m or nearer | 0 | 4 | 1.80 × 2.40 m |

`lerpf(largest, 1.0, fraction)` chooses between the two factors. It is the same interpolation operation used for a route, now applied to size. Clamping matters: walking inside the near limit must not keep enlarging the frame, and walking beyond the far limit must not make it disappear or invert.

The existing `apply_pose(Vector3)` scales the parent. Its children keep their local data, the posts stay on the floor and the sphere stays outside the change. No new mesh is created during `_process()`.

## Approach, pause, return

Walk closer, stop, then walk away. At the same distance the frame has the same size. `_delta` is unused because we calculate a pose from the current position; we are not adding motion over time. Waiting does not accumulate more scale.

The response uses a distance around the threshold, so it also works from the sides and behind. It does not know which way you face. Compare that choice with the slat wall's directional response. Compare its return with the retained cut in the lattice: leaving our study restores a size; leaving the lattice does not restore its missing cells.

## Change one decision

Set `var far_distance := 6.0`. Predict where the change starts and where it reaches half its range. The answers are six metres and 3.5 metres; the midpoint factor is still 2.5. The near limit stays at one metre.

Return to four metres. In `respond()`, replace `apply_pose(Vector3.ONE * factor)` with `apply_pose(Vector3(factor, 1.0, 1.0))`. The near opening becomes 1.80 metres wide but remains 0.60 metres high. Explain why getting closer still cannot make it tall enough for the fixed sphere.

Restore the uniform call. Replace `var factor := lerpf(largest, 1.0, fraction)` with `var factor := lerpf(1.0, largest, fraction)`. Now approaching makes the opening smaller. The distance measurement is unchanged; reversing the output endpoints reverses its invitation. All three exercise versions have complete files online.

Choose another far limit and predict its midpoint before running. Can you explain separately what sets the reach, what sets the largest size, and which objects receive the change?

Carry the frame, constructor and distance-to-factor relation into the next hall. There we will combine operations and add a controlled transition over time. Our immediate visual response is one selected principle of this hall, not a reconstruction of all three installed thresholds.

[Complete files, edition 2026-10-17](../../../doc/book/iterations/2026-10-17-body-carried-opening/files.html#complete) · [Download files and variants](../../../doc/book/iterations/2026-10-17-body-carried-opening/body-studies.zip)

[Godot 4.6: active viewport camera](https://docs.godotengine.org/en/4.6/classes/class_viewport.html#class-viewport-method-get-camera-3d) · [Scalar interpolation](https://docs.godotengine.org/en/4.6/classes/class_@globalscope.html#class-globalscope-method-lerpf)

<details class="full-program">
<summary>Complete lesson.gd — online reference</summary>

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const BoxBody = preload("box_body.gd")

var pivot := Node3D.new()
var point := MeshInstance3D.new()
var near_distance := 1.0
var far_distance := 4.0
var largest := 4.0
var factors := Vector3.ONE

func _ready() -> void:
    assert(far_distance > near_distance and near_distance >= 0.0)
    assert(largest >= 1.0)
    add_child(pivot)
    for at in [Vector3(-0.285, 0.3, 0), Vector3(0.285, 0.3, 0)]:
        var post := box(Vector3(0.12, 0.6, 0.2), at)
        post.reparent(pivot, false)
    var lintel := box(Vector3(0.69, 0.12, 0.2), Vector3(0, 0.66, 0))
    lintel.reparent(pivot, false)
    var sphere := SphereMesh.new()
    sphere.radius = 0.325
    sphere.height = 0.65
    point.mesh = sphere
    add_child(point)
    point.position = Vector3(1.8, 0.325, 0)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.06, 0.06, 0.06)
    point.material_override = ink
    apply_pose(factors)

func _process(_delta: float) -> void:
    var visitor := get_viewport().get_camera_3d()
    if visitor == null:
        return
    var separation := visitor.global_position - pivot.global_position
    separation.y = 0.0
    respond(separation.length())

func respond(distance: float) -> void:
    var fraction := clampf((distance - near_distance) / (far_distance - near_distance), 0.0, 1.0)
    var factor := lerpf(largest, 1.0, fraction)
    apply_pose(Vector3.ONE * factor)

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
    var body := BoxBody.new(size)
    body.position = at
    add_child(body)
    return body


func apply_pose(value: Vector3) -> void:
    assert(value.x > 0.0 and value.y > 0.0 and value.z > 0.0)
    pivot.scale = value
```

</details>
