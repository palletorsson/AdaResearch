# Chamber Noise — Technical

The chamber has no creature. The learner authors a small terrain via a noise-parameter bench.

## Parameter Bench

```gdscript
class_name NoiseParameterBench extends Node3D

@export var noise: FastNoiseLite

var params: Dictionary = {
    "frequency": 0.1,
    "amplitude": 1.0,
    "octaves": 4,
    "displacement": 0.5,
    "distribution": "perlin",  # "perlin", "simplex", "value"
}

func _on_slider_changed(param_name: String, value: float) -> void:
    params[param_name] = value
    apply_to_noise()
    terrain.regenerate()

func apply_to_noise() -> void:
    noise.frequency = params.frequency
    noise.fractal_octaves = int(params.octaves)
    match params.distribution:
        "perlin": noise.noise_type = FastNoiseLite.TYPE_PERLIN
        "simplex": noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
        "value": noise.noise_type = FastNoiseLite.TYPE_VALUE
```

## Terrain Generation

The terrain is a grid of tiles whose heights come from the noise function.

```gdscript
class_name NoiseTerrain extends Node3D

@export var grid_size: Vector2i = Vector2i(32, 32)
@export var tile_size: float = 0.5

var noise: FastNoiseLite
var tile_nodes: Array = []

func regenerate() -> void:
    for y in range(grid_size.y):
        for x in range(grid_size.x):
            var world_pos: Vector3 = Vector3(x, 0, y) * tile_size
            var noise_value: float = noise.get_noise_2d(world_pos.x, world_pos.z)
            var height: float = noise_value * params.amplitude * params.displacement
            if y < tile_nodes.size() and x < tile_nodes[y].size():
                tile_nodes[y][x].position.y = height
```

## Science Screen — Three Views

The science screen displays three synchronised views: 2D map, heightmap, and parameter list.

```gdscript
class_name NoiseScienceScreen extends Node3D

func redraw() -> void:
    draw_2d_map()
    draw_heightmap()
    draw_parameter_list()

func draw_2d_map() -> void:
    # Render the noise field as a colour image
    var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
    for y in range(128):
        for x in range(128):
            var v: float = noise.get_noise_2d(x * params.frequency, y * params.frequency)
            v = (v + 1.0) / 2.0  # map to [0,1]
            image.set_pixel(x, y, Color(v, v, v, 1.0))
    map_texture = ImageTexture.create_from_image(image)

func draw_heightmap() -> void:
    # Render a side-view slice of the terrain
    pass
```

## Configuration Gallery

A small gallery records saved terrains. Each save captures the current parameter values plus a screenshot.

```gdscript
class_name TerrainGallery extends Node3D

var saved_configs: Array = []

func save_current(params: Dictionary) -> void:
    var thumb: ImageTexture = capture_thumbnail()
    saved_configs.append({
        "params": params.duplicate(),
        "thumbnail": thumb,
        "saved_at": Time.get_datetime_string_from_system(),
    })
    add_gallery_entry(saved_configs.back())

func load_config(index: int) -> void:
    var config = saved_configs[index]
    for param_name in config.params:
        set_slider_value(param_name, config.params[param_name])
```

## Complexity

Terrain regeneration is O(grid_size²) and runs whenever a parameter changes. At 32×32 that is 1024 noise lookups; modern CPUs handle this in under a millisecond.

## Within the Sequence

Chamber_Noise is the only catalyst chamber without a creature. World-building is the practice it rewards.

## Save State Integration

The chamber's progress is tracked via the save manager. Befriending a creature, completing a configuration, or reaching a milestone is recorded in the learner's profile and becomes available in subsequent sessions.

```gdscript
func on_befriend_event(creature_name: String) -> void:
    var save = get_tree().get_first_node_in_group("save_manager")
    save.add_befriended_creature(creature_name)
    save.mark_milestone(chamber_id + "_befriended", Time.get_datetime_string_from_system())
```

## Performance Budget

The chamber's per-frame cost is dominated by creature animations and the science screen's rendering. Both are modest: the creature uses a vertex-displacement shader or a prebuilt animation, and the science screen redraws scatter points incrementally rather than from scratch each frame.

```gdscript
func _process(_delta: float) -> void:
    if science_screen.needs_redraw():
        science_screen.redraw_incremental()
```

## VR Comfort

The chamber avoids fast camera moves and sudden lighting changes. Projectiles fire from the learner's hand rather than from fixed spawners, so the learner controls the motion. The chamber's lighting is stable across the encounter; any changes happen gradually through creature state transitions.

## Accessibility

The chamber supports seated play: all interactive elements are within arm's reach, and the projectile direction is controllable from a single hand. The creature responds to either controller, so handedness is not a barrier.

## Within the Curriculum

This chamber is one of the curriculum's catalyst chambers — small, self-contained rooms where the sequence's accumulated vocabulary becomes relationship with a creature. The pattern is consistent across sequences: creature, catalyst (or its deliberate absence), science screen, return to Lab.

## Shared Noise Seed

Saved terrain configurations record their noise seed along with their parameters, so returning to a saved configuration recovers the exact terrain. Different seeds with the same parameters produce visually distinct but statistically equivalent outputs.

## Noise Seed Display

The current noise seed is visible on the parameter bench so learners can reproduce configurations they like.