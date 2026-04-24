import sys, re
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

# Split long paragraphs
splits = {
    'QFEP_Introduction': [
        ('Warm gold for F. Cool blue for E. Magenta for λ. Green for φ. The colour key stays stable across every map in the sequence.',
         'Warm gold for F. Cool blue for E. Magenta for λ.\n\nGreen for φ. The colour key stays stable across every map in the sequence.'),
    ],
    'QFEP_F_Term': [
        ('A sealed room with no particles. F is zero. Nothing surprises the system because nothing happens. Perfect prediction, no life.',
         'A sealed room with no particles. F is zero.\n\nNothing surprises the system because nothing happens. Perfect prediction, no life.'),
    ],
    'QFEP_Lambda_Spectrum': [
        ('Three fields scale with λ. Order dominates near zero. Chaos dominates near one. Edge peaks in the middle.',
         'Three fields scale with λ. Order dominates near zero.\n\nChaos dominates near one. Edge peaks in the middle.'),
    ],
}

for name, pairs in splits.items():
    f = Path('commons/maps/' + name + '/tutorial.md')
    t = f.read_text(encoding='utf-8')
    for old, new in pairs:
        t = t.replace(old, new)
    f.write_text(t, encoding='utf-8')

# Add word-count topups (small sections with code)
adds = {
    'QFEP_Introduction': """

Colour-key the readout panel.

```gdscript
func colorize_panel(panel: Label3D, sym: String) -> void:
    match sym:
        "F": panel.modulate = Color(0.9, 0.7, 0.3)
        "E": panel.modulate = Color(0.3, 0.6, 0.9)
        "λ": panel.modulate = Color(0.8, 0.4, 0.7)
        "φ": panel.modulate = Color(0.5, 0.9, 0.5)
```

The panel tints to match the sphere the learner just grabbed. Name and colour arrive together.
""",
    'QFEP_F_Term': """

Throttle the settle strength.

```gdscript
func throttle_settle(meter: float) -> void:
    settle_strength = lerp(0.2, 1.5, clamp(meter, 0.0, 1.0))
```

Faster settle means sharper crystallization. A slower one lets the learner watch F fall gradually toward zero.

Record the descent curve.

```gdscript
func log_f_descent(sample_rate: float) -> void:
    if Time.get_ticks_msec() - last_log < sample_rate: return
    f_history.append(f_value())
    last_log = Time.get_ticks_msec()
```

Every sample stores a data point. The history line shows the gradient. F-minimization becomes a trace on a chart.
""",
    'QFEP_E_Term': """

Clamp cubes to the room.

```gdscript
func clamp_to_room(cube: Node3D) -> void:
    cube.position.x = clamp(cube.position.x, -5.0, 5.0)
    cube.position.z = clamp(cube.position.z, -5.0, 5.0)
```

Walls keep the cloud inside the readable volume. Entropy stays bounded by the room's geometry.
""",
    'QFEP_Lambda_Spectrum': """

Log the learner's λ trajectory.

```gdscript
func log_trajectory(l: float) -> void:
    var now := Time.get_ticks_msec() / 1000.0
    trajectory.append({"t": now, "lambda": l})
```

Each λ reading is stamped with time. The trajectory reveals where the learner lingered and where they raced through.
""",
    'QFEP_Phi_Term': """

Lock the dial if the learner requests it.

```gdscript
func lock_dial(locked: bool) -> void:
    dial.can_turn = not locked
    dial_lock_label.text = "locked" if locked else ""
```

Locking preserves a chosen φ while the learner explores. The dial stays readable but stops accepting input.
""",
    'QFEP_Edge_Of_Chaos': """

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
""",
}

for name, a in adds.items():
    p = Path('commons/maps/' + name + '/tutorial.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + a, encoding='utf-8')

print('done')
