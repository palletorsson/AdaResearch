# Random Mushrooms

Fungi grow where the distribution allows. Build the forest floor where substrate, moisture, and temperature decide placement.

Declare the substrate sampler.

```gdscript
class_name SubstrateSampler
extends Node3D

@export var moisture_map: Texture2D
@export var temperature_map: Texture2D
@export var substrate_map: Texture2D
```

Three maps describe the ground. Each stores a float per pixel. A sampler reads the combined likelihood at a position.

Compute the likelihood at a point.

```gdscript
func likelihood(pos: Vector3) -> float:
    var uv := _world_to_uv(pos)
    var m: float = moisture_map.get_image().get_pixelv(uv).r
    var t: float = temperature_map.get_image().get_pixelv(uv).r
    var s: float = substrate_map.get_image().get_pixelv(uv).r
    return m * t * s
```

Three values multiplied. If any is zero, the spot is unsuitable. If all are high, the spot invites growth.

Accept or reject a candidate.

```gdscript
func accept_candidate(pos: Vector3) -> bool:
    return randf() < likelihood(pos)
```

The rejection sampler maps the probability to a boolean. Over many candidates, accepted points cluster where likelihood is high.

Spawn a mushroom at an accepted point.

```gdscript
func spawn_mushroom(pos: Vector3) -> void:
    var m := preload("res://commons/artifacts/randomness/mushroom.tscn").instantiate()
    m.position = pos
    m.scale = Vector3.ONE * randf_range(0.6, 1.2)
    add_child(m)
```

Each mushroom has a slightly different size. The forest floor reads as varied because it is.

Scatter candidates across the floor.

```gdscript
func scatter_candidates(count: int) -> void:
    for i in count:
        var pos := Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
        if accept_candidate(pos):
            spawn_mushroom(pos)
```

A hundred candidates might yield thirty mushrooms. The accepted set is the sample from the distribution.

Render the 1955 RAND tables on a wall.

```gdscript
func place_rand_plaque() -> void:
    var plaque := preload("res://commons/artifacts/randomness/rand_book_plaque.tscn").instantiate()
    plaque.position = Vector3(0, 1.5, -6)
    add_child(plaque)
```

Before computers generated randomness, RAND Corporation published a million-digit book. The plaque names the history.

Allow weather to shift.

```gdscript
func shift_moisture(amount: float) -> void:
    var img: Image = moisture_map.get_image()
    img.adjust_bcs(1.0, 1.0, 1.0 + amount)
    moisture_map = ImageTexture.create_from_image(img)
```

A lever adjusts the moisture. New spawns cluster in the wetter half. The distribution is not static.

Log every spawn.

```gdscript
func log_spawn(pos: Vector3) -> void:
    spawn_log.append({"pos": pos, "time": Time.get_ticks_msec()})
```

The log becomes a spore record. The learner can plot the spread over time.

You have sampled life from a distribution. The next map, Random Space Geometry, randomises the space itself.
<<</MAP>>>

Resample on weather change.

```gdscript
func on_weather_changed() -> void:
    _clear_mushrooms()
    scatter_candidates(200)
```

New weather reshapes the likelihood map. The old mushrooms clear and the forest floor resamples.
