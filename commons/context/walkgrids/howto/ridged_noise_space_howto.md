# RidgedNoiseSpace — How to Use in Maps

## What It Is
Ridged multifractal noise — standard noise folded with `abs()` to create sharp ridges. The result: mountain ranges, canyon networks, dragon spines. Layered octaves create eerily realistic geology.

## Scene Path
```
res://commons/context/walkgrids/ridged_noise_space.tscn
```

## Drop Into a Map Scene

```gdscript
var rn = preload("res://commons/context/walkgrids/ridged_noise_space.tscn").instantiate()
rn.terrain_type = RidgedNoiseSpace.TerrainType.MOUNTAIN_RANGE
rn.space_size = Vector2(30, 30)
rn.resolution = 80
rn.height_scale = 3.0
add_child(rn)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `terrain_type` | MOUNTAIN_RANGE | MOUNTAIN_RANGE, CANYON_NETWORK, DRAGON_SPINE, ERODED_PLATEAU, ALIEN_GEOLOGY |
| `noise_scale` | 3.0 | Feature size |
| `octaves` | 6 | Detail layers |
| `lacunarity` | 2.0 | Frequency multiplier per octave |
| `gain` | 0.5 | Amplitude decay per octave |
| `ridge_offset` | 1.0 | Ridge sharpness control |
| `ridge_power` | 2.0 | Exponent for ridge shaping |
| `erosion_strength` | 0.3 | Simulated erosion (0 = none) |
| `terrace_count` | 0 | Quantize into terrace steps (0 = off) |

## Terrain Types

| Type | Character | Best For |
|------|-----------|----------|
| MOUNTAIN_RANGE | Sharp ridges with smooth valleys | Geology, terrain generation lessons |
| CANYON_NETWORK | Inverted — ridges become canyons | Exploring negative space |
| DRAGON_SPINE | Sharp peaks, flat valleys | Dramatic obstacle courses |
| ERODED_PLATEAU | Flat mesa tops with eroded edges | Layered rock formations |
| ALIEN_GEOLOGY | Multiple noise types combined | Speculative terrain |

## Map Integration Examples

### Terrain Generation Map
```gdscript
func _ready():
    var rn = RidgedNoiseSpace.new()
    rn.terrain_type = RidgedNoiseSpace.TerrainType.MOUNTAIN_RANGE
    rn.space_size = Vector2(40, 40)
    rn.octaves = 6
    rn.height_scale = 4.0
    rn.erosion_strength = 0.4
    add_child(rn)
```

### Terraced Landscape
```gdscript
# Rice paddy / mesa terrain
var rn = RidgedNoiseSpace.new()
rn.terrain_type = RidgedNoiseSpace.TerrainType.ERODED_PLATEAU
rn.terrace_count = 8  # 8 distinct height levels
rn.height_scale = 3.0
rn.space_size = Vector2(30, 30)
add_child(rn)
```

### Terrain Type Comparison
```gdscript
var types = [
    RidgedNoiseSpace.TerrainType.MOUNTAIN_RANGE,
    RidgedNoiseSpace.TerrainType.CANYON_NETWORK,
    RidgedNoiseSpace.TerrainType.DRAGON_SPINE,
    RidgedNoiseSpace.TerrainType.ERODED_PLATEAU,
    RidgedNoiseSpace.TerrainType.ALIEN_GEOLOGY,
]
for i in range(types.size()):
    var rn = RidgedNoiseSpace.new()
    rn.position.x = i * 35.0
    rn.terrain_type = types[i]
    rn.space_size = Vector2(30, 30)
    rn.seed_value = 42
    add_child(rn)
```

### Dramatic Backdrop
```gdscript
# Large-scale mountain range behind the map
var mountains = RidgedNoiseSpace.new()
mountains.space_size = Vector2(100, 40)
mountains.height_scale = 8.0
mountains.terrain_type = RidgedNoiseSpace.TerrainType.MOUNTAIN_RANGE
mountains.position = Vector3(0, -2, -30)  # Behind and below
add_child(mountains)
```

## Teaching Suggestions
- Compare with NoiseSpace to show what `abs()` folding does
- `terrace_count` demonstrates quantization / step functions
- `erosion_strength` shows how secondary processes modify primary generation
- CANYON_NETWORK is just `-1 × MOUNTAIN_RANGE` — teach sign inversion

## Performance Notes
- Static generation — no per-frame cost
- Resolution 100 + 6 octaves is instant
- `space_size` can be very large (100×100) with resolution 150 for backdrop mountains
