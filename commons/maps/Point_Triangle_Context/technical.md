# Triangles

In *Point_Triangle*, three points closed a boundary. An interior appeared — the first region of space with an inside and an outside. This map goes further. The triangle isn't just a closed shape. It has a property no other polygon has. It is the only form that cannot change its shape without changing its edge lengths. This matters for everything that follows.

---

## Rigidity: The Property That Makes Triangles Different

Take four points connected in a square. Push one corner sideways. The angles change. The square shears into a parallelogram without any edge needing to stretch. The structure has no resistance to deformation. Add a diagonal and you've split it into two triangles. Now the structure is rigid.

This isn't a metaphor. It is a theorem in structural mechanics — the triangle is the minimal rigid polygon. Bridges, trusses, and geodesic domes are triangles for this reason. But it's also what makes the triangle the atom of 3D rendering. Every surface in a GPU pipeline decomposes into triangles because the hardware rasterizer needs one guarantee: three points define exactly one plane. Four do not.

When you grab a vertex sphere in the `interactivetriangle` artifact and drag it, notice how the other two vertices stay fixed. The surface reshapes to that one constraint. The triangle yields — but only to what you explicitly move. Nothing deforms implicitly. That is rigidity operating in real time.

---

## Constructing a Triangle in GDScript

A triangle is three vertices and a normal. The normal tells the renderer which side is facing forward. Without it, the GPU doesn't know what to illuminate or whether to draw the face at all.

The `triangle.gd` artifact constructs its mesh using `SurfaceTool`, Godot's programmatic mesh builder:

```gdscript
func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
    var v0 = vertices[face[0]]
    var v1 = vertices[face[1]]
    var v2 = vertices[face[2]]

    # The cross product of two edges gives a vector perpendicular to the face.
    # Normalize it to get the unit normal.
    var edge1 = v1 - v0
    var edge2 = v2 - v0
    var normal = edge1.cross(edge2).normalized()

    st.set_normal(normal)
    st.set_uv(Vector2(0.0, 0.0))
    st.add_vertex(v0)

    st.set_normal(normal)
    st.set_uv(Vector2(1.0, 0.0))
    st.add_vertex(v1)

    st.set_normal(normal)
    st.set_uv(Vector2(0.5, 1.0))
    st.add_vertex(v2)
```

Two edges from the same vertex: `v1 - v0` and `v2 - v0`. Their cross product is perpendicular to both — it points away from the face in the direction determined by winding order (which way you traverse the vertices). The cross product encodes orientation. This is not arbitrary: the GPU uses it to determine illumination and whether to skip drawing the face entirely (back-face culling).

To build a complete triangle mesh:

```gdscript
func update_triangle_mesh():
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    # Collect the three vertex positions
    var triangle_vertices = [
        vertex_positions[0],
        vertex_positions[1],
        vertex_positions[2]
    ]

    add_triangle_with_normal(st, triangle_vertices, [0, 1, 2])
    triangle_mesh.mesh = st.commit()
```

`SurfaceTool.begin()` opens a surface with a primitive type. `PRIMITIVE_TRIANGLES` means every three vertices form one triangle — no implicit connectivity. `commit()` finalizes the mesh and returns an `ArrayMesh`. That mesh goes onto a `MeshInstance3D` and becomes visible geometry.

The interactive triangle stores its three corner positions in an array and rebuilds the mesh whenever a vertex moves:

```gdscript
var vertex_positions: Array[Vector3] = [
    Vector3(-0.25, sphere_y_offset - 0.25, 0.0),  # Bottom-left
    Vector3( 0.25, sphere_y_offset - 0.25, 0.0),  # Bottom-right
    Vector3( 0.0,  sphere_y_offset + 0.25, 0.0)   # Top-center
]

func _on_point_moved(index: int, position: Vector3, _meta: Dictionary) -> void:
    if vertex_positions[index] == position:
        return
    vertex_positions[index] = position
    update_triangle_mesh()
```

Every drag event fires `_on_point_moved`. The position array updates. The mesh rebuilds. The latency is zero frames — the mesh is rebuilt synchronously in `_process` that frame.

---

## Orientation: Front, Back, and the Two Faces

The cross product determines which side the normal points toward, and that determines what "front" means. Reverse the vertex winding order — go `v0, v2, v1` instead of `v0, v1, v2` — and the normal flips 180 degrees. The front face becomes the back.

The `triangle.gd` artifact renders both sides by adding a second set of three vertices with the negated normal:

