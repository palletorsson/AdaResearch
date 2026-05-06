**Worley Noise**
Cellular Patterns and Distance Fields

**Worley noise** (also called **Voronoi noise** or **cellular noise**) divides space into cells around random points.

Not smooth gradients - sharp boundaries, organic cells, natural cracks.

---

## The Core Concept: Distance to Nearest Point

**Algorithm:**
1. Scatter random points in space (feature points)
2. For any sample position, find distance to nearest feature point
3. Distance = noise value

**Code: Basic 2D Worley Noise**

```
# Scatter feature points in grid cells
func get_feature_point(cell_x: int, cell_y: int) -> Vector2:
    # Random offset within cell [0, 1] × [0, 1]
    var hash_x = hash_2d(cell_x, cell_y)
    var hash_y = hash_2d(cell_x + 1, cell_y + 1)
    return Vector2(cell_x + hash_x, cell_y + hash_y)

func worley_noise_2d(x: float, y: float) -> float:
    var cell_x = int(floor(x))
    var cell_y = int(floor(y))

    var min_dist = INF

    # Check 3×3 grid of cells (current + neighbors)
    for offset_y in range(-1, 2):
        for offset_x in range(-1, 2):
            var neighbor_x = cell_x + offset_x
            var neighbor_y = cell_y + offset_y

            var feature_point = get_feature_point(neighbor_x, neighbor_y)
            var diff = Vector2(x, y) - feature_point
            var dist = diff.length()

            if dist < min_dist:
                min_dist = dist

    return min_dist

# Result: Distance field - values increase away from feature points
# Creates cell boundaries where distances are equal
```

**Key insight:** Where two cells meet, distances to their feature points are equal → boundary.

---

## F1, F2, F2-F1: Distance Metrics

**Different combinations create different patterns:**

**F1: Distance to Closest Point**

```
func worley_F1(x: float, y: float) -> float:
    # Return distance to NEAREST feature point
    return min_dist  # As computed above

# Result: Smooth cells with sharp boundaries
# Dark at feature points, bright at boundaries
# Like: cells, bubbles, stone texture
```

**F2: Distance to Second-Closest Point**

func worley_F2(x: float, y: float) -> float:
    var distances = []

    # Collect all distances
    for neighbor in neighbors:
        var dist = (sample_pos - feature_point).length()
        distances.append(dist)

    distances.sort()
    return distances[1]  # Second smallest

# Result: Boundaries emphasized, cell centers de-emphasized
# Creates