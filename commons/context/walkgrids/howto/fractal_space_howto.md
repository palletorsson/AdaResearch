# FractalSpace — How to Use in Maps

## What It Is
Recursive fractal terrain using diamond-square, midpoint displacement, or custom recursive subdivision. Self-similar at every scale — zoom in and the terrain looks the same. Classic terrain generation algorithm.

## Scene Path
```
res://commons/context/walkgrids/fractal_space.tscn
```

## Drop Into a Map Scene

```gdscript
var fs = preload("res://commons/context/walkgrids/fractal_space.tscn").instantiate()
fs.algorithm = FractalSpace.FractalAlgorithm.DIAMOND_SQUARE
fs.fractal_depth = 5
fs.space_size = Vector2(25, 25)
fs.resolution = 80
fs.height_scale = 2.0
add_child(fs)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `algorithm` | DIAMOND_SQUARE | DIAMOND_SQUARE, MIDPOINT_DISPLACEMENT, RECURSIVE_SUBDIVISION |
| `fractal_depth` | 5 | Recursion depth (2-8). Grid size = 2^depth + 1 |
| `initial_displacement` | 2.0 | Starting random range |
| `roughness` | 0.5 | How much displacement shrinks per iteration (0.1-1.0) |
| `enable_animation` | false | Gentle wave motion on the surface |

## Algorithm Comparison

| Algorithm | Character | Speed |
|-----------|-----------|-------|
| DIAMOND_SQUARE | Smooth, realistic terrain — the classic | Fast |
| MIDPOINT_DISPLACEMENT | Rougher, more angular — more visible artifacts | Fast |
| RECURSIVE_SUBDIVISION | Even rougher — custom recursive layers | Fast |

## Map Integration Examples

### Fractals Map — Diamond-Square
```gdscript
func _ready():
    var fs = FractalSpace.new()
    fs.algorithm = FractalSpace.FractalAlgorithm.DIAMOND_SQUARE
    fs.fractal_depth = 6
    fs.roughness = 0.5
    fs.space_size = Vector2(30, 30)
    fs.height_scale = 3.0
    add_child(fs)
```

### Roughness Progression
```gdscript
# Show how roughness parameter changes the terrain character
var roughness_values = [0.2, 0.4, 0.6, 0.8, 1.0]
for i in range(roughness_values.size()):
    var fs = FractalSpace.new()
    fs.position.x = i * 25.0
    fs.roughness = roughness_values[i]
    fs.fractal_depth = 5
    fs.seed_value = 42
    fs.space_size = Vector2(20, 20)
    add_child(fs)
```

### Algorithm Comparison
```gdscript
for i in range(3):
    var fs = FractalSpace.new()
    fs.position.x = i * 28.0
    fs.algorithm = i  # DIAMOND_SQUARE, MIDPOINT, RECURSIVE
    fs.fractal_depth = 5
    fs.seed_value = 42
    fs.space_size = Vector2(24, 24)
    add_child(fs)
```

### Animated Fractal
```gdscript
var fs = FractalSpace.new()
fs.enable_animation = true
fs.animation_speed = 0.3
fs.animation_amplitude = 0.3
fs.height_scale = 2.0
add_child(fs)
```

## Teaching Suggestions
- `roughness` is the Hurst exponent — show how it controls self-similarity
- Diamond-square was the first real-time terrain generation algorithm (1982)
- Compare with NoiseSpace — fractal terrain is conceptually similar but uses subdivision instead of sampling
- `fractal_depth` directly controls the power-of-2 grid — good for teaching recursion

## Performance Notes
- Diamond-square at depth 6 = 65×65 grid — instant
- Depth 8 = 257×257 grid — still fast but mesh generation takes a moment
- Animation updates mesh every frame — keep resolution reasonable
