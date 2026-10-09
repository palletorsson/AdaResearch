# Trig Walking Path

Two lanes, 90 degrees out of phase. Build the path that generates itself under the learner's feet.

Declare the path generator.

```gdscript
class_name TrigPath
extends Node3D

@export var lane_spacing: float = 1.5
@export var amplitude: float = 0.8
@export var frequency: float = 0.5
@export var ahead_distance: float = 8.0
```

Two lanes spaced apart. Amplitude is vertical. Ahead distance is how far the path pre-generates beyond the learner.

Sample both lanes at a distance.

```gdscript
func sample_lanes(z: float) -> Array:
    var sin_y: float = amplitude * sin(TAU * frequency * z)
    var cos_y: float = amplitude * cos(TAU * frequency * z)
    return [
        Vector3(-lane_spacing * 0.5, sin_y, z),
        Vector3(lane_spacing * 0.5, cos_y, z),
    ]
```

Sine on the left, cosine on the right. The 90-degree phase difference gives the visual rhythm of the dual path.

Generate new steps ahead of the player.

```gdscript
func extend_path(player_z: float) -> void:
    while last_z < player_z + ahead_distance:
        last_z += 0.4
        var points := sample_lanes(last_z)
        spawn_step(points[0])
        spawn_step(points[1])
```

As the learner walks forward, steps spawn ahead. The path never ends because it is always being drawn in front of them.

Spawn each step.

```gdscript
func spawn_step(pos: Vector3) -> void:
    var step := preload("res://commons/artifacts/wavefunctions/trig_step.tscn").instantiate()
    step.position = pos
    add_child(step)
    steps.append(step)
```

Each spawned step is tracked for despawn. The steps are small floating plates. The learner steps from one to the next.

Despawn steps behind.

```gdscript
func cull_behind(player_z: float) -> void:
    steps = steps.filter(func(s):
        if s.position.z < player_z - 5.0:
            s.queue_free()
            return false
        return true
    )
```

Old steps free themselves. Memory stays low. The path is finite at any moment but infinite over time.

Label each step with its angle.

```gdscript
func label_step(step: Node3D, z: float) -> void:
    var label: Label3D = step.get_node("Label3D")
    label.text = "θ = %.2f" % (TAU * frequency * z)
```

Each step carries its angle. The learner can read their position in the waveform by looking down.

Colour the lanes differently.

```gdscript
func tint_lanes() -> void:
    for step in steps:
        var is_left: bool = step.position.x < 0.0
        var mat := step.get_node("MeshInstance3D").material_override as StandardMaterial3D
        mat.albedo_color = Color(0.4, 0.7, 0.9) if is_left else Color(0.9, 0.6, 0.3)
```

Sine lane cool, cosine lane warm. The colour lets the learner cross-reference the phase without checking numbers.

You have walked the two fundamentals. The next map, Synthesis Lab, stacks harmonics until any waveform appears.
<<</MAP>>>
