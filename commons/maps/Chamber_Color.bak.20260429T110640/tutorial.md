# Chamber Color

Four hues, four creature responses. The catalyst speaks.

Build the chromatic catalyst.

```gdscript
class_name ChromaticCatalyst extends Node3D

@export var current_hue: Color = Color.RED

func cycle_hue() -> void:
    const HUE_CYCLE := [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
    var i: int = HUE_CYCLE.find(current_hue)
    current_hue = HUE_CYCLE[(i + 1) % HUE_CYCLE.size()]
```

Four hues cycle. Each press of a dedicated button advances to the next.

Fire a hue projectile.

```gdscript
func fire(direction: Vector3) -> void:
    var projectile := HUE_PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.linear_velocity = direction * 10.0
    projectile.hue = current_hue
    get_tree().root.add_child(projectile)
```

The projectile carries the current hue as metadata. On impact, the hue determines the response.

Build the kaleidocycle creature.

```gdscript
class_name KaleidocycleEnemy extends CharacterBody3D

enum Face { FIRE, ICE, SPIKE, SHIELD }
const FACE_HUES := {
    Face.FIRE: Color.RED, Face.ICE: Color.BLUE,
    Face.SPIKE: Color.GREEN, Face.SHIELD: Color.YELLOW,
}

var current_face: int = Face.FIRE
@export var cycle_interval: float = 2.0

var time_since_cycle: float = 0.0

func _process(delta: float) -> void:
    time_since_cycle += delta
    if time_since_cycle >= cycle_interval:
        time_since_cycle = 0.0
        current_face = (current_face + 1) % 4
        update_visual()
```

Four faces cycle in order. Each face is associated with one hue.

Match a hue to the current face.

```gdscript
func hue_match(incoming: Color) -> float:
    var expected := FACE_HUES[current_face]
    var hue_diff: float = abs(incoming.h - expected.h)
    if hue_diff > 0.5: hue_diff = 1.0 - hue_diff
    return 1.0 - hue_diff * 2.0
```

Compare hues on the circle. Score is 1.0 for exact match, 0.0 for opposite.

Respond to a hit.

```gdscript
func on_projectile_hit(hue: Color) -> void:
    var match_strength: float = hue_match(hue)
    if match_strength > 0.8:
        on_face_triggered()
    else:
        on_hue_mismatch()

func on_face_triggered() -> void:
    # Brief flash; possibly state transition
    pass

func on_hue_mismatch() -> void:
    # Reflect the projectile
    pass
```

High match triggers the face; low match is a mismatch. Different creatures interpret these events differently.

Log hits on the science screen.

```gdscript
func log_hit(hue: Color, face: int, success: bool) -> void:
    var screen = get_tree().get_first_node_in_group("science_screen")
    screen.log_event({
        "hue_angle": hue.h * 360.0,
        "face_name": ["fire", "ice", "spike", "shield"][face],
        "success": success,
        "time": Time.get_ticks_msec() / 1000.0,
    })
```

Each hit becomes a data point. Colour angle on one axis, face on the other, success as a colour.

Add a miura observer.

```gdscript
func spawn_miura_witness() -> void:
    var miura := preload("res://commons/transformation/miura_crawler.tscn").instantiate()
    miura.position = Vector3(3, 0, -3)
    miura.set_friendly_posture(true)
    add_child(miura)
```

The miura befriended in the transformation sequence appears as a witness. It confirms the chamber's non-hostile mode.

Detect befriending.

```gdscript
var sustained_match_time: float = 0.0

func _process(delta: float) -> void:
    super(delta)
    if recent_match_strength > 0.9:
        sustained_match_time += delta
    else:
        sustained_match_time = 0.0
    if sustained_match_time > 4.0:
        befriend()
```

Four seconds of sustained hue matching. The kaleidocycle settles, the creature is befriended, and the hue catalyst is added to your kit.

You can now build the chromatic catalyst, fire hue-tagged projectiles, evaluate the match between a hue and a creature face, log hits as scatter data, and befriend the kaleidocycle through sustained matching. The Color sequence closes and hands you forward.
