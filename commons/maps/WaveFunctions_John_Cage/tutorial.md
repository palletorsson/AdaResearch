# John Cage

4'33" made the silence the piece. Build a room where absence is measurable and the noise floor is never actually zero.

Declare the listener.

```gdscript
class_name SilenceListener
extends Node3D

@export var sample_seconds: float = 0.25
var noise_floor_db: float = -60.0
```

A listener records short windows and computes the noise floor. Nothing is ever fully silent; the listener measures how quiet the room actually is.

Sample the ambient level.

```gdscript
func sample_ambient(bus: int) -> float:
    return AudioServer.get_bus_peak_volume_left_db(bus, 0)
```

Godot's AudioServer reports the bus peak in dB. Lower numbers are quieter. The method returns the current read.

Update the floor display.

```gdscript
func update_floor_display(label: Label3D) -> void:
    var level := sample_ambient(ambient_bus)
    noise_floor_db = lerp(noise_floor_db, level, 0.1)
    label.text = "floor: %.1f dB" % noise_floor_db
```

Exponential smoothing keeps the reading stable. The label shows the floor changing with the learner's own breath and movement.

Mark the 4'33" sections.

```gdscript
const CAGE_SECTIONS := [30.0, 162.0, 81.0]

func compute_total() -> float:
    var total := 0.0
    for s in CAGE_SECTIONS: total += s
    return total
```

Cage's score prescribes three movements with specific durations. The total matches the title. The constant records the piece.

Drive a timer against the sections.

```gdscript
func _process(dt: float) -> void:
    elapsed += dt
    if elapsed > CAGE_SECTIONS[current_section]:
        current_section = min(current_section + 1, CAGE_SECTIONS.size() - 1)
        elapsed = 0.0
        movement_label.text = "movement %d" % (current_section + 1)
```

The timer advances through the sections. Movement labels change quietly. The piece performs itself without a musician.

Generate an aleatoric event.

```gdscript
func aleatoric_event() -> void:
    if randf() < 0.005:
        var sound := preload("res://commons/artifacts/wavefunctions/ambient_click.tscn").instantiate()
        sound.position = Vector3(randf_range(-3, 3), randf_range(1, 2), randf_range(-3, 3))
        add_child(sound)
```

Rare, random clicks. The room performs chance. Cage's indeterminacy as a spawn rule.

Log each event for reflection.

```gdscript
func log_event(at: float, kind: String) -> void:
    events.append({"at": at, "kind": kind})
```

The log captures what happened in the silence. Every visit generates a different piece. The score is the rule; the performance is unique.

You have listened to the space between. The next map, AirMusic, lets position in space become note.
<<</MAP>>>

Offer a print mode of the generated piece.

```gdscript
func print_piece() -> String:
    var out := "events:
"
    for e in events:
        out += "  %5.2f  %s
" % [e.at, e.kind]
    return out
```

The piece can be exported as text. The silence becomes a score.

Dim the lights during the movements.

```gdscript
func dim_room(dt: float) -> void:
    world_environment.environment.ambient_light_energy = lerp(world_environment.environment.ambient_light_energy, 0.2, dt)
```

Ambient drops gradually. The room prepares the listener for attention.
