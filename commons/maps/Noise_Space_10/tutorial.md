# Noise Space 10

Ten parameters. The space of all possible noise.

Define the parameter space.

```gdscript
class_name NoiseParameters

var position: Vector3 = Vector3.ZERO
var time: float = 0.0
var octaves: int = 4
var persistence: float = 0.5
var lacunarity: float = 2.0
var frequency: float = 1.0
var amplitude: float = 1.0
var seed: int = 12345
```

Eight scalar parameters plus position (3D) and time. All controls exposed.

Configure a noise generator.

```gdscript
func apply_to(noise: FastNoiseLite, params: NoiseParameters) -> void:
    noise.seed = params.seed
    noise.fractal_octaves = params.octaves
    noise.fractal_gain = params.persistence
    noise.fractal_lacunarity = params.lacunarity
    noise.frequency = params.frequency
```

Map the parameter bag onto FastNoiseLite's fields. The generator's behaviour fully determined by these.

Sample at a position.

```gdscript
func sample(noise: FastNoiseLite, params: NoiseParameters) -> float:
    apply_to(noise, params)
    return noise.get_noise_3dv(params.position) * params.amplitude
```

One function; ten-dimensional input; scalar output.

Walk through parameter space.

```gdscript
var trajectory: Array = []

func step_through_space(param_name: String, target: float, duration: float) -> void:
    var start: float = current.get(param_name)
    var tween := create_tween()
    tween.tween_method(
        func(t): current.set(param_name, lerp(start, target, t)); record_trajectory(current); rerender()
    , 0.0, 1.0, duration)
```

Animate any single parameter while others stay fixed. The trajectory is a line in the 10D space.

Record a trajectory.

```gdscript
func record_trajectory(params: NoiseParameters) -> void:
    trajectory.append({
        "position": params.position,
        "octaves": params.octaves,
        "persistence": params.persistence,
        # ... other params
    })
```

Stores a snapshot of each step. Lets the learner replay the traversal.

Save preset.

```gdscript
func save_preset(name: String, params: NoiseParameters) -> void:
    var preset_data: Dictionary = {
        "octaves": params.octaves,
        "persistence": params.persistence,
        "lacunarity": params.lacunarity,
        "frequency": params.frequency,
        "amplitude": params.amplitude,
        "seed": params.seed,
    }
    presets[name] = preset_data
```

Named configurations. The learner builds a library of interesting points in the space.

Load preset.

```gdscript
func load_preset(name: String) -> NoiseParameters:
    var data := presets.get(name, {})
    var params := NoiseParameters.new()
    for key in data:
        params.set(key, data[key])
    return params
```

Reverse of save. The learner can jump to any saved point.

You can now define a noise parameter bag, apply it to a generator, walk through parameter space with tweens, record trajectories, and save/load presets. Noise_Perlin_Simplex extends into algorithm comparison.

Clamp to valid range.

```gdscript
func clamp_noise(value: float, low: float = -1.0, high: float = 1.0) -> float:
    return clamp(value, low, high)
```

Guarantees output stays in the expected range. Useful before writing to textures.
