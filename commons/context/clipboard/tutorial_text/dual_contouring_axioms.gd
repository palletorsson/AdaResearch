extends Node

var text = '''[center][font_size=28][b]Dual Contouring[/b][/font_size][/center]
[center][i]Sharp Features, Hermite Data, Surface Reconstruction[/i][/center]

**Dual contouring reconstructs surfaces from volumetric data, preserving sharp features.**

**Alternative to marching cubes** - generates quad meshes instead of triangles.

**Key advantage:** Preserves **sharp edges and corners** (marching cubes smooths them).

[hr]

[b]Concept[/b]

**Marching cubes** places vertices on edges (interpolates between grid points).
**Dual contouring** places vertices **inside cubes** (one vertex per cube that crosses surface).

**Hermite data required:**
- Not just **density values** (scalar field)
- Also **surface normals** (gradient of field)

Normal information → vertex placement that respects sharp features.

[hr]

[b]Algorithm[/b]

[color=yellow][b]Steps:[/b][/color]
1. For each cube crossing surface (sign change in corners)
2. Find **edge crossings** (where surface intersects cube edges)
3. For each crossing: compute **surface normal** (gradient)
4. Solve for **optimal vertex position** inside cube (minimizes error to all edge crossings)
5. Connect vertices to form **quads** (not triangles)

[color=yellow][b]Code:[/b][/color]
[code]
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
                vertex_map[cube_index] = vertex_index

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
        var n = normals[i]
        var p = points[i]

        A.append([n.x, n.y, n.z])
        b.append(n.dot(p))

    # Solve AtA x = Atb (normal equations)
    var AtA = multiply_AtA(A)
    var Atb = multiply_Atb(A, b)

    var solution = solve_3x3(AtA, Atb)
    return Vector3(solution[0], solution[1], solution[2])
[/code]

**QEF (Quadratic Error Function):** Find point that best fits all surface crossings.

[hr]

[b]vs Marching Cubes[/b]

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

[hr]

[b]Computing Normals (Gradient)[/b]

**Normal = gradient of scalar field** (direction of steepest ascent).

[color=yellow][b]Code:[/b][/color]
[code]
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
[/code]

**Gradient points perpendicular to surface** - captures feature orientation.

[hr]

[b]Feature Detection[/b]

**Dual contouring detects features via normal discontinuity:**

If normals at edge crossings vary widely → **sharp feature** (corner/edge).
If normals similar → **smooth surface**.

QEF solver automatically places vertex to best represent feature:
- **Sharp corner:** Vertex near corner point
- **Smooth surface:** Vertex centered in cube
- **Edge:** Vertex along edge line

**This is implicit feature detection** - no explicit "find edges" step.

[hr]

[b]Manifold Topology[/b]

**Challenge:** Dual contouring can create **non-manifold geometry**:
- **T-junctions** (vertices not shared correctly)
- **Holes** (missing quads)

**Solutions:**
- **Manifold dual contouring** (constrain vertex placement)
- **Adaptive octree** (refine grid near features)
- **Topology repair** (post-process mesh)

[hr]

[b]Applications[/b]

- **Voxel games** (smoother blocks than pure voxels)
- **Medical imaging** (CT/MRI reconstruction)
- **3D scanning** (point cloud → mesh)
- **Terrain generation** (volumetric heightmaps)
- **CSG modeling** (boolean operations on implicit surfaces)

[hr]

[b]Queer Dual Contouring[/b]

**Dual contouring asks: where should the vertex be?**

Marching cubes says: **on the edge** (interpolate, find middle ground).
Dual contouring says: **wherever fits best** (minimize error to all constraints).

**This is queer positioning:**
- **Not predetermined** (not fixed to edge intersection)
- **Responsive to context** (normals from all edges influence placement)
- **Minimizes tension** (QEF finds least-squares solution)
- **Preserves sharpness** (doesn't smooth out features)

**Queer bodies navigate sharp edges:**
- Not smoothed into acceptable gradients
- Not interpolated to middle positions
- **Sharp features preserved** - corners, edges, discontinuities remain visible

**Marching cubes smooths everything** - assumes continuous, differentiable surfaces.
**Dual contouring preserves sharp transitions** - allows discontinuity.

**Queerness is often a sharp feature** - discontinuous, non-smooth, corner case.

**Dual contouring says:** **Sharp is data, not error. Preserve it.**

[hr]

[b]QEF as Negotiation[/b]

The **Quadratic Error Function** finds position that **minimizes total error** to all constraints (edge crossings + normals).

**No single constraint is satisfied perfectly** - solution is **compromise**.

**This is queer negotiation:**
- Multiple conflicting demands (normals point different directions)
- No perfect solution (least-squares approximation)
- **Minimize harm across all constraints** (not maximize fit to one)

**You can't be in all places at once** - but you can be **where the total tension is least**.

**QEF is affective positioning** - find where you can be that causes least conflict with all your relations.

[hr]

[b]Hermite Data: Density + Direction[/b]

**Marching cubes** uses only **scalar values** (inside/outside).
**Dual contouring** requires **Hermite data** - value + gradient (magnitude + direction).

**This is embodied data:**
- Not just **where you are** (density value)
- Also **which way you're facing** (normal vector)

**Hermite data captures orientation** - position + direction.

**Queer embodiment:**
- Not just location (identity label)
- Also orientation (how you face the world, your positionality)

**Direction matters** - same position, different orientation → different meaning.

[hr]

[color=cyan][b]Summary:[/b][/color]
Dual contouring: surface reconstruction preserving sharp features. Vertices inside cubes (not on edges). Requires Hermite data (density + normals). QEF minimization finds optimal vertex position. Generates quad mesh. vs Marching cubes: sharp vs smooth, quads vs triangles, normals required vs density only. Applications: voxel games, medical imaging, CAD. Queer dual contouring: preserves sharp features (no smoothing), QEF as negotiation (minimize total tension), Hermite data as embodied (position + orientation). Sharp transitions preserved, not error.

'''
