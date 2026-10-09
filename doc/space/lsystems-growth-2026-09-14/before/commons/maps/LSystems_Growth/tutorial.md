# Growth

Watch the L-system grow. One generation per visible step.

Animate by generations.

```gdscript
class_name GrowthAnimator extends Node

@export var lsystem: LSystem
@export var generations_per_second: float = 0.5

var current_generation: int = 0
var time_accumulator: float = 0.0

func _process(delta: float) -> void:
    time_accumulator += delta
    if time_accumulator > 1.0 / generations_per_second:
        time_accumulator = 0.0
        current_generation += 1
        rebuild_to_generation(current_generation)
```

Half a second per generation. The plant grows in visible steps.

Rebuild at a specific generation.

```gdscript
func rebuild_to_generation(gen: int) -> void:
    clear_segments()
    var string := lsystem.expand(gen)
    var turtle := Turtle3D.new()
    turtle.interpret(string, 0.2, deg_to_rad(lsystem.angle_deg))
    render_segments_3d(turtle.segments)
```

Clear the previous generation's geometry, compute the new string, interpret it, render the result.

Use a 3D turtle.

```gdscript
class_name Turtle3D

var position: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.UP
var right: Vector3 = Vector3.RIGHT
var up: Vector3 = Vector3.FORWARD
var segments: Array = []
var stack: Array = []

func interpret(lstring: String, step: float, angle_rad: float) -> void:
    for c in lstring:
        match c:
            "F":
                var end := position + direction * step
                segments.append([position, end])
                position = end
            "+": direction = direction.rotated(right, angle_rad)
            "-": direction = direction.rotated(right, -angle_rad)
            "&": direction = direction.rotated(up, angle_rad)
            "^": direction = direction.rotated(up, -angle_rad)
            "[": stack.append({"p": position, "d": direction, "r": right, "u": up})
            "]":
                var s = stack.pop_back()
                position = s.p; direction = s.d; right = s.r; up = s.u
```

Three-dimensional turtle. Six rotation commands cover pitch, yaw, and the stack operations.

Spawn a plant stalk.

```gdscript
class_name PlantStalk extends Node3D

@export var grow_rate: float = 0.3

var current_height: float = 0.0
@export var max_height: float = 3.0

func _process(delta: float) -> void:
    current_height = min(max_height, current_height + grow_rate * delta)
    var mesh: CylinderMesh = mesh_instance.mesh
    mesh.height = current_height
    mesh_instance.position.y = current_height / 2.0
```

The stalk extends over time. The cylinder mesh's height and the mesh instance's position both update.

Add leaves at the tips.

```gdscript
func spawn_leaf_at(position: Vector3) -> Node3D:
    var leaf := MeshInstance3D.new()
    leaf.mesh = preload("res://commons/lsystems/leaf.tscn").instantiate().mesh
    leaf.position = position
    leaf.scale = Vector3.ONE * 0.3
    add_child(leaf)
    return leaf
```

A leaf mesh at each terminal segment. Small scale so leaves don't overwhelm the stalk.

Vary per-plant.

```gdscript
func randomize_parameters(plant: PlantStalk) -> void:
    plant.grow_rate = randf_range(0.2, 0.5)
    plant.max_height = randf_range(2.0, 4.0)
    plant.rotate_y(randf_range(0, TAU))
```

Each plant gets slightly different parameters. A garden of plants reads as a population rather than as copies.

You can now animate L-system growth by generations, interpret the result with a 3D turtle, and populate a scene with varied plants. LSystems_Grammars_And_Curves extends into different curve grammars.
