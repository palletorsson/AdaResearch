# Random_Gaussian - Technical Documentation

## Core Concept in Code

### Generating Gaussian Random Numbers

GDScript provides `randfn()` for Gaussian random values, but understanding the Box-Muller transform is essential:

```gdscript
# Box-Muller transform: uniform → Gaussian
func gaussian_random(mean: float = 0.0, std_dev: float = 1.0) -> float:
    var u1 = randf()
    var u2 = randf()

    # Avoid log(0) edge case
    while u1 == 0:
        u1 = randf()

    var z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
    return mean + z0 * std_dev

# Generate values clustered around 100 with std_dev of 15
var iq_score = gaussian_random(100.0, 15.0)
```

### Using Godot's Built-in Gaussian

```gdscript
var rng = RandomNumberGenerator.new()
rng.randomize()

# randfn(mean, deviation) - returns Gaussian random
var value = rng.randfn(0.0, 1.0)  # Standard normal: mean=0, std=1
```

## Implementation Details

### GaussianBlurShader

The blur shader applies a Gaussian kernel to pixels. The kernel weights follow the bell curve:

```gdscript
# 1D Gaussian kernel generation
func generate_gaussian_kernel(size: int, sigma: float) -> Array:
    var kernel = []
    var sum = 0.0
    var center = size / 2

    for i in range(size):
        var x = i - center
        var weight = exp(-(x * x) / (2.0 * sigma * sigma))
        kernel.append(weight)
        sum += weight

    # Normalize so weights sum to 1
    for i in range(size):
        kernel[i] /= sum

    return kernel
```

In shader code (GLSL/Godot shader):
```glsl
// Separable Gaussian blur - horizontal pass
float gaussian_weight(float x, float sigma) {
    return exp(-(x * x) / (2.0 * sigma * sigma));
}

void fragment() {
    vec4 color = vec4(0.0);
    float total_weight = 0.0;
    float sigma = 2.0;

    for (int i = -5; i <= 5; i++) {
        float weight = gaussian_weight(float(i), sigma);
        color += texture(TEXTURE, UV + vec2(float(i) * TEXTURE_PIXEL_SIZE.x, 0.0)) * weight;
        total_weight += weight;
    }

    COLOR = color / total_weight;
}
```

### GaussianPaintSplatter

Splatter positions are generated with Gaussian distribution around a center point:

```gdscript
func create_splatter(center: Vector2, count: int, spread: float) -> Array:
    var points = []
    var rng = RandomNumberGenerator.new()
    rng.randomize()

    for i in range(count):
        # Gaussian offset from center
        var offset_x = rng.randfn(0.0, spread)
        var offset_y = rng.randfn(0.0, spread)
        points.append(center + Vector2(offset_x, offset_y))

    return points

# Most splatter lands near center, fewer at edges
var splatter = create_splatter(Vector2(512, 512), 1000, 50.0)
```

### random_decay_objects

Objects decay with Gaussian probability over time:

```gdscript
var decay_mean = 5.0      # Average lifetime in seconds
var decay_std = 1.5       # Variation in lifetime
var lifetime: float

func _ready():
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    # Each object gets its own lifetime from Gaussian distribution
    lifetime = max(0.5, rng.randfn(decay_mean, decay_std))

func _process(delta):
    lifetime -= delta
    if lifetime <= 0:
        decay()
```

## Map-Specific Configuration

### Structure Array Analysis
- 12×13 grid (12 columns, 13 rows)
- Perimeter walls at heights 2-3 create enclosed arena
- Exit gap at position (8,12) with height 0

### Interactable Positioning
Demonstrations arranged for progressive discovery:
- Northwest: theoretical (clipboard, blur shader)
- Center: contemplation zone (dark_sphere)
- Central-south: artistic application (splatter)
- Southeast: temporal and generative (decay, gaussian_random)

## Key Takeaways

1. **Gaussian emerges from accumulation** - Central Limit Theorem explains ubiquity
2. **Box-Muller bridges uniform to Gaussian** - computational technique for generating bell curves
3. **Same math, different domains** - blur, splatter, decay all use Gaussian
4. **68-95-99.7 rule** - predictable clustering around mean

## Related Systems
- `RandomNumberGenerator.randfn()` - Godot's built-in Gaussian
- `FastNoiseLite` - uses Gaussian in some noise generation modes
- Particle systems often use Gaussian for natural-looking spread

## Within the Sequence

Random_Gaussian is the sequence's introduction to non-uniform distributions. The Gaussian sample machinery, and the Box-Muller transform that produces it, is the foundation for every later map where normal-distribution sampling appears.

The per-frame cost of the map scales with the number of instanced artifacts and the resolution of the procedural effects. On typical consumer hardware the whole map runs at 60 frames per second with the default parameter ranges; pushing the parameters to their extremes can raise GPU load to the point where frame rate drops, and the map does not hide this from the learner. A corner indicator reads out the current frame time so the learner can observe the cost of their parameter choices.

Failure modes worth naming. A learner who pushes the sliders off the calibrated ranges can produce visually incoherent output — flickering surfaces, runaway growth, or flat featureless fields. The map's controls are clamped at safe bounds, but within those bounds the parameters still interact nonlinearly, and the nonlinear interactions are part of what the map rewards. Understanding the interactions requires running the parameters through their ranges rather than setting them once from a preset.

The map is one station in a longer arc. The artifacts it introduces reappear in later maps with extended parameter sets, composed behaviours, or different contextual framings. The learner who walks this map carefully carries a vocabulary the remaining sequence depends on, and the vocabulary is the map's concrete contribution to the curriculum.