```gdscript
# Front face — normal points forward
st.set_normal(normal)
st.add_vertex(v0)
st.set_normal(normal)
st.add_vertex(v1)
st.set_normal(normal)
st.add_vertex(v2)

# Back face — reversed winding, negated normal
st.set_normal(-normal)
st.add_vertex(v0)
st.set_normal(-normal)
st.add_vertex(v2)   # v2 before v1 — reversed order
st.set_normal(-normal)
st.add_vertex(v1)
```

This is called double-sided rendering by duplication. An alternative is setting `cull_mode = BaseMaterial3D.CULL_DISABLED` on the material, which draws the face from both directions using the same normal — but then back-face illumination is wrong because the light calculates against the forward normal even when seen from behind.

The `interactivetriangle` uses both approaches across its two halves (pink front, dark back). Grab a vertex and rotate it to see the triangle flip from pink to dark. Orientation is not abstract here — it is directly sensed.

---

## The Pythagorean Theorem as Visible Area

The Pythagorean theorem is a statement about area. `a² + b²  = c²` doesn't just mean side lengths satisfy a relation — it means the square grown from the hypotenuse has exactly the same area as the two squares grown from the legs combined.

The `pythagorean_triangle_angles` artifact makes this visible. It constructs three squares, one grown from each side of a right triangle, using `update_square_mesh()`:

```gdscript
func update_square_mesh(mesh_inst: MeshInstance3D, p1: Vector3, p2: Vector3):
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    # The side vector — the edge we're growing the square from
    var side = p2 - p1
    # Perpendicular to the side, in the plane of the triangle
    var perp = side.cross(Vector3(0, 0, 1)).normalized() * side.length()

    var sq0 = p1
    var sq1 = p2
    var sq2 = p2 + perp
    var sq3 = p1 + perp

    # Two triangles forming the square
    add_triangle_face(st, sq0, sq1, sq2, normal)
    add_triangle_face(st, sq0, sq2, sq3, normal)

    mesh_inst.mesh = st.commit()
```

Drag the triangle's vertices. The three squares grow and shrink. When the angle at one vertex is exactly 90 degrees — when two sides are perpendicular — the two smaller squares together exactly fill the area of the large one. This is the theorem. Not stated: shown.

The artifact also displays the three interior angles as arc meshes at each vertex, updated live as vertices move. Angles, areas, and the theorem all change together when any vertex shifts. The constraint is spatial — you feel it, not just read it.

This is the decisive property of the right triangle that makes it the anchor for all measurement in Euclidean geometry. From this, trigonometry, coordinate systems, and 3D distance calculations all follow.

---

## Strips: When Triangles Share Edges

Geometry that triangulates a surface face-by-face is wasteful. A triangle strip shares edges between consecutive triangles, halving the vertex count for connected surfaces.

The `folded_strip` artifact creates 24 triangles as a connected strip, alternating vertex heights to make a pleated ribbon:

```gdscript
func _initialize_straight_strip():
    var num_verts = num_triangles + 2  # 24 triangles = 26 vertices
    var segment_width = strip_length / float(num_verts - 1)
    var start_x = -strip_length / 2.0

    for i in range(num_verts):
        var x = start_x + i * segment_width

        if i % 2 == 0:
            # Front row — lower
            vertex_positions.append(Vector3(x, base_y + height * 0.3 + strip_y_offset, 0.15))
        else:
            # Back row — higher
            vertex_positions.append(Vector3(x, base_y + height + strip_y_offset, -0.15))
```

The strip iterates through triangles with overlapping vertex indices:

```gdscript
for i in range(num_triangles):
    var p0 = vertex_positions[i]
    var p1 = vertex_positions[i + 1]
    var p2 = vertex_positions[i + 2]

    var col = color_main if (i % 2 == 0) else color_alt
    add_double_sided_triangle(st, p0, p1, p2, col)
```

Triangle `i` uses vertices `i`, `i+1`, `i+2`. Triangle `i+1` uses `i+1`, `i+2`, `i+3`. They share the edge between `i+1` and `i+2`. That shared edge is why the strip deforms continuously — drag one vertex sphere and both triangles that share its adjacent edge reshape.

This is the topological constraint made tactile. When you grab vertex 12 in the middle of the strip and pull it sideways, triangles 10, 11, 12, and 13 all respond. You can't move a shared vertex without affecting everything it's part of. Mesh topology is the constraint set. The geometry follows.

The `folded_strip` exposes all 24+2 vertex positions as grab spheres. Deform it into a saddle. Fold one end up. The mesh follows every drag because every triangle rebuilds from the current `vertex_positions` array each frame. This is not simulation — it's real-time mesh reconstruction from an editable data structure.

---

## Quads Are Two Triangles

Every face in a 3D mesh that appears to be a rectangle is secretly two triangles. The quad is a convenience. The hardware only knows triangles.

