# Air Music

Walk into a position, the room plays a note. Build the spatial instrument where phasing loops drift over each other.

Declare the voice registry.

```gdscript
class_name SpatialVoice
extends Node3D

@export var midi_note: int = 60
@export var phase_period: float = 7.3
```

Each voice is a Node3D with a note and a phase period. Periods are irrationally spaced so the voices drift rather than lock.

Build the grid of voices.

```gdscript
func populate_voices(parent: Node3D) -> void:
    var scale := [0, 2, 4, 5, 7, 9, 11]
    for i in 12:
        var v := preload("res://commons/artifacts/wavefunctions/spatial_voice.tscn").instantiate()
        v.midi_note = 48 + scale[i % scale.size()] + 12 * (i / scale.size())
        v.position = Vector3(i * 1.2 - 6.5, 1.2, 0.0)
        v.phase_period = 5.0 + float(i) * 0.7
        parent.add_child(v)
```

Twelve voices across a major scale. Phase periods grow slowly. No two voices share a rate.

Detect the listener within range.

```gdscript
func within_range(listener: Vector3) -> bool:
    return global_position.distance_to(listener) < 1.0
```

The voice wakes only when the learner comes close. Everything else stays silent. The instrument plays by being visited.

Emit when triggered.

```gdscript
func _process(dt: float) -> void:
    if within_range(listener.global_position):
        var t := Time.get_ticks_msec() / 1000.0
        var phase_gate: bool = fmod(t, phase_period) < phase_period * 0.3
        if phase_gate and not sounding:
            play_note()
            sounding = true
        elif not phase_gate:
            sounding = false
```

Within range, the voice plays only during its phase window. Two nearby voices overlap only when their windows coincide. Harmony emerges from independent cycles.

Render a soft halo on the active voice.

```gdscript
func show_halo(active: bool) -> void:
    halo.visible = active
    halo.modulate = Color(1.0, 0.9, 0.6, 0.6)
```

A warm halo marks the active voice without sound alone. Visually quiet, sonically present.

Apply FM synthesis on the note.

```gdscript
func play_note() -> void:
    var freq: float = 440.0 * pow(2.0, (midi_note - 69) / 12.0)
    audio_player.frequency = freq
    audio_player.modulator = freq * 2.1
    audio_player.play()
```

FM piano-like tone, bright and bell-like. The modulator ratio gives Eno-era character. No composed sequence; the room composes.

Log the walk as a piece.

```gdscript
func log_note(v: SpatialVoice, t: float) -> void:
    piece.append({"t": t, "note": v.midi_note})
```

The piece records each voice that played and when. The learner takes a generated composition home. The room is a pencil, not a score.

You have made the space an instrument. The next map, Sky Stairs, ascends the wave.
<<</MAP>>>
