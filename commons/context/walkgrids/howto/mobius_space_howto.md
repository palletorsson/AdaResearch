# MöbiusSpace — How to Use in Maps

## What It Is
A Möbius strip projected into a walkable height field. The non-orientable surface where walking far enough flips your "up." Three projection modes preserve different aspects of the topology.

## Scene Path
```
res://commons/context/walkgrids/mobius_space.tscn
```

## Drop Into a Map Scene

```gdscript
var ms = preload("res://commons/context/walkgrids/mobius_space.tscn").instantiate()
ms.projection_mode = MobiusSpace.ProjectionMode.HEIGHT_MAP
ms.space_size = Vector2(25, 25)
ms.resolution = 80
ms.height_scale = 2.0
add_child(ms)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `projection_mode` | HEIGHT_MAP | HEIGHT_MAP, UNROLLED, CYLINDRICAL |
| `strip_radius` | 8.0 | Radius of the central ring |
| `strip_width` | 4.0 | Width of the walkable strip |
| `twist_count` | 1 | 1 = Möbius, 2 = full twist (orientable!), 3 = trefoil-like |
| `height_amplitude` | 0.5 | Surface wave detail |
| `flatten_factor` | 0.3 | 0 = true Möbius height, 1 = flat ring |

## Projection Modes

| Mode | What It Does | Best For |
|------|-------------|----------|
| HEIGHT_MAP | XZ position from strip surface, Y from Z-coordinate | Recognizable Möbius shape |
| UNROLLED | Strip unrolled flat, twist visible as height ripples | Showing the twist mathematically |
| CYLINDRICAL | Ring-like with twist encoded in bumps | Walking "around" the Möbius |

## Map Integration Examples

### Alternative Geometries Map
```gdscript
func _ready():
    var ms = MobiusSpace.new()
    ms.projection_mode = MobiusSpace.ProjectionMode.HEIGHT_MAP
    ms.strip_radius = 10.0
    ms.strip_width = 5.0
    ms.flatten_factor = 0.4  # Somewhat flattened for walkability
    ms.height_scale = 1.5
    ms.space_size = Vector2(30, 30)
    add_child(ms)
```

### Twist Progression
```gdscript
# Show 1-twist (Möbius), 2-twist (orientable), 3-twist
for i in range(3):
    var ms = MobiusSpace.new()
    ms.position.x = i * 28.0
    ms.twist_count = i + 1
    ms.space_size = Vector2(24, 24)
    add_child(ms)
```

### Projection Mode Comparison
```gdscript
var modes = [
    MobiusSpace.ProjectionMode.HEIGHT_MAP,
    MobiusSpace.ProjectionMode.UNROLLED,
    MobiusSpace.ProjectionMode.CYLINDRICAL,
]
for i in range(modes.size()):
    var ms = MobiusSpace.new()
    ms.position.x = i * 28.0
    ms.projection_mode = modes[i]
    ms.space_size = Vector2(24, 24)
    add_child(ms)
```

## Teaching Suggestions
- The material has `cull_mode = CULL_DISABLED` — appropriate for a one-sided surface
- Compare twist_count = 1 (non-orientable) vs 2 (orientable) to teach orientation
- `flatten_factor = 0` shows the true geometry but is hard to walk on
- Pair with the existing Möbius strip algorithm scene for comparison

## Performance Notes
- Static generation, no per-frame cost
- Trig functions per vertex — fast at any resolution
