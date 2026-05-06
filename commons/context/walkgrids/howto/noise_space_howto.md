# NoiseSpace — How to Use in Maps

## What It Is
FastNoiseLite fractal noise as walkable terrain. Rough, organic, unpredictable — where algorithmic prediction fails. The resistance landscape.

## Scene Path
```
res://commons/context/walkgrids/noise_space.tscn
```

## Drop Into a Map Scene

```gdscript
var ns = preload("res://commons/context/walkgrids/noise_space.tscn").instantiate()
ns.space_size = Vector2(25, 25)
ns.resolution = 80
ns.noise_scale = 5.0
ns.height_scale = 2.0
add_child(ns)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `noise_scale` | 5.0 | Feature scale (higher = more detail) |
| `octaves` | 4 | Fractal layers (more = richer detail) |
| `persistence` | 0.5 | How much each octave contributes |
| `height_scale` | 2.0 | Global height multiplier |

## Map Integration Examples

### Noise / Randomness Map
```gdscript
func _ready():
    var ns = NoiseSpace.new()
    ns.noise_scale = 4.0
    ns.octaves = 5
    ns.space_size = Vector2(30, 30)
    ns.height_scale = 2.5
    add_child(ns)
```

### Octave Progression
```gdscript
# Show how octaves add detail: 1, 2, 3, 4, 6 octaves
var octave_counts = [1, 2, 3, 4, 6]
for i in range(octave_counts.size()):
    var ns = NoiseSpace.new()
    ns.position.x = i * 25.0
    ns.octaves = octave_counts[i]
    ns.noise_scale = 4.0
    ns.space_size = Vector2(20, 20)
    add_child(ns)
```

### Sine vs Noise Comparison
```gdscript
# Deterministic vs stochastic — the core contrast
var ss = SineSpace.new()
ss.wave_frequency = 1.5
ss.space_size = Vector2(20, 20)
add_child(ss)

var ns = NoiseSpace.new()
ns.position.x = 25.0
ns.noise_scale = 4.0
ns.space_size = Vector2(20, 20)
add_child(ns)
```

### Gentle Terrain Floor
```gdscript
var ns = NoiseSpace.new()
ns.noise_scale = 2.0      # Large features
ns.octaves = 3             # Not too much detail
ns.height_scale = 0.8      # Subtle — walkable
ns.space_size = Vector2(40, 40)
add_child(ns)
```

## Teaching Suggestions
- The workhorse terrain generator — most game terrain starts here
- Compare 1 octave (smooth blobs) with 6 octaves (rich detail)
- `persistence` controls self-similarity: 0.5 = natural, 1.0 = all octaves equal
- Pair with SineSpace to teach deterministic vs stochastic
- Show that noise IS random but coherent — unlike RandomSpace which is pure chaos

## Performance Notes
- FastNoiseLite is highly optimized — fast at any resolution
- Static generation — no per-frame cost
- Scale 2.0 with octaves 6 at resolution 100 is instant
