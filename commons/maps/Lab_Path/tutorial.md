# Lab Path

The corridor back. Shared template across every sequence.

Build the corridor.

```gdscript
class_name LabPath extends Node3D

@export var source_sequence: String = ""
@export var target_lab_state: String = ""

func _ready() -> void:
    build_corridor_geometry()
    place_ambient_sphere()
    place_teleporter()
    configure_lighting()
```

Four standard components. Every sequence's exit uses the same recipe.

Build corridor geometry.

```gdscript
func build_corridor_geometry() -> void:
    var floor := MeshInstance3D.new()
    floor.mesh = BoxMesh.new()
    floor.mesh.size = Vector3(5, 0.1, 5)
    floor.position = Vector3(2.5, -0.05, 2.5)
    add_child(floor)
    var ceiling := MeshInstance3D.new()
    ceiling.mesh = BoxMesh.new()
    ceiling.mesh.size = Vector3(5, 0.1, 5)
    ceiling.position = Vector3(2.5, 2.5, 2.5)
    add_child(ceiling)
```

5x5 floor and ceiling. Low-key; nothing draws attention.

Place the ambient sphere.

```gdscript
func place_ambient_sphere() -> void:
    var sphere := DARK_SPHERE_SCENE.instantiate()
    sphere.position = Vector3(2.5, 1.5, 2.5)
    add_child(sphere)
```

A slow-pulsing dark sphere at the centre. The only visual feature.

Place the teleporter.

```gdscript
func place_teleporter() -> void:
    var teleporter := TELEPORTER_SCENE.instantiate()
    teleporter.position = Vector3(2.5, 0, 4.5)
    teleporter.target = "res://commons/maps/Lab/map.tscn"
    teleporter.target_state = target_lab_state
    add_child(teleporter)
```

At the far end of the corridor. Entering returns the learner to the Lab.

Configure soft lighting.

```gdscript
func configure_lighting() -> void:
    var light := DirectionalLight3D.new()
    light.light_energy = 0.3
    light.rotation = Vector3(-0.5, 0.3, 0)
    add_child(light)
    var environment := WorldEnvironment.new()
    environment.environment = preload("res://commons/environments/lab_path.tres")
    add_child(environment)
```

Low-energy light, plus a shared environment resource. Consistent across every sequence's corridor.

Fade to black on exit.

```gdscript
func _on_teleporter_activated() -> void:
    var fade := ColorRect.new()
    fade.color = Color(0, 0, 0, 0)
    add_child(fade)
    var tween := create_tween()
    tween.tween_property(fade, "color:a", 1.0, 0.3)
    tween.tween_callback(func():
        get_tree().change_scene_to_file("res://commons/maps/Lab/map.tscn")
    )
```

Brief fade prevents cut-to-Lab. Eye-friendly transition.

Pass state to the Lab.

```gdscript
func prepare_handoff() -> void:
    GameState.last_sequence_completed = source_sequence
    GameState.lab_target_state = target_lab_state
```

The Lab reads the state to decide how to present itself. Different sequences complete differently.

You can now build the shared corridor, ambient sphere, teleporter with target state, soft lighting, and fade-to-black transition. Chamber_Noise extends into the chamber for the Noise sequence.

Clamp to valid range.

```gdscript
func clamp_noise(value: float, low: float = -1.0, high: float = 1.0) -> float:
    return clamp(value, low, high)
```

Guarantees output stays in the expected range. Useful before writing to textures.
