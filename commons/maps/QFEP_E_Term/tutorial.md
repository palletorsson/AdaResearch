# E Term

E(S) is the size of the possibility space. Build a room where freedom is felt as cubes refusing to stay still.

Declare the entropy meter.

```gdscript
class_name EMeter
extends Node3D

@export var sample_count: int = 256
var positions: PackedVector3Array = PackedVector3Array()

func entropy() -> float:
    return _spread(positions)
```

The meter holds recent positions and computes their spread. Spread is the entropy proxy; more spread means more possibility.

Spawn a cloud of random cubes.

```gdscript
func spawn_random() -> void:
    for i in sample_count:
        var cube := preload("res://commons/artifacts/qfep/entropy_cube.tscn").instantiate()
        cube.position = _sample_in_box()
        add_child(cube)
        positions.append(cube.position)
```

Each cube is placed inside the room's volume by rejection sampling. No two cubes share a target. The room begins in high entropy.

Kick every cube randomly per frame.

```gdscript
func _physics_process(_dt: float) -> void:
    for cube in cubes:
        cube.linear_velocity += Vector3(
            randf_range(-1.0, 1.0),
            randf_range(-0.5, 0.5),
            randf_range(-1.0, 1.0)
        )
```

Brownian kicks keep the entropy alive. Nothing settles. The room refuses to predict itself.

Compute spread as a proxy for E(S).

```gdscript
func _spread(pts: PackedVector3Array) -> float:
    if pts.is_empty(): return 0.0
    var mean := Vector3.ZERO
    for p in pts: mean += p
    mean /= pts.size()
    var total := 0.0
    for p in pts: total += mean.distance_squared_to(p)
    return sqrt(total / pts.size())
```

Standard deviation from the centre of mass. Not true Shannon entropy, but proportional in this volume. The meter updates each physics frame.

Render the meter as a glass column.

```gdscript
func update_visual(level: float) -> void:
    var mapped: float = clamp(level / max_spread, 0.0, 1.0)
    column.scale.y = mapped
    column.position.y = mapped * 0.5
```

The column rises and falls with the cloud. Entropy becomes posture in the room.

Offer a freeze button.

```gdscript
func _on_freeze_pressed() -> void:
    for cube in cubes:
        cube.freeze = true
    meter.update_visual(0.01)
```

Freezing the cubes collapses the cloud. The column shrinks. The learner sees that entropy is a rate, not a property.

Offer a release button.

```gdscript
func _on_release_pressed() -> void:
    for cube in cubes:
        cube.freeze = false
```

Released cubes resume Brownian motion. Entropy returns. The two buttons make the dialectic interactive.

You have built the E side of the dialectic. The next map, Lambda Spectrum, combines F and E into a walkable gradient.
<<</MAP>>>

Clamp cubes to the room.

```gdscript
func clamp_to_room(cube: Node3D) -> void:
    cube.position.x = clamp(cube.position.x, -5.0, 5.0)
    cube.position.z = clamp(cube.position.z, -5.0, 5.0)
```

Walls keep the cloud inside the readable volume. Entropy stays bounded by the room's geometry.
