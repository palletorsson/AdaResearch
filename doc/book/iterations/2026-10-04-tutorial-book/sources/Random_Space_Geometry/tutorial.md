# Random Space Geometry

Space itself becomes stochastic. Build two chambers where random transformations sculpt the arena.

Declare the chamber pair.

```gdscript
class_name ChamberPair
extends Node3D

@export var north_seed: int = 1
@export var south_seed: int = 2
```

Two seeds, two chambers. Each seed determines every random transform applied to its chamber's geometry.

Generate a chamber mesh.

```gdscript
func generate_chamber(seed_value: int) -> ArrayMesh:
    seed(seed_value)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in 120:
        var pos := Vector3(randf_range(-3, 3), randf_range(0, 3), randf_range(-3, 3))
        _add_random_panel(st, pos)
    return st.commit()
```

120 panels placed randomly. The seed ensures reproducibility. A given seed always builds the same chamber.

Add a panel.

```gdscript
func _add_random_panel(st: SurfaceTool, centre: Vector3) -> void:
    var rot := Basis.from_euler(Vector3(randf(), randf(), randf()) * TAU)
    var size := Vector3(randf_range(0.3, 1.2), 0.05, randf_range(0.3, 1.2))
    st.add_triangle_fan([
        centre + rot * Vector3(-size.x * 0.5, 0, -size.z * 0.5),
        centre + rot * Vector3(size.x * 0.5, 0, -size.z * 0.5),
        centre + rot * Vector3(size.x * 0.5, 0, size.z * 0.5),
        centre + rot * Vector3(-size.x * 0.5, 0, size.z * 0.5),
    ])
```

Each panel has a random centre, rotation, and size. The chamber becomes an array of irregular plates.

Connect the chambers by a spine.

```gdscript
func build_spine(from: Vector3, to: Vector3) -> void:
    var segments := 12
    for i in segments:
        var t: float = float(i) / float(segments - 1)
        var pos: Vector3 = from.lerp(to, t)
        pos.y += sin(t * PI) * 0.5
        var seg := preload("res://commons/artifacts/randomness/spine_segment.tscn").instantiate()
        seg.position = pos
        add_child(seg)
```

A gentle arch connects north and south. Walking from one chamber to the other crosses from one random geometry to another.

Render the chamber ceilings.

```gdscript
func place_ceilings() -> void:
    var mesh := generate_chamber(north_seed)
    north_ceiling.mesh = mesh
    south_ceiling.mesh = generate_chamber(south_seed)
```

Each ceiling is the random panel array mounted overhead. The learner looks up and sees a different randomness in each chamber.

Reroll on demand.

```gdscript
func _on_reroll_button_pressed(side: String) -> void:
    if side == "north":
        north_seed = randi()
    else:
        south_seed = randi()
    place_ceilings()
```

A button rerolls one side. The other stays. Comparison becomes live.

Label the seeds.

```gdscript
func label_seeds() -> void:
    north_label.text = "N: seed %d" % north_seed
    south_label.text = "S: seed %d" % south_seed
```

The seeds are visible. Reproducibility is shown, not assumed. Two learners with the same seeds build the same chambers.

You have made space itself stochastic. The next map, Examples of Randomness, surveys randomness across domains.
<<</MAP>>>
