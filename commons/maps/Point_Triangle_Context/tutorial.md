# Point Triangle Context

Place a triangle among other shapes. Relationships emerge.

Spawn a triangle and a square.

```gdscript
func spawn_triangle_and_square() -> void:
    spawn_triangle(Vector3(-2, 0, 0))
    spawn_square(Vector3(2, 0, 0))
```

Two shapes at different positions. Their relationship becomes a feature of the map.

Measure the shortest distance between them.

```gdscript
func shortest_distance(shape_a: Array, shape_b: Array) -> float:
    var min_dist: float = INF
    for va in shape_a:
        for vb in shape_b:
            min_dist = min(min_dist, va.distance_to(vb))
    return min_dist
```

Brute-force vertex-to-vertex check. For shapes with few vertices (triangles, squares), this is fast.

Detect whether two shapes overlap.

```gdscript
func shapes_overlap(a: Array, b: Array) -> bool:
    var a_bounds := compute_aabb(a)
    var b_bounds := compute_aabb(b)
    return a_bounds.intersects(b_bounds)
```

The axis-aligned bounding box test is conservative — it may return true when shapes are close but not touching. For exact overlap, use separating-axis theorem.

Render shapes with different colours by type.

```gdscript
func color_by_type(shape_type: String) -> Color:
    match shape_type:
        "triangle": return Color.RED
        "square": return Color.BLUE
        "pentagon": return Color.GREEN
    return Color.WHITE
```

A visual legend emerges from the colour assignment. Shape type is readable at a glance.

Group shapes into scenes.

```gdscript
func group_into_scene(shapes: Array) -> Node3D:
    var scene := Node3D.new()
    for s in shapes:
        scene.add_child(s)
    return scene
```

Grouping enables uniform transformations. Move the scene and every shape moves with it.

Compute the convex hull of combined vertex sets.

```gdscript
func convex_hull(points: Array) -> Array:
    # Graham scan (simplified for 2D)
    points.sort_custom(func(a, b): return a.x < b.x or (a.x == b.x and a.y < b.y))
    var lower: Array = []
    for p in points:
        while lower.size() >= 2 and cross2d(lower[-2], lower[-1], p) <= 0:
            lower.pop_back()
        lower.append(p)
    return lower
```

The convex hull wraps all the points as tightly as possible. Shapes' relationships become visible as the hull's shape.

Define proximity as a relationship.

```gdscript
func are_neighbours(shape_a: Array, shape_b: Array, threshold: float = 0.5) -> bool:
    return shortest_distance(shape_a, shape_b) < threshold
```

Shapes within the threshold distance are neighbours. The map's spatial relationships are now queryable.

You can now place shapes in space, measure their proximity, test overlap, and compute the hull containing them all. Primitives_Polythedra will next lift the 2D polygons into 3D polyhedra.

Measure a shape's centroid.

```gdscript
func centroid(vertices: Array) -> Vector3:
    var sum := Vector3.ZERO
    for v in vertices:
        sum += v
    return sum / vertices.size()
```

The arithmetic mean of the vertices. The centroid is the shape's balance point.

Rotate all shapes around a shared centre.

```gdscript
func rotate_group(shapes: Array, centre: Vector3, axis: Vector3, angle: float) -> void:
    for shape in shapes:
        var offset: Vector3 = shape.global_position - centre
        var rotated: Vector3 = offset.rotated(axis, angle)
        shape.global_position = centre + rotated
```

Every shape pivots around the same point. The group rotates as a rigid body.
