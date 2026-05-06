import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

splits = {
    'WaveFunctions_Effect_Sound': [
        ('Four waveform shapes from a single sine source. Square is sign. Sawtooth is fmod. Triangle is absolute value. Chiptune from one function.',
         'Four waveform shapes from a single sine source.\n\nSquare is sign. Sawtooth is fmod. Triangle is absolute value. Chiptune from one function.'),
    ],
}

for name, pairs in splits.items():
    f = Path('commons/maps/' + name + '/tutorial.md')
    t = f.read_text(encoding='utf-8')
    for old, new in pairs:
        t = t.replace(old, new)
    f.write_text(t, encoding='utf-8')

adds = {
    'WaveFunctions_Intro': """

Cycle the kind on a timer.

```gdscript
func auto_cycle(dt: float) -> void:
    cycle_time += dt
    if cycle_time > 3.0:
        current_kind = (current_kind + 1) % 4
        cycle_time = 0.0
```

A demo mode walks through the four kinds automatically. The learner sees the shapes transition without touching controls.
""",
    'WaveFunctions_Pendulum': """

Draw the path of the bob as a fading trail.

```gdscript
func update_trail(trail: Line3D) -> void:
    trail.add_point(bob.position)
    if trail.get_point_count() > 80:
        trail.remove_point(0)
```

The arc of the swing becomes visible as a fading curve. Motion leaves a readable mark.

Pause on apex.

```gdscript
func pause_on_apex() -> void:
    if abs(angular_velocity) < 0.02:
        paused_time += get_process_delta_time()
```

The apex is where motion stops. A brief pause label highlights the moment. Pendulum physics becomes attention.
""",
    'WaveFunctions_Unit_Circle': """

Draw the chord from cosine to sine runners.

```gdscript
func draw_chord(mesh: ImmediateMesh, a: Vector3, b: Vector3) -> void:
    mesh.clear_surfaces()
    mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    mesh.surface_add_vertex(a)
    mesh.surface_add_vertex(b)
    mesh.surface_end()
```

The chord length visualises the phase difference as distance. When phase equals a quarter turn, chord length equals the radius.

Label the two runners.

```gdscript
func label_runners() -> void:
    sin_runner.label = "sin"
    cos_runner.label = "cos"
```

Each runner wears its function name. The amphitheater becomes legible to a first-time visitor.
""",
    'WaveFunctions_Sine_Space': """

Save the current corridor as a preset.

```gdscript
func save_preset(slot: int) -> void:
    UserSettings.set_value("sine_space/slot_%d" % slot, {
        "amplitude": amplitude,
        "frequency": frequency,
    })
```

Each slot stores two numbers. Later visits can reload a past corridor.
""",
    'WaveFunctions_3D_Wave_Propagation': """

Readout the nearest source's phase at the player.

```gdscript
func readout_phase(player: Vector3) -> float:
    if sources.is_empty(): return 0.0
    var nearest: Node3D = sources[0]
    for s in sources:
        if s.global_position.distance_to(player) < nearest.global_position.distance_to(player):
            nearest = s
    return nearest.global_position.distance_to(player) / nearest.speed
```

Phase delay is distance divided by speed. The readout shows how far behind the source the learner is standing.
""",
    'WaveFunctions_John_Cage': """

Offer a print mode of the generated piece.

```gdscript
func print_piece() -> String:
    var out := "events:\n"
    for e in events:
        out += "  %5.2f  %s\n" % [e.at, e.kind]
    return out
```

The piece can be exported as text. The silence becomes a score.

Dim the lights during the movements.

```gdscript
func dim_room(dt: float) -> void:
    world_environment.environment.ambient_light_energy = lerp(world_environment.environment.ambient_light_energy, 0.2, dt)
```

Ambient drops gradually. The room prepares the listener for attention.
""",
    'Chamber_Waves': """

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
""",
}

for name, a in adds.items():
    p = Path('commons/maps/' + name + '/tutorial.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + a, encoding='utf-8')

print('done')
