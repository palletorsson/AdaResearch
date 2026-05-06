# VoronoiSpace — How to Use in Maps

## What It Is
Nearest-point territory division as walkable terrain. Each random seed point claims a flat plateau. Boundaries between territories create sharp height transitions. Biological, territorial, organic.

## Scene Path
```
res://commons/context/walkgrids/voronoi_space.tscn
```

## Drop Into a Map Scene

```gdscript
var vs = preload("res://commons/context/walkgrids/voronoi_space.tscn").instantiate()
vs.space_size = Vector2(25, 25)
vs.resolution = 80
vs.num_points = 20
vs.height_variation = 2.0
vs.height_scale = 2.0
add_child(vs)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `num_points` | 20 | Number of territory cells |
| `height_variation` | 2.0 | Height difference between cells |
| `height_scale` | 2.0 | Global height multiplier |

## Map Integration Examples

### Computational Geometry Map
```gdscript
func _ready():
    var vs = VoronoiSpace.new()
    vs.num_points = 15
    vs.height_variation = 1.5
    vs.space_size = Vector2(30, 30)
    add_child(vs)
```

### Cell Count Progression
```gdscript
# Show how more points create finer territories
var counts = [5, 10, 20, 40, 80]
for i in range(counts.size()):
    var vs = VoronoiSpace.new()
    vs.position.x = i * 25.0
    vs.num_points = counts[i]
    vs.space_size = Vector2(20, 20)
    add_child(vs)
```

### Voronoi vs Worley Comparison
```gdscript
# Same points, different interpretation:
# Voronoi = flat cells with different heights
# Worley = distance-based ridges at borders
var vs = VoronoiSpace.new()
vs.num_points = 20
vs.space_size = Vector2(20, 20)
add_child(vs)

var ws = WorleySpace.new()
ws.position.x = 25.0
ws.num_points = 20
ws.combination = WorleySpace.DistanceCombination.F2_MINUS_F1
ws.space_size = Vector2(20, 20)
add_child(ws)
```

### Flat Platform Level
```gdscript
# Low num_points + low variation = distinct walkable platforms
var vs = VoronoiSpace.new()
vs.num_points = 8
vs.height_variation = 1.0
vs.height_scale = 1.5
vs.space_size = Vector2(30, 30)
add_child(vs)
```

## Teaching Suggestions
- Voronoi = "which point am I closest to?" — fundamental computational geometry
- Compare with WorleySpace — Voronoi uses closest point's HEIGHT, Worley uses the DISTANCE
- Low num_points makes clear territorial boundaries visible
- Pair with the existing Voronoi algorithm scene for 3D visualization comparison

## Performance Notes
- O(num_points × vertices) — fast for num_points < 100
- Static generation — no per-frame cost
- num_points > 200 gets slow at high resolution — use WorleySpace for fine cells instead
