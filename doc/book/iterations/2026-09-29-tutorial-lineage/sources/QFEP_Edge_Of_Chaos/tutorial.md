# Edge Of Chaos

λ near 0.4, φ positive, both held. Build the narrow band where Turing patterns, Langton's rules, and life itself live.

Declare the edge controller.

```gdscript
class_name EdgeController
extends Node3D

@export var lambda_value: float = 0.4
@export var phi_value: float = 0.6
@export var window: float = 0.12
```

Two live values and a tolerance. The controller holds the target and reports whether the learner is in the window.

Test the window.

```gdscript
func in_edge(l: float, p: float) -> bool:
    return abs(l - lambda_value) < window and p > 0.0
```

Inside the window means close to target λ and positive φ. Outside means nothing bad; only less complex. The edge is a location, not a judgement.

Drive a reaction-diffusion field by λ.

```gdscript
func step_rd(field: Image, l: float) -> void:
    var feed: float = 0.035 + l * 0.025
    var kill: float = 0.06 + l * 0.005
    _apply_rd(field, feed, kill)
```

Feed and kill parameters shift with λ. The Gray-Scott system produces spots, stripes, and dissolution across the swept range. The edge hosts the patterns.

Render the RD field to a floor texture.

```gdscript
func update_floor(field: Image) -> void:
    var tex := ImageTexture.create_from_image(field)
    floor_material.albedo_texture = tex
```

The texture updates live. The learner walks on the pattern. The pattern is λ made visible on the ground.

Spawn Langton ants at the edge.

```gdscript
func spawn_ants_if_edge(l: float, p: float) -> void:
    if not in_edge(l, p): return
    for i in 6:
        var ant := preload("res://commons/artifacts/qfep/langton_ant.tscn").instantiate()
        ant.position = Vector3(randf_range(-4, 4), 0.05, randf_range(-4, 4))
        add_child(ant)
```

Ants appear only when the conditions are met. They leave trails that remember the learner's location history. Rule 110 and Langton's ant both live in this neighbourhood.

Chime on entering the window.

```gdscript
func _on_window_entered() -> void:
    audio.stream = edge_chime
    audio.play()
    window_label.text = "you are at the edge"
```

The chime marks the threshold without spotlighting it. The window is a discovery, not a level.

Fade everything outside the window.

```gdscript
func _on_window_exited() -> void:
    for creature in creatures:
        creature.queue_free()
    rd_enabled = false
```

Leaving the edge clears the patterns. The learner sees complexity as something sustained, not something earned. Step back in and it returns.

You have inhabited the edge. The next map, Sandbox, removes every guardrail and gives the parameters to the learner.
<<</MAP>>>

Count ants visible in the frame.

```gdscript
func count_visible_ants(cam: Camera3D) -> int:
    var count := 0
    for ant in ants:
        if cam.is_position_in_frustum(ant.global_position):
            count += 1
    return count
```

Ant-count rises when the learner stands inside the window. A small readout on the wall updates from this value.
