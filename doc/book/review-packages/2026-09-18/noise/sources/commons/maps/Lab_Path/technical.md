# Lab Path — Technical

A shared corridor template used by every sequence to transition back to the Lab. A 5×5 grid, low ceiling, one ambient element, one teleporter.

## Template Scene

```gdscript
class_name LabPath extends Node3D

@export var source_sequence: String = ""
@export var target_lab_state: String = ""

func _ready() -> void:
    setup_lighting()
    spawn_dark_sphere()
    position_teleporter()

func setup_lighting() -> void:
    var light := DirectionalLight3D.new()
    light.light_energy = 0.3
    light.rotation = Vector3(-0.5, 0.2, 0)
    add_child(light)
    var env := WorldEnvironment.new()
    env.environment = preload("res://commons/environments/lab_path.tres")
    add_child(env)

func spawn_dark_sphere() -> void:
    var sphere := DARK_SPHERE_SCENE.instantiate()
    sphere.position = Vector3(2.5, 1.5, 2.5)  # centre of the 5x5 grid at ~1.5m height
    add_child(sphere)

func position_teleporter() -> void:
    var teleporter := TELEPORTER_SCENE.instantiate()
    teleporter.position = Vector3(2.5, 0.0, 4.5)  # end of the corridor
    teleporter.target_scene = "res://commons/maps/Lab/map.tscn"
    teleporter.target_state = target_lab_state
    add_child(teleporter)
```

## Dark Sphere Ambient

The dark_sphere artifact pulses slowly with purple emission.

```gdscript
class_name DarkSphere extends MeshInstance3D

@export var pulse_period: float = 6.0
@export var base_emission: Color = Color(0.15, 0.05, 0.35)

func _process(_delta: float) -> void:
    var t: float = Time.get_ticks_msec() / 1000.0
    var phase: float = sin(t / pulse_period * TAU)
    var pulse_amount: float = (phase + 1.0) / 2.0
    var mat: StandardMaterial3D = material_override
    mat.emission_energy_multiplier = 0.5 + pulse_amount * 1.5
    rotate_y(0.1 * _delta)  # slow rotation
```

## Transition State

The lab_path passes a state token to the Lab that the Lab can read. The token records which sequence the learner just completed, so the Lab can reveal new artifacts or open new sequences accordingly.

```gdscript
# On teleport
func transition_to_lab() -> void:
    GameState.current_lab_state = target_lab_state
    get_tree().change_scene_to_file("res://commons/maps/Lab/map.tscn")
```

## Minimal Set of Assets

The map uses only four scene files: the corridor mesh, the dark sphere, the teleporter, and the spawn point. This minimalism is deliberate — the corridor is supposed to feel emptier than the sequence's active maps.

## Load Time

Because the scene is small, loading is fast. The learner does not wait at the transition; the scene change is perceptually instantaneous.

## Variants

Each sequence's lab_path is nearly identical, differing only in the source_sequence and target_lab_state parameters. This is implemented by subclassing the shared template scene with minimal overrides.

```gdscript
class_name NoiseLabPath extends LabPath

func _init() -> void:
    source_sequence = "noise"
    target_lab_state = "noise_complete"
```

## Complexity

The scene is O(1) in complexity. Per-frame cost is dominated by the dark sphere's rendering with emission, which is still under a millisecond on modern hardware.

## Within the Sequence

Lab_Path is the sequence's exit threshold. It teaches nothing and delivers nothing new, which is the point.

## Save State Integration

The chamber's progress is tracked via the save manager. Befriending a creature, completing a configuration, or reaching a milestone is recorded in the learner's profile and becomes available in subsequent sessions.

```gdscript
func on_befriend_event(creature_name: String) -> void:
    var save = get_tree().get_first_node_in_group("save_manager")
    save.add_befriended_creature(creature_name)
    save.mark_milestone(chamber_id + "_befriended", Time.get_datetime_string_from_system())
```

## Performance Budget

The chamber's per-frame cost is dominated by creature animations and the science screen's rendering. Both are modest: the creature uses a vertex-displacement shader or a prebuilt animation, and the science screen redraws scatter points incrementally rather than from scratch each frame.

```gdscript
func _process(_delta: float) -> void:
    if science_screen.needs_redraw():
        science_screen.redraw_incremental()
```

## VR Comfort

The chamber avoids fast camera moves and sudden lighting changes. Projectiles fire from the learner's hand rather than from fixed spawners, so the learner controls the motion. The chamber's lighting is stable across the encounter; any changes happen gradually through creature state transitions.

## Accessibility

The chamber supports seated play: all interactive elements are within arm's reach, and the projectile direction is controllable from a single hand. The creature responds to either controller, so handedness is not a barrier.

## Within the Curriculum

This chamber is one of the curriculum's catalyst chambers — small, self-contained rooms where the sequence's accumulated vocabulary becomes relationship with a creature. The pattern is consistent across sequences: creature, catalyst (or its deliberate absence), science screen, return to Lab.

## Transition Smoothing

The teleporter uses a short fade-to-black before the scene change, giving the learner's eyes time to adjust. The fade is 0.3 seconds — long enough to smooth the transition, short enough not to feel sluggish.