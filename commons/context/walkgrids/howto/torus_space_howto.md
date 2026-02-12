# TorusSpace — How to Use in Maps

## What It Is
A torus surface unwrapped onto a flat plane. The height field preserves curvature information — the inner ring (compressed) is tall, the outer ring (stretched) is flat. Six height modes show different aspects of toroidal topology.

## Scene Path
```
res://commons/context/walkgrids/torus_space.tscn
```

## Drop Into a Map Scene

```gdscript
var ts = preload("res://commons/context/walkgrids/torus_space.tscn").instantiate()
ts.height_mode = TorusSpace.TorusHeightMode.GAUSSIAN_CURVATURE
ts.space_size = Vector2(25, 25)
ts.resolution = 80
ts.height_scale = 2.0
add_child(ts)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `height_mode` | GAUSSIAN_CURVATURE | See height modes below |
| `major_radius` | 6.0 | Distance from center to tube center (R) |
| `minor_radius` | 2.0 | Tube radius (r) |
| `wave_frequency` | 3.0 | For wave modes |
| `wave_amplitude` | 0.5 | For wave modes |

## Height Modes

| Mode | Formula | Character |
|------|---------|-----------|
| GAUSSIAN_CURVATURE | K = cos(u) / (R(R+r·cos(u))) | Positive inner ring, negative outer — the actual curvature |
| ELEVATION | z = r·sin(u) | Z-coordinate of the torus surface |
| MERIDIAN_WAVES | Curvature + sin along small circles | Ribbed torus |
| PARALLEL_WAVES | Curvature + sin along large circles | Segmented torus |
| VILLARCEAU_CIRCLES | Oblique cross-sections | Linked-ring pattern |
| FLAT_TORUS | Clifford torus embedding | Gentle undulation (intrinsically flat!) |

## Map Integration Examples

### Space Topology Map
```gdscript
func _ready():
    var ts = TorusSpace.new()
    ts.height_mode = TorusSpace.TorusHeightMode.GAUSSIAN_CURVATURE
    ts.space_size = Vector2(30, 30)
    ts.major_radius = 8.0
    ts.minor_radius = 3.0
    ts.height_scale = 2.0
    add_child(ts)
```

### Height Mode Gallery
```gdscript
var modes = [
    TorusSpace.TorusHeightMode.GAUSSIAN_CURVATURE,
    TorusSpace.TorusHeightMode.ELEVATION,
    TorusSpace.TorusHeightMode.VILLARCEAU_CIRCLES,
    TorusSpace.TorusHeightMode.FLAT_TORUS,
]
for i in range(modes.size()):
    var ts = TorusSpace.new()
    ts.position.x = i * 28.0
    ts.height_mode = modes[i]
    ts.space_size = Vector2(24, 24)
    add_child(ts)
```

### Pac-Man Topology
```gdscript
# The torus IS Pac-Man's world — walk off one edge, appear on the other
# (You'd need to add teleport logic at the edges)
var ts = TorusSpace.new()
ts.height_mode = TorusSpace.TorusHeightMode.FLAT_TORUS
ts.height_scale = 0.5  # Nearly flat for gameplay
ts.space_size = Vector2(20, 20)
add_child(ts)
```

## Teaching Suggestions
- Gaussian curvature mode literally shows K > 0 (inner) vs K < 0 (outer)
- FLAT_TORUS teaches that intrinsic flatness ≠ extrinsic flatness
- Villarceau circles show non-obvious cross-sections of the torus
- The grid IS u×v parameter space — walking x = going around the tube, walking z = going around the ring

## Performance Notes
- All modes are pure trig — instant generation at any resolution
