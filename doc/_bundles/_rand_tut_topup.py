import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

splits = {
    'Randomness_Examples_of_Randomness': [
        ('The chart scrolls. Most values cluster near zero. Occasional outliers punctuate. Tail distributions become readable.',
         'The chart scrolls. Most values cluster near zero.\n\nOccasional outliers punctuate. Tail distributions become readable.'),
    ],
}

for name, pairs in splits.items():
    f = Path('commons/maps/' + name + '/tutorial.md')
    t = f.read_text(encoding='utf-8')
    for old, new in pairs:
        t = t.replace(old, new)
    f.write_text(t, encoding='utf-8')

adds = {
    'Random_Definition': """

Seed from player input.

```gdscript
func _on_seed_keyboard_entry(text: String) -> void:
    if text.is_valid_int():
        seed = int(text)
        state = seed
```

The learner can type a seed. Any reproducible run becomes shareable.

Compare PRNG and TRNG side by side.

```gdscript
func compare_sources(count: int) -> void:
    for i in count:
        log_sample(uniform(), "prng")
        log_sample(true_random_sample(), "trng")
```

Pairs of samples accumulate under each label. The histograms diverge subtly over time.

Expose a bit view.

```gdscript
func bit_view(v: float) -> String:
    var bits: int = int(v * 0xffffff)
    return String.num_int64(bits, 2).pad_zeros(24)
```

Each float becomes a binary string. The view exposes the underlying entropy source in its rawest form.
""",
    'Random_Remove': """

Undo the last removal.

```gdscript
func undo_last() -> void:
    if removal_log.is_empty(): return
    var last: Dictionary = removal_log.pop_back()
    _respawn_cube(Vector2i(last.x, last.y))
```

The last removed cube respawns at its old position. The learner can rewind a step at a time.
""",
    'Randomness_10_PRINT_Algorithm': """

Expose the flip bias.

```gdscript
func set_bias(p: float) -> void:
    bias = clamp(p, 0.0, 1.0)

func flip_cell_biased() -> String:
    return "/" if randf() < bias else "\\\\"
```

A bias slider tilts the coin. At 0.5 the maze is symmetric. At the extremes the maze degenerates into a single diagonal.
""",
    'Random_Cubes': """

Save a profile to disk.

```gdscript
func save_profile(cube: RandomEdgeCube, slot: int) -> void:
    UserSettings.set_value("cubes/slot_%d" % slot, cube.edge_profile)
```

Any profile can be saved and reloaded later. Randomness becomes archivable.
""",
    'Random_Rotate_Random_XYZ': """

Save the current orientation as a preset.

```gdscript
func save_preset(name: String) -> void:
    presets[name] = Vector3(x_angle, y_angle, z_angle)
```

Presets capture a favourite orientation. The learner can return to a surprise they liked.

Animate between presets.

```gdscript
func tween_to_preset(name: String) -> void:
    if not presets.has(name): return
    var target: Vector3 = presets[name]
    create_tween().tween_property(self, "rotation", target, 0.8)
```

A tween smoothly rotates from the current angle to the preset. The transition reads as a handwritten arc.
""",
    'Random_Walk': """

Colour older segments faintly.

```gdscript
func fade_old_segments(mesh: ImmediateMesh) -> void:
    for i in path.size():
        var age: float = float(path.size() - i) / float(path.size())
        mesh.surface_set_color(Color(1.0, 0.9, 0.6, 1.0 - age))
```

Old portions of the path fade. Recent steps are bright. Memory visibly decays.
""",
    'Random_Mushrooms': """

Resample on weather change.

```gdscript
func on_weather_changed() -> void:
    _clear_mushrooms()
    scatter_candidates(200)
```

New weather reshapes the likelihood map. The old mushrooms clear and the forest floor resamples.
""",
    'Randomness_Examples_of_Randomness': """

Add a label to each room.

```gdscript
func label_room(room: Node3D, key: String) -> void:
    var label := Label3D.new()
    label.text = "%s\n%s" % [key, registry.rooms[key]]
    label.position = Vector3(0, 2.5, 0)
    room.add_child(label)
```

Each doorway announces the register within. The learner can skip or linger based on the label.
""",
    'Random_Space': """

Pulse the room lights slightly on each drip.

```gdscript
func _on_drop_landed() -> void:
    arena_light.light_energy = 3.0
    create_tween().tween_property(arena_light, "light_energy", 1.5, 0.4)
```

Each splat pulses the ambient. The finale feels like it has a pulse. The pulse is random, not rhythmic.
""",
    'Chamber_Random': """

Apply chaos scatter to subsequent chambers.

```gdscript
func apply_chaos_elsewhere() -> void:
    CatalystBracelet.set_global_scatter(0.3)
```

The catalyst mode carries scatter forward. Every future shot, placement, or bond will include a small amount of chance.
""",
}

for name, a in adds.items():
    p = Path('commons/maps/' + name + '/tutorial.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + a, encoding='utf-8')

print('done')
