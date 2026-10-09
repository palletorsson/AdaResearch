# Random Space

The sequence finale. Build the arena where every thread of the randomness curriculum converges.

Declare the finale environment.

```gdscript
class_name RandomSpaceArena
extends Node3D

@export var gaussian_sources: int = 4
@export var butterfly_count: int = 16
@export var pollock_drippers: int = 3
```

Four Gaussians, sixteen butterflies, three drip sources. The numbers are small enough to read and large enough to layer.

Place Gaussian field markers.

```gdscript
func place_gaussians() -> void:
    for i in gaussian_sources:
        var marker := preload("res://commons/artifacts/randomness/gaussian_marker.tscn").instantiate()
        marker.position = Vector3(randfn(0, 4), 0.1, randfn(0, 4))
        add_child(marker)
```

Gaussian random positions. Markers cluster near the origin with rare outliers. The distribution shape is felt through placement.

Scatter butterflies.

```gdscript
func scatter_butterflies() -> void:
    for i in butterfly_count:
        var b := preload("res://commons/artifacts/randomness/butterfly.tscn").instantiate()
        b.position = Vector3(randf_range(-5, 5), randf_range(0.5, 2.5), randf_range(-5, 5))
        add_child(b)
```

Butterflies occupy the air at random heights and floor positions. Each has its own noise-driven path.

Start the drippers.

```gdscript
func start_drippers() -> void:
    for i in pollock_drippers:
        var dripper := preload("res://commons/artifacts/randomness/dripper.tscn").instantiate()
        dripper.position = Vector3(randf_range(-3, 3), 3.0, randf_range(-3, 3))
        add_child(dripper)
```

Drippers hover above the floor, releasing drops at random intervals. The floor collects the splatter over time.

Blend the three into one reading.

```gdscript
func compose_reading() -> Dictionary:
    return {
        "gaussian_count": gaussian_sources,
        "butterfly_count": butterflies.size(),
        "pollock_drops": drop_log.size(),
    }
```

The reading summarises the three modes in one dictionary. A panel displays the numbers.

Fade audio in layers.

```gdscript
func layer_audio(dt: float) -> void:
    gaussian_bus.volume_db = lerp(gaussian_bus.volume_db, -6.0, dt)
    butterfly_bus.volume_db = lerp(butterfly_bus.volume_db, -9.0, dt)
    drip_bus.volume_db = lerp(drip_bus.volume_db, -12.0, dt)
```

Three audio buses ride the three modes. The room sounds like layered randomness rather than one noise.

Write the closing sign.

```gdscript
func write_closing(label: Label3D) -> void:
    label.text = "randomness saturates space"
    label.modulate = Color(0.9, 0.8, 0.7)
```

The sign names the finale. The arena is not about any one example; it is about saturation.

You have walked the finale. The next map, Random Game, makes randomness playable.
<<</MAP>>>

Pulse the room lights slightly on each drip.

```gdscript
func _on_drop_landed() -> void:
    arena_light.light_energy = 3.0
    create_tween().tween_property(arena_light, "light_energy", 1.5, 0.4)
```

Each splat pulses the ambient. The finale feels like it has a pulse. The pulse is random, not rhythmic.

The pulse is a memory of the drip. The finale lives in these small recalls.
