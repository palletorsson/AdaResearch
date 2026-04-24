# Chamber Noise

The only chamber without a creature. Sculpt terrain.

Build the parameter bench.

```gdscript
class_name NoiseParameterBench extends Node3D

@export var noise: FastNoiseLite

func expose_sliders() -> void:
    spawn_slider("frequency", 0.01, 1.0, noise.frequency)
    spawn_slider("amplitude", 0.1, 2.0, current_amplitude)
    spawn_slider("octaves", 1, 8, noise.fractal_octaves)
    spawn_slider("persistence", 0.1, 0.9, noise.fractal_gain)
    spawn_slider("displacement", 0.0, 2.0, current_displacement)
```

Five sliders for the most useful parameters. Each updates the terrain live.

Bind slider to parameter.

```gdscript
func _on_slider_changed(param_name: String, value: float) -> void:
    match param_name:
        "frequency": noise.frequency = value
        "amplitude": current_amplitude = value
        "octaves": noise.fractal_octaves = int(value)
        "persistence": noise.fractal_gain = value
        "displacement": current_displacement = value
    terrain.regenerate()
```

Slider callback updates the matching parameter; terrain regenerates.

Switch distributions.

```gdscript
enum Distribution { PERLIN, SIMPLEX, VALUE }

@export var distribution: Distribution = Distribution.PERLIN

func set_distribution(new_dist: Distribution) -> void:
    distribution = new_dist
    match distribution:
        Distribution.PERLIN: noise.noise_type = FastNoiseLite.TYPE_PERLIN
        Distribution.SIMPLEX: noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
        Distribution.VALUE: noise.noise_type = FastNoiseLite.TYPE_VALUE
    terrain.regenerate()
```

Three noise types. Each gives the ground a different grain.

Save a terrain.

```gdscript
var saved_terrains: Array = []

func save_current() -> void:
    var config: Dictionary = {
        "frequency": noise.frequency,
        "amplitude": current_amplitude,
        "octaves": noise.fractal_octaves,
        "persistence": noise.fractal_gain,
        "seed": noise.seed,
        "displacement": current_displacement,
        "distribution": distribution,
        "timestamp": Time.get_datetime_string_from_system(),
    }
    saved_terrains.append(config)
```

One entry per save. The gallery grows as the learner makes more terrains.

Load a terrain.

```gdscript
func load_terrain(index: int) -> void:
    var config: Dictionary = saved_terrains[index]
    noise.frequency = config.frequency
    noise.fractal_octaves = config.octaves
    noise.fractal_gain = config.persistence
    noise.seed = config.seed
    current_amplitude = config.amplitude
    current_displacement = config.displacement
    set_distribution(config.distribution)
    terrain.regenerate()
```

Sets every parameter from the saved config. The terrain instantly matches the saved shape.

Display science screen.

```gdscript
class_name NoiseScienceScreen extends Node3D

@export var bench: NoiseParameterBench

func update_display() -> void:
    render_2d_heatmap(bench.noise)
    render_heightmap_slice(bench.noise)
    render_parameter_list(bench.get_current_config())
```

Three views at once: 2D heatmap, 1D slice, parameter list. The terrain is readable as data.

You can now build a noise parameter bench with live sliders, switch distributions, save and load terrains, and display the results on a science screen. The Noise sequence hands the learner back to the Lab with the noise sculpting toolkit.

Clamp to valid range.

```gdscript
func clamp_noise(value: float, low: float = -1.0, high: float = 1.0) -> float:
    return clamp(value, low, high)
```

Guarantees output stays in the expected range. Useful before writing to textures.
