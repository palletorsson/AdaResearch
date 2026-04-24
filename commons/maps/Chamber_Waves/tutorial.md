# Chamber Waves

Match the creature's frequency and it greets you. Build the chamber where oscillation is the shared variable between two bodies.

Declare the resonance pair.

```gdscript
class_name ResonancePair
extends Node3D

@export var learner_freq: float = 0.5
@export var creature_freq: float = 1.2
@export var tolerance: float = 0.15
```

Two frequencies and a tolerance window. When the difference falls inside the window, the pair resonates.

Read the learner's frequency from the catalyst bracelet.

```gdscript
func read_bracelet(bracelet: Node3D) -> float:
    return bracelet.get("waveform_frequency")
```

The bracelet is the instrument. Turning the stone changes the frequency. The chamber reads it every frame.

Compute the beat frequency.

```gdscript
func beat_freq() -> float:
    return abs(learner_freq - creature_freq)
```

When the beat falls below the tolerance, the two are effectively the same. The chamber reacts then.

Fire helix shots from the bracelet.

```gdscript
func fire_helix(origin: Vector3, dir: Vector3, freq: float) -> void:
    var shot := preload("res://commons/artifacts/wavefunctions/helix_shot.tscn").instantiate()
    shot.position = origin
    shot.direction = dir
    shot.helix_frequency = freq
    add_child(shot)
```

Each shot spirals through the air at the bracelet's frequency. The visual is the waveform made projectile.

Bounce the waterbomb creature.

```gdscript
func bounce(creature: Node3D, t: float) -> void:
    creature.position.y = ground_height + abs(sin(TAU * creature_freq * t)) * 0.7
```

Rectified sine so the creature only goes up. The creature bounces at its own frequency regardless of the learner.

Detect contact.

```gdscript
func _on_shot_hit(shot: Node3D, target: Node3D) -> void:
    if beat_freq() < tolerance:
        target.greet(shot.helix_frequency)
    else:
        target.recoil()
```

Matching frequency greets; mismatched frequency recoils. The learner tunes the bracelet by listening rather than reading.

Greet visibly.

```gdscript
func greet(freq: float) -> void:
    modulate = Color(0.9, 0.9, 0.5)
    emit_signal("befriended")
    play_greeting_tone(freq)
```

The creature lights up, emits a signal, plays a tone at the shared frequency. The friendship is a frequency match.

Unlock the exit on befriending.

```gdscript
func _on_befriended() -> void:
    exit_door.unlock()
    CatalystBracelet.register_friend(creature_name)
```

The exit opens when the creature is friendly. The bracelet records the friend for later chambers. Friendship persists.

You have closed the Wavefunctions sequence. The next arc returns to the QFEP Laboratory, where oscillation is one of four fundamentals.
<<</MAP>>>

Record the friend's greeting frequency.

```gdscript
func record_greeting(freq: float) -> void:
    greeting_log.append({
        "freq": freq,
        "time": Time.get_unix_time_from_system(),
    })
```

Each befriended creature leaves a frequency fingerprint in the log. Future chambers can reference the fingerprint to recognise the learner.

Visualise the beat as a ring.

```gdscript
func update_beat_ring(ring: MeshInstance3D) -> void:
    var beat := beat_freq()
    var glow: float = clamp(1.0 - beat / tolerance, 0.0, 1.0)
    ring.material_override.emission_energy_multiplier = glow * 2.0
```

The ring brightens as frequencies converge. Tuning becomes a visible approach rather than a guess.
