# HyperbolicSpace — How to Use in Maps

## What It Is
The Poincaré disk model of hyperbolic geometry projected as terrain. Near the center, space is flat and normal. Near the edges, heights change exponentially — you can walk forever and never reach the boundary. Negative curvature made physical.

## Scene Path
```
res://commons/context/walkgrids/hyperbolic_space.tscn
```

## Drop Into a Map Scene

```gdscript
var hs = preload("res://commons/context/walkgrids/hyperbolic_space.tscn").instantiate()
hs.height_mode = HyperbolicSpace.HeightMode.HYPERBOLIC_DISTANCE
hs.space_size = Vector2(25, 25)
hs.resolution = 80
hs.height_scale = 2.0
add_child(hs)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `height_mode` | HYPERBOLIC_DISTANCE | HYPERBOLIC_DISTANCE, GAUSSIAN_CURVATURE, GEODESIC_GRID, PSEUDOSPHERE |
| `curvature` | 1.0 | Negative curvature strength |
| `disk_radius` | 0.95 | How close to the boundary (< 1.0) |
| `tessellation` | NONE | NONE, POINCARE_TILING, GEODESIC_CIRCLES |
| `tiling_p` | 5 | Polygon sides for tiling |
| `tiling_q` | 4 | Polygons meeting at vertex |
| `ridge_sharpness` | 0.5 | Tiling ridge height |

## Height Modes

| Mode | Character |
|------|-----------|
| HYPERBOLIC_DISTANCE | Height = arctanh(r). Flat center, exponential rise at edges. |
| GAUSSIAN_CURVATURE | Shows curvature itself — dramatic rise near boundary. |
| GEODESIC_GRID | Sine grid warped hyperbolically — cells compress at edge. |
| PSEUDOSPHERE | Tractricoid profile — sech(d) gives the classic funnel shape. |

## Map Integration Examples

### Alternative Geometries Map
```gdscript
func _ready():
    var hs = HyperbolicSpace.new()
    hs.height_mode = HyperbolicSpace.HeightMode.HYPERBOLIC_DISTANCE
    hs.tessellation = HyperbolicSpace.TessellationType.POINCARE_TILING
    hs.curvature = 1.2
    hs.space_size = Vector2(30, 30)
    hs.height_scale = 2.5
    add_child(hs)
```

### Euclidean vs Hyperbolic Comparison
```gdscript
# Flat grid next to hyperbolic grid — same resolution, different geometry
var flat = SineSpace.new()
flat.wave_amplitude = 0.0  # Flat
flat.space_size = Vector2(24, 24)
add_child(flat)

var hyp = HyperbolicSpace.new()
hyp.position.x = 28.0
hyp.height_mode = HyperbolicSpace.HeightMode.GEODESIC_GRID
hyp.space_size = Vector2(24, 24)
add_child(hyp)
```

### Tiling Exploration
```gdscript
# {5,4} tiling — 4 pentagons meet at each vertex (impossible in Euclidean!)
var hs = HyperbolicSpace.new()
hs.tessellation = HyperbolicSpace.TessellationType.POINCARE_TILING
hs.tiling_p = 5  # Pentagons
hs.tiling_q = 4  # 4 meeting at vertex
hs.height_mode = HyperbolicSpace.HeightMode.HYPERBOLIC_DISTANCE
hs.ridge_sharpness = 0.8
add_child(hs)
```

### Pseudosphere Floor
```gdscript
# The only surface with constant negative curvature you can build in 3D
var hs = HyperbolicSpace.new()
hs.height_mode = HyperbolicSpace.HeightMode.PSEUDOSPHERE
hs.curvature = 0.8
hs.height_scale = 3.0
add_child(hs)
```

## Teaching Suggestions
- Walking from center to edge: same Euclidean steps, exponentially more hyperbolic distance
- {5,4} tiling shows why hyperbolic space has "more room" — pentagons can tile with 4 at a vertex
- Compare PSEUDOSPHERE with a regular cone — both have curvature but different kinds
- Pair with existing Poincaré disk artifact for 2D comparison

## Performance Notes
- Static generation, no per-frame cost
- log() and atan2() per vertex — fast at any resolution
- `disk_radius` very close to 1.0 creates extreme heights at edges — clamp or lower height_scale
