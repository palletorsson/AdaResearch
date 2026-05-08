# Iter 5 — tetrahedron → PARTIAL (silhouette OK, edges not faithful)

**Verdict:** PARTIAL — promoted as `CylinderMesh(radial_segments=3, top_radius=0, bottom_radius=0.6, height=0.85)` but with a real visual fidelity gap.

## What works
The SILHOUETTE is correct. From outside, the v2 reads as a tetrahedron — apex on top, triangular base, three slanted faces. AABB matches. Edge lengths approximately right.

## What doesn't
Godot's `CylinderMesh` isn't topologically a tetrahedron. It's a sphere-like mesh with many internal triangles to support smooth normals. When you render with:

- **ParametricGrid shader (UV-space lines):** the UV mapping has a seam where u wraps from 1 back to 0; the seam shows as a stray white line that doesn't align with any face boundary.

- **SimpleGrid shader (barycentric edges):** highlights every triangle edge in the mesh, including the fan-triangulation at the apex. Result: dozens of tiny internal edges instead of the clean 6 a real tetrahedron has.

The original `tetrahedron.gd` uses `PrimitiveMeshBuilder` with 4 hand-coded vertices and 4 faces — exactly 6 edges, exactly 4 triangular faces, no fan triangulation. That clean topology is what makes the original look right with edge-highlighting shaders. The CylinderMesh-based v2 can't reproduce that without internal-edge cleanup that Godot's built-in primitives don't provide.

## What this tells us
Tetrahedron is a case where **silhouette equivalence isn't visual equivalence**. The shape from outside is right, but the shader's reaction to the mesh's actual triangulation reveals the difference. The original's 4-vertex hand-coded approach is genuinely better for edge-highlighting curricula than any built-in primitive can produce.

**Filed as PARTIAL PROMOTION** — usable if the artifact gets a no-edge material (StandardMaterial3D with flat color) and the curriculum doesn't depend on counting visible edges. Stays hand-coded if edge structure matters pedagogically.

## Updates the family scorecard from iter 6
The Platonic-solids family with this honest assessment:
- **tetrahedron** ← PARTIAL (silhouette only, clean edges need hand-coding)
- **cube** ← PROMOTED (BoxMesh)
- **octahedron** ← PROMOTED (`SphereMesh(rings=2, radial_segments=4)` = bipyramid_v2)
- **dodecahedron** ← WALL
- **icosahedron** ← WALL

So 2 fully-promoted, 1 partial, 2 walls. Less rosy than the 3-of-5 I claimed earlier.
