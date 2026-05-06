# Competition

Plants compete for light. The L-system that reaches the sun first wins.

Track sunlight at each point.

```gdscript
class_name LightField extends Node

var occluders: Array = []  # list of (position, radius) tuples

func light_at(point: Vector3) -> float:
    var above: Vector3 = point + Vector3.UP * 10
    var occlusion: float = 0.0
    for occ in occluders:
        var segment_distance: float = segment_to_point_distance(point, above, occ.position)
        if segment_distance < occ.radius:
            occlusion += 1.0 - segment_distance / occ.radius
    return max(0.0, 1.0 - occlusion)
```

Ray from point to directly above. Each occluder within range reduces the light. Value 0 is full shade; 1 is full sun.

Grow a plant proportional to its available light.

```gdscript
class_name LightCompetingPlant extends LSystemPlant

@export var max_height: float = 4.0

var growth_rate: float = 0.0

func _process(delta: float) -> void:
    var light: float = light_field.light_at(global_position + Vector3.UP * current_height)
    growth_rate = lerp(growth_rate, light * 0.5, delta * 2.0)
    current_height = min(max_height, current_height + growth_rate * delta)
```

More light, faster growth. Plants that start taller cast shadow on shorter ones, reinforcing their advantage.

Register the plant as an occluder.

```gdscript
func register_as_occluder() -> void:
    light_field.occluders.append({
        "position": global_position + Vector3.UP * current_height * 0.5,
        "radius": current_height * 0.3,
    })
```

Each plant's canopy blocks light for its neighbours. Position and radius scale with the plant's height.

Spawn a population.

```gdscript
func spawn_population(count: int, bounds: Vector2) -> void:
    for _i in count:
        var p := LightCompetingPlant.new()
        p.position = Vector3(randf_range(0, bounds.x), 0, randf_range(0, bounds.y))
        p.max_height = randf_range(2.0, 5.0)
        p.growth_rate = randf_range(0.2, 0.8)
        add_child(p)
```

Twenty or so plants, randomly placed and sized. The genetic variation drives the competition.

Run the generation timer.

```gdscript
@export var generation_interval: float = 10.0  # seconds

func _ready() -> void:
    var timer := Timer.new()
    timer.wait_time = generation_interval
    timer.timeout.connect(next_generation)
    add_child(timer)
    timer.start()

func next_generation() -> void:
    cull_weak()
    reproduce_strong()
```

Every ten seconds, the population iterates: weak plants die, strong plants reproduce. Evolution through generations.

Cull plants below a height threshold.

```gdscript
func cull_weak() -> void:
    for child in get_children():
        if child is LightCompetingPlant and child.current_height < 1.0:
            child.queue_free()
```

Plants that failed to grow past one unit are removed. Weaker genetic lines die out.

Reproduce the strong.

```gdscript
func reproduce_strong() -> void:
    var strong: Array = get_children().filter(func(p): return p.current_height > 3.0)
    for parent in strong.slice(0, 3):  # top 3 reproduce
        for _i in 2:
            var offspring := LightCompetingPlant.new()
            offspring.position = parent.position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
            offspring.max_height = parent.max_height + randf_range(-0.5, 0.5)
            add_child(offspring)
```

Top three plants each spawn two offspring. Offspring inherit parent traits with mutation.

You can now grow plants under a light field, register them as occluders, cull weak competitors, and reproduce the strong. LSystems_Living extends L-systems into a full ecosystem.
