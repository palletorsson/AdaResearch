# WorleySpace — How to Use in Maps

## What It Is
Worley noise (cellular noise) creates cracked-earth, cell-wall terrain. Each cell has a flat region with sharp ridges at the boundaries. Think dried mud, honeycomb, Voronoi edges.

## Scene Path
```
res://commons/context/walkgrids/worley_space.tscn
```

## Drop Into a Map Scene

### Method 1: Direct scene instance
```gdscript
# In your map's _ready() or setup:
var worley = preload("res://commons/context/walkgrids/worley_space.tscn").instantiate()
worley.position = Vector3(0, -0.5, 0)  # Slightly below player start
worley.space_size = Vector2(30, 30)      # Match your map dimensions
worley.resolution = 80                    # Higher = smoother but slower
worley.height_scale = 1.5
add_child(worley)
```

### Method 2: Via TopologyManager
```gdscript
var tm = TopologyManager.new()
tm.create_worley_space = true
add_child(tm)
```

### Method 3: Add as child in editor
1. Open your map `.tscn`
2. Add a `Node3D` child
3. Attach `WorleySpace.gd` as script
4. Configure in Inspector

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `num_points` | 30 | Number of cells (more = finer grid) |
| `distance_metric` | EUCLIDEAN | Cell shape: EUCLIDEAN (round), MANHATTAN (diamond), CHEBYSHEV (square) |
| `combination` | F1 | F1 = smooth cells, F2_MINUS_F1 = ridge lines (cracked earth), F2 = star patterns |
| `invert` | false | Swap ridges ↔ valleys |
| `jitter` | 1.0 | 0 = regular grid, 1 = fully random |
| `height_scale` | 2.0 | Overall height multiplier |

## Map Integration Examples

### As a Floor for a Noise Map
Replace the flat grid floor with Worley terrain to teach cellular noise:
```gdscript
# In a Noise map scene
func _ready():
    var floor = WorleySpace.new()
    floor.space_size = Vector2(grid_width * cube_size, grid_depth * cube_size)
    floor.num_points = 20
    floor.combination = WorleySpace.DistanceCombination.F2_MINUS_F1  # Cracked earth
    floor.height_scale = 0.8  # Subtle enough to walk on
    add_child(floor)
```

### Side-by-Side Comparison (Teaching Metrics)
```gdscript
# Show all 4 distance metrics next to each other
for i in range(4):
    var ws = WorleySpace.new()
    ws.position.x = i * 25.0
    ws.distance_metric = i  # EUCLIDEAN, MANHATTAN, CHEBYSHEV, MINKOWSKI_P3
    ws.space_size = Vector2(20, 20)
    ws.num_points = 15
    add_child(ws)
```

### Dynamic: Change on Interaction
```gdscript
# Connect to a button or trigger
func _on_button_pressed():
    var ws = $WorleySpace
    ws.combination = (ws.combination + 1) % 5
    ws.generate_space()  # Regenerates mesh + collision
```

## map_data.json Integration
Worley works best as a standalone terrain scene placed under the map's root. It replaces or supplements the grid floor:
```json
{
    "settings": {
        "show_grid": false,
        "custom_floor": "res://commons/context/walkgrids/worley_space.tscn"
    }
}
```

## Performance Notes
- Resolution 60-80 is fine for VR
- `num_points` > 50 with F2_MINUS_F1 gets slow (O(n) per vertex per point)
- Pre-generate with `generate_space()` in `_ready()`, don't call every frame