The `quad` artifact makes this explicit. Four vertices. Two triangles. The diagonal between them is a choice:

```gdscript
# Triangle A: Bottom-left, Bottom-right, Top-right
var triangle_a_indices: Array[int] = [0, 1, 2]

# Triangle B: Bottom-left, Top-right, Top-left
var triangle_b_indices: Array[int] = [0, 2, 3]
```

The diagonal runs from vertex `0` (bottom-left) to vertex `2` (top-right). This splits the quad. The alternative diagonal — `1` to `3` — would produce different triangles. The choice isn't neutral: different diagonals produce different normals at the shared edge, which affects shading. In a curved surface, the wrong diagonal creates visible artifacts.

The artifact renders each triangle with different colors on front and back, using `cull_mode` to separate them:

```gdscript
func _apply_material(mesh_instance: MeshInstance3D, color: Color, cull_mode: int):
    var material = StandardMaterial3D.new()
    material.albedo_color = color
    material.cull_mode = cull_mode  # CULL_BACK for front, CULL_FRONT for back
    mesh_instance.material_override = material
```

Four `MeshInstance3D` nodes render the same two triangle meshes — one for front face of triangle A, one for back face of triangle A, two more for triangle B. Each shows a different color depending on which side faces you. Rotate the quad and watch the colors shift. The four-color surface reveals the underlying triangle structure that the single-color quad would hide.

Drag vertex 2 (top-right) away from the plane. The quad is no longer planar. Triangle A stays in one plane; triangle B stays in another. The two planes diverge. This is why quads are "virtual" in hardware: the moment the four vertices aren't coplanar, the two triangles must occupy different planes. The quad is a useful fiction that dissolves when any vertex moves off the shared plane.

---

## Drawing Closed Loops into Surfaces

The `draw_triangle_faces` artifact takes a different approach. Rather than defining vertex positions in advance, it lets you place points interactively and closes loops into filled triangle faces.

When you drop a grab sphere close to the first point, the distance check triggers a snap:

```gdscript
func _handle_snap_to_point(point_index: int) -> void:
    # Snap the current drawing position to an existing point
    # If we've placed at least 2 prior points, closing to the first creates a face
```

This is fan triangulation: one fixed center point, and a series of vertices arranged around it. Each consecutive pair of outer vertices forms a triangle with the center. A pentagon becomes three triangles. An octagon becomes six. Any convex polygon fans from its first point.

The principle generalizes to the `draw_triangle_faces` workflow: place points freely, close the loop, and the artifact fills it with a colored mesh face. The loop becomes a surface. This is how polygon meshes were historically authored — point by point, face by face, until a closed watertight form emerged.

What the artifact demonstrates is the discretization underlying all polygon modeling: continuous surfaces don't exist in the GPU. There are only vertices, edges, and triangle faces. Everything curved is an approximation built from flat triangles. The more triangles, the smoother the curve — but it remains triangles all the way down.

---

## Setting Up Volume

This map closes the loop on flat geometry. Triangle rigidity, the Pythagorean theorem, strip topology, quad decomposition, face drawing — these are the full toolkit for 2D surfaces embedded in 3D space.

But surfaces without enclosure are just sheets. The dark sphere in this map is an atmosphere marker, not a lesson. The cube scene marker points forward. The `cube_scene` placed at position `(3, 7)` signals where the curriculum goes next: closed volumes, faces that face inward, a mesh that wraps around empty space.

Three triangles meeting at a vertex create a corner of space. Three such corners, connected by edges, close into a tetrahedron. The trihedron — three triangular faces meeting at a point — is the spatial analog of the triangle itself. Where the triangle is the minimal closed curve in 2D, the trihedron is the minimal closed surface in 3D.

*Primitives_Polythedra* begins exactly there: the moment surface becomes volume, the moment inside and outside exist in three dimensions rather than two.

---

## Possible Artifacts

**diagonal_flip_quad** — A quad that lets you toggle which diagonal splits it, showing in real time how the two triangulations produce different shading artifacts when vertices are off-plane. The current `quad` shows the triangles statically; this would make the topological choice explicit and reversible.

**area_sum_visualizer** — An artifact that renders the running area sum of the three Pythagorean squares as a floating number, updating live as vertices move. The theorem is visually present in `pythagorean_triangle_angles` but there's no direct numeric confirmation that leg-squares sum to hypotenuse-square. A live label showing `a² + b² = c²` with computed values would close that gap.

**triangle_strip_wave** — A folded strip with a sinusoidal height driver that animates the vertex heights automatically, showing how the strip topology propagates waveforms across the mesh. The current `folded_strip` requires manual deformation; an animated version would make the shared-edge constraint visible as a propagating wave rather than a static sculpture.