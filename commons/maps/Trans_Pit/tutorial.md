# Trans Pit

Three rooms, three transformations, three hazards. The pit does not care which move sent you into it.

Build a pusher block.

```gdscript
class_name PusherBlock extends StaticBody3D

@export var axis: Vector3 = Vector3.RIGHT
@export var distance: float = 4.0
@export var speed: float = 2.0

var start_position: Vector3
var phase: float = 0.0

func _ready() -> void:
    start_position = global_position

func _physics_process(delta: float) -> void:
    phase = fmod(phase + delta * speed / distance, 2.0)
    var t: float = phase if phase < 1.0 else 2.0 - phase  # triangle wave
    global_position = start_position + axis * distance * t
```

The phase cycles between 0 and 2; the t value produces a triangle wave for smooth back-and-forth motion.

Build a revolving wall.

```gdscript
class_name RevolvingWall extends StaticBody3D

@export var angular_velocity: float = 1.0

func _physics_process(delta: float) -> void:
    rotate_y(angular_velocity * delta)
```

Constant rotation around the Y axis. The wall sweeps in a circle around its pivot.

Build a grower block.

```gdscript
class_name GrowerBlock extends StaticBody3D

@export var scale_rate: float = 0.2
@export var max_scale: float = 3.0

var current: float = 1.0

func _physics_process(delta: float) -> void:
    current = min(max_scale, current + scale_rate * delta)
    scale = Vector3.ONE * current
```

Grows until max_scale. The learner's safe footprint shrinks as the block expands.

Place fire pits around the hazards.

```gdscript
func place_fire_pits(rectangle: Rect2) -> void:
    for i in rectangle.size.x:
        for j in rectangle.size.y:
            var pit := FIRE_PIT_SCENE.instantiate()
            pit.position = Vector3(rectangle.position.x + i, 0, rectangle.position.y + j)
            add_child(pit)
```

The pits are the constant across the three rooms. Their positions vary with the room's layout.

Handle fire pit contact.

```gdscript
func _on_fire_pit_body_entered(body: Node) -> void:
    if body.is_in_group("learner"):
        DeathEffect.trigger(body, "fire")
```

The DeathEffect autoload handles the death sequence: flash, freeze, haptic, reload.

Trigger map reload.

```gdscript
func reload_map() -> void:
    get_tree().reload_current_scene()
```

The scene reloads from scratch. All hazards reset to their starting positions.

You can now build pusher blocks, revolving walls, grower blocks, and fire pits, and trigger the death-and-reload sequence on contact. Chamber_Transformation converts transformation into a creature encounter.

Check identity.

```gdscript
func is_identity(t: Transform3D) -> bool:
    return t.is_equal_approx(Transform3D.IDENTITY)
```

Identity preserves the input. Useful as a test for whether a chain of transforms cancels out.

Invert a transform.

```gdscript
func invert(t: Transform3D) -> Transform3D:
    return t.affine_inverse()
```

Undo the transform. Composing t with t.affine_inverse() produces identity.

Compose with multiplication.

```gdscript
func combine(a: Transform3D, b: Transform3D) -> Transform3D:
    return a * b
```

Right-to-left application order. a * b applies b first, then a.

Extract the origin.

```gdscript
func get_origin(t: Transform3D) -> Vector3:
    return t.origin
```

The origin is the translation part of the transform. Ignore the basis to get just the position.
