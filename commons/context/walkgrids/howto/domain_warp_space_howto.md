# DomainWarpSpace — How to Use in Maps

## What It Is
Feed noise into the coordinates of more noise — domain warping (Inigo Quilez technique). The result: organic, fluid, lava-lamp terrain where space folds back on itself. Also generates marble, wood grain, and crystalline patterns.

## Scene Path
```
res://commons/context/walkgrids/domain_warp_space.tscn
```

## Drop Into a Map Scene

```gdscript
var dw = preload("res://commons/context/walkgrids/domain_warp_space.tscn").instantiate()
dw.warp_style = DomainWarpSpace.WarpStyle.ORGANIC
dw.space_size = Vector2(25, 25)
dw.resolution = 80
dw.height_scale = 2.0
add_child(dw)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `warp_style` | ORGANIC | ORGANIC, CRYSTALLINE, TURBULENT, MARBLE, WOOD_GRAIN |
| `warp_strength` | 4.0 | How much the domain is distorted |
| `warp_layers` | 2 | Recursion depth (1=simple, 2=complex, 3=alien) |
| `noise_scale` | 3.0 | Base noise frequency |
| `octaves` | 4 | Noise detail layers |

## Warp Styles

| Style | Character | Material |
|-------|-----------|----------|
| ORGANIC | Smooth flowing — like fluid dynamics | Earthy green |
| CRYSTALLINE | Quantized angles — sharp folds | Steel grey-blue |
| TURBULENT | `abs()` warping — sharp creases | Warm brown |
| MARBLE | `sin(x + noise)` — classic marble texture | White/cream |
| WOOD_GRAIN | Concentric rings distorted by noise | Warm wood brown |

## Map Integration Examples

### Procedural Generation Map
```gdscript
func _ready():
    var dw = DomainWarpSpace.new()
    dw.warp_style = DomainWarpSpace.WarpStyle.ORGANIC
    dw.warp_layers = 2
    dw.warp_strength = 5.0
    dw.space_size = Vector2(30, 30)
    dw.height_scale = 2.5
    add_child(dw)
```

### Material Study — All 5 Styles
```gdscript
var styles = [
    DomainWarpSpace.WarpStyle.ORGANIC,
    DomainWarpSpace.WarpStyle.CRYSTALLINE,
    DomainWarpSpace.WarpStyle.TURBULENT,
    DomainWarpSpace.WarpStyle.MARBLE,
    DomainWarpSpace.WarpStyle.WOOD_GRAIN,
]
for i in range(styles.size()):
    var dw = DomainWarpSpace.new()
    dw.position.x = i * 25.0
    dw.warp_style = styles[i]
    dw.space_size = Vector2(20, 20)
    dw.seed_value = 42
    add_child(dw)
```

### Warp Layer Progression
```gdscript
# Show how each layer of warping adds complexity
for i in range(3):
    var dw = DomainWarpSpace.new()
    dw.position.x = i * 25.0
    dw.warp_layers = i + 1
    dw.warp_style = DomainWarpSpace.WarpStyle.ORGANIC
    dw.space_size = Vector2(20, 20)
    add_child(dw)
```

### Decorative Floor
```gdscript
# Marble floor for a gallery/museum map
var floor = DomainWarpSpace.new()
floor.warp_style = DomainWarpSpace.WarpStyle.MARBLE
floor.height_scale = 0.3      # Very subtle — it's a floor
floor.warp_strength = 3.0
floor.space_size = Vector2(40, 40)
add_child(floor)
```

## Teaching Suggestions
- Domain warping is THE technique behind most organic terrain in games
- Show `warp_layers = 1` then 2 then 3 — each adds a "dream within a dream" level
- MARBLE shows how `sin(x + noise)` creates classic material textures
- Compare ORGANIC (smooth warp) vs TURBULENT (abs warp) vs CRYSTALLINE (quantized warp)

## Performance Notes
- 3 noise samples per warp layer per vertex — warp_layers 3 = 9 noise calls per vertex
- Resolution 80 with warp_layers 2 is instant
- Resolution 100+ with warp_layers 3 is still fine (FastNoiseLite is fast)
