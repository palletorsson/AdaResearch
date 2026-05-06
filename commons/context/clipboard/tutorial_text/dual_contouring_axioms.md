**Dual Contouring**
Sharp Features, Hermite Data, Surface Reconstruction

**Dual contouring reconstructs surfaces from volumetric data, preserving sharp features.**

**Alternative to marching cubes** - generates quad meshes instead of triangles.

**Key advantage:** Preserves **sharp edges and corners** (marching cubes smooths them).

---

## Concept

**Marching cubes** places vertices on edges (interpolates between grid points).
**Dual contouring** places vertices **inside cubes** (one vertex per cube that crosses surface).

**Hermite data required:**
- Not just **density values** (scalar field)
- Also **surface normals** (gradient of field)

Normal information → vertex placement that respects sharp features.

---

## Algorithm

**Steps:**
1. For each cube crossing surface (sign change in corners)
2. Find **edge crossings** (where surface intersects cube edges)
3. For each crossing: compute **surface normal** (gradient)
4. Solve for **optimal vertex position** inside cube (minimizes error to all edge crossings)
5. Connect vertices to form **quads** (not triangles)

**Code:**

```
func dual_contour(field: Array, gradient_field: Array, iso_value: float = 0.0) -> ArrayMesh:
    var vertices = []
    var quads = []
    var vertex_map = {}  # Map cube index → vertex index

    for x in range(grid_size.x - 1):
        for y in range(grid_size.y - 1):
            for z in range(grid_size.z - 1):
                var cube_index = get_cube_index(x, y, z)

                # Check if cube crosses surface
                var corners = get_corner_values(field, x, y, z)
                if not crosses_surface(corners, iso_value):
                    continue

                # Find edge crossings and their normals
                var edge_crossings = []
                var edge_normals = []

                for edge in range(12):  # Cube has 12 edges
                    if edge_crosses_surface(corners, edge, iso_value):
                        var crossing_point = interpolate_edge_crossing(
                            x, y, z, edge, corners, iso_value
                        )
                        var normal = get_gradient_at_point(
                            gradient_field, crossing_point
                        )

                        edge_crossings.append(crossing_point)
                        edge_normals.append(normal)

                # Solve for optimal vertex position inside cube
                var vertex_pos = solve_qef(edge_crossings, edge_normals)

                # Clamp to cube bounds (prevent vertices outside)
                vertex_pos = clamp_to_cube(vertex_pos, x, y, z)

                var vertex_index = vertices.size()
                vertices.append(vertex_pos)
                vertex_map = vertex_index

    # Generate quads by connecting neighboring cube vertices
    generate_quads(vertex_map, quads)

    return create_mesh_from_quads(vertices, quads)

func solve_qef(points: Array, normals: Array) -> Vector3:
    # Quadratic Error Function minimization
    # Find point P that minimizes sum of squared distances to planes
    # Each plane defined by: point + normal

    # Least squares solution: (A^T A)^-1 A^T b
    # where planes are: normal · (x - point) = 0

    var A = []
    var b = []

    for i in range(points.size()):
        var n = normals
        var p = points

        A.append([n.x, n.y, n.z])
        b.append(n.dot(p))

    # Solve AtA x = Atb (normal equations)
    var AtA = multiply_AtA(A)
    var Atb = multiply_Atb(A, b)

    var solution = solve_3x3(AtA, Atb)
    return Vector3(solution[0], solution[1], solution[2])
```

**QEF (Quadratic Error Function):** Find point that best fits all surface crossings.

---

## vs Marching Cubes

| **Marching Cubes** | **Dual Contouring** |
|---|---|
| Vertices on edges | Vertices inside cubes |
| Triangle mesh | Quad mesh |
| Smooth surfaces | Sharp features |
| Only density needed | Density + normals required |
| 15 unique cases | Simpler topology |

**Dual contouring excels at:**
- **Hard surface modeling** (architecture, manufactured objects)
- **Voxel art** (Minecraft-style with smooth edges)
- **CAD data** (preserving designed edges)

**Marching cubes better for:**
- **Organic forms** (blobs, metaballs)
- **When normals unavailable**
- **Simpler implementation**

---

## Computing Normals (Gradient)

**Normal = gradient of scalar field** (direction of steepest ascent).

**Code:**

```
func compute_gradient(field: Array, x: int, y: int, z: int) -> Vector3:
    var epsilon = 1.0  # Step size

    # Central difference approximation
    var dx = (get_field_value(field, x + 1, y, z) -
              get_field_value(field, x - 1, y, z)) / (2.0 * epsilon)

    var dy = (get_field_value(field, x, y + 1, z) -
              get_field_value(field, x, y - 1, z)) / (2.0 * epsilon)

    var dz = (get_field_value(field, x, y, z + 1) -
              get_field_value(field, x, y, z - 1)) / (2.0 * epsilon)

    return Vector3(dx, dy, dz).normalized()
```

**Gradient points perpendicular to surface** - captures feature orientation.

---

## Feature Detection

**Dual contouring detects features via normal discontinuity:**

If normals at edge crossings vary widely → **sharp feature** (corner/edge).
If normals similar → **smooth surface**.

QEF solver automatically places vertex to best represent feature:
- **Sharp corner:** Vertex near corner point
- **Smooth surface:** Vertex centered in cube
- **Edge:** Vertex along edge line

**This is implicit feature detection** - no explicit