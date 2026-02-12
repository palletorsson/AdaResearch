# SineSpace — How to Use in Maps

## What It Is
Perfect mathematical sine/cosine waves as walkable terrain. Smooth, metallic, totally predictable — every point calculable from its coordinates. The surveillance landscape.

## Scene Path
```
res://commons/context/walkgrids/sine_space.tscn
```

## Drop Into a Map Scene

```gdscript
var ss = preload("res://commons/context/walkgrids/sine_space.tscn").instantiate()
ss.space_size = Vector2(25, 25)
ss.resolution = 80
ss.wave_frequency = 1.2
ss.wave_amplitude = 0.7
ss.height_scale = 2.0
add_child(ss)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `wave_frequency` | 1.2 | How tight the waves are (higher = more hills) |
| `wave_amplitude` | 0.7 | How tall the waves are |
| `phase_x` | 0.0 | Wave offset in X |
| `phase_z` | 0.0 | Wave offset in Z |
| `height_scale` | 2.0 | Global height multiplier |

## Formula
```
height = amplitude * sin(x * frequency + phase_x) * cos(z * frequency + phase_z)
```

## Map Integration Examples

### Oscillation / Wave Functions Map
```gdscript
func _ready():
    var ss = SineSpace.new()
    ss.wave_frequency = 1.5
    ss.wave_amplitude = 1.0
    ss.space_size = Vector2(30, 30)
    ss.height_scale = 2.0
    add_child(ss)
```

### Frequency Progression
```gdscript
# Show what frequency does — from slow rolls to tight ripples
var freqs = [0.3, 0.8, 1.5, 3.0, 6.0]
for i in range(freqs.size()):
    var ss = SineSpace.new()
    ss.position.x = i * 25.0
    ss.wave_frequency = freqs[i]
    ss.wave_amplitude = 0.8
    ss.space_size = Vector2(20, 20)
    add_child(ss)
```

### Flat Reference Surface
```gdscript
# Use as a perfectly flat floor for comparison
var flat = SineSpace.new()
flat.wave_amplitude = 0.0  # No waves = flat plane
flat.space_size = Vector2(30, 30)
add_child(flat)
```

### Phase Animation (manual)
```gdscript
var ss: SineSpace

func _ready():
    ss = SineSpace.new()
    ss.space_size = Vector2(25, 25)
    add_child(ss)

func _process(delta):
    ss.phase_x += delta * 2.0
    ss.generate_space()  # Regenerate with new phase
```

## Teaching Suggestions
- The simplest walkgrid — start here, then show what happens when you add complexity
- `amplitude = 0` gives a flat plane — the mathematical zero state
- Compare with NoiseSpace: sine is deterministic, noise is stochastic
- Phase shifting shows wave propagation
- `sin(x) * cos(z)` creates a 2D egg-carton pattern — explain why

## Performance Notes
- Pure trig — the fastest space to generate
- Safe to regenerate every frame for animation
- Use as baseline for performance comparisons
