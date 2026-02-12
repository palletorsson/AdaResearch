# MandelbrotSpace — How to Use in Maps

## What It Is
The Mandelbrot set as walkable terrain. Iteration count becomes elevation — the boundary of the set, where the algorithm struggles to decide convergence, becomes the highest ridges. Walk the edge of decidability.

## Scene Path
```
res://commons/context/walkgrids/mandelbrot_space.tscn
```

## Drop Into a Map Scene

```gdscript
var mb = preload("res://commons/context/walkgrids/mandelbrot_space.tscn").instantiate()
mb.space_size = Vector2(25, 25)
mb.resolution = 100
mb.preset_location = MandelbrotSpace.PresetLocation.FULL_SET
mb.max_iterations = 100
mb.height_scale = 2.0
add_child(mb)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `preset_location` | FULL_SET | FULL_SET, SEAHORSE_VALLEY, ELEPHANT_VALLEY, SPIRAL, MINI_BROT, LIGHTNING, CUSTOM |
| `center_real` | -0.5 | Real part of view center |
| `center_imag` | 0.0 | Imaginary part of view center |
| `zoom` | 1.5 | View zoom (smaller = more zoomed in) |
| `max_iterations` | 100 | Computation depth — higher = more detail at boundary |
| `interior_height` | 0.0 | Height for points inside the set (flat valleys) |
| `boundary_exaggeration` | 1.5 | How much to amplify the boundary ridges |
| `smooth_coloring` | true | Smooth iteration count (avoids stepped terrain) |

## Preset Locations

| Preset | center_real | center_imag | zoom | What You See |
|--------|-------------|-------------|------|-------------|
| FULL_SET | -0.5 | 0.0 | 1.5 | The classic view |
| SEAHORSE_VALLEY | -0.75 | 0.1 | 0.05 | Spiraling seahorse tails |
| ELEPHANT_VALLEY | 0.28 | 0.008 | 0.015 | Mini-brots in the antenna |
| SPIRAL | -0.7463 | 0.1102 | 0.005 | Double spiral |
| MINI_BROT | -1.768 | 0.001 | 0.02 | Tiny copy of the whole set |
| LIGHTNING | -0.170337 | 1.06506 | 0.006 | Filamentary structures |

## Map Integration Examples

### Fractals Map — Walk the Mandelbrot Boundary
```gdscript
func _ready():
    var mb = MandelbrotSpace.new()
    mb.preset_location = MandelbrotSpace.PresetLocation.FULL_SET
    mb.space_size = Vector2(30, 30)
    mb.max_iterations = 150
    mb.height_scale = 2.5
    mb.boundary_exaggeration = 2.0  # Dramatic ridges at the boundary
    add_child(mb)
```

### Zoom Progression — Multiple Scales Side by Side
```gdscript
# Show the same region at increasing zoom levels
var zooms = [1.5, 0.3, 0.06, 0.012]
for i in range(zooms.size()):
    var mb = MandelbrotSpace.new()
    mb.position.x = i * 28.0
    mb.preset_location = MandelbrotSpace.PresetLocation.CUSTOM
    mb.center_real = -0.75
    mb.center_imag = 0.1
    mb.zoom = zooms[i]
    mb.max_iterations = 100 + i * 50  # More iterations at deeper zoom
    mb.space_size = Vector2(24, 24)
    add_child(mb)
```

### Interactive Zoom
```gdscript
# Player can zoom in/out with triggers
var mb: MandelbrotSpace

func _ready():
    mb = MandelbrotSpace.new()
    mb.space_size = Vector2(25, 25)
    add_child(mb)

func _on_zoom_in():
    mb.zoom_in(0.5)  # Half the view = 2x zoom

func _on_zoom_out():
    mb.zoom_out(2.0)

func _on_pan(direction: Vector2):
    mb.pan(direction.x * 0.1, direction.y * 0.1)
```

### Low-Iteration vs High-Iteration Comparison
```gdscript
# Show how iteration count reveals boundary detail
for i in range(4):
    var mb = MandelbrotSpace.new()
    mb.position.x = i * 28.0
    mb.max_iterations = [10, 50, 200, 500][i]
    mb.space_size = Vector2(24, 24)
    add_child(mb)
```

## Teaching Suggestions
- Start with FULL_SET, explain iteration = "how long before we give up"
- The flat interior (iteration = max) IS the Mandelbrot set
- The ridges ARE the boundary — where computation is hardest
- Zoom into SEAHORSE_VALLEY to show self-similarity
- Compare `smooth_coloring = true` vs `false` to show banding artifacts

## Performance Notes
- Resolution 100 + iterations 100 is instant
- Resolution 100 + iterations 500 takes ~1 second
- Resolution 200 + iterations 1000 for pre-baked high-detail maps
- No animation overhead — it's a one-shot computation
