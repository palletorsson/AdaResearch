# Iter 6 — dodecahedron + icosahedron → WALLS

**Two regular polyhedra, both walls. Filed together because they fail for the same reason.**

## dodecahedron → WALL
20 vertices, 12 pentagonal faces, edge-symmetric. No Godot built-in primitive produces this topology. SphereMesh approximations look smooth/geodesic, not faceted-pentagonal. Composition can't reach it either — there's no axis-aligned arrangement of cylinders or boxes that produces a regular dodecahedron.

## icosahedron → WALL
12 vertices, 20 triangular faces, edge-symmetric. Same story. SphereMesh(rings=2, radial_segments=5) is a pentagonal bipyramid (7 vertices, 10 faces), not an icosahedron (12 vertices, 20 faces). No built-in matches. No composition reaches it.

## Why the regular-polyhedra family is a wall

The five Platonic solids:
- **tetrahedron** ← PROMOTED via `CylinderMesh(radial_segments=3, top_radius=0)` (the cone trick)
- **cube** ← PROMOTED via `BoxMesh` (already done earlier today)
- **octahedron** ← PROMOTED via `SphereMesh(rings=2, radial_segments=4)` (= bipyramid_v2 from this morning)
- **dodecahedron** ← WALL
- **icosahedron** ← WALL

Three of five Platonic solids are reachable through the genome (tetrahedron via cone-degenerate-cylinder, cube via BoxMesh, octahedron via low-poly sphere). The remaining two — dodecahedron and icosahedron — are NOT special cases of any Godot built-in primitive's parameter space. Their pentagonal-face / 20-triangle-face symmetry has no parametric expression.

To promote them we'd need either:
1. A new Godot built-in primitive (RegularPolyhedronMesh with N type slots — not happening)
2. A custom `commons/primitives/shared/platonic_factory.gd` that takes a name and emits the right vertex/face arrays — but that's exactly the hand-coded pattern we're trying to retire.

**Filed as WALLS.** Useful boundary information: the regular-polyhedra family has 3-of-5 reachable, 2-of-5 unreachable. The genome's reach has a clean topological edge here.
