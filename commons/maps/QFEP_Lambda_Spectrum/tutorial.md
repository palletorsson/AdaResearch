# Lambda Spectrum

Your position is the λ value. Walk from crystal at λ=0 to dissolution at λ=1, through the edge of chaos in between.

Declare the lambda reader.

```gdscript
class_name LambdaReader
extends Node3D

@export var track_start: Vector3 = Vector3.ZERO
@export var track_end: Vector3 = Vector3(20.0, 0.0, 0.0)

func lambda_for(player_pos: Vector3) -> float:
    var total := track_start.distance_to(track_end)
    var here := track_start.distance_to(player_pos)
    return clamp(here / total, 0.0, 1.0)
```

A straight track with a start and end. Player position projects onto the track to yield λ. The reader is the only translator between body and number.

Sample the player every frame.

```gdscript
func _process(_dt: float) -> void:
    var l := lambda_for(player.global_position)
    lambda_label.text = "λ = %.2f" % l
    world.apply_lambda(l)
```

The label updates with each step. The world reshapes itself to match.

Shape the world by λ.

```gdscript
func apply_lambda(l: float) -> void:
    crystallizer.strength = 1.0 - l
    chaos_field.strength = l
    edge_field.strength = _edge_weight(l)
```

Three fields scale with λ. Order dominates near zero.

Chaos dominates near one. Edge peaks in the middle.

Compute the edge weight.

```gdscript
func _edge_weight(l: float) -> float:
    return exp(-pow((l - 0.4) / 0.12, 2.0))
```

A Gaussian centred on λ=0.4 with tight sigma. The edge is narrow. Miss by 0.2 and complexity falls off sharply.

Populate the edge with living patterns.

```gdscript
func populate_edge() -> void:
    for i in 18:
        var pattern := preload("res://commons/artifacts/qfep/edge_creature.tscn").instantiate()
        pattern.position = Vector3(track_start.x + 8.0 + randf_range(-2, 2), 0, randf_range(-2, 2))
        add_child(pattern)
```

Eighteen small creatures live only in the middle band. Their meshes breathe. They vanish at either end.

Drain each creature's life by distance from the edge.

```gdscript
func update_creature(creature: Node3D, l: float) -> void:
    var life := _edge_weight(l)
    creature.scale = Vector3.ONE * life
    creature.modulate.a = life
```

Outside the edge band, the creatures shrink and fade. The learner watches complexity retreat as they step toward either end.

Mark the three stations.

```gdscript
func label_stations() -> void:
    crystal_sign.text = "λ = 0\ncrystal"
    edge_sign.text = "λ ≈ 0.4\nthe edge"
    dissolution_sign.text = "λ = 1\ndissolution"
```

Signs name the three regimes. The learner is not reading about them; the learner is standing in them.

You have walked the spectrum. The next map, Phi Term, adds the system's attitude toward movement along it.
<<</MAP>>>

Log the learner's λ trajectory.

```gdscript
func log_trajectory(l: float) -> void:
    var now := Time.get_ticks_msec() / 1000.0
    trajectory.append({"t": now, "lambda": l})
```

Each λ reading is stamped with time. The trajectory reveals where the learner lingered and where they raced through.
