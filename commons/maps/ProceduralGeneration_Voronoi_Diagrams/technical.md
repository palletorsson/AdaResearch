# Voronoi Diagrams — Technical

## Brute Force (for understanding)

```gdscript
func voronoi_bruteforce(point: Vector2, seeds: Array) -> int:
    # Returns index of closest seed
    var min_dist = INF
    var closest = -1
    for i in range(seeds.size()):
        var d = point.distance_to(seeds[i])
        if d < min_dist:
            min_dist = d
            closest = i
    return closest

# Generate image
func render_voronoi(width: int, height: int, seeds: Array) -> Image:
    var img = Image.create(width, height, false, Image.FORMAT_RGB8)
    for x in range(width):
        for y in range(height):
            var cell = voronoi_bruteforce(Vector2(x, y), seeds)
            img.set_pixel(x, y, cell_colors[cell])
    return img
```

## Jump Flooding Algorithm (GPU-friendly)

```gdscript
# O(log n) passes, parallelizable
func jump_flood(seeds: Array, size: int) -> Array:
    var grid = initialize_grid(seeds, size)
    var step = size / 2
    
    while step >= 1:
        for x in range(size):
            for y in range(size):
                # Check 9 neighbors at distance 'step'
                for dx in [-step, 0, step]:
                    for dy in [-step, 0, step]:
                        var nx = x + dx
                        var ny = y + dy
                        if in_bounds(nx, ny):
                            var neighbor_seed = grid[nx][ny]
                            if is_closer(x, y, neighbor_seed, grid[x][y]):
                                grid[x][y] = neighbor_seed
        step /= 2
    return grid
```

## Delaunay via Bowyer-Watson

```gdscript
func bowyer_watson(points: Array) -> Array:
    # Start with super-triangle containing all points
    var triangles = [create_super_triangle(points)]
    
    for point in points:
        var bad_triangles = []
        
        # Find triangles whose circumcircle contains point
        for tri in triangles:
            if tri.circumcircle_contains(point):
                bad_triangles.append(tri)
        
        # Find boundary of polygonal hole
        var polygon = find_boundary(bad_triangles)
        
        # Remove bad triangles
        for tri in bad_triangles:
            triangles.erase(tri)
        
        # Re-triangulate with new point
        for edge in polygon:
            triangles.append(Triangle.new(edge.a, edge.b, point))
    
    # Remove triangles connected to super-triangle
    return filter_super(triangles)

# Voronoi from Delaunay: connect circumcenters
func delaunay_to_voronoi(triangles: Array) -> Array:
    var edges = []
    for tri in triangles:
        var center = tri.circumcenter()
        for neighbor in tri.neighbors:
            edges.append([center, neighbor.circumcenter()])
    return edges
```

## 3D Voronoi

```gdscript
# 3D cells are convex polyhedra
func voronoi_3d_cell(seed: Vector3, all_seeds: Array) -> ConvexHull:
    # Start with large bounding box
    var cell = BoundingBox.new()
    
    # Clip by half-space for each other seed
    for other in all_seeds:
        if other == seed:
            continue
        var plane = bisector_plane(seed, other)
        cell = cell.clip(plane)
    
    return cell
```

## Shader-based Voronoi

```glsl
// Fragment shader for real-time Voronoi
float voronoi(vec2 uv, float scale) {
    vec2 p = uv * scale;
    vec2 cell = floor(p);
    vec2 frac = fract(p);
    
    float min_dist = 1.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 neighbor = vec2(x, y);
            vec2 seed = hash2(cell + neighbor); // Pseudo-random
            float d = distance(frac, neighbor + seed);
            min_dist = min(min_dist, d);
        }
    }
    return min_dist;
}
```
