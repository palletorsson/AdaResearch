# FlowFieldSpace — How to Use in Maps

## What It Is
A 2D vector field's potential energy becomes elevation. Vortices create hills, sources push up, sinks pull down. Walk the landscape of forces — the terrain IS the field.

## Scene Path
```
res://commons/context/walkgrids/flow_field_space.tscn
```

## Drop Into a Map Scene

```gdscript
var ff = preload("res://commons/context/walkgrids/flow_field_space.tscn").instantiate()
ff.field_type = FlowFieldSpace.FieldType.VORTEX_ARRAY
ff.space_size = Vector2(25, 25)
ff.resolution = 80
ff.height_scale = 2.0
add_child(ff)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `field_type` | VORTEX_ARRAY | VORTEX_ARRAY, SOURCE_SINK, DIPOLE_FIELD, GRADIENT_NOISE, SADDLE_POINTS, ELECTROMAGNETIC |
| `num_elements` | 6 | Number of field sources |
| `field_strength` | 1.5 | Overall force strength |

## Field Types

| Type | Potential | Character |
|------|-----------|-----------|
| VORTEX_ARRAY | −Γ·ln(r) | Spinning whirlpools — log height around each vortex |
| SOURCE_SINK | Q·ln(r) | Alternating hills (sources) and pits (sinks) |
| DIPOLE_FIELD | Paired source/sink | Magnetic-like field lines as terrain |
| GRADIENT_NOISE | Noise as stream function | Divergence-free flow — organic hills |
| SADDLE_POINTS | x²−y² (rotated) | Hyperbolic passes between hills |
| ELECTROMAGNETIC | 1/r + angular | Combined radial + tangential — spiral terrain |

## Map Integration Examples

### Forces / Vectors Map
```gdscript
func _ready():
    var ff = FlowFieldSpace.new()
    ff.field_type = FlowFieldSpace.FieldType.VORTEX_ARRAY
    ff.num_elements = 4
    ff.field_strength = 2.0
    ff.space_size = Vector2(30, 30)
    ff.height_scale = 2.5
    add_child(ff)
```

### Field Type Gallery
```gdscript
var types = [
    FlowFieldSpace.FieldType.VORTEX_ARRAY,
    FlowFieldSpace.FieldType.SOURCE_SINK,
    FlowFieldSpace.FieldType.DIPOLE_FIELD,
    FlowFieldSpace.FieldType.SADDLE_POINTS,
    FlowFieldSpace.FieldType.ELECTROMAGNETIC,
]
for i in range(types.size()):
    var ff = FlowFieldSpace.new()
    ff.position.x = i * 28.0
    ff.field_type = types[i]
    ff.space_size = Vector2(24, 24)
    ff.seed_value = 42
    add_child(ff)
```

### Single Source + Single Sink
```gdscript
var ff = FlowFieldSpace.new()
ff.field_type = FlowFieldSpace.FieldType.SOURCE_SINK
ff.num_elements = 2
ff.field_strength = 2.0
ff.space_size = Vector2(25, 25)
add_child(ff)
# One hill, one pit — water flows downhill from source to sink
```

### Combined with Particle Visualization
```gdscript
# Place flow field as floor, add particle system that follows the field
var ff = FlowFieldSpace.new()
ff.field_type = FlowFieldSpace.FieldType.GRADIENT_NOISE
ff.height_scale = 1.5  # Gentle enough to walk, visible enough to see flow
add_child(ff)
# Then add particles/agents that "roll" downhill on this surface
```

## Teaching Suggestions
- "Uphill = against the force, downhill = with the force"
- SOURCE_SINK with 2 elements creates the simplest potential well
- VORTEX_ARRAY shows how vortices create their own topography
- ELECTROMAGNETIC combines radial + angular — good for physics lessons
- SADDLE_POINTS teach stability analysis (hilltop = unstable, valley = stable, saddle = mixed)

## Performance Notes
- O(num_elements × vertices) — fast for typical num_elements (< 20)
- Static generation — no per-frame cost
- log() near singularity is clamped to avoid infinities
