# WaveInterferenceSpace — How to Use in Maps

## What It Is
Multiple wave sources create constructive and destructive interference patterns as animated terrain. Walk through the physics of superposition — where waves meet, the ground rises or cancels.

## Scene Path
```
res://commons/context/walkgrids/wave_interference_space.tscn
```

## Drop Into a Map Scene

```gdscript
var wi = preload("res://commons/context/walkgrids/wave_interference_space.tscn").instantiate()
wi.wave_type = WaveInterferenceSpace.WaveType.DOUBLE_SLIT
wi.space_size = Vector2(25, 25)
wi.resolution = 80
wi.height_scale = 1.5
wi.enable_animation = true
add_child(wi)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `wave_type` | CIRCULAR | CIRCULAR, PLANE, MIXED, DOUBLE_SLIT, RIPPLE_TANK |
| `num_sources` | 5 | Number of wave sources |
| `base_frequency` | 2.0 | Wave frequency |
| `damping` | 0.02 | Distance decay (higher = waves die faster) |
| `wave_speed` | 1.0 | Propagation speed |
| `enable_animation` | true | Waves move in real-time |
| `animation_speed` | 1.0 | How fast waves propagate |
| `time_snapshot` | 0.0 | Frozen moment (when animation is off) |

## Wave Types

| Type | Sources | What You See |
|------|---------|-------------|
| CIRCULAR | N random points | Ripples expanding from random positions |
| PLANE | N directions | Parallel wave fronts at different angles |
| DOUBLE_SLIT | 2 coherent points | Classic interference fringes |
| MIXED | Mix of circular + plane | Complex realistic interference |
| RIPPLE_TANK | 1 center + 4 reflections | Waves bouncing off walls |

## Map Integration Examples

### Physics / Oscillation Map — Double Slit
```gdscript
func _ready():
    var wi = WaveInterferenceSpace.new()
    wi.wave_type = WaveInterferenceSpace.WaveType.DOUBLE_SLIT
    wi.space_size = Vector2(30, 30)
    wi.base_frequency = 3.0
    wi.damping = 0.01          # Low damping so pattern extends far
    wi.enable_animation = true
    wi.animation_speed = 0.5   # Slow enough to see the fringes form
    wi.height_scale = 1.2
    add_child(wi)
```

### Frozen Snapshot for Analysis
```gdscript
# Static terrain showing interference at a specific moment
var wi = WaveInterferenceSpace.new()
wi.wave_type = WaveInterferenceSpace.WaveType.CIRCULAR
wi.num_sources = 3
wi.enable_animation = false
wi.time_snapshot = 5.0  # Frozen at t=5
wi.height_scale = 2.0
add_child(wi)
```

### Interactive: Add Sources on Click
```gdscript
var wi: WaveInterferenceSpace

func _ready():
    wi = WaveInterferenceSpace.new()
    wi.wave_type = WaveInterferenceSpace.WaveType.CIRCULAR
    wi.num_sources = 0  # Start empty
    wi.enable_animation = true
    add_child(wi)

func _on_point_clicked(world_pos: Vector3):
    wi.add_source(Vector2(world_pos.x, world_pos.z), 2.5, 1.0)
```

### Wave Type Comparison
```gdscript
var types = [
    WaveInterferenceSpace.WaveType.CIRCULAR,
    WaveInterferenceSpace.WaveType.PLANE,
    WaveInterferenceSpace.WaveType.DOUBLE_SLIT,
    WaveInterferenceSpace.WaveType.RIPPLE_TANK,
]
for i in range(types.size()):
    var wi = WaveInterferenceSpace.new()
    wi.position.x = i * 28.0
    wi.wave_type = types[i]
    wi.space_size = Vector2(24, 24)
    wi.enable_animation = true
    wi.animation_speed = 0.8
    add_child(wi)
```

## Teaching Suggestions
- DOUBLE_SLIT is the money shot — shows quantum-like behavior from classical waves
- Start with 1 source (CIRCULAR, num_sources=1), add sources to show superposition
- Freeze animation to let students walk along nodes (zero-height lines) and antinodes
- Compare CIRCULAR (isotropic) vs PLANE (anisotropic) for wave physics lessons

## Performance Notes
- Animated waves regenerate the mesh every frame — keep resolution ≤ 80
- Collision updated every 0.5 seconds (not every frame)
- `num_sources` > 10 is fine — wave computation is O(sources × vertices)
- `damping = 0` means waves never die — can create tall peaks far from sources
