# Random_Noise_Types - Technical Tutorial

## White Noise

White noise is the baseline—pure, unfiltered randomness.

```gdscript
# Generate white noise: each sample independent
func generate_white_noise(count: int) -> Array:
    var samples = []
    var rng = RandomNumberGenerator.new()
    rng.randomize()

    for i in range(count):
        samples.append(rng.randf())  # Uniform 0.0-1.0

    return samples

# Properties:
# - Flat power spectrum (all frequencies equal)
# - No correlation between samples
# - Maximum entropy per sample
# - Looks like TV static
```

### Visualizing White Noise

```gdscript
# White noise as point cloud
func scatter_white_noise(bounds: AABB, count: int):
    var rng = RandomNumberGenerator.new()
    rng.randomize()

    for i in range(count):
        var point = Vector3(
            rng.randf_range(bounds.position.x, bounds.end.x),
            rng.randf_range(bounds.position.y, bounds.end.y),
            rng.randf_range(bounds.position.z, bounds.end.z)
        )
        spawn_point_at(point)

# Result: points distributed uniformly but with visible clumping
# This is the "birthday paradox" of random placement
```

## Blue Noise

Blue noise is constrained randomness—samples maintain minimum distance.

```gdscript
# Poisson disk sampling for blue noise
func generate_blue_noise(bounds: AABB, min_distance: float) -> Array:
    var points = []
    var active_list = []
    var grid = {}  # Spatial hash for fast neighbor lookup
    var cell_size = min_distance / sqrt(3)  # 3D diagonal

    # Start with one random point
    var first = random_point_in_bounds(bounds)
    points.append(first)
    active_list.append(first)

    while active_list.size() > 0:
        # Pick random active point
        var idx = randi() % active_list.size()
        var point = active_list[idx]

        var found_valid = false
        for attempt in range(30):  # Try 30 candidates
            # Generate candidate in annulus [r, 2r] around point
            var candidate = generate_annulus_point(point, min_distance, min_distance * 2)

            if is_in_bounds(candidate, bounds) and has_no_neighbors(candidate, grid, min_distance):
                points.append(candidate)
                active_list.append(candidate)
                add_to_grid(candidate, grid, cell_size)
                found_valid = true
                break

        if not found_valid:
            active_list.remove_at(idx)

    return points
```

### Blue Noise Properties

```gdscript
# Blue noise distributes evenly without patterns
# - High frequencies emphasized (hence "blue")
# - No visible clumping
# - No visible patterns/grids
# - Optimal for sampling/dithering

# Comparison:
# White noise: random = unpredictable but clumpy
# Blue noise: random = unpredictable but evenly distributed
```

## The Noise Spectrum

Noise types named by color analogy to light:

| Noise Type | Low Freq | High Freq | Character |
|------------|----------|-----------|-----------|
| **White** | Equal | Equal | Pure chaos, flat spectrum |
| **Pink** | Higher | Lower | Natural, 1/f falloff |
| **Brown** | High | Low | Slow drift, random walk |
| **Blue** | Lower | Higher | Anti-clustering, sparse |
| **Violet** | Low | High | Derivative of white |

```gdscript
# Pink noise (1/f noise): common in nature
func generate_pink_noise(count: int) -> Array:
    # Multiple octaves of white noise, decreasing amplitude
    var octaves = 6
    var samples = []

    for i in range(count):
        var value = 0.0
        var amplitude = 1.0
        for oct in range(octaves):
            value += randf() * amplitude
            amplitude *= 0.5  # Each octave half the amplitude
        samples.append(value / 2.0)  # Normalize

    return samples
```

## Implementation Notes

### WhiteNoiseGallery
The `WhiteNoiseGallery` interactable displays white noise patterns in visual form—likely a texture or particle system where each pixel/particle is independent.

### NoiseColors3D
The `NoiseColors3D` interactable extends noise visualization into 3D color space, showing how different noise distributions create different color textures.

### The randompoint/randompoints Elements
These visualize the fundamental unit (single point) and collection (multiple points) of random spatial distribution.

## Key Takeaway

Not all randomness looks or behaves the same. White noise is maximum entropy—each sample independent, distributions clump by chance. Blue noise constrains randomness—maintaining distance while appearing unstructured. This distinction matters for:
- **Texture generation**: Blue noise creates better dithering
- **Sampling**: Blue noise avoids redundant samples
- **Perception**: Blue noise looks "more random" to humans despite being more structured

The paradox: **adding constraints can make randomness look more random**.

## Axiom References
- `commons/context/clipboard/tutorial_text/white_noise_axioms.md`
- `commons/context/clipboard/tutorial_text/blue_noise_axioms.md`
- `commons/context/clipboard/tutorial_text/noise_axioms.md`

## Within the Sequence

Random_Noise_Types distinguishes white noise from blue noise and sets up the coherent-noise techniques the Noise sequence will extend.

The per-frame cost of the map scales with the number of instanced artifacts and the resolution of the procedural effects. On typical consumer hardware the whole map runs at 60 frames per second with the default parameter ranges; pushing the parameters to their extremes can raise GPU load to the point where frame rate drops, and the map does not hide this from the learner. A corner indicator reads out the current frame time so the learner can observe the cost of their parameter choices.

Failure modes worth naming. A learner who pushes the sliders off the calibrated ranges can produce visually incoherent output — flickering surfaces, runaway growth, or flat featureless fields. The map's controls are clamped at safe bounds, but within those bounds the parameters still interact nonlinearly, and the nonlinear interactions are part of what the map rewards. Understanding the interactions requires running the parameters through their ranges rather than setting them once from a preset.

The map is one station in a longer arc. The artifacts it introduces reappear in later maps with extended parameter sets, composed behaviours, or different contextual framings. The learner who walks this map carefully carries a vocabulary the remaining sequence depends on, and the vocabulary is the map's concrete contribution to the curriculum.
