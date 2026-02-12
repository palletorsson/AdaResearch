# ErosionSpace — How to Use in Maps

## What It Is
Starts with noise terrain, then simulates hydraulic erosion by dropping thousands of water particles. Each particle carries sediment downhill, depositing when it slows. River valleys, alluvial fans, canyon networks emerge.

## Scene Path
```
res://commons/context/walkgrids/erosion_space.tscn
```

## Drop Into a Map Scene

```gdscript
var es = preload("res://commons/context/walkgrids/erosion_space.tscn").instantiate()
es.space_size = Vector2(30, 30)
es.resolution = 100
es.num_droplets = 50000
es.height_scale = 3.0
add_child(es)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `num_droplets` | 50000 | Water particles to simulate (more = more erosion) |
| `droplet_lifetime` | 80 | Max steps per droplet |
| `erosion_rate` | 0.3 | How much sediment water picks up |
| `deposition_rate` | 0.3 | How much sediment water drops |
| `evaporation_rate` | 0.01 | Water loss per step |
| `gravity` | 4.0 | Downhill force |
| `inertia` | 0.1 | Momentum vs gradient (0 = follows slope exactly) |
| `erosion_radius` | 3 | Brush radius for erosion |
| `noise_scale` | 3.0 | Base terrain noise scale |
| `initial_height_scale` | 3.0 | Pre-erosion terrain amplitude |

## Map Integration Examples

### Terrain Generation Map — Before/After Erosion
```gdscript
func _ready():
    # Before: raw noise
    var raw = NoiseSpace.new()
    raw.space_size = Vector2(25, 25)
    raw.height_scale = 3.0
    raw.noise_scale = 3.0
    add_child(raw)
    
    # After: same noise + erosion
    var eroded = ErosionSpace.new()
    eroded.position.x = 30.0
    eroded.space_size = Vector2(25, 25)
    eroded.noise_scale = 3.0
    eroded.initial_height_scale = 3.0
    eroded.num_droplets = 80000
    eroded.seed_value = 42  # Same seed for fair comparison
    add_child(eroded)
```

### Erosion Intensity Progression
```gdscript
# Show increasing erosion: 0, 10K, 50K, 200K droplets
var counts = [0, 10000, 50000, 200000]
for i in range(counts.size()):
    var es = ErosionSpace.new()
    es.position.x = i * 28.0
    es.num_droplets = counts[i]
    es.space_size = Vector2(24, 24)
    es.seed_value = 42
    add_child(es)
```

### River Valley Landscape
```gdscript
var es = ErosionSpace.new()
es.space_size = Vector2(40, 40)
es.resolution = 120
es.num_droplets = 100000
es.erosion_rate = 0.4      # Aggressive erosion
es.deposition_rate = 0.2   # Less deposition = deeper valleys
es.inertia = 0.3           # Some momentum for meandering rivers
es.height_scale = 4.0
add_child(es)
```

### Gentle Erosion for Walkable Terrain
```gdscript
var es = ErosionSpace.new()
es.num_droplets = 30000
es.erosion_rate = 0.2
es.erosion_radius = 4       # Wide brush = smooth channels
es.initial_height_scale = 2.0
es.height_scale = 2.0
add_child(es)
```

## Teaching Suggestions
- Compare pre-erosion (NoiseSpace) with post-erosion (same seed) — the rivers appear
- `num_droplets = 0` gives you the raw noise terrain — increase to show geological time
- `inertia` controls meandering: 0 = straight downhill, 0.5 = river-like curves
- This is the same algorithm used in real-time terrain tools (Hydraulic erosion à la Hans Beyer)

## Performance Notes
- 50K droplets × 80 steps = 4M particle steps — takes ~2-4 seconds at resolution 100
- 200K droplets can take 10+ seconds — use for pre-baked maps
- Resolution affects both mesh AND erosion quality (particles move on the heightmap)
- No per-frame cost after generation
