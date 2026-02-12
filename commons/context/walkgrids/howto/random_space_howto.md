# RandomSpace — How to Use in Maps

## What It Is
Pure mathematical chaos — every vertex height is independently random. Animated with four modes (wave, ripple, random walk, chaotic). The most aggressive, unpredictable terrain. Mathematical anarchy.

## Scene Path
```
res://commons/context/walkgrids/random_space.tscn
```

## Drop Into a Map Scene

```gdscript
var rs = preload("res://commons/context/walkgrids/random_space.tscn").instantiate()
rs.space_size = Vector2(25, 25)
rs.resolution = 60
rs.chaos_level = 2.0
rs.enable_animation = true
rs.animation_type = RandomSpace.AnimationType.WAVE
add_child(rs)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `chaos_level` | 2.0 | Height range of randomness |
| `enable_animation` | true | Animate the surface |
| `animation_type` | WAVE | WAVE, RIPPLE, RANDOM_WALK, CHAOTIC |
| `animation_speed` | 1.0 | Animation rate |
| `animation_amplitude` | 0.5 | Animation intensity |
| `update_frequency` | 30.0 | Mesh updates per second |
| `collision_update_interval` | 0.5 | Collision update interval (seconds) |
| `use_trimesh_collision` | true | Accurate collision (vs convex approximation) |

## Animation Types

| Type | Character |
|------|-----------|
| WAVE | Smooth sine waves over the random base |
| RIPPLE | Expanding ripples from center |
| RANDOM_WALK | Smooth chaotic drift |
| CHAOTIC | Combined oscillations — most unpredictable |

## Map Integration Examples

### Randomness Map — Pure Chaos Floor
```gdscript
func _ready():
    var rs = RandomSpace.new()
    rs.chaos_level = 1.5
    rs.enable_animation = true
    rs.animation_type = RandomSpace.AnimationType.CHAOTIC
    rs.animation_speed = 0.5
    rs.space_size = Vector2(25, 25)
    add_child(rs)
```

### Static Random Terrain
```gdscript
var rs = RandomSpace.new()
rs.enable_animation = false  # Frozen chaos
rs.chaos_level = 1.0
rs.height_scale = 1.5
add_child(rs)
```

### Animation Type Gallery
```gdscript
var types = [
    RandomSpace.AnimationType.WAVE,
    RandomSpace.AnimationType.RIPPLE,
    RandomSpace.AnimationType.RANDOM_WALK,
    RandomSpace.AnimationType.CHAOTIC,
]
for i in range(types.size()):
    var rs = RandomSpace.new()
    rs.position.x = i * 28.0
    rs.animation_type = types[i]
    rs.enable_animation = true
    rs.space_size = Vector2(24, 24)
    add_child(rs)
```

### Noise vs Random Comparison
```gdscript
# Coherent randomness vs pure randomness
var ns = NoiseSpace.new()
ns.space_size = Vector2(20, 20)
add_child(ns)

var rs = RandomSpace.new()
rs.position.x = 25.0
rs.enable_animation = false
rs.space_size = Vector2(20, 20)
add_child(rs)
# Noise = smooth hills. Random = jagged chaos. Both are "random" — different kind.
```

### Gentle Ambient Motion
```gdscript
var rs = RandomSpace.new()
rs.chaos_level = 0.5       # Low chaos = gentle terrain
rs.enable_animation = true
rs.animation_type = RandomSpace.AnimationType.WAVE
rs.animation_speed = 0.3
rs.animation_amplitude = 0.2  # Subtle breathing
add_child(rs)
```

## Runtime Controls
```gdscript
var rs = $RandomSpace
rs.set_animation_type(RandomSpace.AnimationType.RIPPLE)
rs.set_animation_speed(2.0)
rs.toggle_animation()
rs.reset_animation()
print(rs.get_animation_info())
```

## Teaching Suggestions
- Compare with NoiseSpace: noise has spatial coherence, RandomSpace doesn't
- Show `chaos_level` progression from 0.1 (barely bumpy) to 5.0 (unwalkable)
- Animation modes demonstrate how even random bases can carry organized motion
- The visual/physical discomfort of walking on random terrain IS the lesson

## Performance Notes
- Animation updates mesh 30× per second by default — keep resolution ≤ 60 for VR
- Collision updates every 0.5s — separate from mesh updates for performance
- LOD system reduces detail for distant players automatically
- `update_frequency = 15` for VR if performance is tight
